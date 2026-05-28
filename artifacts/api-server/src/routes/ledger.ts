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
  unlinkSync,
  constants as fsConstants,
} from "node:fs";
import path from "node:path";
import type {
  LedgerAlertContext,
  LedgerAlertInvocation,
  LedgerAlertSink,
} from "../lib/ledgerAlerts.js";
import { createKernelAlertSink } from "../lib/ledgerAlerts.js";
import {
  computeAlertId,
  defaultAlertsAckPath,
  isAlertAcknowledged,
} from "../lib/alertAckStore.js";
import { logger as defaultLogger } from "../lib/logger.js";

type FailureMode =
  | "hits_missing"
  | "checkpoint_missing"
  | "checkpoint_malformed"
  | "checkpoint_unreadable"
  | "hits_truncated"
  | "hits_rewritten_in_place";

// Task #110: status of the persisted `data/hits.txt.lastok` sidecar
// the last time the server tried to read it. `ok` = HMAC verified and
// checkpoint binding matches. `missing` = no sidecar file on disk (a
// fresh deploy or a wipe). `forged` = the file existed but the HMAC
// did not verify (a missing `mac` field, a malformed mac, or a wrong
// mac — i.e. someone wrote the file without the per-deploy secret).
// `stale_checkpoint_binding` = HMAC verified but `boundCheckpointSha`
// / `boundCheckpointSize` no longer match the on-disk checkpoint, so
// the persisted `lastOkAt` refers to a different sealed prefix and we
// discard it. `missing` / `stale_checkpoint_binding` are benign /
// recoverable; `forged` is a tamper signal and triggers a red banner
// + a one-shot monitor alert on boot.
type LastOkSidecarStatus =
  | "ok"
  | "missing"
  | "forged"
  | "stale_checkpoint_binding";

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
  lastCheckedAgeSeconds: number | null;
  staleThresholdSeconds: number;
  stale: boolean;
  checkedStaleThresholdSeconds: number;
  checkedStale: boolean;
  checkpointLastModified: string | null;
  checkpointAgeSeconds: number | null;
  checkpointCoverageRatio: number | null;
  checkpointStaleThresholdSeconds: number;
  checkpointStale: boolean;
  // Task #110: tamper-state of the persisted `lastOk` sidecar.
  // Surfaces a red banner in the dashboard on `forged` so operators
  // see a tamper attempt distinctly from a fresh boot (`missing`).
  lastOkSidecarStatus: LastOkSidecarStatus;
  /**
   * Task #137: whether the API server was booted with
   * `LEDGER_SIDECAR_SECRET_STRICT_MODE` enabled. Sourced from the
   * same `isSidecarSecretStrictMode` helper used at boot so this
   * value cannot drift from the runtime posture. Surfaced as a small
   * badge on the Ledger Integrity dashboard card so operators can
   * confirm a hardened deploy at a glance.
   */
  sidecarSecretStrictMode: boolean;
  /**
   * Task #124: ISO-8601 timestamp at which the operator acknowledged
   * the current forged-sidecar incident via
   * `POST /ledger/sidecar-forged-ack`. Null while the banner is
   * still un-acked (or when there is no forged incident at all).
   * The dashboard renders an "acknowledged" badge on the banner and
   * keeps it visible (sticky) until a fresh forged read on next boot
   * either clears the incident (sidecar gone / written ok) or
   * replaces it with a new un-acked one (a different forged payload).
   */
  lastOkSidecarStatusAcknowledgedAt: string | null;
  /**
   * Task #139: attribution for the operator that dismissed the
   * current forged-sidecar incident. Mirrors the named-token
   * attribution used by `POST /api/lean/verify/rebuild`: a matched
   * named token from `LEDGER_REBUILD_TOKENS` wins; otherwise the
   * sanitized `X-Referee-Name` header; otherwise the literal string
   * `"anonymous"` (shared-token deploys with no header). Null while
   * the banner is still un-acked (or when there is no forged
   * incident at all). Persisted alongside `acknowledgedAt` in
   * `data/hits.txt.lastok.forged-ack` so attribution survives a
   * restart of the API server.
   */
  lastOkSidecarStatusAcknowledgedBy: string | null;
}

const DEFAULT_STALE_THRESHOLD_SECONDS = 3600;
// Task #96: how old the committed checkpoint sidecar
// (`data/hits.txt.checkpoint`) may get before we flag the operator
// that the known-good prefix is no longer being re-rolled. Default
// 30 days — long enough to allow normal append-only workflow, short
// enough that a months-long stall surfaces before tamper coverage
// shrinks too far.
const DEFAULT_CHECKPOINT_STALE_THRESHOLD_SECONDS = 2_592_000;
// Task #99: how stale `lastCheckedAt` may get before we flag the
// operator that the verifier itself has stopped *running* (not just
// stopped seeing OK results). The default is computed at request
// time as `2 × monitorIntervalSeconds` when a monitor is registered
// (see `resolveCheckedStaleThreshold` below); this constant is the
// hard fallback when no monitor is available (e.g. integration tests
// that construct a `createLedgerChecker` without ever starting the
// background timer). 600s = 2 × default 300s monitor interval.
const DEFAULT_CHECKED_STALE_THRESHOLD_SECONDS = 600;

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

function resolveCheckedStaleThresholdSecondsFromEnv(
  raw: string | undefined,
): number | null {
  // Returns null when unset/empty so the caller can fall back to
  // `2 × monitorIntervalSeconds`. A bad value falls back too (null)
  // rather than silently coercing to the hard 600s default — we want
  // the monitor-derived default to win when the env var is junk.
  if (raw == null) return null;
  const trimmed = raw.trim();
  if (trimmed === "") return null;
  const n = Number(trimmed);
  if (!Number.isFinite(n) || n <= 0) return null;
  return Math.floor(n);
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
  /**
   * Task #99: how stale `lastCheckedAt` may get before the integrity
   * endpoint flags `checkedStale: true`. When omitted, the threshold
   * is sourced from `LEDGER_CHECKED_STALE_THRESHOLD_SECONDS`. When
   * THAT is also unset, the threshold is computed lazily at status-
   * build time as `2 × monitorIntervalSeconds` (from the registered
   * monitor info provider), falling back to
   * `DEFAULT_CHECKED_STALE_THRESHOLD_SECONDS` if no monitor is
   * registered. Distinct from `staleThresholdSeconds`, which is
   * about `lastOkAt` (last *successful* check) — `checkedStale` is
   * about `lastCheckedAt` (last *attempted* check) and closes the
   * blind spot where the verifier silently stops running.
   */
  checkedStaleThresholdSeconds?: number;
}

export type { LedgerIntegrityStatus, FailureMode };

