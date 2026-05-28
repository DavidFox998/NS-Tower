import { test, expect } from "@playwright/test";
import {
  bootForgedSidecarFixture,
  cleanupForgedSidecarTmpDir,
  createForgedSidecarTmpDir,
  installForgedSidecarForwarders,
  payloadShaFor,
  writeForgedSidecar,
  type FixtureServer,
} from "./helpers/forged-sidecar-fixture.js";

/**
 * Task #167: end-to-end coverage for the "Recent dismissals" panel
 * (`panel-ledger-sidecar-forged-history`) added in task #150.
 *
 * The panel renders under the red forged-sidecar banner and reads
 * from `GET /api/lean/ledger/sidecar-forged-ack/history` — a rotating
 * JSONL log that survives the single-incident sidecar being replaced
 * by a later forged read. The server-side append + read path is
 * covered by `routes/ledger.integration.test.ts`, but the wiring
 * between the orval-generated `useGetSidecarForgedAckHistory` hook
 * and the dashboard panel (row ordering, `data-payload-sha` /
 * `data-acked-by` attributes, count text, and the empty-state hide)
 * had no Playwright coverage.
 *
 * This spec exercises a realistic repeat-tamper attack flow:
 *
 *   1. Forge a sidecar (payload-v1), ack it as referee "alice"
 *      (named-token path so the history row carries an attribution).
 *   2. Restart the fixture and forge with DIFFERENT bytes
 *      (payload-v2). The prior ack file is bound to the previous
 *      payload sha and gets discarded, so the banner re-fires
 *      un-acked, exactly as task #138 modelled.
 *   3. Ack the new incident as referee "bob".
 *   4. Assert the panel lists both rows newest-first: row 0 = bob /
 *      sha_v2, row 1 = alice / sha_v1, plus the "2 of last 20"
 *      count text.
 *
 * A second test covers the empty state: a forged sidecar at boot
 * with no history file on disk → the red banner is visible but the
 * dismissals panel is NOT rendered.
 *
 * Task #186: the in-process express fixture (and its inline copy of
 * the history GET handler) used to live in this file. They now live
 * in `helpers/forged-sidecar-fixture.ts`, which delegates the read
 * path to the real `readForgedAckHistory` exported from
 * `routes/ledger.ts` — so this spec stays pinned to the same parser
 * production uses.
 */

const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

const ALICE_TOKEN = "alice-named-token-fixture";
const BOB_TOKEN = "bob-named-token-fixture";
const ALICE_NAME = "alice";
const BOB_NAME = "bob";

const namedTokens = new Map<string, string | null>([
  [ALICE_TOKEN, ALICE_NAME],
  [BOB_TOKEN, BOB_NAME],
]);

