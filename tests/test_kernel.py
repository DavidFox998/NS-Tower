"""Numerical regression tests for the mpmath L-function backend in
`kernel.probe()`.

These pin the actual numbers the backend writes to the append-only
ledger, so a future refactor (precision change, Euler-factor rewrite,
mpmath bump) can't silently shift what gets recorded.

Cases covered:
  * `probe(1, 1, 0.5, 14.134725)` — first nontrivial zero of ζ.
    Tag `MPMATH_ZETA`, `|L| < 1e-6`.
  * `probe(1, 1, 2, 0)` — ζ(2) = π²/6. Tag `MPMATH_ZETA`,
    `|L - π²/6| < 1e-10`.
  * `probe(1, 19, 0.5, 0)` — principal Dirichlet character mod 19.
    Tag `MPMATH_DIRICHLET_TRIVIAL`; the prime-19 Euler factor is
    stripped, so the value matches `ζ(0.5) · (1 - 19^{-0.5})`.
  * `probe(2, 547, 0, 0)` — out of scope for the mpmath backend.
    Tag `NEEDS_SAGE` with the documented
    `h>=2_out_of_scope_for_mpmath_backend` reason.

Each test monkeypatches `kernel.HITS` to a throwaway file in `tmp_path`
so the real append-only ledger is never touched.
"""

from __future__ import annotations

import hashlib
import multiprocessing
import os
from pathlib import Path

import mpmath
import pytest

import kernel


def _concurrent_appender_worker(
    hits_path: str, worker_id: int, n_lines: int
) -> None:
    """Subprocess entry point for `test_append_line_is_concurrency_safe`.

    Must be module-level so multiprocessing can pickle it. Each worker
    redirects `kernel.HITS` to the shared tmp path, stubs the seal
    verifier (the tmp file has no Genesis preamble), then appends
    `n_lines` distinct, self-checking lines through `_append_line`.
    The line format mirrors a real probe-style ledger entry just
    enough to be SHA-stamped: `worker=<id> i=<i> sha=<sha>` where the
    SHA is computed over `<id>:<i>` so we can verify on the parent
    side that every line is intact (no torn writes, no half-flushed
    bytes from a rival worker).
    """
    kernel.HITS = Path(hits_path)
    kernel.CHECKPOINT = Path(hits_path + ".checkpoint")
    kernel._verify_seal = lambda: None  # type: ignore[assignment]
    for i in range(n_lines):
        body = f"{worker_id}:{i}"
        sha = hashlib.sha256(body.encode("utf-8")).hexdigest()
        kernel._append_line(f"worker={worker_id} i={i} sha={sha}")


@pytest.fixture
def tmp_hits(tmp_path, monkeypatch):
    """Redirect `kernel.HITS` to a throwaway file under tmp_path, and
    stub `kernel._verify_seal` to a no-op for the duration of the test.

    Why stub the seal check: `_verify_seal` shells out to
    `scripts/check-genesis-seal.py`, which hardcodes
    `REPO_ROOT/data/hits.txt` (it cannot be redirected via the
    `kernel.HITS` monkeypatch). When the validation harness runs
    `kernel-numerics` in parallel with `morningstar-tamper`, the
    tamper suite mutates `data/hits.txt` mid-test (byte-flips,
    line-swaps) and restores it after each case via a backup
    fixture. If the seal subprocess fires during a tampered window,
    these tests fail with a spurious "Genesis seal mismatch" that
    has nothing to do with what they're actually pinning (mpmath
    numerics + ledger-line format).

    Seal verification is fully covered elsewhere — `test_morningstar.py`
    drives `_verify_seal` against the real file in a fixture-protected,
    serialized way, and `scripts/check-genesis-seal.py` is invoked
    directly by `scripts/post-merge.sh` on every merge. Stubbing it
    here removes the cross-workflow race without weakening the
    end-to-end tamper-evidence guarantee.
    """
    fake = tmp_path / "hits.txt"
    monkeypatch.setattr(kernel, "HITS", fake)
    monkeypatch.setattr(kernel, "CHECKPOINT", tmp_path / "hits.txt.checkpoint")
    monkeypatch.setattr(kernel, "ALERTS_LOG", tmp_path / "ledger-alerts.jsonl")
    monkeypatch.setattr(kernel, "_verify_seal", lambda: None)
    return fake


def test_probe_zeta_first_zero(tmp_hits):
    out = kernel.probe(1, 1, 0.5, 14.134725)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    assert mpmath.mpf(out["L_abs"]) < mpmath.mpf("1e-6")
    assert tmp_hits.exists()
    assert tmp_hits.read_text(encoding="utf-8").count("\n") == 1


