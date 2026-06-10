/-
================================================================
Towers / YM / LatticeGauge — parametric gauge group, canonical SU(3)
(Task #248, Step 1; generalizes Batch 168.1 / TRI PARALLEL #8)

**Definition module.** Introduces the carrier types for finite
lattice gauge theory, now **parametric over the gauge group**:

  * `SU N`            — `Matrix.specialUnitaryGroup (Fin N) ℂ`, the
                        special-unitary gauge group family.
  * `G`              — the canonical Yang–Mills gauge group `SU 3`
                        (was `SU 2` in Batch 168.1; generalized to
                        SU(3) for the real-transfer-Hamiltonian work).
  * `Lattice d L`    — sites of a `d`-dimensional periodic lattice of
                        side length `L`. Encoded as `Fin d → Fin L`.
  * `Link d L`       — an oriented link: a site plus a direction.
  * `GaugeConfigOf 𝒢 d L` — a `𝒢`-valued function on links, parametric
                        in the gauge-group type `𝒢`.
  * `GaugeConfig d L` — the canonical SU(3) configuration
                        `= Link d L → G`, definitionally equal to
                        `GaugeConfigOf G d L`. Signature kept stable so
                        every downstream consumer in the
                        `TheoremaAureum.Towers.YM.LatticeGauge` namespace
                        is unchanged and now resolves to SU(3).

## Honest scope (locked)
* This file declares **definitions only** (plus trivial `rfl`
  registration bricks). It says nothing about dynamics, the Wilson
  action (`WilsonAction`), or any measure (`GibbsMeasure`).
* Does **NOT** prove the continuum limit, OS axioms, or any
  Yang–Mills statement. Surface #1 stays OPEN; YM Status: Open.
* The SU(2) → SU(3) flip is a carrier-type change only; every
  downstream brick in this namespace is a group-agnostic vacuous /
  `rfl` stand-in, so the flip changes no proof.

## Generalization from Batch 168.1
* Batch 168.1 fixed `G := SU(2)` ("simplest non-abelian, matched the
  user snippet"). This module makes the gauge group a first-class
  parameter via `GaugeConfigOf` and fixes the canonical `G := SU 3`,
  the physical Yang–Mills gauge group, as the real transfer-operator
  work requires SU(3).
* `Lattice`/`Link` are gauge-group-independent and unchanged.
  `GaugeConfig d L` keeps its `(d L : Nat)` signature; only the gauge
  group it points at moved from SU(2) to SU(3).

## Axiom footprint
Every brick is `rfl`; `#print axioms` is expected to be the strictly
empty set `[]` (no classical trio needed for these type-level `rfl`s).
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Data.Finset.Lattice
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- The special-unitary gauge-group family `SU(N) = specialUnitaryGroup (Fin N) ℂ`. -/
abbrev SU (N : ℕ) : Type := Matrix.specialUnitaryGroup (Fin N) ℂ

/-- The canonical Yang–Mills gauge group: `SU(3)`.

    Generalized from the Batch 168.1 `SU(2)` stand-in. The lattice
    carriers below are parametric over any gauge-group type via
    `GaugeConfigOf`; `G` fixes the canonical instance at SU(3). -/
abbrev G : Type := SU 3

/-- Sites of a `d`-dimensional periodic lattice of side length `L`,
    encoded as the function space `Fin d → Fin L` (the `d`-fold product
    of `Fin L`). `Fin L`'s native modular `+` supplies periodic
    boundaries when `[NeZero L]` is in scope. -/
def Lattice (d L : Nat) : Type := Fin d → Fin L

/-- An oriented link: a site plus a direction. -/
def Link (d L : Nat) : Type := Lattice d L × Fin d

/-- Gauge-group-parametric configuration: a `𝒢`-valued function on
    links, for an arbitrary gauge-group type `𝒢`. -/
def GaugeConfigOf (𝒢 : Type _) (d L : Nat) : Type := Link d L → 𝒢

/-- A gauge configuration: a `G`(= SU(3))-valued function on links.
    Definitionally `GaugeConfigOf G d L`; signature kept stable so every
    downstream consumer is unchanged. -/
def GaugeConfig (d L : Nat) : Type := Link d L → G

/-- **Brick (`Lattice_def`).** Definitional unfolding of the
    `Lattice d L` carrier. `rfl` rewrite target for downstream code that
    needs `Fin d → Fin L` directly. -/
theorem Lattice_def (d L : Nat) :
    Lattice d L = (Fin d → Fin L) := rfl

/-- **Brick (`G_eq_SU3`).** The canonical gauge group is `SU(3)`.
    Certifies the SU(2) → SU(3) generalization at the type level. -/
theorem G_eq_SU3 : G = SU 3 := rfl

/-- **Brick (`GaugeConfig_eq_parametric`).** The canonical SU(3)
    configuration is the `G`-instance of the gauge-group-parametric
    `GaugeConfigOf`. Ties the stable `GaugeConfig` signature to the new
    parametric carrier. -/
theorem GaugeConfig_eq_parametric (d L : Nat) :
    GaugeConfig d L = GaugeConfigOf G d L := rfl

end TheoremaAureum.Towers.YM.LatticeGauge
