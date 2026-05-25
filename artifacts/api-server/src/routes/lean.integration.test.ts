import {
  describe,
  it,
  expect,
  beforeEach,
  afterEach,
  beforeAll,
  afterAll,
  vi,
} from "vitest";
import { EventEmitter } from "node:events";
import http from "node:http";
import type { AddressInfo } from "node:net";

const insertedRows: Array<Record<string, unknown>> = [];
let selectOffsetResult: Array<{ id: number }> = [];

vi.mock("@workspace/db", () => {
  const insertChain = {
    values: vi.fn(async (v: Record<string, unknown>) => {
      insertedRows.push(v);
    }),
  };
  const selectChain = {
    from: () => ({
      orderBy: () => ({
        limit: () => ({
          offset: async () => selectOffsetResult,
        }),
      }),
    }),
  };
  const deleteChain = {
    where: async () => undefined,
  };
  return {
    db: {
      insert: vi.fn(() => insertChain),
      select: vi.fn(() => selectChain),
      delete: vi.fn(() => deleteChain),
    },
    leanRebuildHistoryTable: { id: Symbol("id") },
  };
});

class FakeChild extends EventEmitter {
  stdout = new EventEmitter();
  stderr = new EventEmitter();
  kill = vi.fn();
}

let lastSpawnedChild: FakeChild | null = null;
let spawnHandler: ((c: FakeChild) => void) | null = null;

vi.mock("node:child_process", () => ({
  spawn: vi.fn(() => {
    const c = new FakeChild();
    lastSpawnedChild = c;
    queueMicrotask(() => spawnHandler?.(c));
    return c;
  }),
}));

vi.mock("node:fs", async (orig) => {
  const actual = (await orig()) as typeof import("node:fs");
  return {
    ...actual,
    default: actual,
    existsSync: (p: import("node:fs").PathLike) => {
      const s = String(p);
      if (s.endsWith("regenerate.sh") || s.endsWith("VERIFY.txt")) return true;
      return actual.existsSync(p);
    },
    readFileSync: ((p: import("node:fs").PathOrFileDescriptor, ...rest: unknown[]) => {
      const s = String(p);
      if (s.endsWith("VERIFY.txt")) {
        return "Lean toolchain : leanprover/lean4:v4.12.0\nDate verified : 2026-05-25\nAxiom debt = []\n";
      }
      return (actual.readFileSync as Function)(p, ...rest);
    }) as typeof actual.readFileSync,
    statSync: ((p: import("node:fs").PathLike) => {
      const s = String(p);
      if (s.endsWith("VERIFY.txt")) {
        return { mtime: new Date("2026-05-25T00:00:00Z") } as unknown as ReturnType<
          typeof actual.statSync
        >;
      }
      return actual.statSync(p);
    }) as typeof actual.statSync,
  };
});

const { default: express } = await import("express");
const { default: leanRouter, __testing } = await import("./lean.js");

const ORIGINAL_ENV = { ...process.env };

function buildApp() {
  const app = express();
  app.use(express.json());
  // Inject a test IP override and a minimal req.log shim.
  app.use((req, _res, next) => {
    const ipHeader = req.headers["x-test-ip"];
    const ip = Array.isArray(ipHeader) ? ipHeader[0] : ipHeader;
    if (ip) {
      Object.defineProperty(req, "ip", { value: ip, configurable: true });
    }
    (req as unknown as { log: unknown }).log = {
      info: () => {},
      warn: () => {},
      error: () => {},
    };
    next();
  });
  app.use("/api", leanRouter);
  return app;
}

let server: http.Server;
let baseUrl: string;

beforeAll(async () => {
  const app = buildApp();
  server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const addr = server.address() as AddressInfo;
  baseUrl = `http://127.0.0.1:${addr.port}`;
});

afterAll(async () => {
  await new Promise<void>((resolve, reject) =>
    server.close((err) => (err ? reject(err) : resolve())),
  );
});

