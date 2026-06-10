/-
STAND-IN: Witnesses `HasMassGap H T (1/2)` on `H = L²(ℝ, ℂ)` with the
scalar-of-identity operator `T = (1/2 : ℂ) • 1`. First `HasMassGap`
witness that lives on a genuinely infinite-dimensional Hilbert space
(exiting the `(ℂ, 0)` toy witness of Batches 162.2 / 164.2 / 165.1).
Does NOT prove any Yang-Mills theory has a spectral gap.
Surface #1 stays Open. Wall 496 → 497.

Batch 166.3. Third of the TRI PARALLEL #6 trio.

CONTRACT NOTE: The witness uses `m = 1/2 ∈ (0, 1)` — strictly inside
the Batch 164.2 contract `m ∈ (0, 1]`. The bound `(1/2)·‖x‖² ≤
(1/2)·‖x‖²` holds with *equality*, so there is no margin to push `m`
toward `0` or `1`; sharpening would require a genuine spectral
estimate.

Honest scope of this file
-------------------------
* `nontrivial_gap`           — `∃ (m : ℝ), 0 < m ∧ m < 1 ∧
                                ∃ (T : H →L[ℂ] H), HasMassGap H T m`
                                with witnesses `m = 1/2` and
                                `T = (1/2 : ℂ) • (1 : H →L[ℂ] H)`,
                                where `H = L²(ℝ, ℂ)`.

What this is NOT
----------------
* NOT a proof that any Yang-Mills transfer / Hamiltonian operator
  has a positive spectral gap. The witnessing operator is a *scalar
  multiple of the identity* on a generic `L²` space; its spectrum is
  the single point `{1/2}` (totally degenerate). The "non-trivial"
  upgrade vs Batches 162.2 / 164.2 / 165.1 is the Hilbert space
  (`L²(ℝ, ℂ)` instead of `ℂ`), NOT the operator.
* NOT a closure of Surface #1. Surface #1 stays OPEN.

Drift from snippet
------------------
(1) **Operator choice.** Snippet picked `T := shift 0 - (1/2) • 1`,
    intending to use the (Batch 166.2) translation operator at `a = 0`.
    But on `L²` spaces `shift 0` is `compMeasurePreservingₗᵢ (a + ·)`
    at `a = 0`, which is only *a.e.-equal* to the identity, NOT
    definitionally / propositionally equal as a CLM. Proving
    `shift 0 = (1 : H →L[ℂ] H)` requires an `Lp.ae_eq` chain
    (`compMeasurePreserving f hf g =ᵐ[μ] g ∘ f`) plus a CLM
    extensionality lemma — non-trivial mathlib spelunking that the
    user's "sorry -- fill" placeholder elides. Honest pivot: drop
    the `shift 0` term entirely and use `T := (1/2 : ℂ) • 1`
    directly. The "non-trivial" character of this batch is the
    *Hilbert space* `L²(ℝ, ℂ)`, not the operator; using a scalar-
    of-identity is still a strict upgrade over Batches 162.2 / 164.2
    / 165.1, which had `(ℂ, 0)` — here we have `(L²(ℝ, ℂ), (1/2)·id)`.
    The `Towers.YM.ShiftOperator` import is kept positionally to
    record the dep edge into Batch 166.2 (whose `norm_shift` lemma
    is the actual ShiftOperator deliverable).
