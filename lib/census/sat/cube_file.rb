# frozen_string_literal: true

module Census
  module SAT
    # A march-style iCNF cube file: one "a <literal>... 0" line per cube, each
    # cube a partial assignment splitting the formula into an easier
    # sub-problem. The cubes jointly cover all assignments, so every cube
    # UNSAT refutes the formula, and any cube SAT satisfies it.
    class CubeFile
      def initialize(path:)
        @path = path
      end

      def cubes
        @cubes ||= File.readlines(@path).filter_map do |line|
          parts = line.split
          parts[1..-2].map { Integer(it) } if parts.first == "a"
        end
      end

      # Stream the original formula with the cube appended as unit clauses,
      # header adjusted — never materializes a copy of the (possibly huge)
      # formula in memory or on disk.
      def self.stream_augmented(cnf_path:, cube:, io:)
        File.open(cnf_path) do |cnf|
          header = cnf.readline
          variables, clauses = header.split.last(2).map { Integer(it) }
          io.write("p cnf #{variables} #{clauses + cube.size}\n")
          IO.copy_stream(cnf, io)
          cube.each { io.write("#{it} 0\n") }
        end
      end
    end
  end
end
