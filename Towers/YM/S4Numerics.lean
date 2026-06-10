/-
S4Numerics.lean — STANDALONE TRUE ARITHMETIC FACTS (transparency record).

================================ READ FIRST ================================
This file records, AS PLAIN ARITHMETIC AND NOTHING MORE, four numerical
statements requested in connection with the "Battle Plan v1.6 / Opera
Numerorum" certificate corpus:

  * `c_S4_lt`         :  C_S4 < 5/2          where
        C_S4 := ∑_{p ∈ {2,3,19,191}} log p / (p - 1)   (true; value ≈ 1.4337)
  * `kEff_le`         :  kEff ≤ 16/5 (= 3.2)  where  kEff := 10/π   (≈ 3.1831)
  * `zModes_eq`       :  zModes = 120 / 2^3   where  zModes := 15
  * `h4Order_factor`  :  h4OrderLiterature = 2^6 * 3^2 * 5^2   (= 14400)

WHAT THIS FILE DOES **NOT** DO — and what no line here may ever be read as doing:

  1. It does NOT construct the H4 Coxeter group, and does NOT prove that the
     order of that group is 14400.  `h4Order_factor` is a prime factorization
     of the *integer* 14400 (the literature value of |H4|), proved by
     `norm_num`.  It is group-theoretically EMPTY.  A faithful Lean
     construction of H4 with a machine-checked order is a separate, large
     formalization (Todd–Coxeter-scale) and is deliberately NOT attempted —
     `decide` cannot enumerate a 14400-element Coxeter group.  Naming a
     14400-element index set "H4" would be a mislabel and is refused.

  2. `C_S4` here uses the divisor `log p / (p - 1)` (value ≈ 1.4337).  The
     corpus's own modules M5 / M17 / M18 use a DIFFERENT quantity,
     `log p · p / (p - 1)` ≈ 11.4221, for which `C_S4 < 5/2` is FALSE.  These
     are two different numbers; do not conflate them.  An earlier "Orbit120"
     attempt instead required `C_S4 ∈ (2√13, 2√13 + 1) = (7.211, 8.211)` — the
     OPPOSITE direction.  A single quantity cannot satisfy both `< 2.5` and
     `> 7.211`.

  3. `kEff = 10/π` and `zModes = 15` are bare constants.  They carry NO
     physical or number-theoretic content.  NOTHING here connects them to a
     speed of light, a resonant cavity, a "cliff", a wormhole, a graviton
     mode count, RH, BSD, the Tate conjecture, or a Yang–Mills mass gap.

  4. NOTHING here discharges `Towers/Attempts/ClusterExpansion.lean`'s
     `kotecky_preiss_criterion` `sorry`.  The Kotecký–Preiss convergence bound
     for the SU(3) polymer expansion quantifies over a weight function
     `a : Polymer → ℝ` on ALL lattice polymers (an infinite family of
     inequalities).  A four-term sum over {2,3,19,191} is not, and cannot be
     substituted for, that bound.  There is no theorem `C_S4 < 5/2 → KP`.

INVARIANT-LOCKED:
  * Makes NO mass-gap / μ>0 / Surface-#1-CLOSED / RH / BSD / Tate claim.
    YM and NS towers stay `Status: Open`; Surface #1 stays OPEN.
  * No `sorry` / `admit`.  Intended axiom footprint: the classical trio
    {propext, Classical.choice, Quot.sound}.

VERIFICATION STATUS — **VERIFIED** (machine-checked, classical-trio clean):
  Compiled with the v4.12.0 toolchain (`lean Towers/YM/S4Numerics.lean`,
  EXIT=0) against the vendored mathlib oleans, and audited with
  `#print axioms`:
    * `c_S4_lt`, `kEff_le`            →  {propext, Classical.choice, Quot.sound}
    * `zModes_eq`, `h4Order_factor`   →  {propext} only
  No `sorryAx`, no user-declared axiom.  Registered in `lakefile.lean` roots
  and in the `BRICKS` array of `scripts/check-towers.sh`, where the per-brick
  axiom-footprint gate re-confirms the trio bound on every run.
-/
import Mathlib.Data.Complex.ExponentialBounds
import Mathlib.Data.Real.Pi.Bounds
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Algebra.BigOperators.Group.Finset

namespace TheoremaAureum.Towers.YM.S4Numerics

open Real

/-! ### Fact 1 — `C_S4 < 5/2` (a four-term arithmetic inequality, nothing more) -/

/-- The finite set `S₄ = {2, 3, 19, 191} ⊂ ℝ`. -/
noncomputable def S4 : Finset ℝ := {2, 3, 19, 191}

/-- `C_S4 := ∑_{p ∈ S₄} log p / (p - 1)` with the divisor `log p / (p - 1)`
    (value ≈ 1.4337).  This is NOT the corpus's `log p · p/(p-1)` ≈ 11.422. -/
