# frozen_string_literal: true

require "json"
require "sinatra/base"
require "rack/attack"

module Census
  module AtHome
    # The HTTP face of the coordinator: four JSON endpoints, no views, no
    # sessions. Everything that decides anything lives in Coordinator; this
    # class only speaks HTTP, so it can be swapped for Rails the day the
    # volunteer portal needs accounts.
    #
    # Generic web risks are handled here (body caps, rate limiting, JSON
    # shape); domain risks (submission size, verification cost) are handled
    # by SubmissionGuard and Coordinator, because no framework knows what a
    # plausible tiling certificate looks like.
    # The counter store Rack::Attack expects, minus the Rails dependency:
    # per-key hit counts in a bounded, self-expiring hash.
    class MemoryStore
      def initialize
        @counts = {}
        @mutex = Mutex.new
      end

      def increment(key, amount = 1, options = {})
        expires_in = options[:expires_in].to_i
        @mutex.synchronize do
          @counts.delete_if { |_, (_, expiry)| expiry < Process.clock_gettime(Process::CLOCK_MONOTONIC) }
          count, expiry = @counts[key]
          expiry = Process.clock_gettime(Process::CLOCK_MONOTONIC) + expires_in if expiry.nil? || expiry < Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @counts[key] = [(count || 0) + amount, expiry]
          @counts[key].first
        end
      end

      def read(key) = @mutex.synchronize { @counts[key]&.first }
      def write(key, value, options = {}) = @mutex.synchronize { @counts[key] = [value, Process.clock_gettime(Process::CLOCK_MONOTONIC) + options[:expires_in].to_i] }
      def delete(key) = @mutex.synchronize { @counts.delete(key) }
    end

    class Server < Sinatra::Base
      MAX_BODY_BYTES = 5 * 1024 * 1024

      class << self
        attr_accessor :coordinator
      end

      configure do
        set :show_exceptions, false
        set :raise_errors, false
        set :logging, false
        disable :protection

        # Volunteers reach this by IP or whatever hostname the deployment
        # answers to, so host authorization is off by default — Sinatra 4
        # would otherwise 403 every remote client in production. Set
        # AT_HOME_HOSTS to a comma-separated list to restrict it.
        set :host_authorization, { permitted_hosts: ENV.fetch("AT_HOME_HOSTS", "").split(",") }
      end

      use Rack::Attack

      # In-process counters: one coordinator, so throttling needs no shared
      # store. Put Redis here (or rate-limit at the proxy) if it ever scales
      # to more than one process.
      Rack::Attack.cache.store = MemoryStore.new
      Rack::Attack.throttle("requests by ip", limit: 120, period: 60) { it.ip }
      Rack::Attack.throttled_responder = lambda do |_request|
        [429, { "Content-Type" => "application/json" }, [%({"error":"slow down"}\n)]]
      end

      before do
        content_type :json
        halt(413, json(error: "payload too large")) if request.content_length.to_i > MAX_BODY_BYTES
      end

      post "/register" do
        body = parse_body
        json(client: coordinator.register(handle: require_field(body, :handle),
                                          display_name: body[:display_name],
                                          contact: body[:contact]))
      end

      post "/lease" do
        body = parse_body
        json(unit: coordinator.lease(client_id: Integer(require_field(body, :client_id))))
      end

      post "/results" do
        body = parse_body
        json(coordinator.submit(unit_id: Integer(require_field(body, :unit_id)),
                                client_id: Integer(require_field(body, :client_id)),
                                verdict: String(require_field(body, :verdict)),
                                payload: body[:payload] || {},
                                seconds: body[:seconds]))
      end

      get "/status" do
        json(coordinator.status)
      end

      error do
        status 400
        json(error: env["sinatra.error"].message)
      end

      private

      def coordinator = self.class.coordinator

      def parse_body
        raw = request.body.read(MAX_BODY_BYTES + 1).to_s
        halt(413, json(error: "payload too large")) if raw.bytesize > MAX_BODY_BYTES
        return {} if raw.empty?

        parsed = JSON.parse(raw, symbolize_names: true)
        raise ArgumentError, "body must be a JSON object" unless parsed.is_a?(Hash)

        parsed
      end

      def require_field(body, key)
        body.fetch(key) { raise ArgumentError, "missing #{key}" }
      end

      def json(payload) = "#{JSON.generate(payload)}\n"
    end
  end
end
