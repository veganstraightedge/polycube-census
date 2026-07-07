# frozen_string_literal: true

require "open3"
require "tempfile"

module Census
  module SAT
    # Runs the kissat solver on an Instance. Returns the set of true variables
    # for a satisfiable instance, nil for an unsatisfiable one.
    class Kissat
      SATISFIABLE = 10
      UNSATISFIABLE = 20

      def self.solve(instance, proof_path: nil)
        Tempfile.create(["census", ".cnf"]) do |file|
          file.write(instance.to_dimacs)
          file.flush
          run(file.path, proof_path:)
        end
      end

      def self.run(path, proof_path: nil)
        command = ["kissat", "--quiet", path]
        command << proof_path if proof_path
        output, status = Open3.capture2(*command)
        case status.exitstatus
        when SATISFIABLE then true_variables(output)
        when UNSATISFIABLE then nil
        else raise "kissat failed with exit status #{status.exitstatus}"
        end
      end

      def self.true_variables(output)
        output.lines
              .select { it.start_with?("v ") }
              .flat_map { it.split.drop(1) }
              .map { Integer(it) }
              .select(&:positive?)
              .to_set
      end
    end
  end
end
