/-
================================================================
Towers / YM / SU3Basis  (Task #56 Path B, batch 1 of 3)

**The 8 anti-Hermitian Gell-Mann generators `iλ₁ … iλ₈` of su(3),
each proven to lie in `su3_submodule`.**

This file is the foundation for the downstream bricks
`su3_basis_def`, `su3_basis_linearIndependent`, `su3_basis_spans`
(batch 2, via `Basis.ofEquivFun` over a Gell-Mann LinearEquiv to
`Fin 8 → ℝ`), and `instance_inner_product_space_su3_euclidean`
(batch 3, via `InnerProductSpace.Core` on the same basis).

### Why the unnormalised `iλ₈`

Physics uses `λ₈ = (1/√3) · diag(1, 1, -2)`. We use
`gellMann₈ := !![I, 0, 0; 0, 0, 0; 0, 0, -I]` instead — all entries
in `{0, I, -I, 1, -1}`, no `√3`. This is still *a* basis for
`su3_submodule` (the two diagonal generators `gellMann₃`,
`gellMann₈` together span the same 2-dim real subspace of
diag-imaginary-traceless matrices that `λ₃, λ₈` do), so it gives a
valid `Basis (Fin 8) ℝ ↥su3_submodule` downstream. The cost is
that the resulting inner product is not the physics-normalised
`tr(A* B) / 2` — but the downstream IPS brick declares its own
inner product anyway, so nothing depends on this choice.

### Honest scope

`gellMann_k_mem` says: "this explicit 3×3 complex matrix is
anti-Hermitian and traceless." Nothing more. No statement about
Yang-Mills dynamics, the YM Hamiltonian, the mass-gap conjecture,
or any QFT. YM tower status remains **Open**
(`docs/ROADMAP.md` § 2). The bricks here are stepping stones to
giving `↥su3_submodule` the geometric structure (basis + inner
product) that the eventual `YMHamiltonian` schema concretization
will consume — they are NOT themselves a YM result.
================================================================
-/

import Mathlib.Data.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Algebra.Module.LinearMap.End
import Mathlib.Algebra.Module.Equiv.Basic
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.LinearAlgebra.Pi
import Mathlib.Analysis.InnerProductSpace.Basic
import Towers.YM.SU3

namespace TheoremaAureum
namespace Towers
namespace YM

open Matrix Complex

/-! ### The 8 Gell-Mann generators in anti-Hermitian form -/

/-- `iλ₁` — off-diagonal real-symmetric times `I` (slots (0,1)/(1,0)). -/
def gellMann₁ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, I, 0;
     I, 0, 0;
     0, 0, 0]

/-- `iλ₂` — off-diagonal real-skew (slots (0,1)/(1,0)). -/
def gellMann₂ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0,  1, 0;
     -1, 0, 0;
     0,  0, 0]

/-- `iλ₃` — diagonal `diag(I, -I, 0)`. -/
def gellMann₃ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0;
     0, -I, 0;
     0, 0, 0]

/-- `iλ₄` — off-diagonal real-symmetric times `I` (slots (0,2)/(2,0)). -/
def gellMann₄ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, I;
     0, 0, 0;
     I, 0, 0]

/-- `iλ₅` — off-diagonal real-skew (slots (0,2)/(2,0)). -/
def gellMann₅ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0,  0, 1;
     0,  0, 0;
     -1, 0, 0]

/-- `iλ₆` — off-diagonal real-symmetric times `I` (slots (1,2)/(2,1)). -/
def gellMann₆ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, 0;
     0, 0, I;
     0, I, 0]

/-- `iλ₇` — off-diagonal real-skew (slots (1,2)/(2,1)). -/
def gellMann₇ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0,  0;
     0, 0,  1;
     0, -1, 0]

/-- `iλ₈` (unnormalised) — diagonal `diag(I, 0, -I)`. -/
def gellMann₈ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0;
     0, 0, 0;
     0, 0, -I]

