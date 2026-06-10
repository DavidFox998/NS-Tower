/-
================================================================
Towers / NS / WeakSolution  —  NS Tower 540, Phase 5 (weak existence)

Phase-5 deliverable on top of the Phase-3/4 stack: the Phase-3 energy
functional (`Towers.NS.Energy`), the Phase-4A Galerkin scheme
(`Towers.NS.GalerkinApprox`) and the Phase-4B compactness layer
(`Towers.NS.Compactness`). It assembles the classical Galerkin
existence argument for **weak** solutions of the incompressible
Navier–Stokes system into an HONEST combinator.

### What this file provides (classical trio, zero `sorryAx`)

  * `ExternalForce s` — the time-dependent forcing `ℝ → Hdiv_free (s+2)`.
  * `WeakMomentum u f` — a **MODELED** weak momentum balance: the
    tested (distributional) identity
    `d/dt ⟪u t, φ⟫ = -⟪A u t, ι φ⟫ + ⟪f t, φ⟫` for every test field `φ`
    (`A = stokes_op`, `ι = embed`, viscosity normalized `ν = 1`). HONEST
    scope: this is the **linear** Stokes weak form — the nonlinear
    transport term `(u·∇)u` is DROPPED (there is no nonlinearity / no
    physical-space test-function machinery in mathlib v4.12.0), so this
    is a *surrogate* for the genuine distributional Navier–Stokes weak
    form, NOT that form literally.
  * `WeakNS u u₀ f` — the **MODELED** weak-solution predicate: the
    initial condition `u 0 = u₀`, the modeled `WeakMomentum`, and the
    Leray–Hopf-style energy inequality `energy u t ≤ energy u 0` for
    `t ≥ 0` (the force-free dissipative bound; the forcing-work term is
    dropped — modeled, disclaimed). HONEST: a surrogate for the genuine
    Leray–Hopf weak-solution notion, NOT that notion literally.
  * `IsGalerkinLimit K u` — `u(t)` is the (modeled, `TendstoLocL2`)
    lower-order limit of its own Galerkin projections
    `galerkin_seq K u n t`. Uses the Phase-4A sequence + the Phase-4B
    surrogate convergence.
  * **`weak_solution_exists`** — THE Phase-5 headline. A TRIO-CLEAN
    *combinator*: GIVEN the three NAMED analytic inputs below, it
    produces `∃ u, WeakNS u u₀ f`. `#print axioms weak_solution_exists`
    is the classical trio `[propext, Classical.choice, Quot.sound]` — NO
    `sorryAx`.

### The three NAMED SORRYs (Phase-5 order, ≤3, all classical-trio)

In Lean 4 `sorry` IS the axiom `sorryAx` (literally the same term), so a
`by sorry` proof necessarily injects `sorryAx`. Per the honesty lock we
therefore NAME each unproved analytic input as a `Prop` (the *statement*)
and consume it as a hypothesis — never as `by sorry`. Naming a Prop
creates no proof obligation, so each carries NO `sorryAx` and NO new
axioms. The three are exactly the three steps of the Galerkin argument:

  * `galerkin_subsequence_converges K u₀ f`  -- SORRY 1: the Galerkin
    sequence converges to a weak-solution candidate (extraction of a
    convergent subsequence with the right initial data — needs the genuine
    Aubin–Lions COMPACT embedding, `Compactness.AubinLionsCriterion`,
    absent from mathlib v4.12.0).
  * `limit_satisfies_weak_form K f`          -- SORRY 2: the limit solves
    NS in the (modeled) distribution sense — passing the Galerkin weak
    identity to the limit.
  * `energy_inequality_passes_to_limit K`    -- SORRY 3: the energy
    inequality passes to the limit (weak lower semicontinuity of the
    energy norm under the surrogate convergence).

