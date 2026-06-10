-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (classical trio only).
-- Scope: PHASE-2 INFRASTRUCTURE ONLY — a rigorous rational interval-arithmetic
--   CORE (structure + sound ℝ-membership + add/neg/sub/mul + strict-upper-bound
--   transfer). This is the foundation an `Interval.exp` / `Interval.besselI`
--   evaluator would build on; those transcendental enclosures and the final
--   `w1_weyl β₀ < 1/7` bound are NOT here (each is a large separate phase). This
--   file proves NOTHING about `w1_weyl`, the opaque `besselI`/`w1`, or the open
--   axioms of `Hw1_Surface.lean`; it makes NO mass-gap / Surface-#1 / `μ>0`
--   claim. NOT a brick / lakefile root.
/-
Interval — Phase 2 core. A `RatInterval` is a pair of rational endpoints
`lo ≤ hi`; its `contains` predicate says a REAL number lies between the
(cast) endpoints. The arithmetic operations are proven SOUND: if `x ∈ I` and
`y ∈ J` then `x + y ∈ I.add J`, `-x ∈ I.neg`, `x - y ∈ I.sub J`,
`x * y ∈ I.mul J`. Endpoints are ℚ (kernel arithmetic is GMP-backed), so later
phases evaluate enclosures WITHOUT `norm_num` on ℝ. (Named `RatInterval` to
avoid the clash with mathlib's order-theoretic `Interval`.)

HONEST STATUS: this is the arithmetic kernel only. It does not by itself bound
any Bessel value or `Real.exp`, and discharges no axiom.
-/

import Mathlib

namespace TheoremaAureum.Towers.YM.IntervalArith

/-- A rational interval `[lo, hi]` with `lo ≤ hi`. -/
structure RatInterval where
  lo : ℚ
  hi : ℚ
  isLE : lo ≤ hi

namespace RatInterval

/-- A real number is contained in `[lo, hi]` iff it lies between the cast
endpoints. -/
def contains (I : RatInterval) (x : ℝ) : Prop :=
  (I.lo : ℝ) ≤ x ∧ x ≤ (I.hi : ℝ)

/-- The point interval `[q, q]`. -/
def ofRat (q : ℚ) : RatInterval := ⟨q, q, le_refl q⟩

theorem ofRat_contains (q : ℚ) : (ofRat q).contains (q : ℝ) :=
  ⟨le_refl _, le_refl _⟩

/-- Strict-upper-bound transfer: the comparison the final `< 1/7` step needs. -/
theorem lt_of_contains {I : RatInterval} {x c : ℝ} (h : I.contains x)
    (hc : (I.hi : ℝ) < c) : x < c :=
  lt_of_le_of_lt h.2 hc

/-- Lower-bound transfer. -/
theorem lt_of_contains' {I : RatInterval} {x c : ℝ} (h : I.contains x)
    (hc : c < (I.lo : ℝ)) : c < x :=
  lt_of_lt_of_le hc h.1

/-- Addition. -/
def add (I J : RatInterval) : RatInterval :=
  ⟨I.lo + J.lo, I.hi + J.hi, add_le_add I.isLE J.isLE⟩

theorem add_contains {I J : RatInterval} {x y : ℝ}
    (hx : I.contains x) (hy : J.contains y) : (I.add J).contains (x + y) := by
  refine ⟨?_, ?_⟩
  · show ((I.lo + J.lo : ℚ) : ℝ) ≤ x + y
    rw [Rat.cast_add]; exact add_le_add hx.1 hy.1
  · show x + y ≤ ((I.hi + J.hi : ℚ) : ℝ)
    rw [Rat.cast_add]; exact add_le_add hx.2 hy.2

/-- Negation. -/
def neg (I : RatInterval) : RatInterval :=
  ⟨-I.hi, -I.lo, neg_le_neg I.isLE⟩

theorem neg_contains {I : RatInterval} {x : ℝ}
    (hx : I.contains x) : (I.neg).contains (-x) := by
  refine ⟨?_, ?_⟩
  · show ((-I.hi : ℚ) : ℝ) ≤ -x
    rw [Rat.cast_neg]; exact neg_le_neg hx.2
  · show -x ≤ ((-I.lo : ℚ) : ℝ)
    rw [Rat.cast_neg]; exact neg_le_neg hx.1

/-- Subtraction. -/
def sub (I J : RatInterval) : RatInterval := I.add J.neg

theorem sub_contains {I J : RatInterval} {x y : ℝ}
    (hx : I.contains x) (hy : J.contains y) : (I.sub J).contains (x - y) := by
  rw [sub_eq_add_neg]
  exact add_contains hx (neg_contains hy)

/-- Real bilinear lower bound: over the rectangle `[a,b]×[c,d]`, the product is
`≥` the least of the four corner products. -/
private theorem real_mul_lb {a b c d x y : ℝ}
    (hax : a ≤ x) (hxb : x ≤ b) (hcy : c ≤ y) (hyd : y ≤ d) :
    min (min (a * c) (a * d)) (min (b * c) (b * d)) ≤ x * y := by
  have h1 : min (a * y) (b * y) ≤ x * y := by
    rcases le_total 0 y with hy | hy
    · exact le_trans (min_le_left _ _) (mul_le_mul_of_nonneg_right hax hy)
    · exact le_trans (min_le_right _ _) (mul_le_mul_of_nonpos_right hxb hy)
  have h2 : min (a * c) (a * d) ≤ a * y := by
    rcases le_total 0 a with ha | ha
    · exact le_trans (min_le_left _ _) (mul_le_mul_of_nonneg_left hcy ha)
    · exact le_trans (min_le_right _ _) (mul_le_mul_of_nonpos_left hyd ha)
  have h3 : min (b * c) (b * d) ≤ b * y := by
    rcases le_total 0 b with hb | hb
    · exact le_trans (min_le_left _ _) (mul_le_mul_of_nonneg_left hcy hb)
    · exact le_trans (min_le_right _ _) (mul_le_mul_of_nonpos_left hyd hb)
  refine le_trans (le_min ?_ ?_) h1
  · exact le_trans (min_le_left _ _) h2
  · exact le_trans (min_le_right _ _) h3

/-- Real bilinear upper bound: the product is `≤` the greatest corner product. -/
private theorem real_mul_ub {a b c d x y : ℝ}
    (hax : a ≤ x) (hxb : x ≤ b) (hcy : c ≤ y) (hyd : y ≤ d) :
    x * y ≤ max (max (a * c) (a * d)) (max (b * c) (b * d)) := by
  have h1 : x * y ≤ max (a * y) (b * y) := by
    rcases le_total 0 y with hy | hy
    · exact le_trans (mul_le_mul_of_nonneg_right hxb hy) (le_max_right _ _)
    · exact le_trans (mul_le_mul_of_nonpos_right hax hy) (le_max_left _ _)
  have h2 : a * y ≤ max (a * c) (a * d) := by
    rcases le_total 0 a with ha | ha
    · exact le_trans (mul_le_mul_of_nonneg_left hyd ha) (le_max_right _ _)
    · exact le_trans (mul_le_mul_of_nonpos_left hcy ha) (le_max_left _ _)
  have h3 : b * y ≤ max (b * c) (b * d) := by
    rcases le_total 0 b with hb | hb
    · exact le_trans (mul_le_mul_of_nonneg_left hyd hb) (le_max_right _ _)
    · exact le_trans (mul_le_mul_of_nonpos_left hcy hb) (le_max_left _ _)
  refine le_trans h1 (max_le ?_ ?_)
  · exact le_trans h2 (le_max_left _ _)
  · exact le_trans h3 (le_max_right _ _)

/-- ℚ→ℝ cast commutes with `min` (v4.12.0 has no `Rat.cast_min`). -/
private theorem cast_min (p q : ℚ) : ((min p q : ℚ) : ℝ) = min (p : ℝ) (q : ℝ) := by
  rcases le_total p q with h | h
  · rw [min_eq_left h, min_eq_left (by exact_mod_cast h : (p : ℝ) ≤ q)]
  · rw [min_eq_right h, min_eq_right (by exact_mod_cast h : (q : ℝ) ≤ p)]

/-- ℚ→ℝ cast commutes with `max`. -/
private theorem cast_max (p q : ℚ) : ((max p q : ℚ) : ℝ) = max (p : ℝ) (q : ℝ) := by
  rcases le_total p q with h | h
  · rw [max_eq_right h, max_eq_right (by exact_mod_cast h : (p : ℝ) ≤ q)]
  · rw [max_eq_left h, max_eq_left (by exact_mod_cast h : (q : ℝ) ≤ p)]

/-- Multiplication: enclose by the min/max of the four rational corner products. -/
def mul (I J : RatInterval) : RatInterval :=
  ⟨min (min (I.lo * J.lo) (I.lo * J.hi)) (min (I.hi * J.lo) (I.hi * J.hi)),
   max (max (I.lo * J.lo) (I.lo * J.hi)) (max (I.hi * J.lo) (I.hi * J.hi)),
   le_trans (le_trans (min_le_left _ _) (min_le_left _ _))
     (le_trans (le_max_left _ _) (le_max_left _ _))⟩

theorem mul_contains {I J : RatInterval} {x y : ℝ}
    (hx : I.contains x) (hy : J.contains y) : (I.mul J).contains (x * y) := by
  obtain ⟨hax, hxb⟩ := hx
  obtain ⟨hcy, hyd⟩ := hy
  refine ⟨?_, ?_⟩
  · show ((min (min (I.lo * J.lo) (I.lo * J.hi)) (min (I.hi * J.lo) (I.hi * J.hi)) : ℚ) : ℝ)
        ≤ x * y
    rw [cast_min, cast_min, cast_min, Rat.cast_mul, Rat.cast_mul, Rat.cast_mul, Rat.cast_mul]
    exact real_mul_lb hax hxb hcy hyd
  · show x * y ≤
        ((max (max (I.lo * J.lo) (I.lo * J.hi)) (max (I.hi * J.lo) (I.hi * J.hi)) : ℚ) : ℝ)
    rw [cast_max, cast_max, cast_max, Rat.cast_mul, Rat.cast_mul, Rat.cast_mul, Rat.cast_mul]
    exact real_mul_ub hax hxb hcy hyd

end RatInterval

end TheoremaAureum.Towers.YM.IntervalArith

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.IntervalArith.RatInterval.mul_contains  -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.IntervalArith.RatInterval.add_contains  -- classical trio
