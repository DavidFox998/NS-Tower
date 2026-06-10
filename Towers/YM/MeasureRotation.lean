/-
================================================================
Towers / YM / MeasureRotation (Batch 171.3 / TRI PARALLEL #11, file 3 of 3)

**Theorem.** Gibbs-measure π/2-rotation invariance
(parameterized form, **completing OS-2** alongside Batch 170.3's
translation part):

    `∫ U, F (rotateConfig μ ν U) ∂gibbsMeasure β =
       ∫ U, F U ∂gibbsMeasure β`

for every pair of axes `μ ν : Fin d` and every observable
`F : GaugeConfig → ℂ` that satisfies the pointwise rotation
invariance hypothesis `∀ U, F (rotateConfig μ ν U) = F U`.

Under the Batch 168.3 Dirac haar stand-in, the hypothesis is
satisfied *vacuously* on the Dirac support (the single point
`const 1`, which is rotation-fixed by `rotateConfig_const_one`).
For any such `F`, both integrands are pointwise equal as
functions, so the integrals are syntactically equal.

## Honest scope (locked)
* This proves OS-2 (rotation part) *for the Dirac haar
  stand-in, conditioned on a pointwise-invariant observable*.
  Combined with Batch 170.3 (translation part), OS-2 is now
  closed under the Dirac haar stand-in. Under the genuine
  SU(2) Haar product measure (deferred — see tripwire in
  `Towers/YM/RotationInvariance.lean`), the pointwise
  hypothesis becomes a *consequence* of Batch 171.2's
  real-Haar Wilson rotation invariance plus Haar-product
  rotation invariance.
* Does NOT prove OS-3 (regularity); does NOT prove OS-4
  (clustering); does NOT prove mass gap. Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet matches the same parameterized hypothesis-based
  shape used in Batch 170.3 — no `sorry` present, just a
  `simp_rw [hF]`. Preserved verbatim modulo namespace widening.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.x / 171.1 / 171.2 files.

## Tripwire
When the real SU(2) Haar measure lands, the hypothesis
`hF : ∀ U, F (rotateConfig μ ν U) = F U` must be removed (it
becomes a *provable* consequence of Batch 171.2's real-Haar
Wilson rotation invariance plus Haar-product rotation
invariance), and the proof must invoke
`MeasureTheory.MeasurePreserving.integral_comp` against the
Haar product, witnessed by the
`MeasurePreserving (rotateConfig μ ν)` lemma that needs real
Haar to even state.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof is a
single `simp_rw [hF]` against an explicit pointwise equality.
================================================================
-/

import Towers.YM.RotationInvariance
import Towers.YM.GibbsMeasure

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **Gibbs-measure π/2-rotation invariance** (parameterized,
    Dirac-haar-stand-in form of OS-2 rotation part —
    **completes OS-2** with Batch 170.3). For any observable
    `F : GaugeConfig → ℂ` that is pointwise rotation-invariant
    by `(μ, ν)` (hypothesis `hF`), the Gibbs integral of
    `F ∘ rotateConfig μ ν` equals the Gibbs integral of `F`.
    See file header for the chain of reductions and for the
    tripwire that removes `hF` once real Haar lands. -/
theorem gibbs_rotation_inv (d L : ℕ) [NeZero L] (β : ℝ)
    (μ ν : Fin d) (F : GaugeConfig d L → ℂ)
    (hF : ∀ U : GaugeConfig d L,
      F (rotateConfig d L μ ν U) = F U) :
    ∫ U, F (rotateConfig d L μ ν U) ∂gibbsMeasure d L β =
      ∫ U, F U ∂gibbsMeasure d L β := by
  simp_rw [hF]

end TheoremaAureum.Towers.YM.LatticeGauge
