/-
================================================================
Towers / YM / GaugeField  (Task #56 Path B, batch 4 of 4)

**A discrete lattice gauge field stand-in carrying a Pi-L² inner
product, with a trivial discrete curvature stand-in and a
sum-of-squared-curvature `YMHamiltonian` stand-in.**

User-spec (sketch):
```
def GaugeField (n : ℕ) := Fin n → su3_submodule
instance : InnerProductSpace ℝ (GaugeField n) := Pi.innerProductSpace
def YMHamiltonian (A : GaugeField n) : ℝ := ∑ i, ‖curvature A i‖ ^ 2
```

### Why `EuclideanSpace ℝ (Fin 8)` site values, not `↥su3_submodule`

Mathlib v4.12.0 does not have a bare `Pi.innerProductSpace`. The
canonical Euclidean Π construction is `PiLp 2`, which fires
`InnerProductSpace ℝ (PiLp 2 (fun _ => α))` automatically when each
`α` is already an `InnerProductSpace ℝ` (via `PiLp.innerProductSpace`).
But Batch 3 (`instance_inner_product_space_su3_core`) only ships
`↥su3_submodule` with an `InnerProductSpace.Core ℝ`, not the full
`InnerProductSpace ℝ` instance — to promote it would need to install
a new `NormedAddCommGroup ↥su3_submodule` via
`InnerProductSpace.Core.toNormedAddCommGroup`, which collides with
any future install of `Matrix.normedAddCommGroup` on the ambient
space.

So the site type is the 8-dim Euclidean coordinate space
`EuclideanSpace ℝ (Fin 8)`. The link to `↥su3_submodule` is via the
Batch 2 v2 equiv `su3_equiv_fin8_def : ↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)`;
the two are isomorphic as real inner product spaces (via the Batch 3
`inner_su3_def := ∑ i, (su3_equiv_fin8_def x) i * (su3_equiv_fin8_def y) i`,
which is the pull-back of the standard `Fin 8 → ℝ` inner product —
i.e. the Euclidean inner product on `EuclideanSpace ℝ (Fin 8)`).
Concretely this means: a `GaugeField n` value is "morally" a
function `Fin n → ↥su3_submodule`, with the obvious Pi-L² inner
product, but expressed in the Gell-Mann coordinate basis.

### Why `curvature := id`

The genuine lattice curvature `F_μν` compares neighbour values
(e.g. `A (i+1) - A i` for 1d, or Wilson plaquette `A_μ + A_ν - A_{ν,μ+1} - A_{μ,ν+1}`
on a 2d lattice). To land a brick without committing to a lattice
geometry we use the trivial identity stand-in `curvature A i := A i`.
The downstream `YMHamiltonian A = ∑ ‖A i‖²` is then the squared
Pi-L² norm — `YMHamiltonian_eq_norm_sq` makes this explicit.

### Honest scope

This file claims ONLY:

  * `GaugeField n` is the n-fold Euclidean direct sum of the 8-dim
    real coordinate space of `↥su3_submodule`;
  * the trivial discrete curvature stand-in is well-defined and
    additively linear on the gauge field;
  * the stand-in `YMHamiltonian` is non-negative and equals the
    squared Pi-L² norm of the gauge field.

It does NOT claim anything about:

  * the genuine Yang-Mills curvature `F_μν = ∂_μ A_ν - ∂_ν A_μ + g [A_μ, A_ν]`
    (no commutator bracket, no derivative, no coupling constant);
  * the Wilson plaquette action or any lattice gauge theory action;
  * the YM mass-gap conjecture, the spectral gap of the YM Hamiltonian,
    Osterwalder–Schrader / Wightman axioms, or Clay-style YM dynamics.

The YM tower status remains **Open** (`docs/ROADMAP.md` § 2).
================================================================
-/

import Mathlib.Analysis.InnerProductSpace.PiL2
import Towers.YM.SU3Basis

namespace TheoremaAureum
namespace Towers
namespace YM
namespace GaugeField

open scoped BigOperators

/-- **`GaugeField n` — a discrete lattice gauge field on `n` sites,
each site valued in the 8-dim Euclidean coordinate space of
`↥su3_submodule` (per `su3_equiv_fin8_def`).** Carries the Pi-L²
(Euclidean) inner product structure via `PiLp 2`. -/
abbrev GaugeField (n : ℕ) : Type :=
  PiLp 2 (fun _ : Fin n => EuclideanSpace ℝ (Fin 8))

/-- **Trivial discrete curvature stand-in.** Identity on the site
value. A genuine lattice curvature would compare `A i` with `A (i+1)`
(1d) or with neighbour values on a higher-dimensional lattice; this
identity choice keeps the brick minimal and honest. -/
def curvature {n : ℕ} (A : GaugeField n) (i : Fin n) :
    EuclideanSpace ℝ (Fin 8) :=
  A i

/-- **Stand-in `YMHamiltonian` — sum of squared site curvature norms.**
For the trivial `curvature = id` stand-in this equals `‖A‖²` in the
Pi-L² norm (see `YMHamiltonian_eq_norm_sq` below). NOT the YM action
nor the Clay surface; see file header for the honest-scope disclaimer. -/
noncomputable def YMHamiltonian {n : ℕ} (A : GaugeField n) : ℝ :=
  ∑ i, ‖curvature A i‖ ^ 2

/-! ### Bricks (6) -/

/-- **Brick 1.** The zero gauge field is zero at every site. Sanity
brick — verifies that the `PiLp 2` abbrev does not obstruct
component-wise reasoning. -/
theorem GaugeField_zero_apply {n : ℕ} (i : Fin n) :
    (0 : GaugeField n) i = 0 := rfl

/-- **Brick 2.** The trivial discrete curvature of the zero gauge
field is zero at every site. -/
theorem curvature_zero {n : ℕ} (i : Fin n) :
    curvature (0 : GaugeField n) i = 0 := rfl

/-- **Brick 3.** The trivial discrete curvature is additively linear
on the gauge field. This is the first hint that any *genuine*
curvature stand-in living in this file will need to interact with
the Pi-L² additive structure correctly; the `rfl` proof here is the
identity stand-in's payoff. -/
theorem curvature_add {n : ℕ} (A B : GaugeField n) (i : Fin n) :
    curvature (A + B) i = curvature A i + curvature B i := rfl

/-- **Brick 4.** `YMHamiltonian 0 = 0` — the zero gauge field has
zero stand-in energy. Each site curvature is `0`, each site term
`‖0‖² = 0`, the sum is `0`. -/
theorem YMHamiltonian_zero (n : ℕ) :
    YMHamiltonian (0 : GaugeField n) = 0 := by
  simp [YMHamiltonian, curvature]

/-- **Brick 5.** `YMHamiltonian` is non-negative (sum of squares of
real norms). This is the only invariant one expects of any
energy-like functional, and the stand-in does satisfy it. -/
theorem YMHamiltonian_nonneg {n : ℕ} (A : GaugeField n) :
    0 ≤ YMHamiltonian A := by
  unfold YMHamiltonian
  exact Finset.sum_nonneg (fun i _ => sq_nonneg _)

/-- **Brick 6.** For the trivial `curvature = id` stand-in,
`YMHamiltonian A = ‖A‖²` in the Pi-L² norm. This is what the
"Hamiltonian = sum of squared norms" formula reduces to when the
curvature operator does no work; the result is a real-analysis fact
about `PiLp 2`, namely `PiLp.norm_sq_eq_of_L2`. -/
theorem YMHamiltonian_eq_norm_sq {n : ℕ} (A : GaugeField n) :
    YMHamiltonian A = ‖A‖ ^ 2 := by
  unfold YMHamiltonian curvature
  rw [PiLp.norm_sq_eq_of_L2]

end GaugeField
end YM
end Towers
end TheoremaAureum
