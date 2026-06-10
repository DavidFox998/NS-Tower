/-
Wall257_StrongCoupling — HONEST CONDITIONAL strong-coupling polymer-activity bound.

Requested goal (the honest, quantifier-corrected version):
  `∀ γ, β ≥ β₀ → polymerActivity L β γ ≤ (1/8) ^ |γ|`,
derived from a genuine per-polymer energy lower bound supplied as a NAMED
hypothesis.

This file lands that bound as an HONEST CONDITIONAL COMBINATOR
`polymerActivity_le_inv8_of_energy_lb` (and its `(1/8) < (1/7)` corollary),
NOT an unconditional smallness proof, NOT a beat-the-entropy result, and NOT a
spectral-radius bound `ρ(T) < 1`.

What is GENUINE / UNCONDITIONAL here
------------------------------------
* `inv8_pow_eq_exp_neg` — `(1/8)^n = exp(-(log 8)·n)` (via `Real.rpow_natCast`
  + `Real.rpow_def_of_pos` + `Real.log_inv`). The honest bridge between the
  geometric form `(1/8)^n` and the exponential form `exp(-rate·n)`.
* `exp_neg_mul_le_inv8_pow` — for `log 8 ≤ r`, `exp(-r·n) ≤ (1/8)^n` for every
  `n : ℕ`. Genuine `exp`-monotonicity arithmetic.
* `inv8_pow_le_inv7_pow` — `(1/8)^n ≤ (1/7)^n` (`pow_le_pow_left`), the only true
  content behind "1/8 < 1/7".
* `polymerEnergy_vacuum_eq_zero` — at the constant-`1` (vacuum) link field the
  polymer energy is `0` (`plaquetteEnergy_const_one` termwise).

What is CONDITIONAL / OPEN here
-------------------------------
`polymerActivity_le_inv8_of_energy_lb` derives `polymerActivity L β γ ≤ (1/8)^|γ|`
from THREE hypotheses:
  * `hβ : 0 ≤ β` — harmless sign condition;
  * `hβc : Real.log 8 ≤ β * c` — strong-coupling threshold (`β ≥ (log 8)/c`);
  * `hLB : ∀ w, c·|γ| ≤ polymerEnergy (toGauge L w) γ` — a UNIFORM per-polymer
    energy lower bound. This is a NAMED OPEN hypothesis (NOT `by sorry`, so NO
    `sorryAx`).
The genuine work is the integral step: `polymerActivity = ∫ exp(-β·E) ∂haarN ≤
∫ exp(-β·c·|γ|) = exp(-β·c·|γ|) ≤ (1/8)^|γ|` (`integral_mono` +
`integrable_polymerWeight` + `integral_const` over the probability measure
`haarN`).

WHY `hLB` CANNOT BE DISCHARGED — and why this is NOT a smallness result
----------------------------------------------------------------------
The pointwise lower bound `hLB` with `c > 0` is OUTRIGHT FALSE, not merely open:
`vacuum_breaks_energy_lb` PROVES `¬ hLB` for `c > 0` and nonempty `γ`, because
the vacuum link field `w ≡ 1` has `polymerEnergy = 0` (`polymerEnergy_vacuum_eq_zero`),
so `c·|γ| ≤ 0` is violated. Consequently:
  * this combinator establishes NOTHING about the real `polymerActivity` (its
    hypothesis is unsatisfiable for `c > 0`);
  * the genuine Kotecký–Preiss smallness lives at the INTEGRAL/measure level
    (`∫ exp(-β·E) ∂haarN` small for large `β`), driven by how `haarN`
    concentrates near the vacuum — NOT by any pointwise energy floor, and NOT by
    `inf_{w≠1} polymerEnergy > 0` (that infimum is `0`).
This mirrors the honest gap records elsewhere in the tower (e.g.
`seven_half_not_lt_one`): the combinator is a valid implication whose too-strong
sufficient hypothesis is recorded as false, so no smallness is smuggled in.

HONEST SCOPE (locked invariants)
--------------------------------
* Proves NO smallness of the real polymer activity, NO KP convergence, does NOT
  beat the `7ⁿ` entropy, and does NOT establish `ρ(T) ≤ 1/8` or `ρ(T) < 1`.
  Surface #1 stays OPEN; `kotecky_preiss_criterion` is untouched.
* Makes NO mass-gap / `μ > 0` / Surface-#1 claim. YM stays `Status: Open`.

Axiom footprint
---------------
Classical trio `{propext, Classical.choice, Quot.sound}` only; no `sorry`.
-/

import Towers.YM.Transfer
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.Positivity

namespace TheoremaAureum.Towers.YM.Wall257

open Real MeasureTheory
open TheoremaAureum.Towers.YM.Transfer
open TheoremaAureum.Towers.YM.LatticeGauge
open TheoremaAureum.Towers.YM.SU3Instances

set_option synthInstance.maxHeartbeats 400000

/-- GENUINE / UNCONDITIONAL. `(1/8)^n = exp(-(log 8)·n)`: the honest bridge from
    the geometric form to the exponential clustering form. -/
theorem inv8_pow_eq_exp_neg (n : ℕ) :
    ((1 : ℝ) / 8) ^ n = Real.exp (-(Real.log 8) * (n : ℝ)) := by
  have hlog : Real.log ((1 : ℝ) / 8) = -(Real.log 8) := by
    rw [one_div, Real.log_inv]
  rw [← Real.rpow_natCast ((1 : ℝ) / 8) n,
      Real.rpow_def_of_pos (show (0 : ℝ) < 1 / 8 by norm_num), hlog]

/-- GENUINE / UNCONDITIONAL. For a rate `r ≥ log 8`, `exp(-r·n) ≤ (1/8)^n` for
    every `n : ℕ` (`exp`-monotonicity, `n ≥ 0`). -/
