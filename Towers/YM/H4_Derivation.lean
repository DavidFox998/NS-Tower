/-
  H4_Derivation.lean  —  "Module D": the boundary law, stated HONESTLY as an OPEN
  conjecture (NOT proven).

  HONEST SCOPE.  The proposed
      `C13_law : ∀ p, p.Prime → digit_len p ≥ 13 → symOf p = 1`
  is NOT proved here, and CANNOT be proved in this module's setting.  Three
  independent blockers, each fatal on its own:

    1. INFINITE / UNDECIDABLE QUANTIFIER.  The statement ranges over all primes
       (infinitely many).  No finite computation settles it.  A genuine proof
       needs a general structural theorem — "every ≥13-digit decode lands off the
       fixed locus of every nontrivial `W(H₄)` element" — which is NOT established
       and may be false for some large prime (the decode can hit special points).
       We do not have, and do not assert, such a theorem.

    2. THE GEOMETRY IS NOT KERNEL-CHECKABLE.  `symOf` is a 14400-pair enumeration
       over the 960-int table; kernel `decide` overflows `maxRecDepth` on even a
       single `symOf 191` (confirmed 2026-06-02).  So `symOf p = 1` is not
       provable by `decide`/`rfl` even for ONE prime, let alone a list — which is
       exactly why Modules A/B/C report `symOf` via `#eval` (compiled), never as a
       kernel proof.

    3. `p.Prime` / `Nat.log10` NEED mathlib.  This H4 line is mathlib-FREE and
       compiled direct precisely because the lake/mathlib build is the documented
       destructive operation in this environment.  Neither symbol is available
       here; a faithful statement must supply its own primality predicate.

  Therefore this leaf records `C13_law` as a NAMED OPEN `Prop` (`C13_Law_Open`),
  carries the `#eval` sample evidence as `boundary_proven : Bool`, and proves only
  cheap axiom-free facts.  NO `sorry` / `admit` / `sorryAx` / `native_decide`;
  NOT a brick; NOT in BRICKS; NOT a lakefile root; compiled direct.  It proves NO
  Yang–Mills / mass-gap / Surface-#1 result and discharges NO open surface.
  `symOf` values come verbatim from `H4Core.symOf` — never hardcoded.
-/

import Towers.YM.H4Core

namespace H4Strata

/-- The boundary digit count. -/
def C13 : Nat := 13

/-- Decimal digit length (Lean-core `toString`; `Nat.log10` is mathlib-only). -/
def digit_len (p : Nat) : Nat := (toString p).length

/-- Mathlib-free primality (trial division), so the conjecture below is
    well-formed without `Nat.Prime`.  Used only inside the stated `Prop`; it is
    never `#eval`-ed on large inputs. -/
def isPrime (n : Nat) : Bool :=
  if n < 2 then false else
    let rec go (d fuel : Nat) : Bool :=
      match fuel with
      | 0          => true
      | fuel + 1   => if n < d * d then true
                      else if n % d == 0 then false
                      else go (d + 1) fuel
    go 2 n

/-- The proposed boundary law, stated as an OPEN conjecture.  It is DELIBERATELY
    left unproven — there is no `theorem` discharging it (see the header for why).
    Naming it as a `Prop` is honest accounting, NOT a proof. -/
def C13_Law_Open : Prop :=
  ∀ p : Nat, isPrime p = true → C13 ≤ digit_len p → symOf p = 1

/-- Explicit finite witnesses (known ≥13-digit primes from Modules A.1 / E). -/
def derivationWitnesses : List Nat :=
  [1000000001119, 1000000001357, 1000000001511, 1000000001723, 1000000001831, 1000000002111]

/-- Sample CHECK of the law on the explicit witnesses — a `Bool` computation via
    `#eval`, NOT a proof and NOT a discharge of `C13_Law_Open`. -/
def boundary_proven : Bool :=
  derivationWitnesses.all (fun p => decide (C13 ≤ digit_len p) && (symOf p == 1))

/-! ### Cheap kernel-checked facts (classical trio; axiom-free) -/

/-- `C13 = 13`, definitionally. -/
theorem C13_val : C13 = 13 := rfl

/-! ### Measurements (`#eval`, compiled — not kernel `decide`) -/

-- (digit_len, symOf) per witness → [(13,1),(13,1),(13,1),(13,1),(13,1),(13,1)]
#eval derivationWitnesses.map (fun p => (digit_len p, symOf p))
-- sample check holds on the explicit list → true  (SAMPLE ONLY, not the ∀-law)
#eval boundary_proven

#print axioms C13_val

end H4Strata
