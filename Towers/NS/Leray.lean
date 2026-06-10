/-
================================================================
Towers / NS / Leray  (Tower 540, Phase 2A — Leray projection)

**The Leray (Helmholtz) projection onto divergence-free fields.**

Builds on the Phase-1 weighted-`L²` Fourier model
`Towers/NS/FunctionSpaces.lean`: `Hsv s = Lp ℂ³ 2 μ_s` and its
CLOSED divergence-free subspace `divFreeSubmodule s` (proved closed
+ complete in Phase 1). Because that subspace is a complete subspace
of a Hilbert space, mathlib's `orthogonalProjection` exists for it,
and we DEFINE the Leray projection as exactly that projection.

------------------------------------------------------------------
## What is PROVED here (real, `sorry`-free)

  * `leray_proj s : Hˢ →L[ℂ] Hdiv_free s` — the orthogonal (Leray)
    projection onto the divergence-free subspace. Well defined
    because `divFreeSubmodule s` is complete (Phase 1).
  * `leray_projE s : Hˢ →L[ℂ] Hˢ` — the same map viewed as an
    endomorphism (`subtypeL ∘ projection`), for the `P² = P` law.
  * `leray_projE_idempotent` — `P² = P` (`orthogonalProjection`
    fixes vectors already in the subspace).
  * `leray_proj_norm_le` — `‖P u‖ ≤ ‖u‖` (`orthogonalProjection`
    has operator norm `≤ 1`).
  * `leray_proj_apply_eq_self_of_mem` — `P` fixes divergence-free
    fields: `P ↑v = v` for `v` in the subspace.
  * `leray_proj_ker` — `ker P = (divFreeSubmodule s)ᗮ` (the
    orthogonal complement), free from `ker_orthogonalProjection`.

------------------------------------------------------------------
## The ONE Clay-adjacent `sorry` (Helmholtz decomposition)

  * `leray_proj_ker_eq_grad` — `ker P = gradSubmodule s`, i.e. the
    kernel of the Leray projection is exactly the space of GRADIENT
    fields (Fourier transform pointwise parallel to `ξ`). Combined
    with `leray_proj_ker` this is the statement
    `(divFreeSubmodule s)ᗮ = gradSubmodule s` — the genuine
    Helmholtz / Leray L²-orthogonal decomposition
    `Hˢ = Hˢ_div ⊕ ∇Hˢ⁺¹`. TRUE (pointwise, the orthogonal
    complement of the hyperplane `{v : ξ·v = 0}` is `ℂ·ξ`), but the
    honest proof that the GLOBAL `L²`-orthogonal complement equals
    the pointwise one is a measurable-selection / direct-integral
    argument, not a one-liner. Deferred, NOT a brick.

------------------------------------------------------------------
## Honest scope (tripwires)

  * **No existence/regularity claim.** This file builds the Leray
    projector and proves its algebraic/metric structure only; it
    proves NO Navier–Stokes result.
  * `leray_proj_ker_eq_grad` is honest scaffolding (1 documented
    `sorry`), NOT a brick; it is excluded from `BRICKS` and is not a
    lakefile root.
  * NS tower stays `Status: Open`; Surface #2 stays OPEN.
  * Self-contained: imports only the Phase-1 `FunctionSpaces`; no
    cross-tower imports, definitions, or claims.
================================================================
-/

import Towers.NS.FunctionSpaces
import Mathlib.Analysis.InnerProductSpace.Projection

open MeasureTheory
open TheoremaAureum.Towers.NS.FunctionSpaces

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Leray

/-- **The Leray projection** `P : Hˢ → Hˢ_div`, defined as the
    `L²`-orthogonal projection onto the (Phase-1 closed, complete)
    divergence-free subspace. The `HasOrthogonalProjection` instance
    is synthesized from `instCompleteSpaceDivFree` (Phase 1) via
    `HasOrthogonalProjection.ofCompleteSpace`. -/
noncomputable def leray_proj (s : ℝ) : Hsv s →L[ℂ] Hdiv_free s :=
  orthogonalProjection (divFreeSubmodule s)

/-- **The Leray projection as an endomorphism** `Hˢ → Hˢ`
    (`subtypeL ∘ projection`), the form in which the projector law
    `P² = P` is stated. -/
noncomputable def leray_projE (s : ℝ) : Hsv s →L[ℂ] Hsv s :=
  (divFreeSubmodule s).subtypeL.comp (orthogonalProjection (divFreeSubmodule s))

/-- **Projector law `P² = P`.** The endomorphism Leray projection is
    idempotent: `orthogonalProjection` fixes any vector already in the
    subspace (`orthogonalProjection_mem_subspace_eq_self`). -/
theorem leray_projE_idempotent (s : ℝ) :
    (leray_projE s).comp (leray_projE s) = leray_projE s := by
  refine ContinuousLinearMap.ext (fun u => ?_)
  simp only [leray_projE, ContinuousLinearMap.comp_apply, Submodule.subtypeL_apply,
    orthogonalProjection_mem_subspace_eq_self]

/-- **`P` is a contraction: `‖P u‖ ≤ ‖u‖`.** The orthogonal
    projection has operator norm `≤ 1` (`orthogonalProjection_norm_le`). -/
