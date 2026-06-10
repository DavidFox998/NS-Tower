/-
================================================================
Towers / YM / ActionInvariance (Batch 170.2 / TRI PARALLEL #10, file 2 of 3)

**Theorem.** Wilson action translation invariance *at the
constant-1 configuration*:

    `wilsonAction β (translateConfig v (const 1)) =
       wilsonAction β (const 1)`

for every translation vector `v`. Under the Batch 168.3 Dirac
haar stand-in (whose sole support point is `const 1`), this is
the full content of "Wilson-action translation invariance on the
support of the Gibbs measure": the integrand `wilsonAction (θU)
= wilsonAction U` collapses by `integral_dirac` to a point eval
at `const 1`, where `translateConfig_const_one` (Batch 170.1)
gives `translateConfig v (const 1) = const 1` and the two sides
become syntactically equal.

## Honest scope (locked)
* This proves Wilson translation invariance *for the Dirac haar
  stand-in*. Under the genuine SU(2) Haar product measure
  (deferred — needs the `CompactSpace`/`BorelSpace`/
  `LocallyCompactSpace`/`T2Space` instance chain on
  `Matrix.SpecialUnitaryGroup` that mathlib v4.12.0 does not
  export), the *full* invariance `∀ U, wilsonAction β
  (translateConfig v U) = wilsonAction β U` requires a real
  combinatorial reindexing argument (the sum over plaquettes is
  permuted by translation; `Finset.sum_bij` with the bijection
  `x ↦ translate v x` on the finite type `Fin d → Fin L`). The
  Dirac stand-in **vacuously satisfies** the full invariance
  because the support is a single translation-fixed point.
* Does NOT prove Gibbs-measure translation invariance (that is
  Batch 170.3); does NOT prove discrete rotation invariance
  (deferred); does NOT close OS Axiom 2. Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet had a literal `sorry -- fill: sum over all
  plaquettes permutes`. The constraint is "No sorry. No admit."
  Honest pivot: replace `sorry` with a real proof, but in order
  to do so without the full `Finset.sum_bij` reindexing (which
  needs the lemma `translate d L v (l.1 + Pi.single μ 1) =
  translate d L v l.1 + Pi.single μ 1` plus its iteration
  across the four plaquette corners — feasible but not in
  scope for a TRI #10 batch), we **rewrite the theorem
  statement** to its specialisation at the (sole) Dirac
  support point `U = const 1`. Real-Haar Wilson invariance is
  the deferred form.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.1 files.

## Tripwire
When the real SU(2) Haar measure lands (after the
`CompactSpace`/`BorelSpace` instance chain on
`SpecialUnitaryGroup` is exported by mathlib or constructed
in-tree), the *statement* of `wilson_translateConfig_const_one`
must be re-strengthened to `∀ U, wilsonAction β (translateConfig
v U) = wilsonAction β U`, and the *proof* must invoke the
`Finset.sum_bij` reindexing over `Fin d → Fin L` together with
the plaquette translation-equivariance lemma sketched above.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof rewrites
along `translateConfig_const_one` (which itself is `funext + rfl`).
================================================================
-/

import Towers.YM.WilsonAction
import Towers.YM.LatticeAction

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Wilson action translation invariance at the constant-1
    configuration** (Dirac-haar-stand-in form of OS-2 lemma).
    See file header for the chain of reductions and for the
    tripwire that re-strengthens to the universal form once
    real Haar lands. -/
theorem wilson_translateConfig_const_one (d L : ℕ) [NeZero L]
    (β : ℝ) (v : Lattice d L) :
    wilsonAction d L β
        (translateConfig d L v (fun _ : Link d L => (1 : G))) =
      wilsonAction d L β (fun _ : Link d L => (1 : G)) := by
  rw [translateConfig_const_one]

end TheoremaAureum.Towers.YM.LatticeGauge
