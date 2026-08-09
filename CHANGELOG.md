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
- `script/census --shard i/k`: parallel workers over disjoint shapes.
- n=8 sweep (6-way parallel, Shane's terminal): 6,921 of 6,922 octacubes tile (383 box / 6,538 torus). Exactly one survivor: 8/1309, the flat 3x3 square ring — the holey octomino, a classic 2D non-tiler whose hole in 3D is an open channel rings can thread. 8,151 certificates verified.
- 8/1309 stamped `open` after a raised-budget probe: provably no box through volume 128 (16 copies), no periodic block through index 64. The census's sole open question through n=8.
- Overnight hunt: no periodic tiling through index 152 (19 rings per block), lattice orbit dedup (20x fewer solves).
- `Surround` (corona-1) + `Corona` (depth-k Heesch test with Sinz AMO encoding, DRAT capture, live solver output).
- THEOREM: 8/1309, the square ring, has Heesch number 1 and does not tile space — corona-1 SAT (28-copy verified witness), corona-2 UNSAT (reproduced by kissat and CaDiCaL; DRAT proof drat-trim VERIFIED). It is the unique smallest non-tiling polycube. The census through n=8 is complete: zero open shapes.
- n=9 enumerated: 48,311 nonacubes, counts verified against OEIS.
- n=9 sweep: 48,200 of 48,311 nonacubes tile (782 box / 47,418 torus), every certificate independently verified. 111 survivors (60 mirror classes: 9 achiral + 51 chiral pairs) head to raised-budget probes and corona triage.
- README and PLAN.md caught up: ring theorem stamped into M5, n=9 campaign added, sample record's budget/credit fields match reality.
- Markdown docs reflowed: one line per paragraph and list item (soft-wrap in editors, cleaner diffs); LICENSE untouched.
- `script/census` budget flags (--max/--min volume and index): raised-budget probes that skip already-exhausted work; Pipeline reports each shape as it starts.
- n=9 triage rounds 1–2: 12 survivors fell at torus index 54–72 (every one a skew torus; the box stage went 0-for-12).
- Ring family side-quest: the 4×4 ring (2×2 tunnel) and 3×4 ring (1×2 tunnel) tile space (verified torus certificates, indices 48 and 20); the 5×5 ring (3×3 tunnel) has Heesch number 1 — corona-2 UNSAT in 8.8s, DRAT drat-trim VERIFIED. Conjecture on the table: a skinny rectangular ring tiles iff its tunnel has an even dimension.
- BREAKTHROUGH: 9/2127 (a flat achiral survivor) has a verified corona-2 — Heesch >= 2, the first shape in 3D known to wrap twice. No box through 128, no torus through 72. Corona-3 queued: UNSAT would make it the first Heesch-2 object in three dimensions.
- `MirroredCertificate` + `script/propagate-mirrors`: P tiles iff mirror(P) tiles — reflect a solved twin's certificate, verify independently, stamp. 5 survivors resolved for free; every future pair costs one solve, not two.
