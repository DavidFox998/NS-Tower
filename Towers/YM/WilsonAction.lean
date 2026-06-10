/-
================================================================
Towers / YM / WilsonAction — genuine SU(3) Wilson plaquette action
(Task #248, Step 2; supersedes the Batch 168.2 pure-core Int stand-in)

**Definition module.** Builds the *real* Wilson plaquette action,
valued in ℝ, over the SU(3) gauge configuration `GaugeConfig d L`
from `Towers.YM.LatticeGauge` (Task #248 Step 1). This replaces the
vacuous integer stand-in `S_Wilson_const : Int := 0` (kept below for
the still-registered `wilsonAction_zero_beta` brick) with the genuine
matrix-trace action.

  * `latticeShift x μ`      — the periodic neighbour shift
                             `x ↦ x + ê_μ` on `Lattice d L` (the
                             `Fin L`-modular successor in component
                             `μ`, needs `[NeZero L]`).
  * `wilsonPlaquette U x μ ν : Matrix (Fin 3) (Fin 3) ℂ`
                             — the ordered Wilson plaquette with
                             site-shifted links
                             `U_μ(x)·U_ν(x+ê_μ)·U_μ(x+ê_ν)*·U_ν(x)*`.
  * `plaquetteEnergy U x μ ν : ℝ`
                             — the real per-plaquette Wilson energy
                             `(3 − Re tr P_{μν}(x)) / 3`
                             (= `1 − (1/3)·Re tr P`, the SU(3)
                             normalisation; `N = 3`).
  * `wilsonAction U : ℝ`     — the bare ordered-pair plaquette action
                             `∑_{x} ∑_{μ,ν} plaquetteEnergy U x μ ν`
                             (no coupling `1/g²`, no Wick rotation,
                             no measure).

These mirror, on the general `Lattice d L`/`Link d L`/`GaugeConfig d L`
carrier, the proven-green SU(3) plaquette algebra of
`Towers.YM.PlaquetteAction` (Task #88, over the fixed-`d=4`
`Lattice4D n`): the matrix-product idiom `(U _).1 * … * star (U _).1`,
the `(3 − tr.re)/3` term, and the `Submonoid.coe_one` / `star_one` /
`Matrix.trace_one` / `Fintype.card_fin` evaluation lemmas.

## Honest scope (locked)
* The three genuine bricks witness only the **vacuum / Dirac-support
  evaluation** `U ≡ (1 : G)` (every plaquette is the 3×3 identity,
  `tr = 3`, energy `0`, action `0`). This is the *bottom* of the energy
  interval, the same Dirac-support pivot used throughout the OS bricks.
* **Does NOT prove the uniform bound `0 ≤ plaquetteEnergy ≤ 2`.** The
  loaded direction needs the SU(3) character bound `Re tr U ≥ -3`
  (equivalently `|tr U| ≤ 3`) for arbitrary `U ∈ specialUnitaryGroup
  (Fin 3) ℂ`, which mathlib v4.12.0 does not ship in a usable shape
  (it routes through the eigenvalue parametrisation / spectral theorem).
  That uniform bound is the deferred analytic input.
* **Surface #1 stays OPEN; YM Status: Open.** No mass-gap / `μ > 0` /
  spectral-gap statement is proved or implied. This file constructs the
  action object the transfer-operator route (Steps 3–5) will consume; it
  closes nothing.

## Relation to the deferred `Towers.YM.PlaquetteEnergy`
The deferred (unregistered) `Towers.YM.PlaquetteEnergy` carried an
SU(2) `plaquetteEnergy` referencing a `Towers.YM.WilsonAction.plaquette`
that the Task #208 trim had already deleted (so it no longer builds).
This module supersedes it: the genuine `plaquetteEnergy` now lives here,
SU(3)-valued, on the Step 1 carrier.

## Axiom footprint (static analysis — live `#print axioms` deferred to
   the next green `towers-build`, per the lake re-clone gotcha)
* `wilsonAction_zero_beta` — `rfl` on `Int`, axioms `[]` (unchanged).
* `wilsonPlaquette_const_one`, `plaquetteEnergy_const_one`,
  `wilsonAction_const_one_eq_zero` — discharged by the same `simp`
  lemma sets that close the proven-green `wilsonPlaquette_one` /
  `YMHamiltonianWilson_vacuum_eq_zero` in `Towers.YM.PlaquetteAction`,
  whose audited footprint is the classical trio
  `{propext, Classical.choice, Quot.sound}`. Expected: classical trio.
================================================================
-/

import Towers.YM.LatticeGauge
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.Basic

namespace TheoremaAureum.Towers.YM

/-- Surface #1: YM Wilson action vacuous stand-in (Batch 168.2).
    Kept for the still-registered `wilsonAction_zero_beta` brick. The
    genuine ℝ-valued action is `LatticeGauge.wilsonAction` below. -/
def S_Wilson_const : Int := 0

def wilson_action_measure : Unit := ()

theorem S_Wilson_nonneg : 0 ≤ S_Wilson_const := by decide

end TheoremaAureum.Towers.YM

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`wilsonAction_zero_beta`).** Pure-core vacuous stand-in that
    preserves the registered wall brick name (`check-towers.sh` entry
    `Towers.YM.WilsonAction`). At zero coupling the integer stand-in
    action is `0`. Superseded *as the action object* by the genuine
    `wilsonAction` below; kept until Step 6 retires the stand-in. -/
theorem wilsonAction_zero_beta :
    TheoremaAureum.Towers.YM.S_Wilson_const = 0 := rfl

