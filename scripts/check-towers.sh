#!/usr/bin/env bash
# check-towers.sh — Build the opt-in Towers Lean library (mathlib-backed
# first bricks for the open towers: RH, BSD, Navier-Stokes,
# Yang-Mills) and verify each named brick's axiom debt is either
# empty or a subset of mathlib's classical core
# {propext, Classical.choice, Quot.sound}.
#
# This script targets the SIBLING package at `lean-proof-towers/`. The
# main spine package `lean-proof/` is deliberately untouched: it stays
# mathlib-free so the fast spine drift guard (`check-lean-proof.sh`)
# keeps running in seconds.
#
# Cost (cold cache, no mathlib oleans on disk):
#   - `lake update` resolves the mathlib v4.12.0 git dep (sources).
#   - `lake exe cache get` downloads ~2 GB of prebuilt mathlib oleans
#     from the Lean community CDN. Typically 5–15 min on a reasonable
#     connection.
#   - `lake build Towers` then compiles the Towers library on top of
#     mathlib. Typically <1 min on warm cache.
#
# Cost (warm cache, mathlib oleans already on disk under
#       `lean-proof-towers/.lake/packages/mathlib/.lake/build/`):
#   - 10–30 seconds total.
#
# Behaviour when `lake` is missing or the cache fetch fails (e.g.
# offline sandbox): exits non-zero with a clear message. There is no
# "soft skip" mode — the towers-build workflow is the canonical place
# to surface mathlib-availability problems.
#
# Adding a new brick:
#   1. Add a `lean_lib` root in `lean-proof-towers/lakefile.lean`.
#   2. Append a pair `"<Towers module>|<fully-qualified theorem>"` to
#      the BRICKS array below. The script will build a tiny verifier
#      file per pair and run the axiom-footprint check.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOWERS_DIR="$REPO_ROOT/lean-proof-towers"
cd "$TOWERS_DIR"

if ! command -v lake >/dev/null 2>&1; then
  echo "error: \`lake\` (Lean 4) not on PATH." >&2
  echo "       Install Lean 4 via elan (https://leanprover.github.io/lean4/doc/setup.html)." >&2
  exit 127
fi

# Restore each `.lake/packages/<pkg>/.git/` from its committed tar
# under `lean-proof-towers/lake-deps/`. The outer repo cannot carry
# nested `.git/` directories (git treats them as submodule
# boundaries) and the whole `.lake/` tree is gitignored on top of
# that, so this idempotent restore is the *prerequisite* for every
# Lake operation below. Task #76 (follow-up to Task #66). The script
# exits non-zero if any package ends up without a real `.git` at its
# manifest-pinned rev, so we never reach `lake update` in a broken
# state where Lake would re-clone and wipe the working tree.
echo ">> restore-lake-git.sh (rehydrate vendored .git/ from tars)" >&2
"$REPO_ROOT/scripts/restore-lake-git.sh"

