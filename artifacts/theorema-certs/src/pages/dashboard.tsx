import {
  useGetCertificateSummary,
  useListCertificates,
  useGetLeanVerification,
  useGetLeanRebuildHistory,
  useGetLeanLockouts,
  useClearLeanLockout,
  useGetMorningstarHits,
  useGetLedgerIntegrity,
  useGetLedgerAlerts,
  useAckLedgerAlert,
  useAckSidecarForged,
  useAckSidecarStaleBinding,
  useRotateSidecarSecret,
  useRerollLedgerCheckpoint,
  useGetLedgerCheckpointRerollHistory,
  useGetLedgerCheckpointRerollDigest,
  getGetLedgerCheckpointRerollDigestQueryKey,
  GetLedgerCheckpointRerollDigestWindow,
  useGetSidecarForgedAckHistory,
  getGetSidecarForgedAckHistoryQueryKey,
  useGetSidecarStaleBindingAckHistory,
  getGetSidecarStaleBindingAckHistoryQueryKey,
  getGetMorningstarHitsQueryKey,
  getGetLeanVerificationQueryKey,
  getGetLeanRebuildHistoryQueryKey,
  getGetLeanLockoutsQueryKey,
  getGetLedgerIntegrityQueryKey,
  getGetLedgerAlertsQueryKey,
  getGetLedgerCheckpointRerollHistoryQueryKey,
} from "@workspace/api-client-react";
import type {
  LedgerAlertDeliveryStatus,
  RerollDigestBucket,
} from "@workspace/api-client-react";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { VerifyTxtDialog } from "@/components/verify-txt-dialog";
import { Card } from "@/components/ui/card";
import { Link } from "wouter";
import {
  CheckCircle2,
  ArrowRight,
  FileText,
  ShieldCheck,
  AlertTriangle,
  Clock,
  RefreshCw,
  XCircle,
  ShieldAlert,
  Ban,
  Activity,
} from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
const REBUILD_REFEREE_NAME_STORAGE_KEY = "lean-rebuild-referee-name";
const REBUILD_HISTORY_REFEREE_FILTER_STORAGE_KEY =
  "lean-rebuild-history-referee-filter";
const REROLL_HISTORY_REFEREE_FILTER_STORAGE_KEY =
  "lean-checkpoint-reroll-history-referee-filter";
const SIDECAR_FORGED_HISTORY_REFEREE_FILTER_STORAGE_KEY =
  "lean-sidecar-forged-history-referee-filter";
const SIDECAR_STALE_BINDING_HISTORY_REFEREE_FILTER_STORAGE_KEY =
  "lean-sidecar-stale-binding-history-referee-filter";
const LEDGER_ALERTS_KIND_FILTER_STORAGE_KEY =
  "lean-ledger-alerts-kind-filter";
type LedgerAlertsKindFilter = "all" | "tamper" | "monitor";
const isLedgerAlertsKindFilter = (
  v: string | null,
): v is LedgerAlertsKindFilter =>
  v === "all" || v === "tamper" || v === "monitor";
const REFEREE_NAME_PATTERN = /^[A-Za-z0-9 _.\-]{1,64}$/;

const STALE_THRESHOLD_DAYS = 30;
const REBUILD_COOLDOWN_MS = 60 * 1000;

function formatAge(ageDays: number | undefined): string {
  if (ageDays === undefined || Number.isNaN(ageDays)) return "unknown";
  if (ageDays < 1 / 24) return "just now";
  if (ageDays < 1) {
    const hours = Math.max(1, Math.round(ageDays * 24));
    return `${hours} hour${hours === 1 ? "" : "s"} ago`;
  }
  const days = Math.round(ageDays);
  return `${days} day${days === 1 ? "" : "s"} ago`;
}

function formatRelativeAge(iso: string | null | undefined, nowMs: number): string {
  if (!iso) return "never";
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return "unknown";
  const deltaSec = Math.max(0, Math.round((nowMs - t) / 1000));
  if (deltaSec < 5) return "just now";
  if (deltaSec < 60) return `${deltaSec}s ago`;
  const mins = Math.floor(deltaSec / 60);
  if (mins < 60) return `${mins} min${mins === 1 ? "" : "s"} ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} hour${hours === 1 ? "" : "s"} ago`;
  const days = Math.floor(hours / 24);
  return `${days} day${days === 1 ? "" : "s"} ago`;
}

function formatTimestamp(iso: string | undefined): string {
  if (!iso) return "unknown";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toISOString().replace("T", " ").replace(/\.\d+Z$/, "Z");
}

/**
 * Task #224: compact volume-over-time chart for the re-roll digest.
 * Each bucket is a vertical column; the column is split into a green
 * (ok) segment and a red (fail) segment stacked on top, sized against
 * the busiest bucket so a burst of activity (or a spike of failures)
 * visibly towers over the rest. Kept as a hand-rolled SVG to match the
 * dense font-mono panel aesthetic rather than the heavier recharts
 * container used elsewhere. Renders nothing meaningful (a flat
 * baseline) when the window is empty.
 */
function RerollDigestChart({
  buckets,
}: {
  buckets: RerollDigestBucket[];
}) {
  const maxAttempts = buckets.reduce(
    (m, b) => (b.attempts > m ? b.attempts : m),
    0,
  );
  const totalFailures = buckets.reduce((s, b) => s + b.failCount, 0);
  const count = buckets.length || 1;
  const gap = 1;
  const colWidth = (100 - gap * (count - 1)) / count;
  return (
    <div
      className="px-3 py-2 border-b border-border bg-muted/5"
      data-testid="chart-reroll-digest"
      data-bucket-count={buckets.length}
      data-max-attempts={maxAttempts}
    >
      <div className="flex items-center justify-between mb-1">
        <span className="font-mono text-[10px] uppercase tracking-wider text-muted-foreground">
          volume over time
        </span>
        <span className="font-mono text-[10px] text-muted-foreground">
          peak {maxAttempts}/bucket
        </span>
      </div>
      <svg
        viewBox="0 0 100 28"
        preserveAspectRatio="none"
        className="w-full h-12 overflow-visible"
        role="img"
        aria-label={`Re-roll volume across ${buckets.length} time buckets, peak ${maxAttempts} attempts per bucket, ${totalFailures} failures total`}
      >
        {/* baseline */}
        <line
          x1="0"
          y1="28"
          x2="100"
          y2="28"
          className="stroke-border"
          strokeWidth="0.5"
          vectorEffect="non-scaling-stroke"
        />
        {buckets.map((b, i) => {
          const x = i * (colWidth + gap);
          const totalH =
            maxAttempts > 0 ? (b.attempts / maxAttempts) * 28 : 0;
          const failH =
            b.attempts > 0 ? (b.failCount / b.attempts) * totalH : 0;
          const okH = totalH - failH;
          const okY = 28 - okH;
          const failY = okY - failH;
          const title = `${formatTimestamp(b.start)} — ${b.attempts} attempts (ok=${b.okCount}, fail=${b.failCount})`;
          return (
            <g key={b.start} data-testid={`chart-reroll-digest-bucket-${i}`}>
              <title>{title}</title>
              {/* invisible full-height hit area so empty buckets are hoverable */}
              <rect
                x={x}
                y={0}
                width={colWidth}
                height={28}
                fill="transparent"
              />
              {okH > 0 ? (
                <rect
                  x={x}
                  y={okY}
                  width={colWidth}
                  height={okH}
                  className="fill-green-600 dark:fill-green-500"
                />
              ) : null}
              {failH > 0 ? (
                <rect
                  x={x}
                  y={failY}
                  width={colWidth}
                  height={failH}
                  className="fill-red-600 dark:fill-red-500"
                />
              ) : null}
            </g>
          );
        })}
      </svg>
    </div>
  );
}

interface RebuildOutcome {
  ok: boolean;
  message: string;
  stdout: string;
  stderr: string;
  durationMs: number;
  exitCode: number;
}

interface RebuildLogLine {
  stream: "stdout" | "stderr";
  line: string;
}

interface RebuildResultPayload {
  ok: boolean;
  exitCode: number;
  stdout: string;
  stderr: string;
  durationMs: number;
  error: string | null;
  verification: unknown;
}

const REBUILD_STREAM_URL = `${import.meta.env.BASE_URL}api/lean/verify/rebuild/stream`.replace(
  /\/{2,}/g,
  "/",
);
const REBUILD_CANCEL_URL = `${import.meta.env.BASE_URL}api/lean/verify/rebuild/cancel`.replace(
  /\/{2,}/g,
  "/",
);
const REROLL_STREAM_URL = `${import.meta.env.BASE_URL}api/ledger/checkpoint/reroll/stream`.replace(
  /\/{2,}/g,
  "/",
);

interface RerollResultPayload {
  ok: boolean;
  exitCode: number;
  stdout: string;
  stderr: string;
  durationMs: number;
  error: string | null;
}

async function streamReroll(
  token: string,
  refereeName: string,
  onLine: (line: RebuildLogLine) => void,
  signal: AbortSignal,
): Promise<
  | { kind: "result"; payload: RerollResultPayload }
  | { kind: "error"; error: string; status?: number; retryAfterMs?: number }
> {
  let response: Response;
  try {
    const headers: Record<string, string> = { Authorization: `Bearer ${token}` };
    if (refereeName) headers["X-Referee-Name"] = refereeName;
    response = await fetch(REROLL_STREAM_URL, {
      method: "POST",
      headers,
      signal,
    });
  } catch (err) {
    return { kind: "error", error: err instanceof Error ? err.message : String(err) };
  }

  if (!response.ok) {
    let detail = `HTTP ${response.status}`;
    try {
      const body = await response.json();
      if (body && typeof body === "object" && typeof (body as { error?: unknown }).error === "string") {
        detail = (body as { error: string }).error;
      }
    } catch {
      // ignore
    }
    let retryAfterMs: number | undefined;
    const retryAfterHeader = response.headers.get("Retry-After");
    if (retryAfterHeader) {
      const sec = Number(retryAfterHeader);
      if (Number.isFinite(sec) && sec > 0) retryAfterMs = sec * 1000;
    }
    return { kind: "error", error: detail, status: response.status, retryAfterMs };
  }

  if (!response.body) {
    return { kind: "error", error: "Streaming not supported by this browser." };
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let finalResult: RerollResultPayload | null = null;
  let streamError: string | null = null;

  const handleEvent = (eventName: string, dataStr: string) => {
    let data: unknown;
    try {
      data = JSON.parse(dataStr);
    } catch {
      return;
    }
    if (eventName === "line" && data && typeof data === "object") {
      const obj = data as Partial<RebuildLogLine>;
      if ((obj.stream === "stdout" || obj.stream === "stderr") && typeof obj.line === "string") {
        onLine({ stream: obj.stream, line: obj.line });
      }
    } else if (eventName === "result") {
      finalResult = data as RerollResultPayload;
    } else if (eventName === "error" && data && typeof data === "object") {
      const obj = data as { error?: unknown };
      if (typeof obj.error === "string") streamError = obj.error;
    }
  };

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      let sep: number;
      while ((sep = buffer.indexOf("\n\n")) !== -1) {
        const raw = buffer.slice(0, sep);
        buffer = buffer.slice(sep + 2);
        let eventName = "message";
        const dataLines: string[] = [];
        for (const rawLine of raw.split("\n")) {
          if (rawLine.startsWith(":") || rawLine.length === 0) continue;
          if (rawLine.startsWith("event:")) {
            eventName = rawLine.slice(6).trim();
          } else if (rawLine.startsWith("data:")) {
            dataLines.push(rawLine.slice(5).replace(/^ /, ""));
          }
        }
        if (dataLines.length > 0) handleEvent(eventName, dataLines.join("\n"));
      }
    }
  } catch (err) {
    // Task #201: a forcibly-terminated stream (proxy dropped the
    // connection, spawn OOM-killed mid-flight, server crashed) makes
    // `reader.read()` reject instead of returning `done`. Without this
    // guard the rejection escaped `streamReroll` entirely, the button's
    // onClick `finally` cleared the spinner, and the live-log panel
    // froze on the last PROGRESS line with no error — the operator
    // never learned the re-roll actually failed. Surface it explicitly.
    // If a `result` frame already arrived before the break, prefer it.
    if (finalResult) return { kind: "result", payload: finalResult };
    return {
      kind: "error",
      error: `Re-roll stream interrupted before completion: ${
        err instanceof Error ? err.message : String(err)
      }`,
    };
  }

  if (finalResult) return { kind: "result", payload: finalResult };
  if (streamError) return { kind: "error", error: streamError };
  return { kind: "error", error: "Stream ended without a result frame." };
}

async function streamRebuild(
  token: string,
  refereeName: string,
  onLine: (line: RebuildLogLine) => void,
  signal: AbortSignal,
): Promise<
  | { kind: "result"; payload: RebuildResultPayload }
  | { kind: "error"; error: string; status?: number; retryAfterMs?: number }
> {
  let response: Response;
  try {
    const headers: Record<string, string> = { Authorization: `Bearer ${token}` };
    if (refereeName) headers["X-Referee-Name"] = refereeName;
    response = await fetch(REBUILD_STREAM_URL, {
      method: "POST",
      headers,
      signal,
    });
  } catch (err) {
    return { kind: "error", error: err instanceof Error ? err.message : String(err) };
  }

  if (!response.ok) {
    let detail = `HTTP ${response.status}`;
    try {
      const body = await response.json();
      if (body && typeof body === "object" && typeof (body as { error?: unknown }).error === "string") {
        detail = (body as { error: string }).error;
      }
    } catch {
      // ignore
    }
    let retryAfterMs: number | undefined;
    const retryAfterHeader = response.headers.get("Retry-After");
    if (retryAfterHeader) {
      const sec = Number(retryAfterHeader);
      if (Number.isFinite(sec) && sec > 0) retryAfterMs = sec * 1000;
    }
    return { kind: "error", error: detail, status: response.status, retryAfterMs };
  }

  if (!response.body) {
    return { kind: "error", error: "Streaming not supported by this browser." };
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let finalResult: RebuildResultPayload | null = null;
  let streamError: string | null = null;

  const handleEvent = (eventName: string, dataStr: string) => {
    let data: unknown;
    try {
      data = JSON.parse(dataStr);
    } catch {
      return;
    }
    if (eventName === "line" && data && typeof data === "object") {
      const obj = data as Partial<RebuildLogLine>;
      if ((obj.stream === "stdout" || obj.stream === "stderr") && typeof obj.line === "string") {
        onLine({ stream: obj.stream, line: obj.line });
      }
    } else if (eventName === "result") {
      finalResult = data as RebuildResultPayload;
    } else if (eventName === "error" && data && typeof data === "object") {
      const obj = data as { error?: unknown };
      if (typeof obj.error === "string") streamError = obj.error;
    }
  };

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      let sep: number;
      while ((sep = buffer.indexOf("\n\n")) !== -1) {
        const raw = buffer.slice(0, sep);
        buffer = buffer.slice(sep + 2);
        let eventName = "message";
        const dataLines: string[] = [];
        for (const rawLine of raw.split("\n")) {
          if (rawLine.startsWith(":") || rawLine.length === 0) continue;
          if (rawLine.startsWith("event:")) {
            eventName = rawLine.slice(6).trim();
          } else if (rawLine.startsWith("data:")) {
            dataLines.push(rawLine.slice(5).replace(/^ /, ""));
          }
        }
        if (dataLines.length > 0) handleEvent(eventName, dataLines.join("\n"));
      }
    }
  } catch (err) {
    // Task #227: a forcibly-terminated stream (proxy dropped the
    // connection, spawn OOM-killed mid-flight, server crashed) makes
    // `reader.read()` reject instead of returning `done`. Without this
    // guard the rejection escaped `streamRebuild` entirely, the button's
    // onClick `finally` cleared the spinner, and the rebuild live-log
    // panel froze on the last line with no error — the operator never
    // learned the rebuild actually failed. Surface it explicitly. If a
    // `result` frame already arrived before the break, prefer it.
    if (finalResult) return { kind: "result", payload: finalResult };
    return {
      kind: "error",
      error: `Rebuild stream interrupted before completion: ${
        err instanceof Error ? err.message : String(err)
      }`,
    };
  }

  if (finalResult) return { kind: "result", payload: finalResult };
  if (streamError) return { kind: "error", error: streamError };
  return { kind: "error", error: "Stream ended without a result frame." };
}

