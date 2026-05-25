"""Layer 7 (Application) — MorningStar-Lab v1.9 "Three Guns" REPL/CLI.

Three explicitly-typed entry points so a probe's *intent* is visible on
the command line, not inferred from `(h, N)`:

  Gun 1 — Zeta sniper    (mpmath.zetazero exact zero, axioms=[])
    zeta_sniper(n)          alias of kernel.zero(n)
    zeta_burst(n_start,n_end)   alias of kernel.hunt_zeros
    bracket_riemann_zero(n,eps) alias of kernel.bracket_zero
    zeta_sieve(t_start,t_end[,write=True])  Stage 2A-Prime:
      sign-change sieve via mpmath.siegelz + multiprocessing.Pool.
      write=False prints zeros but does NOT touch the ledger
      (dry-run path used to validate the sieve before firing it
      against the live append-only file).

  Gun 2 — Dirichlet radar (principal χ₀ via mpmath Euler-factor strip)
    dirichlet_probe(N,re,im[,char])
      char=0 (principal) routes to kernel.probe(1,N,re,im).
      char!=0 returns NEEDS_SAGE without writing a ledger line.

  Gun 3 — Elliptic stub   (no evaluation; SHA-stamped intent only)
    elliptic_probe(label,re,im)   alias of kernel.elliptic_stub.
      Writes a tag=ELLIPTIC_STUB line so a later Sage-backed run can
      prove we asked first.

The legacy single-gun commands (`probe`, `zero`, `hunt_zeros`,
`bracket_zero`, `scan_critical_line`, `scan_line`, `scan_plane`) all
still work unchanged — Three-Guns is additive.

Usage:
  python lab.py                                          # banner + REPL
  python lab.py -c "zeta_sniper(6709)"
  python lab.py -c "dirichlet_probe(1094, 0.5, 0)"
  python lab.py -c "elliptic_probe(37a1, 1, 0)"
  python lab.py -c "bracket_riemann_zero(1, 1e-4)"
"""

from __future__ import annotations

import argparse
import json
import re
import sys

import kernel

BANNER = (
    "MorningStar-Lab v1.9 Three Guns. 4D Ready. Axes: W=h Z=N X=Re Y=Im\n"
    "  Gun 1 (Zeta sniper):    zeta_sniper | zeta_burst | bracket_riemann_zero\n"
    "  Gun 2 (Dirichlet radar): dirichlet_probe\n"
    "  Gun 3 (Elliptic stub):   elliptic_probe\n"
    "  Legacy:                  probe | zero | hunt_zeros | bracket_zero | "
    "scan_critical_line | scan_line | scan_plane"
)


def _split_args(rest: str) -> list[str]:
    rest = rest.strip()
    if rest.startswith("(") and rest.endswith(")"):
        rest = rest[1:-1]
    return [p for p in re.split(r"[,\s]+", rest) if p]


def _parse_probe(expr: str) -> tuple[int, int, float, float]:
    s = expr.strip()
    if not s.startswith("probe"):
        raise ValueError(f"unknown command: {expr!r}")
    parts = _split_args(s[len("probe") :])
    if len(parts) != 4:
        raise ValueError(f"probe needs 4 args (h N re_s im_s); got {len(parts)}")
    h, N, re_s, im_s = parts
    return int(h), int(N), float(re_s), float(im_s)


def _parse_zero(expr: str) -> int:
    parts = _split_args(expr.strip()[len("zero") :])
    if len(parts) != 1:
        raise ValueError(f"zero needs 1 arg (n); got {len(parts)}")
    return int(parts[0])


def _parse_args(expr: str, head: str, n: int) -> list[str]:
    parts = _split_args(expr.strip()[len(head) :])
    if len(parts) != n:
        raise ValueError(f"{head} needs {n} args; got {len(parts)}")
    return parts


def _parse_args_range(expr: str, head: str, lo: int, hi: int) -> list[str]:
    parts = _split_args(expr.strip()[len(head) :])
    if not (lo <= len(parts) <= hi):
        raise ValueError(
            f"{head} needs {lo}..{hi} args; got {len(parts)}"
        )
    return parts


def _parse_scan(expr: str) -> tuple[int, float, float, float]:
    parts = _split_args(expr.strip()[len("scan_critical_line") :])
    if len(parts) not in (3, 4):
        raise ValueError(
            f"scan_critical_line needs 3 or 4 args (N im_start im_end [step]); got {len(parts)}"
        )
    N = int(parts[0])
    im_start = float(parts[1])
    im_end = float(parts[2])
    step = float(parts[3]) if len(parts) == 4 else 0.01
    return N, im_start, im_end, step


def _format_result(out: dict) -> str:
    pretty = {k: v for k, v in out.items() if k != "ledger_line"}
    rendered = json.dumps(pretty, sort_keys=True, indent=2, default=str)
    if "ledger_line" in out:
        return rendered + "\n  ledger: " + out["ledger_line"]
    return rendered


def _short_sha(sha: str) -> str:
    return sha[:8] if sha else "?"


