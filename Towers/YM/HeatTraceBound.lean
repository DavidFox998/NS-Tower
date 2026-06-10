/-
================================================================
Towers / YM / HeatTraceBound  (Task #156 — file 3a of 6,
antidiagonal envelope)

ANTIDIAGONAL ENVELOPE ONLY. Single brick:

  heat_trace_envelope : ∀ t > 0,
    K t ≤ ∑' k : ℕ, ((k : ℝ) + 1) * (8 * ((k : ℝ) + 1) ^ 3) ^ 2
                     * Real.exp (-(3/4) * t * (k : ℝ) ^ 2)

where K(t) := ∑' (m n : ℕ),
  (dim_SU3 m n : ℝ)² · Real.exp (-t · Casimir_SU3_explicit (m, n))
is the iterated Peter–Weyl spectral sum for the SU(3) heat kernel
at the identity. (The genuine identity
`K_t(1) = ∑_λ dim(λ)² · exp(-t · C₂(λ))` is classical analysis on
compact Lie groups; this is its formal stand-in.)

Inputs used (from sibling bricks):
  • `Towers.YM.WeylDim.dim_cubic_bound`
      `dim_SU3 m n ≤ 8 · (m + n + 1) ³`
  • `Towers.YM.Casimir.Casimir_SU3_explicit_real_ge_quadratic`
      `¾ · (m + n)² + 3 · (m + n) ≤ C₂(m, n)`
  • `Towers.YM.PeterWeyl.PeterWeyl_Summable_SU3` (β := t)
      summability of the LHS summand on ℕ × ℕ

Honest scope (locked).
  - NOT the Weyl-law headline `K(t) ≤ C · t^{-4}`. That closure
    needs the Gaussian moment integral `∫₀^∞ x⁷ · exp(-a · x²) dx
       = 3 / a⁴` (gamma-function change-of-variables), which mathlib
    v4.12.0 does not ship as a one-liner. That is the future file 3b.
  - Does NOT discharge Varadhan, the per-plaquette activity bound,
    KP, the cluster expansion, the area law, or any mass-gap statement.
  - YM tower stays Status: Open (docs/ROADMAP.md § 2).
  - Surface #2 stays OPEN; `kotecky_preiss_criterion` remains a
    `sorry` in `Towers/Attempts/ClusterExpansion.lean`.
  - mathlib v4.12.0 only. Axiom footprint = classical trio
    `{propext, Classical.choice, Quot.sound}`.
  - No sorry, no admit, no axiom, no unsafe, no implemented_by.

Proof outline.
  Bridge.   `dim_SU3 m n = Weyl_dim_SU3_explicit (m, n)`            [rfl]
  Step 2.   LHS summand `Summable` on ℕ × ℕ                         [PeterWeyl + congr]
  Step 3.   Pointwise bound `summand (m,n) ≤ G (m,n)` where
              `G (m,n) := (8(m+n+1)³)² · exp(-(3/4)·t·(m+n)²)`
              via squaring `dim_cubic_bound` and exp-monotonicity
              on `Casimir_SU3_explicit_real_ge_quadratic`.            [pow_le_pow_left + exp_le_exp]
  Step 4.   Single-index envelope `Summable (k ↦ (k+1) · F t k)`
              where `F t k := (8(k+1)³)² · exp(-(3/4)·t·k²)`,
              via `k² ≥ k` (k ∈ ℕ) ⇒ poly × Gaussian ≤ poly × geometric.
  Step 5.   `Summable G` on ℕ × ℕ via
              `sigmaAntidiagonalEquivProd.summable_iff` + sigma split
              (each antidiagonal is finite, the n-th has card (n+1)).
  Step 6.   K t = ∑' p : ℕ × ℕ, summand p                            [tsum_prod' reverse]
  Step 7.   ∑' p, G p = ∑' k, (k+1) · F t k                          [sigmaAntidiagonalEquivProd.tsum_eq + tsum_sigma' + Finset.sum_const + card_antidiagonal]
  Headline. Combine 2,3,4,5,6,7 via `tsum_le_tsum`.
================================================================
-/

import Towers.YM.Casimir
import Towers.YM.WeylDim
import Towers.YM.PeterWeylHeat
import Mathlib.Topology.Algebra.InfiniteSum.Ring
import Mathlib.Algebra.Order.Antidiag.Prod
import Mathlib.Data.Finset.NatAntidiagonal
import Mathlib.MeasureTheory.Integral.Gamma

namespace TheoremaAureum.Towers.YM.HeatTraceBound

open TheoremaAureum.Towers.YM.ClusterExpansion
  (Weyl_dim_SU3_explicit Casimir_SU3_explicit Casimir_SU3_explicit_nonneg)
open TheoremaAureum.Towers.YM.PeterWeyl (PeterWeyl_Summable_SU3)
open TheoremaAureum.Towers.YM.Casimir (Casimir_SU3_explicit_real_ge_quadratic)
open TheoremaAureum.Towers.YM.WeylDim (dim_SU3 dim_cubic_bound)
open TheoremaAureum.Towers.YM.PeterWeylHeat (Heat_kernel_envelope_real)
open Finset

/-! ### Definition of `K (t)` -/

/-- **Heat-trace placeholder `K (t)`** — iterated Peter–Weyl spectral
sum for the SU(3) heat kernel at the identity. Definitional only. -/
noncomputable def K (t : ℝ) : ℝ :=
  ∑' (m : ℕ) (n : ℕ),
    ((dim_SU3 m n : ℝ)) ^ 2 *
      Real.exp (-t * (Casimir_SU3_explicit (m, n) : ℝ))

/-! ### Helpers — summand, envelope `F`, antidiagonal envelope `G` -/

/-- The LHS summand as a function of a pair. -/
private noncomputable def summand (t : ℝ) (mn : ℕ × ℕ) : ℝ :=
  ((dim_SU3 mn.1 mn.2 : ℝ)) ^ 2 *
    Real.exp (-t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ))

private lemma summand_nonneg (t : ℝ) (mn : ℕ × ℕ) : 0 ≤ summand t mn :=
  mul_nonneg (sq_nonneg _) (Real.exp_pos _).le

/-- Per-antidiagonal envelope value at antidiagonal `k`:
  `F t k := (8 · (k+1)³)² · exp(-(3/4) · t · k²)`. -/
private noncomputable def F (t : ℝ) (k : ℕ) : ℝ :=
  (8 * ((k : ℝ) + 1) ^ 3) ^ 2 * Real.exp (-(3/4) * t * (k : ℝ) ^ 2)

private lemma F_nonneg (t : ℝ) (k : ℕ) : 0 ≤ F t k :=
  mul_nonneg (sq_nonneg _) (Real.exp_pos _).le

/-- Antidiagonal envelope on `ℕ × ℕ`: depends only on `m + n`. -/
private noncomputable def G (t : ℝ) (mn : ℕ × ℕ) : ℝ :=
  F t (mn.1 + mn.2)

private lemma G_nonneg (t : ℝ) (mn : ℕ × ℕ) : 0 ≤ G t mn := F_nonneg _ _

/-! ### Step 2 — LHS summand is Summable on `ℕ × ℕ` -/

private lemma summable_summand (t : ℝ) (ht : 0 < t) :
    Summable (summand t) := by
  have hpw := PeterWeyl_Summable_SU3 (β := t) ht
  refine hpw.congr (fun mn => ?_)
  -- PeterWeyl summand is
  --   (Weyl_dim_SU3_explicit mn : ℝ)^2 * Real.exp (-(t * (C₂ mn : ℝ)))
  -- Our `summand t mn` is
  --   (dim_SU3 mn.1 mn.2 : ℝ)^2 * Real.exp (-t * (C₂ (mn.1, mn.2) : ℝ))
  -- `(mn.1, mn.2) = mn` by Prod.eta; `dim_SU3 m n = Weyl_dim_SU3_explicit (m,n)` by rfl.
  show (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) = summand t mn
  unfold summand
  have hprod : (mn.1, mn.2) = mn := rfl
  rw [hprod]
  congr 1
  ring

/-! ### Step 3 — pointwise bound: `summand (m, n) ≤ G (m, n)` -/

