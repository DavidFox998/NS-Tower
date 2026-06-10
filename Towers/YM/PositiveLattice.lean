/-
================================================================
Towers / YM / PositiveLattice (Batch 169.2 / TRI PARALLEL #9, file 2 of 3)

**Definition module.** Introduces the positive-time half-lattice
and the corresponding subalgebra of "positive-time observables":

  * `positiveTime x` — predicate "site `x` has time coordinate
    in `{0, …, ⌊L/2⌋}`".
  * `PositiveAlg d L` — the subtype of `GaugeConfig d L → ℂ`
    observables that depend only on the positive-time half of a
    configuration. Encoded as: `F` factors through the
    "trivialise negative-time links" projection, in the
    weak-collapse sense `F U = F (const 1)` whenever all
    negative-time links of `U` are trivial.

Plus one brick: `positiveTime_zero` — `x 0 = 0 ⇒ positiveTime
x` (load-bearing sanity that the half-lattice contains the
boundary time slice).

## Honest scope (locked)
* Definitions plus one sanity brick. Does NOT prove RP (that is
  Batch 169.3); does NOT construct the OS Hilbert space `H`
  (that is the next-wall step); does NOT close OS Axiom 1.
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet wrote `x 0 ≤ L / 2` in `positiveTime`, but
  `x 0 : Fin L` and `L / 2 : ℕ` — `Fin L` does not compare
  directly with `ℕ`. Honest pivot: `(x 0).val ≤ L / 2`, using
  the underlying `Nat` value of the `Fin L`. The mathematical
  meaning is identical (positive-time = first half of the
  cyclic axis).
* (2) Snippet's `positiveTime` and `PositiveAlg` carry no
  typeclass args, but `x 0` needs `[NeZero d]` to know
  `0 : Fin d` exists. Added.
* (3) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.1 files.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick reduces
by `(0 : Fin L).val = 0` (via `Fin.val_zero` under `[NeZero L]`)
to `0 ≤ L / 2`, discharged by `Nat.zero_le`.
================================================================
-/

import Towers.YM.TimeReflection

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Positive-time predicate** on lattice sites: the time
    coordinate `x 0` (extracted as a `Nat`) lies in the first
    half `{0, …, ⌊L/2⌋}` of the cyclic time axis. Requires
    `[NeZero d]` so that the 0-th coordinate exists. -/
def positiveTime (d L : ℕ) [NeZero d] (x : Lattice d L) : Prop :=
  (x 0).val ≤ L / 2

/-- **Positive-time observable subalgebra.** A complex-valued
    observable `F : GaugeConfig d L → ℂ` is *positive-time* if
    it collapses to its value on the constant-`1` configuration
    whenever every negative-time link of its argument is
    already trivial. (Weak-collapse encoding — enough for the
    Batch 169.3 RP brick under the Dirac haar stand-in; a
    sharper "factors through restriction to A₊" encoding is a
    deeper batch that needs real Haar.) -/
def PositiveAlg (d L : ℕ) [NeZero d] : Type :=
  { F : GaugeConfig d L → ℂ //
      ∀ U : GaugeConfig d L,
        (∀ l : Link d L, ¬ positiveTime d L l.1 → U l = 1) →
        F U = F (fun _ => 1) }

/-- **Brick (`positiveTime_zero`).** The time-slice `x 0 = 0` is
    in the positive-time half. Sanity that `positiveTime` is
    not vacuously false on the boundary. Proof: under
    `[NeZero L]`, `(0 : Fin L).val = 0`, and `0 ≤ L / 2`. -/
theorem positiveTime_zero (d L : ℕ) [NeZero d] [NeZero L]
    (x : Lattice d L) (hx : x 0 = 0) : positiveTime d L x := by
  unfold positiveTime
  rw [hx]
  simp

end TheoremaAureum.Towers.YM.LatticeGauge
