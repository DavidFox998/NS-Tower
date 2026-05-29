import { test, expect, type Route } from "@playwright/test";

/**
 * Task #202: end-to-end coverage for the All / Tamper / Monitor
 * segmented kind filter above the Recent ledger alerts panel
 * (added by Task #178).
 *
 * Task #178 put a three-way segmented control above the alerts panel
 * so an operator can hide watchdog ("monitor") noise and focus on
 * real tamper rows (or vice-versa). The selection is mirrored into
 * localStorage (`lean-ledger-alerts-kind-filter`) so it survives a
 * reload, and the count header reflects the active filter plus a
 * "hidden by filter" suffix when rows are filtered out. None of that
 * was pinned by an automated test, so a regression could silently let
 * watchdog noise drown out tamper rows again.
 *
 * Selectors / copy under test
 * (`artifacts/theorema-certs/src/pages/dashboard.tsx`):
 *   - `[data-testid="group-ledger-alerts-kind-filter"]` — the group
 *   - `[data-testid="btn-ledger-alerts-kind-{all,tamper,monitor}"]` —
 *     the three segmented buttons (active carries `data-active="true"`)
 *   - `[data-testid="row-ledger-alert-N"]` — a rendered alert row;
 *     monitor rows carry `data-monitor-row="true"`
 *   - `[data-testid="text-ledger-alerts-count"]` — the count header,
 *     reflecting the active filter (e.g. "(tamper only)") + the
 *     "N hidden by filter" suffix
 *
 * Fixture: a 4-row mix — 2 real tamper rows + a monitor pair
 * (`monitor_stalled` + its paired `recovered`). So the "monitor"
 * filter keeps 2 rows, the "tamper" filter keeps the other 2.
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";
const KIND_FILTER_STORAGE_KEY = "lean-ledger-alerts-kind-filter";

function deliveryOk() {
  return {
    webhook: { status: "ok", error: null },
    email: { status: "ok", error: null },
  };
}

function buildMixedAlertsResponse() {
  // Render order mirrors the array order (the route walks the ring
  // buffer most-recent-first; this fixture lists them already in
  // that order). Two tamper rows bracket a monitor pair.
  return {
    alerts: [
      {
        id: "tamper-row-a",
        acknowledgedAt: null,
        timestamp: "2026-05-28T01:30:00.000Z",
        workflow: "zeta-burst-101-10000",
        message:
          "Ledger checkpoint verification failed: live prefix sha mismatch",
        subject:
          "[MorningStar] Ledger integrity alert: zeta-burst-101-10000",
        failureMode: "hits_rewritten_in_place",
        previousFailureMode: null,
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: 1024,
        actualSize: 1024,
        expectedSha: "0".repeat(64),
        source: "kernel._verify_checkpoint",
        delivery: deliveryOk(),
      },
      {
        id: "monitor-recovered-row",
        acknowledgedAt: null,
        timestamp: "2026-05-28T01:20:00.000Z",
        workflow: "api-server",
        message:
          "The auto-integrity check has resumed — push alerts on ledger tamper are firing again",
        subject: "[MorningStar] Ledger monitor RECOVERED: api-server",
        failureMode: "recovered",
        previousFailureMode: "monitor_stalled",
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: null,
        actualSize: null,
        expectedSha: null,
        source: "api-server.checkWatchdog",
        delivery: deliveryOk(),
      },
      {
        id: "monitor-stalled-row",
        acknowledgedAt: null,
        timestamp: "2026-05-28T01:10:00.000Z",
        workflow: "api-server",
        message:
          "The auto-integrity check has stalled — push alerts on ledger tamper may not fire until the api-server is investigated",
        subject:
          "[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: api-server",
        failureMode: "monitor_stalled",
        previousFailureMode: null,
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: null,
        actualSize: null,
        expectedSha: null,
        source: "api-server.checkWatchdog",
        delivery: deliveryOk(),
      },
      {
        id: "tamper-row-b",
        acknowledgedAt: null,
        timestamp: "2026-05-28T01:00:00.000Z",
        workflow: "psi-cascade-202-20000",
        message:
          "Ledger checkpoint verification failed: sealed prefix size shrank",
        subject:
          "[MorningStar] Ledger integrity alert: psi-cascade-202-20000",
        failureMode: "hits_truncated",
        previousFailureMode: null,
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: 2048,
        actualSize: 1024,
        expectedSha: "1".repeat(64),
        source: "kernel._verify_checkpoint",
        delivery: deliveryOk(),
      },
    ],
    limit: 50,
    totalReturned: 4,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped: 0,
    rotation: 0,
    availableRotations: [],
  };
}

async function installLedgerAlertsMock(
  page: import("@playwright/test").Page,
) {
  await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildMixedAlertsResponse()),
    });
  });
}

test.describe("dashboard: ledger alerts kind filter (task #202)", () => {
  test("filters rows by kind, reflects the active filter in the count header, and restores the selection from localStorage", async ({
    page,
  }) => {
    await installLedgerAlertsMock(page);

    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const group = page.locator(
      '[data-testid="group-ledger-alerts-kind-filter"]',
    );
    await expect(group).toBeVisible();

    const allBtn = page.locator('[data-testid="btn-ledger-alerts-kind-all"]');
    const tamperBtn = page.locator(
      '[data-testid="btn-ledger-alerts-kind-tamper"]',
    );
    const monitorBtn = page.locator(
      '[data-testid="btn-ledger-alerts-kind-monitor"]',
    );
    const count = page.locator('[data-testid="text-ledger-alerts-count"]');

    const rows = page.locator('[data-testid^="row-ledger-alert-"]');
    const monitorRows = page.locator(
      '[data-testid^="row-ledger-alert-"][data-monitor-row="true"]',
    );

    // Default: no localStorage → "all" is active and every row shows.
    await expect(allBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(4);
    await expect(monitorRows).toHaveCount(2);
    await expect(count).toHaveText("4 entries");
    await expect(count).toHaveAttribute("data-kind-filter", "all");

    // Tamper: only the 2 non-monitor rows remain; the 2 monitor rows
    // are filtered out and reported as "hidden by filter".
    await tamperBtn.click();
    await expect(tamperBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(2);
    await expect(monitorRows).toHaveCount(0);
    await expect(count).toHaveAttribute("data-kind-filter", "tamper");
    await expect(count).toHaveText(
      "2 entries (tamper only) (2 hidden by filter)",
    );

    // Monitor: only the 2 monitor rows remain (the stalled + its
    // paired recovered row), the 2 tamper rows are hidden.
    await monitorBtn.click();
    await expect(monitorBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(2);
    await expect(monitorRows).toHaveCount(2);
    await expect(count).toHaveAttribute("data-kind-filter", "monitor");
    await expect(count).toHaveText(
      "2 entries (monitor only) (2 hidden by filter)",
    );

    // The active selection is mirrored into localStorage.
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          KIND_FILTER_STORAGE_KEY,
        ),
      )
      .toBe("monitor");

    // Reload with no query string — the previously selected filter is
    // restored from localStorage, not reset to "all".
    await page.reload();
    await expect(monitorBtn).toHaveAttribute("data-active", "true");
    await expect(allBtn).not.toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(2);
    await expect(monitorRows).toHaveCount(2);
    await expect(count).toHaveText(
      "2 entries (monitor only) (2 hidden by filter)",
    );

    // Returning to "all" clears the persisted value (the setter
    // removes the key on "all").
    await allBtn.click();
    await expect(allBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(4);
    await expect(count).toHaveText("4 entries");
    await expect
      .poll(() =>
        page.evaluate(
          (k) => window.localStorage.getItem(k),
          KIND_FILTER_STORAGE_KEY,
        ),
      )
      .toBeNull();
  });
});
