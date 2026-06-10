/-
================================================================
Towers / YM / CasimirGap

**SU(3) spectral gap: minimum non-trivial Casimir eigenvalue.**

For the explicit SU(3) Casimir
`Casimir_SU3_explicit (m, n) = m² + n² + m·n + 3m + 3n`
(the integer form, `= 3 · C₂` where the true rational eigenvalue is
`C₂(m, n) = (m² + n² + m·n) / 3 + m + n`), every NON-trivial highest
weight `(m, n) ≠ (0, 0)` satisfies `4 ≤ Casimir_SU3_explicit (m, n)`,
with equality at the fundamental reps `(1, 0)` and `(0, 1)`. In true
(rational) units this is the SU(3) **spectral gap**
`min_{λ ≠ 0} C₂(λ) = 4/3`.

### Honest scope (locked)

This is an elementary `ℕ`-arithmetic fact about the explicit Casimir
polynomial. It is NOT, and must not be reported as:
  * the Varadhan / Molchanov small-`t` heat-kernel asymptotic
    `Heat_kernel_envelope_real t ≤ C · t⁻⁴` — that governs the `t → 0⁺`
    polynomial blow-up and stays OPEN (no `e^{-c/t}` factor exists at the
    identity, where the geodesic distance is `0`);
  * a mass-gap lower bound on any Yang–Mills Hamiltonian.
The constant `4/3` is the eigenvalue gap of the Casimir / Laplace–Beltrami
operator on SU(3); it bounds the exponential decay rate of
`Heat_kernel_envelope_real t - 1` as `t → ∞` (the LARGE-`t` regime), not
the small-`t` blow-up the user's `varadhan_SU3` target referred to.

`#print axioms casimir_SU3_min_nontrivial` = classical trio
`{propext, Classical.choice, Quot.sound}`. Sorry-free, axiom-free. NOT a
brick. YM tower stays `Status: Open` in `docs/ROADMAP.md`.
================================================================
-/
import Towers.YM.ClusterExpansion

namespace TheoremaAureum
namespace Towers
namespace YM
namespace CasimirGap

open TheoremaAureum.Towers.YM.ClusterExpansion

/-- **Minimum non-trivial SU(3) Casimir (integer form).** For every
highest weight `(m, n) ≠ (0, 0)`, `4 ≤ Casimir_SU3_explicit (m, n)`,
with equality at `(1, 0)` and `(0, 1)` (see `casimir_SU3_fundamental`).
In true units this is the spectral gap `min_{λ ≠ 0} C₂(λ) = 4/3`, since
`Casimir_SU3_explicit = 3 · C₂`.

Proof: `(m, n) ≠ (0, 0)` forces `m ≠ 0` or `n ≠ 0`; in either case the
corresponding square contributes `≥ 1` and the linear term `3·_` adds
`≥ 3`, with every remaining `ℕ` summand `≥ 0`. The single nonlinear fact
(`1 ≤ m²` resp. `1 ≤ n²`) is supplied explicitly so `omega` can close the
remaining linear bound. Pure `ℕ` arithmetic; classical trio, sorry-free. -/
theorem casimir_SU3_min_nontrivial (m n : ℕ) (h : (m, n) ≠ (0, 0)) :
    4 ≤ Casimir_SU3_explicit (m, n) := by
  have key : Casimir_SU3_explicit (m, n)
      = m ^ 2 + n ^ 2 + m * n + 3 * m + 3 * n := rfl
  rw [key]
  have hmn : m ≠ 0 ∨ n ≠ 0 := by
    by_contra hc
    push_neg at hc
    exact h (by rw [hc.1, hc.2])
  rcases hmn with hm | hn
  · have h1 : 1 ≤ m ^ 2 := Nat.one_le_pow 2 m (Nat.pos_of_ne_zero hm)
    omega
  · have h1 : 1 ≤ n ^ 2 := Nat.one_le_pow 2 n (Nat.pos_of_ne_zero hn)
    omega

/-- The fundamental rep `(1, 0)` saturates the gap:
`Casimir_SU3_explicit (1, 0) = 4` (true units: `C₂ = 4/3`). Together with
`casimir_SU3_min_nontrivial` this witnesses that `4` is the genuine
minimum, not a loose lower bound. -/
theorem casimir_SU3_fundamental : Casimir_SU3_explicit (1, 0) = 4 := rfl

/-- The conjugate fundamental rep `(0, 1)` also saturates the gap:
`Casimir_SU3_explicit (0, 1) = 4`. Both fundamentals attain the minimum. -/
theorem casimir_SU3_antifundamental : Casimir_SU3_explicit (0, 1) = 4 := rfl

-- #print axioms casimir_SU3_min_nontrivial

end CasimirGap
end YM
end Towers
end TheoremaAureum
