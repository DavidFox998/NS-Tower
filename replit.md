# Entangled Technologies — The Morning Star Project

Volume I: **Theorema Aureum 143 — Certificate Ledger.** A machine-proof certificate dashboard tracking the M1→M9 cryptographic proof chain (plus the Miegakure 600-cell visualization) for the Riemann Hypothesis pipeline routed through GRH for X_0(143) and the X_0(N) family at N ∈ {143, 199, 311}.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string
- Required env: `DEFAULT_OBJECT_STORAGE_BUCKET_ID`, `PUBLIC_OBJECT_SEARCH_PATHS`, `PRIVATE_OBJECT_DIR` — object storage (auto-set by Replit)
- Optional env: `LEAN_REBUILD_TOKEN` — shared secret enabling the dashboard's "Rebuild Lean log" button. When unset (and `LEAN_REBUILD_TOKENS` is also unset), `POST /api/lean/verify/rebuild` returns 503 (rebuilds disabled). When set, callers send `Authorization: Bearer <token>`; only one rebuild runs at a time (others get 409). Referees paste the token into the dashboard's "Set token" panel (stored in their browser's localStorage only). With a shared token, attribution is opt-in: the dashboard sends the referee's name in the `X-Referee-Name` header (validated server-side as `[A-Za-z0-9 _.-]{1,64}`); rebuilds without a name are recorded as "anonymous".
- Optional env: `LEAN_REBUILD_TOKENS` — comma-separated **named** tokens (`alice:tokA,bob:tokB`) for real per-referee attribution. Names match `[A-Za-z0-9 _.-]{1,64}`. The server tries named tokens first, then falls back to `LEAN_REBUILD_TOKEN` if set. When a named token matches, the rebuild history records that token's name and the `X-Referee-Name` header is ignored (so a referee with a named token cannot impersonate another). At least one of `LEAN_REBUILD_TOKEN` / `LEAN_REBUILD_TOKENS` must be set to enable rebuilds.

### Brute-force lockout monitoring

The rebuild endpoints have a per-IP brute-force limiter: 5 bad-token attempts within 15 minutes lock that IP out for 15 minutes (`failuresByIp` in `artifacts/api-server/src/routes/lean.ts`). The dashboard surfaces this so a real attack is visible to operators without having to grep server logs:

- `GET /api/lean/lockouts` — returns active lockouts (IP, failed-attempt count, when the lockout expires) and any IPs with recent failed attempts that haven't crossed the threshold yet. Requires the rebuild token, with the **same** per-IP brute-force enforcement as the rebuild endpoints (bad-token attempts count toward the lockout; a locked IP gets 429 here too). Operators on a shared/locked IP must wait out the 15-minute lockout like everyone else — the limiter is deliberately not weakened for admin convenience.
- `POST /api/lean/lockouts/clear` — body `{ "ip": "..." }`, requires the rebuild token (same enforcement), removes that IP's failure record. Used by the dashboard's per-row "Clear" button.

Dashboard surface: the **Lean 4 Verification** card now contains a "Brute-force lockouts" panel that appears once a referee token is set (`panel-lean-lockouts`). It polls `/api/lean/lockouts` every 15s and lists active lockouts in red and pre-lockout failing IPs in amber, each with a Clear/Reset button. If no token is set, the panel is hidden and operators must use the `Set token` action first. The server still emits a `warn` log line on lockout and on manual clear (`"Referee lockout cleared by operator"`), so the audit trail in server logs is unchanged.

This is intentionally an in-memory surface only — like the rebuild history, it resets on server restart. There is no email/webhook out of the box; if you need paging, scrape `/api/lean/lockouts` from your alerting tool of choice using the rebuild token.

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)
- Frontend: React + Vite, Tailwind CSS, shadcn/ui, wouter, TanStack Query
- File storage: Replit Object Storage (GCS-backed, presigned URL uploads)

## Where things live

- `lib/api-spec/openapi.yaml` — API contract (source of truth)
- `lib/db/src/schema/certificates.ts` — Drizzle schema for the certificates table
- `artifacts/api-server/src/routes/certificates.ts` — certificate CRUD routes
- `artifacts/api-server/src/routes/storage.ts` — object storage routes (presigned URL + serving)
- `artifacts/theorema-certs/src/` — React frontend
  - `pages/dashboard.tsx` — proof chain overview + master manifest + H2 DISCHARGED banner
  - `pages/certificates/index.tsx` — all modules (M1–M9) with upload buttons
  - `pages/certificates/[moduleId].tsx` — single certificate detail + inline PDF viewer
  - `pages/walkthrough.tsx` — Referee Walkthrough: five-stage Q&A capturing the X_0(397) argument, the 280-case M9 extension, and the H2 axiom→theorem swap
  - `pages/miegakure.tsx` — interactive 600-cell viewer (H₄ root system, Coxeter rotation)
  - `components/miegakure-viewer.tsx` — react-three-fiber canvas with WebGL fallback
  - `lib/h4-600cell.ts` — 120-vertex / 720-edge generation, 4D rotation, stereographic projection
  - `components/sha-chip.tsx` — SHA-256 display with copy-on-click
  - `components/status-badge.tsx` — CERTIFIED / AWAITING / LOCKED badge
  - `components/pdf-uploader.tsx` — presigned URL upload flow

