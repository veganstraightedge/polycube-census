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

    # Hashes wider than this break onto their own lines. Certificates and the
    # prior_art in credits are the ones that reach it. Lines can still exceed it
    # where the content is a single long string, since JSON cannot wrap those.
    WIDTH = 100

    # Raised when formatting would change a record. Nothing should ever be able
    # to trigger it, which is the point: it fires only if this class has a bug.
    class ContentChanged < StandardError; end

    def initialize(hash)
      @hash = hash
    end

    def generate
      pairs    = hash.map { |key, value| pair_of(key, value, indent: INDENT) }
      document = "{\n#{pairs.map { "#{" " * INDENT}#{it}" }.join(",\n")}\n}\n"

      verified(document)
    end

    private

    attr_reader :hash

    # Formatting must never change a record. Every writer goes through here,
    # including the four scripts the suite does not cover, so the check lives
    # where none of them can route around it.
    def verified(document)
      return document if JSON.parse(document) == JSON.parse(JSON.generate(hash))

      raise ContentChanged, "formatting changed #{hash[:id] || "the record"}"
    rescue JSON::ParserError => error
      raise ContentChanged, "formatting produced invalid JSON for #{hash[:id] || "the record"}: #{error.message}"
    end

    # A key and its value, plus the column its value starts in, so the value can
    # tell whether it fits on the rest of the line. Escaping the key is the
    # stdlib's job, since a key holding a quote would otherwise end the string.
    def pair_of(key, value, indent:)
      label = "#{JSON.generate(key.to_s)}: "

      "#{label}#{render(value, indent:, used: indent + label.length)}"
    end

    def render(value, indent:, used:)
      case value
      when Array then array_of(value, indent:)
      when Hash  then hash_of(value, indent:, used:)
      else            JSON.generate(value)
      end
    end

    # Sorted keys, spaces inside the braces. Breaks when it would overflow the
    # line, or when a child already broke, so a hash is never half inline and
    # half stacked.
    def hash_of(value, indent:, used:)
      return "{}" if value.empty?

      pairs  = value.keys.sort_by(&:to_s).map { pair_of(it, value[it], indent: indent + INDENT) }
      inline = "{ #{pairs.join(", ")} }"
      return inline unless used + inline.length > WIDTH || pairs.any? { multiline?(it) }

      stacked(pairs, close: "}", indent:, open: "{")
    end

    # Arrays of hashes always break, one element per line, because that is where
    # the long lines come from: placements, coronas, witnesses. Arrays of
    # anything else stay inline at any width, so cells keep reading as a list of
    # coordinates rather than as a column of digits.
    def array_of(value, indent:)
      return "[]" if value.empty?

      items = value.map { render(it, indent: indent + INDENT, used: indent + INDENT) }
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
