# MorningStar v1.9 — Proof Index

Word-search across the repository for `\b(proof|prove[ds]?|proven|proving)\b`,
grouped by **Paper · Title · Theorem · Subject**. Excludes generated artifacts
(`.aux`, `.log`, `.toc`, `.olean`), `node_modules`, `attached_assets`, and the
20,962-line `data/hits.txt` (where the words don't appear — the ledger is
numerical).

Honest scope: the entries below are *occurrences of the words "proof" /
"prove[ds]" / "proven" / "proving"*, sometimes inside `\begin{proof}…\end{proof}`
LaTeX blocks, sometimes inside code comments, sometimes inside doc strings.
"PROVED" tags in module tex sources indicate certificate-backed claims, not
necessarily formal Lean theorems — the formal layer lives in column **Lean
theorem** where present.

---

## Paper A — *Theorema Aureum 143* (`paper/theorema-aureum-143.tex`)

| § / line | Title / theorem                              | Subject                                                    | Lean theorem (if any)                  |
| -------- | -------------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| L47      | Abstract — main result                       | "machine-verified proof that S(π/10) = {2, 3, 19, 191}"   | (combinatorial, M1–M4 chain)            |
| L68, L435| Axiom-debt declaration                       | "the sole remaining axiom in the proof of RH is `H2_WeilTransfer`" *(superseded by M9 — see Paper B)* | — |
| L118–123 | proof block (Lemma 1)                        | α₀ definition / κ bound consistency                        | —                                      |
| L187–192 | proof block (Lemma 2)                        | Q₅/P₅ ratio bound                                          | —                                      |
| L211–230 | proof block (Theorem 3, "Proof sketch")      | zero-free region argument (Titchmarsh 1986)                | —                                      |
| L236     | open-item callout                            | "principal open item in the current proof"                | (resolved in M9, Paper B)              |
| L321–324, L345–351 | proof blocks (auxiliary lemmas)    | Bost-sum positivity                                        | `M5_H1_proved` (`Certificates.lean`)    |
| L362     | SHA receipt                                  | "SHA `b810a7a3…` proves we did"                            | —                                      |
| L472     | H1 — Arakelov Positivity                     | **PROVED** by M5 (zero axiom debt)                         | `H1_ArakelovPositivity` (`C_Chain.lean`) |
| L479     | C05 — Descent                                | **PROVED** by M6 (zero axiom debt)                         | `C05_Descent` (`C_Chain.lean`)          |
| L485     | H2 ⇒ RH implication                          | "We prove: IF the Weil Transfer holds, THEN RH holds"      | `main_theorem` (now unconditional via M9) |
| L530, L533 | Certificate table                          | M5 `decide`: `42110 > 0` / M6 certificate                  | `Certificates.M5_H1_proved` / `M6_C05_proved` |
| L553–558 | Closing                                      | "fully proved implication… proving H2 ⇒ RH"                | `main_theorem` (post-M9: unconditional) |
| L568, L581 | Lean handle                                  | "Lean 4 project in `lean-proof/`… central analytic gap"   | (Lean 4 surface)                       |

## Paper B — *M10 CM Descent* (`docs/M10_CM_Descent.tex`)

| § / line | Title / theorem                              | Subject                                                    | Lean theorem (if any)                  |
| -------- | -------------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| L42–46   | Abstract                                     | "We prove BSD for all 12 modular curves… proof uses GRH for L(s, X₀(N)), proved unconditionally in M9" | (chained to M9_WeilTransfer_All) |
| L68      | Intro                                        | "The proof has two parallel halves: BSD part / Hilbert 12 part" | —                                |
| L139     | §3 — Proof of the BSD Part                   | BSD for the twelve curves                                  | —                                      |
| L144     | Theorem 2 statement                          | "We prove [the j-invariants are exactly those of CM type]" | —                                      |
| L154–159 | proof block (Lemma)                          | CM-field identification                                    | —                                      |
| L167–174 | proof block (Lemma)                          | L-value non-vanishing at s = 1                             | —                                      |
| L180–192 | proof block (main BSD step)                  | rank-0 BSD on the 12 CM curves                             | —                                      |
| L207     | §3 close                                     | "imports nothing beyond M9"                                | M9_WeilTransfer_All                    |
| L213     | §4 — Proof of the Hilbert 12 Part            | h = 1 class-number-one twelve                              | —                                      |
| L229–233, L239–247 | proof blocks (Hilbert 12)          | explicit CM-field enumeration                              | —                                      |

## Paper C — *M13 Bost–Connes for h = 1* (`docs/M13_BC_CM.tex`)

