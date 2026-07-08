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

      # instance_path keeps the generated CNF on disk — a DRAT proof is only
      # checkable against the exact formula it refutes.
      #
      # CENSUS_FFI=1 routes plain solves through the in-process IPASIR engine
      # (no spawn tax). Proof-capture and progress-streaming runs always use
      # the subprocess path — proofs and live statistics need it.
      def self.solve(instance, instance_path: nil, proof_path: nil, progress: nil)
        if ENV["CENSUS_FFI"] == "1" && proof_path.nil? && progress.nil?
          require_relative "ipasir"
          return IPASIR.solve(instance)
        end
        if instance_path
          File.write(instance_path, instance.to_dimacs)
          return run(instance_path, proof_path:, progress:)
        end

        Tempfile.create(["census", ".cnf"]) do |file|
          file.write(instance.to_dimacs)
          file.flush
          run(file.path, proof_path:, progress:)
        end
      end

      # With a progress IO, kissat runs un-quieted and its periodic statistics
      # lines stream there live; the verdict lines are parsed as usual.
      def self.run(path, proof_path: nil, progress: nil)
        solver = ENV.fetch("CENSUS_SOLVER", "kissat")
        command = progress ? [solver, path] : [solver, "--quiet", path]
        command << proof_path if proof_path
        return streamed(command, progress) if progress

        output, status = Open3.capture2(*command)
        verdict(status.exitstatus, output)
      end

      def self.streamed(command, progress)
        verdict_lines = []
        status = nil
        Open3.popen2(*command) do |_stdin, stdout, waiter|
          stdout.each_line do |line|
            if line.start_with?("c")
              progress.puts(line)
            else
              verdict_lines << line
            end
          end
          status = waiter.value
        end
        verdict(status.exitstatus, verdict_lines.join)
      end

      def self.verdict(exitstatus, output)
        case exitstatus
        when SATISFIABLE then true_variables(output)
        when UNSATISFIABLE then nil
        else raise "kissat failed with exit status #{exitstatus}"
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
