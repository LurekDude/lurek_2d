# IDEA — `src/runtime/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.
>
> See [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md) for filling instructions.

---

## 1. Header

- **Module**: `runtime`
- **Owner module path**: `src/runtime/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~3170 · **Public Lua surface**: `lurek.platform.setLogLevel` — 1 fn / 0 userdata
- **Inbound non-`lua_api` callers**: every module in the engine (dependency root)
- **Heavy dependencies**: `mlua` (config loading), `slotmap`, `thiserror`, `toml`, `log`

## 2. Mission Summary

The `runtime` module is the dependency tree's root — every other Rust module imports from it. It provides `SharedState` (the central mutable context wrapped in `Rc<RefCell<>>`), `Config` (loaded from `conf.toml` or `conf.lua`), `EngineError` (flat error enum with stable codes), typed resource keys (SlotMap newtype wrappers), and the structured log message catalog. It serves **EngDev** and indirectly every other persona. It is NOT a Lua API surface and NOT a game-facing module.

## 3. Existing Strengths

- **Comprehensive error model**: `EngineError` covers all subsystems with stable four-digit codes, categories, and recovery hints — well-structured for the error screen.
- **Typed resource keys**: SlotMap newtype keys (`TextureKey`, `FontKey`, etc.) prevent cross-pool access bugs at compile time.
- **Dual config loading**: `conf.toml` + `conf.lua` fallback with nested merge-on-top-of-defaults logic ensures forward and backward compatibility.
- **Log message catalog**: Stable `L001`-style IDs with TOML-backed human-readable text; `log_msg!` macro keeps log calls structured and greppable.
- **LRU eviction**: `SharedState::evict_lru_resources()` implements texture memory budgeting with frame-based last-used tracking.
- **Module dependency gating**: `ModulesConfig::validate_and_fix()` auto-disables modules whose dependencies are off (e.g. particle requires graphics).

## 4. Gap List

1. ~~**[P1][GAP]** `Filesystem` category missing in `ErrorCategory` — `FileSystemError` and `IoError` share `System` category, losing granularity for user-facing diagnostics.~~ ✅ **DONE** — Added `ErrorCategory::Filesystem`; `EngineError::FileSystemError` now maps to `ErrorCategory::Filesystem` with `as_str() = "filesystem"`.
   - ~~Why: error screen could show filesystem-specific hints vs generic system errors.~~
2. **[P2][GAP]** No `SharedState` size tracking beyond textures — fonts, canvases, shaders, meshes, particle systems have no memory accounting.
   - Why: LRU eviction only covers textures; large font atlases or canvas pools can still exceed GPU memory.
3. ~~**[P2][GAP]** `ModulesConfig` has no validation for `animation` requiring `graphics`, `tween` not requiring anything, etc. — only 6 of 30+ flags are validated.~~ ✅ **DONE** — Added validation rules for `animation`, `tilemap`, `raycaster`, `camera`, `globe` (all require `graphics`) and `spine` (requires `animation`); docstring updated.
   - ~~Why: Disabling `graphics` but leaving `animation` on causes silent failures.~~

## 5. Feature Ideas

1. **[P2][FEAT]** `Config hot-reload via file watcher` — Watch `conf.toml` at runtime and apply mutable settings (title, FPS cap, log level) without restart. Immutable settings (backend, window size) would be skipped.
   - Rationale: Accelerates game author iteration (GameDev). Already have `filesystem::FileWatcher`.
   - Effort: M · Risk: med.
   - Competitor inspiration: `[LÖVE: conf.lua is read once at boot — no live reload, but Defold reloads project settings live]`, `[Godot: project.godot settings reloaded on editor focus]`.

2. **[P2][FEAT]** `Extended resource budget` — Track memory for fonts, canvases, and shaders alongside textures. Evict by combined budget.
   - Rationale: Prevents GPU OOM on integrated GPUs (Player on Intel UHD / AMD APU).
   - Effort: M · Risk: low.

3. ~~**[P3][FEAT]** `Serialisable error snapshots` — Serialize `ErrorInfo` (code + category + message + hint) to JSON for crash reporting or test assertion.~~ ✅ **DONE** — Added `ErrorSnapshot` struct + `EngineError::snapshot()` + `lurek.platform.errorSnapshot(msg)` Lua binding.
   - ~~Rationale: Enables automated game testing (GameTest, EngTest) to assert on specific error codes.~~
   - ~~Effort: S · Risk: low.~~
   - ~~Competitor inspiration: `[Solar2D: runtime errors include errorType and errorMessage fields in JSON event objects]`.~~

## 6. Performance / Reliability / Quality Ideas

- **[P2][PERF]** `Reduce per-frame allocs in evict_lru_resources` — The candidates `Vec` is allocated every frame when budget is set. Pre-allocate or use a sorted index.
  - Hot path: `shared_state.rs:evict_lru_resources`.
  - Verification: criterion bench with 500+ loaded textures.
- **[P2][QUAL]** `SharedState is too large` — 60+ fields make it hard to reason about borrow scope. Consider splitting into sub-states (RenderState, InputState, AudioState) behind interior references.
  - File: `shared_state.rs`.
  - Reason: Reduces borrow contention and improves readability.
- **[P3][REL]** `get_message unsafe lifetime extension` — The `get_message()` function uses `unsafe` to extend `&str` lifetime from `&'static MessageCatalog`. Add a `// SAFETY:` comment and consider returning `Cow<'static, str>` instead.
  - File: `messages.rs:get_message`.

## 7. Test Coverage Gaps

- **[P1][TEST-RUST]** Add Rust unit tests for `EngineError` code/category/hint mapping — DONE in this session.
- **[P1][TEST-RUST]** Add Rust unit tests for `log_messages` ID format and `get_log_level` — DONE in this session.
- **[P2][TEST-RUST]** Add Rust unit tests for `Config::load_from_conf_toml` TOML merge logic (non-Lua-reachable internal).
- ~~**[P3][TEST-LUA]** Add Lua BDD tests for `lurek.platform.setLogLevel` / `getLogLevel`.~~ ✅ **DONE** — Tests present in `tests/lua/unit/test_system.lua`.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): timer::Clock — SharedState owns a Clock for frame timing; timer module also exports Clock. Verify single source of truth.
TODO(dedup): event::EventQueue — SharedState owns EventQueue directly; consider if event module should provide a factory.
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): config_inspector — Lua helper to dump current Config as a table for debugging — citation: none (game author workflow gap).
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): CORE-KEEP — runtime is the dependency root; every module imports from it. Cannot be extracted.
```

