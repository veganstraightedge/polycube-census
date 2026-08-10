# frozen_string_literal: true

RSpec.describe Census::MirroredWitness do
  describe "#placements" do
    let(:screw) { Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]]).canonical }
    let(:twin) { screw.mirror.canonical }

    it "reflects a corona witness into one the mirror twin's surround verifies" do
      witness = Census::Surround.new(shape: screw).solve
      compact = witness.map { it.slice(:rotation, :offset) }

      mirrored = described_class.new(placements: compact, shape: screw, twin:).placements
      surround = Census::Surround.new(shape: twin)
      reconstructed = mirrored.map { it.merge(cells: Census::Assembly.placed_cells(it, twin)) }
      expect(surround.verified?(reconstructed)).to be(true)
    end

    it "returns rotation-and-offset placements only" do
      witness = Census::Surround.new(shape: screw).solve
      compact = witness.map { it.slice(:rotation, :offset) }

      mirrored = described_class.new(placements: compact, shape: screw, twin:).placements
      expect(mirrored).to all(match(hash_including(rotation: Integer, offset: [Integer, Integer, Integer])))
    end
  end
end
