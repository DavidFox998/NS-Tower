-- DEPRECATED: Vacuous tautology  ∀ g > 0, ∃ lam, 0 < lam < 1  (pick lam = 1/2).
-- Provable with NO hypothesis; encodes nothing about any real transfer operator.
-- The genuine non-trivial open surfaces are indexed in
-- `Towers/CanonicalSurfaces.lean`. Kept for history only; NOT a brick.
-- Moved from `Towers/Attempts/Perron.lean` on 2026-05-31.
-- NOTE: post-purge this file is `sorry`-free (named `Prop` hypothesis); the
-- "sorry-bearing" prose below is HISTORICAL and no longer accurate.
/-
================================================================
Towers / Attempts / Perron  (Batch 18 Track 1 — sorry-bearing stub)

**THIS FILE IS NOT A BRICK.** It is deliberately excluded from the
BRICKS array in `scripts/check-towers.sh`. The theorem below is
`sorry`-backed. Its `#print axioms` includes `sorryAx` and would
fail the {propext, Classical.choice, Quot.sound} footprint — that
is *why* it is not a brick. Per the locked rule in `replit.md`:
"Hard theorems land in `Towers/Attempts/` as sorry-bearing stubs."

## What this file pins

The **unconditional** Perron–Frobenius bound on the YM transfer
matrix for the Wilson SU(3) action — the Clay-level analytic
surface that the existing `Towers.YM.Transfer.Perron_Frobenius_for_transfer`
brick *only states as a conditional* (hypothesis ⇒ same hypothesis).

  * `Perron_Frobenius_for_transfer_unconditional` — for every
    coupling `g > 0`, the spectral radius of the transfer
    operator is strictly less than 1. Discharging this is
    equivalent to a mass gap for SU(3) Wilson on the lattice.

## Honest-scope reminder

YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2). The headline
target `MassGap_YM4_Clay` does NOT auto-promote: the conjectural
chain in `Towers.YM.Spectrum` reads "if Perron-Frobenius gives
λ < 1 then mass gap" and the antecedent is still `sorry` here.
The Batch 18 user prompt's "If all 3 compile as `theorem`, auto-
promote" is satisfied vacuously in the wrong direction: the
theorem compiles only because of `sorry`, so no promotion fires.

================================================================
-/

import Towers.YM.Transfer

namespace TheoremaAureum
namespace Towers
namespace Attempts
namespace Perron

open TheoremaAureum.Towers.YM

/- **Unconditional Perron–Frobenius for the YM transfer matrix.**

For every positive coupling `g`, there is `λ ∈ (0, 1)` bounding the
spectral radius of the transfer operator from above. Stated here
as an existential over `ℝ`; the *body* of the statement is what
the real `WilsonAction g`-transfer would need to inhabit. Proof is
`sorry` — discharging it is equivalent to the SU(3) lattice mass
gap and is far outside the Towers scope. -/
/-- The named-open analytic surface behind
`Perron_Frobenius_for_transfer_unconditional`: the unconditional Perron–Frobenius
bound for the YM transfer matrix. Stated as a `Prop`, NOT discharged with
`by sorry` (which would inject `sorryAx`). Discharging it is equivalent to the
SU(3) lattice mass gap and stays OPEN. -/
def Perron_Frobenius_for_transfer_unconditional_Surface : Prop :=
  ∀ g : ℝ, 0 < g → ∃ lam : ℝ, 0 < lam ∧ lam < 1

theorem Perron_Frobenius_for_transfer_unconditional
    (h : Perron_Frobenius_for_transfer_unconditional_Surface) :
    ∀ g : ℝ, 0 < g → ∃ lam : ℝ, 0 < lam ∧ lam < 1 := h

end Perron
end Attempts
end Towers
end TheoremaAureum
