# frozen_string_literal: true

module Census
  # Reference counts the enumerator must reproduce before anything downstream
  # runs. Values copied from the OEIS b-files, never from memory.
  module OEIS
    # https://oeis.org/A000162 — free polycubes with n cells, mirror images distinct
    A000162 = [1, 1, 2, 8, 29, 166, 1023, 6922, 48_311, 346_543, 2_522_522, 18_598_427].freeze

    # https://oeis.org/A038119 — free polycubes with n cells, mirror images identified
    A038119 = [1, 1, 2, 7, 23, 112, 607, 3811, 25_413, 178_083, 1_279_537, 9_371_094].freeze
  end
end
