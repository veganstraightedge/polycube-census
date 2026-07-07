# frozen_string_literal: true

RSpec.describe Census::TorusSearch do
  describe "#certificate" do
    it "certifies the straight tricube at its own size" do
      straight = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      certificate = described_class.new(shape: straight).certificate
      expect(certificate[:placements].size).to eq(1)
    end

    it "labels certificates with their type" do
      straight = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      expect(described_class.new(shape: straight).certificate[:type]).to eq("torus")
    end

    it "finds the L-tricube its translations-only staircase lattice of index 3" do
      l_tricube = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]])
      certificate = described_class.new(shape: l_tricube).certificate
      lattice = Census::Lattice.new(basis: certificate[:lattice])
      expect(lattice.index).to eq(3)
    end
  end
end
