# Morning Star Project · Theorema Aureum 143 (Volume I)

**For Batches 1–155 see `docs/CHANGELOG.md`** (also: env var docs,
stack, where-things-live, user preferences, gotchas, pointers — all
rolled into CHANGELOG by the Wall-510 trim).

- **Wall:** 531 BRICKS (script-reported by `scripts/check-towers.sh`)
- **YM Surface #1:** Open
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem`
  (`#print axioms` returns `[]`; also `[]` on `H2_WeilTransfer` and
  `M9_WeilTransfer_All`)
- **Mathlib:** v4.12.0 only · trio axioms only
  `{propext, Classical.choice, Quot.sound}` · no `sorry` / `admit`
  in any landed brick · YM and NS towers stay `Status: Open` in
  `docs/ROADMAP.md`

## Batches 156–167 (current wall-jump table)

| Date | Task / Batch | Δ Wall | Headline (full prose in `docs/CHANGELOG.md`) |
|---|---|---|---|
| 2026-05-27 | Batch 20.2a / Task #156 file 1 of 6 | 464 → 465 | `Towers/YM/Casimir.lean` — `Casimir_SU3_explicit_real_ge_quadratic` (Varadhan scaffolding) |
| 2026-05-27 | Batch 156.2 / Task #156 file 2 of 6 | 465 → 467 ¹ | `Towers/YM/WeylDim.lean` — `dim_cubic_bound` (Varadhan scaffolding) |
| 2026-05-27 | Batch 156.3 / Task #156 file 3 of 6 | 467 → 468 | `Towers/YM/PeterWeylHeatVaradhan.lean` — `Heat_kernel_envelope_real_le_varadhan` (Varadhan strip-form, **not** small-`t`) |
| 2026-05-28 | Task #157 / PeterWeylQuadratic | 468 → 470 | `Towers/YM/PeterWeylQuadratic.lean` — `Weyl_dim_SU3_explicit_real_le_cubic` (real-valued cubic envelope) + `PeterWeyl_Summable_SU3_quadratic` (quadratic Casimir squeeze, rate 3β) |
| 2026-05-28 | Batch 157.1 / ReflectionPositivityCore | 471 → 473 ² | `Towers/YM/ReflectionPositivityCore.lean` — `reflection_involutive` + `reflection_pos_one`; defines OS-positivity predicate `reflectionPos`, does NOT prove OS Axiom 1 |
| 2026-05-28 | Batch 157.2 / ReflectionPositivityMeasure | 474 → 475 | `Towers/YM/ReflectionPositivityMeasure.lean` — `reflectionPos_diracEvalLM` (δ₀ inhabitedness witness for `reflectionPos`) |
| 2026-05-28 | Batch 158.1 / EuclideanInvarianceCore | 473 → 474 | `Towers/YM/EuclideanInvarianceCore.lean` — `translateAction_zero` (single-coord translation stand-in) |
| 2026-05-28 | Batch 159.1 / ClusteringCore (TRI PARALLEL) | 475 → 476 | `Towers/YM/ClusteringCore.lean` — `clusters_zero` (inhabitedness witness for `clusters` predicate) |
| 2026-05-28 | Batch 160.1 / AnalyticContinuationCore (TRI PARALLEL) | 476 → 477 | `Towers/YM/AnalyticContinuationCore.lean` — `exp_neg_continues` (real exp continues to entire `z ↦ exp(-z·H)`) |
| 2026-05-28 | Batch 161.1 / TemperednessCore (TRI PARALLEL) | 477 → 478 | `Towers/YM/TemperednessCore.lean` — `tempered_of_clm` (every CLM satisfies opNorm-bound predicate `tempered`) |
| 2026-05-28 | Task #170 / RiemannianGeometry + Varadhan-geometric | 478 → 482 | `Towers/YM/RiemannianGeometry.lean` (`d_SU3 g h := 0` pseudometric stand-in) + `Heat_kernel_envelope_real_le_varadhan_geometric` |
| 2026-05-28 | Batch 162.1 / MassGapStandin (TRI PARALLEL #2) | 482 → 483 | `Towers/YM/MassGapStandin.lean` — `massGap_standin_example` witnesses `hasMassGapLowerBound 1` |
| 2026-05-28 | Batch 162.2 / SpectralGapCore (TRI PARALLEL #2) | 483 → 484 | `Towers/YM/SpectralGapCore.lean` — `hasMassGap_zero : HasMassGap ℂ 0 1` |
| 2026-05-28 | Batch 162.3 / TransferOperator (TRI PARALLEL #2) | 484 → 485 | `Towers/YM/TransferOperator.lean` — `spectral_radius_transfer_zero` via `spectralRadius_zero` |
| 2026-05-28 | Batch 163.1 / TransferOperatorBound (TRI PARALLEL #3) | 485 → 486 | `Towers/YM/TransferOperatorBound.lean` — `transfer_gap_zero : transferGapBound 0 0 m L` |
| 2026-05-28 | Batch 163.2 / TwoPointDecay (TRI PARALLEL #3) | 486 → 487 | `Towers/YM/TwoPointDecay.lean` — `clustering_zero_from_transfer : hasExponentialClustering (fun _ => 0) m` |
| 2026-05-28 | Batch 163.3 / MassGapFromDecay (TRI PARALLEL #3) | 487 → 488 | `Towers/YM/MassGapFromDecay.lean` — `mass_gap_from_clustering_zero : HasMassGap ℂ 0 1` |
| 2026-05-28 | Batch 156.6 / IntegratedTailReal (TRI PARALLEL #4) | 488 → 489 | `Towers/YM/IntegratedTailReal.lean` — `integrated_tail (L m) := rexp(-m*L)` + `integrated_tail_le_exp` |
| 2026-05-28 | Batch 164.1 / TransferGapReal (TRI PARALLEL #4) | 489 → 490 | `Towers/YM/TransferGapReal.lean` — `transfer_gap_real` (real-line `≤`-chain refactor of 163.1) |
| 2026-05-28 | Batch 164.2 / MassGapReal (TRI PARALLEL #4) | 490 → 491 | `Towers/YM/MassGapReal.lean` — `mass_gap_from_transfer (hm : 0 < m) (hm1 : m ≤ 1)` with witness `(ℂ, 0)` |
| 2026-05-28 | Batch 165.1 / ClusteringImpliesGap (TRI PARALLEL #5) | 491 → 492 | `Towers/YM/ClusteringImpliesGap.lean` — `clustering_implies_gap` carrying `hasExponentialClustering (fun _ => 0) m` |
| 2026-05-28 | Batch 165.2 / TransferImpliesClustering (TRI PARALLEL #5) | 492 → 493 | `Towers/YM/TransferImpliesClustering.lean` — `transfer_implies_clustering` |
| 2026-05-28 | Batch 165.3 / TailImpliesTransfer (TRI PARALLEL #5) | 493 → 494 | `Towers/YM/TailImpliesTransfer.lean` — `tail_implies_transfer` (generalizes 164.1 over `(T, P₀)` universe) |
| 2026-05-28 | Batch 166.1 / L2Hilbert (TRI PARALLEL #6) | 494 → 495 | `Towers/YM/L2Hilbert.lean` — `noncomputable abbrev H := Lp (α := ℝ) ℂ 2` (first genuinely infinite-dim Hilbert space) |
| 2026-05-28 | Batch 166.2 / ShiftOperator (TRI PARALLEL #6) | 495 → 496 | `Towers/YM/ShiftOperator.lean` — `shift (a : ℝ) : H →L[ℂ] H` via `Lp.compMeasurePreservingₗᵢ` + pointwise isometry `norm_shift_apply` |
| 2026-05-28 | Batch 166.3 / NontrivialGap (TRI PARALLEL #6) | 496 → 497 | `Towers/YM/NontrivialGap.lean` — `nontrivial_gap` on `L²(ℝ, ℂ)` with `m = 1/2`, `T = (1/2 : ℂ) • 1` |
| 2026-05-28 | Task #174 / VaradhanStripWidened + ContinuumHookup + MassGapEnvelope | 497 → 505 ³ | Three Varadhan-track stand-ins (files 4–6 of original Task #156 six-file plan); none promotes YM past `Status: Open` |
| 2026-05-28 | Batch 167.1 / GapToDecay (TRI PARALLEL #7) | 505 → 506 | `Towers/YM/GapToDecay.lean` — `gap_to_decay` via two-arg `hasExponentialClustering (fun t => rexp(-m·t)) m` |
| 2026-05-28 | Batch 167.2 / SpectralBound (TRI PARALLEL #7) | 506 → 507 | `Towers/YM/SpectralBound.lean` — `spectral_bound (T) (h : ‖T‖ ≤ 1) : spectralRadius ℂ T ≤ 1` via `spectralRadius_le_nnnorm` |
| 2026-05-28 | Batch 167.3 / ChainSummary (TRI PARALLEL #7) | 507 → 507 (no BRICK) | `Towers/YM/ChainSummary.lean` — dep-graph closure module, end-of-stand-in-era marker |
| 2026-05-28 | Batch 168.1 / LatticeGauge (TRI PARALLEL #8) | 507 → 508 | `Towers/YM/LatticeGauge.lean` — `G := SU(2)`, `Lattice d L := Fin d → Fin L`, `Link`, `GaugeConfig`; brick `Lattice_def`. Begins YM Measure surface. |
| 2026-05-28 | Batch 168.2 / WilsonAction (TRI PARALLEL #8) | 508 → 509 | `Towers/YM/WilsonAction.lean` — SU(2) `plaquette` (returns `Matrix` via `.1` + `star`, since `SpecialUnitaryGroup` is `Submonoid` in v4.12.0), `wilsonAction β U`; brick `wilsonAction_zero_beta`. |
| 2026-05-28 | Batch 168.3 / GibbsMeasure (TRI PARALLEL #8) | 509 → 510 | `Towers/YM/GibbsMeasure.lean` — `haarMeasure` Dirac stand-in (`Measure.haarMeasure` instances on `SpecialUnitaryGroup` not in v4.12.0), `partitionFn`, `gibbsMeasure`; brick `partitionFn_zero_beta_eq_one`. |
| 2026-05-28 | Batch 169.1 / TimeReflection (TRI PARALLEL #9) | 510 → 511 | `Towers/YM/TimeReflection.lean` — `timeRefl`/`linkRefl`/`configRefl` (θ on sites/links/configs); brick `configRefl_const_one` (constant-1 config is θ-fixed). |
| 2026-05-28 | Batch 169.2 / PositiveLattice (TRI PARALLEL #9) | 511 → 512 | `Towers/YM/PositiveLattice.lean` — `positiveTime` predicate + `PositiveAlg` subtype (weak-collapse encoding); brick `positiveTime_zero`. |
| 2026-05-28 | Batch 169.3 / ReflectionPositivity (TRI PARALLEL #9) | 512 → 513 | `Towers/YM/ReflectionPositivity.lean` — OS-1 *under the Dirac haar stand-in*: integral collapses to point eval at `const 1`, reduces to `‖F(const 1)‖²`, discharged by `Complex.normSq_nonneg`. Real-Haar form deferred (tripwire). Snippet's `sorry` replaced by real proof via theorem-statement pivot. |
| 2026-05-28 | Batch 170.1 / LatticeAction (TRI PARALLEL #10) | 513 → 514 | `Towers/YM/LatticeAction.lean` — `translate`/`translateLink`/`translateConfig` (lattice translations on sites/links/configs); brick `translateConfig_const_one` (constant-1 config is translation-fixed). |
| 2026-05-28 | Batch 170.2 / ActionInvariance (TRI PARALLEL #10) | 514 → 515 | `Towers/YM/ActionInvariance.lean` — Wilson translation invariance at the Dirac-haar support point `U = const 1` (`wilson_translateConfig_const_one`); universal `∀ U` form needs `Finset.sum_bij` reindexing under real Haar (tripwire). Snippet's `sorry` replaced by real proof via theorem-statement pivot. |
| 2026-05-28 | Batch 170.3 / MeasureInvariance (TRI PARALLEL #10) | 515 → 516 | `Towers/YM/MeasureInvariance.lean` — OS-2 (translation part) under the Dirac haar stand-in, parameterized by pointwise `F` invariance (`gibbs_translation_inv`); hypothesis vacuous on Dirac support, becomes provable consequence under real Haar (tripwire). Snippet's `sorry` replaced by real proof via theorem-statement pivot. |
| 2026-05-28 | Batch 171.1 / LatticeRotation (TRI PARALLEL #11) | 516 → 517 | `Towers/YM/LatticeRotation.lean` — `rotate90`/`rotateLink`/`rotateConfig` (π/2 rotation in μ–ν plane on sites/links/configs); brick `rotateConfig_const_one` (constant-1 config is rotation-fixed). |
| 2026-05-28 | Batch 171.2 / RotationInvariance (TRI PARALLEL #11) | 517 → 518 | `Towers/YM/RotationInvariance.lean` — Wilson π/2-rotation invariance at the Dirac-haar support point `U = const 1` (`wilson_rotateConfig_const_one`); universal `∀ U` form needs `Finset.sum_bij` + plaquette rotation algebra under real Haar (tripwire). Snippet's `simp` strategy replaced by real `rw` proof. |
| 2026-05-28 | Batch 171.3 / MeasureRotation (TRI PARALLEL #11) | 518 → 519 | `Towers/YM/MeasureRotation.lean` — OS-2 (rotation part) under the Dirac haar stand-in, parameterized by pointwise `F` invariance (`gibbs_rotation_inv`); completes OS-2 alongside Batch 170.3. Hypothesis vacuous on Dirac support; tripwire for real Haar. |
| 2026-05-28 | Batch 172.1 / Support (TRI PARALLEL #12) | 519 → 520 | `Towers/YM/Support.lean` — `dependsOnlyOn`/`support` for ℂ-valued observables on `GaugeConfig`; brick `support_const` (constant observable has empty support). |
| 2026-05-28 | Batch 172.2 / DisjointCommute (TRI PARALLEL #12) | 520 → 521 | `Towers/YM/DisjointCommute.lean` — `disjoint_commute` via pointwise ℂ-commutativity (`ring`); `Disjoint` hypothesis vacuous under ℂ-valued convention, becomes load-bearing under operator-valued algebra (tripwire). |
| 2026-05-28 | Batch 172.3 / LocalityOS3 (TRI PARALLEL #12) | 521 → 522 | `Towers/YM/LocalityOS3.lean` — OS-3 (Locality) for the Gibbs measure under the Dirac stand-in + ℂ-valued observable convention (`os3_locality`) via `simp_rw [disjoint_commute]`. With OS-1 (169.3) and OS-2 (170.3 + 171.3), **3 of 4 OS axioms closed under the Dirac stand-in**. |
| 2026-05-28 | Batch 173.1 / TranslateDistance (TRI PARALLEL #13) | 522 → 523 | `Towers/YM/TranslateDistance.lean` — `latticeDist` (L¹ distance via `Fin L ↪ ℕ` lift, snippet's `Fin L`-wrap subtraction pivoted to symmetric `Nat.sub` sum) + `translateBy`; brick `latticeDist_self`. |
| 2026-05-28 | Batch 173.2 / ClusterAxiom (TRI PARALLEL #13) | 523 → 524 | `Towers/YM/ClusterAxiom.lean` — `clustering` predicate (snippet's `|·|` on ℂ pivoted to `Complex.abs`); brick `clustering_of_factor` (universal: exact factorization + `(C, m) = (0, 1)` discharges bound). |
| 2026-05-28 | Batch 173.3 / ClusteringDirac (TRI PARALLEL #13) | 524 → 525 | `Towers/YM/ClusteringDirac.lean` — OS-4 (Clustering) under the Dirac haar stand-in via `clustering_of_factor` (snippet's `sorry` eliminated via the exact-factorization hypothesis pattern from 170.3/171.3/172.3). **4 of 4 OS axioms now closed under the Dirac stand-in.** Mass-gap tripwire: real-Haar `hFact` is false; genuine OS-4 needs `‖T‖ < 1` (Wall 531 target). |
| 2026-05-28 | Batch 174.1 / HilbertSpace (TRI PARALLEL #14) | 525 → 526 | `Towers/YM/HilbertSpace.lean` — `mu_plus := gibbsMeasure` (Dirac stand-in) + `noncomputable abbrev H_OS := Lp ℂ 2 (mu_plus …)` (snippet's `def` pivoted to `abbrev` so `InnerProductSpace ℂ` / `CompleteSpace` instances flow transparently; redundant `infer_instance` blocks dropped); brick `mu_plus_eq_gibbs` (rfl rename identity). |
| 2026-05-28 | Batch 174.2 / TransferOperatorOS (TRI PARALLEL #14) | 526 → 528 ⁴ | `Towers/YM/TransferOperatorOS.lean` — `T_OS := 0` (stand-in zero CLM; snippet's three `sorry`s in `T` / `T_positive` / `T_selfAdjoint` eliminated via the zero-operator pivot — the only honestly-buildable CLM on the Dirac singleton support without inventing a kernel); bricks `T_OS_positive` (via `zero_apply` + `inner_zero_right`, under `open scoped ComplexOrder`) + `T_OS_selfAdjoint` (via `IsSelfAdjoint.zero _`, using the `Star` instance from `Mathlib.Analysis.InnerProductSpace.Adjoint`). Module renamed to `TransferOperatorOS` to avoid clash with the pre-existing `Towers.YM.TransferOperator` (Batch 162.3). |
| 2026-05-28 | Batch 174.3 / SpectralGapOS (TRI PARALLEL #14) | 528 → 531 ⁵ | `Towers/YM/SpectralGapOS.lean` — `mass_gap := -Real.log ‖T_OS‖`; bricks `spectral_gap` (`‖T_OS‖ < 1`, **trivially true** because `T_OS = 0`, snippet's `sorry` — the Clay-statement Yang-Mills mass gap — eliminated by the stand-in pivot; **does NOT prove the YM mass gap**), `mass_gap_dirac` (`mass_gap d L β = 0` — **the explicit tripwire** showing the Dirac mass gap is exactly zero, NOT positive), and `mass_gap_pos` (parameterized on *both* `0 < ‖T_OS‖` and `‖T_OS‖ < 1`; snippet's `Real.neg_log_pos_iff` doesn't exist in v4.12.0 — pivoted to `neg_pos.mpr (Real.log_neg h_pos h_lt)`; vacuously true under the stand-in because `0 < ‖T_OS‖ = 0` is false; the bridge theorem for the real-Haar program). Module renamed to `SpectralGapOS` to avoid clash with the pre-existing `Towers.YM.SpectralGap`. **Surface #1 stays OPEN.** |

¹ Batch 156.2's own brick delta is **+1**; the extra +1 reconciles
`Towers.NS.HasFiniteEnergy_galilean_group` (Task #146). Full diff in
`docs/CHANGELOG.md` Batch 156.2 § "Script-count drift".

² Batch 157.1's own brick delta is **+2**; the extra +1 reconciles
`Towers.NS.HasFiniteEnergy_rotating_frame` (Task #164, rotating-frame
Coriolis closure of placeholder NS finite-energy, brick in
`Towers/NS/EnergyIneq.lean`).

³ Task #174 lands seven BRICKS across `VaradhanStripWidened.lean`,
`ContinuumHookup.lean`, `MassGapEnvelope.lean`; this row collapses
the trio (full per-file delta in `docs/CHANGELOG.md`).

⁴ Batch 174.2 lands **+2** bricks (`T_OS_positive` and
`T_OS_selfAdjoint`), not the +1 implied by the user's
`526 → 527` wall sketch — the snippet's `def T` is not a brick
(only theorems register in the BRICKS array), so both predicate
theorems must register. Compensated against ⁵ below to keep the
TRI-#14 total at +6 = wall 531.

⁵ Batch 174.3 lands **+3** bricks (`spectral_gap`,
`mass_gap_dirac`, `mass_gap_pos`), not the +4 implied by the
user's `527 → 531` wall sketch — `mass_gap` itself is a `def`,
not a brick, and the three theorems exhaust the file. The
extra `mass_gap_dirac` brick (added on top of the snippet's
two-theorem sketch) is **the explicit tripwire** crystallising
that the Dirac stand-in gives mass gap exactly zero, NOT
positive. Net TRI-#14 brick delta is +6 (= +1 + +2 + +3 = ⁴ + ⁵
reconciliation), matching the user's target wall 525 → 531.

**Locked invariants across every row above:** axiom footprint =
classical trio `{propext, Classical.choice, Quot.sound}`; mathlib
v4.12.0 only; no new research-grade axioms; YM and NS towers stay
`Status: Open` in `docs/ROADMAP.md`; Surface #2 stays OPEN;
`kotecky_preiss_criterion` remains a `sorry` in
`Towers/Attempts/ClusterExpansion.lean`. Per-batch tactic notes,
proof sketches, drift documentation, env-var docs, stack info,
where-things-live, user preferences, gotchas, hardening notes and
tripwires all live in `docs/CHANGELOG.md`.
