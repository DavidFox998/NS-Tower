/-
================================================================
Towers / YM / RiemannianGeometry  (Task #189 — REAL Killing-form
bi-invariant distance on SU(3), replacing the Task #170 `≡ 0`
stand-in.)

**STATUS: Open.** This file now ships a **genuine, point-separating,
bi-invariant** distance on SU(3) built from the Killing / trace
inner product on the ambient matrix algebra — replacing the
Task #170 placeholder `d_SU3 g h := 0`.

Concretely, with `↑g : Matrix (Fin 3) (Fin 3) ℂ` the underlying
matrix of `g : SU3` and `star · = ·ᴴ` the conjugate transpose,

  `hsNormSq M := (Matrix.trace (star M * M)).re`
              ` = ∑_{i,j} |M i j|²`   (Hilbert–Schmidt / Frobenius)

  `d_SU3 g h := Real.sqrt (hsNormSq (↑g - ↑h))`.

This is the **chordal distance** induced by the Hilbert–Schmidt
inner product `⟨A, B⟩ = tr(Aᴴ B)`, whose restriction to the Lie
algebra `𝔰𝔲(3)` is a positive multiple of the Killing form
(`B(X, Y) = 6 · tr(X Y)` on `𝔰𝔲(3)`, and `tr(Xᴴ Y) = -tr(X Y)`
for anti-Hermitian `X, Y`). It is a genuine metric: it separates
points, is symmetric, nonnegative, vanishes exactly on the
diagonal, and — because the Hilbert–Schmidt norm is invariant
under left/right multiplication by unitaries — it is **bi-invariant**
under the SU(3) group action. All five of these facts are proved
below as honest `rfl`-free theorems.

### What is real here (no stand-in)

  * `d_SU3` is **not** identically zero. For `g ≠ h` (as matrices)
    `hsNormSq (↑g - ↑h) > 0`, so `d_SU3 g h > 0`: the distance
    genuinely separates points.
  * `d_SU3_self`     — vanishes on the diagonal (real proof: `↑g - ↑g = 0`).
  * `d_SU3_nonneg`   — nonnegative (real proof: `Real.sqrt_nonneg`).
  * `d_SU3_symm`     — symmetric (real proof: `hsNormSq (-M) = hsNormSq M`).
  * `d_SU3_isPseudoDist`  — the three pseudo-distance clauses hold for
                            the real distance.
  * `d_SU3_isBiInvariant` — left- AND right-invariance under the
                            `Matrix.specialUnitaryGroup (Fin 3) ℂ`
                            multiplication, proved from
                            `star k * k = k * star k = 1` and the
                            cyclicity of the trace. This is the genuine
                            unitary-invariance of the Hilbert–Schmidt
                            norm, NOT a vacuous `0 = 0`.

### Drift from the Task #189 brief (honest, locked)

The Task #189 "Done looks like" line asked for the distance built
from the Killing-form inner product **and the Riemannian exponential
map** — i.e. the bi-invariant *geodesic* (Riemannian) distance
`d_g(g, h) = min { ‖X‖_B : exp(X) = g⁻¹h }`. What we ship is the
**chordal** distance `‖↑g - ↑h‖_HS` from the *same* Killing/trace
inner product, NOT the geodesic distance. The two agree
infinitesimally near the diagonal (and the chordal distance is the
honest, fully-constructible witness available in mathlib v4.12.0),
but they differ globally: the geodesic distance additionally
requires the matrix logarithm / Riemannian exponential map, the
cut-locus analysis of SU(3), and geodesic completeness — none of
which is in mathlib v4.12.0. So the genuine **geodesic** Killing
distance, and with it the genuine off-diagonal Varadhan / Molchanov
small-`t` asymptotic, remain the tripwire.

What the upgrade DOES achieve, relative to the Task #170 stand-in:
  * `d_SU3` is now a real metric that separates points — so the
    downstream geometric brick
    `Heat_kernel_envelope_real_le_varadhan_geometric` can no longer
    be proved for arbitrary `x` by collapsing `exp(-d²/4t)` to
    `exp 0 = 1`. Under the real distance the geometric envelope is
    only provable on the diagonal locus `{x : d_SU3 x 1 = 0} = {1}`,
    and the off-diagonal case is exactly the open Varadhan bound.
    That brick has therefore been re-stated with an explicit
    diagonal hypothesis `hx : d_SU3 x 1 = 0` (see
    `PeterWeylHeatVaradhan.lean`) — the substitution breaking the
    old `rfl` proof IS the tripwire the task describes.

### Honest scope (locked)

This file is **not**:
  * the bi-invariant *geodesic* Riemannian distance on SU(3)
    (needs the Riemannian exponential map / matrix log / cut-locus
    analysis, not in mathlib v4.12.0);
  * the off-diagonal Varadhan / Molchanov asymptotic itself
    (that bound is still open — the chordal distance does not
    discharge it);
  * a constructive 4D pure-Yang-Mills measure;
  * a mass-gap lower bound on any YM Hamiltonian.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2.

Axiom footprint
---------------
Depends only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Matrix.Notation
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Data.Real.Basic
import Mathlib.Data.Real.Archimedean
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum
namespace Towers
namespace YM
namespace RiemannianGeometry

/-- The SU(3) group as it appears throughout the YM tower. Same
abbreviation used by `Towers/YM/OffDiagKernel.lean` and
`Towers/YM/MassGap.lean` — kept locally for self-contained
elaboration of the bricks below. -/
abbrev SU3 : Type := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-! ## The Hilbert–Schmidt squared norm on 3×3 ℂ-matrices -/

