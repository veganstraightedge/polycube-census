# Changelog

## Unreleased

- Project scaffold: Ruby 4.0.5, RSpec, RuboCop, Scripts to Rule Them All, Brewfile, CC0 license.
- `Rotation`: the 24 proper rotations of the cubic lattice.
- `Polycube`: normalized value object with canonical form, mirror, chirality, symmetry order, growth.
- `Enumeration`: generates all free polycubes per size; verified against OEIS A000162 and A038119.
- `ShapeRecord` + `DataWriter`: one `data/<n>/<index>/shape.json` per shape, stable lexicographic indices, chiral twins cross-linked.
- `script/enumerate`: full run through n=8 — 8,152 shapes written, all counts matching OEIS (M1 complete).
