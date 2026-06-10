/-
Wilson Action Positivity for SU(2) — the N = 2 companion to
`Towers/YM/WilsonPositivity.lean`.

HONEST SCOPE — a real, `sorry`-free brick, but explicitly NOT a mass-gap
claim and NOT an SU(2)-specific result:
  This file proves, for a 2×2 unitary matrix `A` (`star A * A = 1`):
    * `Re (tr A) ≤ 2`           (upper character bound at N = 2),
    * `Re (tr A) = 2 ↔ A = 1`   (equality case),
  and the resulting per-plaquette Wilson energy `(2 − Re tr P)/2 ≥ 0`,
  `> 0 ↔ P ≠ 1`.

WHY THIS EXISTS — a transparency exhibit, not new physics:
  These are the verbatim N = 2 instances of the N = 3 bricks in
  `WilsonPositivity.lean`. The proof route is identical: the
  Hilbert–Schmidt identity `hsNormSq (A − 1) = 2N − 2·Re tr A`
  (here `4 − 2·Re tr A`; the SU(3) file has `6 − 2·Re tr A`) plus
  `0 ≤ hsNormSq` and `hsNormSq M = 0 ↔ M = 0`.

  The fact that the SU(3) proof ports unchanged to N = 2 is exactly the
  point: this content is GENERIC linear algebra. It uses ONLY unitarity
  (`star A * A = 1`) — it never uses `det = 1`, so it is not even
  SU-specific, let alone SU(3)- or SU(2)-specific, and it is N-generic.
  It therefore bears on NO group-specific structure and on NOTHING about
  the Yang–Mills mass gap.

INVARIANT-LOCKED:
  * Makes NO mass-gap / μ>0 / Surface-#1-CLOSED claim. Surface #1 stays
    OPEN, YM `Status: Open`. The genuine gap remains the disclaimed
    `Transfer.kotecky_preiss_criterion` `sorry`, untouched by this file.
  * Every declaration is `sorry`-free; axiom footprint is the classical
    trio `{propext, Classical.choice, Quot.sound}`.
-/
import Towers.YM.RiemannianGeometry

namespace TheoremaAureum.Towers.YM.LatticeGauge

open Matrix Complex

/-- **`hsNormSq2 M`** — the Hilbert–Schmidt squared norm `tr(Mᴴ M).re`
    of a `2×2` complex matrix (the N = 2 analogue of
    `RiemannianGeometry.hsNormSq`). -/
noncomputable def hsNormSq2 (M : Matrix (Fin 2) (Fin 2) ℂ) : ℝ :=
  (Matrix.trace (star M * M)).re

/-- `hsNormSq2 M = ∑_{i,j} |M i j|² ≥ 0` (explicit `Fin 2` expansion). -/
theorem hsNormSq2_nonneg (M : Matrix (Fin 2) (Fin 2) ℂ) :
    0 ≤ hsNormSq2 M := by
  unfold hsNormSq2
  rw [Matrix.trace_fin_two]
  simp only [Matrix.mul_apply, Matrix.star_apply, Fin.sum_univ_two,
    Complex.star_def, ← Complex.normSq_eq_conj_mul_self,
    Complex.add_re, Complex.ofReal_re]
  linarith [Complex.normSq_nonneg (M 0 0), Complex.normSq_nonneg (M 1 0),
    Complex.normSq_nonneg (M 0 1), Complex.normSq_nonneg (M 1 1)]

/-- The HS squared norm of a `2×2` matrix vanishes iff the matrix is zero. -/
theorem hsNormSq2_eq_zero_iff (M : Matrix (Fin 2) (Fin 2) ℂ) :
    hsNormSq2 M = 0 ↔ M = 0 := by
  constructor
  · intro h
    unfold hsNormSq2 at h
    rw [Matrix.trace_fin_two] at h
    simp only [Matrix.mul_apply, Matrix.star_apply, Fin.sum_univ_two,
      Complex.star_def, ← Complex.normSq_eq_conj_mul_self, Complex.add_re,
      Complex.ofReal_re] at h
    have n00 := Complex.normSq_nonneg (M 0 0)
    have n01 := Complex.normSq_nonneg (M 0 1)
    have n10 := Complex.normSq_nonneg (M 1 0)
    have n11 := Complex.normSq_nonneg (M 1 1)
    have e00 : M 0 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e01 : M 0 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e10 : M 1 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e11 : M 1 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    refine Matrix.ext fun i j => ?_
    fin_cases i <;> fin_cases j <;> simp_all
  · rintro rfl
    simp [hsNormSq2]

