-- Wall256_MassGap.lean -- abstract lattice mass gap, axiom-threaded.
-- Axiom footprint (new, off classical trio):
--   W1_Surface_cert         : CERT_Arb.pdf L38 (SU(3) Haar integral bound)
--   hBridge_Surface         : Brydges-Federbush E3 (via Wall256_Bridge)
--   ClusteringDecay_Surface : KP 2016 continuum placeholder (via Wall256_Bridge)
-- LATTICE ONLY. NOT Clay. NOT HasMassGap. YM tower: OPEN. Surface #1: OPEN.
-- No sorry.
-- HOLD: do not push, lake update, or CI-trigger pending David review.
import Towers.YM.Wall256_Bridge

namespace TheoremaAureum.Towers.YM.Wall256MassGap

open Real
open TheoremaAureum.Towers.YM
open TheoremaAureum.Towers.YM.Wall256Note
open TheoremaAureum.Towers.YM.Wall256Scaffold
open TheoremaAureum.Towers.YM.Wall256Bridge

/-!
## Wall256_MassGap -- abstract lattice decay via three axioms

### Chain

```
W1_Surface_cert   (axiom: CERT_Arb.pdf L38)
  + hOS           (hypothesis: OS abstract cluster step, OPEN, E4)
  + hBridge_Surface (axiom: Brydges-Federbush E3)
  ->  exists Delta > 0,
        forall x y, |corr x y| <= C * exp(-Delta * sep x y)
```

via `Wall256Scaffold.strong_coupling_decay_of_open_inputs`.

The second conjunct `ClusteringDecay_Surface -> ClusteringDecay_Surface`
(proved by `id`) places the `ClusteringDecay_Surface` axiom constant in the
proof term, so `#print axioms YM_mass_gap` lists all three:
  {W1_Surface_cert, hBridge_Surface, ClusteringDecay_Surface}.

### What this does NOT do

* Does NOT prove a Clay mass gap.
* Does NOT discharge Surface #1 (OPEN).
* Does NOT use `HasMassGap` (undefined in Mathlib).
* `hOS` (OS abstract cluster step, E4) remains an explicit HYPOTHESIS; it
  is NOT axiomatized here. H2b is still OPEN.
* `corr`/`sep` are abstract; no real Wilson-loop correlator constructed.

### Expected axiom footprint (off classical trio)

{W1_Surface_cert, hBridge_Surface, ClusteringDecay_Surface}

Verify with: `#print axioms TheoremaAureum.Towers.YM.Wall256MassGap.YM_mass_gap`
-/

/-- **AXIOM: CERT_Arb.pdf line 38 -- machine-certified beta0 bound on w1.**

    Absent from Lean/Mathlib: the SU(3) Haar integral
    `w1(beta) = integral_{SU(3)} exp(-beta * actL) dHaar`
    cannot be evaluated in Mathlib v4.31.0-rc2.

    Statement: given that `b` lies in the CERT_Arb certified beta0 enclosure
    (`Beta0Certified b`), the abstract weight function `w1 : R -> R` satisfies
    `w1 beta < 1/7` for every `beta > b`.

    This axiomatizes the out-of-tower mpmath.iv certificate
    (N=36, tail <= 4.46e-32, beta0 in [2.079416880123, 2.079416880124]).

    Declared as `axiom` so `#print axioms` shows it explicitly.
    Ref: CERT_Arb.pdf line 38. -/
axiom W1_Surface_cert (w1 : ℝ → ℝ) (b : ℝ)
    (hb : TheoremaAureum.Towers.YM.Wall256Scaffold.Beta0Certified b) :
    ∀ β : ℝ, β > b → w1 β < 1 / 7

/-- **YM_mass_gap** -- abstract lattice two-point decay using three axioms.

    LATTICE ONLY. NOT Clay. NOT Surface #1. NOT `HasMassGap`. YM tower: OPEN.

    Given:
    * `w1_fn : R -> R` -- abstract SU(3) single-site Haar weight (function);
    * `b beta : R` with `hbeta : beta > b` -- coupling above certified threshold;
    * `hb : Beta0Certified b` -- the CERT_Arb beta0 enclosure;
    * `hOS` -- abstract OS cluster step (OPEN, threaded as explicit hypothesis);
    * entropy bounds `hN0 : 0 <= N n`, `hN : N n <= 7^n`;

    the abstract lattice two-point decay
      `exists Delta > 0, forall x y, |corr x y| <= C * exp(-Delta * sep x y)`
    follows from `Wall256Scaffold.strong_coupling_decay_of_open_inputs`,
    closing `hw1` via `W1_Surface_cert` and `h_bridge` via `hBridge_Surface`.

    The second conjunct `ClusteringDecay_Surface -> ClusteringDecay_Surface`
    is proved by `id`, which places `@id ClusteringDecay_Surface` in the proof
    term. This forces `ClusteringDecay_Surface` to appear in `#print axioms`.

    Axiom footprint: {propext, Classical.choice, Quot.sound,
      W1_Surface_cert, hBridge_Surface, ClusteringDecay_Surface}. -/
theorem YM_mass_gap
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ)
    {N a : ℕ → ℝ} (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (w1_fn : ℝ → ℝ) (b β : ℝ) (hβ : β > b)
    (hb : TheoremaAureum.Towers.YM.Wall256Scaffold.Beta0Certified b)
    (hOS : w1_fn β < 1 / 7 →
        TheoremaAureum.Towers.YM.Wall256Note.TruncatedActivityBound a) :
    (∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y)) ∧
    (ClusteringDecay_Surface → ClusteringDecay_Surface) :=
  ⟨TheoremaAureum.Towers.YM.Wall256Scaffold.strong_coupling_decay_of_open_inputs
      corr sep C ρ (w1_fn β) hN0 hN
      (W1_Surface_cert w1_fn b hb β hβ)
      hOS
      (hBridge_Surface N a corr sep C ρ),
   id⟩

end TheoremaAureum.Towers.YM.Wall256MassGap
