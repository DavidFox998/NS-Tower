/-
  Z_Test.lean — mathlib-free, computable mirror of the Z experiment harness
  (experiments/z-metastability/).

  HONEST SCOPE
  ------------
  * `tool = true`  (tool-assisted echo): reproduction is DETERMINISTIC. The shell
    harness measured 50 inputs × 100 trials = 5000 trials with 0 errors, so the
    literal is reproduced exactly: `Z_protocol_test s true = Repro.exact (digitLen s)`.
  * `tool = false` (pure generation, T = 0): this regime was NEVER measured by the
    shell harness. We do NOT invent an error value (in particular NOT `0.5`, which
    is merely `sigmoid 0`). It is honestly `Repro.unmeasured`.

  This file asserts NO theorem and NO law. It claims no relation between
  reproduction error and `Sym`, digit length, or zero-run. It only computes the
  structural fields (`digitLen`, `zeroRun`) and the protocol's KNOWN outcomes.
  mathlib OFF (Lean core only); no `sorry` / `axiom` / `decide`-claim.
-/

namespace ZTest

/-- Digit length = number of characters in the literal. -/
def digitLen (s : String) : Nat := s.length

/-- Longest run of consecutive '0' characters in `s`. -/
def zeroRun (s : String) : Nat :=
  (s.toList.foldl
    (fun (acc : Nat × Nat) (c : Char) =>
      let cur := if c = '0' then acc.2 + 1 else 0
      (max acc.1 cur, cur))
    (0, 0)).1

/-- Reproduction outcome of one trial.
    `exact n`    : literal reproduced exactly (`n` digits).
    `unmeasured` : regime not measured by this harness (no fabricated value). -/
inductive Repro where
  | exact (digits : Nat) : Repro
  | unmeasured : Repro
deriving Repr

/-- The Z protocol on one literal.
    `tool = true`  ⟹ deterministic tool-assisted echo ⟹ `exact (digitLen s)`.
    `tool = false` ⟹ pure-generation (T=0) regime, NOT measured ⟹ `unmeasured`. -/
def Z_protocol_test (s : String) (tool : Bool) : Repro :=
  if tool then Repro.exact (digitLen s) else Repro.unmeasured

/-- All 50 harness inputs as (literal, known Sym from H4Core or `none`).
    Digit length and zero-run are COMPUTED below, never hand-labeled. -/
def testCases : List (String × Option Nat) :=
  [ ("2", some 120), ("3", some 20), ("19", some 2), ("191", some 2),
    ("1000000001119", some 1), ("10000000001119", some 1),
    ("1000000001357", some 1), ("1000000001511", some 1),
    ("1000000001723", some 1), ("1000000001831", some 1),
    ("1234567891", none), ("1000123456", none), ("1000000123", none),
    ("1000000000", none), ("12345678912", none), ("10001234567", none),
    ("10000001234", none), ("10000000001", none), ("123456789123", none),
    ("100012345678", none), ("100000012345", none), ("100000000012", none),
    ("1234567891234", none), ("1000123456789", none), ("1000000123456", none),
    ("1000000000123", none), ("1000000000000", none), ("12345678912345", none),
    ("10001234567891", none), ("10000001234567", none), ("10000000001234", none),
    ("10000000000001", none), ("123456789123456", none), ("100012345678912", none),
    ("100000012345678", none), ("100000000012345", none), ("100000000000012", none),
    ("1234567891234567", none), ("1000123456789123", none), ("1000000123456789", none),
    ("1000000000123456", none), ("1000000000000123", none), ("1000000000000000", none),
    ("123456789123456789", none), ("100012345678912345", none),
    ("100000012345678912", none), ("100000000012345678", none),
    ("100000000000012345", none), ("100000000000000012", none),
    ("12345678912345678912", none) ]

-- Number of test cases (expect 50).
#eval testCases.length

-- (literal, digitLen, zeroRun) computed for every case.
#eval testCases.map (fun c => (c.1, digitLen c.1, zeroRun c.1))

-- (literal, known Sym) — `none` where Sym is not certified.
#eval testCases.map (fun c => (c.1, c.2))

-- tool = true: every literal reproduced exactly.
#eval testCases.map (fun c => Z_protocol_test c.1 true)

-- tool = false: every literal is `unmeasured` (T=0 not tested here).
#eval testCases.map (fun c => Z_protocol_test c.1 false)

-- Count of exact reproductions under tool = true (expect 50).
#eval (testCases.filter
  (fun c => match Z_protocol_test c.1 true with
            | Repro.exact _ => true
            | Repro.unmeasured => false)).length

end ZTest
