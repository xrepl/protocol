# Acceptance ledger

Imported scope for **Wire encoding and shared types**. See [slice plan](slice-plan.md) for exact source paths, operations and provenance.

All rows remain `open`; historical claims are asserted or attested, not independently reproduced.

| ID | Criterion | Verify | Significance | Origin | Status | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| A01S01-01 | The framed codec and shared type/alias helpers satisfy the extraction and foundation contracts. | Exercise length framing, partial/multiple packet buffers, malformed inputs, shared message fields and alias helpers in the named codec/type suites. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A01S01-02 | Binary keys, operation/field aliases and optional/required fields preserve compatibility. | Inspect the guide checklist and exercise each applicable input/output alias. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A01S01-03 | Positive, negative and round-trip cases pass without weakening the payload oracle. | Run the named tests through the repository CI commands; inspect missing/invalid-field assertions. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
| A01S01-04 | Public module/function documentation and usage examples match the delivered API. | Inspect docstrings and exercise the documented examples on the recorded source revision. | correctness-grade | Historical guide / spec | open | [Session claim](../../artifacts/implementation/SESSION_PROGRESS.md) — asserted; not re-run. | Carryover; acceptance pending. |
