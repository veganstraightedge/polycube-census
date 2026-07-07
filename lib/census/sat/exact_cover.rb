# frozen_string_literal: true

module Census
  module SAT
    # Exact cover via SAT: choose placements so that every universe cell is
    # covered exactly once. Each placement is a hash with :cells plus whatever
    # identifying fields the caller wants back. Returns the chosen placements
    # (without :cells) or nil.
    class ExactCover
      def initialize(placements:, universe:)
        @placements = placements
        @universe = universe
      end

      def solve
        return nil if placements.empty?

        instance = Instance.new
        variables = placements.map { instance.new_variable }
        covering = covering_variables(variables)
        return nil if covering.any? { |_cell, cell_variables| cell_variables.empty? }

        add_clauses(instance, covering)
        model = Kissat.solve(instance)
        model && chosen(variables, model)
      end

      private

      attr_reader :placements, :universe

      def covering_variables(variables)
        covering = universe.to_h { [it, []] }
        placements.each_with_index do |placement, position|
          placement[:cells].each { covering.fetch(it) << variables[position] }
        end
        covering
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

      def chosen(variables, model)
        placements.zip(variables)
                  .select { |_placement, variable| model.include?(variable) }
                  .map { |placement, _variable| placement.except(:cells) }
      end
    end
  end
end
