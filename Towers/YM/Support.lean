/-
================================================================
Towers / YM / Support (Batch 172.1 / TRI PARALLEL #12, file 1 of 3)

**Definition module.** Introduces the support of a ℂ-valued
observable on `GaugeConfig`:

  * `dependsOnlyOn F S` — `F` agrees on configurations that agree
    on `S` (a sufficient condition for "supp F ⊆ S").
  * `support F` — the set of links `l` such that there exist two
    configurations `U`, `V` agreeing off `{l}` for which
    `F U ≠ F V` (the necessary "supp F"). Standard
    "smallest determining set" definition.

Plus one brick: `support_const` — a constant observable has
empty support (load-bearing for sanity checks of OS-3 in later
batches; also confirms the `support` definition extracts the
"observable-dependence" intuition correctly).

## Honest scope (locked)
* Definitions only, plus the constant-observable brick.
  Does NOT prove disjoint-support commutation (that is Batch
  172.2); does NOT prove OS-3 (that is Batch 172.3).
  Surface #1 stays OPEN.

## Drift from snippet
* (1) Snippet had two `def`s only and no theorem; per the
  TRI #12 wall accounting (`519 → 520`), this file must land
  one brick. Honest pivot: add `support_const` (constant
  observable has empty support) as the brick — it is a one-line
  proof from the definition (`ext l; simp [support]` reduces
  the membership `l ∈ support (fun _ => c)` to `¬ True`, hence
  `False`, hence `l ∈ ∅`).
* (2) Snippet's `namespace TheoremaAureum.Towers.YM` is widened
  to `TheoremaAureum.Towers.YM.LatticeGauge` to match the
  Batch 168.x / 169.x / 170.x / 171.x files.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — the brick is `ext`
plus `simp`, both of which use only the trio.
================================================================
-/

import Towers.YM.LatticeGauge

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **`dependsOnlyOn F S`** — `F` agrees on any two configurations
    that agree on every link in `S`. Sufficient (and standard)
    characterization of "support of `F` is contained in `S`". -/
def dependsOnlyOn (d L : ℕ) (F : GaugeConfig d L → ℂ)
    (S : Set (Link d L)) : Prop :=
  ∀ U V : GaugeConfig d L, (∀ l ∈ S, U l = V l) → F U = F V

/-- **`support F`** — the set of links on which `F` actually
    depends: a link `l` is in `support F` iff there exist two
    configurations that agree off `{l}` but at which `F` takes
    different values. -/
def support (d L : ℕ) (F : GaugeConfig d L → ℂ) : Set (Link d L) :=
  {l | ¬ ∀ U V : GaugeConfig d L,
        (∀ l' : Link d L, l' ≠ l → U l' = V l') → F U = F V}

/-- **Brick (`support_const`).** A constant observable has empty
    support — there is no link on which the constant function
    can take different values. -/
theorem support_const (d L : ℕ) (c : ℂ) :
    support d L (fun _ : GaugeConfig d L => c) = ∅ := by
  ext l
  simp [support]

end TheoremaAureum.Towers.YM.LatticeGauge
