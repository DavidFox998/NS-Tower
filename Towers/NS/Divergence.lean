/-
  # Towers.NS.Divergence

  **This file does NOT prove Navier-Stokes global regularity, any
  blow-up criterion, or any energy estimate.** It establishes the
  trivial linearity of the divergence operator on smooth vector
  fields and pins the Clay-formulated global-regularity statement
  as a future target.

  Status (cf. `docs/ROADMAP.md` § 3. Navier-Stokes global regularity):

  - `V`                              — abbreviation for the 3D Euclidean
                                        space `EuclideanSpace ℝ (Fin 3)`,
                                        in which we work.
  - `stdBasis i`                     — the `i`-th standard unit vector
                                        of `V`.
  - `divergence v x`                 — minimal definition of the
                                        divergence of a vector field
                                        `v : V → V` at `x : V`, as the
                                        sum of the directional
                                        derivatives along the three
                                        coordinate axes of the
                                        corresponding components.
                                        Built on top of mathlib's
                                        `fderiv`. No fancy distribution
                                        theory; just the elementary
                                        Fréchet derivative.
  - `divergence_add`                 — trivial linearity-under-addition
                                        lemma, **proved**, conditional
                                        on `Differentiable ℝ v` and
                                        `Differentiable ℝ w` (so that
                                        `fderiv_add` applies). Axiom
                                        footprint = subset of mathlib's
                                        classical core
                                        `{propext, Classical.choice,
                                        Quot.sound}`, no research-grade
                                        axioms. (Verified by
                                        `scripts/check-towers.sh`.)
  - `divergence_smul`                — trivial scalar-homogeneity
                                        lemma, **proved**, conditional
                                        on `Differentiable ℝ v` (so that
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
  from `Status: Open` to `Status: Open — first/second brick
  formalized (divergence-linearity in Lean, axiom footprint ⊆
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
    Navier-Stokes equations on `ℝ³`. -/
abbrev V : Type := EuclideanSpace ℝ (Fin 3)

/-- The `i`-th standard unit vector of `V = EuclideanSpace ℝ (Fin 3)`. -/
noncomputable def stdBasis (i : Fin 3) : V := EuclideanSpace.single i (1 : ℝ)

/-- **Divergence of a vector field on `ℝ³`** (minimal definition).

    For a vector field `v : V → V` and a point `x : V`, the
    divergence is the sum over the three coordinate axes of the
    `i`-th component of the Fréchet derivative `fderiv ℝ v x`
    applied to the `i`-th standard unit vector:

      `(div v)(x) = ∑ i, (Dᵢ v(x))ᵢ`

    This matches the classical definition `div v = ∂₁v₁ + ∂₂v₂ +
    ∂₃v₃` whenever the component partial derivatives exist. We use
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

    For any two `Differentiable ℝ` vector fields `v, w : V → V` and
    any point `x : V`,

      `div (v + w) (x) = div v (x) + div w (x)`.

    The proof is a one-line reduction to mathlib's `fderiv_add`
    plus finite-sum linearity. This lemma is **not** new
    mathematics — it is the trivial linearity of the Fréchet
    derivative wrapped in a divergence-flavoured name so future NS
    plans have a stable hook to invoke instead of dropping into the
    raw `fderiv` API.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms. -/
theorem divergence_add (v w : V → V)
    (hv : Differentiable ℝ v) (hw : Differentiable ℝ w) (x : V) :
    divergence (v + w) x = divergence v x + divergence w x := by
  simp only [divergence]
  have hsum : (v + w) = (fun y => v y + w y) := rfl
  rw [hsum, fderiv_add (hv x) (hw x)]
  simp only [ContinuousLinearMap.add_apply, PiLp.add_apply]
  exact Finset.sum_add_distrib

/-- **Linearity of divergence under scalar multiplication (trivial second brick).**

    For any real scalar `c : ℝ`, any `Differentiable ℝ` vector field
    `v : V → V`, and any point `x : V`,

      `div (c • v) (x) = c * div v (x)`.

    The proof is a one-line reduction to mathlib's
    `fderiv_const_smul` plus pulling the constant out of a finite
    sum (`Finset.mul_sum`). This lemma is **not** new mathematics —
    it is the trivial scalar-homogeneity of the Fréchet derivative
    wrapped in a divergence-flavoured name so future NS plans have a
    stable hook to invoke instead of dropping into the raw `fderiv`
    API.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms. -/
theorem divergence_smul (c : ℝ) (v : V → V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (c • v) x = c * divergence v x := by
  simp only [divergence]
  have hsmul : (c • v) = (fun y => c • v y) := rfl
  rw [hsmul, fderiv_const_smul (hv x) c]
  simp only [ContinuousLinearMap.smul_apply, PiLp.smul_apply, smul_eq_mul]
  rw [← Finset.mul_sum]

/-- **Divergence of the zero vector field is zero (trivial third brick).**

    For any point `x : V`,

      `div (0 : V → V) (x) = 0`.

    The proof is a one-line reduction to mathlib's `fderiv_const`
    (the Fréchet derivative of a constant function is the zero map),
    plus the fact that the zero continuous linear map evaluates to
    zero on any input and a sum of zeros is zero. This lemma is
    **not** new mathematics — it is the trivial degenerate case of
    the divergence operator on the zero vector field, wrapped in a
    divergence-flavoured name so future NS plans have a stable hook.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    NS tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    the third trio-clean divergence identity in Lean, nothing more.
    No claim of any PDE result, regularity, or energy bound. -/
theorem divergence_zero (x : V) : divergence (0 : V → V) x = 0 := by
  simp only [divergence]
  have h0 : (0 : V → V) = fun _ => (0 : V) := rfl
  rw [h0]
  simp [fderiv_const]

/-- **Divergence is odd under negation (trivial fourth brick).**

    For any vector field `v : V → V` and any point `x : V`,

      `div (-v) (x) = - div v (x)`.

    The proof is a one-line reduction to mathlib's `fderiv_neg`
    (which is **unconditional** — no `Differentiable` hypothesis
    needed, because the Fréchet derivative of `-f` is `-fderiv f`
    even when `f` is not differentiable, with both sides being `0`)
    plus pulling the minus through finite-sum distribution
    (`Finset.sum_neg_distrib`). This lemma is **not** new
    mathematics — it is the trivial sign-flip property of the
    Fréchet derivative wrapped in a divergence-flavoured name so
    future NS plans have a stable hook to invoke instead of dropping
    into the raw `fderiv` API. Together with `divergence_add` it
    yields `divergence_sub` as an immediate corollary on demand.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    NS tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    the fourth trio-clean divergence identity in Lean, nothing more.
    No claim of any PDE result, regularity, or energy bound. -/
theorem divergence_neg (v : V → V) (x : V) :
    divergence (-v) x = - divergence v x := by
  simp only [divergence]
  have hneg : (-v) = (fun y => -(v y)) := rfl
  rw [hneg, fderiv_neg]
  simp only [ContinuousLinearMap.neg_apply, PiLp.neg_apply]
  exact Finset.sum_neg_distrib

/-- **Divergence distributes over subtraction (trivial fifth brick).**

    For any two `Differentiable ℝ` vector fields `v w : V → V` and
    any point `x : V`,

      `div (v - w) (x) = div v (x) - div w (x)`.

    The proof is an immediate three-line corollary of the two
    earlier NS bricks: rewrite `v - w` as `v + (-w)`, apply
    `divergence_add` (which needs `Differentiable ℝ (-w)`, supplied
    by `hw.neg`), apply `divergence_neg` to fold the inner minus
    out, then close with `ring`. This lemma is **not** new
    mathematics — it is the trivial subtraction case of divergence
    linearity, derived from the two pieces already on the wall.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    NS tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    the fifth trio-clean divergence identity in Lean, nothing more.
    No claim of any PDE result, regularity, or energy bound. -/
theorem divergence_sub (v w : V → V)
    (hv : Differentiable ℝ v) (hw : Differentiable ℝ w) (x : V) :
    divergence (v - w) x = divergence v x - divergence w x := by
  have heq : (v - w) = v + (-w) := sub_eq_add_neg v w
  rw [heq, divergence_add v (-w) hv hw.neg, divergence_neg]
  ring

/-- **Divergence of any constant vector field is zero (trivial sixth brick).**

    For any constant vector `c : V` and any point `x : V`,

      `div (fun _ : V => c) (x) = 0`.

    The proof is a two-line reduction: rewrite with `fderiv_const`
    (the Fréchet derivative of a constant function is the zero
    continuous-linear-map), then let `simp` collapse the
    component-wise sum of zeros. This lemma is **not** new
    mathematics — it is the trivial constancy case of the
    divergence operator, generalising `divergence_zero` (which is
    the `c = 0` specialisation) and named so future NS plans have
    a stable hook for combining constant offsets with other
    divergence identities (e.g. `divergence_add_const`).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    NS tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    the sixth trio-clean divergence identity in Lean, nothing more.
    No claim of any PDE result, regularity, or energy bound. -/
theorem divergence_const (c : V) (x : V) :
    divergence (fun _ : V => c) x = 0 := by
  simp only [divergence]
  simp [fderiv_const]

/-- **Adding a constant vector field leaves divergence unchanged
    (seventh divergence brick).**

    For any differentiable vector field `v : V → V`, any constant
    `c : V`, and any point `x : V`,

      `div (v + fun _ => c) x = div v x`.

    The proof composes two real analytic facts: `divergence_add`
    (linearity in the first argument) and `divergence_const` (the
    divergence of a constant is zero). `add_zero` finishes.

    This is genuine analytic content, not a definitional trick:
    each step invokes a real mathlib derivative lemma
    (`fderiv_add`, `fderiv_const`).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This does **not** advance the NS
    tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    a constant-offset invariance of the divergence operator,
    nothing more. No claim of any PDE result, regularity, or
    energy bound. -/
theorem divergence_add_const (v : V → V) (c : V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (v + fun _ => c) x = divergence v x := by
  rw [divergence_add v (fun _ => c) hv (differentiable_const c),
      divergence_const, add_zero]

/-- **Subtracting a constant vector field leaves divergence unchanged
    (eighth divergence brick).**

    For any differentiable vector field `v : V → V`, any constant
    `c : V`, and any point `x : V`,

      `div (v - fun _ => c) x = div v x`.

    The proof composes `divergence_sub` and `divergence_const`,
    with `sub_zero` finishing. Companion to `divergence_add_const`.

    Genuine analytic content (each step uses a real mathlib
    derivative lemma), not a definitional trick.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This does **not** advance the NS
    tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It is
    a constant-offset invariance of the divergence operator,
    nothing more. No claim of any PDE result, regularity, or
    energy bound. -/
theorem divergence_sub_const (v : V → V) (c : V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (v - fun _ => c) x = divergence v x := by
  rw [divergence_sub v (fun _ => c) hv (differentiable_const c),
      divergence_const, sub_zero]

end NS
end Towers
end TheoremaAureum
