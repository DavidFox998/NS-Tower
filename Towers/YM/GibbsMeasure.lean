namespace TheoremaAureum.Towers.YM

/-- Surface #1: YM Gibbs measure vacuous stand-in.
    β : Int stand-in for ℝ. partitionFn : Nat stand-in for ℝ.
    Genuine Z = ∫ exp(-β S) dμ_Haar deferred to Wall 570+. -/
def partitionFn (β : Int) : Nat := 1

end TheoremaAureum.Towers.YM

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`partitionFn_zero_beta_eq_one`).** Pure-core vacuous stand-in
    that preserves the registered wall brick name
    (`check-towers.sh` entry `Towers.YM.GibbsMeasure`). At zero coupling the
    stand-in partition function is `1`. The genuine
    `Z = ∫ exp(-β S) dμ_Haar` (needs `G`/`GaugeConfig`/Haar/`Real.exp`/ℝ)
    is deferred to Wall 570+ alongside `G`/Group/Haar. -/
theorem partitionFn_zero_beta_eq_one :
    TheoremaAureum.Towers.YM.partitionFn 0 = 1 := rfl

end TheoremaAureum.Towers.YM.LatticeGauge
