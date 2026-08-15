-- polycubing@home coordinator schema.
--
-- Two ideas carry the whole design:
--   1. A unit is a question with a self-certifying answer. Positive answers
--      (a tiling, a corona) carry witnesses the coordinator re-verifies with
--      plain geometry; negative answers carry proofs or exhausted budgets.
--      Nothing is ever decided by trusting a worker.
--   2. Units nest. A shape too hard for one worker becomes cubes; a cube too
--      hard becomes sub-cubes (parent_id). The same protocol serves both.

CREATE TABLE IF NOT EXISTS workers (
  id           BIGSERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  contact      TEXT,
  first_seen   TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen    TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted     INTEGER NOT NULL DEFAULT 0,
  rejected     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS units (
  id           BIGSERIAL PRIMARY KEY,
  kind         TEXT NOT NULL CHECK (kind IN ('shape', 'cube')),
  shape_id     TEXT NOT NULL,
  parent_id    BIGINT REFERENCES units (id),
  payload      JSONB NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'leased', 'done', 'exhausted', 'split')),
  lease_worker BIGINT REFERENCES workers (id),
  lease_until  TIMESTAMPTZ,
  attempts     INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (kind, shape_id, parent_id, payload)
);

CREATE INDEX IF NOT EXISTS units_leasable ON units (status, lease_until);
CREATE INDEX IF NOT EXISTS units_shape ON units (shape_id);

CREATE TABLE IF NOT EXISTS results (
  id           BIGSERIAL PRIMARY KEY,
  unit_id      BIGINT NOT NULL REFERENCES units (id),
  worker_id    BIGINT NOT NULL REFERENCES workers (id),
  verdict      TEXT NOT NULL
                 CHECK (verdict IN ('tiler', 'exhausted', 'unsat', 'sat', 'error')),
  payload      JSONB NOT NULL DEFAULT '{}'::jsonb,
  seconds      NUMERIC,
  verified     BOOLEAN,
  verifier_note TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS results_unit ON results (unit_id);
