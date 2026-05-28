import { and, desc, gte } from "drizzle-orm";
import type { Logger } from "pino";
import { db, ledgerCheckpointRerollHistoryTable } from "@workspace/db";
import type { LedgerAlertSink } from "./ledgerAlerts.js";

export interface RerollDigestRow {
  timestamp: string;
  durationMs: number;
  exitCode: number;
  ok: boolean;
  error: string | null;
  refereeName: string | null;
  ip: string | null;
}

export interface RerollDigestPerReferee {
  refereeName: string;
  okCount: number;
  failCount: number;
}

export interface RerollDigest {
  windowHours: number;
  windowStart: string;
  windowEnd: string;
  totalAttempts: number;
  okCount: number;
  failCount: number;
  perReferee: RerollDigestPerReferee[];
  failures: RerollDigestRow[];
  text: string;
}

const ANON_REFEREE = "(unnamed)";

/**
 * Task #176: build the human-readable digest body. Groups by referee
 * (ok/fail counts), then lists every failing row so an unexpected
 * referee or a spike of failed re-rolls jumps out of the email
 * without anyone watching the dashboard live.
 */
export function buildRerollDigest(
  rows: RerollDigestRow[],
  windowHours: number,
  now: Date = new Date(),
): RerollDigest {
  const windowEnd = now.toISOString();
  const windowStart = new Date(
    now.getTime() - windowHours * 60 * 60 * 1000,
  ).toISOString();
  const byReferee = new Map<string, RerollDigestPerReferee>();
  let okCount = 0;
  let failCount = 0;
  const failures: RerollDigestRow[] = [];
  for (const r of rows) {
    const ref =
      r.refereeName && r.refereeName.length > 0 ? r.refereeName : ANON_REFEREE;
    let bucket = byReferee.get(ref);
    if (!bucket) {
      bucket = { refereeName: ref, okCount: 0, failCount: 0 };
      byReferee.set(ref, bucket);
    }
    if (r.ok) {
      bucket.okCount += 1;
      okCount += 1;
    } else {
      bucket.failCount += 1;
      failCount += 1;
      failures.push(r);
    }
  }
  const perReferee = Array.from(byReferee.values()).sort((a, b) => {
    if (b.failCount !== a.failCount) return b.failCount - a.failCount;
    if (b.okCount !== a.okCount) return b.okCount - a.okCount;
    return a.refereeName.localeCompare(b.refereeName);
  });

  const lines: string[] = [];
  lines.push(
    `Window: ${windowStart} → ${windowEnd} (${windowHours}h)`,
    `Total attempts: ${rows.length} (ok=${okCount}, fail=${failCount})`,
    "",
    "By referee:",
  );
  if (perReferee.length === 0) {
    lines.push("  (no checkpoint re-roll attempts in this window)");
  } else {
    for (const p of perReferee) {
      lines.push(
        `  - ${p.refereeName}: ok=${p.okCount}, fail=${p.failCount}`,
      );
    }
  }
  lines.push("", "Failures:");
  if (failures.length === 0) {
    lines.push("  (none)");
  } else {
    for (const f of failures) {
      const ref =
        f.refereeName && f.refereeName.length > 0
          ? f.refereeName
          : ANON_REFEREE;
      const ip = f.ip ?? "?";
      const err = f.error ? f.error.replace(/\s+/g, " ").slice(0, 200) : "";
      lines.push(
        `  - ${f.timestamp} referee=${ref} ip=${ip} exit=${f.exitCode}${
          err ? ` err="${err}"` : ""
        }`,
      );
    }
  }

  return {
    windowHours,
    windowStart,
    windowEnd,
    totalAttempts: rows.length,
    okCount,
    failCount,
    perReferee,
    failures,
    text: lines.join("\n"),
  };
}

/**
 * Task #176: fetch every reroll-history row from the last
 * `windowHours` hours (no capacity cap — the digest must reflect the
 * full window, not just the last N kept by the ring buffer).
 */
