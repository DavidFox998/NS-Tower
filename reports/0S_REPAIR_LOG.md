# 0S BRICK REPAIR LOG — `TheoremaAureum.Towers.YM.OS`

_Mode: `REPAIR_WITH_FULL_FORENSICS` · Guards: `ABORT_ON_SORRY=1`,
`ABORT_ON_T0S_ZERO=1`, `ABORT_ON_AXIOM_BLOAT=1`_
_Generated 2026-06-03 · WHEN-tag: **2026-06-03 Universal Phase Shift audit**_
_REPORT-ONLY: no brick modified, no `lake`/`lake env` invoked, no deletion._

---

## Directive-vs-repo reconciliation (read first)

The directive targets `lean-proof-towers/Towers/YM/0S/` files containing the
literal token **`T_0S = 0`**. Neither exists in this repository:

- There is **no `Towers/YM/0S/` directory.** The real sources are flat files
  `lean-proof-towers/Towers/YM/*.lean` under the Lean namespace
  `TheoremaAureum.Towers.YM.OS` (`OS`, capital-O capital-S, not zero-S).
- A repo-wide search for `T_0S` returns **zero matches.** The vacuity is not
  carried by a literal `T_0S = 0` assignment; it is carried by **witness
  collapse** — the predicate is inhabited by the *zero operator*
  `(0 : ℂ →L[ℂ] ℂ)`, the *zero function* `fun _ => 0`, or a `rexp ≤ rexp`
  pass-through. So the directive's `ABORT_ON_T0S_ZERO` guard is read here as
  "abort if the conclusion still collapses to the trivial/zero witness."

The 13 files below are the genuinely-vacuous OS bricks (cross-ref
`vacuous_dossier.md`). The other 12 OS bricks are genuine modeled lemmas and
are out of scope.

---

# PHASE 1 — DIAGNOSIS

For each brick: **WHAT** (file/theorem/lines) · **WHY_VACUOUS** (the
derivation chain that collapses to the trivial/zero witness) · **WHERE_FAILS**
(the ζ-protocol violation it instantiates) · **WHEN**.

