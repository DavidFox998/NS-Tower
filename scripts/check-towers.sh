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
# Corrupt-cache resilience (Task #213): the olean fetch is delegated to
# `scripts/fetch-mathlib-oleans.sh`, which guarantees mathlib oleans are
# on disk before `lake build Towers` WITHOUT ever silently falling back
# to a from-source mathlib compile. It (1) never skips the download on a
# heuristic — it always runs `lake exe cache get` (idempotent + hash-based:
# a no-op on a complete cache, a top-up of only the missing oleans
# otherwise), so a partial/incomplete cache can never slip through into a
# from-source compile, (2) heals a stale 0-byte / non-executable mathlib `cache` exe via
# `scripts/ensure-mathlib-cache-bin.sh` so `lake exe cache get` can
# rebuild + run it, (3) exits non-zero with a clear message when
# `cache get` itself fails (genuinely unreachable CDN / broken toolchain)
# instead of proceeding into a multi-hour source build, and (4) asserts
# both the cache exe and the oleans are actually populated afterwards.
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

# Ensure the prebuilt mathlib oleans are on disk before `lake build Towers`,
# WITHOUT ever silently falling back to compiling mathlib from source (Task
# #213 + lead-wall hardening). `fetch-mathlib-oleans.sh`:
#   - never skips the download on a heuristic — it always runs `lake exe cache
#     get` (idempotent + hash-based: a no-op on a complete cache, a top-up of
#     only the missing oleans otherwise), so a partial/incomplete cache can no
#     longer slip through into a from-source compile the way the old
#     sentinel-file heuristic allowed;
#   - heals a corrupt (0-byte / non-executable) mathlib `cache` exe up front via
#     `ensure-mathlib-cache-bin.sh` so `lake exe cache get` can rebuild + run it;
#   - on `cache get` failure (genuinely unreachable CDN / broken toolchain)
#     exits non-zero with a clear message rather than proceeding into a
#     multi-hour from-source build;
#   - asserts both the cache exe AND the oleans are actually populated after a
#     successful fetch.
# With real `.git/` directories in place (restore step above) `cache get` is
# safe — Lake no longer sees the packages as URL-changed and will not re-clone.
echo ">> fetch-mathlib-oleans.sh (ensure mathlib oleans; never fall back to source)" >&2
"$REPO_ROOT/scripts/fetch-mathlib-oleans.sh"

# Force a from-source recompile of the Towers layer so the wall is gated on a
# genuine clean build, never on stale oleans (Task #240 / lesson of Task #208).
# We delete ONLY this package's own build artifacts under `.lake/build/`; the
# expensive vendored mathlib cache under `.lake/packages/mathlib/.lake/build/`
# is left completely untouched, so this is cheap to recover (a Towers-only
# recompile) and never triggers a mathlib re-fetch.
echo ">> clean stale Towers oleans (force from-source recompile; mathlib cache untouched)" >&2
rm -rf "$TOWERS_DIR/.lake/build/lib/Towers" "$TOWERS_DIR/.lake/build/ir/Towers"

# Best-effort whole-library build (parallel, fast). Deliberately tolerant: a
# failure here is EXPECTED when a registered brick is broken, and aborting now
# would deny us the per-file report. The authoritative gate is the per-brick
# build+axiom loop at the bottom of this script, which pinpoints exactly which
# brick(s) failed to compile from clean oleans.
echo ">> lake build Towers (from clean; tolerant — per-brick loop below is the gate)" >&2
if ! lake build Towers; then
  echo "warn: \`lake build Towers\` reported errors; the per-brick report below" >&2
  echo "      pinpoints which registered brick(s) do not compile from clean oleans." >&2
fi

