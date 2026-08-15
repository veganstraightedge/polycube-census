# frozen_string_literal: true

RSpec.describe Census::AtHome::Client do
  # A port nothing is listening on: the coordinator having died, from the
  # client's point of view.
  let(:dead_url) { "http://127.0.0.1:9" }

  it "retries a dead coordinator instead of crashing, then stops cleanly" do
    notes = []
    client = described_class.new(url: dead_url, handle: "spec", give_up_after: 2,
                                 report: ->(line) { notes << line })

    tally = nil
    expect { tally = client.run(once: true) }.not_to raise_error
    expect(tally).to eq({ "stopped" => 1 })
    expect(notes.first).to match(/coordinator unavailable/)
    expect(notes.last).to match(/still unreachable/)
  end

  it "backs off between attempts rather than hammering" do
    client = described_class.new(url: dead_url, handle: "spec", give_up_after: 4)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    client.run(once: true)
    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be >= 1
  end

  it "treats throttling and coordinator errors as worth retrying" do
    expect(described_class::TRANSIENT_ERRORS).to include(Errno::ECONNREFUSED, Net::ReadTimeout)
    expect(Census::AtHome::TransientResponse.ancestors).to include(StandardError)
  end

  it "reports solved-but-unreportable work instead of discarding it silently" do
    client = described_class.new(url: dead_url, handle: "spec", give_up_after: 1)
    # Register succeeds, leasing succeeds, submission is what fails.
    allow(client).to receive(:post).and_return({ client: { id: 1 } },
                                               { unit: { id: 7, kind: "shape", shape_id: "3/1",
                                                         cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]], budgets: {} } },
                                               nil)
    notes = []
    client.instance_variable_set(:@report, ->(line) { notes << line })

    expect(client.run(once: true)).to eq({ "stopped" => 1 })
    expect(notes.last).to match(/UNREPORTED/)
  end
end
