# frozen_string_literal: true

RSpec.describe Census::STL do
  describe ".model" do
    it "renders the monocube byte-identical to the fixture" do
      model = described_class.model(cells: [[0, 0, 0]], name: "monocube")
      expect(model).to eq(File.read("spec/fixtures/monocube.stl"))
    end

    it "culls the shared face of the dicube" do
      model = described_class.model(cells: [[0, 0, 0], [0, 0, 1]], name: "dicube")
      expect(model.scan("facet normal").size).to eq(20)
    end

    it "culls both shared faces of the L-tricube" do
      model = described_class.model(cells: [[0, 0, 0], [1, 0, 0], [0, 1, 0]], name: "l")
      expect(model.scan("facet normal").size).to eq((3 * 12) - (2 * 2 * 2))
    end
  end
end