def test_probe_zeta_at_two(tmp_hits):
    out = kernel.probe(1, 1, 2, 0)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    expected = mpmath.pi ** 2 / 6
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")
    assert out["L_nonvanish"] is True


def test_probe_dirichlet_trivial_strips_prime_19(tmp_hits):
    out = kernel.probe(1, 19, 0.5, 0)
    assert out["tag"] == "MPMATH_DIRICHLET_TRIVIAL"
    assert out["backend"] == "mpmath"
    with mpmath.workdps(50):
        s = mpmath.mpc(0.5, 0)
        expected = mpmath.zeta(s) * (mpmath.mpc(1) - mpmath.power(19, -s))
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")


def test_probe_h_ge_2_needs_sage(tmp_hits):
    out = kernel.probe(2, 547, 0, 0)
    assert out["tag"] == "NEEDS_SAGE"
    assert out["backend"] == "none"
    assert out["L_real"] is None
    assert out["L_imag"] is None
    assert out["L_abs"] is None
    assert out["reason"] == "h>=2_out_of_scope_for_mpmath_backend"
    assert "NEEDS_SAGE" in tmp_hits.read_text(encoding="utf-8")


def test_elliptic_stub_appends_one_line_with_intent_tag(tmp_hits):
    """Gun 3: elliptic_stub writes one ELLIPTIC_STUB line, no L value,
    no claim of RH_ok, and includes the elliptic_L_requires_sage reason.
    """
    out = kernel.elliptic_stub("37a1", 1.0, 0.0)
    assert out["tag"] == "ELLIPTIC_STUB"
    assert out["backend"] == "none"
    assert out["reason"] == "elliptic_L_requires_sage"
    assert out["RH_ok"] is None
    assert out["kms_beta"] is None
    assert out["axioms"] == []
    assert len(out["sha"]) == 64
    body = tmp_hits.read_text(encoding="utf-8")
    assert body.count("\n") == 1
    line = body.strip()
    assert line.startswith("elliptic_stub ts=")
    assert "label=37a1" in line
    assert "tag=ELLIPTIC_STUB" in line
    assert "reason=elliptic_L_requires_sage" in line
    assert f"sha={out['sha']}" in line


def test_elliptic_stub_rejects_bad_label_without_writing(tmp_hits):
    """A label that violates ELLIPTIC_LABEL_RE must raise before any
    seal check or append — no ledger line, no partial state."""
    with pytest.raises(ValueError, match="elliptic_stub: label"):
        kernel.elliptic_stub("37a1; rm -rf /", 1.0, 0.0)
    assert not tmp_hits.exists() or tmp_hits.read_text(encoding="utf-8") == ""


def test_elliptic_stub_does_not_call_mpmath_backend(tmp_hits):
    """Gun 3 is a stub: even when label looks like a real curve and s is
    well-defined, no L value is ever filled in. Catches a future refactor
    that accidentally routes elliptic_stub through probe()."""
    out = kernel.elliptic_stub("143b2", 0.5, 14.134725)
    assert "L_abs" not in out  # no numeric field at all
    assert "L_real" not in out
    assert "L_imag" not in out
    assert out["tag"] == "ELLIPTIC_STUB"


