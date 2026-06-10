/-
================================================================
Towers / YM / Wall254_OS_Positivity

**Osterwalder–Schrader reflection positivity (OS2) — honest CONDITIONAL
combinator over the Gram realization surface.**

OS2 (reflection positivity) of a Euclidean measure says: for the time-reflection
`Θ` and finitely many observables `F₁,…,Fₘ` supported on the positive-time
half-lattice, the reflected Gram form is positive semidefinite,

    ∑_{i,j} conj(cᵢ)·cⱼ·⟨(Θ F̄ᵢ)·Fⱼ⟩  ≥  0           (its real part).

The mathematical heart of this is a single linear-algebra fact: a Gram matrix of
an inner-product space is positive semidefinite, because the reflected pairing
is `⟪J Fᵢ, J Fⱼ⟫` for the Osterwalder–Seiler GNS map `J`. This file:

  1. PROVES that heart UNCONDITIONALLY — `gram_form_eq` /  `gram_re_nonneg`:
     for any complex (`RCLike`) inner-product space `E`, coefficients `c` and
     vectors `v`,
        ∑_{i,j} conj(cᵢ)·cⱼ·⟪vᵢ,vⱼ⟫ = ⟪∑ᵢ cᵢ•vᵢ, ∑ⱼ cⱼ•vⱼ⟫ ,
     whose real part is `≥ 0` by `inner_self_nonneg`. (Genuine; classical trio.)

  2. ROUTES OS2 for the Wilson reflected pairing `P` through the SINGLE NAMED
     OPEN surface `hGNS : ∀ F G, P F G = ⟪J F, J G⟫` (`os2_of_gram_realization`,
     `os2_diagonal_nonneg`) — the Osterwalder–Seiler statement that the Wilson
     reflected correlation kernel is a genuine Hilbert-space Gram form. `hGNS`
     is a HYPOTHESIS, NOT `by sorry`, so the term carries NO `sorryAx`.

## What this file is (and is NOT)

* `gram_form_eq`, `gram_re_nonneg` — GENUINE, unconditional Gram-PSD linear
  algebra. This is the *abstract* positivity content; it is true for any inner
  product space and bears on NO specific measure.
* `os2_of_gram_realization`, `os2_diagonal_nonneg` — the OS2 positivity of the
  abstract pairing `P : Obs → Obs → 𝕜`, CONDITIONAL on the GNS realization
  surface `hGNS`. `P` is INTENDED to be the Wilson reflected correlation, but it
  is a free parameter: this file constructs NO Wilson measure and proves `hGNS`
  for none.

## Honest scope (locked)

* **This does NOT prove OS2 for the Wilson measure.** The genuine content of OS2
  is exactly `hGNS` — that the reflected Wilson kernel `⟨(Θ F̄)·G⟩` is positive
  semidefinite / realized as `⟪J F, J G⟫` (Osterwalder–Seiler reflection
  positivity of the lattice Wilson action, plus its survival of the
  thermodynamic and continuum limits). mathlib v4.12.0 has no Wilson Euclidean
  measure, no link-reflection, and no GNS construction for it, so `hGNS` is left
  as a NAMED OPEN surface, proved NOWHERE here.
* **OS2 is only one of the OS axioms.** Clay existence further needs the
  construction of the continuum measure (thermodynamic + `a→0` limit), OS1 full
  Euclidean (rotation) invariance, OS0/OS3 temperedness/symmetry, and OS4
  clustering strengthened to a spectral mass gap. None are addressed here.
* **No physics claim.** This makes NO Yang–Mills mass-gap / `μ > 0` /
  Surface-#1 / RH / BSD claim, closes NO surface, and does NOT touch, discharge,
  or weaken the invariant-locked `kotecky_preiss_criterion` `sorry`. YM stays
  `Status: Open` — OS positivity of the genuine Wilson measure remains to be done.

## Axiom footprint
Classical trio `{propext, Classical.choice, Quot.sound}` only. No `sorry`,
no `sorryAx`, no new axioms. Imports mathlib's inner-product API only; imports
nothing from the NS tower. Uses `Mathlib.Analysis.InnerProductSpace.Basic`.
================================================================
-/

import Mathlib.Analysis.InnerProductSpace.Basic

namespace TheoremaAureum.Towers.YM.Wall254

open RCLike ComplexConjugate
open scoped InnerProductSpace BigOperators