interface PersistedState {
  lastOkAt: string | null;
  lastCheckedAt: string | null;
  // Task #110: result of the most recent sidecar-read attempt. The
  // closure in `createLedgerChecker` stashes the boot read so the
  // dashboard can surface `forged` distinctly from `missing`.
  sidecarStatus: LastOkSidecarStatus;
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

/**
 * Task #109: warn loudly if the on-disk keyfile is readable by anyone
 * other than the owner. The HMAC scheme protects against an attacker
 * who can write the sidecar but NOT read the key; a group/world-
 * readable keyfile collapses that protection because the attacker can
 * forge a valid MAC. We surface this on startup so the operator can
 * `chmod 600` (or move the secret out of the data dir entirely via
 * `LEDGER_SIDECAR_SECRET_PATH` / `LEDGER_SIDECAR_SECRET`) before the
 * next deploy. Best-effort: on platforms where `statSync().mode` is
 * not meaningful (e.g. Windows, some FUSE mounts) we skip silently
 * rather than spamming warnings.
 */
/**
 * Task #123: thrown by `loadOrCreateSecret` when strict mode is on
 * and the on-disk keyfile is group/world-readable. Surfaces as a
 * hard startup failure from `createLedgerChecker` so the API server
 * refuses to boot rather than silently logging a warning that may
 * get lost in production log noise.
 */
export class SidecarSecretLooseModeError extends Error {
  readonly secretPath: string;
  readonly mode: string;
  constructor(secretPath: string, mode: string) {
    super(
      `ledger sidecar: secret file ${secretPath} is group/world-readable (mode ${mode}) and LEDGER_SIDECAR_SECRET_STRICT_MODE is enabled — chmod 600, relocate via LEDGER_SIDECAR_SECRET_PATH, or supply LEDGER_SIDECAR_SECRET as an inline hex value`,
    );
    this.name = "SidecarSecretLooseModeError";
    this.secretPath = secretPath;
    this.mode = mode;
  }
}

/**
 * Task #109: warn loudly if the on-disk keyfile is readable by anyone
 * other than the owner. The HMAC scheme protects against an attacker
 * who can write the sidecar but NOT read the key; a group/world-
 * readable keyfile collapses that protection because the attacker can
 * forge a valid MAC. We surface this on startup so the operator can
 * `chmod 600` (or move the secret out of the data dir entirely via
 * `LEDGER_SIDECAR_SECRET_PATH` / `LEDGER_SIDECAR_SECRET`) before the
 * next deploy. Best-effort: on platforms where `statSync().mode` is
 * not meaningful (e.g. Windows, some FUSE mounts) we skip silently
 * rather than spamming warnings.
 *
 * Task #123: returns `{ loose, mode }` so the caller can promote the
 * warning to a hard startup failure when strict mode is enabled.
 */
function warnIfSecretFileLoose(
  secretPath: string,
  logger?: { warn: (...args: unknown[]) => void },
): { loose: boolean; mode: string | null } {
  try {
    const st = statSync(secretPath);
    // Low 9 bits = rwxrwxrwx. We only care about group + other read bits.
    const looseBits = st.mode & (fsConstants.S_IRGRP | fsConstants.S_IROTH);
    if (looseBits !== 0) {
      const modeOctal = (st.mode & 0o777).toString(8).padStart(3, "0");
      logger?.warn?.(
        { secretPath, mode: modeOctal },
        "ledger sidecar: secret file is group/world-readable — an attacker with read access can forge sidecar HMACs; chmod 600 or move the secret out of the data dir (set LEDGER_SIDECAR_SECRET_PATH to a tighter-ACL path, or LEDGER_SIDECAR_SECRET to an inline hex value with no on-disk fallback)",
      );
      return { loose: true, mode: modeOctal };
    }
    return { loose: false, mode: (st.mode & 0o777).toString(8).padStart(3, "0") };
  } catch {
    /* best-effort — stat may be unsupported, that's fine */
    return { loose: false, mode: null };
  }
}

/**
 * Task #123: parse `LEDGER_SIDECAR_SECRET_STRICT_MODE`. Truthy values
 * (`1`, `true`, `yes`, `on`, case-insensitive) enable strict mode.
 * Anything else (including unset / empty / `0` / `false`) leaves the
 * existing lenient-warn posture in place — backward compatible.
 */
export function isSidecarSecretStrictMode(raw: string | undefined): boolean {
  if (raw == null) return false;
  const v = raw.trim().toLowerCase();
  return v === "1" || v === "true" || v === "yes" || v === "on";
}

/**
 * Task #109: prefer an env-var-only secret when set, so the keyfile
 * never touches disk. Accepts 64-char lowercase/uppercase hex (32
 * bytes). Invalid/empty values fall through to the file-based path
 * with a warning rather than silently disabling the protection.
 */
function loadInlineSecret(
  raw: string | undefined,
  logger?: { warn: (...args: unknown[]) => void },
): Buffer | null {
  if (raw == null) return null;
  const trimmed = raw.trim();
  if (trimmed === "") return null;
  if (!/^[0-9a-f]{64}$/i.test(trimmed)) {
    logger?.warn?.(
      "ledger sidecar: LEDGER_SIDECAR_SECRET set but not a 64-char hex string; falling back to on-disk keyfile",
    );
    return null;
  }
  return Buffer.from(trimmed, "hex");
}

function loadOrCreateSecret(
  secretPath: string,
  logger?: { warn: (...args: unknown[]) => void },
  inlineSecret?: string | undefined,
  strictMode: boolean = false,
): Buffer {
  const inline = loadInlineSecret(inlineSecret, logger);
  if (inline != null) return inline;
  try {
    if (existsSync(secretPath)) {
      const looseResult = warnIfSecretFileLoose(secretPath, logger);
      if (strictMode && looseResult.loose) {
        // Task #123: hard-fail boot in strict mode. We deliberately
        // throw a typed error before reading the keyfile so a forged
        // secret can never reach the HMAC verifier in this posture.
        throw new SidecarSecretLooseModeError(
          secretPath,
          looseResult.mode ?? "???",
        );
      }
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
    // Task #123: strict-mode loose-keyfile failure must propagate.
    // Anything else (e.g. transient read errors) falls through to the
    // existing "regenerate the secret" recovery path.
    if (err instanceof SidecarSecretLooseModeError) throw err;
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
    // Defensive re-chmod after rename in case the umask widened it.
    try {
      chmodSync(secretPath, 0o600);
    } catch {
      /* best-effort */
    }
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
  const empty: PersistedState = {
    lastOkAt: null,
    lastCheckedAt: null,
    sidecarStatus: "missing",
  };
  const forged: PersistedState = {
    lastOkAt: null,
    lastCheckedAt: null,
    sidecarStatus: "forged",
  };
  try {
    if (!existsSync(sidecarPath)) return empty;
    const raw = readFileSync(sidecarPath, "utf-8");
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      logger?.warn?.(
        { sidecarPath },
        "ledger sidecar: unparseable JSON — treating as forged, discarding",
      );
      return forged;
    }
    if (!parsed || typeof parsed !== "object") {
      logger?.warn?.(
        { sidecarPath },
        "ledger sidecar: non-object payload — treating as forged, discarding",
      );
      return forged;
    }
    const obj = parsed as Record<string, unknown>;
    const mac = typeof obj["mac"] === "string" ? (obj["mac"] as string) : null;
    if (!mac) {
      logger?.warn?.(
        { sidecarPath },
        "ledger sidecar: missing mac — treating as forged, discarding",
      );
      return forged;
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
      return forged;
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
        return {
          lastOkAt: null,
          lastCheckedAt: payload.lastCheckedAt,
          sidecarStatus: "stale_checkpoint_binding",
        };
      }
    }
    return {
      lastOkAt: payload.lastOkAt,
      lastCheckedAt: payload.lastCheckedAt,
      sidecarStatus: "ok",
    };
  } catch {
    return empty;
  }
}

/**
 * Task #124: forged-sidecar acknowledgement sidecar. Persists the
 * operator's "I've seen and handled this" click across server
 * restarts. Bound to the sha256 of the forged sidecar payload so a
 * fresh tamper attempt with different bytes is correctly surfaced as
 * a NEW, un-acked incident (the old ack does not "cover" the new
 * forged file).
 */
interface ForgedAckRecord {
  payloadSha: string;
  acknowledgedAt: string;
  // Task #139: attribution string persisted alongside the ack so the
  // dashboard tooltip / audit trail can answer "who dismissed this
  // banner?" after a server restart. Null on legacy ack files written
  // before task #139 landed.
  ackedBy: string | null;
}

function readForgedAck(
  ackPath: string,
  logger?: { warn: (...args: unknown[]) => void },
): ForgedAckRecord | null {
  try {
    if (!existsSync(ackPath)) return null;
    const raw = readFileSync(ackPath, "utf-8").trim();
    if (!raw) return null;
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== "object") return null;
    const obj = parsed as Record<string, unknown>;
    const payloadSha = obj["payloadSha"];
    const acknowledgedAt = obj["acknowledgedAt"];
    if (
      typeof payloadSha !== "string" ||
      !/^[0-9a-f]{64}$/i.test(payloadSha) ||
      typeof acknowledgedAt !== "string" ||
      Number.isNaN(Date.parse(acknowledgedAt))
    ) {
      return null;
    }
    // Task #139: attribution is optional for backward compatibility
    // with ack files written by the task-#124 implementation. A
    // non-string / empty value is normalized to null so the dashboard
    // can fall back to a generic "acknowledged" tooltip.
    const ackedByRaw = obj["ackedBy"];
    const ackedBy =
      typeof ackedByRaw === "string" && ackedByRaw.length > 0
        ? ackedByRaw
        : null;
    return {
      payloadSha: payloadSha.toLowerCase(),
      acknowledgedAt,
      ackedBy,
    };
  } catch (err) {
    logger?.warn?.(
      { err, ackPath },
      "ledger sidecar: forged-ack record unreadable; ignoring",
    );
    return null;
  }
}

function writeForgedAck(
  ackPath: string,
  record: ForgedAckRecord,
  logger?: { warn: (...args: unknown[]) => void },
): void {
  try {
    const tmp = `${ackPath}.tmp`;
    writeFileSync(tmp, JSON.stringify(record) + "\n", { mode: 0o600 });
    renameSync(tmp, ackPath);
  } catch (err) {
    logger?.warn?.(
      { err, ackPath },
      "ledger sidecar: failed to persist forged-ack record",
    );
    throw err;
  }
}

/**
 * Task #150: append-only history of every operator-driven
 * forged-sidecar dismissal. Lives next to the single-incident ack
 * file at `<ackPath>.log.jsonl` and rotates on a byte cap so the
 * file does not grow without bound. The dashboard tails the live
 * file to render a small "Recent dismissals" list under the red
 * banner — operators investigating a repeat tamper attack can see
 * who clicked Acknowledge on prior incidents (and when, against
 * which payloadSha prefix) even after the next forged read has
 * replaced the single-incident sidecar.
 *
 * Rotation policy mirrors `data/ledger-alerts.jsonl`: when the live
 * file exceeds `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES` bytes
 * after an append, it is rotated to `.1` (with `.1 → .2`, etc.) and
 * the oldest rotation past `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS`
 * is deleted. The dashboard endpoint only reads the live file;
 * rotated copies are archival.
 */
interface ForgedAckHistoryEntry {
  payloadSha: string;
  acknowledgedAt: string;
  ackedBy: string | null;
}

const FORGED_ACK_HISTORY_DEFAULT_MAX_BYTES = 256 * 1024;
const FORGED_ACK_HISTORY_DEFAULT_MAX_ROTATIONS = 3;

function resolvePositiveIntFromEnv(
  raw: string | undefined,
  fallback: number,
): number {
  if (raw == null) return fallback;
  const trimmed = raw.trim();
  if (trimmed === "") return fallback;
  const parsed = Number(trimmed);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.floor(parsed);
}

