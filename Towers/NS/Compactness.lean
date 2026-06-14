/-
================================================================
Towers / NS / Compactness  —  NS Tower 540, Phase 4B (Aubin–Lions)

Phase-4B builds the compactness layer on top of the Phase-4A Galerkin
scheme (`Towers.NS.GalerkinApprox`). It states the Aubin–Lions /
Rellich–Kondrachov compactness input as a NAMED `Prop` and derives, from
that hypothesis together with the Phase-4A a-priori energy bound, the
existence of an `L²_loc`-convergent subsequence of the Galerkin sequence.

### What this file provides (classical trio, `sorry`-free)

  * `embedToLower : Hˢ⁺² →L Hˢ` — the order-lowering Sobolev inclusion
    `Hˢ⁺² ↪ Hˢ` (the Phase-1 `embed` at `s ≤ s+2`). HONEST: this is the
    *bounded, NON-compact* inclusion — NOT the compact (Rellich–Kondrachov)
    embedding (absent from mathlib v4.12.0).
  * `TendstoLocL2 g w` — **modeled lower-order convergence**: the images
    `embedToLower (g n)` converge to `embedToLower w` in the lower-order space
    `Hˢ`. HONEST: this is an `Hˢ`-norm surrogate for physical-space `L²_loc`,
    NOT literally `L²_loc` convergence (no physical-space machinery here).
  * `AubinLionsCriterion` — **the genuine compactness theorem, stated as a
    NAMED `Prop` HYPOTHESIS, NOT proved (and NOT `sorry`-ed).** It says: any
    sequence in `Hˢ⁺²` with a uniform `‖·‖²`-bound admits a subsequence that
    converges in `L²_loc`. This is exactly Aubin–Lions / Rellich–Kondrachov,
    which needs a COMPACT Sobolev embedding — unavailable in mathlib v4.12.0.
    We therefore expose it as an input hypothesis.
  * `galerkin_seq_energy_bounded` — re-export of the Phase-4A a-priori bound
    `‖uₙ(t)‖² ≤ energy u t`.
  * **`galerkin_strong_convergence`** — THE Phase-4B combinator: GIVEN
    `AubinLionsCriterion`, the energy-bounded Galerkin sequence `uₙ(t)` has a
    subsequence converging in `L²_loc`. `#print axioms` = classical trio
    `[propext, Classical.choice, Quot.sound]`.

### HONEST scope / deviation note

  * **Zero `sorry`, zero `sorryAx`** (the `≤ 2 sorries` budget is met with
    `0`). In Lean 4 `sorry` IS the axiom `sorryAx`, so the unproved
    compactness content is NAMED as a `Prop` hypothesis (`AubinLionsCriterion`)
    and consumed as an assumption — never asserted via `sorry`.
  * `galerkin_strong_convergence` is an HONEST *combinator*: it proves nothing
    about NS by itself; it only routes the Phase-4A energy bound through the
    NAMED Aubin–Lions hypothesis. The hard analytic content (compact embedding)
    is the unproved `AubinLionsCriterion`.
  * It proves NO Navier–Stokes existence/uniqueness/regularity result. NOT a
    brick, not in BRICKS, not a lakefile root. NS tower stays `Status: Open`;
    Surface #2 stays OPEN. YM untouched.
================================================================
-/

import Towers.NS.GalerkinApprox

open Filter Topology

open TheoremaAureum.Towers.NS.FunctionSpaces
open TheoremaAureum.Towers.NS.Energy
open TheoremaAureum.Towers.NS.GalerkinApprox

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Compactness

variable {s : ℝ}

/-- **The order-lowering Sobolev inclusion `Hˢ⁺² ↪ Hˢ`** (the Phase-1 `embed`
at `s ≤ s+2`). HONEST scope: this is the *bounded, NON-compact* inclusion,
NOT the compact Rellich–Kondrachov embedding (absent from mathlib v4.12.0). -/
noncomputable def embedToLower : Hdiv_free (s + 2) →L[ℂ] Hdiv_free s :=
  embed (by linarith : s ≤ s + 2)

