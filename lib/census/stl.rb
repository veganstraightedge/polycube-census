# frozen_string_literal: true

module Census
  # Renders cells as an ASCII STL mesh: one quad (two triangles) per cube face
  # that borders empty space, wound counter-clockwise seen from outside, so the
  # solid is watertight and printable.
  module STL
    # Per face: the neighbor direction, the outward normal, and the four
    # corner offsets (from the cell's min corner) in outward-CCW order.
    FACES = [
      { neighbor: [-1, 0, 0], normal: [-1, 0, 0],
        corners: [[0, 0, 0], [0, 0, 1], [0, 1, 1], [0, 1, 0]] },
      { neighbor: [1, 0, 0], normal: [1, 0, 0],
        corners: [[1, 0, 0], [1, 1, 0], [1, 1, 1], [1, 0, 1]] },
      { neighbor: [0, -1, 0], normal: [0, -1, 0],
        corners: [[0, 0, 0], [1, 0, 0], [1, 0, 1], [0, 0, 1]] },
      { neighbor: [0, 1, 0], normal: [0, 1, 0],
        corners: [[0, 1, 0], [0, 1, 1], [1, 1, 1], [1, 1, 0]] },
      { neighbor: [0, 0, -1], normal: [0, 0, -1],
        corners: [[0, 0, 0], [0, 1, 0], [1, 1, 0], [1, 0, 0]] },
      { neighbor: [0, 0, 1], normal: [0, 0, 1],
        corners: [[0, 0, 1], [1, 0, 1], [1, 1, 1], [0, 1, 1]] }
    ].freeze

    def self.model(cells:, name: "polycube")
      occupied = cells.to_set
      facets = cells.sort.flat_map { |cell| cell_facets(cell, occupied) }
      "solid #{name}\n#{facets.join}endsolid #{name}\n"
    end

    def self.cell_facets(cell, occupied)
      FACES.filter_map do |face|
        neighbor = cell.zip(face[:neighbor]).map(&:sum)
        next if occupied.include?(neighbor)

        corners = face[:corners].map { |corner| cell.zip(corner).map(&:sum) }
        quad(face[:normal], corners)
      end
    end

    def self.quad(normal, corners)
      first, second, third, fourth = corners
      facet(normal, [first, second, third]) + facet(normal, [first, third, fourth])
    end

    def self.facet(normal, triangle)
      vertices = triangle.map { "    vertex #{it.join(' ')}\n" }.join
      "facet normal #{normal.join(' ')}\n  outer loop\n#{vertices}  endloop\nendfacet\n"
    end
  end
end
