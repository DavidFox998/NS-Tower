-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Scope: PHASE-3 INFRASTRUCTURE ONLY — a rigorous, machine-checked RATIONAL
--   interval ENCLOSURE of the determinant of the real 3×3 Bessel–Toeplitz matrix
--   `B(k)` with entries `B(k)_{ij} = I_{|i-j-k|}(β₀/3)` (modified Bessel `I_n`,
--   here the genuine power series `besselI_series`), for every shift `k`.
--   • `toeplitz_det_contains k` : `(B(k)).det ∈ toeplitzDetInterval k` (an honest
--     real-membership certificate; `det` is `Matrix.det_fin_three`).
--   • `toeplitz_det_width_lt k` : each enclosure has width `< 2·10⁻⁹`.
--   • `toeplitz_det_total_width_lt` : summed over the 51 shifts `k = -25..25`,
--     the total enclosure width is `< 1.02·10⁻⁷`.
--   The width bound is UNIFORM in `k` (`width(det) ≤ 18·U²·E`, `U = 42` the entry
--   magnitude bound, `E = 10⁻¹⁴` the per-entry width from the order-40 series
--   truncation), so the THEOREM PROOFS use NO per-`k` kernel computation
--   (`decide`/`native_decide`) and NO kernel reduction over `k` — `native_decide`
--   is FORBIDDEN and absent everywhere. The only per-`k` `decide` is in the two
--   optional `#eval decide` diagnostics at the end, which are compiler-evaluated
--   (NOT kernel) and contribute NO axioms to the theorems above.
-- HONESTY: this file computes a determinant ENCLOSURE only. It proves NOTHING
--   about the opaque `besselI`/`w1`, the Weyl/Toeplitz identity `w1_eq_weyl`, or
--   the bound `w1_weyl β₀ < 1/7` of `Hw1_Surface.lean`; it discharges NO YM/NS
--   open surface and makes NO mass-gap / Surface-#1 / `μ>0` / Clay claim. The
--   `β₀/3` argument (not `β₀`) is the Gross–Witten Toeplitz argument; entries are
--   pinned at the rational point `β₀_rat/3` for soundness. NOT a brick / lakefile
--   root; verified via the direct-lean bypass (pin `v4.12.0` unresolved).

import Towers.YM.Interval
import Towers.YM.IntervalBessel

namespace TheoremaAureum.Towers.YM.IntervalArith
open scoped BigOperators
open RatInterval
open TheoremaAureum.Towers.YM.BesselSeries

/-! ### §1  RatInterval width / magnitude lemmas (uniform, no kernel compute). -/
namespace RatInterval

def width (I : RatInterval) : ℚ := I.hi - I.lo

theorem width_nonneg (I : RatInterval) : 0 ≤ I.width := by
  simp only [width]; linarith [I.isLE]

theorem add_width (I J : RatInterval) : (I.add J).width = I.width + J.width := by
  simp only [width, add]; ring

theorem neg_width (I : RatInterval) : (I.neg).width = I.width := by
  simp only [width, neg]; ring

theorem sub_width (I J : RatInterval) : (I.sub J).width = I.width + J.width := by
  rw [sub, add_width, neg_width]

theorem mul_lo_nonneg {I J : RatInterval} (hI : 0 ≤ I.lo) (hJ : 0 ≤ J.lo) :
    0 ≤ (I.mul J).lo := by
  have hb : 0 ≤ I.hi := le_trans hI I.isLE
  have hd : 0 ≤ J.hi := le_trans hJ J.isLE
  simp only [mul]
  exact le_min (le_min (mul_nonneg hI hJ) (mul_nonneg hI hd))
    (le_min (mul_nonneg hb hJ) (mul_nonneg hb hd))

theorem mul_hi_le {I J : RatInterval} (hI : 0 ≤ I.lo) (hJ : 0 ≤ J.lo) :
    (I.mul J).hi ≤ I.hi * J.hi := by
  have hb : 0 ≤ I.hi := le_trans hI I.isLE
  simp only [mul]
  refine max_le (max_le ?_ ?_) (max_le ?_ ?_)
  · exact mul_le_mul I.isLE J.isLE hJ hb
  · exact mul_le_mul_of_nonneg_right I.isLE (le_trans hJ J.isLE)
  · exact mul_le_mul_of_nonneg_left J.isLE hb
  · exact le_refl _

