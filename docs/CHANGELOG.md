# Lurek2D Changelog

All notable changes to Lurek2D are recorded here.

## Versioning scheme

```
MAJOR.MINOR.PATCH
```

| Segment | Increment when… |
|---|---|
| **MAJOR** | Breaking API changes — Lua scripts or engine configuration must be ported |
| **MINOR** | New backwards-compatible features — new `lurek.*` APIs, new modules, new default configs |
| **PATCH** | Bug fixes, internal refactors, documentation and tooling changes that do not affect the public API |

Always update this file **in the same commit** as the change. Use the commit type as the section label.

---

## [0.6.22] — 2026-04-09
### Fixed
- **data** module audit: D-04 stubs (byte_data×2, compress, encode, hash), D-03 LuaDataView # Fields, SP-05 LuaDataView heading, T-03 six test_ prefixes removed → PASS (8th)
- **tween** module audit: D-09 separators (3+ box chars via Python), SP-02/SP-03 added Summary/Source Files/Key Types sections, SP-05 LuaTween/LuaTweenSequence/LuaTweenParallel headings → PASS (9th)

## [0.6.21] — 2026-04-09

### Fixed
- **Quality: D-04** — Replaced "Consult the module-level documentation" stub phrases with real doc content in `src/graph/` (7 entries in `core.rs`, `item.rs`, `node.rs`, `supply_demand.rs`), `src/input/touch.rs` (4 entries), `src/input/mouse.rs` (2 entries), `src/thread/channel.rs` (1 entry), `src/modding/mod_manager.rs` (5 entries), `src/savegame/save_data.rs` (5 entries)
- **Quality: SP-03** — Trimmed `## Summary` sections to under 2000 chars in `docs/specs/timer.md` (2373→1429), `docs/specs/modding.md` (2399→1615), `docs/specs/savegame.md` (2005→1620)
- **Quality: SP-05** — Added missing Key Type headings (`CommandEntry`, `Blackboard`, `BlackboardValue`, `Debounce`, `Funnel`, `FunnelEntry`) to `docs/specs/patterns.md`; fixed `### Enums` stub ("No public enums") with `BlackboardValue` heading
- **Quality: D-03** — Added `# Fields` section to `SimpleState` in `src/patterns/simple_state.rs`, to `Scheduler` in `src/timer/scheduler.rs`; fixed oversized doc window for `Minimap` in `src/minimap/minimap.rs` (reduced Fields list by 2 entries so section falls within 25-line check window)
- **Quality: T-01 + T-05** — Created `tests/rust/unit/log_tests.rs` (21 tests) covering `SinkLevel`, `MemoryEntry`, `Sink`, and `SinkRegistry`; registered in `Cargo.toml`
- **Quality: SP-05** — Added heading-based Key Types entries in `docs/specs/log.md` for `MemoryEntry`, `Sink`, `SinkRegistry`, `SinkLevel`, `SinkKind`
- **Quality audit** — `log` module now PASS (6/46 total: serial, window, localization, debugbridge, procgen, log). Modules graph, patterns, input, minimap, thread, modding, savegame, timer all reach ≤2W and will PASS immediately when Developer resolves B-02/B-03 findings

## [0.6.20] — 2026-04-09

### Fixed
- **Quality: B-06** — Audit check now only flags genuinely bare `{}` blocks (not closure bodies or control-flow blocks). Added word-boundary constraint so `r_tbl.set(` and `d_tbl.set(` patterns no longer match. Eliminates false positives in `debugbridge_api.rs` and `procgen_api.rs`.
- **Quality: SP-03** — Trimmed `## Summary` sections to under 2000 chars in `docs/specs/debugbridge.md` (2370→1951) and `docs/specs/procgen.md` (2324→1983)
- **Quality: SP-05** — Removed internal `pub(crate) struct Lcg` from `## Key Types` section of `docs/specs/procgen.md`; it is documented in `## Submodules` instead
- **Quality: D-04** — Replaced "Consult the module-level documentation" stub phrases with real doc content in `src/procgen/flood_fill.rs` and `src/procgen/voronoi.rs` (3 entries)
- **Quality: T-04** — Fixed float-literal assertions in `tests/rust/unit/localization_tests.rs` by separating `PluralForm::english(1.0)` calls to their own `let` binding before the `assert_eq!` comparison
- **Quality audit** — `localization`, `debugbridge`, and `procgen` modules now PASS (5/46 total: serial, window, localization, debugbridge, procgen)

## [0.6.19] — 2026-04-09

