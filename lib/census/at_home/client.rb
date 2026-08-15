# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Census
  module AtHome
    # The volunteer half: ask for a unit, solve it locally, hand back the
    # answer, repeat. Holds no census state and needs no trust in either
    # direction — the coordinator re-verifies everything it returns.
    # Raised for responses worth retrying (throttled, or the coordinator
    # having a bad moment) as opposed to responses that are our own fault.
    class TransientResponse < StandardError; end

    class Client
      # A coordinator can restart, redeploy, or briefly vanish; none of that
      # should cost a volunteer their work. Transient failures are retried
      # with capped backoff — including the submission of an already-solved
      # unit, which is the one thing genuinely expensive to lose.
      TRANSIENT_ERRORS = [
        Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
        Errno::EPIPE, EOFError, SocketError, Net::OpenTimeout, Net::ReadTimeout
      ].freeze
      RETRY_DELAYS = [1, 2, 5, 10, 20, 30, 60].freeze

      # Responses meaning "not now" rather than "you asked wrongly".
      TOO_MANY_REQUESTS = 429
      SERVER_ERROR_FLOOR = 500

      def initialize(url:, handle:, display_name: nil, contact: nil, report: nil, give_up_after: nil)
        @base = URI(url)
        @handle = handle
        @display_name = display_name
        @contact = contact
        @report = report
        @give_up_after = give_up_after
        @client_id = nil
      end

      def register
        response = post("/register", { handle:, display_name:, contact: })
        @client_id = response && response[:client][:id]
      end

      # Runs until the queue is empty (or limit units are done). Returns a
      # tally of what happened, for the caller to print. A `stopped` entry
      # means the coordinator went away and did not come back.
      def run(limit: nil, idle_sleep: 5, once: false)
        tally = Hash.new(0)
        register unless client_id
        return tally.merge("stopped" => 1) unless client_id

        loop do
          lease = post("/lease", { client_id: })
          break tally["stopped"] = 1 unless lease

          unit = lease[:unit]
          unless unit
            break if once

            report&.call("no work available")
            sleep(idle_sleep)
            next
          end

          verdict, payload, seconds = solve(unit)
          answer = post("/results", { unit_id: unit[:id], client_id:, verdict:, payload:, seconds: })
          unless answer
            # The work is done but unreportable; the lease will expire and
            # the unit returns to the queue for someone else.
            report&.call("#{unit[:shape_id]}  #{verdict}  UNREPORTED — coordinator unreachable")
            break tally["stopped"] = 1
          end

          tally[answer[:accepted] ? "accepted" : "rejected"] += 1
          tally[verdict] += 1
          report&.call("#{unit[:shape_id]}  #{verdict}  #{answer[:accepted] ? 'accepted' : "REJECTED (#{answer[:note]})"}  #{seconds}s")
          break if limit && tally["accepted"] + tally["rejected"] >= limit
        end
        tally
      end

      private

      attr_reader :base, :client_id, :contact, :display_name, :give_up_after, :handle, :report

      def solve(unit)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        verdict, payload = case unit[:kind]
                           when "shape" then solve_shape(unit)
                           when "cube" then solve_cube(unit)
                           else ["error", { note: "unknown unit kind #{unit[:kind]}" }]
                           end
        [verdict, payload, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)]
      end

      def solve_shape(unit)
        shape = Polycube.new(cells: unit[:cells])
        budgets = unit[:budgets] || {}
        certificate = BoxSearch.new(shape:, max_volume: budgets.fetch(:box_max_volume, BoxSearch::DEFAULT_MAX_VOLUME)).certificate ||
                      TorusSearch.new(shape:, max_index: budgets.fetch(:torus_max_index, TorusSearch::DEFAULT_MAX_INDEX)).certificate
        return ["exhausted", { budgets: }] unless certificate

        ["tiler", { certificate: }]
      end

      def solve_cube(unit)
        model = SAT::Kissat.solve_cube(cnf_path: unit[:cnf_path], cube: unit[:cube])
        model ? ["sat", { model: model.to_a }] : ["unsat", { cube: unit[:cube] }]
      end

      # Retries while the coordinator is unreachable or unwell, and raises
      # only on failures retrying cannot fix (a malformed request of ours).
      # Returns nil if it gives up, so callers can stop cleanly rather than
      # crash with a stack trace in a volunteer's terminal.
      def post(path, body)
        waited = 0
        attempt = 0
        begin
          exchange(path, body)
        rescue *TRANSIENT_ERRORS, TransientResponse => error
          delay = RETRY_DELAYS[[attempt, RETRY_DELAYS.size - 1].min]
          if give_up_after && waited + delay > give_up_after
            report&.call("coordinator still unreachable after #{waited}s — stopping (#{error.class})")
            return nil
          end

          report&.call("coordinator unavailable (#{error.class}); retrying in #{delay}s")
          sleep(delay)
          waited += delay
          attempt += 1
          retry
        end
      end

      def exchange(path, body)
        request = Net::HTTP::Post.new(URI.join(base, path))
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
        response = Net::HTTP.start(base.host, base.port, read_timeout: 300, open_timeout: 30) { it.request(request) }

        # Throttling and server errors mean "not now"; other 4xx means we
        # asked wrongly and repeating it would just be rude.
        status = response.code.to_i
        raise TransientResponse, "HTTP #{status}" if status == TOO_MANY_REQUESTS || status >= SERVER_ERROR_FLOOR

        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
