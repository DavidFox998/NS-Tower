/-
================================================================
Towers / YM / Wall259_DependenceBound

**The dependence-defect REDUCTION — honest CONDITIONAL combinator.**

The honest conditional version of the "dependence defect" reduction. Where
`Wall258_DependenceDefect` worked with the bare arithmetic `iE − D`, this file
makes the decomposition a FIRST-CLASS object and records the reduction
"single-site bound ⇒ polymer-rate criterion" as a clean conditional combinator.

The single mathematical content is the decomposition

        I_polymer  =  I_E  −  Defect

(the genuine per-polymer large-deviation rate equals the single-site rate `I_E`
minus the inter-polymer dependence defect `Defect`, the rate lost to shared-link
correlations between overlapping polymers) together with the elementary
reduction: if the single-site rate clears the defect-raised entropy threshold,
then the polymer rate clears the bare entropy threshold `log 7`, so the KP
rate-function criterion (`Wall256Rate.kp_polymer_rate_summable`) fires.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `polymerRate` / `polymerRate_eq` — the decomposition `I_polymer = I_E − Defect`,
  as a definition and its defining identity.
* `defect_eq` — the dual reading `Defect = I_E − I_polymer` (the defect IS the
  rate gap between single-site and polymer rates).
* `polymer_criterion_of_single_site` — the reduction in its rawest form: from the
  single-site bound `log 7 + Defect < I_E` conclude `log 7 < I_polymer`.
* `polymer_criterion_of_threshold` — the same in threshold form: from a defect
  bound `Defect ≤ log C` and a single-site rate clearing `log(7·C)`, conclude
  `log 7 < I_polymer` (via `log(7·C) = log 7 + log C`).

WHAT IS CONDITIONAL (on NAMED OPEN surfaces — hypotheses, NOT `axiom`/`sorry`):
* `dependence_bound_kp_summable` — the KP polymer sum at the DECOMPOSED rate
  `I_polymer = I_E − Defect` is `Summable`, GIVEN the named open surfaces
  `h_entropy` (connective-constant count `≤ 7ⁿ`), `h_defect : Defect ≤ log C`
  (the cluster-expansion convergence input), and `h_rate : log(7·C) < I_E` (the
  genuine SU(N) large-deviation rate). Routed through
  `Wall256Rate.kp_polymer_rate_summable`.

## Honest scope (locked)

* **This is a REDUCTION, not a proof.** It records `I_polymer = I_E − Defect` and
  the implication "single-site bound ⇒ polymer-rate criterion" as a CONDITIONAL
  COMBINATOR over NAMED OPEN hypotheses. It proves NO mass gap and discharges NO
  open surface.
* **`Defect ≤ log C` is a NAMED OPEN hypothesis, NOT a Lean `axiom`.** It is the
  genuine cluster-expansion / shared-link dependence input, absent from mathlib
  v4.12.0; proved NOWHERE here. A real `axiom` would register in `#print axioms`
  and break the classical-trio footprint; a hypothesis does not.
* **`I_polymer` is the DEFINED surrogate `I_E − Defect`, NOT a constructed SU(N)
  polymer-rate functional.** No large-deviation rate for the real lattice gauge
  measure is built; `I_E` and `Defect` are abstract reals.
* This file establishes NO KP convergence, proves NO real defect/rate bound, and
  makes NO mass-gap / `μ > 0` / Surface-#1 / RH / BSD claim. It does NOT touch,
  discharge, or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`.
  YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall256_RateFunction` (hence
`EntropyBound`) only; nothing from the NS tower.
================================================================
-/

import Towers.YM.Wall256_RateFunction

namespace TheoremaAureum.Towers.YM.Wall259

open TheoremaAureum.Towers.YM

/-- **The dependence decomposition.** The genuine per-polymer large-deviation
rate is the single-site rate `I_E` minus the inter-polymer dependence defect
`Defect`: `I_polymer := I_E − Defect`. NOTE: this is a DEFINED surrogate alias
(`I_E`, `Defect` abstract reals), NOT a constructed SU(N) polymer-rate functional
— it carries the decomposition bookkeeping only and proves no real rate. -/
def polymerRate (I_E Defect : ℝ) : ℝ := I_E - Defect

/-- The decomposition identity `I_polymer = I_E − Defect`, definitionally. -/
@[simp] theorem polymerRate_eq (I_E Defect : ℝ) :
    polymerRate I_E Defect = I_E - Defect := rfl

/-- **Dual reading.** The defect IS the rate gap between the single-site rate and
the polymer rate: `Defect = I_E − I_polymer`. -/
theorem defect_eq (I_E Defect : ℝ) :
    Defect = I_E - polymerRate I_E Defect := by
  unfold polymerRate; ring

/-- **The reduction (raw form): single-site bound ⇒ polymer-rate criterion.**
If the single-site rate clears the defect-raised entropy threshold
`log 7 + Defect < I_E`, then the decomposed polymer rate clears the bare entropy
threshold: `log 7 < I_polymer`. -/
theorem polymer_criterion_of_single_site {I_E Defect : ℝ}
    (h : Real.log 7 + Defect < I_E) :
    Real.log 7 < polymerRate I_E Defect := by
  unfold polymerRate; linarith

/-- **The reduction (threshold form).** With the defect bounded by `Defect ≤ log C`
(`C > 0`) and the single-site rate clearing the raised threshold
`log(7·C) < I_E`, the polymer rate clears the entropy threshold:
`log 7 < I_polymer`. Uses `log(7·C) = log 7 + log C`. -/
theorem polymer_criterion_of_threshold {C I_E Defect : ℝ} (hCpos : 0 < C)
    (h_defect : Defect ≤ Real.log C)
    (h_rate : Real.log (7 * C) < I_E) :
    Real.log 7 < polymerRate I_E Defect := by
  apply polymer_criterion_of_single_site
  have hmul : Real.log (7 * C) = Real.log 7 + Real.log C :=
    Real.log_mul (by norm_num) (ne_of_gt hCpos)
  rw [hmul] at h_rate
  linarith

/-- **CONDITIONAL KP combinator at the decomposed rate.** The genuine
`EntropyBound` polymer count, weighted by the activity `exp(−I_polymer)ⁿ` at the
DECOMPOSED rate `I_polymer = I_E − Defect`, is `Summable`, CONDITIONAL on the
NAMED OPEN surfaces:
* `h_entropy` — the connective-constant count `≤ 7ⁿ` (open per `EntropyBound`);
* `h_defect : Defect ≤ log C` — the dependence-defect bound (the cluster-expansion
  convergence input; OPEN, a hypothesis NOT an `axiom`);
* `h_rate : log(7·C) < I_E` — the single-site rate clears the raised threshold
  (the genuine SU(N) rate; OPEN).
Proves NO KP convergence; makes NO mass-gap claim; does NOT discharge
`kotecky_preiss_criterion`. -/
theorem dependence_bound_kp_summable
    {L : ℕ} [NeZero L]
    (Connected : LatticeGauge.Polymer 4 L → Prop)
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          ≤ EntropyBound.polymer_const ^ n)
    {C I_E Defect : ℝ} (hCpos : 0 < C)
    (h_defect : Defect ≤ Real.log C)
    (h_rate : Real.log (7 * C) < I_E) :
    Summable (fun n : ℕ =>
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          * Real.exp (-(polymerRate I_E Defect)) ^ n) :=
  Wall256Rate.kp_polymer_rate_summable Connected h_entropy
    (polymer_criterion_of_threshold hCpos h_defect h_rate)

end TheoremaAureum.Towers.YM.Wall259
