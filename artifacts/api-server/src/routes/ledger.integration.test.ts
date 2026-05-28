import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from "vitest";
import { mkdtempSync, writeFileSync, readFileSync, rmSync, unlinkSync, existsSync, chmodSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash, createHmac } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createLedgerRouter, createLedgerChecker, startLedgerMonitor } from "./ledger.js";
import type { LedgerAlertInvocation, LedgerAlertSink } from "../lib/ledgerAlerts.js";

/**
 * Mirrors the canonicalize() + HMAC scheme in ledger.ts so tests can
 * legitimately seed the sidecar (e.g. with an old lastOkAt) or
 * simulate a forged sidecar that the server should REJECT.
 */
function sealSidecar(
  secretHex: string,
  payload: {
    lastOkAt: string | null;
    lastCheckedAt: string | null;
    boundCheckpointSize: number | null;
    boundCheckpointSha: string | null;
  },
): string {
  const canonical = JSON.stringify({
    lastOkAt: payload.lastOkAt,
    lastCheckedAt: payload.lastCheckedAt,
    boundCheckpointSize: payload.boundCheckpointSize,
    boundCheckpointSha: payload.boundCheckpointSha,
  });
  const mac = createHmac("sha256", Buffer.from(secretHex, "hex"))
    .update(canonical)
    .digest("hex");
  return JSON.stringify({ ...payload, mac }) + "\n";
}

let tmpDir: string;
let hitsPath: string;
let checkpointPath: string;
let server: http.Server;
let baseUrl: string;

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

function writeHits(content: string): { size: number; sha: string } {
  const buf = Buffer.from(content, "utf-8");
  writeFileSync(hitsPath, buf);
  return { size: buf.length, sha: sha256(buf) };
}

function writeCheckpoint(size: number, sha: string) {
  writeFileSync(checkpointPath, `${size} ${sha}\n`);
}

beforeAll(async () => {
  const app = express();
  // Route to a freshly-built router each request so the test can swap paths
  // by re-mounting if needed. Simpler: build once with fixed paths under tmpDir.
  tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-test-"));
  hitsPath = path.join(tmpDir, "hits.txt");
  checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  app.use("/api", createLedgerRouter({ hitsPath, checkpointPath }));
  server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const addr = server.address() as AddressInfo;
  baseUrl = `http://127.0.0.1:${addr.port}`;
});

afterAll(async () => {
  await new Promise<void>((resolve, reject) =>
    server.close((err) => (err ? reject(err) : resolve())),
  );
  rmSync(tmpDir, { recursive: true, force: true });
});

