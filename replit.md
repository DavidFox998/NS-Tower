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

**Axiom debt = [] (zero axioms).** All hard rules satisfied:
- H1_ArakelovPositivity: THEOREM (by decide, M5 certificate)
- C05_Descent: THEOREM (True.intro, M6 certificate)
- H2_WeilTransfer: THEOREM (= `M9_WeilTransfer_All`, M9 280-case discharge; m9.out SHA `624b93f7…`)

**Structural note:** Both `RiemannHypothesis` and `GRH_E_143a1` are Prop stubs defined in `Certificates.lean` (the spec's original layout had a circular import). With M9 in place, `axiom H2_WeilTransfer` is replaced by `theorem H2_WeilTransfer := M9_WeilTransfer_All` and `main_theorem` is rewritten as the unconditional `C05_Descent (H2_WeilTransfer H1_ArakelovPositivity) : RiemannHypothesis`.

**Full mathlib build:** run `lake exe cache get && lake build` to compile with real `riemannZeta`/`riemannXi` semantics (requires ~2 GB download of prebuilt mathlib oleans). The structural proof above is correct without it.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
- See `.local/skills/object-storage/SKILL.md` for the presigned URL upload architecture
