/-!
# Brydges-Federbush D1-D3: KP Summability from Scratch

Three sorry-free, axiom-free lemmas that together give Kirkwood-Pirogov summability
in the strong-coupling SU(3) lattice gauge cluster expansion:

* **D1 (`peierls_branching_bound`)** — Abstract Peierls entropy bound by induction.
  Any counting function `N` with `N 0 ≤ 1` and branching recurrence
  `N (n+1) ≤ 7 * N n` satisfies `N n ≤ 7^n`. This is the abstract form of the
  lattice-plaquette entropy bound for Z^4: each plaquette of a polymer of size n+1
  was reached from a plaquette of size n by at most one step in 2*4 - 1 = 7
  non-backtracking directions. The recurrence hypothesis encapsulates the Peierls
  "subtract the parent" argument without requiring the full lattice formalism.

* **D2 (`geometric_activity_bound`)** — For `0 < w1 < 1/7`, the geometric polymer
  activity `a n := w1^n` satisfies `Wall256Note.TruncatedActivityBound a`, i.e.,
  there exists a rate `I > log 7` such that `a n ≤ exp(-I)^n` for all n.
  Witness: `I := -log w1`. The bound reduces to equality by `exp(log w1) = w1`.

* **D3 (`kp_summable`)** — From D1 + D2 + the already-proved in-tower lemma
  `Wall256Note.kp_summable_of_truncatedActivity` (Wall256_Note.lean:25), the
  entropy-weighted polymer series `∑_n N n * w1^n` is summable.

### What this does NOT claim

* NO mass gap. NO spectral gap. NO Clay result. NO Surface #1 discharge.
* `w1` is abstract; it is NOT connected to the SU(3) Haar integral here.
* The branching recurrence for N is a HYPOTHESIS (the abstract Peierls bound);
  no lattice-animal formalism is built.

### Axiom footprint

Classical trio `{propext, Classical.choice, Quot.sound}` only.
No `sorry`. No `axiom`. Verified by structure: every step is a standard Mathlib lemma.
-/
import Towers.YM.Wall256_Note

namespace TheoremaAureum.Towers.YM.BrydgesFederbush

open Real
open TheoremaAureum.Towers.YM.Wall256Note

/-! ### D1 — Peierls branching bound -/

/-- **D1 (polymer_counting) — Peierls branching bound**, proved by induction on n.

    For any polymer counting function `N : ℕ → ℝ` satisfying:
    * `N 0 ≤ 1`                  (at most one root polymer per site),
    * `∀ n, N (n+1) ≤ 7 * N n`  (Peierls step: each polymer of size n+1 is
                                   built by adding one plaquette to a polymer
                                   of size n with at most 7 = 2·4-1 choices),

    the entropy bound `N n ≤ 7^n` holds for all `n : ℕ`.

    Mathematical content: this is the Peierls / Klarner-cell spanning-tree bound.
    In Z^4 with 2·d = 8 neighbors per plaquette, the spanning-tree construction
    gives a polymer count satisfying N(n+1) ≤ (2d-1)·N(n) = 7·N(n). The
    induction base N(0) ≤ 1 normalizes by the root plaquette.

    Axiom footprint: {propext, Classical.choice, Quot.sound}. No sorry. -/
lemma peierls_branching_bound (N : ℕ → ℝ)
    (h0    : N 0 ≤ 1)
    (hstep : ∀ n, N (n + 1) ≤ 7 * N n) :
    ∀ n, N n ≤ (7 : ℝ) ^ n := by
  intro n
  induction n with
  | zero =>
    simpa using h0
  | succ n ih =>
    calc N (n + 1)
        ≤ 7 * N n          := hstep n
      _ ≤ 7 * (7 : ℝ) ^ n  := mul_le_mul_of_nonneg_left ih (by norm_num)
      _ = (7 : ℝ) ^ (n + 1) := by ring

/-! ### D2 — Geometric activity bound -/

