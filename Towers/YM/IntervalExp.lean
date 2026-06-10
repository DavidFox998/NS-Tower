-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Scope: PHASE-2a — a RIGOROUS, in-Lean enclosure of `Real.exp (-β₀)` for the
--   Wall256 weight constant `β₀ = 2.079416880124`, built on the Phase-2
--   `RatInterval` core (`Towers/YM/Interval.lean`). The enclosure is the
--   alternating Taylor/Lagrange bracket `[S_32 - err, S_32]` with
--   `S_32 = ∑_{k≤32} (-β₀)^k/k!` and `err = β₀^33/33!`, proved sound against
--   mathlib's `taylor_mean_remainder_lagrange`. ℚ endpoints only; NO `norm_num`
--   on ℝ for the enclosure itself.
--
-- HONEST STATUS: this file bounds ONE transcendental (`exp (-β₀)`). It does NOT
--   touch the opaque `besselI`/`w1`, does NOT bound any Bessel value or the
--   Toeplitz determinant, makes NO claim about `w1_weyl β₀ < 1/7`, and discharges
--   NONE of the open axioms of `Hw1_Surface.lean`. NO mass-gap / Surface-#1 /
--   `μ>0` claim. NOT a brick / lakefile root.
/-
IntervalExp — Phase 2a. Method (alternating Taylor with Lagrange remainder):
for `x > 0` and `N` even,
  `∑_{k≤N} (-x)^k/k!  -  x^{N+1}/(N+1)!  ≤  exp (-x)  ≤  ∑_{k≤N} (-x)^k/k!`.
We obtain this from `taylor_mean_remainder_lagrange` applied to `g t = exp (-t)`
on `[0, x]` (so the orientation `x₀ < x` holds), whose `k`-th derivative is
`(-1)^k · exp (-t)`; the Lagrange remainder is `-(exp (-ξ))·x^{N+1}/(N+1)!` with
`ξ ∈ (0,x)`, hence sits in `(-x^{N+1}/(N+1)!, 0)` because `0 < exp (-ξ) < 1`.

NB (deviation from the literal task spec): `exp_neg_interval` is given the
`RatInterval` argument the task asked for, but its output is built with `min`/`max`
so the structural invariant `lo ≤ hi` is trivial; for the point input
`ofRat β₀` this evaluates to exactly `[S_32 - err, S_32]`. The width at `N = 32`
is `err = β₀^33/33! ≈ 3.7e-27`, far inside the `5e-9` budget.
-/

import Towers.YM.Interval

namespace TheoremaAureum.Towers.YM.IntervalArith

open scoped BigOperators
open RatInterval

/-- The Wall256 weight constant `β₀ = 2.079416880124` as an exact rational. -/
def β₀_rat : ℚ := 2079416880124 / 1000000000000

/-- Partial sum `∑_{k≤N} (-x)^k / k!` (the alternating exp series, truncated). -/
def exp_neg_partial (x : ℚ) (N : ℕ) : ℚ :=
  ∑ k ∈ Finset.range (N + 1), (-x) ^ k / (k.factorial : ℚ)

/-- The Lagrange error magnitude `x^{N+1}/(N+1)!`. -/
def exp_neg_error (x : ℚ) (N : ℕ) : ℚ :=
  x ^ (N + 1) / ((N + 1).factorial : ℚ)

/-- The enclosing interval for `exp (-x)` (point case: `[S_N - err, S_N]`).
Built with `min`/`max` so `lo ≤ hi` is structural. -/
def exp_neg_interval (x : RatInterval) (N : ℕ) : RatInterval :=
  let a := exp_neg_partial x.hi N - exp_neg_error x.hi N
  let b := exp_neg_partial x.lo N
  ⟨min a b, max a b, min_le_max⟩

/-- `β₀ > 0` as a real. -/
private theorem beta0R_pos : (0 : ℝ) < (β₀_rat : ℝ) := by
  have : (0 : ℚ) < β₀_rat := by norm_num [β₀_rat]
  exact_mod_cast this