/-- For a unitary `2×2` matrix `A`, `hsNormSq2 (A − 1) = 4 − 2·Re(tr A)`
    (= `2N − 2·Re tr A` with N = 2). -/
theorem hsNormSq2_sub_one_eq (A : Matrix (Fin 2) (Fin 2) ℂ)
    (hA : star A * A = 1) :
    hsNormSq2 (A - 1) = 4 - 2 * (Matrix.trace A).re := by
  unfold hsNormSq2
  have hstar : star (A - 1) = star A - 1 := by rw [star_sub, star_one]
  have he : star (A - 1) * (A - 1) = star A * A - star A - A + 1 := by
    rw [hstar, sub_mul, mul_sub, mul_sub, mul_one, one_mul, mul_one]
    abel
  rw [he, hA]
  simp only [Matrix.trace_add, Matrix.trace_sub, Matrix.trace_one,
    Matrix.star_eq_conjTranspose, Matrix.trace_conjTranspose,
    Fintype.card_fin, Complex.add_re, Complex.sub_re, Complex.star_def,
    Complex.conj_re, Complex.natCast_re]
  push_cast
  ring

/-- **Upper character bound at N = 2.** `Re tr A ≤ 2` for unitary `A`. -/
theorem traceRe_le_two (A : Matrix (Fin 2) (Fin 2) ℂ)
    (hA : star A * A = 1) : (Matrix.trace A).re ≤ 2 := by
  have h0 := hsNormSq2_nonneg (A - 1)
  rw [hsNormSq2_sub_one_eq A hA] at h0
  linarith

/-- **Equality case at N = 2.** `Re tr A = 2 ↔ A = 1` for unitary `A`. -/
theorem traceRe_eq_two_iff (A : Matrix (Fin 2) (Fin 2) ℂ)
    (hA : star A * A = 1) : (Matrix.trace A).re = 2 ↔ A = 1 := by
  have key : A = 1 ↔ hsNormSq2 (A - 1) = 0 := by
    rw [hsNormSq2_eq_zero_iff, sub_eq_zero]
  rw [key, hsNormSq2_sub_one_eq A hA]
  constructor <;> intro h <;> linarith

/-- Per-plaquette Wilson energy at N = 2: `(2 − Re tr P)/2`. -/
noncomputable def plaquetteEnergy2 (P : Matrix (Fin 2) (Fin 2) ℂ) : ℝ :=
  (2 - (Matrix.trace P).re) / 2

/-- The N = 2 per-plaquette energy is non-negative for unitary `P`. -/
theorem plaquetteEnergy2_nonneg (P : Matrix (Fin 2) (Fin 2) ℂ)
    (hP : star P * P = 1) : 0 ≤ plaquetteEnergy2 P := by
  unfold plaquetteEnergy2
  have hb := traceRe_le_two P hP
  exact div_nonneg (by linarith) (by norm_num)

/-- The N = 2 per-plaquette energy is strictly positive iff `P ≠ 1`. -/
theorem plaquetteEnergy2_pos_iff (P : Matrix (Fin 2) (Fin 2) ℂ)
    (hP : star P * P = 1) : 0 < plaquetteEnergy2 P ↔ P ≠ 1 := by
  unfold plaquetteEnergy2
  constructor
  · intro hpos hP1
    have hr : (Matrix.trace P).re = 2 := (traceRe_eq_two_iff P hP).mpr hP1
    rw [hr] at hpos; norm_num at hpos
  · intro hne
    have hlt : (Matrix.trace P).re < 2 :=
      lt_of_le_of_ne (traceRe_le_two P hP)
        (fun he => hne ((traceRe_eq_two_iff P hP).mp he))
    exact div_pos (by linarith) (by norm_num)

end TheoremaAureum.Towers.YM.LatticeGauge
