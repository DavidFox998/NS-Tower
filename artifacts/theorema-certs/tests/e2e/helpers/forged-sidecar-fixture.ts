import type { Page, Route, Request } from "@playwright/test";
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
import {
  createLedgerChecker,
  readForgedAckHistory,
} from "../../../../api-server/src/routes/ledger.js";

/**
 * Shared Playwright fixture for the forged-sidecar e2e specs
 * (tasks #138, #151, #167; helper extracted by task #186).
 *
 * Three specs used to redefine the same in-process express fixture
 * around `createLedgerChecker`, each with its own copy of
 * `seedTmpLedger`, `bootFixture`, `installForwarders`, the named-
 * token POST handler, and (for the history-panel spec) a duplicate
 * `/api/ledger/sidecar-forged-ack/history` GET handler. Production
 * endpoint contracts had to be updated in three places. This helper
 * collapses all of that into one surface:
 *
 *   - `seedTmpLedger(tmpDir)`         — write hits.txt + checkpoint +
 *                                       HMAC secret in a fresh tmp dir
 *   - `bootForgedSidecarFixture({paths, namedTokens})` — boot the
 *                                       express server around a real
 *                                       `createLedgerChecker`, mount
 *                                       the integrity router, the ack
 *                                       POST (bearer-token resolution
 *                                       via `namedTokens`), and the
 *                                       history GET (delegating to
 *                                       the real `readForgedAckHistory`
 *                                       from `routes/ledger.ts` so the
 *                                       fixture does NOT re-implement
 *                                       the read logic).
 *   - `installForgedSidecarForwarders(page, getActive)` — forward the
 *                                       three dashboard endpoints to
 *                                       the currently-active fixture,
 *                                       reading `getActive()` per
 *                                       request so a mid-test fixture
 *                                       swap (simulated restart) takes
 *                                       effect on the next poll.
 *   - `writeForgedSidecar` / `forgedSidecarBytes` / `payloadShaFor` /
 *     `sha256` — deterministic forged-payload helpers.
 *
 * The `namedTokens` map carries the (token → refereeName) shape from
 * the production `LEAN_REBUILD_TOKENS=alice:...,bob:...` parser. A
 * `null` value means "valid token, but no attribution" — that's how
 * the basic task-#138 spec uses it (a single anonymous token).
 */

export const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
export const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
export const LEDGER_ACK_HISTORY_URL =
  "**/api/ledger/sidecar-forged-ack/history*";

export function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

export type ForgedSidecarPaths = {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
};

export type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

export type BootForgedSidecarFixtureOptions = {
  paths: ForgedSidecarPaths;
  /**
   * Bearer-token → referee-name map. A token with value `null` is
   * accepted but produces no attribution (the original task-#138
   * "anonymous fixture token" shape). Tokens not in the map are
   * rejected with 401.
   */
  namedTokens: Map<string, string | null>;
};

/**
 * Seed a tmp dir with a healthy sealed prefix + matching checkpoint
 * + pre-seeded HMAC secret. Returns the four file paths the
 * checker needs. The caller is responsible for writing the forged
 * sidecar at `lastOkPath` before booting the fixture.
 */
export function seedTmpLedger(tmpDir: string): ForgedSidecarPaths {
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(hitsPath, buf);
  writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  // Pre-seed the HMAC secret so the router does NOT auto-generate
  // one — the forged sidecar must be evaluated against a known
  // secret it carries no valid mac for.
  writeFileSync(secretPath, "ab".repeat(32) + "\n");
  return { hitsPath, checkpointPath, lastOkPath, secretPath };
}

