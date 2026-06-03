# Exceptional-Prime Desert Map — α₀ = 299 + π/10

**Status: data report, independently re-certified (Plan #316). No new mathematics is claimed or proved. GRH/RH stay OPEN; primality is BPSW, not a formal certificate for the 1000+ digit entries.**

**Rule.** A prime `p` is *exceptional* ⟺ `‖p·π/10‖ < 1/p`, where `‖x‖` = distance to nearest integer. Since `299·p ∈ ℤ`, this equals `‖p·(299+π/10)‖`, so the α₀ test and the π/10 test are identical.

**Certification (this report).** Every one of the 20 primes was recomputed from scratch and tested against **π to 9,000 decimal digits** (≥ the 8,300-digit requirement; entry #20 needs ~7,200). For each, `r = p·‖p·π/10‖` was evaluated at full precision and the rule confirmed as `r < 1`; primality was re-confirmed by BPSW (`sympy.isprime`). Reproduce with `python3 scripts/verify_desert_map.py`. Exact integers and all fields: `data/desert_map.csv`.

**Completeness (cited, not re-derived here).** By Legendre / best-approximation theory every `q` with `‖q·α₀‖ < 1/q` is a convergent or upper-semiconvergent of π/10; all such `q ≤ 10⁴⁰⁰⁰` were enumerated and tested exactly with a decision certificate (min margin ~10⁸²⁹⁵ ≫ threshold 10⁸⁰⁰⁰) in `data/pi10_exceptional_primes.txt`. **Result: exactly 20 exceptional primes to 10⁴⁰⁰⁰.**

## Structural claim

- **S₄ = {2, 3, 19, 191}** (the "trio + 191").
- **C_unwt(S₄) = 1.433676813 < 7.2111** (= 2√13, the classical bound). The unweighted energy of the whole set barely moves above this — **C_unwt(S₂₀) = 1.433676813** — because `log p/(p−1) → 0` for the giant primes, so only S₄ contributes meaningfully.
- **C_wt(S₄) = 11.42214869**, growing to **C_wt(S₂₀) = 40793.25685** (≫ 7.2111). The weighted energy is flagged **Open** — it is a computed quantity, not a proof of any bound.
- **P5 = 3993746143633** (13 digits) opens **Desert 1**, a void of **3993746143441** consecutive non-exceptional integers after 191 (= P5 − 191 − 1).

## P5 explicit verification (the centerpiece)
```
P5            = 3993746143633   (13 digits)
‖P5·π/10‖     = 3.81503838596e-14
1/P5          = 2.50391478085e-13
‖P5·π/10‖ < 1/P5 ?  True   (r = P5·‖P5·π/10‖ = 0.1523629484 < 1)
```

## Desert widths  (width_k = p_k − p_(k-1) − 1)

| Desert | between | width (consecutive non-exceptional integers) |
|---:|:---|:---|
| 1 | P1 → P2 | 0 |
| 2 | P2 → P3 | 15 |
| 3 | P3 → P4 | 171 |
| 4 | P4 → P5 | 3993746143441 |
| 5 | P5 → P6 | 3220063985374763 |
| 6 | P6 → P7 | 631474302110268417202233 |
| 7 | P7 → P8 | 10531012662113225396941729792152809 |
| 8 | P8 → P9 | 763655502743292386…218764019701  (76 digits) |
| 9 | P9 → P10 | 878228977826120898…187360517525  (95 digits) |
| 10 | P10 → P11 | 489830773366832200…230719479149  (111 digits) |
| 11 | P11 → P12 | 194626099310997110…823451721901  (372 digits) |
| 12 | P12 → P13 | 883216099405337755…541776675229  (859 digits) |
| 13 | P13 → P14 | 196819030242832262…533358308079  (1025 digits) |
| 14 | P14 → P15 | 529434903242710060…161306314575  (1592 digits) |
| 15 | P15 → P16 | 174943788961438175…111980648163  (1863 digits) |
| 16 | P16 → P17 | 915117487968349622…221401711395  (2272 digits) |
| 17 | P17 → P18 | 207163392083512332…927062252433  (2389 digits) |
| 18 | P18 → P19 | 994698744384214170…684906919177  (3428 digits) |
| 19 | P19 → P20 | 127374706877116396…806614900713  (3548 digits) |

## The 20 exceptional primes

### PRIME #1 — 1 digit  ·  [Trio]
- Exact: `2`
- r = p·‖p·π/10‖ = 0.7433629386  (< 1 ✓)
- ‖p·π/10‖ = 0.3716815
- BPSW prime: True
- Gap from previous: — (first)
- C_unwt cumulative: 0.6931471806
- C_wt cumulative: 1.386294361

### PRIME #2 — 1 digit  ·  [Trio]
- Exact: `3`
- r = p·‖p·π/10‖ = 0.1725666118  (< 1 ✓)
- ‖p·π/10‖ = 0.0575222
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 1
- Desert width (p_k − p_(k-1) − 1): 0
- C_unwt cumulative: 1.242453325
- C_wt cumulative: 3.034212794

### PRIME #3 — 2 digits  ·  [Trio]
- Exact: `19`
- r = p·‖p·π/10‖ = 0.5885052054  (< 1 ✓)
- ‖p·π/10‖ = 0.03097396
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 16
- Desert width (p_k − p_(k-1) − 1): 15
- C_unwt cumulative: 1.406033268
- C_wt cumulative: 6.142231717

### PRIME #4 — 3 digits  ·  [Trio_End]
- Exact: `191`
- r = p·‖p·π/10‖ = 0.8441595609  (< 1 ✓)
- ‖p·π/10‖ = 0.004419684
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 172
- Desert width (p_k − p_(k-1) − 1): 171
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 11.42214869

### PRIME #5 — 13 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `3993746143633`
- r = p·‖p·π/10‖ = 0.1523629484  (< 1 ✓)
- ‖p·π/10‖ = 3.815038e-14
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 3993746143442
- Desert width (p_k − p_(k-1) − 1): 3993746143441
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 40.43789948

### PRIME #6 — 16 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `3224057731518397`
- r = p·‖p·π/10‖ = 0.7749507673  (< 1 ✓)
- ‖p·π/10‖ = 2.40365e-16
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 3220063985374764
- Desert width (p_k − p_(k-1) − 1): 3220063985374763
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 76.1473166

### PRIME #7 — 24 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `631474305334326148720631`
- r = p·‖p·π/10‖ = 0.1441998944  (< 1 ✓)
- ‖p·π/10‖ = 2.283543e-25
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 631474302110268417202234
- Desert width (p_k − p_(k-1) − 1): 631474302110268417202233
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 130.9496608

### PRIME #8 — 35 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `10531012662744699702276055940873441`
- r = p·‖p·π/10‖ = 0.3570549299  (< 1 ✓)
- ‖p·π/10‖ = 3.390509e-35
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 10531012662113225396941729792152810
- Desert width (p_k − p_(k-1) − 1): 10531012662113225396941729792152809
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 209.2892934

### PRIME #9 — 76 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `763655502743292386…274704893143  (76 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.4366732631  (< 1 ✓)
- ‖p·π/10‖ = 5.718197e-77
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 763655502743292386…218764019702  (76 digits)
- Desert width (p_k − p_(k-1) − 1): 763655502743292386…218764019701  (76 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 384.0161219

### PRIME #10 — 95 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `878228977826120898…462065410669  (95 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.833469601  (< 1 ✓)
- ‖p·π/10‖ = 9.490345e-96
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 878228977826120898…187360517526  (95 digits)
- Desert width (p_k − p_(k-1) − 1): 878228977826120898…187360517525  (95 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 602.6318578

### PRIME #11 — 111 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `489830773366832287…692784889819  (111 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.5405288295  (< 1 ✓)
- ‖p·π/10‖ = 1.103501e-111
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 489830773366832200…230719479150  (111 digits)
- Desert width (p_k − p_(k-1) − 1): 489830773366832200…230719479149  (111 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 857.5051079

### PRIME #12 — 372 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `194626099310997110…516236611721  (372 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.5248111827  (< 1 ✓)
- ‖p·π/10‖ = 2.69651e-372
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 194626099310997110…823451721902  (372 digits)
- Desert width (p_k − p_(k-1) − 1): 194626099310997110…823451721901  (372 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 1712.430087

### PRIME #13 — 859 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `883216099405337755…058013286951  (859 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.5359789266  (< 1 ✓)
- ‖p·π/10‖ = 6.068491e-860
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 883216099405337755…541776675230  (859 digits)
- Desert width (p_k − p_(k-1) − 1): 883216099405337755…541776675229  (859 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 3690.226497

### PRIME #14 — 1025 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `196819030242832262…591371595031  (1025 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.01476066777  (< 1 ✓)
- ‖p·π/10‖ = 7.499614e-1027
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 196819030242832262…533358308080  (1025 digits)
- Desert width (p_k − p_(k-1) − 1): 196819030242832262…533358308079  (1025 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 6048.750747

### PRIME #15 — 1592 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `529434903242710060…752677909607  (1592 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.9803959394  (< 1 ✓)
- ‖p·π/10‖ = 1.851778e-1592
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 529434903242710060…161306314576  (1592 digits)
- Desert width (p_k − p_(k-1) − 1): 529434903242710060…161306314575  (1592 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 9713.83027

### PRIME #16 — 1863 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `174943788961438175…864658557771  (1863 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.05049001301  (< 1 ✓)
- ‖p·π/10‖ = 2.886071e-1864
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 174943788961438175…111980648164  (1863 digits)
- Desert width (p_k − p_(k-1) − 1): 174943788961438175…111980648163  (1863 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 14001.80301

### PRIME #17 — 2272 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `915117487968349622…086060269167  (2272 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.5457595867  (< 1 ✓)
- ‖p·π/10‖ = 5.96382e-2273
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 915117487968349622…221401711396  (2272 digits)
- Desert width (p_k − p_(k-1) − 1): 915117487968349622…221401711395  (2272 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 19233.18764

### PRIME #18 — 2389 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `207163392083512332…013122521601  (2389 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.6931474143  (< 1 ✓)
- ‖p·π/10‖ = 3.345897e-2389
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 207163392083512332…927062252434  (2389 digits)
- Desert width (p_k − p_(k-1) − 1): 207163392083512332…927062252433  (2389 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 24732.48918

### PRIME #19 — 3428 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `994698744384214170…698029440779  (3428 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.5105709998  (< 1 ✓)
- ‖p·π/10‖ = 5.132921e-3429
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 994698744384214170…684906919178  (3428 digits)
- Desert width (p_k − p_(k-1) − 1): 994698744384214170…684906919177  (3428 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 32625.74556

### PRIME #20 — 3548 digits  ·  [GIANT]  ·  **Open** (P5–P20 flagged Open)
- Exact: `127374706877116396…504644341493  (3548 digits)`  — full integer in `data/desert_map.csv`
- r = p·‖p·π/10‖ = 0.0276853026  (< 1 ✓)
- ‖p·π/10‖ = 2.173532e-3549
- BPSW prime: True
- Gap from previous (p_k − p_(k-1)): 127374706877116396…806614900714  (3548 digits)
- Desert width (p_k − p_(k-1) − 1): 127374706877116396…806614900713  (3548 digits)
- C_unwt cumulative: 1.433676813
- C_wt cumulative: 40793.25685

## Notes
- **First desert (191 → P5)** is the headline void: 3993746143441 consecutive integers with zero exceptional primes.
- The circulated list `…291,317,607,…` is a `299+π` (not π/10) artifact; 291 = 3×97 is composite; only 2,3,19,191 of it actually pass. Excluded.
- **Honesty.** BPSW is not a formal primality proof for the 1000+ digit entries; C_wt(S₂₀) is a computed value flagged Open; this report proves no new mathematics and asserts no bound.
