# Library composition and release readiness

- Project: `project01-mvp`
- Status: planned carryover; no implementation assignment issued
- Workflow: one contributor
- Source baseline: `0bfa6fd727da06338d064c7651de9b984bfabc23`

## Goal and scope

Establish whether the complete protocol library is usable as a packaged dependency and whether the historical definition of done is met. This single slice sits directly under the project, following the canonical rule to omit an arc wrapper for a one-slice body of work.

Consume the bounded accepted codec, shared types and 12 operation-category APIs from all four arcs. Delivery homes are the implementation repository's `README.md`, `rebar.config`, `src/xrepl_protocol.app.src`, `src/`, `test/` and shipped examples when needed. The original guide's optional aggregator remains optional.

Retain the [guide's Final Integration and Success Criteria](../artifacts/design/xrepl-protocol-impl-guide.md) (original lines 2668–2696): app module inclusion, cross-operation integration tests, operation documentation, examples, MessagePack profiling and throughput benchmarks, all 83 operations, binary keys, aliases, >90% coverage, passing tests, style, docstrings and a warning-free build. No performance threshold is invented during migration.

The [extraction record](../artifacts/design/xrepl-protocol-extraction.md) (original lines 928–940) also requires the consumer to compile/test with the dependency and use protocol builders instead of ad-hoc maps, including client requests. Track the protocol library's compatibility evidence here; implementing server/editor changes requires work in the respective consumer repository and is not assigned by this migration. Coordinate that evidence with the Operator rather than treating a library test as proof of consumer behavior.

## Verification and exit criteria

Walk the [ledger](ledger.md) on an identified revision. Compare all arc results, run the appropriate repository build/test and coverage commands, inspect the packaged application and usable documentation/examples, record benchmark conditions and results, and obtain consumer-side integration evidence for the extraction criteria. The historical 776-test claim is not a measured coverage percentage. The current CI's `--min_coverage=0` does not establish the guide's >90% requirement.

Resolve the spec/status representation discrepancy documented in the [project plan](../project-plan.md) before claiming full conformance. Any scope or acceptance change needs an explicit Operator decision; keeping the server-handler master plan as related context does not waive external extraction obligations.

Artifacts: this slice's `artifacts/` directory when work is actually performed. No close documents or synthetic CC prompt are created. Next-action owner: Operator with the selected contributor; select a concrete follow-up before execution.

## Assignment history

2026-10-17: imported outstanding composition/release scope; current assignment: none.

## Version History

- v1.0 — 2026-10-17: preserve integration, documentation, performance and release obligations without declaring acceptance.
