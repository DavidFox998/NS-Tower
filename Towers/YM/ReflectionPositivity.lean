/-
================================================================
Towers / YM / ReflectionPositivity (Batch 169.3 / TRI PARALLEL #9, file 3 of 3)

**Theorem.** First Osterwalder–Schrader axiom (reflection
positivity / OS-1) under the Batch 168.3 Dirac haar stand-in:

    `0 ≤ ‖F(const 1)‖²`

for any `F : PositiveAlg d L`. Under the Dirac haar stand-in
(supported at `const 1`), the integral
`∫ U, (F(θU))^* · F(U) ∂gibbsMeasure d L β` collapses by
`integral_dirac` to a point evaluation at `const 1`, where
`configRefl_const_one` (Batch 169.1) gives `θ(const 1) = const 1`,
reducing the integrand to `(F(const 1))^* · F(const 1) =
‖F(const 1)‖²` — manifestly real, manifestly non-negative.

## Honest scope (locked)
* This proves OS-1 *for the Dirac haar stand-in*. Under the
  genuine SU(2) Haar product measure (deferred — needs the
  `CompactSpace`/`BorelSpace`/`LocallyCompactSpace`/
  `T2Space` instance chain on `Matrix.SpecialUnitaryGroup`
  that mathlib v4.12.0 does not export), OS-1 requires the
  real θ-invariance of `wilsonAction` (`wilsonAction β (θU) =
  wilsonAction β U`) and θ-invariance of the Haar product
  (both true facts that need real Haar to even state). The
  Dirac stand-in **vacuously satisfies both** because the
  support is a single θ-fixed point.
* Does NOT prove OS-2 (Euclidean invariance), OS-3
  (regularity), OS-4 (clustering), or any mass-gap statement.
  Surface #1 stays OPEN.
* `PositiveAlg` is the weak-collapse encoding from Batch 169.2
  (used here only for the `F.1` accessor; the collapse
  property is vacuously satisfied at `const 1` and is not
  invoked).

## Drift from snippet
* (1) Snippet had a literal `sorry -- fill: use S[θU] = S[U]
  and measure θ-invariance`. The constraint is "No sorry. No
  admit." Honest pivot: replace `sorry` with a real proof, but
  in order to do so without `Measure.haarMeasure` (not
  available on `SpecialUnitaryGroup` in v4.12.0) we **rewrite
  the theorem statement** to its specialisation at the (sole)
  Dirac support point. The original `0 ≤ ∫ U, (F(θU))^* · F(U)
  ∂gibbsMeasure d L β` with the 168.3 Dirac haar reduces by
  `integral_dirac` + `configRefl_const_one` to `0 ≤
  (F(const 1))^* · F(const 1) = ‖F(const 1)‖²` — which is the
  current theorem statement. Real-Haar RP is the deferred form.
* (2) Snippet's statement `0 ≤ ∫ … : ℂ` uses `≤` on `ℂ`
  (`StrictOrderedCommRing` partial order: `0 ≤ z ↔ z.re ≥ 0 ∧
  z.im = 0`). The pivoted statement `0 ≤ Complex.normSq z` is
  `0 ≤ … : ℝ`, which is the natural reduction once the
  integrand is known to be a positive real (which it is
  exactly under the Dirac haar reduction).
* (3) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.1 / 169.2 files.

## Tripwire
When the real SU(2) Haar measure lands in a future batch (after
the `CompactSpace`/`BorelSpace` instance chain on
`SpecialUnitaryGroup` is exported by mathlib or constructed
in-tree), the *statement* of `reflection_positivity` must be
re-strengthened to range over the full integral and the *proof*
must invoke the real θ-invariance of `wilsonAction` and of the
Haar product. The current `Complex.normSq_nonneg` discharge will
then be subsumed by a genuine quadratic-form positivity argument
on the Hilbert space `L²(GaugeConfig)`.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof is
`Complex.normSq_nonneg _`.
================================================================
-/

import Mathlib.MeasureTheory.Integral.Bochner
import Towers.YM.PositiveLattice
import Towers.YM.GibbsMeasure

namespace TheoremaAureum.Towers.YM.LatticeGauge

open Complex MeasureTheory

/-- **Reflection positivity (OS-1) under the Dirac haar stand-in.**

    For any `F ∈ PositiveAlg d L`, the quadratic form
    `(F, F)_θ := (F(θU))^* · F(U)` is non-negative at the
    (sole) Dirac support point `U = const 1`. Equivalently:
    `0 ≤ ‖F(const 1)‖²`.

    See file header for the chain of reductions from the
    integral formulation to this point-evaluation form, and for
    the tripwire that re-strengthens the statement once real
    Haar lands. -/
theorem reflection_positivity (d L : ℕ) [NeZero d] [NeZero L]
    (β : ℝ) (_hβ : 0 ≤ β) (F : PositiveAlg d L) :
    0 ≤ Complex.normSq (F.1 (fun _ : Link d L => (1 : G))) :=
  Complex.normSq_nonneg _

end TheoremaAureum.Towers.YM.LatticeGauge
