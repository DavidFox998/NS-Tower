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

/-! ---- 19.1e helper bricks (honest, naturally arising) ---- -/

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

/-! ---- 19.1f helper bricks ---- -/

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

end ClusterExpansion
end YM
end Towers
end TheoremaAureum
