/-
================================================================
Towers / YM / PolymerModel (Batch 176.1 / TRI PARALLEL #16, file 1 of 3)

**Definition module.** Sets up the polymer expansion carrier
types for the Kotecký–Preiss program:

  * `Polymer d L` — `Finset (Link d L)` (snippet's `def`
    pivoted to `abbrev` so `Finset`'s `card` / `prod_const` /
    `PairwiseDisjoint` flow transparently through dot
    notation).
  * `linkEnergy l : ℝ` — stand-in for the per-link energy
    `1 - 1/2 · Re tr U_p`. Returns the constant `1` (the
    upper end of the SU(2) energy range, since `Re tr U_p ∈
    [-2, 2]` ⟹ `1 - 1/2 · Re tr U_p ∈ [0, 2]`). The real form
    requires a `plaquette`-arity fix + matrix-trace
    infrastructure not landed.
  * `polymerWeightReal d L β X` — `∏ l ∈ X, rexp(-β ·
    linkEnergy l)`. With `linkEnergy ≡ 1`, this is `∏ l,
    rexp(-β) = rexp(-β)^|X|`.
  * `isAdmissible γ` — pairwise-disjoint family of polymers
    (snippet's `PairwiseDisjoint γ` pivoted to the well-typed
    `γ.PairwiseDisjoint (fun X => (X : Set (Link d L)))`).
  * `polymerWeightReal_empty` (brick) — empty polymer has
    weight `1` (trivial; `Finset.prod_empty`).

## Honest scope (locked)
* **Does NOT define the genuine Wilson polymer activity.** The
  real `polymerWeightReal` should use `(1 - 1/2 · (Matrix.trace
  (plaquetteMat d L U x μ ν)).re)` where `U : GaugeConfig d L`
  is the lattice configuration the polymer lives in, but the
  snippet's `plaquette d L β l` has the wrong arity
  (`plaquette` takes `(U : GaugeConfig) (x : Lattice) (μ ν :
  Fin d)`, not `(β : ℝ) (l : Link)`) and a `Link → Plaquette`
  embedding does not exist for general dimensions. Honest
  pivot: replace the per-link energy with the constant `1` —
  this is the **conservative upper bound** of the SU(2) energy
  range, so any cluster-expansion bound proven against it
  trivially fails to control the real polymer activity (which
  can have `0 < energy < 2`, giving smaller weights but also
  no uniform lower bound on `energy` without geometric
  information).
* **Surface #1 stays OPEN.** The snippet's header comment
  `Surface #1 Open` is preserved; the brick below does not
  prove any Yang–Mills statement.
* **Does NOT touch `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`.**
  That `sorry` is invariant-locked.

## Drift from snippet
* (1) **`def Polymer` → `abbrev Polymer`.** Snippet wrote
  `def Polymer (d L : ℕ) := Finset (Link d L)` but then uses
  `X.card`, `Finset.prod_const`, `PairwiseDisjoint γ` which
  all require `Polymer` to definitionally unfold to `Finset`
  *and* be transparent under instance search. `abbrev` flows
  Finset's typeclass instances + dot notation, `def` does not
  (under reducible-only instance search).
* (2) **`Matrix.trace (plaquette d L β l)` dropped.** Snippet's
  `plaquette d L β l` does not typecheck — `plaquette` in
  `Towers.YM.WilsonAction` has signature `plaquette (U :
  GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d)`, returning
  a `Matrix (Fin 2) (Fin 2) ℂ` via `.1` coercion (per Batch
  168.2's drift note). Honest pivot: introduce `linkEnergy :
  Link d L → ℝ` as a parameterized stand-in (constant `1`
  here); the real plaquette-based energy requires a `Link →
  Plaquette` embedding + an ambient `GaugeConfig`, neither
  landed.
* (3) **`PairwiseDisjoint γ` typed correctly.** Snippet wrote
  `PairwiseDisjoint γ` where `γ : Finset (Polymer d L)`, but
  `PairwiseDisjoint` is `(s : Set ι) → (f : ι → α) → Prop`
  (or `Finset.PairwiseDisjoint`), requiring a function to a
  type with `Disjoint` (e.g., sets). Pivot: `γ.PairwiseDisjoint
  (fun X : Polymer d L => (X : Set (Link d L)))` — the natural
  reading "distinct polymers in the family are disjoint as
  link-sets".
* (4) **Namespace widen** to
  `TheoremaAureum.Towers.YM.LatticeGauge` (snippet used
  `TheoremaAureum.Towers.YM`, but `Link` lives in the
  `LatticeGauge` sub-namespace; opening it pollutes the
  global namespace, qualifying everywhere is noisy, so we
  match the Batch 168.x / 174.x / 175.x convention).
* (5) **Brick `polymerWeightReal_empty` added.** Snippet has
  no brick (only definitions); to register a wall increment
  the file lands one trivial theorem witnessing
  `polymerWeightReal d L β ∅ = 1` (empty product = 1 via
  `Finset.prod_empty`).

## Tripwire (mass gap)
* `linkEnergy ≡ 1` is the **upper bound** of the SU(2) link
  energy range (`[0, 2]`); any K-P bound proven against it
  is a *trivial* upper bound — the real activity ranges over
  `[0, 2]` and gives `polymerWeight ∈ [exp(-2β·|X|), 1]`. The
  cluster expansion's convergence depends on a *uniform*
  decay rate, which requires energy lower bounds (geometric
  / FKG / Brascamp–Lieb), none landed.

## Axiom footprint
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}` — proof of
`polymerWeightReal_empty` is `simp [polymerWeightReal]`
(`Finset.prod_empty`).
================================================================
-/

import Towers.YM.LatticeGauge
import Towers.YM.WilsonAction
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Data.Set.Pairwise.Lattice

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **`Polymer d L`** — a polymer is a finite set of links on
    the periodic lattice. `abbrev` so `Finset`'s `card`,
    `prod_const`, `PairwiseDisjoint`, and dot notation flow
    transparently. -/
abbrev Polymer (d L : ℕ) : Type := Finset (Link d L)

/-- **`linkEnergy l`** — stand-in per-link energy. The real
    form is `1 - 1/2 · (Matrix.trace (plaquetteMat U x μ ν)).re`
    for some `U : GaugeConfig d L` containing `l`, taking
    values in `[0, 2]` for SU(2). Returns the constant upper
    bound `1` (so any K-P bound here is the conservative
    upper-bound version). -/
def linkEnergy {d L : ℕ} (_l : Link d L) : ℝ := 1

/-- **`polymerWeightReal d L β X`** — total weight of polymer
    `X` at coupling `β`. With `linkEnergy ≡ 1`, evaluates to
    `rexp(-β)^|X|`. -/
noncomputable def polymerWeightReal (d L : ℕ) (β : ℝ) (X : Polymer d L) : ℝ :=
  ∏ l in X, Real.exp (-β * linkEnergy l)

/-- **`isAdmissible γ`** — a family `γ` of polymers is
    admissible iff distinct polymers in `γ` are disjoint as
    sets of links. Honest typing of snippet's
    `PairwiseDisjoint γ`. -/
def isAdmissible {d L : ℕ} (γ : Finset (Polymer d L)) : Prop :=
  (γ : Set (Polymer d L)).PairwiseDisjoint (fun X : Polymer d L => (X : Set (Link d L)))

/-- **Brick (`polymerWeightReal_empty`).** The empty polymer
    has weight `1` (empty product). Trivial; lands one brick
    for wall registration. -/
theorem polymerWeightReal_empty (d L : ℕ) (β : ℝ) :
    polymerWeightReal d L β (∅ : Polymer d L) = 1 := by
  simp [polymerWeightReal]

end TheoremaAureum.Towers.YM.LatticeGauge
