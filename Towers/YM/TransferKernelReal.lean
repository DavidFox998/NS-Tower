/-
================================================================
Towers / YM / TransferKernelReal (Batch 177.3 / TRI PARALLEL #17, file 3 of 3)

**Stand-in module.** Lands a `‖T_real‖ < 1` spectral-norm
strict-inequality on the existing `T_real` from
`Towers.YM.CorrelationReal` (Batch 176.3), under the same Dirac
stand-in `T_real := 0`. Snippet's `def T_real := sorry` with a
"K(U, U') = rexp(-β · S_link)" kernel construction is REFUSED —
that requires real-Haar `gibbsMeasure` + Bochner-integrable
kernel-operator infrastructure, none landed. The brick is a
strict sharpening of `spectral_gap_real_kp` (Batch 176.3,
non-strict `≤ rexp(-μ)`), and parallels `spectral_gap` (Batch
174.3, on `T_OS`) and `spectral_gap_real` (Batch 175.3, on
`T_OS d L β`).

  * `spectral_gap_real_kernel` (brick) — `‖T_real d L β‖ < 1`.
    Trivially true: `‖0‖ = 0 < 1`. **Does NOT prove the YM mass
    gap** (which needs `0 < ‖T_real‖ < 1` for a non-zero `T`).

## Honest scope (locked)
* **Surface #1 stays OPEN.** The snippet's
  `CONTRACT: ‖T_real‖ < 1 now requires 177.2 + chessboard`
  claim and the user-supplied `"Real K-P proven, μ > 0"` /
  `"Surface #1 still OPEN until 177.3 lands with ‖T_real‖ < 1"`
  closing claim are both REFUSED at the *closure* level: this
  brick proves `‖T_real‖ < 1` under `T_real = 0`, which is the
  **trivial corner** of the inequality (a zero operator has
  zero norm), NOT the genuine Wilson transfer-operator
  spectral gap. The genuine `‖T‖ < 1` requires a non-zero `T`
  built from the real Wilson kernel + real Haar; deferred.
* **Does NOT upgrade `T_real = 0` to a real transfer kernel.**
  The snippet's `def T_real : H_OS →L[ℂ] H_OS := sorry` with a
  K(U, U') comment is REFUSED — the existing `T_real` from
  Batch 176.3 (Towers.YM.CorrelationReal) is *kept as-is* at
  `T_real := 0`. Defining a new "real" T here would either
  - clash with the existing `T_real` symbol in the same
    `TheoremaAureum.Towers.YM.LatticeGauge` namespace, or
  - require the Bochner / Lp kernel-operator infrastructure
    (deferred — Batch 174.2 / 176.3 tripwires).
  Honest pivot: reuse the existing `T_real`. The brick below
  is a strictly-sharper statement (`< 1` instead of `≤
  rexp(-μ)` from Batch 176.3's `spectral_gap_real_kp`), but
  proven by the same trivial `‖0‖ = 0` argument.
* **Does NOT prove the YM mass gap.** `mass_gap := -Real.log
  ‖T_OS‖` (Batch 174.3 `SpectralGapOS`) is defined in terms of
  `T_OS`, not `T_real`. Even if the brick below were on `T_OS`,
  `‖T_OS‖ < 1` alone gives `mass_gap = -log ‖T_OS‖ ≥ 0`, *not*
  `> 0` — the strict positivity requires `0 < ‖T_OS‖` (the
  vacuum-bridge hypothesis of `mass_gap_pos` / `mass_gap_pos_real`
  / `mass_gap_pos_real_kp`), which is *false* under the Dirac
  stand-in `T_OS = 0`.

## Drift from snippet
* (1) **`def T_real := sorry` REFUSED.** Snippet redeclared
  `T_real : H_OS d L β →L[ℂ] H_OS d L β := sorry` with a "Build
  from real Wilson kernel K(U,U') = exp(-β * S_link(U,U'))"
  comment. This would either clash with the existing `T_real`
  from Batch 176.3 (`Towers.YM.CorrelationReal`, in the same
  namespace, set to `0`) or introduce a `sorry` (forbidden under
  the trio-axioms / no-sorry invariant). Honest pivot: import
  and reuse the existing `T_real := 0` from `CorrelationReal`,
  and prove the new strict-inequality brick on top of it. No new
  T-definition lands.
* (2) **Brick renamed `spectral_gap_real_kp` →
  `spectral_gap_real_kernel`.** Snippet's name clashes with the
  existing `spectral_gap_real_kp` brick in Batch 176.3
  (`Towers.YM.CorrelationReal`, same namespace). Honest pivot:
  rename to `spectral_gap_real_kernel`, reflecting that the
  conceptual upgrade the snippet aimed for was a real kernel
  (deferred). The two bricks are now distinct theorems on the
  same `T_real := 0` symbol — Batch 176.3's is non-strict
  (`‖T_real‖ ≤ rexp(-μ)`), this batch's is strict (`‖T_real‖ <
  1`).
* (3) **Free symbol `β₀` removed from signature.** Snippet's
  `(hβ : β > β₀)` carried a hypothesis that does not load-bear
  under `T_real = 0` (the conclusion `‖0‖ < 1` is unconditional
  on `β`). Honest pivot: drop the hypothesis; the parameter `β
  : ℝ` is still in the signature because `T_real` depends on
  it (definitionally `0` for all `β`, but the dependence is
  declared in `CorrelationReal`).
* (4) **`sorry -- fill: Uses 177.2 + chessboard estimate +
  Cauchy-Schwarz` eliminated.** Snippet's chessboard /
  Cauchy-Schwarz estimate would bridge a real K-P bound
  (Batch 177.2 — which itself is trivial `μ = 0` under the
  honest pivot) to a spectral-norm bound on the real transfer
  operator. Since `T_real = 0`, no estimate is needed: `‖0‖
  = 0 < 1` via `norm_zero` + `(0 : ℝ) < 1`.
* (5) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (matches Batch 176.3 /
  177.1 / 177.2).

## Tripwire (mass gap, explicit)
* `‖T_real‖ < 1` here is the **trivial corner** of the
  Yang-Mills mass-gap statement. The Clay-statement mass gap
  requires `0 < m := -log ‖T_real‖`, which requires
  `0 < ‖T_real‖ < 1` (strict on both sides). The lower bound
  `0 < ‖T_real‖` is *false* under the Dirac stand-in (`T_real
  = 0` ⟹ `‖T_real‖ = 0`), making `mass_gap = -log 0 = 0` (by
  mathlib convention for `Real.log` on `0`), NOT positive. This
  is the same tripwire as Batches 174.3 `mass_gap_dirac` and
  176.3 `mass_gap_pos_real_kp`.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof shows
`T_real := 0` definitionally, rewrites by `norm_zero`, and
closes via `zero_lt_one`.
================================================================
-/

import Towers.YM.CorrelationReal

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`spectral_gap_real_kernel`).** Stand-in strict
    spectral-norm bound on the existing `T_real := 0` from
    Batch 176.3 (`Towers.YM.CorrelationReal`):
    `‖T_real d L β‖ < 1`. **Trivially true** under the Dirac
    stand-in `T_real = 0`: `‖0‖ = 0 < 1` via `norm_zero` +
    `zero_lt_one`. Strict sharpening of the non-strict
    `spectral_gap_real_kp` brick (Batch 176.3, `‖T_real‖ ≤
    rexp(-μ)`). **Does NOT prove the YM mass gap** (which needs
    `0 < ‖T_real‖`, false under the Dirac stand-in). The
    snippet's `def T_real := sorry` with a "K(U,U') = exp(-β ·
    S_link)" kernel construction is REFUSED — the existing
    `T_real := 0` is kept as-is, and the brick is a strict
    upper bound on its norm. -/
theorem spectral_gap_real_kernel (d L : ℕ) [NeZero L] (β : ℝ) :
    ‖T_real d L β‖ < 1 := by
  show ‖(0 : H_OS d L β →L[ℂ] H_OS d L β)‖ < 1
  rw [norm_zero]
  exact zero_lt_one

end TheoremaAureum.Towers.YM.LatticeGauge
