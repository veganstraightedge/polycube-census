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

    # Solving one lattice per rotation orbit suffices: rotating a whole tiling
    # by R turns a tiling on L into one on R(L), and all 24 orientations of the
    # shape are allowed anyway.
    def self.orbit_representatives_of_index(index)
      all_of_index(index).group_by(&:orbit_key).values.map(&:first)
    end

    # Canonical lower-triangular Hermite normal form of any integer basis:
    # positive diagonal, off-diagonals reduced modulo their column's diagonal.
    def self.hermite_normal_form(rows)
      rows = rows.map(&:dup)
      2.downto(0) { |column| clear_column(rows, column) }
      reduce_shears(rows)
      rows
    end

    def self.clear_column(rows, column)
      active = (0..column).to_a
      loop do
        nonzero = active.select { rows[it][column] != 0 }
        pivot = nonzero.min_by { rows[it][column].abs }
        others = nonzero - [pivot]
        if others.empty?
          rows[pivot], rows[column] = rows[column], rows[pivot]
          rows[column] = rows[column].map { -it } if rows[column][column].negative?
          break
        end
        others.each do |row|
          quotient = rows[row][column].div(rows[pivot][column])
          rows[row] = subtract(rows[row], rows[pivot], quotient)
        end
      end
    end

    def self.reduce_shears(rows)
      rows[2] = subtract(rows[2], rows[1], rows[2][1].div(rows[1][1]))
      rows[1] = subtract(rows[1], rows[0], rows[1][0].div(rows[0][0]))
      rows[2] = subtract(rows[2], rows[0], rows[2][0].div(rows[0][0]))
    end

    def self.subtract(row, other, quotient)
      row.each_index.map { row[it] - (quotient * other[it]) }
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

    def orbit_key
      @orbit_key ||= Rotation.all
                             .map { |rotation| self.class.hermite_normal_form(basis.map { rotation.apply(it) }) }
                             .min
    end

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
