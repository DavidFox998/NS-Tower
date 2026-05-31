-- Axiom status: Uses [propext, Classical.choice, Quot.sound]
-- Scope: Honest Zoe Comparison Test for X₅. Series is ENTIRE (R=∞). Hodge stays Open.
/-
ZoeComparisonTest — an HONEST, machine-checked analysis of the "Zoe Comparison
Test" generating function
  𝔗(ω, s) = Σ_{n≥0}  Z(ω)ⁿ / (n!)²  ·  ⟨ω, Frobⁿ ω⟩  ·  q^{n·s}
for the genus-5 Jacobian X₅ = Jac(y² = x¹¹ − x).

This file proves NO instance of the Hodge conjecture, refutes NO instance, and
discharges NO open surface. HODGE_STATUS stays OPEN. What it DOES establish:

  (T1/T2) The combinatorics behind Paper 2's Hankel rank: C(5,2) = 10 (the
          recurrence-test order) and rank(H) = C(5,2) + C(5,4) = 15 > 10. The
          number 15 is the *Hankel rank*, an entirely different quantity from the
          Zoe invariant Z. The Zoe invariant of Paper 3 satisfies 1 ≤ Z ≤ p and,
          for X₅, p = 2, so Z ≤ 2 (NOT 15 — never conflate the two).

  (T3)    The series 𝔗(ω, s) is ENTIRE: for every s its term sequence is
          absolutely summable. This is the OPPOSITE of "radius 0 / pole at s = 1":
          the (n!)² denominator dominates ANY geometric Weil bound
          |⟨ω, Frobⁿ ω⟩| ≤ C·Bⁿ, so the test supplies NO divergence and hence NO
          obstruction. This is itself a machine-checked finding, refuting the
          earlier "radius 0" claim. We do NOT manufacture divergence.

  (T4)    Because the series converges, any "divergence ⇒ transcendence" bridge is
          VACUOUS for this object. We record it honestly as a CONDITIONAL
          combinator over a single named-open Prop (`hDivToTrans`), SORRY-free,
          exactly the Wall256/Wall300 pattern. It proves transcendence of NO
          actual class: the antecedent (`Diverges ω`) is never met for 𝔗.

  (extra) A small arithmetic REFUTATION of Lemma 7.6's Step-3 dimension count
          (`step3_degenerate`): the literal bound `Z(ω) ≤ C(dim NS, p)` gives
          `C(1,2) = 0` for X₅, which is degenerate — Step 3 conflates the
          wedge-of-Néron–Severi dimension with the tensor rank.

Honest scope (locked invariants)
--------------------------------
* HODGE stays `Status: Open`. NO Hodge class is shown algebraic or transcendental;
  no Clay claim. `Cls`, `Transcendental`, `Diverges`, `pairing` are ABSTRACT —
  no actual (2,2)-class, Frobenius action, or NS lattice is constructed.
* The Weil bound `|⟨ω, Frobⁿ ω⟩| ≤ C·Bⁿ` is carried as a HYPOTHESIS (`hWeil`),
  not proved; it is the only analytic input, and it is GENEROUS — any geometric
  growth is killed by (n!)², so the conclusion (entire) is robust.
* NOT a brick / NOT in BRICKS / NOT a lakefile root; touches NO YM or NS surface.

Axiom footprint: classical trio `{propext, Classical.choice, Quot.sound}` only;
no `sorry`, no `axiom`.
-/

import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Data.Nat.Choose.Basic

namespace TheoremaAureum.Towers.Hodge.ZoeComparisonTest

open Real

/-! ## T1 / T2 — the combinatorics (Hankel rank ≠ Zoe invariant) -/

/-- The genus of `X₅ = Jac(y² = x¹¹ − x)`. -/
def gX5 : ℕ := 5

/-- `p = [E : F]` for the relevant CM model; for the X₅ family Paper 3 takes
`p = 2`. The Zoe invariant satisfies `1 ≤ Z ≤ p`, so for X₅ this caps `Z ≤ 2`. -/
def pX5 : ℕ := 2

/-- The recurrence-test order from Paper 2: `C(5,2) = 10`. -/
theorem choose_5_2 : Nat.choose 5 2 = 10 := by decide

/-- `C(5,4) = 5`, the excess piece. -/
theorem choose_5_4 : Nat.choose 5 4 = 5 := by decide

/-- The Hankel rank reported in Paper 2 for the 200 classes:
`rank(H) = C(5,2) + C(5,4) = 15`. (INPUT DATUM from Paper 2; this `15` is the
HANKEL RANK, NOT the Zoe invariant.) -/
def hankelRankX5 : ℕ := Nat.choose 5 2 + Nat.choose 5 4

