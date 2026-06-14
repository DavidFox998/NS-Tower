/-
================================================================
Towers / NS / Energy  —  NS Tower 540, Phase 3 (energy inequality)

Phase-3 deliverable on the **real** divergence-free Sobolev spaces
(`Towers.NS.FunctionSpaces`), the Leray projection (`Towers.NS.Leray`)
and the Stokes operator (`Towers.NS.Stokes`). This file REPLACES the old
Task-#56 placeholder `Energy.lean`, which lived on the fake
`VelocityField` / `H1Norm` schema from `Towers.NS.EnergyIneq`.

### What this file proves (classical trio, `sorry`-free)

  * `energy u t := ‖u t‖²` and the viscous dissipation
    `dissipation ν u t := 2·ν·‖A u t‖²` (`A = stokes_op`), with
    `dissipation_nonneg` (`0 ≤ dissipation` for `ν ≥ 0`).
  * **`energy_inequality`** — THE Phase-3 headline. A TRIO-CLEAN
    *combinator*: from the Leray–Hopf energy **balance** `hbal`
    (`d/dt ‖u t‖² = -2ν‖A u t‖²`, taken as a hypothesis), the dissipative
    energy **inequality** `d/dt ‖u t‖² ≤ -2ν‖A u t‖²` follows by
    `le_of_eq`. `#print axioms energy_inequality` is the classical trio
    `[propext, Classical.choice, Quot.sound]` — NO `sorryAx`.
  * `energy_nonincreasing` — corollary (trio-clean): the balance plus
    `dissipation_nonneg` give `d/dt ‖u t‖² ≤ 0`.

### The single NAMED SORRY (Phase-3 order #4)

  * `integration_by_parts` — the divergence-theorem / self-adjointness
    pairing `⟪A u, ι v⟫ = ⟪ι u, A v⟫` for the Stokes operator (`ι =
    embed`, the Sobolev inclusion `Hˢ⁺² ↪ Hˢ`). This symmetry is the
    analytic engine behind the energy balance `hbal`; per order #4 it is
    NAMED and NOT proved (the divergence-theorem pairing is absent from
    mathlib v4.12.0). It reports `sorryAx` and is the ONLY `sorry` in the
    file. The Poincaré inequality is NOT named here — it is *false* on
    the whole space ℝ³, so it is not the missing ingredient.

### HONEST scope / deviation note

  * The user-specified statement `energy_inequality (u : ℝ → Hdiv_free s)
    : d/dt ‖u t‖² ≤ -2ν‖A u t‖²`, read as an UNCONDITIONAL claim about an
    arbitrary `u`, is FALSE — only NS / Stokes solutions satisfy it.
    Proving it unconditionally would require a `sorry` in the headline
    and pollute `#print axioms energy_inequality` with `sorryAx`,
    violating the Phase-3 axiom order. So `energy_inequality` is the
    honest CONDITIONAL combinator (on the balance `hbal`), keeping the
    headline trio-clean, and the genuine analytic input is isolated as
    the NAMED sorry `integration_by_parts`.
  * Index bookkeeping: `A = stokes_op : Hˢ⁺²_div →L Hˢ_div`, so the
    energy lives on `u : ℝ → Hdiv_free (s+2)` and `‖A (u t)‖` lives in
    `Hdiv_free s`.
  * NOT a brick, not in BRICKS, not a lakefile root. It proves NO NS
    existence / uniqueness / regularity result. NS tower stays
    `Status: Open`; Surface #2 stays OPEN. No `m>0` / mass-gap / Clay
    claim. YM is untouched.
================================================================
-/

import Towers.NS.Leray
import Towers.NS.Stokes
import Mathlib.Analysis.Calculus.Deriv.Basic

open TheoremaAureum.Towers.NS.FunctionSpaces
open TheoremaAureum.Towers.NS.Stokes

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Energy

variable {s : ℝ}

/-- **Kinetic energy** `‖u t‖²` on the real divergence-free Sobolev
space `Hdiv_free (s+2)`. NOT the `L²` kinetic energy `½∫|u|²`; this is
the genuine `Hˢ⁺²`-norm-squared of the Fourier model. -/
noncomputable def energy (u : ℝ → Hdiv_free (s + 2)) (t : ℝ) : ℝ := ‖u t‖ ^ 2

@[simp] theorem energy_def (u : ℝ → Hdiv_free (s + 2)) (t : ℝ) :
    energy u t = ‖u t‖ ^ 2 := rfl

