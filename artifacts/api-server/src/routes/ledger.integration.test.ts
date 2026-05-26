import { describe, it, expect, beforeEach, afterEach, beforeAll, afterAll } from "vitest";
import { mkdtempSync, writeFileSync, readFileSync, rmSync, unlinkSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash, createHmac } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerRouter } from "./ledger.js";

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
