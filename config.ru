# frozen_string_literal: true

# Rack entry point for the polycubing@home server.
#
#   bundle exec puma -C config/puma.rb
#   # or:
#   script/at_home/server
#
# The connection pool is sized to the server's thread count
# so that a saturated server never waits on connections.
# Both the connection pool and the web server use the AT_HOME_THREADS.
# To change the thread count and connection pool size:
#     set AT_HOME_THREADS ENV variable and restart the server.

require_relative "lib/census"

threads = Integer(ENV.fetch("AT_HOME_THREADS", "16"))
store = Census::AtHome::Store.new(pool_size: threads)
proofs = ENV.fetch("AT_HOME_PROOFS", Census::AtHome::Coordinator::DEFAULT_PROOFS)
Census::AtHome::Server.coordinator = Census::AtHome::Coordinator.new(store:, proofs:)

run Census::AtHome::Server