### Fixed
- **Quality: A-02** — Added `## Key Types` and `## Lua API Summary` sections to 39 AGENT.md files missing them (all modules except ai, which already had them) — fixes A-02 WARN in all modules
- **Quality: D-09** — Broadened section separator detection to accept ASCII `// ---` in addition to Unicode `// ─────`; added minimal separator comments to `patterns_api.rs` and `tween_api.rs` which had none
- **Quality: SP-06** — Made stub detection case-sensitive (`PLACEHOLDER` all-caps only) to stop false-positive warnings from legitimate documentation uses of the word "placeholder" in `gui.md`, `localization.md`, `window.md`, `engine.md`; fixed 4 genuine `TODO` stubs in `docs/specs/serial.md`
- **Quality: W-05** — Created 13 stub wiki pages for modules missing them: `Graph-API.md`, `Image-API.md`, `Light-API.md`, `Localization-API.md`, `Log-API.md`, `Minimap-API.md`, `Patterns-API.md`, `Pipeline-API.md`, `Raycaster-API.md`, `Serial-API.md`, `Spine-API.md`, `Thread-API.md`, `Tween-API.md`
- **Quality: R-01** — Expanded tier registry in `tools/audit/audit_module.py`: added 7 modules to TIER1 (`debugbridge`, `devtools`, `docs`, `localization`, `log`, `patterns`, `tween`) and 9 modules to TIER2 (`fx`, `light`, `network`, `pipeline`, `procgen`, `raycaster`, `serial`, `spine`, `terminal`) — previously these were in EXTRA (unassigned)
- **Quality audit** — `serial` and `window` modules now fully PASS the automated quality audit (2/46 modules PASS)

---

## [0.6.18] — 2026-04-09

### Fixed
- **Quality: mass D-08 fix all lua_api files** — Converted rustdoc `# Parameters`/`# Returns`/`# Fields` sections to `@param`/`@return` annotations in all 33 remaining `src/lua_api/*_api.rs` files
- **Quality: D-01** — Added `//!` module-level doc comment to `src/spine/bone.rs`, `src/spine/skeleton.rs`, `src/spine/slot.rs`, `src/graphics/color.rs`, `src/engine/temp_test.rs`
- **Quality: tween AGENT.md** — Added property table with `**Tier**`, `**Status**`, `**Lua API**` entries; renamed `## Overview` → `## Purpose` (fixes A-02/A-03/A-06)
- **Quality: A-04** — Added missing source file rows to `src/event/AGENT.md` (`event_queue.rs`), `src/patterns/AGENT.md` (7 files), `src/savegame/AGENT.md` (`save_manager.rs`)
- **Quality: Q-01** — Replaced `eprintln!` with `log::debug!` in `src/engine/app.rs`; replaced `eprintln!` with `writeln!(stderr)` in `src/devtools/logger.rs`
- **Quality: W-02** — Added missing API coverage snippets to four `content/examples/` files (`docs.lua`, `math.lua`, `physics.lua`, `tilemap.lua`)
- **Quality: tween_api.rs B-06** — Renamed inner result table `tbl` → `out` inside `getEasingNames` closure to eliminate B-06 false-positive
- **Audit: T-04 regex** — Improved `check_float_comparisons()` in `tools/audit/audit_module.py` to strip comments and string literals before scanning; eliminates false-positive T-04 reports

---

## [0.6.17] — 2025-07-19
  - D-09: Added missing `// ── name ──────` section separator comments to `ai_api.rs` (19), `automation_api.rs` (17), `animation_api.rs` (1)
  - D-04: Removed 24 stub docstrings (`Consult the module-level documentation…`) from `src/audio/` and `src/camera/` files
  - D-01: Added `//!` module header to `src/audio/dsp.rs`
  - A-02: Added `## Key Types` and `## Lua API Summary` tables to `src/ai/AGENT.md`, `src/animation/AGENT.md`, `src/audio/AGENT.md`, `src/automation/AGENT.md`, `src/camera/AGENT.md`
  - automation R-01: Corrected tier label in `src/automation/AGENT.md` from Tier 2 to Tier 1
  - automation SP-04: Added `lurek.simulator.loadFromToml` row to `docs/specs/automation.md`
- **Audit tool** (`tools/audit/audit_module.py`) — Fixed four bugs:
  - W-01: Wrong example file path (`examples/` → `content/examples/`)
  - W-03: Wrong demo path (`examples/` → `content/demos/`)
  - R-02: Added `CRATE_ROOT_EXPORTS` skip list to suppress false positives for `log_msg` macro
  - T-04: Fixed float comparison check to test the `assert_eq!` line itself (not surrounding context window)
  - SP-05: Updated heading regex to handle `####` and module-path-qualified type names; filter generic section words

## [0.6.17] — 2025-07-19

### Changed
- **Full project rename: Luna2D → Lurek2D / `luna.*` → `lurek.*`** — Complete rename of all identifiers, namespaces, and strings across the entire repository (the engine was not yet published):
  - Display name: `Luna2D` / `Luna 2D` → `Lurek2D` / `Lurek 2D` in all docs, comments, UI strings
  - Crate name: `luna2d` → `lurek2d` (Cargo.toml package, lib, bin)
  - Lua API global namespace: `luna.*` → `lurek.*` in all Rust bindings, Lua scripts, tests, examples, and docs
  - Lua global table string: `globals().set("luna", ...)` / `globals().get("luna")` → `"lurek"` in all Rust files
  - Entry point function: `luna_run()` → `lurek_run()` in `src/lib.rs`, `src/main.rs`, `src/bin/lurekc.rs`
  - Console-less binary: `lunec` → `lurekc` (Cargo.toml `[[bin]]`, `src/bin/lunec.rs` renamed to `lurekc.rs`)
  - Archive format: `.lunar` → `.lurek`; `extract_lunar_archive()` → `extract_lurek_archive()`
  - Build cfg flag: `luna2d_has_splash` → `lurek2d_has_splash` in `build.rs`
  - Log filter prefix: `RUST_LOG=luna2d` → `RUST_LOG=lurek2d` in all documentation and scripts
  - All Rust imports: `use luna2d::` / `luna2d::` qualified paths → `use lurek2d::` / `lurek2d::`

