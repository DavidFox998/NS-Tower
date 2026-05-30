# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **NS Tower 540 Phase 2A/2B COMPLETE** (milestones `NS-540-phase2a-leray`,
  `NS-540-phase2b-stokes`; both on `main` @ checkpoint `f4becd5`). The active
  Phase 1–2 NS chain carries **1 documented `sorry` total**:
  `Towers/NS/FunctionSpaces.lean` (0 sorries), `Towers/NS/Leray.lean`
  (1 — `leray_proj_ker_eq_grad`, the Helmholtz `(divFree)ᗮ = gradSubmodule`
  identification), `Towers/NS/Stokes.lean` (0 — every decl classical-trio,
  zero `sorryAx`, verified live). HONEST scope: these NAME/BOUND operators
  only; NOT bricks, not lakefile roots; NS stays `Status: Open`, Surface #2
  stays OPEN.
  (Milestone tags recorded here as prose, matching this repo's SHA/prose
  versioning convention — see note in "Operational gotchas" on git-tag
  creation being restricted for the main agent.)

- **NS Tower 540 Phase 3 COMPLETE** (milestone `NS-540-phase3-energy` @
  checkpoint `ae85a633`): `Towers/NS/Energy.lean` — the Phase-3 kinetic energy
  functional `energy u t = ‖u t‖²` on `Hdiv_free (s+2)`, with `energy_def`.
  Trio-clean, no `sorryAx`. NOT a brick, not in BRICKS, not a lakefile root;
  NS stays `Status: Open`, Surface #2 OPEN.

- **NS Tower 540 Phase 4A/4B COMPLETE — Galerkin scheme + Aubin–Lions
  combinator (NOT bricks, not in BRICKS, not lakefile roots; both fully
  `sorry`-free / classical-trio, `#print axioms` = trio on every decl,
  verified live):**
  - `Towers/NS/GalerkinApprox.lean` (Phase 4A, imports Energy) — the genuine
    **finite-dimensional Galerkin projection** `galerkinProj K n : Hˢ⁺² →L Kₙ`
    (mathlib `orthogonalProjection` onto the finite-dim `Kₙ`; the
    `HasOrthogonalProjection` instance comes from `FiniteDimensional.complete`,
    supplied as a *local* `haveI` so it never pollutes global instance
    resolution — making the projection genuinely finite-dimensional), plus the
    Galerkin sequence `galerkin_seq K u n t = ↑(Pₙ (u t))` and three a-priori
    bounds: `galerkinProj_norm_le` (`‖Pₙ‖ ≤ 1`), `galerkin_seq_norm_le`
    (`‖uₙ(t)‖ ≤ ‖u(t)‖`, via `Submodule.norm_coe` + `le_opNorm` —
    `Submodule.norm_coe` is essential: the coe-norm `‖↑x‖ = ‖x‖` is NOT
    definitional on the deep `Hdiv_free` Lp-over-`withDensity` stack, so `rfl`
    blows the heartbeat budget), and the headline
    `galerkin_seq_sq_le_energy` (`‖uₙ(t)‖² ≤ energy u t`).
  - `Towers/NS/Compactness.lean` (Phase 4B, imports GalerkinApprox) — the
    compactness layer: `embedToLower` (the bounded, **NON-compact** Sobolev
    inclusion `Hˢ⁺² ↪ Hˢ`), `TendstoLocL2` (**modeled** lower-order
    convergence — an `Hˢ`-norm surrogate for `L²_loc`, NOT literal `L²_loc`),
    and `AubinLionsCriterion` — the genuine Rellich–Kondrachov compactness
    theorem stated as a **NAMED `Prop` HYPOTHESIS, NOT proved and NOT
    `sorry`-ed** (the *compact* embedding it needs is absent from mathlib
    v4.12.0). `galerkin_strong_convergence` is an HONEST combinator: it routes
    the Phase-4A energy bound through the assumed criterion to yield an
    `L²_loc`-surrogate-convergent subsequence; it proves nothing about NS by
    itself. `galerkin_seq_energy_bounded` re-exports the Phase-4A bound.
  - HONEST scope: these build the approximation scheme + its a-priori bound and
    NAME the compactness input; they prove **NO** NS
    existence/uniqueness/regularity result and **NO** convergence of the full
    sequence. NS tower stays `Status: Open`; Surface #2 stays OPEN; YM
    untouched.