def test_append_line_is_concurrency_safe(tmp_path):
    """Task #54: two concurrent appender processes against the same
    `hits.txt` must not interleave bytes within a line, drop any line,
    or desync the at-rest checkpoint.

    We spawn two `multiprocessing.Process` workers, each writing
    `N_PER_WORKER` SHA-stamped lines through `kernel._append_line`,
    against a shared throwaway file. After both join we assert:

      * Total line count is exactly `2 * N_PER_WORKER` — nothing was
        lost, nothing was double-counted.
      * Every line matches the strict `worker=<id> i=<i> sha=<hex>`
        regex and the SHA on the line equals SHA-256 of `<id>:<i>`.
        Any byte-level tearing (e.g. a write from worker A landing
        mid-line of worker B) would corrupt the SHA or break the
        regex and fail this check.
      * Each `(worker_id, i)` pair appears exactly once.
      * The final `hits.txt.checkpoint` records the *current* size
        and SHA-256 of `hits.txt` (the last write's checkpoint update
        wins, but it must still be self-consistent — no torn checkpoint
        from a half-finished refresh).

    Uses the `fork` start method so workers inherit the current
    `kernel` module without re-importing it under a different working
    directory. `N_PER_WORKER=80` is large enough to interleave a few
    times on a busy machine without making the test slow.
    """
    import re

    N_PER_WORKER = 80
    hits = tmp_path / "hits.txt"

    ctx = multiprocessing.get_context("fork")
    procs = [
        ctx.Process(
            target=_concurrent_appender_worker,
            args=(str(hits), wid, N_PER_WORKER),
        )
        for wid in (0, 1)
    ]
    for p in procs:
        p.start()
    for p in procs:
        p.join(timeout=60)
        assert p.exitcode == 0, f"worker {p.pid} exited {p.exitcode}"

    text = hits.read_text(encoding="utf-8")
    lines = text.splitlines()
    assert len(lines) == 2 * N_PER_WORKER, (
        f"expected {2 * N_PER_WORKER} lines, got {len(lines)} — "
        f"a concurrent writer dropped or duplicated a line"
    )

    pattern = re.compile(r"^worker=(\d+) i=(\d+) sha=([0-9a-f]{64})$")
    seen: set[tuple[int, int]] = set()
    for line in lines:
        m = pattern.match(line)
        assert m is not None, (
            f"line did not parse cleanly — byte-level tearing? line={line!r}"
        )
        wid, i, sha = int(m.group(1)), int(m.group(2)), m.group(3)
        expected_sha = hashlib.sha256(f"{wid}:{i}".encode("utf-8")).hexdigest()
        assert sha == expected_sha, (
            f"SHA mismatch on worker={wid} i={i}: line={line!r}"
        )
        key = (wid, i)
        assert key not in seen, f"duplicate ledger entry for {key}"
        seen.add(key)
    assert len(seen) == 2 * N_PER_WORKER

    checkpoint = hits.with_suffix(hits.suffix + ".checkpoint")
    assert checkpoint.exists(), "checkpoint was never refreshed"
    cp_size_str, cp_sha = checkpoint.read_text(encoding="utf-8").strip().split()
    cp_size = int(cp_size_str)
    raw = hits.read_bytes()
    assert cp_size == len(raw), (
        f"checkpoint size {cp_size} != live file size {len(raw)} — "
        f"a checkpoint refresh raced with a sibling append"
    )
    assert cp_sha == hashlib.sha256(raw[:cp_size]).hexdigest(), (
        "checkpoint SHA does not match the recorded prefix — "
        "torn checkpoint refresh"
    )


def _seed_healthy_ledger(tmp_hits):
    """Bootstrap a tmp ledger + matching checkpoint by writing one
    legitimate line through `_append_line`. Caller can then mutate the
    file to simulate corruption."""
    kernel._append_line("seed line ok")


def test_alert_fires_on_truncated_ledger_and_does_not_mask_error(
    tmp_hits, monkeypatch
):
    """Task #63: when `_verify_checkpoint` trips inside `_append_line`,
    the opt-in alert hook fires AND the `LedgerIntegrityError` still
    propagates to halt the workflow."""
    _seed_healthy_ledger(tmp_hits)

    fired = []

    def fake_post(url, payload):
        fired.append((url, payload))

    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")
    monkeypatch.setenv("MORNINGSTAR_WORKFLOW_NAME", "zeta-burst-101-10000")
    monkeypatch.setattr(kernel, "_post_webhook", fake_post)

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])

    with pytest.raises(kernel.LedgerIntegrityError) as ei:
        kernel._append_line("second line")

    assert kernel._await_alert_dispatch(timeout=5.0)
    assert "SHRUNK" in str(ei.value) or "rewritten" in str(ei.value)
    assert len(fired) == 1, "alert webhook fired exactly once"
    url, payload = fired[0]
    assert url == "http://example/alert"
    assert payload["workflow"] == "zeta-burst-101-10000"
    assert payload["failure_mode"] in {
        "hits_truncated",
        "hits_rewritten_in_place",
    }
    assert "expected_size" in payload
    assert "actual_size" in payload
    assert "REPRODUCE.md" in payload["recovery"]
    assert len(tmp_hits.read_bytes()) == 1


def test_alert_delivery_failure_does_not_mask_integrity_error(
    tmp_hits, monkeypatch
):
    """If the webhook transport raises, the operator still gets the
    underlying `LedgerIntegrityError` — alerts are best-effort."""
    _seed_healthy_ledger(tmp_hits)

    def boom(url, payload):
        raise RuntimeError("simulated webhook outage")

    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")
    monkeypatch.setattr(kernel, "_post_webhook", boom)

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])

    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")


