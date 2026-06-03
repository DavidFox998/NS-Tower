# MorningStar v1.9 — Site Map

Repository nodes relabeled by **paper / certificate title**, not file path.
Where a node ships as both a Lean theorem and a LaTeX module, both are named.

Genesis seal (immutable across all of the below):
`eecbcd9a540aa7a2c90edd23827c73e4d1bb5af641d352f70a5de849b21f875f`

Lean axiom debt for `main_theorem`, `H2_WeilTransfer`, `M9_WeilTransfer_All`: **`[]`**.

---

## I. The Theorema Aureum 143 paper (Volume I)

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `paper/theorema-aureum-143.{tex,pdf}`         | *Theorema Aureum 143 — A Machine-Verified Certificate Chain for the Riemann Hypothesis routed through GRH for X₀(143)* |
| `paper/modules/m01-alpha0def.tex`             | M1 — α₀ Definition Certificate                                     |
| `paper/modules/m02-kappabound.tex`            | M2 — κ Bound Certificate                                           |
| `paper/modules/m03-q5p5bound.tex`             | M3 — Q₅/P₅ Bound Certificate (`p₅ > 82,829`)                       |
| `paper/modules/m04-esete4.tex`                | M4 — eSeTe₄ Source/Binary/Stdout/Bound-Proof SHA Certificate       |
| `paper/modules/m05-bostbound.tex`             | M5 — Bost Sum Certificate (Arakelov positivity, VALOR = 42110)     |
| `paper/modules/m06-grhx0143.tex`              | M6 — GRH for X₀(143) Certificate (genus 13, `h(-143) = 10`)        |
| `paper/modules/m07-manifest.tex`              | M7 — Master Manifest (LOCKED, SHA `5b80b84d…`)                     |

## II. The Lean 4 formalization (`lean-proof/`)

| Node                                                       | Title                                                       |
| ---------------------------------------------------------- | ----------------------------------------------------------- |
| `lean-proof/TheoremaAureum/Certificates.lean`              | M5/M6/M7 Certificate Records (Lean)                          |
| `lean-proof/TheoremaAureum/M9_WeilTransfer.lean`           | M9 — Weil Transfer All — 280-Case Discharge (`M9_WeilTransfer_All`, m9.out SHA `624b93f7…`) |
| `lean-proof/TheoremaAureum/C_Chain.lean`                   | C-Chain — Unconditional `main_theorem : RiemannHypothesis`  |
| `lean-proof/TheoremaAureum/AutoLemmas.lean`                | MorningStar-Lab Auto-Lemmas (`hit_437`, `hit_1094`; honest-scope tautologies) |
| `lean-proof/TheoremaAureum.lean`                           | Root Module                                                 |
| `lean-proof/Verify.lean`                                   | Axiom-Debt `#print axioms` Script                           |
| `lean-proof/VERIFY.txt`                                    | Verification Log (axiom debt = `[]`, dated 2026-05-25)      |
| `lean-proof/regenerate.sh`                                 | VERIFY.txt Regenerator (fails closed on drift)              |
| `scripts/check-lean-proof.sh`                              | CI Drift Guard (strict mode in `lean-proof` workflow)       |

## III. The Bost–Connes / CM extension (Volume II spine, h = 1)

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `docs/M10_CM_Descent.{tex,pdf}`               | M10 — CM Descent: BSD for the Twelve Modular Curves                |
| `docs/M13_BC_CM.{tex,pdf}`                    | M13 — Bost–Connes for the Twelve Imaginary Quadratic Fields (h = 1) |
| `data/M13_CERT.txt`                           | M13 Certificate Header (`d99b0df4…`, sealed against `VERIFY.txt`)   |

## IV. The MorningStar-Lab research surface (Volume III, v1.9 Three Guns)

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `kernel.py`                                   | Layer 4 — Genesis-Sealed Probe Kernel (mpmath backend)             |
| `lab.py`                                      | Layer 7 — Three-Guns CLI / REPL                                    |
| `lean_bridge.py`                              | Layer 2 — Genesis-Integer → Lean Emitter (`AutoLemmas.lean`)        |
| `scripts/check-genesis-seal.py`               | Layer 1 — Genesis Seal Verifier (SHA-256 of preamble)              |
| `scripts/validate-morningstar.sh`             | Full-Chain Harness (probe → bridge → `lake build` → `#print axioms`) |
| `scripts/seal-birth.py`                       | Seal-Birth Helper (preamble untouched)                              |
| `data/hits.txt`                               | Genesis-Sealed Probe Ledger (20,962 lines, 11,410 unique im(t) values with 8,223 repeats; 11,735 RH_ok=True / 9,216 RH_ok=False) |
| `data/CASUALTY_LOG.md`                        | Phase 1 Casualty Log (4 incidents, seal verified throughout)        |
| `data/MorningStar_RH_Cert.{tex,pdf}`          | Reconnaissance Certificate (explicitly NOT a proof of RH)           |
| `tests/test_kernel.py`                        | Kernel-Numerics Test Suite (`MPMATH_ZETA`, `MPMATH_DIRICHLET_TRIVIAL`, `NEEDS_SAGE`, `ELLIPTIC_STUB`) |
| `tests/test_morningstar.py`                   | Genesis-Seal Tamper-Evidence Suite                                  |

