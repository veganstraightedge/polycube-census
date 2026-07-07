# frozen_string_literal: true

require "json"

module Census
  # Serializes a census record hash: one top-level key per line, values compact.
  module JSONDocument
    def self.generate(hash)
      fields = hash.map { |key, value| %(  "#{key}": #{JSON.generate(value)}) }
      "{\n#{fields.join(",\n")}\n}\n"
    end
  end
end