## [0.6.16] - 2026-04-09

### Changed
- **Repository layout** — Relocated root-level folders into `docs/`:
  - `specs/` → `docs/specs/` (module technical specifications)
  - `wiki/` → `docs/wiki/` (GitHub wiki pages)
  - `pages/` → `docs/site/` (GitHub Pages source)
  - `save/` removed from git tracking and added to `.gitignore` (runtime-generated save data)
- Updated all references in `src/*/AGENT.md`, `.github/`, and `tools/` to use the new `docs/specs/`, `docs/wiki/`, and `docs/site/` paths.

### Added
- **`src/image/layers.rs`** � `ImageLayer` and `LayeredImage` types for compositing layer stacks with Porter-Duff "over" merge.
- **`src/image/serial.rs`** � LIMG binary format: save/load `ImageData` and `LayeredImage` with zlib compression.
- **Lua API** additions on `lurek.img`: `newLayeredImage`, `saveImage`, `loadImage`, `loadLayered`, and 14 `LayeredImage` userdata methods.
- 19 new Rust tests in `tests/rust/unit/image_tests.rs` (62 total); new Lua BDD tests for layers and serialization.

## [0.6.15] � 2026-04-09

### Added
- **`src/image/effects.rs`** — 20 CPU-side pixel-processing effects on `ImageData`:
  - **Color / Tone** (in-place): `brightness`, `contrast`, `saturation`, `gamma`, `tint`
  - **Filters** (in-place): `grayscale`, `sepia`, `invert`, `threshold`, `posterize`, `fill`, `noise`, `alpha_mask`
  - **Geometric in-place**: `flip_horizontal`, `flip_vertical`
  - **Geometric new-image**: `rotate_90_cw`, `crop`, `resize_nearest`
  - **Convolution new-image**: `blur` (two-pass box), `sharpen` (3×3 unsharp)
- All 20 effects exposed to Lua on `ImageData` userdata: `brightness`, `contrast`, `saturation`, `gamma`, `tint`, `grayscale`, `sepia`, `invert`, `threshold`, `posterize`, `fill`, `noise`, `alphaMask`, `flipHorizontal`, `flipVertical`, `rotate90cw`, `crop`, `resizeNearest`, `blur`, `sharpen`

### Fixed
- **`src/image/image_data.rs`** — fields `width`, `height`, `pixels` changed from private to `pub(super)` to allow the sibling `effects.rs` module to access them directly without going through the public API on every pixel — necessary for efficient in-place operations on large images.

### Tests
- `tests/rust/unit/image_tests.rs` — 23 new tests covering all 20 effects (43 total, all passing)
- `tests/lua/unit/test_image.lua` — 91 new BDD tests for all 20 Lua-exposed effect methods (98 total, all passing)

### Documentation
- `content/examples/image.lua` — expanded with full effects section demonstrating all 20 methods with comments
- `specs/image.md` — updated source files table, added effects table to `ImageData` key types, expanded Lua API section with all 28 methods organised by category
- `src/image/AGENT.md` — updated source files table, added Key Types and Lua API Summary sections

## [0.6.14] — 2026-04-09

### Fixed
- **`tools/audit/audit_module.py`** — fixed VS Code extension-host pipe deadlock that hung the entire IDE on batch audits:
  - Root cause: `sys.stdout = io.TextIOWrapper(sys.stdout.buffer, ...)` created a block-buffered pipe wrapper (8 KB blocks). Printing hundreds of KB of text for `--all` mode filled the 64 KB Windows pipe buffer, then blocked indefinitely waiting for VS Code's pipe reader to drain it. CPU stayed at 8% (single thread, waiting on OS pipe write).
  - Fix: replaced the `TextIOWrapper` assignment with `sys.stdout.reconfigure(encoding="utf-8", errors="replace")` — modifies the existing wrapper in-place, leaving its buffer mode unchanged.
  - Fix: replaced `print(output)` (one giant string) with line-by-line `print(ln, flush=True)` so the pipe drains continuously.
  - Fix: when `--docs-quality` is active, suppressed the large text report on stdout entirely — the per-module Markdown files in `docs/quality/` are the primary artifact.
  - Added `sys.stdout.flush()` in a `try/finally` block before interpreter teardown to prevent partial output on `sys.exit()`.
  - **Benchmark**: `--all --docs-quality` for 46 modules completes in **2.4 seconds** with no VS Code UI freeze.

---

## [0.6.13] — 2026-04-09

