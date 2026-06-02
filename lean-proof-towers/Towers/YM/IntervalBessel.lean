-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Scope: PHASE-2b — a RIGOROUS, in-Lean enclosure of the modified Bessel value
--   `I₀(β₀/3)` (`besselI_series 0 (β₀/3)`), the single most-needed Bessel input
--   for the SU(3) Gross–Witten weight `w1_weyl β₀`, built on the Phase-2
--   `RatInterval` core (`Towers/YM/Interval.lean`) and the genuine series of
--   `Towers/YM/BesselSeries.lean`. The enclosure is `[S_40, S_40 + err]` with
--   `S_40 = ∑_{k≤40} (β₀/6)^{2k}/(k!)²` and a geometric tail bound
--   `err = (β₀/6)^{82}/(41!)² / (1 - (β₀/6)²/42)`, proved sound against the
--   defining `tsum`. ℚ endpoints only; NO `norm_num` on ℝ for the enclosure.
--
-- HONEST STATUS: this file bounds ONE Bessel value (`I₀(β₀/3)`). It does NOT
--   touch the opaque `besselI`/`w1` of `Hw1_Surface.lean`, does NOT bound the
--   `3×3` Toeplitz determinant or the `∑'_{k∈ℤ}`, makes NO claim about
--   `w1_weyl β₀ < 1/7`, and discharges NONE of the open axioms of
--   `Hw1_Surface.lean`. NO mass-gap / Surface-#1 / `μ>0` claim. NOT a brick /
--   lakefile root.
/-
IntervalBessel — Phase 2b. Method (all-positive power series with geometric tail):
`I₀(x) = ∑_{k≥0} (x/2)^{2k}/(k!)²` has nonnegative terms, so the partial sum
`S_N = ∑_{k≤N} (x/2)^{2k}/(k!)²` is a LOWER bound (`sum_le_tsum`). For the UPPER
bound, the tail `∑_{i≥0} a_{i+N+1}` is dominated geometrically: with
`a_k = (x/2)^{2k}/(k!)²` and `t = (x/2)²`,
  `a_{i+N+1} ≤ a_{N+1} · (t/(N+2))^i`,
because `(i+N+1)!·(i+N+1)! ≥ (N+1)!·(N+2)^i · (N+1)!`
(`Nat.factorial_mul_pow_le_factorial` + `Nat.factorial_le`). Summing the
geometric majorant gives `tail ≤ a_{N+1}/(1 - t/(N+2))` whenever `t/(N+2) < 1`.
NB the denominator `1 - t/(N+2)` is LOOSER than the sharp ratio `1 - t/(N+2)²`,
hence still a valid (over-)estimate; it matches the requested error shape.

At `N = 40`, `x = β₀/3 = 0.6931389600413…`: `t/(N+2) = (β₀/6)²/42 ≈ 0.00286 < 1`
and the width `err ≈ 3.6e-137`, far inside the `5e-8` budget.
-/

import Towers.YM.IntervalExp
import Towers.YM.BesselSeries

namespace TheoremaAureum.Towers.YM.IntervalArith

open scoped BigOperators
open RatInterval
open TheoremaAureum.Towers.YM.BesselSeries

/-- Partial sum `∑_{k≤N} (x/2)^{2k} / (k!)²` of the `I₀` series. -/
def besselI0_partial (x : ℚ) (N : ℕ) : ℚ :=
  ∑ k ∈ Finset.range (N + 1), (x / 2) ^ (2 * k) / ((k.factorial : ℚ) * (k.factorial : ℚ))

/-- Geometric tail bound `(x/2)^{2N+2}/((N+1)!)² / (1 - (x/2)²/(N+2))`. -/
def besselI0_error (x : ℚ) (N : ℕ) : ℚ :=
  (x / 2) ^ (2 * N + 2) / (((N + 1).factorial : ℚ) * ((N + 1).factorial : ℚ))
    / (1 - (x / 2) ^ 2 / ((N : ℚ) + 2))

