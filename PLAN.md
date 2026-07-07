# Polycube Tiling Census — Technical Plan

A machine-verified census of the tiling behavior of all small polycubes:
which ones tile 3D space, which provably can't (and their 3D Heesch numbers),
and which resist classification. Modeled on Craig Kaplan's 2D census
(_Heesch Numbers of Unmarked Polyforms_, [arXiv:2105.09438](https://arxiv.org/abs/2105.09438)),
which has no 3D counterpart.

## Goal

For every polycube up to size 8, produce a verdict with a machine-checkable certificate:

- `TILER` — with the strongest certificate found (translation lattice, box, or periodic block)
- `NON_TILER` — with its 3D Heesch number and the frozen maximal corona
- `OPEN` — survived all tests within documented budgets (the interesting shortlist)

Headline unclaimed facts this settles, in order of reachability:

1. Certify the folklore that all polycubes through n=6 tile space (currently rests on
   hand-found patterns catalogued on
   [the Poly Pages](http://www.recmath.com/PolyPages/PolyPages/Tiling.htm), not proofs).
2. Find the smallest non-tiling polycube (2D analogue — a heptomino — known for decades;
   3D answer undocumented).
3. Tabulate the first 3D Heesch numbers.
4. Identify the smallest anisohedral polycube (tiles, but never tile-transitively).
5. Publish anything that lands in `OPEN` as einstein candidates.

## Scale

| n   | shapes (rotations only, [A000162](https://oeis.org/A000162)) | mirror-identified ([A038119](https://oeis.org/A038119)) | cumulative shapes |
| --- | -----------------------------------------------------------: | ------------------------------------------------------: | ----------------: |
| 1   |                                                            1 |                                                       1 |                 1 |
| 2   |                                                            1 |                                                       1 |                 2 |
| 3   |                                                            2 |                                                       2 |                 4 |
| 4   |                                                            8 |                                                       7 |                12 |
| 5   |                                                           29 |                                                      23 |                41 |
| 6   |                                                          166 |                                                     112 |               207 |
| 7   |                                                        1,023 |                                                     607 |             1,230 |
| 8   |                                                        6,922 |                                                   3,811 |             8,152 |

P tiles iff its mirror tiles (reflect the whole tiling), so compute once per
mirror-identified class (753 classes through n=7) and report per shape.
First paper target: n ≤ 7. Stretch: n = 8.

## Definitions (decision log)

- **D1 — Shape identity:** polycubes equivalent under the 24 proper rotations.
  Mirror twins are distinct shapes cross-linked by `mirror_id` (a printed left screw
  can't become a right screw).
- **D2 — Allowed motions in tilings:** two columns.
  `tiles_rotations_only` (24 orientations — the physical/printable reading) and
  `tiles_with_reflections` (48 — i.e., tiling by the pair {P, mirror(P)}).
  The gap between them (chiral shapes needing their mirror) is itself census content;
  this distinction is exactly where the 2D Spectre story lived.
- **D3 — Corona (for Heesch numbers):** corona i is a set of non-overlapping copies
  covering every cell 26-adjacent (face, edge, or vertex) to the configuration through
  corona i−1. Lift of Kaplan's 2D conventions; run face-only adjacency as a sensitivity
  check on any record-holders.
- **D4 — Verdicts are about tilings of all of ℝ³**, not slabs or boxes per se
  (a box certificate implies a space tiling).

## Pipeline

Each shape runs through increasingly expensive stages; stop at the first certificate.

- **Stage 0 — cheap filters.** Enclosed-cavity detection (a cavity smaller than n cells
  is an instant non-tiling proof; irrelevant at n ≤ 8, matters later). Symmetry group,
  chirality, bounding box.
- **Stage 1 — translation lattice.** Torus test (Stage 3) restricted to the identity
  orientation. Catches most small shapes instantly.
- **Stage 2 — box tiling.** Exact cover of an a×b×c box by all placements of all
  orientations. Try boxes in increasing volume (multiples of n) up to budget.
  Certificate: placement list. Cross-validate against
  [BurrTools](https://burrtools.sourceforge.net) on a sample.
- **Stage 3 — periodic tiling (torus SAT).** Tile the quotient ℤ³/L for sublattices L,
  enumerated by Hermite normal form in increasing index (index a multiple of n).
  Skew lattices matter: periodic tilings need not have orthogonal periods, and
  diagonal-only tori would miss them. SAT (Boolean satisfiability — encode constraints
  as a true/false formula, hand it to an off-the-shelf solver): one variable per
  (orientation, offset mod L),
  exactly-one constraint per quotient cell. Certificate: L plus placement list.
- **Stage 4 — Heesch / corona SAT.** Seed copy fixed at origin (breaks symmetry).
  Ask SAT for k complete coronas per D3; UNSAT at k+1 after SAT at k ⇒ Heesch number k,
  shape is a certified non-tiler. Budgets on k and on placement-universe radius.
- **Stage 5 — shortlist.** Anything still unresolved: record exact budgets exhausted
  (max torus index, max corona depth, solver time) so `OPEN` is a precise statement,
  then publish the shortlist.

Order the sweep so Stages 1–3 run over everything first (most shapes are tilers);
Stage 4 only sees the survivors.

## Data model

One folder per shape — a folder of folders keyed by cube count, then a stable
1-based index within that count:

```
data/
  1/
    1/          # the monocube
  2/
    1/
  3/
    1/
    2/
  ...
  8/
    1/
    ...
    6922/
```

Each shape folder holds:

- `shape.json` — the record below; with its certificate, the single source of truth
- `model.stl` — the shape alone, watertight and printable (GitHub previews STL in-browser)
- `tiling.obj` + `tiling.mtl` — tilers only: a chunk of one certified tiling,
  one color per copy (OBJ because STL carries no color)
- `corona.obj` — certified non-tilers only: the maximal corona, seed highlighted,
  layers colored by corona number (the 3D Heesch witness)
- `render.png` — quick browsing without a 3D viewer
- `cnf/` — published instances backing UNSAT claims

All meshes are generated from certificates by `script/gallery` — derived data,
regenerable, never hand-edited. Rollup tables likewise.

Index stability rule: within each n, shapes are numbered by the lexicographic order
of their canonical forms, assigned once and never renumbered — so `7/412` is a
permanent, citable name for a shape.

```json
{
  "id": "7/412",
  "cells": [
    [0, 0, 0],
    [1, 0, 0]
  ],
  "n": 7,
  "symmetry_order": 1,
  "chiral": true,
  "mirror_id": "7/413",
  "verdict": "tiler",
  "tiles_rotations_only": true,
  "tiles_with_reflections": true,
  "certificate": {
    "type": "torus",
    "lattice": [
      [4, 0, 0],
      [1, 2, 0],
      [0, 0, 7]
    ],
    "placements": [{ "rotation": 5, "offset": [0, 0, 0] }]
  },
  "heesch": null,
  "budgets": { "max_torus_index": 56, "max_corona": 3, "solver_seconds": 41.2 },
  "credits": {
    "solved_by": "census-pipeline v1.0",
    "verified_by": null,
    "prior_art": null
  }
}
```

`cells` is the canonical form: translate to the origin corner, take the
lexicographically minimal cell list over all 24 rotations.

Credits follow the [WHUTS](https://whuts.org) model: every verdict names its solver
(a human, or the pipeline at a specific version) and, once someone independently
rechecks it, its verifier. Where a shape was already settled by prior work — the
261 tesseract unfoldings on WHUTS, hand-found Poly Pages patterns — import the
solution as a certificate, cross-check it, and credit the original solver with a
link in `prior_art`.

## Verification

Trust nothing from the solver directly:

- `script/verify` independently rechecks every certificate with plain geometry
  (coverage exactly once, placements congruent to the canonical shape) — no SAT involved.
  This is what makes the census citable.
- UNSAT verdicts (non-tilers, Heesch bounds): publish the CNF (conjunctive normal form)
  instances; produce DRAT proofs (a machine-checkable trace of the solver's reasoning,
  verified with [drat-trim](https://github.com/marijnheule/drat-trim)) for
  record-holders and headline facts only —
  proof files are huge.
- Global sanity check: enumeration counts must reproduce
  [OEIS](https://oeis.org) (Online Encyclopedia of Integer Sequences)
  [A000162](https://oeis.org/A000162) and [A038119](https://oeis.org/A038119)
  exactly before anything downstream runs.

## Tooling

- **Ruby** for everything orchestral: enumeration, canonical forms, CNF generation,
  certificate verification, reporting. Shapes at this scale are trivial for Ruby.
- **[kissat](https://github.com/arminbiere/kissat)** (via Homebrew) as the SAT
  workhorse; DIMACS files (the standard plain-text CNF format) in, witness out.
  [CaDiCaL](https://github.com/arminbiere/cadical) as fallback / second opinion.
- **RSpec** with real fixture files in `spec/fixtures/` (known tilers, known
  certificates, hand-built coronas).
- **Mesh export written directly in Ruby** — STL (the standard 3D-printing mesh
  format) for single shapes, OBJ/MTL for colored multi-copy assemblies; both are
  simple text formats, no mesh library needed. GLB for the web gallery can come
  at M6 from the same certificates.
- Scripts to Rule Them All:

```
script/setup      # brew install kissat, bundle install
script/test       # rspec --format progress
script/enumerate  # generate data/shapes/ for n ≤ N, check counts vs OEIS
script/census     # run pipeline stages over unresolved shapes
script/verify     # independently recheck every stored certificate
script/gallery    # emit STLs and renders
```

## Milestones

- **M1 — Scaffold + enumerator.** Repo, canonical forms, enumeration through n=8,
  counts match A000162/A038119. Acceptance: `script/enumerate 8` reproduces OEIS.
- **M2 — SAT plumbing.** Box + torus stages working; all shapes n ≤ 4 certified,
  results hand-checkable (screws pair into a 2×2×2 cube, etc.).
- **M3 — Folklore certified.** All 207 shapes through n=6 carry `TILER` certificates.
  (Publishing anything, incl. OEIS submissions, waits until after M5 — see M6–M8.)
- **M4 — The heptacube sweep.** All 1,023 n=7 shapes resolved or budgeted-OPEN.
  Headline: smallest non-tiler (or proof all heptacubes tile), first 3D Heesch table.
  This is the paper.
- **M5 — n=8.** Records hunt: max 3D Heesch, first anisohedral, shortlist growth.
  Includes the 261 tesseract unfoldings already settled by the
  [WHUTS](https://whuts.org) community (all tile; solutions collected via
  Moritz Firsching's code, independently verified by Georgios Papoutsis) —
  import their tilings as certificates with per-shape solver credits, and use the
  overlap as an external cross-check of our pipeline.
- **M6 — Publish: gallery.** Browsable gallery generated from certificates,
  printed record-holders.
- **M7 — Publish: OEIS.** New sequences submitted (number of n-polycubes that tile
  a box, that tile space, non-tilers by Heesch number, …).
- **M8 — Publish: paper.** [Geombinatorics](https://geombina.uccs.edu) fits the genre;
  arXiv math.CO/math.MG with endorsement.
  Writing convention: keep standard math idioms (`iff`, coronas, anisohedral, …) in the
  text, and include a glossary footnote/appendix expanding them for non-mathematicians.

## Someday / future

- **Lean (formal verification), two hooks.** At M4: check solver UNSAT proofs with a
  formally verified checker (Lean 4's LRAT checker or cake_lpr) for headline claims —
  drat-trim is itself unverified C. Post-M8 stretch: formalize the encoding's
  soundness ("CNF UNSAT ⇒ no tiling of ℤ³") in Lean, making the smallest-non-tiler
  result a fully machine-checked theorem; potential Lean-community collaboration.
- **Box-order addendum.** For shapes holding only torus certificates, rerun the box
  stage at rising budgets (an "upgrade pass" — the pipeline must revisit
  already-stamped shapes seeking stronger certificates). First box found in
  ascending volume = the shape's exact box order (Klarner's "order", unexplored in
  3D; Dahlke's heptominoes hit orders 76 and 92 in 2D). Survivors get certified
  lower bounds ("no box through k copies"); diffable data releases per budget raise.
- **Manim visualizations + YouTube.** After M6, use the census as source material for
  Manim animations (tilings assembling, coronas growing and getting stuck) and a video
  or few. Certificates are the animation data — placements are keyframes — so this
  stays a pure consumer of `data/` and needs nothing from the pipeline now.

## Risks and open questions

- **Scoop / prior-art risk.** The folklore claim and the unanswered forum question
  suggest this is unclaimed. Passive literature searches (which reveal nothing)
  continue throughout. Active outreach — Poly Pages maintainer,
  [the tiling group thread](https://www.facebook.com/groups/tiling/posts/1150714768685400),
  Kaplan — is deliberately deferred until after n=8 is done (decided 2026-07-06):
  math first, packaging and comms after, with results in hand.
- **Corona SAT blowup in 3D.** Placement universes grow much faster than in 2D.
  Mitigations: tight radius bounds, incremental solving, aggressive symmetry breaking
  on the seed. Unknown until measured — measure early on a few n=7 shapes.
- **Torus budget misses long-period tilers.** A tiler whose minimal periodic block
  exceeds the budget lands in `OPEN`. Acceptable: `OPEN` verdicts state their budgets.
- **Definition sensitivity.** Heesch values can depend on D3's adjacency choice;
  report the convention prominently and sensitivity-check records.
- **The einstein jackpot is not the plan.** Anything in `OPEN` after honest budgets
  is a finding to publish, not a proof of aperiodicity — proving that would be a
  separate (human) project. The census is the contribution either way.

## Week 1

1. Literature pass: "space-filling polycubes", heptacube tiling, 3D Heesch,
   anisohedral polycubes. Confirm nobody has published the sweep.
2. Check whether Kaplan's Heesch/isohedral SAT code is public
   (per _Detecting Isohedral Polyforms with a SAT Solver_,
   [arXiv:2406.16407](https://arxiv.org/abs/2406.16407)); steal encodings if so.
3. M1: enumerator + canonical form + OEIS count check.
4. First SAT round-trip: L-tricube → CNF → kissat → certificate → `script/verify` green.
