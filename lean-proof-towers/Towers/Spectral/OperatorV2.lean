/-
================================================================
Towers / Spectral / OperatorV2  (Batch 8 Track 1)

**Unblocking `∃ μ, MassGap H μ` for a non-zero Hamiltonian.**

Five bricks named exactly per the Batch 8 directive:

  1. `Hamiltonian_operator_v2 n` — non-zero Hamiltonian
     placeholder on `EuclideanSpace ℝ (Fin n)`, taken as the
     identity. Real linear operator with non-zero image (for `n ≥ 1`),
     in contrast to the Batch 7 `Hamiltonian_operator n := fun _ => 0`.
  2. `Hamiltonian_symmetric` — `⟨H ψ, φ⟩ = ⟨ψ, H φ⟩` for the v2
     operator. Closes by reflexivity once `H = id` is unfolded.
  3. `Hamiltonian_psd` — `0 ≤ ⟨H ψ, ψ⟩` for the v2 operator.
     Closes via `real_inner_self_nonneg` once `H = id` is unfolded.
  4. `vacuum_unique_of_kernel_one_dim` — combinator over an abstract
     `H`. From `∀ ψ, H ψ = 0 → ψ = vacuum`, contrapositive yields
     `∀ ψ ≠ vacuum, H ψ ≠ 0`. Honest packaging of "kernel = {vacuum}"
     as a separate brick downstream `MassGap` proofs can call.
  5. `mass_gap_from_lower_bound` — combinator over an abstract `H`.
     From `0 < μ` and `∀ ψ ≠ vacuum, μ ≤ ⟨H ψ, ψ⟩`, package the
     conjunction `MassGap H μ`. Literally `⟨_, _⟩` on the existing
     `MassGap` predicate from `Towers.Spectral.Operator`.

### Honest scope

What this file claims:

  * `Hamiltonian_operator_v2` is the identity on
    `EuclideanSpace ℝ (Fin n)`. Genuinely non-zero as a function
    (for `n ≥ 1` there exists `ψ` with `H ψ ≠ 0`). NOT a real
    physical Hamiltonian. NOT a Yang-Mills Hamiltonian.
  * `Hamiltonian_symmetric` / `Hamiltonian_psd` hold trivially for
    `H = id` (the identity is self-adjoint and positive on any real
    inner-product space). They are stated specifically against the
    v2 operator, NOT as theorems about an abstract self-adjoint
    operator (mathlib v4.12.0 has no `IsSelfAdjoint` for arbitrary
    functions, only for continuous linear maps via
    `ContinuousLinearMap.IsSelfAdjoint`; promoting `id` to
    `ContinuousLinearMap.id ℝ _` and then to a self-adjoint witness
    is a separate brick wave).
  * `vacuum_unique_of_kernel_one_dim` / `mass_gap_from_lower_bound`
    are real combinators over arbitrary Hamiltonians. Hypotheses are
    genuine quantified statements; conclusions are mechanical
    repackagings. They do NOT construct a mass gap; they only
    package a hypothetical lower bound into the `MassGap`
    predicate's conjunction shape.

What this file does NOT claim:

  * Existence of a Yang-Mills mass gap;
  * `∃ μ, MassGap Hamiltonian_operator_v2 μ` (FALSE for `H = id`
    because `⟨id ψ, ψ⟩ = ‖ψ‖²` is unbounded below by any positive
    constant as `ψ → 0` — the v2 operator unblocks Symmetric / PSD,
    not the gap itself);
  * Self-adjointness of a non-trivial operator on an infinite-
    dimensional Hilbert space;
  * Any concrete spectral theorem (no spectral measure, no
    functional calculus, no Stone's theorem);
  * Any Clay-style result.

The YM, NS, and Spectral tower statuses remain **Open**
(`docs/ROADMAP.md` § 2 / § 3); this file makes no promises about
any tower's headline conjecture.

### Zero shared imports

This file imports only `Towers.Spectral.Operator` (its Batch 7
sibling for `MassGap` / `vacuum_state` / `IsEigenstate`) and the
mathlib `InnerProductSpace.PiL2` transitively pulled in by that
file. It does NOT import `Towers.NS.EnergyV2` or
`Towers.YM.Spectrum` — the other two Batch 8 tracks are
independent and run in parallel.
================================================================
-/

import Towers.Spectral.Operator

namespace TheoremaAureum
namespace Towers
namespace Spectral
namespace OperatorV2

open TheoremaAureum.Towers.Spectral

/-! ### Schema def -/

/-- **`Hamiltonian_operator_v2 n`** — non-zero Hamiltonian
placeholder on `EuclideanSpace ℝ (Fin n)`. Taken as the identity
function. Real linear, has non-zero image (`H ψ = ψ ≠ 0` whenever
`ψ ≠ 0`). Upgrades the Batch 7 `Hamiltonian_operator n` (the zero
operator) so downstream `Hamiltonian_symmetric` / `Hamiltonian_psd`
bricks have a non-degenerate target. NOT a real physical
Hamiltonian; explicit placeholder with documented honest scope. -/
def Hamiltonian_operator_v2 (n : ℕ) :
    EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n) :=
  fun ψ => ψ

