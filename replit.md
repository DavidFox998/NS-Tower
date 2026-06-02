# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-06-02

- **MODULE B LANDED — `Towers/YM/H4_Boundary.lean` (2026-06-02).** Boundary
  check over the Module-A decode; imports the shared core `Towers.YM.H4Core`,
  mathlib-FREE, `sorry`/`admit`/`sorryAx`/`native_decide`-free, NOT a brick, NOT
  in BRICKS, NOT a lakefile root, compiled direct (EXIT 0). `digit_len p :=
  (toString p).length` (`Nat.log10` is mathlib-only), `C13 := 13`. For the nine
  proposed witnesses `[2,3,19,191,10000000001119,1000000001357,1000000001511,
  1000000001723,1000000001831]` the engine gives `digit_len =
  [1,1,2,3,14,13,13,13,13]` and `symOf = [120,20,2,2,1,1,1,1,1]` (from
  `H4Core.symOf`, NOT hardcoded). `boundary_test` (`digit_len≥13 ⟹ symOf=1`,
  else `symOf≥2`) is `true` on all nine — a CHECKED SAMPLE FACT, NOT a proved
  ∀-law. **HONEST FINDING:** the proposed `P5 = 10000000001119` has `digit_len
  14`, NOT 13, so the proposed identity `digit_len P5 = C13` is FALSE; the real
  13-digit boundary prime is `1000000001119` (Module A) with `digit_len=13`,
  `symOf=1`. `symOf 19 = 2` (NOT 20) reconfirmed. Cheap axiom-free fact
  `C13_val` (`#print axioms` = none). Per-module `data.json`
  (`Towers/YM/H4_Boundary.data.json`, SHA-256
  `121ff80c61831b34de8f3826787cfe90907557471798ee9269862a8ce9eb481c`) records
  the real per-witness `{p, digit_len, sym}`. Proves NO YM/mass-gap/Surface-#1
  result; pure finite geometry. Companion `#326` NOT built (user STOP).
- **MODULE A LANDED — `Towers/YM/H4_Strata_Ztau.lean` (2026-06-02).** Real
  W(H₄) point-stabilizer computation over exact `ℤ[τ]` (`τ²=τ+1`), mathlib-FREE
  (Lean core only), `sorry`/`admit`/`sorryAx`/`native_decide`-free, NOT a brick,
  NOT imported, NOT in `scripts/check-towers.sh` BRICKS. `V` = 120 doubled
  icosians stored as a flat `List Int` (`vflat`, 960 ints) reshaped by a
  structural `chunk` (avoids the super-linear elaboration blow-up of 120 nested
  anonymous-constructor literals). `W(H₄)` (order 14400) acts via the EXACT
  integer maps `p·x·q̄=4x` (proper) / `p·x̄·q̄=4x` (improper) with the `±(p,q)`
  identification; `Sym x` enumerates `V×V`. **Verified `#eval` outputs:**
  `Sym(origin)=14400`, `Sym(vertex)=120`; Module-A witness primes
  `[2,3,19,191,1000000001119] → [120,20,2,2,1]` (nine: `[120,20,2,2,1,1,1,1,1]`);
  Lagrange divisibility all `true`. **HONEST FINDING:** the natAbs Euclidean
  decode yields `[120,20,2,2,1]`, NOT David's conjectured `[120,20,20,2,1]` —
  the `20` at `p=19` came from a different (signed) decode; per the geometry-wins
  rule the table is corrected. Kernel-checked axiom-clean facts: `tau_sq`
  (`τ²=τ+1`), `vflat_card` (`vflat.length=960`) — both `#print axioms` = none.
  PURE FINITE GEOMETRY: proves NO YM/NS/RH/Bost/BSD, makes NO mass-gap/μ>0/
  Surface-#1 claim, NOT keyed to any prime or L-function. Compiled via the
  v4.12.0 toolchain (the registered milestone is prose+SHA only — main-agent git
  is write-blocked; Replit checkpoints capture the merged state).
  **REFACTOR (2026-06-02):** the reusable engine (ℤ[τ]/Quat arithmetic, `vflat`/
  `chunk`/`V`, the `W(H₄)` action, `Sym`, `ilog3`, `decodeQuat`/`symOf`) is now
  factored into the shared mathlib-free core `Towers/YM/H4Core.lean`; Module A
  `import`s it and its `#eval` outputs are BYTE-IDENTICAL (`[120,20,2,2,1]`,
  `Sym origin=14400`, `Sym vertex=120`, Lagrange all `true`), with
  `tau_sq`/`vflat_card` still axiom-free (`#print axioms` = none). Core+leaf
  both EXIT 0 via direct `lean` over a hand-built `LEAN_PATH` (no lake). The
  per-module `data.json` + SHA-256 / certified-prime-source output convention is
  DEFERRED at the user's request ("come back to .json") — NOT yet built.