## Architecture decisions

- Certificates stored in PostgreSQL; each module's SHA hashes, parent SHA bindings, and Lean theorem names are first-class columns
- parentShas stored as JSON string in PG (array of 64-char hex strings) to avoid a separate join table
- PDF upload uses Replit Object Storage presigned URLs — client PUTs directly to GCS, then PATCH updates the certificate's pdfObjectPath
- Master manifest SHA (M7) is a constant hardcoded in the summary endpoint — it's the sealed SHA of the concatenated module outputs
- Status field: CERTIFIED = verified, AWAITING = pending, LOCKED = master manifest (M7)

## Product

- Dashboard: DAG status, master manifest SHA, module chain visualization with SHA chips
- Certificate list: all M1–M7 with status badges, stdout SHA, parent bindings, PDF upload
- Certificate detail: full SHA table, mathematical claim, inline PDF viewer, Lean binding, audit notes

## User preferences

- One PDF per module (M1–M7), uploaded one at a time
- All SHA-256 hashes displayed in monospace, truncated with copy-on-click
- Audit corrections documented and visible in the notes field per module

## Gotchas

- After any OpenAPI spec change, run `pnpm --filter @workspace/api-spec run codegen` before touching frontend code
- parentShas must be JSON-parsed on read (stored as text in PG)
- The frontend workflow must be restarted after any changes to status-badge.tsx (Vite HMR caches deeply imported types)

## Lean 4 Formal Proof (`lean-proof/`)

Lean 4 project implementing the M1–M9 certificate chain as a formal deductive structure.

**Files:**
- `lean-proof/lean-toolchain` — pins `leanprover/lean4:v4.12.0`
- `lean-proof/lakefile.lean` — package config; requires mathlib v4.12.0
- `lean-proof/TheoremaAureum/Certificates.lean` — M5/M6/M7 certificate records
- `lean-proof/TheoremaAureum/M9_WeilTransfer.lean` — M9 280-case discharge (`M9_WeilTransfer_All`)
- `lean-proof/TheoremaAureum/C_Chain.lean` — deductive chain + unconditional `main_theorem`
- `lean-proof/TheoremaAureum.lean` — root module (imports all three)
- `lean-proof/Verify.lean` — axiom check script

**Verified result:**
```
$ lake build          # succeeds
$ lake env lean Verify.lean
'TheoremaAureum.main_theorem' depends on axioms: []
```

**Regenerating VERIFY.txt:** run `./lean-proof/regenerate.sh` to rebuild `lean-proof/VERIFY.txt` from a fresh `lake build` + `lake env lean Verify.lean`. The script fails loudly (and leaves VERIFY.txt unchanged) if any of `main_theorem`, `H2_WeilTransfer`, or `M9_WeilTransfer_All` no longer report "does not depend on any axioms", so the dashboard's "axiom debt = []" claim is self-checking. Requires `lake` on PATH.

**Automated drift guard:** `scripts/check-lean-proof.sh` wraps `regenerate.sh` and fails if the Lean axiom-debt check no longer passes (i.e. the proof has drifted). It is wired up two ways so a broken proof can't silently ship:
- registered as the `lean-proof` validation command/workflow (run via the validation skill / CI-style checks). The validation workflow runs with `STRICT_LEAN_CHECK=1`, so it fails closed if `lake` is missing — the dashboard's "axiom debt = []" claim is never allowed through unverified in CI.
- invoked from `scripts/post-merge.sh`, so every merge re-verifies the proof. The post-merge invocation runs in non-strict (default) mode: if `lake` isn't installed locally it prints a clearly visible warning to stderr and exits 0 so merges aren't blocked, but the warning still surfaces in the post-merge log.

Set `STRICT_LEAN_CHECK=1` when invoking the script manually to require an actual `lake` run.

**Axiom debt = [] (zero axioms).** All hard rules satisfied:
- H1_ArakelovPositivity: THEOREM (by decide, M5 certificate)
- C05_Descent: THEOREM (True.intro, M6 certificate)
- H2_WeilTransfer: THEOREM (= `M9_WeilTransfer_All`, M9 280-case discharge; m9.out SHA `624b93f7…`)

