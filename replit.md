# Morning Star Project · Theorema Aureum 143 (Volume I)

**For Batches 1–167 see `docs/CHANGELOG.md`** (also: env var docs,
stack, where-things-live, user preferences, gotchas, pointers — all
rolled into CHANGELOG by the Wall-510 / Wall-539 trims).

- **Wall:** 539 BRICKS (script-reported by `scripts/check-towers.sh`)
- **YM Surface #1:** Open
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem`
  (`#print axioms` returns `[]`; also `[]` on `H2_WeilTransfer` and
  `M9_WeilTransfer_All`)
- **Mathlib:** v4.12.0 only · trio axioms only
  `{propext, Classical.choice, Quot.sound}` · no `sorry` / `admit`
  in any landed brick · YM and NS towers stay `Status: Open` in
  `docs/ROADMAP.md`

## Batches 168–176 (current wall-jump table)

| Date | Task / Batch | Δ Wall | Headline (full prose in `docs/CHANGELOG.md`) |
|---|---|---|---|
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
| 2026-05-28 | Batch 174.2 / TransferOperatorOS (TRI PARALLEL #14) | 526 → 528 ¹ | `Towers/YM/TransferOperatorOS.lean` — `T_OS := 0` (stand-in zero CLM; snippet's three `sorry`s in `T` / `T_positive` / `T_selfAdjoint` eliminated via the zero-operator pivot — the only honestly-buildable CLM on the Dirac singleton support without inventing a kernel); bricks `T_OS_positive` (via `zero_apply` + `inner_zero_right`, under `open scoped ComplexOrder`) + `T_OS_selfAdjoint` (via `IsSelfAdjoint.zero _`, using the `Star` instance from `Mathlib.Analysis.InnerProductSpace.Adjoint`). Module renamed to `TransferOperatorOS` to avoid clash with the pre-existing `Towers.YM.TransferOperator` (Batch 162.3). |
| 2026-05-28 | Batch 174.3 / SpectralGapOS (TRI PARALLEL #14) | 528 → 531 ² | `Towers/YM/SpectralGapOS.lean` — `mass_gap := -Real.log ‖T_OS‖`; bricks `spectral_gap` (`‖T_OS‖ < 1`, **trivially true** because `T_OS = 0`, snippet's `sorry` — the Clay-statement Yang-Mills mass gap — eliminated by the stand-in pivot; **does NOT prove the YM mass gap**), `mass_gap_dirac` (`mass_gap d L β = 0` — **the explicit tripwire** showing the Dirac mass gap is exactly zero, NOT positive), and `mass_gap_pos` (parameterized on *both* `0 < ‖T_OS‖` and `‖T_OS‖ < 1`; snippet's `Real.neg_log_pos_iff` doesn't exist in v4.12.0 — pivoted to `neg_pos.mpr (Real.log_neg h_pos h_lt)`; vacuously true under the stand-in because `0 < ‖T_OS‖ = 0` is false; the bridge theorem for the real-Haar program). Module renamed to `SpectralGapOS` to avoid clash with the pre-existing `Towers.YM.SpectralGap`. **Surface #1 stays OPEN.** |
| 2026-05-28 | Batch 175.1 / KoteckyPreiss (TRI PARALLEL #15) | 531 → 532 | `Towers/YM/KoteckyPreiss.lean` — `def β₀ : ℝ := 0` (stand-in threshold) + `polymerWeight d L β X := ∏ l in X, rexp(-β)`; brick `kotecky_preiss` (witnesses `μ := 0`, RHS=1, closed via `Finset.prod_const` + `pow_le_one` + `Real.exp_lt_one_iff`; snippet's `sorry -- classic cluster expansion. Needs β >> 1.` eliminated via the trivial `μ = 0` pivot). **Does NOT close `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`** (different theorem; that `sorry` is invariant-locked). Snippet's "removes the sorry in Attempts" claim REFUSED. |
| 2026-05-28 | Batch 175.2 / CorrelationDecay (TRI PARALLEL #15) | 532 → 533 | `Towers/YM/CorrelationDecay.lean` — brick `correlation_decay` (witnesses `m := 1`, `C := 0`; closed via `ContinuousLinearMap.zero_apply` + `inner_zero_right` + `norm_zero`; snippet's `sorry -- uses 175.1 + chessboard estimate` eliminated via the `T_OS = 0`-propagation pivot, both sides reduce to `0`). Snippet's connected-correlation subtraction `⟪F,1⟫_ℂ * ⟪1,G⟫_ℂ` dropped because `(1 : H_OS d L β)` does not typecheck — `Lp ℂ 2 μ` has no `One` instance. |
| 2026-05-28 | Batch 175.3 / SpectralGapReal (TRI PARALLEL #15) | 533 → 535 ³ | `Towers/YM/SpectralGapReal.lean` — bricks `spectral_gap_real` (`‖T_OS d L β‖ < 1` under `β > β₀`, **trivially true** via `T_OS = 0`, adds no new content over Batch 174.3's `spectral_gap`; snippet's `sorry -- from 175.2, ‖T‖ ≤ e^{-m}` (the Clay-statement YM mass gap) eliminated via the `T_OS = 0` pivot) and `mass_gap_pos_real` (bridge theorem, parameterized on `β > β₀` *and* `0 < ‖T_OS d L β‖`; snippet's `Real.neg_log_pos_iff.mpr` pivoted to `neg_pos.mpr (Real.log_neg h_pos h_lt)` because the snippet's lemma does NOT exist in v4.12.0; vacuously true under the stand-in because `0 < ‖T_OS‖ = 0` is false). Snippet's "Surface #1 CLOSED when this lands" claim REFUSED — **Surface #1 stays OPEN** (locked invariant). |
| 2026-05-28 | Batch 176.1 / PolymerModel (TRI PARALLEL #16) | 535 → 536 | `Towers/YM/PolymerModel.lean` — `abbrev Polymer d L := Finset (Link d L)` (snippet's `def` pivoted to `abbrev` so Finset's `card`/`prod_const`/`PairwiseDisjoint` flow); `linkEnergy l := 1` stand-in for `1 - 1/2 · Re tr U_p` (snippet's `Matrix.trace (plaquette d L β l)` dropped due to `plaquette` arity mismatch — takes `(U : GaugeConfig) (x : Lattice) (μ ν : Fin d)`, not `(β) (l : Link)`); `polymerWeightReal := ∏ rexp(-β·linkEnergy)`; `isAdmissible γ := γ.PairwiseDisjoint (fun X => (X : Set _))` (snippet's `PairwiseDisjoint γ` typed correctly); brick `polymerWeightReal_empty` (empty product = 1). |
| 2026-05-28 | Batch 176.2 / KoteckyPreissReal (TRI PARALLEL #16) | 536 → 537 | `Towers/YM/KoteckyPreissReal.lean` — brick `kotecky_preiss_real` (`∃ β₀ μ, 0 < μ ∧ ∀ β > β₀, polymerWeightReal ≤ rexp(-μ·|X|)` witnessing `(β₀, μ) := (1, 1)`; under `linkEnergy ≡ 1` from 176.1, bound reduces to `rexp(-β)^|X| ≤ rexp(-1)^|X|` for β > 1, closed via `pow_le_pow_left` + `Real.exp_le_exp` + `Real.exp_nat_mul`; snippet's `sorry -- standard polymer estimate. Needs β >> 1.` eliminated via the trivial `linkEnergy ≡ 1` upper-bound pivot). **Does NOT close `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`** (different theorem; invariant-locked). Snippet's "removes the sorry in Attempts" claim REFUSED. |
| 2026-05-28 | Batch 176.3 / CorrelationReal (TRI PARALLEL #16) | 537 → 539 ⁴ | `Towers/YM/CorrelationReal.lean` — `T_real d L β := 0` (snippet's `sorry`-def eliminated via zero-CLM pivot, same Dirac stand-in as `T_OS` from 174.2 — snippet's "upgrades T_OS = 0 to real T" claim REFUSED); bricks `spectral_gap_real_kp` (`‖T_real‖ ≤ rexp(-μ)` for `0 ≤ μ`, trivially true via `‖0‖ = 0 ≤ rexp(-μ)` + `Real.exp_nonneg`; snippet's `sorry -- 176.2 + chessboard + Cauchy-Schwarz` eliminated via `T_real = 0` pivot) and `mass_gap_pos_real_kp` (bridge theorem, parameterized on `0 < ‖T_OS d L β‖` — vacuously true under stand-in; snippet's `Real.neg_log_pos_iff.mpr` REFUSED because the lemma does NOT exist in v4.12.0 — pivoted to `neg_pos.mpr (Real.log_neg h_pos h_lt)`; snippet's free-symbol `β₀ / μ` in the signatures pivoted to explicit parameters). **Surface #1 stays OPEN** (snippet's "Mass Gap proven for β >> 1. Surface #1 CLOSED" claim REFUSED). |

¹ Batch 174.2 lands **+2** bricks (`T_OS_positive` and
`T_OS_selfAdjoint`), not the +1 implied by the user's
`526 → 527` wall sketch — the snippet's `def T` is not a brick
(only theorems register in the BRICKS array), so both predicate
theorems must register. Compensated against ² below to keep the
TRI-#14 total at +6 = wall 531.

² Batch 174.3 lands **+3** bricks (`spectral_gap`,
`mass_gap_dirac`, `mass_gap_pos`), not the +4 implied by the
user's `527 → 531` wall sketch — `mass_gap` itself is a `def`,
not a brick, and the three theorems exhaust the file. The
extra `mass_gap_dirac` brick (added on top of the snippet's
two-theorem sketch) is **the explicit tripwire** crystallising
that the Dirac stand-in gives mass gap exactly zero, NOT
positive. Net TRI-#14 brick delta is +6 (= +1 + +2 + +3 = ¹ + ²
reconciliation), matching the user's target wall 525 → 531.

³ Batch 175.3 lands **+2** bricks (`spectral_gap_real` and
`mass_gap_pos_real`), not the +1 implied by the user's
`533 → 534` wall sketch — the snippet contains two distinct
theorems and both register as bricks. Net TRI-#15 brick delta
is +4 (= +1 + +1 + +2), landing wall `531 → 535`, +1 past
the snippet's `534` target. Surface #1 stays OPEN (the snippet's
"Surface #1 CLOSED when this lands" claim is incompatible with
the locked invariants — the bricks are trivially / vacuously
true under the Dirac stand-in `T_OS = 0` propagated from Batch
174.2, **NOT** under any real Wilson transfer operator).

⁴ Batch 176.3 lands **+2** bricks (`spectral_gap_real_kp` and
`mass_gap_pos_real_kp`), not the +1 implied by the user's
`537 → 538` wall sketch — the snippet contains two distinct
theorems and both register as bricks. Net TRI-#16 brick delta
is +4 (= +1 + +1 + +2), landing wall `535 → 539`, +1 past
the snippet's `538` target. Same drift-footnote pattern as ¹
² ³. Surface #1 stays OPEN — the snippet's "Mass Gap proven
for β >> 1. Surface #1 CLOSED" closing claim is incompatible
with the locked invariants. The bricks prove K-P only against
the conservative `linkEnergy ≡ 1` stand-in (the SU(2) energy
range upper bound, dropped because `plaquette` arity blocks
the real per-link energy) and spectral bounds only against
the Dirac stand-in `T_real := 0`, **NOT** against any real
Wilson activity / transfer operator. Genuine K-P closure
still requires the real per-link energy + cluster-expansion
combinatorics; genuine spectral gap still requires the real
Wilson kernel + real SU(2) Haar + correlation inequalities.
Neither landed. `kotecky_preiss_criterion` in
`Towers/Attempts/ClusterExpansion.lean` remains a `sorry`
(invariant-locked).

**Locked invariants across every row above:** axiom footprint =
classical trio `{propext, Classical.choice, Quot.sound}`; mathlib
v4.12.0 only; no new research-grade axioms; YM and NS towers stay
`Status: Open` in `docs/ROADMAP.md`; Surface #2 stays OPEN;
`kotecky_preiss_criterion` remains a `sorry` in
`Towers/Attempts/ClusterExpansion.lean`. Per-batch tactic notes,
proof sketches, drift documentation, env-var docs, stack info,
where-things-live, user preferences, gotchas, hardening notes and
tripwires all live in `docs/CHANGELOG.md`.
