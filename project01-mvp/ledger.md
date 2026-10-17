# Acceptance ledger

Project definition-of-done and recomposition ledger. This is a carryover contract, not a migration completion checklist.

All rows remain `open`; historical claims are asserted or attested, not independently reproduced.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| P-01 | Wire encoding and core protocol messages satisfies its scope and composition criteria. | Walk [arc01-wire-and-core ledger](arc01-wire-and-core/ledger.md) and inspect actual composition evidence. | correctness-grade | Imported library roadmap | open | Historical completion assertion only. | Carryover; acceptance pending. |
| P-02 | Editor intelligence, navigation and documentation messages satisfies its scope and composition criteria. | Walk [arc02-editor-services ledger](arc02-editor-services/ledger.md) and inspect actual composition evidence. | correctness-grade | Imported library roadmap | open | Historical completion assertion only. | Carryover; acceptance pending. |
| P-03 | Debugging, testing, refactoring and compilation messages satisfies its scope and composition criteria. | Walk [arc03-development-tools ledger](arc03-development-tools/ledger.md) and inspect actual composition evidence. | correctness-grade | Imported library roadmap | open | Historical completion assertion only. | Carryover; acceptance pending. |
| P-04 | BEAM and advanced protocol messages satisfies its scope and composition criteria. | Walk [arc04-platform-operations ledger](arc04-platform-operations/ledger.md) and inspect actual composition evidence. | correctness-grade | Imported library roadmap | open | Historical completion assertion only. | Carryover; acceptance pending. |
| P-05 | All 83 operation contracts conform, including binary keys, field/operation aliases and error/validation behavior. | Reconcile spec operations 1–83 with slice ledgers and exercised payload oracles. | correctness-grade | Guide success criteria | open | Historical 83/83 assertion; status representation unresolved. | Carryover; acceptance pending. |
| P-06 | Builds/tests pass; measured test coverage exceeds 90%; documentation, examples and style meet the guide. | Run pinned-revision build/test/coverage checks; inspect the full guide checklist. | correctness-grade | Guide success criteria | open | Historical 776 tests; no fresh measured coverage. | Carryover; acceptance pending. |
| P-07 | Whole-library package/composition, performance checks and extraction consumer integration have evidence. | Walk [composition slice ledger](slice01-composition-and-release/ledger.md). | correctness-grade | Guide final integration / extraction success criteria | open | Not established by migration. | Carryover; acceptance pending. |
| P-08 | All arc and composition findings have explicit project dispositions. | Walk each child ledger/result and the project open findings before project close. | correctness-grade | Bubble-up and closure discipline | open | Project remains open. | Carryover; acceptance pending. |
