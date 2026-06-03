/-
STAND-IN: From `(∃ T : H →L[ℂ] H, T ≠ 0 ∧ HasMassGap H T m)` (a
non-trivial spectral-gap witness on `H = L²(ℝ, ℂ)`, Batch 166.3),
exhibit an exponentially clustering function in the
`hasExponentialClustering` predicate sense (Batch 163.2 / TwoPointDecay).

Honest scope (locked)
---------------------
* This is the *converse* direction "spectral gap ⇒ decay" only in
  shape — we discharge `hasExponentialClustering (fun t => rexp(-m*t)) m`
  with the *obvious* witness function `f t := rexp(-m*t)`, which
  trivially satisfies `|f t| ≤ 1 · rexp(-m*t)`. The `T` hypothesis is
  not consumed; it is carried positionally to record the
  166.3 → 167.1 dependency.
* Does **NOT** prove that any real YM correlator decays exponentially
  from a YM mass gap. Surface #1 stays OPEN.

Drift from snippet
------------------
(1) Snippet wrote the conclusion as `hasExponentialClustering m`, but
    the live `hasExponentialClustering` in `Towers/YM/TwoPointDecay.lean`
    has signature `(f : ℝ → ℝ) (m : ℝ) : Prop` — it takes **two**
    arguments, not one. The snippet's `use fun t => rexp (-m * t), 1`
    line is consistent with the two-argument form (it provides the
    decay function and the constant `C = 1`), so we keep the proof
    body and fix the conclusion to
    `hasExponentialClustering (fun t => rexp (-m * t)) m`.
(2) Snippet's `simp` closer is not enough — the residual goal is
    `|rexp (-m * t)| ≤ 1 * rexp (-m * t)`. `Real.exp` is non-negative,
    so `|·|` collapses via `abs_of_nonneg (Real.exp_nonneg _)`, then
    `one_mul` rewrites the RHS. We use `simp [abs_of_nonneg
    (Real.exp_nonneg _), one_mul]` explicitly.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Towers.YM.NontrivialGap
import Towers.YM.TwoPointDecay

namespace TheoremaAureum.Towers.YM.OS

open Real ContinuousLinearMap

/-- From a non-trivial spectral-gap witness on `H = L²(ℝ, ℂ)`,
    exhibit the `hasExponentialClustering` predicate at rate `m`
    with the obvious function `f t := rexp(-m*t)`. The `T` witness
    is carried positionally to record the 166.3 → 167.1 dependency.
    Does NOT prove YM correlators decay. -/
theorem gap_to_decay (m : ℝ) (_hm : 0 < m) (_hm1 : m < 1) :
    (∃ T : H →L[ℂ] H, T ≠ 0 ∧ HasMassGap H T m) →
      hasExponentialClustering (fun t => Real.exp (-m * t)) m := by
  intro _hT
  refine ⟨1, one_pos, ?_⟩
  intro t
  simp [abs_of_nonneg (Real.exp_nonneg _)]

end TheoremaAureum.Towers.YM.OS