- **Extraction blockers**: Every module in the engine depends on `SharedState`, `EngineError`, `Config`, resource keys.
- **Heavy dep impact if extracted**: n/a.
- **Lua surface stability**: stable (only `setLogLevel`/`getLogLevel`).
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/runtime.md](../../docs/specs/runtime.md)
- Lua API reference: [docs/API/lua-api.md](../../docs/API/lua-api.md)
- Philosophy constraints touched: `B-01` (LuaJIT primary), `B-05` (TOML for config)
- Plugin doc tier table: [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
- Session plan: [PLAN.md](../../work/src-module-review-20260418/reports/PLAN.md)
# IDEA.md — `runtime` module

> Migrated from `ideas/features/engine.md` (runtime / infrastructure sections).
> Status checked against `src/runtime/` (config.rs, resource_keys.rs, shared_state.rs, etc.).
> Lua namespace: N/A — `runtime` is internal infrastructure; no direct Lua exposure.

---

## Features

### ✅ DONE — Streaming Resource Loading (Background Thread)
**Source**: general performance patterns

`src/filesystem/async_loader.rs` implements `AsyncLoader` — a background thread pool
that reads files off the main thread and returns `LoadHandle` futures. The Lua API
exposes `lurek.filesystem.loadAsync(path)` with `isDone()`, `getBytes()`, and `getError()`
methods for polling from the game loop without blocking the main thread.

---

### ✅ DONE — Resource Eviction Policy
**Source**: general resource management

`SharedState` now tracks a configurable `resource_budget` (bytes) and an LRU access-time
table for textures and audio buffers. When total resident size exceeds the budget,
the least-recently-used resources are evicted. Eviction is triggered automatically at
frame start and can also be forced via the internal `evict_lru_resources()` helper.

---

### 🤔 CONSIDER — Config Hot Reload
**Source**: features/engine.md — Feature Gaps #1

With `src/filesystem/watcher.rs` (polling `FileWatcher`) now available, reloading
`conf.toml` at runtime for adjustable settings (window title, frame budget, active
modules) is feasible without a full restart. Medium effort — needs a diff-and-apply
strategy that avoids reinitialising immutable settings (window size, backend selection).
