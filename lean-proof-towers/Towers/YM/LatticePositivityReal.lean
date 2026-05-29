-- Surface #1: Yang-Mills Mass Gap
-- Wall 572 [YM1-LB-Real]: Hamiltonian Positivity over ℝ
-- Status: REDUCTION / LOWER BOUND ONLY. Does NOT prove m > 0.
-- Axioms: [propext, Classical.choice, Quot.sound] - PROJECT INVARIANT
--
-- Task #248 Step 4: H = −log T (genuine action-weighted Hamiltonian).
--   SUPERSEDES the Wall 572 `H = 1` identity stand-in. `H` below is now
--   the real Wilson Hamiltonian `H U := wilsonAction U • 𝟙`, the
--   `−log` of the Step-3 transfer operator `T = exp(−S_W[U]) · 𝟙`
--   (`TransferOperator`, `boltzmannWeight`): at the scalar / Perron
--   eigenvalue level `−log(exp(−S_W)) = S_W`, so `H`'s eigenvalue is
--   exactly `S_W[U] = wilsonAction U` (`neg_log_boltzmannWeight_eq_
--   wilsonAction` below makes this an honest brick).
--
-- HONEST SCOPE — READ BEFORE CITING:
--   * `H U ψ = wilsonAction U • ψ` on the finite real ℓ² space
--     `PiLp 2 (fun _ : Fin n => ℝ)` (= `EuclideanSpace ℝ (Fin n)`). Its
--     quadratic form is EXACTLY `⟪ψ, H U ψ⟫_ℝ = wilsonAction U · ‖ψ‖²`
--     (`hamiltonian_self_inner_eq`, UNCONDITIONAL).
--   * Positivity `0 ≤ ⟪ψ, H U ψ⟫_ℝ` therefore holds **iff**
--     `0 ≤ wilsonAction U`. The brick `hamiltonian_pos` is the genuine
--     REDUCTION: it takes `hS : 0 ≤ wilsonAction U` as an explicit
--     HYPOTHESIS and concludes `0 ≤ ⟪ψ, H U ψ⟫_ℝ`. It does NOT prove
--     `0 ≤ wilsonAction U`.
--   * `0 ≤ wilsonAction U` is the DEFERRED analytic input — the SU(3)
--     character / energy lower bound `Re tr P ≤ 3` (`plaquetteEnergy ≥
--     0`), which mathlib v4.12.0 does not ship usably (Task #248 Step 2
--     header). Until it lands, `H ≥ 0` is conditional and the equality
--     characterisation `⟪ψ,Hψ⟫=0 ↔ ψ=0` (which additionally needs the
--     STRICT `0 < wilsonAction U`) is NOT asserted.
--   * `hamiltonian_pos` makes **NO** mass-gap / μ>0 / spectral-gap /
--     Surface-#1 claim. Surface #1 stays OPEN; the YM tower stays
--     Status: Open. Any `m > 0` existence and the spectral gap are
--     deferred (Wall 573 / 574, Task #248 Step 5). `MassGap574.lean`
--     is untouched.
--
-- Drift from prior Wall 572: the old `hamiltonian_pos` was UNCONDITIONAL
-- because `H` was the identity (trivially PSD). The real `H = S_W · 𝟙`
-- is PSD only on the `S_W ≥ 0` locus, so the brick is now a hypothesis-
-- gated reduction (mirrors the Wall 573 `gap_reduction` pattern). This is
-- strictly more honest about the real operator, not a regression.
--
-- Registration: [YM1-LB-Real] (NOT [YM1]). NOT in `check-towers.sh`
--   BRICKS (lake-gated). Verify:
--     lake env lean Towers/YM/LatticePositivityReal.lean
--     #print axioms TheoremaAureum.YM_MassGap.hamiltonian_pos
--     (expected: [propext, Classical.choice, Quot.sound] — project trio)

import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Towers.YM.TransferOperator

open scoped InnerProductSpace
open TheoremaAureum.Towers.YM.LatticeGauge
open TheoremaAureum.Towers.YM.OS

namespace TheoremaAureum.YM_MassGap

variable {n : ℕ}

/-- **`H U`** — the genuine action-weighted Wilson Hamiltonian
    `H U ψ := wilsonAction U • ψ` on the finite real ℓ² space, i.e. the
    operator `wilsonAction U • 𝟙`. This is `−log T` of the Step-3
    transfer operator `T = exp(−S_W[U]) · 𝟙` at the scalar / Perron
    eigenvalue level (see `neg_log_boltzmannWeight_eq_wilsonAction`).
    Supersedes the Wall 572 `H = 1` identity stand-in.

    `noncomputable`: `wilsonAction U • ψ` scales a real `PiLp 2` vector,
    so the def depends on `Real.instRCLike` and has no executable code.
    This is codegen-only (axiom-neutral, proof-preserving); required so
    the module emits a real `.olean` for downstream `lake env lean`
    verification of `SpectrumBound` / `MassGap574`. -/
noncomputable def H {d L : ℕ} [NeZero L] (U : GaugeConfig d L)
    (ψ : PiLp 2 (fun _ : Fin n => ℝ)) : PiLp 2 (fun _ : Fin n => ℝ) :=
  wilsonAction U • ψ

/-- **Brick (`neg_log_boltzmannWeight_eq_wilsonAction`).** The genuine
    `H = −log T` relation at the eigenvalue level: minus the log of the
    Step-3 Boltzmann weight `exp(−S_W[U])` is the Wilson action
    `wilsonAction U` (= the eigenvalue of `H U`). Discharged by
    `Real.log_exp`. Honest content of "the Hamiltonian is `−log` of the
    transfer operator" on the Perron / scalar sector. -/
theorem neg_log_boltzmannWeight_eq_wilsonAction {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) :
    - Real.log (boltzmannWeight U) = wilsonAction U := by
  unfold boltzmannWeight
  rw [Real.log_exp]
  ring

/-- **Brick (`hamiltonian_self_inner_eq`).** UNCONDITIONAL quadratic-form
    identity: the energy expectation of the action-weighted Hamiltonian
    is exactly `wilsonAction U · ⟪ψ, ψ⟫_ℝ` (= `S_W[U] · ‖ψ‖²`). The
    genuine spectral content of `H U`; its sign is governed entirely by
    the sign of `wilsonAction U`. -/
theorem hamiltonian_self_inner_eq {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (ψ : PiLp 2 (fun _ : Fin n => ℝ)) :
    ⟪ψ, H U ψ⟫_ℝ = wilsonAction U * ⟪ψ, ψ⟫_ℝ := by
  unfold H
  rw [real_inner_smul_right]

/-- **Brick (`hamiltonian_pos`).** REDUCTION of "the real Wilson
    Hamiltonian is positive semidefinite" to the deferred action
    lower bound. GIVEN `hS : 0 ≤ wilsonAction U` (the open SU(3) energy
    nonnegativity, taken as a HYPOTHESIS), THEN `0 ≤ ⟪ψ, H U ψ⟫_ℝ` for
    every state `ψ` — because the energy is `wilsonAction U · ‖ψ‖²`
    (`hamiltonian_self_inner_eq`) and a product of nonnegatives is
    nonnegative (`mul_nonneg` with `real_inner_self_nonneg`).

    Proves NO `0 ≤ wilsonAction U`, NO `m > 0`, NO spectral gap — only
    the conditional "assumed action-nonnegativity ⟹ `H` is PSD". Makes
    NO mass-gap / μ>0 / Surface-#1 claim. Surface #1 stays OPEN, YM
    Status: Open. -/
theorem hamiltonian_pos {d L : ℕ} [NeZero L] (U : GaugeConfig d L)
    (hS : 0 ≤ wilsonAction U) :
    ∀ ψ : PiLp 2 (fun _ : Fin n => ℝ), 0 ≤ ⟪ψ, H U ψ⟫_ℝ := by
  intro ψ
  rw [hamiltonian_self_inner_eq]
  exact mul_nonneg hS real_inner_self_nonneg

end TheoremaAureum.YM_MassGap