noncomputable def C_S4 : ℝ := ∑ p ∈ S4, Real.log p / (p - 1)

/-- `C_S4 < 5/2`.  A bound on a four-term finite sum; it proves nothing about
    RH, BSD, the Kotecký–Preiss criterion, or the Yang–Mills mass gap. -/
theorem c_S4_lt : C_S4 < 5 / 2 := by
  have hlog2 : Real.log 2 < 0.6931471808 := Real.log_two_lt_d9
  have hlog2' : Real.log 2 < 7 / 10 := by
    have e : (0.6931471808 : ℝ) ≤ 7 / 10 := by norm_num
    linarith [hlog2, e]
  -- log 3 ≤ log 4 = 2·log 2
  have h3 : Real.log 3 ≤ 2 * Real.log 2 := by
    calc Real.log 3 ≤ Real.log 4 := Real.log_le_log (by norm_num) (by norm_num)
      _ = Real.log ((2 : ℝ) ^ 2) := by norm_num
      _ = 2 * Real.log 2 := by rw [Real.log_pow]; push_cast; ring
  -- log 19 ≤ log 32 = 5·log 2
  have h19 : Real.log 19 ≤ 5 * Real.log 2 := by
    calc Real.log 19 ≤ Real.log 32 := Real.log_le_log (by norm_num) (by norm_num)
      _ = Real.log ((2 : ℝ) ^ 5) := by norm_num
      _ = 5 * Real.log 2 := by rw [Real.log_pow]; push_cast; ring
  -- log 191 ≤ log 256 = 8·log 2
  have h191 : Real.log 191 ≤ 8 * Real.log 2 := by
    calc Real.log 191 ≤ Real.log 256 := Real.log_le_log (by norm_num) (by norm_num)
      _ = Real.log ((2 : ℝ) ^ 8) := by norm_num
      _ = 8 * Real.log 2 := by rw [Real.log_pow]; push_cast; ring
  -- expand the four-term sum
  have hexpand : C_S4 = Real.log 2 + Real.log 3 / 2
      + Real.log 19 / 18 + Real.log 191 / 190 := by
    simp only [C_S4, S4]
    rw [Finset.sum_insert (by norm_num), Finset.sum_insert (by norm_num),
        Finset.sum_insert (by norm_num), Finset.sum_singleton]
    ring
  rw [hexpand]
  -- per-term bounds in units of log 2
  have t2 : Real.log 3 / 2 ≤ Real.log 2 := by
    rw [div_le_iff (by norm_num : (0:ℝ) < 2)]; linarith [h3]
  have t3 : Real.log 19 / 18 ≤ 5 * Real.log 2 / 18 :=
    (div_le_div_right (by norm_num : (0:ℝ) < 18)).mpr h19
  have t4 : Real.log 191 / 190 ≤ 8 * Real.log 2 / 190 :=
    (div_le_div_right (by norm_num : (0:ℝ) < 190)).mpr h191
  linarith [hlog2', t2, t3, t4]

/-! ### Fact 2 — `kEff ≤ 3.2` (a bound on `10/π`, no meaning attached) -/

/-- `kEff := 10/π` (≈ 3.1831).  A bare real constant; no physical or
    geometric meaning is attached to it here. -/
noncomputable def kEff : ℝ := 10 / Real.pi

/-- `kEff ≤ 16/5` (= 3.2), i.e. `10/π ≤ 3.2`, because `π > 3.125`. -/
theorem kEff_le : kEff ≤ 16 / 5 := by
  have hpi : (25 : ℝ) / 8 < Real.pi := by
    have e : (25 : ℝ) / 8 ≤ 3.141592 := by norm_num
    linarith [Real.pi_gt_d6, e]
  rw [kEff, div_le_iff Real.pi_pos]
  linarith [hpi]

/-! ### Fact 3 — `zModes = 15 = 120/2³` (integer arithmetic, no meaning attached) -/

/-- `zModes := 15`.  A bare natural-number constant. -/
def zModes : ℕ := 15

/-- `zModes = 120 / 2^3` as natural-number arithmetic (`120/8 = 15`). -/
theorem zModes_eq : zModes = 120 / 2 ^ 3 := by norm_num [zModes]

/-! ### Fact 4 — factorization of the integer 14400 (NOT a group order) -/

/-- The integer 14400, recorded as the literature value of `|H4|`.  This is a
    plain natural number; the H4 Coxeter group is NOT constructed here. -/
def h4OrderLiterature : ℕ := 14400

/-- `14400 = 2^6 · 3^2 · 5^2` — a prime factorization of the integer 14400.
    This is group-theoretically EMPTY: it does NOT prove `|H4| = 14400`. -/
theorem h4Order_factor : h4OrderLiterature = 2 ^ 6 * 3 ^ 2 * 5 ^ 2 := by
  norm_num [h4OrderLiterature]

end TheoremaAureum.Towers.YM.S4Numerics
