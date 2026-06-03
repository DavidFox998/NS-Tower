# Exceptional-Prime Gap
— α₀ = 299 + π/10

The exceptional-prime sequence for
constant α₀ = 299 + π/10 and the "desert" gaps between consecutive exceptional
primes. Every number below was recomputed at 7,600–12,000 decimal digits of π
and cross-checked against the repository sieve data
(`data/pi10_exceptional_primes.txt`). A self-contained re-runnable script is in
the appendix.

---

## 1. The test (there is only one)

A prime `p` is **exceptional** when

```
‖ p · α₀ ‖ < 1/p,      where ‖x‖ = min over n∈ℤ of |x − n|.
```

Because `299·p` is an integer, it drops out of the nearest-integer distance:

```
‖ p · α₀ ‖ = ‖ p · (299 + π/10) ‖ = ‖ p · π/10 ‖.
```

So the α₀ test and the π/10 test are **the same test** — there is no second
"test subject." Numerically:

| quantity | value |
|---|---|
| α₀ = 299 + π/10 | **299.31415927…** |
| (for contrast) 299 + π | 302.14159265… |

> **Caution (a common slip):** the decimal `302.14159265` is `299 + π`, **not**
> `299 + π/10`. A test built on `299 + π` reduces to `‖p·π‖ < 1/p`, which is a
> *different* irrational with a *different* exceptional set. See §6.

---

## 2. Method

- Candidates: exact continued-fraction **convergents and upper-semiconvergents**
  of π/10 (the only places where `‖p·π/10‖` can dip below `1/p`).
- Exceptional test evaluated in exact integer/rational arithmetic against π
  truncated to **8,300 digits**, with a decision certificate (margin ≈ 10⁸²⁹⁵
  over the whole search window `p ≤ 10⁴⁰⁰⁰`).
- Primality: **BPSW**. This is not a formal primality certificate for the
  thousand-digit-plus entries — flagged as a known limitation (§7).

---

## 3. Verified exceptional primes to 10⁴⁰⁰⁰ — count = 20

`r = p · ‖p·π/10‖` (so the test "passes" ⟺ `r < 1`). `class` distinguishes a
principal CF convergent from an upper-semiconvergent. `in 14?` marks the subset
found by report v1.6.

| # | digits | r = p‖p·π/10‖ | class | gap to prev (integers) | C_unwt cum | C_wt cum | in 14? |
|---|---|---|---|---|---|---|---|
| 1 | 1 (=2)   | 0.7434 | semiconv  | —        | 0.6931 | 1.386   | Y |
| 2 | 1 (=3)   | 0.1726 | principal | 1        | 1.2425 | 3.034   | Y |
| 3 | 2 (=19)  | 0.5885 | semiconv  | 16       | 1.4060 | 6.142   | Y |
| 4 | 3 (=191) | 0.8442 | semiconv  | 172      | 1.4337 | 11.422  | Y |
| 5 | 13       | 0.1524 | principal | 3,993,746,143,442 | 1.4337 | 40.44   | Y |
| 6 | 16       | 0.7750 | semiconv  | ~10¹⁵    | 1.4337 | 76.15   | Y |
| 7 | 24       | 0.1442 | principal | ~10²³    | 1.4337 | 130.9   | Y |
| 8 | 35       | 0.3571 | principal | ~10³⁴    | 1.4337 | 209.3   | Y |
| 9 | 76       | 0.4367 | principal | ~10⁷⁵    | 1.4337 | 384.0   | Y |
| 10| 95       | 0.8335 | semiconv  | ~10⁹⁴    | 1.4337 | 602.6   | **n** |
| 11| 111      | 0.5405 | semiconv  | ~10¹¹⁰   | 1.4337 | 857.5   | Y |
| 12| 372      | 0.5248 | semiconv  | ~10³⁷¹   | 1.4337 | 1712    | Y |
| 13| 859      | 0.5360 | semiconv  | ~10⁸⁵⁸   | 1.4337 | 3690    | Y |
| 14| 1025     | 0.0148 | principal | ~10¹⁰²⁴  | 1.4337 | 6049    | Y |
| 15| 1592     | 0.9804 | semiconv  | ~10¹⁵⁹¹  | 1.4337 | 9714    | **n** |
| 16| 1863     | 0.0505 | principal | ~10¹⁸⁶²  | 1.4337 | 14002   | Y |
| 17| 2272     | 0.5458 | semiconv  | ~10²²⁷¹  | 1.4337 | 19233   | **n** |
| 18| 2389     | 0.6931 | semiconv  | ~10²³⁸⁸  | 1.4337 | 24732   | **n** |
| 19| 3428     | 0.5106 | semiconv  | ~10³⁴²⁷  | 1.4337 | 32626   | **n** |
| 20| 3548     | 0.0277 | principal | ~10³⁵⁴⁷  | 1.4337 | 40793   | **n** |

