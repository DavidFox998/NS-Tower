"""Layer 4 (Transport) — MorningStar-Lab kernel.

probe(h, N, re_s, im_s) -> dict.

Backend: mpmath (pure-Python arbitrary-precision). What we can actually
compute honestly:

- h == 1, N == 1: Riemann zeta ζ(s). Tag MPMATH_ZETA.
- h == 1, N > 1: principal Dirichlet character χ₀ mod N. We strip the
  Euler factors at primes p|N from ζ(s):
      L(s, χ₀) = ζ(s) · ∏_{p|N} (1 - p^{-s}).
  Tag MPMATH_DIRICHLET_TRIVIAL.
- h >= 2: class-group / modular L-functions are out of scope for the
  mpmath backend. The line is tagged NEEDS_SAGE and L_nonvanish is left
  as a stub (True) — the tag is the contract that says "do not trust
  this number".

Failure modes (overflow, mpmath exception, timeout-by-exception) also
fall back to NEEDS_SAGE with a reason field; the ledger never silently
lies about a backend result.

Append-only invariant: before any write, this module re-verifies the
Genesis preamble of data/hits.txt against the baked-in seal and refuses
to proceed if a single byte has changed. The verification routine is
imported in-process from scripts/check-genesis-seal.py so that the seal
hash has exactly ONE source of truth, while avoiding a ~400ms subprocess
fork on every append. The standalone script and the CLI tamper-evidence
guard (scripts/check-genesis-seal.py invoked from tests/post-merge) are
unchanged.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
import math
import multiprocessing
import os
import re as _re
import socket
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import mpmath

try:
    import fcntl  # POSIX-only; the repo targets Linux (Replit/Nix)
except ImportError:  # pragma: no cover - non-POSIX fallback
    fcntl = None  # type: ignore[assignment]

ELLIPTIC_LABEL_RE = _re.compile(r"^[A-Za-z0-9._-]{1,32}$")

REPO_ROOT = Path(__file__).resolve().parent
HITS = REPO_ROOT / "data" / "hits.txt"
CHECKPOINT = REPO_ROOT / "data" / "hits.txt.checkpoint"
# Ring-buffer log of recent ledger integrity alerts (task #71). Every
# `_fire_ledger_alert` invocation appends one JSON line here regardless
# of transport success/failure, so a midnight tamper is still visible
# the next morning even if the webhook was down and the operator was
# asleep. Capped to the last `_ALERTS_MAX_ENTRIES` lines on write;
# disk-full / permission errors are swallowed (best-effort, must never
# mask `LedgerIntegrityError`).
#
# Task #105: in addition to the per-write line cap, the file is rotated
# by byte size to bound disk usage during a long burst of incidents.
# When the live file exceeds `_ALERTS_MAX_BYTES`, it is renamed to
# `ledger-alerts.jsonl.1`, the previous `.1` is shifted to `.2`, and
# so on up to `_ALERTS_MAX_ROTATIONS`; rotations past the cap are
# deleted. The dashboard reader only consults the live file (older
# rotations are archival).
ALERTS_LOG = REPO_ROOT / "data" / "ledger-alerts.jsonl"
_ALERTS_MAX_ENTRIES = 200


def _env_positive_int(name: str, default: int) -> int:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        v = int(raw)
    except ValueError:
        return default
    return v if v > 0 else default


_ALERTS_MAX_BYTES = _env_positive_int(
    "MORNINGSTAR_ALERTS_MAX_BYTES", 5 * 1024 * 1024
)
_ALERTS_MAX_ROTATIONS = _env_positive_int(
    "MORNINGSTAR_ALERTS_MAX_ROTATIONS", 3
)
# Sidecar lockfile coordinating cross-process / cross-tool access to
# `hits.txt`. Used by `_append_line` AND by external backup/restore
# helpers (e.g. the `morningstar-tamper` snapshot/restore fixture in
# `tests/test_morningstar.py`) so that snapshot → mutate → restore
# windows queue against live appenders instead of silently clobbering
# lines that landed mid-window (task #59). A sidecar file is used
# rather than `flock(HITS)` itself because tamper helpers may
# `os.replace` the ledger, which swaps the inode and orphans any
# lock taken directly on the old file. The sidecar lives on a stable
# inode that no helper replaces.
HITS_LOCK_FILE = REPO_ROOT / "data" / ".hits.lock"
SEAL_CHECK = REPO_ROOT / "scripts" / "check-genesis-seal.py"

BACKEND = "mpmath"
BACKEND_VERSION = mpmath.__version__
NONVANISH_TOL = mpmath.mpf("1e-10")
# Honest-scope zero-witness tolerance for RH_ok=True. Tighter than the
# nonvanish threshold so the two predicates don't both fire on borderline
# values: RH_ok is only True when we have actually pinned a zero
# (|ζ| < 1e-12) on the critical line with the real ζ backend.
ZERO_WITNESS_TOL = mpmath.mpf("1e-12")
# Back-compat alias for the older HEAD name.
RH_VANISH_TOL = ZERO_WITNESS_TOL


def _kms_beta(re_s: float) -> float | None:
    """Bost–Connes inverse-temperature β = 1/Re(s). At Re(s)=0.5 the
    physical phase transition fires at β=2 — this is the live KMS
    surface from M13 piped into the ledger. None at Re(s)=0."""
    if re_s == 0.0:
        return None
    return 1.0 / float(re_s)


# Public alias retained for callers from the older `hunt_zeros`/`scan_plane`
# surface; same semantics as the underscore helper.
kms_beta = _kms_beta


def _rh_ok(re_s: float, tag: str, L_abs: str | None) -> bool:
    """Honest-scope RH witness.

    RH_ok is True iff we actually observed |L(s)| below the zero-
    witness tolerance on the critical line, using the real Riemann ζ
    backend. Anything else — off-line, wrong backend (Dirichlet, no
    backend), NEEDS_SAGE stub, missing |L| — is False. The gunsight
    must know when it misses.
    """
    if tag != "MPMATH_ZETA":
        return False
    if re_s != 0.5:
        return False
    if L_abs is None:
        return False
    try:
        return mpmath.mpf(L_abs) < ZERO_WITNESS_TOL
    except (TypeError, ValueError):
        return False


def _load_seal_module():
    """Load scripts/check-genesis-seal.py as a module (the hyphen in the
    filename prevents a plain `import`). Exposes the SAME compute_seal()
    and EXPECTED_SEAL constant that the standalone CLI uses, so there is
    exactly one source of truth for the baked-in hash."""
    spec = importlib.util.spec_from_file_location(
        "_morningstar_seal_check", str(SEAL_CHECK)
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(
            f"Genesis seal check module could not be loaded from {SEAL_CHECK}"
        )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_SEAL_MOD = _load_seal_module()


_SEAL_VERIFY_RETRIES = 4
_SEAL_VERIFY_BACKOFF_S = 0.05


def _verify_seal() -> None:
    """Re-verify data/hits.txt's Genesis preamble against the baked-in
    seal. In-process (no subprocess fork) for speed; the standalone
    scripts/check-genesis-seal.py CLI still works and is used by the
    post-merge guard and the morningstar-tamper test suite.

    Retries up to `_SEAL_VERIFY_RETRIES` times with a short backoff
    before giving up. A genuine tamper is stable, so it still fails
    after every retry; a transient mid-write read (e.g. another
    process rewriting the file with `Path.write_text`, which truncates
    then writes) recovers on the next attempt. This kept the
    zeta-burst workflow chronically red when run alongside the
    morningstar-tamper test fixture, even though the on-disk seal was
    intact — see docs/CHANGELOG.md (v1.10 task #52)."""
    last_err: BaseException | None = None
    expected = _SEAL_MOD.EXPECTED_SEAL
    for attempt in range(_SEAL_VERIFY_RETRIES):
        try:
            # Concurrent-tamper race fix: take the sidecar lock around the preamble read.
            # The `morningstar-tamper` fixture wraps its
            # snapshot → mutate → restore window in the SAME lock
            # (`kernel.hits_exclusive_lock()`, task #59), so any
            # concurrent legitimate-tamper window in another process
            # blocks our read here until the file is restored. Without
            # this, a long-running probe (e.g. `zeta-burst-101-10000`)
            # caught the file in the *mutated* state — `os.replace`
            # makes the new bytes fully visible mid-window, so the
            # retry loop above is useless against this case: every
            # retry sees the same tampered SHA. The lock is
            # thread-reentrant within a process, so the tamper fixture
            # itself (which holds the lock and calls `kernel.probe()`,
            # which calls `_verify_seal()`) does not self-deadlock.
            with _HitsLock():
                got = _SEAL_MOD.compute_seal()
        except SystemExit as e:
            # compute_seal raises SystemExit when hits.txt is missing
            # or the marker is gone — usually a transient mid-write
            # read; we retry, then surface as a hard tamper signal if
            # it persists.
            last_err = RuntimeError(
                f"Genesis seal verification failed (preamble unreadable): {e}"
            )
        else:
            if got == expected:
                return
            last_err = RuntimeError(
                "Genesis seal verification failed:\n"
                f"  expected: {expected}\n"
                f"  got:      {got}"
            )
        if attempt < _SEAL_VERIFY_RETRIES - 1:
            time.sleep(_SEAL_VERIFY_BACKOFF_S * (attempt + 1))
    assert last_err is not None
    raise last_err


class LedgerIntegrityError(RuntimeError):
    """Raised by `_verify_checkpoint` when the at-rest checkpoint detects
    a corrupted ledger (shrunken, in-place rewritten, missing, or with a
    malformed/missing checkpoint sidecar).

    Carries a structured `context` dict so the alert layer
    (`_fire_ledger_alert`) can emit machine-readable fields (expected vs
    actual size/sha, failure mode) without re-parsing the string message.
    Subclass of `RuntimeError` so existing callers that `except
    RuntimeError` (task #57's `_append_line` site, the long-running probe
    workflows, the tests) continue to catch it unchanged.
    """

    def __init__(self, message: str, context: "dict[str, Any] | None" = None) -> None:
        super().__init__(message)
        self.context: dict[str, Any] = dict(context or {})


def _alert_workflow_name() -> str:
    """Best-effort identifier of the workflow that just hit the alert.
    Prefers an explicit env var so workflow YAMLs / shell invocations can
    tag themselves; otherwise falls back to argv0 / hostname so the
    operator at least sees *something* in the alert body."""
    name = os.environ.get("MORNINGSTAR_WORKFLOW_NAME", "").strip()
    if name:
        return name
    argv0 = sys.argv[0] if sys.argv else ""
    if argv0:
        return os.path.basename(argv0) or argv0
    try:
        return socket.gethostname()
    except OSError:
        return "unknown"


_ALERT_RECOVERY_POINTER = (
    "Recovery: see docs/REPRODUCE.md section "
    '"Recovering data/hits.txt from a tamper or accidental truncation".'
)


def _alert_timeout_seconds() -> float:
    """Read the per-transport alert delivery timeout (in seconds) from
    `MORNINGSTAR_ALERT_TIMEOUT_SECONDS`, defaulting to 5.0. Task #82:
    a real DNS hang / TLS handshake stall / SMTP greylist delay on the
    on-call sink should be tunable per deployment without code edits.
    Invalid or non-positive values fall back to the default rather than
    raising — alerts are best-effort observability, not a correctness
    surface, so a typo in the env var must not break ledger writes."""
    raw = os.environ.get("MORNINGSTAR_ALERT_TIMEOUT_SECONDS", "").strip()
    if not raw:
        return 5.0
    try:
        v = float(raw)
    except ValueError:
        return 5.0
    return v if v > 0 else 5.0


def _alert_subject(payload: "dict[str, Any]") -> str:
    """Build the human-readable subject line for an alert payload.

    The watchdog stall / recovery signals fired by the api-server's
    `checkWatchdog` (task #113) ride the same `_fire_ledger_alert`
    transport as a real tamper, but a midnight on-call should be able
    to tell them apart from a glance at the inbox / Slack channel —
    a stalled monitor means "push alerts may be silent", not "the
    ledger has been corrupted". Task #144.

    The subject is also injected back into the payload as `subject`
    before delivery so webhook consumers (Slack, PagerDuty, etc.)
    can route on a single human-readable field without re-deriving
    it from `failure_mode` / `previous_failure_mode`.
    """
    workflow = payload.get("workflow", "?")
    failure_mode = payload.get("failure_mode")
    previous = payload.get("previous_failure_mode")
    if failure_mode == "monitor_stalled":
        return (
            f"[MorningStar] Ledger MONITOR STALLED — push alerts may "
            f"be silent: {workflow}"
        )
    if failure_mode == "recovered" and previous == "monitor_stalled":
        return f"[MorningStar] Ledger monitor RECOVERED: {workflow}"
    if failure_mode == "recovered":
        return f"[MorningStar] Ledger integrity RECOVERED: {workflow}"
    if failure_mode == "reroll_digest":
        # Task #176: daily summary email of checkpoint re-roll attempts.
        # Distinct subject so on-call can split routine digests from
        # tamper / watchdog alerts without re-deriving from
        # `failure_mode`.
        window_hours = payload.get("window_hours")
        suffix = (
            f" (last {window_hours}h)"
            if isinstance(window_hours, (int, float)) and window_hours > 0
            else ""
        )
        return (
            f"[MorningStar] Checkpoint re-roll digest{suffix}: {workflow}"
        )
    return f"[MorningStar] Ledger integrity alert: {workflow}"


def _post_webhook(url: str, payload: "dict[str, Any]") -> None:
    """POST JSON payload to `url` with a short timeout. Raises on any
    failure (caller wraps in best-effort try/except)."""
    from urllib import request as _urlreq

    body = json.dumps(payload).encode("utf-8")
    req = _urlreq.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with _urlreq.urlopen(  # noqa: S310 - opt-in URL
        req, timeout=_alert_timeout_seconds()
    ) as resp:
        resp.read()


def _send_email(payload: "dict[str, Any]", message: str) -> None:
    """Send a plaintext alert email via SMTP using env-var config. Raises
    on any failure (caller wraps in best-effort try/except)."""
    import smtplib
    from email.message import EmailMessage

    to_addr = os.environ.get("MORNINGSTAR_ALERT_EMAIL_TO", "").strip()
    host = os.environ.get("MORNINGSTAR_ALERT_SMTP_HOST", "").strip()
    if not to_addr or not host:
        return
    port = int(os.environ.get("MORNINGSTAR_ALERT_SMTP_PORT", "25"))
    from_addr = (
        os.environ.get("MORNINGSTAR_ALERT_EMAIL_FROM", "").strip() or to_addr
    )
    user = os.environ.get("MORNINGSTAR_ALERT_SMTP_USER", "").strip()
    password = os.environ.get("MORNINGSTAR_ALERT_SMTP_PASSWORD", "")

    msg = EmailMessage()
    msg["Subject"] = _alert_subject(payload)
    msg["From"] = from_addr
    msg["To"] = to_addr
    failure_mode = payload.get("failure_mode")
    if failure_mode in ("monitor_stalled", "recovered") and (
        failure_mode == "monitor_stalled"
        or payload.get("previous_failure_mode") == "monitor_stalled"
    ):
        # Task #144: watchdog signals carry stall_age/threshold/last_tick
        # fields instead of the expected/actual size+sha fields used for
        # real tamper alerts. Tail with a "what to do about it" pointer
        # rather than the tamper-recovery doc, since a stalled monitor
        # is not a tamper — the operator should investigate the
        # api-server process / its periodic tick, not restore hits.txt.
        body = (
            f"{message}\n\n"
            f"workflow: {payload.get('workflow')}\n"
            f"timestamp: {payload.get('timestamp')}\n"
            f"failure_mode: {failure_mode}\n"
            f"previous_failure_mode: {payload.get('previous_failure_mode')}\n"
            f"source: {payload.get('source')}\n"
            f"last_tick_at: {payload.get('last_tick_at')}\n"
            f"stall_age_seconds: {payload.get('stall_age_seconds')}\n"
            f"stall_threshold_seconds: {payload.get('stall_threshold_seconds')}\n"
            f"monitor_interval_seconds: {payload.get('monitor_interval_seconds')}\n\n"
            f"This is a ledger MONITOR signal, not a tamper. While "
            f"the monitor is stalled, push alerts on a real ledger "
            f"tamper may not fire until the api-server is restarted. "
            f"Investigate the api-server process and its periodic "
            f"integrity tick; do NOT restore hits.txt.\n"
        )
    elif failure_mode == "reroll_digest":
        # Task #176: routine daily summary of checkpoint re-roll
        # attempts. Body carries the pre-formatted digest text built by
        # the api-server (referee → ok/fail counts, plus a per-row list
        # of any failures). NOT a tamper signal; the recovery pointer
        # is intentionally omitted so on-call doesn't think the ledger
        # was touched.
        digest = payload.get("digest_text")
        body = (
            f"{message}\n\n"
            f"workflow: {payload.get('workflow')}\n"
            f"timestamp: {payload.get('timestamp')}\n"
            f"window_hours: {payload.get('window_hours')}\n"
            f"total_attempts: {payload.get('total_attempts')}\n"
            f"ok_count: {payload.get('ok_count')}\n"
            f"fail_count: {payload.get('fail_count')}\n\n"
            f"{digest if isinstance(digest, str) else ''}\n"
            f"\nThis is a routine digest, not a tamper alert. No "
            f"action required unless an unexpected referee or a "
            f"high fail-count appears above.\n"
        )
    else:
        body = (
            f"{message}\n\n"
            f"workflow: {payload.get('workflow')}\n"
            f"timestamp: {payload.get('timestamp')}\n"
            f"expected_size: {payload.get('expected_size')}\n"
            f"actual_size: {payload.get('actual_size')}\n"
            f"expected_sha: {payload.get('expected_sha')}\n"
            f"actual_sha: {payload.get('actual_sha')}\n"
            f"failure_mode: {payload.get('failure_mode')}\n\n"
            f"{_ALERT_RECOVERY_POINTER}\n"
        )
    msg.set_content(body)
    with smtplib.SMTP(host, port, timeout=_alert_timeout_seconds()) as smtp:
        if user:
            try:
                smtp.starttls()
            except smtplib.SMTPException:
                pass
            smtp.login(user, password)
        smtp.send_message(msg)


_ALERT_DISPATCH_THREADS: "list[threading.Thread]" = []
_ALERT_DISPATCH_LOCK = threading.Lock()

# Task #94: hard cap on in-flight background alert-dispatch threads.
# Task #82 made delivery asynchronous so a hung sink (DNS hang, TLS
# stall, SMTP greylist) doesn't freeze `_append_line`. The trade-off
# is that if the sink stays unreachable AND the ledger keeps tripping
# (e.g. a burst-probe run hitting a wedged integrity check repeatedly),
# background dispatch threads can accumulate without bound — each
# holding a socket waiting for its timeout. When this cap is reached,
# new alerts are dropped with a stderr WARN and a ring-buffer entry
# tagged `delivery.{webhook,email}.status == "dropped_backpressure"`
# so the on-call still sees that an alert WAS suppressed.
_ALERT_DISPATCH_MAX_INFLIGHT = 16


def _await_alert_dispatch(timeout: float = 10.0) -> bool:
    """Block until every still-running background alert-dispatch thread
    has terminated, or `timeout` seconds have elapsed. Returns True if
    all threads completed in time, False if any were still alive at
    the deadline.

    Task #82: alert delivery now runs in a daemon thread so a hung sink
    (DNS hang, TLS stall, SMTP greylist) doesn't freeze the caller of
    `_append_line`. This helper exists so tests and operator tooling
    can deterministically wait for delivery + history-write to finish
    before reading the on-disk ring buffer.
    """
    deadline = time.monotonic() + max(0.0, timeout)
    with _ALERT_DISPATCH_LOCK:
        threads = [t for t in _ALERT_DISPATCH_THREADS if t.is_alive()]
    for t in threads:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        t.join(remaining)
    with _ALERT_DISPATCH_LOCK:
        _ALERT_DISPATCH_THREADS[:] = [
            t for t in _ALERT_DISPATCH_THREADS if t.is_alive()
        ]
        return not _ALERT_DISPATCH_THREADS


def _deliver_ledger_alert(
    payload: "dict[str, Any]",
    message: str,
    webhook: str,
    email_to: str,
) -> None:
    """Background worker: run each configured transport, then write the
    ring-buffer history line. Exceptions are swallowed to stderr —
    this runs after the foreground `LedgerIntegrityError` has already
    re-raised, so it has nowhere to surface failures except the log."""
    delivery: dict[str, Any] = {}
    if webhook:
        try:
            _post_webhook(webhook, payload)
            delivery["webhook"] = {"status": "ok"}
        except Exception as e:  # noqa: BLE001 - best-effort, never mask
            sys.stderr.write(
                f"WARN: ledger alert webhook delivery failed: {e}\n"
            )
            delivery["webhook"] = {"status": "failed", "error": str(e)}
    else:
        delivery["webhook"] = {"status": "not_configured"}
    if email_to:
        try:
            _send_email(payload, message)
            delivery["email"] = {"status": "ok"}
        except Exception as e:  # noqa: BLE001 - best-effort, never mask
            sys.stderr.write(
                f"WARN: ledger alert email delivery failed: {e}\n"
            )
            delivery["email"] = {"status": "failed", "error": str(e)}
    else:
        delivery["email"] = {"status": "not_configured"}
    try:
        _record_alert_history(payload, delivery)
    except Exception as e:  # noqa: BLE001 - best-effort, never mask
        sys.stderr.write(
            f"WARN: ledger alert history dispatch failed: {e}\n"
        )


def _fire_ledger_alert(message: str, context: "dict[str, Any]") -> None:
    """Best-effort notification that a ledger integrity check has failed.

    Opt-in via env var:
      - `MORNINGSTAR_ALERT_WEBHOOK_URL` — POST JSON payload, or
      - `MORNINGSTAR_ALERT_EMAIL_TO` + `MORNINGSTAR_ALERT_SMTP_HOST` —
        plaintext SMTP delivery.

    Both may be set simultaneously; each transport is attempted
    independently. If neither env var is configured, the function is
    still recorded to the on-disk ring buffer (task #71) — but no
    network call is made.

    Task #82: the actual network delivery + history write run in a
    daemon thread so a slow or hung sink can't block the failing
    `_append_line` caller for the full timeout window. The foreground
    caller returns immediately after building the payload and
    launching the worker; the `LedgerIntegrityError` then re-raises
    without waiting for socket I/O.

    Failure to deliver MUST NOT mask the underlying integrity
    exception. Tests and operator tooling that need to read the ring
    buffer can call `_await_alert_dispatch(timeout)` to block until
    the worker has finished.
    """
    webhook = os.environ.get("MORNINGSTAR_ALERT_WEBHOOK_URL", "").strip()
    email_to = os.environ.get("MORNINGSTAR_ALERT_EMAIL_TO", "").strip()
    payload: dict[str, Any] = {
        "workflow": _alert_workflow_name(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "message": message,
        "recovery": _ALERT_RECOVERY_POINTER,
        "hits_path": str(HITS),
        "checkpoint_path": str(CHECKPOINT),
        **context,
    }
    # Task #144: derive a human-readable subject so webhook consumers
    # (Slack, PagerDuty) and the email transport route on the same
    # field, and so a watchdog-stalled alert is visibly distinct from
    # a real tamper at a glance.
    payload["subject"] = _alert_subject(payload)
    thread = threading.Thread(
        target=_deliver_ledger_alert,
        args=(payload, message, webhook, email_to),
        name="ledger-alert-dispatch",
        daemon=True,
    )
    with _ALERT_DISPATCH_LOCK:
        _ALERT_DISPATCH_THREADS[:] = [
            t for t in _ALERT_DISPATCH_THREADS if t.is_alive()
        ]
        # Task #94: bound in-flight dispatch threads. If the cap is
        # already saturated (hung sink + ledger tripping repeatedly),
        # drop the new alert with a backpressure marker rather than
        # spawn yet another socket-holding thread.
        if len(_ALERT_DISPATCH_THREADS) >= _ALERT_DISPATCH_MAX_INFLIGHT:
            inflight = len(_ALERT_DISPATCH_THREADS)
            sys.stderr.write(
                f"WARN: ledger alert dropped (backpressure: {inflight} "
                f"in-flight deliveries >= cap {_ALERT_DISPATCH_MAX_INFLIGHT}); "
                f"sink appears wedged\n"
            )
            dropped_delivery = {
                "webhook": {
                    "status": "dropped_backpressure",
                    "inflight": inflight,
                    "cap": _ALERT_DISPATCH_MAX_INFLIGHT,
                },
                "email": {
                    "status": "dropped_backpressure",
                    "inflight": inflight,
                    "cap": _ALERT_DISPATCH_MAX_INFLIGHT,
                },
            }
            try:
                _record_alert_history(payload, dropped_delivery)
            except Exception as e:  # noqa: BLE001 - best-effort, never mask
                sys.stderr.write(
                    f"WARN: ledger alert history dispatch failed: {e}\n"
                )
            return
        _ALERT_DISPATCH_THREADS.append(thread)
    thread.start()


def _record_alert_history(
    payload: "dict[str, Any]", delivery: "dict[str, Any]"
) -> None:
    """Append one structured JSON line to `ALERTS_LOG` capturing the
    alert payload plus per-transport delivery status, then trim the
    file to the last `_ALERTS_MAX_ENTRIES` lines. Task #71: a durable,
    restart-surviving trace so a midnight tamper isn't forgotten by
    morning even when both transports failed (or weren't configured).

    Best-effort: any OSError / JSON error is swallowed to stderr so the
    underlying `LedgerIntegrityError` is never masked by a disk-full
    or permission failure on the alerts log itself.
    """
    try:
        entry = {**payload, "delivery": delivery}
        line = json.dumps(entry, sort_keys=True, default=str) + "\n"
        ALERTS_LOG.parent.mkdir(parents=True, exist_ok=True)
        with open(ALERTS_LOG, "a", encoding="utf-8") as fh:
            fh.write(line)
        # Trim to the last N entries. Read-trim-rewrite is cheap at
        # N=200 and bounded; we don't need a lock because alerts fire
        # on rare integrity failures, not in hot probe paths.
        try:
            with open(ALERTS_LOG, "r", encoding="utf-8") as fh:
                lines = fh.readlines()
            if len(lines) > _ALERTS_MAX_ENTRIES:
                trimmed = lines[-_ALERTS_MAX_ENTRIES:]
                tmp = ALERTS_LOG.with_suffix(ALERTS_LOG.suffix + ".tmp")
                with open(tmp, "w", encoding="utf-8") as fh:
                    fh.writelines(trimmed)
                os.replace(tmp, ALERTS_LOG)
        except OSError as e:
            sys.stderr.write(
                f"WARN: ledger alert log rotation failed: {e}\n"
            )
        # Task #105: byte-size rotation. Even with the 200-entry line
        # cap above, a pathological single entry (or a future schema
        # widening) could push disk usage unbounded across a long
        # deployment. When the live file exceeds the byte cap, shift
        # `ledger-alerts.jsonl{,.1,.2,...}` down by one and start
        # fresh. Older rotations past `_ALERTS_MAX_ROTATIONS` are
        # deleted; the dashboard reader only inspects the live file.
        try:
            _rotate_alerts_log_if_needed()
        except OSError as e:
            sys.stderr.write(
                f"WARN: ledger alert size rotation failed: {e}\n"
            )
    except OSError as e:
        sys.stderr.write(
            f"WARN: ledger alert history write failed: {e}\n"
        )


def _rotate_alerts_log_if_needed() -> None:
    """Rotate `ALERTS_LOG` when it grows past `_ALERTS_MAX_BYTES`.

    Rotation scheme (logrotate-style):
      ledger-alerts.jsonl.(K-1) -> deleted (if K rotations already kept)
      ledger-alerts.jsonl.(K-2) -> ledger-alerts.jsonl.(K-1)
      ...
      ledger-alerts.jsonl.1     -> ledger-alerts.jsonl.2
      ledger-alerts.jsonl       -> ledger-alerts.jsonl.1

    Best-effort: any OSError propagates to the caller which logs to
    stderr without masking the underlying integrity failure.
    """
    try:
        size = ALERTS_LOG.stat().st_size
    except FileNotFoundError:
        return
    if size <= _ALERTS_MAX_BYTES:
        return
    # Drop the oldest rotation if it exists at the cap boundary.
    oldest = ALERTS_LOG.with_suffix(
        ALERTS_LOG.suffix + f".{_ALERTS_MAX_ROTATIONS}"
    )
    if oldest.exists():
        try:
            oldest.unlink()
        except FileNotFoundError:
            pass
    # Shift .N-1 -> .N, ..., .1 -> .2
    for i in range(_ALERTS_MAX_ROTATIONS - 1, 0, -1):
        src = ALERTS_LOG.with_suffix(ALERTS_LOG.suffix + f".{i}")
        if src.exists():
            dst = ALERTS_LOG.with_suffix(ALERTS_LOG.suffix + f".{i + 1}")
            os.replace(src, dst)
    # Current -> .1
    dst1 = ALERTS_LOG.with_suffix(ALERTS_LOG.suffix + ".1")
    os.replace(ALERTS_LOG, dst1)


def read_recent_alerts(limit: int = 20) -> "list[dict[str, Any]]":
    """Return up to `limit` most-recent alert entries from `ALERTS_LOG`,
    newest first. Returns an empty list if the log is missing, empty,
    or unreadable — callers (CLI / dashboard endpoint) get a stable
    surface regardless of whether any alert has ever fired. Task #71.

    Malformed JSON lines (e.g. a partial write from a crashed process)
    are skipped, not raised; the ring buffer is informational, not a
    correctness surface.
    """
    if limit <= 0:
        return []
    try:
        with open(ALERTS_LOG, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return []
    out: list[dict[str, Any]] = []
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            continue
        if len(out) >= limit:
            break
    return out


def _verify_checkpoint() -> None:
    """Verify the at-rest checkpoint against the live ledger BEFORE
    appending. Complements `_verify_seal` (which only covers the 9-line
    Genesis preamble).

    Reads `data/hits.txt.checkpoint` (written by `_update_checkpoint`
    after every legitimate append) and confirms:
      - the live ledger is at least as long as the checkpoint records,
      - SHA-256 of the live ledger's first `expected_size` bytes matches
        the recorded hash.

    Because the ledger is append-only, any legitimate growth above the
    recorded size still validates against the recorded prefix SHA — a
    stale checkpoint is *safe*; only a *shrunken* or *in-place
    rewritten* file is a tamper. This is the in-process twin of
    `scripts/check-ledger-integrity.py`, called per-append so a
    body-truncation between `post-merge.sh` runs is caught immediately
    instead of compounding across thousands of appends. Task #57.

    No-op if the checkpoint file is absent: that is a legitimate
    bootstrap state (e.g. test fixtures pointing `HITS` at a throwaway
    tmp file with no prior checkpoint). The committed checkpoint is
    always present in production, so this branch only fires for
    fixtures that have already monkeypatched `kernel.CHECKPOINT`
    accordingly.

    Raises RuntimeError on truncation or in-place rewrite. Callers
    (`_append_line`) must propagate the exception without appending —
    the whole point is to refuse to grow a corrupted ledger.
    """
    if not CHECKPOINT.exists():
        return
    try:
        raw = CHECKPOINT.read_text(encoding="utf-8").strip()
    except OSError as e:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: cannot read {CHECKPOINT}: {e}",
            {"failure_mode": "checkpoint_unreadable"},
        ) from e
    parts = raw.split()
    if len(parts) != 2:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {CHECKPOINT} malformed "
            f"(expected '<size> <sha256>', got {raw!r}).",
            {"failure_mode": "checkpoint_malformed"},
        )
    try:
        expected_size = int(parts[0])
    except ValueError as e:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {CHECKPOINT} size field "
            f"not an integer: {parts[0]!r}.",
            {"failure_mode": "checkpoint_size_not_int"},
        ) from e
    expected_sha = parts[1].lower()
    if len(expected_sha) != 64 or any(c not in "0123456789abcdef" for c in expected_sha):
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {CHECKPOINT} sha256 field "
            f"malformed: {expected_sha!r}.",
            {"failure_mode": "checkpoint_sha_malformed",
             "expected_size": expected_size},
        )
    try:
        with HITS.open("rb") as fh:
            prefix = fh.read(expected_size)
    except FileNotFoundError as e:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {HITS} missing while "
            f"checkpoint expects {expected_size} bytes.",
            {"failure_mode": "hits_missing",
             "expected_size": expected_size,
             "expected_sha": expected_sha},
        ) from e
    actual_prefix_size = len(prefix)
    if actual_prefix_size < expected_size:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {HITS} SHRUNK — expected "
            f"at least {expected_size} bytes, got {actual_prefix_size}. "
            "TRUNCATION or in-place rewrite suspected. Refusing to "
            "append; recover the ledger before continuing (see "
            "docs/REPRODUCE.md).",
            {"failure_mode": "hits_truncated",
             "expected_size": expected_size,
             "actual_size": actual_prefix_size,
             "expected_sha": expected_sha},
        )
    prefix_sha = hashlib.sha256(prefix).hexdigest()
    if prefix_sha != expected_sha:
        raise LedgerIntegrityError(
            f"Ledger integrity check failed: {HITS} first "
            f"{expected_size} bytes have been rewritten in place.\n"
            f"  expected sha256: {expected_sha}\n"
            f"  got sha256:      {prefix_sha}\n"
            "The ledger is append-only; in-place edits are not "
            "permitted. Refusing to append.",
            {"failure_mode": "hits_rewritten_in_place",
             "expected_size": expected_size,
             "actual_size": actual_prefix_size,
             "expected_sha": expected_sha,
             "actual_sha": prefix_sha},
        )


