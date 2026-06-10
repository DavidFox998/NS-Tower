import Towers.YM.Wall261_H4Defect
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Algebra.Algebra.Spectrum
import Mathlib.Data.Matrix.Notation

/-!
# Wall263 — H4 Coxeter matrix: `φ` is the EDGE WEIGHT, not the spectral radius

This brick is the HONEST response to the proposal to "restate Wall261 using the
H4 Coxeter matrix instead of the 120-cell 1-skeleton", with the requested
theorem

  *the largest eigenvalue of `2I − M_H4` equals `φ = 2cos(π/5)`.*

That theorem is FALSE, and this file machine-checks why, without introducing any
`axiom` (the footprint stays the classical trio).

## The matrix

`M_H4` is the H4 Cartan/Gram matrix, so its "off-diagonal" companion is the
weighted-path adjacency matrix

  `B := 2·I − M_H4 = !![0,1,0,0; 1,0,1,0; 0,1,0,φ; 0,0,φ,0]`,

i.e. the H4 Coxeter diagram `o—o—o—(5)—o` whose three edges carry the weights
`2cos(π/3)=1`, `2cos(π/3)=1`, `2cos(π/5)=φ`. So `φ` is the WEIGHT on the
label-`5` edge — it is *an entry of the matrix*, NOT a spectral quantity.

## What is actually true

