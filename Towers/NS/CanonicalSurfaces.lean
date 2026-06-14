/-
================================================================
Towers / NS / CanonicalSurfaces  —  HONEST open-surface registry (NS)
("Theoria tower separation", 2026-06-01)

A COMPILING registry (real `import`s + a real `def`), replacing the prior
doc-only `Towers/CanonicalSurfaces.lean`. It bundles the genuine Navier–Stokes
open surfaces under one named `Prop`, `NS_Open`.

NS-FREEZE NOTE: `Towers/NS/*` is otherwise frozen at the Clay boundary. This
file is added under an EXPLICIT user unfreeze order ("Unlock freeze on NS
Tower"). It is purely additive and references-only: it imports the existing NS
surface defs and NAMES them; it does NOT modify any frozen NS proof.

HONESTY NOTES (read before citing this file):
  * `NS_Open` is OPEN. It is a *conjunction of hypotheses*, NOT a theorem.
    Nothing here discharges either conjunct. No "NS solved" / "regularity
    proven" / "weak solutions exist (literally)" claim is made or implied.
  * The two genuine NS surfaces:
      - `enstrophy_bound_global_Surface`  (global H¹/enstrophy bound; discharging
        it is equivalent to 3D NS global regularity, i.e. Surface #1),
      - `leray_proj_ker_eq_grad_Surface`  (the global L²-orthogonal Helmholtz
        decomposition `ker P = gradSubmodule`).
  * These are NS-only. They are independent of the YM mass gap and of the
    Kotecký–Preiss criterion; this registry does NOT bundle YM with NS.
  * Axiom footprint: classical trio only `{propext, Classical.choice,
    Quot.sound}`. No `sorry` / `admit` / custom `axiom`.
================================================================
-/

import Towers.Attempts.Enstrophy
import Towers.NS.Leray

namespace TheoremaAureum.Towers.NS.CanonicalSurfaces

open TheoremaAureum.Towers.Attempts.Enstrophy
open TheoremaAureum.Towers.NS.Leray

/-- **THEORIA LOCK — Navier–Stokes open hypotheses.** The conjunction of the two
genuine NS open surfaces. This `Prop` is OPEN: it is asserted by NO theorem in
the codebase, and each conjunct is an unproved hypothesis (the global enstrophy
bound — equivalent to 3D NS global regularity — and the global L²-orthogonal
Helmholtz decomposition). Discharging either is OUT OF SCOPE. NO "NS solved"
claim; Surface #1 stays OPEN. -/
def NS_Open : Prop :=
  (∀ u, enstrophy_bound_global_Surface u) ∧
  (∀ s : ℝ, leray_proj_ker_eq_grad_Surface s)

end TheoremaAureum.Towers.NS.CanonicalSurfaces
