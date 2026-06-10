/-
================================================================
Towers / YM / Wall260_ClayReduction

**The Clay reduction (pointwise dependence-defect form) — honest CONDITIONAL
combinator.**

Per the requested spec. Sequel to `Wall258_DependenceDefect` (scalar `iE − D`)
and `Wall259_DependenceBound` (scalar decomposition object). This wall states the
defect bound POINTWISE over rate FUNCTIONS `I_E, I_polymer : ℝ → ℝ` and packages
the "single-site bound ⇒ polymer-rate criterion" implication as a single named
combinator `new_clay_reduction`, parameterised by the dependence/incidence
constant `C` and the defect hypothesis `h_defect`.

The split (as requested):
* **`C = 6` is COMBINATORICS.** `C_Z4 := 6 : ℕ` is the ℤ⁴ link incidence
  `2(d−1) = 6`, reusing the proven `Wall258.linkIncidence_four` via
  `link_incidence_number_4d`. No H4 / 120-cell here (deferred to a later wall).
* **`h_defect` is ANALYSIS.** `h_defect : ∀ x, I_E x − I_polymer x ≤ log C` is a
  NAMED OPEN hypothesis (the genuine cluster-expansion / Dobrushin-uniqueness
  dependence input), NOT a Lean `axiom` and NOT `by sorry` — so `#print axioms`
  shows no new axioms and the classical-trio footprint is preserved. It is proved
  NOWHERE here.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `link_incidence_number_4d` — `Wall258.linkIncidence 4 = C_Z4` (= 6), the ℤ⁴
  combinatorial constant (reuses `Wall258.linkIncidence_four`).
* `threshold_split` — `log(7·C) = log 7 + log C` for `C > 0`.
* `new_clay_reduction` — the reduction: from `h_defect : ∀ x, I_E x − I_polymer x
  ≤ log C` and `h_rate : ∀ x, log(7·C) < I_E x` conclude `∀ x, log 7 < I_polymer x`.
* `new_clay_reduction_Z4` — the same instantiated at the genuine ℤ⁴ incidence
  `C = 6`; threshold `log(7·6) = log 42 ≈ 3.73767`.

## Honest scope (locked)

* **This is a REDUCTION, not a proof.** It reduces the polymer-rate criterion to
  TWO NAMED OPEN hypotheses (`h_defect`, `h_rate`). Despite the name, it proves NO
  part of the Clay Yang–Mills problem, discharges NO open surface, and constructs
  NO real SU(N) rate functional — `I_E`, `I_polymer` are abstract functions
  `ℝ → ℝ`.
* **`h_defect` is a NAMED OPEN hypothesis, NOT a Lean `axiom`.** It is the genuine
  inter-polymer dependence input (cluster expansion / Dobrushin uniqueness),
  absent from mathlib v4.12.0; a real `axiom` would register in `#print axioms`
  and break the classical-trio footprint — a hypothesis does not.
* **`C = 6` is the ℤ⁴ honest constant**, so the honest threshold is `log 42`. A
  smaller `C` (e.g. an H4 / 120-cell spectral gap `1 + λ₂ ≈ 2.618`, threshold
  ≈ `log 18.33`) is a statement about a DIFFERENT geometry, deferred to a later
  wall; this wall stays general in `C` and pins `C = 6` for ℤ⁴.
* Establishes NO KP convergence, makes NO mass-gap / `μ > 0` / Surface-#1 / RH /
  BSD claim. Does NOT touch, discharge, or weaken the invariant-locked
  `kotecky_preiss_criterion` `sorry`. YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall258_DependenceDefect` only;
nothing from the NS tower.
================================================================
-/

import Towers.YM.Wall258_DependenceDefect

namespace TheoremaAureum.Towers.YM.Wall260

open TheoremaAureum.Towers.YM

/-- **The ℤ⁴ link-incidence constant (combinatorics).** `C_Z4 := 6`, the number
of plaquettes of the 4-dimensional cubic lattice containing a fixed link
(`2(d−1) = 6` at `d = 4`). -/
def C_Z4 : ℕ := 6

/-- `C_Z4` IS the ℤ⁴ link incidence `2(d−1) = 6`, reusing the proven combinatorial
fact `Wall258.linkIncidence_four`. Pure combinatorics; no H4. -/
theorem link_incidence_number_4d : Wall258.linkIncidence 4 = C_Z4 :=
  Wall258.linkIncidence_four

/-- **GENUINE arithmetic.** The raised KP threshold splits additively:
`log(7·C) = log 7 + log C` for `C > 0`. -/
theorem threshold_split {C : ℝ} (hCpos : 0 < C) :
    Real.log (7 * C) = Real.log 7 + Real.log C :=
  Real.log_mul (by norm_num) (ne_of_gt hCpos)

/-- **The Clay reduction (pointwise dependence-defect form).** Given rate
functions `I_E, I_polymer : ℝ → ℝ`, the NAMED OPEN defect bound
`h_defect : ∀ x, I_E x − I_polymer x ≤ log C` (the analysis input — NOT a Lean
`axiom`) and the single-site rate clearing the raised threshold
`h_rate : ∀ x, log(7·C) < I_E x`, the polymer rate clears the bare entropy
threshold everywhere: `∀ x, log 7 < I_polymer x`.

HONEST: a REDUCTION to `h_defect`/`h_rate`, proving NO Clay result, NO mass gap,
and NO real rate functional (`I_E`, `I_polymer` abstract). -/
theorem new_clay_reduction {C : ℝ} (hCpos : 0 < C)
    {I_E I_polymer : ℝ → ℝ}
    (h_defect : ∀ x, I_E x - I_polymer x ≤ Real.log C)
    (h_rate : ∀ x, Real.log (7 * C) < I_E x) :
    ∀ x, Real.log 7 < I_polymer x := by
  intro x
  have hr := h_rate x
  have hd := h_defect x
  rw [threshold_split hCpos] at hr
  linarith

/-- **Instantiation at the genuine ℤ⁴ incidence `C = 6`.** The threshold is
`log(7·6) = log 42 ≈ 3.73767`. Same honest scope: `h_defect` is the NAMED OPEN
analysis input, proved nowhere; this is a reduction, NOT a Clay proof. -/
theorem new_clay_reduction_Z4
    {I_E I_polymer : ℝ → ℝ}
    (h_defect : ∀ x, I_E x - I_polymer x ≤ Real.log 6)
    (h_rate : ∀ x, Real.log 42 < I_E x) :
    ∀ x, Real.log 7 < I_polymer x := by
  refine new_clay_reduction (C := 6) (by norm_num) h_defect ?_
  intro x
  rw [show (7 : ℝ) * 6 = 42 by norm_num]
  exact h_rate x

end TheoremaAureum.Towers.YM.Wall260
