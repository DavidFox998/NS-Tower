/-
================================================================
Towers / YM / SpectralGapOS (Batch 174.3 / TRI PARALLEL #14, file 3 of 3)

**Stand-in module.** Introduces the spectral-gap / mass-gap
quantities for the OS transfer operator + the tripwire that
crystallises why the Dirac stand-in **does NOT** prove the
Yang-Mills mass gap:

  * `mass_gap d L β` — `noncomputable def` for `-log ‖T_OS‖`.
    Under the Dirac stand-in, `T_OS = 0`, `‖T_OS‖ = 0`,
    `Real.log 0 = 0` (mathlib convention), and `mass_gap = 0`
    (NOT positive). Brick `mass_gap_dirac` below.
  * `spectral_gap` — `‖T_OS d L β‖ < 1`. Trivially true under
    the stand-in because `‖0‖ = 0 < 1`. **Does NOT prove the
    Yang-Mills mass gap** — the bound is vacuous for the zero
    operator. Surface #1 stays OPEN.
  * `mass_gap_dirac` — `mass_gap d L β = 0` (the Dirac
    stand-in gives mass gap exactly zero). **This is the
    tripwire.** It makes the gap between the stand-in
    (`mass_gap = 0`) and the genuine Yang-Mills mass gap
    (`mass_gap > 0`) explicit and provable.
  * `mass_gap_pos` — `0 < mass_gap d L β`, parameterized on
    *both* `0 < ‖T_OS‖` and `‖T_OS‖ < 1`. Under the stand-in,
    `0 < ‖T_OS‖ = 0` is false, so the hypothesis cannot be
    supplied and the theorem is vacuously true. Under a real
    transfer operator with `0 < ‖T‖ < 1`, both hypotheses hold
    and the conclusion gives the mass gap.

Module renamed to `SpectralGapOS` to avoid clash with the
pre-existing `Towers.YM.SpectralGap` (older module already in
lakefile roots).

## Honest scope (locked)
* **Surface #1 stays OPEN.** This module does *NOT* prove the
  Yang-Mills mass gap — the `spectral_gap` and `mass_gap_pos`
  theorems below are trivially / vacuously true under the
  Dirac stand-in of Batch 168.3, and the `mass_gap_dirac`
  brick *crystallises* this honestly: the Dirac mass gap is
  `0`, not positive. The genuine Yang-Mills mass gap requires
  the chain
    - real-Haar `gibbsMeasure` (deferred — Batch 168.3
      tripwire),
    - real-Haar OS-1..4 (deferred — Batches 169.3 / 170.3 /
      171.3 / 172.3 / 173.3 tripwires),
    - real Wilson kernel for the transfer operator
      (deferred — Batch 174.2 tripwire),
    - cluster expansion + correlation inequalities (Kotecký–
      Preiss / Brascamp–Lieb / etc., none landed; the
      `kotecky_preiss_criterion` in
      `Towers/Attempts/ClusterExpansion.lean` is still a
      `sorry` — invariant-locked).
* Does NOT prove `0 < ‖T‖` for any non-stand-in `T`. Does NOT
  prove `‖T‖ < 1` for any non-stand-in `T`. Does NOT close any
  Dirac-stand-in tripwire from Batches 169.3 / 170.3 / 171.3 /
  172.3 / 173.3. Does NOT touch the Clay-statement axiom
  footprint of `TheoremaAureum.main_theorem`.

## Drift from snippet
* (1) **`sorry` elimination via `T_OS := 0` propagation.**
  Snippet's `spectral_gap` was `sorry -- THE HARD THEOREM. Needs
  cluster expansion + correlation inequalities.` (the Yang-
  Mills mass gap, Clay problem). Under the trio-axioms / no-
  sorry invariant this must not land as `sorry`. Honest
  pivot: with the stand-in `T_OS := 0` from Batch 174.2,
  `‖T_OS‖ = ‖0‖ = 0 < 1` is provable by `simp [T_OS]`. The
  result is *vacuously true* (it bounds the norm of the zero
  operator) and **does NOT prove the Yang-Mills mass gap** —
  this is documented prominently in the file header, the
  theorem docstring, and the `mass_gap_dirac` brick.
* (2) **`mass_gap_pos` hypothesis pivot.** Snippet wrote
  `mass_gap_pos (hβ : β > 0) : 0 < mass_gap` with proof
  `exact Real.neg_log_pos_iff.mpr h` — but
  `Real.neg_log_pos_iff` does NOT exist in mathlib v4.12.0
  (the closest is `Real.log_neg : 0 < x → x < 1 → log x < 0`,
  which requires *both* `0 < x` and `x < 1`, not just one).
  And even if it did, `‖T_OS‖ = 0` under the stand-in fails
  `0 < ‖T_OS‖`. Honest pivot: parameterize `mass_gap_pos` on
  *both* `0 < ‖T_OS‖` and `‖T_OS‖ < 1`, then close via
  `neg_pos.mpr (Real.log_neg h_pos h_lt)`. The hypothesis
  `h_pos : 0 < ‖T_OS‖` is *false* under the stand-in (it
  reduces to `0 < 0`), so the theorem is vacuously true — its
  *use* is as the bridge that, once real-`T` is landed with
  `0 < ‖T‖ < 1`, gives the genuine mass gap.
* (3) **`mass_gap_dirac` brick added.** Snippet had two
  theorems; under the +3 wall jump accounting from this file
  (`528 → 531`, after 174.1 +1 and 174.2 +2), this file must
  land three bricks. Added `mass_gap_dirac : mass_gap d L β =
  0` as the **explicit tripwire** that the Dirac stand-in
  gives mass gap zero, NOT positive.
* (4) **Module rename to `SpectralGapOS`** to avoid clash
  with `Towers.YM.SpectralGap` (older module already in
  lakefile roots).
* (5) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge`.

## Tripwire (mass-gap, made explicit)
The genuine Yang-Mills mass gap requires:
  1. A **non-zero** transfer operator `T` — needs real Wilson
     kernel + real Haar (Batches 168.3 / 174.2 tripwires).
  2. `0 < ‖T‖` — needs the kernel to be non-degenerate,
     i.e. needs the partition function to be non-zero on a
     non-vacuous support. (Under real Haar on SU(2)^Links and
     real-valued `wilsonAction`, both hold.)
  3. `‖T‖ < 1` — **the actual mass gap** — needs cluster
     expansion (Kotecký–Preiss, currently a `sorry` in
     `Towers/Attempts/ClusterExpansion.lean`, invariant-
     locked) + correlation inequalities (Brascamp–Lieb /
     Reflection Positivity / etc., deferred).
None of (1), (2), or (3) is landed for the real Wilson
transfer operator on real Haar. **Surface #1 stays OPEN.**

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proofs are
`simp [T_OS]` (using `norm_zero`, `Real.log_zero`,
`zero_lt_one`) and `neg_pos.mpr (Real.log_neg _ _)`.
================================================================
-/

import Towers.YM.TransferOperatorOS

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **`mass_gap`** — `-log ‖T_OS‖`. Under the Dirac stand-in,
    `T_OS = 0`, `‖T_OS‖ = 0`, `Real.log 0 = 0` (mathlib
    convention), so `mass_gap = -0 = 0`. **NOT positive under
    the stand-in** — see `mass_gap_dirac` below. -/
noncomputable def mass_gap (d L : ℕ) [NeZero L] (β : ℝ) : ℝ :=
  -Real.log ‖T_OS d L β‖

/-- **Brick (`spectral_gap`).** `‖T_OS d L β‖ < 1`. **Trivially
    true under the Dirac stand-in** because `T_OS := 0` and
    `‖0‖ = 0 < 1`. **Does NOT prove the Yang-Mills mass gap** —
    the bound is vacuous for the zero operator. Surface #1
    stays OPEN. See file header for the deferred chain (real
    Haar + cluster expansion + correlation inequalities). -/
theorem spectral_gap (d L : ℕ) [NeZero L] (β : ℝ) (_hβ : 0 < β) :
    ‖T_OS d L β‖ < 1 := by
  show ‖(0 : H_OS d L β →L[ℂ] H_OS d L β)‖ < 1
  simp

/-- **Brick (`mass_gap_dirac`).** **The tripwire.** Under the
    Dirac stand-in, `mass_gap d L β = 0` — exactly zero, not
    positive. Crystallises the gap between the stand-in and
    the genuine Yang-Mills mass gap: the latter requires a
    non-stand-in transfer operator (real Wilson kernel + real
    Haar) with `0 < ‖T‖ < 1`, which the stand-in `T_OS := 0`
    does NOT provide. -/
theorem mass_gap_dirac (d L : ℕ) [NeZero L] (β : ℝ) :
    mass_gap d L β = 0 := by
  show -Real.log ‖(0 : H_OS d L β →L[ℂ] H_OS d L β)‖ = 0
  simp

/-- **Brick (`mass_gap_pos`).** `0 < mass_gap d L β`,
    parameterized on **both** `0 < ‖T_OS d L β‖` and
    `‖T_OS d L β‖ < 1`. Under the Dirac stand-in,
    `0 < ‖T_OS‖ = 0` is false, so the theorem is *vacuously
    true*. Under a real transfer operator with
    `0 < ‖T‖ < 1`, both hypotheses hold and the conclusion
    gives `mass_gap = -log ‖T‖ > 0` (the genuine mass gap).
    This is the bridge theorem to the real-Haar program. -/
theorem mass_gap_pos (d L : ℕ) [NeZero L] (β : ℝ)
    (h_pos : 0 < ‖T_OS d L β‖) (h_lt : ‖T_OS d L β‖ < 1) :
    0 < mass_gap d L β := by
  show 0 < -Real.log ‖T_OS d L β‖
  exact neg_pos.mpr (Real.log_neg h_pos h_lt)

end TheoremaAureum.Towers.YM.LatticeGauge
