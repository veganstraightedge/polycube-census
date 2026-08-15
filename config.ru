# frozen_string_literal: true

# Rack entry point for the polycubing@home coordinator.
#
#   bundle exec puma -C config/puma.rb    (or script/at_home/server)
#
# The connection pool is sized to the server's thread count so a saturated
# server never waits on connections: set AT_HOME_THREADS once and both
# follow it.

require_relative "lib/census"

threads = Integer(ENV.fetch("AT_HOME_THREADS", "16"))
store = Census::AtHome::Store.new(pool_size: threads)
Census::AtHome::Server.coordinator = Census::AtHome::Coordinator.new(store:)

run Census::AtHome::Server