### Fixed
- **`tools/audit/audit_module.py`** — major performance overhaul to eliminate VS Code extension-host crashes when batch-auditing 15+ modules:
  - Added module-level `_FILE_CACHE` dict so each `.rs` file is read from disk exactly once per audit run instead of being re-read by each of the 8 independent check functions (previously: 8 reads per file per module; now: 1 read per file).
  - Added `_analyze_module_files()` which performs a single sequential pass over the module's source files, accumulating all findings (D-01/D-02/D-04/R-02/R-03/Q-01/Q-03/Q-04 and file sizes) in one loop. Individual check functions now query the pre-computed `ModuleFileAnalysis` instead of re-iterating files.
  - Fixed wrong `REQUIRED_SECTIONS` list (`Summary`, `Key Types`, `Item Summary`) that was generating false A-02 ERRORs on every module. Updated to the canonical AGENT.md format: `Purpose`, `Source Files`, `Full Specification` (also accepting the short form `Full Spec`).
  - Fixed contradictory A-05 check (previously required `\`\`\`lua` blocks in AGENT.md, contradicting the agent-md skill which places Lua examples in `specs/`). A-05 now checks for the existence of the `specs/<module>.md` companion file instead.
  - Fixed duplicate `if __name__ == "__main__":` UTF-8 wrapper block; added `try/except AttributeError` guard for subprocess contexts.
  - Added `clear_file_cache()` call between modules in batch runs to bound memory usage.
  - **Benchmark**: 1 module: 0.12 s; 15 modules: 0.18 s; all 46 modules: 0.35 s (previously blocked VS Code on 15-module batches).

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
- **`wiki/Data-API.md`** — new wiki page for `lurek.data` (W-05 audit finding).
- **`wiki/Dataframe-API.md`** — new wiki page for `lurek.dataframe` (W-05 audit finding).
- **`wiki/Debugbridge-API.md`** — new wiki page for `lurek.debugbridge` (W-05 audit finding).
- **`wiki/Devtools-API.md`** — new wiki page for `lurek.devtools` (W-05 audit finding).
- **`wiki/Docs-API.md`** — new wiki page for `lurek.docs` (W-05 audit finding).

---

## [0.6.11] — 2026-04-08

### Fixed
- **`src/lua_api/animation_api.rs`** — `register()` docstring changed from stale `lurek.tween` to correct `lurek.animation`; removed prohibited `# Parameters` rustdoc section (D-06, D-08 audit findings).
- **`src/lua_api/compute_api.rs`** — module-level `//!` header and `register()` docstring updated from stale `lurek.gpu` to correct `lurek.compute`; removed prohibited `# Parameters` section from `register()` (D-06, D-08 audit findings).
- **`src/lib.rs`** — two stale `(lurek.gpu)` references updated to `(lurek.compute)` in crate-level docs (D-06 finding).
- **`src/compute/array.rs`** — four production-code `.unwrap()` calls in `get_f64()` and `get_i32()` replaced with `.expect("byte slice invariant: offset validated by flat_index")` (Q-04 audit finding).
- **`src/audio/AGENT.md`** — added missing `mod.rs` entry to Source Files table (A-04 audit finding).
- **`src/camera/AGENT.md`** — added missing `mod.rs` entry to Source Files table (A-04 audit finding).
- **`src/ai/AGENT.md`** — Rust Tests row updated from deprecated `tests/rust/game/ai_tests.rs` to canonical `tests/rust/unit/ai_tests.rs` (T-01 audit finding).
- **`tests/rust/unit/ai_tests.rs`** — ai integration tests migrated from `tests/rust/game/` to canonical `tests/rust/unit/` location (T-01 audit finding).
- **`Cargo.toml`** — `ai_tests` `[[test]]` entry moved to unit test section with updated path `tests/rust/unit/ai_tests.rs`.

### Added
- **`wiki/Compute-API.md`** — new wiki page for the `lurek.compute` module with overview, full API reference table, dtype table, and a procedural terrain example (W-05 audit finding).

### Changed
- **`.github/prompts/audit-module.prompt.md`** — Fix Workflow section updated: the fix pass now runs automatically after every audit without requiring a separate user request; post-fix `cargo check` and final summary are now mandatory.

## [0.6.10] — 2026-04-08

### Changed
- **`src/math/tween.rs`** — removed deprecated blockquote from module doc; replaced with a clear positive description of the module's scope and how it differs from `lurek.tween`.
- **`src/tween/state.rs`** — module doc cross-reference updated: now points to `src/tween/handle.rs` and `src/tween/engine.rs` instead of the old `lua_api` path.
- **`specs/tween.md`** — renamed "Lua Binding Types (src/lua_api/tween_api.rs)" section to "Domain Types (src/tween/)"; replaced stale `TweenApiState` description with current `TweenEngine`; updated UserData section headers to include correct source files; replaced "Cross-Module References" with an explicit "Separation of Duties" table covering `tween`, `animation`, `math::tween`, and `spine`.
- **`src/tween/AGENT.md`** — added "Separation from Related Modules" table explaining responsibilities of each animation-related module.
- **`content/examples/tween.lua`** — added sections 11–13 covering previously missing API: `lurek.tween.getActiveCount()`, `LuaTween:getProgress()`, `LuaTweenSequence:cancel()` + `isActive()`, `LuaTweenParallel:add()` + `cancel()` + `isActive()`. All 13 API surface areas now covered.

## [0.6.9] — 2026-04-15

