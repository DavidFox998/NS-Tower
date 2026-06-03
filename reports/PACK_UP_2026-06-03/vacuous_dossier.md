# Vacuous Brick Dossier — `TheoremaAureum.Towers.YM.OS`
_Generated 2026-06-03T09:40:10Z · REPORT-ONLY (no rebuild, no deletion, no lake)_

**Scope.** Of the 25 registered bricks in the `TheoremaAureum.Towers.YM.OS`
namespace, these **13** are TRULY VACUOUS: each conclusion collapses to a
triviality under the Dirac/stand-in transfer operator (`T_OS = 0` /
`T_real = 0`), a zero-function witness (`fun _ => 0`), or a `rexp ≤ rexp`
pass-through. The remaining 12 OS bricks are GENUINE modeled lemmas and are
NOT in this set (Reflection×2, ReflectionPositivityMeasure, EuclideanInvariance,
AnalyticContinuation, Temperedness, TransferOperator×3, ShiftOperator,
NontrivialGap, SpectralBound).

**Static axiom scan:** 0 file-level `axiom`/`constant` declarations across all
13 (classical-trio only). Axiom *footprint* per brick is not recomputed here —
that needs `#print axioms` (a compile), and rebuild is forbidden under this
directive; the locked invariant records the trio `{propext, Classical.choice,
Quot.sound}` with no research-grade axioms.

**Honest replacement note:** none of the 13 has a non-vacuous replacement in
mathlib v4.12.0 — a real proof needs the Wilson transfer operator / SU(3)
spectral-gap machinery that is ABSENT from the stack. So all 13 are
STRUCTURALLY blocked, not blocked-pending-a-search.

---

## 1. `ClusteringCore.lean` :: `OS.clusters_zero`
- file: `lean-proof-towers/Towers/YM/ClusteringCore.lean`
- decl: `62:lemma clusters_zero {α : Type*} [MeasurableSpace α] (μ : Measure α) :`
- vacuity: zero–zero pair clusters trivially (μ-a.e. over the trivial pair)
- imported-by: (none — leaf)

## 2. `MassGapStandin.lean` :: `OS.massGap_standin_example`
- file: `lean-proof-towers/Towers/YM/MassGapStandin.lean`
- decl: `75:lemma massGap_standin_example : hasMassGapLowerBound 1 :=`
- vacuity: hasMassGapLowerBound 1 := ∃C,0<C ∧ 0<1 (stand-in predicate, no operator)
- imported-by: (none — leaf)

## 3. `SpectralGapCore.lean` :: `OS.hasMassGap_zero`
- file: `lean-proof-towers/Towers/YM/SpectralGapCore.lean`
- decl: `79:lemma hasMassGap_zero : HasMassGap ℂ (0 : ℂ →L[ℂ] ℂ) 1 := by`
- vacuity: HasMassGap ℂ (0:ℂ→L[ℂ]ℂ) 1 — witnessed by the ZERO operator
- imported-by: Towers.YM.NontrivialGap,Towers.YM.ClusteringImpliesGap Towers.YM.MassGapReal,Towers.YM.MassGapFromDecay Towers.YM.Continuum

## 4. `TransferOperatorBound.lean` :: `OS.transfer_gap_zero`
- file: `lean-proof-towers/Towers/YM/TransferOperatorBound.lean`
- decl: `82:lemma transfer_gap_zero (m L : ℝ) :`
- vacuity: transferGapBound with T=P₀=0 ⇒ ‖0-0‖=0 ≤ exp(-m·L)
- imported-by: Towers.YM.TwoPointDecay,Towers.YM.TailImpliesTransfer Towers.YM.TransferImpliesClustering

## 5. `TwoPointDecay.lean` :: `OS.clustering_zero_from_transfer`
- file: `lean-proof-towers/Towers/YM/TwoPointDecay.lean`
- decl: `82:lemma clustering_zero_from_transfer (m L : ℝ)`
- vacuity: hasExponentialClustering (fun _=>0) ⇒ |0| ≤ C·exp(-m·t)
- imported-by: Towers.YM.GapToDecay,Towers.YM.TransferImpliesClustering Towers.YM.ClusteringImpliesGap,Towers.YM.MassGapFromDecay

