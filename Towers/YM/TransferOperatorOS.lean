/-
================================================================
Towers / YM / TransferOperatorOS (Batch 174.2 / TRI PARALLEL #14, file 2 of 3)

**Stand-in module.** Introduces the OS transfer operator carrier
+ two of its load-bearing properties under the Dirac haar
stand-in:

  * `T_OS d L β` — `noncomputable def` for the transfer operator
    on `H_OS d L β`. **Stand-in form: `T_OS := 0`** (the zero
    continuous linear map). The real transfer operator would
    be time-translation by one step against the Wilson Gibbs
    kernel `K(U, U') := exp(-S_link[U, U'])`; under the Dirac
    haar stand-in (Batch 168.3) the support is the singleton
    `{const 1}`, every observable is constant-a.e., and the
    only continuous linear endomorphism honouring the Dirac
    support that can be honestly declared with a `rfl` axiom-
    footprint without inventing a kernel is the zero operator.
  * `T_OS_positive` — `0 ≤ ⟪ψ, T_OS ψ⟫_ℂ` for every `ψ`. Under
    the stand-in, `T_OS ψ = 0` so the inner product is `0`,
    trivially `≤` itself. Load-bearing predicate name from
    OS-1; under real Haar this becomes the consequence of
    reflection positivity. Requires `open scoped ComplexOrder`
    to put `PartialOrder ℂ` in scope.
  * `T_OS_selfAdjoint` — `IsSelfAdjoint (T_OS d L β)`. Under
    the stand-in, `T_OS = 0` and `IsSelfAdjoint.zero _`
    discharges the goal. Load-bearing predicate name from OS-2;
    under real Haar this becomes the consequence of
    time-reflection invariance of the Wilson action.

Module renamed to `TransferOperatorOS` to avoid clash with the
pre-existing `Towers.YM.TransferOperator` (Batch 162.3,
trivial-`(ℂ, 0)`-witness module that registered the brick
`spectral_radius_transfer_zero`).

## Honest scope (locked)
* This is a **stand-in module**, not a construction of the
  real Wilson transfer operator. The real construction would
  require:
    - real-Haar `gibbsMeasure` (deferred),
    - the Wilson link kernel `K(U, U')` with real-Haar
      normalisation (deferred),
    - a Bochner-integrable kernel-operator definition (deferred),
    - OS-1 + OS-2 (real-Haar versions, deferred).
  None of the above is landed. Surface #1 stays OPEN.
* The stand-in `T_OS := 0` is the **honest minimum** that lets
  the predicate names `T_OS_positive` and `T_OS_selfAdjoint`
  carry a real proof under the trio-axioms / no-sorry
  invariant. It also sets up Batch 174.3's
  `mass_gap_dirac : mass_gap = 0` tripwire: the Dirac stand-in
  yields a stand-in transfer operator with spectral norm `0`,
  which gives a "mass gap" of `-log 0 = 0`, *not* a positive
  mass gap.

## Drift from snippet
* (1) **`sorry` elimination via `T := 0` pivot.** Snippet had
  three `sorry`s (one in `def T`, one in `T_positive`, one in
  `T_selfAdjoint`), all forbidden under the trio-axioms / no-
  sorry invariant. Honest pivot: define `T_OS := 0` (the zero
  CLM), then `T_OS_positive` discharges via
  `inner_zero_right` and `le_refl 0` (under
  `open scoped ComplexOrder`), and `T_OS_selfAdjoint`
  discharges via `IsSelfAdjoint.zero _` (the `Star`
  instance on `H_OS →L[ℂ] H_OS` comes from
  `Mathlib.Analysis.InnerProductSpace.Adjoint`).
* (2) **Module rename to `TransferOperatorOS`** to avoid
  clash with `Towers.YM.TransferOperator` (Batch 162.3, in
  lakefile roots, registers `spectral_radius_transfer_zero`).
* (3) **Symbol rename to `T_OS`** (rather than `T`) to avoid
  ambiguity at the term level with any future `T : transferOp`
  symbol from the trivial-witness module, and to make the
  OS-reconstruction provenance explicit.
* (4) **Namespace widen** to `TheoremaAureum.Towers.YM.LatticeGauge`.
* (5) **`open scoped ComplexOrder`** added so the bare
  `0 ≤ z` for `z : ℂ` in `T_OS_positive` elaborates against
  the `PartialOrder ℂ` instance (scoped in `ComplexOrder` in
  mathlib v4.12.0).

## Tripwire (mass-gap)
* The `T_OS := 0` stand-in makes `T_OS_positive` and
  `T_OS_selfAdjoint` *vacuous* (they hold for any zero
  operator) — the real content (`T = ∫ K dμ` with `K` the
  Wilson kernel, RP-based positivity, time-reflection-based
  self-adjointness) is the real bottleneck on Wall 531 → 534+.
* Batch 174.3 makes this tripwire explicit via
  `mass_gap_dirac : mass_gap d L β = 0` (the Dirac stand-in
  gives mass gap exactly zero, NOT positive — the genuine
  mass gap requires `0 < ‖T‖ < 1`, which requires a non-zero
  T, which requires the real Wilson kernel).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proofs are
`rw [zero_apply, inner_zero_right]` + `le_refl` and
`IsSelfAdjoint.zero _`.
================================================================
-/

import Towers.YM.HilbertSpace
import Towers.YM.LatticeAction
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Data.Complex.Order

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory
open scoped ComplexOrder

/-- **`T_OS`** — OS transfer operator on `H_OS`, stand-in form.
    Defined as the zero continuous linear endomorphism (under
    the Dirac haar stand-in, the only honestly-buildable
    operator that respects the singleton support without
    inventing a kernel). The real Wilson transfer operator
    requires real Haar + the Wilson link kernel; deferred. -/
noncomputable def T_OS (d L : ℕ) [NeZero L] (β : ℝ) :
    H_OS d L β →L[ℂ] H_OS d L β := 0

/-- **Brick (`T_OS_positive`).** OS-positivity of the transfer
    operator: `0 ≤ ⟪ψ, T_OS ψ⟫_ℂ` for every `ψ`. Under the
    stand-in, `T_OS ψ = 0` so the inner product is `0`,
    trivially `≤` itself. Load-bearing predicate name from
    OS-1; under real Haar this becomes the *consequence* of
    reflection positivity. -/
theorem T_OS_positive (d L : ℕ) [NeZero L] (β : ℝ) :
    ∀ ψ : H_OS d L β, 0 ≤ ⟪ψ, T_OS d L β ψ⟫_ℂ := by
  intro ψ
  show 0 ≤ ⟪ψ, (0 : H_OS d L β →L[ℂ] H_OS d L β) ψ⟫_ℂ
  rw [ContinuousLinearMap.zero_apply, inner_zero_right]

/-- **Brick (`T_OS_selfAdjoint`).** `IsSelfAdjoint (T_OS d L β)`.
    Under the stand-in, `T_OS = 0` and the `Star` instance on
    `H_OS →L[ℂ] H_OS` (via `ContinuousLinearMap.adjoint` from
    `Mathlib.Analysis.InnerProductSpace.Adjoint`) gives
    `star 0 = 0` via `IsSelfAdjoint.zero _`. Load-bearing
    predicate name from OS-2; under real Haar this becomes the
    consequence of time-reflection invariance of the Wilson
    action. -/
theorem T_OS_selfAdjoint (d L : ℕ) [NeZero L] (β : ℝ) :
    IsSelfAdjoint (T_OS d L β) := by
  show IsSelfAdjoint (0 : H_OS d L β →L[ℂ] H_OS d L β)
  exact IsSelfAdjoint.zero _

end TheoremaAureum.Towers.YM.LatticeGauge
