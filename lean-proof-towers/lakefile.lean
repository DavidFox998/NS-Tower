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
  roots := #[`Towers.RH.ZeroDensity, `Towers.BSD.MordellWeil, `Towers.NS.Divergence, `Towers.NS.EnergyIneq, `Towers.YM.MassGap, `Towers.YM.SU3, `Towers.YM.SU3Basis, `Towers.YM.GaugeField, `Towers.YM.RealCurvature, `Towers.YM.RealCurvatureV2, `Towers.YM.Geometry, `Towers.YM.PlaquetteAction, `Towers.NS.Energy, `Towers.Spectral.Operator, `Towers.Spectral.OperatorV2, `Towers.NS.EnergyV2, `Towers.YM.Spectrum, `Towers.YM.Wilson, `Towers.YM.CloverF, `Towers.NS.RealH1Norm, `Towers.YM.Transfer, `Towers.YM.OSReconstruction, `Towers.YM.SpectralGap, `Towers.YM.ClusterExpansion, `Towers.Attempts.OSHilbert, `Towers.Attempts.Perron, `Towers.Attempts.UniformGap, `Towers.Attempts.Enstrophy, `Towers.Attempts.T_g, `Towers.Attempts.ClusterExpansion]
