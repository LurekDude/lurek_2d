# Luna2D Changelog

All notable changes to Luna2D are recorded here.

## Versioning scheme

```
MAJOR.MINOR.PATCH
```

| Segment | Increment when… |
|---|---|
| **MAJOR** | Breaking API changes — Lua scripts or engine configuration must be ported |
| **MINOR** | New backwards-compatible features — new `luna.*` APIs, new modules, new default configs |
| **PATCH** | Bug fixes, internal refactors, documentation and tooling changes that do not affect the public API |

Always update this file **in the same commit** as the change. Use the commit type as the section label.

---

## [0.6.12] — 2026-04-08

### Fixed
- **`src/lua_api/data_api.rs`** — removed prohibited `# Parameters` rustdoc section from `register()` (D-08 audit finding); removed `LuaDataView` struct definition and `impl LuaUserData` block (B-02/B-03 audit findings) — both now live in `src/data/dataview.rs`.
- **`src/lua_api/dataframe_api.rs`** — removed prohibited `# Parameters` section from `register()` (D-08 audit finding).
- **`src/lua_api/devtools_api.rs`** — removed prohibited `# Parameters` and `# Returns` sections from `register()` (D-08 audit finding).
- **`src/data/dataview.rs`** — added `LuaDataView` struct and `impl LuaUserData` (moved from `src/lua_api/data_api.rs`; domain now owns its own Lua userdata binding).
- **`src/data/mod.rs`** — exported `LuaDataView` from the domain module.
- **`src/data/AGENT.md`** — added missing `mod.rs` row to Source Files table (A-04 audit finding).
- **`src/debugbridge/AGENT.md`** — corrected stale `Rust Tests: —` to `tests/rust/unit/debugbridge_tests.rs` (A-02 audit finding); removed non-canonical `## Ownership Rule` section — detail moved to specs (A-06 audit finding).
- **`src/devtools/AGENT.md`** — removed non-canonical `## New Lua API (v0.5.x)` section — detail belongs in specs (A-06 audit finding).
- **`src/docs/AGENT.md`** — corrected stale `Rust Tests: —` to `tests/rust/unit/docs_tests.rs` (A-02 audit finding); removed non-canonical `## Key Lua API (additions)` section (A-06 audit finding).

### Added
- **`wiki/Data-API.md`** — new wiki page for `luna.data` (W-05 audit finding).
- **`wiki/Dataframe-API.md`** — new wiki page for `luna.dataframe` (W-05 audit finding).
- **`wiki/Debugbridge-API.md`** — new wiki page for `luna.debugbridge` (W-05 audit finding).
- **`wiki/Devtools-API.md`** — new wiki page for `luna.devtools` (W-05 audit finding).
- **`wiki/Docs-API.md`** — new wiki page for `luna.docs` (W-05 audit finding).

---

## [0.6.11] — 2026-04-08

### Fixed
- **`src/lua_api/animation_api.rs`** — `register()` docstring changed from stale `luna.tween` to correct `luna.animation`; removed prohibited `# Parameters` rustdoc section (D-06, D-08 audit findings).
- **`src/lua_api/compute_api.rs`** — module-level `//!` header and `register()` docstring updated from stale `luna.gpu` to correct `luna.compute`; removed prohibited `# Parameters` section from `register()` (D-06, D-08 audit findings).
- **`src/lib.rs`** — two stale `(luna.gpu)` references updated to `(luna.compute)` in crate-level docs (D-06 finding).
- **`src/compute/array.rs`** — four production-code `.unwrap()` calls in `get_f64()` and `get_i32()` replaced with `.expect("byte slice invariant: offset validated by flat_index")` (Q-04 audit finding).
- **`src/audio/AGENT.md`** — added missing `mod.rs` entry to Source Files table (A-04 audit finding).
- **`src/camera/AGENT.md`** — added missing `mod.rs` entry to Source Files table (A-04 audit finding).
- **`src/ai/AGENT.md`** — Rust Tests row updated from deprecated `tests/rust/game/ai_tests.rs` to canonical `tests/rust/unit/ai_tests.rs` (T-01 audit finding).
- **`tests/rust/unit/ai_tests.rs`** — ai integration tests migrated from `tests/rust/game/` to canonical `tests/rust/unit/` location (T-01 audit finding).
- **`Cargo.toml`** — `ai_tests` `[[test]]` entry moved to unit test section with updated path `tests/rust/unit/ai_tests.rs`.

