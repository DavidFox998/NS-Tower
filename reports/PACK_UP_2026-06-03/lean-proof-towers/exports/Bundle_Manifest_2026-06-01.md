# Big Day Bundle — Manifest (2026-06-01)

- `bundle_id: Final_Bundle_2026-06-01`
- `scope: EXPORT_ONLY` — no Lean changes, no proofs, no new claims.
- `lean_repo_commit (HEAD): a1980ec8e09f72fc1620a1265ebdf7d9802336c8`
- `Wall256_Scaffold.lean last changed at: ac241de37a86e53298d80071c2b43cd0243a1f53` (post-β₀ wiring)
- `bundle_archive: Final_Bundle_2026-06-01.zip`
- `bundle_archive SHA-256: d04426cc107d7ada545766eef7873228954d7d45cb5a7329c0a7cfd3a236b1e2`

## Artifact table

| File | SHA-256 | Status | Honesty Lock |
| --- | --- | --- | --- |
| `D4_w1_NEGATIVE_Certificate_2026-06-01.pdf` | `9a794ccf0c707812e6fa3db2095a350f2d5b61a011fcc77e453c548716ac8764` | VERIFIED_OUT_OF_TOWER · NEGATIVE (w1(0.86)≈0.4324 > 1/7; D4 fails) | closes_surface_1: false |
| `CERT_Arb_beta0.pdf` | `b5a9f0a7666a91f283a7d4531ae99dff2097c2cedef10424b77833b7bbc840d3` | VERIFIED_OUT_OF_TOWER (β₀∈[2.079416880123, 2.079416880124]) | closes_surface_1: false |
| `Big_Day_Status_2026-06-01.md` | `9a00f1106bf93da155d8366521579eeec17bcacd2f4aea62fbcd0159dedfc7d1` | STATUS_DOC | closes_surface_1: false |
| `D1_to_D3_Plan.md` | `a40422fe7595ebc2c3c7d8d4b80a2c5645431ac1a52f3699c732562d4574b553` | PLAN (docs-only; D1–D3/hOS/h_bridge map) | closes_surface_1: false |
| `hOS_Plan.md` | `1a95b66bec0a0eb2e038f023db99f56caaae3e620863582de1746d706df250a0` | PLAN (docs-only; D5 dependency map) | closes_surface_1: false |
| `h_bridge_Plan.md` | `90e8c9407ba407ebea070da284e9ec8797177de42a734bb9a5b60c6418877ec6` | PLAN (docs-only; D6 dependency map) | closes_surface_1: false |
| `Final_Status_Bundle_2026-06-01.json` | `7bf08e1c516156f7bb8d52617ef7d95014b8512e496d4180949e1623ddbf8b24` | STATUS_BUNDLE | closes_surface_1: false |
| `Wall256_Scaffold.lean` | `9846d0f61c0e4804c986fb398040dd4b4ae3425d31f799a7313a17296cc17157` | COMPILES (direct-lean) · classical trio · post-β₀ wiring · NOT a brick | closes_surface_1: false |

## What is and is NOT in this bundle

- **OUT-OF-TOWER certs** (`D4_w1_NEGATIVE`, `CERT_Arb_beta0`) are interval-numerics
  evidence, **not** Lean terms; they discharge **zero** Lean obligations.
- **PLAN docs** (`D1_to_D3`, `hOS`, `h_bridge`) are dependency maps only — they
  enumerate requirements, discharge nothing, schedule nothing.
- **`Wall256_Scaffold.lean`** carries the honest conditional reduction
  `strong_coupling_decay_of_open_inputs` over the three OPEN hypotheses
  (`hw1`, `hOS`, `h_bridge`) plus the β₀ wiring (`Beta0Certified` / `Hw1_Surface`
  / `theorem hw1`). It compiles (EXIT=0), axiom footprint = classical trio
  `{propext, Classical.choice, Quot.sound}`, **no `sorry` / no new axiom**. It is
  **NOT a brick** and proves **no** mass gap.

## Honesty locks (bundle-wide)

```yaml
scope: EXPORT_ONLY
writes_lean: false
produces_proof: false
discharges_surface: false
closes_surface_1: false
surface_1_status: OPEN
ym_tower_status: OPEN
m_gt_0_claimed: false
mass_gap_proven: false
beta0_discharges_any_lean_obligation: false
hOS_status: OPEN
h_bridge_status: OPEN
rh_grh_c05_separate: true
no_rh_claims_in_ym_certs: true
note: >
  This bundle EXPORTS already-landed artifacts and their SHA-256 digests. It makes
  no new claim. Surface #1 and the YM tower stay OPEN; the certified β₀ is
  out-of-tower numerics that discharges no Lean obligation. No mass-gap / μ>0 /
  Clay / RH claim; the M7/GRH/C05 tower stays SEPARATE.
```