/-- **D2 (activity_bound) — Geometric activity bound**, proved from log monotonicity.

    For `0 < w1 < 1/7`, the geometric polymer activity `a n := w1^n` satisfies
    `Wall256Note.TruncatedActivityBound a`:

    (i) Non-negativity: `w1^n ≥ 0` from `w1 > 0`.
    (ii) Rate: the witness `I := -log w1` satisfies `I > log 7`.
         Proof: `w1 < 1/7 = 7⁻¹` → `log w1 < log(7⁻¹) = -log 7` → `log 7 < -log w1`.
    (iii) Bound: `w1^n ≤ exp(-I)^n`. Since `I = -log w1`, `exp(-I) = exp(log w1) = w1`,
         so the bound is `w1^n ≤ w1^n` (equality), from `Real.exp_log`.

    Axiom footprint: {propext, Classical.choice, Quot.sound}. No sorry. -/
lemma geometric_activity_bound (w1 : ℝ) (h_pos : 0 < w1) (h_lt : w1 < 1 / 7) :
    TruncatedActivityBound (fun n => w1 ^ n) := by
  constructor
  · -- (i) non-negativity: 0 ≤ w1^n
    intro n
    exact pow_nonneg h_pos.le n
  · -- (ii) + (iii): ∃ I > log 7, ∀ n, w1^n ≤ exp(-I)^n
    refine ⟨-Real.log w1, ?_, fun n => ?_⟩
    · -- Rate: log 7 < -log w1
      -- Step 1: w1 < 7⁻¹
      have hinv : w1 < (7 : ℝ)⁻¹ := by
        have h7inv : (7 : ℝ)⁻¹ = 1 / 7 := by norm_num
        linarith
      -- Step 2: log w1 < log(7⁻¹) by strict log monotonicity
      have hlog : Real.log w1 < Real.log ((7 : ℝ)⁻¹) :=
        Real.log_lt_log h_pos hinv
      -- Step 3: log(7⁻¹) = -log 7, so log w1 < -log 7, hence log 7 < -log w1
      rw [Real.log_inv] at hlog
      linarith
    · -- Bound: w1^n ≤ exp(-(-log w1))^n = exp(log w1)^n = w1^n
      -- Real.exp_log : 0 < w1 → exp(log w1) = w1, so the bound is equality.
      have heq : Real.exp (- -Real.log w1) ^ n = w1 ^ n := by
        rw [neg_neg, Real.exp_log h_pos]
      exact heq.ge

/-! ### D3 — KP summability -/

/-- **D3 (kp_summable) — Kirkwood-Pirogov summability**, proved from D1 + D2.

    For any polymer count `N : ℕ → ℝ` satisfying the Peierls branching recurrence
    (D1) and any coupling `w1` with `0 < w1 < 1/7` (D2), the entropy-weighted
    polymer series `∑_n N n · w1^n` converges absolutely.

    Proof chain:
    1. D1: `peierls_branching_bound N h0 hstep` gives `∀ n, N n ≤ 7^n`.
    2. D2: `geometric_activity_bound w1 h_pos h_lt` gives
          `TruncatedActivityBound (fun n => w1^n)`.
    3. `kp_summable_of_truncatedActivity` (IN TOWER, Wall256_Note.lean:25)
       combines these to conclude `Summable (fun n => N n * w1^n)`.

    IN-TOWER CITE: `kp_summable_of_truncatedActivity` uses `Summable.of_nonneg_of_le`
    (geometric comparison) and `summable_geometric_of_lt_one`; both are classical-trio
    Mathlib lemmas. See Wall256_Note.lean:25-50 for the machine-checked proof.

    Axiom footprint: {propext, Classical.choice, Quot.sound}. No sorry. No axiom. -/
theorem kp_summable (N : ℕ → ℝ) (w1 : ℝ)
    (hN0   : ∀ n, 0 ≤ N n)
    (h0    : N 0 ≤ 1)
    (hstep : ∀ n, N (n + 1) ≤ 7 * N n)
    (h_pos : 0 < w1)
    (h_lt  : w1 < 1 / 7) :
    Summable (fun n => N n * w1 ^ n) :=
  kp_summable_of_truncatedActivity
    hN0
    (peierls_branching_bound N h0 hstep)
    (geometric_activity_bound w1 h_pos h_lt)

-- Axiom audit: all three D-lemmas depend only on the classical trio.
-- Uncomment after lake build with mathlib oleans to verify live:
-- #print axioms peierls_branching_bound
-- #print axioms geometric_activity_bound
-- #print axioms kp_summable

end TheoremaAureum.Towers.YM.BrydgesFederbush
