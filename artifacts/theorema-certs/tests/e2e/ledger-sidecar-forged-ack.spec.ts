import { test, expect } from "@playwright/test";
import { existsSync } from "node:fs";
import {
  bootForgedSidecarFixture,
  cleanupForgedSidecarTmpDir,
  createForgedSidecarTmpDir,
  installForgedSidecarForwarders,
  writeForgedSidecar,
  type FixtureServer,
} from "./helpers/forged-sidecar-fixture.js";

/**
 * Task #138: end-to-end coverage for the sidecar tamper banner's
 * Acknowledge button (`button-ack-ledger-sidecar-forged`) and its
 * sticky acknowledged-state across server restarts.
 *
 * Task #124 made the red "Sidecar tamper detected" banner
 * (`panel-ledger-sidecar-forged`) sticky: clicking Acknowledge
 * persists an `acknowledgedAt` to a sibling ack file
 * (`data/hits.txt.lastok.forged-ack`) bound to the sha256 of the
 * forged payload. The banner stays visible (with an "acknowledged"
 * badge) until a non-forged sidecar is read on the next boot, OR a
 * fresh tamper attempt with DIFFERENT bytes lands — in which case
 * the stale ack is dropped and the banner re-fires un-acked.
 *
 * Task #186: the in-process express fixture used to live inline in
 * this file. It now lives in `helpers/forged-sidecar-fixture.ts`
 * and is shared with the named-referee + history-panel specs so
 * production endpoint contract changes only have to be reflected
 * in one place.
 *
 * "Restart" is modeled by closing the express server, tearing down
 * the checker, and constructing a fresh `createLedgerChecker` over
 * the SAME tmp dir — exactly what a real process restart does: the
 * forged sidecar + ack file are re-read from disk.
 *
 * The dashboard authenticates the ack POST with the token it pulls
 * from `localStorage["lean-rebuild-token"]`, so we seed that via
 * `page.addInitScript` before navigating.
 *
 * Task #184: the two "simulated restart" phases used to call
 * `page.reload()` to make the dashboard pick up the rebooted fixture
 * server. That paid the Vite SPA cold-start cost twice per test on
 * top of the real express restart, which pushed the spec into the
 * 30s default per-test timeout under parallel-worker CPU contention.
 * Replaced with `page.clock.fastForward("31s")` so the dashboard's
 * 30s integrity `refetchInterval` fires inside the SAME page session
 * — the helper's forwarder reads `getActive()` on every request, so
 * the refetch lands on the rebooted fixture without any reload, and
 * the assertions hold against the same observable state.
 */

const FIXTURE_TOKEN = "fixture-referee-token";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
// 31s — just past the 30s `refetchInterval` on
// `useGetLedgerIntegrity`, so a single fastForward triggers exactly
// one /integrity refetch through the page.route forwarder.
const INTEGRITY_REFETCH_TICK_MS = 31_000;

// Single anonymous fixture token — no referee-name attribution.
// `null` value means "accept this token but don't pass a name to
// `acknowledgeForgedSidecar`", matching the original task-#138 shape.
const namedTokens = new Map<string, string | null>([[FIXTURE_TOKEN, null]]);

test.describe("dashboard: sidecar tamper banner Acknowledge button (task #138)", () => {
  test("clicking Acknowledge persists across restart, and a fresh tamper attempt re-fires un-acked", async ({
    page,
  }) => {
    const { tmpDir, paths } = createForgedSidecarTmpDir("ledger-ack-e2e-");
    const { lastOkPath } = paths;

    // Initial forged payload — boot 1.
    writeForgedSidecar(lastOkPath, "payload-v1");

    let active: FixtureServer = await bootForgedSidecarFixture({
      paths,
      namedTokens,
    });

    try {
      // Install Playwright's virtual clock so the two simulated
      // restart phases below can advance past the dashboard's 30s
      // integrity refetchInterval without sleeping. Anchor at real
      // `Date.now()` so any baked-in age math in the rendered card
      // stays sensible.
      await page.clock.install({ time: Date.now() });
      await installForgedSidecarForwarders(page, () => active);

      // Seed the referee token in localStorage so the dashboard
      // sends Authorization: Bearer <token> on the ack POST and so
      // the Acknowledge button renders (it's gated on rebuildToken).
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_TOKEN],
      );

      // --- Boot 1: banner visible, un-acked ---
      await page.goto("/");
      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-forged"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-forged"]',
      );
      await expect(ackButton).toBeVisible();
      await expect(ackButton).toBeEnabled();
      await expect(ackButton).toHaveText(/^Acknowledge$/);
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toHaveCount(0);

      // --- Click Acknowledge ---
      await ackButton.click();

      // After the POST resolves + the query is invalidated, the
      // panel must flip to data-acknowledged="true", the badge must
      // render, and the button must read "Acknowledged" and be
      // disabled (gated on lastOkSidecarStatusAcknowledgedAt).
      await expect(panel).toHaveAttribute("data-acknowledged", "true");
      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
      );
      await expect(badge).toBeVisible();
      await expect(badge).toHaveText(/acknowledged/i);
      await expect(ackButton).toBeDisabled();
      await expect(ackButton).toHaveText(/^Acknowledged$/);

      // The ack file must have been persisted to disk — that's the
      // mechanism that survives the restart.
      const ackPath = `${lastOkPath}.forged-ack`;
      expect(existsSync(ackPath)).toBe(true);

      // --- Restart: same forged file, same ack file → still acked ---
      // The first /integrity poll after boot writes a valid HMAC'd
      // sidecar back to disk (task #110), so we must re-write the
      // SAME forged bytes before tearing down to model the realistic
      // "attacker writes the forged payload again, operator reboots"
      // scenario. Same bytes → same sha → ack file still applies.
      await active.close();
      writeForgedSidecar(lastOkPath, "payload-v1");
      active = await bootForgedSidecarFixture({ paths, namedTokens });

      // Trigger the dashboard's 30s integrity refetch — the
      // forwarder reads `getActive()` per request, so the refetch
      // lands on the newly-rebooted fixture without any SPA reload.
      await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "true");
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toBeVisible();
      await expect(ackButton).toBeDisabled();
      await expect(ackButton).toHaveText(/^Acknowledged$/);

      // --- Fresh tamper attempt: different bytes → new payload sha
      // → stale ack discarded → banner re-fires un-acked ---
      await active.close();
      writeForgedSidecar(lastOkPath, "payload-v2-different-bytes");
      active = await bootForgedSidecarFixture({ paths, namedTokens });

      // Same trick: advance the page clock past the integrity
      // refetchInterval so the dashboard re-polls the (now-fresh)
      // fixture and the changed payload sha drops the stale ack.
      await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toHaveCount(0);
      await expect(ackButton).toBeEnabled();
      await expect(ackButton).toHaveText(/^Acknowledge$/);
    } finally {
      await active.close();
      cleanupForgedSidecarTmpDir(tmpDir, paths);
    }
  });
});
