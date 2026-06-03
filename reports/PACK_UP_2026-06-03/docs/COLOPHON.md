# Colophon

**Title:** Towers YM v2.3 — H₄ Boundary Protocol
**Author:** D. Fox
**ORCID:** 0009-0008-1290-6105
**Contact:** contact@entangledtechnologies.net
**URL:** www.entangledtechnologies.net
**Date:** 2026-06-02
**Version:** 2.3 FINAL

**P5_genuine = 1000000001119 [13 digits, Sym=1] LOCKED**

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
   **Certified 13-character P5 table** (digit counts tool-certified via
   `${#literal}`, never eye-counted):

   | Name | Value | Digits | Sym | Status |
   |---|---|---|---|---|
   | `P5_genuine` | `1000000001119` | 13 | 1 | **CERTIFIED · LOCKED** |
   | `P5_proposed_14` | `10000000001119` | 14 | — | REJECTED |
   | `P5_proposed_15` | `100000000001119` | 15 | — | REJECTED |

   `P5_genuine = 1000000001119` is the ONLY live P5 in v2.3 — the real 13-digit
   boundary prime (`digit_len = 13`, `Sym = 1`). The two over-zero variants each
   carry one extra zero, so their `digit_len P5 = C13` (= 13) claim is **FALSE**;
   they are kept solely as labeled **REJECTED** counter-records, not used as P5
   anywhere. `H4_Boundary.data.json` records the 14-digit `10000000001119` as the
   honest counter-record. No spike, transition, or `Sym`/critical-line meaning is
   attached to digit length (see `docs/BOUNDARY_ARTIFACT.md`).
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

## Z Experiment Harness (v2.3)

**Tool use eliminates digit reproduction error.** Pure measurement, no
conjecture: 50 script-generated inputs (digit length 10–25, zero-run 0–15,
`Sym ∈ {1, 2, null}`) were reproduced tool-assisted (`printf` / `${#s}`) over
5000 trials (100 per input). Result: **0 errors, error rate 0.0** — tool-assisted
reproduction is deterministic across every tested input.

Scope (honest): this measures only the tool-assisted regime (`T = 1`). With all
errors zero there is no correlation between reproduction error and `Sym`, digit
length, or zero-run when `T = 1` — but a null result cannot rank those factors,
and the harness does NOT test the pure-generation (`T = 0`) regime. No
`Sym`-coupling, digit-band, or "metastability" law is implied. Harness:
`experiments/z-metastability/`.

## Gates

Gematria: OFF | Abjad: OFF | Religious: OFF | AI Attribution: OFF

## License

© 2026 D. Fox. All computations reproducible from the SHA-locked Lean sources.