### Added
- **`wiki/Compute-API.md`** — new wiki page for the `luna.compute` module with overview, full API reference table, dtype table, and a procedural terrain example (W-05 audit finding).

### Changed
- **`.github/prompts/audit-module.prompt.md`** — Fix Workflow section updated: the fix pass now runs automatically after every audit without requiring a separate user request; post-fix `cargo check` and final summary are now mandatory.

## [0.6.10] — 2026-04-08

### Changed
- **`src/math/tween.rs`** — removed deprecated blockquote from module doc; replaced with a clear positive description of the module's scope and how it differs from `luna.tween`.
- **`src/tween/state.rs`** — module doc cross-reference updated: now points to `src/tween/handle.rs` and `src/tween/engine.rs` instead of the old `lua_api` path.
- **`specs/tween.md`** — renamed "Lua Binding Types (src/lua_api/tween_api.rs)" section to "Domain Types (src/tween/)"; replaced stale `TweenApiState` description with current `TweenEngine`; updated UserData section headers to include correct source files; replaced "Cross-Module References" with an explicit "Separation of Duties" table covering `tween`, `animation`, `math::tween`, and `spine`.
- **`src/tween/AGENT.md`** — added "Separation from Related Modules" table explaining responsibilities of each animation-related module.
- **`examples/tween.lua`** — added sections 11–13 covering previously missing API: `luna.tween.getActiveCount()`, `LuaTween:getProgress()`, `LuaTweenSequence:cancel()` + `isActive()`, `LuaTweenParallel:add()` + `cancel()` + `isActive()`. All 13 API surface areas now covered.

## [0.6.9] — 2026-04-15

### Changed
- **`luna.tween` architectural refactor** — moved all business logic out of `src/lua_api/tween_api.rs` into proper domain modules, enforcing the Thin Wrapper Rule:
  - `src/tween/engine.rs` (new) — `TweenEngine`: active-pool management, `update()`, `cancel_all()`, `active_count()`.
  - `src/tween/handle.rs` (new) — `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`, `ParallelEntry` + all `impl LuaUserData` blocks.
  - `src/tween/mod.rs` — expanded with `pub mod engine`, `pub mod handle`, and public re-exports for all new types.
  - `src/lua_api/tween_api.rs` — reduced to ~200-line thin registration wrapper (`pub fn register()` only).
  - `src/math/tween.rs` — module doc updated with deprecation notice pointing to `luna.tween`.
  - `specs/tween.md` — Architecture diagram and Module Layout table updated to reflect new 4-layer structure.
  - `src/tween/AGENT.md` — Source file table updated with `handle.rs` and `engine.rs` entries.
- **CAG rule enforced** — Added mandatory **Thin Wrapper Rule** paragraph to `.github/copilot-instructions.md` under "Lua API Conventions".
- Public API unchanged — all `luna.tween.*` function names and signatures are identical.

## [0.6.8] — 2026-04-14

### Changed
- **`examples/` quality pass (part 2)** — stub sections in four high-complexity example files replaced with fully documented example code:
  - `math.lua` (stubs → 5 organised sections): BezierCurve introspection, Transform/Tween supplemental, easing standalone functions, geometry utilities (14 functions), and math wrappers.
  - `ai.lua` (13 class stubs → 13 documented sections): supplemental methods for AIWorld, Agent, BTNode, BehaviorTree, Blackboard, CommandQueue, GOAPPlanner, InfluenceMap, QLearner, Squad, StateMachine, SteeringManager, UtilityAI — all with context comments, realistic args, and use-case rationale.
  - `pathfinding.lua` (5 class stubs → 5 documented sections): AiFlowField introspection, FlowField query methods, NavGrid chunk info, PathGrid dynamic obstacles, UnitPathfinder cache control.
  - `graphics.lua` (9 thin class sections → 11 sections): Canvas, DrawLayer, Font, Image, ImageData, Mesh, NineSlice, Quad, Shader, Shape, SpriteBatch — each with type identity pattern, supplemental methods, and cross-reference notes.
  - Coverage maintained at **2539/2539 = 100%** throughout.

