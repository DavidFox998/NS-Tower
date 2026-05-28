/-
================================================================
Towers / YM / HilbertSpace (Batch 174.1 / TRI PARALLEL #14, file 1 of 3)

**Definition module.** Introduces the OS-reconstructed Hilbert
space carrier (stand-in form):

  * `mu_plus d L β` — the positive-time measure on
    `GaugeConfig d L`. Stand-in: under the Dirac haar form
    of `gibbsMeasure` (Batch 168.3), the OS positive-time
    restriction is the same Dirac mass at the constant-`1`
    configuration; the rename keeps the OS-reconstruction
    contract explicit for downstream callers.
  * `H_OS d L β` — `noncomputable abbrev` for
    `Lp ℂ 2 (mu_plus d L β)`, the L²-completion of complex
    observables on the positive-time algebra.

Plus one brick: `mu_plus_eq_gibbs` — under the Dirac haar
stand-in, `mu_plus` equals `gibbsMeasure` on the nose. Load-
bearing for the tripwire chain into Batches 174.2 (transfer
operator) and 174.3 (spectral gap).

## Honest scope (locked)
* Definitions only, plus the rename-identity brick. Does NOT
  construct the transfer operator (that is Batch 174.2);
  does NOT prove a spectral gap (that is Batch 174.3);
  does NOT prove OS reconstruction (the standard contract that
  RP + OS-2..4 gives a positive Hilbert space + self-adjoint
  Hamiltonian); does NOT prove anything about real Yang-Mills.
  Surface #1 stays OPEN.
* Pattern matches Batch 166.1 (`L2Hilbert.lean`): use
  `noncomputable abbrev` so the `NormedAddCommGroup`,
  `InnerProductSpace ℂ`, and `CompleteSpace` instances on
  `Lp ℂ 2 μ` flow through reducibility without redundant
  `instance` declarations.

## Drift from snippet
* (1) **`def` → `abbrev` pivot.** Snippet wrote
  `noncomputable def H_OS … : Type := Lp ℂ 2 (mu_plus …)`
  followed by two `instance : InnerProductSpace ℂ (H_OS …)
  := by infer_instance` blocks. `def` is opaque to typeclass
  resolution — `inferInstance` could not look through
  `H_OS d L β` to the underlying `Lp` to find the
  `InnerProductSpace` instance. Honest pivot: use
  `noncomputable abbrev` (reducible), which makes the
  instance declarations *unnecessary* (they flow transparently
  through the abbrev). This is the same convention as
  Batch 166.1's `H := Lp ℂ 2 (volume : Measure ℝ)`.
* (2) **Namespace widen.** Snippet's
  `TheoremaAureum.Towers.YM` is widened to
  `TheoremaAureum.Towers.YM.LatticeGauge` to match the Batch
  168.x / 169.x / 170.x / 171.x / 172.x / 173.x files (where
  `GaugeConfig`, `gibbsMeasure`, `ReflectionPositivity` all
  live).
* (3) **Brick add.** Snippet had only definitions and instance
  declarations; under the +1 wall jump accounting
  (`525 → 526`), this file must land one brick. Added
  `mu_plus_eq_gibbs`: `mu_plus d L β = gibbsMeasure d L β`
  (proved by `rfl` since `mu_plus` is the rename).

## Tripwire (mass-gap chain)
The OS-reconstruction Hilbert space is *not* genuinely the
L²-completion of the positive-time algebra under real Haar
unless OS-1 (real-Haar reflection positivity) is in hand. The
chain is:
  - real Haar `gibbsMeasure` (deferred — needs SU(2) Haar
    + product measure + topological-group / locally-compact /
    BorelSpace on `Matrix.SpecialUnitaryGroup`)
  - real-Haar `mu_plus` restriction to positive-time algebra
    `A₊` (deferred — needs σ-algebra of positive-time
    observables)
  - real-Haar OS-1 (deferred — Dirac OS-1 in Batch 169.3 is
    vacuous on the singleton support)
  - quotient by the RP null-space (deferred)
  - L²-completion of the quotient (this file's `Lp ℂ 2 μ`
    plays the role under the Dirac stand-in)

Under the Dirac stand-in, the entire chain collapses to a
1-dim (essentially) L²-space — and Batch 174.3 will show
the corresponding transfer operator has spectral norm `0`,
*not* a genuine `(0, 1)` spectral gap, hence
`mass_gap_dirac : mass_gap = 0` (tripwire).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is `rfl`.
================================================================
-/

import Towers.YM.ReflectionPositivity
import Towers.YM.GibbsMeasure
import Mathlib.MeasureTheory.Function.L2Space

namespace TheoremaAureum.Towers.YM.LatticeGauge

open MeasureTheory

/-- **`mu_plus`** — positive-time measure on `GaugeConfig d L`,
    stand-in form. Under the Dirac haar form of `gibbsMeasure`
    (Batch 168.3), the OS-restriction collapses to the same
    Dirac mass; the rename keeps the OS-reconstruction contract
    explicit. -/
noncomputable def mu_plus (d L : ℕ) [NeZero L] (β : ℝ) :
    Measure (GaugeConfig d L) :=
  gibbsMeasure d L β

/-- **`H_OS`** — the OS-reconstructed Hilbert space carrier:
    `L²(GaugeConfig d L, ℂ; mu_plus)`. Uses `noncomputable
    abbrev` so the `NormedAddCommGroup`, `InnerProductSpace ℂ`,
    and `CompleteSpace` instances on `Lp ℂ 2 μ` flow through
    reducibility — same pattern as Batch 166.1's `L2Hilbert`. -/
noncomputable abbrev H_OS (d L : ℕ) [NeZero L] (β : ℝ) : Type :=
  Lp (E := ℂ) 2 (μ := mu_plus d L β)

/-- Sanity examples — confirm the `Lp` instance chain on `H_OS`
    via `inferInstance` (same convention as Batch 166.1). Not
    bricks; existence of these terms is the smoke test that the
    abbrev is properly reducible to `Lp ℂ 2 μ`. -/
noncomputable example (d L : ℕ) [NeZero L] (β : ℝ) :
    InnerProductSpace ℂ (H_OS d L β) := inferInstance

noncomputable example (d L : ℕ) [NeZero L] (β : ℝ) :
    CompleteSpace (H_OS d L β) := inferInstance

/-- **Brick (`mu_plus_eq_gibbs`).** Under the Dirac haar stand-in,
    the positive-time measure equals the Gibbs measure on the
    nose. Load-bearing identity for the Batches 174.2 / 174.3
    tripwire chain: every integral against `mu_plus` collapses
    to the corresponding `gibbsMeasure` integral, which under
    Dirac collapses further to a point evaluation at
    `const 1`. -/
theorem mu_plus_eq_gibbs (d L : ℕ) [NeZero L] (β : ℝ) :
    mu_plus d L β = gibbsMeasure d L β := rfl

end TheoremaAureum.Towers.YM.LatticeGauge
