# frozen_string_literal: true

require "json"

module Census
  # Serializes a census record hash: one top-level key per line, values compact.
  # Top-level keys keep the caller's order, which is the document's readable
  # shape: identity, then geometry, then verdict, then evidence, then credits.
  class JSONDocument
    def initialize(hash)
      @hash = hash
    end

    def generate
      fields = hash.map { |key, value| %(  "#{key}": #{JSON.generate(canonical(value))}) }

      "{\n#{fields.join(",\n")}\n}\n"
    end

    private

    attr_reader :hash

    # A record should be defined by its content, not by the order whichever
    # writer produced it happened to build it in. Certificates that round trip
    # through the coordinator's jsonb columns come back with their keys
    # rearranged, so without this the same answer reaches data/ as a different
    # file and re-running the pipeline stops reproducing byte-identical output.
    #
    # Hash keys sort. Array order is data and stays put.
    def canonical(value)
      case value
      when Hash  then value.keys.sort_by(&:to_s).to_h { [it, canonical(value[it])] }
      when Array then value.map { canonical(it) }
      else            value
      end
    end
  end
end
