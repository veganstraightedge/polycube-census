# frozen_string_literal: true

RSpec.describe Census::SAT::Instance do
  describe "#to_dimacs" do
    it "renders the standard DIMACS header and clauses" do
      instance = described_class.new
      first = instance.new_variable
      second = instance.new_variable
      instance.add_clause([first, second])
      instance.add_clause([-first])
      expect(instance.to_dimacs).to eq("p cnf 2 2\n1 2 0\n-1 0\n")
    end
  end
end
