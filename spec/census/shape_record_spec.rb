# frozen_string_literal: true

RSpec.describe Census::ShapeRecord do
  describe "#to_json_document" do
    it "matches the fixture for the L-tricube" do
      l_tricube = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]])
      record = described_class.new(shape: l_tricube, index: 2, mirror_index: 2)
      fixture = File.read("spec/fixtures/3/2/shape.json")
      expect(record.to_json_document).to eq(fixture)
    end
  end
end