function forgedAckHistoryMaxBytes(): number {
  return resolvePositiveIntFromEnv(
    process.env.MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES,
    FORGED_ACK_HISTORY_DEFAULT_MAX_BYTES,
  );
}

function forgedAckHistoryMaxRotations(): number {
  return resolvePositiveIntFromEnv(
    process.env.MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS,
    FORGED_ACK_HISTORY_DEFAULT_MAX_ROTATIONS,
  );
}

function rotateForgedAckHistory(
  historyPath: string,
  logger?: { warn: (...args: unknown[]) => void },
): void {
  try {
    const maxRotations = forgedAckHistoryMaxRotations();
    // Drop the oldest archive first so the shift below cannot
    // overwrite it.
    const oldest = `${historyPath}.${maxRotations}`;
    if (existsSync(oldest)) {
      try {
        unlinkSync(oldest);
      } catch (err) {
        logger?.warn?.(
          { err, oldest },
          "forged-ack history: failed to delete oldest rotation",
        );
      }
    }
    for (let i = maxRotations - 1; i >= 1; i--) {
      const src = `${historyPath}.${i}`;
      const dst = `${historyPath}.${i + 1}`;
      if (existsSync(src)) {
        try {
          renameSync(src, dst);
        } catch (err) {
          logger?.warn?.(
            { err, src, dst },
            "forged-ack history: failed to shift rotation",
          );
        }
      }
    }
    if (existsSync(historyPath)) {
      try {
        renameSync(historyPath, `${historyPath}.1`);
      } catch (err) {
        logger?.warn?.(
          { err, historyPath },
          "forged-ack history: failed to rotate live file",
        );
      }
    }
  } catch (err) {
    logger?.warn?.(
      { err, historyPath },
      "forged-ack history: rotation failed (best-effort, continuing)",
    );
  }
}

function appendForgedAckHistory(
  historyPath: string,
  entry: ForgedAckHistoryEntry,
  logger?: { warn: (...args: unknown[]) => void },
): void {
  try {
    const line = JSON.stringify(entry) + "\n";
    // Use writeFileSync with flag 'a' for atomic appends within a
    // single process. The history file is small per-line so this is
    // fine; we are not contending with the kernel append loop.
    writeFileSync(historyPath, line, { flag: "a", mode: 0o600 });
    let size = 0;
    try {
      size = statSync(historyPath).size;
    } catch {
      size = 0;
    }
    if (size > forgedAckHistoryMaxBytes()) {
      rotateForgedAckHistory(historyPath, logger);
    }
  } catch (err) {
    logger?.warn?.(
      { err, historyPath },
      "forged-ack history: failed to append entry (best-effort)",
    );
  }
}

/**
 * Task #168: upper bound on how many rotated forged-ack history files
 * we probe for. The rotator caps itself at
 * `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS` (default 3), but an
 * operator may have manually preserved older archives next to the
 * live file; mirror the `ledger-alerts.jsonl` rotation probe so the
 * dashboard surfaces every archive on disk.
 */
const FORGED_ACK_HISTORY_ROTATION_PROBE_MAX = 32;

interface ForgedAckHistoryRotationInfo {
  index: number;
  path: string;
  size: number;
  mtime: string;
}

function listForgedAckHistoryRotations(
  historyPath: string,
): ForgedAckHistoryRotationInfo[] {
  const out: ForgedAckHistoryRotationInfo[] = [];
  for (let i = 1; i <= FORGED_ACK_HISTORY_ROTATION_PROBE_MAX; i++) {
    const p = `${historyPath}.${i}`;
    try {
      const st = statSync(p);
      if (st.isFile()) {
        out.push({
          index: i,
          path: p,
          size: st.size,
          mtime: st.mtime.toISOString(),
        });
      }
    } catch {
      // Missing or unreadable rotation — skip silently.
    }
  }
  return out;
}

export function readForgedAckHistory(
  historyPath: string,
  limit: number,
  logger?: { warn: (...args: unknown[]) => void },
): { entries: ForgedAckHistoryEntry[]; logExists: boolean } {
  if (!existsSync(historyPath)) {
    return { entries: [], logExists: false };
  }
  try {
    const raw = readFileSync(historyPath, "utf-8");
    const lines = raw.split("\n").filter((l) => l.length > 0);
    const out: ForgedAckHistoryEntry[] = [];
    // Walk from the tail so we only parse `limit` good entries.
    for (let i = lines.length - 1; i >= 0 && out.length < limit; i--) {
      const line = lines[i];
      try {
        const parsed = JSON.parse(line) as unknown;
        if (!parsed || typeof parsed !== "object") continue;
        const obj = parsed as Record<string, unknown>;
        const payloadSha = obj["payloadSha"];
        const acknowledgedAt = obj["acknowledgedAt"];
        if (
          typeof payloadSha !== "string" ||
          !/^[0-9a-f]{64}$/i.test(payloadSha) ||
          typeof acknowledgedAt !== "string" ||
          Number.isNaN(Date.parse(acknowledgedAt))
        ) {
          continue;
        }
        const ackedByRaw = obj["ackedBy"];
        const ackedBy =
          typeof ackedByRaw === "string" && ackedByRaw.length > 0
            ? ackedByRaw
            : null;
        out.push({
          payloadSha: payloadSha.toLowerCase(),
          acknowledgedAt,
          ackedBy,
        });
      } catch {
        // Skip malformed line; keep scanning so a single bad write
        // doesn't blank the panel.
        continue;
      }
    }
    return { entries: out, logExists: true };
  } catch (err) {
    logger?.warn?.(
      { err, historyPath },
      "forged-ack history: failed to read (returning empty)",
    );
    return { entries: [], logExists: true };
  }
}

