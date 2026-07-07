# frozen_string_literal: true

RSpec.describe Census::OBJ do
  describe ".assembly" do
    it "renders one closed solid per group" do
      result = described_class.assembly(groups: [{ name: "seed", cells: [[0, 0, 0], [0, 0, 1]] }])
      expect(result[:obj].scan(/^f /).size).to eq(10)
    end

    it "assigns each group its own material" do
      groups = [
        { name: "one", cells: [[0, 0, 0]] },
        { name: "two", cells: [[1, 0, 0]] }
      ]
      result = described_class.assembly(groups:)
      expect(result[:obj].scan(/^usemtl /).size).to eq(2)
    end

    it "defines every used material in the mtl" do
      groups = [
        { name: "one", cells: [[0, 0, 0]] },
        { name: "two", cells: [[1, 0, 0]] }
      ]
      result = described_class.assembly(groups:)
      expect(result[:mtl].scan(/^newmtl /).size).to eq(2)
    end

    it "keeps faces between different copies" do
      groups = [
        { name: "one", cells: [[0, 0, 0]] },
        { name: "two", cells: [[1, 0, 0]] }
      ]
      result = described_class.assembly(groups:)
      expect(result[:obj].scan(/^f /).size).to eq(12)
    end
  end
end
