# frozen_string_literal: true

RSpec.describe Census::Lattice do
  describe ".all_of_index" do
    it "finds the 7 sublattices of index 2" do
      expect(described_class.all_of_index(2).size).to eq(7)
    end

    it "finds the 35 sublattices of index 4" do
      expect(described_class.all_of_index(4).size).to eq(35)
    end

    it "gives every lattice the requested index" do
      expect(described_class.all_of_index(6).map(&:index)).to all(eq(6))
    end
  end

  describe "#reduce" do
    it "wraps coordinates into the diagonal box" do
      doubled = described_class.new(basis: [[2, 0, 0], [0, 2, 0], [0, 0, 2]])
      expect(doubled.reduce([3, -1, 5])).to eq([1, 1, 1])
    end

    it "applies shears before wrapping" do
      sheared = described_class.new(basis: [[2, 0, 0], [1, 1, 0], [0, 0, 1]])
      expect(sheared.reduce([0, 1, 0])).to eq([1, 0, 0])
    end

    it "fixes points already inside the box" do
      lattice = described_class.new(basis: [[3, 0, 0], [1, 1, 0], [0, 0, 1]])
      expect(lattice.reduce([2, 0, 0])).to eq([2, 0, 0])
    end
  end

  describe "#quotient_cells" do
    it "spans the diagonal box" do
      lattice = described_class.new(basis: [[2, 0, 0], [0, 1, 0], [0, 0, 2]])
      expect(lattice.quotient_cells).to eq([[0, 0, 0], [0, 0, 1], [1, 0, 0], [1, 0, 1]])
    end
  end
end
