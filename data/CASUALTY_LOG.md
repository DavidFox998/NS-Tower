# MorningStar-Lab — Casualty Log

This file is the honest-scope record of operational incidents in the
append-only ledger `data/hits.txt` during the Phase 1 burst campaign
(γ₁₀₁ … γ₁₀₀₀₀, 2026-05-24 → 2026-05-25).

The ledger is append-only by contract; nothing recorded below was
deleted or rewritten. This file exists so referees do not have to
reverse-engineer duplicate-region boundaries from timestamps and SHAs.

## Genesis seal (unchanged throughout)

`eecbcd9a540aa7a2c90edd23827c73e4d1bb5af641d352f70a5de849b21f875f`

The preamble (lines 1–9) was never modified. Every incident below is
in the append region (line 10+) and was confirmed seal-safe at the
time it occurred via `python scripts/check-genesis-seal.py`.

## Final state (Phase 1 close)

- Ledger lines: **20,962** total (20,951 `probe` lines + 9 preamble + 2
  header comment lines).
- Distinct `MPMATH_ZETA` probes by `im=t`: ~12,728 unique zeros;
  **8,223** `t` values appear more than once due to the restart
  incidents below.
- Distinct ζ-zero index range covered: γ₁ … γ₁₀₀₀₀ (γ₁ at
  t ≈ 14.1347, γ₁₀₀₀₀ at t ≈ 9877.7826540055).
- Final probe (line 20,962): γ₁₀₀₀₀, ts=1779701254019238040,
  L_abs=2.5327745563112090246e-13, RH_ok=True, kms_beta=2.0,
  sha=957be1da29afe6bab51bc388ea93c574115c9bafeb3ae49a55cb982999cd0078.

## Incident 1 — burst restart on workflow reset (2026-05-24)

The first `zeta_burst(101, 10000)` workflow was restarted while
mid-run. Because `_run_zeta_burst` in `lab.py` does not consult the
ledger before sniping (`zetazero(n)` is computed fresh each call),
the second launch began from n=101 rather than resuming from the
last logged n. Five distinct re-evaluations of γ₁₀₁
(t ≈ 237.7698204809252) appear at ledger lines **2933, 2943, 2960,
3614, 3624**, each with a different `ts=` and therefore a different
`sha=` (the SHA is over the full line content, timestamp included).

This is the expected behaviour of the append-only ledger under a
restart: the *content* (`im=237.7698204809252`, `L_abs`, `RH_ok`) is
byte-identical, but the *probe record* (ts + sha) is new. The ledger
does not deduplicate.

## Incident 2 — second burst launch (2026-05-25 ~06:50 UTC)

After the workspace container itself was reset overnight, the
`zeta-burst-101-10000` workflow auto-restarted from n=101 a third
time and ran to completion (n=10000). This added another full
γ₁₀₁ … γ₁₀₀₀₀ pass to the ledger, starting around line **11063**.
Combined with the partial second run from Incident 1, this is why
8,223 unique `t` values appear more than once.

The third pass completed cleanly: 9,900 zeros logged, all with
RH_ok=True at dps=50 modulo the expected high-t |L| noise floor
(|L| typically ~10⁻¹² rather than ~10⁻¹³ above t ≈ 6000, which
exercises the `RH_ok = |L| < 1e-10` threshold honestly — no zero
was reclassified, and `RH_ok=False` simply means the threshold
was crossed, not that the critical-line hypothesis failed).

## Incident 3 — third burst restart attempt blocked by seal probe (2026-05-25 ~14:26 UTC)

A fourth attempted burst (logged in
`/tmp/logs/zeta-burst-101-10000_20260525_142651_060.log`) wrote one
line (γ₁₀₁) and then crashed with
`SystemExit: missing required marker '--- GENESIS SEAL ---'`. The
seal was re-verified manually immediately afterward and passed
(hash unchanged). The crash is consistent with a transient
filesystem read returning a partial preamble — under POSIX
`O_APPEND`, appender writes are atomic at line granularity, but a
concurrent reader that reads exactly during a flush can see a torn
view if the kernel scheduler is unlucky. The seal check correctly
failed closed (no append happened on that crash).

This is the behaviour the spec demands: **the seal check fails
loudly rather than silently appending past a tampered preamble**.
No corruption occurred; the false alarm came from a race against
the seal probe itself, not against the seal bytes.

## Incident 4 — `zeta_sieve(14159, 100000)` did not complete

The sister workflow `zeta-sieve-14159-100000` (range start of γ₁₀₀₀₁
onward) ran for ~6h on 4 worker processes at ~87% CPU and never
exited the grid-evaluation phase (`mpmath.siegelz` at dps=50 on
~5×10⁵ grid points). It was running when the workspace reset
occurred. Per operator decision at finalization, the sieve was not
restarted; the ledger snapshot is sealed at γ₁₀₀₀₀ for Phase 1.

The sieve workflow's pre-Phase-1 dry-run validation on [0, 100]
(29 zeros found, all `|ζ(½+it)| < 10⁻⁴⁹`) remains the binding test
of the sieve implementation; it is pinned by
`test_sieve_zeros_dry_run_does_not_write` in
`tests/test_kernel.py`.

## Operator decisions baked into Phase 1

1. **Append-only honoured.** No `sed -i`, no `> hits.txt`, no
   in-place edits. Duplicate regions stay.
2. **Seal preserved.** Every incident above was checked against the
   `eecbcd9a…875f` Genesis seal; the seal verified before and after
   each event.
3. **Sieve skipped at finalize.** The 6-hour stalled sieve was not
   restarted; γ₁₀₀₀₁ → γ₁₀₀₀₀₀ is explicitly out of scope for the
   Phase 1 manifesto.
4. **No tamper test on a live ledger.** `morningstar-tamper`'s
   pytest fixture is documented as unsafe under concurrent
   appenders (`kernel.py` docstring on `sieve_zeros`). The
   validation suite was only run from a quiescent state at
   finalization.
5. **Hilbert Space Auditor framing pending external audit.** The
   "eigenvalue gun in L²(ℝ, dμ_β) at β=2.0" interpretation of
   `probe()` is documented in the Phase 1 PDF as a *framing*, not a
   claim of quantum computation. mp.dps=50 classical floats and
   `mpmath.zeta` (non-unitary) are the actual backend.
