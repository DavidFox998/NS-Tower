/-
================================================================
Towers / YM / TimeReflection (Batch 169.1 / TRI PARALLEL #9, file 1 of 3)

**Definition module.** Introduces the time-reflection involution θ
on lattice sites, links, and gauge configurations:

  * `timeRefl x` — flips the 0-th (time) coordinate, `x₀ → −x₀`
    (mod `L`).
  * `linkRefl l` — applies `timeRefl` to the base site of a link.
  * `configRefl U` — pulls a gauge configuration back along
    `linkRefl`.

Plus one brick: `configRefl_const_one` — the constant-`1`
configuration is θ-fixed (load-bearing for Batch 169.3 RP).

## Honest scope (locked)
* Definitions only, plus the fixed-point brick. Does NOT prove
  RP (that is Batch 169.3); does NOT prove θ-invariance of the
  Wilson action (that is a deeper batch, not in this trio); does
  NOT close OS Axiom 1. Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet wrote `Function.update x 0 (L - x 0)`, but
  `x 0 : Fin L` and `L : ℕ` — the subtraction has a type
  mismatch. Honest pivot: `Function.update x 0 (- x 0)`, using
  `Fin L`'s native `Neg` instance (available under `[NeZero L]`).
  Mathematical content is identical: `-x = L − x (mod L)` in
  `Fin L`, which is the same reflection `x₀ → −x₀`.
* (2) Snippet's `[NeZero L]` typeclass arg is necessary on
  `timeRefl` for `Neg (Fin L)`. We also add `[NeZero d]` so that
  `0 : Fin d` exists (the 0-th coordinate index).
* (3) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x files (where `Lattice`, `Link`, `GaugeConfig`,
  and `G` are declared).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is a
`funext` followed by a definitional reduction.
================================================================
-/

import Towers.YM.LatticeGauge

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Time reflection** on lattice sites: flip the 0-th coordinate
    via `Fin L`'s modular negation. Requires `[NeZero d]` (so the
    0-th coordinate exists) and `[NeZero L]` (so `Fin L` has
    `Neg`). -/
def timeRefl (d L : ℕ) [NeZero d] [NeZero L]
    (x : Lattice d L) : Lattice d L :=
  Function.update x 0 (- x 0)

/-- **Time reflection** on oriented links: applies `timeRefl` to
    the base site; direction is unchanged. -/
def linkRefl (d L : ℕ) [NeZero d] [NeZero L]
    (l : Link d L) : Link d L :=
  (timeRefl d L l.1, l.2)

/-- **Time reflection** on gauge configurations: pulls the
    configuration back along `linkRefl`. -/
def configRefl (d L : ℕ) [NeZero d] [NeZero L]
    (U : GaugeConfig d L) : GaugeConfig d L :=
  fun l => U (linkRefl d L l)

/-- **Brick (`configRefl_const_one`).** The constant-`1` gauge
    configuration is θ-fixed: `configRefl (const 1) = const 1`.
    Load-bearing for the Batch 169.3 RP proof — combined with
    the Batch 168.3 Dirac-haar stand-in, the RP integrand
    `(F(θU))^* · F(U)` evaluated at the (sole) support point
    `U = const 1` reduces to `(F(const 1))^* · F(const 1) =
    ‖F(const 1)‖²`. -/
theorem configRefl_const_one (d L : ℕ) [NeZero d] [NeZero L] :
    configRefl d L (fun _ : Link d L => (1 : G)) =
      (fun _ : Link d L => (1 : G)) := by
  funext _
  rfl

end TheoremaAureum.Towers.YM.LatticeGauge