private lemma summand_le_G (t : ℝ) (ht : 0 < t) (mn : ℕ × ℕ) :
    summand t mn ≤ G t mn := by
  -- dim_SU3 ≤ 8 · (m+n+1)³  ⇒  (dim_SU3)² ≤ (8 · (m+n+1)³)²
  -- 0 < t, ¾(m+n)² + 3(m+n) ≤ C₂  ⇒  exp(-t · C₂) ≤ exp(-(3/4) · t · (m+n)²)
  unfold summand G F
  have hdim_nonneg : (0 : ℝ) ≤ (dim_SU3 mn.1 mn.2 : ℝ) := Nat.cast_nonneg _
  have hdim_le : (dim_SU3 mn.1 mn.2 : ℝ) ≤ 8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3 := by
    have h := dim_cubic_bound mn.1 mn.2
    have hcast : (dim_SU3 mn.1 mn.2 : ℝ) ≤ (8 * (mn.1 + mn.2 + 1) ^ 3 : ℕ) := by
      exact_mod_cast h
    -- Now show the ℕ cast equals the ℝ expression.
    have hpush : ((8 * (mn.1 + mn.2 + 1) ^ 3 : ℕ) : ℝ)
                  = 8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3 := by push_cast; ring
    rw [hpush] at hcast
    exact hcast
  have hsq_le :
      (dim_SU3 mn.1 mn.2 : ℝ) ^ 2 ≤ (8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3) ^ 2 :=
    pow_le_pow_left hdim_nonneg hdim_le 2
  -- Real-valued quadratic Casimir bound (via the named brick on Weyl_label = (mn.1, mn.2)).
  have hcas := Casimir_SU3_explicit_real_ge_quadratic (mn.1, mn.2)
  -- hcas : (3/4) * ((mn.1 : ℝ) + mn.2)^2 + 3 * ((mn.1 : ℝ) + mn.2)
  --          ≤ (Casimir_SU3_explicit (mn.1, mn.2) : ℝ)
  have hexp_arg_le :
      -t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ)
        ≤ -(3/4) * t * ((mn.1 : ℝ) + mn.2) ^ 2 := by
    -- Equivalent to: (3/4) * t * (m+n)^2 ≤ t * Casimir.
    -- We have: (3/4)(m+n)^2 + 3(m+n) ≤ Casimir, so (3/4)(m+n)^2 ≤ Casimir
    -- (since 3(m+n) ≥ 0), and multiplying by t > 0 preserves.
    have _hmn_nonneg : (0 : ℝ) ≤ ((mn.1 : ℝ) + mn.2) := by positivity
    have hdrop : (3/4 : ℝ) * ((mn.1 : ℝ) + mn.2) ^ 2
                  ≤ (Casimir_SU3_explicit (mn.1, mn.2) : ℝ) := by
      have _h_extra : 0 ≤ 3 * ((mn.1 : ℝ) + mn.2) := by positivity
      linarith
    have hmul := mul_le_mul_of_nonneg_left hdrop ht.le
    linarith
  have hexp_le :
      Real.exp (-t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ))
        ≤ Real.exp (-(3/4) * t * ((mn.1 : ℝ) + mn.2) ^ 2) :=
    Real.exp_le_exp.mpr hexp_arg_le
  have hexp_nonneg :
      (0 : ℝ) ≤ Real.exp (-t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ)) :=
    (Real.exp_pos _).le
  have hpoly_sq_nonneg :
      (0 : ℝ) ≤ (8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3) ^ 2 := sq_nonneg _
  -- Show the antidiagonal F-shape with `(mn.1 + mn.2 : ℕ) : ℝ` equals
  -- `((mn.1 : ℝ) + mn.2)` etc. (push the cast).
  have _hk_cast : ((mn.1 + mn.2 : ℕ) : ℝ) = ((mn.1 : ℝ) + mn.2) := by push_cast; ring
  have _hk1_cast :
      ((mn.1 + mn.2 : ℕ) : ℝ) + 1 = ((mn.1 : ℝ) + mn.2 + 1) := by push_cast; ring
  -- Combine.
  calc
    (dim_SU3 mn.1 mn.2 : ℝ) ^ 2 *
          Real.exp (-t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ))
        ≤ (8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3) ^ 2 *
            Real.exp (-t * (Casimir_SU3_explicit (mn.1, mn.2) : ℝ)) :=
          mul_le_mul_of_nonneg_right hsq_le hexp_nonneg
    _ ≤ (8 * ((mn.1 : ℝ) + mn.2 + 1) ^ 3) ^ 2 *
            Real.exp (-(3/4) * t * ((mn.1 : ℝ) + mn.2) ^ 2) :=
          mul_le_mul_of_nonneg_left hexp_le hpoly_sq_nonneg
    _ = (8 * (((mn.1 + mn.2 : ℕ) : ℝ) + 1) ^ 3) ^ 2 *
            Real.exp (-(3/4) * t * ((mn.1 + mn.2 : ℕ) : ℝ) ^ 2) := by
          push_cast
          ring

/-! ### Step 4 — Summable `(k ↦ (k + 1) · F t k)` -/

/-- The single-index envelope `∑'_k (k+1) · F t k` is `Summable`.
Reduces poly × Gaussian ≤ poly × geometric via `k² ≥ k` on ℕ. -/
private lemma summable_card_mul_F (t : ℝ) (ht : 0 < t) :
    Summable (fun k : ℕ => ((k : ℝ) + 1) * F t k) := by
  set β : ℝ := (3 / 4) * t with hβ_def
  have hβ : 0 < β := by positivity
  -- Envelope: 8192 · (k^7 · exp(-β·k)) + 8192 · (k^0 · exp(-β·k))
  --   coming from (k+1)·F t k = 64 · (k+1)^7 · exp(-β·k²)
  --              ≤ 64 · (128·k^7 + 128) · exp(-β·k)   [(k+1)^7 ≤ 128(k^7+1), k² ≥ k]
  --              = 8192·k^7·exp(-β·k) + 8192·exp(-β·k).
  have hsum7 : Summable (fun k : ℕ =>
      (8192 : ℝ) * ((k : ℝ) ^ 7 * Real.exp (-β * (k : ℝ)))) :=
    (Real.summable_pow_mul_exp_neg_nat_mul 7 hβ).mul_left _
  have hsum0 : Summable (fun k : ℕ =>
      (8192 : ℝ) * ((k : ℝ) ^ 0 * Real.exp (-β * (k : ℝ)))) :=
    (Real.summable_pow_mul_exp_neg_nat_mul 0 hβ).mul_left _
  have hsum_env :
      Summable (fun k : ℕ =>
        (8192 : ℝ) * ((k : ℝ) ^ 7 * Real.exp (-β * (k : ℝ)))
          + (8192 : ℝ) * ((k : ℝ) ^ 0 * Real.exp (-β * (k : ℝ)))) :=
    hsum7.add hsum0
  refine Summable.of_nonneg_of_le ?_ ?_ hsum_env
  · intro k
    exact mul_nonneg (by positivity) (F_nonneg _ _)
  · intro k
    -- Bound (k+1) · F t k by the envelope.
    have hk_sq : ((k : ℝ)) ≤ ((k : ℝ)) ^ 2 := by
      rcases Nat.eq_zero_or_pos k with hk | hk
      · subst hk; simp
      · have hk1 : (1 : ℝ) ≤ (k : ℝ) := by exact_mod_cast hk
        nlinarith
    have hβ_neg : -β ≤ 0 := neg_nonpos.mpr hβ.le
    have hexp_le :
        Real.exp (-(3 / 4) * t * (k : ℝ) ^ 2) ≤ Real.exp (-β * (k : ℝ)) := by
      apply Real.exp_le_exp.mpr
      have h1 : -β * ((k : ℝ)) ^ 2 ≤ -β * (k : ℝ) :=
        mul_le_mul_of_nonpos_left hk_sq hβ_neg
      have h2 : -(3 / 4) * t * (k : ℝ) ^ 2 = -β * ((k : ℝ)) ^ 2 := by
        rw [hβ_def]; ring
      linarith [h1, h2.le, h2.ge]
    have hexp_nonneg : (0 : ℝ) ≤ Real.exp (-(3 / 4) * t * (k : ℝ) ^ 2) :=
      (Real.exp_pos _).le
    have hexp_envelope_nonneg : (0 : ℝ) ≤ Real.exp (-β * (k : ℝ)) :=
      (Real.exp_pos _).le
    -- (k+1)^7 ≤ 128 · (k^7 + 1)
    have hpow_le : ((k : ℝ) + 1) ^ 7 ≤ 128 * ((k : ℝ) ^ 7 + 1) := by
      rcases Nat.eq_zero_or_pos k with hk | hk
      · subst hk; norm_num
      · have hk1 : (1 : ℝ) ≤ (k : ℝ) := by exact_mod_cast hk
        have _hk_pos : (0 : ℝ) < (k : ℝ) := by exact_mod_cast hk
        -- (k+1) ≤ 2k for k ≥ 1, so (k+1)^7 ≤ (2k)^7 = 128·k^7 ≤ 128(k^7+1).
        have h2k : ((k : ℝ) + 1) ≤ 2 * (k : ℝ) := by linarith
        have h2k_nn : (0 : ℝ) ≤ (k : ℝ) + 1 := by linarith
        have hpow7 : ((k : ℝ) + 1) ^ 7 ≤ (2 * (k : ℝ)) ^ 7 :=
          pow_le_pow_left h2k_nn h2k 7
        have h2_pow : (2 * (k : ℝ)) ^ 7 = 128 * (k : ℝ) ^ 7 := by ring
        have _hk7_nn : (0 : ℝ) ≤ (k : ℝ) ^ 7 := by positivity
        nlinarith [hpow7, h2_pow]
    have _hpow_nonneg : (0 : ℝ) ≤ ((k : ℝ) + 1) ^ 7 := by positivity
    -- Now (k+1) · F t k = 64 · (k+1)^7 · exp(-(3/4)t·k²)
    have h_eq_64 :
        ((k : ℝ) + 1) * F t k = 64 * ((k : ℝ) + 1) ^ 7
                                  * Real.exp (-(3 / 4) * t * (k : ℝ) ^ 2) := by
      unfold F; ring
    rw [h_eq_64]
    -- Bound poly part: 64 · (k+1)^7 ≤ 64 · 128 · (k^7 + 1) = 8192 · k^7 + 8192
    have hpoly_le :
        64 * ((k : ℝ) + 1) ^ 7 ≤ 8192 * (k : ℝ) ^ 7 + 8192 := by
      have := mul_le_mul_of_nonneg_left hpow_le (by norm_num : (0 : ℝ) ≤ 64)
      linarith
    have hpoly_nonneg : (0 : ℝ) ≤ 64 * ((k : ℝ) + 1) ^ 7 := by positivity
    -- Combine: poly * exp ≤ poly * exp_env ≤ (8192k^7 + 8192) * exp_env
    calc 64 * ((k : ℝ) + 1) ^ 7 * Real.exp (-(3 / 4) * t * (k : ℝ) ^ 2)
          ≤ 64 * ((k : ℝ) + 1) ^ 7 * Real.exp (-β * (k : ℝ)) :=
            mul_le_mul_of_nonneg_left hexp_le hpoly_nonneg
      _ ≤ (8192 * (k : ℝ) ^ 7 + 8192) * Real.exp (-β * (k : ℝ)) :=
            mul_le_mul_of_nonneg_right hpoly_le hexp_envelope_nonneg
      _ = 8192 * ((k : ℝ) ^ 7 * Real.exp (-β * (k : ℝ)))
            + 8192 * ((k : ℝ) ^ 0 * Real.exp (-β * (k : ℝ))) := by ring