- **`examples/` quality pass (part 1)** — all 45 example files improved for readability and accuracy:
  - `gui.lua` fully rewritten (703 lines); all 37 GUI classes with real method arguments.
  - `audio.lua` Bus and Decoder sections rewritten with all 10 methods each; `newSoundData` added.
  - Removed redundant `-- X instance methods (variable: x)` header comments from 19 files.
  - `typeOf("name")` placeholder args corrected to actual class names in all files.
  - `type()` return comments updated with canonical class name strings.
  - ~40 `"value"` / `"default"` argument placeholders replaced with domain-appropriate strings across 9 files.
- **New tools** added in `tools/fix/`:
  - `fix_typeof_args.py` — uses API JSON to correct `typeOf("name")` stubs and `type()` comments.
  - `fix_type_stub_vars.py` — renames duplicated `class_name`/`is_X_type` locals to per-variable names.
  - `strip_instance_method_comments.py` — strips auto-generated `instance methods` header lines.
- Coverage metric: 2539 / 2539 = **100%** maintained throughout all edits.

---

## [0.6.7] — 2026-04-11

### Added
- **`luna.tween` — property tweening system** — new `src/tween/` Tier 1 module plus `src/lua_api/tween_api.rs` binding. Animate any Lua table field by name in real-time: `luna.tween.tween(duration, target, {field = end_value, ...}, easing)`. Supports multi-field tweens, sequences (`:tween()` / `:delay()` / `:callback()`), parallels (`:tween()` / `:add()`), repeat + yoyo, pause/resume, and `onComplete` / `onUpdate` / `onCancel` callbacks. Manual update model: call `luna.tween.update(dt)` from `luna.process(dt)`. Start values are captured lazily on the first update tick.
- **`luna.tween.sequence()`** — chain animation steps that execute one after another.
- **`luna.tween.parallel()`** — run multiple tweens simultaneously; fires `onComplete` when all children finish.
- **`luna.tween.delay(sec, fn?)`** — standalone timer convenience helper.
- **`luna.tween.registerEasing(name, fn)` / `luna.tween.getEasingNames()`** — custom Lua easing functions and introspection of all 23 built-in easing names.
- **`ModulesConfig.tween: bool`** — gating flag in `conf.lua` (`modules.tween`, default `true`).
- **`tests/rust/unit/tween_tests.rs`** — 14 Rust unit tests for `TweenState`, `resolve_easing`, `builtin_easing_names`.
- **`tests/lua/unit/test_tween.lua`** — ~50 Lua BDD tests covering all `luna.tween.*` API surface.
- **`examples/tween.lua`** — 10-section usage script demonstrating all API features.
- **`src/tween/AGENT.md`**, **`specs/tween.md`** — module agent reference and full specification.
- Fixed stale `//! \`luna.tween\`` header comment in `src/lua_api/animation_api.rs` (correctly `luna.animation`).
- Fixed stale comment in `src/lua_api/mod.rs` registration block (animation maps to `luna.animation`).

---

## [0.6.6] — 2026-04-10

