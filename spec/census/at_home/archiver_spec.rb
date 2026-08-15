# frozen_string_literal: true

require "tmpdir"

RSpec.describe Census::AtHome::Archiver, :home do
  let(:store) { Census::AtHome::Store.new }
  let(:coordinator) { Census::AtHome::Coordinator.new(store:) }
  let(:straight) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]]) }

  before do
    store.load_schema(File.expand_path("../../../db/at_home.sql", __dir__))
    store.reset
  end

  after { store.close }

  def solved_unit(root, handle: "spec", display_name: nil)
    Census::DataWriter.new(root:).write(Census::Enumeration.new(max_size: 3))
    record = JSON.parse(File.read(File.join(root, "3/1/shape.json")), symbolize_names: true)
    store.add_unit(kind: "shape", shape_id: "3/1", payload: { cells: record[:cells], budgets: {} })
    worker = coordinator.register(handle:, display_name:)
    unit = coordinator.lease(client_id: worker[:id])
    certificate = Census::TorusSearch.new(shape: Census::Polycube.new(cells: record[:cells])).certificate
    coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "tiler", payload: { certificate: })
    worker
  end

  it "writes a verified result into data/ as a stamped record" do
    Dir.mktmpdir do |root|
      solved_unit(root)
      expect(described_class.new(store:, root:).promote).to eq(["3/1"])

      record = JSON.parse(File.read(File.join(root, "3/1/shape.json")), symbolize_names: true)
      expect(record[:verdict]).to eq("tiler")
      expect(Census::Verifier.new(certificate: record[:certificate], shape: straight)).to be_valid
    end
  end

  it "credits the opaque handle when a display name is not approved" do
    Dir.mktmpdir do |root|
      solved_unit(root, handle: "client-7f3a", display_name: "unapproved name")
      described_class.new(store:, root:).promote
      record = JSON.parse(File.read(File.join(root, "3/1/shape.json")), symbolize_names: true)
      expect(record.dig(:credits, :solved_by)).to include("client-7f3a")
    end
  end

  it "credits an approved display name" do
    Dir.mktmpdir do |root|
      worker = solved_unit(root, handle: "client-7f3a", display_name: "Ada Lovelace")
      store.approve_display_name(worker[:id])
      described_class.new(store:, root:).promote
      record = JSON.parse(File.read(File.join(root, "3/1/shape.json")), symbolize_names: true)
      expect(record.dig(:credits, :solved_by)).to include("Ada Lovelace")
    end
  end

  it "is idempotent: a second pass writes nothing" do
    Dir.mktmpdir do |root|
      solved_unit(root)
      promoter = described_class.new(store:, root:)
      promoter.promote
      expect(promoter.promote).to be_empty
    end
  end

  it "refuses to archive a certificate that fails verification at promotion time" do
    Dir.mktmpdir do |root|
      solved_unit(root)
      # A coordinator that had been compromised after accepting the result.
      store.send(:synchronize) do |connection|
        connection.exec("UPDATE results SET payload = '{\"certificate\":{\"type\":\"torus\",\"lattice\":[[1,0,0],[0,1,0],[0,0,1]],\"placements\":[{\"rotation\":0,\"offset\":[0,0,0]}]}}'::jsonb")
      end

      notes = []
      expect(described_class.new(store:, root:, report: ->(line) { notes << line }).promote).to be_empty
      expect(notes.first).to match(/REFUSED/)
    end
  end
end
