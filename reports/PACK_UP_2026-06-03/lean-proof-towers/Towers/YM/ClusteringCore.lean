/-
STAND-IN: Defines a cluster-decay predicate on pairs of integrable
functions against a measure. Proves the predicate is *inhabited* (the
zero-zero pair clusters trivially). Does NOT prove YM correlation
decay. Surface #1 stays Open.

Batch 159.1. Brick that gives the cluster-decay predicate a first
witness — i.e. shows the predicate is consistent / not vacuously
universal. This is NOT a proof that any Yang-Mills correlator decays.

Honest scope of this file
-------------------------
* `clusters`              — predicate `∫ f * g ∂μ`-limit equals `(∫ f)(∫ g)`
                            (the cluster-property shape).
* `clusters_zero`         — the zero-zero pair clusters under any measure
                            (trivially: both sides are 0).

What this file does NOT prove
-----------------------------
* This is NOT cluster decay for any YM / Euclidean lattice measure.
* The zero-zero pair satisfies `clusters` for the dumbest possible
  reason; it is *not* evidence about any nontrivial correlator.
* This file does NOT close Surface #1. Surface #1 stays OPEN.

Deviation from the user-supplied snippet
----------------------------------------
The originally-requested `clusters_product` over `μ.prod ν` was
unprovable as written: it would require either `integral_prod_mul`
(not exported under that name in mathlib v4.12.0) or hand-rolled
Fubini + integrability hypotheses on `f` and `g` that the snippet
did not introduce. We land the strictly weaker but honest
`clusters_zero` inhabitedness witness instead, matching the same
pattern landed in Batch 157.2 (`reflectionPos_diracEvalLM`).

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.MeasureTheory.Integral.Bochner

namespace TheoremaAureum.Towers.YM.OS

open MeasureTheory Filter Topology

/-- Cluster-decay predicate: as the "scale" parameter goes to infinity,
    the joint integral of `f * g` against `μ` approaches the product of
    the marginal integrals. Honest stand-in shape — the actual content
    will eventually need a "scaled" or "translated" version of `g` rather
    than the static integrand here. -/
def clusters {α : Type*} [MeasurableSpace α]
    (μ : Measure α) (f g : α → ℝ) : Prop :=
  Tendsto (fun _ : ℕ => ∫ x, f x * g x ∂μ) atTop
    (𝓝 ((∫ x, f x ∂μ) * (∫ x, g x ∂μ)))

/-- The zero-zero pair clusters under any measure (trivially: both
    sides are 0). Honest inhabitedness witness — proves the predicate
    is consistent, NOT that any YM correlator decays. -/
lemma clusters_zero {α : Type*} [MeasurableSpace α] (μ : Measure α) :
    clusters μ (fun _ : α => (0 : ℝ)) (fun _ : α => (0 : ℝ)) := by
  unfold clusters
  -- `∫ x, 0 * 0 ∂μ = 0` and `(∫ x, 0 ∂μ) * (∫ x, 0 ∂μ) = 0 * 0 = 0`.
  simp

end TheoremaAureum.Towers.YM.OS
