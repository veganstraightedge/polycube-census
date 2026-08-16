# frozen_string_literal: true

require "digest"

module Census
  module SAT
    # A DRAT proof on disk, addressed by its contents.
    #
    # A refutation is worth exactly what its proof is worth. Today a volunteer's
    # "unsat" is taken on report, which is fine against shapes we have already
    # solved and not fine for anything published. Naming the artifact by hash is
    # what makes the claim auditable later: the digest travels back with the
    # result while the bytes stay on the machine that produced them, so the
    # coordinator can ask for the proof itself whenever it wants to check one.
    #
    # A proof only means something against the exact formula it refutes. For a
    # cube unit that formula is the base CNF plus the cube's unit clauses, which
    # is reproducible from the unit alone, so it never has to be shipped.
    class Proof
      def self.of(path) = new(path:)

      def initialize(path:)
        @path = path
      end

      attr_reader :path

      def sha256 = @sha256 ||= Digest::SHA256.file(path).hexdigest
      def bytes  = @bytes  ||= File.size(path)

      # Kissat writes nothing when it never had to derive a clause. An empty
      # proof is not a refutation, and must never be reported as one.
      def empty? = bytes.zero?

      def to_h = { bytes:, sha256: }
    end
  end
end
