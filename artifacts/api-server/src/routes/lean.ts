import { Router, type IRouter } from "express";
import { existsSync, readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createHash } from "node:crypto";
import path from "node:path";
import { desc, lt } from "drizzle-orm";
import {
  db,
  leanRebuildHistoryTable,
  ledgerCheckpointRerollHistoryTable,
} from "@workspace/db";

const router: IRouter = Router();

function resolveRepoRoot(): string {
  const candidates = [
    process.cwd(),
    path.resolve(process.cwd(), "..", ".."),
    path.resolve(process.cwd(), ".."),
  ];
  for (const c of candidates) {
    if (existsSync(path.join(c, "lean-proof", "VERIFY.txt"))) return c;
    if (existsSync(path.join(c, "lean-proof", "regenerate.sh"))) return c;
  }
  return candidates[0];
}

const REPO_ROOT = resolveRepoRoot();
const VERIFY_PATH = path.join(REPO_ROOT, "lean-proof", "VERIFY.txt");
const REGENERATE_SCRIPT = path.join(REPO_ROOT, "lean-proof", "regenerate.sh");
const REBUILD_TIMEOUT_MS = 5 * 60 * 1000;
const REBUILD_COOLDOWN_MS = 60 * 1000;

let lastRebuildFinishedAt = 0;

interface RebuildHistoryEntry {
  timestamp: string;
  durationMs: number;
  exitCode: number;
  ok: boolean;
  error: string | null;
  streamed: boolean;
  refereeName: string | null;
}

const REBUILD_HISTORY_CAPACITY = 20;

async function recordRebuildAttempt(
  entry: RebuildHistoryEntry,
  log: import("pino").Logger,
): Promise<void> {
  try {
    await db.insert(leanRebuildHistoryTable).values({
      timestamp: new Date(entry.timestamp),
      durationMs: entry.durationMs,
      exitCode: entry.exitCode,
      ok: entry.ok,
      error: entry.error,
      streamed: entry.streamed,
      refereeName: entry.refereeName,
    });

    // Trim to capacity: delete rows older than the Nth most recent.
    const cutoff = await db
      .select({ id: leanRebuildHistoryTable.id })
      .from(leanRebuildHistoryTable)
      .orderBy(desc(leanRebuildHistoryTable.id))
      .limit(1)
      .offset(REBUILD_HISTORY_CAPACITY);
    if (cutoff.length > 0) {
      await db
        .delete(leanRebuildHistoryTable)
        .where(lt(leanRebuildHistoryTable.id, cutoff[0].id + 1));
    }
  } catch (err) {
    log.error({ err }, "Failed to persist rebuild history entry");
  }
}

interface CheckpointRerollHistoryEntry {
  timestamp: string;
  durationMs: number;
  exitCode: number;
  ok: boolean;
  error: string | null;
  refereeName: string | null;
  ip: string | null;
}

const CHECKPOINT_REROLL_HISTORY_CAPACITY = 20;

async function recordCheckpointRerollAttempt(
  entry: CheckpointRerollHistoryEntry,
  log: import("pino").Logger,
): Promise<void> {
  try {
    await db.insert(ledgerCheckpointRerollHistoryTable).values({
      timestamp: new Date(entry.timestamp),
      durationMs: entry.durationMs,
      exitCode: entry.exitCode,
      ok: entry.ok,
      error: entry.error,
      refereeName: entry.refereeName,
      ip: entry.ip,
    });
    const cutoff = await db
      .select({ id: ledgerCheckpointRerollHistoryTable.id })
      .from(ledgerCheckpointRerollHistoryTable)
      .orderBy(desc(ledgerCheckpointRerollHistoryTable.id))
      .limit(1)
      .offset(CHECKPOINT_REROLL_HISTORY_CAPACITY);
    if (cutoff.length > 0) {
      await db
        .delete(ledgerCheckpointRerollHistoryTable)
        .where(lt(ledgerCheckpointRerollHistoryTable.id, cutoff[0].id + 1));
    }
  } catch (err) {
    log.error({ err }, "Failed to persist checkpoint reroll history entry");
  }
}

async function listCheckpointRerollHistory(): Promise<CheckpointRerollHistoryEntry[]> {
  const rows = await db
    .select()
    .from(ledgerCheckpointRerollHistoryTable)
    .orderBy(desc(ledgerCheckpointRerollHistoryTable.id))
    .limit(CHECKPOINT_REROLL_HISTORY_CAPACITY);
  return rows.map((r) => ({
    timestamp: r.timestamp.toISOString(),
    durationMs: r.durationMs,
    exitCode: r.exitCode,
    ok: r.ok,
    error: r.error,
    refereeName: r.refereeName,
    ip: r.ip,
  }));
}

async function listRebuildHistory(): Promise<RebuildHistoryEntry[]> {
  const rows = await db
    .select()
    .from(leanRebuildHistoryTable)
    .orderBy(desc(leanRebuildHistoryTable.id))
    .limit(REBUILD_HISTORY_CAPACITY);
  return rows.map((r) => ({
    timestamp: r.timestamp.toISOString(),
    durationMs: r.durationMs,
    exitCode: r.exitCode,
    ok: r.ok,
    error: r.error,
    streamed: r.streamed,
    refereeName: r.refereeName,
  }));
}

function checkRebuildCooldown(): { ok: true } | { ok: false; retryAfterMs: number } {
  const elapsed = Date.now() - lastRebuildFinishedAt;
  if (lastRebuildFinishedAt > 0 && elapsed < REBUILD_COOLDOWN_MS) {
    return { ok: false, retryAfterMs: REBUILD_COOLDOWN_MS - elapsed };
  }
  return { ok: true };
}

interface ParsedVerification {
  toolchain: string;
  dateVerified: string;
  axiomDebt: string[];
  axiomLines: string[];
  content: string;
  lastModified: string;
}

function parseVerification(content: string, lastModified: string): ParsedVerification {
  const toolchainMatch = content.match(/Lean toolchain\s*:\s*(.+)/);
  const dateMatch = content.match(/Date verified\s*:\s*(.+)/);
  const axiomLines = content
    .split("\n")
    .filter((l) => /does not depend on any axioms/.test(l))
    .map((l) => l.trim());
  const debtMatch = content.match(/Axiom debt\s*=\s*\[([^\]]*)\]/);
  const axiomDebt = debtMatch && debtMatch[1].trim().length > 0
    ? debtMatch[1].split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  return {
    toolchain: toolchainMatch ? toolchainMatch[1].trim() : "unknown",
    dateVerified: dateMatch ? dateMatch[1].trim() : "unknown",
    axiomDebt,
    axiomLines,
    content,
    lastModified,
  };
}

let cached: ParsedVerification | null = null;
let cachedError: string | null = null;

function readVerification(): ParsedVerification | null {
  try {
    const content = readFileSync(VERIFY_PATH, "utf8");
    const stat = statSync(VERIFY_PATH);
    return parseVerification(content, stat.mtime.toISOString());
  } catch (err) {
    cachedError = err instanceof Error ? err.message : String(err);
    return null;
  }
}

function load(): ParsedVerification | null {
  if (cached) return cached;
  if (cachedError) return null;
  cached = readVerification();
  return cached;
}

function invalidateCache(): void {
  cached = null;
  cachedError = null;
}

