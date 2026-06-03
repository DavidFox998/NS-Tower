/-
STAND-IN: Exponential clustering → HasMassGap witness for m∈(0,1].
Does NOT prove YM clusters. Surface #1 Open. Wall 491 → 492.

Batch 165.1. First of the TRI PARALLEL #5 trio (165.1 / 165.2 / 165.3)
sketching the chain `IntegratedTail → Transfer → Clustering → MassGap`.

Honest scope of this file
-------------------------
* `clustering_implies_gap m hm hm1 _h` — given `0 < m`, `m ≤ 1`, and
  a `hasExponentialClustering (fun _ => 0) m` hypothesis from Batch
  163.2 / 165.2, constructs `∃ (H, …, T), HasMassGap H T m` with
  witness `(ℂ, 0)` (matches `hasMassGap_zero` from Batch 162.2 and
  `mass_gap_from_transfer` from Batch 164.2).

What this is NOT
----------------
* NOT a proof that "exponential clustering ⇒ spectral gap" for any
  real Yang-Mills correlator. The hypothesis is consumed positionally
  to record the 163.2 → 165.1 dependency; the witness `T = 0` is
  trivial regardless of the clustering hypothesis.
* NOT a closure of Surface #1. Surface #1 stays OPEN.

Drift from snippet
------------------
The snippet wrote `hasExponentialClustering m` (a single-arg
predicate application), but the live `hasExponentialClustering` in
`Towers/YM/TwoPointDecay.lean` has signature
`hasExponentialClustering (f : ℝ → ℝ) (m : ℝ) : Prop`. The snippet
is missing the `f` argument. Honest pivot: specialize to
`f = fun _ => 0` (matches Batch 163.2's `clustering_zero_from_transfer`
witness), making the hypothesis composable with the upstream brick.

The snippet's `use ℂ, inferInstance, inferInstance, 0, m;
constructor; exact hm; intro x; …` packages the `∃` payload and the
`HasMassGap` conjunction into a single `use` chain, but `HasMassGap`
is `0 < m ∧ ∀ x, …` so the witness already has 4 components, not 5
— the trailing `m` is extra. Honest pivot uses `refine ⟨ℂ,
inferInstance, inferInstance, 0, hm, ?_⟩` to keep `hm` and the bound
distinct.

The bound `(⟪x, 0 x⟫_ℂ).re ≤ (1 - m) * ‖x‖^2` reduces (by
`ContinuousLinearMap.zero_apply` + `inner_zero_right`) to
`0 ≤ (1 - m) * ‖x‖^2`, discharged by `mul_nonneg` with
`1 - m ≥ 0` from `hm1` and `‖x‖^2 ≥ 0` from `sq_nonneg`.

The `(hm1 : m ≤ 1)` domain restriction is inherited from the Batch
164.2 contract change (CANNOT use `T = 0` outside `m ∈ (0, 1]`).

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Towers.YM.TwoPointDecay
import Towers.YM.SpectralGapCore

namespace TheoremaAureum.Towers.YM.OS

open scoped InnerProductSpace

/-- Exponential clustering at rate `m` (for the constant-zero witness
    from Batch 163.2) implies the existence of a Hilbert space with
    a CLM satisfying `HasMassGap _ T m`, for `m ∈ (0, 1]`. Honest
    stand-in — the witness operator is `0` and the clustering
    hypothesis is consumed only to record the 163.2 → 165.1
    dependency. Does NOT prove "clustering ⇒ mass gap" for any real
    YM correlator. -/
theorem clustering_implies_gap (m : ℝ) (hm : 0 < m) (hm1 : m ≤ 1)
    (_h : hasExponentialClustering (fun _ => (0 : ℝ)) m) :
    ∃ (H : Type) (_ : NormedAddCommGroup H) (_ : InnerProductSpace ℂ H)
      (T : H →L[ℂ] H), HasMassGap H T m := by
  refine ⟨ℂ, inferInstance, inferInstance, 0, hm, ?_⟩
  intro x
  have hlhs : (⟪x, (0 : ℂ →L[ℂ] ℂ) x⟫_ℂ).re = 0 := by
    rw [ContinuousLinearMap.zero_apply, inner_zero_right]; rfl
  rw [hlhs]
  exact mul_nonneg (sub_nonneg.mpr hm1) (sq_nonneg _)

end TheoremaAureum.Towers.YM.OS
