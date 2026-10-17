# Acceptance ledger

Composition ledger for **Wire encoding and core protocol messages**.

All rows remain `open`; historical claims are asserted or attested, not independently reproduced.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| A01-01 | Wire encoding and shared types satisfies its complete scope and is accepted. | Walk [slice01-wire-foundation ledger](slice01-wire-foundation/ledger.md). | correctness-grade | Imported child scope | open | Historical report only — asserted. | Carryover; acceptance pending. |
| A01-02 | Evaluation messages satisfies its complete scope and is accepted. | Walk [slice02-evaluation ledger](slice02-evaluation/ledger.md). | correctness-grade | Imported child scope | open | Historical report only — asserted. | Carryover; acceptance pending. |
| A01-03 | Session messages satisfies its complete scope and is accepted. | Walk [slice03-sessions ledger](slice03-sessions/ledger.md). | correctness-grade | Imported child scope | open | Historical report only — asserted. | Carryover; acceptance pending. |
| A01-04 | System and introspection messages satisfies its complete scope and is accepted. | Walk [slice04-system ledger](slice04-system/ledger.md). | correctness-grade | Imported child scope | open | Historical report only — asserted. | Carryover; acceptance pending. |
| A01-C | The accepted category APIs compose with the shared codec/types contract. | Demonstrate encode/decode/parse workflows across every child, including aliases and errors. | correctness-grade | Arc capability | open | Not yet demonstrated. | Carryover; acceptance pending. |
| A01-B | All child findings are reflected in the project plan or explicitly dispositioned. | Compare every child result and unresolved finding with the project plan. | correctness-grade | Bubble-up discipline | open | No close records exist. | Carryover; acceptance pending. |
