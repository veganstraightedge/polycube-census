# frozen_string_literal: true

RSpec.describe Census::Rotation do
  describe ".all" do
    it "contains 24 rotations" do
      expect(described_class.all.size).to eq(24)
    end

    it "acts distinctly on a generic point" do
      images = described_class.all.map { it.apply([1, 2, 3]) }
      expect(images.uniq.size).to eq(24)
    end

    it "includes the identity" do
      images = described_class.all.map { it.apply([1, 2, 3]) }
      expect(images).to include([1, 2, 3])
    end

    it "excludes reflections" do
      images = described_class.all.map { it.apply([1, 2, 3]) }
      expect(images).not_to include([-1, 2, 3])
    end
  end
end
