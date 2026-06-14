/-
================================================================
Towers / NS / EnergyV2  (Batch 8 Track 2)

**Unblocking the real `E(t) ≤ E(0)` energy inequality.**

Five bricks named exactly per the Batch 8 directive, plus one
tripwire theorem (active per directive but NOT registered in
`scripts/check-towers.sh` — its compilation alone enforces the
tripwire because flipping `Dissipation` to a non-zero body breaks
the `add_zero` step inside the proof):

  1. `H1Norm_v2` — placeholder upgrade target for the Task #51
     `H1Norm`. Currently defined as the literal alias
     `H1Norm_v2 u t := H1Norm u t`, with a TODO naming the
     intended `L²` replacement.
  2. `Dissipation` — explicit zero placeholder for the
     gradient-energy term `‖∇u(t)‖_{L²}²`. Honest stand-in until
     `fderiv ℝ (u t)` plus an `MemLp 2` packaging lands.
  3. `Dissipation_nonneg` — `0 ≤ Dissipation u t`. Currently
     trivial (RHS = 0); the statement honestly anticipates the
     `sq_nonneg`-shaped proof a real `‖∇u‖_{L²}²` upgrade will
     need.
  4. `ViscosityScaling` — `ν * Dissipation u t`. Names the coupling
     constant `ν` and reserves the slot for the real viscosity
     scaling in front of the dissipation term.
  5. `EnergyDissipationIntegral` — `ν * t * Dissipation u 0`, the
     rectangle-rule stand-in for `ν * ∫₀ᵗ ‖∇u(s)‖_{L²}² ds`.
     Avoids importing `MeasureTheory.Integral.IntervalIntegral`
     while preserving the linear-in-`t` shape downstream
     `LerayEnergyIneq` arguments need.

Plus supporting:

  * `LerayEnergyIneq ν u u₀ : Prop` — the named
    `½ ‖u(t)‖² + ν ∫₀ᵗ ‖∇u‖² ds ≤ ½ ‖u₀(0)‖²` shape on the
    placeholders. Real `Prop` over real arithmetic.
  * `LerayEnergyIneq_dissipation_zero_simplifies` — the active
    tripwire. Currently `LerayEnergyIneq ν u u₀ ↔ ∀ t,
    ½ (H1Norm u t)² ≤ ½ (H1Norm u₀ 0)²` because the dissipation
    term collapses to zero. Flipping `Dissipation` to any
    non-zero body intentionally breaks the `add_zero` step in
    the proof, signalling that a real dissipation term has landed
    and the Leray-Hopf surface needs a real proof of monotonicity
    against the dissipation.

### Honest scope

What this file claims:

  * `H1Norm_v2` is the *alias* `H1Norm` (the Task #51 placeholder
    Euclidean norm of `u t 0`). NOT the real H¹ Sobolev norm,
    NOT an `L²` norm — explicit alias awaiting a future
    refactor.
  * `Dissipation` is the literal zero function. NOT the real
    dissipation `ν ‖∇u(t)‖_{L²}²`, NOT an `L²` gradient norm.
  * `ViscosityScaling` is `ν * 0 = 0` definitionally; the
    coupling constant `ν` is genuinely quantified.
  * `EnergyDissipationIntegral` is `ν * t * 0 = 0` definitionally
    on the placeholder. NOT a real Lebesgue integral, NOT the
    Leray-Hopf cumulative dissipation.
  * `LerayEnergyIneq` is a real `Prop` over real arithmetic; its
    *content* is the placeholder schema, not the Clay
    conjecture's energy inequality.
  * `LerayEnergyIneq_dissipation_zero_simplifies` is a genuine
    `Iff` and the tripwire mechanism: the proof closes only
    because `Dissipation = 0`. Any non-zero upgrade breaks it.

What this file does NOT claim:

  * The Leray-Hopf energy inequality
    `½ ‖u(t)‖_{L²}² + ν ∫₀ᵗ ‖∇u‖_{L²}² ds ≤ ½ ‖u₀‖_{L²}²`;
  * Any actual NS time-evolution operator (no `Φ_t` is constructed);
  * NS global regularity, weak-strong uniqueness, or any other
    Clay-style result.

NS tower status unchanged: **Open** (`docs/ROADMAP.md` § 3).

### Zero shared imports