/-- The enclosing interval for `I₀(x)` (point case: `[S_N, S_N + err]`).
Built with `min`/`max` so `lo ≤ hi` is structural. -/
def besselI0_interval (x : RatInterval) (N : ℕ) : RatInterval :=
  let a := besselI0_partial x.lo N
  let b := besselI0_partial x.hi N + besselI0_error x.hi N
  ⟨min a b, max a b, min_le_max⟩

/-- **Termwise geometric tail bound** for the `I₀` series at a real argument `y`.
For `t = (y/2)²` with `t/(N+2) < 1`, the tail past `N+1` terms is dominated by the
geometric majorant `a_{N+1}/(1 - t/(N+2))`. -/
private theorem bessel0_term_tail_le (y : ℝ) (N : ℕ)
    (hr1 : (y / 2) ^ 2 / ((N : ℝ) + 2) < 1) :
    (∑' i : ℕ, (y / 2) ^ (2 * (i + (N + 1)))
        / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1)).factorial : ℝ)))
      ≤ ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
        / (1 - (y / 2) ^ 2 / ((N : ℝ) + 2)) := by
  have hr0 : 0 ≤ (y / 2) ^ 2 / ((N : ℝ) + 2) := by positivity
  -- Summability of the bessel-0 term function `a k = (y/2)^(2k)/(k!)²`.
  have hT : Summable (fun k : ℕ =>
      (y / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ))) :=
    (besselI_series_summable 0 y).congr (fun k => by simp [Nat.zero_add])
  have htail_summable : Summable (fun i : ℕ =>
      (y / 2) ^ (2 * (i + (N + 1)))
        / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1)).factorial : ℝ))) := by
    have h := (summable_nat_add_iff (N + 1)).mpr hT
    exact h
  have hgeom_summable : Summable (fun i : ℕ =>
      ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
        * ((y / 2) ^ 2 / ((N : ℝ) + 2)) ^ i) :=
    (summable_geometric_of_lt_one hr0 hr1).mul_left _
  -- Termwise domination.
  have hterm : ∀ i : ℕ,
      (y / 2) ^ (2 * (i + (N + 1)))
          / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1)).factorial : ℝ))
        ≤ ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
          * ((y / 2) ^ 2 / ((N : ℝ) + 2)) ^ i := by
    intro i
    have h1 : (N + 1).factorial * (N + 2) ^ i ≤ (i + (N + 1)).factorial := by
      have h := Nat.factorial_mul_pow_le_factorial (m := N + 1) (n := i)
      have he : N + 1 + i = i + (N + 1) := by omega
      rw [he] at h
      exact h
    have h2 : (N + 1).factorial ≤ (i + (N + 1)).factorial := Nat.factorial_le (by omega)
    have hnat : (N + 1).factorial * (N + 1).factorial * (N + 2) ^ i
        ≤ (i + (N + 1)).factorial * (i + (N + 1)).factorial := by
      calc (N + 1).factorial * (N + 1).factorial * (N + 2) ^ i
          = ((N + 1).factorial * (N + 2) ^ i) * (N + 1).factorial := by ring
        _ ≤ (i + (N + 1)).factorial * (i + (N + 1)).factorial := Nat.mul_le_mul h1 h2
    have hnatR : ((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ) * ((N : ℝ) + 2) ^ i
        ≤ ((i + (N + 1)).factorial : ℝ) * ((i + (N + 1)).factorial : ℝ) := by
      exact_mod_cast hnat
    rw [pow_mul, pow_mul]
    set P := (y / 2) ^ 2 with hP
    have hPnonneg : 0 ≤ P := by rw [hP]; positivity
    rw [div_pow, div_mul_div_comm, ← pow_add, show N + 1 + i = i + (N + 1) from by omega]
    exact div_le_div_of_nonneg_left (pow_nonneg hPnonneg _) (by positivity) hnatR
  calc (∑' i : ℕ, (y / 2) ^ (2 * (i + (N + 1)))
          / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1)).factorial : ℝ)))
      ≤ ∑' i : ℕ, ((y / 2) ^ (2 * (N + 1))
            / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
          * ((y / 2) ^ 2 / ((N : ℝ) + 2)) ^ i :=
        tsum_le_tsum hterm htail_summable hgeom_summable
    _ = ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
          * ∑' i : ℕ, ((y / 2) ^ 2 / ((N : ℝ) + 2)) ^ i := tsum_mul_left
    _ = ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
          * (1 - (y / 2) ^ 2 / ((N : ℝ) + 2))⁻¹ := by
        rw [tsum_geometric_of_lt_one hr0 hr1]
    _ = ((y / 2) ^ (2 * (N + 1)) / (((N + 1).factorial : ℝ) * ((N + 1).factorial : ℝ)))
          / (1 - (y / 2) ^ 2 / ((N : ℝ) + 2)) := by ring

