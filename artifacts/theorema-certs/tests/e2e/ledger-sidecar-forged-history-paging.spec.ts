import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #187: end-to-end coverage for the prev/next archive selector
 * on the dashboard's "Recent dismissals" panel (task #168 paging on
 * top of the task #150 history log). The existing rotation spec
 * (task #185, `ledger-sidecar-forged-history-rotation.spec.ts`) only
 * asserts the rotation tab buttons are visible — it never clicks
 * them, so a regression that drops the `rotation` query param from
 * the orval-generated hook (or that breaks the panel's re-render on
 * a `setForgedAckRotation` change) would land silently.
 *
 * This spec forces one rotation, then exercises the actual paging
 * controls:
 *
 *   1. Two distinct forged-incident acks (alice, bob) under a
 *      shrunken `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES` cap so
 *      the second append rotates the live file to `.1`.
 *   2. A third ack (carol) repopulates the live file so the
 *      dashboard panel has a row to render under the banner.
 *   3. Load the dashboard against the in-process fixture and
 *      confirm the panel shows carol on the live view
 *      (`data-rotation="0"`).
 *   4. Click `btn-ledger-sidecar-forged-history-older` and assert
 *      the panel re-renders with `data-rotation="1"` and the
 *      archived rows for alice + bob.
 *   5. Re-load the panel (back to live) via the
 *      `btn-ledger-sidecar-forged-history-rotation-1` tab click as
 *      a separate path — the explicit rotation tab — to pin both
 *      paging entry points the dashboard exposes.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const LEDGER_ACK_HISTORY_URL = "**/api/ledger/sidecar-forged-ack/history*";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

function forgedSidecarBytes(marker: string): Buffer {
  return Buffer.from(
    JSON.stringify({
      lastOkAt: "2099-01-01T00:00:00.000Z",
      lastCheckedAt: "2099-01-01T00:00:00.000Z",
      marker,
    }) + "\n",
  );
}

function writeForgedSidecar(lastOkPath: string, marker: string): void {
  writeFileSync(lastOkPath, forgedSidecarBytes(marker));
}

function payloadShaFor(marker: string): string {
  return sha256(forgedSidecarBytes(marker));
}

function seedTmpLedger(tmpDir: string): {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
} {
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");
  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(hitsPath, buf);
  writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(secretPath, "ab".repeat(32) + "\n");
  return { hitsPath, checkpointPath, lastOkPath, secretPath };
}

type SeedPaths = ReturnType<typeof seedTmpLedger>;

function ackOnce(seeded: SeedPaths, marker: string, ref: string): void {
  writeForgedSidecar(seeded.lastOkPath, marker);
  const checker = createLedgerChecker(seeded);
  const r = checker.acknowledgeForgedSidecar(ref);
  if (!r.ok) {
    throw new Error(`ackOnce failed for marker=${marker}: no_incident`);
  }
  if (r.alreadyAcknowledged) {
    throw new Error(
      `ackOnce produced alreadyAcknowledged for marker=${marker} — ` +
        `prior ack file must have collided on payloadSha`,
    );
  }
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

async function bootFixture(seeded: SeedPaths): Promise<FixtureServer> {
  const checker = createLedgerChecker(seeded);
  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.get("/api/ledger/sidecar-forged-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit: number | undefined;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) limit = Math.floor(parsed);
    }
    const rawRotation = req.query["rotation"];
    let rotation: number | undefined;
    if (typeof rawRotation === "string" && rawRotation.trim() !== "") {
      const parsed = Number(rawRotation);
      if (Number.isFinite(parsed) && parsed >= 0) {
        rotation = Math.floor(parsed);
      }
    }
    res.json(checker.listForgedAckHistory(limit, rotation));
  });
  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;
  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    },
  };
}

async function installForwarders(
  page: import("@playwright/test").Page,
  getActive: () => FixtureServer,
): Promise<void> {
  const forward = async (route: Route, request: Request, suffix: string) => {
    const upstream = new URL(request.url());
    const forwarded = `${getActive().baseUrl}${suffix}${upstream.search}`;
    const postData = request.postData();
    const res = await fetch(forwarded, {
      method: request.method(),
      headers: request.headers(),
      body: postData ?? undefined,
    });
    const body = Buffer.from(await res.arrayBuffer());
    const headers: Record<string, string> = {};
    res.headers.forEach((v, k) => {
      const lk = k.toLowerCase();
      if (
        lk === "content-encoding" ||
        lk === "content-length" ||
        lk === "transfer-encoding"
      ) {
        return;
      }
      headers[k] = v;
    });
    await route.fulfill({ status: res.status, headers, body });
  };
  await page.route(LEDGER_INTEGRITY_URL, (route, request) =>
    forward(route, request, "/api/ledger/integrity"),
  );
  await page.route(LEDGER_ACK_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack"),
  );
  await page.route(LEDGER_ACK_HISTORY_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack/history"),
  );
}