theorem mul_lo_ge {I J : RatInterval} (hI : 0 ≤ I.lo) (hJ : 0 ≤ J.lo) :
    I.lo * J.lo ≤ (I.mul J).lo := by
  have hb : 0 ≤ I.hi := le_trans hI I.isLE
  simp only [mul]
  exact le_min (le_min (le_refl _) (mul_le_mul_of_nonneg_left J.isLE hI))
    (le_min (mul_le_mul_of_nonneg_right I.isLE hJ) (mul_le_mul I.isLE J.isLE hJ hb))

theorem mul_width_le {I J : RatInterval} (hI : 0 ≤ I.lo) (hJ : 0 ≤ J.lo) :
    (I.mul J).width ≤ I.hi * J.width + J.hi * I.width := by
  have hhi := mul_hi_le hI hJ
  have hlo := mul_lo_ge hI hJ
  have hprod : 0 ≤ (I.hi - I.lo) * (J.hi - J.lo) :=
    mul_nonneg (sub_nonneg.mpr I.isLE) (sub_nonneg.mpr J.isLE)
  simp only [width] at *
  nlinarith [hhi, hlo, hprod]

/-- Width of a positive triple product, uniform bound `3 U² E`. -/
theorem triple_width_le {A B C : RatInterval} (U E : ℚ)
    (hA0 : 0 ≤ A.lo) (hAU : A.hi ≤ U) (hAE : A.width ≤ E)
    (hB0 : 0 ≤ B.lo) (hBU : B.hi ≤ U) (hBE : B.width ≤ E)
    (hC0 : 0 ≤ C.lo) (hCU : C.hi ≤ U) (hCE : C.width ≤ E)
    (hU : 0 ≤ U) (_hE : 0 ≤ E) :
    ((A.mul B).mul C).width ≤ 3 * U ^ 2 * E := by
  have hBhi0 : 0 ≤ B.hi := le_trans hB0 B.isLE
  have hABlo : 0 ≤ (A.mul B).lo := mul_lo_nonneg hA0 hB0
  have hABhi : (A.mul B).hi ≤ U * U := le_trans (mul_hi_le hA0 hB0) (mul_le_mul hAU hBU hBhi0 hU)
  have hABw : (A.mul B).width ≤ U * E + U * E := by
    have h := mul_width_le hA0 hB0
    have t1 : A.hi * B.width ≤ U * E := mul_le_mul hAU hBE (width_nonneg B) hU
    have t2 : B.hi * A.width ≤ U * E := mul_le_mul hBU hAE (width_nonneg A) hU
    linarith
  have hABwnn : 0 ≤ (A.mul B).width := width_nonneg _
  have hmain := mul_width_le hABlo hC0
  have s1 : (A.mul B).hi * C.width ≤ U * U * E :=
    mul_le_mul hABhi hCE (width_nonneg C) (by positivity)
  have s2 : C.hi * (A.mul B).width ≤ U * (U * E + U * E) :=
    mul_le_mul hCU hABw hABwnn hU
  calc ((A.mul B).mul C).width
      ≤ (A.mul B).hi * C.width + C.hi * (A.mul B).width := hmain
    _ ≤ U * U * E + U * (U * E + U * E) := by linarith [s1, s2]
    _ = 3 * U ^ 2 * E := by ring

end RatInterval

/-! ### §2  Per-order Bessel entry bounds at `β₀/3` (uniform in order). -/

/-- `Iₙ(β₀/3) ∈ besselIn_beta0_interval n`. -/
theorem besselIn_beta0_contains (m : ℕ) :
    (besselIn_beta0_interval m).contains (besselI_series m ((β₀_rat / 3 : ℚ) : ℝ)) := by
  obtain ⟨I, hI, hc, _⟩ := besselIn_beta0_enclosure m
  rw [show besselIn_beta0_interval m = I from hI]
  exact hc

theorem besselIn_error_beta0_nonneg (m : ℕ) : 0 ≤ besselIn_error m (β₀_rat / 3) 40 := by
  unfold besselIn_error
  apply div_nonneg
  · exact div_nonneg (pow_nonneg (by norm_num [β₀_rat]) _) (by positivity)
  · rw [sub_nonneg, div_le_one (by positivity)]
    have hb : ((β₀_rat / 3) / 2) ^ 2 ≤ 1 := by norm_num [β₀_rat]
    push_cast
    nlinarith [Nat.cast_nonneg (α := ℚ) m, hb]