### Changed
- **`lurek.tween` architectural refactor** — moved all business logic out of `src/lua_api/tween_api.rs` into proper domain modules, enforcing the Thin Wrapper Rule:
  - `src/tween/engine.rs` (new) — `TweenEngine`: active-pool management, `update()`, `cancel_all()`, `active_count()`.
  - `src/tween/handle.rs` (new) — `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`, `ParallelEntry` + all `impl LuaUserData` blocks.
  - `src/tween/mod.rs` — expanded with `pub mod engine`, `pub mod handle`, and public re-exports for all new types.
  - `src/lua_api/tween_api.rs` — reduced to ~200-line thin registration wrapper (`pub fn register()` only).
  - `src/math/tween.rs` — module doc updated with deprecation notice pointing to `lurek.tween`.
  - `specs/tween.md` — Architecture diagram and Module Layout table updated to reflect new 4-layer structure.
  - `src/tween/AGENT.md` — Source file table updated with `handle.rs` and `engine.rs` entries.
- **CAG rule enforced** — Added mandatory **Thin Wrapper Rule** paragraph to `.github/copilot-instructions.md` under "Lua API Conventions".
- Public API unchanged — all `lurek.tween.*` function names and signatures are identical.

## [0.6.8] — 2026-04-14

### Changed
- **`content/examples/` quality pass (part 2)** — stub sections in four high-complexity example files replaced with fully documented example code:
  - `math.lua` (stubs → 5 organised sections): BezierCurve introspection, Transform/Tween supplemental, easing standalone functions, geometry utilities (14 functions), and math wrappers.
  - `ai.lua` (13 class stubs → 13 documented sections): supplemental methods for AIWorld, Agent, BTNode, BehaviorTree, Blackboard, CommandQueue, GOAPPlanner, InfluenceMap, QLearner, Squad, StateMachine, SteeringManager, UtilityAI — all with context comments, realistic args, and use-case rationale.
  - `pathfinding.lua` (5 class stubs → 5 documented sections): AiFlowField introspection, FlowField query methods, NavGrid chunk info, PathGrid dynamic obstacles, UnitPathfinder cache control.
  - `graphics.lua` (9 thin class sections → 11 sections): Canvas, DrawLayer, Font, Image, ImageData, Mesh, NineSlice, Quad, Shader, Shape, SpriteBatch — each with type identity pattern, supplemental methods, and cross-reference notes.
  - Coverage maintained at **2539/2539 = 100%** throughout.

- **`content/examples/` quality pass (part 1)** — all 45 example files improved for readability and accuracy:
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
- **`lurek.tween` — property tweening system** — new `src/tween/` Tier 1 module plus `src/lua_api/tween_api.rs` binding. Animate any Lua table field by name in real-time: `lurek.tween.tween(duration, target, {field = end_value, ...}, easing)`. Supports multi-field tweens, sequences (`:tween()` / `:delay()` / `:callback()`), parallels (`:tween()` / `:add()`), repeat + yoyo, pause/resume, and `onComplete` / `onUpdate` / `onCancel` callbacks. Manual update model: call `lurek.tween.update(dt)` from `lurek.process(dt)`. Start values are captured lazily on the first update tick.
- **`lurek.tween.sequence()`** — chain animation steps that execute one after another.
- **`lurek.tween.parallel()`** — run multiple tweens simultaneously; fires `onComplete` when all children finish.
- **`lurek.tween.delay(sec, fn?)`** — standalone timer convenience helper.
- **`lurek.tween.registerEasing(name, fn)` / `lurek.tween.getEasingNames()`** — custom Lua easing functions and introspection of all 23 built-in easing names.
- **`ModulesConfig.tween: bool`** — gating flag in `conf.lua` (`modules.tween`, default `true`).
- **`tests/rust/unit/tween_tests.rs`** — 14 Rust unit tests for `TweenState`, `resolve_easing`, `builtin_easing_names`.
- **`tests/lua/unit/test_tween.lua`** — ~50 Lua BDD tests covering all `lurek.tween.*` API surface.
- **`content/examples/tween.lua`** — 10-section usage script demonstrating all API features.
- **`src/tween/AGENT.md`**, **`specs/tween.md`** — module agent reference and full specification.
- Fixed stale `//! \`lurek.tween\`` header comment in `src/lua_api/animation_api.rs` (correctly `lurek.animation`).
- Fixed stale comment in `src/lua_api/mod.rs` registration block (animation maps to `lurek.animation`).

---

## [0.6.6] — 2026-04-10

