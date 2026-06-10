-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Scope: PHASE-1 INFRASTRUCTURE ONLY. Defines the GENUINE modified Bessel series
--   `I_n` and proves its summability. This is NOT the opaque `besselI` of
--   `Towers/YM/Hw1_Surface.lean` (that file is untouched; its `besselI`/`w1` stay
--   opaque and its two `[NEEDS_LEMMA]` axioms stay OPEN). This file discharges
--   NOTHING: it does not prove `w1_weyl β₀ < 1/7`, does not touch `w1_eq_weyl`,
--   makes NO mass-gap / Surface-#1 / `μ>0` claim. NOT a brick / lakefile root.
/-
BesselSeries — Phase 1 of an attempt to evaluate the SU(3) Gross–Witten
single-site weight `w1_weyl β₀` in-Lean.

`besselI_series n x = ∑' k, (x/2)^(n+2k) / (k! · (n+k)!)` is the standard power
series of the modified Bessel function `I_n` (integer order `n ≥ 0`; for the
Toeplitz indices use `I_{-n} = I_n`, i.e. `besselI_series n.natAbs`).

HONEST STATUS / why the full goal is NOT reached here
----------------------------------------------------
The eventual target is the OPEN axiom `Hw1_Surface.w1_weyl_beta0_lt :
w1_weyl β₀ < 1/7`. That is a NUMERIC strict bound with a razor-thin margin:
`1/7 − w1_weyl(β₀) ≈ 3.86e-7` (CERT_Arb: `w1_weyl(β₀) ≈ 0.142856757048`). To
close it trio-only one must (i) replace `Hw1_Surface`'s opaque `besselI` with
THIS series, (ii) prove the `3×3` Toeplitz determinant and its `∑'_{k∈ℤ}`
converge with an explicit tail bound, and (iii) produce verified rational
enclosures of `Real.exp(-β₀)` and every Bessel value tight to `< 1e-7` — i.e. a
formal interval-arithmetic re-implementation of the out-of-tower CERT_Arb
computation. `norm_num` cannot decimalise `Real.exp` nor bound a `tsum`
remainder, so that is a large standalone development, NOT done here. Even if it
were, only axiom #2 would be discharged; `w1_eq_weyl` (axiom #1, the SU(3) Weyl /
Gross–Witten integration identity for the genuine Haar weight `w1`) would stay
OPEN, so `Hw1_Surface.hw1` would remain non-trio. This file is a first, honest
building block only.
-/

import Mathlib

namespace TheoremaAureum.Towers.YM.BesselSeries

open scoped Nat

/-- Power series of the modified Bessel function of the first kind, integer order
`n ≥ 0`: `I_n(x) = ∑_{k≥0} (x/2)^(n+2k) / (k! · (n+k)!)`. This is the GENUINE
series (not a stand-in); `noncomputable` only because it is a real `tsum`. -/
noncomputable def besselI_series (n : ℕ) (x : ℝ) : ℝ :=
  ∑' k : ℕ, (x / 2) ^ (n + 2 * k) / ((Nat.factorial k : ℝ) * (Nat.factorial (n + k) : ℝ))

/-- The defining series of `besselI_series` is summable for every order `n` and
every real argument `x`. Proof: dominate term-by-term (in absolute value) by
`(|x/2|^n / n!) · (|x/2|^2)^k / k!`, a constant multiple of the exponential
series `∑ y^k/k!`, using `(n+k)! ≥ n!`. -/
theorem besselI_series_summable (n : ℕ) (x : ℝ) :
    Summable (fun k : ℕ =>
      (x / 2) ^ (n + 2 * k) / ((Nat.factorial k : ℝ) * (Nat.factorial (n + k) : ℝ))) := by
  set t : ℝ := x / 2
  -- Dominating summable series: a constant times the exponential series in |t|².
  have hsum :
      Summable (fun k : ℕ =>
        (|t| ^ n / (Nat.factorial n : ℝ)) * ((|t| ^ 2) ^ k / (Nat.factorial k : ℝ))) :=
    (Real.summable_pow_div_factorial (|t| ^ 2)).mul_left _
  refine Summable.of_norm (Summable.of_nonneg_of_le (fun k => norm_nonneg _) ?_ hsum)
  intro k
  rw [Real.norm_eq_abs, abs_div, abs_pow,
      abs_of_pos (show (0 : ℝ) < (Nat.factorial k : ℝ) * (Nat.factorial (n + k) : ℝ) by positivity),
      pow_add, pow_mul, div_mul_div_comm,
      div_le_div_iff (by positivity) (by positivity)]
  -- goal: A * (↑n! * ↑k!) ≤ A * (↑k! * ↑(n+k)!), with A = |t|^n * (|t|^2)^k ≥ 0
  refine mul_le_mul_of_nonneg_left ?_ (by positivity)
  -- goal: ↑n! * ↑k! ≤ ↑k! * ↑(n+k)!
  rw [mul_comm (Nat.factorial n : ℝ) (Nat.factorial k : ℝ)]
  refine mul_le_mul_of_nonneg_left ?_ (by positivity)
  exact_mod_cast Nat.factorial_le (Nat.le_add_right n k)

end TheoremaAureum.Towers.YM.BesselSeries

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.BesselSeries.besselI_series_summable  -- classical trio
