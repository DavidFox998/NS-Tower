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

- **Wall:** BRICKS array in `scripts/check-towers.sh` (`${#BRICKS[@]}`) is the
  source of truth for the count, not this file.
- **Wall262a_RatioModel — HONEST standalone numeric MODEL of "Theoria's" richer
  R-series (bricks, in BRICKS):** `Towers/YM/Wall262a_RatioModel.lean` (namespace
  `Wall262a`). The HONEST version of Theoria's fuller `R(a) = 1 − ∑ Hₙaⁿ⁻¹/n!`
  writeup: it keeps Theoria's H4/120-cell/`2,3,5` narrative as DOCUMENTATION but
  machine-checks only a concrete finite numeric MODEL. **A STANDALONE LEAF —
  imports only `Mathlib`, nothing imports it, OUT of the YM dependency graph.**
  **GENUINE/UNCONDITIONAL:** `Hweight` (the four INVENTED H4 ratio weights
  `1,2,3/2,2` at `n=2..5`, `0` beyond), `term`, the coherent 4-term
  `R a = 1 − (a/2 + a²/3 + a³/16 + a⁴/60)`; `Hweight_values`, `Hweight_nonneg`,
  `term_nonneg`; `R_le_one_sub_half` (`0≤a ⟹ R a ≤ 1−a/2`, the HONEST
  drop-the-nonneg-tail reduction); `exp_neg88_lower` (`257/1000 ≤ exp(−0.88)`, via
  `exp 0.88 ≤ exp 1 < 2.7182818286` then invert; `257/1000` is the exact
  break-even of `1−a/2 = 1743/2000`); `R_le` (the headline `R(exp(−0.88)) ≤
  1743/2000`, margin huge — true `R ≈ 0.73`). Honest prime-structure record:
  `factorial_smooth` (`2!,3!,4!,5!` all 5-smooth `= 2,2·3,2³·3,2³·3·5`),
  `seven_enters_at_seven` (`7! = 2⁴·3²·5·7` — the entropy prime `7` enters only
  BEYOND the truncation, so the 5-smoothness is a truncation artifact),
  `threshold_factorization` (`1743 = 3·7·83`, `2000 = 2⁴·5³`). 9 public theorems;
  all `sorry`-free, `#print axioms` = classical trio (the three ℕ-arithmetic ones
  only `propext`; verified live, raw `lean` v4.12.0, EXIT=0). **DOCUMENTARY ONLY +
  Theoria errors FLAGGED:** the H4 Coxeter matrix `M_H4`, the 120-cell, `h=30`,
  exponents `1,11,19,29`, `φ` as highest-root norm are NOT in mathlib v4.12.0
  (`CoxeterGroup.H4.spectral_radius`/`.subgraph_count`/`.highest_root_norm` do NOT
  exist); Theoria's "largest eigenvalue of `2I−M_H4` = `φ`" is FALSE (it is
  `2cos(π/30)≈1.989`; `φ` is NOT an eigenvalue — see `Wall263`); Theoria's
  alternating-sign / `R≤0.6665` arithmetic is incoherent (coherent value ≈0.73).
  HONEST: a standalone numeric MODEL with INVENTED weights; does **NOT** discharge
  `Wall262`'s open `hR` (the real `R := μ_ℤ⁴/φ` is research-level, not a 4-term
  sum); uses NO real Coxeter/H4 datum; proves NO YM result; discharges no open
  surface. YM stays `Status: Open`.