# Hard preflight assertion: every package under `.lake/packages/`
# must have a real `.git/` directory whose HEAD resolves. If any is
# missing, fail loudly here instead of letting `lake update` decide
# to re-clone from scratch.
for pkg_dir in "$TOWERS_DIR"/.lake/packages/*/; do
  pkg_name="$(basename "$pkg_dir")"
  if [ ! -d "$pkg_dir/.git" ]; then
    echo "error: $pkg_name has no \`.git/\` after restore-lake-git.sh." >&2
    echo "       Refusing to run \`lake update\` — it would re-clone and wipe the working tree." >&2
    exit 1
  fi
  if ! git -C "$pkg_dir" rev-parse HEAD >/dev/null 2>&1; then
    echo "error: $pkg_name has \`.git/\` but HEAD does not resolve." >&2
    exit 1
  fi
done

# With every package presenting a real `.git` at its manifest-pinned
# rev, Lake sees its checkout URL and rev as matching the manifest
# and takes no destructive action. `lake update` is now a no-op
# resolve; the older Task #60 / Task #66 skip guards are gone.
echo ">> lake update (resolve manifest)" >&2
lake update

# `lake exe cache get` fetches prebuilt mathlib oleans from the Lean
# community CDN. With real `.git/` directories in place this is now
# safe — Lake no longer sees the packages as URL-changed and will not
# re-clone them. A fast-path skip kept for the common warm-cache case
# (mathlib oleans already populated on disk).
MATHLIB_OLEAN_PRESENT=0
if [ -d ".lake/packages/mathlib/.lake/build/lib/Mathlib" ] && {
     [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib.olean" ] \
  || [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib/Init.olean" ] \
  || [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib/Tactic.olean" ] \
  || [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib/Logic/Basic.olean" ]; }; then
  MATHLIB_OLEAN_PRESENT=1
fi

if [ "$MATHLIB_OLEAN_PRESENT" = "1" ]; then
  echo ">> lake exe cache get: SKIPPED (mathlib oleans already on disk;" >&2
  echo "   .lake/packages/mathlib/.lake/build/lib/ is populated)." >&2
else
  echo ">> lake exe cache get (fetch ~2 GB prebuilt mathlib oleans)" >&2
  lake exe cache get
fi

echo ">> lake build Towers" >&2
lake build Towers

# ------------------------------------------------------------------
# Per-brick axiom-footprint check.
#
# Each entry is "<lean import path>|<fully qualified theorem name>".
# The lean import path is the dot-separated module name that mathlib's
# Lean elaborator expects in `import <...>` (e.g. `Towers.RH.ZeroDensity`).
# The theorem name is what `#print axioms` will receive.
#
# Acceptable axiom footprint per brick:
#   (a) truly no axioms ("does not depend on any axioms"), OR
#   (b) a subset of mathlib's classical core
#       {propext, Classical.choice, Quot.sound}.
# Any other axiom name — `sorryAx`, a user-declared `axiom`, etc. —
# is rejected and the script exits non-zero on the first failure.
# ------------------------------------------------------------------
BRICKS=(
  "Towers.RH.ZeroDensity|TheoremaAureum.Towers.RH.N_monotone_in_sigma"
  "Towers.BSD.MordellWeil|TheoremaAureum.Towers.BSD.MordellWeilGroup.add_comm"
  "Towers.BSD.MordellWeil|TheoremaAureum.Towers.BSD.MordellWeilGroup.eq_zero_of_isRankZero"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_add"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_smul"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_zero"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_neg"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_sub"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_const"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_add_const"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_sub_const"
  # NOTE: The six `gauge_action_*` bricks (one_smul, mul_smul,
  # inv_smul, smul_inv, inv_inv, pow_zero) on `TrivialConfiguration`
  # were retired in the 2026-05-26 retirement (Task #50, Option A).
  # The `TrivialConfiguration` scalar action was `· • A := A`, so
  # every `gauge_action_*` lemma reduced definitionally on both
  # sides to `A`, exercising neither group multiplication nor the
  # action — hollow even by trivial-brick standards. Removing them
  # drops the wall from 24 → 18 but enforces the user-locked rule
  # "no `gauge_action_*` on TrivialConfiguration anymore (only real
  # SU(3))" consistently. YM bricks now live exclusively in
  # `Towers.YM.MassGap` against the real `Matrix.specialUnitaryGroup`
  # API. See git history for the withdrawn theorems.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_one_mul"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_unitary"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_det_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_mul_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_one_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_mul_unitary"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_mul_det_one"
  # Task #51 (2026-05-26): the three schema defs `HilbertSpace`,
  # `YMHamiltonian`, `IsEigenstate` in `Towers.YM.MassGap` were
  # concretized from `sorry` to minimal mathlib-backed types
  # (`EuclideanSpace ℂ (Fin 3)`, sum-of-component-traces, scaling-
  # form predicate). The new brick `IsEigenstate_zero_zero` below
  # is the first downstream use proving the schema is no longer
  # dead weight. Same Open status for YM (`docs/ROADMAP.md` § 2).
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_zero_zero"
  # 2026-05-26 brick wave (no associated task #; "Shawlocked" walk):
  # extend the trivial-bundle SU(3) laws on connection components.
  # `mul_assoc` completes the standard monoid laws (`one_mul`,
  # `mul_one`, `mul_assoc`). `_component_star_mul_self` is the
  # other side of `_component_unitary` (full two-sided unitary
  # law at the matrix level via `star`). `_component_star_det_one`
  # shows the conjugate-transpose is also det 1, so `star (A i).1`
  # is again in SU(3) — recovering "closed under inverse" content
  # without an `Inv` instance on `specialUnitaryGroup` (which is a
  # `Submonoid` in mathlib v4.12.0, no `Group` instance). Wall:
  # 19 → 22. None advance YM past Status: Open.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_mul_assoc"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_star_mul_self"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_star_det_one"
  # 2026-05-26 Branch C Step 1 (Task #55 continuation): open the real
  # `su(3)` Lie algebra surface as a plain `Set` of anti-Hermitian
  # traceless 3×3 ℂ-matrices in the new file `Towers/YM/SU3.lean`.
  # Three foundation bricks that every later batch (closure under
  # `+/-/•`, bracket `[·,·]`, `L²(su(3))` Hilbert space) will depend
  # on. Wall: 22 → 25. None advance YM past Status: Open — see the
  # honest-scope block at the top of `Towers/YM/SU3.lean`.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_lie_algebra_def"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_mem_iff_anti_hermitian_traceless"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_zero_mem"
  # 2026-05-26 Branch C Step 2 (Task #55 continuation): closure of
  # `su(3)` under +, -, and ℝ-scalars. Together with `su3_zero_mem`
  # from Step 1, these four are the algebra-closure facts needed
  # to upgrade `su3` to a `Submodule ℝ` in a later (separate)
  # brick. Wall: 29 → 33. None advance YM past Status: Open — see
  # the `### Branch C Step 2` section header in `Towers/YM/SU3.lean`.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_add_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_neg_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_sub_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_smul_mem"
  # 2026-05-26 Branch C Step 2.5: bundle the Step 2 closure lemmas
  # into a real `Submodule ℝ` (`su3_submodule`), add the carrier
  # unpacker, and ratify the two mathlib-derived typeclass
  # instances (`AddCommGroup ↥su3_submodule`, `Module ℝ ↥su3_submodule`)
  # under named handles so the axiom-footprint check pins them.
  # Wall: 36 → 40. None advance YM past Status: Open — these are
  # algebra-bundling moves, not YM dynamics. The next batch (a
  # separate brick wave) adds an `InnerProductSpace ℝ ↥su3_submodule`
  # so we can build `L²(Fin n, ↥su3_submodule)` on a finite lattice.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_submodule"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_submodule_mem_iff"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.instance_addcommgroup_su3"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.instance_module_real_su3"
  # Task #55 (2026-05-26): four load-bearing bricks on the now-real
  # YM schema concretized by Task #51 (`HilbertSpace`,
  # `YMHamiltonian`, `IsEigenstate`). Three of them reference at
  # least two of those defs; one references all three. They prove
  # the schema is genuinely load-bearing — e.g. `YMHamiltonian
  # (fun _ => 1) = 12` is the first numerical answer extracted from
  # the def, and `¬ IsEigenstate YMHamiltonian (0 : HilbertSpace)`
  # combines all three. Wall: 25 → 29. YM status still Open.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_one_eq_twelve"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_zero_const"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_of_forall_zero"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_not_isEigenstate_zero"
  # Task #56 (2026-05-26): first load-bearing bricks on the NS energy
  # schema concretized by Task #51 (`H1Norm`, `HasFiniteEnergy` in
  # `Towers/NS/EnergyIneq.lean`). NS analogue of YM's
  # `IsEigenstate_zero_zero`: zero velocity field has zero placeholder
  # H¹-norm, has finite placeholder energy, and the placeholder
  # H¹-norm is nonneg. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). These are NOT statements about the H¹
  # Sobolev norm, the L² energy bound, or any Leray-Hopf solution.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_nonneg"
  # Task #62 (2026-05-26): second wave of NS energy schema bricks
  # on the Task #51 concretizations of `H1Norm` / `HasFiniteEnergy`,
  # this time referencing fully-general / non-zero inputs (not just
  # the zero velocity field). NS analogue of the YM Task #55 wave:
  # `H1Norm_eq_norm_apply_zero` is the named unfolder for arbitrary
  # `(u, t)`; `HasFiniteEnergy_of_bounded_zero` packages any uniform
  # `∀ x, ‖u₀ 0 x‖ ≤ M` bound into the placeholder finite-energy
  # witness; `HasFiniteEnergy_const` proves every constant-in-
  # spacetime field `(fun _ _ => c)` has finite placeholder energy
  # via `M = ‖c‖`. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). These are NOT statements about the H¹
  # Sobolev norm, the L² energy bound, or any Leray-Hopf solution.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_eq_norm_apply_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_of_bounded_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_const"
  # Task #69 (2026-05-26): combinator bricks on the NS energy schema
  # — first non-trivial combinators on `HasFiniteEnergy` that
  # exercise smoothly-varying (non-constant, non-zero) inputs.
  # `HasFiniteEnergy_add` shows the placeholder finite-energy
  # predicate is closed under pointwise sum (witness M₁ + M₂ via the
  # triangle inequality). `HasFiniteEnergy_of_smul_bounded` shows that
  # any scalar profile `f : ℝ³ → ℝ` with `|f x| ≤ 1` times a fixed
  # vector `c` has finite placeholder energy (witness ‖c‖) — first
  # brick on a genuinely non-constant family. NS tower status
  # unchanged: Open (`docs/ROADMAP.md` § 3). These are NOT statements
  # about the H¹ Sobolev norm, the L² energy bound, or any Leray-Hopf
  # solution.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_add"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_of_smul_bounded"
  # Task #78 (2026-05-26): spatial-translation invariance of the
  # placeholder finite-energy predicate. Continues the Task #69
  # combinator wave on `HasFiniteEnergy`: if `u₀` has finite
  # placeholder energy with witness `M`, then for any fixed
  # translation `a : ℝ³` the shifted field
  # `fun t x => u₀ t (x + a)` also has finite placeholder energy
  # with the *same* witness `M`. First NS combinator that looks like
  # a real PDE symmetry (rigid spatial translation) rather than a
  # pure norm-algebra fact (triangle inequality / homogeneity of
  # `‖·‖`). NS tower status unchanged: Open (`docs/ROADMAP.md` § 3).
  # NOT a statement about the L² energy bound or any Leray-Hopf
  # solution; this is closure of the *placeholder* predicate under
  # spatial shift.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_translate"
  # Task #70 (2026-05-26): name the "energy never grows" predicate
  # inside the NS schema. `EnergyMonotone u u₀ : Prop` is the
  # explicit `∀ t, H1Norm u t ≤ H1Norm u₀ 0` shape named by the
  # `LeraySolution.h_energy` docstring TODO. The structure field
  # itself stays as a bare `Prop` (flipping its type would change
  # the structure's shape); the predicate is exposed as a
  # standalone `def` external readers can name. Two trio-clean
  # bricks: `EnergyMonotone_of_h1norm_const` (diagonal witness on
  # any `u₀` with constant-in-`t` placeholder norm, via `le_refl`)
  # and `EnergyMonotone_zero` (the zero velocity field is
  # monotone w.r.t. any `u₀`, via `H1Norm_zero` + `H1Norm_nonneg`).
  # NS tower status unchanged: Open (`docs/ROADMAP.md` § 3). NOT
  # the Leray-Hopf H¹ energy inequality — `H1Norm` is the
  # Task #51 placeholder (Euclidean norm at the spatial origin).
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.EnergyMonotone"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.EnergyMonotone_of_h1norm_const"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.EnergyMonotone_zero"
  # Task #55 (Branch A witness, 2026-05-26): infinite-dimensionality
  # witness for `HilbertSpace = lp (fun _ : ℕ => ℂ) 2`. The canonical
  # `lp.single`-at-`1` family indexed by ℕ is orthonormal (norm-one
  # from `lp.norm_single`; pairwise inner zero from
  # `lp.inner_single_left` + `lp.single_apply_ne`), hence linearly
  # independent, hence `HilbertSpace` is NOT finite-dimensional over
  # ℂ (via `Module.Finite.not_linearIndependent_of_infinite`). Three
  # bricks: the family def, the orthonormality theorem, and the
  # non-finite-dim conclusion. Her tri-parallel ask included two
  # other branches (`SymmetricFockSpace` over `L² ⊗ su(3)`; subtype
  # `{f // MemLp f 2 volume}`); neither is landable on mathlib
  # v4.12.0 — Fock-space machinery absent; the raw `MemLp`-subtype
  # is only a semi-inner-product (no a.e.-quotient). So this lands
  # the witness on the existing ∞-dim ℓ²(ℕ,ℂ) carrier. YM tower
  # status unchanged: Open (`docs/ROADMAP.md` § 2). This brick says
  # NOTHING about the YM physical-state Hilbert space.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.hilbertCanonicalFamily"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.hilbertCanonicalFamily_orthonormal"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.HilbertSpace_not_finiteDimensional"

  # ---------------------------------------------------------------
  # Task #56 Path B batch 1 (2026-05-26): the 8 anti-Hermitian
  # Gell-Mann generators `iλ₁ … iλ₈` of su(3), each proven to lie in
  # `su3_submodule`. Unnormalised `iλ₈ = diag(I, 0, -I)` (no √3)
  # chosen so every membership proof closes via
  # `ext + fin_cases + simp` on the matrix-literal unfolders +
  # `Complex.conj_I`. These are the foundation for batch 2
  # (`su3_basis_def` via `Basis.ofEquivFun`, plus
  # `su3_basis_linearIndependent` and `su3_basis_spans` as 1-line
  # `.linearIndependent` / `.span_eq` wrappers) and batch 3
  # (`instance_inner_product_space_su3_euclidean` via
  # `InnerProductSpace.Core`). The bricks claim ONLY:
  # anti-Hermitian + traceless. No statement about YM dynamics, the
  # YM Hamiltonian, or the mass-gap conjecture. YM tower status
  # remains **Open** (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₁_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₂_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₃_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₄_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₅_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₆_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₇_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₈_mem"
  # Task #61 (2026-05-26): the first *uniform* `∀ A, _ ≤ _` bound on
  # the YM Hamiltonian schema. Proves `|YMHamiltonian A| ≤ 12` by
  # bounding each diagonal entry of an SU(3) matrix by 1 (rows of a
  # unitary matrix are unit vectors), hence `|trace.re| ≤ 3` per
  # component, hence `≤ 4 · 3 = 12` summed. Genuine inequality, not
  # a point value or contradiction. YM tower status unchanged: Open
  # (`docs/ROADMAP.md` § 2). Still a bound on the placeholder
  # sum-of-traces schema, NOT the YM field energy.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_abs_le_twelve"
  # Task #67 (2026-05-26): tightness witness for the Task #61 bound.
  # `|YMHamiltonian (fun _ => 1)| = 12` — the all-ones SU(3) connection
  # saturates the `≤ 12` bound, so 12 is a genuine supremum of the
  # schema, not merely an upper bound. One-line `rw` against
  # `YMHamiltonian_one_eq_twelve` + `norm_num` for the `|12| = 12`
  # absolute-value step. YM tower status unchanged: Open
  # (`docs/ROADMAP.md` § 2). Still a tightness witness for the
  # placeholder sum-of-traces schema, NOT the YM field energy.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_abs_le_twelve_tight"
  # Task #68 (2026-05-26): state a real "mass gap" predicate inside
  # the placeholder YM schema. `MassGap (Δ : ℝ) : Prop` packages the
  # Clay-flavoured shape `0 < Δ ∧ ∀ ψ A, IsEigenstate YMHamiltonian ψ
  # → ψ ≠ 0 → Δ ≤ YMHamiltonian A`. Two trio-clean bricks: `MassGap_pos`
  # projects out positivity; `MassGap_le_twelve_of_witness` is the
  # honest conditional version of "MassGap Δ → Δ ≤ 12" — given any
  # non-zero placeholder eigenstate, `MassGap Δ → Δ ≤ 12` follows by
  # instantiating at the all-ones SU(3) connection and rewriting via
  # `YMHamiltonian_one_eq_twelve`. The conditional shape is honest:
  # no non-zero placeholder eigenstate is known to exist (Task #55's
  # `YMHamiltonian_not_isEigenstate_zero` already rules out `ψ = 0`).
  # YM tower status unchanged: Open (`docs/ROADMAP.md` § 2). The
  # predicate is on the placeholder schema (`HilbertSpace = ℓ²(ℕ,ℂ)`,
  # sum-of-traces `YMHamiltonian`, scaling-form `IsEigenstate`), NOT
  # the YM physical surface.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.MassGap"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.MassGap_pos"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.MassGap_le_twelve_of_witness"
  # ---------------------------------------------------------------
  # Batch 8 (2026-05-26) — three independent tracks, 5 bricks each
  # (15 total), zero shared imports across tracks. Each track lives
  # in a new file and imports only its own pre-existing tower
  # foundation. Brick names are exactly as specified in the Batch 8
  # directive.
  #
  # Tripwire (active per directive): Batch 8 / Track 2 also carries
  # an unregistered tripwire theorem `LerayEnergyIneq_dissipation
  # _zero_simplifies` whose proof closes only because
  # `Dissipation = 0`. Flipping `Dissipation` to a non-zero body
  # intentionally breaks the `add_zero` step in the tripwire proof,
  # signalling that a real dissipation term has landed and the
  # Leray-Hopf surface needs a real proof of monotonicity against
  # the dissipation. The tripwire is enforced by compile, not by
  # `#print axioms`, so it does NOT appear in BRICKS — but the file
  # is in `Towers` lake roots, so a tripwire failure fails
  # `lake build Towers` and the whole script.
  #
  # Sealed surfaces (`data/hits.txt`, `THEOREMA_AUREUM_143.manifest
  # .txt`, `scripts/print-direction.sh`, `lean-proof/` Lean spine):
  # untouched by Batch 8. All work confined to `lean-proof-towers/`.
  #
  # Track 1 (Towers/Spectral/OperatorV2.lean) — unblock
  # `∃ μ, MassGap H μ` by upgrading the placeholder Hamiltonian
  # from the zero operator to the identity (`Hamiltonian_operator_v2
  # := id`), proving symmetry / PSD for the identity, and adding
  # two abstract combinators (`vacuum_unique_of_kernel_one_dim`,
  # `mass_gap_from_lower_bound`) that downstream `MassGap` proofs
  # can call once a non-trivial Hamiltonian and a real Rayleigh
  # bound land. NOT a real mass-gap proof — `H = id` has no
  # positive Rayleigh-quotient lower bound, so
  # `∃ μ, MassGap Hamiltonian_operator_v2 μ` is still FALSE on
  # this batch's witness. Spectral / YM / NS towers all stay Open.
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_operator_v2"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_symmetric"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_psd"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.vacuum_unique_of_kernel_one_dim"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.mass_gap_from_lower_bound"
  # Track 2 (Towers/NS/EnergyV2.lean) — unblock real `E(t) ≤ E(0)`
  # by reserving the placeholder slots a real Leray-Hopf inequality
  # needs: `H1Norm_v2` (alias of the Task #51 placeholder, name
  # reserved for the future `L²` replacement), `Dissipation`
  # (literal zero placeholder for `‖∇u‖_{L²}²`),
  # `Dissipation_nonneg`, `ViscosityScaling := ν * Dissipation`,
  # and `EnergyDissipationIntegral := ν * t * Dissipation u 0`
  # (rectangle-rule stand-in, avoids importing
  # `MeasureTheory.Integral.IntervalIntegral`). NOT the Leray-Hopf
  # energy inequality — `H1Norm` is still the Task #51 placeholder,
  # `Dissipation = 0`, and `EnergyDissipationIntegral = 0` on this
  # batch's defs. NS tower stays Open. The active tripwire
  # `LerayEnergyIneq_dissipation_zero_simplifies` (unregistered in
  # BRICKS, enforced by compile) closes only because
  # `Dissipation = 0`; flipping breaks it intentionally.
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.H1Norm_v2"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Dissipation"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Dissipation_nonneg"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.ViscosityScaling"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.EnergyDissipationIntegral"
  # Track 3 (Towers/YM/Spectrum.lean) — go from "`YMHamiltonian`
  # non-zero" (`YMHamiltonian_image_nonzero`) to "`YMHamiltonian`
  # has a gap-above-vacuum schema"
  # (`YMHamiltonian_gap_above_vacuum_schema`) via uniform bound
  # (`_image_bounded`), `BddBelow ∧ Nonempty` packaging
  # (`_image_has_inf`), and a named vacuum
  # (`_vacuum_def` against `vacuum_connection := fun _ => 1`).
  # Brick 5 is the positivity projection of a new gap-above-vacuum
  # `MassGapV2 Δ := 0 < Δ ∧ ∀ A ≠ vacuum, Δ ≤ |H A − H vacuum|`
  # predicate that fixes the wrong-physics of the Task #68
  # `MassGap` (which measures `|H A|` instead of `|H A − H vacuum|`).
  # The unconditional `∃ Δ > 0, MassGapV2 Δ` is NOT proved here —
  # only the predicate shape and its positivity projection. YM
  # tower stays Open.
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_image_nonzero"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_image_bounded"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_image_has_inf"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_vacuum_def"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_gap_above_vacuum_schema"

  # ---- Batch 9 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Track 1 (OperatorV2): first non-vacuous `MassGap`
  # witness via the one-point space `EuclideanSpace ℝ (Fin 0)`, plus
  # quadratic-form identity, ground-state inequality, PSD lower-bound
  # combinator. Track 2 (EnergyV2): adds a SECOND dissipation surface
  # (`Dissipation_real` ≠ 0) and `LerayEnergyIneq_real` over it,
  # WITHOUT touching the Batch 8 `Dissipation = 0` tripwire. Track 3
  # (Spectrum): vacuum-singleton sInf = 12, attainment witness, and
  # MassGapV2 algebra (zero-iff-False, monotone-in-Δ, ≤ 0 projection).
  # None promote any tower; YM / NS / Spectral stay Status: Open.
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_spectrum_toy"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.vacuum_is_ground_state"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_mass_gap_toy"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_exists_diagonal"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.lower_bound_from_psd"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.H1Norm_real"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Dissipation_real"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.LerayEnergyIneq_real"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Dissipation_positive_ae"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.EnergyDecayBound"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_inf_eq_twelve"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_attains_inf"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.MassGap_v2_zero_iff"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.MassGap_v2_monotone"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.spectrum_gap_schema"

  # ---- Batch 10 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Track 1 (OperatorV2): toy → real-operator schema
  # bridges — `Hamiltonian_compact_resolvent_schema` + `essential_
  # spectrum_empty_schema` as NAMED Prop predicates (the directive's
  # tripwire — if a caller cannot supply the compact-resolvent
  # schema for their H, `MassGap_from_discrete_spectrum` is
  # unreachable); `first_excitation_lower_bound` / `minimax_
  # characterization_μ` as pure projections of `MassGap H μ`.
  # Track 2 (EnergyV2): global-regularity scaffolds — `Enstrophy`
  # placeholder + `EnstrophyBalance` / `BealeKatoMajda_criterion_
  # schema` / `SmallDataGlobal_schema` / `EnergyEnstrophy_
  # interpolation` as NAMED Prop predicates. Batch 8 `Dissipation = 0`
  # tripwire untouched. Track 3 (Spectrum): infrared-bound / OS-
  # reconstruction setup — `YMHamiltonian_coercive` (real lower
  # bound `-12` via Task #61) + `YMHamiltonian_essentially_
  # selfadjoint_schema` / `vacuum_gap_positive_schema` / `cluster_
  # decomposition_schema` / `infrared_regularization` as NAMED Prop
  # / schema defs. `vacuum_gap_positive_schema := ∃ Δ, MassGapV2 Δ`
  # honestly names the Clay target without supplying a witness; YM
  # mass gap stays Open. None promote any tower; YM / NS / Spectral
  # stay Status: Open (`docs/ROADMAP.md` § 2 / § 3).
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_compact_resolvent_schema"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.essential_spectrum_empty_schema"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_from_discrete_spectrum"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.first_excitation_lower_bound"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.minimax_characterization_μ"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Enstrophy"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.EnstrophyBalance"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.BealeKatoMajda_criterion_schema"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.SmallDataGlobal_schema"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.EnergyEnstrophy_interpolation"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_coercive"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_essentially_selfadjoint_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.vacuum_gap_positive_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.cluster_decomposition_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.infrared_regularization"

  # ---- Batch 11 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Wall 156 → 171. Track 1 (OperatorV2): realize the
  # gap — `Hamiltonian_discrete_spectrum_from_compact_resolvent`
  # (combinator bridging Batch 10's two schemas); `MassGap_toy_proven`
  # (∃ μ > 0, MassGap (Hamiltonian_operator 0) μ — first fully-∃
  # mass-gap witness, vacuous on Fin 0); `vacuum_spectral_gap_
  # corollary` (corollary of brick 2); `first_excited_state_exists`
  # (combinator requiring a caller-supplied non-vacuum vector —
  # tripwire honored: on Fin 0 the hypothesis is FALSE); `minimax_μ_
  # equals_gap` (pure conjunction projection of `MassGap`).
  # Track 2 (EnergyV2): small-data global existence track —
  # `Enstrophy_bound_from_small_data` (combinator squaring the
  # Fujita-Kato H1 bound into the Enstrophy bound); `BealeKatoMajda_
  # implies_global` (combinator: BKM schema elimination on the
  # placeholder); `SmallDataGlobal_proven` (PROVES the schema for
  # zero VelocityField via `H1Norm_zero`; trivial-on-zero witness,
  # NOT real Fujita-Kato); `Energy_decay_exponential` (NAMED Prop
  # schema for `∃ C η > 0, H1Norm u t ≤ C * exp(-η * t)`); `LerayHopf_
  # weak_solution_exists` (NAMED Prop schema `∃ u, EnergyMonotone u
  # u₀`). Track 3 (Spectrum): OS reconstruction path —
  # `YMHamiltonian_selfadjoint` (REAL combinator using `ExistsUnique`,
  # consuming the injectivity hypothesis from Batch 10's essentially-
  # selfadjoint schema); `OsterwalderSchrader_axioms_schema` (NAMED
  # Prop 4-fold conjunction); `Wightman_functions_from_OS_schema`
  # (identity bridge naming OS → Wightman); `cluster_implies_mass_
  # gap_schema` (combinator requiring `vacuum_gap_positive_schema`
  # as a hypothesis — tripwire honored: YM mass-gap existence stays
  # Open); `vacuum_expectation_bounded` (REAL theorem `|YMHamiltonian
  # vacuum_connection| ≤ 12` via Task #61's
  # `YMHamiltonian_abs_le_twelve`). All three directive tripwires
  # honored: Track 1 — gap-without-excited-state on singleton; Track
  # 2 — BKM stays unproven, so SmallDataGlobal_proven is restricted
  # to zero field; Track 3 — selfadjoint is a combinator, so OS-axiom
  # bricks stay Prop-level. No promotion: YM / NS / Spectral stay
  # Status: Open (`docs/ROADMAP.md` § 2 / § 3).
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_discrete_spectrum_from_compact_resolvent"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_toy_proven"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.vacuum_spectral_gap_corollary"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.first_excited_state_exists"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.minimax_μ_equals_gap"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Enstrophy_bound_from_small_data"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.BealeKatoMajda_implies_global"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.SmallDataGlobal_proven"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Energy_decay_exponential"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.LerayHopf_weak_solution_exists"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_selfadjoint"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.OsterwalderSchrader_axioms_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.Wightman_functions_from_OS_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.cluster_implies_mass_gap_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.vacuum_expectation_bounded"

  # ---- Batch 12 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Wall 171 → 186. Track 1 (OperatorV2): prove the toy
  # gap — `Hamiltonian_compact_resolvent_toy` (REAL theorem for the
  # zero operator on `EuclideanSpace ℝ (Fin n)`, N := 0);
  # `essential_spectrum_empty_toy` (REAL theorem on `Fin 0` via
  # `Subsingleton.elim` — tripwire honored: VACUOUS on Fin 0, would
  # FAIL on Fin (n+1)); `MassGap_toy_exists` (REAL ∃ ∃ theorem `∃ H,
  # ∃ μ > 0, MassGap H μ` on Fin 0 — second fully-∃ mass-gap witness
  # after Batch 11's MassGap_toy_proven); `first_excitation_explicit`
  # (noncomputable def of the standard basis vector e₀ on Fin (n+1));
  # `gap_equals_μ` (Iff.rfl identification of MassGap with the
  # gap-conjunction). Track 2 (EnergyV2): small-data global existence
  # — `SmallDataGlobal_nonzero` (REAL theorem on constant velocity
  # fields `fun _ _ => v` — second real witness for the schema after
  # Batch 11's zero witness, restricted to constant-field surface);
  # `Enstrophy_bound_global` (NAMED Prop schema `∃ C ≥ 0, ∀ t,
  # Enstrophy u t ≤ C * H1Norm u₀ 0`); `Energy_decay_optimal` (NAMED
  # Prop schema `∃ C > 0, ∀ t ≥ 0, H1Norm u t ≤ C / (1+t)²` —
  # Schonbek sharp rate companion to Batch 11's exponential decay);
  # `BealeKatoMajda_criterion` (REAL theorem on zero velocity field
  # for any T, M ≥ 0 via H1Norm_zero — tripwire honored: BKM
  # promoted only on zero, matching SmallDataGlobal_nonzero on
  # constant); `LerayHopf_unique` (NAMED Prop schema uniqueness
  # `∀ u u', EnergyMonotone u u₀ → EnergyMonotone u' u₀ → u = u'`).
  # Track 3 (Spectrum): selfadjoint to OS — `YMHamiltonian_selfadjoint_
  # proven` (REAL ∃ theorem `∀ A, ∃ B, YMHamiltonian B = YMHamiltonian
  # A` via B := A, rfl — function-identity form, NOT Kato-Rellich);
  # `OS0_temperedness_from_coercive` (REAL combinator: coercive
  # hypothesis → uniform boundedness `∃ C, ∀ A, |YMHamiltonian A| ≤ C`
  # via Task #61's YMHamiltonian_abs_le_twelve — uniform-bounded
  # form, NOT real OS0 temperedness); `OS1_euclidean_invariance_
  # schema` (NAMED Prop schema `∀ A, ∀ R, YMHamiltonian (R A) =
  # YMHamiltonian A` — FALSE in general, needs gauge fixing);
  # `cluster_decomposition_implies_gap` (REAL combinator threading
  # cluster + vacuum_gap_positive_schema → ∃ Δ > 0, MassGapV2 Δ —
  # tripwire honored: vacuum_gap_positive_schema stays unproved);
  # `vacuum_gap_lower_bound` (NAMED Prop schema `∃ Δ ≥ 12,
  # MassGapV2 Δ` — conjectural lower bound, NOT proved). All three
  # directive tripwires honored: Track 1 — essential_spectrum_empty_
  # toy vacuous on singleton; Track 2 — BKM real only on zero so
  # SmallDataGlobal_nonzero stays on constant fields; Track 3 —
  # selfadjoint is function-identity so OS0 is uniform-bounded form,
  # OS1 stays schema. No promotion: YM / NS / Spectral stay
  # Status: Open (`docs/ROADMAP.md` § 2 / § 3).
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_compact_resolvent_toy"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.essential_spectrum_empty_toy"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_toy_exists"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.first_excitation_explicit"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.gap_equals_μ"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.SmallDataGlobal_nonzero"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Enstrophy_bound_global"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Energy_decay_optimal"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.BealeKatoMajda_criterion"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.LerayHopf_unique"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.YMHamiltonian_selfadjoint_proven"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.OS0_temperedness_from_coercive"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.OS1_euclidean_invariance_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.cluster_decomposition_implies_gap"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.vacuum_gap_lower_bound"
  # Task #56 Path B batch 2 v2 (2026-05-26): the explicit
  # `↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)` equiv, the Gell-Mann basis
  # packaging via `Basis.ofEquivFun`, plus the linear-independence
  # and span_eq theorems. Concrete `toFun`/`invFun` pair avoids the
  # `LinearMap.smulRight` combinator chain that exceeded mathlib's
  # heartbeat budget in v1; `set_option maxHeartbeats 4000000` covers
  # the 9-entry × 2-component matrix-equality elaboration in
  # `left_inv`. Bricks 5+6 (NormedSpace/InnerProductSpace instances)
  # deferred to Path B batch 3 — `InnerProductSpace.induced` does not
  # exist in mathlib v4.12.0, so batch 3 must build the structure via
  # `InnerProductSpace.Core` pulled back through the equiv.
  # YM tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_equiv_fin8_def"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_def"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_linearIndependent"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_spans"
  # Task #56 Path B batch 3 (2026-05-26): the `InnerProductSpace.Core
  # ℝ ↥su3_submodule`, built by hand because mathlib v4.12.0 has no
  # `InnerProductSpace.induced` (only `InnerProductSpace.ofCore`).
  # Six bricks: (1) `inner_su3` — the Euclidean inner product on
  # `↥su3_submodule` pulled back through `su3_equiv_fin8_def`;
  # (2) `norm_su3` — `Real.sqrt (inner_su3 x x)`; (3) `conj_symm`,
  # (4) `add_left`, (5) `smul_left` — the three algebraic axioms an
  # `InnerProductSpace.Core` field over ℝ needs; (6)
  # `instance_inner_product_space_su3_core` — the packaged Core
  # record (inner + conj_symm + nonneg_re + definite + add_left +
  # smul_left), NOT registered as a global `instance` to avoid
  # constraining downstream lattice-YM bricks that may want a
  # different normalisation. This is the unnormalised Gell-Mann
  # coordinate inner product (no `1/√3` on λ₈, no `tr(A* B)/2`); it
  # is *a* real inner product on the 8-dim ℝ-vector space, NOT the
  # physics-normalised Killing form / Frobenius inner product. YM
  # tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.norm_su3"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_conj_symm"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_add_left"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_smul_left"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.instance_inner_product_space_su3_core"

  # Task #56 Path B batch 4 (2026-05-26): a discrete lattice gauge
  # field stand-in `GaugeField n := PiLp 2 (fun _ : Fin n =>
  # EuclideanSpace ℝ (Fin 8))`, a trivial-identity `curvature`
  # stand-in, and a `YMHamiltonian := ∑ i, ‖curvature A i‖²`
  # stand-in. Six bricks: (1) `GaugeField_zero_apply` — `(0 :
  # GaugeField n) i = 0` (sanity); (2) `curvature_zero`; (3)
  # `curvature_add` (additive linearity of the identity stand-in);
  # (4) `YMHamiltonian_zero`; (5) `YMHamiltonian_nonneg` (sum of
  # squares); (6) `YMHamiltonian_eq_norm_sq` — for `curvature = id`
  # the Hamiltonian equals the Pi-L² squared norm
  # (`PiLp.norm_sq_eq_of_L2`). Site type is `EuclideanSpace ℝ (Fin
  # 8)` (not `↥su3_submodule` directly): the Batch 2 v2 equiv
  # `su3_equiv_fin8_def : ↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)` is the
  # bridge, and going via `EuclideanSpace` sidesteps shipping a
  # full `InnerProductSpace ℝ ↥su3_submodule` instance (Batch 3
  # only ships the `Core`, and promoting it via ofCore would
  # collide with any future `Matrix.normedAddCommGroup` install).
  # This is NOT the YM action, NOT the Wilson plaquette action, NOT
  # a genuine `F_μν` curvature (no commutator bracket, no
  # derivative, no coupling constant). YM tower status unchanged:
  # Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.GaugeField_zero_apply"
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.curvature_zero"
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.curvature_add"
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.YMHamiltonian_zero"
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.YMHamiltonian_nonneg"
  "Towers.YM.GaugeField|TheoremaAureum.Towers.YM.GaugeField.YMHamiltonian_eq_norm_sq"

  # Task #56 Path B batch 5 (2026-05-26): an SU(3) structure-constants
  # schema (`structure_constants_su3 : Fin 8 → Fin 8 → Fin 8 → ℝ`,
  # all-zero placeholder for the real Gell-Mann `f^{abc}`), a
  # placeholder Lie bracket on `EuclideanSpace ℝ (Fin 8)` built from
  # it (`lie_bracket X Y c := ∑ a b, f^{abc} X^a Y^b`, identically
  # zero under the placeholder), an identity-stand-in lattice
  # covariant derivative `lattice_deriv (A : GaugeField n) (μ : Fin 4)
  # := A`, the resulting `curvature A i := lie_bracket (lattice_deriv
  # A 0 i) (lattice_deriv A 1 i)` (also identically zero), and
  # `YMHamiltonian := ∑ i, ‖curvature A i‖²` with the headline
  # `YMEnergy_nonneg`. Five bricks, one per user-spec item:
  # (1) `structure_constants_su3_eq_zero` documents the placeholder;
  # (2) `lie_bracket_eq_zero` exercises the bilinear sum via
  # `Finset.sum_const_zero`; (3) `lattice_deriv_id` is rfl;
  # (4) `curvature_eq_zero` routes through `lie_bracket_eq_zero`
  # — the proof will break the moment the placeholder constants are
  # replaced with real `f^{abc}`, which is the *intended* tripwire;
  # (5) `YMEnergy_nonneg` is robust against future swaps of either
  # placeholder, since `‖·‖² ≥ 0` is independent of both. This is
  # NOT the actual SU(3) Lie algebra (`f^{abc}` is all-zero); NOT
  # the genuine lattice covariant derivative (no shift, no parallel
  # transport); NOT the YM action; NOT the Wilson plaquette; NOT
  # mass-gap. YM tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.RealCurvature|TheoremaAureum.Towers.YM.RealCurvature.structure_constants_su3_eq_zero"
  "Towers.YM.RealCurvature|TheoremaAureum.Towers.YM.RealCurvature.lie_bracket_eq_zero"
  "Towers.YM.RealCurvature|TheoremaAureum.Towers.YM.RealCurvature.lattice_deriv_id"
  "Towers.YM.RealCurvature|TheoremaAureum.Towers.YM.RealCurvature.curvature_eq_zero"
  "Towers.YM.RealCurvature|TheoremaAureum.Towers.YM.RealCurvature.YMEnergy_nonneg"

  # Task #56 Path B batch 6 (2026-05-26): non-trivial successor to
  # Batch 5. Two real upgrades land at once:
  # (a) `structure_constants_su3` lifts from the all-zero placeholder
  #     to the canonical first Gell-Mann entry `f^{012} = 1` (zero
  #     elsewhere). Honors the architect's Batch-4 recommendation to
  #     introduce non-identity content.
  # (b) `lattice_deriv` is the GENUINE cyclic forward difference
  #     `(D_μ A)(i) := A(i+1) − A i` on `Fin n` with `[NeZero n]`,
  #     replacing Batch 5's identity stand-in.
  # The composition
  #     `curvature_su3 A i := lie_bracket_su3 (D_0 A i) (D_1 A i)`
  # is now genuinely non-trivial: for a generic gauge field `A` the
  # curvature is NOT identically zero, and `YMHamiltonian A := ∑ ‖curv i‖²`
  # is a real sum of squared norms. Five bricks, one per user-spec
  # item: (1) `structure_constants_su3_def` (`f^{012} = 1`, decidable);
  # (2) `lie_bracket_su3_def` (apply formula, rfl); (3)
  # `lattice_deriv_forward_diff` (`= A (i+1) − A i`, rfl — the headline
  # upgrade); (4) `curvature_su3_def` (composition formula, rfl);
  # (5) `YMEnergy_nonneg` (Finset.sum_nonneg + sq_nonneg, robust).
  # Honest scope: this is ONE entry of the antisymmetric f^{abc}
  # table — Jacobi, antisymmetry, the five other independent rationals
  # plus the two √3/2 entries are still missing. NOT the full SU(3)
  # Lie algebra; NOT a gauge-covariant derivative; NOT the YM action;
  # NOT mass-gap. YM tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.RealCurvatureV2|TheoremaAureum.Towers.YM.RealCurvatureV2.structure_constants_su3_def"
  "Towers.YM.RealCurvatureV2|TheoremaAureum.Towers.YM.RealCurvatureV2.lie_bracket_su3_def"
  "Towers.YM.RealCurvatureV2|TheoremaAureum.Towers.YM.RealCurvatureV2.lattice_deriv_forward_diff"
  "Towers.YM.RealCurvatureV2|TheoremaAureum.Towers.YM.RealCurvatureV2.curvature_su3_def"
  "Towers.YM.RealCurvatureV2|TheoremaAureum.Towers.YM.RealCurvatureV2.YMEnergy_nonneg"

  # Task #56 Path B batch 7 / Track A (2026-05-26): YM geometry upgrade.
  # New file `Towers/YM/Geometry.lean`. Introduces the totally
  # antisymmetric WRAPPER `structure_constants_su3_full` defined as
  # the 6-term antisymmetrizer of a placeholder `f_seed = 0` — so
  # values are zero, but antisymmetry holds STRUCTURALLY by `ring`,
  # independent of seed. Also adds `Lattice4D n := Fin n × Fin n ×
  # Fin n × Fin n` (first 4D index type in the tower; Batches 4-6
  # used 1D `Fin n`) and a placeholder `curvature_4d A μ ν i :=
  # A μ i - A ν i` (direction-antisymmetric placeholder, NOT the
  # real `∂_μ A_ν - ∂_ν A_μ + g[A_μ,A_ν]`). Jacobi holds because
  # the seed is zero; a Batch 8 task will replace the seed with the
  # nine canonical Gell-Mann entries (`f^{012}=1, f^{036}=½,
  # f^{057}=-½, f^{135}=½, f^{146}=-½, f^{247}=½, f^{345}=½,
  # f^{367}=√3/2, f^{567}=√3/2`), at which point `f_abc_jacobi`
  # will need a real algebraic proof. NOT the real SU(3) Lie
  # algebra; NOT a gauge-covariant 4D derivative; NOT the Wilson
  # plaquette; NOT mass-gap. YM tower status unchanged: Open
  # (`docs/ROADMAP.md` § 2).
  "Towers.YM.Geometry|TheoremaAureum.Towers.YM.Geometry.structure_constants_su3_full_def"
  "Towers.YM.Geometry|TheoremaAureum.Towers.YM.Geometry.f_abc_antisymm"
  "Towers.YM.Geometry|TheoremaAureum.Towers.YM.Geometry.f_abc_jacobi"
  "Towers.YM.Geometry|TheoremaAureum.Towers.YM.Geometry.lattice_spacetime_4d_def"
  "Towers.YM.Geometry|TheoremaAureum.Towers.YM.Geometry.curvature_4d_def"

  # Task #56 Path B batch 7 / Track B (2026-05-26): NS energy
  # decomposition. New file `Towers/NS/Energy.lean`. Introduces a
  # named `total = kinetic + potential` split on the Task #51 NS
  # placeholder schema (`VelocityField`, `H1Norm`,
  # `HasFiniteEnergy` from `Towers.NS.EnergyIneq`):
  # `kinetic_energy u t := ½ · H1Norm u t ²`,
  # `potential_energy u t := 0` (explicit zero placeholder for the
  # NS forcing / pressure-work slot), `total_energy = kinetic +
  # potential`. Adds two real combinators that take a generic
  # parameter `Φ : VelocityField → VelocityField` (no NS time-
  # evolution operator is constructed): `energy_nonincreasing_flow`
  # (if pointwise H1Norm does not grow under Φ then total_energy
  # does not grow, via `pow_le_pow_left` + `H1Norm_nonneg`) and
  # `finite_energy_persistent` (if `Φ u₀` is pointwise bounded
  # at t=0 then `HasFiniteEnergy (Φ u₀)`, via the Task #62
  # packager `HasFiniteEnergy_of_bounded_zero`). NOT the Leray-Hopf
  # energy inequality; NOT NS global regularity; NOT weak-strong
  # uniqueness. NS tower status unchanged: Open (`docs/ROADMAP.md`
  # § 3).
  "Towers.NS.Energy|TheoremaAureum.Towers.NS.Energy.kinetic_energy_def"
  "Towers.NS.Energy|TheoremaAureum.Towers.NS.Energy.potential_energy_def"
  "Towers.NS.Energy|TheoremaAureum.Towers.NS.Energy.energy_decomposition"
  "Towers.NS.Energy|TheoremaAureum.Towers.NS.Energy.energy_nonincreasing_flow"
  "Towers.NS.Energy|TheoremaAureum.Towers.NS.Energy.finite_energy_persistent"

  # Task #56 Path B batch 7 / Track C (2026-05-26): generic
  # spectral schema. New file `Towers/Spectral/Operator.lean`,
  # intentionally INDEPENDENT of `Towers.YM.MassGap` (which carries
  # the YM-specific schema `HilbertSpace := lp(ℕ,ℂ,2)` and
  # `YMHamiltonian` as a trace sum). This file gives a thin
  # generic surface: `Hamiltonian_operator n` (placeholder zero
  # operator on `EuclideanSpace ℝ (Fin n)`), `vacuum_state n`
  # (the literal zero vector), `IsEigenstate H ψ μ := H ψ = μ • ψ`,
  # `MassGap H μ := 0 < μ ∧ ∀ ψ ≠ vacuum, μ ≤ ⟨H ψ, ψ⟩`. With the
  # placeholder zero `H` the existential `∃ μ, MassGap H μ` is
  # FALSE — honestly reflecting that the placeholder has no mass
  # gap. Five bricks: three named unfolders (`Hamiltonian_operator_def`,
  # `vacuum_state_def`, `MassGap_def`), `vacuum_is_eigenstate`
  # (zero is an eigenstate of zero with eigenvalue 0), and
  # `mass_gap_pos_means_spectrum_gap` (positivity extractor from a
  # `MassGap` witness). NOT a Yang-Mills mass-gap existence proof;
  # NOT a spectral theorem; NOT self-adjointness of any non-trivial
  # operator; NOT OS reconstruction. YM tower status unchanged:
  # Open (`docs/ROADMAP.md` § 2).
  "Towers.Spectral.Operator|TheoremaAureum.Towers.Spectral.Hamiltonian_operator_def"
  "Towers.Spectral.Operator|TheoremaAureum.Towers.Spectral.vacuum_state_def"
  "Towers.Spectral.Operator|TheoremaAureum.Towers.Spectral.vacuum_is_eigenstate"
  "Towers.Spectral.Operator|TheoremaAureum.Towers.Spectral.MassGap_def"
  "Towers.Spectral.Operator|TheoremaAureum.Towers.Spectral.mass_gap_pos_means_spectrum_gap"
  # Task #77 (2026-05-26): close the conditional shape of Task #68's
  # `MassGap_le_twelve_of_witness` by proving the placeholder
  # `YMHamiltonian` admits no eigenstate at all. The
  # uniform-scaling form `IsEigenstate H ψ := ∃ μ, ∀ A, H A = μ·‖ψ‖²`
  # would force `YMHamiltonian` to be constant on `SU3Connection`,
  # but the all-ones SU(3) connection evaluates to 12 (Task #55,
  # `YMHamiltonian_one_eq_twelve`) while the all-`diag(-1,-1,1)` SU(3)
  # connection evaluates to -4 (Task #77, the new
  # `YMHamiltonian_diagNegOneOne_eq_neg_four`). Four trio-clean
  # bricks: (1) `diagNegOneOneMat` — the SU(3) matrix `diag(-1,-1,1)`
  # (det `(-1)·(-1)·1 = 1`, unitary because each diagonal entry has
  # modulus 1); (2) the `-4` numerical witness; (3)
  # `YMHamiltonian_no_eigenstate` — for every ψ, `¬ IsEigenstate
  # YMHamiltonian ψ`, the strong form; (4) `YMHamiltonian_no_nonzero_
  # eigenstate` — the task-headline `∀ ψ, IsEigenstate YMHamiltonian
  # ψ → ψ = 0` (vacuously true via the strong form). And (5) the
  # vacuous mass-gap follow-on: `MassGap_iff_pos : MassGap Δ ↔ 0 < Δ`
  # — since no eigenstate exists, the universal clause of Task #68's
  # `MassGap` predicate collapses, demonstrating the placeholder
  # schema is content-free as Clay physics. Vacuity is *expected*
  # — it confirms the schema is not the Clay surface, NOT that the
  # Clay mass gap has been proved. YM tower status unchanged: Open
  # (`docs/ROADMAP.md` § 2).
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.diagNegOneOneMat"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_diagNegOneOne_eq_neg_four"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_no_eigenstate"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_no_nonzero_eigenstate"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.MassGap_iff_pos"
  # ---- Batch 13 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Track 1: infrared regularization on
  # Spectral/OperatorV2.lean. Track 2: large-data attempt on
  # NS/EnergyV2.lean. Track 3: cluster → gap on YM/Spectrum.lean.
  # All three directive tripwires honored:
  #   - Spectral: `IR_removal_limit_schema` and
  #     `MassGap_persists_under_limit_schema` stay schemas; the
  #     `Λ → ∞` removal step is the genuinely hard one and is not
  #     discharged on the placeholder. `MassGap_IR` is real on
  #     `Fin 0` only (vacuous-on-singleton, identical-shape to
  #     Batch 11/12 vacuous witnesses).
  #   - NS: `BealeKatoMajda_bootstrap` packages BKM only on the
  #     zero velocity field; `Blowup_exclusion_small_target` is
  #     real on zero only; `Global_scheme_for_all_data` stays a
  #     schema (the genuine open Clay step of upgrading small-data
  #     to all-data is NOT discharged).
  #   - YM: `cluster_decomposition_proven` IS promoted to a real
  #     theorem (the placeholder body is trivial reflexivity), but
  #     `vacuum_gap_positive_theorem` stays a schema (iff-bridge
  #     to real exponential clustering; the genuine open Clay
  #     step of producing an unconditional Δ > 0 from real
  #     clustering is NOT discharged). YM / NS / Spectral towers
  #     stay Status: Open (`docs/ROADMAP.md` § 2 / § 3).
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.InfraredCutoff_Λ"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_IR_regularized"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_IR"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.IR_removal_limit_schema"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_persists_under_limit_schema"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Enstrophy_critical_bound"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.BealeKatoMajda_bootstrap"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Conditional_regularity_theorem"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Blowup_exclusion_small_target"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Global_scheme_for_all_data"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.Correlation_length_from_coercive"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.Exponential_clustering_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.cluster_decomposition_proven"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.spectral_gap_from_clustering"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.vacuum_gap_positive_theorem"
  # ---- Batch 14 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Track 1: uniform IR bound on
  # Spectral/OperatorV2.lean (`Hamiltonian_IR_gap_uniform` stays
  # schema; `MassGap_continuum` stays schema per tripwire;
  # `continuum_limit_exists` + `first_excitation_continuum` real;
  # `spectrum_discrete_below_2Δ` schema). Track 2: break the
  # conditional on NS/EnergyV2.lean (`Enstrophy_bound_unconditional`
  # is the explicitly-hardest schema; `Global_regularity_proven`
  # stays schema per tripwire; `BKM_implies_strong_L3_bound` +
  # `Ladyzhenskaya_inequality` + `Serrin_criterion_L3` real on
  # zero only). Track 3: prove clustering on YM/Spectrum.lean
  # (`clustering_for_YM3` is the explicitly-hardest schema;
  # `MassGap_YM4_proven` stays schema per tripwire;
  # `OS_reconstruction_from_H` schema; `reflection_positivity_check`
  # + `correlation_decay_from_gap` real). All three towers stay
  # Status: Open. No Clay claim — Δ > 0 for SU(3) 4D is NOT proven
  # in any of these files.
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Hamiltonian_IR_gap_uniform"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.continuum_limit_exists"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_continuum"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.first_excitation_continuum"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.spectrum_discrete_below_2Δ"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Enstrophy_bound_unconditional"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.BKM_implies_strong_L3_bound"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Ladyzhenskaya_inequality"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Serrin_criterion_L3"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Global_regularity_proven"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.OS_reconstruction_from_H"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.reflection_positivity_check"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.correlation_decay_from_gap"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.clustering_for_YM3"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.MassGap_YM4_proven"
)

VERIFIER_DIR="$(mktemp -d)"
AXIOM_LOG="$(mktemp)"
trap 'rm -f "$AXIOM_LOG"; rm -rf "$VERIFIER_DIR"' EXIT

check_brick() {
  local module="$1"
  local thm="$2"
  local thm_escaped
  thm_escaped="$(printf '%s' "$thm" | sed 's/[.]/\\./g')"

  local verifier="$VERIFIER_DIR/Verify_${thm//./_}.lean"
  cat > "$verifier" <<EOF
import $module
#print axioms $thm
EOF

  echo ">> axiom-debt check: $thm" >&2
  if ! lake env lean "$verifier" 2>&1 | tee "$AXIOM_LOG" >&2; then
    echo "error: lake env lean on verifier for $thm failed." >&2
    return 1
  fi

  local zero_line="'$thm' does not depend on any axioms"
  # Flatten the log first: `#print axioms` wraps long axiom lists across
  # multiple lines, but grep -E does not span lines. Collapsing
  # newlines+whitespace to single spaces lets the regex below match
  # both the single-line case (short axiom names) and the wrapped case
  # (e.g. three classical-trio axioms spread across three lines).
  local flat
  flat="$(tr '\n' ' ' < "$AXIOM_LOG" | tr -s '[:space:]' ' ')"
  local trio_re="'${thm_escaped}' depends on axioms: \[((propext|Classical\.choice|Quot\.sound)(, (propext|Classical\.choice|Quot\.sound)){0,2})\]"

  if grep -qF "$zero_line" "$AXIOM_LOG"; then
    echo "ok: $thm has axiom debt = [] (no axioms used at all)." >&2
  elif printf '%s\n' "$flat" | grep -qE "$trio_re"; then
    echo "ok: $thm axiom footprint = subset of mathlib's classical trio" >&2
    echo "    {propext, Classical.choice, Quot.sound}. No research-grade axioms." >&2
  else
    echo "error: axiom-debt check failed for $thm." >&2
    echo "       Allowed: (a) no axioms at all, or" >&2
    echo "                (b) a subset of {propext, Classical.choice, Quot.sound}." >&2
    echo "       Got:" >&2
    cat "$AXIOM_LOG" >&2
    return 2
  fi
}

for entry in "${BRICKS[@]}"; do
  module="${entry%%|*}"
  thm="${entry#*|}"
  check_brick "$module" "$thm"
done

echo "ok: Towers library built; all ${#BRICKS[@]} brick(s) passed the axiom-footprint check." >&2
