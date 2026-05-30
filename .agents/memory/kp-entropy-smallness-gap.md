---
name: KP cluster-expansion entropy/smallness gap
description: why the single-plaquette smallness surrogate cannot honestly yield unconditional KP convergence in the YM tower
---

# Kotecký–Preiss convergence: the entropy vs. smallness gap

The genuine KP polymer sum `∑_π |activity π|` is organised by size:
`∑_n (#{size-n polymers}) · (per-polymer activity)`. The polymer multiplicity
(entropy) grows like `(2d−1)^n = 7^n` on the 4d lattice (cf.
`EntropyBound.polymer_const = 7`). A geometric majorant
`∑_n (7 · activity)^n` converges ONLY if per-polymer activity `< 1/7`.

The single-plaquette smallness surrogate (`Wall252.kp_sum_lt_half`) gives only
`KP_sum β g < 1/2`, NOT `< 1/7`. So:

- A pure geometric series in `r = KP_sum` over sizes `n` (`∑_n r^n`) DOES
  converge (`r < 1`), but it is a SIZE-series majorant with multiplicity
  DROPPED — it is NOT the genuine polymer-index sum.
- The entropy-weighted sum `∑_n (7·r)^n` is NOT shown to converge from this
  smallness (`7·(1/2) = 3.5 > 1`).

**Why:** this is exactly the genuine open content behind the invariant-locked
`kotecky_preiss_criterion` sorry — proving the weighted-summability surface
(tree-graph / Ursell bounds + entropy control with multiplicity) is the real
work, absent from mathlib v4.12.0.

**How to apply:** when asked to "extend the KP bound / sum over all polymers",
the only honest deliverable is a CONDITIONAL combinator routing the hard step
through a NAMED open surface (a `Summable (...)` hypothesis, NOT `by sorry`),
plus genuine but explicitly-disclaimed size-series majorants. NEVER claim
unconditional KP convergence, a mass gap, μ>0, or that the Attempts/
`kotecky_preiss_criterion` sorry is discharged — these are REFUSED. YM stays
Status: Open until the entropy-weighted summability and OS positivity are done.
