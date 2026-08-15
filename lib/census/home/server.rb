# frozen_string_literal: true

require "json"
require "webrick"

module Census
  module Home
    # A deliberately small HTTP layer over the coordinator: four endpoints,
    # JSON in and out, no framework. Volunteers need nothing but curl.
    #
    #   POST /register  {name, contact}          -> {worker_id}
    #   POST /lease     {worker_id}              -> unit or {unit: null}
    #   POST /results   {unit_id, worker_id, verdict, payload, seconds}
    #   GET  /status                             -> census-wide progress
    class Server
      def initialize(coordinator:, port: 9292, logger: nil)
        @coordinator = coordinator
        @port = port
        @logger = logger
      end

      def start
        server = WEBrick::HTTPServer.new(Port: port, Logger: quiet_logger, AccessLog: [])
        mount(server, "/register") { |body| { worker: coordinator.register(name: body.fetch(:name), contact: body[:contact]) } }
        mount(server, "/lease") { |body| { unit: coordinator.lease(worker_id: body.fetch(:worker_id)) } }
        mount(server, "/results") { |body| submit(body) }
        server.mount_proc("/status") { |_request, response| respond(response, coordinator.status) }
        trap("INT") { server.shutdown }
        logger&.puts("polycubing@home coordinator listening on port #{port}")
        server.start
      end

      private

      attr_reader :coordinator, :logger, :port

      def submit(body)
        coordinator.submit(
          unit_id: body.fetch(:unit_id),
          worker_id: body.fetch(:worker_id),
          verdict: body.fetch(:verdict),
          payload: body[:payload] || {},
          seconds: body[:seconds]
        )
      end

      def mount(server, path, &handler)
        server.mount_proc(path) do |request, response|
          body = request.body.to_s.empty? ? {} : JSON.parse(request.body, symbolize_names: true)
          respond(response, handler.call(body))
        rescue StandardError => error
          response.status = 400
          respond(response, { error: error.message })
        end
      end

      def respond(response, payload)
        response["Content-Type"] = "application/json"
        response.body = "#{JSON.generate(payload)}\n"
      end

      def quiet_logger = WEBrick::Log.new(File::NULL)
    end
  end
end
