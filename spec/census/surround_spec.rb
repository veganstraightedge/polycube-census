# frozen_string_literal: true

RSpec.describe Census::Surround do
  let(:ring) do
    Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2], [0, 1, 0],
                                 [0, 1, 2], [0, 2, 0], [0, 2, 1], [0, 2, 2]])
  end

  describe "#frontier" do
    it "counts 26 cells around the monocube" do
      surround = described_class.new(shape: Census::Polycube.new(cells: [[0, 0, 0]]))
      expect(surround.frontier.size).to eq(26)
    end

    it "includes the ring's hole" do
      expect(described_class.new(shape: ring).frontier).to include([0, 1, 1])
    end
  end

  describe "#solve" do
    it "surrounds the dicube" do
      surround = described_class.new(shape: Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]]))
      expect(surround.solve).not_to be_nil
    end

    it "produces a witness that survives verification" do
      surround = described_class.new(shape: Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1]]))
      expect(surround.verified?(surround.solve)).to be(true)
    end
  end

  describe "#verified?" do
    it "rejects a witness with a placement removed" do
      surround = described_class.new(shape: Census::Polycube.new(cells: [[0, 0, 0]]))
      witness = surround.solve
      expect(surround.verified?(witness.drop(1))).to be(false)
    end
  end
end
