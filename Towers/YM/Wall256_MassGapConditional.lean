/-
Wall256_MassGapConditional — HONEST CONDITIONAL Yang–Mills mass-gap apex.

Requested goal:
  `mass_gap_pos : ∃ Δ > 0, ∀ x y, |⟨W(x)W(y)⟩| ≤ C · exp(-Δ · ‖x-y‖)`.

This file lands that EXACT statement shape as an HONEST CONDITIONAL COMBINATOR
`mass_gap_pos_of_spectral_gap`, NOT an unconditional mass-gap proof.

What is GENUINE / UNCONDITIONAL here
------------------------------------
* `neg_log_pos_of_lt_one` — for `0 < ρ < 1`, the rate `Δ := -log ρ` is strictly
  positive (`Real.log_neg`). This is the real content of "a spectral radius
  strictly below one yields a positive mass/decay rate".
* `rpow_eq_exp_neg_rate` — for `0 < ρ`, `ρ ^ d = exp(-(-log ρ) · d)` (i.e.
  `ρ^d = exp(-Δ·d)` with `Δ = -log ρ`), via `Real.rpow_def_of_pos`. This is the
  honest conversion of a geometric/spectral decay `ρ^d` into the exponential
  clustering shape `exp(-Δ·d)`.

What is CONDITIONAL / OPEN here
-------------------------------
`mass_gap_pos_of_spectral_gap` derives the requested existential from TWO NAMED
OPEN surfaces, each a HYPOTHESIS (NOT `by sorry`, so NO `sorryAx`):
  1. `h1 : ρ < 1` — the strict spectral-radius / transfer-operator gap. This IS
     Yang–Mills Surface #1 (the mass gap). The real transfer operator `T_L` is
     only known to satisfy `‖T_L‖ ≤ 1` (sub-Markov; `Transfer.lean`), with
     `S_min = inf_{U≠1} wilsonAction U = 0`, so `ρ(T) < 1` does NOT follow from
     compactness and remains OPEN (locked behind the disclaimed
     `Towers/Attempts/ClusterExpansion.lean` `kotecky_preiss_criterion` `sorry`).
  2. `hcl : ∀ x y, |corr x y| ≤ C · ρ ^ (sep x y)` — the cluster-expansion output
     bounding the two-point correlator by a geometric series in the
     spectral-radius `ρ`. This is the Kotecký–Preiss convergence output, which is
     itself OPEN: Wall255 beats the `7ⁿ` polymer entropy ONLY under the open
     `q < 1/7` surface (`seven_q_lt_one_of_lt_inv_seven`), and Wall252 supplies
     only `< 1/2` (`seven_half_not_lt_one` records `< 1/2` is insufficient). No
     unconditional KP convergence exists in the tower.

HONEST SCOPE (locked invariants)
--------------------------------
* This proves NO Yang–Mills mass gap. The ENTIRE mathematical content of the
  mass gap lives in the two OPEN hypotheses `h1` (ρ < 1) and `hcl` (KP geometric
  clustering); the theorem only performs the genuine `ρ^d → exp(-Δ·d)` algebra
  on top of them.
* `ρ < 1` is NOT discharged here. In particular there is NO `kp_activity_lt_inv7`
  theorem and Wall255 does NOT establish `q < 1/7` / `ρ(T) ≤ 1/8` — those remain
  OPEN. Any claim that this file (or Wall254/Wall255) closes Surface #1, proves
  `μ > 0` / a mass gap, or discharges `kotecky_preiss_criterion` is REFUSED.
* `corr` and `sep` are ABSTRACT (an arbitrary `corr sep : E → E → ℝ`); NO real
  Wilson-loop correlator or lattice metric is constructed. YM stays Status: Open.

Axiom footprint
---------------
Classical trio `{propext, Classical.choice, Quot.sound}` only; no `sorry`.
-/

import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.Positivity

namespace TheoremaAureum.Towers.YM.Wall256

open Real

/-- GENUINE / UNCONDITIONAL. For a spectral radius `0 < ρ < 1`, the associated
    rate `Δ := -log ρ` is strictly positive. The real content of "spectral
    radius below one ⇒ positive decay rate". -/
theorem neg_log_pos_of_lt_one {ρ : ℝ} (h0 : 0 < ρ) (h1 : ρ < 1) :
    0 < -Real.log ρ := by
  have hlog : Real.log ρ < 0 := Real.log_neg h0 h1
  linarith

/-- GENUINE / UNCONDITIONAL. For `0 < ρ` and any real separation `d`, the
    geometric decay `ρ ^ d` equals the exponential clustering shape
    `exp(-Δ · d)` with rate `Δ := -log ρ`. The honest bridge from a
    spectral/geometric bound to the requested `exp(-Δ·‖x-y‖)` form. -/
theorem rpow_eq_exp_neg_rate {ρ : ℝ} (h0 : 0 < ρ) (d : ℝ) :
    ρ ^ d = Real.exp (-(-Real.log ρ) * d) := by
  rw [Real.rpow_def_of_pos h0, neg_neg]

/-- HONEST CONDITIONAL APEX. The requested mass-gap statement
    `∃ Δ > 0, ∀ x y, |corr x y| ≤ C · exp(-Δ · sep x y)`, derived from the TWO
    NAMED OPEN surfaces:
      * `h1 : ρ < 1` — the strict spectral-radius gap (= YM Surface #1, OPEN);
      * `hcl : ∀ x y, |corr x y| ≤ C · ρ ^ (sep x y)` — the Kotecký–Preiss
        geometric clustering output (OPEN; no unconditional KP in the tower).
    The rate is `Δ := -log ρ`. Proves NO mass gap: the entire content is the two
    open hypotheses; this only runs the genuine `ρ^d = exp(-Δ·d)` algebra. -/
theorem mass_gap_pos_of_spectral_gap
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    (h0 : 0 < ρ) (h1 : ρ < 1)
    (hcl : ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) := by
  refine ⟨-Real.log ρ, neg_log_pos_of_lt_one h0 h1, ?_⟩
  intro x y
  have hbound := hcl x y
  rwa [rpow_eq_exp_neg_rate h0 (sep x y)] at hbound

end TheoremaAureum.Towers.YM.Wall256
