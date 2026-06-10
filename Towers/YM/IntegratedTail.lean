/-
# Finite-time integrated tail for the SU(3) heat-kernel stand-in — STAND-IN

**STATUS: Open.** Real metric / kernel / Gaussian tail deferred to
Batch 156.6.

Unlike the earlier (now-rejected) `Set.Ioi` draft, this version
integrates over the **finite** interval `Set.Ioc δ T` with `δ < T ≤ 1`,
so the lemma is **non-vacuous**: the bound
`(T - δ) · K t ≤ C · t^(-4) · (T - δ)` is a real consequence of the
`heat_trace_poly_bound` trace bound, just lifted to the
`g`-independent stand-in `K' t _ := K t`.

It is **not** a real off-diagonal Gaussian tail bound — the `g`
dependence is still absent because `K'` and `d` are the degenerate
stand-ins introduced in `Towers.YM.OffDiagKernel`.  The "tail" here is
just the Lebesgue length `(T - δ)` of the integration window times the
diagonal heat-trace bound.  Real Gaussian decay in `s` (via a real
metric) lands in Batch 156.6.

**Tripwire:** the moment `K' t g` actually depends on `g` (= once the
real heat kernel lands), the integrand stops being constant in `s` and
this proof intentionally breaks — that's the signal that the real
tail-bound proof needs to be written.
-/

import Towers.YM.OffDiagKernel
import Mathlib.MeasureTheory.Integral.SetIntegral
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace TheoremaAureum.Towers.YM.IntegratedTail

open TheoremaAureum.Towers.YM.HeatTraceBound
open TheoremaAureum.Towers.YM.OffDiagKernel
open MeasureTheory

/-- **STAND-IN.** Finite-time integrated tail bound for the SU(3)
    heat-kernel stand-in.  Because `K' t 1 = K t` is constant in `s`,
    `∫ s in Set.Ioc δ T, K' t 1 = (T - δ) · K t`, which the
    `heat_trace_poly_bound` upper-bounds by `(T - δ) · C · t^(-4)`.
    This is **NOT** a real off-diagonal Gaussian tail bound; the `g`
    dependence collapses because the stand-in `K'` ignores its group
    argument.  See file docstring for the tripwire. -/
lemma integrated_tail_standin
    (δ T : ℝ) (hδ : 0 < δ) (hδT : δ < T) (hT : T ≤ 1) :
    ∃ C : ℝ, 0 < C ∧ ∀ t ∈ Set.Ioc (0:ℝ) T,
      (∫ _s in Set.Ioc δ T,
          K' t (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
        ≤ C * t ^ (-4 : ℝ) * (T - δ) := by
  obtain ⟨C₀, hC₀_pos, hC₀_bound⟩ := heat_trace_poly_bound
  refine ⟨C₀, hC₀_pos, ?_⟩
  intro t ht
  -- `K' t 1 = K t` by definition (stand-in).
  show (∫ _s in Set.Ioc δ T, K t) ≤ C₀ * t ^ (-4 : ℝ) * (T - δ)
  -- ∫_(δ,T] (K t) ds = (T - δ) • K t = (T - δ) * K t.
  have hTδ_nn : (0 : ℝ) ≤ T - δ := by linarith
  rw [setIntegral_const, Real.volume_Ioc, ENNReal.toReal_ofReal hTδ_nn, smul_eq_mul]
  -- Goal: `(T - δ) * K t ≤ C₀ * t^(-4) * (T - δ)`.
  rw [mul_comm (T - δ) (K t), mul_comm (C₀ * t ^ (-4 : ℝ)) (T - δ),
      mul_comm (T - δ) (C₀ * t ^ (-4 : ℝ))]
  exact mul_le_mul_of_nonneg_right
    (hC₀_bound t ⟨ht.1, le_trans ht.2 hT⟩) hTδ_nn

end TheoremaAureum.Towers.YM.IntegratedTail
