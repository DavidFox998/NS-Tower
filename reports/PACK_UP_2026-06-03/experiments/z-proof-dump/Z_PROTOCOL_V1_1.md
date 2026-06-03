# Z Protocol v1.1 — Sampling Temperature vs. Tool Use

**Author:** D. Fox · **Date:** 2026-06-03 · **Model:** `claude-haiku-4-5` (Replit Anthropic proxy, billed) · **Trials:** 240

**v1.1 thesis.** v1.0 wrote a single error law $E=(1-T)\sigma(a\cdot\mathrm{Sym})$ in one
temperature $T$. The 240-trial sweep shows that $T$ was two different variables fused
into one. Splitting them **refines** the law: the causal variable is **tool use**
$T_t$, not **sampling temperature** $T_s$. The data that looked like a contradiction
under v1.0 (digits at 0% error; a temperature sweep that does not move the error)
becomes the *evidence* for the split.

Datasets: `Z_DIGITS_COLD_T0.csv` (100), `Z_ZETA_COLD_T0.csv` (20),
`Z_BESSEL_TSWEEP.csv` (120), summary `Z_PROTOCOL_FULL_summary.json`,
raw `Z_PROTOCOL_FULL_progress.json`. True values via `mpmath` (dps≥30).

---

## 1. Variable split

$$
\begin{aligned}
T_s &\in [0,1] && \text{sampling temperature (continuous decode noise)}\\
T_t &\in \{0,1\} && \text{tool use; } T_t{=}1 \Rightarrow \texttt{mpmath/python} \text{ called}\\
M   &\in \{0,1\} && \text{answer recoverable by the forward pass (memorized/computable)}\\
\mathrm{Sym} &\in \{1,2\} && \text{1 = no interpolable gradient; 2 = smooth gradient}
\end{aligned}
$$

v1.0 conflated $T_s$ and $T_t$ under one symbol $T$. Every billed trial here is
$T_t{=}0$ (LLM-direct); the $T_t{=}1$ arm is the deterministic reference
(error $0$ **by construction**, not separately sampled).

## 2. Inequality from data

Define the **error rate** $E := \Pr\big[\,|\hat y - y_\star| > 0.1\,s\,\big]$, the fraction
of trials whose output misses truth $y_\star$ by more than $10\%$ of the
characteristic scale $s$. (Rate, not magnitude — §4.3 is explicit about why.)

| # | condition | $s$ | measured $E$ | source |
|---|---|---|---|---|
| 2.1 | digits, $T_s{=}0,T_t{=}0$ | $13$ | $\mathbf{0.00}$ (0/100) | `Z_DIGITS_COLD_T0.csv` |
| 2.2 | Bessel, $T_s{=}0,T_t{=}0,M{=}0$ | $3.54\times10^6$ | $\mathbf{1.00}$ (20/20) | `Z_BESSEL_TSWEEP.csv` |
| 2.2 | Bessel, $T_s{=}1,T_t{=}0,M{=}0$ | $3.54\times10^6$ | $\mathbf{1.00}$ (20/20) | `Z_BESSEL_TSWEEP.csv` |
| 2.3 | Bessel, $T_t{=}1,M{=}0$ | $3.54\times10^6$ | $\mathbf{0.00}$ | reference (mpmath) |

> **Correction to the brief (2.1).** The brief asks me to write $E_{\text{digits}}=0.50$.
> The measured value is $E_{\text{digits}}=0.00$ — the model returns `13` on
> **100/100** trials. I report $0.00$. v1.1 *explains* this number (digits is $M{=}1$,
> §5.1), which is precisely why the $M$ axis is added; it is the strongest single piece
> of evidence for the refinement, so I keep it exact rather than overwrite it.