### Added
- **`luna.log` configurable sinks** — new `src/log/sinks.rs` module with `SinkLevel`, `SinkKind` (File / Memory), `Sink`, and `SinkRegistry` types. All `luna.log.*` emit functions now accept an optional `tag` second argument (default `"Lua"`). New API: `addSink(cfg)→id`, `removeSink(id)→bool`, `clearSinks()`, `listSinks()→table`, `readMemory(id, drain?)→table?`, `flushFile(id)`. Sinks dispatch independently of `RUST_LOG` filtering.
- **`luna.docs.schema()`** — new `src/docs/schema.rs` with `Schema`, `FieldRule`, `FieldType`, `SchemaError`, `SchemaResult`. Game scripts can define typed field rules (required, min/max, minLen/maxLen, enum, strict mode) and call `schema:validate(data)`, `schema:check(data)`, `schema:assert(data)` for safe runtime data-validation.
- **`luna.docs.reflectLive(ns?)`** — walks the live `luna.*` Lua table and returns a structured `{ns → [{name, type}]}` map. Supports optional namespace filter argument.
- **`luna.docs.reflectTable(tbl, name?)`** — reflects any Lua table; returns `{name, qualifiedName, type}[]`.
- **`luna.devtools.exposeWatch(name, getter, category?)`** — registers a named getter function; returns a sequential id.
- **`luna.devtools.removeWatch(id)`** — removes a watch by id.
- **`luna.devtools.getWatches()`** — samples all registered watch getters; returns `{name, category, value}[]`.
- **`luna.devtools.snapshot()`** — captures a full point-in-time diagnostic dump (watches, frameStats, profile frame, last 10 log entries).
- **`examples/log.lua`** — updated with sink demos (memory sink, file sink, listSinks, clearSinks, tagged messages).
- **`examples/docs.lua`** — added schema validation and reflectLive/reflectTable demo sections.
- **`examples/devtools.lua`** — added exposeWatch/getWatches/snapshot demo sections.
- **`specs/log.md`**, **`specs/docs.md`**, **`specs/devtools.md`** — updated with full documentation for all new types, functions, and examples.
- **`src/log/AGENT.md`**, **`src/docs/AGENT.md`**, **`src/devtools/AGENT.md`** — synced with new source files and API additions.

---

## [0.6.5] — 2026-04-09

### Fixed
- **`examples/` and `demos/` namespace and callback corrections** — resolved all stale API references introduced by the engine callback rename:
  - `examples/graphics.lua`, `examples/gui.lua`: replaced `luna.draw =` with `luna.render =` / `luna.render_ui =`.
  - `examples/gui.lua`, `examples/network.lua`, `demos/retro/cannon_fodder/main.lua`: replaced `luna.update =` with `luna.process =`; removed broken `local _upd = luna.update` chaining pattern.
  - `demos/showcase/entity_showcase/main.lua`: replaced `luna.timer.getFPS()` with `luna.time.getFPS()`.
  - **33 demo files**: replaced `luna.load()` restart calls with `luna.signal.restart()`.
  - **8 example files** (`animation.lua`, `automation.lua`, `input.lua`, `physics.lua`, `timer.lua` and section headers in 3 demos): updated stale `luna.update` / `luna.draw` references in comments and section headers to `luna.process` / `luna.render`.

### Changed
- **`examples/` documentation** — added `-- This file is documentation code, not a runnable game.` header line to 26 example files that were missing it; consistent with existing API reference examples.
- **`demos/` documentation** — added `-- Run with: cargo run -- demos/<category>/<name>` run-hint line to 111 demo `main.lua` files.

---

## [0.6.4] — 2026-04-08

### Fixed
- **`docs/architecture/engine-architecture.md` Tier tables fully synced with codebase** — 22 net corrections:
  - **Tier 1**: moved `automation` to Tier 2 (it depends on Tier 1 `event`); removed stale `sound` entry (`src/sound/` does not exist — SoundData lives in `src/audio/`); removed TOML from `data` description; added 6 new Tier 1 modules: `debugbridge`, `devtools`, `docs`, `localization`, `log`, `patterns`.
  - **Tier 2**: added `automation`; fixed `postfx | src/postfx/` → `fx | src/fx/` (the module directory and API file are named `fx`); removed stale `overlay` entry (`src/overlay/` does not exist — overlay functionality is provided by the `fx` module); added 7 new Tier 2 modules: `light`, `network`, `pipeline`, `procgen`, `raycaster`, `serial`, `spine`.
  - **API Namespaces table**: removed stale `luna.sound → sound_api.rs` (file does not exist); expanded from 18 to 47 entries covering all registered `luna.*` namespaces.
  - **Boot Sequence**: updated comment from `18+` to `40+` API modules; removed `sound` from example list.