def _update_checkpoint() -> None:
    """Refresh data/hits.txt.checkpoint with the current (size, sha256).

    The checkpoint is the at-rest guard against silent truncation /
    in-place rewrites of `data/hits.txt`. `scripts/check-ledger-integrity.py`
    refuses any state where the live file is shorter than the
    checkpoint's recorded size, or where the SHA-256 of the first
    `size` bytes of the live file differs from the recorded hash.
    Because the ledger is append-only, any legitimate growth above
    the recorded size still validates against the recorded prefix
    SHA — a stale checkpoint is *safe*, only a shrunken or rewritten
    file is a tamper. The write is atomic (tmp + os.replace) so a
    crash mid-update cannot leave the checkpoint truncated.
    """
    data = HITS.read_bytes()
    size = len(data)
    sha = hashlib.sha256(data).hexdigest()
    tmp = CHECKPOINT.with_name(CHECKPOINT.name + ".tmp")
    tmp.write_text(f"{size} {sha}\n", encoding="utf-8")
    os.replace(tmp, CHECKPOINT)


class _HitsLock:
    """Context manager: take an exclusive `fcntl.flock` on the sidecar
    `HITS_LOCK_FILE` for the duration of the `with` block.

    This is the canonical cross-tool serialization primitive for any
    code that touches `data/hits.txt` — `_append_line` (live probe
    workflows) AND external backup/restore helpers (the
    `morningstar-tamper` snapshot/restore fixture in
    `tests/test_morningstar.py`) all queue on the same lock.

    Why a sidecar and not `flock(HITS)` directly: tamper helpers
    snapshot the ledger, mutate it (often via `os.replace` for
    atomicity against concurrent readers), then restore from the
    snapshot. `os.replace` swaps the inode at the path; any flock
    taken on the *file* HITS would now be orphaned on the old inode,
    and a fresh `open(HITS)` from a sibling probe would see the new
    inode with no contention and slip a line in during the mutate →
    restore window — the restore would then silently overwrite that
    line (task #59). The sidecar lockfile lives on a stable inode
    that no helper replaces, so the lock is durable across atomic
    rewrites of the ledger itself.

    Thread-reentrant within the same process: built on a
    `threading.RLock`, so a tamper fixture that holds the lock and
    then (in the same thread) calls `kernel.probe()` —  which
    internally calls `_append_line()`, which also takes the lock —
    just bumps the recursion counter instead of self-deadlocking.
    A *different* thread in the same process still has to wait for
    the RLock to be released, exactly like a different process
    waits for the flock. So both layers preserve mutual exclusion
    between independent writers; the only "reentrancy" allowed is
    "the same thread re-entering its own critical section".

    The underlying flock is acquired once at outermost entry (depth
    transitions 0 → 1) and released at outermost exit (N → 0), so
    the cross-process serialization contract is unchanged: another
    process's `_append_line` blocks until *our* outermost
    `with kernel.hits_exclusive_lock()` exits.

    On non-POSIX hosts where `fcntl` is unavailable the flock layer
    is a no-op (falls back to the pre-task-#54 behaviour); the
    thread-level RLock still serializes intra-process writers. The
    repo targets Linux, so the fcntl-less path is just defensive.
    """

    # Class-level state: thread-reentrant exclusion via RLock,
    # process-level exclusion via flock on a sidecar file.
    _rlock = threading.RLock()
    _depth: int = 0
    _fp = None

    def __enter__(self) -> "_HitsLock":
        # RLock.acquire() blocks if another thread holds it; same
        # thread reentries just bump RLock's internal recursion
        # counter without blocking.
        _HitsLock._rlock.acquire()
        # _depth and _fp are now protected by RLock ownership.
        if _HitsLock._depth == 0:
            HITS_LOCK_FILE.parent.mkdir(parents=True, exist_ok=True)
            # Open in append mode so the file is created on first
            # use without truncating an existing one.
            _HitsLock._fp = HITS_LOCK_FILE.open("a+")
            if fcntl is not None:
                fcntl.flock(_HitsLock._fp.fileno(), fcntl.LOCK_EX)
        _HitsLock._depth += 1
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        try:
            _HitsLock._depth -= 1
            if _HitsLock._depth == 0 and _HitsLock._fp is not None:
                try:
                    if fcntl is not None:
                        fcntl.flock(_HitsLock._fp.fileno(), fcntl.LOCK_UN)
                finally:
                    _HitsLock._fp.close()
                    _HitsLock._fp = None
        finally:
            _HitsLock._rlock.release()


