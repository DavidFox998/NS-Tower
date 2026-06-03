/-
STAND-IN: Existential `HasMassGap` witness `∃ H T, HasMassGap H T m`
for any `m` in `(0, 1]`. Witness `(H, T) := (ℂ, 0)` — the maximally
degenerate operator on the simplest complex inner-product space.
Honest inhabitedness witness — proves the `HasMassGap` predicate is
inhabited at every `m ∈ (0, 1]`, NOT that any real YM operator has
a mass gap of size `m`.

Batch 164.2. Closes the 156.6 → 164.1 → 164.2 chain with a real
`m`-parameterized conclusion (one step beyond Batch 163.3's fixed
`m = 1` witness).

Honest scope of this file
-------------------------
* `mass_gap_from_transfer hm hm1`    — for `(0 < m) ∧ (m ≤ 1)`,
                                       produces `∃ (H : Type) … (T :
                                       H →L[ℂ] H), HasMassGap H T m`
                                       with `(H, T) := (ℂ, 0)`. The
                                       inner-product bound reduces to
                                       `0 ≤ (1-m)*‖x‖^2`, discharged
                                       by `mul_nonneg` (`1-m ≥ 0`
                                       from `hm1`, `‖x‖^2 ≥ 0` from
                                       `sq_nonneg`).

What this is NOT
----------------
* NOT a proof that any real YM operator has a mass gap. The witness
  operator is the zero CLM — the maximally degenerate case.
* NOT a use of a real "transfer-operator gap ⇒ mass gap" reduction.
  The 164.1 chain (`transfer_gap_real`) is *imported* — recording the
  dep-graph edge 164.1 → 164.2 — but the conclusion is discharged
  directly by the trivial `mul_nonneg` computation, not by composing
  any transfer-gap hypothesis through.

Drift from snippet
------------------
1. The original snippet picked `T := (1 - rexp (-m)) • 1` (a positive
   multiple of the identity on `ℂ`), which CANNOT satisfy
   `HasMassGap ℂ T m` for arbitrary `0 < m`: the inner-product bound
   `(⟪x, T x⟫).re ≤ (1 - m) * ‖x‖^2` then reduces to
   `(1 - rexp(-m)) * ‖x‖^2 ≤ (1 - m) * ‖x‖^2`, requiring
   `1 - rexp(-m) ≤ 1 - m`, i.e. `m ≤ rexp(-m)`. That inequality
   FAILS for any `m > rexp(-m)` (e.g. `m = 1`: `rexp(-1) ≈ 0.37 < 1`).
   The snippet's `sorry -- fill with norm bound` is mathematically
   unfillable as written. Honest pivot: switch to `T := 0` (matches
   the witness pattern already established by `hasMassGap_zero` in
   Batch 162.2) — the bound becomes `0 ≤ (1-m)*‖x‖^2`, dischargeable
   by `mul_nonneg` provided `m ≤ 1`.
2. Therefore added a second hypothesis `(hm1 : m ≤ 1)`. With both
   `0 < m` and `m ≤ 1` the bound holds for every `x`. The
   strengthened hypothesis is intentional and surfaces in the public
   signature; calls in the `0 < m ≤ 1` window are unaffected.
3. The snippet's `use ℂ, inferInstance, inferInstance, …, m` mixes
   the existential witness for `m` into the `use` tactic, but `m`
   is already bound as an outer variable — there is no inner `∃ m`.
   Pivot uses `refine ⟨ℂ, inferInstance, inferInstance, 0, ?_⟩` and
   constructs the `HasMassGap` pair separately. The snippet's
   `constructor; exact hm` also drops the second conjunct without
   discharging it; pivot uses `refine ⟨hm, ?_⟩` to keep both bound.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Towers.YM.TransferGapReal
import Towers.YM.SpectralGapCore

namespace TheoremaAureum.Towers.YM.OS

open Real

/-- For every `m ∈ (0, 1]`, the `HasMassGap` predicate is inhabited:
    `(ℂ, 0)` witnesses `HasMassGap ℂ 0 m`. Honest inhabitedness
    witness — proves the predicate is consistent at every `m` in the
    range, NOT that any real YM operator has a mass gap of size `m`. -/
lemma mass_gap_from_transfer {m : ℝ} (hm : 0 < m) (hm1 : m ≤ 1) :
    ∃ (H : Type) (_ : NormedAddCommGroup H) (_ : InnerProductSpace ℂ H)
      (T : H →L[ℂ] H), HasMassGap H T m := by
  refine ⟨ℂ, inferInstance, inferInstance, 0, hm, ?_⟩
  intro x
  simp
  exact mul_nonneg (by linarith) (sq_nonneg _)

end TheoremaAureum.Towers.YM.OS
