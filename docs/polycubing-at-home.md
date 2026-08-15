# polycubing@home — distributed census computation

A spike, working end to end: a coordinator that hands out work and verifies everything that comes back, a client that needs no trust in either direction, and a Postgres-backed queue. Built so the n=10 campaign is a continuation of the n≤9 method rather than a re-architecture.

## The idea it rests on

Census claims are **self-certifying**. A tiling comes back as a lattice and a placement list, and the coordinator re-derives coverage with plain geometry before believing a word of it. So a worker can be a stranger, a bug, or a saboteur without endangering the result — the worst case is a wasted lease. That removes the machinery volunteer projects normally need (quorum, replication, reputation-as-truth) and replaces it with one verification step.

Demonstrated: a worker submitting a forged certificate is rejected (`certificate failed geometric verification`), its unit returns to the queue, and the rejection is recorded against it.

## The pieces

| piece | file | what it does |
| --- | --- | --- |
| queue + state | `db/home.sql`, `lib/census/home/store.rb` | workers, units (shape or cube, nestable via `parent_id`), results; leases with expiry so a vanished worker costs one lease |
| trust boundary | `lib/census/home/coordinator.rb` | leases units, verifies every submission, closes or requeues, credits the worker |
| HTTP API | `lib/census/home/server.rb` | four endpoints, JSON, no framework: `/register`, `/lease`, `/results`, `/status` |
| client | `lib/census/home/worker.rb` | leases, solves locally (box/torus for shapes, kissat for cubes), submits, repeats |
| durability | `lib/census/home/promoter.rb`, `script/home/promote` | moves verified results out of Postgres into plaintext `data/` files, commits, pushes |

Scripts: `home-setup` (create databases), `home-seed` (fill the queue from `data/`), `home-server`, `home-worker`, `home-audit` (compare accepted results against the census's own answers).

## Shakedown run

```sh
script/home/setup --reset
script/home/seed 5                 # 29 pentacubes
script/home/server &
script/home/worker --name alpha &
script/home/worker --name beta &
script/home/audit
```

Result: 29 units solved by two competing clients, every certificate verified on arrival, and the audit reporting `tiler_confirmed: 29, same_certificate_type: 29, no disagreements with data/` — the volunteers independently rediscovered exactly what the census already knew.

## Why the unit table nests

The tail of every census size is a handful of shapes no single worker can finish. `units.parent_id` exists so a shape that exhausts its budget can be split into cube units, and a cube that times out into sub-cubes — the same escalation the n=9 campaign performed by hand, expressed as data instead of judgement calls. The worker protocol is identical at every level.

## Two identities, on purpose

`workers.handle` is the scheduling key: opaque, permanent, never displayed — every lease and result hangs off it forever. `workers.display_name` is what may appear in `credits.solved_by`: mutable, and gated by `display_state` (`pending` → `approved`/`rejected`). Until a human approves a name, the credit string falls back to the handle.

The reason to build this on day one rather than retrofit it: volunteer credit is the retention mechanic (your name on a shape in a public dataset, permanently, WHUTS-style), but free-form names invite abuse, and the record is citable and lives in git forever. Splitting the two means a name can be moderated, changed, or scrubbed years later without touching a single result or invalidating the ledger.

    credit while pending:  "worker-laptop-1"
    credit once approved:  "Shane"

## LOCKSS: the database is not the archive

Postgres holds scheduling state — leases, queues, worker profiles. It is deliberately _disposable_: if it dies we lose in-flight leases and nothing else, because `script/home/promote` has been moving every verified result into plaintext files under `data/` all along, where git (and S3, for the big pieces) keep the copies that matter. The dependency runs one way: the database is reconstructible from the archive (`script/home/seed`), the archive is not reconstructible from the database.

The promoter is idempotent by comparison rather than bookkeeping — each run asks "what does the coordinator know that `data/` doesn't?" — so an interrupted run loses nothing and a repeated run writes nothing twice. It re-verifies every certificate before writing, the third independent check after the worker and the coordinator: a coordinator compromised _after_ accepting a result still cannot put a false claim into the archive (there is a spec for exactly that).

    script/home/promote                  # write files
    script/home/promote --commit --push  # write, commit, pull-rebase, push

Scheduling is deliberately external — cron, a systemd timer, Heroku Scheduler, or Sidekiq-cron if the coordinator ever becomes a Rails app. The script is the durable artifact; the trigger is a detail.

## Security posture

Generic web risks live at the HTTP edge: Sinatra on Puma (not WEBrick), `Rack::Attack` throttling, a 5 MB body cap, JSON shape validation, and pooled Postgres connections. Every query is parameterized; no worker-supplied value is ever interpolated into SQL. TLS and crude flood protection belong at a reverse proxy.

Domain risks are handled where the domain lives, because no framework knows what a plausible tiling certificate looks like: `SubmissionGuard` bounds placement counts and coordinate ranges _before_ the geometry verifier is allowed to spend CPU on a stranger's submission.

## Not built yet (deliberate spike boundaries)

- **Proof return.** Cube UNSAT results are accepted on report; the design is that a worker runs drat-trim locally and returns `(verdict, proof sha256, checker output)`, with the coordinator requesting full proofs for a random sample and for headline claims. That is what makes negative results as trustworthy as positive ones.
- **Automatic splitting.** The coordinator accepts `exhausted` but does not yet generate child cube units from it.
- **Writing back to `data/`.** Accepted certificates live in the results table; promoting them into shape records (and committing) is still a human-run step.
- **Browser client.** The WASM story from PLAN_N_10; the HTTP protocol is deliberately curl-simple so it can be spoken from anywhere.
- **Connection pooling.** One PG connection serialized behind a mutex — fine at a coordinator's request rates, an obvious upgrade at fleet scale.
