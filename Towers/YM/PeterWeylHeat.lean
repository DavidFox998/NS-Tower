/-
================================================================
Towers / YM / PeterWeylHeat  (Batch 19.1p-redux-b — Task #155)

**Truncated Peter-Weyl ≤ heat-kernel envelope.** Four sorry-free
bricks wiring the SU(3) Peter-Weyl `Summable` lemma from Batch
19.1p-redux-a (`Towers/YM/PeterWeyl.lean`, headline
`PeterWeyl_Summable_SU3`) into a real bound for the finite
truncation `Weyl_sum_explicit_SU3_real t N`.

### Honest scope note (locked)

The original Batch 19.3 attempt parked a sorry in
`Towers/Attempts/ClusterExpansion.lean:693` claiming
`Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_def_real t`,
i.e. against the small-`t` Varadhan / Molchanov asymptotic
placeholder `exp(-c/t) / t^4`. That statement is **false at the
placeholder values** (LHS at `N = 0, t = 1` equals
`Weyl_sum_explicit_SU3_real_at_zero = 1`, RHS equals
`Real.exp (-1) / 1 ≈ 0.368`). The honest discharge therefore
lands against an envelope `Heat_kernel_envelope_real t` defined
as the **genuine Peter-Weyl `tsum`** of the explicit spectral
series — which IS well-defined for every `t > 0` via
`PeterWeyl_Summable_SU3`. The Varadhan asymptotic
`tsum t ≤ heat_amplitude_constant · exp(-c/t) / t^4` for small
`t` remains a separate gap and is the *next* parked sorry; it is
what would actually advance YM tower past Open.

### What ships (4 bricks)

  1. `Heat_kernel_envelope_real_nonneg`
        `0 ≤ Heat_kernel_envelope_real t`
     Trivial via `tsum_nonneg` and nonneg of `(dim)² · exp _`.

  2. `Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real`
     *(headline)*
        `Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_envelope_real t` for `t > 0`
     Direct `Summable.sum_le_tsum` on the explicit Finset
     `(Finset.range (N+1) ×ˢ Finset.range (N+1)).filter (m+n ≤ N)`
     against the tsum `∑'_{(m,n) : ℕ²} (dim)² · exp(-(t · C₂))`.
     Consumes `PeterWeyl_Summable_SU3` from Batch 19.1p-redux-a.

  3. `Heat_kernel_envelope_real_ge_one_of_pos`
        `1 ≤ Heat_kernel_envelope_real t` for `t > 0`
     Composition: `Weyl_sum_explicit_SU3_real_at_zero` gives
     LHS = 1 at `N = 0`, then Brick 2 closes the rest. Shows the
     envelope is not the trivial-zero `tsum`-default value — i.e.
     `Summable` actually fires and the trivial-rep summand `1` is
     accounted for.

  4. `Heat_kernel_envelope_real_ge_truncation`
        `Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_envelope_real t` for `t > 0`
     Convenience alias of Brick 2 with the `{t : ℝ} (ht : 0 < t)`
     argument order flipped to `(t : ℝ) (ht : 0 < t) (N : ℕ)`,
     matching the original Attempts/ParkedSorry signature so the
     downstream patch in `Towers/Attempts/ClusterExpansion.lean`
     can `:= …` against this brick.

### Honest scope (locked)

The four bricks above are textbook real-analysis facts about the
finite truncation of a `Summable` series. They are NOT:
  * the Varadhan / Molchanov small-`t` asymptotic
    `K_t(1) ~ C · exp(-c/t) / t^4`,
  * a proof that `Heat_kernel_envelope_real = Heat_kernel_def_real`
    (the placeholder shape — that equality is FALSE at the
    placeholder values, see preamble),
  * a constructive 4D pure-Yang-Mills measure,
  * a mass-gap lower bound on any YM Hamiltonian.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2.
================================================================
-/

import Towers.YM.PeterWeyl
import Towers.YM.ClusterExpansion
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Topology.Algebra.InfiniteSum.Order

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeylHeat

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl

/-- **Genuine SU(3) Peter-Weyl heat-kernel envelope at the identity.**
The `tsum` over all SU(3) highest weights `(m, n) : ℕ × ℕ` of the
explicit spectral summand `(dim λ)² · exp(-(t · C₂(λ)))`.

Well-defined as the limit of partial sums for every `t > 0` via
`PeterWeyl_Summable_SU3` (Batch 19.1p-redux-a). At `t ≤ 0` the
`Summable` hypothesis fails and `tsum` defaults to `0` by mathlib
convention — none of the bricks below depend on that regime. -/
noncomputable def Heat_kernel_envelope_real (t : ℝ) : ℝ :=
  ∑' (mn : ℕ × ℕ),
    ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
      Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ)))

