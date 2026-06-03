# h_bridge Dependency Map — Brydges–Federbush KP⟹clustering bridge (Wall256 leaf D6)

- `plan_id: h_bridge_dependency_map`
- `parent_plan: D1_to_D3_dependency_map` (this is the §2 `h_bridge` leaf, expanded; companion to `hOS_Plan.md`)
- `export_date: 2026-06-01`
- `scope: IN_TOWER_PLANNING_DOCS_ONLY` — **no `.lean` written, no proof, no numerics, map only.**
- `tag_scheme: [NEEDS_NUMERICS] | [NEEDS_LEMMA] | [BLOCKED_BY_Wall256]`

> **Honesty correction (critical).** The Wall256 stack went through a SORRY
> PURGE: there are **no bare `sorry` / `admit` proof terms**. The `sorry` strings
> in `Wall256_Scaffold.lean` / `Wall256_Note.lean` are **docstring prose**.
> `h_bridge` is **not** a `sorry`; it is a **named open hypothesis** of
> `strong_coupling_decay_of_open_inputs` (`Wall256_Scaffold.lean:85`). The
> "sorry inventory specific to h_bridge" below inventories the **open obligation
> `h_bridge` names** and what it depends on. **Nothing here is discharged or
> scheduled.**

---

## 1. What `h_bridge` is

- **Lean signature** (`Towers/YM/Wall256_Scaffold.lean:85–86`, a hypothesis of
  `strong_coupling_decay_of_open_inputs`):
  ```lean
  (h_bridge : Summable (fun n : ℕ => N n * a n) →
      0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y))
  ```
  with `corr sep : E → E → ℝ`, `C ρ : ℝ`, `N a : ℕ → ℝ` all ABSTRACT — no real
  Wilson correlator, lattice metric, or decay rate is constructed.
- **In the KP taxonomy** (`KP_Plan_2026-06-01.json`): `h_bridge` = **leaf D6**,
  the Brydges–Federbush step that turns KP-summability into geometric two-point
  clustering with ratio `ρ < 1` (Friedli–Velenik 2018, Ch. 5).
- **Mathematical role:** it is the implication that converts the *summability* of
  the entropy-weighted activity series (`Summable (Σ N n · a n)`) into an
  *exponential* two-point decay bound `|corr x y| ≤ C·ρ^{sep x y}` with strict
  `ρ ∈ (0,1)`.
- **Status:** OPEN · OUT_OF_TOWER · `in_mathlib_v4_12_0 = false` · stub-only.

---

## 2. h_bridge-specific sorry inventory (file-grounded, 2026-06-01)

**Method.** `rg ":=\s*sorry|by\s+sorry|exact\s+sorry"` over `Wall256_Scaffold.lean`,
`Wall256_Note.lean`, `Wall256_MassGapConditional.lean`. **Bare proof-term `sorry`
count touching the h_bridge chain = 0.** `h_bridge` is a named open hypothesis;
its `Summable` premise is *produced* by a proved combinator; its `ρ→Δ` consumer
is *proved*. The inventory of the open obligation `h_bridge` carries and its inputs:

| # | obligation | location | status | tag |
| --- | --- | --- | --- | --- |
| B0 | `h_bridge : Summable (Σ N n·a n) → ρ∈(0,1) ∧ decay` | `Wall256_Scaffold.lean:85` | OPEN · OUT_OF_TOWER | `[NEEDS_LEMMA]` Brydges–Federbush KP⟹clustering (E3) |
| B1 | the `Summable (fun n => N n * a n)` premise (= KP leaf D3) | premise of B0 | OPEN, but PROVED *given* `TruncatedActivityBound a` | `[BLOCKED_BY_Wall256]` (`TruncatedActivityBound` comes from the open `hOS`) + `[NEEDS_LEMMA]` D1 entropy count `N n ≤ 7ⁿ` (E2) |
| B2 | strict `ρ < 1` (geometric ratio, not merely `≤ 1`) | inside B0's conclusion | OPEN | `[NEEDS_LEMMA]` (the clustering rate must be *strict*, part of E3) |
| B3 | `ρ^d = exp(−Δ·d)` conversion to the `exp` decay shape | `Wall256_MassGapConditional.lean:88` | **PROVED** (not an obligation) | — (context only) |

**Does the certified β₀ discharge any of these? NO.** `CERT_Arb` (β₀ ∈
[2.079416880123, 2.079416880124]) is OUT-OF-TOWER interval numerics, not a Lean
term. `h_bridge` has **no direct numeric dependency**: its only β-coupling is
*indirect*, inherited through B1's `Summable` premise, which traces back through
`hOS` to `hw1`'s out-of-tower numeric (E1). B0/B2 are pure cluster-expansion
analysis (E3), untouched by β₀.

---

## 3. Dependency list (each tagged)

`h_bridge` depends on:

1. **`Summable (fun n => N n * a n)` premise (D3)** — `[BLOCKED_BY_Wall256]` + `[NEEDS_LEMMA]`.
   - This premise is **already produced**, machine-checked, by the GENUINE
     combinator `Wall256Note.kp_summable_of_truncatedActivity`
     (`Wall256_Note.lean:82`) from `TruncatedActivityBound a` + `N n ≤ 7ⁿ`
     (comparison test). So **no new lemma is needed for the summation step itself.**
   - What is OPEN: its input `TruncatedActivityBound a` comes from the open `hOS`
     (`Wall256_Scaffold.lean:84`) — hence `[BLOCKED_BY_Wall256]` (see `hOS_Plan.md`).
   - The entropy count `N n ≤ 7ⁿ` is the scaffold hypothesis `hN`
     (`Wall256_Scaffold.lean:82`); instantiating it for the real 4D-lattice SU(3)
     connected-polymer count is the open feeder **D1** (E2) — `[NEEDS_LEMMA]`.

2. **Brydges–Federbush clustering lemma (E3)** — `[NEEDS_LEMMA]`.
   - The actual content of `h_bridge`: KP-summability of the entropy-weighted
     activity ⟹ exponential two-point clustering with `ρ < 1`. Friedli–Velenik
     2018, Ch. 5. **Absent from mathlib v4.12.0.**

3. **Strict ratio `ρ < 1` (B2)** — `[NEEDS_LEMMA]` (part of E3).
   - Geometric (not just bounded) decay requires `ρ` *strictly* below 1; this is
     where the strict KP-summability margin is consumed. Without strictness the
     downstream `Δ > 0` (positive decay rate) is unavailable.

**Not dependencies (downstream / already proven — context only):**
- `Wall256Note.kp_summable_of_truncatedActivity` (`:82`, GENUINE comparison test,
  proved) — *produces* `h_bridge`'s `Summable` premise.
- `Wall256Note.su2_gap_of_truncatedActivity` (`:106`, proved) — the apex
  combinator that *consumes* `h_bridge`'s clustering output and delegates to…
- `Wall256.mass_gap_pos_of_spectral_gap` (`Wall256_MassGapConditional.lean:88`,
  proved) — the genuine `ρ^d = exp(−Δ·d)` algebra giving the final `exp` decay
  shape. (Name is conditional/abstract; proves NO mass gap on its own.)

These are proved and trio-clean — they are what `h_bridge` *feeds* and *is fed by*,
not what it needs. **"PROVED" here means proved as conditional combinators**: each
is a real theorem body with a real proof, but it is *parametrized over* the open
hypotheses (`TruncatedActivityBound a`, `h_bridge`, the spectral-gap inputs) — so
it carries no unconditional mass-gap content of its own.

---

## 4. Dependency graph (`kp_summable → h_bridge → strong_coupling_decay`)

```
   [BLOCKED_BY_Wall256: TruncatedActivityBound from open hOS]   [NEEDS_LEMMA: D1 count N n ≤ 7ⁿ, E2]
                 hOS (D5, OPEN) ──produces──▶ TruncatedActivityBound a        hN : N n ≤ 7ⁿ
                                                        │                          │
                                                        └────────────┬────────────┘
                                                                     ▼
                            kp_summable_of_truncatedActivity   (Wall256_Note.lean:82, PROVED)
                                                                     ▼
                                                   Summable (fun n => N n · a n)   (D3 premise)
                                                                     │
   [NEEDS_LEMMA: Brydges–Federbush KP⟹clustering, E3, absent v4.12.0]            │
                                              h_bridge (D6, OPEN) ◀──consumes─────┘
                                                                     │ produces
                                                                     ▼
                                              0 < ρ ∧ ρ < 1 ∧ |corr x y| ≤ C·ρ^{sep x y}
                                                                     │
                            su2_gap_of_truncatedActivity (Wall256_Note.lean:106, PROVED)
                                                                     ▼
                            mass_gap_pos_of_spectral_gap (Wall256_MassGapConditional.lean:88, PROVED)
                                              ρ^d = exp(−Δ·d) algebra
                                                                     ▼
   strong_coupling_decay_of_open_inputs  (Wall256_Scaffold.lean:80–92, abstract corr/sep)
                            ∃ Δ > 0, ∀ x y, |corr x y| ≤ C·exp(−Δ·sep x y)
                                                                     │
   ┄┄┄ NO Lean edge ┄┄┄  (abstract LATTICE decay shape  ↛  real continuum transfer gap)
                                                                     ▼
   YM_mass_gap_Surface  (Surface #1, MassGap574.lean:69) — scalar/Perron shadow, OPEN
```

The only **inbound** open edges to `h_bridge` are B1 (its `Summable` premise,
blocked-by-Wall256 via `hOS` + D1 count) and the Brydges–Federbush lemma E3
(`[NEEDS_LEMMA]`). Everything between `kp_summable_of_truncatedActivity` and the
final `exp` shape is **already machine-checked** — the open content is exactly B0
(the bridge lemma) and its upstream `TruncatedActivityBound` (via `hOS`).

---

## 5. Minimal path: hOS + h_bridge + D1–D3 = lattice decay shape ONLY

