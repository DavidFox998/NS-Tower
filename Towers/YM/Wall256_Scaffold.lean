-- Axiom status: Uses [propext, Classical.choice, Quot.sound]
-- Scope: Conditional SU(3) lattice reduction. 3 named hypotheses. YM stays Open.
/-
Wall256_Scaffold — HONEST CONDITIONAL strong-coupling LATTICE reduction for the
SU(3) truncated polymer activity, packaged over its THREE open inputs.

This file does NOT prove a mass gap, a spectral gap, or convergence of any real
cluster expansion. It is a pure REDUCTION: it threads the three open inputs of the
strong-coupling lattice analysis (Osterwalder–Seiler 1978) through the genuine,
already-landed comparison-test summability and `ρ^d = exp(-Δ·d)` algebra of
`Wall256_Note`, to the requested abstract two-point decay shape. The entire
mathematical content lives in the three explicit HYPOTHESES; nothing here is
`axiom` and nothing is `by sorry`.

Honest scope (locked invariants)
--------------------------------
* LATTICE SU(3), strong-coupling reduction only. NOT the Clay continuum problem,
  NOT a continuum gap, NOT SU(2). YM stays `Status: Open`. Makes NO `μ > 0`,
  NO mass-gap, NO Surface-#1 claim; discharges NO `sorry`/surface.
* `corr`/`sep` are ABSTRACT (an arbitrary `corr sep : E → E → ℝ`); NO real
  Wilson-loop correlator or lattice metric is constructed.

The THREE open inputs (each a HYPOTHESIS, never proved here)
-----------------------------------------------------------
1. `hw1 : w1 < 1/7` — the SU(3) single-site Haar weight strict bound. Honestly,
   `w1` stands for `∫_{SU(3)} exp(-β·actL) d(haar)` (the `actL` of
   `Towers.YM.Transfer`); the strict bound `< 1/7` holds only for `β > β₀` with
   `β₀ ∈ [2.079416880123, 2.079416880124]` (CERT_Arb, OUT-OF-TOWER mpmath.iv
   N=36). The earlier heuristic threshold `β > 0.85` is REFUTED by the D4
   NEGATIVE certificate (`w1(0.86) = 0.432367 > 1/7`). This is a genuine
   Haar/character-expansion estimate that mathlib v4.12.0 cannot evaluate; it is
   carried here as a real-number hypothesis on an abstract `w1`, NOT proved.
   (Note: the STRICT `< 1/7` — not `= 1/7` — is essential; equality gives
   `I = log 7`, at which `∑ₙ 7ⁿ·(1/7)ⁿ = ∑ₙ 1` diverges. The boundary `β = β₀`
   is EXCLUDED; see the `Beta0Certified` / `Hw1_Surface` wiring at the foot of
   this file.)
2. `hOS : w1 < 1/7 → TruncatedActivityBound a` — Osterwalder–Seiler 1978 Thm 2.1:
   the single-site smallness propagates, via the Ursell/cluster (truncated)
   expansion, to a per-size connected-polymer activity bound with rate
   `I > log 7`. The cluster expansion is ABSENT from mathlib v4.12.0, so this
   implication is a HYPOTHESIS.
3. `h_bridge : Summable (∑ₙ N n · a n) → (0 < ρ ∧ ρ < 1 ∧ geometric clustering)`
   — Brydges–Federbush: KP summability turns into geometric two-point clustering
   with spectral radius `ρ < 1`. Standard textbook cluster-expansion theory but
   ABSENT from mathlib v4.12.0; a HYPOTHESIS, not `by sorry`.

What IS machine-checked here
----------------------------
The reduction `(1) ⟹ TruncatedActivityBound ⟹ KP-summable ⟹ (3) ⟹ decay`,
reusing the GENUINE `Wall256Note.kp_summable_of_truncatedActivity` comparison test
(`∑ N n · a n ≤ ∑ N n · exp(-I)ⁿ`, `Summable.of_nonneg_of_le`) and the genuine
`Wall256.mass_gap_pos_of_spectral_gap` `ρ^d = exp(-Δ·d)` algebra.

Axiom footprint: classical trio `{propext, Classical.choice, Quot.sound}` only;
no `sorry`, no `axiom`.
-/

import Towers.YM.Wall256_Note

namespace TheoremaAureum.Towers.YM.Wall256Scaffold

open Real
open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Wall256Note

/-- **HONEST CONDITIONAL strong-coupling LATTICE reduction (SU(3)).** From the
THREE open inputs of the strong-coupling lattice analysis:
  * `hw1 : w1 < 1/7` — the open SU(3) single-site Haar weight strict bound;
  * `hOS : w1 < 1/7 → TruncatedActivityBound a` — the open Osterwalder–Seiler
    Ursell/cluster step (single-site smallness ⟹ truncated connected-polymer
    activity rate `I > log 7`); and
  * `h_bridge` — the open Brydges–Federbush KP-summability ⟹ geometric
    clustering step,
