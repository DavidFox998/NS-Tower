/-
  H4_TimeBound.lean  —  "Module C": a magnitude comparison over the Module-A decode.

  HONEST SCOPE.  This leaf imports the shared mathlib-FREE engine
  `Towers.YM.H4Core` and, for a list of 13-digit witness naturals, MEASURES the
  decimal length `digit_len p`, the real `W(H₄)` stabilizer `symOf p`, and the
  plain integer comparisons against two named constants:

    • `TimeHorizon := 3^40 = 12157665459056928801`
    • `C13_digit_min := 10^12 = 1000000000000`  (smallest 13-digit number)

  It is mathlib-FREE (Lean core only); NOT a brick; NOT in BRICKS; NOT a lakefile
  root (compiled direct); `sorry`/`admit`/`sorryAx`/`native_decide`-free.

  HONEST SCOPE-LIMITS.  The name "TimeHorizon" carries NO dynamical, physical, or
  temporal meaning here — `3^40` is simply an integer the witnesses are compared
  against.  This file proves NO Yang–Mills / Navier–Stokes / Riemann / Bost / BSD
  result, makes NO mass-gap / μ>0 / Surface-#1 claim, and `symOf` is reported
  verbatim from `H4Core.symOf` (never hardcoded).  PURE FINITE GEOMETRY + plain
  ℕ arithmetic.

  OBSERVED (geometry-first; see the `#eval`s):
    • Every witness has `digit_len = 13`, `symOf = 1`, and `p < 3^40`
      (so `below_3_40 = true` for all; `p > TimeHorizon` is false for all).
    • The sample pattern "`p > 10^12 ⟹ symOf = 1`" holds on all six points
      (`time_bound_test` is `true` everywhere).  This is a CHECKED SAMPLE FACT,
      NOT a proved ∀-law: it is NOT established that every `p > 10^12` has
      `symOf = 1`, nor that `10^12` is a universal boundary.
    • `10^12 < 3^40` by ~7 orders of magnitude.  So IF `3^40` were intended as a
      horizon for the `symOf = 1` collapse, it sits far above where the collapse
      is first seen on this sample — i.e. far larger than necessary on these
      data.  This is a magnitude observation, NOT a proof about all `p`.
-/

import Towers.YM.H4Core

namespace H4Strata

/-- Decimal digit length of `p` (Lean-core `toString`; `Nat.log10` is mathlib). -/
def digit_len (p : Nat) : Nat := (toString p).length

/-- The exponent under test. -/
def N40 : Nat := 40

/-- `3^40 = 12157665459056928801`.  A plain integer — NO temporal meaning. -/
def TimeHorizon : Nat := 3 ^ N40

/-- The smallest 13-digit number, `10^12 = 1000000000000`. -/
def C13_digit_min : Nat := 10 ^ 12

/-- The genuine 13-digit boundary prime (Module A / Module B). -/
def P5_13 : Nat := 1000000001119

/-- The six 13-digit witnesses (P5_13, P6..P10). -/
def timeWitnesses : List Nat :=
  [1000000001119, 1000000001357, 1000000001511, 1000000001723, 1000000001831, 1000000002111]

/-- `true` iff `p` is strictly below the `3^40` horizon. -/
def below_3_40 (p : Nat) : Bool := decide (p < TimeHorizon)

/-- Computable sample check of "`p > 10^12 ⟹ symOf = 1`" (an implication, NOT a
    universal law): false antecedent or `symOf p = 1`.  `#eval`-verified only. -/
def time_bound_test (p : Nat) : Bool :=
  (! decide (C13_digit_min < p)) || (symOf p == 1)

/-! ### Cheap kernel-checked facts (classical trio) -/

/-- `N40 = 40`, definitionally. -/
theorem N40_val : N40 = 40 := rfl

/-- The honest magnitude gap: `10^12 < 3^40`. -/
theorem min_lt_horizon : C13_digit_min < TimeHorizon := by decide

/-! ### Measurements (`#eval`, compiled — not kernel `decide`) -/

-- TimeHorizon = 3^40 = 12157665459056928801
#eval TimeHorizon
-- C13_digit_min = 10^12 = 1000000000000  (digit_len 13)
#eval (C13_digit_min, digit_len C13_digit_min)
-- digit lengths → [13, 13, 13, 13, 13, 13]
#eval timeWitnesses.map digit_len
-- real stabilizers from H4Core.symOf (NOT hardcoded) → [1, 1, 1, 1, 1, 1]
#eval timeWitnesses.map symOf
-- p > TimeHorizon → [false ×6]   (every witness is below 3^40)
#eval timeWitnesses.map (fun p => decide (p > TimeHorizon))
-- below_3_40 → [true ×6]
#eval timeWitnesses.map below_3_40
-- time_bound_test (p > 10^12 ⟹ symOf = 1) → [true ×6]
#eval timeWitnesses.map time_bound_test
-- whole-sample: time_bound_test all true
#eval timeWitnesses.all time_bound_test

#print axioms N40_val
#print axioms min_lt_horizon

end H4Strata
