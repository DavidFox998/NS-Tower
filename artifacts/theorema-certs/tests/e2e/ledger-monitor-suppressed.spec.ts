import { test, expect, type Route } from "@playwright/test";

/**
 * Task #131: end-to-end coverage for the "alerts suppressed —
 * acknowledged" indicator (and its "failure mode changed while
 * silenced" companion badge) added to the Lean 4 Verification
 * monitor panel by Task #115.
 *
 * Selectors / copy under test:
 *   - `[data-testid="text-ledger-monitor-suppressed"]` renders when
 *     `monitor.lastAcknowledgedAlertId` is non-null and contains the
 *     copy "alerts suppressed — acknowledged".
 *   - `[data-testid="link-ledger-monitor-ack-id"]` has
 *     `href="#alert-<id>"` and visible text equal to the first 12
 *     chars of the id followed by an ellipsis.
 *   - `[data-testid="badge-ledger-monitor-silenced-transition"]`
 *     renders only when the live `failureMode` differs from
 *     `monitor.lastAlertedFailureMode` (and the live ledger is
 *     non-ok).
 *   - The whole suppressed block stays out of the DOM when
 *     `lastAcknowledgedAlertId` is null.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

type SuppressedOverrides = {
  status: "ok" | "mismatch";
  failureMode: string | null;
  lastAcknowledgedAlertId: string | null;
  lastAlertedFailureMode: string | null;
};

function buildLedgerIntegrityBody(overrides: SuppressedOverrides) {
  const nowIso = new Date().toISOString();
  return {
    status: overrides.status,
    failureMode: overrides.failureMode,
    reason:
      overrides.status === "ok"
        ? null
        : "Synthetic mismatch for suppressed-badge e2e coverage.",
    checkpointSize: 1024,
    checkpointSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    liveSize: 1024,
    livePrefixSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    growthBytes: 0,
    checkedAt: nowIso,
    ledgerLastModified: nowIso,
    ledgerPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    lastOkAt: nowIso,
    lastOkAgeSeconds: 5,
    lastCheckedAt: nowIso,
    lastCheckedAgeSeconds: 5,
    staleThresholdSeconds: 1800,
    stale: false,
    checkedStaleThresholdSeconds: 600,
    checkedStale: false,
    checkpointLastModified: nowIso,
    checkpointAgeSeconds: 100,
    checkpointCoverageRatio: 1,
    checkpointStaleThresholdSeconds: 2592000,
    checkpointStale: false,
    lastOkSidecarStatus: "ok",
    lastOkSidecarStatusAcknowledgedAt: null,
    monitor: {
      enabled: true,
      intervalSeconds: 300,
      lastTickAt: nowIso,
      lastAlertedFailureMode: overrides.lastAlertedFailureMode,
      lastAcknowledgedAlertId: overrides.lastAcknowledgedAlertId,
      watchdogState: "ok",
      watchdogLastFiredAt: null,
    },
  };
}

async function installLedgerIntegrityMock(
  page: import("@playwright/test").Page,
  overridesRef: { current: SuppressedOverrides },
) {
  await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildLedgerIntegrityBody(overridesRef.current)),
    });
  });
}

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function buildLedgerAlertsBody(alertId: string) {
  const ts = new Date().toISOString();
  // Pad with a generous number of filler rows so the target row is
  // genuinely off-screen at page load, making the scrollIntoView
  // assertion meaningful (otherwise it could pass trivially).
  const fillers = Array.from({ length: 40 }, (_, i) => ({
    id: `filler-alert-${i}`,
    acknowledgedAt: null,
    timestamp: ts,
    workflow: `filler-workflow-${i}`,
    message: `Filler alert ${i} — padding so the target alert row starts off-screen`,
    failureMode: "truncation",
    recovery: null,
    hitsPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    expectedSize: 1024,
    actualSize: 1024,
    expectedSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    source: "kernel._verify_checkpoint",
    delivery: { webhook: { status: "ok", error: null } },
  }));
  return {
    alerts: [
      ...fillers,
      {
        id: alertId,
        acknowledgedAt: ts,
        timestamp: ts,
        workflow: "zeta-burst-101-10000",
        message: "Target alert — the suppressed link should jump here.",
        failureMode: "truncation",
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: 1024,
        actualSize: 1024,
        expectedSha:
          "0000000000000000000000000000000000000000000000000000000000000000",
        source: "kernel._verify_checkpoint",
        delivery: { webhook: { status: "ok", error: null } },
      },
    ],
    limit: 50,
    totalReturned: fillers.length + 1,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped: 0,
    rotation: 0,
    availableRotations: [],
  };
}

test.describe("dashboard: ledger monitor suppressed badge", () => {
  test("renders the suppressed indicator with ack-id link, surfaces the silenced-transition badge when failure modes diverge, and stays absent when no alert is acknowledged", async ({
    page,
  }) => {
    const ackedId =
      "01HX9YQF8VABCDEF0123456789ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
    const overridesRef: { current: SuppressedOverrides } = {
      current: {
        status: "mismatch",
        failureMode: "truncation",
        lastAcknowledgedAlertId: ackedId,
        lastAlertedFailureMode: "truncation",
      },
    };

    await installLedgerIntegrityMock(page, overridesRef);

    // Case 1: alert acknowledged, live failure mode matches the
    // acked failure mode — suppressed paragraph visible, no
    // silenced-transition badge.
    await page.goto("/");

    const suppressed = page.locator(
      '[data-testid="text-ledger-monitor-suppressed"]',
    );
    await expect(suppressed).toBeVisible();
    await expect(suppressed).toContainText("alerts suppressed — acknowledged");
    await expect(suppressed).toHaveAttribute(
      "data-acknowledged-alert-id",
      ackedId,
    );

    const ackLink = page.locator('[data-testid="link-ledger-monitor-ack-id"]');
    await expect(ackLink).toBeVisible();
    await expect(ackLink).toHaveAttribute("href", `#alert-${ackedId}`);
    await expect(ackLink).toHaveText(`${ackedId.slice(0, 12)}…`);

    await expect(
      page.locator(
        '[data-testid="badge-ledger-monitor-silenced-transition"]',
      ),
    ).toHaveCount(0);

    // Case 2: live failure mode drifts away from the acked one
    // while the alert is still acknowledged — silenced-transition
    // badge must light up.
    overridesRef.current = {
      status: "mismatch",
      failureMode: "in_place_rewrite",
      lastAcknowledgedAlertId: ackedId,
      lastAlertedFailureMode: "truncation",
    };
    await page.reload();

    await expect(suppressed).toBeVisible();
    const transitionBadge = page.locator(
      '[data-testid="badge-ledger-monitor-silenced-transition"]',
    );
    await expect(transitionBadge).toBeVisible();
    await expect(transitionBadge).toContainText(
      "failure mode changed while silenced → in_place_rewrite",
    );

    // Case 3: control — no acknowledged alert id, the entire
    // suppressed paragraph (and its child badge) stays out of the
    // DOM.
    overridesRef.current = {
      status: "ok",
      failureMode: null,
      lastAcknowledgedAlertId: null,
      lastAlertedFailureMode: null,
    };
    await page.reload();

    await expect(
      page.locator('[data-testid="text-ledger-monitor-suppressed"]'),
    ).toHaveCount(0);
    await expect(
      page.locator('[data-testid="link-ledger-monitor-ack-id"]'),
    ).toHaveCount(0);
    await expect(
      page.locator(
        '[data-testid="badge-ledger-monitor-silenced-transition"]',
      ),
    ).toHaveCount(0);
  });

  test("clicking the ack-id link scrolls the target alert row into view and visibly highlights it (task #145)", async ({
    page,
  }) => {
    const ackedId =
      "01HX9YQF8VABCDEF0123456789ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
    const overridesRef: { current: SuppressedOverrides } = {
      current: {
        status: "mismatch",
        failureMode: "truncation",
        lastAcknowledgedAlertId: ackedId,
        lastAlertedFailureMode: "truncation",
      },
    };

    await installLedgerIntegrityMock(page, overridesRef);
    await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(buildLedgerAlertsBody(ackedId)),
      });
    });

    await page.goto("/");

    // The alerts panel renders the acked-alerts toggle hidden by
    // default; the target alert in our fixture carries
    // `acknowledgedAt`, so flip the toggle on before clicking the
    // link so the row is actually in the DOM. The link's onClick
    // handler is the surface under test; the toggle behaviour is
    // covered elsewhere.
    const acknowledgedToggle = page.locator(
      '[data-testid="checkbox-show-acknowledged-alerts"]',
    );
    await expect(acknowledgedToggle).toBeVisible();
    if (!(await acknowledgedToggle.isChecked())) {
      await acknowledgedToggle.check();
    }

    const targetRow = page.locator(`#alert-${ackedId}`);
    await expect(targetRow).toHaveCount(1);
    await expect(targetRow).toHaveAttribute("data-alert-id", ackedId);

    // Sanity: before the click, the target row must NOT be marked
    // as highlighted. (The transient class is set by the link's
    // onClick handler.)
    await expect(targetRow).not.toHaveAttribute("data-highlighted", "true");

    // Measure scroll position before; the filler rows push the target
    // off-screen so a working scrollIntoView must move the page.
    const scrollBefore = await page.evaluate(() => window.scrollY);

    const ackLink = page.locator('[data-testid="link-ledger-monitor-ack-id"]');
    await expect(ackLink).toBeVisible();
    await ackLink.click();

    // Highlight must light up synchronously when the row is in DOM.
    await expect(targetRow).toHaveAttribute("data-highlighted", "true");

    // The row must end up within the viewport — Playwright's
    // `toBeInViewport` covers the "at minimum brings it into view"
    // half of the acceptance criteria.
    await expect(targetRow).toBeInViewport();

    // And the document must have actually scrolled — not just
    // "happened to already be visible".
    const scrollAfter = await page.evaluate(() => window.scrollY);
    expect(scrollAfter).not.toEqual(scrollBefore);

    // The highlight is transient (cleared on a ~1.6s timer); we don't
    // assert on its removal because the exact timing is an
    // implementation detail and flakily timing the disappearance
    // would add no real coverage.
  });

  test("deep-linking to /#alert-<id> on a fresh page load highlights the row and brings it into view (task #163)", async ({
    page,
  }) => {
    const ackedId =
      "01HX9YQF8VABCDEF0123456789ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
    const overridesRef: { current: SuppressedOverrides } = {
      current: {
        status: "mismatch",
        failureMode: "truncation",
        lastAcknowledgedAlertId: ackedId,
        lastAlertedFailureMode: "truncation",
      },
    };

    await installLedgerIntegrityMock(page, overridesRef);
    await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(buildLedgerAlertsBody(ackedId)),
      });
    });

    // Pre-flip the acked-alerts toggle via localStorage isn't an
    // option (the dashboard initialises it to false on mount), so
    // navigate first, flip the toggle, then navigate *back* to the
    // same path with the hash baked into the URL. This mirrors the
    // user pasting a `#alert-<id>` link they kept in chat.
    await page.goto("/");
    const acknowledgedToggle = page.locator(
      '[data-testid="checkbox-show-acknowledged-alerts"]',
    );
    await expect(acknowledgedToggle).toBeVisible();
    if (!(await acknowledgedToggle.isChecked())) {
      await acknowledgedToggle.check();
    }

    // Now navigate fresh with the hash present from the start. The
    // browser will do its default jump; the dashboard's task-#163
    // useEffect must additionally fire the smooth-scroll +
    // transient amber highlight once the alerts query settles.
    await page.goto(`/#alert-${ackedId}`);

    // Toggle survives the navigation only if it's been persisted —
    // it isn't, so flip it again so the row enters the DOM.
    await expect(acknowledgedToggle).toBeVisible();
    if (!(await acknowledgedToggle.isChecked())) {
      await acknowledgedToggle.check();
    }

    const targetRow = page.locator(`#alert-${ackedId}`);
    await expect(targetRow).toHaveCount(1);
    await expect(targetRow).toHaveAttribute("data-alert-id", ackedId);

    // The deep-link load (no click) must light up the highlight
    // attribute on its own. This is the core acceptance bit.
    await expect(targetRow).toHaveAttribute("data-highlighted", "true");

    // And the row must end up within the viewport.
    await expect(targetRow).toBeInViewport();
  });
});
