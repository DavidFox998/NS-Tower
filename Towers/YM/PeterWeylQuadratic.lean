/-
================================================================
Towers / YM / PeterWeylQuadratic  (Task #157 — tighter envelope)

**Tighter envelope bricks for the SU(3) Peter-Weyl heat-kernel
series.** Two new sorry-free bricks that strengthen the slack
bounds shipped in Batch 19.1p-redux-a (`Towers/YM/PeterWeyl.lean`):

  1. `Casimir_SU3_explicit_real_ge_quadratic`
       (already landed in `Towers/YM/Casimir.lean`, Batch 156 file
       1; the bound is `¾·(m+n)² + 3(m+n) ≤ C₂`, sharper than the
       linear `(m+n) ≤ C₂` from `PeterWeyl.lean` Brick 1).

  2. `Weyl_dim_SU3_explicit_real_le_cubic`  *(new, this file)*
       `(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m+n : ℝ) + 2)^3`
       — real-valued cubic upper bound on the SU(3) Weyl
       dimension, in the `(m+n)` antidiagonal shape. Companion to
       Batch 156.2 file 2's `dim_cubic_bound` in
       `Towers/YM/WeylDim.lean` (which targets the integer-valued
       `dim_SU3 m n` definition and gives `≤ 8·(m+n+1)^3`).
       Both bounds are real and coexist; this one is the
       PeterWeyl-shape (`Weyl_dim_SU3_explicit` over `Weyl_label`),
       not the standalone-integer shape.

  3. `PeterWeyl_Summable_SU3_quadratic`  *(headline, this file)*
       Same conclusion as Batch 19.1p-redux-a's
       `PeterWeyl_Summable_SU3` — `Summable` for every `β > 0` —
       but the proof routes through the **quadratic** Casimir
       bound from `Towers/YM/Casimir.lean` instead of the linear
       bound. Concretely we keep the linear `3(m+n)` part of the
       quadratic lower bound (dropping the nonneg `¾(m+n)²` term),
       yielding `exp(-β·C₂) ≤ exp(-(3β)·m) · exp(-(3β)·n)` — a
       factor-of-3 sharper decay rate than the `PeterWeyl_Summable_SU3`
       envelope. The Peter-Weyl summand is then squeezed against
       the same `summable_poly_succ_exp_neg_real` 1-D envelope from
       Batch 19.1p-redux-a, now at the sharper rate `3β > 0`.

### Why this file exists

`Casimir_SU3_explicit_real_ge_linear` and
`Weyl_dim_SU3_explicit_real_le_poly` in Batch 19.1p-redux-a were
shipped as intentionally-slack envelope bounds (tripwires noted
in `docs/CHANGELOG.md`). The downstream Varadhan small-`t`
asymptotic in `Towers/YM/PeterWeylHeatVaradhan.lean` (and the
in-progress off-diagonal heat-kernel work) needs the **quadratic**
Casimir bound to recover the small-`t` decay exponent
`exp(-c/t)`, and any quantitative spectral-gap work on top of
this needs both tightenings. The new bricks land them in
PeterWeyl shape so the downstream files can `apply` them without
re-routing through `Towers/YM/Casimir.lean` and the standalone
`Towers/YM/WeylDim.lean`.

### Honest scope (locked)

The three bricks above are real-analysis facts about the SU(3)
Peter-Weyl spectral series at the identity. They are NOT:
  * a constructive 4D pure-Yang-Mills measure,
  * an Osterwalder-Schrader Hilbert space reconstruction,
  * a mass-gap lower bound on any YM Hamiltonian,
  * the Varadhan / Molchanov small-`t` heat-kernel asymptotic
    (that is parked in `Towers/YM/PeterWeylHeatVaradhan.lean`,
    strip form only).

**The old Batch 19.1p-redux-a bricks (`_real_ge_linear`,
`_real_le_poly`, `PeterWeyl_Summable_SU3`) are left in place,
unmodified.** This file is purely additive; no deletions.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface
#2 stays OPEN; `kotecky_preiss_criterion` remains a `sorry` in
`Towers/Attempts/ClusterExpansion.lean`. mathlib v4.12.0 only.
Axiom footprint: subset of mathlib's classical trio
`{propext, Classical.choice, Quot.sound}`.
================================================================
-/

import Towers.YM.Casimir

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeylQuadratic

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl
open TheoremaAureum.Towers.YM.Casimir

/-! ## Brick 1 — Cubic real-valued upper bound on Weyl dim

`(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m+n : ℝ) + 2)^3`.

Proof: all comparison at the ℕ level. The polynomial inequality
`(m+1)(n+1)(m+n+2) ≤ 2 · (m+n+2)^3` follows from
`(m+1)(n+1) = mn + m + n + 1 ≤ (m+n+2)^2` (AM-GM with slack since
`(m+n+2)^2 = (m+1)^2 + 2(m+1)(n+1) + (n+1)^2 ≥ 2(m+1)(n+1)`).
Then `Nat.div_le_of_le_mul` drops the `/2`, and a single
`push_cast; linarith` lands the real-valued statement.

Used by the downstream Varadhan work to control `dim²` against
the antidiagonal `(m+n)^6` (which the new quadratic Casimir
bound's `exp(-β·(m+n)²)` factor can absorb). -/
theorem Weyl_dim_SU3_explicit_real_le_cubic (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ≤ ((mn.1 : ℝ) + mn.2 + 2) ^ 3 := by
  have key_nat :
      Weyl_dim_SU3_explicit mn ≤ (mn.1 + mn.2 + 2) ^ 3 := by
    unfold Weyl_dim_SU3_explicit
    -- (m+1)(n+1)(m+n+2) ≤ 2·(m+n+2)^3, all at ℕ.
    have h1 : (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2)
                ≤ 2 * (mn.1 + mn.2 + 2) ^ 3 := by
      zify
      nlinarith [sq_nonneg ((mn.1 : ℤ) - mn.2),
                 sq_nonneg ((mn.1 : ℤ) + mn.2 + 2),
                 Int.natCast_nonneg mn.1, Int.natCast_nonneg mn.2]
    exact Nat.div_le_of_le_mul h1
  have hcast : ((Weyl_dim_SU3_explicit mn : ℕ) : ℝ)
                ≤ (((mn.1 + mn.2 + 2 : ℕ) : ℝ)) ^ 3 := by
    exact_mod_cast key_nat
  have hpush : (((mn.1 + mn.2 + 2 : ℕ) : ℝ)) ^ 3
                = ((mn.1 : ℝ) + mn.2 + 2) ^ 3 := by push_cast; ring
  linarith

/-! ## Brick 2 (Headline) — Direct summability via quadratic Casimir

For every `β > 0`, `∑_{(m,n)} dim² · exp(-β · C₂)` is `Summable`,
proved directly via the **quadratic** Casimir lower bound
`¾·(m+n)² + 3(m+n) ≤ C₂` from `Towers/YM/Casimir.lean`. We drop
the nonneg `¾·(m+n)²` term and keep the linear `3(m+n)` part,
yielding the factor-of-3 sharper rate
`exp(-β·C₂) ≤ exp(-(3β)·m) · exp(-(3β)·n)` — versus the rate
`β` produced by the linear Casimir bound consumed by
`PeterWeyl_Summable_SU3`. The squeeze against the per-factor
envelope reuses Batch 19.1p-redux-a's
`summable_poly_succ_exp_neg_real` at rate `3β > 0`. -/
theorem PeterWeyl_Summable_SU3_quadratic {β : ℝ} (hβ : 0 < β) :
    Summable (fun mn : ℕ × ℕ =>
      ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ)))) := by
  have h3β : 0 < 3 * β := by linarith
  -- Per-factor 1D envelope at the sharpened rate `3β`.
  have h1d :
      Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 4 * Real.exp (-(3 * β * n))) :=
    summable_poly_succ_exp_neg_real h3β
  set f : ℕ → ℝ := fun n => ((n : ℝ) + 1) ^ 4 * Real.exp (-(3 * β * n))
    with hf_def
  have hf_nonneg : ∀ n, 0 ≤ f n := by
    intro n
    exact mul_nonneg (pow_nonneg (by positivity) _) (Real.exp_pos _).le
  set env : ℕ × ℕ → ℝ := fun mn => f mn.1 * f mn.2 with henv_def
  have henv_nonneg : (0 : ℕ × ℕ → ℝ) ≤ env :=
    fun mn => mul_nonneg (hf_nonneg _) (hf_nonneg _)
  have henv_summable : Summable env := by
    rw [summable_prod_of_nonneg henv_nonneg]
    refine ⟨fun x => ?_, ?_⟩
    · exact h1d.mul_left (f x)
    · have hcong : (fun x : ℕ => ∑' y, env (x, y)) =
          fun x : ℕ => f x * ∑' y, f y := by
        funext x
        simp only [henv_def]
        exact tsum_mul_left
      rw [hcong]
      exact h1d.mul_right _
  -- Pointwise bound: summand ≤ env, routing through the QUADRATIC Casimir.
  have hbound : ∀ mn : ℕ × ℕ,
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤ env mn := by
    intro mn
    have hdim_nonneg : (0 : ℝ) ≤ (Weyl_dim_SU3_explicit mn : ℝ) :=
      Nat.cast_nonneg _
    -- Reuse the existing degree-4 Weyl-dim bound for the product shape.
    have hdim_sq :
        (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 :=
      pow_le_pow_left hdim_nonneg (Weyl_dim_SU3_explicit_real_le_poly mn) 2
    -- Quadratic Casimir → linear `3(m+n) ≤ C₂` (drop the ¾(m+n)² term).
    have hcas_q := Casimir_SU3_explicit_real_ge_quadratic mn
    have hsq_nn : 0 ≤ (3 / 4 : ℝ) * ((mn.1 : ℝ) + mn.2) ^ 2 :=
      mul_nonneg (by norm_num) (sq_nonneg _)
    have hcas_lin :
        3 * ((mn.1 : ℝ) + mn.2) ≤ (Casimir_SU3_explicit mn : ℝ) := by
      linarith
    have hexp_bound :
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) := by
      apply Real.exp_le_exp.mpr
      have hβmul := mul_le_mul_of_nonneg_left hcas_lin hβ.le
      linarith
    have hexp_split :
        Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) =
          Real.exp (-(3 * β * mn.1)) * Real.exp (-(3 * β * mn.2)) := by
      rw [← Real.exp_add]; congr 1; ring
    have hexp_nonneg :
        (0 : ℝ) ≤ Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) :=
      (Real.exp_pos _).le
    have hpoly_sq_eq :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 =
          ((mn.1 : ℝ) + 1) ^ 4 * ((mn.2 : ℝ) + 1) ^ 4 := by ring
    have hstep1 :
        (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) :=
      mul_le_mul_of_nonneg_right hdim_sq hexp_nonneg
    have hstep2 :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) := by
      apply mul_le_mul_of_nonneg_left hexp_bound
      exact sq_nonneg _
    have hstep3 :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) = env mn := by
      simp only [henv_def, hf_def, hpoly_sq_eq, hexp_split]
      ring
    linarith [hstep1.trans (hstep2.trans hstep3.le)]
  -- Squeeze.
  have hsum_nonneg : ∀ mn : ℕ × ℕ, 0 ≤
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) := fun mn =>
    mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  exact Summable.of_nonneg_of_le hsum_nonneg hbound henv_summable

