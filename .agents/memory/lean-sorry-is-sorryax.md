---
name: Lean sorry == sorryAx (honesty-locked axiom audits)
description: Why a `theorem := by sorry` can never pass an axiom lock, and how to name an unproved analytic input without injecting an axiom.
---

In Lean 4, `sorry` IS the axiom `sorryAx` — they are literally the same term.
Any declaration proved (even partially) with `by sorry` will make
`#print axioms <decl>` report `sorryAx`. There is no flavor of `sorry` that
avoids the axiom, and relabeling the comment does nothing.

**Why this matters here:** the Morning Star repo is axiom-locked to the
classical trio `[propext, Classical.choice, Quot.sound]` only (Shawlock Rule
#1). A reviewer running `#print axioms` will REJECT any decl showing `sorryAx`,
even one you intended as an "accepted named sorry". "Max N sorries" and "0
axioms / no sorryAx" are contradictory demands for a *theorem* — you cannot
satisfy both with a sorry-backed proof.

**How to apply:** to NAME an unproved analytic input (e.g. integration by
parts / a divergence-theorem pairing missing from mathlib v4.12.0) WITHOUT
injecting an axiom:
- State it as a `Prop`-valued `def` (the statement, no proof obligation) —
  `#print axioms` then returns the trio only, no sorryAx; or
- Thread it as an explicit hypothesis on the theorem that consumes it (this is
  what `energy_inequality` does with its `hbal` balance hypothesis); or
- Actually prove it (only if genuinely feasible in-scope).
Never use `theorem foo := by sorry` in a file that must pass an axiom audit.
Keep the headline theorem independent of any sorry so its footprint stays trio.
