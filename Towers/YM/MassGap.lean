/-
  # Towers.YM.MassGap

  **Mostly-statement file. As of the Task #51 + Task #55 merge
  (2026-05-26) all three previously `sorry`-backed schema defs
  (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) have been
  replaced by concrete, mathlib-backed types** so the file is now
  `sorry`-free.

  Task #55 (Branch A) upgraded `HilbertSpace` to `lp (fun _ : ℕ
  => ℂ) 2`, the canonical separable infinite-dim ℓ²(ℕ,ℂ). Task
  #51 concretized `YMHamiltonian` as `∑ i : Fin 4, ((A
  i).1).trace.re` and `IsEigenstate H ψ` as `∃ μ : ℝ, ∀ A, H A =
  μ * (‖ψ‖ * ‖ψ‖)`. The schema is still **not** the real Clay
  Yang-Mills surface (no Wightman axioms, no Sobolev spaces, no
  trace-of-the-curvature-2-form, no Osterwalder–Schrader
  reconstruction). It is a typed, inhabited stand-in whose only
  purpose is to let downstream bricks reference a Hilbert space,
  a real-valued "Hamiltonian" function on `SU3Connection`, and
  an eigenstate predicate without tripping over `sorryAx`. This
  file pins the Clay Yang-Mills mass-gap conjecture as a future
  formalisation target, using a structured (rather than
  single-`sorry`) schema.

  The seven trio-clean SU(3) bricks proved below are:
  `SU3Connection_one_mul`, `SU3Connection_component_unitary`,
  `SU3Connection_component_det_one`, `SU3Connection_mul_one`,
  `SU3Connection_one_one`, `SU3Connection_component_mul_unitary`,
  `SU3Connection_component_mul_det_one`. Each is real SU(3)
  monoid / submonoid algebra (no `TrivialConfiguration` shortcut)
  with axiom footprint a subset of `{propext, Classical.choice,
  Quot.sound}`. None of them advances the YM tower past
  `Status: Open` (see `docs/ROADMAP.md` § 2); they are foundation
  bricks under the schema, not Millennium claims.

  ## Status of the schema after the Plan #52 MassGap refactor

  As of this refactor, the previously-opaque `SU3Connection : Type
  := sorry` has been replaced by a **concrete, sorry-free type**:

      abbrev SU3Connection : Type :=
        Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ

  This is the **trivial-bundle constant-coefficient case** of an
  SU(3) gauge connection on `ℝ⁴`: four constant SU(3)-valued fields,
  one per spacetime direction. It is **not** a connection on a
  non-trivial principal bundle — that would need
  `Mathlib.Geometry.Manifold.VectorBundle.Basic` and a `Connection`
  type, neither of which is plumbed up to where we need them in
  mathlib v4.12.0. But it is a real, inhabited, sorry-free type
  that future YM bricks can prove things about, using the real
  `Matrix.specialUnitaryGroup` API from
  `Mathlib/LinearAlgebra/UnitaryGroup.lean`.

  **Correction to a prior internal note.** An earlier comment in
  this file (and in a planning message) claimed
  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` was missing
  from mathlib v4.12.0. That was *technically* correct (no file by
  that name) but *substantively misleading*: `Matrix.specialUnitaryGroup`
  itself **does exist**, as an `abbrev` in
  `Mathlib/LinearAlgebra/UnitaryGroup.lean` (line 180):

      abbrev specialUnitaryGroup := unitaryGroup n α ⊓ MonoidHom.mker detMonoidHom

  This refactor uses it directly. The earlier "OMITTED" line about
  the SpecialUnitaryGroup file is preserved below for historical
  honesty, with a corrected pointer to where the type actually lives.

  ## Concretized schema defs (NOT the Clay surface)

    * `HilbertSpace      := lp (fun _ : ℕ => ℂ) 2`
    * `YMHamiltonian A   := ∑ i : Fin 4, ((A i).1).trace.re`
    * `IsEigenstate H ψ  := ∃ μ : ℝ, ∀ A, H A = μ * (‖ψ‖ * ‖ψ‖)`

  These are honest, mathlib-backed stand-ins, not the Clay
  surface. `HilbertSpace` is ℓ²(ℕ,ℂ) — a real separable
  infinite-dim complex Hilbert space, but NOT the Osterwalder–
  Schrader-reconstructed YM physical state space (which does not
  exist in mathlib v4.12.0 and is itself open research).
  `YMHamiltonian` is a sum of traces of connection components,
  NOT `∫ tr(F_A ∧ ★F_A)`. `IsEigenstate` is a quantitative
  scaling predicate that captures the *form* of "H has constant
  value μ‖ψ‖² on every connection", NOT the spectral-eigenvector
  property of an operator on the physical Hilbert space.

  Because these defs are now concrete (no `sorry`), `#print axioms
  YM_mass_gap_statement` no longer displays `[sorryAx]`. The statement
  type-checks, but its *content* is the placeholder above — not the
  Clay conjecture. `YM_mass_gap_statement` remains NOT a brick, is
  NOT in `scripts/check-towers.sh BRICKS`, and is NOT imported by
  any of the bricks that ARE in BRICKS.

  ## What this file IS now (post-refactor)

  * Seven real trio-clean SU(3) bricks (listed above) using the
    concrete `SU3Connection` type and the real
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid structure.
    Axiom footprint of each = subset of mathlib's classical trio.
  * Stable citable Lean identifiers for future plans to point at.
  * A flagged TODO surface: every remaining `sorry` is paired with a
    `TODO:` comment naming the mathlib module that would replace it.

  ## Status

  Per `docs/ROADMAP.md` § 2. Yang-Mills mass gap: **Open.** No
  promotion. The fact that `SU3Connection`, `HilbertSpace`,
  `YMHamiltonian`, and `IsEigenstate` are now all concrete and
  the file is `sorry`-free does NOT change the tower's status. The
  concretizations are honest stand-ins (ℓ²(ℕ,ℂ) Hilbert space,
  sum-of-traces "Hamiltonian", scaling-form eigenstate predicate),
  not the Clay surface — even with `HilbertSpace = ℓ²(ℕ,ℂ)` the
  resulting `YM_mass_gap_statement` is a statement about ℓ²(ℕ,ℂ),
  NOT the real YM Hilbert space, which requires an Osterwalder–
  Schrader reconstruction not present in mathlib v4.12.0. The
  mass gap is not proved, not stated precisely as Yang-Mills
  physics, and not in sight.
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Matrix.Notation
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Data.Fintype.BigOperators
import Towers.YM.PlaquetteAction

namespace TheoremaAureum
namespace Towers
namespace YM

/-- **SU(3) gauge field, trivial-bundle constant-coefficient case.**

    A `SU3Connection` is a 4-tuple of constant `SU(3)` matrices, one
    per spacetime direction. This is the trivial-bundle special case
    of an honest YM connection — no base manifold, no bundle, no
    differential structure — but it is a real, inhabited, sorry-free
    type that the brick `SU3Connection_one_mul` below can prove
    things about using the real `Matrix.specialUnitaryGroup` API. -/
