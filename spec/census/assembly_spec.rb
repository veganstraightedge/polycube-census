# frozen_string_literal: true

RSpec.describe Census::Assembly do
  describe ".groups_for" do
    it "makes one group per placement for a box certificate" do
      dicube = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]])
      certificate = Census::BoxSearch.new(shape: dicube).certificate
      groups = described_class.groups_for(certificate:, shape: dicube)
      expect(groups.size).to eq(1)
    end

    it "replicates torus placements across eight lattice translates" do
      straight = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      certificate = Census::TorusSearch.new(shape: straight).certificate
      groups = described_class.groups_for(certificate:, shape: straight)
      expect(groups.size).to eq(8)
    end

    it "keeps replicated copies disjoint" do
      straight = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]])
      certificate = Census::TorusSearch.new(shape: straight).certificate
      cells = described_class.groups_for(certificate:, shape: straight).flat_map { it[:cells] }
      expect(cells.uniq.size).to eq(cells.size)
    end
  end
end