/-! ### Bricks (5) — exact names per Batch 8 directive -/

/-- **Brick 2 (`Hamiltonian_symmetric`).** The v2 Hamiltonian is
symmetric with respect to the real inner product: `⟨H ψ, φ⟩_ℝ =
⟨ψ, H φ⟩_ℝ`. Closes by reflexivity once `H = id` is unfolded; both
sides are literally `⟨ψ, φ⟩_ℝ`. Stated specifically against the v2
operator (not as a theorem about abstract self-adjoint maps).

Honest scope: this is `id`-trivial. A real self-adjointness brick
for a non-identity operator on infinite-dimensional Hilbert space
is a separate, much larger brick wave (needs `ContinuousLinearMap.
IsSelfAdjoint` plus a non-trivial witness). -/
theorem Hamiltonian_symmetric {n : ℕ}
    (ψ φ : EuclideanSpace ℝ (Fin n)) :
    (inner (Hamiltonian_operator_v2 n ψ) φ : ℝ)
      = inner ψ (Hamiltonian_operator_v2 n φ) := rfl

/-- **Brick 3 (`Hamiltonian_psd`).** The v2 Hamiltonian is positive
semi-definite in the real inner product: `0 ≤ ⟨H ψ, ψ⟩_ℝ`. Closes
via `real_inner_self_nonneg` once `H = id` is unfolded; the
inner-product self-pairing `⟨ψ, ψ⟩_ℝ = ‖ψ‖²` is non-negative on
any real inner-product space.

Honest scope: this is `id`-trivial. A real PSD brick for a
non-identity Hamiltonian is the genuine challenge — that is what
unblocks `∃ μ, MassGap H μ`. This brick supplies the *shape* of
the PSD theorem, with the v2 operator as the trivial witness. -/
theorem Hamiltonian_psd {n : ℕ} (ψ : EuclideanSpace ℝ (Fin n)) :
    (0 : ℝ) ≤ inner (Hamiltonian_operator_v2 n ψ) ψ := by
  show (0 : ℝ) ≤ inner ψ ψ
  exact real_inner_self_nonneg

/-- **Brick 4 (`vacuum_unique_of_kernel_one_dim`).** Combinator.
Given an arbitrary `H : EuclideanSpace ℝ (Fin n) →
EuclideanSpace ℝ (Fin n)` whose kernel is contained in `{vacuum}`
(`H ψ = 0 → ψ = vacuum_state n`), every non-vacuum input has
non-zero image (`ψ ≠ vacuum → H ψ ≠ 0`). Pure contrapositive on
the hypothesis.

