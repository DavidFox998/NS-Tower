# Morning Star Project · Theorema Aureum 143 (Volume I)

Publisher: **Morning Star Project (independent research)**
License: **All rights reserved (license pending review)**

Volume I: **Theorema Aureum 143 — Certificate Ledger**, plus the
MorningStar-Lab CLI surface for probing L-functions against a
Genesis-sealed append-only ledger.

For the version history and full design notes of v1.0 → v1.9 Stage 2A-Prime
(seven-layer surface, Three Guns CLI, sign-change sieve, etc.) see
`docs/CHANGELOG.md`. For a 3-command reproducibility recipe see
`docs/REPRODUCE.md`. For the full architecture write-up see
`docs/MorningStar_Architecture.pdf`.

## Single source of truth — before you edit anything

`scripts/print-direction.sh` and `data/THEOREMA_AUREUM_143.manifest.txt`
are the canonical "who/what/where" surface. They print the project
name, publisher, license, sealed-ledger path, Genesis seal, and
public-alias symlink. If anything in this README ever drifts from
those, the script and the manifest win — fix this file, not them.

**Rule: additive only — never edit sealed files.** That means
`data/hits.txt` (preamble lines 1–9 are Genesis-sealed),
`data/THEOREMA_AUREUM_143.manifest.txt`, `scripts/print-direction.sh`,
and the Lean spine in `lean-proof/` are not surfaces for casual edits.
Append new probes through `kernel.probe()` / the Three-Guns CLI; do
not hand-edit the ledger.

## Volume I — what this repo actually ships

**Theorema Aureum 143: A Formal Spine and Computational Ledger for RH.**

Three real, defensible deliverables:

1. **The Ledger** — `data/hits.txt`, a 20,964-line append-only DAG of
   L-function probes with a Genesis-sealed preamble (SHA
   `eecbcd9a…875f`). Tamper-evident, reproducible from a fresh
   checkout (`docs/REPRODUCE.md`). Publishable computational data.
2. **The Spine** — Lean 4 deductive chain
   `H1_ArakelovPositivity → H2_WeilTransfer → main_theorem` in
   `lean-proof/`, with `#print axioms TheoremaAureum.main_theorem`
   returning `[]`. That is a real formal theorem: *given* the
   Prop-level stubs declared in `Certificates.lean`, the spine closes
   without new axioms. It is **not** a formal proof of RH itself.
3. **The Infrastructure** — append-only ledger discipline, per-line
   SHA chain, Genesis-seal verifier, drift guard (`post-merge.sh` +
   `lean-proof` CI), and a single-source-of-truth banner
   (`scripts/print-direction.sh`). Real software, real reproducibility.

For the longer-term research direction — RH, Yang-Mills, Navier-Stokes,
the 280-curve cohort, Bost-Connes — see `docs/ROADMAP.md`. Those are
**Open**; this repo does not claim to have proved them.

## Run & operate

- `pnpm --filter @workspace/api-server run dev` — API server
- `pnpm run typecheck` — full typecheck
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regen API hooks + Zod from OpenAPI
- `pnpm --filter @workspace/db run push` — push DB schema (dev only)
- `python lab.py` — open the MorningStar-Lab REPL
- `python lab.py -c "zeta_sniper(1)"` — one-shot probe
- `bash scripts/validate-morningstar.sh` — full kernel→bridge→lake harness
- `bash scripts/print-direction.sh` — print the canonical "you are here" banner

## Environment