let ALERTS_LOG_PATH = path.join(REPO_ROOT, "data", "ledger-alerts.jsonl");
let ALERTS_ACK_PATH = path.join(REPO_ROOT, "data", "ledger-alerts.ack.json");
const ALERTS_DEFAULT_LIMIT = 20;
const ALERTS_MAX_LIMIT = 200;
// Upper bound on how many rotated alert files we probe for. The Python
// rotator caps itself at `MORNINGSTAR_ALERTS_MAX_ROTATIONS` (default 3),
// but operators can tune that env var up; we scan a generous fixed
// window so the dashboard surfaces any rotation a sysadmin may have
// kept around manually.
const ALERTS_ROTATION_PROBE_MAX = 32;

interface AlertRotationInfo {
  index: number;
  path: string;
  size: number;
  mtime: string;
}

function listAlertRotations(): AlertRotationInfo[] {
  const out: AlertRotationInfo[] = [];
  for (let i = 1; i <= ALERTS_ROTATION_PROBE_MAX; i++) {
    const p = `${ALERTS_LOG_PATH}.${i}`;
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
      // Missing or unreadable rotation — skip silently. The dashboard
      // surface is informational, not a correctness one.
    }
  }
  return out;
}

import {
  computeAlertId,
  readAckMap as readAckMapShared,
  writeAckMap as writeAckMapShared,
} from "../lib/alertAckStore.js";
import { buildRerollDigest, fetchRerollRowsSince } from "../lib/rerollDigest.js";
import { defaultChecker as defaultLedgerChecker } from "./ledger.js";

/**
 * Task #124: indirection so tests can swap in a stub acker without
 * needing the full ledger boot path. Defaults to the real default
 * checker's `acknowledgeForgedSidecar` (which writes the on-disk
 * forged-ack sidecar and clears any in-flight one-shot alert latch).
 */
let forgedSidecarAcker: typeof defaultLedgerChecker.acknowledgeForgedSidecar =
  defaultLedgerChecker.acknowledgeForgedSidecar;

/**
 * Task #140: same indirection as `forgedSidecarAcker` so tests can
 * swap in a stub rotator without booting the full checker.
 */
let sidecarSecretRotator: typeof defaultLedgerChecker.rotateSidecarSecret =
  defaultLedgerChecker.rotateSidecarSecret;

/**
 * Task #150: same indirection so tests can swap in a stub history
 * source without booting the full checker.
 */
let forgedSidecarHistoryLister: typeof defaultLedgerChecker.listForgedAckHistory =
  defaultLedgerChecker.listForgedAckHistory;

function readAckMap(log: import("pino").Logger): Record<string, string> {
  return readAckMapShared(ALERTS_ACK_PATH, log);
}

function writeAckMap(map: Record<string, string>, log: import("pino").Logger): void {
  writeAckMapShared(ALERTS_ACK_PATH, map, log);
}

type AlertDeliveryStatus = "ok" | "failed" | "not_configured";

interface AlertDelivery {
  status: AlertDeliveryStatus;
  error: string | null;
}

interface LedgerAlertView {
  id: string;
  acknowledgedAt: string | null;
  timestamp: string;
  workflow: string;
  message: string;
  subject: string;
  failureMode: string | null;
  previousFailureMode: string | null;
  recovery: string | null;
  hitsPath: string | null;
  checkpointPath: string | null;
  expectedSize: number | null;
  actualSize: number | null;
  expectedSha: string | null;
  source: string | null;
  delivery: {
    webhook: AlertDelivery;
    email: AlertDelivery;
  };
}

/**
 * Mirror of `kernel._alert_subject` (task #144). The python kernel
 * injects a `subject` field into every fired payload, but legacy
 * `data/ledger-alerts.jsonl` entries from before that change still
 * lack it. The dashboard renders this field as the row header (task
 * #161), so we derive it server-side when the raw entry is missing
 * the field — keeping the UI free of null-coalescing branches and
 * keeping a single source of truth for subject wording.
 */
function deriveAlertSubject(
  workflow: string,
  failureMode: string | null,
  previousFailureMode: string | null,
): string {
  if (failureMode === "monitor_stalled") {
    return `[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: ${workflow}`;
  }
  if (failureMode === "recovered" && previousFailureMode === "monitor_stalled") {
    return `[MorningStar] Ledger monitor RECOVERED: ${workflow}`;
  }
  if (failureMode === "recovered") {
    return `[MorningStar] Ledger integrity RECOVERED: ${workflow}`;
  }
  return `[MorningStar] Ledger integrity alert: ${workflow}`;
}

function pickString(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}

function pickInt(v: unknown): number | null {
  return typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null;
}

function normalizeDelivery(raw: unknown): AlertDelivery {
  if (!raw || typeof raw !== "object") {
    return { status: "not_configured", error: null };
  }
  const r = raw as Record<string, unknown>;
  const status = r["status"];
  const allowed: AlertDeliveryStatus[] = ["ok", "failed", "not_configured"];
  const s: AlertDeliveryStatus =
    typeof status === "string" && (allowed as string[]).includes(status)
      ? (status as AlertDeliveryStatus)
      : "not_configured";
  const err = typeof r["error"] === "string" ? (r["error"] as string) : null;
  return { status: s, error: err };
}

function normalizeAlertEntry(raw: unknown): LedgerAlertView | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const timestamp = pickString(r["timestamp"]);
  const message = pickString(r["message"]);
  if (!timestamp || !message) return null;
  const workflow = pickString(r["workflow"]) ?? "unknown";
  const delivery = (r["delivery"] ?? {}) as Record<string, unknown>;
  const failureMode = pickString(r["failure_mode"]);
  const previousFailureMode = pickString(r["previous_failure_mode"]);
  const rawSubject = pickString(r["subject"]);
  const subject =
    rawSubject && rawSubject.length > 0
      ? rawSubject
      : deriveAlertSubject(workflow, failureMode, previousFailureMode);
  return {
    id: computeAlertId(timestamp, message),
    acknowledgedAt: null,
    timestamp,
    workflow,
    message,
    subject,
    failureMode,
    previousFailureMode,
    recovery: pickString(r["recovery"]),
    hitsPath: pickString(r["hits_path"]),
    checkpointPath: pickString(r["checkpoint_path"]),
    expectedSize: pickInt(r["expected_size"]),
    actualSize: pickInt(r["actual_size"]),
    expectedSha: pickString(r["expected_sha"]),
    source: pickString(r["source"]),
    delivery: {
      webhook: normalizeDelivery(delivery["webhook"]),
      email: normalizeDelivery(delivery["email"]),
    },
  };
}

