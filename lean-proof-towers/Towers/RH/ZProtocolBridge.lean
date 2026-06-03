/-
  # ZProtocol.Towers.RH — Z-Protocol re-skin of the RH growth contradiction

  **This file does NOT prove the Riemann Hypothesis, and the "Z Protocol"
  constants discharge NOTHING.** It is a re-skin of
  `Towers/RH/GrowthContradiction.lean`: the genuine RH (mathlib's
  `_root_.RiemannHypothesis`) is again derived from two named OPEN hypotheses
  that are NEVER discharged. Wrapping the growth coefficient in a finite set of
  Bessel-derived numbers `{C_stable, C_Z1, C_Z2}` changes none of that.

  ## What the Z-constants do NOT do

  `C_Z1 = 6.506`, `C_Z2 = 8.087`, `C_stable = 1.0` are just real numbers. Putting
  them into `GrowthBound_Z` as the candidate constant does **not** make the bound
  true: `GrowthBound_Z` asserts `|ζ(½+it)| ≤ C (log t)²` for *some* `C` in that
  set, and this is **false** — classical Ω-results (Titchmarsh §8, Montgomery)
  show `|ζ(½+it)|` exceeds *any* fixed multiple of `(log t)²` infinitely often, so
  no constant works, Bessel-derived or otherwise. `GrowthBound_Z` therefore
  remains an UNPROVEN, in-fact-false hypothesis exactly like the original
  `GrowthBound`; no provider of it can ever exist, so the combinator below can
  never actually yield a proof of RH.

  ## Honesty notes on the original request

  * The requested theorem name `Z_BSD_Bridge` is a misnomer twice over: this is
    the **Riemann Hypothesis**, not Birch–Swinnerton-Dyer (a different Clay
    problem), and it is a re-statement of an OPEN reduction, not a "bridge" to a
    result. It is renamed honestly below.
  * The submitted snippet did not type-check: `I * t` needs `t` cast to `ℂ`
    (and `t ≥ 2` cannot live on `ℂ`, which has no order), so `t : ℝ` is cast in
    the `riemannZeta` argument. The `sorry` is genuinely filled — no `sorry` /
    `sorryAx` remains (classical-trio axioms only), per the project invariant.

  The only substantive math is the pure-calculus comparison
  `exp_loglog_dominates_sq` (a verbatim copy of the lemma in
  `GrowthContradiction.lean`, inlined so this file compiles standalone against
  mathlib only): `exp(c₁ log t / log log t)` eventually dominates `C (log t)²`.
  It carries no RH content. Both hypotheses stay OPEN. Proves NOTHING new about
  RH; makes NO "RH proved / Lindelöf proved / Z Protocol proves RH" claim.
-/

import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

namespace ZProtocol
namespace Towers
namespace RH

open Filter

/-! ## Z-Protocol constants (arbitrary reals w.r.t. RH; discharge nothing) -/

/-- From `I_0(5)`, `I_1(5)` (Z-Protocol "stable" coefficient). Just a real
    number; gives `GrowthBound_Z` no truth value of its own. -/
def C_stable : ℝ := 1.0

/-- From `BESSEL_COLD_T0_raw.json`. Arbitrary w.r.t. RH. -/
def C_Z1 : ℝ := 6.506

/-- From `Z_BESSEL_TSWEEP.csv`. Arbitrary w.r.t. RH. -/
def C_Z2 : ℝ := 8.087

/-- **OPEN (and in fact false).** `∃ C ∈ {C_stable, C_Z1, C_Z2}, ∀ t ≥ 2,
    |ζ(½+it)| ≤ C (log t)²`. Stronger than Lindelöf, unproven, and false by
    classical Ω-results regardless of which Bessel constant is chosen. Never
    discharged. -/
def GrowthBound_Z : Prop :=
  ∃ C ∈ ({C_stable, C_Z1, C_Z2} : Set ℝ), ∀ t : ℝ, 2 ≤ t →
    ‖riemannZeta (1 / 2 + Complex.I * (t : ℂ))‖ ≤ C * (Real.log t) ^ 2

/-- **OPEN, conditional.** *If* there is a nontrivial off-line zero, *then*
    `|ζ(½+it)| ≥ exp(c₁ log t / log log t)` for arbitrarily large `t`. Asserted
    as "standard" but not proved; never discharged. Kept conditional so the
    combinator stays non-vacuous (cf. `GrowthContradiction.lean`). -/