/-- The `n`-th derivative of `t ↦ exp (-t)` within `[0, β₀]` is `(-1)^n · exp (-x)`. -/
private theorem exp_neg_iteratedDerivWithin (n : ℕ) :
    ∀ x ∈ Set.Icc (0 : ℝ) (β₀_rat : ℝ),
      iteratedDerivWithin n (fun t => Real.exp (-t)) (Set.Icc 0 (β₀_rat : ℝ)) x
        = (-1 : ℝ) ^ n * Real.exp (-x) := by
  have hu : UniqueDiffOn ℝ (Set.Icc (0 : ℝ) (β₀_rat : ℝ)) := uniqueDiffOn_Icc beta0R_pos
  induction n with
  | zero =>
    intro x _
    simp [iteratedDerivWithin_zero]
  | succ n ih =>
    intro x hx
    rw [iteratedDerivWithin_succ (hu x hx)]
    have hEq : Set.EqOn (iteratedDerivWithin n (fun t => Real.exp (-t)) (Set.Icc 0 (β₀_rat : ℝ)))
        (fun y => (-1 : ℝ) ^ n * Real.exp (-y)) (Set.Icc 0 (β₀_rat : ℝ)) := fun y hy => ih y hy
    rw [derivWithin_congr hEq (ih x hx)]
    have h1 : HasDerivAt (fun y : ℝ => Real.exp (-y)) (-Real.exp (-x)) x := by
      have := (Real.hasDerivAt_exp (-x)).comp x ((hasDerivAt_id x).neg)
      simpa using this
    have hd : HasDerivAt (fun y : ℝ => (-1 : ℝ) ^ n * Real.exp (-y))
        ((-1 : ℝ) ^ n * (-Real.exp (-x))) x := h1.const_mul _
    rw [hd.hasDerivWithinAt.derivWithin (hu x hx), pow_succ]
    ring

/-- Cast of the rational partial sum to the real truncated series. -/
private theorem cast_partial_eq :
    ((exp_neg_partial β₀_rat 32 : ℚ) : ℝ)
      = ∑ k ∈ Finset.range 33, (-(β₀_rat : ℝ)) ^ k / (k.factorial : ℝ) := by
  rw [exp_neg_partial, Rat.cast_sum]
  apply Finset.sum_congr rfl
  intro k _
  rw [Rat.cast_div, Rat.cast_pow, Rat.cast_neg, Rat.cast_natCast]

/-- Mathlib's Taylor polynomial of `t ↦ exp (-t)` at `0`, evaluated at `β₀`,
equals the rational partial sum `S_32`. -/
private theorem taylorPoly_eq_partial :
    taylorWithinEval (fun t : ℝ => Real.exp (-t)) 32 (Set.Icc 0 (β₀_rat : ℝ)) 0 (β₀_rat : ℝ)
      = ((exp_neg_partial β₀_rat 32 : ℚ) : ℝ) := by
  rw [taylor_within_apply, cast_partial_eq]
  have h0 : (0 : ℝ) ∈ Set.Icc (0 : ℝ) (β₀_rat : ℝ) := ⟨le_refl _, le_of_lt beta0R_pos⟩
  apply Finset.sum_congr rfl
  intro k _
  rw [exp_neg_iteratedDerivWithin k 0 h0]
  simp only [neg_zero, Real.exp_zero, mul_one, sub_zero, smul_eq_mul]
  rw [neg_pow (β₀_rat : ℝ) k]
  ring

