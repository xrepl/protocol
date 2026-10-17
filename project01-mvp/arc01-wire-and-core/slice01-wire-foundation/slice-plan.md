# Wire encoding and shared types

- Project: `project01-mvp`
- Arc: `arc01-wire-and-core`
- Status: historical implementation claimed complete; reconstructed acceptance open
- Workflow: one contributor; no assignment issued by this migration
- Baseline: `0bfa6fd727da06338d064c7651de9b984bfabc23` in the implementation worktree

## Goal and scope

Provide the library's wire representation for this capability to LFE clients and servers through the public modules below. This is a reconstructed scope unit, not evidence of a historical execution branch or accepted slice.

- Length-prefixed MessagePack encoding, decoding and buffering.
- Shared message fields, binary-key normalization, required-field handling and field-alias helpers.
- Independent library compilation and codec/type tests.

Delivery: `src/xrepl-ptcl-msgpack.lfe`, `src/xrepl-ptcl-types.lfe`.
Checks: `test/xrepl-ptcl-msgpack-tests.lfe`, `test/xrepl-ptcl-types-tests.lfe`.
Server handlers, editor UI, networking and authentication enforcement belong to their consumer repositories. Their message fields remain part of the wire contract.

## Dependencies

None; consumes the historical extraction design and MessagePack/LFE dependencies.

## Provenance and historical result

- [Library implementation guide](../../artifacts/design/xrepl-protocol-impl-guide.md), original lines 81–293.
- [Session progress](../../artifacts/implementation/SESSION_PROGRESS.md), original lines 11–20: `Phase 0: Foundation Updates` reports completion.
- [Implementation analysis](../../artifacts/implementation/IMPLEMENTATION_ANALYSIS.md) maps the operation inventory; its production-ready verdict is historical assertion.
- [Unified specification](../../artifacts/design/xrepl-unified-spec.md) defines the payloads and operation aliases.

Historical module names predate the `xrepl-ptcl-*` rename; use the source paths below. No historical per-slice ledger, preserved issued prompt, close report or independent acceptance record was found in the inspected local/remote branches. The session report contains useful category-level progress; it is not a formal slice close. Future evidence belongs in this slice's `artifacts/` directory. The cross-category originals remain at project scale to avoid duplicating or rewriting them.

## Verification and exit criteria

Before executing follow-up work, inspect the exact current source and tests against every listed operation and the guide's full per-module checklist (original lines 2518–2539). Check request and response construction with minimal and optional fields, binary keys, field and operation aliases, parsing, positive and negative validation, missing/invalid fields, and MessagePack round trips. Confirm function/module documentation and examples. Preserve useful existing tests; a passing suite alone does not establish spec conformance.

From the implementation checkout, the existing CI runs `rebar3 compile`, `rebar3 as test compile`, and `rebar3 as test lfe ltest -tunit` (with system/integration categories on newer OTP). Record commands, outputs, revision and operation denominator when actually executed. These commands were inspected, not run as part of this documentation migration. See the project plan for the unresolved historical command/coverage differences.

The sibling [ledger](ledger.md) must be dispositioned against current evidence before acceptance. Self-checks stay attested; existing independent/Operator gates are not discharged by this migration. No `cc-prompt.md`, verification-role record or closing report is fabricated for the imported history.

## Assignment history

2026-10-17: reconstructed from existing records for planning migration only. Current implementation assignment: none. Next-action owner: Operator with the selected contributor, when protocol follow-up is requested.

## Version History

- v1.0 — 2026-10-17: import historical scope and retain acceptance uncertainty.
