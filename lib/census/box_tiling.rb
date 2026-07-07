# frozen_string_literal: true

module Census
  # Can copies of one shape fill an a×b×c box? Encoded as exact cover:
  # one SAT variable per placement, every box cell covered exactly once.
  # Returns the chosen placements (rotation index + offset) or nil.
  class BoxTiling
    def initialize(box:, shape:)
      @box = box
      @shape = shape
    end

    def solve
      return nil unless volume_divisible?

      placements = all_placements
      return nil if placements.empty?

      solve_instance(placements)
    end

    private

    attr_reader :box, :shape

    def volume_divisible? = (box.reduce(:*) % shape.size).zero?

    def all_placements
      unique_orientations.flat_map { |cells, rotation| placements_of(cells, rotation) }
    end

    def unique_orientations
      first_rotation_by_cells = {}
      Rotation.all.each_with_index do |rotation, index|
        first_rotation_by_cells[shape.rotated(rotation).cells] ||= index
      end
      first_rotation_by_cells.to_a
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

    def solve_instance(placements)
      instance = SAT::Instance.new
      variables = placements.map { instance.new_variable }
      covering = covering_variables(placements, variables)
      return nil if covering.any? { |_cell, covering_variables| covering_variables.empty? }

      add_clauses(instance, covering)
      model = SAT::Kissat.solve(instance)
      model && chosen(placements, variables, model)
    end

    def covering_variables(placements, variables)
      covering = box_cells.to_h { [it, []] }
      placements.each_with_index do |placement, position|
        placement[:cells].each { covering.fetch(it) << variables[position] }
      end
      covering
    end

    def box_cells
      (0...box[0]).to_a.product((0...box[1]).to_a, (0...box[2]).to_a)
    end

    def add_clauses(instance, covering)
      covering.each_value { instance.add_clause(it) }
      overlapping_pairs(covering).each { |one, other| instance.add_clause([-one, -other]) }
    end

    def overlapping_pairs(covering)
      pairs = Set.new
      covering.each_value do |cell_variables|
        cell_variables.combination(2) { pairs << it.sort }
      end
      pairs
    end

    def chosen(placements, variables, model)
      placements.zip(variables)
                .select { |_placement, variable| model.include?(variable) }
                .map { |placement, _variable| placement.slice(:rotation, :offset) }
    end
  end
end
