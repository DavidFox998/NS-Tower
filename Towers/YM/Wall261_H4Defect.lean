/-
================================================================
Towers / YM / Wall261_H4Defect

**The H4 / 120-cell defect improvement — honest CONDITIONAL combinator.**

Sequel to `Wall260_ClayReduction` (the general pointwise dependence-defect
reduction with threshold `log(7·C)`). Where Wall260 pins the ℤ⁴ link incidence
`C = 6` (threshold `log 42`), this wall records the H4 / 120-cell improvement:
the second-largest adjacency eigenvalue of the relevant H4 graph is the golden
ratio `λ₂ = φ`, so the improved dependence constant is `C = 1 + φ = φ² ≈ 2.618`
and the defect drops to `Defect ≤ log(1+φ) − ε`, with the margin `ε > 0` coming
from the ℤ⁴-vs-H4 graph comparison. Threshold drops to `log(7·(1+φ)) ≈ log 18.33
< log 42`.

The golden ratio is `φ := (1 + √5)/2`; `1 + φ = φ²` is the genuine golden-ratio
identity.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `phi_pos` — `0 < φ`.
* `phi_sq_eq` — `φ² = φ + 1`, i.e. `1 + φ = φ²` (the golden-ratio identity, the
  reason `1 + φ` is the special H4 constant).
* `one_add_phi_lt_six` — `1 + φ < 6`: the H4 constant is strictly smaller than the
  ℤ⁴ link incidence.
