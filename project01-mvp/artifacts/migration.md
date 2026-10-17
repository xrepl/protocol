# Protocol planning migration — 2026-10-17

## Authority and result

The Operator requested the standard planning branch/worktree, a single `project01-mvp`, project/arc/slice organization where appropriate, preservation of the two progress/analysis reports, inspection of `spec-impl`, and one-contributor Expedited Mode with commit/push. Sofie performed the migration and self-checks in this chat. No additional contributor or independent acceptance is claimed.

The resulting orphan `planning` branch lives at `.worktrees/planning`. Its project plan provides four capability arcs and fourteen reconstructed slices: shared codec/types, twelve operation categories, and a direct project-level composition/release slice. That last single-slice body omits an arc wrapper under the canonical sizing rule. Each owning scale has a plan and acceptance ledger. Existing library category plans/progress justify this reconstruction; the directory names are new and are not asserted to be historical execution branches.

## Exact relocation and provenance

[migration-manifest.json](migration-manifest.json) records all nine source/destination paths, SHA-256 hashes, byte and line counts, tracked/untracked status, and the source commit where one exists. All originals are preserved byte-for-byte. The source branch removes the old documents and points to planning; it retains user documentation, source, tests, CI, configuration and license. The original tracked guide remains recoverable in main/spec-impl Git history. Planning deliberately starts without implementation ancestry; this is a snapshot relocation with pinned provenance, not a rewrite or claim to have copied the historical commit graph.

| Original | New home relative to the project | Purpose |
|---|---|---|
| `docs/design/xrepl-unified-spec.md` | [artifacts/design/xrepl-unified-spec.md](design/xrepl-unified-spec.md) | Complete protocol reference, including appendices and runtime context. |
| `docs/design/xrepl-protocol-impl-guide.md` | [artifacts/design/xrepl-protocol-impl-guide.md](design/xrepl-protocol-impl-guide.md) | Library requirements, category recipes, checklist and success criteria. |
| `docs/design/xrepl-protocol-extraction.md` | [artifacts/design/xrepl-protocol-extraction.md](design/xrepl-protocol-extraction.md) | Library extraction and external consumer integration obligations. |
| `docs/design/xrepl-protocol-impl-master-plan.md` | [artifacts/design/xrepl-protocol-impl-master-plan.md](design/xrepl-protocol-impl-master-plan.md) | Related server-handler roadmap; explicitly not the protocol library roadmap. |
| `SESSION_PROGRESS.md` | [artifacts/implementation/SESSION_PROGRESS.md](implementation/SESSION_PROGRESS.md) | Historical category progress and test-count claims. |
| `IMPLEMENTATION_ANALYSIS.md` | [artifacts/implementation/IMPLEMENTATION_ANALYSIS.md](implementation/IMPLEMENTATION_ANALYSIS.md) | Historical 83-operation comparison and production-readiness assertion. |
| `PR_MSG.md` | [artifacts/implementation/PR_MSG.md](implementation/PR_MSG.md) | Related implementation PR draft, retained as context. |
| `spec-func-sigs.lfe` | [artifacts/implementation/spec-func-sigs.lfe](implementation/spec-func-sigs.lfe) | Supporting API signature inventory, not executable source. |
| `spec-func-sigs-clean.lfe` | [artifacts/implementation/spec-func-sigs-clean.lfe](implementation/spec-func-sigs-clean.lfe) | Companion signature inventory, retained without deduplication. |

Only the library implementation guide was tracked at intake. The other eight files were untracked and absent from the inspected branch histories. They now gain durable planning history. Project-level artifact placement is intentional: these original records span multiple categories and cannot honestly be assigned to one historical slice. Future slice-produced evidence belongs under that slice's `artifacts/`.

Original prose, module names, dates, paths, timelines, code blocks and completion claims remain unchanged inside the archives. The relative link between the session report and analysis still resolves; obsolete absolute source paths and historical code/example references are evidence, not current navigation. Use this mapping and the slice plans for current navigation. The migration verifier checks authored navigation separately from immutable historical text.

## Branch evidence

A normal fetch first failed with sandbox DNS resolution (`Could not resolve hostname github.com: -65563`). The same `git fetch origin` succeeded with authorized host/network access, adding tags `0.1.0` and `0.2.0` and leaving both branch tips unchanged.

- Source `main` / fetched `origin/main`: `0bfa6fd727da06338d064c7651de9b984bfabc23`.
- `spec-impl` / fetched `origin/spec-impl`: `c2ef69be064f74633bff12c00814ebf445efdd1c`.
- `git rev-list --left-right --count main...spec-impl`: `1 4`.
- `git merge-base --is-ancestor spec-impl main`: exit 1.
- `git diff --stat main spec-impl`: empty; full trees are identical.
- Both pinned trees: `b88461be35411626bb97d6368a392fa1841b86f7`.
- `git log -1 --format=full main` identifies “Complete xREPL Protocol Implementation (#1)” and includes the implementation plus both renames and README update from the four feature commits.

Conclusion: `spec-impl` was squash-integrated into main; it is not merged by ancestry, but contributes no missing file/content at the inspected tips. Keep the branch intact. No extra project or branch recovery is needed.

## Evidence disposition and limits

The [project plan](../project-plan.md) retains historical completion claims, scope distinctions and unresolved acceptance issues. The guide and session record support category-level reconstruction; they do not establish historical slice acceptance. All imported rows remain open, with their actual evidence strength. No prompts, close reports, historical dates or independent verdicts are backfilled.

The master plan's explicit server-handler goal differs from the library guide. Its placeholder dates/counts and cross-repo tasks are preserved as related context. The extraction's consumer obligations remain visible in final composition rather than silently disappearing with that distinction.

Routine inspection also found a response-status contract discrepancy (array in the unified spec versus binary in the guide/current eval test). It is recorded for future Operator disposition. No implementation or test is changed to resolve it in a planning migration.

## Repeatable self-check

From `.worktrees/planning`:

```sh
python3 project01-mvp/artifacts/verify-migration.py --source ../..
git diff --check -- . ':(exclude)project01-mvp/artifacts/design/**' ':(exclude)project01-mvp/artifacts/implementation/**'
```

The verifier checks exact archive hashes and tracked-blob provenance, unchanged source/test/config/CI/license files, the pinned identical branch trees, orphan planning ancestry, project/arc/slice document coverage, exact 1–83 operation ownership, source/test path mappings, authored local links, and that every carryover ledger row remains open. Its optional `--allow-source-originals` mode is a pre-removal check only; final validation must omit that flag.

Source diff review is limited to removing the one tracked planning document, adding planning instructions/navigation and ignoring `.worktrees/`. Runtime tests and coverage are not run: source/tests/config/CI remain byte-identical, and this migration makes no fresh runtime or coverage claim. This is attested migration validation, not implementation acceptance. Commit and push receipts are available from each branch's Git log and the task completion report.

## Recorded migration validation

The pre-removal self-check passed for all 9 exact archives, 33 unchanged implementation/CI/config/license files, 4 arcs, 14 slices, exactly 83 uniquely owned operations, and 205 authored local links. All 87 imported project/arc/slice acceptance rows remain open. Final source-removal and committed orphan-ancestry checks use the same verifier without its pre-removal flag. These counts describe migration structure, not runtime coverage.

The initial unfiltered staged `git diff --check` returned exit 2 for inherited trailing whitespace in the exact source archives. The full output and disposition are retained in [migration-validation.json](migration-validation.json). Authored-file whitespace validation passed. Archive whitespace remains unchanged to preserve source bytes.
