# Colophon

**Title:** Towers YM v2.3 — H₄ Boundary Protocol
**Author:** D. Fox
**ORCID:** 0009-0008-1290-6105
**Contact:** contact@entangledtechnologies.net
**URL:** www.entangledtechnologies.net
**Date:** 2026-06-02
**Version:** 2.3 FINAL

## Build protocol

**Formal + Empirical**
**Axioms:** 0
**Sorry:** 0
**Mathlib:** OFF (mathlib-free, Lean core only)
**Provenance:** ON

## Modules

On-disk filenames use underscores; the published module names are listed first.

1. **H4Core** (`Towers/YM/H4Core.lean` + leaf `Towers/YM/H4_Strata_Ztau.lean`) —
   Task #324 — manifest SHA *record* `48536d9d…ba997` (prose milestone record
   hash, NOT a file hash). Real file SHA-256 `aa8c1180…a6ce`, recorded in
   `H4Core.data.json`.
2. **H4Boundary** (`Towers/YM/H4_Boundary.lean`) — Task #325 — `C13 := 13`.
   **P5 distinction (LOCKED):**
   - `P5_genuine = 1000000001119` — **13 digits** (`digit_len = 13`, `Sym = 1`).
     The real 13-digit boundary prime. **ACCEPTED.**
   - `P5_proposed = 10000000001119` — **14 digits** (`digit_len = 14`). Its
     `digit_len P5 = C13` (i.e. `= 13`) claim is **FALSE**, so this proposed P5 is
     **REJECTED** as the 13-digit boundary — corrected per geometry-wins.

   The two differ by a single leading-block zero (13 vs 14 digits); do not
   conflate them. The witness table in `H4_Boundary.data.json` carries the
   rejected `P5_proposed = 10000000001119` with `digit_len 14` as the honest
   counter-record.
3. **H4TimeBound** (`Towers/YM/H4_TimeBound.lean`) — Task #326 — `N40 := 40`;
   `TimeHorizon := 3^40` carries no causal/temporal meaning; `10^12 << 3^40`
   (by ~7 orders of magnitude).
4. **H4Derivation** (`Towers/YM/H4_Derivation.lean`) — Task #327 — file SHA-256
   `e21ae1ba…e2b2`. `C13_Law_Open`: **CONJECTURE** (named open `Prop`; no theorem
   discharges it).

## Core results

**Primary law (CONJECTURE — empirical 6/6 only, NOT proven):**
`digit_len p ≥ 13 → Sym p = 1`.

**Demoted:** `N40 := 40`. `TimeHorizon := 3^40` is not causal — a plain integer
the witnesses are compared against.

**Computed (real W(H₄) action, not hardcoded):** `Sym(19) = 2`, `Sym(191) = 2`,
`Sym(1000000001119) = 1`. (`Sym(19) = 2`, NOT 20.)

## Gates

Gematria: OFF | Abjad: OFF | Religious: OFF | AI Attribution: OFF

## License

© 2026 D. Fox. All computations reproducible from the SHA-locked Lean sources.
