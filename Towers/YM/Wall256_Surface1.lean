-- Axiom status: Uses [propext, Classical.choice, Quot.sound, hw1]
-- Scope: Conditional SU(3) lattice reduction (Surface-#1 framing). H1 carried as
--        the SINGLE explicit OPEN axiom `hw1`; hOS/h_bridge are OPEN black-box
--        hypotheses. YM stays Open. NOT a brick, NOT a lakefile root.
/-
Wall256_Surface1 — HONEST CONDITIONAL "H1 ⟹ exponential two-point decay" for the
SU(3) strong-coupling LATTICE reduction.

H1 (the SU(3) single-site Haar weight strict bound `w1 β < 1/7`) is carried as the
SINGLE explicit, fully-disclosed OPEN `axiom hw1`. The Osterwalder–Seiler
Ursell/cluster step (`hOS`) and the Brydges–Federbush KP-summability ⟹ decay step
(`h_bridge`) are carried as OPEN BLACK-BOX HYPOTHESES. The file proves NOTHING
beyond the implication: it only threads these open inputs through the genuine
comparison-test summability and `ρ^d = exp(-Δ·d)` algebra of `Wall256_Note`.

  closes_surface_1 = false.   mass_gap_proven = false.   Conditional only.

Coexistence with `Wall256_Scaffold`
-----------------------------------
This file and `Wall256_Scaffold.strong_coupling_decay_of_open_inputs` package the
SAME conditional reduction two honest ways: the scaffold carries H1 as a
HYPOTHESIS (`hw1 : w1 < 1/7`), so its footprint is the classical trio; this file
carries H1 as the SINGLE explicit OPEN `axiom hw1`, so its footprint is
`{trio, hw1}`. Neither proves anything beyond the implication.

Honest scope (locked invariants)
--------------------------------
* LATTICE SU(3), strong-coupling reduction only. NOT Clay, NOT a continuum gap,
  NOT SU(2). YM stays `Status: Open`. Makes NO `μ > 0` / mass-gap / Surface-#1
  claim; discharges NO `sorry` / surface. IN-TOWER ONLY: no RH / GRH / M7 / C05 /
  π/10 / S₄ / S₁₄ content; imports only `Towers.YM.Wall256_Note`.
* `w1 : ℝ → ℝ` (the SU(3) single-site Haar weight
  `β ↦ ∫_{SU(3)} exp(-β·actL) d haar`) and `β : ℝ` (the coupling) are OPAQUE —
  fixed but unknown; NO real integral is constructed or evaluated. `corr`/`sep`
  are ABSTRACT (an arbitrary `corr sep : E → E → ℝ`); NO real Wilson-loop
  correlator or lattice metric is constructed.

H1 as an axiom — why this is honest, not a hidden claim
------------------------------------------------------
`hw1 : w1 β < 1/7` is an `axiom` ON PURPOSE (the task's explicit request): it is
the SINGLE declared OPEN input, made VISIBLE in `#print axioms` rather than hidden
in a `sorry`. It is OPEN · OUT_OF_TOWER · [NEEDS_NUMERICS] — mathlib v4.12.0
cannot evaluate the SU(3) Haar integral; the only evidence is the OUT-OF-TOWER
CERT_Arb β₀ certificate (`β₀ ∈ [2.079416880123, 2.079416880124]`, mpmath.iv
N=36), which is NOT a Lean term. It is NOT proved here. Because `w1`/`β` are
OPAQUE (fixed-but-unknown), the axiom asserts only a property of an unknown
constant — it is CONSISTENT (a model with `w1 := fun _ => 0` satisfies it), so NO
`False` is derivable. (Had `w1`/`β` been free `variable`s, the axiom would auto-
generalize to the ABSURD `∀ w1 β, w1 β < 1/7`; using `opaque` constants is
exactly what keeps it sound.) The STRICT `< 1/7` is essential — `= 1/7` gives the
divergent entropy series `∑ₙ 1`.

REFUSED from the drafted spec
-----------------------------
* "Use `sorry` for hOS/h_bridge proofs" — REFUSED. `sorry` emits `sorryAx`, which
  (a) violates THIS file's own axiom contract `#print axioms = {trio, hw1}` and
  (b) violates the global no-`sorryAx` ship-clean lock. The honest equivalent —
  and exactly the requested "use as black boxes / only wire the implication" — is
  to thread `hOS` and `h_bridge` as OPEN BLACK-BOX HYPOTHESES (Prop parameters).
  Zero `sorry` anywhere in this file.

Axiom footprint
---------------
Classical trio `{propext, Classical.choice, Quot.sound}` + the single declared
open input `hw1`. No other axiom; no `sorry`.
-/

import Towers.YM.Wall256_Note

namespace TheoremaAureum.Towers.YM.Wall256Surface1

open Real
open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Wall256Note

/-- Abstract SU(3) single-site Haar weight `β ↦ ∫_{SU(3)} exp(-β·actL) d haar`.
OPAQUE — fixed but unknown; NO real integral is constructed. -/
opaque w1 : ℝ → ℝ

/-- The (fixed, abstract) lattice coupling `β`. OPAQUE — no concrete value. -/
opaque β : ℝ

/-- **H1 — the SU(3) single-site Haar weight strict bound, carried as the SINGLE
explicit OPEN axiom.** `w1 β < 1/7`. OPEN · OUT_OF_TOWER · [NEEDS_NUMERICS]: the
sole evidence is the OUT-OF-TOWER CERT_Arb β₀ certificate, which is NOT a Lean
term; mathlib v4.12.0 cannot evaluate the SU(3) Haar integral. NOT proved here.
CONSISTENT (asserts a property of the opaque `w1`/`β`; no `False` derivable). -/
axiom hw1 : w1 β < 1 / 7

/-- **The conditional core: H1 ⟹ exponential two-point decay.** From the OPEN
black-box hypotheses
  * `hOS : w1 β < 1/7 → TruncatedActivityBound a` — the OPEN Osterwalder–Seiler
    Ursell/cluster step (single-site smallness ⟹ truncated polymer activity rate
    `I > log 7`); ABSENT from mathlib v4.12.0; and
  * `h_bridge` — the OPEN Brydges–Federbush KP-summability ⟹ geometric two-point
    clustering (`ρ < 1`) step; ABSENT from mathlib v4.12.0,
together with any polymer entropy count `N n ≤ 7ⁿ`, the hypothesis
`hw : w1 β < 1/7` yields the abstract exponential two-point decay shape
`∃ Δ > 0, ∀ x y, |corr x y| ≤ C·exp(-Δ·sep x y)`. Proves NO gap: the entire
content is the open inputs; this only threads them through the genuine
`kp_summable_of_truncatedActivity` summability and the genuine `ρ^d = exp(-Δ·d)`
algebra of `Wall256.mass_gap_pos_of_spectral_gap`. `corr`/`sep` ABSTRACT.
`#print axioms` of THIS decl = classical trio only (`hw` is a hypothesis here, so
the open axiom `hw1` is NOT consumed). LATTICE only; NOT Clay; YM stays Open. -/
theorem strong_coupling_decay_of_open_inputs
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (hOS : w1 β < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y))
    (hw : w1 β < 1 / 7) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  Wall256Note.su2_gap_of_truncatedActivity corr sep C ρ hN0 hN (hOS hw) h_bridge

/-- **Footprint witness — the core fed by the OPEN axiom `hw1`.** Identical
conclusion, with H1 discharged by the declared open axiom `hw1` instead of a
hypothesis. This is the declaration whose `#print axioms` is exactly
`{propext, Classical.choice, Quot.sound, hw1}` — the task's axiom contract.
`hOS`/`h_bridge` remain OPEN black-box hypotheses; zero `sorry`. Still proves NO
gap: conditional on `hOS`, `h_bridge`, and the OPEN axiom `hw1`.
closes_surface_1 = false; mass_gap_proven = false. -/
theorem strong_coupling_decay
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (hOS : w1 β < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  strong_coupling_decay_of_open_inputs corr sep C ρ hN0 hN hOS h_bridge hw1

end TheoremaAureum.Towers.YM.Wall256Surface1

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.Wall256Surface1.strong_coupling_decay_of_open_inputs  -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Wall256Surface1.strong_coupling_decay                 -- classical trio + hw1
