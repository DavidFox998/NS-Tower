/-
================================================================
Towers / Attempts / Enstrophy  (Batch 18 Track 3 — sorry-bearing stub)

**THIS FILE IS NOT A BRICK.** Deliberately excluded from BRICKS in
`scripts/check-towers.sh`. The theorem below is `sorry`-backed;
its `#print axioms` includes `sorryAx` and would fail the
{propext, Classical.choice, Quot.sound} footprint — that is *why*
it is not a brick. Per locked rule in `replit.md`: "Hard theorems
land in `Towers/Attempts/` as sorry-bearing stubs."

## What this file pins

The **global enstrophy bound** for 3D Navier-Stokes — i.e. the
Clay Navier-Stokes global regularity surface itself, restated in
the H¹-norm form: `‖∇u(t)‖_{L²} ≤ C` for all `t ≥ 0`, with `C`
depending only on the initial datum.

  * `enstrophy_bound_global` — there is a finite `C` bounding
    `H1Norm_v2 u t` uniformly in `t`. On the current
    `Towers.NS.EnergyV2` placeholder where `H1Norm_v2 := H1Norm`
    and `Dissipation := 0`, the inequality is vacuously closeable
    by `C := H1Norm u 0`; we leave the proof `sorry` anyway
    because the *real* statement — the one that promotes
    `NavierStokes_global_regular` — needs the upgraded
    `H1Norm_v2` (the real `L²` of `∇u(t)`) which has not landed
    and the global-in-time bootstrap argument that is the
    Clay surface.

## Honest-scope reminder

NS tower stays `Status: Open` (`docs/ROADMAP.md` § 3). The
headline target `NavierStokes_global_regular` does NOT auto-
promote: the schema in `Towers.NS.EnergyV2` (and downstream) is
guarded by the H¹-norm bound this file leaves `sorry`. The Batch
18 user prompt's "If all 3 compile as `theorem`, auto-promote"
is satisfied vacuously in the wrong direction — `theorem` here
compiles only because of `sorry`, so no promotion fires.

================================================================
-/

import Towers.NS.EnergyV2

namespace TheoremaAureum
namespace Towers
namespace Attempts
namespace Enstrophy

open TheoremaAureum.Towers.NS
open TheoremaAureum.Towers.NS.EnergyV2

/-- **Global enstrophy bound for 3D Navier-Stokes.**

For every velocity field `u : VelocityField` the H¹-norm of
`u(t)` is bounded by a finite constant `C` uniformly in `t`.
Discharging this is equivalent to the Clay 3D Navier-Stokes
global regularity statement (no finite-time blow-up of `‖∇u‖_{L²}`).
Proof is `sorry` — far outside the Towers scope. -/
theorem enstrophy_bound_global
    (u : VelocityField) :
    ∃ C : ℝ, ∀ t : ℝ, H1Norm_v2 u t ≤ C := by
  sorry

end Enstrophy
end Attempts
end Towers
end TheoremaAureum
