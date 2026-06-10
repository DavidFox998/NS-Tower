-- Axiom status: `hw1` (= `w1_beta0_lt_seventh`) depends on
--   [propext, Classical.choice, Quot.sound, w1_eq_weyl, w1_weyl_beta0_lt].
--   The two `[NEEDS_LEMMA]` axioms (`w1_eq_weyl`, `w1_weyl_beta0_lt`) are the only
--   non-trio axioms. `cert_value_lt_seventh` / `beta0_in_cert` use the trio only;
--   `lattice_decay_conditional` inherits {trio, w1_eq_weyl, w1_weyl_beta0_lt} via `hw1`.
-- Scope: H1 (`w1 β₀ < 1/7`) is NOT proved — it is DERIVED from the two disclosed
--   OPEN axioms, both `[NEEDS_LEMMA]`, validated only by the OUT-OF-TOWER CERT_Arb
--   certificate. YM stays Open; Surface #1 stays OPEN. NOT a brick / lakefile root.
/-
Hw1_Surface — HONEST packaging of H1, the SU(3) single-site Haar weight strict
bound `w1 β₀ < 1/7`, DERIVED from two disclosed OPEN `[NEEDS_LEMMA]` axioms.

WHY H1 IS NOT PROVED (and cannot be, in mathlib v4.12.0)
-------------------------------------------------------
`w1 β = ∫_{SU(3)} exp(-β·actL) d haar` (the `actL` of `Towers.YM.Transfer`) needs
three ingredients mathlib v4.12.0 lacks: (1) the modified Bessel function `I_n`
(`find *bessel*` returns nothing; no `Real.besselI`); (2) the SU(3) Weyl
integration formula + the Gross–Witten Toeplitz-determinant identity; (3) a
verified interval/Taylor evaluator for `I_n`/`exp` (so `norm_num` cannot
decimalise the final `< 1/7`). Any `sorry` filler would emit `sorryAx`. So the
two analytic facts are carried as DISCLOSED OPEN axioms, made VISIBLE in
`#print axioms` — NOT hidden in a `sorry`.

THE TWO OPEN `[NEEDS_LEMMA]` AXIOMS
-----------------------------------
* `w1_eq_weyl : w1 β₀ = w1_weyl β₀` — the SU(3) Weyl / Gross–Witten closed form.
* `w1_weyl_beta0_lt : w1_weyl β₀ < 1/7` — the truncated (K=3) winding sum bound.
`hw1` is DERIVED by rewriting along the first and applying the second; its footprint
is exactly {trio, w1_eq_weyl, w1_weyl_beta0_lt}. Both axioms are validated ONLY by
the OUT-OF-TOWER CERT_Arb numerics (`exports/CERT_Arb_beta0_2026-06-01.yaml`,
mpmath.iv N=36: `β₀ ∈ [2.079416880123, 2.079416880124]`, `w1(β₀) ≈ 0.142856757048
< 1/7`), cross-checked by `exports/w1_repo_normalization.py`. They are CONSISTENT:
`w1` and `besselI` are opaque, so a model (`w1 β₀ = w1_weyl β₀ = 0`) satisfies
both; no `False` is derivable.

Honest scope (locked invariants)
--------------------------------
LATTICE SU(3), single-site weight only. NOT Clay, NOT a continuum gap, NOT SU(2).
YM stays `Status: Open`; Surface #1 stays OPEN. Makes NO `μ > 0` / mass-gap /
Surface-#1 claim. `w1` and `besselI` are OPAQUE (fixed but unknown; NO real
integral or Bessel value constructed). The STRICT `< 1/7` is essential — `= 1/7`
gives `I = log 7` and the divergent entropy series `∑ₙ 1`.
-/

import Towers.YM.Wall256_Scaffold

namespace TheoremaAureum.Towers.YM.Hw1Surface

open Real
open TheoremaAureum.Towers.YM.Wall256Note (TruncatedActivityBound)
open TheoremaAureum.Towers.YM.Wall256Scaffold
  (Beta0Certified beta0_lo beta0_hi strong_coupling_decay_of_open_inputs)

/-- The CERT_Arb-certified threshold, pinned to the exact rational upper endpoint
`β₀ = 2.079416880124` of `β₀ ∈ [2.079416880123, 2.079416880124]` (mpmath.iv,
N=36). OUT-OF-TOWER interval numerics as a literal, NOT a Lean proof. -/
noncomputable def β₀ : ℝ := 2.079416880124

/-- Abstract SU(3) single-site Haar weight `β ↦ ∫_{SU(3)} exp(-β·actL) d haar`.
OPAQUE — fixed but unknown; NO real integral constructed (no SU(3) Weyl formula in
mathlib v4.12.0). -/
opaque w1 : ℝ → ℝ

/-- Stand-in for the modified Bessel function `I_n` — ABSENT from mathlib v4.12.0.
OPAQUE (fixed but unknown); this is NOT the real `I_n`, and no Bessel value is
fabricated. -/
opaque besselI : ℤ → ℝ → ℝ