# ------------------------------------------------------------------
# Per-brick build + axiom-footprint check.
#
# Each entry is "<lean import path>|<fully qualified theorem name>".
# The lean import path is the dot-separated module name that mathlib's
# Lean elaborator expects in `import <...>` (e.g. `Towers.RH.ZeroDensity`).
# The theorem name is what `#print axioms` will receive.
#
# A brick is counted toward the wall ONLY if BOTH hold:
#   (1) its module compiles from clean oleans (`lake build <module>`), AND
#   (2) its theorem's axiom footprint is acceptable:
#         (a) truly no axioms ("does not depend on any axioms"), OR
#         (b) a subset of mathlib's classical core
#             {propext, Classical.choice, Quot.sound}.
# Any other axiom name — `sorryAx`, a user-declared `axiom`, etc. — is
# rejected. Unlike earlier revisions, the loop does NOT abort on the first
# failure: it checks every brick, prints a per-file report, reports the wall
# as the number of bricks that actually pass, and exits non-zero if any failed.
# This is what makes the wall impossible to report as healthy while the tower
# does not build (Task #240).
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
  # Task #132 (2026-05-27): *signed* time-reversal invariance of the
  # placeholder finite-energy predicate — the physically correct
  # Navier-Stokes time reversal `u₀(t, x) ↦ -u₀(-t, x)`, which Task
  # #117 deferred. Where Task #117's unsigned `HasFiniteEnergy_time_reverse`
  # reverses only the time axis (`u₀(-t, x)`) and reduces to a pure
  # reindexing (`-0 = 0`) with no norm facts, the signed variant
  # *also* applies `Neg.neg` on the velocity output — exactly the
  # physical convention that velocity reverses under time reversal.
  # At `t = 0` the transformed field is `-(u₀ 0 x)`, and the proof
  # closes via `norm_neg : ‖-v‖ = ‖v‖` + the original hypothesis.
  # Same witness `M` as `u₀` itself. Both honest variants of the
  # time-axis reflection are now on the schema. NS tower status
  # unchanged: Open (`docs/ROADMAP.md` § 3). NOT a statement about
  # the L² energy bound or any Leray-Hopf solution; this is closure
  # of the *placeholder* predicate under the full physical time
  # reversal.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_time_reverse_signed"
  # Task #118 (2026-05-27): full spacetime rigid-motion invariance of
  # the placeholder finite-energy predicate. Composes Task #100
  # (`HasFiniteEnergy_time_translate`, time translation, conditional
  # on a uniform spatial bound at the shifted time `s`) with Task #101
  # (`HasFiniteEnergy_euclidean_motion`, full spatial Euclidean motion
  # `x ↦ R x + a`) into the full spacetime rigid motion
  # `(t, x) ↦ (t + s, R x + a)` — exactly what a complete change of
  # inertial reference frame looks like on the spatial slice. Given
  # `∀ x, ‖u₀ s x‖ ≤ M`, any linear isometry
  # `R : EuclideanSpace ℝ (Fin 3) →ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 3)`,
  # and any spatial translation `a : ℝ³`, the field
  # `fun t x => u₀ (t + s) (R x + a)` also has finite placeholder
  # energy with the same witness `M`. The hypothesis sits at the
  # shifted time `s` (not `0`) — inherited from Task #100 — because
  # the placeholder predicate only sees `u₀` at `t = 0` and translation
  # cannot manufacture a bound at `s` from one at `0` without the
  # (absent) Leray energy inequality; the spatial Euclidean step
  # composes for free since it is unconditional. Documents that the
  # schema respects the full rigid-motion group on spacetime, not just
  # the purely spatial subgroup or the time axis in isolation. NS
  # tower status unchanged: Open (`docs/ROADMAP.md` § 3). NOT a
  # statement about the L² energy bound or any Leray-Hopf solution;
  # this is closure of the *placeholder* predicate under spacetime
  # rigid motion.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_spacetime_rigid_motion"
  # Task #133 (2026-05-27): parity (spatial reflection) invariance of
  # the placeholder finite-energy predicate. Completes the discrete
  # spacetime-symmetry pair (T + P) on the placeholder NS energy
  # schema alongside Task #117's unsigned time reversal
  # `HasFiniteEnergy_time_reverse` (and Task #132's signed variant).
  # Where the continuous rigid-motion quartet was carried by Task #78
  # (spatial translation), Task #89 (rotation), and Task #100 (time
  # translation), parity `x ↦ -x` is the remaining elementary discrete
  # spacetime symmetry. Proved as the one-line specialisation of
  # Task #89's `HasFiniteEnergy_rotate` instantiated with
  # `R := (LinearIsometryEquiv.neg ℝ).toLinearIsometry` — the negation
  # map is a linear isometry of `EuclideanSpace ℝ (Fin 3)`. Same
  # witness `M`. NS tower status unchanged: Open (`docs/ROADMAP.md` § 3).
  # NOT a statement about the L² energy bound or any Leray-Hopf
  # solution; this is closure of the *placeholder* predicate under
  # the spatial reflection `x ↦ -x`.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_parity"
  # Task #134 (2026-05-27): Galilean-boost invariance of the
  # placeholder finite-energy predicate — switching to an inertial
  # frame moving at constant velocity `v`, `(t, x) ↦ (t, x + v t)`.
  # The remaining piece of the full inhomogeneous Galilean group on
  # the placeholder after Task #118's full spacetime rigid motion
  # `(t, x) ↦ (t + s, R x + a)`. Because the placeholder predicate
  # `HasFiniteEnergy u₀ := ∃ M, ∀ x, ‖u₀ 0 x‖ ≤ M` only inspects `u₀`
  # at `t = 0`, and the boost `x ↦ x + v t` evaluated at `t = 0` is
  # the identity (`x + v • 0 = x`), the proof is unconditional and
  # one-line — same `t = 0`-is-fixed-point flavour as Task #117 (time
  # reversal). Same witness `M` survives unchanged. Together with
  # Task #118 (`HasFiniteEnergy_spacetime_rigid_motion`), this
  # documents closure under the full inhomogeneous Galilean group on
  # the spatial slice — the actual symmetry group of classical
  # Navier-Stokes. NS tower status unchanged: Open (`docs/ROADMAP.md`
  # § 3). NOT a statement about the L² energy bound or any Leray-Hopf
  # solution, and NOT Galilean invariance of real Navier-Stokes;
  # this is closure of the *placeholder* predicate under the boost
  # `x ↦ x + v t`.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_galilean_boost"
  # Task #146 (2026-05-27): full inhomogeneous Galilean-group invariance
  # of the placeholder finite-energy predicate — the most general change
  # of inertial reference frame classical Navier-Stokes respects,
  # `(t, x) ↦ (t + s, R x + a + v (t + s))`. Composes Task #134
  # (`HasFiniteEnergy_galilean_boost`, applied inline as the boosted
  # field `fun t x => u₀ t (x + t • v)`) with Task #118
  # (`HasFiniteEnergy_spacetime_rigid_motion`, which absorbs the
  # rotation `R`, spatial shift `a`, and time shift `s` — promoting the
  # inner `t • v` to `(t + s) • v`). Conditional on the same uniform
  # spatial bound at the shifted time `s` inherited from Task #100,
  # same witness `M` end-to-end. Documents that the placeholder schema
  # is honest under the *entire* Galilean symmetry group, not just its
  # generators in isolation, the way Task #101 documented full E(3) on
  # the spatial slice and Task #118 documented full spacetime rigid
  # motion. NS tower status unchanged: Open (`docs/ROADMAP.md` § 3).
  # NOT a statement about the L² energy bound or any Leray-Hopf
  # solution, and NOT Galilean invariance of real Navier-Stokes; this
  # is closure of the *placeholder* predicate under the full Galilean
  # change of inertial frame.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_galilean_group"
  # Task #164 (2026-05-28): rotating-frame (Coriolis) closure of the
  # placeholder finite-energy predicate — switching to a frame spinning
  # at angular velocity Ω, `(t, x) ↦ (t + s, R (t + s) x + a + (t + s) • v)`,
  # with `R : ℝ → (EuclideanSpace ℝ (Fin 3) →ₗᵢ[ℝ] EuclideanSpace ℝ (Fin 3))`
  # a time-dependent family of linear isometries rather than the fixed
  # rotation of Task #146. Same one-line composition trick as Task #146:
  # the placeholder predicate inspects `u₀` only at `t = 0`, so the
  # spinning rotation collapses to the single isometry `R s` at the
  # evaluation point and `simpa using h (R s x + a + s • v)` closes
  # the bound with the original witness `M`. Conditional on the same
  # uniform spatial bound at the shifted time `s` inherited from
  # Task #100, same witness `M` end-to-end. Completes the
  # symmetry-group catalog the placeholder schema is honest under:
  # rigid Euclidean motion (Task #101), spacetime rigid motion
  # (Task #118), full inhomogeneous Galilean group (Task #146), and
  # now the time-dependent rotating frame. NS tower status unchanged:
  # Open (`docs/ROADMAP.md` § 3). NOT a statement about the L² energy
  # bound or any Leray-Hopf solution, NOT real rotating-frame
  # invariance of Navier-Stokes — the Coriolis force `2 Ω × u` and
  # centrifugal force `Ω × (Ω × x)` are NOT present in the placeholder
  # schema. This is closure of the *placeholder* predicate under a
  # spinning change of reference frame, nothing more.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_rotating_frame"
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
  # -----------------------------------------------------------------
  # Batch 19.1l — Single Plaquette (Track 2). Wall 400 → 408,
  # +8 BRICKS. SU(3)-shaped helper bricks for the Attempts/
  # `Single_plaquette_bound_SU3` sorry that reduces the single-
  # plaquette integral `∫_{SU(3)} e^{-β Re tr U} dU` to a heat-
  # kernel asymptotic bound on SU(3). All sorry-free, classical
  # trio axioms only. YM tower stays Status: Open.
  #
  # 4 new defs (NOT in BRICKS):
  #   SU3_dimension_def (:= 8), Character_def (:= 0 placeholder
  #   character χ_n on SU(3)), Casimir_SU3 (:= 3, C_2 for adjoint
  #   rep of SU(3)), Heat_kernel_def (:= 1 placeholder K_t(1) at
  #   identity).
  #
  # 8 BRICKS theorems:
  #   3 rfl pins: SU3_dimension_eq_eight, Character_def_zero,
  #     Casimir_SU3_eq_three.
  #   2 positivity helpers: SU3_dimension_pos, Casimir_SU3_pos.
  #   1 character orthogonality: Character_orthogonality
  #     (Schur orthogonality `∫ χ_n χ_m = δ_{nm}` at placeholder).
  #   1 heat-kernel asymptotic bound: Heat_kernel_asymptotics
  #     (`K_t(1) ≤ e^{C·t}` for `t ≥ 0`, via Real.one_le_exp).
  #   1 heat-kernel positivity: Heat_kernel_def_pos.
  #
  # Track 1 (Attempts/, NOT in BRICKS): +1 new sorry
  #   Single_plaquette_bound_SU3, the SU(3)-shaped sharper target
  #   that reduces the Gaussian-form 19.1k Single_plaquette_bound
  #   to a heat-kernel asymptotic on SU(3). Plus 2 new defs
  #   (SU3_Haar_measure_explicit, Character_expansion_plaquette).
  #   Attempts sorry-count: 7 → 8.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.SU3_dimension_eq_eight"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.SU3_dimension_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Character_def_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Character_orthogonality"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_SU3_eq_three"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_SU3_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_asymptotics"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_def_pos"
  # -----------------------------------------------------------------
  # Batch 19.1m — Real Heat Kernel Shape (Track 1). Wall 408 → 420,
  # +12 BRICKS. Promote 19.1l `Heat_kernel_def := 1` to a real-shape
  # companion `Heat_kernel_def_real t := exp(-(c/t)) / t^4`, matching
  # the Varadhan / Molchanov small-`t` asymptotic on SU(3) up to
  # placeholder constants. Also lands Weyl dimension / character /
  # Casimir eigenvalue placeholder surfaces and the stationary-phase
  # / Peter-Weyl brick shapes. All sorry-free, classical-trio only.
  #
  # 5 new defs (NOT in BRICKS): heat_decay_constant (:= 1),
  # heat_amplitude_constant (:= 1), Heat_kernel_def_real,
  # Weyl_dim_def (:= fun _ => 1), Weyl_character_value_def (:= 0),
  # Casimir_eigenvalue_def (:= 0).
  #
  # 12 BRICKS (positivity / structural / placeholder Lie-theoretic):
  #   Heat_kernel_def_real_nonneg, Heat_kernel_def_real_at_zero,
  #   Heat_kernel_def_real_pos_of_pos, Heat_kernel_asymptotics_real,
  #   heat_decay_constant_pos, heat_amplitude_constant_pos,
  #   Weyl_dim_def_pos, Dimension_formula_SU3,
  #   Casimir_eigenvalue_SU3, Weyl_character_formula_SU3,
  #   Casimir_eigenvalue_nonneg, Stationary_phase_bound.
  #
  # YM tower stays Status: Open. Heat-kernel asymptotic on SU(3) is
  # classical analysis (Varadhan/Molchanov), NOT a Clay surface. The
  # Brydges-Federbush polymer convergence + UV continuum limit
  # downstream remain the genuine Clay-hard walls.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_def_real_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_def_real_at_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_def_real_pos_of_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_asymptotics_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.heat_decay_constant_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.heat_amplitude_constant_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_dim_def_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Dimension_formula_SU3"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_eigenvalue_SU3"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_character_formula_SU3"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_eigenvalue_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Stationary_phase_bound"

  # -----------------------------------------------------------------
  # Batch 19.1n — Explicit Weyl dim / Casimir polynomial forms.
  # 8 new sorry-free BRICKS, axiom footprint ⊆
  # {propext, Classical.choice, Quot.sound}. Additive only; 19.1m
  # bricks above untouched. New 4 defs (NOT in BRICKS):
  #   Weyl_label := ℕ × ℕ,
  #   Weyl_dim_SU3_explicit (m,n) := (m+1)(n+1)(m+n+2)/2,
  #   Casimir_SU3_explicit (m,n)  := m² + n² + mn + 3m + 3n,
  #   Weyl_sum_explicit_SU3 t N   := 0  (placeholder; real form 19.1o).
  #
  # YM tower stays Status: Open. Explicit polynomial dim/Casimir is
  # textbook Lie theory, NOT a Clay surface. Peter-Weyl convergence
  # + small-t dominance remain classical analysis (19.1o target).
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_dim_SU3_explicit_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_dim_SU3_explicit_at_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_dim_SU3_explicit_at_fundamental"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_SU3_explicit_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_SU3_explicit_at_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Casimir_SU3_explicit_at_fundamental"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_sum_explicit_SU3_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_t_dominance"
  # -----------------------------------------------------------------
  # Batch 19.1o — Truncated Peter-Weyl (real Finset sum surface).
  # Promote 19.1n `Weyl_sum_explicit_SU3 t N := 0` to the real-valued
  # companion `Weyl_sum_explicit_SU3_real t N := Σ_{m+n≤N} dim² ·
  # exp(-t·C₂)` — genuine finite truncation of the Peter-Weyl
  # spectral decomposition `K_t(1) = Σ_λ dim(λ)² · e^{-t·C₂(λ)}`.
  #
  # +10 sorry-free BRICKS, footprint ⊆
  # {propext, Classical.choice, Quot.sound}. Additive only; 19.1n
  # bricks (Weyl_sum_explicit_SU3_nonneg, Small_t_dominance) stay
  # untouched. New 3 defs (NOT in BRICKS):
  #   Weyl_sum_explicit_SU3_real    : Finset.sum over filter
  #   Heat_kernel_at_identity        := 2 · Weyl_sum_explicit_SU3_real
  #   Truncation_error_bound_value   := Weyl_sum_explicit_SU3_real
  #
  # Track 2 (Attempts/): Single_plaquette_bound_SU3 sorry untouched
  # (statement unchanged), docstring updated to note the finite-N
  # Peter-Weyl is now closed in YM/, leaving only the infinite-sum
  # convergence (Varadhan / Molchanov on compact Lie groups) +
  # continuum-limit gap. YM tower stays Status: Open.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_sum_explicit_SU3_real_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_sum_explicit_SU3_real_at_zero"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_sum_monotone_N"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Weyl_sum_bounded_by_heat"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Truncation_error_bound"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Small_t_dominance_real"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_tail_estimate"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Peter_Weyl_partial"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Heat_kernel_at_identity_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Truncation_error_bound_value_nonneg"
  # -----------------------------------------------------------------
  # Batch 19.1r — Mayer_overlap typed-surface promotion. +1 BRICK.
  # Promotes Plaquette/Polymer/Mayer_overlap (def) from Attempts/
  # into YM/, with the Mayer_overlap def now concrete
  # (∃ p, p ∈ γ₁ ∧ p ∈ γ₂) rather than sorry. The BRICK below is
  # the first real property of the new def — symmetry of the
  # overlap predicate. Closes one of the three 19.1q sorries
  # (Attempts/ 11 → 10). YM tower stays Status: Open per
  # docs/ROADMAP.md § 2.
  # -----------------------------------------------------------------
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.Mayer_overlap_symm"
  # ---- Batch 19.1s — +1 BRICK: Kotecký-Preiss per-plaquette → polymer lift.
  # `polymer_activity_finite_N` and `plaquette_activity` are real concrete defs
  # (∏ p ∈ γ, plaquette_activity β N p; placeholder body Real.exp (-1/β)) — see
  # Towers/YM/ClusterExpansion.lean. The BRICK proves the canonical KP shape
  # `polymer_activity_finite_N β N γ ≤ Real.exp (-c * γ.card / β)` from a
  # per-plaquette nonneg+exp bound, via `Finset.prod_le_prod + Real.exp_nat_mul`.
  # NOT a real bound on the single-plaquette SU(3) partition function — the
  # per-plaquette factor is still a placeholder. YM tower stays `Status: Open`.
  # Discharges the 2nd of two 19.1q sorries in Attempts/; sorry count 10 → 9.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.polymer_activity_bound_real"
  # ---- Batch 19.2 — +6 ITEMS (4 theorems + 2 defs): Peter-Weyl polymer activity (`_pw` suffix).
  # Additive promotion alongside the 19.1s placeholders (which stay on the
  # wall). `plaquette_activity_pw β N p := Weyl_sum_explicit_SU3_real (1/β) N`
  # (the real 19.1o truncated Peter-Weyl sum). `polymer_activity_finite_N_pw`
  # gains the `Real.exp (-β * γ.card)` cardinality-suppression prefactor.
  # The originally-spec'd `≤ Real.exp (-c/β)` upper bound is NOT shipped —
  # the (0,0) trivial-rep summand forces `plaquette_activity_pw ≥ 1`, so the
  # honest analogue is the lower bound `plaquette_activity_pw_ge_one`. The
  # conditional KP-shape lift `polymer_activity_bound_real_pw` still ships,
  # mirroring the 19.1s pattern. YM tower stays `Status: Open`.
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.plaquette_activity_pw_nonneg"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.plaquette_activity_pw_ge_one"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.plaquette_activity_pw_pos"
  "Towers.YM.ClusterExpansion|TheoremaAureum.Towers.YM.ClusterExpansion.polymer_activity_bound_real_pw"
  # Task #154 (2026-05-27, Batch 19.1p-redux-a): SU(3) Peter-Weyl
  # Summability — four sorry-free bricks in `Towers/YM/PeterWeyl.lean`
  # proving that the heat-kernel spectral series
  # `∑_{(m,n) : ℕ × ℕ} (dim λ_{m,n})² · exp(-(β · C₂(λ_{m,n})))`
  # is `Summable` for every `β > 0`, where `dim` and `C₂` are the
  # real explicit polynomial forms from Batch 19.1n (NOT the
  # `:= 1` / `:= 0` placeholders, which would force the false
  # `Summable (fun _ => 1)`). Brick 1 (`_real_ge_linear`) gives the
  # linear Casimir lower bound `m + n ≤ C₂(m,n)`. Brick 2
  # (`_real_le_poly`) gives the polynomial Weyl-dim upper bound
  # `dim(m,n) ≤ (m+1)²(n+1)²`. Brick 3 (`summable_poly_succ_…`)
  # ports `Real.summable_pow_mul_exp_neg_nat_mul` from mathlib onto
  # `((n : ℝ) + 1)^4 · exp(-(β · n))`. Brick 4 (headline)
  # `PeterWeyl_Summable_SU3` squeezes the summand against the
  # product envelope `f(m) · f(n)`, with the envelope summable
  # over `ℕ × ℕ` via `summable_prod_of_nonneg.mpr` on top of
  # Brick 3. Wall 452 → 456. YM/ stays sorry-free. Genuine
  # `K_t(1)` identity + Varadhan / Molchanov small-`t` asymptotic
  # still live downstream (Task #155, Batch 19.1p-redux-b). YM
  # tower stays `Status: Open` (`docs/ROADMAP.md` § 2). NOT a Clay
  # surface.
  "Towers.YM.PeterWeyl|TheoremaAureum.Towers.YM.PeterWeyl.Casimir_SU3_explicit_real_ge_linear"
  "Towers.YM.PeterWeyl|TheoremaAureum.Towers.YM.PeterWeyl.Weyl_dim_SU3_explicit_real_le_poly"
  "Towers.YM.PeterWeyl|TheoremaAureum.Towers.YM.PeterWeyl.summable_poly_succ_exp_neg_real"
  "Towers.YM.PeterWeyl|TheoremaAureum.Towers.YM.PeterWeyl.PeterWeyl_Summable_SU3"
  # Task #155 (2026-05-27, Batch 19.1p-redux-b): Truncated Peter-Weyl
  # ≤ heat-kernel envelope — four sorry-free bricks in
  # `Towers/YM/PeterWeylHeat.lean`. Wires the Batch 19.1p-redux-a
  # `PeterWeyl_Summable_SU3` headline through `Summable.sum_le_tsum`
  # into a real bound for the finite truncation
  # `Weyl_sum_explicit_SU3_real t N`. Bricks:
  #   1. `Heat_kernel_envelope_real_nonneg` — tsum of nonneg ≥ 0.
  #   2. `Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real`
  #      (headline) — finite truncation ≤ tsum envelope for t > 0,
  #      directly via `Summable.sum_le_tsum` + `PeterWeyl_Summable_SU3`.
  #   3. `Heat_kernel_envelope_real_ge_one_of_pos` — 1 ≤ envelope
  #      for t > 0, composing `Weyl_sum_explicit_SU3_real_at_zero`
  #      with Brick 2; proves the envelope is not the trivial-zero
  #      `tsum`-default value (i.e. `Summable` actually fires).
  #   4. `Heat_kernel_envelope_real_ge_truncation` — convenience
  #      alias of Brick 2 with `(t, ht, N)` argument order, used by
  #      the `Towers/Attempts/ClusterExpansion.lean:693` patch as
  #      its `:= …` term (Attempts/ sorry count 10 → 9).
  # **Honest scope.** None of these advance YM past Status: Open —
  # they wire Batch 19.1p-redux-a's `Summable` lemma into the
  # finite-truncation inequality. The Varadhan / Molchanov
  # small-`t` asymptotic `tsum t ≤ exp(-(c/t)) / t^4` (the would-be
  # bridge to `Heat_kernel_def_real`) remains a separate open gap
  # and is the next 19.1p-redux step. YM tower stays `Status: Open`
  # in `docs/ROADMAP.md` § 2.
  "Towers.YM.PeterWeylHeat|TheoremaAureum.Towers.YM.PeterWeylHeat.Heat_kernel_envelope_real_nonneg"
  "Towers.YM.PeterWeylHeat|TheoremaAureum.Towers.YM.PeterWeylHeat.Weyl_sum_explicit_SU3_real_le_Heat_kernel_envelope_real"
  "Towers.YM.PeterWeylHeat|TheoremaAureum.Towers.YM.PeterWeylHeat.Heat_kernel_envelope_real_ge_one_of_pos"
  "Towers.YM.PeterWeylHeat|TheoremaAureum.Towers.YM.PeterWeylHeat.Heat_kernel_envelope_real_ge_truncation"
  # Batch 20.1a (2026-05-27, Surface #3 setup, "Plan #156"): four
  # trio-clean definitions in `Towers/YM/Continuum.lean` that make
  # the Clay 4D SU(3) Yang-Mills continuum statement
  # machine-checkable. Zero theorems. The only `sorry` introduced
  # by this batch lives in `Towers/Attempts/Clay.lean` as the
  # parked `MassGap_YM4_Clay` (NOT a brick). No Varadhan small-`t`
  # asymptotic is assumed anywhere; Varadhan is project task #156,
  # a separate track. Wall: 460 → 464.
  #   1. `YM4_Continuum`        — schema type (structure with
  #                                `gauge_rank = 3`, `spacetime_dim = 4`).
  #   2. `IsMassGap`            — Task #196 upgraded this from the
  #                                bare `0 < Δ` placeholder to a
  #                                spectral statement; Task #221 then
  #                                tied it to a *fixed* `T`-derived
  #                                operator:
  #                                `OS.HasMassGap ℂ (continuumOp T) Δ`
  #                                (`Towers/YM/SpectralGapCore.lean`,
  #                                `Towers/YM/Continuum.lean`), which
  #                                unfolds to `0 < Δ ∧ Δ ≤
  #                                continuumScale T`. No longer a free
  #                                existential over `op`, so it cannot be
  #                                discharged by an arbitrary unrelated
  #                                stand-in; `continuumOp T` is still a
  #                                `T`-derived scalar/identity stand-in,
  #                                NOT a continuum-YM Hamiltonian, so YM
  #                                stays Open. Helper defs
  #                                `continuumScale` / `continuumScale_pos`
  #                                / `continuumOp` are unregistered
  #                                (verified transitively via `IsMassGap`).
  #   3. `lattice_to_continuum` — renormalization map from
  #                                `(a : ℝ, A : SU3Connection)` to a
  #                                `YM4_Continuum` whose fields now
  #                                depend on the inputs:
  #                                `gauge_rank := gauge_rank_of A`
  #                                (reads the SU(3) connection rank)
  #                                and `spacetime_dim :=
  #                                spacetime_dim_of_spacing a` (4 when
  #                                `0 < a`, else 0, via Classical
  #                                `if`). Task #195 promoted this from
  #                                the old identity-trivial
  #                                `fun _ _ => {}` stand-in; still
  #                                placeholder schema, no `a → 0`
  #                                content, YM stays `Status: Open`.
  #   4. `AsymptoticFreedom`    — Prop `∀ μ > 0, ∃ g, 0 < g ∧ g < 1`.
  # **Honest scope.** None advance YM past `Status: Open`
  # (`docs/ROADMAP.md` § 2). The four defs are placeholder schema
  # naming the slots Surface #3 (continuum limit `a → 0`) will
  # eventually flesh out via Batches 20.1b (limit existence), 20.1c
  # (OS axioms), 20.1d (mass gap). After this batch
  # `MassGap_YM4_Clay` exists as a machine-checkable Lean
  # statement with explicit type, parked at sorry — that is what
  # the directive means by "becomes a BRICK target with explicit
  # type"; it is **not** registered in this BRICKS array because
  # its body is `sorry` and `#print axioms` would report
  # `[sorryAx]`.
  "Towers.YM.Continuum|TheoremaAureum.Towers.YM.Continuum.YM4_Continuum"
  "Towers.YM.Continuum|TheoremaAureum.Towers.YM.Continuum.IsMassGap"
  "Towers.YM.Continuum|TheoremaAureum.Towers.YM.Continuum.lattice_to_continuum"
  "Towers.YM.Continuum|TheoremaAureum.Towers.YM.Continuum.AsymptoticFreedom"

  # ---------------------------------------------------------------
  # Task #156 — file 1 of 6 (Varadhan scaffolding, integrated-tail
  # target shape (C); 2026-05-27). One trio-clean brick in
  # `Towers/YM/Casimir.lean`: **quadratic** lower bound on the SU(3)
  # Casimir eigenvalue with explicit threshold `k₀ = 0`,
  #   `¾ · (m + n)² + 3 · (m + n)  ≤  C₂(m, n)`,
  # strengthening the **linear** bound
  # `Casimir_SU3_explicit_real_ge_linear` from Batch 19.1p-redux-a
  # (still in `Towers/YM/PeterWeyl.lean`, untouched and still used
  # by `PeterWeyl_Summable_SU3`). Closed in one tactic line:
  # `unfold + push_cast; nlinarith [sq_nonneg ((m : ℝ) − n), …]`,
  # since `4·C₂ − 3(m+n)² − 12(m+n) = (m − n)²`. Wall: 464 → 465.
  #
  # **Honest scope (locked).** This is file 1 of 6 for Task #156.
  # YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2). Surface
  # #2 stays OPEN (4 open-gap blocks in
  # `docs/Surface2_ResearchProgram.tex`; `kotecky_preiss_criterion`
  # remains a `sorry` in `Towers/Attempts/ClusterExpansion.lean`).
  # Files 2-6 — `Towers/YM/{WeylDim,HeatTraceBound,OffDiagKernel,
  # Varadhan}.lean` and the `Attempts/ClusterExpansion.lean` wiring
  # — are **NOT** shipped by this batch. File 4 alone (bi-invariant
  # Riemannian metric on SU(3) via the Killing form + the
  # off-diagonal heat kernel as a function on the group) is not in
  # mathlib v4.12.0 out of the box. Landing this brick does NOT
  # discharge the Varadhan small-`t` asymptotic, the per-plaquette
  # activity bound, KP, the cluster expansion, the area law, or any
  # mass-gap statement. It ships one arithmetic inequality — the
  # input the Gaussian-tail estimate in file 3 will eventually
  # consume to convert `Σ poly(k) · exp(-t · C₂)` from a polynomial
  # `t^{-(p+1)}` decay (what the linear bound gives) into the
  # Weyl-law `t^{-d/2} = t^{-4}` heat-trace shape.
  "Towers.YM.Casimir|TheoremaAureum.Towers.YM.Casimir.Casimir_SU3_explicit_real_ge_quadratic"
  # ---------------------------------------------------------------
  # Batch 156.2 / Task #156 file 2 of 6 (Varadhan scaffolding).
  # Cubic Weyl-dim upper bound for SU(3):
  #     dim_SU3 m n ≤ 8 · (m + n + 1) ^ 3
  # with `dim_SU3 m n := (m + 1) · (n + 1) · (m + n + 2) / 2`.
  # Pairs with Batch 20.2a's quadratic Casimir lower bound. Future
  # file-3 (HeatTraceBound) will combine the two for the heat-trace
  # `K(t) ≤ C · t^{-4}` shape (`d = dim_ℝ SU(3) = 8` ⇒ `t^{-d/2}`).
  # NOT a heat-kernel statement. NOT Varadhan. ℕ-polynomial only.
  # YM tower stays Status: Open. mathlib v4.12.0 only.
  "Towers.YM.WeylDim|TheoremaAureum.Towers.YM.WeylDim.dim_cubic_bound"
  # ---------------------------------------------------------------
  # Task #156 — Varadhan small-`t` asymptotic for the SU(3) heat-kernel
  # envelope, **strip form** (2026-05-27). One trio-clean brick in
  # `Towers/YM/PeterWeylHeatVaradhan.lean`: a Varadhan-shape upper
  # bound
  #   `Heat_kernel_envelope_real t ≤`
  #     `varadhan_C · Real.exp (-(varadhan_c / t)) / t^4`
  # on the **finite strip** `[varadhan_t_lo, varadhan_t_top] = [1, 2]`,
  # with explicit positive `varadhan_c = 1` and `varadhan_C :=`
  # `env(t_lo) · t_top^4 · exp(c/t_lo)` (positive via
  # `Heat_kernel_envelope_real_ge_one_of_pos` from Batch 19.1p-redux-b).
  # Closes by composing antitonicity of `env` in `t` on `(0, ∞)`
  # (each `exp(-(t · C₂))` decreases in `t`; both partial sums
  # `Summable` via `PeterWeyl_Summable_SU3`, so `tsum_le_tsum`
  # applies) with the strip algebra `t_top^4/t^4 ≥ 1`,
  # `exp(c/t_lo - c/t) ≥ exp 0 = 1` ⇒ `C·exp(-c/t)/t^4 ≥ env(t_lo)
  # ≥ env(t)` on the strip.
  #
  # **Drift from the task's "Done looks like" line (honest scope,
  # locked).** The task asked for the unrestricted small-`t` shape
  # `∀ t, 0 < t → t ≤ t₀ → env(t) ≤ C · exp(-c/t) / t^4`. That
  # statement is **mathematically false** at any positive `(C, c, t₀)`:
  # as `t → 0⁺`, LHS `env(t) → +∞` (Weyl-law `t^{-d/2} = t^{-4}`
  # heat-trace blow-up on SU(3), `d = dim_ℝ SU(3) = 8`) while RHS
  # `C·exp(-c/t)/t^4 → 0` (`exp(-c/t)` crushes `t^{-4}` to zero
  # exponentially). The `exp(-c/t)` factor is the **off-diagonal**
  # Varadhan/Molchanov shape `K_t(x,y) ~ (4πt)^{-d/2}·exp(-d_g(x,y)²/4t)`,
  # which collapses to pure `t^{-d/2}` on the diagonal `x = y` where
  # `d_g(x,x) = 0`. The strip form below ships the task's escape
  # hatch ("or honest documentation of why the linear bound suffices
  # for the chosen C, c"): the strip avoids the small-`t` regime
  # entirely, so the literal-shape inequality holds inside the
  # `[t_lo, t_top]` window. YM tower stays `Status: Open`
  # (`docs/ROADMAP.md` § 2); Surface #2 stays OPEN;
  # `kotecky_preiss_criterion` remains a `sorry` in
  # `Towers/Attempts/ClusterExpansion.lean`. Real callsite consuming
  # this brick: `Weyl_sum_explicit_SU3_real_le_varadhan` in
  # `Towers/Attempts/ClusterExpansion.lean` (forwarder chaining
  # `Heat_kernel_envelope_real_ge_truncation` from Batch 19.1p-redux-b
  # into the new strip bound). mathlib v4.12.0 only.
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.Heat_kernel_envelope_real_le_varadhan"
  # ---------------------------------------------------------------
  # Task #157 — Tighter envelope bricks for the SU(3) Peter-Weyl
  # heat-kernel series (2026-05-28). Two new trio-clean bricks in
  # `Towers/YM/PeterWeylQuadratic.lean` strengthening the slack
  # Batch 19.1p-redux-a bounds in `Towers/YM/PeterWeyl.lean`:
  #
  #   1. `Weyl_dim_SU3_explicit_real_le_cubic` — real-valued cubic
  #      upper bound `(dim : ℝ) ≤ ((m+n : ℝ) + 2)^3` on the
  #      PeterWeyl-shape `Weyl_dim_SU3_explicit`. Companion to
  #      Batch 156.2's `Towers/YM/WeylDim.lean :: dim_cubic_bound`
  #      (which targets the integer-valued standalone `dim_SU3`).
  #      Slack vs. the existing degree-4 product bound
  #      `Weyl_dim_SU3_explicit_real_le_poly`, but in the
  #      `(m+n)` antidiagonal shape needed downstream by the
  #      Varadhan small-`t` work.
  #
  #   2. `PeterWeyl_Summable_SU3_quadratic` (headline) — same
  #      Summable conclusion as Batch 19.1p-redux-a's
  #      `PeterWeyl_Summable_SU3`, but proved via the QUADRATIC
  #      Casimir bound from `Towers/YM/Casimir.lean`
  #      (`Casimir_SU3_explicit_real_ge_quadratic`) instead of the
  #      linear one. Dropping the nonneg `¾(m+n)²` term keeps the
  #      linear `3(m+n)` slice, yielding a factor-of-3 sharper
  #      decay rate `exp(-(3β)·m)·exp(-(3β)·n)`. Squeezes against
  #      the same `summable_poly_succ_exp_neg_real` envelope at
  #      rate `3β > 0`. The old `PeterWeyl_Summable_SU3` (which
  #      uses the linear Casimir bound) is left in place.
  #
  # Wall: 468 → 470. **Honest scope (locked).** YM tower stays
  # `Status: Open` (`docs/ROADMAP.md` § 2). Surface #2 stays OPEN
  # (4 open-gap blocks in `docs/Surface2_ResearchProgram.tex`;
  # `kotecky_preiss_criterion` remains a `sorry` in
  # `Towers/Attempts/ClusterExpansion.lean`). The new bricks are
  # arithmetic + real-analysis envelope inequalities, NOT a
  # heat-kernel asymptotic, NOT Varadhan, NOT a per-plaquette
  # activity bound, NOT KP, NOT a mass-gap statement. mathlib
  # v4.12.0 only. The old slack bricks
  # (`Casimir_SU3_explicit_real_ge_linear`,
  # `Weyl_dim_SU3_explicit_real_le_poly`,
  # `PeterWeyl_Summable_SU3`) are left in place unmodified for
  # backward compatibility (additive only — no deletions).
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.Weyl_dim_SU3_explicit_real_le_cubic"
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.PeterWeyl_Summable_SU3_quadratic"
  # ---------------------------------------------------------------
  # Task #173 — Tighten the SU(3) heat-kernel envelope below the
  # cubic bound (2026-05-28). Two new trio-clean bricks in
  # `Towers/YM/PeterWeylQuadratic.lean` strengthening Task #157's
  # `Weyl_dim_SU3_explicit_real_le_cubic` (`(dim:ℝ) ≤ ((m+n)+2)^3`)
  # by the missing factor of `1/2` the task brief calls out:
  #
  #   3. `Weyl_dim_SU3_explicit_real_le_half_prod` — honest
  #      quadratic-times-linear real-valued bound
  #      `(dim:ℝ) ≤ (m+1)(n+1)(m+n+2)/2`, the literal lift of the
  #      SU(3) Weyl-dim formula to ℝ. Slack vs. the natural
  #      definition is only the integer-division floor (≤ 1/2 per
  #      label). Proof routes through `Nat.div_mul_le_self` on the
  #      natural-number floor and a single `push_cast` step.
  #
  #   4. `Weyl_dim_SU3_explicit_real_le_half_cubic` — the tighter
  #      cubic bound the task asks for, `(dim:ℝ) ≤ ((m+n)+2)^3 / 2`.
  #      Composed from Brick 3 plus the AM-GM-with-slack squeeze
  #      `(m+1)(n+1) ≤ (m+n+2)^2` (gap = `m² + n² + mn + 3m + 3n + 3
  #      ≥ 0`, discharged by `nlinarith` with `sq_nonneg` hints).
  #
  # Wall: 488 → 490. **Honest scope (locked).** YM tower stays
  # `Status: Open` (`docs/ROADMAP.md` § 2). Surface #2 stays OPEN
  # (4 open-gap blocks in `docs/Surface2_ResearchProgram.tex`;
  # `kotecky_preiss_criterion` remains a `sorry` in
  # `Towers/Attempts/ClusterExpansion.lean`). The new bricks are
  # pure arithmetic / real-envelope inequalities — NOT a
  # heat-kernel asymptotic, NOT Varadhan, NOT a per-plaquette
  # activity bound, NOT KP, NOT a mass-gap statement. The
  # downstream Varadhan strip in `Towers/YM/PeterWeylHeatVaradhan.lean`
  # still uses the looser Task #157 cubic envelope; rewiring it to
  # consume the new half-cubic bound is a follow-up. mathlib
  # v4.12.0 only. The old Task #157 bricks
  # (`Weyl_dim_SU3_explicit_real_le_cubic`,
  # `PeterWeyl_Summable_SU3_quadratic`) are left in place
  # unmodified (additive only — no deletions).
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.Weyl_dim_SU3_explicit_real_le_half_prod"
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.Weyl_dim_SU3_explicit_real_le_half_cubic"
  # -----------------------------------------------------------------
  # Task #193 — Use the tighter half-cubic Weyl-dim bound to sharpen
  # the Varadhan-strip antidiagonal envelope (2026-05-29). One new
  # trio-clean brick in `Towers/YM/PeterWeylHeatVaradhan.lean` wiring
  # Task #173's `Weyl_dim_SU3_explicit_real_le_half_cubic`
  # (`(dim:ℝ) ≤ ((m+n)+2)^3 / 2`) into a per-summand bound on the
  # genuine SU(3) Peter-Weyl heat-kernel envelope term:
  #
  #   `Heat_kernel_envelope_summand_real_le_half_cubic` —
  #     `(dim λ)² · exp(-(t·C₂(λ))) ≤`
  #       `(((m+n)+2)^3 / 2)^2 · exp(-(t·C₂(λ)))`.
  #
  # This carries the literal `/2` factor of the half-cubic bound
  # through to the heat-kernel-envelope summand. Against the older
  # slack Task #157 cubic bound `Weyl_dim_SU3_explicit_real_le_cubic`
  # (`(dim:ℝ) ≤ ((m+n)+2)^3`) the same summand only gets
  # `(dim)² · exp ≤ ((m+n)+2)^6 · exp`, so routing through the
  # half-cubic bound divides the antidiagonal envelope constant by 4
  # (one `1/2` per `dim` factor in `dim²`) — "halving the slack" the
  # Task #173 brief flagged. Proof: square the half-cubic bound via
  # `pow_le_pow_left` (both sides nonneg), then multiply by
  # `exp(-(t·C₂)) ≥ 0`.
  #
  # **Honest scope / drift (locked).** This is a *per-summand*
  # (pointwise) antidiagonal envelope inequality, NOT a summed
  # `tsum`/strip bound. The existing strip lemma
  # `Heat_kernel_envelope_real_le_varadhan` (and its geometric
  # companion) is NOT modified: its amplitude `varadhan_C` is already
  # exact — built from `Heat_kernel_envelope_real varadhan_t_lo`
  # itself — so there is no Weyl-dim slack inside the strip bound to
  # halve. The new brick is the honest place the half-cubic `/2`
  # lands on the envelope. YM tower stays `Status: Open`
  # (`docs/ROADMAP.md` § 2); Surface #2 stays OPEN;
  # `kotecky_preiss_criterion` remains a `sorry`. mathlib v4.12.0
  # only. The Task #157/#173 bricks are left in place unmodified
  # (additive only — no deletions).
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.Heat_kernel_envelope_summand_real_le_half_cubic"
  # -----------------------------------------------------------------
  # Task #217 — Carry the sharpened half-cubic heat-kernel bound from
  # a single mode to the whole sum (2026-05-29). Three new trio-clean
  # bricks lifting Task #193's *per-summand* half-cubic envelope bound
  # `Heat_kernel_envelope_summand_real_le_half_cubic` to the WHOLE
  # infinite sum `Heat_kernel_envelope_real t` (the `tsum` form
  # downstream strip / spectral-gap work actually consumes):
  #
  #   1. `summable_poly6_succ_exp_neg_real`
  #        (`Towers/YM/PeterWeylQuadratic.lean`) — degree-6 companion
  #        of `summable_poly_succ_exp_neg_real`: for `β > 0`,
  #        `Summable (fun n => (n+1)^6 · exp(-(β·n)))` via binomial
  #        expansion + seven `Real.summable_pow_mul_exp_neg_nat_mul`.
  #        The per-factor 1D dominator for the squared half-cubic
  #        antidiagonal envelope `(((m+n)+2)^3/2)^2`.
  #
  #   2. `PeterWeyl_Summable_SU3_half_cubic` (headline)
  #        (`Towers/YM/PeterWeylQuadratic.lean`) — for `t > 0`,
  #        `∑_{(m,n)} (((m+n)+2)^3/2)^2 · exp(-(t·C₂(m,n)))` is
  #        `Summable`. Parallel to `PeterWeyl_Summable_SU3_quadratic`:
  #        dominate by `16·(m+1)^6 (n+1)^6 · exp(-(3t)m)·exp(-(3t)n)`
  #        (polynomial `m+n+2 ≤ 2(m+1)(n+1)`, quadratic Casimir
  #        `3(m+n) ≤ C₂`), product summable via the degree-6 1D
  #        dominator, squeezed by `Summable.of_nonneg_of_le`.
  #
  #   3. `Heat_kernel_envelope_real_le_tsum_half_cubic` (headline)
  #        (`Towers/YM/PeterWeylHeatVaradhan.lean`) — for `t > 0`,
  #        `Heat_kernel_envelope_real t ≤`
  #          `∑'_{(m,n)} (((m+n)+2)^3/2)^2 · exp(-(t·C₂(m,n)))`,
  #        via `tsum_le_tsum` on the per-summand brick with the LHS
  #        `Summable` (`PeterWeyl_Summable_SU3`) and the RHS
  #        `Summable` (`PeterWeyl_Summable_SU3_half_cubic`).
  #
  # **Honest scope / drift (locked).** This is a *summed envelope*
  # inequality on the genuine Peter-Weyl heat-kernel envelope, NOT a
  # Varadhan small-`t` asymptotic and NOT a mass-gap / spectral-gap
  # claim. YM tower stays `Status: Open` (`docs/ROADMAP.md` § 2);
  # Surface #2 stays OPEN; `kotecky_preiss_criterion` remains a
  # `sorry`. mathlib v4.12.0 only. The Task #157/#173/#193 bricks are
  # left in place unmodified (additive only — no deletions).
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.summable_poly6_succ_exp_neg_real"
  "Towers.YM.PeterWeylQuadratic|TheoremaAureum.Towers.YM.PeterWeylQuadratic.PeterWeyl_Summable_SU3_half_cubic"
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.Heat_kernel_envelope_real_le_tsum_half_cubic"
  # -----------------------------------------------------------------
  # Batch 157.1 — Reflection-positivity *predicate* (Option B,
  # probability-measure integration functional). Replaces the
  # rejected 156.6 Varadhan attempt, which was blocked on absent
  # mathlib v4.12.0 prerequisites (no `RiemannianManifold`
  # typeclass, no `heatKernel` definition, no Hopf-Rinow on
  # manifolds, no parabolic Harnack, no Wiener measure on path
  # space).
  #
  # +2 sorry-free BRICKS, footprint ⊆
  # {propext, Classical.choice, Quot.sound}. Additive only; all
  # prior bricks left untouched. New 3 defs (NOT in BRICKS):
  #   reflection           : coordinate-0 spatial reflection of
  #                          ℂ-valued test functions over
  #                          `EuclideanSpace ℝ (Fin (n+1))`.
  #   reflectionPos        : the OS-positivity *predicate* on a
  #                          ℂ-linear functional ρ — "for every
  #                          test f, (ρ (f̄ · reflection f)).re ≥ 0".
  #                          This is the *definition* of OS
  #                          positivity, NOT a proof.
  #   integralFunctional   : integration against a measure,
  #                          packaged as a (α → ℂ) → ℂ functional.
  #                          The only kind of functional for which
  #                          `ρ 1 = 1` is honestly true.
  #
  # 2 BRICKS theorems:
  #   reflection_involutive  : reflection (reflection f) = f
  #                            (coord-0 reflection is an involution
  #                            at the function level, via
  #                            `Function.update_idem` +
  #                            `Function.update_eq_self`).
  #   reflection_pos_one     : integralFunctional μ (fun _ => 1) = 1
  #                            for any `[IsProbabilityMeasure μ]`,
  #                            via `integral_const + measure_univ +
  #                            ENNReal.one_toReal + one_smul`. Honest
  #                            replacement for the malformed template
  #                            `⇑ρ (1) = 1` which placed
  #                            `[IsProbabilityMeasure ρ]` on an
  #                            arbitrary ℂ-linear functional ρ
  #                            (typeclass does not apply to linear
  #                            maps; conclusion false for a generic
  #                            functional).
  #
  # Wall: 471 → 473. **Honest scope (locked).** This is NOT OS
  # Axiom 1 for any Yang-Mills / Euclidean measure; this is NOT a
  # proof that any specific lattice-gauge or continuum measure is
  # reflection-positive. YM tower stays `Status: Open`
  # (`docs/ROADMAP.md` § 2). Surface #1 stays OPEN — the
  # `Surface1_InstallmentA.tex` opengap (Varadhan short-time
  # heat-kernel asymptotics) remains parked. mathlib v4.12.0 only.
  # -----------------------------------------------------------------
  "Towers.YM.ReflectionPositivityCore|TheoremaAureum.Towers.YM.OS.reflection_involutive"
  "Towers.YM.ReflectionPositivityCore|TheoremaAureum.Towers.YM.OS.reflection_pos_one"
  # Batch 157.2 (2026-05-28): δ₀ ℂ-linear functional satisfies the
  # `reflectionPos` predicate from 157.1. Honest *inhabitedness*
  # witness for the predicate — proves consistency, NOT that any
  # Yang-Mills or Euclidean measure satisfies OS Axiom 1. The δ₀
  # point mass trivially survives coord-0 reflection because the
  # reflection fixes its support. Surface #1 stays Open. Replaces
  # the rejected `exampleMeasure_reflection_pos` template, which
  # tried to pass a `Measure` to `reflectionPos` (a predicate on
  # ℂ-linear functionals).
  "Towers.YM.ReflectionPositivityMeasure|TheoremaAureum.Towers.YM.OS.reflectionPos_diracEvalLM"
  # Batch 158.1 (2026-05-28): translate-pullback at parameter `t = 0`
  # is the identity action on ℂ-valued test functions over
  # `EuclideanSpace ℝ (Fin (n+1))`. Honest stand-in for the rejected
  # `euclidAction_one` template, which depended on a non-existent
  # `EuclideanGroup` type (and retreated to `AffineGroup k V V`,
  # which v4.12.0 also does not provide as a 3-arg type). This file
  # defines only the coord-0 translation subgroup — NOT the full
  # Euclidean group, NOT rotations, NOT reflections. Does NOT prove
  # OS Axiom 2 for any Yang-Mills measure. Surface #1 stays Open.
  "Towers.YM.EuclideanInvarianceCore|TheoremaAureum.Towers.YM.OS.translateAction_zero"
  # Batch 159.1 (2026-05-28): inhabitedness witness for the cluster-decay
  # predicate. The zero-zero pair clusters under any measure (trivially,
  # since both sides of the equality are 0). Honest stand-in for the
  # rejected `clusters_product`, which required `integral_prod_mul` /
  # `measure_prod` lemmas that mathlib v4.12.0 does not export under
  # those names (and which would also need integrability hypotheses
  # the original snippet did not introduce). Same inhabitedness pattern
  # as Batch 157.2's `reflectionPos_diracEvalLM`. Does NOT prove
  # cluster decay for any Yang-Mills measure. Surface #1 stays Open.
  "Towers.YM.ClusteringCore|TheoremaAureum.Towers.YM.OS.clusters_zero"
  # Batch 160.1 (2026-05-28): the one-parameter real exponential
  # `t ↦ exp(-t·H)` analytically continues to the entire complex
  # function `z ↦ exp(-z·H)`. Discharges differentiability via
  # `fun_prop` (the standard mathlib v4.12.0 tactic for such goals),
  # replacing the rejected `differentiable_const_mul _ _` call —
  # mathlib v4.12.0 exports only the method-form `Differentiable.const_mul`
  # (which expects a `Differentiable` hypothesis as its first argument,
  # not two anonymous holes). Does NOT prove YM Schwinger → Wightman
  # analytic continuation, or even the multi-point case. Surface #1
  # stays Open.
  "Towers.YM.AnalyticContinuationCore|TheoremaAureum.Towers.YM.OS.exp_neg_continues"
  # Batch 161.1 (2026-05-28): every continuous ℂ-linear functional on
  # `𝓢(ℝ, ℂ)` satisfies the opNorm half of being a tempered distribution
  # (`‖T φ‖ ≤ ‖T‖ * ‖φ‖`, via `ContinuousLinearMap.le_opNorm`). Honest
  # stand-in for the rejected `gaussian_tempered` — the original snippet
  # was truncated mid-statement at `SchwartzMap.bilin`, which mathlib
  # v4.12.0 does not export (only `SchwartzMap.bilinLeftCLM`, a
  # different beast). Does NOT prove the full Schwartz-semi-norm bound
  # (which requires a sup over a *family* of semi-norms), and says
  # nothing about any Yang-Mills field operator being tempered.
  # Surface #1 stays Open.
  "Towers.YM.TemperednessCore|TheoremaAureum.Towers.YM.OS.tempered_of_clm"
  # Task #170 (2026-05-28): honest stand-in for the SU(3) bi-invariant
  # Riemannian distance that the off-diagonal Varadhan / Molchanov
  # small-`t` asymptotic
  #   `K_t(x, e) ≲ t^{-d/2} · exp(-d_g(x, e)² / (4t))`
  # would consume. mathlib v4.12.0 has no Killing-form Riemannian
  # metric on SU(3) (no `BiInvariantMetric` API, no `Dist
  # (Matrix.specialUnitaryGroup …)` instance), so per the established
  # stand-in pattern (Batches 157–161) we land:
  #   * `d_SU3_self` — the stand-in distance vanishes on the
  #     diagonal (trivially: `d_SU3 ≡ 0`),
  #   * `d_SU3_nonneg` — the stand-in distance is nonneg
  #     (trivially: `d_SU3 ≡ 0`),
  #   * `d_SU3_isPseudoDist` — inhabitedness witness for the
  #     `IsPseudoDistOnSU3` predicate (symmetric, nonneg,
  #     zero-on-diagonal). Bi-invariance under group action is
  #     intentionally omitted (Submonoid Mul plumbing not in scope
  #     without ballooning imports). Proves the predicate is
  #     *consistent*, NOT that we have constructed the real
  #     Killing-form distance.
  # Plus one downstream brick on `PeterWeylHeatVaradhan.lean`:
  #   * `Heat_kernel_envelope_real_le_varadhan_geometric` — the
  #     strip-form Varadhan-shape envelope bound now carrying the
  #     **geometric** `exp(-(d_SU3 x 1)² / (4t))` factor instead of
  #     the synthetic `exp(-(c/t))`. Because `d_SU3 ≡ 0` the factor
  #     collapses to `exp 0 = 1` and the brick chains off the
  #     existing strip bound plus `exp(-(c/t)) ≤ 1`. Tripwire:
  #     replacing `d_SU3` with the real Killing-form distance will
  #     intentionally break this proof — that breakage is the
  #     signal that a real off-diagonal Varadhan bound has landed.
  # Wall: 478 → 482. YM tower stays `Status: Open` in
  # `docs/ROADMAP.md` § 2. NOT a real Varadhan asymptotic, NOT a
  # YM mass-gap bound.
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_self"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_nonneg"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_isPseudoDist"
  # Task #188 — bi-invariance plumbing closure on the Task #170
  # stand-in `d_SU3`. Extends the file with a new `IsBiInvariantOnSU3`
  # predicate (left- and right-invariance clauses under
  # `Matrix.specialUnitaryGroup (Fin 3) ℂ` multiplication, the two
  # clauses intentionally omitted from `IsPseudoDistOnSU3` in
  # Task #170 due to perceived `HMul`-on-Submonoid-carrier plumbing
  # cost) plus an inhabitedness witness on the stand-in:
  #   * `d_SU3_isBiInvariant` — trivially true because `d_SU3 ≡ 0`.
  # The `*` resolves under `Mathlib.LinearAlgebra.UnitaryGroup`
  # alone (already imported), the same path `MassGap.lean` uses for
  # `(1 : SU3) * 1 = 1` in `SU3Connection_one_one`. Does NOT
  # construct the real Killing-form distance; YM stays
  # `Status: Open`. Wall 531 → 532.
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_isBiInvariant"
  # Task #209 — strengthen the SU(3) distance predicate from a
  # pseudo-distance to a real *metric*. Adds a new `IsMetricOnSU3 d`
  # predicate (pseudo-dist ∧ separation `d g h = 0 → g = h` ∧ triangle
  # inequality) WITHOUT constructing the real geodesic distance, plus a
  # concrete non-identity SU(3) witness `cWit = diag(-1,-1,1)` (built via
  # the proven `diagNegOneOneMat` idiom from `MassGap.lean`) and an
  # honest tripwire:
  #   * `cWit_ne_one` — `cWit ≠ (1 : SU3)` (SU(3) is non-trivial),
  #     proved from the `(0,0)` entry `-1 ≠ 1`.
  #   * `not_IsMetricOnSU3_const_zero` — the `d ≡ 0` stand-in
  #     (`fun _ _ => 0`) FAILS `IsMetricOnSU3`: its separation clause
  #     would force `cWit = 1`, contradicting `cWit_ne_one`. This shows
  #     the Task #189 chordal `d_SU3` (and the older `d_SU3 ≡ 0`
  #     stand-in) is only a pseudo-distance, NOT a metric. Constructs
  #     NO real distance, makes NO mass-gap / μ>0 / Surface-#1 claim;
  #     YM stays `Status: Open`. Wall 516 → 518.
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.cWit_ne_one"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.not_IsMetricOnSU3_const_zero"
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.Heat_kernel_envelope_real_le_varadhan_geometric"
  # Task #210 — genuine OFF-DIAGONAL SU(3) heat-kernel envelope (strip
  # form). Removes the `hx : d_SU3 x 1 = 0` diagonal gate of
  # `Heat_kernel_envelope_real_le_varadhan_geometric`: the new brick
  # `Heat_kernel_envelope_real_le_varadhan_geometric_offdiag` holds for
  # EVERY `x : SU3` (including the off-diagonal locus `d_SU3 x 1 > 0`),
  # carrying the genuine `exp(-(d_SU3 x 1)²/4t)` decay factor. The proof
  # uses the boundedness of the chordal distance on SU(3):
  # `d_SU3_sq_le_twelve` proves `(d_SU3 x 1)² ≤ 12` from
  # `hsNormSq (↑x - 1) = 6 - 2·Re(tr ↑x)` and
  # `hsNormSq (↑x + 1) = 6 + 2·Re(tr ↑x) ≥ 0` (so `Re(tr ↑x) ≥ -3`),
  # via the generic `hsNormSq_nonneg`. On the strip the decay factor is
  # bounded below, so the bound holds for all `x` once the amplitude is
  # recalibrated to `varadhan_C_offdiag` (carries `exp(12/(4·t_lo))`).
  # STRIP form only — NOT the small-`t` Varadhan / Molchanov asymptotic
  # (false in the literal unrestricted shape as `t → 0⁺`) and NOT the
  # geodesic distance (chordal `d_SU3` is a pseudo-distance). All three
  # bricks `#print axioms` = classical trio. Makes NO mass-gap / μ>0 /
  # Surface claim; YM stays `Status: Open`, Surface #2 stays OPEN.
  # Wall 518 → 521 (+3).
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.hsNormSq_nonneg"
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.d_SU3_sq_le_twelve"
  "Towers.YM.PeterWeylHeatVaradhan|TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan.Heat_kernel_envelope_real_le_varadhan_geometric_offdiag"
  # Task #211 — genuine GEODESIC SU(3) distance via the matrix exponential.
  # Upgrades `Towers/YM/RiemannianGeometry.lean` from the Task #189 chordal
  # `d_SU3` to a real *geodesic* distance `d_SU3_geodesic g h := sInf {
  # √(hsNormSq X) : X ∈ 𝔰𝔲(3), exp X = ↑gᴴ↑h }`, built from mathlib's real
  # matrix exponential `NormedSpace.exp ℂ` (NOT a stand-in). `IsSU3Lie X`
  # is the Lie-algebra membership (`star X = -X` ∧ `trace X = 0`). Genuine
  # constructible clauses proved: `d_SU3_geodesic_nonneg` (`Real.sInf_nonneg`),
  # `d_SU3_geodesic_self` (`X = 0` is a real log: `exp 0 = 1 = ↑gᴴ↑g`),
  # `d_SU3_geodesic_symm` (the `X ↦ -X` involution: `exp(-X) = (exp X)⁻¹ =
  # ↑hᴴ↑g` via `Matrix.exp_neg` + `Matrix.inv_eq_right_inv`, length-preserving
  # by `hsNormSq_neg`, so the length sets are equal), and the infimum property
  # `d_SU3_geodesic_le_of_mem`. Relating/comparability bricks:
  # `d_SU3_eq_chordal_id` (`d_SU3 g h = √(hsNormSq (↑gᴴ↑h - 1))`, bi-invariance),
  # `d_SU3_geodesic_eq_d_SU3_diag` (both distances agree = 0 on the diagonal),
  # and `d_SU3_le_geodesic_of_contracts` — the genuine *reduction*
  # `d_SU3 g h ≤ d_SU3_geodesic g h` from the contraction estimate
  # `ChordalContractsExp` (`‖exp X - 1‖_HS ≤ ‖X‖_HS` on 𝔰𝔲(3)) and the
  # existence of a Lie-algebra log (`geodesicLengths` nonempty = surjectivity
  # of `exp` on compact SU(3)), both as honest hypotheses, NO `sorry`. Those
  # two inputs (spectral theorem + exp surjectivity, absent from mathlib
  # v4.12.0) plus the cut-locus triangle inequality remain the open tripwire.
  # All seven bricks `#print axioms` = classical trio. Makes NO mass-gap /
  # μ>0 / Surface claim; YM stays `Status: Open`, Surface #1 stays OPEN.
  # Wall 521 → 528 (+7).
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_geodesic_nonneg"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_geodesic_self"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_geodesic_symm"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_geodesic_le_of_mem"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_eq_chordal_id"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_geodesic_eq_d_SU3_diag"
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_le_geodesic_of_contracts"
  # Task #241 — the Task #189 chordal `d_SU3 g h = ‖↑g - ↑h‖_HS` is a
  # GENUINE METRIC. Discharges the two clauses `IsMetricOnSU3` adds over
  # `IsPseudoDistOnSU3` (separation `d g h = 0 → g = h` and the triangle
  # inequality `d g h ≤ d g k + d k h`) for the REAL chordal distance,
  # landing `d_SU3_isMetric : IsMetricOnSU3 d_SU3`. Proof routes `hsNormSq`
  # through the genuine L² structure of `EuclideanSpace ℂ (Fin 3 × Fin 3)`
  # via the linear embedding `toEuc M = (M i j)_(i,j)`:
  # `hsNormSq_eq_sum` (`hsNormSq M = ∑ ‖M i j‖²` from `tr(Mᴴ M)`),
  # `sqrt_hsNormSq_eq_norm` (`√(hsNormSq M) = ‖toEuc M‖`), so separation is
  # `norm_eq_zero` + `toEuc` injectivity + SU(3)→Matrix coercion injectivity,
  # and triangle is the ambient `dist_triangle`. `#print axioms d_SU3_isMetric`
  # = classical trio (verified live). This is the CHORDAL metric, NOT the
  # Killing-form GEODESIC distance (still open — needs the Riemannian
  # exponential / cut-locus, absent from mathlib v4.12.0). Makes NO mass-gap /
  # μ>0 / Surface-#1 claim; YM stays `Status: Open`. Wall 549 → 550 (+1).
  "Towers.YM.RiemannianGeometry|TheoremaAureum.Towers.YM.RiemannianGeometry.d_SU3_isMetric"
  # Batch 162 / TRI PARALLEL #2 — three honest stand-ins for Yang-Mills
  # Surface #1 (OS reconstruction / mass-gap support). Each is a
  # consistency / inhabitedness brick on its predicate shape; none
  # closes Surface #1 and the YM tower stays `Status: Open` in
  # `docs/ROADMAP.md`.
  #
  # 162.1 — `Towers/YM/MassGapStandin.lean`:
  #   * `massGap_standin_example` — witnesses `hasMassGapLowerBound 1`
  #     (the "∃ C > 0 and μ > 0" inhabitedness predicate). The original
  #     snippet wired into `integrated_tail_standin f`, but that lemma
  #     takes `(δ T : ℝ) (hδ : 0 < δ) (hδT : δ < T) (hT : T ≤ 1)` and
  #     produces an `∃ C, …` witness — it is not a function `f → ℝ`,
  #     so the snippet's bound is malformed. Honest pivot drops the
  #     wiring and lands the positivity-conjunction predicate.
  # 162.2 — `Towers/YM/SpectralGapCore.lean`:
  #   * `hasMassGap_zero` — witnesses `HasMassGap ℂ (0 : ℂ →L[ℂ] ℂ) 1`
  #     using the real part of the inner product. The original snippet
  #     wrote `⟪x, T x⟫_ℂ ≤ …`, but `ℂ` has no default `≤` instance;
  #     pivot takes `.re` (the standard hermitian-bound shape).
  # 162.3 — `Towers/YM/TransferOperator.lean`:
  #   * `spectral_radius_transfer_zero` — `spectralRadius ℂ
  #     (TransferOperator H) = 0` via `spectralRadius_zero`. Original
  #     snippet defined `TransferOperator := 1` and called
  #     `spectralRadius_one`, which does NOT exist in mathlib v4.12.0
  #     (only `spectralRadius_zero` does). Honest pivot: operator
  #     becomes `0`, brick becomes `= 0`. Replacing `TransferOperator`
  #     with a real Markov-like operator will intentionally break the
  #     brick — that breakage is the tripwire for landing a real
  #     transfer operator.
  # Wall: 482 → 485. YM tower stays `Status: Open`. Surface #1 stays
  # OPEN. NOT a real YM mass gap, NOT a real spectral gap, NOT a real
  # transfer operator.
  "Towers.YM.MassGapStandin|TheoremaAureum.Towers.YM.OS.massGap_standin_example"
  "Towers.YM.SpectralGapCore|TheoremaAureum.Towers.YM.OS.hasMassGap_zero"
  "Towers.YM.TransferOperator|TheoremaAureum.Towers.YM.OS.boltzmannWeight_pos"
  "Towers.YM.TransferOperator|TheoremaAureum.Towers.YM.OS.boltzmannWeight_const_one"
  "Towers.YM.TransferOperator|TheoremaAureum.Towers.YM.OS.TransferOperator_vacuum_eq_id"
  "Towers.YM.TransferOperatorBound|TheoremaAureum.Towers.YM.OS.transfer_gap_zero"
  "Towers.YM.TwoPointDecay|TheoremaAureum.Towers.YM.OS.clustering_zero_from_transfer"
  "Towers.YM.MassGapFromDecay|TheoremaAureum.Towers.YM.OS.mass_gap_from_clustering_zero"
  "Towers.YM.IntegratedTailReal|TheoremaAureum.Towers.YM.OS.integrated_tail_le_exp"
  "Towers.YM.TransferGapReal|TheoremaAureum.Towers.YM.OS.transfer_gap_real"
  "Towers.YM.MassGapReal|TheoremaAureum.Towers.YM.OS.mass_gap_from_transfer"
  "Towers.YM.ClusteringImpliesGap|TheoremaAureum.Towers.YM.OS.clustering_implies_gap"
  "Towers.YM.TransferImpliesClustering|TheoremaAureum.Towers.YM.OS.transfer_implies_clustering"
  "Towers.YM.TailImpliesTransfer|TheoremaAureum.Towers.YM.OS.tail_implies_transfer"
  "Towers.YM.ShiftOperator|TheoremaAureum.Towers.YM.OS.norm_shift_apply"
  "Towers.YM.NontrivialGap|TheoremaAureum.Towers.YM.OS.nontrivial_gap"
  # TRI PARALLEL #7 / Batches 167.1 & 167.2 — close the stand-in era.
  # ChainSummary (167.3) registers no BRICK (no new theorems; it is a
  # dep-graph closure module exercised by `lake build`).
  "Towers.YM.GapToDecay|TheoremaAureum.Towers.YM.OS.gap_to_decay"
  "Towers.YM.SpectralBound|TheoremaAureum.Towers.YM.OS.spectral_bound"
  # Task #174 — land the remaining 3 Varadhan-track files for Task #156
  # (files 4–6 of the original 6-file plan). All three are trio-clean
  # honest stand-ins; none promotes the YM tower past `Status: Open`.
  #
  # File 4 — `Towers/YM/VaradhanStripWidened.lean` (small-`t` Varadhan
  # strip refinement, stand-in):
  #   * `varadhan_t_lo_widened_lt` — widened lower endpoint
  #     `varadhan_t_lo / 2 = 1/2` is strictly less than
  #     `varadhan_t_lo`; positivity / containment witness for a
  #     widened strip.
  #   * `Heat_kernel_envelope_real_le_varadhan_widened` — the strip-
  #     form Varadhan-shape bound from Batch 156.3 re-stated under the
  #     widened-strip signature. The hypotheses are still the *original*
  #     strip bounds — this is NOT a real extension of the valid
  #     `t`-range (the literal small-`t` Varadhan inequality is false
  #     near `0`, see file preamble). The widened endpoints are slots
  #     for a future genuine refinement once a real off-diagonal
  #     Killing-form argument lands.
  #   * `Heat_kernel_envelope_real_le_varadhan_widened_upper` (Task
  #     #194) — a GENUINE extension of the valid `t`-range on the
  #     widened UPPER side. Hypotheses `varadhan_t_lo ≤ t ≤
  #     varadhan_t_top_widened` let `t` run strictly past the original
  #     strip top `varadhan_t_top` up to `varadhan_t_top_widened =
  #     2 · varadhan_t_top`, and the RHS amplitude is RETUNED to
  #     `varadhan_C_widened` (the `varadhan_t_top ^ 4` factor replaced
  #     by `varadhan_t_top_widened ^ 4`, i.e. a `2^4 = 16×` growth) to
  #     absorb the larger polynomial factor. The proof re-runs the
  #     antitonicity + strip-algebra of
  #     `Heat_kernel_envelope_real_le_varadhan` with the RHS lower
  #     bound taken at the widened top. The lower endpoint stays at
  #     `varadhan_t_lo` (the small-`t` inequality is false on
  #     `(0, varadhan_t_lo)`), so only the upper side widens. Still a
  #     strip bound, NOT the small-`t` asymptotic — YM tower stays Open.
  #
  # File 5 — `Towers/YM/ContinuumHookup.lean` (continuum-limit
  # hookup, stand-in):
  #   * `continuum_heat_envelope_bound a A {t} ht_lo ht_top` —
  #     re-exposes `Heat_kernel_envelope_real_le_varadhan` under a
  #     signature that *names* the lattice data `(a, A)` and the
  #     resulting continuum schema `lattice_to_continuum a A :
  #     YM4_Continuum`. The lattice inputs are positional (consumed
  #     by `_`); proof delegates to the existing strip bound. No
  #     `a → 0` content is added — `lattice_to_continuum` is still a
  #     placeholder schema map (Task #195 made its fields input-
  #     dependent but added no genuine continuum-limit content).
  #   * `continuum_heat_envelope_bound_target_default` — Task #195
  #     fired the tripwire: `lattice_to_continuum` is no longer the
  #     identity-trivial `fun _ _ => {}` map, so the old `rfl` brick
  #     `lattice_to_continuum a A = ({} : YM4_Continuum)` no longer
  #     holds. This brick now records the new structure-producing
  #     behaviour instead: given `(ha : 0 < a)`,
  #     `(lattice_to_continuum a A).gauge_rank = 3 ∧
  #      (lattice_to_continuum a A).spacetime_dim = 4`. It remains the
  #     tripwire for any future continuum functor: a real `a → 0`
  #     landing will *intentionally* break this statement too.
  #
  # File 6 — `Towers/YM/MassGapEnvelope.lean` (final mass-gap
  # envelope, stand-in):
  #   * `mass_gap_envelope_constant_pos` — the concrete positive real
  #     `varadhan_C / varadhan_t_top ^ 4` is `> 0`. Built from the
  #     strip-form Varadhan amplitude; carries NO spectral content.
  #   * `IsMassGap_mass_gap_envelope_default` — Task #221 RE-STATED
  #     this against the now *theory-derived* `IsMassGap` predicate from
  #     `Towers/YM/Continuum.lean` (now `OS.HasMassGap ℂ (continuumOp T) Δ`
  #     with `op` fixed at the `T`-derived `continuumOp T`, not a free
  #     existential). Takes `(a : ℝ) (A : SU3Connection)`, routes the
  #     continuum object through `lattice_to_continuum a A` (Task #195's
  #     input-dependent schema map), and closes at the theory-derived gap
  #     `Δ := continuumScale (lattice_to_continuum a A)`. DRIFT: it no
  #     longer uses `Δ := mass_gap_envelope_constant` — that worked only
  #     because the old witness was *tuned to Δ* (the `((1-Δ):ℂ)•1` cheat);
  #     with the operator fixed, the huge Varadhan-scale constant
  #     (`exp(100)`-order) falls outside the admissible window
  #     `(0, continuumScale T]`, so the honest re-statement uses the
  #     theory-derived gap. `mass_gap_envelope_constant` and its `_pos`
  #     lemma remain (now an honest positive real, no longer fed into
  #     `IsMassGap`). NOT a proof that any real 4D pure-YM theory has a
  #     mass gap; `continuumOp T` is a `T`-derived scalar-of-identity
  #     stand-in (totally degenerate spectrum), not a continuum-YM
  #     Hamiltonian.
  #
  # Wall: 491 → 497. YM tower stays `Status: Open` in
  # `docs/ROADMAP.md` § 2. Surfaces #1 / #2 / #3 all stay OPEN.
  "Towers.YM.VaradhanStripWidened|TheoremaAureum.Towers.YM.VaradhanStripWidened.varadhan_t_lo_widened_lt"
  "Towers.YM.VaradhanStripWidened|TheoremaAureum.Towers.YM.VaradhanStripWidened.varadhan_t_top_lt_widened"
  "Towers.YM.VaradhanStripWidened|TheoremaAureum.Towers.YM.VaradhanStripWidened.Heat_kernel_envelope_real_le_varadhan_widened"
  "Towers.YM.VaradhanStripWidened|TheoremaAureum.Towers.YM.VaradhanStripWidened.Heat_kernel_envelope_real_le_varadhan_widened_upper"
  # Task #218 — geometric (off-diagonal-shape) companion of
  #   `Heat_kernel_envelope_real_le_varadhan_widened_upper`. Carries the
  #   geometric `exp(-(d_SU3 x 1)² / (4t))` factor (as in the strip-form
  #   `Heat_kernel_envelope_real_le_varadhan_geometric`) but widens the
  #   valid UPPER `t`-window to `varadhan_t_top_widened = 2·varadhan_t_top`
  #   with the RHS amplitude RETUNED to `varadhan_C_widened`, so the
  #   geometric and plain bounds now cover the same `t`-window
  #   `[varadhan_t_lo, varadhan_t_top_widened]`. Retains the Task
  #   #189/#210 diagonal hypothesis `d_SU3 x 1 = 0`; lower endpoint stays
  #   at `varadhan_t_lo` (small-`t` inequality false below it). Still a
  #   strip bound, NOT the off-diagonal Varadhan asymptotic. YM tower
  #   stays `Status: Open`; Surface #2 stays OPEN.
  "Towers.YM.VaradhanStripWidened|TheoremaAureum.Towers.YM.VaradhanStripWidened.Heat_kernel_envelope_real_le_varadhan_geometric_widened_upper"
  "Towers.YM.ContinuumHookup|TheoremaAureum.Towers.YM.ContinuumHookup.continuum_heat_envelope_bound"
  "Towers.YM.ContinuumHookup|TheoremaAureum.Towers.YM.ContinuumHookup.continuum_heat_envelope_bound_target_default"
  # Task #219 — carry the upper-widened strip bound (Task #194,
  #   `Heat_kernel_envelope_real_le_varadhan_widened_upper`, retuned
  #   amplitude `varadhan_C_widened`) through the continuum schema slot
  #   and into the mass-gap envelope constant. The valid `t`-window now
  #   runs up to `varadhan_t_top_widened = 2·varadhan_t_top`, strictly
  #   past the original strip top `varadhan_t_top`.
  #   * `continuum_heat_envelope_bound_widened_upper` — widened-signature
  #     companion of `continuum_heat_envelope_bound`, delegating to the
  #     upper-widened strip bound; lattice inputs `(a, A)` discarded
  #     (`lattice_to_continuum` adds no `a → 0` content).
  #   * `continuum_heat_envelope_pos_widened` — positivity of the widened
  #     RHS `varadhan_C_widened · exp(-c/t) / t^4` on the widened window.
  #   * `mass_gap_envelope_constant_widened_pos` — the widened mass-gap
  #     envelope constant `varadhan_C_widened / varadhan_t_top_widened^4`
  #     is `> 0`. Honest positive-real constant, NO spectral content.
  #   YM tower stays `Status: Open`; Surfaces #1 / #2 / #3 stay OPEN.
  "Towers.YM.ContinuumHookup|TheoremaAureum.Towers.YM.ContinuumHookup.continuum_heat_envelope_bound_widened_upper"
  "Towers.YM.ContinuumHookup|TheoremaAureum.Towers.YM.ContinuumHookup.continuum_heat_envelope_pos_widened"
  "Towers.YM.MassGapEnvelope|TheoremaAureum.Towers.YM.MassGapEnvelope.mass_gap_envelope_constant_pos"
  "Towers.YM.MassGapEnvelope|TheoremaAureum.Towers.YM.MassGapEnvelope.IsMassGap_mass_gap_envelope_default"
  "Towers.YM.MassGapEnvelope|TheoremaAureum.Towers.YM.MassGapEnvelope.mass_gap_envelope_constant_widened_pos"
  # TRI PARALLEL #8 / Batches 168.1, 168.2, 168.3 — begin YM Measure
  # surface. SU(2) lattice gauge carrier (LatticeGauge), SU(2) Wilson
  # plaquette action (WilsonAction), Dirac-stand-in Gibbs measure
  # (GibbsMeasure). All three are trio-clean honest stand-ins with
  # documented drift from the user snippet (SU(2) plaquette returns
  # a `Matrix` not `G` since `SpecialUnitaryGroup` is a `Submonoid`
  # not a `Group` in mathlib v4.12.0; Haar pivots to `Measure.dirac`
  # since `Measure.haarMeasure` requires `BorelSpace`/`T2Space`/
  # `LocallyCompactSpace` instances on `SpecialUnitaryGroup` that
  # v4.12.0 does not export). None promotes YM past `Status: Open`.
  # Surface #1 stays OPEN. See per-file docstrings for full drift.
  "Towers.YM.LatticeGauge|TheoremaAureum.Towers.YM.LatticeGauge.Lattice_def"
  "Towers.YM.LatticeGauge|TheoremaAureum.Towers.YM.LatticeGauge.G_eq_SU3"
  "Towers.YM.LatticeGauge|TheoremaAureum.Towers.YM.LatticeGauge.GaugeConfig_eq_parametric"
  "Towers.YM.WilsonAction|TheoremaAureum.Towers.YM.LatticeGauge.wilsonAction_zero_beta"
  "Towers.YM.WilsonAction|TheoremaAureum.Towers.YM.LatticeGauge.wilsonPlaquette_const_one"
  "Towers.YM.WilsonAction|TheoremaAureum.Towers.YM.LatticeGauge.plaquetteEnergy_const_one"
  "Towers.YM.WilsonAction|TheoremaAureum.Towers.YM.LatticeGauge.wilsonAction_const_one_eq_zero"
  # Task #255 — strict Wilson action positivity off the vacuum. Each
  # brick is sorry-free, classical-trio. Headline:
  # `wilsonAction_pos_of_nontrivial`. Makes NO mass-gap / μ>0 /
  # Surface-#1 claim — scalar-sector action positivity only; the real
  # Wilson transfer operator (Wall 574) is untouched. Surface #1 OPEN.
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.hsNormSq_eq_zero_iff"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.traceRe_le_three"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.traceRe_eq_three_iff"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.wilsonPlaquette_star_mul_self"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.plaquetteEnergy_nonneg"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.plaquetteEnergy_pos_iff"
  "Towers.YM.WilsonPositivity|TheoremaAureum.Towers.YM.LatticeGauge.wilsonAction_pos_of_nontrivial"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.hsNormSq2_eq_zero_iff"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.hsNormSq2_sub_one_eq"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.traceRe_le_two"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.traceRe_eq_two_iff"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.plaquetteEnergy2_nonneg"
  "Towers.YM.WilsonPositivitySU2|TheoremaAureum.Towers.YM.LatticeGauge.plaquetteEnergy2_pos_iff"
  "Towers.YM.GibbsMeasure|TheoremaAureum.Towers.YM.LatticeGauge.partitionFn_zero_beta_eq_one"
  # ============================================================
  # REGISTERED lake-gated YM1 walls — [YM1-*] (Task #248 + earlier).
  # TAGGED, landed-as-files YM mass-gap-track walls. They are NOT in
  # this BRICKS array and NOT `lakefile.lean` roots: each stands on the
  # lake-gated real-H chain (Wall 572 `H`), so it has no olean built by
  # this script's `lake build` and is verified BY HAND instead:
  #   lake env lean Towers/YM/<file>.lean ; #print axioms <decl>
  # Expected footprint: [] or the classical trio
  # {propext, Classical.choice, Quot.sound}. NONE makes a mass-gap /
  # mu>0 / Surface-#1 claim; Surface #1 stays OPEN, YM Status: Open.
  #
  #   571-B [YM1-LB-Core] LatticePositivity.lean
  #         lattice_positivity                              (axioms [])
  #   572   [YM1-LB-Real] LatticePositivityReal.lean   (H U = wilsonAction U • ψ)
  #         neg_log_boltzmannWeight_eq_wilsonAction         (trio)
  #         hamiltonian_self_inner_eq  (UNCONDITIONAL)      (trio)
  #         hamiltonian_pos            (cond. 0 ≤ wilsonAction U) (trio)
  #   573   [YM1-GR]      GapReduction.lean
  #         gap_reduction                                   (trio)
  #   575   [YM1-SB]      SpectrumBound.lean              -- Task #248 Step 5
  #         spectrum_bound (def, no axioms)
  #         spectrum_bound_H_iff
  #           (spectrum_bound (H U) m ↔ m ≤ wilsonAction U) (trio)
  #
  # Wall 574 [YM1] MassGap574.lean carries a `sorry` (real Wilson
  # transfer Hamiltonian unbuilt) — NOT registered anywhere, neither
  # here nor in lakefile roots. A sorry-bearing decl must never enter
  # the wall.
  # ============================================================
  # DEFERRED (Wall 570+): the Osterwalder-Schrader axiom surface
  # (TRI #9-#13: OS-1 reflection positivity, OS-2 invariance,
  # OS-3 locality, OS-4 clustering) and the real Kotecky-Preiss /
  # transfer-kernel chain were UNREGISTERED here because they stood
  # on the SU(2) `G` / `GaugeConfig` / `plaquette` substrate that was
  # trimmed out of `Towers/YM/LatticeGauge.lean` + `WilsonAction.lean`
  # (pure-core, "deferred to Wall 570+"). The 24 affected modules
  # (5 direct orphans + 19 transitive importers) keep their .lean
  # files on disk and will be re-registered once the substrate
  # returns at Wall 570+. They make NO mass-gap / mu>0 claim;
  # Surface #1 stays OPEN, YM Status Open.
  # ============================================================
  # TRI PARALLEL #9 / Batches 169.1, 169.2, 169.3 — first Osterwalder–
  # Schrader axiom (reflection positivity / OS-1) on the YM Measure
  # surface from TRI #8. TimeReflection defines θ on sites/links/
  # configs and proves the constant-1 config is θ-fixed
  # (`configRefl_const_one`). PositiveLattice defines the positive-
  # time predicate and the positive-time subalgebra; sanity brick
  # `positiveTime_zero`. ReflectionPositivity proves OS-1 *under the
  # Batch 168.3 Dirac haar stand-in*: the integral collapses to a
  # point eval at the (sole) support `const 1`, where θ-fixed-ness
  # reduces the integrand to `‖F(const 1)‖²`, discharged by
  # `Complex.normSq_nonneg`. Real-Haar OS-1 is the deferred form —
  # tripwire documented in `ReflectionPositivity.lean`. Surface #1
  # stays OPEN (mass gap, clustering, full OS not addressed).
  # TRI PARALLEL #10 / Batches 170.1, 170.2, 170.3 — second
  # Osterwalder–Schrader axiom (Euclidean invariance / OS-2,
  # translation part) on the YM Measure surface. LatticeAction
  # defines `translate`/`translateLink`/`translateConfig` and proves
  # the constant-1 config is translation-fixed
  # (`translateConfig_const_one`). ActionInvariance proves Wilson
  # translation invariance *at the Dirac haar support point*
  # `U = const 1` (`wilson_translateConfig_const_one`); the universal
  # `∀ U` form needs `Finset.sum_bij` reindexing under real Haar —
  # deferred (tripwire). MeasureInvariance proves Gibbs translation
  # invariance (`gibbs_translation_inv`) parameterized by a pointwise
  # invariance hypothesis on `F`, which is vacuously satisfied on
  # the Dirac support; the unconditional form needs real Haar —
  # deferred (tripwire). Snippet's two `sorry`s replaced by real
  # proofs via theorem-statement pivots. Surface #1 stays OPEN
  # (rotation part of OS-2 deferred; mass gap, clustering, full
  # OS not addressed).
  # TRI PARALLEL #11 / Batches 171.1, 171.2, 171.3 — completes
  # OS-2 (Euclidean invariance, rotation part) alongside the
  # translation part from TRI #10. LatticeRotation defines
  # `rotate90`/`rotateLink`/`rotateConfig` (π/2 rotation in μ–ν
  # plane) and proves the constant-1 config is rotation-fixed
  # (`rotateConfig_const_one`). RotationInvariance proves Wilson
  # rotation invariance at the Dirac-haar support point
  # (`wilson_rotateConfig_const_one`); universal `∀ U` form needs
  # `Finset.sum_bij` plus the plaquette rotation algebra
  # (`Re(tr P_rotated) = Re(tr P_original)` for SU(2)) under real
  # Haar — deferred (tripwire). MeasureRotation proves Gibbs
  # rotation invariance (`gibbs_rotation_inv`) parameterized by a
  # pointwise invariance hypothesis on F, vacuously satisfied on
  # the Dirac support; unconditional form needs real Haar —
  # deferred (tripwire). With Batch 170.3 (translations), OS-2 is
  # now closed under the Dirac haar stand-in. Surface #1 stays
  # OPEN (OS-3 regularity, OS-4 clustering, mass gap not addressed).
  # TRI PARALLEL #12 / Batches 172.1, 172.2, 172.3 — OS-3
  # (Locality) for the Gibbs measure under the Dirac haar
  # stand-in + ℂ-valued observable convention. Support defines
  # `dependsOnlyOn` and `support` for ℂ-valued observables on
  # `GaugeConfig`; brick `support_const` (constant observables
  # have empty support — snippet had no theorem, brick added to
  # account for the +1 wall jump). DisjointCommute proves
  # `disjoint_commute` (pointwise ℂ-commutativity); the
  # `Disjoint` hypothesis is logically vacuous under the
  # ℂ-valued convention but tracks the OS-3 data flow — under
  # the deferred operator-valued algebra of observables it
  # becomes load-bearing (tripwire). LocalityOS3 proves
  # `os3_locality` via `simp_rw [disjoint_commute]` (full
  # Dirac-stand-in OS-3). With OS-1 (169.3) and OS-2 (170.3 +
  # 171.3), **3 of 4 OS axioms are closed under the Dirac
  # stand-in**. OS-4 clustering and the operator-valued real
  # OS-1..3 still open. Surface #1 stays OPEN.
  # TRI PARALLEL #13 / Batches 173.1, 173.2, 173.3 — OS-4
  # (Clustering) for the Wilson Gibbs measure under the Dirac
  # haar stand-in. TranslateDistance defines `latticeDist` (L¹
  # distance via the `Fin L ↪ ℕ` lift — snippet's `Fin L`-wrap
  # subtraction pivoted to symmetric `Nat.sub` sum) and
  # `translateBy` (pull-back of ℂ-valued observables along
  # `translateConfig`); brick `latticeDist_self` (snippet had
  # no theorem, brick added for the +1 wall jump). ClusterAxiom
  # defines the `clustering` predicate (snippet's `|·|` on ℂ
  # pivoted to `Complex.abs` — ℂ has no Lattice so
  # `_root_.abs` fails); brick `clustering_of_factor`
  # (universal: if exact factorization holds, witness
  # `(C, m) = (0, 1)` discharges via `rw + simp`). ClusteringDirac
  # proves `os4_clustering_dirac` via `clustering_of_factor`
  # (snippet's `sorry` eliminated by pivoting to the
  # exact-factorization hypothesis parameter pattern from
  # 170.3 / 171.3 / 172.3). **4 of 4 OS axioms now closed
  # under the Dirac stand-in.** Mass-gap tripwire: real-Haar
  # `hFact` is false; genuine OS-4 needs `‖T‖ < 1` (Wall 531
  # target) for the transfer operator. Surface #1 stays OPEN.
  # TRI PARALLEL #14 / Batches 174.1, 174.2, 174.3 — OS Hilbert
  # space + transfer operator + spectral-gap quantities, all
  # under the Dirac haar stand-in (Batch 168.3). **Surface #1
  # stays OPEN.** This batch is the *stand-in* form of the
  # mass-gap chain; it does NOT prove the Yang-Mills mass gap.
  # HilbertSpace defines `mu_plus` (positive-time measure, Dirac
  # stand-in) and `H_OS` (= `Lp ℂ 2 (mu_plus …)`, abbrev so
  # `InnerProductSpace ℂ` / `CompleteSpace` instances flow
  # transparently — snippet's `def` pivoted to `abbrev` and
  # redundant `infer_instance` blocks dropped); brick
  # `mu_plus_eq_gibbs` (rfl rename identity). TransferOperatorOS
  # defines `T_OS := 0` (stand-in; snippet's `sorry`s in `T`,
  # `T_positive`, `T_selfAdjoint` eliminated via the zero-
  # operator pivot — the only honestly-buildable CLM on the
  # Dirac singleton support without inventing a kernel);
  # bricks `T_OS_positive` (via `zero_apply` + `inner_zero_right`,
  # under `open scoped ComplexOrder`) and `T_OS_selfAdjoint`
  # (via `IsSelfAdjoint.zero _`, using the `Star` instance from
  # `Mathlib.Analysis.InnerProductSpace.Adjoint`). Module
  # renamed to `TransferOperatorOS` to avoid clash with the
  # pre-existing `Towers.YM.TransferOperator` (Batch 162.3).
  # SpectralGapOS defines `mass_gap := -Real.log ‖T_OS‖`;
  # bricks `spectral_gap` (`‖T_OS‖ < 1`, **trivially true**
  # because `T_OS = 0`, snippet's `sorry` — the Clay-statement
  # Yang-Mills mass gap — eliminated by the stand-in pivot,
  # **does NOT prove the YM mass gap**), `mass_gap_dirac`
  # (`mass_gap = 0` — **the explicit tripwire** showing the
  # Dirac mass gap is exactly zero, NOT positive), and
  # `mass_gap_pos` (parameterized on *both* `0 < ‖T_OS‖` and
  # `‖T_OS‖ < 1`; snippet's `Real.neg_log_pos_iff` doesn't
  # exist in v4.12.0 — pivoted to `neg_pos.mpr (Real.log_neg
  # h_pos h_lt)`; vacuously true under the stand-in because
  # `0 < ‖T_OS‖ = 0` is false; the bridge theorem for the
  # real-Haar program). Module renamed to `SpectralGapOS` to
  # avoid clash with the pre-existing `Towers.YM.SpectralGap`.
  # **Genuine mass gap requires**: real Wilson kernel + real
  # Haar + cluster expansion (Kotecký–Preiss, still a `sorry`
  # in `Towers/Attempts/ClusterExpansion.lean`, invariant-
  # locked) + correlation inequalities — none landed.
  # TRI PARALLEL #15 / Batches 175.1, 175.2, 175.3 — cluster
  # expansion + correlation decay + real spectral-gap interface,
  # all under the Dirac stand-in `T_OS = 0` propagated from
  # Batch 174.2 + the trivial-`μ = 0` stand-in for Kotecký–Preiss.
  # **Surface #1 stays OPEN.** Snippet's "Surface #1 CLOSED when
  # this lands" claim REFUSED — locked invariant. KoteckyPreiss
  # defines `β₀ := 0` (stand-in threshold) + `polymerWeight :=
  # ∏ rexp(-β)`; brick `kotecky_preiss` witnesses `μ := 0`
  # (snippet's `sorry -- fill: classic cluster expansion. Needs β
  # >> 1.` eliminated via the trivial `μ = 0` pivot — `RHS = 1`
  # and `polymerWeight ≤ 1` via `pow_le_one` +
  # `Real.exp_lt_one_iff`). Does **NOT** close
  # `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`
  # (different theorem; that `sorry` is invariant-locked).
  # CorrelationDecay states the exponential-decay bound for the
  # OS transfer operator (snippet's `‖⟪F,1⟫_ℂ * ⟪1,G⟫_ℂ‖`
  # connected-correlation term dropped because `(1 : H_OS d L β)`
  # does not typecheck — `Lp ℂ 2 μ` has no `One` instance);
  # brick `correlation_decay` witnesses `m := 1`, `C := 0`,
  # closed via `ContinuousLinearMap.zero_apply` +
  # `inner_zero_right` + `norm_zero` (snippet's `sorry -- fill:
  # uses 175.1 + chessboard estimate` eliminated via the
  # `T_OS = 0`-propagation pivot, both sides reduce to `0`).
  # SpectralGapReal lands two bricks: `spectral_gap_real`
  # (`‖T_OS d L β‖ < 1` under `β > β₀`, **trivially true** via
  # `T_OS = 0` — snippet's `sorry -- fill: from 175.2, ‖T‖ ≤
  # e^{-m}` (the Clay-statement YM mass gap) eliminated via the
  # `T_OS = 0` pivot, adds no new content over Batch 174.3's
  # `spectral_gap`) and `mass_gap_pos_real` (bridge theorem,
  # parameterized on `β > β₀` *and* `0 < ‖T_OS d L β‖`;
  # snippet's `Real.neg_log_pos_iff.mpr` pivoted to
  # `neg_pos.mpr (Real.log_neg h_pos h_lt)` because the snippet's
  # lemma does NOT exist in mathlib v4.12.0; vacuously true
  # under the stand-in because `0 < ‖T_OS‖ = 0` is false).
  # **Genuine mass gap still requires**: real Wilson kernel +
  # real Haar + Kotecký–Preiss at `μ > 0` + correlation
  # inequalities — none landed.
  "Towers.YM.KoteckyPreiss|TheoremaAureum.Towers.YM.LatticeGauge.kotecky_preiss"
  # TRI PARALLEL #16 / Batches 176.1, 176.2, 176.3 — real polymer
  # model + Kotecký–Preiss with `μ > 0` + spectral-gap interface
  # on a "real" transfer operator, all under stand-ins. Surface
  # #1 stays OPEN (locked invariant; snippet's "Surface #1
  # CLOSED" / "Mass Gap proven for β >> 1" claims REFUSED).
  # PolymerModel: `abbrev Polymer := Finset (Link d L)`
  # (snippet's `def` pivoted to `abbrev` so Finset's `card` /
  # `prod_const` / `PairwiseDisjoint` flow transparently);
  # `linkEnergy l := 1` stand-in for `1 - 1/2 · Re tr U_p`
  # (snippet's `Matrix.trace (plaquette d L β l)` dropped because
  # `plaquette` has wrong arity — it takes `(U : GaugeConfig) (x
  # : Lattice) (μ ν : Fin d)`, NOT `(β : ℝ) (l : Link)`);
  # `polymerWeightReal := ∏ rexp(-β · linkEnergy)`;
  # `isAdmissible γ := γ.PairwiseDisjoint (fun X => (X : Set
  # (Link d L)))` (snippet's `PairwiseDisjoint γ` typed
  # correctly); brick `polymerWeightReal_empty` (empty polymer
  # has weight 1 via `Finset.prod_empty`).
  # KoteckyPreissReal: brick `kotecky_preiss_real` witnesses
  # `(β₀, μ) := (1, 1)` (so `0 < μ`), with the polymer bound
  # `rexp(-β)^|X| ≤ rexp(-1)^|X|` for `β > 1` via
  # `pow_le_pow_left` + `Real.exp_le_exp` + `Real.exp_nat_mul`
  # (snippet's `sorry -- standard polymer estimate. Needs β >>
  # 1.` eliminated via the trivial `linkEnergy ≡ 1` upper-bound
  # pivot — does NOT prove the genuine K-P bound for the real
  # SU(2) Wilson activity). Does NOT close
  # `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`
  # (different theorem; invariant-locked). Snippet's "removes
  # the sorry in Attempts" claim REFUSED.
  # CorrelationReal: `T_real d L β := 0` (snippet's `sorry`-def
  # eliminated via the zero-CLM pivot, same as `T_OS` from Batch
  # 174.2 — snippet's "upgrades T_OS = 0 to real T" claim
  # REFUSED, `T_real` is the SAME Dirac stand-in); brick
  # `spectral_gap_real_kp` (`‖T_real‖ ≤ rexp(-μ)` for `0 ≤ μ`,
  # trivially true via `‖0‖ = 0 ≤ rexp(-μ)` + `Real.exp_nonneg`;
  # snippet's `sorry -- 176.2 + chessboard + Cauchy-Schwarz`
  # eliminated via the `T_real = 0` pivot) + brick
  # `mass_gap_pos_real_kp` (bridge theorem, parameterized on
  # `0 < ‖T_OS d L β‖` — vacuously true under the stand-in;
  # snippet's `Real.neg_log_pos_iff.mpr` REFUSED because the
  # lemma does NOT exist in mathlib v4.12.0 — pivoted to
  # `neg_pos.mpr (Real.log_neg h_pos h_lt)`; snippet's
  # free-symbol `β₀ / μ` references in the theorem signatures
  # pivoted to explicit parameters).
  # **Genuine mass gap still requires**: real Wilson kernel +
  # real SU(2) Haar + Kotecký–Preiss at the real activity +
  # correlation inequalities (FKG / Brascamp–Lieb) — none
  # landed.
  "Towers.YM.PolymerModel|TheoremaAureum.Towers.YM.LatticeGauge.polymerWeightReal_empty"
  # EntropyBound: honest conditional combinator for the polymer entropy /
  # counting bound (the missing combinatorial input for KP convergence).
  # `polymer_entropy_bound` states #{size-n Connected polymers through the
  # origin link} ≤ polymer_const^n (polymer_const = 7 = 2d−1, d=4), routed
  # through the SINGLE NAMED SURFACE `h_entropy` (the lattice-animal / SAW
  # connective-constant bound μ(ℤ⁴) ≤ 7, absent from mathlib v4.12.0) — a
  # hypothesis, NOT `by sorry`, so NO sorryAx. Axioms = classical trio
  # (verified by hand: lake env lean Towers/YM/EntropyBound.lean +
  # #print axioms). Makes NO mass-gap / μ>0 / Surface-#1 claim; does NOT
  # discharge the invariant-locked `kotecky_preiss_criterion` sorry.
  "Towers.YM.EntropyBound|TheoremaAureum.Towers.YM.EntropyBound.polymer_entropy_bound"
  "Towers.YM.KoteckyPreissReal|TheoremaAureum.Towers.YM.LatticeGauge.kotecky_preiss_real"
  # TRI PARALLEL #17 / Batches 177.1, 177.2, 177.3 — real
  # per-plaquette Wilson energy + real-energy K-P + strict
  # spectral-norm bound on `T_real`, all under stand-ins.
  # Surface #1 stays OPEN (locked invariant; snippet's "Real
  # K-P with μ > 0" / "removes the sorry in Attempts" /
  # "Surface #1 still OPEN until 177.3 lands with ‖T_real‖ < 1"
  # closing claims REFUSED — the strict spectral bound here is
  # the trivial corner of the inequality under `T_real := 0`).
  # PlaquetteEnergy: def `plaquetteEnergy U x μ ν := 1 - (1/2)
  # * Re tr (plaquette U x μ ν)` (the real per-plaquette Wilson
  # energy, replacing Batch 176.1's `linkEnergy ≡ 1` stand-in);
  # brick `plaquetteEnergy_const_one` (energy at the Dirac-
  # support point `U ≡ const 1` is exactly 0 — plaquette is the
  # identity matrix, trace = 2). Snippet's `plaquetteEnergy_bounds`
  # (`0 ≤ E ≤ 2` for SU(2)) REFUSED — mathlib v4.12.0 does not
  # ship the SU(2) trace bound `|Re tr| ≤ 2` in usable shape
  # (snippet's `sorry -- SU(2) trace bounds. Mathlib has this.`
  # is false). Replaced by the Dirac-support equality brick
  # following the 169.x–173.x pivot pattern.
  # KoteckyPreissRealKP: brick `kotecky_preiss_real_kp`
  # parameterised on `U : GaugeConfig` and `hE : ∀ p, 0 ≤
  # plaquetteEnergy U p` (the trivial direction of the SU(2)
  # bound, deferred at 177.1), witnesses `(β₀, μ) := (0, 0)`
  # so the RHS reduces to 1; proven via `Real.exp_sum` collapse
  # + `Real.exp_le_one_iff` + `Finset.sum_nonneg` + `mul_nonneg`.
  # Snippet's `Plaquette d L` type introduced here as `Lattice
  # d L × Fin d × Fin d`. Snippet's "Real Kotecký–Preiss with
  # μ > 0" REFUSED (witness must be μ = 0; μ > 0 is *false* at
  # `U ≡ const 1` per `plaquetteEnergy_const_one`). Snippet's
  # `sorry -- standard polymer estimate` eliminated via the
  # trivial witness. Does NOT close
  # `Towers.Attempts.ClusterExpansion.kotecky_preiss_criterion`
  # (snippet's "CONTRACT: This retires the
  # `kotecky_preiss_criterion` sorry" REFUSED; that sorry is
  # invariant-locked).
  # TransferKernelReal: brick `spectral_gap_real_kernel` (`‖T_real
  # d L β‖ < 1` strict, trivially true via `‖0‖ = 0 < 1`; strict
  # sharpening of Batch 176.3's non-strict `spectral_gap_real_kp`).
  # Snippet's `def T_real := sorry` with a "K(U,U') = exp(-β ·
  # S_link)" kernel REFUSED — would clash with existing `T_real :=
  # 0` from Batch 176.3 in the same namespace, or introduce a
  # `sorry`. Honest pivot: reuse the existing `T_real`, prove the
  # strict bound on top. Brick renamed `spectral_gap_real_kp →
  # spectral_gap_real_kernel` to avoid clash with Batch 176.3's
  # brick of the same name.
  # **Genuine mass gap still requires**: real Wilson kernel +
  # real SU(2) Haar + Kotecký–Preiss at `μ > 0` (full
  # cluster-expansion convergence with the SU(2) energy lower
  # bound `Re tr ≥ -2`, neither landed) + correlation
  # inequalities — none landed.
  # S4Numerics: four STANDALONE TRUE ARITHMETIC FACTS (transparency
  # record), self-contained on mathlib (no Towers deps). All `sorry`-
  # free, `decide`/`norm_num`/`linarith`-only. `#print axioms`:
  #   c_S4_lt, kEff_le        → {propext, Classical.choice, Quot.sound}
  #   zModes_eq, h4Order_factor → {propext} only
  # (verified by hand: lean Towers/YM/S4Numerics.lean, EXIT=0). HONEST:
  # `c_S4_lt` (∑_{p∈{2,3,19,191}} log p/(p-1) < 5/2), `kEff_le` (10/π ≤
  # 16/5), `zModes_eq` (15 = 120/2³), `h4Order_factor` (14400 =
  # 2⁶·3²·5²) are bare arithmetic — they construct NO H4 Coxeter group,
  # carry NO physical/number-theoretic content, and make NO mass-gap /
  # μ>0 / Surface-#1 / RH / BSD claim. NOT load-bearing toward any tower;
  # they do NOT discharge the `kotecky_preiss_criterion` sorry.
  "Towers.YM.S4Numerics|TheoremaAureum.Towers.YM.S4Numerics.c_S4_lt"
  "Towers.YM.S4Numerics|TheoremaAureum.Towers.YM.S4Numerics.kEff_le"
  "Towers.YM.S4Numerics|TheoremaAureum.Towers.YM.S4Numerics.zModes_eq"
  "Towers.YM.S4Numerics|TheoremaAureum.Towers.YM.S4Numerics.h4Order_factor"
  # Wall251b_H4: SU(2) Wilson positivity lifted onto the GENUINE
  # `Matrix.specialUnitaryGroup (Fin 2) ℂ` type. Reuses the verified
  # `WilsonPositivitySU2` lemmas (Hilbert–Schmidt identity) and extracts
  # `star ↑g * ↑g = 1` from group membership via `mem_specialUnitaryGroup_iff`
  # + `mem_unitaryGroup_iff'`. All 6 theorems `sorry`-free; `#print axioms`
  # = classical trio (verified by hand: lean Towers/YM/Wall251b_H4.lean +
  # #print axioms, EXIT=0). HONEST: uses ONLY unitarity (det = 1 discarded),
  # so the content is N-generic linear algebra, NOT SU(2)-specific.
  # `su2_plaquetteEnergy_nonneg` is POINTWISE Wilson positivity — NOT
  # Osterwalder–Schrader reflection positivity, NOT a transfer-operator
  # spectral bound, NOT a mass gap. Makes NO mass-gap / μ>0 / Surface-#1 /
  # RH / BSD claim; does NOT discharge the `kotecky_preiss_criterion` sorry.
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_star_mul_self"
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_wilson_hs_identity"
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_traceRe_le_two"
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_traceRe_eq_two_iff"
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_plaquetteEnergy_nonneg"
  "Towers.YM.Wall251b_H4|TheoremaAureum.Towers.YM.Wall251b.su2_plaquetteEnergy_pos_iff"
  # Wall252_KP: a MODELED Kotecký–Preiss-style smallness bound assembled as a
  # pure arithmetic combinator. `kp_sum_lt_half` proves `0 ≤ β < 48/e →
  # KP_sum β g < 1/2`, where KP_sum := zModes·kEff·C_S4·exp(−β·E_g)·e·β/11520.
  # USES all four named inputs: zModes_eq, kEff_le, c_S4_lt (→ kpModeWeight <
  # 120) and su2_plaquetteEnergy_nonneg (→ activity exp(−β·E_g) ≤ 1). All 3
  # public theorems `sorry`-free; `#print axioms` = classical trio (verified by
  # hand: lean Towers/YM/Wall252_KP.lean + #print axioms, EXIT=0). HONEST:
  # KP_sum is a MODELED single-term majorant SURROGATE, NOT the genuine
  # infinite Kotecký–Preiss polymer sum (∑ over all lattice polymers with a
  # weight a:Polymer→ℝ). This bound does NOT establish KP convergence, does
  # NOT discharge the `kotecky_preiss_criterion` sorry, and makes NO mass-gap /
  # μ>0 / Surface-#1 / RH / BSD claim. The prefactor constants are bare
  # numerics (see S4Numerics); 48/e and 11520 are tuned so the bound is tight.
  "Towers.YM.Wall252_KP|TheoremaAureum.Towers.YM.Wall252.kpModeWeight_lt"
  "Towers.YM.Wall252_KP|TheoremaAureum.Towers.YM.Wall252.kpModeWeight_nonneg"
  "Towers.YM.Wall252_KP|TheoremaAureum.Towers.YM.Wall252.kp_sum_lt_half"
  # Wall253_KP_Cluster: HONEST CONDITIONAL Kotecký–Preiss cluster-expansion
  # combinator built on Wall252's `kp_sum_lt_half` base case, in two layers.
  # (1) BASE CASE: `kp_sum_nonneg`, `kp_sum_lt_one` give 0 ≤ KP_sum β g < 1 for
  # 0 ≤ β < 48/e (from kp_sum_lt_half's < 1/2). (2) CLUSTER EXPANSION: a GENUINE
  # multi-term geometric series over ALL polymer sizes n — `kp_cluster_summable`
  # (Summable (fun n => (KP_sum β g)^n)) + `kp_cluster_sum_lt_two` (total < 2),
  # via mathlib summable_geometric_of_lt_one / tsum_geometric_of_lt_one. (3) FULL
  # POLYMER-INDEX criterion: `kp_cluster_criterion` derives Summable (∑_π
  # |activity π|) over an arbitrary (infinite) polymer index from the NAMED OPEN
  # surface hKP : Summable (|activity π|·e^{a π}) by the comparison test. All 5
  # public theorems `sorry`-free; `#print axioms` = classical trio (verified by
  # hand: lean Towers/YM/Wall253_KP_Cluster.lean + #print axioms, EXIT=0).
  # HONEST: the geometric layer is a SIZE-series MAJORANT with polymer
  # multiplicity (entropy ≈ 7^n) DROPPED — beating it needs activity < 1/7, NOT
  # the < 1/2 kp_sum_lt_half supplies, so the entropy-weighted sum is NOT shown
  # to converge. `kp_cluster_criterion` is CONDITIONAL on the OPEN surface hKP
  # (the genuine KP tree-graph/Ursell core, absent from mathlib v4.12.0), a
  # HYPOTHESIS not `by sorry`. This file proves hKP nowhere, establishes NO
  # unconditional KP convergence, does NOT touch/discharge the invariant-locked
  # `kotecky_preiss_criterion` sorry, and makes NO mass-gap / μ>0 / Surface-#1 /
  # RH / BSD claim. YM stays Status: Open.
  "Towers.YM.Wall253_KP_Cluster|TheoremaAureum.Towers.YM.Wall253.kp_sum_nonneg"
  "Towers.YM.Wall253_KP_Cluster|TheoremaAureum.Towers.YM.Wall253.kp_sum_lt_one"
  "Towers.YM.Wall253_KP_Cluster|TheoremaAureum.Towers.YM.Wall253.kp_cluster_summable"
  "Towers.YM.Wall253_KP_Cluster|TheoremaAureum.Towers.YM.Wall253.kp_cluster_sum_lt_two"
  "Towers.YM.Wall253_KP_Cluster|TheoremaAureum.Towers.YM.Wall253.kp_cluster_criterion"
  # Wall254_OS_Positivity: HONEST CONDITIONAL Osterwalder-Schrader reflection
  # positivity (OS2) combinator. gram_form_eq / gram_re_nonneg PROVE the genuine,
  # unconditional Gram positive-semidefiniteness (re ∑_{i,j} conj(c_i)c_j⟪v_i,v_j⟫
  # = re⟪Σ c_i•v_i, Σ⟫ ≥ 0 via inner_self_nonneg) — the linear-algebra heart of
  # OS positivity, bearing on NO measure. os2_of_gram_realization /
  # os2_diagonal_nonneg route OS2 for the (abstract) Wilson reflected pairing P
  # through the SINGLE NAMED OPEN surface hGNS : ∀ F G, P F G = ⟪J F, J G⟫ (the
  # Osterwalder-Seiler GNS realization of the reflected kernel as a Hilbert-space
  # Gram form) — a HYPOTHESIS, NOT `by sorry`, so NO sorryAx. All sorry-free,
  # #print axioms = classical trio (verified by hand: raw lean v4.12.0 +
  # #print axioms, EXIT=0). HONEST: this proves NO OS2 for the actual Wilson
  # measure (the entire content is the open hGNS; no Wilson measure is
  # constructed), addresses only OS2 (not OS0/1/3/4 nor the continuum limit), and
  # makes NO mass-gap / mu>0 / Surface-#1 claim; does NOT discharge the
  # invariant-locked kotecky_preiss_criterion sorry. YM stays Status: Open.
  "Towers.YM.Wall254_OS_Positivity|TheoremaAureum.Towers.YM.Wall254.gram_form_eq"
  "Towers.YM.Wall254_OS_Positivity|TheoremaAureum.Towers.YM.Wall254.gram_re_nonneg"
  "Towers.YM.Wall254_OS_Positivity|TheoremaAureum.Towers.YM.Wall254.os2_of_gram_realization"
  "Towers.YM.Wall254_OS_Positivity|TheoremaAureum.Towers.YM.Wall254.os2_diagonal_nonneg"
  # Wall255_KP_Entropy: HONEST CONDITIONAL "beat the 7^n entropy" combinator.
  # entropy_geometric_summable / entropy_geometric_tsum PROVE the genuine,
  # unconditional convergence of ∑_n 7^n·q^n = ∑_n (7q)^n (total (1-7q)⁻¹) for
  # 0≤q, 7q<1 — the 7^n entropy factor is KEPT (contrast Wall253's size-series
  # majorant, which dropped it). kp_entropy_weighted_summable beats the entropy
  # for any count N n ≤ 7^n by comparison; kp_polymer_entropy_weighted_summable
  # instantiates it at EntropyBound's genuine polymer count, CONDITIONAL on the
  # two NAMED OPEN surfaces h_entropy (connective-constant count) and q<1/7
  # (per-polymer smallness). seven_q_lt_one_of_lt_inv_seven (q<1/7 ⟹ 7q<1) and
  # seven_half_not_lt_one (¬ 7·(1/2)<1) record the honest gap: Wall252's
  # kp_sum_lt_half (<1/2) does NOT reach the <1/7 needed. All sorry-free,
  # #print axioms = classical trio (verified by hand: raw lean v4.12.0 +
  # #print axioms, EXIT=0). HONEST: the entropy is beaten ONLY under the OPEN
  # q<1/7 surface; establishes NO KP convergence (no uniform per-polymer activity
  # bound, no tree-graph weighting), makes NO mass-gap / mu>0 / Surface-#1 claim,
  # and does NOT discharge the invariant-locked kotecky_preiss_criterion sorry.
  # YM stays Status: Open.
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.seven_q_lt_one_of_lt_inv_seven"
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.seven_half_not_lt_one"
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.entropy_geometric_summable"
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.entropy_geometric_tsum"
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.kp_entropy_weighted_summable"
  "Towers.YM.Wall255_KP_Entropy|TheoremaAureum.Towers.YM.Wall255.kp_polymer_entropy_weighted_summable"
  # Wall256_MassGapConditional: HONEST CONDITIONAL Yang-Mills mass-gap apex.
  # Lands the requested statement shape `∃ Δ>0, ∀ x y, |⟨W(x)W(y)⟩| ≤ C·exp(-Δ·‖x-y‖)`
  # as a CONDITIONAL combinator mass_gap_pos_of_spectral_gap, NOT an unconditional
  # mass gap. GENUINE/UNCONDITIONAL: neg_log_pos_of_lt_one (0<ρ<1 ⟹ Δ:=-log ρ>0,
  # via Real.log_neg) and rpow_eq_exp_neg_rate (0<ρ ⟹ ρ^d = exp(-Δ·d), via
  # Real.rpow_def_of_pos) — the honest spectral-radius → exponential-clustering
  # algebra. CONDITIONAL: mass_gap_pos_of_spectral_gap derives the existential
  # from TWO NAMED OPEN surfaces (hypotheses, NOT `by sorry`, so NO sorryAx):
  # h1 : ρ<1 (the strict transfer-operator spectral gap = YM Surface #1; the real
  # T_L only has ‖T_L‖≤1 and S_min=0, locked behind kotecky_preiss_criterion) and
  # hcl : ∀ x y, |corr x y| ≤ C·ρ^(sep x y) (the KP geometric clustering output;
  # OPEN — Wall255 beats the 7^n entropy only under the open q<1/7 surface, no
  # unconditional KP exists). corr/sep are ABSTRACT; no Wilson correlator built.
  # 3 public theorems; all sorry-free, #print axioms = classical trio (verified
  # live, raw lean v4.12.0, EXIT=0). HONEST: proves NO mass gap (the entire
  # content is the open h1+hcl); ρ<1 is NOT discharged (there is no
  # kp_activity_lt_inv7; Wall255 did NOT prove q<1/7 or ρ≤1/8); makes NO mass-gap
  # / μ>0 / Surface-#1 claim and does NOT discharge kotecky_preiss_criterion.
  # YM stays Status: Open.
  "Towers.YM.Wall256_MassGapConditional|TheoremaAureum.Towers.YM.Wall256.neg_log_pos_of_lt_one"
  "Towers.YM.Wall256_MassGapConditional|TheoremaAureum.Towers.YM.Wall256.rpow_eq_exp_neg_rate"
  "Towers.YM.Wall256_MassGapConditional|TheoremaAureum.Towers.YM.Wall256.mass_gap_pos_of_spectral_gap"
  # Wall257_StrongCoupling: HONEST CONDITIONAL strong-coupling polymer-activity
  # bound. The requested "polymerActivity ≤ (1/8)^|γ|" landed as a conditional
  # combinator over a NAMED OPEN per-polymer energy lower bound hLB, NOT an
  # unconditional smallness proof. GENUINE/UNCONDITIONAL: inv8_pow_eq_exp_neg
  # ((1/8)^n = exp(-(log8)·n)), exp_neg_mul_le_inv8_pow (exp(-r·n) ≤ (1/8)^n for
  # log8 ≤ r), inv8_pow_le_inv7_pow ((1/8)^n ≤ (1/7)^n), polymerEnergy_vacuum_eq_zero
  # (vacuum energy = 0). HONEST GAP: vacuum_breaks_energy_lb PROVES hLB is FALSE
  # for c>0 (vacuum w≡1 has energy 0), so the combinator establishes NO smallness
  # of the real activity. CONDITIONAL: polymerActivity_le_inv8/inv7_of_energy_lb
  # route the integral bound through hLB (integral_mono + integrable_polymerWeight
  # + integral_const over the probability measure haarN). All sorry-free, #print
  # axioms = classical trio (verified by hand: raw lean Towers/YM/
  # Wall257_StrongCoupling.lean + #print axioms, EXIT=0). Makes NO mass-gap / μ>0
  # / Surface-#1 claim, does NOT beat the entropy, does NOT give ρ(T)<1, and does
  # NOT discharge kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.inv8_pow_eq_exp_neg"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.exp_neg_mul_le_inv8_pow"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.inv8_pow_le_inv7_pow"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.polymerEnergy_vacuum_eq_zero"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.vacuum_breaks_energy_lb"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.polymerActivity_le_inv8_of_energy_lb"
  "Towers.YM.Wall257_StrongCoupling|TheoremaAureum.Towers.YM.Wall257.polymerActivity_le_inv7_of_energy_lb"

  # Wall255_JensenObstruction: HONEST mean-energy NO-GO (the dual of Wall257's
  # vacuum_breaks_energy_lb). Via Jensen's inequality, the MEAN plaquette energy
  # can NEVER deliver the KP per-polymer smallness polymerActivity ≤ (1/8)^|γ|.
  # GENUINE/UNCONDITIONAL: plaquetteEnergy_le_two (closes the deferred Re tr ≥ -3
  # endpoint via traceRe_le_three (-P)), polymerEnergy_le_two_card, meanEnergy_nonneg,
  # meanEnergy_le_two_card, e_bar_le_two (e_bar := meanEnergy/|γ| ≤ 2),
  # inv8_pow_eq_exp_neg, and the heart jensen_obstruction (for EVERY β,
  # exp(-(β·meanEnergy)) ≤ polymerActivity, via ConvexOn.map_integral_le for the
  # convex exp against the probability measure haarN — a LOWER bound, the WRONG
  # direction for KP). CONDITIONAL: e_bar_pos_of_meanEnergy_pos and
  # mean_threshold_fails (at β₀ := log8/e_bar, (1/8)^|γ| ≤ polymerActivity) take
  # the named TRUE input hpos : 0 < meanEnergy (unprovable in mathlib v4.12.0 —
  # needs ∫tr=0 character orthogonality / Haar non-atomicity; a HYPOTHESIS, NOT
  # by sorry, so NO sorryAx). All sorry-free, #print axioms = classical trio
  # (verified by hand: raw lean Towers/YM/Wall255_JensenObstruction.lean + #print
  # axioms, EXIT=0). HONEST: isolates the genuine open problem as the
  # large-deviation RATE function, not the mean. Makes NO mass-gap / μ>0 /
  # Surface-#1 claim, establishes NO KP convergence, does NOT beat the 7^n
  # entropy, does NOT give ρ(T)<1, and does NOT discharge kotecky_preiss_criterion.
  # YM stays Status: Open.
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.plaquetteEnergy_le_two"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.polymerEnergy_le_two_card"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.meanEnergy_nonneg"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.meanEnergy_le_two_card"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.e_bar_le_two"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.e_bar_pos_of_meanEnergy_pos"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.inv8_pow_eq_exp_neg"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.jensen_obstruction"
  "Towers.YM.Wall255_JensenObstruction|TheoremaAureum.Towers.YM.Wall255Jensen.mean_threshold_fails"

  # Wall256_RateFunction: the large-deviation RATE FUNCTION criterion. HONEST
  # CONDITIONAL combinator. Program S4 → 7 → rate I(x) > log 7: per-polymer
  # activity exp(-I·n) beats the 7^n entropy iff 7·exp(-I)<1 iff exp(-I)<1/7 iff
  # log 7 < I — i.e. Wall255_KP_Entropy's q<1/7 under the dictionary q=exp(-I).
  # GENUINE/UNCONDITIONAL: exp_neg_lt_inv_seven_iff (exp(-I)<1/7 ↔ log7<I),
  # seven_exp_neg_lt_one_iff (7·exp(-I)<1 ↔ log7<I), rate_beats_entropy /
  # rate_tsum (for log7<I, ∑ₙ 7^n·exp(-I)^n Summable = (1-7·exp(-I))⁻¹, entropy
  # KEPT), rateFn + le_rateFn (Legendre transform of an ABSTRACT cgf Λ with the
  # variational lower bound), entropy_threshold_eq (log polymer_const = log 7,
  # the "→ 7" link), log_seven_pos, mean_rate_fails_criterion (¬ log7<0: the rate
  # VANISHES at the mean so the mean can NEVER meet the criterion — restates the
  # Wall255_JensenObstruction no-go). CONDITIONAL: kp_rate_summable and
  # kp_polymer_rate_summable route the genuine EntropyBound polymer count weighted
  # by exp(-I)^n through the named OPEN surfaces h_entropy (connective-constant
  # count) and h_rate : log7<I (the genuine SU(3) large-deviation rate bound,
  # absent from mathlib v4.12.0; a HYPOTHESIS, NOT by sorry, so NO sorryAx). All
  # sorry-free, #print axioms = classical trio (verified by hand: raw lean
  # Towers/YM/Wall256_RateFunction.lean + #print axioms, EXIT=0). HONEST: the rate
  # bound log7<I is the ENTIRE open content (needs Cramér/Varadhan + the SU(3)
  # log-MGF, none in mathlib); rateFn is the Legendre transform of an ABSTRACT Λ,
  # NOT the SU(3) cgf. Establishes NO KP convergence, makes NO mass-gap / μ>0 /
  # Surface-#1 claim, does NOT give ρ(T)<1, and does NOT discharge
  # kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.exp_neg_lt_inv_seven_iff"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.seven_exp_neg_lt_one_iff"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.rate_beats_entropy"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.rate_tsum"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.le_rateFn"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.entropy_threshold_eq"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.log_seven_pos"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.mean_rate_fails_criterion"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.kp_rate_summable"
  "Towers.YM.Wall256_RateFunction|TheoremaAureum.Towers.YM.Wall256Rate.kp_polymer_rate_summable"
  # Wall257_RateLowerBound: a single-site large-deviation rate that clears the
  # entropy threshold log 7 — HONEST MODELED brick (namespace Wall257Rate; the
  # Wall257 namespace is taken by Wall257_StrongCoupling). GENUINE/UNCONDITIONAL:
  # bddAbove_slopes (the Legendre slope family t·x−t² is bounded above by x²/4 via
  # (t−x/2)²≥0), quarter_sq_le_I_E (x²/4 ≤ I_E x, from Wall256Rate.le_rateFn at the
  # optimal slope t=x/2), I_E_unbounded (∀ M, ∃ x₀, M < I_E x₀ — the modeled rate
  # clears ANY bar), exists_rate_gt_log_seven (∃ x₀, log 7 < I_E x₀),
  # rate_gap_single_site_vs_polymer (the Gap Lemma: ∃ iE iP, log7<iE ∧ ¬log7<iP —
  # clearing log 7 at one site is NOT the polymer rate clearing it; reuses
  # Wall256Rate.mean_rate_fails_criterion). All sorry-free, #print axioms =
  # classical trio (verified by hand: raw lean Towers/YM/Wall257_RateLowerBound.lean
  # + #print axioms, EXIT=0). HONEST: cgfModel t := t² is a MODELED Gaussian-type
  # cgf, NOT the SU(N) plaquette log-MGF; its Legendre transform x²/4 clears any
  # threshold, so the model proves NOTHING about the real SU(N) rate (needs Cramér/
  # Varadhan + the SU(N) character integral, absent from mathlib v4.12.0).
  # Establishes NO KP convergence, makes NO mass-gap / μ>0 / Surface-#1 claim, does
  # NOT discharge kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall257_RateLowerBound|TheoremaAureum.Towers.YM.Wall257Rate.bddAbove_slopes"
  "Towers.YM.Wall257_RateLowerBound|TheoremaAureum.Towers.YM.Wall257Rate.quarter_sq_le_I_E"
  "Towers.YM.Wall257_RateLowerBound|TheoremaAureum.Towers.YM.Wall257Rate.I_E_unbounded"
  "Towers.YM.Wall257_RateLowerBound|TheoremaAureum.Towers.YM.Wall257Rate.exists_rate_gt_log_seven"
  "Towers.YM.Wall257_RateLowerBound|TheoremaAureum.Towers.YM.Wall257Rate.rate_gap_single_site_vs_polymer"
  # Wall258_DependenceDefect: the inter-polymer dependence defect — HONEST
  # CONDITIONAL combinator. Polymers sharing a lattice link are NOT independent;
  # passing from a single-site rate I_E to the polymer rate costs a defect D, so
  # the effective rate is I_E−D and beating the 7^n entropy needs the single-site
  # rate to clear the RAISED threshold log(7·C). GENUINE/UNCONDITIONAL:
  # linkIncidence_four (2(d−1)=6 at d=4, the ℤ⁴ link incidence; by decide),
  # rate_clears_after_defect (D≤log C ∧ log(7·C)<iE ⟹ log7<iE−D, via
  # log(7·C)=log7+log C), threshold_mono (log(7·C) strictly increasing in C — the
  # requested "lower the numbers" lever; pins that below log 42 needs C<6 which ℤ⁴
  # does NOT provide). CONDITIONAL: dependence_defect_kp_summable (general C>0) and
  # dependence_defect_kp_summable_Z4 (C=6, threshold log 42) route the genuine
  # EntropyBound polymer count weighted by exp(−(iE−D))^n through
  # Wall256Rate.kp_polymer_rate_summable, CONDITIONAL on NAMED OPEN hypotheses
  # h_entropy (connective-constant count), h_defect : D≤log C (the cluster-expansion
  # convergence input), h_rate : log(7·C)<iE (the genuine SU(N) rate). All
  # hypotheses, NOT axiom/sorry — so NO sorryAx and no new axioms. All sorry-free,
  # #print axioms = classical trio (linkIncidence_four = no axioms; verified by
  # hand: raw lean Towers/YM/Wall258_DependenceDefect.lean + #print axioms, EXIT=0).
  # HONEST: D≤log C is a NAMED OPEN hypothesis NOT a Lean axiom; linkIncidence is
  # the incidence FORMULA (full Finset.card count left as genuine combinatorial
  # content); "lower the numbers" is a lever, not a free lunch — ℤ⁴ pins C=6 so the
  # honest threshold is log 42, and a smaller C is a DIFFERENT geometry. Establishes
  # NO KP convergence, makes NO mass-gap / μ>0 / Surface-#1 claim, does NOT
  # discharge kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall258_DependenceDefect|TheoremaAureum.Towers.YM.Wall258.linkIncidence_four"
  "Towers.YM.Wall258_DependenceDefect|TheoremaAureum.Towers.YM.Wall258.rate_clears_after_defect"
  "Towers.YM.Wall258_DependenceDefect|TheoremaAureum.Towers.YM.Wall258.threshold_mono"
  "Towers.YM.Wall258_DependenceDefect|TheoremaAureum.Towers.YM.Wall258.dependence_defect_kp_summable"
  "Towers.YM.Wall258_DependenceDefect|TheoremaAureum.Towers.YM.Wall258.dependence_defect_kp_summable_Z4"
  # Wall259_DependenceBound: the dependence-defect REDUCTION as an HONEST
  # CONDITIONAL combinator (namespace Wall259). Makes the decomposition a
  # first-class object: polymerRate I_E Defect := I_E − Defect (the genuine
  # per-polymer rate = single-site rate minus inter-polymer dependence defect),
  # and records "single-site bound ⇒ polymer-rate criterion" as a clean reduction.
  # GENUINE/UNCONDITIONAL: polymerRate_eq (the decomposition identity
  # I_polymer = I_E − Defect, by rfl), defect_eq (dual reading Defect = I_E −
  # I_polymer), polymer_criterion_of_single_site (log 7 + Defect < I_E ⟹
  # log 7 < I_polymer), polymer_criterion_of_threshold (Defect ≤ log C ∧
  # log(7·C) < I_E ⟹ log 7 < I_polymer, via log(7·C)=log7+logC). CONDITIONAL:
  # dependence_bound_kp_summable routes the genuine EntropyBound polymer count
  # weighted by exp(−I_polymer)^n through Wall256Rate.kp_polymer_rate_summable,
  # CONDITIONAL on NAMED OPEN hypotheses h_entropy (connective-constant count),
  # h_defect : Defect ≤ log C (the cluster-expansion convergence input) and
  # h_rate : log(7·C) < I_E (the genuine SU(N) rate). All hypotheses, NOT
  # axiom/sorry — so NO sorryAx and no new axioms. All sorry-free, #print axioms
  # = classical trio (verified by hand: raw lean Towers/YM/Wall259_DependenceBound
  # .lean + #print axioms, EXIT=0). HONEST: this is a REDUCTION not a proof —
  # I_polymer is the DEFINED surrogate I_E − Defect, NOT a constructed SU(N)
  # polymer-rate functional; Defect ≤ log C is a NAMED OPEN hypothesis NOT a Lean
  # axiom, proved nowhere. Establishes NO KP convergence, makes NO mass-gap / μ>0
  # / Surface-#1 claim, discharges NO open surface, does NOT touch
  # kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall259_DependenceBound|TheoremaAureum.Towers.YM.Wall259.polymerRate_eq"
  "Towers.YM.Wall259_DependenceBound|TheoremaAureum.Towers.YM.Wall259.defect_eq"
  "Towers.YM.Wall259_DependenceBound|TheoremaAureum.Towers.YM.Wall259.polymer_criterion_of_single_site"
  "Towers.YM.Wall259_DependenceBound|TheoremaAureum.Towers.YM.Wall259.polymer_criterion_of_threshold"
  "Towers.YM.Wall259_DependenceBound|TheoremaAureum.Towers.YM.Wall259.dependence_bound_kp_summable"
  # Wall260_ClayReduction: the Clay reduction in POINTWISE dependence-defect form —
  # HONEST CONDITIONAL combinator (namespace Wall260). Split as requested: C=6 is
  # COMBINATORICS, h_defect is ANALYSIS. GENUINE/UNCONDITIONAL: C_Z4 := 6 : ℕ;
  # link_incidence_number_4d (Wall258.linkIncidence 4 = C_Z4, no axioms at all,
  # reuses linkIncidence_four); threshold_split (log(7·C)=log7+logC for C>0);
  # new_clay_reduction (from the NAMED OPEN defect bound h_defect : ∀ x, I_E x −
  # I_polymer x ≤ log C and h_rate : ∀ x, log(7·C) < I_E x conclude ∀ x, log 7 <
  # I_polymer x — rate FUNCTIONS I_E,I_polymer : ℝ→ℝ); new_clay_reduction_Z4 (C=6,
  # threshold log(7·6)=log 42 ≈ 3.73767). h_defect/h_rate are HYPOTHESES, NOT
  # axiom/sorry — so NO sorryAx and no new axioms. All sorry-free, #print axioms =
  # classical trio (link_incidence_number_4d = no axioms; verified by hand: raw
  # lean Towers/YM/Wall260_ClayReduction.lean + #print axioms, EXIT=0). HONEST: a
  # REDUCTION not a proof — despite the name it proves NO part of the Clay problem,
  # discharges NO open surface, constructs NO real SU(N) rate functional (I_E,
  # I_polymer abstract); h_defect is the NAMED OPEN cluster-expansion / Dobrushin
  # dependence input, proved nowhere. C=6 is the ℤ⁴ honest constant (threshold log
  # 42); smaller C (H4/120-cell) is a DIFFERENT geometry, deferred. Makes NO mass-
  # gap / μ>0 / Surface-#1 claim, does NOT touch kotecky_preiss_criterion. YM
  # stays Status: Open.
  "Towers.YM.Wall260_ClayReduction|TheoremaAureum.Towers.YM.Wall260.link_incidence_number_4d"
  "Towers.YM.Wall260_ClayReduction|TheoremaAureum.Towers.YM.Wall260.threshold_split"
  "Towers.YM.Wall260_ClayReduction|TheoremaAureum.Towers.YM.Wall260.new_clay_reduction"
  "Towers.YM.Wall260_ClayReduction|TheoremaAureum.Towers.YM.Wall260.new_clay_reduction_Z4"
  # Wall261_H4Defect: the H4 / 120-cell defect improvement — HONEST CONDITIONAL
  # combinator (namespace Wall261). Sequel to Wall260: where Wall260 pins ℤ⁴ C=6
  # (threshold log 42), this records the H4 improvement C = 1+φ = φ² ≈ 2.618
  # (threshold log(7·(1+φ)) ≈ log 18.33 < log 42), with the margin ε>0 from the
  # ℤ⁴-vs-H4 graph comparison. φ := (1+√5)/2. GENUINE/UNCONDITIONAL: phi_sq_eq
  # (φ²=φ+1, the golden-ratio identity ⇒ 1+φ=φ²); one_add_phi_lt_six (1+φ<6, H4
  # constant below ℤ⁴ incidence); graph_gap_pos (0 < log6 − log(1+φ), the honest
  # CONSTANT-level positive gap = "ε>0 comes from graph comparison"); h4_threshold
  # _lt_z4 (log(7·(1+φ)) < log 42). CONDITIONAL (h_rate mechanism, hypotheses NOT
  # axioms): h4_defect_beats_z4 (NAMED OPEN h_graph : Defect ≤ log(1+φ)−ε, ε>0 ⟹
  # Defect < log 6); h4_clay_reduction (feeds the NAMED OPEN H4 defect bound +
  # H4-threshold rate through Wall260.new_clay_reduction at C=1+φ ⟹ ∀x, log7 <
  # I_polymer x). All sorry-free, #print axioms = classical trio (verified by hand:
  # raw lean Towers/YM/Wall261_H4Defect.lean + #print axioms, EXIT=0). HONEST: does
  # NOT prove the real H4 spectral gap λ₂=φ (no 120-cell adjacency spectrum in
  # mathlib v4.12.0; φ enters only as the real (1+√5)/2), does NOT prove the real
  # dependence defect (Defect abstract; the H4 defect bound is a NAMED OPEN
  # hypothesis, proved nowhere). A REDUCTION/IMPROVEMENT not a proof — proves NO
  # Clay result, discharges NO open surface, NO real SU(N) rate functional. Makes
  # NO mass-gap / μ>0 / Surface-#1 claim, does NOT touch kotecky_preiss_criterion.
  # YM stays Status: Open.
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.phi_sq_eq"
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.one_add_phi_lt_six"
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.graph_gap_pos"
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.h4_threshold_lt_z4"
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.h4_defect_beats_z4"
  "Towers.YM.Wall261_H4Defect|TheoremaAureum.Towers.YM.Wall261.h4_clay_reduction"
  # Wall262_ConnectiveRatio: the connective-ratio defect bound → SU(2) polymer-rate
  # win — HONEST CONDITIONAL combinator (namespace Wall262). Sequel to Wall261:
  # encodes the "ratio of two expansion rates" R := μ_Z4/φ and lands BOTH requested
  # theorems (defect_bound via h_defect, and su2_wins) over one genuine arithmetic
  # core. GENUINE/UNCONDITIONAL: phi_lt (φ<32361/20000 from √5<2.2361); exp_lower
  # (12053/5000 ≤ e^0.88 via degree-7 Real.exp_bound — degree ≤6 misses the margin);
  # defect_bound_arith (0≤R≤1743/2000 ⟹ log(1+φR)<22/25, via log_lt_iff_lt_exp);
  # threshold_factorization (1743=3·7·83, 2000=2^4·5^3 — 0.8715 terminates).
  # CONDITIONAL (NAMED OPEN hyps, NOT axioms/sorry): defect_lt (h_defect ⟹
  # Defect<0.88); su2_wins (+ h_rate: log7+0.88≤I_E ⟹ log7<I_E−Defect, the polymer
  # criterion I_polymer=I_E−Defect). All sorry-free, #print axioms = classical trio
  # (verified live, raw lean v4.12.0 Towers/YM/Wall262_ConnectiveRatio.lean, EXIT=0).
  # HONEST: proves NO YM result; R/Defect/I_E/μ_Z4 abstract; hR/h_defect/h_rate are
  # NAMED OPEN hypotheses proved NOWHERE; μ_Z4 numeric value asserted nowhere (real
  # ≈3 ⟹ R>1 fails hR); Ursell series NOT encoded (0.8715 is the reverse-engineered
  # break-even, not a series output). Makes NO mass-gap/μ>0/Surface-#1 claim, does
  # NOT touch kotecky_preiss_criterion. YM stays Status: Open.
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.phi_lt"
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.exp_lower"
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.defect_bound_arith"
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.threshold_factorization"
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.defect_lt"
  "Towers.YM.Wall262_ConnectiveRatio|TheoremaAureum.Towers.YM.Wall262.su2_wins"
  # Wall263_CoxeterSpectral: the HONEST response to "restate Wall261 using the H4
  # Coxeter matrix M_H4, with largest eigenvalue of 2I−M_H4 = φ = 2cos(π/5)" — that
  # claimed eigenvalue identity is FALSE, and this file machine-checks why WITHOUT
  # any `axiom` (namespace Wall263). B := 2I−M_H4 is the weighted path with edge
  # weights 1,1,φ (φ is the label-5 EDGE WEIGHT, an entry of the matrix, NOT a
  # spectral quantity). GENUINE/UNCONDITIONAL: coxeterCharpoly (det(λI−B) =
  # λ⁴−(2+φ²)λ²+φ²); coxeterCharpoly_phi (value at λ=φ is −φ², a pure `ring` fact —
  # the φ⁴ cancels φ²·φ² identically, golden-ratio identity not even invoked);
  # phi_not_root (machine-checks coxeterCharpoly φ ≠ 0; the "hence NOT an
  # eigenvalue, not the largest" reading is DOCUMENTARY modulo the hand-computed
  # char poly — mathlib v4.12.0 has no det_fin_four/charpoly↔eigenvalue bridge, so
  # B/det/eigenvalues are NOT formalized); phi_lt_two (only φ<2 is machine-checked;
  # documentary: true spectral radius 2cos(π/30)≈1.989∈(φ,2); NO false "degree-≥2 ⟹
  # radius-≥2" claim — the A₄ path refutes it); one_lt_phi (1<φ). The largest
  # eigenvalue is actually 2cos(π/30)≈1.989 (H4 Coxeter number h=30), NOT φ≈1.618.
  # CONDITIONAL (NAMED OPEN hyps, NOT axioms/sorry): defect_bound_H4 — the faithful
  # transcription of `apply KP_theorem_weighted H4_spectral_bound` over two ordinary
  # hypotheses h_spec (EffDeg x ≤ φ, the unproven leap; real KP constant is the
  # connective constant ≥6, not φ) and h_kp (the weighted-KP combinator). All
  # sorry-free, #print axioms = classical trio (verified live, raw lean v4.12.0
  # Towers/YM/Wall263_CoxeterSpectral.lean, EXIT=0). HONEST: proves NO YM result,
  # refutes the proposed eigenvalue identity, does NOT touch kotecky_preiss_criterion.
  # YM stays Status: Open.
  "Towers.YM.Wall263_CoxeterSpectral|TheoremaAureum.Towers.YM.Wall263.coxeterCharpoly_phi"
  "Towers.YM.Wall263_CoxeterSpectral|TheoremaAureum.Towers.YM.Wall263.phi_not_root"
  "Towers.YM.Wall263_CoxeterSpectral|TheoremaAureum.Towers.YM.Wall263.phi_lt_two"
  "Towers.YM.Wall263_CoxeterSpectral|TheoremaAureum.Towers.YM.Wall263.one_lt_phi"
  "Towers.YM.Wall263_CoxeterSpectral|TheoremaAureum.Towers.YM.Wall263.defect_bound_H4"
  # Wall262a_RatioModel: the HONEST version of "Theoria's" richer R-series writeup
  # (namespace Wall262a). A STANDALONE LEAF (imports only Mathlib; nothing imports
  # it; OUT of the YM dependency graph). Machine-checks only a concrete finite
  # numeric MODEL: the four invented H4 ratio weights 1,2,3/2,2; the coherent
  # 4-term R a = 1 - (a/2 + a^2/3 + a^3/16 + a^4/60); the HONEST drop-the-tail
  # reduction R a <= 1 - a/2; exp(-0.88) >= 257/1000 (via exp 0.88 <= exp 1 <
  # 2.7182818286, then invert); and the headline R(exp(-0.88)) <= 1743/2000 (margin
  # huge, true R ~ 0.73). PLUS an honest arithmetic record of the prime structure:
  # 2!,3!,4!,5! all 5-smooth; 7! = 2^4*3^2*5*7 (prime 7 enters only beyond the
  # truncation); 1743 = 3*7*83, 2000 = 2^4*5^3. The H4 Coxeter matrix / 120-cell /
  # h=30 / exponents / phi-as-highest-root-norm are DOCUMENTARY only and Theoria's
  # "largest eigenvalue of 2I-M_H4 = phi" is FALSE (it is 2cos(pi/30); see Wall263).
  # all sorry-free, #print axioms = classical trio (verified live, raw lean v4.12.0
  # Towers/YM/Wall262a_RatioModel.lean, EXIT=0). HONEST: a standalone numeric MODEL
  # with invented weights; does NOT discharge Wall262 hR; uses NO real Coxeter/H4
  # datum; proves NO YM result; discharges no open surface. YM stays Status: Open.
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.Hweight_values"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.Hweight_nonneg"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.term_nonneg"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.R_le_one_sub_half"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.exp_neg88_lower"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.R_le"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.factorial_smooth"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.seven_enters_at_seven"
  "Towers.YM.Wall262a_RatioModel|TheoremaAureum.Towers.YM.Wall262a.threshold_factorization"
)