/-! ### Step 5 — `Summable G` on ℕ × ℕ via the antidiagonal equiv -/

private lemma G_const_on_antidiag (t : ℝ) (k : ℕ) (ij : ℕ × ℕ)
    (hij : ij ∈ antidiagonal k) :
    G t ij = F t k := by
  unfold G
  congr 1
  exact (Finset.mem_antidiagonal.mp hij)

/-- The antidiagonal-sigma sum collapses (each antidiagonal is finite and
G is constant on it). -/
private lemma sum_antidiag_G (t : ℝ) (k : ℕ) :
    ∑ ij ∈ antidiagonal k, G t ij = ((k : ℝ) + 1) * F t k := by
  rw [Finset.sum_congr rfl (fun ij hij => G_const_on_antidiag t k ij hij)]
  rw [Finset.sum_const, Finset.Nat.card_antidiagonal]
  simp [Nat.cast_add, Nat.cast_one, mul_comm]

private lemma summable_G (t : ℝ) (ht : 0 < t) : Summable (G t) := by
  -- Strategy: via sigmaAntidiagonalEquivProd, Summable G ↔ Summable F_sigma
  -- where F_sigma s := G (sigmaAntidiagonalEquivProd s) — depends only on s.1.
  rw [← Finset.sigmaAntidiagonalEquivProd.summable_iff]
  -- Goal: Summable (fun s : Σ n, antidiagonal n => G t (equiv s)).
  -- Build via Summable.sigma_factor (each fibre finite) +
  -- Summable on n via summable_card_mul_F.
  -- We use `summable_sigma_of_nonneg`-style: it suffices to show
  --   (a) ∀ n, Summable (c ↦ G t (equiv ⟨n, c⟩))   [trivial: finite]
  --   (b) Summable (n ↦ ∑' c, G t (equiv ⟨n, c⟩))
  refine (summable_sigma_of_nonneg ?_).mpr ⟨?_, ?_⟩
  · intro s; exact G_nonneg _ _
  · intro n
    exact (hasSum_fintype (fun c : antidiagonal n =>
      G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩))).summable
  · -- Congr to (n ↦ (n+1) · F t n), then use summable_card_mul_F.
    have hcong : (fun n : ℕ => ∑' c : antidiagonal n,
                    G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩))
                  = fun n : ℕ => ((n : ℝ) + 1) * F t n := by
      funext n
      rw [tsum_fintype]
      -- Each c : antidiagonal n is a subtype element; sigmaAntidiagonalEquivProd
      -- extracts the underlying pair. So G t (equiv ⟨n, c⟩) = G t c.1.
      have heq_pt : ∀ c : antidiagonal n,
          G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩) = G t c.val :=
        fun _ => rfl
      have : (∑ c : antidiagonal n,
                G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩))
              = ∑ ij ∈ antidiagonal n, G t ij := by
        rw [Finset.sum_congr rfl (fun c _ => heq_pt c)]
        exact Finset.sum_attach (antidiagonal n) (G t)
      rw [this]
      exact sum_antidiag_G t n
    have h_summable_inner :
        Summable fun n : ℕ => ∑' c : antidiagonal n,
                                G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩) := by
      rw [hcong]
      exact summable_card_mul_F t ht
    -- The goal involves `G t ∘ ⇑equiv ⟨x, y⟩`, which is defeq to
    -- `G t (equiv ⟨x, y⟩)`.
    exact h_summable_inner

/-! ### Step 6 — `K t = ∑' p : ℕ × ℕ, summand t p` -/

private lemma K_eq_tsum_prod (t : ℝ) (ht : 0 < t) :
    K t = ∑' p : ℕ × ℕ, summand t p := by
  unfold K
  -- ∑' m, ∑' n, f m n = ∑' p, f p.1 p.2  via tsum_prod' (reverse direction).
  have h_summable := summable_summand t ht
  -- tsum_prod' :  ∑' p, f p = ∑' (b) (c), f (b, c)   under summability.
  -- Apply with f := summand t; need also `∀ b, Summable (c ↦ summand t (b, c))`.
  have h_factor : ∀ m : ℕ, Summable (fun n : ℕ => summand t (m, n)) :=
    fun m => h_summable.prod_factor m
  have h_tsum_prod : ∑' p : ℕ × ℕ, summand t p
                      = ∑' (m : ℕ) (n : ℕ), summand t (m, n) :=
    tsum_prod' h_summable h_factor
  -- Now identify the RHS of h_tsum_prod with the unfolded K t.
  -- summand t (m, n) = (dim_SU3 m n : ℝ)^2 * Real.exp (-t * (C₂ (m, n) : ℝ)).
  -- That's exactly the inner term of K.
  rw [h_tsum_prod]
  rfl

/-! ### Step 7 — `∑' p, G t p = ∑' k, (k+1) · F t k` -/