def hits_exclusive_lock() -> _HitsLock:
    """Public alias of `_HitsLock` for tools outside kernel.py (e.g.
    the `morningstar-tamper` test fixture). Use as
    `with kernel.hits_exclusive_lock(): ...` to serialize a
    snapshot → mutate → restore window against live `_append_line`
    writers. See `_HitsLock` for the why."""
    return _HitsLock()


def _append_line(line: str) -> None:
    """Append exactly one line + newline to hits.txt, fsync, then
    refresh the at-rest checkpoint.

    Cross-process safety: takes an exclusive `fcntl.flock` on the
    sidecar `HITS_LOCK_FILE` (the canonical lock, shared with
    backup/restore helpers — see `_HitsLock`) AND a second flock on
    the open append handle. Two concurrent appenders (e.g.
    `zeta-burst-101-10000` running alongside
    `zeta-sieve-14159-100000`) therefore queue on the sidecar lock
    instead of racing on the checkpoint refresh —
    `_update_checkpoint` reads the whole file, hashes it, and
    atomically replaces `data/hits.txt.checkpoint`, so without
    serialization writer A can land its line, writer B can append
    its own line, then writer A's `_update_checkpoint` would rehash
    the file (now containing B's line) and stamp it as A's
    checkpoint. With the lock the sequence
    `write + flush + fsync + checkpoint` is atomic per line; a
    second writer waits at `flock(LOCK_EX)` until the first fully
    completes. POSIX `O_APPEND` already prevents byte-level tearing
    for short writes (<= `PIPE_BUF`), but the lock is what keeps the
    SHA chain in `hits.txt` and the recorded prefix-hash in
    `hits.txt.checkpoint` consistent.

    On non-POSIX hosts where `fcntl` is unavailable the function
    falls back to plain append (the original behaviour). This repo
    targets Linux, so that path is just defensive.
    """
    HITS.parent.mkdir(parents=True, exist_ok=True)
    with _HitsLock():
        with HITS.open("a", encoding="utf-8") as f:
            if fcntl is not None:
                fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            try:
                # Task #57: verify at-rest checkpoint while holding the
                # exclusive lock, so a body-truncation or in-place rewrite
                # that occurred between probes is caught BEFORE we commit
                # another line to a corrupted ledger. The Genesis seal
                # (checked by `_verify_seal` in `probe`) only covers the
                # 9-line preamble; this catches the rest of the file.
                try:
                    _verify_checkpoint()
                except LedgerIntegrityError as exc:
                    # Best-effort: alert operators (opt-in via env var),
                    # then re-raise so the workflow still halts loudly.
                    # Alert delivery is wrapped internally; it cannot
                    # mask `exc` (task #63).
                    _fire_ledger_alert(str(exc), exc.context)
                    raise
                f.write(line + "\n")
                f.flush()
                os.fsync(f.fileno())
                _update_checkpoint()
            finally:
                if fcntl is not None:
                    fcntl.flock(f.fileno(), fcntl.LOCK_UN)


