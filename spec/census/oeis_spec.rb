# frozen_string_literal: true

RSpec.describe Census::OEIS do
  it "records A000162 through n=12" do
    expect(described_class::A000162.size).to eq(12)
  end

  it "records A038119 through n=12" do
    expect(described_class::A038119.size).to eq(12)
  end
end