- **`specs/README.md`** — added missing entries for `devtools`, `localization`, and `patterns`.
- **Rust test paths corrected in 6 spec files** (`tests/rust/game/` is retired; `tests/unit/` was missing the `rust/` segment):
  - `specs/ai.md`: `tests/rust/game/ai_tests.rs` → `tests/rust/unit/ai_tests.rs`
  - `specs/minimap.md`: `tests/rust/game/minimap_tests.rs` → `tests/rust/unit/minimap_tests.rs`
  - `specs/math.md`: `tests/unit/math_tests.rs` → `tests/rust/unit/math_tests.rs`
  - `specs/pathfinding.md`: `tests/unit/pathfinding_tests.rs` → `tests/rust/unit/pathfinding_tests.rs`
  - `specs/physics.md`: `tests/unit/physics_tests.rs` → `tests/rust/unit/physics_tests.rs`
  - `specs/terminal.md`: `tests/unit/terminal_tests.rs` → `tests/rust/unit/terminal_tests.rs`

## [0.6.3] — 2026-04-13

### Removed
- **`luna.data.parseToml` / `luna.data.encodeToml` removed** — `data` is a binary-only module. These functions have been moved to `luna.codec` (`serial` module) which already provides `luna.codec.fromToml` / `luna.codec.toToml`. Lua scripts using `luna.data.parseToml` or `luna.data.encodeToml` must be updated to use `luna.codec.fromToml` / `luna.codec.toToml`.
- **`src/data/toml_convert.rs` removed from `pub mod` list** — the `data` module no longer exports TOML helpers. The equivalent functionality lives in `src/serial/toml.rs`.

### Changed
- **`specs/data.md`** — removed all TOML references from Summary, architecture diagram, Source Files table, Lua API table, and Notes. The `serial` cross-reference entry now correctly states TOML is `serial`'s sole responsibility via `luna.codec`.
- **`specs/log.md`** — clarified purpose as the **game developer's Lua logging tool** (not an engine-internal mechanism).
- **`specs/devtools.md`** — clarified purpose as the **engine and game diagnostics toolkit for engine developers and advanced game developers**; reinforced `modules.debug = true` gate and non-production intent.
- **`specs/debugbridge.md`** — clarified that it serves **both audiences**: game developers (via VS Code extension) and engine developers (via MCP server).
- **`specs/animation.md`** — strengthened framing as **frame-based GIF-style sprite animation**; added explicit boundary note that it is not related to `spine`.
- **`specs/spine.md`** — strengthened framing as an **independent skeletal/bone-hierarchy system**, explicitly distinct from `animation`.
- **`specs/gui.md`** — added note that shared widget type names (`Button`, `Label`, `TextBox`) with `terminal` are **intentional design** — same conceptual interface, different renderers.
- **`specs/terminal.md`** — added matching note that shared widget type names with `gui` are intentional.
- **`specs/docs.md`** — `loadToml` dependency corrected from `luna.data.parseToml` to `luna.codec.fromToml`.
- **Generated docs** (`docs/API/lua-api.md`, `docs/API/luna.lua`, `wiki/API-Reference.md`, `docs/logs/lua_api_data.json`) — `parseToml`/`encodeToml` entries removed from the `luna.data` section.

## [0.6.2] — 2026-04-08

### Fixed
- **`src/lua_api/log_api.rs` `pub fn register` docstring** — mixed `# Errors` + `@param`/`@return` inline tags replaced with the gold-standard `# Parameters` format used by `timer_api.rs`, `devtools_api.rs`, and `automation_api.rs`.
- **`src/debugbridge/AGENT.md` missing Ownership Rule** — the three-channel logging table (`debugbridge` / `log` / `devtools`) that lives in `specs/debugbridge.md` was absent from the AGENT.md. Now added so developers reading the short module overview see the ownership boundary without having to open the full spec.

