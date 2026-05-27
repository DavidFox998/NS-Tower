import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtempSync, writeFileSync, rmSync, unlinkSync, utimesSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import {
  createLedgerChecker,
  startLedgerMonitor,
  type LedgerMonitorHandle,
} from "./ledger.js";
import type {
  LedgerAlertInvocation,
  LedgerAlertSink,
} from "../lib/ledgerAlerts.js";

let tmpDir: string;
let hitsPath: string;
let checkpointPath: string;
let lastOkPath: string;
let monitor: LedgerMonitorHandle | null = null;

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

function silentLogger() {
  return { info: () => {}, warn: () => {}, error: () => {} };
}

function makeRecordingSink(): {
  sink: LedgerAlertSink;
  calls: LedgerAlertInvocation[];
} {
  const calls: LedgerAlertInvocation[] = [];
  const sink: LedgerAlertSink = (inv) => {
    calls.push(inv);
    return Promise.resolve();
  };
  return { sink, calls };
}

beforeEach(() => {
  tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-monitor-test-"));
  hitsPath = path.join(tmpDir, "hits.txt");
  checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  lastOkPath = path.join(tmpDir, "hits.txt.lastok");
});

afterEach(() => {
  monitor?.stop();
  monitor = null;
  for (const p of [hitsPath, checkpointPath, lastOkPath]) {
    try {
      unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
  rmSync(tmpDir, { recursive: true, force: true });
});

describe("startLedgerMonitor", () => {
  it("fires no alert when the ledger stays healthy across ticks", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { router: _r, buildStatus, hitsPath: hp, checkpointPath: cp } =
      createLedgerChecker({ hitsPath, checkpointPath, lastOkPath });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      hitsPath: hp,
      checkpointPath: cp,
      logger: silentLogger(),
    });

    await monitor.tick();
    await monitor.tick();
    await monitor.tick();
    expect(calls).toHaveLength(0);
  });

  it("fires exactly one alert when the ledger goes red, dedupes while still red", async () => {
    const sealed = "line1\nline2\nline3\nline4\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus, hitsPath: hp, checkpointPath: cp } =
      createLedgerChecker({ hitsPath, checkpointPath, lastOkPath });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      hitsPath: hp,
      checkpointPath: cp,
      logger: silentLogger(),
    });

    // First tick: still ok, no alert.
    await monitor.tick();
    expect(calls).toHaveLength(0);

    // Tamper: truncate the live ledger below the checkpoint.
    writeFileSync(hitsPath, "line1\n");

    await monitor.tick();
    expect(calls).toHaveLength(1);
    expect(calls[0].kind).toBe("alert");
    expect(calls[0].context.failure_mode).toBe("hits_truncated");
    expect(calls[0].context.expected_size).toBe(size);
    expect(calls[0].context.expected_sha).toBe(sha);
    expect(calls[0].context.source).toBe("api-server-monitor");
    expect(calls[0].context.hits_path).toBe(hp);
    expect(calls[0].context.checkpoint_path).toBe(cp);
    expect(calls[0].message).toMatch(/Ledger integrity check failed/);

    // Two more ticks while still red with the same failure_mode: silent.
    await monitor.tick();
    await monitor.tick();
    expect(calls).toHaveLength(1);
  });

  it("re-fires when the failure_mode changes while still red", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
    });

    // Tamper 1: truncate.
    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(1);
    expect(calls[0].context.failure_mode).toBe("hits_truncated");

    // Tamper 2: same length as checkpoint but rewritten in place.
    const tampered = "LINE1\nLINE2\nLINE3\n";
    expect(Buffer.byteLength(tampered)).toBe(size);
    writeFileSync(hitsPath, tampered);
    await monitor.tick();
    expect(calls).toHaveLength(2);
    expect(calls[1].context.failure_mode).toBe("hits_rewritten_in_place");

    // Stay rewritten: silent.
    await monitor.tick();
    expect(calls).toHaveLength(2);
  });

  it("fires a single 'recovered' alert when the ledger comes back to green", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
    });

    // Go red.
    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(1);
    expect(calls[0].kind).toBe("alert");

    // Restore.
    writeFileSync(hitsPath, sealed);
    await monitor.tick();
    expect(calls).toHaveLength(2);
    expect(calls[1].kind).toBe("recovered");
    expect(calls[1].context.failure_mode).toBe("recovered");
    expect(calls[1].context.previous_failure_mode).toBe("hits_truncated");
    expect(calls[1].message).toMatch(/RECOVERED/);

    // Stay green: silent.
    await monitor.tick();
    await monitor.tick();
    expect(calls).toHaveLength(2);
  });

  it("survives a sink that throws — no exception bubbles, state still advances", async () => {
    const sealed = "line1\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    let calls = 0;
    const sink: LedgerAlertSink = () => {
      calls++;
      throw new Error("sink down");
    };
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
    });

    writeFileSync(hitsPath, "");
    await expect(monitor.tick()).resolves.toBeUndefined();
    expect(calls).toBe(1);
    // Dedup still works — sink throwing doesn't cause re-spam.
    await monitor.tick();
    expect(calls).toBe(1);
  });

  it("suppresses re-fire on failure_mode transition when the prior alert was acknowledged (task #98)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    const ackedIds = new Set<string>();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
      isAcknowledged: (id) => ackedIds.has(id),
    });

    // Tamper 1: truncate → first alert fires.
    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(1);
    expect(calls[0].context.failure_mode).toBe("hits_truncated");
    const firedTimestamp = calls[0].context["timestamp"] as string;
    const firedMessage = calls[0].message;
    expect(firedTimestamp).toBeTruthy();
    const firedId = sha256(firedTimestamp + "\n" + firedMessage);

    // Operator dismisses it in the dashboard.
    ackedIds.add(firedId);

    // Tamper 2: failure_mode genuinely changes — normally re-fires.
    // With ack-share state: monitor stays silent.
    const tampered = "LINE1\nLINE2\nLINE3\n";
    expect(Buffer.byteLength(tampered)).toBe(size);
    writeFileSync(hitsPath, tampered);
    await monitor.tick();
    expect(calls).toHaveLength(1);

    // getInfo reflects the suppressed-ack state and the latest mode.
    const info = monitor.getInfo();
    expect(info.lastAcknowledgedAlertId).toBe(firedId);
    expect(info.lastAlertedFailureMode).toBe("hits_rewritten_in_place");

    // Another non-ok tick of the new mode: still silent.
    await monitor.tick();
    expect(calls).toHaveLength(1);
  });

  it("fires the recovery alert even when the prior alert was acknowledged (task #98)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    const ackedIds = new Set<string>();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
      isAcknowledged: (id) => ackedIds.has(id),
    });

    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(1);
    const firedId = sha256(
      (calls[0].context["timestamp"] as string) + "\n" + calls[0].message,
    );
    ackedIds.add(firedId);

    // Restore — recovery alert MUST still fire, ack notwithstanding.
    writeFileSync(hitsPath, sealed);
    await monitor.tick();
    expect(calls).toHaveLength(2);
    expect(calls[1].kind).toBe("recovered");

    // State is reset; lastAcknowledgedAlertId clears on recovery.
    expect(monitor.getInfo().lastAcknowledgedAlertId).toBeNull();
    expect(monitor.getInfo().lastAlertedFailureMode).toBeNull();

    // If a new incident arises after recovery, it fires fresh (the
    // old ack doesn't bleed across incidents).
    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(3);
    expect(calls[2].kind).toBe("alert");
  });

  it("does not suppress when isAcknowledged is omitted (backwards-compatible)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
    });

    writeFileSync(hitsPath, "x");
    await monitor.tick();
    expect(calls).toHaveLength(1);
    const tampered = "LINE1\nLINE2\nLINE3\n";
    expect(Buffer.byteLength(tampered)).toBe(size);
    writeFileSync(hitsPath, tampered);
    await monitor.tick();
    expect(calls).toHaveLength(2);
  });

  it("fires a one-shot 'sidecar_forged' alert on first tick when boot detected a forged sidecar (task #110)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    // Forge the sidecar BEFORE constructing the checker so the boot
    // read sees a missing-mac payload and latches the alert.
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: new Date(Date.now() + 60_000).toISOString(),
        lastCheckedAt: new Date().toISOString(),
      }) + "\n",
    );

    const secretPath = `${lastOkPath}.key`;
    const checker = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });

    // Boot status surfaces `forged` in the integrity payload before
    // the first build overwrites the sidecar.
    const bootStatus = checker.buildStatus();
    // Note: buildStatus() itself runs a write that flips status back
    // to "ok" — but `base` is constructed first, so the FIRST build
    // returns the forged status (the dashboard's first poll will see
    // it). Subsequent builds report "ok".
    expect(bootStatus.lastOkSidecarStatus).toBe("ok");
    // Capture the status before any build for the dashboard:
    // we already overwrote it, but the in-memory latch is what feeds
    // the monitor alert.

    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus: checker.buildStatus,
      sink,
      intervalMs: 60_000,
      hitsPath: checker.hitsPath,
      checkpointPath: checker.checkpointPath,
      sidecarPath: lastOkPath,
      consumeBootForgedAlert: checker.consumeBootForgedAlert,
      logger: silentLogger(),
    });

    await monitor.tick();
    // Exactly one sidecar-forged alert was fired. The ledger itself
    // is healthy, so no integrity alert follows.
    expect(calls).toHaveLength(1);
    expect(calls[0].kind).toBe("alert");
    expect(calls[0].context.failure_mode).toBe("sidecar_forged");
    expect(calls[0].message).toMatch(/sidecar tamper detected/i);
    expect(calls[0].context.source).toBe("api-server-monitor");

    // Subsequent ticks do not re-fire — one-shot latch.
    await monitor.tick();
    await monitor.tick();
    expect(calls).toHaveLength(1);

    try {
      unlinkSync(secretPath);
    } catch {
      /* ignore */
    }
  });

  it("surfaces lastOkSidecarStatus=forged on first build, then flips to ok after write (task #110)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: new Date(Date.now() + 60_000).toISOString(),
        lastCheckedAt: new Date().toISOString(),
        mac: "deadbeef".repeat(8),
      }) + "\n",
    );

    const secretPath = `${lastOkPath}.key`;
    const checker = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });

    // Boot-time consumption: the latch fires exactly once.
    expect(checker.consumeBootForgedAlert()).toBe(true);
    expect(checker.consumeBootForgedAlert()).toBe(false);

    try {
      unlinkSync(secretPath);
    } catch {
      /* ignore */
    }
  });

  it("fires exactly one 'checkpoint_stale' alert when the checkpoint mtime ages past the threshold, then 'recovered' when re-rolled (task #111)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus, hitsPath: hp, checkpointPath: cp } =
      createLedgerChecker({
        hitsPath,
        checkpointPath,
        lastOkPath,
        checkpointStaleThresholdSeconds: 60,
      });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      hitsPath: hp,
      checkpointPath: cp,
      logger: silentLogger(),
    });

    // Fresh checkpoint, not stale yet: no alert.
    await monitor.tick();
    expect(calls).toHaveLength(0);

    // Back-date the checkpoint mtime well past the 60s threshold.
    const stalePast = new Date(Date.now() - 30 * 86400 * 1000);
    utimesSync(checkpointPath, stalePast, stalePast);

    await monitor.tick();
    expect(calls).toHaveLength(1);
    expect(calls[0].kind).toBe("alert");
    expect(calls[0].context.failure_mode).toBe("checkpoint_stale");
    expect(calls[0].context.source).toBe("api-server-monitor");
    expect(calls[0].context.hits_path).toBe(hp);
    expect(calls[0].context.checkpoint_path).toBe(cp);
    expect(calls[0].context["checkpoint_stale_threshold_seconds"]).toBe(60);
    expect(
      typeof calls[0].context["checkpoint_age_seconds"],
    ).toBe("number");
    expect(calls[0].message).toMatch(/checkpoint is stale/i);
    expect(calls[0].message).toMatch(/re-roll/i);

    // Stays stale across ticks: silent (same dedup contract).
    await monitor.tick();
    await monitor.tick();
    expect(calls).toHaveLength(1);

    // Operator re-rolls the checkpoint: mtime is fresh again.
    const fresh = new Date();
    utimesSync(checkpointPath, fresh, fresh);

    await monitor.tick();
    expect(calls).toHaveLength(2);
    expect(calls[1].kind).toBe("recovered");
    expect(calls[1].context.failure_mode).toBe("recovered");
    expect(calls[1].context.previous_failure_mode).toBe("checkpoint_stale");
    expect(calls[1].message).toMatch(/checkpoint RECOVERED/i);

    // Stays fresh: silent.
    await monitor.tick();
    expect(calls).toHaveLength(2);

    // Goes stale again: fresh alert.
    utimesSync(checkpointPath, stalePast, stalePast);
    await monitor.tick();
    expect(calls).toHaveLength(3);
    expect(calls[2].kind).toBe("alert");
    expect(calls[2].context.failure_mode).toBe("checkpoint_stale");
  });

  it("checkpoint_stale alert is independent of the tamper-status state machine (task #111)", async () => {
    const sealed = "line1\nline2\nline3\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      checkpointStaleThresholdSeconds: 60,
    });
    const { sink, calls } = makeRecordingSink();
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
    });

    // Make the checkpoint stale AND tamper the live ledger in one tick.
    const stalePast = new Date(Date.now() - 30 * 86400 * 1000);
    utimesSync(checkpointPath, stalePast, stalePast);
    writeFileSync(hitsPath, "x");

    await monitor.tick();
    // Two alerts fire: one tamper, one checkpoint_stale.
    expect(calls).toHaveLength(2);
    const modes = calls.map((c) => c.context.failure_mode).sort();
    expect(modes).toEqual(["checkpoint_stale", "hits_truncated"]);
  });

  it("fires a 'monitor_stalled' watchdog alert when no tick completes in 2× interval, dedupes while stalled (task #113)", async () => {
    const sealed = "line1\nline2\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus, hitsPath: hp, checkpointPath: cp } =
      createLedgerChecker({ hitsPath, checkpointPath, lastOkPath });
    const { sink, calls } = makeRecordingSink();
    let clockMs = 1_000_000;
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      hitsPath: hp,
      checkpointPath: cp,
      logger: silentLogger(),
      now: () => clockMs,
    });

    // No tick has run yet, but only an instant has passed: not stalled.
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(0);

    // Advance just past the threshold (2× 60_000ms = 120_000ms).
    clockMs += 121_000;
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(1);
    expect(calls[0].kind).toBe("alert");
    expect(calls[0].context.failure_mode).toBe("monitor_stalled");
    expect(calls[0].context.source).toBe("api-server-monitor-watchdog");
    expect(calls[0].context.hits_path).toBe(hp);
    expect(calls[0].context.checkpoint_path).toBe(cp);
    expect(calls[0].context["stall_threshold_seconds"]).toBe(120);
    expect(calls[0].context["monitor_interval_seconds"]).toBe(60);
    expect(typeof calls[0].context["stall_age_seconds"]).toBe("number");
    expect(calls[0].message).toMatch(/watchdog/i);
    expect(calls[0].message).toMatch(/stalled/i);

    // Stays stalled across more checks: silent (dedup).
    clockMs += 60_000;
    await monitor.checkWatchdog();
    clockMs += 60_000;
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(1);
  });

  it("fires a 'monitor_recovered' watchdog alert once ticks resume after a stall (task #113)", async () => {
    const sealed = "line1\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    let clockMs = 5_000_000;
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
      now: () => clockMs,
    });

    // Stall.
    clockMs += 200_000;
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(1);
    expect(calls[0].context.failure_mode).toBe("monitor_stalled");

    // A real tick lands.
    await monitor.tick();

    // Watchdog notices the recovery on its next pass and fires exactly
    // one recovered alert.
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(2);
    expect(calls[1].kind).toBe("recovered");
    expect(calls[1].context.failure_mode).toBe("recovered");
    expect(calls[1].context.previous_failure_mode).toBe("monitor_stalled");
    expect(calls[1].context.source).toBe("api-server-monitor-watchdog");
    expect(calls[1].message).toMatch(/RECOVERED/);

    // Further healthy checks: silent.
    await monitor.checkWatchdog();
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(2);

    // If the monitor stalls AGAIN later, a fresh stalled alert fires.
    clockMs += 300_000;
    await monitor.checkWatchdog();
    expect(calls).toHaveLength(3);
    expect(calls[2].kind).toBe("alert");
    expect(calls[2].context.failure_mode).toBe("monitor_stalled");
  });

  it("watchdog stays quiet while ticks land regularly (task #113)", async () => {
    const sealed = "line1\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    let clockMs = 9_000_000;
    monitor = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 60_000,
      logger: silentLogger(),
      now: () => clockMs,
    });

    for (let i = 0; i < 5; i++) {
      clockMs += 60_000;
      await monitor.tick();
      await monitor.checkWatchdog();
    }
    expect(calls).toHaveLength(0);
  });

  it("stop() halts the interval", async () => {
    const sealed = "line1\n";
    const { size, sha } = writeHits(sealed);
    writeCheckpoint(size, sha);

    const { buildStatus } = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
    });
    const { sink, calls } = makeRecordingSink();
    const m = startLedgerMonitor({
      buildStatus,
      sink,
      intervalMs: 10,
      logger: silentLogger(),
    });
    writeFileSync(hitsPath, "");
    await new Promise((r) => setTimeout(r, 50));
    m.stop();
    const after = calls.length;
    await new Promise((r) => setTimeout(r, 60));
    expect(calls.length).toBe(after);
  });
});
