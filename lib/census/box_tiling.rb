# frozen_string_literal: true

module Census
  # Can copies of one shape fill an a×b×c box? One SAT variable per placement,
  # every box cell covered exactly once. Returns the chosen placements
  # (rotation index + offset) or nil.
  class BoxTiling
    def initialize(box:, shape:)
      @box = box
      @shape = shape
    end

    def solve
      return nil unless volume_divisible?

      SAT::ExactCover.new(placements: all_placements, universe: box_cells).solve
    end

    private

    attr_reader :box, :shape

    def volume_divisible? = (box.reduce(:*) % shape.size).zero?

    def all_placements
      shape.unique_orientations.flat_map { |cells, rotation| placements_of(cells, rotation) }
    end

    def placements_of(cells, rotation)
      offset_ranges = offset_ranges_for(cells)
      return [] if offset_ranges.any?(&:empty?)

      offset_ranges[0].product(offset_ranges[1], offset_ranges[2]).map do |offset|
        { rotation:, offset:, cells: cells.map { |cell| cell.zip(offset).map(&:sum) } }
      end
    end

    def offset_ranges_for(cells)
      cells.transpose.map(&:max).zip(box).map { |extent, limit| (0..(limit - 1 - extent)).to_a }
    end

    def box_cells
      (0...box[0]).to_a.product((0...box[1]).to_a, (0...box[2]).to_a)
    end
  end
end
