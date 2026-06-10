/-
================================================================
Towers / YM / DisjointCommute (Batch 172.2 / TRI PARALLEL #12, file 2 of 3)

**Theorem.** ℂ-valued observables on `GaugeConfig` with disjoint
support commute pointwise:

    `Disjoint (support F) (support G) → ∀ U, F U * G U = G U * F U`

Under the ℂ-valued observable convention used throughout this
tower (ℂ-valued path-integral observables on the Dirac haar
stand-in, not operator-valued algebra-of-observables), the
conclusion is *unconditional* — ℂ is commutative — so the
disjointness hypothesis is logically unused. This is the
honest content of "OS-3 locality at the observable level under
the Dirac stand-in".

## Honest scope (locked)
* This proves disjoint-support commutation for ℂ-valued
  observables. Under the **operator-valued** algebra of
  observables that the *real* OS-3 axiom requires (where
  `F` and `G` are bounded operators on the OS Hilbert space
  built from real Haar + reflection positivity, and
  multiplication is operator composition which is *not*
  commutative in general), the disjointness hypothesis becomes
  load-bearing — it gets discharged by trace cyclicity for the
  Haar measure together with the spatial-locality structure of
  the lattice plaquette action. That is the deferred form.
* Does NOT prove OS-3 (that is Batch 172.3); does NOT prove
  OS-4 (clustering); does NOT prove mass gap.
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet's proof `intro U; ring` is preserved. The
  `h : Disjoint …` hypothesis is unused under the ℂ-valued
  observable convention; the universal `ring` closure is honest.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.x / 171.x / 172.1 files.

## Tripwire
When the algebra of observables is upgraded from `GaugeConfig
→ ℂ` to operator-valued (Loop observables, Wilson loops as
elements of `B(H_OS)` etc.), the proof must be re-derived from
trace cyclicity / Haar invariance, and the `h : Disjoint`
hypothesis becomes load-bearing rather than vacuously satisfied
by ℂ-commutativity.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — `ring` over ℂ uses
only the trio.
================================================================
-/

import Towers.YM.Support

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Disjoint-support commutation.** ℂ-valued observables on
    `GaugeConfig` always commute pointwise (since ℂ is
    commutative); the `Disjoint` hypothesis is included to
    track the OS-3-locality data flow but is logically vacuous
    under the ℂ-valued convention. See file header for the
    tripwire to the operator-valued case. -/
theorem disjoint_commute (d L : ℕ) (F G : GaugeConfig d L → ℂ)
    (_h : Disjoint (support d L F) (support d L G)) :
    ∀ U : GaugeConfig d L, F U * G U = G U * F U := by
  intro U
  ring

end TheoremaAureum.Towers.YM.LatticeGauge
