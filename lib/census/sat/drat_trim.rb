# frozen_string_literal: true

require "open3"

module Census
  module SAT
    # Checks a DRAT proof against the formula it claims to refute.
    #
    # This is what turns a volunteer's "unsat" from a claim into a result. A
    # proof means nothing apart from its formula: for a cube unit that formula
    # is the base CNF plus the cube's unit clauses, which the coordinator
    # rebuilds for itself rather than accepting one it was handed. Checking a
    # proof against a formula someone else chose would verify nothing.
    class DratTrim
      # Raised when the checker is absent. Distinguished from a proof that
      # fails, because "we could not check" and "it is wrong" are different
      # answers and must never be collapsed into one.
      class Missing < StandardError; end

      VERIFIED = "s VERIFIED"

      # drat-trim's own limit is 40000 seconds. A coordinator checking a
      # stranger's proof cannot spend eleven hours finding out it was rubbish,
      # so the limit is ours rather than the tool's.
      DEFAULT_TIMEOUT = 300

      # No Homebrew formula exists, so drat-trim is vendored and run by path.
      # CENSUS_DRAT_TRIM overrides it on a machine with its own build.
      def self.executable
        ENV.fetch("CENSUS_DRAT_TRIM", File.expand_path("../../../vendor/drat-trim/drat-trim", __dir__))
      end

      def self.available? = File.executable?(executable)

      def self.check(cnf_path:, proof_path:, timeout: DEFAULT_TIMEOUT)
        new(cnf_path:, proof_path:, timeout:).check
      end

      def initialize(cnf_path:, proof_path:, timeout: DEFAULT_TIMEOUT)
        @cnf_path = cnf_path
        @proof_path = proof_path
        @timeout = timeout
      end

      # A proof that fails to check is an answer, not an error, so this returns
      # a Result rather than raising. Only a missing checker raises.
      def check
        raise Missing, "drat-trim not found at #{self.class.executable}" unless self.class.available?

        output, status = Open3.capture2e(self.class.executable, cnf_path, proof_path, "-t", timeout.to_s)

        Result.new(output:, status: status.exitstatus)
      end

      # What the checker said, kept whole. The output is the audit trail and
      # goes into a record's provenance alongside the verdict.
      class Result
        def initialize(output:, status:)
          @output = output
          @status = status
        end

        attr_reader :output, :status

        # Read from the verdict line rather than searched for anywhere in the
        # output, so a proof carrying those bytes cannot claim its own success.
        def verified? = verdicts.include?(VERIFIED)

        def summary = verdicts.join(", ")

        private

        # drat-trim redraws its progress with carriage returns, so the verdict
        # can sit mid-line behind one. Ruby anchors ^ after newlines only.
        def verdicts = @verdicts ||= output.delete("\r").lines.grep(/^s /).map(&:chomp)
      end

      private

      attr_reader :cnf_path, :proof_path, :timeout
    end
  end
end
