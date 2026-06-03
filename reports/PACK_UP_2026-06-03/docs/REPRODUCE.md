# Reproduce MorningStar v1.9 in 3 commands

Goal: a skeptical referee should be able to clone the repo and convince
themselves of the two load-bearing claims in under five minutes:

1. The Lean 4 proof `TheoremaAureum.main_theorem` has axiom debt `[]`.
2. The probe ledger `data/hits.txt` is Genesis-sealed and tamper-evident.

No SageMath required. mpmath, Python 3, and Lean 4 (`leanprover/lean4:v4.12.0`
via `elan`/`lake`) are the only external tools.

---

## Command 1 — Lean axiom-debt check

```bash
STRICT_LEAN_CHECK=1 ./scripts/check-lean-proof.sh
```

What it does: runs `./lean-proof/regenerate.sh`, which does a fresh
`lake build` and then `lake env lean Verify.lean`, and fails closed
unless all three of `main_theorem`, `H2_WeilTransfer`, and
`M9_WeilTransfer_All` report "does not depend on any axioms".

Expected on success: exit 0 and `lean-proof/VERIFY.txt` updated with
lines like

```
'TheoremaAureum.main_theorem' depends on axioms: []
'TheoremaAureum.H2_WeilTransfer' depends on axioms: []
'TheoremaAureum.M9_WeilTransfer_All' depends on axioms: []
```

If `lake` is not on PATH, strict mode exits non-zero (intentional — the
"axiom debt = []" claim is not allowed through unverified in CI).

---

## Command 2 — Genesis-seal + tamper-evidence tests

```bash
python -m pytest tests/test_morningstar.py tests/test_kernel.py -q
```

What it does, in one process:

- `test_morningstar.py` — confirms `scripts/check-genesis-seal.py` exits
  non-zero on byte-flips, line-swaps, and pre-marker insertions in
  `data/hits.txt`; that the unmodified file passes; that
  `lean_bridge._guard` refuses rendered Lean containing `axiom `,
  `sorry`, or `admit `; and that `kernel.probe()` raises before
  appending when the preamble is tampered. A pytest fixture backs up
  and restores `data/hits.txt` so a crash mid-test cannot corrupt the
  live ledger.
- `test_kernel.py` — pins the mpmath L-function backend numerics
  (`MPMATH_ZETA` `|L|<1e-6` at γ₁, `|ζ(2) − π²/6| < 1e-10`,
  `MPMATH_DIRICHLET_TRIVIAL` matches `ζ(0.5)·(1 − 19^{-0.5})`,
  `NEEDS_SAGE` for `h≥2`); the three `elliptic_stub` invariants
  (ELLIPTIC_STUB tag, malformed label rejection, no `L_*` keys ever);
  and the `zeta_sieve` dry-run invariants (25 ≤ zeros found in [0,100] ≤ 35,
  ledger byte-identical before/after).

Expected on success: all tests pass, ledger SHA-256 unchanged.

---

## Command 3 — End-to-end harness (kernel → bridge → Lake)

```bash
bash scripts/validate-morningstar.sh
```

What it does:

1. `python lab.py -c "probe(1,1,0.5,14.134725141734693)"` — one probe
   at the first nontrivial ζ zero. Seal-verifies before appending.
2. `python lean_bridge.py` — reads the five Genesis lines, emits
   `lean-proof/TheoremaAureum/AutoLemmas.lean` with `theorem hit_<n> :
   True := trivial` for each, refuses to write `sorry`/`axiom`/`admit`.
3. `lake build` inside `lean-proof/`.
4. `lake env lean Verify.lean` + an axiom check on `hit_437` and `hit_1094`.

Expected last line on success:

```
MorningStar-Lab v1.0 online. 4D stable. W=h Z=N X=Re Y=Im.
CERTIFICATE at /data/M13_CERT.txt
```

---

## What the ledger actually says (snapshot)

`data/hits.txt` at the time of the v1.9 master manifesto:

- 20,962 lines total (9-line sealed preamble + 20,953 probes).
- 20,934 lines tagged `MPMATH_ZETA`, 8 `MPMATH_DIRICHLET_TRIVIAL`,
  9 `NEEDS_SAGE`, 1 `ELLIPTIC_STUB`.
