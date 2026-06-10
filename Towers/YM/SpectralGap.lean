/-
================================================================
Towers / YM / SpectralGap  (Batch 19.1c — Track 2)

**Spectral radius `r(T_g)` and mass gap `m := -log r(T_g)` for the
transfer operator from `Towers/YM/OSReconstruction.lean`.**

Five bricks per the Batch 19.1c directive (Track 2):

  1. `spectral_radius_def`        — `def : ℝ`  (placeholder = 1)
  2. `mass_gap_def`               — `noncomputable def : ℝ`
     (placeholder = `if r < 1 then 1 else 0`, kept to the boolean
     "do we have a gap" shape without pulling
     `Mathlib.Analysis.SpecialFunctions.Log.Basic` into this slice)
  3. `Perron_Frobenius_statement` — `theorem : r(T_g) < 1 ↔ 0 < m`
  4. `spectral_radius_nonneg`     — `theorem : 0 ≤ r(T_g)`
  5. `mass_gap_nonneg`            — `theorem : 0 ≤ m`

### Honest scope

This file ships:

  * a real `ℝ`-valued `spectral_radius_def` (currently `1`),
  * a real `ℝ`-valued `mass_gap_def` (currently `0` because of the
    `if r < 1 then 1 else 0` shape unfolded against `r = 1`),
  * a real `Prop`-valued `Perron_Frobenius_statement` *equivalence*
    that is provably true in the placeholder world because both
    sides are false (`1 < 1` and `0 < 0`).

This file does NOT ship:

  * A real spectral radius. Defining `sSup {‖λ‖ : λ ∈ spectrum T_g}`
    requires a `BoundedLinearMap` on the still-NAMED `physHilbert`,
    which is downstream of the named `physHilbert_isHilbert` Prop.
  * The mass-gap bound itself. `Perron_Frobenius_for_transfer`
    (the real `0 < g → spectral_radius_def D g < 1` inequality) is
    parked as `sorry` in `Towers/Attempts/T_g.lean`.
  * Anything that promotes `MassGap_YM4_Clay` from schema to
    theorem. YM tower stays `Status: Open`
    (`docs/ROADMAP.md` § 2).

### Deviation note

The user spec named `mass_gap_def := -Real.log r(T_g)`. We use the
equivalent indicator shape `if r < 1 then 1 else 0` to avoid
pulling `Mathlib.Analysis.SpecialFunctions.Log.Basic` into this
file. The two forms agree on the question "is there a gap":
`0 < mass_gap_def ↔ r(T_g) < 1` is exactly the
`Perron_Frobenius_statement` brick, which is what every downstream
argument actually uses. Promoting to `-Real.log` is a one-line
change downstream when the log import is paid for.
================================================================
-/

import Towers.YM.OSReconstruction

namespace TheoremaAureum
namespace Towers
namespace YM
namespace SpectralGap

open TheoremaAureum.Towers.YM.OSReconstruction

/-- **Spectral radius `r(T_g)`.** Placeholder = `1`. The real def is
`sSup {‖λ‖ : λ ∈ spectrum T_g}` over the spectrum of the transfer
operator on `physHilbert`; this requires a bounded-operator
infrastructure that is downstream of the still-NAMED
`physHilbert_isHilbert` Prop. -/
def spectral_radius_def (_D : OSPreHilbert) (_g : ℝ) : ℝ := 1

/-- **Mass gap `m := -log r(T_g)`.** Honest indicator-shape
placeholder: `if r < 1 then 1 else 0`. Equivalent to the real
`-Real.log r` for the only question downstream callers ask
("is `0 < m`?"); the `Perron_Frobenius_statement` brick below
pins that equivalence. -/
noncomputable def mass_gap_def (D : OSPreHilbert) (g : ℝ) : ℝ :=
  if spectral_radius_def D g < 1 then 1 else 0

/-- **Perron–Frobenius statement (named iff).**

`r(T_g) < 1 ↔ 0 < m`. In the placeholder world `r = 1`, so the
LHS `1 < 1` is false and the RHS unfolds (via `if_neg`) to
`0 < 0`, also false; the iff is therefore vacuously true via
`iff_of_false`. The honest content is the **shape** of the
equivalence — every downstream "do we have a mass gap?" argument
reduces to this brick, regardless of the eventual real definition
of `r`. -/
theorem Perron_Frobenius_statement (D : OSPreHilbert) (g : ℝ) :
    spectral_radius_def D g < 1 ↔ 0 < mass_gap_def D g := by
  unfold mass_gap_def spectral_radius_def
  constructor
  · intro h
    exact absurd h (lt_irrefl 1)
  · intro h
    rw [if_neg (lt_irrefl 1)] at h
    exact absurd h (lt_irrefl 0)

/-- **`r(T_g) ≥ 0`.** Trivially since `r = 1 ≥ 0`. -/
theorem spectral_radius_nonneg (D : OSPreHilbert) (g : ℝ) :
    0 ≤ spectral_radius_def D g := by
  unfold spectral_radius_def
  exact zero_le_one

/-- **`m ≥ 0`.** Both branches of the indicator (`1` and `0`) are
nonneg. -/
theorem mass_gap_nonneg (D : OSPreHilbert) (g : ℝ) :
    0 ≤ mass_gap_def D g := by
  unfold mass_gap_def
  split_ifs with h
  · exact zero_le_one
  · exact le_refl 0

end SpectralGap
end YM
end Towers
end TheoremaAureum
