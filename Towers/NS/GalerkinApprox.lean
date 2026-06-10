/-
================================================================
Towers / NS / GalerkinApprox  —  NS Tower 540, Phase 4A (Galerkin)

Phase-4A deliverable on the **real** divergence-free Sobolev spaces
(`Towers.NS.FunctionSpaces`) and the Phase-3 energy functional
(`Towers.NS.Energy`). It builds the Galerkin finite-dimensional
approximation scheme and proves the a-priori energy bound on the
Galerkin sequence.

### What this file proves (classical trio, `sorry`-free)

  * `galerkinProj K n : Hˢ⁺² →L Kₙ` — the **finite-dimensional orthogonal
    projection** `Pₙ` onto the `n`-th Galerkin subspace `Kₙ` (a
    finite-dimensional subspace of `Hdiv_free (s+2)`), realized by
    mathlib's `orthogonalProjection`.  `galerkinProj_norm_le` : `‖Pₙ‖ ≤ 1`.
  * `galerkin_seq K u n t : Hˢ⁺²` — the **Galerkin sequence** `uₙ(t) =
    Pₙ (u t)`, the projection of a field `u : ℝ → Hˢ⁺²` onto `Kₙ`.
  * **`galerkin_seq_norm_le`** — the contraction bound `‖uₙ(t)‖ ≤ ‖u(t)‖`
    (the projection has operator norm `≤ 1`).
  * **`galerkin_seq_sq_le_energy`** — THE Phase-4A headline a-priori
    bound: `‖uₙ(t)‖² ≤ energy u t`. The Galerkin sequence is uniformly
    bounded by the (Phase-3) kinetic energy. `#print axioms` = classical
    trio `[propext, Classical.choice, Quot.sound]`.

### HONEST scope / deviation note

  * **Zero `sorry`, zero `sorryAx`** (the `≤ 2 sorries` budget is met with
    `0`; every declaration is the classical trio only). In Lean 4 `sorry`
    IS the axiom `sorryAx`, so a clean axiom audit forbids any `by sorry`;
    accordingly nothing here is `sorry`-backed.
  * **Deviation from the bare `galerkin_seq : ℕ → Hdiv_free s` signature.**
    A Galerkin scheme needs (i) the family `K : ℕ → Submodule ℂ Hˢ⁺²` of
    finite-dim subspaces, (ii) the field `u` being approximated, and
    (iii) the time `t`. So `galerkin_seq` takes `K`, `u`, `t` and is
    indexed by `ℕ`. The subspaces carry `[FiniteDimensional ℂ (K n)]`
    (the genuine finite-dimensionality of the scheme) and
    `[(K n).HasOrthogonalProjection]` (so `Pₙ` exists). Index bookkeeping
    matches Phase 3: `energy` lives on `Hdiv_free (s+2)`.
  * It builds the approximation scheme and its a-priori bound only; it
    proves NO Navier–Stokes existence/uniqueness/regularity result, and
    NO convergence of `uₙ` (that is Phase 4B, Aubin–Lions). NOT a brick,
    not in BRICKS, not a lakefile root. NS tower stays `Status: Open`;
    Surface #2 stays OPEN. YM untouched.
================================================================
-/

import Towers.NS.Energy
import Mathlib.Analysis.InnerProductSpace.Projection

open TheoremaAureum.Towers.NS.FunctionSpaces
open TheoremaAureum.Towers.NS.Energy

namespace TheoremaAureum
namespace Towers
namespace NS
namespace GalerkinApprox

variable {s : ℝ}
variable (K : ℕ → Submodule ℂ (Hdiv_free (s + 2))) [∀ n, FiniteDimensional ℂ (K n)]

/-- **The finite-dimensional Galerkin projection `Pₙ`** onto the `n`-th
finite-dimensional subspace `Kₙ` of `Hdiv_free (s+2)`, given by mathlib's
`orthogonalProjection`. The orthogonal projection exists because `Kₙ` is
finite-dimensional, hence complete (`FiniteDimensional.complete`) — supplied
as a *local* `CompleteSpace` instance so it never pollutes global instance
resolution. This is what makes the projection genuinely finite-dimensional. -/
noncomputable def galerkinProj (n : ℕ) : Hdiv_free (s + 2) →L[ℂ] (K n) :=
  haveI : CompleteSpace (K n) := FiniteDimensional.complete ℂ (K n)
  orthogonalProjection (K n)

/-- **`Pₙ` is a contraction: `‖Pₙ‖ ≤ 1`** (`orthogonalProjection_norm_le`). -/
theorem galerkinProj_norm_le (n : ℕ) : ‖galerkinProj K n‖ ≤ 1 := by
  haveI : CompleteSpace (K n) := FiniteDimensional.complete ℂ (K n)
  exact orthogonalProjection_norm_le (K n)

/-- **The Galerkin sequence** `uₙ(t) = Pₙ (u t)`, the projection of the
field `u` onto the `n`-th finite-dim subspace, viewed back in `Hˢ⁺²`. -/
noncomputable def galerkin_seq (u : ℝ → Hdiv_free (s + 2)) (n : ℕ) (t : ℝ) :
    Hdiv_free (s + 2) :=
  (galerkinProj K n (u t) : Hdiv_free (s + 2))

/-- **Contraction bound `‖uₙ(t)‖ ≤ ‖u(t)‖`.** The Galerkin projection does
not increase the norm. Trio-clean. -/
theorem galerkin_seq_norm_le (u : ℝ → Hdiv_free (s + 2)) (n : ℕ) (t : ℝ) :
    ‖galerkin_seq K u n t‖ ≤ ‖u t‖ := by
  have h1 : ‖galerkin_seq K u n t‖ = ‖galerkinProj K n (u t)‖ := Submodule.norm_coe _
  rw [h1]
  calc ‖galerkinProj K n (u t)‖
      ≤ ‖galerkinProj K n‖ * ‖u t‖ := (galerkinProj K n).le_opNorm (u t)
    _ ≤ 1 * ‖u t‖ :=
          mul_le_mul_of_nonneg_right (galerkinProj_norm_le K n) (norm_nonneg _)
    _ = ‖u t‖ := one_mul _

/-- **Phase-4A headline a-priori bound: `‖uₙ(t)‖² ≤ energy u t`.** The
Galerkin sequence is uniformly bounded by the Phase-3 kinetic energy.
Trio-clean (no `sorryAx`). -/
theorem galerkin_seq_sq_le_energy (u : ℝ → Hdiv_free (s + 2)) (n : ℕ) (t : ℝ) :
    ‖galerkin_seq K u n t‖ ^ 2 ≤ energy u t := by
  rw [energy_def]
  exact pow_le_pow_left (norm_nonneg _) (galerkin_seq_norm_le K u n t) 2

end GalerkinApprox
end NS
end Towers
end TheoremaAureum