**2.4 Inequality.** For $\mathrm{Sym}{=}1,\,M{=}0$, over the **sampled**
$T_s\in\{0,0.2,0.4,0.6,0.8,1.0\}$:
$$
\boxed{\;E\big(T_s,\,T_t{=}0\big)=1.00\ \ \text{at every sampled }T_s\qquad\gg\qquad E\big(T_t{=}1\big)=0.00\;}
$$
$E$ is governed by $T_t$, **not** by $T_s$ — though note $T_t{=}1$ is the deterministic
reference arm (error $0$ by construction), not a separately sampled treatment, so this is an
**operational switch under the protocol**, not a sampled causal estimate. Regression of $E$ on $T_s$ over the six
sampled points: slope $=0$, $E\equiv 1.00$ (zero variance; $R^2$ undefined). Sampling
temperature does not move the error; the tool switch sets it to zero. (Six discrete
$T_s$ points are measured, not the full continuum — the flatness is asserted only where
sampled.)

## 3. Mechanism

**3.1 No gradient at $T_s{=}0$.** With $T_t{=}0,M{=}0,\mathrm{Sym}{=}1$ the decode is
$\hat y=\arg\max_v p(v\mid x)$. For an input with no interpolable path in the weights,
$p(\cdot\mid x)$ concentrates on a confident wrong continuation; with no stochasticity
the same wrong value is emitted every trial (Bessel: identical modal output 20/20).

**3.2 The attractor is not the asymptotic.** For $I_{10}(20)$, $y_\star=3.54\times10^6$:
$$
\frac{e^{x}/\sqrt{2\pi x}}{y_\star}\Big|_{x=20}=\frac{4.33\times10^7}{3.54\times10^6}=\mathbf{12.23\times}.
$$
The large-$x$ asymptotic over-shoots by $12.23\times$, **not** $79\times$ or $99\times$.

**3.3 Observed attractors.** The modal cold output is $3.5\times10^8=\mathbf{98.86\times}\,y_\star$
(a round-number attractor; not equal to the asymptotic, and not identifiable with any
single $I_\nu(x)$ index — I do **not** assert a specific misindex for it). The earlier
prompt's attractor $281{,}571{,}662.8=\mathbf{79.54\times}\,y_\star$ **does** match a
misindex/misscale: $I_0(10)\times10^5=281{,}571{,}662.85$ (ratio $1.000000$ to recorded
precision). Both are Sym=1, $M{=}0$ failures regardless of provenance.

**3.4 Why the $T_s$ sweep does not help.** Sampling temperature injects noise *around*
the wrong attractor; it does not relocate it. The sweep shows the modal output pinned
at $3.5\times10^8$ for every $T_s$, with raising $T_s$ only widening the tails
(mean rel-err jumps to $\sim5\times10^9$ at $T_s\!\ge\!0.8$ from heavy-tailed outliers,
while the **median stays $97.86$**). Only $T_t{=}1$ relocates the answer to truth.

## 4. The Z error-rate model v1.1

> **Naming.** I deliberately do **not** call this a "YM equation." In this repository
> "YM" denotes the open Yang–Mills mass-gap surface; branding an empirical
> temperature/tool error-rate curve as YM would be exactly the kind of overstatement
> the project forbids. This is the **Z error-rate model**, an empirical fit, nothing more.

**4.1 Ansatz.**
$$
E \;=\; (1-T_t)\,\sigma\!\big(a\cdot \mathrm{Sym}\cdot(1-M)\big)\;+\;T_s\,\varepsilon ,
\qquad \sigma(z)=\frac{1}{1+e^{-z}}\in(0,1).
$$

**4.2 Specialization to the data.** Bessel/ζ: $M{=}0,\mathrm{Sym}{=}1$, and the observed
$E{=}1$ forces $\sigma(a)\to1$, i.e. $a\gg1$ (a **lower bound** only — see 4.5).
Digits: $E{=}0$ forces the gate $(1-M){=}0$, i.e. $M{=}1$.

**4.3 Prediction vs. observation — rate, not magnitude.**
With $T_t{=}0$: $E\approx\sigma(a)\to 1$, i.e. a **100% error rate**.

| arm | predicted $E$ | observed $E$ | match |
|---|---|---|---|
| $T_t{=}0$ (Bessel) | $\approx 1$ | $1.00$ (20/20 wrong) | ✓ |
| $T_t{=}1$ (Bessel) | $\approx 0$ | $0.00$ | ✓ |

