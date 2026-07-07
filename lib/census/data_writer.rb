# frozen_string_literal: true

module Census
  # Writes data/<n>/<index>/shape.json for every enumerated shape.
  class DataWriter
    attr_reader :root

    def initialize(root:)
      @root = Pathname(root)
    end

    def write(enumeration)
      (1..enumeration.max_size).each { write_size(enumeration.shapes_of(it), size: it) }
    end

    private

    def write_size(shapes, size:)
      indices = index_by_cells(shapes)
      shapes.each_with_index do |shape, position|
        record = ShapeRecord.new(
          shape:,
          index: position + 1,
          mirror_index: indices.fetch(shape.mirror.canonical_cells)
        )
        write_record(record, size:, index: position + 1)
      end
    end

    def index_by_cells(shapes)
      shapes.each_with_index.to_h { |shape, position| [shape.cells, position + 1] }
    end

    def write_record(record, size:, index:)
      directory = root.join(size.to_s, index.to_s)
      directory.mkpath
      directory.join("shape.json").write(record.to_json_document)
    end
  end
end
