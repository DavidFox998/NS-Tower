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
- Optional: `MORNINGSTAR_ALERT_WEBHOOK_URL` — POST-JSON sink fired by `kernel._fire_ledger_alert` when `_verify_checkpoint` raises mid-workflow (truncation or in-place rewrite) and by `scripts/check-ledger-integrity.py` on a hard FATAL. Best-effort; delivery failure logs to stderr but never masks the underlying `LedgerIntegrityError`. Unset means no alert (silent no-op). Task #63. Task #144: the api-server's watchdog (`checkWatchdog`, task #113) also rides this same sink when the auto-integrity check stalls (`failure_mode: "monitor_stalled"`) and again when ticks resume (`failure_mode: "recovered"`, `previous_failure_mode: "monitor_stalled"`). The webhook JSON now carries an explicit `subject` field — `"[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: <workflow>"` for a stall, `"[MorningStar] Ledger monitor RECOVERED: <workflow>"` for the all-clear, and `"[MorningStar] Ledger integrity alert: <workflow>"` for the legacy tamper case — so Slack / PagerDuty routing can split watchdog signals from real tamper alerts without re-deriving from `failure_mode`.
- Optional: `MORNINGSTAR_ALERT_EMAIL_TO` + `MORNINGSTAR_ALERT_SMTP_HOST` (+ optional `MORNINGSTAR_ALERT_SMTP_PORT` default 25, `MORNINGSTAR_ALERT_EMAIL_FROM`, `MORNINGSTAR_ALERT_SMTP_USER`, `MORNINGSTAR_ALERT_SMTP_PASSWORD`) — plaintext SMTP sink for the same alert. Set alongside or instead of the webhook. Task #144: the Subject header mirrors the webhook `subject` field — distinct lines for `monitor_stalled` / `monitor_recovered` / tamper — and the body for watchdog signals carries `stall_age_seconds` / `stall_threshold_seconds` / `monitor_interval_seconds` / `last_tick_at` instead of the tamper `expected_size` / `actual_size` / `expected_sha` columns, with a "do NOT restore hits.txt — investigate the api-server process" pointer in place of the tamper-recovery doc link.
- Optional: `MORNINGSTAR_ALERT_TIMEOUT_SECONDS` — per-transport delivery timeout in seconds for the webhook and SMTP alert paths (default 5). Bad / non-positive values fall back to the default. Task #82.
- Optional: `MORNINGSTAR_ALERTS_MAX_BYTES` — byte cap before `data/ledger-alerts.jsonl` is rotated to `ledger-alerts.jsonl.1` (with `.1 → .2`, etc.). Default `5242880` (5 MB). Bad / non-positive values fall back to the default. Task #105.
- Optional: `MORNINGSTAR_ALERTS_MAX_ROTATIONS` — how many rotated copies (`.1`, `.2`, …) to keep before the oldest is deleted. Default `3`. The dashboard endpoint `/api/lean/ledger-alerts` only reads the live file; rotated copies are archival.
- Optional: `LEDGER_SIDECAR_SECRET` — inline 64-char hex (32 bytes) HMAC secret for the `data/hits.txt.lastok` sidecar. When set, the secret is held in memory only and no keyfile is written to disk — the recommended deploy posture, since it removes the "attacker who can read the data dir can forge MACs" failure mode entirely. Malformed values are ignored with a warning and the server falls through to the on-disk keyfile.
- Optional: `LEDGER_SIDECAR_SECRET_PATH` — relocate the on-disk HMAC keyfile out of the data dir onto a tighter-ACL mount (e.g. a secrets volume). Defaults to `${lastOkPath}.key` (i.e. `data/hits.txt.lastok.key`). Ignored when `LEDGER_SIDECAR_SECRET` is set. On startup the server stats the keyfile; if it is group- or world-readable, a loud `WARN` is logged with the exact octal mode and remediation steps (`chmod 600`, relocate, or switch to env-only). Loose mode is a warning, not a hard fail — the server still boots. Task #109.
- Optional: `LEDGER_SIDECAR_SECRET_STRICT_MODE` — when truthy (`1`, `true`, `yes`, `on`, case-insensitive), promotes the Task #109 loose-keyfile WARN to a hard startup failure (`SidecarSecretLooseModeError`). The API server refuses to boot until the operator either `chmod 600`s the keyfile, relocates it via `LEDGER_SIDECAR_SECRET_PATH` to a tighter-ACL mount, or supplies `LEDGER_SIDECAR_SECRET` inline (env-only, no on-disk fallback). Defaults to off (lenient warn — backward compatible). Recommended for hardened production deploys where a loose-mode keyfile shipping into production would otherwise be lost in log noise. Task #123. The runtime posture is surfaced on the Ledger Integrity dashboard card as a small "Strict keyfile mode: ON / OFF" badge (`sidecarSecretStrictMode` on `GET /api/ledger/integrity`), sourced from the same env parser used at boot so the badge cannot drift from the actual posture. Task #137.
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
| 2026-05-27 | #154 / Batch 19.1p-redux-a (SU(3) Peter-Weyl Summability) | 452 → 456 | New file `Towers/YM/PeterWeyl.lean`: Casimir linear lower bound, Weyl-dim polynomial upper bound, 1D `(n+1)^4·exp(-βn)` summability, headline `PeterWeyl_Summable_SU3` for β > 0 via product-envelope squeeze (see `docs/CHANGELOG.md` for per-batch prose). YM tower stays `Status: Open`. |
| 2026-05-27 | Batch 20.1a / "Plan #156" (Surface #3 setup — define the continuum) | 460 → 464 | New files `Towers/YM/Continuum.lean` (4 trio-clean defs: `YM4_Continuum`, `IsMassGap`, `lattice_to_continuum`, `AsymptoticFreedom`) and `Towers/Attempts/Clay.lean` (parked `MassGap_YM4_Clay : ∀ T, AsymptoticFreedom T → ∃ Δ, IsMassGap T Δ` — the only new sorry, NOT a brick). Zero theorems landed. No Varadhan assumed (separate track, task #156). YM tower stays `Status: Open`. Dragons ahead: 20.1b limit existence, 20.1c OS axioms, 20.1d mass gap. |
| 2026-05-27 | Batch 20.2a / Task #156 file 1 of 6 (Varadhan scaffolding — Casimir quadratic lower bound) | 464 → 465 | New file `Towers/YM/Casimir.lean`: `Casimir_SU3_explicit_real_ge_quadratic` proves `¾·(m+n)² + 3·(m+n) ≤ C₂(m,n)` with explicit `k₀ = 0`, via `(m − n)² ≥ 0` after `unfold + push_cast; nlinarith`. **Strengthens** (does not replace) the linear bound `Casimir_SU3_explicit_real_ge_linear` from Batch 19.1p-redux-a. Target shape for Task #156 is **(C) integrated tail** `∫_{d(g,e)≥δ} K_t(g,e) dg ≤ C·t⁻⁴·e⁻ᶜᵟ²ᐟᵗ`, NOT the false trace shape `K(t) ≤ C·t⁻⁴·e⁻ᶜᐟᵗ`. Files 2–6 NOT shipped (file 4 needs bi-invariant Riemannian metric on SU(3), absent from mathlib v4.12.0). YM tower stays `Status: Open`; Surface #2 stays OPEN; `kotecky_preiss_criterion` still a `sorry`. |
| 2026-05-27 | Batch 156.2 / Task #156 file 2 of 6 (Varadhan scaffolding — Weyl-dim cubic upper bound) | 465 → 467 (+1 this batch + 1 previously-registered NS brick) | New file `Towers/YM/WeylDim.lean`: `dim_cubic_bound` proves `dim_SU3 m n ≤ 8·(m+n+1)³` with explicit `k₀ = 0`, where `dim_SU3 m n := (m+1)(n+1)(m+n+2)/2` (standard SU(3) Weyl-dim formula on the (m,n) highest-weight lattice, ℕ floor division). Proof: `zify; nlinarith [sq_nonneg ((m:ℤ)−n), …]` closes the polynomial `(m+1)(n+1)(m+n+2) ≤ 16·(m+n+1)³`, then `set R := (m+n+1)^3` and `omega` discharges `A/2 ≤ 8·R` from `A ≤ 16·R` via `Nat.div_le_div_right`. Pairs with file 1's quadratic Casimir lower bound; the future file 3 (`HeatTraceBound`) will combine the two for the Weyl-law `K(t) ≤ C·t⁻⁴` heat-trace shape (`d = dim_ℝ SU(3) = 8` ⇒ `t⁻ᵈᐟ²`). NOT a heat-kernel statement. NOT Varadhan. ℕ-polynomial only. Coexists with `Weyl_dim_SU3_explicit_real_le_poly` (degree-4 bound on (m,n) separately) in `PeterWeyl.lean` — different shape needed because Weyl-law summation is on the `m+n = k` antidiagonal. Files 3–6 NOT shipped. YM tower stays `Status: Open`; Surface #2 stays OPEN; `kotecky_preiss_criterion` still a `sorry`. mathlib v4.12.0 only; axiom footprint = classical trio. Wall-jump honesty: this batch's brick delta is +1 (`dim_cubic_bound`); the other +1 is `Towers.NS.HasFiniteEnergy_galilean_group` (Task #146 context, registered in BRICKS line 442 but first axiom-debt-checked in this build because the 21:46 UTC log was stale). See `docs/CHANGELOG.md` Batch 156.2 § "Script-count drift" for the full diff. |
| 2026-05-27 | #155 / Batch 19.1p-redux-b (Truncated Peter-Weyl ≤ heat-kernel envelope) | 456 → 460 | New file `Towers/YM/PeterWeylHeat.lean`: genuine envelope `Heat_kernel_envelope_real := ∑'_{(m,n) : ℕ²} (dim)² · exp(-(t · C₂))`, nonneg, finite truncation ≤ envelope for `t > 0` via mathlib `sum_le_tsum` + redux-a's `PeterWeyl_Summable_SU3`, `1 ≤ envelope` for `t > 0` (trivial-rep contribution), Attempts forwarder alias. Discharges parked sorry `Attempts/ClusterExpansion.lean:693` (sorry count 10 → 9) by retargeting the **false** original RHS `Heat_kernel_def_real` (Varadhan asymptotic placeholder — false at `N = 0, t = 1`: 1 vs ≈ 0.368) at the **true** envelope `tsum`. Varadhan small-`t` asymptotic remains a separate open gap. YM tower stays `Status: Open`. |

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
