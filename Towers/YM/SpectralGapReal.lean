/-
================================================================
Towers / YM / SpectralGapReal (Batch 175.3 / TRI PARALLEL #15, file 3 of 3)

**Stand-in module.** A `β > β₀`-parameterized form of the OS
transfer-operator spectral-norm bound + the bridge theorem for
positive mass gap:

  * `spectral_gap_real` (brick) — `‖T_OS d L β‖ < 1` under
    `β > β₀`. **Trivially true** under the Dirac stand-in
    `T_OS = 0` (Batch 174.2), since `‖0‖ = 0 < 1`.
  * `mass_gap_pos_real` (brick) — `0 < mass_gap d L β` under
    `β > β₀` *and* `h_pos : 0 < ‖T_OS d L β‖`. Vacuously true
    under the stand-in because `h_pos` reduces to `0 < 0`
    (false), so the theorem cannot be invoked; once a real `T`
    with `0 < ‖T‖ < 1` lands, both hypotheses hold and
    `mass_gap = -log ‖T‖ > 0` is the genuine mass gap. Bridge
    theorem for the real-Haar program.

## Honest scope (locked)
* **Surface #1 stays OPEN.** This module does *NOT* prove the
  Yang–Mills mass gap. The snippet's header `Surface #1 CLOSED
  when this lands` is incompatible with the locked invariants;
  honest pivot: the bricks below are trivially / vacuously
  true under the Dirac stand-in, exactly as Batch 174.3's
  `spectral_gap` / `mass_gap_pos` (this file is the
  `β > β₀`-parameterized restatement, opening the interface
  for real-Haar swap-in but not closing the gap).
* The genuine Yang–Mills mass gap requires:
    - real Wilson `T` (Batch 174.2 tripwire),
    - Kotecký–Preiss at `μ > 0` (Batch 175.1 tripwire),
    - correlation inequalities / cluster bound `‖T‖ ≤
      rexp(-m)` (Batch 175.2 tripwire),
    - real Haar on SU(2) link-product (Batch 168.3 tripwire).
  None of the above is landed; `kotecky_preiss_criterion` in
  `Towers/Attempts/ClusterExpansion.lean` remains a `sorry`
  (invariant-locked).

## Drift from snippet
* (1) **`sorry` elimination via `T_OS = 0` propagation.**
  Snippet's `spectral_gap_real` was `sorry -- fill: from 175.2,
  ‖T‖ ≤ e^{-m}` (the Clay-statement Yang–Mills mass gap).
  Under the trio-axioms / no-sorry invariant this must not
  land. Honest pivot: same as Batch 174.3's `spectral_gap` —
  `T_OS := 0`, `‖T_OS‖ = ‖0‖ = 0 < 1` is closed by `simp`.
  The bound is *vacuous* and **does NOT prove the YM mass
  gap**.
* (2) **`Real.neg_log_pos_iff` pivot.** Snippet wrote
  `Real.neg_log_pos_iff.mpr (spectral_gap_real d L β hβ)` for
  `mass_gap_pos_real`. The lemma `Real.neg_log_pos_iff` does
  **not** exist in mathlib v4.12.0 (it would mean
  `0 < -log x ↔ x < 1`, but `log` is `0` on `x ≤ 0`, so this
  iff is false — `0 < -log 0 = 0` is false). The closest is
  `Real.log_neg : 0 < x → x < 1 → log x < 0`, which requires
  **both** `0 < x` and `x < 1`, not just one. Honest pivot:
  reparameterize on `h_pos : 0 < ‖T_OS d L β‖` (in addition
  to `_hβ`) and close via `neg_pos.mpr (Real.log_neg h_pos
  (spectral_gap_real …))`. Under the stand-in `h_pos` reduces
  to `0 < 0` (false), so the theorem is *vacuously true*; its
  *use* is the bridge into the real-Haar program.
* (3) **Symbol pivot `T` → `T_OS`.** Snippet's `T d L β` does
  not exist; the OS transfer operator is `T_OS` (Batch 174.2,
  renamed from snippet's `T` to avoid clash with the
  pre-existing `Towers.YM.TransferOperator`).
* (4) **`mass_gap` reused from Batch 174.3.** Snippet's
  `rw [mass_gap]` works because `mass_gap` in
  `Towers.YM.SpectralGapOS` (Batch 174.3) is defined as
  `-Real.log ‖T_OS d L β‖`; we import that module here
  rather than redefining.
* (5) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge`.
* (6) **Wall accounting drift (+1).** Snippet's wall sketch
  `533 → 534` allots +1 brick for this file, but it contains
  *two* theorems (`spectral_gap_real` + `mass_gap_pos_real`),
  both of which register as bricks. Net TRI-#15 brick delta
  is +4 (= +1 + +1 + +2), landing wall `531 → 535`, +1 past
  the snippet's `534` target. Documented as footnote ⁶ in
  `replit.md`.

## Tripwire (mass gap, explicit)
* `spectral_gap_real` here adds no new content over Batch
  174.3's `spectral_gap` — both reduce to `‖0‖ < 1` under
  the stand-in. The hypothesis `hβ : β > β₀` is *unused* in
  the proof (preserved in the signature for downstream
  interface compatibility).
* `mass_gap_pos_real` is the *bridge* theorem: take the
  conclusion of an honest cluster-expansion / correlation-
  decay chain (`0 < ‖T‖ < 1`) and produce the mass gap. Under
  the stand-in this bridge cannot fire (the `0 < ‖T_OS‖`
  hypothesis is false because `T_OS = 0`).

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proofs use
`simp` (via `norm_zero`, `zero_lt_one`) and
`neg_pos.mpr (Real.log_neg _ _)`.
================================================================
-/

import Towers.YM.CorrelationDecay
import Towers.YM.SpectralGapOS

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`spectral_gap_real`).** Stand-in spectral-norm
    bound: `‖T_OS d L β‖ < 1` under `β > β₀`. **Trivially true**
    under the Dirac stand-in `T_OS = 0` since `‖0‖ = 0 < 1`.
    Adds no new content over Batch 174.3's `spectral_gap` —
    the `β > β₀` hypothesis is preserved in the signature for
    downstream interface compatibility but is *unused* in the
    proof. **Does NOT prove the Yang–Mills mass gap.** -/