## 6. `MassGapFromDecay.lean` :: `OS.mass_gap_from_clustering_zero`
- file: `lean-proof-towers/Towers/YM/MassGapFromDecay.lean`
- decl: `76:lemma mass_gap_from_clustering_zero`
- vacuity: re-uses hasMassGap_zero (zero-operator witness)
- imported-by: (none — leaf)

## 7. `IntegratedTailReal.lean` :: `OS.integrated_tail_le_exp`
- file: `lean-proof-towers/Towers/YM/IntegratedTailReal.lean`
- decl: `73:lemma integrated_tail_le_exp (L m : ℝ) (_hm : 0 ≤ m) (_hL : 0 ≤ L) :`
- vacuity: integrated_tail L m := rexp(-m·L); bound is rexp ≤ rexp (le_refl)
- imported-by: Towers.YM.TailImpliesTransfer,Towers.YM.TransferGapReal

## 8. `TransferGapReal.lean` :: `OS.transfer_gap_real`
- file: `lean-proof-towers/Towers/YM/TransferGapReal.lean`
- decl: `67:theorem transfer_gap_real (T P₀ : ℂ →L[ℂ] ℂ) (m L : ℝ)`
- vacuity: def pass-through integrated_tail = rexp(-m·L); no real T
- imported-by: Towers.YM.MassGapReal

## 9. `MassGapReal.lean` :: `OS.mass_gap_from_transfer`
- file: `lean-proof-towers/Towers/YM/MassGapReal.lean`
- decl: `80:lemma mass_gap_from_transfer {m : ℝ} (hm : 0 < m) (hm1 : m ≤ 1) :`
- vacuity: witness (H,T):=(ℂ,0) — maximally trivial Hilbert space + zero op
- imported-by: (none — leaf)

## 10. `ClusteringImpliesGap.lean` :: `OS.clustering_implies_gap`
- file: `lean-proof-towers/Towers/YM/ClusteringImpliesGap.lean`
- decl: `70:theorem clustering_implies_gap (m : ℝ) (hm : 0 < m) (hm1 : m ≤ 1)`
- vacuity: from clustering(fun _=>0) to HasMassGap via (ℂ,0) witness
- imported-by: Towers.YM.ChainSummary

## 11. `TransferImpliesClustering.lean` :: `OS.transfer_implies_clustering`
- file: `lean-proof-towers/Towers/YM/TransferImpliesClustering.lean`
- decl: `61:theorem transfer_implies_clustering (m L : ℝ) (_hm : 0 < m)`
- vacuity: witnesses hasExponentialClustering (fun _=>0)
- imported-by: Towers.YM.ChainSummary

## 12. `TailImpliesTransfer.lean` :: `OS.tail_implies_transfer`
- file: `lean-proof-towers/Towers/YM/TailImpliesTransfer.lean`
- decl: `62:theorem tail_implies_transfer (m L : ℝ)`
- vacuity: pass-through integrated_tail = rexp(-m·L); no real tail
- imported-by: Towers.YM.ChainSummary

## 13. `GapToDecay.lean` :: `OS.gap_to_decay`
- file: `lean-proof-towers/Towers/YM/GapToDecay.lean`
- decl: `52:theorem gap_to_decay (m : ℝ) (_hm : 0 < m) (_hm1 : m < 1) :`
- vacuity: witness f t:=rexp(-m·t); |rexp| ≤ 1·rexp trivially
- imported-by: Towers.YM.ChainSummary

---

## Reverse-dependency summary (purge-impact)
- **Leaves (no importers):** ClusteringCore, MassGapStandin, MassGapFromDecay, MassGapReal.
- **Internal-only (imported solely by other vacuous modules or by non-brick glue `ChainSummary`):** TransferOperatorBound, TwoPointDecay, IntegratedTailReal, TransferGapReal, ClusteringImpliesGap, TransferImpliesClustering, TailImpliesTransfer, GapToDecay.
- **Entangled with GENUINE keepers:** `SpectralGapCore` is imported by **NontrivialGap** and **Continuum** (genuine bricks) — but only for its `HasMassGap` *definition*, not the vacuous `hasMassGap_zero` theorem.
- **`ChainSummary.lean`** is non-brick dep-graph glue (declares no theorem) importing 4 of the vacuous modules.
