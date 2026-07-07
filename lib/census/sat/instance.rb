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

      def to_dimacs
        lines = ["p cnf #{variable_count} #{clauses.size}"]
        clauses.each { lines << "#{it.join(' ')} 0" }
        "#{lines.join("\n")}\n"
      end
    end
  end
end