/-- **Phase-2b enclosure.** `I₀(β₀/3) ∈ besselI0_interval (ofRat (β₀/3)) 40`, with
width `< 5·10⁻⁸`. The interval is `[S_40, S_40 + (β₀/6)^82/(41!)²/(1-(β₀/6)²/42)]`. -/
theorem besselI0_beta0_enclosure :
    ∃ I : RatInterval, besselI0_interval (ofRat (β₀_rat / 3)) 40 = I
      ∧ I.contains (besselI_series 0 ((β₀_rat / 3 : ℚ) : ℝ))
      ∧ I.hi - I.lo < 5 / 10 ^ 8 := by
  set q : ℚ := β₀_rat / 3 with hq
  have hqpos : 0 < q := by rw [hq]; norm_num [β₀_rat]
  have hr1Q : (q / 2) ^ 2 / ((40 : ℚ) + 2) < 1 := by rw [hq]; norm_num [β₀_rat]
  -- the bessel series as the clean term sum, and pointwise nonnegativity
  have hTsum : Summable (fun k : ℕ =>
      ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ))) :=
    (besselI_series_summable 0 (q : ℝ)).congr (fun k => by simp [Nat.zero_add])
  have hg_nonneg : ∀ k : ℕ,
      0 ≤ ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)) := by
    intro k; rw [pow_mul]; positivity
  have bessel0_eq : besselI_series 0 ((q : ℝ))
      = ∑' k : ℕ, ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)) := by
    unfold besselI_series
    exact tsum_congr (fun k => by simp [Nat.zero_add])
  -- cast lemmas
  have hcast_partial : ((besselI0_partial q 40 : ℚ) : ℝ)
      = ∑ k ∈ Finset.range (40 + 1),
          ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)) := by
    unfold besselI0_partial
    rw [Rat.cast_sum]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    push_cast; ring
  have hcast_error : ((besselI0_error q 40 : ℚ) : ℝ)
      = ((q : ℝ) / 2) ^ (2 * (40 + 1)) / (((40 + 1).factorial : ℝ) * ((40 + 1).factorial : ℝ))
        / (1 - ((q : ℝ) / 2) ^ 2 / ((40 : ℝ) + 2)) := by
    unfold besselI0_error
    push_cast; ring
  -- error nonneg
  have herr_nonneg : 0 ≤ besselI0_error q 40 := by
    unfold besselI0_error
    apply div_nonneg
    · exact div_nonneg (pow_nonneg (div_nonneg hqpos.le (by norm_num)) _) (by positivity)
    · push_cast; linarith [hr1Q]
  -- endpoint identities for the point interval
  have hab : besselI0_partial q 40 ≤ besselI0_partial q 40 + besselI0_error q 40 :=
    le_add_of_nonneg_right herr_nonneg
  have hlo : (besselI0_interval (ofRat q) 40).lo = besselI0_partial q 40 := by
    dsimp only [besselI0_interval, RatInterval.ofRat]; exact min_eq_left hab
  have hhi : (besselI0_interval (ofRat q) 40).hi
      = besselI0_partial q 40 + besselI0_error q 40 := by
    dsimp only [besselI0_interval, RatInterval.ofRat]; exact max_eq_right hab
  refine ⟨besselI0_interval (ofRat q) 40, rfl, ⟨?_, ?_⟩, ?_⟩
  · -- lower bound
    rw [hlo, hcast_partial, bessel0_eq]
    exact sum_le_tsum _ (fun i _ => hg_nonneg i) hTsum
  · -- upper bound
    rw [hhi]
    have hsplit : besselI_series 0 ((q : ℝ))
        = (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)))
          + ∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)))
              / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1)).factorial : ℝ)) := by
      rw [bessel0_eq]; exact (sum_add_tsum_nat_add (40 + 1) hTsum).symm
    have htail_le : (∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)))
            / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1)).factorial : ℝ)))
          ≤ ((besselI0_error q 40 : ℚ) : ℝ) := by
      have h := bessel0_term_tail_le (q : ℝ) 40 (by exact_mod_cast hr1Q)
      rw [hcast_error]
      simpa only [Nat.cast_ofNat] using h
    calc besselI_series 0 ((q : ℝ))
        = (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)))
          + ∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)))
              / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1)).factorial : ℝ)) := hsplit
      _ ≤ (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k) / ((k.factorial : ℝ) * (k.factorial : ℝ)))
          + ((besselI0_error q 40 : ℚ) : ℝ) := add_le_add_left htail_le _
      _ = ((besselI0_partial q 40 : ℚ) : ℝ) + ((besselI0_error q 40 : ℚ) : ℝ) := by
            rw [hcast_partial]
      _ = ((besselI0_partial q 40 + besselI0_error q 40 : ℚ) : ℝ) := by rw [Rat.cast_add]
  · -- width
    rw [hhi, hlo,
      show besselI0_partial q 40 + besselI0_error q 40 - besselI0_partial q 40
        = besselI0_error q 40 from by ring, hq]
    norm_num [besselI0_error, β₀_rat, Nat.factorial]

