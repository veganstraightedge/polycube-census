# frozen_string_literal: true

RSpec.describe Census::SAT::Proof do
  # A real refutation, written by kissat from spec/fixtures/proof/contradiction.cnf
  # (the four clauses over two variables that contradict each other).
  let(:path) { "spec/fixtures/proof/contradiction.drat" }

  it "addresses a proof by the digest of its bytes" do
    expected = Digest::SHA256.hexdigest(File.binread(path))

    expect(described_class.of(path).sha256).to eq(expected)
  end

  it "reports the size on disk" do
    expect(described_class.of(path).bytes).to eq(File.size(path))
  end

  it "travels as a hash of digest and size" do
    proof = described_class.of(path)

    expect(proof.to_h).to eq(bytes: proof.bytes, sha256: proof.sha256)
  end

  it "is not empty when the solver had to derive something" do
    expect(described_class.of(path)).not_to be_empty
  end

  # kissat writes nothing when it refutes a formula without deriving a clause.
  # Reporting that as a refutation would be reporting an absence as evidence.
  it "is empty when the solver wrote nothing" do
    Tempfile.create(["census", ".drat"]) do |file|
      expect(described_class.of(file.path)).to be_empty
    end
  end
end