/-! ## Genuine SU(3) Wilson plaquette action (Task #248 Step 2) -/

/-- **`latticeShift x μ`** — the periodic neighbour shift `x ↦ x + ê_μ`
    on `Lattice d L = Fin d → Fin L`: increment component `μ` by `1`
    with `Fin L`'s native modular wrap (requires `[NeZero L]` so the
    modular successor and `(1 : Fin L)` are well-defined). Each lattice
    axis is an independent cyclic factor. -/
def latticeShift {d L : ℕ} [NeZero L] (x : Lattice d L) (μ : Fin d) :
    Lattice d L :=
  Function.update x μ (x μ + 1)

/-- **`wilsonPlaquette U x μ ν`** — the ordered Wilson plaquette with
    site-shifted links:

    `P_{μν}(x) := U_μ(x) · U_ν(x + ê_μ) · U_μ(x + ê_ν)* · U_ν(x)*`.

    Each `(U _).1` extracts the underlying 3×3 complex matrix from its
    SU(3) carrier; `star` is the conjugate transpose (= the SU(3)
    inverse on the carrier). The neighbour shifts use `latticeShift`
    (the genuine `Fin L`-modular successor). Requires `[NeZero L]`. -/
noncomputable def wilsonPlaquette {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    Matrix (Fin 3) (Fin 3) ℂ :=
  (U (x, μ)).1 * (U (latticeShift x μ, ν)).1
    * star (U (latticeShift x ν, μ)).1 * star (U (x, ν)).1

/-- **`plaquetteEnergy U x μ ν`** — the real per-plaquette Wilson energy
    `(3 − Re tr P_{μν}(x)) / 3` (the SU(3) normalisation `1 − (1/N)·Re
    tr P`, `N = 3`). For SU(3) it *should* take values in `[0, 2]`; the
    loaded direction of that bound is the deferred analytic input (see
    header). The brick below witnesses only the lower endpoint `0` at
    the Dirac-support point `U ≡ const 1`. -/
noncomputable def plaquetteEnergy {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) : ℝ :=
  (3 - (wilsonPlaquette U x μ ν).trace.re) / 3

/-- **`wilsonAction U`** — the bare ordered-pair Wilson plaquette action
    `∑_{x : Lattice d L} ∑_{μ ν : Fin d} plaquetteEnergy U x μ ν` over
    the whole finite lattice. Ordered-pair sum (double-counts each
    unordered plaquette by 2; `μ = ν` diagonal pairs contribute the
    identity plaquette, energy `0`). No coupling, no measure. -/
noncomputable def wilsonAction {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) : ℝ :=
  (Finset.univ : Finset (Fin d → Fin L)).sum (fun x =>
    (Finset.univ : Finset (Fin d)).sum (fun μ =>
      (Finset.univ : Finset (Fin d)).sum (fun ν =>
        plaquetteEnergy U x μ ν)))

/-! ### Vacuum / Dirac-support bricks -/

/-- **Brick (`wilsonPlaquette_const_one`).** At the constant-`1` gauge
    configuration `U ≡ (1 : G)`, every plaquette product is the 3×3
    identity matrix: the four links are all `(1 : SU(3)).1 = 1`,
    `star 1 = 1`, and `1 · 1 · 1 · 1 = 1`. Mirrors the proven-green
    `Towers.YM.PlaquetteAction.wilsonPlaquette_one`. -/
theorem wilsonPlaquette_const_one {d L : ℕ} [NeZero L]
    (x : Lattice d L) (μ ν : Fin d) :
    wilsonPlaquette (fun _ : Link d L => (1 : G)) x μ ν
      = (1 : Matrix (Fin 3) (Fin 3) ℂ) := by
  simp [wilsonPlaquette, Submonoid.coe_one, OneMemClass.coe_one, star_one]

/-- **Brick (`plaquetteEnergy_const_one`).** At `U ≡ (1 : G)` the
    plaquette is the identity (`wilsonPlaquette_const_one`), whose trace
    is `3` (`Matrix.trace_one` on `Fin 3`, `Fintype.card_fin`), so the
    energy is `(3 − 3) / 3 = 0`. The Dirac-support evaluation of the
    genuine Wilson energy — the bottom of the `[0, 2]` interval; the
    uniform bound is deferred. -/
theorem plaquetteEnergy_const_one {d L : ℕ} [NeZero L]
    (x : Lattice d L) (μ ν : Fin d) :
    plaquetteEnergy (fun _ : Link d L => (1 : G)) x μ ν = 0 := by
  simp [plaquetteEnergy, wilsonPlaquette_const_one, Matrix.trace_one,
    Fintype.card_fin]

/-- **Brick (`wilsonAction_const_one_eq_zero`).** The all-`1` SU(3)
    configuration sits at the minimum `0` of the genuine Wilson plaquette
    action: every per-plaquette energy is `0`
    (`plaquetteEnergy_const_one`), so the triple sum collapses to `0`
    (`Finset.sum_const_zero`). Mirrors the proven-green
    `Towers.YM.PlaquetteAction.YMHamiltonianWilson_vacuum_eq_zero`.
    Makes NO mass-gap / `μ > 0` / Surface-#1 claim — Surface #1 stays
    OPEN, YM Status: Open. -/
theorem wilsonAction_const_one_eq_zero {d L : ℕ} [NeZero L] :
    wilsonAction (fun _ : Link d L => (1 : G)) = 0 := by
  simp [wilsonAction, plaquetteEnergy_const_one, Finset.sum_const_zero]

end TheoremaAureum.Towers.YM.LatticeGauge
