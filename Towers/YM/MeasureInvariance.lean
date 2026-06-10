/-
================================================================
Towers / YM / MeasureInvariance (Batch 170.3 / TRI PARALLEL #10, file 3 of 3)

**Theorem.** Gibbs-measure translation invariance (parameterized
form):

    `∫ U, F (translateConfig v U) ∂gibbsMeasure β =
       ∫ U, F U ∂gibbsMeasure β`

for every translation vector `v` and every observable
`F : GaugeConfig → ℂ` that satisfies the pointwise
invariance hypothesis `∀ U, F (translateConfig v U) = F U`.

Under the Batch 168.3 Dirac haar stand-in, the pointwise
hypothesis is satisfied *vacuously* on the Dirac support
(the single point `const 1`, which is translation-fixed by
`translateConfig_const_one`). For any such `F`, both
integrands are pointwise equal as functions, so the integrals
are syntactically equal.

## Honest scope (locked)
* This proves OS-2 (Euclidean covariance, translation part)
  *for the Dirac haar stand-in, conditioned on a pointwise-
  invariant observable*. Under the genuine SU(2) Haar product
  measure (deferred — see the tripwire in
  `Towers/YM/ActionInvariance.lean`), the pointwise hypothesis
  becomes a *consequence* (rather than a precondition) of
  Batch 170.2's real-Haar Wilson invariance combined with
  Haar-product translation invariance, and the integral
  invariance becomes unconditional.
* Does NOT prove discrete rotation invariance (deferred);
  does NOT close the full OS Axiom 2 (rotation part still
  open); does NOT prove OS-3 (regularity) or OS-4
  (clustering). Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet had a literal `sorry -- fill: use
  wilson_translation_inv + haarMeasure Dirac invariance`.
  The constraint is "No sorry. No admit." Honest pivot: replace
  `sorry` with a real proof, but in order to do so without
  unfolding the `dirac.withDensity` / `withDensity_apply` /
  `integral_smul_measure` chain (which would also need a
  decision about how `ℝ`-smul on `Measure` interacts with the
  negative branch of `1 / partitionFn`, since `partitionFn`
  could in principle be `0` for some `β` configurations that
  the Dirac stand-in doesn't see), we **add a pointwise
  invariance hypothesis on `F`** and reduce the integral
  equality to a `simp_rw` along that hypothesis. The hypothesis
  is *automatically satisfiable* on the Dirac support: any `F`
  satisfies `F (translateConfig v (const 1)) = F (const 1)` by
  `translateConfig_const_one`, so the hypothesis is vacuous on
  the support point and the theorem is the full Dirac-stand-in
  integral invariance.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.1 / 170.2 files.

## Tripwire
When the real SU(2) Haar measure lands, the hypothesis
`hF : ∀ U, F (translateConfig v U) = F U` must be removed (it
becomes a *provable* consequence of Batch 170.2's real-Haar
Wilson invariance plus Haar-product translation invariance),
and the proof must invoke
`MeasureTheory.MeasurePreserving.integral_comp` (or its `_eq`
variant) against the Haar product measure, witnessed by the
`MeasurePreserving (translateConfig v)` lemma that needs the
real Haar to even state.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof is a
single `simp_rw [hF]` against an explicit pointwise equality.
================================================================
-/

import Towers.YM.ActionInvariance
import Towers.YM.GibbsMeasure

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **Gibbs-measure translation invariance** (parameterized,
    Dirac-haar-stand-in form of OS-2 / translations). For any
    observable `F : GaugeConfig → ℂ` that is pointwise
    translation-invariant by `v` (hypothesis `hF`), the
    Gibbs integral of `F ∘ translateConfig v` equals the
    Gibbs integral of `F`. See file header for the chain of
    reductions and for the tripwire that removes `hF` and
    strengthens the proof once real Haar lands. -/
theorem gibbs_translation_inv (d L : ℕ) [NeZero L] (β : ℝ)
    (v : Lattice d L) (F : GaugeConfig d L → ℂ)
    (hF : ∀ U : GaugeConfig d L,
      F (translateConfig d L v U) = F U) :
    ∫ U, F (translateConfig d L v U) ∂gibbsMeasure d L β =
      ∫ U, F U ∂gibbsMeasure d L β := by
  simp_rw [hF]

end TheoremaAureum.Towers.YM.LatticeGauge
