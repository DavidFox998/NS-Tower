import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Complex.ExponentialBounds
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic

/-!
# Wall262a — H4 ratio model `R(a)`: an HONEST standalone numeric model

This brick is the HONEST version of "Theoria's" richer `R`-series writeup. It
keeps Theoria's *narrative* (the H4 Coxeter / 120-cell story, the `2,3,5` prime
structure, the `R = 1 − ∑ Hₙ aⁿ⁻¹/n!` ratio series) as DOCUMENTATION, but the
Lean content it actually machine-checks is only a concrete finite numeric MODEL
plus a clean arithmetic record of the prime structure. It is deliberately a
STANDALONE LEAF: it imports only `Mathlib` (no other Wall), nothing imports it,
and it discharges nothing. **It is OUT of the YM dependency graph.**

## What is machine-checked here (genuine, classical-trio only)

A finitely supported MODEL weight `Hweight` taking the four values Theoria reads
off the H4 ratios — `H₂/S₂ = 1`, `H₃/S₃ = 2`, `H₄/S₄ = 3/2`, `H₅/S₅ = 2` — and
the coherent 4-term model

  `R a := 1 − (term a 2 + term a 3 + term a 4 + term a 5)`,
  `term a n := Hweight n · aⁿ⁻¹ / n!`,

i.e. `R a = 1 − (a/2 + a²/3 + a³/16 + a⁴/60)`. Over this model we prove:

* `Hweight_values`, `Hweight_nonneg`, `term_nonneg` — the model is well-formed
  and every term is `≥ 0` for `a ≥ 0`.
* `R_le_one_sub_half : 0 ≤ a → R a ≤ 1 − a/2` — the HONEST reduction. Because the
  last three terms are nonnegative, dropping them gives `R a ≤ 1 − a/2`. (No
  alternating signs, no ratio-test tail: see the honesty note below.)
* `exp_neg88_lower : 257/1000 ≤ exp(−0.88)` — via `exp 0.88 ≤ exp 1 < 2.7182…`,
  so `exp(−0.88) = (exp 0.88)⁻¹ ≥ (2.7182…)⁻¹ ≈ 0.368 ≥ 0.257`.
* `R_le : R (exp(−0.88)) ≤ 1743/2000` — the headline, since `a ≥ 257/1000`
  forces `1 − a/2 ≤ 1 − 257/2000 = 1743/2000`. `257/1000` is exactly the
  break-even of `1 − a/2 = 1743/2000`.

An honest machine-checked nod to the prime structure Theoria emphasizes:

* `factorial_smooth` — `2! , 3! , 4! , 5!` are all `5`-smooth
  (`2, 2·3, 2³·3, 2³·3·5`), so every denominator through `n = 5` uses only the
  primes `2, 3, 5`.
* `seven_enters_at_seven` — `7! = 2⁴·3²·5·7`: the prime `7` (the polymer-entropy
  prime, `log 7`) first appears at `n = 7`, BEYOND this truncation. The 5-smooth
  pattern is therefore a truncation artifact, not a property of the full series.
* `threshold_factorization` — `1743 = 3·7·83`, `2000 = 2⁴·5³`. So the threshold
  `0.8715 = 1743/2000` is a terminating rational whose primes are `2, 3, 5`
  (denominator), `7`, and the lone large prime `83` (numerator).

## DOCUMENTARY ONLY — and where Theoria is WRONG

The following are recorded as narrative context; NONE of it is machine-checked
here, and the flagged claims are FALSE in mathlib v4.12.0:

* **The H4 Coxeter matrix `M_H4 = !![2,-1,0,0; -1,2,-1,0; 0,-1,2,-φ; 0,0,-φ,2]`,
  the 120-cell, `h = 30`, the exponents `1,11,19,29`, `φ` as the highest-root
  norm.** mathlib v4.12.0 has no 120-cell adjacency, no
  `CoxeterGroup.H4.spectral_radius` / `.subgraph_count` / `.highest_root_norm`
  (these do NOT exist — verified against the source), and no det/charpoly↔
  eigenvalue bridge.
* **Theoria's "the largest eigenvalue of `2I − M_H4` equals `φ = 2cos(π/5)`" is
  FALSE.** The largest eigenvalue is `2cos(π/30) ≈ 1.989` (the Coxeter number is
  `h = 30`); `φ ≈ 1.618` is NOT an eigenvalue at all — the char poly evaluates to
  `−φ² ≠ 0` at `λ = φ`. (This is exactly what `Wall263_CoxeterSpectral` proves;
  see that brick for the machine-checked refutation.)
* **Theoria's alternating-sign / `R ≤ 0.6665` arithmetic is incoherent.** With
  all-positive H4 ratios the series is `1 − ∑(positive)`, so the signs do not
  alternate, and the coherent value is `R(exp(−0.88)) ≈ 0.73`, not `0.6685`. We
  therefore use the coherent all-positive 4-term model and the trivial
  drop-the-tail bound, which still clears `0.8715` with enormous margin.

## Honest scope (LOCKED)

This is a STANDALONE NUMERIC MODEL with concrete invented weights. It does **NOT**
discharge `Wall262`'s open hypothesis `hR` (the real connective ratio
`R := μ_ℤ⁴/φ`, which needs the actual SU(2) plaquette connective constant — that
is research-level, not a 4-term sum). It does **NOT** use any real Coxeter/H4
datum (none is formalizable here). It proves **NO** YM result and discharges no
open surface; YM stays `Status: Open`.