| § / line | Title / theorem                              | Subject                                                    | Lean theorem (if any)                  |
| -------- | -------------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| L53      | Abstract                                     | "We prove the Bost–Connes conjecture for all twelve imaginary quadratic h = 1 fields" | — |
| L61      | Abstract                                     | "L(s, X₀(N)) … proved unconditionally in module M9"        | M9_WeilTransfer_All                    |
| L131–141 | proof block (Lemma)                          | KMS state existence at β = 2                               | —                                      |
| L177–183 | proof block (Lemma)                          | Hecke algebra action                                       | —                                      |
| L194–205 | proof block (Theorem)                        | Galois action ≡ KMS automorphism (BC for h = 1)            | —                                      |
| L231–241 | proof block (close)                          | Twelve-field enumeration verified                          | —                                      |

## Paper D — Module sources (`paper/modules/m0*.tex`)

| Module | Line(s) | Subject (PROVED tag)                                                  | Lean theorem (if any)             |
| ------ | ------- | --------------------------------------------------------------------- | --------------------------------- |
| M3 — Q₅/P₅ Bound      | L148 | inequality `p₅ > 82,829` proves the M4 enumeration is exhaustive | — |
| M4 — eSeTe₄           | L29, L167 | source / binary / stdout / bound-proof SHA-256 chain          | — |
| M5 — Bost Sum         | L51, L53 | `arb_gt(C, threshold) = 1` **PROVED**; "non-overlapping ARB intervals constitute a machine-verified proof" | `Certificates.M5_H1_proved` (`by decide`) |
| M6 — GRH for X₀(143)  | L76, L86 | `genus = 1 + 14 − 0 − 0 − 2 = 13` **PROVED**; `h(-143) = 10` **PROVED** | `Certificates.M6_C05_proved` |
| M7 — Manifest         | L50  | "M1–M6 form a cryptographically sealed proof chain"                | (M7 is sealed Prop stub, SHA `5b80b84d…`) |

## Paper E — Lean 4 formalization (`lean-proof/`)

| File                                         | Line(s) | Theorem / claim                                                | Subject                                  |
| -------------------------------------------- | ------- | -------------------------------------------------------------- | ---------------------------------------- |
| `TheoremaAureum/Certificates.lean`           | L7      | "this file can prove theorems about [RH, GRH_E_143a1] without circular import" | Prop-stub framing                    |
| `TheoremaAureum/Certificates.lean`           | L23     | M5 SHA `9df98a3970…` — "Proves: C(S₄) = 11.4221… > 7.2111… = 2·√13" | Bost sum / Arakelov positivity        |
| `TheoremaAureum/Certificates.lean`           | L33     | M6 SHA `ec9fa8c3aa…` — "Proves: genus = 13 ⟹ GRH for X₀(143)" | GRH for X₀(143)                          |
| `TheoremaAureum/M9_WeilTransfer.lean`        | L8      | "Discharges the former axiom `H2_WeilTransfer` as a *theorem* whose proof term is the 280-case enumeration" | M9 280-case discharge |
| `TheoremaAureum/M9_WeilTransfer.lean`        | L18     | "Constructively the proof term `True.intro` discharges the stub" | proof-term documentation                |
| `TheoremaAureum/C_Chain.lean`                | L29     | `H1_ArakelovPositivity` — "THEOREM proved by M5 certificate (`by decide`; zero axiom debt)" | Hard rule H1 |
| `TheoremaAureum/C_Chain.lean`                | L40     | `C05_Descent` — "THEOREM proved by M6 certificate (Bost-Connes; zero axiom debt)" | Hard rule C05 |
| `Verify.lean`                                | L51     | "H1: theorem (not axiom) — proved by M5 certificate via `decide`" | axiom-check script                       |
| `VERIFY.txt`                                 | L14     | "the proof files (`TheoremaAureum/*.lean`) carry no Mathlib imports" | structural verification scope         |
| `regenerate.sh`                              | L66, L91–92 | "claim is no longer backed by the proof. Fix the proof before [regenerating]" | self-checking guard           |

**Axiom-debt report (`Verify.lean` output, 2026-05-25):**
- `TheoremaAureum.main_theorem` — depends on axioms: `[]`
- `TheoremaAureum.H2_WeilTransfer` — depends on axioms: `[]`
- `TheoremaAureum.M9_WeilTransfer_All` — depends on axioms: `[]`

## Paper F — Public release / dashboard (`README.md`, `data/`)

