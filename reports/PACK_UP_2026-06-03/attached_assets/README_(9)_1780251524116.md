# Rank-15 Hodge Classes on Jac(y^2 = x^11 - x): Computational Counterexamples to the Recurrence Test

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20087650.svg)](https://doi.org/10.5281/zenodo.20087650)

**Paper 2 of 3: Rank Obstructions for the Hodge Recurrence Test**

This repository provides 200 explicit (2,2)-classes on the genus-5 Jacobian `X_5 = Jac(y^2 = x^11 - x)` where the linear recurrence test from Paper 1 fails.

### Companion Papers
- **Paper 1**: [Computable Linear Recurrence Test](https://github.com/DavidFox998/hodge-cm-recurrence) — Test works for p=1, verifies Hodge for all 339 CM abelian varieties in LMFDB
- **Paper 2**: **This repo** — Rank Obstructions for the Hodge Recurrence Test
- **Paper 3**: [Tensor Rank Criteria for (p,p)-Classes](https://github.com/DavidFox998/tensor-rank-criteria-abelian-varieties) — Zoe invariant repairs the test for p≥2

---

### Main Result
For Jacobians `X_g = Jac(y^2 = x^{2g+1} - x)` with `g = 3,4,5` and `End^0(X_g) = ℚ`, the linear recurrence test from Paper 1 fails for `(2,2)`-classes.

We construct **200 explicit counterexamples** `ω ∈ H^{2,2}(X_g, ℚ)` where:

$$ \mathrm{rank}_{\mathbb{Q}}(H_{ij}) = \binom{g}{2} + \binom{g}{4} + \cdots > \binom{g}{2} $$

**For g=5**: `rank = 15 > 10 = binom(5,2)`. Algorithm A2 returns `False`.

### Key Finding 
The recurrence bound `rank ≤ binom(g,p)` holds **iff p=1**. When `p≥2`, rank can grow to:

$$ \mathrm{rank} = \binom{g}{p} + \binom{g}{p+2} + \binom{g}{p+4} + \cdots $$

This is a **computational obstruction to extending the recurrence test** beyond `p=1`. It motivates the tensor-rank criterion in Paper 3.

### The Test
For `ω ∈ H^{p,p}(X, ℚ)`, define the intersection characteristic:

$$ R_\omega(k) := \int_X \omega^k \cup H^{g-pk}, \quad 0 \leq k \leq \lfloor g/p \rfloor $$

Form Hankel matrix `H_{ij} = R_\omega(i+j)`. If `ω` is algebraic, Paper 1 predicts `rank(H) ≤ binom(g,p)`.

**We found 200 ω where this fails for p=2, g=5.**

### Verify it yourself in 1 command
1. Install SageMath 10.4+
2. Clone: `git clone https://github.com/DavidFox998/hodge-zoe-rank-obstructions`
3. Run: `sage verify.sage`
4. Output: `All 200 classes: rank = 15. Bound = 10. Test FAILED.`

Runtime: ~7 hours. All arithmetic exact over `QQ`. SHA256 hashes in `SHA256SUMS`.

```sage
sage: load("rank_obstruction.sage")
sage: load("generate_paper2_data.sage") 
sage: omega = generate_omega(g=5, index=0)
sage: A2(omega, g=5)
False, rank(H) = 15
