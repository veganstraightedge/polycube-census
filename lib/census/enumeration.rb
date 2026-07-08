# frozen_string_literal: true

module Census
  # Grows all free polycubes generation by generation, deduplicating by
  # canonical form. Shapes of each size are sorted lexicographically by their
  # canonical cells; that order defines the census's stable 1-based indices.
  class Enumeration
    attr_reader :max_size

    def initialize(max_size:, progress: nil)
      @max_size = max_size
      @progress = progress
    end

    def shapes_of(size) = shapes_by_size.fetch(size)

    def mirror_classes_of(size) = shapes_of(size).group_by(&:mirror_class_key).values

    def shapes_by_size
      @shapes_by_size ||= build
    end

    private

    def build
      generations = { 1 => [Polycube.new(cells: [[0, 0, 0]])] }
      (2..max_size).each do |size|
        generations[size] = next_generation(generations.fetch(size - 1))
        @progress&.call("n=#{size}: #{generations[size].size} shapes enumerated")
      end
      generations
    end

    def next_generation(shapes)
      canonical_forms = Set.new
      shapes.each_with_index do |shape, position|
        if @progress && position.positive? && (position % 500).zero?
          @progress.call("  growing: #{position}/#{shapes.size} parents expanded, #{canonical_forms.size} children so far")
        end
        shape.growths.each { canonical_forms << it.canonical_cells }
      end
      canonical_forms.sort.map { Polycube.new(cells: it) }
    end
  end
end
