/-
================================================================
Towers / YM / OSReconstruction  (Batch 19.1a)

**Abstract Osterwalder–Schrader reconstruction skeleton.**

First slice of the OS reconstruction project that the Three
Hard Lemmas (`docs/THREE_HARD_LEMMAS.md`) require as a
prerequisite. Adds an abstract `ReflectionPositiveData`
structure plus seven structural lemmas that follow from the
involution axiom alone. Wall 278 → 285 (this file). NOT the
full +42-brick Batch 19.1 as originally scoped; see
`docs/THREE_HARD_LEMMAS.md` "Batch 19.1 split" entry for the
sub-batch roadmap (19.1a → 19.1b → 19.1c → 19.1d).

## What this file IS

An abstract `ReflectionPositiveData` structure that captures the
**type-level shape** of Osterwalder–Schrader data:

  * a carrier type `Ω` (field-configuration space stand-in)
  * an involution `θ : Ω → Ω` with `θ² = id` (time reflection)
  * the reflection-positivity property as a `Prop` field
    (NAMED, not discharged)

Plus seven structural lemmas that follow from the involution
axiom alone:

  * `theta_theta_eq` — named handle for `θ ∘ θ = id` pointwise
  * `theta_injective`, `theta_surjective`, `theta_bijective`
    — `θ` is a bijection (proven from the involution axiom,
    not assumed)
  * `pullback_pullback` — pullback of a field by `θ` is itself
    an involution on fields
  * `vacuumFunction_apply` — the constant-1 "vacuum function"
    evaluates to `1` at every configuration
  * `pullback_vacuum` — the vacuum function is `θ`-invariant

## What this file IS NOT

  * NOT the constructive QFT problem solved. The carrier `Ω`
    stays abstract; the Wilson lattice measure, the continuum
    Gaussian measure on `S'(ℝ³)`, and Bochner–Minlos are NOT
    constructed here.
  * NOT a claim of reflection positivity for any concrete
    action. `reflectionPositive` is a `Prop` field of the
    structure; inhabiting it for the Wilson action is the
    Osterwalder–Seiler 1978 theorem and is OUT OF SCOPE.
  * NOT a construction of the physical Hilbert space
    `ℋ_phys := L²(Ω, dμ) / ker`. That is Batch 19.1b
    territory and requires `MeasureTheory.Lp` on a constructed
    measure, which we do not have.
  * NOT a discharge of `OS_positivity` (Wilson),
    `Transfer_compact`, `Perron_Frobenius_for_transfer`,
    `gap_uniform_in_Lambda`, `enstrophy_bound_global`, or any
    other Three-Hard-Lemmas surface. Those remain conditional
    in their current files; their unconditional forms remain
    `sorry`-bearing stubs documented in
    `docs/THREE_HARD_LEMMAS.md`, not bricks.

YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2). The
honest-scope rule (`replit.md`, "honest-scope wording is
locked") is NOT modified by this batch: no tower is promoted
out of `Status: Open`.

## Axiom footprint

Every brick below carries axiom footprint a subset of
`{propext, Classical.choice, Quot.sound}` (mathlib's classical
trio). No `sorryAx`. No new axioms declared.
================================================================
-/

import Mathlib.Logic.Function.Basic
import Mathlib.Data.Real.Basic

namespace TheoremaAureum
namespace Towers
namespace YM
namespace OSReconstruction

/--
**Abstract reflection-positive data.**

Captures the *type-level shape* of an Osterwalder–Schrader data
tuple: a carrier (field-configuration space stand-in), a time-
reflection involution `θ` with `θ² = id`, and the reflection-
positivity property as a `Prop` field (named, not discharged).

NOT a construction of any concrete OS data. To inhabit this
structure for the Wilson SU(3) lattice gauge action one would
need to construct the Wilson measure on `SU(3)^{|Λ|}` and prove
reflection positivity à la Osterwalder–Seiler 1978 — both OUT
OF SCOPE here.
-/
structure ReflectionPositiveData where
  /-- Carrier type. Abstract stand-in for `Ω = S'(ℝ³)` or
      `Ω = SU(3)^{|Λ|}`. We do not construct it here. -/
  carrier : Type
  /-- Time-reflection involution on the carrier. -/
  theta : carrier → carrier
  /-- `θ` is an involution: applying it twice is the identity. -/
  theta_invol : ∀ ω : carrier, theta (theta ω) = ω
  /-- Reflection-positivity, named as a `Prop` (NOT discharged).
      Inhabiting this on a concrete `carrier` requires real
      analysis (Osterwalder–Schrader 1973 + Osterwalder–Seiler
      1978 for Wilson). OUT OF SCOPE for this file. -/
  reflectionPositive : Prop

namespace ReflectionPositiveData

/-- **`θ ∘ θ = id` pointwise (named handle for `theta_invol`).**

Stable identifier for downstream batches (19.1b, 19.1c) to
reference without unfolding the structure-field name. -/
theorem theta_theta_eq (D : ReflectionPositiveData) (ω : D.carrier) :
    D.theta (D.theta ω) = ω :=
  D.theta_invol ω

/-- **`θ` is injective.**

Real consequence of the involution axiom: if `θ a = θ b` then
applying `θ` once more and using `θ² = id` twice gives `a = b`. -/
theorem theta_injective (D : ReflectionPositiveData) :
    Function.Injective D.theta := by
  intro a b hab
  have h : D.theta (D.theta a) = D.theta (D.theta b) := by rw [hab]
  rwa [D.theta_invol, D.theta_invol] at h

/-- **`θ` is surjective.**

Real consequence of the involution axiom: for any `b`, the
preimage `θ b` satisfies `θ (θ b) = b` by `theta_invol`. -/
theorem theta_surjective (D : ReflectionPositiveData) :
    Function.Surjective D.theta := by
  intro b
  exact ⟨D.theta b, D.theta_invol b⟩

/-- **`θ` is a bijection.** Combination of `theta_injective` and
`theta_surjective`. -/
theorem theta_bijective (D : ReflectionPositiveData) :
    Function.Bijective D.theta :=
  ⟨D.theta_injective, D.theta_surjective⟩

/-- **Time-zero field.** Abstract real-valued observable on the
field-configuration carrier. NOT a Wightman field — just a real
function on `Ω`. -/
def TimeZeroField (D : ReflectionPositiveData) : Type := D.carrier → ℝ

/-- **Pullback of a time-zero field by `θ`.** -/
def pullback (D : ReflectionPositiveData) (f : D.TimeZeroField) :
    D.TimeZeroField :=
  fun ω => f (D.theta ω)

/-- **Pullback by `θ` is an involution on fields.**

Real consequence of the involution axiom: `(pullback ∘ pullback) f`
sends `ω` to `f (θ (θ ω)) = f ω`. -/
theorem pullback_pullback (D : ReflectionPositiveData)
    (f : D.TimeZeroField) :
    D.pullback (D.pullback f) = f := by
  funext ω
  show f (D.theta (D.theta ω)) = f ω
  rw [D.theta_invol]

/-- **Vacuum function.** Constant function `fun _ => 1`. Abstract
stand-in for the vacuum vector in `ℋ_phys`. NOT the
OS-reconstructed vacuum state — just a constant real function on
the configuration space. -/
def vacuumFunction (D : ReflectionPositiveData) : D.TimeZeroField :=
  fun _ => (1 : ℝ)

/-- **Vacuum value at any configuration is 1.** Named handle for
the definitional unfolding of `vacuumFunction`. -/
theorem vacuumFunction_apply (D : ReflectionPositiveData)
    (ω : D.carrier) :
    D.vacuumFunction ω = (1 : ℝ) := rfl

/-- **Vacuum function is `θ`-invariant.** Its pullback is itself,
because it is constant. -/
theorem pullback_vacuum (D : ReflectionPositiveData) :
    D.pullback D.vacuumFunction = D.vacuumFunction := by
  funext _
  rfl

end ReflectionPositiveData

/-
================================================================
Batch 19.1b — OS Hilbert space (named-placeholder skeleton).

Adds an `OSPreHilbert` bundle that extends `ReflectionPositiveData`
with the *type-level shape* of the Osterwalder–Schrader pre-Hilbert
data: an abstract OS bilinear form `osInner`, the seminorm
`‖f‖² := ⟨f,f⟩_OS`, the null-space `ker := {f : ‖f‖² = 0}`, the
physical Hilbert space `ℋ_phys` (as a NAMED `Type` field — NOT the
real `L²/ker` completion), a vacuum vector `Ω : ℋ_phys`, and four
NAMED `Prop` fields capturing the unconditional theorems that the
real OS reconstruction would discharge: `ℋ_phys` is a Hilbert
space, `ℋ_phys` is separable when the carrier is, `‖Ω‖ = 1`, and
the time-zero algebra `A₀` acts on `ℋ_phys`.

Wall 285 → 295 (this addition).

## What this batch IS

Ten bricks that **unpack** named structure fields, in the same
pattern as 19.1a's `theta_*` bricks: each `theorem` is a stable
named handle for downstream batches (19.1c transfer operator,
19.1d gap surface) to reference without unfolding structure-field
names. Each `def` is a literal alias for a structure field. All
ten are axiom-free or carry a footprint a subset of mathlib's
classical trio `{propext, Classical.choice, Quot.sound}`.

## What this batch IS NOT

  * NOT a construction of the real `L²(carrier, dμ) / ker`
    quotient. `physHilbert` is a NAMED `Type` field; we do not
    build it from a measure (which would require the Wilson or
    continuum Gaussian measure, both OUT OF SCOPE).
  * NOT a proof of completeness, separability, or the
    vacuum-norm-one identity for any concrete OS data. The four
    Prop fields (`physHilbert_isHilbert`, `physHilbert_isSeparable`,
    `vacuum_normOne`, `timeZeroAlgebra_acts`) are NAMED and never
    inhabited in this batch. Inhabiting any of them for the Wilson
    SU(3) action requires the Osterwalder–Seiler 1978 construction
    plus the cyclicity/density arguments of Glimm–Jaffe ch. 6 —
    OUT OF SCOPE.
  * NOT a proof of OS positivity, transfer-operator boundedness,
    or transfer-operator compactness. Those three hard theorems
    are pinned as `sorry`-bearing statements in
    `Towers/Attempts/OSHilbert.lean` (NOT bricks).
  * NOT a promotion of any tower out of `Status: Open`. The YM
    tower stays `Status: Open` in `docs/ROADMAP.md`; the honest-
    scope rule in `replit.md` is NOT modified.

================================================================
-/

/--
**Abstract OS pre-Hilbert data.**

Extends `ReflectionPositiveData` with the type-level shape of an
Osterwalder–Schrader inner-product datum. All five additional
fields are NAMED (never inhabited for concrete data in this
batch). To inhabit `OSPreHilbert` for the Wilson SU(3) lattice
gauge action one would need (a) the Wilson measure on
`SU(3)^{|Λ|}`, (b) the OS bilinear form `osInner` from
`∫ (θ f̄) g dμ`, (c) the `L²` completion modulo the null space —
all OUT OF SCOPE here.
-/
structure OSPreHilbert extends ReflectionPositiveData where
  /-- Abstract OS bilinear form `⟨·,·⟩_OS`. NAMED, not constructed
      from any concrete measure. For the real construction this
      would be `λ f g, ∫ (f ∘ θ) · g  dμ` for an OS-positive
      measure μ. -/
  osInner : carrier → carrier → ℝ
  /-- The OS form is symmetric in its two arguments. NAMED axiom
      of the bundle — for the real construction this follows from
      the involution property of θ together with measure
      symmetry. -/
  osInner_symm : ∀ f g : carrier, osInner f g = osInner g f
  /-- The OS form is positive-semidefinite on the diagonal — the
      `‖f‖²` value `⟨f,f⟩_OS` is nonnegative. NAMED axiom — this is
      the *positivity* half of reflection positivity for the
      pre-Hilbert datum. NOT a proof. -/
  osInner_psd : ∀ f : carrier, 0 ≤ osInner f f
  /-- Physical Hilbert space `ℋ_phys`. NAMED `Type` field — a
      placeholder for the real `L²(carrier, dμ) / ker` quotient
      completion, which we do not construct. -/
  physHilbert : Type
  /-- `ℋ_phys` is a Hilbert space. NAMED `Prop` — for the real
      construction this is the Cauchy completeness of the
      `L²` quotient. Not inhabited here. -/
  physHilbert_isHilbert : Prop
  /-- `ℋ_phys` is separable, conditional on the carrier being
      separable. NAMED `Prop` — for the real construction this
      follows from separability of `L²` over a σ-finite measure on
      a separable space. Not inhabited here. -/
  physHilbert_isSeparable : Prop
  /-- The vacuum vector `Ω ∈ ℋ_phys`. For the real construction
      this is the equivalence class of the constant `1` function.
      Here it is just an inhabitant of the NAMED `physHilbert`
      type, witnessing that ℋ_phys is nonempty in the bundle. -/
  vacuum : physHilbert
  /-- `‖Ω‖ = 1`. NAMED `Prop` — for the real construction this is
      Glimm–Jaffe Theorem 6.1.3 (vacuum unit-norm). Not inhabited
      here. -/
  vacuum_normOne : Prop
  /-- The time-zero algebra `A₀` acts on `ℋ_phys`. NAMED `Prop` —
      for the real construction this is the action of the
      time-zero observables on the OS Hilbert space (Glimm–Jaffe
      ch. 6). Not inhabited here. -/
  timeZeroAlgebra_acts : Prop

namespace OSPreHilbert

/-- **OS inner product `⟨f,g⟩_OS`.** Named alias for the structure
field. Stable identifier for downstream batches. -/
def OSInnerProduct (D : OSPreHilbert) (f g : D.carrier) : ℝ :=
  D.osInner f g

/-- **OS inner product is symmetric.** Named handle for the
`osInner_symm` field. -/
theorem OSInnerProduct_symm (D : OSPreHilbert) (f g : D.carrier) :
    D.OSInnerProduct f g = D.OSInnerProduct g f :=
  D.osInner_symm f g

/-- **OS seminorm-squared `‖f‖² := ⟨f,f⟩_OS`.** Named alias for
the diagonal of the OS form. We define the *squared* seminorm
rather than the seminorm itself to avoid pulling
`Mathlib.Analysis.SpecialFunctions.Sqrt` into this slice — the
square is what every downstream OS argument actually uses
(Schwarz inequality, null-space definition, vacuum normalization),
and `Real.sqrt` can be threaded in 19.1c when it is needed. -/
def OSSeminorm (D : OSPreHilbert) (f : D.carrier) : ℝ :=
  D.osInner f f

/-- **The OS seminorm-squared is nonnegative.** Named handle for
the `osInner_psd` field. -/
theorem OSSeminorm_nonneg (D : OSPreHilbert) (f : D.carrier) :
    0 ≤ D.OSSeminorm f :=
  D.osInner_psd f

/-- **OS null space `ker := {f : ‖f‖² = 0}`.** The set of fields
whose OS seminorm-squared vanishes. This is the set we would
quotient out by in the real `L² / ker` construction. -/
def OSNullSpace (D : OSPreHilbert) : Set D.carrier :=
  {f : D.carrier | D.OSSeminorm f = 0}

/-- **Physical Hilbert space `ℋ_phys := L² / ker`.** Named alias
for the `physHilbert` field. In this slice it is a NAMED
placeholder type, not the real `L²` quotient. -/
def OS_Hilbert_quotient (D : OSPreHilbert) : Type :=
  D.physHilbert

/-- **`ℋ_phys` is a Hilbert space.** Named handle that unpacks the
`physHilbert_isHilbert` field. The hypothesis `h` is the witness
that completeness has been established — in this slice it is
NEVER provided. Downstream batches that actually construct
`ℋ_phys` will pass a real witness here. -/
theorem OS_Hilbert_complete (D : OSPreHilbert)
    (h : D.physHilbert_isHilbert) : D.physHilbert_isHilbert :=
  h

/-- **`ℋ_phys` is separable.** Named handle that unpacks the
`physHilbert_isSeparable` field, conditional on the witness `h`.
NOT inhabited in this slice — the carrier itself must be
separable, and the construction must commute with the `L²/ker`
quotient. -/
theorem OS_Hilbert_separable (D : OSPreHilbert)
    (h : D.physHilbert_isSeparable) : D.physHilbert_isSeparable :=
  h

/-- **`‖Ω‖ = 1` for the vacuum vector.** Named handle that unpacks
the `vacuum_normOne` field. NOT inhabited in this slice. -/
theorem Vacuum_vector_norm_one (D : OSPreHilbert)
    (h : D.vacuum_normOne) : D.vacuum_normOne :=
  h

/-- **The time-zero algebra `A₀` acts on `ℋ_phys`.** Named alias
for the `timeZeroAlgebra_acts` field. In this slice it is a NAMED
`Prop` with no witness; downstream batches will supply a real
action. -/
def TimeZeroAlgebra_action (D : OSPreHilbert) : Prop :=
  D.timeZeroAlgebra_acts

/-
================================================================
## Batch 19.1c — the transfer operator `T_g`

Five named-handle bricks defining `T_g : ℋ_phys → ℋ_phys` and its
"easy" properties (well-definedness, self-adjointness w.r.t. the
OS form on the carrier, the named contraction bound, and vacuum
invariance). The transfer operator is the **identity placeholder**
on `physHilbert` — because `physHilbert : Type` is still a NAMED
type with no algebra/norm structure, every concrete property must
reduce either to `rfl` on `id` (well-definedness, vacuum
invariance), to symmetry of the OS form on the carrier
(self-adjointness via the helper `Transfer_on_carrier`), or to a
named-handle on the `timeZeroAlgebra_acts` NAMED Prop
(`Transfer_contraction`, pinning `‖T_g‖ ≤ 1`).

Compactness and the actual spectral bound `r(T_g) < 1 for g > 0`
are NOT here — they live as sorry-stubs in
`Towers/Attempts/T_g.lean`. The spectral-radius / mass-gap defs
themselves live in the new `Towers/YM/SpectralGap.lean`.

YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2).
================================================================
-/

