# frozen_string_literal: true

module Census
  # The surround test (corona 1): can copies of the shape completely enclose
  # one fixed seed copy — covering every cell that touches it by face, edge,
  # or corner — without overlapping the seed or each other? UNSAT means
  # Heesch number 0: a certified non-tiler.
  class Surround
    NEIGHBOR_STEPS = [-1, 0, 1].product([-1, 0, 1], [-1, 0, 1])
                               .reject { |step| step == [0, 0, 0] }.freeze

    def initialize(shape:)
      @shape = shape
    end

    def solve(proof_path: nil)
      instance = SAT::Instance.new
      variables = placements.map { instance.new_variable }
      coverage_clauses(instance, variables)
      overlap_clauses(instance, variables)
      model = SAT::Kissat.solve(instance, proof_path:)
      model && chosen(variables, model)
    end

    def verified?(chosen_placements)
      cells = chosen_placements.flat_map { it[:cells] }
      no_overlaps = cells.uniq.size == cells.size
      seed_untouched = (cells & shape.cells).empty?
      frontier_covered = (frontier - cells).empty?
      no_overlaps && seed_untouched && frontier_covered
    end

    def frontier
      @frontier ||= begin
        occupied = shape.cells.to_set
        shape.cells.flat_map { neighbors_of(it) }.uniq.reject { occupied.include?(it) }.sort
      end
    end

    def placements
      @placements ||= shape.unique_orientations.flat_map do |cells, rotation|
        offsets_for(cells).filter_map do |offset|
          placed = cells.map { |cell| cell.zip(offset).map(&:sum) }
          { rotation:, offset:, cells: placed } if useful?(placed)
        end
      end
    end

    private

    attr_reader :shape

    def neighbors_of(cell)
      NEIGHBOR_STEPS.map { |step| cell.zip(step).map(&:sum) }
    end

    # A placement matters only if it avoids the seed and covers frontier;
    # covering frontier already implies touching the seed.
    def useful?(placed)
      placed.none? { seed_cells.include?(it) } && placed.any? { frontier_cells.include?(it) }
    end

    def seed_cells = @seed_cells ||= shape.cells.to_set

    def frontier_cells = @frontier_cells ||= frontier.to_set

    def offsets_for(cells)
      extents = cells.transpose.map(&:max)
      seed_extents = shape.cells.transpose.map(&:max)
      ranges = extents.zip(seed_extents).map { |extent, seed_extent| ((-extent - 1)..(seed_extent + 1)).to_a }
      ranges[0].product(ranges[1], ranges[2])
    end

    def coverage_clauses(instance, variables)
      frontier.each do |cell|
        covering = placements.each_index.select { placements[it][:cells].include?(cell) }
        instance.add_clause(covering.map { variables[it] })
      end
    end

    def overlap_clauses(instance, variables)
      by_cell = Hash.new { |hash, key| hash[key] = [] }
      placements.each_with_index { |placement, index| placement[:cells].each { by_cell[it] << variables[index] } }
      pairs = Set.new
      by_cell.each_value { |cell_variables| cell_variables.combination(2) { pairs << it.sort } }
      pairs.each { |one, other| instance.add_clause([-one, -other]) }
    end

    def chosen(variables, model)
      placements.zip(variables)
                .select { |_placement, variable| model.include?(variable) }
                .map(&:first)
    end
  end
end