**The matrix bridge is now MACHINE-CHECKED.** mathlib v4.12.0 has no
`det_fin_four`, but the determinant is still computed *in Lean* by Laplace
cofactor expansion (`Matrix.det_succ_row_zero` down to `det_fin_zero`). So this
brick now DOES formalize the concrete matrix `B : Matrix (Fin 4) (Fin 4) ℝ`
(`B` below), proves its characteristic determinant equals the hand polynomial
(`det_charmatrix : det(λ·I − B) = coxeterCharpoly λ`), and concludes, via the
genuine `spectrum.not_mem_iff` + `isUnit_iff_isUnit_det` bridge, that `φ` is NOT
an eigenvalue (`phi_not_mem_spectrum : φ ∉ spectrum ℝ B`). What remains
DOCUMENTARY is only the *identity of the largest* eigenvalue ("the largest is
`2cos(π/30)`, the H4 Coxeter number `h = 30`") — we do not formalize the full
spectrum or its ordering — and the 120-cell / 600-cell geometry, which is not
constructed here.

`B` is symmetric tridiagonal, so its characteristic polynomial is, by the
standard three-term determinant recursion (now carried out *in Lean* — see
`det_charmatrix`),

  `det(λ·I − B) = λ⁴ − (2 + φ²)·λ² + φ²`  ( = `coxeterCharpoly λ` below ).

Setting `x = λ²` and solving `x² − (2+φ²)x + φ² = 0` gives the four eigenvalues
`±2cos(π/30)` and `±2cos(11π/30)`. The LARGEST is `2cos(π/30) ≈ 1.989` — the H4
Coxeter number is `h = 30` and the Perron eigenvalue of a Coxeter diagram is
always `2cos(π/h)`. It is NOT `φ = 2cos(π/5) ≈ 1.618`. (This largest-eigenvalue
reading stays DOCUMENTARY: the full spectrum is not formalized.)

`φ` is not even an eigenvalue of `B` — and this is now PROVEN in Lean
(`phi_not_mem_spectrum`): evaluating the characteristic determinant at `λ = φ`
gives `det(φ·I − B) = −φ² ≠ 0` (the quartic `φ⁴` cancels the `φ²·φ²` term
identically — `coxeterCharpoly_phi` is a pure `ring` identity, it does not even
use the golden-ratio relation), so `φ·I − B` is invertible and `φ ∉ spectrum ℝ B`.
`φ = 2cos(π/5)` *is* genuinely the largest eigenvalue of the UNWEIGHTED
`4`-vertex path (the `A₄` diagram), but that is a different matrix and is still
not a KP "effective degree".

## Why this does not (and cannot) close the SU(2) gap

The Kotecký–Preiss convergence constant is the connective constant / max degree
of the polymer incidence graph (`6` for `ℤ⁴` links, `12` for the 600-cell), NOT
a sub-dominant eigenvalue `≈ 1.618`. Replacing "degree" by `φ` is the unproven
leap. We record the honest reduction `defect_bound_H4` as a CONDITIONAL
combinator over TWO NAMED-OPEN hypotheses (the effective-degree bound and the
weighted-KP combinator) — both ordinary Lean hypotheses, NOT `axiom`s, so no new
axioms enter the footprint. This file proves NO YM result; YM stays
`Status: Open`.

All public theorems are `sorry`-free and `#print axioms` = the classical trio.
-/

namespace TheoremaAureum.Towers.YM.Wall263

open Real

/-- The characteristic polynomial of the H4 Coxeter matrix
`B = 2I − M_H4 = !![0,1,0,0; 1,0,1,0; 0,1,0,φ; 0,0,φ,0]` (the weighted path with
edge weights `1, 1, φ`), hand-computed by the standard symmetric-tridiagonal
determinant recursion:
`det(λ·I − B) = λ⁴ − (2 + φ²)·λ² + φ²`. -/
noncomputable def coxeterCharpoly (lam : ℝ) : ℝ :=
  lam ^ 4 - (2 + Wall261.phi ^ 2) * lam ^ 2 + Wall261.phi ^ 2

/-- GENUINE/UNCONDITIONAL: evaluating the H4 Coxeter characteristic polynomial at
`λ = φ` yields `−φ²`. The quartic term `φ⁴` cancels against `φ²·φ²` **identically**
— this is a pure `ring` fact and does not even invoke the golden-ratio identity
`φ² = φ + 1`. -/
theorem coxeterCharpoly_phi : coxeterCharpoly Wall261.phi = -(Wall261.phi ^ 2) := by
  unfold coxeterCharpoly
  ring

/-- GENUINE/UNCONDITIONAL: `φ` is NOT a root of `coxeterCharpoly` (the H4 Coxeter
characteristic polynomial): its value at `φ` is `−φ² < 0`. The
`coxeterCharpoly ↔ det(λ·I − B)` link is no longer hand-only — it is now
machine-checked in `det_charmatrix` below, and the eigenvalue-level reading "`φ`
is not an eigenvalue of `2I − M_H4`, a fortiori not the largest, refuting
'largest eigenvalue `= φ`'" is proved as `phi_not_mem_spectrum`. This lemma is
the polynomial-level statement `coxeterCharpoly φ ≠ 0` it rests on. -/
theorem phi_not_root : coxeterCharpoly Wall261.phi ≠ 0 := by
  rw [coxeterCharpoly_phi, neg_ne_zero]
  have h2 : 0 < Wall261.phi ^ 2 := by
    have := Wall261.phi_pos; nlinarith
  exact h2.ne'

/-! ### The matrix bridge (now machine-checked)

Previously the link between `coxeterCharpoly` and the actual matrix `B` was only
DOCUMENTARY. The following section closes that gap: `B` is now a concrete
`Matrix (Fin 4) (Fin 4) ℝ`, the `4×4` determinant `det(λ·I − B)` is proved
*in Lean* to equal `coxeterCharpoly λ` (`det_charmatrix`), and `φ ∉ spectrum ℝ B`
(`phi_not_mem_spectrum`) — i.e. `φ` is genuinely not an eigenvalue. mathlib
v4.12.0 has no `det_fin_four`, so the determinant is expanded by Laplace
cofactor expansion (`Matrix.det_succ_row_zero`) down to `det_fin_zero`; the
spectrum bridge is `spectrum.not_mem_iff` + `Matrix.isUnit_iff_isUnit_det` +
`isUnit_iff_ne_zero` over the field `ℝ`. -/

open Matrix in
/-- The H4 Coxeter companion matrix `B = 2I − M_H4`, as a concrete real `4×4`
matrix: the weighted path `o—o—o—(5)—o` with edge weights `1, 1, φ`. -/
noncomputable def B : Matrix (Fin 4) (Fin 4) ℝ :=
  !![0, 1, 0, 0;
     1, 0, 1, 0;
     0, 1, 0, Wall261.phi;
     0, 0, Wall261.phi, 0]

open Matrix in
/-- The characteristic matrix `λ·I − B` is the explicit symmetric tridiagonal
matrix `!![λ,-1,0,0; -1,λ,-1,0; 0,-1,λ,-φ; 0,0,-φ,λ]`. -/
theorem charmatrix_eq (lam : ℝ) :
    lam • (1 : Matrix (Fin 4) (Fin 4) ℝ) - B =
      !![lam, -1, 0, 0;
         -1, lam, -1, 0;
         0, -1, lam, -Wall261.phi;
         0, 0, -Wall261.phi, lam] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [B, Matrix.one_apply, Matrix.sub_apply, Matrix.smul_apply,
      Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_succ, Matrix.head_cons, Matrix.head_fin_const,
      Matrix.empty_val', Matrix.cons_val_fin_one, Matrix.of_apply,
      Matrix.vecHead, Matrix.vecTail]

open Matrix in
/-- GENUINE/UNCONDITIONAL (machine-checked, classical trio): the real `4×4`
determinant of the characteristic matrix `det(λ·I − B)` equals the hand-computed
characteristic polynomial `coxeterCharpoly λ = λ⁴ − (2+φ²)λ² + φ²`. This is the
bridge that was previously only DOCUMENTARY — the determinant is now computed
*in Lean* by Laplace cofactor expansion, not by hand. -/
theorem det_charmatrix (lam : ℝ) :
    (lam • (1 : Matrix (Fin 4) (Fin 4) ℝ) - B).det = coxeterCharpoly lam := by
  rw [charmatrix_eq]
  unfold coxeterCharpoly
  simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Matrix.submatrix_apply,
    Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
    Matrix.cons_val_succ, Matrix.head_cons, Matrix.head_fin_const,
    Matrix.empty_val', Matrix.cons_val_fin_one, Matrix.of_apply,
    Fin.succAbove, Fin.lt_def]
  ring