router.get("/lean/ledger-alerts", (req, res) => {
  const rawLimit = req.query["limit"];
  let limit = ALERTS_DEFAULT_LIMIT;
  if (typeof rawLimit === "string" && rawLimit.length > 0) {
    const n = Number.parseInt(rawLimit, 10);
    if (Number.isFinite(n) && n > 0) {
      limit = Math.min(ALERTS_MAX_LIMIT, n);
    }
  }
  const rawInclude = req.query["includeAcknowledged"];
  const includeAcknowledged =
    typeof rawInclude === "string" && /^(1|true|yes)$/i.test(rawInclude);
  const rawRotation = req.query["rotation"];
  let rotation = 0;
  if (typeof rawRotation === "string" && rawRotation.length > 0) {
    const n = Number.parseInt(rawRotation, 10);
    if (Number.isFinite(n) && n > 0) {
      rotation = Math.min(ALERTS_ROTATION_PROBE_MAX, n);
    }
  }
  const availableRotations = listAlertRotations();
  const targetPath =
    rotation > 0 ? `${ALERTS_LOG_PATH}.${rotation}` : ALERTS_LOG_PATH;
  // GC of stale ack entries only runs when reading the live log. Rotated
  // files are immutable archives; their acks may legitimately predate the
  // oldest entry in the live ring buffer, and reaping them here would
  // destroy the operator's ability to see "this incident was already
  // dismissed" when paging back.
  const isLiveRead = rotation === 0;
  const ackMap = readAckMap(req.log);
  const logExists = existsSync(targetPath);
  if (!logExists) {
    res.json({
      alerts: [],
      limit,
      totalReturned: 0,
      logPath: targetPath,
      logExists: false,
      ackGcDropped: 0,
      rotation,
      availableRotations,
    });
    return;
  }
  let raw: string;
  try {
    raw = readFileSync(targetPath, "utf8");
  } catch (err) {
    req.log.warn({ err, path: targetPath }, "Failed to read alerts log");
    res.json({
      alerts: [],
      limit,
      totalReturned: 0,
      logPath: targetPath,
      logExists: true,
      ackGcDropped: 0,
      rotation,
      availableRotations,
    });
    return;
  }
  const lines = raw.split("\n");
  // GC pass: drop ack ids whose acknowledgement predates the oldest live
  // alert in the log. Such acks reference alerts that have rolled off the
  // ring buffer and can never match a real entry again — keeping them
  // around just bloats the sidecar and risks spurious collisions if a
  // future alert hashes to the same id.
  let ackGcDropped = 0;
  if (isLiveRead) {
    let oldestLiveAlertMs: number | null = null;
    for (const line of lines) {
      const t = line.trim();
      if (!t) continue;
      try {
        const parsed = JSON.parse(t) as unknown;
        const entry = normalizeAlertEntry(parsed);
        if (!entry) continue;
        const ms = Date.parse(entry.timestamp);
        if (Number.isFinite(ms)) {
          oldestLiveAlertMs = ms;
          break;
        }
      } catch {
        // Skip malformed lines.
      }
    }
    if (oldestLiveAlertMs !== null && Object.keys(ackMap).length > 0) {
      for (const [id, ackedAt] of Object.entries(ackMap)) {
        const ackMs = Date.parse(ackedAt);
        if (Number.isFinite(ackMs) && ackMs < oldestLiveAlertMs) {
          delete ackMap[id];
          ackGcDropped++;
        }
      }
      if (ackGcDropped > 0) {
        try {
          writeAckMap(ackMap, req.log);
        } catch (err) {
          req.log.warn(
            { err, path: ALERTS_ACK_PATH },
            "Failed to persist GC'd alert ack sidecar",
          );
        }
      }
    }
  }
  const alerts: LedgerAlertView[] = [];
  for (let i = lines.length - 1; i >= 0 && alerts.length < limit; i--) {
    const line = lines[i].trim();
    if (!line) continue;
    try {
      const parsed = JSON.parse(line) as unknown;
      const entry = normalizeAlertEntry(parsed);
      if (!entry) continue;
      const ack = ackMap[entry.id];
      if (ack) {
        if (!includeAcknowledged) continue;
        entry.acknowledgedAt = ack;
      }
      alerts.push(entry);
    } catch {
      // Malformed JSON line (e.g. partial write) — skip; informational
      // surface, not a correctness one.
    }
  }
  res.json({
    alerts,
    limit,
    totalReturned: alerts.length,
    logPath: targetPath,
    logExists: true,
    ackGcDropped,
    rotation,
    availableRotations,
  });
});

const RerollHelperPath = path.join(REPO_ROOT, "scripts", "reroll-checkpoint.py");
const REROLL_TIMEOUT_MS = 30 * 1000;

let checkpointRerollInFlight = false;

interface RerollOutcome {
  ok: boolean;
  exitCode: number;
  stdout: string;
  stderr: string;
  error: string | null;
}

type RerollSpawner = (opts: {
  script: string;
  cwd: string;
  timeoutMs: number;
}) => Promise<RerollOutcome>;

const defaultRerollSpawner: RerollSpawner = ({ script, cwd, timeoutMs }) =>
  new Promise<RerollOutcome>((resolve) => {
    let child: ChildProcessWithoutNullStreams;
    try {
      child = spawn("python3", [script], { cwd, env: process.env });
    } catch (err) {
      resolve({
        ok: false,
        exitCode: -1,
        stdout: "",
        stderr: "",
        error: `spawn_failed: ${err instanceof Error ? err.message : String(err)}`,
      });
      return;
    }
    let stdout = "";
    let stderr = "";
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill("SIGKILL");
    }, timeoutMs);
    child.stdout.on("data", (c: Buffer) => {
      stdout += c.toString("utf8");
    });
    child.stderr.on("data", (c: Buffer) => {
      stderr += c.toString("utf8");
    });
    child.on("error", (err) => {
      clearTimeout(timer);
      resolve({
        ok: false,
        exitCode: -1,
        stdout,
        stderr,
        error: `spawn_failed: ${err.message}`,
      });
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      if (timedOut) {
        resolve({
          ok: false,
          exitCode: code ?? -1,
          stdout,
          stderr,
          error: `timeout: reroll-checkpoint.py exceeded ${timeoutMs}ms`,
        });
        return;
      }
      const ok = code === 0;
      let error: string | null = null;
      if (!ok) {
        if (code === 2) {
          error =
            "refused: existing checkpoint fails verification — investigate the tamper incident before re-rolling.";
        } else {
          error = `reroll-checkpoint.py exited ${code ?? "null"}`;
        }
      }
      resolve({ ok, exitCode: code ?? -1, stdout, stderr, error });
    });
  });

let rerollSpawner: RerollSpawner = defaultRerollSpawner;

router.post("/ledger/checkpoint/reroll", async (req, res) => {
  const start = Date.now();
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: auth.error,
    });
    return;
  }
  if (checkpointRerollInFlight || rebuildInFlight) {
    res.status(409).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error:
        "Another checkpoint re-roll or Lean rebuild is already in flight. Please wait for it to finish.",
    });
    return;
  }
  const cooldown = checkRebuildCooldown();
  if (!cooldown.ok) {
    const retryAfterSec = Math.ceil(cooldown.retryAfterMs / 1000);
    res.setHeader("Retry-After", String(retryAfterSec));
    res.status(429).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: `Rebuild/re-roll cooldown active. Please wait ${retryAfterSec}s before triggering another.`,
    });
    return;
  }
  checkpointRerollInFlight = true;
  try {
    const outcome = await rerollSpawner({
      script: RerollHelperPath,
      cwd: REPO_ROOT,
      timeoutMs: REROLL_TIMEOUT_MS,
    });
    lastRebuildFinishedAt = Date.now();
    const durationMs = Date.now() - start;
    const clientIp = getClientIp(req);
    req.log.info(
      {
        ok: outcome.ok,
        exitCode: outcome.exitCode,
        durationMs,
        rerolledBy: clientIp,
        refereeName: auth.refereeName,
      },
      "Ledger checkpoint reroll attempted",
    );
    await recordCheckpointRerollAttempt(
      {
        timestamp: new Date().toISOString(),
        durationMs,
        exitCode: outcome.exitCode,
        ok: outcome.ok,
        error: outcome.error,
        refereeName: auth.refereeName,
        ip: clientIp || null,
      },
      req.log,
    );
    res.json({
      ok: outcome.ok,
      exitCode: outcome.exitCode,
      stdout: outcome.stdout,
      stderr: outcome.stderr,
      durationMs,
      error: outcome.error,
    });
  } finally {
    checkpointRerollInFlight = false;
  }
});