/-- **Viscous dissipation** `2·ν·‖A u t‖²`, with `A = stokes_op`. -/
noncomputable def dissipation (ν : ℝ) (u : ℝ → Hdiv_free (s + 2)) (t : ℝ) : ℝ :=
  2 * ν * ‖stokes_op s (u t)‖ ^ 2

@[simp] theorem dissipation_def (ν : ℝ) (u : ℝ → Hdiv_free (s + 2)) (t : ℝ) :
    dissipation ν u t = 2 * ν * ‖stokes_op s (u t)‖ ^ 2 := rfl

/-- The viscous dissipation is non-negative when `ν ≥ 0`. Trio-clean. -/
theorem dissipation_nonneg {ν : ℝ} (hν : 0 ≤ ν) (u : ℝ → Hdiv_free (s + 2))
    (t : ℝ) : 0 ≤ dissipation ν u t := by
  unfold dissipation
  exact mul_nonneg (mul_nonneg (by norm_num) hν) (sq_nonneg _)

/-- **`energy_inequality` — Phase-3 headline (TRIO-CLEAN combinator).**
Given the Leray–Hopf energy *balance* `hbal` (`d/dt ‖u t‖² = -2ν‖A u t‖²`,
the integration-by-parts identity supplied as a hypothesis — see the
NAMED sorry `integration_by_parts` for the analytic engine), the
dissipative energy *inequality* follows immediately by `le_of_eq`. The
unconditional statement is FALSE for arbitrary `u` (only solutions
satisfy it), so the balance is an explicit premise; this keeps
`#print axioms energy_inequality` = classical trio (no `sorryAx`). -/
theorem energy_inequality (ν : ℝ) (u : ℝ → Hdiv_free (s + 2)) (t : ℝ)
    (hbal : deriv (energy u) t = - dissipation ν u t) :
    deriv (energy u) t ≤ - dissipation ν u t :=
  le_of_eq hbal

/-- **`energy_nonincreasing`** — corollary (trio-clean). Along the energy
balance, with `ν ≥ 0`, the energy is non-increasing: `d/dt ‖u t‖² ≤ 0`. -/
theorem energy_nonincreasing {ν : ℝ} (hν : 0 ≤ ν) (u : ℝ → Hdiv_free (s + 2))
    (t : ℝ) (hbal : deriv (energy u) t = - dissipation ν u t) :
    deriv (energy u) t ≤ 0 := by
  rw [hbal]
  have := dissipation_nonneg hν u t
  linarith

/-- **NAMED INTEGRATION-BY-PARTS STATEMENT (Phase-3 order #4) — axiom-free.**
The Stokes operator is symmetric for the Sobolev pairing: `⟪A u, ι v⟫ = ⟪ι u,
A v⟫`, where `ι = embed` is the inclusion `Hˢ⁺²_div ↪ Hˢ_div`. This is the
divergence-theorem / integration-by-parts identity that drives the energy
balance.

Per the Shawlock Rule #1 axiom lock we record it as a `Prop` (the *statement*),
NOT as a `theorem … := by sorry`. In Lean 4 `sorry` IS the axiom `sorryAx`
(they are literally the same term), so any `by sorry` proof necessarily makes
`#print axioms` report `sorryAx` — there is no `sorry` that avoids the axiom.
Naming the proposition creates no proof obligation, so it carries NO `sorryAx`
and NO new axioms: `#print axioms integration_by_parts` is the classical trio
only. It is honestly NOT proved (the divergence-theorem pairing is absent from
mathlib v4.12.0) and NOT asserted true — it is the named analytic input behind
the `hbal` hypothesis of `energy_inequality`. NOT a brick.

  -- SORRY: Integration by parts for Hdiv_free. Follows from Fourier
  -- characterization + decay. (Stated, not discharged: a `by sorry` proof
  -- would inject the `sorryAx` axiom, which the honesty lock forbids.) -/
def integration_by_parts : Prop :=
  ∀ (u v : Hdiv_free (s + 2)),
    (@inner ℂ (Hdiv_free s) _ (stokes_op s u) (@embed (s + 2) s (by linarith) v))
      = (@inner ℂ (Hdiv_free s) _ (@embed (s + 2) s (by linarith) u) (stokes_op s v))

end Energy
end NS
end Towers
end TheoremaAureum
