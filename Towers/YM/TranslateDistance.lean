/-
================================================================
Towers / YM / TranslateDistance (Batch 173.1 / TRI PARALLEL #13, file 1 of 3)

**Definition module.** Introduces the L¹ lattice distance and the
pull-back action of a lattice translation on ℂ-valued observables:

  * `latticeDist x y` — coordinate-wise L¹ distance on
    `Lattice d L` valued in `ℕ`. Uses the truncated-natural
    subtraction `(x i : ℕ) - (y i : ℕ) + ((y i : ℕ) - (x i : ℕ))`
    (which equals `|↑(x i) - ↑(y i)|` on ℕ since one of the two
    `Nat.sub` terms is zero) so the result is honest-distance
    *under the lift `Fin L ↪ ℕ`* rather than the wrapping
    `Fin L`-subtraction in the snippet.
  * `translateBy v F` — translates a ℂ-valued observable by
    `v ∈ Lattice d L` via the pull-back convention
    `(translateBy v F) U := F (translateConfig (-v) U)`, matching
    the left-action convention from Batch 170.1.

Plus one brick: `latticeDist_self` — the distance from a site
to itself is `0` (load-bearing for OS-4 clustering at `v = 0`).

## Honest scope (locked)
* Definitions only, plus the diagonal-zero brick. Does NOT prove
  OS-4 clustering (that is Batches 173.2 and 173.3); does NOT
  prove the triangle inequality, symmetry, or any further
  metric-space structure (not needed for the OS-4 statement).
  Surface #1 stays OPEN.

## Drift from snippet
* (1) **`Fin L` wrap pivot.** Snippet wrote
  `∑ i, if x i ≥ y i then x i - y i else y i - x i` with
  `x i, y i : Fin L`. Two problems:
    - `x i - y i` on `Fin L` is *modular* subtraction (wraps
      around `L`), not the natural-number distance the
      OS-4-clustering definition needs (it would make
      `latticeDist` distance-zero on antipodal points).
    - The if-then-else returns `Fin L`, but the function
      signature declares result `ℕ` — so the `∑` would
      typecheck at `Fin L` (or `ℕ` via coercion) but the
      *value* would be wrong.
  Honest pivot: coerce each coordinate to `ℕ` first via
  `(x i : ℕ)`, then use the symmetric ℕ-subtraction sum
  `(x i : ℕ) - (y i : ℕ) + ((y i : ℕ) - (x i : ℕ))`, which is
  `Nat.sub`-safe (one of the two terms is `0` and the other is
  the honest difference) and gives the genuine L¹ distance on
  the unwrapped sites. The if-then-else is unnecessary under
  this formulation.
* (2) **Namespace widen.** Snippet's `TheoremaAureum.Towers.YM`
  is widened to `TheoremaAureum.Towers.YM.LatticeGauge` to match
  the Batch 168.x / 169.x / 170.x / 171.x / 172.x files.
* (3) **Brick add.** Snippet had no theorem — under the +1 wall
  jump accounting (`522 → 523`), this file must land one brick.
  Added `latticeDist_self`: `latticeDist d L x x = 0` (proved by
  `simp [latticeDist]` since each summand `n - n + (n - n) = 0`).

## Tripwire
The genuine OS-4 statement uses *Euclidean* distance on the
infinite-volume continuum, not the periodic L¹ distance on a
finite lattice. The replacement chain is: real-Haar Gibbs →
thermodynamic limit (infinite volume, removes the
`Fin L`-periodicity) → continuum limit (replaces lattice
spacing `a → 0`, recovering the Euclidean distance). All three
limits are deferred. Surface #1 stays OPEN.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is a
single `simp` over `Finset.sum` and `Nat.sub_self`.
================================================================
-/

import Towers.YM.LatticeAction

namespace TheoremaAureum.Towers.YM.LatticeGauge

open BigOperators

/-- **`latticeDist`** — L¹ distance on `Lattice d L`, valued in
    `ℕ`, via the lift `Fin L ↪ ℕ`. Symmetric in `x`/`y` because
    `Nat.sub` truncates: at each coordinate exactly one of
    `(x i : ℕ) - (y i : ℕ)` or `(y i : ℕ) - (x i : ℕ)` is the
    honest difference and the other is `0`. -/
def latticeDist (d L : ℕ) (x y : Lattice d L) : ℕ :=
  ∑ i, ((x i : ℕ) - (y i : ℕ) + ((y i : ℕ) - (x i : ℕ)))

/-- **`translateBy`** — pull-back of a ℂ-valued observable by
    a lattice translation, using the same left-action convention
    as `translateConfig` (Batch 170.1). -/
def translateBy (d L : ℕ) [NeZero L]
    (v : Lattice d L) (F : GaugeConfig d L → ℂ) :
    GaugeConfig d L → ℂ :=
  fun U => F (translateConfig d L (-v) U)

/-- **Brick (`latticeDist_self`).** The L¹ distance from any
    site to itself is `0`. Each summand reduces to
    `(x i : ℕ) - (x i : ℕ) + ((x i : ℕ) - (x i : ℕ)) = 0` via
    `Nat.sub_self`, and the sum of zeros is `0`. -/
theorem latticeDist_self (d L : ℕ) (x : Lattice d L) :
    latticeDist d L x x = 0 := by
  simp [latticeDist]

end TheoremaAureum.Towers.YM.LatticeGauge
