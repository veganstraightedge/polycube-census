# frozen_string_literal: true

require "json"

module Census
  # Serializes a census record hash: one top-level key per line.
  #
  # Top-level keys keep the caller's order, which is the document's readable
  # shape: identity, then geometry, then verdict, then evidence, then credits.
  #
  # Below the top level, keys sort. A record should be defined by its content
  # and not by the order whichever writer produced it happened to build it in.
  # Certificates that round trip through the coordinator's jsonb columns come
  # back with their keys rearranged, so without sorting the same answer reaches
  # data/ as a different file and re-running the pipeline stops reproducing
  # byte-identical output.
  class JSONDocument
    INDENT = 2

    def initialize(hash)
      @hash = hash
    end

    def generate
      fields = hash.map { |key, value| %(#{" " * INDENT}"#{key}": #{render(value, indent: INDENT)}) }

      "{\n#{fields.join(",\n")}\n}\n"
    end

    private

    attr_reader :hash

    def render(value, indent:)
      case value
      when Array then array_of(value, indent:)
      when Hash  then hash_of(value, indent:)
      else            JSON.generate(value)
      end
    end

    # Sorted keys, spaces inside the braces. Breaks onto its own lines only when
    # a child broke, so a hash is never half inline and half stacked.
    def hash_of(value, indent:)
      return "{}" if value.empty?

      pairs = value.keys.sort_by(&:to_s).map { %("#{it}": #{render(value[it], indent: indent + INDENT)}) }
      return "{ #{pairs.join(", ")} }" unless pairs.any? { multiline?(it) }

      stacked(pairs, close: "}", indent:, open: "{")
    end

    # Arrays of hashes always break, one element per line, because that is where
    # the long lines come from: placements, coronas, witnesses. Arrays of
    # anything else stay inline, so cells keep reading as a list of coordinates.
    def array_of(value, indent:)
      return "[]" if value.empty?

      items = value.map { render(it, indent: indent + INDENT) }
      return "[#{items.join(", ")}]" unless value.all?(Hash) || items.any? { multiline?(it) }

      stacked(items, close: "]", indent:, open: "[")
    end

    def stacked(parts, close:, indent:, open:)
      inner = " " * (indent + INDENT)

      "#{open}\n#{parts.map { "#{inner}#{it}" }.join(",\n")}\n#{" " * indent}#{close}"
    end

    def multiline?(text) = text.include?("\n")
  end
end