/-- **T2 — `rank(H) = 15`** (Paper 2 citation). The Hankel rank reported for the
200 classes; an INPUT DATUM, and NOT the Zoe invariant. -/
theorem rank_H_X5 : hankelRankX5 = 15 := by decide

/-- The excess: the Hankel rank `15` strictly exceeds the recurrence-test order
`C(5,2) = 10`. This is exactly Paper 2's "Algorithm A₂ returns False" — a failure
of the *recurrence test*, NOT a Hodge-conjecture verdict. -/
theorem rank_gt_test : Nat.choose 5 2 < hankelRankX5 := by decide

/-- **Zoe bound transcription.** Paper 3's lemma `1 ≤ Z(A) ≤ p` together with
`p = 2` for X₅ caps the Zoe invariant at `Z ≤ 2`. The source bound `Z ≤ p` is
taken as the (proved-in-the-paper) input `hZle`; this lemma only threads it. In
particular `Z ≠ 15`: the `15` of Paper 2 is the Hankel rank, a different
quantity. -/
theorem Z_X5_bound {Z : ℕ} (hZle : Z ≤ pX5) : Z ≤ 2 := by
  simpa [pX5] using hZle

/-! ## T3 — the Zoe Comparison series is ENTIRE (R = ∞) -/

/-- The `n`-th term of the Zoe Comparison Test
`𝔗(ω, s) = Σ Z(ω)ⁿ/(n!)² · ⟨ω, Frobⁿ ω⟩ · q^{n·s}`, with the abstract Frobenius
pairing `pairing n := ⟨ω, Frobⁿ ω⟩` and `b := q^s` (so `q^{n·s} = bⁿ`). -/
noncomputable def zoeTerm (Z b : ℝ) (pairing : ℕ → ℝ) (n : ℕ) : ℝ :=
  Z ^ n / (n.factorial : ℝ) ^ 2 * pairing n * b ^ n

/-- The `(n!)²`-weighted geometric series converges for EVERY real ratio `r ≥ 0`.
This is the analytic heart: `(n!)²` dominates `n!`, and `Σ rⁿ/n!` already
converges (`Real.summable_pow_div_factorial`), so a fortiori does `Σ rⁿ/(n!)²`. -/
theorem summable_pow_div_factorial_sq (r : ℝ) (hr : 0 ≤ r) :
    Summable (fun n => r ^ n / (n.factorial : ℝ) ^ 2) := by
  refine Summable.of_nonneg_of_le
    (fun n => div_nonneg (pow_nonneg hr n) (sq_nonneg _)) (fun n => ?_)
    (Real.summable_pow_div_factorial r)
  have h1 : (1 : ℝ) ≤ (n.factorial : ℝ) := by exact_mod_cast n.factorial_pos
  have hpos : (0 : ℝ) < (n.factorial : ℝ) := by exact_mod_cast n.factorial_pos
  have hrn : (0 : ℝ) ≤ r ^ n := pow_nonneg hr n
  rw [pow_two, ← div_div]
  exact div_le_self (div_nonneg hrn hpos.le) h1

/-- **T3 (machine-checked): the Zoe Comparison series `𝔗(ω, s)` is ENTIRE.**
For every Zoe ratio `Z ≥ 0` and every `b = q^s ≥ 0`, and for ANY Frobenius
pairing obeying the geometric Weil bound `|⟨ω, Frobⁿ ω⟩| ≤ C·Bⁿ`, the term
sequence of `𝔗` is absolutely summable. The radius of convergence is therefore
infinite — the `(n!)²` denominator overwhelms any geometric Weil growth.

This REFUTES the earlier "radius 0 / pole at `s = 1`" claim: the test, as
defined, supplies NO divergence and hence NO obstruction. No Hodge verdict is
produced; `pairing` is abstract. -/
theorem summable_abs_zoeTerm
    (Z b C Bnd : ℝ) (pairing : ℕ → ℝ)
    (hZ : 0 ≤ Z) (hb : 0 ≤ b) (hBnd : 0 ≤ Bnd)
    (hWeil : ∀ n, |pairing n| ≤ C * Bnd ^ n) :
    Summable (fun n => |zoeTerm Z b pairing n|) := by
  have hr : 0 ≤ Z * Bnd * b := mul_nonneg (mul_nonneg hZ hBnd) hb
  have hsum : Summable (fun n => C * ((Z * Bnd * b) ^ n / (n.factorial : ℝ) ^ 2)) :=
    (summable_pow_div_factorial_sq (Z * Bnd * b) hr).mul_left C
  refine Summable.of_nonneg_of_le (fun n => abs_nonneg _) (fun n => ?_) hsum
  have hpx : 0 ≤ Z ^ n / (n.factorial : ℝ) ^ 2 :=
    div_nonneg (pow_nonneg hZ n) (sq_nonneg _)
  have hbx : 0 ≤ b ^ n := pow_nonneg hb n
  calc |zoeTerm Z b pairing n|
      = Z ^ n / (n.factorial : ℝ) ^ 2 * |pairing n| * b ^ n := by
        unfold zoeTerm
        rw [abs_mul, abs_mul, abs_of_nonneg hpx, abs_of_nonneg hbx]
    _ ≤ Z ^ n / (n.factorial : ℝ) ^ 2 * (C * Bnd ^ n) * b ^ n := by
        apply mul_le_mul_of_nonneg_right _ hbx
        exact mul_le_mul_of_nonneg_left (hWeil n) hpx
    _ = C * ((Z * Bnd * b) ^ n / (n.factorial : ℝ) ^ 2) := by
        rw [mul_pow, mul_pow]; ring

