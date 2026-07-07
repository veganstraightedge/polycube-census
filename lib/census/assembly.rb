# frozen_string_literal: true

module Census
  # Turns a tiling certificate into copy groups for OBJ assembly: box
  # placements as-is, torus placements replicated across a 2x2x2 block of
  # lattice translates so the pattern's interlocking is visible.
  class Assembly
    def self.groups_for(certificate:, shape:)
      case certificate[:type]
      when "box"   then box_groups(certificate, shape)
      when "torus" then torus_groups(certificate, shape)
      else []
      end
    end

    def self.box_groups(certificate, shape)
      certificate[:placements].each_with_index.map do |placement, index|
        { name: "copy_#{index + 1}", cells: placed_cells(placement, shape) }
      end
    end

    def self.torus_groups(certificate, shape)
      groups = []
      certificate[:placements].each_with_index do |placement, index|
        cells = placed_cells(placement, shape)
        lattice_shifts(certificate[:lattice]).each_with_index do |shift, domain|
          shifted = cells.map { |cell| cell.zip(shift).map(&:sum) }
          groups << { name: "copy_#{index + 1}_domain_#{domain + 1}", cells: shifted }
        end
      end
      groups
    end

    def self.lattice_shifts(basis)
      [0, 1].product([0, 1], [0, 1]).map do |a, b, c|
        (0..2).map { (a * basis[0][it]) + (b * basis[1][it]) + (c * basis[2][it]) }
      end
    end

    def self.placed_cells(placement, shape)
      rotation = Rotation.all.fetch(placement[:rotation])
      shape.rotated(rotation).cells.map { |cell| cell.zip(placement[:offset]).map(&:sum) }
    end
  end
end
