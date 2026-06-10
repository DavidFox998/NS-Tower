/-
STAND-IN: Defines an analytic-continuation predicate. Proves the
imaginary-axis exponential `t ↦ exp(-t·H)` extends to the entire
complex plane as `z ↦ exp(-z·H)`. Does NOT prove YM Schwinger →
Wightman. Surface #1 stays Open.

Batch 160.1. Brick that gives the analytic-continuation predicate a
first witness — i.e. shows the predicate is consistent / not vacuously
universal. This is NOT a proof that the YM Schwinger functions analytically
continue to Wightman distributions.

Honest scope of this file
-------------------------
* `analyticallyContinues f F` — predicate: `F` restricted to the real
                                axis equals `f`, and `F` is entire.
* `exp_neg_continues H`       — `t ↦ exp(-t·H)` analytically continues
                                to `z ↦ exp(-z·H)`. Standard fact.

What this file does NOT prove
-----------------------------
* This is NOT OS Axiom 0 / OS reconstruction.
* It only shows that a *one-parameter* exponential continues; it says
  nothing about the analytic continuation of multi-point Schwinger
  functions.
* This file does NOT close Surface #1. Surface #1 stays OPEN.

Deviation from the user-supplied snippet
----------------------------------------
The originally-requested `differentiable_const_mul _ _` is not the
name of an exported lemma in mathlib v4.12.0. We discharge the
differentiability obligation by explicit composition through
`Complex.differentiable_exp.comp` and `Differentiable.mul_const`.
(A `fun_prop` discharge was tried first but failed at build time
with "No theorems found for `Complex.exp`" because the v4.12.0
`fun_prop` simp set, in our minimal import surface, does not register
the `Complex.exp` differentiability lemmas — adding heavier imports
to fix that would balloon build time. Explicit composition is the
robust path here.)

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Complex.Analytic

namespace TheoremaAureum.Towers.YM.OS

open Complex

/-- Analytic-continuation predicate: `F : ℂ → ℂ` restricted to the real
    axis equals `f : ℝ → ℂ`, and `F` is entire (differentiable on all
    of `ℂ`). Honest stand-in shape — does not bake in growth bounds,
    Schwarz reflection, or any QFT-specific structure. -/
def analyticallyContinues (f : ℝ → ℂ) (F : ℂ → ℂ) : Prop :=
  Differentiable ℂ F ∧ ∀ t : ℝ, F (t : ℂ) = f t

/-- The real exponential `t ↦ exp(-t·H)` analytically continues to the
    entire complex function `z ↦ exp(-z·H)`. Both sides agree on the
    real axis by `push_cast` / `Complex.ofReal_*` simp normal form;
    entirety is `Complex.exp ∘ (polynomial)`, discharged by `fun_prop`. -/
lemma exp_neg_continues (H : ℝ) :
    analyticallyContinues
      (fun t : ℝ => (Complex.exp (-(t : ℂ) * (H : ℂ))))
      (fun z : ℂ => Complex.exp (-z * (H : ℂ))) := by
  refine ⟨?_, ?_⟩
  · -- Differentiable ℂ (fun z => Complex.exp (-z * (H : ℂ))).
    -- Explicit composition: identity is differentiable, so is its
    -- negation, so is `(-·) * (H : ℂ)`, and `Complex.exp` is entire.
    exact Complex.differentiable_exp.comp
      (differentiable_id.neg.mul_const (H : ℂ))
  · -- ∀ t, F (t : ℂ) = f t — definitional equality after coercion.
    intro _; rfl

end TheoremaAureum.Towers.YM.OS
