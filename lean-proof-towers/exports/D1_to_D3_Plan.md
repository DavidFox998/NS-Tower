# D1–D3 Dependency Map — Wall256 `hOS` + `h_bridge` (and the D1/D2/D3 feeders)

- `plan_id: D1_to_D3_dependency_map`
- `parent_plan: kp-surface-discharge-decomposition`
- `export_date: 2026-06-01`
- `scope: IN_TOWER_PLANNING_DOCS_ONLY` — **no `.lean` written, no proof, no numerics, stubs only.**

> **Honesty correction (critical).** This repo went through a SORRY PURGE: there
> are **no bare `sorry` / `admit` proof terms** in any landed brick. The `sorry`
> strings still visible in `Wall256_Scaffold.lean` / `MassGap574.lean` are
> **docstring prose**, not proof terms. So a literal "sorry inventory" does not
> exist. What follows inventories the **named open `Prop` surfaces and open
> hypotheses** (the post-purge form): `hw1`, `hOS`, `h_bridge`,
> `kotecky_preiss_criterion_Surface`, `YM_mass_gap_Surface`,
> `trivial_polymer_set_null_Surface`. **Nothing here is discharged.**

---

## 0. Reduction chain (one line)

```
D4 (hw1)  ⟹  D5 (hOS)  ⟹  (D1 + D2  ⟹  D3, KP-summable)  ⟹  D6 (h_bridge)  ⟹  target two-point decay
```

Valid **only if all of D1..D6 hold**. NONE is discharged or scheduled. Every
leaf is open research or absent from mathlib v4.12.0. This chain proves nothing,
closes no surface, and makes no mass-gap / μ>0 / Surface-#1 / Clay claim.

**Naming reconciliation.** The user label "D1–D3" names the two *remaining*
Wall256 open hypotheses `hOS` and `h_bridge` **plus** the upstream feeders that
the summability premise of `h_bridge` consumes. In the parent KP taxonomy
(`KP_Plan_2026-06-01.json`):

| User label here | KP-plan leaf | Object |
| --- | --- | --- |
| `hw1`      | **D4** | strict single-site weight bound `w1 < 1/7` (TESTED_NEGATIVE_CERTIFIED at β=0.86; CERT_Arb β₀∈[2.079416880123, 2.079416880124], so requires **β > 2.07941688**) |
| `hOS`      | **D5** | Osterwalder–Seiler Ursell/cluster step |
| `h_bridge` | **D6** | Brydges–Federbush KP-summability ⟹ geometric clustering |
| feeders    | **D1 / D2 / D3** | polymer counting / activity bound / KP summability that produce the `Summable …` premise `h_bridge` consumes |

---

## 0b. Sorry scan (file-grounded, 2026-06-01)

**Method.** `rg ":=\s*sorry|by\s+sorry|exact\s+sorry"` over
`Wall256_Scaffold.lean`, `Wall256_Note.lean`, `MassGap574.lean`, `Transfer.lean`.

**Result: BARE PROOF-TERM `sorry` COUNT = 0.** Every `sorry`/`by sorry` string in
these files is **docstring prose**, not a proof term. Post sorry-purge each
former `sorry` is an explicit **named open `Prop` / hypothesis**. (E.g.
`MassGap574.YM_mass_gap` is `:= hsurf`, consuming the hypothesis
`hsurf : YM_mass_gap_Surface …` — it does NOT carry `by sorry`, despite stale
docstring lines that still say "keeps its `sorry`".)

So the table below inventories the **named open obligations** (the post-purge
form of what would otherwise be sorries), tagged per the requested scheme:
`[NEEDS_NUMERICS]` (needs a verified bound, out-of-tower), `[NEEDS_LEMMA]`
(needs an absent mathlib/research lemma), `[BLOCKED_BY x]` (depends on another
open obligation).