/-- Tight comparison `errorₙ ≤ error₀` (replicates the internal `hcmp`). -/
theorem besselIn_error_le_I0 (m : ℕ) :
    besselIn_error m (β₀_rat / 3) 40 ≤ besselI0_error (β₀_rat / 3) 40 := by
  set x : ℚ := β₀_rat / 3 with hx
  have hx2nn : (0 : ℚ) ≤ x / 2 := by rw [hx]; norm_num [β₀_rat]
  have hx2le1 : x / 2 ≤ 1 := by rw [hx]; norm_num [β₀_rat]
  have hF1 : (0 : ℚ) < ((40 + 1).factorial : ℚ) := by positivity
  have hDr0 : (0 : ℚ) < 1 - (x / 2) ^ 2 / (((40 : ℕ) : ℚ) + 2) := by rw [hx]; norm_num [β₀_rat]
  have hDle : 1 - (x / 2) ^ 2 / (((40 : ℕ) : ℚ) + 2)
      ≤ 1 - (x / 2) ^ 2 / ((m : ℚ) + ((40 : ℕ) : ℚ) + 2) := by
    have hb : (x / 2) ^ 2 / ((m : ℚ) + ((40 : ℕ) : ℚ) + 2)
        ≤ (x / 2) ^ 2 / (((40 : ℕ) : ℚ) + 2) :=
      div_le_div_of_nonneg_left (by positivity) (by positivity) (by push_cast; linarith)
    linarith
  have hpow : (x / 2) ^ (m + 2 * (40 + 1)) ≤ (x / 2) ^ (2 * 40 + 2) := by
    rw [show m + 2 * (40 + 1) = (2 * 40 + 2) + m from by omega, pow_add]
    calc (x / 2) ^ (2 * 40 + 2) * (x / 2) ^ m
        ≤ (x / 2) ^ (2 * 40 + 2) * 1 :=
          mul_le_mul_of_nonneg_left (pow_le_one m hx2nn hx2le1) (pow_nonneg hx2nn _)
      _ = (x / 2) ^ (2 * 40 + 2) := mul_one _
  have hfacN : ((40 + 1).factorial : ℚ) ≤ ((m + (40 + 1)).factorial : ℚ) := by
    exact_mod_cast Nat.factorial_le (Nat.le_add_left (40 + 1) m)
  unfold besselIn_error besselI0_error
  refine le_trans (div_le_div_of_nonneg_left ?_ hDr0 hDle) ?_
  · exact div_nonneg (pow_nonneg hx2nn _) (by positivity)
  · exact (div_le_div_right hDr0).mpr
      (div_le_div (pow_nonneg hx2nn _) hpow (mul_pos hF1 hF1)
        (mul_le_mul_of_nonneg_left hfacN hF1.le))

theorem besselIn_beta0_lo_eq (m : ℕ) :
    (besselIn_beta0_interval m).lo = besselIn_partial m (β₀_rat / 3) 40 := by
  have hab : besselIn_partial m (β₀_rat / 3) 40
      ≤ besselIn_partial m (β₀_rat / 3) 40 + besselIn_error m (β₀_rat / 3) 40 := by
    have := besselIn_error_beta0_nonneg m; linarith
  simp only [besselIn_beta0_interval, besselIn_interval, ofRat]
  exact min_eq_left hab

theorem besselIn_beta0_hi_eq (m : ℕ) :
    (besselIn_beta0_interval m).hi
      = besselIn_partial m (β₀_rat / 3) 40 + besselIn_error m (β₀_rat / 3) 40 := by
  have hab : besselIn_partial m (β₀_rat / 3) 40
      ≤ besselIn_partial m (β₀_rat / 3) 40 + besselIn_error m (β₀_rat / 3) 40 := by
    have := besselIn_error_beta0_nonneg m; linarith
  simp only [besselIn_beta0_interval, besselIn_interval, ofRat]
  exact max_eq_right hab

theorem besselIn_beta0_lo_nonneg (m : ℕ) : 0 ≤ (besselIn_beta0_interval m).lo := by
  rw [besselIn_beta0_lo_eq]
  unfold besselIn_partial
  apply Finset.sum_nonneg
  intro k _
  exact div_nonneg (pow_nonneg (by norm_num [β₀_rat]) _) (by positivity)