/-! ### Membership in `su3_submodule`

    For each generator we have to show:
    (i)  `star A = -A`  (anti-Hermitian: `Aᴴ = -A`)
    (ii) `Matrix.trace A = 0`

    The proof is a uniform tactic block:
      * unpack the iff via `su3_submodule_mem_iff`;
      * for (i), reduce to entry-by-entry equality with
        `ext i j; fin_cases i <;> fin_cases j` and close every case
        with `simp` over the matrix-literal cons/of unfolders and
        `Complex.conj_I`;
      * for (ii), use `Matrix.trace_fin_three` to expand to
        `A 0 0 + A 1 1 + A 2 2`, then simp away.

    `Matrix.star_apply` in mathlib v4.12.0 reduces
    `(star A) i j = star (A j i)`, which together with
    `Complex.conj_I : star I = -I` and the cons-of-cons unfolders
    closes every case.

    Axiom footprint target for each: subset of mathlib's classical
    trio `{propext, Classical.choice, Quot.sound}`. No new axioms.
-/

/-- Internal: the entry-by-entry `star = neg` tactic for an
    explicit 3×3 `!![...]` literal of `Matrix (Fin 3) (Fin 3) ℂ`.
    Takes the unfolder for the specific generator. -/
local macro "gellMann_antiHermitian_tac" name:ident : tactic =>
  `(tactic|
    (ext i j
     fin_cases i <;> fin_cases j <;>
       (simp [$name:ident, Matrix.star_apply, Matrix.neg_apply,
              Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.vecHead, Matrix.vecTail,
              Complex.conj_I, star_neg, star_one, star_zero,
              neg_neg, neg_zero] <;> rfl)))

/-- Internal: the trace-zero tactic for an explicit 3×3 `!![...]`
    literal. Takes the unfolder for the specific generator. -/
local macro "gellMann_traceless_tac" name:ident : tactic =>
  `(tactic|
    (simp [$name:ident, Matrix.trace_fin_three, Matrix.of_apply,
           Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
           Matrix.head_fin_const, Matrix.empty_val', Matrix.cons_val_fin_one,
           Matrix.vecHead, Matrix.vecTail] <;> rfl))

theorem gellMann₁_mem : gellMann₁ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₁
  · gellMann_traceless_tac gellMann₁

theorem gellMann₂_mem : gellMann₂ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₂
  · gellMann_traceless_tac gellMann₂

theorem gellMann₃_mem : gellMann₃ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₃
  · gellMann_traceless_tac gellMann₃

theorem gellMann₄_mem : gellMann₄ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₄
  · gellMann_traceless_tac gellMann₄

theorem gellMann₅_mem : gellMann₅ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₅
  · gellMann_traceless_tac gellMann₅

theorem gellMann₆_mem : gellMann₆ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₆
  · gellMann_traceless_tac gellMann₆

theorem gellMann₇_mem : gellMann₇ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₇
  · gellMann_traceless_tac gellMann₇

theorem gellMann₈_mem : gellMann₈ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₈
  · gellMann_traceless_tac gellMann₈

/-! ### Path B batch 2 v2 — the explicit `↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)` equiv

Where v1 failed: feeding `simp + linarith` an 8-term
`∑ cᵢ • LinearMap.smulRight _ gellMannᵢ` sum through
`LinearEquiv.ofLinear` + `Basis.ofEquivFun` blew past the default
200 000-heartbeat budget — `whnf` / `isDefEq` on `LinearMap.smulRight`
combinators expanded into a quadratic tree that mathlib v4.12.0
cannot fold in time.

v2 strategy:

* Replace the `LinearMap.smulRight` composition with **direct
  matrix sums**: `invFun c := ⟨c 0 • gellMann₁ + … + c 7 • gellMann₈,
  membership_proof⟩`, evaluated by `Matrix.add_apply` / `Matrix.smul_apply`
  alone. No `LinearMap`-combinator unfolding required.
* Use `set_option maxHeartbeats 1000000 in` as belt-and-braces (the
  per-entry simp+linarith block has 9 cases × 2 (re/im) = 18
  simp goals, each modest, but elaboration of the 8-term sum still
  needs headroom).
* Extract anti-Hermitian per-entry facts once (`hAH_app`) and the
  trace-zero fact once (`hTrim`), then `ext p q; fin_cases p; fin_cases q;
  Complex.ext` and close each leaf with `simp + linarith` over the
  small hypothesis bag.

### Honest scoping (Path B batch 3 deferred)