beforeEach(() => {
  delete process.env["LEAN_REBUILD_TOKEN"];
  delete process.env["LEAN_REBUILD_TOKENS"];
  insertedRows.length = 0;
  selectOffsetResult = [];
  spawnHandler = null;
  lastSpawnedChild = null;
  __testing.resetAuthState();
  __testing.resetRebuildState();
});

afterEach(() => {
  process.env = { ...ORIGINAL_ENV };
  __testing.resetAuthState();
  __testing.resetRebuildState();
});

interface CallOpts {
  method?: "GET" | "POST";
  path: string;
  ip?: string;
  authorization?: string;
  refereeName?: string;
  body?: unknown;
}

async function call(opts: CallOpts): Promise<{
  status: number;
  headers: Headers;
  json: any;
  text: string;
}> {
  const headers: Record<string, string> = {
    "x-test-ip": opts.ip ?? "10.0.0.1",
  };
  if (opts.authorization) headers["authorization"] = opts.authorization;
  if (opts.refereeName !== undefined) headers["x-referee-name"] = opts.refereeName;
  if (opts.body !== undefined) headers["content-type"] = "application/json";
  const res = await fetch(`${baseUrl}${opts.path}`, {
    method: opts.method ?? "GET",
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    /* not json */
  }
  return { status: res.status, headers: res.headers, json, text };
}

describe("POST /api/lean/verify/rebuild — auth & error envelopes", () => {
  it("returns 503 when neither token env var is set", async () => {
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer anything",
    });
    expect(r.status).toBe(503);
    expect(r.json.ok).toBe(false);
    expect(r.json.error).toMatch(/disabled/i);
    expect(r.json.verification).toBeNull();
    expect(r.headers.get("retry-after")).toBeNull();
    expect(insertedRows).toHaveLength(0);
  });

  it("returns 401 with no Retry-After when the bearer token is wrong", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer nope",
    });
    expect(r.status).toBe(401);
    expect(r.json.ok).toBe(false);
    expect(r.json.exitCode).toBe(-1);
    expect(r.headers.get("retry-after")).toBeNull();
    expect(insertedRows).toHaveLength(0);
  });

  it("returns 429 with a Retry-After header after 5 bad-token attempts", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    for (let i = 0; i < 5; i++) {
      const r = await call({
        method: "POST",
        path: "/api/lean/verify/rebuild",
        ip: "9.9.9.9",
        authorization: "Bearer wrong",
      });
      expect(r.status).toBe(401);
    }
    const blocked = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      ip: "9.9.9.9",
      authorization: "Bearer shared",
    });
    expect(blocked.status).toBe(429);
    const retryAfter = blocked.headers.get("retry-after");
    expect(retryAfter).not.toBeNull();
    expect(Number(retryAfter)).toBeGreaterThan(0);
  });
});

describe("POST /api/lean/verify/rebuild — success path", () => {
  it("persists a leanRebuildHistoryTable row with the named-token referee name", async () => {
    process.env["LEAN_REBUILD_TOKENS"] = "alice:tokA";
    spawnHandler = (child) => {
      child.stdout.emit("data", Buffer.from("rebuilt ok\n"));
      child.emit("close", 0, null);
    };

    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer tokA",
      refereeName: "mallory",
    });

    expect(r.status).toBe(200);
    expect(r.json.ok).toBe(true);
    expect(r.json.exitCode).toBe(0);
    expect(r.json.stdout).toContain("rebuilt ok");
    expect(r.json.verification).not.toBeNull();
    expect(r.json.verification.axiomDebt).toEqual([]);

    // Persisted row reflects the named token, not the spoofed header.
    expect(insertedRows).toHaveLength(1);
    expect(insertedRows[0]).toMatchObject({
      ok: true,
      exitCode: 0,
      streamed: false,
      refereeName: "alice",
    });
    expect(insertedRows[0].error).toBeNull();
    expect(typeof insertedRows[0].durationMs).toBe("number");
    expect(insertedRows[0].timestamp).toBeInstanceOf(Date);
  });

  it("records refereeName=null (anonymous) when shared token is used without a header", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    spawnHandler = (child) => {
      child.emit("close", 0, null);
    };
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer shared",
    });
    expect(r.status).toBe(200);
    expect(r.json.ok).toBe(true);
    expect(insertedRows).toHaveLength(1);
    expect(insertedRows[0].refereeName).toBeNull();
  });

  it("returns the right error envelope when the rebuild script exits non-zero", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    spawnHandler = (child) => {
      child.stderr.emit("data", Buffer.from("drift!\n"));
      child.emit("close", 2, null);
    };
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer shared",
    });
    expect(r.status).toBe(200);
    expect(r.json.ok).toBe(false);
    expect(r.json.exitCode).toBe(2);
    expect(r.json.error).toMatch(/drifted/i);
    expect(r.json.verification).toBeNull();
    expect(insertedRows).toHaveLength(1);
    expect(insertedRows[0]).toMatchObject({ ok: false, exitCode: 2 });
  });
});

