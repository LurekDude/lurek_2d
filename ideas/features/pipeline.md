# pipeline — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/pipeline.md`
**Files**: DAG workflow orchestrator

## Purpose

General-purpose DAG (Directed Acyclic Graph) task pipeline: define named stages with dependencies, execute them in topological order, passing data between stages via a shared context map.

## Current Feature Summary

- `luna.pipeline.new(name?)` — create a new pipeline
- `pipeline:addStage(name, fn, opts)` — add a stage with dependencies
- `pipeline:run(context?)` — execute stages in dependency order
- `pipeline:getResult(stageName)` — get stage output
- `pipeline:getOrder()` — get planned execution order
- Kahn's algorithm for topological sort
- Cycle detection with descriptive errors
- Each stage receives and returns a context table
- Stage error handling: stop-on-first-error
- Optional stage metadata (description, tags)

## Feature Gaps

1. **No parallel execution**: All stages run sequentially even when independent stages could run in parallel.
2. **No async stages**: Can't have stages that wait for I/O or timers. All stages are synchronous Lua functions.
3. **No pipeline persistence**: Can't save/load pipeline definitions. Must rebuild programmatically each time.
4. **No visual representation**: No way to visualize the DAG (even as text/ASCII art).
5. **No conditional stages**: Can't skip stages based on runtime conditions.
6. **No stage retry**: Failed stages can't be retried.
7. **No pipeline composition**: Can't nest pipelines or merge two pipelines.
8. **No progress callbacks**: No way to track execution progress.

## Structural Issues

- **Is this a game engine feature?**: This is the most debatable module. DAG orchestration is typically a build system or data pipeline concept. Most game developers will never use a DAG workflow. However:
  - Asset processing pipelines (load → transform → cache)
  - AI behavior sequences (gather → evaluate → execute)
  - Game initialization (load assets → init systems → start)
  - Mod loading (sort → validate → load → hook)
  These are valid game use cases, but they're niche.
- **Overlap with AI behavior trees**: Behavior trees in the AI module are also DAG-like execution structures. Pipeline is a more generic version.
- **Could be a Tier 3 Lunasome library**: The pipeline module has no Rust dependencies beyond the standard library. It could be implemented entirely in Lua as a pure library.
- **Low usage probability**: Of all 30+ modules, this is the least likely to be used by a typical game developer.

## Suggestions

1. **Consider moving to Tier 3** (Lunasome library): No engine internals needed. Implement in pure Lua in `library/pipeline/`. This reduces engine surface area.
2. **Add conditional stages**: `pipeline:addStage(name, fn, {when = function(ctx) return ctx.debug end})` — skip stages based on context.
3. **Add progress callbacks**: `pipeline:onProgress(function(stage, index, total) end)` — track execution.
4. **Add pipeline visualization**: `pipeline:toAscii()` — render DAG as ASCII art for debugging.
5. **Document use cases clearly**: Provide concrete examples: asset pipeline, mod loading order, game initialization. Without examples, users won't know why this module exists.
6. **If keeping as Tier 2**: Add parallel execution support via `luna.thread` workers for independent stages. This would be the strongest justification for keeping it in Rust.

## Competitor Comparison

No competitor 2D Lua engine has a built-in pipeline orchestrator. This is unique to Luna2D, but its uniqueness may indicate it doesn't belong in a game engine.

| Feature | Luna2D | Love2D | Solar2D | Build tools |
|---|---|---|---|---|
| DAG scheduling | ✅ | ❌ | ❌ | ✅ (Make, Gulp) |
| Dependency resolution | ✅ | N/A | N/A | ✅ |
| Cycle detection | ✅ | N/A | N/A | ✅ |
| Parallel execution | ❌ | N/A | N/A | ✅ |
| Persistence | ❌ | N/A | N/A | ✅ (file-based) |

## Priority

**LOW** — The module works for what it does. The strategic question is whether it should remain a Rust engine module or become a Lunasome library. Recommend moving to Tier 3 unless parallel execution (requiring Rust threads) is added.
