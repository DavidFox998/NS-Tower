/-
================================================================
Towers / YM / Wall258_DependenceDefect

**The inter-polymer dependence defect — honest CONDITIONAL combinator.**

Sequel to `Wall257_RateLowerBound`. `Wall256_RateFunction` showed the KP polymer
sum is `Summable` once the per-polymer rate clears `log 7`
(`kp_polymer_rate_summable`). But polymers that share a lattice link are NOT
independent: passing from a single-site rate `I_E` to the genuine polymer rate
costs a **dependence defect** `D` — the rate lost to those shared-link
correlations. This file routes the KP criterion through that defect HONESTLY.

The mechanism. A fixed lattice link is shared by exactly `2(d−1)` plaquettes
(`linkIncidence`); in `d = 4` that is `C_Z4 = 6`. The defect is bounded by
`D ≤ log C` (the cluster-expansion convergence input), so the effective polymer
rate is `I_E − D ≥ I_E − log C`. To still beat the `7ⁿ` entropy we need
`I_E − D > log 7`, i.e. the single-site rate must clear the RAISED threshold
`log(7·C) = log 42` (for `C = 6`). Then `kp_polymer_rate_summable` applies at
rate `I_E − D`.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `linkIncidence_four` — the link-incidence count `2(d−1)` evaluates to `6` at
  `d = 4` (the genuine ℤ⁴ geometry constant; see honest scope on the count vs the
  formula).
* `rate_clears_after_defect` — the honest arithmetic heart: if `D ≤ log C` and
  `log(7·C) < iE` then `log 7 < iE − D` (via `log(7·C) = log 7 + log C`).
* `threshold_mono` — the KP threshold `log(7·C)` is strictly increasing in `C`:
  a SMALLER dependence/incidence constant gives a SMALLER (easier) threshold.
  This is the requested "lower the numbers" lever — and it pins the honest fact
  that any threshold below `log 42` requires `C < 6`, which the standard 4-cubic
  lattice does NOT provide (see honest scope).

WHAT IS CONDITIONAL (on NAMED OPEN surfaces — hypotheses, NOT `axiom`/`sorry`):
* `dependence_defect_kp_summable` — for a general dependence constant `C > 0`,
  the KP polymer sum is `Summable` GIVEN the defect bound `h_defect : D ≤ log C`
  (the genuine cluster-expansion convergence input — OPEN) and the rate bound
  `h_rate : log(7·C) < iE` (the genuine SU(N) large-deviation rate — OPEN),
  routed through `Wall256Rate.kp_polymer_rate_summable` (which itself also
  consumes the OPEN connective-constant count `h_entropy`).
* `dependence_defect_kp_summable_Z4` — the same specialised to the genuine ℤ⁴
  link incidence `C = 6`, threshold `log 42`.

## Honest scope (locked)

* **`D ≤ log C` is a NAMED OPEN hypothesis, NOT a Lean `axiom`.** A real `axiom`
  would register in `#print axioms` and break the classical-trio footprint; a
  hypothesis does not. We prove the defect bound NOWHERE — it is the genuine
  cluster-expansion / Brydges–Federbush convergence input, absent from mathlib
  v4.12.0.
* **`linkIncidence d := 2(d−1)` is the incidence FORMULA**, evaluated at `d = 4`.
  The standard count (a link lies in `d−1` coordinate-plane orientations, each
  contributing `2` plaquettes) is its geometric meaning; a full `Finset.card`
  proof over the lattice is left as the genuine combinatorial content (cf.
  `EntropyBound.polymer_const = 2d−1`, whose real count is the open `h_entropy`).
* **"Lower the numbers" is honest only as a lever, not a free lunch.** For ℤ⁴ the
  incidence is exactly `6`, so the honest threshold is `log 42`. `threshold_mono`
  shows a smaller `C` lowers it, but a smaller `C` is a statement about a
  DIFFERENT geometry (the H4 / 120-cell motivation deferred to a later wall), NOT
  about the ℤ⁴ lattice this YM model is built on.
* This file establishes NO KP convergence, proves NO real defect/rate bound, and
  makes NO mass-gap / `μ > 0` / Surface-#1 / RH / BSD claim. It does NOT touch,
  discharge, or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`.
  YM stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall257_RateLowerBound`
(hence `Wall256_RateFunction`) only; nothing from the NS tower.
================================================================
-/

import Towers.YM.Wall257_RateLowerBound

namespace TheoremaAureum.Towers.YM.Wall258

open TheoremaAureum.Towers.YM