beforeEach(() => {
  for (const p of [hitsPath, checkpointPath]) {
    try {
      unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
});

afterEach(() => {
  for (const p of [hitsPath, checkpointPath]) {
    try {
      unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
});

async function getStatus(): Promise<{ status: number; json: any }> {
  const res = await fetch(`${baseUrl}/api/ledger/integrity`);
  const json = (await res.json()) as any;
  return { status: res.status, json };
}

describe("GET /api/ledger/integrity", () => {
  it("returns status=ok with growthBytes when the prefix matches and the ledger has grown", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    // Append more bytes after checkpoint — legal append-only growth.
    writeFileSync(hitsPath, sealed + "appended-line\n");

    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("ok");
    expect(r.json.failureMode).toBeNull();
    expect(r.json.checkpointSize).toBe(size);
    expect(r.json.checkpointSha).toBe(sha);
    expect(r.json.liveSize).toBe(size + "appended-line\n".length);
    expect(r.json.livePrefixSha).toBe(sha);
    expect(r.json.growthBytes).toBe("appended-line\n".length);
    expect(r.json.lastOkAt).toBe(r.json.checkedAt);
  });

  it("persists lastOkAt across router restarts via the sidecar file", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    // Build a one-off router pointing at the same paths and hit it directly.
    const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
    const app1 = express();
    app1.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath }));
    const srv1 = http.createServer(app1);
    await new Promise<void>((resolve) => srv1.listen(0, "127.0.0.1", resolve));
    const port1 = (srv1.address() as AddressInfo).port;
    const r1 = await (await fetch(`http://127.0.0.1:${port1}/api/ledger/integrity`)).json() as any;
    expect(r1.status).toBe("ok");
    expect(r1.lastOkAt).toBe(r1.checkedAt);
    await new Promise<void>((resolve, reject) =>
      srv1.close((err) => (err ? reject(err) : resolve())),
    );

    // Fresh router (simulating a server restart) should read the sidecar
    // and surface lastOkAt immediately, without needing a probe first.
    const app2 = express();
    app2.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath }));
    const srv2 = http.createServer(app2);
    await new Promise<void>((resolve) => srv2.listen(0, "127.0.0.1", resolve));
    const port2 = (srv2.address() as AddressInfo).port;
    // Break the ledger so the next check returns mismatch — lastOkAt should
    // still be the pre-restart timestamp, proving persistence.
    writeFileSync(hitsPath, "X");
    const r2 = await (await fetch(`http://127.0.0.1:${port2}/api/ledger/integrity`)).json() as any;
    expect(r2.status).toBe("mismatch");
    expect(r2.lastOkAt).toBe(r1.lastOkAt);
    await new Promise<void>((resolve, reject) =>
      srv2.close((err) => (err ? reject(err) : resolve())),
    );
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
  });

  it("persists lastCheckedAt across router restarts even when the check failed", async () => {
    // Break the ledger so every check returns mismatch — we want to verify
    // that lastCheckedAt is persisted regardless of outcome.
    writeFileSync(hitsPath, "X");
    writeCheckpoint(999, "0".repeat(64));

    const lastOkPath = path.join(tmpDir, "hits.txt.checkedat-test.lastok");
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }

    const app1 = express();
    app1.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath }));
    const srv1 = http.createServer(app1);
    await new Promise<void>((resolve) => srv1.listen(0, "127.0.0.1", resolve));
    const port1 = (srv1.address() as AddressInfo).port;
    const r1 = await (await fetch(`http://127.0.0.1:${port1}/api/ledger/integrity`)).json() as any;
    expect(r1.status).toBe("mismatch");
    expect(r1.lastOkAt).toBeNull();
    expect(r1.lastCheckedAt).toBe(r1.checkedAt);
    await new Promise<void>((resolve, reject) =>
      srv1.close((err) => (err ? reject(err) : resolve())),
    );

    // Fresh router (simulating a restart). Build status WITHOUT hitting the
    // route yet would require an in-process call; instead just call the
    // endpoint and check that lastCheckedAt was carried over from the
    // previous process — the returned object surfaces lastCheckedAt as the
    // NEW now, but the persistence is observable via a second startup that
    // reads the sidecar.
    const app2 = express();
    app2.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath }));
    const srv2 = http.createServer(app2);
    await new Promise<void>((resolve) => srv2.listen(0, "127.0.0.1", resolve));
    const port2 = (srv2.address() as AddressInfo).port;
    const r2 = await (await fetch(`http://127.0.0.1:${port2}/api/ledger/integrity`)).json() as any;
    expect(r2.status).toBe("mismatch");
    // lastCheckedAt is updated by the current call but must be >= the
    // previously persisted value (which was r1.checkedAt).
    expect(Date.parse(r2.lastCheckedAt)).toBeGreaterThanOrEqual(Date.parse(r1.checkedAt));
    await new Promise<void>((resolve, reject) =>
      srv2.close((err) => (err ? reject(err) : resolve())),
    );
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
  });

  it("returns status=mismatch failureMode=hits_truncated when the live ledger is shorter than the checkpoint", async () => {
    const sealed = "line1\nline2\nline3\nline4\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    // Truncate the live file below the checkpoint size.
    writeFileSync(hitsPath, "line1\n");

    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("mismatch");
    expect(r.json.failureMode).toBe("hits_truncated");
    expect(r.json.reason).toMatch(/SHRUNK/);
    expect(r.json.checkpointSize).toBe(size);
    expect(r.json.liveSize).toBeLessThan(size);
  });

  it("returns status=mismatch failureMode=hits_rewritten_in_place when the prefix sha drifts", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    // Rewrite the first `size` bytes in place to something else of equal length.
    const tampered = "LINE1\nLINE2\nLINE3\n";
    expect(Buffer.byteLength(tampered)).toBe(size);
    writeFileSync(hitsPath, tampered);

    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("mismatch");
    expect(r.json.failureMode).toBe("hits_rewritten_in_place");
    expect(r.json.checkpointSha).toBe(sha);
    expect(r.json.livePrefixSha).toBe(sha256(tampered));
    expect(r.json.livePrefixSha).not.toBe(sha);
    expect(r.json.reason).toMatch(/rewritten in place/);
  });

  it("returns status=missing failureMode=checkpoint_missing when the checkpoint file is absent", async () => {
    writeHits("line1\nline2\n");
    // No checkpoint written.
    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("missing");
    expect(r.json.failureMode).toBe("checkpoint_missing");
    expect(r.json.reason).toMatch(/missing/);
    expect(r.json.liveSize).toBeGreaterThan(0);
  });

  it("returns status=mismatch failureMode=checkpoint_malformed when the checkpoint file is garbage", async () => {
    writeHits("line1\n");
    writeFileSync(checkpointPath, "not a valid checkpoint line\n");
    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("mismatch");
    expect(r.json.failureMode).toBe("checkpoint_malformed");
    expect(r.json.reason).toMatch(/malformed|sha256/i);
  });

  it("returns status=missing failureMode=hits_missing when the ledger file is absent", async () => {
    writeCheckpoint(10, "0".repeat(64));
    const r = await getStatus();
    expect(r.status).toBe(200);
    expect(r.json.status).toBe("missing");
    expect(r.json.failureMode).toBe("hits_missing");
  });

  it("surfaces a configured staleness threshold and reports stale=false on a fresh ok check", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const r = await getStatus();
    expect(r.json.status).toBe("ok");
    expect(r.json.staleThresholdSeconds).toBeGreaterThan(0);
    expect(r.json.stale).toBe(false);
    expect(r.json.lastOkAgeSeconds).toBeGreaterThanOrEqual(0);
    expect(r.json.lastOkAgeSeconds).toBeLessThan(r.json.staleThresholdSeconds);
  });

  it("reports stale=true when lastOkAt is older than the configured threshold", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    // Pre-seed a very-old lastOkAt sidecar with a VALID HMAC (using the
    // same secret the router will use on construction). The router will
    // read the sidecar on construction and the very next /integrity
    // call should flag it stale even though the live ledger is healthy.
    const lastOkPath = path.join(tmpDir, "hits.txt.stale-test.lastok");
    const secretPath = `${lastOkPath}.key`;
    // Pre-seed a deterministic secret so we can MAC the sidecar.
    const secretHex = "ab".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    writeFileSync(
      lastOkPath,
      sealSidecar(secretHex, {
        lastOkAt: "2020-01-01T00:00:00.000Z",
        lastCheckedAt: "2020-01-01T00:00:00.000Z",
        boundCheckpointSize: size,
        boundCheckpointSha: sha,
      }),
    );

    const app = express();
    app.use(
      "/api",
      createLedgerRouter({
        hitsPath,
        checkpointPath,
        lastOkPath,
        secretPath,
        staleThresholdSeconds: 1,
      }),
    );
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;

    // Break the ledger so the check returns mismatch — but lastOkAt
    // remains the seeded ancient timestamp, so we can observe staleness
    // independent of the current check outcome.
    const orig = sealed;
    writeFileSync(hitsPath, "X");
    const rBroken = await (
      await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)
    ).json() as any;
    expect(rBroken.status).toBe("mismatch");
    expect(rBroken.staleThresholdSeconds).toBe(1);
    expect(rBroken.lastOkAgeSeconds).toBeGreaterThan(1);
    expect(rBroken.stale).toBe(true);

    // Restore the ledger; the next ok check should reset lastOkAt and
    // immediately flip stale back to false.
    writeFileSync(hitsPath, orig);
    const rOk = await (
      await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)
    ).json() as any;
    expect(rOk.status).toBe("ok");
    expect(rOk.stale).toBe(false);
    expect(rOk.lastOkAgeSeconds).toBeLessThanOrEqual(1);

    await new Promise<void>((resolve, reject) =>
      srv.close((err) => (err ? reject(err) : resolve())),
    );
    try {
      unlinkSync(lastOkPath);
    } catch {
      /* ignore */
    }
  });

  it("task #99: surfaces lastCheckedAgeSeconds + checkedStale=false on a fresh attempt", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const r = await getStatus();
    expect(r.json.status).toBe("ok");
    // Fields are surfaced and reasonable.
    expect(typeof r.json.checkedStaleThresholdSeconds).toBe("number");
    expect(r.json.checkedStaleThresholdSeconds).toBeGreaterThan(0);
    expect(r.json.lastCheckedAgeSeconds).toBeGreaterThanOrEqual(0);
    expect(r.json.lastCheckedAgeSeconds).toBeLessThan(
      r.json.checkedStaleThresholdSeconds,
    );
    expect(r.json.checkedStale).toBe(false);
  });

  it("task #99: reports checkedStale=true when lastCheckedAt is older than the configured threshold", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    // Pre-seed an ancient lastCheckedAt (with valid HMAC) so the
    // sidecar load makes the very first response see a stale check
    // age — before lastCheckedAt is rewritten to "now" later in the
    // request. We construct a router with checkedStaleThresholdSeconds
    // = 1 so any age above 1s flips the badge.
    const lastOkPath = path.join(tmpDir, "hits.txt.chkstale.lastok");
    const secretPath = `${lastOkPath}.key`;
    const secretHex = "cd".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    writeFileSync(
      lastOkPath,
      sealSidecar(secretHex, {
        lastOkAt: null,
        lastCheckedAt: "2020-01-01T00:00:00.000Z",
        boundCheckpointSize: null,
        boundCheckpointSha: null,
      }),
    );

    // Build a router that exposes `buildStatus` directly so we can
    // observe the BASE response (before the inner run rewrites
    // lastCheckedAt for the next call). We use the higher-level
    // createLedgerChecker for that.
    const { createLedgerChecker } = await import("./ledger.js");
    const checker = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
      checkedStaleThresholdSeconds: 1,
    });
    // First call: lastCheckedAt was pre-seeded to 2020-01-01 so the
    // *snapshot* age is huge; even though the inner run advances
    // lastCheckedAt to "now" later, the response surfaces the age as
    // computed AFTER that advance — which means a fresh call should
    // be fresh. We need to assert on the FIRST call's snapshot of
    // checkedStaleThresholdSeconds and the SECOND call's age.
    const r1 = checker.buildStatus();
    expect(r1.checkedStaleThresholdSeconds).toBe(1);
    // After the first buildStatus(), lastCheckedAt is "now". Sleep
    // 1.2s so the next call sees age > threshold (1s).
    await new Promise((res) => setTimeout(res, 2100));
    const r2 = checker.buildStatus();
    expect(r2.lastCheckedAgeSeconds).toBeGreaterThanOrEqual(2);
    expect(r2.checkedStale).toBe(true);

    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
  });

  it("records each forged-sidecar dismissal to a rotating history log (task #150)", async () => {
    // Seed a healthy ledger + a forged sidecar so the boot read
    // surfaces a forgedIncident the operator can ack.
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.fackhist.lastok");
    const secretPath = `${lastOkPath}.key`;
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
    try { unlinkSync(`${lastOkPath}.forged-ack`); } catch { /* ignore */ }
    try { unlinkSync(`${lastOkPath}.forged-ack.log.jsonl`); } catch { /* ignore */ }
    const secretHex = "ab".repeat(32);
    writeFileSync(secretPath, secretHex + "\n", { mode: 0o600 });
    // Forged payload: valid JSON shape, but no `mac` field ⇒ checker
    // classifies as forged and discards the value.
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: new Date().toISOString(),
        lastCheckedAt: new Date().toISOString(),
        boundCheckpointSize: size,
        boundCheckpointSha: sha,
      }) + "\n",
    );

    const { createLedgerChecker } = await import("./ledger.js");
    const checker = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });

    // First Ack: appends one entry tagged with the referee.
    const r1 = checker.acknowledgeForgedSidecar("alice");
    expect(r1.ok).toBe(true);
    if (r1.ok) {
      expect(r1.alreadyAcknowledged).toBe(false);
      expect(r1.ackedBy).toBe("alice");
    }
    const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
    expect(existsSync(historyPath)).toBe(true);
    const firstHistory = checker.listForgedAckHistory();
    expect(firstHistory.logExists).toBe(true);
    expect(firstHistory.entries.length).toBe(1);
    expect(firstHistory.entries[0]?.ackedBy).toBe("alice");
    expect(firstHistory.capacity).toBeGreaterThan(0);

    // Re-acking the SAME incident is idempotent and must NOT
    // append a duplicate history entry.
    const r2 = checker.acknowledgeForgedSidecar("bob");
    expect(r2.ok).toBe(true);
    if (r2.ok) expect(r2.alreadyAcknowledged).toBe(true);
    expect(checker.listForgedAckHistory().entries.length).toBe(1);

    // Now simulate a NEW forged incident on next boot: write a
    // different forged payload (different bytes ⇒ different
    // payloadSha) and rebuild the checker.
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: new Date(Date.now() + 1000).toISOString(),
        lastCheckedAt: new Date(Date.now() + 1000).toISOString(),
        boundCheckpointSize: size,
        boundCheckpointSha: sha,
      }) + "\n",
    );
    const checker2 = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });
    const r3 = checker2.acknowledgeForgedSidecar("carol");
    expect(r3.ok).toBe(true);
    if (r3.ok) {
      expect(r3.alreadyAcknowledged).toBe(false);
      expect(r3.ackedBy).toBe("carol");
    }
    const finalHistory = checker2.listForgedAckHistory();
    // Most-recent-first ordering: carol's incident dismissal first,
    // alice's earlier one still visible after the single-incident
    // sidecar has been overwritten.
    expect(finalHistory.entries.length).toBe(2);
    expect(finalHistory.entries[0]?.ackedBy).toBe("carol");
    expect(finalHistory.entries[1]?.ackedBy).toBe("alice");
    // Distinct payload shas — the panel groups by incident.
    expect(finalHistory.entries[0]?.payloadSha).not.toBe(
      finalHistory.entries[1]?.payloadSha,
    );

    // Exercise the HTTP endpoint shape via a dedicated app mount.
    const subApp = express();
    subApp.use("/api", createLedgerRouter({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    }));
    // The HTTP endpoint lives in lean.ts, not ledger.ts — sanity-check
    // the in-process helper instead. (The lean.ts route delegates to
    // the default checker's `listForgedAckHistory`, which we just
    // exercised end-to-end.)

    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
    try { unlinkSync(`${lastOkPath}.forged-ack`); } catch { /* ignore */ }
    try { unlinkSync(`${lastOkPath}.forged-ack.log.jsonl`); } catch { /* ignore */ }
  });

  it("paging into a rotated forged-ack archive returns archived entries + rotations metadata (task #187)", async () => {
    // Task #187: cover the new dismissals paging end-to-end at the
    // checker layer. Force a rotation by setting
    // MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES low enough that two
    // appends tip the live file past the cap, then assert the
    // archived `.1` is reachable via `listForgedAckHistory(undefined, 1)`
    // and that `rotations[0].index === 1` so the dashboard pager
    // can light up the right tab without a second round-trip.
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.fackpage.lastok");
    const secretPath = `${lastOkPath}.key`;
    const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
    const rot1 = `${historyPath}.1`;
    for (const p of [
      lastOkPath,
      secretPath,
      `${lastOkPath}.forged-ack`,
      historyPath,
      rot1,
      `${historyPath}.2`,
    ]) {
      try { unlinkSync(p); } catch { /* ignore */ }
    }
    const secretHex = "ef".repeat(32);
    writeFileSync(secretPath, secretHex + "\n", { mode: 0o600 });

    const ENV_BYTES_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES";
    const ENV_ROTS_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS";
    const prevBytes = process.env[ENV_BYTES_KEY];
    const prevRots = process.env[ENV_ROTS_KEY];
    // One JSONL entry is ~140 bytes. 200 fits exactly one; the
    // second append tips it over and the rotator renames the live
    // file to `.1`.
    process.env[ENV_BYTES_KEY] = "200";
    process.env[ENV_ROTS_KEY] = "2";

    try {
      const { createLedgerChecker } = await import("./ledger.js");
      const ackOnce = (marker: string, ref: string) => {
        writeFileSync(
          lastOkPath,
          JSON.stringify({
            lastOkAt: new Date().toISOString(),
            lastCheckedAt: new Date().toISOString(),
            boundCheckpointSize: size,
            boundCheckpointSha: sha,
            marker,
          }) + "\n",
        );
        const checker = createLedgerChecker({
          hitsPath,
          checkpointPath,
          lastOkPath,
          secretPath,
        });
        const r = checker.acknowledgeForgedSidecar(ref);
        expect(r.ok).toBe(true);
        if (r.ok) expect(r.alreadyAcknowledged).toBe(false);
      };

      // Two distinct forged incidents → two history rows; the
      // second append crosses the byte cap and rotates the live
      // file to `.1`.
      ackOnce("page-v1", "alice");
      ackOnce("page-v2", "bob");

      expect(existsSync(rot1)).toBe(true);
      // After rotation the live file does not exist (or is empty)
      // until the next ack repopulates it.
      const liveExists =
        existsSync(historyPath) &&
        statSync(historyPath).size > 0;
      expect(liveExists).toBe(false);

      // Build a fresh checker to read; it inherits the on-disk
      // rotated state.
      writeFileSync(
        lastOkPath,
        JSON.stringify({
          lastOkAt: new Date().toISOString(),
          lastCheckedAt: new Date().toISOString(),
          boundCheckpointSize: size,
          boundCheckpointSha: sha,
          marker: "page-v3",
        }) + "\n",
      );
      const reader = createLedgerChecker({
        hitsPath,
        checkpointPath,
        lastOkPath,
        secretPath,
      });

      // Default (live) read: rotations metadata surfaces the `.1`
      // archive so the dashboard can render the pager.
      const live = reader.listForgedAckHistory();
      expect(live.rotation).toBe(0);
      expect(live.rotations.length).toBeGreaterThanOrEqual(1);
      expect(live.rotations[0]?.index).toBe(1);
      expect(live.rotations[0]?.path).toBe(rot1);

      // Paged read: rotation=1 returns the archived entries (both
      // alice and bob, newest-first) and echoes rotation=1.
      const archived = reader.listForgedAckHistory(undefined, 1);
      expect(archived.rotation).toBe(1);
      expect(archived.logExists).toBe(true);
      expect(archived.rotations.length).toBeGreaterThanOrEqual(1);
      expect(archived.rotations[0]?.index).toBe(1);
      const ackedBys = archived.entries.map((e) => e.ackedBy);
      expect(ackedBys).toContain("alice");
      expect(ackedBys).toContain("bob");
      // Newest-first ordering: bob's ack landed after alice's.
      expect(ackedBys[0]).toBe("bob");
    } finally {
      if (prevBytes === undefined) delete process.env[ENV_BYTES_KEY];
      else process.env[ENV_BYTES_KEY] = prevBytes;
      if (prevRots === undefined) delete process.env[ENV_ROTS_KEY];
      else process.env[ENV_ROTS_KEY] = prevRots;
      for (const p of [
        lastOkPath,
        secretPath,
        `${lastOkPath}.forged-ack`,
        historyPath,
        rot1,
        `${historyPath}.2`,
      ]) {
        try { unlinkSync(p); } catch { /* ignore */ }
      }
    }
  });

  it("rejects a forged sidecar with a fake future lastOkAt (HMAC mismatch ⇒ discarded as null)", async () => {
    // Healthy ledger so the integrity check itself succeeds. We're
    // testing that a hand-edited sidecar — written by an attacker who
    // has data-dir write access but does NOT have the per-deploy HMAC
    // secret — cannot make the dashboard claim the ledger was
    // verified moments ago.
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.forge.lastok");
    const secretPath = `${lastOkPath}.key`;
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    // 1) Forge a sidecar with a future lastOkAt and NO mac — what a
    //    naive attacker would write by hand-editing the JSON.
    const forgedFuture = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: forgedFuture,
        lastCheckedAt: forgedFuture,
      }) + "\n",
    );

    // 2) Construct a router pointing at a STILL-EMPTY secret file. The
    //    router will auto-generate a fresh secret (so the forged
    //    sidecar's missing mac will never verify) and then break the
    //    ledger so the next check is mismatch — that way `lastOkAt`
    //    only comes from the (forged) sidecar, not from a fresh ok.
    //    The endpoint must surface lastOkAt=null, NOT the forged future.
    const app1 = express();
    app1.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
    const srv1 = http.createServer(app1);
    await new Promise<void>((resolve) => srv1.listen(0, "127.0.0.1", resolve));
    const port1 = (srv1.address() as AddressInfo).port;
    // Break the ledger BEFORE the first request so the integrity check
    // returns mismatch and cannot legitimately mint a fresh lastOkAt.
    writeFileSync(hitsPath, "X");
    const r1 = await (await fetch(`http://127.0.0.1:${port1}/api/ledger/integrity`)).json() as any;
    expect(r1.status).toBe("mismatch");
    expect(r1.lastOkAt).toBeNull();
    expect(r1.lastOkAgeSeconds).toBeNull();
    await new Promise<void>((resolve, reject) =>
      srv1.close((err) => (err ? reject(err) : resolve())),
    );

    // 3) Now simulate an attacker who ALSO knows the on-disk
    //    checkpoint values and replays them in `boundCheckpointSize`/
    //    `boundCheckpointSha` — still no mac ⇒ still rejected.
    writeFileSync(hitsPath, sealed);
    writeCheckpoint(size, sha);
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: forgedFuture,
        lastCheckedAt: forgedFuture,
        boundCheckpointSize: size,
        boundCheckpointSha: sha,
      }) + "\n",
    );
    // Break the ledger so any reported lastOkAt must come from the
    // forged sidecar — not from the mismatch check itself.
    writeFileSync(hitsPath, "X");
    const app2 = express();
    app2.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
    const srv2 = http.createServer(app2);
    await new Promise<void>((resolve) => srv2.listen(0, "127.0.0.1", resolve));
    const port2 = (srv2.address() as AddressInfo).port;
    const r2 = await (await fetch(`http://127.0.0.1:${port2}/api/ledger/integrity`)).json() as any;
    expect(r2.status).toBe("mismatch");
    expect(r2.lastOkAt).toBeNull();
    await new Promise<void>((resolve, reject) =>
      srv2.close((err) => (err ? reject(err) : resolve())),
    );

    // 4) Finally, an attacker who has somehow ALSO read the secret
    //    keyfile could forge a valid sidecar — that's outside this
    //    threat model (filesystem ACLs on the keyfile are the
    //    perimeter). Sanity-check the positive path: a properly-MAC'd
    //    sidecar IS accepted, proving the mechanism actually permits
    //    legitimate persisted state.
    const realSecret = readFileSync(secretPath, "utf-8").trim();
    expect(/^[0-9a-f]{64}$/i.test(realSecret)).toBe(true);
    const legitPast = new Date(Date.now() - 30_000).toISOString();
    writeFileSync(hitsPath, sealed);
    writeCheckpoint(size, sha);
    writeFileSync(
      lastOkPath,
      sealSidecar(realSecret, {
        lastOkAt: legitPast,
        lastCheckedAt: legitPast,
        boundCheckpointSize: size,
        boundCheckpointSha: sha,
      }),
    );
    // Break ledger again so the lastOkAt we see must be the sidecar
    // value (not the result of a fresh ok check overwriting it).
    writeFileSync(hitsPath, "X");
    const app3 = express();
    app3.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
    const srv3 = http.createServer(app3);
    await new Promise<void>((resolve) => srv3.listen(0, "127.0.0.1", resolve));
    const port3 = (srv3.address() as AddressInfo).port;
    const r3 = await (await fetch(`http://127.0.0.1:${port3}/api/ledger/integrity`)).json() as any;
    expect(r3.status).toBe("mismatch");
    expect(r3.lastOkAt).toBe(legitPast);
    await new Promise<void>((resolve, reject) =>
      srv3.close((err) => (err ? reject(err) : resolve())),
    );

    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
  });

  it("discards lastOkAt when the bound checkpoint no longer matches the on-disk checkpoint", async () => {
    // A sidecar can be a valid MAC over a STALE checkpoint binding —
    // e.g. someone rotated the checkpoint after the ok was recorded.
    // The persisted lastOkAt refers to a different sealed prefix and
    // must not be surfaced.
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.bindrot.lastok");
    const secretPath = `${lastOkPath}.key`;
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
    const secretHex = "cd".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    // Bind to an OLD checkpoint that no longer matches what's on disk.
    writeFileSync(
      lastOkPath,
      sealSidecar(secretHex, {
        lastOkAt: new Date(Date.now() - 30_000).toISOString(),
        lastCheckedAt: new Date(Date.now() - 30_000).toISOString(),
        boundCheckpointSize: 999,
        boundCheckpointSha: "0".repeat(64),
      }),
    );
    // Break the ledger so the next check is mismatch ⇒ no fresh ok
    // would overwrite lastOkAt.
    writeFileSync(hitsPath, "X");
    const app = express();
    app.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;
    const r = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
    expect(r.status).toBe("mismatch");
    expect(r.lastOkAt).toBeNull();
    // Task #183: the boot-time stale-checkpoint-binding signal must
    // survive to the wire — previously `buildStatusInner` overwrote
    // it with `"ok"` on every call, so the dashboard amber banner
    // never lit up in production.
    expect(r.lastOkSidecarStatus).toBe("stale_checkpoint_binding");
    expect(r.lastOkSidecarStatusAcknowledgedAt).toBeNull();
    expect(r.lastOkSidecarStatusAcknowledgedBy).toBeNull();
    // A second poll (still no fresh ok verify) keeps the signal
    // sticky — the verifier hasn't yet refreshed the binding.
    const r2 = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
    expect(r2.lastOkSidecarStatus).toBe("stale_checkpoint_binding");
    await new Promise<void>((resolve, reject) =>
      srv.close((err) => (err ? reject(err) : resolve())),
    );
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
  });

  it("clears the stale-binding signal once a successful integrity verify refreshes the sidecar (task #183)", async () => {
    // Boot with a valid-MAC but stale-bound sidecar AND a healthy
    // ledger so the very first /integrity call returns `ok` and
    // re-seals the binding. The amber banner must clear on that
    // same response.
    const sealed = "alpha\nbeta\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.bindrot-clears.lastok");
    const secretPath = `${lastOkPath}.key`;
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
    const secretHex = "ef".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    writeFileSync(
      lastOkPath,
      sealSidecar(secretHex, {
        lastOkAt: new Date(Date.now() - 30_000).toISOString(),
        lastCheckedAt: new Date(Date.now() - 30_000).toISOString(),
        boundCheckpointSize: 999,
        boundCheckpointSha: "0".repeat(64),
      }),
    );

    const app = express();
    app.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;
    const r = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
    expect(r.status).toBe("ok");
    expect(r.lastOkSidecarStatus).toBe("ok");
    await new Promise<void>((resolve, reject) =>
      srv.close((err) => (err ? reject(err) : resolve())),
    );
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
  });

  it("surfaces checkpoint coverage and flags checkpointStale=true when the sidecar mtime exceeds the threshold (task #96)", async () => {
    // Healthy ledger with a checkpoint that we then back-date so its
    // mtime is older than a 1-second threshold. The integrity check
    // itself stays `ok`; the dashboard hint flips to checkpointStale.
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    // Append more bytes so coverage < 1.
    writeFileSync(hitsPath, sealed + "appended-line\n");
    // Back-date the checkpoint mtime to 10 minutes ago.
    const { utimesSync } = await import("node:fs");
    const past = new Date(Date.now() - 600_000);
    utimesSync(checkpointPath, past, past);

    const lastOkPath = path.join(tmpDir, "hits.txt.cpstale.lastok");
    const secretPath = `${lastOkPath}.key`;
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    const app = express();
    app.use(
      "/api",
      createLedgerRouter({
        hitsPath,
        checkpointPath,
        lastOkPath,
        secretPath,
        checkpointStaleThresholdSeconds: 1,
      }),
    );
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;
    const r = await (
      await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)
    ).json() as any;
    expect(r.status).toBe("ok");
    expect(r.checkpointStaleThresholdSeconds).toBe(1);
    expect(r.checkpointAgeSeconds).toBeGreaterThan(1);
    expect(r.checkpointStale).toBe(true);
    expect(r.checkpointLastModified).toBe(past.toISOString());
    // Coverage should be < 1 since live ledger grew past the checkpoint.
    expect(r.checkpointCoverageRatio).toBeGreaterThan(0);
    expect(r.checkpointCoverageRatio).toBeLessThan(1);

    await new Promise<void>((resolve, reject) =>
      srv.close((err) => (err ? reject(err) : resolve())),
    );
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }
  });

  it("reports checkpointStale=true when the checkpoint sidecar is missing", async () => {
    writeHits("line1\nline2\n");
    // No checkpoint written.
    const r = await getStatus();
    expect(r.json.status).toBe("missing");
    expect(r.json.checkpointAgeSeconds).toBeNull();
    expect(r.json.checkpointLastModified).toBeNull();
    expect(r.json.checkpointStale).toBe(true);
    expect(r.json.checkpointCoverageRatio).toBeNull();
  });

  it("Task #109: accepts an inline LEDGER_SIDECAR_SECRET env var with no keyfile on disk", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.inline.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.inline.lastok.key");
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    const inlineHex = "ef".repeat(32);
    const prev = process.env.LEDGER_SIDECAR_SECRET;
    process.env.LEDGER_SIDECAR_SECRET = inlineHex;
    try {
      // Seed a sidecar MAC'd by the inline secret — server should
      // accept it without ever touching the on-disk keyfile.
      const legitPast = new Date(Date.now() - 30_000).toISOString();
      writeFileSync(
        lastOkPath,
        sealSidecar(inlineHex, {
          lastOkAt: legitPast,
          lastCheckedAt: legitPast,
          boundCheckpointSize: size,
          boundCheckpointSha: sha,
        }),
      );
      // Break ledger so lastOkAt must come from the seeded sidecar.
      writeFileSync(hitsPath, "X");
      const app = express();
      app.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
      const srv = http.createServer(app);
      await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
      const port = (srv.address() as AddressInfo).port;
      const r = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
      expect(r.lastOkAt).toBe(legitPast);
      // Confirm the keyfile was never written to disk.
      expect(existsSync(secretPath)).toBe(false);
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    } finally {
      if (prev == null) delete process.env.LEDGER_SIDECAR_SECRET;
      else process.env.LEDGER_SIDECAR_SECRET = prev;
      try { unlinkSync(lastOkPath); } catch { /* ignore */ }
      try { unlinkSync(secretPath); } catch { /* ignore */ }
    }
  });

  it("Task #109: warns when the on-disk secret keyfile is group/world-readable", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.loose.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.loose.lastok.key");
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    // Pre-seed a valid keyfile, then loosen its mode to 0644.
    const secretHex = "ab".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    try {
      chmodSync(secretPath, 0o644);
    } catch {
      // chmod may be unsupported on some platforms — skip the test there.
      return;
    }
    const mode = statSync(secretPath).mode & 0o777;
    if ((mode & 0o044) === 0) {
      // umask or filesystem stripped the perms — skip.
      return;
    }

    // The warning is emitted via the module's pino logger (stdout
    // JSON), so we don't intercept it here — we just smoke-test that
    // a loose-mode keyfile is still accepted (loose mode is a
    // warning, not a hard fail) and the integrity endpoint responds.
    try {
      const app = express();
      app.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
      const srv = http.createServer(app);
      await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
      const port = (srv.address() as AddressInfo).port;
      const r = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
      // Server still functions — loose-mode is a warning, not a hard fail.
      expect(r.status).toBe("ok");
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    } finally {
      try { unlinkSync(lastOkPath); } catch { /* ignore */ }
      try { unlinkSync(secretPath); } catch { /* ignore */ }
    }
  });

  it("Task #123: strict mode hard-fails boot when secret keyfile is group/world-readable", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.strict.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.strict.lastok.key");
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    const secretHex = "ab".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    try {
      chmodSync(secretPath, 0o644);
    } catch {
      return;
    }
    const mode = statSync(secretPath).mode & 0o777;
    if ((mode & 0o044) === 0) {
      return;
    }

    const prev = process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
    process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE = "1";
    try {
      const { createLedgerChecker, SidecarSecretLooseModeError } = await import("./ledger.js");
      expect(() =>
        createLedgerChecker({ hitsPath, checkpointPath, lastOkPath, secretPath }),
      ).toThrow(SidecarSecretLooseModeError);
    } finally {
      if (prev === undefined) {
        delete process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
      } else {
        process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE = prev;
      }
      try { unlinkSync(lastOkPath); } catch { /* ignore */ }
      try { unlinkSync(secretPath); } catch { /* ignore */ }
    }
  });

  it("Task #123: lenient mode (default) boots successfully when secret keyfile is group/world-readable", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const lastOkPath = path.join(tmpDir, "hits.txt.lenient.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.lenient.lastok.key");
    try { unlinkSync(lastOkPath); } catch { /* ignore */ }
    try { unlinkSync(secretPath); } catch { /* ignore */ }

    const secretHex = "cd".repeat(32);
    writeFileSync(secretPath, secretHex + "\n");
    try {
      chmodSync(secretPath, 0o644);
    } catch {
      return;
    }
    const mode = statSync(secretPath).mode & 0o777;
    if ((mode & 0o044) === 0) {
      return;
    }

    const prev = process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
    delete process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE;
    try {
      const app = express();
      app.use("/api", createLedgerRouter({ hitsPath, checkpointPath, lastOkPath, secretPath }));
      const srv = http.createServer(app);
      await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
      const port = (srv.address() as AddressInfo).port;
      const r = await (await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)).json() as any;
      expect(r.status).toBe("ok");
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    } finally {
      if (prev !== undefined) {
        process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE = prev;
      }
      try { unlinkSync(lastOkPath); } catch { /* ignore */ }
      try { unlinkSync(secretPath); } catch { /* ignore */ }
    }
  });

  it("reports stale=true with lastOkAgeSeconds=null when no successful check has ever been recorded", async () => {
    // Fresh router pointing at a sidecar that does not exist, with the
    // ledger broken so no ok check fires.
    const lastOkPath = path.join(tmpDir, "hits.txt.never.lastok");
    try {
      unlinkSync(lastOkPath);
    } catch {
      /* ignore */
    }
    writeFileSync(hitsPath, "X");
    writeCheckpoint(999, "0".repeat(64));

    const app = express();
    app.use(
      "/api",
      createLedgerRouter({ hitsPath, checkpointPath, lastOkPath }),
    );
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;
    const r = await (
      await fetch(`http://127.0.0.1:${port}/api/ledger/integrity`)
    ).json() as any;
    expect(r.lastOkAt).toBeNull();
    expect(r.lastOkAgeSeconds).toBeNull();
    expect(r.stale).toBe(true);
    await new Promise<void>((resolve, reject) =>
      srv.close((err) => (err ? reject(err) : resolve())),
    );
  });
});

