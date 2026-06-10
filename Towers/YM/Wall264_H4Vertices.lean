/-
================================================================
Towers / YM / Wall264_H4Vertices

**The 600-cell ("hypericosahedron") vertex geometry — MACHINE-CHECKED.**

This brick formally verifies, with EXACT golden-ratio arithmetic (no floating
point), the core geometry of the 600-cell {3,3,5} (the H4 root system) that the
`theorema-certs` dashboard renders in 3D (see
`artifacts/theorema-certs/src/lib/h4-600cell.ts`).

What is proved (classical trio only, no `sorry`):

* `vertices` is the standard 120-vertex set, split EXACTLY 8 + 16 + 96:
  - `famA` (8): the axis vectors `±e_i`;
  - `famB` (16): `(±1/2, ±1/2, ±1/2, ±1/2)`;
  - `famC` (96): even permutations of `(φ/2, 1/2, 1/(2φ), 0)` with the 8 sign
    combinations of the three non-zero entries.
  `famA_length`/`famB_length`/`famC_length`/`vertices_card` pin `8/16/96/120`.

* `vertices_on_sphere` — every one of the 120 vertices lies EXACTLY on the unit
  3-sphere (`nSq v = 1`). The `famC` cases close by `linear_combination` against
  the genuine golden-ratio identity `φ² = φ + 1` (`Wall261.phi_sq_eq`).

* `exists_unit_edge` — there is an adjacent pair of vertices at squared distance
  EXACTLY `2 − φ = 1/φ²` (the nearest-neighbor / edge separation of the
  600-cell, realized between `e₁` and a `famC` vertex).

DIVISION-FREE ENCODING. The website uses `1/(2φ)`; here it is written `(φ−1)/2`,
which is the SAME real number (`1/φ = φ − 1` from `φ² = φ + 1`). The vertex SET
is therefore identical to the rendered one; the rewrite only makes every proof a
polynomial identity in `φ` (no division), closable by `ring` / `linear_combination`.

HONEST SCOPE. This proves (a) all 120 vertices lie on the unit sphere, and (b)
that `2 − φ` is REALIZED as an edge length. It does NOT prove global minimality
(that `2 − φ` is the MINIMUM squared distance over all 7140 pairs), nor the full
720-edge / 12-regular adjacency structure — that finite-but-heavy enumeration is
deliberately DEFERRED (it is the "full edge structure" work, out of scope here).

This is a standalone GEOMETRY leaf. It proves NO Yang–Mills / mass-gap / NS
result, makes NO `μ > 0` / Surface-#1 claim, and touches no YM/NS surface. YM and
NS stay `Status: Open`.

Axioms: `{propext, Classical.choice, Quot.sound}` (classical trio); 0 `sorry`.
================================================================
-/
import Towers.YM.Wall261_H4Defect
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

namespace TheoremaAureum.Towers.YM.Wall264

/-- The golden ratio `φ = (1+√5)/2`, reused from `Wall261` (with `φ² = φ + 1`). -/
local notation "φ" => Wall261.phi

/-- A vertex of the 600-cell, as a point of `ℝ⁴`. -/
abbrev V : Type := ℝ × ℝ × ℝ × ℝ

/-- Squared Euclidean norm on `ℝ⁴`. -/
noncomputable def nSq : V → ℝ := fun (a, b, c, d) => a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2

/-- Squared Euclidean distance on `ℝ⁴`. -/
noncomputable def distSq : V → V → ℝ :=
  fun (a, b, c, d) (e, f, g, h) => (a - e) ^ 2 + (b - f) ^ 2 + (c - g) ^ 2 + (d - h) ^ 2

/-- Family A (8): the axis vectors `±e_i`. -/
noncomputable def famA : List V :=
[
  (1, 0, 0, 0),
  (0, 1, 0, 0),
  (0, 0, 1, 0),
  (0, 0, 0, 1),
  (-1, 0, 0, 0),
  (0, -1, 0, 0),
  (0, 0, -1, 0),
  (0, 0, 0, -1)
]
/-- Family B (16): `(±1/2, ±1/2, ±1/2, ±1/2)`. -/
noncomputable def famB : List V :=
[
  (-(1/2), -(1/2), -(1/2), -(1/2)),
  (1/2, -(1/2), -(1/2), -(1/2)),
  (-(1/2), 1/2, -(1/2), -(1/2)),
  (1/2, 1/2, -(1/2), -(1/2)),
  (-(1/2), -(1/2), 1/2, -(1/2)),
  (1/2, -(1/2), 1/2, -(1/2)),
  (-(1/2), 1/2, 1/2, -(1/2)),
  (1/2, 1/2, 1/2, -(1/2)),
  (-(1/2), -(1/2), -(1/2), 1/2),
  (1/2, -(1/2), -(1/2), 1/2),
  (-(1/2), 1/2, -(1/2), 1/2),
  (1/2, 1/2, -(1/2), 1/2),
  (-(1/2), -(1/2), 1/2, 1/2),
  (1/2, -(1/2), 1/2, 1/2),
  (-(1/2), 1/2, 1/2, 1/2),
  (1/2, 1/2, 1/2, 1/2)
]
/-- Family C (96): even perms of `(φ/2, 1/2, (φ-1)/2, 0)` with the 8 sign
    combinations of the three non-zero entries (`(φ-1)/2 = 1/(2φ)`). -/
