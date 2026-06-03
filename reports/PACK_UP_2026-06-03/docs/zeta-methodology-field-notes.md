# Zeta Methodology — Honest Field Notes

**Author:** D. Fox · **Status:** field notes (personal consolidation, NOT a
proof, NOT a submission) · **Date:** 2026-06-03

---

## Purpose

This document consolidates the scattered "how we arrived at ζ" work into one
readable trace of the *whole methodology chain*, end to end, with a
field-reporter verdict at each link: what is genuine mathematics, what is
standard-but-correct, what is overstated, and exactly where each link breaks.

It is a map of the path — a way to see clearly which steps are load-bearing and
which are decorative — not a new result. **Nothing here proves the Riemann
Hypothesis, a zero-free region, or any new bound on ζ.** Where the source drafts
claim otherwise, that is recorded as a finding, not adopted.

The honest register is borrowed deliberately from the strongest of the source
drafts, `Geometric_Zeta_Paper` ("No Rational Approximation Protocol", "Does not
resolve RH", and its explicit "what we deleted from v1" list). The over-claiming
draft, `Lemma33`, is reconciled against it below.

### Source material

| File | Role | Honesty |
|---|---|---|
| `attached_assets/Geometric_Zeta_Paper._(1)_*.tex` | The main draft; V, the dimension bound, the exp-sum corollary, the growth lemma | **Honest** — concedes true `D_H = 1`, "does not resolve RH", bound weaker than `t^{13/84}` |
| `attached_assets/Lemma33_*.tex` | "Ezekiel's Wheel" — the dimension-drop lemma + a claimed zero-free region | **Over-claims** — its own data table contradicts its caption |
| `attached_assets/prime_chi7_analysis_(1)_*.md` | The χ₇(p) = p² mod 7 counting experiment | **Honest** — explicitly an illustration of Dirichlet, "converges toward 1" |
| `attached_assets/main_(31)_*.tex` | "Hr sec 4 phone" — the `(log t)²` growth lemma + the RH endpoint | **False/circular** — recreated honestly in Lean as a conditional reduction |

### Existing honest recreations in the repo

| File | What it captures |
|---|---|
| `lean-proof-towers/Towers/RH/GrowthContradiction.lean` | The RH endpoint as an *undischarged conditional reduction* (growth + repulsion ⇒ real RH); both hypotheses OPEN, `GrowthBound` in fact false |
| `lean-proof-towers/Towers/RH/ZProtocolBridge.lean` | The same reduction re-skinned with Bessel constants; same verdict — constants discharge nothing |
| `lean-proof-towers/Towers/RH/ZeroDensity.lean` | The trivial zero-counting monotonicity brick + the Riemann–von Mangoldt formula pinned as a *statement only* |

---

## The chain at a glance

```
  (1) Bands         7-fold modular symmetry of primes: 3^p mod 7, χ₇(p)=p² mod 7
        │
  (2) Ratios        "wheel speed"  log N_r(x) / log x  per residue class
        │
  (3) Curves        V := 2∑(2πk/7)³ ≈ 52.069  and  D_H ≤ 1 − c/V   (claimed)
        │
  (4) Exp. sum      |∑ e^{−it log p}| ≤ H·t^{D_H−1+ε} + t^{1/2} log t   (claimed)
        │
  (5) ζ growth      |ζ(½+it)| ≤ C (log t)^{1/(1−D_H)+ε}   (claimed)
        │
  (6) RH attempt    growth bound + zero-repulsion  ⇒  RH
```

Each link feeds the next. The crucial observation of these notes is that the
chain **breaks at link (3)**: the dimension never drops below 1, so links (4)–(6)
inherit a vacuous input and produce nothing — and link (6) is independently
false and circular regardless.

---

## Link (1) — Bands: the 7-fold modular symmetry

### The genuine math

Two related maps partition the primes:

- **The orbit map `p ↦ 3^p mod 7`.** Since `3` is a *primitive root mod 7* —
  its powers cycle through all of `(ℤ/7)^×`:

  ```
  3^1=3, 3^2=2, 3^3=6, 3^4=4, 3^5=5, 3^6=1  (mod 7)
  ```

  the value `3^p mod 7` depends only on `p mod 6` (the order of 3 is 6).

- **The quadratic character `χ₇(p) = p² mod 7`.** For `p` coprime to `7`,
  `p² mod 7 ∈ {1, 2, 4}` — exactly the three quadratic residues. This groups the
  six coprime classes into three pairs, each of density `1/3`:

  | `p² mod 7` | residues of `p mod 7` |
  |:---:|:---:|
  | 1 | `1, 6` |
  | 2 | `3, 4` |
  | 4 | `2, 5` |

### Verdict — Link (1)

> **GENUINE but standard.** Both maps are correct elementary number theory. The
> χ₇ partition into three density-`1/3` pairs is a clean illustration of
> Dirichlet's theorem on primes in arithmetic progressions — and the
> `prime_chi7_analysis` note presents it honestly as exactly that. No new content.
>
> **The first crack appears here.** `Lemma33` restricts attention to the "active
> classes" `r ∈ {3, 5}`, i.e. `{p : 3^p ≡ 3 or 5 mod 7}`. Because `3` is a
> primitive root, `3^p ≡ 3 or 5 (mod 7)` **exactly when `p ≡ 1 or 5 (mod 6)`** —
> which is *every* prime `p > 3`. (`3^p ≡ 3` for `p ≡ 1`, `3^p ≡ 5` for `p ≡ 5`;
> verified directly.) So the "active class" set is essentially **all primes**,
> of natural density `1`. There is no sparse subset to exploit.

---

## Link (2) — Ratios: the "wheel speed" `log N_r(x) / log x`

### The genuine math

For a residue class `r`, set `N_r(x) = #{p ≤ x : 3^p ≡ r mod 7}` and track the
ratio `log N_r(x) / log x`. If `N_r(x) ≈ x^{α}`, this ratio estimates the
exponent `α`. The drafts call it the "wheel speed."

### What the data actually says

Recomputing the two active classes (matches the `Lemma33` table exactly):

| `x` | `N_3(x)` | `log N_3 / log x` | `N_5(x)` | `log N_5 / log x` |
|---|---|---|---|---|
| `10³` | 80 | 0.634363 | 86 | 0.644833 |
| `10⁴` | 611 | 0.696510 | 616 | 0.697395 |
| `10⁵` | 4784 | 0.735958 | 4806 | 0.736357 |
| `10⁶` | 39231 | 0.765605 | 39265 | 0.765668 |
| `10⁷` | (332194) | 0.788770 | (332383) | 0.788806 |
| `10⁸` | (2880517) | 0.807434 | (2880936) | 0.807442 |

The ratio runs `0.634 → 0.807` and **rises monotonically toward 1.0** — exactly
the behavior of `π(x) ~ x/log x`, where `log(x/log x)/log x = 1 − log log x/log x
→ 1`. This is the count converging to full density-`1`/`2` of the primes (one
class), not a dimension below 1.

### Verdict — Link (2)

> **GENUINE measurement, but it points the *opposite* way from the claim.** The
> `Lemma33` caption reads: *"The vector trends away from 1.0, with empirical gap
> `c ≥ 9.93` at `x = 10⁸`."* The table immediately below it **increases toward
> 1.0**. The caption contradicts its own data. The `Geometric_Zeta_Paper` draft
> reports the same numbers honestly: Test 4 lists `0.806 → 0.903 → 1.0 as
> k → ∞ [Expected by Chebotarev]` and concludes *"True D_H = 1."*
>
> The `c ≥ 9.93` figure is an artifact: it comes from comparing the *finite*
> ratio `0.807` at `x = 10⁸` against the weak target `0.998`, then back-solving
> for `c`. It is not a stable asymptotic constant — push `x` further and the
> ratio keeps climbing, shrinking any apparent gap to `0`.

---

## Link (3) — Curves: the volume `V` and the dimension bound `D_H ≤ 1 − c/V`

### The genuine math

**A note on what "dimension" means here.** The set `L_r = {log p : 3^p ≡ r mod
7}` is *countable*, so its literal Hausdorff dimension is trivially `0`. The
drafts (and these notes) use "`D_H`" loosely for the **box-counting / upper
Minkowski exponent of the counting function**, `limsup_{x→∞} log N_r(x) / log x`
— the quantity actually tabulated in Link (2). `Geometric_Zeta_Paper` writes
`D_H := dim_M L_r` (Minkowski) in places and `dim_H` in others; that conflation
is itself a small imprecision in the sources. Read every "`D_H`" below as the
counting exponent.

The constant is real and clean:

```
V := 2 ∑_{k=1}^{3} (2πk/7)³ = 72·(2π/7)³ = 576·(π/7)³ = 52.068849468958…
```

(verified: `576·(π/7)³ = 52.0688…`). The *machinery* invoked is also genuine,
textbook analytic number theory:

- **Erdős–Turán** bounds the discrepancy `D_N` of a sequence by its Weyl
  exponential sums — a real inequality.
- **Frostman's lemma / the mass-distribution principle** converts a measure with
  `μ(B(x,s)) ≤ s^{β}` into a Hausdorff-dimension lower bound — real.
- **Vaughan's method** handles exponential sums over primes — real.

The proposed pipeline: discrepancy ⇒ gaps of size `δ = c/V` ⇒ a set with uniform
gaps has a Cantor-like cover ⇒ `dim_H ≤ 1 − c`.

### Where it breaks

The pipeline is applied to the wrong set. The sequence `3^n mod 7` is **periodic
with period 6** (because `3` is a primitive root in the *finite* group
`(ℤ/7)^×`); it does not equidistribute on a circle with a `V`-controlled
discrepancy in any way that thins out the primes. The map `p ↦ 3^p mod 7`
factors through `p mod 6`, so selecting a residue class just selects primes in an
arithmetic progression mod 6 — which, by **Dirichlet/Chebotarev**, has positive
natural density. A positive-density subset of `{log p}` is **not** sparse:

```
        true   D_H = 1.
```

The draft's own proof sketch concedes the gap: step 5 reads *"c exists because V
finite and θ_r ≠ π. No computation needed."* Finiteness of `V` and `θ_r ≠ π` do
**not** imply any dimension drop — there is no mechanism connecting them to a
covering deficit, because the underlying set has density 1.

Even granting the bound formally, it is quantitatively inert. With the draft's
own `c = 0.1`:

```
1 − c/V = 1 − 0.1/52.0688… = 0.99807946…
```

a dimension of `0.998`, not below `1` in any useful sense — and, as link (6) will
show, hopelessly far from the `D_H < 1/2` that RH-grade conclusions require.

### Verdict — Link (3)

> **THIS IS WHERE THE CHAIN BREAKS.** The constant `V ≈ 52.069` is genuine and the
> cited tools (Erdős–Turán, Frostman, Vaughan) are real, but they are pointed at
> a density-`1` set, so they yield **no dimension drop**: the true Hausdorff/
> Minkowski dimension is `D_H = 1`, as both the data (Link 2) and Chebotarev
> confirm — and as `Geometric_Zeta_Paper` itself states ("Real D_H → 1 by
> Chebotarev"). The claimed `D_H ≤ 1 − c/V` is, at best, the vacuous `D_H ≤ 1`;
> the `0.998` figure is non-sharp and not load-bearing.
>
> **Knock-on:** `Lemma33`'s Theorem ("zero-free region from dimension",
> `β > 1 − c/(4V)·1/log|γ|`) is the classical de la Vallée Poussin *shape*, but
> its content is supplied entirely by `c > 0` from the broken lemma. With the
> honest `c = 0` (no drop), it asserts nothing.

---

## Link (4) — Exponential sum over primes

### The claim

From a Frostman measure of dimension `D_H`, the draft derives, for `H ≤ t^{1/2}`:

```
|∑_{x < p ≤ x+H, p∈P_r} e^{−it log p}|  ≤  H·t^{D_H−1+ε} + t^{1/2} log t.
```

### Verdict — Link (4)

> **CONDITIONALLY genuine, but fed a vacuous input.** The derivation shape (a
> dimension-`D_H` set gives a `t^{D_H−1}` saving in the exponential sum) is a
> legitimate heuristic. But it requires `D_H < 1` to give any saving — the factor
> `t^{D_H−1}` is a genuine power saving only when the exponent is negative. With
> the honest `D_H = 1` from Link (3), `t^{D_H−1+ε} = t^{ε}` and the first term is
> just `H·t^{ε}` — **no saving at all** beyond the trivial bound. The draft's own
> Test 3 confirms the weakness from the other side: at `t = 10²⁴`,
> `Bound/H = 56.16 > 0.1`, i.e. the bound does **not** decay. The cancellation the
> method needs does not exist, because selecting a residue class mod 6 introduces
> no oscillation — it is plain counting in an arithmetic progression.

---

## Link (5) — ζ growth bound

### The claim

The exponential-sum bound is fed into an approximate-functional-equation /
Riemann–Siegel-style assembly to yield:

```
|ζ(½ + it)|  ≤  C · (log t)^{1/(1−D_H)+ε}.
```

With `c = 0.1` (so `D_H ≤ 0.998079…`), the exponent is `1/(1−D_H) ≈ 520.7`,
giving the draft's `(log t)^{522+ε}`.

### Verdict — Link (5)

> **VACUOUS at the honest `D_H`.** The exponent `1/(1−D_H)` *diverges to `+∞`* as
> `D_H → 1`. With the true `D_H = 1` (Link 3) the bound degenerates to
> `(log t)^{∞}` — i.e. it says nothing. The `(log t)^{522}` figure exists only
> under the unestablished `0.998`. `Geometric_Zeta_Paper` is candid that even at
> face value this is *"insufficient for the Riemann Hypothesis"* and *"weaker than
> `t^{13/84}`"* (the known subconvexity bound). So the most this link could ever
> deliver — if Link (3) somehow held — is a `t^{o(1)}` bound far weaker than what
> is already proved by classical methods. It does not.

---

## Link (6) — RH attempt: growth bound + zero-repulsion ⇒ RH

### The claim (`main_(31)`, "Hr sec 4 phone")

```
Lemma (Growth bound).  ∃ C > 0, ∀ t ≥ 2, |ζ(½+it)| ≤ C (log t)².
Theorem (RH).          every nontrivial zero ρ has Re ρ = ½.
Proof.                 an off-line zero forces, "by standard zero-repulsion",
                       |ζ(½+it)| ≥ exp(c₁ log t / log log t) for arbitrarily
                       large t, contradicting the Lemma.
```

### Why this link fails on its own terms

Two independent problems, neither dependent on Links (1)–(5):

1. **The growth Lemma is false.** `|ζ(½+it)| ≤ C (log t)²` is far stronger than
   the Lindelöf hypothesis (`|ζ(½+it)| ≪ t^{ε}`) and is **refuted by classical
   Ω-results** (Titchmarsh §8; Montgomery): `|ζ(½+it)|` exceeds *any* fixed power
   of `log t` for arbitrarily large `t`. No such `C` exists. Note this is a
   *different* `(log t)²` from the `(log t)^{522}` of Link (5) — the fragment
   simply asserts it, and even cites a nonexistent "Lemma 5.1" at the
   contradiction step.

2. **It is circular.** Any *true* bound of comparable strength on `|ζ(½+it)|` is
   itself a consequence of RH. Using it as a hypothesis to prove RH assumes what
   it sets out to show.

### How the repo captures this honestly

The endpoint is recreated in Lean **not** as a proof of RH but as an *honest
conditional reduction* — `Towers/RH/GrowthContradiction.lean`:

- The target is the **real** RH (`_root_.RiemannHypothesis`, mathlib's
  million-dollar statement, aliased `RiemannHypothesisStmt`) — *not* the legacy
  `Prop := True` stub, which is untouched and not imported.
- `GrowthBound` and `ZeroRepulsion` are carried as **named, undischarged
  hypotheses**, with banners stating `GrowthBound` is unproven, false, and
  circular.
- The combinator `riemannHypothesis_of_growth_and_repulsion : GrowthBound →
  ZeroRepulsion → RiemannHypothesisStmt` is a genuine, `sorry`-free,
  classical-trio Lean proof — but its *only* real mathematics is a pure-calculus
  comparison `exp_loglog_dominates_sq` (that `exp(c₁ log t/log log t)` eventually
  dominates `C(log t)²`). That lemma carries **no** RH content; it just powers the
  contradiction. `ZeroRepulsion` is stated *conditionally* on an off-line zero so
  the combinator stays non-vacuous rather than collapsing to ex-falso.

`Towers/RH/ZProtocolBridge.lean` is the same reduction re-skinned with
Bessel-derived constants `{C_stable, C_Z1, C_Z2}`; wrapping the coefficient in
named numbers changes nothing — `GrowthBound_Z` is false for *every* choice, so
no provider can exist. `Towers/RH/ZeroDensity.lean` keeps the related
Riemann–von Mangoldt zero-counting formula honestly as a **statement only**, with
a trivial (proved) monotonicity brick around it.

### Verdict — Link (6)

> **FALSE and CIRCULAR as a proof; HONEST as a conditional reduction.** The
> implication "growth bound ⇒ RH (modulo repulsion)" is a real, machine-checked
> Lean theorem, but it proves nothing about RH because its growth hypothesis is
> unprovable (false by Ω-results) and circular. The Lean files exist precisely to
> record this honestly: **no `sorry`, no axiom debt, no RH claim.**

---

## What would actually be needed

For this methodology to bear on ζ, the broken links would each need a genuine
replacement — none of which is in hand:

1. **A real power saving in the prime exponential sum (Link 4):** a bound of the
   form `|∑_{p≤x} e^{−it log p}| ≪ x·t^{−η}` with `η > 0`, i.e. genuine
   cancellation. Selecting a residue class mod 6 gives none; this is the hard
   core of analytic number theory, not a corollary of `V`.

2. **A genuine sparsity / dimension input (Link 3):** some set with `D_H < 1`
   that actually controls `|ζ(½+it)|`. The active prime classes have `D_H = 1`,
   so the Frostman route starts from nothing.

3. **For RH specifically (Links 5–6):** the chain would need `D_H < 1/2` (per the
   draft's own Test 3), an enormous gap from `D_H = 1`; and any growth bound used
   at the endpoint must be one *not* equivalent to RH, or the argument is circular.

The honest constants and tools collected along the way — `V = 576(π/7)³`, the
χ₇ partition, Erdős–Turán, Frostman, the pure-calculus comparison lemma — are
real and worth keeping as scaffolding. The load-bearing step (a dimension drop /
exponential-sum saving) is the one that does not exist.

---

## Non-claim statement

These notes establish **no** new theorem. They make **no** claim that the
Riemann Hypothesis, the Generalized Riemann Hypothesis, a zero-free region, a
subconvexity bound, or any improvement on the known growth of `ζ` has been
proved or obtained — by this methodology or otherwise. The honest finding is the
opposite: the central dimension-drop step fails (true `D_H = 1`), and the RH
endpoint is false and circular. What survives is a clear map of *why* the path
does not reach its destination, and a set of genuine, reusable pieces along the
way.