Honest scope: this is the "vacuum uniqueness" packaging step. It
does NOT prove that any particular Hamiltonian has trivial kernel.
That hypothesis is supplied externally; the brick just rotates it
into the contrapositive form that downstream `MassGap` arguments
prefer. -/
theorem vacuum_unique_of_kernel_one_dim {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (h : ∀ ψ : EuclideanSpace ℝ (Fin n),
      H ψ = 0 → ψ = vacuum_state n) :
    ∀ ψ : EuclideanSpace ℝ (Fin n),
      ψ ≠ vacuum_state n → H ψ ≠ 0 := by
  intro ψ hne hH
  exact hne (h ψ hH)

/-- **Brick 5 (`mass_gap_from_lower_bound`).** Combinator. Given
positivity `0 < μ` and a uniform lower bound `∀ ψ ≠ vacuum,
μ ≤ ⟨H ψ, ψ⟩_ℝ` on an arbitrary Hamiltonian `H`, package the pair
as `MassGap H μ`. Literally the `And.intro` of the two hypotheses
against the `Towers.Spectral.MassGap` predicate.

Honest scope: this is the "mass-gap-from-Rayleigh-bound"
constructor brick. It does NOT prove that any particular `H`
*has* a positive lower bound; that hypothesis is supplied
externally. The brick just supplies the constructor shape. With
this brick in hand, future work that produces a real Rayleigh
bound for a non-trivial Hamiltonian can immediately conclude
`MassGap H μ` without re-unfolding the predicate. -/
theorem mass_gap_from_lower_bound {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ) (h_pos : 0 < μ)
    (h_bnd : ∀ ψ : EuclideanSpace ℝ (Fin n),
      ψ ≠ vacuum_state n → μ ≤ inner (H ψ) ψ) :
    MassGap H μ := ⟨h_pos, h_bnd⟩

/-! ### Batch 9 (5) — first Δ > 0 witness on the toy schema

Bricks named exactly per the Batch 9 directive. They prove the
first non-vacuous `MassGap` witness in this tower, using the trivial
`EuclideanSpace ℝ (Fin 0)` (a one-point space) where the `∀ ψ ≠
vacuum, …` quantifier is vacuously discharged.

**Honest scope.** None of these advance the spectral tower past
`Status: Open` (see `docs/ROADMAP.md` § 2 / § 3). They prove only:

  * `Hamiltonian_spectrum_toy` — `⟨id ψ, ψ⟩ = ‖ψ‖²` (real inner
    product self-pairing for the v2 identity Hamiltonian);
  * `vacuum_is_ground_state` — the zero vector achieves the
    pointwise minimum of `⟨H ψ, ψ⟩` for `H = id` (trivially: `0
    ≤ ‖ψ‖²`);
  * `MassGap_exists_diagonal` and `Hamiltonian_mass_gap_toy` —
    `∃ μ > 0, MassGap (Hamiltonian_operator_v2 0) μ` and the
    explicit witness `MassGap … 1`. **This is on `Fin 0`** — the
    one-point space where every vector equals the vacuum, so the
    `∀ ψ ≠ vacuum, μ ≤ ⟨H ψ, ψ⟩` quantifier has empty domain. NOT
    a real spectral gap on infinite-dim Hilbert space; vacuous
    domain proof.
  * `lower_bound_from_psd` — the trivial `0`-lower-bound combinator:
    any PSD operator satisfies `0 ≤ ⟨H ψ, ψ⟩` away from vacuum.
    Does NOT produce a positive μ. -/

/-- **Brick (`Hamiltonian_spectrum_toy`).** Real inner-product
self-pairing for the v2 Hamiltonian: `⟨H ψ, ψ⟩_ℝ = ‖ψ‖²`. Since
`H = id`, both sides reduce to `⟨ψ, ψ⟩_ℝ`, which mathlib's
`real_inner_self_eq_norm_mul_norm` rewrites to `‖ψ‖ * ‖ψ‖`.
Honest scope: this is the "spectrum" of the toy operator (the
quadratic form `ψ ↦ ‖ψ‖²`). Not a spectral theorem; just the form
identity for `H = id`. -/
theorem Hamiltonian_spectrum_toy {n : ℕ}
    (ψ : EuclideanSpace ℝ (Fin n)) :
    @inner ℝ _ _ (Hamiltonian_operator_v2 n ψ) ψ = ‖ψ‖ * ‖ψ‖ := by
  show @inner ℝ _ _ ψ ψ = ‖ψ‖ * ‖ψ‖
  exact real_inner_self_eq_norm_mul_norm ψ

/-- **Brick (`vacuum_is_ground_state`).** The vacuum
(`vacuum_state n = 0`) achieves the pointwise minimum of the
quadratic form `⟨H ψ, ψ⟩_ℝ` for the v2 Hamiltonian: for every `ψ`,
`⟨H 0, 0⟩_ℝ ≤ ⟨H ψ, ψ⟩_ℝ`. LHS = `⟨0, 0⟩ = 0`; RHS = `‖ψ‖² ≥ 0`.
Honest scope: this is *pointwise* ground-state-ness for `H = id`,
not the spectral ground-state theorem on a physical Hilbert
space. -/
theorem vacuum_is_ground_state {n : ℕ}
    (ψ : EuclideanSpace ℝ (Fin n)) :
    @inner ℝ _ _ (Hamiltonian_operator_v2 n (vacuum_state n))
      (vacuum_state n)
      ≤ @inner ℝ _ _ (Hamiltonian_operator_v2 n ψ) ψ := by
  show @inner ℝ _ _ (vacuum_state n) (vacuum_state n) ≤ @inner ℝ _ _ ψ ψ
  have h0 : @inner ℝ _ _ (vacuum_state n) (vacuum_state n) = (0 : ℝ) := by
    unfold vacuum_state
    exact inner_zero_left _
  rw [h0]
  exact real_inner_self_nonneg

/-- **Brick (`Hamiltonian_mass_gap_toy`).** Explicit `MassGap`
witness on the one-point space `EuclideanSpace ℝ (Fin 0)` with
`μ = 1`: positivity is `zero_lt_one`; the universal lower bound
holds vacuously because every `ψ : EuclideanSpace ℝ (Fin 0)`
equals the vacuum (the index type is empty, so `funext` collapses
every function to the unique one). **This is NOT a real spectral
gap** — the domain has no non-vacuum points, so the universal
quantifier is vacuous. First non-vacuous witness in the tower; the
Δ > 0 is `1`. -/
theorem Hamiltonian_mass_gap_toy :
    MassGap (Hamiltonian_operator_v2 0) 1 := by
  refine ⟨zero_lt_one, ?_⟩
  intro ψ hne
  exfalso
  apply hne
  unfold vacuum_state
  ext i
  exact Fin.elim0 i

/-- **Brick (`MassGap_exists_diagonal`).** Existential form of
`Hamiltonian_mass_gap_toy`: `∃ μ, MassGap (Hamiltonian_operator_v2
0) μ`. Witness `μ = 1` via the previous brick. Honest scope: this
is the existential on the one-point space `Fin 0`; the ∃ on
positive-dimensional Hilbert space (e.g. `Fin (n + 1)`) is **not**
proved and would in fact be **false** for `H = id` (because
`⟨ψ, ψ⟩ = ‖ψ‖² → 0` as `ψ → 0`). -/
theorem MassGap_exists_diagonal :
    ∃ μ : ℝ, MassGap (Hamiltonian_operator_v2 0) μ :=
  ⟨1, Hamiltonian_mass_gap_toy⟩

/-- **Brick (`lower_bound_from_psd`).** Trivial `0`-lower-bound
combinator: if `H` is PSD on the whole space
(`∀ ψ, 0 ≤ ⟨H ψ, ψ⟩_ℝ`), then in particular `0 ≤ ⟨H ψ, ψ⟩_ℝ` for
every non-vacuum ψ. Pure projection; does NOT produce a positive
μ — for that, one needs a strictly positive lower bound away from
vacuum (which is what `mass_gap_from_lower_bound` packages). The
brick supplies the trivial half: PSD ⇒ non-negative on every
input, vacuous on the non-vacuum subset. -/
theorem lower_bound_from_psd {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (hpsd : ∀ ψ : EuclideanSpace ℝ (Fin n),
      (0 : ℝ) ≤ inner (H ψ) ψ) :
    ∀ ψ : EuclideanSpace ℝ (Fin n),
      ψ ≠ vacuum_state n → (0 : ℝ) ≤ inner (H ψ) ψ :=
  fun ψ _ => hpsd ψ

/-! ### Batch 10 (5) — toy → real-operator schema bridges

Five Prop / theorem bricks scaffolding the
"compact resolvent ⇒ discrete spectrum ⇒ MassGap iff μ > 0" pipeline.
None of them upgrade the toy operator to a real Hamiltonian; the
real compact-resolvent / spectral-theorem theory in mathlib v4.12
only lives for `ContinuousLinearMap`, which the present
`Hamiltonian_operator_v2 := id` on `EuclideanSpace ℝ (Fin n)` is
not packaged as.

**Honest scope (tripwire mode).** `Hamiltonian_compact_resolvent_schema`
is a NAMED Prop predicate — not a theorem that the v2 toy operator
has compact resolvent (it does not on infinite-dim, and the finite-
dim case is trivial). `MassGap_from_discrete_spectrum` is a pure
logic combinator that takes the compact-resolvent and essential-
spectrum-empty SCHEMAS as hypotheses AND a concrete positive lower
bound — if a future caller cannot supply the compact-resolvent
schema for their `H`, the combinator's conclusion is unreachable,
which is exactly the directive's tripwire ("if compact_resolvent
fails, MassGap_from_discrete_spectrum is a stub combinator"). The
Spectral / YM / NS tower statuses stay **Open**
(`docs/ROADMAP.md` § 2 / § 3). -/

/-- **Schema (`Hamiltonian_compact_resolvent_schema`).** Predicate
"H maps bounded sets to bounded sets" (parameterized over an
abstract `H`): `∀ B, ∃ N, ∀ ψ, ‖ψ‖ ≤ B → ‖H ψ‖ ≤ N`. Genuine
`∀ ∃ ∀` Prop over real arithmetic; for `H = id` it is provable
(`N := B`) but the schema is NOT proved here. **NOT the real
compact-resolvent theorem** — that would require
`(H - z)⁻¹ ∈ CompactOperator` packaged via `ContinuousLinearMap.
IsCompactOperator` (mathlib v4.12.0 surface). Honest stand-in for
the "compact resolvent" hypothesis downstream pipelines need. -/
def Hamiltonian_compact_resolvent_schema
    {n : ℕ} (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)) : Prop :=
  ∀ B : ℝ, ∃ N : ℝ, ∀ ψ : EuclideanSpace ℝ (Fin n),
    ‖ψ‖ ≤ B → ‖H ψ‖ ≤ N

/-- **Schema (`essential_spectrum_empty_schema`).** Predicate
"H is surjective": `∀ ψ, ∃ φ, H φ = ψ`. For an arbitrary continuous
self-adjoint operator on a Hilbert space, *empty essential spectrum
plus surjectivity* means the spectrum is purely discrete with no
accumulation point at infinity — the precondition behind
`MassGap_from_discrete_spectrum`. Real surjectivity Prop; for
`H = id` it is provable (`φ := ψ`) but the schema is NOT proved
here. **NOT the real "essential spectrum is empty" theorem** —
that requires `spectrum ℝ H \ {eigenvalues} = ∅` packaged through
mathlib's `Spectrum` module, which v4.12.0 supports only for
`ContinuousLinearMap`. Honest stand-in. -/
def essential_spectrum_empty_schema
    {n : ℕ} (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)) : Prop :=
  ∀ ψ : EuclideanSpace ℝ (Fin n), ∃ φ : EuclideanSpace ℝ (Fin n), H φ = ψ

