/-
  Towers / YM / InfraredCutoffStub (Wall 566 — Stubwall sprint, Phase 1)

  Pure-core stub. ZERO mathlib imports. `Nat`/`Int`-only carriers.

  Surface #1 remains OPEN. These bricks are trivially/vacuously true:
  `ir_cutoff` is the constant `0` and `finite_volume_obs` is the
  constant-zero map, so the statements are just `0 = 0 → ∀ v, 0 = 0`
  and `0 = 0`. They say NOTHING about any real infrared cutoff,
  finite-volume observables, thermodynamic limit, or Wilson transfer
  operator and do NOT close the Yang–Mills mass gap. Placeholder
  carriers under the locked Dirac/stub stand-in.
-/

namespace TheoremaAureum.Towers.YM
def ir_cutoff : Nat := 0
def finite_volume_obs : Nat → Int := fun _ => 0

theorem ir_cutoff_vacuous :
  ir_cutoff = 0 → ∀ v : Nat, finite_volume_obs v = 0 := by
  intro h v; rfl

theorem ir_cutoff_const :
  ir_cutoff = 0 := by
  rfl
end TheoremaAureum.Towers.YM
