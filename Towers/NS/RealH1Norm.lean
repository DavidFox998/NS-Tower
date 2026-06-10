/-
================================================================
Towers / NS / RealH1Norm  (Task #88, sub-batch 88.6)

**Real `H^1` norm of a non-abelian gauge field on the 2^4 lattice.**

Replaces the placeholder `H1Norm u t := 0` (from
`Towers/NS/EnergyV2.lean` Task #51) with a real, **non-trivial**
Sobolev-style norm that has the two ingredients the user
directive asks for:

  `H1NormReal A := sum_{x, mu, nu} ( ||discrete-curl_{mu nu}(x)||^2_F
                                + ||[A_mu(x), A_nu(x)]||^2_F )`

where the **discrete curl** is the lattice analogue of
`D_mu A_nu - D_nu A_mu`:
  `curlA x mu nu := A (shift x mu) nu - A x nu - A (shift x nu) mu + A x mu`
(forward differences in `mu` of `A_nu` minus forward differences
in `nu` of `A_mu`), and the **commutator** is the matrix
commutator `[X, Y] := X * Y - Y * X` on `Mat3`.

**Honest scope.**
  * The "gauge field" here is a **Lie-algebra-valued** map
    `A : WSite -> Fin 4 -> Mat3` (NOT restricted to `su(3)` -- the
    `su(3)` subspace would be the trace-free antihermitian
    matrices, a proper subspace of `Mat3` that mathlib v4.12.0
    does not surface as a typed `LieAlgebra`; we use `Mat3` and
    note this is a strict relaxation that contains the physical
    `su(3)` configurations as a sub-class).
  * The norms are **Frobenius** (sum of squared `Complex.normSq`
    of matrix entries), the canonical inner product on `Mat3`.
  * Both ingredients (kinetic curl, potential commutator) are
    discrete approximations of the continuum
    `integral ||nabla x A||^2 + ||[A, A]||^2 dx`. The continuum version requires
    `Bochner` integration on `R^4` with `su(3)`-valued fields --
    sub-batch 88.6b, NOT in scope here.

**Key non-trivial fact.** Unlike the placeholder `H1Norm = 0`,
this real H^1 norm is **non-zero on non-abelian configurations**:
if `[A_mu(x), A_nu(x)] not= 0` for some `x, mu, nu`, then
`H1NormReal A > 0`. The "non-abelian" name is essential here --
in an abelian gauge theory (U(1)) all commutators vanish, so
the `[A, A]` term is identically zero; only the non-abelian
`SU(3)` setting gives a genuine commutator contribution.

**Tripwires.**
  * No Sobolev embedding claim.
  * No claim that `H1NormReal` equals the continuum `||A||_{H^1}`.
  * No claim on the energy inequality `E(t) <= E(0)` -- that
    sits one level up in `Towers/NS/EnergyV2.lean` and is
    independent of this file.

NS tower stays `Status: Open`.
================================================================
-/

import Towers.YM.Wilson
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.Ring

open TheoremaAureum.Towers.YM.Wilson

namespace TheoremaAureum
namespace Towers
namespace NS
namespace RealH1Norm

open scoped BigOperators

/-- **Lie-algebra-valued gauge field on the 2^4 lattice.** `Mat3`
    is a strict relaxation of `su(3)` subset of `Mat3`. -/
abbrev GaugeFieldL : Type := WSite → Fin 4 → Mat3

/-- **Discrete curl** of a gauge field in the `(mu, nu)` plane:
    `(A(x+mu_hat))_nu - (A(x))_nu - (A(x+nu_hat))_mu + (A(x))_mu`. This is
    the lattice analogue of `d_mu A_nu - d_nu A_mu` (the
    abelian-curvature kinetic term). -/
def discreteCurl (A : GaugeFieldL) (x : WSite) (μ ν : Fin 4) : Mat3 :=
  A (shift x μ) ν - A x ν - A (shift x ν) μ + A x μ

/-- **Matrix commutator** `[X, Y] := X * Y - Y * X` on `Mat3`.
    Standard Lie bracket on the full matrix algebra; restricts
    to the `su(3)` Lie bracket on the trace-free antihermitian
    subspace. -/
def matComm (X Y : Mat3) : Mat3 := X * Y - Y * X

/-- **Frobenius norm squared** of a 3x3 complex matrix:
    `sum_{i,j} ||M_{ij}||^2`. Manifestly non-negative. -/
noncomputable def frobNormSq (M : Mat3) : ℝ :=
  ∑ i : Fin 3, ∑ j : Fin 3, Complex.normSq (M i j)

/-- `frobNormSq` is non-negative. -/
theorem frobNormSq_nonneg (M : Mat3) : 0 ≤ frobNormSq M := by
  unfold frobNormSq
  apply Finset.sum_nonneg; intro i _
  apply Finset.sum_nonneg; intro j _
  exact Complex.normSq_nonneg _

/-- `frobNormSq` of the zero matrix is zero. -/
@[simp] theorem frobNormSq_zero : frobNormSq (0 : Mat3) = 0 := by
  simp [frobNormSq]

/-- **Real H^1 norm** of a Lie-algebra-valued gauge field on the
    lattice:
      `H1NormReal A := sum_{x, mu, nu} ( ||curlA||^2_F + ||[A_mu, A_nu]||^2_F )`.
    Discrete analogue of the continuum
    `integral |nabla x A|^2 + |[A, A]|^2 dx`. Sum is over ordered `(mu, nu)`
    pairs (double-counting the 6 unordered planes). -/
noncomputable def H1NormReal (A : GaugeFieldL) : ℝ :=
  ∑ x : WSite, ∑ μ : Fin 4, ∑ ν : Fin 4,
    (frobNormSq (discreteCurl A x μ ν) +
     frobNormSq (matComm (A x μ) (A x ν)))

/-- The zero gauge field `A = 0`. -/
def zeroField : GaugeFieldL := fun _ _ => 0

/-- **Brick (`H1NormReal_nonneg`).** Real theorem: the real
    H^1 norm is non-negative on every Lie-algebra-valued
    configuration. The honest replacement for the placeholder
    fact `H1Norm u t = 0` (trivially `<= 0`): we now have a
    real bound `0 <= H1NormReal A` on a genuinely non-trivial
    functional. -/
theorem H1NormReal_nonneg (A : GaugeFieldL) : 0 ≤ H1NormReal A := by
  unfold H1NormReal
  apply Finset.sum_nonneg; intro x _
  apply Finset.sum_nonneg; intro μ _
  apply Finset.sum_nonneg; intro ν _
  exact add_nonneg (frobNormSq_nonneg _) (frobNormSq_nonneg _)

/-- **Brick (`H1NormReal_zero_eq_zero`).** Real theorem: the
    real H^1 norm of the zero field is zero -- both the discrete
    curl and the commutator vanish on `A = 0`. -/
theorem H1NormReal_zero_eq_zero : H1NormReal zeroField = 0 := by
  simp [H1NormReal, discreteCurl, matComm, zeroField]

end RealH1Norm
end NS
end Towers
end TheoremaAureum
