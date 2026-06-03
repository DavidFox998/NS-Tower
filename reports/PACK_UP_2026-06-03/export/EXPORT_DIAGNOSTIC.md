# Morning Star / Theorema Aureum 143 — Full Repo Export Diagnostic

**Generated:** 2026-06-03 · **By:** `full_repo_export()` · **Author:** D. Fox

This is a point-in-time diagnostic snapshot bundled with the source/dataset
export. It records module status and the validation suite result captured at
export time. It is honest about scope: **no Clay-level result is claimed.**

## Validation suite at export time (all green)

| Check | Command | Result |
|---|---|---|
| Lean proof (strict) | `STRICT_LEAN_CHECK=1 ./scripts/check-lean-proof.sh` | PASSED |
| Kernel numerics | `pytest tests/test_kernel.py` | PASSED (19 tests) |
| Lake recovery | `pytest tests/test_restore_lake_git_script.py …` | PASSED (16 tests) |
| Morning Star tamper | `pytest tests/test_morningstar.py …` | PASSED (22 tests) |
| theorema-certs e2e | `STRICT_E2E_CHECK=1 scripts/check-theorema-certs-e2e.sh` | PASSED (47 tests) |

## Module status (honest)

- **Lean proof tower (`lean-proof-towers/`)** — axiom footprint = classical trio
  `{propext, Classical.choice, Quot.sound}`; no `sorry`/`admit`/`sorryAx` in any
  landed brick; mathlib pinned to v4.12.0.
- **RH (`Towers/RH/`)** — `GrowthContradiction.lean` / `ZProtocolBridge.lean` are
  **honest conditional reductions** to mathlib's real `RiemannHypothesis`; both
  growth hypotheses are OPEN and in fact false (Ω-results) / circular. **RH is
  NOT proved.** `ZeroDensity.lean` keeps Riemann–von Mangoldt as a statement only.
- **YM tower** — Surface #1 / mass gap stay **OPEN**; every Measure-surface brick
  is vacuous under the Dirac/stand-in transfer operator. **No `m > 0` claim.**
- **NS tower (`Towers/NS/`)** — FROZEN at the Clay boundary; Surface #1
  (`global_smooth_exists`) and the modeled Surface #2 (`weak_solution_exists`)
  stay **OPEN**.
- **H4 strata (`Towers/YM/H4*`)** — BUILD_MANIFEST v2.3; A/A.1/E/D verified;
  `C13_Law_Open` remains a **CONJECTURE** (empirical 6/6), not a theorem.
- **Zeta methodology field notes (`docs/zeta-methodology-field-notes.md`)** —
  honest end-to-end critique of the 7-fold-modular-symmetry → ζ-growth → RH chain;
  finds the dimension-drop step fails (true counting exponent = 1) and the growth
  bound false/circular. Makes **no** new ζ/RH claim.
- **theorema-certs dashboard (`artifacts/theorema-certs/`)** — certificate-ledger
  web app; typechecks clean; e2e green.

## What this export does NOT assert

No proof of the Riemann Hypothesis, GRH, BSD, the Yang–Mills mass gap, Navier–
Stokes global regularity, or any new bound on ζ. Headline `Prop := True` legacy
stubs are tautologies and are labeled as such in-tree. Every OPEN surface above
stays OPEN. See `replit.md`, `docs/CHANGELOG.md`, and `docs/ROADMAP.md`.

## Contents & exclusions

**Included:** all project source (Lean source, Python kernel/scripts, artifacts
source, libs, tests, docs, paper sources) and the scientific datasets (`data/`,
`attached_assets/`, `*.data.json`, `Z_INPUT_SET.json`, committed certificates).

**Excluded (regenerable / non-portable / state):** `.git` history, all
`node_modules`, `lean-proof*/.lake` build caches + vendored mathlib oleans
(multi-GB, restore via `scripts/fetch-mathlib-oleans.sh`), `.cache`,
`.pythonlibs`, `.pytest_cache`, `__pycache__`, `.config`, `.upm`, agent state
under `.local`, and Playwright artifacts.

Per-file SHA-256 digests for everything bundled are in `SHA256SUMS.txt`; the
archive's own digest is in the accompanying `.tar.gz.sha256` file.
