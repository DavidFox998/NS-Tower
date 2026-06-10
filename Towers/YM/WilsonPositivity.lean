/-
Task #255 — Strict Wilson Action Positivity.

HONEST SCOPE — a real, `sorry`-free brick wave, but NOT a mass-gap claim:
  This file proves the single elementary inequality the Task #248 scalar
  reduction rests on:

    `∀ U, (∃ x μ ν, wilsonPlaquette U x μ ν ≠ 1) → 0 < wilsonAction U`

  i.e. the bare ordered-pair SU(3) Wilson plaquette action is STRICTLY
  positive whenever the gauge field has at least one non-identity
  plaquette. At the vacuum (`U ≡ const 1`, every plaquette `= 1`) the
  action is `0` (`wilsonAction_const_one_eq_zero`), so the hypothesis is
  necessary — this is the honest "off the vacuum" statement.

MATH ROUTE (elementary, no SU(N) character/spectral machinery):
  * Upper character bound + equality case. For a unitary `A`
    (`star A * A = 1`), the Hilbert–Schmidt identity
    `hsNormSq (A − 1) = 6 − 2·Re (tr A)` (already proved,
    `PeterWeylHeatVaradhan.hsNormSq_sub_one_eq`) plus
    `0 ≤ hsNormSq (A − 1)` gives `Re (tr A) ≤ 3`; the equality case
    `Re (tr A) = 3 ↔ A = 1` comes from `hsNormSq M = 0 ↔ M = 0`
    (`hsNormSq_eq_zero_iff`, proved here by the explicit `Fin 3`
    entrywise expansion: a sum of nine `‖·‖²` is `0` iff each entry is).
  * Each `wilsonPlaquette U x μ ν` is unitary — an ordered product of
    SU(3) links and their `star`s — so its energy
    `plaquetteEnergy = (3 − Re tr P)/3` is `≥ 0`, and `> 0 ↔ P ≠ 1`.
  * The action is a finite triple sum of non-negative energies with one
    strictly positive term, hence strictly positive (`Finset.sum_pos'`).

INVARIANT-LOCKED:
  * Makes NO mass-gap / μ>0 / Surface-#1-CLOSED claim. This is the
    SCALAR-sector action positivity only, NOT a statement about the real
    Wilson transfer operator on `L²(∏ SU(3), Haar)` (open Wall 574).
    Surface #1 stays OPEN, YM Status: Open. `MassGap574.lean` is
    untouched and its `sorry` stands.
  * Every declaration is `sorry`-free; axiom footprint is the classical
    trio `{propext, Classical.choice, Quot.sound}` (verify with
    `#print axioms`).
-/
import Towers.YM.WilsonAction
import Towers.YM.PeterWeylHeatVaradhan

namespace TheoremaAureum.Towers.YM.LatticeGauge

/-- **Brick (`hsNormSq_eq_zero_iff`).** The Hilbert–Schmidt squared norm
    of a `3×3` complex matrix vanishes iff the matrix is zero. Proof: the
    explicit `Fin 3` trace/product expansion writes `hsNormSq M` as the
    sum of the nine `Complex.normSq (M i j)`; a sum of non-negatives is
    `0` iff every summand is, and `Complex.normSq z = 0 ↔ z = 0`. This is
    the point-separation fact underlying the equality case of the SU(3)
    character bound. -/
