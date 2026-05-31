# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **NS Tower 540 — honest weak→strong chain, Phases 1–6 COMPLETE, FROZEN at the
  Clay boundary (Status: Open).** NONE are bricks / in BRICKS / lakefile roots;
  all classical-trio, no `sorryAx` EXCEPT one isolated documented `sorry`
  `leray_proj_ker_eq_grad` in `Leray.lean` (not a brick, not in the weak→strong
  chain). Fourier-side model on `Hdiv_free (s+2)`, `ν = 1`; files P1
  `FunctionSpaces` · P2 `Leray`+`Stokes` · P3 `Energy` · P4 `GalerkinApprox`+
  `Compactness` · P5 `WeakSolution` · P6 `Regularity`. Full per-phase detail →
  `docs/CHANGELOG.md` + `docs/ROADMAP.md`. The two Clay surfaces stay OPEN:
  - **Surface #1 — global regularity: OPEN.** `global_smooth_exists : Prop` is
    the single NAMED Clay surface behind `weak_implies_strong` (unproved
    hypothesis, NOT `by sorry`; `#print axioms` = classical trio).
  - **Surface #2 — weak existence: OPEN (modeled).** `weak_solution_exists` is
    an HONEST COMBINATOR over the MODELED `WeakNS` surrogate (linear weak form;
    nonlinear `(u·∇)u` DROPPED) — NOT a literal Leray–Hopf existence theorem.
  FROZEN milestone `NS-540-phase6-clay-boundary` @ checkpoint
  `c5f29fb4390e5dda83ffdbfcae5dea2333cf5c12`. HONEST: these build spaces,
  name/bound operators, and assemble combinators from NAMED inputs; they prove
  NO NS existence/uniqueness/regularity. NS stays `Status: Open`; YM untouched.

- **Wall:** BRICKS array in `scripts/check-towers.sh` (`${#BRICKS[@]}`) is the
  source of truth for the count, not this file.