test.describe(
  "dashboard: Recent dismissals panel under the forged-sidecar banner (task #167)",
  () => {
    test("two distinct forged payloads + acks render newest-first with referee + payloadSha attribution", async ({
      page,
    }) => {
      const { tmpDir, paths } = createForgedSidecarTmpDir(
        "ledger-forged-history-e2e-",
      );
      const { lastOkPath } = paths;

      // --- Boot 1: forge payload-v1 ---
      const markerV1 = "payload-v1-history";
      const markerV2 = "payload-v2-history-distinct";
      const shaV1 = payloadShaFor(markerV1);
      const shaV2 = payloadShaFor(markerV2);
      // Sanity: the two markers really do produce distinct shas, so
      // the second ack lands a new ack file and a new history row
      // (rather than being deduped as alreadyAcknowledged).
      expect(shaV1).not.toBe(shaV2);

      writeForgedSidecar(lastOkPath, markerV1);
      let active: FixtureServer = await bootForgedSidecarFixture({
        paths,
        namedTokens,
      });

      try {
        await installForgedSidecarForwarders(page, () => active);

        // Seed alice's token in localStorage so the first ack POST
        // carries Authorization: Bearer <alice-token>. The in-fixture
        // named-token map resolves this to "alice", which the checker
        // writes into the history row's ackedBy. addInitScript must
        // run BEFORE the dashboard renders — the ack button only
        // appears when a token is present — so we cannot defer the
        // seed to a post-goto page.evaluate. To swap to bob later, we
        // queue a SECOND addInitScript before the relevant reload;
        // Playwright accumulates init scripts in registration order,
        // so the last write wins on each subsequent navigation.
        await page.addInitScript(
          ([key, token]) => {
            window.localStorage.setItem(key as string, token as string);
          },
          [REBUILD_TOKEN_STORAGE_KEY, ALICE_TOKEN],
        );

        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "false");

        // Before any ack, the "Recent dismissals" panel must NOT
        // render (empty state — no history file on disk yet).
        await expect(
          page.locator('[data-testid="panel-ledger-sidecar-forged-history"]'),
        ).toHaveCount(0);

        // --- Ack #1: alice acks payload-v1 ---
        const ackButton = page.locator(
          '[data-testid="button-ack-ledger-sidecar-forged"]',
        );
        await expect(ackButton).toBeEnabled();
        await ackButton.click();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // --- Restart with payload-v2 (DIFFERENT bytes → new sha) ---
        // The first /integrity poll after ack#1 will have written a
        // valid HMAC'd sidecar back to disk (task #110), so re-forge
        // the bytes (with a different marker, so the prior ack file
        // is stale and discarded) before booting the next fixture.
        // This is the realistic "attacker writes a NEW forged
        // payload, operator reboots" scenario from task #138, and
        // it's also the only way the banner stays visible on the
        // next reload — without re-forging, the fresh /integrity
        // call would report sidecar OK and the whole banner (with
        // the history panel under it) would unmount.
        await active.close();
        writeForgedSidecar(lastOkPath, markerV2);
        active = await bootForgedSidecarFixture({ paths, namedTokens });

        // Swap the localStorage token to bob's before the next ack.
        // Queue a SECOND addInitScript — Playwright accumulates them,
        // and the later one overwrites localStorage[key] = BOB on the
        // upcoming reload. The reload is also needed to re-poll the
        // new fixture's /integrity (un-acked v2 banner) AND to pull
        // the history file that ack#1 left on disk.
        await page.addInitScript(
          ([key, token]) => {
            window.localStorage.setItem(key as string, token as string);
          },
          [REBUILD_TOKEN_STORAGE_KEY, BOB_TOKEN],
        );
        await page.reload();

        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "false");

        // History panel now renders alice's row — the rotating log
        // on disk survived the restart even though the single-
        // incident ack file was discarded by the sha mismatch.
        const historyPanel = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history"]',
        );
        await expect(historyPanel).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-count"]',
          ),
        ).toHaveText("1 of last 20");
        const firstRow = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(firstRow).toHaveAttribute("data-acked-by", ALICE_NAME);
        await expect(firstRow).toHaveAttribute("data-payload-sha", shaV1);
        // Truncated payload sha (first 12 hex chars) is the user-
        // visible label inside the row.
        await expect(firstRow).toContainText(shaV1.slice(0, 12));
        await expect(firstRow).toContainText(ALICE_NAME);

        // --- Ack #2: bob acks payload-v2 ---
        await expect(ackButton).toBeEnabled();
        await ackButton.click();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // --- Restart with SAME payload-v2 bytes ---
        // Re-forge the same payload so the next boot's sidecar read
        // still classifies as forged (keeping the banner — and the
        // history panel under it — alive on the next reload), but
        // with the SAME sha so bob's ack file is still bound to it
        // and survives the restart. Symmetric with task #138's
        // "ack persists across restart" leg.
        await active.close();
        writeForgedSidecar(lastOkPath, markerV2);
        active = await bootForgedSidecarFixture({ paths, namedTokens });

        await page.reload();
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");
        await expect(historyPanel).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-count"]',
          ),
        ).toHaveText("2 of last 20");

        // Newest-first ordering: row-0 is bob/v2, row-1 is alice/v1.
        const row0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(row0).toHaveAttribute("data-acked-by", BOB_NAME);
        await expect(row0).toHaveAttribute("data-payload-sha", shaV2);
        await expect(row0).toContainText(shaV2.slice(0, 12));
        await expect(row0).toContainText(BOB_NAME);

        const row1 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-1"]',
        );
        await expect(row1).toHaveAttribute("data-acked-by", ALICE_NAME);
        await expect(row1).toHaveAttribute("data-payload-sha", shaV1);
        await expect(row1).toContainText(shaV1.slice(0, 12));
        await expect(row1).toContainText(ALICE_NAME);

        // Exactly two rows — no stray history entries leaking in.
        await expect(
          page.locator(
            '[data-testid^="row-ledger-sidecar-forged-history-"]',
          ),
        ).toHaveCount(2);
      } finally {
        await active.close();
        cleanupForgedSidecarTmpDir(tmpDir, paths);
      }
    });

    test("empty state: no history file on disk → panel does not render even with a forged banner up", async ({
      page,
    }) => {
      const { tmpDir, paths } = createForgedSidecarTmpDir(
        "ledger-forged-history-empty-e2e-",
      );

      writeForgedSidecar(paths.lastOkPath, "payload-empty-state");
      const active = await bootForgedSidecarFixture({ paths, namedTokens });

      try {
        await installForgedSidecarForwarders(page, () => active);
        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();

        // No ack has been performed, so the rotating history log was
        // never created. The endpoint returns `entries: []` and the
        // dashboard renders nothing for the panel (early-return on
        // `entries.length === 0`).
        await expect(
          page.locator('[data-testid="panel-ledger-sidecar-forged-history"]'),
        ).toHaveCount(0);
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-count"]',
          ),
        ).toHaveCount(0);
        await expect(
          page.locator(
            '[data-testid^="row-ledger-sidecar-forged-history-"]',
          ),
        ).toHaveCount(0);
      } finally {
        await active.close();
        cleanupForgedSidecarTmpDir(tmpDir, paths);
      }
    });
  },
);
