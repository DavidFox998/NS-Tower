---
name: OS-namespace vacuity split (YM transfer-operator bricks)
description: Which Towers.YM.OS bricks are vacuous-under-Dirac vs genuine, and why the vacuous files can't be deleted wholesale.
---

# `TheoremaAureum.Towers.YM.OS` vacuity split

The OS namespace has **25 registered bricks**. Auditing them (unfold the transfer
operator / witness, not just grep names) splits cleanly:

- **13 VACUOUS** — conclusion collapses to a triviality under a Dirac/stand-in
  transfer operator (`T_OS=0`/`T_real=0`), a zero-function witness (`fun _=>0`),
  or a `rexp ≤ rexp` pass-through:
  ClusteringCore.clusters_zero, MassGapStandin.massGap_standin_example,
  SpectralGapCore.hasMassGap_zero, TransferOperatorBound.transfer_gap_zero,
  TwoPointDecay.clustering_zero_from_transfer,
  MassGapFromDecay.mass_gap_from_clustering_zero,
  IntegratedTailReal.integrated_tail_le_exp, TransferGapReal.transfer_gap_real,
  MassGapReal.mass_gap_from_transfer, ClusteringImpliesGap.clustering_implies_gap,
  TransferImpliesClustering.transfer_implies_clustering,
  TailImpliesTransfer.tail_implies_transfer, GapToDecay.gap_to_decay.
- **12 GENUINE** — real norm/inequality/analyticity facts over modeled objects,
  NOT vacuous: Reflection×2, ReflectionPositivityMeasure, EuclideanInvariance,
  AnalyticContinuation (`exp_neg_continues`), Temperedness, TransferOperator×3
  (`boltzmannWeight=exp(−S)>0`), ShiftOperator (`norm_shift_apply`, real isometry),
  NontrivialGap (`T=½•1` witness), SpectralBound (Gelfand).

**Why this matters / how to apply:** a literal "delete all stand-in / Dirac
transfer-operator bricks" pass is WRONG — it would also delete the 12 genuine
modeled lemmas. Only the 13 above are vacuous.

**Entanglement trap (purge-impact):** the vacuous `SpectralGapCore` file cannot
be deleted wholesale — its `HasMassGap` **definition** is imported by the GENUINE
keepers `NontrivialGap` and `Continuum`. To purge, drop only the `hasMassGap_zero`
*theorem* + its brick entry and keep the def. The other 12 vacuous modules plus
the non-brick glue `ChainSummary.lean` (declares no theorem) are removable without
breaking a genuine brick.

**Replacement reality:** none of the 13 has a non-vacuous replacement in mathlib
v4.12.0 — needs the real Wilson transfer operator / SU(3) spectral-gap machinery
absent from the stack. They are structurally blocked, not pending-a-search.
