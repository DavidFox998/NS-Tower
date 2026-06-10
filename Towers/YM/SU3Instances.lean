import Mathlib

/-!
# Real instance stack for `SU(3) = specialUnitaryGroup (Fin 3) ℂ`

This file equips the special unitary group `SU(3)` (as the mathlib
`Matrix.specialUnitaryGroup (Fin 3) ℂ`, a `Submonoid (Matrix (Fin 3) (Fin 3) ℂ)`)
with the instance stack that `MeasureTheory.Measure.haarMeasure` requires:

* `Group` — inverse is the conjugate transpose (`star`); membership closed under `star`.
* `TopologicalGroup` — multiplication and inversion (`= star`) are continuous in the
  ambient (product) matrix topology.
* `CompactSpace` — `SU(3)` is a closed subset of the compact poly-disc
  `{A | ∀ i j, ‖A i j‖ ≤ 1}` (entries of a unitary matrix are bounded by `1`).
* `MeasurableSpace` / `BorelSpace` — the Borel σ-algebra.

With these, `haarMeasure ⊤` elaborates. The point is the **axiom footprint**:
every declaration here is `sorry`-free and depends only on the classical trio
`{propext, Classical.choice, Quot.sound}` (see the `#print axioms` checks at the end).

INVARIANT NOTE: this is genuine measure-theoretic infrastructure. It constructs the
Haar measure on the compact group `SU(3)`; it makes **no** Yang–Mills mass-gap claim,
no `μ > 0` spectral claim, and does **not** touch Surface #1 (which stays OPEN). It is
a `lakefile.lean` root (clean, elaborates green) but NOT in the
`scripts/check-towers.sh` BRICKS array, so the headline wall is unchanged.
-/

open Matrix MeasureTheory TopologicalSpace

namespace TheoremaAureum.Towers.YM.SU3Instances

/-- `SU(3)` as the mathlib special unitary group of `3×3` complex matrices. -/
abbrev SU3 : Submonoid (Matrix (Fin 3) (Fin 3) ℂ) := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-- The conjugate transpose of an `SU(3)` matrix is again in `SU(3)`:
it stays unitary (`unitary.star_mem`) and its determinant is `star 1 = 1`. -/
theorem star_mem_SU3 {A : Matrix (Fin 3) (Fin 3) ℂ} (hA : A ∈ SU3) : star A ∈ SU3 := by
  rw [Matrix.mem_specialUnitaryGroup_iff] at hA ⊢
  obtain ⟨hu, hd⟩ := hA
  refine ⟨unitary.star_mem hu, ?_⟩
  rw [Matrix.star_eq_conjTranspose, Matrix.det_conjTranspose, hd, star_one]

/-- `Group` structure on `SU(3)`, built on top of the inherited `Submonoid` monoid,
with inverse given by `star` (the conjugate transpose). -/
noncomputable instance instGroupSU3 : Group SU3 :=
  { (inferInstance : Monoid SU3) with
    inv := fun A => ⟨star (A : Matrix (Fin 3) (Fin 3) ℂ), star_mem_SU3 A.2⟩
    inv_mul_cancel := fun A => by
      apply Subtype.ext
      have hu : (A : Matrix (Fin 3) (Fin 3) ℂ) ∈ unitaryGroup (Fin 3) ℂ :=
        (Matrix.mem_specialUnitaryGroup_iff.mp A.2).1
      show star (A : Matrix (Fin 3) (Fin 3) ℂ) * (A : Matrix (Fin 3) (Fin 3) ℂ) = 1
      exact (unitary.mem_iff.mp hu).1 }

/-- `SU(3)` is a topological group: multiplication and inversion (`= star`) are
continuous in the ambient product topology, restricted to the subtype. -/
noncomputable instance instTopologicalGroupSU3 : TopologicalGroup SU3 where
  continuous_mul := by
    apply Continuous.subtype_mk
    exact (continuous_subtype_val.comp continuous_fst).mul
      (continuous_subtype_val.comp continuous_snd)
  continuous_inv := by
    apply Continuous.subtype_mk
    exact continuous_star.comp continuous_subtype_val

/-- Entries of a unitary matrix are bounded by `1`: from `star A * A = 1`, the
`(j,j)` entry says `∑ k, ‖A k j‖² = 1`, so each `‖A i j‖² ≤ 1`. -/
theorem norm_entry_le_one {A : Matrix (Fin 3) (Fin 3) ℂ}
    (hA : A ∈ unitaryGroup (Fin 3) ℂ) (i j : Fin 3) : ‖A i j‖ ≤ 1 := by
  have hstar : star A * A = 1 := (unitary.mem_iff.mp hA).1
  have hsum : ∑ k, Complex.normSq (A k j) = 1 := by
    have h1 : (star A * A) j j = 1 := by rw [hstar]; exact Matrix.one_apply_eq j
    rw [Matrix.mul_apply] at h1
    have key : ∀ k, (star A) j k * A k j = ((Complex.normSq (A k j) : ℝ) : ℂ) := by
      intro k
      rw [Matrix.star_apply]
      exact Complex.normSq_eq_conj_mul_self.symm
    have h1' : ∑ k, ((Complex.normSq (A k j) : ℝ) : ℂ) = 1 := by
      rw [← h1]; exact Finset.sum_congr rfl (fun k _ => (key k).symm)
    rw [← Complex.ofReal_sum] at h1'
    exact_mod_cast h1'
  have hle : Complex.normSq (A i j) ≤ 1 := by
    rw [← hsum]
    exact Finset.single_le_sum (f := fun k => Complex.normSq (A k j))
      (fun k _ => Complex.normSq_nonneg _) (Finset.mem_univ i)
  have hns : Complex.normSq (A i j) = ‖A i j‖ ^ 2 := by
    rw [Complex.normSq_eq_abs, Complex.norm_eq_abs]
  rw [hns] at hle
  nlinarith [norm_nonneg (A i j)]