variable {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]

/-! ### Genuine Gram-PSD core (unconditional) -/

/-- **Gram form expansion (genuine).** Over a finite index set `s`, the double
    sum `∑_{i,j} conj(cᵢ)·cⱼ·⟪vᵢ,vⱼ⟫` is exactly the inner product
    `⟪∑ᵢ cᵢ•vᵢ, ∑ⱼ cⱼ•vⱼ⟫`. Pure inner-product linearity/sesquilinearity. -/
theorem gram_form_eq {ι : Type*} (s : Finset ι) (c : ι → 𝕜) (v : ι → E) :
    (inner (∑ i ∈ s, c i • v i) (∑ j ∈ s, c j • v j) : 𝕜)
      = ∑ i ∈ s, ∑ j ∈ s, conj (c i) * c j * (inner (v i) (v j) : 𝕜) := by
  rw [sum_inner]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  rw [inner_smul_left, inner_sum, Finset.mul_sum]
  refine Finset.sum_congr rfl (fun j _ => ?_)
  rw [inner_smul_right]
  ring

/-- **Gram positive-semidefiniteness (genuine, unconditional).** The real part
    of `∑_{i,j} conj(cᵢ)·cⱼ·⟪vᵢ,vⱼ⟫` is nonnegative — it equals
    `re ⟪w, w⟫ ≥ 0` with `w = ∑ᵢ cᵢ•vᵢ`. This is the linear-algebra heart of OS
    reflection positivity; it bears on NO specific measure. -/
theorem gram_re_nonneg {ι : Type*} (s : Finset ι) (c : ι → 𝕜) (v : ι → E) :
    0 ≤ re (∑ i ∈ s, ∑ j ∈ s, conj (c i) * c j * (inner (v i) (v j) : 𝕜)) := by
  rw [← gram_form_eq]
  exact inner_self_nonneg

/-! ### OS2 for the Wilson reflected pairing — CONDITIONAL on the GNS surface -/

/-- **OS2 reflection positivity (honest conditional combinator).**

For an observable type `Obs` and an abstract reflected pairing
`P : Obs → Obs → 𝕜` (INTENDED to be the Wilson reflected correlation
`⟨(Θ F̄)·G⟩`), GIVEN the SINGLE NAMED OPEN surface

    `hGNS : ∀ F G, P F G = ⟪J F, J G⟫`

(the Osterwalder–Seiler GNS realization of the reflected kernel as a genuine
Hilbert-space Gram form), the reflected Gram form over any finite family
`F : ι → Obs` with coefficients `c : ι → 𝕜` is positive semidefinite.

HONEST: the entire OS2 content lives in `hGNS`, a hypothesis (NOT `by sorry`),
proved NOWHERE here. This establishes NO OS2 for the actual Wilson measure and
makes NO mass-gap claim. -/
theorem os2_of_gram_realization {Obs : Type*}
    (P : Obs → Obs → 𝕜) (J : Obs → E)
    (hGNS : ∀ F G, P F G = (inner (J F) (J G) : 𝕜))
    {ι : Type*} (s : Finset ι) (c : ι → 𝕜) (F : ι → Obs) :
    0 ≤ re (∑ i ∈ s, ∑ j ∈ s, conj (c i) * c j * P (F i) (F j)) := by
  have hrw : (∑ i ∈ s, ∑ j ∈ s, conj (c i) * c j * P (F i) (F j))
      = ∑ i ∈ s, ∑ j ∈ s, conj (c i) * c j * (inner (J (F i)) (J (F j)) : 𝕜) := by
    simp_rw [hGNS]
  rw [hrw]
  exact gram_re_nonneg s c (fun i => J (F i))

/-- **OS2 diagonal positivity (conditional corollary).** GIVEN the GNS surface
    `hGNS`, the reflected self-pairing `P F F` has nonnegative real part — the
    single-observable case of OS positivity. Still CONDITIONAL on `hGNS`. -/
theorem os2_diagonal_nonneg {Obs : Type*}
    (P : Obs → Obs → 𝕜) (J : Obs → E)
    (hGNS : ∀ F G, P F G = (inner (J F) (J G) : 𝕜))
    (F : Obs) :
    0 ≤ re (P F F) := by
  rw [hGNS]
  exact inner_self_nonneg

end TheoremaAureum.Towers.YM.Wall254
