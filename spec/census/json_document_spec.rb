# frozen_string_literal: true

RSpec.describe Census::JSONDocument do
  it "puts one top-level key per line and keeps the caller's order" do
    record = { id: "5/1", n: 5 }

    expect(described_class.new(record).generate).to eq(%({\n  "id": "5/1",\n  "n": 5\n}\n))
  end

  it "sorts nested hash keys" do
    record = { certificate: { type: "box", box: [1, 1, 5] } }

    expect(described_class.new(record).generate).to include(%("certificate": {"box":[1,1,5],"type":"box"}))
  end

  it "sorts hash keys nested inside arrays" do
    record = { placements: [{ rotation: 0, offset: [0, 0, 0] }] }

    expect(described_class.new(record).generate).to include(%("placements": [{"offset":[0,0,0],"rotation":0}]))
  end

  it "leaves array order alone, because array order is data" do
    record = { cells: [[9, 9, 9], [0, 0, 0]] }

    expect(described_class.new(record).generate).to include(%("cells": [[9,9,9],[0,0,0]]))
  end

  # The whole point: the same content from two writers becomes the same file.
  it "generates identical output regardless of the order a writer built it in" do
    pipeline_order = { certificate: { type: "box", box: [1, 1, 5] } }
    jsonb_order    = { certificate: { box: [1, 1, 5], type: "box" } }

    expect(described_class.new(jsonb_order).generate).to eq(described_class.new(pipeline_order).generate)
  end
end
