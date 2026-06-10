/-
TheoremaAureum.Towers.YM.WeylDim
================================
Batch 156.2 / Task #156 file 2 of 6 (Varadhan integrated-tail scaffolding).

ARITHMETIC INPUT ONLY. No heat kernel. No K(t). No off-diagonal kernel.
No Varadhan asymptotic. This file is a single ℕ-polynomial inequality.

Brick.
  `dim_cubic_bound (m n : ℕ) :
       dim_SU3 m n ≤ 8 · (m + n + 1) ^ 3`
  with the standard SU(3) Weyl-dim formula
  `dim_SU3 m n := (m + 1) · (n + 1) · (m + n + 2) / 2`
  on the (m, n) highest-weight lattice (floor division in ℕ — the
  numerator is always even, but we never need that fact here).

Why this lives separately from `Towers/YM/PeterWeyl.lean`.
  PeterWeyl already ships `Weyl_dim_SU3_explicit_real_le_poly`,
  the **degree-4** real-valued upper bound
  `(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m:ℝ)+1)² · ((n:ℝ)+1)²`
  needed by the Peter–Weyl summability envelope (paired with the
  geometric `exp(-βm) · exp(-βn)` factor). The future file-3
  `HeatTraceBound` needs a different shape — a **cubic** bound in
  `m + n` (not `m` and `n` separately) — because the Weyl-law
  `t^{-d/2}` heat-trace estimate sums on the `m + n = k` antidiagonal
  and asks for `# antidiagonal · dim² · exp(-t·C₂) ≲ poly(k) · exp(-t·k²)`.
  Both bounds are real; they coexist (this strengthens neither).

  `dim_SU3` is the integer-valued formula on (m, n); `Weyl_dim_SU3_explicit`
  in PeterWeyl is the same combinatorial object but lifted through a
  different ℕ → ℝ cast pattern. Bridging the two (so the future
  file-3 can cite *one* dim bound) is a separate housekeeping task,
  not part of Batch 156.2.

Honest scope (locked, unchanged from Batch 20.2a).
  - mathlib v4.12.0 only. No other deps.
  - Axiom footprint: {propext, Classical.choice, Quot.sound} (mathlib's
    classical trio; no research-grade axioms).
  - No `sorry`, no `admit`, no `axiom`, no `unsafe`, no `implemented_by`.
  - YM tower stays Status: Open (docs/ROADMAP.md § 2).
  - Surface #2 stays OPEN (4 open-gap blocks in
    docs/Surface2_ResearchProgram.tex; `kotecky_preiss_criterion`
    remains a `sorry` in `Towers/Attempts/ClusterExpansion.lean`).
  - Landing this brick does NOT discharge Varadhan, the per-plaquette
    activity bound, KP, cluster expansion, area law, or any mass-gap
    statement. It is **one ℕ-polynomial inequality**.

Algebra.
  Set s := m + n. The strict polynomial bound is
    (m + 1) · (n + 1) · (s + 2) ≤ 16 · (s + 1) ^ 3.
  Slack here is ≫ 8×, way more than tight; we don't need tightness
  because the future file-3 swallows the constant `8` into `C` anyway.
  Proof closed by `zify; nlinarith [sq_nonneg ((m:ℤ) − n), …]`.
  Then a / 2 ≤ 8 · R follows from a ≤ 16 · R = 2 · (8 · R) via
  `Nat.div_le_div_right` (handled by `omega` with `R` generalised).
-/

import Mathlib.Tactic
import Mathlib.Data.Nat.Defs

namespace TheoremaAureum.Towers.YM.WeylDim

/-- SU(3) Weyl-dim formula on the (m, n) highest-weight lattice:
    `dim π_(m,n) = (m+1)(n+1)(m+n+2) / 2`.

    The numerator `(m+1)(n+1)(m+n+2)` is always even (one of the three
    consecutive-ish factors is even), so the ℕ floor division is exact;
    but `dim_cubic_bound` below does not depend on that fact. -/
def dim_SU3 (m n : ℕ) : ℕ := (m + 1) * (n + 1) * (m + n + 2) / 2

/-- Cubic upper bound on the SU(3) Weyl dimension:
    `dim_SU3 m n ≤ 8 · (m + n + 1) ^ 3` for **every** `(m, n) : ℕ × ℕ`
    (explicit threshold `k₀ = 0`, no "for sufficiently large m + n" caveat).

    Proof. The polynomial inequality
      `(m + 1) · (n + 1) · (m + n + 2) ≤ 16 · (m + n + 1) ^ 3`
    is closed by `zify; nlinarith [sq_nonneg ((m:ℤ) − n), …]` (AM-GM
    on `(m+1)+(n+1) = m+n+2` plus the trivial `m + n + 2 ≤ 2·(m + n + 1)`).
    Dividing both sides by 2 and using `Nat.div_le_div_right` plus
    `omega` (with `(m + n + 1) ^ 3` generalised so omega treats the
    cubic term as an opaque ℕ) lands the headline. -/
theorem dim_cubic_bound (m n : ℕ) :
    dim_SU3 m n ≤ 8 * (m + n + 1) ^ 3 := by
  unfold dim_SU3
  have key : (m + 1) * (n + 1) * (m + n + 2) ≤ 16 * (m + n + 1) ^ 3 := by
    zify
    nlinarith [sq_nonneg ((m : ℤ) - n), sq_nonneg ((m : ℤ) + n + 1),
               sq_nonneg ((m : ℤ) + n), Int.natCast_nonneg m,
               Int.natCast_nonneg n]
  -- `A / 2 ≤ 8 · R` from `A ≤ 16 · R = 2 · (8 · R)`, with `R` opaque.
  set R := (m + n + 1) ^ 3 with hR
  set A := (m + 1) * (n + 1) * (m + n + 2) with hA
  omega

end TheoremaAureum.Towers.YM.WeylDim
