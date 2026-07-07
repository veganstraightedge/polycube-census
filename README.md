# Polycube Tiling Census

A machine-verified census of the tiling behavior of every small polycube:
which shapes tile 3D space, which provably cannot — with their 3D Heesch
numbers, tabulated for the first time — and which resist classification.

In 2D this work has been done: exhaustive censuses classify every small
polyomino, polyhex, and polyiamond as tiler or non-tiler, crowned by Craig
Kaplan's [_Heesch Numbers of Unmarked Polyforms_](https://arxiv.org/abs/2105.09438).
In 3D, no equivalent exists. Even the smallest polycube that fails to tile
space appears to be undocumented — the 2D answer has been known for decades.
This project builds the 3D census in public, with a machine-checkable
certificate behind every claim.

## Verdicts

Every polycube through n = 8 cells gets exactly one:

| Verdict     | Meaning                                   | Certificate                                        |
| ----------- | ----------------------------------------- | -------------------------------------------------- |
| `TILES`     | fills all of space                        | a repeating block you can verify by hand or script |
| `NON_TILER` | provably cannot tile                      | an exhausted maximal corona (its Heesch number)    |
| `OPEN`      | survived every test within stated budgets | the budgets themselves                             |

`OPEN` is the interesting bucket: shapes that tile far but have no small
periodic pattern. Anything that lands there is a candidate for deeper study —
the 3D analogue of the hunt that produced the 2023 aperiodic monotile.

## Questions this settles

1. Do all 207 polycubes through n = 6 tile space? (Folklore says yes; folklore
   isn't proof.)
2. What is the smallest polycube that does not tile space?
3. What are the first 3D Heesch numbers? (No table of them exists anywhere.)
4. What is the smallest polycube that tiles only anisohedrally — never
   tile-transitively?
5. Does anything through n = 8 resist classification entirely?

## How it works

Each shape runs a gauntlet of increasingly expensive stages, stopping at the
first certificate: translation-lattice check, box tiling, periodic tiling on
skew tori, then corona-by-corona SAT (Boolean satisfiability) search until the
shape is certified either way or budgets are exhausted. Details, definitions,
and decision log: [PLAN.md](PLAN.md).

Three rules keep it honest:

- **No claim without a certificate.** Solver output is never trusted directly;
  an independent script rechecks every certificate with plain geometry.
- **The enumeration must reproduce OEIS** (the Online Encyclopedia of Integer
  Sequences: [A000162](https://oeis.org/A000162),
  [A038119](https://oeis.org/A038119)) before anything downstream runs.
- **Every verdict names its solver and verifier**, in the style of
  [WHUTS](https://whuts.org/) — including imported prior work, credited to the
  people who did it.

## The data

One folder per shape, one JSON record per folder:

```sh
data/
  1/1/shape.json      # the monocube
  ...
  6/122/shape.json    # "6/122" is this shape's permanent id
  ...
  8/6922/shape.json
```

Indices are assigned once, by lexicographic order of canonical forms, and
never renumbered — `6/122` is a citable name whose id is literally its path.
Records carry the shape's geometry (canonical cells, symmetry order,
chirality, a link to its mirror twin) and its verdict fields, which fill in
as the pipeline runs. Meshes (`model.stl`, tiling and corona assemblies) are
generated from certificates and land beside each record.

## Status

- [x] **M1 — Enumeration.** All 8,152 shapes through n = 8, counts matching OEIS A000162 and A038119 exactly.
- [ ] **M2 — SAT plumbing.** Box and torus stages; everything through n = 4 certified.
- [ ] **M3 — Folklore certified.** All 207 shapes through n = 6 carrying `TILES` certificates.
- [ ] **M4 — The heptacube sweep.** All 1,023 n = 7 shapes resolved; smallest non-tiler found or ruled out at this size.
- [ ] **M5 — n = 8.** Records hunt, incl. cross-checking the 261 tesseract unfoldings settled by [WHUTS](https://whuts.org/).
- [ ] **M6 — Publish.** Paper, OEIS sequences, browsable gallery.

## Running it

```
script/setup        # brew bundle (kissat) + bundle install
script/enumerate 8  # regenerate data/, verified against OEIS
script/test         # specs + linter
```

Ruby version is pinned in `.ruby-version`.

## Kin and prior art

- [Kaplan, _Heesch Numbers of Unmarked Polyforms_](https://arxiv.org/abs/2105.09438)
  and [isohedral/heesch-sat](https://github.com/isohedral/heesch-sat) — the 2D
  model for this census
- [WHUTS](https://whuts.org/) — hypercube unfoldings (a slice of our n = 8),
  and the credit model
- [The Poly Pages](http://www.recmath.com/PolyPages/PolyPages/Tiling.htm) —
  the hand-found folklore this census sets out to certify
- [BurrTools](https://burrtools.sourceforge.net/) — independent cross-check
  for box tilings
- [OEIS](https://oeis.org/) — ground truth for counts, destination for new
  sequences

## Glossary

- **polycube** — a solid made of unit cubes glued face-to-face
- **tiling** — filling all of space with copies of a shape, no gaps or overlaps
- **periodic** — a tiling that repeats on a lattice, like 3D wallpaper
- **Heesch number** — how many complete layers (coronas) of copies you can
  wrap around a shape before getting stuck; measures how far a non-tiler gets
- **anisohedral** — tiles space, but no tiling treats every copy identically
- **chiral** — differs from its mirror image; no rotation turns one into the other
- **SAT solver** — a program that decides whether a huge true/false formula
  can be satisfied; our tiling questions are encoded as such formulas
- **certificate** — data that lets anyone recheck a claim without trusting us

## Author and license

By [Shane Becker](https://veganstraightedge.com). Dedicated to the public
domain under [CC0 1.0](LICENSE) — reuse anything, credit appreciated.
