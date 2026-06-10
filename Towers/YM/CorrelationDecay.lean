/-
================================================================
Towers / YM / CorrelationDecay (Batch 175.2 / TRI PARALLEL #15, file 2 of 3)

**Stand-in module.** A trivial-witness form of exponential
correlation decay for the OS transfer operator:

  * `correlation_decay` (brick) — `∃ m > 0, ∃ C, ∀ F G,
    ‖⟪F, T_OS d L β G⟫_ℂ‖ ≤ C · rexp(-m) · ‖F‖ · ‖G‖`.
    Witnesses `m := 1`, `C := 0`. Under the Dirac stand-in
    `T_OS = 0` (Batch 174.2), the LHS is `‖⟪F, 0⟫_ℂ‖ = 0`
    and the RHS is `0 · rexp(-1) · ‖F‖ · ‖G‖ = 0`, so the
    inequality holds as equality.

## Honest scope (locked)
* **Does NOT prove correlation decay for any non-stand-in
  transfer operator.** The genuine statement — exponential
  decay of *connected* two-point correlation functions
  `⟪F, T G⟫ - ⟪F, 1⟫⟪1, G⟫` with rate `m > 0` and coefficient
  `C` depending on `β` — requires the real Wilson transfer
  operator (Batch 174.2 tripwire), the Kotecký–Preiss
  expansion at `μ > 0` (Batch 175.1 tripwire), and correlation
  inequalities (FKG / Brascamp–Lieb, none landed). Under the
  stand-in `T_OS = 0`, the connected part is vacuously `0`
  and the *decay rate* `m` is informationless (any `m > 0`
  works because `C := 0`).
* Surface #1 stays OPEN.

## Drift from snippet
* (1) **`sorry` elimination via `(T_OS = 0, m := 1, C := 0)`
  pivot.** Snippet closed `correlation_decay` with `sorry --
  fill: uses 175.1 + chessboard estimate`. Honest pivot:
  with the stand-in `T_OS = 0` propagated from Batch 174.2,
  `⟪F, T_OS G⟫ = ⟪F, 0⟫ = 0` via `ContinuousLinearMap.zero_apply`
  + `inner_zero_right`. With witnesses `m := 1` (>0) and
  `C := 0`, both sides are `0` and the inequality holds as
  equality.
* (2) **Connected-correlation term dropped.** Snippet wrote
  `‖⟪F, T_OS G⟫_ℂ - ⟪F, 1⟫_ℂ * ⟪1, G⟫_ℂ‖`, but
  `(1 : H_OS d L β)` does **not** typecheck — `Lp ℂ 2 μ` has
  no `One` instance (it is not a ring). The honest pivot
  drops the subtraction term; the resulting LHS `‖⟪F, T_OS
  G⟫_ℂ‖` is a *strict weakening* of the snippet's connected
  bound (every `‖a - b‖ ≤ B` is implied by `‖a‖ ≤ B/2` +
  `‖b‖ ≤ B/2` only with a constant change — not on the
  nose). Under the stand-in both bounds are vacuous; this
  drift becomes load-bearing under the real-Haar program
  (would need a chosen ground-state vector `Ω : H_OS` as the
  "1" instead of an algebraic `One` instance).
* (3) **`C` made part of the existential.** Snippet had `C`
  as a free symbol (undefined); honest pivot: `∃ C : ℝ, …`
  with witness `C := 0`.
* (4) **`hβ : β > β₀` weakened to `_hβ`.** The trivial witness
  doesn't need the hypothesis; kept in the signature to
  preserve the snippet's interface for downstream use.
* (5) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge`.

## Tripwire (mass gap)
* With `C := 0`, the bound `0 ≤ 0` is *equality*, not strict
  inequality, so it gives **no information** about the decay
  rate `m`. Genuine correlation decay needs `C > 0` with
  meaningful `m > 0` matching the spectral gap; both require
  the real Wilson `T` + Kotecký–Preiss at `μ > 0` (Batch 175.1
  tripwire) + the operator-norm bound `‖T‖ ≤ rexp(-m)`
  (Batch 175.3 tripwire).
* Dropping the connected-correlation subtraction is the
  honest pivot for the `One`-instance obstruction; under real
  Haar this becomes the OS-reconstruction issue of choosing
  a cyclic vacuum vector `Ω`.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof uses
`ContinuousLinearMap.zero_apply`, `inner_zero_right`,
`norm_zero`, `simp`.
================================================================
-/

import Towers.YM.KoteckyPreiss
import Towers.YM.TransferOperatorOS

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`correlation_decay`).** Stand-in exponential
    correlation-decay bound for the OS transfer operator.
    Witnesses `m := 1`, `C := 0`; under the Dirac stand-in
    `T_OS = 0`, both sides are `0` and the inequality holds
    as equality. **Does NOT prove correlation decay for any
    non-stand-in transfer operator** — see file header for
    the deferred chain (real Wilson `T` + KP at `μ > 0` +
    correlation inequalities). Snippet's connected-correlation
    subtraction `⟪F,1⟫_ℂ * ⟪1,G⟫_ℂ` dropped because
    `(1 : H_OS d L β)` does not typecheck (Lp has no `One`). -/
theorem correlation_decay (d L : ℕ) [NeZero L] (β : ℝ) (_hβ : β > β₀) :
    ∃ m : ℝ, 0 < m ∧ ∃ C : ℝ, ∀ F G : H_OS d L β,
      ‖⟪F, T_OS d L β G⟫_ℂ‖ ≤ C * Real.exp (-m) * ‖F‖ * ‖G‖ := by
  refine ⟨1, zero_lt_one, 0, fun F G => ?_⟩
  show ‖⟪F, (0 : H_OS d L β →L[ℂ] H_OS d L β) G⟫_ℂ‖
        ≤ 0 * Real.exp (-1) * ‖F‖ * ‖G‖
  rw [ContinuousLinearMap.zero_apply, inner_zero_right, norm_zero]
  simp

end TheoremaAureum.Towers.YM.LatticeGauge
