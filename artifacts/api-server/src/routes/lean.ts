import { Router, type IRouter } from "express";
import { existsSync, readFileSync, statSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";

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
  | { ok: true }
  | { ok: false; status: number; error: string };

function checkRebuildAuth(req: import("express").Request): RebuildAuthResult {
  const expectedToken = process.env["LEAN_REBUILD_TOKEN"];
  if (!expectedToken || expectedToken.length === 0) {
    req.log.warn("Rebuild blocked: LEAN_REBUILD_TOKEN not configured");
    return {
      ok: false,
      status: 503,
      error:
        "Lean rebuild is disabled on this server: LEAN_REBUILD_TOKEN is not configured. Set the secret to enable referee-driven rebuilds.",
    };
  }
  const provided = extractBearerToken(req.headers["authorization"]);
  if (!provided || !timingSafeEqual(provided, expectedToken)) {
    req.log.warn({ hasHeader: Boolean(provided) }, "Rebuild blocked: bad token");
    return {
      ok: false,
      status: 401,
      error:
        "Unauthorized: a valid referee rebuild token is required (Authorization: Bearer <token>).",
    };
  }
  return { ok: true };
}

router.post("/lean/verify/rebuild/stream", (req, res) => {
  const start = Date.now();

  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
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
  let child;
  try {
    child = spawn("bash", [REGENERATE_SCRIPT], {
      cwd: REPO_ROOT,
      env: process.env,
    });
  } catch (err) {
    rebuildInFlight = false;
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
      },
      "Lean rebuild attempted",
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

router.post("/lean/verify/rebuild", (req, res) => {
  const start = Date.now();

  const auth = checkRebuildAuth(req);
  if (!auth.ok) {
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
  let child;
  try {
    child = spawn("bash", [REGENERATE_SCRIPT], {
      cwd: REPO_ROOT,
      env: process.env,
    });
  } catch (err) {
    rebuildInFlight = false;
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
      },
      "Lean rebuild attempted",
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