- **Wall:** 550 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`). The
  source of truth for the count is the script, not this file.
- **Real SU(3) chordal distance is a genuine metric (NEW brick, in BRICKS):**
  `Towers/YM/RiemannianGeometry.lean` now lands `d_SU3_isMetric :
  IsMetricOnSU3 d_SU3` — the Task #189 chordal distance `d_SU3 g h =
  ‖↑g - ↑h‖_HS` PROVES the full metric predicate (the three pseudo-distance
  clauses + separation `d g h = 0 → g = h` + triangle `d g h ≤ d g k + d k h`).
  Proof routes `hsNormSq` through the genuine L² structure of
  `EuclideanSpace ℂ (Fin 3 × Fin 3)` via the linear embedding `toEuc`
  (`sqrt_hsNormSq_eq_norm : √(hsNormSq M) = ‖toEuc M‖`): separation is
  `norm_eq_zero` + `toEuc`/coercion injectivity, triangle is the ambient
  `dist_triangle`. `#print axioms` = classical trio (verified live), no `sorry`.
  HONEST scope: this is the CHORDAL metric, NOT the Killing-form GEODESIC
  distance (still open — needs the Riemannian exponential / cut-locus, absent
  from mathlib v4.12.0). Makes NO mass-gap / μ>0 / Surface-#1 claim; YM stays
  `Status: Open`.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (`#print axioms`
  returns `[]`; also `[]` on `H2_WeilTransfer` and `M9_WeilTransfer_All`).
  Every landed brick is classical-trio-only.
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
- **Honest measure infra (NOT a brick, not in BRICKS):**
  `Towers/YM/SU3Instances.lean` carries the real `SU(3)` instance stack
  (`Group` / `TopologicalGroup` / `CompactSpace` / `BorelSpace`), `haarSU3 =
  haarMeasure ⊤`, and now `haarN n := Measure.pi (fun _ : Fin n => haarSU3)` —
  the product Haar measure on `Fin n → SU(3)` link configurations — plus
  `IsProbabilityMeasure` instances for both. `#print axioms` on `haarSU3` /
  `haarN` = classical trio (`[propext, Classical.choice, Quot.sound]`), verified
  live. This is measure-theoretic scaffolding ONLY: built on the *real* Haar
  measure (NOT the Dirac stand-in), but it makes **no** `m > 0` / mass-gap /
  `μ > 0` claim and does **not** touch Surface #1 (stays OPEN).
- **Real integral transfer operator `T_L` (NOT a brick, not in BRICKS):**
  `Towers/YM/Transfer.lean` now carries a `sorry`-free `noncomputable def T_L
  (L β) : Lp ℝ 2 (haarN (4·L⁴)) → Lp ℝ 2 (haarN (4·L⁴))`, the genuine integral
  operator `(T_L f)(U) = ∫ V, exp(-β·wilsonAction(V⁻¹·U))·f(V) d(haarN)` — a real
  heat kernel over the *real* product Haar measure built from the *real* SU(3)
  Wilson action (via `linkEquiv`/`toGauge`, continuity + `Memℒp` proofs). `#print
  axioms T_L` = classical trio (no `sorryAx`), verified live. Makes **no**
  spectral / mass-gap / `m > 0` claim; Surface #1 stays OPEN; YM stays
  `Status: Open`. The companion `Transfer.transfer_operator_norm_le` is now
  **TIGHTENED** to the genuine sub-Markov **contraction** (it was an `exp(a·β)`
  growth bound): `∀ β > 0, ∀ f, ‖T_L L β f‖ ≤ ‖f‖` — i.e. `‖T_L‖ ≤ 1`.
  `sorry`-free, classical-trio only (`#print axioms` = trio, verified live).
  Proof: the heat kernel `exp(-β·actL) ≤ 1` because `actL ≥ 0`
  (`Transfer.actL_nonneg ← WilsonPositivity.wilsonAction_nonneg`), then
  `L¹ ≤ L²` on the probability measure `haarN`. It is explicitly **NOT** a
  *strict* contraction, decay, spectral-gap, or mass-gap claim: only
  `‖T_L‖ ≤ 1` is proved (no equality / tightness claim — constants are
  eigenfunctions with eigenvalue `Z(β) = ∫ exp(-β·actL) ≤ 1`, so `T_L` does
  **not** contract the vacuum sector to `0`), and
  `S_min := inf_{U ≠ 1} wilsonAction U = 0` (the action is continuous and
  vanishes at the vacuum), so no `exp(-β·S_min)` decay holds. The genuine mass gap would be the OPPOSITE inequality — a
  spectral *lower* bound `T_L ≥ c·𝟙` on the zero-mean sector — and stays OPEN
  in the NEW `Transfer.kotecky_preiss_criterion`, a **disclaimed
  single-`sorry` placeholder** (own namespace `…YM.Transfer`, reports `sorryAx`,
  NOT a brick): `∃ β₀ > 0, ∀ β > β₀, ∃ gap > 0, ∀ L f, (∫ f d(haarN) = 0) →
  ‖T_L L β f‖ ≤ exp(-(β·gap))·‖f‖`. OPEN — it does NOT close Surface #1, does
  NOT prove the mass gap, and does NOT touch the invariant-locked
  `kotecky_preiss_criterion` `sorry` in `Towers/Attempts/ClusterExpansion.lean`.