router.post("/ledger/checkpoint/reroll/stream", (req, res) => {
  const start = Date.now();
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ error: auth.error });
    return;
  }
  if (checkpointRerollInFlight || rebuildInFlight) {
    res.status(409).json({
      error:
        "Another checkpoint re-roll or Lean rebuild is already in flight. Please wait for it to finish.",
    });
    return;
  }
  const cooldown = checkRebuildCooldown();
  if (!cooldown.ok) {
    const retryAfterSec = Math.ceil(cooldown.retryAfterMs / 1000);
    res.setHeader("Retry-After", String(retryAfterSec));
    res.status(429).json({
      error: `Rebuild/re-roll cooldown active. Please wait ${retryAfterSec}s before triggering another.`,
    });
    return;
  }
  if (!existsSync(RerollHelperPath)) {
    req.log.error({ path: RerollHelperPath }, "reroll-checkpoint.py not found");
    res
      .status(500)
      .json({ error: `reroll-checkpoint.py not found at ${RerollHelperPath}` });
    return;
  }

  res.status(200);
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders?.();

  const sendEvent = (event: string, data: unknown) => {
    if (res.writableEnded) return;
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  checkpointRerollInFlight = true;
  let child: ChildProcessWithoutNullStreams;
  try {
    child = spawn("python3", [RerollHelperPath], {
      cwd: REPO_ROOT,
      env: process.env,
    });
  } catch (err) {
    checkpointRerollInFlight = false;
    const message = err instanceof Error ? err.message : String(err);
    req.log.error({ err: message }, "Failed to spawn reroll-checkpoint.py");
    sendEvent("result", {
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: `spawn_failed: ${message}`,
    });
    res.end();
    return;
  }

  let stdout = "";
  let stderr = "";
  let stdoutBuf = "";
  let stderrBuf = "";
  let timedOut = false;

  const pushLines = (stream: "stdout" | "stderr", buf: string): string => {
    let remainder = buf;
    let idx: number;
    while ((idx = remainder.indexOf("\n")) !== -1) {
      const line = remainder.slice(0, idx).replace(/\r$/, "");
      remainder = remainder.slice(idx + 1);
      sendEvent("line", { stream, line });
    }
    return remainder;
  };

  child.stdout.on("data", (chunk: Buffer) => {
    const text = chunk.toString("utf8");
    stdout += text;
    stdoutBuf = pushLines("stdout", stdoutBuf + text);
  });
  child.stderr.on("data", (chunk: Buffer) => {
    const text = chunk.toString("utf8");
    stderr += text;
    stderrBuf = pushLines("stderr", stderrBuf + text);
  });

  const heartbeat = setInterval(() => {
    if (!res.writableEnded) res.write(`: keepalive\n\n`);
  }, 15000);

  const timer = setTimeout(() => {
    timedOut = true;
    child.kill("SIGKILL");
  }, REROLL_TIMEOUT_MS);

  let responded = false;
  const finish = (payload: { ok: boolean; exitCode: number; error: string | null }) => {
    if (responded) return;
    responded = true;
    clearTimeout(timer);
    clearInterval(heartbeat);
    checkpointRerollInFlight = false;
    lastRebuildFinishedAt = Date.now();

    if (stdoutBuf.length > 0) {
      sendEvent("line", { stream: "stdout", line: stdoutBuf.replace(/\r$/, "") });
      stdoutBuf = "";
    }
    if (stderrBuf.length > 0) {
      sendEvent("line", { stream: "stderr", line: stderrBuf.replace(/\r$/, "") });
      stderrBuf = "";
    }

    const durationMs = Date.now() - start;
    const clientIp = getClientIp(req);
    req.log.info(
      {
        ok: payload.ok,
        exitCode: payload.exitCode,
        durationMs,
        rerolledBy: clientIp,
        refereeName: auth.refereeName,
        streamed: true,
      },
      "Ledger checkpoint reroll attempted",
    );
    void recordCheckpointRerollAttempt(
      {
        timestamp: new Date().toISOString(),
        durationMs,
        exitCode: payload.exitCode,
        ok: payload.ok,
        error: payload.error,
        refereeName: auth.refereeName,
        ip: clientIp || null,
      },
      req.log,
    );

    sendEvent("result", {
      ok: payload.ok,
      exitCode: payload.exitCode,
      stdout,
      stderr,
      durationMs,
      error: payload.error,
    });
    res.end();
  };

  child.on("error", (err) => {
    const message = err instanceof Error ? err.message : String(err);
    finish({ ok: false, exitCode: -1, error: `spawn_failed: ${message}` });
  });

  child.on("close", (code) => {
    if (timedOut) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `timeout: reroll-checkpoint.py exceeded ${REROLL_TIMEOUT_MS}ms`,
      });
      return;
    }
    const exitCode = code ?? -1;
    if (exitCode === 0) {
      finish({ ok: true, exitCode, error: null });
      return;
    }
    let error: string;
    if (exitCode === 2) {
      error =
        "refused: existing checkpoint fails verification — investigate the tamper incident before re-rolling.";
    } else {
      error = `reroll-checkpoint.py exited ${exitCode}`;
    }
    finish({ ok: false, exitCode, error });
  });
});

router.get("/ledger/checkpoint/reroll/history", async (req, res) => {
  try {
    const entries = await listCheckpointRerollHistory();
    res.json({ entries, capacity: CHECKPOINT_REROLL_HISTORY_CAPACITY });
  } catch (err) {
    req.log.error({ err }, "Failed to read checkpoint reroll history");
    res.status(500).json({ error: "Failed to read checkpoint reroll history" });
  }
});

// Task #199: surface the daily re-roll digest on the dashboard. Digests
// aren't persisted (the scheduler only emails/webhooks them), so we
// recompute on demand from the persisted re-roll history using the exact
// same `buildRerollDigest` the scheduler uses — operators get the same
// per-referee ok/fail rollup + failing rows + rendered text without
// digging through their inbox.
const REROLL_DIGEST_WINDOW_HOURS: Record<string, number> = {
  "24h": 24,
  "7d": 24 * 7,
  "30d": 24 * 30,
};
const REROLL_DIGEST_DEFAULT_WINDOW = "24h";

router.get("/ledger/checkpoint/reroll/digest", async (req, res) => {
  const rawWindow = req.query["window"];
  const windowKey =
    typeof rawWindow === "string" &&
    Object.hasOwn(REROLL_DIGEST_WINDOW_HOURS, rawWindow)
      ? rawWindow
      : REROLL_DIGEST_DEFAULT_WINDOW;
  const windowHours = REROLL_DIGEST_WINDOW_HOURS[windowKey];
  try {
    const rows = await fetchRerollRowsSince(windowHours);
    const digest = buildRerollDigest(rows, windowHours);
    res.json({ window: windowKey, ...digest });
  } catch (err) {
    req.log.error({ err }, "Failed to build checkpoint reroll digest");
    res
      .status(500)
      .json({ error: "Failed to build checkpoint reroll digest" });
  }
});

