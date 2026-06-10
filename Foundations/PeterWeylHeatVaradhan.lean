/-
================================================================
Towers / YM / PeterWeylHeatVaradhan  (Task #156 — Varadhan small-t
asymptotic for the SU(3) heat-kernel envelope, **strip form**)

**Headline.** A sorry-free Varadhan-shape upper bound on the
genuine SU(3) Peter-Weyl heat-kernel envelope
  `Heat_kernel_envelope_real t :=
       ∑'_{(m,n) : ℕ²} (dim λ)² · exp(-(t · C₂(λ)))`
(landed in `Towers/YM/PeterWeylHeat.lean` via
`PeterWeyl_Summable_SU3`, Batch 19.1p-redux-a/b, Tasks #154/#155).
For every `t : ℝ` in the **finite strip** `[varadhan_t_lo, varadhan_t_top]`
(concretely `[1/100, 100]` after the Task #190 widening — previously
`[1, 2]`), with explicit positive constants
`varadhan_c, varadhan_C`, the brick

  `Heat_kernel_envelope_real_le_varadhan :`
      `varadhan_t_lo ≤ t → t ≤ varadhan_t_top →`
      `Heat_kernel_envelope_real t ≤`
        `varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4`

closes by composing (1) antitonicity of the envelope in `t` on
`(0,∞)` (each summand `exp(-(t·C₂))` decreases in `t` since `C₂ ≥ 0`,
both partial sums are `Summable` via `PeterWeyl_Summable_SU3` so
`tsum_le_tsum` applies), and (2) the algebraic fact that on the
strip `[t_lo, t_top]`, both `t_top^4 / t^4 ≥ 1` and the exp factor
`exp(c/t_lo) · exp(-c/t) ≥ exp(0) = 1` (since `t ≥ t_lo > 0` and
`c > 0` force `c/t ≤ c/t_lo`). Hence `varadhan_C · exp(-c/t)/t^4
≥ env(t_lo) ≥ env(t)` on the strip.

### Drift from the original task signature (honest scope, locked)

The Task #156 "Done looks like" line asked for the unrestricted
small-`t` shape
  `∀ t, 0 < t → t ≤ t₀ → env(t) ≤ C · exp(-c/t) / t^4`
for explicit positive `C, c, t₀`. **That statement is mathematically
false** for any positive `C, c, t₀` and the genuine envelope: as
`t → 0⁺`,
  - LHS `env(t) → +∞` (the SU(3) heat-trace blows up like `t^{-4}`,
    the Weyl-law `t^{-d/2}` with `d = dim_ℝ SU(3) = 8`),
  - RHS `C · exp(-c/t) / t^4 → 0` (the `exp(-c/t)` factor crushes
    `t^{-4}` to zero exponentially fast).
So no Varadhan-shape upper bound with `c > 0` can hold on any open
neighbourhood of `0`. The `exp(-c/t)` factor is the **off-diagonal**
Varadhan/Molchanov small-`t` asymptotic
  `K_t(x, y) ~ (4πt)^{-d/2} · exp(-d_g(x,y)² / 4t)`,
which collapses to the pure `t^{-d/2}` blow-up on the diagonal
`x = y` (where `d_g(x,x) = 0`). The repo's `Heat_kernel_def_real t
:= exp(-c/t) / t^4` placeholder is the off-diagonal shape; the
envelope is the on-diagonal trace, and the two cannot be related by
the literal Varadhan inequality without either (a) `c ≤ 0` or
(b) a lower bound on `t` away from `0`.

This file ships option (b): a **strip-form** Varadhan-shape bound
with `0 < t_lo ≤ t ≤ t_top`. The original task's "or honest
documentation of why the linear bound suffices for the chosen C, c"
escape hatch covers this drift: the strip carries no claim about
the small-`t` asymptotic regime, only the comparison shape inside
a bounded `t`-window — which is what a real off-diagonal Varadhan
bound + finite-volume cutoff would consume downstream once the
bi-invariant SU(3) Riemannian metric (Killing form) lands (not in
mathlib v4.12.0). The constants are nonetheless traceable to the
SU(3) Casimir via the `PeterWeyl_Summable_SU3` proof chain, since
`varadhan_C` is built directly from `Heat_kernel_envelope_real
varadhan_t_lo`, which in turn is dominated by the
Casimir/Weyl-dim product envelope of Bricks 1+2+3 in
`Towers/YM/PeterWeyl.lean`.

### Honest scope (locked)

This file is **not**:
  * the small-`t` Varadhan / Molchanov asymptotic on the open
    neighbourhood of `0` (mathematically false in the stated shape,
    see drift block above),
  * a heat-trace bound of the form `K(t) ≤ C · t^{-d/2}`
    (file 3 of 6 — `Towers/YM/HeatTraceBound.lean`, not landed),
  * the off-diagonal heat kernel `K_t(g, e)` or any SU(3)
    bi-invariant metric `d_{SU(3)}(g, e)` (file 4 of 6 — requires
    Killing-form geometry not in mathlib v4.12.0),
  * a constructive 4D pure-Yang-Mills measure,
  * a mass-gap lower bound on any YM Hamiltonian,
  * a substantive close of `kotecky_preiss_criterion` (still a
    `sorry` in `Towers/Attempts/ClusterExpansion.lean`).

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface #2
stays OPEN.

================================================================
-/

import Towers.YM.PeterWeyl
import Towers.YM.PeterWeylHeat
import Towers.YM.PeterWeylQuadratic
import Towers.YM.Casimir
import Towers.YM.RiemannianGeometry
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.Algebra.InfiniteSum.Order

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeylHeatVaradhan

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl
open TheoremaAureum.Towers.YM.PeterWeylHeat
open TheoremaAureum.Towers.YM.RiemannianGeometry

/-! ## Helper — antitonicity of the envelope in `t` on `(0, ∞)` -/

/-- **Antitonicity of the SU(3) heat-kernel envelope.** For
`0 < t₁ ≤ t₂`, `Heat_kernel_envelope_real t₂ ≤ Heat_kernel_envelope_real t₁`.

Proof: every summand `(dim λ)² · exp(-(t · C₂(λ)))` is antitone in
`t` since `C₂(λ) ≥ 0` and `exp` is monotone. Both partial sums are
`Summable` via `PeterWeyl_Summable_SU3`, so `tsum_le_tsum` closes. -/
theorem Heat_kernel_envelope_real_antitone
    {t₁ t₂ : ℝ} (h1 : 0 < t₁) (h12 : t₁ ≤ t₂) :
    Heat_kernel_envelope_real t₂ ≤ Heat_kernel_envelope_real t₁ := by
  have h2 : 0 < t₂ := lt_of_lt_of_le h1 h12
  unfold Heat_kernel_envelope_real
  refine tsum_le_tsum (fun mn => ?_) (PeterWeyl_Summable_SU3 h2)
    (PeterWeyl_Summable_SU3 h1)
  have hcas : (0 : ℝ) ≤ (Casimir_SU3_explicit mn : ℝ) := Nat.cast_nonneg _
  have hexp_ineq :
      Real.exp (-(t₂ * (Casimir_SU3_explicit mn : ℝ))) ≤
        Real.exp (-(t₁ * (Casimir_SU3_explicit mn : ℝ))) := by
    apply Real.exp_le_exp.mpr
    have hmul : t₁ * (Casimir_SU3_explicit mn : ℝ) ≤
        t₂ * (Casimir_SU3_explicit mn : ℝ) :=
      mul_le_mul_of_nonneg_right h12 hcas
    linarith
  exact mul_le_mul_of_nonneg_left hexp_ineq (sq_nonneg _)

/-! ## Varadhan-shape constants on the strip `[t_lo, t_top]` -/

/-- Decay constant `c` in the Varadhan-shape bound. Concrete value
`1`. Positive. Traceable to the SU(3) Casimir surface only in the
weak sense that the bound holds **for this choice of `c`** because
the strip avoids the small-`t` regime where `c` would have to
match the cut-locus geometry of SU(3). -/
noncomputable def varadhan_c : ℝ := 1

/-- Strip lower endpoint `t_lo`. Concrete value `1/100` (Task #190
widening — previously `1`). Strictly positive — the bound is **not**
a small-`t` asymptotic and does not extend to `t → 0⁺`. The endpoint
is a *fixed* positive number bounded away from `0`; lowering it from
`1` to `1/100` enlarges the strip (and hence the downstream β-range
`[1/t_top, 1/t_lo]`) by two orders of magnitude on the upper β edge,
with the amplitude constant `varadhan_C` automatically re-derived
from `Heat_kernel_envelope_real varadhan_t_lo` to keep the bound
honest. -/
noncomputable def varadhan_t_lo : ℝ := 1 / 100

/-- Strip upper endpoint `t_top`. Concrete value `100` (Task #190
widening — previously `2`). Raising it from `2` to `100` enlarges
the strip on the lower β edge (`1/t_top` drops from `1/2` to
`1/100`). -/
noncomputable def varadhan_t_top : ℝ := 100

/-- Amplitude constant `C` in the Varadhan-shape bound, defined as
  `C := Heat_kernel_envelope_real varadhan_t_lo *`
       `varadhan_t_top ^ 4 * Real.exp (varadhan_c / varadhan_t_lo)`.
Positive because each factor is positive (the envelope is `≥ 1` on
`(0, ∞)` via `Heat_kernel_envelope_real_ge_one_of_pos`). Built
exactly to make the strip bound `env(t) ≤ C · exp(-c/t) / t^4` close
in one calc chain on `[t_lo, t_top]`. -/
noncomputable def varadhan_C : ℝ :=
  Heat_kernel_envelope_real varadhan_t_lo *
    varadhan_t_top ^ 4 * Real.exp (varadhan_c / varadhan_t_lo)

theorem varadhan_c_pos : 0 < varadhan_c := by
  unfold varadhan_c; norm_num

theorem varadhan_t_lo_pos : 0 < varadhan_t_lo := by
  unfold varadhan_t_lo; norm_num

theorem varadhan_t_top_pos : 0 < varadhan_t_top := by
  unfold varadhan_t_top; norm_num

theorem varadhan_t_lo_le_t_top : varadhan_t_lo ≤ varadhan_t_top := by
  unfold varadhan_t_lo varadhan_t_top; norm_num

theorem varadhan_C_pos : 0 < varadhan_C := by
  unfold varadhan_C
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep : (0 : ℝ) < Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4 : (0 : ℝ) < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  exact mul_pos (mul_pos hep htop4) (Real.exp_pos _)

/-! ## Headline — strip-form Varadhan-shape upper bound -/

/-- **Varadhan-shape upper bound on the SU(3) Peter-Weyl heat-kernel
envelope, strip form.** For every `t : ℝ` with
`varadhan_t_lo ≤ t ≤ varadhan_t_top`,
  `Heat_kernel_envelope_real t ≤ varadhan_C · exp(-(varadhan_c / t)) / t^4`.

See the file preamble for the (honest, locked) explanation of why
this is the strip form rather than the unrestricted small-`t` shape
asked for by the Task #156 "Done looks like" line — the literal
statement is mathematically false at any positive `(C, c, t₀)`
because `env(t) → +∞` as `t → 0⁺` while `C · exp(-c/t) / t^4 → 0`.

Proof sketch.
  - Antitonicity of `env` in `t` on `(0, ∞)` gives
    `env(t) ≤ env(t_lo)`.
  - Algebraic strip fact:
      `C · exp(-c/t) / t^4`
        = `env(t_lo) · (t_top^4 / t^4) · exp(c/t_lo) · exp(-c/t)`
        ≥ `env(t_lo) · 1 · 1`         (each factor `≥ 1`)
        = `env(t_lo)`,
    where `t_top^4 / t^4 ≥ 1` because `t ≤ t_top`, and
    `exp(c/t_lo - c/t) ≥ exp(0) = 1` because `c > 0` and
    `c/t ≤ c/t_lo` (since `t_lo ≤ t > 0`).
  - Chain the two. -/
theorem Heat_kernel_envelope_real_le_varadhan
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top) :
    Heat_kernel_envelope_real t ≤
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4_pos : 0 < t ^ 4 := pow_pos htpos 4
  -- Step 1: monotonicity.
  have hmono :
      Heat_kernel_envelope_real t ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_antitone varadhan_t_lo_pos ht_lo
  -- Step 2: bound RHS from below by `env(t_lo)`.
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep_nonneg : 0 ≤ Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4_pos : 0 < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  -- (a) `c/t ≤ c/t_lo` since `0 < t_lo ≤ t` and `c > 0`.
  have hclo : varadhan_c / t ≤ varadhan_c / varadhan_t_lo := by
    rw [div_le_div_iff htpos varadhan_t_lo_pos]
    have := mul_le_mul_of_nonneg_left ht_lo varadhan_c_pos.le
    linarith
  -- (b) Hence `exp(c/t_lo) · exp(-c/t) ≥ exp(0) = 1`.
  have hexp_ineq :
      1 ≤ Real.exp (varadhan_c / varadhan_t_lo) *
            Real.exp (-(varadhan_c / t)) := by
    rw [← Real.exp_add]
    have h0 : (0 : ℝ) ≤ varadhan_c / varadhan_t_lo + -(varadhan_c / t) := by
      linarith
    calc (1 : ℝ) = Real.exp 0 := Real.exp_zero.symm
      _ ≤ Real.exp (varadhan_c / varadhan_t_lo + -(varadhan_c / t)) :=
            Real.exp_le_exp.mpr h0
  -- (c) `t^4 ≤ t_top^4` since `0 ≤ t ≤ t_top`.
  have ht4_le : t ^ 4 ≤ varadhan_t_top ^ 4 :=
    pow_le_pow_left htpos.le ht_top 4
  -- Combine: `env(t_lo) ≤ C · exp(-c/t) / t^4`.
  have hrhs :
      Heat_kernel_envelope_real varadhan_t_lo ≤
        varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
    rw [le_div_iff₀ ht4_pos]
    have hC_eq :
        varadhan_C * Real.exp (-(varadhan_c / t)) =
          Heat_kernel_envelope_real varadhan_t_lo *
            varadhan_t_top ^ 4 *
              (Real.exp (varadhan_c / varadhan_t_lo) *
                Real.exp (-(varadhan_c / t))) := by
      unfold varadhan_C; ring
    rw [hC_eq]
    calc Heat_kernel_envelope_real varadhan_t_lo * t ^ 4
        ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 :=
            mul_le_mul_of_nonneg_left ht4_le hep_nonneg
      _ = Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 * 1 := by
            ring
      _ ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 *
            (Real.exp (varadhan_c / varadhan_t_lo) *
              Real.exp (-(varadhan_c / t))) :=
            mul_le_mul_of_nonneg_left hexp_ineq
              (mul_nonneg hep_nonneg htop4_pos.le)
  linarith

/-! ## Geometric (off-diagonal Varadhan-shape) brick — Task #170 -/

/-- **Geometric decay constant** `c_geom(x) := d_SU3(x, 1)² / 4`.
This is the **off-diagonal** Varadhan/Molchanov small-`t` constant
`d_g(x, e)² / 4` from `K_t(x, e) ≲ t^{-d/2} · exp(-d(x, e)² / 4t)`
— now expressed against the stand-in bi-invariant distance
`d_SU3 : SU3 → SU3 → ℝ` from `Towers/YM/RiemannianGeometry.lean`.

Because `d_SU3 ≡ 0` in the current stand-in, `c_geom(x) = 0` for
every `x`. Replacing `d_SU3` with the real Killing-form distance
will *intentionally* break the downstream geometric brick (since
the proof exploits `d_SU3 x 1 = 0` rfl-style) — that is the
tripwire signalling a real off-diagonal Varadhan bound has
landed. -/
noncomputable def varadhan_geometric_c (x : SU3) : ℝ :=
  (d_SU3 x (1 : SU3)) ^ 2 / 4

/-- The geometric decay constant vanishes **on the diagonal** locus
`{x : d_SU3 x 1 = 0}` (which, under the real chordal distance, is the
single point `x = 1`). The canonical witness is `x = 1`, where
`d_SU3 1 1 = 0` by `RiemannianGeometry.d_SU3_self`.

**Tripwire (Task #189).** Under the Task #170 stand-in `d_SU3 ≡ 0`
this held for *every* `x` (`rfl`). Now that `d_SU3` is the real
Killing-form chordal distance it holds only on the diagonal — the
off-diagonal case `d_SU3 x 1 > 0` is precisely the open off-diagonal
Varadhan / Molchanov regime. -/
theorem varadhan_geometric_c_one :
    varadhan_geometric_c (1 : SU3) = 0 := by
  unfold varadhan_geometric_c
  rw [RiemannianGeometry.d_SU3_self]
  ring

/-- **Geometric-form Varadhan-shape upper bound on the SU(3)
Peter-Weyl heat-kernel envelope, strip form (Task #170).** For
every `t : ℝ` with `varadhan_t_lo ≤ t ≤ varadhan_t_top` and every
`x : SU3`,
  `Heat_kernel_envelope_real t ≤`
      `varadhan_C · exp(-(d_SU3 x 1)^2 / (4 · t)) / t^4`.

This is the **shape** the real off-diagonal Varadhan asymptotic
would consume — the same `exp(-d(x, e)² / 4t)` factor and the
same `t^{-4}` polynomial decay.

**Task #189 tripwire — diagonal hypothesis.** With `d_SU3` upgraded
to the *real* Killing-form chordal distance (file
`Towers/YM/RiemannianGeometry.lean`), the `exp(-d(x, 1)² / (4t))`
factor no longer collapses to `1` for arbitrary `x`: when
`d_SU3 x 1 > 0` the right-hand side is *strictly smaller* than
`varadhan_C / t^4`, so the bound can NO LONGER be derived from the
strip bound — that off-diagonal case is exactly the open
Varadhan / Molchanov asymptotic. The brick is therefore re-stated
with an explicit diagonal hypothesis `hx : d_SU3 x 1 = 0` (the locus
`{x : d_SU3 x 1 = 0} = {1}`), on which the factor genuinely equals
`exp 0 = 1` and the bound reduces to the existing strip bound plus
`exp(-c/t) ≤ 1`. The canonical witness is `x = 1` via
`RiemannianGeometry.d_SU3_self`. The breaking of the old `rfl`-style
proof IS the tripwire the Task #170/#189 brief describes.

**Honest scope (locked).** This is NOT the real off-diagonal
Varadhan / Molchanov asymptotic — see the file preamble and the
`RiemannianGeometry.lean` docstring. The off-diagonal envelope
(`x` with `d_SU3 x 1 > 0`) remains open. YM tower stays
`Status: Open`. -/
theorem Heat_kernel_envelope_real_le_varadhan_geometric
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top)
    (x : SU3) (hx : d_SU3 x (1 : SU3) = 0) :
    Heat_kernel_envelope_real t ≤
      varadhan_C *
        Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4_pos : 0 < t ^ 4 := pow_pos htpos 4
  -- Step 1: existing strip bound.
  have hstrip :
      Heat_kernel_envelope_real t ≤
        varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 :=
    Heat_kernel_envelope_real_le_varadhan ht_lo ht_top
  -- Step 2: the geometric exp factor collapses to `1` on the diagonal.
  have hd : d_SU3 x (1 : SU3) = 0 := hx
  have hgeom_zero : (d_SU3 x (1 : SU3)) ^ 2 / (4 * t) = 0 := by
    rw [hd]; ring
  have hexp_geom :
      Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) = 1 := by
    rw [hgeom_zero, neg_zero, Real.exp_zero]
  -- Step 3: `exp(-(c/t)) ≤ 1` since `c, t > 0`.
  have hcoverpos : 0 ≤ varadhan_c / t :=
    div_nonneg varadhan_c_pos.le htpos.le
  have hexp_le_one :
      Real.exp (-(varadhan_c / t)) ≤ 1 := by
    calc Real.exp (-(varadhan_c / t))
        ≤ Real.exp 0 := Real.exp_le_exp.mpr (by linarith)
      _ = 1 := Real.exp_zero
  -- Step 4: turn the geometric RHS into `varadhan_C / t^4` and chain.
  have hVC_pos : 0 < varadhan_C := varadhan_C_pos
  have h_geom_rhs :
      varadhan_C *
          Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) / t ^ 4 =
        varadhan_C / t ^ 4 := by
    rw [hexp_geom, mul_one]
  rw [h_geom_rhs]
  -- And the strip RHS is `≤ varadhan_C / t^4` since `exp(-c/t) ≤ 1`.
  have hnum :
      varadhan_C * Real.exp (-(varadhan_c / t)) ≤ varadhan_C := by
    calc varadhan_C * Real.exp (-(varadhan_c / t))
        ≤ varadhan_C * 1 :=
          mul_le_mul_of_nonneg_left hexp_le_one hVC_pos.le
      _ = varadhan_C := mul_one _
  have hstrip_le :
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 ≤
        varadhan_C / t ^ 4 := by
    rw [div_le_div_iff ht4_pos ht4_pos]
    nlinarith [hnum, ht4_pos]
  exact le_trans hstrip hstrip_le

/-! ## Genuine off-diagonal envelope — Task #210

The geometric brick above is gated behind the diagonal hypothesis
`hx : d_SU3 x 1 = 0`. The genuine off-diagonal case (`d_SU3 x 1 > 0`)
is the open Varadhan / Molchanov small-`t` asymptotic. This section
discharges the **strip-form** off-diagonal bound for *every* `x : SU3`
(hypothesis `hx` removed), using the fact that the chordal `d_SU3`
is **bounded** on SU(3): for `x ∈ SU(3)`,
  `(d_SU3 x 1)² = hsNormSq (↑x - 1) = 6 - 2·Re(tr ↑x) ≤ 12`,
because `hsNormSq (↑x + 1) = 6 + 2·Re(tr ↑x) ≥ 0` forces
`Re(tr ↑x) ≥ -3`. On the strip `[t_lo, t_top]` the decay factor
`exp(-(d_SU3 x 1)² / (4t))` is therefore bounded below by the
positive constant `exp(-12 / (4·t_lo))`, so the bound holds for all
`x` once the amplitude is recalibrated from `varadhan_C` to
`varadhan_C_offdiag` (which carries `exp(12 / (4·t_lo))` in place of
`exp(varadhan_c / t_lo)`).

**Honest scope (locked).** This is the genuine off-diagonal *strip*
bound — it carries the real `exp(-d(x,1)²/4t)` decay factor for every
`x` including the off-diagonal locus `d_SU3 x 1 > 0`, with constants
traceable to `Heat_kernel_envelope_real varadhan_t_lo`. It is NOT the
small-`t` Varadhan / Molchanov asymptotic (still open — the literal
unrestricted shape is false as `t → 0⁺`, see the file preamble), and
it does NOT use the *geodesic* distance (the chordal `d_SU3` is only a
pseudo-distance, see `RiemannianGeometry.lean`). YM tower stays
`Status: Open`; Surface #2 stays OPEN. No mass-gap / μ>0 / Surface
claim. -/

/-- **`hsNormSq` is nonnegative.** `hsNormSq M = (tr(Mᴴ M)).re`
expands to `∑_{i,j} |M i j|² ≥ 0`. Proved by the explicit `Fin 3`
trace/matrix-product expansion. -/
theorem hsNormSq_nonneg (M : Matrix (Fin 3) (Fin 3) ℂ) :
    0 ≤ RiemannianGeometry.hsNormSq M := by
  unfold RiemannianGeometry.hsNormSq
  rw [Matrix.trace_fin_three]
  simp only [Matrix.mul_apply, Matrix.star_apply, Fin.sum_univ_three,
    Complex.star_def, ← Complex.normSq_eq_conj_mul_self,
    Complex.add_re, Complex.ofReal_re]
  linarith [Complex.normSq_nonneg (M 0 0), Complex.normSq_nonneg (M 1 0),
    Complex.normSq_nonneg (M 2 0), Complex.normSq_nonneg (M 0 1),
    Complex.normSq_nonneg (M 1 1), Complex.normSq_nonneg (M 2 1),
    Complex.normSq_nonneg (M 0 2), Complex.normSq_nonneg (M 1 2),
    Complex.normSq_nonneg (M 2 2)]

/-- **Diagonal-shifted Hilbert–Schmidt norm of a unitary.** For
`A` with `star A * A = 1`,
  `hsNormSq (A - 1) = 6 - 2·(tr A).re`.
Proof: expand `(Aᴴ - 1)(A - 1) = Aᴴ A - Aᴴ - A + 1`, use
`Aᴴ A = 1`, `tr 1 = 3`, `tr Aᴴ = conj (tr A)`. -/
theorem hsNormSq_sub_one_eq (A : Matrix (Fin 3) (Fin 3) ℂ)
    (hA : star A * A = 1) :
    RiemannianGeometry.hsNormSq (A - 1) = 6 - 2 * (Matrix.trace A).re := by
  unfold RiemannianGeometry.hsNormSq
  have hstar : star (A - 1) = star A - 1 := by rw [star_sub, star_one]
  have he : star (A - 1) * (A - 1) = star A * A - star A - A + 1 := by
    rw [hstar, sub_mul, mul_sub, mul_sub, mul_one, one_mul, mul_one]
    abel
  rw [he, hA]
  simp only [Matrix.trace_add, Matrix.trace_sub, Matrix.trace_one,
    Matrix.star_eq_conjTranspose, Matrix.trace_conjTranspose,
    Fintype.card_fin, Complex.add_re, Complex.sub_re, Complex.star_def,
    Complex.conj_re, Complex.natCast_re]
  push_cast
  ring

/-- **Anti-diagonal-shifted Hilbert–Schmidt norm of a unitary.** For
`A` with `star A * A = 1`,
  `hsNormSq (A + 1) = 6 + 2·(tr A).re`. -/
theorem hsNormSq_add_one_eq (A : Matrix (Fin 3) (Fin 3) ℂ)
    (hA : star A * A = 1) :
    RiemannianGeometry.hsNormSq (A + 1) = 6 + 2 * (Matrix.trace A).re := by
  unfold RiemannianGeometry.hsNormSq
  have hstar : star (A + 1) = star A + 1 := by rw [star_add, star_one]
  have he : star (A + 1) * (A + 1) = star A * A + star A + A + 1 := by
    rw [hstar, add_mul, mul_add, mul_add, mul_one, one_mul, mul_one]
    abel
  rw [he, hA]
  simp only [Matrix.trace_add, Matrix.trace_one,
    Matrix.star_eq_conjTranspose, Matrix.trace_conjTranspose,
    Fintype.card_fin, Complex.add_re, Complex.star_def,
    Complex.conj_re, Complex.natCast_re]
  push_cast
  ring

/-- **The chordal SU(3) distance to the identity is bounded:**
`(d_SU3 x 1)² ≤ 12` for every `x : SU3`. The bound `12 = (2√3)²` is
the squared HS-diameter of SU(3). Proof: `(d_SU3 x 1)² =
hsNormSq (↑x - 1) = 6 - 2·Re(tr ↑x)` while `hsNormSq (↑x + 1) =
6 + 2·Re(tr ↑x) ≥ 0` forces `Re(tr ↑x) ≥ -3`. -/
theorem d_SU3_sq_le_twelve (x : RiemannianGeometry.SU3) :
    (RiemannianGeometry.d_SU3 x (1 : RiemannianGeometry.SU3)) ^ 2 ≤ 12 := by
  have hone : ((1 : RiemannianGeometry.SU3) : Matrix (Fin 3) (Fin 3) ℂ)
      = 1 := OneMemClass.coe_one _
  have hxU : star (x : Matrix (Fin 3) (Fin 3) ℂ) *
      (x : Matrix (Fin 3) (Fin 3) ℂ) = 1 :=
    Matrix.mem_unitaryGroup_iff'.mp
      (Matrix.mem_specialUnitaryGroup_iff.mp x.2).1
  have hsq : (RiemannianGeometry.d_SU3 x (1 : RiemannianGeometry.SU3)) ^ 2
      = RiemannianGeometry.hsNormSq ((x : Matrix (Fin 3) (Fin 3) ℂ) - 1) := by
    unfold RiemannianGeometry.d_SU3
    rw [hone, Real.sq_sqrt (hsNormSq_nonneg _)]
  rw [hsq, hsNormSq_sub_one_eq _ hxU]
  have hpos : 0 ≤ RiemannianGeometry.hsNormSq
      ((x : Matrix (Fin 3) (Fin 3) ℂ) + 1) := hsNormSq_nonneg _
  rw [hsNormSq_add_one_eq _ hxU] at hpos
  linarith

/-- Amplitude constant for the off-diagonal strip bound. Mirrors
`varadhan_C` but carries `exp(12 / (4·t_lo))` — large enough to
absorb the bounded decay factor `exp(-(d_SU3 x 1)² / (4t)) ≥
exp(-12/(4·t_lo))` uniformly over the strip and over all `x`. -/
noncomputable def varadhan_C_offdiag : ℝ :=
  Heat_kernel_envelope_real varadhan_t_lo *
    varadhan_t_top ^ 4 * Real.exp (12 / (4 * varadhan_t_lo))

theorem varadhan_C_offdiag_pos : 0 < varadhan_C_offdiag := by
  unfold varadhan_C_offdiag
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep : (0 : ℝ) < Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4 : (0 : ℝ) < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  exact mul_pos (mul_pos hep htop4) (Real.exp_pos _)

/-- **Genuine off-diagonal Varadhan-shape upper bound on the SU(3)
Peter-Weyl heat-kernel envelope, strip form (Task #210).** For every
`t : ℝ` with `varadhan_t_lo ≤ t ≤ varadhan_t_top` and **every**
`x : SU3` (no diagonal hypothesis),
  `Heat_kernel_envelope_real t ≤`
      `varadhan_C_offdiag · exp(-(d_SU3 x 1)² / (4·t)) / t^4`.

This removes the `hx : d_SU3 x 1 = 0` gate of
`Heat_kernel_envelope_real_le_varadhan_geometric`: the bound now
carries the genuine `exp(-d(x,1)²/4t)` decay factor for *every* `x`,
including the off-diagonal locus `d_SU3 x 1 > 0`.

Proof.
  - Antitonicity: `env(t) ≤ env(t_lo)`.
  - The chordal distance is bounded: `(d_SU3 x 1)² ≤ 12`
    (`d_SU3_sq_le_twelve`), so on the strip
      `(d_SU3 x 1)²/(4t) ≤ 12/(4t) ≤ 12/(4·t_lo)`,
    hence `exp(12/(4·t_lo)) · exp(-(d_SU3 x 1)²/(4t)) ≥ 1`.
  - With `t^4 ≤ t_top^4` and `env(t_lo) ≥ 1`:
      `env(t_lo) ≤ env(t_lo)·t_top^4·exp(12/(4·t_lo))·exp(-(…)²/4t)/t^4`
              `= varadhan_C_offdiag · exp(-(…)²/4t) / t^4`.

**Honest scope (locked).** Strip-form only; NOT the small-`t`
asymptotic (false in the literal unrestricted shape, see preamble),
NOT the geodesic distance (chordal `d_SU3` is a pseudo-distance).
Makes NO mass-gap / μ>0 / Surface claim — YM tower stays
`Status: Open`, Surface #2 stays OPEN. -/
theorem Heat_kernel_envelope_real_le_varadhan_geometric_offdiag
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top)
    (x : RiemannianGeometry.SU3) :
    Heat_kernel_envelope_real t ≤
      varadhan_C_offdiag *
        Real.exp (-((RiemannianGeometry.d_SU3 x (1 : RiemannianGeometry.SU3)) ^ 2
          / (4 * t))) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4_pos : 0 < t ^ 4 := pow_pos htpos 4
  set dsq : ℝ := (RiemannianGeometry.d_SU3 x (1 : RiemannianGeometry.SU3)) ^ 2
  have hdsq_nonneg : 0 ≤ dsq := sq_nonneg _
  have hdsq_le : dsq ≤ 12 := d_SU3_sq_le_twelve x
  -- Step 1: antitonicity.
  have hmono :
      Heat_kernel_envelope_real t ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_antitone varadhan_t_lo_pos ht_lo
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep_nonneg : 0 ≤ Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4_pos : 0 < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  -- Step 2: the geometric exp argument is bounded below.
  have h4t : (0 : ℝ) < 4 * t := by linarith
  have h4lo : (0 : ℝ) < 4 * varadhan_t_lo := by
    have := varadhan_t_lo_pos; linarith
  have harg : dsq / (4 * t) ≤ 12 / (4 * varadhan_t_lo) := by
    rw [div_le_div_iff h4t h4lo]
    nlinarith [mul_le_mul_of_nonneg_right hdsq_le h4lo.le,
      mul_le_mul_of_nonneg_left ht_lo (by norm_num : (0 : ℝ) ≤ 48),
      hdsq_nonneg, varadhan_t_lo_pos, htpos]
  -- Step 3: `exp(12/(4 t_lo)) · exp(-(dsq/(4t))) ≥ 1`.
  have hexp_ge1 :
      1 ≤ Real.exp (12 / (4 * varadhan_t_lo)) *
            Real.exp (-(dsq / (4 * t))) := by
    rw [← Real.exp_add]
    have h0 : (0 : ℝ) ≤ 12 / (4 * varadhan_t_lo) + -(dsq / (4 * t)) := by
      linarith
    calc (1 : ℝ) = Real.exp 0 := Real.exp_zero.symm
      _ ≤ Real.exp (12 / (4 * varadhan_t_lo) + -(dsq / (4 * t))) :=
            Real.exp_le_exp.mpr h0
  -- Step 4: `t^4 ≤ t_top^4`.
  have ht4_le : t ^ 4 ≤ varadhan_t_top ^ 4 :=
    pow_le_pow_left htpos.le ht_top 4
  -- Combine.
  have hrhs :
      Heat_kernel_envelope_real varadhan_t_lo ≤
        varadhan_C_offdiag * Real.exp (-(dsq / (4 * t))) / t ^ 4 := by
    rw [le_div_iff₀ ht4_pos]
    have hC_eq :
        varadhan_C_offdiag * Real.exp (-(dsq / (4 * t))) =
          Heat_kernel_envelope_real varadhan_t_lo *
            varadhan_t_top ^ 4 *
              (Real.exp (12 / (4 * varadhan_t_lo)) *
                Real.exp (-(dsq / (4 * t)))) := by
      unfold varadhan_C_offdiag; ring
    rw [hC_eq]
    calc Heat_kernel_envelope_real varadhan_t_lo * t ^ 4
        ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 :=
            mul_le_mul_of_nonneg_left ht4_le hep_nonneg
      _ = Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 * 1 := by
            ring
      _ ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 *
            (Real.exp (12 / (4 * varadhan_t_lo)) *
              Real.exp (-(dsq / (4 * t)))) :=
            mul_le_mul_of_nonneg_left hexp_ge1
              (mul_nonneg hep_nonneg htop4_pos.le)
  exact le_trans hmono hrhs

/-! ## Half-cubic antidiagonal envelope summand bound — Task #193 -/

/-- **Half-cubic sharpening of the SU(3) heat-kernel envelope
summand (Task #193).** Each summand of `Heat_kernel_envelope_real t`
— the genuine SU(3) Peter-Weyl spectral term
`(dim λ)² · exp(-(t · C₂(λ)))` — is bounded by the **squared
half-cubic** antidiagonal envelope

  `(((m+n)+2)^3 / 2)^2 · exp(-(t · C₂(λ)))`,

routed through Task #173's `Weyl_dim_SU3_explicit_real_le_half_cubic`
(`(dim:ℝ) ≤ ((m+n)+2)^3 / 2`). This carries the literal `/2` factor
of the half-cubic Weyl-dim bound through to the heat-kernel-envelope
summand statement: against the older slack cubic bound from Task
#157's `Weyl_dim_SU3_explicit_real_le_cubic` (`(dim:ℝ) ≤ ((m+n)+2)^3`)
the same summand carries the bound `(dim:ℝ)² · exp ≤ ((m+n)+2)^6 · exp`,
so routing through the half-cubic bound divides the antidiagonal
envelope constant by `4` (one `1/2` per `dim` factor in `dim²`) —
"halving the slack" exactly as the Task #173 brief flagged.

Proof: square the half-cubic bound via `pow_le_pow_left` (both
sides nonneg), then multiply by `exp(-(t · C₂)) ≥ 0`.

**Honest scope (locked).** This is a *per-summand* (pointwise)
antidiagonal envelope inequality on the genuine Peter-Weyl
heat-kernel envelope term, NOT a summed `tsum`/strip bound and NOT
a Varadhan small-`t` asymptotic — the strip amplitude `varadhan_C`
is already exact (built from `Heat_kernel_envelope_real varadhan_t_lo`
itself, with no Weyl-dim slack to halve). YM tower stays
`Status: Open` in `docs/ROADMAP.md` § 2; Surface #2 stays OPEN. -/
theorem Heat_kernel_envelope_summand_real_le_half_cubic
    (t : ℝ) (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) ≤
      (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
        Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) := by
  have hdim_nonneg : (0 : ℝ) ≤ (Weyl_dim_SU3_explicit mn : ℝ) :=
    Nat.cast_nonneg _
  have hhalf := PeterWeylQuadratic.Weyl_dim_SU3_explicit_real_le_half_cubic mn
  have hsq :
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 ≤
        (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 :=
    pow_le_pow_left hdim_nonneg hhalf 2
  exact mul_le_mul_of_nonneg_right hsq (Real.exp_pos _).le

/-! ## Summed half-cubic envelope bound — Task #217 -/

/-- **Whole-sum half-cubic upper bound on the SU(3) Peter-Weyl
heat-kernel envelope (Task #217).** For every `t > 0`,
  `Heat_kernel_envelope_real t ≤`
    `∑'_{(m,n)} (((m+n)+2)^3 / 2)^2 · exp(-(t · C₂(m,n)))`.

This carries the per-summand half-cubic brick
`Heat_kernel_envelope_summand_real_le_half_cubic` (Task #193) from a
single mode to the **whole** infinite sum: the genuine envelope
`Heat_kernel_envelope_real t = ∑'_{(m,n)} (dim λ)² · exp(-(t·C₂(λ)))`
is bounded above by the `tsum` of the squared half-cubic antidiagonal
envelope. The summed form is what downstream strip / spectral-gap work
actually consumes.

Proof: `tsum_le_tsum` applied to the per-summand bound, with the LHS
series `Summable` via `PeterWeyl_Summable_SU3 ht` (Batch 19.1p-redux-a)
and the RHS series `Summable` via the new
`PeterWeylQuadratic.PeterWeyl_Summable_SU3_half_cubic ht` (Task #217).

**Honest scope (locked).** This is a *summed envelope* inequality on the
genuine Peter-Weyl heat-kernel envelope, NOT a Varadhan small-`t`
asymptotic and NOT a mass-gap / spectral-gap claim. YM tower stays
`Status: Open` in `docs/ROADMAP.md` § 2; Surface #2 stays OPEN. -/
theorem Heat_kernel_envelope_real_le_tsum_half_cubic
    {t : ℝ} (ht : 0 < t) :
    Heat_kernel_envelope_real t ≤
      ∑' (mn : ℕ × ℕ),
        (((mn.1 : ℝ) + mn.2 + 2) ^ 3 / 2) ^ 2 *
          Real.exp (-(t * (Casimir_SU3_explicit mn : ℝ))) := by
  unfold Heat_kernel_envelope_real
  exact tsum_le_tsum
    (fun mn => Heat_kernel_envelope_summand_real_le_half_cubic t mn)
    (PeterWeyl_Summable_SU3 ht)
    (PeterWeylQuadratic.PeterWeyl_Summable_SU3_half_cubic ht)

end PeterWeylHeatVaradhan
end YM
end Towers
end TheoremaAureum
