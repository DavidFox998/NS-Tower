/-
  # Towers.RH.ZeroDensity

  **This file does NOT prove the Riemann Hypothesis, GRH, or any
  zero-density estimate.** It establishes the trivial monotonicity
  brick that any real zero-density argument needs, and pins the
  *statement* of the Riemann–von Mangoldt zero-counting formula as
  a future target.

  Status (cf. `docs/ROADMAP.md` § 1. Riemann Hypothesis):

  - `zerosBox σ T`             — definition of the rectangle of nontrivial
                                  zeros of `riemannZeta` in `[σ, 1] × [0, T]`.
  - `N σ T`                    — cardinality of `zerosBox σ T`.
  - `zerosBox_subset`          — trivial set-inclusion lemma.
  - `N_monotone_in_sigma`      — trivial subset-cardinality lemma, **proved**.
                                  Conditional on a finiteness hypothesis
                                  (`(zerosBox σ₁ T).Finite`) which is exactly
                                  the Riemann–von Mangoldt-adjacent finiteness
                                  fact not yet in mathlib. Axiom footprint =
                                  subset of mathlib's classical core
                                  `{propext, Classical.choice, Quot.sound}`,
                                  no research-grade axioms. (Verified by
                                  `scripts/check-towers.sh`.)
  - `RiemannVonMangoldt_setCounting_statement` — **statement only.**
                                     No proof. The *set-counting* (i.e.
                                     multiplicity-free) variant of the
                                     classical Riemann–von Mangoldt formula.
                                     Closing it — or its multiplicity-aware
                                     analogue — is open mathlib-scale work.

  Imports the real `riemannZeta` from mathlib v4.12.0 so the
  statements actually mention the analytic object, not a `Prop := True`
  placeholder. The existing tautological
  `TheoremaAureum.RiemannHypothesis : Prop := True` in
  `lean-proof/TheoremaAureum/Certificates.lean` is deliberately
  untouched; this file lives in a fresh `TheoremaAureum.Towers.RH`
  namespace so there is no name collision and no implicit
  relabelling of a tautology as a theorem.

  **Honesty note on the finiteness hypothesis.** The classical
  Riemann–von Mangoldt theorem (Titchmarsh §9.4) gives, in
  particular, that `zerosBox 0 T` is finite for every `T`. That
  statement is *itself* not yet formalised in mathlib v4.12.0,
  which is why the monotonicity lemma below takes finiteness as a
  hypothesis rather than discharging it. Closing
  `RiemannVonMangoldt_statement` below would automatically supply
  this hypothesis for `σ = 0` (and, via the subset lemma, for all
  `σ ≥ 0`).
-/

import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.Data.Set.Card

namespace TheoremaAureum
namespace Towers
namespace RH

open Set Complex

/-- The set of nontrivial zeros of `riemannZeta` inside the rectangle
    `[σ, 1] × [0, T]` in the critical strip.

    "Nontrivial" here is encoded as `ρ ≠ 1` (the pole). For a
    counting function targeted at `σ ∈ [0, 1]`, the well-known
    trivial zeros at negative even integers are already excluded by
    `σ ≤ ρ.re`. -/
def zerosBox (σ T : ℝ) : Set ℂ :=
  { ρ | riemannZeta ρ = 0 ∧ ρ ≠ 1 ∧ σ ≤ ρ.re ∧ ρ.re ≤ 1 ∧ 0 ≤ ρ.im ∧ ρ.im ≤ T }

/-- The strip-counting function `N(σ, T)`: the (natural-number)
    cardinality of `zerosBox σ T`.

    Uses `Set.ncard`, which returns `0` on infinite sets. The
    classical Riemann–von Mangoldt theorem implies `zerosBox σ T`
    is finite for all `σ ∈ [0, 1]` and `T ≥ 0`, but that fact is
    not yet in mathlib v4.12.0 and is therefore not used here. -/
noncomputable def N (σ T : ℝ) : ℕ := (zerosBox σ T).ncard

/-- Subset relation between strip-zero sets: raising the left edge
    `σ` upward can only *remove* zeros from the rectangle. -/
lemma zerosBox_subset {σ₁ σ₂ : ℝ} (h : σ₁ ≤ σ₂) (T : ℝ) :
    zerosBox σ₂ T ⊆ zerosBox σ₁ T := by
  intro ρ hρ
  obtain ⟨hzero, hne, hσ, hone, him0, himT⟩ := hρ
  exact ⟨hzero, hne, le_trans h hσ, hone, him0, himT⟩

/-- **Monotonicity of the strip-counting function (conditional).**

    For `σ₁ ≤ σ₂` and any `T`, *assuming* the larger box
    `[σ₁, 1] × [0, T]` contains only finitely many zeros, the
    smaller box `[σ₂, 1] × [0, T]` contains at most as many.

    The finiteness hypothesis is **not** discharged here — it is the
    Riemann–von Mangoldt fact that is itself an open mathlib-scale
    formalisation target (see `RiemannVonMangoldt_statement`).
    Conditioning on it explicitly is the honest move; it keeps the
    axiom debt of this lemma at `[]`. -/
theorem N_monotone_in_sigma {σ₁ σ₂ : ℝ} (h : σ₁ ≤ σ₂) (T : ℝ)
    (hfin : (zerosBox σ₁ T).Finite) :
    N σ₂ T ≤ N σ₁ T :=
  Set.ncard_le_ncard (zerosBox_subset h T) hfin

/-- **Statement** of the *set-counting* analogue of the Riemann–von
    Mangoldt zero-counting formula.

    Classical form (see e.g. Titchmarsh, *Theory of the Riemann
    Zeta-Function*, §9.4): there exists a constant `C > 0` such that
    for all `T ≥ 2`,

      `|N(0, T) − (T / 2π) · log(T / 2π) + T / 2π| ≤ C · log T`.

    **Honest deviation from Titchmarsh.** Our `N σ T` is
    `Set.ncard (zerosBox σ T)` — it counts *distinct* zeros and ignores
    multiplicity. The classical statement counts zeros with multiplicity
    (well-defined because the nontrivial zeros are isolated). Under
    the (also classical, also open in mathlib) fact that all nontrivial
    zeros in the rectangle are simple, the two statements coincide; we
    do not assume that here. The constant `C` is required to be
    strictly positive, matching the classical statement.

    **Statement only. Do NOT close with `True.intro`, `trivial`,
    `sorry`, or any tautology.** Proving this — or its multiplicity-
    aware analogue — is an open mathlib-scale project, and is the
    natural successor goal to this file. -/
def RiemannVonMangoldt_setCounting_statement : Prop :=
  ∃ C : ℝ, 0 < C ∧ ∀ T : ℝ, 2 ≤ T →
    |((N 0 T : ℝ)) - (T / (2 * Real.pi)) * Real.log (T / (2 * Real.pi))
        + T / (2 * Real.pi)|
      ≤ C * Real.log T

end RH
end Towers
end TheoremaAureum
