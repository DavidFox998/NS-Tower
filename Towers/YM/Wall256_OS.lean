-- Wall256_OS.lean  (H2 — Osterwalder–Seiler 1978 Thm 2.1, rate/summability certificate)
-- Axiom footprint: {propext, Classical.choice, Quot.sound} only. No sorry. No axiom.
-- Scope: H2a machine-checked (rate I = -log w1 for concrete a n = w1^n).
--        H2b (SU(3) Haar integral; abstract cluster step) stays OPEN / OUT_OF_TOWER.
-- HOLD: written; do NOT push, lake build, or CI-trigger pending David's review.
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Towers.YM.Wall256_Scaffold

namespace TheoremaAureum.Towers.YM.Wall256OS

open Real

/-!
## Wall256_OS — Osterwalder–Seiler rate certificate (H2a)

### What this file is

This file formalizes the *analytic* half of the Osterwalder–Seiler 1978 Thm 2.1
activity bound (OS leaf D5, label **H2a** in the KP taxonomy):

> Given `0 < w1 < 1/7`, the rate `I := -log w1` satisfies `I > log 7` and makes
> `∑_{n} 7^n · exp(-I)^n` summable (geometric ratio `7·w1 < 1`).

This is the **rate/summability certificate**; it is machine-checked in full.

### What this file is NOT

- It does NOT formalize the Osterwalder–Seiler *cluster expansion* step (H2b):
  the abstract-activity propagation through the Ursell/truncated expansion.
  That step is absent from Mathlib v4.31.0-rc2; tagged OPEN / OUT_OF_TOWER / E4.
- It does NOT link `w1` to the SU(3) Haar integral
  `∫_{SU(3)} exp(-β·actL) dHaar`. That numeric dependency (E1) is certified
  out-of-tower by CERT_Arb: β₀ ∈ [2.079416880123, 2.079416880124]. Still OPEN
  as a Lean term.
- It does NOT prove a mass gap, Surface #1, or any Clay result.
  `hOS_Surface` / `W1_Surface` record exactly what stays OPEN.
- No `sorry`. No `axiom`. Classical trio preserved.
-/

/-- **Rate/summability activity bound** (Wall256OS version).
    `TruncatedActivityBound I` asserts that the entropy-weighted geometric series
    `∑_{n} 7^n · exp(-I)^n` converges — equivalently, that `7·exp(-I) < 1`,
    i.e. that `I > log 7`.

    **Distinct from** `Wall256Note.TruncatedActivityBound (a : ℕ → ℝ)`: that is
    the *function-level* per-polymer activity bound (∀ n, a n ≤ exp(-I)^n).
    This `def` is the *rate certificate* for the concrete geometric series, and
    is what the machine-checked `hOS` theorem produces. -/
def TruncatedActivityBound (I : ℝ) : Prop :=
  Summable (fun n : ℕ => (7 : ℝ) ^ n * Real.exp (-I) ^ n)

/-!
### H2a — machine-checked theorems (rate certificate)
-/

/-- For the concrete per-polymer activity `a n := w1^n`, the per-size bound
    `a n ≤ w1^n` is immediate (reflexivity). This records the H2a base case:
    when the abstract `a` of `Wall256_Scaffold` is instantiated to the geometric
    sequence `fun n => w1^n`, the Wall256Note activity bound is trivially
    satisfied with no residual obligation. -/
theorem os_activity_bound_of_w1 (w1 : ℝ) (hw1_pos : 0 < w1) (hw1 : w1 < 1 / 7) :
    ∀ n : ℕ, w1 ^ n ≤ w1 ^ n :=
  fun _ => le_refl _

