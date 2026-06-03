# theorema-certs end-to-end tests

Playwright suite covering the dashboard SPA. Driven by
`playwright.config.ts` in this artifact.

## Two ways to run

### 1. Local dev — against the Replit workflow stack

Both `artifacts/api-server` and `artifacts/theorema-certs: web` are
already up behind the global proxy on `localhost:80`:

```bash
pnpm --filter @workspace/theorema-certs exec playwright test
```

Tests hit the real api-server. Specs that depend on Replit-seeded
ledger state (e.g. existing forged sidecars, acknowledged alerts) only
work in this mode and are NOT excluded.

### 2. Managed / CI — Playwright boots its own dev servers

```bash
PLAYWRIGHT_MANAGED_WEB_SERVER=1 CI=1 \
  pnpm --filter @workspace/theorema-certs exec playwright test
```

This is what `scripts/check-theorema-certs-e2e.sh` (the
`theorema-certs-e2e` validation workflow + `scripts/post-merge.sh`
merge gate) runs. Playwright spawns a scoped Vite dev server on
`PLAYWRIGHT_MANAGED_PORT` (default 23180) and a scoped api-server on
`PLAYWRIGHT_MANAGED_API_PORT` (default 8080), with
`reuseExistingServer: true` so it doesn't EADDRINUSE against the
long-running workflows.

Specs listed in `MANAGED_TEST_IGNORE` (top of `playwright.config.ts`)
are skipped under managed mode because they depend on real
api-server state the fresh fixture doesn't seed. Override with
`PLAYWRIGHT_DISABLE_MANAGED_IGNORE=1` if you want to reproduce the
underlying failures locally.

## Reproducing a flaky run locally

When a managed-mode test is suspected of being flaky:

```bash
# 1. Stop the long-running workflow so the managed servers own the ports cleanly.
#    (Optional — reuseExistingServer also makes "leave them running" work,
#    but a clean port avoids cross-contamination from other dashboard sessions.)

# 2. Repeat the targeted spec inside one managed-mode invocation.
PLAYWRIGHT_MANAGED_WEB_SERVER=1 CI=1 \
  pnpm --filter @workspace/theorema-certs exec playwright test \
    ledger-sidecar-forged.spec.ts \
    -g "stale checkpoint binding" \
    --repeat-each=20 --workers=1 --retries=0

# 3. Trace artefacts for each failed iteration live under
#    artifacts/theorema-certs/test-results/<spec>-<title>-chromium-repeatN/
#    Open the trace:
pnpm --filter @workspace/theorema-certs exec playwright show-trace \
  test-results/<…>/trace.zip
```

Two distinct failure shapes have been seen and have distinct root causes:

- `expect(locator).toBeVisible()` timeout → the test asserts UI state
  the API doesn't actually surface (a TEST-logic flake). Task #165's
  rewrite of the stale-binding case to a synthetic `page.route` mock
  closed this class for that test; the analysis is in the comment
  block above the test in `ledger-sidecar-forged.spec.ts`.

- `page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:23180/`
  → the managed Vite dev server died mid-suite (typically after many
  consecutive `repeat-each` iterations of the same spec). This is an
  infrastructure flake, not a test-logic flake. Re-run with fewer
  repeats per invocation, or restart the dev server between batches.

## Adding a new spec

- Put it under `tests/e2e/`. Playwright picks it up automatically.
- If the spec depends on real api-server seed state, add it to
  `MANAGED_TEST_IGNORE` so it doesn't break the CI gate, and either
  refactor to a synthetic `page.route` mock or document the manual
  reproduction recipe in the spec header.
- Prefer mocking only the endpoints the spec actually asserts against
  — the rest of the dashboard (e.g. `/api/certificates`,
  `/api/lean/verify`) talks to the managed api-server normally, which
  catches integration regressions that a fully-mocked SPA would miss.