router.get("/ledger/sidecar-forged-ack/history", (req, res) => {
  // Task #150: read-only, no auth — mirrors `/ledger/checkpoint/reroll/history`.
  // The "Recent dismissals" panel is an audit view; referees should be
  // able to look at it without holding a rebuild token.
  const rawLimit = req.query["limit"];
  let limit: number | undefined;
  if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
    const parsed = Number(rawLimit);
    if (Number.isFinite(parsed) && parsed > 0) {
      limit = Math.floor(parsed);
    }
  }
  // Task #168: rotation paging — `0` (default) reads the live history
  // file, `N >= 1` reads the Nth archive. Clamping happens inside the
  // checker so a hostile `?rotation=999999` query can't drive path
  // traversal.
  const rawRotation = req.query["rotation"];
  let rotation: number | undefined;
  if (typeof rawRotation === "string" && rawRotation.trim() !== "") {
    const parsed = Number(rawRotation);
    if (Number.isFinite(parsed) && parsed >= 0) {
      rotation = Math.floor(parsed);
    }
  }
  try {
    const result = forgedSidecarHistoryLister(limit, rotation);
    res.json(result);
  } catch (err) {
    req.log.error({ err }, "Failed to read forged-ack history");
    res.status(500).json({ error: "Failed to read forged-ack history" });
  }
});

router.post("/ledger/sidecar-forged-ack", (req, res) => {
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ ok: false, error: auth.error });
    return;
  }
  // Task #139: thread the rebuild-auth attribution into the ack so
  // the audit trail / dashboard tooltip name the dismisser. Named
  // tokens from LEDGER_REBUILD_TOKENS win (auth.refereeName already
  // implements that precedence over X-Referee-Name); a shared-token
  // deploy with no header falls through to "anonymous" inside the
  // checker.
  const result = forgedSidecarAcker(auth.refereeName);
  if (!result.ok) {
    res.status(409).json({
      ok: false,
      error:
        "No forged-sidecar incident to acknowledge: the boot sidecar read came back ok / missing / stale_checkpoint_binding.",
    });
    return;
  }
  req.log.info(
    {
      payloadSha: result.payloadSha,
      acknowledgedAt: result.acknowledgedAt,
      alreadyAcknowledged: result.alreadyAcknowledged,
      ackedBy: result.ackedBy,
      ackedByIp: getClientIp(req),
      refereeName: auth.refereeName,
    },
    "Ledger sidecar-forged incident acknowledged by operator",
  );
  res.json({
    ok: true,
    acknowledgedAt: result.acknowledgedAt,
    alreadyAcknowledged: result.alreadyAcknowledged,
    payloadSha: result.payloadSha,
    ackedBy: result.ackedBy,
  });
});

router.post("/ledger/sidecar-secret/rotate", (req, res) => {
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ ok: false, error: auth.error });
    return;
  }
  // Task #140: thread the rebuild-auth attribution into the rotation
  // log so the audit trail names the operator who rotated the secret
  // (named tokens win over X-Referee-Name, same precedence as ack).
  const result = sidecarSecretRotator(auth.refereeName);
  req.log.warn(
    {
      rotatedAt: result.rotatedAt,
      rotatedBy: result.rotatedBy,
      rotatedByIp: getClientIp(req),
      refereeName: auth.refereeName,
      persistedTo: result.persistedTo,
      secretPersisted: result.secretPersisted,
      sidecarResealed: result.sidecarResealed,
      hadForgedIncident: result.hadForgedIncident,
    },
    "Ledger sidecar HMAC secret rotated by operator",
  );
  res.json({
    ok: true,
    rotatedAt: result.rotatedAt,
    rotatedBy: result.rotatedBy,
    persistedTo: result.persistedTo,
    keyfilePath: result.keyfilePath,
    secretPersisted: result.secretPersisted,
    sidecarResealed: result.sidecarResealed,
    hadForgedIncident: result.hadForgedIncident,
  });
});

router.post("/lean/ledger-alerts/ack", (req, res) => {
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ ok: false, error: auth.error });
    return;
  }
  const body = (req.body ?? {}) as { timestamp?: unknown; message?: unknown };
  const timestamp = typeof body.timestamp === "string" ? body.timestamp : "";
  const message = typeof body.message === "string" ? body.message : "";
  if (!timestamp || !message) {
    res.status(400).json({
      ok: false,
      error: "Missing required fields `timestamp` and/or `message`.",
    });
    return;
  }
  const id = computeAlertId(timestamp, message);
  const ackMap = readAckMap(req.log);
  const existing = ackMap[id];
  if (existing) {
    res.json({
      ok: true,
      id,
      acknowledgedAt: existing,
      alreadyAcknowledged: true,
    });
    return;
  }
  const acknowledgedAt = new Date().toISOString();
  ackMap[id] = acknowledgedAt;
  try {
    writeAckMap(ackMap, req.log);
  } catch (err) {
    res.status(500).json({
      ok: false,
      error: `Failed to persist acknowledgement: ${err instanceof Error ? err.message : String(err)}`,
    });
    return;
  }
  req.log.info(
    { alertId: id, ackedBy: getClientIp(req) },
    "Ledger alert acknowledged by operator",
  );
  res.json({
    ok: true,
    id,
    acknowledgedAt,
    alreadyAcknowledged: false,
  });
});

router.get("/lean/verify/history", async (req, res) => {
  try {
    const entries = await listRebuildHistory();
    res.json({ entries, capacity: REBUILD_HISTORY_CAPACITY });
  } catch (err) {
    req.log.error({ err }, "Failed to read rebuild history");
    res.status(500).json({ error: "Failed to read rebuild history" });
  }
});

router.get("/lean/verify", (req, res) => {
  const parsed = load();
  if (!parsed) {
    req.log.error({ path: VERIFY_PATH, err: cachedError }, "Failed to read VERIFY.txt");
    res.status(500).json({ error: "Verification log unavailable" });
    return;
  }
  const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
  const ageDays = ageMs / (1000 * 60 * 60 * 24);
  res.json({ ...parsed, ageDays });
});

let rebuildInFlight = false;
let currentChild: ChildProcessWithoutNullStreams | null = null;
let cancelRequested = false;

function extractBearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

type RebuildAuthResult =
  | { ok: true; refereeName: string | null }
  | { ok: false; status: number; error: string; retryAfterSec?: number };

const REFEREE_NAME_PATTERN = /^[A-Za-z0-9 _.\-]{1,64}$/;

function sanitizeRefereeName(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (!REFEREE_NAME_PATTERN.test(trimmed)) return null;
  return trimmed;
}

interface NamedToken {
  name: string;
  token: string;
}

let namedTokensCache: { raw: string | undefined; tokens: NamedToken[] } = {
  raw: undefined,
  tokens: [],
};

