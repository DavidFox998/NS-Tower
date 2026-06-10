/-
================================================================
Towers / YM / RotationInvariance (Batch 171.2 / TRI PARALLEL #11, file 2 of 3)

**Theorem.** Wilson action π/2-rotation invariance *at the
constant-1 configuration*:

    `wilsonAction β (rotateConfig μ ν (const 1)) =
       wilsonAction β (const 1)`

for every pair of axes `μ ν : Fin d`. Under the Batch 168.3
Dirac haar stand-in (whose sole support point is `const 1`),
this is the full content of "Wilson-action rotation invariance
on the support of the Gibbs measure".

## Honest scope (locked)
* This proves Wilson rotation invariance *for the Dirac haar
  stand-in*. Under the genuine SU(2) Haar product measure
  (deferred — same instance-chain obstruction as Batches 168.3
  / 170.2), the *full* invariance `∀ U, wilsonAction β
  (rotateConfig μ ν U) = wilsonAction β U` requires a real
  combinatorial reindexing argument plus the plaquette rotation
  algebra — every plaquette in the μ–ν plane gets mapped to
  another plaquette in the (rotated) μ–ν plane with the
  matrix-trace `(P)_re` preserved (since `Re(tr A) = Re(tr A^†)`
  for `A ∈ SU(2)`, and a π/2 rotation swaps `(μ, ν)`-corners
  with `(ν, μ)`-corners which differ by the dagger).
* Does NOT prove Gibbs-measure rotation invariance (that is
  Batch 171.3); does NOT close OS Axiom 2 on its own.
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet attempted `simp [wilsonAction, rotateConfig,
  rotateLink, rotate90]`. That cannot close the goal — `simp`
  would have to evaluate the triple sum `∑ x, ∑ μ, ∑ ν, if h
  then …` over the finite type `Fin d → Fin L`, recognise the
  permutation symmetry on the index set, and rewrite the
  Re(trace) terms. None of those steps are `simp` lemmas in
  v4.12.0. Honest pivot: rewrite along `rotateConfig_const_one`
  (which collapses the LHS argument to `fun _ => 1` syntactically),
  reducing the equality to `rfl`. Real `∀ U` form is the
  deferred case.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.x / 171.1 files.
* (3) The genuine `LatticeGauge.wilsonAction` (Task #248 Step 2)
  takes only the configuration `U` (its `d L` are implicit and it
  carries NO coupling parameter `β`). The earlier vacuous stand-in
  took `d L β` explicitly; those arguments are dropped from both
  call sites here, and the now-unused `β` binder is removed from
  the theorem signature. The conceptual β discussion above is
  unchanged — it describes the deferred real-Haar case.

## Tripwire
When the real SU(2) Haar measure lands, the *statement* of
`wilson_rotateConfig_const_one` must be re-strengthened to
`∀ U, wilsonAction β (rotateConfig μ ν U) = wilsonAction β U`,
and the *proof* must invoke a `Finset.sum_bij` reindexing
across the four plaquette corners plus the
`Re(tr P_rotated) = Re(tr P_original)` lemma for SU(2)
plaquettes.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof rewrites
along `rotateConfig_const_one` (which is `funext + rfl`).
================================================================
-/

import Towers.YM.WilsonAction
import Towers.YM.LatticeRotation

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Wilson action π/2-rotation invariance at the constant-1
    configuration** (Dirac-haar-stand-in form of OS-2 rotation
    lemma). See file header for the chain of reductions and for
    the tripwire that re-strengthens to the universal form once
    real Haar lands. -/
theorem wilson_rotateConfig_const_one (d L : ℕ) [NeZero L]
    (μ ν : Fin d) :
    wilsonAction (rotateConfig d L μ ν (fun _ : Link d L => (1 : G))) =
      wilsonAction (fun _ : Link d L => (1 : G)) := by
  rw [rotateConfig_const_one]

end TheoremaAureum.Towers.YM.LatticeGauge