- Required: `DATABASE_URL` (Postgres)
- Required (auto-set by Replit): `DEFAULT_OBJECT_STORAGE_BUCKET_ID`, `PUBLIC_OBJECT_SEARCH_PATHS`, `PRIVATE_OBJECT_DIR`
- Optional: `LEAN_REBUILD_TOKEN` — shared rebuild token. Unset ⇒ rebuild endpoint returns 503. Callers send `Authorization: Bearer <token>`. Only one rebuild at a time (others 409). Referees may opt-in attribution via `X-Referee-Name` (`[A-Za-z0-9 _.-]{1,64}`).
- Optional: `LEAN_REBUILD_TOKENS` — comma-separated named tokens (`alice:tokA,bob:tokB`) for real per-referee attribution. Named tokens take precedence over the shared one; a matched named token wins over any `X-Referee-Name` header. At least one of the two must be set to enable rebuilds.
- Optional: `MORNINGSTAR_ALERT_WEBHOOK_URL` — POST-JSON sink fired by `kernel._fire_ledger_alert` when `_verify_checkpoint` raises mid-workflow (truncation or in-place rewrite) and by `scripts/check-ledger-integrity.py` on a hard FATAL. Best-effort; delivery failure logs to stderr but never masks the underlying `LedgerIntegrityError`. Unset means no alert (silent no-op). Task #63.
- Optional: `MORNINGSTAR_ALERT_EMAIL_TO` + `MORNINGSTAR_ALERT_SMTP_HOST` (+ optional `MORNINGSTAR_ALERT_SMTP_PORT` default 25, `MORNINGSTAR_ALERT_EMAIL_FROM`, `MORNINGSTAR_ALERT_SMTP_USER`, `MORNINGSTAR_ALERT_SMTP_PASSWORD`) — plaintext SMTP sink for the same alert. Set alongside or instead of the webhook.
- Optional: `MORNINGSTAR_ALERT_TIMEOUT_SECONDS` — per-transport delivery timeout in seconds for the webhook and SMTP alert paths (default 5). Bad / non-positive values fall back to the default. Task #82.
- Optional: `LEDGER_CHECKPOINT_STALE_THRESHOLD_SECONDS` — age in seconds beyond which `data/hits.txt.checkpoint` (the committed known-good prefix) is flagged as stale on `/api/ledger/integrity` (`checkpointStale: true`). Default `2592000` (30 days). Distinct from `LEDGER_STALE_THRESHOLD_SECONDS` (which flags the verifier loop, not the sidecar). The dashboard surfaces the two warnings separately so operators don't confuse "nobody has verified the ledger lately" with "the sealed prefix is far behind the live file and tamper coverage is shrinking". Task #96.
- Optional: `MORNINGSTAR_WORKFLOW_NAME` — friendly tag (`zeta-burst-101-10000`, `zeta-sieve-14159-100000`, …) included in the alert payload so the operator can tell which long-running probe halted. Falls back to `argv[0]` / hostname.

### Brute-force lockout

Per-IP limiter on `/api/lean/verify/rebuild`: 5 bad-token attempts / 15
min ⇒ 15 min lockout (`failuresByIp` in
`artifacts/api-server/src/routes/lean.ts`). Same limiter applies to
`/api/lean/lockouts` and `/api/lean/lockouts/clear` — admin endpoints
don't bypass it.

Dashboard surface: the **Lean 4 Verification** card has a "Brute-force
lockouts" panel (`panel-lean-lockouts`) once a referee token is set,
polling `/api/lean/lockouts` every 15s. Active lockouts shown in red,
pre-lockout failing IPs in amber, each with a Clear button.
In-memory only — resets on server restart, no email/webhook out of
the box.

## Stack

- pnpm workspaces, Node 24, TypeScript 5.9
- API: Express 5, PostgreSQL + Drizzle ORM, Zod (`zod/v4`), Orval codegen
- Frontend: React + Vite, Tailwind, shadcn/ui, wouter, TanStack Query
- File storage: Replit Object Storage (presigned PUT)
- Kernel: Python 3, mpmath (arbitrary precision), Lean 4 (`leanprover/lean4:v4.12.0`) + mathlib v4.12.0

## Where things live

