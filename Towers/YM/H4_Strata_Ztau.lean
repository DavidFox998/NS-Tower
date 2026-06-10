/-
  H4_Strata_Ztau.lean  —  "Module A": the W(H₄) point-stabilizer computation.

  HONEST SCOPE.  This file MEASURES point-stabilizer orders `Sym(x)` in the real
  symmetry group `W(H₄)` of the 600-cell, by an ACTUAL group action over exact
  `ℤ[τ]` integer arithmetic (`τ² = τ + 1`).  The reusable engine (ℤ[τ]/Quat
  arithmetic, the 120-vertex table, the `W(H₄)` action, `Sym`, and the
  deterministic `decode`) now lives in the shared core `Towers.YM.H4Core`; this
  leaf only imports it, records the kernel-checked `tau_sq` / `vflat_card` facts,
  and runs the `#eval` measurements.  It is:

    • mathlib-FREE (Lean core only); NOT a brick; NOT in `scripts/check-towers.sh`'s
      BRICKS array.
    • `sorry`-free / `admit`-free / `sorryAx`-free / `native_decide`-free.

  It proves NO Yang–Mills / Navier–Stokes / Riemann / Bost / BSD result.  It
  makes NO mass-gap / μ>0 / Surface-#1 claim.  `Sym(x)` is the stabilizer of a
  finite point under the linear `W(H₄)` action — PURE FINITE GEOMETRY.  It is NOT
  keyed to any prime and is causally independent of any L-function value; no
  L-function "seal" is asserted or implied.

  OBSERVED RESULTS (geometry-first; see the `#eval`s below):
    • `Sym(origin) = 14400 = |W(H₄)|`, `Sym(vertex) = 120`.
    • For the Module-A witness primes `[2,3,19,191,1000000001119]` the geometry
      yields `[120, 20, 2, 2, 1]` (full nine: `[120,20,2,2,1,1,1,1,1]`).  This
      is the TRUE output of the deterministic `decode` (absolute-value remainder)
      in `Towers.YM.H4Core`; it does NOT match the earlier conjectured
      `[120,20,20,2,1]` — that `20` at `p=19` came from a different (signed)
      decode convention.  Per the proposal's own rule, the geometry wins and the
      table is updated.
    • Every observed `Sym` value divides 14400 (Lagrange — see `symDvd?`).  The
      universal statement `∀ p, Sym p ∣ 14400` is the order/stabilizer (Lagrange)
      theorem; it is VERIFIED computationally for the witnesses here, and is NOT
      asserted as a formal ∀-theorem in this mathlib-free leaf (that would need
      the group-theoretic Lagrange machinery from mathlib).
-/

import Towers.YM.H4Core

namespace H4Strata

/-! ### Cheap kernel-checked facts (classical trio; `#print axioms` below) -/

/-- `τ·τ = τ + 1`, i.e. `(0+1·τ)² = 1 + 1·τ`. -/
theorem tau_sq : zmul ⟨0, 1⟩ ⟨0, 1⟩ = (⟨1, 1⟩ : Ztau) := by decide

/-- The flat vertex table really has `960 = 120·8` integer entries. -/
theorem vflat_card : vflat.length = 960 := by rfl

/-! ### Measurements (`#eval`, compiled — not kernel `decide`) -/

-- |V| = 120  (= 960 / 8 ints per vertex)
#eval V.length
-- |W(H₄)| = 14400  (= Sym at the origin)
#eval Sym origin
-- Sym of a vertex = 120
#eval Sym ⟨⟨2,0⟩, ⟨0,0⟩, ⟨0,0⟩, ⟨0,0⟩⟩
-- Module-A witness primes → TRUE geometry output:  [120, 20, 2, 2, 1]
#eval [2, 3, 19, 191, 1000000001119].map symOf
-- Full nine witnesses → [120, 20, 2, 2, 1, 1, 1, 1, 1]
#eval [2, 3, 19, 191, 1000000001119, 1000000000117, 1000000000189,
       1000000000273, 1000000000327].map symOf
-- Lagrange: every observed Sym divides 14400 → [true, true, true, true, true]
#eval [2, 3, 19, 191, 1000000001119].map symDvd?

#print axioms tau_sq
#print axioms vflat_card

end H4Strata
