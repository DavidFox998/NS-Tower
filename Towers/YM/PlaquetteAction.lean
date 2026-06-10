/-
================================================================
Towers / YM / PlaquetteAction  (Task #88 — real Wilson plaquette
action over a real `Lattice4D` config, with site-shifted links)

**Real Wilson plaquette `tr(F_{μν} F^{μν})`-flavoured action over
a periodic `Lattice4D n`, plumbed up as the canonical Wilson
surface for new YM work.** The placeholder `YMHamiltonian`
(sum-of-traces stand-in) in `Towers.YM.MassGap` is preserved for
backward compatibility with the ~25 Spectrum-track bricks in
`Towers.YM.Spectrum` Batches 8–15 that explicitly depend on the
trace-sum schema, and is now framed as the **Legacy placeholder
schema** in `MassGap.lean`. New YM work should target
`YMHamiltonianWilson` here, or the module-boundary alias
`MassGap.YMHamiltonianReal`.

## Honest scope

What this file claims:

  * `latticeShift x μ` — the genuine periodic neighbour shift
    `x ↦ x + ê_μ` on `Lattice4D n` (requires `n > 0` via
    `[NeZero n]`; the four `Fin n` components are independent
    cyclic axes). Uses `Fin n`'s native modular `+ 1`.
  * `wilsonPlaquette U x μ ν` is the **standard ordered Wilson
    plaquette with site-shifted links**

      `P_{μν}(x) := U_μ(x) · U_ν(x + ê_μ) · U_μ(x + ê_ν)*
                                          · U_ν(x)*`

    a 3×3 unitary matrix, equal to the identity on the all-ones
    gauge field at every site, and genuinely non-trivial whenever
    the parallel transports around the (μ, ν) plaquette do not
    cancel.
  * `wilsonPlaquetteAction U` is the standard Wilson plaquette
    action on `Lattice4D n`:

      `S_W[U] := ∑_{x : Lattice4D n} ∑_{μ, ν : Fin 4}
                    (3 − Re tr(P_{μν}(x))) / 3`.

    Ordered-pair sum (16 pairs per site, double-counts each
    unordered plaquette by 2; `(μ, μ)` diagonal pairs evaluate
    to the identity and contribute `0`). The bare action — no
    coupling `1/g²`, no Wick rotation, no measure.
  * `YMHamiltonianWilson A` specialises the action to the
    constant gauge field induced by an `A : Fin 4 → SU(3)`
    (the `SU3Connection` shape from `Towers.YM.MassGap`) over
    `Lattice4D 1`. This is the canonical Wilson surface
    `MassGap.YMHamiltonianReal` aliases to.
  * `YMHamiltonianWilson_vacuum_eq_zero` is the going-forward
    counterpart of `MassGap.YMHamiltonian_one_eq_twelve`: the
    all-ones SU(3) connection sits at the **minimum** `0` of
    the Wilson plaquette action — every plaquette evaluates to
    the identity (the four links commute) and the ordered-pair
    sum collapses to `∑ (3 − 3) / 3 = 0`. Contrast with the
    placeholder value `12 = 4 · 3` is what makes
    `YMHamiltonian_one_eq_twelve` an *honest numerical
    placeholder*.

What this file does NOT claim:

  * A proof of the YM mass-gap conjecture, the Clay-YM 4D
    statement, or any Δ > 0 for SU(3) in 4D. The Wilson
    plaquette action is the *kinematic* surface; mass-gap
    extraction from it is the open Glimm-Jaffe-Spencer
    constructive QFT step (still Open in `docs/ROADMAP.md` § 2).
  * A coupling-constant-dependent action — `g` is not in
    scope; the action is the bare `∑(3 − Re tr(P)) / 3`.
  * The continuum `∫ tr(F_{μν} F^{μν}) d⁴x` — only the
    discrete lattice Wilson form. The continuum limit
    `a → 0` is out of scope.
  * Gauge invariance, OS positivity, transfer-matrix, or any
    of the downstream constructive QFT structure (those are
    schemas in `Towers.YM.Spectrum`).
  * That the placeholder `YMHamiltonian` (sum-of-traces) in
    `Towers.YM.MassGap` has been *removed* — it is preserved
    for backward compatibility with Batches 8–15 of the
    Spectrum-track bricks, which are explicitly bricks on the
    *placeholder* schema. `YMHamiltonianWilson` (and its
    `MassGap.YMHamiltonianReal` alias) is the going-forward
    real-action surface for new work.

