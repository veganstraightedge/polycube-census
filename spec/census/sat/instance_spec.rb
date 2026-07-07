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

  describe "#add_at_most_one" do
    it "refuses two of the constrained literals being true together" do
      instance = described_class.new
      literals = Array.new(3) { instance.new_variable }
      instance.add_at_most_one(literals)
      instance.add_clause([literals[0]])
      instance.add_clause([literals[2]])
      expect(Census::SAT::Kissat.solve(instance)).to be_nil
    end

    it "allows exactly one" do
      instance = described_class.new
      literals = Array.new(3) { instance.new_variable }
      instance.add_at_most_one(literals)
      instance.add_clause([literals[1]])
      expect(Census::SAT::Kissat.solve(instance)).not_to be_nil
    end
  end
end