/-- **Link-incidence formula.** The number of plaquettes (unit squares) of the
`d`-dimensional cubic lattice that contain a fixed link: `2(d−1)`. -/
def linkIncidence (d : ℕ) : ℕ := 2 * (d - 1)

/-- The genuine ℤ⁴ link incidence: `linkIncidence 4 = 6`. (A link lies in `d−1 =
3` coordinate-plane orientations, each contributing `2` plaquettes.) -/
theorem linkIncidence_four : linkIncidence 4 = 6 := by decide

/-- **GENUINE arithmetic heart.** If the dependence defect satisfies
`D ≤ log C` and the single-site rate clears the raised threshold
`log(7·C) < iE`, then the effective polymer rate clears the entropy threshold:
`log 7 < iE − D`. Uses `log(7·C) = log 7 + log C`. -/
theorem rate_clears_after_defect {C D iE : ℝ} (hCpos : 0 < C)
    (h_defect : D ≤ Real.log C)
    (h_rate : Real.log (7 * C) < iE) :
    Real.log 7 < iE - D := by
  have hmul : Real.log (7 * C) = Real.log 7 + Real.log C :=
    Real.log_mul (by norm_num) (ne_of_gt hCpos)
  rw [hmul] at h_rate
  linarith

/-- **GENUINE "lower the numbers" lever.** The KP rate threshold `log(7·C)` is
strictly increasing in the dependence/incidence constant `C`: a smaller `C`
yields a smaller, easier-to-clear threshold. For ℤ⁴, `C = linkIncidence 4 = 6`
(threshold `log 42`); pushing below `log 42` requires `C < 6`, which the standard
4-cubic lattice does not provide (each link lies in exactly `2(d−1) = 6`
plaquettes). -/
theorem threshold_mono {C₁ C₂ : ℝ} (h1 : 0 < C₁) (h12 : C₁ < C₂) :
    Real.log (7 * C₁) < Real.log (7 * C₂) :=
  Real.log_lt_log (by positivity) (by linarith)

/-- **CONDITIONAL KP combinator (general dependence constant `C`).** The genuine
`EntropyBound` polymer count, weighted by the defect-corrected activity
`exp(−(iE − D))ⁿ`, is `Summable`, CONDITIONAL on the NAMED OPEN surfaces:
* `h_entropy` — the connective-constant count `≤ 7ⁿ` (open per `EntropyBound`);
* `h_defect : D ≤ log C` — the dependence-defect bound (the cluster-expansion
  convergence input; OPEN, a hypothesis NOT an `axiom`);
* `h_rate : log(7·C) < iE` — the single-site rate clears the raised threshold
  (the genuine SU(N) rate; OPEN).
Proves NO KP convergence; makes NO mass-gap claim; does NOT discharge
`kotecky_preiss_criterion`. -/
theorem dependence_defect_kp_summable
    {L : ℕ} [NeZero L]
    (Connected : LatticeGauge.Polymer 4 L → Prop)
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          ≤ EntropyBound.polymer_const ^ n)
    {C D iE : ℝ} (hCpos : 0 < C)
    (h_defect : D ≤ Real.log C)
    (h_rate : Real.log (7 * C) < iE) :
    Summable (fun n : ℕ =>
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          * Real.exp (-(iE - D)) ^ n) :=
  Wall256Rate.kp_polymer_rate_summable Connected h_entropy
    (rate_clears_after_defect hCpos h_defect h_rate)

/-- **CONDITIONAL KP combinator at the genuine ℤ⁴ link incidence `C = 6`.** The
defect bound is `D ≤ log 6` and the raised threshold is `log 42 = log(7·6)`. Same
honest scope as `dependence_defect_kp_summable`: both `h_defect` and `h_rate` are
NAMED OPEN hypotheses; this proves NO KP convergence and makes NO mass-gap
claim. -/
theorem dependence_defect_kp_summable_Z4
    {L : ℕ} [NeZero L]
    (Connected : LatticeGauge.Polymer 4 L → Prop)
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          ≤ EntropyBound.polymer_const ^ n)
    {D iE : ℝ}
    (h_defect : D ≤ Real.log 6)
    (h_rate : Real.log 42 < iE) :
    Summable (fun n : ℕ =>
        (Nat.card {X : LatticeGauge.Polymer 4 L //
            X.card = n ∧ Connected X ∧ EntropyBound.originLink L ∈ X} : ℝ)
          * Real.exp (-(iE - D)) ^ n) := by
  refine dependence_defect_kp_summable (C := 6) Connected h_entropy
    (by norm_num) h_defect ?_
  rwa [show (7 : ℝ) * 6 = 42 by norm_num]

end TheoremaAureum.Towers.YM.Wall258