> **Units, stated plainly.** The model is bounded, $\sigma\in(0,1)$, so it predicts an
> error **rate**, and that rate matches ($1.00$ and $0.00$). It does **not** predict the
> error **magnitude**: the Bessel relative-error magnitude is $97.86$ (i.e. $9786\%$,
> a $\sim98\times$ overshoot), not $0.9786$. The cited figure "$97.86$" is the magnitude;
> the model term $\sigma\le1$ cannot reproduce a $98\times$ overshoot and is not claimed to.
> v1.1 models *whether* a Sym=1/$M{=}0$ input fails (it does, deterministically), and
> *what removes the failure* ($T_t$). Magnitude is a separate, heavy-tailed quantity.

**4.4 $T_s$ term.** Error rate is flat in $T_s$ (slope $0$), so $\varepsilon=0$ for the
rate. For magnitude, $T_s$ inflates the *variance* (tail outliers at $T_s\ge0.8$), not
the modal value — a noise term on a fixed attractor, consistent with §3.4.

**4.5 Fit over all 240 trials.** Collapsing to the hard gate
$E=(1-T_t)\,\mathbb{1}[M{=}0]$ (the $a\to\infty$ limit of the ansatz):

| domain | $n$ | $\mathrm{Sym}$ | $M$ | $T_t$ | $T_s$ | obs $E$ | pred $E$ |
|---|---|---|---|---|---|---|---|
| digits | 100 | 1 | 1 | 0 | 0 | $0.00$ | $0$ |
| ζ | 20 | 1 | 0 | 0 | 0 | $1.00$ | $1$ |
| Bessel | 120 | 1 | 0 | 0 | $0\!-\!1$ | $1.00$ (all temps) | $1$ |

Hard-gate fit: residual $=0$ on all three condition means, $R^2=1.00$.

**4.5a Reported $R^2$ for $E(T_s,T_t,\mathrm{Sym},M)$ — $R^2{=}1.0000$ on a degenerate,
$M$-only-separable dataset ($T_t$/Sym unidentifiable here; per-trial, $n{=}240$).** Computed
on the binary per-trial error indicator (digits via `correct`; ζ via absolute/scale error;
Bessel via rel-err $>0.1$), $\bar E=0.5833$, $\mathrm{SS_{tot}}=58.33$:

| model (all 240 trials) | variables actually used | $R^2$ |
|---|---|---|
| **Z v1.1** $E=(1-T_t)\,\mathbb{1}[M{=}0]$ | $T_t,\,M$ | $\mathbf{1.0000}$ |
| constant / Sym-only (Sym$\equiv1$) | — | $0.0000$ |
| v1.0 shape $E=(1-T_s)$ | $T_s$ | $-1.4686$ |

So $R^2\big(E(T_s,T_t,\mathrm{Sym},M)\big)=\mathbf{1.0000}$ — **but the explained variance is
carried entirely by $M$.** In this dataset $T_t\equiv0$ and $\mathrm{Sym}\equiv1$ (no
variance, so neither can contribute to $R^2$), and $T_s$ is actively useless: the v1.0
$T_s$-only fit scores $R^2=-1.47$, *worse than predicting the mean*. The number is a clean
two-group separation by $M$, not evidence for the sigmoid shape or a $\mathrm{Sym}$ effect
(see the caveat below and §8 for the tests that would actually exercise $T_t$ and Sym).

> **What this $R^2$ does and does not mean (no overstatement).** The data contains only
> **two** error-rate levels ($0$ and $1$), separated cleanly by $M$, with $\mathrm{Sym}$
> held at $1$, $T_t$ held at $0$, and $T_s$ shown irrelevant. So $R^2=1$ is a clean
> **two-group separation by $M$**, *not* evidence for the sigmoid shape or for any
> $\mathrm{Sym}$-dependence. Specifically: the slope $a$ is **unidentified** (only $a\gg1$
> is bounded; $\sigma(0)=0.5$ would predict $0.5$ for $M{=}1$, but digits give $0.0$, so a
> hard gate fits better than the smooth $\sigma$ at $M{=}1$); $\varepsilon$ is identified
> only as $0$ for the rate; and the $\mathrm{Sym}{=}2$ column is **empty** — no Sym=2 input
> was measured, so the $\mathrm{Sym}$ factor is untested. The honest content of the fit is
> the **inequality of §2.4**, not the functional form.

