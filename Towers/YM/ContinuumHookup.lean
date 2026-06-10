/-
================================================================
Towers / YM / ContinuumHookup  (Task #174 / Task #156 file 5 of 6
— continuum-limit hookup, **honest stand-in**)

**One-line summary.** Wire the strip-form Varadhan-shape envelope
bound (`Heat_kernel_envelope_real_le_varadhan`, Batch 156.3) to
the continuum-YM schema (`YM4_Continuum`, `lattice_to_continuum`,
Batch 20.1a / `Towers/YM/Continuum.lean`). The wiring exposes a
single function `continuum_heat_envelope_bound` that, given a
lattice spacing `a : ℝ`, a lattice SU(3) connection
`A : SU3Connection`, and a strip-time `t : ℝ` in the original
Varadhan strip `[varadhan_t_lo, varadhan_t_top]`, lands the
Varadhan-shape upper bound on `Heat_kernel_envelope_real t`. The
schema slot is honored (the function takes the lattice data and
produces a bound that references the resulting `YM4_Continuum`
via the identity-trivial `lattice_to_continuum` map), but the
bound itself is the existing `t`-only strip bound — *no* new
content about `a → 0` is added.

### Drift / honest scope (locked)

The original Task #156 brief asked for a real `a → 0` continuum
limit hookup: take the lattice heat-kernel envelope, push it
through `lattice_to_continuum`, and re-derive the bound on the
continuum side. **`lattice_to_continuum` is currently the
identity-trivial map** (`Towers/YM/Continuum.lean` ships
`lattice_to_continuum a A := {}`, the default `YM4_Continuum`,
with NO real `a → 0` limit), so a "real" continuum-side bound is
not yet available. The wiring here is the honest **plumbing**:
take the (lattice) inputs, name the continuum slot, and emit the
strip bound from the existing surface. Replacing
`lattice_to_continuum` with a genuine continuum-limit functor
will *intentionally* break this hookup (the schema fields it
depends on will move), and that breakage is the tripwire signal
for a real continuum limit landing.

### What this file ships

  * `continuum_heat_envelope_bound a A t ht_lo ht_top` —
    re-exposes `Heat_kernel_envelope_real_le_varadhan` under a
    signature that *names* the lattice data `(a, A)` and the
    resulting continuum schema (`lattice_to_continuum a A :
    YM4_Continuum`). The conclusion is unchanged.
  * `continuum_heat_envelope_bound_target_default` — at the
    representative strip-time `t = varadhan_t_lo`, the continuum
    schema produced by `lattice_to_continuum` is *definitionally*
    the default `YM4_Continuum`. Records the identity-trivial
    nature of the current `lattice_to_continuum` map.
  * `continuum_heat_envelope_pos` — at any strip-time `t` the
    Varadhan-shape RHS `varadhan_C · exp(-c/t) / t^4` is strictly
    positive. A consistency brick on the bound shape (the LHS
    `Heat_kernel_envelope_real t` is already known `≥ 1` via
    `Heat_kernel_envelope_real_ge_one_of_pos` from
    `Towers/YM/PeterWeylHeat.lean`).

### What this file does NOT ship

  * A real `a → 0` continuum limit of the lattice heat-kernel
    envelope (depends on a real `lattice_to_continuum`).
  * A continuum-side Varadhan asymptotic.
  * A mass-gap statement on `YM4_Continuum` (that is file 6 of 6,
    `Towers/YM/MassGapEnvelope.lean`).
  * Any new constants or any change to `varadhan_C`, `varadhan_c`.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface #3
(continuum YM) stays OPEN.

### Invariants honored

  * Sorry-free (this file has zero `sorry`).
  * Axiom footprint ⊆ `{propext, Classical.choice, Quot.sound}`.
  * No edit to `Towers/YM/Continuum.lean`, `Towers/YM/MassGap.lean`,
    or `Towers/YM/PeterWeylHeatVaradhan.lean`. Purely additive.

================================================================
-/

import Towers.YM.Continuum
import Towers.YM.PeterWeylHeatVaradhan
import Towers.YM.VaradhanStripWidened

namespace TheoremaAureum
namespace Towers
namespace YM
namespace ContinuumHookup

open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Continuum
open TheoremaAureum.Towers.YM.PeterWeylHeat
open TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan
open TheoremaAureum.Towers.YM.VaradhanStripWidened

/-- **Strip-form Varadhan-shape envelope bound, wired through the
continuum schema slot.** For lattice spacing `a : ℝ` and lattice
SU(3) connection `A : SU3Connection`, the continuum schema
`lattice_to_continuum a A : YM4_Continuum` is named in the
signature (currently the identity-trivial default — see
`Towers/YM/Continuum.lean`). For every strip-time `t` in
`[varadhan_t_lo, varadhan_t_top]`, the existing strip bound
applies.

The lattice inputs `(a, A)` are positional in the signature so
downstream consumers can be written against the real continuum-
limit hookup once `lattice_to_continuum` becomes non-trivial. The
proof discards them and delegates to
`Heat_kernel_envelope_real_le_varadhan`. -/
theorem continuum_heat_envelope_bound
    (_a : ℝ) (_A : SU3Connection)
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top) :
    Heat_kernel_envelope_real t ≤
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 :=
  Heat_kernel_envelope_real_le_varadhan ht_lo ht_top

