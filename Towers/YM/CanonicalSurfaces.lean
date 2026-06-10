/-
================================================================
Towers / YM / CanonicalSurfaces  —  HONEST open-surface registry (YM)
("Theoria tower separation", 2026-06-01)

A COMPILING registry (real `import`s + a real `def`), replacing the prior
doc-only `Towers/CanonicalSurfaces.lean`. It bundles the genuine, NON-vacuous
Yang–Mills open surfaces under one named `Prop`, `YM_Clay_Open`.

HONESTY NOTES (read before citing this file):
  * `YM_Clay_Open` is OPEN. It is a *conjunction of hypotheses*, NOT a theorem.
    Nothing in this file discharges any conjunct. No `m > 0`, no mass gap, no
    "Surface #1 closed" is claimed or implied.
  * These are the three GENUINE YM surfaces (not the vacuous stand-in Props):
      - `MassGap_YM4_Clay_Surface`  (the Clay 4D SU(3) mass-gap conclusion,
        over the placeholder `YM4_Continuum` schema),
      - `kotecky_preiss_criterion_Surface`  (real integral transfer `T_L`),
      - `YM_mass_gap_Surface`  (the SCALAR-shadow Wall-574 gap; the shadow `H`
        is NOT the real Wilson transfer operator).
  * `kotecky_preiss_criterion_Surface` stays INVARIANT-LOCKED OPEN. This file
    only NAMES it; it does not, and must not, discharge it.
  * The proven YM "wall" bricks (e.g. `Wall263_CoxeterSpectral`) are machine-
    checked lemmas about 600-cell / Coxeter geometry. They prove NO YM physics
    result, discharge NONE of the conjuncts below, and make NO mass-gap claim.
    They are deliberately NOT referenced here.
  * Axiom footprint: classical trio only `{propext, Classical.choice,
    Quot.sound}`. No `sorry` / `admit` / custom `axiom`.
================================================================
-/

import Towers.Attempts.Clay
import Towers.YM.Transfer
import Towers.YM.MassGap574

namespace TheoremaAureum.Towers.YM.CanonicalSurfaces

open TheoremaAureum.Towers.Attempts.Clay
open TheoremaAureum.Towers.YM.Transfer
open TheoremaAureum.YM_MassGap
open TheoremaAureum.Towers.YM.Continuum
open TheoremaAureum.Towers.YM.LatticeGauge

/-- **THEORIA LOCK — Yang–Mills Clay-type open hypotheses.** The conjunction of
the three genuine YM open surfaces, grouped here because they live in the YM
tower. This `Prop` is OPEN: it is asserted by NO theorem in the codebase, and
each conjunct is an unproved hypothesis (the Clay mass-gap conclusion, the
Kotecký–Preiss strict-positivity criterion for the real transfer operator, and
the scalar-shadow Wall-574 gap). Discharging any conjunct is OUT OF SCOPE and
would require the corresponding open mathematics. NO mass-gap / `m > 0` claim. -/
def YM_Clay_Open : Prop :=
  (∀ T : YM4_Continuum, MassGap_YM4_Clay_Surface T) ∧
  kotecky_preiss_criterion_Surface ∧
  (∀ (d L n : ℕ) [NeZero L] [NeZero n] (U : GaugeConfig d L),
      YM_mass_gap_Surface d L n U)

end TheoremaAureum.Towers.YM.CanonicalSurfaces
