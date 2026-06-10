/-
STAND-IN: Defines OS-positivity predicate. Does NOT prove OS Axiom 1.
Surface #1 remains Open.

Batch 157.1. Brick 6 of 6 REVISED (replaces the 156.6 Varadhan attempt,
which is blocked on absent mathlib v4.12.0 prerequisites: there is no
`RiemannianManifold` typeclass, no `heatKernel` definition, no Hopf-Rinow
on manifolds, no parabolic Harnack, no Wiener measure on path space).

Honest scope of this file
-------------------------
* `reflection`         — spatial reflection of ℂ-valued test functions in
                          coordinate 0 of `EuclideanSpace ℝ (Fin (n+1))`.
                          Real function, not a placeholder. The companion
                          `reflection_involutive` lemma below is real.
* `reflectionPos`      — the *predicate* "the ℂ-linear functional ρ is
                          OS-positive". This is a `Prop`-level definition,
                          NOT a theorem that any specific functional
                          satisfies it.
* `reflection_pos_one` — the only honest companion lemma we can pin in
                          mathlib v4.12.0: integration against a *probability*
                          measure sends the constant-1 function to 1.

What this file does NOT prove
-----------------------------
* This is NOT OS Axiom 1 for any Yang-Mills / Euclidean measure.
* This is NOT a proof that any specific lattice-gauge or continuum measure
  is reflection-positive.
* The malformed template `[IsProbabilityMeasure ρ]` on a linear map has been
  rewritten as a typeclass on the *measure* (`μ`, not `ρ`), which is the
  only way the statement can be true: a generic ℂ-linear functional does
  NOT send `1 ↦ 1` — only an integration-against-probability functional does.

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`. This file does
NOT close Surface #1. The Surface1_InstallmentA.tex opengap (Varadhan
short-time heat-kernel asymptotics) remains and is parked.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.MeasureTheory.Integral.Bochner
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum.Towers.YM.OS

open MeasureTheory

/-- Spatial reflection in coordinate 0 on ℂ-valued functions over
    `EuclideanSpace ℝ (Fin (n+1))`. Pulls a function back along the
    pointwise map `x ↦ (−x₀, x₁, …, xₙ)`. -/
noncomputable def reflection {n : ℕ}
    (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    EuclideanSpace ℝ (Fin (n+1)) → ℂ :=
  fun x => f (Function.update x 0 (-(x 0)))

/-- Coordinate-0 reflection is an involution at the function level. -/
lemma reflection_involutive {n : ℕ}
    (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    reflection (reflection f) = f := by
  funext x
  unfold reflection
  have h0 : (Function.update x 0 (-(x 0)) : Fin (n+1) → ℝ) 0 = -(x 0) :=
    Function.update_same 0 (-(x 0)) x
  rw [h0, neg_neg, Function.update_idem, Function.update_eq_self]

/-- OS-positivity *predicate* on a ℂ-linear functional
    `ρ : (EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ`:
    for every test function `f`, the value
    `ρ (f̄ · reflection f)` has nonnegative real part.

    This is the *definition* of OS positivity, NOT a proof that any
    specific Yang-Mills or Euclidean measure satisfies it. -/
def reflectionPos {n : ℕ}
    (ρ : (EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ) : Prop :=
  ∀ f : EuclideanSpace ℝ (Fin (n+1)) → ℂ,
    0 ≤ (ρ (fun x => starRingEnd ℂ (f x) * reflection f x)).re

/-- Integration against a measure, packaged as a `(α → ℂ) → ℂ` functional.
    This is the honest stand-in for "linear functional represented by a
    Euclidean measure" — the only kind of functional for which
    `ρ 1 = 1` is true. -/
noncomputable def integralFunctional {α : Type*} [MeasurableSpace α]
    (μ : Measure α) : (α → ℂ) → ℂ :=
  fun f => ∫ x, f x ∂μ

/-- Honest replacement for the malformed template lemma `⇑ρ (1) = 1`:
    when `ρ` is integration against a *probability* measure `μ`, the
    constant-1 test function maps to `1`.

    Cf. the template, which placed `[IsProbabilityMeasure ρ]` on an
    *arbitrary* ℂ-linear functional `ρ`; that typeclass does not apply
    to linear maps (it is a typeclass on `Measure`), and the conclusion
    `ρ 1 = 1` is false for a generic linear functional. -/
lemma reflection_pos_one {α : Type*} [MeasurableSpace α]
    (μ : Measure α) [IsProbabilityMeasure μ] :
    integralFunctional μ (fun _ : α => (1 : ℂ)) = 1 := by
  unfold integralFunctional
  rw [integral_const, measure_univ, ENNReal.one_toReal, one_smul]

end TheoremaAureum.Towers.YM.OS
