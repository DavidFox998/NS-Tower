---
name: Named-Prop surface vacuity
description: Converting a `sorry` to a named `Prop` hypothesis is only honest if the body is non-trivial; many YM surfaces collapse to 1<1 or 0≤1 under stand-in defs.
---

# Named-Prop surface vacuity

The SORRY-purge pattern `theorem foo (h : Foo_Surface a) : Goal := h` removes
`sorryAx`, but it is **honest only if `Foo_Surface` has non-trivial content**.
When the surface body is built from stand-in defs that are constants, it
collapses to a tautology (or an unsatisfiable falsehood) and encodes nothing.

**Why:** in this repo the stand-in defs are literal constants —
`spectral_radius_def := 1`, `Decay_constant_real := 1`, `Plaquette_action_def
:= 0`, `Polymer_activity_def := 0`, `Wilson_measure_gaussian_part := 1`,
`mayer_K_constant := 1`, `Character_expansion_plaquette := 0`. So e.g.
`spectral_radius_def D g < 1` is `1 < 1` (vacuously FALSE — can never be
discharged, conditional theorem holds only ex falso), and
`|Polymer_activity_def …| ≤ mayer_K_constant^n` is `0 ≤ 1` (vacuously TRUE).
A `*_Surface` over a `D.fieldName : Prop` structure field of the placeholder
`OSPreHilbert` bundle is non-vacuous but necessary-not-sufficient (no concrete
measure behind it).

**How to apply:** before treating any `*_Surface` / named hypothesis as a real
open problem, unfold its body through the underlying defs. If every leaf is a
constant, it is vacuous — do NOT present it as a genuine open surface. Genuine
surfaces are the ones over real objects: real `T_L` / real `haarN` (YM
Transfer), real Hilbert-space projections (NS Leray), real seminorms (NS
Enstrophy, though `H1Norm := ‖u t 0‖` is a SIMPLIFIED seminorm, not full H¹).
Clay `MassGap_YM4_Clay` and `MassGap574.YM_mass_gap` are non-vacuous *statements*
but over SCALAR shadow operators (`continuumOp = (1−scale)•1`,
`H = wilsonAction U • 𝟙`) — necessary-not-sufficient, never a real mass gap.
The canonical honest index lives in doc-only `Towers/CanonicalSurfaces.lean`
(no `iff`, grouped by REAL tower: 4 of the 6 genuine surfaces are YM, 2 are NS).