def _run_zeta_sniper(n: int) -> dict:
    """Gun 1: exact n-th Riemann zero via mpmath.zetazero. axioms=[]."""
    out = kernel.zero(int(n))
    l_abs = out.get("L_abs") or "NA"
    print(
        f"ZETA SNIPER n={out['n']}: t={out['gamma']} "
        f"|L|={l_abs} RH_ok={out['RH_ok']} sha={_short_sha(out['sha'])}"
    )
    return out


def _run_zeta_burst(n_start: int, n_end: int) -> list[dict]:
    """Gun 1 (burst): zeros n_start..n_end via kernel.hunt_zeros."""
    return kernel.hunt_zeros(int(n_start), int(n_end))


def _parse_zeta_sieve(expr: str) -> tuple[float, float, bool]:
    """Parse `zeta_sieve(t_start, t_end[, write=False])`.

    Accepts: positional t_start and t_end (required), optional
    `write=True|False` keyword as the third token. Any other token or
    keyword raises ValueError BEFORE the kernel is called, so a typo
    can't leak into the live ledger.
    """
    parts = _split_args(expr.strip()[len("zeta_sieve") :])
    if not (2 <= len(parts) <= 3):
        raise ValueError(
            f"zeta_sieve needs 2 or 3 args (t_start t_end [write=BOOL]); got {len(parts)}"
        )
    t_start = float(parts[0])
    t_end = float(parts[1])
    write = True
    if len(parts) == 3:
        token = parts[2]
        if "=" not in token:
            raise ValueError(
                f"zeta_sieve third arg must be `write=True` or `write=False`; got {token!r}"
            )
        key, val = token.split("=", 1)
        if key.strip() != "write":
            raise ValueError(
                f"zeta_sieve only accepts the `write` keyword; got {key!r}"
            )
        v = val.strip().lower()
        if v in ("true", "1", "yes"):
            write = True
        elif v in ("false", "0", "no"):
            write = False
        else:
            raise ValueError(
                f"zeta_sieve write= must be True/False; got {val!r}"
            )
    return t_start, t_end, write


def _run_zeta_sieve(t_start: float, t_end: float, write: bool) -> list[dict]:
    """Stage 2A-Prime: sign-change sieve via kernel.sieve_zeros.

    write=False is the dry-run path: zeros are printed but no ledger
    line is appended. write=True is the live path: each refined zero
    goes through probe(1, 1, 0.5, t0), which verifies the Genesis seal
    THEN appends one line per zero, per the same contract as
    zeta_burst.
    """
    found = kernel.sieve_zeros(
        float(t_start), float(t_end), write=bool(write)
    )
    mode = "LIVE" if write else "DRY-RUN"
    partial = any(e.get("partial") for e in found)
    print(
        f"ZETA SIEVE {mode}: [{t_start}, {t_end}] → {len(found)} zeros "
        f"({'appended to ledger' if write else 'NOT appended (write=False)'})"
    )
    # Exact spec-mandated summary line. We additionally re-verify the
    # Genesis seal here at the CLI boundary so a write=True run prints
    # "Genesis intact." as a *fresh* verification, not a stale claim.
    seal_ok = True
    if write:
        try:
            kernel._verify_seal()
        except Exception as e:  # noqa: BLE001
            seal_ok = False
            print(f"SIEVE: GENESIS SEAL FAILURE after run: {e}", flush=True)
    suffix = "Genesis intact." if seal_ok else "Genesis BROKEN — investigate."
    if partial:
        suffix = "partial (SIGINT); " + suffix
    print(
        f"SIEVE: {len(found)} zeros in [{t_start}, {t_end}]. {suffix}",
        flush=True,
    )
    return found


def _run_bracket_riemann_zero(n: int, eps: float) -> dict:
    """Gun 1 (proof of work): sweep |ζ| dipping at the n-th zero."""
    out = kernel.bracket_zero(int(n), float(eps))
    print(
        f"BRACKETED n={out['n']} t0={out['t0']} window={out['window']} "
        f"step={out['step']} zeros_found={out['zeros_count']}"
    )
    return out


def _run_dirichlet_probe(
    N: int, re_s: float, im_s: float, char: int = 0
) -> dict:
    """Gun 2: explicit Dirichlet routing. Non-principal char rejected."""
    if int(char) != 0:
        result = {
            "N": int(N),
            "re_s": float(re_s),
            "im_s": float(im_s),
            "char": int(char),
            "tag": "NEEDS_SAGE",
            "reason": "non_principal_dirichlet_requires_sage",
            "backend": "none",
            "ledger_written": False,
        }
        print(
            f"DIRICHLET RADAR REJECT: N={N} char={char} → "
            f"NEEDS_SAGE (no ledger line; only principal chars supported)"
        )
        return result
    out = kernel.probe(1, int(N), float(re_s), float(im_s))
    l_abs = out.get("L_abs") or "NA"
    print(
        f"DIRICHLET RADAR: N={N} s={re_s}+{im_s}i tag={out['tag']} "
        f"|L|={l_abs} sha={_short_sha(out['sha'])}"
    )
    return out


