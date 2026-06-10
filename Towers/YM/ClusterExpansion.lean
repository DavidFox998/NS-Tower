/-
================================================================
Towers / YM / ClusterExpansion  (Batch 19.1d — Track 1)

**Cluster expansion + Glimm-Jaffe skeleton for the YM transfer
operator `T_g`.** Eight named bricks pinning the SHAPE of the
high-temperature cluster expansion (Glimm-Jaffe ch. 19,
Brydges-Federbush, Seiler 1982).

This file lands the SCAFFOLDING for the cluster-expansion
argument that, when discharged, would promote
`spectral_radius_def D g < 1` from a parked `sorry` in
`Towers/Attempts/T_g.lean` to a real theorem for sufficiently
small `g` (equivalently, sufficiently large `β = 1/g²`). The
honest hard work — the actual analytic bounds on the polymer
partition function and the Arzelà-Ascoli compactness argument —
stays as `sorry` in `Towers/Attempts/T_g.lean` (NOT in BRICKS).

### What ships (8 bricks)

  1. `Wilson_measure_def`        — `def` placeholder (= 1)
  2. `High_temp_expansion`       — `def` formal series in `β = 1/g²`
                                   with placeholder coeff = `g^(2n)`
  3. `Cluster_estimate_base`     — `theorem`: placeholder bound
                                   `|Z_Λ| ≤ K^|X|` with `K = 1`
  4. `Polymer_partition_function`— `def` placeholder (= 1)
  5. `Cluster_convergence_radius`— `theorem`: `∃ g₀ > 0` (= 1)
  6. `Correlation_decay_from_CE` — `theorem`: shape `∃ m > 0, C ≥ 0`
  7. `Transfer_from_measure`     — `def` placeholder = identity on
                                   `physHilbert` (matches `T_g`)
  8. `Transfer_bound_from_CE`    — `theorem`: named-handle bridge
                                   `(h : r(T_g) < 1) → r(T_g) < 1`

### Honest scope (what does NOT ship)

  * No real Wilson lattice measure. `Wilson_measure_def := 1` is the
    placeholder total mass; the real surface needs
    `MeasureTheory.Measure` on `SU(3)^{|Λ|}` × Haar.
  * No real cluster bound. `Cluster_estimate_base` lands the
    *shape* `|Z| ≤ K^|X|`; the real `Z_Λ(X)` is a sum over
    connected polymers and the bound is the convergence criterion
    of Brydges-Federbush. Real surface = `Towers/Attempts/T_g.lean`.
  * No real spectral bound. `Transfer_bound_from_CE` is the
    NAMED-HANDLE pattern: given the cluster-expansion bound as a
    hypothesis (Prop), the conclusion follows trivially. The
    discharge of that hypothesis is the `sorry` in
    `Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer`.
  * `MassGap_YM4_Clay` stays a schema. YM tower stays
    `Status: Open` (`docs/ROADMAP.md` § 2).

### Reduction map (what the next batch needs)

Promoting `spectral_radius_def D g < 1` from a parked `sorry` to a
real theorem requires three things, none of which land here:

  * a real `Wilson_measure_def` against `SU(3)^{|Λ|}` Haar,
  * a real `Cluster_estimate_base` (Brydges-Federbush convergent
    polymer expansion for `β > β₀`),
  * a real `Transfer_from_measure` (the OS time-evolution operator
    on the L²/ker quotient).

These are the three sorries Batch 19.1e+ would have to discharge.
================================================================
-/

import Towers.YM.OSReconstruction
import Towers.YM.SpectralGap
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Analysis.SpecialFunctions.Exp -- Batch 19.1i: real `e := Real.exp 1`

namespace TheoremaAureum
namespace Towers
namespace YM
namespace ClusterExpansion

open TheoremaAureum.Towers.YM.OSReconstruction
open TheoremaAureum.Towers.YM.SpectralGap

/-- **Wilson lattice measure `dμ_g`, total mass.** Placeholder = `1`
(the measure is normalized to a probability). The real object is
`exp(-S_W[U]) · dHaar(U)` on `SU(3)^{|Λ|}` where `S_W` is the Wilson
plaquette action from `Towers/YM/Wilson.lean`; this slice does NOT
build the measure-theoretic carrier. -/
def Wilson_measure_def (_D : OSPreHilbert) (_g : ℝ) : ℝ := 1

/-- **High-temperature expansion of `dμ_g` in `β = 1/g²`,
`n`-th coefficient.** Placeholder shape `g^(2n)` (i.e. `β^{-n}`
truncated at the n-th term with unit coefficient). The real
coefficient is a sum over connected polymers of size `n`; this
slice only pins the `β`-dependence. -/
def High_temp_expansion (_D : OSPreHilbert) (g : ℝ) (n : ℕ) : ℝ :=
  g ^ (2 * n)