| file | line | prop / hypothesis | status | blocker tag |
| --- | --- | --- | --- | --- |
| `Towers/YM/Wall256_Scaffold.lean` | 79 | `hw1 : w1 < 1/7` (= D4) | OPEN · OUT_OF_TOWER | `[NEEDS_NUMERICS]` — verified `∫_{SU(3)} e^{−β·S} < 1/7`; CERT_Arb certifies β₀∈[2.079416880123, 2.079416880124] **out-of-tower**, NOT a Lean object |
| `Towers/YM/Wall256_Scaffold.lean` | 80 | `hOS : w1 < 1/7 → TruncatedActivityBound a` (= D5) | OPEN · OUT_OF_TOWER | `[NEEDS_LEMMA]` Osterwalder–Seiler 1978 Thm 2.1; `[BLOCKED_BY hw1]` |
| `Towers/YM/Wall256_Scaffold.lean` | 81–82 | `h_bridge : Summable (Σ N n·a n) → ρ∈(0,1) clustering` (= D6) | OPEN · OUT_OF_TOWER | `[NEEDS_LEMMA]` Brydges–Federbush; `[BLOCKED_BY D1,D2,D3]` (its `Summable` premise) |
| `Towers/YM/Transfer.lean` | 409 | `kotecky_preiss_criterion_Surface` | OPEN · genuine open combinatorics | `[NEEDS_LEMMA]` (D1 polymer count, E2); non-vacuous |
| `Towers/YM/Transfer.lean` | 669 | `trivial_polymer_set_null_Surface` | OPEN · necessary-NOT-sufficient (different branch) | `[NEEDS_LEMMA]` E5 (`NoAtoms` precond) + E6 (L=1 estimate) |
| `Towers/YM/MassGap574.lean` | 69 | `YM_mass_gap_Surface` (**Surface #1**, scalar shadow) | OPEN | `[NEEDS_LEMMA]` real Wilson transfer-operator gap (Wall 574); `H U = wilsonAction U • 𝟙` is the scalar/Perron shadow, NOT the real operator |

**Does β > 2.079416880124 discharge any of these? NO.** CERT_Arb is OUT-OF-TOWER
interval numerics, not a Lean term, so it discharges **zero** Lean obligations —
not even `hw1` (there is no Lean proof of `w1 < 1/7`). It only certifies the
*shape* of the constraint `hw1` would impose (β above the certified β₀) and the
*negative* verdict at β=0.86. Every row stays **OPEN**.

## 0c. Dependency graph (`hOS → … → Surface #1`)

```
        [NEEDS_NUMERICS, out-of-tower]
hw1 (D4) ──────────────┐
                       ▼
                 hOS (D5)  ── needs ──▶ TruncatedActivityBound  (rate I > log 7)
                       │
   D1 polymer count ───┤
   D2 activity bound ──┤──▶ D3 KP-summable  ⟹  Summable (Σ N n·a n)
                       │                              │
                       ▼                              ▼
                 h_bridge (D6) ── consumes the Summable premise ──▶ ρ∈(0,1) geometric clustering
                       │
                       ▼
   strong_coupling_decay_of_open_inputs  (Wall256_Scaffold.lean:76, abstract corr/sep)
                       │  ABSTRACT two-point decay shape — LATTICE only, NOT Clay
                       ▼
   ┄┄┄ NO Lean edge exists here ┄┄┄  (lattice strong-coupling decay  ↛  real continuum transfer gap)
                       ▼
   YM_mass_gap_Surface  (Surface #1, MassGap574.lean:69) — scalar/Perron shadow, real-operator gap OPEN
```

The dashed gap is critical: closing `hOS`+`h_bridge`+D1–D3 would discharge only
the **abstract lattice** decay shape of `strong_coupling_decay_of_open_inputs`.
There is **no Lean implication** from that to `YM_mass_gap_Surface` — the latter
is the scalar shadow of the *real* Wilson transfer operator, and the real
continuum mass gap (Surface #1) stays OPEN regardless.

## 0d. Minimal path to close Wall256 (given β₀ certified) — NOT scheduled

Strictly to discharge `strong_coupling_decay_of_open_inputs`'s open inputs
(this is the **lattice** reduction, NOT Surface #1):

1. **`hw1`** `[NEEDS_NUMERICS]` — port a verified `w1 < 1/7` for `β > 2.079416880124`
   into Lean. CERT_Arb gives the rigorous interval out-of-tower; a Lean object
   needs SU(3) character theory or verified cubature — **absent from mathlib v4.12.0**.
2. **D1** `[NEEDS_LEMMA]` — explicit `C, α > 0` connected-polymer count
   `#{γ:|γ|=n} ≤ Cⁿ·ε^{α n}` (E2). The single hardest leaf (Clay-grade combinatorics).
3. **D2** `[NEEDS_LEMMA]` — truncated activity bound `|z(γ)| ≲ e^{−β·energy(γ)}`.
4. **D3** `[BLOCKED_BY D1,D2]` — KP summability `∑_{γ∋0}|z(γ)|e^{|γ|} < ∞`; gives the `Summable` premise.
5. **`hOS`** `[NEEDS_LEMMA, BLOCKED_BY hw1]` — Osterwalder–Seiler step ⟹ `TruncatedActivityBound` with `I > log 7`.
6. **`h_bridge`** `[NEEDS_LEMMA, BLOCKED_BY D3]` — Brydges–Federbush ⟹ geometric clustering.

Even with all six, the result is the **abstract lattice two-point decay shape**,
**NOT** the YM mass gap and **NOT** Surface #1 (see the dashed edge in §0c). No
step is scheduled; steps 2–6 are absent from mathlib v4.12.0 / open research.

---

## 1. `hOS` — the Osterwalder–Seiler cluster step (= KP leaf D5)

- **Lean signature** (`Towers/YM/Wall256_Scaffold.lean:80`, hypothesis of
  `strong_coupling_decay_of_open_inputs`):
  ```lean
  (hOS : w1 < 1 / 7 → TruncatedActivityBound a)
  ```
  where (`Towers/YM/Wall256_Note.lean:72`)
  ```lean
  def TruncatedActivityBound (a : ℕ → ℝ) : Prop :=
    (∀ n, 0 ≤ a n) ∧ ∃ I : ℝ, Real.log 7 < I ∧ ∀ n, a n ≤ Real.exp (-I) ^ n
  ```
- **Consumes:** `hw1 : w1 < 1/7` — the strict single-site weight bound
  (KP leaf D4 / out-of-tower input E1). Per CERT_Arb this needs
  **β > β₀** under the repo action `S = (3 − Re tr U)/3`, with β₀ now CERTIFIED
  (CERT_Arb rigorous interval enclosure) in `[2.079416880123, 2.079416880124]`,
  i.e. the conservative formal requirement is **β > 2.079416880124** (the certified
  upper endpoint); `2.07941688` appears only as a rounded planning shorthand and is
  NOT a safe strict bound. (NOT the stale `β > 0.85`, which was for the
  un-normalized action.)
- **Produces:** `TruncatedActivityBound a` — a per-polymer connected/truncated
  activity bound with rate `I > log 7`, the input KP summability needs. The
  **strict** `I > log 7` is essential: at `I = log 7` the entropy-weighted series
  `∑ₙ 7ⁿ·exp(−I)ⁿ = ∑ₙ 1` diverges.
- **Out-of-tower input:** **E4** — Osterwalder–Seiler 1978 Thm 2.1 (strong-coupling
  Ursell/cluster activity bound; **not** OS reflection positivity). Absent from
  mathlib v4.12.0.
- **Status:** OPEN · OUT_OF_TOWER · in_mathlib_v4_12_0 = false · stub_only.

## 2. `h_bridge` — the Brydges–Federbush bridge (= KP leaf D6)

- **Lean signature** (`Towers/YM/Wall256_Scaffold.lean:81–82`):
  ```lean
  (h_bridge : Summable (fun n : ℕ => N n * a n) →
      0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y))
  ```
  (`corr sep : E → E → ℝ` are ABSTRACT — no real Wilson correlator / lattice
  metric is constructed.)
- **Consumes:** KP-summability `Summable (fun n => N n · a n)` (KP leaf **D3**),
  which itself needs the feeders **D1** (polymer counting) + **D2** (activity
  bound). The genuine, already-landed combinator
  `Wall256Note.kp_summable_of_truncatedActivity` produces this `Summable` premise
  *from* `TruncatedActivityBound a` + `N n ≤ 7ⁿ` (comparison test) — that step is
  machine-checked; what is OPEN is `TruncatedActivityBound` itself (via `hOS`).
- **Produces:** `ρ ∈ (0,1)` geometric two-point clustering ⟹ the target decay
  shape `∃ Δ > 0, ∀ x y, |corr x y| ≤ C·exp(−Δ·sep x y)` (via the genuine
  `ρ^d = exp(−Δ·d)` algebra of `Wall256.mass_gap_pos_of_spectral_gap`).
- **Out-of-tower input:** **E3** — Brydges–Federbush KP ⟹ decay bridge
  (Friedli–Velenik 2018, Ch. 5). Absent from mathlib v4.12.0.
- **Status:** OPEN · OUT_OF_TOWER · in_mathlib_v4_12_0 = false · stub_only.

### 2a. Upstream feeders of `h_bridge`'s `Summable` premise (D1 / D2 / D3)

| Leaf | Statement | Status | OOT input |
| --- | --- | --- | --- |
| **D1** polymer counting | `#{ γ : |γ|=n, energy(γ)<ε } ≤ Cⁿ · ε^{α·n}` (∃ C,α>0) | OPEN — the Clay-grade open combinatorics; the `Transfer.lean` docstring names it the **sole** upstream combinatorial dependency of `kotecky_preiss_criterion_Surface` | **E2** (explicit C,α for the 4D-lattice SU(3)-constrained connected-polymer count) |
| **D2** activity bound | `|z(γ)| ≲ exp(−β·energy(γ))` (truncated/connected weight) | OPEN | — |
| **D3** KP summability | `∑_{γ∋0} |z(γ)| e^{|γ|} < ∞` at finite β₀ | OPEN — follows from D1+D2 (Cⁿ entropy beaten by ε^{α·n} small-energy gain for β large-but-finite) | — |

---

## 3. Consolidated open-obligation inventory

Every named open `Prop` surface / open hypothesis reachable from the Wall256
chain and from `MassGap574` Surface #1. Each is **OPEN**; none discharged.

| # | Object | Location | Statement (abridged) | Tag |
| --- | --- | --- | --- | --- |
| 1 | `hw1` (= D4) | `Wall256_Scaffold.lean:79` | `w1 < 1/7` | OPEN · OUT_OF_TOWER (E1); D4 TESTED_NEGATIVE_CERTIFIED; CERT_Arb: needs **β > 2.07941688**, certified β₀∈[2.079416880123, 2.079416880124] |
| 2 | `hOS` (= D5) | `Wall256_Scaffold.lean:80` | `w1 < 1/7 → TruncatedActivityBound a` | OPEN · OUT_OF_TOWER (E4) · in_mathlib:false |
| 3 | `h_bridge` (= D6) | `Wall256_Scaffold.lean:81` | `Summable (Σ N n·a n) → ρ∈(0,1) clustering` | OPEN · OUT_OF_TOWER (E3) · in_mathlib:false |
| 4 | `kotecky_preiss_criterion_Surface` | `Transfer.lean:409` | `∃ β₀>0, ∀ β>β₀, ∃ gap>0, ∀ L f, (∫f=0) → ‖T_L L β f‖ ≤ exp(−(β·gap))·‖f‖` | OPEN · genuine open combinatorics (D1/E2); non-vacuous (strictly stronger than the proven `‖T_L‖≤1`) |
| 5 | `trivial_polymer_set_null_Surface` | `Transfer.lean:669` | `haarN {w | polymerEnergy (toGauge L w) γ = 0} = 0` | OPEN · **necessary-NOT-sufficient, DIFFERENT branch** — closing it does NOT close KP (single-polymer β→∞ limit vs the uniform finite-β sum KP needs); needs E5 (`NoAtoms_haarSU3`) + E6 (L=1 commuting-variety estimate) |
| 6 | `YM_mass_gap_Surface` (Surface #1, scalar shadow) | `MassGap574.lean:69` | `∃ m>0, spectrum_bound (H U) m` | OPEN · `H U = wilsonAction U • 𝟙` is the SCALAR/Perron shadow, NOT the real Wilson transfer operator; real YM transfer gap is the open Wall 574 work |

### Out-of-tower input ledger (E1–E6)

| E | For | Need | mathlib v4.12.0 |
| --- | --- | --- | --- |
| E1 | D4 (`hw1`) | verified `∫_{SU(3)} exp(−β·S) dHaar < 1/7` for β > β₀ (β₀∈[2.079416880123, 2.079416880124], op. β>2.07941688) | absent in Lean (CERT_Arb supplies the rigorous interval enclosure of β₀ out-of-tower, status VERIFIED_OUT_OF_TOWER; still NOT a Lean object) |
| E2 | D1 | explicit C,α for the 4D-lattice connected-polymer count w/ SU(3) small-energy constraint | absent |
| E3 | D6 (`h_bridge`) | geometric clustering ρ<1 from KP summability (Brydges–Federbush) | absent |
| E4 | D5 (`hOS`) | Osterwalder–Seiler Ursell/cluster activity bound (1978 Thm 2.1) | absent |
| E5 | `trivial_polymer_set_null` | `(𝓝[≠] (1:SU3)).NeBot ⟹ NoAtoms haarSU3` | `IsHaarMeasure.noAtoms` exists; the NeBot precondition is unproved here |
| E6 | L=1 sub-case | SU(3) commuting-variety / regular-element codimension measure estimate | absent |

**Already proven, trio-clean (NOT obligations — context only):** `T_L`
(`Transfer.lean:296`), `transfer_operator_norm_le` (`‖T_L‖≤1`, `:322`),
`polymerActivity` (def, ≥0, antitone-in-β, `~:426`),
`polymerActivity_tendsto_zero_of_null` (DCT reduction, conditional on null hyp,
`:589`), and the comparison-test combinator
`Wall256Note.kp_summable_of_truncatedActivity`.

---

## 4. When promoted to BUILD — STUBS ONLY

If/when any of these is realized in Lean, produce **named open `Prop` stubs
only** — never a proof:

- ✅ `def hOS_Surface (w1 : ℝ) (a : ℕ → ℝ) : Prop := w1 < 1/7 → TruncatedActivityBound a`
  (a named open Prop mirroring the hypothesis), and likewise for `h_bridge`.
- ❌ **Never** `theorem foo := by sorry` — that emits `sorryAx` and breaks the
  axiom lock. The honest post-purge pattern is
  `def Foo_Surface … : Prop := <goal>` + (optionally)
  `theorem foo (h : Foo_Surface …) : <goal> := h`.
- ❌ Do **not** discharge any surface, write a real proof term, edit
  `Wall256_Scaffold.lean` / `Transfer.lean` / `MassGap574.lean`, or claim a mass
  gap / μ>0 / Surface-#1 / Clay result.
- ⚠️ Verify any new `.lean` file with a **direct** `lake env lean <file>` +
  `#print axioms` **only after** asserting
  `git -C lean-proof-towers/.lake/packages/mathlib rev-parse v4.12.0` succeeds;
  never run `towers-build` / `lake update` casually (they wipe the mathlib pin +
  oleans).

---

## 5. Honesty locks

```yaml
status: PLAN_DRAFT
scope: IN_TOWER_PLANNING_DOCS_ONLY
sorry_inventory_reframed: "no bare sorries exist post-purge; inventory NAMED OPEN surfaces/hypotheses"
writes_lean: false
produces_proof: false
discharges_surface: false
closes_surface_1: false
closes_ym_tower: false
m_gt_0_claimed: false
mass_gap_proven: false
surface_1_status: OPEN
ym_tower_status: OPEN
rh_grh_c05_separate: true
no_rh_claims_in_ym_certs: true   # the M7/GRH/C05 tower stays SEPARATE
split_statement: "No RH claims in YM certs."
note: >
  A dependency map enumerates requirements only. hOS and h_bridge stay OPEN named
  hypotheses; every leaf (D1..D6, E1..E6) is open research or absent from mathlib
  v4.12.0. This proves nothing, discharges nothing, schedules no discharge, and
  makes no mass-gap / Surface-#1 / RH claim.
```

## Sources (read-only; not edited)

- `lean-proof-towers/Towers/YM/Wall256_Scaffold.lean` (`hw1`/`hOS`/`h_bridge`)
- `lean-proof-towers/Towers/YM/Wall256_Note.lean` (`TruncatedActivityBound`, `kp_summable_of_truncatedActivity`)
- `lean-proof-towers/Towers/YM/Transfer.lean` (`kotecky_preiss_criterion_Surface:409`, `trivial_polymer_set_null_Surface:669`)
- `lean-proof-towers/Towers/YM/MassGap574.lean` (`YM_mass_gap_Surface:69`)
- `lean-proof-towers/exports/KP_Plan_2026-06-01.json` (D1..D6 / E1..E6 taxonomy)
- `lean-proof-towers/exports/D1_to_D3_hOS_hbridge_depmap_draft.yaml` (prior draft)
- `lean-proof-towers/exports/CERT_Arb_beta0_2026-06-01.yaml` (corrected β₀ threshold)
