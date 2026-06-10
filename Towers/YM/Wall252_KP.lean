/-
Wall252_KP.lean — a MODELED Kotecký–Preiss-style smallness bound, assembled
as a pure arithmetic combinator from the four named inputs
`S4Numerics.c_S4_lt`, `S4Numerics.kEff_le`, `S4Numerics.zModes_eq`, and
`Wall251b.su2_plaquetteEnergy_nonneg`.

================================ READ FIRST ================================
Main statement (`kp_sum_lt_half`):  for `0 ≤ β < 48 / e`,

        KP_sum β g  <  1/2 ,

where (`KP_sum`)

        KP_sum β g  :=  kpModeWeight · exp(−β · E_g) · e · β / 11520 ,
        kpModeWeight :=  zModes · kEff · C_S4 ,
        E_g          :=  su2PlaquetteEnergy g   (the SU(2) per-plaquette
                         Wilson energy `(2 − Re tr ↑g)/2 ≥ 0`).

How each named input is USED (none is decorative):
  * `zModes_eq`  → `(zModes : ℝ) = 15`              ┐  bound the prefactor
  * `kEff_le`    → `kEff ≤ 16/5`                    ├  `kpModeWeight < 120`
  * `c_S4_lt`    → `C_S4 < 5/2`                     ┘  (+ `C_S4 ≥ 0`)
  * `su2_plaquetteEnergy_nonneg` → `E_g ≥ 0`, hence the activity factor
    `exp(−β·E_g) ≤ 1` for `β ≥ 0`.
Then `kpModeWeight < 120`, activity `≤ 1`, and `β·e < 48` (from `β < 48/e`)
combine to `KP_sum < 120·1·48/11520 = 1/2`.  The constants `48/e` and `11520`
are TUNED so the inequality is tight at the boundary (`= 1/2` exactly at the
critical `β = 48/e` with the extremal prefactor), making the bound non-vacuous.

