# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **NS Tower 540 — honest weak→strong chain, Phases 1–6 COMPLETE** (NONE are
  bricks / in BRICKS / lakefile roots; all classical-trio, no `sorryAx` EXCEPT
  the one isolated documented `sorry` `leray_proj_ker_eq_grad` in `Leray.lean`
  (reports `sorryAx`, not a brick, not in the weak→strong chain),
  verified live; full per-phase detail → `docs/CHANGELOG.md` +
  `docs/ROADMAP.md`). Fourier-side model on `Hdiv_free (s+2)`, `ν = 1`:
  - **P1** `FunctionSpaces.lean` (Hˢ as weighted `L²`; `divFreeSubmodule`
    PROVED-closed; bounded `embed` — NOT a compact embedding). **P2**
    `Leray.lean` (`leray_proj`; 1 documented `sorry` `leray_proj_ker_eq_grad`)
    + `Stokes.lean` (`stokes_op`, fully `sorry`-free; NAMES/BOUNDS the operator
    only — no self-adjointness / semigroup). **P3** `Energy.lean` (`energy`,
    `energy_inequality` combinator; NAMED `integration_by_parts`). **P4**
    `GalerkinApprox.lean` (finite-dim `galerkinProj`, a-priori bounds) +
    `Compactness.lean` (NAMED `AubinLionsCriterion`; `galerkin_strong_convergence`
    combinator).
  - **P5** `WeakSolution.lean` — `weak_solution_exists : ∃ u, WeakNS u u₀ f`, an
    honest combinator from THREE NAMED Props (`galerkin_subsequence_converges`,
    `limit_satisfies_weak_form`, `energy_inequality_passes_to_limit`).
    `WeakMomentum`/`WeakNS` are MODELED surrogates (linear weak form — nonlinear
    `(u·∇)u` DROPPED; force-free energy bound), NOT literal Leray–Hopf.
  - **P6** `Regularity.lean` — `weak_implies_strong (h : global_smooth_exists)
    (w : WeakSolution s) : ∃ T > 0, IsSmoothOn w.u T`, an honest combinator from
    the SINGLE NAMED Prop `global_smooth_exists` (the NS global-regularity
    surface). `IsSmoothOn` is a MODELED surrogate for `C^∞((0,T) × ℝ³)` (temporal
    `ContDiffOn ℝ ⊤` of tested profiles `t ↦ ⟪u t, φ⟫` only). `#print axioms` on
    both `weak_implies_strong` and `global_smooth_exists` = classical trio.
    Because the single sorry IS the surface, **NS Tower 540 is FROZEN at 251**
    (milestone `NS-540-phase6-clay-boundary` @ checkpoint
    `c5f29fb4390e5dda83ffdbfcae5dea2333cf5c12`; supersedes
    `NS-540-phase6-regularity`): the regularity surface is reached, left OPEN.
  - **NS COMPLETE TO THE CLAY BOUNDARY — FROZEN (Status still Open).** The
    weak→strong tower is built up to the Clay surface and stopped there:
    - **Surface #1 — global regularity: OPEN.** `global_smooth_exists : Prop`
      is the single NAMED Clay surface (an unproved hypothesis, NOT `by sorry`,
      so NO `sorryAx`); `#print axioms` = classical trio. This is the entire
      mathematical content behind `weak_implies_strong`.
    - **Surface #2 — weak existence: OPEN (modeled).** `weak_solution_exists`
      is an HONEST COMBINATOR routing THREE NAMED Props over the MODELED
      `WeakNS` surrogate (linear weak form; nonlinear `(u·∇)u` DROPPED) — it is
      NOT a literal Leray–Hopf existence theorem and proves NO NS existence.
    - Audited live: `Regularity.lean` compiles EXIT=0; `#print axioms` on both
      `global_smooth_exists` and `weak_implies_strong` = `[propext,
      Classical.choice, Quot.sound]`. NS named surfaces (no `sorryAx`):
      `global_smooth_exists`, `galerkin_subsequence_converges`,
      `limit_satisfies_weak_form`, `energy_inequality_passes_to_limit`,
      `AubinLionsCriterion`, `integration_by_parts` (6). PLUS one pre-existing
      real `sorry` `leray_proj_ker_eq_grad` (`Leray.lean`, reports `sorryAx`,
      ISOLATED — not a brick, not used by the weak→strong chain). 7 total ≤ 9.
  - HONEST scope: these build spaces, name/bound operators, and assemble the
    Galerkin weak-existence + conditional-regularity combinators from NAMED
    inputs; they prove NO NS existence/uniqueness/regularity result. NS stays
    `Status: Open`; Surface #1/#2 stay OPEN; YM untouched.