The exact digit strings for every entry are in
`data/pi10_exceptional_primes.txt` (with the completeness/margin certificate).

### Why v1.6 reported 14, not 20 — both reasons are documented in v1.6 itself
1. **Search scope.** v1.6 enumerated **principal convergent numerators hₙ** only.
   Legendre's theorem guarantees principal convergents are complete only for the
   *stricter* threshold `1/(2p)` — not the `1/p` the project actually uses. The 5
   semiconvergent solutions (#10, 15, 17, 18, 19) are structurally invisible to
   that search.
2. **Precision ceiling.** v1.6's 4,010-digit π loses resolution past ~10²⁰⁰⁵ and
   flags this false-negative itself at h₄₆₁₀. Entry #20 is a *genuine principal
   convergent* (`r = 0.028`) that simply needs ≥7,200 digits to confirm.

The 14 is therefore "what v1.6's method + precision could see," **not** a clean
mathematical invariant. Note there is no natural criterion that yields exactly
14: `‖p·π/10‖ < 1/p` gives **20**, and the stricter `1/(2p)` would *drop*
2, 19, and 191 (all semiconvergents), leaving only 8.

---

## 4. The desert structure

- **First desert: 191 → p₅ = 3,993,746,143,633** — exactly
  **3,993,746,143,442** consecutive integers with **zero** exceptional primes.
  This ~4-trillion-wide void is bounded below by the 3-digit prime 191 and above
  by the **13-digit** prime p₅.
- Every subsequent gap is itself a desert of width ≈ 10¹⁵, 10²³, … up to 10³⁵⁴⁷
  (the entries are CF convergents, so they grow roughly geometrically in digit
  count).
- The four small primes 2, 3, 19, 191 are the *only* exceptional primes below
  10¹² — everything after is a giant.

---

## 5. Energy

Two cumulative sums over the exceptional set `S`:

```
C_unwt(S) = Σ_{p∈S} log p / (p − 1)
C_wt(S)   = Σ_{p∈S} log p · p / (p − 1)
```

| | through {2,3,19,191} | the 14 | the 20 |
|---|---|---|---|
| C_unwt | 1.4337 | 1.4337 | 1.4337 |
| C_wt | 11.4221 | 10,118 | 40,793 |
| vs 2√13 = 7.2111 | C_unwt < 7.2111 | — | — |

The unweighted sum is identical for the 14 and the 20 because the giant primes
contribute ~10⁻¹² each. **C_unwt = 1.4337 stays below 2√13 = 7.2111 under either
count.** The through-191 weighted value 11.4221 is exact and reproduces the
published figure for the classical four.

---

## 6. Appendix A — reconciliation with the previously-circulated 14-list

A list `2, 3, 19, 191, 291, 317, 607, 1091, 1567, 1709, 2087, 2273, 2609,
10651` was circulated as "the 14." Tested at full precision:

| p | prime? | ‖p·π/10‖ < 1/p | ‖p·π‖ < 1/p |
|---|---|---|---|
| 2, 3, 19, 191 | yes | **pass** | — |
| 291 | **no — 291 = 3 × 97** | fail | fail |
| 317 | yes | fail (‖·‖ ≈ 0.41) | fail |
| 607, 1091, 1567, 1709, 2087, 2273, 2609, 10651 | yes | **all fail** | all fail |

- **The first four (2, 3, 19, 191) are exactly right** and match this audit.
- From the fifth entry on, the list was generated from a **π** computation
  (α = 299 + π, decimal 302.14159…) mislabeled as π/10. Its worked examples
  confirm this: `‖2α‖ = 0.283185` is `‖2π‖`, and `‖3α‖ = 0.424777` is `‖3π‖`
  (the stated "0.424777 < 0.333" does not hold — that row fails its own test).
- A brute scan of all primes `p ≤ 11,000` finds `‖p·π/10‖<1/p` passes **only
  {2, 3, 19, 191}**, and `‖p·π‖<1/p` passes **{2, 7, 113}**. The circulated list
  matches neither test.
- The real fifth exceptional prime is the 13-digit p₅, which opens the first
  desert. The small numbers 291…10651 are not on the sequence.

### The "float64 false positives" diagnosis does not hold
- At insufficient precision the test returns `0.0` — a *meaningless* result, not
  a false pass. Confirmed: entry #10 needs π to ≥250 digits to register at all;
  entry #20 needs ≥7,200 digits.
- float64 carries ~15–16 significant digits and cannot even *represent* a
  95-digit or 3,548-digit integer, so it cannot have produced these entries.
- Once precision is sufficient the values are stable to many digits:
  #10 → `r = 0.83347` identically at 250 / 2,000 / 9,000-digit π;
  #20 → `r = 0.0276853` identically at 7,200 / 9,000-digit π.
- The six entries beyond v1.6's 14 are **verified prime**, not composite.

---

## 7. Appendix B — repo fixes needed (pending the 14-vs-20 decision)

The stored data currently contains values from the superseded v1.3–v1.5 run
(which tested CF **denominators** kₙ instead of **numerators** hₙ) and must be
corrected before any of it is relied on. **No edits have been made yet** — these
are flagged for the maintainer:

1. **`lean-proof-towers/Towers/Hodge/Defs.lean` — `S_14`.** Entries #8–#14 are
   composite (e.g. `154837899060399532100017991`, `5041018329913599611229009621`)
   and are not exceptional primes. Replace with the verified set chosen below.
2. **`data/exceptional_primes.csv` (and any mirror).** Same composite tail;
   the `n`-index column does not match the listed values' magnitudes.
3. **`lean-proof-towers/Towers/BostViolations/Compute.lean` — `C_rat ≈ 842.42`.**
   This figure is computed over the ≤31-digit composite `S_14` above, so it is
   not a meaningful energy for the real exceptional set. It must be recomputed
   over the corrected set (real C_wt: 10,118 for the 14, 40,793 for the 20).

**Open decision for the maintainer:** which set is canonical?
- **20** — the complete set under the project's stated `‖p·π/10‖ < 1/p` to
  10⁴⁰⁰⁰ (recommended: it is the only clean criterion that keeps 2, 19, 191).
- **14** — v1.6's principal-convergent working subset, with the criterion
  restated to match and the other 6 footnoted as "beyond v1.6's reach."

These corrections, and any publishing of this report, are deliberately deferred
until this draft is independently verified.

---

## 8. Appendix C — re-runnable verification script

```python
# Reproduces every number in this report. Requires: mpmath, sympy.
# Run from the repository root (reads data/pi10_exceptional_primes.txt).
from mpmath import mp, mpf, nint, log
from sympy import isprime, factorint, primerange
mp.dps = 9000
def norm(x): return abs(x - nint(x))

# §1 — which alpha0
print("299 + pi/10 =", mp.nstr(299 + mp.pi/10, 16))
print("299 + pi    =", mp.nstr(299 + mp.pi, 16), " (= the 302.14159 decimal)")

# §6 — the circulated 14-list, both tests
circulated = [2,3,19,191,291,317,607,1091,1567,1709,2087,2273,2609,10651]
for p in circulated:
    d10, dpi, inv = norm(mpf(p)*mp.pi/10), norm(mpf(p)*mp.pi), 1/mpf(p)
    print(f"{p:>6} prime={str(isprime(p)):>5} "
          f"pi/10<1/p={str(d10<inv):>5} pi<1/p={str(dpi<inv):>5} "
          f"{'' if isprime(p) else factorint(p)}")

# §6 — brute scan
print("pass pi/10:", [p for p in primerange(2,11001) if norm(mpf(p)*mp.pi/10) < 1/mpf(p)])
print("pass pi   :", [p for p in primerange(2,11001) if norm(mpf(p)*mp.pi)    < 1/mpf(p)])

# §3 + §5 — re-verify all 20 and the cumulative energies
vals = {}
for line in open("data/pi10_exceptional_primes.txt"):
    s = line.strip()
    if s and not s.startswith('#'):
        c = s.split()
        if len(c) >= 4 and c[0].isdigit():
            vals[int(c[0])] = int(c[3])
cu = cw = mpf(0)
for i in sorted(vals):
    p = vals[i]; assert norm(mpf(p)*mp.pi/10) < 1/mpf(p), f"#{i} FAILS"
    cu += log(p)/(p-1); cw += log(p)*p/(p-1)
print("count =", len(vals), " C_unwt =", mp.nstr(cu,8), " C_wt =", mp.nstr(cw,9))
print("first desert 191 -> p5:", vals[5]-191, "integers")
```
