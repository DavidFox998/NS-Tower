/-
================================================================
Towers / YM / Wall253_KP_Cluster

**Kotecký–Preiss cluster expansion — honest CONDITIONAL combinator.**

This file extends the single-plaquette smallness surrogate `kp_sum_lt_half`
(Wall252_KP) toward a *full* polymer sum, in two honestly-scoped layers:

  1. a GENUINE multi-term geometric cluster series over all polymer SIZES
     `n : ℕ`, whose convergence is driven by the base-case smallness
     `kp_sum_lt_half` (`kp_cluster_summable`, `kp_cluster_sum_lt_two`); and
  2. a CONDITIONAL full-polymer-index criterion `kp_cluster_criterion`:
     summability of the genuine sum `∑_π |activity π|` over an arbitrary
     (possibly infinite) polymer index, routed through a single NAMED OPEN
     surface — the weighted Kotecký–Preiss summability `hKP`.

## What this file is (and is NOT)

* **`kp_sum_nonneg`, `kp_sum_lt_one`** — the base case: for `0 ≤ β < 48/e`
  and a genuine SU(2) plaquette `g`, `0 ≤ KP_sum β g < 1`. These are honest
  consequences of `kp_sum_lt_half` (which gives `< 1/2`) plus nonnegativity of
  the mode weight / activity / `β`.

* **`kp_cluster_summable`, `kp_cluster_sum_lt_two`** — the "cluster expansion":
  the geometric series `∑' n, (KP_sum β g)^n` over all polymer sizes is genuinely
  `Summable` and its total is `< 2`. This is a REAL infinite sum (mathlib's
  `summable_geometric_of_lt_one` / `tsum_geometric_of_lt_one`), NOT a single
  term — but see the honesty box: it is a MODELED size-series majorant, NOT the
  literal polymer-index sum, because it omits polymer multiplicity (entropy).

* **`kp_cluster_criterion`** — the "sum over all polymers π": for an arbitrary
  index type `Polymer` and activities `activity, a : Polymer → ℝ` with `a ≥ 0`,
  GIVEN the NAMED surface `hKP : Summable (fun π => |activity π| · e^{a π})`
  (the weighted KP sum is finite), the unweighted full sum
  `Summable (fun π => |activity π|)` follows by the comparison test
  (`e^{a π} ≥ 1`). The convergence lives ENTIRELY in `hKP`.

## Honest scope (locked)

* **The geometric layer is a SIZE-series MAJORANT, not the polymer-index sum.**
  The genuine KP sum is `∑_π |activity π|` over polymers organised by size:
  `∑_n (#{size-n polymers}) · (per-polymer activity)`. Beating the entropy
  factor `#{size-n} ≈ (2d−1)^n = 7^n` (cf. `EntropyBound.polymer_const = 7`)
  geometrically requires per-polymer activity `< 1/7`. `kp_sum_lt_half` only
  delivers `< 1/2`, NOT `< 1/7` — so the entropy-weighted geometric series is
  NOT shown to converge here. `kp_cluster_summable` is the convergence of the
  SIMPLIFIED series `∑_n r^n` (multiplicity dropped), an honest majorant of a
  reduced model, not of the genuine polymer sum.

* **`kp_cluster_criterion` is CONDITIONAL on the OPEN surface `hKP`.** `hKP`
  is the genuine Kotecký–Preiss combinatorial core (the tree-graph / Ursell
  weighted-summability bound from the local overlap criterion
  `∑_{π'∼π} |ζ(π')| e^{a(π')} ≤ a(π)`), absent from mathlib v4.12.0. It is a
  HYPOTHESIS, NOT `by sorry`, so the elaborated term carries NO `sorryAx`. This
  file proves `hKP` NOWHERE. It is the same comparison-test shape as
  `Towers/Attempts/ClusterExpansion.lean`'s `kotecky_preiss_criterion` and does
  NOT touch, discharge, or weaken that invariant-locked `sorry`.

* **No physics claim.** This makes NO Yang–Mills mass-gap / `μ > 0` /
  Surface-#1 / RH / BSD claim, establishes NO unconditional KP convergence, and
  proves NO Wilson-transfer spectral gap. YM stays `Status: Open` — the cluster
  expansion + OS positivity remain to be done.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports `Towers.YM.Wall252_KP` and mathlib's
geometric-series API only; imports nothing from the NS tower.
================================================================
-/

import Towers.YM.Wall252_KP
import Mathlib.Analysis.SpecificLimits.Basic

namespace TheoremaAureum.Towers.YM.Wall253

open TheoremaAureum.Towers.YM.Wall252

/-! ### Base case (driven by `kp_sum_lt_half`) -/

/-- **Base-case nonnegativity.** For `0 ≤ β`, the single-plaquette KP smallness
    surrogate `KP_sum β g` is nonnegative (mode weight `≥ 0`, both exponentials
    `> 0`, and `β ≥ 0`). -/