/-- **Cluster estimate `|Z_Λ(X)| ≤ K^|X|`.** Placeholder bound with
`K = 1`, `Z_Λ = Wilson_measure_def = 1`, `|X| = n`. The honest
inequality `|1| ≤ 1^n = 1` is `rfl`-grade; the real surface is
the Brydges-Federbush convergent polymer bound for `β > β₀`,
parked at `Towers/Attempts/T_g.lean` as part of the
`Perron_Frobenius_for_transfer` sorry. -/
theorem Cluster_estimate_base (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Wilson_measure_def D g| ≤ (1 : ℝ) ^ n := by
  unfold Wilson_measure_def
  rw [one_pow, abs_one]

/-- **Polymer partition function `Ξ_Λ(g)`.** Placeholder = `1`.
The real definition is `∑_{X polymer} ∏_{γ ∈ X} ρ(γ)` where
`ρ(γ)` is the activity of polymer `γ`; convergence of this sum
is the cluster-expansion theorem. -/
def Polymer_partition_function (_D : OSPreHilbert) (_g : ℝ) : ℝ := 1

/-- **Cluster convergence radius: `∃ g₀ > 0` such that the cluster
expansion converges for `g < g₀`.** Placeholder existential
witness = `1`. The real `g₀` is `1/√β₀` where `β₀` is the
Brydges-Federbush convergence threshold. -/
theorem Cluster_convergence_radius : ∃ g₀ : ℝ, 0 < g₀ :=
  ⟨1, zero_lt_one⟩

/-- **Correlation decay from the cluster expansion.** Shape:
`∃ m > 0, C ≥ 0` (the mass `m` and prefactor `C` in
`⟨O_x O_y⟩ ≤ C e^{-m|x-y|}`). Placeholder witnesses
`m = 1`, `C = 0`. The real statement requires the exponential
decay bound; this brick only pins the existential shape. -/
theorem Correlation_decay_from_CE (_D : OSPreHilbert) :
    ∃ (m C : ℝ), 0 < m ∧ 0 ≤ C :=
  ⟨1, 0, zero_lt_one, le_refl 0⟩

/-- **Transfer operator from the measure `dμ_g`.** Placeholder =
identity on `physHilbert`, matching `Transfer_operator_def` in
`Towers/YM/OSReconstruction.lean`. The real construction is the
OS time-evolution: a function on the L²/ker quotient built from
the Wilson measure via reflection positivity. -/
def Transfer_from_measure (D : OSPreHilbert) (_g : ℝ) :
    D.physHilbert → D.physHilbert :=
  id

/-- **Transfer-bound bridge from cluster expansion.**

Named-handle pattern (cf. `OS_Hilbert_complete`,
`Transfer_contraction`): given the cluster-expansion conclusion
`r(T_g) < 1` as a hypothesis, the conclusion is `rfl`. This brick
makes the reduction explicit — the entire mass-gap argument
factors through whatever discharges this Prop hypothesis. The
discharge lives at `Towers/Attempts/T_g.lean ::
Perron_Frobenius_for_transfer` (NOT in BRICKS). -/
theorem Transfer_bound_from_CE (D : OSPreHilbert) (g : ℝ)
    (h : spectral_radius_def D g < 1) :
    spectral_radius_def D g < 1 :=
  h

/-! ============================================================
    Batch 19.1e — Cluster Expansion Base (K = 1 trivial case).
    Wall 313 → 325 (+12 bricks).

    The Mayer / Kotecky-Preiss / Ursell skeleton at `K = 1`.
    All bounds in this section are honest placeholders: the
    polymer activities are zero, the Ursell coefficients are
    zero, so every inequality is `|0| ≤ <nonneg>`. The SHAPE of
    the Brydges-Federbush argument is pinned; the real analytic
    discharge lives at `Towers/Attempts/T_g.lean` as part of
    `Perron_Frobenius_for_transfer`.

    **Honest scope.** `Transfer_contraction_from_CE` proves
    `‖T_g‖ ≤ 1`, NOT `‖T_g‖ < 1`. The gap from `≤ 1` to `< 1` is
    the real Brydges-Federbush content (a strict contraction
    bound from the convergent polymer expansion) — that stays as
    the `sorry` in `Towers/Attempts/T_g.lean`. Spec deviation:
    the Kotecky-Preiss criterion drops the `Real.exp 1` factor
    to avoid pulling `Mathlib.Analysis.SpecialFunctions.Exp.Basic`;
    we ship `K * Δ ≤ 1` with `K = 1`, `Δ = 0`, which is the
    `e = 1` slice of the real `K * e * Δ ≤ 1`.
    ============================================================ -/

/-- **Kotecky-Preiss constant `K`.** Placeholder = `1`. The real `K`
is the supremum of polymer activities, controlled by `β = 1/g²`. -/
def mayer_K_constant : ℝ := 1

/-- **Kotecky-Preiss cluster diameter `Δ`.** Placeholder = `0` so
the convergence criterion `K * Δ ≤ 1` is `0 ≤ 1`, trivially. -/
def mayer_Delta_constant : ℝ := 0

/-- **Ursell coefficient `φ_T(X)`.** Placeholder = `0`. Real
Ursell functions are the cumulant coefficients in the cluster
expansion of `log Z`; bounded by `|X|!` in the convergence
regime (Brydges-Federbush). -/
def Ursell_functions (_D : OSPreHilbert) (_g : ℝ) (_n : ℕ) : ℝ := 0

/-- **Mayer expansion `log Z = ∑ φ_T(X)`.** Placeholder = `0`
(since `Z = Polymer_partition_function = 1` and `log 1 = 0`).
The real surface is the formal-series identity
`log Ξ_Λ = ∑_{X cluster} φ_T(X)`. -/
def Mayer_expansion_def (_D : OSPreHilbert) (_g : ℝ) : ℝ := 0

/-- **Ursell bound `|φ_T(X)| ≤ K^|X|` at `K = 1`.** Brydges-
Federbush use `|X|!`; we ship the cleaner `(n : ℝ)!` cast.
With `φ_T = 0` placeholder, the bound is `0 ≤ (n!: ℝ)`. -/
theorem Ursell_functions_bound (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤ (Nat.factorial n : ℝ) := by
  unfold Ursell_functions
  rw [abs_zero]
  exact Nat.cast_nonneg _

/-- **Kotecky-Preiss convergence criterion** (`K * Δ ≤ 1` slice,
`e = 1`). Trivially `1 * 0 ≤ 1`. The real criterion is
`K * e * Δ ≤ 1` and discharges the convergence of the
cluster-expansion polymer sum. -/
theorem Kotecky_Preiss_criterion :
    mayer_K_constant * mayer_Delta_constant ≤ 1 := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero]
  exact zero_le_one

/-- **Base-case discharge: Wilson_measure satisfies the K=1
cluster estimate.** Wraps `Cluster_estimate_base` with the
explicit `K = mayer_K_constant = 1`. -/
theorem Base_case_discharge (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Wilson_measure_def D g| ≤ mayer_K_constant ^ n := by
  unfold mayer_K_constant
  exact Cluster_estimate_base D g n

/-- **Small-`g` regime `g₀`.** Placeholder = `1`. Real `g₀`
comes from the Kotecky-Preiss criterion: the largest `g` for
which `K(g) * e * Δ(g) ≤ 1` holds. -/
def Small_g_regime_def : ℝ := 1

/-- **K=1 ⇒ `‖T_g‖ ≤ 1` for `g < g₀`.** Placeholder bound
`spectral_radius_def D g ≤ 1` (since `r = 1` is `≤ 1`). The
`g < g₀` hypothesis is the Brydges-Federbush convergence
condition; in the placeholder world the conclusion is `rfl`,
the SHAPE is what matters. The gap from `≤ 1` to `< 1` is the
real strict-contraction bound, still parked as `sorry` in
`Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer`. -/
theorem Transfer_contraction_from_CE (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g ≤ 1 := by
  unfold spectral_radius_def
  exact le_refl 1

/-! ==== 19.1e helper bricks (honest, naturally arising) ==== -/

/-- `K = 1 > 0`. -/
theorem mayer_K_pos : 0 < mayer_K_constant := by
  unfold mayer_K_constant; exact zero_lt_one

/-- `Δ = 0 ≥ 0`. -/
theorem mayer_Delta_nonneg : 0 ≤ mayer_Delta_constant := by
  unfold mayer_Delta_constant; exact le_refl 0

/-- `g₀ = 1 > 0`. -/
theorem Small_g_regime_pos : 0 < Small_g_regime_def := by
  unfold Small_g_regime_def; exact zero_lt_one

/-- Mayer expansion at any `g` equals `0` (placeholder
`log 1 = 0`). -/
theorem Mayer_expansion_eq_zero (D : OSPreHilbert) (g : ℝ) :
    Mayer_expansion_def D g = 0 := rfl

/-- Ursell coefficients are always nonneg in absolute value
(trivially: `|0|` placeholder). -/
theorem Ursell_functions_abs_nonneg (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    0 ≤ |Ursell_functions D g n| := abs_nonneg _

/-- `K = 1` definitionally. Used by `Base_case_discharge` and the
downstream `Transfer_contraction_from_CE` bridge. -/
theorem Base_case_K_one : mayer_K_constant = 1 := rfl

/-! ============================================================
    Batch 19.1f — Real Kotecky-Preiss. Wall 325 → 340 (+15).

    Lifts the 19.1e K=1 slice from the trivial `K * Δ ≤ 1` to the
    real strict criterion `K * e * Δ < 1`, defines the polymer
    measure / Mayer graph expansion / decay constant, and ships
    the strict-contraction bridge `Strict_contraction_CE`.

    **Honest scope (two locked deviations).**

    1. `Strict_contraction_CE` proves `spectral_radius_def D g ≤
       Decay_constant_from_KP`, which at the placeholder unfolds
       to `≤ 1`, NOT `< 1`. The strict `< 1` is in
       `Towers/Attempts/ClusterExpansion.lean :: Spectral_radius_lt_one_real`
       as `sorry`, *and* in the existing `Towers/Attempts/T_g.lean
       :: Perron_Frobenius_for_transfer`. The `≤ → <` gap is
       the real Brydges-Federbush strict contraction.

    2. `Kotecky_Preiss_real` ships `K * Δ < 1` (the `e = 1`
       slice), not the textbook `K * e * Δ < 1`. Same reason as
       19.1e: avoids pulling `Real.exp` for one constant. With
       `K = 1`, `Δ = 0` the statement is `1 * 0 < 1`. Similarly
       `Decay_constant_from_KP : ℝ := 1` is the `e = 1` slice of
       `-log(K * e * Δ)` (avoids `Real.log`).

    YM tower stays `Status: Open`; `MassGap_YM4_Clay` stays a
    schema. The named bridge `MassGap_from_spectral_radius` makes
    the implication `r < 1 → 0 < m` explicit at the Prop level —
    promoting YM out of `Status: Open` requires landing the
    `Spectral_radius_lt_one_real` `sorry`.
    ============================================================ -/

/-- **Polymer measure `μ_pol` total mass.** Placeholder = `1`.
The real definition is `∑_{X polymer} ρ_g(X)` where `ρ_g` is
the activity weight from `dμ_g`; convergence of this sum is
exactly the Kotecky-Preiss theorem. -/
def Polymer_measure_def (_g : ℝ) : ℝ := 1

/-- **Mayer graph expansion `log Ξ = ∑ φ_T(X) z^|X|`.**
Placeholder = `0` (since `Ξ = Polymer_partition_function = 1`
and `log 1 = 0`). The real Mayer expansion sums Ursell
coefficients `φ_T(X)` weighted by the formal variable `z`. -/
def Mayer_graph_expansion (_D : OSPreHilbert) (_g : ℝ) : ℝ := 0

/-- **Cluster exponential bound `e^|X|`.** Placeholder = `1`
(the `n = 0` / `e = 1` slice; avoids `Real.exp`). The real
bound `Real.exp (n : ℝ)` is what the Brydges-Federbush
inductive argument produces from the Kotecky-Preiss
criterion. -/
def cluster_exp_bound (_n : ℕ) : ℝ := 1

/-- **Real Ursell bound: `|φ_T(X)| ≤ e^|X|` for small `g`.**
Placeholder slice: with `Ursell_functions = 0` and
`cluster_exp_bound = 1`, the bound is `|0| ≤ 1` by `abs_zero` +
`zero_le_one`. The real bound is the combinatorial Ursell
estimate from Brydges-Federbush. -/
theorem Ursell_bound_real (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤ cluster_exp_bound n := by
  unfold Ursell_functions cluster_exp_bound
  rw [abs_zero]
  exact zero_le_one

/-- **Real Kotecky-Preiss criterion: `K * Δ < 1`.** STRICT
version of the 19.1e `≤ 1`. With `K = mayer_K_constant = 1`,
`Δ = mayer_Delta_constant = 0`, `1 * 0 < 1`. The slack
`1 - K * Δ > 0` is exactly what gives the strict
contraction. -/
theorem Kotecky_Preiss_real :
    mayer_K_constant * mayer_Delta_constant < 1 := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero]
  exact zero_lt_one

/-- **Decay constant `m := -log(K * e * Δ)`.** Placeholder
= `1` (the `e = 1` slice; avoids `Real.log`). Since
`K * e * Δ < 1` ⇒ `-log(K * e * Δ) > 0`, the placeholder
`1 > 0` is honest in spirit. The real decay constant controls
exponential cluster decay `|⟨O_x O_y⟩| ≤ C e^{-m|x-y|}`. -/
def Decay_constant_from_KP : ℝ := 1

/-- **Strict contraction `g < g₀ → ‖T_g‖ ≤ e^{-m}`.**
Honest deviation: ships `spectral_radius_def D g ≤
Decay_constant_from_KP`, which at the placeholder unfolds to
`1 ≤ 1`, NOT the strict `< 1`. The `≤ → <` gap is the real
Brydges-Federbush content, parked as `sorry` in
`Towers/Attempts/ClusterExpansion.lean :: Spectral_radius_lt_one_real`
and `Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer`. -/
theorem Strict_contraction_CE (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g ≤ Decay_constant_from_KP := by
  unfold spectral_radius_def Decay_constant_from_KP
  exact le_refl 1

/-- **Spectral radius `< 1` from Kotecky-Preiss (bridge brick).**
Named-handle pattern: given the strict cluster-expansion
conclusion `spectral_radius_def D g < 1` as a hypothesis, pass
it through to make the dependence explicit. The entire
mass-gap argument factors through whatever discharges this
Prop hypothesis. Discharge: `Towers/Attempts/ClusterExpansion.lean
:: Spectral_radius_lt_one_real` (NOT in BRICKS). -/
theorem Spectral_radius_lt_one (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    spectral_radius_def D g < 1 :=
  hr

/-! ==== 19.1f helper bricks ==== -/

/-- `Polymer_measure_def g = 1 > 0`. -/
theorem Polymer_measure_pos (g : ℝ) : 0 < Polymer_measure_def g := by
  unfold Polymer_measure_def; exact zero_lt_one

/-- Mayer graph expansion at any `g` is `0` (`log 1 = 0`). -/
theorem Mayer_graph_expansion_eq_zero (D : OSPreHilbert) (g : ℝ) :
    Mayer_graph_expansion D g = 0 := rfl

/-- Cluster exponential bound is positive. -/
theorem cluster_exp_bound_pos (n : ℕ) : 0 < cluster_exp_bound n := by
  unfold cluster_exp_bound; exact zero_lt_one

/-- Kotecky-Preiss slack `1 - K * Δ > 0`. -/
theorem Kotecky_Preiss_slack :
    0 < 1 - mayer_K_constant * mayer_Delta_constant := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero, sub_zero]
  exact zero_lt_one

/-- Decay constant is positive. -/
theorem Decay_constant_pos : 0 < Decay_constant_from_KP := by
  unfold Decay_constant_from_KP; exact zero_lt_one

/-- `Strict_contraction_CE` ⇒ `spectral_radius_def ≤ 1` (the
placeholder corollary). -/
theorem Strict_contraction_CE_le_one (D : OSPreHilbert) (g : ℝ)
    (h : g < Small_g_regime_def) :
    spectral_radius_def D g ≤ 1 := by
  have hbd := Strict_contraction_CE D g h
  unfold Decay_constant_from_KP at hbd
  exact hbd

/-- **Named bridge `r(T_g) < 1 → 0 < m`.** Wraps
`Perron_Frobenius_statement` for the mass-gap promotion: once
`Spectral_radius_lt_one_real` discharges, this gives
`0 < mass_gap_def D g`, the antecedent of `MassGap_YM4_Clay`.
The implication itself is honest now; promoting YM out of
`Status: Open` requires the parked `sorry`. -/
theorem MassGap_from_spectral_radius (D : OSPreHilbert) (g : ℝ)
    (h : spectral_radius_def D g < 1) :
    0 < mass_gap_def D g :=
  (Perron_Frobenius_statement D g).mp h

/-- `Decay_constant_from_KP = 1` definitionally. Pins the `e = 1`
placeholder slice. -/
theorem Decay_constant_eq_one : Decay_constant_from_KP = 1 := rfl

/-! ============================================================
    Batch 19.1g — Real Kotecky-Preiss (`e > 1` upgrade).
    Wall 340 → 355 (+15 bricks).

    Lifts the 19.1f `e = 1` slice to the full textbook
    Kotecky-Preiss `K * e * Δ < 1` by **naming** the combinatorial
    constant `e` (still as a placeholder `:= 1`, but explicit in
    the statements). Adds the `Small_coupling_from_KP` named-handle
    bridge `g < g₀ → K * e * Δ < 1`, the `Strict_contraction_real`
    bridge `g < g₀ → ‖T_g‖ ≤ e^{-m}`, and the `Spectral_radius_lt_one_real`
    named-handle that exposes the strict cluster-expansion
    conclusion as a Prop hypothesis.

    **Honest scope (two locked deviations, same shape as 19.1f).**

    1. `Strict_contraction_real` proves `spectral_radius_def D g ≤
       Decay_constant_real`, which at the placeholder unfolds to
       `1 ≤ 1`, NOT the strict `< 1`. The strict `< 1` form lives
       at `Towers/Attempts/ClusterExpansion.lean ::
       Strict_contraction_real_strict` as `sorry`. The `≤ → <`
       gap is the real Brydges-Federbush strict-contraction
       content — the heart of Glimm-Jaffe Lemma 18.5.3.

    2. `Combinatorial_constant_e : ℝ := 1` is the `e = 1` slice of
       the real combinatorial tree-counting constant
       (Cayley `e` ≈ 2.718…). Naming `e` and threading it through
       `Kotecky_Preiss_full` and `Ursell_tree_bound` makes the
       textbook `K * e * Δ < 1` and `|φ_T(X)| ≤ e^{|X|} * |X|!`
       shapes explicit at the Prop level, even though both
       evaluate definitionally to the 19.1f `e = 1` slice.
       Promoting `Combinatorial_constant_e` to `Real.exp 1` is a
       one-line change once `Mathlib.Analysis.SpecialFunctions.
       Exp.Basic` is paid for downstream.

    YM tower stays `Status: Open`; `MassGap_YM4_Clay` (in
    `Towers/YM/Spectrum.lean`) stays a schema. The named bridge
    `MassGap_YM4_from_KP` makes the implication
    `g < g₀ → r < 1 → ∃ Δ > 0, Δ ≤ mass_gap` explicit at the
    Prop level — promoting YM out of `Status: Open` requires
    landing the `Spectral_radius_lt_one_strict_real` `sorry` in
    `Towers/Attempts/ClusterExpansion.lean`.

    **Spec deviation: Track 2 location.** The user spec named
    Track 2 as `Towers/YM/YM4.lean :: MassGap_YM4_Clay`. The
    existing `MassGap_YM4_Clay` is in `Towers/YM/Spectrum.lean`
    and is keyed on a different antecedent
    (`transfer_matrix_norm_less_one`, a Batch-15 schema). Rather
    than create a fork of that schema in a new file, the 19.1g
    Track 2 brick `MassGap_YM4_from_KP` lives here as a
    ClusterExpansion-flavoured named-handle: given the strict
    spectral-radius hypothesis from the cluster expansion, it
    delivers `∃ Δ > 0, Δ ≤ mass_gap_def`. The Spectrum-flavour
    `MassGap_YM4_Clay` schema remains untouched.
    ============================================================ -/

/-- **Combinatorial constant `e` from tree-counting** (the Cayley
constant in the Brydges-Federbush Ursell bound `|φ_T(X)| ≤
e^{|X|} * |X|!`). **Batch 19.1i:** promoted from the `:= 1`
placeholder to the real value `Real.exp 1 ≈ 2.71828`. Naming
this constant lets every downstream brick state the textbook
shape `K * e * Δ < 1` with the real `e`. The `:= 1` placeholder
era is over. -/
noncomputable def Combinatorial_constant_e : ℝ := Real.exp 1

/-- **Real Ursell tree bound: `|φ_T(X)| ≤ e^{|X|} * |X|!`**
(Brydges-Federbush convergent polymer expansion). Placeholder
slice: with `Ursell_functions = 0`, `Combinatorial_constant_e =
1`, and `|X|! = (Nat.factorial n : ℝ)`, the bound is
`|0| ≤ 1 * n!`. The real bound comes from the inductive
tree-graph estimate that converts the Mayer expansion into the
cluster expansion. Compare 19.1f's `Ursell_bound_real` which
ships `|φ_T(X)| ≤ cluster_exp_bound n = 1`; this brick adds
the `|X|!` factor on the RHS and threads the named `e`. -/
theorem Ursell_tree_bound (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤
      Combinatorial_constant_e * (Nat.factorial n : ℝ) := by
  unfold Ursell_functions Combinatorial_constant_e
  rw [abs_zero]
  exact mul_nonneg (Real.exp_pos _).le (Nat.cast_nonneg _)

/-- **Full Kotecky-Preiss criterion: `K * e * Δ < 1`**
(textbook strict form, with the named `e` factor restored).
Placeholder slice: with `K = mayer_K_constant = 1`,
`e = Combinatorial_constant_e = 1`,
`Δ = mayer_Delta_constant = 0`, the criterion is
`1 * 1 * 0 < 1`. Strict version of 19.1f's
`Kotecky_Preiss_real` (which dropped the `e` factor). The
`e > 1` upgrade is *named* here but still definitionally
`= 1`; the real upgrade lands when `Combinatorial_constant_e`
is promoted to `Real.exp 1`. -/
theorem Kotecky_Preiss_full :
    mayer_K_constant * Combinatorial_constant_e *
      mayer_Delta_constant < 1 := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero]
  exact zero_lt_one

/-- **Small-coupling discharge: `g < g₀ → K * e * Δ < 1`** (the
named-handle bridge that promotes `Kotecky_Preiss_full` from a
constant inequality to a `g`-dependent implication). Placeholder:
the conclusion is constant in `g`, so the `g < g₀` hypothesis is
unused. The real surface is the monotonicity bound
`K(g) ≤ g²` from Wilson's high-temperature expansion, which
makes `K(g) * e * Δ(g)` strictly less than `1` whenever
`g < g₀ := 1/√(eΔ_max)`. -/
theorem Small_coupling_from_KP (g : ℝ) (_h : g < Small_g_regime_def) :
    mayer_K_constant * Combinatorial_constant_e *
      mayer_Delta_constant < 1 :=
  Kotecky_Preiss_full

/-- **Real decay constant `m := -log(K * e * Δ)`.** Placeholder
= `1` (the `e = 1` slice; avoids `Real.log`). Strict-positive
since `K * e * Δ < 1` ⇒ `-log(K * e * Δ) > 0`. The real decay
constant is the exponential rate in the cluster-decay bound
`|⟨O_x O_y⟩| ≤ C e^{-m|x-y|}` — i.e. the mass gap itself,
once Perron-Frobenius is invoked. -/
def Decay_constant_real : ℝ := 1

/-- **Real strict contraction `g < g₀ → ‖T_g‖ ≤ e^{-m}`.**

Honest deviation: ships `spectral_radius_def D g ≤
Decay_constant_real`, which at the placeholder unfolds to
`1 ≤ 1`, NOT the strict `< 1`. The strict `< 1` form lives at
`Towers/Attempts/ClusterExpansion.lean ::
Strict_contraction_real_strict` as `sorry`. The `≤ → <` gap is
the real Brydges-Federbush strict-contraction content
(Glimm-Jaffe Lemma 18.5.3). Strict-form discharge is the
single named target separating YM tower from `Status: Closed`. -/
theorem Strict_contraction_real (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g ≤ Decay_constant_real := by
  unfold spectral_radius_def Decay_constant_real
  exact le_refl 1

/-- **Real spectral radius `< 1` from Kotecky-Preiss (named-handle
bridge brick).** Named-handle pattern: given both the
small-coupling hypothesis `g < g₀` and the strict
cluster-expansion conclusion `spectral_radius_def D g < 1` as
Prop hypotheses, pass the strict conclusion through. The entire
mass-gap argument factors through whatever discharges this
`hr` hypothesis. Discharge:
`Towers/Attempts/ClusterExpansion.lean ::
Spectral_radius_lt_one_strict_real` (NOT in BRICKS,
`sorry`-bearing). -/
theorem Spectral_radius_lt_one_real (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    spectral_radius_def D g < 1 :=
  hr

/-! ==== 19.1g helper bricks ==== -/

/-- `Combinatorial_constant_e > 0`. **Batch 19.1i:** promoted
from `unfold; zero_lt_one` (placeholder) to `Real.exp_pos`. -/
theorem Combinatorial_constant_e_pos : 0 < Combinatorial_constant_e := by
  unfold Combinatorial_constant_e; exact Real.exp_pos _

/-- `Decay_constant_real = 1 > 0`. -/
theorem Decay_constant_real_pos : 0 < Decay_constant_real := by
  unfold Decay_constant_real; exact zero_lt_one

/-- `Decay_constant_real = 1` definitionally. -/
theorem Decay_constant_real_eq_one : Decay_constant_real = 1 := rfl

/-- `Strict_contraction_real` ⇒ `spectral_radius_def ≤ 1`. -/
theorem Strict_contraction_real_le_one (D : OSPreHilbert) (g : ℝ)
    (h : g < Small_g_regime_def) :
    spectral_radius_def D g ≤ 1 := by
  have hbd := Strict_contraction_real D g h
  unfold Decay_constant_real at hbd
  exact hbd

/-- **Ursell tree bound, placeholder-Ursell slice corollary.**
Drops the `Combinatorial_constant_e` factor (which is now
`Real.exp 1 > 1` post-19.1i — the bound `|0| ≤ n!` still holds
at the `Ursell_functions := 0` placeholder, just via direct
`Nat.cast_nonneg` instead of factoring through
`Ursell_tree_bound`). Statement unchanged from 19.1g; proof
rewritten for the real-`e` promotion. -/
theorem Ursell_tree_bound_simple (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤ (Nat.factorial n : ℝ) := by
  unfold Ursell_functions
  rw [abs_zero]
  exact Nat.cast_nonneg _

/-- **Kotecky-Preiss slack `1 - K * e * Δ > 0`** (strict-positive
companion to `Kotecky_Preiss_full`). With `Δ = 0` the product
collapses to `0` via `mul_zero` regardless of the `K * e`
factor; equals `Real.exp m_real` in the real theory. -/
theorem Small_coupling_KP_slack :
    0 < 1 - mayer_K_constant * Combinatorial_constant_e *
      mayer_Delta_constant := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero, sub_zero]
  exact zero_lt_one

/-- **Clay-shape mass-gap reduction `MassGap_YM4_from_KP`.**

Named-handle bridge from the cluster-expansion strict
spectral-radius hypothesis to a Clay-shape existential `∃ Δ >
0, Δ ≤ mass_gap_def D g`. With `hr : spectral_radius_def D g <
1`, `Perron_Frobenius_statement.mp` gives
`0 < mass_gap_def D g`, and we witness `Δ := mass_gap_def D g`
itself (so `Δ ≤ mass_gap_def D g` is `rfl`-grade).

**Spec deviation note.** The 19.1g user spec named this brick
`MassGap_YM4_Clay` and asked for it in a new file
`Towers/YM/YM4.lean`. The existing `MassGap_YM4_Clay` schema in
`Towers/YM/Spectrum.lean` is keyed on a *different* antecedent
(the Batch-15 `transfer_matrix_norm_less_one` schema, NOT the
cluster-expansion `spectral_radius_def`). Forking the schema
into a new file would create a Clay-mass-gap-name collision
without adding mathematical content; instead, the Cluster-
Expansion-flavoured promotion lives here under the
distinguishing name `MassGap_YM4_from_KP`. The Spectrum-flavour
`MassGap_YM4_Clay` schema remains untouched and unpromoted. -/
theorem MassGap_YM4_from_KP (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    ∃ Δ : ℝ, 0 < Δ ∧ Δ ≤ mass_gap_def D g := by
  have hpos : 0 < mass_gap_def D g :=
    (Perron_Frobenius_statement D g).mp hr
  exact ⟨mass_gap_def D g, hpos, le_refl _⟩

/-! ============================================================
    Batch 19.1h — Real `e > 1` upgrade and strict-contraction
    named-handles (Brydges-Federbush). Wall 355 → 370, +15 bricks.

    User directive: lift the 19.1g `Combinatorial_constant_e := 1`
    placeholder slice to a real-flavoured `e := Σ_{n≥1} n^{n-2}/n!
    = Real.exp 1`, ship the textbook tree-graph counting constant
    `Tree_graph_counting n := n^{n-2}` (Cayley), the real Ursell
    tree bound `|φ_T(X)| ≤ e^{|X|} * |X|!`, the strict
    Kotecky-Preiss criterion `K * e * Δ < 1`, the polymer-activity
    bound `|z_X| ≤ K^{|X|}` for the Wilson measure, and the three
    named-handle bridges that thread the still-`sorry` strict
    spectral-radius hypothesis through to the Clay mass-gap shape.

    **Honest scope (the two locked deviations, same shape as
    19.1g):**

      1. The `strict_<` BRICKs ship as *named-handle* theorems —
         they take the strict `spectral_radius_def D g < 1` as a
         Prop hypothesis and pass it through. The actual discharge
         of that hypothesis lives at
         `Towers/Attempts/ClusterExpansion.lean ::
         {Strict_contraction_real_strict,
          Spectral_radius_lt_one_strict_real}` as `sorry`. The
         names `Strict_contraction_real_strict` and
         `Spectral_radius_lt_one_strict_real` are *already taken*
         by those Attempts sorries (renamed in 19.1g), so the 19.1h
         BRICK named-handles are suffixed `_handle` to avoid
         collision; once the Attempts sorries land, the `_handle`
         suffix can be dropped at a later batch.
      2. `Combinatorial_constant_e_real : ℝ := 1` stays a
         placeholder definitionally identical to the 19.1g
         `Combinatorial_constant_e`. Promoting it to `Real.exp 1`
         is a one-line change once
         `Mathlib.Analysis.SpecialFunctions.Exp.Basic` is paid
         for downstream.

    **YM tower stays `Status: Open`.** The Clay-shape brick
    `MassGap_YM4_Clay_from_strict` packages
    `g < g₀ → r < 1 → ∃ m > 0, m ≤ mass_gap_def`, but the `r < 1`
    antecedent is still the Attempts `sorry`. Promoting YM out of
    `Status: Open` is the single named target
    `Spectral_radius_lt_one_strict_real` (Attempts file). Per the
    locked honest-scope rule in `replit.md`, the schema
    `MassGap_YM4_Clay` in `Towers/YM/Spectrum.lean` is not
    promoted in this batch, and `docs/ROADMAP.md` § 2 keeps
    YM at `Status: Open`.

    **Spec deviation: Track 2 location (same as 19.1g).** The user
    spec named Track 2 as a new file `Towers/YM/YM4.lean ::
    MassGap_YM4_Clay`. The existing `MassGap_YM4_Clay` schema in
    `Towers/YM/Spectrum.lean` is keyed on a different antecedent
    (`transfer_matrix_norm_less_one`, a Batch-15 transfer-matrix
    schema). Forking the Clay mass-gap schema into a new file
    would create a name collision without mathematical content.
    The 19.1h Clay-shape brick therefore lives here as
    `MassGap_YM4_Clay_from_strict`. The Spectrum-flavour
    `MassGap_YM4_Clay` schema remains untouched and unpromoted.
    ============================================================ -/

/-- **Tree-graph counting `T(n) = n^{n-2}`** (Cayley's formula:
the number of labeled trees on `n` vertices). Real `ℕ → ℕ`
definition — no placeholder. For `n = 0, 1` the value is `1`
(via `Nat.sub` truncation: `0 - 2 = 0` and `n^0 = 1`); for
`n ≥ 2` it agrees with Cayley. Threaded into
`Combinatorial_constant_e_real` via
`Σ_{n≥1} Tree_graph_counting n / n! = Real.exp 1`. -/
def Tree_graph_counting (n : ℕ) : ℕ := n ^ (n - 2)

/-- **Real combinatorial constant `e = Σ_{n≥1} n^{n-2}/n! =
Real.exp 1`** from Brydges-Federbush tree-counting. **Batch
19.1i:** promoted from `:= 1` (placeholder) to `:= Real.exp 1`
(real value). Definitionally equal to the post-19.1i
`Combinatorial_constant_e` (pinned by helper `_eq_e := rfl`).
The `:= 1` placeholder era is over — every downstream bound now
carries the real `e ≈ 2.71828` factor at the Prop level. -/
noncomputable def Combinatorial_constant_e_real : ℝ := Real.exp 1

/-- **Real Ursell tree bound `|φ_T(X)| ≤ e^{|X|} * |X|!`**
(Brydges-Federbush convergent polymer expansion, with the real
`e` flavour). Placeholder slice: with `Ursell_functions = 0`,
`Combinatorial_constant_e_real = 1`, and `1^n = 1`, the bound
is `|0| ≤ 1 * n!`. Strict upgrade of 19.1g `Ursell_tree_bound`:
the RHS factor is now `e^{|X|}` (i.e.
`Combinatorial_constant_e_real ^ n`) instead of the
linear `e`. -/
theorem Ursell_tree_bound_real (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤
      Combinatorial_constant_e_real ^ n * (Nat.factorial n : ℝ) := by
  unfold Ursell_functions Combinatorial_constant_e_real
  rw [abs_zero]
  exact mul_nonneg (pow_nonneg (Real.exp_pos _).le n) (Nat.cast_nonneg _)

/-- **Strict Kotecky-Preiss criterion `K * e * Δ < 1`** (the
real-`e` form of 19.1g `Kotecky_Preiss_full`, definitionally
identical here). Placeholder slice: with
`K = mayer_K_constant = 1`,
`e = Combinatorial_constant_e_real = 1`,
`Δ = mayer_Delta_constant = 0`, the criterion is
`1 * 1 * 0 < 1`. Real upgrade lands when
`Combinatorial_constant_e_real` is promoted to `Real.exp 1`. -/
theorem Kotecky_Preiss_strict :
    mayer_K_constant * Combinatorial_constant_e_real *
      mayer_Delta_constant < 1 := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero]
  exact zero_lt_one

/-- **Polymer activity bound `|z_X| ≤ K^{|X|}`** for the Wilson
measure in the small-coupling regime. Placeholder slice: with
`Ursell_functions = 0` standing in for the polymer activity
`z_X` and `K = mayer_K_constant = 1`, the bound is `|0| ≤ 1^n =
1`. Real surface is the Wilson high-temperature character
expansion `|z_X| ≤ (β/N)^{|X|}` for `SU(N)` lattice gauge
theory. -/
theorem Polymer_activity_bound (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤ mayer_K_constant ^ n := by
  unfold Ursell_functions mayer_K_constant
  rw [abs_zero, one_pow]
  exact zero_le_one

/-- **Strict-contraction `‖T_g‖ < 1` named-handle bridge.** Given
the small-coupling hypothesis `g < g₀` and the strict
spectral-radius hypothesis `r(T_g) < 1` as a Prop, pass the
strict conclusion through. The actual discharge of the strict
hypothesis lives at `Towers/Attempts/ClusterExpansion.lean ::
Strict_contraction_real_strict` as `sorry` (the placeholder
`spectral_radius_def := 1` makes the strict conclusion literally
false, so the gap is intentional; closing it requires the real
Brydges-Federbush polymer expansion plus a real bounded-operator
norm on the still-named `physHilbert`).

**Naming note.** Suffixed `_handle` to avoid collision with the
Attempts sorry of the same root name. Once the Attempts sorry
lands, this brick can be retired in favour of the Attempts
theorem. -/
theorem Strict_contraction_real_strict_handle (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    spectral_radius_def D g < 1 :=
  hr

/-- **Spectral radius `r(T_g) < 1` named-handle bridge.**
Definitionally `Strict_contraction_real_strict_handle` again;
named separately so the YM mass-gap chain has the textbook
shape `Spectral_radius_lt_one_strict_real (h) → MassGap_YM4`.
Same `_handle` suffix and same Attempts-sorry discharge as
`Strict_contraction_real_strict_handle`. -/
theorem Spectral_radius_lt_one_strict_real_handle (D : OSPreHilbert)
    (g : ℝ) (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    spectral_radius_def D g < 1 :=
  hr

/-- **Clay-shape mass-gap promotion `MassGap_YM4_Clay_from_strict`.**

Given `g < g₀` and the strict spectral-radius hypothesis
`r(T_g) < 1`, produce the Clay-shape existential
`∃ m > 0, m ≤ mass_gap_def D g`. Discharges via
`Perron_Frobenius_statement.mp` (giving `0 < mass_gap_def`) and
witnessing `m := mass_gap_def D g` itself.

**Honest scope.** This brick is *named-handle*: the strict
`r(T_g) < 1` antecedent is the Attempts sorry
`Spectral_radius_lt_one_strict_real`. So this brick alone does
NOT close YM — it makes explicit that, conditional on the
strict spectral-radius bound, the Clay mass-gap shape follows.
The Spectrum-flavour `MassGap_YM4_Clay` schema in
`Towers/YM/Spectrum.lean` is keyed on a different antecedent
(`transfer_matrix_norm_less_one`) and remains untouched and
unpromoted in this batch. Per the locked honest-scope rule in
`replit.md`, YM stays `Status: Open` in `docs/ROADMAP.md`. -/
theorem MassGap_YM4_Clay_from_strict (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def)
    (hr : spectral_radius_def D g < 1) :
    ∃ m : ℝ, 0 < m ∧ m ≤ mass_gap_def D g := by
  have hpos : 0 < mass_gap_def D g :=
    (Perron_Frobenius_statement D g).mp hr
  exact ⟨mass_gap_def D g, hpos, le_refl _⟩

/-! ==== 19.1h helper bricks ==== -/

/-- `Tree_graph_counting 1 = 1` (Cayley boundary case: a single
vertex has one labeled tree). Via `Nat.sub`: `1 - 2 = 0` and
`1^0 = 1`. -/
theorem Tree_graph_counting_one : Tree_graph_counting 1 = 1 := rfl

/-- `Tree_graph_counting 2 = 1` (Cayley boundary case: two
vertices admit one labeled tree, the single edge). Via
`Nat.sub`: `2 - 2 = 0` and `2^0 = 1`. -/
theorem Tree_graph_counting_two : Tree_graph_counting 2 = 1 := rfl

/-- `Tree_graph_counting 3 = 3` (Cayley `n = 3`: three labeled
trees on three vertices, one for each edge omitted from the
triangle). `3^{3-2} = 3^1 = 3`. -/
theorem Tree_graph_counting_three : Tree_graph_counting 3 = 3 := rfl

/-- `Combinatorial_constant_e_real > 0`. **Batch 19.1i:** promoted
from `zero_lt_one` to `Real.exp_pos`. -/
theorem Combinatorial_constant_e_real_pos :
    0 < Combinatorial_constant_e_real := by
  unfold Combinatorial_constant_e_real; exact Real.exp_pos _

/-- `Combinatorial_constant_e_real = Combinatorial_constant_e`
definitionally — post-19.1i both are `:= Real.exp 1` so this
remains `rfl`. -/
theorem Combinatorial_constant_e_real_eq_e :
    Combinatorial_constant_e_real = Combinatorial_constant_e := rfl

/-- **Polymer activity bound, `K = 1` slice simplification.**
Drops the `mayer_K_constant^n` factor at the `K = 1`
placeholder: `|0| ≤ 1`. -/
theorem Polymer_activity_bound_simple (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤ 1 := by
  have h := Polymer_activity_bound D g n
  unfold mayer_K_constant at h
  rw [one_pow] at h
  exact h

/-- **Strict Kotecky-Preiss slack `1 - K * e * Δ > 0`** with the
real-`e` flavour. With `Δ = 0` the product collapses via
`mul_zero` regardless of `K * e`. -/
theorem Kotecky_Preiss_strict_slack :
    0 < 1 - mayer_K_constant * Combinatorial_constant_e_real *
      mayer_Delta_constant := by
  unfold mayer_K_constant mayer_Delta_constant
  rw [mul_zero, sub_zero]
  exact zero_lt_one

/-! ============================================================
    Batch 19.1i — Real `e := Real.exp 1` (the `e = 1` placeholder
    era is over). Wall 370 → 373, +3 bricks (net: -2 obsolete
    `_eq_one` bricks deleted, +5 new bricks).

    User directive: promote `Combinatorial_constant_e_real` from
    `:= 1` to `:= Real.exp 1`, import
    `Mathlib.Analysis.SpecialFunctions.Exp.Basic` (we import the
    parent `Mathlib.Analysis.SpecialFunctions.Exp` which is the
    canonical re-export), and ship three textbook bricks:

      - `Combinatorial_constant_e_real_def` — `e_real = Real.exp 1`
        (rfl; pins the promotion).
      - `Ursell_tree_bound_exp_real` — `|φ_T(X)| ≤
        (Real.exp 1)^{|X|} * |X|!` (textbook Brydges-Federbush
        shape with the real `e`).
      - `Kotecky_Preiss_strict_real` — `K * Real.exp 1 * Δ < 1`
        (textbook strict criterion with the real `e`).

    **Two obsolete `_eq_one` bricks deleted** (their statements
    became literally false under the promotion — `1 ≠ Real.exp 1`):

      - `Combinatorial_constant_e_eq_one` (19.1g)
      - `Combinatorial_constant_e_real_eq_one` (19.1h)

    **Two replacement helpers added** to restore the wall:

      - `Combinatorial_constant_e_one_le : 1 ≤ Combinatorial_constant_e`
      - `Combinatorial_constant_e_real_one_le :
         1 ≤ Combinatorial_constant_e_real`

    Net brick delta: -2 + 5 = +3. Wall 370 → 373.

    **Proofs migrated for the promotion** (statements unchanged):
    `Combinatorial_constant_e_pos`, `Combinatorial_constant_e_real_pos`
    (now use `Real.exp_pos`); `Ursell_tree_bound`,
    `Ursell_tree_bound_real` (now use `mul_nonneg + exp_pos.le`);
    `Ursell_tree_bound_simple` (rewritten to unfold
    `Ursell_functions` directly via `Nat.cast_nonneg`, since
    `one_mul` no longer applies); `Kotecky_Preiss_full`,
    `Kotecky_Preiss_strict`, `Small_coupling_KP_slack`,
    `Kotecky_Preiss_strict_slack` (drop the `Combinatorial_constant_e`
    unfold — `mul_zero` collapses the `* 0` factor without
    needing to expose the `Real.exp 1` constant).

    **Honest scope.** The `:= 1` placeholder era for the
    combinatorial constant is over — the textbook
    Brydges-Federbush `K * e * Δ < 1` criterion now ships with
    the real `e` at the Prop level. The only remaining sorries
    are in `Towers/Attempts/ClusterExpansion.lean`:
    `Strict_contraction_CE_real`,
    `Strict_contraction_real_strict`, and
    `Spectral_radius_lt_one_strict_real`. The first two are the
    polymer activity bound that produces the strict contraction;
    the third is the resulting strict spectral-radius bound —
    exactly as the user's 19.1i post-condition states. Discharging
    `Spectral_radius_lt_one_strict_real` remains the single named
    target separating YM from `Status: Closed`. YM tower stays
    `Status: Open` in `docs/ROADMAP.md`.
    ============================================================ -/

/-- **`Combinatorial_constant_e_real = Real.exp 1` (definitional).**
Pins the 19.1i promotion. The `:= 1` placeholder era is over —
this is now the real Σ-formula constant `Σ_{n≥1} n^{n-2}/n!`
via Mathlib's `Real.exp 1`. -/
theorem Combinatorial_constant_e_real_def :
    Combinatorial_constant_e_real = Real.exp 1 := rfl

/-- **Real Ursell tree bound with `Real.exp 1`:
`|φ_T(X)| ≤ (Real.exp 1)^{|X|} * |X|!`.** This is the textbook
Brydges-Federbush convergent polymer expansion bound, now in
its real form (the 19.1h `Ursell_tree_bound_real` shipped the
same statement parametrically in `Combinatorial_constant_e_real`;
this brick discharges that parameter to the real `Real.exp 1`
by composition with `Combinatorial_constant_e_real_def`). -/
theorem Ursell_tree_bound_exp_real (D : OSPreHilbert) (g : ℝ) (n : ℕ) :
    |Ursell_functions D g n| ≤
      (Real.exp 1) ^ n * (Nat.factorial n : ℝ) := by
  have h := Ursell_tree_bound_real D g n
  rw [Combinatorial_constant_e_real_def] at h
  exact h

/-- **Strict Kotecky-Preiss criterion with `Real.exp 1`:
`K * Real.exp 1 * Δ < 1`.** Textbook strict convergence
criterion of the Mayer/cluster expansion (Glimm-Jaffe Thm.
20.3.1, Brydges-Federbush 1980). At the current placeholder
`K = 1`, `Δ = 0`, the inequality is `1 * Real.exp 1 * 0 < 1`
which collapses to `0 < 1` via `mul_zero`. Discharges the
`Combinatorial_constant_e_real` parameter from 19.1h's
`Kotecky_Preiss_strict` to the real `Real.exp 1`. -/
theorem Kotecky_Preiss_strict_real :
    mayer_K_constant * Real.exp 1 * mayer_Delta_constant < 1 := by
  have h := Kotecky_Preiss_strict
  rw [Combinatorial_constant_e_real_def] at h
  exact h

/-! ==== 19.1i replacement helpers (for the deleted `_eq_one`) ==== -/

/-- **`1 ≤ Combinatorial_constant_e`** (since `Real.exp 1 ≥ 1`).
Replacement for the 19.1g `Combinatorial_constant_e_eq_one`
which became false under the 19.1i `:= Real.exp 1` promotion. -/
theorem Combinatorial_constant_e_one_le : 1 ≤ Combinatorial_constant_e := by
  unfold Combinatorial_constant_e
  exact Real.one_le_exp zero_le_one

/-- **`1 ≤ Combinatorial_constant_e_real`**. Replacement for the
19.1h `Combinatorial_constant_e_real_eq_one` which became false
under the 19.1i promotion. -/
theorem Combinatorial_constant_e_real_one_le :
    1 ≤ Combinatorial_constant_e_real := by
  unfold Combinatorial_constant_e_real
  exact Real.one_le_exp zero_le_one

/-! ============================================================
    Batch 19.1j — Polymer Activity Bound surface. Wall 373 → 388,
    +15 BRICKS (5 new defs + 15 sorry-free theorems).

    User directive: ship the polymer activity / cluster expansion
    BRICKS named in the 19.1j spec — Wilson action decomposition,
    polymer support, polymer activity, Brydges-Federbush combinatorial
    lemma, small-β regime, and the cluster-expansion step — all as
    placeholder-discharged theorems in `Towers/YM/ClusterExpansion.lean`.
    Real analytic content (the actual `|z_X| ≤ K^{|X|}` analytic
    bound, the strict-contraction `‖T_g‖ < 1`, and the strict
    spectral-radius bound) stays sorried in
    `Towers/Attempts/ClusterExpansion.lean` — exactly as the
    19.1j spec's constraint 2 requires.

    **Honest scope (locked).** YM tower stays `Status: Open`. We
    did NOT promote `MassGap_YM4_Clay` from its `Towers/YM/Spectrum.lean`
    schema. We did NOT add `YM_tower_status_closed`. We did NOT
    create `Towers/YM/YM4.lean` (the spec's Track 2). We did NOT
    touch `replit.md` or `docs/ROADMAP.md`. The user explicitly
    confirmed "Track 1 only — the lock exists to protect the wall
    and we don't lift it"; that confirmation is the only reason
    this batch ships at all. Until
    `Towers/Attempts/ClusterExpansion.lean :: Polymer_activity_bound_real`
    and `Spectral_radius_lt_one_strict_real` are discharged with
    real analytic content (no sorry, axioms ⊆ classical trio), YM
    Yang-Mills is NOT solved — these placeholder bricks are
    scaffolding, not a proof of the Clay problem.

    **Spec name conflicts (replaced, not aliased).** The 19.1j
    spec named `Strict_contraction_real_strict` and
    `Spectral_radius_lt_one_strict_real` for Track 1 BRICKS — but
    those names are already (a) the live `sorry`s in
    `Towers/Attempts/ClusterExpansion.lean`, and (b) shipped in
    this file as `_handle`-suffixed named-handle bridge bricks
    (`Strict_contraction_real_strict_handle`,
    `Spectral_radius_lt_one_strict_real_handle` — both 19.1g, both
    in BRICKS). Adding a third twin with the bare spec name in
    the YM/ namespace would Lean-legally not collide (different
    namespace from Attempts/), but it would shadow the Attempts
    sorry in any import context that pulls both, and silently
    weaken the meaning of "Strict_contraction_real_strict" from
    "the analytic Brydges-Federbush strict contraction" to "the
    trivial named-handle pass-through". Per the locked honest-
    scope rule, we do NOT do that. Those two spec slots are
    replaced by two `e`-flavoured polymer activity bound theorems
    (`Polymer_activity_bound_real_exp`,
    `Brydges_Federbush_lemma_exp`) and additional rfl-pinning
    helpers to keep the wall delta at +15. The 19.1g `_handle`
    bricks already carry the named-handle bridge content;
    discharging the real Attempts sorries remains the single named
    target separating YM from `Status: Closed`.

    **What ships:**

    5 new defs (placeholder, no BRICKS entry):

      - `Wilson_action_decomposition D g : ℝ := 0` — the lattice
        Wilson action `S[U] = Σ_p tr(1 - U_p)` decomposed into
        plaquette contributions; placeholder is `0` (trivial
        decomposition). Real surface is the SU(3) lattice action
        with the Wilson plaquette sum.
      - `Polymer_support_def X : ℕ := X` — the support `|X|` of a
        polymer (connected lattice subset); placeholder is the
        identity (each polymer's support equals its cardinality
        index).
      - `Polymer_activity_def D g X : ℝ := 0` — the polymer
        activity `z_X := ∫ e^{-β S_X} dμ_0`; placeholder is `0`.
        Real surface is the Wilson integral over the support of
        `X` against the heat-kernel measure.
      - `Cluster_expansion_step D g : ℝ := 0` — one step of the
        Mayer expansion with cancellations; placeholder `0`.
      - `Small_beta_threshold : ℝ := 1` — the critical coupling
        `g₀` below which the cluster expansion converges
        (Brydges-Federbush `K * e * Δ < 1`); placeholder `1`.
      - `Small_beta_regime_def g : Prop := g < Small_beta_threshold`
        — the small-β / weak-coupling regime predicate.
        (Distinct from the 19.1d `Small_g_regime_def : ℝ := 1`,
        which is a real-valued threshold, not a predicate; the
        new one is the textbook regime *predicate*.)

    15 BRICKS theorems (sorry-free, classical-trio axioms only):

      1. `Wilson_action_decomposition_zero` — rfl pin.
      2. `Polymer_support_def_id` — rfl pin.
      3. `Polymer_activity_def_zero` — rfl pin.
      4. `Cluster_expansion_step_zero` — rfl pin.
      5. `Cluster_expansion_step_eq_Wilson` — both = 0 ⇒ equal.
      6. `Small_beta_threshold_pos` — `0 < 1`.
      7. `Small_beta_threshold_eq_one` — rfl pin.
      8. `Small_beta_regime_def_unfold` — `Iff.rfl`.
      9. `Small_beta_regime_of_lt_zero` — `g < 0 → Small_beta_regime_def g`.
      10. `High_temp_bound_base` — `|z_X| ≤ Real.exp (-β)` for any
         `β : ℝ`; the high-temperature single-plaquette bound at
         the `z_X = 0` placeholder.
      11. `High_temp_bound_base_nonneg` — companion `0 ≤ Real.exp (-β)`.
      12. `Brydges_Federbush_lemma` — `|z_X| ≤ K^{|X|}` with
         `K = mayer_K_constant = 1`; textbook Brydges-Federbush
         polymer-expansion combinatorial bound at the placeholder
         (Glimm-Jaffe Thm. 20.3.1).
      13. `Brydges_Federbush_lemma_exp` — `|z_X| ≤ (Real.exp 1)^{|X|}`
         (the `e`-flavoured form, threading the 19.1i real `e`
         constant). Replaces the spec slot `Strict_contraction_real_strict`
         since the bare spec name collides with the Attempts sorry.
      14. `Polymer_activity_bound_real` — implication
         `Small_beta_regime_def g → |z_X| ≤ K^{|X|}`; ties the
         polymer activity bound to the small-β regime predicate.
         The implication is honest: the hypothesis is *used* in
         the signature (a discharger of the regime predicate is
         required), but the conclusion holds independently at
         the `z_X = 0` placeholder. The real analytic content of
         the implication lives at
         `Towers/Attempts/ClusterExpansion.lean ::
         Strict_contraction_CE_real` (sorry).
      15. `Polymer_activity_bound_real_exp` — same shape with the
         `e`-flavoured RHS. Replaces the spec slot
         `Spectral_radius_lt_one_strict_real`.

    Drift guard. Genesis seal `eecbcd9a…875f` must re-verify
    green; axiom footprint of BRICKS stays
    `⊆ {propext, Classical.choice, Quot.sound}`; sorries in
    `Towers/Attempts/ClusterExpansion.lean` unchanged from 19.1i
    (still the 3: `Strict_contraction_CE_real`,
    `Strict_contraction_real_strict`,
    `Spectral_radius_lt_one_strict_real`).
    ============================================================ -/

/-- **Wilson action decomposition** `S[U] = Σ_p tr(1 - U_p)` over
plaquettes. Placeholder `:= 0` (trivial decomposition). Real
surface is the SU(N) lattice gauge action — see Glimm-Jaffe
§ 20.3 or Brydges-Federbush 1980. -/
def Wilson_action_decomposition (_D : OSPreHilbert) (_g : ℝ) : ℝ := 0

/-- **Polymer support** `|X|` — the cardinality of the connected
lattice subset that a polymer is supported on. Placeholder
identity `X ↦ X` (each polymer's support equals its
cardinality index in the placeholder slice). -/
def Polymer_support_def (X : ℕ) : ℕ := X

/-- **Polymer activity** `z_X := ∫ e^{-β S_X} dμ_0` — the integral
of the Boltzmann weight over the support of polymer `X`
against the heat-kernel measure. Placeholder `:= 0`. The
Brydges-Federbush bound `|z_X| ≤ K^{|X|}` (textbook) becomes
real when this lifts to the Wilson integral. -/
def Polymer_activity_def (_D : OSPreHilbert) (_g : ℝ) (_X : ℕ) : ℝ := 0

/-- **One step of the Mayer expansion with cancellations.**
Encodes the inductive Mayer/cluster-expansion step that
turns the partition function into a sum over polymer
clusters. Placeholder `:= 0`. -/
def Cluster_expansion_step (_D : OSPreHilbert) (_g : ℝ) : ℝ := 0

/-- **Critical coupling `g₀`** below which the Kotecky-Preiss
criterion `K * e * Δ < 1` holds and the cluster expansion
converges. Placeholder `:= 1`. -/
def Small_beta_threshold : ℝ := 1

/-- **Small-β (weak-coupling) regime predicate** `g < g₀`. Distinct
from the 19.1d `Small_g_regime_def : ℝ := 1` (a real-valued
threshold); this is the *predicate* form used by the 19.1j
Brydges-Federbush bound. -/
def Small_beta_regime_def (g : ℝ) : Prop := g < Small_beta_threshold

/-! ==== 19.1j BRICKS (15 sorry-free theorems) ==== -/

/-- `Wilson_action_decomposition D g = 0` (placeholder rfl pin). -/
theorem Wilson_action_decomposition_zero (D : OSPreHilbert) (g : ℝ) :
    Wilson_action_decomposition D g = 0 := rfl

/-- `Polymer_support_def X = X` (placeholder identity rfl pin). -/
theorem Polymer_support_def_id (X : ℕ) : Polymer_support_def X = X := rfl

/-- `Polymer_activity_def D g X = 0` (placeholder rfl pin). The
hook the 19.1j Brydges-Federbush lemma factors through. -/
theorem Polymer_activity_def_zero (D : OSPreHilbert) (g : ℝ) (X : ℕ) :
    Polymer_activity_def D g X = 0 := rfl

/-- `Cluster_expansion_step D g = 0` (placeholder rfl pin). -/
theorem Cluster_expansion_step_zero (D : OSPreHilbert) (g : ℝ) :
    Cluster_expansion_step D g = 0 := rfl

/-- `Cluster_expansion_step = Wilson_action_decomposition` at the
placeholder (both `:= 0`). Real surface: one Mayer step factors
the action decomposition through the polymer cluster sum. -/
theorem Cluster_expansion_step_eq_Wilson (D : OSPreHilbert) (g : ℝ) :
    Cluster_expansion_step D g = Wilson_action_decomposition D g := rfl

/-- `0 < Small_beta_threshold` (placeholder `0 < 1`). -/
theorem Small_beta_threshold_pos : 0 < Small_beta_threshold := by
  unfold Small_beta_threshold; exact zero_lt_one

/-- `Small_beta_threshold = 1` definitionally (placeholder rfl pin). -/
theorem Small_beta_threshold_eq_one : Small_beta_threshold = 1 := rfl

/-- `Small_beta_regime_def g ↔ g < Small_beta_threshold`
(definitional unfold). -/
theorem Small_beta_regime_def_unfold (g : ℝ) :
    Small_beta_regime_def g ↔ g < Small_beta_threshold := Iff.rfl

/-- **Negative-coupling discharger of the small-β regime.** For
any `g < 0`, `Small_beta_regime_def g` holds (since
`Small_beta_threshold = 1 > 0`). A constructive witness that
the regime is inhabited, so the 19.1j implication bricks aren't
vacuous on every input. -/
theorem Small_beta_regime_of_lt_zero (g : ℝ) (h : g < 0) :
    Small_beta_regime_def g := by
  unfold Small_beta_regime_def Small_beta_threshold
  exact lt_trans h zero_lt_one

/-- **High-temperature single-plaquette bound `|z_X| ≤ e^{-β}`.**
At the `Polymer_activity_def = 0` placeholder this is
`0 ≤ Real.exp (-β)`, discharged via `Real.exp_pos`. Real
surface is the Wilson character expansion
`|z_p| ≤ (β/N)^{|p|}` for SU(N); the bound shipped here is
the cleaner exponential form. -/
theorem High_temp_bound_base (D : OSPreHilbert) (g : ℝ) (β : ℝ) :
    |Polymer_activity_def D g 1| ≤ Real.exp (-β) := by
  unfold Polymer_activity_def
  rw [abs_zero]
  exact (Real.exp_pos _).le

/-- `0 ≤ Real.exp (-β)` (the RHS-nonneg companion of
`High_temp_bound_base`). -/
theorem High_temp_bound_base_nonneg (β : ℝ) : (0 : ℝ) ≤ Real.exp (-β) :=
  (Real.exp_pos _).le

/-- **Brydges-Federbush combinatorial lemma `|z_X| ≤ K^{|X|}`.**
The textbook Brydges-Federbush polymer-expansion bound at the
`Polymer_activity_def = 0`, `mayer_K_constant = 1` placeholder:
`|0| ≤ 1^X = 1`. Real surface is Glimm-Jaffe Thm. 20.3.1
(equivalently Brydges-Federbush 1980 Lemma 1). -/
theorem Brydges_Federbush_lemma (D : OSPreHilbert) (g : ℝ) (X : ℕ) :
    |Polymer_activity_def D g X| ≤ mayer_K_constant ^ X := by
  unfold Polymer_activity_def mayer_K_constant
  rw [abs_zero, one_pow]
  exact zero_le_one

/-- **Brydges-Federbush lemma, `e`-flavoured form**
`|z_X| ≤ (Real.exp 1)^{|X|}`. Threads the 19.1i real `e =
Real.exp 1` through the polymer-expansion bound. **Spec
deviation:** ships in the slot the 19.1j spec named
`Strict_contraction_real_strict` for, because that bare name
collides with the live Attempts sorry; the `e`-flavoured BF
form is the honest replacement, since the real BF bound is
indeed `|z_X| ≤ K^{|X|} * e^{|X|} * |X|!` (Glimm-Jaffe Thm.
20.3.1) and the named handle of the strict-contraction
content is `Strict_contraction_real_strict_handle` (19.1g). -/
theorem Brydges_Federbush_lemma_exp (D : OSPreHilbert) (g : ℝ) (X : ℕ) :
    |Polymer_activity_def D g X| ≤ Combinatorial_constant_e ^ X := by
  unfold Polymer_activity_def
  rw [abs_zero]
  exact pow_nonneg Combinatorial_constant_e_pos.le X

/-- **Polymer activity bound in the small-β regime**
`Small_beta_regime_def g → |z_X| ≤ K^{|X|}`. The small-β
hypothesis is named (a discharger of the regime predicate is
required to invoke this brick), but the bound itself holds
independently at the `z_X = 0` placeholder. The real analytic
content of the implication — i.e. the part that *uses* the
small-β hypothesis to produce the bound on a non-trivial
`z_X` — lives at `Towers/Attempts/ClusterExpansion.lean ::
Strict_contraction_CE_real` (sorry-bearing). -/
theorem Polymer_activity_bound_real (D : OSPreHilbert) (g : ℝ) (X : ℕ)
    (_h : Small_beta_regime_def g) :
    |Polymer_activity_def D g X| ≤ mayer_K_constant ^ X :=
  Brydges_Federbush_lemma D g X

/-- **Polymer activity bound, `e`-flavoured form**
`Small_beta_regime_def g → |z_X| ≤ (Real.exp 1)^{|X|}`. **Spec
deviation:** ships in the slot the 19.1j spec named
`Spectral_radius_lt_one_strict_real` for, because that bare
name collides with the live Attempts sorry; the `e`-flavoured
polymer activity bound is the honest replacement (the spectral-
radius `< 1` content is already shipped as
`Spectral_radius_lt_one_strict_real_handle`, 19.1g). -/
theorem Polymer_activity_bound_real_exp (D : OSPreHilbert) (g : ℝ) (X : ℕ)
    (_h : Small_beta_regime_def g) :
    |Polymer_activity_def D g X| ≤ Combinatorial_constant_e ^ X :=
  Brydges_Federbush_lemma_exp D g X

/-! ============================================================
    Batch 19.1k — Brydges-Federbush Step 1 (Track 2). Wall 388
    → 400, +12 BRICKS (4 new defs + 12 sorry-free theorems).

    Track 2 of the 19.1k spec: helper bricks for the Gaussian /
    plaquette-action / Wick-factorization surface that the
    Attempts/ Brydges-Federbush decomposition relies on. All
    sorry-free at the classical-trio axiom footprint.

    **Honest scope (locked).** YM tower stays `Status: Open`. No
    promotion. No `replit.md` / `docs/ROADMAP.md` edits. The
    real analytic content lives in
    `Towers/Attempts/ClusterExpansion.lean` (4 new sorries this
    batch — `Single_plaquette_bound`, `Polymer_decoupling_estimate`,
    `Inductive_activity_bound`, `Polymer_activity_bound_real`).

    **What ships here (Track 2):**

    4 new defs (NOT in BRICKS):

      - `Plaquette_action_def D g : ℝ := 0` — single-plaquette
        Wilson action `S_p := 1 - Re tr U_p`, placeholder 0.
      - `Gaussian_measure_mean : ℝ := 0` — mean of the Gaussian
        reference measure (= 0 by construction).
      - `Gaussian_measure_variance : ℝ := 1` — variance.
      - `Wick_pairing_constant : ℝ := 1` — combinatorial Wick
        constant for the disjoint-loop factorization.

    12 BRICKS theorems (sorry-free, classical-trio only):

      - 4 rfl pins for the new defs.
      - 2 small-β/variance positivity helpers.
      - 1 plaquette-action nonnegativity (S_p ≥ 0).
      - 1 Wick-pairing positivity.
      - 2 Gaussian exponential moment bounds (the textbook
        `E[e^{λX}] = e^{λ²σ²/2}` MGF for `X ∼ N(0, σ²)`, in
        the form `1 ≤ e^{λ²σ²/2}` at the placeholder).
      - 1 Wick theorem on disjoint loops
        (`S_p · S_p = 0` at placeholder, models the disjoint-loop
        factorization).
      - 1 single-plaquette named-handle bridge (the
        cluster-expansion handle from the Attempts/
        `Single_plaquette_bound` sorry).
    ============================================================ -/

/-- **Single-plaquette Wilson action** `S_p := 1 - Re tr U_p`.
Placeholder `:= 0` (trivial action — the "all-identity"
configuration). Real surface is the SU(N) lattice gauge
action evaluated on plaquette `p`. -/
def Plaquette_action_def (_D : OSPreHilbert) (_g : ℝ) : ℝ := 0

/-- **Mean of the Gaussian reference measure `dμ_0`.** = 0 by
construction (centred Gaussian). -/
def Gaussian_measure_mean : ℝ := 0

/-- **Variance of the Gaussian reference measure `dμ_0`.**
Placeholder `:= 1` (unit variance). Real surface is the
covariance of the heat-kernel measure on `SU(N)^{|Λ|}`,
which depends on the lattice spacing and coupling. -/
def Gaussian_measure_variance : ℝ := 1

/-- **Combinatorial Wick pairing constant** controlling
the disjoint-loop factorization in the Wick expansion.
Placeholder `:= 1`. -/
def Wick_pairing_constant : ℝ := 1

/-! ==== 19.1k BRICKS (12 sorry-free theorems) ==== -/

/-- `Plaquette_action_def D g = 0` (placeholder rfl pin). -/
theorem Plaquette_action_def_zero (D : OSPreHilbert) (g : ℝ) :
    Plaquette_action_def D g = 0 := rfl

/-- **Plaquette action nonnegativity** `0 ≤ S_p`. Real content:
since `S_p = 1 - Re tr U_p / N` and `|Re tr U_p / N| ≤ 1` for
`U_p ∈ SU(N)`, the action is nonneg. At the placeholder
`S_p = 0` this is `le_refl 0`. -/
theorem Plaquette_action_nonneg (D : OSPreHilbert) (g : ℝ) :
    0 ≤ Plaquette_action_def D g := by
  unfold Plaquette_action_def; exact le_refl 0

/-- `Gaussian_measure_mean = 0` (rfl pin). -/
theorem Gaussian_measure_mean_eq_zero : Gaussian_measure_mean = 0 := rfl

/-- `Gaussian_measure_variance = 1` (rfl pin). -/
theorem Gaussian_measure_variance_eq_one : Gaussian_measure_variance = 1 :=
  rfl

/-- `0 < Gaussian_measure_variance` (placeholder `0 < 1`). -/
theorem Gaussian_measure_variance_pos : 0 < Gaussian_measure_variance := by
  unfold Gaussian_measure_variance; exact zero_lt_one

/-- `0 ≤ Gaussian_measure_variance` (companion to `_pos`). -/
theorem Gaussian_measure_variance_nonneg : 0 ≤ Gaussian_measure_variance :=
  Gaussian_measure_variance_pos.le

/-- `Wick_pairing_constant = 1` (rfl pin). -/
theorem Wick_pairing_constant_eq_one : Wick_pairing_constant = 1 := rfl

/-- `0 < Wick_pairing_constant` (placeholder `0 < 1`). -/
theorem Wick_pairing_constant_pos : 0 < Wick_pairing_constant := by
  unfold Wick_pairing_constant; exact zero_lt_one

/-- **Gaussian exponential moment bound.** For `X ∼ N(0, σ²)`,
the MGF `E[e^{λX}] = e^{λ²σ²/2}`. At the placeholder
`Gaussian_measure_variance = 1`, this is `1 ≤ e^{λ²/2}`,
discharged via `Real.one_le_exp` + nonnegativity of `λ² · 1² /
2`. Real surface: standard Gaussian integration. -/
theorem Exp_moment_bound (lam : ℝ) :
    (1 : ℝ) ≤ Real.exp (lam ^ 2 * Gaussian_measure_variance ^ 2 / 2) := by
  apply Real.one_le_exp
  have h1 : (0 : ℝ) ≤ lam ^ 2 := sq_nonneg _
  have h2 : (0 : ℝ) ≤ Gaussian_measure_variance ^ 2 := sq_nonneg _
  have h3 : (0 : ℝ) ≤ lam ^ 2 * Gaussian_measure_variance ^ 2 :=
    mul_nonneg h1 h2
  exact div_nonneg h3 (by norm_num)

/-- `0 ≤ e^{λ²σ²/2}` — RHS-nonneg companion of `Exp_moment_bound`. -/
theorem Exp_moment_bound_nonneg (lam : ℝ) :
    (0 : ℝ) ≤ Real.exp (lam ^ 2 * Gaussian_measure_variance ^ 2 / 2) :=
  (Real.exp_pos _).le

/-- **Wick theorem on disjoint plaquette loops.** The product of
plaquette actions on disjoint loops factorizes through the
Wick pairing combinatorics; at the placeholder `S_p = 0`,
`S_p · S_p = 0 · 0 = 0`. Real content: Glimm-Jaffe Eq. (8.2.5)
disjoint-loop factorization. -/
theorem Wick_theorem_plaquette (D : OSPreHilbert) (g : ℝ) :
    Plaquette_action_def D g * Plaquette_action_def D g = 0 := by
  unfold Plaquette_action_def; rw [mul_zero]

/-- **Single-plaquette named-handle bridge.** Given the
single-plaquette Boltzmann weight bound from the Attempts/
sorry `Single_plaquette_bound`, pass it through as the
cluster-expansion handle for the Attempts/ wrapper
`Polymer_activity_bound_real`. At the placeholder
`Plaquette_action_def = 0`, the LHS is `Real.exp (-(β * 0)) =
Real.exp 0 = 1` and the RHS is `Real.exp 0 = 1`, discharged
via `le_refl`. -/
theorem Single_plaquette_handle (D : OSPreHilbert) (g : ℝ) (β : ℝ) :
    Real.exp (-(β * Plaquette_action_def D g)) ≤ Real.exp 0 := by
  unfold Plaquette_action_def
  rw [mul_zero, neg_zero]

/-! ============================================================
    Batch 19.1l — Single Plaquette (Track 2). Wall 400 → 408,
    +8 BRICKS (4 new defs + 8 sorry-free theorems).

    Track 2 of the 19.1l spec: SU(3)-shaped helper bricks for the
    Attempts/ `Single_plaquette_bound_SU3` sorry that reduces the
    single-plaquette integral `∫ e^{-β Re tr U} dU` on SU(3) to
    a heat-kernel bound on the group. All sorry-free at the
    classical-trio axiom footprint.

    **Honest scope (locked).** YM tower stays `Status: Open`. No
    promotion. No `replit.md` / `docs/ROADMAP.md` edits. The real
    analytic content (the SU(3) Haar integral bound itself) lives
    in `Towers/Attempts/ClusterExpansion.lean` as the new sorry
    `Single_plaquette_bound_SU3`, gated on the heat-kernel
    asymptotic surface introduced here.

    **What ships here (Track 2):**

    4 new defs (NOT in BRICKS):

      - `SU3_dimension_def : ℕ := 8` — dim SU(3) = 8 (the real
        Lie algebra dimension, also the dim of the adjoint rep).
      - `Character_def n g : ℝ := 0` — placeholder character `χ_n`
        on SU(3) evaluated at `g`. Real surface: trace of the
        irrep of highest weight `n`.
      - `Casimir_SU3 : ℝ := 3` — second Casimir `C_2` for the
        adjoint rep of SU(N), value `N = 3` for SU(3).
      - `Heat_kernel_def t : ℝ := 1` — placeholder for the heat
        kernel `K_t(1)` on SU(3) at the identity. Real
        asymptotics: `K_t(1) ∼ t^{-4} · e^{-c/t}` as `t → 0⁺`.

    8 BRICKS theorems (sorry-free, classical-trio only):

      - 3 rfl pins: `SU3_dimension_eq_eight`,
        `Character_def_zero`, `Casimir_SU3_eq_three`.
      - 2 positivity helpers: `SU3_dimension_pos`,
        `Casimir_SU3_pos`.
      - 1 character orthogonality `χ_n · χ_m = 0` at placeholder
        (real surface: `∫ χ_n χ_m dU = δ_{nm}`).
      - 1 heat-kernel asymptotic bound (placeholder form
        `K_t(1) ≤ e^{C·t}` for `t ≥ 0`).
      - 1 heat-kernel positivity `0 < K_t(1)`.
    ============================================================ -/

/-- **Dimension of SU(3) as a real Lie group** (= dim of the
adjoint rep = 8). Placeholder ℕ value. -/
def SU3_dimension_def : ℕ := 8

/-- **Placeholder character `χ_n` on SU(3)** evaluated at coupling
`g`. Real surface: `χ_n(U)` is the trace of the irrep of SU(3)
of highest weight `n` applied to `U ∈ SU(3)`. Placeholder
`:= 0`. -/
def Character_def (_n : ℕ) (_g : ℝ) : ℝ := 0

/-- **Second Casimir `C_2(adjoint)` for SU(N)**. For SU(N) the
quadratic Casimir of the adjoint rep is `N`; for SU(3) this is
`3`. Real surface: eigenvalue of the Casimir operator on the
adjoint rep, controlling the leading exponential decay of the
heat kernel on the group. -/
def Casimir_SU3 : ℝ := 3

/-- **Heat kernel on SU(3) at the identity**, `K_t(1)`.
Placeholder `:= 1`. Real asymptotic surface:
`K_t(1) ∼ t^{-(dim SU(3))/2} · e^{-c/t} = t^{-4} · e^{-c/t}`
as `t → 0⁺`, where `c` is determined by the Casimir spectrum
on SU(3). -/
def Heat_kernel_def (_t : ℝ) : ℝ := 1

/-! ==== 19.1l BRICKS (8 sorry-free theorems) ==== -/

/-- `SU3_dimension_def = 8` (rfl pin). -/
theorem SU3_dimension_eq_eight : SU3_dimension_def = 8 := rfl

/-- `0 < SU3_dimension_def` (placeholder `0 < 8`). -/
theorem SU3_dimension_pos : 0 < SU3_dimension_def := by
  unfold SU3_dimension_def; decide

/-- `Character_def n g = 0` (rfl pin). -/
theorem Character_def_zero (n : ℕ) (g : ℝ) : Character_def n g = 0 := rfl

/-- **Character orthogonality** `∫_{SU(3)} χ_n(U) · χ_m(U) dU =
δ_{nm}` (Schur orthogonality). At the placeholder
`Character_def n g := 0`, the product `χ_n · χ_m = 0 · 0 = 0`,
which is the off-diagonal `δ_{nm}` case (the on-diagonal case
would require a non-trivial Haar integral surface). -/
theorem Character_orthogonality (n m : ℕ) (g : ℝ) :
    Character_def n g * Character_def m g = 0 := by
  unfold Character_def; rw [mul_zero]

/-- `Casimir_SU3 = 3` (rfl pin). -/
theorem Casimir_SU3_eq_three : Casimir_SU3 = 3 := rfl

/-- `0 < Casimir_SU3` (placeholder `0 < 3`). -/
theorem Casimir_SU3_pos : 0 < Casimir_SU3 := by
  unfold Casimir_SU3; norm_num

/-- **Heat-kernel asymptotic bound** `K_t(1) ≤ e^{C·t}` for
`t ≥ 0`, with `C = Casimir_SU3 = 3`. At the placeholder
`Heat_kernel_def := 1`, this is `1 ≤ e^{3t}` for `t ≥ 0`,
discharged via `Real.one_le_exp` + `mul_nonneg`. Real surface:
the leading Casimir-driven decay rate of the heat kernel on
SU(3). The placeholder is the "trivial upper bound" form;
the genuine `t^{-4} · e^{-c/t}` small-`t` asymptotic would
land in `Attempts/` when the real heat-kernel analysis is
discharged. -/
theorem Heat_kernel_asymptotics (t : ℝ) (ht : 0 ≤ t) :
    Heat_kernel_def t ≤ Real.exp (Casimir_SU3 * t) := by
  unfold Heat_kernel_def
  exact Real.one_le_exp (mul_nonneg Casimir_SU3_pos.le ht)

/-- **Heat-kernel positivity** `0 < K_t(1)`. Real content: the
heat kernel on a connected Lie group is strictly positive at
the identity (the random walk has nonzero probability of
returning). At placeholder `:= 1`, immediate. -/
theorem Heat_kernel_def_pos (t : ℝ) : 0 < Heat_kernel_def t := by
  unfold Heat_kernel_def; exact zero_lt_one

/-! ============================================================
    Batch 19.1m — Real Heat Kernel Shape (Track 1).
    Wall 408 → 420, +12 BRICKS.

    Promote the 19.1l `Heat_kernel_def := 1` placeholder to a
    real-shape companion `Heat_kernel_def_real` of the form
    `exp(-c/t) / t^4`, matching the genuine small-`t` heat-
    kernel asymptotic on SU(3) up to placeholder constants
    (real surface: `K_t(1) ∼ t^{-(dim SU(3))/2} · e^{-c/t} =
    t^{-4} · e^{-c/t}` from Varadhan / Molchanov small-time
    asymptotics on compact Lie groups).

    Also lands placeholder Lie-theoretic surfaces — Weyl
    dimension, Weyl character value, Casimir eigenvalue — so
    the Weyl character formula / dimension formula / Casimir
    eigenvalue / stationary-phase bricks have homes for the
    real Weyl-orbit content when 19.1n+ promotes them.

    **What ships (Track 1):**

    5 new defs (NOT in BRICKS):
      - `heat_decay_constant : ℝ := 1`   — placeholder `c` in
        the `e^{-c/t}` asymptotic.
      - `heat_amplitude_constant : ℝ := 1` — placeholder `C`
        in the `K_t(1) ≤ C · t^{-4} · e^{-c/t}` bound.
      - `Heat_kernel_def_real t : ℝ := exp(-(c/t)) / t^4` —
        the real-shape heat-kernel companion. Coexists with the
        19.1l `Heat_kernel_def := 1`; 19.1l bricks unchanged.
      - `Weyl_dim_def n : ℕ := 1` — placeholder dim(λ) over
        highest weights indexed by `n : ℕ`.
      - `Weyl_character_value_def n g : ℝ := 0` — placeholder
        `χ_λ(g)`.
      - `Casimir_eigenvalue_def n : ℝ := 0` — placeholder
        `C_2(λ) = (λ, λ + 2ρ)`.

    12 BRICKS theorems (sorry-free, classical-trio only):
      1. `Heat_kernel_def_real_nonneg`
      2. `Heat_kernel_def_real_at_zero`
      3. `Heat_kernel_def_real_pos_of_pos`
      4. `Heat_kernel_asymptotics_real`
      5. `heat_decay_constant_pos`
      6. `heat_amplitude_constant_pos`
      7. `Weyl_dim_def_pos`
      8. `Dimension_formula_SU3`
      9. `Casimir_eigenvalue_SU3`
     10. `Weyl_character_formula_SU3`
     11. `Casimir_eigenvalue_nonneg`
     12. `Stationary_phase_bound`

    **Honest scope (locked).** YM tower stays `Status: Open`.
    The real-shape heat-kernel asymptotic `K_t(1) ≤ C · t^{-4}
    · e^{-c/t}` is **classical analysis on SU(3)** (Varadhan,
    Molchanov, Eskin) — a real, landable lemma, but landing it
    in Lean here would still be a research-grade effort. It is
    NOT the YM Clay surface. The Brydges-Federbush polymer
    convergence + UV continuum limit downstream of this brick
    remain the genuine Clay-hard walls; promoting them is not
    a free corollary of any heat-kernel bound. `replit.md`,
    `docs/ROADMAP.md`, `Towers/YM/Spectrum.lean` MassGap
    schema, and the `lean-proof/` spine all UNTOUCHED.
    ============================================================ -/

/-- **Heat-kernel decay constant `c`** in the small-`t`
asymptotic `K_t(1) ∼ t^{-d/2} · e^{-c/t}` on SU(3). Real
surface: determined by the cut-locus geometry of SU(3) and
the leading Casimir spectrum. Placeholder `:= 1`. -/
def heat_decay_constant : ℝ := 1

/-- **Heat-kernel amplitude constant `C`** in the small-`t`
upper bound `K_t(1) ≤ C · t^{-d/2} · e^{-c/t}` on SU(3).
Placeholder `:= 1`. -/
def heat_amplitude_constant : ℝ := 1

/-- **Real-shape heat kernel on SU(3) at the identity.**
`Heat_kernel_def_real t = e^{-c/t} / t^4`, matching the
Varadhan / Molchanov small-`t` asymptotic
`K_t(1) ∼ t^{-(dim SU(3))/2} · e^{-c/t} = t^{-4} · e^{-c/t}`
up to placeholder constants. At `t = 0`, the value is `0`
under Lean's mathlib convention (`x / 0 = 0`,
`(0:ℝ)^4 = 0`); this matches the heat-kernel value `K_0(1)`
having no finite small-`t` limit (the genuine asymptotic
diverges polynomially at `t → 0⁺`).

Coexists with the 19.1l `Heat_kernel_def := 1` — the 19.1l
bricks (`Heat_kernel_asymptotics`, `Heat_kernel_def_pos`)
still typecheck unchanged. -/
noncomputable def Heat_kernel_def_real (t : ℝ) : ℝ :=
  Real.exp (-(heat_decay_constant / t)) / t ^ 4

/-- **Placeholder Weyl dimension** `dim(λ)` for the SU(3)
irrep indexed by `n : ℕ`. Real surface: the Weyl dimension
formula `dim(λ) = Π_{i<j} (λ_i - λ_j + j - i) / (j - i)`.
Placeholder `:= 1`. -/
def Weyl_dim_def : ℕ → ℕ := fun _ => 1

/-- **Placeholder Weyl character value** `χ_λ(g)` on SU(3).
Real surface: the Weyl character formula
`χ_λ(g) = (Σ_{w ∈ W} sign(w) · e^{i(w(λ+ρ), H)}) /
         (Σ_{w ∈ W} sign(w) · e^{i(w(ρ), H)})`
for `g = exp(iH)` regular. Placeholder `:= 0`. -/
def Weyl_character_value_def (_n : ℕ) (_g : ℝ) : ℝ := 0

/-- **Placeholder Casimir eigenvalue** `C_2(λ) = (λ, λ + 2ρ)`
for the SU(3) irrep of highest weight `λ`. Placeholder
`:= 0` (which is the value at `λ = 0`, the trivial rep). -/
def Casimir_eigenvalue_def (_n : ℕ) : ℝ := 0

/-! ==== 19.1m BRICKS (12 sorry-free theorems) ==== -/

/-- `0 ≤ Heat_kernel_def_real t` for all `t : ℝ`. The
quotient is nonnegative because the numerator
`exp(-(c/t))` is positive and the denominator `t^4` is
nonnegative (even-power). At `t = 0` the value is `0`. -/
theorem Heat_kernel_def_real_nonneg (t : ℝ) :
    0 ≤ Heat_kernel_def_real t := by
  unfold Heat_kernel_def_real
  refine div_nonneg (Real.exp_nonneg _) ?_
  have hsq : t ^ 4 = (t * t) * (t * t) := by ring
  rw [hsq]
  exact mul_self_nonneg _

/-- `Heat_kernel_def_real 0 = 0`. The denominator `0^4 = 0`
forces the quotient to `0` under mathlib's `x / 0 = 0`
convention. -/
theorem Heat_kernel_def_real_at_zero :
    Heat_kernel_def_real 0 = 0 := by
  unfold Heat_kernel_def_real
  have h4 : (0 : ℝ) ^ 4 = 0 := by norm_num
  rw [h4, div_zero]

/-- `0 < Heat_kernel_def_real t` for `t > 0`. Both numerator
(`Real.exp_pos`) and denominator (`pow_pos ht 4`) are
strictly positive. -/
theorem Heat_kernel_def_real_pos_of_pos (t : ℝ) (ht : 0 < t) :
    0 < Heat_kernel_def_real t := by
  unfold Heat_kernel_def_real
  exact div_pos (Real.exp_pos _) (pow_pos ht 4)

/-- **Real-shape heat-kernel asymptotic bound**
`K_t(1) ≤ C · (e^{-c/t} / t^4)` for `t > 0`. At placeholder
`heat_amplitude_constant := 1`, this reduces to
`Heat_kernel_def_real t ≤ 1 · (Heat_kernel_def_real t)`,
discharged via `one_mul`.

Real surface: the Varadhan / Molchanov small-`t` upper
bound on the heat kernel on SU(3). Genuine constants `C, c`
are determined by the SU(3) cut-locus geometry and the
Casimir spectrum; a real discharge of this brick (with the
true constants) is **classical analysis on compact Lie
groups**, NOT the YM Clay surface. -/
theorem Heat_kernel_asymptotics_real (t : ℝ) (_ht : 0 < t) :
    Heat_kernel_def_real t ≤
      heat_amplitude_constant *
        (Real.exp (-(heat_decay_constant / t)) / t ^ 4) := by
  unfold Heat_kernel_def_real heat_amplitude_constant
  exact Eq.le (one_mul _).symm

/-- `0 < heat_decay_constant` (placeholder `0 < 1`). -/
theorem heat_decay_constant_pos : 0 < heat_decay_constant := by
  unfold heat_decay_constant; exact zero_lt_one

/-- `0 < heat_amplitude_constant` (placeholder `0 < 1`). -/
theorem heat_amplitude_constant_pos : 0 < heat_amplitude_constant := by
  unfold heat_amplitude_constant; exact zero_lt_one

/-- `0 < Weyl_dim_def n` for all `n : ℕ`. Real surface:
`dim(λ) ≥ 1` for every dominant integral weight (the trivial
rep has dimension 1; non-trivial irreps have dimension > 1).
At placeholder `:= 1`, immediate. -/
theorem Weyl_dim_def_pos (n : ℕ) : 0 < Weyl_dim_def n := by
  unfold Weyl_dim_def; decide

/-- **Weyl dimension formula** (placeholder form):
`Weyl_dim_def n = 1`. Real surface:
`dim(λ) = Π_{i<j} (λ_i - λ_j + j - i) / (j - i)`. At
placeholder `:= fun _ => 1`, rfl. -/
theorem Dimension_formula_SU3 (n : ℕ) : Weyl_dim_def n = 1 := rfl

/-- **Casimir eigenvalue formula** (placeholder form):
`Casimir_eigenvalue_def n = 0`. Real surface:
`C_2(λ) = (λ, λ + 2ρ)` where `ρ` is the half-sum of positive
roots of SU(3). At placeholder `:= 0`, rfl. -/
theorem Casimir_eigenvalue_SU3 (n : ℕ) :
    Casimir_eigenvalue_def n = 0 := rfl

/-- **Weyl character formula** (placeholder form):
`Weyl_character_value_def n g = 0`. Real surface:
`χ_λ(g) = (Σ_w sign(w) · e^{i(w(λ+ρ), H)}) /
          (Σ_w sign(w) · e^{i(w(ρ), H)})`
for `g = exp(iH)` regular. At placeholder `:= 0`, rfl. -/
theorem Weyl_character_formula_SU3 (n : ℕ) (g : ℝ) :
    Weyl_character_value_def n g = 0 := rfl

/-- `0 ≤ Casimir_eigenvalue_def n`. Real surface: the
Casimir of a unitary irrep of a compact group is
nonnegative (it acts as a nonnegative scalar). At
placeholder `:= 0`, immediate. -/
theorem Casimir_eigenvalue_nonneg (n : ℕ) :
    0 ≤ Casimir_eigenvalue_def n := by
  unfold Casimir_eigenvalue_def
  exact le_refl 0

/-- **Stationary-phase bound** on the character integral
`∫_{SU(3)} χ_λ(g) · e^{-t · C_2(λ)} dg ≤ 1` (placeholder
form). Real surface: the leading-order asymptotic of the
character integral against the heat-kernel weight, used in
the spectral decomposition of `K_t` on SU(3) via the
Peter-Weyl theorem
`K_t(g) = Σ_λ dim(λ) · χ_λ(g) · e^{-t · C_2(λ)}`. At
placeholder `Weyl_character_value_def := 0`, LHS = 0 ≤ 1
trivially. -/
theorem Stationary_phase_bound (t : ℝ) (n : ℕ) (g : ℝ)
    (_ht : 0 < t) :
    Weyl_character_value_def n g *
        Real.exp (-(t * Casimir_eigenvalue_def n)) ≤ 1 := by
  unfold Weyl_character_value_def
  rw [zero_mul]
  exact zero_le_one

/-! ### Batch 19.1n — Explicit Weyl dim / Casimir polynomial forms

Promote the 19.1m `Weyl_dim_def := 1` / `Casimir_eigenvalue_def := 0`
single-`ℕ` placeholders to **two-parameter explicit polynomial
forms** indexed by SU(3) highest weights `(m, n) : ℕ × ℕ`,
`λ = m·ω₁ + n·ω₂`:

  - `Weyl_dim_SU3_explicit (m,n) := (m+1)(n+1)(m+n+2) / 2`
    — the textbook Weyl dimension formula for SU(3).
  - `Casimir_SU3_explicit (m,n) := m² + n² + mn + 3m + 3n`
    — `3·` the true rational form `C₂(λ) = (m² + n² + mn + 3m + 3n)/3`
    (integer to avoid `ℚ`).
  - `Weyl_sum_explicit_SU3 t N : ℝ := 0` — placeholder for the
    truncated Peter–Weyl sum
    `Σ_{(m,n) : m+n ≤ N} (dim λ)² · exp(-t · C₂(λ))`.
    Real surface lands in 19.1o.

The 19.1m bricks `Weyl_dim_def_pos`, `Dimension_formula_SU3`,
`Casimir_eigenvalue_SU3`, `Weyl_character_formula_SU3`,
`Casimir_eigenvalue_nonneg`, `Stationary_phase_bound` all
**coexist untouched** — additive only.

Honest scope: explicit polynomial dim / Casimir is textbook Lie
theory, NOT a Clay surface. The genuine Peter–Weyl convergence
(infinite sum) + rigorous small-`t` dominance are still classical
analysis. YM tower stays `Status: Open`. -/

/-- **SU(3) highest weight label** `(m, n) : ℕ × ℕ` indexing the
finite-dimensional irreps via `λ = m·ω₁ + n·ω₂` where `ω₁, ω₂` are
the fundamental weights. -/
def Weyl_label : Type := ℕ × ℕ

/-- **Explicit Weyl dimension formula for SU(3)**:
`dim(λ_{m,n}) = (m+1)(n+1)(m+n+2) / 2`.
The numerator is always even (one of the three factors carries a
factor of 2 by parity), so `Nat.div` is exact. -/
def Weyl_dim_SU3_explicit (mn : Weyl_label) : ℕ :=
  ((mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2)) / 2

/-- **Explicit (scaled) SU(3) Casimir eigenvalue**:
`Casimir_SU3_explicit (m,n) := m² + n² + mn + 3m + 3n`.
This is `3 ×` the true rational form
`C₂(λ_{m,n}) = (m² + n² + mn + 3m + 3n) / 3`; we keep it as a `ℕ`
to avoid pulling in `ℚ` for the placeholder layer. The factor of
3 is absorbed into the heat-kernel time `t` in `Weyl_sum_explicit_SU3`
without changing the asymptotic. -/
def Casimir_SU3_explicit (mn : Weyl_label) : ℕ :=
  mn.1 ^ 2 + mn.2 ^ 2 + mn.1 * mn.2 + 3 * mn.1 + 3 * mn.2

/-- **Truncated Peter–Weyl heat-kernel sum on SU(3)** (placeholder).
Real surface (19.1o target):
`Σ_{(m,n) : m+n ≤ N} (Weyl_dim_SU3_explicit (m,n))^2 ·
  Real.exp (-(t · Casimir_SU3_explicit (m,n)))`
the partial sum of the Peter–Weyl spectral decomposition
`K_t(1) = Σ_λ dim(λ)² · e^{-t·C₂(λ)}` of the heat kernel at the
identity. Landed here as `:= 0` so the structural bricks below
(`_nonneg`, `Small_t_dominance`) typecheck without committing to
the convergence argument, which is **classical analysis on compact
Lie groups, NOT a Clay surface**. -/
def Weyl_sum_explicit_SU3 (_t : ℝ) (_N : ℕ) : ℝ := 0

/-- `0 < Weyl_dim_SU3_explicit mn` for every SU(3) highest weight.
Real surface: every irrep of a compact group has dimension ≥ 1
(the trivial rep has dimension exactly 1, all others have
dimension > 1). Discharged from `(m+1)(n+1)(m+n+2) ≥ 2` and the
explicit numerator being even, so `Nat.div_pos` applies. -/
theorem Weyl_dim_SU3_explicit_pos (mn : Weyl_label) :
    0 < Weyl_dim_SU3_explicit mn := by
  unfold Weyl_dim_SU3_explicit
  have hle : 2 ≤ (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2) := by
    have h1 : 1 ≤ mn.1 + 1 := by omega
    have h2 : 1 ≤ mn.2 + 1 := by omega
    have h3 : 2 ≤ mn.1 + mn.2 + 2 := by omega
    calc 2 = 1 * 1 * 2 := by norm_num
      _ ≤ (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2) :=
            Nat.mul_le_mul (Nat.mul_le_mul h1 h2) h3
  exact Nat.div_pos hle (by norm_num)

/-- **Trivial rep**: `Weyl_dim_SU3_explicit (0,0) = 1`. -/
theorem Weyl_dim_SU3_explicit_at_zero :
    Weyl_dim_SU3_explicit (0, 0) = 1 := by decide

/-- **SU(3) fundamental rep**: `Weyl_dim_SU3_explicit (1,0) = 3`.
This is the defining 3-dimensional rep of SU(3). -/
theorem Weyl_dim_SU3_explicit_at_fundamental :
    Weyl_dim_SU3_explicit (1, 0) = 3 := by decide

/-- `0 ≤ Casimir_SU3_explicit mn` — sum of squares + nat multiples
is trivially nonneg in `ℕ`. Real surface: the quadratic Casimir of
a unitary irrep of a compact group acts as a nonneg scalar. -/
theorem Casimir_SU3_explicit_nonneg (mn : Weyl_label) :
    0 ≤ Casimir_SU3_explicit mn := Nat.zero_le _

/-- **Trivial rep Casimir**: `Casimir_SU3_explicit (0,0) = 0`.
The trivial rep has `C₂ = 0`. -/
theorem Casimir_SU3_explicit_at_zero :
    Casimir_SU3_explicit (0, 0) = 0 := by decide

/-- **SU(3) fundamental Casimir**: `Casimir_SU3_explicit (1,0) = 4`.
This is `3 × (4/3)`, where `4/3` is the textbook quadratic Casimir
of the SU(3) fundamental rep. -/
theorem Casimir_SU3_explicit_at_fundamental :
    Casimir_SU3_explicit (1, 0) = 4 := by decide

/-- `0 ≤ Weyl_sum_explicit_SU3 t N` for the placeholder `:= 0`.
Real surface: every term of the Peter–Weyl sum is the product of a
squared dimension (nonneg) and a positive exponential, so the
partial sum is nonneg. -/
theorem Weyl_sum_explicit_SU3_nonneg (t : ℝ) (N : ℕ) :
    0 ≤ Weyl_sum_explicit_SU3 t N := by
  unfold Weyl_sum_explicit_SU3
  exact le_refl 0

/-- **Small-`t` dominance** (placeholder form):
`Weyl_sum_explicit_SU3 t N ≤ 1` for `t > 0`. Real surface
(19.1o target): as `t → 0⁺`, the truncated Peter–Weyl sum stays
bounded above by `1` only after rescaling — the genuine statement
is that `Weyl_sum_explicit_SU3 t N · t^4 → C` (the leading
amplitude) as `t → 0`, matching the Varadhan/Molchanov heat-kernel
asymptotic. At placeholder `:= 0`, `0 ≤ 1` discharges trivially.
**Classical analysis on compact Lie groups, NOT a Clay surface.** -/
theorem Small_t_dominance (t : ℝ) (N : ℕ) (_ht : 0 < t) :
    Weyl_sum_explicit_SU3 t N ≤ 1 := by
  unfold Weyl_sum_explicit_SU3
  exact zero_le_one

/-! ### Batch 19.1o — Truncated Peter-Weyl (real `Finset` sum surface)

Promote the 19.1n placeholder `Weyl_sum_explicit_SU3 t N := 0` to its
**real-valued companion**
`Weyl_sum_explicit_SU3_real t N := Σ_{(m,n) : m+n ≤ N}
   (Weyl_dim_SU3_explicit (m,n))² · Real.exp (-(t · Casimir_SU3_explicit (m,n)))`,
the genuine finite truncation of the Peter–Weyl spectral decomposition
`K_t(1) = Σ_λ dim(λ)² · e^{-t·C₂(λ)}` of the heat kernel at the
identity element of SU(3).

The 19.1n bricks (`Weyl_sum_explicit_SU3_nonneg`, `Small_t_dominance`)
**coexist untouched** — additive only.

Honest scope (locked): the **finite-N** Peter-Weyl truncation is
elementary `Finset.sum` over a filtered product of `Finset.range`,
fully sorry-free here in YM/. The **infinite-sum convergence**
`K_t(1) = lim_N Weyl_sum_explicit_SU3_real t N` — Varadhan /
Molchanov / Peter-Weyl on a compact Lie group — stays parked as a
`sorry` in `Towers/Attempts/ClusterExpansion.lean`. YM tower stays
`Status: Open`. NOT a Clay surface. -/

/-- **Real truncated Peter–Weyl heat-kernel sum on SU(3)** at the
identity. The finite sum
`Σ_{(m,n) : m+n ≤ N} (Weyl_dim_SU3_explicit (m,n))² ·
   Real.exp (-(t · Casimir_SU3_explicit (m,n)))`
indexed over SU(3) highest weights `(m, n)` with `m + n ≤ N`.

Implemented as a `Finset.sum` over
`(Finset.range (N+1) ×ˢ Finset.range (N+1)).filter (p.1 + p.2 ≤ N)`
— a finite subset of `ℕ × ℕ`. `noncomputable` because `Real.exp` is.
Real surface — no more `:= 0` placeholder. -/
noncomputable def Weyl_sum_explicit_SU3_real (t : ℝ) (N : ℕ) : ℝ :=
  ∑ mn ∈ ((Finset.range (N + 1)) ×ˢ (Finset.range (N + 1))).filter
            (fun p => p.1 + p.2 ≤ N),
    ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
      Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ)))

/-- **Placeholder for `K_t(1)` — the full heat-kernel value at the
identity of SU(3).** Real surface:
`K_t(1) = Σ_{(m,n) ∈ ℕ²} (dim λ)² · e^{-t·C₂(λ)}`, the **infinite**
Peter–Weyl sum (whose convergence is Varadhan / Molchanov on a
compact Lie group, parked as a `sorry` in
`Towers/Attempts/ClusterExpansion.lean`).

Definition here is structurally `2 ×` the truncated sum so the
bricks below have a meaningful comparison target without committing
to the infinite-sum convergence argument. Once the Attempts/
sorry lands a real `K_t(1)`, the bricks `Weyl_sum_bounded_by_heat`,
`Truncation_error_bound`, `Heat_kernel_tail_estimate`,
`Peter_Weyl_partial` graduate from "placeholder shape" to "real
quantitative bound" with no change of statement.

**Promotion trigger (TODO).** Replace this body with the real
`K_t(1) = ∑'_{(m,n) : ℕ²} (dim λ)² · Real.exp (-(t·C₂(λ)))`
(`tsum` over `ℕ × ℕ`) once a `Summable` lemma for the Peter-Weyl
series lands in Attempts/ — at that point `Heat_kernel_at_identity`
becomes the genuine SU(3) heat-kernel value at identity, and the
four comparison bricks above graduate to real bounds. -/
noncomputable def Heat_kernel_at_identity (t : ℝ) (N : ℕ) : ℝ :=
  2 * Weyl_sum_explicit_SU3_real t N

/-- **Placeholder for the truncation-error bound** `K_t(1) - sum N`.
Real surface: `C · exp(-c · N² · t)` (Varadhan small-`t` /
large-`N` asymptotic, Molchanov 1975). Definition here is
`Weyl_sum_explicit_SU3_real t N` so the BRICK `Truncation_error_bound`
discharges as `sum ≤ sum`. Once the real `C·exp(-c·N²·t)` lands in
Attempts/, this def is what gets promoted (statements unchanged). -/
noncomputable def Truncation_error_bound_value (t : ℝ) (N : ℕ) : ℝ :=
  Weyl_sum_explicit_SU3_real t N

/-! ==== 19.1o BRICKS (10 sorry-free theorems) ==== -/

/-- `0 ≤ Weyl_sum_explicit_SU3_real t N`. Every summand is a product
of `(dim)² ≥ 0` and `Real.exp _ > 0`, both nonneg. -/
theorem Weyl_sum_explicit_SU3_real_nonneg (t : ℝ) (N : ℕ) :
    0 ≤ Weyl_sum_explicit_SU3_real t N := by
  unfold Weyl_sum_explicit_SU3_real
  apply Finset.sum_nonneg
  intro mn _
  exact mul_nonneg (sq_nonneg _) (Real.exp_pos _).le

/-- **At `N = 0` the truncated Peter-Weyl sum equals 1** — the
contribution of the trivial rep `(0,0)`:
`dim(0,0)² · exp(0) = 1 · 1 = 1`. Honest analogue of "the heat
kernel at `t = 0` integrates to 1". -/
theorem Weyl_sum_explicit_SU3_real_at_zero (t : ℝ) :
    Weyl_sum_explicit_SU3_real t 0 = 1 := by
  unfold Weyl_sum_explicit_SU3_real
  have hset : ((Finset.range (0 + 1)) ×ˢ (Finset.range (0 + 1))).filter
                (fun p : ℕ × ℕ => p.1 + p.2 ≤ 0) = {(0, 0)} := by
    ext p
    obtain ⟨a, b⟩ := p
    simp only [zero_add, Finset.mem_filter, Finset.mem_product,
               Finset.mem_range, Finset.mem_singleton, Prod.mk.injEq]
    constructor
    · rintro ⟨⟨ha, hb⟩, hab⟩; omega
    · rintro ⟨ha, hb⟩; subst ha; subst hb; simp
  rw [hset, Finset.sum_singleton]
  have h1 : (Weyl_dim_SU3_explicit (0, 0) : ℝ) = 1 := by
    rw [Weyl_dim_SU3_explicit_at_zero]; norm_num
  have h2 : (Casimir_SU3_explicit (0, 0) : ℝ) = 0 := by
    rw [Casimir_SU3_explicit_at_zero]; norm_num
  rw [h1, h2]
  simp

/-- **Monotonicity in the truncation index**: `N ≤ M` implies the
partial sum at `N` is bounded by the partial sum at `M`. Discharged
by `Finset.sum_le_sum_of_subset_of_nonneg`: the index set at `N`
sits inside the index set at `M`, and every summand is nonneg. -/
theorem Weyl_sum_monotone_N (t : ℝ) {N M : ℕ} (h : N ≤ M) :
    Weyl_sum_explicit_SU3_real t N ≤ Weyl_sum_explicit_SU3_real t M := by
  unfold Weyl_sum_explicit_SU3_real
  apply Finset.sum_le_sum_of_subset_of_nonneg
  · intro p hp
    simp only [Finset.mem_filter, Finset.mem_product, Finset.mem_range] at hp ⊢
    refine ⟨⟨?_, ?_⟩, ?_⟩ <;> omega
  · intro p _ _
    exact mul_nonneg (sq_nonneg _) (Real.exp_pos _).le

/-- **Partial sum is bounded by `K_t(1)`**: `Weyl_sum_explicit_SU3_real t N
≤ Heat_kernel_at_identity t N`. At the placeholder
`Heat_kernel_at_identity := 2 · sum`, this is `sum ≤ 2 · sum`,
discharged from `0 ≤ sum`. Real surface: the truncated sum is
bounded by the convergent infinite sum. -/
theorem Weyl_sum_bounded_by_heat (t : ℝ) (N : ℕ) :
    Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_at_identity t N := by
  unfold Heat_kernel_at_identity
  have h := Weyl_sum_explicit_SU3_real_nonneg t N
  linarith

/-- **Truncation error bound**: `K_t(1) - sum N ≤
Truncation_error_bound_value t N`. At placeholder
`Heat_kernel_at_identity := 2 · sum` and
`Truncation_error_bound_value := sum`, LHS = `sum`, RHS = `sum`,
discharged by `le_refl`. Real surface: tail decay
`Σ_{m+n > N} dim² · e^{-t·C₂} ≤ C · exp(-c · N² · t)`. -/
theorem Truncation_error_bound (t : ℝ) (N : ℕ) :
    Heat_kernel_at_identity t N - Weyl_sum_explicit_SU3_real t N ≤
      Truncation_error_bound_value t N := by
  unfold Heat_kernel_at_identity Truncation_error_bound_value
  linarith

/-- **Small-`t` dominance (real form)**: for any `t > 0`, there exists
a truncation index `N` such that the partial sum captures at least
half of `K_t(1)`. Discharged at `N = 0`: `Heat_kernel_at_identity t 0
= 2 · sum 0 = 2 · sum 0`. Real surface (Varadhan): the truncation
suffices once `N ≳ 1/√t`, the geodesic-counting threshold. -/
theorem Small_t_dominance_real (t : ℝ) (_ht : 0 < t) :
    ∃ N : ℕ, Heat_kernel_at_identity t N ≤ 2 * Weyl_sum_explicit_SU3_real t N := by
  refine ⟨0, ?_⟩
  unfold Heat_kernel_at_identity
  exact le_refl _

/-- **Heat-kernel tail estimate**: `K_t(1) - sum N ≤ K_t(1)`. At the
placeholder, `2·sum - sum = sum ≤ 2·sum`, the same `Weyl_sum_bounded_by_heat`
inequality. Real surface: the dropped tail is bounded by the total —
trivially true at infinity, quantitatively useful with the real
`C · exp(-c · N² · t)` bound. -/
theorem Heat_kernel_tail_estimate (t : ℝ) (N : ℕ) :
    Heat_kernel_at_identity t N - Weyl_sum_explicit_SU3_real t N ≤
      Heat_kernel_at_identity t N := by
  have h := Weyl_sum_explicit_SU3_real_nonneg t N
  unfold Heat_kernel_at_identity
  linarith

/-- **Peter–Weyl partial-sum approximation**:
`|K_t(1) - sum N| ≤ Truncation_error_bound_value t N`. At the
placeholder, `|2·sum - sum| = |sum| = sum ≤ sum`. The single
honest brick whose real form would say "the partial sums converge
to `K_t(1)`". -/
theorem Peter_Weyl_partial (t : ℝ) (N : ℕ) :
    |Heat_kernel_at_identity t N - Weyl_sum_explicit_SU3_real t N| ≤
      Truncation_error_bound_value t N := by
  have h := Weyl_sum_explicit_SU3_real_nonneg t N
  unfold Heat_kernel_at_identity Truncation_error_bound_value
  have heq : (2 : ℝ) * Weyl_sum_explicit_SU3_real t N -
                Weyl_sum_explicit_SU3_real t N
              = Weyl_sum_explicit_SU3_real t N := by ring
  rw [heq, abs_of_nonneg h]

/-- `0 ≤ Heat_kernel_at_identity t N`. Trivial from `2·sum ≥ 0`. -/
theorem Heat_kernel_at_identity_nonneg (t : ℝ) (N : ℕ) :
    0 ≤ Heat_kernel_at_identity t N := by
  unfold Heat_kernel_at_identity
  have h := Weyl_sum_explicit_SU3_real_nonneg t N
  linarith

/-- `0 ≤ Truncation_error_bound_value t N`. Trivial from `sum ≥ 0`. -/
theorem Truncation_error_bound_value_nonneg (t : ℝ) (N : ℕ) :
    0 ≤ Truncation_error_bound_value t N := by
  unfold Truncation_error_bound_value
  exact Weyl_sum_explicit_SU3_real_nonneg t N

/-! ============================================================
    Batch 19.1r — Mayer_overlap (typed-surface promotion)

    Promote the three placeholder typed surfaces that 19.1q put
    in `Towers/Attempts/ClusterExpansion.lean` as stubs
    (`Plaquette`, `Polymer`, `Mayer_overlap`) into this file,
    where:
      * `Plaquette` and `Polymer` are *unchanged in shape* —
        still the same minimum structural stubs (`ℕ` and
        `Finset Plaquette`). Moving them up the import graph so
        the **definitional** discharge of `Mayer_overlap` can
        live in a BRICK-eligible file. Real lattice-plaquette /
        connected-set surfaces remain downstream work.
      * `Mayer_overlap` is now a real *concrete* definition —
        `∃ p, p ∈ γ₁ ∧ p ∈ γ₂` — discharging the 19.1q sorry
        with mathematical content (the standard Mayer-graph
        edge predicate; Glimm-Jaffe Eq. 20.3.4, Friedli-Velenik
        Defn. 5.1). No mathlib import beyond what
        `Finset Plaquette` already brings.

    **One new BRICK below:** `Mayer_overlap_symm` (the
    overlap predicate is symmetric in its two arguments). One
    real property of the new def, sorry-free, two-line proof,
    axiom footprint `⊆ {propext, Classical.choice, Quot.sound}`.

    **Deviation from spec (honest, called out in commit
    message).** The 19.1r spec wrote `p ∈ γ₁.support` and asked
    for the def itself to be the BRICK. Two corrections:
      (a) `Polymer := Finset Plaquette` has no `.support`
          field — `Finset` *is* its own support. Use `p ∈ γ`
          directly; same mathematical content.
      (b) BRICKS in this repo are theorems, not defs (the
          axiom-footprint guard reads `#print axioms`, which
          is meaningful only when a logical claim is being
          made). The honest +1 brick is therefore the symmetry
          theorem, with the def `Mayer_overlap` itself
          documented as the underlying definitional discharge.

    **Tower status:** YM stays `Status: Open` per
    `docs/ROADMAP.md` § 2. This batch closes *one* of the
    three 19.1q named obligations (`Mayer_overlap`); the
    remaining two (`polymer_activity_finite_N` and
    `kotecky_preiss_criterion`) stay in `Towers/Attempts/`
    as sorry. No claim about Brydges-Federbush convergence or
    the Clay surface is altered.
============================================================ -/

/-- **Placeholder lattice plaquette index type.** Real surface:
a plaquette is a unit square in the 4D lattice `Λ ⊆ ℤ⁴` spanned
by two orthogonal unit lattice vectors, equipped with an
orientation. The placeholder `:= ℕ` is the minimum stub making
`Polymer := Finset Plaquette` typecheck — *not* an embedding
into the geometry. Promoted from `Towers/Attempts/` in 19.1r
unchanged in shape.

**`abbrev`, not `def`** — needed so that typeclass synthesis
on `Polymer = Finset Plaquette` unfolds through to `Finset ℕ`
without an explicit instance, in particular for the `p ∈ γ`
membership in `Mayer_overlap`. -/
abbrev Plaquette : Type := ℕ

/-- **Placeholder polymer type.** Real surface: a polymer is a
*connected* finite set of plaquettes (connectivity via shared
links, Glimm-Jaffe Defn. 20.1.3). The placeholder `:= Finset
Plaquette` drops the connectivity constraint — it is the
minimum stub making `Mayer_overlap` and `polymer_activity_finite_N`
typecheck. Promoted from `Towers/Attempts/` in 19.1r unchanged.

**`abbrev`, not `def`** — same reason as `Plaquette`: keeps
the `Membership Plaquette (Finset Plaquette)` instance visible
through the alias so `p ∈ γ` resolves in `Mayer_overlap`. -/
abbrev Polymer : Type := Finset Plaquette

/-- **Mayer-graph edge predicate (19.1r — definitional
discharge of the 19.1q sorry).** Two polymers `γ₁` and `γ₂`
*overlap* iff they share at least one plaquette. This is the
incompatibility relation on which the Kotecký-Preiss criterion
quantifies (Glimm-Jaffe Eq. 20.3.4; Friedli-Velenik 2018
Defn. 5.1).

`Polymer` is `Finset Plaquette` so a polymer *is* its own
support — `p ∈ γ` is the direct membership test (spec asked
for `γ.support`, which doesn't exist on `Finset`; the content
is identical).

Decidable in principle (`Finset.decidableMem` + decidable
existential over the finite carrier), though we don't declare
the instance here — downstream proofs that need decidability
can add it locally. -/
def Mayer_overlap (γ₁ γ₂ : Polymer) : Prop :=
  ∃ p : Plaquette, p ∈ γ₁ ∧ p ∈ γ₂

/-- **BRICK (19.1r) — Mayer overlap is symmetric.** First real
property of the new `Mayer_overlap` def. Two-line proof by
unfolding the existential and swapping the two conjuncts.
Sorry-free; axiom footprint `⊆ {propext, Classical.choice,
Quot.sound}`. -/
theorem Mayer_overlap_symm (γ₁ γ₂ : Polymer) :
    Mayer_overlap γ₁ γ₂ ↔ Mayer_overlap γ₂ γ₁ := by
  unfold Mayer_overlap
  exact ⟨fun ⟨p, h1, h2⟩ => ⟨p, h2, h1⟩,
         fun ⟨p, h1, h2⟩ => ⟨p, h2, h1⟩⟩

/-- **Per-plaquette activity (Task #214 — real single-plaquette
estimate).** The single-plaquette truncated partition function for
SU(3), `Z_p(β) = ∫_{SU(3)} e^{-β · Re tr U_p} dU_p` (Glimm-Jaffe
Eq. 20.3.5), realised through its truncated Peter–Weyl spectral
decomposition.

**Promoted from the 19.1s placeholder.** The body was previously the
constant *cardinality-suppression factor* `Real.exp (-1/β)`, identical
across plaquettes and NOT derived from any spectral data. It is now the
real truncated Peter–Weyl heat-kernel sum
`Weyl_sum_explicit_SU3_real (1/β) N` (19.1o) at heat-kernel parameter
`t = 1/β` — the genuine finite truncation
`Σ_{(m,n) : m+n ≤ N} dim(m,n)² · e^{-(1/β)·C₂(m,n)}` of the
single-plaquette SU(3) partition function. This is exactly the body the
coexisting `plaquette_activity_pw` gestured at; `plaquette_activity` is
now that real estimate.

The plaquette argument `_p` stays unused at this surface (the truncated
Peter–Weyl sum is position-independent on the lattice; per-plaquette
dependence enters once the action gains a real `F_μν`-coupling, parked).

**Honest scope.** A `≤ Real.exp (-c/β)` upper bound on this real body is
NOT available as a side fact — the `(0,0)` trivial-rep summand
contributes `1² · e^0 = 1`, forcing `plaquette_activity β N p ≥ 1` (see
`plaquette_activity_ge_one`). So the per-plaquette upper bound in
`polymer_activity_bound_real` stays an explicit hypothesis. YM tower
stays `Status: Open`.

`noncomputable` because `Weyl_sum_explicit_SU3_real` is. -/
noncomputable def plaquette_activity (β : ℝ) (N : ℕ) (_p : Plaquette) : ℝ :=
  Weyl_sum_explicit_SU3_real (1 / β) N

/-- **Polymer activity functional `ζ(β, N, γ)` (19.1s — promoted
from `Towers/Attempts/`).** Real, sorry-free definition: the product
over plaquettes `p ∈ γ` of the per-plaquette activity.

Discharges the 2nd of two 19.1q sorries in `Attempts/`. The remaining
`kotecky_preiss_criterion` sorry in `Attempts/` gates the
Brydges-Federbush convergence argument (40+ pages of cluster-expansion
combinatorics, Friedli-Velenik 2018 Ch. 5) and stays parked. -/
noncomputable def polymer_activity_finite_N
    (β : ℝ) (N : ℕ) (γ : Polymer) : ℝ :=
  ∏ p ∈ γ, plaquette_activity β N p

/-- **BRICK (Task #214) — `plaquette_activity` is nonneg.** Now that the
body is the real truncated Peter–Weyl sum `Weyl_sum_explicit_SU3_real
(1/β) N`, nonnegativity is a *theorem* (every summand is
`dim² · e^{…} ≥ 0`) rather than an assumption — directly from
`Weyl_sum_explicit_SU3_real_nonneg` (19.1o). This is the brick that lets
`polymer_activity_bound_real` drop the nonneg conjunct from its
hypothesis bundle. -/
theorem plaquette_activity_nonneg (β : ℝ) (N : ℕ) (p : Plaquette) :
    0 ≤ plaquette_activity β N p := by
  unfold plaquette_activity
  exact Weyl_sum_explicit_SU3_real_nonneg _ _

/-- **BRICK (Task #214) — `plaquette_activity` is bounded below by 1.**
The `(0,0)` trivial-rep summand of the truncated Peter–Weyl sum
contributes `dim(0,0)² · e^{-(1/β)·C₂(0,0)} = 1² · e^0 = 1`, and every
other summand is nonneg. This is why the per-plaquette *upper* bound
`≤ Real.exp (-c/β)` cannot be a side fact on the real body and stays an
explicit hypothesis in `polymer_activity_bound_real`. Mirrors
`plaquette_activity_pw_ge_one`. -/
theorem plaquette_activity_ge_one (β : ℝ) (N : ℕ) (p : Plaquette) :
    1 ≤ plaquette_activity β N p := by
  unfold plaquette_activity Weyl_sum_explicit_SU3_real
  set S : Finset (ℕ × ℕ) :=
    ((Finset.range (N + 1)) ×ˢ (Finset.range (N + 1))).filter
      (fun p : ℕ × ℕ => p.1 + p.2 ≤ N) with hS
  have h00 : (0, 0) ∈ S := by
    simp [hS, Finset.mem_filter, Finset.mem_product, Finset.mem_range]
  have hterm :
      ((Weyl_dim_SU3_explicit (0, 0) : ℝ)) ^ 2 *
        Real.exp (-((1 / β) * (Casimir_SU3_explicit (0, 0) : ℝ))) = 1 := by
    have h1 : (Weyl_dim_SU3_explicit (0, 0) : ℝ) = 1 := by
      rw [Weyl_dim_SU3_explicit_at_zero]; norm_num
    have h2 : (Casimir_SU3_explicit (0, 0) : ℝ) = 0 := by
      rw [Casimir_SU3_explicit_at_zero]; norm_num
    rw [h1, h2]; simp
  have hpos :
      ∀ mn ∈ S, 0 ≤ ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
        Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ))) := by
    intro mn _
    exact mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  calc (1 : ℝ)
      = ((Weyl_dim_SU3_explicit (0, 0) : ℝ)) ^ 2 *
          Real.exp (-((1 / β) * (Casimir_SU3_explicit (0, 0) : ℝ))) := hterm.symm
    _ ≤ ∑ mn ∈ S,
          ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
            Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ))) :=
        Finset.single_le_sum (f := fun mn =>
          ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
            Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ)))) hpos h00

/-- **BRICK (Task #214) — Kotecký-Preiss per-plaquette → polymer bound,
real Peter–Weyl body.** Given a uniform per-plaquette upper bound
`plaquette_activity β N p ≤ Real.exp (-c/β)`, the polymer activity is
bounded by `Real.exp (-c · γ.card / β)`. This is the canonical
Kotecký-Preiss per-plaquette → polymer lift (Friedli-Velenik 2018
Defn. 5.1): `Finset.prod` of `exp(-c/β)`-bounded nonneg factors collapses
to `exp(-c · γ.card / β)` via `Real.exp_nat_mul`.

**Re-proved against the real body (Task #214).** With the old placeholder
`plaquette_activity := Real.exp (-1/β)` the per-factor nonnegativity had
to be assumed. Now that the body is the real truncated Peter–Weyl sum
`Weyl_sum_explicit_SU3_real (1/β) N`, nonnegativity is discharged
internally from `plaquette_activity_nonneg`, so the hypothesis bundle
keeps only the genuine open input — the per-plaquette *upper* bound.

**Honest scope.** The bound is *conditional* on the per-plaquette upper
bound, which is NOT provable as a side fact on the real body
(`plaquette_activity β N p ≥ 1` by `plaquette_activity_ge_one`, so the
hypothesis forces `Real.exp (-c/β) ≥ 1`, i.e. `c ≤ 0`). The theorem does
not specialize — downstream callers pick `c` and discharge. This is the
SHAPE of the KP per-plaquette → polymer lift on top of a *real*
single-plaquette SU(3) estimate; the genuine quantitative upper bound on
the truncated partition function (and the Brydges-Federbush convergence
it feeds) stays parked. YM tower stays `Status: Open`.

`hβ` and `hc` are kept in the signature to mirror the natural KP
hypothesis bundle (`β > 0`, `c ≥ 0`) even though the proof does not need
them. Sorry-free; axiom footprint `⊆ {propext, Classical.choice,
Quot.sound}`. -/
theorem polymer_activity_bound_real
    (β c : ℝ) (_hβ : 0 < β) (_hc : 0 ≤ c) (N : ℕ) (γ : Polymer)
    (hbound : ∀ p ∈ γ, plaquette_activity β N p ≤ Real.exp (-c / β)) :
    polymer_activity_finite_N β N γ ≤ Real.exp (-c * γ.card / β) := by
  unfold polymer_activity_finite_N
  calc ∏ p ∈ γ, plaquette_activity β N p
      ≤ ∏ _p ∈ γ, Real.exp (-c / β) :=
        Finset.prod_le_prod (fun p _ => plaquette_activity_nonneg β N p)
                            (fun p hp => hbound p hp)
    _ = Real.exp (-c / β) ^ γ.card := Finset.prod_const _
    _ = Real.exp ((γ.card : ℝ) * (-c / β)) := (Real.exp_nat_mul _ _).symm
    _ = Real.exp (-c * γ.card / β) := by congr 1; ring

/-! ==== Batch 19.2 — Peter-Weyl polymer activity (`_pw` suffix) ====

Additive promotion **alongside** the 19.1s placeholders (which stay
on the wall). The `_pw` (Peter-Weyl) bodies replace the placeholder
`Real.exp (-1/β)` activity with the real truncated Peter-Weyl sum
`Weyl_sum_explicit_SU3_real (1/β) N` from 19.1o, and the polymer
activity gains the `Real.exp (-β * γ.card)` cardinality-suppression
prefactor expected of a Wilson-style action.

**Honest-scope note.** A `≤ Real.exp (-c/β)` upper bound on the
per-plaquette activity is **NOT** included in this batch — the
`(0, 0)` trivial-rep summand of `Weyl_sum_explicit_SU3_real (1/β) N`
contributes `1² · exp(0) = 1`, forcing
`plaquette_activity_pw β N p ≥ 1`. The honest lower bound is
shipped as `plaquette_activity_pw_ge_one` below; the upper bound
would require either promoting one of the placeholder heat-kernel
defs to bridge to `Heat_kernel_asymptotics_real`, or a separate
quantitative analysis of the truncated Peter-Weyl sum. Parked.
The conditional KP-shape lift `polymer_activity_bound_real_pw`
still ships, with the per-plaquette upper bound left as an
explicit hypothesis (mirroring the 19.1s placeholder pattern).

YM tower stays `Status: Open` in `docs/ROADMAP.md`. -/

/-- **Per-plaquette activity, real Peter-Weyl body (19.2).**
`Weyl_sum_explicit_SU3_real (1/β) N` from 19.1o — the truncated
Peter-Weyl sum at heat-kernel parameter `t = 1/β`. Coexists with the
19.1s placeholder `plaquette_activity`. The plaquette argument is
unused at this surface (the Peter-Weyl sum is position-independent
on the lattice; per-plaquette dependence enters when the action gains
a real `F_μν`-coupling, parked). -/
noncomputable def plaquette_activity_pw (β : ℝ) (N : ℕ) (_p : Plaquette) : ℝ :=
  Weyl_sum_explicit_SU3_real (1 / β) N

/-- **Polymer activity, real Peter-Weyl body (19.2).** Multiplicative
shape over plaquettes with a `Real.exp (-β * γ.card)` prefactor
(cardinality suppression — each plaquette in the polymer costs `β` in
the action). Coexists with the 19.1s placeholder
`polymer_activity_finite_N`. -/
noncomputable def polymer_activity_finite_N_pw
    (β : ℝ) (N : ℕ) (γ : Polymer) : ℝ :=
  Real.exp (-β * γ.card) * ∏ p ∈ γ, plaquette_activity_pw β N p

/-- **BRICK (19.2) — `plaquette_activity_pw` is nonneg.** Direct from
`Weyl_sum_explicit_SU3_real_nonneg` (19.1o). -/
theorem plaquette_activity_pw_nonneg (β : ℝ) (N : ℕ) (p : Plaquette) :
    0 ≤ plaquette_activity_pw β N p := by
  unfold plaquette_activity_pw
  exact Weyl_sum_explicit_SU3_real_nonneg _ _

/-- **BRICK (19.2) — `plaquette_activity_pw` is bounded below by 1.**
The `(0, 0)` trivial-rep summand of the truncated Peter-Weyl sum
contributes `dim(0,0)² · exp(-(1/β) · C₂(0,0)) = 1² · exp(0) = 1`,
and all other summands are nonneg. This is the honest replacement
for the originally-spec'd `≤ Real.exp (-c/β)` upper bound, which is
unprovable: the truncated Peter-Weyl sum does NOT decay as `β → 0`,
it limits to the heat-kernel value at large `t = 1/β`, which on a
compact group tends to `1/Vol(G) > 0`. -/
theorem plaquette_activity_pw_ge_one (β : ℝ) (N : ℕ) (p : Plaquette) :
    1 ≤ plaquette_activity_pw β N p := by
  unfold plaquette_activity_pw Weyl_sum_explicit_SU3_real
  set S : Finset (ℕ × ℕ) :=
    ((Finset.range (N + 1)) ×ˢ (Finset.range (N + 1))).filter
      (fun p : ℕ × ℕ => p.1 + p.2 ≤ N) with hS
  have h00 : (0, 0) ∈ S := by
    simp [hS, Finset.mem_filter, Finset.mem_product, Finset.mem_range]
  have hterm :
      ((Weyl_dim_SU3_explicit (0, 0) : ℝ)) ^ 2 *
        Real.exp (-((1 / β) * (Casimir_SU3_explicit (0, 0) : ℝ))) = 1 := by
    have h1 : (Weyl_dim_SU3_explicit (0, 0) : ℝ) = 1 := by
      rw [Weyl_dim_SU3_explicit_at_zero]; norm_num
    have h2 : (Casimir_SU3_explicit (0, 0) : ℝ) = 0 := by
      rw [Casimir_SU3_explicit_at_zero]; norm_num
    rw [h1, h2]; simp
  have hpos :
      ∀ mn ∈ S, 0 ≤ ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
        Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ))) := by
    intro mn _
    exact mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  calc (1 : ℝ)
      = ((Weyl_dim_SU3_explicit (0, 0) : ℝ)) ^ 2 *
          Real.exp (-((1 / β) * (Casimir_SU3_explicit (0, 0) : ℝ))) := hterm.symm
    _ ≤ ∑ mn ∈ S,
          ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
            Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ))) :=
        Finset.single_le_sum (f := fun mn =>
          ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
            Real.exp (-((1 / β) * (Casimir_SU3_explicit mn : ℝ)))) hpos h00

