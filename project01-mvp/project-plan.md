---
project: project01-mvp
status: active
depends-on: []
blocks: []
related:
  - https://github.com/xrepl/xrepl
  - https://github.com/xrepl/protocol/pull/1
---

# xREPL Protocol MVP

## Purpose and boundaries

Deliver the reusable LFE wire-protocol library: framed MessagePack serialization, shared message types, request/response builders, parsers, validation and client-compatible aliases for all 83 operations in the [unified specification](artifacts/design/xrepl-unified-spec.md). Public source, user documentation, tests and packages remain on the implementation branch.

This library represents evaluation, debugging, testing and other requests; it does not execute the server operations itself. The [historical extraction design](artifacts/design/xrepl-protocol-extraction.md) explains the separation. The [library implementation guide](artifacts/design/xrepl-protocol-impl-guide.md) supplies the library contract and historical category breakdown.

**Scope warning:** [xrepl-protocol-impl-master-plan.md](artifacts/design/xrepl-protocol-impl-master-plan.md), despite its filename, explicitly plans server handlers/dispatchers in `xrepl/xrepl` and calls this protocol library an existing external dependency (original lines 40–58, 215–254). Its 19 chunks are preserved as related server planning, not converted into this library's slices. No second project is created here. Its unresolved counts, placeholder date and timelines are historical text, not current commitments. Extraction's consumer integration obligations remain visible in the composition slice.

## Definition of done

The [project ledger](ledger.md) and each child ledger retain the library guide's full success criteria: all 83 operation contracts, binary keys, bidirectional field and operation aliases, positive/negative validation, lossless round trips, >90% test coverage, passing tests, warning-free builds, LFE style, module/function documentation and examples. Final integration includes app module inventory, cross-operation workflows, a usable dependency/package, performance profiling/benchmarks and evidence for the extraction's consumer integration criteria. The optional aggregator stays optional. Spec sections about transports, authentication, security, error recovery and IDE behavior constrain wire compatibility where applicable; their runtime enforcement belongs to consuming applications.

## Arc roadmap and dependencies

These arcs group the library guide and recorded category progress. Slice IDs are reconstructed on 2026-10-17; they do not establish historical execution units. Every category retains its original operation inventory and per-module checklist. First usable increment: framed codec/types plus evaluation, session and introspection messages usable through the public library API (Arc01).

| Unit | Capability | Required input | Status |
|---|---|---|---|
| [arc01-wire-and-core](arc01-wire-and-core/arc-plan.md) | Wire encoding and core protocol messages | codec/types first; categories consume that bounded contract | carryover; acceptance open |
| [arc02-editor-services](arc02-editor-services/arc-plan.md) | Editor intelligence, navigation and documentation messages | codec/types first; categories consume that bounded contract | carryover; acceptance open |
| [arc03-development-tools](arc03-development-tools/arc-plan.md) | Debugging, testing, refactoring and compilation messages | codec/types first; categories consume that bounded contract | carryover; acceptance open |
| [arc04-platform-operations](arc04-platform-operations/arc-plan.md) | BEAM and advanced protocol messages | codec/types first; categories consume that bounded contract | carryover; acceptance open |
| [slice01-composition-and-release](slice01-composition-and-release/slice-plan.md) | Whole-library composition, packaging, documentation, benchmarks and consumer integration evidence | Accepted bounded results from all four arcs, plus consumer receipts | planned carryover; acceptance open |

All arcs deliver to the implementation repository's `src/` and `test/`, together with affected public documentation/examples. The last body of work is one slice, so the canonical sizing rule omits an extra arc wrapper. The [manifest](artifacts/migration-manifest.json) maps every operation 1–83 to exactly one category slice.

## Current status and evidence limits

Source baseline: `0bfa6fd727da06338d064c7651de9b984bfabc23`. The [session record](artifacts/implementation/SESSION_PROGRESS.md), [implementation analysis](artifacts/implementation/IMPLEMENTATION_ANALYSIS.md), [PR draft](artifacts/implementation/PR_MSG.md) and merged commit claim all 83 operations and 776 passing tests across 12 modules. They are retained as historical assertions/attestations. No raw historical run receipt or formal slice close/independent verification record was found in the inspected branches/files. Test counts differ across passages in the historical reports; those passages are preserved.