/-- **`hsNormSq M`** — the Hilbert–Schmidt (Frobenius) squared norm
`tr(Mᴴ M) = ∑_{i,j} |M i j|²` of a 3×3 complex matrix, read off as a
real number via `.re` (the value is real because `tr(Mᴴ M)` is a
sum of squared magnitudes). This is the squared norm of the inner
product `⟨A, B⟩ = tr(Aᴴ B)` whose restriction to `𝔰𝔲(3)` is a
positive multiple of the Killing form. -/
noncomputable def hsNormSq (M : Matrix (Fin 3) (Fin 3) ℂ) : ℝ :=
  (Matrix.trace (star M * M)).re

/-! ## The real Killing-form (chordal) distance on SU(3) -/

/-- **`d_SU3 g h`** — the genuine bi-invariant chordal distance on
SU(3) induced by the Killing / Hilbert–Schmidt inner product:
`d_SU3 g h = ‖↑g - ↑h‖_HS = √(∑_{i,j} |g i j - h i j|²)`.

This REPLACES the Task #170 placeholder `d_SU3 ≡ 0`. It is a real
metric: nonnegative, symmetric, zero exactly on the diagonal, and
bi-invariant under the SU(3) action (Hilbert–Schmidt unitary
invariance). See the file docstring for the honest drift note: this
is the *chordal* distance from the Killing form, not the *geodesic*
Riemannian distance (which needs the Riemannian exponential map,
absent from mathlib v4.12.0). -/
noncomputable def d_SU3 (g h : SU3) : ℝ :=
  Real.sqrt (hsNormSq ((g : Matrix (Fin 3) (Fin 3) ℂ) - h))

/-! ## Helper lemmas on `hsNormSq` -/

/-- `hsNormSq` is invariant under negation: `hsNormSq (-M) = hsNormSq M`.
(The conjugate transpose distributes over the sign and the two signs
cancel.) -/
theorem hsNormSq_neg (M : Matrix (Fin 3) (Fin 3) ℂ) :
    hsNormSq (-M) = hsNormSq M := by
  unfold hsNormSq
  rw [star_neg, neg_mul_neg]

/-- **Left unitary invariance of `hsNormSq`.** If `star K * K = 1`
(i.e. `K` is unitary), then `hsNormSq (K * M) = hsNormSq M`. This is
`tr((KM)ᴴ (KM)) = tr(Mᴴ Kᴴ K M) = tr(Mᴴ M)`. -/
theorem hsNormSq_left (K M : Matrix (Fin 3) (Fin 3) ℂ)
    (hK : star K * K = 1) : hsNormSq (K * M) = hsNormSq M := by
  unfold hsNormSq
  congr 1
  rw [star_mul, mul_assoc, ← mul_assoc (star K) K M, hK, one_mul]

/-- **Right unitary invariance of `hsNormSq`.** If `K * star K = 1`
(i.e. `K` is unitary), then `hsNormSq (M * K) = hsNormSq M`. This is
`tr((MK)ᴴ (MK)) = tr(Kᴴ Mᴴ M K) = tr(Mᴴ M K Kᴴ) = tr(Mᴴ M)`, using
cyclicity of the trace. -/
theorem hsNormSq_right (M K : Matrix (Fin 3) (Fin 3) ℂ)
    (hK : K * star K = 1) : hsNormSq (M * K) = hsNormSq M := by
  unfold hsNormSq
  congr 1
  rw [star_mul, mul_assoc, Matrix.trace_mul_comm, mul_assoc, mul_assoc,
    hK, mul_one]

/-! ## Pseudo-distance predicate -/

/-- **`IsPseudoDistOnSU3 d`** — the three pseudo-distance properties:

  1. symmetric:        `d g h = d h g`
  2. nonneg:           `0 ≤ d g h`
  3. zero on diagonal: `d g g = 0`

The real `d_SU3` satisfies all three (proved in
`d_SU3_isPseudoDist`). Unlike the Task #170 stand-in, `d_SU3` is now
a *genuine* metric that also separates points (`d g h = 0 → g = h`
as matrices); we keep the predicate at the pseudo-distance level
because that is the interface the downstream bricks consume. -/
def IsPseudoDistOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  (∀ g h : SU3, d g h = d h g) ∧
  (∀ g h : SU3, 0 ≤ d g h) ∧
  (∀ g : SU3, d g g = 0)

/-- **`IsBiInvariantOnSU3 d`** — the two group-action clauses of a
genuine bi-invariant distance on SU(3):

  4. left-invariance:  `d (k * g) (k * h) = d g h`
  5. right-invariance: `d (g * k) (h * k) = d g h`

The real `d_SU3` satisfies both genuinely (proved in
`d_SU3_isBiInvariant`) — this is the Hilbert–Schmidt unitary
invariance, NOT a vacuous `0 = 0`. -/
def IsBiInvariantOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  (∀ k g h : SU3, d (k * g) (k * h) = d g h) ∧
  (∀ k g h : SU3, d (g * k) (h * k) = d g h)

/-! ## Bricks -/

/-- **Brick 1 (`d_SU3_self`).** The distance vanishes on the diagonal.
Real proof: `↑g - ↑g = 0`, `hsNormSq 0 = 0`, `√0 = 0`. -/
theorem d_SU3_self (g : SU3) : d_SU3 g g = 0 := by
  unfold d_SU3 hsNormSq
  rw [sub_self]
  simp only [star_zero, mul_zero, Matrix.trace_zero, Complex.zero_re,
    Real.sqrt_zero]

/-- **Brick 2 (`d_SU3_nonneg`).** The distance is nonnegative.
Real proof: `Real.sqrt_nonneg`. -/
theorem d_SU3_nonneg (g h : SU3) : 0 ≤ d_SU3 g h := by
  unfold d_SU3
  exact Real.sqrt_nonneg _