- `scripts/print-direction.sh` — single source of truth for project name, publisher, license, paths
- `data/THEOREMA_AUREUM_143.manifest.txt` — public manifest (unsealed, regeneratable) that mirrors the above
- `data/hits.txt` — **canonical** Genesis-sealed append-only probe ledger (preamble lines 1–9 sealed against SHA `eecbcd9a…875f`)
- `data/theorema-aureum-143-hits.txt` — public symlink alias for `data/hits.txt` (byte-identical; do not treat as a separate file)
- `data/CASUALTY_LOG.md`, `data/M13_CERT.txt` — incident log + M13 certificate header
- `lib/api-spec/openapi.yaml` — API contract (source of truth)
- `lib/db/src/schema/certificates.ts` — Drizzle schema
- `artifacts/api-server/src/routes/{certificates,storage,lean}.ts` — routes
- `artifacts/theorema-certs/src/` — React frontend (dashboard, certificate list/detail, walkthrough, Miegakure 600-cell viewer)
- `kernel.py`, `lab.py`, `lean_bridge.py` — MorningStar-Lab CLI surface
- `lean-proof/` — Lean 4 project (axiom debt = [], drift-guarded)
- `scripts/check-genesis-seal.py`, `scripts/check-lean-proof.sh`, `scripts/validate-morningstar.sh`, `scripts/post-merge.sh`
- `tests/test_kernel.py`, `tests/test_morningstar.py`
- `docs/MorningStar_Architecture.{tex,pdf}`, `docs/SiteMap.md`, `docs/ProofIndex.md`, `docs/CHANGELOG.md`, `docs/REPRODUCE.md`, `docs/ROADMAP.md`

## Architecture (one-liners)

- Certificates in PostgreSQL; SHA hashes, parent SHAs (JSON string), Lean theorem names are first-class columns.
- PDF upload = presigned-URL PUT to GCS, then PATCH `pdfObjectPath`.
- Master manifest SHA (M7) is hardcoded in the summary endpoint.
- Ledger preamble (lines 1–9 of `data/hits.txt`) is sealed; SHA-256 must match `eecbcd9a…875f` before any append.
- Lean `main_theorem` axiom debt = [] is re-verified on every merge by `scripts/post-merge.sh` and in CI by the `lean-proof` workflow (`STRICT_LEAN_CHECK=1`).

## Tests / validations

- `kernel-numerics` workflow — `pytest tests/test_kernel.py` (mpmath backend numerics + Three-Guns invariants + sieve dry-run)
- `morningstar-tamper` workflow — `pytest tests/test_morningstar.py` (Genesis-seal tamper-evidence; also invoked from `post-merge.sh`)
- `lean-proof` workflow — strict-mode `check-lean-proof.sh`; fails closed if `lake` missing

## Honest-scope guards

- `hit_437` / `hit_1094` are tautologies (`True := trivial`). Their *names* reference the OpenCV cube counts; their *statements* claim nothing about number theory.
- `probe()` and friends never call SageMath. Out-of-scope inputs are recorded with `NEEDS_SAGE` and a `reason=` field, never silently stubbed.
- `elliptic_stub` writes a SHA-stamped intent line tagged `ELLIPTIC_STUB`; the returned dict has no `L_*` keys. `test_kernel.py` pins this.
- `zeta_sieve` is a parallelised sign-change sieve, **not** the Odlyzko-Schönhage 1991 FFT. The docstring says so.
### YM / NS Lean schema — Path B Tower Bricks (current state)

All bricks below pass `scripts/check-towers.sh` with axiom footprint
= `{propext, Classical.choice, Quot.sound}` (mathlib's classical
trio — no research-grade axioms). All schemas are honest stand-ins
for the Clay surfaces; **YM and NS towers stay `Status: Open` in
`docs/ROADMAP.md`**. The schemas are NOT the YM action / Wilson
plaquette / `F_μν` / mass-gap, NOT the Sobolev H¹ norm / Leray–Hopf
solution. For per-batch prose and tactic notes see
`docs/CHANGELOG.md`.