function getNamedTokens(): NamedToken[] {
  const raw = process.env["LEAN_REBUILD_TOKENS"];
  if (raw === namedTokensCache.raw) return namedTokensCache.tokens;
  const tokens: NamedToken[] = [];
  if (raw && raw.trim().length > 0) {
    for (const pair of raw.split(",")) {
      const trimmed = pair.trim();
      if (!trimmed) continue;
      const colon = trimmed.indexOf(":");
      if (colon <= 0 || colon === trimmed.length - 1) continue;
      const name = trimmed.slice(0, colon).trim();
      const token = trimmed.slice(colon + 1).trim();
      if (!name || !token) continue;
      if (!REFEREE_NAME_PATTERN.test(name)) continue;
      tokens.push({ name, token });
    }
  }
  namedTokensCache = { raw, tokens };
  return tokens;
}

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;
const FAILURE_WINDOW_MS = 15 * 60 * 1000;
const MAX_TRACKED_IPS = 10_000;

interface FailureRecord {
  count: number;
  firstFailureAt: number;
  lockedUntil: number;
}

const failuresByIp = new Map<string, FailureRecord>();

function getClientIp(req: import("express").Request): string {
  // Relies on `app.set("trust proxy", ...)` in app.ts so req.ip reflects the
  // real peer only when the request actually came through a trusted proxy
  // hop. We deliberately do NOT parse raw X-Forwarded-For here — that would
  // let any caller spoof the throttle key.
  return req.ip ?? req.socket.remoteAddress ?? "unknown";
}

function evictExpiredFailures(now: number): void {
  for (const [ip, rec] of failuresByIp) {
    const lockoutExpired = rec.lockedUntil > 0 && rec.lockedUntil <= now;
    const windowExpired =
      rec.lockedUntil === 0 && now - rec.firstFailureAt > FAILURE_WINDOW_MS;
    if (lockoutExpired || windowExpired) {
      failuresByIp.delete(ip);
    }
  }
}

function checkLockout(ip: string): { locked: false } | { locked: true; retryAfterMs: number } {
  const rec = failuresByIp.get(ip);
  if (!rec) return { locked: false };
  const now = Date.now();
  if (rec.lockedUntil > now) {
    return { locked: true, retryAfterMs: rec.lockedUntil - now };
  }
  if (rec.lockedUntil > 0 && rec.lockedUntil <= now) {
    failuresByIp.delete(ip);
  }
  return { locked: false };
}

function recordAuthFailure(ip: string, log: import("pino").Logger): void {
  const now = Date.now();
  const rec = failuresByIp.get(ip);
  if (!rec || now - rec.firstFailureAt > FAILURE_WINDOW_MS) {
    if (failuresByIp.size >= MAX_TRACKED_IPS) {
      evictExpiredFailures(now);
      if (failuresByIp.size >= MAX_TRACKED_IPS) {
        // Evict the oldest insertion to keep the map bounded.
        const oldest = failuresByIp.keys().next();
        if (!oldest.done) failuresByIp.delete(oldest.value);
      }
    }
    failuresByIp.set(ip, { count: 1, firstFailureAt: now, lockedUntil: 0 });
    return;
  }
  rec.count += 1;
  if (rec.count >= MAX_FAILED_ATTEMPTS && rec.lockedUntil === 0) {
    rec.lockedUntil = now + LOCKOUT_MS;
    log.warn(
      { ip, failedAttempts: rec.count, lockoutMs: LOCKOUT_MS },
      "Rebuild IP locked out after repeated bad-token attempts",
    );
  }
}

function clearAuthFailures(ip: string): void {
  failuresByIp.delete(ip);
}

function checkRebuildAuth(req: import("express").Request): RebuildAuthResult {
  const ip = getClientIp(req);
  const lockout = checkLockout(ip);
  if (lockout.locked) {
    const retryAfterSec = Math.ceil(lockout.retryAfterMs / 1000);
    req.log.warn(
      { ip, retryAfterSec },
      "Rebuild blocked: IP is locked out from repeated bad-token attempts",
    );
    return {
      ok: false,
      status: 429,
      retryAfterSec,
      error: `Too many failed referee-token attempts from this IP. Try again in ${retryAfterSec}s.`,
    };
  }

  const sharedToken = process.env["LEAN_REBUILD_TOKEN"];
  const namedTokens = getNamedTokens();
  const hasShared = Boolean(sharedToken && sharedToken.length > 0);
  if (!hasShared && namedTokens.length === 0) {
    req.log.warn(
      "Rebuild blocked: neither LEAN_REBUILD_TOKEN nor LEAN_REBUILD_TOKENS is configured",
    );
    return {
      ok: false,
      status: 503,
      error:
        "Lean rebuild is disabled on this server: neither LEAN_REBUILD_TOKEN nor LEAN_REBUILD_TOKENS is configured. Set one to enable referee-driven rebuilds.",
    };
  }
  const provided = extractBearerToken(req.headers["authorization"]);
  if (!provided) {
    recordAuthFailure(ip, req.log);
    req.log.warn({ ip, hasHeader: false }, "Rebuild blocked: bad token");
    return {
      ok: false,
      status: 401,
      error:
        "Unauthorized: a valid referee rebuild token is required (Authorization: Bearer <token>).",
    };
  }
  let matchedName: string | null = null;
  for (const nt of namedTokens) {
    if (timingSafeEqual(provided, nt.token)) {
      matchedName = nt.name;
      break;
    }
  }
  let isSharedMatch = false;
  if (matchedName === null && hasShared && timingSafeEqual(provided, sharedToken!)) {
    isSharedMatch = true;
  }
  if (matchedName === null && !isSharedMatch) {
    recordAuthFailure(ip, req.log);
    req.log.warn({ ip, hasHeader: true }, "Rebuild blocked: bad token");
    return {
      ok: false,
      status: 401,
      error:
        "Unauthorized: a valid referee rebuild token is required (Authorization: Bearer <token>).",
    };
  }
  clearAuthFailures(ip);
  let refereeName: string | null;
  if (matchedName !== null) {
    // Named tokens are authoritative — ignore any X-Referee-Name header
    // so a referee can't impersonate another by spoofing the header.
    refereeName = matchedName;
  } else {
    const header = req.headers["x-referee-name"];
    const headerValue = Array.isArray(header) ? header[0] : header;
    refereeName = sanitizeRefereeName(headerValue);
  }
  return { ok: true, refereeName };
}

function applyAuthFailureHeaders(
  res: import("express").Response,
  auth: Extract<RebuildAuthResult, { ok: false }>,
): void {
  if (auth.status === 429 && typeof auth.retryAfterSec === "number") {
    res.setHeader("Retry-After", String(auth.retryAfterSec));
  }
}

interface ActiveLockoutView {
  ip: string;
  failedAttempts: number;
  lockedSince: string;
  lockedUntil: string;
  retryAfterMs: number;
}

interface FailingIpView {
  ip: string;
  failedAttempts: number;
  firstFailureAt: string;
  windowExpiresAt: string;
}

