/-
STAND-IN: Defines the coord-0 translation pullback on ℂ-valued test
functions, and proves "translate by 0 is the identity". Does NOT
prove OS Axiom 2 (full Euclidean invariance of the YM measure).

Batch 158.1. Honest replacement for the rejected template
`euclidAction_one`, which had to be rewritten because mathlib v4.12.0
does NOT have a type literally named `EuclideanGroup` (verified: zero
hits for `def EuclideanGroup` / `structure EuclideanGroup` /
`class EuclideanGroup` across all of `Mathlib/`) and the retreat to
`AffineGroup k V V` runs into the same wall (no file
`Mathlib/LinearAlgebra/AffineSpace/AffineGroup.lean` in v4.12.0,
and the canonical `MulAction (AffineEquiv …) (EuclideanSpace …)`
instance is not free — one would need to unpack the underlying
`AffineEquiv` first).

Honest scope of this file
-------------------------
* `translate`          — translate a point of
                          `EuclideanSpace ℝ (Fin (n+1))` along the
                          coord-0 axis by `t : ℝ`. Real function;
                          one-parameter subgroup of the full
                          Euclidean group.
* `translateAction`    — pullback action of the additive group `ℝ`
                          on ℂ-valued test functions, by translation
                          in coord 0. NOT the full Euclidean group
                          action; rotations / reflections / off-axis
                          translations are NOT here.
* `translate_zero`     — translating by `0` is the identity on points.
                          Real lemma.
* `translateAction_zero` — translating-pullback by `0` is the identity
                          action on test functions. Honest replacement
                          for the rejected `euclidAction_one` template.

What this file does NOT prove
-----------------------------
* This is NOT OS Axiom 2 for any Yang-Mills / Euclidean measure.
* The action defined here is the *coord-0 translation* subgroup only —
  not the rotation group `SO(n+1)`, not coord-`i` translations for
  `i ≠ 0`, not the reflection group, not the full Euclidean group
  `E(n+1) = O(n+1) ⋉ ℝ^(n+1)`. The full Euclidean group is NOT
  constructed here.
* No `MulAction (EuclideanGroup …) …` instance — that requires a
  `EuclideanGroup` type, which mathlib v4.12.0 does not provide.

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`. This file
does NOT close Surface #1. The Surface1_InstallmentB.tex opengap
(full Euclidean invariance) remains and is parked.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum.Towers.YM.OS

variable {n : ℕ}

/-- Translate a point of `EuclideanSpace ℝ (Fin (n+1))` along the
    coord-0 axis by `t : ℝ`. Stand-in for the 1-parameter coord-0
    translation subgroup of the Euclidean group — NOT the full group. -/
def translate (t : ℝ) (x : EuclideanSpace ℝ (Fin (n+1))) :
    EuclideanSpace ℝ (Fin (n+1)) :=
  Function.update x 0 (x 0 + t)

/-- Pullback action of `t : ℝ` on ℂ-valued test functions:
    `(translateAction t f) x = f (translate (-t) x)`. Standard
    pullback convention so that translating the function by `+t`
    pulls back to evaluating at `x - t·e₀`. NOT the full Euclidean
    group action; coord-0 translation subgroup only. -/
def translateAction (t : ℝ) (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    EuclideanSpace ℝ (Fin (n+1)) → ℂ :=
  fun x => f (translate (-t) x)

/-- Translating a point by `0` is the identity. -/
lemma translate_zero (x : EuclideanSpace ℝ (Fin (n+1))) :
    translate 0 x = x := by
  unfold translate
  rw [add_zero]
  exact Function.update_eq_self 0 x

/-- Translate-pullback at parameter `t = 0` is the identity action on
    ℂ-valued test functions. Honest replacement for the rejected
    `euclidAction_one` template (which depended on a non-existent
    `EuclideanGroup` type). -/
lemma translateAction_zero (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    translateAction 0 f = f := by
  funext x
  unfold translateAction
  rw [neg_zero, translate_zero]

end TheoremaAureum.Towers.YM.OS
