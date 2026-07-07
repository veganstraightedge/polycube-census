# frozen_string_literal: true

require "tmpdir"

RSpec.describe Census::SAT::Kissat do
  describe ".solve" do
    it "returns the true variables for a satisfiable instance" do
      instance = Census::SAT::Instance.new
      first = instance.new_variable
      second = instance.new_variable
      instance.add_clause([first, second])
      instance.add_clause([-first])
      expect(described_class.solve(instance)).to eq(Set[second])
    end

    it "returns nil for an unsatisfiable instance" do
      instance = Census::SAT::Instance.new
      only = instance.new_variable
      instance.add_clause([only])
      instance.add_clause([-only])
      expect(described_class.solve(instance)).to be_nil
    end

    it "solves identically when streaming progress" do
      instance = Census::SAT::Instance.new
      first = instance.new_variable
      second = instance.new_variable
      instance.add_clause([first, second])
      instance.add_clause([-first])
      expect(described_class.solve(instance, progress: StringIO.new)).to eq(Set[second])
    end

    it "writes a DRAT proof for an unsatisfiable instance when asked" do
      instance = Census::SAT::Instance.new
      only = instance.new_variable
      instance.add_clause([only])
      instance.add_clause([-only])
      Dir.mktmpdir do |dir|
        proof_path = File.join(dir, "refutation.drat")
        described_class.solve(instance, proof_path:)
        expect(File.size(proof_path)).to be_positive
      end
    end
  end
end