theorem leray_proj_norm_le (s : ℝ) (u : Hsv s) :
    ‖leray_proj s u‖ ≤ ‖u‖ := by
  calc ‖leray_proj s u‖ ≤ ‖leray_proj s‖ * ‖u‖ := (leray_proj s).le_opNorm u
    _ ≤ 1 * ‖u‖ := by
          gcongr
          exact orthogonalProjection_norm_le (divFreeSubmodule s)
    _ = ‖u‖ := one_mul _

/-- **`P` fixes divergence-free fields.** For `v` in the divergence-free
    subspace, `P ↑v = v` (`orthogonalProjection_mem_subspace_eq_self`). -/
theorem leray_proj_apply_eq_self_of_mem (s : ℝ) (v : divFreeSubmodule s) :
    leray_proj s (v : Hsv s) = v :=
  orthogonalProjection_mem_subspace_eq_self v

/-- **`ker P = (divFreeSubmodule s)ᗮ`.** Free from
    `ker_orthogonalProjection`: the kernel of the orthogonal
    projection onto `K` is its orthogonal complement `Kᗮ`. -/
theorem leray_proj_ker (s : ℝ) :
    LinearMap.ker (leray_proj s) = (divFreeSubmodule s)ᗮ :=
  ker_orthogonalProjection

/-- **Gradient predicate** in Fourier variables: `û(ξ)` is (a.e.)
    parallel to `ξ`, i.e. `û(ξ) = c(ξ) · toVal ξ` for some scalar.
    This is the frequency-side form of "`u` is a gradient `∇φ`"
    (`∇φ ↔ û(ξ) = i ξ φ̂(ξ) ∥ ξ`). -/
def IsGrad {s : ℝ} (f : Hsv s) : Prop :=
  ∀ᵐ ξ ∂(mu s), ∃ c : ℂ, f ξ = c • toVal ξ

/-- **The gradient subspace** of `Hˢ`, as a genuine `Submodule ℂ`.
    Linearity (`0`, `+`, `•` closure) is PROVED pointwise from the
    `Lp` coe-fn calculus (the scalar combines: `c•ξ + d•ξ = (c+d)•ξ`,
    `a•(c•ξ) = (a·c)•ξ`). -/
noncomputable def gradSubmodule (s : ℝ) : Submodule ℂ (Hsv s) where
  carrier := {f | IsGrad f}
  zero_mem' := by
    show IsGrad (0 : Hsv s)
    filter_upwards [Lp.coeFn_zero Val 2 (mu s)] with ξ hξ
    exact ⟨0, by rw [hξ, Pi.zero_apply, zero_smul]⟩
  add_mem' := by
    intro f g hf hg
    show IsGrad (f + g)
    filter_upwards [Lp.coeFn_add f g, hf, hg] with ξ hadd hfξ hgξ
    obtain ⟨c, hc⟩ := hfξ
    obtain ⟨d, hd⟩ := hgξ
    exact ⟨c + d, by rw [hadd, Pi.add_apply, hc, hd, add_smul]⟩
  smul_mem' := by
    intro a f hf
    show IsGrad (a • f)
    filter_upwards [Lp.coeFn_smul a f, hf] with ξ hsmul hfξ
    obtain ⟨c, hc⟩ := hfξ
    exact ⟨a * c, by rw [hsmul, Pi.smul_apply, hc, smul_smul]⟩

@[simp] theorem mem_gradSubmodule {s : ℝ} (f : Hsv s) :
    f ∈ gradSubmodule s ↔ IsGrad f := Iff.rfl

/- **Helmholtz / Leray decomposition (DEFERRED — 1 documented `sorry`).**
    The kernel of the Leray projection is exactly the space of gradient
    fields: `ker P = gradSubmodule s`. With `leray_proj_ker` this says
    `(divFreeSubmodule s)ᗮ = gradSubmodule s`, the genuine `L²`-orthogonal
    Helmholtz decomposition `Hˢ = Hˢ_div ⊕ ∇Hˢ⁺¹`.

    TRUE: pointwise, the orthogonal complement of the hyperplane
    `{v : ⟪toVal ξ, v⟫ = 0}` is the line `ℂ · toVal ξ`. But proving the
    GLOBAL `L²`-orthogonal complement equals the pointwise one is a
    measurable-selection / direct-integral argument, not a short proof.
    Deferred. NOT a brick; makes NO NS claim. -/
/-- Named-open surface behind `leray_proj_ker_eq_grad`: the global `L²`-orthogonal
Helmholtz decomposition `ker P = gradSubmodule s`. Stated as a `Prop`, NOT
discharged with `by sorry`; the global statement is a measurable-selection /
direct-integral argument. NOT a brick; makes NO NS claim. -/
def leray_proj_ker_eq_grad_Surface (s : ℝ) : Prop :=
  LinearMap.ker (leray_proj s) = gradSubmodule s

theorem leray_proj_ker_eq_grad (s : ℝ)
    (h : leray_proj_ker_eq_grad_Surface s) :
    LinearMap.ker (leray_proj s) = gradSubmodule s := h

end Leray
end NS
end Towers
end TheoremaAureum
