import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright config for theorema-certs dashboard end-to-end tests.
 *
 * The tests drive the dashboard SPA and intercept the only API
 * endpoints they care about (`/api/ledger/integrity`,
 * `/api/ledger/sidecar-forged-ack`, …) via `page.route` so they do
 * not depend on real server state. They only need the Vite SPA to
 * be reachable at `baseURL`.
 *
 * Two ways to run:
 *
 *   1. Local dev — the standard Replit workflow stack is already up
 *      (api-server + theorema-certs), both behind the global proxy
 *      on `localhost:80`. Just:
 *        pnpm --filter @workspace/theorema-certs exec playwright test
 *
 *   2. CI / one-shot — boot an isolated Vite dev server scoped to
 *      this test run, no Replit workflow required. Triggered by
 *      `PLAYWRIGHT_MANAGED_WEB_SERVER=1`:
 *        PLAYWRIGHT_MANAGED_WEB_SERVER=1 \
 *          pnpm --filter @workspace/theorema-certs exec playwright test
 *      Task #149 / `scripts/check-theorema-certs-e2e.sh` uses this
 *      so the validation workflow doesn't have to coordinate with
 *      the long-running dev workflow.
 */
const MANAGED = process.env.PLAYWRIGHT_MANAGED_WEB_SERVER === "1";
const MANAGED_PORT = Number(process.env.PLAYWRIGHT_MANAGED_PORT ?? "23180");
const MANAGED_API_PORT = Number(
  process.env.PLAYWRIGHT_MANAGED_API_PORT ?? "8080",
);

/**
 * Specs that pass against the long-running Project workflow stack
 * (real api-server + real Vite + real ledger state) but fail under
 * the self-contained MANAGED webServer harness — typically because
 * they assert against state seeded by the real ledger that the
 * managed mode boots fresh. Tracked by follow-up #165; excluded
 * here so the CI gate stays green for everything else. NOT
 * excluded in local-dev (non-managed) mode, so contributors can
 * still run them against the proxy on :80.
 */
/**
 * Task #165 reclaimed `ledger-sidecar-forged.spec.ts` from this list
 * by rewriting its one flaky case (the "stale checkpoint binding"
 * test) as a synthetic `page.route` mock — at the time the
 * fixture-driven version could never pass deterministically because
 * the API's `buildStatusInner()` overwrote `lastOkSidecarStatus =
 * "ok"` on every /integrity call. Task #183 made that signal sticky
 * and real, and Task #205 then restored the case to a fixture-driven
 * shape (it boots a real `createLedgerRouter` over a valid-MAC
 * sidecar bound to a bogus checkpoint — see the comment block above
 * the test). All three cases in that spec are now fixture-driven.
 * Task #182 reclaimed `ledger-monitor-suppressed.spec.ts` by fixing
 * the underlying fixture bug: the spec's mocked
 * `/api/lean/ledger-alerts` payload was missing
 * `delivery.email` (and the required `subject` field), so the
 * dashboard's `droppedCount` filter threw `Cannot read properties of
 * undefined (reading 'status')` on `a.delivery.email.status`, which
 * killed the whole `panel-ledger-alerts` body and with it the
 * `checkbox-show-acknowledged-alerts` toggle the 2nd + 3rd cases
 * depend on. With both transports + `subject` added to the fixture,
 * all three cases pass deterministically under managed mode.
 */
const MANAGED_TEST_IGNORE = process.env.PLAYWRIGHT_DISABLE_MANAGED_IGNORE
  ? []
  : [];

