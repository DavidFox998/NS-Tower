# hOS Dependency Map — Osterwalder–Seiler cluster step (Wall256 leaf D5)

- `plan_id: hOS_dependency_map`
- `parent_plan: D1_to_D3_dependency_map` (this is the §1 `hOS` leaf, expanded)
- `export_date: 2026-06-01`
- `scope: IN_TOWER_PLANNING_DOCS_ONLY` — **no `.lean` written, no proof, no numerics, map only.**
- `tag_scheme: [NEEDS_NUMERICS] | [NEEDS_LEMMA] | [BLOCKED_BY_Wall256]`

> **Honesty correction (critical).** The repo went through a SORRY PURGE: there
> are **no bare `sorry` / `admit` proof terms** anywhere in the Wall256 stack.
> The `sorry` strings in `Wall256_Scaffold.lean` / `Wall256_Note.lean` are
> **docstring prose**. `hOS` is **not** a `sorry`; it is a **named open
> hypothesis** of `strong_coupling_decay_of_open_inputs`. So the "sorry inventory
> specific to hOS" below inventories the **open obligation `hOS` names** and what
> it depends on. **Nothing here is discharged or scheduled.**

---

## 1. What `hOS` is

- **Lean signature** (`Towers/YM/Wall256_Scaffold.lean:84`, a hypothesis of
  `strong_coupling_decay_of_open_inputs`):
  ```lean
  (hOS : w1 < 1 / 7 → TruncatedActivityBound a)
  ```
  where `w1 : ℝ` is the abstract scalar single-site weight and (`Towers/YM/Wall256_Note.lean:72`):
  ```lean
  def TruncatedActivityBound (a : ℕ → ℝ) : Prop :=
    (∀ n, 0 ≤ a n) ∧ ∃ I : ℝ, Real.log 7 < I ∧ ∀ n, a n ≤ Real.exp (-I) ^ n
  ```
- **In the KP taxonomy** (`KP_Plan_2026-06-01.json`): `hOS` = **leaf D5**, the
  Osterwalder–Seiler 1978 Thm 2.1 strong-coupling Ursell/cluster step (single-site
  smallness ⟹ truncated connected-polymer activity rate `I > log 7`). This is the
  **Ursell/cluster** activity bound, **NOT** OS reflection positivity.
- **Mathematical role:** it is the implication that turns the strict single-site
  bound `w1 < 1/7` into a per-polymer activity decay fast enough (`I > log 7`,
  strict) to beat the `N n ≤ 7ⁿ` polymer entropy in the comparison test.
- **Status:** OPEN · OUT_OF_TOWER · `in_mathlib_v4_12_0 = false` · stub-only.

---

## 2. hOS-specific sorry inventory (file-grounded, 2026-06-01)

**Method.** `rg ":=\s*sorry|by\s+sorry|exact\s+sorry"` over `Wall256_Scaffold.lean`
and `Wall256_Note.lean`. **Bare proof-term `sorry` count touching the hOS chain = 0.**
`hOS` is a named open hypothesis; `TruncatedActivityBound` is a `def`; its consumer
`kp_summable_of_truncatedActivity` is a *proved* combinator. The inventory of the
**open obligation `hOS` carries** and its inputs:

| # | obligation | location | status | tag |
| --- | --- | --- | --- | --- |
| H0 | `hOS : w1 < 1/7 → TruncatedActivityBound a` | `Wall256_Scaffold.lean:84` | OPEN · OUT_OF_TOWER | `[NEEDS_LEMMA]` Osterwalder–Seiler 1978 Thm 2.1 (E4) |
| H1 | antecedent `w1 < 1/7` (the scalar form `hOS` is applied to) | `Wall256_Scaffold.lean:83` (`hw1`) | OPEN | `[BLOCKED_BY_Wall256]` (the open `hw1` hypothesis) + underlying `[NEEDS_NUMERICS]` (E1) |
| H2 | existence of strict rate `I` with `log 7 < I` | inside `TruncatedActivityBound` (`Wall256_Note.lean:72`) | OPEN | `[NEEDS_LEMMA]` (the OS bound must *produce* `I > log 7`, not just `≥`) |
| H3 | nonnegativity `∀ n, 0 ≤ a n` | inside `TruncatedActivityBound` | OPEN (trivial once `a` is the real activity) | `[NEEDS_LEMMA]` (follows from the real cluster weight `a := polymerActivity`) |

**Does the certified β₀ discharge any of these? NO.** `CERT_Arb` (β₀ ∈
[2.079416880123, 2.079416880124]) is OUT-OF-TOWER interval numerics, not a Lean
term. It bears only on H1's *numeric* side (E1) and even there does not produce a
Lean proof. H0/H2/H3 are pure cluster-expansion analysis (E4), untouched by β₀.