theorem hsNormSq_eq_zero_iff (M : Matrix (Fin 3) (Fin 3) ℂ) :
    RiemannianGeometry.hsNormSq M = 0 ↔ M = 0 := by
  constructor
  · intro h
    unfold RiemannianGeometry.hsNormSq at h
    rw [Matrix.trace_fin_three] at h
    simp only [Matrix.mul_apply, Matrix.star_apply, Fin.sum_univ_three,
      Complex.star_def, ← Complex.normSq_eq_conj_mul_self, Complex.add_re,
      Complex.ofReal_re] at h
    have n00 := Complex.normSq_nonneg (M 0 0)
    have n01 := Complex.normSq_nonneg (M 0 1)
    have n02 := Complex.normSq_nonneg (M 0 2)
    have n10 := Complex.normSq_nonneg (M 1 0)
    have n11 := Complex.normSq_nonneg (M 1 1)
    have n12 := Complex.normSq_nonneg (M 1 2)
    have n20 := Complex.normSq_nonneg (M 2 0)
    have n21 := Complex.normSq_nonneg (M 2 1)
    have n22 := Complex.normSq_nonneg (M 2 2)
    have e00 : M 0 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e01 : M 0 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e02 : M 0 2 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e10 : M 1 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e11 : M 1 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e12 : M 1 2 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e20 : M 2 0 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e21 : M 2 1 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    have e22 : M 2 2 = 0 := Complex.normSq_eq_zero.mp (by linarith)
    refine Matrix.ext fun i j => ?_
    fin_cases i <;> fin_cases j <;> simp_all
  · rintro rfl
    simp [RiemannianGeometry.hsNormSq]

/-- **Brick (`traceRe_le_three`).** The real part of the trace of a
    unitary `3×3` matrix is at most `3 = dim`. From
    `0 ≤ hsNormSq (A − 1) = 6 − 2·Re (tr A)`. -/
theorem traceRe_le_three (A : Matrix (Fin 3) (Fin 3) ℂ)
    (hA : star A * A = 1) : (Matrix.trace A).re ≤ 3 := by
  have h0 := PeterWeylHeatVaradhan.hsNormSq_nonneg (A - 1)
  rw [PeterWeylHeatVaradhan.hsNormSq_sub_one_eq A hA] at h0
  linarith

/-- **Brick (`traceRe_eq_three_iff`).** Equality case of the upper
    character bound: a unitary `3×3` matrix attains `Re (tr A) = 3` iff it
    is the identity. From `hsNormSq (A − 1) = 6 − 2·Re (tr A)` and
    `hsNormSq (A − 1) = 0 ↔ A − 1 = 0`. -/
theorem traceRe_eq_three_iff (A : Matrix (Fin 3) (Fin 3) ℂ)
    (hA : star A * A = 1) : (Matrix.trace A).re = 3 ↔ A = 1 := by
  have key : A = 1 ↔ RiemannianGeometry.hsNormSq (A - 1) = 0 := by
    rw [hsNormSq_eq_zero_iff, sub_eq_zero]
  rw [key, PeterWeylHeatVaradhan.hsNormSq_sub_one_eq A hA]
  constructor <;> intro h <;> linarith

/-- **Brick (`wilsonPlaquette_star_mul_self`).** Every Wilson plaquette is
    unitary: as an ordered product of SU(3) links and their `star`s it
    lies in the `unitary` submonoid (closed under `*` and `star`), so
    `star P * P = 1`. -/