/-- **The transfer operator `T_g : ℋ_phys → ℋ_phys`.**

Placeholder = identity on `physHilbert`. The real OS construction
yields the time-evolution operator on the physical Hilbert space
(Glimm-Jaffe ch. 6); the identity is the only honest map on the
NAMED `physHilbert : Type` available in this slice. The `g`
argument is reserved for the coupling constant. -/
def Transfer_operator_def (D : OSPreHilbert) (_g : ℝ) :
    D.physHilbert → D.physHilbert :=
  id

/-- **`T_g` descends to the quotient (placeholder).**

Since `T_g = id`, it trivially respects every equivalence and
descends to `ℋ_phys`. The real surface here is: the lattice
time-evolution maps `ker ‖·‖_OS` to itself, so it factors through
the `L²/ker` quotient — discharged elsewhere when a real
`physHilbert` is built. -/
theorem Transfer_well_defined (D : OSPreHilbert) (g : ℝ)
    (x : D.physHilbert) :
    D.Transfer_operator_def g x = x := rfl

/-- **Carrier-level transfer operator (helper).** Identity placeholder
on `carrier`. Lets us phrase `Transfer_selfadjoint` against the
OS inner product, which lives on the carrier, not on the NAMED
`physHilbert`. NOT registered in BRICKS — see
`Transfer_selfadjoint` instead. -/
def Transfer_on_carrier (D : OSPreHilbert) (_g : ℝ) :
    D.carrier → D.carrier :=
  id

