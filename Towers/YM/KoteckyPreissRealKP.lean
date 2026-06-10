/-
================================================================
Towers / YM / KoteckyPreissRealKP (Batch 177.2 / TRI PARALLEL #17, file 2 of 3)

**Stand-in module.** Lands a Kotecký–Preiss-shaped existential
`∃ β₀ μ, 0 ≤ μ ∧ ∀ β > β₀, ∀ X, ∏ p in X, rexp(-β ·
plaquetteEnergy U p) ≤ rexp(-μ · |X|)` against the *real*
per-plaquette Wilson energy `plaquetteEnergy` introduced in
Batch 177.1. Parameterised on an arbitrary configuration `U` and
a per-plaquette non-negativity hypothesis on `plaquetteEnergy`
(the trivial direction of the SU(2) bound, which lands as a
hypothesis here because the full SU(2) trace bound is a
real-Haar tripwire — see Batch 177.1 header).

  * **Witness `(β₀, μ) := (0, 0)`.** `μ := 0` so `0 ≤ μ` is
    `le_refl 0`. The RHS `rexp(-0 · |X|) = rexp(0) = 1`. The
    LHS is a finite product of `rexp(-β · E_p)` terms; each is
    `≤ 1` for `β > 0` and `E_p ≥ 0` (`exp` of a non-positive
    argument), so the product is `≤ 1` via `Finset.sum_nonpos`
    after collapsing `∏ exp = exp (∑)` (`Real.exp_sum`).

## Honest scope (locked)
* **Does NOT witness `0 < μ`.** The snippet asserts `0 < μ`
  (strict), but at any plaquette with `plaquetteEnergy = 0`
  (which the Dirac-support point `U ≡ const 1` exhibits — see
  Batch 177.1 `plaquetteEnergy_const_one`), the LHS contains the
  factor `rexp(-β · 0) = 1`, so the product over `|X| ≥ 1` is
  `1`, and for any `μ > 0` the RHS `rexp(-μ · |X|) < 1` for
  `|X| ≥ 1` — making `LHS ≤ RHS` *false*. Honest pivot: weaken
  to `0 ≤ μ` and witness `μ := 0` (same pattern as the
  `linkEnergy ≡ 1` K-P brick in Batch 175.1 / 176.2). The
  snippet's "**Real Kotecký–Preiss with μ > 0**" headline claim
  is REFUSED — `μ > 0` is mathematically *false* without
  geometric / FKG / cluster-expansion machinery (none landed).
* **Does NOT close
  `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`.**
  The snippet's "CONTRACT: This retires the
  `kotecky_preiss_criterion` sorry" claim is REFUSED. That sorry
  is *invariant-locked* per the locked invariants in `replit.md`
  (axiom debt is the classical trio; the genuine K-P criterion
  needs the SU(2) trace bound + cluster-expansion convergence
  argument — combinatorial induction over polymer families,
  geometric counting bounds, neither landed). The brick below
  lives in `TheoremaAureum.Towers.YM.LatticeGauge`; the Attempts
  theorem lives in `Towers.Attempts.ClusterExpansion` and does
  not unify with it. **`kotecky_preiss_criterion` remains a
  `sorry` in `Towers/Attempts/ClusterExpansion.lean`.**
* **Surface #1 stays OPEN.** The K-P bound here is the trivial
  `μ = 0` upper bound `∏ exp(-β · E) ≤ 1`, which is the *same*
  content as Batch 175.1 / 176.2 (just expressed against
  `plaquetteEnergy` instead of `linkEnergy ≡ 1`). It does NOT
  give the spectral gap; the genuine cluster-expansion `μ > 0`
  requires the full SU(2) energy lower bound + induction.

## Drift from snippet
* (1) **`Plaquette d L` introduced** as the canonical plaquette
  argument type `Lattice d L × Fin d × Fin d`. Snippet
  referenced `Finset (Plaquette d L)` but never declared the
  type; the inline tuple is the natural reading (a plaquette is
  a site + an ordered pair of directions, matching the
  `wilsonAction` summation in Batch 168.2). Defined here
  rather than 177.1 to avoid leaking the name into modules that
  do not need it.
* (2) **Free symbol `U` made an explicit parameter.** Snippet
  referenced `U` in the theorem body but never bound it. Honest
  pivot: take `U : GaugeConfig d L` as an explicit hypothesis.
* (3) **Free hypothesis `hE : ∀ p, 0 ≤ plaquetteEnergy U p`
  added.** Required to discharge `β · E_p ≥ 0` (needed so
  `rexp(-β · E_p) ≤ 1`). This is the *trivial direction* of
  the SU(2) bound `0 ≤ plaquetteEnergy ≤ 2`, deferred at 177.1
  because the snippet's `sorry`-fill cited "Mathlib has this"
  but mathlib v4.12.0 does not. Same parameterisation pattern
  as `clustering_of_factor` (Batch 173.2) / `gibbs_translation_inv`
  (Batch 170.3).
* (4) **`0 < μ` → `0 ≤ μ`** with witness `μ := 0` (see Honest
  scope above).
* (5) **`sorry -- fill: Uses 177.1 bounds + β >> 1. Standard
  polymer estimate.` eliminated.** Snippet's "standard polymer
  estimate" is the cluster-expansion convergence theorem (not
  landed). Honest pivot: with `μ := 0`, the RHS is `1` and the
  bound reduces to `∏ exp(-β · E_p) ≤ 1`, provable via
  `Real.exp_sum` (collapse product to `exp(-β · ∑ E_p)`) +
  `Real.exp_le_one_iff.mpr` (non-positivity of the exponent) +
  `Finset.sum_nonneg` + `mul_nonneg` + `Real.exp_zero`.
