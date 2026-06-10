/-
================================================================
Towers / YM / Casimir  (Task #156 — file 1 of 6, Varadhan scaffolding)

**SU(3) Casimir quadratic lower bound** with explicit `k₀ = 0`:
for every highest weight `(m, n) : ℕ × ℕ`,
  `¾ · (m + n)² + 3 · (m + n)  ≤  C₂(m, n)`
where `C₂(m, n) = m² + n² + mn + 3m + 3n` is the SU(3) Casimir
eigenvalue already landed in `Towers/YM/ClusterExpansion.lean`
(re-exposed via `Towers/YM/PeterWeyl.lean` as
`Casimir_SU3_explicit`).

### Why this brick

Batch 19.1p-redux-a (`Towers/YM/PeterWeyl.lean` Brick 1) only
proved the **linear** bound `(m + n) ≤ C₂(m, n)`. That is strong
enough to dominate the summand by a product envelope (the
"Summable" result) but is **not** strong enough for the Gaussian
tail estimate `Σ poly(k) · exp(-t · C₂) ≤ C · t^{-d/2}` that
Varadhan-style heat-trace bounds need: the integral
`∫ x^p · exp(-t · x) dx` is `~ t^{-(p+1)}` (polynomial), while
`∫ x^p · exp(-t · x²) dx` is `~ t^{-(p+1)/2}` (Gaussian, which
is what gives the `t^{-4}` scaling for SU(3) with `d = 8`).

So the quadratic bound below is the **arithmetic** input that
later files in the Task #156 chain will integrate against. It is
trivial (one application of `(m - n)² ≥ 0`), but it has to land
as a named brick so downstream files can `apply` it without
reopening the algebra.

### Honest scope (locked)

This file ships **one brick** and nothing else:

  * `Casimir_SU3_explicit_real_ge_quadratic`
        `(3/4 : ℝ) * ((m : ℝ) + n)^2 + 3 * ((m : ℝ) + n)
            ≤ (Casimir_SU3_explicit (m, n) : ℝ)`
    with `k₀ = 0` (the bound holds for **all** `(m, n) : ℕ × ℕ`,
    not just sufficiently large; no threshold needed).

This file does NOT ship — and the YM tower stays `Status: Open`
in `docs/ROADMAP.md` § 2 until ALL of the following also land
with trio-clean axiom footprints:

  2. `Towers/YM/WeylDim.lean`         — `dim(m,n) ≤ (m+n+1)³`
  3. `Towers/YM/HeatTraceBound.lean`  — `K(t) ≤ C · t^{-4}`
                                        (heat-trace polynomial,
                                        not Varadhan shape)
  4. `Towers/YM/OffDiagKernel.lean`   — `K_t(g, e)` def +
                                        bi-invariant metric
                                        `d_{SU(3)}(g, e)`
                                        (requires defining the
                                        SU(3) Riemannian metric
                                        via the Killing form;
                                        not in mathlib v4.12.0
                                        out of the box)
  5. `Towers/YM/Varadhan.lean`        — integrated tail
                                        `∫_{d(g,e)≥δ} K_t(g,e) dg
                                            ≤ C · t^{-4} · e^{-cδ²/t}`
  6. `Towers/Attempts/ClusterExpansion.lean`
                                      — wiring to KP /
                                        `plaquette_activity_pw`

In particular, **`Surface #2` stays OPEN** (4 open-gap blocks in
`docs/Surface2_ResearchProgram.tex`, `kotecky_preiss_criterion`
remains a `sorry` in `Towers/Attempts/ClusterExpansion.lean`).
Landing this brick is one ℕ→ℝ algebraic inequality; it does not
discharge Varadhan, the per-plaquette activity bound, KP, the
cluster expansion, the area law, or the mass gap.

================================================================
-/

import Towers.YM.PeterWeyl
import Mathlib.Tactic.Linarith

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Casimir

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl

/-! ## Brick — Casimir quadratic lower bound (k₀ = 0) -/

/-- **Quadratic lower bound on the explicit SU(3) Casimir.**
For every highest weight `(m, n) : ℕ × ℕ`,
`¾ · (m + n)² + 3 · (m + n)  ≤  C₂(m, n)`.

Proof: `4 · C₂ − 3(m+n)² − 12(m+n)
     = 4(m² + n² + mn + 3m + 3n) − 3(m² + 2mn + n²) − 12(m + n)
     = m² − 2mn + n² = (m − n)² ≥ 0`,
hence `C₂ ≥ ¾(m+n)² + 3(m+n)`. Closed by `nlinarith` with
`sq_nonneg ((m : ℝ) - n)` after `unfold + push_cast`.

The threshold is `k₀ = 0`: the bound holds for **all** `(m, n)`,
not just sufficiently large `m + n`. This is stronger than the
linear bound `(m + n) ≤ C₂` from `Towers.YM.PeterWeyl` Brick 1
(`Casimir_SU3_explicit_real_ge_linear`); both coexist, the linear
form being what `PeterWeyl_Summable_SU3` consumes today and the
quadratic form being what file 3 (`Towers/YM/HeatTraceBound.lean`)
will consume once it lands.

Honest scope: this is one arithmetic inequality. It is NOT the
Varadhan asymptotic, NOT a heat-trace bound, NOT a per-plaquette
activity bound, NOT KP, NOT a mass gap. -/
theorem Casimir_SU3_explicit_real_ge_quadratic (mn : Weyl_label) :
    (3 / 4 : ℝ) * ((mn.1 : ℝ) + mn.2) ^ 2 + 3 * ((mn.1 : ℝ) + mn.2)
      ≤ (Casimir_SU3_explicit mn : ℝ) := by
  unfold Casimir_SU3_explicit
  push_cast
  nlinarith [sq_nonneg ((mn.1 : ℝ) - mn.2),
             sq_nonneg ((mn.1 : ℝ)), sq_nonneg ((mn.2 : ℝ))]

end Casimir
end YM
end Towers
end TheoremaAureum
