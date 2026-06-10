/-
================================================================
Towers / YM / Wall262_ConnectiveRatio

**The connective-ratio defect bound → SU(2) polymer-rate win — honest
CONDITIONAL combinator.**

Sequel to `Wall261_H4Defect`. Where Wall261 records the H4 constant `1 + φ`
abstractly, this wall encodes the requested "ratio of two expansion rates"
quantitative form and lands BOTH requested theorems over a single genuine
arithmetic core:

* `defect_bound` (the cluster / Ursell bound) — here the NAMED OPEN hypothesis
  `h_defect : Defect ≤ Real.log (1 + φ * R)`.
* `su2_wins` — `Real.log 7 < I_E − Defect`, i.e. `I_E > Real.log 7 + Defect`:
  the polymer rate `I_polymer = I_E − Defect` (cf. `Wall259.polymerRate`) clears
  the bare entropy threshold `log 7`.

The picture: `φ = (1 + √5)/2` is the H4 rate; `μ_Z4` is the ℤ⁴ plaquette
connective constant (ABSTRACT — asserted nowhere); the ratio is `R := μ_Z4 / φ`.
"H4 shrinks the rate" is the bound `R ≤ 1743/2000 = 0.8715`, which through
`Defect ≤ log(1 + φ·R)` forces `Defect < 22/25 = 0.88`, and together with the
SU(2) rate clearing the raised bar (`log 7 + 0.88 ≤ I_E`) gives the polymer-rate
win `log 7 < I_E − Defect`.

WHAT IS GENUINE / UNCONDITIONAL (classical trio, no `sorry`):
* `phi_lt` — `φ < 32361/20000` (= 1.61805), a sharp rational upper bound from
  `√5 < 2.2361`.
* `exp_lower` — `12053/5000 ≤ Real.exp (22/25)` (= `2.4106 ≤ e^0.88`), the sharp
  lower bound on `e^0.88` via the degree-7 Taylor remainder `Real.exp_bound`
  (a degree-2 bound gives only `2.2672`, a degree-6 only `2.4094 < 2.4101` — the
  margin to `1 + φ·0.8715 = 2.41013` genuinely needs order 7).
* `defect_bound_arith` — `0 ≤ R → R ≤ 1743/2000 → Real.log (1 + φ*R) < 22/25`:
  the heart, via `Real.log_lt_iff_lt_exp` then `1 + φ·R < 12053/5000 ≤ e^0.88`.
* `threshold_factorization` — `(1743 : ℕ) = 3*7*83 ∧ (2000 : ℕ) = 2^4 * 5^3`:
  the honest record that `0.8715 = 1743/2000` is a TERMINATING rational with a
  finite continued fraction (the "endless 9s" reading was floating-point noise).

WHAT IS CONDITIONAL (named-open hypotheses — NOT Lean `axiom`s, NOT `by sorry`):
* `defect_lt` — from `h_defect : Defect ≤ log(1 + φ*R)` (the cluster/Ursell
  bound) and `R ≤ 1743/2000`, conclude `Defect < 22/25`.
