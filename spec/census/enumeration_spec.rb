# frozen_string_literal: true

RSpec.describe Census::Enumeration do
  subject(:enumeration) { described_class.new(max_size: 6) }

  describe "#shapes_of" do
    it "reproduces OEIS A000162 through n=6" do
      counts = (1..6).map { enumeration.shapes_of(it).size }
      expect(counts).to eq([1, 1, 2, 8, 29, 166])
    end

    it "orders shapes lexicographically by canonical cells" do
      cells = enumeration.shapes_of(6).map(&:cells)
      expect(cells).to eq(cells.sort)
    end

    it "puts the straight tricube before the bent one" do
      expect(enumeration.shapes_of(3).first.cells).to eq([[0, 0, 0], [0, 0, 1], [0, 0, 2]])
    end

    it "stores every shape in canonical form" do
      shapes = enumeration.shapes_of(4)
      expect(shapes.map(&:cells)).to eq(shapes.map(&:canonical_cells))
    end
  end

  describe "#mirror_classes_of" do
    it "reproduces OEIS A038119 through n=6" do
      counts = (1..6).map { enumeration.mirror_classes_of(it).size }
      expect(counts).to eq([1, 1, 2, 7, 23, 112])
    end
  end
end
