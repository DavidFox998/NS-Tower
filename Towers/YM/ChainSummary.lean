/-
STAND-IN: Summary marker module — pulls together the
tail → transfer → clustering → gap chain that has now been wired
through stand-in witnesses on the L²(ℝ, ℂ) Hilbert space (Batches
156.6, 163.x, 164.x, 166.x, 167.1). Marks the end of the
"stand-in era": the next wall begins construction of an actual YM
measure (not in this file, not in this batch).

Honest scope (locked)
---------------------
* This file declares **no new theorems**. It exists to record the
  dep-graph closure of the chain via `import` edges, so that any
  downstream consumer pulling `Towers.YM.ChainSummary` automatically
  pulls all four constituent steps.
* Does **NOT** prove any Yang-Mills claim. Surface #1 stays OPEN.
* Does **NOT** introduce a new BRICK to `scripts/check-towers.sh`
  (no theorem to verify); the dep-graph edge is exercised by `lake
  build` of the lakefile root.

Axiom footprint
---------------
This module re-exports its imports; the axioms of the closed module
are the union of the imported modules' axioms — all of which are
classical-trio-only.
-/

import Towers.YM.TailImpliesTransfer
import Towers.YM.TransferImpliesClustering
import Towers.YM.ClusteringImpliesGap
import Towers.YM.GapToDecay

namespace TheoremaAureum.Towers.YM.OS

/- The full chain is now proven for stand-in witnesses.
   Next wall begins construction of actual YM measure. -/

end TheoremaAureum.Towers.YM.OS