### Changed
- **`specs/animation.md` Similar modules** — added `spine` reference explaining the frame-based vs skeletal-animation distinction; previously only mentioned `particle` and `graphics::sprite`.

## [0.6.1] — 2026-04-08

### Fixed
- **`src/lua_api/log_api.rs` now calls through the domain module** — `log_api.rs` previously bypassed `src/log/mod.rs` and called `engine::log_messages` directly, leaving the domain module as unreachable dead code. `setLevel` and `getLevel` now call `crate::log::set_level()` / `crate::log::get_level()` so the architecture matches the intended `lua_api → domain → engine` layering.
- **`tests/lua/harness.rs`: removed incorrect `#[ignore]` on `lua_test_log` and `lua_test_debugbridge`** — both `luna.log` and `luna.debugbridge` are registered in the test VM; the ignore attributes were wrong. Tests now run: 14/14 (`log`) and 18/18 (`debugbridge`) pass.
- **`tests/lua/harness.rs`: updated `lua_test_docs` ignore reason** — the `docs` test is skipped because the quality-score baseline test fails, not because `luna.docs` is unregistered.
- **Generated API docs namespace corrections** — `luna.timer`, `luna.event`, and `luna.automation` are internal module-folder key names; the actual registered Lua namespaces are `luna.time`, `luna.signal`, and `luna.simulator`. Fixed in:
  - `docs/API/lua-api.md` (regenerated)
  - `docs/API/luna.lua` LuaCATS stubs (regenerated)
  - `docs/logs/lua_api_data.json` (`lua_name` values)
  - `wiki/API-Reference.md` (section headers, TOC, function signatures)
  - `tools/docs/gen_docs_lua.py` — `_LUA_NAMESPACE` override dict added
  - `tools/docs/gen_luadoc.py` — `_LUA_NAMESPACE` override dict + `lua_name` prefix remap added

### Changed
- **`specs/log.md` Architecture section** — updated to show `log_api.rs → crate::log → engine::log_messages` call chain; added architecture note explaining why `set_level`/`get_level` logic belongs in the domain module.
- **`src/log/AGENT.md`** — Purpose section rewritten with correct call chain, explicit `[Lua]` prefix note, and the devtools separation rule.

## [0.6.0] — 2026-04-18

### Removed
- **`luna.debugbridge.recordFrame(dt)`** — removed from the public Lua API. Frame timing is now automatic.

### Changed
- **`luna.debugbridge.poll()` auto-records frame delta** — `poll()` now reads `luna.time.getDelta()` each frame and feeds the result into `BridgeShared.frame_times`. `getPerformance()` continues to work unchanged; game scripts no longer need a manual `recordFrame(dt)` call alongside `poll()`. Scripts that called `recordFrame` must remove that call.
- **Scope separation documented** — `specs/debugbridge.md` now includes an Ownership Rule section distinguishing `luna.log` (engine stdout), `devtools.Logger` (in-game UI), and `debugbridge.print_history` (TCP external tools). `specs/devtools.md` now documents the frame-timing ownership rule: use `luna.time` for basic fps/delta; use `devtools.frameStats` only for p50/p95/p99 percentile analysis.
- **`specs/timer.md`** — `Clock` is now documented as the canonical source for fps/delta in Luna2D.
- **`specs/event.md`** — Namespace Note added clarifying that `luna.signal.push/poll` (FIFO EventQueue) and `luna.signal.newSignal()` (pub-sub Signal) are independent primitives under the same namespace.
- **`specs/patterns.md`** — When-to-use guidance added for `EventBus` vs `Signal`, `ServiceLocator` vs Lua tables, and `StateMachine` vs `automation.Simulator`.
- **`specs/automation.md`** — See Also section added cross-referencing `timer::Scheduler` and `patterns::StateMachine`.
- **`specs/log.md`** — Ownership boundary note added to References table.
- **AGENT.md files** updated for `debugbridge`, `devtools`, `event`, `patterns`, and `automation`.

