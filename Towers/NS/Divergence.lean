/-
  # Towers.NS.Divergence

  **This file does NOT prove Navier-Stokes global regularity, any
  blow-up criterion, or any energy estimate.** It establishes the
  trivial linearity of the divergence operator on smooth vector
  fields and pins the Clay-formulated global-regularity statement
  as a future target.

  Status (cf. `docs/ROADMAP.md` § 3. Navier-Stokes global regularity):

  - `V`                              -- abbreviation for the 3D Euclidean
                                        space `EuclideanSpace R (Fin 3)`,
                                        in which we work.
  - `stdBasis i`                     -- the `i`-th standard unit vector
                                        of `V`.
  - `divergence v x`                 -- minimal definition of the
                                        divergence of a vector field
                                        `v : V -> V` at `x : V`, as the
                                        sum of the directional
                                        derivatives along the three
                                        coordinate axes of the
                                        corresponding components.
                                        Built on top of mathlib's
                                        `fderiv`. No fancy distribution
                                        theory; just the elementary
                                        Frechet derivative.
  - `divergence_add`                 -- trivial linearity-under-addition
                                        lemma, **proved**, conditional
                                        on `Differentiable R v` and
                                        `Differentiable R w` (so that
                                        `fderiv_add` applies). Axiom
                                        footprint = subset of mathlib's
                                        classical core
                                        `{propext, Classical.choice,
                                        Quot.sound}`, no research-grade
                                        axioms. (Verified by
                                        `scripts/check-towers.sh`.)
  - `divergence_smul`                -- trivial scalar-homogeneity
                                        lemma, **proved**, conditional
                                        on `Differentiable R v` (so that
                                        `fderiv_const_smul` applies).
                                        Same axiom-footprint guarantee.

  **The Clay 3D incompressible Navier-Stokes global-regularity
  statement schema has been moved to the sibling file
  `Towers/NS/EnergyIneq.lean`** as a `sorry`-backed `def`. That
  file is deliberately NOT a brick (it ships with `sorryAx` by
  design) and is excluded from `BRICKS` in
  `scripts/check-towers.sh`. This file (`Towers.NS.Divergence`)
  is now **div-linearity-only**: no placeholder axioms, no
  schema, no `sorry`.

  **Honest scoping reminder.** This file does **not** advance the NS
  tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It moves NS
  from `Status: Open` to `Status: Open -- first/second brick
  formalized (divergence-linearity in Lean, axiom footprint subseteq
  classical trio)`. No promotion past `Open`. No claim of any PDE
  result.
-/

import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.InnerProductSpace.EuclideanDist
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum
namespace Towers
namespace NS

open scoped BigOperators

/-- 3D Euclidean space, the ambient space for the incompressible
    Navier-Stokes equations on `R^3`. -/
abbrev V : Type := EuclideanSpace ℝ (Fin 3)

/-- The `i`-th standard unit vector of `V = EuclideanSpace R (Fin 3)`. -/
noncomputable def stdBasis (i : Fin 3) : V := EuclideanSpace.single i (1 : ℝ)

/-- **Divergence of a vector field on `R^3`** (minimal definition).

    For a vector field `v : V -> V` and a point `x : V`, the
    divergence is the sum over the three coordinate axes of the
    `i`-th component of the Frechet derivative `fderiv R v x`
    applied to the `i`-th standard unit vector:

      `(div v)(x) = sum_i (D_i v(x))_i`

    This matches the classical definition `div v = d1v1 + d2v2 +
    d3v3` whenever the component partial derivatives exist. We use
    `fderiv` (rather than a coordinate-wise `deriv`) so we can
    invoke `fderiv_add` directly in the linearity lemma below
    without reaching for `Function.partialDeriv` (which mathlib
    v4.12.0 does not provide under that name).

    No multiplicity-of-zero or distributional theory is invoked.
    This is the elementary divergence on smooth vector fields, and
    nothing more. -/
noncomputable def divergence (v : V → V) (x : V) : ℝ :=
  ∑ i : Fin 3, (fderiv ℝ v x (stdBasis i)) i

