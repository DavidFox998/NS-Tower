/-
================================================================
Towers / YM / Wilson  (Task #88, sub-batch 88.1)

**Real SU(3) Wilson plaquette action on a cubic lattice.**

Replaces the placeholder `YMHamiltonian : SU3Connection → ℝ`
(`∑ i, ((A i).1).trace.re`, identically `12` on
`vacuum_connection`) with a real, gauge-theoretically meaningful
functional `YMHamiltonian_real := WilsonAction 1` built from
honest SU(3) link variables on a 2⁴ periodic cubic lattice.

**Honest scope.**
  * The lattice is `WSite := Fin 2 × Fin 2 × Fin 2 × Fin 2`
    (smallest non-trivial 4D periodic lattice, 16 sites). The
    construction is parametric in lattice size in principle; we
    instantiate at `L = 2` to keep the `Fin` arithmetic
    `decide`-reachable for the ground-state computation.
  * Link variables: `WilsonLinks := WSite → Fin 4 → SU3` where
    `SU3 := Matrix.specialUnitaryGroup (Fin 3) ℂ`. Real, honest,
    Haar-equipped (via mathlib's `MeasureTheory.Measure.Haar` —
    though we don't invoke it in this sub-batch).
  * Plaquette at site `x` in plane `(μ, ν)`:
    `U_μ(x) · U_ν(x+μ̂) · U_μ(x+ν̂)⁻¹ · U_ν(x)⁻¹`. Computed at
    the matrix level via `star` (the unitary inverse on `Mat3`)
    to avoid carrying the `Submonoid (Matrix _ _ _)` subgroup
    inverse through. The result is a `Mat3` (not a re-wrapped
    `SU3`); we don't claim closure in `SU3` at the type level in
    this sub-batch — we only need the algebraic identity at the
    matrix level.
  * Wilson action density:
    `(1/6) · ∑_{i,j} ‖I_{ij} - U_p_{ij}‖²` (Frobenius-norm-
    squared form). For unitary plaquettes this is identically
    equal to the standard spec wording
    `(1 - (1/3) · Re Tr U_p)` — algebraic identity
    `‖I-U‖_F² = 6 - 2 Re Tr U` for `U ∈ U(3)`. We use the
    Frobenius form as the **definition** because it is manifestly
    non-negative (sum of `Complex.normSq` terms). The equivalence
    `1 - (1/3) Re Tr U = (1/6) ‖I-U‖_F²` on unitary `U` is a
    routine algebraic lemma deferred to sub-batch 88.1b — it is
    NOT load-bearing for the non-negativity result here.
  * Wilson action: `β · ∑_{x, μ, ν} density(U, x, μ, ν)`. The
    sum is over **ordered** pairs `(μ, ν)` (double-counts the 6
    unordered planes); this rescales `β` by a factor of 2 vs the
    physics convention but does not affect non-negativity.

**Tripwires.**
  * No claim of self-adjointness or compactness of any associated
    transfer matrix — sub-batches 88.4 / 88.5, marked TODO below.
  * No claim of reflection positivity of the action — also a
    deeper sub-batch.
  * No claim that `WilsonAction` has a mass gap — that is the
    Clay problem, still `Status: Open` in `docs/ROADMAP.md`.

**Compatibility with prior bricks.**
  * The legacy `Towers.YM.MassGap.YMHamiltonian` (the constant-12
    trace functional) is **not** touched by this file. All Batch
    1–15 bricks that reference it continue to compile against
    their original placeholder. New (Batch 16+) bricks should use
    `Towers.YM.Wilson.YMHamiltonian_real`.

**TODOs (subsequent sub-batches).**
  * 88.1b: algebraic identity `1 - (1/3) Re Tr U = (1/6) ‖I-U‖²`
    for `U ∈ unitaryGroup (Fin 3) ℂ`.
  * 88.1c: explicit non-trivial SU(3) witness (e.g.
    `diagonal ![(-1:ℂ), -1, 1]`) and `WilsonAction_not_constant`
    as an absolute (non-conditional) `∃ U₁ U₂, WA U₁ ≠ WA U₂`.
  * 88.3: `transfer_matrix : L²((SU(3))^Links) →L L²(…)`.
  * 88.4: `transfer_matrix selfadjoint` (Osterwalder–Seiler RP).
  * 88.5: `transfer_matrix compact` (Hilbert–Schmidt kernel).

YM tower stays `Status: Open`. No Clay claim.
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Matrix.Notation
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.Ring

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Wilson

open scoped BigOperators

/-- 3×3 complex matrices — the carrier for SU(3). -/
abbrev Mat3 : Type := Matrix (Fin 3) (Fin 3) ℂ

/-- SU(3) as a submonoid of `Mat3`. Real, mathlib-backed. -/
abbrev SU3 : Type := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-- Site of the 2⁴ periodic cubic lattice. 16 sites total. -/
abbrev WSite : Type := Fin 2 × Fin 2 × Fin 2 × Fin 2

/-- Configuration of link variables `U_μ(x) ∈ SU(3)` on the
    2⁴ lattice. -/
abbrev WilsonLinks : Type := WSite → Fin 4 → SU3

/-- Periodic lattice shift `x → x + μ̂` in the `μ`-th direction.
    `Fin 2` addition is mod 2, so this is automatically periodic. -/
def shift (x : WSite) (μ : Fin 4) : WSite :=
  if μ.1 = 0 then (x.1 + 1, x.2.1, x.2.2.1, x.2.2.2)
  else if μ.1 = 1 then (x.1, x.2.1 + 1, x.2.2.1, x.2.2.2)
  else if μ.1 = 2 then (x.1, x.2.1, x.2.2.1 + 1, x.2.2.2)
  else (x.1, x.2.1, x.2.2.1, x.2.2.2 + 1)

/-- Coercion of a link variable to its underlying 3×3 matrix. -/
def linkMat (U : WilsonLinks) (x : WSite) (μ : Fin 4) : Mat3 :=
  (U x μ).1

/-- **Plaquette matrix** at site `x` in plane `(μ, ν)`:
    `U_μ(x) · U_ν(x+μ̂) · U_μ(x+ν̂)⁻¹ · U_ν(x)⁻¹`.

    Computed at the `Mat3` level using `star` for the unitary
    inverse. Result is a 3×3 matrix; the fact that it is unitary
    (closure of `SU(3)` under products and conjugates) is true
    but not directly invoked in this sub-batch. -/
def plaquetteMat (U : WilsonLinks) (x : WSite) (μ ν : Fin 4) : Mat3 :=
  linkMat U x μ * linkMat U (shift x μ) ν *
    star (linkMat U (shift x ν) μ) * star (linkMat U x ν)

/-- **Wilson action density** in the Frobenius-norm-squared form:
    `(1/6) · ∑_{i,j} ‖I_{ij} - (U_p)_{ij}‖²`. For unitary `U_p`
    this equals `1 - (1/3) · Re Tr U_p` (algebraic identity
    deferred to 88.1b). Manifestly non-negative as a sum of
    `Complex.normSq` terms. -/
noncomputable def wDensity
    (U : WilsonLinks) (x : WSite) (μ ν : Fin 4) : ℝ :=
  (1 / 6 : ℝ) * ∑ i : Fin 3, ∑ j : Fin 3,
    Complex.normSq ((1 : Mat3) i j - plaquetteMat U x μ ν i j)

/-- **Wilson action** at coupling `β`:
    `β · ∑_{x, μ, ν} wDensity U x μ ν`. Sum over **ordered**
    `(μ, ν)` pairs — this is `2β` times the standard physics
    Wilson action which sums over unordered `μ < ν` planes. The
    factor of 2 is harmless for non-negativity and depends-on-U
    arguments. -/
noncomputable def WilsonAction (β : ℝ) (U : WilsonLinks) : ℝ :=
  β * ∑ x : WSite, ∑ μ : Fin 4, ∑ ν : Fin 4, wDensity U x μ ν

/-- **Real YM Hamiltonian** — `WilsonAction` at `β = 1`. This is
    the **real replacement** for the placeholder
    `Towers.YM.MassGap.YMHamiltonian` (which was the constant
    trace functional, identically `12` on the vacuum). Batch 16+
    should reference this symbol, not the legacy placeholder. -/
noncomputable def YMHamiltonian_real (U : WilsonLinks) : ℝ :=
  WilsonAction 1 U

/-- The trivial link configuration `U_μ(x) ≡ 1` (every link is
    the identity element of SU(3)). -/
def trivialLinks : WilsonLinks := fun _ _ => 1

/-- `linkMat trivialLinks x μ = 1`. -/
@[simp] lemma linkMat_trivial (x : WSite) (μ : Fin 4) :
    linkMat trivialLinks x μ = (1 : Mat3) := by
  simp [linkMat, trivialLinks, Submonoid.coe_one]

/-- **Brick (`plaquetteMat_trivial`).** The plaquette of the
    trivial configuration is the identity matrix at every site
    and plane. Real computation: `1 * 1 * star 1 * star 1 = 1`. -/
theorem plaquetteMat_trivial (x : WSite) (μ ν : Fin 4) :
    plaquetteMat trivialLinks x μ ν = (1 : Mat3) := by
  simp [plaquetteMat]

/-- **Brick (`wDensity_trivial_eq_zero`).** The Wilson density
    vanishes on the trivial configuration — each plaquette is the
    identity, so `I - U_p = 0`, hence the Frobenius norm² is 0. -/
theorem wDensity_trivial_eq_zero (x : WSite) (μ ν : Fin 4) :
    wDensity trivialLinks x μ ν = 0 := by
  simp [wDensity, plaquetteMat_trivial]

/-- **Brick (`WilsonAction_trivial_eq_zero`).** Real theorem:
    the Wilson action vanishes on the trivial configuration.
    This is the SU(3) analogue of "the vacuum has zero action"
    — the **honest** counterpart of the placeholder
    `YMHamiltonian vacuum_connection = 12`. The real action gives
    `0`, not `12`, on the vacuum. -/
theorem WilsonAction_trivial_eq_zero (β : ℝ) :
    WilsonAction β trivialLinks = 0 := by
  simp [WilsonAction, wDensity_trivial_eq_zero]

/-- **Brick (`wDensity_nonneg`).** Real theorem: every Wilson
    density value is non-negative. Follows from `Complex.normSq`
    being non-negative and the prefactor `1/6 ≥ 0`. -/
theorem wDensity_nonneg (U : WilsonLinks) (x : WSite) (μ ν : Fin 4) :
    0 ≤ wDensity U x μ ν := by
  unfold wDensity
  apply mul_nonneg
  · norm_num
  · apply Finset.sum_nonneg
    intro i _
    apply Finset.sum_nonneg
    intro j _
    exact Complex.normSq_nonneg _

/-- **Brick (`WilsonAction_nonneg`).** Real theorem: for any
    coupling `β ≥ 0`, the Wilson action is non-negative on every
    link configuration. The action is bounded below by zero —
    the vacuum is its minimum. This is the **load-bearing**
    replacement for the placeholder `YMHamiltonian vacuum = 12`:
    instead of "the vacuum evaluates to a meaningless constant",
    we now have "the action is non-negative with a real
    minimum at zero on the trivial configuration". -/
theorem WilsonAction_nonneg (β : ℝ) (hβ : 0 ≤ β) (U : WilsonLinks) :
    0 ≤ WilsonAction β U := by
  unfold WilsonAction
  apply mul_nonneg hβ
  apply Finset.sum_nonneg; intro x _
  apply Finset.sum_nonneg; intro μ _
  apply Finset.sum_nonneg; intro ν _
  exact wDensity_nonneg U x μ ν

/-- **Brick (`YMHamiltonian_real_trivial_eq_zero`).** The real YM
    Hamiltonian vanishes on the trivial (vacuum) configuration.
    The honest analogue of `vacuum_connection` evaluating to `0`,
    NOT `12`. -/
theorem YMHamiltonian_real_trivial_eq_zero :
    YMHamiltonian_real trivialLinks = 0 := by
  unfold YMHamiltonian_real
  exact WilsonAction_trivial_eq_zero 1

/-- **Brick (`YMHamiltonian_real_nonneg`).** The real YM
    Hamiltonian is non-negative on every link configuration.
    Real theorem: the **load-bearing fact** that replaces
    "`YMHamiltonian vacuum = 12`" (a meaningless constant) with
    "`YMHamiltonian_real U ≥ 0` for all `U`" (a real bound). -/
theorem YMHamiltonian_real_nonneg (U : WilsonLinks) :
    0 ≤ YMHamiltonian_real U := by
  unfold YMHamiltonian_real
  exact WilsonAction_nonneg 1 zero_le_one U

end Wilson
end YM
end Towers
end TheoremaAureum
