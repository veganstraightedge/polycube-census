# frozen_string_literal: true

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
  end
end