describe("GET /api/lean/lockouts — auth & shared limiter", () => {
  it("returns 503 when no token is configured", async () => {
    const r = await call({ path: "/api/lean/lockouts" });
    expect(r.status).toBe(503);
  });

  it("returns 401 with a wrong token", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      path: "/api/lean/lockouts",
      authorization: "Bearer wrong",
    });
    expect(r.status).toBe(401);
  });

  it("returns a snapshot for a valid token, including a failing IP that has not been locked yet", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    // Two bad attempts from one IP — should appear under failingIps, not active lockouts.
    for (let i = 0; i < 2; i++) {
      await call({
        path: "/api/lean/verify/rebuild",
        method: "POST",
        ip: "4.4.4.4",
        authorization: "Bearer wrong",
      });
    }
    const r = await call({
      path: "/api/lean/lockouts",
      ip: "1.1.1.1",
      authorization: "Bearer shared",
    });
    expect(r.status).toBe(200);
    expect(r.json.maxFailedAttempts).toBe(5);
    expect(r.json.activeLockouts).toEqual([]);
    expect(r.json.failingIps).toHaveLength(1);
    expect(r.json.failingIps[0].ip).toBe("4.4.4.4");
    expect(r.json.failingIps[0].failedAttempts).toBe(2);
  });

  it("shares the per-IP brute-force limiter (bad-token attempts on /lockouts count toward lockout, and a locked IP gets 429)", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    // 5 bad-token GETs from the same IP should trip the lockout for that IP.
    for (let i = 0; i < 5; i++) {
      const r = await call({
        path: "/api/lean/lockouts",
        ip: "7.7.7.7",
        authorization: "Bearer wrong",
      });
      expect(r.status).toBe(401);
    }
    // Even a valid token from the locked IP now gets 429 with Retry-After.
    const blocked = await call({
      path: "/api/lean/lockouts",
      ip: "7.7.7.7",
      authorization: "Bearer shared",
    });
    expect(blocked.status).toBe(429);
    expect(Number(blocked.headers.get("retry-after"))).toBeGreaterThan(0);
  });

  it("hides the failing IP after the operator clears it", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    await call({
      path: "/api/lean/verify/rebuild",
      method: "POST",
      ip: "8.8.8.8",
      authorization: "Bearer wrong",
    });
    let snap = await call({
      path: "/api/lean/lockouts",
      ip: "1.1.1.1",
      authorization: "Bearer shared",
    });
    expect(snap.json.failingIps.map((f: any) => f.ip)).toContain("8.8.8.8");

    const cleared = await call({
      method: "POST",
      path: "/api/lean/lockouts/clear",
      ip: "1.1.1.1",
      authorization: "Bearer shared",
      body: { ip: "8.8.8.8" },
    });
    expect(cleared.status).toBe(200);
    expect(cleared.json).toMatchObject({ ok: true, cleared: true });

    snap = await call({
      path: "/api/lean/lockouts",
      ip: "1.1.1.1",
      authorization: "Bearer shared",
    });
    expect(snap.json.failingIps).toEqual([]);
  });
});