YM tower status remains **Open** (`docs/ROADMAP.md` § 2). This
file is plumbing, not a proof.
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.Basic
import Towers.YM.Geometry

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PlaquetteAction

open scoped BigOperators
open Geometry

/-- **`latticeShift x μ`** — the periodic neighbour shift
`x ↦ x + ê_μ` on `Lattice4D n`. For `μ ∈ {0, 1, 2, 3}` it
increments the corresponding `Fin n` component by `1`, with
`Fin n`'s native modular wrap (requires `[NeZero n]` so the
modular successor is well-defined). The four spacetime axes
are independent cyclic factors. -/
def latticeShift {n : ℕ} [NeZero n] (x : Lattice4D n)
    (μ : Fin 4) : Lattice4D n :=
  if μ.val = 0 then (x.1 + 1, x.2.1, x.2.2.1, x.2.2.2)
  else if μ.val = 1 then (x.1, x.2.1 + 1, x.2.2.1, x.2.2.2)
  else if μ.val = 2 then (x.1, x.2.1, x.2.2.1 + 1, x.2.2.2)
  else (x.1, x.2.1, x.2.2.1, x.2.2.2 + 1)

/-- **`LatticeGaugeField n`** — a discrete SU(3) gauge field on
`Lattice4D n`: one SU(3) matrix per site `x : Lattice4D n` per
spacetime direction `μ : Fin 4`. The "real Lattice4D config"
the Task #88 brief named. -/
abbrev LatticeGaugeField (n : ℕ) : Type :=
  Lattice4D n → Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ

/-- **`wilsonPlaquette U x μ ν`** — the standard ordered Wilson
plaquette with **site-shifted links**:

  `P_{μν}(x) := U_μ(x) · U_ν(x + ê_μ) · U_μ(x + ê_ν)* · U_ν(x)*`.

Each `(U _ _).1` extracts the underlying 3×3 complex matrix from
its SU(3) carrier. The neighbour shifts use `latticeShift` (the
genuine periodic `Fin n`-modular successor). Requires `[NeZero n]`
so the lattice has at least one site and `Fin n`'s `+ 1` is
modular. -/
noncomputable def wilsonPlaquette {n : ℕ} [NeZero n]
    (U : LatticeGaugeField n) (x : Lattice4D n) (μ ν : Fin 4) :
    Matrix (Fin 3) (Fin 3) ℂ :=
  (U x μ).1 * (U (latticeShift x μ) ν).1
    * star (U (latticeShift x ν) μ).1 * star (U x ν).1

/-- **`wilsonPlaquetteAction U`** — the standard Wilson plaquette
action over `Lattice4D n`:

  `S_W[U] := ∑_{x : Lattice4D n} ∑_{μ, ν : Fin 4}
                (3 − Re tr(P_{μν}(x))) / 3`.

Ordered-pair sum (16 pairs per site; double-counts each unordered
plaquette by 2). The bare action — no coupling `1/g²`, no Wick
rotation, no measure. -/
noncomputable def wilsonPlaquetteAction {n : ℕ} [NeZero n]
    (U : LatticeGaugeField n) : ℝ :=
  (Finset.univ : Finset (Lattice4D n)).sum (fun x =>
    (Finset.univ : Finset (Fin 4)).sum (fun μ =>
      (Finset.univ : Finset (Fin 4)).sum (fun ν =>
        (3 - (wilsonPlaquette U x μ ν).trace.re) / 3)))

/-- **`constantLatticeGaugeField A`** — promote an `A : Fin 4 →
SU(3)` (the `SU3Connection` shape from `Towers.YM.MassGap`) into
a `LatticeGaugeField n` by ignoring the site index. The bridge
between the constant-coefficient connection used by the
placeholder `YMHamiltonian` and the genuine lattice gauge field
the Wilson action ranges over. -/
noncomputable def constantLatticeGaugeField {n : ℕ}
    (A : Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ) :
    LatticeGaugeField n :=
  fun _ μ => A μ