### HONEST scope / deviation note

  * **Zero `sorry`, zero `sorryAx`** — the `≤3 sorries` budget is met by
    NAMING the 3 inputs as Props; the combinator itself is fully proved.
  * `weak_solution_exists` proves NOTHING about Navier–Stokes by itself:
    it only routes the three NAMED inputs into the conclusion, exactly as
    `Compactness.galerkin_strong_convergence` routes `AubinLionsCriterion`.
    The entire mathematical content lives in the three unproved inputs.
  * `WeakMomentum` / `WeakNS` are MODELED surrogates (linear weak form,
    force-free energy bound) — NOT the literal distributional Leray–Hopf
    definitions. Index bookkeeping matches Phase 3/4: everything lives on
    `Hdiv_free (s+2)` (the user's `Hdiv_free s` / `ν`-free `WeakNS u u₀ f`
    are realized with the Phase-3 `(s+2)` index and `ν = 1`).
  * NOT a brick, not in BRICKS, not a lakefile root. It proves NO NS
    existence/uniqueness/regularity result. NS tower stays `Status:
    Open`; Surface #2 stays OPEN; Surface #1 untouched. No `m>0` /
    mass-gap / Clay claim. YM is untouched.
================================================================
-/

import Towers.NS.Compactness
import Mathlib.Analysis.Calculus.Deriv.Basic

open Filter Topology
open TheoremaAureum.Towers.NS.FunctionSpaces
open TheoremaAureum.Towers.NS.Energy
open TheoremaAureum.Towers.NS.Stokes
open TheoremaAureum.Towers.NS.GalerkinApprox
open TheoremaAureum.Towers.NS.Compactness

namespace TheoremaAureum
namespace Towers
namespace NS
namespace WeakSolution

variable {s : ℝ}

/-- **External forcing** for the momentum equation: a time-dependent
field `f : ℝ → Hdiv_free (s+2)`. (Modeled in the solution space; the
genuine forcing may live in a lower/dual space.) -/
abbrev ExternalForce (s : ℝ) : Type := ℝ → Hdiv_free (s + 2)

/-- **MODELED weak momentum balance** (linear Stokes weak form, `ν = 1`).
For every test field `φ`,
`d/dt ⟪u t, φ⟫ = -⟪A u t, ι φ⟫ + ⟪f t, φ⟫`, with `A = stokes_op` and
`ι = embed` the inclusion `Hˢ⁺² ↪ Hˢ`. HONEST scope: the nonlinear
transport term `(u·∇)u` is DROPPED — this is a surrogate for the genuine
distributional Navier–Stokes weak form, NOT that form literally. -/
def WeakMomentum (u : ℝ → Hdiv_free (s + 2)) (f : ExternalForce s) : Prop :=
  ∀ (φ : Hdiv_free (s + 2)) (t : ℝ),
    deriv (fun τ => (@inner ℂ (Hdiv_free (s + 2)) _ (u τ) φ)) t
      = - (@inner ℂ (Hdiv_free s) _ (stokes_op s (u t))
              (@embed (s + 2) s (by linarith) φ))
        + (@inner ℂ (Hdiv_free (s + 2)) _ (f t) φ)

/-- **MODELED weak-solution predicate.** `u` is a weak solution with
initial data `u₀` and forcing `f` iff (i) `u 0 = u₀`, (ii) the modeled
`WeakMomentum` holds, and (iii) the Leray–Hopf-style energy inequality
`energy u t ≤ energy u 0` holds for `t ≥ 0`. HONEST scope: a surrogate
for the genuine Leray–Hopf weak-solution notion (the forcing-work term is
dropped from (iii), the nonlinearity from (ii)); NOT that notion
literally. -/
structure WeakNS (u : ℝ → Hdiv_free (s + 2)) (u₀ : Hdiv_free (s + 2))
    (f : ExternalForce s) : Prop where
  /-- The initial condition `u 0 = u₀`. -/
  init : u 0 = u₀
  /-- The (modeled, linear) weak momentum balance. -/
  momentum : WeakMomentum u f
  /-- The Leray–Hopf-style (force-free) energy inequality for `t ≥ 0`. -/
  energy_le : ∀ t : ℝ, 0 ≤ t → energy u t ≤ energy u 0

variable (K : ℕ → Submodule ℂ (Hdiv_free (s + 2))) [∀ n, FiniteDimensional ℂ (K n)]

/-- **`u` is a Galerkin limit**: for every time `t`, the field value
`u t` is the (modeled, `TendstoLocL2`) lower-order limit of its own
Galerkin projections `galerkin_seq K u n t`. Uses the Phase-4A sequence
and the Phase-4B surrogate convergence. -/
def IsGalerkinLimit (u : ℝ → Hdiv_free (s + 2)) : Prop :=
  ∀ t : ℝ, TendstoLocL2 (fun n => galerkin_seq K u n t) (u t)