set_option maxHeartbeats 800000 in
private lemma tsum_G_eq (t : ℝ) (ht : 0 < t) :
    ∑' p : ℕ × ℕ, G t p = ∑' k : ℕ, ((k : ℝ) + 1) * F t k := by
  have h_G_summable := summable_G t ht
  -- via sigmaAntidiagonalEquivProd: ∑' p, G p = ∑' s : Σ n, antidiag n, G (equiv s).
  rw [← (Finset.sigmaAntidiagonalEquivProd.tsum_eq (G t))]
  -- Now split the sigma sum via tsum_sigma'.
  have h_sigma_summable :
      Summable (fun s : Σ n : ℕ, antidiagonal n =>
                  G t (Finset.sigmaAntidiagonalEquivProd s)) :=
    Finset.sigmaAntidiagonalEquivProd.summable_iff.mpr h_G_summable
  have h_inner_summable :
      ∀ n : ℕ, Summable (fun c : antidiagonal n =>
                  G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩)) :=
    fun n => (hasSum_fintype _).summable
  rw [tsum_sigma' h_inner_summable h_sigma_summable]
  -- Inner tsum is over a finite type → finite sum, then collapses.
  apply tsum_congr
  intro n
  rw [tsum_fintype]
  have heq_pt : ∀ c : antidiagonal n,
      G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩) = G t c.val :=
    fun _ => rfl
  have hattach : (∑ c : antidiagonal n,
                    G t (Finset.sigmaAntidiagonalEquivProd ⟨n, c⟩))
                  = ∑ ij ∈ antidiagonal n, G t ij := by
    rw [Finset.sum_congr rfl (fun c _ => heq_pt c)]
    exact Finset.sum_attach (antidiagonal n) (G t)
  rw [hattach]
  exact sum_antidiag_G t n

/-! ### Headline brick — antidiagonal envelope -/

/-- **Antidiagonal envelope for the SU(3) heat-trace placeholder.**
For every `t > 0`,
`K t ≤ ∑'_k (k+1) · (8(k+1)³)² · exp(-(3/4)·t·k²)`. -/
theorem heat_trace_envelope : ∀ t : ℝ, 0 < t →
    K t ≤ ∑' k : ℕ, ((k : ℝ) + 1) * (8 * ((k : ℝ) + 1) ^ 3) ^ 2
                      * Real.exp (-(3/4) * t * (k : ℝ) ^ 2) := by
  intro t ht
  have h_K := K_eq_tsum_prod t ht
  have h_summand_summable := summable_summand t ht
  have h_G_summable := summable_G t ht
  have h_pointwise : ∀ p : ℕ × ℕ, summand t p ≤ G t p := fun p => summand_le_G t ht p
  have h_tsum_le :
      ∑' p : ℕ × ℕ, summand t p ≤ ∑' p : ℕ × ℕ, G t p :=
    tsum_le_tsum h_pointwise h_summand_summable h_G_summable
  have h_G_collapse : ∑' p : ℕ × ℕ, G t p = ∑' k : ℕ, ((k : ℝ) + 1) * F t k :=
    tsum_G_eq t ht
  -- Combine: K t = ∑' p, summand ≤ ∑' p, G = ∑' k, (k+1)·F t k.
  rw [h_K]
  calc ∑' p : ℕ × ℕ, summand t p ≤ ∑' p : ℕ × ℕ, G t p := h_tsum_le
    _ = ∑' k : ℕ, ((k : ℝ) + 1) * F t k := h_G_collapse
    _ = ∑' k : ℕ, ((k : ℝ) + 1) * (8 * ((k : ℝ) + 1) ^ 3) ^ 2
                    * Real.exp (-(3/4) * t * (k : ℝ) ^ 2) := by
        apply tsum_congr
        intro k
        unfold F
        ring

/-! ### Batch 156.3b — Gaussian moment and polynomial heat-trace bound -/

/-- **Gaussian seventh moment.**  `∫₀^∞ x^7 · exp(-a · x²) dx = 3/a^4`
for every `a > 0`. Direct application of mathlib's
`integral_rpow_mul_exp_neg_mul_rpow` with `p = 2, q = 7`, evaluating
`Γ(4) = 6` via iterated `Real.Gamma_add_one`. -/
lemma gaussian_moment_7 (a : ℝ) (ha : 0 < a) :
    ∫ x in Set.Ioi (0:ℝ), x^7 * Real.exp (-a * x^2) = 3 / a^4 := by
  -- Rewrite nat-powers on x as rpows (valid since x > 0).
  have h_eq : Set.EqOn (fun x : ℝ => x^7 * Real.exp (-a * x^2))
                       (fun x : ℝ => x^(7:ℝ) * Real.exp (-a * x^(2:ℝ)))
                       (Set.Ioi (0:ℝ)) := by
    intro x _
    have h7 : (x : ℝ)^(7:ℝ) = x^(7:ℕ) := by
      have hcast : ((7:ℕ):ℝ) = (7:ℝ) := by norm_num
      rw [← hcast, Real.rpow_natCast]
    have h2 : (x : ℝ)^(2:ℝ) = x^(2:ℕ) := by
      have hcast : ((2:ℕ):ℝ) = (2:ℝ) := by norm_num
      rw [← hcast, Real.rpow_natCast]
    simp only [h7, h2]
  rw [MeasureTheory.setIntegral_congr measurableSet_Ioi h_eq]
  rw [integral_rpow_mul_exp_neg_mul_rpow (by norm_num : (0:ℝ) < 2)
        (by norm_num : (-1:ℝ) < 7) ha]
  -- Now: a^(-(7+1)/2) * (1/2) * Γ((7+1)/2) = a^(-4) * (1/2) * Γ(4).
  have hexp_arg : (-(7 + 1) / 2 : ℝ) = -4 := by norm_num
  have hΓ_arg : ((7 + 1) / 2 : ℝ) = 4 := by norm_num
  rw [hexp_arg, hΓ_arg]
  -- Γ(4) = 6.
  have hΓ4 : Real.Gamma 4 = 6 := by
    have e1 : (4 : ℝ) = 3 + 1 := by norm_num
    rw [e1, Real.Gamma_add_one (by norm_num : (3:ℝ) ≠ 0)]
    have e2 : (3 : ℝ) = 2 + 1 := by norm_num
    rw [e2, Real.Gamma_add_one (by norm_num : (2:ℝ) ≠ 0)]
    have e3 : (2 : ℝ) = 1 + 1 := by norm_num
    rw [e3, Real.Gamma_add_one (by norm_num : (1:ℝ) ≠ 0), Real.Gamma_one]
    ring
  rw [hΓ4]
  -- a^(-4 : ℝ) = (a^4)⁻¹.
  have ha4 : a^(-4 : ℝ) = (a^(4:ℕ))⁻¹ := by
    have hcast : ((4:ℕ):ℝ) = (4:ℝ) := by norm_num
    rw [show (-4:ℝ) = -((4:ℕ):ℝ) from by rw [hcast],
        Real.rpow_neg ha.le, Real.rpow_natCast]
  rw [ha4]
  have ha4_ne : a^(4:ℕ) ≠ 0 := pow_ne_zero _ ha.ne'
  field_simp
  ring

/-! ### Batch 156.3c — polynomial heat-trace bound `K t ≤ C · t^{-4}` -/

set_option maxHeartbeats 1600000 in
/-- **Polynomial heat-trace bound.**  There exists a constant `C > 0` such that
for every `t ∈ (0, 1]`, `K t ≤ C · t^{-4}`.