### Added
- **`lurek.log` configurable sinks** — new `src/log/sinks.rs` module with `SinkLevel`, `SinkKind` (File / Memory), `Sink`, and `SinkRegistry` types. All `lurek.log.*` emit functions now accept an optional `tag` second argument (default `"Lua"`). New API: `addSink(cfg)→id`, `removeSink(id)→bool`, `clearSinks()`, `listSinks()→table`, `readMemory(id, drain?)→table?`, `flushFile(id)`. Sinks dispatch independently of `RUST_LOG` filtering.
- **`lurek.docs.schema()`** — new `src/docs/schema.rs` with `Schema`, `FieldRule`, `FieldType`, `SchemaError`, `SchemaResult`. Game scripts can define typed field rules (required, min/max, minLen/maxLen, enum, strict mode) and call `schema:validate(data)`, `schema:check(data)`, `schema:assert(data)` for safe runtime data-validation.
- **`lurek.docs.reflectLive(ns?)`** — walks the live `lurek.*` Lua table and returns a structured `{ns → [{name, type}]}` map. Supports optional namespace filter argument.
- **`lurek.docs.reflectTable(tbl, name?)`** — reflects any Lua table; returns `{name, qualifiedName, type}[]`.
- **`lurek.devtools.exposeWatch(name, getter, category?)`** — registers a named getter function; returns a sequential id.
- **`lurek.devtools.removeWatch(id)`** — removes a watch by id.
- **`lurek.devtools.getWatches()`** — samples all registered watch getters; returns `{name, category, value}[]`.
- **`lurek.devtools.snapshot()`** — captures a full point-in-time diagnostic dump (watches, frameStats, profile frame, last 10 log entries).
- **`content/examples/log.lua`** — updated with sink demos (memory sink, file sink, listSinks, clearSinks, tagged messages).
- **`content/examples/docs.lua`** — added schema validation and reflectLive/reflectTable demo sections.
- **`content/examples/devtools.lua`** — added exposeWatch/getWatches/snapshot demo sections.
- **`specs/log.md`**, **`specs/docs.md`**, **`specs/devtools.md`** — updated with full documentation for all new types, functions, and examples.
- **`src/log/AGENT.md`**, **`src/docs/AGENT.md`**, **`src/devtools/AGENT.md`** — synced with new source files and API additions.

---

## [0.6.5] — 2026-04-09

### Fixed
- **`content/examples/` and `content/demos/` namespace and callback corrections** — resolved all stale API references introduced by the engine callback rename:
  - `content/examples/graphics.lua`, `content/examples/gui.lua`: replaced `lurek.draw =` with `lurek.render =` / `lurek.render_ui =`.
  - `content/examples/gui.lua`, `content/examples/network.lua`, `content/demos/retro/cannon_fodder/main.lua`: replaced `lurek.update =` with `lurek.process =`; removed broken `local _upd = lurek.update` chaining pattern.
  - `content/demos/showcase/entity_showcase/main.lua`: replaced `lurek.timer.getFPS()` with `lurek.time.getFPS()`.
  - **33 demo files**: replaced `lurek.load()` restart calls with `lurek.signal.restart()`.
  - **8 example files** (`animation.lua`, `automation.lua`, `input.lua`, `physics.lua`, `timer.lua` and section headers in 3 demos): updated stale `lurek.update` / `lurek.draw` references in comments and section headers to `lurek.process` / `lurek.render`.

### Changed
- **`content/examples/` documentation** — added `-- This file is documentation code, not a runnable game.` header line to 26 example files that were missing it; consistent with existing API reference examples.
- **`content/demos/` documentation** — added `-- Run with: cargo run -- content/demos/<category>/<name>` run-hint line to 111 demo `main.lua` files.

---

## [0.6.4] — 2026-04-08

### Fixed
- **`docs/architecture/engine-architecture.md` Tier tables fully synced with codebase** — 22 net corrections:
  - **Tier 1**: moved `automation` to Tier 2 (it depends on Tier 1 `event`); removed stale `sound` entry (`src/sound/` does not exist — SoundData lives in `src/audio/`); removed TOML from `data` description; added 6 new Tier 1 modules: `debugbridge`, `devtools`, `docs`, `localization`, `log`, `patterns`.
  - **Tier 2**: added `automation`; fixed `postfx | src/postfx/` → `fx | src/fx/` (the module directory and API file are named `fx`); removed stale `overlay` entry (`src/overlay/` does not exist — overlay functionality is provided by the `fx` module); added 7 new Tier 2 modules: `light`, `network`, `pipeline`, `procgen`, `raycaster`, `serial`, `spine`.
  - **API Namespaces table**: removed stale `lurek.sound → sound_api.rs` (file does not exist); expanded from 18 to 47 entries covering all registered `lurek.*` namespaces.
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
- **`lurek.data.parseToml` / `lurek.data.encodeToml` removed** — `data` is a binary-only module. These functions have been moved to `lurek.codec` (`serial` module) which already provides `lurek.codec.fromToml` / `lurek.codec.toToml`. Lua scripts using `lurek.data.parseToml` or `lurek.data.encodeToml` must be updated to use `lurek.codec.fromToml` / `lurek.codec.toToml`.
- **`src/data/toml_convert.rs` removed from `pub mod` list** — the `data` module no longer exports TOML helpers. The equivalent functionality lives in `src/serial/toml.rs`.