/-- `SU(3)` is a closed subset of the matrix space: it is the intersection of the
unitary condition `A * star A = 1` and the determinant condition `det A = 1`, both
closed (preimages of `{1}` under continuous maps). -/
theorem isClosed_SU3 : IsClosed (SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ)) := by
  have hset : (SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
      = {A | A * star A = 1} ∩ {A | A.det = 1} := by
    ext A
    simp only [SetLike.mem_coe, Set.mem_inter_iff, Set.mem_setOf_eq]
    rw [Matrix.mem_specialUnitaryGroup_iff, Matrix.mem_unitaryGroup_iff]
  rw [hset]
  refine IsClosed.inter ?_ ?_
  · exact isClosed_eq (continuous_id.mul continuous_star) continuous_const
  · exact isClosed_eq (Continuous.matrix_det continuous_id) continuous_const

/-- `SU(3)` is compact: it is a closed subset of the compact poly-disc
`∏ᵢⱼ closedBall 0 1` (finite product of compact closed balls in `ℂ`). -/
theorem isCompact_SU3 : IsCompact (SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ)) := by
  have hbox : IsCompact
      (Set.univ.pi (fun _ : Fin 3 => Set.univ.pi
        (fun _ : Fin 3 => Metric.closedBall (0 : ℂ) 1)) : Set (Matrix (Fin 3) (Fin 3) ℂ)) :=
    isCompact_univ_pi (fun _ => isCompact_univ_pi (fun _ => isCompact_closedBall _ _))
  refine hbox.of_isClosed_subset isClosed_SU3 ?_
  intro A hA
  simp only [Set.mem_univ_pi, Metric.mem_closedBall, dist_zero_right]
  intro i j
  exact norm_entry_le_one (Matrix.mem_specialUnitaryGroup_iff.mp hA).1 i j

/-- `SU(3)` is a compact space. -/
noncomputable instance instCompactSpaceSU3 : CompactSpace SU3 :=
  isCompact_iff_compactSpace.mp isCompact_SU3

/-- Borel σ-algebra on `SU(3)`. -/
instance instMeasurableSpaceSU3 : MeasurableSpace SU3 := borel _

instance instBorelSpaceSU3 : BorelSpace SU3 := ⟨rfl⟩

instance instNonemptySU3 : Nonempty SU3 := ⟨1⟩

/-- The (normalized, by mathlib's convention) **Haar measure** on the compact group
`SU(3)`, witnessed by the whole space `⊤ : PositiveCompacts`. This is the payload: it
elaborates only because the full instance stack above is present. -/
noncomputable def haarSU3 : MeasureTheory.Measure SU3 :=
  MeasureTheory.Measure.haarMeasure ⊤

-- Axiom audit. Axioms are transitive, so `haarSU3` being the classical trio
-- certifies the whole instance stack it depends on is `sorry`/`sorryAx`-free.
-- Verified live (`lake env lean` + `#print axioms`): `haarSU3` depends on axioms
-- `[propext, Classical.choice, Quot.sound]`.
#print axioms haarSU3

/-- `haarSU3` is a **probability measure**: `haarMeasure ⊤` assigns the whole
(compact) group `SU(3)` total mass `1` (`haarMeasure_self`, since the carrier of
`⊤ : PositiveCompacts` is `univ`). -/
instance instIsProbabilityMeasureHaarSU3 : IsProbabilityMeasure haarSU3 where
  measure_univ := by
    rw [haarSU3, ← TopologicalSpace.PositiveCompacts.coe_top (α := SU3)]
    exact MeasureTheory.Measure.haarMeasure_self

/-- The (normalized) **product Haar measure** on the lattice gauge configuration
space `Fin n → SU(3)`: the independent product of the `SU(3)` Haar measure over
all `n` links. This is the measure with respect to which gauge configurations are
averaged — the `haarN` of the lattice programme, here built honestly from the
real `SU(3)` Haar measure rather than any Dirac stand-in.

INVARIANT NOTE: this is genuine measure-theoretic infrastructure. `haarN n` is
the *measure* on configurations; it makes **no** Yang–Mills mass-gap claim, no
`μ > 0` spectral claim, and does **not** touch Surface #1 (which stays OPEN). It
is exactly the finite product of `haarSU3`, nothing more. -/
noncomputable def haarN (n : ℕ) : MeasureTheory.Measure (Fin n → SU3) :=
  MeasureTheory.Measure.pi (fun _ : Fin n => haarSU3)

/-- `haarN n` is a probability measure on the configuration space `Fin n → SU(3)`:
a finite product of probability measures is a probability measure. -/
instance instIsProbabilityMeasureHaarN (n : ℕ) : IsProbabilityMeasure (haarN n) := by
  unfold haarN
  infer_instance

-- Axiom audit for the product measure (transitive: certifies `haarN` and its
-- probability-measure instance are `sorry`/`sorryAx`-free). Expected:
-- `[propext, Classical.choice, Quot.sound]`.
#print axioms haarN

end TheoremaAureum.Towers.YM.SU3Instances
