/-
  H4_Boundary.lean  —  "Module B": a boundary check over the Module-A decode.

  HONEST SCOPE.  This leaf imports the shared mathlib-FREE engine
  `Towers.YM.H4Core` and MEASURES, for a list of witness naturals, two numbers:
  the decimal digit length `digit_len p` and the real `W(H₄)` point-stabilizer
  `symOf p`.  It is:

    • mathlib-FREE (Lean core only); NOT a brick; NOT in `scripts/check-towers.sh`'s
      BRICKS array; NOT a lakefile root (compiled direct).
    • `sorry`-free / `admit`-free / `sorryAx`-free / `native_decide`-free.

  It proves NO Yang–Mills / Navier–Stokes / Riemann / Bost / BSD result, makes NO
  mass-gap / μ>0 / Surface-#1 claim, and is NOT keyed to any prime or L-function.
  `symOf` is PURE FINITE GEOMETRY (a stabilizer order under the linear `W(H₄)`
  action), reported here verbatim from `H4Core.symOf` — never hardcoded.

  HONEST FINDINGS (geometry-first; see the `#eval`s):
    • The proposed `P5 = 10000000001119` has decimal length 14, NOT 13.  So the
      proposed identity `digit_len P5 = C13` is FALSE for this P5; the genuine
      13-digit boundary prime is `1000000001119` (Module A / `H4_Strata_Ztau`),
      which has `digit_len = 13` and `symOf = 1`.  P5's real `symOf` is 1.
    • `symOf 19 = 2` (NOT 20), confirming the Module-A correction.
    • On this 9-point sample the pattern "`digit_len ≥ 13 ⟹ symOf = 1`" and
      "`digit_len < 13 ⟹ symOf ≥ 2`" both hold (`boundary_test` is `true`
      everywhere).  This is a CHECKED SAMPLE FACT, NOT a proved universal law —
      no ∀-theorem over the boundary is asserted.

  `Nat.log10` is unavailable in the core-only setting, so `digit_len` uses the
  Lean-core decimal serialization length `(toString p).length`.
-/

import Towers.YM.H4Core

namespace H4Strata

/-- The boundary digit count under test. -/
def C13 : Nat := 13

/-- Decimal digit length of `p` (Lean-core `toString`; `Nat.log10` is mathlib). -/
def digit_len (p : Nat) : Nat := (toString p).length

/-- `P5` exactly as proposed.  HONEST: `digit_len P5 = 14`, NOT `C13 = 13`. -/
def P5 : Nat := 10000000001119

/-- The genuine 13-digit boundary prime (Module A), for comparison. -/
def P5_thirteen : Nat := 1000000001119

/-- The nine proposed witnesses P1..P9. -/
def boundaryWitnesses : List Nat :=
  [2, 3, 19, 191, 10000000001119, 1000000001357, 1000000001511, 1000000001723, 1000000001831]

/-- Computable boundary check (NOT a universal law): high side
    (`digit_len ≥ 13`) collapses the stabilizer to 1; low side
    (`digit_len < 13`) keeps it `≥ 2`.  Verified on the sample by `#eval`. -/
def boundary_test (p : Nat) : Bool :=
  if 13 ≤ digit_len p then symOf p == 1 else decide (2 ≤ symOf p)

/-! ### Cheap kernel-checked fact (classical trio) -/

/-- `C13 = 13`, definitionally. -/
theorem C13_val : C13 = 13 := rfl

/-! ### Measurements (`#eval`, compiled — not kernel `decide`) -/

-- digit lengths → [1, 1, 2, 3, 14, 13, 13, 13, 13]   (P5 is 14, NOT 13)
#eval boundaryWitnesses.map digit_len
-- real stabilizers from H4Core.symOf (NOT hardcoded) → [120,20,2,2,1,1,1,1,1]
#eval boundaryWitnesses.map symOf
-- P5 as proposed: (digit_len, symOf) = (14, 1)   — digit_len ≠ C13 = 13
#eval (digit_len P5, symOf P5)
-- the genuine 13-digit boundary prime: (digit_len, symOf) = (13, 1)
#eval (digit_len P5_thirteen, symOf P5_thirteen)
-- boundary_test on each witness → [true ×9]
#eval boundaryWitnesses.map boundary_test
-- boundary_test holds on the whole sample → true
#eval boundaryWitnesses.all boundary_test

#print axioms C13_val

end H4Strata