theorem spectral_gap_real (d L : ℕ) [NeZero L] (β : ℝ) (_hβ : β > β₀) :
    ‖T_OS d L β‖ < 1 := by
  show ‖(0 : H_OS d L β →L[ℂ] H_OS d L β)‖ < 1
  simp

/-- **Brick (`mass_gap_pos_real`).** Bridge theorem: under
    `β > β₀` *and* `0 < ‖T_OS d L β‖`, the mass gap
    (`-Real.log ‖T_OS‖`, from Batch 174.3) is positive.
    **Vacuously true** under the stand-in `T_OS = 0` (the
    `0 < ‖T_OS‖` hypothesis reduces to `0 < 0`, false); under
    a real transfer operator with `0 < ‖T‖ < 1`, both
    hypotheses hold and the conclusion gives the genuine mass
    gap. Snippet's `Real.neg_log_pos_iff.mpr` pivoted to
    `neg_pos.mpr (Real.log_neg h_pos h_lt)` because
    `Real.neg_log_pos_iff` does not exist in mathlib v4.12.0
    (and would be false: `log 0 = 0` by convention, so
    `0 < -log 0 ↔ 0 < 1` is true while `0 < 1` is true but
    `-log 0 = 0` is *not* positive). -/
theorem mass_gap_pos_real (d L : ℕ) [NeZero L] (β : ℝ) (hβ : β > β₀)
    (h_pos : 0 < ‖T_OS d L β‖) :
    0 < mass_gap d L β := by
  show 0 < -Real.log ‖T_OS d L β‖
  exact neg_pos.mpr (Real.log_neg h_pos (spectral_gap_real d L β hβ))

end TheoremaAureum.Towers.YM.LatticeGauge
