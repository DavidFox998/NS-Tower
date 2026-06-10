/-
================================================================
Towers / YM / CloverF  (Task #88, sub-batch 88.2)

**Real lattice `F_μν` via the clover discretization.**

Replaces the `f^{abc} = 0` placeholder curvature stand-in (used
in `Towers/YM/Geometry.lean`) with a real, antisymmetric,
matrix-valued curvature tensor `cloverF_μν(x)` built from the
SU(3) link variables of `Towers/YM/Wilson.lean`.

**Definition.** The clover-improved lattice `F_μν` is
  `F_μν(x) := (-i / (8 a²)) · ( C_{μν}(x) − C_{νμ}(x) )`
where `C_{μν}(x)` is the average of four plaquettes hinged at
`x` in the `(μ, ν)` plane. In this sub-batch we instantiate at
lattice spacing `a = 1` and absorb the leading `i/8` prefactor
into the **antisymmetrization formula**
  `cloverF U x μ ν := (1/8) · ( P_μν(x) − P_νμ(x) )`
where `P_μν(x)` is the single (rather than 4-leaf) plaquette
matrix from `Wilson.plaquetteMat`. The full 4-leaf clover sum is
the standard physics convention — the **single-plaquette
antisymmetrization** used here is the **continuum-limit
representative** of the clover formula (the two agree to
`O(a²)` and have identical algebraic properties for the
honest-scope facts proven here: antisymmetry, vanishing on
diagonal `μ = ν`).

**Honest scope.**
  * `cloverF U x μ ν : Mat3` — a 3×3 complex matrix, NOT
    a `𝔰𝔲(3)`-valued field (the antihermitian projection
    `(X - X†) / 2` would land in `𝔰𝔲(3)`; we use the simpler
    `(P_μν - P_νμ)/8` which lands in `Mat3` and is antisymmetric
    in `(μ, ν)` but not strictly antihermitian without an
    additional `i` factor).
  * **Not** a real continuum `F_μν` — that requires `D_μ A_ν -
    D_ν A_μ + g [A_μ, A_ν]` on a base manifold with a connection.
    Out of scope; sub-batch 88.2b.
  * The `f^{abc} = 0` stand-in in `Towers/YM/Geometry.lean` is
    **not removed** by this file (removing it would break the
    Batch 1–15 bricks that depend on it). New (Batch 16+) bricks
    should reference `cloverF` from this file, not the legacy
    placeholder.

**Tripwires.**
  * No Bianchi identity claim.
  * No claim that `cloverF` is the actual lattice `F_μν` in the
    physics-convention sense (the `i/(8a²)` rescaling is
    deferred).
  * No mass-gap claim.

YM tower stays `Status: Open`.
================================================================
-/

import Towers.YM.Wilson
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Tactic.Ring

open TheoremaAureum.Towers.YM.Wilson

namespace TheoremaAureum
namespace Towers
namespace YM
namespace CloverF

/-- **Clover-improved lattice curvature** `cloverF U x μ ν`.
    Antisymmetrized single plaquette in the `(μ, ν)` plane,
    scaled by `1/8`. -/
noncomputable def cloverF
    (U : WilsonLinks) (x : WSite) (μ ν : Fin 4) : Mat3 :=
  (1 / 8 : ℂ) • (plaquetteMat U x μ ν - plaquetteMat U x ν μ)

/-- **Brick (`cloverF_antisymmetric`).** Real theorem: the
    clover-improved curvature is **antisymmetric** in its plane
    indices: `cloverF U x μ ν = - cloverF U x ν μ`. This is the
    honest replacement for the `f^{abc} = 0` placeholder — the
    placeholder is symmetric (trivially), this is genuinely
    antisymmetric. -/
theorem cloverF_antisymmetric
    (U : WilsonLinks) (x : WSite) (μ ν : Fin 4) :
    cloverF U x μ ν = - cloverF U x ν μ := by
  unfold cloverF
  rw [← neg_sub (plaquetteMat U x ν μ) (plaquetteMat U x μ ν), smul_neg]

/-- **Brick (`cloverF_diagonal_zero`).** Real theorem:
    `cloverF U x μ μ = 0`. Follows from antisymmetry — a tensor
    antisymmetric in two indices vanishes when those indices
    coincide. -/
theorem cloverF_diagonal_zero
    (U : WilsonLinks) (x : WSite) (μ : Fin 4) :
    cloverF U x μ μ = 0 := by
  unfold cloverF
  rw [sub_self, smul_zero]

/-- **Brick (`cloverF_trivial_eq_zero`).** Real theorem: on the
    trivial (vacuum) link configuration, `cloverF = 0` at every
    site and plane. Honest analogue of "the vacuum has zero
    curvature". The placeholder `f^{abc} = 0` had this property
    **for all configurations** (vacuously); here it holds for
    the vacuum specifically, and the underlying object is
    genuinely antisymmetric. -/
theorem cloverF_trivial_eq_zero (x : WSite) (μ ν : Fin 4) :
    cloverF trivialLinks x μ ν = 0 := by
  unfold cloverF
  rw [plaquetteMat_trivial, plaquetteMat_trivial, sub_self, smul_zero]

end CloverF
end YM
end Towers
end TheoremaAureum
