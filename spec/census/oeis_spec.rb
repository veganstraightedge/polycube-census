# frozen_string_literal: true

RSpec.describe Census::Oeis do
  it "records A000162 through n=8" do
    expect(described_class::A000162.size).to eq(8)
  end

  it "records A038119 through n=8" do
    expect(described_class::A038119.size).to eq(8)
  end
end
