import { describe, it, expect, vi } from "vitest";
import {
  buildRerollDigest,
  resolveRerollDigestIntervalSeconds,
  runRerollDigestOnce,
  type RerollDigestRow,
} from "./rerollDigest.js";

const NOW = new Date("2026-05-28T12:00:00Z");

function row(overrides: Partial<RerollDigestRow> = {}): RerollDigestRow {
  return {
    timestamp: "2026-05-28T10:00:00Z",
    durationMs: 1234,
    exitCode: 0,
    ok: true,
    error: null,
    refereeName: "alice",
    ip: "10.0.0.1",
    ...overrides,
  };
}

const stubLogger = {
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn(),
};

describe("buildRerollDigest", () => {
  it("groups by referee with ok/fail counts and sorts by fail-desc", () => {
    const rows: RerollDigestRow[] = [
      row({ refereeName: "alice", ok: true }),
      row({ refereeName: "alice", ok: false, exitCode: 1, error: "boom" }),
      row({ refereeName: "bob", ok: false, exitCode: 2, error: "kaboom" }),
      row({ refereeName: "bob", ok: false, exitCode: 2 }),
      row({ refereeName: null, ok: true }),
    ];
    const d = buildRerollDigest(rows, 24, NOW);
    expect(d.totalAttempts).toBe(5);
    expect(d.okCount).toBe(2);
    expect(d.failCount).toBe(3);
    expect(d.perReferee[0]).toEqual({
      refereeName: "bob",
      okCount: 0,
      failCount: 2,
    });
    expect(d.perReferee[1].refereeName).toBe("alice");
    expect(d.perReferee[2].refereeName).toBe("(unnamed)");
    expect(d.failures).toHaveLength(3);
    expect(d.text).toContain("By referee:");
    expect(d.text).toContain("- bob: ok=0, fail=2");
    expect(d.text).toContain('err="boom"');
  });

  it("emits a 'no attempts' line on empty input", () => {
    const d = buildRerollDigest([], 24, NOW);
    expect(d.totalAttempts).toBe(0);
    expect(d.text).toContain("(no checkpoint re-roll attempts in this window)");
    expect(d.text).toContain("Failures:\n  (none)");
  });

  it("collapses whitespace and caps error length in failure list", () => {
    const huge = "x".repeat(500);
    const d = buildRerollDigest(
      [row({ ok: false, error: `multi\nline   ${huge}` })],
      24,
      NOW,
    );
    const failureLine = d.text.split("\n").find((l) => l.includes("err="))!;
    expect(failureLine).toBeDefined();
    expect(failureLine.length).toBeLessThan(300);
    expect(failureLine).not.toContain("\n");
  });
});

describe("runRerollDigestOnce", () => {
  it("dispatches via the sink with reroll_digest failure_mode", async () => {
    const sink = vi.fn().mockResolvedValue(undefined);
    const rows = [row({ ok: true }), row({ ok: false, refereeName: "mallory" })];
    const result = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => rows,
    });
    expect(result).not.toBeNull();
    expect(sink).toHaveBeenCalledTimes(1);
    const inv = sink.mock.calls[0]![0];
    expect(inv.kind).toBe("alert");
    expect(inv.context.failure_mode).toBe("reroll_digest");
    expect(inv.context.window_hours).toBe(24);
    expect(inv.context.total_attempts).toBe(2);
    expect(inv.context.ok_count).toBe(1);
    expect(inv.context.fail_count).toBe(1);
    expect(typeof inv.context.digest_text).toBe("string");
    expect(inv.message).toContain("Checkpoint re-roll digest");
  });

  it("skips dispatch when the window has no attempts (default)", async () => {
    const sink = vi.fn();
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [],
    });
    expect(r).toBeNull();
    expect(sink).not.toHaveBeenCalled();
  });

  it("still dispatches an empty digest when skipWhenEmpty=false", async () => {
    const sink = vi.fn().mockResolvedValue(undefined);
    await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [],
      skipWhenEmpty: false,
    });
    expect(sink).toHaveBeenCalledTimes(1);
  });

  it("swallows sink failures so a flaky on-call sink can't crash the timer", async () => {
    const sink = vi.fn().mockRejectedValue(new Error("smtp down"));
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [row({ ok: false })],
    });
    expect(r).not.toBeNull();
  });
});

describe("resolveRerollDigestIntervalSeconds", () => {
  it("defaults to 86400 seconds (24h) when unset", () => {
    expect(resolveRerollDigestIntervalSeconds(undefined)).toBe(86400);
    expect(resolveRerollDigestIntervalSeconds("")).toBe(86400);
  });

  it("returns null for off/disabled/0/none (case-insensitive)", () => {
    for (const v of ["off", "Off", "DISABLED", "disable", "none", "0"]) {
      expect(resolveRerollDigestIntervalSeconds(v)).toBeNull();
    }
  });

  it("falls back to default on bad input", () => {
    expect(resolveRerollDigestIntervalSeconds("nonsense")).toBe(86400);
    expect(resolveRerollDigestIntervalSeconds("-5")).toBe(86400);
  });

  it("accepts positive numeric values", () => {
    expect(resolveRerollDigestIntervalSeconds("3600")).toBe(3600);
    expect(resolveRerollDigestIntervalSeconds("43200.7")).toBe(43200);
  });
});