function snapshotLockouts(): {
  activeLockouts: ActiveLockoutView[];
  failingIps: FailingIpView[];
} {
  const now = Date.now();
  evictExpiredFailures(now);
  const activeLockouts: ActiveLockoutView[] = [];
  const failingIps: FailingIpView[] = [];
  for (const [ip, rec] of failuresByIp) {
    if (rec.lockedUntil > now) {
      activeLockouts.push({
        ip,
        failedAttempts: rec.count,
        lockedSince: new Date(rec.lockedUntil - LOCKOUT_MS).toISOString(),
        lockedUntil: new Date(rec.lockedUntil).toISOString(),
        retryAfterMs: rec.lockedUntil - now,
      });
    } else if (rec.lockedUntil === 0) {
      failingIps.push({
        ip,
        failedAttempts: rec.count,
        firstFailureAt: new Date(rec.firstFailureAt).toISOString(),
        windowExpiresAt: new Date(rec.firstFailureAt + FAILURE_WINDOW_MS).toISOString(),
      });
    }
  }
  activeLockouts.sort((a, b) => b.retryAfterMs - a.retryAfterMs);
  failingIps.sort((a, b) => b.failedAttempts - a.failedAttempts);
  return { activeLockouts, failingIps };
}

router.get("/lean/lockouts", (req, res) => {
  // Token-gated, with the same brute-force enforcement as the rebuild
  // endpoints (bad-token attempts here count toward the per-IP lockout,
  // and a locked IP gets 429 here too). Operators on a shared/locked IP
  // must wait out the 15-minute lockout like everyone else — we will not
  // weaken the limiter to make admin access more convenient.
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ error: auth.error });
    return;
  }
  const snap = snapshotLockouts();
  res.json({
    ...snap,
    maxFailedAttempts: MAX_FAILED_ATTEMPTS,
    lockoutMs: LOCKOUT_MS,
    failureWindowMs: FAILURE_WINDOW_MS,
  });
});

router.post("/lean/lockouts/clear", (req, res) => {
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ ok: false, error: auth.error });
    return;
  }
  const body = (req.body ?? {}) as { ip?: unknown };
  const ip = typeof body.ip === "string" ? body.ip.trim() : "";
  if (!ip) {
    res.status(400).json({ ok: false, error: "Missing required field `ip`." });
    return;
  }
  const existed = failuresByIp.delete(ip);
  req.log.warn(
    { clearedIp: ip, existed, clearedBy: getClientIp(req) },
    "Referee lockout cleared by operator",
  );
  res.json({
    ok: true,
    cleared: existed,
    message: existed
      ? `Cleared lockout/failure record for ${ip}.`
      : `No active lockout or failure record found for ${ip}.`,
  });
});

router.post("/lean/verify/rebuild/stream", (req, res) => {
  const start = Date.now();

  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ error: auth.error });
    return;
  }

  if (rebuildInFlight) {
    res.status(409).json({
      error:
        "A Lean rebuild is already in progress. Please wait for it to finish before triggering another.",
    });
    return;
  }

  const cooldown = checkRebuildCooldown();
  if (!cooldown.ok) {
    const retryAfterSec = Math.ceil(cooldown.retryAfterMs / 1000);
    res.setHeader("Retry-After", String(retryAfterSec));
    res.status(429).json({
      error: `Lean rebuilds are rate-limited. Please wait ${retryAfterSec}s before triggering another.`,
    });
    return;
  }

  if (!existsSync(REGENERATE_SCRIPT)) {
    req.log.error({ path: REGENERATE_SCRIPT }, "regenerate.sh not found");
    res.status(500).json({ error: `regenerate.sh not found at ${REGENERATE_SCRIPT}` });
    return;
  }

  res.status(200);
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache, no-transform");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders?.();

  const sendEvent = (event: string, data: unknown) => {
    if (res.writableEnded) return;
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  rebuildInFlight = true;
  cancelRequested = false;
  let child: ChildProcessWithoutNullStreams;
  try {
    child = spawn("bash", [REGENERATE_SCRIPT], {
      cwd: REPO_ROOT,
      env: process.env,
    });
    currentChild = child;
  } catch (err) {
    rebuildInFlight = false;
    currentChild = null;
    const message = err instanceof Error ? err.message : String(err);
    req.log.error({ err: message }, "Failed to spawn regenerate.sh");
    sendEvent("result", {
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: `Failed to spawn rebuild: ${message}`,
      verification: null,
    });
    res.end();
    return;
  }

  let stdout = "";
  let stderr = "";
  let stdoutBuf = "";
  let stderrBuf = "";
  let timedOut = false;

  const pushLines = (stream: "stdout" | "stderr", buf: string): string => {
    let remainder = buf;
    let idx: number;
    while ((idx = remainder.indexOf("\n")) !== -1) {
      const line = remainder.slice(0, idx).replace(/\r$/, "");
      remainder = remainder.slice(idx + 1);
      sendEvent("line", { stream, line });
    }
    return remainder;
  };

  child.stdout.on("data", (chunk: Buffer) => {
    const text = chunk.toString("utf8");
    stdout += text;
    stdoutBuf = pushLines("stdout", stdoutBuf + text);
  });
  child.stderr.on("data", (chunk: Buffer) => {
    const text = chunk.toString("utf8");
    stderr += text;
    stderrBuf = pushLines("stderr", stderrBuf + text);
  });

  const heartbeat = setInterval(() => {
    if (!res.writableEnded) res.write(`: keepalive\n\n`);
  }, 15000);

  const timer = setTimeout(() => {
    timedOut = true;
    child.kill("SIGKILL");
  }, REBUILD_TIMEOUT_MS);

  req.on("close", () => {
    // Client disconnected — let the rebuild keep running so the next caller
    // sees the result; just stop writing.
  });

  let responded = false;
  const finish = (payload: { ok: boolean; exitCode: number; error: string | null }) => {
    if (responded) return;
    responded = true;
    clearTimeout(timer);
    clearInterval(heartbeat);
    rebuildInFlight = false;
    currentChild = null;
    lastRebuildFinishedAt = Date.now();

    // Flush trailing partial lines
    if (stdoutBuf.length > 0) {
      sendEvent("line", { stream: "stdout", line: stdoutBuf.replace(/\r$/, "") });
      stdoutBuf = "";
    }
    if (stderrBuf.length > 0) {
      sendEvent("line", { stream: "stderr", line: stderrBuf.replace(/\r$/, "") });
      stderrBuf = "";
    }

    const durationMs = Date.now() - start;
    invalidateCache();
    let verification: (ParsedVerification & { ageDays: number }) | null = null;
    if (payload.ok) {
      const parsed = readVerification();
      if (parsed) {
        cached = parsed;
        const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
        verification = { ...parsed, ageDays: ageMs / (1000 * 60 * 60 * 24) };
      }
    }

    req.log.info(
      {
        ok: payload.ok,
        exitCode: payload.exitCode,
        durationMs,
        error: payload.error,
        streamed: true,
        refereeName: auth.refereeName,
      },
      "Lean rebuild attempted",
    );

    void recordRebuildAttempt(
      {
        timestamp: new Date().toISOString(),
        durationMs,
        exitCode: payload.exitCode,
        ok: payload.ok,
        error: payload.error,
        streamed: true,
        refereeName: auth.refereeName,
      },
      req.log,
    );

    sendEvent("result", {
      ok: payload.ok,
      exitCode: payload.exitCode,
      stdout,
      stderr,
      durationMs,
      error: payload.error,
      verification,
    });
    res.end();
  };

  child.on("error", (err) => {
    const message = err instanceof Error ? err.message : String(err);
    finish({ ok: false, exitCode: -1, error: `Spawn error: ${message}` });
  });

  child.on("close", (code, signal) => {
    if (cancelRequested) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `Rebuild cancelled by referee (${signal ?? "SIGTERM"}). VERIFY.txt was NOT overwritten.`,
      });
      return;
    }
    if (timedOut) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `Rebuild timed out after ${REBUILD_TIMEOUT_MS / 1000}s and was killed (${signal ?? "SIGKILL"}).`,
      });
      return;
    }
    const exitCode = code ?? -1;
    if (exitCode === 0) {
      finish({ ok: true, exitCode, error: null });
      return;
    }
    let error: string;
    if (exitCode === 127) {
      error = "`lake` (Lean 4) is not installed in this environment, so the proof cannot be re-verified.";
    } else if (exitCode === 2) {
      error = "Axiom-debt check failed: the Lean proof has drifted. VERIFY.txt was NOT overwritten.";
    } else {
      error = `Rebuild script exited with code ${exitCode}.`;
    }
    finish({ ok: false, exitCode, error });
  });
});