All public theorems are `sorry`-free and `#print axioms` = the classical trio.
-/

namespace TheoremaAureum.Towers.YM.Wall262a

open Real

noncomputable section

/-- MODEL H4 ratio weights `Hₙ/Sₙ`: the four values Theoria reads off
(`1, 2, 3/2, 2` at `n = 2,3,4,5`) and `0` beyond. Finitely supported, INVENTED —
not extracted from any real Coxeter datum. -/
def Hweight (n : ℕ) : ℝ :=
  if n = 2 then 1 else if n = 3 then 2 else if n = 4 then 3 / 2 else if n = 5 then 2 else 0

/-- The `n`-th term of the ratio series, `Hₙ · aⁿ⁻¹ / n!`. -/
def term (a : ℝ) (n : ℕ) : ℝ := Hweight n * a ^ (n - 1) / (n.factorial : ℝ)

/-- The coherent 4-term model `R a = 1 − (a/2 + a²/3 + a³/16 + a⁴/60)`. -/
def R (a : ℝ) : ℝ := 1 - (term a 2 + term a 3 + term a 4 + term a 5)

/-- The four model weights, as Theoria reads them off the H4 ratios. -/
theorem Hweight_values :
    Hweight 2 = 1 ∧ Hweight 3 = 2 ∧ Hweight 4 = 3 / 2 ∧ Hweight 5 = 2 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> · unfold Hweight; norm_num

/-- Every model weight is nonnegative. -/
theorem Hweight_nonneg (n : ℕ) : 0 ≤ Hweight n := by
  unfold Hweight; split_ifs <;> norm_num

/-- Every term is nonnegative for `a ≥ 0`. -/
theorem term_nonneg (a : ℝ) (ha : 0 ≤ a) (n : ℕ) : 0 ≤ term a n := by
  unfold term
  apply div_nonneg
  · exact mul_nonneg (Hweight_nonneg n) (pow_nonneg ha _)
  · exact Nat.cast_nonneg _

/-- HONEST reduction: dropping the three nonnegative tail terms gives
`R a ≤ 1 − a/2`. -/
theorem R_le_one_sub_half (a : ℝ) (ha : 0 ≤ a) : R a ≤ 1 - a / 2 := by
  have e2 : term a 2 = a / 2 := by
    have h : Hweight 2 = 1 := by unfold Hweight; norm_num
    unfold term; rw [h]; norm_num [Nat.factorial]
  have h3 := term_nonneg a ha 3
  have h4 := term_nonneg a ha 4
  have h5 := term_nonneg a ha 5
  unfold R
  linarith

/-- `257/1000 ≤ exp(−0.88)`: via `exp 0.88 ≤ exp 1 < 2.7182818286`, then invert.
`257/1000` is exactly the break-even of `1 − a/2 = 1743/2000`. -/
theorem exp_neg88_lower : (257 : ℝ) / 1000 ≤ Real.exp (-0.88) := by
  have hpos : 0 < Real.exp 0.88 := Real.exp_pos _
  have hub : Real.exp 0.88 < 2.7182818286 :=
    lt_of_le_of_lt (Real.exp_le_exp.mpr (by norm_num : (0.88 : ℝ) ≤ 1)) Real.exp_one_lt_d9
  -- launder the decimal `OfScientific` literal to an exact rational so linarith
  -- can compute with it (it treats decimals as opaque atoms otherwise).
  have hc : (2.7182818286 : ℝ) = 27182818286 / 10000000000 := by norm_num
  rw [hc] at hub
  rw [Real.exp_neg, inv_eq_one_div, le_div_iff₀ hpos]
  linarith

/-- Headline: the model `R` at `a = exp(−0.88)` clears the threshold
`1743/2000 = 0.8715`, with enormous margin (`R ≈ 0.73`). -/
theorem R_le : R (Real.exp (-0.88)) ≤ 1743 / 2000 := by
  have ha : 0 ≤ Real.exp (-0.88) := (Real.exp_pos _).le
  have hred := R_le_one_sub_half (Real.exp (-0.88)) ha
  have hlow := exp_neg88_lower
  linarith

/-- Prime-structure record: `2! , 3! , 4! , 5!` are all `5`-smooth — every
denominator through `n = 5` uses only the primes `2, 3, 5`. -/
theorem factorial_smooth :
    Nat.factorial 2 = 2 ∧ Nat.factorial 3 = 2 * 3 ∧
      Nat.factorial 4 = 2 ^ 3 * 3 ∧ Nat.factorial 5 = 2 ^ 3 * 3 * 5 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> decide

/-- The prime `7` (the polymer-entropy prime `log 7`) first enters at `7!`,
beyond this truncation: `7! = 2⁴·3²·5·7`. -/
theorem seven_enters_at_seven : Nat.factorial 7 = 2 ^ 4 * 3 ^ 2 * 5 * 7 := by
  decide

/-- The threshold `0.8715 = 1743/2000` is a terminating rational:
`1743 = 3·7·83`, `2000 = 2⁴·5³`. -/
theorem threshold_factorization : (1743 : ℕ) = 3 * 7 * 83 ∧ (2000 : ℕ) = 2 ^ 4 * 5 ^ 3 := by
  refine ⟨?_, ?_⟩ <;> norm_num

end

end TheoremaAureum.Towers.YM.Wall262a
