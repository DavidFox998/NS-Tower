/-
================================================================
Towers / YM / PeterWeyl  (Batch 19.1p-redux-a — Task #154)

**SU(3) Peter-Weyl Summability.** Four sorry-free bricks proving
that the Peter-Weyl spectral series of the SU(3) heat kernel at
the identity,
  `∑_{(m,n) : ℕ × ℕ} (dim λ_{m,n})² · exp(-β · C₂(λ_{m,n}))`
is `Summable` for every `β > 0`. Discharges what Batch 19.3
parked as the "Summable lemma is what blocks 19.1p" sorry in
`Towers/Attempts/ClusterExpansion.lean` (line 693).

The summand uses the **real explicit polynomial forms** landed in
Batch 19.1n (`Towers/YM/ClusterExpansion.lean` lines 1783-1794),
NOT the placeholders `Weyl_dim_def := 1` / `Casimir_eigenvalue_def := 0`
(which would force `Summable (fun _ => 1)`, false).

### What ships (4 bricks)

  1. `Casimir_SU3_explicit_real_ge_linear`
        `((m : ℝ) + n) ≤ Casimir_SU3_explicit (m,n)`
     Trivial Nat→Real cast bound: `m² + n² + mn + 3m + 3n ≥ 3m + 3n ≥ m + n`.

  2. `Weyl_dim_SU3_explicit_real_le_poly`
        `(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m : ℝ)+1)^2 · ((n : ℝ)+1)^2`
     Via `Nat.cast_div_le` and `(m+n+2) ≤ 2(m+1)(n+1)`.

  3. `summable_poly_succ_exp_neg_real`
        `Summable (fun n : ℕ => ((n : ℝ)+1)^4 · Real.exp (-(β · n)))` for `β > 0`
     Index-shift onto mathlib's `summable_pow_mul_exp_neg_nat_mul` with `k = 4`.

  4. `PeterWeyl_Summable_SU3` *(headline)*
        `Summable (fun (mn : ℕ × ℕ) =>
            (Weyl_dim_SU3_explicit mn : ℝ)^2 · Real.exp (-(β · Casimir_SU3_explicit mn)))`
     Squeeze via brick 1+2 against the product envelope
     `((m+1)^4 · exp(-βm)) · ((n+1)^4 · exp(-βn))`, with the
     product `Summable` via `summable_prod_of_nonneg.mpr` and
     `Summable.mul_left` / `.mul_right` on top of brick 3.

### Honest scope (locked)

The four bricks above are textbook real-analysis facts about the
SU(3) Peter-Weyl spectral series at the identity. They are NOT:
  * a constructive 4D pure-Yang-Mills measure,
  * the Osterwalder-Schrader Hilbert space reconstruction,
  * a mass-gap lower bound on any YM Hamiltonian,
  * the Varadhan / Molchanov small-`t` heat-kernel asymptotic
    `K_t(1) ~ C · exp(-c/t) / t^4` (that is the *next* gap,
    parked downstream in 19.1p-redux-b).

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2.
================================================================
-/

import Towers.YM.ClusterExpansion
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Topology.Algebra.InfiniteSum.Ring

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeyl

open TheoremaAureum.Towers.YM.ClusterExpansion

/-! ## Brick 1 — Casimir lower bound (linear) -/

/-- **Linear lower bound on the explicit SU(3) Casimir.**
For every highest weight `(m, n) : ℕ × ℕ`,
`m + n ≤ Casimir_SU3_explicit (m, n)`. Trivial via
`m² + n² + mn + 3m + 3n ≥ 3m + 3n ≥ m + n`; cast to ℝ.

Used in Brick 4 to dominate `exp(-β · C₂)` by
`exp(-β · m) · exp(-β · n)`. -/
theorem Casimir_SU3_explicit_real_ge_linear (mn : Weyl_label) :
    ((mn.1 : ℝ) + mn.2) ≤ (Casimir_SU3_explicit mn : ℝ) := by
  unfold Casimir_SU3_explicit
  have h : mn.1 + mn.2 ≤
      mn.1 ^ 2 + mn.2 ^ 2 + mn.1 * mn.2 + 3 * mn.1 + 3 * mn.2 := by
    have hm : 0 ≤ mn.1 ^ 2 := Nat.zero_le _
    have hn : 0 ≤ mn.2 ^ 2 := Nat.zero_le _
    have hmn : 0 ≤ mn.1 * mn.2 := Nat.zero_le _
    omega
  exact_mod_cast h

/-! ## Brick 2 — Weyl dim polynomial upper bound -/

/-- **Polynomial upper bound on the explicit SU(3) Weyl dimension.**
For every highest weight `(m, n) : ℕ × ℕ`,
`(Weyl_dim_SU3_explicit (m, n) : ℝ) ≤ ((m : ℝ) + 1)^2 · ((n : ℝ) + 1)^2`.

Proof: Prove the comparison entirely at the `ℕ` level via
`(m+1)(n+1)(m+n+2) ≤ 2 · (m+1)²(n+1)²` — which follows from
`(m+1)(n+1) = mn + m + n + 1 ≥ m + n + 1`, hence
`2(m+1)(n+1) ≥ m + n + 2` — then apply `Nat.div_le_of_le_mul` to
drop the `/2`, and cast once at the end. Keeping all arithmetic
at `ℕ` avoids the `((·/2 : ℕ) : ℝ)` cast trap (truncating
integer division is not generally cast-friendly).

Used in Brick 4 to dominate `dim²` by `((m+1)²(n+1)²)² = (m+1)⁴(n+1)⁴`. -/
theorem Weyl_dim_SU3_explicit_real_le_poly (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ≤
      ((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2 := by
  -- All comparison at the Nat level (Nat.div is not generally
  -- cast-friendly), then a single cast at the end.
  have key_nat :
      Weyl_dim_SU3_explicit mn ≤ (mn.1 + 1) ^ 2 * (mn.2 + 1) ^ 2 := by
    unfold Weyl_dim_SU3_explicit
    -- (m+1)(n+1) = mn + m + n + 1, so 2(m+1)(n+1) ≥ m + n + 2.
    have h1 : mn.1 + mn.2 + 2 ≤ 2 * ((mn.1 + 1) * (mn.2 + 1)) := by
      nlinarith [Nat.zero_le (mn.1 * mn.2)]
    have h2 :
        (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2)
          ≤ 2 * ((mn.1 + 1) ^ 2 * (mn.2 + 1) ^ 2) := by
      calc (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2)
          ≤ (mn.1 + 1) * (mn.2 + 1) * (2 * ((mn.1 + 1) * (mn.2 + 1))) :=
            Nat.mul_le_mul_left _ h1
        _ = 2 * ((mn.1 + 1) ^ 2 * (mn.2 + 1) ^ 2) := by ring
    exact Nat.div_le_of_le_mul (by linarith)
  -- Cast the Nat bound to ℝ.
  have hcast : ((Weyl_dim_SU3_explicit mn : ℕ) : ℝ) ≤
      (((mn.1 + 1) ^ 2 * (mn.2 + 1) ^ 2 : ℕ) : ℝ) := by exact_mod_cast key_nat
  have hpoly : (((mn.1 + 1) ^ 2 * (mn.2 + 1) ^ 2 : ℕ) : ℝ) =
      ((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2 := by push_cast; ring
  linarith

/-! ## Brick 3 — 1D summability of `(n+1)^4 · exp(-β n)` -/

/-- **Polynomial × geometric summability (real, ℕ-shifted form).**
For every `β > 0`,
`Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 4 · Real.exp (-(β · n)))`.

Proof: Bound `((n : ℝ) + 1)^4 ≤ ((n : ℝ) + 1)^4` and apply
`Real.summable_pow_mul_exp_neg_nat_mul` with `k = 4`. The shift
`(n+1)^4` is replaced by `Σ_{i ≤ 4} C(4,i) · n^i` via the binomial
expansion, each summand summable by the same mathlib lemma at
`k = i`. We package this directly via `Summable.congr` after
unfolding `(n+1)^4` and `Summable.add`/`Summable.mul_left` to combine.

Used in Brick 4 as the per-factor 1D envelope. -/
theorem summable_poly_succ_exp_neg_real {β : ℝ} (hβ : 0 < β) :
    Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 4 * Real.exp (-(β * n))) := by
  -- Expand (n+1)^4 = n^4 + 4n^3 + 6n^2 + 4n + 1, then each
  -- summand is summable by mathlib's `summable_pow_mul_exp_neg_nat_mul`
  -- (or, for the constant term, `summable_exp_neg_nat` after scaling).
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
        (n : ℝ) ^ 4 * Real.exp (-β * n)
          + 4 * ((n : ℝ) ^ 3 * Real.exp (-β * n))
          + 6 * ((n : ℝ) ^ 2 * Real.exp (-β * n))
          + 4 * ((n : ℝ) ^ 1 * Real.exp (-β * n))
          + 1 * ((n : ℝ) ^ 0 * Real.exp (-β * n))) := by
    exact ((((h4.add (h3.mul_left 4)).add (h2.mul_left 6)).add
      (h1.mul_left 4)).add (h0.mul_left 1))
  refine hcombined.congr (fun n => ?_)
  have hexp : Real.exp (-(β * (n : ℝ))) = Real.exp (-β * (n : ℝ)) := by
    congr 1; ring
  rw [hexp]
  ring

/-! ## Brick 4 — Headline: Peter-Weyl Summability for SU(3) -/

/-- **Peter-Weyl Summability for the SU(3) heat kernel at the identity.**
For every `β > 0`, the spectral series
`∑_{(m,n) : ℕ × ℕ} (Weyl_dim_SU3_explicit (m,n))² · exp(-(β · Casimir_SU3_explicit (m,n)))`
is `Summable` on `ℕ × ℕ`.

This is the analytic input the Peter-Weyl spectral decomposition
of the SU(3) heat kernel needs to even *make sense* as an infinite
sum. The genuine `K_t(1) = ∑'_λ dim(λ)² · exp(-t · C₂(λ))` identity,
plus the small-`t` Varadhan / Molchanov asymptotic
`K_t(1) ~ C · exp(-c/t) / t^4`, are still classical analysis on
compact Lie groups and live downstream in Batch 19.1p-redux-b
(Task #155). YM tower stays `Status: Open`.

Proof: squeeze. The summand is bounded above by
`((m+1)^4 · exp(-β m)) · ((n+1)^4 · exp(-β n))` via Bricks 1 + 2.
The envelope `Summable` follows from `summable_prod_of_nonneg.mpr`
on top of Brick 3 (1D summability), and the squeeze closes by
`Summable.of_nonneg_of_le`. -/
theorem PeterWeyl_Summable_SU3 {β : ℝ} (hβ : 0 < β) :
    Summable (fun mn : ℕ × ℕ =>
      ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ)))) := by
  -- Per-factor 1D envelope (Brick 3).
  have h1d : Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 4 * Real.exp (-(β * n))) :=
    summable_poly_succ_exp_neg_real hβ
  -- The product envelope is summable on ℕ × ℕ via summable_prod_of_nonneg.
  set f : ℕ → ℝ := fun n => ((n : ℝ) + 1) ^ 4 * Real.exp (-(β * n)) with hf_def
  have hf_nonneg : ∀ n, 0 ≤ f n := by
    intro n
    exact mul_nonneg (pow_nonneg (by positivity) _) (Real.exp_pos _).le
  set env : ℕ × ℕ → ℝ := fun mn => f mn.1 * f mn.2 with henv_def
  have henv_nonneg : (0 : ℕ × ℕ → ℝ) ≤ env := fun mn => mul_nonneg (hf_nonneg _) (hf_nonneg _)
  have henv_summable : Summable env := by
    rw [summable_prod_of_nonneg henv_nonneg]
    refine ⟨fun x => ?_, ?_⟩
    · -- For fixed x, ∑_y f x * f y = f x · (∑ f).
      exact h1d.mul_left (f x)
    · -- ∑_x (f x · (∑' y, f y)) = (∑' y, f y) · ∑_x f x.
      have : (fun x : ℕ => ∑' y, env (x, y)) =
          fun x : ℕ => f x * ∑' y, f y := by
        funext x
        simp only [henv_def]
        exact tsum_mul_left
      rw [this]
      exact h1d.mul_right _
  -- Pointwise bound: summand ≤ env.
  have hbound : ∀ mn : ℕ × ℕ,
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤ env mn := by
    intro mn
    have hdim_nonneg : (0 : ℝ) ≤ (Weyl_dim_SU3_explicit mn : ℝ) :=
      Nat.cast_nonneg _
    -- Bound the dim²:
    have hdim_sq :
        (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 := by
      exact pow_le_pow_left hdim_nonneg (Weyl_dim_SU3_explicit_real_le_poly mn) 2
    -- Bound the exp by exp(-β(m+n)) = exp(-βm)·exp(-βn):
    have hcas := Casimir_SU3_explicit_real_ge_linear mn
    have hexp_bound :
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          Real.exp (-(β * ((mn.1 : ℝ) + mn.2))) := by
      apply Real.exp_le_exp.mpr
      have hβmul := mul_le_mul_of_nonneg_left hcas hβ.le
      linarith
    have hexp_split :
        Real.exp (-(β * ((mn.1 : ℝ) + mn.2))) =
          Real.exp (-(β * mn.1)) * Real.exp (-(β * mn.2)) := by
      rw [← Real.exp_add]; congr 1; ring
    have hexp_nonneg : (0 : ℝ) ≤ Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) :=
      (Real.exp_pos _).le
    -- Combine: dim² · exp ≤ poly⁴ · exp(-βm)·exp(-βn) = f(m)·f(n).
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
            Real.exp (-(β * ((mn.1 : ℝ) + mn.2))) := by
      apply mul_le_mul_of_nonneg_left hexp_bound
      exact sq_nonneg _
    have hstep3 :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * ((mn.1 : ℝ) + mn.2))) = env mn := by
      simp only [henv_def, hf_def, hpoly_sq_eq, hexp_split]
      ring
    linarith [hstep1.trans (hstep2.trans hstep3.le)]
  -- Squeeze.
  have hsum_nonneg : ∀ mn : ℕ × ℕ, 0 ≤
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) := fun mn =>
    mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  exact Summable.of_nonneg_of_le hsum_nonneg hbound henv_summable

end PeterWeyl
end YM
end Towers
end TheoremaAureum