export default function DashboardPage() {
  const { data: summary, isLoading: isSummaryLoading } = useGetCertificateSummary();
  const { data: certificates, isLoading: isCertsLoading } = useListCertificates();
  const { data: leanVerify } = useGetLeanVerification();
  const { data: rebuildHistory } = useGetLeanRebuildHistory();
  const { data: morningstarHits, error: morningstarError } = useGetMorningstarHits(
    { limit: 20 },
    {
      query: {
        queryKey: getGetMorningstarHitsQueryKey({ limit: 20 }),
        refetchInterval: 15000,
        refetchIntervalInBackground: false,
        retry: false,
      },
    },
  );
  const queryClient = useQueryClient();
  const [rebuildToken, setRebuildToken] = useState<string>("");
  const [refereeName, setRefereeName] = useState<string>("");
  const [refereeNameError, setRefereeNameError] = useState<string | null>(null);
  const lockoutsAuthHeader = rebuildToken
    ? { Authorization: `Bearer ${rebuildToken}` }
    : undefined;
  const {
    data: lockoutsData,
    error: lockoutsError,
    refetch: refetchLockouts,
  } = useGetLeanLockouts({
    query: {
      queryKey: getGetLeanLockoutsQueryKey(),
      enabled: Boolean(rebuildToken),
      refetchInterval: rebuildToken ? 15000 : false,
      refetchIntervalInBackground: false,
      retry: false,
    },
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const [alertRotation, setAlertRotation] = useState<number>(0);
  const {
    data: ledgerAlertsData,
    error: ledgerAlertsError,
  } = useGetLedgerAlerts(
    { limit: 20, includeAcknowledged: true, rotation: alertRotation },
    {
      query: {
        queryKey: getGetLedgerAlertsQueryKey({
          limit: 20,
          includeAcknowledged: true,
          rotation: alertRotation,
        }),
        // Rotated archives are immutable, so don't waste cycles polling
        // them — only the live read needs to refresh on a timer.
        refetchInterval: alertRotation === 0 ? 30000 : false,
        refetchIntervalInBackground: false,
        retry: false,
      },
    },
  );
  const [showAcknowledgedAlerts, setShowAcknowledgedAlerts] = useState(false);
  const [alertsKindFilter, setAlertsKindFilterState] =
    useState<LedgerAlertsKindFilter>(() => {
      try {
        const stored = window.localStorage.getItem(
          LEDGER_ALERTS_KIND_FILTER_STORAGE_KEY,
        );
        return isLedgerAlertsKindFilter(stored) ? stored : "all";
      } catch {
        return "all";
      }
    });
  const setAlertsKindFilter = useCallback((value: LedgerAlertsKindFilter) => {
    setAlertsKindFilterState(value);
    try {
      if (value === "all") {
        window.localStorage.removeItem(LEDGER_ALERTS_KIND_FILTER_STORAGE_KEY);
      } else {
        window.localStorage.setItem(
          LEDGER_ALERTS_KIND_FILTER_STORAGE_KEY,
          value,
        );
      }
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);
  const isMonitorAlert = useCallback(
    (a: {
      failureMode?: string | null;
      previousFailureMode?: string | null;
    }): boolean =>
      a.failureMode === "monitor_stalled" ||
      (a.failureMode === "recovered" &&
        a.previousFailureMode === "monitor_stalled"),
    [],
  );
  const ackAlertMutation = useAckLedgerAlert({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const ackSidecarForgedMutation = useAckSidecarForged({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const ackSidecarStaleBindingMutation = useAckSidecarStaleBinding({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const rotateSidecarSecretMutation = useRotateSidecarSecret({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const rerollCheckpointMutation = useRerollLedgerCheckpoint({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const [isRerollingCheckpoint, setIsRerollingCheckpoint] = useState(false);
  const [rerollLogLines, setRerollLogLines] = useState<RebuildLogLine[]>([]);
  const rerollAbortRef = useRef<AbortController | null>(null);
  // Task #168: rotation paging for the "Recent dismissals" panel.
  // `0` = live forged-ack history file, `N >= 1` = the Nth rotated
  // archive. Rotated archives are immutable so we skip the poll when
  // not on the live page, exactly like the alerts panel.
  const [forgedAckRotation, setForgedAckRotation] = useState<number>(0);
  const forgedAckHistoryParams = { rotation: forgedAckRotation };
  const { data: forgedAckHistory } = useGetSidecarForgedAckHistory(
    forgedAckHistoryParams,
    {
      query: {
        queryKey: getGetSidecarForgedAckHistoryQueryKey(forgedAckHistoryParams),
        // Task #150: poll alongside the integrity status so the
        // "Recent dismissals" panel under the forged banner stays
        // fresh after each Acknowledge click. Rotated archives never
        // change once the rotator has moved on, so don't waste cycles
        // re-fetching them.
        refetchInterval: forgedAckRotation === 0 ? 30_000 : false,
        refetchIntervalInBackground: false,
        retry: false,
      },
    },
  );
  // Task #231: same rotation paging as the forged "Recent dismissals"
  // panel, for the amber stale-checkpoint-binding banner. `0` is the
  // live history file; `N >= 1` reads the Nth rotated archive.
  const [staleBindingAckRotation, setStaleBindingAckRotation] =
    useState<number>(0);
  const staleBindingAckHistoryParams = { rotation: staleBindingAckRotation };
  const { data: staleBindingAckHistory } = useGetSidecarStaleBindingAckHistory(
    staleBindingAckHistoryParams,
    {
      query: {
        queryKey: getGetSidecarStaleBindingAckHistoryQueryKey(
          staleBindingAckHistoryParams,
        ),
        // Task #231: poll the live page alongside the integrity status
        // so the panel stays fresh after each Acknowledge click;
        // rotated archives are immutable so skip the poll off the live
        // page, exactly like the forged panel.
        refetchInterval: staleBindingAckRotation === 0 ? 30_000 : false,
        refetchIntervalInBackground: false,
        retry: false,
      },
    },
  );
  const { data: checkpointRerollHistory } = useGetLedgerCheckpointRerollHistory({
    query: {
      queryKey: getGetLedgerCheckpointRerollHistoryQueryKey(),
      refetchInterval: 30000,
      refetchIntervalInBackground: false,
      retry: false,
    },
  });
  // Task #199: on-demand re-roll digest panel. Operators pick a window
  // (24h / 7d / 30d) and we recompute the same per-referee ok/fail rollup
  // the daily email/webhook sends, so trends can be browsed without
  // digging through an inbox.
  const [rerollDigestWindow, setRerollDigestWindow] =
    useState<GetLedgerCheckpointRerollDigestWindow>(
      GetLedgerCheckpointRerollDigestWindow["24h"],
    );
  const rerollDigestParams = useMemo(
    () => ({ window: rerollDigestWindow }),
    [rerollDigestWindow],
  );
  const { data: rerollDigest, isError: isRerollDigestError } =
    useGetLedgerCheckpointRerollDigest(rerollDigestParams, {
      query: {
        queryKey: getGetLedgerCheckpointRerollDigestQueryKey(rerollDigestParams),
        refetchInterval: 30000,
        refetchIntervalInBackground: false,
        retry: false,
      },
    });
  const [rerollCheckpointError, setRerollCheckpointError] = useState<
    string | null
  >(null);
  const [sidecarForgedAckError, setSidecarForgedAckError] = useState<
    string | null
  >(null);
  const [sidecarStaleBindingAckError, setSidecarStaleBindingAckError] =
    useState<string | null>(null);
  const [sidecarSecretRotateError, setSidecarSecretRotateError] = useState<
    string | null
  >(null);
  const [pendingAckId, setPendingAckId] = useState<string | null>(null);
  const [alertAckError, setAlertAckError] = useState<string | null>(null);
  const [highlightedAlertId, setHighlightedAlertId] = useState<string | null>(
    null,
  );
  // Task #163: parse `#alert-<id>` from the URL so a deep-linked load
  // (paste/back/share) can fire the same scroll-into-view + transient
  // amber highlight that the in-page ack link does on click.
  const parseAlertHash = (): string | null => {
    if (typeof window === "undefined") return null;
    const m = window.location.hash.match(/^#alert-(.+)$/);
    return m ? m[1] : null;
  };
  const [pendingHashAlertId, setPendingHashAlertId] = useState<string | null>(
    () => parseAlertHash(),
  );
  const highlightAlertRow = useCallback((id: string): boolean => {
    const row = document.getElementById(`alert-${id}`);
    if (!row) return false;
    row.scrollIntoView({ behavior: "smooth", block: "center" });
    setHighlightedAlertId(id);
    window.setTimeout(
      () => setHighlightedAlertId((cur) => (cur === id ? null : cur)),
      1600,
    );
    return true;
  }, []);
  useEffect(() => {
    const onHashChange = () => {
      setPendingHashAlertId(parseAlertHash());
    };
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);
  // Task #163: once the alerts query has settled (data present) and a
  // hash like `#alert-<id>` is parked in `pendingHashAlertId`, try to
  // highlight the target row. Debouncing on `ledgerAlertsData` ensures
  // we don't fire before the row exists in the DOM. If the row still
  // isn't there (e.g. it's acknowledged and the toggle is off), we
  // leave the hash parked but don't retry on subsequent renders —
  // matches the spec's "currently in the DOM" gate.
  useEffect(() => {
    if (!pendingHashAlertId) return;
    if (!ledgerAlertsData) return;
    const id = pendingHashAlertId;
    const raf = window.requestAnimationFrame(() => {
      highlightAlertRow(id);
      setPendingHashAlertId((cur) => (cur === id ? null : cur));
    });
    return () => window.cancelAnimationFrame(raf);
  }, [pendingHashAlertId, ledgerAlertsData, highlightAlertRow]);
  const {
    data: ledgerIntegrity,
    error: ledgerIntegrityError,
  } = useGetLedgerIntegrity({
    query: {
      queryKey: getGetLedgerIntegrityQueryKey(),
      refetchInterval: 30000,
      refetchIntervalInBackground: false,
      retry: false,
    },
  });
  const clearLockoutMutation = useClearLeanLockout({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const [lockoutClearError, setLockoutClearError] = useState<string | null>(null);
  const [pendingClearIp, setPendingClearIp] = useState<string | null>(null);
  const [rebuildOutcome, setRebuildOutcome] = useState<RebuildOutcome | null>(null);
  const [cooldownUntilMs, setCooldownUntilMs] = useState<number | null>(null);
  const [cooldownRemainingMs, setCooldownRemainingMs] = useState<number>(0);
  const [showTokenInput, setShowTokenInput] = useState(false);
  const [isRebuilding, setIsRebuilding] = useState(false);
  const [isCancelling, setIsCancelling] = useState(false);
  const [rebuildStartedAt, setRebuildStartedAt] = useState<number | null>(null);
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);
  const [cancelConfirmElapsedMs, setCancelConfirmElapsedMs] = useState(0);
  const [rebuildLogLines, setRebuildLogLines] = useState<RebuildLogLine[]>([]);
  const [historyRefereeFilter, setHistoryRefereeFilterState] =
    useState<string>(() => {
      try {
        return (
          window.localStorage.getItem(
            REBUILD_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          ) ?? ""
        );
      } catch {
        return "";
      }
    });
  const setHistoryRefereeFilter = useCallback((value: string) => {
    setHistoryRefereeFilterState(value);
    try {
      if (value) {
        window.localStorage.setItem(
          REBUILD_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          value,
        );
      } else {
        window.localStorage.removeItem(
          REBUILD_HISTORY_REFEREE_FILTER_STORAGE_KEY,
        );
      }
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);
  const [nowMs, setNowMs] = useState<number>(() => Date.now());
  useEffect(() => {
    const id = window.setInterval(() => setNowMs(Date.now()), 1000);
    return () => window.clearInterval(id);
  }, []);
  const logPanelRef = useRef<HTMLPreElement | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const ANONYMOUS_KEY = "__anonymous__";
  const refereeKey = (name: string | null | undefined): string =>
    name && name.length > 0 ? name : ANONYMOUS_KEY;
  const refereeLabel = (key: string): string =>
    key === ANONYMOUS_KEY ? "anonymous" : key;

  const refereeSummaries = useMemo(() => {
    const map = new Map<
      string,
      { total: number; ok: number; fail: number; lastOk: string | null; lastFail: string | null }
    >();
    const entries = rebuildHistory?.entries ?? [];
    for (const entry of entries) {
      const key = refereeKey(entry.refereeName);
      const existing = map.get(key) ?? {
        total: 0,
        ok: 0,
        fail: 0,
        lastOk: null as string | null,
        lastFail: null as string | null,
      };
      existing.total += 1;
      if (entry.ok) {
        existing.ok += 1;
        if (!existing.lastOk) existing.lastOk = entry.timestamp;
      } else {
        existing.fail += 1;
        if (!existing.lastFail) existing.lastFail = entry.timestamp;
      }
      map.set(key, existing);
    }
    return Array.from(map.entries())
      .map(([key, v]) => ({ key, ...v }))
      .sort((a, b) => b.total - a.total);
  }, [rebuildHistory]);

  const filteredHistoryEntries = useMemo(() => {
    const entries = rebuildHistory?.entries ?? [];
    if (!historyRefereeFilter) return entries;
    return entries.filter(
      (e) => refereeKey(e.refereeName) === historyRefereeFilter,
    );
  }, [rebuildHistory, historyRefereeFilter]);

  const [rerollHistoryRefereeFilter, setRerollHistoryRefereeFilterState] =
    useState<string>(() => {
      try {
        return (
          window.localStorage.getItem(
            REROLL_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          ) ?? ""
        );
      } catch {
        return "";
      }
    });
  const setRerollHistoryRefereeFilter = useCallback((value: string) => {
    setRerollHistoryRefereeFilterState(value);
    try {
      if (value) {
        window.localStorage.setItem(
          REROLL_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          value,
        );
      } else {
        window.localStorage.removeItem(
          REROLL_HISTORY_REFEREE_FILTER_STORAGE_KEY,
        );
      }
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);

  const [forgedHistoryRefereeFilter, setForgedHistoryRefereeFilterState] =
    useState<string>(() => {
      try {
        return (
          window.localStorage.getItem(
            SIDECAR_FORGED_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          ) ?? ""
        );
      } catch {
        return "";
      }
    });
  const setForgedHistoryRefereeFilter = useCallback((value: string) => {
    setForgedHistoryRefereeFilterState(value);
    try {
      if (value) {
        window.localStorage.setItem(
          SIDECAR_FORGED_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          value,
        );
      } else {
        window.localStorage.removeItem(
          SIDECAR_FORGED_HISTORY_REFEREE_FILTER_STORAGE_KEY,
        );
      }
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);

  const [
    staleBindingHistoryRefereeFilter,
    setStaleBindingHistoryRefereeFilterState,
  ] = useState<string>(() => {
    try {
      return (
        window.localStorage.getItem(
          SIDECAR_STALE_BINDING_HISTORY_REFEREE_FILTER_STORAGE_KEY,
        ) ?? ""
      );
    } catch {
      return "";
    }
  });
  const setStaleBindingHistoryRefereeFilter = useCallback((value: string) => {
    setStaleBindingHistoryRefereeFilterState(value);
    try {
      if (value) {
        window.localStorage.setItem(
          SIDECAR_STALE_BINDING_HISTORY_REFEREE_FILTER_STORAGE_KEY,
          value,
        );
      } else {
        window.localStorage.removeItem(
          SIDECAR_STALE_BINDING_HISTORY_REFEREE_FILTER_STORAGE_KEY,
        );
      }
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);

  const rerollRefereeSummaries = useMemo(() => {
    const map = new Map<
      string,
      { total: number; ok: number; fail: number; lastOk: string | null; lastFail: string | null }
    >();
    const entries = checkpointRerollHistory?.entries ?? [];
    for (const entry of entries) {
      const key = refereeKey(entry.refereeName);
      const existing = map.get(key) ?? {
        total: 0,
        ok: 0,
        fail: 0,
        lastOk: null as string | null,
        lastFail: null as string | null,
      };
      existing.total += 1;
      if (entry.ok) {
        existing.ok += 1;
        if (!existing.lastOk) existing.lastOk = entry.timestamp;
      } else {
        existing.fail += 1;
        if (!existing.lastFail) existing.lastFail = entry.timestamp;
      }
      map.set(key, existing);
    }
    return Array.from(map.entries())
      .map(([key, v]) => ({ key, ...v }))
      .sort((a, b) => b.total - a.total);
  }, [checkpointRerollHistory]);

  const filteredRerollEntries = useMemo(() => {
    const entries = checkpointRerollHistory?.entries ?? [];
    if (!rerollHistoryRefereeFilter) return entries;
    return entries.filter(
      (e: { refereeName?: string | null }) =>
        refereeKey(e.refereeName) === rerollHistoryRefereeFilter,
    );
  }, [checkpointRerollHistory, rerollHistoryRefereeFilter]);

  // Forged-sidecar dismissals are attributed via `ackedBy` (the operator
  // who clicked Acknowledge) rather than `refereeName`, and carry no
  // ok/fail outcome — so the summary only tracks per-operator counts and
  // the most recent dismissal timestamp.
  const forgedRefereeSummaries = useMemo(() => {
    const map = new Map<string, { total: number; lastAt: string | null }>();
    const entries = forgedAckHistory?.entries ?? [];
    for (const entry of entries) {
      const key = refereeKey(entry.ackedBy);
      const existing = map.get(key) ?? {
        total: 0,
        lastAt: null as string | null,
      };
      existing.total += 1;
      if (!existing.lastAt) existing.lastAt = entry.acknowledgedAt;
      map.set(key, existing);
    }
    return Array.from(map.entries())
      .map(([key, v]) => ({ key, ...v }))
      .sort((a, b) => b.total - a.total);
  }, [forgedAckHistory]);

  const filteredForgedEntries = useMemo(() => {
    const entries = forgedAckHistory?.entries ?? [];
    if (!forgedHistoryRefereeFilter) return entries;
    return entries.filter(
      (e: { ackedBy?: string | null }) =>
        refereeKey(e.ackedBy) === forgedHistoryRefereeFilter,
    );
  }, [forgedAckHistory, forgedHistoryRefereeFilter]);

  // Task #231: same per-operator summary as the forged panel — stale-
  // binding dismissals are attributed via `ackedBy` and carry no
  // ok/fail outcome, so just count dismissals per operator plus the
  // most recent dismissal timestamp.
  const staleBindingRefereeSummaries = useMemo(() => {
    const map = new Map<string, { total: number; lastAt: string | null }>();
    const entries = staleBindingAckHistory?.entries ?? [];
    for (const entry of entries) {
      const key = refereeKey(entry.ackedBy);
      const existing = map.get(key) ?? {
        total: 0,
        lastAt: null as string | null,
      };
      existing.total += 1;
      if (!existing.lastAt) existing.lastAt = entry.acknowledgedAt;
      map.set(key, existing);
    }
    return Array.from(map.entries())
      .map(([key, v]) => ({ key, ...v }))
      .sort((a, b) => b.total - a.total);
  }, [staleBindingAckHistory]);

  const filteredStaleBindingEntries = useMemo(() => {
    const entries = staleBindingAckHistory?.entries ?? [];
    if (!staleBindingHistoryRefereeFilter) return entries;
    return entries.filter(
      (e: { ackedBy?: string | null }) =>
        refereeKey(e.ackedBy) === staleBindingHistoryRefereeFilter,
    );
  }, [staleBindingAckHistory, staleBindingHistoryRefereeFilter]);

  useEffect(() => {
    if (logPanelRef.current) {
      logPanelRef.current.scrollTop = logPanelRef.current.scrollHeight;
    }
  }, [rebuildLogLines]);

  useEffect(() => {
    return () => {
      abortRef.current?.abort();
    };
  }, []);

  useEffect(() => {
    if (!showCancelConfirm || rebuildStartedAt == null) return;
    const id = window.setInterval(() => {
      setCancelConfirmElapsedMs(Date.now() - rebuildStartedAt);
    }, 1000);
    return () => window.clearInterval(id);
  }, [showCancelConfirm, rebuildStartedAt]);

  useEffect(() => {
    if (cooldownUntilMs == null) {
      setCooldownRemainingMs(0);
      return;
    }
    let intervalId: number | null = null;
    const tick = () => {
      const remaining = cooldownUntilMs - Date.now();
      if (remaining <= 0) {
        setCooldownRemainingMs(0);
        setCooldownUntilMs(null);
        if (intervalId != null) {
          window.clearInterval(intervalId);
          intervalId = null;
        }
      } else {
        setCooldownRemainingMs(remaining);
      }
    };
    const startInterval = () => {
      if (intervalId == null) {
        intervalId = window.setInterval(tick, 250);
      }
    };
    const stopInterval = () => {
      if (intervalId != null) {
        window.clearInterval(intervalId);
        intervalId = null;
      }
    };
    const handleVisibilityChange = () => {
      if (document.hidden) {
        stopInterval();
      } else {
        tick();
        if (cooldownUntilMs != null) {
          startInterval();
        }
      }
    };
    tick();
    if (!document.hidden) {
      startInterval();
    }
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      stopInterval();
    };
  }, [cooldownUntilMs]);

  const cooldownActive = cooldownRemainingMs > 0;
  const cooldownSecondsLeft = Math.ceil(cooldownRemainingMs / 1000);

  const startRebuild = async () => {
    if (!rebuildToken) {
      setShowTokenInput(true);
      setRebuildOutcome({
        ok: false,
        message: "A referee rebuild token is required. Enter it below and try again.",
        stdout: "",
        stderr: "",
        durationMs: 0,
        exitCode: -1,
      });
      return;
    }
    setRebuildOutcome(null);
    setRebuildLogLines([]);
    setIsRebuilding(true);
    setRebuildStartedAt(Date.now());
    setShowCancelConfirm(false);
    const controller = new AbortController();
    abortRef.current = controller;
    try {
      const outcome = await streamRebuild(
        rebuildToken,
        refereeName,
        (line) => setRebuildLogLines((prev) => [...prev, line]),
        controller.signal,
      );
      if (outcome.kind === "result") {
        const r = outcome.payload;
        const message = r.ok
          ? `Rebuild succeeded in ${(r.durationMs / 1000).toFixed(1)}s. VERIFY.txt refreshed.`
          : r.error ?? `Rebuild failed (exit code ${r.exitCode}).`;
        setRebuildOutcome({
          ok: r.ok,
          message,
          stdout: r.stdout,
          stderr: r.stderr,
          durationMs: r.durationMs,
          exitCode: r.exitCode,
        });
        setCooldownUntilMs(Date.now() + REBUILD_COOLDOWN_MS);
        await Promise.all([
          queryClient.invalidateQueries({ queryKey: getGetLeanVerificationQueryKey() }),
          queryClient.invalidateQueries({ queryKey: getGetLeanRebuildHistoryQueryKey() }),
        ]);
      } else {
        setRebuildOutcome({
          ok: false,
          message: outcome.error,
          stdout: "",
          stderr: "",
          durationMs: 0,
          exitCode: -1,
        });
        if (outcome.status === 429 && outcome.retryAfterMs && outcome.retryAfterMs > 0) {
          setCooldownUntilMs(Date.now() + outcome.retryAfterMs);
        }
      }
    } finally {
      setIsRebuilding(false);
      setIsCancelling(false);
      setRebuildStartedAt(null);
      setShowCancelConfirm(false);
      abortRef.current = null;
    }
  };

  const requestCancelRebuild = () => {
    if (!isRebuilding || !rebuildToken) return;
    setCancelConfirmElapsedMs(
      rebuildStartedAt ? Date.now() - rebuildStartedAt : 0,
    );
    setShowCancelConfirm(true);
  };

  const dismissCancelConfirm = () => {
    setShowCancelConfirm(false);
  };

  const cancelRebuild = async () => {
    if (!isRebuilding || !rebuildToken) return;
    setShowCancelConfirm(false);
    setIsCancelling(true);
    try {
      const cancelHeaders: Record<string, string> = {
        Authorization: `Bearer ${rebuildToken}`,
      };
      if (refereeName) cancelHeaders["X-Referee-Name"] = refereeName;
      const res = await fetch(REBUILD_CANCEL_URL, {
        method: "POST",
        headers: cancelHeaders,
      });
      if (!res.ok) {
        let detail = `HTTP ${res.status}`;
        try {
          const body = await res.json();
          if (body && typeof body === "object" && typeof (body as { error?: unknown }).error === "string") {
            detail = (body as { error: string }).error;
          }
        } catch {
          // ignore
        }
        setRebuildOutcome({
          ok: false,
          message: `Cancel failed: ${detail}`,
          stdout: "",
          stderr: "",
          durationMs: 0,
          exitCode: -1,
        });
        setIsCancelling(false);
      }
      // On success, leave isCancelling true until the stream finishes with
      // the cancellation result frame; the finally{} in startRebuild clears it.
    } catch (err) {
      setRebuildOutcome({
        ok: false,
        message: `Cancel failed: ${err instanceof Error ? err.message : String(err)}`,
        stdout: "",
        stderr: "",
        durationMs: 0,
        exitCode: -1,
      });
      setIsCancelling(false);
    }
  };

  useEffect(() => {
    try {
      const stored = window.localStorage.getItem(REBUILD_TOKEN_STORAGE_KEY);
      if (stored) setRebuildToken(stored);
      const storedName = window.localStorage.getItem(
        REBUILD_REFEREE_NAME_STORAGE_KEY,
      );
      if (storedName) setRefereeName(storedName);
    } catch {
      // ignore (private mode, etc.)
    }
  }, []);

  const handleAckAlert = async (
    alert: { id: string; timestamp: string; message: string },
  ) => {
    if (!rebuildToken) return;
    setAlertAckError(null);
    setPendingAckId(alert.id);
    try {
      await ackAlertMutation.mutateAsync({
        data: { timestamp: alert.timestamp, message: alert.message },
      });
      await queryClient.invalidateQueries({
        queryKey: getGetLedgerAlertsQueryKey({
          limit: 20,
          includeAcknowledged: true,
        }),
      });
    } catch (err) {
      setAlertAckError(
        err instanceof Error ? err.message : "Failed to dismiss alert.",
      );
    } finally {
      setPendingAckId(null);
    }
  };

  const handleClearLockout = async (ip: string) => {
    if (!rebuildToken) return;
    setLockoutClearError(null);
    setPendingClearIp(ip);
    try {
      await clearLockoutMutation.mutateAsync({ data: { ip } });
      await queryClient.invalidateQueries({ queryKey: getGetLeanLockoutsQueryKey() });
      await refetchLockouts();
    } catch (err) {
      setLockoutClearError(
        err instanceof Error ? err.message : `Failed to clear lockout for ${ip}.`,
      );
    } finally {
      setPendingClearIp(null);
    }
  };

  const lockoutsErrorMessage =
    lockoutsError instanceof Error ? lockoutsError.message : null;

  const isLoading = isSummaryLoading || isCertsLoading;

  if (isLoading) {
    return (
      <div className="space-y-8 animate-pulse">
        <div className="h-32 bg-muted w-full border border-border"></div>
        <div className="h-64 bg-muted w-full border border-border"></div>
      </div>
    );
  }

  if (!summary || !certificates) {
    return <div className="text-destructive font-mono text-sm">FAILED TO LOAD LEDGER STATE</div>;
  }

  return (
    <div className="space-y-8">
      <header>
        <h2 className="text-2xl font-bold font-sans tracking-tight mb-2">Ledger Status</h2>
        <p className="text-sm font-mono text-muted-foreground">OVERVIEW OF DAG CHAIN VERIFICATION</p>
      </header>

      <Card className="p-5 border-amber-500/50 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-amber-700 dark:text-amber-400 uppercase tracking-[0.18em] mb-2 border-b border-amber-500/30 pb-2">
          <AlertTriangle className="w-4 h-4" />
          What this ledger is — and is not
        </div>
        <div className="space-y-2 font-serif text-sm leading-relaxed text-foreground/85">
          <p>
            This is a <strong>formal-verification ledger</strong> for an{" "}
            <strong>in-progress</strong> Lean&nbsp;4 formalization: it tracks build
            status, axiom footprints, and the certificate chain. An{" "}
            <span className="font-mono">axiom debt = [ ]</span> means the listed
            declarations compile against Lean&rsquo;s standard classical
            foundations only — a statement about <em>logical hygiene</em>, not a
            claim that a theorem&rsquo;s informal target has been settled.
          </p>
          <p>
            <strong>No Millennium Prize problem is claimed solved here.</strong>{" "}
            The Yang–Mills mass gap and Navier–Stokes regularity remain{" "}
            <span className="font-mono">Open</span>; the Riemann and GRH
            propositions in the current Lean sources are{" "}
            <strong>placeholder definitions</strong>. See the{" "}
            <Link href="/walkthrough" className="text-primary hover:underline">
              Walkthrough
            </Link>{" "}
            and{" "}
            <Link href="/foundations" className="text-primary hover:underline">
              Foundations
            </Link>{" "}
            pages for the exact scope of each before drawing conclusions.
          </p>
        </div>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">DAG Status</span>
          <span className={`text-lg font-bold font-mono mt-2 ${summary.dagSealed ? 'text-green-600 dark:text-green-400' : 'text-amber-600 dark:text-amber-400'}`}>
            {summary.dagSealed ? 'SEALED' : 'OPEN'}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">Modules Certified</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.certifiedCount} / {summary.totalModules}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">Modules Awaiting</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.awaitingCount}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">PDF Documents</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.pdfUploadedCount} / {summary.pdfTotal ?? summary.totalModules}
          </span>
        </Card>
      </div>

      <Card className="p-6 border-green-500/40 bg-green-500/5">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h3 className="text-sm font-mono font-bold uppercase text-green-700 dark:text-green-400 mb-1 flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4" /> Axiom Status
            </h3>
            <p className="text-sm text-foreground/80">
              <span className="font-mono">H2_WeilTransfer</span>{" "}
              <span className="line-through text-muted-foreground">axiom</span>{" "}
              <span className="font-mono font-bold text-green-700 dark:text-green-400">DISCHARGED</span>{" "}
              via M9 (280-case Weil Transfer All).
            </p>
            <p className="text-xs font-mono text-muted-foreground mt-1">
              main_theorem axiom debt: [] (zero axioms)
            </p>
            <p className="text-xs font-mono text-muted-foreground mt-1">
              H2_WeilTransfer is now a theorem (M9). #print axioms TheoremaAureum → [].
            </p>
            <p className="text-xs font-serif text-amber-700 dark:text-amber-400 mt-2 max-w-prose leading-relaxed">
              Scope: [] is the axiom footprint of the formal scaffold as written.
              The RiemannHypothesis / GRH propositions it targets are placeholder
              definitions in the current sources, so this certifies axiom hygiene —
              not a machine-checked proof of RH. See the walkthrough.
            </p>
          </div>
          <Link href="/walkthrough" data-testid="link-walkthrough-banner">
            <span className="inline-flex items-center gap-2 font-mono text-xs uppercase tracking-wider text-primary hover:underline">
              Referee Walkthrough <ArrowRight className="w-3 h-3" />
            </span>
          </Link>
        </div>
      </Card>

      <Card
        className="p-6 border-green-500/40 bg-green-500/5"
        data-testid="card-lean-verification"
      >
        <div className="flex flex-col gap-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <h3 className="text-sm font-mono font-bold uppercase text-green-700 dark:text-green-400 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4" /> Lean 4 Verification
            </h3>
            <span
              className="inline-flex items-center gap-2 px-3 py-1 border border-green-500/50 bg-green-500/10 font-mono text-xs font-bold text-green-700 dark:text-green-400"
              data-testid="badge-axiom-debt"
            >
              Lean axiom debt = [
              {leanVerify?.axiomDebt.join(", ") ?? ""}
              ]
            </span>
          </div>

          {leanVerify ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs font-mono">
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Toolchain</span>
                  <span
                    className="inline-flex items-center self-start px-2 py-1 border border-green-500/50 bg-green-500/10 font-bold text-green-700 dark:text-green-400"
                    data-testid="text-lean-toolchain"
                  >
                    {leanVerify.toolchain}
                  </span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Date verified</span>
                  <span data-testid="text-lean-date">{leanVerify.dateVerified}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Log last refreshed</span>
                  {(() => {
                    const stale =
                      typeof leanVerify.ageDays === "number" &&
                      leanVerify.ageDays > STALE_THRESHOLD_DAYS;
                    return (
                      <span
                        className={`inline-flex items-center gap-1.5 self-start ${
                          stale
                            ? "text-amber-700 dark:text-amber-400 font-bold"
                            : "text-foreground"
                        }`}
                        data-testid="text-lean-last-modified"
                        title={leanVerify.lastModified ?? ""}
                      >
                        {stale ? (
                          <AlertTriangle className="w-3 h-3" />
                        ) : (
                          <Clock className="w-3 h-3" />
                        )}
                        <span data-testid="text-lean-age">
                          {formatAge(leanVerify.ageDays)}
                        </span>
                        <span className="text-muted-foreground">
                          ({formatTimestamp(leanVerify.lastModified)})
                        </span>
                        {stale ? (
                          <span
                            className="ml-1 px-1.5 py-0.5 border border-amber-500/50 bg-amber-500/10 text-[10px] uppercase tracking-wider"
                            data-testid="badge-lean-stale"
                          >
                            stale &gt; {STALE_THRESHOLD_DAYS}d
                          </span>
                        ) : null}
                      </span>
                    );
                  })()}
                </div>
              </div>

              <div className="bg-muted/50 border border-border p-3 font-mono text-xs space-y-1">
                {leanVerify.axiomLines.length === 0 ? (
                  <span className="text-muted-foreground">No axiom-status lines found.</span>
                ) : (
                  leanVerify.axiomLines.map((line, i) => (
                    <div
                      key={i}
                      className="text-green-700 dark:text-green-400"
                      data-testid={`text-axiom-line-${i}`}
                    >
                      {line}
                    </div>
                  ))
                )}
              </div>

              <div className="flex flex-wrap items-center gap-4">
                <VerifyTxtDialog
                  trigger={
                    <button
                      type="button"
                      className="inline-flex items-center gap-2 font-mono text-xs uppercase tracking-wider text-primary hover:underline"
                      data-testid="button-view-verify-txt"
                    >
                      <FileText className="w-3 h-3" /> View VERIFY.txt
                    </button>
                  }
                />
                <button
                  type="button"
                  onClick={() => {
                    void startRebuild();
                  }}
                  disabled={isRebuilding || !rebuildToken || cooldownActive}
                  title={
                    !rebuildToken
                      ? "Set a referee rebuild token to enable this action."
                      : cooldownActive
                        ? `Cooldown active — available in ${cooldownSecondsLeft}s`
                        : undefined
                  }
                  className="inline-flex items-center gap-2 px-3 py-1.5 border border-green-500/50 bg-green-500/10 font-mono text-xs uppercase tracking-wider text-green-700 dark:text-green-400 hover:bg-green-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                  data-testid="button-rebuild-lean-log"
                >
                  <RefreshCw
                    className={`w-3 h-3 ${isRebuilding ? "animate-spin" : ""}`}
                  />
                  {isRebuilding
                    ? "Rebuilding…"
                    : cooldownActive
                      ? `Available in ${cooldownSecondsLeft}s`
                      : "Rebuild Lean log"}
                </button>
                {isRebuilding ? (
                  <button
                    type="button"
                    onClick={() => {
                      if (isCancelling) return;
                      requestCancelRebuild();
                    }}
                    disabled={isCancelling || !rebuildToken}
                    className="inline-flex items-center gap-2 px-3 py-1.5 border border-red-500/50 bg-red-500/10 font-mono text-xs uppercase tracking-wider text-red-700 dark:text-red-400 hover:bg-red-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                    data-testid="button-cancel-lean-rebuild"
                  >
                    <XCircle className="w-3 h-3" />
                    {isCancelling ? "Cancelling…" : "Cancel"}
                  </button>
                ) : null}
                <button
                  type="button"
                  onClick={() => setShowTokenInput((v) => !v)}
                  className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground hover:text-foreground underline-offset-2 hover:underline"
                  data-testid="button-toggle-rebuild-token"
                >
                  {rebuildToken ? "Change token" : "Set token"}
                </button>
                {isRebuilding ? (
                  <span
                    className="font-mono text-xs text-muted-foreground"
                    data-testid="text-rebuild-progress"
                  >
                    Streaming lean-proof/regenerate.sh — {rebuildLogLines.length} line
                    {rebuildLogLines.length === 1 ? "" : "s"} so far.
                  </span>
                ) : null}
              </div>

              {(isRebuilding || rebuildLogLines.length > 0) ? (
                <div
                  className="border border-border bg-black/90 dark:bg-black/70"
                  data-testid="panel-rebuild-live-log"
                >
                  <div className="flex items-center justify-between px-3 py-1.5 border-b border-border bg-muted/30">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                      Live rebuild output
                    </span>
                    <span
                      className="font-mono text-[11px] text-muted-foreground"
                      data-testid="text-rebuild-line-count"
                    >
                      {rebuildLogLines.length} line{rebuildLogLines.length === 1 ? "" : "s"}
                      {isRebuilding ? " · streaming…" : ""}
                    </span>
                  </div>
                  <pre
                    ref={logPanelRef}
                    className="max-h-72 overflow-auto px-3 py-2 font-mono text-[11px] leading-relaxed text-green-300 whitespace-pre-wrap"
                    data-testid="text-rebuild-live-log"
                  >
                    {rebuildLogLines.length === 0
                      ? "Waiting for output…"
                      : rebuildLogLines
                          .map((l) => (l.stream === "stderr" ? `! ${l.line}` : l.line))
                          .join("\n")}
                  </pre>
                </div>
              ) : null}

              {showCancelConfirm && isRebuilding ? (
                <div
                  role="alertdialog"
                  aria-label="Confirm cancel rebuild"
                  className="flex flex-wrap items-center gap-3 border border-red-500/50 bg-red-500/10 p-3"
                  data-testid="panel-cancel-rebuild-confirm"
                >
                  <span
                    className="font-mono text-xs text-red-700 dark:text-red-300"
                    data-testid="text-cancel-rebuild-confirm"
                  >
                    Are you sure? You'll lose ~
                    <span data-testid="text-cancel-rebuild-elapsed">
                      {Math.max(1, Math.round(cancelConfirmElapsedMs / 1000))}s
                    </span>{" "}
                    of progress.
                  </span>
                  <div className="flex items-center gap-2 ml-auto">
                    <button
                      type="button"
                      onClick={() => {
                        void cancelRebuild();
                      }}
                      disabled={isCancelling}
                      className="inline-flex items-center gap-2 px-3 py-1.5 border border-red-500/60 bg-red-500/20 font-mono text-xs uppercase tracking-wider text-red-700 dark:text-red-300 hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed"
                      data-testid="button-confirm-cancel-rebuild"
                    >
                      <XCircle className="w-3 h-3" />
                      Yes, cancel
                    </button>
                    <button
                      type="button"
                      onClick={dismissCancelConfirm}
                      className="inline-flex items-center gap-2 px-3 py-1.5 border border-border bg-background font-mono text-xs uppercase tracking-wider text-muted-foreground hover:text-foreground"
                      data-testid="button-dismiss-cancel-rebuild"
                    >
                      Keep rebuilding
                    </button>
                  </div>
                </div>
              ) : null}

              {showTokenInput ? (
                <div
                  className="flex flex-wrap items-end gap-2 border border-border bg-muted/30 p-3"
                  data-testid="panel-rebuild-token"
                >
                  <label className="flex flex-col gap-1 flex-1 min-w-[16rem]">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                      Referee rebuild token
                    </span>
                    <input
                      type="password"
                      value={rebuildToken}
                      onChange={(e) => setRebuildToken(e.target.value)}
                      placeholder="Bearer token (LEAN_REBUILD_TOKEN or one of LEAN_REBUILD_TOKENS)"
                      className="font-mono text-xs px-2 py-1 bg-background border border-border focus:outline-none focus:border-primary"
                      data-testid="input-rebuild-token"
                      autoComplete="off"
                    />
                  </label>
                  <label className="flex flex-col gap-1 flex-1 min-w-[12rem]">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                      Referee name (optional)
                    </span>
                    <input
                      type="text"
                      value={refereeName}
                      onChange={(e) => {
                        setRefereeName(e.target.value);
                        setRefereeNameError(null);
                      }}
                      placeholder="e.g. Alice (shared-token audit label)"
                      maxLength={64}
                      className="font-mono text-xs px-2 py-1 bg-background border border-border focus:outline-none focus:border-primary"
                      data-testid="input-referee-name"
                      autoComplete="off"
                    />
                  </label>
                  <button
                    type="button"
                    onClick={() => {
                      const trimmedName = refereeName.trim();
                      if (trimmedName && !REFEREE_NAME_PATTERN.test(trimmedName)) {
                        setRefereeNameError(
                          "Referee name must be 1–64 chars: letters, digits, spaces, _.- only.",
                        );
                        return;
                      }
                      setRefereeName(trimmedName);
                      try {
                        if (rebuildToken) {
                          window.localStorage.setItem(
                            REBUILD_TOKEN_STORAGE_KEY,
                            rebuildToken,
                          );
                        } else {
                          window.localStorage.removeItem(REBUILD_TOKEN_STORAGE_KEY);
                        }
                        if (trimmedName) {
                          window.localStorage.setItem(
                            REBUILD_REFEREE_NAME_STORAGE_KEY,
                            trimmedName,
                          );
                        } else {
                          window.localStorage.removeItem(
                            REBUILD_REFEREE_NAME_STORAGE_KEY,
                          );
                        }
                      } catch {
                        // ignore
                      }
                      setRefereeNameError(null);
                      setShowTokenInput(false);
                    }}
                    className="px-3 py-1 border border-border bg-background font-mono text-[11px] uppercase tracking-wider hover:bg-muted"
                    data-testid="button-save-rebuild-token"
                  >
                    Save
                  </button>
                  {refereeNameError ? (
                    <p
                      className="basis-full font-mono text-[11px] text-red-700 dark:text-red-400"
                      data-testid="text-referee-name-error"
                    >
                      {refereeNameError}
                    </p>
                  ) : null}
                  <p className="basis-full font-mono text-[11px] text-muted-foreground">
                    Stored in your browser only. The server accepts either a
                    shared <code className="mx-1">LEAN_REBUILD_TOKEN</code>
                    (in which case the referee name is sent as
                    <code className="mx-1">X-Referee-Name</code> for audit) or a
                    named token from <code className="mx-1">LEAN_REBUILD_TOKENS</code>
                    (format <code>name1:tok1,name2:tok2</code>), where the name
                    is taken from the token itself.
                  </p>
                </div>
              ) : null}

              {rebuildHistory && rebuildHistory.entries.length > 0 ? (
                <div
                  className="border border-border bg-muted/20"
                  data-testid="panel-rebuild-history"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2 px-3 py-1.5 border-b border-border bg-muted/30">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                      Recent rebuild attempts
                    </span>
                    <div className="flex items-center gap-2">
                      <label
                        htmlFor="rebuild-history-referee-filter"
                        className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground"
                      >
                        Referee
                      </label>
                      <select
                        id="rebuild-history-referee-filter"
                        value={historyRefereeFilter}
                        onChange={(e) => setHistoryRefereeFilter(e.target.value)}
                        className="font-mono text-[11px] bg-background border border-border px-1.5 py-0.5"
                        data-testid="select-rebuild-history-referee-filter"
                      >
                        <option value="">all</option>
                        {refereeSummaries.map((s) => (
                          <option key={s.key} value={s.key}>
                            {refereeLabel(s.key)} ({s.total})
                          </option>
                        ))}
                      </select>
                      {historyRefereeFilter ? (
                        <button
                          type="button"
                          onClick={() => setHistoryRefereeFilter("")}
                          className="font-mono text-[11px] underline text-muted-foreground hover:text-foreground"
                          data-testid="button-rebuild-history-clear-filter"
                        >
                          clear
                        </button>
                      ) : null}
                      <span
                        className="font-mono text-[11px] text-muted-foreground"
                        data-testid="text-rebuild-history-count"
                      >
                        {historyRefereeFilter
                          ? `${filteredHistoryEntries.length} of ${rebuildHistory.entries.length}`
                          : `${rebuildHistory.entries.length} of last ${rebuildHistory.capacity}`}
                      </span>
                    </div>
                  </div>
                  {refereeSummaries.length > 0 ? (
                    <ul
                      className="divide-y divide-border border-b border-border bg-muted/10"
                      data-testid="list-rebuild-history-referee-summary"
                    >
                      {refereeSummaries.map((s) => {
                        const isActive = historyRefereeFilter === s.key;
                        return (
                          <li
                            key={s.key}
                            className={`flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-1.5 font-mono text-[11px] ${
                              isActive ? "bg-muted/40" : ""
                            }`}
                            data-testid={`row-rebuild-history-summary-${s.key}`}
                          >
                            <button
                              type="button"
                              onClick={() =>
                                setHistoryRefereeFilter(isActive ? "" : s.key)
                              }
                              className={`md:w-40 truncate text-left underline-offset-2 hover:underline ${
                                s.key === ANONYMOUS_KEY
                                  ? "text-muted-foreground italic"
                                  : "text-foreground"
                              } ${isActive ? "font-bold" : ""}`}
                              title={
                                isActive
                                  ? "Click to clear filter"
                                  : `Filter to ${refereeLabel(s.key)}`
                              }
                              data-testid={`button-rebuild-history-summary-${s.key}`}
                            >
                              {refereeLabel(s.key)}
                            </button>
                            <span className="text-muted-foreground md:w-16">
                              {s.total} total
                            </span>
                            <span className="text-green-700 dark:text-green-400 md:w-16">
                              {s.ok} ok
                            </span>
                            <span className="text-red-700 dark:text-red-400 md:w-16">
                              {s.fail} fail
                            </span>
                            <span className="text-muted-foreground">
                              last ok:{" "}
                              {s.lastOk ? formatTimestamp(s.lastOk) : "—"}
                            </span>
                            <span className="text-muted-foreground">
                              last fail:{" "}
                              {s.lastFail ? formatTimestamp(s.lastFail) : "—"}
                            </span>
                          </li>
                        );
                      })}
                    </ul>
                  ) : null}
                  {filteredHistoryEntries.length === 0 ? (
                    <p
                      className="px-3 py-2 font-mono text-[11px] text-muted-foreground italic"
                      data-testid="text-rebuild-history-empty"
                    >
                      No rebuild attempts match the current filter.
                    </p>
                  ) : null}
                  <ul className="divide-y divide-border">
                    {filteredHistoryEntries.map((entry, i) => (
                      <li
                        key={`${entry.timestamp}-${i}`}
                        className="flex flex-col md:flex-row md:items-center gap-1 md:gap-3 px-3 py-2 font-mono text-[11px]"
                        data-testid={`row-rebuild-history-${i}`}
                      >
                        <span
                          className={`inline-flex items-center gap-1 font-bold w-20 ${
                            entry.ok
                              ? "text-green-700 dark:text-green-400"
                              : "text-red-700 dark:text-red-400"
                          }`}
                          data-testid={`text-rebuild-history-status-${i}`}
                        >
                          {entry.ok ? (
                            <CheckCircle2 className="w-3 h-3" />
                          ) : (
                            <XCircle className="w-3 h-3" />
                          )}
                          {entry.ok ? "OK" : "FAIL"}
                        </span>
                        <span
                          className="text-muted-foreground md:w-48"
                          title={entry.timestamp}
                          data-testid={`text-rebuild-history-timestamp-${i}`}
                        >
                          {formatTimestamp(entry.timestamp)}
                        </span>
                        <span className="text-muted-foreground md:w-20">
                          {(entry.durationMs / 1000).toFixed(1)}s
                        </span>
                        <span className="text-muted-foreground md:w-20">
                          exit {entry.exitCode}
                        </span>
                        <span className="text-muted-foreground md:w-16">
                          {entry.streamed ? "stream" : "sync"}
                        </span>
                        <button
                          type="button"
                          onClick={() => {
                            const key = refereeKey(entry.refereeName);
                            setHistoryRefereeFilter(
                              historyRefereeFilter === key ? "" : key,
                            );
                          }}
                          className={`md:w-40 truncate text-left underline-offset-2 hover:underline ${
                            entry.refereeName
                              ? "text-foreground"
                              : "text-muted-foreground italic"
                          }`}
                          title={
                            entry.refereeName
                              ? `Click to filter to ${entry.refereeName}`
                              : "anonymous (no referee name supplied) — click to filter"
                          }
                          data-testid={`text-rebuild-history-referee-${i}`}
                        >
                          by {entry.refereeName ?? "anonymous"}
                        </button>
                        {entry.error ? (
                          <span
                            className="text-red-700 dark:text-red-400 flex-1 truncate"
                            title={entry.error}
                          >
                            {entry.error}
                          </span>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}

              {rebuildToken ? (
                <div
                  className="border border-border bg-muted/20"
                  data-testid="panel-lean-lockouts"
                >
                  <div className="flex items-center justify-between px-3 py-1.5 border-b border-border bg-muted/30">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                      <ShieldAlert className="w-3 h-3" />
                      Brute-force lockouts
                    </span>
                    <span
                      className="font-mono text-[11px] text-muted-foreground"
                      data-testid="text-lean-lockouts-count"
                    >
                      {lockoutsData
                        ? `${lockoutsData.activeLockouts.length} locked · ${lockoutsData.failingIps.length} failing`
                        : "loading…"}
                    </span>
                  </div>
                  {lockoutsErrorMessage ? (
                    <p
                      className="px-3 py-2 font-mono text-[11px] text-red-700 dark:text-red-400"
                      data-testid="text-lean-lockouts-error"
                    >
                      {lockoutsErrorMessage}
                    </p>
                  ) : lockoutsData &&
                    lockoutsData.activeLockouts.length === 0 &&
                    lockoutsData.failingIps.length === 0 ? (
                    <p
                      className="px-3 py-2 font-mono text-[11px] text-muted-foreground"
                      data-testid="text-lean-lockouts-empty"
                    >
                      No active lockouts or recent bad-token attempts. Threshold:
                      {" "}
                      {lockoutsData.maxFailedAttempts} failed attempts within
                      {" "}
                      {Math.round(lockoutsData.failureWindowMs / 60000)}m triggers a
                      {" "}
                      {Math.round(lockoutsData.lockoutMs / 60000)}m lockout.
                    </p>
                  ) : null}

                  {lockoutsData && lockoutsData.activeLockouts.length > 0 ? (
                    <ul className="divide-y divide-border">
                      {lockoutsData.activeLockouts.map((lo, i) => (
                        <li
                          key={`active-${lo.ip}-${i}`}
                          className="flex flex-col md:flex-row md:items-center gap-1 md:gap-3 px-3 py-2 font-mono text-[11px]"
                          data-testid={`row-lean-lockout-active-${i}`}
                        >
                          <span
                            className="inline-flex items-center gap-1 font-bold text-red-700 dark:text-red-400 w-20"
                          >
                            <Ban className="w-3 h-3" /> LOCKED
                          </span>
                          <span
                            className="text-foreground md:w-40 truncate"
                            data-testid={`text-lean-lockout-ip-${i}`}
                            title={lo.ip}
                          >
                            {lo.ip}
                          </span>
                          <span className="text-muted-foreground md:w-32">
                            {lo.failedAttempts} attempts
                          </span>
                          <span
                            className="text-muted-foreground md:w-48"
                            title={lo.lockedUntil}
                          >
                            expires {formatTimestamp(lo.lockedUntil)}
                          </span>
                          <span
                            className="text-muted-foreground md:w-24"
                            data-testid={`text-lean-lockout-remaining-${i}`}
                          >
                            ~{Math.max(1, Math.round(lo.retryAfterMs / 60000))}m left
                          </span>
                          <button
                            type="button"
                            onClick={() => {
                              void handleClearLockout(lo.ip);
                            }}
                            disabled={pendingClearIp === lo.ip}
                            className="ml-auto inline-flex items-center gap-1 px-2 py-1 border border-red-500/50 bg-red-500/10 font-mono text-[11px] uppercase tracking-wider text-red-700 dark:text-red-400 hover:bg-red-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                            data-testid={`button-clear-lean-lockout-${i}`}
                          >
                            {pendingClearIp === lo.ip ? "Clearing…" : "Clear"}
                          </button>
                        </li>
                      ))}
                    </ul>
                  ) : null}

                  {lockoutsData && lockoutsData.failingIps.length > 0 ? (
                    <ul className="divide-y divide-border border-t border-border">
                      {lockoutsData.failingIps.map((f, i) => (
                        <li
                          key={`failing-${f.ip}-${i}`}
                          className="flex flex-col md:flex-row md:items-center gap-1 md:gap-3 px-3 py-2 font-mono text-[11px]"
                          data-testid={`row-lean-lockout-failing-${i}`}
                        >
                          <span className="inline-flex items-center gap-1 font-bold text-amber-700 dark:text-amber-400 w-20">
                            <AlertTriangle className="w-3 h-3" /> FAILING
                          </span>
                          <span
                            className="text-foreground md:w-40 truncate"
                            title={f.ip}
                          >
                            {f.ip}
                          </span>
                          <span className="text-muted-foreground md:w-32">
                            {f.failedAttempts} /
                            {" "}
                            {lockoutsData.maxFailedAttempts} before lockout
                          </span>
                          <span
                            className="text-muted-foreground md:w-48"
                            title={f.firstFailureAt}
                          >
                            since {formatTimestamp(f.firstFailureAt)}
                          </span>
                          <button
                            type="button"
                            onClick={() => {
                              void handleClearLockout(f.ip);
                            }}
                            disabled={pendingClearIp === f.ip}
                            className="ml-auto inline-flex items-center gap-1 px-2 py-1 border border-border bg-background font-mono text-[11px] uppercase tracking-wider text-muted-foreground hover:text-foreground disabled:opacity-60 disabled:cursor-not-allowed"
                            data-testid={`button-clear-lean-failing-${i}`}
                          >
                            {pendingClearIp === f.ip ? "Clearing…" : "Reset"}
                          </button>
                        </li>
                      ))}
                    </ul>
                  ) : null}

                  {lockoutClearError ? (
                    <p
                      className="px-3 py-2 border-t border-border font-mono text-[11px] text-red-700 dark:text-red-400"
                      data-testid="text-lean-lockout-clear-error"
                    >
                      {lockoutClearError}
                    </p>
                  ) : null}
                </div>
              ) : null}

              <div
                className="border border-border bg-muted/20"
                data-testid="panel-ledger-alerts"
              >
                <div className="flex items-center justify-between px-3 py-1.5 border-b border-border bg-muted/30 gap-3 flex-wrap">
                  <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                    <Activity className="w-3 h-3" />
                    Recent ledger alerts
                  </span>
                  <span className="flex items-center gap-3 flex-wrap">
                    {ledgerAlertsData ? (
                      <span
                        className="inline-flex border border-border rounded-sm overflow-hidden"
                        role="group"
                        aria-label="Filter ledger alerts by kind"
                        data-testid="group-ledger-alerts-kind-filter"
                      >
                        {(
                          [
                            { value: "all", label: "All" },
                            { value: "tamper", label: "Tamper" },
                            { value: "monitor", label: "Monitor" },
                          ] as Array<{
                            value: LedgerAlertsKindFilter;
                            label: string;
                          }>
                        ).map((opt) => {
                          const active = alertsKindFilter === opt.value;
                          return (
                            <button
                              key={opt.value}
                              type="button"
                              onClick={() => setAlertsKindFilter(opt.value)}
                              className={`font-mono text-[11px] px-2 py-0.5 ${
                                active
                                  ? "bg-primary text-primary-foreground"
                                  : "bg-muted/30 hover:bg-muted/50 text-muted-foreground"
                              }`}
                              aria-pressed={active}
                              data-testid={`btn-ledger-alerts-kind-${opt.value}`}
                              data-active={active ? "true" : undefined}
                            >
                              {opt.label}
                            </button>
                          );
                        })}
                      </span>
                    ) : null}
                    {ledgerAlertsData ? (
                      <label
                        className="font-mono text-[11px] text-muted-foreground inline-flex items-center gap-1.5 cursor-pointer select-none"
                        data-testid="label-show-acknowledged-alerts"
                      >
                        <input
                          type="checkbox"
                          className="h-3 w-3"
                          checked={showAcknowledgedAlerts}
                          onChange={(e) =>
                            setShowAcknowledgedAlerts(e.target.checked)
                          }
                          data-testid="checkbox-show-acknowledged-alerts"
                        />
                        Show acknowledged
                      </label>
                    ) : null}
                    <span
                      className="font-mono text-[11px] text-muted-foreground"
                      data-testid="text-ledger-alerts-count"
                      data-kind-filter={alertsKindFilter}
                    >
                      {ledgerAlertsError
                        ? "error"
                        : ledgerAlertsData
                          ? (() => {
                              const matchesKind = (a: {
                                failureMode?: string | null;
                                previousFailureMode?: string | null;
                              }): boolean => {
                                if (alertsKindFilter === "all") return true;
                                const monitor = isMonitorAlert(a);
                                return alertsKindFilter === "monitor"
                                  ? monitor
                                  : !monitor;
                              };
                              const ackVisible = ledgerAlertsData.alerts.filter(
                                (a) =>
                                  showAcknowledgedAlerts || !a.acknowledgedAt,
                              );
                              const visible = ackVisible.filter(matchesKind)
                                .length;
                              const hiddenByKind =
                                ackVisible.length - visible;
                              const ackCount = ledgerAlertsData.alerts.filter(
                                (a) => a.acknowledgedAt,
                              ).length;
                              const droppedCount = ledgerAlertsData.alerts.filter(
                                (a) =>
                                  a.delivery?.webhook?.status ===
                                    "dropped_backpressure" ||
                                  a.delivery?.email?.status ===
                                    "dropped_backpressure",
                              ).length;
                              const kindLabel =
                                alertsKindFilter === "tamper"
                                  ? "tamper only"
                                  : alertsKindFilter === "monitor"
                                    ? "monitor only"
                                    : null;
                              const base = kindLabel
                                ? `${visible} entr${visible === 1 ? "y" : "ies"} (${kindLabel})`
                                : `${visible} entr${visible === 1 ? "y" : "ies"}`;
                              const suffixes: string[] = [];
                              if (hiddenByKind > 0 && kindLabel) {
                                suffixes.push(
                                  `${hiddenByKind} hidden by filter`,
                                );
                              }
                              if (ackCount > 0 && !showAcknowledgedAlerts) {
                                suffixes.push(`${ackCount} ack'd hidden`);
                              }
                              if (droppedCount > 0) {
                                suffixes.push(
                                  `${droppedCount} suppressed (sink wedged)`,
                                );
                              }
                              const gcDropped =
                                ledgerAlertsData.ackGcDropped ?? 0;
                              if (gcDropped > 0) {
                                suffixes.push(
                                  `${gcDropped} stale dismissal${gcDropped === 1 ? "" : "s"} cleaned up`,
                                );
                              }
                              return suffixes.length > 0
                                ? `${base} (${suffixes.join(", ")})`
                                : base;
                            })()
                          : "loading…"}
                    </span>
                  </span>
                </div>
                {(() => {
                  const rotations = ledgerAlertsData?.availableRotations ?? [];
                  const currentRotation = ledgerAlertsData?.rotation ?? alertRotation;
                  if (rotations.length === 0 && currentRotation === 0) {
                    return null;
                  }
                  const fmtSize = (n: number): string => {
                    if (n < 1024) return `${n} B`;
                    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
                    return `${(n / (1024 * 1024)).toFixed(2)} MB`;
                  };
                  return (
                    <div
                      className="flex flex-wrap items-center gap-2 px-3 py-1.5 border-b border-border bg-muted/10"
                      data-testid="panel-ledger-alerts-rotations"
                    >
                      <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                        Archive
                      </span>
                      <button
                        type="button"
                        onClick={() => setAlertRotation(0)}
                        className={`font-mono text-[11px] px-2 py-0.5 border border-border rounded-sm ${
                          currentRotation === 0
                            ? "bg-primary text-primary-foreground border-primary"
                            : "bg-muted/30 hover:bg-muted/50"
                        }`}
                        data-testid="btn-ledger-alerts-rotation-0"
                        title="Live alert log (data/ledger-alerts.jsonl)"
                      >
                        live
                      </button>
                      {rotations.map((r) => (
                        <button
                          key={`rot-${r.index}`}
                          type="button"
                          onClick={() => setAlertRotation(r.index)}
                          className={`font-mono text-[11px] px-2 py-0.5 border border-border rounded-sm ${
                            currentRotation === r.index
                              ? "bg-primary text-primary-foreground border-primary"
                              : "bg-muted/30 hover:bg-muted/50"
                          }`}
                          data-testid={`btn-ledger-alerts-rotation-${r.index}`}
                          title={`Rotated archive .${r.index} — ${fmtSize(r.size)}, rotated ${formatTimestamp(r.mtime)}`}
                        >
                          .{r.index}
                        </button>
                      ))}
                      {currentRotation > 0 ? (
                        <span
                          className="font-mono text-[11px] text-muted-foreground ml-auto"
                          data-testid="text-ledger-alerts-rotation-hint"
                        >
                          read-only archive — acknowledgements are
                          disabled
                        </span>
                      ) : rotations.length > 0 ? (
                        <span
                          className="font-mono text-[11px] text-muted-foreground ml-auto"
                          data-testid="text-ledger-alerts-rotation-hint"
                        >
                          {rotations.length} rotated archive
                          {rotations.length === 1 ? "" : "s"} available
                        </span>
                      ) : null}
                    </div>
                  );
                })()}
                {ledgerAlertsError ? (
                  <p
                    className="px-3 py-2 font-mono text-[11px] text-red-700 dark:text-red-400"
                    data-testid="text-ledger-alerts-error"
                  >
                    {ledgerAlertsError instanceof Error
                      ? ledgerAlertsError.message
                      : "Failed to load alert log"}
                  </p>
                ) : ledgerAlertsData ? (
                  (() => {
                    const ackVisibleAlerts = ledgerAlertsData.alerts.filter(
                      (a) => showAcknowledgedAlerts || !a.acknowledgedAt,
                    );
                    const visibleAlerts = ackVisibleAlerts.filter((a) => {
                      if (alertsKindFilter === "all") return true;
                      const monitor = isMonitorAlert(a);
                      return alertsKindFilter === "monitor"
                        ? monitor
                        : !monitor;
                    });
                    if (visibleAlerts.length === 0) {
                      const allAcked =
                        ledgerAlertsData.alerts.length > 0 &&
                        !showAcknowledgedAlerts &&
                        ackVisibleAlerts.length === 0;
                      const hiddenByKind =
                        alertsKindFilter !== "all" &&
                        ackVisibleAlerts.length > 0;
                      return (
                        <p
                          className="px-3 py-2 font-mono text-[11px] text-green-700 dark:text-green-400 flex items-center gap-1.5"
                          data-testid="text-ledger-alerts-empty"
                        >
                          <CheckCircle2 className="w-3 h-3" />
                          {hiddenByKind
                            ? alertsKindFilter === "tamper"
                              ? "No tamper alerts match the current filter."
                              : "No monitor alerts match the current filter."
                            : allAcked
                              ? "All alerts acknowledged. No outstanding incidents."
                              : "No alerts on record."}
                        </p>
                      );
                    }
                    return (
                      <ul className="divide-y divide-border">
                        {visibleAlerts.map((alert, i) => {
                          const missingTransport: LedgerAlertDeliveryStatus = {
                            status: "not_configured",
                          };
                          const transports = [
                            {
                              name: "webhook",
                              info: alert.delivery?.webhook ?? missingTransport,
                            },
                            {
                              name: "email",
                              info: alert.delivery?.email ?? missingTransport,
                            },
                          ];
                          const anyFailed = transports.some(
                            (t) => t.info.status === "failed",
                          );
                          const anyDropped = transports.some(
                            (t) => t.info.status === "dropped_backpressure",
                          );
                          const isAcked = Boolean(alert.acknowledgedAt);
                          const isHighlighted =
                            highlightedAlertId === alert.id;
                          // Task #161: a "MONITOR" badge fires for both
                          // the stalled-monitor alert and its paired
                          // recovery row, so an operator can see at a
                          // glance that the row is a watchdog signal
                          // (push-alerts silent) rather than a real
                          // tamper. The underlying signal is the same
                          // failure_mode / previous_failure_mode pair
                          // that drives `kernel._alert_subject`.
                          const isMonitorRow =
                            alert.failureMode === "monitor_stalled" ||
                            (alert.failureMode === "recovered" &&
                              alert.previousFailureMode ===
                                "monitor_stalled");
                          const isRecoveryRow =
                            alert.failureMode === "recovered";
                          return (
                            <li
                              key={`alert-${alert.id}`}
                              id={`alert-${alert.id}`}
                              className={`px-3 py-2 font-mono text-[11px] space-y-1 scroll-mt-24 transition-colors duration-500 ${
                                isHighlighted
                                  ? "ring-2 ring-amber-500 bg-amber-500/30"
                                  : isAcked
                                    ? "opacity-60"
                                    : anyDropped
                                      ? "bg-amber-500/15 border-l-2 border-amber-600"
                                      : anyFailed
                                        ? "bg-amber-500/10 border-l-2 border-amber-500"
                                        : ""
                              }`}
                              data-testid={`row-ledger-alert-${i}`}
                              data-alert-id={alert.id}
                              data-highlighted={
                                isHighlighted ? "true" : undefined
                              }
                              data-dropped-backpressure={
                                anyDropped ? "true" : undefined
                              }
                              data-monitor-row={
                                isMonitorRow ? "true" : undefined
                              }
                            >
                              <div
                                className={`font-bold break-words ${
                                  isRecoveryRow
                                    ? "text-green-700 dark:text-green-400"
                                    : "text-red-700 dark:text-red-400"
                                }`}
                                data-testid={`text-ledger-alert-subject-${i}`}
                              >
                                {alert.subject}
                              </div>
                              <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                                <span
                                  className={`inline-flex items-center gap-1 font-bold ${
                                    isRecoveryRow
                                      ? "text-green-700 dark:text-green-400"
                                      : "text-red-700 dark:text-red-400"
                                  }`}
                                >
                                  <AlertTriangle className="w-3 h-3" />
                                  {alert.failureMode ?? "alert"}
                                </span>
                                {isMonitorRow ? (
                                  <span
                                    className="inline-block px-1.5 py-0.5 border border-sky-600/60 bg-sky-500/15 text-sky-800 dark:text-sky-300 font-semibold uppercase tracking-wider"
                                    title="Watchdog signal from the auto-integrity monitor — push alerts on ledger tamper may have been silent. Not a tamper alert."
                                    data-testid={`text-ledger-alert-monitor-badge-${i}`}
                                  >
                                    MONITOR
                                  </span>
                                ) : null}
                                <span
                                  className="text-muted-foreground"
                                  title={alert.timestamp}
                                  data-testid={`text-ledger-alert-timestamp-${i}`}
                                >
                                  {formatTimestamp(alert.timestamp)}
                                </span>
                                <span
                                  className="text-foreground truncate"
                                  data-testid={`text-ledger-alert-workflow-${i}`}
                                  title={alert.workflow}
                                >
                                  workflow={alert.workflow}
                                </span>
                                <span className="ml-auto flex items-center gap-1.5">
                                  {transports.map((t) => {
                                    const isDropped =
                                      t.info.status === "dropped_backpressure";
                                    const cls =
                                      t.info.status === "ok"
                                        ? "text-green-700 dark:text-green-400 border-green-500/40"
                                        : t.info.status === "failed"
                                          ? "text-amber-700 dark:text-amber-400 border-amber-500/50 bg-amber-500/10"
                                          : isDropped
                                            ? "text-amber-800 dark:text-amber-300 border-amber-600/70 bg-amber-500/20 font-semibold"
                                            : "text-muted-foreground border-border";
                                    const label = isDropped
                                      ? `${t.name}: suppressed (sink wedged)`
                                      : `${t.name}: ${t.info.status}`;
                                    const tooltip = isDropped
                                      ? `In-flight dispatch cap saturated when alert tried to fire (inflight=${
                                          t.info.inflight ?? "?"
                                        } / cap=${
                                          t.info.cap ?? "?"
                                        }). No network call was made — the sink itself is wedged.`
                                      : (t.info.error ?? undefined);
                                    return (
                                      <span
                                        key={t.name}
                                        className={`inline-block px-1.5 py-0.5 border ${cls}`}
                                        title={tooltip}
                                        data-testid={`text-ledger-alert-${t.name}-${i}`}
                                        data-status={t.info.status}
                                      >
                                        {label}
                                      </span>
                                    );
                                  })}
                                  {isAcked ? (
                                    <span
                                      className="inline-block px-1.5 py-0.5 border border-border text-muted-foreground"
                                      title={`Acknowledged at ${alert.acknowledgedAt}`}
                                      data-testid={`text-ledger-alert-acked-${i}`}
                                    >
                                      ack'd {formatTimestamp(alert.acknowledgedAt ?? undefined)}
                                    </span>
                                  ) : rebuildToken && alertRotation === 0 ? (
                                    <button
                                      type="button"
                                      onClick={() => {
                                        void handleAckAlert({
                                          id: alert.id,
                                          timestamp: alert.timestamp,
                                          message: alert.message,
                                        });
                                      }}
                                      disabled={pendingAckId === alert.id}
                                      className="inline-flex items-center gap-1 px-2 py-0.5 border border-border bg-background font-mono text-[11px] uppercase tracking-wider text-muted-foreground hover:text-foreground disabled:opacity-60 disabled:cursor-not-allowed"
                                      data-testid={`button-dismiss-ledger-alert-${i}`}
                                    >
                                      {pendingAckId === alert.id
                                        ? "Dismissing…"
                                        : "Dismiss"}
                                    </button>
                                  ) : null}
                                </span>
                              </div>
                              <p
                                className="text-foreground/80 break-words"
                                data-testid={`text-ledger-alert-message-${i}`}
                              >
                                {alert.message}
                              </p>
                            </li>
                          );
                        })}
                      </ul>
                    );
                  })()
                ) : null}
                {alertAckError ? (
                  <p
                    className="px-3 py-2 border-t border-border font-mono text-[11px] text-red-700 dark:text-red-400"
                    data-testid="text-ledger-alert-ack-error"
                  >
                    {alertAckError}
                  </p>
                ) : null}
              </div>

              {rebuildOutcome ? (
                <div
                  className={`border p-3 font-mono text-xs space-y-2 ${
                    rebuildOutcome.ok
                      ? "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400"
                      : "border-red-500/50 bg-red-500/10 text-red-700 dark:text-red-400"
                  }`}
                  data-testid="panel-rebuild-result"
                >
                  <div className="flex items-center gap-2">
                    {rebuildOutcome.ok ? (
                      <CheckCircle2 className="w-3 h-3" />
                    ) : (
                      <XCircle className="w-3 h-3" />
                    )}
                    <span
                      className="font-bold"
                      data-testid="text-rebuild-message"
                    >
                      {rebuildOutcome.message}
                    </span>
                  </div>
                  {rebuildOutcome.stdout || rebuildOutcome.stderr ? (
                    <details className="text-foreground/80">
                      <summary className="cursor-pointer text-muted-foreground hover:text-foreground">
                        Show script output (exit {rebuildOutcome.exitCode},{" "}
                        {(rebuildOutcome.durationMs / 1000).toFixed(1)}s)
                      </summary>
                      <pre
                        className="mt-2 max-h-64 overflow-auto whitespace-pre-wrap bg-muted/40 p-2 text-foreground"
                        data-testid="text-rebuild-output"
                      >
                        {rebuildOutcome.stdout}
                        {rebuildOutcome.stderr ? `\n${rebuildOutcome.stderr}` : ""}
                      </pre>
                    </details>
                  ) : null}
                </div>
              ) : null}
            </>
          ) : (
            <p className="text-xs font-mono text-muted-foreground">
              Verification log unavailable.
            </p>
          )}
        </div>
      </Card>

      <Card
        className="p-6 border-border bg-card"
        data-testid="card-ledger-integrity"
      >
        <div className="flex flex-col gap-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground flex items-center gap-2">
              <ShieldCheck className="w-4 h-4" /> Ledger integrity (at rest)
            </h3>
            {ledgerIntegrity ? (
              <span
                className={`inline-flex items-center gap-2 px-3 py-1 border font-mono text-xs font-bold ${
                  ledgerIntegrity.status === "ok"
                    ? "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400"
                    : ledgerIntegrity.status === "missing"
                      ? "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400"
                      : "border-red-500/50 bg-red-500/10 text-red-700 dark:text-red-400"
                }`}
                data-testid="badge-ledger-integrity"
              >
                {ledgerIntegrity.status === "ok" ? (
                  <CheckCircle2 className="w-3 h-3" />
                ) : ledgerIntegrity.status === "missing" ? (
                  <AlertTriangle className="w-3 h-3" />
                ) : (
                  <ShieldAlert className="w-3 h-3" />
                )}
                {ledgerIntegrity.status === "ok"
                  ? "Checkpoint verified"
                  : ledgerIntegrity.status === "missing"
                    ? "Ledger file MISSING"
                    : "Checkpoint MISMATCH"}
              </span>
            ) : ledgerIntegrityError ? (
              <span
                className="inline-flex items-center gap-2 px-3 py-1 border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 font-mono text-xs font-bold"
                data-testid="badge-ledger-integrity-unreachable"
              >
                <AlertTriangle className="w-3 h-3" />
                Unreachable
              </span>
            ) : null}
          </div>

          {ledgerIntegrity ? (
            <div className="flex items-center gap-2 flex-wrap text-xs font-mono">
              <span className="text-muted-foreground uppercase tracking-wider">
                Sidecar keyfile posture:
              </span>
              <span
                className={`inline-flex items-center gap-1 px-2 py-0.5 border text-[11px] font-bold uppercase tracking-wider ${
                  ledgerIntegrity.sidecarSecretStrictMode
                    ? "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400"
                    : "border-muted-foreground/40 bg-muted-foreground/5 text-muted-foreground"
                }`}
                data-testid="badge-ledger-sidecar-strict-mode"
                data-strict-mode={
                  ledgerIntegrity.sidecarSecretStrictMode ? "on" : "off"
                }
                title={
                  ledgerIntegrity.sidecarSecretStrictMode
                    ? "LEDGER_SIDECAR_SECRET_STRICT_MODE is ON — the API server refuses to boot when the on-disk sidecar keyfile is group/world-readable."
                    : "LEDGER_SIDECAR_SECRET_STRICT_MODE is OFF (default lenient mode) — a loose keyfile only emits a startup WARN. Set LEDGER_SIDECAR_SECRET_STRICT_MODE=1 for hardened deploys."
                }
              >
                Strict keyfile mode:{" "}
                {ledgerIntegrity.sidecarSecretStrictMode ? "ON" : "OFF"}
              </span>
            </div>
          ) : null}

          <p className="text-xs font-mono text-muted-foreground">
            Compares <span className="text-foreground">data/hits.txt</span> against the
            committed{" "}
            <span className="text-foreground">data/hits.txt.checkpoint</span> sidecar
            (size + sha256 of the last known-good prefix). Mirrors{" "}
            <span className="text-foreground">scripts/check-ledger-integrity.py</span>.
            Read-only — never mutates the ledger. Polls every 30s.
          </p>

          {ledgerIntegrity?.lastOkSidecarStatus === "forged" ? (
            <div
              className="border border-red-500/50 bg-red-500/10 p-3 font-mono text-xs space-y-1 text-red-700 dark:text-red-400"
              data-testid="panel-ledger-sidecar-forged"
              data-acknowledged={
                ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt
                  ? "true"
                  : "false"
              }
            >
              <div className="font-bold uppercase tracking-wider flex items-center gap-2 flex-wrap">
                <ShieldAlert className="w-3 h-3" />
                Sidecar tamper detected
                {ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt ? (
                  <span
                    className="text-[10px] uppercase tracking-wider border border-red-500/40 bg-red-500/20 px-1.5 py-0.5"
                    data-testid="badge-ledger-sidecar-forged-acknowledged"
                    data-acked-by={
                      ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy ?? ""
                    }
                    title={
                      ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy
                        ? `Acknowledged by ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedBy} at ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedAt}`
                        : `Acknowledged at ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedAt}`
                    }
                  >
                    acknowledged
                    {ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy ? (
                      <span className="normal-case lowercase tracking-normal ml-1 opacity-80">
                        · {ledgerIntegrity.lastOkSidecarStatusAcknowledgedBy}
                      </span>
                    ) : null}
                  </span>
                ) : null}
              </div>
              <div
                className="whitespace-pre-wrap text-foreground/90"
                data-testid="text-ledger-sidecar-forged-reason"
              >
                The persisted{" "}
                <span className="text-foreground">data/hits.txt.lastok</span>{" "}
                sidecar failed HMAC verification at boot — someone with
                write access to the data dir wrote a forged payload
                without the per-deploy secret. The forged value has
                been discarded (lastOkAt reset to null).
              </div>
              <div className="text-foreground/70">
                Recommended: rotate the sidecar secret (
                <span className="text-foreground">LEDGER_SIDECAR_SECRET</span>{" "}
                or <span className="text-foreground">data/hits.txt.lastok.key</span>
                ), audit who has write access to{" "}
                <span className="text-foreground">data/</span>, and re-verify
                the ledger from a fresh checkout.
              </div>
              {rebuildToken ? (
                <div className="flex items-center gap-2 pt-1 flex-wrap">
                  <button
                    type="button"
                    className="border border-red-500/40 bg-red-500/10 hover:bg-red-500/20 disabled:opacity-50 disabled:cursor-not-allowed px-2 py-1 text-[11px] uppercase tracking-wider text-red-700 dark:text-red-300"
                    data-testid="button-ack-ledger-sidecar-forged"
                    disabled={
                      ackSidecarForgedMutation.isPending ||
                      Boolean(
                        ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt,
                      )
                    }
                    onClick={() => {
                      setSidecarForgedAckError(null);
                      ackSidecarForgedMutation.mutate(undefined, {
                        onSuccess: () => {
                          void queryClient.invalidateQueries({
                            queryKey: getGetLedgerIntegrityQueryKey(),
                          });
                        },
                        onError: (err: unknown) => {
                          const msg =
                            err instanceof Error
                              ? err.message
                              : "Failed to acknowledge sidecar tamper banner.";
                          setSidecarForgedAckError(msg);
                        },
                      });
                    }}
                  >
                    {ackSidecarForgedMutation.isPending
                      ? "Acknowledging…"
                      : ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt
                        ? "Acknowledged"
                        : "Acknowledge"}
                  </button>
                  <button
                    type="button"
                    className="border border-red-500/40 bg-red-500/10 hover:bg-red-500/20 disabled:opacity-50 disabled:cursor-not-allowed px-2 py-1 text-[11px] uppercase tracking-wider text-red-700 dark:text-red-300"
                    data-testid="button-rotate-ledger-sidecar-secret"
                    disabled={rotateSidecarSecretMutation.isPending}
                    title="Generate a fresh HMAC secret, re-seal the live sidecar, and clear this banner. Operator-attribution is recorded in the server log."
                    onClick={() => {
                      setSidecarSecretRotateError(null);
                      rotateSidecarSecretMutation.mutate(undefined, {
                        onSuccess: () => {
                          void queryClient.invalidateQueries({
                            queryKey: getGetLedgerIntegrityQueryKey(),
                          });
                        },
                        onError: (err: unknown) => {
                          const msg =
                            err instanceof Error
                              ? err.message
                              : "Failed to rotate sidecar HMAC secret.";
                          setSidecarSecretRotateError(msg);
                        },
                      });
                    }}
                  >
                    {rotateSidecarSecretMutation.isPending
                      ? "Rotating…"
                      : "Rotate sidecar secret"}
                  </button>
                  <span className="text-[10px] text-muted-foreground">
                    Acknowledge keeps the banner sticky until next boot;
                    rotate clears it immediately by re-sealing the sidecar
                    with a fresh secret.
                  </span>
                </div>
              ) : (
                <div
                  className="text-[10px] text-muted-foreground pt-1"
                  data-testid="hint-ack-ledger-sidecar-forged-no-token"
                >
                  Paste a referee rebuild token in the Lean 4 Verification
                  card to enable the Acknowledge button.
                </div>
              )}
              {sidecarForgedAckError ? (
                <div
                  className="text-[11px] text-red-700 dark:text-red-300"
                  data-testid="text-ack-ledger-sidecar-forged-error"
                >
                  {sidecarForgedAckError}
                </div>
              ) : null}
              {sidecarSecretRotateError ? (
                <div
                  className="text-[11px] text-red-700 dark:text-red-300"
                  data-testid="text-rotate-ledger-sidecar-secret-error"
                >
                  {sidecarSecretRotateError}
                </div>
              ) : null}
              {(() => {
                // Task #150: prior forged-sidecar dismissals from the
                // rotating history log. The single-incident sidecar
                // only carries the current incident's ack, so this
                // panel is what operators investigating a repeat
                // tamper attack rely on to see who dismissed earlier
                // banners.
                // Task #168: also surfaces prev/next paging into the
                // rotated archives so a long-running tamper campaign
                // doesn't lose its earlier dismissals once the live
                // file rotates past the byte cap.
                const entries = forgedAckHistory?.entries ?? [];
                const rotations = forgedAckHistory?.rotations ?? [];
                const currentRotation =
                  forgedAckHistory?.rotation ?? forgedAckRotation;
                // Hide the whole panel when there is nothing to show
                // anywhere — neither live entries nor any rotated
                // archive on disk.
                if (entries.length === 0 && rotations.length === 0) {
                  return null;
                }
                const capacity =
                  forgedAckHistory?.capacity ?? entries.length;
                const maxRotationIdx = rotations.reduce(
                  (m, r) => (r.index > m ? r.index : m),
                  0,
                );
                const canGoOlder = currentRotation < maxRotationIdx;
                const canGoNewer = currentRotation > 0;
                const fmtSize = (n: number): string => {
                  if (n < 1024) return `${n} B`;
                  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
                  return `${(n / (1024 * 1024)).toFixed(2)} MB`;
                };
                // Task #207: how full the live log is before it rotates,
                // and which archive the next rotation would drop. Once the
                // live file passes `maxBytes` it rotates to `.1`, every
                // archive shifts up an index, and the archive at
                // `maxRotations` is unlinked — so during an active tamper
                // campaign that archive is the evidence most at risk.
                const liveSize = forgedAckHistory?.liveSize ?? null;
                const maxBytes = forgedAckHistory?.maxBytes ?? null;
                const maxRotations = forgedAckHistory?.maxRotations ?? null;
                const livePct =
                  liveSize != null && maxBytes != null && maxBytes > 0
                    ? Math.min(100, (liveSize / maxBytes) * 100)
                    : null;
                // The next rotation drops whichever archive is currently
                // at the rotation cap index. If the live file is already
                // at/over that cap, that archive is on the chopping block.
                const nextDropIdx =
                  maxRotations != null &&
                  rotations.some((r) => r.index === maxRotations)
                    ? maxRotations
                    : null;
                return (
                  <div
                    className="border border-red-500/30 bg-background/40 mt-2"
                    data-testid="panel-ledger-sidecar-forged-history"
                    data-rotation={currentRotation}
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2 px-2 py-1 border-b border-red-500/20">
                      <span className="font-mono text-[10px] uppercase tracking-wider text-red-700/80 dark:text-red-300/80">
                        Recent dismissals
                        {currentRotation > 0 ? (
                          <span
                            className="ml-2 normal-case tracking-normal text-red-700/60 dark:text-red-300/60"
                            data-testid="text-ledger-sidecar-forged-history-archive-label"
                          >
                            (archive .{currentRotation})
                          </span>
                        ) : null}
                      </span>
                      <div className="flex items-center gap-2">
                        {liveSize != null && maxBytes != null ? (
                          <span
                            className="font-mono text-[10px] text-red-700/70 dark:text-red-300/70"
                            data-testid="text-ledger-sidecar-forged-history-live-fullness"
                            data-live-size={liveSize}
                            data-max-bytes={maxBytes}
                            title={
                              livePct != null
                                ? `Live log is ${livePct.toFixed(0)}% of the way to its ${fmtSize(maxBytes)} rotation cap. When it rotates, archive .${maxRotations ?? "N"} is dropped.`
                                : undefined
                            }
                          >
                            live: {fmtSize(liveSize)} / {fmtSize(maxBytes)}
                            {livePct != null
                              ? ` (${livePct.toFixed(0)}%)`
                              : ""}
                          </span>
                        ) : null}
                        {/* Task #234: cumulative volume of dismissals
                            that have aged out (been dropped past the
                            rotation cap) since the API server booted.
                            Sourced from the integrity status, which
                            tallies every rotation drop — unlike the
                            one-shot archive-full alert, this keeps
                            counting so operators can see the running
                            total of lost dismissal records. Hidden when
                            nothing has aged out yet. */}
                        {(ledgerIntegrity?.forgedAckHistoryDroppedArchivesTotal ??
                          0) > 0 ? (
                          <span
                            className="font-mono text-[10px] text-red-700/70 dark:text-red-300/70"
                            data-testid="text-ledger-sidecar-forged-history-aged-out"
                            data-dropped-archives={
                              ledgerIntegrity?.forgedAckHistoryDroppedArchivesTotal ??
                              0
                            }
                            data-dropped-entries={
                              ledgerIntegrity?.forgedAckHistoryDroppedEntriesTotal ??
                              0
                            }
                            title={`${
                              ledgerIntegrity?.forgedAckHistoryDroppedEntriesTotal ??
                              0
                            } dismissal record(s) across ${
                              ledgerIntegrity?.forgedAckHistoryDroppedArchivesTotal ??
                              0
                            } archive(s) have aged out (dropped past the rotation cap) since the server booted. This count resets on restart.`}
                          >
                            aged out:{" "}
                            {ledgerIntegrity?.forgedAckHistoryDroppedEntriesTotal ??
                              0}{" "}
                            since boot
                          </span>
                        ) : null}
                        <label
                          htmlFor="ledger-sidecar-forged-history-referee-filter"
                          className="font-mono text-[10px] uppercase tracking-wider text-red-700/80 dark:text-red-300/80"
                        >
                          Referee
                        </label>
                        <select
                          id="ledger-sidecar-forged-history-referee-filter"
                          value={forgedHistoryRefereeFilter}
                          onChange={(e) =>
                            setForgedHistoryRefereeFilter(e.target.value)
                          }
                          className="font-mono text-[10px] bg-background border border-red-500/30 px-1.5 py-0.5"
                          data-testid="select-ledger-sidecar-forged-history-referee-filter"
                        >
                          <option value="">all</option>
                          {forgedRefereeSummaries.map((s) => (
                            <option key={s.key} value={s.key}>
                              {refereeLabel(s.key)} ({s.total})
                            </option>
                          ))}
                        </select>
                        {forgedHistoryRefereeFilter ? (
                          <button
                            type="button"
                            onClick={() => setForgedHistoryRefereeFilter("")}
                            className="font-mono text-[10px] underline text-red-700/70 dark:text-red-300/70 hover:text-red-700 dark:hover:text-red-300"
                            data-testid="button-ledger-sidecar-forged-history-clear-filter"
                          >
                            clear
                          </button>
                        ) : null}
                        <span
                          className="font-mono text-[10px] text-red-700/70 dark:text-red-300/70"
                          data-testid="text-ledger-sidecar-forged-history-count"
                        >
                          {forgedHistoryRefereeFilter
                            ? `${filteredForgedEntries.length} of ${entries.length}`
                            : `${entries.length} of last ${capacity}`}
                        </span>
                      </div>
                    </div>
                    {livePct != null ? (
                      <div
                        className="px-2 py-1 border-b border-red-500/20"
                        data-testid="meter-ledger-sidecar-forged-history-live"
                      >
                        <div className="h-1 w-full rounded-sm bg-red-500/15 overflow-hidden">
                          <div
                            className={`h-full rounded-sm ${
                              livePct >= 90
                                ? "bg-red-500"
                                : livePct >= 60
                                  ? "bg-amber-500"
                                  : "bg-red-500/50"
                            }`}
                            style={{ width: `${livePct}%` }}
                          />
                        </div>
                      </div>
                    ) : null}
                    {rotations.length > 0 ? (
                      <div
                        className="flex flex-wrap items-center gap-2 px-2 py-1 border-b border-red-500/20 bg-red-500/5"
                        data-testid="panel-ledger-sidecar-forged-history-rotations"
                      >
                        <button
                          type="button"
                          onClick={() =>
                            setForgedAckRotation((r) =>
                              Math.max(0, r - 1),
                            )
                          }
                          disabled={!canGoNewer}
                          className="font-mono text-[10px] px-2 py-0.5 border border-red-500/30 rounded-sm bg-background/40 hover:bg-background/70 disabled:opacity-40 disabled:cursor-not-allowed"
                          data-testid="btn-ledger-sidecar-forged-history-newer"
                          title="Page to the newer archive (or back to the live file)"
                        >
                          ← newer
                        </button>
                        <button
                          type="button"
                          onClick={() => setForgedAckRotation(0)}
                          className={`font-mono text-[10px] px-2 py-0.5 border rounded-sm ${
                            currentRotation === 0
                              ? "bg-red-500/80 text-white border-red-500"
                              : "bg-background/40 border-red-500/30 hover:bg-background/70"
                          }`}
                          data-testid="btn-ledger-sidecar-forged-history-rotation-0"
                          title="Live forged-ack history (data/hits.txt.lastok.forged-ack.log.jsonl)"
                        >
                          live
                        </button>
                        {rotations.map((r) => {
                          const isNextDrop = r.index === nextDropIdx;
                          return (
                            <button
                              key={`forged-ack-rot-${r.index}`}
                              type="button"
                              onClick={() => setForgedAckRotation(r.index)}
                              className={`font-mono text-[10px] px-2 py-0.5 border rounded-sm ${
                                currentRotation === r.index
                                  ? "bg-red-500/80 text-white border-red-500"
                                  : isNextDrop
                                    ? "bg-amber-500/10 border-amber-500/60 hover:bg-amber-500/20"
                                    : "bg-background/40 border-red-500/30 hover:bg-background/70"
                              }`}
                              data-testid={`btn-ledger-sidecar-forged-history-rotation-${r.index}`}
                              data-next-drop={isNextDrop ? "true" : undefined}
                              title={`Rotated archive .${r.index} — ${fmtSize(r.size)}, rotated ${formatTimestamp(r.mtime)}${
                                isNextDrop
                                  ? " — NEXT TO BE DROPPED on the next rotation (at the rotation cap). Off-box it to preserve this evidence."
                                  : ""
                              }`}
                            >
                              .{r.index}
                              {isNextDrop ? (
                                <span
                                  className="ml-1 text-amber-600 dark:text-amber-400"
                                  aria-label="next to be dropped"
                                  data-testid={`badge-ledger-sidecar-forged-history-next-drop-${r.index}`}
                                >
                                  ⚠
                                </span>
                              ) : null}
                            </button>
                          );
                        })}
                        <button
                          type="button"
                          onClick={() =>
                            setForgedAckRotation((r) =>
                              Math.min(maxRotationIdx, r + 1),
                            )
                          }
                          disabled={!canGoOlder}
                          className="font-mono text-[10px] px-2 py-0.5 border border-red-500/30 rounded-sm bg-background/40 hover:bg-background/70 disabled:opacity-40 disabled:cursor-not-allowed"
                          data-testid="btn-ledger-sidecar-forged-history-older"
                          title="Page to the next-older archive"
                        >
                          older →
                        </button>
                        {currentRotation > 0 ? (
                          <span
                            className="font-mono text-[10px] text-red-700/70 dark:text-red-300/70 ml-auto"
                            data-testid="text-ledger-sidecar-forged-history-rotation-hint"
                          >
                            read-only archive
                          </span>
                        ) : (
                          <span
                            className="font-mono text-[10px] text-red-700/70 dark:text-red-300/70 ml-auto"
                            data-testid="text-ledger-sidecar-forged-history-rotation-hint"
                          >
                            {rotations.length} rotated archive
                            {rotations.length === 1 ? "" : "s"} available
                          </span>
                        )}
                      </div>
                    ) : null}
                    {entries.length === 0 ? (
                      <p
                        className="px-2 py-2 font-mono text-[10px] text-red-700/60 dark:text-red-300/60"
                        data-testid="text-ledger-sidecar-forged-history-empty"
                      >
                        archive empty
                      </p>
                    ) : null}
                    {entries.length > 0 &&
                    filteredForgedEntries.length === 0 ? (
                      <p
                        className="px-2 py-2 font-mono text-[10px] text-red-700/60 dark:text-red-300/60"
                        data-testid="text-ledger-sidecar-forged-history-no-match"
                      >
                        No dismissals match the current filter.
                      </p>
                    ) : null}
                    <ul className="divide-y divide-red-500/15">
                      {filteredForgedEntries.map((entry, i) => (
                        <li
                          key={`${entry.acknowledgedAt}-${i}`}
                          className="flex flex-wrap items-center gap-x-3 gap-y-1 px-2 py-1 font-mono text-[10px]"
                          data-testid={`row-ledger-sidecar-forged-history-${i}`}
                          data-payload-sha={entry.payloadSha}
                          data-acked-by={entry.ackedBy ?? ""}
                        >
                          <span className="text-foreground/70 md:w-44">
                            {formatTimestamp(entry.acknowledgedAt)}
                          </span>
                          <span
                            className={
                              entry.ackedBy
                                ? "text-foreground md:w-40 truncate"
                                : "text-muted-foreground italic md:w-40 truncate"
                            }
                            title={
                              entry.ackedBy ??
                              "no operator attribution captured"
                            }
                          >
                            {entry.ackedBy ?? "anonymous"}
                          </span>
                          <span
                            className="text-muted-foreground truncate"
                            title={`payloadSha: ${entry.payloadSha}`}
                          >
                            payload {entry.payloadSha.slice(0, 12)}…
                          </span>
                        </li>
                      ))}
                    </ul>
                  </div>
                );
              })()}
            </div>
          ) : ledgerIntegrity?.lastOkSidecarStatus ===
            "stale_checkpoint_binding" ? (
            <div
              className="border border-amber-500/50 bg-amber-500/10 p-3 font-mono text-xs space-y-1 text-amber-700 dark:text-amber-400"
              data-testid="panel-ledger-sidecar-stale-binding"
              data-acknowledged={
                ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt
                  ? "true"
                  : "false"
              }
            >
              <div
                className="font-bold uppercase tracking-wider flex items-center gap-2 flex-wrap"
                data-testid="text-ledger-sidecar-stale-binding"
              >
                <ShieldAlert className="w-3 h-3" />
                Stale checkpoint binding
                {ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt ? (
                  <span
                    className="text-[10px] uppercase tracking-wider border border-amber-500/40 bg-amber-500/20 px-1.5 py-0.5"
                    data-testid="badge-ledger-sidecar-stale-binding-acknowledged"
                    data-acked-by={
                      ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy ?? ""
                    }
                    title={
                      ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy
                        ? `Acknowledged by ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedBy} at ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedAt}`
                        : `Acknowledged at ${ledgerIntegrity.lastOkSidecarStatusAcknowledgedAt}`
                    }
                  >
                    acknowledged
                    {ledgerIntegrity?.lastOkSidecarStatusAcknowledgedBy ? (
                      <span className="normal-case lowercase tracking-normal ml-1 opacity-80">
                        · {ledgerIntegrity.lastOkSidecarStatusAcknowledgedBy}
                      </span>
                    ) : null}
                  </span>
                ) : null}
              </div>
              <div className="whitespace-pre-wrap text-foreground/90">
                The persisted{" "}
                <span className="text-foreground">data/hits.txt.lastok</span>{" "}
                sidecar passed HMAC verification but is bound to a different
                checkpoint than the one currently on disk. The stale lastOkAt
                has been discarded (reset to null) so the dashboard never shows
                a "verified ok" time that belongs to an older ledger snapshot.
              </div>
              <div className="text-foreground/70">
                Recommended: re-verify the ledger from a fresh checkout to
                re-seal the sidecar against the current checkpoint, which
                clears this banner.
              </div>
              {rebuildToken ? (
                <div className="flex items-center gap-2 pt-1 flex-wrap">
                  <button
                    type="button"
                    className="border border-amber-500/40 bg-amber-500/10 hover:bg-amber-500/20 disabled:opacity-50 disabled:cursor-not-allowed px-2 py-1 text-[11px] uppercase tracking-wider text-amber-700 dark:text-amber-300"
                    data-testid="button-ack-ledger-sidecar-stale-binding"
                    disabled={
                      ackSidecarStaleBindingMutation.isPending ||
                      Boolean(
                        ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt,
                      )
                    }
                    onClick={() => {
                      setSidecarStaleBindingAckError(null);
                      ackSidecarStaleBindingMutation.mutate(undefined, {
                        onSuccess: () => {
                          void queryClient.invalidateQueries({
                            queryKey: getGetLedgerIntegrityQueryKey(),
                          });
                        },
                        onError: (err: unknown) => {
                          const msg =
                            err instanceof Error
                              ? err.message
                              : "Failed to acknowledge stale checkpoint binding banner.";
                          setSidecarStaleBindingAckError(msg);
                        },
                      });
                    }}
                  >
                    {ackSidecarStaleBindingMutation.isPending
                      ? "Acknowledging…"
                      : ledgerIntegrity?.lastOkSidecarStatusAcknowledgedAt
                        ? "Acknowledged"
                        : "Acknowledge"}
                  </button>
                  <span className="text-[10px] text-muted-foreground">
                    Acknowledge keeps the banner sticky (with this badge) until
                    a re-verify re-seals the sidecar against the current
                    checkpoint.
                  </span>
                </div>
              ) : (
                <div
                  className="text-[10px] text-muted-foreground pt-1"
                  data-testid="hint-ack-ledger-sidecar-stale-binding-no-token"
                >
                  Paste a referee rebuild token in the Lean 4 Verification
                  card to enable the Acknowledge button.
                </div>
              )}
              {sidecarStaleBindingAckError ? (
                <div
                  className="text-[11px] text-amber-700 dark:text-amber-300"
                  data-testid="text-ack-ledger-sidecar-stale-binding-error"
                >
                  {sidecarStaleBindingAckError}
                </div>
              ) : null}
              {(() => {
                // Task #231: prior stale-checkpoint-binding dismissals
                // from the rotating history log. The single-incident
                // sidecar only carries the current incident's ack, so
                // this panel is what operators investigating a recurring
                // stale binding rely on to see who dismissed earlier
                // banners — mirrors the forged-sidecar "Recent
                // dismissals" panel, with prev/next paging into the
                // rotated archives.
                const entries = staleBindingAckHistory?.entries ?? [];
                const rotations = staleBindingAckHistory?.rotations ?? [];
                const currentRotation =
                  staleBindingAckHistory?.rotation ?? staleBindingAckRotation;
                // Hide the whole panel when there is nothing to show
                // anywhere — neither live entries nor any rotated
                // archive on disk.
                if (entries.length === 0 && rotations.length === 0) {
                  return null;
                }
                const capacity =
                  staleBindingAckHistory?.capacity ?? entries.length;
                const maxRotationIdx = rotations.reduce(
                  (m, r) => (r.index > m ? r.index : m),
                  0,
                );
                const canGoOlder = currentRotation < maxRotationIdx;
                const canGoNewer = currentRotation > 0;
                const fmtSize = (n: number): string => {
                  if (n < 1024) return `${n} B`;
                  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
                  return `${(n / (1024 * 1024)).toFixed(2)} MB`;
                };
                return (
                  <div
                    className="border border-amber-500/30 bg-background/40 mt-2"
                    data-testid="panel-ledger-sidecar-stale-binding-history"
                    data-rotation={currentRotation}
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2 px-2 py-1 border-b border-amber-500/20">
                      <span className="font-mono text-[10px] uppercase tracking-wider text-amber-700/80 dark:text-amber-300/80">
                        Recent dismissals
                        {currentRotation > 0 ? (
                          <span
                            className="ml-2 normal-case tracking-normal text-amber-700/60 dark:text-amber-300/60"
                            data-testid="text-ledger-sidecar-stale-binding-history-archive-label"
                          >
                            (archive .{currentRotation})
                          </span>
                        ) : null}
                      </span>
                      <div className="flex items-center gap-2">
                        <label
                          htmlFor="ledger-sidecar-stale-binding-history-referee-filter"
                          className="font-mono text-[10px] uppercase tracking-wider text-amber-700/80 dark:text-amber-300/80"
                        >
                          Referee
                        </label>
                        <select
                          id="ledger-sidecar-stale-binding-history-referee-filter"
                          value={staleBindingHistoryRefereeFilter}
                          onChange={(e) =>
                            setStaleBindingHistoryRefereeFilter(e.target.value)
                          }
                          className="font-mono text-[10px] bg-background border border-amber-500/30 px-1.5 py-0.5"
                          data-testid="select-ledger-sidecar-stale-binding-history-referee-filter"
                        >
                          <option value="">all</option>
                          {staleBindingRefereeSummaries.map((s) => (
                            <option key={s.key} value={s.key}>
                              {refereeLabel(s.key)} ({s.total})
                            </option>
                          ))}
                        </select>
                        {staleBindingHistoryRefereeFilter ? (
                          <button
                            type="button"
                            onClick={() =>
                              setStaleBindingHistoryRefereeFilter("")
                            }
                            className="font-mono text-[10px] underline text-amber-700/70 dark:text-amber-300/70 hover:text-amber-700 dark:hover:text-amber-300"
                            data-testid="button-ledger-sidecar-stale-binding-history-clear-filter"
                          >
                            clear
                          </button>
                        ) : null}
                        <span
                          className="font-mono text-[10px] text-amber-700/70 dark:text-amber-300/70"
                          data-testid="text-ledger-sidecar-stale-binding-history-count"
                        >
                          {staleBindingHistoryRefereeFilter
                            ? `${filteredStaleBindingEntries.length} of ${entries.length}`
                            : `${entries.length} of last ${capacity}`}
                        </span>
                      </div>
                    </div>
                    {rotations.length > 0 ? (
                      <div
                        className="flex flex-wrap items-center gap-2 px-2 py-1 border-b border-amber-500/20 bg-amber-500/5"
                        data-testid="panel-ledger-sidecar-stale-binding-history-rotations"
                      >
                        <button
                          type="button"
                          onClick={() =>
                            setStaleBindingAckRotation((r) =>
                              Math.max(0, r - 1),
                            )
                          }
                          disabled={!canGoNewer}
                          className="font-mono text-[10px] px-2 py-0.5 border border-amber-500/30 rounded-sm bg-background/40 hover:bg-background/70 disabled:opacity-40 disabled:cursor-not-allowed"
                          data-testid="btn-ledger-sidecar-stale-binding-history-newer"
                          title="Page to the newer archive (or back to the live file)"
                        >
                          ← newer
                        </button>
                        <button
                          type="button"
                          onClick={() => setStaleBindingAckRotation(0)}
                          className={`font-mono text-[10px] px-2 py-0.5 border rounded-sm ${
                            currentRotation === 0
                              ? "bg-amber-500/80 text-white border-amber-500"
                              : "bg-background/40 border-amber-500/30 hover:bg-background/70"
                          }`}
                          data-testid="btn-ledger-sidecar-stale-binding-history-rotation-0"
                          title="Live stale-binding-ack history (data/hits.txt.lastok.stale-binding-ack.log.jsonl)"
                        >
                          live
                        </button>
                        {rotations.map((r) => (
                          <button
                            key={`stale-binding-ack-rot-${r.index}`}
                            type="button"
                            onClick={() => setStaleBindingAckRotation(r.index)}
                            className={`font-mono text-[10px] px-2 py-0.5 border rounded-sm ${
                              currentRotation === r.index
                                ? "bg-amber-500/80 text-white border-amber-500"
                                : "bg-background/40 border-amber-500/30 hover:bg-background/70"
                            }`}
                            data-testid={`btn-ledger-sidecar-stale-binding-history-rotation-${r.index}`}
                            title={`Rotated archive .${r.index} — ${fmtSize(r.size)}, rotated ${formatTimestamp(r.mtime)}`}
                          >
                            .{r.index}
                          </button>
                        ))}
                        <button
                          type="button"
                          onClick={() =>
                            setStaleBindingAckRotation((r) =>
                              Math.min(maxRotationIdx, r + 1),
                            )
                          }
                          disabled={!canGoOlder}
                          className="font-mono text-[10px] px-2 py-0.5 border border-amber-500/30 rounded-sm bg-background/40 hover:bg-background/70 disabled:opacity-40 disabled:cursor-not-allowed"
                          data-testid="btn-ledger-sidecar-stale-binding-history-older"
                          title="Page to the next-older archive"
                        >
                          older →
                        </button>
                        {currentRotation > 0 ? (
                          <span
                            className="font-mono text-[10px] text-amber-700/70 dark:text-amber-300/70 ml-auto"
                            data-testid="text-ledger-sidecar-stale-binding-history-rotation-hint"
                          >
                            read-only archive
                          </span>
                        ) : (
                          <span
                            className="font-mono text-[10px] text-amber-700/70 dark:text-amber-300/70 ml-auto"
                            data-testid="text-ledger-sidecar-stale-binding-history-rotation-hint"
                          >
                            {rotations.length} rotated archive
                            {rotations.length === 1 ? "" : "s"} available
                          </span>
                        )}
                      </div>
                    ) : null}
                    {entries.length === 0 ? (
                      <p
                        className="px-2 py-2 font-mono text-[10px] text-amber-700/60 dark:text-amber-300/60"
                        data-testid="text-ledger-sidecar-stale-binding-history-empty"
                      >
                        archive empty
                      </p>
                    ) : null}
                    {entries.length > 0 &&
                    filteredStaleBindingEntries.length === 0 ? (
                      <p
                        className="px-2 py-2 font-mono text-[10px] text-amber-700/60 dark:text-amber-300/60"
                        data-testid="text-ledger-sidecar-stale-binding-history-no-match"
                      >
                        No dismissals match the current filter.
                      </p>
                    ) : null}
                    <ul className="divide-y divide-amber-500/15">
                      {filteredStaleBindingEntries.map((entry, i) => (
                        <li
                          key={`${entry.acknowledgedAt}-${i}`}
                          className="flex flex-wrap items-center gap-x-3 gap-y-1 px-2 py-1 font-mono text-[10px]"
                          data-testid={`row-ledger-sidecar-stale-binding-history-${i}`}
                          data-bound-checkpoint-sha={entry.boundCheckpointSha ?? ""}
                          data-acked-by={entry.ackedBy ?? ""}
                        >
                          <span className="text-foreground/70 md:w-44">
                            {formatTimestamp(entry.acknowledgedAt)}
                          </span>
                          <span
                            className={
                              entry.ackedBy
                                ? "text-foreground md:w-40 truncate"
                                : "text-muted-foreground italic md:w-40 truncate"
                            }
                            title={
                              entry.ackedBy ??
                              "no operator attribution captured"
                            }
                          >
                            {entry.ackedBy ?? "anonymous"}
                          </span>
                          <span
                            className="text-muted-foreground truncate"
                            title={
                              entry.boundCheckpointSha
                                ? `boundCheckpointSha: ${entry.boundCheckpointSha}`
                                : "no checkpoint was on disk when the sidecar was sealed"
                            }
                          >
                            {entry.boundCheckpointSha
                              ? `checkpoint ${entry.boundCheckpointSha.slice(0, 12)}…`
                              : "no checkpoint"}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </div>
                );
              })()}
            </div>
          ) : null}

          {(() => {
            const isStale =
              ledgerIntegrity?.status === "ok" && ledgerIntegrity?.stale === true;
            const thresholdSec = ledgerIntegrity?.staleThresholdSeconds ?? null;
            const fmtAge = (sec: number | null | undefined): string | null => {
              if (sec == null) return null;
              if (sec >= 86400) return `${Math.round(sec / 86400)}d`;
              if (sec >= 3600) return `${Math.round(sec / 3600)}h`;
              if (sec >= 60) return `${Math.round(sec / 60)}m`;
              return `${sec}s`;
            };
            const thresholdLabel = fmtAge(thresholdSec);
            return (
              <p
                className={`text-xs font-mono ${
                  isStale
                    ? "border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                    : "text-muted-foreground"
                }`}
                data-testid="text-ledger-last-ok"
                data-stale={isStale ? "true" : "false"}
                title={
                  ledgerIntegrity?.lastOkAt
                    ? `last verified ok at ${ledgerIntegrity.lastOkAt}`
                    : "no successful verification recorded since the server started"
                }
              >
                last verified ok:{" "}
                <span className={isStale ? "" : "text-foreground"}>
                  {formatRelativeAge(ledgerIntegrity?.lastOkAt ?? null, nowMs)}
                </span>
                {thresholdLabel ? (
                  <span
                    className="ml-2 text-muted-foreground"
                    data-testid="text-ledger-stale-threshold"
                  >
                    (stale &gt; {thresholdLabel})
                  </span>
                ) : null}
                {isStale ? (
                  <span
                    className="ml-2 font-bold uppercase tracking-wider"
                    data-testid="badge-ledger-stale"
                  >
                    STALE — verifier may have stopped
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #99: surface "verifier itself hasn't even *run* in
            // too long". Distinct from `stale` (which is about
            // `lastOkAt` — last *successful* check) — this one is
            // about `lastCheckedAt` (last *attempted* check) and
            // catches the blind spot where the background monitor
            // silently stops ticking while `lastOkAt` quietly drifts.
            if (!ledgerIntegrity) return null;
            const checkedStale = ledgerIntegrity.checkedStale === true;
            const ageSec =
              ledgerIntegrity.lastCheckedAgeSeconds ?? null;
            const thrSec =
              ledgerIntegrity.checkedStaleThresholdSeconds ?? null;
            const fmt = (sec: number | null): string | null => {
              if (sec == null) return null;
              if (sec >= 86400) return `${Math.round(sec / 86400)}d`;
              if (sec >= 3600) return `${Math.round(sec / 3600)}h`;
              if (sec >= 60) return `${Math.round(sec / 60)}m`;
              return `${sec}s`;
            };
            const ageLabel = fmt(ageSec);
            const thrLabel = fmt(thrSec);
            return (
              <p
                className={`text-xs font-mono ${
                  checkedStale
                    ? "border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                    : "text-muted-foreground"
                }`}
                data-testid="text-ledger-last-checked"
                data-checked-stale={checkedStale ? "true" : "false"}
                title={
                  ledgerIntegrity.lastCheckedAt
                    ? `verifier last attempted a check at ${ledgerIntegrity.lastCheckedAt}`
                    : "no check has ever been attempted on this deploy"
                }
              >
                last attempted check:{" "}
                <span className={checkedStale ? "" : "text-foreground"}>
                  {ageLabel == null
                    ? "never"
                    : ageSec === 0
                      ? "just now"
                      : `${ageLabel} ago`}
                </span>
                {thrLabel ? (
                  <span
                    className="ml-2 text-muted-foreground"
                    data-testid="text-ledger-checked-threshold"
                  >
                    (stale &gt; {thrLabel})
                  </span>
                ) : null}
                {checkedStale ? (
                  <span
                    className="ml-2 font-bold uppercase tracking-wider"
                    data-testid="badge-ledger-checked-stale"
                  >
                    VERIFIER NOT RUNNING — no recent attempt
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #96: checkpoint-sidecar staleness. Distinct from
            // `stale` (verifier-not-running) — this flags that the
            // committed known-good prefix hasn't been re-rolled in too
            // long, so tamper coverage of the live ledger is shrinking.
            if (!ledgerIntegrity) return null;
            const cpStale = ledgerIntegrity.checkpointStale === true;
            const cpAge = ledgerIntegrity.checkpointAgeSeconds ?? null;
            const cpThr =
              ledgerIntegrity.checkpointStaleThresholdSeconds ?? null;
            const cov = ledgerIntegrity.checkpointCoverageRatio ?? null;
            const fmt = (sec: number | null): string | null => {
              if (sec == null) return null;
              if (sec >= 86400) return `${Math.round(sec / 86400)}d`;
              if (sec >= 3600) return `${Math.round(sec / 3600)}h`;
              if (sec >= 60) return `${Math.round(sec / 60)}m`;
              return `${sec}s`;
            };
            const ageLabel = fmt(cpAge) ?? "unknown";
            const thrLabel = fmt(cpThr);
            const covPct =
              cov != null ? `${(cov * 100).toFixed(1)}%` : null;
            return (
              <p
                className={`text-xs font-mono ${
                  cpStale
                    ? "border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                    : "text-muted-foreground"
                }`}
                data-testid="text-ledger-checkpoint-age"
                data-checkpoint-stale={cpStale ? "true" : "false"}
                title={
                  ledgerIntegrity.checkpointLastModified
                    ? `checkpoint last re-rolled at ${ledgerIntegrity.checkpointLastModified}`
                    : "checkpoint sidecar is missing or unreadable"
                }
              >
                checkpoint re-rolled:{" "}
                <span className={cpStale ? "" : "text-foreground"}>
                  {ageLabel === "unknown" ? "never" : `${ageLabel} ago`}
                </span>
                {thrLabel ? (
                  <span
                    className="ml-2 text-muted-foreground"
                    data-testid="text-ledger-checkpoint-threshold"
                  >
                    (stale &gt; {thrLabel})
                  </span>
                ) : null}
                {covPct ? (
                  <span
                    className="ml-2 text-muted-foreground"
                    data-testid="text-ledger-checkpoint-coverage"
                  >
                    coverage {covPct}
                  </span>
                ) : null}
                {cpStale ? (
                  <span
                    className="ml-2 font-bold uppercase tracking-wider"
                    data-testid="badge-ledger-checkpoint-stale"
                  >
                    CHECKPOINT STALE — re-roll the sealed prefix
                  </span>
                ) : null}
                {cpStale && rebuildToken ? (
                  <span className="mt-2 flex flex-col gap-2 normal-case">
                    <span className="flex flex-wrap items-center gap-2">
                      <button
                        type="button"
                        className="border border-amber-500/50 bg-amber-500/10 hover:bg-amber-500/20 text-amber-700 dark:text-amber-300 px-2 py-1 text-xs disabled:opacity-50 disabled:cursor-not-allowed"
                        data-testid="button-reroll-checkpoint"
                        disabled={isRerollingCheckpoint || rerollCheckpointMutation.isPending}
                        onClick={async () => {
                          setRerollCheckpointError(null);
                          setRerollLogLines([]);
                          setIsRerollingCheckpoint(true);
                          const controller = new AbortController();
                          rerollAbortRef.current = controller;
                          try {
                            const outcome = await streamReroll(
                              rebuildToken,
                              refereeName,
                              (line) =>
                                setRerollLogLines((prev) => [...prev, line]),
                              controller.signal,
                            );
                            if (outcome.kind === "result" && outcome.payload.ok) {
                              queryClient.invalidateQueries({
                                queryKey: getGetLedgerIntegrityQueryKey(),
                              });
                              queryClient.invalidateQueries({
                                queryKey: getGetLedgerAlertsQueryKey(),
                              });
                              queryClient.invalidateQueries({
                                queryKey: getGetLedgerCheckpointRerollHistoryQueryKey(),
                              });
                            } else if (outcome.kind === "result") {
                              setRerollCheckpointError(
                                outcome.payload.error ??
                                  (outcome.payload.stderr
                                    ? outcome.payload.stderr.trim()
                                    : null) ??
                                  "Re-roll failed (no error returned).",
                              );
                              queryClient.invalidateQueries({
                                queryKey: getGetLedgerCheckpointRerollHistoryQueryKey(),
                              });
                            } else {
                              setRerollCheckpointError(outcome.error);
                            }
                          } finally {
                            setIsRerollingCheckpoint(false);
                            rerollAbortRef.current = null;
                          }
                        }}
                      >
                        {isRerollingCheckpoint
                          ? "Re-rolling..."
                          : "Re-roll checkpoint"}
                      </button>
                      {isRerollingCheckpoint ? (
                        <span
                          className="font-mono text-[11px] text-muted-foreground"
                          data-testid="text-reroll-checkpoint-progress"
                        >
                          Streaming reroll-checkpoint.py — {rerollLogLines.length} line
                          {rerollLogLines.length === 1 ? "" : "s"} so far.
                        </span>
                      ) : null}
                      {rerollCheckpointError ? (
                        <span
                          className="text-red-700 dark:text-red-400 normal-case"
                          data-testid="text-reroll-checkpoint-error"
                        >
                          {rerollCheckpointError}
                        </span>
                      ) : null}
                    </span>
                    {(isRerollingCheckpoint || rerollLogLines.length > 0) ? (
                      <div
                        className="border border-border bg-black/90 dark:bg-black/70"
                        data-testid="panel-reroll-live-log"
                      >
                        <div className="flex items-center justify-between px-3 py-1.5 border-b border-border bg-muted/30">
                          <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                            Live re-roll output
                          </span>
                          <span
                            className="font-mono text-[11px] text-muted-foreground"
                            data-testid="text-reroll-line-count"
                          >
                            {rerollLogLines.length} line
                            {rerollLogLines.length === 1 ? "" : "s"}
                            {isRerollingCheckpoint ? " · streaming…" : ""}
                          </span>
                        </div>
                        <pre
                          className="max-h-48 overflow-auto px-3 py-2 font-mono text-[11px] leading-relaxed text-green-300 whitespace-pre-wrap"
                          data-testid="text-reroll-live-log"
                        >
                          {rerollLogLines.length === 0
                            ? "Waiting for output…"
                            : rerollLogLines
                                .map((l) =>
                                  l.stream === "stderr" ? `! ${l.line}` : l.line,
                                )
                                .join("\n")}
                        </pre>
                      </div>
                    ) : null}
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #141: persistent audit trail of checkpoint re-rolls.
            // Mirrors the rebuild-history panel above so referees can
            // see who re-rolled the sealed prefix, when, from which IP,
            // and whether the attempt succeeded — across restarts.
            const entries = checkpointRerollHistory?.entries ?? [];
            if (entries.length === 0) return null;
            const capacity = checkpointRerollHistory?.capacity ?? entries.length;
            return (
              <div
                className="border border-border bg-muted/20"
                data-testid="panel-checkpoint-reroll-history"
              >
                <div className="flex flex-wrap items-center justify-between gap-2 px-3 py-1.5 border-b border-border bg-muted/30">
                  <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                    Recent checkpoint re-rolls
                  </span>
                  <div className="flex items-center gap-2">
                    <label
                      htmlFor="checkpoint-reroll-history-referee-filter"
                      className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground"
                    >
                      Referee
                    </label>
                    <select
                      id="checkpoint-reroll-history-referee-filter"
                      value={rerollHistoryRefereeFilter}
                      onChange={(e) =>
                        setRerollHistoryRefereeFilter(e.target.value)
                      }
                      className="font-mono text-[11px] bg-background border border-border px-1.5 py-0.5"
                      data-testid="select-checkpoint-reroll-history-referee-filter"
                    >
                      <option value="">all</option>
                      {rerollRefereeSummaries.map((s) => (
                        <option key={s.key} value={s.key}>
                          {refereeLabel(s.key)} ({s.total})
                        </option>
                      ))}
                    </select>
                    {rerollHistoryRefereeFilter ? (
                      <button
                        type="button"
                        onClick={() => setRerollHistoryRefereeFilter("")}
                        className="font-mono text-[11px] underline text-muted-foreground hover:text-foreground"
                        data-testid="button-checkpoint-reroll-history-clear-filter"
                      >
                        clear
                      </button>
                    ) : null}
                    <span
                      className="font-mono text-[11px] text-muted-foreground"
                      data-testid="text-checkpoint-reroll-history-count"
                    >
                      {rerollHistoryRefereeFilter
                        ? `${filteredRerollEntries.length} of ${entries.length}`
                        : `${entries.length} of last ${capacity}`}
                    </span>
                  </div>
                </div>
                {rerollRefereeSummaries.length > 0 ? (
                  <ul
                    className="divide-y divide-border border-b border-border bg-muted/10"
                    data-testid="list-checkpoint-reroll-history-referee-summary"
                  >
                    {rerollRefereeSummaries.map((s) => {
                      const isActive = rerollHistoryRefereeFilter === s.key;
                      return (
                        <li
                          key={s.key}
                          className={`flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-1.5 font-mono text-[11px] ${
                            isActive ? "bg-muted/40" : ""
                          }`}
                          data-testid={`row-checkpoint-reroll-history-summary-${s.key}`}
                        >
                          <button
                            type="button"
                            onClick={() =>
                              setRerollHistoryRefereeFilter(
                                isActive ? "" : s.key,
                              )
                            }
                            className={`md:w-40 truncate text-left underline-offset-2 hover:underline ${
                              s.key === ANONYMOUS_KEY
                                ? "text-muted-foreground italic"
                                : "text-foreground"
                            } ${isActive ? "font-bold" : ""}`}
                            title={
                              isActive
                                ? "Click to clear filter"
                                : `Filter to ${refereeLabel(s.key)}`
                            }
                            data-testid={`button-checkpoint-reroll-history-summary-${s.key}`}
                          >
                            {refereeLabel(s.key)}
                          </button>
                          <span className="text-muted-foreground md:w-16">
                            {s.total} total
                          </span>
                          <span className="text-green-700 dark:text-green-400 md:w-16">
                            {s.ok} ok
                          </span>
                          <span className="text-red-700 dark:text-red-400 md:w-16">
                            {s.fail} fail
                          </span>
                          <span className="text-muted-foreground">
                            last ok:{" "}
                            {s.lastOk ? formatTimestamp(s.lastOk) : "—"}
                          </span>
                          <span className="text-muted-foreground">
                            last fail:{" "}
                            {s.lastFail ? formatTimestamp(s.lastFail) : "—"}
                          </span>
                        </li>
                      );
                    })}
                  </ul>
                ) : null}
                {filteredRerollEntries.length === 0 ? (
                  <p
                    className="px-3 py-2 font-mono text-[11px] text-muted-foreground italic"
                    data-testid="text-checkpoint-reroll-history-empty"
                  >
                    No checkpoint re-rolls match the current filter.
                  </p>
                ) : null}
                <ul className="divide-y divide-border">
                  {filteredRerollEntries.map((entry, i) => (
                    <li
                      key={`${entry.timestamp}-${i}`}
                      className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-1.5 font-mono text-[11px]"
                      data-testid={`row-checkpoint-reroll-history-${i}`}
                      data-reroll-ok={entry.ok ? "true" : "false"}
                    >
                      <span
                        className={
                          entry.ok
                            ? "text-green-700 dark:text-green-400 md:w-12"
                            : "text-red-700 dark:text-red-400 md:w-12"
                        }
                      >
                        {entry.ok ? "ok" : "fail"}
                      </span>
                      <span className="text-muted-foreground md:w-44">
                        {formatTimestamp(entry.timestamp)}
                      </span>
                      <span className="text-muted-foreground md:w-20">
                        {entry.durationMs}ms
                      </span>
                      <span
                        className={
                          entry.refereeName
                            ? "text-foreground md:w-40 truncate"
                            : "text-muted-foreground italic md:w-40 truncate"
                        }
                        title={
                          entry.refereeName ?? "no referee attribution supplied"
                        }
                      >
                        {entry.refereeName ?? "anonymous"}
                      </span>
                      <span
                        className="text-muted-foreground md:w-32 truncate"
                        title={entry.ip ?? "no client ip captured"}
                      >
                        {entry.ip ?? "—"}
                      </span>
                      {entry.error ? (
                        <span
                          className="text-red-700 dark:text-red-400 flex-1 min-w-0 truncate"
                          title={entry.error}
                          data-testid={`text-checkpoint-reroll-history-error-${i}`}
                        >
                          {entry.error}
                        </span>
                      ) : null}
                    </li>
                  ))}
                </ul>
              </div>
            );
          })()}

          {(() => {
            // Task #199: re-roll digest panel. The daily digest only
            // goes out as email/webhook; this surfaces the same
            // per-referee ok/fail rollup (recomputed on demand for the
            // chosen window) so operators can scan trends in the UI.
            const windows: GetLedgerCheckpointRerollDigestWindow[] = [
              GetLedgerCheckpointRerollDigestWindow["24h"],
              GetLedgerCheckpointRerollDigestWindow["7d"],
              GetLedgerCheckpointRerollDigestWindow["30d"],
            ];
            const perReferee = rerollDigest?.perReferee ?? [];
            const failures = rerollDigest?.failures ?? [];
            return (
              <div
                className="border border-border bg-muted/20"
                data-testid="panel-checkpoint-reroll-digest"
              >
                <div className="flex flex-wrap items-center justify-between gap-2 px-3 py-1.5 border-b border-border bg-muted/30">
                  <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                    Re-roll digest
                  </span>
                  <div className="flex items-center gap-1">
                    {windows.map((w) => {
                      const isActive = rerollDigestWindow === w;
                      return (
                        <button
                          key={w}
                          type="button"
                          onClick={() => setRerollDigestWindow(w)}
                          className={`font-mono text-[11px] px-1.5 py-0.5 border ${
                            isActive
                              ? "border-foreground bg-muted/60 text-foreground font-bold"
                              : "border-border text-muted-foreground hover:text-foreground"
                          }`}
                          data-testid={`button-reroll-digest-window-${w}`}
                        >
                          {w}
                        </button>
                      );
                    })}
                  </div>
                </div>
                {isRerollDigestError ? (
                  <p
                    className="px-3 py-2 font-mono text-[11px] text-red-700 dark:text-red-400 italic"
                    data-testid="text-reroll-digest-error"
                  >
                    Failed to load digest. Retrying…
                  </p>
                ) : !rerollDigest ? (
                  <p
                    className="px-3 py-2 font-mono text-[11px] text-muted-foreground italic"
                    data-testid="text-reroll-digest-loading"
                  >
                    Loading digest…
                  </p>
                ) : (
                  <>
                    <div
                      className="flex flex-wrap items-center gap-x-4 gap-y-1 px-3 py-1.5 border-b border-border bg-muted/10 font-mono text-[11px]"
                      data-testid="text-reroll-digest-summary"
                    >
                      <span className="text-muted-foreground">
                        {rerollDigest.totalAttempts} attempts
                      </span>
                      <span className="text-green-700 dark:text-green-400">
                        {rerollDigest.okCount} ok
                      </span>
                      <span className="text-red-700 dark:text-red-400">
                        {rerollDigest.failCount} fail
                      </span>
                      <span className="text-muted-foreground">
                        over last {rerollDigest.windowHours}h
                      </span>
                    </div>
                    <RerollDigestChart buckets={rerollDigest.buckets} />
                    {perReferee.length === 0 ? (
                      <p
                        className="px-3 py-2 font-mono text-[11px] text-muted-foreground italic"
                        data-testid="text-reroll-digest-empty"
                      >
                        No checkpoint re-roll attempts in this window.
                      </p>
                    ) : (
                      <ul
                        className="divide-y divide-border"
                        data-testid="list-reroll-digest-per-referee"
                      >
                        {perReferee.map((p, i) => (
                          <li
                            key={`${p.refereeName}-${i}`}
                            className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-1.5 font-mono text-[11px]"
                            data-testid={`row-reroll-digest-referee-${i}`}
                          >
                            <span className="md:w-44 truncate text-foreground">
                              {p.refereeName}
                            </span>
                            <span className="text-green-700 dark:text-green-400 md:w-16">
                              {p.okCount} ok
                            </span>
                            <span className="text-red-700 dark:text-red-400 md:w-16">
                              {p.failCount} fail
                            </span>
                          </li>
                        ))}
                      </ul>
                    )}
                    {failures.length > 0 ? (
                      <div
                        className="border-t border-border"
                        data-testid="list-reroll-digest-failures"
                      >
                        <div className="px-3 py-1 bg-red-50 dark:bg-red-950/30 font-mono text-[11px] uppercase tracking-wider text-red-700 dark:text-red-400">
                          {failures.length} failure
                          {failures.length === 1 ? "" : "s"}
                        </div>
                        <ul className="divide-y divide-border">
                          {failures.map((f, i) => (
                            <li
                              key={`${f.timestamp}-${i}`}
                              className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-1.5 font-mono text-[11px]"
                              data-testid={`row-reroll-digest-failure-${i}`}
                            >
                              <span className="text-muted-foreground md:w-44">
                                {formatTimestamp(f.timestamp)}
                              </span>
                              <span
                                className={
                                  f.refereeName
                                    ? "text-foreground md:w-40 truncate"
                                    : "text-muted-foreground italic md:w-40 truncate"
                                }
                              >
                                {f.refereeName ?? "anonymous"}
                              </span>
                              {f.error ? (
                                <span
                                  className="text-red-700 dark:text-red-400 flex-1 min-w-0 truncate"
                                  title={f.error}
                                >
                                  {f.error}
                                </span>
                              ) : null}
                            </li>
                          ))}
                        </ul>
                      </div>
                    ) : null}
                  </>
                )}
              </div>
            );
          })()}

          {(() => {
            // Task #97: surface the background ledger-integrity
            // monitor — operators can see at a glance that the
            // auto-check is running, when it last ticked, and (red)
            // if the monitor itself looks stalled.
            if (!ledgerIntegrity) return null;
            const m = ledgerIntegrity.monitor;
            const fmt = (sec: number | null): string | null => {
              if (sec == null) return null;
              if (sec >= 86400) return `${Math.round(sec / 86400)}d`;
              if (sec >= 3600) return `${Math.round(sec / 3600)}h`;
              if (sec >= 60) return `${Math.round(sec / 60)}m`;
              return `${sec}s`;
            };
            if (!m || !m.enabled) {
              return (
                <p
                  className="text-xs font-mono border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                  data-testid="text-ledger-monitor"
                  data-monitor-enabled="false"
                >
                  monitor:{" "}
                  <span className="font-bold uppercase tracking-wider">
                    disabled
                  </span>
                  <span className="ml-2 text-muted-foreground">
                    (set LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS to enable
                    the background timer)
                  </span>
                </p>
              );
            }
            const intervalSec = m.intervalSeconds ?? null;
            const lastTickMs = m.lastTickAt
              ? Date.parse(m.lastTickAt)
              : NaN;
            const tickAgeSec =
              Number.isFinite(lastTickMs) && Number.isFinite(nowMs)
                ? Math.max(0, Math.floor((nowMs - lastTickMs) / 1000))
                : null;
            const stalled =
              m.lastTickAt == null ||
              (intervalSec != null &&
                tickAgeSec != null &&
                tickAgeSec > intervalSec * 2);
            const tickLabel =
              m.lastTickAt == null
                ? "never (waiting for first tick)"
                : tickAgeSec == null
                  ? m.lastTickAt
                  : `${fmt(tickAgeSec) ?? `${tickAgeSec}s`} ago`;
            const intervalLabel = fmt(intervalSec);
            return (
              <p
                className={`text-xs font-mono ${
                  stalled
                    ? "border border-red-500/50 bg-red-500/10 text-red-700 dark:text-red-400 px-3 py-2"
                    : "text-muted-foreground"
                }`}
                data-testid="text-ledger-monitor"
                data-monitor-enabled="true"
                data-monitor-stalled={stalled ? "true" : "false"}
                title={
                  m.lastTickAt
                    ? `monitor last completed a tick at ${m.lastTickAt}`
                    : "monitor enabled, no tick has completed yet"
                }
              >
                monitor:{" "}
                <span
                  className={
                    stalled ? "font-bold uppercase tracking-wider" : "text-foreground"
                  }
                >
                  {stalled ? "stalled" : "running"}
                </span>
                <span className="ml-2">
                  last tick{" "}
                  <span className={stalled ? "" : "text-foreground"}>
                    {tickLabel}
                  </span>
                </span>
                {intervalLabel ? (
                  <span
                    className="ml-2 text-muted-foreground"
                    data-testid="text-ledger-monitor-interval"
                  >
                    (every {intervalLabel})
                  </span>
                ) : null}
                {m.lastAlertedFailureMode ? (
                  <span
                    className="ml-2 font-bold uppercase tracking-wider text-red-700 dark:text-red-400"
                    data-testid="text-ledger-monitor-alert"
                  >
                    alerting: {m.lastAlertedFailureMode}
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #223: surface the daily re-roll digest's effective
            // state. Task #198 made the digest short-circuit (logging
            // a line nobody watching the dashboard can see) when no
            // alert sink is configured. Without this panel a
            // misconfigured deployment (interval live, no sink) looks
            // identical to a healthy quiet one or a deliberate
            // interval=off opt-out. Three distinct renderings:
            //  - enabled  → muted "running every Nh, window Nh"
            //  - off      → muted "disabled (interval=off)" — on purpose
            //  - no sink  → amber "disabled (no alert sink)" — fixable
            if (!ledgerIntegrity) return null;
            const d = ledgerIntegrity.rerollDigest;
            if (!d) return null;
            const fmt = (sec: number | null): string | null => {
              if (sec == null) return null;
              if (sec >= 86400) return `${Math.round(sec / 86400)}d`;
              if (sec >= 3600) return `${Math.round(sec / 3600)}h`;
              if (sec >= 60) return `${Math.round(sec / 60)}m`;
              return `${sec}s`;
            };
            if (d.state === "disabled_no_sink") {
              return (
                <p
                  className="text-xs font-mono border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                  data-testid="text-reroll-digest"
                  data-digest-state="disabled_no_sink"
                >
                  re-roll digest:{" "}
                  <span className="font-bold uppercase tracking-wider">
                    disabled
                  </span>
                  <span className="ml-2 text-muted-foreground">
                    (no alert sink — set MORNINGSTAR_ALERT_WEBHOOK_URL or
                    MORNINGSTAR_ALERT_EMAIL_TO to start the digest)
                  </span>
                </p>
              );
            }
            if (d.state === "disabled_interval_off") {
              return (
                <p
                  className="text-xs font-mono text-muted-foreground"
                  data-testid="text-reroll-digest"
                  data-digest-state="disabled_interval_off"
                >
                  re-roll digest:{" "}
                  <span className="uppercase tracking-wider">disabled</span>
                  <span className="ml-2">
                    (MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS=off)
                  </span>
                </p>
              );
            }
            const cadence = fmt(d.intervalSeconds);
            return (
              <p
                className="text-xs font-mono text-muted-foreground"
                data-testid="text-reroll-digest"
                data-digest-state="enabled"
              >
                re-roll digest:{" "}
                <span className="text-foreground">enabled</span>
                {cadence ? (
                  <span
                    className="ml-2"
                    data-testid="text-reroll-digest-cadence"
                  >
                    every <span className="text-foreground">{cadence}</span>
                  </span>
                ) : null}
                {d.windowHours != null ? (
                  <span
                    className="ml-2"
                    data-testid="text-reroll-digest-window"
                  >
                    window{" "}
                    <span className="text-foreground">{d.windowHours}h</span>
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #128: surface the in-process watchdog (task #113)
            // distinctly from the checkedStale badge. checkedStale is
            // derived from the persisted sidecar's lastCheckedAt and
            // survives restarts; watchdogState is purely in-memory
            // and tells operators "the monitor's tick loop has wedged
            // RIGHT NOW (or did at watchdogLastFiredAt)" — a related
            // but distinct signal. A red badge fires while
            // watchdogState === "stalled"; an amber recovered-recently
            // badge fires when the watchdog has previously fired in
            // this process lifetime but has since gone back to ok.
            if (!ledgerIntegrity) return null;
            const m = ledgerIntegrity.monitor;
            if (!m || !m.enabled) return null;
            const wdState = m.watchdogState;
            const wdFiredAt = m.watchdogLastFiredAt;
            if (wdState !== "stalled" && !wdFiredAt) return null;
            const stalled = wdState === "stalled";
            const firedAgo = formatRelativeAge(wdFiredAt, nowMs);
            return (
              <p
                className={`text-xs font-mono px-3 py-2 border ${
                  stalled
                    ? "border-red-500/50 bg-red-500/10 text-red-700 dark:text-red-400"
                    : "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400"
                }`}
                data-testid="text-ledger-monitor-watchdog"
                data-watchdog-state={wdState ?? "ok"}
                data-watchdog-fired-at={wdFiredAt ?? ""}
                title={
                  stalled
                    ? `monitor watchdog fired at ${wdFiredAt ?? "unknown"} — no integrity tick has completed in 2× the configured interval; push alerts on ledger tamper may not fire until the api-server is restarted`
                    : `monitor watchdog previously fired at ${wdFiredAt} but has since recovered — ticks are landing again`
                }
              >
                <span className="font-bold uppercase tracking-wider">
                  {stalled
                    ? "watchdog fired — monitor stalled"
                    : "watchdog recovered"}
                </span>
                {wdFiredAt ? (
                  <span className="ml-2 text-muted-foreground">
                    last fire{" "}
                    <span
                      className="text-foreground"
                      data-testid="text-ledger-monitor-watchdog-fired"
                      title={wdFiredAt}
                    >
                      {firedAgo ?? wdFiredAt}
                    </span>
                  </span>
                ) : null}
              </p>
            );
          })()}

          {(() => {
            // Task #115: when the operator has dismissed the most
            // recent monitor alert via POST /lean/ledger-alerts/ack,
            // `monitor.lastAcknowledgedAlertId` becomes non-null and
            // the monitor holds fire on subsequent non-ok ticks —
            // including failure_mode transitions — until a recovery
            // clears the state. Without a visible cue here, an
            // operator who sees the ledger stay red has no way to
            // tell that the monitor is intentionally silenced rather
            // than broken or stalled.
            if (!ledgerIntegrity) return null;
            const m = ledgerIntegrity.monitor;
            if (!m || !m.enabled) return null;
            const ackedId = m.lastAcknowledgedAlertId;
            if (!ackedId) return null;
            const shortId = ackedId.slice(0, 12);
            const currentFm = ledgerIntegrity.failureMode ?? null;
            const alertedFm = m.lastAlertedFailureMode ?? null;
            // A failure_mode transition while silenced: the live
            // ledger is non-ok and its failureMode no longer matches
            // the failureMode that was acked. lastAlertedFailureMode
            // does not update silently while silenced, so compare
            // against the live failureMode rather than against itself.
            const silencedTransition =
              ledgerIntegrity.status !== "ok" &&
              currentFm != null &&
              alertedFm != null &&
              currentFm !== alertedFm;
            return (
              <p
                className="text-xs font-mono border border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400 px-3 py-2"
                data-testid="text-ledger-monitor-suppressed"
                data-acknowledged-alert-id={ackedId}
                title={`monitor alerts suppressed — operator acknowledged alert ${ackedId} via POST /api/lean/ledger-alerts/ack; the monitor will hold fire on subsequent non-ok ticks until a recovery clears the state`}
              >
                <span className="font-bold uppercase tracking-wider">
                  alerts suppressed — acknowledged
                </span>
                <span className="ml-2 text-muted-foreground">ack id</span>{" "}
                <a
                  href={`#alert-${ackedId}`}
                  className="text-foreground underline decoration-dotted underline-offset-2"
                  data-testid="link-ledger-monitor-ack-id"
                  title={ackedId}
                  onClick={(e) => {
                    // Task #163: route through the shared highlight
                    // helper so click and deep-link load behave the
                    // same. If the row isn't in DOM (acked alerts
                    // toggle is off), let the default hash navigation
                    // through so the URL still records the intent.
                    if (highlightAlertRow(ackedId)) {
                      e.preventDefault();
                    }
                  }}
                >
                  {shortId}…
                </a>
                {alertedFm ? (
                  <span className="ml-2 text-muted-foreground">
                    (last fired:{" "}
                    <span className="text-foreground">{alertedFm}</span>)
                  </span>
                ) : null}
                {silencedTransition ? (
                  <span
                    className="ml-2 font-bold uppercase tracking-wider text-red-700 dark:text-red-400"
                    data-testid="badge-ledger-monitor-silenced-transition"
                    title={`while suppressed, the live ledger failure mode changed from ${alertedFm} to ${currentFm} — the monitor did not re-alert because the previous alert is still acknowledged`}
                  >
                    failure mode changed while silenced → {currentFm}
                  </span>
                ) : null}
              </p>
            );
          })()}

          {ledgerIntegrity && ledgerIntegrity.status !== "ok" ? (
            <div
              className="border border-red-500/50 bg-red-500/10 p-3 font-mono text-xs space-y-1 text-red-700 dark:text-red-400"
              data-testid="panel-ledger-integrity-mismatch"
            >
              <div className="font-bold uppercase tracking-wider">
                {ledgerIntegrity.failureMode ?? "mismatch"}
              </div>
              <div
                className="whitespace-pre-wrap text-foreground/90"
                data-testid="text-ledger-integrity-reason"
              >
                {ledgerIntegrity.reason ?? "Ledger integrity check failed."}
              </div>
              <div className="text-foreground/70">
                Recovery: see{" "}
                <span className="text-foreground">docs/REPRODUCE.md</span> —
                "Recovering data/hits.txt from a tamper or accidental truncation".
              </div>
            </div>
          ) : null}

          {ledgerIntegrity ? (
            <dl
              className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 font-mono text-xs"
              data-testid="panel-ledger-integrity-metrics"
            >
              <div className="flex flex-col gap-0.5">
                <dt className="text-muted-foreground uppercase tracking-wider text-[10px]">
                  Checkpoint size
                </dt>
                <dd
                  className="text-foreground"
                  data-testid="text-ledger-checkpoint-size"
                >
                  {ledgerIntegrity.checkpointSize != null
                    ? `${ledgerIntegrity.checkpointSize.toLocaleString()} B`
                    : "—"}
                </dd>
              </div>
              <div className="flex flex-col gap-0.5">
                <dt className="text-muted-foreground uppercase tracking-wider text-[10px]">
                  Live size
                </dt>
                <dd
                  className="text-foreground"
                  data-testid="text-ledger-live-size"
                >
                  {ledgerIntegrity.liveSize != null
                    ? `${ledgerIntegrity.liveSize.toLocaleString()} B`
                    : "—"}
                  {ledgerIntegrity.growthBytes != null &&
                  ledgerIntegrity.growthBytes > 0 ? (
                    <span className="ml-2 text-muted-foreground">
                      (+{ledgerIntegrity.growthBytes.toLocaleString()} since
                      checkpoint)
                    </span>
                  ) : null}
                </dd>
              </div>
              <div className="flex flex-col gap-0.5 md:col-span-2">
                <dt className="text-muted-foreground uppercase tracking-wider text-[10px]">
                  Checkpoint sha256
                </dt>
                <dd data-testid="text-ledger-checkpoint-sha">
                  {ledgerIntegrity.checkpointSha ? (
                    <ShaChip sha={ledgerIntegrity.checkpointSha} />
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </dd>
              </div>
              <div className="flex flex-col gap-0.5">
                <dt className="text-muted-foreground uppercase tracking-wider text-[10px]">
                  Last checked
                </dt>
                <dd
                  className="text-foreground"
                  data-testid="text-ledger-checked-at"
                  title={
                    ledgerIntegrity.lastCheckedAt
                      ? `persisted across server restarts; previous check at ${ledgerIntegrity.lastCheckedAt}`
                      : undefined
                  }
                >
                  {formatTimestamp(ledgerIntegrity.checkedAt)}
                </dd>
              </div>
              <div className="flex flex-col gap-0.5">
                <dt className="text-muted-foreground uppercase tracking-wider text-[10px]">
                  Ledger mtime
                </dt>
                <dd
                  className="text-foreground"
                  data-testid="text-ledger-mtime"
                >
                  {ledgerIntegrity.ledgerLastModified
                    ? formatTimestamp(ledgerIntegrity.ledgerLastModified)
                    : "—"}
                </dd>
              </div>
            </dl>
          ) : ledgerIntegrityError ? (
            <p
              className="text-xs font-mono text-amber-700 dark:text-amber-400"
              data-testid="text-ledger-integrity-error"
            >
              {ledgerIntegrityError instanceof Error
                ? ledgerIntegrityError.message
                : "Ledger integrity endpoint unreachable."}
            </p>
          ) : (
            <p
              className="text-xs font-mono text-muted-foreground"
              data-testid="text-ledger-integrity-loading"
            >
              Checking ledger integrity…
            </p>
          )}
        </div>
      </Card>

      <Card
        className="p-6 border-border bg-card"
        data-testid="card-morningstar-hits"
      >
        <div className="flex flex-col gap-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground flex items-center gap-2">
              <Activity className="w-4 h-4" /> MorningStar-Lab activity
            </h3>
            {morningstarHits ? (
              <span
                className={`inline-flex items-center gap-2 px-3 py-1 border font-mono text-xs font-bold ${
                  morningstarHits.sealOk
                    ? "border-green-500/50 bg-green-500/10 text-green-700 dark:text-green-400"
                    : "border-red-500/50 bg-red-500/10 text-red-700 dark:text-red-400"
                }`}
                data-testid="badge-morningstar-seal"
              >
                {morningstarHits.sealOk ? (
                  <CheckCircle2 className="w-3 h-3" />
                ) : (
                  <ShieldAlert className="w-3 h-3" />
                )}
                {morningstarHits.sealOk
                  ? "Genesis seal verified"
                  : "Genesis seal MISMATCH"}
              </span>
            ) : null}
          </div>

          {morningstarError ? (
            <p
              className="font-mono text-xs text-red-700 dark:text-red-400"
              data-testid="text-morningstar-error"
            >
              Failed to load probe ledger:{" "}
              {morningstarError instanceof Error
                ? morningstarError.message
                : "unknown error"}
            </p>
          ) : !morningstarHits ? (
            <p className="font-mono text-xs text-muted-foreground">
              Loading probe ledger…
            </p>
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs font-mono">
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">
                    Seal SHA-256 (computed)
                  </span>
                  <ShaChip sha={morningstarHits.sealSha} />
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">
                    Seal SHA-256 (expected)
                  </span>
                  <ShaChip sha={morningstarHits.expectedSealSha} />
                </div>
              </div>

              <div className="bg-muted/50 border border-border p-3 font-mono text-xs space-y-1">
                <div className="text-muted-foreground uppercase text-[10px] tracking-wider mb-1">
                  Genesis lines (lines{" "}
                  {morningstarHits.headerLines.length + 1}–
                  {morningstarHits.headerLines.length +
                    morningstarHits.genesisLines.length}
                  )
                </div>
                {morningstarHits.genesisLines.map((line, i) => (
                  <div
                    key={i}
                    className="text-foreground/90 break-all"
                    data-testid={`text-morningstar-genesis-${i}`}
                  >
                    {line}
                  </div>
                ))}
              </div>

              <div className="border border-border">
                <div className="flex items-center justify-between px-3 py-2 border-b border-border bg-muted/30 font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                  <span>
                    Recent probes ({morningstarHits.returnedProbes} of{" "}
                    {morningstarHits.totalProbes})
                  </span>
                  <span title={morningstarHits.lastModified}>
                    ledger {formatTimestamp(morningstarHits.lastModified)}
                  </span>
                </div>
                {morningstarHits.probes.length === 0 ? (
                  <p className="px-3 py-2 font-mono text-xs text-muted-foreground">
                    No probes recorded yet.
                  </p>
                ) : (
                  <ul
                    className="divide-y divide-border"
                    data-testid="list-morningstar-probes"
                  >
                    {morningstarHits.probes.map((probe) => (
                      <li
                        key={probe.lineNumber}
                        className="px-3 py-2 font-mono text-[11px] flex flex-col gap-1"
                        data-testid={`row-morningstar-probe-${probe.lineNumber}`}
                      >
                        <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                          <span className="text-muted-foreground">
                            #{probe.lineNumber}
                          </span>
                          <span
                            className="text-foreground"
                            title={probe.ts ?? ""}
                          >
                            {probe.timestamp
                              ? formatTimestamp(probe.timestamp)
                              : probe.ts ?? "no-ts"}
                          </span>
                          {probe.tag ? (
                            <span
                              className={`px-1.5 py-0.5 border text-[10px] uppercase tracking-wider ${
                                probe.tag === "NEEDS_SAGE"
                                  ? "border-amber-500/50 bg-amber-500/10 text-amber-700 dark:text-amber-400"
                                  : "border-blue-500/50 bg-blue-500/10 text-blue-700 dark:text-blue-400"
                              }`}
                            >
                              {probe.tag}
                            </span>
                          ) : null}
                          <span className="text-muted-foreground">
                            h={probe.h ?? "?"} N={probe.n ?? "?"} s=
                            {probe.re ?? "?"}
                            {probe.im !== null && probe.im !== undefined
                              ? `${probe.im >= 0 ? "+" : ""}${probe.im}i`
                              : ""}
                          </span>
                          <span
                            className={
                              probe.rhOk
                                ? "text-green-700 dark:text-green-400"
                                : "text-amber-700 dark:text-amber-400"
                            }
                          >
                            RH_ok={probe.rhOk === null ? "?" : String(probe.rhOk)}
                          </span>
                          {probe.lAbs ? (
                            <span className="text-muted-foreground">
                              |L|={probe.lAbs}
                            </span>
                          ) : null}
                          {probe.kmsBeta !== null &&
                          probe.kmsBeta !== undefined ? (
                            <span
                              className="text-muted-foreground"
                              title="Bost–Connes inverse temperature β = 1/Re(s)"
                              data-testid={`text-morningstar-kms-beta-${probe.lineNumber}`}
                            >
                              β={probe.kmsBeta}
                            </span>
                          ) : null}
                          {probe.sha ? (
                            <span className="ml-auto">
                              <ShaChip sha={probe.sha} />
                            </span>
                          ) : null}
                        </div>
                        {probe.reason ? (
                          <span className="text-amber-700 dark:text-amber-400">
                            reason: {probe.reason}
                          </span>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
              <p className="text-[11px] font-mono text-muted-foreground">
                Read-only view of <code>data/hits.txt</code>. Polled every 15s.
              </p>
            </>
          )}
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <h3 className="text-sm font-mono font-bold mb-4 uppercase text-muted-foreground border-b border-border pb-2">Master Manifest</h3>
        <div className="flex flex-col gap-2">
          <span className="text-xs font-mono text-muted-foreground">SHA-256 DIGEST (M1..M7 SEALED CHAIN)</span>
          <div className="bg-muted p-4 border border-border">
            <ShaChip sha={summary.masterSha} truncate={false} />
          </div>
        </div>
      </Card>

      <div className="space-y-4">
        <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground border-b border-border pb-2">Module DAG Visualization</h3>
        <div className="grid grid-cols-1 gap-2">
          {certificates.sort((a, b) => a.dagPosition - b.dagPosition).map((cert, index) => (
            <div key={cert.moduleId} className="flex flex-col md:flex-row md:items-center gap-4 p-4 border border-border bg-card hover:bg-muted/50 transition-colors">
              <div className="w-16 font-mono font-bold text-lg text-primary">{cert.moduleId}</div>
              <div className="flex-1 min-w-0">
                <Link href={`/certificates/${cert.moduleId}`} className="font-sans font-semibold hover:underline block truncate">
                  {cert.title}
                </Link>
                <p className="text-xs font-mono text-muted-foreground truncate mt-1">{cert.claim}</p>
              </div>
              <div className="w-48 hidden md:block">
                <ShaChip sha={cert.stdoutSha} />
              </div>
              <div className="w-32 flex justify-end">
                <StatusBadge status={cert.status} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