## V. The Theorema Aureum dashboard (Volume I operator surface)

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `artifacts/theorema-certs/`                   | Theorema Aureum 143 — Certificate Ledger Dashboard (React/Vite)    |
| `artifacts/api-server/`                       | Certificate API (Express 5, Drizzle, OpenAPI)                       |
| `artifacts/api-server/src/routes/lean.ts`     | Lean Rebuild Endpoint + Per-IP Lockout Surface                      |
| `artifacts/theorema-certs/src/pages/dashboard.tsx`     | DAG Status + Master Manifest + H2 DISCHARGED banner       |
| `artifacts/theorema-certs/src/pages/walkthrough.tsx`   | Referee Walkthrough (X₀(397), 280-case M9, H2 axiom→theorem)        |
| `artifacts/theorema-certs/src/pages/miegakure.tsx`     | 600-Cell Viewer (H₄ root system, Coxeter rotation)                  |
| `artifacts/theorema-certs/src/lib/h4-600cell.ts`       | H₄ 600-Cell Geometry (120 vertices, 720 edges, 4D rotation)         |
| `lib/db/src/schema/certificates.ts`           | Drizzle Schema — Certificates Table (M1–M9, parent SHAs, Lean theorem names) |
| `lib/api-spec/openapi.yaml`                   | API Contract (source of truth, drives Orval codegen)                |

## VI. The Architecture Volume (this manifesto)

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `docs/MorningStar_Architecture.{tex,pdf}`     | *The MorningStar Architecture — A Mathematical-Engineering Firewall* (Vol. I Math Kernel + Vol. II Engineering Manifest) |
| `docs/SiteMap.md`                             | Repository Site Map (this file)                                     |
| `docs/ProofIndex.md`                          | Proof Index — Paper · Title · Theorem · Subject                     |
| `.local/tasks/morningstar-pdf.md`             | Architecture PDF — Locked Plan (Plan/Build firewall doctrine)       |
| `.local/tasks/pdf-notes-batch1-hilbert-auditor.md`     | Source Batch 1 — H₄-KMS Hilbert Space Auditor framing      |
| `.local/tasks/pdf-notes-batch2-protocol-roadmap.md`    | Source Batch 2 — RH-TLS/1.0 + Millennium roadmap            |
| `.local/tasks/pdf-notes-batch3-eigenvalue-gun-stationos.md` | Source Batch 3 — Eigenvalue Gun + StationOS v1.8-BC    |
| `.local/tasks/pdf-notes-batch4-rfc-zeta-osi.md`        | Source Batch 4 — RFC-ζ-1.0 + OSI mapping + Three Invariants |
| `.local/tasks/pdf-notes-batch5-h4-stationos-observer.md`| Source Batch 5 — H₄, GLM-600, 600-cell superstate, Plan/Build observer effect |
| `README.md`                                    | Public-Facing Release Summary (v1.8-BC scope)                       |
| `CITATION.cff`                                 | Citation Metadata (no DOI; v1.8-BC source-of-truth on Replit)       |
| `replit.md`                                    | Operator Runbook                                                    |

## VII. Yang–Mills surface installments (Volume IV, research-program preprints)

Honest-scope writeups of the formalized infrastructure landing on the YM tower
(`lean-proof-towers/Towers/YM/`). The YM tower itself remains
**Status: Open** in `docs/ROADMAP.md` § 2; these documents do not promote it.
Each preprint enumerates exactly which Lean identifiers it relies on and which
gaps remain open as project tasks.

| Node                                          | Title                                                              |
| --------------------------------------------- | ------------------------------------------------------------------ |
| `docs/Surface1_InstallmentA.{tex,pdf}`        | *Surface #1, Installment A — A Formalized Truncation-to-Envelope Bridge for the SU(3) Peter–Weyl Heat-Kernel Series* (tasks #154, #155; +8 trio-clean bricks; Varadhan small-t asymptotic remains open as task #156) |
| `docs/Surface2_ResearchProgram.{tex,pdf}`     | *Surface #2 (Research Program) — A Polymer-Expansion Scaffold for 4D SU(3) Lattice Yang–Mills, With an Honest Accounting of the Open Analytic Gaps* (target of `kotecky_preiss_criterion` parked sorry; nothing formalized at this surface yet) |

## VIII. Out of scope for v1.9 (explicitly deferred)

- L₂ = Dirichlet L(s, χ₅) — no `hits_dirichlet_5.txt` exists; no `genesis_dir5` computed.
- L₃ = Elliptic L(E37a1, s) — `kernel.elliptic_stub` refuses to evaluate; no Sage backend wired.
- Yang–Mills mass gap (Surface #1 envelope landed in §VII; full proof open), Navier–Stokes regularity, BSD beyond M10/M13 — roadmap only.
- E₈ cross-L coupling, gaskets — Stage 4 deferral list (batch 3 §F.1).
- γ₁₀₀₀₁ → γ₁₀₀₀₀₀ via `zeta_sieve(14159, 100000)` — workflow stalled at finalize, not restarted; see Casualty Log Incident 4.