function writePersistedState(
  sidecarPath: string,
  secret: Buffer,
  checkpointPath: string,
  state: Pick<PersistedState, "lastOkAt" | "lastCheckedAt">,
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

export interface LedgerMonitorInfo {
  enabled: boolean;
  intervalSeconds: number | null;
  lastTickAt: string | null;
  lastAlertedFailureMode: string | null;
  /**
   * Task #98: when the operator has acknowledged the most-recent
   * monitor-fired alert via `POST /lean/ledger-alerts/ack`, this is
   * the alert id (sha256 hex). Subsequent non-ok ticks are silent
   * (no webhook/email re-fire), even on failure_mode transition,
   * until a recovery alert clears the state. Null when there is no
   * outstanding acknowledged alert.
   */
  lastAcknowledgedAlertId: string | null;
  /**
   * Task #128: current state of the in-process watchdog (task #113).
   * `ok` while ticks are landing within 2× the configured interval;
   * `stalled` once the watchdog has fired a `monitor_stalled` alert
   * and not yet seen a recovery. Distinct from the existing
   * `checkedStale` flag on the integrity status payload: that one is
   * derived from the sidecar's `lastCheckedAt` timestamp (and so
   * persists across restarts), whereas `watchdogState` reflects the
   * live in-memory state of the monitor's own watchdog and goes
   * back to `ok` on every server restart. `null` when the monitor is
   * disabled.
   */
  watchdogState: "ok" | "stalled" | null;
  /**
   * Task #128: ISO-8601 timestamp of the most recent
   * `monitor_stalled` alert fired by the watchdog (task #113), or
   * null if the watchdog has never fired in this process lifetime.
   * Lets the dashboard show operators when the stall happened even
   * after the watchdog has subsequently recovered.
   */
  watchdogLastFiredAt: string | null;
}

const DISABLED_MONITOR_INFO: LedgerMonitorInfo = {
  enabled: false,
  intervalSeconds: null,
  lastTickAt: null,
  lastAlertedFailureMode: null,
  lastAcknowledgedAlertId: null,
  watchdogState: null,
  watchdogLastFiredAt: null,
};

export interface LedgerChecker {
  router: IRouter;
  buildStatus: () => LedgerIntegrityStatus;
  hitsPath: string;
  checkpointPath: string;
  /**
   * Task #97: register a provider for ledger-monitor observability so
   * GET /api/ledger/integrity can surface `monitor: {...}`. Called
   * fresh on every request — provider may return live state.
   */
  setMonitorInfoProvider: (fn: () => LedgerMonitorInfo) => void;
  /**
   * Task #110: one-shot latch consumed by the background monitor on
   * its first tick. Returns `true` exactly once — and only when the
   * boot-time sidecar read came back `forged` — so the monitor can
   * fire a tamper-detected alert per process lifetime without
   * re-spamming on subsequent ticks. Returns `false` for `missing` /
   * `ok` / `stale_checkpoint_binding` boots (and on every call after
   * the first true).
   */
  consumeBootForgedAlert: () => boolean;
  /**
   * Task #124: operator-driven acknowledgement of the current
   * forged-sidecar incident. Returns `null` when there is no active
   * forged incident to acknowledge (e.g. the boot read was `ok` /
   * `missing` / `stale_checkpoint_binding`). Idempotent: re-acking
   * an already-acked incident returns the original `acknowledgedAt`
   * with `alreadyAcknowledged: true`.
   */
  acknowledgeForgedSidecar: (ackedBy?: string | null) =>
    | {
        ok: true;
        acknowledgedAt: string;
        alreadyAcknowledged: boolean;
        payloadSha: string;
        ackedBy: string | null;
      }
    | { ok: false; reason: "no_incident" };
  /**
   * Task #150: most-recent-first snapshot of operator-driven
   * forged-sidecar dismissals from the rotating history log next to
   * the single-incident ack file. The dashboard renders these under
   * the red banner so a repeat tamper attack still shows who
   * dismissed prior incidents (after the single-incident sidecar
   * has been replaced).
   */
  listForgedAckHistory: (
    limit?: number,
    rotation?: number,
  ) => {
    entries: Array<{
      payloadSha: string;
      acknowledgedAt: string;
      ackedBy: string | null;
    }>;
    logExists: boolean;
    capacity: number;
    /**
     * Task #168: which rotation file was read. `0` = the live
     * `data/hits.txt.lastok.forged-ack.log.jsonl`; `N >= 1` reads
     * the `.N` archive. Echoes the request so the dashboard can
     * highlight the active tab without a second round-trip.
     */
    rotation: number;
    /**
     * Task #168: snapshot of every rotated archive currently on
     * disk (newest-rotated first by index). Lets the dashboard
     * render paging controls without polling each rotation index
     * blindly. Mirrors `/lean/ledger-alerts`'s `availableRotations`.
     */
    rotations: Array<{
      index: number;
      path: string;
      size: number;
      mtime: string;
    }>;
  };
  /**
   * Task #140: rotate the sidecar HMAC secret in response to a tamper
   * alert. Persists the new key (keyfile, or in-memory env slot when
   * the boot-time secret came from `LEDGER_SIDECAR_SECRET`), re-seals
   * the live sidecar with the new MAC, and clears the sticky
   * forged-incident state + its on-disk ack sibling so the dashboard
   * banner clears on the next `/api/ledger/integrity` poll.
   */
  rotateSidecarSecret: (rotatedBy?: string | null) => {
    ok: true;
    rotatedAt: string;
    secretPersisted: boolean;
    persistedTo: "env" | "keyfile";
    keyfilePath: string | null;
    rotatedBy: string | null;
    sidecarResealed: boolean;
    hadForgedIncident: boolean;
  };
}

export function createLedgerChecker(opts: LedgerRouterOptions): LedgerChecker {
  const HITS = opts.hitsPath;
  const CHECKPOINT = opts.checkpointPath;
  const LAST_OK_PATH = opts.lastOkPath ?? `${opts.hitsPath}.lastok`;
  // Task #109: allow operators to relocate the sidecar HMAC keyfile
  // out of the data dir (e.g. onto a tighter-ACL secrets mount) by
  // setting LEDGER_SIDECAR_SECRET_PATH. Explicit `opts.secretPath`
  // (used by tests) still wins.
  const SECRET_PATH =
    opts.secretPath ??
    (process.env.LEDGER_SIDECAR_SECRET_PATH &&
    process.env.LEDGER_SIDECAR_SECRET_PATH.trim() !== ""
      ? process.env.LEDGER_SIDECAR_SECRET_PATH.trim()
      : `${LAST_OK_PATH}.key`);
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
  const explicitCheckedStaleSeconds =
    opts.checkedStaleThresholdSeconds != null &&
    Number.isFinite(opts.checkedStaleThresholdSeconds) &&
    opts.checkedStaleThresholdSeconds > 0
      ? Math.floor(opts.checkedStaleThresholdSeconds)
      : resolveCheckedStaleThresholdSecondsFromEnv(
          process.env.LEDGER_CHECKED_STALE_THRESHOLD_SECONDS,
        );
  const STRICT_MODE = isSidecarSecretStrictMode(
    process.env.LEDGER_SIDECAR_SECRET_STRICT_MODE,
  );
  // Task #140: track whether the boot-time secret came from
  // `LEDGER_SIDECAR_SECRET` (env-only, no on-disk fallback) so the
  // rotate endpoint can preserve that posture — updating the
  // in-memory `process.env` slot rather than persisting a fresh
  // keyfile that would defeat the env-only deploy. `null` means the
  // on-disk keyfile was used (rotation should rewrite the keyfile);
  // a string means the env var was honored at boot (rotation should
  // update the env slot only).
  const bootInlineSecretRaw = process.env.LEDGER_SIDECAR_SECRET;
  const bootInlineSecretWasUsed: boolean =
    loadInlineSecret(bootInlineSecretRaw) != null;
  let SIDECAR_SECRET = loadOrCreateSecret(
    SECRET_PATH,
    defaultLogger,
    process.env.LEDGER_SIDECAR_SECRET,
    STRICT_MODE,
  );
  const persisted = readPersistedState(
    LAST_OK_PATH,
    SIDECAR_SECRET,
    CHECKPOINT,
    defaultLogger,
  );
  let lastOkAt: string | null = persisted.lastOkAt;
  let lastCheckedAt: string | null = persisted.lastCheckedAt;
  // Task #110: sticky sidecar-status surface. We seed from the boot
  // read. Subsequent legitimate writes by THIS process flip it back
  // to `ok` (we just wrote a valid mac), so the banner clears once
  // an attacker's forged file has been overwritten. A `forged` boot
  // status remains visible to operators until the next legitimate
  // write — long enough that the dashboard surfaces the tamper
  // attempt distinctly from a fresh-boot empty sidecar.
  let lastOkSidecarStatus: LastOkSidecarStatus = persisted.sidecarStatus;
  // Task #124: sticky forged-sidecar incident. Set when boot detects
  // a forged sidecar; kept in memory (and persisted as a sibling ack
  // file) until the operator acknowledges, then surfaces as a
  // visible "acknowledged" badge on the dashboard banner. Cleared
  // only by a subsequent boot whose sidecar read is non-forged OR
  // whose forged payload sha differs from the acknowledged one (a
  // fresh tamper attempt = new un-acked incident).
  const FORGED_ACK_PATH = `${LAST_OK_PATH}.forged-ack`;
  // Task #150: rotating history log alongside the single-incident
  // ack sidecar. Each operator-driven dismissal appends one JSONL
  // line so the dashboard can show a "Recent dismissals" list under
  // the red banner even after the next forged read has replaced
  // FORGED_ACK_PATH.
  const FORGED_ACK_HISTORY_PATH = `${FORGED_ACK_PATH}.log.jsonl`;
  type ForgedIncident = {
    payloadSha: string;
    acknowledgedAt: string | null;
    ackedBy: string | null;
  };
  let forgedIncident: ForgedIncident | null = null;
  if (persisted.sidecarStatus === "forged") {
    let payloadSha: string;
    try {
      const raw = readFileSync(LAST_OK_PATH);
      payloadSha = createHash("sha256").update(raw).digest("hex");
    } catch {
      // The file became unreadable between readPersistedState and
      // here (race / filesystem flake) — treat as missing rather
      // than forged. The banner won't show, but we also don't
      // synthesize a fake incident.
      payloadSha = "";
    }
    if (payloadSha) {
      const priorAck = readForgedAck(FORGED_ACK_PATH, defaultLogger);
      const carriedAck =
        priorAck != null && priorAck.payloadSha === payloadSha
          ? priorAck.acknowledgedAt
          : null;
      // Task #139: carry forward the persisted attribution so the
      // dashboard tooltip / audit trail survives a restart.
      const carriedAckedBy =
        priorAck != null && priorAck.payloadSha === payloadSha
          ? priorAck.ackedBy
          : null;
      if (priorAck != null && priorAck.payloadSha !== payloadSha) {
        // Stale ack from a previous incident — clear it so the
        // dashboard surfaces the new tamper as un-acked.
        try {
          unlinkSync(FORGED_ACK_PATH);
        } catch {
          /* best-effort */
        }
      }
      forgedIncident = {
        payloadSha,
        acknowledgedAt: carriedAck,
        ackedBy: carriedAck != null ? carriedAckedBy : null,
      };
    } else {
      // Couldn't sha the forged file — fall back to "no incident".
      try {
        unlinkSync(FORGED_ACK_PATH);
      } catch {
        /* best-effort */
      }
    }
  } else {
    // No forged sidecar on this boot — drop any leftover ack file
    // from a previous incident.
    try {
      if (existsSync(FORGED_ACK_PATH)) unlinkSync(FORGED_ACK_PATH);
    } catch {
      /* best-effort */
    }
  }
  // Task #183: sticky stale-checkpoint-binding flag. Set when boot
  // reads a sidecar whose HMAC verifies but whose `boundCheckpoint*`
  // fields no longer match the on-disk checkpoint (Task #110's
  // `stale_checkpoint_binding` PersistedState). Without this latch
  // the surface would be silently overwritten on the very first
  // `/integrity` call, because `buildStatusInner` always re-seals the
  // sidecar with a fresh MAC bound to the current checkpoint and
  // then flips the in-memory `lastOkSidecarStatus` to `"ok"`. The
  // dashboard's amber "stale checkpoint binding" banner therefore
  // never lit up in production. We clear the flag once an integrity
  // check returns `ok` (which means the binding has just been
  // legitimately refreshed and the operator's view of the world is
  // healthy again) or on the next boot whose sidecar read is
  // non-stale. The `forgedIncident` branch always wins over this
  // one — a tamper signal is strictly more severe.
  let staleCheckpointBindingAtBoot: boolean =
    persisted.sidecarStatus === "stale_checkpoint_binding";
  // One-shot latch for the boot-time forged-detection alert. The
  // server-side monitor (when wired) reads + clears this on its first
  // tick so the alert fires exactly once per process lifetime.
  // Task #124: an already-acknowledged forged incident from a prior
  // boot must not re-fire the webhook/SMTP alert — the operator has
  // already seen and dismissed it. Same isAcknowledged semantics as
  // the integrity-alert path (task #98).
  let bootForgedAlertPending: boolean =
    persisted.sidecarStatus === "forged" &&
    (forgedIncident == null || forgedIncident.acknowledgedAt == null);

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

  function resolveCheckedStaleThreshold(): number {
    // Explicit constructor option / env var always wins.
    if (explicitCheckedStaleSeconds != null) {
      return explicitCheckedStaleSeconds;
    }
    // Otherwise, derive `2 × monitorIntervalSeconds` from the live
    // monitor info provider so the threshold tracks whatever cadence
    // the operator configured for the background timer. We deliberately
    // re-resolve on every call because the monitor provider may be
    // registered after createLedgerChecker() (see the bottom of this
    // file) and may also change at runtime.
    let info: LedgerMonitorInfo;
    try {
      info = monitorInfoProvider();
    } catch {
      return DEFAULT_CHECKED_STALE_THRESHOLD_SECONDS;
    }
    if (
      info.enabled &&
      info.intervalSeconds != null &&
      Number.isFinite(info.intervalSeconds) &&
      info.intervalSeconds > 0
    ) {
      return info.intervalSeconds * 2;
    }
    return DEFAULT_CHECKED_STALE_THRESHOLD_SECONDS;
  }

  function computeCheckedStaleness(checkedAtIso: string): {
    lastCheckedAgeSeconds: number | null;
    checkedStaleThresholdSeconds: number;
    checkedStale: boolean;
  } {
    const thresh = resolveCheckedStaleThreshold();
    if (!lastCheckedAt) {
      // No prior attempted check on record — flag stale so the
      // dashboard surfaces "verifier hasn't run" rather than a silent
      // blank field.
      return {
        lastCheckedAgeSeconds: null,
        checkedStaleThresholdSeconds: thresh,
        checkedStale: true,
      };
    }
    const checkedMs = Date.parse(lastCheckedAt);
    const nowMs = Date.parse(checkedAtIso);
    if (!Number.isFinite(checkedMs) || !Number.isFinite(nowMs)) {
      return {
        lastCheckedAgeSeconds: null,
        checkedStaleThresholdSeconds: thresh,
        checkedStale: true,
      };
    }
    const ageSeconds = Math.max(0, Math.floor((nowMs - checkedMs) / 1000));
    return {
      lastCheckedAgeSeconds: ageSeconds,
      checkedStaleThresholdSeconds: thresh,
      checkedStale: ageSeconds > thresh,
    };
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
    // Task #99: deliberately DO NOT re-derive checked-staleness here.
    // The inner run already snapshotted it against the prior
    // lastCheckedAt before advancing the persisted value, which is
    // the semantic we want (see the buildStatusInner comment).
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
    const csInit = computeCheckedStaleness(checkedAt);
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
      lastCheckedAgeSeconds: csInit.lastCheckedAgeSeconds,
      staleThresholdSeconds: STALE_THRESHOLD_SECONDS,
      stale,
      checkedStaleThresholdSeconds: csInit.checkedStaleThresholdSeconds,
      checkedStale: csInit.checkedStale,
      checkpointLastModified: cpInit.checkpointLastModified,
      checkpointAgeSeconds: cpInit.checkpointAgeSeconds,
      checkpointCoverageRatio: cpInit.checkpointCoverageRatio,
      checkpointStaleThresholdSeconds: CHECKPOINT_STALE_THRESHOLD_SECONDS,
      checkpointStale: cpInit.checkpointStale,
      lastOkSidecarStatus,
      sidecarSecretStrictMode: STRICT_MODE,
      lastOkSidecarStatusAcknowledgedAt: null,
      lastOkSidecarStatusAcknowledgedBy: null,
    };


    // Always update lastCheckedAt — we ran a check regardless of outcome.
    // NOTE (task #99): the `base` object's lastCheckedAgeSeconds /
    // checkedStale fields were computed BEFORE this write, against
    // the prior persisted value. That is intentional: we want the
    // surfaced age to mean "time since the *previous* check attempt"
    // so the dashboard can detect a stalled background monitor (if
    // the monitor stops ticking, the dashboard poll's own writes are
    // the only thing advancing lastCheckedAt, but each poll sees the
    // gap to the prior poll). If we re-derived here, every response
    // would show age ≈ 0 and `checkedStale` could never flip true.
    lastCheckedAt = checkedAt;
    writePersistedState(LAST_OK_PATH, SIDECAR_SECRET, CHECKPOINT, { lastOkAt, lastCheckedAt });
    // Task #110: a legitimate write replaces whatever forged /
    // missing payload was on disk with a fresh HMAC'd one. Flip the
    // surfaced status back to `ok` — but task #124 keeps the banner
    // sticky via `forgedIncident` so the operator still sees the
    // tamper notice (with an "acknowledged" badge once they click
    // Acknowledge) until a subsequent boot clears the incident.
    lastOkSidecarStatus = "ok";
    base.lastCheckedAt = lastCheckedAt;
    if (forgedIncident != null) {
      base.lastOkSidecarStatus = "forged";
      base.lastOkSidecarStatusAcknowledgedAt = forgedIncident.acknowledgedAt;
      base.lastOkSidecarStatusAcknowledgedBy = forgedIncident.ackedBy;
    } else if (staleCheckpointBindingAtBoot) {
      // Task #183: surface the sticky boot-time stale-binding signal
      // so the dashboard's amber banner reflects what the server
      // actually observed. Cleared by a successful ok verify (below)
      // or by a subsequent boot whose sidecar read is non-stale.
      base.lastOkSidecarStatus = "stale_checkpoint_binding";
      base.lastOkSidecarStatusAcknowledgedAt = null;
      base.lastOkSidecarStatusAcknowledgedBy = null;
    } else {
      base.lastOkSidecarStatus = lastOkSidecarStatus;
      base.lastOkSidecarStatusAcknowledgedAt = null;
      base.lastOkSidecarStatusAcknowledgedBy = null;
    }

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
    // Task #183: a successful verify just re-sealed the sidecar with
    // a fresh MAC bound to the on-disk checkpoint, so the binding is
    // no longer stale. Clear the sticky flag and override the
    // surface so the dashboard banner clears on this very response
    // (the `base` object was computed before this branch decided
    // verification would succeed).
    const hadStaleBindingAtBoot = staleCheckpointBindingAtBoot;
    if (hadStaleBindingAtBoot) {
      staleCheckpointBindingAtBoot = false;
    }
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
      ...(hadStaleBindingAtBoot
        ? {
            lastOkSidecarStatus: "ok" as const,
            lastOkSidecarStatusAcknowledgedAt: null,
            lastOkSidecarStatusAcknowledgedBy: null,
          }
        : {}),
    };
  }

  let monitorInfoProvider: () => LedgerMonitorInfo = () => DISABLED_MONITOR_INFO;
  const router: IRouter = Router();
  router.get("/ledger/integrity", (_req, res) => {
    const status = buildStatus();
    let monitor: LedgerMonitorInfo;
    try {
      monitor = monitorInfoProvider();
    } catch {
      monitor = DISABLED_MONITOR_INFO;
    }
    res.status(200).json({ ...status, monitor });
  });

  function acknowledgeForgedSidecar(
    ackedBy?: string | null,
  ):
    | {
        ok: true;
        acknowledgedAt: string;
        alreadyAcknowledged: boolean;
        payloadSha: string;
        ackedBy: string | null;
      }
    | { ok: false; reason: "no_incident" } {
    if (forgedIncident == null) {
      return { ok: false, reason: "no_incident" };
    }
    if (forgedIncident.acknowledgedAt != null) {
      return {
        ok: true,
        acknowledgedAt: forgedIncident.acknowledgedAt,
        alreadyAcknowledged: true,
        payloadSha: forgedIncident.payloadSha,
        ackedBy: forgedIncident.ackedBy,
      };
    }
    // Task #139: normalize the caller-supplied attribution. Empty /
    // missing values collapse to the literal "anonymous" so the
    // audit trail always names a dismisser (shared-token deploys
    // with no X-Referee-Name header still produce a stable string,
    // matching the rebuild-attribution contract).
    const ackedByNormalized: string =
      typeof ackedBy === "string" && ackedBy.length > 0
        ? ackedBy
        : "anonymous";
    const acknowledgedAt = new Date().toISOString();
    writeForgedAck(
      FORGED_ACK_PATH,
      {
        payloadSha: forgedIncident.payloadSha,
        acknowledgedAt,
        ackedBy: ackedByNormalized,
      },
      defaultLogger,
    );
    // Task #150: append to the rotating history log so the
    // "Recent dismissals" panel survives the single-incident
    // sidecar being replaced by a later forged read.
    appendForgedAckHistory(
      FORGED_ACK_HISTORY_PATH,
      {
        payloadSha: forgedIncident.payloadSha,
        acknowledgedAt,
        ackedBy: ackedByNormalized,
      },
      defaultLogger,
    );
    forgedIncident = {
      payloadSha: forgedIncident.payloadSha,
      acknowledgedAt,
      ackedBy: ackedByNormalized,
    };
    // Suppress any still-pending boot-forged one-shot alert: the
    // operator has dismissed the incident from the dashboard, so the
    // monitor's first tick should stay quiet (same dedup contract as
    // `isAcknowledged` for integrity-mismatch alerts, task #98).
    bootForgedAlertPending = false;
    return {
      ok: true,
      acknowledgedAt,
      alreadyAcknowledged: false,
      payloadSha: forgedIncident.payloadSha,
      ackedBy: ackedByNormalized,
    };
  }

  /**
   * Task #140: rotate the sidecar HMAC secret after a tamper alert.
   * Generates a fresh 32-byte key, persists it (keyfile by default,
   * or in-memory env slot when the boot-time secret came from
   * `LEDGER_SIDECAR_SECRET`), re-seals the live sidecar with the new
   * MAC so the next integrity poll classifies it as `ok`, and clears
   * the sticky forged-incident state plus its on-disk ack sibling.
   *
   * Returns the persistence posture used (`"env"` vs `"keyfile"`),
   * the resolved keyfile path when applicable, and the rotation
   * timestamp. Best-effort on the file writes: a keyfile write
   * failure does NOT abort rotation — the new secret stays in
   * memory and the function reports `secretPersisted: false` so the
   * dashboard can warn the operator that the next restart will
   * regenerate yet another key.
   */
  function rotateSidecarSecret(
    rotatedBy?: string | null,
  ): {
    ok: true;
    rotatedAt: string;
    secretPersisted: boolean;
    persistedTo: "env" | "keyfile";
    keyfilePath: string | null;
    rotatedBy: string | null;
    sidecarResealed: boolean;
    hadForgedIncident: boolean;
  } {
    const rotatedAt = new Date().toISOString();
    const rotatedByNormalized: string =
      typeof rotatedBy === "string" && rotatedBy.length > 0
        ? rotatedBy
        : "anonymous";
    const fresh = randomBytes(32);
    let secretPersisted = false;
    let persistedTo: "env" | "keyfile";
    let keyfilePath: string | null = null;
    if (bootInlineSecretWasUsed) {
      // Env-only posture (Task #109): hold the new secret in memory
      // and update the process.env slot so any in-process consumer
      // re-reading it sees the rotated value. We deliberately do NOT
      // touch the keyfile here — writing one would silently downgrade
      // the operator's hardened deploy posture.
      process.env.LEDGER_SIDECAR_SECRET = fresh.toString("hex");
      persistedTo = "env";
      secretPersisted = true;
    } else {
      persistedTo = "keyfile";
      keyfilePath = SECRET_PATH;
      try {
        const tmp = `${SECRET_PATH}.tmp`;
        writeFileSync(tmp, fresh.toString("hex") + "\n");
        try {
          chmodSync(tmp, 0o600);
        } catch {
          /* best-effort */
        }
        renameSync(tmp, SECRET_PATH);
        try {
          chmodSync(SECRET_PATH, 0o600);
        } catch {
          /* best-effort */
        }
        secretPersisted = true;
      } catch (err) {
        defaultLogger.warn?.(
          { err, secretPath: SECRET_PATH },
          "ledger sidecar: rotate could not persist new secret to keyfile (in-memory only; next restart will regenerate)",
        );
      }
    }
    SIDECAR_SECRET = fresh;
    // Re-seal the live sidecar with the new MAC so the next
    // /api/ledger/integrity poll reads a valid payload and flips
    // `lastOkSidecarStatus` back to `ok`.
    let sidecarResealed = true;
    try {
      writePersistedState(LAST_OK_PATH, SIDECAR_SECRET, CHECKPOINT, {
        lastOkAt,
        lastCheckedAt,
      });
    } catch {
      sidecarResealed = false;
    }
    // Clear sticky forged-incident state and its on-disk ack sibling
    // so the banner does not re-render after rotation.
    const hadForgedIncident = forgedIncident != null;
    forgedIncident = null;
    lastOkSidecarStatus = "ok";
    bootForgedAlertPending = false;
    try {
      if (existsSync(FORGED_ACK_PATH)) unlinkSync(FORGED_ACK_PATH);
    } catch {
      /* best-effort */
    }
    defaultLogger.warn?.(
      {
        rotatedAt,
        rotatedBy: rotatedByNormalized,
        persistedTo,
        secretPersisted,
        hadForgedIncident,
      },
      "ledger sidecar: HMAC secret rotated",
    );
    return {
      ok: true,
      rotatedAt,
      secretPersisted,
      persistedTo,
      keyfilePath,
      rotatedBy: rotatedByNormalized,
      sidecarResealed,
      hadForgedIncident,
    };
  }

  return {
    router,
    buildStatus,
    hitsPath: HITS,
    checkpointPath: CHECKPOINT,
    setMonitorInfoProvider(fn) {
      monitorInfoProvider = fn;
    },
    consumeBootForgedAlert() {
      if (!bootForgedAlertPending) return false;
      bootForgedAlertPending = false;
      return true;
    },
    acknowledgeForgedSidecar,
    listForgedAckHistory(limit?: number, rotation?: number) {
      const cap = FORGED_ACK_HISTORY_LIST_CAPACITY;
      const n =
        typeof limit === "number" && Number.isFinite(limit) && limit > 0
          ? Math.min(Math.floor(limit), cap)
          : cap;
      // Task #168: rotation paging. `0` (default) = live file; `N >= 1`
      // reads `${FORGED_ACK_HISTORY_PATH}.N`. Clamp to the probe ceiling
      // so a hostile query param can't drive arbitrary path traversal.
      const rotNorm =
        typeof rotation === "number" && Number.isFinite(rotation) && rotation > 0
          ? Math.min(Math.floor(rotation), FORGED_ACK_HISTORY_ROTATION_PROBE_MAX)
          : 0;
      const targetPath =
        rotNorm > 0
          ? `${FORGED_ACK_HISTORY_PATH}.${rotNorm}`
          : FORGED_ACK_HISTORY_PATH;
      const { entries, logExists } = readForgedAckHistory(
        targetPath,
        n,
        defaultLogger,
      );
      const rotations = listForgedAckHistoryRotations(FORGED_ACK_HISTORY_PATH);
      return {
        entries,
        logExists,
        capacity: cap,
        rotation: rotNorm,
        rotations,
      };
    },
    rotateSidecarSecret,
  };
}

