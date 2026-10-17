# xREPL Protocol

Planning artifacts live on orphan branch `planning`, worktree
`.worktrees/planning`, under `project01-mvp`. Start with that worktree's
`README.md`, `project01-mvp/project-plan.md` and `project01-mvp/ledger.md`.
Source, tests, configuration and user documentation remain in this checkout.

Use canonical `project-plan.md`, `arc-plan.md`, `slice-plan.md` and sibling
`ledger.md` records at each scale. Supporting outputs from future slices
belong in the owning slice's `artifacts/` directory. Imported cross-category
design/progress records and the relocation manifest are project-scoped
artifacts on `planning`; preserve their original contents and provenance.

The Operator selected the One-Contributor Workflow and Expedited Mode for the
2026-10-17 planning migration, including commit and push. This is scoped to
that migration; it does not assign follow-up implementation or waive existing
acceptance gates. Self-checks are attested, not independent acceptance. The
reconstructed category slices retain open acceptance rows.

This repository implements protocol messages and serialization. The archived
`xrepl-protocol-impl-master-plan.md` plans server handlers in `xrepl/xrepl`;
do not treat its filename as authority to implement server behavior here.

The user calls this assistant **Sofie** (she/her).
