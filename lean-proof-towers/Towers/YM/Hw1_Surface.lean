-- Axiom status: w1_beta0_lt_seventh uses [propext, Classical.choice, Quot.sound, hw1].
--   The trio-only facts (cert_value_lt_seventh, beta0_in_cert,
--   w1_lt_seventh_of_closed_form) use [propext, Classical.choice, Quot.sound] only.
-- Scope: H1 (`w1 β₀ < 1/7`) is NOT proved in Lean. It is CARRIED by the single
--   disclosed OPEN `axiom hw1`; the only evidence is the OUT-OF-TOWER CERT_Arb
--   certificate (not a Lean term). YM stays Open. NOT a brick, NOT a lakefile root.
/-
Hw1_Surface — HONEST option-2 packaging of H1, the SU(3) single-site Haar weight
strict bound `w1 β₀ < 1/7`, at the CERT_Arb-certified threshold `β₀`.

WHY H1 IS NOT PROVED HERE (and cannot be, in mathlib v4.12.0)
------------------------------------------------------------
Proving `w1 β₀ < 1/7` from the integral definition
`w1 β = ∫_{SU(3)} exp(-β·actL) d haar` (the `actL` of `Towers.YM.Transfer`)
requires THREE ingredients that mathlib v4.12.0 does not have:
  1. the modified Bessel function `I_n` — ABSENT (`find` for any `*bessel*` file
     in mathlib returns nothing; there is no `Real.besselI`);
  2. the SU(3) Weyl integration formula + the Gross–Witten Toeplitz-determinant
     identity that turns the Haar integral into the winding sum below — ABSENT;
  3. a verified interval/Taylor evaluator for `I_n` and `exp`, so the final
     `< 1/7` would be a checkable rational bound — ABSENT (`norm_num` cannot
     decimalise `Real.exp` or any Bessel value; there is no such extension).
Any "proof" filling (1)–(3) with `sorry` would emit `sorryAx`, violating the
ship-clean lock and this file's own axiom contract. So H1 is carried HONESTLY as
the single disclosed OPEN `axiom hw1` — made VISIBLE in `#print axioms`, not
hidden in a `sorry`.

THE OUT-OF-TOWER EVIDENCE (NOT a Lean proof)
--------------------------------------------
The sole evidence for H1 is the rigorous interval certificate
`exports/CERT_Arb_beta0_2026-06-01.yaml` (mpmath.iv, N=36): it encloses
`β₀ ∈ [2.079416880123, 2.079416880124]` with `w1(β₀) ≈ 0.142856757048 < 1/7`,
cross-checked by the EXACT Bessel-determinant closed form
`w1(β) = e^{-β}·∑_{k∈ℤ} det[I_{(i-j)+k}(β/3)]_{3×3}`
(`exports/w1_repo_normalization.py`). Both are OUT-OF-TOWER numerics, NOT Lean
terms. The earlier heuristic threshold `β > 0.85` is REFUTED
(`w1(0.86) = 0.432367 > 1/7`); the un-normalised single Toeplitz det
`e^{-3β}·det[I_{j-i}(2β)]/β²` is also REFUTED (gives 0.029 at β₀, not 1/7).

WHAT THIS FILE ACTUALLY CONTAINS
--------------------------------
* `w1_beta0_lt_seventh : w1 β₀ < 1/7` — the requested theorem, but discharged
  `:= hw1` (the OPEN axiom). It PROVES NOTHING; `#print axioms` reveals the `hw1`
  dependency. closes_surface_1 = false; mass_gap_proven = false.
* `WeylClosedForm` — the exact winding-sum closed form mirrored into Lean as a
  NAMED OPEN `Prop`, stated abstractly over an arbitrary `I : ℤ → ℝ → ℝ` (the
  stand-in for the absent `I_n`). Asserted by NO theorem.
* `w1_lt_seventh_of_closed_form` — the option-2 CONDITIONAL: IF `w1` has the Weyl
  closed form for some `I`, and IF that closed-form value at `β₀` is `< 1/7`
  (the step v4.12.0 cannot evaluate — the SAME un-evaluatable Bessel numeral),
  THEN `w1 β₀ < 1/7`. This RESTATES H1; it discharges nothing. Trio-only.
* `cert_value_lt_seventh`, `beta0_in_cert` — the only GENUINELY Lean-checkable
  facts: the certificate's numeric value lands below `1/7`, and the chosen `β₀`
  literal lies inside the CERT_Arb enclosure `[beta0_lo, beta0_hi]`. Trio-only.
  Neither proves `w1 β₀ < 1/7`.

Honest scope (locked invariants)
--------------------------------
LATTICE SU(3), single-site weight only. NOT Clay, NOT a continuum gap, NOT SU(2).
YM stays `Status: Open`; Surface #1 stays OPEN. Makes NO `μ > 0` / mass-gap /
Surface-#1 claim; discharges NO `sorry`/surface. `w1` is OPAQUE (fixed but
unknown; NO real integral constructed or evaluated). The STRICT `< 1/7` is
essential — `= 1/7` gives `I = log 7` and the divergent entropy series `∑ₙ 1`.
-/

import Towers.YM.Wall256_Scaffold

namespace TheoremaAureum.Towers.YM.Hw1Surface

open Real
open TheoremaAureum.Towers.YM.Wall256Scaffold (Beta0Certified beta0_lo beta0_hi)

