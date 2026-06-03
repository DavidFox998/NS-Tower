# Roadmap — five towers we want to reach

This is the *research roadmap* for the Morning Star Project. None of
the five towers below is proved in this repo. The Lean spine
(`TheoremaAureum.main_theorem`, axioms = []) closes the deductive
chain `H1 → H2 → main_theorem` *given* Prop-level stubs declared in
`lean-proof/TheoremaAureum/Certificates.lean`. Closing those stubs
is the open work.

Status legend:

- **Open** — the statement is a Prop stub in Lean; no proof in this
  repo; closing it is research-grade work.
- **Certified for N=397** — the specific conductor `N = 397` is
  discharged in `m9.out` and pinned by the spine; the general
  statement remains Open.
- **Certified in spine** — the named theorem actually closes inside
  the Lean spine without new axioms.

> **SORRY-purge note (2026-05-31).** Every live `sorry` proof-term across
> `Towers/` has been converted to a named open `Prop` hypothesis (Option B),
> and the BSD `axiom`s to hypotheses. This is logical hygiene only: it removes
> `sorryAx` from the touched files but **discharges no surface and proves no new
> result.** All five towers below stay **Open**; YM is a conditional reduction
> only, NS keeps Surfaces #1/#2 Open, and Hodge stays Open behind the named-open
> `AnalyticObstruction`.

---

## 1. Riemann Hypothesis (RH)