- **H1 AXIOM-DERIVED PACKAGING — `Towers/YM/Hw1_Surface.lean` (2026-06-01).** H1
  (`w1 β₀ < 1/7`) is DERIVED from two disclosed OPEN `[NEEDS_LEMMA]` axioms (NOT
  proved). Direct proof infeasible in mathlib v4.12.0 (NO Bessel/`Real.besselI`,
  NO SU(3) Weyl/Gross–Witten, `norm_num` can't decimalise `Real.exp`/Bessel; any
  `sorry` ⟹ `sorryAx`), so the two analytic facts are carried as VISIBLE axioms,
  not hidden in a `sorry`. Over `opaque w1`, `opaque besselI` (Bessel stand-in),
  `β₀ := 2.079416880124` (CERT_Arb upper endpoint): concrete `def w1_weyl β :=
  e^{-β}·∑_{k∈ℤ} det[besselI ((i-j)+k) (β/3)]_{3×3}` (Toeplitz det at β/3);
  `axiom w1_eq_weyl : w1 β₀ = w1_weyl β₀` `[NEEDS_LEMMA]`; `axiom w1_weyl_beta0_lt
  : w1_weyl β₀ < 1/7` `[NEEDS_LEMMA]`; `theorem hw1 : w1 β₀ < 1/7` (`rw
  [w1_eq_weyl]; exact w1_weyl_beta0_lt`) — `#print axioms` = trio +
  `w1_eq_weyl` + `w1_weyl_beta0_lt` exactly. `w1_beta0_lt_seventh := hw1` (alias).
  Trio-only checkable facts: `cert_value_lt_seventh` (`0.142856757048 < 1/7`),
  `beta0_in_cert` (`β₀ ∈ [beta0_lo, beta0_hi]`). `lattice_decay_conditional` =
  the HONEST `closes_surface_1` (REFUSED that name): threads `hw1` + the two
  further OPEN inputs `hOS`+`h_bridge` through
  `Wall256Scaffold.strong_coupling_decay_of_open_inputs` to a LATTICE two-point
  decay shape (necessary-not-sufficient; does NOT close Surface #1). The two
  axioms are CONSISTENT (`w1`/`besselI` opaque ⟹ model `w1 β₀ = w1_weyl β₀ = 0`).
  Direct-lean EXIT=0; SORRY: 0; NOT a brick / lakefile root. Evidence OUT-OF-TOWER
  only (CERT_Arb + `w1_repo_normalization.py`). Surface #1 / YM stay OPEN; NO
  mass-gap / μ>0 / Clay claim. Detail → `docs/CHANGELOG.md`.
- **Older 2026-06-01 leaves (full detail → `docs/CHANGELOG.md`):** Bost-violation
  check `Towers/BostViolations/Compute.lean` (computable `C_rat` over ℚ,
  `BostViolations_12 = []` — no violations; conjecture stays OPEN); Hodge
  `SMap.lean` / `Twelve.lean` / `Defs.lean` (12-curve `exceptional_12` + real
  M4-certified `S_14`, `opaque S` per-curve set; `TwelveViolation_Surface` OPEN,
  unasserted; α₀ = 299+π/10 is ONE constant, NOT a per-`d` family — no
  fabrication); compiling `CanonicalSurfaces` registries split `Towers/YM/` +
  `Towers/NS/` (`YM_Clay_Open`, `NS_Open` — name/group only, discharge nothing).
  All classical trio, SORRY: 0, prove NOTHING new.
- **VACUOUS SURFACE PURGE + SORRY PURGE (2026-05-31; detail → `docs/CHANGELOG.md`).**
  Every live `sorry` proof-term in `Towers/` → named open `Prop` hypothesis
  (`theorem foo := by sorry` ⟹ `def Foo_Surface : Prop` + `theorem foo (h) := h`);
  BSD `axiom`s → hypotheses. Audit: 11 named `*_Surface` Props were VACUOUS under
  stand-in defs (2 fully-vacuous files → `Towers/Deprecated/`, 9 flagged in
  `Attempts/`); 6 GENUINE open surfaces (4 YM, 2 NS) indexed by the split
  registries above. Grep: 0 bare `sorry`/`axiom`/`admit` proof-terms. Logical
  hygiene only — discharges NO surface. SORRY: 0; classical trio.
- **NS Tower 540 — weak→strong chain, Phases 1–6 COMPLETE, FROZEN at the Clay
  boundary (Status: Open).** Milestone `NS-540-phase6-clay-boundary` @ checkpoint
  `c5f29fb4390e5dda83ffdbfcae5dea2333cf5c12`. Both Clay surfaces stay OPEN:
  Surface #1 global regularity (`global_smooth_exists : Prop`, named hypothesis,
  classical trio) and Surface #2 weak existence (`weak_solution_exists`, HONEST
  combinator over the MODELED `WeakNS` surrogate, nonlinear term dropped — NOT
  literal Leray–Hopf). Per-phase detail → `docs/CHANGELOG.md` + `docs/ROADMAP.md`.