theorem besselIn_partial_le (m : ℕ) : besselIn_partial m (β₀_rat / 3) 40 ≤ 41 := by
  have h : besselIn_partial m (β₀_rat / 3) 40
      ≤ ∑ _k ∈ Finset.range (40 + 1), (1 : ℚ) := by
    unfold besselIn_partial
    apply Finset.sum_le_sum
    intro k _
    rw [div_le_one (by positivity)]
    refine le_trans (pow_le_one _ (by norm_num [β₀_rat]) (by norm_num [β₀_rat])) ?_
    have h2 : (1 : ℚ) ≤ ((m + k).factorial : ℚ) := by exact_mod_cast Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero (m + k))
    have h1 : (1 : ℚ) ≤ (k.factorial : ℚ) := by exact_mod_cast Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero k)
    calc (1 : ℚ) ≤ (k.factorial : ℚ) := h1
      _ ≤ (k.factorial : ℚ) * ((m + k).factorial : ℚ) := le_mul_of_one_le_right (by positivity) h2
  refine le_trans h ?_
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; norm_num

theorem besselIn_beta0_hi_le (m : ℕ) : (besselIn_beta0_interval m).hi ≤ 42 := by
  rw [besselIn_beta0_hi_eq]
  have hp : besselIn_partial m (β₀_rat / 3) 40 ≤ 41 := besselIn_partial_le m
  have he : besselIn_error m (β₀_rat / 3) 40 ≤ 1 :=
    le_trans (besselIn_error_le_I0 m) (by norm_num [besselI0_error, β₀_rat, Nat.factorial])
  linarith

theorem besselIn_beta0_width_le (m : ℕ) : (besselIn_beta0_interval m).width ≤ 1 / 10 ^ 14 := by
  simp only [RatInterval.width]
  rw [besselIn_beta0_hi_eq, besselIn_beta0_lo_eq]
  have heq : besselIn_partial m (β₀_rat / 3) 40 + besselIn_error m (β₀_rat / 3) 40
      - besselIn_partial m (β₀_rat / 3) 40 = besselIn_error m (β₀_rat / 3) 40 := by ring
  rw [heq]
  exact le_trans (besselIn_error_le_I0 m) (by norm_num [besselI0_error, β₀_rat, Nat.factorial])

/-! ### §3  Interval determinant (3×3, `det_fin_three` shape). -/

def detI (e : Fin 3 → Fin 3 → RatInterval) : RatInterval :=
  ((((((e 0 0).mul (e 1 1)).mul (e 2 2)).sub
      (((e 0 0).mul (e 1 2)).mul (e 2 1))).sub
      (((e 0 1).mul (e 1 0)).mul (e 2 2))).add
      (((e 0 1).mul (e 1 2)).mul (e 2 0))).add
      (((e 0 2).mul (e 1 0)).mul (e 2 1)) |>.sub
      (((e 0 2).mul (e 1 1)).mul (e 2 0))

theorem detI_contains {e : Fin 3 → Fin 3 → RatInterval} {M : Matrix (Fin 3) (Fin 3) ℝ}
    (hc : ∀ i j, (e i j).contains (M i j)) : (detI e).contains M.det := by
  rw [Matrix.det_fin_three]
  exact sub_contains (add_contains (add_contains (sub_contains (sub_contains
    (mul_contains (mul_contains (hc 0 0) (hc 1 1)) (hc 2 2))
    (mul_contains (mul_contains (hc 0 0) (hc 1 2)) (hc 2 1)))
    (mul_contains (mul_contains (hc 0 1) (hc 1 0)) (hc 2 2)))
    (mul_contains (mul_contains (hc 0 1) (hc 1 2)) (hc 2 0)))
    (mul_contains (mul_contains (hc 0 2) (hc 1 0)) (hc 2 1)))
    (mul_contains (mul_contains (hc 0 2) (hc 1 1)) (hc 2 0))

