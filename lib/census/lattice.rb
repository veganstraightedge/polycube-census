# frozen_string_literal: true

module Census
  # A full-rank sublattice of Z^3 in lower-triangular Hermite normal form.
  # Basis rows: (a,0,0), (b,c,0), (d,e,f) with reduced shears. The quotient
  # Z^3/L keeps one representative per cell of the a×c×f diagonal box, so a
  # tiling of the quotient lifts to an L-periodic tiling of space.
  class Lattice
    def self.all_of_index(index)
      diagonal_triples(index).flat_map do |a, c, f|
        (0...a).flat_map do |b|
          (0...a).flat_map do |d|
            (0...c).map { |e| new(basis: [[a, 0, 0], [b, c, 0], [d, e, f]]) }
          end
        end
      end
    end

    def self.diagonal_triples(index)
      (1..index).select { (index % it).zero? }.flat_map do |a|
        remainder = index / a
        (1..remainder).select { (remainder % it).zero? }.map { |c| [a, c, remainder / c] }
      end
    end

    attr_reader :basis

    def initialize(basis:)
      @basis = basis
    end

    def index = basis[0][0] * basis[1][1] * basis[2][2]

    def reduce(cell)
      x, y, z = cell
      first, second, third = basis

      turns = z.div(third[2])
      x -= turns * third[0]
      y -= turns * third[1]
      z -= turns * third[2]

      turns = y.div(second[1])
      x -= turns * second[0]
      y -= turns * second[1]

      [x % first[0], y, z]
    end

    def quotient_cells
      (0...basis[0][0]).to_a.product((0...basis[1][1]).to_a, (0...basis[2][2]).to_a)
    end
  end
end
