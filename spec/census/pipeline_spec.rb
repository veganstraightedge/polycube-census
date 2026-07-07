# frozen_string_literal: true

require "tmpdir"

RSpec.describe Census::Pipeline do
  describe "#run" do
    it "stamps every small shape as a tiler with a verified certificate" do
      Dir.mktmpdir do |root|
        Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 3))
        described_class.new(root:).run(max_size: 3)
        verdicts = Dir.glob("*/*/shape.json", base: root)
                      .map { JSON.parse(File.read(File.join(root, it)), symbolize_names: true) }
        expect(verdicts.map { it[:verdict] }).to all(eq("tiler"))
      end
    end

    it "writes certificates that survive independent verification" do
      Dir.mktmpdir do |root|
        Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 3))
        described_class.new(root:).run(max_size: 3)
        record = JSON.parse(File.read(File.join(root, "3/2/shape.json")), symbolize_names: true)
        shape = Census::Polycube.new(cells: record[:cells])
        expect(Census::Verifier.new(certificate: record[:certificate], shape:)).to be_valid
      end
    end

    it "credits the pipeline version as solver" do
      Dir.mktmpdir do |root|
        Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 2))
        described_class.new(root:).run(max_size: 2)
        record = JSON.parse(File.read(File.join(root, "2/1/shape.json")), symbolize_names: true)
        expect(record[:credits][:solved_by]).to eq("polycube-census v#{Census::VERSION}")
      end
    end

    it "falls back to the torus stage when the box budget is too small" do
      Dir.mktmpdir do |root|
        Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 3))
        described_class.new(root:, max_volume: 4, max_index: 6).run(max_size: 3)
        record = JSON.parse(File.read(File.join(root, "3/2/shape.json")), symbolize_names: true)
        expect(record[:certificate][:type]).to eq("torus")
      end
    end

    it "skips shapes that already carry a verdict" do
      Dir.mktmpdir do |root|
        Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 1))
        pipeline = described_class.new(root:)
        pipeline.run(max_size: 1)
        before = File.read(File.join(root, "1/1/shape.json"))
        pipeline.run(max_size: 1)
        expect(File.read(File.join(root, "1/1/shape.json"))).to eq(before)
      end
    end
  end
end