- **Honest positivity scaffolding (NOT bricks, not in BRICKS):**
  `Towers/YM/WilsonPositivity.lean` adds `wilsonAction_nonneg`,
  `plaquetteEnergy_eq_zero_iff`, and `wilsonAction_eq_zero_iff` — the LAST
  states `wilsonAction U = 0 ↔ ∀ x μ ν, wilsonPlaquette U x μ ν = 1` (all
  plaquettes trivial), HONESTLY **NOT** `↔ U = 1`. Plus a polymer-energy
  functional `polymerEnergy` with `polymerEnergy_nonneg` and
  `polymerEnergy_pos_of_nontrivial` (the latter needs an explicit
  non-trivial-plaquette hypothesis). `Transfer.actL_nonneg` lifts
  `wilsonAction_nonneg` through `toGauge`. All classical-trio, verified live;
  every lemma is *necessary-not-sufficient* — pointwise positivity is NOT a
  uniform spectral gap, since the off-vacuum infimum of `wilsonAction` is `0`.
- **Polymer-activity scaffolding (NOT bricks, not in BRICKS):**
  `Towers/YM/Transfer.lean` adds the cluster-expansion *activity* functional
  `polymerActivity L β γ := ∫ w, exp(-β·polymerEnergy (toGauge w) γ) d(haarN)`
  (real `polymerEnergy`, real product Haar `haarN`), with `sorry`-free,
  classical-trio (`#print axioms` = trio, verified live) companions:
  `polymerActivity_nonneg` (`integral_nonneg`), `integrable_polymerWeight`
  (continuity on the compact config space ⇒ bounded ⇒ `L¹`), `polymerActivity_empty`
  (`= 1` for `γ = ∅`, the one *proven* value), and `polymerActivity_antitone_in_beta`
  (`β₁ ≤ β₂ ⟹ activity β₂ ≤ activity β₁`, from `polymerEnergy ≥ 0`). HONEST
  scope: nonneg + antitone are *necessary-not-sufficient* — NO convergence,
  decay, spectral gap, or `m > 0`. The `β → ∞` limit is `haarN {polymerEnergy =
  0}`; this file asserts **neither** that it is `0` nor that it is positive (for
  non-empty `γ` the trivial-plaquette set is a positive-codimension, plausibly
  Haar-null subvariety). KP convergence needs a uniform SUM over *connected /
  truncated* weights — the OPEN content of `Transfer.kotecky_preiss_criterion`,
  which stays a disclaimed `sorry` (UNTOUCHED). Surface #1 stays OPEN.
