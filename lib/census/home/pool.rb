# frozen_string_literal: true

require "pg"

module Census
  module Home
    # A minimal connection pool. Puma is genuinely concurrent, so the single
    # mutex-guarded connection that served the WEBrick spike would serialize
    # the whole coordinator; this hands each request its own connection and
    # blocks only when every one is busy.
    class Pool
      def initialize(url:, size: 8, timeout: 5)
        @url = url
        @size = size
        @timeout = timeout
        @available = Queue.new
        @created = 0
        @mutex = Mutex.new
      end

      def with
        connection = checkout
        begin
          yield connection
        ensure
          @available << connection
        end
      end

      def close
        @available.close
        @available.size.times { @available.pop&.close }
      end

      private

      def checkout
        mutex.synchronize do
          if @created < size
            @created += 1
            return PG.connect(url)
          end
        end
        Timeout.timeout(timeout) { @available.pop }
      end

      attr_reader :mutex, :size, :timeout, :url
    end
  end
end