noncomputable def famC : List V :=
[
  (φ/2, 1/2, (φ-1)/2, 0),
  (-(φ/2), 1/2, (φ-1)/2, 0),
  (φ/2, -(1/2), (φ-1)/2, 0),
  (-(φ/2), -(1/2), (φ-1)/2, 0),
  (φ/2, 1/2, -((φ-1)/2), 0),
  (-(φ/2), 1/2, -((φ-1)/2), 0),
  (φ/2, -(1/2), -((φ-1)/2), 0),
  (-(φ/2), -(1/2), -((φ-1)/2), 0),
  (φ/2, (φ-1)/2, 0, 1/2),
  (-(φ/2), (φ-1)/2, 0, 1/2),
  (φ/2, -((φ-1)/2), 0, 1/2),
  (-(φ/2), -((φ-1)/2), 0, 1/2),
  (φ/2, (φ-1)/2, 0, -(1/2)),
  (-(φ/2), (φ-1)/2, 0, -(1/2)),
  (φ/2, -((φ-1)/2), 0, -(1/2)),
  (-(φ/2), -((φ-1)/2), 0, -(1/2)),
  (φ/2, 0, 1/2, (φ-1)/2),
  (-(φ/2), 0, 1/2, (φ-1)/2),
  (φ/2, 0, -(1/2), (φ-1)/2),
  (-(φ/2), 0, -(1/2), (φ-1)/2),
  (φ/2, 0, 1/2, -((φ-1)/2)),
  (-(φ/2), 0, 1/2, -((φ-1)/2)),
  (φ/2, 0, -(1/2), -((φ-1)/2)),
  (-(φ/2), 0, -(1/2), -((φ-1)/2)),
  (1/2, φ/2, 0, (φ-1)/2),
  (-(1/2), φ/2, 0, (φ-1)/2),
  (1/2, -(φ/2), 0, (φ-1)/2),
  (-(1/2), -(φ/2), 0, (φ-1)/2),
  (1/2, φ/2, 0, -((φ-1)/2)),
  (-(1/2), φ/2, 0, -((φ-1)/2)),
  (1/2, -(φ/2), 0, -((φ-1)/2)),
  (-(1/2), -(φ/2), 0, -((φ-1)/2)),
  (1/2, (φ-1)/2, φ/2, 0),
  (-(1/2), (φ-1)/2, φ/2, 0),
  (1/2, -((φ-1)/2), φ/2, 0),
  (-(1/2), -((φ-1)/2), φ/2, 0),
  (1/2, (φ-1)/2, -(φ/2), 0),
  (-(1/2), (φ-1)/2, -(φ/2), 0),
  (1/2, -((φ-1)/2), -(φ/2), 0),
  (-(1/2), -((φ-1)/2), -(φ/2), 0),
  (1/2, 0, (φ-1)/2, φ/2),
  (-(1/2), 0, (φ-1)/2, φ/2),
  (1/2, 0, -((φ-1)/2), φ/2),
  (-(1/2), 0, -((φ-1)/2), φ/2),
  (1/2, 0, (φ-1)/2, -(φ/2)),
  (-(1/2), 0, (φ-1)/2, -(φ/2)),
  (1/2, 0, -((φ-1)/2), -(φ/2)),
  (-(1/2), 0, -((φ-1)/2), -(φ/2)),
  ((φ-1)/2, φ/2, 1/2, 0),
  (-((φ-1)/2), φ/2, 1/2, 0),
  ((φ-1)/2, -(φ/2), 1/2, 0),
  (-((φ-1)/2), -(φ/2), 1/2, 0),
  ((φ-1)/2, φ/2, -(1/2), 0),
  (-((φ-1)/2), φ/2, -(1/2), 0),
  ((φ-1)/2, -(φ/2), -(1/2), 0),
  (-((φ-1)/2), -(φ/2), -(1/2), 0),
  ((φ-1)/2, 1/2, 0, φ/2),
  (-((φ-1)/2), 1/2, 0, φ/2),
  ((φ-1)/2, -(1/2), 0, φ/2),
  (-((φ-1)/2), -(1/2), 0, φ/2),
  ((φ-1)/2, 1/2, 0, -(φ/2)),
  (-((φ-1)/2), 1/2, 0, -(φ/2)),
  ((φ-1)/2, -(1/2), 0, -(φ/2)),
  (-((φ-1)/2), -(1/2), 0, -(φ/2)),
  ((φ-1)/2, 0, φ/2, 1/2),
  (-((φ-1)/2), 0, φ/2, 1/2),
  ((φ-1)/2, 0, -(φ/2), 1/2),
  (-((φ-1)/2), 0, -(φ/2), 1/2),
  ((φ-1)/2, 0, φ/2, -(1/2)),
  (-((φ-1)/2), 0, φ/2, -(1/2)),
  ((φ-1)/2, 0, -(φ/2), -(1/2)),
  (-((φ-1)/2), 0, -(φ/2), -(1/2)),
  (0, φ/2, (φ-1)/2, 1/2),
  (0, -(φ/2), (φ-1)/2, 1/2),
  (0, φ/2, -((φ-1)/2), 1/2),
  (0, -(φ/2), -((φ-1)/2), 1/2),
  (0, φ/2, (φ-1)/2, -(1/2)),
  (0, -(φ/2), (φ-1)/2, -(1/2)),
  (0, φ/2, -((φ-1)/2), -(1/2)),
  (0, -(φ/2), -((φ-1)/2), -(1/2)),
  (0, 1/2, φ/2, (φ-1)/2),
  (0, -(1/2), φ/2, (φ-1)/2),
  (0, 1/2, -(φ/2), (φ-1)/2),
  (0, -(1/2), -(φ/2), (φ-1)/2),
  (0, 1/2, φ/2, -((φ-1)/2)),
  (0, -(1/2), φ/2, -((φ-1)/2)),
  (0, 1/2, -(φ/2), -((φ-1)/2)),
  (0, -(1/2), -(φ/2), -((φ-1)/2)),
  (0, (φ-1)/2, 1/2, φ/2),
  (0, -((φ-1)/2), 1/2, φ/2),
  (0, (φ-1)/2, -(1/2), φ/2),
  (0, -((φ-1)/2), -(1/2), φ/2),
  (0, (φ-1)/2, 1/2, -(φ/2)),
  (0, -((φ-1)/2), 1/2, -(φ/2)),
  (0, (φ-1)/2, -(1/2), -(φ/2)),
  (0, -((φ-1)/2), -(1/2), -(φ/2))
]
/-- The 120 vertices of the 600-cell, `famA ++ famB ++ famC`. -/
noncomputable def vertices : List V := famA ++ famB ++ famC

