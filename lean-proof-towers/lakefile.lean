import Lake
open Lake DSL

package «theorema-aureum-towers» where

-- Sibling package to `lean-proof/`. Holds the mathlib-backed first
-- bricks for the open towers (RH / Yang-Mills / Navier-Stokes).
-- Kept separate so adding mathlib here does NOT slow down the fast
-- spine drift guard (`scripts/check-lean-proof.sh`), which builds
-- the no-mathlib `lean-proof/` package in seconds.
--
-- Cost (cold cache): `lake exe cache get` fetches ~2 GB of prebuilt
-- mathlib oleans the first time. `scripts/check-towers.sh` is the
-- canonical entry point.

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.12.0"

@[default_target]
lean_lib Towers where
  roots := #[`Towers.RH.ZeroDensity, `Towers.BSD.MordellWeil, `Towers.NS.Divergence, `Towers.NS.EnergyIneq, `Towers.YM.MassGap, `Towers.YM.SU3, `Towers.YM.SU3Basis, `Towers.YM.GaugeField, `Towers.YM.RealCurvature, `Towers.YM.RealCurvatureV2, `Towers.YM.Geometry, `Towers.YM.PlaquetteAction, `Towers.NS.Energy, `Towers.Spectral.Operator, `Towers.Spectral.OperatorV2, `Towers.NS.EnergyV2, `Towers.YM.Spectrum, `Towers.YM.Wilson, `Towers.YM.CloverF, `Towers.NS.RealH1Norm, `Towers.YM.Transfer, `Towers.YM.OSReconstruction, `Towers.YM.SpectralGap, `Towers.YM.ClusterExpansion, `Towers.YM.PeterWeyl, `Towers.YM.PeterWeylHeat, `Towers.Attempts.OSHilbert, `Towers.Attempts.Perron, `Towers.Attempts.UniformGap, `Towers.Attempts.Enstrophy, `Towers.Attempts.T_g, `Towers.Attempts.ClusterExpansion, `Towers.YM.Continuum, `Towers.Attempts.Clay, `Towers.YM.Casimir, `Towers.YM.WeylDim, `Towers.YM.RiemannianGeometry, `Towers.YM.PeterWeylHeatVaradhan, `Towers.YM.PeterWeylQuadratic, `Towers.YM.HeatTraceBound, `Towers.YM.OffDiagKernel, `Towers.YM.IntegratedTail, `Towers.YM.ReflectionPositivityCore, `Towers.YM.ReflectionPositivityMeasure, `Towers.YM.EuclideanInvarianceCore, `Towers.YM.ClusteringCore, `Towers.YM.AnalyticContinuationCore, `Towers.YM.TemperednessCore, `Towers.YM.MassGapStandin, `Towers.YM.SpectralGapCore, `Towers.YM.TransferOperator, `Towers.YM.TransferOperatorBound, `Towers.YM.TwoPointDecay, `Towers.YM.MassGapFromDecay, `Towers.YM.IntegratedTailReal, `Towers.YM.TransferGapReal, `Towers.YM.MassGapReal, `Towers.YM.ClusteringImpliesGap, `Towers.YM.TransferImpliesClustering, `Towers.YM.TailImpliesTransfer, `Towers.YM.L2Hilbert, `Towers.YM.ShiftOperator, `Towers.YM.NontrivialGap, `Towers.YM.VaradhanStripWidened, `Towers.YM.ContinuumHookup, `Towers.YM.MassGapEnvelope, `Towers.YM.GapToDecay, `Towers.YM.SpectralBound, `Towers.YM.ChainSummary, `Towers.YM.LatticeGauge, `Towers.YM.WilsonAction, `Towers.YM.GibbsMeasure, `Towers.YM.TimeReflection, `Towers.YM.PositiveLattice, `Towers.YM.ReflectionPositivity, `Towers.YM.LatticeAction, `Towers.YM.ActionInvariance, `Towers.YM.MeasureInvariance, `Towers.YM.LatticeRotation, `Towers.YM.RotationInvariance, `Towers.YM.MeasureRotation, `Towers.YM.Support, `Towers.YM.DisjointCommute, `Towers.YM.LocalityOS3, `Towers.YM.TranslateDistance, `Towers.YM.ClusterAxiom, `Towers.YM.ClusteringDirac, `Towers.YM.HilbertSpace, `Towers.YM.TransferOperatorOS, `Towers.YM.SpectralGapOS]
