# frozen_string_literal: true

RSpec.describe Census::Polycube do
  let(:monocube) { described_class.new(cells: [[0, 0, 0]]) }
  let(:dicube) { described_class.new(cells: [[0, 0, 0], [0, 0, 1]]) }
  let(:l_tricube) { described_class.new(cells: [[0, 0, 0], [1, 0, 0], [0, 1, 0]]) }
  let(:screw_tetracube) { described_class.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]]) }

  describe "#cells" do
    it "normalizes to the origin corner and sorts" do
      shifted = described_class.new(cells: [[5, 6, 5], [5, 5, 5], [6, 5, 5]])
      expect(shifted.cells).to eq([[0, 0, 0], [0, 1, 0], [1, 0, 0]])
    end
  end

  describe "#canonical_cells" do
    it "is identical across all orientations of the same shape" do
      forms = Census::Rotation.all.map { l_tricube.rotated(it).canonical_cells }
      expect(forms.uniq.size).to eq(1)
    end

    it "distinguishes different shapes" do
      straight = described_class.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      bent = described_class.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]])
      expect(straight.canonical_cells).not_to eq(bent.canonical_cells)
    end
  end

  describe "#symmetry_order" do
    it "is 24 for the monocube" do
      expect(monocube.symmetry_order).to eq(24)
    end

    it "is 8 for the dicube" do
      expect(dicube.symmetry_order).to eq(8)
    end

    it "is 2 for the L-tricube" do
      expect(l_tricube.symmetry_order).to eq(2)
    end
  end

  describe "#chiral?" do
    it "is false for planar shapes" do
      expect(l_tricube).not_to be_chiral
    end

    it "is true for the screw tetracube" do
      expect(screw_tetracube).to be_chiral
    end
  end

  describe "#mirror" do
    it "is an unreachable shape for chiral polycubes" do
      expect(screw_tetracube.mirror.canonical_cells).not_to eq(screw_tetracube.canonical_cells)
    end

    it "round-trips back to the original" do
      expect(screw_tetracube.mirror.mirror.canonical_cells).to eq(screw_tetracube.canonical_cells)
    end
  end

  describe "#growths" do
    it "grows the monocube in six directions" do
      expect(monocube.growths.size).to eq(6)
    end

    it "grows the monocube into the dicube every time" do
      expect(monocube.growths.map(&:canonical_cells).uniq.size).to eq(1)
    end

    it "only adds face-adjacent cells" do
      grown_sizes = l_tricube.growths.map { it.cells.size }
      expect(grown_sizes).to all(eq(4))
    end
  end
end
