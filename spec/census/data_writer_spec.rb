# frozen_string_literal: true

require "tmpdir"

RSpec.describe Census::DataWriter do
  describe "#write" do
    it "writes one folder per shape" do
      Dir.mktmpdir do |root|
        described_class.new(root:).write(Census::Enumeration.new(max_size: 3))
        written = Dir.glob("*/*/shape.json", base: root).sort
        expect(written).to eq(["1/1/shape.json", "2/1/shape.json", "3/1/shape.json", "3/2/shape.json"])
      end
    end

    it "writes the L-tricube byte-identical to the fixture" do
      Dir.mktmpdir do |root|
        described_class.new(root:).write(Census::Enumeration.new(max_size: 3))
        expect(File.read(File.join(root, "3/2/shape.json"))).to eq(File.read("spec/fixtures/3/2/shape.json"))
      end
    end

    it "never overwrites an existing record" do
      Dir.mktmpdir do |root|
        described_class.new(root:).write(Census::Enumeration.new(max_size: 1))
        path = File.join(root, "1/1/shape.json")
        stamped = File.read(path).sub('"verdict": null', '"verdict": "tiler"')
        File.write(path, stamped)
        described_class.new(root:).write(Census::Enumeration.new(max_size: 1))
        expect(File.read(path)).to eq(stamped)
      end
    end

    it "finds exactly one chiral pair among the tetracubes" do
      expect(chiral_tetracube_records.size).to eq(2)
    end

    it "cross-links chiral mirror twins to each other" do
      records = chiral_tetracube_records
      expect(records.map { it["mirror_id"] }.sort).to eq(records.map { it["id"] }.sort)
    end

    it "never self-links a chiral shape" do
      self_linked = chiral_tetracube_records.count { it["mirror_id"] == it["id"] }
      expect(self_linked).to eq(0)
    end
  end

  def chiral_tetracube_records
    Dir.mktmpdir do |root|
      described_class.new(root:).write(Census::Enumeration.new(max_size: 4))
      Dir.glob("4/*/shape.json", base: root)
         .map { JSON.parse(File.read(File.join(root, it))) }
         .select { it["chiral"] }
    end
  end
end