open Matrix in
/-- GENUINE/UNCONDITIONAL (machine-checked, classical trio): `det(φ·I − B) = −φ²`,
hence nonzero. The quartic `φ⁴` cancels `φ²·φ²` identically. -/
theorem det_charmatrix_phi :
    (Wall261.phi • (1 : Matrix (Fin 4) (Fin 4) ℝ) - B).det = -(Wall261.phi ^ 2) := by
  rw [det_charmatrix, coxeterCharpoly_phi]

open Matrix in
/-- GENUINE/UNCONDITIONAL (machine-checked, classical trio): `φ` is **not** an
eigenvalue of `B = 2I − M_H4`, i.e. `φ ∉ spectrum ℝ B`. This UPGRADES the
previously DOCUMENTARY eigenvalue reading to a Lean-checked fact: since
`det(φ·I − B) = −φ² ≠ 0`, the matrix `φ·I − B` is invertible, so `φ` is not in
the spectrum. It refutes "the largest eigenvalue of `2I − M_H4` equals `φ`" at
the eigenvalue level, a fortiori. (Which eigenvalue *is* largest — the Perron
value `2cos(π/30)` — is still DOCUMENTARY; we do not formalize the full spectrum
or its ordering here. No YM result is proved; YM stays `Status: Open`.) -/
theorem phi_not_mem_spectrum : Wall261.phi ∉ spectrum ℝ B := by
  rw [spectrum.not_mem_iff, Algebra.algebraMap_eq_smul_one,
      Matrix.isUnit_iff_isUnit_det, isUnit_iff_ne_zero, det_charmatrix_phi,
      neg_ne_zero]
  have h2 : 0 < Wall261.phi ^ 2 := by
    have := Wall261.phi_pos; nlinarith
  exact h2.ne'

/-- GENUINE/UNCONDITIONAL: `φ < 2`. Documentary context: the spectral radius of
`B` is the H4 Perron eigenvalue `2cos(π/30) ≈ 1.989`, which lies strictly between
`φ ≈ 1.618` and `2`; so the edge weight `φ` sits below the true spectral radius.
(No general "degree `≥ 2 ⟹` radius `≥ 2`" claim is made — that is FALSE, e.g. the
unweighted `A₄` path has max degree `2` and spectral radius exactly `φ < 2`.) What
is machine-checked here is only `φ < 2`. -/
theorem phi_lt_two : Wall261.phi < 2 := by
  have h5 : Real.sqrt 5 ^ 2 = 5 := Wall261.sqrt_five_sq
  have hnn : (0 : ℝ) ≤ Real.sqrt 5 := Real.sqrt_nonneg 5
  have hlt : Real.sqrt 5 < 3 := by nlinarith [h5, hnn]
  unfold Wall261.phi
  linarith

/-- GENUINE/UNCONDITIONAL: `1 < φ`. -/
theorem one_lt_phi : (1 : ℝ) < Wall261.phi := by
  have h5 : Real.sqrt 5 ^ 2 = 5 := Wall261.sqrt_five_sq
  have hnn : (0 : ℝ) ≤ Real.sqrt 5 := Real.sqrt_nonneg 5
  have hgt : (1 : ℝ) < Real.sqrt 5 := by nlinarith [h5, hnn]
  unfold Wall261.phi
  linarith

/-- HONEST CONDITIONAL (axiom-free, classical trio): the H4 "Coxeter-input" defect
bound, the faithful transcription of `apply KP_theorem_weighted H4_spectral_bound`
WITHOUT any `axiom`. Both inputs are NAMED-OPEN ordinary hypotheses, proved
NOWHERE:

* `h_spec` — the H4 "effective degree" bound `EffDeg x ≤ φ` (this is exactly the
  unproven leap; the real KP constant is the connective constant `≥ 6`, not `φ`);
* `h_kp` — the weighted Kotecký–Preiss combinator turning that spectral input into
  the defect bound.

`a ≤ exp(−22/25)` is the activity-domain hypothesis (`0.88 = 22/25`), kept to
mirror the requested signature. Proves NO YM result. -/
theorem defect_bound_H4
    {Defect R EffDeg : ℝ → ℝ} {a : ℝ}
    (_ha : a ≤ Real.exp (-(22 / 25)))
    (h_spec : ∀ x, EffDeg x ≤ Wall261.phi)
    (h_kp : (∀ x, EffDeg x ≤ Wall261.phi) →
      Defect a ≤ Real.log (1 + Wall261.phi * R a)) :
    Defect a ≤ Real.log (1 + Wall261.phi * R a) :=
  h_kp h_spec

end TheoremaAureum.Towers.YM.Wall263