describe("POST /api/lean/lockouts/clear", () => {
  it("returns 503 when no token is configured", async () => {
    const r = await call({
      method: "POST",
      path: "/api/lean/lockouts/clear",
      body: { ip: "1.2.3.4" },
    });
    expect(r.status).toBe(503);
  });

  it("returns 400 when the body is missing `ip`", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      method: "POST",
      path: "/api/lean/lockouts/clear",
      authorization: "Bearer shared",
      body: {},
    });
    expect(r.status).toBe(400);
    expect(r.json).toMatchObject({ ok: false });
    expect(r.json.error).toMatch(/ip/i);
  });

  it("reports cleared=false when no record exists", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      method: "POST",
      path: "/api/lean/lockouts/clear",
      authorization: "Bearer shared",
      body: { ip: "203.0.113.1" },
    });
    expect(r.status).toBe(200);
    expect(r.json).toMatchObject({ ok: true, cleared: false });
  });

  it("shares the per-IP brute-force limiter (bad token counts toward lockout)", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    for (let i = 0; i < 5; i++) {
      const r = await call({
        method: "POST",
        path: "/api/lean/lockouts/clear",
        ip: "6.6.6.6",
        authorization: "Bearer wrong",
        body: { ip: "x" },
      });
      expect(r.status).toBe(401);
    }
    const blocked = await call({
      method: "POST",
      path: "/api/lean/lockouts/clear",
      ip: "6.6.6.6",
      authorization: "Bearer shared",
      body: { ip: "x" },
    });
    expect(blocked.status).toBe(429);
    expect(Number(blocked.headers.get("retry-after"))).toBeGreaterThan(0);
  });
});

interface SseEvent {
  event: string;
  data: any;
}

async function consumeSse(res: Response): Promise<SseEvent[]> {
  if (!res.body) return [];
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = "";
  const events: SseEvent[] = [];
  for (;;) {
    const { value, done } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });
    let idx: number;
    while ((idx = buf.indexOf("\n\n")) !== -1) {
      const raw = buf.slice(0, idx);
      buf = buf.slice(idx + 2);
      const lines = raw.split("\n").filter((l) => !l.startsWith(":"));
      let evName = "message";
      let data = "";
      for (const l of lines) {
        if (l.startsWith("event:")) evName = l.slice(6).trim();
        else if (l.startsWith("data:")) data += l.slice(5).trim();
      }
      if (data) {
        let parsed: any = data;
        try {
          parsed = JSON.parse(data);
        } catch {
          /* leave as string */
        }
        events.push({ event: evName, data: parsed });
      }
    }
  }
  return events;
}

async function openStream(opts: {
  ip?: string;
  authorization?: string;
  refereeName?: string;
}): Promise<Response> {
  const headers: Record<string, string> = {
    "x-test-ip": opts.ip ?? "10.0.0.1",
  };
  if (opts.authorization) headers["authorization"] = opts.authorization;
  if (opts.refereeName !== undefined) headers["x-referee-name"] = opts.refereeName;
  return fetch(`${baseUrl}/api/lean/verify/rebuild/stream`, {
    method: "POST",
    headers,
  });
}

