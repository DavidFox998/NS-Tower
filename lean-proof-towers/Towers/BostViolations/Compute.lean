-- Axiom status: Uses [propext, Classical.choice, Quot.sound] (subset)
-- Scope: COMPUTABLE rational sanity-check of the Bost sum over the REAL
--        14-prime certified set S_14 (and its prefix S_4). Proves NO theorem;
--        asserts NO violation.
/-
================================================================
Towers / BostViolations / Compute — computable rational Bost-sum check
================================================================

**THIS FILE IS NOT A BRICK.** It is a COMPUTABLE (`#eval`-able) rational
sanity check of the Bost sum over the REAL certified prime data: the full
14-prime exceptional set `S_14` (`Defs.S_14`, Module 4 / `bin/print_S14`) and
its leading 4-prime prefix `S_4 = {2,3,19,191}` (`Defs.S_4`, Module 5). It
runs the Bost-bound test across the 12 documented CM curves
(`Twelve.ExceptionalSet₁₂`).

HONESTY NOTES — read before trusting any number printed here:

  * `attached_assets/alpha_sieve_1780282002329.pdf` ("Transcendental Sieve α₀",
    D. Fox) is a ONE-PAGE abstract. It contains NO per-discriminant `α₀(d)`
    table and NO embedded prime list — it only NAMES the generator
    `bin/print_S14` and a SHA-256 "Shaw lock". `print_S14` emits the SINGLE
    14-prime set already encoded verbatim as `Defs.S_14`; it is NOT a
    per-curve family.
  * There is therefore NO per-discriminant `α₀(d)` family. Battle Plan v1.6
    (M1) defines ONE constant α₀ = 299 + π/10 (`Defs.alpha_0`) for the SINGLE
    exceptional set `S(α₀)`. Encoding "12 distinct `α₀(d)`" would require
    fabricating 11 numbers with no source — REFUSED. Hence `S_of_curve` is the
    CONSTANT `Defs.S_14` for every curve (curve-INDEPENDENT, explicit unused
    `_X`); no `opaque`, no `sorry`, no invented data.
  * `ratLog` is a ROUNDED (3-dp) rational approximation of `Real.log` with exact
    table entries only for the small primes 2,3,5,7,11,19,191; the large `S_14`
    primes fall to the coarse `Nat.log2` fallback. So `C_rat` is an
    APPROXIMATION of the real Bost sum `Twelve.C`, for `#eval`/visualisation
    only — the CERTIFIED inequality `C(S_4) > 2√13` is Module 5's external `arb`
    certificate, NOT this `#eval`.
  * The `[]` (no-violation) result is ROBUST to the rounding: `ratLog p ≥ 0` and
    `p/(p-1) > 0` for every prime, so `C_rat` is monotone under set inclusion,
    and `S_4 ⊆ S_14` gives `C_rat S_14 ≥ C_rat S_4 ≈ 11.42 ≫ 7.21` for any
    nonnegative log estimator (including the current `ratLog`). Adding primes
    only GROWS the sum.
    This file asserts NO theorem either way — the violation conjecture
    `Twelve.TwelveViolation_Surface` stays OPEN and unasserted.

SORRY: 0. No `sorry`/`axiom`/`opaque`. Axioms: classical-trio subset.
-/
import Towers.Hodge.Twelve
import Towers.Hodge.Defs
import Mathlib.Data.Rat.Defs
import Mathlib.Data.Finset.Sort
import Mathlib.Algebra.BigOperators.Group.Finset

namespace TheoremaAureum.Towers.BostViolations

open TheoremaAureum.Towers.Hodge.Twelve
open TheoremaAureum.Towers.Hodge.Defs
open BigOperators

/-- Rounded (3-dp) rational approximation of `Real.log n`: hardcoded rounded
constants for the small primes 2,3,5,7,11,19,191; coarse `Nat.log2` fallback for
everything else (incl. the large `S_14` primes). APPROXIMATION ONLY — see file
header. Note `ratLog p ≥ 0` for every `p`. -/
def ratLog (n : ℕ) : ℚ :=
  if n = 2 then 693/1000
  else if n = 3 then 1099/1000
  else if n = 5 then 1609/1000
  else if n = 7 then 1946/1000
  else if n = 11 then 2398/1000
  else if n = 19 then 2944/1000
  else if n = 191 then 5252/1000
  else (Nat.log2 n : ℚ)

/-- Computable rational approximation of the Bost sum
`C(S) = Σ_{p∈S} log p · p/(p-1)` (`Twelve.C`), using `ratLog`. -/
def C_rat (S : Finset ℕ) : ℚ :=
  ∑ p in S, ratLog p * (p : ℚ) / ((p : ℚ) - 1)

/-- The Bost threshold `2√13 ≈ 7.2111`, as a rational approximation. -/
def bostThreshold : ℚ := 7211/1000

/-- The prime set attached to a curve. CONSTANT `Defs.S_14` (the full 14-prime
certified exceptional set, M4 / `bin/print_S14`) for EVERY curve: the source
defines ONE exceptional set `S(α₀)`, not a per-`d` family, so there is no honest
per-curve prime data (see file header). The unused argument is explicit `_X`. -/
def S_of_curve (_X : CM_Curve) : Finset ℕ := S_14

/-- The 12 documented CM curves as a COMPUTABLE list, derived from the real
`Twelve.exceptional_12` via `Finset.sort` (ascending). `Finset.toList` is
noncomputable in mathlib v4.12.0, so we sort to obtain a list usable in
`#eval`; the data is the SAME 12 levels, not a fabricated re-listing. -/
def curves_12 : List CM_Curve :=
  (exceptional_12.sort (· ≤ ·)).map CM_Curve.mk

/-- Bost-bound VIOLATION test for a curve: `true` iff the (approx) Bost sum
does NOT exceed the threshold. EXPECTED `false` for every documented curve. -/
def BostViolation (X : CM_Curve) : Bool :=
  decide (C_rat (S_of_curve X) ≤ bostThreshold)

/-- The levels among the 12 CM curves that (approximately) VIOLATE the Bost
bound. EXPECTED `[]` under the certified data; a non-empty list would witness
a violation. Asserts NO theorem — `Twelve.TwelveViolation_Surface` stays OPEN. -/
def BostViolations_12 : List ℕ :=
  curves_12.filterMap (fun X => if BostViolation X then some X.id else none)

-- Computable witnesses (run at elaboration time):
#eval C_rat S_4                                              -- ≈ 11.42 (M5 reproduction)
#eval C_rat S_14                                             -- full 14-prime set (≫ 11.42)
#eval curves_12.map (fun X => (X.id, C_rat (S_of_curve X))) -- 12 × C_rat S_14 (constant)
#eval BostViolations_12                                     -- expected: []

end TheoremaAureum.Towers.BostViolations