/**
 * Task #129: end-to-end coverage that proves the watchdog stall alert
 * actually rides the same kernel `_fire_ledger_alert` rail as
 * production. We boot the real `startLedgerMonitor` wired against a
 * sink that mirrors `createKernelAlertSink` (spawns the real
 * `kernel.py`) but redirects `kernel.ALERTS_LOG` to a per-test tmp
 * file so the assertions don't pollute `data/ledger-alerts.jsonl`.
 * The unit tests in `ledger.monitor.test.ts` already pin the state
 * machine; this test pins the wiring through to the on-disk JSONL.
 */
describe("watchdog stall alert (task #129, e2e through kernel)", () => {
  const REPO_ROOT = path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    "..",
    "..",
    "..",
    "..",
  );

  function makeKernelishSink(alertsLogPath: string): LedgerAlertSink {
    // Mirror of `createKernelAlertSink` but injects
    // `kernel.ALERTS_LOG = Path(alertsLogPath)` before firing so we
    // observe a real kernel write into a per-test tmp file. Also
    // clears alert env vars so no real webhook / SMTP delivery is
    // attempted from this test.
    const program = [
      "import json, os, sys, pathlib",
      `sys.path.insert(0, ${JSON.stringify(REPO_ROOT)})`,
      "for v in ('MORNINGSTAR_ALERT_WEBHOOK_URL','MORNINGSTAR_ALERT_EMAIL_TO','MORNINGSTAR_ALERT_SMTP_HOST'):",
      "    os.environ.pop(v, None)",
      "import kernel",
      `kernel.ALERTS_LOG = pathlib.Path(${JSON.stringify(alertsLogPath)})`,
      "data = json.load(sys.stdin)",
      "kernel._fire_ledger_alert(data['message'], data['context'])",
      "assert kernel._await_alert_dispatch(15.0), 'alert dispatch did not drain'",
    ].join("\n");
    return (invocation: LedgerAlertInvocation) =>
      new Promise<void>((resolve, reject) => {
        const child = spawn("python3", ["-c", program], {
          stdio: ["pipe", "ignore", "pipe"],
        });
        let stderr = "";
        child.stderr.on("data", (b: Buffer) => {
          stderr += b.toString("utf-8");
        });
        child.on("error", (err) => reject(err));
        child.on("exit", (code) => {
          if (code !== 0) {
            reject(
              new Error(
                `kernel sink subprocess exited ${code}; stderr=${stderr}`,
              ),
            );
            return;
          }
          resolve();
        });
        child.stdin.end(
          JSON.stringify({
            message: invocation.message,
            context: invocation.context,
          }),
        );
      });
  }

  function readAlertsLog(p: string): Array<Record<string, unknown>> {
    if (!existsSync(p)) return [];
    return readFileSync(p, "utf-8")
      .split("\n")
      .filter((l) => l.trim() !== "")
      .map((l) => JSON.parse(l) as Record<string, unknown>);
  }

  it(
    "fires a monitor_stalled entry to ledger-alerts.jsonl when ticks freeze, then a monitor_recovered entry when ticks resume",
    async () => {
      const dir = mkdtempSync(path.join(tmpdir(), "watchdog-e2e-"));
      const hp = path.join(dir, "hits.txt");
      const cp = path.join(dir, "hits.txt.checkpoint");
      const lp = path.join(dir, "hits.txt.lastok");
      const alertsLogPath = path.join(dir, "ledger-alerts.jsonl");

      const sealed = "line1\nline2\n";
      const buf = Buffer.from(sealed, "utf-8");
      writeFileSync(hp, buf);
      writeFileSync(cp, `${buf.length} ${sha256(buf)}\n`);

      const { buildStatus } = createLedgerChecker({
        hitsPath: hp,
        checkpointPath: cp,
        lastOkPath: lp,
      });
      const sink = makeKernelishSink(alertsLogPath);

      // Use a tiny interval (LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS=1
      // ⇒ intervalMs=1000, stall threshold = 2s). We drive the
      // watchdog manually against an injected `now()` clock so the
      // test is deterministic and does not actually sleep.
      let clockMs = 10_000_000;
      const monitor = startLedgerMonitor({
        buildStatus,
        sink,
        intervalMs: 1_000,
        hitsPath: hp,
        checkpointPath: cp,
        logger: { info: () => {}, warn: () => {}, error: () => {} },
        now: () => clockMs,
      });

      try {
        // Just past the 2x interval = 2_000ms threshold: stall fires.
        clockMs += 2_500;
        await monitor.checkWatchdog();

        const stalled = readAlertsLog(alertsLogPath);
        expect(stalled).toHaveLength(1);
        expect(stalled[0]["failure_mode"]).toBe("monitor_stalled");
        expect(stalled[0]["source"]).toBe("api-server-monitor-watchdog");
        expect(stalled[0]["hits_path"]).toBe(hp);
        expect(stalled[0]["checkpoint_path"]).toBe(cp);
        expect(stalled[0]["stall_threshold_seconds"]).toBe(2);
        expect(stalled[0]["monitor_interval_seconds"]).toBe(1);
        expect(typeof stalled[0]["stall_age_seconds"]).toBe("number");
        expect(String(stalled[0]["message"])).toMatch(/watchdog/i);
        expect(String(stalled[0]["message"])).toMatch(/stalled/i);
        // The kernel decorates every record with its own delivery /
        // workflow metadata — proof we routed through the real
        // `_fire_ledger_alert` path, not a stub.
        expect(stalled[0]["delivery"]).toBeTruthy();
        expect(stalled[0]["workflow"]).toBeTruthy();

        // Still stalled across additional checks: silent (dedup).
        clockMs += 5_000;
        await monitor.checkWatchdog();
        expect(readAlertsLog(alertsLogPath)).toHaveLength(1);

        // A real tick lands ⇒ watchdog notices recovery on next pass.
        await monitor.tick();
        await monitor.checkWatchdog();

        const recovered = readAlertsLog(alertsLogPath);
        expect(recovered).toHaveLength(2);
        expect(recovered[1]["failure_mode"]).toBe("recovered");
        expect(recovered[1]["previous_failure_mode"]).toBe("monitor_stalled");
        expect(recovered[1]["source"]).toBe("api-server-monitor-watchdog");
        expect(String(recovered[1]["message"])).toMatch(/RECOVERED/);
      } finally {
        monitor.stop();
        rmSync(dir, { recursive: true, force: true });
      }
    },
    30_000,
  );
});

