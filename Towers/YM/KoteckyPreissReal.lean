/-
================================================================
Towers / YM / KoteckyPreissReal (Batch 176.2 / TRI PARALLEL #16, file 2 of 3)

**Stand-in module.** Lands the K-P existential `∃ β₀ μ : ℝ,
0 < μ ∧ ∀ β > β₀, ∀ X, polymerWeightReal d L β X ≤ rexp(-μ ·
|X|)` under the `linkEnergy ≡ 1` stand-in from Batch 176.1:

  * **Witness `(β₀, μ) := (1, 1)`.** Under `linkEnergy ≡ 1`,
    `polymerWeightReal d L β X = rexp(-β)^|X|`, and the
    desired RHS `rexp(-1 · |X|) = rexp(-1)^|X|`. For `β > 1`,
    `rexp(-β) ≤ rexp(-1)` (monotonicity of `Real.exp`), and
    `pow_le_pow_left` propagates the bound to the |X|-th
    power.

## Honest scope (locked)
* **Does NOT prove the genuine Kotecký–Preiss criterion.**
  The genuine K-P bound requires the *real* per-link Wilson
  energy `1 - 1/2 · Re tr U_p` (Batch 176.1 tripwire: dropped
  due to `plaquette` arity), the cluster-expansion convergence
  argument (combinatorial induction over polymer families,
  not landed), and a positive critical coupling `β_c` that
  depends on the gauge group (SU(2) here) + dimension. The
  brick below witnesses K-P only for the *conservative
  upper-bound* `linkEnergy ≡ 1` stand-in, where the bound
  trivializes.
* **Does NOT close `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`.**
  That `sorry` is invariant-locked per the locked invariants
  in `replit.md`; the brick below is a separately-named
  theorem in the `TheoremaAureum.Towers.YM.LatticeGauge`
  namespace (the Attempts theorem lives in
  `Towers.Attempts.ClusterExpansion`) and does not unify with
  it. The snippet's header claim "This removes the sorry in
  Attempts" is REFUSED.
* **Surface #1 stays OPEN.** The snippet's "Mass Gap proven
  for β >> 1. Surface #1 CLOSED" closing claim is
  incompatible with the locked invariants — the brick proves
  K-P only against the trivial energy stand-in `linkEnergy ≡
  1`, not against the real SU(2) Wilson activity. The
  genuine YM mass gap requires the full chain (real Wilson
  kernel + real Haar + K-P at the real activity + correlation
  inequalities), none landed.

## Drift from snippet
* (1) **`sorry -- fill: Uses β >> 1 and trace ≤ 2 for SU(2).
  Standard polymer estimate.` eliminated.** Snippet's
  "standard polymer estimate" is the cluster-expansion
  convergence theorem, which requires both the real activity
  *and* the combinatorial induction argument. Honest pivot:
  with `linkEnergy ≡ 1` (Batch 176.1 stand-in), the bound
  reduces to `rexp(-β)^|X| ≤ rexp(-1)^|X|`, provable for
  `β > 1` via `Real.exp_le_exp.mpr` + `pow_le_pow_left`.
* (2) **`X.card : ℝ` coercion** added throughout (snippet
  mixed `ℕ` and `ℝ` without coercion).
* (3) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (matches Batch 176.1).
* (4) **`open Real` dropped.** Snippet opened `Real`, but the
  proof uses fully-qualified `Real.exp` / `Real.exp_le_exp`
  for explicitness.

## Tripwire (mass gap)
* The witness `(β₀, μ) := (1, 1)` produces `μ = 1`, but only
  against the conservative `linkEnergy ≡ 1` stand-in. The
  genuine K-P `μ` depends on `β` (the real critical coupling
  `β_c` is positive but finite, and `μ` grows with `β - β_c`);
  this μ is a *trivial* constant, not the genuine spectral
  rate.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof uses
`Finset.prod_const`, `Real.exp_nonneg`, `Real.exp_le_exp`,
`pow_le_pow_left`, `Real.exp_nat_mul`, `linarith`,
`push_cast`, `ring`.
================================================================
-/

import Towers.YM.PolymerModel

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`kotecky_preiss_real`).** Stand-in form of the
    Kotecký–Preiss criterion under the `linkEnergy ≡ 1`
    Batch 176.1 pivot. Witnesses `(β₀, μ) := (1, 1)` (so
    `0 < μ`), and the polymer bound reduces to `rexp(-β)^|X|
    ≤ rexp(-1)^|X|` for `β > 1`. **Does NOT prove the genuine
    K-P criterion** (real Wilson activity + cluster expansion
    deferred). **Does NOT close
    `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`**
    (invariant-locked; different theorem). -/
theorem kotecky_preiss_real (d L : ℕ) [NeZero L] :
    ∃ β₀ μ : ℝ, 0 < μ ∧ ∀ β > β₀, ∀ X : Polymer d L,
      polymerWeightReal d L β X ≤ Real.exp (-μ * (X.card : ℝ)) := by
  refine ⟨1, 1, zero_lt_one, fun β hβ X => ?_⟩
  unfold polymerWeightReal linkEnergy
  simp only [mul_one]
  rw [Finset.prod_const]
  have hβ' : (1 : ℝ) < β := hβ
  have h_exp_nn : (0 : ℝ) ≤ Real.exp (-β) := Real.exp_nonneg _
  have h_exp_le : Real.exp (-β) ≤ Real.exp (-1) :=
    Real.exp_le_exp.mpr (by linarith)
  calc Real.exp (-β) ^ X.card
      ≤ Real.exp (-1) ^ X.card := pow_le_pow_left h_exp_nn h_exp_le _
    _ = Real.exp ((X.card : ℕ) * (-1 : ℝ)) := (Real.exp_nat_mul (-1) X.card).symm
    _ = Real.exp (-1 * (X.card : ℝ)) := by congr 1; push_cast; ring

end TheoremaAureum.Towers.YM.LatticeGauge
