import { Router, type IRouter } from "express";
import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import {
  existsSync,
  openSync,
  readSync,
  closeSync,
  statSync,
  readFileSync,
  writeFileSync,
  renameSync,
  chmodSync,
} from "node:fs";
import path from "node:path";
import type {
  LedgerAlertContext,
  LedgerAlertInvocation,
  LedgerAlertSink,
} from "../lib/ledgerAlerts.js";
import { createKernelAlertSink } from "../lib/ledgerAlerts.js";
import { logger as defaultLogger } from "../lib/logger.js";

type FailureMode =
  | "hits_missing"
  | "checkpoint_missing"
  | "checkpoint_malformed"
  | "checkpoint_unreadable"
  | "hits_truncated"
  | "hits_rewritten_in_place";

interface LedgerIntegrityStatus {
  status: "ok" | "mismatch" | "missing";
  failureMode: FailureMode | null;
  reason: string | null;
  checkpointSize: number | null;
  checkpointSha: string | null;
  liveSize: number | null;
  livePrefixSha: string | null;
  growthBytes: number | null;
  checkedAt: string;
  ledgerLastModified: string | null;
  ledgerPath: string;
  checkpointPath: string;
  lastOkAt: string | null;
  lastOkAgeSeconds: number | null;
  lastCheckedAt: string | null;
  staleThresholdSeconds: number;
  stale: boolean;
  checkpointLastModified: string | null;
  checkpointAgeSeconds: number | null;
  checkpointCoverageRatio: number | null;
  checkpointStaleThresholdSeconds: number;
  checkpointStale: boolean;
}

const DEFAULT_STALE_THRESHOLD_SECONDS = 3600;
// Task #96: how old the committed checkpoint sidecar
// (`data/hits.txt.checkpoint`) may get before we flag the operator
// that the known-good prefix is no longer being re-rolled. Default
// 30 days — long enough to allow normal append-only workflow, short
// enough that a months-long stall surfaces before tamper coverage
// shrinks too far.
const DEFAULT_CHECKPOINT_STALE_THRESHOLD_SECONDS = 2_592_000;

function resolvePositiveSeconds(
  raw: string | undefined,
  fallback: number,
): number {
  if (raw == null) return fallback;
  const trimmed = raw.trim();
  if (trimmed === "") return fallback;
  const n = Number(trimmed);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.floor(n);
}

function resolveStaleThresholdSeconds(raw: string | undefined): number {
  return resolvePositiveSeconds(raw, DEFAULT_STALE_THRESHOLD_SECONDS);
}

function resolveCheckpointStaleThresholdSeconds(
  raw: string | undefined,
): number {
  return resolvePositiveSeconds(
    raw,
    DEFAULT_CHECKPOINT_STALE_THRESHOLD_SECONDS,
  );
}

function resolveRepoRoot(): string {
  const candidates = [
    process.cwd(),
    path.resolve(process.cwd(), "..", ".."),
    path.resolve(process.cwd(), ".."),
  ];
  for (const c of candidates) {
    if (existsSync(path.join(c, "data", "hits.txt"))) return c;
    if (existsSync(path.join(c, "data", "hits.txt.checkpoint"))) return c;
  }
  return candidates[0];
}

function readPrefixSha(filePath: string, size: number): string {
  const fd = openSync(filePath, "r");
  try {
    const buf = Buffer.alloc(size);
    let off = 0;
    while (off < size) {
      const n = readSync(fd, buf, off, size - off, off);
      if (n === 0) break;
      off += n;
    }
    return createHash("sha256").update(buf.subarray(0, off)).digest("hex");
  } finally {
    closeSync(fd);
  }
}

export interface LedgerRouterOptions {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath?: string;
  /**
   * Path to the per-deploy HMAC secret used to authenticate the
   * `lastOkPath` sidecar payload. Defaults to `${lastOkPath}.key`.
   * The secret is auto-generated (32 random bytes, hex) on first use
   * if the file is absent. Tamper detection: if an attacker writes a
   * forged `{lastOkAt: <future>}` to the sidecar without the secret,
   * the HMAC won't verify and the persisted value is dropped on read.
   */
  secretPath?: string;
  staleThresholdSeconds?: number;
  checkpointStaleThresholdSeconds?: number;
}

