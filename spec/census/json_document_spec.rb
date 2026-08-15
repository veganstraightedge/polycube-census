# frozen_string_literal: true

RSpec.describe Census::JSONDocument do
  def generate(record) = described_class.new(record).generate

  it "puts one top-level key per line and keeps the caller's order" do
    expect(generate(id: "5/1", n: 5)).to eq(%({\n  "id": "5/1",\n  "n": 5\n}\n))
  end

  it "sorts nested hash keys" do
    expect(generate(budgets: { torus_max_index: 48, box_max_volume: 96 }))
      .to include(%("budgets": { "box_max_volume": 96, "torus_max_index": 48 }))
  end

  it "keeps arrays of non-hashes inline, so cells read as coordinates" do
    expect(generate(cells: [[0, 0, 0], [0, 1, 2]])).to include(%("cells": [[0, 0, 0], [0, 1, 2]]))
  end

  it "leaves array order alone, because array order is data" do
    expect(generate(cells: [[9, 9, 9], [0, 0, 0]])).to include(%("cells": [[9, 9, 9], [0, 0, 0]]))
  end

  it "breaks an array of hashes one element per line" do
    document = generate(placements: [{ rotation: 0, offset: [0, 0, 0] }, { rotation: 1, offset: [0, 2, 1] }])

    expect(document).to eq(<<~JSON)
      {
        "placements": [
          { "offset": [0, 0, 0], "rotation": 0 },
          { "offset": [0, 2, 1], "rotation": 1 }
        ]
      }
    JSON
  end

  # Never half inline and half stacked: if placements break, the certificate
  # holding them breaks too.
  it "breaks a hash when one of its children broke" do
    document = generate(certificate: { type: "box", box: [1, 1, 5], placements: [{ rotation: 0 }] })

    expect(document).to eq(<<~JSON)
      {
        "certificate": {
          "box": [1, 1, 5],
          "placements": [
            { "rotation": 0 }
          ],
          "type": "box"
        }
      }
    JSON
  end

  it "renders empty containers without stray whitespace" do
    expect(generate(budgets: {}, cells: [])).to include(%("budgets": {}), %("cells": []))
  end

  it "leaves long strings on one line, because JSON cannot wrap them" do
    prose = "mirror of 9/42947, whose corona-2 refutation forbids it"

    expect(generate(certificate: { refutation: prose })).to include(%("refutation": "#{prose}"))
  end

  # The whole point: the same content from two writers becomes the same file.
  it "generates identical output regardless of the order a writer built it in" do
    pipeline_order = { certificate: { type: "box", box: [1, 1, 5] } }
    jsonb_order    = { certificate: { box: [1, 1, 5], type: "box" } }

    expect(generate(jsonb_order)).to eq(generate(pipeline_order))
  end
end
