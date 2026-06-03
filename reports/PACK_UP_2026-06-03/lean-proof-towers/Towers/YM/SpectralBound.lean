/-
STAND-IN: Generic utility — for any bounded operator `T : H →L[ℂ] H`
on a complex Banach space, `spectralRadius ℂ T ≤ ‖T‖`. (This is the
standard Gelfand-style bound from mathlib's spectral theory.)

Honest scope (locked)
---------------------
* This is a *generic* spectral-radius bound, NOT a statement about
  any Yang-Mills transfer operator. The `‖T‖ ≤ 1` hypothesis from the
  snippet is unused — the underlying mathlib lemma
  `spectralRadius_le_nnnorm` gives `spectralRadius ≤ ‖T‖₊` directly
  (which is ≤ `1` only when `‖T‖ ≤ 1`). We expose the unconditional
  version `spectralRadius ℂ T ≤ ‖T‖₊` here and let downstream callers
  chain through `h : ‖T‖ ≤ 1` separately.
* Does **NOT** prove the YM transfer operator is bounded or has
  bounded spectrum. Surface #1 stays OPEN.

Drift from snippet
------------------
(1) Snippet's import `Mathlib.Analysis.NormedSpace.Spectrum` does not
    exist under that name in mathlib v4.12.0 — that module path was a
    pre-rename location. In v4.12.0 the `spectralRadius` API (including
    `spectralRadius_le_nnnorm`) lives in
    `Mathlib.Analysis.Normed.Algebra.Spectrum`, which is the module we
    import here (matching `Towers/YM/TransferOperator.lean`). The old
    `NormedSpace.Spectrum` path only ever resolved against a stale
    cached olean, so this brick built standalone but broke a full
    `lake build Towers` replay against the real v4.12.0 source tree
    (Task #208).
(2) Snippet wrote `spectralRadius_le_opNorm` — that constant does
    not exist in mathlib v4.12.0. The library lemma is
    `spectralRadius_le_nnnorm : spectralRadius 𝕜 a ≤ ‖a‖₊`.
(3) Snippet's conclusion `spectralRadius ℂ T ≤ 1` requires the
    `h : ‖T‖ ≤ 1` hypothesis to chain. We keep the snippet's
    public signature verbatim and discharge by
    `le_trans (spectralRadius_le_nnnorm T) (by exact_mod_cast h)`.

Axiom footprint
---------------
Should depend only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
-/

import Mathlib.Analysis.NormedSpace.OperatorNorm.NormedSpace
import Mathlib.Analysis.Normed.Algebra.Spectrum

namespace TheoremaAureum.Towers.YM.OS

open ContinuousLinearMap

/-- For a bounded operator `T : H →L[ℂ] H` on a complex Banach space,
    `‖T‖ ≤ 1` implies `spectralRadius ℂ T ≤ 1`. Generic utility,
    not a YM-specific bound. -/
theorem spectral_bound {H : Type*}
    [NormedAddCommGroup H] [NormedSpace ℂ H] [CompleteSpace H] [Nontrivial H]
    (T : H →L[ℂ] H) (h : ‖T‖ ≤ 1) : spectralRadius ℂ T ≤ 1 := by
  have hsr : spectralRadius ℂ T ≤ ‖T‖₊ := spectrum.spectralRadius_le_nnnorm T
  exact le_trans hsr (by exact_mod_cast h)

end TheoremaAureum.Towers.YM.OS
