# frozen_string_literal: true

module Census
  # Rechecks a certificate with plain geometry — no solver involved.
  # Exact cover by pigeonhole: right count + no duplicates + all inside.
  class Verifier
    def initialize(certificate:, shape:)
      @certificate = certificate
      @shape = shape
    end

    def valid?
      case certificate[:type]
      when "box" then valid_box?
      else false
      end
    end

    private

    attr_reader :certificate, :shape

    def valid_box?
      cells = placed_cells
      cells.size == box_volume && cells.uniq.size == cells.size && cells.all? { inside_box?(it) }
    end

    def placed_cells
      certificate[:placements].flat_map do |placement|
        rotation = Rotation.all.fetch(placement[:rotation])
        shape.rotated(rotation).cells.map { |cell| cell.zip(placement[:offset]).map(&:sum) }
      end
    end

    def box_volume = certificate[:box].reduce(:*)

    def inside_box?(cell)
      cell.zip(certificate[:box]).all? { |coordinate, limit| coordinate >= 0 && coordinate < limit }
    end
  end
end