export default defineConfig({
  testDir: "./tests/e2e",
  testIgnore: MANAGED ? MANAGED_TEST_IGNORE : [],
  // Task #166: the specs are isolation-safe by construction — each
  // fixture-driven spec opens its own random-port in-process express
  // server (`.listen(0)`) over its own `mkdtempSync` tmp dir, and the
  // mock-only specs intercept everything they assert via `page.route`.
  // No shared filesystem state, no shared port, no shared globals.
  // So we run files in parallel (`fullyParallel: false` + multi-worker
  // = file-level parallelism — one worker per spec file, tests within
  // a file still run serial, preserving any implicit ordering inside
  // a `test.describe` block).
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  // Task #184: the four watchdog / sidecar-ack specs that used to
  // need retry-on-flake under parallel workers were rewritten to
  // drive `page.clock` directly instead of waiting on the 1s tick +
  // the 30s `refetchInterval` + a real page reload, so retries on
  // CI are no longer covering for a real flake — they would only
  // mask a genuine regression. Keep at 0 in both environments.
  retries: 0,
  workers: Number(process.env.PLAYWRIGHT_WORKERS ?? "2"),
  // Task #184: back to the Playwright default (30s) now that those
  // four specs no longer wall-clock-sleep through the monitor +
  // refetch cycle. Each of them runs in well under 10s on a warm
  // machine with the fake-clock fast-forward, so the default ceiling
  // is plenty of headroom even under 2-worker CPU contention while
  // still catching real hangs fast.
  timeout: 30_000,
  reporter: "list",
  use: {
    baseURL:
      process.env.PLAYWRIGHT_BASE_URL ??
      (MANAGED ? `http://127.0.0.1:${MANAGED_PORT}` : "http://localhost:80"),
    trace: "retain-on-failure",
  },
  ...(MANAGED
    ? {
        webServer: [
          {
            // api-server: required because the dashboard's other API
            // calls (`/api/certificates`, `/api/lean/verify`, …) are
            // NOT mocked by the e2e specs. Without it, the SPA crashes
            // before the tamper banner can render. Tests still mock
            // the specific endpoints they assert against via
            // `page.route`, so the api-server only has to be alive
            // enough to keep `/api/certificates` from 500-ing.
            // Task #166: avoid the unconditional `build && start` of
            // `run dev` — esbuild over the api-server takes ~5-10s and
            // dominates managed-mode boot. Reuse `dist/index.mjs` when
            // present (the CI wrapper `scripts/check-theorema-certs-e2e.sh`
            // pre-builds it once); only fall back to a build when the
            // bundle is missing (e.g. raw local `playwright test`
            // invocations on a clean checkout). `exec` so signal
            // handling stays clean.
            command:
              "sh -c '([ -f ../api-server/dist/index.mjs ] || pnpm --filter @workspace/api-server run build) && exec pnpm --filter @workspace/api-server run start'",
            url: `http://127.0.0.1:${MANAGED_API_PORT}/api/healthz`,
            // reuseExistingServer: true so the e2e suite works in
            // both fresh-CI (port 8080 free → boot our own) and
            // dev / post-merge (the `artifacts/api-server` workflow
            // already holds 8080 → reuse it instead of EADDRINUSE-
            // crashing). Specs mock the endpoints they assert via
            // page.route, so the only requirement is that api-server
            // is alive enough not to 500 on /api/certificates.
            reuseExistingServer: true,
            timeout: 180_000,
            stdout: "pipe",
            stderr: "pipe",
            env: {
              PORT: String(MANAGED_API_PORT),
            },
          },
          {
            command: "pnpm run dev",
            cwd: ".",
            url: `http://127.0.0.1:${MANAGED_PORT}/`,
            // reuseExistingServer: true — symmetric with api-server
            // above, so dev-environment runs don't EADDRINUSE-crash
            // against the `artifacts/theorema-certs: web` workflow.
            reuseExistingServer: true,
            timeout: 120_000,
            stdout: "pipe",
            stderr: "pipe",
            env: {
              PORT: String(MANAGED_PORT),
              BASE_PATH: "/",
              // Route /api through Vite → api-server, mirroring the
              // global proxy on :80 used in normal dev.
              E2E_API_PROXY_TARGET: `http://127.0.0.1:${MANAGED_API_PORT}`,
            },
          },
        ],
      }
    : {}),
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
