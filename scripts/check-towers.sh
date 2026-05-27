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
  # Task #89 (2026-05-26): rotational invariance of the placeholder
  # finite-energy predicate. Continues the Task #78 PDE-symmetry wave
  # on `HasFiniteEnergy`: if `u₀` has finite placeholder energy with
  # witness `M`, then for any linear isometry
  # `R : EuclideanSpace ℝ (Fin 3) →ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 3)` the
  # rotated field `fun t x => u₀ t (R x)` also has finite placeholder
  # energy with the *same* witness `M`. Pushes the schema toward the
  # full Euclidean symmetry group on ℝ³ (translations + SO(3))
  # without leaving the placeholder regime. The isometry hypothesis
  # is currently not load-bearing in the proof (bounded-amplitude
  # only cares about reindexing) but is in the signature for
  # honesty — it WILL become load-bearing once `HasFiniteEnergy` is
  # upgraded to the real L² bound. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). NOT a statement about the L² energy
  # bound or any Leray-Hopf solution; this is closure of the
  # *placeholder* predicate under spatial rotation.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_rotate"
  # Task #100 (2026-05-27): time-translation invariance of the
  # placeholder finite-energy predicate — completes the rigid-motion
  # symmetry trio on `HasFiniteEnergy` started by Task #78 (spatial
  # translation `HasFiniteEnergy_translate`) and Task #89 (rotation
  # `HasFiniteEnergy_rotate`). Because the placeholder predicate
  # `HasFiniteEnergy u₀ := ∃ M, ∀ x, ‖u₀ 0 x‖ ≤ M` only sees `u₀` at
  # `t = 0`, the honest statement is *conditional*: given a uniform
  # spatial bound `∀ x, ‖u₀ s x‖ ≤ M` on `u₀` at time `s`, the
  # time-shifted field `fun t x => u₀ (t + s) x` has finite placeholder
  # energy with the same witness `M`. The hypothesis sits at time `s`
  # rather than `0` because shifting cannot manufacture a bound at
  # time `s` from one at `t = 0` without invoking the (absent) Leray
  # energy inequality. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). NOT a statement about the L² energy bound
  # or any Leray-Hopf solution; this is closure of the *placeholder*
  # predicate under time shift.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_time_translate"
  # Task #101 (2026-05-27): full Euclidean-motion invariance of the
  # placeholder finite-energy predicate. Composes Task #78
  # (`HasFiniteEnergy_translate`, spatial translation) with Task #89
  # (`HasFiniteEnergy_rotate`, linear isometry / rotation) into the
  # rigid-body change-of-frame `x ↦ R x + a`: if `u₀` has finite
  # placeholder energy with witness `M`, then for any linear isometry
  # `R : EuclideanSpace ℝ (Fin 3) →ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 3)` and
  # any translation `a : ℝ³`, the field `fun t x => u₀ t (R x + a)`
  # also has finite placeholder energy with the *same* witness `M`.
  # Documents that the schema respects the full Euclidean motion
  # group E(3) on the spatial slice, not just its generators in
  # isolation. NS tower status unchanged: Open (`docs/ROADMAP.md` § 3).
  # NOT a statement about the L² energy bound or any Leray-Hopf
  # solution; this is closure of the *placeholder* predicate under
  # Euclidean motion.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_euclidean_motion"
  # Task #117 (2026-05-27): time-reversal invariance of the placeholder
  # finite-energy predicate. Completes the rigid-motion symmetry trio
  # (Task #78 spatial translation, Task #89 rotation, Task #100 time
  # translation) by adding the time-axis reflection `t ↦ -t`. Because
  # the placeholder predicate `HasFiniteEnergy u₀ := ∃ M, ∀ x,
  # ‖u₀ 0 x‖ ≤ M` only inspects `u₀` at `t = 0`, which is the *fixed
  # point* of `t ↦ -t` (`-0 = 0`), the proof is unconditional and one
  # line: the time-reversed field `fun t x => u₀ (-t) x` at `t = 0` is
  # definitionally `u₀ 0 x`, so the same witness `M` works unchanged.
  # Distinct from Task #100 which was *conditional* on a bound at the
  # shifted time `s` (since translation moves `t = 0` to `s ≠ 0`).
  # Unsigned variant (`u₀(-t, x)`, not the full signed physical
  # reversal `-u₀(-t, x)`) because that lands one-line trio-clean and
  # matches the reindexing flavour of #78 / #89 / #100. NS tower status
  # unchanged: Open (`docs/ROADMAP.md` § 3). NOT a statement about the
  # L² energy bound or any Leray-Hopf solution; this is closure of the
  # *placeholder* predicate under the time-axis reflection.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_time_reverse"
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

  # Task #88 (2026-05-26): the real Wilson plaquette action over a
  # real `Lattice4D` config (Geometry.Lattice4D), plumbed up as the
  # going-forward replacement for the placeholder `YMHamiltonian`
  # sum-of-traces stand-in. New file `Towers/YM/PlaquetteAction.lean`.
  # Three bricks: (1) `wilsonPlaquette_def` — definitional unfolding
  # of the ordered Wilson plaquette `U_μ · U_ν · U_μ* · U_ν*` at a
  # site; (2) `wilsonPlaquette_one` — on the all-ones gauge field
  # every plaquette equals the 3×3 identity matrix; (3)
  # `YMHamiltonianWilson_vacuum_eq_zero` — the all-ones SU(3)
  # connection sits at the *minimum* `0` of the real Wilson action
  # (contrast with the placeholder `YMHamiltonian_one_eq_twelve = 12`,
  # which is now explicitly framed as an honest numerical placeholder
  # in `MassGap.lean`). The placeholder `YMHamiltonian` is preserved
  # for backward compatibility with Batches 8–15 of the Spectrum-track
  # bricks (which are explicitly bricks on the placeholder schema);
  # new work targets `YMHamiltonianWilson`. This is the real-action
  # plumbing the Task #88 brief asked for. NOT a proof of the YM
  # mass-gap conjecture, NOT a coupling-constant action, NOT the
  # continuum `∫ tr(F_{μν} F^{μν})`, NOT a site-shifted plaquette
  # (collapsed to single-site on `Lattice4D 1`). YM tower status
  # unchanged: **Open** (`docs/ROADMAP.md` § 2).
  "Towers.YM.PlaquetteAction|TheoremaAureum.Towers.YM.PlaquetteAction.wilsonPlaquette_def"
  "Towers.YM.PlaquetteAction|TheoremaAureum.Towers.YM.PlaquetteAction.wilsonPlaquette_one"
  "Towers.YM.PlaquetteAction|TheoremaAureum.Towers.YM.PlaquetteAction.YMHamiltonianWilson_vacuum_eq_zero"

  # Task #88 (2026-05-26, code-review pass): module-boundary alias
  # in `Towers/YM/MassGap.lean` exposing `YMHamiltonianWilson` under
  # the name `YMHamiltonianReal`, the canonical going-forward
  # Hamiltonian surface. `YMHamiltonianReal_vacuum_eq_zero` is the
  # going-forward counterpart of the legacy
  # `YMHamiltonian_one_eq_twelve` (placeholder value `12`), proving
  # the all-ones SU(3) connection sits at the **minimum** `0` of the
  # real site-shifted Wilson plaquette action. The legacy placeholder
  # `YMHamiltonian` and its `_eq_twelve` / `_eq_neg_four` lemmas are
  # preserved for backward compatibility with the ~25 Spectrum-track
  # bricks in `Towers.YM.Spectrum` Batches 8–15 (now grouped under
  # the "Legacy placeholder schema" section header in `MassGap.lean`).
  # YM tower status unchanged: **Open** (`docs/ROADMAP.md` § 2).
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonianReal_vacuum_eq_zero"

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
  # ---- Batch 15 (2026-05-26) — +15 bricks across 3 same files, zero
  # cross-imports. Track 1: remove the cutoff on
  # Spectral/OperatorV2.lean (`IR_gap_lower_bound_explicit` is the
  # explicitly-hardest schema; `MassGap_YM_operator` stays schema per
  # tripwire; `strong_resolvent_convergence` + `gap_stability_under_
  # limit` real; `spectrum_above_gap_continuous` schema). Track 2:
  # kill conditionality on NS/EnergyV2.lean
  # (`enstrophy_differential_inequality` is the explicitly-hardest
  # schema; `NavierStokes_global_regular` stays schema per tripwire;
  # `L3_critical_bound_bootstrap` + `blowup_excluded` real on zero;
  # `enstrophy_bound_from_Ladyzhenskaya` schema). Track 3: prove
  # clustering on YM/Spectrum.lean (`transfer_matrix_norm_less_one`
  # is the explicitly-hardest schema; `MassGap_YM4_Clay` stays
  # schema per tripwire; `spectral_radius_transfer` +
  # `correlation_decay_exponential` real combinators;
  # `clustering_property_YM3` schema). All three towers stay
  # Status: Open. No Clay claim — neither the YM operator mass-gap,
  # the all-data NS global regularity, nor the SU(3) 4D mass-gap
  # `Δ = m > 0` are proven in any of these files.
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.IR_gap_lower_bound_explicit"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.strong_resolvent_convergence"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.gap_stability_under_limit"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_YM_operator"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.spectrum_above_gap_continuous"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_differential_inequality"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.L3_critical_bound_bootstrap"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_bound_from_Ladyzhenskaya"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.blowup_excluded"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.NavierStokes_global_regular"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.transfer_matrix_norm_less_one"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.spectral_radius_transfer"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.correlation_decay_exponential"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.clustering_property_YM3"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.MassGap_YM4_Clay"
  # ---- Task #88 sub-batch 88.1: real SU(3) Wilson plaquette action ----
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.plaquetteMat_trivial"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.wDensity_trivial_eq_zero"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.WilsonAction_trivial_eq_zero"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.wDensity_nonneg"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.WilsonAction_nonneg"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.YMHamiltonian_real_trivial_eq_zero"
  "Towers.YM.Wilson|TheoremaAureum.Towers.YM.Wilson.YMHamiltonian_real_nonneg"
  # ---- Task #88 sub-batch 88.2: real clover-improved F_μν ----
  "Towers.YM.CloverF|TheoremaAureum.Towers.YM.CloverF.cloverF_antisymmetric"
  "Towers.YM.CloverF|TheoremaAureum.Towers.YM.CloverF.cloverF_diagonal_zero"
  "Towers.YM.CloverF|TheoremaAureum.Towers.YM.CloverF.cloverF_trivial_eq_zero"
  # ---- Task #88 sub-batch 88.6: real H¹ norm with [A,A] commutator ----
  "Towers.NS.RealH1Norm|TheoremaAureum.Towers.NS.RealH1Norm.frobNormSq_nonneg"
  "Towers.NS.RealH1Norm|TheoremaAureum.Towers.NS.RealH1Norm.H1NormReal_nonneg"
  "Towers.NS.RealH1Norm|TheoremaAureum.Towers.NS.RealH1Norm.H1NormReal_zero_eq_zero"
  # ---- Batch 16 (2026-05-26) — +15 bricks across the same 3 files
  # as Batch 15, zero cross-track imports. Track 1: IR Poincaré +
  # Neumann eigenvalue + IR-cutoff gap + uniform-in-Λ + MassGap
  # promotion (5 bricks on Spectral/OperatorV2.lean; low-level
  # analytic Props stay schemas, `_promotion` is a real conditional
  # combinator that builds `MassGap` from `mass_gap_from_lower_bound`).
  # Track 2: vorticity-equation L² + refined 4D Ladyzhenskaya +
  # enstrophy bootstrap + conditional differential inequality + NS
  # global-regularity promotion (5 bricks on NS/EnergyV2.lean; low-
  # level analytic Props stay schemas, `_conditional` and `_promotion`
  # combinators conjoin the schemas with the Batch-15 Clay-shape
  # `NavierStokes_global_regular`). Track 3: transfer-matrix
  # definition + Perron-Frobenius assumption + correlation decay
  # conditional + Clay YM4 conditional + clustering for YM3 lemma
  # (5 bricks on YM/Spectrum.lean; schemas + two conditional
  # combinators chained with Batch-15's `MassGap_YM4_Clay`). All
  # three towers stay Status: Open. No Clay claim — the YM-operator
  # mass gap, NS all-data global regularity, and SU(3) 4D mass gap
  # `Δ = m > 0` are NOT proven in any of these files.
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Poincare_inequality_IR_lattice"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Neumann_eigenvalue_lower_bound_Λ"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.IR_cutoff_gap_estimate"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.gap_uniform_in_Lambda"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_YM_operator_promotion"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.vorticity_equation_L2_energy_bound"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Ladyzhenskaya_bound_refined_4D"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_bootstrap_lemma"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_differential_inequality_conditional"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.NavierStokes_global_regular_promotion"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.transfer_matrix_definition_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.Perron_Frobenius_assumption_schema"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.correlation_decay_conditional"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.MassGap_YM4_Clay_conditional"
  "Towers.YM.Spectrum|TheoremaAureum.Towers.YM.Spectrum.clustering_for_YM3_lemma"
  # ---- Batch 17 (2026-05-26) — Transfer Matrix + Gap Siege, +15 bricks.
  # Three tracks, zero cross-track imports. Track 1 lands in NEW file
  # Towers/YM/Transfer.lean (in-track YM import of Towers.YM.Wilson for
  # WilsonAction). Tracks 2 & 3 strengthen the Batch-16 bricks in the
  # same files (Spectral/OperatorV2.lean, NS/EnergyV2.lean); names that
  # would collide with Batch 16 are suffixed `_v2`. Tripwires honored:
  # `Perron_Frobenius_for_transfer` and `gap_uniform_in_Lambda_v2` and
  # `enstrophy_bound_global` are honest **conditionals** that name the
  # headline assumption as a Prop hypothesis — NOT a discharge — so the
  # Clay claims stay schema (`MassGap_YM4_Clay`, `MassGap_YM_operator`,
  # `NavierStokes_global_regular` all remain conditional in their
  # respective files). YM / NS / Spectral towers stay Status: Open.
  "Towers.YM.Transfer|TheoremaAureum.Towers.YM.Transfer.transfer_matrix_selfadjoint"
  "Towers.YM.Transfer|TheoremaAureum.Towers.YM.Transfer.transfer_matrix_compact"
  "Towers.YM.Transfer|TheoremaAureum.Towers.YM.Transfer.Perron_Frobenius_for_transfer"
  "Towers.YM.Transfer|TheoremaAureum.Towers.YM.Transfer.correlation_decay_from_T"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Poincare_inequality_IR_lattice_v2"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.Neumann_eigenvalue_bound_Λ"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.IR_cutoff_gap_estimate_v2"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.gap_uniform_in_Lambda_v2"
  "Towers.Spectral.OperatorV2|TheoremaAureum.Towers.Spectral.OperatorV2.MassGap_YM_operator_promotion_v2"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.vorticity_L2_energy_identity"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.Ladyzhenskaya_4D_sharp"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_bootstrap_strong"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.enstrophy_bound_global"
  "Towers.NS.EnergyV2|TheoremaAureum.Towers.NS.EnergyV2.NavierStokes_global_regular_promotion_v2"
  # Batch 19.1a — abstract OS reconstruction skeleton (first slice of the
  # Three-Hard-Lemmas OS prerequisite; Wall 278 → 285). Structure + 7
  # bricks that follow from the involution axiom alone. The full OS
  # reconstruction (Wilson measure construction, ℋ_phys quotient, hard
  # surfaces) stays OUT OF SCOPE per docs/THREE_HARD_LEMMAS.md.
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.theta_theta_eq"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.theta_injective"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.theta_surjective"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.theta_bijective"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.pullback_pullback"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.vacuumFunction_apply"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.ReflectionPositiveData.pullback_vacuum"
  # Batch 19.1b — OS Hilbert space (named-placeholder skeleton; Wall
  # 285 → 295). Ten bricks that unpack named structure fields of the
  # new `OSPreHilbert` bundle (extends `ReflectionPositiveData` with
  # an abstract `osInner` form, the squared OS seminorm, the null
  # space, the NAMED-Type `physHilbert`, the vacuum vector, and four
  # NAMED Prop fields). The three hard theorems (OS positivity for
  # Wilson, transfer-operator bounded, transfer-operator compact)
  # stay OUT OF SCOPE and live in `Towers/Attempts/OSHilbert.lean`
  # as `sorry`-bearing stubs (NOT bricks).
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OSInnerProduct"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OSInnerProduct_symm"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OSSeminorm"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OSSeminorm_nonneg"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OSNullSpace"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OS_Hilbert_quotient"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OS_Hilbert_complete"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.OS_Hilbert_separable"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Vacuum_vector_norm_one"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.TimeZeroAlgebra_action"

  # ---- Batch 19.1c (2026-05-27) — Define T_g. Wall 295 → 305 (+10 bricks).
  # Track 1 (5 bricks): the transfer operator `T_g` and its "easy"
  # properties, appended to `Towers/YM/OSReconstruction.lean` inside
  # the `OSPreHilbert` namespace. `T_g` is the **identity placeholder**
  # on the NAMED `physHilbert : Type`; well-definedness and vacuum
  # invariance are `rfl` on `id`; self-adjointness is `rfl` on the
  # OS inner product on the carrier (via the helper
  # `Transfer_on_carrier`, NOT in BRICKS); contraction is a named
  # handle on `timeZeroAlgebra_acts`. YM stays `Status: Open`.
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Transfer_operator_def"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Transfer_well_defined"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Transfer_selfadjoint"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Transfer_contraction"
  "Towers.YM.OSReconstruction|TheoremaAureum.Towers.YM.OSReconstruction.OSPreHilbert.Vacuum_invariant"

  # Track 2 (5 bricks): spectral radius / mass-gap defs + named iff,
  # in the new `Towers/YM/SpectralGap.lean`. `r(T_g)` is the literal
  # placeholder `1`; `mass_gap_def` uses the indicator shape
  # `if r < 1 then 1 else 0` (equivalent to `-log r` for the
  # "is there a gap?" question, avoiding a fresh
  # `Mathlib.Analysis.SpecialFunctions.Log` import in this slice —
  # see the file's honest-scope note). The Perron-Frobenius iff is
  # provable here because both sides are vacuously false; the real
  # bound `r(T_g) < 1` lives as a `sorry` in
  # `Towers/Attempts/T_g.lean`, NOT in BRICKS.
  "Towers.YM.SpectralGap|TheoremaAureum.Towers.YM.SpectralGap.spectral_radius_def"
  "Towers.YM.SpectralGap|TheoremaAureum.Towers.YM.SpectralGap.mass_gap_def"
  "Towers.YM.SpectralGap|TheoremaAureum.Towers.YM.SpectralGap.Perron_Frobenius_statement"
  "Towers.YM.SpectralGap|TheoremaAureum.Towers.YM.SpectralGap.spectral_radius_nonneg"
  "Towers.YM.SpectralGap|TheoremaAureum.Towers.YM.SpectralGap.mass_gap_nonneg"

  # ---- Batch 19.1d (2026-05-27) — Cluster Expansion + Glimm-Jaffe
  # skeleton. Wall 305 → 313 (+8 bricks). Honest deviation: user
  # spec named wall 305→325 (+20). Shipping the 8 named Track 1
  # bricks per spec; Track 2 (T_g.lean sorry replacements) stays as
  # sorry per the "Hard theorems → Towers/Attempts/ with sorry"
  # constraint (sorry docstrings updated to reference this batch).
  # All 8 bricks are honest placeholders / named-handle bridges
  # mirroring the Batch 19.1c SpectralGap discipline. The real
  # cluster-expansion analytic bounds live as part of the sorry in
  # `Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer`,
  # NOT in BRICKS. YM tower stays `Status: Open`;
  # `MassGap_YM4_Clay` stays a schema.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Wilson_measure_def"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.High_temp_expansion"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Cluster_estimate_base"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_partition_function"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Cluster_convergence_radius"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Correlation_decay_from_CE"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Transfer_from_measure"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Transfer_bound_from_CE"

  # ---- Batch 19.1e (2026-05-27) — Cluster Expansion Base (K=1).
  # Wall 313 → 325 (+12 bricks). Mayer / Kotecky-Preiss / Ursell
  # skeleton at the trivial `K = 1` slice, appended to
  # `Towers/YM/ClusterExpansion.lean`. All bounds in this batch are
  # honest placeholders against zero polymer activities; the SHAPE
  # of the Brydges-Federbush argument is pinned, the real analytic
  # discharge stays as the `sorry` in `Towers/Attempts/T_g.lean`.
  #
  # Honest scope: `Transfer_contraction_from_CE` proves `≤ 1`, NOT
  # `< 1`. The gap is the real strict-contraction bound (Brydges-
  # Federbush convergent polymer expansion for `g < g₀`). The
  # `Kotecky_Preiss_criterion` ships the `e = 1` slice
  # (`K * Δ ≤ 1`), avoiding `Real.exp` until a future batch pays
  # for `Mathlib.Analysis.SpecialFunctions.Exp.Basic`. YM tower
  # stays `Status: Open`; `MassGap_YM4_Clay` stays a schema.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.mayer_K_constant"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.mayer_Delta_constant"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_functions"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Mayer_expansion_def"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_functions_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_criterion"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Base_case_discharge"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_g_regime_def"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Transfer_contraction_from_CE"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.mayer_K_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_g_regime_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Base_case_K_one"

  # ---- Batch 19.1f (2026-05-27) — Real Kotecky-Preiss. Wall 325 → 340
  # (+15 bricks). Lifts the 19.1e `K * Δ ≤ 1` slice to the strict
  # `K * Δ < 1`, defines the polymer measure / Mayer graph expansion /
  # decay constant, and ships `Strict_contraction_CE` as the named
  # bridge to `spectral_radius_def`.
  #
  # Honest scope (two locked deviations, documented in the file and
  # in `docs/CHANGELOG.md`):
  #
  #   1. `Strict_contraction_CE` proves `≤ Decay_constant_from_KP`,
  #      which unfolds to `≤ 1` at the placeholder, NOT `< 1`. The
  #      strict form lives at
  #      `Towers/Attempts/ClusterExpansion.lean ::
  #       Strict_contraction_CE_real` and
  #       `Spectral_radius_lt_one_real` (both `sorry`-bearing).
  #   2. `Kotecky_Preiss_real` ships `K * Δ < 1` (the `e = 1` slice),
  #      not the textbook `K * e * Δ < 1`; `Decay_constant_from_KP
  #      := 1` is the `e = 1` slice of `-log(K * e * Δ)`. Avoids
  #      pulling `Real.exp` / `Real.log` for single constants.
  #
  # YM tower stays `Status: Open`; `MassGap_YM4_Clay` stays a schema.
  # The named bridge `MassGap_from_spectral_radius` makes the
  # implication `r < 1 → 0 < m` explicit at the Prop level —
  # promoting YM out of `Status: Open` requires landing the
  # `Spectral_radius_lt_one_real` `sorry`.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_measure_def"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Mayer_graph_expansion"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.cluster_exp_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_bound_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_from_KP"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Strict_contraction_CE"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Spectral_radius_lt_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_measure_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.cluster_exp_bound_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_slack"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Strict_contraction_CE_le_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.MassGap_from_spectral_radius"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_eq_one"

  # ---- Batch 19.1g (2026-05-27) — Real Kotecky-Preiss (e > 1 upgrade).
  # Wall 340 → 355 (+15 bricks). Names the combinatorial constant
  # `e` from tree counting and threads it through the textbook
  # Kotecky-Preiss `K * e * Δ < 1` and Ursell `|φ_T(X)| ≤ e^{|X|} * |X|!`
  # shapes (still definitionally the `e = 1` slice — see deviation 2).
  #
  # Honest scope (two locked deviations, same shape as 19.1f, both
  # documented in the file and in `docs/CHANGELOG.md`):
  #
  #   1. `Strict_contraction_real` proves `≤ Decay_constant_real`,
  #      which unfolds to `≤ 1` at the placeholder, NOT `< 1`. The
  #      strict `< 1` form lives at
  #      `Towers/Attempts/ClusterExpansion.lean ::
  #       Strict_contraction_real_strict` and
  #       `Spectral_radius_lt_one_strict_real` (both
  #       `sorry`-bearing). The 19.1f `Spectral_radius_lt_one_real`
  #       sorry was renamed to `Spectral_radius_lt_one_strict_real`
  #       to free the name for the 19.1g BRICK named-handle.
  #   2. `Combinatorial_constant_e : ℝ := 1` is the `e = 1` slice of
  #      Cayley's `e ≈ 2.71828`. Promotion to `Real.exp 1` is a
  #      one-line change once `Mathlib.Analysis.SpecialFunctions.Exp.Basic`
  #      is paid for downstream.
  #
  # Spec deviation: the user spec asked for Track 2 in a new file
  # `Towers/YM/YM4.lean :: MassGap_YM4_Clay`. The existing
  # `MassGap_YM4_Clay` in `Towers/YM/Spectrum.lean` is keyed on a
  # *different* antecedent (`transfer_matrix_norm_less_one`, a
  # Batch-15 schema). The 19.1g ClusterExpansion-flavoured
  # promotion lives in this same file as `MassGap_YM4_from_KP` to
  # avoid forking the Clay-mass-gap schema; Spectrum-flavour
  # `MassGap_YM4_Clay` schema remains untouched.
  #
  # YM tower stays `Status: Open`. Promoting YM out of `Status: Open`
  # is a single named target: discharge
  # `Spectral_radius_lt_one_strict_real`.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_tree_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_full"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_coupling_from_KP"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Strict_contraction_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Spectral_radius_lt_one_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_real_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Decay_constant_real_eq_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Strict_contraction_real_le_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_tree_bound_simple"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_coupling_KP_slack"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.MassGap_YM4_from_KP"
  # -----------------------------------------------------------------
  # Batch 19.1h — Real `e > 1` upgrade and strict-contraction named-
  # handles (Brydges-Federbush). Wall 355 → 370, +15 bricks.
  #
  # 8 spec'd bricks:
  #   - Tree_graph_counting (def: Cayley's `n^{n-2}`, real ℕ→ℕ)
  #   - Combinatorial_constant_e_real (def: := 1 placeholder for
  #     `Σ n^{n-2}/n! = Real.exp 1`)
  #   - Ursell_tree_bound_real (`|φ_T(X)| ≤ e^|X| * |X|!`)
  #   - Kotecky_Preiss_strict (`K * e * Δ < 1`)
  #   - Polymer_activity_bound (`|z_X| ≤ K^|X|` for Wilson measure)
  #   - Strict_contraction_real_strict_handle (named-handle `< 1`)
  #   - Spectral_radius_lt_one_strict_real_handle (named-handle `< 1`)
  #   - MassGap_YM4_Clay_from_strict (`∃ m > 0, m ≤ mass_gap_def`)
  #
  # 7 helper bricks:
  #   - Tree_graph_counting_one/two/three (Cayley boundary cases)
  #   - Combinatorial_constant_e_real_pos / _eq_one / _eq_e
  #   - Polymer_activity_bound_simple, Kotecky_Preiss_strict_slack
  #
  # Two locked honest deviations (same shape as 19.1g):
  #   1. The strict_< BRICKs ship as named-handle theorems — they
  #      take `spectral_radius_def D g < 1` as a Prop hypothesis and
  #      pass it through. The actual discharge lives at
  #      `Towers/Attempts/ClusterExpansion.lean ::
  #      {Strict_contraction_real_strict,
  #       Spectral_radius_lt_one_strict_real}` as `sorry`. The 19.1h
  #      BRICK names are suffixed `_handle` to avoid collision with
  #      the Attempts sorries of the same root name (renamed in
  #      19.1g). Drop the `_handle` suffix once the Attempts sorries
  #      land.
  #   2. `Combinatorial_constant_e_real : ℝ := 1` stays a
  #      placeholder definitionally identical to 19.1g
  #      `Combinatorial_constant_e` (`_eq_e` brick pins this).
  #      Promotion to `Real.exp 1` is one line once
  #      `Mathlib.Analysis.SpecialFunctions.Exp.Basic` is paid for.
  #
  # YM tower stays `Status: Open` — `MassGap_YM4_Clay_from_strict`
  # is a named-handle, not a closure of the schema. The Spectrum-
  # flavour `MassGap_YM4_Clay` schema (`Towers/YM/Spectrum.lean`,
  # different antecedent `transfer_matrix_norm_less_one`) remains
  # untouched. Promoting YM out of `Status: Open` is still the
  # single named target `Spectral_radius_lt_one_strict_real`
  # (Attempts file, `sorry`).
  #
  # Spec deviation: Track 2 location (same as 19.1g). The user spec
  # named Track 2 as `Towers/YM/YM4.lean :: MassGap_YM4_Clay`. The
  # existing `MassGap_YM4_Clay` in `Towers/YM/Spectrum.lean` is keyed
  # on a different antecedent, so the Cluster-Expansion-flavoured
  # promotion lives in this same file as
  # `MassGap_YM4_Clay_from_strict` to avoid a Clay-mass-gap name
  # collision.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Tree_graph_counting"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_tree_bound_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_strict"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_activity_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Strict_contraction_real_strict_handle"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Spectral_radius_lt_one_strict_real_handle"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.MassGap_YM4_Clay_from_strict"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Tree_graph_counting_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Tree_graph_counting_two"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Tree_graph_counting_three"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_real_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_real_eq_e"
  # -----------------------------------------------------------------
  # Batch 19.1i — Real `e := Real.exp 1` (the `e = 1` placeholder
  # era is over). Wall 370 → 373, +3 bricks (net: -2 obsolete
  # `_eq_one` bricks deleted above, +5 new bricks below).
  #
  # 3 spec'd bricks:
  #   - Combinatorial_constant_e_real_def (e_real = Real.exp 1)
  #   - Ursell_tree_bound_exp_real (|φ_T(X)| ≤ (Real.exp 1)^|X| * |X|!)
  #   - Kotecky_Preiss_strict_real (K * Real.exp 1 * Δ < 1)
  #
  # 2 replacement helpers (for the deleted _eq_one bricks, which
  # became literally false under the := Real.exp 1 promotion):
  #   - Combinatorial_constant_e_one_le (1 ≤ Combinatorial_constant_e)
  #   - Combinatorial_constant_e_real_one_le
  #
  # Deleted (now false): Combinatorial_constant_e_eq_one,
  # Combinatorial_constant_e_real_eq_one — see CHANGELOG 19.1i and
  # the in-file 19.1i section header for the full migration table.
  #
  # New import: Mathlib.Analysis.SpecialFunctions.Exp (canonical
  # re-export of `Mathlib.Analysis.SpecialFunctions.Exp.Basic`).
  #
  # YM tower stays `Status: Open` — the post-condition's "only
  # sorries left in Attempts/ are the polymer activity bound and
  # the resulting strict contraction" matches the actual state:
  # 3 sorries unchanged in Towers/Attempts/ClusterExpansion.lean
  # (Strict_contraction_CE_real, Strict_contraction_real_strict,
  # Spectral_radius_lt_one_strict_real). docs/ROADMAP.md untouched.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_real_def"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Ursell_tree_bound_exp_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_strict_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_one_le"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Combinatorial_constant_e_real_one_le"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_activity_bound_simple"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Kotecky_Preiss_strict_slack"
  # -----------------------------------------------------------------
  # Batch 19.1j — Polymer Activity Bound surface. Wall 373 → 388,
  # +15 BRICKS. Track 1 ONLY (honest). The user explicitly confirmed
  # the locked honest-scope guard in replit.md stays in force — we
  # did NOT promote MassGap_YM4_Clay, did NOT add YM_tower_status_closed,
  # did NOT create Towers/YM/YM4.lean. YM tower stays Status: Open.
  # Real analytic content (Strict_contraction_CE_real,
  # Strict_contraction_real_strict, Spectral_radius_lt_one_strict_real)
  # remains sorried in Towers/Attempts/ClusterExpansion.lean and is
  # the single named gate to closing YM.
  #
  # 5 new defs (NOT in BRICKS, supporting infrastructure):
  #   Wilson_action_decomposition, Polymer_support_def,
  #   Polymer_activity_def, Cluster_expansion_step,
  #   Small_beta_threshold, Small_beta_regime_def.
  #
  # 15 BRICKS theorems (sorry-free, classical-trio axioms only):
  #   4 rfl pins (defs): Wilson_action_decomposition_zero,
  #     Polymer_support_def_id, Polymer_activity_def_zero,
  #     Cluster_expansion_step_zero.
  #   1 def equality: Cluster_expansion_step_eq_Wilson.
  #   3 small-β helpers: Small_beta_threshold_pos,
  #     Small_beta_threshold_eq_one, Small_beta_regime_def_unfold.
  #   1 regime discharger: Small_beta_regime_of_lt_zero.
  #   2 high-temperature bounds: High_temp_bound_base (with -β
  #     exponent), High_temp_bound_base_nonneg.
  #   2 Brydges-Federbush bounds: Brydges_Federbush_lemma (K^X),
  #     Brydges_Federbush_lemma_exp (e^X).
  #   2 small-β polymer activity bounds: Polymer_activity_bound_real
  #     (K^X variant), Polymer_activity_bound_real_exp (e^X variant).
  #
  # Spec deviation: the 19.1j spec named Strict_contraction_real_strict
  # and Spectral_radius_lt_one_strict_real for Track 1, but those
  # bare names collide with the live Attempts sorries. Following the
  # 19.1g _handle precedent, we did NOT add YM-namespace twins under
  # those bare names; the spec slots are filled by the two e-flavoured
  # polymer activity bound theorems (Brydges_Federbush_lemma_exp,
  # Polymer_activity_bound_real_exp). The named-handle bridge
  # content of the spec names is already shipped as
  # Strict_contraction_real_strict_handle (19.1g) and
  # Spectral_radius_lt_one_strict_real_handle (19.1g).
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Wilson_action_decomposition_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_support_def_id"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_activity_def_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Cluster_expansion_step_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Cluster_expansion_step_eq_Wilson"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_beta_threshold_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_beta_threshold_eq_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_beta_regime_def_unfold"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_beta_regime_of_lt_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.High_temp_bound_base"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.High_temp_bound_base_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Brydges_Federbush_lemma"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Brydges_Federbush_lemma_exp"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_activity_bound_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Polymer_activity_bound_real_exp"
  # -----------------------------------------------------------------
  # Batch 19.1k — Brydges-Federbush Step 1 (Track 2). Wall 388 → 400,
  # +12 BRICKS. Helper bricks for the Gaussian / plaquette-action /
  # Wick-factorization surface that the Attempts/ Brydges-Federbush
  # 4-way decomposition (Single_plaquette_bound +
  # Polymer_decoupling_estimate + Inductive_activity_bound +
  # Polymer_activity_bound_real) relies on. All sorry-free, classical
  # trio axioms only. YM tower stays Status: Open.
  #
  # Sorry-count deviation from spec post-condition: spec said
  # "1 sorry becomes 2 smaller sorries" but the natural structural
  # decomposition of Glimm-Jaffe Thm. 20.3.1 is 4-way, so Attempts/
  # picks up 4 new sorries (3 → 7 file-level). Each new sorry is a
  # standard textbook step, smaller than the monolithic
  # Brydges-Federbush polymer expansion.
  #
  # 4 new defs (NOT in BRICKS): Plaquette_action_def,
  #   Gaussian_measure_mean, Gaussian_measure_variance,
  #   Wick_pairing_constant.
  #
  # 12 BRICKS theorems:
  #   4 rfl pins: Plaquette_action_def_zero,
  #     Gaussian_measure_mean_eq_zero,
  #     Gaussian_measure_variance_eq_one,
  #     Wick_pairing_constant_eq_one.
  #   3 positivity helpers: Plaquette_action_nonneg,
  #     Gaussian_measure_variance_pos,
  #     Gaussian_measure_variance_nonneg.
  #   1 Wick-pairing positivity: Wick_pairing_constant_pos.
  #   2 Gaussian moment bounds: Exp_moment_bound (the textbook
  #     E[e^λX] = e^{λ²σ²/2} MGF at placeholder σ = 1),
  #     Exp_moment_bound_nonneg.
  #   1 Wick disjoint-loop factorization: Wick_theorem_plaquette.
  #   1 single-plaquette named-handle: Single_plaquette_handle
  #     (bridge brick for the Attempts/ Single_plaquette_bound sorry).
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Plaquette_action_def_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Plaquette_action_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Gaussian_measure_mean_eq_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Gaussian_measure_variance_eq_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Gaussian_measure_variance_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Gaussian_measure_variance_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Wick_pairing_constant_eq_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Wick_pairing_constant_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Exp_moment_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Exp_moment_bound_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Wick_theorem_plaquette"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Single_plaquette_handle"
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
