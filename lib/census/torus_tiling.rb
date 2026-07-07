# frozen_string_literal: true

module Census
  # Can copies of one shape tile the quotient Z^3/L? A solution lifts to an
  # L-periodic tiling of all of space. Placements whose cells collide on the
  # quotient (the copy wrapping around onto itself) are discarded up front.
  class TorusTiling
    def initialize(lattice:, shape:)
      @lattice = lattice
      @shape = shape
    end

    def solve
      return nil unless volume_divisible?

      SAT::ExactCover.new(placements: all_placements, universe: lattice.quotient_cells).solve
    end

    private

    attr_reader :lattice, :shape

    def volume_divisible? = (lattice.index % shape.size).zero?

    def all_placements
      shape.unique_orientations.flat_map { |cells, rotation| placements_of(cells, rotation) }
    end

    def placements_of(cells, rotation)
      lattice.quotient_cells.filter_map do |offset|
        covered = cells.map { |cell| lattice.reduce(cell.zip(offset).map(&:sum)) }
        { rotation:, offset:, cells: covered } if covered.uniq.size == covered.size
      end
    end
  end
end
