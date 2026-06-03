# A Note for Referees

**Project:** Morning Star Project — Theorema Aureum 143, Volume I
**Publisher:** Morning Star Project (independent research)
**License:** All rights reserved (license pending review)
**Status:** Independent field research, seeking institutional sponsorship.

This note is written by the author of the repository for any referee,
mathematician, or institution (in particular the Clay Mathematics
Institute) who has been handed this work. It is short on purpose.

## What this repository is

Three real, defensible deliverables. Each is small, finite, and
checkable from a fresh clone via `docs/REPRODUCE.md`.

1. **The Ledger.** `data/hits.txt` is a 20,964-line append-only log
   of L-function probes with a Genesis-sealed preamble (SHA-256
   `eecbcd9a…875f`). Per-line SHA chain, tamper-evident,
   reproducible. This is publishable computational data; it is not
   a proof of anything.
2. **The Spine.** A Lean 4 deductive chain
   `H1_ArakelovPositivity → H2_WeilTransfer → main_theorem` in
   `lean-proof/`. `#print axioms TheoremaAureum.main_theorem`
   returns `[]`. **Read this carefully:** that statement is a real
   formal theorem *given the Prop-level stubs declared in
   `Certificates.lean`*. It is not a formal proof of the Riemann
   Hypothesis. The author makes no claim that it is.
3. **The Infrastructure.** Append-only ledger discipline, Genesis-
   seal verifier, drift guard, single-source-of-truth banner
   (`scripts/print-direction.sh`), and a CI workflow
   (`lean-proof`) that fails closed if the axiom footprint of
   `main_theorem` ever drifts from `[]`. Real software, with
   reproducibility receipts.

## What this repository is *not*

It is not a claimed proof of any Millennium Prize problem.

The five long-term research targets — RH, Yang-Mills mass gap,
Navier-Stokes global regularity, the 280-curve cohort, and the
Bost-Connes endgame — live in `docs/ROADMAP.md`. They are all
listed there as **`Status: Open`** and they stay that way until a
Lean theorem with that *exact* name closes with axioms = `[]` and
without Prop-level stubs standing in for the hard analysis.

The `Towers/` directory in `lean-proof-towers/` contains "bricks"
that pass an axiom-footprint check restricted to mathlib's
classical trio `{propext, Classical.choice, Quot.sound}`. The
author wishes to be unambiguous about what these bricks are:

- They are **schemas** and **honest stand-ins** for the Clay
  surfaces, not the Clay surfaces themselves.
- The "real" Lean proofs inside the towers are typically
  small-dimensional, zero-norm, or one-point witnesses — degenerate
  cases of the headline statement, proven so the Lean spine has
  something concrete to typecheck against.
- The "conditional" lemmas (named `*_conditional`, `*_promotion`,
  `*_from_*`) take the hard hypothesis as a `Prop` argument and
  hand it back through. They are tripwires, not discharges: when a
  real proof of the antecedent lands, these slots are where it
  plugs in.
- The action stand-ins, gauge fields, and curvature placeholders
  are not the Yang-Mills action, not the Wilson plaquette, not
  `F_μν`, and not the Sobolev `H¹` norm or a Leray-Hopf solution.
  Where such a stand-in is structurally trivial in a way that
  would *silently* discharge a Clay claim, a tripwire is in place
  (see `replit.md` § "Honest-scope guards") that will fail the
  build the moment a real object replaces the placeholder.

The phrase "axiom footprint = `{propext, Classical.choice,
Quot.sound}`" means *exactly* that the Lean kernel certified the
brick using only mathlib's classical trio. It does **not** mean the
brick is a proof of its English-language headline. The author
considers this distinction important and asks referees to hold
the project to it.

## On the prose

The author is an independent field researcher. Some of the English
inside docstrings, commit messages, and changelog notes is
unavoidably informal — the voice of someone working alone, not the
voice of an institutional preprint. This is acknowledged. The
machine-checked content (the ledger SHA chain, the axiom footprint,
the per-brick check in `scripts/check-towers.sh`) does not depend
on the prose, and the prose can be rewritten at any time by a
sponsoring institution without invalidating any of the formal
content.

The author would welcome the Clay Mathematics Institute — or any
institutional author — writing their own version of this work in
their own voice and style. The ledger, the spine, the towers, and
the infrastructure are designed to be lifted, re-narrated, and
re-presented on top of. Permission for that is granted in advance.

## How to verify in five minutes

```bash
bash scripts/print-direction.sh            # who/what/where banner
python3 scripts/check-genesis-seal.py      # ledger preamble SHA
bash scripts/check-lean-proof.sh           # spine axioms = []
bash scripts/check-towers.sh               # towers axiom footprint
```

Anything not produced by one of those four commands is commentary,
including this note.

## Contact

The author works as a field researcher and is actively seeking an
institutional sponsor for whom the formal-verification, ledger,
and infrastructure layers of this repository would be useful. If
that includes you, the codebase, the data, and the Lean source are
yours to read, criticise, and adopt under the terms above.

— Morning Star Project
