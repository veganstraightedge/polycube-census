# frozen_string_literal: true

require "tmpdir"

RSpec.describe Census::SAT::CubeFile do
  describe "#cubes" do
    it "parses march-style iCNF cube lines" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "cubes.icnf")
        File.write(path, "a 1 -2 0\na -3 0\n")
        expect(described_class.new(path:).cubes).to eq([[1, -2], [-3]])
      end
    end

    it "ignores non-cube lines" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "cubes.icnf")
        File.write(path, "c comment\na 4 0\n")
        expect(described_class.new(path:).cubes).to eq([[4]])
      end
    end
  end

  describe ".stream_augmented" do
    it "writes the formula with an adjusted header and the cube as unit clauses" do
      Dir.mktmpdir do |dir|
        cnf = File.join(dir, "formula.cnf")
        File.write(cnf, "p cnf 3 2\n1 2 0\n-1 3 0\n")
        io = StringIO.new
        described_class.stream_augmented(cnf_path: cnf, cube: [2, -3], io:)
        expect(io.string).to eq("p cnf 3 4\n1 2 0\n-1 3 0\n2 0\n-3 0\n")
      end
    end
  end
end
