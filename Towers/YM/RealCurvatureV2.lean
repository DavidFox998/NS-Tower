/-
================================================================
Towers / YM / RealCurvatureV2  (Task #56 Path B, batch 6)

**Non-trivial successor to Batch 5: a first real (non-zero) SU(3)
structure constant `f^{012} = 1`, a forward-difference lattice
covariant derivative on a cyclic `Fin n` lattice (n > 0), and the
resulting composed YM curvature stand-in.**

User-spec (this batch):
```
structure_constants_su3_def
lie_bracket_su3_def
lattice_deriv_forward_diff
curvature_su3_def
YMEnergy_nonneg
```

### What changes vs Batch 5 (`Towers.YM.RealCurvature`)

Batch 5 used three placeholders that all evaluated to zero:
`f^{abc} ≡ 0`, `lattice_deriv := id`, and a `curvature` that
collapsed to the zero gauge field. The bricks were honest but
every leaf was 0 and the schema had no non-trivial content
beyond type-checking. This file honours the Batch-4 architect
review note ("add a non-identity curvature operator") by:

  * lifting `structure_constants_su3` from the all-zero placeholder
    to one with the canonical first Gell-Mann entry `f^{012} = 1`
    (the "f^{123} = 1" of `Towers.YM.SU3Basis` indexed from zero);
  * replacing the identity `lattice_deriv` with the genuine
    nearest-neighbour forward difference `(D_μ A)(i) := A(i+1) − A i`
    on a cyclic `Fin n` lattice (so `i + 1` wraps modulo `n`, which
    requires `[NeZero n]`);
  * keeping the same composition shape
    `curvature A i := lie_bracket_su3 (D_0 A i) (D_1 A i)`, so the
    whole pipeline is now genuinely non-trivial: for a generic
    `A` the resulting `curvature` is *not* identically zero, and
    `YMHamiltonian` is a real sum of squared norms.

### Honest scope

What this file claims:

  * `structure_constants_su3` provides ONE real Gell-Mann entry
    `f^{012} = 1` (zero elsewhere). NOT the full antisymmetric
    `f^{abc}` table — five more non-zero independent entries
    (`f^{036}, f^{057}, f^{135}, f^{146}, f^{247}` in this indexing
    convention) plus the `√3/2`-entries `f^{367}, f^{567}` are
    still missing. Antisymmetry under index swap is also NOT
    enforced.
  * `lie_bracket_su3` is the bilinear coordinate sum
    `(lie_bracket X Y)^c = ∑ a b, f^{abc} X^a Y^b` — the real
    formula. With only one non-zero structure constant the
    bracket is non-trivial but very sparse.
  * `lattice_deriv` is the genuine cyclic forward difference
    `(D_μ A)(i) := A((i+1) mod n) − A i`, ignoring `μ : Fin 4`
    (still a one-dimensional lattice indexing; a full 4D lattice
    would need `Fin n × Fin n × Fin n × Fin n → su(3)` and a
    direction-dependent neighbour map).
  * `curvature_su3 A i := lie_bracket_su3 (D_0 A i) (D_1 A i)`
    — the composition is now load-bearing on both upgrades.
  * `YMHamiltonian := ∑ i, ‖curvature_su3 A i‖²` is non-negative.

What this file does NOT claim:

  * Jacobi identity, antisymmetry, or any other Lie algebra
    axiom for `lie_bracket_su3` (they fail with this partial
    table — the bracket is not skew-symmetric);
  * the full SU(3) structure constants;
  * a gauge-covariant lattice derivative (no parallel transport
    `U_μ`);
  * the genuine Yang-Mills curvature `F_{μν} = ∂_μ A_ν − ∂_ν A_μ
    + g [A_μ, A_ν]`;
  * the Wilson plaquette action;
  * the YM mass-gap conjecture, spectral gap, OS / Wightman
    axioms, or Clay-style YM dynamics.

The YM tower status remains **Open** (`docs/ROADMAP.md` § 2).
================================================================
-/

import Mathlib.Analysis.InnerProductSpace.PiL2
import Towers.YM.GaugeField

namespace TheoremaAureum
namespace Towers
namespace YM
namespace RealCurvatureV2

open scoped BigOperators
open TheoremaAureum.Towers.YM.GaugeField

/-- **`structure_constants_su3 a b c`** — partial table for the
SU(3) Gell-Mann structure constants `f^{abc}` (zero-indexed). One
non-zero entry: `f^{012} = 1` (the canonical "f^{123} = 1" up to the
Fin-8 zero offset). Everything else is `0`. -/
def structure_constants_su3 (a b c : Fin 8) : ℝ :=
  if (a, b, c) = (0, 1, 2) then 1 else 0

/-- **`lie_bracket_su3 X Y`** — the real bilinear coordinate sum
`(lie_bracket X Y)^c = ∑ a b, f^{abc} X^a Y^b` on the Gell-Mann
basis of `su(3)` (represented as `EuclideanSpace ℝ (Fin 8)`).
With the partial structure-constant table from this file the
bracket is non-zero only at `c = 2` and only when the `(0, 1)`
coordinate combination of `X, Y` is non-zero. -/
noncomputable def lie_bracket_su3
    (X Y : EuclideanSpace ℝ (Fin 8)) : EuclideanSpace ℝ (Fin 8) :=
  fun c => ∑ a : Fin 8, ∑ b : Fin 8,
    structure_constants_su3 a b c * X a * Y b

/-- **`lattice_deriv A μ`** — cyclic forward-difference lattice
covariant derivative: `(D_μ A)(i) := A(i+1) − A i`, where `i + 1`
is computed in `Fin n` (so wraps modulo `n` — requires `[NeZero n]`).
The direction index `μ : Fin 4` is currently ignored: this is a
one-dimensional lattice indexing, so all four "directions" use the
same neighbour shift. A genuine 4D lattice would index by
`Fin n × Fin n × Fin n × Fin n` with a direction-dependent shift. -/
noncomputable def lattice_deriv {n : ℕ} [NeZero n]
    (A : GaugeField n) (_μ : Fin 4) : GaugeField n :=
  fun i => A (i + 1) - A i

/-- **`curvature_su3 A`** — composed curvature stand-in
`F_{01}(i) := [D_0 A, D_1 A](i)` using the Batch 6
`lie_bracket_su3` and `lattice_deriv`. Non-trivial for generic
`A`, unlike the Batch 5 placeholder. -/
noncomputable def curvature_su3 {n : ℕ} [NeZero n]
    (A : GaugeField n) : GaugeField n :=
  fun i =>
    lie_bracket_su3 (lattice_deriv A 0 i) (lattice_deriv A 1 i)

/-- **`YMHamiltonian A`** — the sum-of-squared-curvature-norms
stand-in for the Batch 6 curvature. Same shape as Batches 4 / 5
but the curvature input is genuinely non-trivial here. -/
noncomputable def YMHamiltonian {n : ℕ} [NeZero n]
    (A : GaugeField n) : ℝ :=
  ∑ i, ‖curvature_su3 A i‖ ^ 2

/-! ### Bricks (5) — one per user-spec item -/

/-- **Brick 1 (`structure_constants_su3_def`).** The first real
Gell-Mann entry `f^{012} = 1`. Concrete numeric witness that the
schema is non-zero, in contrast to Batch 5's all-zero placeholder. -/
theorem structure_constants_su3_def :
    structure_constants_su3 0 1 2 = 1 := by
  unfold structure_constants_su3
  rw [if_pos rfl]

/-- **Brick 2 (`lie_bracket_su3_def`).** Unfolds the bracket to its
defining bilinear sum, exposing the formula for downstream use. -/
theorem lie_bracket_su3_def
    (X Y : EuclideanSpace ℝ (Fin 8)) (c : Fin 8) :
    lie_bracket_su3 X Y c =
      ∑ a : Fin 8, ∑ b : Fin 8,
        structure_constants_su3 a b c * X a * Y b := rfl

/-- **Brick 3 (`lattice_deriv_forward_diff`).** The headline upgrade:
`lattice_deriv` is the genuine cyclic forward difference, NOT
Batch 5's identity stand-in. The `μ : Fin 4` direction index is
absorbed because the lattice is currently one-dimensional. -/
theorem lattice_deriv_forward_diff {n : ℕ} [NeZero n]
    (A : GaugeField n) (μ : Fin 4) (i : Fin n) :
    lattice_deriv A μ i = A (i + 1) - A i := rfl

/-- **Brick 4 (`curvature_su3_def`).** Pins the curvature to the
composition `lie_bracket_su3 ∘ (D_0 A, D_1 A)`. With the Batch 6
upgrades both inner operations are non-trivial. -/
theorem curvature_su3_def {n : ℕ} [NeZero n]
    (A : GaugeField n) (i : Fin n) :
    curvature_su3 A i =
      lie_bracket_su3
        (lattice_deriv A 0 i) (lattice_deriv A 1 i) := rfl

/-- **Brick 5 (`YMEnergy_nonneg`).** Sum of squared real norms is
non-negative, robust against any future strengthening of the
structure-constant table or the lattice derivative. -/
theorem YMEnergy_nonneg {n : ℕ} [NeZero n]
    (A : GaugeField n) : 0 ≤ YMHamiltonian A := by
  unfold YMHamiltonian
  exact Finset.sum_nonneg (fun i _ => sq_nonneg _)

end RealCurvatureV2
end YM
end Towers
end TheoremaAureum
