# frozen_string_literal: true

RSpec.describe Census::MirroredCertificate do
  describe "#certificate" do
    let(:screw) { Census::Polycube.new(cells: [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]]).canonical }
    let(:twin) { screw.mirror.canonical }

    it "reflects a torus certificate into one its mirror twin verifies" do
      certificate = Census::TorusSearch.new(shape: screw, max_index: 8).certificate
      mirrored = described_class.new(certificate:, shape: screw, twin:).certificate
      expect(Census::Verifier.new(certificate: mirrored, shape: twin)).to be_valid
    end

    it "reflects a box certificate into one its mirror twin verifies" do
      certificate = Census::BoxSearch.new(shape: screw, max_volume: 8).certificate
      mirrored = described_class.new(certificate:, shape: screw, twin:).certificate
      expect(Census::Verifier.new(certificate: mirrored, shape: twin)).to be_valid
    end

    it "keeps the certificate type" do
      certificate = Census::TorusSearch.new(shape: screw, max_index: 8).certificate
      mirrored = described_class.new(certificate:, shape: screw, twin:).certificate
      expect(mirrored[:type]).to eq("torus")
    end

    it "is sanity-checked against a genuinely chiral shape" do
      expect(screw).to be_chiral
    end
  end
end
