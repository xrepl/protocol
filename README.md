# xREPL Protocol planning

This orphan `planning` branch contains planning and evidence for [project01-mvp](project01-mvp/project-plan.md). Source and user documentation remain on `main`.

Read the [project plan](project01-mvp/project-plan.md), [project ledger](project01-mvp/ledger.md) and [migration record](project01-mvp/artifacts/migration.md). The plan maps the historical library work into four arcs and fourteen slices (one composition slice has no arc wrapper). Imported implementation claims remain separate from acceptance.

Verify the migration from this worktree:

```sh
python3 project01-mvp/artifacts/verify-migration.py --source ../..
```

The verifier checks exact archived bytes, canonical records and links, 83-operation ownership, orphan ancestry, and preservation/removal at the source checkout. It does not execute or accept protocol functionality.
