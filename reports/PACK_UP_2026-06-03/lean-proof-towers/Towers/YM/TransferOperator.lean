/-
================================================================
Towers / YM / TransferOperator — genuine action-weighted transfer
operator (Task #248, Step 3; supersedes the Batch 162.3 zero-CLM
placeholder and RETIRES its `spectral_radius_transfer_zero` tripwire)

**Definition module.** Replaces the maximally-degenerate zero CLM
`TransferOperator := 0` with a genuine operator built from the *real*
Wilson action `LatticeGauge.wilsonAction` of Task #248 Step 2:

  * `boltzmannWeight U : ℝ`  — the Euclidean Boltzmann / Perron weight
                              `exp(−S_W[U])` of a gauge configuration
                              `U : GaugeConfig d L`. Strictly positive;
                              equals `1` at the vacuum `U ≡ 1` (where
                              `S_W = 0`).
  * `TransferOperator H U`   — the Boltzmann-weighted transfer operator
                              `exp(−S_W[U]) · 𝟙` on a complex Hilbert
                              space `H`. The transfer operator restricted
                              to a single time-slice configuration `U`
                              (the Perron / scalar sector): its single
                              eigenvalue is the Boltzmann weight, and at
                              the vacuum it is the identity (eigenvalue
                              `1`), NOT the degenerate `0` of the old
                              placeholder.

## What this RETIRES
The Batch 162.3 placeholder `TransferOperator := (0 : H →L[ℂ] H)` and
its brick `spectral_radius_transfer_zero` (`spectralRadius ℂ
(TransferOperator H) = 0`). That brick was explicitly documented as a
**tripwire**: "Replacing the placeholder `TransferOperator := 0` with a
real Markov-like / Wilson-loop transfer operator will *intentionally*
break this brick." Step 3 trips it: the operator now carries a config
argument and is action-weighted, so the zero-arg `= 0` brick no longer
typechecks and is removed here (and from `scripts/check-towers.sh`).
No other module referenced the zero-CLM symbol or that brick
(`TransferOperatorBound.transfer_gap_zero` uses a literal `0`, not this
operator), so the retirement is local.

## Honest scope (locked)
* `TransferOperator H U = exp(−S_W[U]) · 𝟙` is the **Perron / scalar
  sector** of the Wilson transfer operator — multiplication by the
  Boltzmann weight on a single time-slice configuration. It is a genuine
  function of the real Wilson action (NOT the zero operator, NOT the
  identity, NOT an integer stand-in).
* It is **NOT** the full Wilson / Markov integral transfer operator on
  `L²(∏_links SU(3), Haar)`: that requires the Haar measure on the
  continuous gauge group and the integral-operator construction
  `(Tψ)(U) = ∫ K(U,U') ψ(U') dμ(U')` with kernel `exp(−S_W)`, neither
  of which is in mathlib v4.12.0 scope. That full operator is deferred.
* **Surface #1 stays OPEN; YM Status: Open.** No mass-gap / `μ > 0` /
  spectral-gap claim. The single eigenvalue / spectral-radius value
  `exp(−S_W[U])` carries NO mass-gap information; this file only builds
  the operator object the Steps 4–5 (`H = −log T`, `spectrum_bound`)
  will consume.

## Axiom footprint (static analysis — live `#print axioms` deferred to
   the next green `towers-build`, per the lake re-clone gotcha)
* `boltzmannWeight_pos`        — `Real.exp_pos`.
* `boltzmannWeight_const_one`  — `wilsonAction_const_one_eq_zero` (Step
                                 2) + `neg_zero` + `Real.exp_zero`.
* `TransferOperator_vacuum_eq_id` — `boltzmannWeight_const_one` +
                                 `Complex.ofReal_one` + `one_smul`.
All three are simp/`exact` discharges over standard mathlib lemmas;
expected footprint is the classical trio
`{propext, Classical.choice, Quot.sound}`. No `sorry`, no new axioms.
================================================================
-/

import Towers.YM.WilsonAction
import Mathlib.Analysis.NormedSpace.OperatorNorm.Basic
import Mathlib.Analysis.Normed.Algebra.Spectrum
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum.Towers.YM.OS

open ContinuousLinearMap
open TheoremaAureum.Towers.YM.LatticeGauge

/-- **`boltzmannWeight U`** — the Euclidean Boltzmann / Perron weight
    `exp(−S_W[U])` of a gauge configuration, built from the genuine
    real Wilson action `wilsonAction` (Task #248 Step 2). Strictly
    positive; `= 1` at the vacuum `U ≡ 1`. -/
noncomputable def boltzmannWeight {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) : ℝ :=
  Real.exp (- wilsonAction U)

/-- **`TransferOperator H U`** — the Boltzmann-weighted transfer
    operator `exp(−S_W[U]) · 𝟙` on a complex Hilbert space `H`. The
    Perron / scalar sector of the Wilson transfer operator: a genuine
    function of the real Wilson action. Replaces the Batch 162.3 zero
    CLM. NOT the full `L²(∏ SU(3), Haar)` integral operator (deferred). -/
noncomputable def TransferOperator (H : Type*)
    [NormedAddCommGroup H] [NormedSpace ℂ H]
    {d L : ℕ} [NeZero L] (U : GaugeConfig d L) : H →L[ℂ] H :=
  (boltzmannWeight U : ℂ) • (1 : H →L[ℂ] H)

/-- **Brick (`boltzmannWeight_pos`).** The Boltzmann weight is strictly
    positive (`Real.exp_pos`). A real, non-degenerate value for every
    configuration — contrast the old placeholder's spectral radius `0`. -/
theorem boltzmannWeight_pos (d L : ℕ) [NeZero L] (U : GaugeConfig d L) :
    0 < boltzmannWeight U := by
  unfold boltzmannWeight
  exact Real.exp_pos _

/-- **Brick (`boltzmannWeight_const_one`).** At the vacuum `U ≡ (1 : G)`
    the Wilson action is `0` (`wilsonAction_const_one_eq_zero`, Step 2),
    so the Boltzmann weight is `exp(−0) = exp 0 = 1` — the Perron
    eigenvalue at the vacuum. -/
theorem boltzmannWeight_const_one (d L : ℕ) [NeZero L] :
    boltzmannWeight (fun _ : Link d L => (1 : G)) = 1 := by
  simp [boltzmannWeight, wilsonAction_const_one_eq_zero, neg_zero,
    Real.exp_zero]

/-- **Brick (`TransferOperator_vacuum_eq_id`).** At the vacuum
    `U ≡ (1 : G)` the transfer operator is the identity
    `exp(−0) · 𝟙 = 1 · 𝟙 = 𝟙` (single eigenvalue `1`). This is the
    genuine replacement for the old `spectral_radius_transfer_zero`
    tripwire: the going-forward transfer operator at the vacuum is the
    identity, NOT the degenerate zero. Makes NO mass-gap / `μ > 0` /
    Surface-#1 claim — Surface #1 stays OPEN, YM Status: Open. -/
theorem TransferOperator_vacuum_eq_id (H : Type*)
    [NormedAddCommGroup H] [NormedSpace ℂ H] (d L : ℕ) [NeZero L] :
    TransferOperator H (fun _ : Link d L => (1 : G)) = (1 : H →L[ℂ] H) := by
  simp [TransferOperator, boltzmannWeight_const_one, Complex.ofReal_one,
    one_smul]

end TheoremaAureum.Towers.YM.OS
