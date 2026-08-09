# frozen_string_literal: true

module Census
  # Finds a periodic tiling by trying every sublattice of Z^3 in increasing
  # index (multiples of the shape's size). Returns a torus certificate or nil.
  # min_index skips indices already exhausted by an earlier run.
  class TorusSearch
    DEFAULT_MAX_INDEX = 48

    def initialize(shape:, max_index: DEFAULT_MAX_INDEX, min_index: 0)
      @shape = shape
      @max_index = max_index
      @min_index = min_index
    end

    def certificate
      indices.each do |index|
        Lattice.orbit_representatives_of_index(index).each do |lattice|
          placements = TorusTiling.new(lattice:, shape:).solve
          return { type: "torus", lattice: lattice.basis, placements: } if placements
        end
      end
      nil
    end

    private

    attr_reader :max_index, :min_index, :shape

    def indices = (shape.size..max_index).step(shape.size).reject { it <= min_index }
  end
end
