import { Router, type IRouter } from "express";
import { existsSync, readFileSync, statSync } from "node:fs";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import path from "node:path";
import { desc, lt } from "drizzle-orm";
import { db, leanRebuildHistoryTable } from "@workspace/db";

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