* (6) **`X.card : ℝ` coercion** explicit throughout (snippet
  mixed `ℕ` and `ℝ`).
* (7) **`open Real` dropped** in favour of fully-qualified
  `Real.exp` / `Real.exp_sum` / `Real.exp_le_one_iff` (matches
  Batch 176.2 convention).
* (8) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (matches Batch 177.1).

## Tripwire (mass gap)
* `(β₀, μ) := (0, 0)` is the **trivial** K-P witness — RHS = 1,
  bound reduces to `LHS ≤ 1`. The genuine K-P needs `μ > 0` with
  `μ` depending on `β - β_c` (positive critical coupling),
  which requires:
    - the SU(2) trace lower bound `Re tr ≥ -2` (so
      `plaquetteEnergy ≤ 2`),
    - cluster-expansion combinatorial induction (none landed),
    - the genuine activity bound `|w(X)| ≤ rexp(-α · |X|)` for
      `α > 0` (Batch 175.1 / 176.2 / this batch all witness `μ
      ≤ 0` style only).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof uses
`Real.exp_sum`, `Real.exp_zero`, `Real.exp_le_one_iff`,
`Finset.sum_nonneg`, `mul_nonneg`, `le_of_lt`, `neg_nonpos`,
`simp`, `linarith`.
================================================================
-/

import Towers.YM.PlaquetteEnergy
import Mathlib.Analysis.SpecialFunctions.Exp

namespace TheoremaAureum.Towers.YM.LatticeGauge

open scoped BigOperators

/-- **`Plaquette d L`** — canonical plaquette argument type:
    a site plus an ordered pair of directions (matching the
    inner summand of `wilsonAction` in Batch 168.2). Snippet
    referenced this type without declaring it; introduced here. -/
def Plaquette (d L : ℕ) : Type := Lattice d L × Fin d × Fin d

/-- **Brick (`kotecky_preiss_real_kp`).** Stand-in form of the
    Kotecký–Preiss criterion against the *real*
    `plaquetteEnergy` from Batch 177.1, parameterised on an
    arbitrary gauge configuration `U` and a per-plaquette
    non-negativity hypothesis `hE` (the trivial direction of
    the SU(2) bound, deferred). Witnesses `(β₀, μ) := (0, 0)`
    so `0 ≤ μ` is `le_refl 0`. **Does NOT prove `0 < μ`**
    (snippet's "Real K-P with μ > 0" claim REFUSED — `μ > 0`
    is false at `U ≡ const 1` per `plaquetteEnergy_const_one`).
    **Does NOT close
    `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`**
    (snippet's "CONTRACT: This retires the
    `kotecky_preiss_criterion` sorry" claim REFUSED — that sorry
    is invariant-locked). -/
theorem kotecky_preiss_real_kp (d L : ℕ) [NeZero L]
    (U : GaugeConfig d L)
    (hE : ∀ p : Plaquette d L, 0 ≤ plaquetteEnergy U p.1 p.2.1 p.2.2) :
    ∃ β₀ μ : ℝ, 0 ≤ μ ∧ ∀ β, β > β₀ → ∀ X : Finset (Plaquette d L),
      ∏ p in X, Real.exp (-β * plaquetteEnergy U p.1 p.2.1 p.2.2)
        ≤ Real.exp (-μ * (X.card : ℝ)) := by
  refine ⟨0, 0, le_refl 0, fun β hβ X => ?_⟩
  -- Collapse the product to a single exponential of the sum.
  rw [← Real.exp_sum]
  -- RHS: rexp (-0 * X.card) = rexp 0 = 1.
  have hRHS : Real.exp (-(0 : ℝ) * (X.card : ℝ)) = 1 := by
    simp
  rw [hRHS]
  -- Reduce to: rexp (∑ p in X, -β * E_p) ≤ 1.
  rw [Real.exp_le_one_iff]
  -- Goal: ∑ p in X, -β * E_p ≤ 0, equivalent to ∑ p in X, β * E_p ≥ 0.
  have h_sum_nonneg : 0 ≤ ∑ p in X, β * plaquetteEnergy U p.1 p.2.1 p.2.2 := by
    apply Finset.sum_nonneg
    intro p _
    exact mul_nonneg (le_of_lt hβ) (hE p)
  have h_neg : ∑ p in X, -β * plaquetteEnergy U p.1 p.2.1 p.2.2
              = -(∑ p in X, β * plaquetteEnergy U p.1 p.2.1 p.2.2) := by
    rw [← Finset.sum_neg_distrib]
    congr 1
    funext p
    ring
  rw [h_neg]
  linarith

end TheoremaAureum.Towers.YM.LatticeGauge
