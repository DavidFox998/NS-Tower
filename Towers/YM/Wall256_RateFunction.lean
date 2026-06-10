/-
================================================================
Towers / YM / Wall256_RateFunction

**The large-deviation RATE FUNCTION criterion — honest CONDITIONAL combinator.**

This is the sequel to `Wall255_JensenObstruction` (the mean-energy NO-GO) and
`Wall255_KP_Entropy` (beat the `7ⁿ` entropy iff per-polymer activity `q < 1/7`).

The program is **S4 → 7 → rate `I(x) > log 7`**:

* `S4`  — the strong-coupling numerics (`S4Numerics`) feed the lattice geometry.
* `7`   — the polymer connective constant `2d − 1 = 7` (`EntropyBound.polymer_const`)
          is the entropy multiplicity `#{size-n polymers} ≤ 7ⁿ`.
* rate  — a large-deviation rate `I` makes the per-polymer activity decay like
          `exp(−I·n)`. The entropy-weighted sum `∑ₙ 7ⁿ · exp(−I·n)` converges
          **iff** `7·exp(−I) < 1` **iff** `exp(−I) < 1/7` **iff** `log 7 < I`.

So the genuine smallness threshold `q < 1/7` of `Wall255_KP_Entropy` is exactly
the **rate condition `I > log 7`** under the dictionary `q = exp(−I)`. This file
makes that dictionary precise and routes the KP polymer sum through it.

WHAT IS GENUINE / UNCONDITIONAL (no hypotheses, classical trio):
* `exp_neg_lt_inv_seven_iff` — `exp(−I) < 1/7 ↔ log 7 < I` (the rate↔smallness
  dictionary), and `seven_exp_neg_lt_one_iff` — `7·exp(−I) < 1 ↔ log 7 < I`.
* `rate_beats_entropy` / `rate_tsum` — for `log 7 < I`, the entropy-weighted
  series `∑ₙ 7ⁿ·exp(−I)ⁿ` is `Summable` with total `(1 − 7·exp(−I))⁻¹`. The
  `7ⁿ` entropy factor is KEPT; this is the genuine "beat the entropy" step,
  re-expressed in rate-function language.
* `rateFn` / `le_rateFn` — the rate as the Legendre transform of an abstract
  cumulant generating function `Λ`, with the genuine variational lower bound
  `t·x − Λ t ≤ rateFn Λ x` (when the slope family is bounded above).
* `entropy_threshold_eq` — `log (polymer_const) = log 7` (the "→ 7" link).
* `log_seven_pos`, `mean_rate_fails_criterion` — `0 < log 7`, hence the
  rate-at-the-mean (which VANISHES, `I(e_bar) = 0`) can NEVER satisfy
  `log 7 < I`. This restates the `Wall255_JensenObstruction` no-go in rate
  language: smallness must come from the large-deviation TAIL, not the mean.

WHAT IS CONDITIONAL (on NAMED OPEN surfaces):
* `kp_rate_summable` — for any count `N n ≤ 7ⁿ`, `∑ₙ N n · exp(−I)ⁿ` is
  `Summable` GIVEN `log 7 < I`.
* `kp_polymer_rate_summable` — the genuine `EntropyBound` polymer count weighted
  by `exp(−I)ⁿ` is `Summable`, CONDITIONAL on BOTH `h_entropy` (the
  connective-constant count `≤ 7ⁿ`, open) AND `h_rate : log 7 < I` (the genuine
  SU(3) large-deviation rate bound — absent from mathlib v4.12.0; a HYPOTHESIS,
  NOT `by sorry`, so NO `sorryAx`).

## Honest scope (locked)