// Task #150: hard cap on the number of "Recent dismissals" the
// dashboard panel renders per page. The rotating log on disk can be
// larger (and may include multiple rotations); this just bounds the
// API surface.
const FORGED_ACK_HISTORY_LIST_CAPACITY = 20;

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
  /**
   * Task #98: predicate consulted before firing a follow-up alert. If
   * it returns true for the id of the most-recently-fired alert, the
   * monitor stays silent — the operator has already acknowledged the
   * incident in the dashboard and a webhook/email re-fire would be
   * noise. Recovery alerts are NOT subject to this check; a green
   * restore always notifies and clears the acked-state.
   *
   * The predicate is called with the alert id of the prior fire
   * (sha256 of `timestamp + "\n" + message`, matching
   * `lean.ts`'s `computeAlertId`). The predicate may read the on-disk
   * ack sidecar fresh each call.
   *
   * Omit the option to opt out — dedup falls back to the pre-task-#98
   * behaviour (re-fire on every failure_mode transition).
   */
  isAcknowledged?: (alertId: string) => boolean;
  /**
   * Task #110: called once before the first integrity-check on each
   * tick. When it returns true, the monitor fires a one-shot
   * "sidecar forged" alert through `sink` — this lets the operator
   * who's set up webhook/SMTP delivery learn about a tamper-at-rest
   * attempt that was detected at boot, before the first scheduled
   * tick discovers anything else. The implementation is expected to
   * be a one-shot latch (i.e. only return true once per process
   * lifetime); the monitor does not re-arm it.
   */
  consumeBootForgedAlert?: () => boolean;
  /** Friendly tag for the boot-forged alert context (defaults to the hits path). */
  sidecarPath?: string;
  /**
   * Task #113: clock source for the watchdog and tick timestamps.
   * Defaults to `Date.now`. Injected by tests so the stalled/recovered
   * transitions can be driven deterministically without real sleeps.
   */
  now?: () => number;
}

