# A Polycube Tiling Census

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

Every polycube through `n = 8` cells gets exactly one:

| Verdict     | Meaning                                   | Certificate                                        |
| ----------- | ----------------------------------------- | -------------------------------------------------- |
| `TILER`     | fills all of space                        | a repeating block you can verify by hand or script |
| `NON_TILER` | provably cannot tile                      | an exhausted maximal corona (its Heesch number)    |
| `OPEN`      | survived every test within stated budgets | the budgets themselves                             |

`OPEN` is the interesting bucket:
shapes that tile far but have no small periodic pattern.
Anything that lands there is a candidate for deeper study
— the 3D analogue of the hunt that produced the 2023 aperiodic monotile.
(The Hat: [Numberphile 1](https://youtu.be/ArADlJx7SlU),
[Numberphile 2](https://youtu.be/_ZS3Oqg1AX0).
Spectre: [Ayliean 1](https://youtu.be/IfVwelta1fE),
[Ayliean 2](https://youtu.be/sLQrHz7CQf4).)

## Questions this aims to answer

1. Do all 207 polycubes through `n = 6` tile space? (Folklore says yes, but folklore isn't proof.)
2. What is the smallest polycube that does not tile space?
3. What are the first 3D Heesch numbers? (AFAICT, no table of them already exists anywhere.)
4. What is the smallest polycube that tiles only anisohedrally — never tile-transitively?
5. Does anything through `n = 8` resist classification entirely?

## How it works

Each shape runs a gauntlet of increasingly expensive stages,
stopping at the first certificate:
translation-lattice check, box tiling, periodic tiling on skew tori,
then corona-by-corona SAT (Boolean satisfiability)
search until the shape is certified either way or budgets are exhausted.
Details, definitions, and decision log: [PLAN.md](PLAN.md).

Three rules keep it honest:

- **No claim without a certificate.** Solver output is never trusted directly. An independent script rechecks every certificate with plain geometry.
- **The enumeration must reproduce OEIS** (the Online Encyclopedia of Integer Sequences: [A000162](https://oeis.org/A000162), [A038119](https://oeis.org/A038119)) before anything downstream runs.
- **Every verdict names its solver and verifier**, in the style of [WHUTS](https://whuts.org) — including imported prior work, credited to the people who did it.

## The data

One folder per shape, one JSON record per folder:

```sh
data/
  1/1/shape.json     # the monocube
  ...
  6/122/shape.json   # "6/122" is this shape's permanent id
  ...
  8/6922/shape.json
```

Indices are assigned once, by lexicographic order of canonical forms, and never renumbered
— `6/122` is a citable name whose ID is literally its path.
Records carry the shape's geometry
(canonical cells, symmetry order, chirality, a link to its mirror twin)
and its verdict fields, which fill in as the pipeline runs.
Meshes (`model.stl`, tiling and corona assemblies)
are generated from certificates and land beside each record.

## Status

- [x] **M1 — Enumeration.** All 8,152 shapes through `n = 8` with counts matching OEIS [A000162](https://oeis.org/A000162) and [A038119](https://oeis.org/A038119) exactly.
- [ ] **M2 — SAT plumbing.** Box and torus stages with everything through `n = 4` certified.
- [ ] **M3 — Folklore certified.** All 207 shapes through `n = 6` carrying `TILER` certificates.
- [ ] **M4 — The heptacube sweep.** All 1,023 `n = 7` shapes resolved with smallest non-tiler found or ruled out at this size.
- [ ] **M5 — N8.** Records hunt, including cross-checking the 261 tesseract unfoldings settled by [WHUTS](https://whuts.org).
- [ ] **M6 — Publish.** Browsable gallery.
- [ ] **M7 — Publish.** OEIS sequences.
- [ ] **M8 — Publish.** Paper.

## Running it

```sh
script/setup        # brew bundle (kissat) + bundle install
script/enumerate 8  # regenerate data/, verified against OEIS
script/test         # specs + linter
```

Ruby version is pinned in `.ruby-version`.

## Kin and prior art

- [BurrTools](https://burrtools.sourceforge.net) — independent cross-check for box tilings
- [Kaplan, _Heesch Numbers of Unmarked Polyforms_](https://arxiv.org/abs/2105.09438) and [isohedral/heesch-sat](https://github.com/isohedral/heesch-sat) — the 2D prior art and inspiration for this census
- [OEIS](https://oeis.org) — ground truth for counts, and will be the destination for any new sequences
- [The Poly Pages](http://www.recmath.com/PolyPages/PolyPages/Tiling.htm) — the hand-found folklore that this census aims to certify
- [WHUTS](https://whuts.org) — hypercube unfoldings (a slice of our `n = 8`), and an example of attribution/credit to contributors (solvers/verifiers)

## Glossary

- **anisohedral** — tiles space, but no tiling treats every copy identically
- **certificate** — data that lets anyone recheck a claim without trusting us
- **chiral** — differs from its mirror image, no rotation turns one into the other
- **Heesch number** — how many complete layers (coronas) of copies you can wrap around a shape before getting stuck, measures how far a non-tiler gets
- **periodic** — a tiling that repeats on a lattice, like 3D wallpaper
- **polycube** — a solid made of unit cubes glued face-to-face, like Tetris pieces (tetracubes)
- **SAT solver** — a program that decides whether a huge `true/false` formula can be satisfied, our tiling questions are encoded as such formulas
- **tiling** — filling all of space with copies of a shape, no gaps or overlaps

## Author and license

By [Shane Becker](https://veganstraightedge.com).
Dedicated to the public domain under [CC0 1.0](LICENSE)
— reuse anything, credit is appreciated but not required.

---

Your heart is as free as the air you breathe. \
The ground you stand on is liberated territory.