export async function fetchRerollRowsSince(
  windowHours: number,
  now: Date = new Date(),
): Promise<RerollDigestRow[]> {
  const since = new Date(now.getTime() - windowHours * 60 * 60 * 1000);
  const rows = await db
    .select()
    .from(ledgerCheckpointRerollHistoryTable)
    .where(
      and(gte(ledgerCheckpointRerollHistoryTable.timestamp, since)),
    )
    .orderBy(desc(ledgerCheckpointRerollHistoryTable.id));
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

export interface RerollDigestRunOptions {
  windowHours: number;
  sink: LedgerAlertSink;
  logger: Pick<Logger, "info" | "warn" | "error">;
  fetchRows?: (
    windowHours: number,
    now: Date,
  ) => Promise<RerollDigestRow[]>;
  now?: () => Date;
  skipWhenEmpty?: boolean;
}

/**
 * Build and dispatch one digest. Returns the digest object so tests
 * can assert on it; swallows sink failures (best-effort observability,
 * same posture as `_fire_ledger_alert` on the Python side).
 */
export async function runRerollDigestOnce(
  opts: RerollDigestRunOptions,
): Promise<RerollDigest | null> {
  const now = (opts.now ?? (() => new Date()))();
  const fetcher = opts.fetchRows ?? fetchRerollRowsSince;
  let rows: RerollDigestRow[];
  try {
    rows = await fetcher(opts.windowHours, now);
  } catch (err) {
    opts.logger.error(
      { err },
      "reroll digest: failed to read history table",
    );
    return null;
  }
  if (opts.skipWhenEmpty !== false && rows.length === 0) {
    opts.logger.info(
      { windowHours: opts.windowHours },
      "reroll digest: skipped (no attempts in window)",
    );
    return null;
  }
  const digest = buildRerollDigest(rows, opts.windowHours, now);
  const message = `Checkpoint re-roll digest: ${digest.totalAttempts} attempts (ok=${digest.okCount}, fail=${digest.failCount}) over the last ${digest.windowHours}h.`;
  try {
    await opts.sink({
      kind: "alert",
      message,
      context: {
        failure_mode: "reroll_digest",
        checked_at: now.toISOString(),
        source: "rerollDigest",
        window_hours: digest.windowHours,
        window_start: digest.windowStart,
        window_end: digest.windowEnd,
        total_attempts: digest.totalAttempts,
        ok_count: digest.okCount,
        fail_count: digest.failCount,
        per_referee: digest.perReferee,
        failures: digest.failures,
        digest_text: digest.text,
      },
    });
    opts.logger.info(
      {
        windowHours: digest.windowHours,
        totalAttempts: digest.totalAttempts,
        okCount: digest.okCount,
        failCount: digest.failCount,
      },
      "reroll digest: dispatched",
    );
  } catch (err) {
    opts.logger.warn(
      { err },
      "reroll digest: sink dispatch failed (swallowed)",
    );
  }
  return digest;
}

export interface RerollDigestScheduler {
  stop(): void;
  runNow(): Promise<RerollDigest | null>;
}

export interface RerollDigestSchedulerOptions extends RerollDigestRunOptions {
  intervalMs: number;
}

/**
 * Spin up the daily digest timer. Cadence is driven by `intervalMs`
 * and the digest window matches that cadence (so a 24h interval
 * digests the last 24h, a 12h interval digests the last 12h, etc.).
 */
export function startRerollDigestScheduler(
  opts: RerollDigestSchedulerOptions,
): RerollDigestScheduler {
  let stopped = false;
  let running = false;
  const tick = async (): Promise<RerollDigest | null> => {
    if (stopped || running) return null;
    running = true;
    try {
      return await runRerollDigestOnce(opts);
    } finally {
      running = false;
    }
  };
  const handle = setInterval(() => {
    void tick();
  }, opts.intervalMs);
  handle.unref?.();
  return {
    stop() {
      stopped = true;
      clearInterval(handle);
    },
    runNow: tick,
  };
}

const DEFAULT_DIGEST_INTERVAL_SECONDS = 24 * 60 * 60;

/**
 * Parse `MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS`. Default 86400
 * (24h). `off`/`0`/`disabled`/`none` disables the scheduler. Bad
 * values fall back to the default — same posture as the existing
 * `LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS` parser.
 */
export function resolveRerollDigestIntervalSeconds(
  raw: string | undefined,
): number | null {
  if (raw == null) return DEFAULT_DIGEST_INTERVAL_SECONDS;
  const trimmed = raw.trim();
  if (trimmed === "") return DEFAULT_DIGEST_INTERVAL_SECONDS;
  if (/^(off|disabled?|none|0)$/i.test(trimmed)) return null;
  const n = Number(trimmed);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_DIGEST_INTERVAL_SECONDS;
  return Math.floor(n);
}