export interface LedgerMonitorHandle {
  stop: () => void;
  tick: () => Promise<void>;
  /**
   * Task #113: manual watchdog entry-point. The watchdog also runs on
   * its own `setInterval` (at `intervalMs` cadence) so a wedged tick
   * still triggers a push alert, but exposing it lets tests drive the
   * stalled/recovered transitions deterministically against an
   * injected `now()` clock without sleeping.
   */
  checkWatchdog: () => Promise<void>;
  /**
   * Task #97: ledger-monitor observability. `enabled` is always true
   * for a started monitor; `intervalSeconds` reflects the configured
   * tick cadence; `lastTickAt` is the ISO-8601 timestamp of the most
   * recent completed tick (null until the first tick finishes);
   * `lastAlertedFailureMode` is the failureMode of the in-flight
   * (still-firing, not-yet-recovered) alert, or null when healthy.
   */
  getInfo: () => LedgerMonitorInfo;
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
  const now = opts.now ?? (() => Date.now());
  let lastAlerted: "none" | "alerted" = "none";
  let lastFailureMode: string | null = null;
  let lastFiredAlertId: string | null = null;
  let lastAcknowledgedAlertId: string | null = null;
  // Task #111: track checkpointStale separately from the integrity-
  // status state machine. The sealed prefix going stale is an
  // operator-attention signal (re-roll the checkpoint), not a tamper
  // signal, so it gets its own dedup latch and its own
  // failure_mode = "checkpoint_stale" so dashboards / alert history
  // can distinguish it from hits_truncated / hits_rewritten_in_place.
  let lastCheckpointStaleAlerted = false;
  let lastTickAt: string | null = null;
  let lastTickMs: number | null = null;
  let inFlightTick: Promise<void> | null = null;
  const intervalSeconds = Math.max(
    1,
    Math.floor(opts.intervalMs / 1000),
  );
  // Task #113: watchdog state. The watchdog fires `monitor_stalled`
  // when no tick has completed in 2× the configured interval, and
  // `monitor_recovered` once ticks resume. Dedup is the same as the
  // tamper-status state machine — one alert per state transition.
  // The baseline for "how long has it been since the last tick" is
  // the monitor's own start time until the first tick completes; that
  // way a monitor whose setInterval never even fires once is caught.
  const monitorStartedMs = now();
  const watchdogStallThresholdMs = opts.intervalMs * 2;
  let watchdogState: "ok" | "stalled" = "ok";
  let watchdogInFlight = false;
  // Task #128: ISO-8601 timestamp of the most recent stall fire.
  // Sticky across recoveries so the dashboard can show operators
  // "the watchdog fired at <time>" even after the monitor has since
  // recovered. Null until the watchdog fires for the first time.
  let watchdogLastFiredAt: string | null = null;

