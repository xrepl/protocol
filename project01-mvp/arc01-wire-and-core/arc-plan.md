# Wire encoding and core protocol messages

- Project: `project01-mvp`
- Status: historical implementation candidates; acceptance open
- Source baseline: `0bfa6fd727da06338d064c7651de9b984bfabc23`

## Capability and delivery

Wire encoding and core protocol messages, exposed by the protocol library's public `src/` modules with corresponding `test/` suites. Each category carries its own construction, parsing, validation, aliases, round-trip tests and documentation. Server behavior is outside this library arc.

## Dependencies

No prior arc; provides codec/types and the first core request/response workflows.

## Reconstructed slice breakdown

These units organize scope already present in the historical guide and session report. They do not claim the work was executed as these slices. Ordering is a wayfinder; dependency statements govern execution. No implementation work is assigned by this migration.

| Slice | Capability | Operation count | Disposition |
|---|---|---|---|
| [slice01-wire-foundation](slice01-wire-foundation/slice-plan.md) | Wire encoding and shared types | codec/types | carryover; acceptance open |
| [slice02-evaluation](slice02-evaluation/slice-plan.md) | Evaluation messages | 7 | carryover; acceptance open |
| [slice03-sessions](slice03-sessions/slice-plan.md) | Session messages | 7 | carryover; acceptance open |
| [slice04-system](slice04-system/slice-plan.md) | System and introspection messages | 6 | carryover; acceptance open |

## Composition and remaining findings

The sibling [ledger](ledger.md) retains child acceptance and cross-category composition as open. Verify common key/alias behavior and encode/decode/parse workflows across every child on a pinned library revision. Historical passing test counts do not prove composition. Carry spec ambiguities and source-name drift to the [project plan](../project-plan.md); scope changes belong to the Operator.

## Version History

- v1.0 — 2026-10-17: reconstructed from library implementation categories; no historical closure manufactured.