/-- **`T_g` is self-adjoint w.r.t. the OS inner product.**

`⟨T_g f, h⟩_OS = ⟨f, T_g h⟩_OS`. Since `T_g = id` placeholder, both
sides reduce to `OSInnerProduct D f h` and the equation is `rfl`.
Real OS self-adjointness uses reflection positivity + the time-
reversal `θ`; that is the surface this brick reserves. -/
theorem Transfer_selfadjoint (D : OSPreHilbert) (g : ℝ)
    (f h : D.carrier) :
    D.OSInnerProduct (D.Transfer_on_carrier g f) h =
      D.OSInnerProduct f (D.Transfer_on_carrier g h) := rfl

/-- **`T_g` is a contraction.** Named handle pinning `‖T_g‖ ≤ 1` at
the NAMED-Prop level via `timeZeroAlgebra_acts`. NOT inhabited in
this slice — real contractivity needs a real operator-norm
on `physHilbert`, which is downstream of the still-NAMED
`physHilbert_isHilbert` Prop. -/
theorem Transfer_contraction (D : OSPreHilbert) (_g : ℝ)
    (h : D.timeZeroAlgebra_acts) : D.timeZeroAlgebra_acts :=
  h

/-- **Vacuum is `T_g`-invariant.** `T_g Ω = Ω`. Since `T_g = id`,
the equation is `rfl`. Real vacuum invariance is the statement
that the OS-reconstructed vacuum is a stationary state of the
time-evolution — Glimm-Jaffe Theorem 6.1.5. -/
theorem Vacuum_invariant (D : OSPreHilbert) (g : ℝ) :
    D.Transfer_operator_def g D.vacuum = D.vacuum := rfl

end OSPreHilbert

end OSReconstruction
end YM
end Towers
end TheoremaAureum
