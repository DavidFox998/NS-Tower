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

/- CLAY_GRADE: OPEN 2026-06-03
   Witness-collapse NOT resolvable under Clay rules. The named proposition
   below is the as-written "gap ⇒ decay" shape; its consequent is discharged
   by the obvious function f t := exp(-m·t) (|f t| ≤ 1·exp), with the gap
   hypothesis unused, so as written it is trivially satisfiable and the
   genuine YM surface (a real correlator decaying from a real spectral gap)
   is unreachable in mathlib v4.12.0. De-registered from BRICKS. This names
   the proposition; it does NOT prove it, and does NOT close Surface #1. No
   sorry / no axiom. -/
def gap_to_decay_OPEN.{u} : Prop :=
  ∀ {H : Type u} [NormedAddCommGroup H] [InnerProductSpace ℂ H] (m : ℝ),
    0 < m → m < 1 →
    (∃ T : H →L[ℂ] H, T ≠ 0 ∧ HasMassGap H T m) →
      hasExponentialClustering (fun t => Real.exp (-m * t)) m

end TheoremaAureum.Towers.YM.OS
