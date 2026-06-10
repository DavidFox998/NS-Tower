/-
================================================================
Towers / YM / LocalityOS3 (Batch 172.3 / TRI PARALLEL #12, file 3 of 3)

**Theorem.** OS-3 (Locality) for the Gibbs measure:
spacelike-separated (disjoint-support) observables commute in
expectation —

    `Disjoint (support F) (support G) →
      ∫ U, F U * G U ∂gibbsMeasure β = ∫ U, G U * F U ∂gibbsMeasure β`

Under the ℂ-valued observable convention (Batch 172.2's
ambient setting), the integrand equality `F U * G U = G U * F U`
holds *pointwise* (ℂ is commutative), so the integral equality
follows by `simp_rw` along `disjoint_commute`. This is the full
Dirac-stand-in content of OS-3.

## Honest scope (locked)
* This proves OS-3 for ℂ-valued observables under the Dirac
  haar stand-in. Under the genuine operator-valued algebra of
  observables on the OS Hilbert space (real Haar + reflection
  positivity, Batches 168.3 / 169.3 deferred), OS-3 becomes
  `[Â, B̂] = 0` on `H_OS` for spacelike-separated bounded
  operators `Â`, `B̂` — a *real* statement that requires trace
  cyclicity plus the spatial-locality structure of the lattice
  plaquette action. Tripwire in `DisjointCommute.lean` header.
* With this batch, **3 of 4 OS axioms are closed under the
  Dirac stand-in**: OS-1 (reflection positivity, Batch 169.3),
  OS-2 (Euclidean invariance, Batches 170.3 + 171.3), OS-3
  (locality, this batch). OS-4 (clustering) remains open.
* Does NOT prove OS-4 (clustering); does NOT prove mass gap;
  does NOT prove the continuum limit. Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet preserved verbatim modulo namespace widening to
  `TheoremaAureum.Towers.YM.LatticeGauge` (to match Batches
  168.x / 169.x / 170.x / 171.x / 172.1 / 172.2).

## Tripwire
When the operator-valued OS-3 lands (after real Haar + the
OS-Hilbert-space construction), the statement of
`os3_locality` must be re-derived for operator products
(not pointwise ℂ-products), and `simp_rw [disjoint_commute]`
must be replaced by the operator-trace-cyclicity argument
sketched in `DisjointCommute.lean`'s tripwire.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — `simp_rw` along an
equation provable by `ring` over ℂ uses only the trio.
================================================================
-/

import Towers.YM.DisjointCommute
import Towers.YM.GibbsMeasure

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **OS-3 (Locality) for the Gibbs measure** — disjoint-support
    ℂ-valued observables commute in expectation. See file
    header for the chain of reductions and for the tripwire to
    the operator-valued real OS-3. -/
theorem os3_locality (d L : ℕ) [NeZero L] (β : ℝ)
    (F G : GaugeConfig d L → ℂ)
    (h : Disjoint (support d L F) (support d L G)) :
    ∫ U, F U * G U ∂gibbsMeasure d L β =
      ∫ U, G U * F U ∂gibbsMeasure d L β := by
  simp_rw [disjoint_commute d L F G h]

end TheoremaAureum.Towers.YM.LatticeGauge