This batch lands `su3_equiv_fin8_def`, `su3_basis_def`,
`su3_basis_linearIndependent`, and `su3_basis_spans`. The two
remaining bricks from the user's batch 2 v2 spec —
`instance_normedSpace_su3_euclidean` and
`instance_inner_product_space_su3_euclidean` — are **deferred to
Path B batch 3** because `InnerProductSpace.induced` does not
exist in mathlib v4.12.0 (only `InnerProductSpace.ofCore` does,
via a 5-field `InnerProductSpace.Core` construction that doubles
the surface). Batch 3 will build the `Core` explicitly from the
EuclideanSpace inner product pulled back through this equiv. That
work is independent of and downstream of this batch.

These bricks claim ONLY: there is an ℝ-linear bijection between
the 8-dimensional real vector space `↥su3_submodule` of
anti-Hermitian traceless 3×3 complex matrices and `Fin 8 → ℝ`,
and the 8 Gell-Mann generators form a basis. They make no claim
about the YM Hamiltonian, the SU(3) Lie algebra structure constants
`f^{abc}`, the Killing form, the inner product structure on `su(3)`,
or the mass-gap conjecture. YM tower status unchanged: **Open**
(`docs/ROADMAP.md` § 2).
-/

set_option maxHeartbeats 4000000 in
/-- **The explicit ℝ-linear equivalence `↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)`
    (Path B batch 2 v2 brick 1).**

    Concrete `toFun` / `invFun` pair, no `LinearMap.smulRight`
    combinator chain — each direction is a direct expression in
    the underlying matrix entries (`toFun`) and a direct 8-term
    sum of `cᵢ • gellMannᵢ` (`invFun`). Coordinate convention:

      c₀ = (A 0 1).im      c₁ =  (A 0 1).re
      c₂ = -(A 1 1).im     c₃ =  (A 0 2).im
      c₄ = (A 0 2).re      c₅ =  (A 1 2).im
      c₆ = (A 1 2).re      c₇ = -(A 2 2).im

    The diagonal `c₀₀.im` is reconstructed from `-(c₂ + c₇) = -(-im₁₁ + -im₂₂)
    = im₁₁ + im₂₂`, which by trace-zero equals `-im₀₀` — hence
    LHS at (0,0) equals `im₀₀ • I = A 0 0`. The other entries
    follow by anti-Hermitian (`conj (A j i) = -A i j`) and the
    diagonal `(A k k).re = 0` corollary.

    Axiom footprint target: subset of mathlib's classical trio
    `{propext, Classical.choice, Quot.sound}`. No new axioms. -/
