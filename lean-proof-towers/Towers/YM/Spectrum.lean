/-
================================================================
Towers / YM / Spectrum  (Batch 8 Track 3)

**From "`YMHamiltonian` non-zero" to "`YMHamiltonian` has a
gap-above-vacuum schema".** Five bricks named exactly per the
Batch 8 directive:

  1. `YMHamiltonian_image_nonzero` — `∃ A, YMHamiltonian A ≠ 0`.
     Witness `A = (fun _ => 1)`, closes via the existing Task #55
     `YMHamiltonian_one_eq_twelve` and `(12 : ℝ) ≠ 0`.
  2. `YMHamiltonian_image_bounded` — `∃ B, ∀ A, |YMHamiltonian A|
     ≤ B`. Witness `B = 12`, closes via the existing Task #61
     `YMHamiltonian_abs_le_twelve`.
  3. `YMHamiltonian_image_has_inf` —
     `BddBelow (Set.range YMHamiltonian) ∧
      (Set.range YMHamiltonian).Nonempty`. Both via Brick 1 / 2.
     Lets downstream callers name `sInf (Set.range YMHamiltonian)`
     without `Classical.choice` on an empty / unbounded set.
  4. `YMHamiltonian_vacuum_def` — pins the "vacuum connection"
     `vacuum_connection := fun _ : Fin 4 => (1 : SU(3))` to the
     numerical value `YMHamiltonian vacuum_connection = 12`. The
     vacuum is the only `SU3Connection` for which the schema
     gives a concrete numerical value.
  5. `YMHamiltonian_gap_above_vacuum_schema` — positivity
     projection of the new `MassGapV2 Δ` predicate, which
     measures the gap *above the vacuum value*
     (`|YMHamiltonian A − YMHamiltonian vacuum_connection|`)
     rather than the absolute value (the existing Task #68
     `MassGap` measures `|YMHamiltonian A|`, which is wrong
     physics — the gap is measured from the vacuum). The brick
     proves `MassGapV2 Δ → 0 < Δ`.

Plus supporting:

  * `vacuum_connection : SU3Connection` — the all-ones connection
    `fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ)`.
    Honest stand-in for the OS-reconstructed YM vacuum; the
    smallest-trace-stand-in vacuum the current placeholder schema
    admits.
  * `MassGapV2 Δ : Prop` — gap-above-vacuum predicate
    `0 < Δ ∧ ∀ A ≠ vacuum_connection, Δ ≤ |YMHamiltonian A −
    YMHamiltonian vacuum_connection|`. Successor to the Task #68
    `MassGap` predicate.

### Honest scope

