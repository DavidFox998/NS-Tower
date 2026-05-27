#!/bin/bash
# scripts/deep-audit.sh
# ---------------------
# Heavy post-merge guards moved off the 20s post-merge.sh critical path.
#
# Runs:
#   1. pytest tests/test_morningstar.py  (Genesis-seal tamper-evidence, ~11s)
#   2. scripts/check-ledger-integrity.py (at-rest ledger truncation guard, ~2s, task #53)
#
# Invocation:
#   - Backgrounded by scripts/post-merge.sh when the merge does NOT touch the
#     tamper surface (kernel.py, lean_bridge.py, scripts/check-genesis-seal.py,
#     scripts/check-ledger-integrity.py, data/hits.txt, tests/test_morningstar.py).
#   - Can also be run by hand: `bash scripts/deep-audit.sh`.
#
# Output:
#   - All stdout/stderr appended to data/deep-audit.log so a backgrounded run
#     (`nohup ... >/dev/null 2>&1 &`) is still inspectable after the fact.
#   - Final line is either "deep-audit: OK <iso8601>" or "deep-audit: FAIL
#     <iso8601> step=<name> rc=<code>" so `tail -1 data/deep-audit.log` is a
#     one-shot health signal.
#
# Failure posture:
#   - Does NOT block the merge (post-merge.sh has already returned 0 by the
#     time this runs in the skip path). A real tamper-surface diff would have
#     been gated *into* post-merge.sh and blocked there.
#   - On FAIL, the per-process MORNINGSTAR_ALERT_WEBHOOK_URL / SMTP sink is
#     NOT auto-fired here (those are wired into check-ledger-integrity.py's
#     own FATAL path; pytest failures are surfaced via the log line).

set -u  # NOT -e — we want to record both step results, not bail on first failure.

cd "$(dirname "$0")/.."

LOG="data/deep-audit.log"
mkdir -p data

ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

{
  echo "=========================================================="
  echo "deep-audit: START $(ts) pid=$$"
  echo "=========================================================="
} >> "$LOG"

run_step() {
  local name="$1"; shift
  local rc=0
  echo ">> $(ts) step=$name :: $*" >> "$LOG"
  "$@" >> "$LOG" 2>&1 || rc=$?
  echo "<< $(ts) step=$name rc=$rc" >> "$LOG"
  return $rc
}

OVERALL_RC=0
FAIL_STEP=""

# NOTE: capture rc immediately after run_step. Using `if ! run_step ...;
# then OVERALL_RC=$?` would capture the exit code of the *negated test*
# (always 0 inside the `then` branch), silently reporting failures as OK.
run_step "morningstar-tamper" python -m pytest tests/test_morningstar.py -q
RC=$?
if [ $RC -ne 0 ]; then
  OVERALL_RC=$RC
  FAIL_STEP="morningstar-tamper"
fi

run_step "check-ledger-integrity" python scripts/check-ledger-integrity.py
RC=$?
if [ $RC -ne 0 ] && [ $OVERALL_RC -eq 0 ]; then
  # Record the first failure; do not overwrite if morningstar already failed.
  OVERALL_RC=$RC
  FAIL_STEP="check-ledger-integrity"
fi

if [ $OVERALL_RC -eq 0 ]; then
  echo "deep-audit: OK $(ts)" >> "$LOG"
else
  echo "deep-audit: FAIL $(ts) step=$FAIL_STEP rc=$OVERALL_RC" >> "$LOG"
fi

exit $OVERALL_RC
