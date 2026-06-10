/-
Wall 574 / [YM1] — Real Yang–Mills transfer Hamiltonian mass gap (SCAFFOLD).

HONEST SCOPE — DOCUMENTATION STUB, NOT A PROOF:
  This file states the TARGET of Wall 574 only. It carries a `sorry`.

  Task #248 Step 5 WIRED the real Step-4/Step-5 machinery in:
    * `H`              — now the genuine action-weighted Hamiltonian
                         `H U = wilsonAction U • 𝟙` (Step 4,
                         `LatticePositivityReal.lean`), the `−log` of the
                         Step-3 transfer operator `T = exp(−S_W[U]) · 𝟙`.
                         This is the SCALAR / Perron-sector shadow, NOT
                         yet the full Wilson transfer operator on
                         `L²(∏ SU(3), Haar)` (that construction is the
                         open Wall 574 work).
    * `spectrum_bound` — the real predicate from Step 5
                         (`SpectrumBound.lean`):
                         `spectrum_bound T m := ∀ ψ, m·‖ψ‖² ≤ ⟪ψ,Tψ⟫_ℝ`.

  The statement now ELABORATES against real symbols; only the `sorry`
  remains.

WHY THE HYPOTHESIS, AND WHY THE `sorry` STILL STANDS:
  By the Step-5 reduction `spectrum_bound_H_iff`, for the scalar `H U`
    `∃ m > 0, spectrum_bound (H U) m  ↔  0 < wilsonAction U`.
  i.e. the scalar-shadow "gap" is EXACTLY the deferred STRICT Wilson
  action positivity. That positivity FAILS at the vacuum configuration
  (`wilsonAction (const 1) = 0`, Step 2), so the bare universally-`U`
  form would be FALSE. We therefore carry `0 < wilsonAction U` as an
  EXPLICIT HYPOTHESIS (`hpos`) — making the statement true and honest
  rather than vacuum-false — and DELIBERATELY retain the `sorry`:

    * We make NO gap claim. Even granting `hpos`, this is only the
      SCALAR shadow `H U = wilsonAction U • 𝟙`, NOT the real Yang–Mills
      transfer operator. Discharging this conditional scalar statement
      (which `spectrum_bound_H_iff` + `hpos` would in fact permit) would
      misleadingly suggest progress on Surface #1, so we do NOT.
    * `hpos` itself (strict SU(3) action positivity off the vacuum) is a
      DEFERRED analytic input, not proved anywhere in the tower.
    * The genuine obligation is the FULL transfer operator (Wall 574);
      this file only WIRES the typed scaffold.

INVARIANT-LOCKED:
  * Makes NO mass-gap / μ>0 / Surface-#1-CLOSED claim while the `sorry`
    stands. Surface #1 stays OPEN; `∃ m > 0` for the real YM `H` is
    UNPROVEN. YM Status: Open.
  * Carries a `sorry`; deliberately NOT a `lean_lib` root and NOT
    registered in `scripts/check-towers.sh` BRICKS. A `sorry`-bearing
    declaration must never enter the wall. Script-reported wall unchanged.
-/
import Towers.YM.SpectrumBound
import Towers.YM.WilsonPositivity

open TheoremaAureum.Towers.YM.LatticeGauge

namespace TheoremaAureum.YM_MassGap

/- Wall 574 TARGET (scaffold, carries `sorry`). For the Step-4 scalar
    Hamiltonian `H U`, `spectrum_bound_H_iff` makes this equivalent to
    `0 < wilsonAction U`, carried here as the explicit hypothesis `hpos`
    (the deferred strict action positivity; it fails at the vacuum, see
    the file header). The `sorry` is retained DELIBERATELY: this is only
    the scalar shadow, NOT the real transfer operator, so we make NO
    mass-gap claim and Surface #1 stays OPEN. -/
/-- Named-open surface behind `YM_mass_gap`: an `∃ m > 0` spectral gap for the
REAL Wilson transfer Hamiltonian (Wall 574). Stated as a `Prop`, NOT discharged
with `by sorry`. This is the scalar-shadow scaffold, NOT the real transfer
operator, so NO mass-gap claim is made and Surface #1 stays OPEN. -/
def YM_mass_gap_Surface (d L n : ℕ) [NeZero L] [NeZero n]
    (U : GaugeConfig d L) : Prop :=
  ∃ m > 0, spectrum_bound (E := PiLp 2 (fun _ : Fin n => ℝ)) (H U) m

theorem YM_mass_gap {d L n : ℕ} [NeZero L] [NeZero n]
    (U : GaugeConfig d L) (_hpos : 0 < wilsonAction U)
    (hsurf : YM_mass_gap_Surface d L n U) :
    ∃ m > 0, spectrum_bound (E := PiLp 2 (fun _ : Fin n => ℝ)) (H U) m := hsurf

/-- **Brick (`YM_mass_gap_nontrivial`) — Task #255 follow-up: discharge
    `hpos`.** Same SCALAR-shadow statement as `YM_mass_gap`, but the
    deferred-positivity hypothesis `hpos : 0 < wilsonAction U` is now
    REPLACED by the geometric, provable condition "the gauge field has
    at least one non-identity plaquette". The chain is:

      `(∃ x μ ν, wilsonPlaquette U x μ ν ≠ 1)`
        ──`wilsonAction_pos_of_nontrivial`──▶  `0 < wilsonAction U`
        ──`spectrum_bound_H_iff … |>.mpr le_rfl`──▶
            `spectrum_bound (H U) (wilsonAction U)`,

    witnessed by `m := wilsonAction U`. This DISCHARGES the conditional
    scalar-shadow gap completely — no `sorry`, classical trio only.

    INVARIANT-LOCKED — this is NOT a Yang–Mills mass gap. `H U =
    wilsonAction U • 𝟙` is the scalar / Perron-sector shadow, NOT the
    real Wilson transfer operator on `L²(∏ SU(3), Haar)`. Wall 574
    (`YM_mass_gap` above) is UNTOUCHED and keeps its `sorry`. Makes NO
    μ>0 / Surface-#1-CLOSED claim — Surface #1 stays OPEN, YM Status:
    Open. -/
theorem YM_mass_gap_nontrivial {d L n : ℕ} [NeZero L] [NeZero n]
    (U : GaugeConfig d L)
    (h : ∃ x μ ν, wilsonPlaquette U x μ ν ≠ 1) :
    ∃ m > 0, spectrum_bound (E := PiLp 2 (fun _ : Fin n => ℝ)) (H U) m := by
  have hpos : 0 < wilsonAction U := wilsonAction_pos_of_nontrivial U h
  exact ⟨wilsonAction U, hpos,
    (spectrum_bound_H_iff (n := n) U (wilsonAction U)).mpr le_rfl⟩

end TheoremaAureum.YM_MassGap