export type { LedgerIntegrityStatus, FailureMode };

interface PersistedState {
  lastOkAt: string | null;
  lastCheckedAt: string | null;
}

interface SidecarPayload {
  lastOkAt: string | null;
  lastCheckedAt: string | null;
  /**
   * Checkpoint binding — the size+sha of `data/hits.txt.checkpoint` at
   * the time this sidecar was written. On read, if the current
   * checkpoint differs, we don't trust the persisted `lastOkAt` (the
   * verification was against a different sealed prefix). Belt-and-
   * suspenders alongside the HMAC.
   */
  boundCheckpointSize: number | null;
  boundCheckpointSha: string | null;
}

function loadOrCreateSecret(
  secretPath: string,
  logger?: { warn: (...args: unknown[]) => void },
): Buffer {
  try {
    if (existsSync(secretPath)) {
      const raw = readFileSync(secretPath, "utf-8").trim();
      if (/^[0-9a-f]{64}$/i.test(raw)) {
        return Buffer.from(raw, "hex");
      }
      logger?.warn?.(
        { secretPath },
        "ledger sidecar: secret file malformed; regenerating",
      );
    }
  } catch (err) {
    logger?.warn?.(
      { err, secretPath },
      "ledger sidecar: secret file unreadable; regenerating",
    );
  }
  const secret = randomBytes(32);
  try {
    const tmp = `${secretPath}.tmp`;
    writeFileSync(tmp, secret.toString("hex") + "\n");
    try {
      chmodSync(tmp, 0o600);
    } catch {
      /* best-effort */
    }
    renameSync(tmp, secretPath);
  } catch (err) {
    logger?.warn?.(
      { err, secretPath },
      "ledger sidecar: could not persist secret (using in-memory only; persistence disabled across restart)",
    );
  }
  return secret;
}

function readCheckpointTuple(
  checkpointPath: string,
): { size: number; sha: string } | null {
  try {
    if (!existsSync(checkpointPath)) return null;
    const raw = readFileSync(checkpointPath, "utf-8").trim();
    const parts = raw.split(/\s+/);
    if (parts.length !== 2) return null;
    const size = Number.parseInt(parts[0], 10);
    if (!Number.isFinite(size) || size < 0 || String(size) !== parts[0]) {
      return null;
    }
    const sha = parts[1].toLowerCase();
    if (!/^[0-9a-f]{64}$/.test(sha)) return null;
    return { size, sha };
  } catch {
    return null;
  }
}

function canonicalize(p: SidecarPayload): string {
  // Stable key order — JSON.stringify with explicit ordering so the
  // HMAC input is deterministic regardless of property iteration order.
  return JSON.stringify({
    lastOkAt: p.lastOkAt,
    lastCheckedAt: p.lastCheckedAt,
    boundCheckpointSize: p.boundCheckpointSize,
    boundCheckpointSha: p.boundCheckpointSha,
  });
}

function computeMac(secret: Buffer, payload: SidecarPayload): string {
  return createHmac("sha256", secret)
    .update(canonicalize(payload))
    .digest("hex");
}

