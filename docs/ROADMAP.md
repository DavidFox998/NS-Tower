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

**Status: Open.**

- Geometric invariant under study in this repo:
  `C(S₄) = 11.4221486889`, an OpenCV-derived symmetry-count
  invariant attached to the M0 cube observations (`cube_M0_v*.jpg`,
  Appendix A of the architecture write-up).
- Honest note: `C(S₄) > 2√32` is an arithmetic fact about a
  cube-counting invariant. It is **not** a mass-gap lower bound on
  any Yang-Mills Hamiltonian, and no derivation in this repo
  connects it to the Jaffe-Witten Clay problem. Treat it as
  conjectural scaffolding for a future link, not as evidence for
  the mass gap.

## 3. Navier-Stokes global regularity

**Status: Open.**

- Conjectural scaffolding in this repo: "Arakelov descent from
  `X_0(397)`" is a label for a proposed bridge from heights on a
  modular curve to PDE energy estimates.
- Honest note: there is no derivation in this repo (or, to our
  knowledge, in the literature) from `X_0(397)` to a Leray-Hopf
  weak-strong uniqueness statement or to the Beale-Kato-Majda
  blow-up criterion for 3D incompressible Navier-Stokes. Treat
  the phrase as a research direction, not as a proof token.

## 4. 280-curve cohort (M9 Weil-transfer discharge)

**Status: Certified for `N = 397`. General statement Open.**

- What is genuinely closed: for the specific elliptic conductor
  `N = 397` (the case that appears in `m9.out`), the Lean theorem
  `M9_WeilTransfer_All` discharges the 280 case-checks and supplies
  `H2_WeilTransfer` to the spine. SHA of `m9.out` and the
  `VALOR_min = 1084` invariant are recorded in the ledger.
- Open: the statement for general conductors. The 280-curve cohort
  beyond `N = 397` is not discharged here.
- Honest note: "M9.OUT SHA + VALOR_min = 1084" certifies *bytes*
  (the discharge file is reproducible) and *one combinatorial
  invariant*; it does not certify a theorem about all conductors.

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
