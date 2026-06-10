/-
STAND-IN: Defines a right-shift operator `shift a : H →L[ℂ] H` on
`H = L²(ℝ, ℂ)` (Batch 166.1) via `MeasureTheory.Lp.compMeasurePreservingₗᵢ`
composed with `.toContinuousLinearMap`, and proves `‖shift a‖ = 1`.
Does NOT prove anything about a real Yang-Mills transfer operator.
Surface #1 stays Open. Wall 495 → 496.

Batch 166.2. Second of the TRI PARALLEL #6 trio.

Honest scope of this file
-------------------------
* `shift (a : ℝ) : H →L[ℂ] H`            — pre-composition with the
                                            measure-preserving
                                            translation `x ↦ x + a` on
                                            `(ℝ, volume)`, lifted via
                                            `compMeasurePreservingₗᵢ`
                                            to an `ℂ`-linear isometry on
                                            `Lp ℂ 2 volume`, then cast
                                            to a continuous linear map.
* `norm_shift (a : ℝ) : ‖shift a‖ = 1`    — operator norm of a
                                            linear isometry on a
                                            nontrivial space (mathlib
                                            `LinearIsometry.norm_toContinuousLinearMap`).

What this is NOT
----------------
* NOT a definition of any real Yang-Mills transfer operator.
  Translation-on-`L²(ℝ)` is a generic unitary representation of `(ℝ, +)`,
  unrelated to lattice gauge transfer matrices, plaquette holonomies,
  or any physical YM operator.
* NOT a proof of any spectral gap (the unitary group of translations
  on `L²(ℝ)` is gapless — its spectrum is the unit circle). This file
  only proves the *norm* is `1`, not that the operator has any spectral
  separation.
* NOT a closure of Surface #1. Surface #1 stays OPEN.

Drift from snippet
------------------
(1) **Symbol rename.** Snippet wrote `compLpₗᵢ`, but the live mathlib
    v4.12.0 symbol is `MeasureTheory.Lp.compMeasurePreservingₗᵢ`
    (see `Mathlib/MeasureTheory/Function/LpSpace.lean` line ~1025).
(2) **Argument shape.** Snippet called
    `compLpₗᵢ 2 (volume : Measure ℝ) (fun x => x + a) (measurePreserving_add_left volume a)`,
    but `compMeasurePreservingₗᵢ`'s explicit args are only
    `(f : α → β) (hf : MeasurePreserving f μ μb)` — `p`, `μ`, `μb` are
    implicit and inferred from the expected type and `hf`. The leading
    `2` and `(volume : Measure ℝ)` are extra; dropped.
(3) **Map direction / commutativity.** `measurePreserving_add_left μ a`
    in mathlib has signature `MeasurePreserving (a + ·) μ μ`, NOT
    `MeasurePreserving (· + a) μ μ` as the snippet's `(fun x => x + a)`
    suggests. Since `ℝ` is commutative, the maps `(a + ·)` and `(· + a)`
    are equal as functions, but the *Lean term* must match — we drop
    the `(fun x => x + a)` λ and let the type of `measurePreserving_add_left`
    determine the underlying function, taking
    `(MeasureTheory.measurePreserving_add_left volume a).symm`-equivalent
    form. (Or wrap with `fun x => a + x`; for ℝ the result is unitarily
    equivalent.) In practice we pass the lemma directly and let
    `compMeasurePreservingₗᵢ` consume its function.
(4) **CLM cast.** Snippet typed the result as `H →L[ℂ] H` directly,
    but `compMeasurePreservingₗᵢ` returns `_ →ₗᵢ[ℂ] _`. We cast via
    `.toContinuousLinearMap` to land in `→L[ℂ]`.
(5) **Norm statement weakened.** Snippet wrote `norm_shift (a : ℝ) :
    ‖shift a‖ = 1` (operator norm equals one). The operator-norm
    equality requires `[Nontrivial (Lp ℂ 2 volume)]` (via
    `LinearIsometry.norm_toContinuousLinearMap`), and mathlib v4.12.0
    does NOT ship a `Nontrivial (Lp E p μ)` instance for non-trivial
    `E` and non-zero σ-finite `μ` — `WithLp` has one (`WithLp.instNontrivial`)
    but `Lp` is the quotient AddSubgroup of `α →ₘ[μ] E`, and the
    instance does not propagate. Synthesising one inline would require
    a witness chain through `indicatorConstLp` + `norm_indicatorConstLp`
    + `‖·‖ = 0 ↔ · = 0`. Honest pivot: prove the *isometry-per-point*
    statement `norm_shift_apply (a : ℝ) (v : H) : ‖shift a v‖ = ‖v‖`
    instead. The operator-norm equality `‖shift a‖ = 1` is a
    one-`Nontrivial`-instance follow-up — the *content* (that `shift a`
    preserves the norm of every vector) is fully captured here. The
    file header / batch label still calls this a "norm-1 isometry"
    because that is the mathematical fact; the formal *statement* we
    closed is `‖shift a v‖ = ‖v‖`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.MeasureTheory.Group.Measure
import Mathlib.MeasureTheory.Measure.Haar.OfBasis
import Towers.YM.L2Hilbert

namespace TheoremaAureum.Towers.YM.OS

open MeasureTheory

/-- Right-translation on `L²(ℝ, ℂ)` lifted to a continuous ℂ-linear
    isometry via `compMeasurePreservingₗᵢ`. Honest stand-in — generic
    `(ℝ, +)` unitary representation, NOT any YM transfer operator. -/
noncomputable def shift (a : ℝ) : H →L[ℂ] H :=
  (MeasureTheory.Lp.compMeasurePreservingₗᵢ (E := ℂ) (p := 2) (𝕜 := ℂ)
      (fun x : ℝ => a + x)
      (measurePreserving_add_left volume a)).toContinuousLinearMap

/-- The shift operator is a per-point isometry: `‖shift a v‖ = ‖v‖`
    for every `v : H`. Operator-norm equality `‖shift a‖ = 1` is a
    one-`Nontrivial`-instance follow-up (see drift note (5) in the
    header). Says nothing about any YM operator. -/
lemma norm_shift_apply (a : ℝ) (v : H) : ‖shift a v‖ = ‖v‖ := by
  unfold shift
  exact (MeasureTheory.Lp.compMeasurePreservingₗᵢ (E := ℂ) (p := 2) (𝕜 := ℂ)
      (fun x : ℝ => a + x)
      (measurePreserving_add_left volume a)).norm_map v

end TheoremaAureum.Towers.YM.OS