- **YM wall series (Wall251b–Wall263, Wall262a, S4Numerics, WilsonPositivitySU2,
  EntropyBound, RiemannianGeometry) — all bricks, in BRICKS; full prose →
  `docs/CHANGELOG.md`.** Every entry is `sorry`-free, `#print axioms` = classical
  trio (verified live, raw `lean` v4.12.0, EXIT=0), and HONEST: each proves NO YM
  result, discharges NO open surface, makes NO mass-gap / μ>0 / Surface-#1 claim,
  and does NOT touch `kotecky_preiss_criterion`. One-line index (newest first):
  - **Wall256_Note** — HONEST CONDITIONAL apex "conditional on the truncated
    activity bound, SU(2) has a gap". `kp_summable_of_truncatedActivity` is the
    GENUINE comparison-test bridge (activity `a n ≤ exp(−I)ⁿ`, `I>log 7` + count
    `≤7ⁿ` ⟹ KP summable); `su2_gap_of_truncatedActivity` threads it through a
    SECOND NAMED OPEN `h_bridge` (Brydges–Federbush KP-summable ⟹ ρ<1 clustering)
    into the gap shape. Entry one step earlier than `mass_gap_pos_of_spectral_gap`;
    proves NO gap (activity rate NOT discharged); abstract corr/sep.
  - **Wall262a_RatioModel** — standalone numeric MODEL of Theoria's R-series
    (invented H4 weights; `R(exp(−0.88)) ≤ 1743/2000`; `1743=3·7·83`,
    `2000=2⁴·5³`); Theoria's "λ_max(2I−M_H4)=φ" FALSE (=2cos(π/30)). Standalone
    leaf, OUT of the YM graph; does NOT discharge `Wall262.hR`.
  - **Wall263_CoxeterSpectral** — axiom-free REFUTATION of "λ_max(2I−M_H4)=φ"
    (`φ` is the label-5 EDGE WEIGHT, not a spectral value; true radius
    `2cos(π/30)≈1.989`). Matrix bridge now MACHINE-CHECKED: concrete
    `B : Matrix (Fin 4) (Fin 4) ℝ`, `det_charmatrix` (Laplace cofactor expansion:
    `det(λI−B) = coxeterCharpoly λ`), and `phi_not_mem_spectrum` (`φ ∉ spectrum ℝ B`
    via `spectrum.not_mem_iff`+`isUnit_iff_isUnit_det`) — all classical trio, 0
    sorry. Only the IDENTITY of the largest eigenvalue (`2cos(π/30)`, h=30) stays
    DOCUMENTARY. Conditional `defect_bound_H4` over NAMED OPEN hyps.
  - **Wall262_ConnectiveRatio** — conditional connective-ratio defect → SU(2)
    polymer-rate win (`R := μ_Z4/φ`; NAMED OPEN `hR`/`h_defect`/`h_rate`).
  - **Wall261_H4Defect** — conditional H4/120-cell defect improvement
    (`C = 1+φ = φ² ≈ 2.618`; NAMED OPEN `h_graph`).
  - **Wall260_ClayReduction** — pointwise defect-form Clay reduction
    (`C=6` combinatorics, `h_defect` analysis; NAMED OPEN).
  - **Wall259_DependenceBound** — dependence-defect reduction
    (`polymerRate := I_E − Defect`; NAMED OPEN `h_defect`/`h_rate`).
  - **Wall258_DependenceDefect** — inter-polymer dependence-defect combinator
    (ℤ⁴ link incidence `2(d−1)=6`; raised threshold `log(7·C)`).
  - **Wall257_RateLowerBound** — MODELED single-site rate (cgf `t²`) clearing
    `log 7`; Gap Lemma: single-site clearing ≠ polymer clearing.
  - **Wall256_RateFunction** — conditional large-deviation rate criterion
    (`log 7 < I ⟺ ∑ₙ 7ⁿe^{−In}` converges; NAMED OPEN `h_rate`).
  - **Wall255_JensenObstruction** — mean-energy NO-GO (Jensen ⟹ the MEAN can
    never give KP smallness; the open problem is the RATE, not the mean).
  - **Wall257_StrongCoupling** — conditional strong-coupling activity bound;
    PROVES the uniform energy floor is FALSE (the vacuum breaks it).
  - **Wall256_MassGapConditional** — conditional mass-gap apex shape from TWO
    NAMED OPEN surfaces (`ρ<1`, KP clustering); proves NO mass gap.
  - **Wall254_OS_Positivity** — conditional OS2 from the genuine Gram-PSD heart
    + NAMED OPEN GNS surface `hGNS`.
  - **Wall255_KP_Entropy** — conditional "beat the 7ⁿ entropy" (needs `q<1/7`,
    NAMED OPEN; Wall252's `<1/2` is not enough).
  - **Wall253_KP_Cluster** — conditional KP cluster expansion (genuine geometric
    layer; entropy DROPPED; NAMED OPEN `hKP`).
  - **Wall252_KP** — MODELED single-term KP smallness majorant `<1/2`.
  - **WilsonPositivitySU2 / Wall251b_H4** — SU(2) Wilson POINTWISE positivity
    (unitarity-only; NOT OS reflection positivity, NOT a mass gap).
  - **S4Numerics** — four standalone TRUE arithmetic facts (group-theoretically
    empty; no H4 Coxeter group constructed).
  - **EntropyBound (YM 249→250)** — conditional polymer entropy bound
    `#{size-n connected polymers} ≤ 7ⁿ` via NAMED OPEN `h_entropy`.
  - **RiemannianGeometry** — SU(3) chordal distance is a genuine metric (the
    CHORDAL metric, NOT the Killing-form geodesic distance).
- **Wall256_Scaffold** (`Towers/YM/Wall256_Scaffold.lean`, NOT a brick, NOT in
  BRICKS, not a lakefile root) — HONEST CONDITIONAL strong-coupling LATTICE
  reduction for SU(3): `strong_coupling_decay_of_open_inputs` threads THREE
  explicit OPEN hypotheses — (1) single-site SU(3) Haar weight `w1 < 1/7`
  (STRICT; equality gives `I = log 7` and a divergent entropy series, so the
  β=0.85 boundary is excluded), (2) the Osterwalder–Seiler Ursell/cluster step
  `w1 < 1/7 → TruncatedActivityBound`, and (3) Brydges–Federbush KP-summability
  ⟹ geometric clustering — through the real, already-landed
  `Wall256Note.su2_gap_of_truncatedActivity` (reused as an abstract combinator;
  the `su2_` name is NOT a group claim) to an abstract two-point decay shape.
  Proves NO mass gap / spectral gap / YM result; makes NO m>0 / Surface-#1
  claim. Verified live (`lake env lean` after restore-lake-git ×2 + retag):
  elaborates EXIT=0, `#print axioms` = classical trio, no `sorry`/`sorryAx`. The
  three open hypotheses are the remaining (open) work; none is scheduled, all are
  Clay-adjacent.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (also `[]` on
  `H2_WeilTransfer`, `M9_WeilTransfer_All`). Every landed brick is
  classical-trio-only.
- **Mathlib:** v4.12.0 only.
- **YM Surface #1: OPEN.** No `m > 0` claim while the `sorry` stands.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) elaborates against the
  real Step-4/5 `H` / `spectrum_bound` and carries `(hpos : 0 < wilsonAction U)`,
  but still carries a `sorry`; INVARIANT-LOCKED, NOT in BRICKS, not a lakefile
  root. The companion `YM_mass_gap_nontrivial` discharges `hpos` for
  non-trivial `U` and is `sorry`-free, but `H = wilsonAction U • 𝟙` is the
  scalar shadow, NOT the real Wilson transfer operator — so no mass-gap claim.
- **Registered YM walls** (tagged files, lake-gated `[YM1-*]`, NOT in BRICKS):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572 `[YM1-LB-Real]`
  (`hamiltonian_pos`), 573 `[YM1-GR]` (`gap_reduction`), 575 `[YM1-SB]`
  (`spectrum_bound` + `spectrum_bound_H_iff`). All classical trio.
- **Deferred:** 24 OS/KP modules unregistered (Task #208); `.lean` files kept
  on disk, await Wall 570+/574 with the real SU(3) `H`.
- **Infra:** mathlib cache self-heal landed (`scripts/fetch-mathlib-oleans.sh`:
  authoritative `lake exe cache get`, no from-source fallback).
- **YM Transfer / polymer / positivity / measure scaffolding (NONE bricks, none
  in BRICKS; all classical-trio, verified live; full detail →
  `docs/CHANGELOG.md`).** Real SU(3) Haar stack (`SU3Instances.lean`: `haarSU3`,
  product `haarN`, probability instances); the real integral transfer operator
  `T_L` with the genuine sub-Markov contraction `‖T_L‖ ≤ 1` (`Transfer.lean` —
  explicitly NOT strict / decay / spectral-gap; `S_min := inf_{U≠1} wilsonAction
  U = 0`); Wilson positivity (`WilsonPositivity.lean`: `wilsonAction_nonneg`,
  `wilsonAction_eq_zero_iff` = all-plaquettes-trivial, NOT `U = 1`); and the
  cluster-expansion `polymerActivity` (nonneg, antitone, empty `= 1`, DCT
  reduction `polymerActivity_tendsto_zero_of_null`). Every lemma is
  necessary-not-sufficient: pointwise positivity / single-polymer `β→∞` decay is
  NOT the mass gap. The OPPOSITE spectral lower bound stays OPEN in the
  disclaimed `sorry` `Transfer.kotecky_preiss_criterion` (downstream of one
  unproved cluster-entropy / Peierls counting bound
  `#{γ : |γ|=n, energy<ε} ≤ Cⁿ·ε^{α·n}`), distinct from the invariant-locked
  `Towers/Attempts/ClusterExpansion.lean` `sorry`. NO `m>0` / μ>0 / mass-gap /
  Surface-#1 claim; Surface #1 stays OPEN.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` remains a `sorry` in
  `Towers/Attempts/ClusterExpansion.lean` (invariant-locked).
- **NS FREEZE.** `Towers/NS/*` is FROZEN at the Clay boundary (milestone
  `NS-540-phase6-clay-boundary`). NO further commits to `Towers/NS/` without an
  explicit unfreeze order from the user. Surface #1 (`global_smooth_exists`) and
  Surface #2 (modeled `weak_solution_exists`) stay OPEN; "NS solved" /
  "regularity proven" / "weak solutions exist (literally)" claims are REFUSED.
  - **Unfreeze exception (2026-05-31): `Towers/NS/Wall300_Scaffold.lean`** added
    under an EXPLICIT user unfreeze order. HONEST CONDITIONAL combinator
    `navier_stokes_global_regularity`: threads THREE named open surfaces —
    weak existence (`∃ u, WeakNS u u₀ f`), local-in-time regularity
    (`global_smooth_exists`), and global continuation / no finite-time blow-up —
    through the genuine `Regularity.weak_implies_strong` to a MODELED global-in-
    time smoothness shape. SORRY: 0, `axiom`-free (classical trio), NOT a brick /
    NOT in BRICKS / NOT a lakefile root. Proves NO regularity; Surfaces #1/#2
    stay OPEN; NS_STATUS: OPEN. Fresh `lake env`/`#print axioms` DEFERRED while
    the `v4.12.0` tag is unresolved (running `lake` would wipe the pin). NS is
    otherwise still frozen at the Clay boundary.
- **Infra (in progress).** Disabling the `towers-build` auto-run and permanently
  locking the mathlib `v4.12.0` pin is tracked as a background Project Task
  (#294); until it lands, every boot/merge can still wipe the pin and require
  the manual recovery in "Operational gotchas".

## Operational gotchas

- **Git-tag creation is restricted for the main agent.** `git tag` (and other
  git writes) are blocked with "Destructive git operations are not allowed in
  the main agent" — they must go through a background Project Task. This repo's
  working convention is therefore to track milestones as **prose + SHA** in
  `replit.md` / `docs/ROADMAP.md` / `docs/CHANGELOG.md` (e.g. "YM frozen at
  `c8f6a7ed`", "milestone `NS-540-phase2b-stokes` @ checkpoint `f4becd5`"),
  NOT as literal git refs. Replit checkpoints already capture the merged state.
- **Do NOT run `towers-build` / `lake update` casually.** Both re-clone the
  vendored mathlib checkout and wipe its oleans, requiring a `lake-recovery`
  (`lake exe cache get`) pass. Verify bricks via direct `lake env lean <file>`
  + `#print axioms` — **but `lake env` is ALSO destructive when the
  `v4.12.0` tag is missing.** `lake env` re-resolves `inputRev: v4.12.0` from
  the mathlib git; if the tag does not resolve it fetches from remote and wipes
  the oleans, exactly like `lake update` (confirmed 2026-05-30). So BEFORE any
  `lake env lean`, assert `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds. Recovery if wiped: `scripts/restore-lake-git.sh`
  (run it TWICE — first run restores `.git` at the pinned rev, second run
  rehydrates the empty worktree via its `git checkout -- .` heal), then recreate
  the tag (`git -C lean-proof-towers/.lake/packages/mathlib tag -f v4.12.0
  809c3fb3b5c8f5d7dace56e200b426187516535a`), then run
  `scripts/fetch-mathlib-oleans.sh` to re-download the oleans.
- The destructive mathlib re-clone is triggered when the restore-tar's vendored
  mathlib `.git` lacks the `v4.12.0` tag (lake fetches from remote to resolve
  `inputRev: v4.12.0`). Fix: recreate the tag locally after any
  `restore-lake-git.sh` worktree rebuild —
  `git -C .lake/packages/mathlib tag v4.12.0 <HEAD>` (manifest `rev` already =
  HEAD). It is NOT persisted in the restore tar.

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## 600-cell geometry — Wall264 (MACHINE-CHECKED geometry leaf; NOT a YM brick)

- **`Towers/YM/Wall264_H4Vertices.lean`** (2026-05-31) — a standalone, formally
  verified leaf for the 600-cell ({3,3,5}, H4 root system) vertex geometry that
  the `theorema-certs` dashboard renders in 3D (mirrors
  `artifacts/theorema-certs/src/lib/h4-600cell.ts`). NOT a brick / NOT in BRICKS
  / NOT a lakefile root / touches NO YM or NS surface.
  - **Proves** (exact φ arithmetic, reuses `Wall261.phi` + `phi_sq_eq : φ²=φ+1`;
    division-free — `(φ-1)/2` stands for `1/(2φ)` since `1/φ = φ-1`): the vertex
    set is exactly `120 = 8 + 16 + 96` (`famA/famB/famC_length`, `vertices_card`);
    every vertex lies EXACTLY on the unit 3-sphere `nSq v = 1`
    (`vertices_on_sphere`, famC closes by `linear_combination (1/2)*phi_sq_eq`);
    and the nearest-neighbor edge separation `2 − φ = 1/φ²` is REALIZED between
    two vertices (`exists_unit_edge` / `edge_realized`).
  - **HONEST SCOPE.** Proves the vertices lie on the sphere and that `2−φ` is
    realized as an edge; does NOT prove global edge minimality (that `2−φ` is the
    MINIMUM over all 7140 pairs) nor the full 720-edge / 12-regular adjacency
    (DEFERRED). Makes NO Yang–Mills, mass-gap, Surface-#1, μ>0, or
    Riemann-hypothesis claim. YM and NS stay `Status: Open`.
  - **Verified live:** classical trio `{propext, Classical.choice, Quot.sound}`
    on `vertices_on_sphere`, `exists_unit_edge`, `vertices_card`, all three
    `*_length`; 0 `sorry`/`sorryAx`; raw `lean` v4.12.0, EXIT=0. Verified by
    DIRECT `lean` (NOT `lake`/`check-towers.sh`): the mathlib `v4.12.0` git tag
    is currently unresolved, so `lake env` would wipe the oleans — but the oleans
    themselves are intact, so compile with a hand-built
    `LEAN_PATH = <each .lake/packages/*/.lake/build/lib>:.lake/build/lib` and
    invoke `lean Towers/YM/Wall264_H4Vertices.lean` from `lean-proof-towers/`.
  - **Website plaque.** `/miegakure` (`artifacts/theorema-certs`) carries a
    "✓ Machine-checked" card stating exactly the three proven facts, the
    classical-trio axiom footprint, 0 `sorry`, and the explicit scope disclaimer
    (no YM / mass-gap / RH claim; edge minimality + 720-edge structure deferred).

## Hodge X₅ — Zoe Comparison Test (HONEST conditional reduction; NOT a brick)

- **`Towers/Hodge/ZoeComparisonTest.lean`** (2026-05-31, new `Towers/Hodge/`
  dir) — an honesty-locked Hodge leaf for `X₅ = Jac(y² = x¹¹ − x)` centered on
  the **Zoe Comparison Test** generating function
  `𝔗(ω,s) = Σ_{n≥0} Z(ω)ⁿ/(n!)² · ⟨ω, Frobⁿ ω⟩ · q^{ns}`. Standalone (imports
  only `Mathlib.Analysis.SpecificLimits.Normed` +
  `Mathlib.Data.Nat.Choose.Basic`). NOT a brick / NOT in BRICKS / NOT a lakefile
  root / touches NO YM or NS surface. **HODGE_STATUS: OPEN.**
  - **Machine-checked (classical trio, 0 sorry):**
    - **Combinatorics (`choose_5_2`=10, `choose_5_4`=5, `rank_H_X5`=15,
      `rank_gt_test`: 10<15).** The `15` is the **Hankel rank** (Paper-2 input
      datum), a DIFFERENT quantity from the Zoe invariant. `Z_X5_bound`: the Zoe
      bound `1 ≤ Z ≤ p` with `p = 2` caps **Z ≤ 2, NOT 15** — never conflate.
    - **`𝔗` is ENTIRE (R = ∞)** (`summable_pow_div_factorial_sq`,
      `summable_abs_zoeTerm`, headline `radius_infinite`): for any `Z, b = q^s ≥ 0`
      and ANY Frobenius pairing
      obeying the geometric Weil bound `|⟨ω,Frobⁿω⟩| ≤ C·Bⁿ`, the term sequence
      is absolutely summable — the `(n!)²` denominator overwhelms any geometric
      growth. This **REFUTES the earlier "radius 0 / pole at s=1" claim**: `𝔗`
      as literally defined supplies NO divergence and hence NO obstruction. (The
      Weil bound is a carried hypothesis, not proved.)
    - **`step3_degenerate`** (`Nat.choose 1 2 = 0`): a Wall263-style axiom-free
      refutation of Lemma 7.6 Step 3 — the literal bound `Z ≤ C(dim NS, p)` gives
      `C(1,2)=0`, degenerate; Step 3 conflates wedge-of-NS dimension with tensor
      rank. Refutes the *step*, not the Hodge conjecture.
  - **`hodge_obstruction_conditional` (CONDITIONAL, SORRY: 0, axiom-free).** The
    "divergence ⇒ transcendence ⇒ Hodge" step appears ONLY as a combinator over
    a SINGLE named-open `Prop` (`AnalyticObstruction := (Diverges ω →
    Transcendental ω)`), closed by `exact h h_div`
    (Wall256/Wall300 pattern), never `by sorry`. It is **VACUOUS for the actual
    object**: T3 shows `𝔗` is entire, so the divergence antecedent is never met
    — it proves transcendence of NO actual class. `Cls`/`Transcendental`/
    `Diverges`/`pairing` are ABSTRACT.
  - **Verified live (direct-lean bypass, NOT `lake`):** the mathlib `v4.12.0`
    git tag is currently unresolved, so `lake env` would wipe the oleans; oleans
    intact ⟹ compile with a hand-built `LEAN_PATH` over the 7
    `.lake/packages/*/.lake/build/lib` dirs and invoke `lean` v4.12.0 directly.
    EXIT=0; `#print axioms` = classical trio on `summable_*`, axiom-free on the
    conditional / arithmetic theorems; 0 `sorry`/`sorryAx`.

### Appendix A — superseded / uncertified Hodge prior work

- **Lemma 7.6 (the "M.S. bound")** — Muse-Spark-generated, **uncertified; proof
  unsound; SUPERSEDED.** Never machine-stamped as an obstruction.
- **The M\* Transform** (`M*(ω) := (12/11)·(1/Z)`) — a **bijection of `Z`**
  (`M* = 4/55 ⟺ Z = 15`), so "M\* ⇒ Hodge fails" is Lemma 7.6's contrapositive
  renamed: it carries **no independent proof content**. Circular; SUPERSEDED.
- The earlier **"200 classes transcendental via Lemma 7.6"** claim is RETRACTED
  / never landed in docs or dashboard; replaced by the honest machine-checked
  statements above. The divergence⇒transcendence step is a NAMED OPEN analytic
  hypothesis; Hodge stays OPEN (Clay / CMI).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.

## Wall256 Status: SU(3) Conditional Reduction

- **COMMIT:** `8eeab54`
- **FILE:** `Towers/YM/Wall256_Scaffold.lean` — tracked on main (committed, not
  deleted) [PERMANENT]
- **AXIOMS:** `[propext, Classical.choice, Quot.sound]` (classical trio)
- **NEW_AXIOMS:** 0
- **SORRY:** 0
- **YM_STATUS:** OPEN
- **SCOPE:** Conditional reduction only. The machine-checked content is the
  threading `(1) ⟹ TruncatedActivityBound ⟹ KP-summable ⟹ (3) ⟹ decay` through
  the genuine `Wall256Note.kp_summable_of_truncatedActivity` comparison test and
  the `ρ^d = exp(-Δ·d)` algebra. The conclusion (abstract two-point decay) is
  VALID ONLY IF the three hypotheses below hold. Proves NO mass gap, NO `μ > 0`,
  NO Surface-#1; LATTICE scope, NOT Clay. `corr`/`sep` are abstract.

### Open hypotheses (none discharged)

These are the three explicit hypotheses of
`strong_coupling_decay_of_open_inputs`; descriptions match the actual file (the
labels are issue names, not new claims):

1. **`w1_SU3_bound`** (`hw1 : w1 < 1/7`) — OPEN. The strict single-site SU(3)
   Haar weight bound. STRICT matters: `= 1/7` gives `I = log 7` and a divergent
   `∑ 7ⁿ(1/7)ⁿ` entropy series. Requires SU(3) character theory or verified
   cubature — neither in mathlib v4.12.0.
2. **`OS_cluster_bound`** (`hOS : w1 < 1/7 → TruncatedActivityBound a`) — OPEN.
   The Osterwalder–Seiler strong-coupling Ursell/cluster step: single-site Haar
   smallness ⟹ truncated connected-polymer activity rate `I > log 7`. (NOT
   Osterwalder–Schrader reflection positivity.)
3. **`KP_implies_decay`** (`h_bridge`) — OPEN. The Brydges–Federbush step:
   KP-summability of the entropy-weighted polymer series `∑ₙ N n · a n < ∞` ⟹
   geometric two-point clustering with spectral radius `ρ < 1`. Standard
   cluster-expansion theory (Friedli–Velenik 2018, Ch. 5), absent from mathlib
   v4.12.0. (NOT Källén–Lehmann → Wilson area law.)

> **Note (hypothesis 1).** In the scaffold `w1 : ℝ` is currently an ABSTRACT
> real, so `hw1` is formally trivial and proves nothing physical. A real
> definition requires `w1 := ∫_{SU(3)} exp(-β·S) d haarSU3` (the genuine
> single-site Haar weight; `haarSU3` and the action exist, integrability follows
> from `continuous_wilsonAction_toGauge`). The strict bound `w1 < 1/7` is
> unprovable without new mathlib infrastructure (SU(3) Peter–Weyl / character
> orthogonality, or verified numerical integration over the 8-dim manifold).

Tower phase complete. Scaffold landed. Research phase begins.
