# Changelog

## Unreleased

- Project scaffold: Ruby 4.0.5, RSpec, RuboCop, Scripts to Rule Them All, Brewfile, CC0 license.
- `Rotation`: the 24 proper rotations of the cubic lattice.
- `Polycube`: normalized value object with canonical form, mirror, chirality, symmetry order, growth.
- `Enumeration`: generates all free polycubes per size; verified against OEIS A000162 and A038119.
- `ShapeRecord` + `DataWriter`: one `data/<n>/<index>/shape.json` per shape, stable lexicographic indices, chiral twins cross-linked.
- `script/enumerate`: full run through n=8 — 8,152 shapes written, all counts matching OEIS (M1 complete).
- Public README.
- GitHub Actions CI (`script/cibuild`: specs + linter).
- `SAT::Instance` + `SAT::Kissat`: CNF construction and solver round-trip.
- `BoxTiling` + `BoxSearch`: exact-cover box stage, smallest box by ascending volume.
- `Verifier`: geometry-only recheck of box certificates (no solver trust).
- `Pipeline` + `script/census`: stamps verified verdicts into `data/`.
- First verdicts: all 12 shapes through n=4 are `tiler`, each with a verified box certificate (screws pair into 2x2x2; skew tetracube needs a 2x3x4).
- Removed RuboCop from the toolchain; style passes happen manually at the end, checked against the suite and generated output.
- `Lattice`: HNF sublattices of Z^3 (enumeration validated against known sublattice counts) with quotient reduction.
- `TorusTiling` + `TorusSearch`: periodic tilings on skew lattices; wired into `Verifier` and `Pipeline` as the box stage's fallback.
- `script/verify`: independent geometry-only recheck of every stored certificate.
- M3: all 207 shapes through n=6 certified as tilers (n=5: 16 box / 13 torus; n=6: 68 box / 98 torus), every certificate independently verified.
- M4 headline: all 1,023 heptacubes tile space (36 box / 987 torus) — the smallest non-tiling polycube has at least 8 cells, unlike 2D where heptominoes already fail. 1,230 certificates verified.