function verifyMac(secret: Buffer, payload: SidecarPayload, mac: string): boolean {
  if (!/^[0-9a-f]{64}$/i.test(mac)) return false;
  const expected = computeMac(secret, payload);
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(mac, "hex");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

function readPersistedState(
  sidecarPath: string,
  secret: Buffer,
  checkpointPath: string,
  logger?: { warn: (...args: unknown[]) => void },
): PersistedState {
  const empty: PersistedState = { lastOkAt: null, lastCheckedAt: null };
  try {
    if (!existsSync(sidecarPath)) return empty;
    const raw = readFileSync(sidecarPath, "utf-8");
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object") return empty;
    const obj = parsed as Record<string, unknown>;
    const mac = typeof obj["mac"] === "string" ? (obj["mac"] as string) : null;
    if (!mac) {
      logger?.warn?.(
        { sidecarPath },
        "ledger sidecar: missing mac — treating as forged, discarding",
      );
      return empty;
    }
    function pickIso(key: string): string | null {
      const v = obj[key];
      if (typeof v !== "string") return null;
      return Number.isNaN(Date.parse(v)) ? null : v;
    }
    function pickInt(key: string): number | null {
      const v = obj[key];
      return typeof v === "number" && Number.isFinite(v) ? v : null;
    }
    function pickShaOrNull(key: string): string | null {
      const v = obj[key];
      if (typeof v !== "string") return null;
      return /^[0-9a-f]{64}$/i.test(v) ? v.toLowerCase() : null;
    }
    const payload: SidecarPayload = {
      lastOkAt: pickIso("lastOkAt"),
      lastCheckedAt: pickIso("lastCheckedAt"),
      boundCheckpointSize: pickInt("boundCheckpointSize"),
      boundCheckpointSha: pickShaOrNull("boundCheckpointSha"),
    };
    if (!verifyMac(secret, payload, mac)) {
      logger?.warn?.(
        { sidecarPath },
        "ledger sidecar: HMAC mismatch — treating as forged, discarding",
      );
      return empty;
    }
    // Checkpoint-binding check: if a bound checkpoint was recorded
    // (i.e. lastOkAt was set), it must still match the on-disk
    // checkpoint. A different checkpoint means the sealed prefix has
    // moved on; the persisted lastOkAt refers to a stale verification.
    if (payload.lastOkAt != null) {
      const cur = readCheckpointTuple(checkpointPath);
      if (
        cur == null ||
        cur.size !== payload.boundCheckpointSize ||
        cur.sha !== payload.boundCheckpointSha
      ) {
        logger?.warn?.(
          { sidecarPath },
          "ledger sidecar: checkpoint binding stale — discarding lastOkAt",
        );
        return { lastOkAt: null, lastCheckedAt: payload.lastCheckedAt };
      }
    }
    return {
      lastOkAt: payload.lastOkAt,
      lastCheckedAt: payload.lastCheckedAt,
    };
  } catch {
    return empty;
  }
}

function writePersistedState(
  sidecarPath: string,
  secret: Buffer,
  checkpointPath: string,
  state: PersistedState,
): void {
  try {
    let bound: { size: number; sha: string } | null = null;
    if (state.lastOkAt != null) {
      bound = readCheckpointTuple(checkpointPath);
    }
    const payload: SidecarPayload = {
      lastOkAt: state.lastOkAt,
      lastCheckedAt: state.lastCheckedAt,
      boundCheckpointSize: bound ? bound.size : null,
      boundCheckpointSha: bound ? bound.sha : null,
    };
    const mac = computeMac(secret, payload);
    const tmp = `${sidecarPath}.tmp`;
    writeFileSync(tmp, JSON.stringify({ ...payload, mac }) + "\n");
    renameSync(tmp, sidecarPath);
  } catch {
    // Best-effort: never let a sidecar write failure break the endpoint.
  }
}

export interface LedgerChecker {
  router: IRouter;
  buildStatus: () => LedgerIntegrityStatus;
  hitsPath: string;
  checkpointPath: string;
}

export function createLedgerChecker(opts: LedgerRouterOptions): LedgerChecker {
  const HITS = opts.hitsPath;
  const CHECKPOINT = opts.checkpointPath;
  const LAST_OK_PATH = opts.lastOkPath ?? `${opts.hitsPath}.lastok`;
  const SECRET_PATH = opts.secretPath ?? `${LAST_OK_PATH}.key`;
  const STALE_THRESHOLD_SECONDS =
    opts.staleThresholdSeconds != null && Number.isFinite(opts.staleThresholdSeconds) && opts.staleThresholdSeconds > 0
      ? Math.floor(opts.staleThresholdSeconds)
      : resolveStaleThresholdSeconds(process.env.LEDGER_STALE_THRESHOLD_SECONDS);
  const CHECKPOINT_STALE_THRESHOLD_SECONDS =
    opts.checkpointStaleThresholdSeconds != null &&
    Number.isFinite(opts.checkpointStaleThresholdSeconds) &&
    opts.checkpointStaleThresholdSeconds > 0
      ? Math.floor(opts.checkpointStaleThresholdSeconds)
      : resolveCheckpointStaleThresholdSeconds(
          process.env.LEDGER_CHECKPOINT_STALE_THRESHOLD_SECONDS,
        );
  const SIDECAR_SECRET = loadOrCreateSecret(SECRET_PATH, defaultLogger);
  const persisted = readPersistedState(
    LAST_OK_PATH,
    SIDECAR_SECRET,
    CHECKPOINT,
    defaultLogger,
  );
  let lastOkAt: string | null = persisted.lastOkAt;
  let lastCheckedAt: string | null = persisted.lastCheckedAt;

  function computeStaleness(checkedAtIso: string): {
    lastOkAgeSeconds: number | null;
    stale: boolean;
  } {
    if (!lastOkAt) {
      return { lastOkAgeSeconds: null, stale: true };
    }
    const okMs = Date.parse(lastOkAt);
    const nowMs = Date.parse(checkedAtIso);
    if (!Number.isFinite(okMs) || !Number.isFinite(nowMs)) {
      return { lastOkAgeSeconds: null, stale: true };
    }
    const ageSeconds = Math.max(0, Math.floor((nowMs - okMs) / 1000));
    return { lastOkAgeSeconds: ageSeconds, stale: ageSeconds > STALE_THRESHOLD_SECONDS };
  }

  function computeCheckpointMetrics(
    checkedAtIso: string,
    liveSize: number | null,
  ): {
    checkpointLastModified: string | null;
    checkpointAgeSeconds: number | null;
    checkpointCoverageRatio: number | null;
    checkpointStale: boolean;
    checkpointSize: number | null;
  } {
    let checkpointLastModified: string | null = null;
    let checkpointAgeSeconds: number | null = null;
    let checkpointSize: number | null = null;
    try {
      if (existsSync(CHECKPOINT)) {
        const st = statSync(CHECKPOINT);
        checkpointLastModified = st.mtime.toISOString();
        const nowMs = Date.parse(checkedAtIso);
        const mtimeMs = st.mtime.getTime();
        if (Number.isFinite(nowMs) && Number.isFinite(mtimeMs)) {
          checkpointAgeSeconds = Math.max(
            0,
            Math.floor((nowMs - mtimeMs) / 1000),
          );
        }
      }
    } catch {
      /* best-effort */
    }
    const tuple = readCheckpointTuple(CHECKPOINT);
    if (tuple) checkpointSize = tuple.size;
    let checkpointCoverageRatio: number | null = null;
    if (
      checkpointSize != null &&
      liveSize != null &&
      liveSize > 0
    ) {
      checkpointCoverageRatio = Math.min(1, checkpointSize / liveSize);
    }
    const checkpointStale =
      checkpointAgeSeconds == null ||
      checkpointAgeSeconds > CHECKPOINT_STALE_THRESHOLD_SECONDS;
    return {
      checkpointLastModified,
      checkpointAgeSeconds,
      checkpointCoverageRatio,
      checkpointStale,
      checkpointSize,
    };
  }

  function buildStatus(): LedgerIntegrityStatus {
    const result = buildStatusInner();
    // Recompute coverage with the final liveSize so the coverage ratio
    // reflects the actual on-disk file, not the placeholder we seeded
    // before stat'ing the ledger.
    const m = computeCheckpointMetrics(result.checkedAt, result.liveSize);
    return {
      ...result,
      checkpointLastModified: m.checkpointLastModified,
      checkpointAgeSeconds: m.checkpointAgeSeconds,
      checkpointCoverageRatio: m.checkpointCoverageRatio,
      checkpointStale: m.checkpointStale,
    };
  }

  function buildStatusInner(): LedgerIntegrityStatus {
    const checkedAt = new Date().toISOString();
    const { lastOkAgeSeconds, stale } = computeStaleness(checkedAt);
    const cpInit = computeCheckpointMetrics(checkedAt, null);
    const base: LedgerIntegrityStatus = {
      status: "ok",
      failureMode: null,
      reason: null,
      checkpointSize: null,
      checkpointSha: null,
      liveSize: null,
      livePrefixSha: null,
      growthBytes: null,
      checkedAt,
      ledgerLastModified: null,
      ledgerPath: HITS,
      checkpointPath: CHECKPOINT,
      lastOkAt,
      lastOkAgeSeconds,
      lastCheckedAt,
      staleThresholdSeconds: STALE_THRESHOLD_SECONDS,
      stale,
      checkpointLastModified: cpInit.checkpointLastModified,
      checkpointAgeSeconds: cpInit.checkpointAgeSeconds,
      checkpointCoverageRatio: cpInit.checkpointCoverageRatio,
      checkpointStaleThresholdSeconds: CHECKPOINT_STALE_THRESHOLD_SECONDS,
      checkpointStale: cpInit.checkpointStale,
    };


    // Always update lastCheckedAt — we ran a check regardless of outcome.
    lastCheckedAt = checkedAt;
    writePersistedState(LAST_OK_PATH, SIDECAR_SECRET, CHECKPOINT, { lastOkAt, lastCheckedAt });
    base.lastCheckedAt = lastCheckedAt;

    if (!existsSync(HITS)) {
      return {
        ...base,
        status: "missing",
        failureMode: "hits_missing",
        reason: `${HITS} missing.`,
      };
    }

    let liveSize: number;
    let ledgerLastModified: string | null = null;
    try {
      const st = statSync(HITS);
      liveSize = st.size;
      ledgerLastModified = st.mtime.toISOString();
    } catch (e) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "hits_missing",
        reason: `Cannot stat ${HITS}: ${(e as Error).message}`,
      };
    }

    if (!existsSync(CHECKPOINT)) {
      return {
        ...base,
        status: "missing",
        failureMode: "checkpoint_missing",
        reason: `${CHECKPOINT} missing — cannot verify at-rest integrity. This file is committed; restore it from git.`,
        liveSize,
        ledgerLastModified,
      };
    }

    let raw: string;
    try {
      raw = readFileSync(CHECKPOINT, "utf-8").trim();
    } catch (e) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "checkpoint_unreadable",
        reason: `Cannot read ${CHECKPOINT}: ${(e as Error).message}`,
        liveSize,
        ledgerLastModified,
      };
    }

    const parts = raw.split(/\s+/);
    if (parts.length !== 2) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "checkpoint_malformed",
        reason: `${CHECKPOINT} malformed (expected '<size> <sha256>', got ${JSON.stringify(raw)}).`,
        liveSize,
        ledgerLastModified,
      };
    }

    const expectedSize = Number.parseInt(parts[0], 10);
    if (!Number.isFinite(expectedSize) || expectedSize < 0 || String(expectedSize) !== parts[0]) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "checkpoint_malformed",
        reason: `${CHECKPOINT} size field not a non-negative integer: ${JSON.stringify(parts[0])}.`,
        liveSize,
        ledgerLastModified,
      };
    }

    const expectedSha = parts[1].toLowerCase();
    if (!/^[0-9a-f]{64}$/.test(expectedSha)) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "checkpoint_malformed",
        reason: `${CHECKPOINT} sha256 field malformed: ${JSON.stringify(parts[1])}.`,
        checkpointSize: expectedSize,
        liveSize,
        ledgerLastModified,
      };
    }

    if (liveSize < expectedSize) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "hits_truncated",
        reason:
          `${HITS} SHRUNK — expected at least ${expectedSize} bytes, got ${liveSize}. ` +
          `TRUNCATION or in-place rewrite suspected. See docs/REPRODUCE.md for recovery.`,
        checkpointSize: expectedSize,
        checkpointSha: expectedSha,
        liveSize,
        ledgerLastModified,
      };
    }

    let prefixSha: string;
    try {
      prefixSha = readPrefixSha(HITS, expectedSize);
    } catch (e) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "checkpoint_unreadable",
        reason: `Cannot hash ${HITS} prefix: ${(e as Error).message}`,
        checkpointSize: expectedSize,
        checkpointSha: expectedSha,
        liveSize,
        ledgerLastModified,
      };
    }

    if (prefixSha !== expectedSha) {
      return {
        ...base,
        status: "mismatch",
        failureMode: "hits_rewritten_in_place",
        reason:
          `${HITS} first ${expectedSize} bytes have been rewritten in place. ` +
          `expected sha256: ${expectedSha} got sha256: ${prefixSha}. ` +
          `The ledger is append-only; in-place edits are not permitted.`,
        checkpointSize: expectedSize,
        checkpointSha: expectedSha,
        liveSize,
        livePrefixSha: prefixSha,
        ledgerLastModified,
      };
    }

    lastOkAt = checkedAt;
    writePersistedState(LAST_OK_PATH, SIDECAR_SECRET, CHECKPOINT, { lastOkAt, lastCheckedAt });
    const freshStaleness = computeStaleness(checkedAt);
    return {
      ...base,
      status: "ok",
      checkpointSize: expectedSize,
      checkpointSha: expectedSha,
      liveSize,
      livePrefixSha: prefixSha,
      growthBytes: liveSize - expectedSize,
      ledgerLastModified,
      lastOkAt,
      lastOkAgeSeconds: freshStaleness.lastOkAgeSeconds,
      lastCheckedAt,
      stale: freshStaleness.stale,
    };
  }

  const router: IRouter = Router();
  router.get("/ledger/integrity", (_req, res) => {
    res.status(200).json(buildStatus());
  });
  return { router, buildStatus, hitsPath: HITS, checkpointPath: CHECKPOINT };
}