theorem kp_sum_nonneg {β : ℝ}
    (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) (hβ0 : 0 ≤ β) :
    0 ≤ KP_sum β g := by
  unfold KP_sum
  apply div_nonneg _ (by norm_num)
  exact mul_nonneg
    (mul_nonneg
      (mul_nonneg kpModeWeight_nonneg (Real.exp_pos _).le) (Real.exp_pos _).le)
    hβ0

/-- **Base case `< 1`.** For `0 ≤ β < 48/e`, `KP_sum β g < 1`, since
    `kp_sum_lt_half` already gives `< 1/2`. This is the geometric ratio
    smallness that powers the cluster series below. -/
theorem kp_sum_lt_one {β : ℝ}
    (g : Matrix.specialUnitaryGroup (Fin 2) ℂ)
    (hβ0 : 0 ≤ β) (hβ : β < 48 / Real.exp 1) :
    KP_sum β g < 1 :=
  lt_trans (kp_sum_lt_half g hβ0 hβ) (by norm_num)

/-! ### Cluster expansion — geometric size-series (genuine multi-term sum) -/

/-- The **cluster series**: the geometric sum `∑' n, (KP_sum β g)^n` over all
    polymer sizes `n : ℕ`. HONEST: a MODELED size-series majorant with polymer
    multiplicity (entropy) dropped — see the file header. -/
noncomputable def kpClusterSum (β : ℝ)
    (g : Matrix.specialUnitaryGroup (Fin 2) ℂ) : ℝ :=
  ∑' n : ℕ, (KP_sum β g) ^ n

/-- **Cluster expansion converges (genuine infinite sum).** For `0 ≤ β < 48/e`
    the geometric series `∑ₙ (KP_sum β g)^n` over all sizes is `Summable`,
    because the base ratio satisfies `0 ≤ KP_sum β g < 1`. This is a real
    multi-term sum, NOT the single-term surrogate — but it is a size-series
    majorant, NOT the genuine polymer-index sum (see header). -/
theorem kp_cluster_summable {β : ℝ}
    (g : Matrix.specialUnitaryGroup (Fin 2) ℂ)
    (hβ0 : 0 ≤ β) (hβ : β < 48 / Real.exp 1) :
    Summable (fun n : ℕ => (KP_sum β g) ^ n) :=
  summable_geometric_of_lt_one (kp_sum_nonneg g hβ0) (kp_sum_lt_one g hβ0 hβ)

/-- **Cluster-sum total bound.** For `0 ≤ β < 48/e`, `kpClusterSum β g < 2`:
    the geometric total `(1 − KP_sum β g)⁻¹` is `< 2` because `KP_sum β g < 1/2`
    forces `1 − KP_sum β g > 1/2`. -/
theorem kp_cluster_sum_lt_two {β : ℝ}
    (g : Matrix.specialUnitaryGroup (Fin 2) ℂ)
    (hβ0 : 0 ≤ β) (hβ : β < 48 / Real.exp 1) :
    kpClusterSum β g < 2 := by
  have hhalf : KP_sum β g < 1 / 2 := kp_sum_lt_half g hβ0 hβ
  unfold kpClusterSum
  rw [tsum_geometric_of_lt_one (kp_sum_nonneg g hβ0) (kp_sum_lt_one g hβ0 hβ)]
  have hpos : (0 : ℝ) < 1 - KP_sum β g := by linarith
  rw [inv_eq_one_div, div_lt_iff hpos]
  linarith

/-! ### Full polymer-index criterion — CONDITIONAL on the open surface `hKP` -/

/-- **Kotecký–Preiss cluster criterion (honest conditional combinator).**

For an arbitrary polymer index type `Polymer` (possibly infinite — the genuine
KP index is the infinite lattice-polymer family) with activities
`activity, a : Polymer → ℝ` and nonnegative weight `a ≥ 0`, GIVEN the weighted
KP summability surface

    `hKP : Summable (fun π => |activity π| * Real.exp (a π))`

the genuine unweighted full sum `Summable (fun π => |activity π|)` follows by the
comparison test, since `Real.exp (a π) ≥ 1`.

HONEST: the convergence lives ENTIRELY in `hKP`, the genuine KP combinatorial
core (tree-graph / Ursell weighted summability), which is a NAMED OPEN surface —
a hypothesis, NOT `by sorry`. This proves `hKP` nowhere, makes NO mass-gap claim,
and does NOT discharge the invariant-locked `kotecky_preiss_criterion` `sorry`. -/
theorem kp_cluster_criterion {Polymer : Type*}
    (activity a : Polymer → ℝ) (ha : ∀ π, 0 ≤ a π)
    (hKP : Summable (fun π : Polymer => |activity π| * Real.exp (a π))) :
    Summable (fun π : Polymer => |activity π|) := by
  refine Summable.of_nonneg_of_le (fun π => abs_nonneg _) (fun π => ?_) hKP
  have hone : (1 : ℝ) ≤ Real.exp (a π) := by
    have h := Real.add_one_le_exp (a π)
    linarith [ha π]
  calc |activity π|
      = |activity π| * 1 := (mul_one _).symm
    _ ≤ |activity π| * Real.exp (a π) :=
        mul_le_mul_of_nonneg_left hone (abs_nonneg _)

end TheoremaAureum.Towers.YM.Wall253