- **YM wall series** (Wall251b–Wall263, Wall262a, S4Numerics,
  WilsonPositivitySU2, EntropyBound, RiemannianGeometry) — all bricks, in BRICKS,
  `sorry`-free, classical trio. Each proves NO YM result, discharges NO open
  surface, makes NO mass-gap / μ>0 / Surface-#1 claim. Full per-wall index →
  `docs/CHANGELOG.md`.
- **YM Transfer / polymer / positivity / measure scaffolding** (NONE bricks,
  classical trio) — real SU(3) Haar stack, integral transfer `T_L` with
  `‖T_L‖ ≤ 1`, Wilson positivity, cluster-expansion `polymerActivity`. Every
  lemma is necessary-not-sufficient; the spectral lower bound stays OPEN as the
  named open-surface `Transfer.kotecky_preiss_criterion` (a `Prop` hypothesis
  post-purge, formerly a disclaimed `sorry`). NO mass-gap / Surface-#1 claim.
  Detail → `docs/CHANGELOG.md`.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) — `YM_mass_gap` elaborates
  against the real Step-4/5 `H` / `spectrum_bound` and now threads the named-open
  surface `YM_mass_gap_Surface` (a `Prop` hypothesis post-purge, formerly a
  `sorry`); OPEN, INVARIANT-LOCKED, NOT in BRICKS. `H = wilsonAction U • 𝟙` is
  the scalar shadow, NOT the real Wilson transfer operator — no mass-gap claim.
  (The companion `YM_mass_gap_nontrivial` discharges `hpos` for non-trivial `U`
  and is `sorry`-free, but only over the same scalar shadow.) NB: some in-file
  docstrings still say "keeps its `sorry`" — stale prose, not the proof-term.
- **Registered YM walls** (tagged, lake-gated, NOT in BRICKS): 571-B
  `[YM1-LB-Core]`, 572 `[YM1-LB-Real]`, 573 `[YM1-GR]`, 575 `[YM1-SB]`. All
  classical trio.