export async function bootForgedSidecarFixture(
  opts: BootForgedSidecarFixtureOptions,
): Promise<FixtureServer> {
  const { paths, namedTokens } = opts;
  const checker = createLedgerChecker({
    hitsPath: paths.hitsPath,
    checkpointPath: paths.checkpointPath,
    lastOkPath: paths.lastOkPath,
    secretPath: paths.secretPath,
  });

  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.post("/api/ledger/sidecar-forged-ack", (req, res) => {
    const auth = req.headers["authorization"] ?? "";
    const match = /^Bearer\s+(.+)$/i.exec(
      Array.isArray(auth) ? (auth[0] ?? "") : auth,
    );
    const provided = match ? match[1]?.trim() : "";
    if (!provided || !namedTokens.has(provided)) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const refereeName = namedTokens.get(provided) ?? null;
    const result =
      refereeName === null
        ? checker.acknowledgeForgedSidecar()
        : checker.acknowledgeForgedSidecar(refereeName);
    if (!result.ok) {
      res.status(409).json({
        ok: false,
        error: "No forged-sidecar incident to acknowledge.",
      });
      return;
    }
    res.json({
      ok: true,
      acknowledgedAt: result.acknowledgedAt,
      alreadyAcknowledged: result.alreadyAcknowledged,
      payloadSha: result.payloadSha,
      ackedBy: result.ackedBy,
    });
  });

  // Task #150's GET history endpoint is registered in production by
  // `routes/lean.ts` (mounted on /api), not by `checker.router`.
  // Delegate to the real `readForgedAckHistory` exported from
  // `routes/ledger.ts` so the fixture does not re-implement the
  // read/parse logic — keeps the e2e and production endpoints
  // pinned to the exact same parser.
  const historyPath = `${paths.lastOkPath}.forged-ack.log.jsonl`;
  app.get("/api/ledger/sidecar-forged-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit = 20;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) {
        limit = Math.floor(parsed);
      }
    }
    const { entries } = readForgedAckHistory(historyPath, limit);
    res.json({ entries, capacity: 20 });
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

/**
 * Forward `/api/ledger/integrity`, `/api/ledger/sidecar-forged-ack`,
 * and `/api/ledger/sidecar-forged-ack/history` from the dashboard
 * to whichever fixture server is currently active. `getActive` is
 * read on every request, so flipping the fixture pointer mid-test
 * (to simulate a server restart) takes effect on the next dashboard
 * poll without re-installing routes.
 */
export async function installForgedSidecarForwarders(
  page: Page,
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

/**
 * Build the bytes of a forged hits.txt.lastok payload. `marker` lets
 * the caller vary the bytes so a second "tamper attempt" lands a
 * DIFFERENT sha256 (the ack file is bound to the prior payload's
 * sha and must be discarded when the bytes change). No HMAC field
 * → the real router's sidecar verify classifies this as `forged`.
 *
 * The timestamps are frozen so the bytes (and therefore the sha)
 * are deterministic across the re-forge calls that bracket a
 * simulated restart.
 */
export function forgedSidecarBytes(marker: string): Buffer {
  return Buffer.from(
    JSON.stringify({
      lastOkAt: "2099-01-01T00:00:00.000Z",
      lastCheckedAt: "2099-01-01T00:00:00.000Z",
      marker,
    }) + "\n",
  );
}

export function writeForgedSidecar(lastOkPath: string, marker: string): void {
  writeFileSync(lastOkPath, forgedSidecarBytes(marker));
}

export function payloadShaFor(marker: string): string {
  return sha256(forgedSidecarBytes(marker));
}

/**
 * Convenience tmp-dir creator + cleanup pair so specs don't repeat
 * the same `mkdtempSync` / `rmSync(force)` boilerplate. The cleanup
 * unlinks the sidecar-adjacent files (sidecar, secret, ack file,
 * history log) best-effort before rming the dir.
 */
export function createForgedSidecarTmpDir(prefix: string): {
  tmpDir: string;
  paths: ForgedSidecarPaths;
} {
  const tmpDir = mkdtempSync(path.join(tmpdir(), prefix));
  const paths = seedTmpLedger(tmpDir);
  return { tmpDir, paths };
}

export function cleanupForgedSidecarTmpDir(
  tmpDir: string,
  paths: ForgedSidecarPaths,
): void {
  for (const p of [
    paths.lastOkPath,
    paths.secretPath,
    `${paths.lastOkPath}.forged-ack`,
    `${paths.lastOkPath}.forged-ack.log.jsonl`,
    paths.hitsPath,
    paths.checkpointPath,
  ]) {
    try {
      if (existsSync(p)) unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
  rmSync(tmpDir, { recursive: true, force: true });
}
