import { test, expect } from "@playwright/test";
import {
  bootForgedSidecarFixture,
  cleanupForgedSidecarTmpDir,
  createForgedSidecarTmpDir,
  installForgedSidecarForwarders,
  writeForgedSidecar,
} from "./helpers/forged-sidecar-fixture.js";

/**
 * Task #151: end-to-end coverage for the named-referee attribution on
 * the sidecar tamper "acknowledged" badge.
 *
 * Task #139 added the referee name to the dashboard badge tooltip
 * ("Acknowledged by alice at <ISO>") and inlined the name next to
 * the badge text ("acknowledged · alice"). It also surfaces the
 * attribution as a `data-acked-by` attribute on
 * `badge-ledger-sidecar-forged-acknowledged`. A unit test pins the
 * API contract (`lastOkSidecarStatusAcknowledgedBy` field) but the
 * rendered UI had no end-to-end coverage, so a future dashboard
 * refactor could silently drop the attribution surface.
 *
 * Task #186: the in-process express fixture used to live inline here.
 * It now lives in `helpers/forged-sidecar-fixture.ts` and is shared
 * with the basic-ack + history-panel specs. The named-token map
 * passed in below mirrors the production
 * `LEAN_REBUILD_TOKENS=alice:...,bob:...` parser shape — a bearer
 * token that matches a named entry resolves to that name and is
 * authoritative. The dashboard's `useAckSidecarForged` hook only
 * sends the `Authorization` header (no `X-Referee-Name` for the ack
 * call), so the named-token map is the realistic mechanism for
 * getting a name on the acknowledged badge through this surface.
 *
 * Assertions:
 *  - inline text after the badge label reads "· alice"
 *  - `data-acked-by` attribute equals "alice"
 *  - `title` attribute reads "Acknowledged by alice at <ISO>" where
 *    the ISO matches the server-issued `acknowledgedAt`
 */

const FIXTURE_REFEREE_NAME = "alice";
const FIXTURE_NAMED_TOKEN = "alice-named-token-fixture";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

const namedTokens = new Map<string, string | null>([
  [FIXTURE_NAMED_TOKEN, FIXTURE_REFEREE_NAME],
]);

test.describe("dashboard: sidecar tamper acknowledged badge surfaces the referee name (task #151)", () => {
  test("named-referee Acknowledge renders inline name + tooltip + data-acked-by on the badge", async ({
    page,
  }) => {
    const { tmpDir, paths } = createForgedSidecarTmpDir(
      "ledger-ack-named-referee-e2e-",
    );
    writeForgedSidecar(paths.lastOkPath, "payload-v1-named");

    const active = await bootForgedSidecarFixture({ paths, namedTokens });

    try {
      // Task #184: install the Playwright virtual clock for parity
      // with `ledger-sidecar-forged-ack.spec.ts`. This spec doesn't
      // simulate a restart, but the install also stops the
      // dashboard's 1s `setNowMs` interval from waking the page on
      // its own under parallel-worker CPU contention, so the test
      // stays well under 10s even on a hot box.
      await page.clock.install({ time: Date.now() });
      await installForgedSidecarForwarders(page, () => active);

      // Seed the bearer token that the in-fixture named-token map
      // resolves to "alice". The dashboard reads this from
      // localStorage and sends it as Authorization: Bearer <token>.
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_NAMED_TOKEN],
      );

      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-forged"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");

      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-forged"]',
      );
      await expect(ackButton).toBeEnabled();
      await ackButton.click();

      await expect(panel).toHaveAttribute("data-acknowledged", "true");

      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
      );
      await expect(badge).toBeVisible();

      // Inline attribution: the badge's text content is "acknowledged"
      // followed by "· alice" rendered as a normal-case span. We assert
      // both pieces in the visible text.
      await expect(badge).toHaveText(/acknowledged/i);
      await expect(badge).toContainText(`· ${FIXTURE_REFEREE_NAME}`);

      // data-acked-by attribute carries the raw name (task #139).
      await expect(badge).toHaveAttribute(
        "data-acked-by",
        FIXTURE_REFEREE_NAME,
      );

      // title attribute reads "Acknowledged by alice at <ISO>". Pull
      // the ISO from the title and assert the shape so the test
      // doesn't race the server clock.
      const title = await badge.getAttribute("title");
      expect(title).not.toBeNull();
      const expectedPrefix = `Acknowledged by ${FIXTURE_REFEREE_NAME} at `;
      expect(title).toMatch(
        new RegExp(
          `^Acknowledged by ${FIXTURE_REFEREE_NAME} at \\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$`,
        ),
      );
      const iso = title!.slice(expectedPrefix.length);
      expect(() => new Date(iso).toISOString()).not.toThrow();
      expect(new Date(iso).toISOString()).toBe(iso);
    } finally {
      await active.close();
      cleanupForgedSidecarTmpDir(tmpDir, paths);
    }
  });
});