The rate bound `log 7 < I` is the ENTIRE open mathematical content. Establishing
it for the real SU(3) plaquette energy is genuine open work — it needs Cramér's
theorem / Varadhan's lemma and an actual computation of the SU(3) cumulant
generating function, none of which exist in mathlib v4.12.0. This file proves NO
such bound; `rateFn` is the Legendre transform of an ABSTRACT `Λ`, NOT the SU(3)
log-MGF. It establishes NO KP convergence, makes NO mass-gap / `μ > 0` /
Surface-#1 / RH / BSD claim, does NOT give `ρ(T) < 1`, and does NOT touch,
discharge, or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`.
YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall255_KP_Entropy` and mathlib's
`exp`/`log` + conditionally-complete-lattice API only; nothing from the NS tower.
================================================================
-/

import Towers.YM.Wall255_KP_Entropy
import Mathlib.Analysis.SpecialFunctions.Log.Basic

namespace TheoremaAureum.Towers.YM.Wall256Rate

open scoped BigOperators

/-! ### The rate↔smallness dictionary `q = exp(−I)` -/

/-- **Rate↔smallness dictionary.** The per-polymer activity `exp(−I)` beats the
`7ⁿ` entropy at the single-polymer level exactly when the rate exceeds `log 7`:
`exp(−I) < 1/7 ↔ log 7 < I`. (`1/7 = exp(−log 7)` and `exp` is strictly
monotone.) -/
theorem exp_neg_lt_inv_seven_iff (I : ℝ) :
    Real.exp (-I) < 1 / 7 ↔ Real.log 7 < I := by
  have h7 : (1 : ℝ) / 7 = Real.exp (-(Real.log 7)) := by
    rw [Real.exp_neg, Real.exp_log (by norm_num : (0:ℝ) < 7), one_div]
  rw [h7, Real.exp_lt_exp]
  constructor <;> intro h <;> linarith

/-- **Rate criterion (geometric form).** `7·exp(−I) < 1 ↔ log 7 < I` — the
condition under which the entropy-weighted geometric series converges. -/
theorem seven_exp_neg_lt_one_iff (I : ℝ) :
    7 * Real.exp (-I) < 1 ↔ Real.log 7 < I := by
  rw [← exp_neg_lt_inv_seven_iff]
  constructor <;> intro h <;> linarith

/-! ### The entropy-beating heart (genuine, unconditional given `log 7 < I`) -/

/-- **`rate_beats_entropy` (genuine).** For a rate `log 7 < I`, the
entropy-weighted series `∑ₙ 7ⁿ·exp(−I)ⁿ` is `Summable`. The `7ⁿ` polymer entropy
is KEPT inside the series. Direct from `Wall255.entropy_geometric_summable` with
`q := exp(−I)`. -/
theorem rate_beats_entropy {I : ℝ} (hI : Real.log 7 < I) :
    Summable (fun n : ℕ => (7 : ℝ) ^ n * Real.exp (-I) ^ n) :=
  Wall255.entropy_geometric_summable (Real.exp_pos _).le
    ((seven_exp_neg_lt_one_iff I).mpr hI)

/-- **`rate_tsum` (genuine).** Under `log 7 < I`, the entropy-weighted total is
`∑ₙ 7ⁿ·exp(−I)ⁿ = (1 − 7·exp(−I))⁻¹`. -/
theorem rate_tsum {I : ℝ} (hI : Real.log 7 < I) :
    ∑' n : ℕ, (7 : ℝ) ^ n * Real.exp (-I) ^ n = (1 - 7 * Real.exp (-I))⁻¹ :=
  Wall255.entropy_geometric_tsum (Real.exp_pos _).le
    ((seven_exp_neg_lt_one_iff I).mpr hI)

/-! ### The Legendre-transform rate function (genuine object, abstract `Λ`) -/

/-- **Large-deviation rate function** as the Legendre transform of a cumulant
generating function `Λ`. `Λ` is ABSTRACT — the genuine SU(3) log-MGF is the open
input; here `rateFn` is defined for any `Λ` so the variational structure is
available. -/
noncomputable def rateFn (Λ : ℝ → ℝ) (x : ℝ) : ℝ := ⨆ t : ℝ, t * x - Λ t