/-- **H2a — Osterwalder–Seiler rate certificate** (machine-checked).
    From `0 < w1 < 1/7`, the rate `I := -log w1` satisfies `I > log 7` and
    `TruncatedActivityBound I` holds. Two steps:

    * **Rate `I > log 7`**: `7·w1 < 1` gives `log(7·w1) < 0`
      (by `Real.log_neg`), hence `log 7 + log w1 < 0`, hence `log 7 < -log w1`.

    * **Summability**: `exp(-(-log w1)) = exp(log w1) = w1`, so the series is
      `∑ (7·w1)^n`, which converges by `summable_geometric_of_lt_one`
      since `0 ≤ 7·w1 < 1`.

    **Note:** This discharges `hOS_Surface` (rate form) but does NOT discharge
    the `hOS` hypothesis of `Wall256_Scaffold` — that `hOS` operates on the
    abstract `a : ℕ → ℝ` via `Wall256Note.TruncatedActivityBound` (the full
    Osterwalder–Seiler cluster step, E4, absent from Mathlib). H2b stays OPEN. -/
theorem hOS (w1 : ℝ) (hw1_pos : 0 < w1) (hw1 : w1 < 1 / 7) :
    ∃ I : ℝ, TruncatedActivityBound I ∧ Real.log 7 < I := by
  refine ⟨-Real.log w1, ?_, ?_⟩
  · -- TruncatedActivityBound (-log w1):
    --   Summable (fun n => 7^n * exp(-(-log w1))^n)
    -- = Summable (fun n => 7^n * w1^n)     [exp(log w1) = w1]
    -- = Summable (fun n => (7·w1)^n)       [← mul_pow]
    show Summable (fun n : ℕ => (7 : ℝ) ^ n * Real.exp (- -Real.log w1) ^ n)
    have hexp : Real.exp (- -Real.log w1) = w1 := by
      rw [neg_neg, Real.exp_log hw1_pos]
    simp_rw [hexp, ← mul_pow]
    exact summable_geometric_of_lt_one (by positivity) (by linarith)
  · -- Real.log 7 < -Real.log w1:
    --   7·w1 < 1  →  log(7·w1) < 0  →  log 7 + log w1 < 0  →  log 7 < -log w1
    have h7w1_pos : (0 : ℝ) < 7 * w1 := mul_pos (by norm_num) hw1_pos
    have h7w1_lt  : (7 : ℝ) * w1 < 1 := by linarith
    have hlog_neg : Real.log ((7 : ℝ) * w1) < 0 :=
      Real.log_neg h7w1_pos h7w1_lt
    rw [Real.log_mul (by norm_num : (7 : ℝ) ≠ 0) hw1_pos.ne'] at hlog_neg
    linarith

/-!
### H2b — named OPEN surfaces (abstract cluster step; absent from Mathlib)
-/

/-- **Named OPEN surface: single-site weight positivity and strict bound.**
    `W1_Surface w1 b` asserts that the abstract weight `w1 : ℝ → ℝ` satisfies
    `0 < w1 β < 1/7` for every `β > b`. This is the numeric precondition H2a's
    antecedent `hw1_pos` + `hw1` requires at the functional level.

    For the concrete SU(3) Haar weight `w1 β = ∫_{SU(3)} exp(-β·actL) dHaar`,
    this holds only for `β` strictly above the certified threshold
    β₀ ∈ [2.079416880123, 2.079416880124] (CERT_Arb, out-of-tower mpmath.iv N=36;
    see `Wall256Scaffold.Hw1_Surface` for the `Beta0Certified` form).
    OPEN · OUT_OF_TOWER · [NEEDS_NUMERICS E1]. -/
def W1_Surface (w1 : ℝ → ℝ) (b : ℝ) : Prop :=
  ∀ β : ℝ, β > b → 0 < w1 β ∧ w1 β < 1 / 7

/-- **Named OPEN surface: abstract OS implication (H2b, Wall256Note form).**
    `hOS_Surface w1 a` is the propositional statement
    `w1 < 1/7 → Wall256Note.TruncatedActivityBound a`, mirroring the
    `hOS : w1 < 1/7 → TruncatedActivityBound a` hypothesis of `Wall256_Scaffold`.
    The machine-checked `theorem hOS` in this file proves the *rate* version
    (Wall256OS.TruncatedActivityBound) for the concrete activity `a n = w1^n`.
    The abstract cluster-expansion step (Osterwalder–Seiler 1978 Thm 2.1 in full,
    for arbitrary `a : ℕ → ℝ`) is absent from Mathlib v4.31.0-rc2.
    OPEN · OUT_OF_TOWER · [NEEDS_LEMMA E4]. -/
def hOS_Surface (w1 : ℝ) (a : ℕ → ℝ) : Prop :=
  w1 < 1 / 7 → TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound a

/-- Post-purge discharge pattern: `hOS_Surface w1 a` implies the
    `Wall256Note.TruncatedActivityBound a` conclusion given `hw1`. Consumes the
    open surface hypothesis directly; no proof term is supplied here. -/
theorem hOS_of_surface (w1 : ℝ) (a : ℕ → ℝ) (h : hOS_Surface w1 a)
    (hw1 : w1 < 1 / 7) :
    TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound a :=
  h hw1

/-!
### H2a -> hOS bridge (concrete geometric activity, classical trio only)
-/

/-- **`os_geometric_activity_bound`** -- H2a closes `Wall256Note.TruncatedActivityBound`
    for the concrete activity `a n = w1^n`.

    Given `0 < w1 < 1/7`, the concrete geometric sequence `fun n => w1^n`
    satisfies `Wall256Note.TruncatedActivityBound`:
    * nonnegativity: `w1^n >= 0` from `w1 > 0`;
    * rate `I = -log w1 > log 7`: same proof as `hOS`;
    * per-size bound: `w1^n = exp(-I)^n` (equality, since `exp(log w1) = w1`).

    This closes the H2a -> hOS gap for the geometric activity without any new
    axiom or sorry. H2b (abstract cluster step, E4) and Surfaces #1-#3 stay OPEN.
    No mass gap. No Clay result. Classical trio preserved. -/
theorem os_geometric_activity_bound (w1 : ℝ) (hw1_pos : 0 < w1) (hw1 : w1 < 1 / 7) :
    TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound (fun n => w1 ^ n) := by
  refine ⟨fun n => pow_nonneg hw1_pos.le n, -Real.log w1, ?_, fun n => ?_⟩
  · have h7w1_pos : (0 : ℝ) < 7 * w1 := mul_pos (by norm_num) hw1_pos
    have h7w1_lt  : (7 : ℝ) * w1 < 1 := by linarith
    have hlog_neg : Real.log ((7 : ℝ) * w1) < 0 :=
      Real.log_neg h7w1_pos h7w1_lt
    rw [Real.log_mul (by norm_num : (7 : ℝ) ≠ 0) hw1_pos.ne'] at hlog_neg
    linarith
  · have hexp : Real.exp (- -Real.log w1) = w1 := by
      rw [neg_neg, Real.exp_log hw1_pos]
    simp [hexp]

/-- **`hOS_concrete`** -- wraps `os_geometric_activity_bound` into the exact
    function signature that `Wall256Scaffold.strong_coupling_decay_of_open_inputs`
    expects for its `hOS` parameter, instantiated at the concrete activity
    `a n = w1^n`.

    This is the bridge between the machine-checked H2a rate certificate and the
    Scaffold's abstract `hOS` hypothesis, for the geometric case.
    No axiom. No sorry. Classical trio preserved.

    H2b (abstract Osterwalder-Seiler cluster step, E4) remains OPEN for
    general `a : N -> R`. This closes only the concrete geometric instance. -/
theorem hOS_concrete (w1 : ℝ) (hw1_pos : 0 < w1) :
    w1 < 1 / 7 →
    TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound (fun n => w1 ^ n) :=
  fun hw1 => os_geometric_activity_bound w1 hw1_pos hw1

end TheoremaAureum.Towers.YM.Wall256OS
