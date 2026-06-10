-- Surface #1: Yang-Mills Mass Gap
-- Wall 575 [YM1-SB]: spectral lower-bound predicate + gap→action reduction
-- Status: REDUCTION ONLY. Does NOT prove m > 0.
-- Axioms: [propext, Classical.choice, Quot.sound] - PROJECT INVARIANT
--
-- Task #248 Step 5: the `spectrum_bound` predicate and the reduction of
--   the spectral gap of the Step-4 action-weighted Hamiltonian
--   `H U = wilsonAction U • 𝟙` to the (deferred) Wilson-action bound.
--
-- HONEST SCOPE — READ BEFORE CITING:
--   * `spectrum_bound T m` is the quadratic-form lower bound
--     `∀ ψ, m · ‖ψ‖² ≤ ⟪ψ, T ψ⟫_ℝ`. For a positive-semidefinite `T`
--     this is the statement "the bottom of the spectrum of `T` is ≥ m".
--   * `spectrum_bound_H_iff` REDUCES the gap question for the Step-4
--     scalar Hamiltonian to a single real inequality:
--       `spectrum_bound (H U) m ↔ m ≤ wilsonAction U`
--     (needs `[NeZero n]` so a unit vector exists). Because `H U` is the
--     SCALAR operator `wilsonAction U • 𝟙`, its quadratic form is
--     `wilsonAction U · ‖ψ‖²` (`hamiltonian_self_inner_eq`), so the
--     spectral bound holds exactly when `m ≤ wilsonAction U`.
--   * CONSEQUENCE (honest tripwire): `∃ m > 0, spectrum_bound (H U) m`
--     is equivalent to `0 < wilsonAction U` — the DEFERRED STRICT action
--     positivity. This FAILS at the vacuum config (`wilsonAction
--     (const 1) = 0`, Step 2 `wilsonAction_const_one_eq_zero`). So the
--     scalar shadow `H U` does NOT deliver a Yang–Mills mass gap; the
--     real gap needs the full transfer operator on `L²(∏ SU(3), Haar)`
--     (Wall 574). See `MassGap574.lean`.
--   * Makes NO mass-gap / μ>0 / spectral-gap-EXISTS / Surface-#1 claim.
--     Surface #1 stays OPEN; the YM tower stays Status: Open.
--
-- Registration: [YM1-SB] (NOT [YM1]). NOT in `check-towers.sh` BRICKS
--   (lake-gated, depends on the lake-gated Wall 572 `H`). Verify:
--     lake env lean Towers/YM/SpectrumBound.lean
--     #print axioms TheoremaAureum.YM_MassGap.spectrum_bound_H_iff
--     (expected: [propext, Classical.choice, Quot.sound] — project trio)

import Mathlib.Analysis.InnerProductSpace.PiL2
import Towers.YM.LatticePositivityReal

open scoped InnerProductSpace
open TheoremaAureum.Towers.YM.LatticeGauge

namespace TheoremaAureum.YM_MassGap

/-- **`spectrum_bound T m`** — the spectral lower-bound predicate: the
    quadratic form of `T` dominates `m · ‖ψ‖²` on every state. For a
    PSD `T` this says the bottom of the spectrum of `T` is `≥ m`. -/
def spectrum_bound {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (T : E → E) (m : ℝ) : Prop :=
  ∀ ψ : E, m * ‖ψ‖ ^ 2 ≤ ⟪ψ, T ψ⟫_ℝ

/-- **Brick (`spectrum_bound_H_iff`).** The gap → action reduction for
    the Step-4 scalar Hamiltonian `H U = wilsonAction U • 𝟙` on the
    finite real ℓ² space (`[NeZero n]` so a unit vector exists):

      `spectrum_bound (H U) m ↔ m ≤ wilsonAction U`.

    Forward: evaluate the bound at the unit basis vector
    `EuclideanSpace.single 0 1` (norm 1) and use
    `hamiltonian_self_inner_eq`. Reverse: `mul_le_mul_of_nonneg_right`
    against `0 ≤ ‖ψ‖²`. Proves NO `m > 0`, NO spectral gap — only the
    equivalence of the bound with the (deferred) action inequality. -/
theorem spectrum_bound_H_iff {d L n : ℕ} [NeZero L] [NeZero n]
    (U : GaugeConfig d L) (m : ℝ) :
    spectrum_bound (E := PiLp 2 (fun _ : Fin n => ℝ)) (H U) m
      ↔ m ≤ wilsonAction U := by
  unfold spectrum_bound
  constructor
  · intro h
    have hn : 0 < n := Nat.pos_of_ne_zero (NeZero.ne n)
    have h0 := h (EuclideanSpace.single (⟨0, hn⟩ : Fin n) (1 : ℝ) :
      PiLp 2 (fun _ : Fin n => ℝ))
    rw [hamiltonian_self_inner_eq, real_inner_self_eq_norm_sq,
        EuclideanSpace.norm_single, norm_one, one_pow, mul_one, mul_one] at h0
    exact h0
  · intro hm ψ
    rw [hamiltonian_self_inner_eq, real_inner_self_eq_norm_sq]
    exact mul_le_mul_of_nonneg_right hm (sq_nonneg ‖ψ‖)

end TheoremaAureum.YM_MassGap
