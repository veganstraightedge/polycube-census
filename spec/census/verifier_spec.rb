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

    it "accepts a torus certificate straight from the search" do
      l_tricube = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]])
      torus = Census::TorusSearch.new(shape: l_tricube).certificate
      expect(described_class.new(certificate: torus, shape: l_tricube)).to be_valid
    end

    it "rejects a torus certificate with duplicated placements" do
      l_tricube = Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 1, 0]])
      torus = Census::TorusSearch.new(shape: l_tricube).certificate
      tampered = torus.merge(placements: torus[:placements] * 2)
      expect(described_class.new(certificate: tampered, shape: l_tricube)).not_to be_valid
    end
  end
end
