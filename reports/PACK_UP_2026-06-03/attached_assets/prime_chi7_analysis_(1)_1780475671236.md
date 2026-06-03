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