/-- The concrete Phase-2b enclosure of `I₀(β₀/3)` at `N = 40`. -/
def besselI0_beta0_interval : RatInterval := besselI0_interval (ofRat (β₀_rat / 3)) 40

#eval besselI0_beta0_interval.lo                                       -- S_40
#eval besselI0_beta0_interval.hi                                       -- S_40 + err
#eval besselI0_beta0_interval.hi - besselI0_beta0_interval.lo          -- width = err

/-! ### Phase 2c — enclosure of `I₁(β₀/3)`

`I₁(x) = ∑_{k≥0} (x/2)^(2k+1) / (k!·(k+1)!)` (all-positive for `x ≥ 0`), so the
partial sum is a LOWER bound and the tail past `N+1` terms is dominated by the
geometric majorant `a_{N+1}/(1 - t/(N+3))` with `a_k = (x/2)^(2k+1)/(k!·(k+1)!)`,
`t = (x/2)²`. The looser `N+3` denominator (vs the sharp `(N+2)(N+3)`) keeps the
requested error shape and is still a valid over-estimate. Same honest scope as the
`I₀` block: bounds ONE Bessel value, discharges NOTHING, NO mass-gap claim. -/

/-- Partial sum `∑_{k≤N} (x/2)^(2k+1) / (k!·(k+1)!)` of the `I₁` series. -/
def besselI1_partial (x : ℚ) (N : ℕ) : ℚ :=
  ∑ k ∈ Finset.range (N + 1),
    (x / 2) ^ (2 * k + 1) / ((k.factorial : ℚ) * ((k + 1).factorial : ℚ))

/-- Geometric tail bound `(x/2)^(2N+3)/((N+1)!·(N+2)!) / (1 - (x/2)²/(N+3))`. -/
def besselI1_error (x : ℚ) (N : ℕ) : ℚ :=
  (x / 2) ^ (2 * N + 3) / (((N + 1).factorial : ℚ) * ((N + 2).factorial : ℚ))
    / (1 - (x / 2) ^ 2 / ((N : ℚ) + 3))

/-- The enclosing interval for `I₁(x)` (point case: `[S_N, S_N + err]`).
Built with `min`/`max` so `lo ≤ hi` is structural. -/
def besselI1_interval (x : RatInterval) (N : ℕ) : RatInterval :=
  let a := besselI1_partial x.lo N
  let b := besselI1_partial x.hi N + besselI1_error x.hi N
  ⟨min a b, max a b, min_le_max⟩

