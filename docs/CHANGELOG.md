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