* `su2_wins` — additionally taking `h_rate : Real.log 7 + 22/25 ≤ I_E` (the SU(2)
  large-deviation rate clearing the raised threshold; same family as
  Wall256/258/259's `h_rate`), conclude `Real.log 7 < I_E − Defect`.

## Honest scope (locked)

* **This proves NO Yang–Mills result.** It is a REDUCTION/IMPROVEMENT in the
  Wall259/260/261 family. `R`, `Defect`, `I_E`, `μ_Z4` are abstract reals; the
  bound `R ≤ 1743/2000` (`hR`), the cluster bound `h_defect`, and the rate bound
  `h_rate` are all NAMED OPEN hypotheses, proved NOWHERE here.
* **No numeric value for `μ_Z4` is asserted.** `μ_Z4 = 2.99314` would give
  `R = 1.85 > 1` and FAIL `hR`; the real plaquette connective constant `≈ 3`
  makes `R < 0.8715` likely FALSE for the genuine object. The bound is kept as an
  abstract hypothesis precisely because it is not established for the real model.
* **The Ursell power series is NOT encoded.** Numerically the stated weight
  schemes do not reproduce `R = 0.8715` at `a = e^{-0.88}`; `0.8715` is the
  reverse-engineered break-even of `log(1 + φ·R) = 0.88`, not a series output.
  Hard-coding a series would be false, so only the abstract bound `hR` is used.
* **`Real.log 7 < I_E − Defect` is the tower's genuine polymer criterion**
  (`I_polymer = I_E − Defect`, `Wall259.polymerRate`), NOT a constructed SU(2)
  rate functional. Makes NO mass-gap / `μ > 0` / Surface-#1 / RH / BSD claim,
  discharges NO open surface, and does NOT touch `kotecky_preiss_criterion`. YM
  stays `Status: Open`.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`, no
`sorryAx`, no new axioms. Reuses `Wall261.phi` / `Wall261.phi_pos` /
`Wall261.sqrt_five_sq`; uses `Real.exp_bound`, `Real.log_lt_iff_lt_exp`.
================================================================
-/

import Towers.YM.Wall261_H4Defect
import Mathlib.Analysis.SpecialFunctions.Log.Basic

namespace TheoremaAureum.Towers.YM.Wall262

open TheoremaAureum.Towers.YM

/-- **GENUINE.** Sharp rational upper bound `φ < 32361/20000` (= 1.61805), from
`√5 < 2.2361`. -/
theorem phi_lt : Wall261.phi < 32361 / 20000 := by
  have h5 : Real.sqrt 5 < 22361 / 10000 := by
    nlinarith [Wall261.sqrt_five_sq, Real.sqrt_nonneg 5,
      sq_nonneg (Real.sqrt 5 - 22361 / 10000)]
  unfold Wall261.phi
  linarith

/-- **GENUINE.** Sharp lower bound `12053/5000 ≤ e^{0.88}` (= `2.4106 ≤ e^0.88`,
true value `2.41090`), via the degree-7 Taylor remainder `Real.exp_bound`. A
degree-2 bound gives only `2.2672` and a degree-6 only `2.4094 < 2.41013`, so the
order-7 term is genuinely required for the margin. -/
theorem exp_lower : (12053 / 5000 : ℝ) ≤ Real.exp (22 / 25) := by
  have habs : |(22 / 25 : ℝ)| = 22 / 25 := abs_of_nonneg (by norm_num)
  have hb := Real.exp_bound (x := (22 / 25 : ℝ)) (by rw [habs]; norm_num)
      (n := 7) (by norm_num)
  rw [abs_le] at hb
  obtain ⟨hlo, _⟩ := hb
  rw [habs] at hlo
  norm_num [Finset.sum_range_succ, Finset.sum_range_zero, Nat.factorial] at hlo
  linarith

/-- **GENUINE — the arithmetic heart.** For `0 ≤ R ≤ 1743/2000`,
`Real.log (1 + φ·R) < 22/25` (= 0.88). Proof: `1 + φ·R < 12053/5000 ≤ e^{0.88}`
via `Real.log_lt_iff_lt_exp`. -/
theorem defect_bound_arith {R : ℝ} (hR0 : 0 ≤ R) (hR : R ≤ 1743 / 2000) :
    Real.log (1 + Wall261.phi * R) < 22 / 25 := by
  have hphiR : 0 ≤ Wall261.phi * R := mul_nonneg Wall261.phi_pos.le hR0
  have hpos : (0 : ℝ) < 1 + Wall261.phi * R := by linarith
  rw [Real.log_lt_iff_lt_exp hpos]
  have hub : 1 + Wall261.phi * R < 12053 / 5000 := by
    nlinarith [phi_lt, hR0, hR, Wall261.phi_pos,
      mul_nonneg (sub_nonneg.2 phi_lt.le) hR0]
  exact lt_of_lt_of_le hub exp_lower

/-- **GENUINE.** `0.8715 = 1743/2000` is a TERMINATING rational: `1743 = 3·7·83`
and `2000 = 2^4·5^3` (finite continued fraction; the "endless 9s" reading was
floating-point noise). -/
theorem threshold_factorization :
    (1743 : ℕ) = 3 * 7 * 83 ∧ (2000 : ℕ) = 2 ^ 4 * 5 ^ 3 := by
  constructor <;> norm_num

/-- **CONDITIONAL.** From the NAMED OPEN cluster/Ursell bound
`h_defect : Defect ≤ log(1 + φ·R)` and the ratio bound `R ≤ 1743/2000`
(`hR`, also NAMED OPEN — the ρ<1 ratio test), the defect clears `Defect < 22/25`.
`h_defect`/`hR` are HYPOTHESES, NOT Lean `axiom`s; proves NO YM result. -/
theorem defect_lt {R Defect : ℝ} (hR0 : 0 ≤ R) (hR : R ≤ 1743 / 2000)
    (h_defect : Defect ≤ Real.log (1 + Wall261.phi * R)) : Defect < 22 / 25 :=
  lt_of_le_of_lt h_defect (defect_bound_arith hR0 hR)

/-- **CONDITIONAL — "SU(2) wins".** Additionally taking the NAMED OPEN SU(2) rate
bound `h_rate : log 7 + 22/25 ≤ I_E` (the single-site rate clearing the
defect-raised threshold; same family as Wall256/258/259), the polymer rate clears
the bare entropy threshold: `Real.log 7 < I_E − Defect`. This is the genuine
polymer criterion `log 7 < I_polymer` with `I_polymer = I_E − Defect`
(`Wall259.polymerRate`). `h_defect`/`h_rate`/`hR` are HYPOTHESES, NOT Lean
`axiom`s; proves NO YM result. -/
theorem su2_wins {R Defect I_E : ℝ} (hR0 : 0 ≤ R) (hR : R ≤ 1743 / 2000)
    (h_defect : Defect ≤ Real.log (1 + Wall261.phi * R))
    (h_rate : Real.log 7 + 22 / 25 ≤ I_E) :
    Real.log 7 < I_E - Defect := by
  have hd : Defect < 22 / 25 := defect_lt hR0 hR h_defect
  linarith

end TheoremaAureum.Towers.YM.Wall262