/-- **Modeled lower-order convergence** (an `Hˢ`-norm surrogate for `L²_loc`):
the sequence `g n` in `Hˢ⁺²` converges to `w` iff its images under the
order-lowering inclusion `Hˢ⁺² ↪ Hˢ` converge to `embedToLower w` in `Hˢ`.
HONEST scope: this is convergence in the lower Sobolev norm `Hˢ`, a modeled
surrogate for physical-space `L²_loc` — NOT literally `L²_loc` convergence
(this formalization carries no physical-space `L²_loc` machinery). -/
def TendstoLocL2 (g : ℕ → Hdiv_free (s + 2)) (w : Hdiv_free (s + 2)) : Prop :=
  Tendsto (fun n => embedToLower (g n)) atTop (𝓝 (embedToLower w))

/-- **The Aubin–Lions / Rellich–Kondrachov compactness criterion — NAMED
`Prop` HYPOTHESIS, NOT proved (and NOT `sorry`-ed).** Any sequence in `Hˢ⁺²`
with a uniform `‖·‖²` bound admits a subsequence converging in the modeled
lower-order norm (`TendstoLocL2`, the `Hˢ` surrogate for `L²_loc`).

This is the genuine compactness theorem: it requires the *compact* Sobolev
embedding `Hˢ⁺² ↪↪ Hˢ` (our `embedToLower` is only the bounded, non-compact
inclusion), which is absent from mathlib v4.12.0. We therefore state it as an
input hypothesis to be supplied; we do NOT prove it here, and — per the
honesty lock — do NOT discharge it with `sorry`. -/
def AubinLionsCriterion : Prop :=
  ∀ (g : ℕ → Hdiv_free (s + 2)) (C : ℝ),
    (∀ n, ‖g n‖ ^ 2 ≤ C) →
      ∃ (w : Hdiv_free (s + 2)) (φ : ℕ → ℕ),
        StrictMono φ ∧ TendstoLocL2 (fun n => g (φ n)) w

variable (K : ℕ → Submodule ℂ (Hdiv_free (s + 2))) [∀ n, FiniteDimensional ℂ (K n)]

/-- **Re-export of the Phase-4A a-priori energy bound** for the Galerkin
sequence: `‖uₙ(t)‖² ≤ energy u t`. -/
theorem galerkin_seq_energy_bounded (u : ℝ → Hdiv_free (s + 2)) (n : ℕ) (t : ℝ) :
    ‖galerkin_seq K u n t‖ ^ 2 ≤ energy u t :=
  galerkin_seq_sq_le_energy K u n t

/-- **Phase-4B headline: Galerkin strong convergence (combinator).**
GIVEN the Aubin–Lions criterion, the energy-bounded Galerkin sequence `uₙ(t)`
has a subsequence converging in the modeled lower-order norm (`TendstoLocL2`,
the `Hˢ` surrogate for `L²_loc`). The uniform
bound is the Phase-4A `galerkin_seq_sq_le_energy` (constant `energy u t`); the
compactness is the NAMED `AubinLionsCriterion` hypothesis. No `sorry`,
classical trio — this only routes the energy bound through the assumed
criterion; the hard analytic content stays in the unproved hypothesis. -/
theorem galerkin_strong_convergence
    (hAL : AubinLionsCriterion (s := s)) (u : ℝ → Hdiv_free (s + 2)) (t : ℝ) :
    ∃ (w : Hdiv_free (s + 2)) (φ : ℕ → ℕ),
      StrictMono φ ∧ TendstoLocL2 (fun n => galerkin_seq K u (φ n) t) w :=
  hAL (fun n => galerkin_seq K u n t) (energy u t)
    (fun n => galerkin_seq_sq_le_energy K u n t)

end Compactness
end NS
end Towers
end TheoremaAureum