- **Wall263_CoxeterSpectral — HONEST REFUTATION of "largest eigenvalue of
  2I−M_H4 = φ", axiom-free (bricks, in BRICKS):**
  `Towers/YM/Wall263_CoxeterSpectral.lean` (namespace `Wall263`). The honest
  response to the proposal to restate Wall261 via the H4 Coxeter/Cartan matrix
  `M_H4 = !![2,-1,0,0;-1,2,-1,0;0,-1,2,-φ;0,0,-φ,2]` with the requested theorem
  "largest eigenvalue of `B := 2I−M_H4` equals `φ = 2cos(π/5)`" — that claim is
  FALSE and this file machine-checks why WITHOUT introducing any Lean `axiom`
  (the user's proposed code used one; classical trio preserved). `B` is the
  weighted path `!![0,1,0,0;1,0,1,0;0,1,0,φ;0,0,φ,0]` with edge weights `1,1,φ`,
  so **`φ` is the label-`5` EDGE WEIGHT (an entry of the matrix), NOT a spectral
  quantity. GENUINE/UNCONDITIONAL:** `coxeterCharpoly` (the char poly
  `det(λI−B) = λ⁴−(2+φ²)λ²+φ²` via the symmetric-tridiagonal determinant
  recursion); `coxeterCharpoly_phi` (value at `λ=φ` is `−φ²`, a pure `ring`
  fact — the `φ⁴` cancels `φ²·φ²` identically, the golden-ratio identity is not
  even invoked); `phi_not_root` (`φ` is NOT a root of `coxeterCharpoly`, the
  hand-computed char poly — machine-checked as `coxeterCharpoly φ ≠ 0`; the
  eigenvalue-level reading "hence not an eigenvalue, a fortiori not the largest"
  is DOCUMENTARY, modulo the hand computation, since mathlib v4.12.0 has no
  `det_fin_four`/charpoly↔eigenvalue bridge so `B`/det/eigenvalues are NOT
  formalized); `phi_lt_two` (`φ<2` — only `φ<2` is machine-checked; documentary
  context: the true spectral radius `2cos(π/30)≈1.989 ∈ (φ,2)`; NO false
  "degree-`≥2 ⟹` radius-`≥2`" claim — the A₄ path refutes that); `one_lt_phi`
  (`1<φ`). The actual largest eigenvalue is `2cos(π/30)≈1.989` (H4 Coxeter number
  `h=30`, Perron eigenvalue `2cos(π/h)`), NOT `φ≈1.618` (which is λ_max of the
  UNWEIGHTED A₄ path — a different matrix, documented only).
  **CONDITIONAL (NAMED OPEN hyps, NOT axioms/sorry):** `defect_bound_H4` — the
  faithful transcription of `apply KP_theorem_weighted H4_spectral_bound` over
  two ordinary Lean hypotheses `h_spec` (`EffDeg x ≤ φ`, the unproven leap; the
  real KP constant is the connective constant `≥ 6`, not `φ`) and `h_kp` (the
  weighted-KP combinator). 5 public theorems; all `sorry`-free, `#print axioms`
  = classical trio (verified live, raw `lean` v4.12.0, EXIT=0). HONEST: proves
  NO YM result — it REFUTES the proposed eigenvalue identity and records the
  honest reduction; makes NO mass-gap / μ>0 / Surface-#1 claim, does NOT touch
  `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall262_ConnectiveRatio — HONEST CONDITIONAL connective-ratio defect bound →
  SU(2) polymer-rate win (bricks, in BRICKS):**
  `Towers/YM/Wall262_ConnectiveRatio.lean` (namespace `Wall262`). Sequel to
  `Wall261_H4Defect`. Encodes the requested "ratio of two expansion rates"
  `R := μ_Z4 / φ` (`μ_Z4` the ℤ⁴ plaquette connective constant, ABSTRACT; `φ` the
  H4 rate `(1+√5)/2`, reused from `Wall261.phi`) and lands BOTH requested
  theorems over ONE genuine arithmetic core: the cluster/Ursell `defect_bound`
  (here the NAMED OPEN `h_defect : Defect ≤ log(1 + φ·R)`) and `su2_wins`
  (`log 7 < I_E − Defect`, the polymer rate `I_polymer = I_E − Defect` clearing
  the bare entropy threshold `log 7`). **GENUINE/UNCONDITIONAL:** `phi_lt`
  (`φ < 32361/20000 = 1.61805`, from `√5 < 2.2361`); `exp_lower`
  (`12053/5000 ≤ e^{0.88}`, i.e. `2.4106 ≤ e^0.88` (true `2.41090`), via the
  degree-7 Taylor remainder `Real.exp_bound` — a degree-2 bound gives only
  `2.2672` and a degree-6 only `2.4094 < 2.41013`, so order 7 is genuinely
  required for the margin); `defect_bound_arith` (`0 ≤ R ≤ 1743/2000 ⟹
  log(1 + φ·R) < 22/25`, via `Real.log_lt_iff_lt_exp` then
  `1 + φ·R < 12053/5000 ≤ e^{0.88}`); `threshold_factorization`
  (`1743 = 3·7·83`, `2000 = 2^4·5^3` — the honest record that `0.8715 = 1743/2000`
  is a TERMINATING rational; the "endless 9s" reading was floating-point noise).
  **CONDITIONAL (h_defect/h_rate/hR — hypotheses, NOT axioms):** `defect_lt`
  (from `h_defect` + `R ≤ 1743/2000`, `Defect < 22/25`); `su2_wins` (additionally
  `h_rate : log 7 + 22/25 ≤ I_E`, the SU(2) large-deviation rate clearing the
  defect-raised threshold — same family as Wall256/258/259 — ⟹
  `log 7 < I_E − Defect`). 6 public theorems; all `sorry`-free, `#print axioms` =
  classical trio (`threshold_factorization` only `propext`; verified live, raw
  `lean` v4.12.0, EXIT=0). HONEST: proves NO YM result — a REDUCTION/IMPROVEMENT
  in the Wall259/260/261 family. `R`, `Defect`, `I_E`, `μ_Z4` are abstract reals;
  `hR : R ≤ 1743/2000` (the ρ<1 ratio test), `h_defect` (cluster/Ursell bound),
  and `h_rate` (genuine SU(2) rate) are all NAMED OPEN hypotheses proved NOWHERE.
  NO numeric `μ_Z4` is asserted — the real plaquette connective constant `≈ 3`
  gives `R > 1` and FAILS `hR`, so the bound stays abstract precisely because it
  is not established for the real model. The Ursell power series is NOT encoded
  (`0.8715` is the reverse-engineered break-even of `log(1+φ·R) = 0.88`, not a
  series output). Makes NO mass-gap / μ>0 / Surface-#1 / RH / BSD claim,
  discharges NO open surface, does NOT touch `kotecky_preiss_criterion`. YM stays
  `Status: Open`.
- **Wall261_H4Defect — HONEST CONDITIONAL H4 / 120-cell defect improvement
  (bricks, in BRICKS):** `Towers/YM/Wall261_H4Defect.lean` (namespace `Wall261`).
  Sequel to `Wall260_ClayReduction`: where Wall260 pins the ℤ⁴ link incidence
  `C = 6` (threshold `log 42`), this records the H4 improvement
  `C = 1 + φ = φ² ≈ 2.618` (threshold `log(7·(1+φ)) ≈ log 18.33 < log 42`), the
  margin `ε > 0` coming from the ℤ⁴-vs-H4 graph comparison. `φ := (1 + √5)/2`.
  **GENUINE/UNCONDITIONAL:** `phi_sq_eq` (`φ² = φ + 1`, the golden-ratio identity
  ⇒ `1 + φ = φ²`); `one_add_phi_lt_six` (`1 + φ < 6`, H4 constant strictly below
  the ℤ⁴ incidence); `graph_gap_pos` (`0 < log 6 − log(1+φ)`, the honest
  CONSTANT-level positive gap — the realization that "`ε > 0` comes from the graph
  comparison"); `h4_threshold_lt_z4` (`log(7·(1+φ)) < log 42`). **CONDITIONAL
  (h_rate mechanism — hypotheses, NOT axioms):** `h4_defect_beats_z4` (from the
  NAMED OPEN `h_graph : Defect ≤ log(1+φ) − ε`, `ε > 0`, conclude `Defect <
  log 6`); `h4_clay_reduction` (feeds the NAMED OPEN H4 defect bound `∀ x, I_E x −
  I_polymer x ≤ log(1+φ) − ε` and the H4-threshold rate through
  `Wall260.new_clay_reduction` at `C = 1+φ` ⟹ `∀ x, log 7 < I_polymer x`). 6
  registered public theorems; all `sorry`-free, `#print axioms` = classical trio
  (verified live, raw `lean` v4.12.0, EXIT=0). HONEST: does NOT prove the real H4
  spectral gap `λ₂ = φ` (no 120-cell adjacency spectrum in mathlib v4.12.0; `φ`
  enters ONLY as the real `(1+√5)/2`), does NOT prove the real dependence defect
  (`Defect` abstract; the H4 defect bound is a NAMED OPEN hypothesis, proved
  nowhere). A REDUCTION/IMPROVEMENT, NOT a proof — proves NO Clay result,
  discharges NO open surface, constructs NO real SU(N) rate functional. Makes NO
  mass-gap / μ>0 / Surface-#1 claim, does NOT touch `kotecky_preiss_criterion`.
  YM stays `Status: Open`.
- **Wall260_ClayReduction — HONEST CONDITIONAL Clay reduction (pointwise defect
  form) (bricks, in BRICKS):** `Towers/YM/Wall260_ClayReduction.lean` (namespace
  `Wall260`). The pointwise-function version of the dependence-defect reduction,
  split as requested: **`C = 6` is COMBINATORICS, `h_defect` is ANALYSIS.**
  **GENUINE/UNCONDITIONAL:** `C_Z4 := 6 : ℕ`; `link_incidence_number_4d`
  (`Wall258.linkIncidence 4 = C_Z4`, NO axioms at all, reuses `linkIncidence_four`);
  `threshold_split` (`log(7·C) = log 7 + log C` for `C > 0`); `new_clay_reduction`
  (from the NAMED OPEN defect bound `h_defect : ∀ x, I_E x − I_polymer x ≤ log C`
  over rate FUNCTIONS `I_E, I_polymer : ℝ → ℝ` and `h_rate : ∀ x, log(7·C) < I_E x`,
  conclude `∀ x, log 7 < I_polymer x`); `new_clay_reduction_Z4` (`C = 6`, threshold
  `log(7·6) = log 42 ≈ 3.73767`). `h_defect`/`h_rate` are HYPOTHESES, NOT
  `axiom`/`by sorry` — so NO `sorryAx` and no new axioms. 4 public theorems; all
  `sorry`-free, `#print axioms` = classical trio (`link_incidence_number_4d` = no
  axioms; verified live, raw `lean` v4.12.0, EXIT=0). HONEST: a REDUCTION, NOT a
  proof — despite the name it proves NO part of the Clay problem, discharges NO
  open surface, constructs NO real SU(N) rate functional (`I_E`, `I_polymer`
  abstract); `h_defect` is the NAMED OPEN cluster-expansion / Dobrushin dependence
  input, proved nowhere. `C = 6` is the ℤ⁴ honest constant (threshold `log 42`); a
  smaller `C` (H4/120-cell spectral gap `1 + λ₂ ≈ 2.618`, threshold ≈ `log 18.33`)
  is a DIFFERENT geometry, deferred. Makes NO mass-gap / μ>0 / Surface-#1 claim,
  does NOT touch `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall259_DependenceBound — HONEST CONDITIONAL dependence-defect REDUCTION
  (bricks, in BRICKS):** `Towers/YM/Wall259_DependenceBound.lean` (namespace
  `Wall259`). The honest conditional version of the "dependence defect" reduction:
  it makes the decomposition a FIRST-CLASS object `polymerRate I_E Defect :=
  I_E − Defect` (`I_polymer = I_E − Defect`: the genuine per-polymer rate equals
  the single-site rate minus the inter-polymer dependence defect) and records the
  reduction "single-site bound ⇒ polymer-rate criterion" as a clean conditional
  combinator. **GENUINE/UNCONDITIONAL:** `polymerRate_eq` (the decomposition
  identity, by `rfl`), `defect_eq` (dual reading `Defect = I_E − I_polymer`),
  `polymer_criterion_of_single_site` (`log 7 + Defect < I_E ⟹ log 7 < I_polymer`),
  `polymer_criterion_of_threshold` (`Defect ≤ log C ∧ log(7·C) < I_E ⟹
  log 7 < I_polymer`, via `log(7·C)=log7+log C`). **CONDITIONAL:**
  `dependence_bound_kp_summable` routes the genuine `EntropyBound` polymer count
  weighted by `exp(−I_polymer)ⁿ` through `Wall256Rate.kp_polymer_rate_summable`,
  CONDITIONAL on the NAMED OPEN hypotheses `h_entropy` (connective-constant count),
  `h_defect : Defect ≤ log C` (the cluster-expansion convergence input) and
  `h_rate : log(7·C) < I_E` (the genuine SU(N) large-deviation rate) — all
  HYPOTHESES, NOT `axiom`/`by sorry`, so NO `sorryAx` and no new axioms. 5 public
  theorems; all `sorry`-free, `#print axioms` = classical trio (verified live, raw
  `lean` v4.12.0, EXIT=0). HONEST: this is a REDUCTION, NOT a proof — `I_polymer`
  is the DEFINED surrogate `I_E − Defect`, NOT a constructed SU(N) polymer-rate
  functional; `Defect ≤ log C` is a NAMED OPEN hypothesis NOT a Lean `axiom`,
  proved nowhere. Establishes NO KP convergence, makes NO mass-gap / μ>0 /
  Surface-#1 claim, discharges NO open surface, does NOT touch
  `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall257_RateLowerBound — HONEST MODELED single-site rate that clears the
  entropy threshold (bricks, in BRICKS):**
  `Towers/YM/Wall257_RateLowerBound.lean` (namespace `Wall257Rate`; the `Wall257`
  namespace is taken by `Wall257_StrongCoupling`). Exhibits a CONCRETE rate `I_E`
  clearing `log 7`, but for a MODELED single-site cgf `cgfModel t := t²`, NOT the
  SU(N) plaquette log-MGF. **GENUINE/UNCONDITIONAL:** `bddAbove_slopes` (the
  Legendre slope family `t·x−t²` is bounded above by `x²/4` via `(t−x/2)²≥0`),
  `quarter_sq_le_I_E` (`x²/4 ≤ I_E x`, from `Wall256Rate.le_rateFn` at the optimal
  slope `t=x/2`), `I_E_unbounded` (`∀ M, ∃ x₀, M < I_E x₀` — the modeled rate
  clears ANY bar), `exists_rate_gt_log_seven` (`∃ x₀, log 7 < I_E x₀`),
  `rate_gap_single_site_vs_polymer` (the Gap Lemma `∃ iE iP, log7<iE ∧ ¬log7<iP`:
  clearing `log 7` at one site is NOT the polymer rate clearing it; reuses
  `Wall256Rate.mean_rate_fails_criterion`). 5 public theorems; all `sorry`-free,
  `#print axioms` = classical trio (verified live, raw `lean` v4.12.0, EXIT=0).
  HONEST: `cgfModel` is a MODELED Gaussian-type cgf whose Legendre transform
  `x²/4` clears any threshold — the model proves NOTHING about the real SU(N)
  rate (needs Cramér/Varadhan + the SU(N) character integral, absent from mathlib
  v4.12.0). Establishes NO KP convergence, makes NO mass-gap / μ>0 / Surface-#1
  claim, does NOT discharge `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall258_DependenceDefect — HONEST CONDITIONAL inter-polymer dependence-defect
  combinator (bricks, in BRICKS):** `Towers/YM/Wall258_DependenceDefect.lean`
  (namespace `Wall258`). Polymers sharing a lattice link are NOT independent;
  passing from a single-site rate `I_E` to the polymer rate costs a defect `D`, so
  the effective rate is `I_E−D` and beating the `7ⁿ` entropy needs the single-site
  rate to clear the RAISED threshold `log(7·C)`. **GENUINE/UNCONDITIONAL:**
  `linkIncidence_four` (`2(d−1)=6` at `d=4`, the ℤ⁴ link incidence; by `decide`),
  `rate_clears_after_defect` (`D≤log C ∧ log(7·C)<iE ⟹ log7<iE−D`, via
  `log(7·C)=log7+log C`), `threshold_mono` (`log(7·C)` strictly increasing in `C`
  — the requested "lower the numbers" lever; pins that below `log 42` needs `C<6`,
  which ℤ⁴ does NOT provide — each link lies in exactly `2(d−1)=6` plaquettes).
  **CONDITIONAL:** `dependence_defect_kp_summable` (general `C>0`) and
  `dependence_defect_kp_summable_Z4` (`C=6`, threshold `log 42`) route the genuine
  `EntropyBound` polymer count weighted by `exp(−(iE−D))ⁿ` through
  `Wall256Rate.kp_polymer_rate_summable`, CONDITIONAL on the NAMED OPEN hypotheses
  `h_entropy` (connective-constant count), `h_defect : D≤log C` (the
  cluster-expansion convergence input) and `h_rate : log(7·C)<iE` (the genuine
  SU(N) large-deviation rate). All three are HYPOTHESES, NOT `axiom`/`by sorry` —
  so NO `sorryAx` and no new axioms. 5 public theorems; all `sorry`-free, `#print
  axioms` = classical trio (`linkIncidence_four` = no axioms; verified live, raw
  `lean` v4.12.0, EXIT=0). HONEST: `D≤log C` is a NAMED OPEN hypothesis NOT a Lean
  `axiom`; `linkIncidence` is the incidence FORMULA (full `Finset.card` count left
  as genuine combinatorial content); "lower the numbers" is a lever, not a free
  lunch — ℤ⁴ pins `C=6` so the honest threshold is `log 42`, and a smaller `C` is
  a DIFFERENT geometry (H4/120-cell motivation, deferred). Establishes NO KP
  convergence, makes NO mass-gap / μ>0 / Surface-#1 claim, does NOT discharge
  `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall256_RateFunction — HONEST CONDITIONAL large-deviation RATE FUNCTION
  criterion (bricks, in BRICKS):** `Towers/YM/Wall256_RateFunction.lean` is the
  sequel to `Wall255_JensenObstruction` (mean no-go) + `Wall255_KP_Entropy`
  (q<1/7). Program **S4 → 7 → rate `I(x) > log 7`**: a large-deviation rate `I`
  makes the per-polymer activity decay like `exp(−I·n)`, and the entropy-weighted
  sum `∑ₙ 7ⁿ·exp(−I·n)` converges **iff** `7·exp(−I)<1` **iff** `exp(−I)<1/7`
  **iff** `log 7 < I` — i.e. Wall255's `q<1/7` under the dictionary `q=exp(−I)`.
  **(1) GENUINE/UNCONDITIONAL:** `exp_neg_lt_inv_seven_iff`
  (`exp(−I)<1/7 ↔ log 7<I`), `seven_exp_neg_lt_one_iff` (`7·exp(−I)<1 ↔ log 7<I`),
  `rate_beats_entropy` / `rate_tsum` (for `log 7<I`, `∑ₙ 7ⁿ·exp(−I)ⁿ` is
  `Summable` `= (1−7·exp(−I))⁻¹`, entropy KEPT), `rateFn` + `le_rateFn` (the rate
  as the Legendre transform of an ABSTRACT cgf `Λ`, with the variational lower
  bound `t·x−Λ t ≤ rateFn`), `entropy_threshold_eq` (`log polymer_const = log 7`,
  the "→ 7" link), `log_seven_pos`, `mean_rate_fails_criterion` (`¬ log 7<0`: the
  rate VANISHES at the mean `I(e_bar)=0`, so the mean can NEVER meet the
  criterion — restates the Jensen no-go in rate language). **(2) CONDITIONAL:**
  `kp_rate_summable` and `kp_polymer_rate_summable` route the genuine
  `EntropyBound` polymer count weighted by `exp(−I)ⁿ` through the named OPEN
  surfaces `h_entropy` (connective-constant count) and `h_rate : log 7<I` (the
  genuine SU(3) large-deviation rate bound, absent from mathlib v4.12.0; a
  HYPOTHESIS, NOT `by sorry`, so NO `sorryAx`). 10 public theorems; all
  `sorry`-free, `#print axioms` = classical trio (verified live, raw `lean`
  v4.12.0, EXIT=0). HONEST: the rate bound `log 7<I` is the ENTIRE open content
  (needs Cramér/Varadhan + the SU(3) log-MGF, none in mathlib); `rateFn` is the
  Legendre transform of an ABSTRACT `Λ`, NOT the SU(3) cgf. Establishes NO KP
  convergence, makes NO mass-gap / μ>0 / Surface-#1 claim, does NOT give
  `ρ(T)<1`, and does NOT discharge `kotecky_preiss_criterion`. YM stays
  `Status: Open`.
- **Wall255_JensenObstruction — HONEST mean-energy NO-GO (bricks, in BRICKS):**
  `Towers/YM/Wall255_JensenObstruction.lean` is the DUAL of Wall257's
  `vacuum_breaks_energy_lb`: via Jensen's inequality the MEAN plaquette energy
  can NEVER deliver the KP per-polymer smallness `polymerActivity ≤ (1/8)^|γ|`.
  **(1) GENUINE/UNCONDITIONAL:** `plaquetteEnergy_le_two` (closes the deferred
  `Re tr P ≥ -3` endpoint noted in `WilsonAction.plaquetteEnergy`, via
  `traceRe_le_three (-P)` — `-P` is unitary too), `polymerEnergy_le_two_card`,
  `meanEnergy_nonneg`, `meanEnergy_le_two_card`, `e_bar_le_two`
  (`e_bar := meanEnergy/|γ| ≤ 2`), `inv8_pow_eq_exp_neg`, and the heart
  `jensen_obstruction` — for EVERY `β`, `exp(−(β·meanEnergy)) ≤ polymerActivity`,
  via `ConvexOn.map_integral_le` (Jensen for the convex `exp` against the
  probability measure `haarN`). This is a LOWER bound — the WRONG direction for
  KP smallness. **(2) CONDITIONAL:** `e_bar_pos_of_meanEnergy_pos` and
  `mean_threshold_fails` (at the mean threshold `β₀ := log 8 / e_bar`,
  `(1/8)^|γ| ≤ polymerActivity L β₀ γ`) take the named TRUE input
  `hpos : 0 < meanEnergy` — TRUE but unprovable in mathlib v4.12.0 (needs
  `∫ tr = 0` character orthogonality / `haarN` non-atomicity, the same measure
  surface `Transfer.trivial_polymer_set_null` treats as OPEN; a HYPOTHESIS, NOT
  `by sorry`, so NO `sorryAx`). 9 public theorems; all `sorry`-free, `#print
  axioms` = classical trio (verified live, raw `lean` v4.12.0, EXIT=0). HONEST:
  isolates the genuine open problem as the large-deviation RATE function, NOT the
  mean. Makes NO mass-gap / μ>0 / Surface-#1 claim, establishes NO KP
  convergence, does NOT beat the `7ⁿ` entropy, does NOT give `ρ(T)<1`, and does
  NOT discharge `kotecky_preiss_criterion`. YM stays `Status: Open`.
- **Wall257_StrongCoupling — HONEST CONDITIONAL strong-coupling polymer-activity
  bound (bricks, in BRICKS):** `Towers/YM/Wall257_StrongCoupling.lean` lands the
  requested `polymerActivity L β γ ≤ (1/8)^|γ|` as an HONEST CONDITIONAL
  COMBINATOR, NOT an unconditional smallness proof. **(1)
  GENUINE/UNCONDITIONAL:** `inv8_pow_eq_exp_neg` (`(1/8)^n = exp(−(log 8)·n)`,
  via `rpow_natCast`+`rpow_def_of_pos`+`log_inv`), `exp_neg_mul_le_inv8_pow`
  (`log 8 ≤ r ⟹ exp(−r·n) ≤ (1/8)^n`), `inv8_pow_le_inv7_pow`
  (`(1/8)^n ≤ (1/7)^n`, `pow_le_pow_left`), `polymerEnergy_vacuum_eq_zero` (the
  vacuum link field `w≡1` has `polymerEnergy = 0`, `plaquetteEnergy_const_one`
  termwise). **(2) HONEST GAP RECORD:** `vacuum_breaks_energy_lb` PROVES the
  combinator's uniform per-polymer energy lower bound `hLB : ∀ w, c·|γ| ≤
  polymerEnergy (toGauge L w) γ` is FALSE for `c>0` and nonempty `γ` (the vacuum
  violates it) — so the combinator's hypothesis is UNSATISFIABLE for `c>0` and
  this file proves NO smallness of the real activity. **(3) CONDITIONAL:**
  `polymerActivity_le_inv8/inv7_of_energy_lb` derive the bound from the NAMED
  OPEN `hLB` + the strong-coupling threshold `hβc : log 8 ≤ β·c` (a HYPOTHESIS,
  NOT `by sorry`, so NO `sorryAx`), with the genuine integral step
  `∫ exp(−β·E) ∂haarN ≤ exp(−β·c·|γ|) ≤ (1/8)^|γ|` (`integral_mono` +
  `integrable_polymerWeight` + `integral_const` over the probability measure
  `haarN`). 7 public theorems; all `sorry`-free, `#print axioms` = classical trio
  (verified live, raw `lean` v4.12.0, EXIT=0). DEVIATION from the literal ask:
  the originally-requested `kp_activity_lt_inv8 : ∀ π, polymerActivity β π ≤
  (1/8)^|π|` (no β/threshold hypothesis) is OUTRIGHT FALSE — at `β=0` the
  integrand is `1` and `haarN` is a probability measure so activity `=1 >
  (1/8)^|π|` — REFUSED and replaced by this honest conditional. HONEST: the real
  KP smallness lives at the integral/measure level (how `haarN` concentrates near
  the vacuum), NOT at any pointwise energy floor (`inf_{w≠1} polymerEnergy = 0`).
  Makes NO mass-gap / μ>0 / Surface-#1 claim, does NOT beat the `7ⁿ` entropy,
  does NOT give `ρ(T)<1`, and does NOT discharge `kotecky_preiss_criterion`. YM
  stays `Status: Open`.
- **Wall256_MassGapConditional — HONEST CONDITIONAL YM mass-gap apex (bricks, in
  BRICKS):** `Towers/YM/Wall256_MassGapConditional.lean` lands the REQUESTED
  statement shape `∃ Δ>0, ∀ x y, |⟨W(x)W(y)⟩| ≤ C·exp(−Δ·‖x−y‖)` as an HONEST
  CONDITIONAL combinator — NOT an unconditional mass gap. **(1)
  GENUINE/UNCONDITIONAL:** `neg_log_pos_of_lt_one` (`0<ρ<1 ⟹ Δ:=−log ρ>0`, via
  `Real.log_neg`) and `rpow_eq_exp_neg_rate` (`0<ρ ⟹ ρ^d = exp(−Δ·d)`, via
  `Real.rpow_def_of_pos`) — the honest spectral-radius→exponential-clustering
  algebra. **(2) CONDITIONAL:** `mass_gap_pos_of_spectral_gap` derives the
  existential (rate `Δ:=−log ρ`) from TWO NAMED OPEN surfaces (hypotheses, NOT
  `by sorry`, so NO `sorryAx`): `h1 : ρ<1` (the strict transfer-operator
  spectral gap = YM Surface #1; the real `T_L` only has `‖T_L‖≤1`, `S_min=0`,
  locked behind `kotecky_preiss_criterion`) and `hcl : ∀ x y, |corr x y| ≤
  C·ρ^(sep x y)` (the KP geometric clustering output; OPEN — Wall255 beats the
  `7ⁿ` entropy only under the open `q<1/7` surface, no unconditional KP exists).
  `corr`/`sep` are ABSTRACT; NO Wilson correlator is constructed. 3 public
  theorems; all `sorry`-free, `#print axioms` = classical trio (verified live,
  raw `lean` v4.12.0, EXIT=0). HONEST: proves NO mass gap (the entire content is
  the open `h1`+`hcl`); `ρ<1` is NOT discharged (there is NO `kp_activity_lt_inv7`
  theorem and Wall255 did NOT prove `q<1/7` / `ρ≤1/8`); makes NO mass-gap / μ>0 /
  Surface-#1 claim and does NOT discharge `kotecky_preiss_criterion`. YM stays
  `Status: Open`.
- **Wall254_OS_Positivity — HONEST CONDITIONAL Osterwalder–Schrader OS2
  combinator (bricks, in BRICKS):** `Towers/YM/Wall254_OS_Positivity.lean`
  routes reflection positivity through the genuine Gram-PSD heart. **(1)
  GENUINE/UNCONDITIONAL:** `gram_form_eq` (`⟪∑cᵢ•vᵢ, ∑cⱼ•vⱼ⟫ = ∑ᵢⱼ
  conj(cᵢ)cⱼ⟪vᵢ,vⱼ⟫`) and `gram_re_nonneg` (`0 ≤ re ∑ᵢⱼ conj(cᵢ)cⱼ⟪vᵢ,vⱼ⟫`, via
  `inner_self_nonneg`) — the linear-algebra heart of OS positivity for any
  `RCLike` inner-product space, bearing on NO measure. **(2) CONDITIONAL:**
  `os2_of_gram_realization` / `os2_diagonal_nonneg` derive OS2 positivity for an
  abstract Wilson reflected pairing `P : Obs→Obs→𝕜` from the SINGLE NAMED OPEN
  surface `hGNS : ∀ F G, P F G = ⟪J F, J G⟫` (the Osterwalder–Seiler GNS
  realization of the reflected kernel as a Hilbert-space Gram form — a
  HYPOTHESIS, NOT `by sorry`, so NO `sorryAx`). 4 public theorems; all
  `sorry`-free, `#print axioms` = classical trio (verified live, raw `lean`
  v4.12.0, EXIT=0). HONEST: proves NO OS2 for the actual Wilson measure (the
  entire content is the OPEN `hGNS`; NO Wilson measure is constructed), addresses
  ONLY OS2 (not OS0/1/3/4, not the thermodynamic/continuum limit), makes NO
  mass-gap / μ>0 / Surface-#1 claim, and does NOT discharge the
  `kotecky_preiss_criterion` `sorry`. Uses `Mathlib.Analysis.InnerProductSpace
  .Basic` (`inner_self_nonneg`, `sum_inner`, `inner_sum`, `inner_smul_left/right`).
- **Wall255_KP_Entropy — HONEST CONDITIONAL "beat the 7ⁿ entropy" combinator
  (bricks, in BRICKS):** `Towers/YM/Wall255_KP_Entropy.lean`. **(1)
  GENUINE/UNCONDITIONAL:** `entropy_geometric_summable` / `entropy_geometric_tsum`
  — for `0 ≤ q`, `7q < 1`, the entropy-weighted series `∑ₙ 7ⁿ·qⁿ = ∑ₙ (7q)ⁿ`
  is `Summable` with total `(1−7q)⁻¹`. The `7ⁿ` factor is KEPT (contrast
  Wall253's size-series majorant, which DROPPED it). **(2) CONDITIONAL:**
  `kp_entropy_weighted_summable` beats the entropy for any count `N n ≤ 7ⁿ` by
  comparison; `kp_polymer_entropy_weighted_summable` instantiates it at
  `EntropyBound`'s genuine polymer count, CONDITIONAL on the two NAMED OPEN
  surfaces `h_entropy` (connective-constant count) and `q < 1/7` (per-polymer
  smallness). **(3) Honest gap:** `seven_q_lt_one_of_lt_inv_seven` (`q<1/7 ⟹
  7q<1`) and `seven_half_not_lt_one` (`¬ 7·(1/2) < 1`) record that Wall252's
  `kp_sum_lt_half` (`< 1/2`) does NOT reach the `< 1/7` needed (`7·½ = 3.5 ≥ 1`).
  6 public theorems; all `sorry`-free, `#print axioms` = classical trio (verified
  live, raw `lean` v4.12.0, EXIT=0). HONEST: the entropy is beaten ONLY under the
  OPEN `q < 1/7` surface; establishes NO KP convergence (no uniform per-polymer
  activity bound `|ζ(γ)| ≤ q^{|γ|}`, no tree-graph weighting), makes NO mass-gap
  / μ>0 / Surface-#1 claim, and does NOT discharge the `kotecky_preiss_criterion`
  `sorry`. YM stays `Status: Open`.
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
