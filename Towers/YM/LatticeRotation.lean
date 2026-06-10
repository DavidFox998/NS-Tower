/-
================================================================
Towers / YM / LatticeRotation (Batch 171.1 / TRI PARALLEL #11, file 1 of 3)

**Definition module.** Introduces π/2 lattice rotations in the
μ–ν plane on sites, links, and gauge configurations:

  * `rotate90 μ ν x` — swap the μ and ν coordinates of `x` and
    negate the new μ-coordinate (modular on `Fin L`). Standard
    discrete planar rotation `(x_μ, x_ν) ↦ (-x_ν, x_μ)`.
  * `rotateLink μ ν l` — applies `rotate90 μ ν` to the base site
    and permutes the direction label between μ and ν.
  * `rotateConfig μ ν U` — pulls a gauge configuration back along
    `rotateLink μ ν`.

Plus one brick: `rotateConfig_const_one` — the constant-`1`
configuration is rotation-fixed (load-bearing for Batches 171.2
and 171.3 OS-2 rotation proofs under the Dirac haar stand-in).

## Honest scope (locked)
* Definitions only, plus the fixed-point brick. Does NOT prove
  Wilson-action rotation invariance (that is Batch 171.2);
  does NOT prove Gibbs-measure rotation invariance (that is
  Batch 171.3); does NOT close OS Axiom 2 (the rotation part
  completes OS-2 alongside Batch 170.3's translation part).
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet wrote `Function.update x μ (L - x ν)` but
  `x ν : Fin L` and `L : ℕ` — the subtraction has a type
  mismatch (same kind of bug fixed in Batch 169.1 by switching
  to `- x ν`). Honest pivot: `Function.update x μ (- x ν)`,
  using `Fin L`'s native `Neg` instance (available under
  `[NeZero L]`). Mathematical content is identical:
  `-x = L − x (mod L)` in `Fin L`, which is the same reflection
  used in the planar rotation `(x_μ, x_ν) ↦ (-x_ν, x_μ)`.
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.x files.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is a
`funext` followed by a definitional reduction (the constant
function `fun _ => 1` is pulled back by anything to itself).
================================================================
-/

import Towers.YM.LatticeGauge

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **π/2 lattice rotation** in the μ–ν plane on sites:
    `(x_μ, x_ν) ↦ (-x_ν, x_μ)`, modular on each `Fin L`
    coordinate. Requires `[NeZero L]` so that `Fin L` carries
    `Neg`. -/
def rotate90 (d L : ℕ) [NeZero L] (μ ν : Fin d)
    (x : Lattice d L) : Lattice d L :=
  Function.update (Function.update x μ (- x ν)) ν (x μ)

/-- **π/2 lattice rotation** on oriented links: rotates the base
    site by `rotate90` and permutes the direction label between
    μ and ν (so a link pointing in direction μ becomes a link
    pointing in direction ν, and vice versa). -/
def rotateLink (d L : ℕ) [NeZero L] (μ ν : Fin d)
    (l : Link d L) : Link d L :=
  if l.2 = μ then (rotate90 d L μ ν l.1, ν)
  else if l.2 = ν then (rotate90 d L μ ν l.1, μ)
  else (rotate90 d L μ ν l.1, l.2)

/-- **π/2 lattice rotation** on gauge configurations: pulls
    back along `rotateLink μ ν`. -/
def rotateConfig (d L : ℕ) [NeZero L] (μ ν : Fin d)
    (U : GaugeConfig d L) : GaugeConfig d L :=
  fun l => U (rotateLink d L μ ν l)

/-- **Brick (`rotateConfig_const_one`).** The constant-`1`
    gauge configuration is rotation-fixed:
    `rotateConfig μ ν (const 1) = const 1` for every μ, ν.
    Load-bearing for the Batches 171.2 and 171.3 OS-2 (rotation
    part) proofs — combined with the Batch 168.3 Dirac-haar
    stand-in, every rotation-image of the (sole) support point
    `const 1` equals `const 1`. -/
theorem rotateConfig_const_one (d L : ℕ) [NeZero L] (μ ν : Fin d) :
    rotateConfig d L μ ν (fun _ : Link d L => (1 : G)) =
      (fun _ : Link d L => (1 : G)) := by
  funext _
  rfl

end TheoremaAureum.Towers.YM.LatticeGauge
