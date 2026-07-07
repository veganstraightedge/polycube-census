# frozen_string_literal: true

module Census
  # Renders an assembly of cell groups (copies in a tiling, coronas around a
  # seed) as OBJ + MTL text. Each group is its own closed solid with its own
  # color, so the seams between copies stay visible.
  module OBJ
    PALETTE = [
      [0.906, 0.298, 0.235], [0.204, 0.596, 0.859], [0.180, 0.800, 0.443],
      [0.945, 0.769, 0.059], [0.608, 0.349, 0.714], [0.902, 0.494, 0.133],
      [0.102, 0.737, 0.612], [0.906, 0.435, 0.318], [0.204, 0.286, 0.369],
      [0.584, 0.647, 0.651], [0.749, 0.937, 0.271], [0.955, 0.475, 0.757]
    ].freeze

    def self.assembly(groups:, name: "assembly")
      obj = +"mtllib #{name}.mtl\n"
      vertex_count = 0
      groups.each_with_index do |group, index|
        obj << "g #{group[:name]}\nusemtl material_#{index % PALETTE.size}\n"
        group_quads(group[:cells]).each do |corners|
          corners.each { obj << "v #{it.join(' ')}\n" }
          obj << "f #{(1..4).map { vertex_count + it }.join(' ')}\n"
          vertex_count += 4
        end
      end
      { mtl: mtl(groups.size), obj: obj }
    end

    def self.group_quads(cells)
      occupied = cells.to_set
      cells.sort.flat_map do |cell|
        STL::FACES.filter_map do |face|
          neighbor = cell.zip(face[:neighbor]).map(&:sum)
          next if occupied.include?(neighbor)

          face[:corners].map { |corner| cell.zip(corner).map(&:sum) }
        end
      end
    end

    def self.mtl(group_count)
      [group_count, PALETTE.size].min.times.map do |index|
        red, green, blue = PALETTE[index]
        "newmtl material_#{index}\nKd #{red} #{green} #{blue}\n"
      end.join
    end
  end
end
