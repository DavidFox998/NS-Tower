/-
================================================================
Towers / YM / LatticeAction (Batch 170.1 / TRI PARALLEL #10, file 1 of 3)

**Definition module.** Introduces the lattice-translation action
on sites, links, and gauge configurations:

  * `translate v x` — Pi-additive shift `x ↦ x + v` on sites
    (modular cyclic on each `Fin L` coordinate).
  * `translateLink v l` — applies `translate v` to the base site;
    direction is unchanged.
  * `translateConfig v U` — pulls a gauge configuration back along
    `translateLink (-v)` (standard "act on config = pull back by
    inverse" convention so that `translateConfig` is a left action).

Plus one brick: `translateConfig_const_one` — the constant-`1`
configuration is translation-fixed (load-bearing for Batches 170.2
and 170.3 OS-2 proofs under the Dirac haar stand-in).

## Honest scope (locked)
* Definitions only, plus the fixed-point brick. Does NOT prove
  Wilson-action translation invariance (that is Batch 170.2);
  does NOT prove Gibbs-measure translation invariance (that is
  Batch 170.3); does NOT prove discrete rotation invariance
  (deferred to a later batch). Does NOT close OS Axiom 2.
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet's `namespace TheoremaAureum.Towers.YM` is widened to
  `TheoremaAureum.Towers.YM.LatticeGauge` to match the Batch 168.x
  / 169.x files (where `Lattice`, `Link`, `GaugeConfig`, `G` live).
* (2) Snippet wrote `[NeZero L]` on `translate`, which is needed
  twice — once for `Add (Fin L)` and once for `Neg (Fin L)` in
  `translateConfig`'s `(-v)`. Preserved as-is.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is a
`funext` followed by a definitional reduction (the constant
function `fun _ => 1` is pulled back by anything to itself).
================================================================
-/

import Towers.YM.LatticeGauge

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Lattice translation** on sites: Pi-additive shift
    `x ↦ x + v`, modular on each `Fin L` coordinate. Requires
    `[NeZero L]` so that `Fin L` carries `Add`. -/
def translate (d L : ℕ) [NeZero L]
    (v : Lattice d L) (x : Lattice d L) : Lattice d L :=
  fun i => x i + v i

/-- **Lattice translation** on oriented links: shifts the base
    site; direction is unchanged. -/
def translateLink (d L : ℕ) [NeZero L]
    (v : Lattice d L) (l : Link d L) : Link d L :=
  (translate d L v l.1, l.2)

/-- **Lattice translation** on gauge configurations: pulls back
    along `translateLink (-v)` so that the resulting map is a left
    action (`translateConfig v` followed by `translateConfig w`
    equals `translateConfig (v + w)` on the nose modulo Pi
    associativity, which is `rfl` for the configurations we
    actually evaluate). Requires `[NeZero L]` for `Neg (Fin L)`. -/
def translateConfig (d L : ℕ) [NeZero L]
    (v : Lattice d L) (U : GaugeConfig d L) : GaugeConfig d L :=
  fun l => U (translateLink d L (fun i => -v i) l)

/-- **Brick (`translateConfig_const_one`).** The constant-`1`
    gauge configuration is translation-fixed:
    `translateConfig v (const 1) = const 1` for every `v`.
    Load-bearing for the Batches 170.2 and 170.3 OS-2 proofs —
    combined with the Batch 168.3 Dirac-haar stand-in, every
    translation-image of the (sole) support point `const 1`
    equals `const 1`, so the Wilson action evaluated on the
    translated configuration equals the Wilson action evaluated
    on the original. -/
theorem translateConfig_const_one (d L : ℕ) [NeZero L]
    (v : Lattice d L) :
    translateConfig d L v (fun _ : Link d L => (1 : G)) =
      (fun _ : Link d L => (1 : G)) := by
  funext _
  rfl

end TheoremaAureum.Towers.YM.LatticeGauge