describe("POST /api/lean/verify/rebuild/stream — auth & error envelopes", () => {
  it("returns 503 JSON when no token is configured", async () => {
    const res = await openStream({ authorization: "Bearer x" });
    expect(res.status).toBe(503);
    expect(res.headers.get("content-type")).toMatch(/json/);
    const body = await res.json();
    expect(body.error).toMatch(/disabled/i);
    expect(res.headers.get("retry-after")).toBeNull();
    expect(insertedRows).toHaveLength(0);
  });

  it("returns 401 JSON on a wrong bearer token (no Retry-After) with the same envelope as the JSON endpoint", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const res = await openStream({ authorization: "Bearer nope" });
    expect(res.status).toBe(401);
    expect(res.headers.get("retry-after")).toBeNull();
    expect(res.headers.get("content-type")).toMatch(/json/);
    const body = await res.json();
    expect(body.error).toMatch(/invalid|unauthor/i);

    // Parity check: JSON endpoint returns the same `error` shape on a wrong token.
    const jsonRes = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer nope",
    });
    expect(jsonRes.status).toBe(401);
    expect(jsonRes.json.error).toBe(body.error);
    expect(insertedRows).toHaveLength(0);
  });

  it("returns 429 + Retry-After after 5 bad-token attempts with the same envelope as the JSON endpoint", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    for (let i = 0; i < 5; i++) {
      const r = await openStream({ ip: "3.3.3.3", authorization: "Bearer wrong" });
      expect(r.status).toBe(401);
      await r.body?.cancel();
    }
    const blocked = await openStream({ ip: "3.3.3.3", authorization: "Bearer shared" });
    expect(blocked.status).toBe(429);
    expect(blocked.headers.get("content-type")).toMatch(/json/);
    const blockedRetryAfter = Number(blocked.headers.get("retry-after"));
    expect(blockedRetryAfter).toBeGreaterThan(0);
    const blockedBody = await blocked.json();
    expect(blockedBody.error).toMatch(/too many|locked|wait/i);

    // Parity check: JSON endpoint sees the same locked-out IP and returns the same envelope shape.
    const jsonBlocked = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      ip: "3.3.3.3",
      authorization: "Bearer shared",
    });
    expect(jsonBlocked.status).toBe(429);
    expect(Number(jsonBlocked.headers.get("retry-after"))).toBeGreaterThan(0);
    expect(typeof jsonBlocked.json.error).toBe("string");
    expect(jsonBlocked.json.error).toMatch(/too many|locked|wait/i);
  });

  it("streams a successful rebuild and persists a streamed=true history row with the named-token referee", async () => {
    process.env["LEAN_REBUILD_TOKENS"] = "alice:tokA";
    spawnHandler = (child) => {
      child.stdout.emit("data", Buffer.from("hello\nworld\n"));
      child.stderr.emit("data", Buffer.from("warn: foo\n"));
      child.emit("close", 0, null);
    };
    const res = await openStream({
      authorization: "Bearer tokA",
      refereeName: "mallory",
    });
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toMatch(/event-stream/);
    const events = await consumeSse(res);
    const lines = events.filter((e) => e.event === "line");
    const result = events.find((e) => e.event === "result");
    expect(lines.length).toBeGreaterThanOrEqual(3);
    expect(lines.some((l) => l.data.stream === "stdout" && l.data.line === "hello")).toBe(true);
    expect(lines.some((l) => l.data.stream === "stderr" && l.data.line === "warn: foo")).toBe(true);
    expect(result).toBeTruthy();
    expect(result!.data.ok).toBe(true);
    expect(result!.data.exitCode).toBe(0);
    expect(result!.data.stdout).toContain("hello");
    expect(result!.data.stdout).toContain("world");
    expect(typeof result!.data.stderr).toBe("string");
    expect(result!.data.stderr).toContain("warn: foo");
    expect(result!.data.verification).not.toBeNull();
    expect(insertedRows).toHaveLength(1);
    expect(insertedRows[0]).toMatchObject({
      ok: true,
      exitCode: 0,
      streamed: true,
      refereeName: "alice",
    });
  });
});