/-- **Variational lower bound (genuine).** Each Legendre slope `t·x − Λ t`
lower-bounds the rate, provided the slope family is bounded above (so the `⨆` is
the genuine supremum, not the junk value). -/
theorem le_rateFn (Λ : ℝ → ℝ) (x : ℝ)
    (hbdd : BddAbove (Set.range (fun t => t * x - Λ t))) (t : ℝ) :
    t * x - Λ t ≤ rateFn Λ x :=
  le_ciSup hbdd t

/-! ### The "→ 7" link and the mean-energy no-go in rate language -/

/-- **The "→ 7" link.** The rate threshold `log 7` is the log of the genuine
polymer connective constant `EntropyBound.polymer_const = 2d − 1 = 7`. -/
theorem entropy_threshold_eq :
    Real.log EntropyBound.polymer_const = Real.log 7 := by
  rw [EntropyBound.polymer_const]

/-- `0 < log 7`. -/
theorem log_seven_pos : 0 < Real.log 7 := Real.log_pos (by norm_num)

/-- **The mean-energy no-go, in rate language.** This theorem proves ONLY the
arithmetic fact `¬ (log 7 < 0)` (equivalently `0 ≤ log 7`). Its significance is
interpretive: the large-deviation rate vanishes at the mean (`I(e_bar) = 0` — a
standard LDP fact, NOT proved here and absent from mathlib v4.12.0), so plugging
`I = 0` into the criterion `log 7 < I` gives `log 7 < 0`, which this theorem
refutes. Hence the mean can NEVER meet the rate criterion — the rate-language
restatement of the `Wall255_JensenObstruction` no-go: KP smallness must come
from the large-deviation TAIL, not the mean energy. -/
theorem mean_rate_fails_criterion : ¬ Real.log 7 < 0 :=
  not_lt.mpr (le_of_lt log_seven_pos)

/-! ### Conditional KP combinators over the named-open rate surface -/

/-- **`kp_rate_summable` (honest conditional combinator).** For any nonnegative
size-count `N n ≤ 7ⁿ` and rate `log 7 < I`, the rate-weighted polymer sum
`∑ₙ N n · exp(−I)ⁿ` is `Summable`, by comparison with the geometric majorant
`(7·exp(−I))ⁿ`. CONDITIONAL on the rate bound `log 7 < I`. -/
theorem kp_rate_summable {N : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n)
    (hN : ∀ n, N n ≤ (7 : ℝ) ^ n) {I : ℝ} (h_rate : Real.log 7 < I) :
    Summable (fun n : ℕ => N n * Real.exp (-I) ^ n) :=
  Wall255.kp_entropy_weighted_summable hN0 hN (Real.exp_pos _).le
    ((seven_exp_neg_lt_one_iff I).mpr h_rate)

/-- **`kp_polymer_rate_summable` — the rate-function KP criterion (headline,
conditional).** The genuine `EntropyBound` polymer count, weighted by the
large-deviation activity `exp(−I)ⁿ`, is `Summable`, CONDITIONAL on BOTH named
OPEN surfaces: `h_entropy` (the connective-constant count `≤ 7ⁿ`, open per
`EntropyBound`) and `h_rate : log 7 < I` (the genuine SU(3) large-deviation rate
bound — absent from mathlib v4.12.0; a HYPOTHESIS, NOT `by sorry`, so no
`sorryAx`). Establishes NO KP convergence and makes NO mass-gap claim; does NOT
discharge `kotecky_preiss_criterion`. -/
theorem kp_polymer_rate_summable {L : ℕ} [NeZero L]
    (Connected : LatticeGauge.Polymer 4 L → Prop)
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          ≤ EntropyBound.polymer_const ^ n)
    {I : ℝ} (h_rate : Real.log 7 < I) :
    Summable (fun n : ℕ =>
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          * Real.exp (-I) ^ n) :=
  Wall255.kp_polymer_entropy_weighted_summable Connected h_entropy
    (Real.exp_pos _).le ((exp_neg_lt_inv_seven_iff I).mpr h_rate)

end TheoremaAureum.Towers.YM.Wall256Rate