export function createLedgerRouter(opts: LedgerRouterOptions): IRouter {
  return createLedgerChecker(opts).router;
}

export interface LedgerMonitorOptions {
  buildStatus: () => LedgerIntegrityStatus;
  sink: LedgerAlertSink;
  intervalMs: number;
  hitsPath?: string;
  checkpointPath?: string;
  logger?: {
    info: (...args: unknown[]) => void;
    warn: (...args: unknown[]) => void;
    error: (...args: unknown[]) => void;
  };
}

export interface LedgerMonitorHandle {
  stop: () => void;
  tick: () => Promise<void>;
}

/**
 * Task #85: server-side recurring integrity check. Calls the same
 * buildStatus() the GET /api/ledger/integrity route uses, and forwards
 * any non-ok result through `sink` (by default a thin shell into
 * `kernel._fire_ledger_alert` so webhook / SMTP transports, payload
 * shape and the ALERTS_LOG ring buffer all stay in lock-step with the
 * Python-side append guard).
 *
 * Dedup contract:
 *   - On status !== 'ok', fire one alert. While the status stays
 *     non-ok with the SAME failureMode, do NOT re-spam.
 *   - If failureMode CHANGES while still non-ok (e.g. truncated →
 *     rewritten_in_place), fire a fresh alert — that's a new incident.
 *   - On the first ok check after any alerted state, fire exactly one
 *     "recovered" alert; subsequent ok checks are silent.
 */