/-- **Termwise geometric tail bound** for the `I₁` series at a real argument `y ≥ 0`.
For `t = (y/2)²` with `t/(N+3) < 1`, the tail past `N+1` terms is dominated by the
geometric majorant `a_{N+1}/(1 - t/(N+3))`. -/
private theorem bessel1_term_tail_le (y : ℝ) (N : ℕ) (hy : 0 ≤ y)
    (hr1 : (y / 2) ^ 2 / ((N : ℝ) + 3) < 1) :
    (∑' i : ℕ, (y / 2) ^ (2 * (i + (N + 1)) + 1)
        / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1) + 1).factorial : ℝ)))
      ≤ ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
        / (1 - (y / 2) ^ 2 / ((N : ℝ) + 3)) := by
  have hr0 : 0 ≤ (y / 2) ^ 2 / ((N : ℝ) + 3) := by positivity
  -- Summability of the bessel-1 term function `a k = (y/2)^(2k+1)/(k!·(k+1)!)`.
  have hT1 : Summable (fun k : ℕ =>
      (y / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ))) :=
    (besselI_series_summable 1 y).congr (fun k => by
      rw [show (1 : ℕ) + 2 * k = 2 * k + 1 from by omega,
          show (1 : ℕ) + k = k + 1 from by omega])
  have htail_summable : Summable (fun i : ℕ =>
      (y / 2) ^ (2 * (i + (N + 1)) + 1)
        / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1) + 1).factorial : ℝ))) := by
    have h := (summable_nat_add_iff (N + 1)).mpr hT1
    exact h
  have hgeom_summable : Summable (fun i : ℕ =>
      ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
        * ((y / 2) ^ 2 / ((N : ℝ) + 3)) ^ i) :=
    (summable_geometric_of_lt_one hr0 hr1).mul_left _
  -- Termwise domination.
  have hterm : ∀ i : ℕ,
      (y / 2) ^ (2 * (i + (N + 1)) + 1)
          / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1) + 1).factorial : ℝ))
        ≤ ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          * ((y / 2) ^ 2 / ((N : ℝ) + 3)) ^ i := by
    intro i
    have h1 : (N + 1).factorial ≤ (i + (N + 1)).factorial := Nat.factorial_le (by omega)
    have h2 : (N + 2).factorial * (N + 3) ^ i ≤ (i + (N + 1) + 1).factorial := by
      have h := Nat.factorial_mul_pow_le_factorial (m := N + 2) (n := i)
      have he : N + 2 + i = i + (N + 1) + 1 := by omega
      rw [he] at h
      exact h
    have hnat : (N + 1).factorial * (N + 2).factorial * (N + 3) ^ i
        ≤ (i + (N + 1)).factorial * (i + (N + 1) + 1).factorial := by
      calc (N + 1).factorial * (N + 2).factorial * (N + 3) ^ i
          = (N + 1).factorial * ((N + 2).factorial * (N + 3) ^ i) := by ring
        _ ≤ (i + (N + 1)).factorial * (i + (N + 1) + 1).factorial := Nat.mul_le_mul h1 h2
    have hnatR : ((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ) * ((N : ℝ) + 3) ^ i
        ≤ ((i + (N + 1)).factorial : ℝ) * ((i + (N + 1) + 1).factorial : ℝ) := by
      exact_mod_cast hnat
    have hy2 : (0 : ℝ) ≤ y / 2 := by linarith
    have hnum : (y / 2) ^ (2 * (i + (N + 1)) + 1)
        = (y / 2) ^ (2 * (N + 1) + 1) * ((y / 2) ^ 2) ^ i := by
      rw [show 2 * (i + (N + 1)) + 1 = (2 * (N + 1) + 1) + 2 * i from by ring, pow_add, pow_mul]
    have hgeomterm : ((y / 2) ^ 2 / ((N : ℝ) + 3)) ^ i
        = ((y / 2) ^ 2) ^ i / ((N : ℝ) + 3) ^ i := div_pow _ _ _
    rw [hnum, hgeomterm]
    rw [show ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          * (((y / 2) ^ 2) ^ i / ((N : ℝ) + 3) ^ i)
        = ((y / 2) ^ (2 * (N + 1) + 1) * ((y / 2) ^ 2) ^ i)
          / ((((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)) * ((N : ℝ) + 3) ^ i)
        from by ring]
    exact div_le_div_of_nonneg_left
      (mul_nonneg (pow_nonneg hy2 _) (pow_nonneg (sq_nonneg _) _))
      (by positivity) hnatR
  calc (∑' i : ℕ, (y / 2) ^ (2 * (i + (N + 1)) + 1)
          / (((i + (N + 1)).factorial : ℝ) * ((i + (N + 1) + 1).factorial : ℝ)))
      ≤ ∑' i : ℕ, ((y / 2) ^ (2 * (N + 1) + 1)
            / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          * ((y / 2) ^ 2 / ((N : ℝ) + 3)) ^ i :=
        tsum_le_tsum hterm htail_summable hgeom_summable
    _ = ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          * ∑' i : ℕ, ((y / 2) ^ 2 / ((N : ℝ) + 3)) ^ i := tsum_mul_left
    _ = ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          * (1 - (y / 2) ^ 2 / ((N : ℝ) + 3))⁻¹ := by
        rw [tsum_geometric_of_lt_one hr0 hr1]
    _ = ((y / 2) ^ (2 * (N + 1) + 1) / (((N + 1).factorial : ℝ) * ((N + 2).factorial : ℝ)))
          / (1 - (y / 2) ^ 2 / ((N : ℝ) + 3)) := by ring

/-- **Phase-2c enclosure.** `I₁(β₀/3) ∈ besselI1_interval (ofRat (β₀/3)) 40`, with
width `< 5·10⁻⁸`. The interval is `[S_40, S_40 + (β₀/6)^83/(41!·42!)/(1-(β₀/6)²/43)]`.
Scope: soundness is established here only for the concrete point `ofRat (β₀/3)` (where
`0 < q` is discharged); this is NOT a fully general interval theorem for arbitrary `q`,
and it discharges no YM surface / makes no mass-gap claim. -/
theorem besselI1_beta0_enclosure :
    ∃ I : RatInterval, besselI1_interval (ofRat (β₀_rat / 3)) 40 = I
      ∧ I.contains (besselI_series 1 ((β₀_rat / 3 : ℚ) : ℝ))
      ∧ I.hi - I.lo < 5 / 10 ^ 8 := by
  set q : ℚ := β₀_rat / 3 with hq
  have hqpos : 0 < q := by rw [hq]; norm_num [β₀_rat]
  have hqR : (0 : ℝ) < (q : ℝ) := by exact_mod_cast hqpos
  have hr1Q : (q / 2) ^ 2 / ((40 : ℚ) + 3) < 1 := by rw [hq]; norm_num [β₀_rat]
  have hTsum : Summable (fun k : ℕ =>
      ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ))) :=
    (besselI_series_summable 1 (q : ℝ)).congr (fun k => by
      rw [show (1 : ℕ) + 2 * k = 2 * k + 1 from by omega,
          show (1 : ℕ) + k = k + 1 from by omega])
  have hg_nonneg : ∀ k : ℕ,
      0 ≤ ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)) := by
    intro k
    exact div_nonneg (pow_nonneg (by linarith) _) (by positivity)
  have bessel1_eq : besselI_series 1 ((q : ℝ))
      = ∑' k : ℕ, ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)) := by
    unfold besselI_series
    exact tsum_congr (fun k => by
      rw [show (1 : ℕ) + 2 * k = 2 * k + 1 from by omega,
          show (1 : ℕ) + k = k + 1 from by omega])
  have hcast_partial : ((besselI1_partial q 40 : ℚ) : ℝ)
      = ∑ k ∈ Finset.range (40 + 1),
          ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)) := by
    unfold besselI1_partial
    rw [Rat.cast_sum]
    refine Finset.sum_congr rfl (fun k _ => ?_)
    push_cast; ring
  have hcast_error : ((besselI1_error q 40 : ℚ) : ℝ)
      = ((q : ℝ) / 2) ^ (2 * (40 + 1) + 1)
          / (((40 + 1).factorial : ℝ) * ((40 + 2).factorial : ℝ))
        / (1 - ((q : ℝ) / 2) ^ 2 / ((40 : ℝ) + 3)) := by
    unfold besselI1_error
    push_cast; ring
  have herr_nonneg : 0 ≤ besselI1_error q 40 := by
    unfold besselI1_error
    apply div_nonneg
    · exact div_nonneg (pow_nonneg (div_nonneg hqpos.le (by norm_num)) _) (by positivity)
    · push_cast; linarith [hr1Q]
  have hab : besselI1_partial q 40 ≤ besselI1_partial q 40 + besselI1_error q 40 :=
    le_add_of_nonneg_right herr_nonneg
  have hlo : (besselI1_interval (ofRat q) 40).lo = besselI1_partial q 40 := by
    dsimp only [besselI1_interval, RatInterval.ofRat]; exact min_eq_left hab
  have hhi : (besselI1_interval (ofRat q) 40).hi
      = besselI1_partial q 40 + besselI1_error q 40 := by
    dsimp only [besselI1_interval, RatInterval.ofRat]; exact max_eq_right hab
  refine ⟨besselI1_interval (ofRat q) 40, rfl, ⟨?_, ?_⟩, ?_⟩
  · -- lower bound
    rw [hlo, hcast_partial, bessel1_eq]
    exact sum_le_tsum _ (fun i _ => hg_nonneg i) hTsum
  · -- upper bound
    rw [hhi]
    have hsplit : besselI_series 1 ((q : ℝ))
        = (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)))
          + ∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)) + 1)
              / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1) + 1).factorial : ℝ)) := by
      rw [bessel1_eq]; exact (sum_add_tsum_nat_add (40 + 1) hTsum).symm
    have htail_le : (∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)) + 1)
            / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1) + 1).factorial : ℝ)))
          ≤ ((besselI1_error q 40 : ℚ) : ℝ) := by
      have h := bessel1_term_tail_le (q : ℝ) 40 hqR.le (by exact_mod_cast hr1Q)
      rw [hcast_error]
      simpa only [Nat.cast_ofNat] using h
    calc besselI_series 1 ((q : ℝ))
        = (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)))
          + ∑' i : ℕ, ((q : ℝ) / 2) ^ (2 * (i + (40 + 1)) + 1)
              / (((i + (40 + 1)).factorial : ℝ) * ((i + (40 + 1) + 1).factorial : ℝ)) := hsplit
      _ ≤ (∑ k ∈ Finset.range (40 + 1),
            ((q : ℝ) / 2) ^ (2 * k + 1) / ((k.factorial : ℝ) * ((k + 1).factorial : ℝ)))
          + ((besselI1_error q 40 : ℚ) : ℝ) := add_le_add_left htail_le _
      _ = ((besselI1_partial q 40 : ℚ) : ℝ) + ((besselI1_error q 40 : ℚ) : ℝ) := by
            rw [hcast_partial]
      _ = ((besselI1_partial q 40 + besselI1_error q 40 : ℚ) : ℝ) := by rw [Rat.cast_add]
  · -- width
    rw [hhi, hlo,
      show besselI1_partial q 40 + besselI1_error q 40 - besselI1_partial q 40
        = besselI1_error q 40 from by ring, hq]
    norm_num [besselI1_error, β₀_rat, Nat.factorial]

/-- The concrete Phase-2c enclosure of `I₁(β₀/3)` at `N = 40`. -/
def besselI1_beta0_interval : RatInterval := besselI1_interval (ofRat (β₀_rat / 3)) 40

#eval besselI1_beta0_interval.lo                                       -- S_40
#eval besselI1_beta0_interval.hi                                       -- S_40 + err
#eval besselI1_beta0_interval.hi - besselI1_beta0_interval.lo          -- width = err

end TheoremaAureum.Towers.YM.IntervalArith

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
#print axioms TheoremaAureum.Towers.YM.IntervalArith.besselI0_beta0_enclosure
#print axioms TheoremaAureum.Towers.YM.IntervalArith.besselI1_beta0_enclosure