/-- **Linearity of divergence under addition (trivial brick).**

    For any two `Differentiable R` vector fields `v, w : V -> V` and
    any point `x : V`,

      `div (v + w) (x) = div v (x) + div w (x)`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_add (v w : V → V)
    (hv : Differentiable ℝ v) (hw : Differentiable ℝ w) (x : V) :
    divergence (v + w) x = divergence v x + divergence w x := by
  simp only [divergence]
  have hsum : (v + w) = (fun y => v y + w y) := rfl
  rw [hsum, fderiv_add (hv x) (hw x)]
  simp only [ContinuousLinearMap.add_apply, PiLp.add_apply]
  exact Finset.sum_add_distrib

/-- **Linearity of divergence under scalar multiplication (trivial second brick).**

    For any real scalar `c : R`, any `Differentiable R` vector field
    `v : V -> V`, and any point `x : V`,

      `div (c * v) (x) = c * div v (x)`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_smul (c : ℝ) (v : V → V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (c • v) x = c * divergence v x := by
  simp only [divergence]
  have hsmul : (c • v) = (fun y => c • v y) := rfl
  rw [hsmul, fderiv_const_smul (hv x) c]
  simp only [ContinuousLinearMap.smul_apply, PiLp.smul_apply, smul_eq_mul]
  rw [← Finset.mul_sum]

/-- **Divergence of the zero vector field is zero (trivial third brick).**

    For any point `x : V`, `div (0 : V -> V) (x) = 0`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_zero (x : V) : divergence (0 : V → V) x = 0 := by
  simp only [divergence]
  have h0 : (0 : V → V) = fun _ => (0 : V) := rfl
  rw [h0]
  simp [fderiv_const]

/-- **Divergence is odd under negation (trivial fourth brick).**

    For any vector field `v : V -> V` and any point `x : V`,
    `div (-v) (x) = - div v (x)`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_neg (v : V → V) (x : V) :
    divergence (-v) x = - divergence v x := by
  simp only [divergence]
  have hneg : (-v) = (fun y => -(v y)) := rfl
  rw [hneg, fderiv_neg]
  simp only [ContinuousLinearMap.neg_apply, PiLp.neg_apply]
  exact Finset.sum_neg_distrib

/-- **Divergence distributes over subtraction (trivial fifth brick).**

    For any two `Differentiable R` vector fields `v w : V -> V` and
    any point `x : V`, `div (v - w) (x) = div v (x) - div w (x)`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_sub (v w : V → V)
    (hv : Differentiable ℝ v) (hw : Differentiable ℝ w) (x : V) :
    divergence (v - w) x = divergence v x - divergence w x := by
  have heq : (v - w) = v + (-w) := sub_eq_add_neg v w
  rw [heq, divergence_add v (-w) hv hw.neg, divergence_neg]
  ring

/-- **Divergence of any constant vector field is zero (trivial sixth brick).**

    For any constant vector `c : V` and any point `x : V`,
    `div (fun _ : V => c) (x) = 0`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_const (c : V) (x : V) :
    divergence (fun _ : V => c) x = 0 := by
  simp only [divergence]
  simp [fderiv_const]

/-- **Adding a constant vector field leaves divergence unchanged
    (seventh divergence brick).**

    For any differentiable vector field `v : V -> V`, any constant
    `c : V`, and any point `x : V`,
    `div (v + fun _ => c) x = div v x`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_add_const (v : V → V) (c : V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (v + fun _ => c) x = divergence v x := by
  rw [divergence_add v (fun _ => c) hv (differentiable_const c),
      divergence_const, add_zero]

/-- **Subtracting a constant vector field leaves divergence unchanged
    (eighth divergence brick).**

    For any differentiable vector field `v : V -> V`, any constant
    `c : V`, and any point `x : V`,
    `div (v - fun _ => c) x = div v x`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms. -/
theorem divergence_sub_const (v : V → V) (c : V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (v - fun _ => c) x = divergence v x := by
  rw [divergence_sub v (fun _ => c) hv (differentiable_const c),
      divergence_const, sub_zero]

end NS
end Towers
end TheoremaAureum
