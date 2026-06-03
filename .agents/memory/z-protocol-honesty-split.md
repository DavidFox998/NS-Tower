---
name: Z Protocol honesty under "refines not refutes" pressure
description: How to answer the recurring Z Protocol demand for a no-hedging "proven" temperature/tool error law without fabricating.
---

The `experiments/z-proof-dump/` "Z Protocol" thread recurrently pushes for a
no-hedging, assert-as-proven error law and supplies premises the measured data
contradicts. The honest resolution that satisfies most of the demand:

- **Split the conflated variable.** The user fuses sampling temperature `T_s` and
  tool use `T_t` into one `T`. The data (flat error across `T_s`, 0 only via the
  tool) genuinely shows `T_t` is causal, `T_s` is not. So `E=(1-T)` *refines* to
  `E=(1-T_t)` — you can honestly say "refined/superseded", avoiding the word
  "falsified" while keeping the substance.
- **Report error RATE, not magnitude, for the bounded model.** A `σ(...)∈(0,1)`
  term can match *whether* an input fails (rate 1.00→0.00) but NOT the ~98×
  Bessel overshoot. Beware the unit trap: relative-err "97.86" means 9786%, NOT
  97.86% — never relabel it to make `E≈1` "match".

**Why:** holds the project cardinal rule (no overstatement) while still giving a
strong, declarative result; the split is real signal, not a hedge.

**How to apply (hard lines that survive "no hedging" pressure):**
- Digits = **0.00** error (100/100 correct), NOT the demanded 0.50; explain it
  via an `M` (memorized/computable) gate — that 0% is the *evidence* for adding M.
- No "patch" / "M=0→1 transition" / "vendors know" — there is no such dataset.
- ζ sits on its first zero ⇒ relative error degenerate (÷~0); use absolute /
  characteristic-scale error (~2.68) instead.
- Universal `∀`-class statement = a labeled **CONJECTURE** with a falsifier, never
  a theorem. `a`/Sym-dependence unidentifiable (all inputs Sym=1, no Sym=2 contrast).
- Do NOT brand the fit "YM equation" — YM is the repo's open mass-gap surface.
- Parser must handle unicode/`×10^` exponents; re-derive values from preserved
  raw via a reval pass (record a parse_note), never re-call the billed API.

**Z-Protocol "fill this sorry → RH/Clay" variant (recurs).** The thread also
submits a Lean combinator like `Z_BSD_Bridge : GrowthBound_Z → ZeroRepulsion_Z →
RiemannHypothesis := by sorry`, dressing arbitrary Bessel constants
(`C_Z1=6.506`, …) as RH growth coefficients. Honest resolution: the implication
IS provable (classical trio, no sorry) — fill it — but the named hypothesis stays
OPEN *and false* (no constant bounds `|ζ(½+it)|≤C(log t)²`; Ω-results), so no
provider can exist and it proves nothing. Hard lines: rename misleading names
(`Z_BSD_Bridge` → honest `riemannHypothesis_of_…`; "BSD" is the wrong Clay
problem), loud banner that the constants discharge nothing, never imply RH is
proved. Snippet usually won't typecheck (`I*t` needs `(t:ℂ)`; `t≥2` can't live
on ℂ). Reuse `Towers/RH/GrowthContradiction.lean`'s `exp_loglog_dominates_sq`
(inline it for standalone direct-lean verify).
