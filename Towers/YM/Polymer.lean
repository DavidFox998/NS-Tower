/-
================================================================
Towers / YM / Polymer — re-export alias.

`Towers.YM.Polymer` is a thin re-export of the canonical polymer-expansion
model `Towers.YM.PolymerModel` (which defines `Polymer d L := Finset (Link d L)`,
`linkEnergy`, `polymerWeightReal`, `isAdmissible`, all in namespace
`TheoremaAureum.Towers.YM.LatticeGauge`). It exists so downstream modules can
`import Towers.YM.Polymer` under the short polymer name; the definitions and
the brick `polymerWeightReal_empty` live in `PolymerModel`. No new
declarations, no `sorry`, no axioms of its own.
================================================================
-/

import Towers.YM.PolymerModel