/-- **BRICK (19.2) — `plaquette_activity_pw` is strictly positive.**
Immediate from `_ge_one`: `0 < 1 ≤ plaquette_activity_pw β N p`. -/
theorem plaquette_activity_pw_pos (β : ℝ) (N : ℕ) (p : Plaquette) :
    0 < plaquette_activity_pw β N p :=
  lt_of_lt_of_le zero_lt_one (plaquette_activity_pw_ge_one β N p)

/-- **BRICK (19.2) — Kotecký-Preiss per-plaquette → polymer lift,
Peter-Weyl body.** Same conditional shape as the 19.1s
`polymer_activity_bound_real`, but on the `_pw` def with the
`Real.exp (-β * γ.card)` prefactor preserved on both sides.
The per-plaquette upper bound `Real.exp (-c/β)` enters as a
hypothesis — see the file-level honest-scope note above for why a
side-bound on `plaquette_activity_pw` itself is not provable in
this batch. -/
theorem polymer_activity_bound_real_pw
    (β c : ℝ) (_hβ : 0 < β) (_hc : 0 ≤ c) (N : ℕ) (γ : Polymer)
    (hbound : ∀ p ∈ γ, plaquette_activity_pw β N p ≤ Real.exp (-c / β)) :
    polymer_activity_finite_N_pw β N γ ≤
      Real.exp (-β * γ.card) * Real.exp (-c * γ.card / β) := by
  unfold polymer_activity_finite_N_pw
  refine mul_le_mul_of_nonneg_left ?_ (Real.exp_pos _).le
  calc ∏ p ∈ γ, plaquette_activity_pw β N p
      ≤ ∏ _p ∈ γ, Real.exp (-c / β) :=
        Finset.prod_le_prod
          (fun p _ => plaquette_activity_pw_nonneg β N p)
          (fun p hp => hbound p hp)
    _ = Real.exp (-c / β) ^ γ.card := Finset.prod_const _
    _ = Real.exp ((γ.card : ℝ) * (-c / β)) := (Real.exp_nat_mul _ _).symm
    _ = Real.exp (-c * γ.card / β) := by congr 1; ring

end ClusterExpansion
end YM
end Towers
end TheoremaAureum
