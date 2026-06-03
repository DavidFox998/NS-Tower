/-
STAND-IN: Defines a `HasMassGap` predicate via a real-part inner-product
bound, and witnesses it for the zero operator at `m = 1`. Does NOT prove
any Yang-Mills theory has a spectral gap. Surface #1 stays OPEN.

Batch 162.2. Brick that shows the `HasMassGap` predicate is consistent
— i.e. has at least one witness. This is NOT a proof that any
Yang-Mills transfer / Hamiltonian operator exhibits a positive spectral
gap.

Honest scope of this file
-------------------------
* `HasMassGap H T m`         — predicate over a complex inner-product
                               space `H` and a continuous ℂ-linear
                               operator `T : H →L[ℂ] H`: there is a
                               positive `m` such that the real part of
                               `⟪x, T x⟫_ℂ` is bounded by
                               `(1 - m) * ‖x‖^2` for every `x`.
* `hasMassGap_zero`          — the zero operator on `ℂ` satisfies the
                               predicate at `m = 1` (the RHS is `0` and
                               so is the LHS; trivially `0 ≤ 0`).

What this file does NOT prove
-----------------------------
* This is NOT a proof that any Yang-Mills operator has a positive
  spectral gap. The witnessing operator is `0`, which has spectrum
  `{0}` and is the maximally degenerate case.
* This is NOT the full Wightman / Osterwalder-Schrader spectral-gap
  axiom (which involves the energy-momentum spectrum, not a single CLM).
* This file does NOT close Surface #1. Surface #1 stays OPEN.

Deviation from the user-supplied snippet
----------------------------------------
The original snippet wrote the bound as

    `⟪x, T x⟫_ℂ ≤ (1 - m) * ‖x‖ ^ 2`

This does not typecheck on mathlib v4.12.0: `⟪·, ·⟫_ℂ` has codomain
`ℂ`, and `ℂ` has no default `≤` ordering. (Mathlib provides a scoped
order via `open scoped ComplexOrder`, but that is not a default
instance.) The honest fix is to take the real part of the inner
product, giving the standard spectral-gap form

    `(⟪x, T x⟫_ℂ).re ≤ (1 - m) * ‖x‖ ^ 2`

which IS the usual hermitian-bound shape used in spectral-gap
arguments on complex Hilbert spaces.

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.NormedSpace.OperatorNorm.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.TypeStar

namespace TheoremaAureum.Towers.YM.OS

open scoped InnerProductSpace

/-- Spectral-gap predicate: there is a positive `m` such that the
    real part of `⟪x, T x⟫_ℂ` is bounded by `(1 - m) * ‖x‖^2`. The
    `.re` is required because `⟪·, ·⟫_ℂ` lands in `ℂ`, which has no
    default `≤` ordering. -/
def HasMassGap (H : Type _) [NormedAddCommGroup H] [InnerProductSpace ℂ H]
    (T : H →L[ℂ] H) (m : ℝ) : Prop :=
  0 < m ∧ ∀ x : H, (⟪x, T x⟫_ℂ).re ≤ (1 - m) * ‖x‖ ^ 2

/-- The zero operator on `ℂ` satisfies the predicate at `m = 1`: the
    LHS `(⟪x, 0⟫_ℂ).re = 0` and the RHS `(1 - 1) * ‖x‖^2 = 0`, so the
    inequality reduces to `0 ≤ 0`. Honest inhabitedness witness —
    proves the predicate is consistent, NOT that any Yang-Mills
    transfer operator has a gap. -/
lemma hasMassGap_zero : HasMassGap ℂ (0 : ℂ →L[ℂ] ℂ) 1 := by
  refine ⟨one_pos, ?_⟩
  intro x
  have hlhs : (⟪x, (0 : ℂ →L[ℂ] ℂ) x⟫_ℂ).re = 0 := by
    rw [ContinuousLinearMap.zero_apply, inner_zero_right]
    rfl
  have hrhs : (1 - (1 : ℝ)) * ‖x‖ ^ 2 = 0 := by ring
  rw [hlhs, hrhs]

end TheoremaAureum.Towers.YM.OS
