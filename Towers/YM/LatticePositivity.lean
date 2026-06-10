/-
  Towers/YM/LatticePositivity.lean — Wall 571-B, brick [YM1-LB-Core]

  HONEST SCOPE (read before citing this file):
  This is a *discrete, pure-core* (no mathlib, no imports) lemma over
  `Int`/`Nat`. `lattice_positivity` says: a finite sum of integer
  squares is `≥ 0`, and is `= 0` iff every term is `0`. That is the
  trivial discrete shadow of "H ≥ 0" — NOTHING more.

  This brick is registered as [YM1-LB-Core] (the discrete lower bound),
  NOT as [YM1]. It makes NO claim about:
    - the Yang-Mills mass gap, μ > 0, or any spectral gap;
    - closing Surface #1 (which remains OPEN) or Surface #2;
    - any real Wilson transfer operator or continuum YM dynamics.
  YM tower Status stays Open (docs/ROADMAP.md). The real-analysis (ℝ)
  companion is deferred to `Towers/YM/LatticePositivityReal.lean`
  (Wall 571 "B-deferred") pending a healthy mathlib cache.

  Axiom footprint: `#print axioms …lattice_positivity` = [] (strictly
  empty — no propext/Classical.choice/Quot.sound, no sorry/admit).

  Verification (lake-free, per the lake gotcha in replit.md):
    cp Towers/YM/LatticePositivity.lean /tmp/lp.lean
    printf '\n#print axioms TheoremaAureum.YM_MassGap.lattice_positivity\n' >> /tmp/lp.lean
    lean /tmp/lp.lean      # expect: "does not depend on any axioms"
  NOT registered in scripts/check-towers.sh BRICKS (that path is
  lake-gated; the script-reported wall is unchanged).
-/
namespace TheoremaAureum.YM_MassGap

def sum_sq : List Int → Nat :=
  fun xs => (xs.map fun x => (x.natAbs * x.natAbs)).foldl (· + ·) 0

theorem foldl_add_acc : ∀ (l : List Nat) (a : Nat),
    l.foldl (· + ·) a = a + l.foldl (· + ·) 0 := by
  intro l
  induction l with
  | nil => intro a; rfl
  | cons h t ih =>
      intro a
      rw [List.foldl_cons, List.foldl_cons, ih (a + h), ih (0 + h),
          Nat.zero_add, Nat.add_assoc]

theorem sum_sq_cons (h : Int) (t : List Int) :
    sum_sq (h :: t) = h.natAbs * h.natAbs + sum_sq t := by
  unfold sum_sq
  rw [List.map_cons, List.foldl_cons, foldl_add_acc, Nat.zero_add]

theorem term_iff (h : Int) :
    h.natAbs * h.natAbs = 0 ↔ decide (h = 0) = true := by
  constructor
  · intro hmul
    have h1 : h.natAbs = 0 := by
      rcases Nat.mul_eq_zero.mp hmul with h0 | h0
      · exact h0
      · exact h0
    have h2 : h = 0 := by
      cases h with
      | ofNat n =>
        have hn : n = 0 := h1
        subst hn
        rfl
      | negSucc n =>
        have hn : n + 1 = 0 := h1
        exact Nat.noConfusion hn
    exact decide_eq_true h2
  · intro hd
    have h2 : h = 0 := of_decide_eq_true hd
    subst h2
    rfl

theorem lattice_positivity :
    ∀ xs : List Int, 0 ≤ sum_sq xs ∧ (sum_sq xs = 0 ↔ xs.all (· = 0)) := by
  intro xs
  refine ⟨Nat.zero_le _, ?_⟩
  induction xs with
  | nil => exact Iff.intro (fun _ => rfl) (fun _ => rfl)
  | cons h t ih =>
      constructor
      · intro hsum
        rw [sum_sq_cons] at hsum
        have hh : h.natAbs * h.natAbs = 0 :=
          Nat.eq_zero_of_add_eq_zero_right hsum
        have htl : sum_sq t = 0 :=
          Nat.eq_zero_of_add_eq_zero_left hsum
        have hb1 : decide (h = 0) = true := (term_iff h).mp hh
        have hb2 : t.all (fun x => decide (x = 0)) = true := ih.mp htl
        show (decide (h = 0) && t.all (fun x => decide (x = 0))) = true
        rw [hb1, hb2]
        rfl
      · intro hall
        have hall' :
            (decide (h = 0) && t.all (fun x => decide (x = 0))) = true := hall
        have hb1 : decide (h = 0) = true := by
          revert hall'
          cases decide (h = 0) with
          | true => intro _; rfl
          | false => intro hx; exact Bool.noConfusion hx
        have hb2 : t.all (fun x => decide (x = 0)) = true := by
          have hcopy := hall'
          rw [hb1] at hcopy
          exact hcopy
        have hh : h.natAbs * h.natAbs = 0 := (term_iff h).mpr hb1
        have htl : sum_sq t = 0 := ih.mpr hb2
        show sum_sq (h :: t) = 0
        rw [sum_sq_cons, hh, htl]

end TheoremaAureum.YM_MassGap