| Date | Task | Wall | Headline |
|---|---|---|---|
| 2026-05-26 | #51 / #55 / #56 (Path B 1–6) | 19 → 81 | YM / NS schemas, Gell-Mann basis, gauge-field stand-in, placeholder `f^{abc}` → `f^{012}=1` + cyclic forward-diff (see `docs/CHANGELOG.md` for per-batch prose) |
| 2026-05-26 | #56 / Path B 7 (3 tracks) | 81 → 96 | A: `Towers/YM/Geometry.lean` (antisymmetrized `f^{abc}` wrapper + `Lattice4D`); B: `Towers/NS/Energy.lean` (kinetic/potential split + flow combinators); C: `Towers/Spectral/Operator.lean` (generic `MassGap` predicate, independent of YM/MassGap) |

**Hardening notes:**

- `scripts/check-towers.sh` uses an olean-existence probe (not
  `find | head | wc`) to decide on `lake exe cache get`; the
  pipefail-SIGPIPE bug that silently passed zero bricks is fixed.
- Task #50 (2026-05-26) retired the six `gauge_action_*` lemmas in
  `Towers/YM/Gauge.lean` — the action was `· • A := A`, so every
  lemma was definitionally trivial on both sides. Rule going forward:
  no `gauge_action_*` on `TrivialConfiguration` — only real SU(3).

**Tripwires:** `RealCurvature.curvature_eq_zero` routes through
`lie_bracket_eq_zero` which is the placeholder `f^{abc}=0`; replacing
the constants with real Gell-Mann values will *intentionally* break
this brick, signalling that a real curvature has landed.

## User preferences

- One PDF per module (M1–M7), uploaded one at a time
- SHA-256 hashes in monospace, truncated with copy-on-click
- Audit corrections documented in the per-module notes field
- Public-facing surface stays in the applied-science frame; scripture / personal-meaning notes are not in the repo
- Publisher line and license line are **locked** to the `scripts/print-direction.sh` wording — "Morning Star Project (independent research)" and "All rights reserved (license pending review)". Do not substitute "Entangled Technologies LLC" or "CC0" (or any other license) anywhere in the repo or UI.
- **Honest-scope wording is locked.** Do not describe any of the five roadmap towers (RH, Yang-Mills, Navier-Stokes, 280-curve cohort, Bost-Connes) as "proved" / "certified" / "discharged" in this repo *unless* the Lean spine actually closes that named theorem with axioms = []. Computational evidence, geometric invariants, and conjectural scaffolding are NOT proofs. Tower status lives in `docs/ROADMAP.md`; do not promote a tower out of `Status: Open` from `replit.md` or any UI surface.

## Gotchas

- After any OpenAPI change, run `pnpm --filter @workspace/api-spec run codegen` before touching frontend.
- `parentShas` is stored as text — JSON-parse on read.
- Restart the `theorema-certs` workflow after `status-badge.tsx` changes (Vite HMR caches the type).
- `_append_line` takes an exclusive `fcntl.flock` on the sidecar `data/.hits.lock` (created on first use, stable inode) **and** a second flock on its own append handle. The sidecar lock is the canonical cross-tool serialization primitive — exposed as `kernel.hits_exclusive_lock()` — and is used by `_append_line` AND by external backup/restore helpers (the `morningstar-tamper` snapshot fixture in `tests/test_morningstar.py` wraps its snapshot → mutate → restore window in this lock, task #59). A sidecar is used rather than `flock(data/hits.txt)` directly because tamper helpers `os.replace` the ledger for atomicity against concurrent readers; a lock taken on HITS itself would be orphaned by the inode swap, and a sibling `_append_line` would slip a line in during the mutate→restore window and have it silently overwritten. The sidecar lock is thread-reentrant within the same process (built on `threading.RLock`), so a fixture that holds the lock and then calls `kernel.probe()` — which itself calls `_append_line()` — does not self-deadlock; cross-thread and cross-process callers still serialize as normal.
- `replit.md` is operational only. History lives in `docs/CHANGELOG.md`. Don't grow this file with version notes.

## Pointers

- `pnpm-workspace` skill — workspace structure, TS setup
- `.local/skills/object-storage/SKILL.md` — presigned-URL upload architecture
- `docs/MorningStar_Architecture.pdf` — the full write-up (Part I Math Kernel, Part II Engineering Manifest, Appendices A–D)