export function startLedgerMonitor(
  opts: LedgerMonitorOptions,
): LedgerMonitorHandle {
  const log = opts.logger ?? defaultLogger;
  let lastAlerted: "none" | "alerted" = "none";
  let lastFailureMode: string | null = null;
  let inFlight = false;

  async function tick(): Promise<void> {
    if (inFlight) return;
    inFlight = true;
    try {
      let s: LedgerIntegrityStatus;
      try {
        s = opts.buildStatus();
      } catch (err) {
        log.error(
          { err },
          "ledger monitor: buildStatus threw, skipping this tick",
        );
        return;
      }
      const commonCtx = {
        hits_path: opts.hitsPath,
        checkpoint_path: opts.checkpointPath,
        source: "api-server-monitor",
      };
      if (s.status !== "ok") {
        if (
          lastAlerted !== "alerted" ||
          lastFailureMode !== s.failureMode
        ) {
          const context: LedgerAlertContext = {
            failure_mode: s.failureMode,
            expected_size: s.checkpointSize,
            expected_sha: s.checkpointSha,
            actual_size: s.liveSize,
            actual_sha: s.livePrefixSha,
            checked_at: s.checkedAt,
            ...commonCtx,
          };
          const message =
            `Ledger integrity check failed (api-server monitor): ` +
            (s.reason ?? s.failureMode ?? "unknown failure");
          const invocation: LedgerAlertInvocation = {
            kind: "alert",
            message,
            context,
          };
          log.warn(
            { failureMode: s.failureMode, status: s.status },
            "ledger monitor: firing alert",
          );
          try {
            await opts.sink(invocation);
          } catch (err) {
            log.warn(
              { err },
              "ledger monitor: alert sink threw (best-effort, swallowed)",
            );
          }
          lastAlerted = "alerted";
          lastFailureMode = s.failureMode;
        }
      } else if (lastAlerted === "alerted") {
        const prev = lastFailureMode;
        const context: LedgerAlertContext = {
          failure_mode: "recovered",
          previous_failure_mode: prev,
          actual_size: s.liveSize,
          actual_sha: s.livePrefixSha,
          checked_at: s.checkedAt,
          ...commonCtx,
        };
        const message =
          `Ledger integrity RECOVERED (api-server monitor): ` +
          `previous failure mode = ${prev ?? "unknown"}`;
        const invocation: LedgerAlertInvocation = {
          kind: "recovered",
          message,
          context,
        };
        log.info(
          { previousFailureMode: prev },
          "ledger monitor: firing recovery alert",
        );
        try {
          await opts.sink(invocation);
        } catch (err) {
          log.warn(
            { err },
            "ledger monitor: recovery sink threw (best-effort, swallowed)",
          );
        }
        lastAlerted = "none";
        lastFailureMode = null;
      }
    } finally {
      inFlight = false;
    }
  }

  const handle = setInterval(() => {
    void tick();
  }, opts.intervalMs);
  handle.unref?.();

  return {
    stop() {
      clearInterval(handle);
    },
    tick,
  };
}