The proof uses the antidiagonal envelope `heat_trace_envelope`, then splits the
resulting sum at `N := ⌊1/√t⌋ + 2`: the head (`k < N`) is bounded by
`64 · N^8 ≤ 64 · 6561 · t^{-4}` using `exp ≤ 1`, and the tail uses
`y^5 · exp(-y) ≤ 120` (from `Real.pow_div_factorial_le_exp` at `n = 5`) with
`y = (3/4) · t · k²`, then a telescoping bound on `∑ 1/(k+N)²`. -/
theorem heat_trace_poly_bound :
    ∃ C : ℝ, 0 < C ∧ ∀ t ∈ Set.Ioc (0:ℝ) 1, K t ≤ C * t^(-4 : ℝ) := by
  -- Corollary of `pow_div_factorial_le_exp` at `n = 5`.
  have y5_bound : ∀ y : ℝ, 0 ≤ y → y ^ 5 * Real.exp (-y) ≤ 120 := by
    intro y hy
    have h := Real.pow_div_factorial_le_exp y hy 5
    -- h : y ^ 5 / ↑(5).factorial ≤ Real.exp y
    have h120 : (0:ℝ) < 120 := by norm_num
    have hfact : ((5 : ℕ).factorial : ℝ) = 120 := by
      norm_num [Nat.factorial]
    have h' : y ^ 5 / 120 ≤ Real.exp y := by
      have := h; rw [hfact] at this; exact this
    have hy5_le : y ^ 5 ≤ 120 * Real.exp y := by
      have := (div_le_iff h120).mp h'
      linarith
    have hexp_neg_pos : (0:ℝ) < Real.exp (-y) := Real.exp_pos _
    have heq : Real.exp y * Real.exp (-y) = 1 := by
      rw [← Real.exp_add, add_neg_cancel, Real.exp_zero]
    calc y ^ 5 * Real.exp (-y)
        ≤ (120 * Real.exp y) * Real.exp (-y) :=
          mul_le_mul_of_nonneg_right hy5_le hexp_neg_pos.le
      _ = 120 * (Real.exp y * Real.exp (-y)) := by ring
      _ = 120 := by rw [heq, mul_one]
  -- Constants.
  set Chead : ℝ := 64 * 6561 with hChead_def
  set Ctail : ℝ := 64 * 128 * 120 * (4/3) ^ 5 with hCtail_def
  refine ⟨Chead + Ctail, by unfold_let Chead Ctail; positivity, ?_⟩
  rintro t ⟨ht_pos, ht_le_one⟩
  -- Square root and t-related arithmetic.
  set st := Real.sqrt t with hst_def
  have hst_pos : 0 < st := Real.sqrt_pos.mpr ht_pos
  have hst_sq : st * st = t := Real.mul_self_sqrt ht_pos.le
  have hst_le_one : st ≤ 1 := by
    rw [hst_def, show (1:ℝ) = Real.sqrt 1 from Real.sqrt_one.symm]
    exact Real.sqrt_le_sqrt ht_le_one
  have h_one_le_inv_st : 1 ≤ 1 / st := by rw [le_div_iff hst_pos]; linarith
  have hinv_st_pos : 0 < 1 / st := by positivity
  -- M := ⌊1/√t⌋, N := M + 2.
  set M : ℕ := Nat.floor (1 / st) with hM_def
  set N : ℕ := M + 2 with hN_def
  have hN_ge_two : 2 ≤ N := by unfold_let N; omega
  have hN_pos : 0 < N := by omega
  have hN_real_pos : (0:ℝ) < (N:ℝ) := by exact_mod_cast hN_pos
  -- (M+1 : ℝ) ≥ 1/st.
  have hMp1_ge_inv : (1 / st : ℝ) ≤ ((M + 1 : ℕ) : ℝ) := by
    have hlt : (1 / st : ℝ) < (Nat.floor (1 / st) : ℝ) + 1 := Nat.lt_floor_add_one _
    push_cast
    linarith
  have hMp1_pos_real : (0:ℝ) < ((M + 1 : ℕ) : ℝ) := by
    exact_mod_cast Nat.succ_pos M
  -- (M+1)^2 ≥ 1/t.
  have h_eq_inv_t : (1 / st) * (1 / st) = 1 / t := by
    rw [div_mul_div_comm, one_mul, hst_sq]
  have h_Mp1_sq_ge : (1 / t : ℝ) ≤ ((M + 1 : ℕ) : ℝ) ^ 2 := by
    have hsq_mono := mul_self_le_mul_self hinv_st_pos.le hMp1_ge_inv
    have hsq : ((M + 1 : ℕ) : ℝ) ^ 2 = ((M + 1 : ℕ) : ℝ) * ((M + 1 : ℕ) : ℝ) := sq _
    rw [hsq]; linarith
  -- t * (M+1)^2 ≥ 1.
  have h_t_Mp1_sq_ge : 1 ≤ t * ((M + 1 : ℕ) : ℝ) ^ 2 := by
    have := (div_le_iff ht_pos).mp h_Mp1_sq_ge
    linarith
  -- N ≤ 1/st + 2.
  have hN_le_inv_plus_two : (N : ℝ) ≤ 1 / st + 2 := by
    have hMub : ((M : ℕ) : ℝ) ≤ 1 / st := Nat.floor_le hinv_st_pos.le
    have hNeq : ((N : ℕ) : ℝ) = (M : ℝ) + 2 := by unfold_let N; push_cast; ring
    rw [hNeq]; linarith
  -- N ≤ 3/st.
  have hN_le_3 : (N : ℝ) ≤ 3 / st := by
    have h_two_le : (2 : ℝ) ≤ 2 / st := by
      rw [le_div_iff hst_pos]; linarith
    have : (1 : ℝ) / st + 2 ≤ 3 / st := by
      have e : (3 : ℝ) / st = 1 / st + 2 / st := by ring
      linarith
    linarith
  -- N^8 ≤ 6561 / t^4.
  have hst_ne : st ≠ 0 := ne_of_gt hst_pos
  have h_st8_pos : 0 < st ^ 8 := pow_pos hst_pos 8
  have h_t4_pos : 0 < t ^ 4 := pow_pos ht_pos 4
  have h_st8_eq_t4 : st ^ 8 = t ^ 4 := by
    have : st ^ 8 = (st * st) ^ 4 := by ring
    rw [this, hst_sq]
  have h_N_nonneg : (0 : ℝ) ≤ (N : ℝ) := hN_real_pos.le
  have h_3invst_nonneg : (0 : ℝ) ≤ 3 / st := by positivity
  have hN8_le : (N : ℝ) ^ 8 ≤ 6561 / t ^ 4 := by
    have hpow : ((N : ℝ)) ^ 8 ≤ (3 / st) ^ 8 :=
      pow_le_pow_left h_N_nonneg hN_le_3 8
    have hrhs : (3 / st) ^ 8 = 6561 / t ^ 4 := by
      rw [div_pow, h_st8_eq_t4]
      norm_num
    linarith
  -- Define g(k) := 64 · (k+1)^7 · exp(-(3/4)·t·k²).
  set g : ℕ → ℝ := fun k =>
    64 * ((k : ℝ) + 1) ^ 7 * Real.exp (-(3/4) * t * (k : ℝ) ^ 2) with hg_def
  have hg_nonneg : ∀ k, 0 ≤ g k := by
    intro k
    refine mul_nonneg (mul_nonneg (by norm_num) ?_) (Real.exp_pos _).le
    positivity
  -- The envelope sum equals ∑'_k g k.
  have h_env := heat_trace_envelope t ht_pos
  have h_env_eq :
      (∑' k : ℕ, ((k : ℝ) + 1) * (8 * ((k : ℝ) + 1) ^ 3) ^ 2 *
          Real.exp (-(3 / 4) * t * (k : ℝ) ^ 2))
        = ∑' k : ℕ, g k := by
    apply tsum_congr; intro k; unfold_let g; ring
  rw [h_env_eq] at h_env
  -- Per-term tail bound: g (k + N) ≤ Ctail · (1/t)^5 · 1/((k+N : ℝ))^3.
  -- Let m := (k+N : ℕ) so (m : ℝ) ≥ 2 ≥ 1.
  have h_tail_term : ∀ k : ℕ,
      g (k + N) ≤ Ctail * (1 / t) ^ 5 * (1 / ((k + N : ℕ) : ℝ) ^ 3) := by
    intro k
    set m : ℕ := k + N with hm_def
    have hm_ge_two_nat : 2 ≤ m := by unfold_let m; omega
    have hm_ge_one_real : (1 : ℝ) ≤ (m : ℝ) := by
      have : (1 : ℕ) ≤ m := by omega
      exact_mod_cast this
    have hm_pos_real : (0 : ℝ) < (m : ℝ) := by linarith
    have hm_ne : (m : ℝ) ≠ 0 := ne_of_gt hm_pos_real
    -- y = (3/4)·t·m².
    set y : ℝ := (3/4) * t * (m : ℝ) ^ 2 with hy_def
    have hy_pos : 0 < y := by
      unfold_let y
      have : (0:ℝ) < (3/4 : ℝ) * t := by positivity
      have h2 : (0:ℝ) < (m : ℝ) ^ 2 := pow_pos hm_pos_real 2
      positivity
    have hy_nonneg : 0 ≤ y := hy_pos.le
    -- y^5 · exp(-y) ≤ 120, so exp(-y) ≤ 120/y^5.
    have h_y5 := y5_bound y hy_nonneg
    have hy5_pos : 0 < y ^ 5 := pow_pos hy_pos 5
    have h_exp_le : Real.exp (-y) ≤ 120 / y ^ 5 := by
      rw [le_div_iff hy5_pos]; linarith
    -- (m+1 : ℝ) ≤ 2·m  (since m ≥ 1).
    have h_succ_le : (m : ℝ) + 1 ≤ 2 * (m : ℝ) := by linarith
    have h_succ_nn : 0 ≤ (m : ℝ) + 1 := by linarith
    have h_succ_pow : ((m : ℝ) + 1) ^ 7 ≤ (2 * (m : ℝ)) ^ 7 :=
      pow_le_pow_left h_succ_nn h_succ_le 7
    -- exp arg: g (k+N) uses ((k+N:ℕ):ℝ) which equals (m:ℝ).
    have h_mreal : ((k + N : ℕ) : ℝ) = (m : ℝ) := by unfold_let m; rfl
    -- Unfold g (k+N).
    have h_gval :
        g (k + N) = 64 * ((m : ℝ) + 1) ^ 7 * Real.exp (-(3/4) * t * (m : ℝ) ^ 2) := by
      unfold_let g; rw [h_mreal]
    rw [h_gval]
    -- exp(-(3/4)·t·m²) = exp(-y).
    have h_exp_arg : -(3/4) * t * (m : ℝ) ^ 2 = -y := by unfold_let y; ring
    rw [h_exp_arg]
    -- 64 · (m+1)^7 ≥ 0; exp(-y) ≥ 0.
    have h64sev_nn : 0 ≤ 64 * ((m : ℝ) + 1) ^ 7 := by positivity
    have hexp_neg_nn : 0 ≤ Real.exp (-y) := (Real.exp_pos _).le
    have h_step1 :
        64 * ((m : ℝ) + 1) ^ 7 * Real.exp (-y)
          ≤ 64 * ((m : ℝ) + 1) ^ 7 * (120 / y ^ 5) :=
      mul_le_mul_of_nonneg_left h_exp_le h64sev_nn
    have h_step2 :
        64 * ((m : ℝ) + 1) ^ 7 * (120 / y ^ 5)
          ≤ 64 * (2 * (m : ℝ)) ^ 7 * (120 / y ^ 5) := by
      have h_div_nn : 0 ≤ 120 / y ^ 5 := by positivity
      have h64_nn : (0 : ℝ) ≤ 64 := by norm_num
      have h_step :
          64 * ((m : ℝ) + 1) ^ 7 ≤ 64 * (2 * (m : ℝ)) ^ 7 :=
        mul_le_mul_of_nonneg_left h_succ_pow h64_nn
      exact mul_le_mul_of_nonneg_right h_step h_div_nn
    -- Simplify RHS of step2 to Ctail · (1/t)^5 · 1/m^3.
    have h_eq_final :
        64 * (2 * (m : ℝ)) ^ 7 * (120 / y ^ 5)
          = Ctail * (1 / t) ^ 5 * (1 / (m : ℝ) ^ 3) := by
      unfold_let Ctail y
      have ht_ne : t ≠ 0 := ne_of_gt ht_pos
      have hm5 : (m : ℝ) ^ 10 = (m : ℝ) ^ 7 * (m : ℝ) ^ 3 := by ring
      field_simp
      ring
    rw [h_mreal]
    linarith [h_step1, h_step2, h_eq_final.le, h_eq_final.ge]
  -- Summability of 1/((k+N:ℕ):ℝ)^3 via comparing with summable 1/(k+1)^3
  -- (using `Real.summable_one_div_nat_add_rpow` with s=3 and shift).
  -- We use a simpler route: show partial sum bound directly via telescoping
  -- for 1/(k+N)^2, then prove summability of the dominating series.
  -- ----- Summability of the bound function -----
  have h_sum_inv_sq_partial :
      ∀ K : ℕ, (∑ k ∈ range K, 1 / (((k + N : ℕ) : ℝ)) ^ 2)
                ≤ 1 / ((M + 1 : ℕ) : ℝ) := by
    intro K
    -- 1/(k+N)^2 ≤ 1/(k+N-1) - 1/(k+N) for k+N ≥ 2.
    have h_telescope_term : ∀ k : ℕ,
        (1 : ℝ) / ((k + N : ℕ) : ℝ) ^ 2
          ≤ 1 / ((k + M + 1 : ℕ) : ℝ) - 1 / ((k + N : ℕ) : ℝ) := by
      intro k
      have hkN_pos : (0 : ℝ) < ((k + N : ℕ) : ℝ) := by
        have : 0 < k + N := by omega
        exact_mod_cast this
      have hkM1_pos : (0 : ℝ) < ((k + M + 1 : ℕ) : ℝ) := by
        have : 0 < k + M + 1 := by omega
        exact_mod_cast this
      -- (k+N : ℕ) = (k+M+1) + 1, i.e. as reals (k+N:ℝ) = (k+M+1:ℝ) + 1.
      have h_succ : ((k + N : ℕ) : ℝ) = ((k + M + 1 : ℕ) : ℝ) + 1 := by
        unfold_let N; push_cast; ring
      -- 1/((k+M+1)·(k+N)) ≤ 1/(k+N)^2... actually we want the other direction.
      -- 1/(k+N)^2 ≤ 1/((k+M+1)·(k+N)) since (k+M+1) ≤ (k+N).
      have h_le_factor : ((k + M + 1 : ℕ) : ℝ) ≤ ((k + N : ℕ) : ℝ) := by
        rw [h_succ]; linarith
      have h_prod_pos : 0 < ((k + M + 1 : ℕ) : ℝ) * ((k + N : ℕ) : ℝ) :=
        mul_pos hkM1_pos hkN_pos
      have h_kN_sq_pos : 0 < ((k + N : ℕ) : ℝ) ^ 2 := by positivity
      have h_inv_le :
          (1 : ℝ) / ((k + N : ℕ) : ℝ) ^ 2
            ≤ 1 / (((k + M + 1 : ℕ) : ℝ) * ((k + N : ℕ) : ℝ)) := by
        rw [div_le_div_iff h_kN_sq_pos h_prod_pos]
        have hsq : ((k + N : ℕ) : ℝ) ^ 2 = ((k + N : ℕ) : ℝ) * ((k + N : ℕ) : ℝ) := sq _
        rw [hsq]
        have := mul_le_mul_of_nonneg_right h_le_factor hkN_pos.le
        nlinarith [this, hkN_pos.le]
      -- telescoping: 1/((k+M+1)·(k+N)) = 1/(k+M+1) - 1/(k+N).
      have h_tele : (1 : ℝ) / (((k + M + 1 : ℕ) : ℝ) * ((k + N : ℕ) : ℝ))
                      = 1 / ((k + M + 1 : ℕ) : ℝ) - 1 / ((k + N : ℕ) : ℝ) := by
        rw [h_succ]
        field_simp
      linarith [h_inv_le, h_tele.le, h_tele.ge]
    -- Apply to partial sum and telescope.
    have h_sum_term_le :
        (∑ k ∈ range K, 1 / (((k + N : ℕ) : ℝ)) ^ 2)
          ≤ ∑ k ∈ range K, (1 / ((k + M + 1 : ℕ) : ℝ)
                              - 1 / ((k + N : ℕ) : ℝ)) :=
      Finset.sum_le_sum (fun k _ => h_telescope_term k)
    -- Telescoping ∑_{k<K} (1/(k+M+1) - 1/(k+N)).
    -- (k+N : ℕ) = ((k+1) + (M+1) : ℕ) since N = M+2.
    have h_succ_index :
        (fun k : ℕ => (1 : ℝ) / ((k + N : ℕ) : ℝ))
          = (fun k : ℕ => (1 : ℝ) / (((k + 1) + (M + 1) : ℕ) : ℝ)) := by
      funext k; unfold_let N; congr 2; push_cast; ring
    -- This is a telescoping sum.
    have h_partial_sum_eq :
        ∑ k ∈ range K, (1 / ((k + M + 1 : ℕ) : ℝ)
                          - 1 / ((k + N : ℕ) : ℝ))
          = 1 / ((M + 1 : ℕ) : ℝ) - 1 / ((K + M + 1 : ℕ) : ℝ) := by
      -- Switch to a clean telescoping form.
      have hfun : (fun k : ℕ => (1 : ℝ) / ((k + M + 1 : ℕ) : ℝ)
                                  - 1 / ((k + N : ℕ) : ℝ))
                  = (fun k : ℕ => (fun j : ℕ => (1 : ℝ) / ((j + M + 1 : ℕ) : ℝ)) k
                                    - (fun j : ℕ => (1 : ℝ) / ((j + M + 1 : ℕ) : ℝ)) (k + 1)) := by
        funext k
        unfold_let N
        congr 1
        congr 2; push_cast; ring
      rw [hfun, Finset.sum_range_sub']
      simp
    -- Final bound.
    have h_neg : (0 : ℝ) ≤ 1 / ((K + M + 1 : ℕ) : ℝ) := by positivity
    linarith [h_sum_term_le, h_partial_sum_eq.le, h_partial_sum_eq.ge]
  -- Summability of 1/((k+N:ℕ):ℝ)^2.
  have h_inv_sq_summable : Summable (fun k : ℕ => 1 / (((k + N : ℕ) : ℝ)) ^ 2) := by
    refine summable_of_sum_range_le (c := 1 / ((M + 1 : ℕ) : ℝ))
      (fun k => by positivity) (fun K => ?_)
    exact h_sum_inv_sq_partial K
  -- tsum bound.
  have h_inv_sq_tsum_le :
      (∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 2) ≤ 1 / ((M + 1 : ℕ) : ℝ) :=
    Real.tsum_le_of_sum_range_le (fun k => by positivity) h_sum_inv_sq_partial
  -- For each k: 1/(k+N)^3 ≤ (1/(M+1)) · (1/(k+N)^2).
  have h_cube_le_sq : ∀ k : ℕ,
      (1 : ℝ) / (((k + N : ℕ) : ℝ)) ^ 3
        ≤ (1 / ((M + 1 : ℕ) : ℝ)) * (1 / (((k + N : ℕ) : ℝ)) ^ 2) := by
    intro k
    have hkN_pos : (0 : ℝ) < ((k + N : ℕ) : ℝ) := by
      have : 0 < k + N := by omega
      exact_mod_cast this
    have h_ge_M1 : ((M + 1 : ℕ) : ℝ) ≤ ((k + N : ℕ) : ℝ) := by
      have : M + 1 ≤ k + N := by unfold_let N; omega
      exact_mod_cast this
    have h_inv_le : (1 : ℝ) / ((k + N : ℕ) : ℝ) ≤ 1 / ((M + 1 : ℕ) : ℝ) :=
      one_div_le_one_div_of_le hMp1_pos_real h_ge_M1
    have h_kN_sq_nn : 0 ≤ (1 : ℝ) / (((k + N : ℕ) : ℝ)) ^ 2 := by positivity
    have hcube_eq : (1 : ℝ) / (((k + N : ℕ) : ℝ)) ^ 3
                      = (1 / ((k + N : ℕ) : ℝ)) * (1 / (((k + N : ℕ) : ℝ)) ^ 2) := by
      field_simp; ring
    rw [hcube_eq]
    exact mul_le_mul_of_nonneg_right h_inv_le h_kN_sq_nn
  -- Summability of 1/(k+N)^3 dominated by (1/(M+1))·(1/(k+N)^2).
  have h_inv_cube_summable : Summable (fun k : ℕ => 1 / (((k + N : ℕ) : ℝ)) ^ 3) := by
    refine Summable.of_nonneg_of_le (fun k => by positivity) h_cube_le_sq ?_
    exact h_inv_sq_summable.mul_left _
  -- tsum 1/(k+N)^3 ≤ (1/(M+1))^2 ≤ t.
  have h_inv_cube_tsum_le :
      (∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 3)
        ≤ (1 / ((M + 1 : ℕ) : ℝ)) ^ 2 := by
    have h1 : (∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 3)
                ≤ ∑' k : ℕ, (1 / ((M + 1 : ℕ) : ℝ)) * (1 / (((k + N : ℕ) : ℝ)) ^ 2) :=
      tsum_le_tsum h_cube_le_sq h_inv_cube_summable (h_inv_sq_summable.mul_left _)
    have h2 : ∑' k : ℕ, (1 / ((M + 1 : ℕ) : ℝ)) * (1 / (((k + N : ℕ) : ℝ)) ^ 2)
                = (1 / ((M + 1 : ℕ) : ℝ)) * ∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 2 := by
      rw [tsum_mul_left]
    rw [h2] at h1
    have h_M1_nn : (0 : ℝ) ≤ 1 / ((M + 1 : ℕ) : ℝ) := by positivity
    have h3 : (1 / ((M + 1 : ℕ) : ℝ)) * ∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 2
                ≤ (1 / ((M + 1 : ℕ) : ℝ)) * (1 / ((M + 1 : ℕ) : ℝ)) :=
      mul_le_mul_of_nonneg_left h_inv_sq_tsum_le h_M1_nn
    have h_sq : (1 / ((M + 1 : ℕ) : ℝ)) * (1 / ((M + 1 : ℕ) : ℝ))
                  = (1 / ((M + 1 : ℕ) : ℝ)) ^ 2 := by ring
    linarith
  -- (1/(M+1))^2 ≤ t.
  have h_inv_M1_sq_le_t : (1 / ((M + 1 : ℕ) : ℝ)) ^ 2 ≤ t := by
    have h_M1_sq_pos : 0 < ((M + 1 : ℕ) : ℝ) ^ 2 := by positivity
    have h_one_le : (1 : ℝ) ≤ t * ((M + 1 : ℕ) : ℝ) ^ 2 := h_t_Mp1_sq_ge
    have h_div : (1 : ℝ) / ((M + 1 : ℕ) : ℝ) ^ 2 ≤ t := by
      rw [div_le_iff h_M1_sq_pos]; linarith
    have h_eq : (1 / ((M + 1 : ℕ) : ℝ)) ^ 2 = 1 / ((M + 1 : ℕ) : ℝ) ^ 2 := by
      rw [div_pow, one_pow]
    rw [h_eq]; exact h_div
  -- Bound the tail tsum: ∑'_k g(k+N) ≤ Ctail · (1/t)^5 · t = Ctail · t^{-4}.
  have h_g_summable_tail : Summable (fun k : ℕ => g (k + N)) := by
    refine Summable.of_nonneg_of_le (fun k => hg_nonneg _) h_tail_term ?_
    exact (h_inv_cube_summable.mul_left _)
  have h_tail_tsum_le :
      (∑' k : ℕ, g (k + N))
        ≤ Ctail * (1 / t) ^ 5 * (1 / ((M + 1 : ℕ) : ℝ)) ^ 2 := by
    have hdom_summable :
        Summable (fun k : ℕ => Ctail * (1 / t) ^ 5 *
                    (1 / (((k + N : ℕ) : ℝ)) ^ 3)) := h_inv_cube_summable.mul_left _
    have hle : (∑' k : ℕ, g (k + N))
                  ≤ ∑' k : ℕ, Ctail * (1 / t) ^ 5 *
                      (1 / (((k + N : ℕ) : ℝ)) ^ 3) :=
      tsum_le_tsum h_tail_term h_g_summable_tail hdom_summable
    have heq : ∑' k : ℕ, Ctail * (1 / t) ^ 5 * (1 / (((k + N : ℕ) : ℝ)) ^ 3)
                = Ctail * (1 / t) ^ 5 *
                    ∑' k : ℕ, 1 / (((k + N : ℕ) : ℝ)) ^ 3 := by
      rw [tsum_mul_left]
    rw [heq] at hle
    have h_coef_nn : 0 ≤ Ctail * (1 / t) ^ 5 := by
      unfold_let Ctail; positivity
    have := mul_le_mul_of_nonneg_left h_inv_cube_tsum_le h_coef_nn
    linarith
  -- Combine the tail estimate.
  have h_tail_final : (∑' k : ℕ, g (k + N)) ≤ Ctail / t ^ 4 := by
    have h_step :
        Ctail * (1 / t) ^ 5 * (1 / ((M + 1 : ℕ) : ℝ)) ^ 2
          ≤ Ctail * (1 / t) ^ 5 * t := by
      have h_coef_nn : 0 ≤ Ctail * (1 / t) ^ 5 := by
        unfold_let Ctail; positivity
      exact mul_le_mul_of_nonneg_left h_inv_M1_sq_le_t h_coef_nn
    have h_simpl : Ctail * (1 / t) ^ 5 * t = Ctail / t ^ 4 := by
      have ht_ne : t ≠ 0 := ne_of_gt ht_pos
      field_simp
      ring
    linarith [h_tail_tsum_le, h_step, h_simpl.le, h_simpl.ge]
  -- Head bound: ∑_{k < N} g k ≤ Chead / t^4.
  have h_head_term_le : ∀ k ∈ range N, g k ≤ 64 * ((N : ℝ)) ^ 7 := by
    intro k hk
    have hk_lt : k < N := Finset.mem_range.mp hk
    have h_kp1_le : ((k : ℝ) + 1) ≤ (N : ℝ) := by
      have : (k + 1 : ℕ) ≤ N := hk_lt
      have hcast : ((k + 1 : ℕ) : ℝ) = (k : ℝ) + 1 := by push_cast; ring
      have := (Nat.cast_le (α := ℝ)).mpr this
      rw [hcast] at this; exact this
    have h_kp1_nn : (0 : ℝ) ≤ (k : ℝ) + 1 := by positivity
    have h_kp1_pow : ((k : ℝ) + 1) ^ 7 ≤ ((N : ℝ)) ^ 7 :=
      pow_le_pow_left h_kp1_nn h_kp1_le 7
    -- exp(-(3/4)·t·k²) ≤ 1.
    have h_arg_nonpos : -(3/4) * t * (k : ℝ) ^ 2 ≤ 0 := by
      have h1 : 0 ≤ (k : ℝ) ^ 2 := sq_nonneg _
      nlinarith [ht_pos, h1]
    have h_exp_le_one : Real.exp (-(3/4) * t * (k : ℝ) ^ 2) ≤ 1 := by
      have := Real.exp_le_one_iff.mpr h_arg_nonpos
      exact this
    have h_exp_nn : 0 ≤ Real.exp (-(3/4) * t * (k : ℝ) ^ 2) := (Real.exp_pos _).le
    have h_64_kp1_nn : 0 ≤ 64 * ((k : ℝ) + 1) ^ 7 := by positivity
    calc g k = 64 * ((k : ℝ) + 1) ^ 7 * Real.exp (-(3/4) * t * (k : ℝ) ^ 2) := rfl
      _ ≤ 64 * ((k : ℝ) + 1) ^ 7 * 1 :=
          mul_le_mul_of_nonneg_left h_exp_le_one h_64_kp1_nn
      _ = 64 * ((k : ℝ) + 1) ^ 7 := by ring
      _ ≤ 64 * ((N : ℝ)) ^ 7 := by
          have h64 : (0 : ℝ) ≤ 64 := by norm_num
          exact mul_le_mul_of_nonneg_left h_kp1_pow h64
  have h_head_sum_le : (∑ k ∈ range N, g k) ≤ Chead / t ^ 4 := by
    have h1 : (∑ k ∈ range N, g k) ≤ ∑ k ∈ range N, 64 * ((N : ℝ)) ^ 7 :=
      Finset.sum_le_sum h_head_term_le
    have h2 : (∑ k ∈ range N, (64 * ((N : ℝ)) ^ 7 : ℝ))
                = (N : ℝ) * (64 * ((N : ℝ)) ^ 7) := by
      rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    have h3 : (N : ℝ) * (64 * ((N : ℝ)) ^ 7) = 64 * (N : ℝ) ^ 8 := by ring
    have h4 : 64 * (N : ℝ) ^ 8 ≤ 64 * (6561 / t ^ 4) := by
      have h64 : (0 : ℝ) ≤ 64 := by norm_num
      exact mul_le_mul_of_nonneg_left hN8_le h64
    have h5 : 64 * (6561 / t ^ 4) = Chead / t ^ 4 := by
      unfold_let Chead; ring
    linarith [h1, h2.le, h2.ge, h3.le, h3.ge, h4, h5.le, h5.ge]
  -- Sum-split: ∑'_k g k = (∑_{k<N} g k) + ∑'_k g (k+N).
  have h_g_summable : Summable g := by
    -- g k = g((k - N) + N) for k ≥ N, etc. Use shift summability:
    -- Summable (fun k => g (k + N)) ↔ Summable g.
    exact (summable_nat_add_iff (G := ℝ) N).mp h_g_summable_tail
  have h_split : (∑' k : ℕ, g k)
                  = (∑ k ∈ range N, g k) + ∑' k : ℕ, g (k + N) :=
    (sum_add_tsum_nat_add (G := ℝ) N h_g_summable).symm
  -- Final bound: ∑'_k g k ≤ (Chead + Ctail) / t^4 = (Chead + Ctail) · t^{-4}.
  have h_tsum_le : (∑' k : ℕ, g k) ≤ (Chead + Ctail) / t ^ 4 := by
    rw [h_split]
    have h_add : Chead / t ^ 4 + Ctail / t ^ 4 = (Chead + Ctail) / t ^ 4 := by
      field_simp
    linarith [h_head_sum_le, h_tail_final, h_add.le, h_add.ge]
  -- Convert t^4 → t^(-4 : ℝ).
  have h_rpow_eq : (Chead + Ctail) / t ^ 4 = (Chead + Ctail) * t ^ (-4 : ℝ) := by
    have ht_ne : t ≠ 0 := ne_of_gt ht_pos
    have h4cast : ((4 : ℕ) : ℝ) = (4 : ℝ) := by norm_num
    have hrpow : t ^ (-4 : ℝ) = (t ^ (4 : ℕ))⁻¹ := by
      rw [show (-4 : ℝ) = -((4 : ℕ) : ℝ) from by rw [h4cast],
          Real.rpow_neg ht_pos.le, Real.rpow_natCast]
    rw [hrpow]
    field_simp
  calc K t ≤ ∑' k : ℕ, g k := h_env
    _ ≤ (Chead + Ctail) / t ^ 4 := h_tsum_le
    _ = (Chead + Ctail) * t ^ (-4 : ℝ) := h_rpow_eq

/-! ### H4 — bridge to `Heat_kernel_envelope_real` (small-`t` polynomial bound) -/

/-- The iterated heat-trace `K t` equals the product-form Peter–Weyl envelope
`Heat_kernel_envelope_real t` (from `Towers/YM/PeterWeylHeat.lean`) for every
`t > 0`. Both are the same spectral series `(dim λ)² · exp(-t·C₂(λ))` summed
over `ℕ × ℕ`; `K` is the iterated `∑'_m ∑'_n` form, the envelope is the
`∑'_{(m,n)}` product form. Bridged via `K_eq_tsum_prod` + `tsum_congr`. -/
private lemma K_eq_envelope (t : ℝ) (ht : 0 < t) :
    K t = Heat_kernel_envelope_real t := by
  rw [K_eq_tsum_prod t ht]
  unfold Heat_kernel_envelope_real
  refine tsum_congr (fun mn => ?_)
  symm
  show (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) = summand t mn
  unfold summand
  have hprod : (mn.1, mn.2) = mn := rfl
  rw [hprod]
  congr 1
  ring

/-- **H4 — honest small-`t` polynomial bound for the SU(3) heat-kernel
envelope.** There is a constant `C > 0` with
`Heat_kernel_envelope_real t ≤ C · t^(-4)` for every `t ∈ (0, 1)`.

This is the expected small-`t` polynomial shape (`t^{-4} = t^{-d/2}`,
`d = dim SU(3) = 8`) — an UPPER bound with exponent 4, NOT a proven optimality
(no matching lower bound is claimed). Obtained from `heat_trace_poly_bound`
via `K t = Heat_kernel_envelope_real t`.
It carries NO exponential `e^{-c/t}` factor: at the identity the heat kernel
blows up polynomially as `t → 0⁺`, so any `C · e^{-c/t} / t⁴` bound with `c > 0`
would be FALSE there (the geodesic distance vanishes on the diagonal, so the
Varadhan factor is `e^0 = 1`). NOT a mass gap, NOT the Varadhan off-diagonal
asymptotic; YM tower stays `Status: Open`. Classical trio, no `sorry`. -/
theorem heat_envelope_small_t :
    ∃ C : ℝ, 0 < C ∧ ∀ t ∈ Set.Ioo (0:ℝ) 1,
      Heat_kernel_envelope_real t ≤ C * t ^ (-4 : ℝ) := by
  obtain ⟨C, hC, hbound⟩ := heat_trace_poly_bound
  refine ⟨C, hC, ?_⟩
  rintro t ⟨ht0, ht1⟩
  rw [← K_eq_envelope t ht0]
  exact hbound t ⟨ht0, ht1.le⟩

-- #print axioms heat_envelope_small_t

end TheoremaAureum.Towers.YM.HeatTraceBound
