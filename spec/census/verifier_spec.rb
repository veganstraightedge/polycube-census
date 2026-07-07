# frozen_string_literal: true

RSpec.describe Census::Verifier do
  let(:screw) { Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]]) }
  let(:certificate) { Census::BoxSearch.new(shape: screw).certificate }

  describe "#valid?" do
    it "accepts a certificate straight from the search" do
      expect(described_class.new(certificate:, shape: screw)).to be_valid
    end

    it "rejects a certificate with a missing placement" do
      tampered = certificate.merge(placements: certificate[:placements].drop(1))
      expect(described_class.new(certificate: tampered, shape: screw)).not_to be_valid
    end

    it "rejects a certificate with a shifted placement" do
      shifted = certificate[:placements].map { it.merge(offset: it[:offset].map { |c| c + 1 }) }
      tampered = certificate.merge(placements: shifted)
      expect(described_class.new(certificate: tampered, shape: screw)).not_to be_valid
    end

    it "rejects unknown certificate types" do
      expect(described_class.new(certificate: { type: "wishful" }, shape: screw)).not_to be_valid
    end
  end
end