Strictly to discharge `h_bridge` and thereby the open inputs of
`strong_coupling_decay_of_open_inputs` (this is the **lattice** reduction, NOT
Surface #1):

1. **`hOS`** `[BLOCKED_BY_Wall256, NEEDS_LEMMA]` — supplies `TruncatedActivityBound a`
   (Osterwalder–Seiler E4). See `hOS_Plan.md`.
2. **D1 entropy count** `[NEEDS_LEMMA]` — instantiate `N n ≤ 7ⁿ` for the real
   connected-polymer count (E2).
3. **D3 summability** — then `kp_summable_of_truncatedActivity` (PROVED) yields the
   `Summable` premise; no new work.
4. **`h_bridge`** `[NEEDS_LEMMA]` — formalize Brydges–Federbush KP⟹clustering with
   strict `ρ < 1` (E3, absent from mathlib v4.12.0).

**Even with all of these, the result is the abstract LATTICE two-point decay
shape only** — `∃ Δ > 0, |corr x y| ≤ C·exp(−Δ·sep x y)` over ABSTRACT `corr/sep`.
It is **NOT** the YM mass gap, **NOT** `μ > 0`, and **NOT** `YM_mass_gap_Surface`
/ Surface #1: the dashed edge in §4 (lattice strong-coupling decay ↛ real
continuum transfer gap) has **no Lean implication**. No step is scheduled; steps
1, 2, 4 are open research or absent from mathlib v4.12.0.

---

## 6. When promoted to BUILD — STUBS ONLY

- ✅ `def hBridge_Surface (N a corr sep) (C ρ) : Prop := Summable (fun n => N n * a n) → 0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)`
  — a named open `Prop` mirroring the hypothesis. Optionally
  `theorem h_bridge_of_surface (h : hBridge_Surface …) : … := h` (discharge FROM
  the hypothesis — the post-purge pattern).
- ❌ **Never** `theorem h_bridge := by sorry` (emits `sorryAx`, breaks the axiom lock).
- ❌ Never `axiom` for the Brydges–Federbush lemma (off the classical trio).
- ❌ Do **not** discharge `h_bridge`, write a real clustering proof, edit
  `Wall256_Scaffold.lean` / `Wall256_Note.lean` / `Wall256_MassGapConditional.lean`,
  or claim a mass gap / μ>0 / Surface-#1 / Clay result.
- ⚠️ Verify any new `.lean` with a **direct** `lake env lean <file>` + `#print
  axioms` **only after** asserting `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds; never run `towers-build` / `lake update` casually
  (they wipe the mathlib pin + oleans).

---

## 7. Honesty locks

```yaml
status: PLAN_DRAFT
scope: IN_TOWER_PLANNING_DOCS_ONLY
sorry_inventory_reframed: "no bare sorries post-purge; h_bridge is a NAMED OPEN hypothesis"
writes_lean: false
produces_proof: false
discharges_surface: false
closes_surface_1: false
closes_ym_tower: false
m_gt_0_claimed: false
mass_gap_proven: false
surface_1_status: OPEN
ym_tower_status: OPEN
h_bridge_status: OPEN
hOS_status: OPEN
beta0_discharges_h_bridge: false
result_if_all_inputs_close: "abstract LATTICE two-point decay shape ONLY — NOT Surface #1, NOT a mass gap"
rh_grh_c05_separate: true
no_rh_claims_in_ym_certs: true   # the M7/GRH/C05 tower stays SEPARATE
split_statement: "No RH claims in YM certs."
note: >
  A dependency map enumerates requirements only. h_bridge stays an OPEN named
  hypothesis; its inputs (the Summable premise via the open hOS + D1 count, and
  the Brydges–Federbush clustering lemma E3) are open research or absent from
  mathlib v4.12.0. The genuine consumers (kp_summable_of_truncatedActivity,
  su2_gap_of_truncatedActivity, mass_gap_pos_of_spectral_gap) are already proved
  but conditional/abstract. This proves nothing, discharges nothing, schedules no
  discharge, and makes no mass-gap / Surface-#1 / Clay / RH claim.
```

## Sources (read-only; not edited)

- `lean-proof-towers/Towers/YM/Wall256_Scaffold.lean` (`hOS:84`, `h_bridge:85–86`, apex `strong_coupling_decay_of_open_inputs:80–92`)
- `lean-proof-towers/Towers/YM/Wall256_Note.lean` (`TruncatedActivityBound:72`, `kp_summable_of_truncatedActivity:82` PROVED, `su2_gap_of_truncatedActivity:106` PROVED)
- `lean-proof-towers/Towers/YM/Wall256_MassGapConditional.lean` (`mass_gap_pos_of_spectral_gap:88` PROVED, ρ^d=exp(−Δ·d) algebra)
- `lean-proof-towers/Towers/YM/MassGap574.lean` (`YM_mass_gap_Surface:69`, Surface #1 scalar shadow)
- `lean-proof-towers/exports/hOS_Plan.md` (companion map; the D5 leaf feeding B1)
- `lean-proof-towers/exports/D1_to_D3_Plan.md` (parent map; §0c dashed lattice↛continuum gap)
- `lean-proof-towers/exports/KP_Plan_2026-06-01.json` (D1..D6 / E1..E6 taxonomy)