noncomputable def su3_equiv_fin8_def : ↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ) where
  toFun A i :=
    match i with
    | ⟨0, _⟩ => (A.val 0 1).im
    | ⟨1, _⟩ => (A.val 0 1).re
    | ⟨2, _⟩ => -(A.val 1 1).im
    | ⟨3, _⟩ => (A.val 0 2).im
    | ⟨4, _⟩ => (A.val 0 2).re
    | ⟨5, _⟩ => (A.val 1 2).im
    | ⟨6, _⟩ => (A.val 1 2).re
    | ⟨7, _⟩ => -(A.val 2 2).im
    | ⟨n + 8, h⟩ => absurd h (by omega)
  invFun c :=
    ⟨c 0 • gellMann₁ + c 1 • gellMann₂ + c 2 • gellMann₃ +
       c 3 • gellMann₄ + c 4 • gellMann₅ + c 5 • gellMann₆ +
       c 6 • gellMann₇ + c 7 • gellMann₈, by
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₈_mem)
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₇_mem)
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₆_mem)
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₅_mem)
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₄_mem)
        refine Submodule.add_mem _ ?_ (Submodule.smul_mem _ _ gellMann₃_mem)
        exact Submodule.add_mem _
                (Submodule.smul_mem _ _ gellMann₁_mem)
                (Submodule.smul_mem _ _ gellMann₂_mem)⟩
  map_add' A B := by
    funext i
    fin_cases i <;>
      (simp [Submodule.coe_add, Matrix.add_apply, Complex.add_re, Complex.add_im,
             neg_add] <;> ring)
  map_smul' r A := by
    funext i
    fin_cases i <;>
      simp [Submodule.coe_smul, Matrix.smul_apply, Complex.real_smul,
            Complex.mul_re, Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im,
            mul_zero, zero_mul, sub_zero, add_zero, mul_neg]
  left_inv A := by
    apply Subtype.ext
    obtain ⟨hAH, hTr⟩ := A.property
    -- Per-entry anti-Hermitian as re/im pair (avoid `conj` in the
    -- displayed type — simp on `star (A j i)` is reliable, simp on
    -- `conj (A j i)` triggered a `sorryAx` corruption in v4.12.0).
    have hAH_re : ∀ i j, (A.val j i).re = -(A.val i j).re := by
      intro i j
      have h : (star A.val) i j = (-A.val) i j := congrFun (congrFun hAH i) j
      rw [Matrix.star_apply, Matrix.neg_apply] at h
      have h2 := congrArg Complex.re h
      simpa using h2
    have hAH_im : ∀ i j, (A.val j i).im = (A.val i j).im := by
      intro i j
      have h : (star A.val) i j = (-A.val) i j := congrFun (congrFun hAH i) j
      rw [Matrix.star_apply, Matrix.neg_apply] at h
      have h2 := congrArg Complex.im h
      simpa using h2
    -- Diagonal real parts are zero.
    have hd00 : (A.val 0 0).re = 0 := by
      have h := hAH_re 0 0; linarith
    have hd11 : (A.val 1 1).re = 0 := by
      have h := hAH_re 1 1; linarith
    have hd22 : (A.val 2 2).re = 0 := by
      have h := hAH_re 2 2; linarith
    -- Off-diagonal anti-Hermitian relations.
    have h10re : (A.val 1 0).re = -(A.val 0 1).re := hAH_re 0 1
    have h10im : (A.val 1 0).im = (A.val 0 1).im := hAH_im 0 1
    have h20re : (A.val 2 0).re = -(A.val 0 2).re := hAH_re 0 2
    have h20im : (A.val 2 0).im = (A.val 0 2).im := hAH_im 0 2
    have h21re : (A.val 2 1).re = -(A.val 1 2).re := hAH_re 1 2
    have h21im : (A.val 2 1).im = (A.val 1 2).im := hAH_im 1 2
    -- Trace-zero on the imaginary part.
    have hTrim : (A.val 0 0).im + (A.val 1 1).im + (A.val 2 2).im = 0 := by
      rw [Matrix.trace_fin_three] at hTr
      have h := congrArg Complex.im hTr
      simpa [Complex.add_im, Complex.zero_im] using h
    -- Entry-by-entry matrix equality.
    ext p q
    fin_cases p <;> fin_cases q <;>
      (apply Complex.ext <;>
        simp [gellMann₁, gellMann₂, gellMann₃, gellMann₄, gellMann₅,
              gellMann₆, gellMann₇, gellMann₈,
              Matrix.add_apply, Matrix.smul_apply,
              Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.vecHead, Matrix.vecTail,
              Complex.real_smul, Complex.add_re, Complex.add_im,
              Complex.mul_re, Complex.mul_im, Complex.I_re, Complex.I_im,
              Complex.ofReal_re, Complex.ofReal_im, Complex.zero_re, Complex.zero_im,
              Complex.neg_re, Complex.neg_im] <;>
        linarith [hd00, hd11, hd22, h10re, h10im, h20re, h20im, h21re, h21im, hTrim])
  right_inv c := by
    funext i
    fin_cases i <;>
      simp [gellMann₁, gellMann₂, gellMann₃, gellMann₄, gellMann₅,
            gellMann₆, gellMann₇, gellMann₈,
            Matrix.add_apply, Matrix.smul_apply,
            Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero,
            Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
            Matrix.empty_val', Matrix.cons_val_fin_one,
            Matrix.vecHead, Matrix.vecTail,
            Complex.real_smul, Complex.add_re, Complex.add_im,
            Complex.mul_re, Complex.mul_im, Complex.I_re, Complex.I_im,
            Complex.ofReal_re, Complex.ofReal_im, Complex.zero_re, Complex.zero_im,
            Complex.neg_re, Complex.neg_im]

