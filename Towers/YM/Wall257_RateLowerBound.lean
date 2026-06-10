/-
================================================================
Towers / YM / Wall257_RateLowerBound

**A single-site large-deviation rate that clears the entropy threshold —
honest MODELED brick.**

Sequel to `Wall256_RateFunction`. That file established the dictionary
`q = exp(−I)` and the criterion `log 7 < I` ("the rate beats the `7ⁿ` polymer
entropy"), with the genuine SU(3) rate `I` left as a NAMED OPEN surface. This
file exhibits a CONCRETE rate `I_E` that DOES clear `log 7` — but for a **MODELED
single-site cumulant generating function**, NOT the real SU(2)/SU(3) plaquette
log-MGF.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `bddAbove_slopes` — the Legendre slope family `t ↦ t·x − t²` is bounded above
  (by `x²/4`, via `(t − x/2)² ≥ 0`), so `Wall256Rate.rateFn` is the genuine
  supremum here, not the `⨆` junk value.
* `quarter_sq_le_I_E` — `x²/4 ≤ I_E x`, the genuine variational lower bound from
  `Wall256Rate.le_rateFn` at the optimal slope `t = x/2`.
* `I_E_unbounded` — `I_E` is unbounded above: for EVERY threshold `M` there is an
  `x₀` with `M < I_E x₀`. (This is precisely WHY the model is meaningless about
  real Yang–Mills — see the honest-scope note.)
* `exists_rate_gt_log_seven` — the requested `∃ x₀, log 7 < I_E x₀`.
* `rate_gap_single_site_vs_polymer` — the **Gap Lemma**: there are rate values
  where the single-site rate clears `log 7` yet the rate-at-the-mean (`0`, where
  every large-deviation rate vanishes) does NOT. Restates that clearing `log 7`
  at one site is NOT the same as the POLYMER rate clearing it; the gap is the
  inter-polymer dependence defect, quantified (conditionally) in
  `Wall258_DependenceDefect`.

## Honest scope (locked)

* `cgfModel t := t²` is a **MODELED Gaussian-type cumulant generating function**,
  NOT the SU(2)/SU(3) plaquette log-MGF. Its Legendre transform is the parabola
  `x²/4`, which clears ANY threshold — that is exactly the point: a modeled rate
  proves NOTHING about the real SU(N) large-deviation rate, which needs Cramér's
  theorem / Varadhan's lemma and the actual SU(N) character integral, none of
  which exist in mathlib v4.12.0.
* This file therefore establishes NO real rate bound, NO KP convergence, and
  makes NO mass-gap / `μ > 0` / Surface-#1 / RH / BSD claim. It does NOT touch,
  discharge, or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`.
  YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only (the trio enters
through `Wall256Rate.rateFn`'s `⨆`/`ciSup`). No `sorry`, no `sorryAx`, no new
axioms. Imports `Towers.YM.Wall256_RateFunction` only; nothing from NS.
================================================================
-/

import Towers.YM.Wall256_RateFunction

namespace TheoremaAureum.Towers.YM.Wall257Rate

open TheoremaAureum.Towers.YM

/-- **MODELED single-site cumulant generating function.** A Gaussian-type cgf
surrogate `Λ(t) = t²`. This is NOT the SU(2)/SU(3) plaquette log-MGF; it is an
abstract stand-in whose Legendre transform is available in closed form so the
rate machinery can be exercised. See the file header for the locked honest
scope. -/
def cgfModel (t : ℝ) : ℝ := t ^ 2

/-- **MODELED single-site large-deviation rate** = Legendre transform of
`cgfModel`. Equals `x²/4` (proved below as a lower bound). NOT the genuine SU(N)
rate. -/
noncomputable def I_E (x : ℝ) : ℝ := Wall256Rate.rateFn cgfModel x

/-- GENUINE. The Legendre slope family `t ↦ t·x − cgfModel t = t·x − t²` is
bounded above by `x²/4` (since `(t − x/2)² ≥ 0`), so the `⨆` defining
`I_E`/`rateFn` is the true supremum here. -/
theorem bddAbove_slopes (x : ℝ) :
    BddAbove (Set.range (fun t => t * x - cgfModel t)) := by
  refine ⟨x ^ 2 / 4, ?_⟩
  rintro y ⟨t, rfl⟩
  simp only [cgfModel]
  nlinarith [sq_nonneg (t - x / 2)]

/-- GENUINE. The variational lower bound `x²/4 ≤ I_E x`, obtained from
`Wall256Rate.le_rateFn` at the optimal Legendre slope `t = x/2`. -/
theorem quarter_sq_le_I_E (x : ℝ) : x ^ 2 / 4 ≤ I_E x := by
  have h := Wall256Rate.le_rateFn cgfModel x (bddAbove_slopes x) (x / 2)
  have hval : (x / 2) * x - cgfModel (x / 2) = x ^ 2 / 4 := by
    simp only [cgfModel]; ring
  rw [hval] at h
  exact h

/-- GENUINE. `I_E` is unbounded above: for every threshold `M` there is an `x₀`
with `M < I_E x₀`. The modeled rate clears ANY bar — which is exactly why it
carries no information about the real SU(N) rate. -/
theorem I_E_unbounded (M : ℝ) : ∃ x₀ : ℝ, M < I_E x₀ := by
  refine ⟨2 * (|M| + 1), ?_⟩
  have hq := quarter_sq_le_I_E (2 * (|M| + 1))
  have hx : (2 * (|M| + 1)) ^ 2 / 4 = (|M| + 1) ^ 2 := by ring
  rw [hx] at hq
  nlinarith [hq, le_abs_self M, abs_nonneg M, sq_nonneg (|M|)]

/-- The requested existential: the MODELED single-site rate clears the entropy
threshold `log 7`. (Immediate from `I_E_unbounded`; the content is modeled, not
real — see the file header.) -/
theorem exists_rate_gt_log_seven : ∃ x₀ : ℝ, Real.log 7 < I_E x₀ :=
  I_E_unbounded (Real.log 7)

/-- **Gap Lemma (single-site vs polymer rate).** There exist rate values `iE`,
`iP` with `log 7 < iE` but `¬ log 7 < iP`: the single-site (modeled) rate can
clear `log 7` while the rate at the mean (`iP = 0`, where every large-deviation
rate vanishes) cannot. The honest content: clearing `log 7` at ONE site does NOT
imply the POLYMER rate clears it — the two differ by the inter-polymer
dependence defect, which `Wall258_DependenceDefect` quantifies (conditionally).
**This is an INTERPRETIVE gap marker, NOT a formal comparison of a defined
polymer-rate functional**: `iE`/`iP` are bare reals (`iE := I_E x₀`, `iP := 0`),
NOT outputs of any formalized polymer-rate object — no such functional is
constructed in this tower. Reuses `Wall256Rate.mean_rate_fails_criterion`
(`¬ log 7 < 0`). -/
theorem rate_gap_single_site_vs_polymer :
    ∃ iE iP : ℝ, Real.log 7 < iE ∧ ¬ Real.log 7 < iP := by
  obtain ⟨x₀, hx₀⟩ := exists_rate_gt_log_seven
  exact ⟨I_E x₀, 0, hx₀, Wall256Rate.mean_rate_fails_criterion⟩

end TheoremaAureum.Towers.YM.Wall257Rate
