/-
# Off-diagonal heat-kernel schema for SU(3) — STAND-IN

**STATUS: Open.** Real metric / kernel / Varadhan principle deferred to
Batch 156.6.  This file ships an **honest stand-in schema** so downstream
bricks can reference `K'` and `d` at type level; both definitions are
degenerate (`d ≡ 0`, `K' t _ := K t`) and the `off_diag_kernel_bound_standin`
lemma is therefore **NOT** a real off-diagonal Gaussian heat-kernel bound on
SU(3) — it reduces to `heat_trace_poly_bound` at `g = 1` because
`Real.exp (-c · 0^2 / t) = 1`.

Real definitions (Riemannian distance on SU(3) via the bi-invariant metric,
true matrix-element heat kernel via Peter–Weyl, Feynman–Kac upper bound)
land in Batch 156.6.  Until then, the YM tower stays `Status: Open` in
`docs/ROADMAP.md`.

**Tripwire:** the bound `exp(-c · d(g,1)^2 / t)` collapses to `1` here.
Replacing `d` with the real Riemannian distance will *intentionally* break
this proof — that is the signal that a real off-diagonal bound has landed.
-/

import Towers.YM.HeatTraceBound
import Mathlib.LinearAlgebra.UnitaryGroup

namespace TheoremaAureum.Towers.YM.OffDiagKernel

open TheoremaAureum.Towers.YM.HeatTraceBound Matrix

/-- Stand-in for the SU(3) group element. -/
abbrev SU3 : Type := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-- **STAND-IN.** Real heat kernel `(t, g) ↦ K(t, g)` deferred to 156.6.
    Here we set `K' t _ := K t`, so the off-diagonal information is trivially
    absent. -/
noncomputable def K' (t : ℝ) (_g : SU3) : ℝ :=
  TheoremaAureum.Towers.YM.HeatTraceBound.K t

/-- **STAND-IN.** Real bi-invariant Riemannian distance on SU(3) deferred to
    156.6.  Here `d _ _ := 0`, so `exp(-c · d²/t) = 1` in every bound. -/
noncomputable def d (_g _h : SU3) : ℝ := 0

/-- **STAND-IN.** Schematic off-diagonal Gaussian bound for the SU(3) heat
    kernel.  Because `d` and `K'` are degenerate here, this lemma is
    equivalent (up to the trivial `exp 0 = 1` factor) to
    `heat_trace_poly_bound`; it is **not** a real Varadhan-style estimate.
    See file docstring for the tripwire. -/
lemma off_diag_kernel_bound_standin :
    ∃ c : ℝ, 0 < c ∧ ∃ C : ℝ, 0 < C ∧
      ∀ t ∈ Set.Ioc (0:ℝ) 1, ∀ g : SU3,
        K' t g ≤ C * t^(-4 : ℝ) * Real.exp (-c * (d g 1)^2 / t) := by
  obtain ⟨C₀, hC₀_pos, hC₀_bound⟩ :=
    TheoremaAureum.Towers.YM.HeatTraceBound.heat_trace_poly_bound
  refine ⟨1, by norm_num, C₀, hC₀_pos, ?_⟩
  intro t ht g
  -- `d g 1 = 0` and `K' t g = K t`, so the goal collapses to `K t ≤ C₀·t^{-4}`.
  show TheoremaAureum.Towers.YM.HeatTraceBound.K t
        ≤ C₀ * t^(-4 : ℝ) * Real.exp (-1 * (d g 1)^2 / t)
  have hd : d g 1 = 0 := rfl
  rw [hd]
  have hexp : Real.exp (-1 * (0:ℝ)^2 / t) = 1 := by
    rw [show -1 * (0:ℝ)^2 / t = 0 by ring, Real.exp_zero]
  rw [hexp, mul_one]
  exact hC₀_bound t ht

end TheoremaAureum.Towers.YM.OffDiagKernel
