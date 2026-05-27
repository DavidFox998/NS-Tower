#!/usr/bin/env bash
# check-theorema-certs-e2e.sh — Run the theorema-certs Playwright suite
# as a CI-style gate.
#
# Task #149: the `ledger-sidecar-forged-ack.spec.ts` end-to-end test
# (task #138) and its siblings under `artifacts/theorema-certs/tests/e2e/`
# previously only ran by hand. This script wraps the suite so the
# `theorema-certs-e2e` validation workflow (in `.replit`) and
# `scripts/post-merge.sh` can run it as a real merge gate, alongside
# `lean-proof` / `kernel-numerics` / `morningstar-tamper`.
#
# Behaviour mirrors `check-lean-proof.sh`:
#
#   * STRICT mode (env `STRICT_E2E_CHECK=1`, set by the CI workflow):
#     missing Chromium browser / system deps is a HARD FAILURE — the
#     check exits non-zero so a future regression in browser availability
#     can never silently pass.
#
#   * Lenient mode (default, e.g. on a fresh local clone with no
#     browsers installed): missing Chromium prints a loud WARN and
#     exits 0 so an unrelated merge isn't blocked just because the
#     contributor's box happens to not have Playwright browsers
#     cached. Once Chromium is present, the suite always runs.
#
# The Playwright config boots an isolated Vite dev server on
# PLAYWRIGHT_MANAGED_PORT (default 23180) when
# PLAYWRIGHT_MANAGED_WEB_SERVER=1, so this script does not require the
# long-running `artifacts/theorema-certs: web` workflow to be up.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STRICT="${STRICT_E2E_CHECK:-0}"

warn() {
  printf '\n[check-theorema-certs-e2e] WARN: %s\n' "$1" >&2
}

fatal() {
  printf '\n[check-theorema-certs-e2e] FATAL: %s\n' "$1" >&2
  exit 1
}

# 1. pnpm must exist. In every CI surface that calls us (`.replit`
#    validation workflow + post-merge.sh) it is guaranteed to be
#    present, so missing pnpm is always a hard fail regardless of
#    strict mode.
if ! command -v pnpm >/dev/null 2>&1; then
  fatal "pnpm not on PATH — cannot run @workspace/theorema-certs tests."
fi

# 2. Try to install Chromium if it's not already cached. Playwright
#    keeps browsers in ~/.cache/ms-playwright by default; if that
#    directory is empty or missing, `playwright install chromium` is
#    a no-op when already present and a download otherwise. We
#    deliberately do NOT pass `--with-deps` — that path shells out
#    to apt and is meaningless on NixOS. System libs (glib, nss,
#    libgbm, libGL, …) are pinned via `.replit`'s nix.packages list.
echo "[check-theorema-certs-e2e] ensuring Chromium is installed…" >&2
if ! pnpm --filter @workspace/theorema-certs exec playwright install chromium >/tmp/pw-install.log 2>&1; then
  tail -n 40 /tmp/pw-install.log >&2 || true
  if [[ "$STRICT" == "1" ]]; then
    fatal "playwright install chromium failed in strict mode."
  fi
  warn "playwright install chromium failed; skipping e2e suite (lenient mode)."
  exit 0
fi

# 3. Confirm the browser binary actually launches. Even with the
#    download in place, missing nix-provided shared libraries on the
#    host will make Chromium SIGABRT on first launch — better to
#    surface that as a clear failure than to let the suite time out
#    waiting for a page to load.
LAUNCH_PROBE=$(pnpm --filter @workspace/theorema-certs exec node -e '
  const { chromium } = require("@playwright/test");
  chromium.launch().then(async (b) => {
    await b.close();
    console.log("OK");
  }).catch((e) => {
    console.error(String(e && e.message ? e.message : e));
    process.exit(1);
  });
' 2>&1) || LAUNCH_FAILED=1

if [[ "${LAUNCH_FAILED:-0}" == "1" ]]; then
  echo "$LAUNCH_PROBE" >&2
  if [[ "$STRICT" == "1" ]]; then
    fatal "Chromium failed to launch in strict mode — check nix.packages for missing libs (glib, nss, libgbm, libGL, …)."
  fi
  warn "Chromium failed to launch; skipping e2e suite (lenient mode)."
  exit 0
fi

# 4. Run the suite. PLAYWRIGHT_MANAGED_WEB_SERVER=1 tells the
#    Playwright config to boot its own Vite dev server scoped to
#    this process, so we don't depend on the long-running dashboard
#    workflow being up.
echo "[check-theorema-certs-e2e] running Playwright suite…" >&2
PLAYWRIGHT_MANAGED_WEB_SERVER=1 CI=1 \
  pnpm --filter @workspace/theorema-certs exec playwright test
