/-
STAND-IN: Defines a "boundedness" predicate (operator-norm bound) on
continuous linear functionals over any complex normed space, and shows
that every such functional is bounded in this sense (via its own
operator norm). Does NOT prove the YM field is tempered. Surface #1
stays Open.

Batch 161.1. Brick that gives an honest stand-in for the temperedness
predicate a first witness — i.e. shows the predicate is consistent /
not vacuously universal. This is NOT a proof that any Yang-Mills field
operator gives rise to a tempered Wightman distribution.

Honest scope of this file
-------------------------
* `tempered T`               — predicate over a complex normed space
                               `E`: there is a `C ≥ 0` such that
                               `‖T φ‖ ≤ C * ‖φ‖` for every `φ : E`.
                               (Bounded-functional half of being a
                               tempered distribution.)
* `tempered_of_clm T`        — every continuous ℂ-linear functional on
                               any `E` (normed `ℂ`-space) is tempered in
                               this sense, with `C := ‖T‖`. Discharged
                               by the standard
                               `ContinuousLinearMap.le_opNorm`.

What this file does NOT prove
-----------------------------
* The eventual target is `E := SchwartzMap ℝ ℂ`, but mathlib v4.12.0
  does not equip `SchwartzMap ℝ ℂ` with a global `Norm` instance —
  Schwartz temperedness uses a *family* of seminorms
  (`SchwartzMap.seminorm 𝕜 k n φ`, indexed by `(k, n)`), not a single
  norm. The honest stand-in here is the single-norm boundedness
  predicate on a generic `E`. The Schwartz-family version is a
  strictly stronger predicate and is not closed in this file.
* It says nothing about the regularity of any Yang-Mills field operator.
* This file does NOT close Surface #1. Surface #1 stays OPEN.

Deviation from the user-supplied snippet
----------------------------------------
The original snippet was truncated mid-statement at `SchwartzMap.bilin`.
Probing mathlib v4.12.0 shows there is no `SchwartzMap.bilin` (only
`SchwartzMap.bilinLeftCLM`, which is a different beast). A first
attempt to land an opNorm-bound predicate directly on
`SchwartzMap ℝ ℂ →L[ℂ] ℂ` also failed because the Schwartz space has
no global `Norm` instance in v4.12.0 — only the seminorm family. We
generalize away from the Schwartz space and land the honest
single-norm boundedness predicate on a generic complex normed space
`E`. The connection to Schwartz temperedness is documented above.

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.NormedSpace.OperatorNorm.Basic
import Mathlib.Analysis.Complex.Basic

namespace TheoremaAureum.Towers.YM.OS

/-- Operator-norm half of being a tempered distribution: there is a
    nonneg constant `C` such that `‖T φ‖ ≤ C * ‖φ‖` for every `φ : E`.
    Honest stand-in for the Schwartz-semi-norm-family version — the
    real predicate would index a sup over a family of Schwartz
    seminorms, but mathlib v4.12.0 does not give `SchwartzMap ℝ ℂ`
    a global `Norm` instance, so we work over a generic complex
    normed space `E` instead. -/
def tempered {E : Type*} [SeminormedAddCommGroup E] [NormedSpace ℂ E]
    (T : E →L[ℂ] ℂ) : Prop :=
  ∃ C : ℝ, 0 ≤ C ∧ ∀ φ : E, ‖T φ‖ ≤ C * ‖φ‖

/-- Every continuous ℂ-linear functional on any complex normed space
    `E` is tempered in the opNorm sense: take `C := ‖T‖`, then
    `‖T φ‖ ≤ ‖T‖ * ‖φ‖` is exactly `ContinuousLinearMap.le_opNorm`.
    Honest inhabitedness witness — proves the predicate is consistent,
    NOT that any Yang-Mills field operator is tempered in the
    Schwartz-distribution sense. -/
lemma tempered_of_clm {E : Type*} [SeminormedAddCommGroup E] [NormedSpace ℂ E]
    (T : E →L[ℂ] ℂ) : tempered T :=
  ⟨‖T‖, norm_nonneg _, fun φ => T.le_opNorm φ⟩

end TheoremaAureum.Towers.YM.OS