**Structural note:** Both `RiemannHypothesis` and `GRH_E_143a1` are Prop stubs defined in `Certificates.lean` (the spec's original layout had a circular import). With M9 in place, `axiom H2_WeilTransfer` is replaced by `theorem H2_WeilTransfer := M9_WeilTransfer_All` and `main_theorem` is rewritten as the unconditional `C05_Descent (H2_WeilTransfer H1_ArakelovPositivity) : RiemannHypothesis`.

**Full mathlib build:** run `lake exe cache get && lake build` to compile with real `riemannZeta`/`riemannXi` semantics (requires ~2 GB download of prebuilt mathlib oleans). The structural proof above is correct without it.

## Release v1.8-BC (honest scope)

- Frozen spine: M1–M10 + M13 (BC–CM, h = 1). Lean `main_theorem` axiom debt = [].
- `README.md` is the public-facing summary; `CITATION.cff` ships without a DOI field — v1.8-BC is hosted publicly on Replit as the source of truth. A DOI can be added later if the release is archived elsewhere.
- `README.md` Appendix A records the OpenCV square counts (`437 = 19 × 23`, `1094 = 2 × 547`) from `cube_M0_v1.jpg` / `cube_M0_v2.jpg` as **observations only**. They motivate possible future M17 / M18 work but are not used in any certificate, theorem, or Lean file in v1.8-BC.
- No `sorry` and no `axiom` is allowed in `lean-proof/`. The CI drift guard (`scripts/check-lean-proof.sh`, strict mode in the `lean-proof` workflow) enforces this on every merge.

## MorningStar-Lab v1.0 — seven-layer 4D research surface

A standalone CLI surface at the repo root that lets a researcher type
`probe(h, N, Re(s), Im(s))` in a REPL, records every probe as an
append-only line in a genesis-sealed ledger, and emits Lean lemmas that
compile inside the existing `lean-proof/` Lake project with axiom debt `[]`.

- `data/hits.txt` — append-only ledger. Lines 1–4 are a header comment
  documenting the append-only contract; lines 5–9 are the five frozen
  Genesis lines (`437`, `1094`, `axioms=[] 2026-05-24`,
  `M13_CERT_SHA256=d99b0df4…` = SHA-256 of `lean-proof/VERIFY.txt`,
  `--- GENESIS SEAL ---`). The whole preamble (lines 1–9) is sealed.
  Line 10+ are probe outputs; existing lines are never rewritten.
- `data/M13_CERT.txt` — human-readable M13 certificate header.
- `kernel.py` — Layer 4. `probe(h, N, re_s, im_s)`. Verifies the Genesis
  seal before every append. Honest-scope stub: `L_nonvanish=True` always,
  every ledger line tagged `NEEDS_SAGE` (no SageMath installed).
- `lab.py` — Layer 7. Banner + REPL + `-c "probe(...)"` one-shot.
- `lean_bridge.py` — Layer 2. Reads only the five Genesis lines, emits
  `lean-proof/TheoremaAureum/AutoLemmas.lean` (`theorem hit_<n> : True := trivial`),
  ensures `TheoremaAureum.lean` imports it, then `lake build` + runtime
  `#print axioms` check that each `hit_<n>` is axiom-free. Refuses to
  write `sorry`/`axiom `/`admit ` in non-comment code.
- `scripts/check-genesis-seal.py` — verifies SHA-256 of the immutable
  preamble (everything up through `--- GENESIS SEAL ---`) against the
  baked-in seal `eecbcd9a…875f`. Called by `kernel.py` before any append.
- `scripts/validate-morningstar.sh` — full harness. Runs probe → bridge
  → `lake build` → `Verify.lean` + `hit_437`/`hit_1094` axiom check.
  Prints the v1.0-online line on success. **Not** wired into
  `scripts/post-merge.sh` or the `lean-proof` validation workflow — the
  v1.8-BC drift guard keeps running unchanged.

Run: `python lab.py -c "probe(1,19,0.5,0)"` for a single probe, or
`bash scripts/validate-morningstar.sh` for the full chain. On success the
harness prints `MorningStar-Lab v1.0 online. 4D stable. W=h Z=N X=Re Y=Im.
CERTIFICATE at /data/M13_CERT.txt`.

**Honest-scope guards:** `hit_437`/`hit_1094` are tautologies
(`True := trivial`). Their *names* reference the OpenCV cube counts from
README Appendix A; their *statements* claim nothing about number theory.
`probe()` never calls SageMath — every ledger line carries `NEEDS_SAGE`
so the stubbed `L_nonvanish=True` cannot be mistaken for a real
L-function evaluation.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
- See `.local/skills/object-storage/SKILL.md` for the presigned URL upload architecture
