import {
  useGetCertificateSummary,
  useListCertificates,
  useGetLeanVerification,
  useGetLeanRebuildHistory,
  useGetLeanLockouts,
  useClearLeanLockout,
  getGetLeanVerificationQueryKey,
  getGetLeanRebuildHistoryQueryKey,
  getGetLeanLockoutsQueryKey,
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
} from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";

const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
const REBUILD_REFEREE_NAME_STORAGE_KEY = "lean-rebuild-referee-name";
const REFEREE_NAME_PATTERN = /^[A-Za-z0-9 _.\-]{1,64}$/;

const STALE_THRESHOLD_DAYS = 30;

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

function formatTimestamp(iso: string | undefined): string {
  if (!iso) return "unknown";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toISOString().replace("T", " ").replace(/\.\d+Z$/, "Z");
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

async function streamRebuild(
  token: string,
  refereeName: string,
  onLine: (line: RebuildLogLine) => void,
  signal: AbortSignal,
): Promise<{ kind: "result"; payload: RebuildResultPayload } | { kind: "error"; error: string; status?: number }> {
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
    return { kind: "error", error: detail, status: response.status };
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

  if (finalResult) return { kind: "result", payload: finalResult };
  if (streamError) return { kind: "error", error: streamError };
  return { kind: "error", error: "Stream ended without a result frame." };
}

export default function DashboardPage() {
  const { data: summary, isLoading: isSummaryLoading } = useGetCertificateSummary();
  const { data: certificates, isLoading: isCertsLoading } = useListCertificates();
  const { data: leanVerify } = useGetLeanVerification();
  const { data: rebuildHistory } = useGetLeanRebuildHistory();
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
  const clearLockoutMutation = useClearLeanLockout({
    request: lockoutsAuthHeader ? { headers: lockoutsAuthHeader } : undefined,
  });
  const [lockoutClearError, setLockoutClearError] = useState<string | null>(null);
  const [pendingClearIp, setPendingClearIp] = useState<string | null>(null);
  const [rebuildOutcome, setRebuildOutcome] = useState<RebuildOutcome | null>(null);
  const [showTokenInput, setShowTokenInput] = useState(false);
  const [isRebuilding, setIsRebuilding] = useState(false);
  const [isCancelling, setIsCancelling] = useState(false);
  const [rebuildStartedAt, setRebuildStartedAt] = useState<number | null>(null);
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);
  const [cancelConfirmElapsedMs, setCancelConfirmElapsedMs] = useState(0);
  const [rebuildLogLines, setRebuildLogLines] = useState<RebuildLogLine[]>([]);
  const logPanelRef = useRef<HTMLPreElement | null>(null);
  const abortRef = useRef<AbortController | null>(null);

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
                  disabled={isRebuilding || !rebuildToken}
                  title={
                    !rebuildToken
                      ? "Set a referee rebuild token to enable this action."
                      : undefined
                  }
                  className="inline-flex items-center gap-2 px-3 py-1.5 border border-green-500/50 bg-green-500/10 font-mono text-xs uppercase tracking-wider text-green-700 dark:text-green-400 hover:bg-green-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                  data-testid="button-rebuild-lean-log"
                >
                  <RefreshCw
                    className={`w-3 h-3 ${isRebuilding ? "animate-spin" : ""}`}
                  />
                  {isRebuilding ? "Rebuilding…" : "Rebuild Lean log"}
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
                  <div className="flex items-center justify-between px-3 py-1.5 border-b border-border bg-muted/30">
                    <span className="font-mono text-[11px] uppercase tracking-wider text-muted-foreground">
                      Recent rebuild attempts
                    </span>
                    <span
                      className="font-mono text-[11px] text-muted-foreground"
                      data-testid="text-rebuild-history-count"
                    >
                      {rebuildHistory.entries.length} of last {rebuildHistory.capacity}
                    </span>
                  </div>
                  <ul className="divide-y divide-border">
                    {rebuildHistory.entries.map((entry, i) => (
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
                        <span
                          className={`md:w-40 truncate ${
                            entry.refereeName
                              ? "text-foreground"
                              : "text-muted-foreground italic"
                          }`}
                          title={
                            entry.refereeName ??
                            "anonymous (no referee name supplied)"
                          }
                          data-testid={`text-rebuild-history-referee-${i}`}
                        >
                          by {entry.refereeName ?? "anonymous"}
                        </span>
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