abbrev SU3Connection : Type := Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ
-- TODO (mathlib v4.13+): replace with
--   Connection (Bundle ℝ ℝ⁴) (Matrix.specialUnitaryGroup (Fin 3) ℂ)
-- once `Mathlib.Geometry.Manifold.VectorBundle.Basic` exposes Connection.
-- (Note: `Matrix.specialUnitaryGroup` itself lives in
--  `Mathlib/LinearAlgebra/UnitaryGroup.lean`, not in a separate
--  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` file.)

/-
  **Task #51 + Task #55 merge note (2026-05-26).** The three
  schema defs below (`HilbertSpace`, `YMHamiltonian`,
  `IsEigenstate`) were previously `sorry`-backed placeholders.

  Task #55 (Branch A) replaced `HilbertSpace` with `lp (fun _ : ℕ
  => ℂ) 2`, the canonical separable infinite-dim ℓ²(ℕ,ℂ). Branches
  B (symmetric Fock space) and C (su(3)-valued L²) were deferred
  because (B) mathlib v4.12.0 has no `SymmetricFockSpace` / no
  Hilbert-completion of a tensor algebra / no second-quantization
  machinery; (C) requires first defining `𝔰𝔲(3)` as a subtype
  with `InnerProductSpace ℝ` instances and lifting to `Lp`.

  Task #51 then replaced `YMHamiltonian` with `∑ i : Fin 4, ((A
  i).1).trace.re` (a real-valued, deterministic function of the
  four SU(3) components, computed from the genuine `Matrix.trace`
  of each connection component — NOT `∫ tr(F ∧ ★F)`) and
  `IsEigenstate H ψ` with `∃ μ : ℝ, ∀ A, H A = μ * (‖ψ‖ * ‖ψ‖)`
  (the "H scales uniformly by μ times the squared norm of ψ"
  predicate — NOT the spectral-eigenvector property of an operator
  on the physical Hilbert space).

  **Honest-scoping rule that survives both upgrades.** ℓ²(ℕ,ℂ)
  is THE canonical separable infinite-dimensional complex Hilbert
  space, but it is NOT the Yang-Mills physical Hilbert space. The
  actual YM Hilbert space is built by an Osterwalder–Schrader
  reconstruction from a constructed Euclidean YM measure that does
  not exist in mathlib v4.12.0 (and is itself an open research
  problem for 4D pure YM). `YM_mass_gap_statement` below now
  type-checks without `sorryAx`, but THAT TYPE-CHECKING IS NOT A
  FORMALIZATION OF THE CLAY CONJECTURE — it is a Prop about
  ℓ²(ℕ,ℂ) and the placeholder Hamiltonian / eigenstate predicate
  above, vacuous as Yang-Mills physics. Tower status: **Open**
  (see `docs/ROADMAP.md` § 2). Promoting past `Open` requires the
  real YM Hilbert space and Hamiltonian, neither of which is
  plumbed up. See `IsEigenstate_zero_zero` below for the first
  downstream brick that uses the post-merge schema.
-/

/-- **Hilbert space placeholder for the schema.**

    Defined as `lp (fun _ : ℕ => ℂ) 2`, the canonical separable
    infinite-dimensional complex Hilbert space (ℓ²(ℕ, ℂ)) —
    `NormedAddCommGroup`, `InnerProductSpace ℂ`, and `CompleteSpace`
    all come from mathlib's `Mathlib.Analysis.InnerProductSpace.l2Space`.

    **This is NOT the Yang-Mills physical state space.** It is a
    real, infinite-dimensional, mathlib-backed Hilbert space chosen
    so the schema below (`YM_mass_gap_statement`) typechecks against
    something real instead of a `sorry`. The actual YM Hilbert space
    requires an Osterwalder–Schrader reconstruction from a
    constructed 4D Euclidean YM measure, which is not in mathlib
    v4.12.0 and is itself an open research problem. See the
    "Task #51 + Task #55 merge note" block immediately above for
    the full honest-scoping argument. -/
abbrev HilbertSpace : Type := lp (fun _ : ℕ => ℂ) 2
-- TODO (mathlib v4.13+ / OS-reconstruction): replace with the actual
-- physical-state Hilbert space of the YM Hamiltonian.

/-- **Yang-Mills Hamiltonian** — concretized (Task #51) as the sum
    of real parts of the matrix traces of the four SU(3) components.
    This is **not** the gauge-invariant field energy
    `∫ tr(F_A ∧ ★F_A)`; it is a real-valued, deterministic function
    of `A` that exercises the genuine `Matrix.trace` API on each
    component. -/
noncomputable def YMHamiltonian (A : SU3Connection) : ℝ :=
  (Finset.univ : Finset (Fin 4)).sum (fun i => ((A i).1).trace.re)
-- TODO (mathlib v4.13+): ∫ tr(F_A ∧ ★F_A) using Distribution.SobolevSpace

/-- **Eigenstate predicate** — concretized (Task #51) as the
    "uniform scaling by μ · ‖ψ‖²" form. `IsEigenstate H ψ` holds
    iff there exists a real scalar `μ` such that for every
    connection `A`, `H A = μ * (‖ψ‖ * ‖ψ‖)`. This is **not** the
    spectral-eigenvector property of an operator on a physical
    Hilbert space; it is the minimal real `Prop` that captures the
    *form* of "H is a constant multiple of ψ's squared norm" and
    lets downstream bricks state eigenstate-flavoured claims
    without `sorryAx`. -/
def IsEigenstate (H : SU3Connection → ℝ) (ψ : HilbertSpace) : Prop :=
  ∃ μ : ℝ, ∀ A : SU3Connection, H A = μ * (‖ψ‖ * ‖ψ‖)
-- TODO (mathlib v4.13+): ψ is a true eigenstate of H as a self-adjoint
-- operator on the YM physical-state Hilbert space.

/-- **Mass gap statement:** `∃ Δ > 0, ∀ eigenstates ψ, E_ψ ≥ Δ`.
    This is NOT a theorem — it is the Clay conjecture restated in
    Lean using the placeholder defs above. It is not in BRICKS.
    With the Task #51 concretizations in place, this now
    type-checks without `sorryAx`, but its *content* is still the
    placeholder schema (finite-dim Hilbert space, sum-of-traces
    Hamiltonian, scaling-form eigenstate predicate), not the Clay
    YM mass gap. -/
def YM_mass_gap_statement : Prop :=
  ∃ Δ : ℝ, 0 < Δ ∧ ∀ (A : SU3Connection) (ψ : HilbertSpace),
    IsEigenstate YMHamiltonian ψ → YMHamiltonian A ≥ Δ

/-- **The zero state is a (trivial) eigenstate of the zero Hamiltonian
    (eighth brick in `MassGap.lean`, first brick to use the Task #51
    concretized schema).**

    For the constant-zero "Hamiltonian" `fun _ => 0` and the zero
    vector `0 : HilbertSpace`, the predicate `IsEigenstate` holds —
    witnessed by `μ = 0`, since `0 = 0 * (‖(0 : HilbertSpace)‖ *
    ‖(0 : HilbertSpace)‖)` by `zero_mul`.

    This brick exists to demonstrate that the concretized
    `HilbertSpace` and `IsEigenstate` are not dead schema: they
    expose enough API (norm, zero vector, multiplication on `ℝ`)
    that a downstream proof can actually mention them by name and
    discharge a genuine Prop. The mathematics is intentionally
    trivial — `0 = 0` — but the *types* (real `EuclideanSpace ℂ
    (Fin 3)` for `ψ`, real `SU3Connection → ℝ` for `H`) are the
    post-Task-#51 schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    says only that the zero vector trivially satisfies the
    placeholder eigenstate predicate against the zero Hamiltonian.
    No claim about the YM Hamiltonian, mass gap, or any QFT
    statement. -/
theorem IsEigenstate_zero_zero :
    IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) (0 : HilbertSpace) :=
  ⟨0, fun _ => (zero_mul _).symm⟩

/-- **Identity acts trivially on each component of an SU(3) connection
    (first real trio-clean brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i`.

    The proof is a one-line delegation to mathlib's `one_mul` on the
    monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`
    (which `specialUnitaryGroup` inherits as a `Submonoid` of
    `Matrix (Fin 3) (Fin 3) ℂ` via `Submonoid.toMonoid`).

    This is **not** new mathematics — it is the trivial left-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema. Its purpose is to be
    the **first real demonstration** that the post-refactor
    `SU3Connection` type is a usable mathlib-flavoured surface,
    rather than an opaque `sorry`-def.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `1 * x = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_one_mul (A : SU3Connection) (i : Fin 4) :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i :=
  one_mul (A i)

/-- **Each component of an SU(3) connection is unitary
    (second real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i`
    satisfies the unitarity equation

      `(A i).1 * star ((A i).1) = 1`

    where `.1` extracts the underlying `Matrix (Fin 3) (Fin 3) ℂ`
    from the `specialUnitaryGroup` subtype.

    The proof unfolds membership through mathlib's
    `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    to extract the unitarity component, then unfolds that through
    `Matrix.mem_unitaryGroup_iff`
    (`A ∈ unitaryGroup n α ↔ A * star A = 1`).

    Unlike `SU3Connection_one_mul` (which only used the abstract
    monoid identity), this brick is **substantive**: it proves the
    defining property of the unitary subgroup — `M M* = I` — using
    the real mathlib `Matrix.unitaryGroup` API, instantiated at the
    SU(3) connection components of our trivial-bundle schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema is in fact unitary — which it is by typing. No claim
    about the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. `HilbertSpace`, `YMHamiltonian`, and `IsEigenstate`
    are all concrete (Task #55 + Task #51 merge), but the
    concretizations are honest stand-ins, NOT the YM physical
    surface (see the "Task #51 + Task #55 merge note" block). -/
theorem SU3Connection_component_unitary (A : SU3Connection) (i : Fin 4) :
    (A i).1 * star (A i).1 = 1 := by
  have h := Matrix.mem_specialUnitaryGroup_iff.mp (A i).2
  exact Matrix.mem_unitaryGroup_iff.mp h.1

/-- **Each component of an SU(3) connection has determinant 1
    (third real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i` has
    determinant `1`:

      `(A i).1.det = 1`.

    This is the *special* in **S**U(3) — the determinant-one
    constraint that distinguishes the special unitary group from
    the full unitary group. The proof unfolds membership through
    mathlib's `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    and projects out the determinant component.

    Together with `SU3Connection_component_unitary` (just above),
    this completes the pair of defining properties of the SU(3)
    subgroup acting on each component of our trivial-bundle
    connection schema: each component matrix is *unitary* AND has
    *determinant one*. These two bricks are the most informative
    use so far of the post-refactor `MassGap.lean` surface —
    actually proving things about the SU(3) structure, not just
    abstract monoid identities.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema has det 1 — which it does by typing. No claim about the
    YM Hamiltonian, mass gap, eigenstates, or any QFT statement. -/
theorem SU3Connection_component_det_one (A : SU3Connection) (i : Fin 4) :
    (A i).1.det = 1 :=
  (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).2

/-- **Right-identity for SU(3) connection components
    (fourth brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i`.

    The proof is a one-line delegation to mathlib's `mul_one` on
    the monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`.
    This is the right-identity companion to `SU3Connection_one_mul`
    (left-identity); together they say the SU(3) monoid identity
    fixes every component on both sides.

    This is **not** new mathematics — it is the trivial right-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `x * 1 = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_mul_one (A : SU3Connection) (i : Fin 4) :
    A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i :=
  mul_one (A i)

/-- **The SU(3) monoid identity squares to itself
    (fifth brick in `MassGap.lean`).**

    `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1`.

    A one-line `mul_one 1` on the SU(3) submonoid. Trivial as
    monoid arithmetic, but the *type* is real SU(3) — not a stub,
    not a placeholder. The lemma exists to give downstream proofs
    a stable rewrite for `1 * 1` simplifications on SU(3) elements.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that `1 * 1 = 1` in the SU(3) submonoid. No claim about
    the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. -/
theorem SU3Connection_one_one :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1 :=
  mul_one 1

/-- **Product of two SU(3)-connection components is unitary
    (sixth brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `(A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ`.

    The proof invokes `Submonoid.mul_mem` on the unitary submonoid:
    if `A i` is unitary and `B i` is unitary, their matrix product
    is unitary. The unitarity of each factor is `component_unitary`
    extracted via `Matrix.mem_specialUnitaryGroup_iff.mp _ |>.1`.

    Genuine algebraic content: it exercises submonoid closure of
    `Matrix.unitaryGroup` under multiplication, a real mathlib
    structure result, not just a definitional unfolding.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that U(3) is closed under matrix multiplication — true by
    definition of the unitary group. No claim about Yang-Mills
    dynamics, mass gap, or any QFT result. -/
theorem SU3Connection_component_mul_unitary
    (A B : SU3Connection) (i : Fin 4) :
    (A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ :=
  (Matrix.unitaryGroup (Fin 3) ℂ).mul_mem
    (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).1
    (Matrix.mem_specialUnitaryGroup_iff.mp (B i).2).1

/-- **Product of two SU(3)-connection components still has determinant 1
    (seventh brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `((A i).1 * (B i).1).det = 1`.

    The proof uses `Matrix.det_mul` (the genuine multiplicative
    property of the determinant — a real mathlib theorem, not a
    definitional unfolding) together with `component_det_one` on
    each factor; `mul_one` finishes.

    Genuine algebraic content: it exercises `Matrix.det_mul`,
    which is the key fact that `det : Matrix n n R → R` is a
    monoid homomorphism. This is the closure-under-multiplication
    proof for the determinant-1 hyperplane, the SL-side of the
    SU(3) algebraic structure (companion to
    `SU3Connection_component_mul_unitary`, the U-side).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that SL(3) ⊃ SU(3) is closed under matrix multiplication
    — true by multiplicativity of the determinant. No claim about
    the Yang-Mills mass gap, dynamics, or any QFT result. -/
theorem SU3Connection_component_mul_det_one
    (A B : SU3Connection) (i : Fin 4) :
    ((A i).1 * (B i).1).det = 1 := by
  rw [Matrix.det_mul, SU3Connection_component_det_one,
      SU3Connection_component_det_one, mul_one]

/-- **Associativity of multiplication on SU(3) connection components
    (eighth real brick in `MassGap.lean`).**

    For any three `SU3Connection`s `A`, `B`, `C` and any spacetime
    direction `i : Fin 4`, the component-wise product is associative:

      `(A i * B i) * C i = A i * (B i * C i)`.

    This is the associativity law of the
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid, instantiated at
    the connection components. It completes the standard set of
    monoid laws (`one_mul`, `mul_one`, `mul_assoc`) on the
    trivial-bundle SU(3) schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open`. It is a monoid identity, not a
    statement about Yang-Mills dynamics. -/
theorem SU3Connection_mul_assoc (A B C : SU3Connection) (i : Fin 4) :
    (A i * B i) * C i = A i * (B i * C i) :=
  mul_assoc (A i) (B i) (C i)

/-- **Left-unitary law on SU(3) connection components
    (ninth real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix satisfies the
    *other* side of the unitary law:

      `star (A i).1 * (A i).1 = 1`.

    Companion to `SU3Connection_component_unitary`, which proves
    `(A i).1 * star (A i).1 = 1`. The pair together is the full
    two-sided unitary law on each component matrix; for unitary
    matrices, `star` IS the inverse (`A⁻¹ = star A`), so this is
    the inverse-cancellation law in disguise. We state it directly
    at the matrix level via `star` rather than via `⁻¹` because
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` is a `Submonoid` (no
    `Group` / `Inv` instance) in mathlib v4.12.0 — the closure of
    the determinant-one constraint under inverse is true but not
    instantiated. Working through `star` on the underlying matrix
    sidesteps that and keeps the proof one line.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A unitary-matrix identity, not a
    statement about YM dynamics. Tower status unchanged: **Open**. -/
theorem SU3Connection_component_star_mul_self
    (A : SU3Connection) (i : Fin 4) :
    star (A i).1 * (A i).1 = 1 := by
  have h := Matrix.mem_specialUnitaryGroup_iff.mp (A i).2
  exact Matrix.mem_unitaryGroup_iff'.mp h.1

/-- **The star of an SU(3) connection component still has
    determinant 1 (tenth real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`:

      `(star (A i).1).det = 1`.

    Concretely, the conjugate-transpose of an SU(3) matrix is
    again an SU(3) matrix — it is unitary (the companion brick
    `SU3Connection_component_star_mul_self` is one half of that)
    and its determinant is `star 1 = 1`. The proof uses
    `Matrix.det_conjTranspose` (`(star A).det = star A.det`) plus
    `SU3Connection_component_det_one`.

    This brick + `SU3Connection_component_star_mul_self` together
    witness in proof-text that `star (A i).1 ∈ SU(3)`, recovering
    the "closed under inverse" content of an SU(3) group structure
    without needing an `Inv` instance on `specialUnitaryGroup`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A determinant identity, not a
    statement about YM dynamics. Tower status unchanged: **Open**. -/
theorem SU3Connection_component_star_det_one
    (A : SU3Connection) (i : Fin 4) :
    (star (A i).1).det = 1 := by
  -- `star` on a complex matrix is definitionally `Matrix.conjTranspose`,
  -- but `rw` needs the syntactic `·ᴴ.det` shape, so reshape the goal
  -- first, then apply `Matrix.det_conjTranspose`.
  show (Matrix.conjTranspose (A i).1).det = 1
  rw [Matrix.det_conjTranspose, SU3Connection_component_det_one, star_one]

/-! ### Task #88: module-boundary alias to the real Wilson action

    `YMHamiltonianReal` exposes
    `PlaquetteAction.YMHamiltonianWilson` (the genuine
    site-shifted Wilson plaquette action on `Lattice4D 1`) under
    a name living in `MassGap.lean`, so callers comparing the
    placeholder against the real action can pick both up from a
    single import. **`YMHamiltonianReal` is the canonical
    going-forward Hamiltonian surface.** The legacy placeholder
    `YMHamiltonian` (above) is preserved for backward
    compatibility with `Towers.YM.Spectrum` Batches 8–15. -/

/-- **`YMHamiltonianReal`** — module-boundary alias for
`PlaquetteAction.YMHamiltonianWilson`, the real site-shifted
Wilson plaquette action on `Lattice4D 1` evaluated on a constant
SU(3) connection. This is the Task #88 canonical replacement for
the trace-sum placeholder `YMHamiltonian` above; new YM work
should target `YMHamiltonianReal`. The placeholder stays as the
**Legacy placeholder schema** (see the section header below) so
that the ~25 dependent bricks in `Towers.YM.Spectrum` Batches
8–15 stay green. -/
noncomputable def YMHamiltonianReal (A : SU3Connection) : ℝ :=
  PlaquetteAction.YMHamiltonianWilson A

/-- **Brick (`YMHamiltonianReal_vacuum_eq_zero`).** The
module-boundary alias agrees with the underlying Wilson action:
the all-ones SU(3) connection sits at the **minimum** `0` of the
real Wilson plaquette action. The going-forward counterpart of
the legacy `YMHamiltonian_one_eq_twelve` (placeholder value
`12`). Re-exporting the
`PlaquetteAction.YMHamiltonianWilson_vacuum_eq_zero` content
under a `MassGap`-namespaced name. -/
theorem YMHamiltonianReal_vacuum_eq_zero :
    YMHamiltonianReal
        (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
      = 0 :=
  PlaquetteAction.YMHamiltonianWilson_vacuum_eq_zero

/-! ### Legacy placeholder schema — Task #55 load-bearing bricks
    on the trace-sum `YMHamiltonian` (preserved for backward
    compatibility with `Towers.YM.Spectrum` Batches 8–15)

    **The four bricks below operate on the legacy placeholder
    `YMHamiltonian` (trace-sum stand-in), not on the canonical
    `YMHamiltonianReal` / `PlaquetteAction.YMHamiltonianWilson`
    surface.** They each reference at least one of the Task #51
    + Task #55 concretized placeholder schema defs
    (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) — and
    three of them reference at least two — proving the
    placeholder schema is genuinely load-bearing rather than
    window dressing. None of them advances the YM tower past
    `Status: Open` (see `docs/ROADMAP.md` § 2); they are
    foundation bricks under the *placeholder* schema. New YM
    work should target `YMHamiltonianReal`. -/

/-- **The all-ones SU(3) connection has placeholder Hamiltonian value 12
    — honest numerical placeholder restatement (Task #88).**

    For the constant SU(3) connection `A = fun _ => 1` (the identity
    matrix in every spacetime direction):

      `YMHamiltonian A = 12`     (placeholder trace-sum value)

    Proof: each component contributes `((1 : SU(3)).1).trace.re`.
    The coercion `(1 : SU(3)).1` is the `3×3` identity matrix
    (`Submonoid.coe_one`), whose trace equals `Fintype.card (Fin 3) = (3 : ℂ)`
    via `Matrix.trace_one`, whose real part is `3`. Summing over the
    four spacetime directions gives `4 * 3 = 12`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest numerical placeholder (Task #88 framing).** The value
    `12 = 4 · 3` is `(# spacetime dimensions) · (dim SU(3)
    fundamental rep)` — an artefact of the trace-sum *placeholder*
    schema `YMHamiltonian A := ∑_μ Re tr(A μ)`, NOT a Yang-Mills
    field-energy. The going-forward **real Wilson plaquette action**
    over a real `Lattice4D` config is in
    `Towers.YM.PlaquetteAction.YMHamiltonianWilson`; on the same
    all-ones connection it returns `0` (proved in
    `Towers.YM.PlaquetteAction.YMHamiltonianWilson_vacuum_eq_zero`),
    because every plaquette `1 · 1 · 1* · 1* = 1` and the standard
    Wilson sum `∑(3 − Re tr(P)) / 3` collapses to `0`. The contrast
    `12` (placeholder) vs. `0` (real Wilson action) is what makes
    this lemma an honest *numerical placeholder*: it documents the
    trace-sum stand-in's evaluation, not the physical YM
    ground-state energy. The lemma is kept (rather than deleted)
    so that the ~25 Spectrum-track bricks in `Towers.YM.Spectrum`
    Batches 8–15 — which are explicitly tagged as bricks *on the
    placeholder schema* — stay green. New work should target
    `YMHamiltonianWilson`. YM tower status unchanged: **Open**
    (`docs/ROADMAP.md` § 2). -/
theorem YMHamiltonian_one_eq_twelve :
    YMHamiltonian (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
      = 12 := by
  simp [YMHamiltonian, Submonoid.coe_one, Matrix.trace_one]
  norm_num

/-- **The constant-zero Hamiltonian has every Hilbert-space vector
    as an eigenstate (Task #55, brick on `HilbertSpace` +
    `IsEigenstate`).**

    For any `ψ : HilbertSpace` (= `lp (fun _ : ℕ => ℂ) 2`):

      `IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) ψ`.

    Witnessed by `μ = 0`, since `0 = 0 * (‖ψ‖ * ‖ψ‖)` by `zero_mul`,
    for every connection `A`.

    This generalises `IsEigenstate_zero_zero` (which fixed `ψ = 0`)
    to *every* vector in the placeholder Hilbert space — i.e. the
    zero Hamiltonian is degenerate on all of ℓ²(ℕ,ℂ). The brick
    exercises both concretized types (`HilbertSpace` and
    `IsEigenstate`) on an arbitrary `ψ`, proving the schema's
    `ψ`-slot is not vacuously specialised to `0`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This says only that the trivial
    "always 0" map satisfies the placeholder scaling-form
    eigenstate predicate against every ℓ²(ℕ,ℂ) vector — vacuous
    as Yang-Mills physics. Tower status unchanged: **Open**. -/
theorem IsEigenstate_zero_const (ψ : HilbertSpace) :
    IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) ψ :=
  ⟨0, fun _ => (zero_mul _).symm⟩

/-- **Any Hamiltonian that is identically zero satisfies the
    eigenstate predicate against every Hilbert-space vector
    (Task #55, brick on `HilbertSpace` + `IsEigenstate`).**

    For any `H : SU3Connection → ℝ` with `∀ A, H A = 0` and any
    `ψ : HilbertSpace`:

      `IsEigenstate H ψ`.

    Witnessed by `μ = 0`: `H A = 0 = 0 * (‖ψ‖ * ‖ψ‖)`. Generalises
    `IsEigenstate_zero_const` (above) from the literal `fun _ => 0`
    to *any* extensionally-zero Hamiltonian. Useful as a rewrite
    target downstream: if a proof reduces some Hamiltonian to the
    zero function pointwise, this brick discharges the eigenstate
    goal in one step.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A statement about the placeholder
    eigenstate predicate, not the Yang-Mills spectrum. Tower
    status unchanged: **Open**. -/
theorem IsEigenstate_of_forall_zero
    (H : SU3Connection → ℝ) (hH : ∀ A, H A = 0) (ψ : HilbertSpace) :
    IsEigenstate H ψ :=
  ⟨0, fun A => by rw [hH A, zero_mul]⟩

/-- **The Yang-Mills Hamiltonian is NOT an eigenstate at the zero
    Hilbert-space vector (Task #55, brick combining all three
    concretized defs: `HilbertSpace`, `YMHamiltonian`,
    `IsEigenstate`).**

      `¬ IsEigenstate YMHamiltonian (0 : HilbertSpace)`.

    Proof: if `IsEigenstate YMHamiltonian 0` held, there would be a
    `μ : ℝ` with `∀ A, YMHamiltonian A = μ * (‖(0 : HilbertSpace)‖ *
    ‖0‖) = μ * 0 = 0`. Instantiating at `A = fun _ => 1` and
    invoking `YMHamiltonian_one_eq_twelve` (just above) gives
    `(12 : ℝ) = 0`, a contradiction via `norm_num`.

    This is the most substantive brick in `MassGap.lean` so far on
    the post-Task-#51 schema: it references **all three** concretized
    defs (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) and the
    previous brick (`YMHamiltonian_one_eq_twelve`), and derives a
    genuine `False` from the conjunction. Concretely it says the
    placeholder Hamiltonian is non-trivial: it does NOT satisfy the
    placeholder eigenstate predicate at the zero vector, because the
    Hamiltonian itself is non-zero (at the all-ones connection).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is a statement about the
    placeholder schema, not the YM physical Hamiltonian on the YM
    physical Hilbert space. The "Hamiltonian" is a sum of matrix
    traces, the "Hilbert space" is ℓ²(ℕ,ℂ), and the "eigenstate"
    predicate is the scaling-form `Prop`. The brick is honest
    about the schema being non-trivial; it makes no Yang-Mills
    physics claim. Tower status unchanged: **Open**. -/
theorem YMHamiltonian_not_isEigenstate_zero :
    ¬ IsEigenstate YMHamiltonian (0 : HilbertSpace) := by
  rintro ⟨μ, h⟩
  have h1 := h (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
  rw [YMHamiltonian_one_eq_twelve, norm_zero, mul_zero, mul_zero] at h1
  norm_num at h1

/-! ### Infinite-dimensionality witness for `HilbertSpace`

    Task #55 upgraded `HilbertSpace` from a finite-dim placeholder
    to `lp (fun _ : ℕ => ℂ) 2`. The three bricks below witness
    that the upgrade is real: the canonical `lp.single` family
    indexed by `ℕ` is orthonormal in `HilbertSpace`, hence linearly
    independent, hence `HilbertSpace` is NOT finite-dimensional
    over `ℂ`.

    This is the "prove infinite_dim" half of Task #55 (Branch A) /
    Her's tri-parallel HilbertSpace ask. The other two branches
    Her proposed (`SymmetricFockSpace` over `L² ⊗ su(3)`; subtype
    `{f // MemLp f 2 volume}`) are not landable on mathlib v4.12.0
    — Fock-space machinery is absent from mathlib at this version,
    and the raw `MemLp`-subtype is not a Hilbert space (no
    a.e.-quotient ⇒ only a semi-inner-product). Branch A's
    full `Lp ℝ³ → su(3)` carrier requires a `NormedSpace ℝ` on
    `↥su3_submodule` that is not yet built (next batch, per the
    Step 2.5 architect note). So this turn lands the witness on
    the existing canonical ∞-dim ℓ²(ℕ,ℂ) carrier, which is the
    most that can be claimed honestly today.

    Tower status unchanged: **Open**. Real `Module ℂ`-rank of the
    YM physical-state space is not in scope. -/

/-- The canonical `lp.single` family at value `1 : ℂ`, indexed by
    `ℕ`. Used to witness that `HilbertSpace = lp (fun _ => ℂ) 2`
    is infinite-dimensional. -/
noncomputable def hilbertCanonicalFamily : ℕ → HilbertSpace :=
  fun n => lp.single 2 n (1 : ℂ)

/-- The canonical `lp.single`-at-`1` family is orthonormal in
    `HilbertSpace`. Norm-one from `lp.norm_single`; pairwise inner
    zero from `lp.inner_single_left` and `lp.single_apply_ne`. -/
theorem hilbertCanonicalFamily_orthonormal :
    Orthonormal ℂ hilbertCanonicalFamily := by
  rw [orthonormal_iff_ite]
  intro i j
  simp only [hilbertCanonicalFamily, lp.inner_single_left, lp.single_apply]
  by_cases h : i = j
  · subst h
    simp
  · rw [dif_neg h]
    simp [h]

/-- **`HilbertSpace` is infinite-dimensional over `ℂ`.**

    Witness: the canonical orthonormal family
    `hilbertCanonicalFamily : ℕ → HilbertSpace` is linearly
    independent (from `Orthonormal.linearIndependent`), and any
    finite-dimensional space cannot host a linearly independent
    family indexed by an infinite type
    (`Module.Finite.not_linearIndependent_of_infinite`).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This brick proves the *carrier*
    `lp (fun _ : ℕ => ℂ) 2` is genuinely infinite-dimensional. It
    does **not** prove anything about the Yang-Mills physical-state
    Hilbert space, which is still an open research surface
    (Wightman / Osterwalder–Schrader reconstruction not in
    mathlib v4.12.0). Tower status: **Open**. -/
theorem HilbertSpace_not_finiteDimensional :
    ¬ FiniteDimensional ℂ HilbertSpace := fun _ =>
  Module.Finite.not_linearIndependent_of_infinite hilbertCanonicalFamily
    hilbertCanonicalFamily_orthonormal.linearIndependent

/-! ### Task #61: a real two-sided bound on the YM Hamiltonian schema

    The brick below proves `∀ A, |YMHamiltonian A| ≤ 12`. Each
    component `(A i).1` is a `3×3` SU(3) matrix, so each diagonal
    entry has norm ≤ 1 (rows of a unitary matrix are unit vectors),
    hence `|((A i).1) j j|.re ≤ 1`, hence `|((A i).1).trace.re| ≤ 3`,
    hence `|YMHamiltonian A| = |∑ i, ((A i).1).trace.re| ≤ 4 · 3 = 12`.

    Unlike the prior point-value bricks (`YMHamiltonian_one_eq_twelve`
    pins one input; `YMHamiltonian_not_isEigenstate_zero` derives one
    contradiction), this is a *uniform* inequality that holds across
    the entire schema's input space — the first genuine
    `∀ A, _ ≤ _` bound in `MassGap.lean`. It exercises the real SU(3)
    structure (unitarity → entrywise bound), the trace API, the
    `Complex.abs_re_le_abs` triangle bound on `Re ↪ ℂ`, and the
    `Finset.abs_sum_le_sum_abs` / `Finset.single_le_sum` /
    `Finset.sum_le_sum` toolkit.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is still a bound on the
    placeholder sum-of-traces schema, NOT the Yang-Mills field
    energy `∫ tr(F ∧ ★F)`. The constant `12 = 4 · 3` is
    `(spacetime-dim) · (SU(3)-fundamental-rep-dim)`, an artefact of
    the schema, not a physical energy scale. The brick proves the
    schema is *bounded* — a real, uniform inequality — which is a
    step toward stating a meaningful "gap" predicate inside the
    schema, but does NOT prove the Yang-Mills mass gap. YM tower
    status unchanged: **Open** (see `docs/ROADMAP.md` § 2). -/
theorem YMHamiltonian_abs_le_twelve (A : SU3Connection) :
    |YMHamiltonian A| ≤ 12 := by
  -- Helper 1: each diagonal entry of a 3×3 unitary matrix has norm ≤ 1.
  have diag_norm_le_one : ∀ (U : Matrix (Fin 3) (Fin 3) ℂ),
      U * star U = 1 → ∀ i : Fin 3, ‖U i i‖ ≤ 1 := by
    intro U hU i
    have hd : (U * star U) i i = (1 : Matrix (Fin 3) (Fin 3) ℂ) i i := by rw [hU]
    rw [Matrix.one_apply_eq, Matrix.mul_apply] at hd
    have step : ∀ k, U i k * (star U : Matrix _ _ ℂ) k i = ((‖U i k‖ ^ 2 : ℝ) : ℂ) := by
      intro k
      rw [Matrix.star_apply]
      have h := RCLike.mul_conj (K := ℂ) (U i k)
      exact_mod_cast h
    simp_rw [step] at hd
    have hd_real : ∑ k, ‖U i k‖ ^ 2 = (1 : ℝ) := by
      have h := hd
      rw [← Complex.ofReal_sum] at h
      exact_mod_cast h
    have hsum : ‖U i i‖ ^ 2 ≤ ∑ k, ‖U i k‖ ^ 2 :=
      Finset.single_le_sum (f := fun k : Fin 3 => ‖U i k‖ ^ 2)
        (fun k _ => sq_nonneg _) (Finset.mem_univ i)
    rw [hd_real] at hsum
    nlinarith [norm_nonneg (U i i)]
  -- Helper 2: each component's trace.re is in [-3, 3].
  have abs_trace_re_le_three : ∀ (U : Matrix (Fin 3) (Fin 3) ℂ),
      U * star U = 1 → |U.trace.re| ≤ 3 := by
    intro U hU
    have h1 : U.trace.re = ∑ i : Fin 3, (U i i).re := by
      rw [Matrix.trace, Complex.re_sum]; rfl
    rw [h1]
    calc |∑ i : Fin 3, (U i i).re|
        ≤ ∑ i : Fin 3, |(U i i).re| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ _i : Fin 3, (1 : ℝ) := by
          apply Finset.sum_le_sum
          intro i _
          calc |(U i i).re| ≤ ‖U i i‖ := Complex.abs_re_le_abs _
            _ ≤ 1 := diag_norm_le_one U hU i
      _ = 3 := by simp
  -- Main: sum over four components.
  unfold YMHamiltonian
  calc |∑ i : Fin 4, ((A i).1).trace.re|
      ≤ ∑ i : Fin 4, |((A i).1).trace.re| := Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ _i : Fin 4, (3 : ℝ) := by
        apply Finset.sum_le_sum
        intro i _
        exact abs_trace_re_le_three _
          (Matrix.mem_unitaryGroup_iff.mp
            (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).1)
    _ = 12 := by simp; norm_num

/-! ### Task #67: the Task #61 bound is tight — saturated at the all-ones connection

    `YMHamiltonian_abs_le_twelve` proves `∀ A, |YMHamiltonian A| ≤ 12`.
    `YMHamiltonian_one_eq_twelve` proves the all-ones SU(3) connection
    evaluates to `12`. Combining the two: the bound is saturated, so
    `12` is a genuine supremum on the schema, not merely an upper
    bound. This brick states the tightness witness directly:
    `|YMHamiltonian (fun _ => 1)| = 12`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** Tightness of the placeholder
    sum-of-traces bound, NOT of any Yang-Mills field-energy bound.
    The saturating "connection" is the trivial SU(3)-all-ones map;
    the saturating value `12 = 4 · 3` is `(spacetime-dim) ·
    (SU(3)-fundamental-rep-dim)`, an artefact of the schema, not
    a physical energy. YM tower status unchanged: **Open**
    (`docs/ROADMAP.md` § 2). -/
theorem YMHamiltonian_abs_le_twelve_tight :
    |YMHamiltonian (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))|
      = 12 := by
  rw [YMHamiltonian_one_eq_twelve]
  norm_num

/-! ### Task #68: a real "mass gap" predicate inside the placeholder schema

    `YMHamiltonian_abs_le_twelve` (Task #61) gives a real *uniform
    upper* bound `∀ A, |YMHamiltonian A| ≤ 12`. The next move is to
    define a Lean predicate `MassGap (Δ : ℝ)` inside the placeholder
    schema that resembles the *shape* of the Clay Yang-Mills mass-gap
    conjecture: a strictly positive `Δ` plus a uniform lower bound
    on `YMHamiltonian A` across all non-zero eigenstates of the
    placeholder Hamiltonian.

    The shape used below is

      `0 < Δ ∧ ∀ (ψ : HilbertSpace) (A : SU3Connection),
         IsEigenstate YMHamiltonian ψ → ψ ≠ 0 → Δ ≤ YMHamiltonian A`

    — directly following the task description, with the eigenstate
    quantifier mirroring "lowest excitation above the vacuum".

    Two trio-clean bricks exercise the new predicate:

    * `MassGap_pos` — projection: any `MassGap Δ` forces `0 < Δ`.
      Trivial as logic; non-trivial as documentation, since it pins
      the positivity clause of the Clay-flavoured shape.

    * `MassGap_le_twelve_of_witness` — the honest conditional
      version of "MassGap Δ → Δ ≤ 12": *given any non-zero
      eigenstate witness `ψ`*, `MassGap Δ` forces `Δ ≤ 12`. The
      proof instantiates the universal quantifier at the all-ones
      SU(3) connection and rewrites via `YMHamiltonian_one_eq_twelve`.
      The conditional shape is honest: in the current placeholder
      schema no non-zero eigenstate is known to exist (and Task #61's
      `YMHamiltonian_not_isEigenstate_zero` already rules out
      `ψ = 0`), so unconditionally proving `MassGap Δ → Δ ≤ 12`
      would require either constructing such a witness or proving
      none exists — neither of which is in scope for this brick.

    **Honest scoping reminder.** The new predicate is defined on the
    placeholder schema (`HilbertSpace = ℓ²(ℕ,ℂ)`,
    `YMHamiltonian = ∑ trace.re`, scaling-form `IsEigenstate`), NOT
    on the YM physical surface. `MassGap Δ` here is NOT the Clay
    mass-gap predicate — that requires the OS-reconstructed YM
    Hilbert space, the gauge-invariant field-energy Hamiltonian
    `∫ tr(F ∧ ★F)`, and the spectral-eigenvector property of a
    self-adjoint operator on the physical Hilbert space, none of
    which exist in mathlib v4.12.0. YM tower status unchanged:
    **Open** (`docs/ROADMAP.md` § 2). -/

/-- **Mass-gap predicate (placeholder schema).**

    `MassGap Δ` holds iff `Δ > 0` and for every non-zero placeholder
    eigenstate `ψ` of `YMHamiltonian`, the Hamiltonian is uniformly
    bounded below by `Δ` over the entire `SU3Connection` input space.

    This is the placeholder-schema analogue of the Clay Yang-Mills
    mass-gap statement; it is **NOT** the Clay statement itself
    (which is about the YM physical-state Hilbert space and the
    gauge-invariant field-energy Hamiltonian). See the file header
    and the Task #68 section header above for the full honest-scope
    argument. -/
def MassGap (Δ : ℝ) : Prop :=
  0 < Δ ∧ ∀ (ψ : HilbertSpace) (A : SU3Connection),
    IsEigenstate YMHamiltonian ψ → ψ ≠ 0 → Δ ≤ YMHamiltonian A

/-- **Positivity projection of the mass-gap predicate
    (first Task #68 brick).**

    `MassGap Δ → 0 < Δ`. The positivity clause of the Clay-flavoured
    shape, projected out as a stand-alone fact. Witness:
    `And.left` on the `MassGap` definition.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** Statement about the placeholder
    `MassGap` predicate on the placeholder YM schema, NOT about the
    Clay Yang-Mills mass gap. Tower status unchanged: **Open**. -/
theorem MassGap_pos {Δ : ℝ} (h : MassGap Δ) : 0 < Δ := h.1

/-- **Conditional upper bound on any mass gap (second Task #68 brick,
    combining `MassGap`, `IsEigenstate`, `YMHamiltonian`, and
    `YMHamiltonian_one_eq_twelve`).**

    Given any non-zero eigenstate `ψ` of `YMHamiltonian`,
    `MassGap Δ → Δ ≤ 12`.

    Proof: `MassGap Δ` instantiated at this `ψ` and the all-ones
    SU(3) connection gives `Δ ≤ YMHamiltonian (fun _ => 1)`;
    `YMHamiltonian_one_eq_twelve` rewrites the right-hand side to
    `12`.

    The conditional `IsEigenstate YMHamiltonian ψ → ψ ≠ 0` shape is
    deliberate. In the current placeholder schema:

    * `YMHamiltonian_not_isEigenstate_zero` (Task #55) rules out
      `ψ = 0` as an eigenstate of `YMHamiltonian`, AND
    * no non-zero eigenstate of `YMHamiltonian` has been constructed
      (the schema's `IsEigenstate` predicate is the uniform-scaling
      form `∃ μ, ∀ A, H A = μ * ‖ψ‖²`, which would force
      `YMHamiltonian` to be constant on `SU3Connection` — and the
      all-ones-vs-other-SU(3)-connection distinction is not yet
      formalised in this file).

    So unconditionally proving `MassGap Δ → Δ ≤ 12` would require
    either (a) constructing a non-zero placeholder eigenstate, or
    (b) proving none exists, neither of which is in scope for this
    brick. The conditional version above is the honest landing
    point.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** Statement about the placeholder
    schema, NOT the Clay Yang-Mills mass gap. The constant `12` is
    `(# spacetime directions) · (dim SU(3) fundamental rep) = 4·3`,
    an artefact of the placeholder sum-of-traces Hamiltonian, NOT a
    physical energy scale. Tower status unchanged: **Open**
    (`docs/ROADMAP.md` § 2). -/
theorem MassGap_le_twelve_of_witness {Δ : ℝ} (h : MassGap Δ)
    {ψ : HilbertSpace} (hψ : IsEigenstate YMHamiltonian ψ)
    (hne : ψ ≠ 0) : Δ ≤ 12 := by
  have h1 := h.2 ψ (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
    hψ hne
  rwa [YMHamiltonian_one_eq_twelve] at h1

/-! ### Task #77: rule out every eigenstate of the placeholder YMHamiltonian

    `MassGap_le_twelve_of_witness` (Task #68) is conditional on a
    non-zero eigenstate witness, because none is known to exist in
    the placeholder schema. The bricks below close that gap: the
    placeholder `YMHamiltonian` admits *no* eigenstate at all, hence
    in particular no non-zero one. The conditional Task #68 brick
    therefore has a vacuously satisfied hypothesis, and the
    universally-quantified clause of `MassGap` collapses to
    `MassGap Δ ↔ 0 < Δ`.

    The argument: `IsEigenstate YMHamiltonian ψ` unfolds to
    `∃ μ : ℝ, ∀ A, YMHamiltonian A = μ * (‖ψ‖ * ‖ψ‖)`, which would
    force `YMHamiltonian` to be a *constant* function on
    `SU3Connection`. But the all-ones SU(3) connection evaluates to
    `12` (`YMHamiltonian_one_eq_twelve`), while the all-`diag(-1,-1,1)`
    SU(3) connection evaluates to `-4`
    (`YMHamiltonian_diagNegOneOne_eq_neg_four`). Two distinct values
    on the schema's input space ⇒ no eigenstate exists.

    The second connection is built around the real SU(3) matrix
    `diag(-1, -1, 1)`: determinant `(-1)·(-1)·1 = 1`, unitary because
    every diagonal entry has modulus one. Its trace is `-1`, so the
    sum over the four spacetime directions is `4·(-1) = -4`.

    **Honest scoping.** Vacuity of the placeholder schema is
    *expected* and is what this brick wave demonstrates. It confirms
    the schema is **not** the Clay Yang-Mills surface (which would
    have a real non-empty eigenspace and a non-zero spectral gap on
    the OS-reconstructed physical Hilbert space); it does **NOT**
    prove the Clay Yang-Mills mass gap. YM tower status unchanged:
    **Open** (`docs/ROADMAP.md` § 2). -/

/-- **The SU(3) matrix `diag(-1, -1, 1)`** — concrete second
    connection-component used to witness that `YMHamiltonian` is not
    constant on `SU3Connection`. Real diagonal, determinant
    `(-1)·(-1)·1 = 1`, unitary because each diagonal entry has
    modulus one (so `M * star M = diag(|-1|², |-1|², |1|²) = 1`).

    Built via `Matrix.mem_specialUnitaryGroup_iff` + the
    `ext + fin_cases + simp` matrix-literal pattern already used in
    `Towers/YM/SU3Basis.lean` for the Gell-Mann generators. -/
noncomputable def diagNegOneOneMat :
    Matrix.specialUnitaryGroup (Fin 3) ℂ :=
  ⟨!![(-1 : ℂ), 0, 0; 0, -1, 0; 0, 0, 1], by
    rw [Matrix.mem_specialUnitaryGroup_iff]
    refine ⟨?_, ?_⟩
    · rw [Matrix.mem_unitaryGroup_iff]
      ext i j
      fin_cases i <;> fin_cases j <;>
        simp [Matrix.mul_apply, Matrix.star_apply, Matrix.one_apply,
              Fin.sum_univ_three, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.of_apply, star_neg, star_one, star_zero]
    · rw [Matrix.det_fin_three]
      simp [Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
            Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
            Matrix.cons_val_fin_one, Matrix.of_apply]⟩

/-- **The all-`diag(-1,-1,1)` SU(3) connection has Hamiltonian value
    `-4` (Task #77 numerical witness).**

    For the constant connection `A = fun _ => diagNegOneOneMat`,
    each component contributes `trace.re = -1 + -1 + 1 = -1`; summing
    over the four spacetime directions gives `4 · (-1) = -4`.

    Companion to `YMHamiltonian_one_eq_twelve` (which gives `12` on
    the all-ones connection). The two values `12 ≠ -4` are exactly
    what `YMHamiltonian_no_eigenstate` below exploits to rule out
    every eigenstate of `YMHamiltonian` under the placeholder
    scaling-form eigenstate predicate.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest numerical placeholder (Task #88 framing).** A
    point-value calculation on the **placeholder** sum-of-traces
    schema, not a Yang-Mills field-energy computation. The
    going-forward real Wilson plaquette action over a real
    `Lattice4D` config (`Towers.YM.PlaquetteAction.YMHamiltonianWilson`)
    returns `0` on the all-`diagNegOneOneMat` connection — every
    component commutes with itself, so every plaquette
    `U · U · U* · U* = 1` reduces to the identity and the standard
    Wilson sum `∑(3 − Re tr(P)) / 3` collapses to `0`. The contrast
    `−4` (placeholder) vs. `0` (real Wilson action) makes this
    lemma an honest *numerical placeholder*: it documents the
    trace-sum stand-in's evaluation on a non-trivial concrete SU(3)
    matrix, not a YM-physics excited-state energy. Kept for
    backward compatibility with `YMHamiltonian_no_eigenstate` and
    the Spectrum-track placeholder bricks. New work should target
    `YMHamiltonianWilson`. YM tower status unchanged: **Open**
    (`docs/ROADMAP.md` § 2). -/
theorem YMHamiltonian_diagNegOneOne_eq_neg_four :
    YMHamiltonian (fun _ : Fin 4 => diagNegOneOneMat) = -4 := by
  show (Finset.univ : Finset (Fin 4)).sum
      (fun _ : Fin 4 =>
        ((!![(-1 : ℂ), 0, 0; 0, -1, 0; 0, 0, 1] :
            Matrix (Fin 3) (Fin 3) ℂ).trace).re) = -4
  simp [Fin.sum_univ_four, Matrix.trace_fin_three,
        Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
        Matrix.head_cons, Matrix.head_fin_const, Matrix.empty_val',
        Matrix.cons_val_fin_one, Matrix.of_apply,
        Complex.add_re, Complex.neg_re, Complex.one_re, Complex.zero_re]

/-- **The placeholder `YMHamiltonian` admits no eigenstate
    (Task #77 main brick).**

    For every `ψ : HilbertSpace`, `¬ IsEigenstate YMHamiltonian ψ`.

    Proof: an eigenstate would force `YMHamiltonian` to be constant
    on `SU3Connection` (equal to `μ · ‖ψ‖²`), but
    `YMHamiltonian_one_eq_twelve` gives `12` on the all-ones
    connection and `YMHamiltonian_diagNegOneOne_eq_neg_four` gives
    `-4` on the all-`diag(-1,-1,1)` connection. Transitivity yields
    `(12 : ℝ) = -4`, closed by `norm_num`.

    This strictly strengthens `YMHamiltonian_not_isEigenstate_zero`
    (Task #55), which only ruled out `ψ = 0`. Here, *no* `ψ` —
    zero or non-zero — is an eigenstate.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A statement about the placeholder
    schema's `IsEigenstate` (the uniform-scaling form
    `∃ μ, ∀ A, H A = μ · ‖ψ‖²`), NOT the spectral-eigenvector
    property of a self-adjoint operator on the YM physical Hilbert
    space. The fact that the placeholder eigenset is empty is a
    *vacuity* result confirming the schema is not the Clay
    surface. YM tower status unchanged: **Open**. -/
theorem YMHamiltonian_no_eigenstate (ψ : HilbertSpace) :
    ¬ IsEigenstate YMHamiltonian ψ := by
  rintro ⟨μ, h⟩
  have h1 := h (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
  have h2 := h (fun _ : Fin 4 => diagNegOneOneMat)
  rw [YMHamiltonian_one_eq_twelve] at h1
  rw [YMHamiltonian_diagNegOneOne_eq_neg_four] at h2
  have hcontra : (12 : ℝ) = -4 := h1.trans h2.symm
  norm_num at hcontra

/-- **Every eigenstate of the placeholder `YMHamiltonian` is the
    zero vector (Task #77, task-headline brick).**

    `∀ ψ, IsEigenstate YMHamiltonian ψ → ψ = 0`. Vacuously true
    because `YMHamiltonian_no_eigenstate` proves no eigenstate
    exists at all; the conclusion `ψ = 0` is then `False.elim`-style.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is the placeholder schema's
    eigenset being empty, NOT a Yang-Mills physics statement. See
    the Task #77 section header above for the full honest-scope
    argument. YM tower status unchanged: **Open**. -/
theorem YMHamiltonian_no_nonzero_eigenstate (ψ : HilbertSpace)
    (h : IsEigenstate YMHamiltonian ψ) : ψ = 0 :=
  absurd h (YMHamiltonian_no_eigenstate ψ)

/-- **Vacuous mass-gap theorem: `MassGap Δ ↔ 0 < Δ`
    (Task #77 follow-on brick).**

    The `MassGap` predicate quantifies over non-zero eigenstates of
    `YMHamiltonian` (Task #68). Since
    `YMHamiltonian_no_eigenstate` shows no such eigenstate exists,
    the universal clause of `MassGap` is vacuously satisfied, and
    `MassGap Δ` collapses to `0 < Δ` alone — any positive real
    satisfies it.

    Forward direction is `MassGap_pos`. Reverse direction packages
    `0 < Δ` with the vacuous quantifier (the eigenstate hypothesis
    is contradicted by `YMHamiltonian_no_eigenstate`).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is the *expected* vacuity of
    the placeholder `MassGap` predicate, NOT a proof of the Clay
    Yang-Mills mass-gap conjecture. The placeholder eigenset is
    empty (`YMHamiltonian_no_eigenstate`), so the placeholder gap
    predicate is content-free — exactly the demonstration the
    task description asks for: the placeholder schema cannot carry
    a real Clay-flavoured mass-gap statement. YM tower status
    unchanged: **Open** (`docs/ROADMAP.md` § 2). -/
theorem MassGap_iff_pos {Δ : ℝ} : MassGap Δ ↔ 0 < Δ := by
  refine ⟨fun h => h.1, fun hΔ => ⟨hΔ, ?_⟩⟩
  intro ψ _ hψ _
  exact absurd hψ (YMHamiltonian_no_eigenstate ψ)

end YM
end Towers
end TheoremaAureum