/-- **T3 headline — the radius of convergence of `𝔗(ω, s)` is INFINITE.**
For a fixed Zoe ratio `Z ≥ 0` and any Frobenius pairing obeying the geometric
Weil bound `|⟨ω, Frobⁿ ω⟩| ≤ C·Bⁿ`, the term sequence of `𝔗` is absolutely
summable **for every** `b = q^s ≥ 0` — i.e. for every value of `s`. Summability
at every point of the variable is exactly what "radius of convergence `= ∞`"
(the series is ENTIRE) means here; it is the direct corollary of
`summable_abs_zoeTerm`. This is NOT a `FormalMultilinearSeries.radius = ⊤`
computation — it is the pointwise-everywhere summability statement, which is the
honest content. Refutes "radius 0 / pole at `s = 1`"; `pairing` abstract; no
Hodge verdict. -/
theorem radius_infinite
    (Z C Bnd : ℝ) (pairing : ℕ → ℝ)
    (hZ : 0 ≤ Z) (hBnd : 0 ≤ Bnd)
    (hWeil : ∀ n, |pairing n| ≤ C * Bnd ^ n) :
    ∀ b : ℝ, 0 ≤ b → Summable (fun n => |zoeTerm Z b pairing n|) :=
  fun b hb => summable_abs_zoeTerm Z b C Bnd pairing hZ hb hBnd hWeil

/-! ## T4 — the (vacuous) conditional obstruction combinator -/

section Obstruction
variable {Cls : Type*} (Diverges Transcendental : Cls → Prop) (ω : Cls)

/-- **The single named-open analytic input.** `AnalyticObstruction` is the
"divergence ⇒ transcendence" bridge for a class `ω`, packaged as ONE `Prop`. It
is the only open hypothesis behind the conditional obstruction; it is **never
discharged** here. This is the Wall256/Wall300 named-open-Prop pattern. -/
def AnalyticObstruction : Prop := Diverges ω → Transcendental ω

/-- **T4 (HONEST CONDITIONAL, SORRY-free).** Threads `h_div : Diverges ω`
through the single named-open input `h : AnalyticObstruction Diverges
Transcendental ω` — nothing more.

CRUCIALLY this combinator is VACUOUS for the actual object: T3
(`radius_infinite` / `summable_abs_zoeTerm`) shows `𝔗(ω, s)` is entire, so
`Diverges ω` is never satisfied for the genuine series. Hence it proves
transcendence of NO actual class. `Cls`, `Transcendental`, `Diverges` are
ABSTRACT; `AnalyticObstruction` stays OPEN; HODGE stays Open. -/
theorem hodge_obstruction_conditional
    (h_div : Diverges ω)
    (h : AnalyticObstruction Diverges Transcendental ω) :
    Transcendental ω :=
  h h_div

end Obstruction

/-- **REFUTATION of Lemma 7.6, Step 3** (arithmetic witness). Step 3 bounds the
Zoe invariant of an algebraic class by `dim (∧^p NS(X)_ℚ) = C(dim NS, p)`. For
X₅, `dim NS(X₅)_ℚ = 1` and `p = 2`, so this count is `C(1, 2) = 0`. A bound
`Z(ω) ≤ 0` on every algebraic class is degenerate — it would forbid the
theta-power classes the very same paragraph then invokes. So `C(dim NS, p)` is
NOT the operative bound: Step 3 conflates the wedge-of-NS dimension with the
tensor rank. (This refutes the *step*, not the Hodge conjecture.) -/
theorem step3_degenerate : Nat.choose 1 pX5 = 0 := by decide

end TheoremaAureum.Towers.Hodge.ZoeComparisonTest
