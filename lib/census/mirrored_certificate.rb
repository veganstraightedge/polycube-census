# frozen_string_literal: true

module Census
  # P tiles iff its mirror tiles: reflect a whole tiling through x -> -x and
  # every copy of P becomes a copy of mirror(P). This derives the twin's
  # certificate from a solved shape's certificate — no solver needed. Always
  # gate the result through Verifier before stamping.
  class MirroredCertificate
    def initialize(certificate:, shape:, twin:)
      @certificate = certificate
      @shape = shape
      @twin = twin
    end

    def certificate
      case @certificate[:type]
      when "box"   then mirrored_box
      when "torus" then mirrored_torus
      else raise ArgumentError, "cannot mirror a #{@certificate[:type]} certificate"
      end
    end

    private

    attr_reader :shape, :twin

    def mirrored_torus
      basis = @certificate[:lattice].map { |x, y, z| [-x, y, z] }
      {
        type: "torus",
        lattice: Lattice.hermite_normal_form(basis),
        placements: @certificate[:placements].map { twin_placement(reflect(placed_cells(it))) }
      }
    end

    def mirrored_box
      width = @certificate[:box].first
      {
        type: "box",
        box: @certificate[:box],
        placements: @certificate[:placements].map do |placement|
          cells = reflect(placed_cells(placement)).map { |x, y, z| [x + width - 1, y, z] }
          twin_placement(cells)
        end
      }
    end

    # Placement semantics must match Verifier: rotated() normalizes to the
    # origin corner before the offset is applied.
    def placed_cells(placement)
      rotation = Rotation.all.fetch(placement[:rotation])
      shape.rotated(rotation).cells.map { |cell| cell.zip(placement[:offset]).map(&:sum) }
    end

    def reflect(cells) = cells.map { |x, y, z| [-x, y, z] }

    # Find the (rotation, offset) placing the twin exactly on the given cells;
    # lexicographic sort aligns the two lists under translation.
    def twin_placement(cells)
      target = cells.sort
      Rotation.all.each_with_index do |rotation, index|
        rotated = twin.rotated(rotation).cells.sort
        offset = target.first.zip(rotated.first).map { |a, b| a - b }
        aligned = rotated.map { |cell| cell.zip(offset).map(&:sum) }
        return { rotation: index, offset: } if aligned == target
      end
      raise "no orientation of the twin matches the reflected placement"
    end
  end
end
