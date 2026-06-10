/-
Wall256_Note — HONEST CONDITIONAL apex: "conditional on the truncated polymer
activity bound, SU(2) has a gap".

This file packages, in ONE place, the reduction of the SU(2) Yang–Mills mass gap
to its single open quantitative input — the truncated polymer-activity decay rate
`I > log 7` (the content of `kotecky_preiss_criterion`). It sits ONE step earlier
than `Wall256_MassGapConditional.mass_gap_pos_of_spectral_gap` (which starts from
an already-assumed spectral gap `ρ < 1`): here the entry point is the activity
rate, and the genuine new content is the bridge from that rate to the
Kotecký–Preiss summability criterion.

What is GENUINE here
--------------------
* `kp_summable_of_truncatedActivity` — REAL comparison-test content. Given any
  entropy count `N n ≤ 7ⁿ` (the `EntropyBound` connective-constant surface) and a
  per-size activity `a` satisfying the truncated activity bound
  (`a n ≤ exp(-I)ⁿ` with `I > log 7`), the entropy-weighted polymer series
  `∑ₙ N n · a n` is `Summable`. Proof: majorize by `∑ₙ N n · exp(-I)ⁿ`
  (`Wall256Rate.kp_rate_summable`) and apply `Summable.of_nonneg_of_le`. This is
  the honest bridge from the per-polymer rate to the KP convergence criterion.

What is CONDITIONAL / OPEN here
-------------------------------
* `TruncatedActivityBound a` — the per-polymer truncated activity decays at a
  rate `I` strictly above the `log 7` entropy threshold. This IS the content of
  the disclaimed `Towers/Attempts/ClusterExpansion.lean` `kotecky_preiss_criterion`
  `sorry`: it is NOT proved anywhere in the tower (no `q < 1/7`, no `ρ(T) < 1`).
  It is a HYPOTHESIS, never `by sorry`, so NO `sorryAx`.
* `su2_gap_of_truncatedActivity` — the apex. It threads the activity bound through
  the genuine summability above AND a SECOND named-open input `h_bridge`: the
  Brydges–Federbush cluster-expansion convergence turning KP summability into
  geometric two-point clustering with spectral radius `ρ < 1`. That convergence
  is standard textbook cluster-expansion theory (Friedli–Velenik 2018, Ch. 5) but
  is ABSENT from mathlib v4.12.0, so it stays a HYPOTHESIS here. The conclusion is
  then the requested mass-gap shape `∃ Δ > 0, |corr x y| ≤ C·exp(-Δ·sep x y)`,
  delegated to `Wall256.mass_gap_pos_of_spectral_gap` (the genuine
  `ρ^d = exp(-Δ·d)` algebra).

HONEST SCOPE (locked invariants)
--------------------------------
* This proves NO Yang–Mills mass gap. The entire mathematical content lives in
  the two OPEN hypotheses (`TruncatedActivityBound` and `h_bridge`); the file only
  performs the genuine comparison-test summability and the `ρ^d → exp(-Δd)`
  algebra on top of them.
* `corr`/`sep` are ABSTRACT (an arbitrary `corr sep : E → E → ℝ`); NO real
  Wilson-loop correlator or lattice metric is constructed. The activity rate is
  NOT discharged. Any claim that this file closes Surface #1, proves `μ > 0` / a
  mass gap, or discharges `kotecky_preiss_criterion` is REFUSED. YM stays
  Status: Open.

Axiom footprint
---------------
Classical trio `{propext, Classical.choice, Quot.sound}` only; no `sorry`.
-/

import Towers.YM.Wall256_RateFunction
import Towers.YM.Wall256_MassGapConditional

namespace TheoremaAureum.Towers.YM.Wall256Note

open Real
open TheoremaAureum.Towers.YM

/-- **The truncated polymer-activity bound (the single open quantitative input).**
For a per-size activity `a : ℕ → ℝ`, there is a large-deviation rate `I` strictly
above the polymer-entropy threshold `log 7` with `a n ≤ exp(-I)ⁿ` for every `n`
(and `a` nonnegative). This is exactly the content of `kotecky_preiss_criterion`:
the truncated polymer activity decays at a rate beating the `7ⁿ` entropy. It is
NOT trivially satisfiable — it forces genuine geometric decay at rate `> log 7` —
and is NOT proved anywhere in the tower. -/
def TruncatedActivityBound (a : ℕ → ℝ) : Prop :=
  (∀ n, 0 ≤ a n) ∧ ∃ I : ℝ, Real.log 7 < I ∧ ∀ n, a n ≤ Real.exp (-I) ^ n

/-- **GENUINE (conditional on the open `TruncatedActivityBound`).** The truncated
activity bound, together with any polymer entropy count `N n ≤ 7ⁿ`, yields KP
summability of the entropy-weighted polymer series `∑ₙ N n · a n`. The honest
bridge from the per-polymer rate to the Kotecký–Preiss convergence criterion:
majorize `N n · a n ≤ N n · exp(-I)ⁿ` and invoke `Wall256Rate.kp_rate_summable`.
Establishes NO KP convergence for the real Wilson measure (the rate `I > log 7`
is the open hypothesis); makes NO mass-gap claim. -/
theorem kp_summable_of_truncatedActivity
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (h : TruncatedActivityBound a) :
    Summable (fun n : ℕ => N n * a n) := by
  obtain ⟨ha0, I, hI, haI⟩ := h
  have hmaj : Summable (fun n : ℕ => N n * Real.exp (-I) ^ n) :=
    Wall256Rate.kp_rate_summable hN0 hN hI
  refine Summable.of_nonneg_of_le (fun n => ?_) (fun n => ?_) hmaj
  · exact mul_nonneg (hN0 n) (ha0 n)
  · exact mul_le_mul_of_nonneg_left (haI n) (hN0 n)

/-- **HONEST CONDITIONAL APEX — "conditional on the truncated activity bound,
SU(2) has a gap".** From TWO named-open inputs:
  * `h_activity : TruncatedActivityBound a` — the open per-polymer rate
    `I > log 7` (= `kotecky_preiss_criterion` content); and
  * `h_bridge` — the Brydges–Federbush cluster-expansion convergence turning the
    KP summability `∑ₙ N n · a n < ∞` into geometric two-point clustering with
    spectral radius `ρ < 1` (standard but ABSENT from mathlib v4.12.0; a
    HYPOTHESIS, not `by sorry`),
the requested mass-gap shape `∃ Δ > 0, ∀ x y, |corr x y| ≤ C·exp(-Δ·sep x y)`
follows, with `Δ = -log ρ`. Proves NO gap: the entire content is the two open
hypotheses; this only threads the genuine `kp_summable_of_truncatedActivity`
summability and the genuine `ρ^d = exp(-Δ·d)` algebra of
`Wall256.mass_gap_pos_of_spectral_gap`. `corr`/`sep` are ABSTRACT. -/
theorem su2_gap_of_truncatedActivity
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (h_activity : TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) := by
  obtain ⟨h0, h1, hcl⟩ :=
    h_bridge (kp_summable_of_truncatedActivity hN0 hN h_activity)
  exact Wall256.mass_gap_pos_of_spectral_gap corr sep C ρ h0 h1 hcl

end TheoremaAureum.Towers.YM.Wall256Note
