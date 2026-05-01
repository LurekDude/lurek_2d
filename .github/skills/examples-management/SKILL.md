---
name: examples-management
description: "Load this skill when adding or reviewing content/examples/ or content/games/ files, README files, or conf.lua examples. Skip it for engine Rust, tests, docs/, or CAG work."
---
# examples-management

## Mission
- Own example and demo content structure, clarity, and coverage value.

## When To Load
- Add or update content/examples/.
- Review content/games/ example content.
- Check example README or conf files.
- Improve API coverage through examples.

## When To Skip
- Engine Rust code.
- Tests.
- docs/ content.
- CAG files.

## Domain Knowledge
- One example, one concept. `content/examples/<module>.lua` is a runnable `--@api-stub:` file that demonstrates exactly one API call or pattern in realistic game context. Look at `content/examples/ai.lua` or `content/examples/physics.lua` for the established format: each block opens with `do`, includes a comment explaining the usage, and closes with `end`.
- The `--@api-stub: lurek.<namespace>.<function>` comment above each block is the signal that `tools/audit/example_coverage.py` uses to measure coverage. Keep that tag on the line immediately above the `do` block or coverage counting breaks.
- How to find missing coverage: run `python tools/audit/example_coverage.py` and compare its output against `docs/api/lurek.lua`. The audit tool produces a list of API names with no matching `--@api-stub:` tag. Prioritise functions that game authors call in their first session (constructors, common callbacks, core configuration) over edge-case functions.
- Minimal setup is a hard rule. If an example needs a physics world, create exactly one `lurek.physics.newWorld(0, 9.81)`. If it needs a sprite, load one asset. Never import a library module, never build helper utilities, never share state between `do` blocks in the same file. If the example is becoming too complex, it wants to be a demo in `content/games/`.
- How to add a new example file: create `content/examples/<module>.lua`, run `cargo test --test examples_load_test`, and confirm the file is picked up and loads without error. If the module has a guard (e.g., `if not lurek.html then return end`), add it at the top of the file so headless CI does not fail.
- Sync rules: if an example changes a function name or parameter order because the API changed, update the matching entry in `docs/api/lurek.lua` (after regenerating via `python tools/gen_all_docs.py`) and the affected `docs/specs/<module>.md` in the same commit. The example is living documentation; it must stay truthful.
- Coverage gap workflow: audit → pick one uncovered function → write the `do` block → confirm the stub tag → run load test → commit with sync. Never inflate count by writing stub tags without runnable code.
## Companion File Index
- None.

## References
- content/examples/
- content/games/
- tools/audit/example_coverage.py
- logs/reports/coverage_gaps.md
