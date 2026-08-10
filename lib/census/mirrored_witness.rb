# frozen_string_literal: true

module Census
  # Non-tiling mirrors too: reflect a corona witness (placements around a seed
  # at the origin) through x -> -x and every copy of the shape becomes a copy
  # of its mirror twin, wrapping the twin's seed. Gate the result through
  # Surround#verified? before writing anything.
  class MirroredWitness
    def initialize(placements:, shape:, twin:)
      @placements = placements
      @shape = shape
      @twin = twin
    end

    def placements
      @placements.map { twin_placement(align(reflect(placed_cells(it)))) }
    end

    private

    attr_reader :shape, :twin

    # The reflected configuration surrounds the reflected seed, which sits in
    # some arbitrary pose; the twin's surround expects its seed on the twin's
    # canonical cells. Find the rigid motion carrying one onto the other and
    # apply it to every copy.
    def align(cells)
      cells.map { |cell| seed_rotation.apply(cell).zip(seed_offset).map(&:sum) }
    end

    def seed_motion
      @seed_motion ||= begin
        reflected_seed = reflect(shape.cells)
        target = twin.cells.sort
        motion = Rotation.all.filter_map do |rotation|
          rotated = reflected_seed.map { rotation.apply(it) }.sort
          offset = target.first.zip(rotated.first).map { |a, b| a - b }
          aligned = rotated.map { |cell| cell.zip(offset).map(&:sum) }
          [rotation, offset] if aligned == target
        end.first
        raise "no rigid motion aligns the reflected seed with the twin" unless motion

        motion
      end
    end

    def seed_rotation = seed_motion.first
    def seed_offset = seed_motion.last

    # Placement semantics must match Assembly.placed_cells: rotated() normalizes
    # to the origin corner before the offset is applied.
    def placed_cells(placement)
      rotation = Rotation.all.fetch(placement[:rotation])
      shape.rotated(rotation).cells.map { |cell| cell.zip(placement[:offset]).map(&:sum) }
    end

    def reflect(cells) = cells.map { |x, y, z| [-x, y, z] }

    def twin_placement(cells)
      target = cells.sort
      Rotation.all.each_with_index do |rotation, index|
        rotated = twin.rotated(rotation).cells.sort
        offset = target.first.zip(rotated.first).map { |a, b| a - b }
        aligned = rotated.map { |cell| cell.zip(offset).map(&:sum) }
        return { rotation: index, offset: } if aligned == target
      end
      raise "no orientation of the twin matches the reflected witness placement"
    end
  end
end
