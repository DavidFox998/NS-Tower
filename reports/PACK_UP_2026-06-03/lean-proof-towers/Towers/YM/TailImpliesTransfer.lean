/-
STAND-IN: IntegratedTail bound → transferGapBound (universally
quantified pass-through via definitional equality `integrated_tail L m
= rexp(-m*L)`). Does NOT prove any real YM tail. Surface #1 Open.
Wall 493 → 494.

Batch 165.3. Third of the TRI PARALLEL #5 trio.

Honest scope of this file
-------------------------
* `tail_implies_transfer m L h` — given `(h : ∀ T P₀ : ℂ →L[ℂ] ℂ,
  ‖T - P₀‖ ≤ integrated_tail L m)` from Batch 156.6, concludes
  `∀ T P₀, transferGapBound T P₀ m L` via the definitional equality
  `integrated_tail L m = rexp(-m*L)`. Same structural shape as Batch
  164.1's `transfer_gap_real`, generalized over all `(T, P₀)`.

What this is NOT
----------------
* NOT a proof that any real YM heat-trace tail bounds any real YM
  transfer operator. The hypothesis is the same universally-quantified
  stand-in that only `T = P₀ = 0` can actually witness.
* NOT a closure of Surface #1. Surface #1 stays OPEN.

Drift from snippet
------------------
The snippet wrote
  `use ‖T - P₀‖ * rexp (m * L)`
  `constructor`
  `· exact mul_nonneg (norm_nonneg _) (le_of_lt (exp_pos _))`
  `· have := h T P₀; rw [integrated_tail] at this;`
  `  rw [mul_assoc, ← mul_le_mul_left (exp_pos (m * L))]; simpa using this`
but the live `transferGapBound T P₀ m L` is defined as the plain
proposition `‖T - P₀‖ ≤ Real.exp (-m * L)` (see
`Towers/YM/TransferOperatorBound.lean`) — it is NOT an `∃ C, …`
witness shape, so there is nothing to `use`. The snippet's
`constructor` / 2-branch `case`-split also has nothing to split on.

Honest pivot: drop the `use`/`constructor` entirely. The proof is the
single definitional unfold chain `transferGapBound = (‖T - P₀‖ ≤
rexp(-m*L))` and `integrated_tail L m = rexp(-m*L)`, after which `h
T P₀` is exactly the goal. Same structural pattern as Batch 164.1
(`unfold integrated_tail at h; exact h`).

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Towers.YM.IntegratedTailReal
import Towers.YM.TransferOperatorBound

namespace TheoremaAureum.Towers.YM.OS

open Real

/-- An `integrated_tail`-shaped bound on `‖T - P₀‖` for every
    `(T, P₀)` implies `transferGapBound T P₀ m L` for every
    `(T, P₀)`, by the definitional equality `integrated_tail L m =
    rexp(-m*L)`. Honest stand-in — generalizes 164.1's pass-through
    over the `(T, P₀)` universe. Does NOT prove any real YM tail. -/
theorem tail_implies_transfer (m L : ℝ)
    (h : ∀ T P₀ : ℂ →L[ℂ] ℂ, ‖T - P₀‖ ≤ integrated_tail L m) :
    ∀ T P₀ : ℂ →L[ℂ] ℂ, transferGapBound T P₀ m L := by
  intro T P₀
  have hTP := h T P₀
  unfold transferGapBound
  unfold integrated_tail at hTP
  exact hTP

end TheoremaAureum.Towers.YM.OS