/-- The SU(3) Weyl / Gross–Witten **closed form** as a concrete Lean `def`: the
`3×3` Toeplitz-determinant winding sum at `β/3`,
`w1_weyl β = e^{-β} · ∑_{k∈ℤ} det[ besselI ((i-j)+k) (β/3) ]_{3×3}`.
`noncomputable` (uses `Real.exp`, a `tsum`, and `Matrix.det` over the opaque
`besselI`). -/
noncomputable def w1_weyl (β : ℝ) : ℝ :=
  Real.exp (-β) *
    ∑' k : ℤ, (Matrix.of (fun i j : Fin 3 => besselI ((i : ℤ) - (j : ℤ) + k) (β / 3))).det

/-- **`[NEEDS_LEMMA]` axiom #1 — the SU(3) Weyl / Gross–Witten formula at `β₀`.**
`w1 β₀ = w1_weyl β₀`. OPEN · OUT_OF_TOWER: the Weyl integration formula and the
Gross–Witten Toeplitz identity are ABSENT from mathlib v4.12.0; validated only by
the CERT_Arb certificate, NOT proved. -/
axiom w1_eq_weyl : w1 β₀ = w1_weyl β₀

/-- **`[NEEDS_LEMMA]` axiom #2 — the truncated (K=3) winding sum is below `1/7` at
`β₀`.** `w1_weyl β₀ < 1/7`. OPEN · OUT_OF_TOWER · `[NEEDS_NUMERICS]`: `norm_num`
cannot decimalise `Real.exp`/`besselI`, so this strict inequality cannot be
evaluated in Lean; validated only by CERT_Arb (`w1_weyl β₀ ≈ 0.142856757048`). -/
axiom w1_weyl_beta0_lt : w1_weyl β₀ < 1 / 7

/-- **H1 — `w1 β₀ < 1/7`, DERIVED from the two `[NEEDS_LEMMA]` axioms.** Rewrites
`w1 β₀` by the Weyl formula and applies the truncated bound. NO `sorry`. PROVES
NOTHING new about SU(3): `#print axioms` is exactly
`{propext, Classical.choice, Quot.sound, w1_eq_weyl, w1_weyl_beta0_lt}`, exposing
the two open dependencies. closes_surface_1 = false; mass_gap_proven = false; YM
stays Open. -/
theorem hw1 : w1 β₀ < 1 / 7 := by
  rw [w1_eq_weyl]; exact w1_weyl_beta0_lt

/-- Alias under the requested name; same footprint as `hw1`. -/
theorem w1_beta0_lt_seventh : w1 β₀ < 1 / 7 := hw1

/-- **Genuinely Lean-checkable fact #1 (trio-only): the CERT_Arb numeric value is
`< 1/7`.** `w1(β₀) ≈ 0.142856757048 < 1/7 = 0.142857142857…`. Checks only the
RATIONAL inequality the certificate lands on; does NOT prove `w1 β₀ < 1/7`. -/
theorem cert_value_lt_seventh : (0.142856757048 : ℝ) < 1 / 7 := by norm_num

/-- **Genuinely Lean-checkable fact #2 (trio-only): the `β₀` literal lies inside
the CERT_Arb enclosure `[beta0_lo, beta0_hi]`.** Numeric bookkeeping only; proves
NOTHING about the SU(3) integral. -/
theorem beta0_in_cert : Beta0Certified β₀ := by
  refine ⟨?_, ?_⟩ <;> norm_num [beta0_lo, beta0_hi, β₀]

/-! ### The honest version of the requested `closes_surface_1`

Discharging the two Weyl axioms does NOT close Surface #1. Per
`Wall256Scaffold.strong_coupling_decay_of_open_inputs`, `w1 < 1/7` (now supplied by
`hw1`) is only ONE of THREE open lattice inputs — `hOS` (Osterwalder–Seiler
Ursell/cluster) and `h_bridge` (Brydges–Federbush KP ⟹ clustering) remain OPEN —
and even with all three the conclusion is an abstract LATTICE two-point decay
shape, necessary-not-sufficient for the continuum Yang–Mills mass gap. So the
deliverable below is named for what it is — a conditional lattice reduction, NOT a
closure. Surface #1 and the YM tower stay OPEN. -/

/-- **CONDITIONAL lattice reduction (the honest `closes_surface_1`).** Using `hw1`
(H1) plus the two further OPEN lattice inputs `hOS` and `h_bridge` and a polymer
entropy count `N n ≤ 7ⁿ`, the abstract two-point decay shape follows by threading
them through `strong_coupling_decay_of_open_inputs`. `corr`/`sep` are ABSTRACT.
LATTICE only; NOT Clay; does NOT close Surface #1; YM stays Open. Footprint
inherits {trio, w1_eq_weyl, w1_weyl_beta0_lt} via `hw1`. -/
theorem lattice_decay_conditional
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ) {N a : ℕ → ℝ}
    (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (hOS : w1 β₀ < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  strong_coupling_decay_of_open_inputs corr sep C ρ (w1 β₀) hN0 hN hw1 hOS h_bridge

end TheoremaAureum.Towers.YM.Hw1Surface

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.hw1                  -- trio + w1_eq_weyl + w1_weyl_beta0_lt
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_beta0_lt_seventh  -- trio + w1_eq_weyl + w1_weyl_beta0_lt
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.cert_value_lt_seventh -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.beta0_in_cert         -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.lattice_decay_conditional -- trio + w1_eq_weyl + w1_weyl_beta0_lt
