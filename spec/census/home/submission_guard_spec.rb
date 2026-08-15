# frozen_string_literal: true

RSpec.describe Census::Home::SubmissionGuard do
  def rejection(payload, verdict: "tiler")
    described_class.new(payload:, verdict:).rejection
  end

  it "passes a plausible certificate" do
    certificate = { placements: [{ rotation: 0, offset: [0, 0, 0] }] }
    expect(rejection({ certificate: })).to be_nil
  end

  it "refuses a certificate with more placements than any real tiling" do
    placements = Array.new(described_class::MAX_PLACEMENTS + 1) { { rotation: 0, offset: [0, 0, 0] } }
    expect(rejection({ certificate: { placements: } })).to match(/too many placements/)
  end

  it "refuses coordinates far outside any plausible region" do
    certificate = { placements: [{ rotation: 0, offset: [0, 0, 10**9] }] }
    expect(rejection({ certificate: })).to match(/coordinate out of range/)
  end

  it "refuses a malformed placement" do
    expect(rejection({ certificate: { placements: ["not a placement"] } })).to match(/malformed placement/)
  end

  it "refuses a missing certificate" do
    expect(rejection({})).to match(/certificate missing/)
  end

  it "refuses an absurd model" do
    model = Array.new(described_class::MAX_MODEL_LITERALS + 1, 1)
    expect(rejection({ model: }, verdict: "sat")).to match(/model too large/)
  end

  it "ignores verdicts that carry no attack surface" do
    expect(rejection({}, verdict: "exhausted")).to be_nil
  end
end