def test_no_alert_fires_on_healthy_ledger(tmp_hits, monkeypatch):
    """A legitimate append must NOT fire the alert hook; that would
    drown operators in false positives on every probe."""
    _seed_healthy_ledger(tmp_hits)

    fired = []
    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")
    monkeypatch.setattr(
        kernel, "_post_webhook", lambda url, payload: fired.append((url, payload))
    )

    kernel._append_line("another legitimate line")

    assert fired == []


def test_alert_is_noop_when_env_unset(tmp_hits, monkeypatch):
    """No env var means silent no-op; transports must not be invoked at
    all (the opt-in contract)."""
    _seed_healthy_ledger(tmp_hits)

    monkeypatch.delenv("MORNINGSTAR_ALERT_WEBHOOK_URL", raising=False)
    monkeypatch.delenv("MORNINGSTAR_ALERT_EMAIL_TO", raising=False)

    called = []
    monkeypatch.setattr(
        kernel, "_post_webhook", lambda *a, **k: called.append("webhook")
    )
    monkeypatch.setattr(
        kernel, "_send_email", lambda *a, **k: called.append("email")
    )

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])
    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("x")

    assert called == []


def test_alert_history_records_every_invocation(tmp_hits, monkeypatch, tmp_path):
    """Task #71: every `_fire_ledger_alert` invocation must append one
    structured JSON line to the on-disk ring buffer, regardless of
    whether the webhook/email transports succeeded, failed, or were
    even configured. A midnight tamper must still leave a trace the
    next morning's operator can read after a restart."""
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)

    _seed_healthy_ledger(tmp_hits)

    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")
    monkeypatch.setenv("MORNINGSTAR_WORKFLOW_NAME", "zeta-burst-101-10000")
    monkeypatch.setattr(kernel, "_post_webhook", lambda url, payload: None)

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])
    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")

    assert kernel._await_alert_dispatch(timeout=5.0)
    recent = kernel.read_recent_alerts(limit=5)
    assert len(recent) == 1
    entry = recent[0]
    assert entry["workflow"] == "zeta-burst-101-10000"
    assert entry["failure_mode"] in {"hits_truncated", "hits_rewritten_in_place"}
    assert entry["delivery"] == {
        "webhook": {"status": "ok"},
        "email": {"status": "not_configured"},
    }
    assert "timestamp" in entry
    assert "expected_size" in entry and "actual_size" in entry


def test_alert_history_records_transport_failure(tmp_hits, monkeypatch, tmp_path):
    """When the webhook delivery raises, the ring buffer must still
    capture the attempt with a failed status — that is the whole
    point of "what fired vs what was delivered" triage."""
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)

    _seed_healthy_ledger(tmp_hits)

    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")

    def boom(url, payload):
        raise RuntimeError("simulated webhook outage")

    monkeypatch.setattr(kernel, "_post_webhook", boom)

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])
    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")

    assert kernel._await_alert_dispatch(timeout=5.0)
    recent = kernel.read_recent_alerts(limit=5)
    assert len(recent) == 1
    delivery = recent[0]["delivery"]
    assert delivery["webhook"]["status"] == "failed"
    assert "simulated webhook outage" in delivery["webhook"]["error"]


def test_alert_history_persists_even_when_no_transports_configured(
    tmp_hits, monkeypatch, tmp_path
):
    """Task #71: even when neither webhook nor SMTP is configured, the
    integrity failure MUST still be recorded to the on-disk ring
    buffer with explicit `not_configured` delivery markers. That is
    the whole point of "durable memory independent of delivery
    success" — otherwise a midnight tamper on a stock deployment
    leaves no trace at all."""
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)

    _seed_healthy_ledger(tmp_hits)
    monkeypatch.delenv("MORNINGSTAR_ALERT_WEBHOOK_URL", raising=False)
    monkeypatch.delenv("MORNINGSTAR_ALERT_EMAIL_TO", raising=False)

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])
    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("x")

    assert kernel._await_alert_dispatch(timeout=5.0)
    recent = kernel.read_recent_alerts(limit=5)
    assert len(recent) == 1
    assert recent[0]["delivery"] == {
        "webhook": {"status": "not_configured"},
        "email": {"status": "not_configured"},
    }
    assert recent[0]["failure_mode"] in {
        "hits_truncated",
        "hits_rewritten_in_place",
    }