theorem detI_width_le {e : Fin 3 → Fin 3 → RatInterval} (U E : ℚ)
    (hU : 0 ≤ U) (hE : 0 ≤ E)
    (h0 : ∀ i j, 0 ≤ (e i j).lo)
    (hhi : ∀ i j, (e i j).hi ≤ U)
    (hw : ∀ i j, (e i j).width ≤ E) :
    (detI e).width ≤ 18 * U ^ 2 * E := by
  simp only [detI, sub_width, add_width]
  have b1 := triple_width_le U E (h0 0 0) (hhi 0 0) (hw 0 0) (h0 1 1) (hhi 1 1) (hw 1 1)
    (h0 2 2) (hhi 2 2) (hw 2 2) hU hE
  have b2 := triple_width_le U E (h0 0 0) (hhi 0 0) (hw 0 0) (h0 1 2) (hhi 1 2) (hw 1 2)
    (h0 2 1) (hhi 2 1) (hw 2 1) hU hE
  have b3 := triple_width_le U E (h0 0 1) (hhi 0 1) (hw 0 1) (h0 1 0) (hhi 1 0) (hw 1 0)
    (h0 2 2) (hhi 2 2) (hw 2 2) hU hE
  have b4 := triple_width_le U E (h0 0 1) (hhi 0 1) (hw 0 1) (h0 1 2) (hhi 1 2) (hw 1 2)
    (h0 2 0) (hhi 2 0) (hw 2 0) hU hE
  have b5 := triple_width_le U E (h0 0 2) (hhi 0 2) (hw 0 2) (h0 1 0) (hhi 1 0) (hw 1 0)
    (h0 2 1) (hhi 2 1) (hw 2 1) hU hE
  have b6 := triple_width_le U E (h0 0 2) (hhi 0 2) (hw 0 2) (h0 1 1) (hhi 1 1) (hw 1 1)
    (h0 2 0) (hhi 2 0) (hw 2 0) hU hE
  linarith [b1, b2, b3, b4, b5, b6]

/-! ### §4  Real Toeplitz–Bessel matrix and its certified determinant enclosure. -/

noncomputable def toeplitzReal (β : ℝ) (k : ℤ) : Matrix (Fin 3) (Fin 3) ℝ :=
  Matrix.of fun i j => besselI_series (((i : ℤ) - (j : ℤ) - k).natAbs) (β / 3)

def toeplitzDetInterval (k : ℤ) : RatInterval :=
  detI (fun i j => besselIn_beta0_interval (((i : ℤ) - (j : ℤ) - k).natAbs))

theorem toeplitz_det_contains (k : ℤ) :
    (toeplitzDetInterval k).contains ((toeplitzReal (β₀_rat : ℝ) k).det) := by
  unfold toeplitzDetInterval
  apply detI_contains
  intro i j
  simp only [toeplitzReal, Matrix.of_apply]
  have hbridge : (β₀_rat : ℝ) / 3 = ((β₀_rat / 3 : ℚ) : ℝ) := by push_cast; ring
  rw [hbridge]
  exact besselIn_beta0_contains _

theorem toeplitz_det_width_le (k : ℤ) :
    (toeplitzDetInterval k).width ≤ 18 * 42 ^ 2 * (1 / 10 ^ 14) := by
  apply detI_width_le 42 (1 / 10 ^ 14) (by norm_num) (by norm_num)
  · intro i j; exact besselIn_beta0_lo_nonneg _
  · intro i j; exact besselIn_beta0_hi_le _
  · intro i j; exact besselIn_beta0_width_le _

theorem toeplitz_det_width_lt (k : ℤ) :
    (toeplitzDetInterval k).width < 2 / 10 ^ 9 :=
  lt_of_le_of_lt (toeplitz_det_width_le k) (by norm_num)

theorem toeplitz_det_total_width_lt :
    ∑ i ∈ Finset.range 51, (toeplitzDetInterval ((i : ℤ) - 25)).width < 102 / 10 ^ 9 := by
  calc ∑ i ∈ Finset.range 51, (toeplitzDetInterval ((i : ℤ) - 25)).width
      ≤ ∑ _i ∈ Finset.range 51, (18 * 42 ^ 2 * (1 / 10 ^ 14) : ℚ) :=
        Finset.sum_le_sum (fun i _ => toeplitz_det_width_le _)
    _ < 102 / 10 ^ 9 := by
        rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]; norm_num


-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms toeplitz_det_contains        -- classical trio
-- #print axioms toeplitz_det_width_lt         -- classical trio
-- #print axioms toeplitz_det_total_width_lt   -- classical trio
--
-- Illustrative compiled checks (`#eval` uses the compiler, NOT the kernel; they
-- are informative only and contribute NO axioms to the theorems above):
-- every per-shift width is below 2·10⁻⁹, and the 51-shift total below 1.02·10⁻⁷.
#eval (List.range 51).all (fun i => decide ((toeplitzDetInterval ((i : ℤ) - 25)).width < 2 / 10 ^ 9))
#eval decide ((List.range 51).foldl
    (fun a i => a + (toeplitzDetInterval ((i : ℤ) - 25)).width) (0 : ℚ) < 102 / 10 ^ 9)

end TheoremaAureum.Towers.YM.IntervalArith