The shared **WHERE_FAILS** pattern, in the language of
`docs/zeta-methodology-field-notes.md`: every brick applies a *real predicate
shape* to the *wrong object* (a zero/degenerate witness), so the tool yields
only the **vacuous** bound — the precise failure mode of Link (3) ("the cited
tools … are pointed at a density-`1` set, so they yield **no dimension drop** …
the claimed `D_H ≤ 1 − c/V` is, at best, the vacuous `D_H ≤ 1`"). The
load-bearing object (a real Wilson transfer operator with positive spectral
gap) is absent from the stack, exactly as the ζ chain's load-bearing step (the
dimension-drop / exponential-sum saving) does not exist (§"What would actually
be needed", §"Non-claim statement").

---

### 1. `ClusteringCore.lean :: OS.clusters_zero`
- **WHAT:** `lean-proof-towers/Towers/YM/ClusteringCore.lean` — `lemma clusters_zero` — lines 62–66.
- **WHY_VACUOUS:** `clusters μ f g := Tendsto (n ↦ ∫ f·g ∂μ) atTop (𝓝 (∫f)(∫g))` is witnessed at `f = g = (fun _ => 0)`. Then `∫ 0·0 ∂μ = 0` and `(∫0)(∫0) = 0`, so the goal is `Tendsto (fun _ => 0) atTop (𝓝 0)` — `simp`-trivial. Inhabitedness only.
- **WHERE_FAILS:** ζ-protocol Link (3) verdict — a genuine tool (cluster property) pointed at the trivial correlator yields no decay information. No nontrivial YM correlator is touched.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 2. `MassGapStandin.lean :: OS.massGap_standin_example`
- **WHAT:** `…/MassGapStandin.lean` — `lemma massGap_standin_example` — lines 75–76.
- **WHY_VACUOUS:** `hasMassGapLowerBound μ := ∃ C, 0 < C ∧ 0 < μ` — a pure conjunction-of-positivity with **no operator and no tail wired in**. Witnessed by `⟨1, one_pos, one_pos⟩`. The mass `μ` is decorative; nothing bounds a spectrum.
- **WHERE_FAILS:** ζ-protocol §"Non-claim statement" — asserts a positivity shape while the load-bearing content (a real spectral/tail bound) is absent; "with the honest `c = 0` … it asserts nothing" (Link 3 knock-on), the YM analogue being "with no operator, it asserts nothing."
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 3. `SpectralGapCore.lean :: OS.hasMassGap_zero`
- **WHAT:** `…/SpectralGapCore.lean` — `lemma hasMassGap_zero` — lines 79–86.
- **WHY_VACUOUS:** `HasMassGap H T m := 0 < m ∧ ∀ x, (⟪x, T x⟫_ℂ).re ≤ (1-m)‖x‖²`, witnessed by `T = (0 : ℂ →L[ℂ] ℂ)`, `m = 1`. LHS `(⟪x,0⟫).re = 0`, RHS `(1-1)‖x‖² = 0` ⇒ `0 ≤ 0`. The witness operator has spectrum `{0}` (maximally degenerate). **NOTE:** the `HasMassGap` *definition* (lines 70–72) is genuine and is re-used by the keeper bricks `NontrivialGap` and `Continuum`; only the `hasMassGap_zero` *witness* is vacuous.
- **WHERE_FAILS:** ζ-protocol Link (3) — real predicate, degenerate object ⇒ vacuous bound. The zero operator is the YM analogue of the density-`1` set: it satisfies the shape for "the dumbest possible reason."
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 4. `TransferOperatorBound.lean :: OS.transfer_gap_zero`
- **WHAT:** `…/TransferOperatorBound.lean` — `lemma transfer_gap_zero (m L : ℝ)` — decl @ 82 (body to ~line 85).
- **WHY_VACUOUS:** transfer-gap bound with `T = P₀ = 0` ⇒ `‖0 - 0‖ = 0 ≤ exp(-m·L)` (RHS positive). No real transfer operator; the spectral projection and the operator coincide at zero.
- **WHERE_FAILS:** ζ-protocol Link (3)/(5) — the bound holds because both sides are decoupled from any spectrum; quantitatively inert, like the `0.998` non-sharp dimension figure.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 5. `TwoPointDecay.lean :: OS.clustering_zero_from_transfer`
- **WHAT:** `…/TwoPointDecay.lean` — `lemma clustering_zero_from_transfer (m L : ℝ)` — decl @ 82 (body to ~line 89).
- **WHY_VACUOUS:** concludes `hasExponentialClustering (fun _ => 0)` ⇒ `|0| ≤ C·exp(-m·t)`; the zero correlator decays trivially for every `C ≥ 0`.
- **WHERE_FAILS:** ζ-protocol Link (3) verdict — exponential-decay shape against a zero object: "no dimension drop," YM analogue "no decay information."
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 6. `MassGapFromDecay.lean :: OS.mass_gap_from_clustering_zero`
- **WHAT:** `…/MassGapFromDecay.lean` — `lemma mass_gap_from_clustering_zero` — decl @ 76 (body to ~line 80).
- **WHY_VACUOUS:** re-exports the `hasMassGap_zero` zero-operator witness; inherits §3's vacuity verbatim.
- **WHERE_FAILS:** ζ-protocol §"Non-claim statement" — a derived conclusion downstream of a vacuous input is itself vacuous (no new content created by re-wrapping).
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 7. `IntegratedTailReal.lean :: OS.integrated_tail_le_exp`
- **WHAT:** `…/IntegratedTailReal.lean` — `lemma integrated_tail_le_exp (L m : ℝ) (_hm) (_hL)` — decl @ 73 (body to ~line 76).
- **WHY_VACUOUS:** `integrated_tail L m := rexp(-m·L)` *by definition*; the claimed bound is `rexp(-m·L) ≤ rexp(-m·L)` ⇒ `le_refl`. No integral is actually performed.
- **WHERE_FAILS:** ζ-protocol §"What would actually be needed" — the genuine object (a real integrated heat-kernel tail) is replaced by its own RHS; a `le_refl` pass-through is the YM analogue of "no power saving."
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 8. `TransferGapReal.lean :: OS.transfer_gap_real`
- **WHAT:** `…/TransferGapReal.lean` — `theorem transfer_gap_real (T P₀ : ℂ →L[ℂ] ℂ) (m L : ℝ)` — decl @ 67 (body to ~line 71).
- **WHY_VACUOUS:** despite naming `T P₀`, the conclusion routes through the def pass-through `integrated_tail = rexp(-m·L)`; the operators are never used to produce a spectral quantity. "Real" in the name, not in the math.
- **WHERE_FAILS:** ζ-protocol Link (5) verdict — a growth/decay claim that is "not load-bearing": the named operands do no work.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 9. `MassGapReal.lean :: OS.mass_gap_from_transfer`
- **WHAT:** `…/MassGapReal.lean` — `lemma mass_gap_from_transfer {m} (hm : 0 < m) (hm1 : m ≤ 1)` — decl @ 80 (body to ~line 86).
- **WHY_VACUOUS:** existential witness `(H, T) := (ℂ, 0)` — the 1-dimensional space with the zero operator, maximally trivial. Inherits §3.
- **WHERE_FAILS:** ζ-protocol §"Non-claim statement" — existence-via-degenerate-witness establishes consistency, never the real (`T_real > 0`) statement.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 10. `ClusteringImpliesGap.lean :: OS.clustering_implies_gap`
- **WHAT:** `…/ClusteringImpliesGap.lean` — `theorem clustering_implies_gap (m) (hm) (hm1)` — decl @ 70 (body to ~line 79).
- **WHY_VACUOUS:** from `clustering (fun _ => 0)` to `HasMassGap` via the `(ℂ, 0)` witness; both ends are the trivial objects of §3 and §5.
- **WHERE_FAILS:** ζ-protocol Link (3) verdict — an implication whose hypothesis and conclusion are each vacuous transmits no content (cf. "Lemma33 … with the honest `c = 0` … asserts nothing").
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 11. `TransferImpliesClustering.lean :: OS.transfer_implies_clustering`
- **WHAT:** `…/TransferImpliesClustering.lean` — `theorem transfer_implies_clustering (m L) (_hm)` — decl @ 61 (body to ~line 67).
- **WHY_VACUOUS:** witnesses `hasExponentialClustering (fun _ => 0)`; the implication discharges into the zero correlator (§5).
- **WHERE_FAILS:** ζ-protocol Link (3) — tool applied to the wrong (zero) object.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 12. `TailImpliesTransfer.lean :: OS.tail_implies_transfer`
- **WHAT:** `…/TailImpliesTransfer.lean` — `theorem tail_implies_transfer (m L)` — decl @ 62 (body to ~line 69).
- **WHY_VACUOUS:** pass-through on `integrated_tail = rexp(-m·L)` (§7); no real tail or transfer operator participates.
- **WHERE_FAILS:** ζ-protocol §"What would actually be needed" — the missing power-saving / genuine bound is silently replaced by an identity.
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

### 13. `GapToDecay.lean :: OS.gap_to_decay`
- **WHAT:** `…/GapToDecay.lean` — `theorem gap_to_decay (m) (_hm) (_hm1)` — decl @ 52 (body to ~line 58).
- **WHY_VACUOUS:** witness `f t := rexp(-m·t)`, goal `|rexp(-m·t)| ≤ 1·rexp(-m·t)` ⇒ trivial via `abs_of_pos`. A self-bound, no operator.
- **WHERE_FAILS:** ζ-protocol Link (5) verdict — a decay statement that is "quantitatively inert."
- **WHEN:** 2026-06-03 Universal Phase Shift audit.

---

# PHASE 2 — REPAIR ATTEMPT (`T_real > 0`)

**Goal of the attempt:** for each brick, replace the zero/degenerate witness
with a *real* transfer operator `T_real` having a positive spectral gap, and
re-derive the conclusion non-vacuously, then verify.

**Outcome: ABORT (all 13).** The attempt is **structurally** blocked, and each
viable continuation trips one of the directive's own guards.

### Why a non-vacuous `T_real > 0` proof cannot be constructed

1. **No Wilson transfer operator exists in the stack.** A real `T_real` is the
   transfer matrix of the lattice Wilson action on `L²(SU(3)^E)`. Building it
   needs SU(3) Haar integration against `exp(-β·S_Wilson)` and the associated
   self-adjoint integral operator. mathlib **v4.12.0** has no SU(3) character
   theory, no verified Haar cubature for SU(3), and no Wilson transfer
   construction. (Cross-ref `replit.md` "Wall256" notes and memory
   `su3-haar-instances`, `w1-su3-normalization-threshold`.)

2. **No spectral-gap theorem to invoke.** Even granting `T_real`, the positive
   gap `‖T_real - P₀‖ ≤ exp(-m·L)` with `m > 0` is precisely the **OPEN**
   Surface #1 / Kotecký–Preiss criterion that the whole tower leaves
   undischarged (`Transfer.kotecky_preiss_criterion`,
   `YM_mass_gap_Surface`). There is nothing in v4.12.0 to close it.

3. **Every concrete continuation trips a guard:**
   - Keeping the existing witness ⇒ conclusion still collapses to the zero
     object ⇒ **`ABORT_ON_T0S_ZERO`**.
   - Substituting `T_real` and finishing the now-unprovable goal with `sorry`
     (or `admit`) ⇒ **`ABORT_ON_SORRY`**.
   - Introducing the gap as a fresh `axiom` to discharge it ⇒
     **`ABORT_ON_AXIOM_BLOAT`** (would break the `[]` footprint on
     `main_theorem` and the classical-trio lock).

### `lake env lean` step — deliberately NOT executed

The directive's "Attempt `lake env lean --run`" was **not** run, for two
independent reasons:

- **Nothing valid to compile.** Per the above, no non-vacuous edit exists to
  test; running the compiler on an unmodified brick re-confirms only the
  already-known vacuous status.
- **`lake env` is destructive here.** With the `v4.12.0` tag unresolved,
  `lake env` re-resolves `inputRev: v4.12.0` from the mathlib git and **wipes
  the vendored oleans** (confirmed 2026-05-30; see `replit.md` "Operational
  gotchas" and memory `direct-lean-verify-bypass`). Honoring `REPAIR` without a
  forbidden side effect means not invoking it. If a compile is ever wanted, the
  safe path is the direct-`lean` bypass over the existing oleans, not `lake
  env`.

### Static guard check (no compile)

- **`ABORT_ON_SORRY`:** the 13 bricks currently contain **0** `sorry`/`admit`
  proof-terms (they are vacuous-but-honest). No `sorry` was introduced. ✔ clean.
- **`ABORT_ON_T0S_ZERO`:** every brick still collapses to the zero/degenerate
  witness — **this guard fires**, which is the correct signal that the bricks
  are unrepaired, not that they were silently "fixed."
- **`ABORT_ON_AXIOM_BLOAT`:** 0 file-level `axiom`/`constant` declarations
  across the 13 (cross-ref `AXIOMS_STATIC.txt`); none added. ✔ clean.

---

## VERDICT

**REPAIR ABORTED — no brick modified.** The 13 OS bricks are *structurally*
vacuous: they instantiate genuine predicate shapes with degenerate witnesses
because the load-bearing object (a real Wilson transfer operator with a proven
positive spectral gap) does not exist in mathlib v4.12.0. This is the YM mirror
of the ζ-methodology's central honest finding — the load-bearing step is the one
that does not exist (`docs/zeta-methodology-field-notes.md`,
§"What would actually be needed", §"Non-claim statement").

No `sorry` was injected, no axiom was added, no `lake`/`lake env` was run, and
no source file was changed. The honest, non-destructive disposition for these
bricks remains the repo's established surface-purge pattern (convert each
vacuous `theorem`/`lemma` to a named **open `Prop`** capturing the real
undischarged statement and **de-register** it from the `BRICKS` array in
`scripts/check-towers.sh`) — which requires an explicit go-ahead because it
edits 13 registered bricks plus the registry. Until then, the bricks stay as-is
and are documented here as OPEN.

Surface #1 / YM mass gap stay **OPEN**. No mass-gap / `μ > 0` / Surface-#1
claim is made or implied by this log.