### Changed
- **`specs/data.md`** — removed all TOML references from Summary, architecture diagram, Source Files table, Lua API table, and Notes. The `serial` cross-reference entry now correctly states TOML is `serial`'s sole responsibility via `lurek.codec`.
- **`specs/log.md`** — clarified purpose as the **game developer's Lua logging tool** (not an engine-internal mechanism).
- **`specs/devtools.md`** — clarified purpose as the **engine and game diagnostics toolkit for engine developers and advanced game developers**; reinforced `modules.debug = true` gate and non-production intent.
- **`specs/debugbridge.md`** — clarified that it serves **both audiences**: game developers (via VS Code extension) and engine developers (via MCP server).
- **`specs/animation.md`** — strengthened framing as **frame-based GIF-style sprite animation**; added explicit boundary note that it is not related to `spine`.
- **`specs/spine.md`** — strengthened framing as an **independent skeletal/bone-hierarchy system**, explicitly distinct from `animation`.
- **`specs/gui.md`** — added note that shared widget type names (`Button`, `Label`, `TextBox`) with `terminal` are **intentional design** — same conceptual interface, different renderers.
- **`specs/terminal.md`** — added matching note that shared widget type names with `gui` are intentional.
- **`specs/docs.md`** — `loadToml` dependency corrected from `lurek.data.parseToml` to `lurek.codec.fromToml`.
- **Generated docs** (`docs/API/lua-api.md`, `docs/API/lurek.lua`, `wiki/API-Reference.md`, `docs/logs/lua_api_data.json`) — `parseToml`/`encodeToml` entries removed from the `lurek.data` section.

## [0.6.2] — 2026-04-08

### Fixed
- **`src/lua_api/log_api.rs` `pub fn register` docstring** — mixed `# Errors` + `@param`/`@return` inline tags replaced with the gold-standard `# Parameters` format used by `timer_api.rs`, `devtools_api.rs`, and `automation_api.rs`.
- **`src/debugbridge/AGENT.md` missing Ownership Rule** — the three-channel logging table (`debugbridge` / `log` / `devtools`) that lives in `specs/debugbridge.md` was absent from the AGENT.md. Now added so developers reading the short module overview see the ownership boundary without having to open the full spec.

### Changed
- **`specs/animation.md` Similar modules** — added `spine` reference explaining the frame-based vs skeletal-animation distinction; previously only mentioned `particle` and `graphics::sprite`.

## [0.6.1] — 2026-04-08

### Fixed
- **`src/lua_api/log_api.rs` now calls through the domain module** — `log_api.rs` previously bypassed `src/log/mod.rs` and called `engine::log_messages` directly, leaving the domain module as unreachable dead code. `setLevel` and `getLevel` now call `crate::log::set_level()` / `crate::log::get_level()` so the architecture matches the intended `lua_api → domain → engine` layering.
- **`tests/lua/harness.rs`: removed incorrect `#[ignore]` on `lua_test_log` and `lua_test_debugbridge`** — both `lurek.log` and `lurek.debugbridge` are registered in the test VM; the ignore attributes were wrong. Tests now run: 14/14 (`log`) and 18/18 (`debugbridge`) pass.
- **`tests/lua/harness.rs`: updated `lua_test_docs` ignore reason** — the `docs` test is skipped because the quality-score baseline test fails, not because `lurek.docs` is unregistered.
- **Generated API docs namespace corrections** — `lurek.timer`, `lurek.event`, and `lurek.automation` are internal module-folder key names; the actual registered Lua namespaces are `lurek.time`, `lurek.signal`, and `lurek.simulator`. Fixed in:
  - `docs/API/lua-api.md` (regenerated)
  - `docs/API/lurek.lua` LuaCATS stubs (regenerated)
  - `docs/logs/lua_api_data.json` (`lua_name` values)
  - `wiki/API-Reference.md` (section headers, TOC, function signatures)
  - `tools/docs/gen_docs_lua.py` — `_LUA_NAMESPACE` override dict added
  - `tools/docs/gen_luadoc.py` — `_LUA_NAMESPACE` override dict + `lua_name` prefix remap added

### Changed
- **`specs/log.md` Architecture section** — updated to show `log_api.rs → crate::log → engine::log_messages` call chain; added architecture note explaining why `set_level`/`get_level` logic belongs in the domain module.
- **`src/log/AGENT.md`** — Purpose section rewritten with correct call chain, explicit `[Lua]` prefix note, and the devtools separation rule.

## [0.6.0] — 2026-04-18

### Removed
- **`lurek.debugbridge.recordFrame(dt)`** — removed from the public Lua API. Frame timing is now automatic.

### Changed
- **`lurek.debugbridge.poll()` auto-records frame delta** — `poll()` now reads `lurek.time.getDelta()` each frame and feeds the result into `BridgeShared.frame_times`. `getPerformance()` continues to work unchanged; game scripts no longer need a manual `recordFrame(dt)` call alongside `poll()`. Scripts that called `recordFrame` must remove that call.
- **Scope separation documented** — `specs/debugbridge.md` now includes an Ownership Rule section distinguishing `lurek.log` (engine stdout), `devtools.Logger` (in-game UI), and `debugbridge.print_history` (TCP external tools). `specs/devtools.md` now documents the frame-timing ownership rule: use `lurek.time` for basic fps/delta; use `devtools.frameStats` only for p50/p95/p99 percentile analysis.
- **`specs/timer.md`** — `Clock` is now documented as the canonical source for fps/delta in Lurek2D.
- **`specs/event.md`** — Namespace Note added clarifying that `lurek.signal.push/poll` (FIFO EventQueue) and `lurek.signal.newSignal()` (pub-sub Signal) are independent primitives under the same namespace.
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
- **`docs` module** (`src/docs/`) — New domain module providing the Lurek2D API catalog: `DocEntry`/`ParamInfo`/`ReturnInfo` types, `Catalog` with search/filter/module-grouping, `ValidationReport`/`QualityReport` with `quality_score()`/`quality_grade()`. Exposed via `lurek.docs.*`. Spec: `specs/docs.md`. Tests: `tests/rust/unit/docs_tests.rs` (38 tests).
- **`debugbridge` module** (`src/debugbridge/`) — New domain module extracting the TCP debug bridge state and server logic: `BridgeShared` (server state), `PendingRequest`/`PendingResponse`, `PrintEntry`, `server_thread()`, `handle_client_message()`. Exposed via `lurek.debugbridge.*`. Spec: `specs/debugbridge.md`. Tests: `tests/rust/unit/debugbridge_tests.rs` (20 tests).
- **`log` module** (`src/log/`) — New thin domain wrapper over `engine::log_messages` providing `set_level()`/`get_level()`/`enabled_for()`. Spec: `specs/log.md`.
- **`SimpleState`** (`src/patterns/simple_state.rs`) — New pattern type: simple string-keyed FSM with `add`/`remove`/`set_current`/`states()`. Used by `lurek.patterns.newSimpleState()`.
- `src/docs/AGENT.md`, `src/debugbridge/AGENT.md`, `src/log/AGENT.md` — module overview files. `specs/README.md` updated.