describe("POST /api/lean/verify/rebuild/cancel — auth & in-flight behavior", () => {
  it("returns 503 when no token is configured", async () => {
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild/cancel",
    });
    expect(r.status).toBe(503);
    expect(r.json.ok).toBe(false);
  });

  it("returns 401 on a wrong bearer token", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild/cancel",
      authorization: "Bearer nope",
    });
    expect(r.status).toBe(401);
    expect(r.json.ok).toBe(false);
  });

  it("returns 429 + Retry-After after 5 bad-token attempts", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    for (let i = 0; i < 5; i++) {
      const r = await call({
        method: "POST",
        path: "/api/lean/verify/rebuild/cancel",
        ip: "2.2.2.2",
        authorization: "Bearer wrong",
      });
      expect(r.status).toBe(401);
    }
    const blocked = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild/cancel",
      ip: "2.2.2.2",
      authorization: "Bearer shared",
    });
    expect(blocked.status).toBe(429);
    expect(Number(blocked.headers.get("retry-after"))).toBeGreaterThan(0);
  });

  it("returns 409 when no rebuild is currently in flight", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    const r = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild/cancel",
      authorization: "Bearer shared",
    });
    expect(r.status).toBe(409);
    expect(r.json.ok).toBe(false);
    expect(r.json.error).toMatch(/no lean rebuild/i);
  });

  it("signals an in-flight stream and records a streamed cancellation", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    // Hold the child open until cancel() is called.
    let captured: FakeChild | null = null;
    spawnHandler = (child) => {
      captured = child;
      child.stdout.emit("data", Buffer.from("starting...\n"));
      // Simulate SIGTERM resulting in a close event.
      child.kill = vi.fn(() => {
        queueMicrotask(() => child.emit("close", null, "SIGTERM"));
        return true;
      });
    };

    const streamResPromise = openStream({ authorization: "Bearer shared" });
    const streamRes = await streamResPromise;
    expect(streamRes.status).toBe(200);

    // Wait until the rebuild is actually in-flight before cancelling.
    for (let i = 0; i < 50 && !captured; i++) {
      await new Promise((r) => setTimeout(r, 5));
    }
    expect(captured).not.toBeNull();

    const cancelRes = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild/cancel",
      authorization: "Bearer shared",
    });
    expect(cancelRes.status).toBe(200);
    expect(cancelRes.json).toMatchObject({ ok: true });
    expect((captured as unknown as FakeChild).kill).toHaveBeenCalledWith("SIGTERM");

    const events = await consumeSse(streamRes);
    const result = events.find((e) => e.event === "result");
    expect(result).toBeTruthy();
    expect(result!.data.ok).toBe(false);
    expect(result!.data.error).toMatch(/cancelled by referee/i);
    expect(result!.data.verification).toBeNull();

    expect(insertedRows).toHaveLength(1);
    expect(insertedRows[0]).toMatchObject({
      ok: false,
      streamed: true,
      refereeName: null,
    });
    expect(insertedRows[0].error).toMatch(/cancelled by referee/i);
  });
});

describe("rebuild cooldown surfaces Retry-After (429) even with a valid token", () => {
  it("rejects a second rebuild within the cooldown window", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    spawnHandler = (child) => {
      child.emit("close", 0, null);
    };
    const first = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer shared",
    });
    expect(first.status).toBe(200);
    expect(first.json.ok).toBe(true);

    const second = await call({
      method: "POST",
      path: "/api/lean/verify/rebuild",
      authorization: "Bearer shared",
    });
    expect(second.status).toBe(429);
    expect(Number(second.headers.get("retry-after"))).toBeGreaterThan(0);
    expect(second.json.error).toMatch(/rate-limited/i);
    // Only the first (successful) rebuild was persisted.
    expect(insertedRows).toHaveLength(1);
  });

  it("rejects a second streamed rebuild within the cooldown window (different IP, same token)", async () => {
    process.env["LEAN_REBUILD_TOKEN"] = "shared";
    spawnHandler = (child) => {
      child.stdout.emit("data", Buffer.from("done\n"));
      child.emit("close", 0, null);
    };
    const first = await openStream({
      ip: "11.11.11.11",
      authorization: "Bearer shared",
    });
    expect(first.status).toBe(200);
    // Drain the first stream to completion so rebuildInFlight clears.
    const firstEvents = await consumeSse(first);
    expect(firstEvents.find((e) => e.event === "result")?.data.ok).toBe(true);
    expect(insertedRows).toHaveLength(1);

    const second = await openStream({
      ip: "12.12.12.12",
      authorization: "Bearer shared",
    });
    expect(second.status).toBe(429);
    expect(second.headers.get("content-type")).toMatch(/json/);
    const retryAfter = Number(second.headers.get("retry-after"));
    expect(retryAfter).toBeGreaterThan(0);
    const body = await second.json();
    expect(body.error).toMatch(/rate-limited/i);

    // No history row was inserted for the rejected second attempt.
    expect(insertedRows).toHaveLength(1);
  });
});
