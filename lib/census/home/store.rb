# frozen_string_literal: true

require "pg"
require "json"

module Census
  module Home
    # Postgres-backed state for the coordinator: workers, units, results.
    # Scheduling state only — the census's truth stays in data/ and git.
    #
    # One connection serves many request threads, so every query is
    # serialized. Queue operations are sub-millisecond; a connection pool is
    # the upgrade when that stops being true.
    class Store
      DEFAULT_URL = ENV.fetch("POLYCUBE_HOME_URL", "postgres:///polycube_home")

      def initialize(url: DEFAULT_URL)
        @connection = PG.connect(url)
        @mutex = Mutex.new
      end

      def load_schema(path)
        synchronize do
          connection.exec("SET client_min_messages TO WARNING")
          connection.exec(File.read(path))
        end
      end

      def reset = synchronize { connection.exec("TRUNCATE results, units, workers RESTART IDENTITY CASCADE") }

      def close = synchronize { connection.close }

      # handle is the permanent scheduling key; display_name is the credit
      # string and starts unapproved — nothing reaches data/ unmoderated.
      def register_worker(handle:, display_name: nil, contact: nil)
        row = synchronize do
          connection.exec_params(<<~SQL, [handle, display_name, contact]).first
            INSERT INTO workers (handle, display_name, contact) VALUES ($1, $2, $3)
            ON CONFLICT (handle) DO UPDATE
              SET last_seen = now(),
                  contact = COALESCE(EXCLUDED.contact, workers.contact),
                  display_name = COALESCE(EXCLUDED.display_name, workers.display_name)
            RETURNING id, handle, display_name, display_state
          SQL
        end
        { id: Integer(row["id"]), handle: row["handle"], display_name: row["display_name"],
          display_state: row["display_state"] }
      end

      # What credits.solved_by may say for this worker: the approved display
      # name, or the opaque handle until a human approves one.
      def credit_string(worker_id)
        row = synchronize do
          connection.exec_params("SELECT handle, display_name, display_state FROM workers WHERE id = $1", [worker_id]).first
        end
        return nil unless row

        row["display_state"] == "approved" && row["display_name"] ? row["display_name"] : row["handle"]
      end

      def approve_display_name(worker_id, approved: true)
        synchronize do
          connection.exec_params("UPDATE workers SET display_state = $2 WHERE id = $1",
                                 [worker_id, approved ? "approved" : "rejected"])
        end
      end

      def add_unit(kind:, shape_id:, payload:, parent_id: nil)
        row = synchronize do
          connection.exec_params(<<~SQL, [kind, shape_id, parent_id, JSON.generate(payload)]).first
            INSERT INTO units (kind, shape_id, parent_id, payload) VALUES ($1, $2, $3, $4)
            ON CONFLICT DO NOTHING
            RETURNING id
          SQL
        end
        row && Integer(row["id"])
      end

      # Atomically hand out the oldest available unit: pending, or leased with
      # an expired lease (a worker that vanished mid-flight costs one lease).
      def lease_unit(worker_id:, seconds:)
        row = synchronize do
          connection.exec_params(<<~SQL, [worker_id, seconds]).first
            UPDATE units SET status = 'leased', lease_worker = $1,
                             lease_until = now() + ($2 || ' seconds')::interval,
                             attempts = attempts + 1
            WHERE id = (
              SELECT id FROM units
              WHERE status = 'pending' OR (status = 'leased' AND lease_until < now())
              ORDER BY id
              FOR UPDATE SKIP LOCKED
              LIMIT 1
            )
            RETURNING id, kind, shape_id, parent_id, payload
          SQL
        end
        row && unit_from(row)
      end

      def unit(id)
        row = synchronize do
          connection.exec_params("SELECT id, kind, shape_id, parent_id, payload, status FROM units WHERE id = $1", [id]).first
        end
        row && unit_from(row)
      end

      def record_result(unit_id:, worker_id:, verdict:, payload:, seconds:, verified:, note: nil)
        synchronize do
          connection.exec_params(<<~SQL, [unit_id, worker_id, verdict, JSON.generate(payload), seconds, verified, note])
            INSERT INTO results (unit_id, worker_id, verdict, payload, seconds, verified, verifier_note)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
          SQL
        end
      end

      def close_unit(id:, status:)
        synchronize do
          connection.exec_params("UPDATE units SET status = $2, lease_worker = NULL, lease_until = NULL WHERE id = $1", [id, status])
        end
      end

      def release_unit(id)
        synchronize do
          connection.exec_params("UPDATE units SET status = 'pending', lease_worker = NULL, lease_until = NULL WHERE id = $1", [id])
        end
      end

      def credit_worker(id:, accepted:)
        column = accepted ? "accepted" : "rejected"
        synchronize do
          connection.exec_params("UPDATE workers SET #{column} = #{column} + 1, last_seen = now() WHERE id = $1", [id])
        end
      end

      def status
        synchronize do
          units = connection.exec("SELECT status, count(*) FROM units GROUP BY status").to_h { [it["status"], Integer(it["count"])] }
          results = connection.exec("SELECT verdict, count(*) FROM results WHERE verified IS NOT FALSE GROUP BY verdict")
                              .to_h { [it["verdict"], Integer(it["count"])] }
          workers = connection.exec("SELECT handle, display_name, display_state, accepted, rejected FROM workers ORDER BY accepted DESC")
                              .map { { handle: it["handle"], display_name: it["display_name"], display_state: it["display_state"],
                              accepted: Integer(it["accepted"]), rejected: Integer(it["rejected"]) } }
          { units:, results:, workers: }
        end
      end

      private

      attr_reader :connection, :mutex

      def synchronize(&) = mutex.synchronize(&)

      def unit_from(row)
        {
          id: Integer(row["id"]),
          kind: row["kind"],
          shape_id: row["shape_id"],
          parent_id: row["parent_id"] && Integer(row["parent_id"]),
          payload: JSON.parse(row["payload"], symbolize_names: true)
        }
      end
    end
  end
end
