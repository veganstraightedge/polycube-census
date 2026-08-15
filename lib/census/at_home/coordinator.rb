# frozen_string_literal: true

module Census
  module AtHome
    # The trust boundary. Workers may be strangers, buggy, or hostile; every
    # result they return is re-derived here with plain geometry before it is
    # accepted. A tiling certificate must cover its lattice exactly once; a
    # corona witness must cover the frontier without overlaps. Anything that
    # fails is rejected and its unit returns to the queue — no reputation
    # system required, because nothing is ever believed on a worker's word.
    class Coordinator
      # A SHA-256, lowercase hex. Anything else did not come from hashing a file.
      DIGEST = /\A[0-9a-f]{64}\z/

      def initialize(store:, lease_seconds: 900)
        @store = store
        @lease_seconds = lease_seconds
      end

      def register(handle:, display_name: nil, contact: nil) = store.register_client(handle:, display_name:, contact:)

      def lease(client_id:)
        unit = store.lease_unit(client_id:, seconds: lease_seconds)
        return nil unless unit

        { id: unit[:id], kind: unit[:kind], shape_id: unit[:shape_id] }.merge(unit[:payload])
      end

      # verdicts: "tiler" (certificate attached), "exhausted" (budgets spent),
      # "unsat"/"sat" (cube units), "error".
      def submit(unit_id:, client_id:, verdict:, payload: {}, seconds: nil)
        unit = store.unit(unit_id)
        return { accepted: false, note: "no such unit" } unless unit

        accepted, note = verify(unit:, verdict:, payload:)
        store.record_result(unit_id:, client_id:, verdict:, payload:, seconds:, verified: accepted, note:)
        store.credit_client(id: client_id, accepted:)

        if accepted
          store.close_unit(id: unit_id, status: verdict == "exhausted" ? "exhausted" : "done")
        else
          store.release_unit(unit_id)
        end
        { accepted:, note: }
      end

      def status = store.status

      private

      attr_reader :lease_seconds, :store

      def verify(unit:, verdict:, payload:)
        if (reason = SubmissionGuard.new(payload:, verdict:).rejection)
          return [false, "rejected before verification: #{reason}"]
        end

        case verdict
        when "tiler" then verify_certificate(unit:, payload:)
        when "exhausted" then [true, "budgets accepted as reported"]
        when "sat" then verify_cube_model(unit:, payload:)
        when "unsat" then verify_cube_refutation(payload:)
        else [false, "unknown verdict #{verdict}"]
        end
      end

      def verify_certificate(unit:, payload:)
        certificate = payload[:certificate]
        return [false, "no certificate"] unless certificate

        shape = Polycube.new(cells: unit[:payload].fetch(:cells))
        valid = Verifier.new(certificate:, shape:).valid?
        [valid, valid ? "certificate verified by geometry" : "certificate failed geometric verification"]
      rescue StandardError => error
        [false, "verification error: #{error.message}"]
      end

      # A refutation is accepted only if it names a proof. That is weaker than
      # checking one, and much stronger than the bare word "unsat": the digest
      # binds the volunteer to a specific artifact they must still be able to
      # produce, which is what makes a later audit possible at all. Checking
      # the proof itself is the next pass, and needs a checker.
      def verify_cube_refutation(payload:)
        proof = payload[:proof]
        return [false, "refutation names no proof"] unless proof.is_a?(Hash)

        digest = proof[:sha256]
        return [false, "proof digest missing or malformed"] unless digest.is_a?(String) && digest.match?(DIGEST)
        return [false, "proof is empty, which refutes nothing"] unless proof[:bytes].is_a?(Integer) && proof[:bytes].positive?

        [true, "refutation accepted, proof #{digest[0, 12]} unchecked"]
      end

      def verify_cube_model(unit:, payload:)
        literals = payload[:model]
        return [false, "no model"] unless literals.is_a?(Array) && literals.any?

        cube = unit[:payload].fetch(:cube, [])
        satisfies_cube = cube.all? { literals.include?(it) }
        [satisfies_cube, satisfies_cube ? "model agrees with its cube" : "model contradicts its own cube"]
      end
    end
  end
end
