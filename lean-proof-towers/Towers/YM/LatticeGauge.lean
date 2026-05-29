/-
================================================================
Towers / YM / LatticeGauge (Batch 168.1 / TRI PARALLEL #8, file 1 of 3)

**Definition module.** Introduces the carrier types for finite
lattice gauge theory with gauge group `G = SU(2)`:

  * `G` — `Matrix.SpecialUnitaryGroup (Fin 2) ℂ`, the gauge group.
  * `Lattice d L` — sites of a `d`-dimensional periodic lattice of
    side length `L`. Encoded as `Fin d → Fin L` (the `d`-fold
    product of `Fin L`).
  * `Link d L` — an oriented link, parameterised by a site and a
    direction.
  * `GaugeConfig d L` — a gauge configuration: a `G`-valued
    function on links.

## Honest scope (locked)
* This file declares **definitions only** (one trivial sanity
  theorem `Lattice_def` for brick registration). It says nothing
  about dynamics, the Wilson action (that is Batch 168.2), or any
  measure (that is Batch 168.3).
* Does **NOT** prove the continuum limit, OS axioms, or any
  Yang-Mills statement. Surface #1 stays OPEN.
* `G := SU(2)` is the simplest non-abelian gauge group — chosen to
  match the user-supplied snippet. The existing
  `Towers.YM.PlaquetteAction` / `Towers.YM.Wilson` infrastructure
  uses SU(3); this batch is independent of those.

## Drift from snippet
* (1) Snippet wrote `def Lattice (d : ℕ) (L : ℕ) := Fin L ^ d`,
  but `Fin L ^ d` as a *type-level* `HPow` does not exist in
  mathlib v4.12.0 (the only `HPow Type _ _` instance is on
  monoids via `Monoid.npow`, which is for elements, not types).
  Honest pivot: `Lattice d L := Fin d → Fin L`, the
  `d`-fold cartesian product encoded as a function space. This is
  the same shape `Geometry.Lattice4D n := Fin n × Fin n × Fin n
  × Fin n` uses for the fixed-`d=4` case; the function-space form
  generalises to arbitrary `d`.
* (2) Snippet's import `Mathlib.Data.Finset.Lattice` is not
  required for any of the carrier types here (those are
  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` only).
  Kept the import positionally to record the snippet edge; it
  does no harm.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — every brick is `rfl`
or a `Fintype`/`Nonempty` instance lookup.
================================================================
-/

-- (Zero mathlib imports until Wall 570 — pure combinatorics.)

namespace TheoremaAureum.Towers.YM.LatticeGauge

/- Surface #1: YM measure vacuous. G/Group/Haar deferred to Wall 570+.
   Lattice is pure combinatorics. -/

-- `G` (the SU(2) gauge group) and `GaugeConfig` are deferred to
-- Wall 570+ together with the Group/Haar structure: they require
-- `Mathlib.LinearAlgebra.UnitaryGroup`, excluded here to keep this
-- file mathlib-free. `ℕ` is a mathlib/notation symbol unavailable
-- in bare Lean core, so the core spelling `Nat` is used below —
-- definitionally identical.

/-- Sites of a `d`-dimensional periodic lattice of side length `L`.

    Encoded as the function space `Fin d → Fin L`, i.e. each
    `x : Lattice d L` is a `d`-tuple of components in `Fin L`.
    `Fin L`'s native modular `+` gives the periodic-boundary
    structure for free (when `[NeZero L]` is in scope, used in
    Batch 168.2). -/
def Lattice (d L : Nat) : Type := Fin d → Fin L

/-- An oriented link: a site plus a direction. -/
def Link (d L : Nat) : Type := Lattice d L × Fin d

/- A gauge configuration: a `G`-valued function on links.
   Deferred to Wall 570+ together with `G`/Group/Haar:
   `def GaugeConfig (d L : Nat) : Type := Link d L → G` -/

/-- **Brick (`Lattice_def`).** Definitional unfolding of the
    `Lattice d L` carrier. Useful as a `rfl` rewrite target for
    any downstream code that needs `Fin d → Fin L` directly. -/
theorem Lattice_def (d L : Nat) :
    Lattice d L = (Fin d → Fin L) := rfl

end TheoremaAureum.Towers.YM.LatticeGauge
