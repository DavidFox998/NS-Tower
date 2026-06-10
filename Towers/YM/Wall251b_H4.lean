/-
Wall251b_H4.lean — SU(2) Wilson positivity on the GENUINE special-unitary
group `Matrix.specialUnitaryGroup (Fin 2) ℂ`.

================================ READ FIRST ================================
This file lifts the already-verified, `sorry`-free SU(2) Wilson lemmas of
`Towers/YM/WilsonPositivitySU2.lean` (which are stated for a bare unitary
matrix `A` with `star A * A = 1`) onto the real mathlib special-unitary
group type `Matrix.specialUnitaryGroup (Fin 2) ℂ`.  For `g ∈ SU(2)`:

  * `su2_star_mul_self`        :  star ↑g * ↑g = 1   (unitarity, extracted
                                  from group membership)
  * `su2_wilson_hs_identity`   :  ‖↑g − 1‖²_HS = 4 − 2·Re(tr ↑g)   (Wilson)
  * `su2_traceRe_le_two`       :  Re(tr ↑g) ≤ 2
  * `su2_traceRe_eq_two_iff`   :  Re(tr ↑g) = 2 ↔ ↑g = 1
  * `su2_plaquetteEnergy_nonneg` : 0 ≤ (2 − Re tr ↑g)/2   (pointwise Wilson
                                   positivity)
  * `su2_plaquetteEnergy_pos_iff`: 0 < (2 − Re tr ↑g)/2 ↔ ↑g ≠ 1

The three "classic-trio lock" anchors requested for this wall:
  1. analysis layer  → `Mathlib.Analysis.RCLike.Basic` (real/complex `re`
     and ordering used by the positivity corollary);
  2. SU(2) layer     → `Mathlib.LinearAlgebra.UnitaryGroup`, which is where
     mathlib v4.12.0 actually defines `Matrix.specialUnitaryGroup` and
     `Matrix.mem_specialUnitaryGroup_iff` (there is NO
     `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` module in v4.12.0);
  3. Wilson identity → reused verbatim from `WilsonPositivitySU2`
     (`hsNormSq2_sub_one_eq`), itself proved by the Hilbert–Schmidt
     expansion `star(A−1)(A−1) = star A·A − star A − A + 1` then `star A·A = 1`.

WHAT THIS FILE DOES **NOT** DO — and what no line here may be read as doing:

  1. It uses ONLY unitarity (`star ↑g * ↑g = 1`).  Although `g` lives in the
     *special* unitary group, the determinant-one constraint is NEVER used;
     the content is N-generic linear algebra (it ports unchanged to U(2),
     SU(3), …), so it bears on NO SU(2)-specific or group-specific structure.

  2. `su2_plaquetteEnergy_nonneg` is POINTWISE Wilson positivity of a single
     plaquette energy `(2 − Re tr)/2 ≥ 0`.  It is necessary-not-sufficient
     and is **NOT** Osterwalder–Schrader reflection positivity, **NOT** a
     transfer-operator spectral bound, and **NOT** a mass gap.  The OS /
     reflection-positivity surface stays OPEN.

  3. NOTHING here discharges `Towers/Attempts/ClusterExpansion.lean`'s
     `kotecky_preiss_criterion` `sorry`, and NOTHING here makes a mass-gap /
     μ>0 / Surface-#1-CLOSED / RH / BSD claim.  YM stays `Status: Open`.

INVARIANT-LOCKED:
  * No `sorry` / `admit` / `axiom`.  Axiom footprint: the classical trio
    {propext, Classical.choice, Quot.sound}, inherited from the reused
    `WilsonPositivitySU2` lemmas.

VERIFICATION STATUS — **VERIFIED** (machine-checked, classical-trio clean):
  Compiled with the v4.12.0 toolchain (`lean Towers/YM/Wall251b_H4.lean`,
  EXIT=0) against the vendored mathlib oleans plus the built
  `WilsonPositivitySU2` olean, and audited with `#print axioms`
  (all six declarations → {propext, Classical.choice, Quot.sound}).
-/
import Mathlib.Analysis.RCLike.Basic
import Mathlib.LinearAlgebra.UnitaryGroup
import Towers.YM.WilsonPositivitySU2

namespace TheoremaAureum.Towers.YM.Wall251b

open Matrix Complex
open TheoremaAureum.Towers.YM.LatticeGauge

/-- **Unitarity from SU(2) membership.** For `g ∈ Matrix.specialUnitaryGroup
    (Fin 2) ℂ`, the underlying matrix satisfies `star ↑g * ↑g = 1`.  Routes
    through `Matrix.mem_specialUnitaryGroup_iff` (unitary ∧ det = 1) and
    `Matrix.mem_unitaryGroup_iff'` (`star A * A = 1`).  Only the unitary
    component is used; det = 1 is discarded. -/
theorem su2_star_mul_self (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    star g.1 * g.1 = 1 :=
  Matrix.mem_unitaryGroup_iff'.mp (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1

/-- **Wilson Hilbert–Schmidt identity on SU(2).** For `g ∈ SU(2)`,
    `hsNormSq2 (↑g − 1) = 4 − 2·Re(tr ↑g)` (= `2N − 2·Re tr` at N = 2).
    A direct instance of `WilsonPositivitySU2.hsNormSq2_sub_one_eq`. -/
theorem su2_wilson_hs_identity (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    hsNormSq2 (g.1 - 1) = 4 - 2 * (Matrix.trace g.1).re :=
  hsNormSq2_sub_one_eq g.1 (su2_star_mul_self g)

/-- **Upper character bound on SU(2).** `Re(tr ↑g) ≤ 2`. -/
theorem su2_traceRe_le_two (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    (Matrix.trace g.1).re ≤ 2 :=
  traceRe_le_two g.1 (su2_star_mul_self g)

/-- **Equality case on SU(2).** `Re(tr ↑g) = 2 ↔ ↑g = 1`. -/
theorem su2_traceRe_eq_two_iff (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    (Matrix.trace g.1).re = 2 ↔ g.1 = 1 :=
  traceRe_eq_two_iff g.1 (su2_star_mul_self g)

/-- The per-plaquette Wilson energy `(2 − Re tr ↑g)/2` of an SU(2) element. -/
noncomputable def su2PlaquetteEnergy (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) : ℝ :=
  plaquetteEnergy2 g.1

/-- **Pointwise Wilson positivity on SU(2).** `0 ≤ (2 − Re tr ↑g)/2`.
    NOT Osterwalder–Schrader reflection positivity and NOT a mass gap. -/
theorem su2_plaquetteEnergy_nonneg (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    0 ≤ su2PlaquetteEnergy g :=
  plaquetteEnergy2_nonneg g.1 (su2_star_mul_self g)

/-- The SU(2) per-plaquette energy is strictly positive iff `↑g ≠ 1`. -/
theorem su2_plaquetteEnergy_pos_iff (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) :
    0 < su2PlaquetteEnergy g ↔ g.1 ≠ 1 :=
  plaquetteEnergy2_pos_iff g.1 (su2_star_mul_self g)

end TheoremaAureum.Towers.YM.Wall251b
