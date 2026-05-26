#!/usr/bin/env python3
"""Print the most recent ledger-integrity alerts from the on-disk ring
buffer (`data/ledger-alerts.jsonl`) for operators who are SSH'd into a
degraded server and don't want to boot the React dashboard.

Task #93. Reads `kernel.read_recent_alerts()` and renders one line per
entry, newest first, with timestamp, workflow, failure_mode, and the
per-transport delivery status.

Exit code is always 0 when the log is missing or empty: this is an
informational surface, not a correctness gate.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import kernel  # noqa: E402


def _fmt_transport(name: str, info: object) -> str:
    if not isinstance(info, dict):
        return f"{name}=?"
    status = info.get("status", "?")
    if status == "failed":
        err = info.get("error", "")
        if err:
            return f"{name}=failed({err})"
        return f"{name}=failed"
    return f"{name}={status}"


def _fmt_entry(entry: dict) -> str:
    ts = entry.get("timestamp", "?")
    workflow = entry.get("workflow", "?")
    failure_mode = entry.get("failure_mode", "?")
    delivery = entry.get("delivery") or {}
    transports = " ".join(
        _fmt_transport(name, delivery.get(name))
        for name in ("webhook", "email")
    )
    return f"{ts}  {workflow}  {failure_mode}  [{transports}]"


def main(argv: "list[str] | None" = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Show the most recent ledger-integrity alerts and their "
            "per-transport delivery status."
        )
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="How many of the newest entries to show (default: 10).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a JSON array instead of a human-readable table.",
    )
    args = parser.parse_args(argv)

    limit = max(0, args.limit)
    entries = kernel.read_recent_alerts(limit=limit) if limit > 0 else []

    if args.json:
        json.dump(entries, sys.stdout, indent=2, sort_keys=True, default=str)
        sys.stdout.write("\n")
        return 0

    if not entries:
        print(
            f"No alerts recorded (log: {kernel.ALERTS_LOG}).",
            file=sys.stderr,
        )
        return 0

    print(f"# {len(entries)} most-recent alert(s) from {kernel.ALERTS_LOG}")
    print("# timestamp                         workflow  failure_mode  [transports]")
    for entry in entries:
        print(_fmt_entry(entry))
    return 0


if __name__ == "__main__":
    sys.exit(main())
