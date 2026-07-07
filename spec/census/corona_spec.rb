# frozen_string_literal: true

RSpec.describe Census::Corona do
  let(:dicube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]]) }

  describe "#solve" do
    it "builds two complete coronas around the dicube" do
      corona = described_class.new(depth: 2, shape: dicube)
      witness = corona.solve
      expect(witness.keys).to eq([1, 2])
    end

    it "produces a witness that survives verification" do
      corona = described_class.new(depth: 2, shape: dicube)
      expect(corona.verified?(corona.solve)).to be(true)
    end
  end

  describe "#verified?" do
    it "rejects a witness with the second corona thinned" do
      corona = described_class.new(depth: 2, shape: dicube)
      witness = corona.solve
      thinned = witness.merge(2 => witness[2].drop(2))
      expect(corona.verified?(thinned)).to be(false)
    end
  end
end