- **Wall:** 575 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`). The
  source of truth for the count is the script, not this file.
- **Wall253_KP_Cluster — HONEST CONDITIONAL Kotecký–Preiss cluster expansion
  (bricks, in BRICKS):** `Towers/YM/Wall253_KP_Cluster.lean` extends Wall252's
  single-plaquette `kp_sum_lt_half` base case toward a full polymer sum in two
  honestly-scoped layers. **(1) Base case:** `kp_sum_nonneg` (`0 ≤ KP_sum β g`
  for `β ≥ 0`) and `kp_sum_lt_one` (`KP_sum β g < 1`, from `kp_sum_lt_half`'s
  `< 1/2`). **(2) Cluster expansion (GENUINE multi-term sum over all polymer
  sizes `n`):** `kp_cluster_summable` (`Summable (fun n => (KP_sum β g)^n)`) +
  `kp_cluster_sum_lt_two` (`∑' n, (KP_sum β g)^n < 2`), via mathlib's
  `summable_geometric_of_lt_one` / `tsum_geometric_of_lt_one`. **(3) Full
  polymer-index criterion:** `kp_cluster_criterion` derives
  `Summable (fun π => |activity π|)` over an arbitrary (possibly infinite)
  polymer index from the NAMED OPEN surface `hKP : Summable (fun π =>
  |activity π|·e^{a π})` by the comparison test (`e^{a π} ≥ 1`). 5 public
  theorems registered; all `sorry`-free, `#print axioms` = classical trio
  (verified live, raw `lean`, EXIT=0). HONEST: the geometric layer is a
  SIZE-series MAJORANT with polymer multiplicity (entropy `≈ 7^n`, cf.
  `EntropyBound.polymer_const = 7`) DROPPED — beating it geometrically needs
  per-polymer activity `< 1/7`, NOT the `< 1/2` that `kp_sum_lt_half` supplies,
  so the entropy-weighted polymer sum is NOT shown to converge here.
  `kp_cluster_criterion` is CONDITIONAL on the OPEN surface `hKP` (the genuine
  KP tree-graph / Ursell weighted-summability core, absent from mathlib
  v4.12.0; a HYPOTHESIS, NOT `by sorry`, so NO `sorryAx`) — it is the same
  comparison-test shape as the invariant-locked `kotecky_preiss_criterion` and
  does NOT touch or discharge that `sorry`. This file proves `hKP` NOWHERE,
  establishes NO unconditional KP convergence, and makes NO mass-gap / μ>0 /
  Surface-#1 / RH / BSD claim. YM stays `Status: Open` (cluster expansion + OS
  positivity remain to be done).
- **Wall252_KP — MODELED Kotecký–Preiss smallness bound (bricks, in BRICKS):**
  `Towers/YM/Wall252_KP.lean` lands `kp_sum_lt_half` — for `0 ≤ β < 48/e`,
  `KP_sum β g < 1/2`, where `KP_sum β g := zModes·kEff·C_S4·exp(−β·E_g)·e·β /
  11520` and `E_g := su2PlaquetteEnergy g`. An HONEST ARITHMETIC COMBINATOR that
  USES all four requested inputs: `zModes_eq` (→ `(zModes:ℝ)=15`), `kEff_le`
  (→ `≤16/5`), `c_S4_lt` (→ `C_S4<5/2`) give `kpModeWeight < 120`
  (`kpModeWeight_lt`); `su2_plaquetteEnergy_nonneg` (→ `E_g≥0`) gives the
  activity `exp(−β·E_g) ≤ 1`. 3 public theorems registered (`kpModeWeight_lt`,
  `kpModeWeight_nonneg`, `kp_sum_lt_half`); all `sorry`-free, `#print axioms`
  = classical trio (verified live, raw `lean`, EXIT=0). DEVIATION from the
  literal `KP_sum β` ask: the def takes `(β, g)` and the theorem assumes `0 ≤ β`
  — both are needed to use `su2_plaquetteEnergy_nonneg` genuinely (the activity
  `exp(−β·E_g) ≤ 1` step requires a real plaquette and `β ≥ 0`). HONEST:
  `KP_sum` is a MODELED SINGLE-TERM MAJORANT SURROGATE, NOT the genuine
  infinite Kotecký–Preiss polymer sum (`∑_{γ∋x} |activity(γ)| e^{a(|γ|)}` over
  ALL lattice polymers with a weight `a:Polymer→ℝ`). The constants are bare
  numerics (see S4Numerics); `48/e` and `11520` are tuned so the bound is tight
  at the boundary. Makes NO mass-gap / μ>0 / Surface-#1 / RH / BSD claim, does
  NOT establish KP convergence, and does NOT discharge the disclaimed
  `kotecky_preiss_criterion` `sorry`; YM stays `Status: Open`.