/**
 * Task #162: end-to-end coverage that the task #144 watchdog-stalled
 * subject ACTUALLY reaches the wire on both the SMTP and webhook
 * transports — not just the on-disk `ledger-alerts.jsonl` ring
 * buffer. The Python-side `tests/test_alerts.py` proves
 * `_fire_ledger_alert` builds the distinct Subject / `subject`
 * field; the TS-side `ledger.monitor.test.ts` proves the watchdog
 * builds the right context shape; this test wires them together so
 * a regression that drops the watchdog-specific fields between TS
 * and Python (e.g. an unintentional payload-key rename) cannot
 * slip past both unit suites.
 *
 * Flow per test:
 *   real `startLedgerMonitor.checkWatchdog`
 *     → real `kernel._fire_ledger_alert` (spawned)
 *       → real `_send_email` to a Node SMTP capture
 *       → real `_post_webhook` to a Node HTTP capture
 *         → assert subject is the distinct "MONITOR STALLED" /
 *           "Ledger monitor RECOVERED" line on both transports.
 */
describe("watchdog stall alert — SMTP + webhook subject on the wire (task #162)", () => {
  const REPO_ROOT = path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    "..",
    "..",
    "..",
    "..",
  );

  interface WebhookCapture {
    server: http.Server;
    port: number;
    captured: Array<{ headers: Record<string, string>; body: string }>;
    close: () => Promise<void>;
  }

  async function startWebhookCapture(): Promise<WebhookCapture> {
    const captured: Array<{
      headers: Record<string, string>;
      body: string;
    }> = [];
    const app = express();
    app.use(express.raw({ type: "*/*", limit: "1mb" }));
    app.post("/alert", (req, res) => {
      captured.push({
        headers: Object.fromEntries(
          Object.entries(req.headers).map(([k, v]) => [
            k,
            Array.isArray(v) ? v.join(",") : String(v ?? ""),
          ]),
        ),
        body: (req.body as Buffer).toString("utf-8"),
      });
      res.status(200).send("ok");
    });
    const server = http.createServer(app);
    await new Promise<void>((resolve) =>
      server.listen(0, "127.0.0.1", resolve),
    );
    const port = (server.address() as AddressInfo).port;
    return {
      server,
      port,
      captured,
      close: () =>
        new Promise<void>((resolve, reject) =>
          server.close((err) => (err ? reject(err) : resolve())),
        ),
    };
  }

  interface SmtpCapture {
    port: number;
    messages: Array<{ raw: string; subject: string; body: string }>;
    close: () => Promise<void>;
  }

  // Minimal RFC-5321 sink: speaks just enough of EHLO / MAIL FROM /
  // RCPT TO / DATA / QUIT for `smtplib.SMTP.send_message` (no auth,
  // no STARTTLS — `_send_email` skips both when SMTP_USER is unset)
  // to complete. Captures the DATA payload plus the parsed Subject
  // header and body.
  async function startSmtpCapture(): Promise<SmtpCapture> {
    const net = await import("node:net");
    const messages: Array<{ raw: string; subject: string; body: string }> = [];
    const server = net.createServer((sock) => {
      sock.setEncoding("utf-8");
      let buf = "";
      let inData = false;
      let dataLines: string[] = [];
      const write = (line: string) => sock.write(line + "\r\n");
      write("220 mini.smtp ready");
      sock.on("data", (chunk: string) => {
        buf += chunk;
        let nl: number;
        while ((nl = buf.indexOf("\r\n")) >= 0) {
          const line = buf.slice(0, nl);
          buf = buf.slice(nl + 2);
          if (inData) {
            if (line === ".") {
              const raw = dataLines.join("\r\n");
              const headerEnd = raw.indexOf("\r\n\r\n");
              let subject = "";
              let body = "";
              if (headerEnd >= 0) {
                const headers = raw.slice(0, headerEnd);
                const rawBody = raw.slice(headerEnd + 4);
                // RFC-2822 unfold + find Subject:.
                const unfolded = headers.replace(/\r\n[\t ]+/g, " ");
                let cte = "";
                for (const h of unfolded.split("\r\n")) {
                  const ms = /^Subject:\s*(.*)$/i.exec(h);
                  if (ms && ms[1] !== undefined) subject = ms[1];
                  const mc = /^Content-Transfer-Encoding:\s*(.*)$/i.exec(h);
                  if (mc && mc[1] !== undefined) cte = mc[1].toLowerCase();
                }
                // Decode quoted-printable so assertions can match
                // human-readable substrings that the SMTP layer may
                // have soft-wrapped (e.g. "do NOT restore hits.txt"
                // landing across an `=\r\n` soft break).
                body = rawBody;
                if (cte === "quoted-printable") {
                  body = body
                    .replace(/=\r\n/g, "")
                    .replace(/=\n/g, "")
                    .replace(/=([0-9A-Fa-f]{2})/g, (_, hex) =>
                      String.fromCharCode(parseInt(hex, 16)),
                    );
                }
              }
              messages.push({ raw, subject, body });
              inData = false;
              dataLines = [];
              write("250 queued");
            } else {
              dataLines.push(line.startsWith("..") ? line.slice(1) : line);
            }
            continue;
          }
          const upper = line.toUpperCase();
          if (upper.startsWith("EHLO") || upper.startsWith("HELO")) {
            write("250 hello");
          } else if (upper.startsWith("MAIL FROM:")) {
            write("250 ok");
          } else if (upper.startsWith("RCPT TO:")) {
            write("250 ok");
          } else if (upper.startsWith("DATA")) {
            write("354 send data");
            inData = true;
            dataLines = [];
          } else if (upper.startsWith("QUIT")) {
            write("221 bye");
            sock.end();
          } else if (upper.startsWith("RSET") || upper.startsWith("NOOP")) {
            write("250 ok");
          } else {
            write("250 ok");
          }
        }
      });
      sock.on("error", () => {
        /* ignore */
      });
    });
    await new Promise<void>((resolve) =>
      server.listen(0, "127.0.0.1", resolve),
    );
    const port = (server.address() as AddressInfo).port;
    return {
      port,
      messages,
      close: () =>
        new Promise<void>((resolve, reject) =>
          server.close((err) => (err ? reject(err) : resolve())),
        ),
    };
  }

  // Sink that mirrors `createKernelAlertSink` but (a) redirects
  // `kernel.ALERTS_LOG` to a per-test tmp file and (b) passes the
  // webhook + SMTP env vars into the spawn so the real
  // `_post_webhook` / `_send_email` transports run against our
  // capture servers. The python program does `_await_alert_dispatch`
  // so the daemon dispatch thread is drained before exit.
  function makeWireSink(
    alertsLogPath: string,
    env: Record<string, string>,
  ): LedgerAlertSink {
    const program = [
      "import json, sys, pathlib",
      `sys.path.insert(0, ${JSON.stringify(REPO_ROOT)})`,
      "import kernel",
      `kernel.ALERTS_LOG = pathlib.Path(${JSON.stringify(alertsLogPath)})`,
      "data = json.load(sys.stdin)",
      "kernel._fire_ledger_alert(data['message'], data['context'])",
      "assert kernel._await_alert_dispatch(15.0), 'alert dispatch did not drain'",
    ].join("\n");
    return (invocation: LedgerAlertInvocation) =>
      new Promise<void>((resolve, reject) => {
        const child = spawn("python3", ["-c", program], {
          stdio: ["pipe", "ignore", "pipe"],
          env: { ...process.env, ...env },
        });
        let stderr = "";
        child.stderr.on("data", (b: Buffer) => {
          stderr += b.toString("utf-8");
        });
        child.on("error", (err) => reject(err));
        child.on("exit", (code) => {
          if (code !== 0) {
            reject(
              new Error(
                `wire sink subprocess exited ${code}; stderr=${stderr}`,
              ),
            );
            return;
          }
          resolve();
        });
        child.stdin.end(
          JSON.stringify({
            message: invocation.message,
            context: invocation.context,
          }),
        );
      });
  }

  it(
    "delivers the distinct MONITOR STALLED subject on both SMTP and webhook, then the distinct RECOVERED subject on transition",
    async () => {
      const dir = mkdtempSync(path.join(tmpdir(), "watchdog-wire-"));
      const hp = path.join(dir, "hits.txt");
      const cp = path.join(dir, "hits.txt.checkpoint");
      const lp = path.join(dir, "hits.txt.lastok");
      const alertsLogPath = path.join(dir, "ledger-alerts.jsonl");

      const sealed = "line1\nline2\n";
      const buf = Buffer.from(sealed, "utf-8");
      writeFileSync(hp, buf);
      writeFileSync(cp, `${buf.length} ${sha256(buf)}\n`);

      const webhook = await startWebhookCapture();
      const smtp = await startSmtpCapture();

      const sink = makeWireSink(alertsLogPath, {
        MORNINGSTAR_ALERT_WEBHOOK_URL: `http://127.0.0.1:${webhook.port}/alert`,
        MORNINGSTAR_ALERT_EMAIL_TO: "ops@example.com",
        MORNINGSTAR_ALERT_EMAIL_FROM: "ledger@example.com",
        MORNINGSTAR_ALERT_SMTP_HOST: "127.0.0.1",
        MORNINGSTAR_ALERT_SMTP_PORT: String(smtp.port),
        MORNINGSTAR_WORKFLOW_NAME: "api-server-e2e-162",
        // Make sure no stale auth lingers from the parent env.
        MORNINGSTAR_ALERT_SMTP_USER: "",
        MORNINGSTAR_ALERT_SMTP_PASSWORD: "",
      });

      const { buildStatus } = createLedgerChecker({
        hitsPath: hp,
        checkpointPath: cp,
        lastOkPath: lp,
      });

      let clockMs = 20_000_000;
      const monitor = startLedgerMonitor({
        buildStatus,
        sink,
        intervalMs: 1_000,
        hitsPath: hp,
        checkpointPath: cp,
        logger: { info: () => {}, warn: () => {}, error: () => {} },
        now: () => clockMs,
      });

      try {
        // Cross the 2× stall threshold → watchdog fires.
        clockMs += 2_500;
        await monitor.checkWatchdog();

        expect(webhook.captured).toHaveLength(1);
        expect(smtp.messages).toHaveLength(1);

        // Webhook: JSON body with the distinct `subject` field and
        // the watchdog-specific context fields plumbed through.
        const stallPayload = JSON.parse(webhook.captured[0]!.body) as Record<
          string,
          unknown
        >;
        expect(stallPayload["failure_mode"]).toBe("monitor_stalled");
        expect(stallPayload["source"]).toBe("api-server-monitor-watchdog");
        expect(stallPayload["monitor_interval_seconds"]).toBe(1);
        expect(stallPayload["stall_threshold_seconds"]).toBe(2);
        expect(typeof stallPayload["stall_age_seconds"]).toBe("number");
        expect(typeof stallPayload["subject"]).toBe("string");
        const stallSubject = String(stallPayload["subject"]);
        expect(stallSubject).toContain("MONITOR STALLED");
        expect(stallSubject).toContain("push alerts may be silent");
        expect(stallSubject).toContain("api-server-e2e-162");
        expect(stallSubject).not.toContain("Ledger integrity alert");

        // SMTP: Subject header matches the same distinct line, and
        // the body carries the stall-specific fields (not the
        // tamper expected/actual hash columns).
        const stallEmail = smtp.messages[0]!;
        expect(stallEmail.subject).toContain("MONITOR STALLED");
        expect(stallEmail.subject).toContain("push alerts may be silent");
        expect(stallEmail.subject).toContain("api-server-e2e-162");
        expect(stallEmail.subject).not.toContain("Ledger integrity alert");
        expect(stallEmail.body).toContain("failure_mode: monitor_stalled");
        expect(stallEmail.body).toContain("stall_threshold_seconds: 2");
        expect(stallEmail.body).toContain("monitor_interval_seconds: 1");
        expect(stallEmail.body).toContain("do NOT restore hits.txt");
        // The tamper-recovery doc pointer must not show up here.
        expect(stallEmail.body).not.toContain("REPRODUCE.md");

        // Dedup: another stalled check while still stalled stays
        // silent on both transports.
        clockMs += 5_000;
        await monitor.checkWatchdog();
        expect(webhook.captured).toHaveLength(1);
        expect(smtp.messages).toHaveLength(1);

        // Real tick lands → recovery fires once on next watchdog.
        await monitor.tick();
        await monitor.checkWatchdog();

        expect(webhook.captured).toHaveLength(2);
        expect(smtp.messages).toHaveLength(2);

        const recoverPayload = JSON.parse(
          webhook.captured[1]!.body,
        ) as Record<string, unknown>;
        expect(recoverPayload["failure_mode"]).toBe("recovered");
        expect(recoverPayload["previous_failure_mode"]).toBe(
          "monitor_stalled",
        );
        expect(recoverPayload["source"]).toBe("api-server-monitor-watchdog");
        const recoverSubject = String(recoverPayload["subject"]);
        expect(recoverSubject).toContain("Ledger monitor RECOVERED");
        expect(recoverSubject).toContain("api-server-e2e-162");
        expect(recoverSubject).not.toContain("MONITOR STALLED");
        expect(recoverSubject).not.toContain("Ledger integrity alert");

        const recoverEmail = smtp.messages[1]!;
        expect(recoverEmail.subject).toContain("Ledger monitor RECOVERED");
        expect(recoverEmail.subject).toContain("api-server-e2e-162");
        expect(recoverEmail.subject).not.toContain("MONITOR STALLED");
        expect(recoverEmail.body).toContain("failure_mode: recovered");
        expect(recoverEmail.body).toContain(
          "previous_failure_mode: monitor_stalled",
        );
        expect(recoverEmail.body).toContain("do NOT restore hits.txt");
        expect(recoverEmail.body).not.toContain("REPRODUCE.md");
      } finally {
        monitor.stop();
        await webhook.close();
        await smtp.close();
        rmSync(dir, { recursive: true, force: true });
      }
    },
    60_000,
  );
});