- **Single-polymer activity decay — honest DCT reduction (1 brick-grade
  trio-clean lemma + 2 disclaimed OPEN `sorry`s, NONE in BRICKS):**
  `Towers/YM/Transfer.lean` now factors the integral route into its *proven*
  and its *open* halves.
  - `continuous_polymerEnergy_toGauge` (NEW, trio-clean): the per-config map
    `w ↦ polymerEnergy (toGauge L w) γ` is continuous (factored out of
    `integrable_polymerWeight`, which now calls it).
  - `polymerActivity_tendsto_zero_of_null` (NEW, **`sorry`-free, classical
    trio**, verified live): the genuine, fully-proved content of the integral
    route — *IF* `haarN {w | polymerEnergy (toGauge L w) γ = 0} = 0` *THEN*
    `polymerActivity L β γ → 0` as `β → ∞`. Proof = dominated convergence
    (`tendsto_integral_filter_of_dominated_convergence`): the heat weight
    `exp(-β·polymerEnergy) → 𝟙[polymerEnergy = 0]` pointwise (`exp_zero` on the
    null set; `Real.tendsto_exp_atBot ∘ const_mul_atTop_of_neg` off it),
    dominated by the constant `1` (integrable on the probability measure
    `haarN`), so the limit integral is `(haarN {…=0}).toReal = 0`.
  - `trivial_polymer_set_null` (NEW, **disclaimed OPEN `sorry`**, reports
    `sorryAx`, NOT a brick): for `γ ≠ ∅`, `haarN {…polymerEnergy = 0} = 0`.
    TRUE but a genuine measure-theoretic theorem, not a short trio proof:
    needs `NoAtoms haarSU3` (only via `IsHaarMeasure.noAtoms`, requiring the
    identity non-isolated, unproved here) PLUS a `Measure.pi` single-coordinate
    marginal argument (`NoAtoms` alone kills only *countable* sets; the trivial
    set is an *uncountable* positive-codim subvariety). The naive
    "codimension `8·|γ|`" count is **lattice-size dependent**: on `L = 1` a
    plaquette degenerates to a commutator `[g,h]`, so the triviality set is the
    *commuting variety* and the four plaquette links are NOT four freely-varying
    coordinates — needs the harder regular-element analysis. Left OPEN.
  - `polymerActivity_tendsto_zero` (NEW, OPEN, inherits `sorryAx` from
    `trivial_polymer_set_null`, NOT a brick): `γ ≠ ∅ ⟹ polymerActivity L β γ →
    0`. Just the trio-clean DCT reduction fed the OPEN null-set input.
  - **Why this is NOT the mass gap (the finite-`β₀` point):** even the full
    `polymerActivity_tendsto_zero` is a **single** polymer's `β → ∞` limit.
    Kotecký–Preiss is strictly stronger and different in kind — a *uniform*
    convergent SUM `∑_{γ ∋ 0} |z(γ)| e^{|γ|} < ∞` at a **finite** `β₀ < ∞` over
    *connected / truncated* weights — driven by "few small-energy polymers at
    large-but-finite `β`", NOT by any single activity's `β → ∞` limit, and NOT
    by `inf_{U≠1} wilsonAction U > 0` (that infimum is `0`). So
    `kotecky_preiss_criterion` stays a disclaimed OPEN `sorry` (UNTOUCHED), no
    Surface #1 closure, YM stays `Status: Open`, no `m > 0` / mass-gap claim.
  - **The single missing combinatorial input (Surface #1 = Clay), now
    documented in the `Transfer.kotecky_preiss_criterion` docstring.** KP
    convergence is downstream of ONE unproved cluster-entropy / Peierls
    polymer-counting bound: `#{γ : |γ| = n, energy(γ) < ε} ≤ Cⁿ · ε^(α·n)`
    (constants `C, α > 0`). That estimate is exactly what beats the geometric
    `Cⁿ` entropy against the suppressed activity `|z(γ)| ≲ exp(-β·energy(γ))`
    to force `∑_{γ ∋ 0} |z(γ)| e^{|γ|} < ∞` at **finite** `β₀`. It is the sole
    dependency of `kotecky_preiss_criterion` and is genuine open combinatorics —
    NOT proved, NOT attempted (per direction: do not attempt without the
    counting estimate). Surface #1 stays OPEN.

- **NS Tower 540, Phase 1: Function Spaces (NOT a brick, not in BRICKS, not a
  lakefile root):** `Towers/NS/FunctionSpaces.lean` models Hˢ honestly on the
  Fourier side as the weighted `L²(ℝ³, ⟨ξ⟩^{2s}·vol; ℂ³)` space
  `Hsv s := Lp (EuclideanSpace ℂ (Fin 3)) 2 (mu s)` (`mu s =
  volume.withDensity ⟨ξ⟩^{2s}`), with the divergence-free condition
  `IsDivFree f := ∀ᵐ ξ, ⟪toVal ξ, f ξ⟫_ℂ = 0` (the Hermitian inner product
  equals the bilinear `ξ·û` because `toVal ξ` has real, conjugation-fixed
  components). `divFreeSubmodule s : Submodule ℂ (Hsv s)` has **PROVED**
  `0/+/•` closure (via `Lp.coeFn_*` + `inner_{zero,add,smul}_right`), and
  `Hdiv_free s` carries the real `NormedAddCommGroup` / `InnerProductSpace ℂ` /
  `CompleteSpace` instances mathlib gives. **NOW `sorry`-free** (the 2 former
  Clay-adjacent `sorry`s are closed): `divFreeSubmodule_isClosed` (the div-free
  set is `L²`-closed) is PROVED by sequential closedness — `L²` convergence ⇒
  convergence in measure (`tendstoInMeasure_of_tendsto_Lp`) ⇒ a.e.-convergent
  subsequence (`TendstoInMeasure.exists_seq_tendsto_ae`; neither needs `μ_s`
  finite, so it works for the infinite weighted measure) ⇒ the linear constraint
  passes to the pointwise limit; and `embed` (the `Hˢ ↪ Hˢ'` Sobolev inclusion
  for `s' ≤ s`) is PROVED via weight monotonicity (`weight_mono` ⇒ `mu_mono :
  μ_{s'} ≤ μ_s`) + `Memℒp.mono_measure`, a bounded inclusion of operator norm
  `≤ 1` (`eLpNorm_mono_measure`), div-freeness transferred a.e. (`μ_{s'} ≪
  μ_s`). `#print axioms` on `divFreeSubmodule_isClosed` / `embed` = classical
  trio `[propext, Classical.choice, Quot.sound]` (no `sorryAx`, verified live);
  compiles exit 0 under `lake env lean` with no warnings. HONEST scope: `embed`
  is the bounded INCLUSION, **not** a compact (Rellich–Kondrachov) embedding.
  Still NOT a brick / not in BRICKS / not a lakefile root; makes **no** NS
  existence/uniqueness/regularity claim; NS tower stays `Status: Open`, Surface
  #2 stays OPEN.
- **NS Tower 540, Phase 2: Leray projection + Stokes operator (NOT bricks, not
  in BRICKS, not lakefile roots; two INDEPENDENT files — Stokes does NOT import
  Leray, each imports only Phase-1 `FunctionSpaces`):**
  - `Towers/NS/Leray.lean` — the Leray/Helmholtz orthogonal projection
    `leray_proj : Hˢ →L[ℂ] Hdiv_free s` (mathlib `orthogonalProjection` onto the
    PROVED-closed `divFreeSubmodule`). `sorry`-free + classical-trio (verified
    live): `leray_projE_idempotent` (`P² = P`), `leray_proj_norm_le`
    (`‖Pu‖ ≤ ‖u‖`), `leray_proj_apply_eq_self_of_mem`, `leray_proj_ker`,
    `gradSubmodule`. Exactly ONE documented `sorry` = `leray_proj_ker_eq_grad`
    (the Helmholtz identification `(divFreeSubmodule)ᗮ = gradSubmodule`); NOT a
    brick.
  - `Towers/NS/Stokes.lean` — the Stokes operator `stokes_op = -PΔ :
    Hdiv_free (s+2) →L[ℂ] Hdiv_free s` as the `‖ξ‖²` Fourier multiplier. **NOW
    FULLY `sorry`-free + classical-trio (the former lone `stokes_eLpNorm_le`
    `sorry` is CLOSED)** — `#print axioms` returns the classical trio on EVERY
    declaration, including the operator `stokes_op` and the bound
    `stokes_op_norm_le` (verified live). NOT a brick / not a lakefile root.
    - **The closed lift:** `stokes_eLpNorm_le` (`‖ξ‖²•û` has `L²(μ_s)`-norm `≤`
      the `L²(μ_{s+2})`-norm of `û`) is genuinely PROVED. Route: both `eLpNorm`s
      → `(∫⁻ ‖·‖₊²)^{1/2}` (`eLpNorm_eq_lintegral_rpow_nnnorm`), pushed onto
      `volume` via `lintegral_withDensity_eq_lintegral_mul₀'`, then compared
      pointwise by the NEW helper `stokes_weight_pointwise` (the `ℝ≥0∞`
      repackaging `weight s ξ · ‖stokesSymbol ξ‖₊² ≤ weight (s+2) ξ` of the real
      `symbol_pow_weight_le`). `ENNReal`/`rpow` plumbing only, no new math.
    - **Also `sorry`-free + classical-trio (as before):** `symbol_pow_weight_le`
      (the `-Δ` symbol/weight estimate `‖ξ‖⁴·⟨ξ⟩^{2s} ≤ ⟨ξ⟩^{2(s+2)}`),
      `stokesSymbol_re_nonneg`, `continuous_stokesSymbol`,
      `stokes_aestronglyMeasurable`.
    - **The operator declarations are now trio-clean (NO `sorryAx`):**
      `stokesMemℒp`, `stokesₗ`, `stokes_mult`, `stokes_op`,
      `stokes_preserves_divFree`, `stokes_mult_norm_le`, `stokes_op_norm_le`
      (the `‖A u‖ ≤ ‖u‖` bound) — the genuine operator (linear,
      div-free-preserving, contractive), no longer provisional.
    HONEST scope: it NAMES and BOUNDS the operator —
    NO self-adjointness / sectoriality / analytic-semigroup claim (that theory
    is absent from mathlib v4.12.0; deliberately NOT fabricated as sorries).
  - Both compile `lake env lean` exit 0. These build spaces and name/bound
    operators; they prove **no** NS existence/uniqueness/regularity result. NS
    tower stays `Status: Open`; Surface #2 stays OPEN.

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
