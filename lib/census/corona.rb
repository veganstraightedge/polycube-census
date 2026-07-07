# frozen_string_literal: true

module Census
  # The depth-k corona test: seed fixed at the origin, then k complete layers —
  # every cell touching the configuration through layer i-1 (faces, edges,
  # corners) is covered by layer <= i, layers pairwise disjoint, and each
  # layer-i copy touches a chosen layer-(i-1) copy. UNSAT at depth k with SAT
  # at depth k-1 pins the Heesch number to exactly k-1 — a certified non-tiler.
  #
  # Convention (PLAN D3): adjacency is 26-neighborhood throughout; a layer-i
  # copy may touch the seed as long as it is anchored to layer i-1.
  class Corona
    def initialize(depth:, shape:)
      @depth = depth
      @shape = shape
    end

    def solve(proof_path: nil)
      build
      model = SAT::Kissat.solve(@instance, proof_path:)
      model && witness(model)
    end

    def verified?(witness)
      return false unless witness

      all_placed = witness.values.flatten.flat_map { it[:cells] }
      disjoint = all_placed.uniq.size == all_placed.size && (all_placed & shape.cells).empty?
      disjoint && frontier_covered?(witness) && anchored?(witness) && complete?(witness)
    end

    def universes
      @universes ||= (1..depth).each_with_object({}) do |level, universes|
        region = if level == 1
                   seed_frontier
                 else
                   previous = universes.fetch(level - 1).flat_map { it[:cells] }.uniq
                   (previous + previous.flat_map { neighbors_of(it) }).uniq - shape.cells
                 end
        universes[level] = placements_touching(region)
      end
    end

    private

    attr_reader :depth, :shape

    def build
      @instance = SAT::Instance.new
      @variables = universes.transform_values { |placements| placements.map { @instance.new_variable } }
      seed_frontier_clauses
      at_most_one_per_cell
      anchoring_clauses
      completeness_clauses
    end

    def seed_frontier_clauses
      cover = cover_map(1)
      seed_frontier.each { @instance.add_clause(cover.fetch(it, [])) }
    end

    def at_most_one_per_cell
      by_cell = Hash.new { |hash, key| hash[key] = [] }
      universes.each do |level, placements|
        placements.each_with_index do |placement, position|
          placement[:cells].each { by_cell[it] << @variables[level][position] }
        end
      end
      by_cell.each_value { @instance.add_at_most_one(it) }
    end

    def anchoring_clauses
      (2..depth).each do |level|
        previous_cover = cover_map(level - 1)
        universes[level].each_with_index do |placement, position|
          anchors = placement[:cells]
                    .flat_map { neighbors_of(it) }.uniq
                    .flat_map { previous_cover.fetch(it, []) }.uniq
          @instance.add_clause([-@variables[level][position]] + anchors)
        end
      end
    end

    def completeness_clauses
      (2..depth).each do |level|
        coverers = (1..level).map { cover_map(it) }
        universes[level - 1].each_with_index do |placement, position|
          variable = @variables[level - 1][position]
          obligation_cells(placement).each do |cell|
            covering = coverers.flat_map { it.fetch(cell, []) }
            @instance.add_clause([-variable] + covering)
          end
        end
      end
    end

    def obligation_cells(placement)
      placement[:cells].flat_map { neighbors_of(it) }.uniq - shape.cells - placement[:cells]
    end

    def cover_map(level)
      @cover_maps ||= {}
      @cover_maps[level] ||= begin
        map = Hash.new { |hash, key| hash[key] = [] }
        universes[level].each_with_index do |placement, position|
          placement[:cells].each { map[it] << @variables[level][position] }
        end
        map
      end
    end

    def seed_frontier
      @seed_frontier ||= begin
        occupied = shape.cells.to_set
        shape.cells.flat_map { neighbors_of(it) }.uniq.reject { occupied.include?(it) }.sort
      end
    end

    def placements_touching(region_cells)
      region = region_cells.to_set
      minimums = region_cells.transpose.map(&:min)
      maximums = region_cells.transpose.map(&:max)
      shape.unique_orientations.flat_map do |cells, rotation|
        extents = cells.transpose.map(&:max)
        ranges = (0..2).map { ((minimums[it] - extents[it])..maximums[it]).to_a }
        ranges[0].product(ranges[1], ranges[2]).filter_map do |offset|
          placed = cells.map { |cell| cell.zip(offset).map(&:sum) }
          next if placed.any? { seed_cells.include?(it) }

          { rotation:, offset:, cells: placed } if placed.any? { region.include?(it) }
        end
      end
    end

    def seed_cells = @seed_cells ||= shape.cells.to_set

    def neighbors_of(cell)
      Surround::NEIGHBOR_STEPS.map { |step| cell.zip(step).map(&:sum) }
    end

    def witness(model)
      universes.to_h do |level, placements|
        chosen = placements.each_index
                           .select { model.include?(@variables[level][it]) }
                           .map { placements[it] }
        [level, chosen]
      end
    end

    def frontier_covered?(witness)
      covered = witness.fetch(1).flat_map { it[:cells] }.to_set
      seed_frontier.all? { covered.include?(it) }
    end

    def anchored?(witness)
      (2..depth).all? do |level|
        previous = witness.fetch(level - 1).flat_map { it[:cells] }.to_set
        witness.fetch(level).all? do |placement|
          placement[:cells].flat_map { neighbors_of(it) }.any? { previous.include?(it) }
        end
      end
    end

    def complete?(witness)
      (2..depth).all? do |level|
        allowed = (seed_cells + (1..level).flat_map { witness.fetch(it) }.flat_map { it[:cells] }).to_set
        witness.fetch(level - 1).all? do |placement|
          obligation_cells(placement).all? { allowed.include?(it) }
        end
      end
    end
  end
end
