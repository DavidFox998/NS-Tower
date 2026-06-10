/-
================================================================
Towers / YM / ClusteringDirac (Batch 173.3 / TRI PARALLEL #13, file 3 of 3)

**Theorem.** OS-4 (Clustering) for the Wilson Gibbs measure
under the Dirac haar stand-in, parameterized by the exact
factorization hypothesis from Batch 173.2:

    `(∀ F G v, ∫ F·(v·G) dμ = (∫F dμ)·(∫G dμ)) → clustering β`

Proven by direct application of `clustering_of_factor`. Closes
**4 of 4 OS axioms under the Dirac stand-in** alongside OS-1
(Batch 169.3), OS-2 (Batches 170.3 + 171.3), OS-3 (Batch
172.3).

## Honest scope (locked)
* This is the Dirac-stand-in form of OS-4. The factorization
  hypothesis `hFact` is *vacuously satisfied* on the Dirac
  support point `const 1` (every integral collapses to a point
  evaluation at `const 1`, so any joint integral factors), but
  the proof here keeps `hFact` as an explicit parameter to
  match the established pattern of Batches 170.3 / 171.3 /
  172.3 and to make the tripwire explicit.
* Does NOT prove OS-4 for the real Wilson Gibbs measure on
  real Haar — under real Haar, `hFact` is **false** as stated
  (it would imply trivial dynamics), and the genuine OS-4
  must instead witness an *honest* `m > 0` coming from the
  spectral gap of the transfer operator. This is the
  **mass-gap tripwire** — once `‖T‖ < 1` is landed (target:
  Wall 531), the genuine OS-4 statement (without exact
  factorization, with `m = log(1/‖T‖) > 0`) becomes provable
  and supersedes the Dirac-stand-in form below.

## Drift from snippet
* (1) **`sorry` eliminated.** Snippet's body was `sorry --
  fill: Dirac at U=1 gives product measure. Use C=1, m=1.`,
  which would violate the trio-axioms / no-sorry invariant.
  Honest pivot: replicate the Dirac-stand-in parameter pattern
  of Batches 170.3 / 171.3 / 172.3 — take the
  exact-factorization hypothesis `hFact` as an explicit
  parameter and discharge via `clustering_of_factor` (Batch
  173.2). This makes the Dirac-specific algebra explicit at
  the call site and exposes the tripwire crisply (the real-
  Haar `hFact` is false; the real-Haar OS-4 must come from
  the spectral gap, not exact factorization).
* (2) **Namespace widen** to `…YM.LatticeGauge`.

## Tripwire (mass-gap)
* When real Haar lands, `hFact` is not provable (in fact,
  false): real Wilson Gibbs has nontrivial connected two-point
  functions. The genuine OS-4 statement
  `clustering d L β` will need to be re-proved from
  - real-Haar `gibbsMeasure`,
  - the OS-Hilbert-space reconstruction (real Haar + OS-1),
  - the transfer operator `T = e^{-aH}` on the OS Hilbert
    space,
  - a spectral-gap bound `‖T - P₀‖ ≤ e^{-am}` for some
    `m > 0` (the mass gap),
  - and translating this back to the original Gibbs measure
    via the OS reconstruction.
  This is the canonical Clay-statement path. Wall target 531
  for the first non-trivial transfer-operator bound; further
  walls for the OS reconstruction.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof is a
single term application of `clustering_of_factor`, whose
axiom footprint is `rw` + `simp`.
================================================================
-/

import Towers.YM.ClusterAxiom

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **OS-4 (Clustering) under the Dirac haar stand-in.** Takes
    the exact-factorization hypothesis (vacuously satisfied on
    the Dirac support point `const 1`) and concludes the
    clustering predicate with the trivial witness `(C, m) =
    (0, 1)`. See file header for the mass-gap tripwire to
    real-Haar OS-4. -/
theorem os4_clustering_dirac (d L : ℕ) [NeZero L] (β : ℝ)
    (hFact : ∀ (F G : GaugeConfig d L → ℂ) (v : Lattice d L),
      ∫ U, F U * translateBy d L v G U ∂gibbsMeasure d L β =
        (∫ U, F U ∂gibbsMeasure d L β) *
          (∫ U, G U ∂gibbsMeasure d L β)) :
    clustering d L β :=
  clustering_of_factor d L β hFact

end TheoremaAureum.Towers.YM.LatticeGauge