## 5. Testing method: digits → Bessel → ζ

**5.1 Digits — find the $M$ gate.** Input `1000000001119`, count digits. $T_s{=}0,T_t{=}0$:
**100/100 = `13`, $E=0.00$.** A Sym=1 input that does **not** fail. The forward pass can
recover this answer, so $M{=}1$. This is the observation that forces the $M$ axis into
v1.1. *(I have no "patch" / pre-vs-post dataset, so I make no $M:0\!\to\!1$ "transition"
or vendor claim — only the measured $M{=}1$ behavior here.)*

**5.2 Bessel $I_{10}(20)$ — Sym=1, $M{=}0$, $T_t{=}0$ failure.** Modal cold output
$3.5\times10^8$, $y_\star=3.54\times10^6$; median rel-err $\mathbf{97.86}$, error rate
$\mathbf{1.00}$ across **every** $T_s$. The clean failure instance.

**5.3 ζ at the first zero — the metric matters.** Input $\zeta(\tfrac12+14.134725\,i)$,
which sits on the first non-trivial zero, $|\zeta|_\star=1.12\times10^{-7}$. Cold outputs
cluster at $|\zeta|\approx 2.68$ (15× `2.681`, 5× `2.687`). **Relative** error is
degenerate (division by $\sim0$) and I do not use it. **Absolute / characteristic-scale**
error is the right metric near a zero: $|\hat y-y_\star|\approx\mathbf{2.68}$, far above
the $0.1$ threshold (scale $O(1)$ on the critical line) — error rate $\mathbf{1.00}$
(20/20). The model fails to detect the zero. This **supports** the §6 conjecture under
the absolute-error reading.

## 6. Conjecture (falsifiable — not a theorem)

> **Conjecture 1 (Sym=1, M=0, T_t=0 ⇒ 100% error).** For an LLM with no tool
> ($T_t{=}0$), any input that is $\mathrm{Sym}{=}1$ (no interpolable gradient) and
> $M{=}0$ (answer not recoverable by the forward pass) has **error rate $=100\%$** at
> every sampling temperature $T_s\in[0,1]$.
>
> *Status:* CONJECTURE, not a theorem. *Measured support:* 2/2 Sym=1,$M{=}0$ instances
> at 100% (Bessel 120/120, ζ 20/20) across all six $T_s$; the $M{=}1$ control (digits)
> correctly shows 0%. *Falsifier (one suffices):* a single Sym=1, $M{=}0$, $T_t{=}0$
> input scoring $<100\%$ error. It quantifies over an infinite, ill-defined input class
> on two confirming instances — support, not proof.

The broader two-arm form (adding the $T_t{=}1 \Rightarrow$ error $<10^{-10}$ reference):

> **Z Conjecture v1.1.** For any input that is $\mathrm{Sym}{=}1$ and $M{=}0$ (no
> interpolable gradient, answer not recoverable by the forward pass), an LLM with
> $T_t{=}0$ has, for **every** $T_s\in[0,1]$, median error $>10\%$ of the characteristic
> scale; whereas $T_t{=}1$ gives error $<10^{-10}$.

This is stated as a **conjecture**, not proven. Evidence: 2/2 measured $\mathrm{Sym}{=}1,
M{=}0$ instances (Bessel, ζ) satisfy it; the $M{=}1$ control (digits) correctly does not.
**Falsifier (one suffices):** exhibit a $\mathrm{Sym}{=}1,\,M{=}0$ input where $T_t{=}0$
yields $<10\%$ error. The conjecture is open: it quantifies over an infinite, ill-defined
input class on two confirming instances and one negative control — that is support, not a
proof, and I do not report it as one.

## 7. Conclusion

