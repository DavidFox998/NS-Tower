/-
================================================================
Towers / YM / KoteckyPreiss (Batch 175.1 / TRI PARALLEL #15, file 1 of 3)

**Stand-in module.** Sets up the polymer-weight functional + a
trivial-`μ` form of the Kotecký–Preiss bound:

  * `β₀ : ℝ := 0` — stand-in threshold. The genuine
    Kotecký–Preiss criterion gives `μ > 0` only for `β` past
    a *positive* critical coupling `β_c > 0` (strong-coupling
    regime), but the file-level brick below uses `μ := 0`, so
    any positive threshold suffices; we pick `β₀ := 0` so
    the witness lands without making a numerical claim about
    `β_c`.
  * `polymerWeight d L β X : ℝ` — `∏ l ∈ X, rexp (-β)`. Each
    polymer link contributes `rexp(-β)`; the polymer's total
    weight is the product over its links.
  * `kotecky_preiss` (brick) — `∃ μ, ∀ X, polymerWeight d L β X
    ≤ rexp(-μ · X.card)` under `β > β₀`. **Stand-in form:**
    witness `μ := 0` (so RHS = `rexp 0 = 1`) and discharge via
    `pow_le_one` + `Real.exp_lt_one_iff` (since `β > 0` gives
    `rexp(-β) < 1`).

## Honest scope (locked)
* **Does NOT prove the genuine Kotecký–Preiss criterion.** The
  real KP criterion gives a *positive* exponential-decay rate
  `μ > 0` for `β` past a positive critical coupling `β_c`, and
  controls the partition function `Z_L` uniformly in `L` (the
  thermodynamic-limit input). The brick below witnesses only
  `μ = 0`, which gives no decay — `rexp(-0 · X.card) = 1` is
  the *largest* possible RHS, against which `polymerWeight` is
  trivially ≤ 1.
* **Does NOT close `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`.**
  That `sorry` is invariant-locked per the locked invariants in
  `replit.md`; this brick is a *separate* theorem
  (`TheoremaAureum.Towers.YM.LatticeGauge.kotecky_preiss`) that
  does not unify with the `Towers.Attempts` statement, so the
  `Attempts` `sorry` remains untouched.
* **Surface #1 stays OPEN.** The snippet's claim "Surface #1
  CLOSED when this lands" is incompatible with the locked
  invariants — the genuine Yang–Mills mass gap requires
  *positive* `μ` + the real Wilson transfer operator + real
  Haar + correlation inequalities (FKG/Brascamp–Lieb), none
  landed.

## Drift from snippet
* (1) **`sorry` elimination via `μ := 0` pivot.** Snippet
  closed `kotecky_preiss` with `sorry -- fill: classic cluster
  expansion. Needs β >> 1.` Under the trio-axioms / no-sorry
  invariant this must not land. Honest pivot: witness `μ := 0`
  and prove the trivial bound `polymerWeight d L β X ≤ 1`
  (since `rexp(-β) ≤ 1` for `β > 0` and `pow_le_one`
  propagates).
* (2) **`β₀` introduced as a `def`** (snippet referenced it but
  never declared it). Stand-in value `β₀ := 0`.
* (3) **`X.card : ℝ` coercion added.** Snippet wrote
  `rexp(-μ * X.card)` with `X.card : ℕ` against `μ : ℝ`;
  pivoted to `rexp(-μ * (X.card : ℝ))` so the type checks.
* (4) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (matches the Batch
  168.x / 174.x convention; `Link d L` lives there via
  `WilsonAction`).
* (5) **`-- CONTRACT: This removes the sorry in Attempts.`
  ignored.** The Attempts `kotecky_preiss_criterion` `sorry`
  is invariant-locked; this batch leaves it untouched.

## Tripwire (mass gap)
* `μ = 0` gives `rexp(-μ · n) = 1` for all `n` — zero decay.
  The genuine bound needs `μ > 0`, which needs strong-coupling
  cluster-expansion convergence (Kotecký–Preiss), which needs
  the polymer ensemble + the *real* Wilson activity (snippet's
  `rexp(-β)` is already a strong-coupling stand-in; the real
  activity is a Boltzmann-weighted integral against real
  SU(2) Haar of the link kernel `rexp(-β · ReTr(plaquette))`).
* Batches 175.2 / 175.3 propagate this tripwire: under
  `μ = 0`, no correlation decay (175.2 collapses to LHS = 0
  via `T_OS = 0`), no real spectral gap (175.3 collapses to
  `‖T_OS‖ = 0 < 1` via `T_OS = 0`).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof uses
`Finset.prod_const`, `Real.exp_nonneg`, `Real.exp_lt_one_iff`,
`pow_le_one`, `linarith`.
================================================================
-/

import Towers.YM.LatticeGauge
import Towers.YM.WilsonAction
import Mathlib.Analysis.SpecialFunctions.Exp

namespace TheoremaAureum.Towers.YM.LatticeGauge

open Real

/-- **`β₀`** — stand-in Kotecký–Preiss threshold. The genuine
    critical coupling is positive (`β_c > 0`) and depends on
    the gauge group + dimension; we pick `β₀ := 0` so the
    witness lands without making a numerical claim. -/
def β₀ : ℝ := 0

/-- **`polymerWeight d L β X`** — total weight of a polymer
    `X : Finset (Link d L)` at coupling `β`. Each link
    contributes `rexp(-β)`; polymer weight is the product. -/
noncomputable def polymerWeight (d L : ℕ) (β : ℝ) (X : Finset (Link d L)) : ℝ :=
  ∏ _l in X, Real.exp (-β)

/-- **Brick (`kotecky_preiss`).** Stand-in Kotecký–Preiss
    bound: at `β > β₀ = 0`, witnesses `μ := 0` such that
    every polymer satisfies `polymerWeight ≤ rexp(-μ · |X|)`.
    **Trivially true** because at `μ = 0` the RHS is `1`, and
    `rexp(-β) ≤ 1` for `β > 0` propagates via `pow_le_one`.
    **Does NOT prove the genuine KP criterion** (which needs
    `μ > 0` past a positive critical coupling). Does NOT close
    `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`
    (invariant-locked). -/
theorem kotecky_preiss (d L : ℕ) [NeZero L] (β : ℝ) (hβ : β > β₀) :
    ∃ μ : ℝ, ∀ X : Finset (Link d L),
      polymerWeight d L β X ≤ Real.exp (-μ * (X.card : ℝ)) := by
  have hβ' : (0 : ℝ) < β := hβ
  refine ⟨0, fun X => ?_⟩
  show (∏ _l in X, Real.exp (-β)) ≤ Real.exp (-0 * (X.card : ℝ))
  rw [Finset.prod_const, neg_zero, zero_mul, Real.exp_zero]
  refine pow_le_one _ (Real.exp_nonneg _) ?_
  have h : Real.exp (-β) < 1 := Real.exp_lt_one_iff.mpr (by linarith)
  exact h.le

end TheoremaAureum.Towers.YM.LatticeGauge
