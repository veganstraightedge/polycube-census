# frozen_string_literal: true

RSpec.describe Census::BoxTiling do
  let(:dicube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]]) }
  let(:l_tricube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]]) }
  let(:skew_tetracube) { Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [2, 1, 0]]) }

  describe "#solve" do
    it "tiles the dicube's own bounding box with one placement" do
      placements = described_class.new(shape: dicube, box: [1, 1, 2]).solve
      expect(placements.size).to eq(1)
    end

    it "places the single dicube at the origin" do
      placements = described_class.new(shape: dicube, box: [1, 1, 2]).solve
      expect(placements.first[:offset]).to eq([0, 0, 0])
    end

    it "tiles a 2x3x1 box with two L-tricubes" do
      placements = described_class.new(shape: l_tricube, box: [2, 3, 1]).solve
      expect(placements.size).to eq(2)
    end

    it "refuses the skew tetracube in a 2x4x1 box" do
      expect(described_class.new(shape: skew_tetracube, box: [2, 4, 1]).solve).to be_nil
    end

    it "refuses boxes whose volume is not a multiple of the shape size" do
      expect(described_class.new(shape: dicube, box: [1, 1, 3]).solve).to be_nil
    end
  end
end
