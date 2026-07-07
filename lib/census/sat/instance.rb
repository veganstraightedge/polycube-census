# frozen_string_literal: true

module Census
  module SAT
    # A CNF (conjunctive normal form) formula under construction: variables are
    # positive integers, clauses are arrays of literals (negative = negated).
    class Instance
      attr_reader :variable_count, :clauses

      def initialize
        @variable_count = 0
        @clauses = []
      end

      def new_variable = @variable_count += 1

      def add_clause(literals) = clauses << literals

      # Sinz sequential at-most-one: linear clauses via register variables,
      # instead of the quadratic pairwise encoding.
      def add_at_most_one(literals)
        return if literals.size < 2
        return add_clause([-literals[0], -literals[1]]) if literals.size == 2

        registers = Array.new(literals.size - 1) { new_variable }
        add_clause([-literals[0], registers[0]])
        (1...(literals.size - 1)).each do |position|
          add_clause([-literals[position], registers[position]])
          add_clause([-registers[position - 1], registers[position]])
          add_clause([-literals[position], -registers[position - 1]])
        end
        add_clause([-literals.last, -registers.last])
      end

      def to_dimacs
        lines = ["p cnf #{variable_count} #{clauses.size}"]
        clauses.each { lines << "#{it.join(' ')} 0" }
        "#{lines.join("\n")}\n"
      end
    end
  end
end
