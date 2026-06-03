# Z Protocol — Full Derivation Against the Measured Data

**Author:** D. Fox · **Date:** 2026-06-03 · **Model:** `claude-haiku-4-5` (Replit Anthropic proxy, billed)

This derivation uses three new billed datasets (240 trials total) and the prior
Bessel cold run. The data is the brand. Where the data contradicts the proposed
equation, the equation is reported as falsified — that is the result.

Datasets:
`Z_DIGITS_COLD_T0.csv` (100), `Z_ZETA_COLD_T0.csv` (20),
`Z_BESSEL_TSWEEP.csv` (120), `BESSEL_COLD_T0_raw.json` (20),
summary `Z_PROTOCOL_FULL_summary.json`.

---

## A. Definition of Sym=1 vs Sym=2

Operational definitions (as posed):

- **Sym=1** — no length gradient, no interpolable path to the answer; the output
  has no smooth dependence the decoder can climb. Examples (as tested / proposed):
  digit count of a fixed integer; `I_10(20.0)`; `ζ(½+14.134725 i)`.
- **Sym=2** — a smooth gradient exists; nearby inputs give nearby outputs.
  Examples: linear/polynomial evaluation, monotone scalar functions on an
  interval, rounding to k places.

**Identifiability caveat (forced by the data):** all three measured inputs are
Sym=1. There is **no Sym=2 measurement**, so any factor `f(Sym)` is
unidentifiable from this data — only its Sym=1 value is observed. No `a` in
`σ(a·Sym)` can be fit. This is stated up front because §D depends on it.

## B. Mechanism: why argmax can fail for Sym=1

At sampling temperature `T_s=0`, decoding is `token = argmax p(token | context)`.
For an input whose answer is neither memorized nor locally computable by the
forward pass, the next-token distribution concentrates on a confident but wrong
continuation; with no stochasticity the same wrong continuation is emitted every
trial.

The data both supports and **bounds** this:

- **Supports:** `I_10(20.0)` at `T_s=0` returns one deterministic wrong magnitude
  on 20/20 (older prompt) and 20/20 (sweep prompt) trials.
- **Bounds (counterexample):** digit-count of `1000000001119` is **Sym=1 yet 0%
  error, 100/100**. So Sym=1 is **not sufficient** for failure. The operative
  axis is *memorization / forward-pass computability*, of which Sym=1 is at most
  a necessary correlate. Any mechanism that predicts "Sym=1 ⇒ argmax fails" is
  refuted by the digit result.

## C. The "79× attractor" and the asymptotic claim

Claim under test: the T=0 output equals the large-argument asymptotic
`I_ν(x) ~ eˣ/√(2πx)`, and the 79× error is that asymptotic over the true value.

**The data rejects this.** With `x=20`:

| quantity | value | ratio to true (3,540,200.209) |
|---|---|---|
| `eˣ/√(2πx)` (asymptotic) | 43,279,746 | **12.23×** |
| observed modal output (sweep prompt) | 350,000,000 | **98.86×** |
| observed output (older prompt) | 281,571,662.8 | **79.54×** = `I₀(10)·10⁵` |

The asymptotic gives 12.23×, not 79× or 99×. The 79× factor is real
(output/true) but is **not** `asymptotic/true`. The observed attractors are a
round number (`3.5×10⁸`) and a misindexed/misscaled Bessel value
(`281,571,662.8 = I₀(10)×10⁵` exactly, ratio 1.000000). They are also
**prompt-dependent** (the two prompts give different deterministic T=0 outputs).
Therefore §C as a derivation from `eˣ/√(2πx)` does not hold; the honest statement
is: *the cold attractor is a confident artifact, not the asymptotic series tail.*

## D. Fit of E = (1−T)·σ(a·Sym) to the data

Here `T` is the **sampling temperature** axis `T_s ∈ {0,…,1}` (all LLM-direct, no
tool). The ansatz `E=(1−T)σ` predicts `E` is **maximal at low T** and **→0 as
T→1**.

Bessel `I_10(20)` relative error by temperature (`Z_BESSEL_TSWEEP.csv`):

| T_s | n | modal output | median E | mean E |
|---|---|---|---|---|
| 0.0 | 20 | 3.5e8 | 97.86 | 97.86 |
| 0.2 | 20 | 3.5e8 | 97.86 | 97.86 |
| 0.4 | 20 | 3.5e8 | 97.86 | 97.86 |
| 0.6 | 20 | 3.5e8 | 97.86 | 93.09 |
| 0.8 | 20 | 3.5e8 | 97.86 | 5.014e9 |
| 1.0 | 20 | 3.5e8 | 97.86 | 5.487e9 |

Regression of `E` on `(1−T)` (the form `E=(1−T)·k` predicts slope **> 0**):

- **Median E:** slope = **0**, `E ≡ 97.86` (flat). R² undefined (zero variance).
- **Mean E:** slope = **−6.07×10⁹** (intercept 4.78×10⁹), R² = 0.699 — but the
  slope is the **wrong sign**: error *rises* as T rises (high-T outliers), the
  opposite of `E=(1−T)σ`.

**Conclusion (D):** the equation `E=(1−T)σ(a·Sym)` is **falsified** on this data.
Median cold error is ~98× *independent of sampling temperature*; mean error only
*increases* toward T=1. Lowering or raising the sampling temperature does not
drive `E→0`. The single best stray sample (E=0.8995, value 355,686.8) is still
~10× low. `a` is unidentifiable (no Sym=2 contrast). No honest positive fit, R²,
or `a` can be reported for the proposed form.

The **only** path observed to give `E=0` is the categorical tool path
(`mpmath`, the original "T=1 = external computation"), which is a *discrete
switch*, not the `T_s→1` limit of the sampling temperature. The two "T"s are
different axes and must not be merged: the equation conflates them, and the
sweep is what exposes it.

## E. Conjecture — restated to what the data supports

Refuted / unsupported (do **not** carry forward):

- "Digit counting T=0 ≈ 50% error" — measured **0%** (100/100). Refuted.
- "E = (1−T)σ(a·Sym)" as a temperature law — refuted (§D).
- "Sym=1 ⇒ cold failure" universally — refuted by digits (§B).
- "79× = asymptotic/true" — refuted (§C).

Surviving honest claim (existence + tool necessity):

> **There exist unmemorized inputs (e.g. `I_10(20.0)`) for which cold LLM
> generation produces a confident, deterministic error of ~2 orders of magnitude
> that does NOT diminish at any sampling temperature `T_s∈[0,1]`, while an
> external deterministic tool yields 0% error. For such inputs, correctness
> requires external computation, not a temperature choice.**

Open / degenerate:

- `ζ(½+14.134725 i)`: model outputs |ζ|≈2.68; true |ζ|≈1.12×10⁻⁷ (the input sits
  on the first non-trivial zero). "E>10%" holds numerically (rel-err ~2×10⁷) but
  is **degenerate** — relative error divides by ~0. The honest reading is an
  absolute miss of ~2.68, i.e. the model does not detect the zero; it is not a
  clean confirmation of a relative-error law. A non-zero test point is needed.

### Reproduce
```bash
python3 z_protocol_full.py                       # 3 datasets (resumable, billed)
python3 -c "import mpmath as mp; mp.mp.dps=50; print(mp.besseli(10,20)); print(mp.zeta(mp.mpf('0.5')+mp.mpf('14.134725')*1j))"
```