def ZeroRepulsion_Z : Prop :=
  (∃ ρ : ℂ, riemannZeta ρ = 0 ∧ ρ ≠ 1 ∧ ρ.re ≠ 1 / 2) →
    ∃ c₁ : ℝ, 0 < c₁ ∧ ∀ B : ℝ, ∃ t : ℝ, B ≤ t ∧
      Real.exp (c₁ * Real.log t / Real.log (Real.log t))
        ≤ ‖riemannZeta (1 / 2 + Complex.I * (t : ℂ))‖

/-- **Pure-calculus comparison (no RH content).** Verbatim copy of the lemma in
    `Towers/RH/GrowthContradiction.lean`, inlined for standalone compilation.
    For fixed `C, c₁ > 0`, `C (log t)² < exp(c₁ log t / log log t)` eventually. -/
theorem exp_loglog_dominates_sq (C c₁ : ℝ) (hC : 0 < C) (hc₁ : 0 < c₁) :
    ∀ᶠ t in atTop,
      C * (Real.log t) ^ 2 < Real.exp (c₁ * Real.log t / Real.log (Real.log t)) := by
  have hexp2 : Tendsto (fun v : ℝ => Real.exp v / v ^ 2) atTop atTop :=
    Real.tendsto_exp_div_pow_atTop 2
  have hsub : Tendsto (fun v : ℝ => c₁ * (Real.exp v / v ^ 2) + (-2)) atTop atTop :=
    tendsto_atTop_add_const_right atTop (-2 : ℝ) (hexp2.const_mul_atTop hc₁)
  have hmul : Tendsto (fun v : ℝ => v * (c₁ * (Real.exp v / v ^ 2) + (-2))) atTop atTop :=
    tendsto_id.atTop_mul_atTop hsub
  have hcore : Tendsto (fun v : ℝ => c₁ * Real.exp v / v - 2 * v) atTop atTop := by
    refine hmul.congr' ?_
    filter_upwards [eventually_gt_atTop (0 : ℝ)] with v hv
    have hv' : v ≠ 0 := ne_of_gt hv
    field_simp
    ring
  have hv_ineq : ∀ᶠ v in atTop, Real.log C + 2 * v < c₁ * Real.exp v / v := by
    filter_upwards [hcore.eventually_gt_atTop (Real.log C)] with v hv
    linarith
  have hloglog : Tendsto (fun t : ℝ => Real.log (Real.log t)) atTop atTop :=
    Real.tendsto_log_atTop.comp Real.tendsto_log_atTop
  have ht_ineq := hloglog.eventually hv_ineq
  filter_upwards [ht_ineq, Real.tendsto_log_atTop.eventually_gt_atTop (0 : ℝ)]
    with t htin htpos
  rw [Real.exp_log htpos] at htin
  have hCsq : C * (Real.log t) ^ 2
      = Real.exp (Real.log C + 2 * Real.log (Real.log t)) := by
    rw [Real.exp_add, Real.exp_log hC, two_mul, Real.exp_add, Real.exp_log htpos, ← pow_two]
  rw [hCsq, Real.exp_lt_exp]
  exact htin

/-- **Combinator (honest conditional reduction; the requested `Z_BSD_Bridge`,
    renamed).** `GrowthBound_Z → ZeroRepulsion_Z → RiemannHypothesis`.

    A genuine Lean proof (classical trio, no `sorry`) — but it proves NOTHING
    new: both inputs are OPEN and undischarged, and `GrowthBound_Z` is in fact
    false for every choice of the Z-constants (see the banner). The proof is the
    same asymptotic contradiction as in `GrowthContradiction.lean`; the Bessel
    constants only fix `0 < C`, which any positive constant would. -/
theorem riemannHypothesis_of_growthBoundZ_and_zeroRepulsionZ
    (hG : GrowthBound_Z) (hR : ZeroRepulsion_Z) : _root_.RiemannHypothesis := by
  intro s hs _htriv hs1
  by_contra hre
  obtain ⟨c₁, hc₁, hbig⟩ := hR ⟨s, hs, hs1, hre⟩
  obtain ⟨C, hCmem, hub⟩ := hG
  have hC : 0 < C := by
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hCmem
    rcases hCmem with h | h | h <;> rw [h] <;> norm_num [C_stable, C_Z1, C_Z2]
  obtain ⟨Ta, hTa⟩ := eventually_atTop.mp (exp_loglog_dominates_sq C c₁ hC hc₁)
  obtain ⟨t, hBt, hge⟩ := hbig (max 2 Ta)
  have h2 : (2 : ℝ) ≤ t := le_trans (le_max_left _ _) hBt
  have hTat : Ta ≤ t := le_trans (le_max_right _ _) hBt
  have hub' := hub t h2
  have hcmp := hTa t hTat
  exact absurd (lt_of_le_of_lt (le_trans hge hub') hcmp) (lt_irrefl _)

end RH
end Towers
end ZProtocol