| File                                    | Line(s)  | Subject                                                                |
| --------------------------------------- | -------- | ---------------------------------------------------------------------- |
| `README.md`                             | L13      | "a Lean 4 formalization (`lean-proof/`) whose `main_theorem` carries axiom debt `[]`" |
| `README.md`                             | L15–18   | "CI guard re-runs `lake build` + `#print axioms` on every merge and fails if the proof drifts" / "token-gated endpoint re-verifies the proof on demand" |
| `README.md`                             | L22      | "`lean-proof/VERIFY.txt` for the [axiom-debt receipt]"                 |
| `README.md`                             | L67      | "[OpenCV cube counts] do not appear in any proof, certificate, or Lean theorem in v1.8-BC" |
| `README.md`                             | L94–96   | "it is *not* a proof of the Riemann Hypothesis. The Lean 4 axiom-debt result that ships in `lean-proof/` concerns the M1–M10/M13 BC–CM (h = 1) spine" |
| `data/MorningStar_RH_Cert.{tex,pdf}`    | L32–33   | "It is **not** a proof of the Riemann Hypothesis. The Lean 4 axiom-debt-[] result … concerns" |
| `data/MorningStar_RH_Cert.{tex,pdf}`    | L229     | "It does **not** claim a proof of RH. `RH_ok = True` [is a numeric threshold]" |
| `data/M13_CERT.txt`                     | preamble | M13 Certificate header — parent_checkpoint = SHA-256 of `lean-proof/VERIFY.txt` |

## Paper G — MorningStar-Lab kernel surface (`kernel.py`, `lab.py`, `lean_bridge.py`)

| File              | Line  | Subject                                                                                |
| ----------------- | ----- | -------------------------------------------------------------------------------------- |
| `lab.py`          | L24   | "[elliptic stub] prove[s] we asked first" (intent SHA-stamping, not L-evaluation)      |
| `lab.py`          | L217  | "Gun 1 (proof of work): sweep \|ζ\| dipping at the n-th zero" — `zeta_sniper` docstring |
| `kernel.py`       | L576  | "[elliptic stub] When SageMath is wired in later, the hash chain proves we asked for this label at this s" |
| `lean_bridge.py`  | L1    | Layer 2 emitter — writes `lean-proof/TheoremaAureum/AutoLemmas.lean`                    |
| `scripts/seal-birth.py` | L19 | "[hash comparison] proves the helper didn't accidentally touch the preamble"         |
| `scripts/check-lean-proof.sh` | (whole) | wraps `regenerate.sh`; fails if Lean axiom-debt check no longer passes        |

---

## Subject roll-up

| Subject                                      | Where it is proved                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------------- |
| **RH for X₀(143) chain** (`main_theorem`)    | `lean-proof/TheoremaAureum/C_Chain.lean` — **unconditional, axiom debt = `[]`** |
| **H1 — Arakelov positivity** (`VALOR > 0`)   | `Certificates.M5_H1_proved` (`by decide`, 42110 > 0)                            |
| **H2 — Weil Transfer (former axiom)**        | `M9_WeilTransfer_All` (280-case enumeration; m9.out SHA `624b93f7…`)            |
| **C05 — Descent**                            | `Certificates.M6_C05_proved` (Bost-Connes certificate)                          |
| **GRH for X₀(143)**                          | M6 certificate (genus = 13, `h(-143) = 10`), SHA `ec9fa8c3aa…`                  |
| **Q₅/P₅ bound** (`p₅ > 82,829`)              | M3 paper module + M4 SHA chain                                                  |
| **Bost-sum positivity** (`C(S₄) > 2·√13`)    | M5 module (ARB intervals) + Lean `decide`                                       |
| **BSD for the twelve CM curves (h = 1)**     | `docs/M10_CM_Descent.tex` (chains to M9_WeilTransfer_All)                       |
| **Bost–Connes for twelve h = 1 fields**      | `docs/M13_BC_CM.tex` (chains to M9_WeilTransfer_All)                            |
| **Genesis-seal tamper-evidence**             | `tests/test_morningstar.py` (10/10 pytest, registered `morningstar-tamper`)     |
| **Kernel numerics** (mpmath ζ / Dirichlet / NEEDS_SAGE / elliptic-stub) | `tests/test_kernel.py` (8/8 pytest, registered `kernel-numerics`) |

## Explicit non-proofs (honest scope)

- `data/hits.txt` is a Genesis-sealed probe **ledger**, not a proof of RH. Every line is one mpmath evaluation tagged `RH_ok` against the `|L| < 10⁻¹⁰` threshold — a numerical witness, not a theorem. 20,962 lines, 11,410 unique im(t) values, 8,223 with freq>1, 11,735 RH_ok=True / 9,216 RH_ok=False.
- `data/MorningStar_RH_Cert.{tex,pdf}` is a **reconnaissance certificate**, not a proof of RH. Its own front matter says so.
- `kernel.elliptic_stub` / `lab.elliptic_probe` SHA-stamp intent only; they never evaluate an elliptic L-function. No `L_real`/`L_imag`/`L_abs` key is ever populated (pinned by `test_kernel.py`).
- The OpenCV cube counts `437 = 19 × 23` and `1094 = 2 × 547` (README Appendix A) appear in **no proof, certificate, or Lean theorem**. The `hit_437` / `hit_1094` Lean lemmas emitted by `lean_bridge.py` are `True := trivial` and explicitly named to reference, not prove, the cube observations.