VERIFIER_DIR="$(mktemp -d)"
AXIOM_LOG="$(mktemp)"
BUILD_LOG="$(mktemp)"
trap 'rm -f "$AXIOM_LOG" "$BUILD_LOG"; rm -rf "$VERIFIER_DIR"' EXIT

# Build a single brick module from (cleaned) source. Returns 0 iff the module
# compiles. On failure the lake build output is echoed, indented, so the final
# report shows exactly why the brick did not build from clean oleans.
build_module() {
  local module="$1"
  echo ">> build-from-clean: $module" >&2
  if lake build "$module" >"$BUILD_LOG" 2>&1; then
    return 0
  fi
  echo "error: \`lake build $module\` failed (does not compile from clean oleans):" >&2
  sed 's/^/    /' "$BUILD_LOG" >&2
  return 1
}

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

# ------------------------------------------------------------------
# Gate the wall on a real clean build (Task #240).
#
# Phase A — compile each UNIQUE brick module from the cleaned source tree
# (mathlib cache intact). A module that fails here disqualifies every brick
# that lives in it: the wall must never count a brick whose file does not
# build from clean oleans.
#
# Phase B — for each brick whose module built, run the `#print axioms` check.
#
# The loops do NOT abort on the first failure (this script runs under
# `set -e`, so each fallible call is guarded). Instead every failure is
# collected and reported per file, the wall is reported as the number of
# bricks that pass BOTH phases, and the script exits non-zero if that number
# is below the registered total.
# ------------------------------------------------------------------