* `graph_gap_pos` — `0 < log 6 − log(1+φ)`: the ℤ⁴-vs-H4 constant comparison
  yields a STRICTLY POSITIVE gap (the honest realization that "ε > 0 comes from
  the graph comparison" — a positive margin exists).
* `h4_threshold_lt_z4` — `log(7·(1+φ)) < log 42`: the H4 KP threshold strictly
  undercuts the ℤ⁴ threshold.

WHAT IS CONDITIONAL (named-open hypotheses — the "h_rate mechanism": a hypothesis,
NOT a Lean `axiom`):
* `h4_defect_beats_z4` — from the NAMED OPEN H4 defect bound
  `h_graph : Defect ≤ log(1+φ) − ε` with `ε > 0`, conclude `Defect < log 6`: the
  H4 graph comparison strictly beats the ℤ⁴ defect bound.
* `h4_clay_reduction` — feeds the H4 defect bound `∀ x, I_E x − I_polymer x ≤
  log(1+φ) − ε` and the H4-threshold rate `h_rate : ∀ x, log(7·(1+φ)) < I_E x`
  through `Wall260.new_clay_reduction` (at `C = 1+φ`) to conclude
  `∀ x, log 7 < I_polymer x`.

## Honest scope (locked)

* **This does NOT prove the real H4 spectral gap `λ₂ = φ`.** That is a statement
  about the adjacency spectrum of the 120-cell / H4 Coxeter graph, which is NOT in
  mathlib v4.12.0 and is not constructed here. `φ` enters here ONLY as the real
  number `(1+√5)/2`; the claim that it IS the H4 second eigenvalue is OUTSIDE this
  file.
* **This does NOT prove the real dependence defect bound.** `Defect` is an
  abstract real scalar and the H4 defect bound `Defect ≤ log(1+φ) − ε` is a NAMED
  OPEN hypothesis (the genuine cluster-expansion / Dobrushin-uniqueness input
  refined by the graph comparison), NOT a Lean `axiom` and NOT `by sorry` — so
  `#print axioms` shows no new axioms. It is proved NOWHERE here. The genuine
  positive-gap content delivered is `graph_gap_pos` (the CONSTANT comparison
  `log 6 vs log(1+φ)`), not the spectral gap and not the defect bound.
* **This is a REDUCTION/IMPROVEMENT, not a proof.** It proves NO part of the Clay
  Yang–Mills problem, discharges NO open surface, constructs NO real SU(N) rate
  functional (`I_E`, `I_polymer` abstract). Makes NO mass-gap / `μ > 0` /
  Surface-#1 / RH / BSD claim, and does NOT touch the invariant-locked
  `kotecky_preiss_criterion` `sorry`. YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall260_ClayReduction` and
`Mathlib.Analysis.SpecialFunctions.Log.Basic` (for `Real.log` monotonicity).
================================================================
-/

import Towers.YM.Wall260_ClayReduction

namespace TheoremaAureum.Towers.YM.Wall261

open TheoremaAureum.Towers.YM

/-- The golden ratio `φ = (1 + √5)/2` (the H4 second adjacency eigenvalue, as a
bare real number — the spectral claim itself is OUTSIDE this file). -/
noncomputable def phi : ℝ := (1 + Real.sqrt 5) / 2

/-- `√5 ^ 2 = 5`. -/
theorem sqrt_five_sq : Real.sqrt 5 ^ 2 = 5 :=
  Real.sq_sqrt (by norm_num)

/-- **GENUINE.** `0 < φ`. -/
theorem phi_pos : 0 < phi := by
  have h : (0 : ℝ) ≤ Real.sqrt 5 := Real.sqrt_nonneg 5
  unfold phi; linarith

/-- **GENUINE — golden-ratio identity.** `φ² = φ + 1`, i.e. `1 + φ = φ²`. This is
why `1 + φ` is the special H4 constant. -/
theorem phi_sq_eq : phi ^ 2 = phi + 1 := by
  unfold phi
  linear_combination (1 / 4 : ℝ) * sqrt_five_sq

/-- **GENUINE.** `1 + φ < 6`: the H4 constant is strictly below the ℤ⁴ link
incidence `C_Z4 = 6`. -/
theorem one_add_phi_lt_six : (1 : ℝ) + phi < 6 := by
  have h : (0 : ℝ) ≤ Real.sqrt 5 := Real.sqrt_nonneg 5
  have hsq : Real.sqrt 5 ^ 2 = 5 := sqrt_five_sq
  unfold phi
  nlinarith [h, hsq]

/-- `0 < 1 + φ`. -/
theorem one_add_phi_pos : (0 : ℝ) < 1 + phi := by
  have := phi_pos; linarith

/-- **GENUINE.** `log(1+φ) < log 6`: the H4 constant gives a strictly smaller
logarithmic threshold ingredient than ℤ⁴. -/
theorem log_one_add_phi_lt_log_six : Real.log (1 + phi) < Real.log 6 :=
  Real.log_lt_log one_add_phi_pos one_add_phi_lt_six

/-- **GENUINE — "ε > 0 comes from the graph comparison".** The ℤ⁴-vs-H4 constant
comparison yields a STRICTLY POSITIVE gap `log 6 − log(1+φ) > 0`. (This is the
honest CONSTANT-level positive margin; the actual H4 spectral gap `λ₂ = φ` is not
proved here.) -/
theorem graph_gap_pos : 0 < Real.log 6 - Real.log (1 + phi) := by
  have := log_one_add_phi_lt_log_six; linarith

/-- **GENUINE.** `log(7·(1+φ)) < log 42`: the H4 KP threshold strictly undercuts
the ℤ⁴ threshold `log 42`. -/
theorem h4_threshold_lt_z4 : Real.log (7 * (1 + phi)) < Real.log 42 := by
  have hpos : (0 : ℝ) < 7 * (1 + phi) := by have := one_add_phi_pos; linarith
  have hlt : 7 * (1 + phi) < 42 := by have := one_add_phi_lt_six; linarith
  have := Real.log_lt_log hpos hlt
  simpa using this

/-- **CONDITIONAL (h_rate mechanism).** From the NAMED OPEN H4 defect bound
`h_graph : Defect ≤ log(1+φ) − ε` with `ε > 0` (the graph-comparison margin),
the H4 defect strictly beats the ℤ⁴ bound `log 6`. `h_graph` is a HYPOTHESIS,
NOT a Lean `axiom`. -/
theorem h4_defect_beats_z4 {ε Defect : ℝ} (hε : 0 < ε)
    (h_graph : Defect ≤ Real.log (1 + phi) - ε) : Defect < Real.log 6 := by
  have hlt := log_one_add_phi_lt_log_six
  linarith

/-- **CONDITIONAL (h_rate mechanism).** The H4 instantiation of the Clay
reduction: feed the NAMED OPEN H4 defect bound `h_defect : ∀ x, I_E x −
I_polymer x ≤ log(1+φ) − ε` (`ε > 0`) and the H4-threshold rate
`h_rate : ∀ x, log(7·(1+φ)) < I_E x` through `Wall260.new_clay_reduction`
(at `C = 1+φ`) to conclude `∀ x, log 7 < I_polymer x`. `h_defect`/`h_rate` are
HYPOTHESES, NOT Lean `axiom`s; proves NO Clay result. -/
theorem h4_clay_reduction {ε : ℝ} (hε : 0 < ε)
    {I_E I_polymer : ℝ → ℝ}
    (h_defect : ∀ x, I_E x - I_polymer x ≤ Real.log (1 + phi) - ε)
    (h_rate : ∀ x, Real.log (7 * (1 + phi)) < I_E x) :
    ∀ x, Real.log 7 < I_polymer x :=
  Wall260.new_clay_reduction one_add_phi_pos
    (fun x => by have := h_defect x; linarith) h_rate

end TheoremaAureum.Towers.YM.Wall261