def _prime_divisors(n: int) -> list[int]:
    """Distinct prime divisors of |n|, n != 0. Trial division is fine
    for the modest N used by the lab."""
    n = abs(int(n))
    if n <= 1:
        return []
    primes: list[int] = []
    d = 2
    while d * d <= n:
        if n % d == 0:
            primes.append(d)
            while n % d == 0:
                n //= d
        d += 1 if d == 2 else 2
    if n > 1:
        primes.append(n)
    return primes


def _evaluate(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    """Return the backend result dict, with keys:
        tag: str           — MPMATH_ZETA | MPMATH_DIRICHLET_TRIVIAL | NEEDS_SAGE
        backend: str       — "mpmath" or "none"
        L_real, L_imag: str (or None for NEEDS_SAGE)
        L_abs: str (or None)
        L_nonvanish: bool
        reason: str (only present when tag == NEEDS_SAGE)
    """
    s = mpmath.mpc(re_s, im_s)

    if h == 1 and N == 1:
        try:
            with mpmath.workdps(50):
                val = mpmath.zeta(s)
                absval = abs(val)
            return {
                "tag": "MPMATH_ZETA",
                "backend": BACKEND,
                "L_real": mpmath.nstr(val.real, 20),
                "L_imag": mpmath.nstr(val.imag, 20),
                "L_abs": mpmath.nstr(absval, 20),
                "L_nonvanish": bool(absval > NONVANISH_TOL),
            }
        except Exception as e:  # noqa: BLE001
            return {
                "tag": "NEEDS_SAGE",
                "backend": "none",
                "L_real": None,
                "L_imag": None,
                "L_abs": None,
                "L_nonvanish": True,
                "reason": f"mpmath_zeta_failed:{type(e).__name__}",
            }

    if h == 1 and N > 1:
        try:
            with mpmath.workdps(50):
                val = mpmath.zeta(s)
                for p in _prime_divisors(N):
                    val = val * (mpmath.mpc(1) - mpmath.power(p, -s))
                absval = abs(val)
            return {
                "tag": "MPMATH_DIRICHLET_TRIVIAL",
                "backend": BACKEND,
                "L_real": mpmath.nstr(val.real, 20),
                "L_imag": mpmath.nstr(val.imag, 20),
                "L_abs": mpmath.nstr(absval, 20),
                "L_nonvanish": bool(absval > NONVANISH_TOL),
            }
        except Exception as e:  # noqa: BLE001
            return {
                "tag": "NEEDS_SAGE",
                "backend": "none",
                "L_real": None,
                "L_imag": None,
                "L_abs": None,
                "L_nonvanish": True,
                "reason": f"mpmath_dirichlet_trivial_failed:{type(e).__name__}",
            }

    return {
        "tag": "NEEDS_SAGE",
        "backend": "none",
        "L_real": None,
        "L_imag": None,
        "L_abs": None,
        "L_nonvanish": True,
        "reason": "h>=2_out_of_scope_for_mpmath_backend",
    }


def probe(h: int, N: int, re_s: float, im_s: float) -> dict[str, Any]:
    """Run a single 4D probe and append exactly one ledger line.

    Returns a dict with keys: h, N, L_nonvanish, RH_ok, kms_beta, tag,
    backend, L_real, L_imag, L_abs, sha, ledger_line. The `reason` key
    is only present when the backend was not able to evaluate
    (tag NEEDS_SAGE).
    """
    _verify_seal()

    ts = time.time_ns()
    inputs = {"h": int(h), "N": int(N), "re_s": float(re_s), "im_s": float(im_s)}

    ev = _evaluate(inputs["h"], inputs["N"], inputs["re_s"], inputs["im_s"])

    kms = _kms_beta(inputs["re_s"])
    output = {
        "h": inputs["h"],
        "N": inputs["N"],
        "L_nonvanish": ev["L_nonvanish"],
        "RH_ok": _rh_ok(inputs["re_s"], ev["tag"], ev["L_abs"]),
        "kms_beta": kms,
        "tag": ev["tag"],
        "backend": ev["backend"],
        "L_real": ev["L_real"],
        "L_imag": ev["L_imag"],
        "L_abs": ev["L_abs"],
    }
    if "reason" in ev:
        output["reason"] = ev["reason"]

    digest_payload = {"ts": ts, "in": inputs, "out": output, "tag": ev["tag"]}
    body = json.dumps(digest_payload, sort_keys=True, separators=(",", ":"))
    sha = hashlib.sha256(body.encode("utf-8")).hexdigest()

    L_abs_field = ev["L_abs"] if ev["L_abs"] is not None else "NA"
    reason_field = f" reason={ev['reason']}" if "reason" in ev else ""
    kms_field = "NA" if kms is None else repr(kms)
    ledger_line = (
        f"probe ts={ts} h={inputs['h']} N={inputs['N']} "
        f"re={inputs['re_s']} im={inputs['im_s']} "
        f"L_nonvanish={output['L_nonvanish']} RH_ok={output['RH_ok']} "
        f"kms_beta={kms_field} "
        f"{ev['tag']} L_abs={L_abs_field}{reason_field} sha={sha}"
    )
    _append_line(ledger_line)

    return {**output, "sha": sha, "ledger_line": ledger_line}


def zero(n: int) -> dict[str, Any]:
    """Compute the n-th nontrivial Riemann zero via mpmath.zetazero and
    log a probe at (Re=0.5, Im=γ_n).

    Returns the probe result dict with two extra keys:
      - `gamma`: γ_n as a 20-digit mpmath nstr (current preferred name)
      - `zero_im_mpmath`: alias for `gamma` (back-compat with the older
        HEAD `hunt_zeros`/`bracket_zero` surface)
      - `n`: the input ordinal

    Float64 rounding of the imaginary part means |ζ| at the probed
    point is typically ~1e-15 rather than 0 — small enough that the
    ZERO_WITNESS_TOL gunsight fires, large enough to be honest about
    the precision loss. Honest scope: mpmath, not a Lean-verified
    statement.
    """
    nn = int(n)
    if nn < 1:
        raise ValueError("zero(n) requires n >= 1")
    with mpmath.workdps(50):
        z = mpmath.zetazero(nn)
        gamma_str = mpmath.nstr(z.imag, 20)
        gamma_f = float(z.imag)
    result = probe(1, 1, 0.5, gamma_f)
    return {
        "n": nn,
        "gamma": gamma_str,
        "zero_im_mpmath": gamma_str,
        **result,
    }


def hunt_zeros(n_start: int = 1, n_end: int = 10) -> list[dict[str, Any]]:
    """Log the n_start..n_end nontrivial ζ zeros via repeated zero(n) calls.

    Each call probes at the zero (so every entry has its own ledger
    line + SHA). Prints a one-line summary per zero.
    """
    if int(n_start) < 1 or int(n_end) < int(n_start):
        raise ValueError("hunt_zeros: require 1 <= n_start <= n_end")
    hits: list[dict[str, Any]] = []
    for n in range(int(n_start), int(n_end) + 1):
        r = zero(n)
        hits.append(r)
        print(
            f"ZERO {n}: t={r['zero_im_mpmath']} "
            f"|L|={r['L_abs']} beta={r['kms_beta']} "
            f"RH_ok={r['RH_ok']} sha={r['sha'][:16]}"
        )
    return hits


def _siegelz_chunk(args: tuple[list[float], int]) -> list[float]:
    """Worker: evaluate Riemann-Siegel Z(t) at each t in chunk at given dps.

    Module-level so it pickles cleanly for multiprocessing.Pool. The
    parent process owns hits.txt; workers only compute Z(t) and return
    floats — they never touch the ledger. The seal module was already
    loaded at import time so a fork carries it forward; no subprocess
    seal check happens inside a worker.
    """
    ts, dps = args
    out: list[float] = []
    with mpmath.workdps(int(dps)):
        for t in ts:
            out.append(float(mpmath.siegelz(mpmath.mpf(t))))
    return out


def sieve_zeros(
    t_start: float,
    t_end: float,
    dps: int = 50,
    grid_density: int = 4,
    write: bool = True,
    pool_workers: int | None = None,
    flush_every: int = 100,
) -> list[dict[str, Any]]:
    """Stage 2A-Prime — sign-change sieve for ζ zeros on [t_start, t_end].

    Pipeline (Odlyzko-Schönhage-shaped, but honest scope: see below):
      1. Build a grid of M ≈ (t_end - t_start) / (avg_gap / grid_density)
         points in [t_start, t_end], padded to the next power of two for
         cosmetic symmetry with the spec sketch.
      2. Batch-evaluate Z(t) on the grid via multiprocessing.Pool.
      3. Sieve for sign changes: any consecutive pair (t_i, t_{i+1}) with
         Z(t_i) · Z(t_{i+1}) < 0 brackets at least one zero of Z (and
         hence at least one ζ zero on the critical line).
      4. Brent-refine each bracket via mpmath.findroot to ~20 digits.
      5. If write=True, log each refined zero via probe(1, 1, 0.5, t0),
         which calls _verify_seal() THEN _append_line() (which itself
         flushes + fsyncs per line — already strictly stronger than the
         "flush every flush_every lines" contract from the brief; the
         counter is used to emit a progress line every flush_every zeros
         so an operator can watch the sieve advance).
         If write=False, NOTHING is appended; we return a results list
         with t, |L|, and a dry_run=True marker, but no SHA (no ledger
         line was made, so there is no SHA to publish).

    Honest scope: this is NOT the full Odlyzko-Schönhage FFT trick
    (which computes Z on the full grid in O(M log M) via the
    Riemann-Siegel main sum re-expansion). It is a parallelized
    sign-change sieve over per-point siegelz evaluations, plus a
    refinement pass. The speed win over zetazero(n) sniping comes from
    (a) skipping the per-zero grampoint search, (b) batching the Z
    evaluations across cores, and (c) reusing one grid for all zeros in
    a window. The constant factor is real; the asymptotic improvement
    is not.

    Concurrency contract: `_append_line` takes an exclusive
    `fcntl.flock` on its open append handle, so the full sequence
    `write + flush + fsync + _update_checkpoint` is atomic per line
    against any other process that also goes through `_append_line`
    (i.e. any sibling using the kernel API). Two concurrent appender
    workflows — e.g. `zeta-burst-101-10000` alongside
    `zeta-sieve-14159-100000` — therefore queue at line granularity
    instead of racing on the checkpoint refresh, and the per-line
    SHA chain in `hits.txt` stays internally consistent with the
    recorded prefix hash in `hits.txt.checkpoint`. The Genesis seal
    covers only the preamble (lines 1-9), which appends never touch.
    Lines may still appear out of strict temporal order — fine for an
    append-only sealed ledger.

    What is NOT safe under concurrency: external backup/restore tools
    (e.g. `morningstar-tamper`'s pytest fixture that snapshots
    `hits.txt`, mutates it, then restores from the snapshot). If a
    sibling process appends a line during that mutate-restore window,
    the restore silently overwrites it. Run those tools only when the
    ledger has no other live writer.

    The multiprocessing.Pool workers only compute Z(t) and return
    floats — they never call _append_line.
    """
    t_a = float(t_start)
    t_b = float(t_end)
    if t_b <= t_a:
        raise ValueError(
            f"sieve_zeros: require t_end > t_start; got [{t_a}, {t_b}]"
        )
    if t_a < 0:
        raise ValueError("sieve_zeros: t_start must be >= 0")
    if int(dps) < 15:
        raise ValueError("sieve_zeros: dps must be >= 15 for honest |L|")
    if int(grid_density) < 2:
        raise ValueError("sieve_zeros: grid_density must be >= 2")

    # Average zero spacing at the midpoint of the interval. The classical
    # density formula is gap ≈ 2π / log(t/(2π)); guard against the
    # log<=0 region at very small t by lifting t_mid to e·2π.
    t_mid = max((t_a + t_b) / 2.0, math.e * 2.0 * math.pi)
    avg_gap = 2.0 * math.pi / math.log(t_mid / (2.0 * math.pi))
    spacing = avg_gap / float(grid_density)
    M = int(math.ceil((t_b - t_a) / spacing)) + 1
    # Pad to next power of two (cosmetic; the FFT-free path doesn't need
    # this but the spec sketch asked for N = 1 << k).
    N_pad = 1 << max(M - 1, 1).bit_length()
    if N_pad < 2:
        N_pad = 2
    actual_spacing = (t_b - t_a) / (N_pad - 1)
    t_grid = [t_a + i * actual_spacing for i in range(N_pad)]

    workers = max(1, int(pool_workers) if pool_workers else min(os.cpu_count() or 1, 8))
    chunk_size = max(1, len(t_grid) // workers)
    chunks = [
        (t_grid[i : i + chunk_size], int(dps))
        for i in range(0, len(t_grid), chunk_size)
    ]

    if workers > 1 and len(t_grid) >= 64:
        ctx = multiprocessing.get_context("fork")
        with ctx.Pool(processes=workers) as pool:
            results = pool.map(_siegelz_chunk, chunks)
        z_vals: list[float] = [v for r in results for v in r]
    else:
        z_vals = [v for chunk in chunks for v in _siegelz_chunk(chunk)]

    # Sieve for sign changes. Exact zeros (Z(t_i) == 0.0) are vanishingly
    # rare on a generic grid, but we handle them as a degenerate bracket
    # of length zero so the refinement loop doesn't divide-by-zero.
    brackets: list[tuple[float, float]] = []
    for i in range(len(z_vals) - 1):
        a_val, b_val = z_vals[i], z_vals[i + 1]
        if a_val == 0.0:
            brackets.append((t_grid[i], t_grid[i]))
        elif a_val * b_val < 0.0:
            brackets.append((t_grid[i], t_grid[i + 1]))

    found: list[dict[str, Any]] = []
    seen_since_flush = 0
    interrupted = False
    # Wrap the refinement loop so SIGINT (Ctrl-C, workflow stop) returns
    # the partial-but-correct set of zeros instead of an unwound traceback.
    # Each iteration is atomic w.r.t. the ledger (probe() either appended
    # a full line or didn't run at all), so a clean interrupt at any
    # boundary leaves hits.txt in a valid state.
    try:
        for a, b in brackets:
            with mpmath.workdps(int(dps)):
                if a == b:
                    t0 = mpmath.mpf(a)
                else:
                    # The brief said "Brent". mpmath has no true Brent
                    # solver — its 1-D catalog is bisect / illinois /
                    # pegasus / anderson / ridder / secant / muller.
                    # We use `anderson` (mpmath defines it as a subclass
                    # of `Pegasus`, the Illinois-family bracket-preserving
                    # solver: superlinear, always keeps the root inside
                    # the bracket by replacing the endpoint whose function
                    # value has the same sign as the new midpoint). It's
                    # the Brent-spirit choice and matches the brief's
                    # bracket-preservation contract.
                    #
                    # We tried `ridder` first (formally closer to Brent),
                    # but on `siegelz` at dps=50 it fails on a real
                    # bracket (γ≈48) with "Could not find root within
                    # given tolerance" — siegelz uses the Riemann-Siegel
                    # asymptotic, whose own noise floor exceeds dps=50
                    # machine epsilon, and ridder demands the latter.
                    # Anderson tolerates that gap. Bisect would also
                    # work but is exponentially slower in the bracket
                    # width.
                    t0 = mpmath.findroot(
                        mpmath.siegelz,
                        (mpmath.mpf(a), mpmath.mpf(b)),
                        solver="anderson",
                    )
                t0_f = float(t0)
                t0_str = mpmath.nstr(t0, 20)
                zeta_val = mpmath.zeta(mpmath.mpc("0.5", t0))
                L_abs_str = mpmath.nstr(abs(zeta_val), 20)

            entry: dict[str, Any] = {
                "t": t0_str,
                "L_abs": L_abs_str,
                "RH_ok": True,
            }
            if write:
                # probe() runs _verify_seal() and then _append_line(),
                # which is already per-line flush + fsync. We re-purpose
                # the flush_every counter as a progress-print cadence so
                # a long sieve is observable from the workflow tail.
                r = probe(1, 1, 0.5, t0_f)
                entry["sha"] = r["sha"]
                entry["RH_ok"] = r["RH_ok"]
                entry["dry_run"] = False
                seen_since_flush += 1
                if seen_since_flush >= int(flush_every):
                    seen_since_flush = 0
                    print(
                        f"SIEVE PROGRESS: {len(found) + 1} zeros refined "
                        f"(latest t={t0_str}, |L|={L_abs_str})",
                        flush=True,
                    )
            else:
                entry["dry_run"] = True
                print(
                    f"SIEVE DRY {len(found) + 1}: t={t0_str} |L|={L_abs_str}",
                    flush=True,
                )
            found.append(entry)
    except KeyboardInterrupt:
        interrupted = True
        print(
            f"SIEVE INTERRUPTED: {len(found)} zeros refined out of "
            f"{len(brackets)} brackets; returning partial result. "
            f"(ledger is consistent — probe() is atomic per line)",
            flush=True,
        )
    if interrupted:
        # Surface the partial-state marker so callers (and the CLI
        # summary line) can tell the difference between a clean
        # completion and a graceful interrupt.
        for entry in found:
            entry.setdefault("partial", True)
    return found


def elliptic_stub(label: str, re_s: float, im_s: float) -> dict[str, Any]:
    """Reserve the elliptic-curve namespace without computing L(E, s).

    The mpmath backend cannot evaluate elliptic L-functions. Rather than
    silently route to `probe(1, conductor, ...)` (which would compute a
    Dirichlet L, not an elliptic L), this writes a SHA-stamped *intent*
    line tagged `ELLIPTIC_STUB` with `reason=elliptic_L_requires_sage`.

    When SageMath is wired in later, the hash chain proves we asked for
    this label at this s before the real backend existed.

    `label` is validated against `ELLIPTIC_LABEL_RE` (Cremona-style
    labels like `37a1`, `143b2`). The seal is verified before the
    append, exactly as in `probe()`.
    """
    if not isinstance(label, str) or not ELLIPTIC_LABEL_RE.match(label):
        raise ValueError(
            f"elliptic_stub: label must match {ELLIPTIC_LABEL_RE.pattern}"
        )
    _verify_seal()

    ts = time.time_ns()
    re_f = float(re_s)
    im_f = float(im_s)

    digest_payload = {
        "ts": ts,
        "kind": "elliptic_stub",
        "label": label,
        "re_s": re_f,
        "im_s": im_f,
        "tag": "ELLIPTIC_STUB",
        "reason": "elliptic_L_requires_sage",
    }
    body = json.dumps(digest_payload, sort_keys=True, separators=(",", ":"))
    sha = hashlib.sha256(body.encode("utf-8")).hexdigest()

    ledger_line = (
        f"elliptic_stub ts={ts} label={label} re={re_f} im={im_f} "
        f"tag=ELLIPTIC_STUB axioms=[] RH_ok=NA kms_beta=NA "
        f"reason=elliptic_L_requires_sage sha={sha}"
    )
    _append_line(ledger_line)

    return {
        "label": label,
        "re_s": re_f,
        "im_s": im_f,
        "tag": "ELLIPTIC_STUB",
        "backend": "none",
        "reason": "elliptic_L_requires_sage",
        "axioms": [],
        "RH_ok": None,
        "kms_beta": None,
        "sha": sha,
        "ledger_line": ledger_line,
    }


def bracket_zero(n: int, window: float = 1e-6) -> dict[str, Any]:
    """Tight critical-line sweep around the n-th ζ zero.

    Calls scan_critical_line over [t0-window, t0+window] with step
    window/5. Note that scan_critical_line uses float steps, so the
    sweep typically won't actually land within ZERO_WITNESS_TOL (1e-12)
    of t0 — call zero(n) separately if you want the exact zero logged.
    The sweep does show |L| dipping toward the zero in the L_abs
    field of each probed ledger line, which is the "radar coverage"
    receipt the bracket exists to produce.
    """
    if int(n) < 1:
        raise ValueError("bracket_zero: n must be >= 1")
    if window <= 0:
        raise ValueError("bracket_zero: window must be > 0")
    with mpmath.workdps(50):
        t0 = float(mpmath.zetazero(int(n)).imag)
    step = window / 5.0
    scan = scan_critical_line(1, t0 - window, t0 + window, step, 1)
    return {
        "n": int(n),
        "t0": t0,
        "window": window,
        "step": step,
        "zeros_found": scan,
        "zeros_count": len(scan),
    }


def scan_critical_line(
    N: int,
    im_start: float,
    im_end: float,
    step: float = 0.01,
    h: int = 1,
) -> list[dict[str, Any]]:
    """Sweep the critical line Re(s) = 0.5 for L-function (h, N).

    Every grid point is probed and appended to data/hits.txt (so the
    sweep is fully audit-trailed). Points where the honest-scope
    gunsight fires (RH_ok=True, i.e. tag=MPMATH_ZETA AND
    |ζ| < ZERO_WITNESS_TOL on the critical line) are returned as
    "zero hits".

    Honest scope: a fixed-step sweep almost never lands within
    ZERO_WITNESS_TOL (1e-12) of an actual zero, so this function will
    typically return []. It is a coverage tool, not a zero finder —
    use `kernel.zero(n)` (mpmath.zetazero) for actual zeros.
    """
    if step <= 0:
        raise ValueError("scan_critical_line: step must be > 0")
    if im_end < im_start:
        raise ValueError("scan_critical_line: im_end must be >= im_start")
    NN = int(N)
    hh = int(h)
    start = float(im_start)
    end = float(im_end)
    delta = float(step)
    hits: list[dict[str, Any]] = []
    i = 0
    while True:
        t = start + i * delta
        if t > end + 1e-12:
            break
        r = probe(hh, NN, 0.5, t)
        if r.get("RH_ok") is True:
            hits.append(
                {
                    "t": t,
                    "im": t,
                    "sha": r["sha"],
                    "L_abs": r.get("L_abs"),
                    "kms_beta": r.get("kms_beta"),
                    "tag": r.get("tag"),
                    "ledger_line": r["ledger_line"],
                }
            )
            print(
                f"ZERO: Im={t:.6f} sha={r['sha']} "
                f"kms_beta={r.get('kms_beta')} tag={r.get('tag')}"
            )
        i += 1
    return hits


def scan_plane(
    h: int,
    N: int,
    re_min: float,
    re_max: float,
    im_min: float,
    im_max: float,
    grid: float = 0.1,
    max_probes: int = 10000,
) -> dict[str, Any]:
    """Full 2D sweep of the (Re(s), Im(s)) rectangle for L-function (h, N).

    Every grid point is probed and appended to data/hits.txt. Useful
    for documenting that an entire region was inspected (off-line zero
    hunt, KMS-temperature region surveys, etc.).

    `max_probes` is a hard safety cap to keep the ledger from
    exploding; the function raises if the grid would exceed it.
    """
    if grid <= 0:
        raise ValueError("scan_plane: grid must be > 0")
    if re_max < re_min or im_max < im_min:
        raise ValueError("scan_plane: max must be >= min on both axes")
    n_re = int((re_max - re_min) / grid) + 1
    n_im = int((im_max - im_min) / grid) + 1
    n_total = n_re * n_im
    if n_total > max_probes:
        raise ValueError(
            f"scan_plane: would emit {n_total} probes (cap is {max_probes}); "
            "raise max_probes explicitly to proceed"
        )
    hits = 0
    for i in range(n_re):
        re_s = re_min + i * grid
        if re_s > re_max:
            break
        for j in range(n_im):
            im_s = im_min + j * grid
            if im_s > im_max:
                break
            out = probe(int(h), int(N), float(re_s), float(im_s))
            if out["RH_ok"] and not out["L_nonvanish"]:
                hits += 1
    return {"probed": n_total, "gunsight_hits": hits, "grid": grid}


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("usage: kernel.py h N re_s im_s", file=sys.stderr)
        sys.exit(2)
    out = probe(int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]))
    print(json.dumps(out, sort_keys=True))