---

## 3. Dependency list (each tagged)

`hOS` depends on:

1. **`hw1` antecedent** `w1 < 1/7` — `[BLOCKED_BY_Wall256]`.
   - `hOS` is *applied* to `hw1` (`hOS hw1` at `Wall256_Scaffold.lean:92`). In
     `strong_coupling_decay_of_open_inputs`, `hw1 : w1 < 1/7` is the open scalar
     hypothesis (`:83`). Its numeric content is `[NEEDS_NUMERICS]` (E1): a verified
     `∫_{SU(3)} exp(−β·S) dHaar < 1/7` for `β > β₀`, with β₀ CERTIFIED out-of-tower
     by CERT_Arb in `[2.079416880123, 2.079416880124]` (conservative formal
     requirement `β > 2.079416880124`). **Not** a Lean object.
   - **Bridge gap:** the new `def Beta0Certified` / `theorem hw1 (function form)`
     at `Wall256_Scaffold.lean:119/137` is **not yet threaded** into the scalar
     `hw1` premise of `strong_coupling_decay_of_open_inputs`. Connecting them is
     the `next_work` item "formalize Beta0Certified→hw1 bridge" — `[BLOCKED_BY_Wall256]`.

2. **Osterwalder–Seiler cluster lemma (E4)** — `[NEEDS_LEMMA]`.
   - The actual content of `hOS`: single-site smallness propagates through the
     Ursell/truncated expansion to `TruncatedActivityBound a` with rate `I > log 7`.
     Osterwalder–Seiler 1978 Thm 2.1. **Absent from mathlib v4.12.0.**

3. **Strict rate `I > log 7`** — `[NEEDS_LEMMA]` (sharp constant).
   - The **strict** inequality is essential: at `I = log 7` the entropy-weighted
     series `∑ₙ 7ⁿ·exp(−I)ⁿ = ∑ₙ 1` diverges. So the OS lemma must deliver a rate
     *strictly* above `log 7` — exactly where the `w1 < 1/7` (strict) input is
     consumed. This couples H2 back to H1 / β₀: a larger β (further above β₀) buys
     a larger `I`. `[BLOCKED_BY_Wall256]` (via `hw1`).

4. **Activity nonnegativity** `∀ n, 0 ≤ a n` — `[NEEDS_LEMMA]`.
   - Trivial once `a` is instantiated to the real connected/truncated activity
     (`polymerActivity`, `Transfer.lean:455`, already `≥ 0` and antitone-in-β); but
     in the abstract scaffold `a : ℕ → ℝ` is arbitrary, so this is part of what a
     real `hOS` would have to establish.

**Not dependencies (downstream / already proven — context only):**
`kp_summable_of_truncatedActivity` (`Wall256_Note.lean:82`, GENUINE comparison test,
machine-checked) *consumes* `TruncatedActivityBound a`; `su2_gap_of_truncatedActivity`
(`:106`) threads it onward. These are proved and trio-clean — they are what `hOS`
*feeds*, not what it needs.

---

## 4. Dependency graph

```
        [NEEDS_NUMERICS, out-of-tower E1]      [BLOCKED_BY_Wall256: Beta0Certified→hw1 bridge, next_work]
β > β₀ (CERT_Arb) ┄┄┄┄┄┄┄ (no Lean edge) ┄┄┄▶ hw1 : w1 < 1/7   (Wall256_Scaffold.lean:83, OPEN)
                                                   │  antecedent
                                                   ▼
   [NEEDS_LEMMA: Osterwalder–Seiler 1978 Thm 2.1, E4, absent v4.12.0]
                                              hOS (D5)  ──produces──▶ TruncatedActivityBound a
                                                   │                  (∀n,0≤a n) ∧ ∃ I>log7, a n ≤ e^{−I·n}
                                                   ▼
                              kp_summable_of_truncatedActivity   (Wall256_Note.lean:82, PROVED)
                                                   ▼
                                         Summable (Σ N n · a n)  ──▶ h_bridge (D6) ──▶ … lattice decay
```

The only **inbound** open edges to `hOS` are H1 (`hw1`, blocked-by-Wall256 +
numerics) and the OS lemma E4 (`[NEEDS_LEMMA]`). The **outbound** edge into
`kp_summable_of_truncatedActivity` is already machine-checked, so closing `hOS`
(plus `h_bridge` + D1–D3) would discharge only the **abstract lattice** decay
shape — **NOT** `YM_mass_gap_Surface` / Surface #1 (see `D1_to_D3_Plan.md` §0c).