/-- **The Gell-Mann basis of `↥su3_submodule` (Path B batch 2 v2 brick 2).**

    Packages `su3_equiv_fin8_def` as a `Basis (Fin 8) ℝ ↥su3_submodule`
    via mathlib's `Basis.ofEquivFun`. Concretely the basis vector
    `b i` is the preimage of the i-th standard basis vector
    `Pi.single i 1 : Fin 8 → ℝ` — by construction these are
    `gellMann₁, …, gellMann₈` (as members of `↥su3_submodule`).

    Axiom footprint target: subset of mathlib's classical trio. -/
noncomputable def su3_basis_def : Basis (Fin 8) ℝ ↥su3_submodule :=
  Basis.ofEquivFun su3_equiv_fin8_def

/-- **Linear independence of the Gell-Mann basis (Path B batch 2 v2 brick 3).**

    Direct consequence of `Basis.linearIndependent` applied to
    `su3_basis_def`. -/
theorem su3_basis_linearIndependent :
    LinearIndependent ℝ (su3_basis_def : Fin 8 → ↥su3_submodule) :=
  su3_basis_def.linearIndependent

/-- **The Gell-Mann basis spans `↥su3_submodule` (Path B batch 2 v2 brick 4).**

    Direct consequence of `Basis.span_eq` applied to
    `su3_basis_def`: the ℝ-span of the 8 basis vectors fills the
    whole submodule. -/
theorem su3_basis_spans :
    Submodule.span ℝ (Set.range (su3_basis_def : Fin 8 → ↥su3_submodule)) = ⊤ :=
  su3_basis_def.span_eq

/-! ### Path B batch 3 — the `InnerProductSpace.Core ℝ ↥su3_submodule`

The Euclidean inner product on `Fin 8 → ℝ` pulled back through
`su3_equiv_fin8_def`. Because `InnerProductSpace.induced` does not
exist in mathlib v4.12.0, this batch builds the structure by hand
via the 5 explicit fields of `InnerProductSpace.Core` and feeds them
to `InnerProductSpace.ofCore`.

### Honest scope

This is the Euclidean inner product in the *unnormalised* Gell-Mann
coordinates (no `1/√3` on `λ₈`, no `1/2` overall, no `tr(A* B)`
formulation). It is `⟨A, B⟩ := ∑ᵢ cᵢ(A) cᵢ(B)` where the `cᵢ` are
the 8 coordinates extracted by `su3_equiv_fin8_def`. It is *a* real
inner product on the 8-dimensional ℝ-vector space
`↥su3_submodule`, but it is NOT the physics-normalised Killing form
`-tr(ad X ∘ ad Y) / N` and it is NOT the Frobenius inner product
`Re tr(X* Y)`. The downstream lattice-YM bricks (whenever those
land) declare the inner product they need; this is just the most
direct, basis-aligned construction that mathlib v4.12.0 can
accept without `induced`. YM tower status unchanged: **Open**
(`docs/ROADMAP.md` § 2).
-/

/-- **The Euclidean inner product on `↥su3_submodule` (Path B
    batch 3 brick 1).** Pulled back from `Fin 8 → ℝ` through
    `su3_equiv_fin8_def`. -/
noncomputable def inner_su3 (x y : ↥su3_submodule) : ℝ :=
  ∑ i, su3_equiv_fin8_def x i * su3_equiv_fin8_def y i

/-- **The Euclidean norm on `↥su3_submodule` (Path B batch 3
    brick 2).** Square root of `inner_su3 x x`. -/
noncomputable def norm_su3 (x : ↥su3_submodule) : ℝ :=
  Real.sqrt (inner_su3 x x)

/-- **Symmetry of `inner_su3` (Path B batch 3 brick 3).**
    `inner_su3 x y = inner_su3 y x`. Reduces to `mul_comm` on ℝ
    inside the sum. -/
theorem inner_su3_conj_symm (x y : ↥su3_submodule) :
    inner_su3 x y = inner_su3 y x := by
  unfold inner_su3
  exact Finset.sum_congr rfl (fun i _ => mul_comm _ _)

/-- **Additivity of `inner_su3` in the left slot (Path B batch 3
    brick 4).** Reduces to `add_mul` + `Finset.sum_add_distrib` after
    rewriting via the `LinearEquiv` `map_add` of `su3_equiv_fin8_def`. -/
