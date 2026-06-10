/-
================================================================
Towers / YM / ClusterAxiom (Batch 173.2 / TRI PARALLEL #13, file 2 of 3)

**Definition + sufficient-condition brick.** Introduces the
OS-4 clustering predicate:

    `clustering β`  ⇔  for every pair of ℂ-valued observables
                       `F, G`, there exist `C, m : ℝ` with
                       `0 < m` such that for every translation
                       `v`,
        `‖∫ F U · (v·G)(U) dμ − (∫F dμ)·(∫G dμ)‖
              ≤ C · exp(−m · latticeDist 0 v)`

where `‖·‖` is `Complex.abs` and `μ = gibbsMeasure d L β`.

Plus one brick: `clustering_of_factor` — if for every `(F, G,
v)` the joint integral *factors exactly* into the product of
marginal integrals, then `clustering` holds with the trivial
witness `(C, m) = (0, 1)`. This is the Dirac-stand-in collapse
that Batch 173.3 will discharge.

## Honest scope (locked)
* Definitional. The `clustering_of_factor` brick is universal
  (works for *any* measure that exactly factors disjoint-support
  observables); it does NOT assert that real Wilson Gibbs
  satisfies exact factorization. Under real Haar, factorization
  is *not* exact — it only holds up to exponential corrections
  controlled by the spectral gap of the transfer operator, and
  the genuine OS-4 must witness `m = mass gap > 0` rather than
  the trivial `C = 0`. Tripwire.
* Does NOT prove OS-4 for the real Gibbs measure; does NOT
  prove the mass gap; does NOT prove `‖T‖ < 1` for the transfer
  operator. Surface #1 stays OPEN.

## Drift from snippet
* (1) **`|·|` on ℂ pivot.** Snippet wrote `|∫ … - …|` over a
  ℂ-valued integrand difference. The `|·|` notation in mathlib
  resolves through `_root_.abs`, which requires `Lattice ℂ` —
  ℂ has no linear order, so `Lattice ℂ` does NOT exist and
  `|z|` for `z : ℂ` fails to elaborate. Honest pivot: use
  `Complex.abs (...)` (the canonical `AbsoluteValue ℂ ℝ`
  applied as a function).
* (2) **Nat-to-Real coercion.** `latticeDist d L 0 v : ℕ` but
  `Real.exp` takes `ℝ`; the `-m * latticeDist d L 0 v` term
  needs the `↑` cast (Lean's elaborator inserts it
  automatically once the target type ℝ is known).
* (3) **Namespace widen** to `…YM.LatticeGauge`.
* (4) **Brick add.** Snippet had no theorem — under the +1 wall
  jump accounting (`523 → 524`), this file must land one
  brick. Added `clustering_of_factor` (the universal Dirac-
  stand-in collapse) — this is the bridge Batch 173.3 will
  apply.

## Tripwire
Real OS-4 needs `m > 0` to come from the spectral gap of the
transfer operator `T = e^{-aH}` on the OS Hilbert space. The
chain is: real Haar → OS Hilbert construction → transfer
operator → spectral gap → exponential clustering with `m =
log(1/‖T‖)`. None of these are landed. The `clustering_of_factor`
brick *cannot* be applied to real Wilson Gibbs because exact
factorization fails — its honest scope is the Dirac stand-in
only.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the proof is
`rw` + `simp` on `Complex.abs 0 = 0` and `0 * _ = 0`.
================================================================
-/

import Towers.YM.TranslateDistance
import Towers.YM.GibbsMeasure

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **OS-4 (Clustering) predicate.** For every pair of
    ℂ-valued observables `F, G`, the connected two-point
    function decays at least exponentially in the lattice
    distance, with a rate `m > 0` and prefactor `C`. -/
def clustering (d L : ℕ) [NeZero L] (β : ℝ) : Prop :=
  ∀ F G : GaugeConfig d L → ℂ,
    ∃ C m : ℝ, 0 < m ∧ ∀ v : Lattice d L,
      Complex.abs
          ((∫ U, F U * translateBy d L v G U ∂gibbsMeasure d L β) -
            (∫ U, F U ∂gibbsMeasure d L β) *
              (∫ U, G U ∂gibbsMeasure d L β))
        ≤ C * Real.exp (-m * (latticeDist d L 0 v : ℝ))

/-- **Brick (`clustering_of_factor`).** If the joint integral
    factors exactly into the product of marginal integrals for
    every `(F, G, v)`, then clustering holds with the trivial
    witness `(C, m) = (0, 1)`: the connected two-point function
    is identically zero, so any positive `m` works and the
    prefactor `C = 0` discharges the bound. -/
theorem clustering_of_factor (d L : ℕ) [NeZero L] (β : ℝ)
    (hFact : ∀ (F G : GaugeConfig d L → ℂ) (v : Lattice d L),
      ∫ U, F U * translateBy d L v G U ∂gibbsMeasure d L β =
        (∫ U, F U ∂gibbsMeasure d L β) *
          (∫ U, G U ∂gibbsMeasure d L β)) :
    clustering d L β := by
  intro F G
  refine ⟨0, 1, one_pos, ?_⟩
  intro v
  rw [hFact F G v]
  simp

end TheoremaAureum.Towers.YM.LatticeGauge
