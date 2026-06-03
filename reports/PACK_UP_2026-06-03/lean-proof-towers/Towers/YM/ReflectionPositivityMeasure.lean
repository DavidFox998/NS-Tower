/-
STAND-IN: Constructs the trivial δ₀ functional satisfying `reflectionPos`.
Does NOT prove that any Yang-Mills / Euclidean measure is reflection-positive.

Batch 157.2. Brick that demonstrates `reflectionPos` (from 157.1
`Towers/YM/ReflectionPositivityCore.lean`) is *inhabited* — i.e. that
the predicate has at least one witness. This is the analog of
"the predicate is consistent / not vacuously universal"; it is NOT
a proof that any specific lattice or continuum Yang-Mills measure
satisfies OS Axiom 1.

Honest scope of this file
-------------------------
* `diracEvalLM`              — δ₀ evaluation packaged as a ℂ-linear functional
                                `(EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ`.
                                Real LinearMap (not a placeholder).
* `reflection_at_zero`       — coord-0 reflection fixes the origin
                                (since reflecting `0₀ = 0` in coord 0
                                yields `0` back). Real lemma.
* `reflectionPos_diracEvalLM` — the δ₀ functional satisfies the
                                `reflectionPos` predicate from 157.1.
                                Closes via `z * conj z = ‖z‖²` and
                                `normSq_nonneg`. Honest brick.

What this file does NOT prove
-----------------------------
* This is NOT OS Axiom 1 for any Yang-Mills measure.
* δ₀ is a *single point mass*; it satisfies `reflectionPos` for the
  trivial reason that the reflection fixes its support. It is not a
  Euclidean field-theory measure. No Yang-Mills content here.
* This file does NOT close Surface #1. The Surface1_InstallmentA.tex
  opengap remains and is parked.

Yang-Mills tower stays `Status: Open` in `docs/ROADMAP.md`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Towers.YM.ReflectionPositivityCore
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum.Towers.YM.OS

/-- δ₀ evaluation as a ℂ-linear functional on ℂ-valued test functions
    over `EuclideanSpace ℝ (Fin (n+1))`. Linearity holds definitionally:
    `(f + g) 0 = f 0 + g 0` and `(c • f) 0 = c • (f 0)` are both `rfl`
    on `Pi`-like function types. -/
noncomputable def diracEvalLM {n : ℕ} :
    (EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ where
  toFun f := f 0
  map_add' _ _ := rfl
  map_smul' _ _ := rfl

@[simp] lemma diracEvalLM_apply {n : ℕ}
    (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    (diracEvalLM : (EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ) f = f 0 := rfl

/-- The coord-0 reflection of any test function evaluated at the origin
    equals its value at the origin (since reflecting `0₀ = 0` in coord 0
    yields the all-zero vector back). -/
lemma reflection_at_zero {n : ℕ} (f : EuclideanSpace ℝ (Fin (n+1)) → ℂ) :
    reflection f (0 : EuclideanSpace ℝ (Fin (n+1))) = f 0 := by
  unfold reflection
  -- After unfold: f (Function.update 0 0 (-((0 : EuclideanSpace …) 0))) = f 0
  -- `(0 : EuclideanSpace ℝ (Fin (n+1))) 0` is `(0 : ℝ)` by `Pi.zero_apply`
  -- under the `WithLp`/`PiLp` type synonym chain (all `rfl` underneath).
  have h0 : ((0 : EuclideanSpace ℝ (Fin (n+1))) 0 : ℝ) = (0 : ℝ) := rfl
  rw [h0, neg_zero]
  -- Goal: f (Function.update 0 0 (0 : ℝ)) = f 0
  -- Use Function.update_eq_self after rewriting 0 to the destination's
  -- own value at index 0 (which is itself 0).
  have h1 : (Function.update (0 : EuclideanSpace ℝ (Fin (n+1))) 0 (0 : ℝ)
            : EuclideanSpace ℝ (Fin (n+1))) = 0 := by
    have hself : ((0 : EuclideanSpace ℝ (Fin (n+1))) 0 : ℝ) = (0 : ℝ) := rfl
    rw [← hself]
    exact Function.update_eq_self 0 (0 : EuclideanSpace ℝ (Fin (n+1)))
  rw [h1]

/-- The δ₀ ℂ-linear functional satisfies the `reflectionPos` predicate
    from 157.1. Honest inhabitedness witness — proves the predicate is
    consistent, NOT that any Yang-Mills measure satisfies OS Axiom 1.
    Surface #1 stays Open. -/
lemma reflectionPos_diracEvalLM {n : ℕ} :
    reflectionPos
      (diracEvalLM : (EuclideanSpace ℝ (Fin (n+1)) → ℂ) →ₗ[ℂ] ℂ) := by
  intro f
  -- Unfold `diracEvalLM` via the `@[simp]` lemma. The goal becomes
  -- `0 ≤ ((fun x => starRingEnd ℂ (f x) * reflection f x) 0).re`,
  -- which beta-reduces to `0 ≤ (starRingEnd ℂ (f 0) * reflection f 0).re`.
  simp only [diracEvalLM_apply]
  -- Goal: 0 ≤ (starRingEnd ℂ (f 0) * reflection f 0).re
  rw [reflection_at_zero]
  -- Goal: 0 ≤ (starRingEnd ℂ (f 0) * f 0).re
  -- Use the standard identity `z * conj z = normSq z` (as a complex number
  -- via `Complex.ofReal`), then take real parts.
  have hmul : starRingEnd ℂ (f 0) * f 0
              = ((Complex.normSq (f 0) : ℝ) : ℂ) := by
    rw [mul_comm]; exact Complex.mul_conj (f 0)
  rw [hmul, Complex.ofReal_re]
  exact Complex.normSq_nonneg _

end TheoremaAureum.Towers.YM.OS
