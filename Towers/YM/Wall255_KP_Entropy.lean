/-
================================================================
Towers / YM / Wall255_KP_Entropy

**Beating the `7ⁿ` polymer entropy — honest CONDITIONAL combinator.**

The genuine Kotecký–Preiss sum is organised by polymer size:

    ∑_π |activity π|  =  ∑ₙ (#{size-n polymers through origin}) · (activity per size).

`EntropyBound` bounds the multiplicity `#{size-n} ≤ polymer_const ^ n = 7ⁿ`
(`polymer_const = 2d − 1 = 7`, `d = 4`). To "beat" this entropy, the entropy-
weighted geometric series `∑ₙ 7ⁿ · qⁿ` must converge, which happens **iff**
`7q < 1`, i.e. per-polymer activity `q < 1/7`.

This file makes that mechanism precise and HONEST:

  1. `entropy_geometric_summable` / `entropy_geometric_tsum` — GENUINE,
     unconditional: for `0 ≤ q` and `7q < 1`, `∑ₙ 7ⁿ·qⁿ = ∑ₙ (7q)ⁿ` is
     `Summable` with total `(1 − 7q)⁻¹`. The `7ⁿ` entropy factor is **kept**,
     not dropped (contrast Wall253's size-series majorant, which dropped it).
  2. `kp_entropy_weighted_summable` — for any nonnegative count `N : ℕ → ℝ`
     with `N n ≤ 7ⁿ`, the entropy-weighted sum `∑ₙ N n · qⁿ` is `Summable`
     (comparison with `(7q)ⁿ`), GIVEN `7q < 1`.
  3. `kp_polymer_entropy_weighted_summable` — the same, instantiated at the
     genuine `EntropyBound` polymer count, CONDITIONAL on the two NAMED OPEN
     surfaces `h_entropy` (the connective-constant count) and `q < 1/7`
     (per-polymer strong-coupling smallness).
  4. `seven_q_lt_one_of_lt_inv_seven`, `seven_half_not_lt_one` — the honesty
     arithmetic: `q < 1/7 ⟹ 7q < 1`, and crucially `¬ (7·(1/2) < 1)` — the
     current smallness `kp_sum_lt_half` (`< 1/2`) does NOT reach the `< 1/7`
     needed to beat the entropy.

## Honest scope (locked)

* **The entropy is beaten ONLY under `q < 1/7`, which is a NAMED OPEN surface.**
  Wall252's `kp_sum_lt_half` delivers per-polymer smallness `< 1/2`, and
  `seven_half_not_lt_one` proves `7·(1/2) = 3.5 ≥ 1`, so that smallness CANNOT
  drive the entropy-weighted series. Establishing `q < 1/7` (the correct
  strong-coupling activity bound, with the entropy constant `2d − 1` built in)
  is genuine OPEN work, supplied here as a hypothesis, NOT `by sorry`.
* **`h_entropy` is also OPEN.** `kp_polymer_entropy_weighted_summable` consumes
  `EntropyBound.polymer_entropy_bound`'s surface `h_entropy` (the lattice-animal
  / connective-constant count `μ(ℤ⁴) ≤ 7`), itself unproved in mathlib v4.12.0.
* **This does NOT establish KP convergence.** The genuine KP criterion also
  needs a uniform per-polymer activity bound `|ζ(γ)| ≤ q^{|γ|}` tying the
  abstract `q` to the real Wilson activity, plus the tree-graph / Ursell
  weighting — none supplied here. This file proves NO Wilson result, makes NO
  mass-gap / `μ > 0` / Surface-#1 / RH / BSD claim, and does NOT touch,
  discharge, or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`.
  YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.EntropyBound` and mathlib's
geometric-series API only; imports nothing from the NS tower.
================================================================
-/

import Towers.YM.EntropyBound
import Mathlib.Analysis.SpecificLimits.Basic

namespace TheoremaAureum.Towers.YM.Wall255

open scoped BigOperators

/-! ### Honesty arithmetic: the `< 1/7` threshold vs the current `< 1/2` -/

/-- The entropy is beaten exactly when `7q < 1`, i.e. `q < 1/7`. -/
theorem seven_q_lt_one_of_lt_inv_seven {q : ℝ} (hq : q < 1 / 7) : 7 * q < 1 := by
  linarith

/-- **Honest gap.** The current single-plaquette smallness `kp_sum_lt_half`
    gives `< 1/2`, but `7 · (1/2) = 3.5 ≥ 1`: a `< 1/2` activity does NOT beat
    the `7ⁿ` entropy. The threshold `< 1/7` is therefore a genuine OPEN surface,
    not a consequence of Wall252. -/
theorem seven_half_not_lt_one : ¬ (7 * (1 / 2 : ℝ) < 1) := by norm_num

/-! ### Genuine entropy-weighted geometric series (unconditional; `7ⁿ` kept) -/

/-- **Entropy-weighted geometric summability (genuine).** For `0 ≤ q` with
    `7q < 1`, the series `∑ₙ 7ⁿ·qⁿ = ∑ₙ (7q)ⁿ` is `Summable`. The `7ⁿ` polymer
    entropy factor is KEPT inside the series — this is what "beating the entropy"
    means. -/
theorem entropy_geometric_summable {q : ℝ} (hq0 : 0 ≤ q) (h7q : 7 * q < 1) :
    Summable (fun n : ℕ => (7 : ℝ) ^ n * q ^ n) := by
  have hfun : (fun n : ℕ => (7 : ℝ) ^ n * q ^ n) = fun n : ℕ => (7 * q) ^ n := by
    funext n; rw [mul_pow]
  rw [hfun]
  exact summable_geometric_of_lt_one (mul_nonneg (by norm_num) hq0) h7q

/-- **Entropy-weighted geometric total (genuine).** Under the same hypotheses,
    `∑ₙ 7ⁿ·qⁿ = (1 − 7q)⁻¹`. -/
theorem entropy_geometric_tsum {q : ℝ} (hq0 : 0 ≤ q) (h7q : 7 * q < 1) :
    ∑' n : ℕ, (7 : ℝ) ^ n * q ^ n = (1 - 7 * q)⁻¹ := by
  have hfun : (fun n : ℕ => (7 : ℝ) ^ n * q ^ n) = fun n : ℕ => (7 * q) ^ n := by
    funext n; rw [mul_pow]
  rw [show (∑' n : ℕ, (7 : ℝ) ^ n * q ^ n) = ∑' n : ℕ, (7 * q) ^ n from by rw [hfun]]
  exact tsum_geometric_of_lt_one (mul_nonneg (by norm_num) hq0) h7q

/-! ### Conditional combinator: beat the entropy for an abstract count `N` -/

/-- **Entropy-weighted polymer-sum summability (honest conditional combinator).**

For any nonnegative size-count `N : ℕ → ℝ` bounded by the entropy `N n ≤ 7ⁿ`,
and per-size activity `q` with `0 ≤ q` and `7q < 1`, the entropy-weighted sum
`∑ₙ N n · qⁿ` is `Summable`, by comparison with the genuine geometric majorant
`(7q)ⁿ`. This is the actual "beat the `7ⁿ` entropy" step — CONDITIONAL on the
smallness `7q < 1` (equivalently `q < 1/7`). -/
theorem kp_entropy_weighted_summable
    {N : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    {q : ℝ} (hq0 : 0 ≤ q) (h7q : 7 * q < 1) :
    Summable (fun n : ℕ => N n * q ^ n) := by
  refine Summable.of_nonneg_of_le
    (fun n => mul_nonneg (hN0 n) (pow_nonneg hq0 n))
    (fun n => mul_le_mul_of_nonneg_right (hN n) (pow_nonneg hq0 n))
    (entropy_geometric_summable hq0 h7q)

/-- **Entropy-weighted summability at the genuine polymer count (conditional).**

Instantiates `kp_entropy_weighted_summable` at `EntropyBound`'s polymer count
`#{size-n Connected polymers through the origin link}`, CONDITIONAL on BOTH named
OPEN surfaces: `h_entropy` (the connective-constant count `≤ 7ⁿ`, open per
`EntropyBound`) and the per-polymer smallness `q < 1/7` (open — Wall252 only
gives `< 1/2`, see `seven_half_not_lt_one`). Proves NO KP convergence; makes NO
mass-gap claim; does NOT discharge `kotecky_preiss_criterion`. -/
theorem kp_polymer_entropy_weighted_summable
    {L : ℕ} [NeZero L]
    (Connected : LatticeGauge.Polymer 4 L → Prop)
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          ≤ EntropyBound.polymer_const ^ n)
    {q : ℝ} (hq0 : 0 ≤ q) (hq : q < 1 / 7) :
    Summable (fun n : ℕ =>
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          * q ^ n) := by
  refine kp_entropy_weighted_summable
    (fun n => Nat.cast_nonneg _) (fun n => ?_) hq0
    (seven_q_lt_one_of_lt_inv_seven hq)
  have h := EntropyBound.polymer_entropy_bound Connected h_entropy n
  simpa [EntropyBound.polymer_const] using h

end TheoremaAureum.Towers.YM.Wall255
