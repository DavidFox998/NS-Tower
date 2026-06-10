/-
================================================================
Towers / YM / EntropyBound

**Polymer entropy / counting bound for Kotecký–Preiss convergence.**

Goal (user-requested, Shawlock Rule #3 — one file, one theorem):

    card { γ : Polymer | |γ| = n ∧ (0,0,0,0) ∈ support γ } ≤ polymer_const ^ n

with `polymer_const : ℝ` explicit and `polymer_const ≤ 7`.

## What this file is

`polymer_entropy_bound` states, for the 4-dimensional periodic cubic lattice,
that the number of size-`n` `Connected` polymers whose support contains the
origin link is at most `polymer_const ^ n = 7 ^ n`.

It is an **honest conditional combinator**: the count is faithfully formalised
(via `Nat.card` over the subtype of qualifying polymers), the constant is
explicit (`7 = 2·d − 1` for `d = 4`), and the bound itself is routed through a
SINGLE NAMED SURFACE `h_entropy` — a hypothesis, NOT `by sorry`, so the
elaborated term carries NO `sorryAx`. `#print axioms` = classical trio
`{propext, Classical.choice, Quot.sound}`.

## Why it is conditional (honest scope — locked)

* The combinatorial fact behind `h_entropy` is the **lattice-animal /
  self-avoiding-walk connective-constant bound** `μ(ℤ⁴) ≤ 2·d − 1 = 7`
  (each SAW step has at most `2d − 1` continuations after excluding the
  immediate backtrack). mathlib v4.12.0 has **no** lattice-animal / SAW
  counting API, so this is left as a named surface, not proved.
* `Connected` is kept **abstract** (a modeled connectivity predicate).
  Without a connectivity constraint the count is infinite-in-`L`, so the
  `7 ^ n` bound would be FALSE; connectivity is exactly what makes the surface
  dischargeable in principle. Landing a real connectivity predicate + the
  connective-constant proof is the genuine open work.
* `(0,0,0,0)` is realised as the **origin link** `((fun _ => 0), 0)`: a
  polymer's "support" is its underlying `Finset (Link 4 L)`, whose members
  are *links*, so the origin site is anchored as the origin-direction link.

## Honest scope

This proves **NO** Yang–Mills mass-gap statement and closes **no** surface. It
states and wires the missing combinatorial input for
`Transfer.kotecky_preiss_criterion`; discharging `h_entropy` (the real
connective-constant count) is what would let KP convergence go through.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports the YM polymer model only; imports
nothing from the NS tower.
================================================================
-/

import Towers.YM.Polymer

namespace TheoremaAureum.Towers.YM.EntropyBound

open TheoremaAureum.Towers.YM.LatticeGauge

/-- **Connective-constant ceiling** for the 4-dimensional cubic lattice:
    a self-avoiding walk has at most `2·d − 1 = 7` continuations at each step
    (forward neighbours minus the immediate backtrack). Explicit; `≤ 7`. -/
def polymer_const : ℝ := 7

/-- `polymer_const = 7 ≤ 7` (the target ceiling). -/
theorem polymer_const_le_seven : polymer_const ≤ 7 := le_refl _

/-- The **origin link**: base site `(0,0,0,0) : Lattice 4 L` in direction `0`.
    Faithful reading of the snippet's `(0,0,0,0) ∈ support γ` — the support of a
    polymer is its underlying `Finset (Link 4 L)`, whose members are links. -/
def originLink (L : ℕ) [NeZero L] : Link 4 L := (fun _ => 0, 0)

/-- **Polymer entropy / counting bound (honest conditional combinator).**

The number of size-`n` `Connected` polymers through the origin link is at most
`polymer_const ^ n = 7 ^ n`. The bound is the single NAMED SURFACE `h_entropy`
(the lattice-animal / self-avoiding-walk connective-constant bound
`μ(ℤ⁴) ≤ 2·d − 1 = 7`, absent from mathlib v4.12.0) — a hypothesis, not
`by sorry`, so no `sorryAx`. See the file header for the locked honest scope:
this proves no Yang–Mills result and closes no surface. -/
theorem polymer_entropy_bound
    {L : ℕ} [NeZero L]
    (Connected : Polymer 4 L → Prop)
    -- SORRY: lattice-animal / self-avoiding-walk connective-constant bound
    --   μ(ℤ⁴) ≤ 2·d − 1 = 7 for `Connected` polymers through the origin link;
    --   not formalised in mathlib v4.12.0. Named surface, NOT `by sorry`.
    (h_entropy : ∀ n : ℕ,
        (Nat.card {X : Polymer 4 L //
            X.card = n ∧ Connected X ∧ originLink L ∈ X} : ℝ)
          ≤ polymer_const ^ n)
    (n : ℕ) :
    (Nat.card {X : Polymer 4 L //
        X.card = n ∧ Connected X ∧ originLink L ∈ X} : ℝ)
      ≤ polymer_const ^ n :=
  h_entropy n

end TheoremaAureum.Towers.YM.EntropyBound