  function checkAcknowledged(): boolean {
    if (!opts.isAcknowledged) return false;
    if (!lastFiredAlertId) return false;
    try {
      return opts.isAcknowledged(lastFiredAlertId);
    } catch (err) {
      log.warn(
        { err },
        "ledger monitor: isAcknowledged predicate threw (treating as not acked)",
      );
      return false;
    }
  }

  async function fireBootForgedAlertIfPending(): Promise<void> {
    if (!opts.consumeBootForgedAlert) return;
    let shouldFire = false;
    try {
      shouldFire = opts.consumeBootForgedAlert();
    } catch (err) {
      log.warn(
        { err },
        "ledger monitor: consumeBootForgedAlert threw (treating as no boot-forged alert)",
      );
      return;
    }
    if (!shouldFire) return;
    const alertTimestamp = new Date().toISOString();
    const message =
      `Ledger sidecar tamper detected (api-server monitor): ` +
      `the persisted lastOk sidecar (${opts.sidecarPath ?? opts.hitsPath ?? "lastok"}) ` +
      `failed HMAC verification at boot. An attacker with write access to the data dir ` +
      `wrote a forged payload without the per-deploy secret. The forged value has been ` +
      `discarded; rotate the sidecar secret and audit data-dir access.`;
    const alertId = computeAlertId(alertTimestamp, message);
    const context: LedgerAlertContext = {
      failure_mode: "sidecar_forged",
      hits_path: opts.hitsPath,
      checkpoint_path: opts.checkpointPath,
      source: "api-server-monitor",
      timestamp: alertTimestamp,
      checked_at: alertTimestamp,
    };
    const invocation: LedgerAlertInvocation = {
      kind: "alert",
      message,
      context,
    };
    log.warn(
      { alertId, sidecarPath: opts.sidecarPath ?? null },
      "ledger monitor: firing one-shot sidecar-forged alert (boot-time tamper)",
    );
    try {
      await opts.sink(invocation);
    } catch (err) {
      log.warn(
        { err },
        "ledger monitor: sidecar-forged sink threw (best-effort, swallowed)",
      );
    }
  }

  async function tick(): Promise<void> {
    // Task #130: when a tick is already running (e.g. the eager
    // startup tick), join its promise instead of returning a silent
    // no-op. Callers that `await monitor.tick()` after a state change
    // would otherwise observe the previous tick's snapshot and miss
    // the alert they were trying to provoke.
    if (inFlightTick) return inFlightTick;
    inFlightTick = runTick();
    try {
      await inFlightTick;
    } finally {
      inFlightTick = null;
    }
  }