theorem exp_neg_mul_le_inv8_pow {r : ℝ} (hr : Real.log 8 ≤ r) (n : ℕ) :
    Real.exp (-r * (n : ℝ)) ≤ ((1 : ℝ) / 8) ^ n := by
  rw [inv8_pow_eq_exp_neg]
  apply Real.exp_le_exp.mpr
  have hn : (0 : ℝ) ≤ (n : ℝ) := Nat.cast_nonneg n
  nlinarith [mul_nonneg (sub_nonneg.mpr hr) hn]

/-- GENUINE / UNCONDITIONAL. `(1/8)^n ≤ (1/7)^n` — the only true content behind
    "1/8 < 1/7". -/
theorem inv8_pow_le_inv7_pow (n : ℕ) :
    ((1 : ℝ) / 8) ^ n ≤ ((1 : ℝ) / 7) ^ n :=
  pow_le_pow_left (by norm_num) (by norm_num) n

/-- GENUINE / UNCONDITIONAL. At the constant-`1` (vacuum) link field the polymer
    energy is `0`: every plaquette is the identity (`plaquetteEnergy_const_one`),
    so the sum collapses to `0`. -/
theorem polymerEnergy_vacuum_eq_zero (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) :
    polymerEnergy (toGauge L (fun _ => 1)) γ = 0 := by
  unfold polymerEnergy
  refine Finset.sum_eq_zero (fun p _ => ?_)
  exact plaquetteEnergy_const_one p.1 p.2.1 p.2.2

/-- **HONEST GAP RECORD.** The uniform per-polymer energy lower bound `hLB` used
    by the combinator below is FALSE for `c > 0` and nonempty `γ`: the vacuum
    link field `w ≡ 1` has `polymerEnergy = 0`, contradicting `c·|γ| ≤ 0`. So the
    combinator's hypothesis is unsatisfiable for `c > 0`, and this file proves NO
    smallness of the real polymer activity. Analogous to `seven_half_not_lt_one`. -/
theorem vacuum_breaks_energy_lb (L : ℕ) [NeZero L]
    (γ : Finset (Lattice 4 L × Fin 4 × Fin 4)) {c : ℝ}
    (hc : 0 < c) (hγ : γ.Nonempty) :
    ¬ (∀ w, c * (γ.card : ℝ) ≤ polymerEnergy (toGauge L w) γ) := by
  intro hLB
  have h := hLB (fun _ => 1)
  rw [polymerEnergy_vacuum_eq_zero] at h
  have hpos : 0 < c * (γ.card : ℝ) :=
    mul_pos hc (by exact_mod_cast Finset.card_pos.mpr hγ)
  linarith

/-- HONEST CONDITIONAL COMBINATOR. Under the strong-coupling threshold
    `log 8 ≤ β·c` and the NAMED OPEN uniform energy lower bound
    `hLB : ∀ w, c·|γ| ≤ polymerEnergy (toGauge L w) γ`, the polymer activity is
    bounded by `(1/8)^|γ|`.

    The genuine content is the integral step (`integral_mono` +
    `integrable_polymerWeight` + `integral_const` over the probability measure
    `haarN`). HONEST: `hLB` is FALSE for `c > 0` (`vacuum_breaks_energy_lb`), so
    this establishes NO smallness of the real activity, NO KP convergence, does
    NOT beat the entropy, and does NOT give `ρ(T) < 1`. YM stays Status: Open. -/
theorem polymerActivity_le_inv8_of_energy_lb (L : ℕ) [NeZero L]
    (β c : ℝ) (γ : Finset (Lattice 4 L × Fin 4 × Fin 4))
    (hβ : 0 ≤ β)
    (hLB : ∀ w, c * (γ.card : ℝ) ≤ polymerEnergy (toGauge L w) γ)
    (hβc : Real.log 8 ≤ β * c) :
    polymerActivity L β γ ≤ ((1 : ℝ) / 8) ^ γ.card := by
  have hmono : polymerActivity L β γ ≤ Real.exp (-(β * c) * (γ.card : ℝ)) := by
    have h1 : polymerActivity L β γ
        ≤ ∫ _w, Real.exp (-(β * c) * (γ.card : ℝ)) ∂(haarN (4 * L ^ 4)) := by
      unfold polymerActivity
      apply integral_mono (integrable_polymerWeight L β γ) (integrable_const _)
      intro w
      apply Real.exp_le_exp.mpr
      nlinarith [mul_le_mul_of_nonneg_left (hLB w) hβ]
    rwa [integral_const, measure_univ, ENNReal.one_toReal, smul_eq_mul, one_mul] at h1
  exact le_trans hmono (exp_neg_mul_le_inv8_pow hβc γ.card)

/-- HONEST CONDITIONAL COROLLARY. The `(1/7)^|γ|` form, via `(1/8)^n ≤ (1/7)^n`.
    Same open hypothesis `hLB` (false for `c > 0`); proves NO smallness. -/
theorem polymerActivity_le_inv7_of_energy_lb (L : ℕ) [NeZero L]
    (β c : ℝ) (γ : Finset (Lattice 4 L × Fin 4 × Fin 4))
    (hβ : 0 ≤ β)
    (hLB : ∀ w, c * (γ.card : ℝ) ≤ polymerEnergy (toGauge L w) γ)
    (hβc : Real.log 8 ≤ β * c) :
    polymerActivity L β γ ≤ ((1 : ℝ) / 7) ^ γ.card :=
  le_trans (polymerActivity_le_inv8_of_energy_lb L β c γ hβ hLB hβc)
    (inv8_pow_le_inv7_pow γ.card)

end TheoremaAureum.Towers.YM.Wall257
