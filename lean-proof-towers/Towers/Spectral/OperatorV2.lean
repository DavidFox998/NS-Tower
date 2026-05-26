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

end OperatorV2
end Spectral
end Towers
end TheoremaAureum
