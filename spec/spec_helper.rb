# frozen_string_literal: true

# The @home specs truncate what they touch, so they get their own database —
# running the suite must never disturb a live coordinator's queue.
ENV["POLYCUBE_AT_HOME_URL"] ||= "postgres:///polycube_at_home_test"

require_relative "../lib/census"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!

  # polycubing@home specs need a live coordinator database; skip them when
  # one isn't configured so the core suite runs anywhere.
  config.before(:each, :home) do
    Census::AtHome::Store.new.close
  rescue StandardError => error
    skip "coordinator database unavailable (#{error.class}) — run script/at_home/setup"
  end

  # Proof checking needs the vendored drat-trim, which has no Homebrew formula
  # and is built by script/setup. Skipping keeps a fresh clone from drowning in
  # failures. CI asserts the binary exists before it runs any spec, so a broken
  # build there is loud rather than quietly skipped into a green run.
  config.before(:each, :checker) do
    skip "drat-trim not built — run script/setup" unless Census::SAT::DratTrim.available?
  end
  config.order = :random
  Kernel.srand config.seed
end