- **Geometry / Hodge leaves** (NOT bricks): `Wall264_H4Vertices.lean` (600-cell
  vertex geometry, machine-checked) and `Towers/Hodge/ZoeComparisonTest.lean`
  (HODGE_STATUS: OPEN, conditional reduction over the named-open
  `AnalyticObstruction`). Detail → `docs/CHANGELOG.md`; prior superseded Hodge
  work (Lemma 7.6, M* Transform) is retracted there.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (also `H2_WeilTransfer`,
  `M9_WeilTransfer_All`). Every landed brick is classical-trio-only.
- **Mathlib:** v4.12.0 only. **YM Surface #1: OPEN** — no `m > 0` claim while
  the `sorry` stands.
- **Wall count:** the BRICKS array in `scripts/check-towers.sh`
  (`${#BRICKS[@]}`) is the source of truth, not this file.
- **Deferred:** 24 OS/KP modules unregistered; `.lean` files kept on disk, await
  Wall 570+/574 with the real SU(3) `H`.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` stays OPEN in
  `Towers/Attempts/ClusterExpansion.lean` — a named open-surface hypothesis
  post-purge (formerly a `sorry`); invariant-locked, do not discharge.
- **NS FREEZE.** `Towers/NS/*` is FROZEN at the Clay boundary (milestone
  `NS-540-phase6-clay-boundary`). NO further commits to `Towers/NS/` without an
  explicit unfreeze order from the user. Surface #1 (`global_smooth_exists`) and
  Surface #2 (modeled `weak_solution_exists`) stay OPEN; "NS solved" /
  "regularity proven" / "weak solutions exist (literally)" claims are REFUSED.
  - **Unfreeze exception (2026-05-31): `Towers/NS/Wall300_Scaffold.lean`** added
    under an EXPLICIT user unfreeze order. HONEST CONDITIONAL combinator
    `navier_stokes_global_regularity` threading three named open surfaces (weak
    existence, local regularity, global continuation) through
    `Regularity.weak_implies_strong` to a MODELED global-smoothness shape.
    SORRY: 0, axiom-free, NOT a brick. Proves NO regularity; Surfaces #1/#2 stay
    OPEN. NS otherwise still frozen.
  - **Unfreeze exception (2026-06-01): `Towers/NS/CanonicalSurfaces.lean`** added
    under an EXPLICIT user unfreeze order. Purely ADDITIVE registry — `def
    NS_Open : Prop` that NAMES/groups the two genuine NS open surfaces
    (`enstrophy_bound_global_Surface`, `leray_proj_ker_eq_grad_Surface`);
    imports/modifies no frozen NS proof. SORRY: 0, classical trio, NOT a brick.
    Discharges NOTHING; Surfaces #1/#2 stay OPEN. NS otherwise still frozen.
- **Infra (in progress).** Disabling the `towers-build` auto-run and permanently
  locking the mathlib `v4.12.0` pin is tracked as a background Project Task
  (#294); until it lands, every boot/merge can still wipe the pin and require
  the manual recovery in "Operational gotchas".

## Operational gotchas

- **Git-tag creation is restricted for the main agent.** `git tag` (and other
  git writes) are blocked with "Destructive git operations are not allowed in
  the main agent" — they must go through a background Project Task. This repo's
  working convention is therefore to track milestones as **prose + SHA** in
  `replit.md` / `docs/ROADMAP.md` / `docs/CHANGELOG.md` (e.g. "YM frozen at
  `c8f6a7ed`", "milestone `NS-540-phase2b-stokes` @ checkpoint `f4becd5`"),
  NOT as literal git refs. Replit checkpoints already capture the merged state.
- **Do NOT run `towers-build` / `lake update` casually.** Both re-clone the
  vendored mathlib checkout and wipe its oleans, requiring a `lake-recovery`
  (`lake exe cache get`) pass. Verify bricks via direct `lake env lean <file>`
  + `#print axioms` — **but `lake env` is ALSO destructive when the
  `v4.12.0` tag is missing.** `lake env` re-resolves `inputRev: v4.12.0` from
  the mathlib git; if the tag does not resolve it fetches from remote and wipes
  the oleans, exactly like `lake update` (confirmed 2026-05-30). So BEFORE any
  `lake env lean`, assert `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds. Recovery if wiped: `scripts/restore-lake-git.sh`
  (run it TWICE — first run restores `.git` at the pinned rev, second run
  rehydrates the empty worktree via its `git checkout -- .` heal), then recreate
  the tag (`git -C lean-proof-towers/.lake/packages/mathlib tag -f v4.12.0
  809c3fb3b5c8f5d7dace56e200b426187516535a`), then run
  `scripts/fetch-mathlib-oleans.sh` to re-download the oleans.
- The destructive mathlib re-clone is triggered when the restore-tar's vendored
  mathlib `.git` lacks the `v4.12.0` tag (lake fetches from remote to resolve
  `inputRev: v4.12.0`). Fix: recreate the tag locally after any
  `restore-lake-git.sh` worktree rebuild —
  `git -C .lake/packages/mathlib tag v4.12.0 <HEAD>` (manifest `rev` already =
  HEAD). It is NOT persisted in the restore tar.
- **Direct-lean verify bypass.** When the `v4.12.0` tag is unresolved (so `lake
  env` would wipe the oleans) but the oleans are intact, compile a brick with a
  hand-built `LEAN_PATH` over each `.lake/packages/*/.lake/build/lib` +
  `.lake/build/lib` and invoke `lean <file>` directly from `lean-proof-towers/`.

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.
Typecheck with `pnpm --filter @workspace/theorema-certs run typecheck` (NOT
`build`, which needs workflow-provided `PORT`/`BASE_PATH`). The dashboard
consumes generated hooks from `@workspace/api-client-react`; after editing the
OpenAPI spec run `pnpm --filter @workspace/api-spec run codegen`, and if the
consuming typecheck reports missing exports rebuild the composite lib
declarations with `pnpm run typecheck:libs` (its `exports` resolves through the
project-reference `dist/*.d.ts`, which can go stale).

## Wall256 — SU(3) conditional reduction (research phase)

`Towers/YM/Wall256_Scaffold.lean` (commit `8eeab54`, tracked on main, NOT a
brick). Classical trio, 0 `sorry`, YM_STATUS: OPEN. **Conditional reduction
only** — `strong_coupling_decay_of_open_inputs` threads three explicit OPEN
hypotheses through the genuine `Wall256Note.kp_summable_of_truncatedActivity`
comparison test to an abstract two-point decay shape. Proves NO mass gap, NO
`μ > 0`, NO Surface-#1; LATTICE scope, NOT Clay. The conclusion is valid ONLY
IF the three hypotheses hold; none is discharged or scheduled:

1. **`w1_SU3_bound`** (`hw1 : w1 < 1/7`) — strict single-site SU(3) Haar weight
   bound. STRICT matters: `= 1/7` gives `I = log 7` and a divergent entropy
   series. In the scaffold `w1 : ℝ` is abstract, so `hw1` is formally trivial;
   a real `w1 := ∫_{SU(3)} exp(-β·S) d haarSU3` needs SU(3) character theory or
   verified cubature, absent from mathlib v4.12.0.
2. **`OS_cluster_bound`** (`hOS : w1 < 1/7 → TruncatedActivityBound a`) — the
   Osterwalder–Seiler strong-coupling Ursell/cluster step (NOT OS reflection
   positivity).
3. **`KP_implies_decay`** (`h_bridge`) — the Brydges–Federbush step:
   KP-summability ⟹ geometric two-point clustering with `ρ < 1` (Friedli–Velenik
   2018, Ch. 5; absent from mathlib v4.12.0).
