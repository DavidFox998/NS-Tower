/-
================================================================
Towers / YM / PlaquetteEnergy (Batch 177.1 / TRI PARALLEL #17, file 1 of 3)

**Definition module.** Introduces the *real* per-plaquette
Wilson energy `1 - 1/2 · Re tr U_p` on top of the SU(2) plaquette
matrix from `Towers.YM.WilsonAction` (Batch 168.2). This replaces
the constant `linkEnergy ≡ 1` upper-bound stand-in from
`Towers.YM.PolymerModel` (Batch 176.1, which dropped the real
form because of a `plaquette` arity mismatch in the snippet).

  * `plaquetteEnergy U x μ ν : ℝ` := `1 - (1/2) ·
    (Matrix.trace (plaquette U x μ ν)).re`.
  * `plaquetteEnergy_const_one` (brick) — at the constant-1 gauge
    configuration `U ≡ (1 : G)`, every plaquette is the identity
    matrix (trace `= 2`), so the energy is exactly `0`.

## Honest scope (locked)
* **Does NOT prove the SU(2) trace bound `Re tr ∈ [-2, 2]`** (and
  therefore does NOT close `0 ≤ plaquetteEnergy ≤ 2`). The
  snippet's `plaquetteEnergy_bounds` asserts that bound, but
  mathlib v4.12.0 does not provide the SU(2) character bound
  `|tr U| ≤ 2` for arbitrary `U ∈ SpecialUnitaryGroup (Fin 2) ℂ`
  in a one-tactic-step shape; a real proof would route through
  `mem_specialUnitaryGroup_iff` + the eigenvalue parametrisation
  `tr = 2 cos θ` for `θ ∈ ℝ`, which needs spectral-theorem
  machinery not in scope. Honest pivot: replace the bounds
  theorem with `plaquetteEnergy_const_one` (the one point of the
  Dirac haar stand-in support — Batch 168.3 — where the energy
  is a tractable equality, not just a bound). This is the same
  Dirac-support pivot pattern used by Batches 169.3 / 170.2 /
  170.3 / 171.2 / 171.3 / 172.3 / 173.3.
* **Does NOT close the `linkEnergy ≡ 1` tripwire from Batch
  176.1.** `PolymerModel`'s `polymerWeightReal` still uses the
  `linkEnergy : Link → ℝ` (constant `1`) stand-in. Wiring the
  real `plaquetteEnergy` here into `polymerWeightReal` requires
  a `Link → Plaquette + GaugeConfig` embedding (a polymer link
  is one edge of a plaquette face, not the plaquette itself) +
  a choice of ambient `U`, neither landed.
* **Surface #1 stays OPEN.** No Yang-Mills statement is proved.

## Drift from snippet
* (1) **`plaquette d L U x μ ν` → `plaquette U x μ ν`.** Snippet
  passed `d` and `L` explicitly, but in
  `Towers.YM.WilsonAction.plaquette` they are *implicit*
  (`{d L : ℕ}`) — the snippet would not elaborate as written.
* (2) **`.trace.re` → `(Matrix.trace …).re`.** Snippet wrote
  `(plaquette … x μ ν).trace.re` using dot-projection syntax,
  but the value `plaquette U x μ ν` has type
  `Matrix (Fin 2) (Fin 2) ℂ`, and `Matrix.trace` is a *function*
  (`Matrix n n α → α`), not a field — dot-projection elaborates
  it as `Matrix.trace (plaquette U x μ ν)` only when the result
  type expects a scalar; safer (and matches the Batch 168.2
  convention in `wilsonAction`) to write `(Matrix.trace
  (plaquette U x μ ν)).re` explicitly.
* (3) **`plaquetteEnergy_bounds` REPLACED by
  `plaquetteEnergy_const_one`.** Snippet's `sorry -- fill:
  SU(2) trace bounds. Mathlib has this.` is REFUSED — mathlib
  v4.12.0 does not ship the SU(2) trace bound `|Re tr| ≤ 2` for
  arbitrary `U ∈ specialUnitaryGroup (Fin 2) ℂ` in a usable
  shape. Honest pivot: an *equality* brick at the single Dirac-
  support point `U ≡ const 1`, where the plaquette is the
  identity matrix, the trace is `2`, and the energy is exactly
  `0`. This matches the Dirac-support pivot pattern of every OS
  brick from 169.3 through 173.3. The full SU(2) range
  `[0, 2]` is a real-Haar tripwire, deferred.
* (4) **Implicit `{d L}` everywhere** — same convention as
  `Towers.YM.WilsonAction` / `Towers.YM.PolymerModel`. Snippet
  declared them explicit.
* (5) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (matches Batch 168.x /
  170.x / 171.x / 172.x / 173.x / 174.x / 175.x / 176.x).

## Tripwire (mass gap)
* The real K-P / cluster-expansion proof needs *both* `0 ≤
  plaquetteEnergy` (the trivial direction — `Re tr ≤ 2`) *and*
  `plaquetteEnergy ≤ 2` (the loaded direction — `Re tr ≥ -2`)
  uniformly in `(U, x, μ, ν)`. Neither lands here. The brick
  below proves only the equality `plaquetteEnergy(const 1) = 0`,
  which is the *bottom* of the bound interval and reflects the
  Dirac stand-in (any K-P bound at this point is trivial because
  the polymer activity is `exp(-β · 0) = 1`, the maximum).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof unfolds
`plaquetteEnergy` and `plaquette`, then uses
`OneMemClass.coe_one`, `Matrix.one_mul`, `star_one`,
`Matrix.trace_one`, `Fintype.card_fin`, and `ring`.
================================================================
-/

import Towers.YM.WilsonAction
import Mathlib.LinearAlgebra.Matrix.Trace

namespace TheoremaAureum.Towers.YM.LatticeGauge

open Matrix

/-- **`plaquetteEnergy U x μ ν`** — real per-plaquette Wilson
    energy `1 - (1/2) · Re tr P_{μν}(x)`. Replaces the constant
    `linkEnergy ≡ 1` upper-bound stand-in from Batch 176.1's
    `Towers.YM.PolymerModel`. For SU(2), the energy *should*
    take values in `[0, 2]` (loaded direction of the bound is
    deferred — see header tripwire); the brick below witnesses
    only the lower endpoint `0` at the Dirac-support point
    `U ≡ const 1`. -/
noncomputable def plaquetteEnergy {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) : ℝ :=
  1 - (1/2) * (Matrix.trace (plaquette U x μ ν)).re

/-- **Brick (`plaquetteEnergy_const_one`).** At the constant-1
    gauge configuration `U ≡ (1 : G)`, every plaquette product
    is the identity matrix `1 : Matrix (Fin 2) (Fin 2) ℂ`
    (`1 · 1 · star 1 · star 1 = 1`), whose trace is `2`
    (`Matrix.trace_one` on `Fin 2`). Therefore the energy is
    `1 - (1/2) · 2 = 0`. This is the Dirac-support evaluation
    of the real Wilson energy — same pivot pattern as
    `wilson_translateConfig_const_one` (Batch 170.2),
    `wilson_rotateConfig_const_one` (Batch 171.2), and
    `configRefl_const_one` (Batch 169.1). The full SU(2) range
    `[0, 2]` is a real-Haar tripwire, deferred. -/
theorem plaquetteEnergy_const_one (d L : ℕ) [NeZero L]
    (x : Lattice d L) (μ ν : Fin d) :
    plaquetteEnergy (fun _ : Link d L => (1 : G)) x μ ν = 0 := by
  unfold plaquetteEnergy plaquette
  simp [OneMemClass.coe_one, Matrix.one_mul, Matrix.mul_one, star_one,
        Matrix.trace_one, Fintype.card_fin]

end TheoremaAureum.Towers.YM.LatticeGauge