- **SU(2) Wilson-positivity companion (brick, in BRICKS):**
  `Towers/YM/WilsonPositivitySU2.lean` lands the verbatim N = 2 instances of the
  SU(3) positivity bricks — `traceRe_le_two` (`Re tr A ≤ 2`),
  `traceRe_eq_two_iff` (`Re tr A = 2 ↔ A = 1`), `plaquetteEnergy2_nonneg/_pos_iff`,
  plus `hsNormSq2_nonneg/_eq_zero_iff/_sub_one_eq` (identity `= 4 − 2·Re tr A`).
  6 registered; all `sorry`-free, `#print axioms` = classical trio (verified live
  `lake env lean`, EXIT=0). HONEST: this content uses ONLY unitarity
  (`star A * A = 1`), never `det = 1` — it is N-generic linear algebra, NOT
  SU(2)/SU(3)-specific and NOT a mass-gap claim. The fact that the SU(3) proof
  ports unchanged to N = 2 is the point: it bears on NO group-specific structure.
  Surface #1 stays OPEN; the genuine gap remains the disclaimed
  `Transfer.kotecky_preiss_criterion` `sorry`, untouched.
- **S4Numerics — four standalone TRUE ARITHMETIC FACTS (bricks, in BRICKS):**
  `Towers/YM/S4Numerics.lean` lands `c_S4_lt` (∑_{p∈{2,3,19,191}} log p/(p−1)
  < 5/2), `kEff_le` (10/π ≤ 16/5), `zModes_eq` (15 = 120/2³), `h4Order_factor`
  (14400 = 2⁶·3²·5²). 4 registered; all `sorry`-free, verified live (raw `lean`,
  EXIT=0): `c_S4_lt`/`kEff_le` `#print axioms` = classical trio,
  `zModes_eq`/`h4Order_factor` = `[propext]` only. HONEST: these are bare
  arithmetic — they construct NO H4 Coxeter group (`h4Order_factor` is a prime
  factorization of the *integer* 14400, group-theoretically EMPTY), carry NO
  physical/number-theoretic content, are NOT load-bearing toward any tower, and
  make NO mass-gap / μ>0 / Surface-#1 / RH / BSD claim. The `linarith` failures
  fixed by converting decimal `OfScientific` literals to clean rationals first
  (linarith treats decimals as opaque atoms).
- **Wall251b_H4 — SU(2) Wilson positivity on the genuine `specialUnitaryGroup`
  (bricks, in BRICKS):** `Towers/YM/Wall251b_H4.lean` lifts the verified
  `WilsonPositivitySU2` lemmas onto `Matrix.specialUnitaryGroup (Fin 2) ℂ`:
  `su2_star_mul_self` (`star ↑g * ↑g = 1`, extracted from membership via
  `mem_specialUnitaryGroup_iff` + `mem_unitaryGroup_iff'`),
  `su2_wilson_hs_identity` (`‖↑g − 1‖²_HS = 4 − 2·Re tr ↑g`),
  `su2_traceRe_le_two`, `su2_traceRe_eq_two_iff`, `su2_plaquetteEnergy_nonneg`,
  `su2_plaquetteEnergy_pos_iff`. 6 registered; all `sorry`-free, `#print axioms`
  = classical trio (verified live, raw `lean`, EXIT=0). NOTE: in v4.12.0
  `specialUnitaryGroup` lives in `Mathlib.LinearAlgebra.UnitaryGroup` (there is
  NO `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` module). HONEST: uses
  ONLY unitarity (det = 1 discarded) — N-generic linear algebra, NOT
  SU(2)-specific. `su2_plaquetteEnergy_nonneg` is POINTWISE Wilson positivity,
  NOT Osterwalder–Schrader reflection positivity, NOT a transfer-operator
  spectral bound, NOT a mass gap. Makes NO mass-gap / μ>0 / Surface-#1 claim;
  does NOT discharge the `kotecky_preiss_criterion` `sorry`.
- **YM 249 → 250 — polymer entropy bound landed (brick, in BRICKS):**
  `Towers/YM/EntropyBound.lean` lands `polymer_entropy_bound` — an HONEST
  CONDITIONAL COMBINATOR for the missing combinatorial input to KP convergence.
  It states `#{size-n Connected polymers through the origin link} ≤
  polymer_const ^ n` with `polymer_const := 7` (= `2d − 1`, `d = 4`), routed
  through the SINGLE NAMED SURFACE `h_entropy` (the lattice-animal /
  self-avoiding-walk connective-constant bound `μ(ℤ⁴) ≤ 7`, absent from mathlib
  v4.12.0) — a hypothesis, NOT `by sorry`, so NO `sorryAx`. `Connected` is left
  abstract (modeled): without connectivity the count is infinite-in-`L`, so the
  `7^n` bound is FALSE; connectivity is what makes the surface dischargeable.
  `#print axioms polymer_entropy_bound` = classical trio (verified by hand:
  `lake env lean Towers/YM/EntropyBound.lean`, EXIT=0). HONEST: makes NO
  mass-gap / `μ>0` / Surface-#1 claim and does NOT discharge the
  invariant-locked `kotecky_preiss_criterion` sorry; YM stays `Status: Open`.