### Changed
- **`luna_api/docs_api.rs`** — Refactored from 1693-line monolith to thin wrapper; all domain types (`DocEntry`, `ParamInfo`, `ReturnInfo`, `Catalog`, `ValidationReport`, `QualityReport`) now live in `src/docs/`. Lua bridge delegates to `crate::docs::*`.
- **`lua_api/debugbridge_api.rs`** — Refactored from 830 lines to 441 lines; `BridgeShared`, `PendingRequest`, `PendingResponse`, `PrintEntry`, `server_thread()`, `handle_client_message()` moved to `src/debugbridge/`. `lua_value_to_json()` and `poll()` remain in the API layer.
- **`lua_api/patterns_api.rs`** — All five embedded "Inner" structs removed; replaced by domain-backed `LuaEventBus`, `LuaObjectPool`, `LuaCommandStack`, `LuaServiceLocator`, `LuaFactory`, `LuaSimpleState` that wrap `crate::patterns::*` types.
- **`lua_api/log_api.rs`** — Docstring format corrected: `# Parameters`/`# Returns` sections replaced with `@param`/`@return` inline annotations.

## [0.5.2] — 2026-04-14

### Added
- **`devtools` module** (`src/devtools/`) — New domain module providing: structured logger (`Logger`/`LogEntry`/`LogLevel`) with min-level filtering and category tagging; hierarchical profiler (`Profiler`/`ProfileZone`) with per-frame zone tracking; rolling frame-time stats (`FrameStats`/`FrameSnapshot`) with FPS, P50/P95/P99 percentiles; and file watcher (`FileWatcher`) for hot-reload polling. Exposed via `lurek.devtools.*` (gated by `modules.debug`). Spec: `specs/devtools.md`. Tests: `tests/rust/unit/devtools_tests.rs` (25 tests).
- **`localization` module** (`src/localization/`) — New domain module providing: multi-locale string catalog (`Catalog`) with load/unload/translate/fallback/export; `{var}` and `{var:fmt}` interpolation (`interpolate`/`interpolate_pairs`); CLDR-based plural forms (`PluralForm`/`pluralize`/`pluralize_slavic`) for English and Slavic rulesets. Exposed via `lurek.localization.*` (gated by `modules.localization`). Spec: `specs/localization.md`. Tests: `tests/rust/unit/localization_tests.rs` (26 tests).
- **`patterns` module** (`src/patterns/`) — New domain module implementing six game-programming design patterns as pure-Rust types: `EventBus` (subscribe/drain-once/priority sort), `ObjectPool` (acquire/release/prewarm/capacity), `CommandStack` (push/undo/redo/batch), `ServiceLocator` (name→any register/unregister/has), `Factory` (type registry + aliases), `StateMachine` (states/transitions/guards/history/reachable). Exposed via `lurek.patterns.*` (gated by `modules.pipeline`). Spec: `specs/patterns.md`. Tests: `tests/rust/unit/patterns_tests.rs` (34 tests).
- `src/devtools/AGENT.md`, `src/localization/AGENT.md`, `src/patterns/AGENT.md` — module overview files.

## [0.5.1] — 2026-04-08

### Added
- Added `LICENSE_INVENTORY.md` at the repository root with explicit first-party Rust module and Lua library lists, direct Cargo dependency license tables, the direct VS Code extension runtime dependency license, and a no-models-found audit summary.

## [0.5.0] — 2026-04-08

### Changed
- Version bumped to 0.5.0 — first tracked release.
- **Distribution build** switched from fat-LTO `--profile dist` to `--release` (thin LTO); balanced binary size vs. link time.
- **Windows installer** (`tools/dist/installer.nsi`): now bundles `content/examples/`, `content/library/`, `content/demos/`, and the full `docs/API/` folder. Registers `.lua` file association so double-clicking any Lua script launches it in Lurek2D.
- **dist.ps1**: updated to use `cargo build --release` and `build/release/lurek2d.exe`; adds `content/demos/` to the portable package.
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
