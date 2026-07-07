# frozen_string_literal: true

module Census
  # A polycube as a value object: a set of unit cells, stored normalized
  # (translated to the origin corner, sorted). Two polycubes are the same
  # free shape when their canonical forms match.
  class Polycube
    FACE_DIRECTIONS = [
      [-1, 0, 0], [1, 0, 0],
      [0, -1, 0], [0, 1, 0],
      [0, 0, -1], [0, 0, 1]
    ].freeze

    attr_reader :cells

    def initialize(cells:)
      @cells = self.class.normalize(cells)
    end

    def self.normalize(cells)
      origin = cells.transpose.map(&:min)
      cells.map { |cell| cell.zip(origin).map { |coordinate, minimum| coordinate - minimum } }.sort
    end

    def size = cells.size

    def rotated(rotation) = self.class.new(cells: cells.map { rotation.apply(it) })

    def orientations = Rotation.all.map { rotated(it) }

    def canonical_cells
      @canonical_cells ||= orientations.map(&:cells).min
    end

    def canonical = self.class.new(cells: canonical_cells)

    def mirror
      @mirror ||= self.class.new(cells: cells.map { |x, y, z| [-x, y, z] })
    end

    def chiral? = canonical_cells != mirror.canonical_cells

    def mirror_class_key
      [canonical_cells, mirror.canonical_cells].min
    end

    def symmetry_order = Rotation.all.count { rotated(it).cells == cells }

    def growths
      neighbors.map { |cell| self.class.new(cells: cells + [cell]) }
    end

    def ==(other) = other.is_a?(self.class) && cells == other.cells
    alias eql? ==

    def hash = cells.hash

    private

    def neighbors
      occupied = cells.to_set
      cells.flat_map { |cell| FACE_DIRECTIONS.map { |direction| cell.zip(direction).map(&:sum) } }
           .uniq
           .reject { occupied.include?(it) }
    end
  end
end