  async function runTick(): Promise<void> {
    try {
      // Task #110: drain the one-shot boot-forged latch on the very
      // first tick. Runs before buildStatus so a sink that throws
      // can't mask the integrity check itself.
      await fireBootForgedAlertIfPending();
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
        const needsFire =
          lastAlerted !== "alerted" || lastFailureMode !== s.failureMode;
        if (needsFire) {
          // Task #98: if the previous monitor-fired alert was already
          // dismissed in the dashboard, stay silent on subsequent
          // non-ok ticks — even when the failure_mode genuinely
          // transitions. The operator has acknowledged the incident;
          // a webhook/email re-fire is noise. A recovery alert (below)
          // will still fire on green-restore and reset state.
          if (checkAcknowledged()) {
            log.info(
              {
                failureMode: s.failureMode,
                previousFailureMode: lastFailureMode,
                acknowledgedAlertId: lastFiredAlertId,
              },
              "ledger monitor: suppressing alert (incident acknowledged in dashboard)",
            );
            lastAcknowledgedAlertId = lastFiredAlertId;
            lastFailureMode = s.failureMode;
            lastAlerted = "alerted";
            return;
          }
          // Pre-stamp the timestamp so the alert id we record matches
          // what the kernel writes to `data/ledger-alerts.jsonl` (the
          // kernel honours `timestamp` in context — see
          // `kernel._fire_ledger_alert`). Without this we'd never be
          // able to correlate an in-memory monitor fire with an ack
          // sidecar entry.
          const alertTimestamp = new Date().toISOString();
          const message =
            `Ledger integrity check failed (api-server monitor): ` +
            (s.reason ?? s.failureMode ?? "unknown failure");
          const alertId = computeAlertId(alertTimestamp, message);
          const context: LedgerAlertContext = {
            failure_mode: s.failureMode,
            expected_size: s.checkpointSize,
            expected_sha: s.checkpointSha,
            actual_size: s.liveSize,
            actual_sha: s.livePrefixSha,
            checked_at: s.checkedAt,
            timestamp: alertTimestamp,
            ...commonCtx,
          };
          const invocation: LedgerAlertInvocation = {
            kind: "alert",
            message,
            context,
          };
          log.warn(
            { failureMode: s.failureMode, status: s.status, alertId },
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
          lastFiredAlertId = alertId;
          lastAcknowledgedAlertId = null;
        }
      } else if (lastAlerted === "alerted") {
        const prev = lastFailureMode;
        const alertTimestamp = new Date().toISOString();
        const message =
          `Ledger integrity RECOVERED (api-server monitor): ` +
          `previous failure mode = ${prev ?? "unknown"}`;
        const alertId = computeAlertId(alertTimestamp, message);
        const context: LedgerAlertContext = {
          failure_mode: "recovered",
          previous_failure_mode: prev,
          actual_size: s.liveSize,
          actual_sha: s.livePrefixSha,
          checked_at: s.checkedAt,
          timestamp: alertTimestamp,
          ...commonCtx,
        };
        const invocation: LedgerAlertInvocation = {
          kind: "recovered",
          message,
          context,
        };
        log.info(
          { previousFailureMode: prev, alertId },
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
        lastFiredAlertId = null;
        lastAcknowledgedAlertId = null;
      }

      // Task #111: checkpoint-stale transitions, tracked independently
      // of the tamper-status state machine above. Fires one alert when
      // the sealed prefix crosses the configured staleness threshold
      // (operator needs to re-roll the checkpoint), and one "recovered"
      // when the prefix is re-rolled. Same dedup contract: silent while
      // the boolean stays in the same state.
      if (s.checkpointStale && !lastCheckpointStaleAlerted) {
        const alertTimestamp = new Date().toISOString();
        const ageDays =
          s.checkpointAgeSeconds != null
            ? Math.floor(s.checkpointAgeSeconds / 86400)
            : null;
        const message =
          `Ledger checkpoint is stale (api-server monitor): ` +
          `the sealed prefix at ${opts.checkpointPath ?? "checkpoint"} ` +
          (ageDays != null
            ? `is ${ageDays} day(s) old `
            : `has no readable mtime `) +
          `(threshold ${s.checkpointStaleThresholdSeconds}s). ` +
          `Re-roll the checkpoint to restore tamper coverage of the latest appends.`;
        const alertId = computeAlertId(alertTimestamp, message);
        const context: LedgerAlertContext = {
          failure_mode: "checkpoint_stale",
          expected_size: s.checkpointSize,
          expected_sha: s.checkpointSha,
          actual_size: s.liveSize,
          actual_sha: s.livePrefixSha,
          checked_at: s.checkedAt,
          timestamp: alertTimestamp,
          checkpoint_age_seconds: s.checkpointAgeSeconds,
          checkpoint_last_modified: s.checkpointLastModified,
          checkpoint_coverage_ratio: s.checkpointCoverageRatio,
          checkpoint_stale_threshold_seconds: s.checkpointStaleThresholdSeconds,
          ...commonCtx,
        };
        const invocation: LedgerAlertInvocation = {
          kind: "alert",
          message,
          context,
        };
        log.warn(
          { alertId, ageSeconds: s.checkpointAgeSeconds },
          "ledger monitor: firing checkpoint-stale alert",
        );
        try {
          await opts.sink(invocation);
        } catch (err) {
          log.warn(
            { err },
            "ledger monitor: checkpoint-stale sink threw (best-effort, swallowed)",
          );
        }
        lastCheckpointStaleAlerted = true;
      } else if (!s.checkpointStale && lastCheckpointStaleAlerted) {
        const alertTimestamp = new Date().toISOString();
        const message =
          `Ledger checkpoint RECOVERED (api-server monitor): ` +
          `sealed prefix re-rolled (age now ${s.checkpointAgeSeconds ?? "unknown"}s, ` +
          `threshold ${s.checkpointStaleThresholdSeconds}s)`;
        const alertId = computeAlertId(alertTimestamp, message);
        const context: LedgerAlertContext = {
          failure_mode: "recovered",
          previous_failure_mode: "checkpoint_stale",
          expected_size: s.checkpointSize,
          expected_sha: s.checkpointSha,
          actual_size: s.liveSize,
          actual_sha: s.livePrefixSha,
          checked_at: s.checkedAt,
          timestamp: alertTimestamp,
          checkpoint_age_seconds: s.checkpointAgeSeconds,
          checkpoint_last_modified: s.checkpointLastModified,
          checkpoint_coverage_ratio: s.checkpointCoverageRatio,
          checkpoint_stale_threshold_seconds: s.checkpointStaleThresholdSeconds,
          ...commonCtx,
        };
        const invocation: LedgerAlertInvocation = {
          kind: "recovered",
          message,
          context,
        };
        log.info(
          { alertId, ageSeconds: s.checkpointAgeSeconds },
          "ledger monitor: firing checkpoint-stale recovery alert",
        );
        try {
          await opts.sink(invocation);
        } catch (err) {
          log.warn(
            { err },
            "ledger monitor: checkpoint-stale recovery sink threw (best-effort, swallowed)",
          );
        }
        lastCheckpointStaleAlerted = false;
      }
    } finally {
      const tickMs = now();
      lastTickMs = tickMs;
      lastTickAt = new Date(tickMs).toISOString();
    }
  }

  async function checkWatchdog(): Promise<void> {
    if (watchdogInFlight) return;
    watchdogInFlight = true;
    try {
      const baselineMs = lastTickMs ?? monitorStartedMs;
      const ageMs = now() - baselineMs;
      const stalled = ageMs > watchdogStallThresholdMs;
      if (stalled && watchdogState === "ok") {
        const ageSeconds = Math.floor(ageMs / 1000);
        const thresholdSeconds = Math.floor(watchdogStallThresholdMs / 1000);
        const alertTimestamp = new Date(now()).toISOString();
        const message =
          `Ledger monitor watchdog: no integrity tick has completed in ` +
          `${ageSeconds}s (threshold ${thresholdSeconds}s = 2 × ${intervalSeconds}s interval). ` +
          `The auto-integrity check has stalled — push alerts on ledger tamper may not fire ` +
          `until the api-server is restarted.`;
        const context: LedgerAlertContext = {
          failure_mode: "monitor_stalled",
          source: "api-server-monitor-watchdog",
          checked_at: alertTimestamp,
          timestamp: alertTimestamp,
          hits_path: opts.hitsPath,
          checkpoint_path: opts.checkpointPath,
          last_tick_at: lastTickAt,
          stall_age_seconds: ageSeconds,
          stall_threshold_seconds: thresholdSeconds,
          monitor_interval_seconds: intervalSeconds,
        };
        log.warn(
          { ageSeconds, thresholdSeconds, lastTickAt },
          "ledger monitor: firing watchdog stalled alert",
        );
        try {
          await opts.sink({ kind: "alert", message, context });
        } catch (err) {
          log.warn(
            { err },
            "ledger monitor: watchdog stalled sink threw (best-effort, swallowed)",
          );
        }
        watchdogState = "stalled";
        watchdogLastFiredAt = alertTimestamp;
      } else if (!stalled && watchdogState === "stalled") {
        const ageSeconds = Math.floor(ageMs / 1000);
        const alertTimestamp = new Date(now()).toISOString();
        const message =
          `Ledger monitor watchdog RECOVERED: integrity ticks have resumed ` +
          `(last tick ${ageSeconds}s ago).`;
        const context: LedgerAlertContext = {
          failure_mode: "recovered",
          previous_failure_mode: "monitor_stalled",
          source: "api-server-monitor-watchdog",
          checked_at: alertTimestamp,
          timestamp: alertTimestamp,
          hits_path: opts.hitsPath,
          checkpoint_path: opts.checkpointPath,
          last_tick_at: lastTickAt,
          monitor_interval_seconds: intervalSeconds,
        };
        log.info(
          { ageSeconds, lastTickAt },
          "ledger monitor: firing watchdog recovery alert",
        );
        try {
          await opts.sink({ kind: "recovered", message, context });
        } catch (err) {
          log.warn(
            { err },
            "ledger monitor: watchdog recovery sink threw (best-effort, swallowed)",
          );
        }
        watchdogState = "ok";
      }
    } finally {
      watchdogInFlight = false;
    }
  }

  const handle = setInterval(() => {
    void tick();
  }, opts.intervalMs);
  handle.unref?.();

  // Task #130: fire an initial tick immediately so `lastTickAt` is
  // populated within seconds of boot. Without this, `setInterval`
  // doesn't fire until t+intervalMs, leaving the dashboard's monitor
  // line stuck on `data-monitor-stalled="true"` for the entire first
  // interval (5 minutes at the default cadence). Eager kickoff also
  // means the watchdog has a real baseline to compare against on its
  // first poll instead of relying solely on `monitorStartedMs`.
  void tick();

  // Task #113: separate watchdog timer so a wedged tick still gets a
  // push alert. We poll at the configured tick cadence — the stall
  // threshold is 2× that, so the watchdog can detect a stall within
  // one extra interval of it happening.
  const watchdogHandle = setInterval(() => {
    void checkWatchdog();
  }, opts.intervalMs);
  watchdogHandle.unref?.();

  return {
    stop() {
      clearInterval(handle);
      clearInterval(watchdogHandle);
    },
    tick,
    checkWatchdog,
    getInfo(): LedgerMonitorInfo {
      return {
        enabled: true,
        intervalSeconds,
        lastTickAt,
        lastAlertedFailureMode:
          lastAlerted === "alerted" ? lastFailureMode : null,
        lastAcknowledgedAlertId,
        watchdogState,
        watchdogLastFiredAt,
      };
    },
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
  const ackPath = defaultAlertsAckPath(REPO_ROOT);
  const monitor = startLedgerMonitor({
    buildStatus: defaultChecker.buildStatus,
    sink: createKernelAlertSink({
      repoRoot: REPO_ROOT,
      logger: defaultLogger,
    }),
    intervalMs: monitorIntervalSeconds * 1000,
    hitsPath: defaultChecker.hitsPath,
    checkpointPath: defaultChecker.checkpointPath,
    sidecarPath: `${defaultChecker.hitsPath}.lastok`,
    consumeBootForgedAlert: defaultChecker.consumeBootForgedAlert,
    logger: defaultLogger,
    // Task #98: share dismissal state with the dashboard's
    // `POST /lean/ledger-alerts/ack` sidecar so an acknowledged
    // incident stays quiet on subsequent ticks (even on failure_mode
    // transition) until a recovery alert clears it.
    isAcknowledged: (alertId) =>
      isAlertAcknowledged(ackPath, alertId, defaultLogger),
  });
  defaultChecker.setMonitorInfoProvider(() => monitor.getInfo());
  defaultLogger.info(
    { intervalSeconds: monitorIntervalSeconds },
    "ledger monitor: started (auto integrity check on a timer)",
  );
} else {
  defaultLogger.info(
    "ledger monitor: disabled (LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS=off)",
  );
}

// Task #176: daily summary email (or webhook) of checkpoint re-roll
// attempts. Runs on its own setInterval so a quiet dashboard doesn't
// hide an unauthorized referee racking up successful re-rolls. Rides
// the same `createKernelAlertSink` plumbing as the integrity monitor,
// so MORNINGSTAR_ALERT_WEBHOOK_URL / MORNINGSTAR_ALERT_EMAIL_TO
// already-configured for tamper alerts also receive the digest.
import {
  resolveRerollDigestIntervalSeconds,
  startRerollDigestScheduler,
} from "../lib/rerollDigest.js";

const rerollDigestIntervalSeconds = resolveRerollDigestIntervalSeconds(
  process.env["MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS"],
);
if (rerollDigestIntervalSeconds != null) {
  const windowHours = Math.max(1, Math.round(rerollDigestIntervalSeconds / 3600));
  startRerollDigestScheduler({
    intervalMs: rerollDigestIntervalSeconds * 1000,
    windowHours,
    sink: createKernelAlertSink({
      repoRoot: REPO_ROOT,
      logger: defaultLogger,
    }),
    logger: defaultLogger,
  });
  defaultLogger.info(
    { intervalSeconds: rerollDigestIntervalSeconds, windowHours },
    "reroll digest: scheduled (daily summary of checkpoint re-rolls)",
  );
} else {
  defaultLogger.info(
    "reroll digest: disabled (MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS=off)",
  );
}

export { defaultChecker };
export default defaultChecker.router;