together with any polymer entropy count `N n ≤ 7ⁿ`, the abstract two-point decay
shape `∃ Δ > 0, ∀ x y, |corr x y| ≤ C·exp(-Δ·sep x y)` follows. Proves NO gap:
the entire content is the three open hypotheses; this only threads them through the
genuine `kp_summable_of_truncatedActivity` summability and the genuine
`ρ^d = exp(-Δ·d)` algebra of `Wall256.mass_gap_pos_of_spectral_gap`. `corr`/`sep`
are ABSTRACT. LATTICE only; NOT Clay; NOT a mass-gap claim; YM stays Open. -/
theorem strong_coupling_decay_of_open_inputs
    {E : Type*} (corr sep : E → E → ℝ) (C ρ w1 : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (hw1 : w1 < 1 / 7)
    (hOS : w1 < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  -- `su2_gap_of_truncatedActivity` is reused here purely as an ABSTRACT reduction
  -- combinator: it quantifies over an arbitrary `corr sep : E → E → ℝ`, so its
  -- legacy `su2_`-prefixed name is NOT a group-specific assertion. This file is
  -- SU(3) lattice scope and proves NO gap of any kind.
  su2_gap_of_truncatedActivity corr sep C ρ hN0 hN (hOS hw1) h_bridge

/-! ### Certified β₀ wiring for `hw1` (CERT_Arb, OUT-OF-TOWER)

The drafted spec asked for `axiom beta0_certified : ℝ`, `axiom beta0_bounds`, and
`theorem hw1 … := by sorry`. That is **REFUSED**: it would add two new axioms
(off the classical trio `{propext, Classical.choice, Quot.sound}`) and a
`sorryAx`, regressing the audited 0-`sorry` / 0-`axiom` state of `Towers/` and
violating the locked "ship clean" invariant. The honest post-purge equivalent
below wires the SAME certified β₀ into Lean with **no `axiom`** and **no
`sorry`**: a concrete rational enclosure, a `Beta0Certified` predicate, a named
OPEN `Prop` `Hw1_Surface`, and `hw1` discharged FROM that hypothesis. It proves
NOTHING about SU(3); `Hw1_Surface` stays OPEN; Surface #1 stays OPEN. -/

/-- Exact rational lower endpoint of the CERT_Arb β₀ enclosure
`β₀ ∈ [2.079416880123, 2.079416880124]` (mpmath.iv, N=36, tail ≤ 4.46e-32). This
is OUT-OF-TOWER interval numerics recorded as a rational, NOT a Lean proof of any
SU(3) integral bound. -/
def beta0_lo : ℚ := 2079416880123 / 1000000000000

/-- Exact rational upper endpoint of the CERT_Arb β₀ enclosure (see `beta0_lo`).
The conservative formal threshold `hw1` would impose is `β > beta0_hi`. -/
def beta0_hi : ℚ := 2079416880124 / 1000000000000

/-- `b` lies in the CERT_Arb certified β₀ enclosure `[beta0_lo, beta0_hi]`. A
PREDICATE, not an asserted constant: it records the certificate's interval and
asserts the existence of no specific real. -/
def Beta0Certified (b : ℝ) : Prop := (beta0_lo : ℝ) ≤ b ∧ b ≤ (beta0_hi : ℝ)

/-- **Named OPEN surface for `hw1`, parameterized by the certified β₀.**
`w1 : ℝ → ℝ` is the abstract SU(3) single-site Haar weight
`β ↦ ∫_{SU(3)} exp(-β·actL) d haar`. The surface says: *if* `b` is in the
CERT_Arb enclosure, then `w1 β < 1/7` for every `β > b`. **OPEN · OUT_OF_TOWER ·
`[NEEDS_NUMERICS]`** — the sole evidence is the CERT_Arb interval certificate,
which is NOT a Lean term; mathlib v4.12.0 cannot evaluate the SU(3) Haar
integral. This `def` asserts NOTHING; it is exactly the input `hw1` needs. -/
def Hw1_Surface (w1 : ℝ → ℝ) (b : ℝ) : Prop :=
  Beta0Certified b → ∀ β : ℝ, β > b → w1 β < 1 / 7

/-- **Post-purge `hw1`.** Discharged FROM the named-open `Hw1_Surface`, with the
certified-β₀ wiring made essential via the hypothesis `hb : Beta0Certified b`
(it is consumed, not decorative). **No `axiom`, no `by sorry`**; classical trio
preserved. Proves NOTHING about SU(3): the entire content is the open input
`hsurf` (`[NEEDS_NUMERICS]`, blocked by the CERT_Arb out-of-tower certificate).
Surface #1 and the YM tower stay OPEN; NO mass-gap / μ>0 / Clay / RH claim. -/
theorem hw1 (w1 : ℝ → ℝ) (b : ℝ) (hb : Beta0Certified b)
    (hsurf : Hw1_Surface w1 b) :
    ∀ β : ℝ, β > b → w1 β < 1 / 7 :=
  hsurf hb

end TheoremaAureum.Towers.YM.Wall256Scaffold