/-- **`YMHamiltonianWilson A`** — the real Wilson plaquette action
with site-shifted links, evaluated on the constant gauge field
induced by `A : Fin 4 → SU(3)`, on the smallest non-empty 4D
lattice `Lattice4D 1` (one site, all shifts collapse to the same
site since `Fin 1` has only one element).

This is the Task #88 "real plaquette action over a real Lattice4D
config" replacement for the trace-sum placeholder `YMHamiltonian`
in `Towers.YM.MassGap`. It is named with the `Wilson` suffix
(rather than reusing `YMHamiltonian`) so that the ~25 downstream
bricks in `Towers.YM.Spectrum` that depend on the *placeholder*'s
numerical values (`= 12` at the vacuum, `≤ 12` uniform bound) stay
green; those bricks are explicitly tagged as bricks on the
placeholder schema (see Batches 9–15 in `Towers.YM.Spectrum`),
and the going-forward real-action work uses `YMHamiltonianWilson`.
A module-boundary alias `MassGap.YMHamiltonianReal` exposes the
same value under a name living in `MassGap.lean` for callers who
want both surfaces side-by-side. -/
noncomputable def YMHamiltonianWilson
    (A : Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ) : ℝ :=
  wilsonPlaquetteAction (constantLatticeGaugeField (n := 1) A)

/-! ## Bricks -/

/-- **Brick (`wilsonPlaquette_def`).** Definitional unfolding of the
site-shifted plaquette product. Useful as a rewrite target for any
downstream evaluation. -/
theorem wilsonPlaquette_def {n : ℕ} [NeZero n] (U : LatticeGaugeField n)
    (x : Lattice4D n) (μ ν : Fin 4) :
    wilsonPlaquette U x μ ν =
      (U x μ).1 * (U (latticeShift x μ) ν).1
        * star (U (latticeShift x ν) μ).1 * star (U x ν).1 := rfl

/-- **Brick (`wilsonPlaquette_one`).** For the all-ones constant
gauge field, every plaquette evaluates to the 3×3 identity matrix
at every site and every direction pair. Proof: `constantLatticeGaugeField`
discards the site argument (so the four shifted-and-unshifted SU(3)
matrices are all `1`), `(1 : SU(3)).1 = (1 : Matrix _ _ ℂ)` (via
`Submonoid.coe_one`), `star 1 = 1`, and `1 * 1 * 1 * 1 = 1`. -/
theorem wilsonPlaquette_one {n : ℕ} [NeZero n] (x : Lattice4D n)
    (μ ν : Fin 4) :
    wilsonPlaquette
        (constantLatticeGaugeField (n := n)
          (fun _ => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ)))
        x μ ν
      = (1 : Matrix (Fin 3) (Fin 3) ℂ) := by
  simp [wilsonPlaquette, constantLatticeGaugeField, Submonoid.coe_one,
        star_one]

/-- **Brick (`YMHamiltonianWilson_vacuum_eq_zero`).** The all-ones
SU(3) connection sits at the **minimum** `0` of the real
site-shifted Wilson plaquette action on `Lattice4D 1`.

Contrast with `MassGap.YMHamiltonian_one_eq_twelve`, which gives
the placeholder trace-sum value `12 = 4 · 3` (an artefact of the
`(spacetime-dim) · (SU(3)-rep-dim)` shape of the placeholder, NOT
a physical energy). The Wilson action returns `0` here because
every plaquette evaluates to the identity (commuting components on
a one-site lattice, where all shifts collapse) and the ordered-pair
sum collapses to `∑ (3 − 3) / 3 = 0`.

This is the brick that makes `YMHamiltonian_one_eq_twelve` an
"honest numerical placeholder": the going-forward real-action value
is `0`, not `12`, and the two-value contrast documents the
placeholder's artefactual character. YM tower status unchanged:
**Open**. -/
theorem YMHamiltonianWilson_vacuum_eq_zero :
    YMHamiltonianWilson
        (fun _ => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ)) = 0 := by
  unfold YMHamiltonianWilson wilsonPlaquetteAction
  simp [wilsonPlaquette_one, Matrix.trace_one, Fintype.card_fin]

end PlaquetteAction
end YM
end Towers
end TheoremaAureum