- **Real SU(3) chordal distance is a genuine metric (brick, in BRICKS):**
  `Towers/YM/RiemannianGeometry.lean` lands `d_SU3_isMetric : IsMetricOnSU3
  d_SU3` — the chordal distance `d_SU3 g h = ‖↑g - ↑h‖_HS` PROVES the full metric
  predicate (pseudo-distance clauses + separation + triangle), routed through
  the genuine L² structure of `EuclideanSpace ℂ (Fin 3 × Fin 3)` via `toEuc`.
  `#print axioms` = classical trio, no `sorry`. HONEST: the CHORDAL metric, NOT
  the Killing-form GEODESIC distance (open — needs the Riemannian exponential /
  cut-locus, absent from mathlib v4.12.0). NO mass-gap / μ>0 / Surface-#1 claim.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (also `[]` on
  `H2_WeilTransfer`, `M9_WeilTransfer_All`). Every landed brick is
  classical-trio-only.
- **Mathlib:** v4.12.0 only.
- **YM Surface #1: OPEN.** No `m > 0` claim while the `sorry` stands.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) elaborates against the
  real Step-4/5 `H` / `spectrum_bound` and carries `(hpos : 0 < wilsonAction U)`,
  but still carries a `sorry`; INVARIANT-LOCKED, NOT in BRICKS, not a lakefile
  root. The companion `YM_mass_gap_nontrivial` discharges `hpos` for
  non-trivial `U` and is `sorry`-free, but `H = wilsonAction U • 𝟙` is the
  scalar shadow, NOT the real Wilson transfer operator — so no mass-gap claim.
- **Registered YM walls** (tagged files, lake-gated `[YM1-*]`, NOT in BRICKS):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572 `[YM1-LB-Real]`
  (`hamiltonian_pos`), 573 `[YM1-GR]` (`gap_reduction`), 575 `[YM1-SB]`
  (`spectrum_bound` + `spectrum_bound_H_iff`). All classical trio.
- **Deferred:** 24 OS/KP modules unregistered (Task #208); `.lean` files kept
  on disk, await Wall 570+/574 with the real SU(3) `H`.
- **Infra:** mathlib cache self-heal landed (`scripts/fetch-mathlib-oleans.sh`:
  authoritative `lake exe cache get`, no from-source fallback).
- **YM Transfer / polymer / positivity / measure scaffolding (NONE bricks, none
  in BRICKS; all classical-trio, verified live; full detail →
  `docs/CHANGELOG.md`).** Real SU(3) Haar stack (`SU3Instances.lean`: `haarSU3`,
  product `haarN`, probability instances); the real integral transfer operator
  `T_L` with the genuine sub-Markov contraction `‖T_L‖ ≤ 1` (`Transfer.lean` —
  explicitly NOT strict / decay / spectral-gap; `S_min := inf_{U≠1} wilsonAction
  U = 0`); Wilson positivity (`WilsonPositivity.lean`: `wilsonAction_nonneg`,
  `wilsonAction_eq_zero_iff` = all-plaquettes-trivial, NOT `U = 1`); and the
  cluster-expansion `polymerActivity` (nonneg, antitone, empty `= 1`, DCT
  reduction `polymerActivity_tendsto_zero_of_null`). Every lemma is
  necessary-not-sufficient: pointwise positivity / single-polymer `β→∞` decay is
  NOT the mass gap. The OPPOSITE spectral lower bound stays OPEN in the
  disclaimed `sorry` `Transfer.kotecky_preiss_criterion` (downstream of one
  unproved cluster-entropy / Peierls counting bound
  `#{γ : |γ|=n, energy<ε} ≤ Cⁿ·ε^{α·n}`), distinct from the invariant-locked
  `Towers/Attempts/ClusterExpansion.lean` `sorry`. NO `m>0` / μ>0 / mass-gap /
  Surface-#1 claim; Surface #1 stays OPEN.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` remains a `sorry` in
  `Towers/Attempts/ClusterExpansion.lean` (invariant-locked).
- **NS FREEZE.** `Towers/NS/*` is FROZEN at the Clay boundary (milestone
  `NS-540-phase6-clay-boundary`). NO further commits to `Towers/NS/` without an
  explicit unfreeze order from the user. Surface #1 (`global_smooth_exists`) and
  Surface #2 (modeled `weak_solution_exists`) stay OPEN; "NS solved" /
  "regularity proven" / "weak solutions exist (literally)" claims are REFUSED.
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

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.
