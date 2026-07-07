# frozen_string_literal: true

module Census
  # Finds the smallest box a shape tiles, trying volumes in increasing
  # multiples of the shape's size. Returns a box certificate or nil.
  class BoxSearch
    DEFAULT_MAX_VOLUME = 96

    def initialize(shape:, max_volume: DEFAULT_MAX_VOLUME)
      @shape = shape
      @max_volume = max_volume
    end

    def certificate
      candidate_boxes.each do |box|
        placements = BoxTiling.new(box:, shape:).solve
        return { type: "box", box:, placements: } if placements
      end
      nil
    end

    private

    attr_reader :max_volume, :shape

    def candidate_boxes
      volumes.flat_map { boxes_of_volume(it) }.select { fits?(it) }
    end

    def volumes = (shape.size..max_volume).step(shape.size).to_a

    def boxes_of_volume(volume)
      boxes = []
      divisors_of(volume).each do |first|
        divisors_of(volume / first).each do |second|
          third = volume / (first * second)
          boxes << [first, second, third] if second.between?(first, third)
        end
      end
      boxes
    end

    def divisors_of(number) = (1..number).select { (number % it).zero? }

    def fits?(box)
      sorted_extents = shape.cells.transpose.map { it.max + 1 }.sort
      sorted_extents.zip(box).all? { |needed, available| needed <= available }
    end
  end
end