- Among `MPMATH_ZETA` lines: 11,410 unique `im(t)` values, 8,223 of
  them appearing more than once (re-probes are recorded honestly,
  not deduped).
- 11,735 lines with `RH_ok=True`, 9,216 with `RH_ok=False`. Both are
  appended — `RH_ok=False` is not a failure, it's a recorded miss
  outside the `|L| < 10⁻¹⁰` threshold.

The Genesis seal protects the *preamble* (the contract). The
per-line SHAs make the *probes* a hash chain. Neither one is a truth
oracle for RH.

---

## Recovering `data/hits.txt` from a tamper or accidental truncation

The Genesis seal protects the 9-line preamble. The at-rest integrity
guard (`scripts/check-ledger-integrity.py`, task #53) protects the
**body**: it compares the live ledger against the
`data/hits.txt.checkpoint` sidecar (`<size> <sha256>` of the last
known-good state, updated atomically by `kernel._append_line` and
`scripts/seal-birth.py` after every legitimate append). If the live
file shrinks below the checkpoint or the recorded prefix SHA stops
matching, the guard exits non-zero with `SHRUNK` or `rewritten in
place`. It runs in `scripts/post-merge.sh` and is exercised by
`tests/test_morningstar.py::test_truncated_hits_fails_integrity_check`
and `test_in_place_rewrite_fails_integrity_check`.

If the guard ever fires (or you find `hits.txt` mysteriously short),
**do not run a probe yet** — `kernel.probe` appends, and appending to
a truncated file would lose the previous lines permanently.

Recovery, in order of safety:

1. **Git working tree** — `git status data/hits.txt`. If it shows as
   modified/deleted, `git restore data/hits.txt data/hits.txt.checkpoint`
   brings both files back to the last committed snapshot. Re-run
   `python scripts/check-ledger-integrity.py` to confirm.

2. **Local reflog / stash** — if the working tree is clean but the
   ledger is wrong, you probably checkpointed earlier. Try
   `git log -- data/hits.txt` to find the most recent good commit
   and `git checkout <sha> -- data/hits.txt data/hits.txt.checkpoint`.

3. **Refusal to silently rebuild** — there is no "rebuild from
   scratch" path. The ledger is an append-only DAG with a Genesis
   seal whose SHA (`eecbcd9a…875f`) is hardcoded; you cannot
   regenerate it without re-running the seal-birth ritual, which
   would invalidate every referenced `hit_<n>` lemma in
   `lean-proof/`. If git can't bring it back, recover from a clone
   of the published repository (the file is checked in).

After recovery, before any new append, run:

```bash
python scripts/check-genesis-seal.py
python scripts/check-ledger-integrity.py
```

Both must exit 0 before `python lab.py -c "probe(...)"` is safe to
run again.

The lint rule
`tests/test_morningstar.py::test_no_non_append_writes_to_hits_txt`
prevents *new* call sites from opening `data/hits.txt` in a
truncating mode (`open('w'/'wb')`, `Path.write_text/bytes`, shell
`> data/hits.txt`) outside the small allowlist (`kernel.py`,
`scripts/seal-birth.py`, `scripts/check-ledger-integrity.py`, and
this test file). If you genuinely need a new maintenance script,
route appends through `kernel._append_line` and add the file path
to `_LEDGER_WRITE_ALLOWLIST`.

---

## Honest-scope reminders

- `hit_437` / `hit_1094` are `True := trivial`. Their names point to
  the OpenCV cube counts in README Appendix A; their statements
  claim nothing about number theory.
- `elliptic_stub` writes intent, not value. The returned dict has
  no `L_real`/`L_imag`/`L_abs` keys; `test_kernel.py` pins this so
  a future refactor cannot silently start lying.
- `zeta_sieve` is a parallelised sign-change sieve plus Brent
  refinement, **not** the Odlyzko-Schönhage 1991 FFT trick.
- Nothing here is a proof of the Riemann Hypothesis. The
  load-bearing claim is the much narrower "the Lean spine is
  axiom-free and the ledger is sealed".