This migration establishes planning structure and provenance. It does not freshly establish runtime behavior, numerical coverage or production readiness. All imported acceptance rows remain open; no arc, slice or project is closed by relabeling old claims. There is no active implementation assignment and no new independent-review requirement imposed on the migration itself. No CC prompts, closing reports or fictional independent verdicts are created for reconstructed history.

`spec-impl` is fully integrated in content through squash commit `0bfa6fd` (PR #1). Its tip `c2ef69be064f74633bff12c00814ebf445efdd1c` is not an ancestor of `main`, but both tips have exactly tree `b88461be35411626bb97d6368a392fa1841b86f7`. No unique files/content need recovery; retain the branch and its original commits. Fetch succeeded after a sandbox DNS failure; the retried fetch confirmed remote tips. See [migration record](artifacts/migration.md).

## Open findings and next-action ownership

1. **Acceptance evidence:** category completion claims are useful history; every category and composition criterion still needs evidence on a pinned source revision before formal acceptance. Owner: Operator with the selected contributor/reviewer when follow-up is commissioned.
2. **Status representation:** the unified spec's core response defines `status: string[]` (original lines 27–35), while the library guide's response pattern and current eval tests use a single binary (`#"done"`). This is an observed contract discrepancy, not a resolved design decision. Owner: Operator with the protocol maintainer; preserve both sources and decide the intended compatibility contract before claiming full conformance.
3. **Coverage/commands:** the guide requires >90% coverage and names older test commands; historical reports name `rebar3 as test eunit`, while current CI uses LFE/ltest and sets coverage minimum to zero. Test counts and CI success do not discharge the >90% requirement. Owner: contributor executing the next requested follow-up; use actual current commands and record the denominator.
4. **Name drift:** originals use pre-rename module names. Reconstructed slice plans point to the current `xrepl-ptcl-*` source and test paths. Archived paths/links are historical evidence; use the manifest's relocation mapping.
5. **External extraction obligations:** consumer dependency/import/builder use and consumer compile/test evidence are not established here. Owner: Operator coordinating consumer-repository work; final composition keeps the obligation open. The server-handler master plan is related context, not a source-scope authorization.
6. **Optional enhancements:** additional operations, optimizations, extended docs and examples listed as optional in session progress remain suggestions. Required guide documentation/examples and performance checks retain their original acceptance obligations.

Next action: the Operator selects a concrete protocol follow-up if desired. This request authorizes migration, self-check, commit and push only; Expedited Mode does not start server implementation or automatically execute reconstructed backlog.

## Workflow, authority and artifact conventions

Operator instruction on 2026-10-17: one-contributor method, Expedited Mode, commit and push when finished. Sofie is the sole contributor for this migration (planning, execution and self-review); no delegated contexts or simulated CDC/CRC/CC handoffs. Self-checks are **attested**. Existing independent or Operator acceptance gates remain pending wherever required.

Planning branch: orphan `planning`; worktree: `.worktrees/planning`; project: `project01-mvp`. The Operator explicitly requested the standard layout and project name, providing the layout authorization. Source-side `AGENTS.md` and this branch's instructions record it for future sessions.

Imported cross-category design and progress records, including both specifically requested reports, live under project `artifacts/` with exact bytes and a manifest. This placement reflects their project-wide scope and the Operator's migration instruction. New slice-produced supporting evidence defaults to the owning slice's `artifacts/`. Canonical plans/ledgers and actual issued prompts/close documents live at their owning scale. For this one-contributor import, there are no `cdc-verification.md` or `crc-verification.md` records; create records only for work/review actually performed.

## Version History

- v1.0 — 2026-10-17: migrate existing protocol designs and progress into the standard orphan planning worktree; reconstruct four arcs and fourteen scope slices; preserve historical content and claims; distinguish the server-handler master plan; leave implementation acceptance open.