theorem inner_su3_add_left (x y z : ↥su3_submodule) :
    inner_su3 (x + y) z = inner_su3 x z + inner_su3 y z := by
  unfold inner_su3
  have hadd : su3_equiv_fin8_def (x + y) = su3_equiv_fin8_def x + su3_equiv_fin8_def y :=
    su3_equiv_fin8_def.map_add x y
  simp only [hadd, Pi.add_apply, add_mul]
  exact Finset.sum_add_distrib

/-- **Scalar-multiplication compatibility of `inner_su3` in the
    left slot (Path B batch 3 brick 5).** Reduces to `mul_assoc`
    + `Finset.mul_sum` after rewriting via the `LinearEquiv`
    `map_smul`. -/
theorem inner_su3_smul_left (r : ℝ) (x y : ↥su3_submodule) :
    inner_su3 (r • x) y = r * inner_su3 x y := by
  unfold inner_su3
  have hsmul : su3_equiv_fin8_def (r • x) = r • su3_equiv_fin8_def x :=
    su3_equiv_fin8_def.map_smul r x
  simp only [hsmul, Pi.smul_apply, smul_eq_mul, mul_assoc]
  exact (Finset.mul_sum _ _ _).symm

/-- **The `InnerProductSpace.Core ℝ ↥su3_submodule` (Path B batch 3
    brick 6).** Packages the 5 bricks above into mathlib's
    `InnerProductSpace.Core` record. `nonneg_re` reduces to
    sum-of-squares ≥ 0; `definite` uses
    `Finset.sum_eq_zero_iff_of_nonneg` + `mul_self_eq_zero` +
    injectivity of `su3_equiv_fin8_def` to conclude `x = 0`.

    NOT registered as a global `instance` — that would shadow any
    pre-existing inner-product structure mathlib may have inferred
    on subtypes via other paths, and would constrain downstream
    lattice-YM bricks that may want a different normalisation. This
    is the explicit Core record any downstream user can feed to
    `InnerProductSpace.ofCore` when they want THIS construction.

    Axiom footprint target: subset of mathlib's classical trio
    `{propext, Classical.choice, Quot.sound}`. -/
noncomputable def instance_inner_product_space_su3_core :
    InnerProductSpace.Core ℝ ↥su3_submodule where
  inner x y := inner_su3 x y
  conj_symm x y := by
    -- On ℝ, `conj = id`, so the goal reduces to `inner_su3 y x = inner_su3 x y`.
    simp [inner_su3_conj_symm]
  nonneg_re x := by
    -- `inner_su3 x x = ∑ i, (cᵢ x)^2`, which is ≥ 0 termwise.
    show 0 ≤ inner_su3 x x
    unfold inner_su3
    exact Finset.sum_nonneg (fun i _ => mul_self_nonneg _)
  definite x hx := by
    -- `∑ (cᵢ x)^2 = 0` ⇒ each `cᵢ x = 0` ⇒ `equiv x = 0` ⇒ `x = 0`.
    have hsum : ∀ i ∈ Finset.univ,
        su3_equiv_fin8_def x i * su3_equiv_fin8_def x i = 0 := by
      refine (Finset.sum_eq_zero_iff_of_nonneg
        (fun i _ => mul_self_nonneg _)).mp ?_
      simpa [inner_su3] using hx
    have hzero : ∀ i, su3_equiv_fin8_def x i = 0 := by
      intro i
      have h := hsum i (Finset.mem_univ i)
      exact (mul_self_eq_zero.mp h)
    have heq : su3_equiv_fin8_def x = 0 := funext hzero
    -- Apply the inverse to recover `x = 0`.
    have : su3_equiv_fin8_def.symm (su3_equiv_fin8_def x)
         = su3_equiv_fin8_def.symm 0 := by rw [heq]
    simpa using this
  add_left x y z := inner_su3_add_left x y z
  smul_left x y r := by
    -- Goal: `inner_su3 (r • x) y = (starRingEnd ℝ) r * inner_su3 x y`.
    -- `starRingEnd ℝ` reduces to `id` on ℝ.
    simp [inner_su3_smul_left]

end YM
end Towers
end TheoremaAureum
