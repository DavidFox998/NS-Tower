/-
STAND-IN: Defines `H := L²(ℝ, ℂ)` (the complex `Lp` space at exponent 2
over Lebesgue measure) and exposes the `NormedAddCommGroup`,
`InnerProductSpace ℂ`, and `CompleteSpace` instances mathlib already
provides. Does NOT construct any Yang-Mills Hilbert space or measure.
Surface #1 stays Open. Wall 494 → 495.

Batch 166.1. First of the TRI PARALLEL #6 trio (166.1 / 166.2 / 166.3)
exiting the "(ℂ, 0)" trivial witness used by Batches 162.2 / 164.2 /
165.1: from this batch onwards, `HasMassGap`-witnessing operators live
on a genuinely infinite-dimensional Hilbert space.

Honest scope of this file
-------------------------
* `H`                   — `noncomputable abbrev`-style alias for
                          `Lp ℂ 2 (volume : Measure ℝ)`. The complex
                          `L²` space over the real line with Lebesgue
                          measure.
* Instance plumbing:    — `NormedAddCommGroup H`, `InnerProductSpace ℂ H`,
                          `CompleteSpace H`. All discharged by
                          `infer_instance` against mathlib's existing
                          `Lp` instances.

What this is NOT
----------------
* NOT a construction of any Yang-Mills Hilbert space. `L²(ℝ, ℂ)` is
  a generic infinite-dimensional complex Hilbert space, not the
  physical Yang-Mills vacuum sector / Fock space / OS-reconstructed
  Hilbert space. No YM measure, no gauge structure, no transfer
  operator.
* NOT a closure of Surface #1. Surface #1 stays OPEN.

Drift from snippet
------------------
None of substance: snippet matches the live mathlib API. The
`noncomputable def H` is required because `Lp` carries a
`Quotient`-of-`Memℒp` structure under the hood; `def` would force
a `Decidable`-style instance synthesis that does not exist.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` (the mathlib `Lp` /
`InnerProductSpace` instances are themselves classical-trio clean).
-/

import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace TheoremaAureum.Towers.YM.OS

open MeasureTheory

/-- The complex `L²` space over `ℝ` with Lebesgue measure. Honest
    stand-in for "first real Hilbert space that isn't `ℂ`"; says
    nothing about any Yang-Mills construction. -/
noncomputable abbrev H : Type := Lp (α := ℝ) ℂ 2

-- Smoke checks that mathlib's `Lp` instances synthesize on `H`.
noncomputable example : NormedAddCommGroup H := inferInstance
noncomputable example : InnerProductSpace ℂ H := inferInstance
noncomputable example : CompleteSpace H := inferInstance

end TheoremaAureum.Towers.YM.OS