---

## [0.5.5] — 2026-04-17

### Changed
- **`docs` export functions extracted to domain** — `export_completions()`, `export_hover()`, `export_signatures()`, and `export_all()` moved from `lua_api/docs_api.rs` into a new `src/docs/export.rs` module (~180 lines). Added `Catalog::from_entries()` and `QualityReport::from_entries()` convenience constructors. The 4 export closures in the Lua binding are now 1-line wrappers. `docs_api.rs` reduced by ~6 KB.
- **`debugbridge` domain methods added** — `BridgeShared::record_frame(dt)`, `BridgeShared::set_max_print_history(max)`, and `BridgeShared::capture_print_with_broadcast(msg, source, line)` added to `src/debugbridge/bridge.rs`. Corresponding closures in `lua_api/debugbridge_api.rs` thinned to single-line delegate calls.

---

## [0.5.4] — 2026-04-16

### Changed
- **`mapgen.rs` generic layer names** — `MapGen::generate()` and `MapGen::generate_world()` now accept an explicit `layer_name: &str` parameter instead of hardcoding game-semantic names (`"generated"`, `"world"`). The Lua binding `mapgen:generate(scriptIndex?, seed?, layerName?)` exposes this as an optional third argument defaulting to `"main"`. All internal call sites and tests updated.
- **`automation` TOML parsing extracted to domain** — `Script::from_toml(name, toml_str) -> Result<Script, String>` added to `src/automation/script.rs`. The 50-line TOML parsing block removed from `lua_api/automation_api.rs`; `loadFromToml` is now a thin 4-line wrapper. 6 new `Script::from_toml` tests added to `tests/rust/unit/automation_tests.rs` (55 total).

---

## [0.5.3] — 2026-04-15

### Added
- **`docs` module** (`src/docs/`) — New domain module providing the Luna2D API catalog: `DocEntry`/`ParamInfo`/`ReturnInfo` types, `Catalog` with search/filter/module-grouping, `ValidationReport`/`QualityReport` with `quality_score()`/`quality_grade()`. Exposed via `luna.docs.*`. Spec: `specs/docs.md`. Tests: `tests/rust/unit/docs_tests.rs` (38 tests).
- **`debugbridge` module** (`src/debugbridge/`) — New domain module extracting the TCP debug bridge state and server logic: `BridgeShared` (server state), `PendingRequest`/`PendingResponse`, `PrintEntry`, `server_thread()`, `handle_client_message()`. Exposed via `luna.debugbridge.*`. Spec: `specs/debugbridge.md`. Tests: `tests/rust/unit/debugbridge_tests.rs` (20 tests).
- **`log` module** (`src/log/`) — New thin domain wrapper over `engine::log_messages` providing `set_level()`/`get_level()`/`enabled_for()`. Spec: `specs/log.md`.
- **`SimpleState`** (`src/patterns/simple_state.rs`) — New pattern type: simple string-keyed FSM with `add`/`remove`/`set_current`/`states()`. Used by `luna.patterns.newSimpleState()`.
- `src/docs/AGENT.md`, `src/debugbridge/AGENT.md`, `src/log/AGENT.md` — module overview files. `specs/README.md` updated.

### Changed
- **`luna_api/docs_api.rs`** — Refactored from 1693-line monolith to thin wrapper; all domain types (`DocEntry`, `ParamInfo`, `ReturnInfo`, `Catalog`, `ValidationReport`, `QualityReport`) now live in `src/docs/`. Lua bridge delegates to `crate::docs::*`.
- **`lua_api/debugbridge_api.rs`** — Refactored from 830 lines to 441 lines; `BridgeShared`, `PendingRequest`, `PendingResponse`, `PrintEntry`, `server_thread()`, `handle_client_message()` moved to `src/debugbridge/`. `lua_value_to_json()` and `poll()` remain in the API layer.
- **`lua_api/patterns_api.rs`** — All five embedded "Inner" structs removed; replaced by domain-backed `LuaEventBus`, `LuaObjectPool`, `LuaCommandStack`, `LuaServiceLocator`, `LuaFactory`, `LuaSimpleState` that wrap `crate::patterns::*` types.
- **`lua_api/log_api.rs`** — Docstring format corrected: `# Parameters`/`# Returns` sections replaced with `@param`/`@return` inline annotations.