/-- **NAMED SORRY 1 (Phase-5 order #1) — axiom-free statement.** The
Galerkin sequence converges to a weak-solution candidate: there exists a
limit field `u` with the prescribed initial data `u 0 = u₀` that is a
Galerkin limit (`IsGalerkinLimit`). The genuine content is the extraction
of a convergent subsequence, which needs the COMPACT Aubin–Lions
embedding (`Compactness.AubinLionsCriterion`), absent from mathlib
v4.12.0. Stated as a `Prop`, NOT discharged with `by sorry` (which would
inject `sorryAx`). NOT a brick.

The forcing `_f` is intentionally UNUSED in this step's body: SORRY #1
asserts only the existence of a convergent candidate with the prescribed
initial data. The candidate's dependence on `f` (the Galerkin ODE driven
by the forcing) is part of the unmodeled construction this input names,
and the forcing's *constraint* on the limit is deferred to SORRY #2
(`limit_satisfies_weak_form`, which is where `f` enters `WeakMomentum`).
`_f` is kept in the signature so the named input reads as
"candidate produced from `(u₀, f)`", faithful to the PDE step.

  -- SORRY: Galerkin sequence converges to weak solution. -/
def galerkin_subsequence_converges (u₀ : Hdiv_free (s + 2))
    (_f : ExternalForce s) : Prop :=
  ∃ u : ℝ → Hdiv_free (s + 2), u 0 = u₀ ∧ IsGalerkinLimit K u

/-- **NAMED SORRY 2 (Phase-5 order #2) — axiom-free statement.** The
limit satisfies NS in the (modeled) distribution sense: every Galerkin
limit `u` satisfies the modeled `WeakMomentum u f`. The genuine content
is passing the Galerkin weak identity to the limit. Stated as a `Prop`,
NOT discharged with `by sorry`. NOT a brick.

  -- SORRY: Limit satisfies NS in distribution sense. -/
def limit_satisfies_weak_form (f : ExternalForce s) : Prop :=
  ∀ u : ℝ → Hdiv_free (s + 2), IsGalerkinLimit K u → WeakMomentum u f

/-- **NAMED SORRY 3 (Phase-5 order #3) — axiom-free statement.** The
energy inequality passes to the limit: every Galerkin limit `u` satisfies
`energy u t ≤ energy u 0` for `t ≥ 0`. The genuine content is weak lower
semicontinuity of the energy norm under the surrogate convergence. Stated
as a `Prop`, NOT discharged with `by sorry`. NOT a brick.

  -- SORRY: Energy inequality passes to limit. -/
def energy_inequality_passes_to_limit : Prop :=
  ∀ u : ℝ → Hdiv_free (s + 2), IsGalerkinLimit K u →
    ∀ t : ℝ, 0 ≤ t → energy u t ≤ energy u 0

/-- **Phase-5 headline: existence of weak solutions (combinator).**
GIVEN the three NAMED analytic inputs — Galerkin subsequence convergence
(`hconv`), the limit solving the modeled weak form (`hweak`), and the
energy inequality passing to the limit (`hener`) — there exists a field
`u` that is a (modeled) weak Navier–Stokes solution `WeakNS u u₀ f`.

This is THE last combinator before Surface #1 (`global_smooth_exists`),
but it closes NOTHING by itself: it only routes the three unproved NAMED
inputs into the conclusion (exactly as
`Compactness.galerkin_strong_convergence` routes `AubinLionsCriterion`).
The entire mathematical content lives in the three inputs. `#print axioms
weak_solution_exists` = classical trio `[propext, Classical.choice,
Quot.sound]` — NO `sorryAx`. NS stays `Status: Open`; Surface #1/#2 stay
OPEN. -/
theorem weak_solution_exists (u₀ : Hdiv_free (s + 2)) (f : ExternalForce s)
    (hconv : galerkin_subsequence_converges K u₀ f)
    (hweak : limit_satisfies_weak_form K f)
    (hener : energy_inequality_passes_to_limit K) :
    ∃ u : ℝ → Hdiv_free (s + 2), WeakNS u u₀ f := by
  obtain ⟨u, hinit, hgal⟩ := hconv
  exact ⟨u, { init := hinit, momentum := hweak u hgal, energy_le := hener u hgal }⟩

end WeakSolution
end NS
end Towers
end TheoremaAureum