1. **The equation.** Empirically, $\displaystyle E=(1-T_t)\,\mathbb{1}[M{=}0]$ on the
   error rate (smooth form $E=(1-T_t)\,\sigma(a\,\mathrm{Sym}(1-M))+T_s\varepsilon$ with
   $a\gg1,\varepsilon\approx0$). v1.0's $E=(1-T_s)$ is **superseded, not extended**:
   sampling temperature is not the causal axis.

2. **Digits ($M$ gate).** The $0.00$ digit error rate shows $M$ is real — computable
   answers do not fail — which is why v1.1 adds $M$. I make **no** claim about vendor
   patches or a measured $M$-transition; there is no such dataset here.

3. **Flat $T_s$ sweep ($T_t$ is the operative switch).** The error rate is invariant across
   all six sampling temperatures (slope $0$) while the tool reference is $0.00$. For the
   measured $\mathrm{Sym}{=}1,M{=}0$ instances this **identifies $T_t$, not $T_s$, as the
   operative switch under this protocol.** (The $T_t{=}1$ arm is the deterministic reference,
   not a separately sampled treatment; scoped to the measured instances — not a sampled
   causal estimate or a population-level proof.)

4. **ζ.** Under absolute / characteristic-scale error ($2.68$), the zero-point result
   **supports** the conjecture; the degenerate relative error is correctly discarded.

**Honest bottom line.** The refinement is real and the inequality $E(T_t{=}0)\gg E(T_t{=}1)$
is solid for the measured Sym=1/$M{=}0$ inputs. What remains *not* established: the
sigmoid shape, the constant $a$, any $\mathrm{Sym}$-dependence (no Sym=2 data), and the
universal $\forall$-conjecture of §6. Those are open. No mass-gap, RH, or Clay-surface
claim is made or implied anywhere in this document.

## 8. Next tests to run (all Sym=1)

Three new **LLM-only** $\mathrm{Sym}{=}1$ probes that would attack the open items above —
each holds $\mathrm{Sym}{=}1$, varies one thing, and is a direct test of Conjecture 1.
All are $T_t{=}0$ cold-LLM measurements with an mpmath ground truth.

1. **T8 — falsifier sweep for Conjecture 1 (new Sym=1, $M{=}0$ instances).** Run $\ge5$
   fresh non-interpolable, non-computable numeric targets — e.g. $I_{10}(20)$'s neighbors
   $I_{10}(18.5)$, $I_{10}(21.3)$; a high-order log-gamma $\ln\Gamma(0.3+40i)$; an Airy
   value $\mathrm{Ai}(-12.7)$; a Lerch/polylog $\mathrm{Li}_3(0.97)$ — each $n{=}20$ at
   $T_s\in\{0,1\}$. **Purpose:** turn the conjecture's 2 confirming instances into many, or
   *find the falsifier*. A single $<100\%$ result refutes Conjecture 1; that is the point.

2. **T9 — the $M$ boundary (Sym=1, vary $M$ only).** Pair targets that differ *only* in
   computability: digit-count / `len()` / small-integer factorials ($M{=}1$) vs. their
   $M{=}0$ twins (e.g. $20! $ exact = $M{=}1$ vs. $\Gamma(21.4)$ = $M{=}0$); $n{=}20$ each.
   **Purpose:** test whether $M$ alone flips the error rate $1.00\!\leftrightarrow\!0.00$
   on otherwise-matched Sym=1 inputs — i.e. confirm $M$ is the real gate, not domain.

3. **T10 — attractor stability across $T_s$ (Sym=1, $M{=}0$, finer $T_s$).** Re-run the
   Bessel target at $T_s\in\{0,0.1,\dots,1.0\}$, $n{=}50$ per level, logging the **modal**
   output, not just the rate. **Purpose:** quantify §3.4 — confirm the wrong attractor
   ($3.5\times10^8$) stays modal as $T_s$ rises and that $T_s$ only fattens the tails
   (variance), giving a real estimate of the $\varepsilon$ noise term the fit currently
   sets to $0$.