def _run_elliptic_probe(label: str, re_s: float, im_s: float) -> dict:
    """Gun 3: SHA-stamped intent to compute L(E,s). No evaluation."""
    out = kernel.elliptic_stub(str(label), float(re_s), float(im_s))
    print(
        f"ELLIPTIC STUB: {out['label']} s={out['re_s']}+{out['im_s']}i "
        f"tag={out['tag']} reason={out['reason']} sha={_short_sha(out['sha'])}"
    )
    return out


def run_one(expr: str) -> int:
    s = expr.strip()
    # Order matters: longer prefixes first.
    if s.startswith("scan_critical_line"):
        N, im_start, im_end, step = _parse_scan(s)
        hits = kernel.scan_critical_line(N, im_start, im_end, step)
        for h_ in hits:
            l_abs = h_.get("L_abs") or "NA"
            print(f"HIT: t={h_['t']:.6f} |L|={l_abs} sha={_short_sha(h_['sha'])}")
        print(
            f"-- {len(hits)} hit(s) over t ∈ [{im_start}, {im_end}] step={step} "
            f"(N={N}, all probes appended to data/hits.txt)"
        )
        return 0
    if s.startswith("scan_line"):
        N, im_start, im_end, step, h = _parse_args(s, "scan_line", 5)
        zeros = kernel.scan_critical_line(
            int(N), float(im_start), float(im_end), float(step), int(h)
        )
        print(json.dumps({"zeros": zeros, "count": len(zeros)}, indent=2, default=str))
        return 0
    if s.startswith("scan_plane"):
        h, N, re_min, re_max, im_min, im_max, grid = _parse_args(s, "scan_plane", 7)
        summary = kernel.scan_plane(
            int(h),
            int(N),
            float(re_min),
            float(re_max),
            float(im_min),
            float(im_max),
            float(grid),
        )
        print(json.dumps(summary, indent=2))
        return 0
    if s.startswith("bracket_riemann_zero"):
        n, eps = _parse_args(s, "bracket_riemann_zero", 2)
        _run_bracket_riemann_zero(int(n), float(eps))
        return 0
    if s.startswith("zeta_sniper"):
        (n,) = _parse_args(s, "zeta_sniper", 1)
        out = _run_zeta_sniper(int(n))
        print(_format_result(out))
        return 0
    if s.startswith("zeta_sieve"):
        t_start, t_end, write = _parse_zeta_sieve(s)
        hits = _run_zeta_sieve(t_start, t_end, write)
        print(json.dumps({"count": len(hits), "write": write}, indent=2))
        return 0
    if s.startswith("zeta_burst"):
        n_start, n_end = _parse_args(s, "zeta_burst", 2)
        hits = _run_zeta_burst(int(n_start), int(n_end))
        print(json.dumps({"count": len(hits)}, indent=2))
        return 0
    if s.startswith("dirichlet_probe"):
        parts = _parse_args_range(s, "dirichlet_probe", 3, 4)
        N, re_s, im_s = parts[0], parts[1], parts[2]
        char = int(parts[3]) if len(parts) == 4 else 0
        out = _run_dirichlet_probe(int(N), float(re_s), float(im_s), char)
        print(_format_result(out))
        return 0
    if s.startswith("elliptic_probe"):
        label, re_s, im_s = _parse_args(s, "elliptic_probe", 3)
        out = _run_elliptic_probe(label, float(re_s), float(im_s))
        print(_format_result(out))
        return 0
    if s.startswith("hunt_zeros"):
        n_start, n_end = _parse_args(s, "hunt_zeros", 2)
        hits = kernel.hunt_zeros(int(n_start), int(n_end))
        print(json.dumps({"count": len(hits)}, indent=2))
        return 0
    if s.startswith("bracket_zero"):
        n, window = _parse_args(s, "bracket_zero", 2)
        out = kernel.bracket_zero(int(n), float(window))
        print(json.dumps(out, indent=2, default=str))
        return 0
    if s.startswith("zero"):
        n = _parse_zero(s)
        out = kernel.zero(n)
        print(f"zero({n}) → 0.5 + {out['gamma']}i")
        print(_format_result(out))
        return 0
    if s.startswith("probe"):
        h, N, re_s, im_s = _parse_probe(s)
        out = kernel.probe(h, N, re_s, im_s)
        print(_format_result(out))
        return 0
    raise ValueError(f"unknown command: {expr!r}")


def repl() -> int:
    print(BANNER)
    print("type a command or 'quit'")
    while True:
        try:
            line = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if not line:
            continue
        if line in ("quit", "exit"):
            return 0
        try:
            run_one(line)
        except Exception as e:  # noqa: BLE001
            print(f"error: {e}", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(prog="lab.py")
    ap.add_argument(
        "-c",
        "--command",
        help=(
            "one-shot command (zeta_sniper / zeta_burst / zeta_sieve / "
            "bracket_riemann_zero / dirichlet_probe / elliptic_probe / "
            "probe / zero / hunt_zeros / bracket_zero / "
            "scan_critical_line / scan_line / scan_plane)"
        ),
    )
    args = ap.parse_args()
    if args.command:
        return run_one(args.command)
    return repl()


if __name__ == "__main__":
    sys.exit(main())
