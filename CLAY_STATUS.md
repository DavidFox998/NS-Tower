# CLAY_STATUS — 13 witness-collapse bricks

**Date:** 2026-06-03 · **Author:** D. Fox · **Mathlib:** v4.12.0
**Full report:** `reports/CLAY_REPAIR_2026-06-03.md` · **Diff:**
`provenance/clay_repair.diff` · **Manifest:** `BUILD_MANIFEST_v2.7.json`

## Summary

| metric | value |
|---|---|
| bricks examined | 13 |
| non-vacuous `T_real > 0` proofs achieved | **0** |
| converted to named open `Prop` | **13** |
| de-registered from `scripts/check-towers.sh` | **13** |
| compile EXIT 0 (direct-lean) | 13 / 13 |
| axiom footprint | classical trio on all 13 |
| `sorry` / `sorryAx` / `admit` proof-terms | 0 |

**Verdict:** every one of the 13 was discharged only by a degenerate witness
(witness collapse). A genuine proof needs a real Wilson transfer operator /
SU(3) character theory absent from mathlib v4.12.0, so **none** is provable
non-vacuously. All 13 are now **OPEN** (named, unproven `Prop`s) and removed
from the brick set. No YM mass-gap / `μ > 0` / Surface-#1 claim is made;
Surface #1 stays OPEN.

## Per-module status

| Module | Open `Prop` | T_real bound | Status |
|---|---|---|---|
| `ClusteringCore` | `clusters_zero_OPEN.{u}` | none | OPEN / de-registered |
| `MassGapStandin` | `massGap_standin_example_OPEN` | none | OPEN / de-registered |
| `SpectralGapCore` | `hasMassGap_zero_OPEN` | none | OPEN / de-registered |
| `TransferOperatorBound` | `transfer_gap_zero_OPEN` | none | OPEN / de-registered |
| `TwoPointDecay` | `clustering_zero_from_transfer_OPEN` | none | OPEN / de-registered |
| `MassGapFromDecay` | `mass_gap_from_clustering_zero_OPEN` | none | OPEN / de-registered |
| `IntegratedTailReal` | `integrated_tail_le_exp_OPEN` | none | OPEN / de-registered |
| `TransferGapReal` | `transfer_gap_real_OPEN` | none | OPEN / de-registered |
| `MassGapReal` | `mass_gap_from_transfer_OPEN` | none | OPEN / de-registered |
| `ClusteringImpliesGap` | `clustering_implies_gap_OPEN` | none | OPEN / de-registered |
| `TransferImpliesClustering` | `transfer_implies_clustering_OPEN` | none | OPEN / de-registered |
| `TailImpliesTransfer` | `tail_implies_transfer_OPEN` | none | OPEN / de-registered |
| `GapToDecay` | `gap_to_decay_OPEN.{u}` | none | OPEN / de-registered |

All supporting predicate `def`s and imports preserved; conversion is in-place.
The `_OPEN` propositions name the as-written shapes and are, as written,
trivially satisfiable (disclosed honestly) — they do **not** assert the genuine
surface.
