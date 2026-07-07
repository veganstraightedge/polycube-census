# frozen_string_literal: true

module Census
  # One of the 24 orientation-preserving symmetries of the cubic lattice,
  # represented as an axis permutation plus per-axis signs.
  class Rotation
    def self.all
      @all ||= build_all.freeze
    end

    def self.build_all
      axis_orders = [0, 1, 2].permutation.to_a
      sign_choices = [1, -1].repeated_permutation(3).to_a
      axis_orders.product(sign_choices)
                 .map { |axes, signs| new(axes:, signs:) }
                 .select(&:proper?)
    end

    attr_reader :axes, :signs

    def initialize(axes:, signs:)
      @axes = axes
      @signs = signs
    end

    def apply(cell)
      axes.zip(signs).map { |axis, sign| sign * cell[axis] }
    end

    def proper? = determinant == 1

    private

    def determinant = permutation_sign * signs.reduce(:*)

    def permutation_sign
      inversions = axes.combination(2).count { |earlier, later| earlier > later }
      inversions.even? ? 1 : -1
    end
  end
end