/-- **`d_SU3_symm`.** The distance is symmetric. Real proof:
`↑g - ↑h = -(↑h - ↑g)` and `hsNormSq` is negation-invariant. -/
theorem d_SU3_symm (g h : SU3) : d_SU3 g h = d_SU3 h g := by
  unfold d_SU3
  rw [show ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) = -((h : Matrix (Fin 3) (Fin 3) ℂ) - g) by
    rw [neg_sub], hsNormSq_neg]

/-- **Brick 3 (`d_SU3_isPseudoDist`).** The real `d_SU3` satisfies the
`IsPseudoDistOnSU3` predicate. Unlike the Task #170 stand-in, this is
NOT vacuous: symmetry comes from negation-invariance of the
Hilbert–Schmidt norm, nonnegativity from `Real.sqrt_nonneg`, and the
diagonal clause from `↑g - ↑g = 0`. -/
theorem d_SU3_isPseudoDist : IsPseudoDistOnSU3 d_SU3 := by
  refine ⟨?_, ?_, ?_⟩
  · intro g h; exact d_SU3_symm g h
  · intro g h; exact d_SU3_nonneg g h
  · intro g; exact d_SU3_self g

/-- **Brick 4 (`d_SU3_isBiInvariant`).** The real `d_SU3` is
bi-invariant under the `Matrix.specialUnitaryGroup (Fin 3) ℂ`
multiplication. This is the genuine Hilbert–Schmidt unitary
invariance: for `k ∈ SU(3)`, `star ↑k * ↑k = 1` and `↑k * star ↑k = 1`,
so left/right multiplication by `↑k` preserves the Hilbert–Schmidt
norm of `↑g - ↑h`. NOT a vacuous `0 = 0`. -/
theorem d_SU3_isBiInvariant : IsBiInvariantOnSU3 d_SU3 := by
  refine ⟨?_, ?_⟩
  · -- left-invariance
    intro k g h
    unfold d_SU3
    have hcoe : ((k * g : SU3) : Matrix (Fin 3) (Fin 3) ℂ) - ((k * h : SU3) : Matrix (Fin 3) (Fin 3) ℂ)
        = (k : Matrix (Fin 3) (Fin 3) ℂ) * ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) := by
      rw [Submonoid.coe_mul, Submonoid.coe_mul, mul_sub]
    have hK : star (k : Matrix (Fin 3) (Fin 3) ℂ) * (k : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
      Matrix.mem_unitaryGroup_iff'.mp (Matrix.mem_specialUnitaryGroup_iff.mp k.2).1
    rw [hcoe, hsNormSq_left _ _ hK]
  · -- right-invariance
    intro k g h
    unfold d_SU3
    have hcoe : ((g * k : SU3) : Matrix (Fin 3) (Fin 3) ℂ) - ((h * k : SU3) : Matrix (Fin 3) (Fin 3) ℂ)
        = ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) * (k : Matrix (Fin 3) (Fin 3) ℂ) := by
      rw [Submonoid.coe_mul, Submonoid.coe_mul, sub_mul]
    have hK : (k : Matrix (Fin 3) (Fin 3) ℂ) * star (k : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
      Matrix.mem_unitaryGroup_iff.mp (Matrix.mem_specialUnitaryGroup_iff.mp k.2).1
    rw [hcoe, hsNormSq_right _ _ hK]

/-! ## Metric predicate — separation + triangle (Task #209) -/

/-- **`IsMetricOnSU3 d`** — the full *metric* predicate on SU(3),
strengthening `IsPseudoDistOnSU3` with the two clauses a genuine
distance has that a mere pseudo-distance lacks:

  6. **separation:**  `d g h = 0 → g = h`   (points at distance `0` coincide)
  7. **triangle:**    `d g h ≤ d g k + d k h`

Together with the three pseudo-distance clauses (symmetry,
nonnegativity, zero-on-diagonal) repackaged via `IsPseudoDistOnSU3`,
this is exactly the predicate signature of the real Killing-form
geodesic distance on SU(3) — so the interface now matches the genuine
metric shape end-to-end.

**Honest scope (Task #209).** This task adds the predicate *clauses*;
it does NOT prove that the (chordal) `d_SU3` of Task #189 satisfies
them, and in particular constructs no real *geodesic* distance. What
it does pin down is the tripwire: the Task #170 stand-in `d_SU3 ≡ 0`
(here `fun _ _ => 0`) satisfies `IsPseudoDistOnSU3` *vacuously* but
provably FAILS the separation clause, because SU(3) is non-trivial —
see `not_IsMetricOnSU3_const_zero`. A distance that genuinely
separates points is a prerequisite before the off-diagonal Varadhan
brick can be promoted from synthetic to honest; the geodesic distance
and the triangle inequality for the real distance remain the open
tripwire (see the file docstring). -/
def IsMetricOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  IsPseudoDistOnSU3 d ∧
  (∀ g h : SU3, d g h = 0 → g = h) ∧
  (∀ g h k : SU3, d g h ≤ d g k + d k h)

/-! ## Nontriviality witness for SU(3) -/

/-- **`cWit`** — a concrete non-identity element of SU(3): the real
diagonal matrix `diag(-1, -1, 1)`. It is special-unitary (real
diagonal of unit-modulus entries ⇒ `M * Mᴴ = 1`; determinant
`(-1)·(-1)·1 = 1`) and differs from `1`. This witnesses that SU(3)
is non-trivial — exactly the fact the separation clause of
`IsMetricOnSU3` needs to rule out the `d ≡ 0` stand-in. Built with the
`!![…]` + `mem_specialUnitaryGroup_iff` + `fin_cases`/`simp`
matrix-literal idiom already used for `diagNegOneOneMat` in
`Towers/YM/MassGap.lean`. -/
noncomputable def cWit : SU3 :=
  ⟨!![(-1 : ℂ), 0, 0; 0, -1, 0; 0, 0, 1], by
    rw [Matrix.mem_specialUnitaryGroup_iff]
    refine ⟨?_, ?_⟩
    · rw [Matrix.mem_unitaryGroup_iff]
      ext i j
      fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Matrix.star_apply, Matrix.one_apply,
              Fin.sum_univ_three, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.of_apply, star_neg, star_one, star_zero]
    · rw [Matrix.det_fin_three]
      simp [Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
            Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
            Matrix.cons_val_fin_one, Matrix.of_apply]⟩

/-- The witness `cWit = diag(-1, -1, 1)` is not the identity of SU(3):
its `(0,0)` entry is `-1 ≠ 1`. -/
theorem cWit_ne_one : cWit ≠ (1 : SU3) := by
  intro h
  have h00 : (cWit : Matrix (Fin 3) (Fin 3) ℂ) 0 0
      = ((1 : SU3) : Matrix (Fin 3) (Fin 3) ℂ) 0 0 :=
    congrArg (fun g : SU3 => (g : Matrix (Fin 3) (Fin 3) ℂ) 0 0) h
  have hL : (cWit : Matrix (Fin 3) (Fin 3) ℂ) 0 0 = -1 := by
    simp [cWit, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
      Matrix.cons_val_fin_one, Matrix.of_apply]
  have hR : ((1 : SU3) : Matrix (Fin 3) (Fin 3) ℂ) 0 0 = 1 := by simp
  rw [hL, hR] at h00
  exact (by norm_num : (-1 : ℂ) ≠ 1) h00

/-! ## Tripwire brick -/

/-- **Brick 5 / Tripwire (`not_IsMetricOnSU3_const_zero`).** The
constant-zero stand-in distance `fun _ _ => 0` — the Task #170
placeholder `d_SU3 ≡ 0` — is NOT a metric on SU(3): it fails the
separation clause of `IsMetricOnSU3`. Indeed `cWit ≠ 1` (SU(3) is
non-trivial) yet the zero distance gives `(fun _ _ => 0) cWit 1 = 0`,
so the separation clause would force `cWit = 1`, a contradiction.

This is the honest tripwire the task describes: the pseudo-distance
predicate is satisfied vacuously by `d ≡ 0`, but the strengthened
metric predicate is NOT — any distance that genuinely separates points
(such as the real Killing-form distance) is required before the
off-diagonal Varadhan brick can be promoted from synthetic to honest.
Makes NO mass-gap / μ>0 / Surface-#1 claim; YM tower stays
`Status: Open`. -/
theorem not_IsMetricOnSU3_const_zero :
    ¬ IsMetricOnSU3 (fun _ _ : SU3 => (0 : ℝ)) := by
  rintro ⟨_, hsep, _⟩
  exact cWit_ne_one (hsep cWit 1 rfl)

/-! ## The chordal `d_SU3` is a genuine metric (Task #241)

This section discharges the two clauses `IsMetricOnSU3` adds over
`IsPseudoDistOnSU3` — **separation** (`d g h = 0 → g = h`) and the
**triangle inequality** (`d g h ≤ d g k + d k h`) — for the *real*
Task #189 chordal distance `d_SU3 g h = ‖↑g - ↑h‖_HS`, landing
`d_SU3_isMetric : IsMetricOnSU3 d_SU3`.

The proof routes the Hilbert–Schmidt squared norm `hsNormSq` through the
genuine `L²` structure of `EuclideanSpace ℂ (Fin 3 × Fin 3)`: the linear
embedding `toEuc M = (M i j)_{(i,j)}` satisfies `√(hsNormSq M) = ‖toEuc M‖`,
so separation is `norm_eq_zero` + injectivity of `toEuc` + injectivity of
the SU(3) → Matrix coercion, and the triangle inequality is the ambient
`dist_triangle`. This is a real metric inherited from the ambient normed
space — NOT a stand-in.

**Honest scope (locked).** This is the *chordal* (Hilbert–Schmidt) metric,
NOT the Killing-form *geodesic* distance (which still needs the Riemannian
exponential / cut-locus, absent from mathlib v4.12.0 — see the file
docstring and the Task #211 geodesic section below). It makes NO mass-gap /
μ>0 / Surface-#1 claim; YM tower stays `Status: Open`. Axiom footprint: the
classical trio `{propext, Classical.choice, Quot.sound}`. -/

/-- **`hsNormSq_eq_sum`.** The Hilbert–Schmidt squared norm is the entrywise
sum of squared magnitudes: `hsNormSq M = ∑_{i,j} ‖M i j‖²`. Read off from
`tr(Mᴴ M) = ∑_i ∑_k conj(M k i)·(M k i)`, taking real parts. -/
theorem hsNormSq_eq_sum (M : Matrix (Fin 3) (Fin 3) ℂ) :
    hsNormSq M = ∑ i, ∑ j, ‖M i j‖ ^ 2 := by
  have hz : ∀ z : ℂ, (star z * z).re = ‖z‖ ^ 2 := by
    intro z
    have hzz : star z * z = ((Complex.normSq z : ℝ) : ℂ) := by
      rw [Complex.star_def, Complex.normSq_eq_conj_mul_self]
    rw [hzz, Complex.ofReal_re, Complex.normSq_eq_abs, Complex.norm_eq_abs]
  unfold hsNormSq
  rw [Matrix.trace]
  simp only [Matrix.diag_apply, Matrix.mul_apply, Matrix.star_apply,
    Complex.re_sum, hz]
  exact Finset.sum_comm

/-- **`toEuc M`** — the linear embedding of a 3×3 complex matrix into the
`L²` space `EuclideanSpace ℂ (Fin 3 × Fin 3)`, sending `M` to the family of
its entries `(i,j) ↦ M i j`. Its norm is the Hilbert–Schmidt norm
(`sqrt_hsNormSq_eq_norm`), which lets us inherit separation and the triangle
inequality from the ambient `L²` space. -/
noncomputable def toEuc (M : Matrix (Fin 3) (Fin 3) ℂ) :
    EuclideanSpace ℂ (Fin 3 × Fin 3) :=
  (WithLp.equiv 2 (Fin 3 × Fin 3 → ℂ)).symm (fun ij => M ij.1 ij.2)

/-- The `(i,j)`-coordinate of `toEuc M` is `M i j`. -/
theorem toEuc_apply (M : Matrix (Fin 3) (Fin 3) ℂ) (ij : Fin 3 × Fin 3) :
    toEuc M ij = M ij.1 ij.2 := rfl

/-- `toEuc` distributes over subtraction (it is additive). -/
theorem toEuc_sub (A B : Matrix (Fin 3) (Fin 3) ℂ) :
    toEuc (A - B) = toEuc A - toEuc B := by
  ext ij
  simp only [toEuc_apply, PiLp.sub_apply, Matrix.sub_apply]

/-- **`sqrt_hsNormSq_eq_norm`.** The square root of the Hilbert–Schmidt
squared norm is the `L²` norm of the `EuclideanSpace` embedding:
`√(hsNormSq M) = ‖toEuc M‖`. -/
theorem sqrt_hsNormSq_eq_norm (M : Matrix (Fin 3) (Fin 3) ℂ) :
    Real.sqrt (hsNormSq M) = ‖toEuc M‖ := by
  rw [EuclideanSpace.norm_eq, hsNormSq_eq_sum, Fintype.sum_prod_type]
  simp only [toEuc_apply]

/-- `toEuc` is injective on the kernel: `toEuc M = 0 → M = 0`. -/
theorem toEuc_eq_zero {M : Matrix (Fin 3) (Fin 3) ℂ} (h : toEuc M = 0) :
    M = 0 := by
  ext i j
  have hz := congrArg (fun x : EuclideanSpace ℂ (Fin 3 × Fin 3) => x (i, j)) h
  simpa only [toEuc_apply] using hz

/-- **Separation for the chordal distance.** `d_SU3 g h = 0 → g = h`. From
`d_SU3 g h = ‖toEuc (↑g - ↑h)‖` (via `sqrt_hsNormSq_eq_norm`), `norm_eq_zero`
gives `toEuc (↑g - ↑h) = 0`, hence `↑g - ↑h = 0` (injectivity of `toEuc`),
hence `g = h` (injectivity of the SU(3) → Matrix coercion). -/
theorem d_SU3_sep (g h : SU3) (hgh : d_SU3 g h = 0) : g = h := by
  unfold d_SU3 at hgh
  rw [sqrt_hsNormSq_eq_norm, norm_eq_zero] at hgh
  have hM : (g : Matrix (Fin 3) (Fin 3) ℂ) - h = 0 := toEuc_eq_zero hgh
  exact Subtype.ext (sub_eq_zero.mp hM)

/-- **Triangle inequality for the chordal distance.**
`d_SU3 g h ≤ d_SU3 g k + d_SU3 k h`. Each chordal distance equals an `L²`
norm of a difference of `toEuc` images (`sqrt_hsNormSq_eq_norm` + `toEuc_sub`),
so the bound is the ambient `dist_triangle` in `EuclideanSpace`. -/
theorem d_SU3_triangle (g h k : SU3) :
    d_SU3 g h ≤ d_SU3 g k + d_SU3 k h := by
  have e : ∀ a b : SU3,
      d_SU3 a b = ‖toEuc (a : Matrix (Fin 3) (Fin 3) ℂ)
        - toEuc (b : Matrix (Fin 3) (Fin 3) ℂ)‖ := by
    intro a b
    unfold d_SU3
    rw [sqrt_hsNormSq_eq_norm, toEuc_sub]
  rw [e g h, e g k, e k h, ← dist_eq_norm, ← dist_eq_norm, ← dist_eq_norm]
  exact dist_triangle _ _ _

/-- **Brick (`d_SU3_isMetric`).** The real Task #189 chordal distance
`d_SU3 g h = ‖↑g - ↑h‖_HS` is a genuine metric on SU(3): it satisfies the
full `IsMetricOnSU3` predicate — the three pseudo-distance clauses
(`d_SU3_isPseudoDist`), separation (`d_SU3_sep`), and the triangle inequality
(`d_SU3_triangle`). This upgrades the heat-kernel envelope's distance from a
pseudo-distance to a real metric.

**Honest scope (locked).** This is the *chordal* metric, NOT the Killing-form
*geodesic* distance (still open — needs the Riemannian exponential / cut-locus,
absent from mathlib v4.12.0). It makes NO mass-gap / μ>0 / Surface-#1 claim;
YM tower stays `Status: Open`. -/
theorem d_SU3_isMetric : IsMetricOnSU3 d_SU3 :=
  ⟨d_SU3_isPseudoDist, d_SU3_sep, d_SU3_triangle⟩

/-! ## The genuine *geodesic* distance via the matrix exponential (Task #211)

This section upgrades the SU(3) distance machinery from the Task #189
*chordal* (Hilbert–Schmidt) distance `d_SU3` to a genuine **geodesic**
(Riemannian) distance `d_SU3_geodesic`, built from the *real* matrix
exponential map `NormedSpace.exp ℂ : Matrix (Fin 3) (Fin 3) ℂ → …`
(mathlib's `Mathlib.Analysis.Normed.Algebra.MatrixExponential`). This is
the "minimal exp-map dev" the Task #189 / #211 briefs called for: rather
than vendoring a bespoke Riemannian exp map, we reuse mathlib's
Banach-algebra matrix exponential and the bi-invariant Killing /
Hilbert–Schmidt length on the Lie algebra `𝔰𝔲(3)`.

### What is genuine here (no stand-in)

For a compact Lie group with a bi-invariant metric the geodesic
distance is the infimum of Killing-form lengths of Lie-algebra
logarithms:
`d_g(g, h) = inf { ‖X‖_B : X ∈ 𝔤, exp X = g⁻¹ h }`.
We implement exactly this:

  * `IsSU3Lie X`        — membership in `𝔰𝔲(3)` (`star X = -X` skew-Hermitian
                          and `trace X = 0`).
  * `geodesicLengths g h` — the set of Hilbert–Schmidt lengths
                          `√(hsNormSq X)` over Lie-algebra logarithms `X`
                          of `g⁻¹h = ↑gᴴ ↑h` (`exp X = star ↑g * ↑h`).
  * `d_SU3_geodesic g h := sInf (geodesicLengths g h)`.

and prove genuinely (NOT vacuously):

  * `d_SU3_geodesic_nonneg`  — `0 ≤ d_g` (`Real.sInf_nonneg`; every length is a `√`).
  * `d_SU3_geodesic_self`    — `d_g g g = 0` (`X = 0` is a genuine log:
                                `exp 0 = 1 = ↑gᴴ↑g` by unitarity; `√0 = 0`).
  * `d_SU3_geodesic_symm`    — `d_g g h = d_g h g`, from the genuine
                                involution `X ↦ -X` on logarithms
                                (`exp(-X) = (exp X)⁻¹ = ↑hᴴ↑g` via
                                `Matrix.exp_neg` + `Matrix.inv_eq_right_inv`),
                                which preserves `hsNormSq` (`hsNormSq_neg`)
                                — so the two length sets are *equal*.
  * `d_SU3_geodesic_le_of_mem` — the genuine infimum property: any actual
                                Lie-algebra log of `g⁻¹h` upper-bounds `d_g`.

### The relating (comparability) result

  * `d_SU3_eq_chordal_id`  — the chordal distance reduced to the identity:
                             `d_SU3 g h = √(hsNormSq (↑gᴴ↑h - 1))`, a genuine
                             bi-invariance fact (`hsNormSq_left` + `hsNormSq_neg`).
  * `d_SU3_geodesic_eq_d_SU3_diag` — both distances agree on the diagonal
                             (`d_g g g = d_SU3 g g = 0`), an unconditional
                             comparability point.
  * `d_SU3_le_geodesic_of_contracts` — the genuine comparability **bound**
                             `d_SU3 g h ≤ d_SU3_geodesic g h`, derived from
                             the differential-geometric contraction estimate
                             `‖exp X - 1‖_HS ≤ ‖X‖_HS` on `𝔰𝔲(3)`
                             (`ChordalContractsExp`) together with the
                             existence of a Lie-algebra logarithm
                             (`geodesicLengths g h` nonempty, i.e. surjectivity
                             of `exp` on the compact group SU(3)).

### Honest scope / remaining tripwire (locked)

The two hypotheses of `d_SU3_le_geodesic_of_contracts` are *exactly* the
open analytic inputs, made explicit as honest hypotheses (NOT `sorry`):

  1. `ChordalContractsExp` — true (for skew-Hermitian `X = U diag(iθⱼ) Uᴴ`,
     `‖exp X - 1‖²_HS = ∑ⱼ |e^{iθⱼ} - 1|² = ∑ⱼ 4 sin²(θⱼ/2) ≤ ∑ⱼ θⱼ² = ‖X‖²_HS`),
     but its Lean proof needs the spectral theorem for skew-Hermitian
     matrices — not pursued here.
  2. `(geodesicLengths g h).Nonempty` — true (`exp` is surjective onto the
     compact connected group SU(3)), but its Lean proof needs the
     surjectivity-of-exp theorem for compact Lie groups, absent from
     mathlib v4.12.0. Without it `sInf ∅ = 0`, so `d_SU3_geodesic` is only
     honestly a *pseudo*-distance lower scaffold off the diagonal — the
     deeper triangle inequality / cut-locus analysis remains the tripwire.

This section constructs the geodesic distance from the genuine exponential
map and proves every constructible clause; it makes NO mass-gap / μ>0 /
Surface-#1 claim. YM tower stays `Status: Open`. Axiom footprint: the
classical trio `{propext, Classical.choice, Quot.sound}`.
-/

/-- **`IsSU3Lie X`** — membership of a 3×3 complex matrix in the Lie
algebra `𝔰𝔲(3)` of SU(3): skew-Hermitian (`star X = -X`, i.e. `Xᴴ = -X`)
and traceless (`trace X = 0`). For such `X`, `exp X` is special-unitary
(`exp` of a skew-Hermitian matrix is unitary; tracelessness gives
`det (exp X) = exp (trace X) = 1`). -/
def IsSU3Lie (X : Matrix (Fin 3) (Fin 3) ℂ) : Prop :=
  star X = -X ∧ Matrix.trace X = 0

/-- **`geodesicLengths g h`** — the set of Hilbert–Schmidt lengths
`√(hsNormSq X)` of the Lie-algebra logarithms `X ∈ 𝔰𝔲(3)` of
`g⁻¹ h = ↑gᴴ ↑h` (those `X` with `exp X = star ↑g * ↑h`). The geodesic
distance is the infimum of this set. -/
noncomputable def geodesicLengths (g h : SU3) : Set ℝ :=
  { r : ℝ | ∃ X : Matrix (Fin 3) (Fin 3) ℂ,
      IsSU3Lie X ∧
      NormedSpace.exp ℂ X
        = star (g : Matrix (Fin 3) (Fin 3) ℂ) * (h : Matrix (Fin 3) (Fin 3) ℂ) ∧
      r = Real.sqrt (hsNormSq X) }

/-- **`d_SU3_geodesic g h`** — the genuine bi-invariant *geodesic*
(Riemannian) distance on SU(3): the infimum of Killing /
Hilbert–Schmidt lengths of the Lie-algebra logarithms of `g⁻¹h`,
`d_g(g, h) = inf { ‖X‖_HS : X ∈ 𝔰𝔲(3), exp X = ↑gᴴ↑h }`. Built from
mathlib's real matrix exponential `NormedSpace.exp ℂ` — NOT a stand-in.
See the section docstring for the honest scope: the contraction bound and
the surjectivity of `exp` (nonemptiness of `geodesicLengths`) remain the
open analytic inputs (stated as explicit hypotheses, not `sorry`). -/
noncomputable def d_SU3_geodesic (g h : SU3) : ℝ := sInf (geodesicLengths g h)

/-- Every geodesic length is nonnegative (it is a `Real.sqrt`). -/
theorem geodesicLengths_nonneg (g h : SU3) :
    ∀ r ∈ geodesicLengths g h, 0 ≤ r := by
  rintro r ⟨X, _, _, rfl⟩
  exact Real.sqrt_nonneg _

/-- `geodesicLengths g h` is bounded below (by `0`). -/
theorem geodesicLengths_bddBelow (g h : SU3) : BddBelow (geodesicLengths g h) :=
  ⟨0, fun r hr => geodesicLengths_nonneg g h r hr⟩

/-- **`d_SU3_geodesic_nonneg`.** The geodesic distance is nonnegative.
Genuine proof: every member of `geodesicLengths` is a `√ ≥ 0`, so
`Real.sInf_nonneg` applies (covering the empty case too, since
`sInf ∅ = 0`). -/
theorem d_SU3_geodesic_nonneg (g h : SU3) : 0 ≤ d_SU3_geodesic g h :=
  Real.sInf_nonneg _ (geodesicLengths_nonneg g h)

/-- `0` is a genuine geodesic length from `g` to itself: `X = 0` is a
Lie-algebra logarithm of `g⁻¹g = 1` (`exp 0 = 1 = ↑gᴴ↑g` by unitarity)
with `√(hsNormSq 0) = 0`. -/
theorem zero_mem_geodesicLengths_self (g : SU3) :
    (0 : ℝ) ∈ geodesicLengths g g := by
  refine ⟨0, ⟨by rw [star_zero, neg_zero], by rw [Matrix.trace_zero]⟩, ?_, ?_⟩
  · rw [NormedSpace.exp_zero]
    exact (Matrix.mem_unitaryGroup_iff'.mp
      (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1).symm
  · rw [hsNormSq]; simp

/-- **`d_SU3_geodesic_self`.** The geodesic distance vanishes on the
diagonal. Genuine proof: `0 ∈ geodesicLengths g g` (the logarithm `X = 0`)
and the set is bounded below by `0`, so `sInf = 0`. -/
theorem d_SU3_geodesic_self (g : SU3) : d_SU3_geodesic g g = 0 := by
  refine le_antisymm ?_ (d_SU3_geodesic_nonneg g g)
  exact csInf_le (geodesicLengths_bddBelow g g) (zero_mem_geodesicLengths_self g)

/-- The genuine involution `X ↦ -X` carries a Lie-algebra logarithm of
`g⁻¹h` to one of `h⁻¹g`, preserving the Hilbert–Schmidt length. Hence the
length sets satisfy `geodesicLengths g h ⊆ geodesicLengths h g`. Key step:
`exp (-X) = (exp X)⁻¹ = (↑gᴴ↑h)⁻¹ = ↑hᴴ↑g` (`Matrix.exp_neg` +
`Matrix.inv_eq_right_inv` from the unitary relations). -/
theorem geodesicLengths_subset_symm (g h : SU3) :
    geodesicLengths g h ⊆ geodesicLengths h g := by
  rintro r ⟨X, ⟨hsk, htr⟩, hexp, rfl⟩
  refine ⟨-X, ⟨by rw [star_neg, hsk, neg_neg], by rw [Matrix.trace_neg, htr, neg_zero]⟩,
    ?_, by rw [hsNormSq_neg]⟩
  rw [Matrix.exp_neg ℂ, hexp]
  refine Matrix.inv_eq_right_inv ?_
  have hg1 : star (g : Matrix (Fin 3) (Fin 3) ℂ) * (g : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
    Matrix.mem_unitaryGroup_iff'.mp (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1
  have hh1 : (h : Matrix (Fin 3) (Fin 3) ℂ) * star (h : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
    Matrix.mem_unitaryGroup_iff.mp (Matrix.mem_specialUnitaryGroup_iff.mp h.2).1
  rw [mul_assoc (star (g : Matrix (Fin 3) (Fin 3) ℂ)) (h : Matrix (Fin 3) (Fin 3) ℂ)
        (star (h : Matrix (Fin 3) (Fin 3) ℂ) * (g : Matrix (Fin 3) (Fin 3) ℂ)),
      ← mul_assoc (h : Matrix (Fin 3) (Fin 3) ℂ) (star (h : Matrix (Fin 3) (Fin 3) ℂ))
        (g : Matrix (Fin 3) (Fin 3) ℂ), hh1, one_mul, hg1]

/-- The geodesic length sets of `(g, h)` and `(h, g)` are equal (by the
`X ↦ -X` involution in both directions). -/
theorem geodesicLengths_symm (g h : SU3) :
    geodesicLengths g h = geodesicLengths h g :=
  Set.Subset.antisymm (geodesicLengths_subset_symm g h) (geodesicLengths_subset_symm h g)

/-- **`d_SU3_geodesic_symm`.** The geodesic distance is symmetric — genuine
proof, from equality of the two length sets via the `X ↦ -X` involution. -/
theorem d_SU3_geodesic_symm (g h : SU3) : d_SU3_geodesic g h = d_SU3_geodesic h g := by
  unfold d_SU3_geodesic
  rw [geodesicLengths_symm]

/-- **`d_SU3_eq_chordal_id`** (chordal bi-invariance reduction). The
chordal distance is the chordal distance from the identity to
`g⁻¹h = ↑gᴴ↑h`:
`d_SU3 g h = √(hsNormSq (↑gᴴ↑h - 1))`.
Genuine proof from left unitary invariance of `hsNormSq` (`hsNormSq_left`
with `K = ↑gᴴ`) and `hsNormSq_neg`. This is the structural bridge to the
geodesic distance, whose logarithms `X` satisfy `exp X = ↑gᴴ↑h`. -/
theorem d_SU3_eq_chordal_id (g h : SU3) :
    d_SU3 g h = Real.sqrt (hsNormSq
      (star (g : Matrix (Fin 3) (Fin 3) ℂ) * (h : Matrix (Fin 3) (Fin 3) ℂ) - 1)) := by
  unfold d_SU3
  have hgK : star (star (g : Matrix (Fin 3) (Fin 3) ℂ)) * star (g : Matrix (Fin 3) (Fin 3) ℂ) = 1 := by
    rw [star_star]
    exact Matrix.mem_unitaryGroup_iff.mp (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1
  have hgg : star (g : Matrix (Fin 3) (Fin 3) ℂ) * (g : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
    Matrix.mem_unitaryGroup_iff'.mp (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1
  rw [← hsNormSq_left (star (g : Matrix (Fin 3) (Fin 3) ℂ))
        ((g : Matrix (Fin 3) (Fin 3) ℂ) - h) hgK]
  congr 1
  rw [mul_sub, hgg,
      ← neg_sub (star (g : Matrix (Fin 3) (Fin 3) ℂ) * (h : Matrix (Fin 3) (Fin 3) ℂ)) 1,
      hsNormSq_neg]

/-- **`d_SU3_geodesic_le_of_mem`** (genuine infimum property). Any actual
Lie-algebra logarithm `X` of `g⁻¹h` (i.e. `X ∈ 𝔰𝔲(3)` with
`exp X = ↑gᴴ↑h`) upper-bounds the geodesic distance:
`d_SU3_geodesic g h ≤ √(hsNormSq X)`. -/
theorem d_SU3_geodesic_le_of_mem (g h : SU3) (X : Matrix (Fin 3) (Fin 3) ℂ)
    (hX : IsSU3Lie X)
    (hexp : NormedSpace.exp ℂ X
      = star (g : Matrix (Fin 3) (Fin 3) ℂ) * (h : Matrix (Fin 3) (Fin 3) ℂ)) :
    d_SU3_geodesic g h ≤ Real.sqrt (hsNormSq X) :=
  csInf_le (geodesicLengths_bddBelow g h) ⟨X, hX, hexp, rfl⟩

/-- **`d_SU3_geodesic_eq_d_SU3_diag`** (unconditional comparability on the
diagonal). The geodesic and chordal distances agree on the diagonal: both
vanish. -/
theorem d_SU3_geodesic_eq_d_SU3_diag (g : SU3) :
    d_SU3_geodesic g g = d_SU3 g g := by
  rw [d_SU3_geodesic_self, d_SU3_self]

/-- **`ChordalContractsExp`** — the differential-geometric contraction
estimate `‖exp X - 1‖²_HS ≤ ‖X‖²_HS` for every `X ∈ 𝔰𝔲(3)`. True (for
skew-Hermitian `X` diagonalisable with imaginary spectrum `iθⱼ`,
`‖exp X - 1‖²_HS = ∑ⱼ |e^{iθⱼ} - 1|² = ∑ⱼ 4 sin²(θⱼ/2) ≤ ∑ⱼ θⱼ² = ‖X‖²_HS`),
but its Lean proof needs the spectral theorem for skew-Hermitian matrices,
beyond this task. Stated as an honest hypothesis (NOT a `sorry`) so the
comparability bound below is a genuine *reduction*. -/
def ChordalContractsExp : Prop :=
  ∀ X : Matrix (Fin 3) (Fin 3) ℂ, IsSU3Lie X →
    hsNormSq (NormedSpace.exp ℂ X - 1) ≤ hsNormSq X

/-- **`d_SU3_le_geodesic_of_contracts`** (genuine comparability bound /
reduction). The chordal distance is dominated by the geodesic distance,
`d_SU3 g h ≤ d_SU3_geodesic g h`, given the two open analytic inputs as
explicit hypotheses:

  * `hcontr : ChordalContractsExp` — the contraction bound `‖exp X - 1‖_HS ≤ ‖X‖_HS`;
  * `hne : (geodesicLengths g h).Nonempty` — existence of a Lie-algebra
    logarithm (surjectivity of `exp` onto compact connected SU(3)).

Genuine reduction proof: `d_SU3 g h = √(hsNormSq (↑gᴴ↑h - 1))` by
`d_SU3_eq_chordal_id`; for any log `X` of `↑gᴴ↑h` the contraction gives
`hsNormSq (exp X - 1) ≤ hsNormSq X`, hence `√(…) ≤ √(hsNormSq X)`; taking
the infimum (`le_csInf`, using `hne`) over all logs yields the bound. No
`sorry`; the two hypotheses are the honest tripwire (see section docstring). -/
theorem d_SU3_le_geodesic_of_contracts
    (hcontr : ChordalContractsExp) (g h : SU3)
    (hne : (geodesicLengths g h).Nonempty) :
    d_SU3 g h ≤ d_SU3_geodesic g h := by
  rw [d_SU3_eq_chordal_id]
  apply le_csInf hne
  rintro r ⟨X, hX, hexp, rfl⟩
  rw [← hexp]
  exact Real.sqrt_le_sqrt (hcontr X hX)

end RiemannianGeometry
end YM
end Towers
end TheoremaAureum