theorem wilsonPlaquette_star_mul_self {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    star (wilsonPlaquette U x μ ν) * wilsonPlaquette U x μ ν = 1 := by
  have huU : ∀ g : G, (g.1 : Matrix (Fin 3) (Fin 3) ℂ) ∈
      unitary (Matrix (Fin 3) (Fin 3) ℂ) := by
    intro g
    refine unitary.mem_iff.mpr ⟨?_, ?_⟩
    · exact Matrix.mem_unitaryGroup_iff'.mp
        (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1
    · exact Matrix.mem_unitaryGroup_iff.mp
        (Matrix.mem_specialUnitaryGroup_iff.mp g.2).1
  have hPmem : wilsonPlaquette U x μ ν ∈
      unitary (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold wilsonPlaquette
    exact mul_mem
      (mul_mem (mul_mem (huU (U (x, μ))) (huU (U (latticeShift x μ, ν))))
        (unitary.star_mem (huU (U (latticeShift x ν, μ)))))
      (unitary.star_mem (huU (U (x, ν))))
  exact unitary.star_mul_self_of_mem hPmem

/-- **Brick (`plaquetteEnergy_nonneg`).** The per-plaquette Wilson energy
    `(3 − Re tr P)/3` is non-negative, since `P` is unitary and so
    `Re tr P ≤ 3`. -/
theorem plaquetteEnergy_nonneg {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    0 ≤ plaquetteEnergy U x μ ν := by
  unfold plaquetteEnergy
  have hb := traceRe_le_three (wilsonPlaquette U x μ ν)
    (wilsonPlaquette_star_mul_self U x μ ν)
  have hnum : (0 : ℝ) ≤ 3 - (wilsonPlaquette U x μ ν).trace.re := by linarith
  exact div_nonneg hnum (by norm_num)

/-- **Brick (`plaquetteEnergy_pos_iff`).** The per-plaquette energy is
    strictly positive exactly when the plaquette is non-trivial:
    `0 < plaquetteEnergy U x μ ν ↔ wilsonPlaquette U x μ ν ≠ 1`. -/
theorem plaquetteEnergy_pos_iff {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    0 < plaquetteEnergy U x μ ν ↔ wilsonPlaquette U x μ ν ≠ 1 := by
  have hsms := wilsonPlaquette_star_mul_self U x μ ν
  unfold plaquetteEnergy
  constructor
  · intro hpos hP1
    have hr3 : (wilsonPlaquette U x μ ν).trace.re = 3 :=
      (traceRe_eq_three_iff _ hsms).mpr hP1
    rw [hr3] at hpos
    norm_num at hpos
  · intro hne
    have hlt : (wilsonPlaquette U x μ ν).trace.re < 3 :=
      lt_of_le_of_ne (traceRe_le_three _ hsms)
        (fun he => hne ((traceRe_eq_three_iff _ hsms).mp he))
    exact div_pos (by linarith) (by norm_num)

/-- **Brick (`wilsonAction_pos_of_nontrivial`) — Task #255 headline.**
    The bare ordered-pair SU(3) Wilson plaquette action is strictly
    positive whenever the gauge field has at least one non-identity
    plaquette. The action is a finite triple sum of non-negative
    per-plaquette energies (`plaquetteEnergy_nonneg`) with at least one
    strictly positive term (`plaquetteEnergy_pos_iff`), so
    `Finset.sum_pos'` applied at each level gives `0 < wilsonAction U`.

    INVARIANT-LOCKED: NOT a mass-gap / μ>0 / Surface-#1 claim. This is the
    scalar-sector action positivity only; the real Wilson transfer
    operator (Wall 574) is untouched. Surface #1 stays OPEN, YM Status:
    Open. -/
theorem wilsonAction_pos_of_nontrivial {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L)
    (h : ∃ x μ ν, wilsonPlaquette U x μ ν ≠ 1) :
    0 < wilsonAction U := by
  obtain ⟨x₀, μ₀, ν₀, hP⟩ := h
  letI : Fintype (Lattice d L) := inferInstanceAs (Fintype (Fin d → Fin L))
  unfold wilsonAction
  have hnn : ∀ (x : Lattice d L) (μ ν : Fin d), 0 ≤ plaquetteEnergy U x μ ν :=
    fun x μ ν => plaquetteEnergy_nonneg U x μ ν
  refine Finset.sum_pos'
    (fun x _ => Finset.sum_nonneg fun μ _ =>
      Finset.sum_nonneg fun ν _ => hnn x μ ν) ?_
  refine ⟨x₀, Finset.mem_univ x₀, ?_⟩
  refine Finset.sum_pos'
    (fun μ _ => Finset.sum_nonneg fun ν _ => hnn x₀ μ ν) ?_
  refine ⟨μ₀, Finset.mem_univ μ₀, ?_⟩
  refine Finset.sum_pos' (fun ν _ => hnn x₀ μ₀ ν) ?_
  exact ⟨ν₀, Finset.mem_univ ν₀,
    (plaquetteEnergy_pos_iff U x₀ μ₀ ν₀).mpr hP⟩

/-! ### Honest KP scaffolding (necessary, NOT sufficient)

The following are `sorry`-free, classical-trio lemmas that any
Kotecký–Preiss / cluster-expansion estimate must rest on. They are
**necessary but NOT sufficient**: each is a *pointwise* positivity, and
the infimum of the Wilson energy over non-vacuum configurations is `0`
(the action is continuous and vanishes at the vacuum), so NONE of them
yields the uniform-in-`L` spectral gap the mass gap needs. Surface #1
stays OPEN; YM stays `Status: Open`; the genuine gap remains the
disclaimed `Transfer.kotecky_preiss_criterion` `sorry`. -/

/-- **Brick (`wilsonAction_nonneg`).** The bare ordered-pair SU(3) Wilson
    action is non-negative: a finite triple sum of non-negative
    per-plaquette energies (`plaquetteEnergy_nonneg`). This is the input
    to the sub-Markov kernel bound `exp(-β·actL) ≤ 1` for `T_L`.
    INVARIANT-LOCKED: NOT a mass-gap / gap claim. -/
theorem wilsonAction_nonneg {d L : ℕ} [NeZero L] (U : GaugeConfig d L) :
    0 ≤ wilsonAction U := by
  letI : Fintype (Lattice d L) := inferInstanceAs (Fintype (Fin d → Fin L))
  unfold wilsonAction
  exact Finset.sum_nonneg fun x _ =>
    Finset.sum_nonneg fun μ _ =>
      Finset.sum_nonneg fun ν _ => plaquetteEnergy_nonneg U x μ ν

/-- **Brick (`plaquetteEnergy_eq_zero_iff`).** The per-plaquette energy
    vanishes exactly at a trivial plaquette:
    `plaquetteEnergy U x μ ν = 0 ↔ wilsonPlaquette U x μ ν = 1`. Immediate
    from `plaquetteEnergy_nonneg` + `plaquetteEnergy_pos_iff`. -/
theorem plaquetteEnergy_eq_zero_iff {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (x : Lattice d L) (μ ν : Fin d) :
    plaquetteEnergy U x μ ν = 0 ↔ wilsonPlaquette U x μ ν = 1 := by
  have hnn := plaquetteEnergy_nonneg U x μ ν
  constructor
  · intro h0
    by_contra hne
    have hpos := (plaquetteEnergy_pos_iff U x μ ν).mpr hne
    rw [h0] at hpos
    exact lt_irrefl 0 hpos
  · intro h1
    by_contra h0
    exact ((plaquetteEnergy_pos_iff U x μ ν).mp
      (lt_of_le_of_ne hnn (Ne.symm h0))) h1

/-- **Brick (`wilsonAction_eq_zero_iff`) — HONEST vacuum characterisation.**
    `wilsonAction U = 0 ↔ every plaquette is trivial`. The sum of
    non-negative energies vanishes iff each does
    (`Finset.sum_eq_zero_iff_of_nonneg`), and each does iff its plaquette
    is `1` (`plaquetteEnergy_eq_zero_iff`).

    HONESTY NOTE: this is **NOT** `U = 1`. A constant non-identity
    configuration (`U ≡ g`, `g ≠ 1`, giving `P = g·g·g⁻¹·g⁻¹ = 1`) and
    flat / pure-gauge configurations have all-trivial plaquettes yet
    `U ≠ 1`, so `wilsonAction U = 0 ↔ U = 1` is **false**. The honest
    right-hand side is "all plaquettes trivial". -/
theorem wilsonAction_eq_zero_iff {d L : ℕ} [NeZero L] (U : GaugeConfig d L) :
    wilsonAction U = 0 ↔ ∀ x μ ν, wilsonPlaquette U x μ ν = 1 := by
  letI : Fintype (Lattice d L) := inferInstanceAs (Fintype (Fin d → Fin L))
  unfold wilsonAction
  constructor
  · intro h x μ ν
    have h1 := (Finset.sum_eq_zero_iff_of_nonneg
      (fun x _ => Finset.sum_nonneg fun μ _ => Finset.sum_nonneg fun ν _ =>
        plaquetteEnergy_nonneg U x μ ν)).mp h x (Finset.mem_univ x)
    have h2 := (Finset.sum_eq_zero_iff_of_nonneg
      (fun μ _ => Finset.sum_nonneg fun ν _ => plaquetteEnergy_nonneg U x μ ν)).mp
      h1 μ (Finset.mem_univ μ)
    have h3 := (Finset.sum_eq_zero_iff_of_nonneg
      (fun ν _ => plaquetteEnergy_nonneg U x μ ν)).mp h2 ν (Finset.mem_univ ν)
    exact (plaquetteEnergy_eq_zero_iff U x μ ν).mp h3
  · intro h
    refine Finset.sum_eq_zero fun x _ => Finset.sum_eq_zero fun μ _ =>
      Finset.sum_eq_zero fun ν _ => ?_
    exact (plaquetteEnergy_eq_zero_iff U x μ ν).mpr (h x μ ν)

/-- A **polymer** (minimal honest scaffolding) is a finite set of oriented
    plaquettes `(x, μ, ν)`; its **energy** is the sum of the per-plaquette
    Wilson energies over the set. This is the *energy functional* ONLY —
    it is NOT the cluster-expansion *activity / weight* `z_γ` and proves
    NOTHING about polymer convergence. -/
noncomputable def polymerEnergy {d L : ℕ} [NeZero L] (U : GaugeConfig d L)
    (γ : Finset (Lattice d L × Fin d × Fin d)) : ℝ :=
  γ.sum (fun p => plaquetteEnergy U p.1 p.2.1 p.2.2)

/-- `polymerEnergy` is non-negative (`plaquetteEnergy_nonneg` termwise). -/
theorem polymerEnergy_nonneg {d L : ℕ} [NeZero L] (U : GaugeConfig d L)
    (γ : Finset (Lattice d L × Fin d × Fin d)) :
    0 ≤ polymerEnergy U γ :=
  Finset.sum_nonneg fun p _ => plaquetteEnergy_nonneg U p.1 p.2.1 p.2.2

/-- **Honest polymer-energy positivity (necessary for KP, NOT sufficient).**
    A polymer containing at least one non-trivial plaquette has strictly
    positive energy (`Finset.sum_pos'` + `plaquetteEnergy_pos_iff`).

    HONESTY NOTE: this does **NOT** give a uniform gap. The infimum of the
    energy over non-trivial polymers is `0` (continuity + vacuum), so this
    pointwise positivity is *necessary* but *not sufficient* — the
    uniform-in-`L` bound a Kotecký–Preiss estimate needs requires the
    (OPEN) cluster expansion. Surface #1 stays OPEN. -/
theorem polymerEnergy_pos_of_nontrivial {d L : ℕ} [NeZero L]
    (U : GaugeConfig d L) (γ : Finset (Lattice d L × Fin d × Fin d))
    (h : ∃ p ∈ γ, wilsonPlaquette U p.1 p.2.1 p.2.2 ≠ 1) :
    0 < polymerEnergy U γ := by
  obtain ⟨p, hp, hne⟩ := h
  refine Finset.sum_pos' (fun q _ => plaquetteEnergy_nonneg U q.1 q.2.1 q.2.2) ?_
  exact ⟨p, hp, (plaquetteEnergy_pos_iff U p.1 p.2.1 p.2.2).mpr hne⟩

end TheoremaAureum.Towers.YM.LatticeGauge