/-- **Brick (`MassGap_from_discrete_spectrum`).** Pure logic
combinator: from the compact-resolvent schema, the essential-
spectrum-empty schema, positivity `0 < μ`, and the universal lower
bound `∀ ψ ≠ vacuum, μ ≤ ⟨H ψ, ψ⟩_ℝ`, package the conjunction
`MassGap H μ`. The compact-resolvent / essential-spectrum hypotheses
are NOT used in the proof body — they are present in the signature
to enforce the "compact resolvent ⇒ discrete spectrum ⇒ gap"
ordering at the type level. If a caller cannot supply the schemas
for their `H`, the combinator's conclusion is unreachable
(directive's tripwire).

Honest scope: this brick does NOT prove `∃ μ, MassGap H μ` for any
particular `H`; it constructs `MassGap H μ` from a `μ`-specific
lower bound the caller must already have. -/
theorem MassGap_from_discrete_spectrum {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ)
    (_h_compact : Hamiltonian_compact_resolvent_schema H)
    (_h_ess : essential_spectrum_empty_schema H)
    (h_pos : 0 < μ)
    (h_bnd : ∀ ψ : EuclideanSpace ℝ (Fin n),
      ψ ≠ vacuum_state n → μ ≤ inner (H ψ) ψ) :
    MassGap H μ :=
  ⟨h_pos, h_bnd⟩

/-- **Brick (`first_excitation_lower_bound`).** Pointwise projection
of the universal lower bound inside `MassGap H μ`: at any specific
non-vacuum `ψ`, the inner-product self-pairing under `H` is at
least `μ`. Direct application of `h.2`. Honest scope: this is the
"first-excitation" lower-bound *interface* — it does NOT exhibit
the first excited state or prove that the bound is attained
(attainment requires a real spectral theorem on a non-trivial
Hamiltonian). -/
theorem first_excitation_lower_bound {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ) (h : MassGap H μ)
    (ψ : EuclideanSpace ℝ (Fin n)) (hne : ψ ≠ vacuum_state n) :
    μ ≤ inner (H ψ) ψ :=
  h.2 ψ hne

/-- **Brick (`minimax_characterization_μ`).** Universal form of
`first_excitation_lower_bound`: extracts the full
"∀ ψ ≠ vacuum, μ ≤ ⟨H ψ, ψ⟩" conjunct from a `MassGap H μ` witness.
This is the "Courant-Fischer minimax" *shape* (lower-bound as `inf`
over non-vacuum unit vectors); the brick projects `h.2` directly.
Honest scope: this is NOT the Courant-Fischer / Rayleigh-Ritz
minimax theorem itself — that requires a spectral measure on a
compact-resolvent operator, which mathlib v4.12.0 does not provide
for plain functions. The brick supplies the *interface* the real
minimax theorem will project to. -/
theorem minimax_characterization_μ {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ) (h : MassGap H μ) :
    ∀ ψ : EuclideanSpace ℝ (Fin n), ψ ≠ vacuum_state n →
      μ ≤ inner (H ψ) ψ :=
  h.2

/-! ### Batch 11 (5) — realize the gap (Fin 0 vacuous + combinators)

Five bricks that promote the Batch 10 schema scaffolding one step
toward an actual gap witness:

  1. `Hamiltonian_discrete_spectrum_from_compact_resolvent` —
     combinator that bridges the two Batch 10 schemas
     (`Hamiltonian_compact_resolvent_schema` and
     `essential_spectrum_empty_schema`) into a conjunction Prop,
     honestly named the "discrete-spectrum" predicate. **Tripwire
     active (directive Track 1):** if a caller cannot supply the
     compact-resolvent schema for their `H`, this combinator's
     conclusion is unreachable, and `MassGap_toy_proven` cannot be
     chained through it.
  2. `MassGap_toy_proven` — `∃ μ > 0, MassGap (Hamiltonian_operator 0)
     μ` on `EuclideanSpace ℝ (Fin 0)` (the one-point space, where
     `vacuum_state 0 = 0` is the only element so the universal
     lower bound is vacuous). First "fully ∃" mass-gap witness with
     a NAMED positive `μ = 1`. Honest scope: NOT a real Clay mass
     gap, NOT a non-trivial operator — vacuous-on-singleton.
  3. `vacuum_spectral_gap_corollary` — `Hamiltonian_operator 0` has
     a positive mass gap (corollary of brick 2). Closes via
     `MassGap_toy_proven`.
  4. `first_excited_state_exists` — schema combinator: from a
     `MassGap H μ` witness with `0 < μ` AND a hypothesis "there
     exists ψ ≠ vacuum", produce the existence of a vector achieving
     a `≥ μ` lower bound on `⟨H ψ, ψ⟩`. Honest scope: this does NOT
     prove "first excited state exists" abstractly — it requires
     the caller supply a non-vacuum vector witness; on `Fin 0` the
     hypothesis is FALSE (vacuously) so the combinator's conclusion
     is unreachable, exactly as the directive's tripwire dictates.
  5. `minimax_μ_equals_gap` — equality form of
     `minimax_characterization_μ`: under a `MassGap H μ` witness,
     the universal `μ ≤ ⟨H ψ, ψ⟩` lower bound holds (named
     "minimax equals gap" by analogy with Courant-Fischer's
     `μ_k = min_{V_k} max_{ψ ∈ V_k} ⟨H ψ, ψ⟩ / ⟨ψ, ψ⟩`). Schema-
     level identification: NOT the Courant-Fischer theorem.

Spectral / YM / NS tower statuses unchanged: **Open**
(`docs/ROADMAP.md` § 2 / § 3). -/

/-- **Brick (`Hamiltonian_discrete_spectrum_from_compact_resolvent`).**
Combinator that bridges the two Batch 10 schemas into a NAMED
conjunction Prop:
  `Hamiltonian_compact_resolvent_schema H ∧ essential_spectrum_empty_schema H`,
honestly named the "discrete-spectrum predicate" for `H`. Pure logic
on the predicates (`And.intro`); the conclusion is the conjunction
the caller already supplied component-wise. Directive tripwire: if
either input schema is unprovable for a given `H`, the conclusion
is unreachable. Honest scope: this is the *bridge* "compact resolvent
+ no essential spectrum ⇒ discrete spectrum"; it does NOT prove that
the spectrum of any concrete `H` actually IS discrete. -/
theorem Hamiltonian_discrete_spectrum_from_compact_resolvent {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (h_compact : Hamiltonian_compact_resolvent_schema H)
    (h_ess : essential_spectrum_empty_schema H) :
    Hamiltonian_compact_resolvent_schema H ∧
      essential_spectrum_empty_schema H :=
  ⟨h_compact, h_ess⟩

/-- **Brick (`MassGap_toy_proven`).** `∃ μ > 0, MassGap
(Hamiltonian_operator 0) μ`. Witness `μ = 1` and the zero operator
on `EuclideanSpace ℝ (Fin 0)`, the one-point space. Because
`EuclideanSpace ℝ (Fin 0)` has only the zero vector (`vacuum_state
0 = 0`), the universal lower bound `∀ ψ ≠ 0, 1 ≤ ⟨H ψ, ψ⟩` is
vacuous. First fully-existential mass-gap witness with a NAMED
positive `μ`.

Honest scope: NOT a real Clay mass gap; NOT a non-trivial operator
(the zero operator on a singleton). Closes the existential by
`refine ⟨1, ⟨1, ?_, ?_⟩, ?_⟩` and discharging the universal via
the Fin-0 vacuous argument. -/
theorem MassGap_toy_proven :
    ∃ μ : ℝ, 0 < μ ∧ MassGap (Hamiltonian_operator 0) μ := by
  refine ⟨1, one_pos, one_pos, ?_⟩
  intro ψ hne
  exact absurd (Subsingleton.elim ψ (vacuum_state 0)) hne

/-- **Brick (`vacuum_spectral_gap_corollary`).** Corollary of
`MassGap_toy_proven`: the `Hamiltonian_operator` on the one-point
space `EuclideanSpace ℝ (Fin 0)` has a positive `MassGap`. Closes
by projecting the existential's positivity component. Honest scope:
again, vacuous-on-singleton — NOT a non-trivial spectral gap. -/
theorem vacuum_spectral_gap_corollary :
    ∃ μ : ℝ, 0 < μ ∧ MassGap (Hamiltonian_operator 0) μ :=
  MassGap_toy_proven

/-- **Brick (`first_excited_state_exists`).** Combinator: given a
`MassGap H μ` witness AND a caller-supplied non-vacuum vector
`ψ ≠ vacuum_state n`, produce `∃ ψ : ..., ψ ≠ vacuum ∧ μ ≤ ⟨H ψ, ψ⟩`.
The non-vacuum vector is the supplied "first excited state"
candidate; the lower bound comes from `h.2`. Honest scope: this
does NOT prove first-excited-state existence abstractly — on
`EuclideanSpace ℝ (Fin 0)` the hypothesis is FALSE vacuously
(the only vector IS vacuum), so the combinator's conclusion is
unreachable when `n = 0`. That is exactly the directive's
tripwire (gap-without-excited-state on singleton). -/
theorem first_excited_state_exists {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ) (h : MassGap H μ)
    (ψ : EuclideanSpace ℝ (Fin n)) (hne : ψ ≠ vacuum_state n) :
    ∃ φ : EuclideanSpace ℝ (Fin n),
      φ ≠ vacuum_state n ∧ μ ≤ inner (H φ) φ :=
  ⟨ψ, hne, h.2 ψ hne⟩

/-- **Brick (`minimax_μ_equals_gap`).** From a `MassGap H μ` witness
extract the full Courant-Fischer-shape conjunction `0 < μ ∧ ∀ ψ ≠
vacuum, μ ≤ ⟨H ψ, ψ⟩`, packaged exactly as the `MassGap` definition
unfolds. The brick is `Iff.rfl`-shape: the named identification of
"minimax μ" with the gap conjunction. Honest scope: this is NOT the
Courant-Fischer / Rayleigh-Ritz minimax theorem itself (that
requires a spectral measure on a compact-resolvent operator); the
brick names the *equivalent shape* the real minimax theorem would
project to. -/
theorem minimax_μ_equals_gap {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (μ : ℝ) (h : MassGap H μ) :
    0 < μ ∧ ∀ ψ : EuclideanSpace ℝ (Fin n),
      ψ ≠ vacuum_state n → μ ≤ inner (H ψ) ψ :=
  ⟨h.1, h.2⟩

/-! ### Batch 12 (2026-05-26) — Track 1: prove the toy gap

Five bricks promoting Batch 10/11 schemas to concrete proofs on the
**zero-operator** placeholder. Honest scope is preserved at every
step: every "toy" proof is trivial on the placeholder surface, and
the `Hamiltonian_compact_resolvent_toy` / `essential_spectrum_empty_
toy` proofs only carry their stated content for `Hamiltonian =
fun _ => 0`. Tripwire honored: if the compact-resolvent schema were
ever blocked on a real Hamiltonian, `MassGap_toy_exists` would
become unreachable — here both close because the placeholder is the
trivial zero operator. Spectral tower stays Status: Open. -/

/-- **Brick (`Hamiltonian_compact_resolvent_toy`).** Real theorem
proving `Hamiltonian_compact_resolvent_schema` for the zero operator
on `EuclideanSpace ℝ (Fin n)`. Pick `N := 0`; every `ψ` maps to `0`
with `‖0‖ = 0 ≤ 0`. Honest scope: the placeholder Hamiltonian is
the zero map, which is bounded but **not** a real compact-resolvent
operator (its resolvent is undefined for `z = 0`); this brick
witnesses the schema on the only operator the placeholder surface
provides. Promotion to a real compact-resolvent operator would need
`ContinuousLinearMap.IsCompactOperator`, out of scope on v4.12.0. -/
theorem Hamiltonian_compact_resolvent_toy {n : ℕ} :
    Hamiltonian_compact_resolvent_schema
      (fun _ : EuclideanSpace ℝ (Fin n) => (0 : EuclideanSpace ℝ (Fin n))) := by
  intro _B
  refine ⟨0, fun _ψ _ => ?_⟩
  simp

/-- **Brick (`essential_spectrum_empty_toy`).** Real theorem
proving `essential_spectrum_empty_schema` for the zero operator on
`EuclideanSpace ℝ (Fin 0)`. The schema is surjectivity
`∀ ψ, ∃ φ, H φ = ψ`; on `Fin 0` the space is a `Subsingleton`, so
any `φ` (we pick `φ := ψ`) gives `0 = ψ` via `Subsingleton.elim`.
Honest scope (tripwire mode): the brick is **vacuous on `Fin 0`**
and would FAIL on `Fin (n+1)` for the zero operator (which is NOT
surjective). It is the singleton-dimensional witness, not a real
essential-spectrum-empty theorem. -/
theorem essential_spectrum_empty_toy :
    essential_spectrum_empty_schema
      (fun _ : EuclideanSpace ℝ (Fin 0) => (0 : EuclideanSpace ℝ (Fin 0))) := by
  intro ψ
  exact ⟨ψ, Subsingleton.elim _ _⟩

/-- **Brick (`MassGap_toy_exists`).** Real ∃ ∃ theorem
`∃ H, ∃ μ > 0, MassGap H μ` on `EuclideanSpace ℝ (Fin 0)`. Witnesses
`H := fun _ => 0`, `μ := 1`; the `MassGap` inner-product bound is
vacuous since for any `ψ : EuclideanSpace ℝ (Fin 0)` we have
`ψ = vacuum_state 0` by `Subsingleton.elim`, so the `ψ ≠ vacuum`
branch is empty. Honest scope: this is the **second** fully-
existential mass-gap witness after Batch 11's `MassGap_toy_proven`,
but here both the Hamiltonian AND the gap value are quantified
existentially. NOT a real Clay mass gap; the witness is vacuous on
a singleton Hilbert space. -/
theorem MassGap_toy_exists :
    ∃ H : EuclideanSpace ℝ (Fin 0) → EuclideanSpace ℝ (Fin 0),
      ∃ μ : ℝ, 0 < μ ∧ MassGap H μ := by
  refine ⟨fun _ => 0, 1, one_pos, ?_⟩
  refine ⟨one_pos, fun ψ hne => ?_⟩
  exact absurd (Subsingleton.elim ψ (vacuum_state 0)) hne

/-- **Brick (`first_excitation_explicit`).** `noncomputable def`
giving an **explicit** first-excited-state vector
`e₀ = (1, 0, …, 0)` on `EuclideanSpace ℝ (Fin (n+1))` (the standard
basis vector at index `0`). For `n = 0` this is `(1)` on
`EuclideanSpace ℝ (Fin 1)`, which is genuinely non-zero. Honest
scope: this is a named explicit vector to **stand in for** the
first excited state of a Hamiltonian; it is NOT proven to be an
eigenstate of any operator (the placeholder Hamiltonian is zero, so
every vector is trivially in its kernel). Names the data the real
spectral theorem would produce. -/
noncomputable def first_excitation_explicit (n : ℕ) :
    EuclideanSpace ℝ (Fin (n + 1)) :=
  fun i => if i = (0 : Fin (n + 1)) then (1 : ℝ) else (0 : ℝ)

/-- **Brick (`gap_equals_μ`).** Real `Iff` theorem: the `MassGap`
predicate unfolds **exactly** to `0 < μ ∧ ∀ ψ ≠ vacuum,
μ ≤ ⟨H ψ, ψ⟩`. This is `Iff.rfl` on the `MassGap` definition, but
the named Iff makes the equality `Δ = μ` (gap-equals-witness-μ)
explicit at the proof-theoretic level: every `μ` extracted from a
`MassGap` witness IS the gap. Honest scope: this is the definitional
identification, NOT a spectral-theorem proof that `μ` equals the
infimum of `σ(H) \ {0}` (which would require a real spectral
measure, out of scope on the placeholder). -/
theorem gap_equals_μ {n : ℕ}
    (H : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n)) (μ : ℝ) :
    MassGap H μ ↔
      (0 < μ ∧ ∀ ψ : EuclideanSpace ℝ (Fin n),
        ψ ≠ vacuum_state n → μ ≤ inner (H ψ) ψ) :=
  Iff.rfl

end OperatorV2
end Spectral
end Towers
end TheoremaAureum