test.describe(
  "dashboard: Recent dismissals prev/next archive paging (task #187)",
  () => {
    const ENV_BYTES_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES";
    const ENV_ROTS_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS";
    let prevBytes: string | undefined;
    let prevRots: string | undefined;

    test.beforeAll(() => {
      prevBytes = process.env[ENV_BYTES_KEY];
      prevRots = process.env[ENV_ROTS_KEY];
      // ~143 bytes per JSONL entry; 200 fits exactly one, the
      // second ack tips the rotator over.
      process.env[ENV_BYTES_KEY] = "200";
      process.env[ENV_ROTS_KEY] = "2";
    });

    test.afterAll(() => {
      if (prevBytes === undefined) delete process.env[ENV_BYTES_KEY];
      else process.env[ENV_BYTES_KEY] = prevBytes;
      if (prevRots === undefined) delete process.env[ENV_ROTS_KEY];
      else process.env[ENV_ROTS_KEY] = prevRots;
    });

    test("clicking 'older' / rotation-1 buttons re-renders the panel with data-rotation=1 and the archived rows", async ({
      page,
    }) => {
      const tmpDir = mkdtempSync(
        path.join(tmpdir(), "ledger-forged-history-paging-e2e-"),
      );
      const seeded = seedTmpLedger(tmpDir);
      const { lastOkPath, secretPath, hitsPath, checkpointPath } = seeded;
      const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
      const rot1 = `${historyPath}.1`;
      const rot2 = `${historyPath}.2`;

      const finalMarker = "page-final";
      const finalRef = "carol";

      let active: FixtureServer | null = null;
      try {
        // Acks 1-2 land alice + bob; the second tips the cap and
        // rotates the live log into `.1`.
        ackOnce(seeded, "page-v1", "alice");
        ackOnce(seeded, "page-v2", "bob");
        expect(existsSync(rot1)).toBe(true);

        // Ack 3 (carol) repopulates the live log with one entry so
        // the banner panel has something to render on first paint.
        ackOnce(seeded, finalMarker, finalRef);
        expect(existsSync(historyPath)).toBe(true);

        // Re-forge with the same final marker so the boot read
        // classifies the sidecar as forged AND the on-disk
        // single-incident ack file from carol still binds to it
        // (banner up + already-acked).
        writeForgedSidecar(lastOkPath, finalMarker);

        active = await bootFixture(seeded);
        await installForwarders(page, () => active!);
        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();

        const historyPanel = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history"]',
        );
        await expect(historyPanel).toBeVisible();
        await expect(historyPanel).toHaveAttribute("data-rotation", "0");

        // Live view: carol on top.
        const liveRow0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(liveRow0).toHaveAttribute("data-acked-by", finalRef);
        await expect(liveRow0).toHaveAttribute(
          "data-payload-sha",
          payloadShaFor(finalMarker),
        );
        await expect(
          page.locator('[data-testid^="row-ledger-sidecar-forged-history-"]'),
        ).toHaveCount(1);

        // The rotation strip must surface the `.1` tab; .2 must NOT
        // exist (only one rotation happened).
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-1"]',
          ),
        ).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-2"]',
          ),
        ).toHaveCount(0);

        // --- Click "older →": panel re-renders with rotation=1 ---
        await page
          .locator('[data-testid="btn-ledger-sidecar-forged-history-older"]')
          .click();
        await expect(historyPanel).toHaveAttribute("data-rotation", "1");
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-archive-label"]',
          ),
        ).toContainText("archive .1");

        // Archived rows: bob (newest) then alice. carol must NOT
        // appear here — she's only in the live log.
        const archivedRow0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(archivedRow0).toHaveAttribute("data-acked-by", "bob");
        await expect(archivedRow0).toHaveAttribute(
          "data-payload-sha",
          payloadShaFor("page-v2"),
        );
        await expect(archivedRow0).toContainText("bob");

        const archivedRow1 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-1"]',
        );
        await expect(archivedRow1).toHaveAttribute("data-acked-by", "alice");
        await expect(archivedRow1).toHaveAttribute(
          "data-payload-sha",
          payloadShaFor("page-v1"),
        );
        await expect(archivedRow1).toContainText("alice");

        await expect(
          page.locator('[data-testid^="row-ledger-sidecar-forged-history-"]'),
        ).toHaveCount(2);

        // --- Click rotation-0 (live) tab: back to carol ---
        await page
          .locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-0"]',
          )
          .click();
        await expect(historyPanel).toHaveAttribute("data-rotation", "0");
        const backToLiveRow0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(backToLiveRow0).toHaveAttribute(
          "data-acked-by",
          finalRef,
        );
        await expect(
          page.locator('[data-testid^="row-ledger-sidecar-forged-history-"]'),
        ).toHaveCount(1);

        // --- Click rotation-1 tab directly: archive re-loads ---
        await page
          .locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-1"]',
          )
          .click();
        await expect(historyPanel).toHaveAttribute("data-rotation", "1");
        const tabRow0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(tabRow0).toHaveAttribute("data-acked-by", "bob");
      } finally {
        if (active) await active.close();
        for (const p of [
          lastOkPath,
          secretPath,
          `${lastOkPath}.forged-ack`,
          historyPath,
          rot1,
          rot2,
          hitsPath,
          checkpointPath,
        ]) {
          try {
            if (existsSync(p)) unlinkSync(p);
          } catch {
            /* ignore */
          }
        }
        rmSync(tmpDir, { recursive: true, force: true });
      }
    });
  },
);
