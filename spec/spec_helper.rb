# frozen_string_literal: true

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
    Census::Home::Store.new.close
  rescue StandardError => error
    skip "coordinator database unavailable (#{error.class}) — run script/home-setup"
  end
  config.order = :random
  Kernel.srand config.seed
end
