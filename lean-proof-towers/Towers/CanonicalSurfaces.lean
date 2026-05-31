/-
================================================================
Towers / CanonicalSurfaces  —  HONEST open-surface registry
(2026-05-31, "Vacuous Surface Purge + Honest Surface Promotion")

This module is a DOCUMENTATION INDEX. It deliberately contains no
`import`s, no `def`s, and no `theorem`s, so it cannot accidentally
assert anything. It records, in one place, which named open
`*_Surface` Props across `Towers/` carry GENUINE mathematical
content versus which are VACUOUS artifacts of the stand-in defs.

--------------------------------------------------------------------
NO `iff` IS CLAIMED. There is NO `NSGlobalRegularityHypothesis` and
NO homogeneous `List Surface`. The genuine surfaces below are NOT a
single "NS tower": FOUR of the six are Yang–Mills, TWO are
Navier–Stokes. None of them — alone or together — is equivalent to
NS global regularity or to the YM mass gap. Every surface stays OPEN.
This registry lives OUTSIDE `Towers/NS/` so it does not touch the NS
freeze; it only NAMES surfaces, it does not import or modify them.
--------------------------------------------------------------------

## GENUINE non-trivial open surfaces (6)

### Real-object surfaces (4) — stated over real mathlib objects

  Navier–Stokes (2):
    · `Towers.NS.Leray.leray_proj_ker_eq_grad_Surface (s : ℝ)`
        `ker (leray_proj s) = gradSubmodule s`
        Helmholtz/Leray decomposition over a real Hilbert space
        (`leray_proj = orthogonalProjection (divFreeSubmodule s)`).
    · `Towers.Attempts.Enstrophy.enstrophy_bound_global_Surface (u)`
        `∃ C, ∀ t, H1Norm_v2 u t ≤ C`
        Uniform-in-time bound on a REAL seminorm
        (`H1Norm_v2 u t = H1Norm u t = ‖u t 0‖`). CAVEAT: simplified
        seminorm, NOT the full H¹ Sobolev norm — mathlib v4.12.0 lacks
        `SobolevSpace.norm`.

  Yang–Mills (2):
    · `Towers.YM.Transfer.kotecky_preiss_criterion_Surface`
        `∃ β₀>0, ∀ β>β₀, ∃ gap>0, ∀ L f, (∫ f = 0) →`
        `   ‖T_L L β f‖ ≤ exp(-(β·gap)) · ‖f‖`
        Geometric decay of the REAL integral transfer `T_L` (genuine
        SU(3) Haar stack, `‖T_L‖ ≤ 1`).
    · `Towers.YM.Transfer.trivial_polymer_set_null_Surface (L) (γ)`
        `haarN (4·L⁴) {w | polymerEnergy (toGauge L w) γ = 0} = 0`
        Measure-zero statement over the REAL `haarN` measure.

### Modeled / shadow-object surfaces (2) — genuine STATEMENTS, but
    over a SCALAR shadow operator (necessary-not-sufficient; NOT a
    real mass-gap claim):

  Yang–Mills (2):
    · `Towers.Attempts.Clay.MassGap_YM4_Clay_Surface (T)`
        `∃ Δ, IsMassGap T Δ`, where `IsMassGap T Δ` unfolds to
        `HasMassGap ℂ (continuumOp T) Δ` and
        `continuumOp T = (1 - continuumScale T) • 1` is SCALAR on ℂ.
    · `Towers.YM.MassGap574.YM_mass_gap_Surface (d L n) (U)`
        `∃ m>0, spectrum_bound (H U) m`, where
        `H U = wilsonAction U • 𝟙` is the SCALAR shadow, NOT the real
        Wilson transfer operator.

## ABSTRACT placeholder-bundle hypotheses (4) — non-vacuous, but each
   asserts a NAMED `Prop` field of the placeholder `OSPreHilbert`
   bundle; necessary-not-sufficient, no concrete measure behind them:
    · `Towers.Attempts.T_g.Transfer_compact_Surface D` = `D.physHilbert_isHilbert`
    · `Towers.Attempts.OSHilbert.OS_positivity_for_Wilson_Surface D` = `D.reflectionPositive`
    · `Towers.Attempts.OSHilbert.Transfer_bounded_Surface D` = `D.timeZeroAlgebra_acts`
    · `Towers.Attempts.OSHilbert.Transfer_compact_Surface D` = `D.physHilbert_isHilbert`

## VACUOUS surfaces (11) — encode NOTHING; deprecated or flagged

  Deprecated to `Towers/Deprecated/` (whole files, both fully vacuous):
    · `…UniformGap.gap_uniform_in_Lambda_v2_Surface`
        `∃ δ₀>0, ∀ Λ, δ₀ ≤ δ₀`  — tautologously TRUE.
    · `…Perron.Perron_Frobenius_for_transfer_unconditional_Surface`
        `∀ g>0, ∃ lam, 0<lam<1`  — tautologously TRUE.

  Flagged in place (stand-in defs collapse them):
    Vacuously FALSE (`1 < 1`; can never be discharged):
      · `…ClusterExpansion.Strict_contraction_CE_real_Surface`
      · `…ClusterExpansion.Strict_contraction_real_strict_Surface`
      · `…ClusterExpansion.Spectral_radius_lt_one_strict_real_Surface`
      · `…T_g.Perron_Frobenius_for_transfer_Surface`
    Vacuously TRUE (`0 ≤ 1` / `1 ≤ 1` / `0 ≤ exp _`):
      · `…ClusterExpansion.Single_plaquette_bound_Surface`
      · `…ClusterExpansion.Polymer_decoupling_estimate_Surface`
      · `…ClusterExpansion.Inductive_activity_bound_Surface`
      · `…ClusterExpansion.Polymer_activity_bound_real_Surface`
      · `…ClusterExpansion.Single_plaquette_bound_SU3_Surface`

  Stand-in defs responsible: `spectral_radius_def := 1`,
  `Decay_constant_real := 1`, `Plaquette_action_def := 0`,
  `Polymer_activity_def := 0`, `Wilson_measure_gaussian_part := 1`,
  `mayer_K_constant := 1`, `Character_expansion_plaquette := 0`.

## STATUS
  YM: OPEN (conditional). NS: OPEN. HODGE: OPEN via AnalyticObstruction.
  SORRY: 0. Axioms: classical trio. No surface above is discharged.

This file is doc-only and is intentionally NOT a lakefile root.
================================================================
-/