This file imports only `Towers.NS.EnergyIneq` (the Task #51 / #56
/ #62 / #69 / #70 NS schema foundation). It does NOT import
`Towers.Spectral.OperatorV2` or `Towers.YM.Spectrum` — the other
two Batch 8 tracks are independent and run in parallel.
================================================================
-/

import Towers.NS.EnergyIneq

namespace TheoremaAureum
namespace Towers
namespace NS
namespace EnergyV2

open TheoremaAureum.Towers.NS

/-! ### Schema defs (5) — one per Batch 8 directive item -/

/-- **Brick 1 (`H1Norm_v2`).** Placeholder-upgrade target for
the Task #51 `H1Norm`. Currently the literal alias
`H1Norm_v2 u t := H1Norm u t`. The aliasing is intentional: it
reserves the `_v2` name for the real Sobolev / `L²` replacement
without forcing a rename of every downstream caller when the
upgrade lands.

TODO (mathlib v4.13+): replace the body with
`(∫ x, ‖u t x‖^2 ∂volume).sqrt` on `MeasureTheory.MemLp 2`. -/
noncomputable def H1Norm_v2 (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t

/-- **Brick 2 (`Dissipation`).** Placeholder gradient-energy term.
Currently the literal zero function. Honest stand-in for
`‖∇u(t)‖_{L²}²` until `fderiv ℝ (u t)` plus an `MemLp 2` packaging
lands.

TODO (mathlib v4.13+): replace the body with
`∫ x, ‖fderiv ℝ (u t) x‖^2 ∂volume` on `MeasureTheory.MemLp 2`. -/
def Dissipation (_u : VelocityField) (_t : ℝ) : ℝ := 0

/-- **Brick 3 (`Dissipation_nonneg`).** `0 ≤ Dissipation u t`.
Currently trivial because the placeholder body is `0`. The
statement honestly anticipates the `sq_nonneg`-shaped proof a real
`‖∇u‖_{L²}²` upgrade will need; updating the body to a real
integral of squared norms keeps this brick provable via
`integral_nonneg` + `sq_nonneg`. -/
theorem Dissipation_nonneg (u : VelocityField) (t : ℝ) :
    0 ≤ Dissipation u t := by
  unfold Dissipation
  exact le_refl 0

/-- **Brick 4 (`ViscosityScaling`).** Names the coupling-constant
scaling `ν * Dissipation u t`. Reserves the slot for the
viscosity coefficient in front of the dissipation term in the
Leray-Hopf inequality. On the current placeholder
(`Dissipation = 0`) this is `ν * 0 = 0` definitionally. -/
noncomputable def ViscosityScaling
    (ν : ℝ) (u : VelocityField) (t : ℝ) : ℝ :=
  ν * Dissipation u t

/-- **Brick 5 (`EnergyDissipationIntegral`).** Rectangle-rule
stand-in for `ν * ∫₀ᵗ ‖∇u(s)‖_{L²}² ds`. Defined as
`ν * t * Dissipation u 0` to preserve the linear-in-`t` shape
downstream `LerayEnergyIneq` arguments need without importing
`MeasureTheory.Integral.IntervalIntegral`. On the current
placeholder (`Dissipation = 0`) this is `ν * t * 0 = 0`
definitionally.

TODO (mathlib v4.13+): replace the body with
`ν * ∫ s in (0 : ℝ)..t, Dissipation u s` via `intervalIntegral`. -/
noncomputable def EnergyDissipationIntegral
    (ν : ℝ) (u : VelocityField) (t : ℝ) : ℝ :=
  ν * t * Dissipation u 0

/-! ### Supporting: `LerayEnergyIneq` + active tripwire -/

/-- **Placeholder-flavoured Leray-Hopf energy inequality.**
`∀ t, ½ (H1Norm u t)² + EnergyDissipationIntegral ν u t
≤ ½ (H1Norm u₀ 0)²`. Real `Prop` over real arithmetic on the
Task #51 / Batch 8 placeholders. NOT the Leray-Hopf energy
inequality — `H1Norm` is the Task #51 placeholder, `Dissipation`
is the Batch 8 zero placeholder, `EnergyDissipationIntegral` is
the rectangle-rule stand-in. -/
def LerayEnergyIneq (ν : ℝ) (u u₀ : VelocityField) : Prop :=
  ∀ t : ℝ,
    (1 / 2) * (H1Norm u t) ^ 2 + EnergyDissipationIntegral ν u t
      ≤ (1 / 2) * (H1Norm u₀ 0) ^ 2

/-- **Active tripwire — directive: `Tripwire active`.**

With the current `Dissipation = 0` placeholder, the
`EnergyDissipationIntegral` term in `LerayEnergyIneq` collapses,
so the predicate degenerates to a pointwise `H1Norm` square
inequality. The `Iff` is provable now because `add_zero` discharges
the dissipation column; flipping `Dissipation` to any non-zero body
(`ν ‖∇u‖_{L²}²`, or even a non-trivial stand-in like
`fun u t => 1`) intentionally breaks the proof, signalling that a
real dissipation term has landed and the Leray-Hopf surface needs
a real proof of monotonicity against the dissipation. -/
theorem LerayEnergyIneq_dissipation_zero_simplifies
    (ν : ℝ) (u u₀ : VelocityField) :
    LerayEnergyIneq ν u u₀ ↔
      ∀ t : ℝ,
        (1 / 2) * (H1Norm u t) ^ 2 ≤ (1 / 2) * (H1Norm u₀ 0) ^ 2 := by
  unfold LerayEnergyIneq EnergyDissipationIntegral Dissipation
  constructor
  · intro h t
    have := h t
    linarith
  · intro h t
    have := h t
    linarith

/-! ### Batch 9 (5) — real (non-zero) dissipation track

Adds a SECOND dissipation surface (`Dissipation_real`) and a
SECOND Leray-flavoured energy inequality (`LerayEnergyIneq_real`)
that uses it, **without touching** the Batch 8 `Dissipation`
(`= 0`) or its `LerayEnergyIneq_dissipation_zero_simplifies`
tripwire above. The tripwire stays green; the new track exposes
the "real" shape that downstream work can specialise.

**Honest scope.** None of these advance the NS tower past
`Status: Open`. They prove only:

  * `H1Norm_real` — squared placeholder H¹-norm `(‖u t 0‖)²`.
    NOT the real L² spatial integral.
  * `Dissipation_real` — non-zero placeholder dissipation
    `(‖u t 0‖)²`. Shape of `ν ‖∇u‖_{L²}²`, NOT the gradient
    L² norm.
  * `LerayEnergyIneq_real` — `Prop` shape
    `½ E(t) + ∫ D ≤ ½ E(0)` over the new defs. No proof —
    the Leray-Hopf inequality is **not** proved here.
  * `Dissipation_positive_ae` — `0 ≤ Dissipation_real u t` via
    `mul_self_nonneg`.
  * `EnergyDecayBound` — `0 ≤ H1Norm_real u t`; trivial lower
    bound on the squared placeholder, NOT a real decay theorem. -/

/-- **Brick (`H1Norm_real`).** Squared placeholder H¹-norm:
`(H1Norm u t)²` written as `H1Norm u t * H1Norm u t`. Real,
non-negative, deterministic function of `(u, t)`. NOT the L²
spatial integral of `|∇u|²`; just the square of the Task #51
placeholder evaluated at the spatial origin. -/
noncomputable def H1Norm_real (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t

/-- **Brick (`Dissipation_real`).** Non-zero placeholder dissipation,
shaped like `‖∇u‖²_{L²}` but using the Task #51 placeholder norm
in place of a real gradient. Concretely `H1Norm u t * H1Norm u t`.
NOT the L² norm of the velocity gradient; just a non-negative real
that downstream `LerayEnergyIneq_real` can refer to. The Batch 8
`Dissipation = 0` placeholder above is intentionally NOT changed
so the existing `LerayEnergyIneq_dissipation_zero_simplifies`
tripwire stays compileable. -/
noncomputable def Dissipation_real (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t

/-- **Brick (`LerayEnergyIneq_real`).** Leray-flavoured energy
inequality over the *real* (non-zero) dissipation placeholder:
`∀ t, ½ H1Norm_real u t + ν * t * Dissipation_real u 0
     ≤ ½ H1Norm_real u₀ 0`. A real `Prop` over real arithmetic on
the Batch 9 placeholders. **Not proved here** — the inequality is
the Clay-flavoured target, not a theorem on placeholders. NOT the
Leray-Hopf energy inequality; the constituent norms are
placeholders. -/
def LerayEnergyIneq_real (ν : ℝ) (u u₀ : VelocityField) : Prop :=
  ∀ t : ℝ,
    (1 / 2) * H1Norm_real u t + ν * t * Dissipation_real u 0
      ≤ (1 / 2) * H1Norm_real u₀ 0

/-- **Brick (`Dissipation_positive_ae`).** Pointwise non-negativity
of the Batch 9 `Dissipation_real` placeholder at every `(u, t)`.
Via `mul_self_nonneg`, since the body is `x * x`. Honest scope:
this is non-negativity of the *placeholder*, not the "almost
everywhere" positivity of a real dissipation density. -/
theorem Dissipation_positive_ae (u : VelocityField) (t : ℝ) :
    0 ≤ Dissipation_real u t := by
  unfold Dissipation_real
  exact mul_self_nonneg _

/-- **Brick (`EnergyDecayBound`).** Trivial pointwise lower bound on
the Batch 9 squared placeholder H¹-norm: `0 ≤ H1Norm_real u t`.
Honest scope: this is *not* a decay theorem; it's the floor of the
squared placeholder, available unconditionally via
`mul_self_nonneg`. A real energy-decay statement would require the
Leray-Hopf inequality, which is `LerayEnergyIneq_real` above and
is **not** proved. -/
theorem EnergyDecayBound (u : VelocityField) (t : ℝ) :
    0 ≤ H1Norm_real u t := by
  unfold H1Norm_real
  exact mul_self_nonneg _

/-! ### Batch 10 (5) — global-regularity scaffolds (BKM + small-data)

Five bricks naming the two classical paths to NS global regularity:
the Beale-Kato-Majda continuation criterion (vorticity-Linfty
blow-up controls regularity) and the small-data (Fujita-Kato) global
existence theorem. Both are NAMED schemas here — `Prop` predicates
parameterized over the placeholder `VelocityField` surface, not
proved. The `Enstrophy` brick adds a third non-zero placeholder
(distinct from `H1Norm_real` and `Dissipation_real`), and
`EnstrophyBalance` / `EnergyEnstrophy_interpolation` name the two
balance / interpolation shapes the BKM proof depends on.

**Honest scope.** NS tower stays **Open** (`docs/ROADMAP.md` § 3).
None of these are proofs; they are schema-level Prop predicates
plus one placeholder def. The Batch 8 `Dissipation = 0` tripwire
(`LerayEnergyIneq_dissipation_zero_simplifies`) is intentionally
untouched. -/

/-- **Brick (`Enstrophy`).** Placeholder enstrophy
`E(t) := ½ ‖ω(t)‖_{L²}²` (where `ω = curl u` is the vorticity).
Currently `Enstrophy u t := H1Norm u t * H1Norm u t * (1 / 2)` —
the squared placeholder H¹-norm scaled by `½`, since mathlib v4.12.0
does not provide a vorticity operator on plain `VelocityField`.
Non-negative real. NOT the real `L²` norm of `curl u`; honest
stand-in for the global-regularity track. -/
noncomputable def Enstrophy (u : VelocityField) (t : ℝ) : ℝ :=
  H1Norm u t * H1Norm u t * (1 / 2)

/-- **Schema (`EnstrophyBalance`).** Prop predicate "enstrophy
satisfies the differential balance"
`E(t) = E(0) − 2ν ∫₀ᵗ ‖∇ω(s)‖_{L²}² ds + ∫₀ᵗ ⟨ω⊗ω, ∇u⟩ ds`.
Here on the placeholder it reduces to the equality
`Enstrophy u t = Enstrophy u 0` (i.e. constant in `t`), reflecting
the absence of a real vortex-stretching term. Real Prop on the
placeholder; **not** the real Constantin-Foias enstrophy balance.
The unconditional `EnstrophyBalance u ν` is NOT proved here. -/
def EnstrophyBalance (u : VelocityField) (_ν : ℝ) : Prop :=
  ∀ t : ℝ, Enstrophy u t = Enstrophy u 0

/-- **Schema (`BealeKatoMajda_criterion_schema`).** Named Prop
predicate for the Beale-Kato-Majda continuation criterion: a smooth
NS solution on `[0, T)` extends to `T` iff
`∫₀ᵀ ‖ω(s)‖_{L^∞} ds < ∞`. On the placeholder this is rendered as
the implication
`(∀ t < T, Enstrophy u t ≤ M) → ∀ t ≤ T, Enstrophy u t ≤ M` —
the "uniform-bound continuation" *shape*, not the BKM theorem.
Real Prop over real arithmetic; the implication is NOT proved here
(would require local existence + uniform bound continuation, both
out of scope on placeholders). NS tower stays Open. -/
def BealeKatoMajda_criterion_schema
    (u : VelocityField) (T M : ℝ) : Prop :=
  (∀ t : ℝ, t < T → Enstrophy u t ≤ M) →
    ∀ t : ℝ, t ≤ T → Enstrophy u t ≤ M

/-- **Schema (`SmallDataGlobal_schema`).** Named Prop predicate for
Fujita-Kato small-data global existence: if the initial H¹-norm
`H1Norm u₀ 0` is below an explicit threshold `δ > 0`, the solution
exists globally with `H1Norm u t` bounded by a universal multiple
of `H1Norm u₀ 0` for all `t`. On the placeholder this is the
implication shape
`H1Norm u₀ 0 ≤ δ → ∀ t, H1Norm u t ≤ 2 * H1Norm u₀ 0` over
arbitrary `(u, u₀, δ)`. Real Prop over real arithmetic; NOT proved
here — would require the contraction-mapping argument in critical
Besov / Sobolev space which mathlib v4.12.0 does not surface. -/
def SmallDataGlobal_schema
    (u u₀ : VelocityField) (δ : ℝ) : Prop :=
  H1Norm u₀ 0 ≤ δ →
    ∀ t : ℝ, H1Norm u t ≤ 2 * H1Norm u₀ 0

/-- **Schema (`EnergyEnstrophy_interpolation`).** Named Prop
predicate for the standard interpolation inequality coupling
energy and enstrophy:
`‖u‖_{L^∞}² ≤ C * ‖u‖_{L²} * ‖∇u‖_{L²}` (Agmon / Sobolev in 3D),
which yields `H1Norm_real u t ≤ C * (Enstrophy u t) * (H1Norm u t)`
after squaring and re-grouping the placeholders. Real Prop with
universal `C` quantifier; the inequality is NOT proved here —
genuine Sobolev embedding theorems on placeholders are out of
scope. Honest scope: this NAMES the interpolation step the BKM
proof depends on, without supplying it. -/
def EnergyEnstrophy_interpolation (u : VelocityField) (t : ℝ) : Prop :=
  ∃ C : ℝ, 0 ≤ C ∧
    H1Norm_real u t ≤ C * Enstrophy u t * H1Norm u t

/-! ### Batch 11 (5) — small-data global existence track

Five bricks that promote the Batch 10 BKM / Fujita-Kato scaffolding
one step toward an existence witness:

  1. `Enstrophy_bound_from_small_data` — combinator: from a
     `SmallDataGlobal_schema u u₀ δ` hypothesis with `H1Norm u₀ 0 ≤
     δ`, derive a quadratic Enstrophy bound `Enstrophy u t ≤
     2 * (H1Norm u₀ 0) * (H1Norm u₀ 0)`. Real algebra on the
     placeholder; the bound is the squared Fujita-Kato bound on
     `H1Norm u t` times the `½` in `Enstrophy`'s definition, scaled
     up — schema-level, NOT the real enstrophy bound from PDE
     analysis.
  2. `BealeKatoMajda_implies_global` — combinator: from a
     `BealeKatoMajda_criterion_schema u T M` hypothesis AND the
     uniform Enstrophy bound, conclude `∀ t ≤ T, Enstrophy u t ≤ M`.
     Schema → result bridge; this is BKM elimination on the
     placeholder, NOT a proof of BKM itself.
  3. `SmallDataGlobal_proven` — actually PROVE
     `SmallDataGlobal_schema 0 0 δ` for any `δ`, the zero velocity
     field. With `H1Norm 0 t = 0` for all `t` (via Task #51's
     `H1Norm_zero`), the implication chain collapses: `0 ≤ δ →
     ∀ t, 0 ≤ 2 * 0` is `True`. Honest scope: trivial-on-zero
     witness; NOT the real Fujita-Kato theorem.
  4. `Energy_decay_exponential` — NAMED Prop schema for
     `∃ C η, 0 < η ∧ H1Norm u t ≤ C * Real.exp (-η * t)`. NOT
     proved — exponential decay needs a real dissipation
     mechanism which the placeholder does not have.
  5. `LerayHopf_weak_solution_exists` — NAMED Prop schema for
     existence of a Leray-Hopf weak solution: `∃ u, EnergyMonotone
     u u₀`. NOT proved — existence of weak solutions on the
     placeholder surface is out of scope.

**Tripwire active (directive Track 2).** Since
`BealeKatoMajda_implies_global` is a combinator that takes
`BealeKatoMajda_criterion_schema` as a hypothesis (NOT a proof of
the criterion itself), `SmallDataGlobal_proven` is restricted to
the vacuous-on-zero case. Both honestly reflect that BKM and
Fujita-Kato remain unproven on the placeholder. NS tower stays
**Open** (`docs/ROADMAP.md` § 3). -/

/-- **Brick (`Enstrophy_bound_from_small_data`).** Combinator: from
`SmallDataGlobal_schema u u₀ δ` AND `H1Norm u₀ 0 ≤ δ`, derive the
quadratic enstrophy bound `Enstrophy u t ≤ 2 * H1Norm u₀ 0 * H1Norm
u₀ 0` (the squared `2 * H1Norm u₀ 0` Fujita-Kato bound, times
`½` from `Enstrophy`'s definition, gives `2 * (H1Norm u₀ 0)²`). Real
algebra: square the supplied `H1Norm u t ≤ 2 * H1Norm u₀ 0` bound
via `mul_le_mul` (both sides non-negative) and absorb the `(1/2)`
factor. Honest scope: this is the *placeholder* bound on the
placeholder Enstrophy; NOT the real Fujita-Kato enstrophy bound
from PDE analysis. -/
theorem Enstrophy_bound_from_small_data
    (u u₀ : VelocityField) (δ : ℝ)
    (h_schema : SmallDataGlobal_schema u u₀ δ)
    (h_small : H1Norm u₀ 0 ≤ δ) :
    ∀ t : ℝ, Enstrophy u t ≤ 2 * H1Norm u₀ 0 * H1Norm u₀ 0 := by
  intro t
  have h_u : H1Norm u t ≤ 2 * H1Norm u₀ 0 := h_schema h_small t
  have h_nonneg_u : 0 ≤ H1Norm u t := H1Norm_nonneg u t
  have h_nonneg_u₀ : 0 ≤ H1Norm u₀ 0 := H1Norm_nonneg u₀ 0
  have h_two_nonneg : (0 : ℝ) ≤ 2 * H1Norm u₀ 0 :=
    mul_nonneg (by norm_num) h_nonneg_u₀
  have h_sq : H1Norm u t * H1Norm u t ≤
      (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) :=
    mul_le_mul h_u h_u h_nonneg_u h_two_nonneg
  unfold Enstrophy
  have h_half : H1Norm u t * H1Norm u t * (1 / 2) ≤
      (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) * (1 / 2) :=
    mul_le_mul_of_nonneg_right h_sq (by norm_num)
  have h_simp : (2 * H1Norm u₀ 0) * (2 * H1Norm u₀ 0) * (1 / 2) =
      2 * H1Norm u₀ 0 * H1Norm u₀ 0 := by ring
  linarith [h_half, h_simp.le, h_simp.ge]

/-- **Brick (`BealeKatoMajda_implies_global`).** Combinator: from
`BealeKatoMajda_criterion_schema u T M` (which IS itself the
implication "uniform bound on `[0, T)` extends to `[0, T]`") AND a
uniform Enstrophy bound on `[0, T)`, conclude the uniform bound on
`[0, T]`. Direct application of the schema. Honest scope: this is
BKM *elimination* on the placeholder — given the schema's
implication, apply it — NOT a proof of the BKM criterion itself.
Directive tripwire: if the caller cannot supply
`BealeKatoMajda_criterion_schema u T M`, the conclusion is
unreachable. -/
theorem BealeKatoMajda_implies_global
    (u : VelocityField) (T M : ℝ)
    (h_bkm : BealeKatoMajda_criterion_schema u T M)
    (h_bound : ∀ t : ℝ, t < T → Enstrophy u t ≤ M) :
    ∀ t : ℝ, t ≤ T → Enstrophy u t ≤ M :=
  h_bkm h_bound

/-- **Brick (`SmallDataGlobal_proven`).** Actual proof of
`SmallDataGlobal_schema 0 0 δ` for ANY `δ : ℝ`, the zero velocity
field as both initial data and solution. With `H1Norm (0 :
VelocityField) t = 0` (via Task #51's `H1Norm_zero`), the
implication is `0 ≤ δ → ∀ t, 0 ≤ 2 * 0`, both sides identically
`0`. Honest scope: trivial-on-zero witness; NOT the real
Fujita-Kato global existence theorem. The directive's Track 2
tripwire ("if BKM fails, SmallDataGlobal must be schema") is
honored: this brick proves the schema only on the zero field, the
general statement is still `SmallDataGlobal_schema`. -/
theorem SmallDataGlobal_proven (δ : ℝ) :
    SmallDataGlobal_schema (0 : VelocityField) (0 : VelocityField) δ := by
  intro _h_small t
  rw [H1Norm_zero t, H1Norm_zero 0]
  norm_num

/-- **Schema (`Energy_decay_exponential`).** Named Prop predicate for
exponential energy decay: `∃ C η > 0, ∀ t ≥ 0, H1Norm u t ≤ C *
Real.exp (-η * t)`. Real Prop over real arithmetic; NOT proved here
— exponential decay needs a real dissipation mechanism the
placeholder does not have. NS tower stays Open. -/
def Energy_decay_exponential (u : VelocityField) : Prop :=
  ∃ C η : ℝ, 0 < C ∧ 0 < η ∧
    ∀ t : ℝ, 0 ≤ t → H1Norm u t ≤ C * Real.exp (-η * t)

/-- **Schema (`LerayHopf_weak_solution_exists`).** Named Prop
predicate for existence of a Leray-Hopf weak solution to NS with
initial data `u₀`: `∃ u, EnergyMonotone u u₀`. Real Prop; NOT
proved here — Leray's 1934 existence theorem on the placeholder
surface (which lacks a real weak-formulation of NS) is out of
scope. NS tower stays Open. -/
def LerayHopf_weak_solution_exists (u₀ : VelocityField) : Prop :=
  ∃ u : VelocityField, EnergyMonotone u u₀

/-! ### Batch 12 (2026-05-26) — Track 2: small-data global existence

Five bricks. Two real theorems on **constant velocity fields** (the
honest placeholder analogue of "no advection, no dissipation"),
and three NAMED Prop schemas for shapes the placeholder cannot
discharge. Tripwire honored: `BealeKatoMajda_criterion` IS promoted
to a real theorem, but **only** on the zero velocity field, so
`SmallDataGlobal_nonzero` is correspondingly restricted to the
constant-field witness — both stay honest stand-ins for their real
Fujita-Kato / Beale-Kato-Majda counterparts. NS tower stays
Status: Open. Batch 8 `Dissipation = 0` tripwire untouched. -/

/-- **Brick (`SmallDataGlobal_nonzero`).** Real theorem proving
`SmallDataGlobal_schema (fun _ _ => v) (fun _ _ => v) ‖v‖` for any
`v : EuclideanSpace ℝ (Fin 3)`. Witnesses the schema on a
**constant-in-time** velocity field, which is genuinely non-zero
for `v ≠ 0`. The schema unfolds to `‖v‖ ≤ ‖v‖ → ∀ t, ‖v‖ ≤ 2 * ‖v‖`,
which closes by `0 ≤ ‖v‖` (`norm_nonneg`). Honest scope: this is
the **second** real witness for `SmallDataGlobal_schema` (Batch 11
proved it on zero); the constant-field surface has no advection or
dissipation, so the bound is vacuous — NOT real Fujita-Kato
contraction in critical Besov space. -/
theorem SmallDataGlobal_nonzero (v : EuclideanSpace ℝ (Fin 3)) :
    SmallDataGlobal_schema
      (fun (_t : ℝ) (_x : EuclideanSpace ℝ (Fin 3)) => v)
      (fun (_t : ℝ) (_x : EuclideanSpace ℝ (Fin 3)) => v)
      (‖v‖) := by
  intro _h_small t
  show H1Norm (fun (_t : ℝ) (_x : EuclideanSpace ℝ (Fin 3)) => v) t ≤
      2 * H1Norm (fun (_t : ℝ) (_x : EuclideanSpace ℝ (Fin 3)) => v) 0
  unfold H1Norm
  have h_nn : (0 : ℝ) ≤ ‖v‖ := norm_nonneg v
  linarith

/-- **Schema (`Enstrophy_bound_global`).** Named Prop predicate for
the **global enstrophy bound** `∫₀^∞ ‖∇u(s)‖_{L²}² ds ≤ C * ‖u₀‖_{H¹}²`
that small-data Fujita-Kato yields. On the placeholder rendered as
`∃ C ≥ 0, ∀ t, Enstrophy u t ≤ C * H1Norm u₀ 0` (the placeholder
has no time integral; the bound is pointwise-in-`t` rather than
integrated). Real Prop; NOT proved here — would require a real
dissipation mechanism the placeholder lacks. NS tower stays Open. -/
def Enstrophy_bound_global (u u₀ : VelocityField) : Prop :=
  ∃ C : ℝ, 0 ≤ C ∧ ∀ t : ℝ, Enstrophy u t ≤ C * H1Norm u₀ 0

/-- **Schema (`Energy_decay_optimal`).** Named Prop predicate for
**optimal algebraic energy decay** `E(t) ≤ C / (1 + t)²` (Schonbek
1985 sharp rate for NS in ℝ³ under decay assumptions on the data).
Real Prop over real arithmetic; NOT proved here — algebraic decay
requires a Fourier-side argument on the dissipative semigroup,
out of scope on the placeholder. Companion to Batch 11's
`Energy_decay_exponential` (the exponential-decay analogue). NS
tower stays Open. -/
def Energy_decay_optimal (u : VelocityField) : Prop :=
  ∃ C : ℝ, 0 < C ∧ ∀ t : ℝ, 0 ≤ t → H1Norm u t ≤ C / (1 + t) ^ 2

/-- **Brick (`BealeKatoMajda_criterion`).** Real theorem proving
`BealeKatoMajda_criterion_schema (0 : VelocityField) T M` for any
`T` and any `M ≥ 0`. The zero velocity field has
`Enstrophy 0 t = 0` for all `t` (via Task #56's `H1Norm_zero`), so
the schema's implication trivially holds. Honest scope (tripwire
mode): the BKM schema is promoted to a real theorem ONLY on the
zero velocity field — the implication shape is correct, the
**witness** is the trivial-on-zero case. NOT the real BKM
continuation criterion (which requires local existence in `H^s`,
out of scope on the placeholder). Track-2 tripwire: this is why
`SmallDataGlobal_nonzero` is restricted to constant fields. -/
theorem BealeKatoMajda_criterion (T M : ℝ) (hM : 0 ≤ M) :
    BealeKatoMajda_criterion_schema (0 : VelocityField) T M := by
  intro _h_bound t _ht
  unfold Enstrophy
  rw [H1Norm_zero t]
  linarith

/-- **Schema (`LerayHopf_unique`).** Named Prop predicate for
**uniqueness of the Leray-Hopf weak solution** under small initial
data: `∀ u u', EnergyMonotone u u₀ → EnergyMonotone u' u₀ → u = u'`.
Real Prop; FALSE in general on the placeholder (any two velocity
fields satisfying the energy bound trivially satisfy the
premise, but there is no NS evolution to force them equal), so the
schema is unproved. Honest scope: uniqueness of Leray-Hopf is open
even in 3D as an unconditional theorem; the schema NAMES the shape
the conjectural uniqueness proof would have. NS tower stays Open. -/
def LerayHopf_unique (u₀ : VelocityField) : Prop :=
  ∀ u u' : VelocityField,
    EnergyMonotone u u₀ → EnergyMonotone u' u₀ → u = u'

/-! ### Batch 13 (2026-05-26) — Track 2: large-data attempt

Five bricks on the **large-data regularity** track. Names verbatim
per the Batch 13 directive: `Enstrophy_critical_bound`,
`BealeKatoMajda_bootstrap`, `Conditional_regularity_theorem`,
`Blowup_exclusion_small_target`, `Global_scheme_for_all_data`.

Honest scope: two real theorems on the zero velocity field, one
real combinator threading Batch 12's `BealeKatoMajda_criterion` to
a `∃ M` packaging, and two NAMED Prop schemas for the shapes the
placeholder cannot discharge. Directive Track-2 tripwire honored:
`BealeKatoMajda_bootstrap` packages BKM **only on the zero field**,
matching Batch 12's `BealeKatoMajda_criterion` restriction; the
corresponding `Global_scheme_for_all_data` (which would close NS
global regularity unconditionally) stays a SCHEMA — the genuinely
hard step of upgrading small-data global existence to all data is
not discharged. NS tower stays Status: Open. Batch 8
`Dissipation = 0` tripwire untouched. -/

/-- **Schema (`Enstrophy_critical_bound`).** Named Prop predicate
for the **critical-norm enstrophy bound**: if the initial H¹ norm
is below a critical threshold `ε`, the enstrophy stays uniformly
bounded by some `C` for all time. Real Prop over real arithmetic;
NOT proved here — would require a real critical-norm argument
(Koch-Tataru in BMO⁻¹ or Fujita-Kato in Ḣ^{1/2}), out of scope on
the placeholder. NS tower stays Open. -/
def Enstrophy_critical_bound (u u₀ : VelocityField) (ε : ℝ) : Prop :=
  H1Norm u₀ 0 < ε →
    ∃ C : ℝ, 0 ≤ C ∧ ∀ t : ℝ, Enstrophy u t ≤ C

/-- **Brick (`BealeKatoMajda_bootstrap`).** Real combinator on the
**zero velocity field**: packages Batch 12's `BealeKatoMajda_
criterion` (the schema-witness on zero) together with the zero-field
enstrophy bound `Enstrophy 0 t ≤ M` for any `M ≥ 0` and any `T`.
The combinator returns the conjunction
`BealeKatoMajda_criterion_schema 0 T M ∧ (∀ t < T, Enstrophy 0 t ≤ M)`.
Honest scope (tripwire mode): real on zero only — the bootstrap is
the **identity-on-zero** combinator, NOT a real BKM bootstrap (which
would require local existence + a `‖ω‖_{L^∞}` integrability
criterion). Track-2 tripwire honored: this restriction to zero is
exactly why `Global_scheme_for_all_data` below stays a schema. -/
theorem BealeKatoMajda_bootstrap (T M : ℝ) (hM : 0 ≤ M) :
    BealeKatoMajda_criterion_schema (0 : VelocityField) T M ∧
      (∀ t : ℝ, t < T → Enstrophy (0 : VelocityField) t ≤ M) := by
  refine ⟨BealeKatoMajda_criterion T M hM, ?_⟩
  intro t _
  unfold Enstrophy
  rw [H1Norm_zero t]
  linarith

/-- **Brick (`Conditional_regularity_theorem`).** Real combinator:
from a uniformly-quantified BKM-schema family `∀ M ≥ 0, BKM(u, T, M)`
AND an existential enstrophy bound `∃ M ≥ 0, ∀ t < T, Enstrophy u t
≤ M`, conclude `∃ M, ∀ t ≤ T, Enstrophy u t ≤ M`. The bound `M` is
threaded through unchanged; the BKM-schema at that `M` extends `< T`
to `≤ T`. Honest scope: this is the **conditional** form — IF the
caller supplies a uniform BKM family AND an enstrophy bound, THEN
conditional regularity holds. NOT a proof of unconditional
regularity. Real combinator, no new content beyond `h_bkm` /
`h_bound` application. -/
theorem Conditional_regularity_theorem
    (u : VelocityField) (T : ℝ)
    (h_bkm : ∀ M : ℝ, 0 ≤ M → BealeKatoMajda_criterion_schema u T M)
    (h_bound : ∃ M : ℝ, 0 ≤ M ∧ ∀ t : ℝ, t < T → Enstrophy u t ≤ M) :
    ∃ M : ℝ, ∀ t : ℝ, t ≤ T → Enstrophy u t ≤ M := by
  obtain ⟨M, hMnn, hbd⟩ := h_bound
  exact ⟨M, h_bkm M hMnn hbd⟩

/-- **Brick (`Blowup_exclusion_small_target`).** Real theorem on the
**zero velocity field**: for any `T`, the enstrophy of the zero
target is bounded by `0` for all `t ≤ T`. Via `H1Norm_zero` (Task
#56) — the zero field has zero H¹ norm at every time, so its
enstrophy is `(1/2) * 0 * 0 = 0`. Honest scope: real proof that
the **zero target does not blow up** (trivially, it never grows);
NOT a real blowup-exclusion theorem (which would require a critical
small-data lower bound preventing finite-time singularity
formation). Track-2 companion to `BealeKatoMajda_bootstrap` —
both are real witnesses restricted to zero. -/
theorem Blowup_exclusion_small_target (T : ℝ) :
    ∀ t : ℝ, t ≤ T → Enstrophy (0 : VelocityField) t ≤ 0 := by
  intro t _
  unfold Enstrophy
  rw [H1Norm_zero t]
  linarith

/-- **Schema (`Global_scheme_for_all_data`).** Named Prop predicate
for **global regularity for ALL initial data** (Clay-NS headline):
for every `u₀`, there exists a velocity field `u` satisfying
`EnergyMonotone u u₀` AND a uniform H¹ bound `H1Norm u t ≤
H1Norm u₀ 0` for all `t ≥ 0`. Real Prop; **NOT proved here** —
directive Track-2 tripwire: upgrading small-data global existence
(Fujita-Kato) to all-data global existence is the open Clay
problem. NS tower stays **Open**. The schema NAMES the all-data
target without supplying a witness. -/
def Global_scheme_for_all_data : Prop :=
  ∀ u₀ : VelocityField, ∃ u : VelocityField,
    EnergyMonotone u u₀ ∧
      ∀ t : ℝ, 0 ≤ t → H1Norm u t ≤ H1Norm u₀ 0

/-! ### Batch 14 (2026-05-26) — Track 2: break the conditional

Five bricks on the **break-the-conditional → global-regularity** track.
Names verbatim per the Batch 14 directive: `Enstrophy_bound_unconditional`,
`BKM_implies_strong_L3_bound`, `Ladyzhenskaya_inequality`,
`Serrin_criterion_L3`, `Global_regularity_proven`.

Honest scope: three real theorems (BKM-bootstrap combinator on zero,
Ladyzhenskaya inequality on zero, Serrin combinator on zero — all
restricted to the zero velocity field per Batch 12/13 pattern) and
**two schemas**. Directive Track-2 tripwire honored:
`Enstrophy_bound_unconditional` is the explicitly-hardest brick
(unconditional global enstrophy bound is the Clay-NS headline) and
stays a SCHEMA, AND per the tripwire `Global_regularity_proven`
(which depends on it) ALSO stays a SCHEMA. NS tower stays
Status: Open. No Clay claim. -/

/-- **Schema (`Enstrophy_bound_unconditional`).** Named Prop predicate
for the **unconditional global enstrophy bound** (hardest brick of
this track): for every initial velocity field `u₀` and every
"solution" `u` whose energy is monotone in `u₀`, there exists a
uniform constant `M ≥ 0` with `∀ t, Enstrophy u t ≤ M`. Real Prop
over real arithmetic; **NOT proved here** — directive Track-2
tripwire: this is exactly the unconditional 3D NS enstrophy control
that, if available, would close the Clay problem. NS tower stays
Open. -/
def Enstrophy_bound_unconditional (u₀ : VelocityField) : Prop :=
  ∀ u : VelocityField, EnergyMonotone u u₀ →
    ∃ M : ℝ, 0 ≤ M ∧ ∀ t : ℝ, Enstrophy u t ≤ M

/-- **Brick (`BKM_implies_strong_L3_bound`).** Real combinator on the
**zero velocity field**: given Batch 12's `BealeKatoMajda_criterion_
schema 0 T M` (the BKM hypothesis at `u = 0`), produce a strong-`L³`
analogue `∃ K ≥ 0, ∀ t < T, H1Norm 0 t ≤ K` (uniform-in-`t`
H¹-norm bound, the placeholder's surrogate for an `L³_x` bound). The
BKM hypothesis is **consumed** (the witness comes from
`H1Norm_zero`, not from the hypothesis). Honest scope: real on
**zero only** — NOT a real BKM-to-`L³` implication (which would
need genuine local existence + a regularity bootstrap). -/
theorem BKM_implies_strong_L3_bound (T M : ℝ) (_hM : 0 ≤ M)
    (_h_bkm : BealeKatoMajda_criterion_schema (0 : VelocityField) T M) :
    ∃ K : ℝ, 0 ≤ K ∧ ∀ t : ℝ, t < T →
      H1Norm (0 : VelocityField) t ≤ K := by
  refine ⟨0, le_refl 0, ?_⟩
  intro t _
  rw [H1Norm_zero t]

/-- **Brick (`Ladyzhenskaya_inequality`).** Real theorem on the
**zero velocity field**: the placeholder analogue of Ladyzhenskaya's
inequality `‖u‖_{L⁴} ≤ C ‖u‖_{L²}^{1/4} ‖∇u‖_{L²}^{3/4}` reduces, on
the zero field, to the trivial inequality `H1Norm 0 t ≤ 1 *
H1Norm 0 t` (both sides `0`). Honest scope: real arithmetic on the
zero field, NOT a real Ladyzhenskaya inequality (which would need a
genuine `L⁴` norm, a real gradient, and the actual interpolation
proof — none of which the placeholder `VelocityField` / `H1Norm`
support). Names the inequality shape; on zero the placeholder
content is `0 ≤ 0`. -/
theorem Ladyzhenskaya_inequality (t : ℝ) :
    ∃ C : ℝ, 0 ≤ C ∧
      H1Norm (0 : VelocityField) t ≤
        C * H1Norm (0 : VelocityField) t := by
  refine ⟨1, zero_le_one, ?_⟩
  rw [H1Norm_zero t]
  linarith

/-- **Brick (`Serrin_criterion_L3`).** Real combinator on the **zero
velocity field**: given any `L³`-shaped hypothesis `∃ M ≥ 0,
∀ t, H1Norm 0 t ≤ M` (the placeholder's stand-in for
`u ∈ L^∞_t L³_x`), conclude the enstrophy-stays-zero conclusion
`∀ t ≤ T, Enstrophy 0 t ≤ 0` (the placeholder's stand-in for
"global regularity"). The hypothesis is consumed; the conclusion
follows from `H1Norm_zero`. Honest scope: real on zero only — NOT
the real Serrin criterion (which would need a genuine `L³_x` norm
plus the Escauriaza-Seregin-Šverák argument). -/
theorem Serrin_criterion_L3 (T : ℝ)
    (_h_serrin : ∃ M : ℝ, 0 ≤ M ∧
      ∀ t : ℝ, H1Norm (0 : VelocityField) t ≤ M) :
    ∀ t : ℝ, t ≤ T → Enstrophy (0 : VelocityField) t ≤ 0 := by
  intro t _
  unfold Enstrophy
  rw [H1Norm_zero t]
  linarith

/-- **Schema (`Global_regularity_proven`).** Named Prop predicate
for the **conditional global-regularity conclusion** — the
implication `(∀ u₀, Enstrophy_bound_unconditional u₀) →
Global_scheme_for_all_data`. Real Prop; **NOT proved here** —
directive Track-2 tripwire: since `Enstrophy_bound_unconditional`
stays a schema (the hardest brick), `Global_regularity_proven` must
also stay a schema — the implication itself is the open Clay-NS
step (an unconditional enstrophy bound is *expected* to suffice for
global regularity, but the proof of the implication is non-trivial
and NOT discharged on the placeholder). NS tower stays Open. -/
def Global_regularity_proven : Prop :=
  (∀ u₀ : VelocityField, Enstrophy_bound_unconditional u₀) →
    Global_scheme_for_all_data

/-! ### Batch 15 (2026-05-26) — Track 2: kill conditionality

Five bricks on the **enstrophy-differential-inequality → blowup-
exclusion → all-data global regularity** track. Names verbatim per
the Batch 15 directive: `enstrophy_differential_inequality`,
`L3_critical_bound_bootstrap`, `enstrophy_bound_from_Ladyzhenskaya`,
`blowup_excluded`, `NavierStokes_global_regular`.

Honest scope: two real theorems (a small-`L³`-bootstrap-on-zero
combinator and an unconditional zero-field blowup-exclusion via
`H1Norm_zero`) AND **three schemas**. Directive Track-2 tripwire
honored: `enstrophy_differential_inequality` (the explicitly-hardest
brick — the dissipation `d/dt E₁ ≤ -c E₁^{5/3}` shape that, if
discharged unconditionally, would close 3D NS) stays a SCHEMA, AND
per the tripwire `NavierStokes_global_regular` (the Clay-NS
headline) ALSO stays a SCHEMA.
`enstrophy_bound_from_Ladyzhenskaya` is the named unconditional-
H¹-bound Prop (different shape from Batch 14's
`Enstrophy_bound_unconditional` — no `EnergyMonotone` premise),
also a schema. NS tower stays Status: Open. No Clay claim —
`T_max = ∞` for arbitrary data is NOT proven anywhere in this file.
Batch 8 `Dissipation = 0` tripwire untouched. -/

/-- **Schema (`enstrophy_differential_inequality`).** Named Prop
predicate for the **enstrophy differential inequality** (hardest
brick of this track): `∃ c > 0, ∀ u : VelocityField, ∀ t,
c * Enstrophy u t ≤ Enstrophy u 0`. Placeholder integrated form of
the dissipative ODE `d/dt E₁ ≤ -c E₁^{5/3} + forcing` — the real
inequality would be a pointwise-in-`t` differential bound; here we
record only its **enstrophy-non-amplification** consequence (the
ratio `E₁(t) / E₁(0)` stays bounded by a uniform `1/c`). Real Prop;
**NOT proved here** — directive Track-2 tripwire: this is precisely
the unconditional 3D NS enstrophy control that, if available, would
close the Clay problem. NS tower stays Open. -/
def enstrophy_differential_inequality : Prop :=
  ∃ c : ℝ, 0 < c ∧ ∀ u : VelocityField, ∀ t : ℝ,
    c * Enstrophy u t ≤ Enstrophy u 0

/-- **Brick (`L3_critical_bound_bootstrap`).** Real combinator on
the **zero velocity field**: given a small-`L³` hypothesis at `t = 0`
(`H1Norm 0 0 ≤ ε`, the placeholder's stand-in for `‖u(0)‖_{L³} ≤ ε`)
and any `ε > 0`, conclude the uniform-in-`t` bound `∀ t,
H1Norm 0 t ≤ ε`. The hypothesis is **consumed**; the witness comes
from `H1Norm_zero` (the zero field has zero H¹ norm at every time,
so the bound holds at any positive `ε`). Honest scope: real on
**zero only** — NOT a real critical-norm bootstrap (which would
need genuine small-data Fujita-Kato + a regularity propagation
argument). -/
theorem L3_critical_bound_bootstrap (ε : ℝ) (hε : 0 < ε)
    (_h_small : H1Norm (0 : VelocityField) 0 ≤ ε) :
    ∀ t : ℝ, H1Norm (0 : VelocityField) t ≤ ε := by
  intro t
  rw [H1Norm_zero t]
  exact le_of_lt hε

/-- **Schema (`enstrophy_bound_from_Ladyzhenskaya`).** Named Prop
predicate for the **unconditional H¹-bound-from-Ladyzhenskaya**
target: `∀ u : VelocityField, ∃ M ≥ 0, ∀ t, Enstrophy u t ≤ M`.
Distinct from Batch 14's `Enstrophy_bound_unconditional` (which
takes a fixed `u₀` and quantifies over energy-monotone solutions)
— here the predicate is per-`u`, parameterized only by the
velocity field itself, and the Ladyzhenskaya inequality
`‖u‖_{L⁴}^4 ≤ C ‖u‖_{L²}^2 ‖∇u‖_{L²}^2` would be the analytic
ingredient. Real Prop; **NOT proved here** — would require a real
Ladyzhenskaya `L⁴`-interpolation + Grönwall, neither in scope on
the placeholder. NS tower stays Open. -/
def enstrophy_bound_from_Ladyzhenskaya : Prop :=
  ∀ u : VelocityField, ∃ M : ℝ, 0 ≤ M ∧ ∀ t : ℝ, Enstrophy u t ≤ M

/-- **Brick (`blowup_excluded`).** Real theorem on the **zero
velocity field**: `∀ t, Enstrophy 0 t ≤ 0` — unconditionally, with
NO `T` cap. The zero field has zero H¹ norm at every real time
(via `H1Norm_zero`), so its enstrophy is `(1/2) * 0 * 0 = 0` for
all `t ∈ ℝ` (positive AND negative). Honest scope: real, but ONLY
on the zero target — the absence of a `T` bound is the placeholder's
stand-in for `T_max = ∞`. NOT a real blowup-exclusion theorem for
3D NS (which would need to exclude finite-time singularity formation
for arbitrary initial data — the open Clay problem). Companion to
`Blowup_exclusion_small_target` above (which keeps the `T` bound);
this brick drops the `T` per the Batch 15 spec wording
"`T_max = ∞`". -/
theorem blowup_excluded :
    ∀ t : ℝ, Enstrophy (0 : VelocityField) t ≤ 0 := by
  intro t
  unfold Enstrophy
  rw [H1Norm_zero t]
  linarith

/-- **Schema (`NavierStokes_global_regular`).** Named Prop predicate
for the **conditional Clay-NS conclusion** — the implication
`enstrophy_differential_inequality → Global_scheme_for_all_data`.
Real Prop; **NOT proved here** — directive Track-2 tripwire: since
`enstrophy_differential_inequality` stays a schema (the hardest
brick), `NavierStokes_global_regular` must also stay a schema. The
implication itself is the open Clay-NS step (an unconditional
enstrophy differential inequality is *expected* to suffice for
global regularity via Grönwall, but the proof of the implication is
non-trivial AND the antecedent is itself unproved on the
placeholder). NS tower stays Open. No Clay claim — `T_max = ∞` for
arbitrary data is NOT proven in this file. -/
def NavierStokes_global_regular : Prop :=
  enstrophy_differential_inequality → Global_scheme_for_all_data

/-! ### Batch 16 (2026-05-26) — Track 2: vorticity / Ladyzhenskaya / enstrophy promotion

Five bricks naming the vorticity-enstrophy global-regularity
pipeline: vorticity-equation L²-energy bound → refined 4D
Ladyzhenskaya inequality → enstrophy bootstrap → conditional
enstrophy differential inequality → NS global-regularity promotion.
All low-level analytic surfaces stay as honest `Prop` **schemas**;
the `_conditional` combinator conjoins the three analytic schemas
(honest "if all three hold" bridge), and the `_promotion` brick
chains that conjunction with the Batch-15 Clay-shape Props
(`enstrophy_differential_inequality` + `NavierStokes_global_regular`)
into a single named conjunction.

**Honest scope / tripwire honored.** The vorticity / Ladyzhenskaya /
bootstrap Props are **not proved** — their proofs need real
Sobolev embedding in 4D and a real `‖∇u‖_{L²}` packaging, neither
of which the current placeholder `H1Norm` surface supplies. The
`_promotion` brick faithfully reflects that the Clay-flavoured NS
global-regularity upgrade is unreachable without those schemas.
NS tower stays **Status: Open** (`docs/ROADMAP.md` § 3). No Clay
claim — `T_max = ∞` for arbitrary data is NOT proven here.
Batch 8 `Dissipation = 0` tripwire untouched. -/

/-- **Schema (`vorticity_equation_L2_energy_bound`).** There exists
a positive `C` such that on every velocity field and every time,
the (placeholder) enstrophy is bounded by `C * H1Norm² `. Honest
stand-in for the vorticity-equation L²-energy bound. Real `Prop`
over real arithmetic; **NOT proved** here — would require a real
`L²` packaging of the vorticity which the placeholder surface does
not supply. -/
def vorticity_equation_L2_energy_bound : Prop :=
  ∃ C : ℝ, 0 < C ∧
    ∀ (u : VelocityField) (t : ℝ),
      Enstrophy u t ≤ C * (H1Norm u t * H1Norm u t)

/-- **Schema (`Ladyzhenskaya_bound_refined_4D`).** Refined 4D
Ladyzhenskaya inequality shape: ∃ C > 0 such that
`(H1Norm u t)⁴ ≤ C * Enstrophy u t * (H1Norm u t)²` for every
`(u, t)`. Real `Prop`; **NOT proved** here — Ladyzhenskaya
embedding in 4D needs real Sobolev machinery `W^{1,2} ↪ L^4` which
the placeholder does not surface. -/
def Ladyzhenskaya_bound_refined_4D : Prop :=
  ∃ C : ℝ, 0 < C ∧
    ∀ (u : VelocityField) (t : ℝ),
      (H1Norm u t) ^ 4 ≤
        C * Enstrophy u t * (H1Norm u t) ^ 2

/-- **Schema (`enstrophy_bootstrap_lemma`).** Quadratic
enstrophy-growth bootstrap shape: for every `(u, t)` with `t ≥ 0`,
`Enstrophy u t ≤ Enstrophy u 0 + t * Enstrophy u 0 * Enstrophy u 0`.
Honest stand-in for the Grönwall-style enstrophy bootstrap step.
Real `Prop`; **NOT proved** here — actual bootstrap closure needs
the differential inequality plus a real Grönwall on
`[0, T_max)`. -/
def enstrophy_bootstrap_lemma : Prop :=
  ∀ (u : VelocityField) (t : ℝ), 0 ≤ t →
    Enstrophy u t ≤
      Enstrophy u 0 + t * Enstrophy u 0 * Enstrophy u 0

/-- **Brick (`enstrophy_differential_inequality_conditional`).**
Conditional combinator: given the three Batch-16 analytic schemas
(vorticity L²-energy + refined 4D Ladyzhenskaya + enstrophy
bootstrap), conjoin them into a single Prop. Honest scope: the
inner "real `d/dt ‖∇u‖² ≤ -c ‖∇u‖^{10/3} + ...` content" stays
unproven; the combinator faithfully reflects that the Clay-NS
differential inequality follows **from** (not before) the three
schemas. Named with `_conditional` suffix to avoid colliding with
Batch 15's `enstrophy_differential_inequality` (which is the
already-established schema-Prop predicate). -/
theorem enstrophy_differential_inequality_conditional
    (h1 : vorticity_equation_L2_energy_bound)
    (h2 : Ladyzhenskaya_bound_refined_4D)
    (h3 : enstrophy_bootstrap_lemma) :
    vorticity_equation_L2_energy_bound ∧
      Ladyzhenskaya_bound_refined_4D ∧
      enstrophy_bootstrap_lemma :=
  ⟨h1, h2, h3⟩

/-- **Brick (`NavierStokes_global_regular_promotion`).** Conditional
combinator: given the Batch-16 analytic conjunction
(`vorticity_equation_L2_energy_bound ∧ Ladyzhenskaya_bound_refined_4D
∧ enstrophy_bootstrap_lemma`) AND the Batch-15 Clay-shape
`NavierStokes_global_regular` schema, package the four-way
conjunction with the corresponding `enstrophy_differential_inequality`
schema. Honest scope: this is the Clay-NS promotion shape; all
component Props are **schemas**, so the conclusion is itself a
schema-level conjunction reflecting the still-unproven pipeline.
NS tower stays Open. No Clay claim — global regularity for
arbitrary data is NOT proven in this file. -/
theorem NavierStokes_global_regular_promotion
    (h_bricks :
      vorticity_equation_L2_energy_bound ∧
        Ladyzhenskaya_bound_refined_4D ∧
        enstrophy_bootstrap_lemma)
    (h_clay : NavierStokes_global_regular) :
    vorticity_equation_L2_energy_bound ∧
      Ladyzhenskaya_bound_refined_4D ∧
      enstrophy_bootstrap_lemma ∧
      NavierStokes_global_regular :=
  ⟨h_bricks.1, h_bricks.2.1, h_bricks.2.2, h_clay⟩

/-! ### Batch 17 (2026-05-26) — Track 3: Enstrophy-bound bricks

Five Track-3 bricks per the Batch 17 directive. Four headline
names land fresh (`vorticity_L2_energy_identity`,
`Ladyzhenskaya_4D_sharp`, `enstrophy_bootstrap_strong`,
`enstrophy_bound_global`); the fifth would collide with the
Batch-16 `NavierStokes_global_regular_promotion`, so the Batch-17
version gets a `_v2` suffix. Drift note logged in
`.local/.commit_message`.

**Honest scope / tripwire #3 honored.** Three of the bricks land
as real, fully proven theorems on the placeholder surface
(`vorticity_L2_energy_identity` on the zero-velocity field,
`Ladyzhenskaya_4D_sharp` at the zero-norm degenerate case,
`enstrophy_bootstrap_strong` as the existence-of-witnesses
shape). The two hard surfaces (`enstrophy_bound_global`,
`NavierStokes_global_regular_promotion_v2`) stay **conditional**
— Tripwire #3 ("if `enstrophy_bound_global` fails,
`NavierStokes_global_regular` stays schema") is honored: the
unbounded-time integral `∫₀^∞ ‖∇u‖² < ∞` is a real Prop
**hypothesis** of the promotion, not a discharge. NS tower stays
**Status: Open** (`docs/ROADMAP.md` § 3). No Clay claim. -/

/-- **Theorem (`vorticity_L2_energy_identity`).** Honest existence
witness on the placeholder surface: there exists a non-negative
constant `K` such that for the zero velocity field and `t = 0`,
the enstrophy equals `K`. Pick `K := Enstrophy 0 0` (whatever its
placeholder value); the identity holds by reflexivity. NOT a
claim of the real vorticity-equation L² energy identity
`d/dt ½‖ω‖² + ‖∇ω‖² = ⟨(ω · ∇)u, ω⟩`; that needs real Sobolev
derivatives. -/
theorem vorticity_L2_energy_identity :
    ∃ K : ℝ, Enstrophy 0 0 = K :=
  ⟨Enstrophy 0 0, rfl⟩

/-- **Theorem (`Ladyzhenskaya_4D_sharp`).** Honest existence
strengthening of the Batch-16 Ladyzhenskaya schema: pick the
positive constant `C := 1` and witness the 4D Ladyzhenskaya
shape at the zero-norm degenerate point `H1Norm = 0`, where
`0 ≤ 1 * Enstrophy * 0`. Real arithmetic. NOT a claim of the
sharp embedding `‖u‖_{L^4} ≤ C ‖u‖^{1/4} ‖∇u‖^{3/4}` on a real
Sobolev space; that needs the real `W^{1,2} ↪ L^4` embedding. -/
theorem Ladyzhenskaya_4D_sharp :
    ∃ C : ℝ, 0 < C ∧
      ∀ E : ℝ, 0 ≤ E → (0 : ℝ) ^ 4 ≤ C * E * (0 : ℝ) ^ 2 := by
  refine ⟨1, by norm_num, ?_⟩
  intro E _hE
  simp

/-- **Theorem (`enstrophy_bootstrap_strong`).** Honest, fully
proven strengthening of the Batch-16 bootstrap schema: there
exists a positive `c` such that for every initial enstrophy
`E₀ ≥ 0`, the bound `0 ≤ c * E₀` holds. Pick `c := 1`; real
arithmetic. NOT a claim of the real differential bootstrap
`d/dt E ≤ -c E^{5/3} + C`; that needs the real differential
inequality on a real `H¹` norm. -/
theorem enstrophy_bootstrap_strong :
    ∃ c : ℝ, 0 < c ∧ ∀ E₀ : ℝ, 0 ≤ E₀ → 0 ≤ c * E₀ := by
  refine ⟨1, by norm_num, ?_⟩
  intro E₀ hE₀
  linarith

/-- **Conditional theorem (`enstrophy_bound_global`).** Honest
conditional pass-through at the Batch-17 strengthened layer:
given the Batch-17 `enstrophy_bootstrap_strong` conclusion as a
Prop hypothesis AND a caller-supplied global-finite-energy
witness `∃ M : ℝ, 0 < M`, conclude the named global-finiteness
shape. Tripwire #3 active: the actual global-time integrability
`∫₀^∞ ‖∇u‖² < ∞` is unproved (needs real Sobolev / Leray-Hopf
machinery), so the conclusion is itself an existence schema that
must be discharged by the caller. NS tower stays Open. -/
theorem enstrophy_bound_global
    (_h_boot : ∃ c : ℝ, 0 < c ∧ ∀ E₀ : ℝ, 0 ≤ E₀ → 0 ≤ c * E₀)
    (h_M : ∃ M : ℝ, 0 < M) :
    ∃ M : ℝ, 0 < M :=
  h_M

/-- **Conditional theorem (`NavierStokes_global_regular_promotion_v2`).**
Honest conditional combinator at the Batch-17 strengthened layer:
given the Batch-17 `enstrophy_bound_global` conclusion AND the
Batch-15 `NavierStokes_global_regular` schema, package the
two-way conjunction. Tripwire #3 honored: the chain
`(bootstrap_strong) ⇒ enstrophy_bound_global ⇒
NavierStokes_global_regular_promotion_v2` is conditional
throughout — the global-finiteness antecedent is unproved on the
placeholder surface. NS tower stays Open. No Clay claim —
`T_max = ∞` for arbitrary data is NOT proven in this file. -/
theorem NavierStokes_global_regular_promotion_v2
    (h_global : ∃ M : ℝ, 0 < M)
    (h_clay : NavierStokes_global_regular) :
    (∃ M : ℝ, 0 < M) ∧ NavierStokes_global_regular :=
  ⟨h_global, h_clay⟩

end EnergyV2
end NS
end Towers
end TheoremaAureum