What this file claims:

  * Genuine `∃` / `∀` statements about the image of the Task #51 /
    Task #55 / Task #61 placeholder `YMHamiltonian : SU3Connection
    → ℝ`. They are real facts about a real `ℝ`-valued function on
    `Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ`.
  * `vacuum_connection` is the literal all-ones SU(3) connection.
  * `YMHamiltonian_vacuum_def` is the literal identity
    `YMHamiltonian (fun _ => 1) = 12`, packaged under a named
    "vacuum" handle.
  * `YMHamiltonian_gap_above_vacuum_schema` is the positivity
    projection of `MassGapV2`. The unconditional claim
    `∃ Δ > 0, MassGapV2 Δ` is **NOT** proved in this file (and
    would require either a non-trivial lower bound on
    `|YMHamiltonian A − 12|` away from the vacuum or a refined
    `YMHamiltonian` def — neither is in scope for this batch).

What this file does NOT claim:

  * Existence of a Yang-Mills mass gap;
  * Any spectral theorem on the YM physical-state Hilbert space;
  * `vacuum_connection` is the physical YM vacuum (it isn't — the
    OS-reconstructed physical vacuum is in a different Hilbert
    space entirely);
  * Any Clay-style result.

YM tower status unchanged: **Open** (`docs/ROADMAP.md` § 2).

### Zero shared imports

This file imports only `Towers.YM.MassGap` (which carries the
existing `SU3Connection`, `YMHamiltonian`, `YMHamiltonian_one_eq_twelve`,
`YMHamiltonian_abs_le_twelve` foundation). It does NOT import
`Towers.Spectral.OperatorV2` or `Towers.NS.EnergyV2` — the other
two Batch 8 tracks are independent and run in parallel.
================================================================
-/

import Towers.YM.MassGap

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Spectrum

open TheoremaAureum.Towers.YM

/-! ### Supporting defs -/

/-- **`vacuum_connection`** — the all-ones SU(3) connection
`fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ)`.
Honest stand-in for the OS-reconstructed YM vacuum; the only
`SU3Connection` on which the placeholder schema gives a concrete
numerical value (`= 12` via Task #55's
`YMHamiltonian_one_eq_twelve`). -/
def vacuum_connection : SU3Connection :=
  fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ)

/-- **`MassGapV2 Δ`** — gap-above-vacuum predicate. Successor to
the Task #68 `MassGap`, which measured `|YMHamiltonian A|`
(wrong physics — the gap is measured from the vacuum). Here the
gap is the absolute difference from the vacuum value:

  `0 < Δ ∧ ∀ A ≠ vacuum_connection,
     Δ ≤ |YMHamiltonian A − YMHamiltonian vacuum_connection|`. -/
def MassGapV2 (Δ : ℝ) : Prop :=
  0 < Δ ∧ ∀ A : SU3Connection, A ≠ vacuum_connection →
    Δ ≤ |YMHamiltonian A - YMHamiltonian vacuum_connection|

/-! ### Bricks (5) — exact names per Batch 8 directive -/

/-- **Brick 1 (`YMHamiltonian_image_nonzero`).**
`∃ A, YMHamiltonian A ≠ 0`. The all-ones SU(3) connection
evaluates to `12` via Task #55's `YMHamiltonian_one_eq_twelve`,
and `(12 : ℝ) ≠ 0`. First time the schema is shown to have
non-zero image. -/
theorem YMHamiltonian_image_nonzero :
    ∃ A : SU3Connection, YMHamiltonian A ≠ 0 := by
  refine ⟨fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ), ?_⟩
  rw [YMHamiltonian_one_eq_twelve]
  norm_num

/-- **Brick 2 (`YMHamiltonian_image_bounded`).**
`∃ B, ∀ A, |YMHamiltonian A| ≤ B`. Promotes the per-`A` Task #61
bound `YMHamiltonian_abs_le_twelve` to an `∃` over `A`, naming
`B = 12` as a uniform witness. The image of `YMHamiltonian` is
a bounded subset of `[-12, 12]`. -/
theorem YMHamiltonian_image_bounded :
    ∃ B : ℝ, ∀ A : SU3Connection, |YMHamiltonian A| ≤ B :=
  ⟨12, YMHamiltonian_abs_le_twelve⟩

/-- **Brick 3 (`YMHamiltonian_image_has_inf`).**
`BddBelow (Set.range YMHamiltonian) ∧
 (Set.range YMHamiltonian).Nonempty`. The lower bound is `-12`
via `abs_le.mp` on `YMHamiltonian_abs_le_twelve`; the non-empty
witness is the all-ones connection at value `12`. Lets downstream
callers name `sInf (Set.range YMHamiltonian)` without
`Classical.choice` on an empty / unbounded set. -/
theorem YMHamiltonian_image_has_inf :
    BddBelow (Set.range YMHamiltonian) ∧
      (Set.range YMHamiltonian).Nonempty := by
  refine ⟨⟨-12, ?_⟩, ?_⟩
  · rintro y ⟨A, rfl⟩
    have h := YMHamiltonian_abs_le_twelve A
    exact (abs_le.mp h).1
  · refine ⟨12, ?_⟩
    exact ⟨fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ),
           YMHamiltonian_one_eq_twelve⟩

/-- **Brick 4 (`YMHamiltonian_vacuum_def`).** Pins the numerical
value of the placeholder Hamiltonian at the named vacuum:
`YMHamiltonian vacuum_connection = 12`. Closes by direct
rewrite against Task #55's `YMHamiltonian_one_eq_twelve` — the
def of `vacuum_connection` is `fun _ => 1`, so the two sides are
literally the same expression.

Honest scope: `vacuum_connection` is NOT the OS-reconstructed YM
vacuum (a different Hilbert space). It is the smallest-trace
SU(3) stand-in vacuum the current placeholder schema admits. -/
theorem YMHamiltonian_vacuum_def :
    YMHamiltonian vacuum_connection = 12 :=
  YMHamiltonian_one_eq_twelve

/-- **Brick 5 (`YMHamiltonian_gap_above_vacuum_schema`).**
Positivity projection of the new `MassGapV2` predicate:
`MassGapV2 Δ → 0 < Δ`. Together with `MassGapV2`'s definition,
this brick pins the *shape* of "gap above the vacuum" without
claiming any particular `Δ` has a witness.

Honest scope: this is a `And.left` projection — the unconditional
claim `∃ Δ > 0, MassGapV2 Δ` is **NOT** proved in this file and
would require either a non-trivial lower bound on
`|YMHamiltonian A − 12|` away from the vacuum, or a refined
`YMHamiltonian` def. Neither is in scope for this batch. YM
tower status unchanged: **Open**. -/
theorem YMHamiltonian_gap_above_vacuum_schema
    {Δ : ℝ} (h : MassGapV2 Δ) : 0 < Δ := h.1

/-! ### Batch 9 (5) — vacuum-attained inf + MassGapV2 algebra

Five more bricks on the Batch 8 `MassGapV2` / `YMHamiltonian` /
`vacuum_connection` surface. Two name the vacuum-value side of the
"placeholder spectrum"; two are pure algebra on the `MassGapV2`
predicate (positivity, monotone-in-Δ); one is the `0 ≤ Δ`
projection schema.

**Honest scope.** None of these advance the YM tower past
`Status: Open` (see `docs/ROADMAP.md` § 2). They prove only:

  * `YMHamiltonian_inf_eq_twelve` — `sInf {YMHamiltonian
    vacuum_connection} = 12`, i.e. `sInf` of the **singleton**
    `{12}`. NOT the infimum of the full image
    `Set.range YMHamiltonian` (that infimum is `-12`, not `12`).
  * `YMHamiltonian_attains_inf` — `∃ A, YMHamiltonian A = 12`
    (witness `vacuum_connection`). Stand-in for "the placeholder
    value `12` is attained", not "the YM Hamiltonian achieves its
    spectral infimum at the vacuum".
  * `MassGap_v2_zero_iff` — `MassGapV2 0 ↔ False`. Pure logic on
    the positivity component of the predicate.
  * `MassGap_v2_monotone` — `MassGapV2 Δ₁ → Δ₂ ≤ Δ₁ → 0 < Δ₂ →
    MassGapV2 Δ₂`. Pure algebra: a lower bound at `Δ₁` is still a
    lower bound at any smaller positive `Δ₂`.
  * `spectrum_gap_schema` — `MassGapV2 Δ → 0 ≤ Δ`. Non-strict
    projection (companion to `YMHamiltonian_gap_above_vacuum_schema`,
    which gives the strict `0 < Δ`). -/

/-- **Brick (`YMHamiltonian_inf_eq_twelve`).** The `sInf` of the
singleton set `{YMHamiltonian vacuum_connection}` equals `12`.
Via `YMHamiltonian_vacuum_def` (the singleton is `{12}`) then
`csInf_singleton`. **Honest scope.** This is `sInf {12} = 12`,
NOT `sInf (Set.range YMHamiltonian) = 12` — the latter is
**FALSE** (the range is bounded below by `-12` via
`YMHamiltonian_abs_le_twelve`, with `-12` attained by `-1`-trace
SU(3) components). The brick names the vacuum value's
singleton-infimum, not the full spectral infimum. -/
theorem YMHamiltonian_inf_eq_twelve :
    sInf ({YMHamiltonian vacuum_connection} : Set ℝ) = 12 := by
  rw [YMHamiltonian_vacuum_def]
  exact csInf_singleton 12

/-- **Brick (`YMHamiltonian_attains_inf`).** The placeholder value
`12` is attained by `YMHamiltonian` on `vacuum_connection`:
`∃ A : SU3Connection, YMHamiltonian A = 12`. Witness
`vacuum_connection` via `YMHamiltonian_vacuum_def`. Honest scope:
this says only that `12` is in the range; it does NOT say `12`
is the spectral infimum (the range infimum is `-12`, not `12`). -/
theorem YMHamiltonian_attains_inf :
    ∃ A : SU3Connection, YMHamiltonian A = 12 :=
  ⟨vacuum_connection, YMHamiltonian_vacuum_def⟩

/-- **Brick (`MassGap_v2_zero_iff`).** `MassGapV2 0 ↔ False`. The
positivity component of `MassGapV2` requires `0 < Δ`, so `Δ = 0`
contradicts it; conversely `False` implies anything. Pure logic
on the predicate's first conjunct. Honest scope: this is a
falsity proof for the degenerate `Δ = 0` case, not a non-existence
proof for any `Δ > 0`. -/
theorem MassGap_v2_zero_iff : MassGapV2 0 ↔ False := by
  constructor
  · intro h
    exact lt_irrefl 0 h.1
  · intro h
    exact h.elim

/-- **Brick (`MassGap_v2_monotone`).** If `MassGapV2 Δ₁` holds and
`0 < Δ₂ ≤ Δ₁`, then `MassGapV2 Δ₂` also holds. Pure algebra:
the universal lower bound `Δ₁ ≤ |YMHamiltonian A − 12|` for
non-zero `ψ` implies the weaker `Δ₂ ≤ |YMHamiltonian A − 12|` by
transitivity through `Δ₂ ≤ Δ₁`. Honest scope: this is monotone-
in-Δ algebra on the predicate, NOT a sharpness or attainment
result. -/
theorem MassGap_v2_monotone {Δ₁ Δ₂ : ℝ}
    (h : MassGapV2 Δ₁) (hle : Δ₂ ≤ Δ₁) (hpos : 0 < Δ₂) :
    MassGapV2 Δ₂ := by
  refine ⟨hpos, ?_⟩
  intro A hne
  exact hle.trans (h.2 A hne)

/-- **Brick (`spectrum_gap_schema`).** Non-strict version of
`YMHamiltonian_gap_above_vacuum_schema`: `MassGapV2 Δ → 0 ≤ Δ`.
Via `le_of_lt` on `h.1`. Honest scope: schema-level projection,
NOT an existence claim — does NOT prove `∃ Δ ≥ 0, MassGapV2 Δ`
nor any positive lower bound on `|YMHamiltonian A − 12|`. -/
theorem spectrum_gap_schema {Δ : ℝ} (h : MassGapV2 Δ) : 0 ≤ Δ :=
  le_of_lt h.1

end Spectrum
end YM
end Towers
end TheoremaAureum