**Status: Open — first brick formalized (N-monotonicity in Lean; axiom footprint = subset of mathlib's classical core {propext, Classical.choice, Quot.sound}, no research-grade axioms).**

- Computational evidence in this repo: 20,954 nontrivial ζ zeros
  located on the critical line via `kernel.sieve_zeros` /
  `zeta_sniper`, every refined `t` satisfying `|ζ(½ + it)| < 1e-49`,
  all appended to the Genesis-sealed ledger.
- Lean stub: `TheoremaAureum.RiemannHypothesis : Prop` in
  `Certificates.lean`. Not proved here. The spine's `main_theorem`
  has type `RiemannHypothesis`, but the proof depends on the
  Prop-stub `H2_WeilTransfer` and on the structure of the
  declaration in `Certificates.lean`, not on a Lean formalization
  of the analytic statement.
- First honest formal brick: `lean-proof-towers/Towers/RH/ZeroDensity.lean`
  defines `N σ T` (the count of nontrivial `riemannZeta` zeros in
  `[σ, 1] × [0, T]`) on top of mathlib's real `riemannZeta`, proves
  the trivial monotonicity lemma `N_monotone_in_sigma` with axiom
  footprint contained in mathlib's classical core
  `{propext, Classical.choice, Quot.sound}` (no `sorryAx`, no
  user-declared axioms), and pins
  `RiemannVonMangoldt_setCounting_statement : Prop` (the multiplicity-free
  variant of the classical Titchmarsh §9.4 statement, with `0 < C`)
  as a named target for a future plan. The lemma is conditional on
  finiteness of the larger box (the Riemann–von Mangoldt-adjacent
  fact that is itself not yet in mathlib v4.12.0) — discharging
  that finiteness is the next step. Lives in a **sibling package**
  `lean-proof-towers/` so the fast spine drift guard stays
  mathlib-free. Built by `scripts/check-towers.sh` / the `towers-build`
  workflow, not by the fast `lean-proof` workflow.
- Honest note: a computational verification window does not imply
  RH. A formal proof would require, at minimum, formalizing a
  zero-density estimate strong enough to rule out off-line zeros,
  which is itself an open mathlib-scale project.

## 2. Yang-Mills mass gap

**Status: Open — seven trio-clean SU(3) bricks formalized in `Towers/YM/MassGap.lean` (real `Matrix.specialUnitaryGroup (Fin 3) ℂ` algebra: monoid identity left/right, unitarity and det = 1 of each component, plus closure under multiplication for both. Axiom footprint = subset of mathlib's classical core `{propext, Classical.choice, Quot.sound}`; no research-grade axioms).**

- Geometric invariant under study in this repo:
  `C(S₄) = 11.4221486889`, an OpenCV-derived symmetry-count
  invariant attached to the M0 cube observations (`cube_M0_v*.jpg`,
  Appendix A of the architecture write-up).
- Honest formal bricks: `lean-proof-towers/Towers/YM/MassGap.lean`
  defines `SU3Connection := Fin 4 → Matrix.specialUnitaryGroup
  (Fin 3) ℂ` (the trivial-bundle constant-coefficient case of an
  SU(3) connection on ℝ⁴ — four constant SU(3)-valued fields, one
  per spacetime direction) and proves seven trio-clean lemmas
  against the real `Matrix.specialUnitaryGroup` API in
  `Mathlib/LinearAlgebra/UnitaryGroup.lean`:
  `SU3Connection_one_mul`, `SU3Connection_mul_one`,
  `SU3Connection_one_one`, `SU3Connection_component_unitary`,
  `SU3Connection_component_det_one`,
  `SU3Connection_component_mul_unitary`,
  `SU3Connection_component_mul_det_one`. Axiom footprint contained
  in `{propext, Classical.choice, Quot.sound}`; no `sorryAx`, no
  user-declared axioms in any brick. Alongside, the file pins
  `YM_mass_gap_statement : Prop` as a *statement schema* with
  two `sorry`-backed defs (`YMHamiltonian`, `IsEigenstate`) plus
  `HilbertSpace`, which Task #55 (2026-05-26, Branch A) upgraded
  from `sorry` to `lp (fun _ : ℕ => ℂ) 2` — i.e. ℓ²(ℕ,ℂ), the
  canonical separable infinite-dim complex Hilbert space from
  `Mathlib.Analysis.InnerProductSpace.l2Space`. **That upgrade is
  NOT a promotion of the YM tower.** ℓ²(ℕ,ℂ) is a real Hilbert
  space but it is NOT the Yang-Mills physical Hilbert space — the
  actual YM Hilbert space requires an Osterwalder–Schrader
  reconstruction from a constructed 4D Euclidean YM measure that
  does not exist in mathlib v4.12.0 (and is itself open in 4D
  pure YM). The remaining two sorries are honest stand-ins
  because mathlib v4.12.0 lacks the Wightman/Osterwalder-Schrader
  axiomatic QFT framework, a constructive 4D Yang-Mills
  Hamiltonian, and the Sobolev-space spectral theory the
  statement needs. Statement-only, no
  `True.intro`. Built by `scripts/check-towers.sh` / the
  `towers-build` workflow. **The trivial-bundle constant-coefficient
  SU(3) connection is a scaffold for future work, not a physically
  meaningful Yang-Mills configuration** — a real connection is a
  Lie-algebra-valued 1-form on a principal bundle over (at least)
  a 4-manifold.
- Retirement note (2026-05-26, Task #50 Option A): a sibling file
  `Towers/YM/Gauge.lean` previously held six `gauge_action_*`
  bricks on a `TrivialConfiguration G` scaffold whose `MulAction`
  was `· • A := A`. Every `gauge_action_*` lemma reduced
  definitionally on both sides to `A`, exercising neither group
  multiplication nor the action; the bricks were hollow even by
  trivial-brick standards. The whole file was withdrawn — see git
  history. YM bricks now live exclusively against the real
  `Matrix.specialUnitaryGroup` API.
- Honest note: `C(S₄) > 2√32` is an arithmetic fact about a
  cube-counting invariant. It is **not** a mass-gap lower bound on
  any Yang-Mills Hamiltonian, and no derivation in this repo
  connects it to the Jaffe-Witten Clay problem. Treat it as
  conjectural scaffolding for a future link, not as evidence for
  the mass gap. The seven SU(3) bricks in `Towers/YM/MassGap.lean`
  above do not advance the mass gap past `Open` — they are
  elementary monoid/unitarity facts about the trivial-bundle
  constant-coefficient SU(3) connection on the way there, not
  spectral lower bounds on any Yang-Mills Hamiltonian.
- Distance-predicate tripwire (Task #209,
  `Towers/YM/RiemannianGeometry.lean`): the SU(3) distance used by
  the heat-kernel envelope is only a *pseudo-distance*, never a real
  metric. A new `IsMetricOnSU3 d` predicate (pseudo-dist ∧ separation
  `d g h = 0 → g = h` ∧ triangle inequality) makes the missing
  separation axiom explicit, and the brick
  `not_IsMetricOnSU3_const_zero` PROVES that the `d ≡ 0` stand-in
  (`fun _ _ => 0`) FAILS `IsMetricOnSU3` — witnessed by the concrete
  non-identity element `cWit = diag(-1,-1,1) ∈ SU(3)` (`cWit_ne_one`),
  on which any zero distance would falsely force `cWit = 1`. This
  constructs NO real geodesic/Killing-form distance and makes NO
  mass-gap, μ>0, or Surface-#1 claim; it only records honestly that
  the current stand-in is not a metric. Axiom footprint of both bricks
  = `{propext, Classical.choice, Quot.sound}`. YM stays
  **Status: Open**.

## 3. Navier-Stokes global regularity

**Status: Open — eight trio-clean divergence bricks formalized in `Towers/NS/Divergence.lean` (linearity under addition / scalar multiplication / negation / subtraction, plus the zero, constant, add-constant, and sub-constant cases of a minimal fderiv-based divergence operator on `Differentiable ℝ` vector fields; axiom footprint = subset of mathlib's classical core `{propext, Classical.choice, Quot.sound}`, no research-grade axioms).**

- Conjectural scaffolding in this repo: "Arakelov descent from
  `X_0(397)`" is a label for a proposed bridge from heights on a
  modular curve to PDE energy estimates.
- Honest formal bricks: `lean-proof-towers/Towers/NS/Divergence.lean`
  defines a minimal `divergence` operator on smooth vector fields
  `V → V` (where `V = EuclideanSpace ℝ (Fin 3)`) as the sum of the
  Fréchet-derivative-based directional derivatives along the three
  coordinate axes, and proves eight trio-clean linearity lemmas
  (`divergence_add`, `divergence_smul`, `divergence_zero`,
  `divergence_neg`, `divergence_sub`, `divergence_const`,
  `divergence_add_const`, `divergence_sub_const`) by delegating to
  mathlib's `fderiv_add`/`fderiv_smul`/`fderiv_const`/etc. and
  `Finset.sum_*` lemmas. Axiom footprint contained in mathlib's
  classical core `{propext, Classical.choice, Quot.sound}` (no
  `sorryAx`, no user-declared axioms in any brick). Alongside,
  the sibling file `Towers/NS/EnergyIneq.lean` pins
  `NS_global_regular_statement : Prop` as a *statement schema*
  with two `sorry`-backed defs (`H1Norm`, `HasFiniteEnergy`) plus
  a `LeraySolution` structure carrying two abstract `Prop` fields
  (`h_div_free`, `h_energy`) — honest stand-ins because mathlib
  v4.12.0 lacks Sobolev spaces (`SobolevSpace.norm` on
  `H^1(ℝ³; ℝ³)`) and the Navier-Stokes operator. Statement-only,
  no `True.intro`. The `Towers/NS/EnergyIneq.lean` file carries
  an in-source "Task #51 decision audit" comment explaining why
  every concrete replacement of those two sorries was rejected as
  either a forbidden stub or a substantively misleading
  formalization. Built by `scripts/check-towers.sh` / the
  `towers-build` workflow.
- Honest note: there is no derivation in this repo (or, to our
  knowledge, in the literature) from `X_0(397)` to a Leray-Hopf
  weak-strong uniqueness statement or to the Beale-Kato-Majda
  blow-up criterion for 3D incompressible Navier-Stokes. Treat
  the phrase as a research direction, not as a proof token. The
  eight divergence linearity bricks above do not advance global
  regularity past `Open` — they are elementary calculus facts
  about a minimal fderiv-based divergence operator on the way
  there, not energy or blow-up estimates for the Navier-Stokes
  operator.
- Function-space scaffolding (NOT bricks, not in BRICKS, not lakefile
  roots; each compiles `sorry`-free except a single documented `sorry`):
  - **Phase 1** `Towers/NS/FunctionSpaces.lean` — the divergence-free
    Sobolev space `Hdiv_free s` as the weighted-`L²` Fourier model
    (genuine Hilbert space; closedness of the div-free subspace and the
    bounded Sobolev inclusion `embed` are PROVED `sorry`-free, classical
    trio).
  - **Phase 2A — Status: Complete** (milestone `NS-540-phase2a-leray`).
    `Towers/NS/Leray.lean` — the Leray/Helmholtz orthogonal
    projection `leray_proj : Hˢ →L Hdiv_free s` with `P² = P`,
    `‖Pu‖ ≤ ‖u‖`, and `ker P` (PROVED, classical trio). The single
    documented `sorry` is `leray_proj_ker_eq_grad` (the Helmholtz
    identification `(divFree)ᗮ = grad`).
  - **Phase 2B — Status: Complete** (milestone `NS-540-phase2b-stokes`;
    `stokes_op` moved Blocked → Complete). `Towers/NS/Stokes.lean` — the
    Stokes operator
    `stokes_op = -PΔ : Hdiv_free (s+2) →L Hdiv_free s`, the `‖ξ‖²`
    Fourier multiplier. **NOW FULLY `sorry`-free + classical trio** —
    the former lone `sorry` (`stokes_eLpNorm_le`) is CLOSED, so
    `#print axioms` returns the classical trio on EVERY declaration,
    including the operator `stokes_op` and the bound
    `stokes_op_norm_le` (verified live). Proved content: the `-Δ`
    symbol estimate `‖ξ‖⁴⟨ξ⟩^{2s} ≤ ⟨ξ⟩^{2(s+2)}`, symbol positivity,
    symbol continuity, a.e.-strong-measurability, the NEW pointwise
    `ℝ≥0∞` density bound `stokes_weight_pointwise`, and the lift
    `stokes_eLpNorm_le` (the `‖ξ‖²•û` `L²` bound) carried through the
    `withDensity`/`eLpNorm` integrals
    (`lintegral_withDensity_eq_lintegral_mul₀'`). The operator-level
    declarations (`stokes_op`, linearity, div-free preservation, the
    `‖A u‖ ≤ ‖u‖` bound) are now trio-clean (no `sorryAx`) — the
    genuine operator, no longer provisional. NO self-adjointness /
    sectoriality / analytic-semigroup claim (absent from mathlib
    v4.12.0). Stokes does NOT import Leray.
  - **Phase 3 — Status: Complete** (milestone `NS-540-phase3-energy` @
    checkpoint `ae85a633`). `Towers/NS/Energy.lean` — the kinetic energy
    functional `energy u t = ‖u t‖²` on `Hdiv_free (s+2)`, with `energy_def`.
    Trio-clean, no `sorryAx`.
  - **Phase 4A — Status: Complete.** `Towers/NS/GalerkinApprox.lean` (imports
    Energy) — the **finite-dimensional Galerkin projection** `galerkinProj K n
    : Hˢ⁺² →L Kₙ` (mathlib `orthogonalProjection` onto the finite-dim `Kₙ`;
    `HasOrthogonalProjection` from `FiniteDimensional.complete`, supplied as a
    *local* `haveI` so it never pollutes global instance resolution), the
    Galerkin sequence `galerkin_seq`, and the a-priori bounds
    `galerkinProj_norm_le` (`‖Pₙ‖ ≤ 1`), `galerkin_seq_norm_le`
    (`‖uₙ(t)‖ ≤ ‖u(t)‖`), and the headline `galerkin_seq_sq_le_energy`
    (`‖uₙ(t)‖² ≤ energy u t`). Fully `sorry`-free, classical trio on every
    decl (verified live).
  - **Phase 4B — Status: Complete.** `Towers/NS/Compactness.lean` (imports
    GalerkinApprox) — `embedToLower` (the bounded, **NON-compact** inclusion
    `Hˢ⁺² ↪ Hˢ`), `TendstoLocL2` (**modeled** lower-order convergence — an
    `Hˢ`-norm surrogate for `L²_loc`, NOT literal `L²_loc`), and
    `AubinLionsCriterion` — the genuine Rellich–Kondrachov compactness theorem
    stated as a **NAMED `Prop` HYPOTHESIS, NOT proved and NOT `sorry`-ed**
    (the *compact* embedding it needs is absent from mathlib v4.12.0).
    `galerkin_strong_convergence` is an HONEST combinator routing the Phase-4A
    energy bound through the assumed criterion; it proves nothing about NS by
    itself. Fully `sorry`-free, classical trio (verified live).
  - **Phase 5 — Status: Complete.** `Towers/NS/WeakSolution.lean` (imports
    Compactness ⇒ the whole Phase-3/4 stack) — the Galerkin weak-existence
    argument as an HONEST combinator. `weak_solution_exists (u₀) (f) :
    ∃ u, WeakNS u u₀ f` is PROVED from THREE NAMED `Prop` inputs (the ≤3
    "sorries", stated as Props — NEVER `by sorry`, so zero `sorryAx`):
    `galerkin_subsequence_converges` (SORRY 1: Galerkin sequence converges to a
    candidate; needs the COMPACT `AubinLionsCriterion`),
    `limit_satisfies_weak_form` (SORRY 2: limit solves NS in the modeled
    distribution sense), `energy_inequality_passes_to_limit` (SORRY 3: energy
    inequality passes to the limit). `WeakMomentum` is a MODELED **linear**
    Stokes weak form (nonlinear `(u·∇)u` DROPPED) and `WeakNS` a MODELED
    surrogate (init + `WeakMomentum` + force-free energy bound), NOT the literal
    Leray–Hopf definition. Index/viscosity match Phase 3/4 (`Hdiv_free (s+2)`,
    `ν = 1`). `#print axioms weak_solution_exists` = classical trio (verified
    live). The combinator routes the three unproved NAMED inputs into the
    conclusion; it proves NOTHING about NS by itself. Last combinator BEFORE
    Surface #1 (`global_smooth_exists`); does NOT touch it.
  - **Phase 6 — Status: Complete; NS FROZEN at 251 at the Clay boundary**
    (milestone `NS-540-phase6-clay-boundary` @ checkpoint
    `c5f29fb4390e5dda83ffdbfcae5dea2333cf5c12`; supersedes
    `NS-540-phase6-regularity`). **FREEZE RULE: no further commits to
    `Towers/NS/` without an explicit unfreeze order.** Surface #1
    (`global_smooth_exists`) and Surface #2 (modeled `weak_solution_exists`)
    stay OPEN. `Towers/NS/Regularity.lean` (imports
    WeakSolution) — the weak⇒strong (conditional) regularity step as an HONEST
    combinator. `weak_implies_strong (h : global_smooth_exists) (w : WeakSolution
    s) : ∃ T > 0, IsSmoothOn w.u T` is PROVED from the SINGLE NAMED `Prop`
    `global_smooth_exists` (the NS global-regularity surface — every modeled weak
    solution is smooth on a short interval; the Clay-grade open content, NAMED,
    NEVER `by sorry`, so zero `sorryAx`). `WeakSolution s` bundles the Phase-5
    field + data + `WeakNS` proof; `IsSmoothOn` is a MODELED surrogate for
    `C^∞((0,T) × ℝ³)` (temporal `ContDiffOn ℝ ⊤` of the tested profiles
    `t ↦ ⟪u t, φ⟫` only — genuine joint space–time smoothness needs the Sobolev
    `⋂ₛ Hˢ ↪ C^∞` embedding across all indices, absent here and from mathlib
    v4.12.0). `#print axioms` on `weak_implies_strong` and `global_smooth_exists`
    = classical trio (verified live). Because the single sorry IS the surface, NS
    Tower 540 is frozen at 251: the regularity surface is reached and left OPEN —
    the combinator proves NOTHING about NS regularity by itself.
  - HONEST scope: these build spaces, name/bound operators, build the
    approximation scheme + its a-priori bound, NAME the compactness input, and
    assemble the weak-existence + conditional-regularity combinators from NAMED
    analytic inputs; they prove NO NS existence/uniqueness/regularity result and
    NO convergence of the full sequence. NS stays `Status: Open`; Surface #1/#2
    stay OPEN.

## 4. 280-curve cohort (M9 Weil-transfer discharge) — and BSD

**Status: Certified for `N = 397`. General statement Open — second general-statement brick formalized (Mordell-Weil commutativity and rank-zero ⇒ trivial-point in Lean; axiom footprint = subset of mathlib's classical core {propext, Classical.choice, Quot.sound}, no research-grade axioms).**

- What is genuinely closed: for the specific elliptic conductor
  `N = 397` (the case that appears in `m9.out`), the Lean theorem
  `M9_WeilTransfer_All` discharges the 280 case-checks and supplies
  `H2_WeilTransfer` to the spine. SHA of `m9.out` and the
  `VALOR_min = 1084` invariant are recorded in the ledger.
- Open: the statement for general conductors. The 280-curve cohort
  beyond `N = 397` is not discharged here.
- First honest general-statement brick toward the
  Birch–Swinnerton-Dyer side of this tower:
  `lean-proof-towers/Towers/BSD/MordellWeil.lean` defines
  `MordellWeilGroup E` as a thin alias for mathlib's
  `WeierstrassCurve.Affine.Point` (inheriting the full
  `AddCommGroup` instance) and proves the trivial commutativity
  brick `MordellWeilGroup.add_comm` by delegating to mathlib's
  `_root_.add_comm`. Axiom footprint contained in mathlib's
  classical core `{propext, Classical.choice, Quot.sound}` (no
  `sorryAx`, no user-declared axioms). Alongside, it pins
  `BSD_rank_statement : Prop` as a *statement schema* (honestly
  flagged: the L-function `L(E, s)` is not in mathlib v4.12.0, so
  the schema quantifies over a placeholder `IsLFunctionOf`
  predicate that future plans must replace). Statement-only, no
  `True.intro`. Built by `scripts/check-towers.sh` / the
  `towers-build` workflow.
- Honest note: "M9.OUT SHA + VALOR_min = 1084" certifies *bytes*
  (the discharge file is reproducible) and *one combinatorial
  invariant*; it does not certify a theorem about all conductors,
  and the commutativity brick above does not advance the
  general-conductor status past `Open`.

## 5. Bost-Connes Core

**Status: Certified in spine (BC-CM at h = 1).**

- The Bost-Connes piece is the one of the five that genuinely
  closes inside the v1.8-BC Lean spine without new axioms, at
  `h = 1` (see `M13_CERT.txt` and `lean-proof/VERIFY.txt`).
  Load-bearing tokens: `C₀ = 320`, `S_14 = {1, 11, 19, 29}`.
- Open extension: BC-CM beyond `h = 1` is not in scope for
  v1.8-BC. Lifting the result to higher `h` is a research-level
  follow-on.

---

## Addendum. Hodge conjecture — X₅ Zoe Comparison Test

**Status: Open — honest conditional reduction to ONE named analytic
hypothesis (no Hodge instance proved or disproved; CMI).**

- The Hodge conjecture is not one of the five towers above; this is an
  additive, honesty-locked leaf prompted by the "Zoe invariant" trilogy.
- Honest formal leaf: `lean-proof-towers/Towers/Hodge/ZoeComparisonTest.lean`
  for `X₅ = Jac(y² = x¹¹ − x)`, centered on the Zoe Comparison Test
  `𝔗(ω,s) = Σ Z(ω)ⁿ/(n!)² · ⟨ω, Frobⁿ ω⟩ · q^{ns}`. NOT a brick, not in
  `BRICKS`, not a lakefile root; touches no YM/NS surface; axiom footprint =
  classical core `{propext, Classical.choice, Quot.sound}`, 0 `sorry`/`sorryAx`.
- Machine-checked: the combinatorics (`C(5,2)=10`, `C(5,2)+C(5,4)=15`,
  `15 > 10`) and the carried-hypothesis Zoe bound `1 ≤ Z ≤ p = 2` ⟹ **Z ≤ 2**
  (`Z_X5_bound`; the `15` is the Hankel rank `rank_H_X5`, a *different* quantity
  — never "Z = 15"); and the headline `radius_infinite` that `𝔗` is
  **entire (R = ∞)** under the geometric Weil bound `|⟨ω,Frobⁿω⟩| ≤ C·Bⁿ`
  (the `(n!)²` dominates), which **refutes the prior "radius 0 / pole at s=1"
  framing**: `𝔗` as defined supplies no divergence / no obstruction.
- The "divergence ⇒ transcendence ⇒ Hodge" step is the OPEN analytic input,
  carried as a single named-open `Prop` in a SORRY-free conditional combinator
  (vacuous for the actual entire series). Lemma 7.6 (M.S. bound) and the M\*
  Transform are recorded as uncertified / superseded (see `replit.md`
  § "Appendix A"); the old "200 classes transcendental" claim is retracted.
- Honest note: nothing about Hodge is closed or refuted here. Proving the named
  analytic hypothesis (or constructing a genuine obstruction) is research-grade
  work; the statement stays **Open**.

## Shared infrastructure

All five towers share:

- The same Genesis-sealed ledger (`data/hits.txt`,
  preamble SHA `eecbcd9a…875f`).
- The same Lean spine (`TheoremaAureum.main_theorem`, axioms = []).
- The same drift guard (`scripts/post-merge.sh` + the `lean-proof`
  CI workflow with `STRICT_LEAN_CHECK=1`).

What "axioms = []" actually means here: the named spine theorems
(`H1_ArakelovPositivity`, `H2_WeilTransfer`, `M9_WeilTransfer_All`,
`main_theorem`) close in Lean without invoking any additional
axioms beyond Lean core + mathlib. It does **not** mean that the
five tower statements above have been formally proved. See
`replit.md` § "Honest-scope guards" for the discipline this repo
follows to avoid that conflation.

## How to contribute to a tower honestly

If you want to push one of these towers forward without breaking
the honest-scope guards:

1. New work goes in new files (additive only — sealed surfaces
   stay untouched).
2. If you discharge a Prop stub, state the *named theorem you are
   actually proving* and replace the stub with a real proof; do
   not relabel a tautology as a tower.
3. Update this roadmap's status line for the affected tower; do
   not promote it to "proved" anywhere in `replit.md` unless the
   spine actually closes the named theorem with axioms = [].
4. Record any out-of-scope dependency (e.g. SageMath, an
   unformalized literature result) with a `reason=` field, the
   same way `probe()` records `NEEDS_SAGE`.
