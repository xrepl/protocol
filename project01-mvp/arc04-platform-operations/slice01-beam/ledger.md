# Acceptance ledger

Imported scope for **BEAM operation messages**. See [slice plan](slice-plan.md) for exact source paths, operations and provenance.

All rows remain `open`; historical claims are asserted or attested, not independently reproduced.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| A04S01-01 | All 6 listed operation contracts have request/response construction and parsing as specified. | Compare every listed spec operation with the named public source API and tests. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A04S01-02 | Binary keys, operation/field aliases and optional/required fields preserve compatibility. | Inspect the guide checklist and exercise each applicable input/output alias. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A04S01-03 | Positive, negative and round-trip cases pass without weakening the payload oracle. | Run the named tests through the repository CI commands; inspect missing/invalid-field assertions. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A04S01-04 | Public module/function documentation and usage examples match the delivered API. | Inspect docstrings and exercise the documented examples on the recorded source revision. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