---

## 5. Minimal path to realize `hOS` (NOT scheduled)

Strictly to turn `hOS` from open hypothesis into a Lean lemma (lattice scope only):

1. **Bridge `hw1`** `[BLOCKED_BY_Wall256]` — thread `Beta0Certified` / the wired
   `hw1` into the scalar `w1 < 1/7` premise (the `next_work` bridge).
2. **Port the SU(3) single-site numeric** `[NEEDS_NUMERICS]` — a Lean proof of
   `w1 < 1/7` for `β > 2.079416880124` (CERT_Arb is out-of-tower; a Lean object
   needs SU(3) character theory or verified cubature — **absent from v4.12.0**).
3. **Formalize Osterwalder–Seiler Thm 2.1** `[NEEDS_LEMMA]` — the Ursell/cluster
   activity bound delivering `I > log 7`. The single hardest leaf; absent from
   mathlib v4.12.0.
4. **Instantiate `a := polymerActivity`** `[NEEDS_LEMMA]` — discharge H3/H2 against
   the real activity (`Transfer.lean:455`) rather than the abstract `a`.

None is scheduled; steps 2–4 are open research or absent from mathlib v4.12.0.
Even all four yield only the lattice activity bound — no mass gap, no Surface #1.

---

## 6. When promoted to BUILD — STUBS ONLY

- ✅ `def hOS_Surface (w1 : ℝ) (a : ℕ → ℝ) : Prop := w1 < 1/7 → TruncatedActivityBound a`
  — a named open `Prop` mirroring the hypothesis. Optionally
  `theorem hOS_of_surface (h : hOS_Surface w1 a) : … := h` (discharge FROM the
  hypothesis, the post-purge pattern).
- ❌ **Never** `theorem hOS := by sorry` (emits `sorryAx`, breaks the axiom lock).
- ❌ Never `axiom` for the OS lemma (off the classical trio).
- ❌ Do **not** discharge `hOS`, write a real cluster-expansion proof, edit
  `Wall256_Scaffold.lean` / `Wall256_Note.lean` / `Transfer.lean`, or claim a mass
  gap / μ>0 / Surface-#1 / Clay result.
- ⚠️ Verify any new `.lean` with a **direct** `lake env lean <file>` + `#print
  axioms` **only after** asserting `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds; never run `towers-build` / `lake update` casually
  (they wipe the mathlib pin + oleans).

---

## 7. Honesty locks

```yaml
status: PLAN_DRAFT
scope: IN_TOWER_PLANNING_DOCS_ONLY
sorry_inventory_reframed: "no bare sorries post-purge; hOS is a NAMED OPEN hypothesis"
writes_lean: false
produces_proof: false
discharges_surface: false
closes_surface_1: false
closes_ym_tower: false
m_gt_0_claimed: false
mass_gap_proven: false
surface_1_status: OPEN
ym_tower_status: OPEN
hOS_status: OPEN
beta0_discharges_hOS: false
rh_grh_c05_separate: true
no_rh_claims_in_ym_certs: true   # the M7/GRH/C05 tower stays SEPARATE
split_statement: "No RH claims in YM certs."
note: >
  A dependency map enumerates requirements only. hOS stays an OPEN named
  hypothesis; its inputs (E1 numeric, E4 Osterwalder–Seiler lemma, the
  Beta0Certified→hw1 bridge) are open research or absent from mathlib v4.12.0.
  This proves nothing, discharges nothing, schedules no discharge, and makes no
  mass-gap / Surface-#1 / Clay / RH claim.
```

## Sources (read-only; not edited)

- `lean-proof-towers/Towers/YM/Wall256_Scaffold.lean` (`hw1:83`, `hOS:84`, apex `:80–92`, β₀ wiring block `:94–137` — `beta0_lo:110`, `Beta0Certified:119`, `Hw1_Surface:128`, `theorem hw1:137`)
- `lean-proof-towers/Towers/YM/Wall256_Note.lean` (`TruncatedActivityBound:72`, `kp_summable_of_truncatedActivity:82`, `su2_gap_of_truncatedActivity:106`)
- `lean-proof-towers/Towers/YM/Transfer.lean` (`polymerActivity:455`)
- `lean-proof-towers/exports/D1_to_D3_Plan.md` (parent map; §0c dashed lattice↛continuum gap)
- `lean-proof-towers/exports/KP_Plan_2026-06-01.json` (D1..D6 / E1..E6 taxonomy)
- `lean-proof-towers/exports/CERT_Arb_beta0_2026-06-01.yaml` (certified β₀ threshold)
