# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Census
  module Home
    # The volunteer half: ask for a unit, solve it locally, hand back the
    # answer, repeat. Holds no census state and needs no trust in either
    # direction — the coordinator re-verifies everything it returns.
    class Worker
      def initialize(url:, handle:, display_name: nil, contact: nil, report: nil)
        @base = URI(url)
        @handle = handle
        @display_name = display_name
        @contact = contact
        @report = report
        @worker_id = nil
      end

      def register
        @worker_id = post("/register", { handle:, display_name:, contact: })[:worker][:id]
      end

      # Runs until the queue is empty (or limit units are done). Returns a
      # tally of what happened, for the caller to print.
      def run(limit: nil, idle_sleep: 5, once: false)
        register unless worker_id
        tally = Hash.new(0)
        loop do
          unit = post("/lease", { worker_id: })[:unit]
          unless unit
            break if once

            report&.call("no work available")
            sleep(idle_sleep)
            next
          end

          verdict, payload, seconds = solve(unit)
          answer = post("/results", { unit_id: unit[:id], worker_id:, verdict:, payload:, seconds: })
          tally[answer[:accepted] ? "accepted" : "rejected"] += 1
          tally[verdict] += 1
          report&.call("#{unit[:shape_id]}  #{verdict}  #{answer[:accepted] ? 'accepted' : "REJECTED (#{answer[:note]})"}  #{seconds}s")
          break if limit && tally["accepted"] + tally["rejected"] >= limit
        end
        tally
      end

      private

      attr_reader :base, :contact, :display_name, :handle, :report, :worker_id

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

      def post(path, body)
        request = Net::HTTP::Post.new(URI.join(base, path))
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
        response = Net::HTTP.start(base.host, base.port, read_timeout: 300, open_timeout: 30) { it.request(request) }
        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