/-! ## Brick 3 — Honest quadratic-times-linear real-valued bound (Task #173)

`(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤
   ((m : ℝ) + 1) * ((n : ℝ) + 1) * ((m : ℝ) + n + 2) / 2`.

Tightens Brick 1's `Weyl_dim_SU3_explicit_real_le_cubic` from
`((m+n)+2)^3` down to the honest **exact** real-valued form — the
literal lift of `(m+1)(n+1)(m+n+2)/2` to `ℝ`, with the slack
coming only from the integer-division floor (at most `1/2`).

Proof: the natural-division floor satisfies
`2 · ((m+1)(n+1)(m+n+2) / 2) ≤ (m+1)(n+1)(m+n+2)` via
`Nat.div_mul_le_self`; cast once and divide by 2.

Used downstream by `Weyl_dim_SU3_explicit_real_le_half_cubic`
(Brick 4 below) and feeds a sharper Varadhan strip in
`Towers/YM/PeterWeylHeatVaradhan.lean` once the off-diagonal
work is wired up. -/
theorem Weyl_dim_SU3_explicit_real_le_half_prod (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ≤
      ((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1) * ((mn.1 : ℝ) + mn.2 + 2) / 2 := by
  have hfloor :
      (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2) / 2 * 2
        ≤ (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2) :=
    Nat.div_mul_le_self _ _
  have hcast :
      ((((mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2) / 2 : ℕ) : ℝ)) * 2
        ≤ ((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1) * ((mn.1 : ℝ) + mn.2 + 2) := by
    have hR := (Nat.cast_le (α := ℝ)).mpr hfloor
    push_cast at hR
    linarith
  unfold Weyl_dim_SU3_explicit
  linarith

/-! ## Brick 4 — Half-cubic real-valued bound (Task #173)

`(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m : ℝ) + n + 2) ^ 3 / 2`.

Tightens Brick 1's `Weyl_dim_SU3_explicit_real_le_cubic`
(`(dim:ℝ) ≤ ((m+n)+2)^3`) by the missing factor of `1/2` that
the task brief calls out as "currently slack". Routed through
Brick 3's honest quadratic-times-linear form, then squeezed by
`(m+1)(n+1) ≤ (m+n+2)^2` (AM-GM with slack: the gap is
`m² + n² + mn + 3m + 3n + 3 ≥ 0`).

Used by the in-progress Varadhan strip work in
`Towers/YM/PeterWeylHeatVaradhan.lean` to halve the slack of the
PeterWeyl-shape antidiagonal envelope. -/
theorem Weyl_dim_SU3_explicit_real_le_half_cubic (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ≤ ((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2 := by
  have hprod := Weyl_dim_SU3_explicit_real_le_half_prod mn
  have hm : (0 : ℝ) ≤ (mn.1 : ℝ) := Nat.cast_nonneg _
  have hn : (0 : ℝ) ≤ (mn.2 : ℝ) := Nat.cast_nonneg _
  have hsum_nn : (0 : ℝ) ≤ (mn.1 : ℝ) + mn.2 + 2 := by linarith
  have hquad :
      ((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1) ≤ ((mn.1 : ℝ) + mn.2 + 2) ^ 2 := by
    nlinarith [sq_nonneg ((mn.1 : ℝ) - mn.2), sq_nonneg ((mn.1 : ℝ) + mn.2),
               mul_nonneg hm hn, hm, hn]
  have hcubic_nat :
      ((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1) * ((mn.1 : ℝ) + mn.2 + 2)
        ≤ ((mn.1 : ℝ) + mn.2 + 2) ^ 3 := by
    have := mul_le_mul_of_nonneg_right hquad hsum_nn
    nlinarith [this]
  linarith

/-! ## Brick 5 — Degree-6 polynomial × geometric 1D summability (Task #217)

For every `β > 0`,
`Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 6 · Real.exp (-(β · n)))`.

Companion to Batch 19.1p-redux-a's degree-4
`summable_poly_succ_exp_neg_real` in `Towers/YM/PeterWeyl.lean`; the
degree-6 shift is what the squared half-cubic antidiagonal envelope
`(((m+n)+2)^3/2)^2` needs as its per-factor 1D dominator (each factor of
the product `(m+1)^6 (n+1)^6`). Proof: binomial-expand `(n+1)^6` and
combine the seven `Real.summable_pow_mul_exp_neg_nat_mul k` summands. -/
theorem summable_poly6_succ_exp_neg_real {β : ℝ} (hβ : 0 < β) :
    Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 6 * Real.exp (-(β * n))) := by
  have h6 : Summable (fun n : ℕ => (n : ℝ) ^ 6 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 6 hβ
  have h5 : Summable (fun n : ℕ => (n : ℝ) ^ 5 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 5 hβ
  have h4 : Summable (fun n : ℕ => (n : ℝ) ^ 4 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 4 hβ
  have h3 : Summable (fun n : ℕ => (n : ℝ) ^ 3 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 3 hβ
  have h2 : Summable (fun n : ℕ => (n : ℝ) ^ 2 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 2 hβ
  have h1 : Summable (fun n : ℕ => (n : ℝ) ^ 1 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 1 hβ
  have h0 : Summable (fun n : ℕ => (n : ℝ) ^ 0 * Real.exp (-β * n)) :=
    Real.summable_pow_mul_exp_neg_nat_mul 0 hβ
  have hcombined :
      Summable (fun n : ℕ =>
        (n : ℝ) ^ 6 * Real.exp (-β * n)
          + 6 * ((n : ℝ) ^ 5 * Real.exp (-β * n))
          + 15 * ((n : ℝ) ^ 4 * Real.exp (-β * n))
          + 20 * ((n : ℝ) ^ 3 * Real.exp (-β * n))
          + 15 * ((n : ℝ) ^ 2 * Real.exp (-β * n))
          + 6 * ((n : ℝ) ^ 1 * Real.exp (-β * n))
          + 1 * ((n : ℝ) ^ 0 * Real.exp (-β * n))) := by
    exact ((((((h6.add (h5.mul_left 6)).add (h4.mul_left 15)).add
      (h3.mul_left 20)).add (h2.mul_left 15)).add (h1.mul_left 6)).add
      (h0.mul_left 1))
  refine hcombined.congr (fun n => ?_)
  have hexp : Real.exp (-(β * (n : ℝ))) = Real.exp (-β * (n : ℝ)) := by
    congr 1; ring
  rw [hexp]
  ring

/-! ## Brick 6 (Headline) — Summability of the squared half-cubic
antidiagonal envelope (Task #217)

For every `t > 0`,
`∑_{(m,n)} (((m+n)+2)^3/2)^2 · exp(-(t · C₂(m,n)))` is `Summable`.

This is the summability needed to carry the per-summand half-cubic
brick `Heat_kernel_envelope_summand_real_le_half_cubic` (Task #193)
through to a `tsum`/strip bound on the genuine heat-kernel envelope
`Heat_kernel_envelope_real t` (the summed form is what downstream
strip / spectral-gap work consumes).

Proof (parallel to `PeterWeyl_Summable_SU3_quadratic`): dominate by the
product envelope `16 · (m+1)^6 (n+1)^6 · exp(-(3t)m) · exp(-(3t)n)`.
  - Polynomial: `m+n+2 ≤ 2(m+1)(n+1)` (AM-GM with slack), so
    `(((m+n)+2)^3/2)^2 = (m+n+2)^6/4 ≤ 16 (m+1)^6 (n+1)^6`.
  - Exponential: the quadratic Casimir bound
    `¾(m+n)² + 3(m+n) ≤ C₂` (dropping `¾(m+n)²`) gives
    `exp(-(t·C₂)) ≤ exp(-(3t)m) · exp(-(3t)n)`.
The product envelope is summable via the degree-6 1D dominator
`summable_poly6_succ_exp_neg_real` at rate `3t > 0`, then squeezed by
`Summable.of_nonneg_of_le`. -/
theorem PeterWeyl_Summable_SU3_half_cubic {t : ℝ} (ht : 0 < t) :
    Summable (fun mn : ℕ × ℕ =>
      (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ)))) := by
  have h3t : 0 < 3 * t := by linarith
  -- Per-factor 1D envelope at rate `3t`.
  have h1d :
      Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 6 * Real.exp (-(3 * t * n))) :=
    summable_poly6_succ_exp_neg_real h3t
  set f : ℕ → ℝ := fun n => ((n : ℝ) + 1) ^ 6 * Real.exp (-(3 * t * n))
    with hf_def
  have hf_nonneg : ∀ n, 0 ≤ f n := by
    intro n
    exact mul_nonneg (pow_nonneg (by positivity) _) (Real.exp_pos _).le
  -- Product envelope (with amplitude 16).
  have hprod_summable : Summable (fun mn : ℕ × ℕ => f mn.1 * f mn.2) := by
    rw [summable_prod_of_nonneg
      (fun mn => mul_nonneg (hf_nonneg _) (hf_nonneg _))]
    refine ⟨fun x => ?_, ?_⟩
    · exact h1d.mul_left (f x)
    · have hcong : (fun x : ℕ => ∑' y, f x * f y) =
          fun x : ℕ => f x * ∑' y, f y := by
        funext x
        exact tsum_mul_left
      rw [hcong]
      exact h1d.mul_right _
  set env : ℕ × ℕ → ℝ := fun mn => 16 * (f mn.1 * f mn.2) with henv_def
  have henv_summable : Summable env := by
    simp only [henv_def]
    exact hprod_summable.mul_left 16
  -- Pointwise bound: summand ≤ env, routing through the QUADRATIC Casimir.
  have hbound : ∀ mn : ℕ × ℕ,
      (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) ≤ env mn := by
    intro mn
    have hm : (0 : ℝ) ≤ (mn.1 : ℝ) := Nat.cast_nonneg _
    have hn : (0 : ℝ) ≤ (mn.2 : ℝ) := Nat.cast_nonneg _
    -- Polynomial base inequality `m+n+2 ≤ 2(m+1)(n+1)`.
    have hbase : (mn.1 : ℝ) + mn.2 + 2 ≤
        2 * (((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1)) := by
      nlinarith [mul_nonneg hm hn, hm, hn]
    have hsum_nn : (0 : ℝ) ≤ (mn.1 : ℝ) + mn.2 + 2 := by linarith
    have h6le : ((mn.1 : ℝ) + mn.2 + 2) ^ 6 ≤
        (2 * (((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1))) ^ 6 :=
      pow_le_pow_left hsum_nn hbase 6
    have hLeq : (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 =
        ((mn.1 : ℝ) + mn.2 + 2) ^ 6 / 4 := by ring
    have hReq : (2 * (((mn.1 : ℝ) + 1) * ((mn.2 : ℝ) + 1))) ^ 6 =
        64 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) := by ring
    have hpoly : (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 ≤
        16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) := by
      rw [hReq] at h6le
      rw [hLeq]
      linarith [h6le]
    -- Quadratic Casimir → linear `3(m+n) ≤ C₂` (drop the ¾(m+n)² term).
    have hcas_q := Casimir_SU3_explicit_real_ge_quadratic mn
    have hsq_nn : 0 ≤ (3 / 4 : ℝ) * ((mn.1 : ℝ) + mn.2) ^ 2 :=
      mul_nonneg (by norm_num) (sq_nonneg _)
    have hcas_lin :
        3 * ((mn.1 : ℝ) + mn.2) ≤ (Casimir_SU3_explicit mn : ℝ) := by
      linarith
    have hexp_bound :
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) ≤
          Real.exp (-(t * (3 * ((mn.1 : ℝ) + mn.2)))) := by
      apply Real.exp_le_exp.mpr
      have hmul := mul_le_mul_of_nonneg_left hcas_lin ht.le
      linarith
    have hexp_split :
        Real.exp (-(t * (3 * ((mn.1 : ℝ) + mn.2)))) =
          Real.exp (-(3 * t * mn.1)) * Real.exp (-(3 * t * mn.2)) := by
      rw [← Real.exp_add]; congr 1; ring
    have hexp_nonneg :
        (0 : ℝ) ≤ Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) :=
      (Real.exp_pos _).le
    have hpoly_nonneg :
        (0 : ℝ) ≤ 16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) := by
      positivity
    have hstep1 :
        (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
            Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) ≤
          16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) *
            Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) :=
      mul_le_mul_of_nonneg_right hpoly hexp_nonneg
    have hstep2 :
        16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) *
            Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) ≤
          16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) *
            Real.exp (-(t * (3 * ((mn.1 : ℝ) + mn.2)))) :=
      mul_le_mul_of_nonneg_left hexp_bound hpoly_nonneg
    have hstep3 :
        16 * (((mn.1 : ℝ) + 1) ^ 6 * ((mn.2 : ℝ) + 1) ^ 6) *
            Real.exp (-(t * (3 * ((mn.1 : ℝ) + mn.2)))) = env mn := by
      rw [hexp_split]
      simp only [henv_def, hf_def]
      ring
    linarith [hstep1.trans (hstep2.trans hstep3.le)]
  -- Squeeze.
  have hsum_nonneg : ∀ mn : ℕ × ℕ, 0 ≤
      (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) := fun mn =>
    mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  exact Summable.of_nonneg_of_le hsum_nonneg hbound henv_summable

end PeterWeylQuadratic
end YM
end Towers
end TheoremaAureum