declare -A MODULE_BUILT       # module -> "1" (built) / "0" (failed)
UNIQUE_MODULES=()
for entry in "${BRICKS[@]}"; do
  module="${entry%%|*}"
  if [ -z "${MODULE_BUILT[$module]+set}" ]; then
    UNIQUE_MODULES+=("$module")
    MODULE_BUILT[$module]="pending"
  fi
done

echo ">> Phase A: compile ${#UNIQUE_MODULES[@]} unique brick module(s) from clean oleans" >&2
for module in "${UNIQUE_MODULES[@]}"; do
  if build_module "$module"; then
    MODULE_BUILT[$module]="1"
  else
    MODULE_BUILT[$module]="0"
  fi
done

echo ">> Phase B: axiom-footprint check for ${#BRICKS[@]} registered brick(s)" >&2
PASSED=0
FAILURES=()
for entry in "${BRICKS[@]}"; do
  module="${entry%%|*}"
  thm="${entry#*|}"
  if [ "${MODULE_BUILT[$module]}" != "1" ]; then
    echo "skip: $thm — its module $module did not build from clean oleans." >&2
    FAILURES+=("$thm  [module $module did not compile from clean oleans]")
    continue
  fi
  if check_brick "$module" "$thm"; then
    PASSED=$((PASSED + 1))
  else
    FAILURES+=("$thm  [axiom-footprint check failed]")
  fi
done

TOTAL=${#BRICKS[@]}
echo "============================================================" >&2
echo "WALL: $PASSED / $TOTAL bricks verified (built from clean oleans + classical-trio axiom footprint)." >&2

if [ "${#FAILURES[@]}" -ne 0 ]; then
  echo "" >&2
  echo "error: ${#FAILURES[@]} registered brick(s) did NOT verify:" >&2
  for f in "${FAILURES[@]}"; do
    echo "  - $f" >&2
  done
  echo "" >&2
  echo "The reported wall ($PASSED) counts ONLY bricks that actually build from" >&2
  echo "clean oleans AND pass \`#print axioms\`. Refusing to report a healthy wall" >&2
  echo "while the tower does not build (Task #240)." >&2
  exit 1
fi

echo "ok: Towers library built from clean oleans; all $TOTAL brick(s) passed the axiom-footprint check." >&2