WHAT THIS FILE DOES **NOT** DO — and what no line here may ever be read as doing:

  1. `KP_sum` is a **MODELED single-term majorant surrogate**, NOT the
     Kotecký–Preiss polymer sum.  The genuine KP sum is an INFINITE sum
     `∑_{γ ∋ x} |activity(γ)| e^{a(|γ|)}` over ALL lattice polymers `γ`
     through a fixed link, controlled by a weight function `a : Polymer → ℝ`
     — an infinite family of inequalities.  A single product of four bare
     constants times one plaquette's activity is NOT, and cannot be
     substituted for, that object.  There is no theorem here of the form
     "`KP_sum β g < 1/2` → KP criterion holds".

  2. The prefactor constants are bare numerics inherited from
     `S4Numerics` (see that file's READ FIRST): `zModes = 15`, `kEff = 10/π`,
     and `C_S4 = ∑_{p∈{2,3,19,191}} log p/(p−1)` carry NO physical or
     number-theoretic content.  Calling `kpModeWeight` an "entropy × coupling"
     is descriptive analogy only; it is literally `15 · (10/π) · C_S4`.

  3. `su2_plaquetteEnergy_nonneg` is genuine POINTWISE Wilson positivity, but
     it is used here ONLY to bound a single activity factor `exp(−β·E_g) ≤ 1`.
     That is necessary-not-sufficient and is NOT Osterwalder–Schrader
     reflection positivity, NOT a transfer-operator spectral bound, NOT a
     cluster-expansion convergence proof.

  4. NOTHING here discharges `Towers/Attempts/ClusterExpansion.lean`'s
     `kotecky_preiss_criterion` `sorry`, and NOTHING here makes a mass-gap /
     μ>0 / Surface-#1-CLOSED / RH / BSD claim.  YM stays `Status: Open`;
     Surface #1 stays OPEN.

INVARIANT-LOCKED:
  * No `sorry` / `admit` / `axiom`.  Axiom footprint: the classical trio
    {propext, Classical.choice, Quot.sound}, inherited from the reused
    `S4Numerics` and `Wall251b` lemmas.

VERIFICATION STATUS — **VERIFIED** (machine-checked, classical-trio clean):
  Compiled with the v4.12.0 toolchain (`lean Towers/YM/Wall252_KP.lean`,
  EXIT=0) against the vendored mathlib oleans plus the built `S4Numerics`
  and `Wall251b_H4` oleans, and audited with `#print axioms`
  (`kpModeWeight_lt`, `kpModeWeight_nonneg`, `kp_sum_lt_half`
  → {propext, Classical.choice, Quot.sound}).
-/
import Mathlib.Analysis.SpecialFunctions.Exp
import Towers.YM.S4Numerics
import Towers.YM.Wall251b_H4

namespace TheoremaAureum.Towers.YM.Wall252

open Real
open TheoremaAureum.Towers.YM.Wall251b
open TheoremaAureum.Towers.YM.S4Numerics

/-- `C_S4 ≥ 0`: the four-term sum `∑_{p∈{2,3,19,191}} log p/(p−1)` is a sum of
    nonnegative terms (`log p ≥ 0` for `p ≥ 1`, denominators positive). -/
private theorem c_S4_nonneg : 0 ≤ C_S4 := by
  simp only [C_S4]
  refine Finset.sum_nonneg (fun p hp => ?_)
  simp only [S4, Finset.mem_insert, Finset.mem_singleton] at hp
  rcases hp with rfl | rfl | rfl | rfl <;>
    exact div_nonneg (Real.log_nonneg (by norm_num)) (by norm_num)

/-- `(zModes : ℝ) = 15`, routed through `zModes_eq` (`zModes = 120 / 2^3`). -/
private theorem zModes_real : (zModes : ℝ) = 15 := by
  rw [zModes_eq]; norm_num

/-- The modeled KP prefactor `kpModeWeight := zModes · kEff · C_S4`.  A bare
    product of the three `S4Numerics` constants; the "entropy × coupling"
    reading is descriptive analogy only (see READ FIRST). -/
noncomputable def kpModeWeight : ℝ := (zModes : ℝ) * kEff * C_S4

/-- **Prefactor smallness.** `kpModeWeight < 120`, from `zModes = 15`,
    `kEff ≤ 16/5`, `C_S4 < 5/2` and `C_S4 ≥ 0`
    (`15 · (16/5) · (5/2) = 120`). -/
theorem kpModeWeight_lt : kpModeWeight < 120 := by
  unfold kpModeWeight
  rw [zModes_real]
  have hk : kEff ≤ 16 / 5 := kEff_le
  have hc : C_S4 < 5 / 2 := c_S4_lt
  have hc0 : 0 ≤ C_S4 := c_S4_nonneg
  nlinarith [mul_le_mul_of_nonneg_right hk hc0, hc, hc0]

/-- The prefactor is nonnegative (`zModes, kEff > 0`, `C_S4 ≥ 0`). -/
theorem kpModeWeight_nonneg : 0 ≤ kpModeWeight := by
  unfold kpModeWeight
  rw [zModes_real]
  have hkpos : 0 < kEff := div_pos (by norm_num) Real.pi_pos
  exact mul_nonneg (mul_nonneg (by norm_num) hkpos.le) c_S4_nonneg

/-- The MODELED Kotecký–Preiss majorant for inverse coupling `β` and a single
    SU(2) plaquette `g`.  See the file header: this is a one-term arithmetic
    surrogate, NOT the genuine infinite polymer sum. -/
noncomputable def KP_sum (β : ℝ) (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) : ℝ :=
  kpModeWeight * Real.exp (-β * su2PlaquetteEnergy g) * Real.exp 1 * β / 11520

/-- **Modeled KP smallness bound.** For `0 ≤ β < 48 / e`, the modeled KP
    majorant satisfies `KP_sum β g < 1/2`.  HONEST SCOPE (see READ FIRST):
    `KP_sum` is a single-term arithmetic surrogate, so this does NOT establish
    Kotecký–Preiss convergence, does NOT discharge `kotecky_preiss_criterion`,
    and makes NO mass-gap / μ>0 / Surface-#1 claim. -/
theorem kp_sum_lt_half {β : ℝ} (g : Matrix.specialUnitaryGroup (Fin 2) ℂ)
    (hβ0 : 0 ≤ β) (hβ : β < 48 / Real.exp 1) :
    KP_sum β g < 1 / 2 := by
  have he : (0 : ℝ) < Real.exp 1 := Real.exp_pos 1
  unfold KP_sum
  set act : ℝ := Real.exp (-β * su2PlaquetteEnergy g) with hactdef
  -- activity factor ≤ 1, using pointwise Wilson positivity `E_g ≥ 0`
  have hact0 : 0 ≤ act := (Real.exp_pos _).le
  have hact1 : act ≤ 1 := by
    rw [hactdef, neg_mul]
    have h0 : 0 ≤ β * su2PlaquetteEnergy g := mul_nonneg hβ0 (su2_plaquetteEnergy_nonneg g)
    calc Real.exp (-(β * su2PlaquetteEnergy g))
        ≤ Real.exp 0 := Real.exp_le_exp.mpr (by linarith)
      _ = 1 := Real.exp_zero
  -- prefactor bounds
  have hw : kpModeWeight < 120 := kpModeWeight_lt
  have hw0 : 0 ≤ kpModeWeight := kpModeWeight_nonneg
  -- p := kpModeWeight · act  ∈ [0, 120)
  have hp0 : 0 ≤ kpModeWeight * act := mul_nonneg hw0 hact0
  have hp : kpModeWeight * act < 120 :=
    lt_of_le_of_lt (mul_le_of_le_one_right hw0 hact1) hw
  -- q := e · β  ∈ [0, 48)
  have hq0 : 0 ≤ Real.exp 1 * β := mul_nonneg he.le hβ0
  have hq : Real.exp 1 * β < 48 := by
    rw [mul_comm]; exact (lt_div_iff he).mp hβ
  -- numerator < 120 · 48 = 5760
  have hN : (kpModeWeight * act) * (Real.exp 1 * β) < 5760 := by
    nlinarith [mul_nonneg (sub_nonneg.mpr hp.le) hq0, hq, hp0]
  rw [div_lt_iff (by norm_num : (0 : ℝ) < 11520)]
  have key : kpModeWeight * act * Real.exp 1 * β
      = (kpModeWeight * act) * (Real.exp 1 * β) := by ring
  rw [key]
  calc (kpModeWeight * act) * (Real.exp 1 * β) < 5760 := hN
    _ = 1 / 2 * 11520 := by norm_num

end TheoremaAureum.Towers.YM.Wall252