router.post("/lean/verify/rebuild/cancel", (req, res) => {
  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({ ok: false, error: auth.error });
    return;
  }
  if (!rebuildInFlight || !currentChild) {
    res.status(409).json({
      ok: false,
      error: "No Lean rebuild is currently in flight.",
    });
    return;
  }
  cancelRequested = true;
  try {
    currentChild.kill("SIGTERM");
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    req.log.error({ err: message }, "Failed to signal in-flight rebuild");
    res.status(500).json({ ok: false, error: `Failed to signal rebuild: ${message}` });
    return;
  }
  req.log.info("Lean rebuild cancellation requested");
  res.status(200).json({ ok: true, message: "Cancellation signal sent to in-flight rebuild." });
});

router.post("/lean/verify/rebuild", (req, res) => {
  const start = Date.now();

  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
    applyAuthFailureHeaders(res, auth);
    res.status(auth.status).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: auth.error,
      verification: null,
    });
    return;
  }

  if (rebuildInFlight) {
    res.status(409).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: "A Lean rebuild is already in progress. Please wait for it to finish before triggering another.",
      verification: null,
    });
    return;
  }

  const cooldown = checkRebuildCooldown();
  if (!cooldown.ok) {
    const retryAfterSec = Math.ceil(cooldown.retryAfterMs / 1000);
    res.setHeader("Retry-After", String(retryAfterSec));
    res.status(429).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: `Lean rebuilds are rate-limited. Please wait ${retryAfterSec}s before triggering another.`,
      verification: null,
    });
    return;
  }

  if (!existsSync(REGENERATE_SCRIPT)) {
    req.log.error({ path: REGENERATE_SCRIPT }, "regenerate.sh not found");
    res.status(200).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: `regenerate.sh not found at ${REGENERATE_SCRIPT}`,
      verification: null,
    });
    return;
  }

  rebuildInFlight = true;
  cancelRequested = false;
  let child: ChildProcessWithoutNullStreams;
  try {
    child = spawn("bash", [REGENERATE_SCRIPT], {
      cwd: REPO_ROOT,
      env: process.env,
    });
    currentChild = child;
  } catch (err) {
    rebuildInFlight = false;
    currentChild = null;
    const message = err instanceof Error ? err.message : String(err);
    req.log.error({ err: message }, "Failed to spawn regenerate.sh");
    res.status(200).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: `Failed to spawn rebuild: ${message}`,
      verification: null,
    });
    return;
  }

  let stdout = "";
  let stderr = "";
  let timedOut = false;

  child.stdout.on("data", (chunk: Buffer) => {
    stdout += chunk.toString("utf8");
  });
  child.stderr.on("data", (chunk: Buffer) => {
    stderr += chunk.toString("utf8");
  });

  const timer = setTimeout(() => {
    timedOut = true;
    child.kill("SIGKILL");
  }, REBUILD_TIMEOUT_MS);

  let responded = false;
  const finish = (
    payload: {
      ok: boolean;
      exitCode: number;
      error: string | null;
    },
  ) => {
    if (responded) return;
    responded = true;
    clearTimeout(timer);
    rebuildInFlight = false;
    currentChild = null;
    lastRebuildFinishedAt = Date.now();
    const durationMs = Date.now() - start;

    invalidateCache();
    let verification: (ParsedVerification & { ageDays: number }) | null = null;
    if (payload.ok) {
      const parsed = readVerification();
      if (parsed) {
        cached = parsed;
        const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
        verification = { ...parsed, ageDays: ageMs / (1000 * 60 * 60 * 24) };
      }
    }

    req.log.info(
      {
        ok: payload.ok,
        exitCode: payload.exitCode,
        durationMs,
        error: payload.error,
        refereeName: auth.refereeName,
      },
      "Lean rebuild attempted",
    );

    void recordRebuildAttempt(
      {
        timestamp: new Date().toISOString(),
        durationMs,
        exitCode: payload.exitCode,
        ok: payload.ok,
        error: payload.error,
        streamed: false,
        refereeName: auth.refereeName,
      },
      req.log,
    );

    res.status(200).json({
      ok: payload.ok,
      exitCode: payload.exitCode,
      stdout,
      stderr,
      durationMs,
      error: payload.error,
      verification,
    });
  };

  child.on("error", (err) => {
    const message = err instanceof Error ? err.message : String(err);
    finish({ ok: false, exitCode: -1, error: `Spawn error: ${message}` });
  });

  child.on("close", (code, signal) => {
    if (cancelRequested) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `Rebuild cancelled by referee (${signal ?? "SIGTERM"}). VERIFY.txt was NOT overwritten.`,
      });
      return;
    }
    if (timedOut) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `Rebuild timed out after ${REBUILD_TIMEOUT_MS / 1000}s and was killed (${signal ?? "SIGKILL"}).`,
      });
      return;
    }
    const exitCode = code ?? -1;
    if (exitCode === 0) {
      finish({ ok: true, exitCode, error: null });
      return;
    }
    let error: string;
    if (exitCode === 127) {
      error = "`lake` (Lean 4) is not installed in this environment, so the proof cannot be re-verified.";
    } else if (exitCode === 2) {
      error = "Axiom-debt check failed: the Lean proof has drifted. VERIFY.txt was NOT overwritten.";
    } else {
      error = `Rebuild script exited with code ${exitCode}.`;
    }
    finish({ ok: false, exitCode, error });
  });
});

export default router;

export const __testing = {
  checkRebuildAuth,
  sanitizeRefereeName,
  getNamedTokens,
  resetAuthState(): void {
    failuresByIp.clear();
    namedTokensCache = { raw: undefined, tokens: [] };
  },
  resetRebuildState(): void {
    rebuildInFlight = false;
    currentChild = null;
    cancelRequested = false;
    lastRebuildFinishedAt = 0;
    cached = null;
    cachedError = null;
  },
  setAlertsLogPath(p: string | null): void {
    ALERTS_LOG_PATH = p ?? path.join(REPO_ROOT, "data", "ledger-alerts.jsonl");
  },
  setAlertsAckPath(p: string | null): void {
    ALERTS_ACK_PATH = p ?? path.join(REPO_ROOT, "data", "ledger-alerts.ack.json");
  },
  setRerollSpawner(fn: RerollSpawner | null): void {
    rerollSpawner = fn ?? defaultRerollSpawner;
  },
  resetCheckpointRerollState(): void {
    checkpointRerollInFlight = false;
  },
  normalizeAlertEntry,
};
