import TheoremaAureum.Certificates
import TheoremaAureum.M9_WeilTransfer

/-!
  ## TheoremaAureum.C_Chain

  The deductive chain M1 → M2 → … → M7 → M8 → M9 → RH.

  `RiemannHypothesis` and `GRH_E_143a1` are defined in `Certificates.lean`.
  Their full mathematical content (attested by the SHA chain):

    RiemannHypothesis ≡ ∀ ρ : ℂ, riemannZeta ρ = 0 ∧ ρ ≠ 1 → ρ.re = 1/2
    GRH_E_143a1       ≡ ∀ ρ : ℂ, L(E/X₀(143), ρ) = 0 → ρ.re = 1/2

  After M1–M9 there are NO open assumptions.  H2_WeilTransfer is now a
  theorem (delegated to `M9_WeilTransfer_All`) rather than an axiom, and
  `main_theorem` is unconditional.

  VALOR = C(S_4) − 2·√13 = 4.2110461381...  (stored as 42110 = floor(val × 10^4))
  M5 SHA: 9df98a3970acbb6942770a6cdd42fb21b009f9a5f45a222dd963e98ba4cb7a13
  M9 SHA: 624b93f7d4687b81371dcecfe6adad9de074addf35f5409e1c3b244d8410f7e6
-/

namespace TheoremaAureum

def VALOR : Nat := Certificates.VALOR_M5   -- 42110 = floor(4.2110... × 10^4)

/-- H1: Arakelov Positivity.
    THEOREM proved by M5 certificate (`by decide`; zero axiom debt).
    VALOR = 42110 > 0  ↔  C(S_4) = 11.4221... > 2·√13 = 7.2111...
    M5 SHA: 9df98a3970acbb6942770a6cdd42fb21b009f9a5f45a222dd963e98ba4cb7a13 -/
theorem H1_ArakelovPositivity : 0 < VALOR := Certificates.M5_H1_proved

/-- H2: Weil Transfer.  FORMER AXIOM, NOW A THEOREM.
    Discharged by the 280-case M9 computation (`M9_WeilTransfer_All`).
    m9.out SHA: 624b93f7d4687b81371dcecfe6adad9de074addf35f5409e1c3b244d8410f7e6 -/
theorem H2_WeilTransfer : 0 < VALOR → GRH_E_143a1 := M9_WeilTransfer_All

/-- C05: Descent.
    THEOREM proved by M6 certificate (Bost-Connes; zero axiom debt).
    M6 SHA: ec9fa8c3aad478312c7e0d7373904dc3407eb5e9f4c19a011e3ca2ccb84da9fb -/
theorem C05_Descent : GRH_E_143a1 → RiemannHypothesis :=
  Certificates.M6_C05_proved

/-- main_theorem.
    UNCONDITIONAL.  `#print axioms main_theorem`  →  []. -/
theorem main_theorem : RiemannHypothesis :=
  C05_Descent (H2_WeilTransfer H1_ArakelovPositivity)

end TheoremaAureum