/-- The CERT_Arb-certified threshold, pinned to the exact rational upper endpoint
`β₀ = 2.079416880124` of the enclosure `β₀ ∈ [2.079416880123, 2.079416880124]`
(mpmath.iv, N=36). OUT-OF-TOWER interval numerics recorded as a literal, NOT a
Lean proof of any SU(3) integral bound. -/
noncomputable def β₀ : ℝ := 2.079416880124

/-- Abstract SU(3) single-site Haar weight `β ↦ ∫_{SU(3)} exp(-β·actL) d haar`.
OPAQUE — fixed but unknown; NO real integral is constructed or evaluated
(mathlib v4.12.0 has no SU(3) Weyl formula / Bessel functions). -/
opaque w1 : ℝ → ℝ

/-- **H1 — the SU(3) single-site Haar weight strict bound, carried as the SINGLE
explicit OPEN axiom at the certified `β₀`.** `w1 β₀ < 1/7`. OPEN · OUT_OF_TOWER ·
`[NEEDS_NUMERICS]`: the sole evidence is the OUT-OF-TOWER CERT_Arb certificate,
which is NOT a Lean term; mathlib v4.12.0 cannot evaluate the SU(3) Haar integral.
NOT proved here. CONSISTENT (asserts a property of the opaque `w1`; a model with
`w1 := fun _ => 0` satisfies it, so no `False` is derivable). -/
axiom hw1 : w1 β₀ < 1 / 7

/-- **The requested theorem `w1 β₀ < 1/7` — discharged by the OPEN axiom `hw1`,
NOT proved.** This exists only to give the asked-for name a home; its
`#print axioms` is exactly `{propext, Classical.choice, Quot.sound, hw1}`,
exposing the open dependency. It establishes NOTHING about SU(3): the entire
content is the disclosed axiom. closes_surface_1 = false; mass_gap_proven =
false; YM stays Open. -/
theorem w1_beta0_lt_seventh : w1 β₀ < 1 / 7 := hw1

/-- **The exact SU(3) winding-sum closed form, mirrored into Lean as a NAMED OPEN
`Prop`.** Stated abstractly over an arbitrary `I : ℤ → ℝ → ℝ` standing in for the
modified Bessel function `I_n` (ABSENT from mathlib v4.12.0 — this is NOT the real
`I_n`, just a parameter):
`w β = e^{-β} · ∑_{k∈ℤ} det[ I_{(i-j)+k}(β/3) ]_{3×3}` for `β > 0`.
This is the `w1_eq_weyl` bridge. It is asserted by NO theorem; it documents the
closed form's SHAPE without fabricating any Bessel value. OPEN · OUT_OF_TOWER. -/
def WeylClosedForm (w : ℝ → ℝ) (I : ℤ → ℝ → ℝ) : Prop :=
  ∀ β : ℝ, 0 < β →
    w β = Real.exp (-β) *
      ∑' k : ℤ, (Matrix.of (fun i j : Fin 3 => I ((i : ℤ) - (j : ℤ) + k) (β / 3))).det

/-- **Option-2 CONDITIONAL reduction (restates H1; discharges nothing).** IF `w1`
has the Weyl closed form for some `I` (`hcf`, OPEN), and IF that closed-form value
at `β₀` is `< 1/7` (`hval` — the step mathlib v4.12.0 cannot evaluate: it is the
SAME un-evaluatable Bessel numeral, NOT a `norm_num` fact), THEN `w1 β₀ < 1/7`.
This merely rewrites `w1 β₀` by its closed form; it adds NO new evidence for H1.
`#print axioms` = classical trio (`hcf`/`hval` are hypotheses). -/
theorem w1_lt_seventh_of_closed_form (I : ℤ → ℝ → ℝ)
    (hcf : WeylClosedForm w1 I)
    (hval : Real.exp (-β₀) *
        ∑' k : ℤ, (Matrix.of (fun i j : Fin 3 => I ((i : ℤ) - (j : ℤ) + k) (β₀ / 3))).det
        < 1 / 7) :
    w1 β₀ < 1 / 7 := by
  have h0 : (0 : ℝ) < β₀ := by norm_num [β₀]
  rw [hcf β₀ h0]
  exact hval

/-- **Genuinely Lean-checkable fact #1 (trio-only): the CERT_Arb numeric value is
`< 1/7`.** `w1(β₀) ≈ 0.142856757048` per the interval certificate, and
`0.142856757048 < 1/7 = 0.142857142857…`. This checks only the RATIONAL
inequality the certificate lands on; it does NOT prove `w1 β₀ < 1/7` (that is the
opaque axiom `hw1`). -/
theorem cert_value_lt_seventh : (0.142856757048 : ℝ) < 1 / 7 := by norm_num

/-- **Genuinely Lean-checkable fact #2 (trio-only): the chosen `β₀` literal lies
inside the CERT_Arb enclosure `[beta0_lo, beta0_hi]`.** Ties this file's `β₀` to
the `Wall256_Scaffold` certified interval. Numeric bookkeeping only; proves
NOTHING about the SU(3) integral. -/
theorem beta0_in_cert : Beta0Certified β₀ := by
  refine ⟨?_, ?_⟩ <;> norm_num [beta0_lo, beta0_hi, β₀]

end TheoremaAureum.Towers.YM.Hw1Surface

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_beta0_lt_seventh          -- trio + hw1
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_lt_seventh_of_closed_form -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.cert_value_lt_seventh        -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.beta0_in_cert                -- classical trio
