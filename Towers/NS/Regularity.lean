/-
================================================================
Towers / NS / Regularity  —  NS Tower 540, Phase 6 (weak ⇒ strong)

Phase-6 deliverable on top of the Phase-5 weak-existence layer
(`Towers.NS.WeakSolution`). It states the **weak-implies-strong
(conditional) regularity** step of the incompressible Navier–Stokes
program as an HONEST combinator: GIVEN the named global-regularity
surface, every (modeled) weak solution is smooth on a short time
interval.

### What this file provides (classical trio, zero `sorryAx`)

  * `WeakSolution s` — a **bundled** weak solution: the field
    `u : ℝ → Hdiv_free (s+2)`, its initial data `u₀`, the forcing `f`,
    and a proof `isWeak : WeakNS u u₀ f` of the Phase-5 MODELED
    weak-solution predicate. This is the `u : WeakSolution` of the
    Phase-6 order, packaged as a type.
  * `IsSmoothOn u T` — a **MODELED** surrogate for
    `u ∈ C^∞((0,T) × ℝ³)`: every tested time-profile
    `t ↦ ⟪u t, φ⟫_ℂ` is `C^∞` (`ContDiffOn ℝ ⊤`) on the open interval
    `(0,T)`. HONEST scope: this captures **temporal** smoothness of the
    weak/tested profiles only. Genuine `C^∞((0,T) × ℝ³)` (joint
    space–time smoothness) needs the spatial Sobolev embedding
    `⋂ₛ Hˢ ↪ C^∞` across ALL indices `s` simultaneously — absent from
    this single-fixed-index Fourier model and from mathlib v4.12.0 — so
    `IsSmoothOn` is a surrogate for that statement, NOT that statement
    literally.
  * **`weak_implies_strong`** — THE Phase-6 headline. A TRIO-CLEAN
    *combinator*: GIVEN the NAMED regularity surface `global_smooth_exists`,
    it produces `∃ T > 0, IsSmoothOn w.u T` for every `w : WeakSolution s`.
    `#print axioms weak_implies_strong` is the classical trio
    `[propext, Classical.choice, Quot.sound]` — NO `sorryAx`.

### The single NAMED SORRY (Phase-6 order, ≤1, classical-trio)

In Lean 4 `sorry` IS the axiom `sorryAx` (literally the same term), so a
`by sorry` proof necessarily injects `sorryAx`. Per the honesty lock we
therefore NAME the one unproved input as a `Prop` (the *statement*) and
consume it as a hypothesis — never as `by sorry`. Naming a Prop creates
no proof obligation, so it carries NO `sorryAx` and NO new axioms.

  * `global_smooth_exists` — the NS **global-regularity surface**: every
    (modeled) weak solution `w : WeakSolution s` is smooth on a short
    interval `∃ T > 0, IsSmoothOn w.u T`. This is the genuine open
    content (the Clay-grade Navier–Stokes regularity statement); it is
    NAMED, NOT proved, and NOT asserted true. NOT a brick.

### HONEST scope / deviation note

  * **Zero `sorry`, zero `sorryAx`** — the `≤1 sorry` budget is met by
    NAMING the surface as a `Prop`; the combinator itself is fully proved.
  * `weak_implies_strong` proves NOTHING about Navier–Stokes regularity by
    itself: it only routes the NAMED surface into the conclusion (exactly
    as `WeakSolution.weak_solution_exists` routes its three named inputs).
    The entire mathematical content lives in `global_smooth_exists`.
  * Per the Phase-6 order, because the single sorry is the surface
    `global_smooth_exists`, **NS Tower 540 is frozen at 251** (milestone
    `NS-540-phase6-regularity`): the regularity surface is reached but
    left OPEN, not closed.
  * `WeakSolution` / `WeakNS` are the Phase-5 MODELED surrogates (linear
    weak form, force-free energy bound) — NOT the literal distributional
    Leray–Hopf definitions. `IsSmoothOn` is a MODELED surrogate for
    `C^∞((0,T) × ℝ³)`. Index bookkeeping matches Phase 3/4/5: everything
    on `Hdiv_free (s+2)`, `ν = 1`.
  * NOT a brick, not in BRICKS, not a lakefile root. It proves NO NS
    existence / uniqueness / regularity result. NS tower stays
    `Status: Open`; Surface #1/#2 stay OPEN. No `m>0` / mass-gap / Clay
    claim. YM is untouched.
================================================================
-/

import Towers.NS.WeakSolution
import Mathlib.Analysis.Calculus.ContDiff.Basic

