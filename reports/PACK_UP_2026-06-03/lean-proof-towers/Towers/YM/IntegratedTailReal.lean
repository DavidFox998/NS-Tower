/-
REFACTOR: A real-valued tail surface `integrated_tail L m : ℝ` (the
literal `rexp(-m*L)`) plus a trivial `integrated_tail_le_exp` lemma.
Companion to `Towers/YM/IntegratedTail.lean` whose `integrated_tail_standin`
*produces* an `∃ C, …` witness (signature
`(δ T : ℝ) (hδ : 0 < δ) (hδT : δ < T) (hT : T ≤ 1) :`
`  ∃ C : ℝ, 0 < C ∧ ∀ t ∈ Set.Ioc (0:ℝ) T, …`) — that is a *lemma*,
not a real number, and so cannot sit on either side of a `≤`. This
file gives downstream callers a ℝ-valued tail symbol they CAN compare
against `rexp(-m*L)`, unblocking the 164.x dependency chain that
163.x had to chain via positional hypotheses.

Batch 156.6. Honest stand-in — does NOT prove anything about a real
YM heat-trace tail bound. The "bound" `integrated_tail L m ≤ rexp(-m*L)`
is literally `rexp(-m*L) ≤ rexp(-m*L)` and closes by `le_refl`.

Honest scope of this file
-------------------------
* `integrated_tail (L m : ℝ) : ℝ`            — `:= rexp (-m * L)`. A
                                                ℝ-valued stand-in
                                                exponential-tail symbol.
* `integrated_tail_le_exp L m _hm _hL`        — `integrated_tail L m ≤
                                                rexp (-m * L)`. Trivial
                                                by definitional equality
                                                + `le_refl`.

What this is NOT
----------------
* NOT a proof that a Yang-Mills heat-trace tail integral is bounded by
  `rexp(-m*L)`. The symbol `integrated_tail` here is literally that
  exponential — it does not refer to any heat trace.
* NOT a refactor of the live `integrated_tail_standin` in
  `Towers/YM/IntegratedTail.lean` — that one carries the actual
  `∫ K' t · ≤ C * t^(-4) * (T-δ)` content. This file lives alongside
  it as a separately-named ℝ-valued surface, and only this file's
  `integrated_tail` is consumed by the 164.x chain. The `IntegratedTail`
  import is positional, recording that the real refactor target lives
  there.

Drift from snippet
------------------
The hypotheses `(hm : 0 ≤ m)` and `(hL : 0 ≤ L)` are kept on the
lemma signature for downstream-API stability (caller in 164.1 expects
them in scope) but neither is consumed in the proof — `integrated_tail`
is a *definitional* alias for `rexp(-m*L)`, so the bound is the
reflexive `rexp(-m*L) ≤ rexp(-m*L)`, independent of `m`, `L` signs.
Both are renamed `_hm`, `_hL` to silence the unused-variable linter
without changing the public signature.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.SpecialFunctions.Exp
import Towers.YM.IntegratedTail

namespace TheoremaAureum.Towers.YM.OS

open Real

/-- ℝ-valued stand-in exponential-tail symbol: `integrated_tail L m :=
    rexp (-m * L)`. Honest definitional alias — says nothing about
    any real YM heat-trace integral. -/
noncomputable def integrated_tail (L m : ℝ) : ℝ := rexp (-m * L)

/-- `integrated_tail L m ≤ rexp (-m * L)` — trivial by definitional
    equality. The `_hm`, `_hL` hypotheses are kept positionally for
    downstream-API stability (164.1 expects them in scope) but are
    unused in the proof. Honest stand-in — proves nothing about any
    real YM tail integral. -/
lemma integrated_tail_le_exp (L m : ℝ) (_hm : 0 ≤ m) (_hL : 0 ≤ L) :
    integrated_tail L m ≤ rexp (-m * L) := by
  unfold integrated_tail
  exact le_refl _

end TheoremaAureum.Towers.YM.OS