/-! ## Brick 1 — `0 ≤ Heat_kernel_envelope_real t` -/

/-- `0 ≤ Heat_kernel_envelope_real t` for every `t : ℝ`.
Trivial: every summand is a product `(dim)² ≥ 0` and `exp _ > 0`,
so `tsum_nonneg` closes regardless of `Summable`. -/
theorem Heat_kernel_envelope_real_nonneg (t : ℝ) :
    0 ≤ Heat_kernel_envelope_real t := by
  unfold Heat_kernel_envelope_real
  exact tsum_nonneg (fun _ =>
    mul_nonneg (sq_nonneg _) (Real.exp_pos _).le)

/-! ## Brick 2 — Truncation ≤ envelope (`Summable.sum_le_tsum`) -/

/-- **Truncated Peter-Weyl sum ≤ genuine envelope.** For `t > 0`,
the finite truncation `Weyl_sum_explicit_SU3_real t N` (a
`Finset.sum` over `{(m,n) : m+n ≤ N}`) is bounded above by the
`tsum` envelope `Heat_kernel_envelope_real t`.

Direct application of mathlib's `Summable.sum_le_tsum`: every
summand is nonneg `(dim)² · exp _ ≥ 0`, and the underlying series
is `Summable` via `PeterWeyl_Summable_SU3 ht`. -/
theorem Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real
    {t : ℝ} (ht : 0 < t) (N : ℕ) :
    Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_envelope_real t := by
  unfold Weyl_sum_explicit_SU3_real Heat_kernel_envelope_real
  exact sum_le_tsum _
    (fun mn _ => mul_nonneg (sq_nonneg _) (Real.exp_pos _).le)
    (PeterWeyl_Summable_SU3 ht)

/-! ## Brick 3 — `1 ≤ envelope` for `t > 0` -/

/-- For every `t > 0`, `1 ≤ Heat_kernel_envelope_real t`.
The trivial-rep `(0,0)` summand contributes
`(dim 0)² · exp(0) = 1 · 1 = 1`, and every other summand is
nonneg; this is exactly what
`Weyl_sum_explicit_SU3_real_at_zero` plus Brick 2 give. Shows
the envelope is not the trivial-zero default of `tsum` at a
non-summable function — `PeterWeyl_Summable_SU3` actually
fires. -/
theorem Heat_kernel_envelope_real_ge_one_of_pos
    {t : ℝ} (ht : 0 < t) :
    1 ≤ Heat_kernel_envelope_real t := by
  have h0 := Weyl_sum_explicit_SU3_real_at_zero t
  have hle :=
    Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real ht 0
  linarith

/-! ## Brick 4 — Attempts/ patch convenience alias -/

/-- Convenience re-export of Brick 2 with the `(t : ℝ) (ht : 0 < t) (N : ℕ)`
argument order matching the original (false-claim) parked sorry
in `Towers/Attempts/ClusterExpansion.lean:693`. The Attempts/
patch in Batch 19.1p-redux-b uses this alias as its
`:= …` term, so the parked sorry becomes a sorry-free `theorem`
against the genuine Peter-Weyl envelope. -/
theorem Heat_kernel_envelope_real_ge_truncation
    (t : ℝ) (ht : 0 < t) (N : ℕ) :
    Weyl_sum_explicit_SU3_real t N ≤ Heat_kernel_envelope_real t :=
  Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real ht N

end PeterWeylHeat
end YM
end Towers
end TheoremaAureum
