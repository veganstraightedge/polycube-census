# frozen_string_literal: true

RSpec.describe Census::BoxSearch do
  describe "#certificate" do
    it "finds the 1x1x3 box for the straight tricube" do
      straight = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      expect(described_class.new(shape: straight).certificate[:box]).to eq([1, 1, 3])
    end

    it "finds the 2x2x2 cube for the chiral screw tetracube" do
      screw = Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]])
      expect(described_class.new(shape: screw).certificate[:box]).to eq([2, 2, 2])
    end

    it "pairs the screw with itself, two placements in the cube" do
      screw = Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]])
      expect(described_class.new(shape: screw).certificate[:placements].size).to eq(2)
    end

    it "labels certificates with their type" do
      monocube = Census::Polycube.new(cells: [[0, 0, 0]])
      expect(described_class.new(shape: monocube).certificate[:type]).to eq("box")
    end
  end
end