(2) **`∃` shape.** Snippet wrote the conclusion as
    `∃ (m : ℝ), 0 < m ∧ m < 1 ∧ ∃ (T : H →L[ℂ] H), HasMassGap H T m`
    but `HasMassGap` already packages the `0 < m` conjunct (it is
    defined as `0 < m ∧ ∀ x, (⟪x, T x⟫_ℂ).re ≤ (1 - m) * ‖x‖^2`).
    Snippet's `constructor; norm_num; constructor; norm_num` then
    discharges `0 < m` and `m < 1` separately, but `HasMassGap`'s
    own `0 < m` slot is discharged a third time at the innermost
    `constructor; norm_num`. Triple-witnessing `0 < m` is consistent
    (it's the same `m`), so we keep the snippet's shape verbatim
    and discharge by `refine ⟨1/2, by norm_num, by norm_num, _,
    by norm_num, ?_⟩`, with `?_` the inner-product bound.
(3) **Inner-product bound.** Snippet wrote `sorry -- fill: ‖(shift 0) x‖ = ‖x‖,
    then compute inner product`. Since we pivoted away from `shift 0`,
    the bound is now `(⟪x, ((1/2 : ℂ) • 1) x⟫_ℂ).re ≤ (1 - 1/2) * ‖x‖^2
    = (1/2) * ‖x‖^2`. The LHS evaluates via
      `((1/2 : ℂ) • 1) x = (1/2 : ℂ) • x`  (by `smul_apply` + `one_apply`)
      `⟪x, (1/2 : ℂ) • x⟫_ℂ = (1/2 : ℂ) * ⟪x, x⟫_ℂ`  (by `inner_smul_right`)
      `(·).re = (1/2 : ℂ).re * (⟪x, x⟫_ℂ).re`  (by `Complex.mul_re` with `(1/2 : ℂ).im = 0`)
      `= (1/2) * ‖x‖^2`  (by `inner_self_eq_norm_sq`).
    The bound is the *equality* `(1/2) * ‖x‖^2 ≤ (1/2) * ‖x‖^2`, closed
    by `le_refl`. This is the architect-noted "real work" — the type
    forces an actual inner-product calculation, not a trivial-bound
    `simp`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Towers.YM.ShiftOperator
import Towers.YM.SpectralGapCore

namespace TheoremaAureum.Towers.YM.OS

open scoped InnerProductSpace
open Complex

/-- A non-trivial `HasMassGap` witness on `H = L²(ℝ, ℂ)`. First
    witness in the tower whose Hilbert space is not `ℂ`. The
    operator is a scalar multiple of the identity (spectrum =
    `{1/2}`, totally degenerate); the upgrade is in the Hilbert
    space, not the operator. Does NOT prove YM has a mass gap. -/
lemma nontrivial_gap :
    ∃ (m : ℝ), 0 < m ∧ m < 1 ∧
      ∃ (T : H →L[ℂ] H), HasMassGap H T m := by
  refine ⟨1/2, by norm_num, by norm_num,
          (1/2 : ℂ) • (1 : H →L[ℂ] H), by norm_num, ?_⟩
  intro x
  have hT : ((1/2 : ℂ) • (1 : H →L[ℂ] H)) x = (1/2 : ℂ) • x := by
    simp [ContinuousLinearMap.smul_apply, ContinuousLinearMap.one_apply]
  rw [hT, inner_smul_right]
  -- Goal: `((1/2 : ℂ) * ⟪x, x⟫_ℂ).re ≤ (1 - 1/2) * ‖x‖^2`.
  -- Unfold `.re` of the product via `Complex.mul_re`, then collapse
  -- `(1/2 : ℂ).re = 1/2`, `(1/2 : ℂ).im = 0`, and use
  -- `inner_self_eq_norm_sq : re ⟪x,x⟫ = ‖x‖^2` to land in ℝ.
  rw [Complex.mul_re]
  have hr : (1/2 : ℂ).re = 1/2 := by norm_num
  have hi : (1/2 : ℂ).im = 0 := by norm_num
  have hsq : (⟪x, x⟫_ℂ).re = ‖x‖^2 :=
    (inner_self_eq_norm_sq (𝕜 := ℂ) x)
  have him : (⟪x, x⟫_ℂ).im = 0 := inner_self_im (𝕜 := ℂ) x
  rw [hr, hi, hsq, him]
  linarith [sq_nonneg ‖x‖]

end TheoremaAureum.Towers.YM.OS