## [0.5.2] — 2026-04-14

### Added
- **`devtools` module** (`src/devtools/`) — New domain module providing: structured logger (`Logger`/`LogEntry`/`LogLevel`) with min-level filtering and category tagging; hierarchical profiler (`Profiler`/`ProfileZone`) with per-frame zone tracking; rolling frame-time stats (`FrameStats`/`FrameSnapshot`) with FPS, P50/P95/P99 percentiles; and file watcher (`FileWatcher`) for hot-reload polling. Exposed via `luna.devtools.*` (gated by `modules.debug`). Spec: `specs/devtools.md`. Tests: `tests/rust/unit/devtools_tests.rs` (25 tests).
- **`localization` module** (`src/localization/`) — New domain module providing: multi-locale string catalog (`Catalog`) with load/unload/translate/fallback/export; `{var}` and `{var:fmt}` interpolation (`interpolate`/`interpolate_pairs`); CLDR-based plural forms (`PluralForm`/`pluralize`/`pluralize_slavic`) for English and Slavic rulesets. Exposed via `luna.localization.*` (gated by `modules.localization`). Spec: `specs/localization.md`. Tests: `tests/rust/unit/localization_tests.rs` (26 tests).
- **`patterns` module** (`src/patterns/`) — New domain module implementing six game-programming design patterns as pure-Rust types: `EventBus` (subscribe/drain-once/priority sort), `ObjectPool` (acquire/release/prewarm/capacity), `CommandStack` (push/undo/redo/batch), `ServiceLocator` (name→any register/unregister/has), `Factory` (type registry + aliases), `StateMachine` (states/transitions/guards/history/reachable). Exposed via `luna.patterns.*` (gated by `modules.pipeline`). Spec: `specs/patterns.md`. Tests: `tests/rust/unit/patterns_tests.rs` (34 tests).
- `src/devtools/AGENT.md`, `src/localization/AGENT.md`, `src/patterns/AGENT.md` — module overview files.

## [0.5.1] — 2026-04-08

### Added
- Added `LICENSE_INVENTORY.md` at the repository root with explicit first-party Rust module and Lua library lists, direct Cargo dependency license tables, the direct VS Code extension runtime dependency license, and a no-models-found audit summary.

## [0.5.0] — 2026-04-08

### Changed
- Version bumped to 0.5.0 — first tracked release.
- **Distribution build** switched from fat-LTO `--profile dist` to `--release` (thin LTO); balanced binary size vs. link time.
- **Windows installer** (`tools/dist/installer.nsi`): now bundles `examples/`, `library/`, `demos/`, and the full `docs/API/` folder. Registers `.lua` file association so double-clicking any Lua script launches it in Luna2D.
- **dist.ps1**: updated to use `cargo build --release` and `build/release/luna2d.exe`; adds `demos/` to the portable package.
- **Icons**: Windows binary now embeds `assets/favicon.ico` (user-supplied). Removed auto-generated icon/splash Python scripts (`gen_icon.py`, `gen_splash.py`, `gen_branding.py`, `gen_svg_assets.py`) — all artwork is now maintained manually in `assets/`.
- **Build.rs**: icon embed path updated to `assets/favicon.ico`.

### Added
- `docs/CHANGELOG.md` — this file; version history starting at 0.5.0.

---

<!-- Template for future entries:

## [X.Y.Z] — YYYY-MM-DD

### Added
-

### Changed
-

### Fixed
-

### Removed
-

-->