/-- **Phase-2a enclosure.** `exp (-β₀) ∈ exp_neg_interval (ofRat β₀) 32`, with
width `< 5·10⁻⁹`. The interval is the alternating Lagrange bracket
`[S_32 - β₀^33/33!, S_32]`. -/
theorem exp_neg_beta0_enclosure :
    ∃ I : RatInterval, exp_neg_interval (ofRat β₀_rat) 32 = I
      ∧ I.contains (Real.exp (-(β₀_rat : ℝ)))
      ∧ I.hi - I.lo < 5 / 10 ^ 9 := by
  refine ⟨exp_neg_interval (ofRat β₀_rat) 32, rfl, ?_, ?_⟩
  · -- containment
    -- The output endpoints for the point input `ofRat β₀`.
    have hab : exp_neg_partial β₀_rat 32 - exp_neg_error β₀_rat 32 ≤ exp_neg_partial β₀_rat 32 :=
      sub_le_self _ (div_nonneg (pow_nonneg (by norm_num [β₀_rat]) _) (by positivity))
    have hlo : (exp_neg_interval (ofRat β₀_rat) 32).lo
        = exp_neg_partial β₀_rat 32 - exp_neg_error β₀_rat 32 := by
      dsimp only [exp_neg_interval, RatInterval.ofRat]
      exact min_eq_left hab
    have hhi : (exp_neg_interval (ofRat β₀_rat) 32).hi = exp_neg_partial β₀_rat 32 := by
      dsimp only [exp_neg_interval, RatInterval.ofRat]
      exact max_eq_right hab
    -- Taylor data.
    have hcd : ContDiffOn ℝ 32 (fun t : ℝ => Real.exp (-t)) (Set.Icc 0 (β₀_rat : ℝ)) := by
      fun_prop
    have hcd' : ContDiffOn ℝ (33 : ℕ∞) (fun t : ℝ => Real.exp (-t))
        (Set.Icc 0 (β₀_rat : ℝ)) := by fun_prop
    have hmn : ((32 : ℕ) : ℕ∞) < (33 : ℕ∞) := by exact_mod_cast (by norm_num : (32 : ℕ) < 33)
    have hdiff : DifferentiableOn ℝ
        (iteratedDerivWithin 32 (fun t : ℝ => Real.exp (-t)) (Set.Icc 0 (β₀_rat : ℝ)))
        (Set.Ioo 0 (β₀_rat : ℝ)) :=
      (hcd'.differentiableOn_iteratedDerivWithin hmn
        (uniqueDiffOn_Icc beta0R_pos)).mono Set.Ioo_subset_Icc_self
    obtain ⟨x', hx'mem, hrem⟩ := taylor_mean_remainder_lagrange beta0R_pos hcd hdiff
    have hx'Icc : x' ∈ Set.Icc (0 : ℝ) (β₀_rat : ℝ) := Set.Ioo_subset_Icc_self hx'mem
    rw [exp_neg_iteratedDerivWithin (32 + 1) x' hx'Icc, taylorPoly_eq_partial] at hrem
    -- Positivity / smallness of the remainder.
    have hexp_pos : (0 : ℝ) < Real.exp (-x') := Real.exp_pos _
    have hexp_lt1 : Real.exp (-x') < 1 := by
      rw [Real.exp_lt_one_iff]; linarith [hx'mem.1]
    set R : ℝ := Real.exp (-x') * ((β₀_rat : ℝ) ^ (32 + 1) / ((32 + 1).factorial : ℝ)) with hR
    have hEcast : ((exp_neg_error β₀_rat 32 : ℚ) : ℝ)
        = (β₀_rat : ℝ) ^ (32 + 1) / ((32 + 1).factorial : ℝ) := by
      rw [exp_neg_error]; push_cast; ring
    have hQpos : (0 : ℝ) < (β₀_rat : ℝ) ^ (32 + 1) / ((32 + 1).factorial : ℝ) :=
      div_pos (pow_pos beta0R_pos _) (by exact_mod_cast Nat.factorial_pos (32 + 1))
    have hRpos : (0 : ℝ) < R := by rw [hR]; exact mul_pos hexp_pos hQpos
    have hRlt : R < ((exp_neg_error β₀_rat 32 : ℚ) : ℝ) := by
      rw [hEcast, hR]
      have hmul := mul_lt_mul_of_pos_right hexp_lt1 hQpos
      rwa [one_mul] at hmul
    -- exp (-β₀) = S_32 - R.
    have hexpeq : Real.exp (-(β₀_rat : ℝ)) = ((exp_neg_partial β₀_rat 32 : ℚ) : ℝ) - R := by
      have hD : (-1 : ℝ) ^ (32 + 1) * Real.exp (-x') * ((β₀_rat : ℝ) - 0) ^ (32 + 1)
            / ((32 + 1).factorial : ℝ) = -R := by
        rw [hR, show ((-1 : ℝ)) ^ (32 + 1) = -1 from by norm_num, sub_zero]; ring
      rw [hD] at hrem
      linarith [hrem]
    refine ⟨?_, ?_⟩
    · rw [hlo, Rat.cast_sub, hexpeq]; linarith [hRlt]
    · rw [hhi, hexpeq]; linarith [hRpos]
  · -- width
    have hab : exp_neg_partial β₀_rat 32 - exp_neg_error β₀_rat 32 ≤ exp_neg_partial β₀_rat 32 :=
      sub_le_self _ (div_nonneg (pow_nonneg (by norm_num [β₀_rat]) _) (by positivity))
    have hlo : (exp_neg_interval (ofRat β₀_rat) 32).lo
        = exp_neg_partial β₀_rat 32 - exp_neg_error β₀_rat 32 := by
      dsimp only [exp_neg_interval, RatInterval.ofRat]; exact min_eq_left hab
    have hhi : (exp_neg_interval (ofRat β₀_rat) 32).hi = exp_neg_partial β₀_rat 32 := by
      dsimp only [exp_neg_interval, RatInterval.ofRat]; exact max_eq_right hab
    rw [hhi, hlo,
      show exp_neg_partial β₀_rat 32 - (exp_neg_partial β₀_rat 32 - exp_neg_error β₀_rat 32)
        = exp_neg_error β₀_rat 32 from by ring, exp_neg_error]
    norm_num [β₀_rat, Nat.factorial]

/-- The concrete Phase-2a enclosure of `exp (-β₀)` at `N = 32`:
the alternating Lagrange bracket `[S_32 - β₀^33/33!, S_32]`. -/
def exp_beta0_interval : RatInterval := exp_neg_interval (ofRat β₀_rat) 32

#eval exp_beta0_interval.lo                          -- S_32 - β₀^33/33!
#eval exp_beta0_interval.hi                          -- S_32
#eval exp_beta0_interval.hi - exp_beta0_interval.lo  -- width = β₀^33/33!

end TheoremaAureum.Towers.YM.IntervalArith

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.IntervalArith.exp_neg_beta0_enclosure  -- classical trio