/-! ### Counts: the exact 8 + 16 + 96 = 120 decomposition. -/

theorem famA_length : famA.length = 8 := by rfl
theorem famB_length : famB.length = 16 := by rfl
theorem famC_length : famC.length = 96 := by rfl
theorem vertices_card : vertices.length = 120 := by rfl

/-! ### Every vertex lies exactly on the unit 3-sphere. -/

theorem famA_on_sphere : ∀ v ∈ famA, nSq v = 1 := by
  intro v hv
  unfold famA at hv
  fin_cases hv <;> simp only [nSq] <;> ring

theorem famB_on_sphere : ∀ v ∈ famB, nSq v = 1 := by
  intro v hv
  unfold famB at hv
  fin_cases hv <;> simp only [nSq] <;> ring

theorem famC_on_sphere : ∀ v ∈ famC, nSq v = 1 := by
  intro v hv
  unfold famC at hv
  fin_cases hv <;> simp only [nSq] <;>
    linear_combination (1 / 2 : ℝ) * Wall261.phi_sq_eq

/-- **MACHINE-CHECKED.** All 120 vertices of the 600-cell lie exactly on the
unit 3-sphere (`nSq v = 1`), via the exact golden-ratio identity `φ² = φ + 1`. -/
theorem vertices_on_sphere : ∀ v ∈ vertices, nSq v = 1 := by
  intro v hv
  unfold vertices at hv
  rcases List.mem_append.mp hv with h | h
  · rcases List.mem_append.mp h with hA | hB
    · exact famA_on_sphere v hA
    · exact famB_on_sphere v hB
  · exact famC_on_sphere v h

/-! ### The nearest-neighbor edge length `2 − φ` is realized. -/

theorem head_famA_mem : ((1, 0, 0, 0) : V) ∈ vertices := by
  unfold vertices
  exact List.mem_append_left _ (List.mem_append_left _ (by unfold famA; exact List.mem_cons_self _ _))

theorem head_famC_mem : ((φ / 2, 1 / 2, (φ - 1) / 2, 0) : V) ∈ vertices := by
  unfold vertices
  exact List.mem_append_right _ (by unfold famC; exact List.mem_cons_self _ _)

/-- The squared distance between `e₁` and the head `famC` vertex is exactly
`2 − φ = 1/φ²`, the 600-cell edge separation. -/
theorem edge_realized :
    distSq ((1, 0, 0, 0) : V) ((φ / 2, 1 / 2, (φ - 1) / 2, 0) : V) = 2 - φ := by
  simp only [distSq]
  linear_combination (1 / 2 : ℝ) * Wall261.phi_sq_eq

/-- **MACHINE-CHECKED.** Two vertices of the 600-cell are at squared distance
EXACTLY `2 − φ` (the nearest-neighbor edge separation, realized). This does NOT
assert global minimality over all pairs (deferred full edge structure). -/
theorem exists_unit_edge : ∃ v ∈ vertices, ∃ w ∈ vertices, distSq v w = 2 - φ :=
  ⟨(1, 0, 0, 0), head_famA_mem, (φ / 2, 1 / 2, (φ - 1) / 2, 0), head_famC_mem, edge_realized⟩

end TheoremaAureum.Towers.YM.Wall264
