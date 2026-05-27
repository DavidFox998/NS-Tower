#!/bin/bash
set -e

# Diff helper. Returns 0 (true) if HEAD~1..HEAD touched any of the given
# paths, 1 (false) if not. Fails open (returns 0) when HEAD~1 is
# unreachable so the conservative path runs.
_touched() {
  if ! git rev-parse --verify --quiet HEAD~1 >/dev/null; then
    return 0
  fi
  if git diff --quiet HEAD~1 HEAD -- "$@"; then
    return 1
  fi
  return 0
}

# pnpm install — only when the dependency surface actually changed.
# Saves ~5s on the skip path. `--frozen-lockfile` would re-resolve and
# write the store on every merge otherwise, even though the resolved
# graph is identical.
if _touched pnpm-lock.yaml pnpm-workspace.yaml package.json '**/package.json'; then
  echo ">> running pnpm install --frozen-lockfile (dependency surface changed)" >&2
  pnpm install --frozen-lockfile
else
  echo ">> skipped pnpm install (no lockfile / package.json diff)" >&2
fi

# Drizzle schema push — only when the DB schema surface actually changed.
# Saves ~3s on the skip path. `db push` connects to Postgres, diffs the
# schema, and is a no-op when nothing changed — but the connect itself
# costs real time.
if _touched lib/db/src/schema lib/db/drizzle.config.ts; then
  echo ">> running pnpm --filter db push (schema surface changed)" >&2
  pnpm --filter db push
else
  echo ">> skipped pnpm --filter db push (no schema diff)" >&2
fi

# Rehydrate `.lake/packages/<pkg>/.git/` for every vendored Lake
# dependency from its committed tar under `lean-proof-towers/lake-deps/`.
# The outer repo cannot carry nested `.git/` directories, so they vanish
# on every merge and have to be restored here before any Lake operation
# can run safely. Task #76 (follow-up to Task #66).
./scripts/restore-lake-git.sh

# Guard against silent Lean proof drift. Fails the merge if `lean-proof/**`
# changed in a way that breaks the axiom-debt check or leaves VERIFY.txt stale.
# When `lake` is unavailable the check prints a visible warning and exits 0
# so merges aren't blocked in environments without a Lean toolchain.
./scripts/check-lean-proof.sh

# Tamper-surface gate (Task: post-merge 20s budget).
# -------------------------------------------------------------
# The two heavy guards below — Genesis-seal tamper-evidence (pytest,
# ~11s) and the at-rest ledger integrity check (~2s, task #53) — are
# only meaningful if the merge actually touched a file that could
# weaken tamper detection. For merges that did NOT touch the tamper
# surface (the vast majority — Lean towers, docs, frontend, etc.) we
# skip them inline and fire scripts/deep-audit.sh in the background
# instead, so the guard still runs but not on the 20s critical path.
#
# Tamper surface (any of these in the merge diff ⇒ run inline):
#   - kernel.py
#   - lean_bridge.py
#   - scripts/check-genesis-seal.py
#   - scripts/check-ledger-integrity.py
#   - data/hits.txt
#   - tests/test_morningstar.py
#
# If HEAD~1 isn't reachable (shallow clone / first commit / detached),
# we fail safe and run the heavy guards inline rather than skip.
TAMPER_PATHS=(
  kernel.py
  lean_bridge.py
  scripts/check-genesis-seal.py
  scripts/check-ledger-integrity.py
  data/hits.txt
  tests/test_morningstar.py
)
TAMPER_TOUCHED=1
if git rev-parse --verify --quiet HEAD~1 >/dev/null; then
  if git diff --quiet HEAD~1 HEAD -- "${TAMPER_PATHS[@]}"; then
    TAMPER_TOUCHED=0
  fi
else
  echo ">> post-merge: HEAD~1 unreachable; running heavy guards inline (fail-safe)" >&2
fi

if [ $TAMPER_TOUCHED -eq 1 ]; then
  # Re-verify the Genesis-seal tamper-evidence guarantees on every merge.
  # This fails the merge if anyone "fixes" check-genesis-seal.py,
  # lean_bridge._guard, or kernel.probe() in a way that weakens the
  # tamper detection covered by tests/test_morningstar.py.
  echo ">> running tests/test_morningstar.py (Genesis-seal tamper-evidence)" >&2
  python -m pytest tests/test_morningstar.py -q

  # At-rest integrity guard against silent truncation / in-place rewrite of
  # the probe ledger. The Genesis seal only covers the 9-line preamble; this
  # catches a stray truncating-write (mode 'w', Path.write_text, or a
  # shell-redirect overwrite) that preserves the preamble but wipes the
  # body. Task #53.
  echo ">> running scripts/check-ledger-integrity.py (at-rest ledger guard)" >&2
  python scripts/check-ledger-integrity.py
else
  echo ">> skipped (no tamper-surface diff); deep-audit started in background" >&2
  nohup bash scripts/deep-audit.sh >/dev/null 2>&1 &
fi

./scripts/print-direction.sh >&2
