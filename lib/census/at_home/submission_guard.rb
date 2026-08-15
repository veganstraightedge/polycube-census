# frozen_string_literal: true

module Census
  module AtHome
    # Bounds a submission before the geometry verifier ever sees it.
    #
    # Verification is compute: a certificate claiming a million placements
    # would have the coordinator allocating and comparing cells on a
    # stranger's say-so. No web framework protects against that — it is a
    # domain-shaped denial of service, so the domain rejects it up front.
    class SubmissionGuard
      MAX_PLACEMENTS = 10_000
      MAX_COORDINATE = 10_000
      MAX_MODEL_LITERALS = 5_000_000

      def initialize(payload:, verdict:)
        @payload = payload
        @verdict = verdict
      end

      # Returns nil when the submission is safe to verify, or a reason string.
      def rejection
        case verdict
        when "tiler" then certificate_rejection
        when "sat" then model_rejection
        end
      end

      private

      attr_reader :payload, :verdict

      def certificate_rejection
        certificate = payload[:certificate]
        return "certificate missing" unless certificate.is_a?(Hash)

        placements = certificate[:placements] || certificate["placements"]
        return "placements missing" unless placements.is_a?(Array)
        return "too many placements (#{placements.size} > #{MAX_PLACEMENTS})" if placements.size > MAX_PLACEMENTS

        placements.each do |placement|
          offset = placement.is_a?(Hash) ? (placement[:offset] || placement["offset"]) : nil
          return "malformed placement" unless offset.is_a?(Array) && offset.size == 3
          return "coordinate out of range" unless offset.all? { it.is_a?(Integer) && it.abs <= MAX_COORDINATE }
        end
        nil
      end

      def model_rejection
        model = payload[:model]
        return "model missing" unless model.is_a?(Array)
        return "model too large (#{model.size} literals)" if model.size > MAX_MODEL_LITERALS
        return "model contains non-integers" unless model.all? { it.is_a?(Integer) }

        nil
      end
    end
  end
end