open Filter Topology
open TheoremaAureum.Towers.NS.FunctionSpaces
open TheoremaAureum.Towers.NS.WeakSolution

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Regularity

variable {s : ℝ}

/-- **Bundled (modeled) weak solution.** Packages the Phase-5 data: the
field `u`, its initial value `u₀`, the forcing `f`, and a proof that the
modeled weak-solution predicate `WeakNS u u₀ f` holds. This realizes the
Phase-6 order's `u : WeakSolution` as a type. HONEST scope: `WeakNS` is
the Phase-5 MODELED surrogate (linear weak form, force-free energy
bound), NOT the literal Leray–Hopf weak-solution notion. -/
structure WeakSolution (s : ℝ) where
  /-- The velocity field. -/
  u : ℝ → Hdiv_free (s + 2)
  /-- The initial data. -/
  u₀ : Hdiv_free (s + 2)
  /-- The external forcing. -/
  f : ExternalForce s
  /-- The (modeled) Phase-5 weak-solution proof. -/
  isWeak : WeakNS u u₀ f

/-- **MODELED smoothness on `(0,T)`** — surrogate for
`u ∈ C^∞((0,T) × ℝ³)`. Every tested time-profile `t ↦ ⟪u t, φ⟫_ℂ` is
`C^∞` (`ContDiffOn ℝ ⊤`) on the open interval `(0,T)`. HONEST scope: this
is **temporal** smoothness of the weak/tested profiles only; genuine
`C^∞((0,T) × ℝ³)` needs the spatial Sobolev embedding into `C^∞` across
ALL Sobolev indices simultaneously (absent from this fixed-index model and
from mathlib v4.12.0). Surrogate, NOT the literal statement. -/
def IsSmoothOn (u : ℝ → Hdiv_free (s + 2)) (T : ℝ) : Prop :=
  ∀ φ : Hdiv_free (s + 2),
    ContDiffOn ℝ (⊤ : ℕ∞)
      (fun t : ℝ => (@inner ℂ (Hdiv_free (s + 2)) _ (u t) φ)) (Set.Ioo 0 T)

/-- **NAMED SORRY (Phase-6 order) — axiom-free statement.** The NS
**global-regularity surface**: every (modeled) weak solution
`w : WeakSolution s` is smooth on a short time interval,
`∃ T > 0, IsSmoothOn w.u T`. This is the genuine open content — the
Clay-grade Navier–Stokes regularity statement (weak ⇒ strong on `(0,T)`).

Per the honesty lock we record it as a `Prop` (the *statement*), NOT as a
`theorem … := by sorry`. In Lean 4 `sorry` IS the axiom `sorryAx` (they
are literally the same term), so any `by sorry` proof necessarily makes
`#print axioms` report `sorryAx`. Naming the proposition creates no proof
obligation, so it carries NO `sorryAx` and NO new axioms:
`#print axioms global_smooth_exists` is the classical trio only. It is
honestly NOT proved and NOT asserted true — it is the named regularity
input behind `weak_implies_strong`. Because this single sorry IS the
surface, **NS is frozen at 251** (the surface is reached, left OPEN). NOT
a brick.

  -- SORRY: global smooth existence (weak ⇒ strong) for Navier–Stokes.
  -- (Stated, not discharged: a `by sorry` proof would inject the
  -- `sorryAx` axiom, which the honesty lock forbids.) -/
def global_smooth_exists : Prop :=
  ∀ w : WeakSolution s, ∃ T > 0, IsSmoothOn w.u T

/-- **Phase-6 headline: weak solutions are strong on a short interval
(combinator).** GIVEN the NAMED regularity surface `global_smooth_exists`
(`h`), every (modeled) weak solution `w : WeakSolution s` is smooth on
some interval `(0,T)` with `T > 0`: `∃ T > 0, IsSmoothOn w.u T` — the
modeled surrogate for `w.u ∈ C^∞((0,T) × ℝ³)`.

This combinator closes NOTHING by itself: it only routes the unproved
NAMED surface into the conclusion (exactly as
`WeakSolution.weak_solution_exists` routes its three named inputs). The
entire mathematical content lives in `global_smooth_exists`, which is NOT
proved. `#print axioms weak_implies_strong` = classical trio
`[propext, Classical.choice, Quot.sound]` — NO `sorryAx`. NS stays
`Status: Open`; Surface #1/#2 stay OPEN; NS frozen at 251. -/
theorem weak_implies_strong (h : global_smooth_exists (s := s))
    (w : WeakSolution s) :
    ∃ T > 0, IsSmoothOn w.u T :=
  h w

end Regularity
end NS
end Towers
end TheoremaAureum