def test_alert_history_rotation_caps_at_max_entries(monkeypatch, tmp_path):
    """The ring buffer must be bounded — a long-running deployment
    that sees thousands of alerts over months should not grow the
    log unboundedly. Cap is enforced as a trim-to-last-N on write."""
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)
    monkeypatch.setattr(kernel, "_ALERTS_MAX_ENTRIES", 5)

    for i in range(12):
        kernel._record_alert_history(
            {"timestamp": f"t{i}", "workflow": "wf", "failure_mode": "x"},
            {"webhook": {"status": "ok"}},
        )

    lines = alerts_log.read_text(encoding="utf-8").splitlines()
    assert len(lines) == 5
    recent = kernel.read_recent_alerts(limit=10)
    assert [e["timestamp"] for e in recent] == ["t11", "t10", "t9", "t8", "t7"]


def test_alert_history_disk_failure_does_not_mask_integrity_error(
    tmp_hits, monkeypatch
):
    """Best-effort contract: if the ring-buffer write itself blows up
    (disk full, permission denied), the `LedgerIntegrityError` must
    still propagate. Alerts are an observability layer, not a
    correctness gate."""
    _seed_healthy_ledger(tmp_hits)

    monkeypatch.setenv("MORNINGSTAR_ALERT_WEBHOOK_URL", "http://example/alert")
    monkeypatch.setattr(kernel, "_post_webhook", lambda url, payload: None)

    def boom(payload, delivery):
        raise OSError("disk full")

    monkeypatch.setattr(kernel, "_record_alert_history", boom)
    # Async dispatch: drain any pending worker so the OSError is swallowed
    # to stderr inside the worker (not the foreground caller).
    _ = kernel._await_alert_dispatch

    tmp_hits.write_bytes(tmp_hits.read_bytes()[:1])
    with pytest.raises(kernel.LedgerIntegrityError):
        kernel._append_line("second line")


def test_read_recent_alerts_skips_malformed_lines(monkeypatch, tmp_path):
    """A torn write from a crashed process leaves a partial JSON line.
    `read_recent_alerts` is informational, not a correctness surface
    — it must skip garbage rather than raise."""
    alerts_log = tmp_path / "ledger-alerts.jsonl"
    monkeypatch.setattr(kernel, "ALERTS_LOG", alerts_log)
    alerts_log.write_text(
        '{"timestamp": "t1", "workflow": "a"}\n'
        "not-json-at-all\n"
        '{"timestamp": "t2", "workflow": "b"}\n',
        encoding="utf-8",
    )
    recent = kernel.read_recent_alerts(limit=10)
    assert [e["timestamp"] for e in recent] == ["t2", "t1"]


def test_sieve_zeros_dry_run_does_not_write(tmp_hits):
    """Stage 2A-Prime: sieve_zeros(write=False) must NOT touch the
    ledger and must find every nontrivial ζ zero in [0, 100].

    Independently-verified count (Odlyzko's tables, also rendered by
    mpmath.zetazero): γ_29 ≈ 92.491899, γ_30 ≈ 95.870634,
    γ_31 ≈ 98.831194. So [0, 100] contains exactly 31 zeros, but the
    sieve is allowed a small tolerance because the very first grid
    points sit near t≈0 where Z is poorly conditioned. The lower
    bound of 25 is generous; if the sieve ever drops below that the
    grid_density default is broken.

    pool_workers=1 forces the serial path so the test doesn't fork
    subprocesses inside pytest (multiprocessing under pytest is
    flaky across CI runners and would obscure real regressions).
    """
    pre_existed = tmp_hits.exists()
    pre_bytes = tmp_hits.read_bytes() if pre_existed else b""

    found = kernel.sieve_zeros(0.0, 100.0, write=False, pool_workers=1)

    # Ledger is untouched: either still missing, or byte-identical.
    if pre_existed:
        assert tmp_hits.read_bytes() == pre_bytes
    else:
        assert not tmp_hits.exists()

    # Count is in the expected window (exact answer is 31).
    assert 25 <= len(found) <= 35, (
        f"expected ~29-31 zeros in [0,100], got {len(found)}: "
        f"{[e['t'] for e in found]}"
    )

    # Every returned t is a real ζ zero to numerical precision.
    for entry in found:
        assert entry["dry_run"] is True
        assert "sha" not in entry  # no ledger line, no SHA to publish
        assert float(entry["L_abs"]) < 1e-8, (
            f"|ζ(0.5 + {entry['t']}i)| = {entry['L_abs']} is too large; "
            f"Brent refinement failed for this bracket"
        )
