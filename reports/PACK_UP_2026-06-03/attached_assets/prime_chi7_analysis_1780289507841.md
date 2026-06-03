# Prime Distribution via the Quadratic Character mod 7

## Overview

This document presents the results of a prime-counting experiment that partitions all primes
up to x according to the value of p² mod 7 — equivalently, by which quadratic residue
class mod 7 the prime p belongs to. Runs at x = 10⁷ and x = 10⁸ confirm Dirichlet's theorem
on primes in arithmetic progressions and give a concrete illustration of how the ratio
log N / log x converges toward 1 as x grows.

---

## The Map χ₇(p) = p² mod 7

For any integer p not divisible by 7, the value p² mod 7 takes exactly one of three possible
values: **1, 2, or 4**. These are precisely the **quadratic residues modulo 7** (since
1² ≡ 1, 2² ≡ 4, 3² ≡ 2, 4² ≡ 2, 5² ≡ 4, 6² ≡ 1 mod 7).

The map χ₇ therefore partitions the six non-zero residue classes mod 7 into three pairs:

| ω = p² mod 7 | Residue classes of p mod 7 |
|:---:|:---:|
| 1 | p ≡ 1 or 6 (mod 7) |
| 2 | p ≡ 3 or 4 (mod 7) |
| 4 | p ≡ 2 or 5 (mod 7) |

Each pair contributes exactly 2 of the 6 coprime residue classes, so by Dirichlet's theorem
each ω-class should contain **asymptotically 1/3** of all primes (away from 7).

---

## Script

```python
from sympy import primerange
import math
import time

LIMIT = 10**8  # 10x bigger than the 10^7 run

start = time.time()

def chi7(p): return pow(p, 2, 7)
N = {1: 0, 2: 0, 4: 0}

for p in primerange(2, LIMIT + 1):
    if p == 7: continue
    N[chi7(p)] += 1

elapsed = time.time() - start
for w in [1, 2, 4]:
    log_ratio = math.log(N[w]) / math.log(LIMIT)
    c = 1 - log_ratio
    print(f"ω = {w}: N = {N[w]:,}, log N / log x = {log_ratio:.6f}, c = {c:.6f}")
print(f"Runtime: {elapsed:.1f}s")
```

**Key implementation notes:**
- `pow(p, 2, 7)` uses Python's three-argument modular exponentiation — exact and fast.
- p = 7 is excluded because 7² ≡ 0 mod 7, placing it outside the three ω-classes.
- The column `c = 1 − log N / log x` measures how far the per-class count still is from
  matching the "dimension" of x itself; it decreases toward 0 as x → ∞.

---

## Results

### x = 10⁷  — π(10⁷) = 664,579

| ω | Count N | log N / log x | c = 1 − log N / log x | Share of π(x) |
|:---:|---:|:---:|:---:|:---:|
| 1 | 221,429 | 0.763605 | 0.236395 | 33.322 % |
| 2 | 221,591 | 0.763650 | 0.236350 | 33.347 % |
| 4 | 221,558 | 0.763641 | 0.236359 | 33.342 % |

Maximum inter-class difference: **162 primes** (< 0.07 % relative).

### x = 10⁸  — π(10⁸) = 5,761,455   ·   Runtime: 87.1 s

| ω | Count N | log N / log x | c = 1 − log N / log x | Share of π(x) |
|:---:|---:|:---:|:---:|:---:|
| 1 | 1,920,663 | 0.785431 | 0.214569 | 33.336 % |
| 2 | 1,920,298 | 0.785421 | 0.214579 | 33.329 % |
| 4 | 1,920,493 | 0.785427 | 0.214573 | 33.333 % |

Maximum inter-class difference: **365 primes** (< 0.02 % relative).

---

## Convergence Across Scales

The most telling comparison is how log N / log x and c evolve as x increases by a factor of 10:

| x | log N / log x (avg) | c (avg) | Max inter-class Δ | Δ / N (relative) |
|:---:|:---:|:---:|---:|:---:|
| 10⁷ | 0.763632 | 0.236368 | 162 | 0.073 % |
| 10⁸ | 0.785426 | 0.214574 | 365 | 0.019 % |

Two observations stand out:

1. **log N / log x is rising toward 1.** Going from x = 10⁷ to x = 10⁸, the ratio increases by
   about 0.022. This is consistent with the Prime Number Theorem: π(x) ~ x / ln x implies
   log π(x) / log x → 1, but only logarithmically slowly. At x = 10⁸ we are still about 0.215
   below the asymptotic value.

2. **The three classes remain in near-perfect lockstep.** The absolute spread grows (162 → 365)
   because there are simply more primes, but the *relative* spread shrinks by a factor of ~4
   (0.073 % → 0.019 %). The equidistribution is tightening exactly as predicted.

---

## Mathematical Interpretation

### Dirichlet's theorem

For any modulus q and any integer a coprime to q:

> π(x; q, a) ~ π(x) / φ(q)   as x → ∞

Here q = 7, φ(7) = 6. The six coprime classes each receive 1/6 of primes asymptotically,
grouping the three ω-classes at exactly 2/6 = 1/3 each.

### The ratio log N / log x and the constant c

By PNT, π(x) ~ x / ln x, so:

> log π(x) / log x = 1 − log(ln x) / log x  →  1   as x → ∞

Since N(ω, x) ≈ π(x)/3, the per-class ratio satisfies:

> log N(ω, x) / log x = log(π(x)/3) / log x = log π(x)/log x − log 3/log x

The correction term log 3 / log x equals about 0.068 at x = 10⁷ and 0.060 at x = 10⁸,
which accounts for most of the gap between the observed ratios and 1. The constant
c = 1 − log N / log x therefore shrinks as **c ≈ log(ln x) / log x + log 3 / log x**,
converging to 0, but only logarithmically — hence the slow movement even over a 10× increase
in x.

### Chebotarev density theorem (broader view)

The partition by p² mod 7 is an instance of the Chebotarev density theorem applied to the
splitting of primes in the cyclotomic field Q(ζ₇). The three ω-values correspond to the three
Frobenius conjugacy classes in Gal(Q(ζ₇)/Q) ≅ (ℤ/7ℤ)× ≅ ℤ/6ℤ when grouped by the squaring
map. The equal densities 1/3 reflect the equal sizes of those classes.

---

## Summary

| Property | x = 10⁷ | x = 10⁸ |
|---|---:|---:|
| Total primes π(x) | 664,579 | 5,761,455 |
| Primes per ω-class (observed avg) | 221,526 | 1,920,485 |
| Primes per ω-class (expected 1/3) | 221,526 | 1,920,485 |
| Max inter-class difference | 162 | 365 |
| log N / log x (avg across classes) | 0.763632 | 0.785426 |
| c = 1 − log N / log x (avg) | 0.236368 | 0.214574 |
| Runtime | < 1 s | 87.1 s |

The experiment provides strong numerical evidence for the uniform distribution of primes across
quadratic residue classes mod 7. The constant c is shrinking — but slowly — consistent with the
logarithmic rate of convergence guaranteed by analytic number theory.