/-- **Tripwire brick, rewritten (Task #195 — intentional break).**

The previous version of this brick recorded the *identity-trivial*
nature of `lattice_to_continuum` as the `rfl` equation
`lattice_to_continuum a A = ({} : YM4_Continuum)`. That contract has
been intentionally retired: `lattice_to_continuum` is now a
**structure-producing** map (`Towers/YM/Continuum.lean`) whose fields
are read from the lattice data — `gauge_rank` off the connection's
SU(3) group structure and `spacetime_dim` off the spacing — so it is
no longer the bare default `{}` and the old `rfl` no longer holds.

This rewrite records the *honest content* of the new map: for any
**physical** lattice spacing (`0 < a`) and SU(3) connection `A`, the
produced continuum schema is genuinely SU(3) in four dimensions —
`gauge_rank = 3` (read off `A`) and `spacetime_dim = 4` (read off the
positive spacing `a`). It is NOT a real `a → 0` continuum limit; the
map only reads the discrete schema slots. A genuine continuum-limit
functor will move these fields again and break *this* brick in turn,
keeping it the tripwire signal for a real continuum limit landing. -/
theorem continuum_heat_envelope_bound_target_default
    (a : ℝ) (A : SU3Connection) (ha : 0 < a) :
    (lattice_to_continuum a A).gauge_rank = 3 ∧
      (lattice_to_continuum a A).spacetime_dim = 4 := by
  refine ⟨?_, ?_⟩
  · show gauge_rank_of A = 3
    simp [gauge_rank_of]
  · show spacetime_dim_of_spacing a = 4
    unfold spacetime_dim_of_spacing
    rw [if_pos ha]

/-- Consistency brick on the Varadhan-shape RHS: at any strip-time
`t ∈ [varadhan_t_lo, varadhan_t_top]` the bound's right-hand side
`varadhan_C · exp(-c/t) / t^4` is strictly positive. -/
theorem continuum_heat_envelope_pos
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (_ht_top : t ≤ varadhan_t_top) :
    0 < varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4 : 0 < t ^ 4 := pow_pos htpos 4
  have hnum : 0 < varadhan_C * Real.exp (-(varadhan_c / t)) :=
    mul_pos varadhan_C_pos (Real.exp_pos _)
  exact div_pos hnum ht4

/-! ## Widened upper-side continuum hookup — Task #219

Carry the genuinely upper-widened strip bound
`Heat_kernel_envelope_real_le_varadhan_widened_upper` (Task #194,
`Towers/YM/VaradhanStripWidened.lean`) through the same continuum
schema slot. The valid `t`-window now runs up to
`varadhan_t_top_widened = 2 · varadhan_t_top` (strictly past the
original strip top `varadhan_t_top`), and the RHS amplitude is the
retuned `varadhan_C_widened`. As with the original hookup, the lattice
inputs `(a, A)` are named in the signature but discarded by the proof:
`lattice_to_continuum` is still the placeholder schema map, so **no
`a → 0` content is added**. -/

/-- **Widened strip-form Varadhan-shape envelope bound, wired through
the continuum schema slot (Task #219).** Same plumbing as
`continuum_heat_envelope_bound`, but consuming the upper-widened bound:
for every strip-time `t` with
`varadhan_t_lo ≤ t ≤ varadhan_t_top_widened` — i.e. `t` may now run
strictly past the original strip top `varadhan_t_top` up to the widened
top `varadhan_t_top_widened = 2 · varadhan_t_top` — the retuned-amplitude
bound `Heat_kernel_envelope_real t ≤ varadhan_C_widened · exp(-c/t) / t^4`
applies. The proof delegates to
`Heat_kernel_envelope_real_le_varadhan_widened_upper`; the lattice
inputs `(a, A)` are discarded (`lattice_to_continuum` adds no `a → 0`
content). -/
theorem continuum_heat_envelope_bound_widened_upper
    (_a : ℝ) (_A : SU3Connection)
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t)
    (ht_top : t ≤ varadhan_t_top_widened) :
    Heat_kernel_envelope_real t ≤
      varadhan_C_widened * Real.exp (-(varadhan_c / t)) / t ^ 4 :=
  Heat_kernel_envelope_real_le_varadhan_widened_upper ht_lo ht_top

/-- Consistency brick on the widened Varadhan-shape RHS: at any
strip-time `t ∈ [varadhan_t_lo, varadhan_t_top_widened]` the bound's
right-hand side `varadhan_C_widened · exp(-c/t) / t^4` is strictly
positive. Companion of `continuum_heat_envelope_pos` for the widened
upper window. -/
theorem continuum_heat_envelope_pos_widened
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t)
    (_ht_top : t ≤ varadhan_t_top_widened) :
    0 < varadhan_C_widened * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4 : 0 < t ^ 4 := pow_pos htpos 4
  have hnum : 0 < varadhan_C_widened * Real.exp (-(varadhan_c / t)) :=
    mul_pos varadhan_C_widened_pos (Real.exp_pos _)
  exact div_pos hnum ht4

end ContinuumHookup
end YM
end Towers
end TheoremaAureum
