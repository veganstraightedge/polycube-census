# frozen_string_literal: true

RSpec.describe Census::AtHome::Coordinator, :home do
  let(:store) { Census::AtHome::Store.new }
  let(:coordinator) { described_class.new(store:) }
  let(:straight) { Census::Polycube.new(cells: [[0, 0, 0], [0, 0, 1], [0, 0, 2]]) }

  before do
    store.load_schema(File.expand_path("../../../db/at_home.sql", __dir__))
    store.reset
  end

  after { store.close }

  def seed_shape(shape, id: "3/1")
    store.add_unit(kind: "shape", shape_id: id, payload: { cells: shape.cells, budgets: {} })
  end

  it "hands a leased unit everything a worker needs to solve it" do
    seed_shape(straight)
    worker = coordinator.register(handle: "spec")
    unit = coordinator.lease(client_id: worker[:id])
    expect(unit).to include(kind: "shape", shape_id: "3/1", cells: straight.cells)
  end

  it "leases each unit to only one worker at a time" do
    seed_shape(straight)
    first = coordinator.register(handle: "first")
    second = coordinator.register(handle: "second")
    coordinator.lease(client_id: first[:id])
    expect(coordinator.lease(client_id: second[:id])).to be_nil
  end

  it "accepts a valid certificate and closes the unit" do
    seed_shape(straight)
    worker = coordinator.register(handle: "spec")
    unit = coordinator.lease(client_id: worker[:id])
    certificate = Census::TorusSearch.new(shape: straight).certificate

    answer = coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "tiler",
                                payload: { certificate: })
    expect(answer[:accepted]).to be(true)
    expect(coordinator.status[:units]).to eq({ "done" => 1 })
  end

  it "rejects a forged certificate and returns the unit to the queue" do
    seed_shape(straight)
    worker = coordinator.register(handle: "liar")
    unit = coordinator.lease(client_id: worker[:id])
    forged = { "type" => "torus", "lattice" => [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
               "placements" => [{ "rotation" => 0, "offset" => [0, 0, 0] }] }

    answer = coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "tiler",
                                payload: { certificate: forged })
    expect(answer[:accepted]).to be(false)
    expect(coordinator.lease(client_id: worker[:id])).not_to be_nil
  end

  it "counts a worker's accepted and rejected submissions" do
    seed_shape(straight)
    worker = coordinator.register(handle: "mixed")
    unit = coordinator.lease(client_id: worker[:id])
    coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "tiler", payload: { certificate: nil })
    unit = coordinator.lease(client_id: worker[:id])
    coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "tiler",
                       payload: { certificate: Census::TorusSearch.new(shape: straight).certificate })

    expect(coordinator.status[:clients].first).to include(handle: "mixed", accepted: 1, rejected: 1)
  end

  it "credits an unapproved display name as the opaque handle" do
    worker = coordinator.register(handle: "client-abc123", display_name: "Booger Butt")
    expect(store.credit_string(worker[:id])).to eq("client-abc123")
  end

  it "credits an approved display name once a human approves it" do
    worker = coordinator.register(handle: "client-abc123", display_name: "Ada Lovelace")
    store.approve_display_name(worker[:id])
    expect(store.credit_string(worker[:id])).to eq("Ada Lovelace")
  end

  it "rejects a cube model that contradicts its own cube" do
    store.add_unit(kind: "cube", shape_id: "9/2127", payload: { cnf_path: "/nonexistent.cnf", cube: [3, -4] })
    worker = coordinator.register(handle: "spec")
    unit = coordinator.lease(client_id: worker[:id])

    answer = coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "sat", payload: { model: [1, 2, 4] })
    expect(answer[:accepted]).to be(false)
  end

  # A refutation that names no artifact cannot be audited, ever. It used to be
  # taken on the volunteer's word.
  describe "cube refutations" do
    def refute(payload)
      store.add_unit(kind: "cube", shape_id: "9/2127", payload: { cnf_path: "/nonexistent.cnf", cube: [3] })
      worker = coordinator.register(handle: "spec")
      unit = coordinator.lease(client_id: worker[:id])

      coordinator.submit(unit_id: unit[:id], client_id: worker[:id], verdict: "unsat", payload:)
    end

    let(:digest) { "a" * 64 }

    it "rejects one that names no proof" do
      expect(refute(cube: [3])).to include(accepted: false, note: /names no proof/)
    end

    it "rejects a digest that did not come from hashing a file" do
      expect(refute(proof: { sha256: "not-a-digest", bytes: 8 })).to include(accepted: false, note: /malformed/)
    end

    # kissat writes nothing when it never derives a clause. An absence of bytes
    # is an absence of evidence.
    it "rejects an empty proof" do
      expect(refute(proof: { sha256: digest, bytes: 0 })).to include(accepted: false, note: /refutes nothing/)
    end

    it "accepts one that names a proof, and says plainly that it is unchecked" do
      expect(refute(proof: { sha256: digest, bytes: 8 })).to include(accepted: true, note: /unchecked/)
    end

    it "returns the unit to the queue when the refutation is refused" do
      refute(cube: [3])

      expect(coordinator.status[:units]).to eq({ "pending" => 1 })
    end
  end
end