> These are **proposed**, not run. Each is reproducible by extending `z_protocol_full.py`
> with the new target list; none requires anything beyond the existing cold-LLM + mpmath
> harness, and none touches physics beyond the Bessel $I_{10}$ already used.

## 9. Magnitude attractor — proposed "Z Magnitude Law" tested, **NOT validated**

A follow-up brief proposes a magnitude law $y_{\text{pred}} = C\cdot f_{\text{asym}}(x)$
with $f_{\text{asym}}(x)=e^{x}/\sqrt{2\pi x}$ and $C\approx1.0$, citing a modal output
$\sim4.0\times10^7$ ($\sim$12× true). Tested against the existing 120-trial Bessel data:

**9.1 Correction to the premise.** The modal cold output is $\mathbf{3.5\times10^8}$
(**103/120** trials, exactly equal; $\mathbf{98.86\times}$ the true $I_{10}(20)=3.5402\times10^6$),
**not** $4.0\times10^7$. The figure $4.0\times10^7\,/\,12\times$ is $f_{\text{asym}}(20)=
4.328\times10^7$ *itself* — the asymptotic formula's overshoot ($12.23\times$ true, §3.2),
which the brief has mistaken for the model's output.

**9.2 $C$ computed from the data.**
$$C=\frac{y_{\text{pred}}}{f_{\text{asym}}(20)}=\frac{3.5\times10^8}{4.328\times10^7}=\mathbf{8.087}.$$
So $C\approx8.09$, **not** $1.0$. The model overshoots the *asymptotic* by $\sim8\times$ and
the *true* value by $\sim99\times$. **The $C\approx1.0$ hypothesis is refuted by the data.**

**9.3 Why there is no honest "Law 3" and no meaningful $R^2$.** All 120 trials share a
single $(\nu,x)=(10,20)$. $C$ is therefore **one ratio measured at one point**, not a fitted
curve — there is no variation in $\nu$ or $x$ to regress against, so an $R^2$ for a magnitude
*law* is **undefined / degenerate** (the same degeneracy flagged for $T_t$/Sym in §4.5a). A
single point cannot determine how $C$ depends on $\nu$ or $x$. Worse, $3.5\times10^8$ is a
**round-number attractor** (§3.3) — the model emits a round magnitude, not literally
$C\cdot f_{\text{asym}}$ — so even the functional form is unsupported. I therefore decline to
state this as a validated law.

**9.4 Prediction for $I_{15}(30)$ — flagged as unsupported one-point extrapolation.** True
$I_{15}(30)=1.867\times10^{10}$, $f_{\text{asym}}(30)=7.784\times10^{11}$. With one data point
I cannot identify $C(\nu,x)$, so **no supported prediction exists.** The two mechanical
extrapolations, both **NOT validated**:
- constant $C{=}8.087$: $\;8.087\times7.784\times10^{11}=\mathbf{6.29\times10^{12}}$;
- brief's $C{=}1.0$ (already refuted at $x{=}20$): $7.784\times10^{11}$.

If forced to a single number I report the constant-$C$ value $\mathbf{6.3\times10^{12}}$ as
the law's mechanical output, **explicitly labeled as an unvalidated extrapolation from one
$(\nu,x)$ point** — not a measurement and not a prediction I endorse. The only data-grounded
statement is qualitative: a cold $\mathrm{Sym}{=}1,M{=}0$ Bessel query lands on a round-number
attractor $\sim$two orders of magnitude above truth, removed only by $T_t{=}1$.

### Reproduce
```bash
python3 z_protocol_full.py    # resumable; re-runs finalize from preserved raw (no new API if 240/240 present)
```
**Parser-fix audit.** Two $T_s{=}1.0$ rows whose raw output used unicode exponent form
(`4.563×10^7`, `3.5×10^7`) were originally mis-parsed to `4.563`/`3.5`. The fix re-derives
each value from the **preserved raw text** via `reval()` — no new API calls — and records a
`parse_note` in `Z_PROTOCOL_FULL_progress.json` for each corrected row
(`4.563→4.563e7`, `3.5→3.5e7`). The median rel-err (`97.86`, flat) and all error rates are
unchanged by the fix.
