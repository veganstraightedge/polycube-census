# frozen_string_literal: true

require "digest"
require "fileutils"
require "tempfile"

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

      # The ceiling on a proof we will take by upload. GitHub refuses blobs past
      # 100 MB, so anything larger could not join the archive even if checked.
      # The triskelion campaign's proofs run far past this, and they need the S3
      # path rather than this one. A record saying "too large to check this way"
      # is worth more than silence about it.
      MAX_PROOF_BYTES = 100 * 1024 * 1024

      DEFAULT_PROOFS = "proofs"

      def initialize(store:, lease_seconds: 900, proofs: DEFAULT_PROOFS)
        @store = store
        @lease_seconds = lease_seconds
        @proofs = proofs
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

        # A digest is only worth recording once its result was believed. The
        # proof is claimed, not held: the bytes are still on the worker's disk.
        proof = accepted ? payload[:proof] : nil
        store.record_result(unit_id:, client_id:, verdict:, payload:, seconds:, verified: accepted, note:,
                            proof:, proof_state: proof ? "claimed" : "none")
        store.credit_client(id: client_id, accepted:)

        if accepted
          store.close_unit(id: unit_id, status: verdict == "exhausted" ? "exhausted" : "done")
        else
          store.release_unit(unit_id)
        end
        { accepted:, note: }
      end

      def status = store.status.merge(proofs: store.proof_states)

      # Ask for a claimed proof. Nothing arrives unasked, so an upload nobody
      # requested has nowhere to land.
      def want_proof(sha256) = store.want_proof(sha256).positive?

      def wanted_proofs(client_id:) = store.wanted_proofs(client_id:)

      # Take delivery of a proof and check it.
      #
      # Four things hold before the checker is worth running: we asked for this
      # proof, it fits, the bytes hash to what was promised, and the formula it
      # claims to refute is one we rebuild ourselves. That last one is the whole
      # point. Checking a proof against a formula the sender chose proves only
      # that they can write two matching files.
      def deliver_proof(sha256:, bytes:)
        wanted = store.wanted_proof(sha256)
        return refusal("no proof was asked for with that digest") unless wanted

        if bytes.bytesize > MAX_PROOF_BYTES
          store.record_proof(id: wanted[:id], state: "too_large", note: "#{bytes.bytesize} bytes exceeds the upload cap")
          return refusal("proof exceeds the #{MAX_PROOF_BYTES} byte cap")
        end

        digest = Digest::SHA256.hexdigest(bytes)
        return refusal("bytes hash to #{digest[0, 12]}, not the promised #{sha256[0, 12]}") unless digest == sha256

        check_delivered(wanted:, sha256:, bytes:)
      end

      private

      attr_reader :lease_seconds, :proofs, :store

      def refusal(note) = { accepted: false, note: }

      # Rebuild the exact formula the proof claims to refute, from the base CNF
      # and the cube this coordinator handed out, then let drat-trim decide.
      def check_delivered(wanted:, sha256:, bytes:)
        path = stored_at(sha256, bytes)
        unit = wanted[:unit]

        result = Tempfile.create(["census-cube", ".cnf"]) do |formula|
          SAT::CubeFile.stream_augmented(cnf_path: unit.fetch(:cnf_path), cube: unit.fetch(:cube, []), io: formula)
          formula.flush
          SAT::DratTrim.check(cnf_path: formula.path, proof_path: path)
        end

        state = result.verified? ? "verified" : "refuted"
        store.record_proof(id: wanted[:id], state:, path:, note: result.summary)

        { accepted: result.verified?, note: "proof #{state}: #{result.summary}" }
      rescue SAT::DratTrim::Missing, KeyError => error
        # Could not check is not the same answer as did not hold.
        store.record_proof(id: wanted[:id], state: "stored", path:, note: "unchecked: #{error.message}")
        { accepted: false, note: "proof stored but unchecked: #{error.message}" }
      end

      def stored_at(sha256, bytes)
        FileUtils.mkdir_p(proofs)
        path = File.join(proofs, "#{sha256}.drat")
        File.binwrite(path, bytes) unless File.exist?(path)

        path
      end

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
