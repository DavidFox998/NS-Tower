# Boundary Artifact — LLM digit-literal instability (2026-06-02)

**Scope/honesty note.** This file *documents* an observed text-generation
artifact per the v2.3 protocol. It is **not** a mathematical result, is **not**
part of any Lean proof, and asserts **nothing** about `Sym`, about `digit_len =
13`, or about the ζ critical line `Re(s) = 1/2`. Those links are explicitly
listed as `not_established`. The only locked numeric fact here is
`P5_genuine = 1000000001119` (`digit_len = 13`, `Sym = 1`).

```json
{
  "boundary_artifact": {
    "date": "2026-06-02",
    "type": "LLM_DIGIT_LITERAL_INSTABILITY",
    "observation": "Long digit literals reproduced unreliably by LLMs; common failure is +/-1 zero in zero-run. General weakness, not specific to any digit_len.",
    "provenance": {
      "P5_genuine": {
        "value": "1000000001119",
        "digits": 13,
        "source": "H4Boundary.lean",
        "status": "STABLE"
      },
      "P5_overzero_15": {
        "value": "100000000001119",
        "digits": 15,
        "source": "typed_instruction",
        "status": "INTRODUCED"
      },
      "P5_overzero_16": {
        "value": "1000000000001119",
        "digits": 16,
        "source": "typed_instruction", 
        "status": "INTRODUCED"
      },
      "agent_emitted_14": {
        "value": "10000000001119",
        "digits": 14,
        "source": "agent_generation",
        "status": "OBSERVED"
      }
    },
    "not_established": [
      "spike_at_digit_len_13",
      "link_to_Sym",
      "link_to_critical_line_1_2"
    ],
    "mitigation": "digit_len from ${#literal}, never model/eye count",
    "sha256_colophon": "pending_pdf_hash"
  },
  "P5_genuine": {
    "value": 1000000001119,
    "digit_len": 13,
    "Sym": 1,
    "status": "LOCKED"
  }
}
```

BOUNDARY ARTIFACT (honest form)
- Observation: long digit literals are reproduced unreliably by LLMs;
  the common failure is +/-1 zero in a long zero-run. General weakness,
  not specific to any digit_len value.
- Provenance (2026-06-02 thread): the over-zeroed literals
  (100000000001119 = 15 digits, 1000000000001119 = 16 digits) were
  introduced in typed instructions; the agent's emitted 14-digit value
  was 10000000001119, and the 13-digit source 1000000001119 was stable.
- NOT established: any spike or transition at digit_len=13; any link to
  Sym or to the 1/2 critical line. None of these is supported.
- Mitigation used: digit counts taken from a deterministic tool
  (${#literal}), never from model/eye counting.
