# frozen_string_literal: true

RSpec.describe Census::TorusTiling do
  let(:dicube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]]) }
  let(:straight_tricube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]]) }
  let(:l_tricube) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]]) }

  describe "#solve" do
    it "tiles the dicube on the doubled-z lattice with one placement" do
      lattice = Census::Lattice.new(basis: [[1, 0, 0], [0, 1, 0], [0, 0, 2]])
      expect(described_class.new(lattice:, shape: dicube).solve.size).to eq(1)
    end

    it "discards self-overlapping placements but still finds the straight one" do
      lattice = Census::Lattice.new(basis: [[2, 0, 0], [0, 1, 0], [0, 0, 1]])
      expect(described_class.new(lattice:, shape: dicube).solve.size).to eq(1)
    end

    it "tiles the straight tricube on a sheared lattice" do
      lattice = Census::Lattice.new(basis: [[3, 0, 0], [1, 1, 0], [0, 0, 1]])
      expect(described_class.new(lattice:, shape: straight_tricube).solve.size).to eq(1)
    end

    it "refuses the L-tricube on a one-dimensional quotient" do
      lattice = Census::Lattice.new(basis: [[3, 0, 0], [0, 1, 0], [0, 0, 1]])
      expect(described_class.new(lattice:, shape: l_tricube).solve).to be_nil
    end

    it "refuses lattices whose index the shape size does not divide" do
      lattice = Census::Lattice.new(basis: [[3, 0, 0], [0, 1, 0], [0, 0, 1]])
      expect(described_class.new(lattice:, shape: dicube).solve).to be_nil
    end
  end
end