const DEFAULT_MONITOR_INTERVAL_SECONDS = 300;

function resolveMonitorIntervalSeconds(
  raw: string | undefined,
): number | null {
  if (raw == null) return DEFAULT_MONITOR_INTERVAL_SECONDS;
  const trimmed = raw.trim();
  if (trimmed === "") return DEFAULT_MONITOR_INTERVAL_SECONDS;
  if (/^(off|disabled?|none|0)$/i.test(trimmed)) return null;
  const n = Number(trimmed);
  if (!Number.isFinite(n) || n <= 0) {
    return DEFAULT_MONITOR_INTERVAL_SECONDS;
  }
  return Math.floor(n);
}

const REPO_ROOT = resolveRepoRoot();
const defaultChecker = createLedgerChecker({
  hitsPath: path.join(REPO_ROOT, "data", "hits.txt"),
  checkpointPath: path.join(REPO_ROOT, "data", "hits.txt.checkpoint"),
});

const monitorIntervalSeconds = resolveMonitorIntervalSeconds(
  process.env["LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS"],
);
if (monitorIntervalSeconds != null) {
  startLedgerMonitor({
    buildStatus: defaultChecker.buildStatus,
    sink: createKernelAlertSink({
      repoRoot: REPO_ROOT,
      logger: defaultLogger,
    }),
    intervalMs: monitorIntervalSeconds * 1000,
    hitsPath: defaultChecker.hitsPath,
    checkpointPath: defaultChecker.checkpointPath,
    logger: defaultLogger,
  });
  defaultLogger.info(
    { intervalSeconds: monitorIntervalSeconds },
    "ledger monitor: started (auto integrity check on a timer)",
  );
} else {
  defaultLogger.info(
    "ledger monitor: disabled (LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS=off)",
  );
}

export default defaultChecker.router;
