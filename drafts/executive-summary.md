# Polycube Tiling Census — Executive Summary (2026-08-14)

Written for Shane, on the `homework` branch, as of the night the torus phase closed.

## What this project is

A machine-verified census of the tiling behavior of every polycube through nine cells — 56,463 shapes: which tile 3D space, which provably cannot, and which resist classification. Every claim carries a certificate a stranger can recheck without trusting us: tilings verified by plain geometry, refutations replayed by an independent proof checker. Modeled on Kaplan's 2D census ([_Heesch Numbers of Unmarked Polyforms_, arXiv:2105.09438](https://arxiv.org/abs/2105.09438), code and data at [isohedral/heesch-sat](https://github.com/isohedral/heesch-sat)); nothing like it existed in 3D, and we now know the structural reason why (the finite classification the 2D method marches through provably has no 3D analogue).

## The scoreboard

| population                     |  count | status                                                                                                                                                                            |
| ------------------------------ | -----: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| certified tilers               | 56,447 | done — 48,298 of them nonacubes, every certificate independently verified                                                                                                         |
| certified non-tilers           |      6 | the square ring (n=8), the twisted pair 8219/8220, the Greek cross, the triskelion pair 42947/42969 — first four proof-backed, triskelion ledger-backed pending its DRAT campaign |
| open club (Heesch ≥ 2)         |      8 | the staircase, 2650/2671, 8203/8214, 20656, 24025/24830 — all with verified two-layer burial witnesses                                                                            |
| unresolved                     |      0 | every shape through n=9 carries a verdict                                                                                                                                         |
| open questions beyond verdicts |      1 | does the staircase wrap a third time? (Heesch exactly 2 vs. ≥ 3)                                                                                                                  |

## Headline results, in order of magnitude

1. **The square ring theorem (n=8).** The unique smallest polycube that cannot tile space; Heesch number 1; corona-2 impossibility proven by two independent solvers and drat-trim-verified. The census through n=8 is complete with zero open shapes.
2. **The first Heesch ≥ 2 objects in three dimensions.** Before this week, no 3D shape was known to admit even two complete coronas. The census found eight (five mirror-classes), each with independently verified witnesses — the largest a 370-copy double burial. Deep faking turns out to be the _default_ behavior of torus-resistant nonacubes, not an anomaly.
3. **The plus sign doesn't tile space.** 9/48258, the 5×5 Greek cross — the census's most tellable theorem: refuted in 140 seconds, proof verified end-to-end on a borrowed server.
4. **n=9 is complete — zero unresolved shapes.** The last holdout, the triskelion 9/42947 (three perpendicular arms braided around a vacant corner), fell to a cube-and-conquer campaign: 12,861 cube verdicts across three provably-covering splits, zero SATISFIABLE, after a single-core attack on the whole formula ran 28 hours without resolving. Its mirror twin followed by reflection. Ledger-backed pending the per-cube DRAT campaign.
5. **The ring-family side quest.** The 4×4 and 3×4 rings tile (verified certificates); the 5×5 ring is a proven non-tiler (Heesch 1, verified); conjecture on the table: a skinny rectangular ring tiles iff its tunnel has an even dimension.

## The staircase (9/2127) — the census's central mystery

A flat, 9-cell staircase with a pinch-sealed 1×1 tunnel — the only sealed-hole shape among all survivors. It has: no box through volume 128, no torus through index 72, a verified 228-copy corona-2, and it has now survived roughly **700 combined core-hours** of corona-3 interrogation across six solver instances, two continents, and three cube-and-conquer campaigns (4,096-way, 192-way flank, 25,920-way clause-split) that closed over 99.7% of the assignment space without finding either a witness or completing the refutation. The residual hardness concentrates fractally in "assert nothing" regions that our splitters thin but never eliminate. Two deep-state veterans (55+ and 72+ hours) continue; the dignified endpoint, if they don't speak, is a documented-budget `open` declaration — which the schema already supports and the shape has thoroughly earned.

## Infrastructure built along the way (all tested, all committed)

- **Pipeline:** box/torus/corona SAT stages, budget floors and ceilings, `--ids` explicit work lists, STOP-file graceful drain, timestamped logs.
- **Verification:** geometry-only `script/verify` over every certificate (56k in ~10 s); the D2 achiral invariant; drat-trim vendored and exercised on proofs from 123 MB to 21 GB (the latter: 8.4 hours, 2 billion resolution steps, VERIFIED).
- **Mirror machinery:** certificates, corona witnesses, and verdicts all propagate to twins by reflection with independent re-verification — every pair costs one solve.
- **Cube-and-conquer:** `make-cubes`, `subsplit-cubes`, `clause-split-cubes`, `cube-solve` with checkpoint ledgers, per-cube timeouts, resume-after-anything. Retired from the staircase fight with honor; permanent equipment for n=10.
- **Distribution:** the borrowed 64-core colo box ran the final 39-survivor campaign one-shape-per-worker; results flowed home through git with verify-gated merges — the PLAN_N_10 trust model exercised for real.
- **Gallery:** meshes for every shape (models, tilings, refutation coronas) plus witness meshes for the whole open club; ~145k files, committed.

## What remains

Near: the triskelion's per-cube DRAT campaign (turning tonight's ledger-backed theorem into a proof-backed one); the staircase's corona-3, still under siege by three long-running solvers (standing policy: they run until they speak); the stage-provenance half of the schema migration; the face-only adjacency sensitivity check; S3 for the oversized artifacts; the paper. (The rest of the schema migration — adjacency conventions, proof checksums, budgets-vs-reached — shipped 2026-08-14.)
Far: the unfoldings track (the field moved in March 2026 — see whitepapers survey), n=10 with Rust + distribution, Lean-checked proofs.

## One-sentence version

In twelve days this went from "folklore says everything tiles" to a complete, independently verifiable map of all 56,463 polycubes through nine cells — every one carrying a verdict — containing six impossibility theorems, the first Heesch table in three dimensions, and one magnificent unanswered question.
