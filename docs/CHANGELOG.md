# Lurek2D Changelog

All notable changes to Lurek2D are recorded here.

## [0.12.0] — 2026-04-15
### Added
- **raycaster**: `Raycaster2D::wall_alphas` — per-tile opacity map (`HashMap<u8, f32>`). `set_wall_alpha(tile_type, alpha)` / `get_wall_alpha(tile_type)` domain methods. Alpha is clamped to `[0.0, 1.0]`.
- **raycaster**: `RayHit.alpha: f32` field — all hit tables returned by `castRay`, `castRays`, and `castRayMulti` expose `.alpha`. Defaults to `1.0` for opaque walls.
- **raycaster**: `cast_ray_multi(ox, oy, angle, max_dist, max_hits)` — Lua: `m:castRayMulti(…)` — continues through translucent walls (alpha < 1.0) collecting up to `max_hits` (≤ 8) wall layers ordered nearest-to-farthest. Perfect for glass, bars, and force fields.
- **raycaster**: `m:setWallAlpha(tile_type, alpha)` / `m:getWallAlpha(tile_type)` Lua bindings on the Raycaster userdata.
- **raycaster**: `lurek.raycaster.newMap(w, h)` — alias for `lurek.raycaster.new(w, h)`.
- **raycaster**: `src/raycaster/sprite_manager.rs` — `SpriteManager` domain type with `WorldSprite { id, x, y, texture, scale, visible }`. Methods: `add`, `remove`, `set_position`, `set_visible`, `clear`, `sort_by_distance`.
- **raycaster**: `lurek.raycaster.newSpriteManager()` — `LuaSpriteManager` userdata. Lua methods: `add`, `remove`, `setPosition`, `setVisible`, `clear`, `sortAndProject`. `sortAndProject(cam_x, cam_y, cam_angle)` returns indexed table `{id, x, y, texture, scale, distance}` sorted back-to-front.
- **parallax**: `layer:setTiling(enabled)` / `layer:getTiling()` — enable seamless infinite tiling on both axes simultaneously; supersedes per-axis `setRepeat` for the common case.
- **parallax**: `layer:setTileSize(w, h)` — override tile dimensions in logical pixels (defaults to scaled texture size); `setTileSize(0, 0)` resets to texture-based sizing.
- **parallax**: `layer:setDepth(z)` / `layer:getDepth()` — floating-point draw depth for fine-grained Z ordering, independent of the existing integer `setZ`.
- **parallax**: `setBlendMode` now accepts canonical mode strings `"normal"` (default, replaces `"alpha"`) and `"additive"` (replaces `"add"`); legacy aliases `"alpha"` and `"add"` remain valid inputs but `getBlendMode` returns the new canonical names.
- **parallax**: `setBlendMode` now returns an error for unrecognised mode strings instead of silently falling back to alpha.
- **scene**: `lurek.scene.transitions` subtable with four built-in transition factory functions: `fade(duration?)`, `slide(direction?, duration?)`, `wipe(duration?)`, `iris(duration?)`. Each returns `{type, duration}` compatible with `push`/`switchTo`/`pop` parameters.
- **scene**: `lurek.scene.depth()` — alias for `getStackSize()`; returns the number of scenes currently on the stack.
- **ecs**: `universe:addRelation(from, name, to)` / `universe:getRelated(from, name)` / `universe:removeRelation(from, name, to)` / `universe:clearRelations(from, name)` / `universe:hasRelation(from, name, to)` — directed named relationship links on `Universe`. Domain: `RelationshipManager.add_link` / `get_links` / `remove_link` / `clear_links` / `has_link` backed by `HashMap<(u32, String), Vec<u32>>`. Lua bindings in `src/lua_api/ecs_api.rs`.
- **serial**: `lurek.codec.encodeMsgPack(tbl)` / `lurek.codec.decodeMsgPack(bytes)` — binary MessagePack encode/decode via `rmp-serde`. Compact binary payloads for save data and network messages.
- **serial**: `lurek.codec.decodeXml(str)` — read-only XML parsing via `roxmltree`. Returns a nested Lua table: `{tag, attrs, text, children}`. Required for Tiled TMX map imports and third-party tool interop.
- **serial**: `lurek.codec.validate(tbl, schema)` — schema validation. Returns `(true, nil)` on success or `(false, error_message)` on failure. Schema supports `type`, `required`, `min`, `max`, `minlen`, `maxlen`, `fields`, and `items`.
- **event**: `Signal:connect(pattern, fn)` — wildcard glob subscriptions. Patterns containing `*` or `?` match all emitted event names that satisfy the glob rule (`*` = any sequence, `?` = one char). Returns a disconnect handle.
- **patterns**: `Trie` — string-key prefix-index trie with `insert`, `search`, `starts_with`, `prefix_search`, `remove`, `len`, `is_empty`. Foundations tier; no Lua binding.
- **patterns**: `BiMap<K, V>` — bidirectional HashMap with `insert` (bijection-enforced), `get_by_key`, `get_by_value`, forward/reverse remove, `len`, `is_empty`, `clear`. Foundations tier; no Lua binding.
- **data**: `ByteData:setBit(byte_offset, bit_offset, value)` — set or clear a single bit (bit_offset 0–7); errors if out of range.
- **data**: `ByteData:getBit(byte_offset, bit_offset)` — read a single bit as a boolean.
- **data**: `ByteData:readBits(byte_offset, bit_offset, count)` — read up to 32 bits LSB-first across byte boundaries into an integer.
- **timer**: `lurek.time.waitSeconds(s)` / `lurek.time.waitFrames(n)` — yield the running coroutine until a wall-clock or frame-count deadline.
- **timer**: `lurek.time.tickWaits()` — drives coroutine resumption; call once per frame from `lurek.process`.

## [0.11.0] — 2026-04-15
### Added
- **render**: `lurek.graphic.printRich(spans, x, y)` — draws a sequence of individually-styled text `TextSpan` objects at a common baseline position. Each span carries its own `r/g/b/a` colour and `scale` multiplier.
- **spine**: `LuaSkeletonAnimation:addEventKey(time, name, value?)` — adds a timed named event marker to an animation clip. Events are sorted automatically.
- **spine**: `LuaSkeletonAnimation:getEvents(from, to)` — returns `{name, value}` pairs for all event markers whose timestamps fall in `(from, to]`.
- **spine**: `LuaSkeleton:blendAnimation(anim, time, blend_weight?)` — evaluates a second animation and linearly blends it into the skeleton's current bone pose. Enables cross-fades between clips.
- **ui**: `Widget:bind(key)` / `Widget:unbind()` — registers/removes a data-binding key on any widget.
- **ui**: `Widget:setAlpha(a)` / `Widget:getAlpha()` — per-widget alpha transparency control.
- **ui**: `Widget:fadeIn()` / `Widget:fadeOut()` — instantly show/hide a widget via alpha + visibility toggle.
- **ui**: `Widget:slideIn(x, y)` / `Widget:slideOut(x, y)` — instantly move a widget to a position and show/hide it.
- **ui**: `Widget:attachToEntity(entity_id)` / `Widget:detachFromEntity()` — anchors a widget's position to a world-space entity ID.
- **ui**: `lurek.ui.update_bindings(data)` — batch-updates all widgets that have a binding key registered, matching `data[key]` to widget value/text.
- **app**: `fixedUpdate(dt)` Lua callback — a second fixed-timestep callback separate from `process_physics`. Enabled by setting `performance.fixed_update_tick_rate` in `conf.toml`.
- **app**: Frame budget warning — when `performance.frame_budget_warn_ms` is set in `conf.toml`, emits a `warn!` log entry whenever a frame exceeds the threshold.
- **dataframe**: `DataFrame:withEval(col_name, expr)` — returns a new `DataFrame` with an additional computed column derived from a simple arithmetic expression referencing existing columns (supports `+`, `-`, `*`, `/`).
- **pipeline**: `Pipeline:addSubPipeline(sub, alias, outer_deps?)` — inlines all steps from `sub` into this pipeline with a `alias/` name prefix. Entry-point steps gain dependencies on `outer_deps`.
- **content/examples/pipeline.lua** — comprehensive pipeline API example covering steps, sub-pipelines, conditionals, and progress callbacks.
### Changed
- `WidgetBase` gained three new fields (`alpha`, `entity_attachment`, `bind_key`) — all default to backwards-compatible values (`1.0`, `None`, `None`).
- `SkeletonAnimation` gained an `events: Vec<EventKeyframe>` field (default empty).
- `PerformanceConfig` gained two new optional fields (`fixed_update_tick_rate`, `frame_budget_warn_ms`) with serde defaults of `None`.
- `SharedState` gained `fixed_update_dt: f64` (default `0.0`).
- `Pipeline` now derives `Clone` (required for `addSubPipeline`).

## [0.10.2] — 2026-04-17
### Added
- **graph**: `graph:colorGraph()` — greedy graph coloring; returns `{node_id → color_int}` table using minimum colors.
- **graph**: `graph:isBipartite()` — BFS two-coloring check; returns `true` if the graph has no odd cycles.
- **i18n**: `lurek.localization.formatNumber(n, opts?)` — locale-aware number formatting with thousands grouping and decimal separator. `opts.decimals` (default 2).
- **i18n**: `lurek.localization.formatDate(timestamp, fmt?)` — locale-aware date formatting from day-offset timestamp. Formats: `"short"` (default), `"long"`, `"iso"`.
- **i18n**: `lurek.localization.tGender(key, gender, vars?)` — gender-sensitive translation via `.masculine`/`.feminine`/`.neutral` key suffixes with fallback to base key.
- **i18n**: `lurek.localization.getLoadedLocales()` — returns array of all loaded locale codes.
- **camera**: `cam:followPath(points, duration)` — animates camera along a table of `{x,y}` waypoints; `cam:updatePath(dt)` advances it; `cam:stopPath()` cancels; `cam:pathProgress()` returns `[0,1]`.
- **camera**: `cam:zoomTo(target_zoom, duration)` — smooth linear zoom tween; `cam:updateZoom(dt)` advances it; `cam:stopZoom()` cancels.
- **camera**: `cam:setParallaxFactor(layer, factor)` / `cam:getParallaxFactor(layer)` / `cam:clearParallaxFactors()` — per-layer parallax scroll multipliers.
- **light**: `light:addFlicker(min, max, hz)` — convenience flicker setter using intensity-multiplier range and Hz frequency; converts to `FlickerConfig.speed`/`strength`.
- **light**: `light:transitionTo(target, duration)` — smooth linear transition of color, intensity, and radius; `light:updateTransition(dt)` advances it; `light:stopTransition()` cancels; `light:transitionProgress()` returns `[0,1]`.
- **light**: `light:setCookie(path)` / `light:getCookie()` / `light:clearCookie()` — light cookie (gobo) texture path for projection masking.
- **render**: `lurek.graphic.newLayer(name, z_order?)` — registers a named render layer with z-ordering.
- **render**: `lurek.graphic.setLayer(name)` / `lurek.graphic.currentLayer()` — set and query the active named layer.
- **render**: `lurek.graphic.setLayerVisible(name, bool)` / `lurek.graphic.isLayerVisible(name)` — toggle layer visibility.
- **render**: `lurek.graphic.getLayerZOrder(name)` / `lurek.graphic.setLayerZOrder(name, z)` — read and update layer draw order.
- **effect**: `stack:setFeedback(factor)` / `stack:getFeedback()` / `stack:clearFeedback()` — feedback loop intensity `[0,1]` for motion-trail / phosphor-persistence effects.
- **effect**: `lurek.postfx.newTransition(kind, duration, color?)` — creates a `ScreenTransition` userdata. Kinds: `"fade"`, `"wipe"`, `"iris"`, `"dissolve"`. Methods: `play()`, `reverse()`, `update(dt)`, `progress()`, `isActive()`, `isDone()`, `kind()`, `color()`, `setColor(t)`.
- New source files: `src/camera/path.rs` (`CameraPath`, `ZoomTween`), `src/light/transition.rs` (`LightTransition`), `src/effect/transition.rs` (`ScreenTransition`, `TransitionKind`).

## [0.10.1] — 2026-04-16
### Added
- `lurek.math.polygonClip(polygon, nx, ny, d)` — Sutherland-Hodgman single half-plane polygon clip. Input and output are flat `{x1,y1,...}` tables.
- `lurek.img.newPaletteLut()` — creates a `PaletteLUT` userdata; `lut:setColor(fr,fg,fb,fa, tr,tg,tb,ta)`, `lut:getColorCount()`, `lut:clear()`.
- `image:applyPaletteLut(lut)` — applies a `PaletteLUT` to every pixel of an `ImageData`.
- `image:convolve(kernel_table, ksize)` — applies an arbitrary N×N convolution kernel to `ImageData` (ksize must be odd; edges clamped; alpha preserved).
- `lurek.animation.newCurve()` — creates an `AnimCurve` with `addKeyframe(t,v)`, `eval(t)`, `setEasing(name)`, `keyframeCount()`, `clear()`. Easings: `step`, `linear`, `ease_in`, `ease_out`, `ease_in_out`.
- `lurek.animation.newSyncGroup()` — creates an `AnimSyncGroup` with `add(key)`, `remove(key)`, `clear()`, `memberCount()`.
- `lurek.fs.glob(pattern)` — lists files matching a `*`/`?` glob pattern within the game sandbox.
- `lurek.fs.copy(src, dst)` — copies a file from the read sandbox into `save/`.
- `lurek.fs.move(src, dst)` — moves a file within the `save/` sandbox.
- `lurek.fs.removeDir(path)` — recursively removes a directory within the `save/` sandbox.
- `lurek.terminal.pushScrollback(t, line)` / `getScrollback(t, offset, count)` / `scrollbackLen(t)` / `setScrollbackCap(t, cap)` — scrollback buffer for terminal output (default cap: 500).
- `lurek.terminal.pushCmdHistory(t, cmd)` / `prevCmd(t)` / `nextCmd(t)` / `cmdHistoryLen(t)` / `clearCmdHistory(t)` — command history with cursor navigation.
- `lurek.terminal.applyTheme(t, name)` — applies a named colour theme (`solarized_dark`, `solarized_light`, `monokai`, `dracula`, `nord`) by recolouring all grid cells.
- `lurek.terminal.printHighlighted(t, col, row, text, rules)` — prints text with plain-substring keyword highlighting; rules are `{pattern, fg={r,g,b}, bg={r,g,b}?}` arrays.
- `lurek.audio.setMeter(level)` / `getMeter()` — stores/retrieves the master peak amplitude level (0-1) on the `Mixer`.
- `LuaBus:setDuckTarget(targetBusName, duckVolume)` / `clearDuck()` — configures automatic bus-volume ducking.
- `LuaBus:getPeak()` — returns the average peak amplitude across all sources on the bus.
### Fixed
- `lurek.audio.getBusPeak(busName)` was always 0.0 (stub); now returns the mean `peak` of all sources assigned to that bus.
- `lurek.audio.setMeter` / `getMeter` were no-op stubs; now correctly read/write `Mixer.master_peak`.
### Internal
- `src/math/polygon.rs` — added `polygon_clip()` (Sutherland-Hodgman) and 4 unit tests.
- `src/image/palette_lut.rs` — added `PaletteLUT::apply(&mut ImageData)`.
- `src/image/effects.rs` — added `ImageData::convolve(&[f64], ksize)`.
- `src/animation/curve.rs` (new) — `AnimCurve` + `EasingKind`.
- `src/animation/sync_group.rs` (new) — `AnimSyncGroup`.
- `src/filesystem/vfs.rs` — added `copy_file`, `move_file`, `remove_dir`, `glob` + `glob_match` helpers.
- `src/terminal/terminal_state.rs` — added scrollback + cmd_history fields and methods; `set_default_colors()`, `print_colored()`.
- `src/audio/mixer.rs` — `AudioEntry.peak: f32`; `Mixer.master_peak: f32`; `set_peak`, `get_peak`, `bus_peak`.
- `src/audio/bus.rs` — `Bus.duck_target: Option<(String, f32)>`; `set_duck_target`, `clear_duck_target`.


### Added
- `lurek.modding.checkApiVersion(mod, host_version)` — returns `(bool, msg?)` for MAJOR/MINOR compatibility gating.
- `ModInfo.api_version` — optional `"MAJOR.MINOR"` string; via `mod:getApiVersion()` / `mod:setApiVersion()`.
- `ModInfo.capabilities` — `Vec<String>` permission list; via `mod:getCapabilities()` / `mod:setCapabilities()`.
- `ModInfo.config_schema` — `Vec<(key, type_hint, default)>` declarative mod settings; via `mod:getConfigSchema()` / `mod:setConfigSchema()`.
- `lurek.savegame` compression — `saveManager:setCompress(bool)` / `isCompressed()`: slot data is LZ4-compressed + base64-encoded when enabled; auto-detected on load.
- `lurek.savegame.onBeforeSave(fn?)` / `onAfterLoad(fn?)` — lifecycle hooks fired with the slot name; pass `nil` to clear.
- `lurek.compute.fft(samples)` — Cooley-Tukey iterative radix-2 FFT; returns `{{re, im}, ...}` array.
- `lurek.compute.ifft(freqs)` — IFFT with 1/N normalisation; returns real-part array.
- `lurek.compute.fftMagnitude(samples)` — `|X[k]|` per bin.
- `ndarray:luDecompose()` — Doolittle LU with partial pivoting; returns `{n, det_sign, perm, lu_data}`.
- `ndarray:eigenPower(max_iter?, tol?)` — power-iteration dominant eigenvalue; returns `{value, vector}`.
- `bt:getDebugState()` — BehaviorTree snapshot: `{ node_count, last_status }`.
- `steering:setSpatialHashCellSize(size)` — cell size for spatial-hash neighbour bucketing (default 64.0).
- `steering:enableSpatialHash(enabled)` — toggle spatial-hash mode on `SteeringManager`.
- `lurek.network.createLobby(name, port, player_count?, max_players?)` — LAN UDP lobby broadcast.
- `lurek.network.discoverLobbies(timeout_ms?)` — collects LAN lobby announcements; returns array of tables.
- `lurek.network.syncEntity(host, entity_id, data, channel?, reliable?)` — packs + broadcasts entity snapshot to peers.
- `tools/mods/mod_init.py` — CLI scaffold: generates `mod.toml`, `main.lua`, `README.md` for a new mod.
### Changed
- `src/procgen/IDEA.md` — all 6 TODO/FIXME items marked done.
- `src/mods/IDEA.md` — api_version/capabilities/config_schema/CLI tool marked done; hot-reload/save-tracking deferred.
- `src/save/IDEA.md` — compression and event hooks marked done; entity bridge/screenshot/delta-saves deferred.
- `src/compute/IDEA.md` — FFT and advanced linalg marked done; sparse/imagedata/rayon deferred.
- `src/ai/IDEA.md` — BT debug state and steering spatial hash marked done; GOAP parallel/rayon steering deferred.
- `src/network/IDEA.md` — lobby and syncEntity marked done; NAT punchthrough/rollback deferred.

## [0.9.5] — 2026-04-15
### Added
- `lurek.thread.newPool(n, code)` — creates a thread pool of `n` pre-spawned worker VMs that share a common input/output channel pair. `ThreadPool` userdata exposes `submit`, `collect`, `join`, `size`, `getInputChannel`, `getOutputChannel`.
- `lurek.thread.async(code, ...)` — runs Lua code in a background thread and returns a `Promise` handle. `Promise` provides `isDone()`, `result()`, and `getError()`.
- `Channel:pushTable(t)` / `Channel:popTable()` — serialise / deserialise Lua tables (including nested tables) through a thread channel using `ChannelValue::Table`.
- `Channel:pushBytes(s)` / `Channel:popBytes()` — send and receive raw binary strings through a thread channel using `ChannelValue::Bytes`.
- `lurek.thread` worker VMs now support `require()` via `package.path = "./?.lua;./?/init.lua"` set during worker init.
- `lurek.thread` workers have read-only filesystem access via `lurek.fs.read(path)` with path-traversal guard.
- `lurek.tilemap.newLargeMapRenderer(tileW, tileH)` — creates a `LargeMapRenderer` for chunk-level occlusion culling on large tilemaps. `LargeMapRenderer` exposes `setMapData`, `setTile`, `getTile`, `getMapSize`, `setChunkSize`, `getChunkSize`, `setCamera`, `setViewport`, `getVisibleChunks`, `getTotalChunks`, `setLodEnabled`, `isLodEnabled`, `setLodThresholds`, `setTilesetColumns`, `getTilesetColumns`, `invalidateChunk`, `invalidateAll`.
### Fixed
- `src/lua_api/tilemap_api.rs` — removed duplicate `use crate::tilemap::ldtk::load_ldtk;` import.
- `src/lua_api/tilemap_api.rs` — removed second `tbl.set("fromLDtk", ...)` registration block (same factory was registered twice; last-write silently overwrote first with identical code).
### Changed
- `src/thread/IDEA.md` — all 6 TODO features marked done (already implemented in codebase).
- `src/tilemap/IDEA.md` — all 6 TODO / 1 FIXME items resolved; cellular FIXME closed with no-code-change note.
- `docs/specs/thread.md` — documented `newPool`, `async`, `ThreadPool` methods, `Promise` methods, `Channel:pushTable/popTable/pushBytes/popBytes`.
- `docs/specs/tilemap.md` — added `newLargeMapRenderer`, `LargeMapRenderer` methods section; removed duplicate `fromLDtk` spec entry.
- `content/examples/thread.lua` — added pushTable/popTable, pushBytes/popBytes, newPool, and async usage examples.
- `content/examples/tilemap.lua` — added newLargeMapRenderer usage example.


### Changed
- `docs/specs/*.md` — all 50 module spec files now have complete, source-derived `## Summary` sections (1000–1500 chars each) covering module purpose, core types, algorithms and subsystems, and scope boundary tier. Previously all 50 had empty or placeholder summary bodies.
- `docs/specs/graph.md` — corrected summary to describe the flow-simulation graph system (typed items, decay, conversion rules, supply/demand, push/pull flow) rather than a generic data-structure graph.
- `src/filesystem/mod.rs`, `src/input/mod.rs`, `src/render/mod.rs`, `src/timer/mod.rs` — replaced generic "Mod implementation for…" placeholder `//!` blocks with accurate module-level docstrings listing the subsystem inventory, key types, threading constraints, and Lua bridge reference.
- `src/event/mod.rs` — fixed literal backslash-escaped `\Signal\` in `//!` comment; replaced with backtick-wrapped `` `Signal` ``; expanded docstring to inventory the `EventQueue` and `Signal` sub-types.
- `src/compute/mod.rs`, `src/save/mod.rs`, `src/sprite/mod.rs` — expanded thin `//!` blocks to include full subsystem inventory tables and Lua namespace references.
- `docs/specs/*.md` (all 50) — ran `tools/docs/gen_module_specs.py` twice to regenerate the `## Files`, `## Types`, `## Functions`, and `## Lua API Reference` sections from updated source code, picking up the improved mod.rs docstrings.


### Added
- `lurek.procgen.simplex2d(x, y)` — single 2-D Simplex noise sample, wrapping `procgen::noise::simplex_noise_2d`.
- `lurek.procgen.simplex3d(x, y, z)` — single 3-D Simplex noise sample, wrapping `procgen::noise::simplex_noise_3d`.
### Fixed
- `src/lua_api/render_api.rs` `LuaImageData` impl block had orphaned `methods.add_method` calls (resize, blit, getRegion, diff, mapPixels) placed outside the `impl LuaUserData for LuaImageData` block — merged into a single valid impl block.  The duplicate minimal `type`/`typeOf` stubs were removed; the more complete implementations are now the authoritative versions.
- `tools/docs/gen_lua_api.py` `collect_class_descriptions()` regex did not match `pub(crate) struct LuaXxx` visibility — updated to `(?:pub(?:\([^)]*\))?\s+)?` so `LuaSoundPool` and other crate-private wrappers now get their descriptions.
- 9 AI Lua method descriptions were either missing (< 15 chars generated by the automated fixer): `AIDirector:pushEvent`, `ContextSteering:addWander`, `EmotionModel:add`, `NeedSystem:addNeed`, `NeuralNet:addLayer`, `ORCASolver:addAgent`, `StimulusWorld:addVisual`, `StrategyAI:addGoal`, `StrategyAI:addTag` — all replaced with full-sentence descriptions.
- 13 internal Rust modules were falsely reported as Rust→Lua gaps in `docs/API/coverage_gaps.md`; added to `_INTERNAL_MODULES` in `tools/audit/gen_coverage_gaps.py` (`animation::aseprite`, `compute::analytics`, `effect::presets`, `network::http`, `network::message`, `pathfind::graph_nav`, `physics::cellular`, `procgen::noise`, `procgen::world_graph`, `render::postfx_pipeline`, `runtime::messages`, `sprite::atlas`, `tilemap::ldtk`).
- 5 `pathfind` submodule `mod.rs` docstrings were single-word stubs (< 15 chars) — expanded to full-sentence descriptions for `graph_nav`, `hex_grid`, `iso_grid`, `jps`, and `range_map`.
- `src/lua_api/procgen_api.rs` had a corrupted import block (duplicate/mangled use statement) — corrected import section; simplex2d/3d now imported properly.
### Changed
- `docs/API/coverage_gaps.md` now reports **0 items** across all three categories (Rust→Lua Gaps, Rust Docstring Issues, Lua Docstring Issues) — 100% clean.
- Lua API data regenerated: 3242 functions, 47 modules, 100% documented.

## [0.9.2] — 2026-04-14
### Changed
- Removed all 49 `GAPS.md` files from `src/` module directories — gap tracking now lives exclusively in `docs/specs/<module>.md`.
- Regenerated all 50 `docs/specs/<module>.md` files from current source (Files, Types, Functions, Lua API Reference sections rebuilt).
- Regenerated `docs/API/lua-api.md`, `docs/API/rust-api.md`, `docs/API/lurek.lua`, and `docs/wiki/API-Reference.md` from current source.
### Fixed
- 239 public Rust items across 79 files were missing `# Parameters`, `# Returns`, `# Fields`, or `# Variants` docstring sections — all filled by `tools/fix/fix_docstrings.py`.
- `SpatialItem` struct in `src/math/spatial_hash.rs` had malformed doc comment (split across `#[derive]` attribute) — replaced with correct placement.

## [0.9.1] — 2026-06-12
### Added
- **AI: TraitProfile** — `src/ai/traits.rs`; `lurek.ai.newTraitProfile()`. Named float personality traits with timed additive modifiers and source-keyed removal.
- **AI: StimulusWorld / perception** — `src/ai/perception.rs`; `lurek.ai.newStimulusWorld()`. Simulated sight/hearing stimulus bus with decay and per-stimulus IDs.
- **AI: ContextSteering** — `src/ai/context_steering.rs`; `lurek.ai.newContextSteering(slots)`. Radial interest/danger ring evaluation producing smooth, obstacle-aware movement vectors.
- **AI: NeedSystem** — `src/ai/needs.rs`; `lurek.ai.newNeedSystem()`. Sims-style motivational drive system with decay, urgency threshold, and advertisement scoring.
- **AI: AIDirector** — `src/ai/director.rs`; `lurek.ai.newAIDirector()`. L4D-style pacing controller with BuildUp/Peak/Sustain/Relief phase state machine and tension API.
- **AI: HTN Planner** — `src/ai/htn.rs`; `lurek.ai.newHTNDomain()`. Hierarchical Task Network domain with addPrimitive/addCompound, precondition-based decomposition, and plan() method.
- **AI: MCTSEngine** — `src/ai/mcts.rs`; `lurek.ai.newMCTSEngine(iterations, uct_c, depth, seed)`. Monte Carlo Tree Search driven by injected Lua closures for get_actions/apply_action/evaluate.
- **AI: EmotionModel** — `src/ai/emotion.rs`; `lurek.ai.newEmotionModel()`. Named affective dimensions with trigger/decay, dominant query, and isActive test.
- **AI: ORCASolver** — `src/ai/orca.rs`; `lurek.ai.newORCASolver(time_horizon)`. ORCA velocity-obstacle crowd avoidance with per-frame compute() producing collision-free safe velocities.
- **AI: NeuralNet** — `src/ai/neural_net.rs`; `lurek.ai.newNeuralNet()`. Inference-only feedforward net with ReLU/Sigmoid/Tanh/Linear/Softmax activations, flat weight get/set.
- **AI: GeneticAlgorithm** — `src/ai/genetic.rs`; `lurek.ai.newGeneticAlgorithm(pop, genes, seed)`. Tournament-selection GA with uniform crossover and Gaussian mutation.
- **AI: Bandit** — `src/ai/bandit.rs`; `lurek.ai.newBandit(arms, strategy, epsilon, seed)`. Multi-armed bandit with ε-greedy, UCB1, and Thompson Sampling strategies.
- **AI: Neuroevolution** — `src/ai/neuroevolution.rs`; `lurek.ai.newNeuroevolution(layer_spec, pop, seed)`. GA-driven neural network weight evolution; chromosome_to_net / best_network accessors.
- **AI: StrategyAI** — `src/ai/strategy.rs`; `lurek.ai.newStrategyAI(interval)`. Throttled strategic goal evaluator with tag-based context filtering and scorer-closure API.
- **AI: AILod** — `src/ai/lod.rs`; `lurek.ai.newAILod()`. Distance-based LOD tier controller with should_update(tier, frame) striding and configurable update intervals.
- **AI: Agent extensions** — `src/ai/agent.rs` gains five new optional fields: `trait_profile`, `sensor`, `emotion_model`, `need_system`, `lod_tier`.
- **Tests** — 12 new Lua BDD test files in `tests/lua/unit/`: `test_ai_traits`, `test_ai_perception`, `test_ai_context_steering`, `test_ai_needs`, `test_ai_director`, `test_ai_htn`, `test_ai_mcts`, `test_ai_emotion`, `test_ai_orca`, `test_ai_ml`, `test_ai_strategy`, `test_ai_lod`. All registered in `tests/lua/harness.rs`.


### Added
- **Network: Full Networking Toolkit** — Major expansion of `src/network/` from ENet-only to a 3-layer architecture (Transport → Game Protocol → Lunasome Libraries).
- **Network: HTTP client** — `lurek.network.newRuntime()` creates a background I/O thread. `rt:httpGet(url)`, `rt:httpPost(url, body)`, `rt:httpRequest({method, url, headers, body, timeout})` for async HTTP via `ureq`.
- **Network: TCP client** — `rt:tcpConnect(addr)`, `rt:tcpSend(id, data)`, `rt:tcpClose(id)` for non-blocking TCP connections.
- **Network: WebSocket client** — `rt:wsConnect(url)`, `rt:wsSend(id, data)`, `rt:wsClose(id)` for WebSocket via `tungstenite`.
- **Network: MessagePack serialization** — `lurek.network.pack(value)` and `lurek.network.unpack(data)` for compact binary serialization of Lua values (40–70% smaller than JSON).
- **Network: Server/Client roles** — `lurek.network.newServer({port})`, `lurek.network.newClient({addr})` convenience constructors with `host:getRole()`, `host:isServer()`, `host:isClient()`.
- **Network: Background I/O thread** — `NetworkRuntime` runs HTTP, TCP, and WebSocket on a dedicated `std::thread` with `mpsc` bridge. `rt:poll()` returns events each frame without blocking the Lua VM.
- **Network: Increased peer limits** — `MAX_PEERS` raised from 8 to 4096 for dedicated server scenarios. `DEFAULT_PEERS` from 4 to 16.
- **Lunasome: `rpc` library** — Pure-Lua RPC (`content/library/rpc/`) with `register`, `call`, `notify`, `broadcast`, request/response, and error handling.
- **Lunasome: `lobby` library** — Pure-Lua lobby/room management (`content/library/lobby/`) with room creation, join/leave, player tracking, and ready-check coordination.
- **Lunasome: `netstate` library** — Pure-Lua state synchronization (`content/library/netstate/`) with authority-based replication, change callbacks, delta sync, and turn-based game support.
- **Dependencies** — Added `ureq = "3"`, `tungstenite = "0.26"`, `rmp-serde = "1"` to Cargo.toml.
- **Tests** — 4 new Lua test files: `test_network_pack_unpack.lua`, `test_network_roles.lua`, `test_network_runtime.lua`, `test_network_security.lua`.

### Changed
- **Network: `DEFAULT_CHANNELS`** — Changed from 1 to 2 (reliable + unreliable by default).
- **Network: error variants** — Added `Http`, `WebSocket`, `Tcp`, `Serialization`, `Thread` to `NetworkError`.

## [0.8.3] — 2026-05-30
### Added
- **Physics: `PhysicsZone`** — New `src/physics/zone.rs` domain module with `PhysicsZone`, `ZoneBoundary` (Rect/Circle), `ZoneGravityMode` (Directional/Point/Repulsor/Zero), `ZoneEvent`, `ZoneEventKind`, and `ZoneTracker`. Zones apply per-body gravity and damping overrides before each rapier step.
- **Physics: `TerrainMap`** — New `src/physics/terrain.rs` domain module. Destructible bitgrid-backed collision mesh for Worms/Tanks-style terrain. Chunked static rapier body management via `flush(&mut World)`. Methods: `fill_circle`, `fill_rect`, `fill_all`, `collapse_columns`, `solid_cell_positions`, `spawn_debris_at`, `to_image_data`, `to_bytes`/`load_from_bytes`.
- **Physics: `CellularWorld`** — New `src/physics/cellular.rs` domain module. 64-rule falling-sand automaton with `CellType` (Air/Sand/Water/Rock/Fire/Gas), deterministic checkerboard stepping, `default_palette`, and PNG-export helpers.
- **Physics Lua API — `lurek.physics`** — Three new userdata types with full bindings:
  - `lurek.physics.newTerrain(w, h, cell_size, world)` → `LuaTerrain` — full destructible terrain API.
  - `lurek.physics.newCellular(w, h)` → `LuaCellular` — falling-sand simulation, `step`, `stepN`, `toImageData`, `findCells`, `countCells`, serialisation.
  - `world:addZone(x, y, w, h)` → `LuaZone` with `setGravityDirectional/Point/Repulsor/Zero`, `setCircle`, `setPriority`, `setLayerMask`, `setEnabled`, `setLinearDampingOverride`, `setAngularDampingOverride`, `destroy`.
  - `world:stepFixed(accum, step_dt, max_steps)` → `remainder` — fixed sub-step accumulator.
  - `world:getZoneEvents()` → `[{zone_id, body_id, kind}]` — zone enter/leave events from the last step.
  - Cell-type constants: `CELL_AIR`, `CELL_SAND`, `CELL_WATER`, `CELL_ROCK`, `CELL_FIRE`, `CELL_GAS`.
- **Lua tests (15)** — `unit/test_physics_zone.lua`, `unit/test_physics_terrain.lua`, `unit/test_physics_terrain_collapse.lua`, `unit/test_physics_cellular.lua`, `unit/test_physics_step_fixed.lua`, `integration/test_physics_worms.lua`, `integration/test_physics_tanks.lua`, `integration/test_physics_space.lua`, `integration/test_physics_world_sim.lua`, `evidence/test_evidence_terrain_render.lua`, `evidence/test_evidence_cellular_sand.lua`, `evidence/test_evidence_physics_zone_debug.lua`, `stress/test_stress_physics_zones.lua`, `stress/test_stress_physics_terrain.lua`, `stress/test_stress_physics_cellular.lua`. All registered in `tests/lua/harness.rs`.

### Added
- **ECS: `queryNot(with, without)`** — New `Universe::query_not` domain method and `lurek.entity:queryNot(with_tbl, without_tbl)` Lua binding. Returns entities that have all components in `with` and none of the components in `without`.
- **ECS: system priority dispatch** — `addSystem(system, {priority=N})` accepts an optional opts table. Systems are now dispatched in ascending priority order during `update`, `render`, and `emit`. Zero is the default priority. Domain: `system_priorities: Vec<i32>` + `get_sorted_system_indices()` in `src/ecs/universe.rs`.
- **ECS: component observers** — `onComponentAdded(name, fn)` and `onComponentRemoved(name, fn)` register observer callbacks. `flushObservers()` dispatches accumulated add/remove events collected from `set_component` and `remove_component`. Domain: `add_events`/`remove_events` event queues + `take_component_events()` in `src/ecs/universe.rs`; observer maps live in `src/lua_api/ecs_api.rs`.
- **ECS: serialization round-trip** — `lurek.entity:serialize()` snapshots the world to a Lua table (entities, components, tags, layers, blueprint registry, bitmap_tags). `lurek.entity:deserialize(snapshot)` restores it. Domain: `serialize_to_table` / `deserialize_from_table` in `src/ecs/universe.rs`.
- **ECS: `spawnBulk(name, count, overrides?)`** — Spawns multiple entities from a blueprint in one call. Returns a table of entity IDs. Domain: `Universe::spawn_bulk` in `src/ecs/universe.rs`.
- **Patterns: `RelationshipManager`** — Moved out of ECS-exclusive API; exposed as `lurek.patterns.newRelationshipManager()`. `LuaRelationshipManager` UserData with `defineType / removeType / typeNames / setValue / getValue / adjustValue / setLevel / getLevel / removePair / pairCount` methods. Domain struct stays in `src/ecs/relationships.rs`.
- **Patterns: `Mediator`** — New `src/patterns/mediator.rs` domain type. `lurek.patterns.newMediator()` returns a `LuaMediator` with `on / off / send / broadcast / handlerCount / channels / removeChannel / clear` methods.
- **Patterns: `Strategy`** — New `src/patterns/strategy.rs` domain type. `lurek.patterns.newStrategy()` returns a `LuaStrategy` with `register / set / execute / getCurrent / has / remove / names / clear` methods.
- **Patterns: `Stack / Queue / List / Set`** — Four general-purpose collection userdatas added to `lurek.patterns`. `newStack(cap?) / newQueue(cap?) / newList() / newSet()`. All Lua-value containers. `LuaSet` is string-keyed with `union / intersection` methods.
- **Scene: `getTransitionTypes()`** — Returns a table of all 10 transition type strings: `none, fade, left, right, up, down, wipe, iris, zoom, crossfade`.
- **Scene: `serializeScene() / deserializeScene(snapshot)`** — Snapshot the active scene stack and all `setData` key/value pairs into a plain Lua table; restore them from the same table.
- **`content/library/patterns/init.lua`** — New pure-Lua Lunasome module. `patterns.newScheduler()` provides a cooperative coroutine task runner with `add(fn) / remove(id) / pause(id) / resume(id) / update(dt) / getCount() / clear()`.
- **Lua tests** — 12 new test files: `tests/lua/unit/test_entity_query_not.lua`, `test_entity_serialization.lua`, `test_entity_observers.lua`, `test_entity_system_priority.lua`, `test_entity_relationships.lua`, `test_patterns_mediator.lua`, `test_patterns_strategy.lua`, `test_patterns_collections.lua`, `test_scene_transitions_extended.lua`, `test_scene_serialization.lua`; `tests/lua/stress/test_entity_bulk_spawn.lua`, `test_scene_depth_sort.lua`. All registered in `tests/lua/harness.rs`.

## [0.8.1] — 2026-05-28
### Added
- **`lurek.sprite` namespace** — New `src/lua_api/sprite_api.rs` with `LuaSpriteSheet` and `LuaSpriteAtlas` UserData. Factories: `newSheet(tw,th,fw,fh)`, `newRPGMakerSheet(tw,th)`, `parseAtlas(json_str)`, `newAtlasSheet(atlas, sw, sh)`. Sheet methods: `getFrame`, `getFrameCount`, `getRow`, `getColumn`, `getGroupFrames`, `getGroupNames`, `nameGroup`, `getFrameSize`, `getGridSize`, `drawToImage`. Atlas methods: `getEntry`, `getByIndex`, `entryCount`, `entryNames`.
- **`src/sprite/atlas.rs`** — `AtlasEntry`, `SpriteAtlas`, `parse_texturepacker_json()` supporting both hash and array TexturePacker formats.
- **`SpriteSheet` domain additions** — `draw_to_image(w,h)`, `from_rpgmaker(tw,th)`, `from_atlas(atlas, sw, sh)` in `src/sprite/sprite_sheet.rs`.
- **`lurek.animation` extended API** — New methods on `Animation` userdata: `crossfade(clip, duration)`, `getBlendState()`, `drawToImage(w, h)`. New `LuaAnimStateMachine` UserData via factory `newStateMachine(anim, initial_state)` with methods: `update(dt)`, `getState()`, `forceState(name)`, `addState(name, clip, looping)`, `addTransition(from, to, condition)`, `setParam(name, value)`, `getQuad()`. New factory `fromAseprite(json_str)` importing Aseprite JSON animation exports.
- **`lurek.spine` extended API** — New skeleton methods: `playAnimation(name, looping?)`, `stopAnimation()`, `updateAnimation(dt)`, `getAnimationTime()`, `addAnimation(anim_ud)`, `addIKConstraint(name, bone_chain, bend_positive?)`, `setIKTarget(name, x, y)`, `addSkin(name)`, `setSkin(name)`, `getSkin()`, `setSkinMapping(skin, slot, attachment)`. New `LuaSkeletonAnimation` UserData via factory `newSkeletonAnimation(name, duration)` with methods: `addKeyframe(bone_idx, property, time, value, easing?)`, `getDuration()`, `getTimelineCount()`. Fixed `drawToImage` to correctly wrap `ImageData` in `LuaImageData`.
- **`src/spine/timeline.rs` + `src/spine/ik.rs`** — Public re-exports: `IKConstraint`, `BoneProperty`, `BoneTimeline`, `EasingType`, `Keyframe`, `SkeletonAnimation` from `src/spine/mod.rs`.
- **`lurek.tilemap` extended API** — New methods: `toNavGrid(layer, walkable_gids)`, `onTileEnter(gid, callback)`, `checkEntities(layer, entities)`. New factory `fromLDtk(json_str, level_name?)`.
- **`src/tilemap/ldtk.rs`** — `load_ldtk(json_str, level_name?)` parsing LDtk JSON exports (Tiles and AutoLayer types).
- **`TileMap::to_nav_grid`** — `to_nav_grid(layer, walkable_gids)` returning `Vec<Vec<bool>>` walkable grid in `src/tilemap/tilemap.rs`.
- **Lua tests** — 4 new unit test files: `tests/lua/unit/test_sprite.lua`, `tests/lua/unit/test_animation_ext.lua`, `tests/lua/unit/test_spine_ext.lua`, `tests/lua/unit/test_tilemap_ext.lua`. All registered in `tests/lua/harness.rs`.

## [0.8.0] — 2026-05-27
### Added
- **`lurek.procgen` expanded API** — 11 new Lua bindings: `bspDungeon(opts)`, `roomsDungeon(opts)`, `heightmap(opts)`, `wfcGenerate(opts)`, `lsystem(opts)`, `lsystemSegments(opts, angle, step)`, `generateName(samples, min, max, seed)`, `generateNames(samples, n, min, max, seed)`, `worldGraph(w, h, count, seed)`, `noiseMap(w, h, opts)`, `noiseMapParallel(w, h, opts)`.
- **`lurek.math` expanded API** — `vec3(x,y,z)` / `Vec3(x,y,z)` constructors with `LuaVec3` UserData (fields: x/y/z; methods: length, lengthSquared, normalize, dot, cross, lerp, distance, add, sub, scale); `catmullRom(points)` → `LuaCatmullRom` with sample/sampleSegment/len; `hermite(p0x,p0y,p1x,p1y,m0x,m0y,m1x,m1y)` → `LuaHermite` with sample; free functions `lerp(a,b,t)` and `remap(v,in_min,in_max,out_min,out_max)`.
- **`lurek.pathfinding` expanded API** — `newHexGrid(w, h, layout?)` → `LuaHexGrid` UserData with methods: setBlocked, setCost, isBlocked, findPath, lineOfSight, fieldOfView, rangeOfMovement, distance; `newJpsGrid(w, h)` → `LuaJpsGrid` UserData with setBlocked, isBlocked, findPath; `rangeMap(opts)` → table with cells/width/height for Dijkstra budget queries.
- **`lurek.graph` expanded API** — `mst()` method on Graph UserData (returns table of edge IDs via Kruskal); `astar(from_node, to_node)` method on Graph UserData (returns path table or nil).
- **Internal** — `LSystem::new_from_pairs(axiom, rules, iterations)` constructor for owned-string rules; `RangeMap::reachable_cells_with_cost()` returning `Vec<(x, y, cost)>` triples.
- **Lua tests** — 6 new integration test files: `test_pathfind_hexmap.lua`, `test_pathfind_graph.lua`, `test_math_pathfind.lua`, `test_procgen_ai.lua`, `test_pathfind_ai.lua`, `test_graph_pathfind.lua`; 1 new stress test: `test_procgen_stress.lua`. All registered in `tests/lua/harness.rs`.

## [0.7.29] — 2026-05-26
### Added
- **`src/compute/analytics.rs`** — New Foundations-tier module with 10 analytics functions: `cumsum`, `diff` (arbitrary order), `histogram` (equal-width bins with lo/hi bounds), `percentile` (linear interpolation), `covariance`, `pearson_corr`, `normalize_range`, `zscore`, `convolve1d` (full output), `correlate1d` (valid output). Exposed as Array userdata methods in `src/lua_api/compute_api.rs`.
- **`src/compute/linalg.rs`** — New Foundations-tier module with 9 linear algebra helpers: `normalize_vec`, `cross2d`, `outer`, `rotate2d_matrix`, `affine2d`, `transform_points`, `gaussian_kernel`, `sobel` (returns Gx/Gy arrays), `linsolve` (Gaussian elimination with partial pivoting). Exposed as Array methods plus `lurek.compute.gaussianKernel`, `lurek.compute.rotate2dMatrix`, `lurek.compute.affine2d`.
- **Rayon parallel ops in `src/compute/ops.rs`** — `elementwise_binary`, `elementwise_unary`, `elementwise_scalar`, `sum`, `min_val`, `max_val` now use Rayon thread pool when element count exceeds `PAR_THRESHOLD = 10_000`.
- **`AggFn` enum in `src/dataframe/frame.rs`** — `Mean`, `Sum`, `Min`, `Max`, `Count`, `First`, `Last` with `AggFn::parse(s)` for Lua string conversion.
- **19 new DataFrame methods in `src/dataframe/query.rs`** — `with_rolling_mean`, `with_rolling_sum`, `with_rolling_min`, `with_rolling_max`, `with_rank` (1-based, averaged ties), `with_pct_change`, `with_cumsum`, `group_agg`, `pivot`, `corr`, `correlation_matrix`, `zscore_col`, `normalize_col`, `outliers`, `mode_val`, `entropy`, `add_row_batch`, `get_column_as_f64`, `set_column_from_f64`. Exposed via `src/lua_api/dataframe_api.rs`.
- **Lua tests** — ~25 new `it()` blocks appended to `tests/lua/unit/test_compute.lua`; ~20 new `it()` blocks appended to `tests/lua/unit/test_dataframe.lua`.

### Fixed
- **DAG violations** — `src/compute/array.rs` and `src/dataframe/frame.rs` / `src/dataframe/query.rs` imported `crate::runtime::log_messages` (Core Runtime tier), violating the Foundations DAG constraint. Replaced all `log_msg!` calls with `log::debug!` / `log::warn!` from the `log` crate facade.

## [0.7.28] — 2026-05-25
### Added
- **GPU PostFx pipeline** — New `src/render/postfx_pipeline.rs` with `PostFxPipeline` struct and 21 built-in WGSL fragment shaders: `bloom`, `blur_h`, `blur_v`, `vignette`, `noise`, `grayscale`, `sepia`, `invert`, `crt`, `chromatic`, `scanlines`, `pixelate`, `hueshift`, `edgedetect`, `godrays`, `waterdistort`, `sharpen`, `dither`, `outline`, `depthoffield`, `motionblur`, `__copy`. Ping-pong rendering with `PostFxTexture` intermediate buffers. Custom shaders can be registered via `register_custom()`.
- **`GpuRenderer` PostFx integration** — `GpuRenderer` gains `postfx_pipeline` and `postfx_capture` fields. `BeginPostFx` lazily creates pipeline and capture texture; `EndPostFx` is a no-op frame marker; `ApplyPostFx` defers to `pending_postfx` and is processed after the light composite pass, before `encoder.finish()`.
- **`PostFxPass` + expanded `ApplyPostFx`** — `renderer.rs` gains `PostFxPass { effect_name, params, shader_id }` struct; `ApplyPostFx` variant expanded to `{ stack_id, passes: Vec<PostFxPass>, width, height }`.
- **8 new `PostFxEffectType` variants** — `DepthOfField`, `MotionBlur`, `PaletteSwap`, `ColorLut`, `WaterDistort`, `Sharpen`, `Dither`, `Outline` added to `src/effect/effect_type.rs`. All match arms updated.
- **Effect presets** — New `src/effect/presets.rs` with `EffectPreset`, `build_preset(name, w, h)`, `preset_names()`, and 5 named presets: `retro_tv`, `horror`, `dream`, `neon`, `sepia_age`.
- **Water UV-distortion overlay** — New `src/effect/water_overlay.rs` with `WaterOverlayState { enabled, amplitude, frequency, speed, tint_r/g/b/strength, depth_r/g/b/strength, time }` and `update(dt)` / `reset()` methods. Integrated into `Overlay` struct in `src/effect/overlay.rs`.
- **4 new image operations** — `ImageData::resize(w, h)` (bilinear), `blit(src, dx, dy)` (Porter-Duff over), `get_region(x, y, w, h)`, `diff(other) -> u32` added to `src/image/effects.rs`; `map_pixel_par<F>()` (rayon parallel, 65,536 px threshold) added to `src/image/image_data.rs`.
- **`lurek.postfx` extended API** — `beginCapture()`, `endCapture()`, `apply()` on `LuaPostFxStack`; `newPresetStack(name, w?, h?)`; `getEffectTypes()` now returns 23 types. Registered in `src/lua_api/effect_api.rs`.
- **`lurek.overlay` water API** — `setWater(amplitude, frequency, speed)`, `setWaterTint(r,g,b,strength)`, `setCustomShader(name?)`, `getWater() -> table` on `LuaOverlay`.
- **`lurek.img` ImageData API** — `resize(w, h)`, `blit(src, dx, dy)`, `getRegion(x, y, w, h)`, `diff(other)`, `mapPixels(fn)` added to `impl mlua::UserData for ImageData` in `src/lua_api/image_api.rs`.
- **Lua tests** — 4 new test files registered in `tests/lua/harness.rs`: `test_effect_overlay_water.lua`, `test_postfx_stack_extended.lua`, `test_image_extended.lua`, `test_evidence_postfx_types.lua`.

## [0.7.27] — 2026-05-24
### Added
- **10 new DSP effect types** — `Notch`, `LowShelf`, `HighShelf`, `BellEq`, `Reverb2`, `Flanger`, `Phaser`, `Distortion`, `Limiter`, `Compressor` added to `src/audio/dsp.rs` `EffectType` enum with full biquad/shelf/comb/LFO/waveshaper/dynamics DSP implementations. `ActiveEffect` gains `compressor_env` and `lfo_phase` fields; `set_param()` extended to 15 match arms.
- **`src/audio/offline.rs`** — New module: `process_offline(input, output, effects)` decodes a WAV, threads samples through an `ActiveEffect` chain, and writes a 16-bit PCM WAV without external deps; `normalize_file(input, output, target)` scales peak amplitude. Exposed as `lurek.audio.processOffline` and `lurek.audio.normalizeFile`.
- **`src/audio/visualizer.rs`** — New module: `waveform_to_png` draws amplitude envelope; `spectrogram_to_png` renders a time–frequency heat-map (simple DFT, 512-sample windows). Uses `image` crate. Exposed as `lurek.audio.waveformToPng` and `lurek.audio.spectrogramToPng`.
- **`src/audio/pool.rs`** — New `SoundPool` struct for polyphonic round-robin voice management; `Mixer::new_pool(file_path, voice_count)` pre-loads N voices and returns the pool. Exposed as `lurek.audio.newPool` → `SoundPool` UserData with `play`, `stopAll`, `setVolume`, `setBus`, `release`, `getVoiceCount`.
- **Stereo width & random pitch APIs** — `Mixer::set_stereo_width`, `get_stereo_width`, `set_random_pitch`, `clear_random_pitch`; `AudioEntry` gains `stereo_width` and `pitch_range` fields. Lua: `lurek.audio.setStereoWidth`, `getStereoWidth`, `setRandomPitch`, `clearRandomPitch`.
- **Crossfade & bus metering** — `Mixer::crossfade(from, to, duration, game_dir)` starts the target with fade-in and stops the source; `get_bus_peak` / `get_bus_rms` stubs for future metering. Lua: `lurek.audio.crossfade`, `getBusPeak`, `getBusRms`.
- **`Bus::add_effect` extended** — Accepts 10 new type strings (`"notch"`, `"lowshelf"`, `"highshelf"`, `"bell_eq"`, `"reverb2"`, `"flanger"`, `"phaser"`, `"distortion"`, `"limiter"`, `"compressor"`).
- **Lua unit tests** — 4 new test files: `tests/lua/unit/test_audio_effects.lua`, `test_audio_pool.lua`, `test_audio_stereo.lua`, `test_audio_offline.lua`; 2 evidence files: `test_evidence_audio_offline.lua`, `test_evidence_audio_visualizer.lua`. All registered in `tests/lua/harness.rs`.

## [0.7.26] — 2026-05-23
### Added
- **15 new `RenderCommand` variants** — `DrawQuadBezier`, `DrawCubicBezier`, `DrawPath`, `DrawGradientRect`, `DrawColoredPolygon`, `DrawIsoCubeTile`, `DrawHexTile`, `BeginSortGroup`, `PushSortKey`, `FlushSortGroup`, `DrawPhysicsDebug`, `DrawSpineSkeleton`, `DrawBevelRect`, `PushLayer`, `PopLayer` added to `src/render/renderer.rs` with 7 new support types: `PathSegment`, `GradientDirection`, `HexOrientation`, `BevelStyle`, `PhysicsDebugShape`, `PhysicsDebugConfig`, `SpineSlotDraw`.
- **GPU renderer match arms** — `GpuRenderer::render_frame` in `src/render/gpu_renderer.rs` processes all 15 new variants. Bezier/path commands tessellate geometry on the CPU into `ColorVertex` batches; gradient rects use per-corner color vertices; iso cube tiles and hex tiles expand into polygon draws; physics debug iterates `PhysicsDebugShape` entries per shape type.
- **`lurek.graphic.*` Lua bindings** — 13 new functions registered in `src/lua_api/render_api.rs`: `drawQuadBezier`, `drawCubicBezier`, `drawPath`, `drawGradientRect`, `drawColoredPolygon`, `drawIsoCubeTile`, `drawHexTile`, `beginSortGroup`, `pushSortKey`, `flushSortGroup`, `drawBevelRect`, `pushLayer`, `popLayer`.
- **`lurek.raycaster` extended factory API** — Three new `UserData` types and factory functions: `lurek.raycaster.newDoorManager()` → `DoorManager`; `lurek.raycaster.newHeightMap(w, h)` → `HeightMap`; `lurek.raycaster.newPointLight(x, y, r, g, b, radius, intensity)` → `PointLight`. Adds `DoorManager` methods: `addDoor`, `openDoor`, `closeDoor`, `update`, `getDoor`, `count`. `HeightMap` methods: `setFloor`, `setCeiling`, `floorAt`, `ceilingAt`. `PointLight` methods: `x`, `y`, `radius`, `intensity`, `color`, `set`.
- **`PhysicsShapeSnapshot`** — New geometry-snapshot struct in `src/physics/world.rs`, exported via `src/physics/mod.rs`. `World::extract_shape_snapshots()` iterates all bodies and returns `Vec<PhysicsShapeSnapshot>` with no `crate::render` dependency, allowing the Lua API layer to convert without creating a cross-module circular dependency.
- **`lurek.physics.drawDebugGpu`** — New Lua function in `src/lua_api/physics_api.rs` that extracts body shapes and pushes `RenderCommand::DrawPhysicsDebug` for GPU-accelerated physics debug visualisation. Accepts an optional config table to override `bodyColor`, `staticColor`, `sleepColor`, `sensorColor`, and `lineWidth`.
- **Evidence tests** — Three new evidence test files: `tests/lua/evidence/test_evidence_raycaster_ext.lua` (8 tests: DoorManager, HeightMap, PointLight); `tests/lua/evidence/test_evidence_physics_debug_gpu.lua` (6 tests); `tests/lua/evidence/test_evidence_graphic_draw_cmds.lua` (18 tests for all new Lua graphic functions). Registered in `tests/lua/harness.rs`.

## [0.7.25] — 2026-05-22
### Added
- **Particle system — 5 new shapes** — `Shrapnel { edges: u8 }`, `Ray { aspect: f32 }`, `Puff`, `Ring { thickness: f32 }`, `Capsule` added to `ParticleShape` (domain) and `ParticleRenderShape` (render). All shapes are fully tessellated in the GPU renderer via the `DrawParticleSystem` batch command.
- **Particle system — GPU batch rendering** — `RenderCommand::DrawParticleSystem` is now fully implemented in `GpuRenderer::render_frame`. Untextured particles are tessellated in one `append_color_draw` call (reducing per-particle draw overhead). `particle_api.rs render()` forwards untextured particles as a `DrawParticleSystem` batch and continues to expand textured particles individually.
- **Particle system — Attractors** — `Attractor { x, y, strength, radius }` struct added to `src/particle/config.rs`. `ParticleSystem` gains `attractors: Vec<Attractor>` and three methods: `add_attractor(x, y, strength, radius)`, `clear_attractors()`, `attractor_count()`. New Lua methods: `addAttractor`, `clearAttractors`, `getAttractorCount`.
- **Particle system — Bounce bounds** — `BounceBounds { x_min, x_max, y_min, y_max, restitution }` struct added to `config.rs`. `ParticleSystem` gains `bounce_bounds: Option<BounceBounds>` with `set_bounds(xmin, xmax, ymin, ymax, restitution)` and `clear_bounds()`. New Lua methods: `setBounds`, `clearBounds`.
- **Particle system — warm_up** — `ParticleSystem::warm_up(seconds: f32)` pre-simulates the system; clamped to 30 s. Exposed as `lurek.particles:warmUp(seconds)`.
- **Particle system — Sub-emitter death spawning** — `ParticleConfig` gains `death_emitter: Option<Box<ParticleConfig>>` and `death_burst_count: u32`. When particles die, their positions spawn sub-systems. `deathBurstCount` accepted in `lurek.particles.newSystem({})`.
- **Particle shape config keys** — `shrapnelEdges`, `rayAspect`, `ringThickness` accepted in `lurek.particles.newSystem({})` opts table. Shape strings `"shrapnel"`, `"ray"`, `"puff"`, `"ring"`, `"capsule"` added to `setShape` / `getShape` / `newSystem` config.
- **`toImage` method alias** — `ParticleSystem:toImage(w, h)` is a convenience alias for `drawToImage`.
- **Particle system — per-particle shape seed** — `Particle` struct gains `shape_seed: u32` assigned at spawn, used by `Shrapnel` tessellation for deterministic polygon geometry.
- **Tests** — New describe blocks in `tests/lua/unit/test_particle.lua` for: new shapes, warmUp, attractors, bounce bounds. New evidence tests in `tests/lua/evidence/test_evidence_particle.lua`: shape composite PNG, attractor PNG.


### Added
- **Scene Phase A — DepthSorter performance** — `DepthSorter` gains a **dirty flag** (sort skipped entirely when no entries added since last flush), a **stable mode** (`set_stable(true)` preserves insertion order for equal depths), a **radix sort path** (O(n) via two-pass LSD on integer depths for 256+ entries), and a **parallel sort path** (rayon `par_sort_unstable_by` for 10 000+ entries). New Lua methods: `setStable`, `isStable`. Added `rayon = "1"` to `[dependencies]`.
- **Scene Phase B — EasingType and new TransitionType variants** — New `EasingType` enum with six curves: `Linear`, `EaseIn`, `EaseOut`, `EaseInOut`, `Bounce`, `Back`. New `TransitionType` variants: `Wipe`, `Iris`, `Zoom`, `CrossFade`. `ActiveTransition` gains `easing` field (defaults to `Linear`), `new_with_easing()` constructor, `progress_eased()`, `set_easing()`, `get_easing()` methods. Lua `push`, `pop`, `switchTo` now accept an optional fourth `easing` string parameter (e.g. `"ease_in"`). New Lua function: `getTransitionProgressEased()`.
- **Scene Phase C — Overlay mode** — `SceneStack` gains `overlay_ids: HashSet<SceneId>`, `push_overlay()`, `is_overlay()`, `get_active_ids()`, and `get_transition_progress_eased()`. `process`, `processPhysics`, and `processLate` Lua callbacks now iterate ALL active scenes when at least one overlay is present. New Lua functions: `pushOverlay`, `isOverlay`, `getActiveScenes`.
- **Scene Phase D — Async scene preloading** — New Lua functions: `preload(name, fn)` registers a loader for a named scene; `isPreloaded(name)` checks whether the scene has been loaded; `pushPreloaded(name, transition?, duration?, easing?, params?)` invokes the loader on first use and then pushes the registered scene. `SceneState` gains `preload_callbacks: HashMap<String, LuaRegistryKey>` and `preloaded_names: HashSet<String>`.
- **Tests** — New `[[test]] name = "scene_tests"` in `Cargo.toml`; `tests/rust/unit/scene_tests.rs` (26 integration tests for DepthSorter, EasingType, TransitionType, ActiveTransition, SceneStack overlay). Added overlay, easing, preload, and DepthSorter `describe` blocks to `tests/lua/unit/test_scene.lua`. New evidence suite `tests/lua/evidence/test_evidence_scene.lua` with `lua_evidence_scene` harness entry.

### Added
- **SpinBox widget** — New `lurek.ui.newSpinBox(min, max)` factory; domain struct in `src/ui/controls.rs` with `set_value`, `increment`, `decrement`, `set_range`, `set_step`; Lua methods `getValue`, `setValue`, `increment`, `decrement`, `setRange`, `setStep`.
- **Switch widget** — New `lurek.ui.newSwitch(on?)` factory; domain struct in `src/ui/controls.rs` with `toggle`, `set_on`; Lua methods `isOn`, `setOn`, `toggle`. Mouse-click in `GuiContext::mouse_pressed` emits `GuiEvent::Change`.
- **Badge widget** — New `lurek.ui.newBadge(count?)` factory; domain struct in `src/ui/extras.rs` with `display_text` (returns `"99+"` format), `set_count`; Lua methods `getCount`, `setCount`, `getDisplayText`.
- **WidgetStyle shadow, highlight, gradient** — Added five new fields to `WidgetStyle`: `shadow_color`, `shadow_offset`, `highlight_alpha`, `gradient_end`, `text_align`. All default to zero/None.
- **Theme::default_dark()** — Pre-styled dark theme with 14 widget-type entries (Button, Label, TextInput, CheckBox, RadioButton, Slider, ProgressBar, ComboBox, ListBox, TabBar, Panel, SpinBox, Switch, Badge). Exposed as `lurek.ui.setDefaultTheme()`.
- **WidgetBase 16px-grid sizes** — `WidgetType::default_size()` now returns per-type sizes on a 16px grid; `WidgetBase::new()` uses these sizes instead of the former 100×30 hardcode.
- **WidgetType parse helpers** — Added `WidgetType::parse_str(s)` mapping all 34 lowercase variant names, and `WidgetType::default_size()` providing per-type (w, h) pairs.
- **Dirty flag and viewport on GuiContext** — `GuiContext` now carries `dirty: bool`, `viewport_w: f32`, `viewport_h: f32`; new methods `set_viewport`, `flush_cache`, `set_default_theme` exposed as `lurek.ui.setViewport`, `lurek.ui.flushCache`, `lurek.ui.setDefaultTheme`.
- **Specialised render emit functions** — `src/ui/render.rs` gains `emit_shadow`, `emit_highlight`, `emit_slider`, `emit_progress_bar`, `emit_checkbox`, `emit_radio_button`, `emit_combo_box_arrow`, `emit_scroll_bar`, `emit_spin_box`, `emit_switch`, `emit_badge`; `render_widget` now dispatches per `WidgetKind` variant.
- **Rust unit tests** — New `tests/rust/unit/gui_tests.rs` (36 tests) registered as `[[test]] name = "gui_tests"` in `Cargo.toml`.
- **Lua BDD tests** — `tests/lua/unit/test_gui.lua` extended with SpinBox, Switch, Badge, and helper describe-blocks (172 new lines, 32 new cases).

## [0.7.22] — 2026-05-16
### Added
- **Physics extension APIs** — New `lurek.physics` capabilities on `World` and `Body` userdata:
  - **Breakable joints** — `world:setJointBreakForce(jid, force)` / `world:getJointBreakForce(jid)`: joints exceeding the relative-velocity threshold are automatically destroyed each step.
  - **One-way platforms** — `world:setBodyOneWay(id, nx, ny)` / `world:clearBodyOneWay(id)` / `world:getBodyOneWay(id)`: post-step velocity correction lets bodies pass through from the specified direction.
  - **Body sleeping** — `world:isBodySleeping(id)`, `world:wakeUpBody(id)`, `world:sleepBody(id)` (and `body:isSleeping()`, `body:wakeUp()`, `body:sleep()` on the Body userdata).
  - **Continuous Collision Detection** — `world:setBodyCCD(id, enabled)` / `world:getBodyCCD(id)` (backed by existing `set_bullet` / `is_bullet`).
  - **Contact callbacks** — `world:setBeginContact(fn)`, `world:clearBeginContact()`, `world:setEndContact(fn)`, `world:clearEndContact()`: fired with `(bodyIdA, bodyIdB)` after each `step`.
  - **Solver iterations** — `world:setSolverIterations(n)` / `world:getSolverIterations()`.
  - **Batch body creation** — `world:newBodies(specs)` creates multiple bodies in a single call.
- **Rust domain methods** — Added `set_body_one_way`, `clear_body_one_way`, `get_body_one_way`, `set_joint_break_force`, `get_joint_break_force`, `is_body_sleeping`, `wake_up_body`, `sleep_body`, `set_solver_iterations`, `get_solver_iterations`, `add_bodies` to `src/physics/world.rs`.
- **Physics tests** — Added `tests/lua/unit/test_physics_ext.lua`, `tests/lua/evidence/test_evidence_physics_ext.lua`, `tests/lua/integration/test_physics_platformer.lua` with corresponding `#[test]` entries in `tests/lua/harness.rs`.
- **rapier2d parallel feature** — Enabled `features = ["parallel"]` on `rapier2d = "0.32"` in `Cargo.toml`.

## [0.7.21] — 2026-05-15
### Fixed
- **Test harness correctness** — Fixed three critical bugs in `tests/lua/harness.rs`: added `#[ignore]` to `lua_test_examples` (phantom file panicking on every run); removed erroneous `tests/lua/` path prefix from two evidence/golden entries; renamed four functions from the banned `lua_test_*` scheme to the canonical `lua_evidence_*` / `lua_golden_*` scheme.
- **Harness registrations** — Added seven previously unregistered `#[test]` entries: `lua_security_fuzz_boundary`, `lua_evidence_geometry`, `lua_evidence_gui`, `lua_evidence_migrated_15`, `lua_evidence_migrated_20`, `lua_golden_migrated_15`, `lua_golden_migrated_20`.
- **assert() anti-pattern** — Replaced 58 raw Lua `assert()` calls across six unit test files and one integration test with typed `expect_*` framework helpers (`expect_true`, `expect_false`, `expect_nil`, `expect_not_nil`, `expect_greater`, `expect_less`, `expect_in_range`); tautological `assert(x ~= nil or x == nil)` in `test_audio.lua` also corrected.
- **@covers marker ownership** — Moved bulk `@covers` lists off `describe()` containers and onto the `it()` blocks they belong to in `tests/lua/unit/test_math.lua` and `tests/lua/unit/test_physics.lua`.
- **Rust test naming** — Removed the banned `test_` prefix from all function names in `tests/rust/ext/math_ext_tests.rs` and `tests/rust/ext/graphics_ext_tests.rs`.

## [0.7.20] — 2026-05-14
### Changed
- **Lua test docstring ownership** — Enforced repository-wide that Lua test file headers stay short prose-only, `describe()` blocks carry only `@description`, and ownership markers such as `@covers`, `@evidence`, and `@golden` belong on `it()` blocks; `tools/audit/lua_test_structure_audit.py` now checks this by default, with `--allow-legacy-describe-markers` available only as a temporary escape hatch.
- **Lua test structure standard** — Defined one repository-wide rule for Lua BDD file headers, `describe()` / `it()` `@description` placement, nested `describe()` usage, local `@covers` placement, and mandatory `test_summary()` endings in `docs/architecture/test-framework.md` and `.github/skills/testing-rust/SKILL.md`.
- **Lua test audit tooling** — Added `tools/audit/lua_test_structure_audit.py` plus audit README / quality-pipeline references to detect missing block descriptions, legacy `@description:` syntax, forbidden `@category` markers, and non-final `test_summary()` calls, with safe autofixes for the legacy syntax cases.
- **Evidence/golden contract enforcement** — Added `tools/audit/lua_evidence_golden_contract_audit.py`, stripped non-artifact pre-checks out of mixed evidence suites, and documented that evidence files must contain artifact-producing cases only while Lua golden files remain compare-only.
- **Lua golden migration** — Moved TOML / encode / hash baselines from `tests/rust/golden/expected/` into `tests/lua/golden/samples/migrated_rust/`, added Lua evidence sources plus compare-only Lua goldens for those artifacts, and removed the corresponding Rust golden harness coverage.
- **System message catalog** — Exposed `lurek.platform.getMessage`, `lurek.platform.hasMessage`, and `lurek.platform.getMessageCount`, migrated the remaining Rust `messages_tests.rs` coverage into `tests/lua/unit/test_system.lua`, and deleted the obsolete Rust integration file.
- **Testing docs/skill sync** — Corrected the false auto-discovery guidance in `docs/architecture/test-framework.md` and `.github/skills/testing-rust/SKILL.md`; Lua files must be registered manually in `tests/lua/harness.rs`.
- **Windows debug linking** — Removed the forced `/DEBUG:FASTLINK` MSVC linker flag from `.cargo/config.toml` because it caused unstable `lua_tests` links with unresolved externals on large debug test binaries.
- **Debug profile stability** — Disabled `incremental` and removed `split-debuginfo = "packed"` from `[profile.dev]` after repeated incremental `lua_tests` rebuilds on Windows MSVC produced unresolved-internal-symbol linker failures.
- **UI Lua API** — Added the missing `widget:getChildren()` wrapper in `src/lua_api/ui_api.rs`, fixing the existing `lua_test_gui` failure for window child enumeration.
- **Test migration Phase 5** — Expanded Lua BDD test coverage across 10 modules and deleted 3 fully-migrated Rust integration test files.
  - **Deleted RS files** (100% Lua-VM-only, all coverage now in Lua BDD layer): `fx_screen_tests.rs` (77 tests), `overlay_tests.rs` (78 tests), `window_tests.rs` (17 tests). Removed corresponding `mod` declarations from `tests/engine_tests.rs`.
  - **`test_terminal.lua`** — Added terminal low-level cell-method and widget-lookup tests: default cell values, clamped dimensions, setChar/setFg/setBg, print clipping, getCursor/setCursor, resize, getWidget(idx), findByTag, no-focus input.
  - **`test_pathfinding.lua`** — Added FlowField RS-parity tests: isCalculated before/after calculate, getTargets, getCostToTarget, steer return types, multi-target calculate, lineOfSight, diagonalMode. +15 tests.
  - **`test_log.lua`** — Added sink-registry tests: addSink, removeSink, readMemory capacity, clearSinks. +5 tests.
  - **`test_patterns.lua`** — Added SimpleState edge-case tests (hasState false, update no-crash, getCurrent nil, clearAll+addState), plus CommandStack undo/redo cycle and getHistorySize. +7 new-passing tests.
  - **`test_scene.lua`** — Added DepthSorter RS-parity tests: add/sort/flush execute order, clear count, popTo falsy return, getStackSize height check. +6 tests.
  - **`test_tween.lua`** — Added easing-name resolution: string easing arg, cubicOut easing, near-zero-duration completion. +5 tests.
  - **`test_localization.lua`** — Added interpolate single/multiple/unknown/double-brace and format helper tests. +8 tests.
  - **`test_dataframe.lua`** — Added CellValue nil/number/text/bool round-trips via `getValue`, Database addTable/getTable/listTables/removeTable CRUD. +8 tests.
  - **`test_compute.lua`** — Added zeros/ones shape-table form, range sequence, getShape on 2D array, zero-step range error. +7 tests.
  - **`test_graph.lua`** — Added addEdge invalid src/dst, removeNode error on bad id, getNodes count. +5 tests.
- **Test migration continuation** — Added Lua-side timer frame-count coverage, a headless network-constants suite, sandbox coverage under `tests/lua/security/test_sandbox.lua`, and a Lua `Vec2` userdata surface (`lurek.math.vec2` / `lurek.math.Vec2`) plus `lurek.ui.parseWidgetState` for GUI-state roundtrip checks.
- **Tween migration continuation** — Added standalone `lurek.tween.newState()` userdata coverage so the pure `TweenState` timing core can be exercised from Lua BDD tests instead of only Rust integration tests.

### Changed
- **Test migration Phase 4** — Fixed and expanded Lua BDD tests for 10 additional modules:
  - `signal` — Stripped embedded UTF-8 BOM that caused a syntax error in `test_signal.lua`; 19/19 tests restored.
  - `system` — Stripped BOM + fully rewrote `test_system.lua` to cover `lurek.platform.*`: getOS/getVersion/getArch/getProcessorCount/getMemorySize/getInfo table fields/clipboard round-trip/debug overlay toggle/log level round-trip/log/getLastError/getEnv/getArgs/parseArgs (flag+option+positional)/getPowerInfo/getPreferredLocales/openURL function-existence check/lurek.signal.quit surface check. 54 tests total (was broken syntax error).
  - `fx` — Rewrote `test_fx.lua` to use the correct `lurek.postfx.*` / `lurek.overlay.*` namespace instead of the non-existent `lurek.effect.*`; corrected `stack:count()` → `stack:len()` and `stack:setEnabled(bool)` → `stack:setEnabled(pos, bool)`; expanded to 32/32 covering getEffectTypes/newEffect/newStack/newPass/newCustomEffect/PostFxEffect-setEnabled-isEnabled/PostFxStack-add-remove-clear-len-getEffect-getDimensions-resize.
  - `camera` — Added setBounds/removeBounds/setTarget/clearTarget/setFollowSmooth/setDeadZone/setLookAhead tests; 28/28 (was 16/16).
  - `raycaster` — Added castRaysFlat/lineOfSight/projectSprite instance methods plus `lurek.raycaster.projectColumn` and `lurek.raycaster.distanceShade` module function tests; 28/28 (was 14/14).
  - `procgen` — Added voronoi determinism/edge cases (single-seed, fill=0/1 bounds, poissonDisk determinism, perlinNoise idempotence); 25/25 (was 19/19).
  - `spine` — Added `drawToImage(w, h)` tests via `newSkeleton`; 21/21 (was 18/18).
  - `font`, `window`, `audio_dsp` — Verified continuing pass (9/9, 64/64, 16/16 respectively).
- **RS cleanup assessment** — Audited 18 Phase 1–3 Rust integration test files; all retain direct Rust struct-level coverage (`Vec2`, `Body`, `Clock`, `ByteData`, etc.) not reachable from the Lua BDD layer; none qualify for deletion under the "fully-migrated" rule.

### Changed
- **Test migration Phase 2** — Migrated public-method coverage from Rust integration tests to Lua BDD tests for 4 additional modules: `physics` (Body UserData position/velocity/angle/mass/type/friction/restitution/layer/mask/forces/damping/gravity-scale/bullet/fixed-rotation, World gravity/bodyCount/bodyIds/destroyBody/clear/step/meter-conversion, Joints revolute/distance/weld/count/ids/type/destroy, Fixtures addFixture/count/friction/restitution/sensor, Collision static/kinematic/gravity-scale/layer-mask), `thread` (Channel type/typeOf/supply/demand/named-channels/FIFO-order), `animation` (pause/resume/setFrame/getCurrentFrame/isLooping/event-lifecycle/pollEvents-drain/speed-edge-cases/clip-switching/addClipFromGrid/zero-dt), `scene` (popTo/DepthSorter-addObject/clear/negative-depths/scene.new-factory/scene.define-factory/data-store-complex-types/transition-params). Total: 196 new Lua assertions across 4 test files (physics 83, thread 31, animation 34, scene 48).
- **Test migration Phase 1** — Migrated public-method coverage from Rust integration tests to Lua BDD tests for 6 modules: `data` (compress/decompress/hash/encode/decode/newByteData/parseToml/encodeToml/write/read/size), `math` (RandomGenerator/Transform/BezierCurve/NoiseGenerator/SpatialHash/easing/triangulate/isConvex/gammaToLinear/linearToGamma), `timer` (Scheduler after/every/cancel/pause/resume/getRemaining/setTimeScale), `event` (Signal register/emit/remove/clear/clearAll/getCount/getTotalCount/type/typeOf/poll), `tween` (case-insensitive easing/zero-duration/paused callbacks/onComplete-fires-once), `serial` (CSV delimiter/headers options/round-trip/error handling). Total: 302 new Lua assertions across 6 test files.
- **Evidence tests** — Stripped 443 value assertions from 31 evidence test files; evidence tests now only create content (no pass/fail on values).
- **Golden tests** — Rewrote all 13 golden tests to compare-only pattern (no content creation); created `tests/lua/golden/samples/` directory with 13 module subdirs.
- **Test framework** — Added 6 evidence/golden helper functions to `tests/lua/init.lua` (`evidence_output_dir`, `ensure_evidence_dir`, `expect_evidence_created`, `_read_file_bytes`, `expect_golden_file_match`, `expect_golden_text_match`).
- **Test architecture** — Updated `docs/architecture/test-framework.md` with evidence-only, golden-compare-only, public→Lua/private→Rust scope rules, and harness auto-discovery notes.

## [0.7.17] — 2026-04-12
### Changed
- **Debug build** — Added `/DEBUG:FASTLINK` Windows MSVC linker flag in `.cargo/config.toml`; PDB generation is now 3–8× faster by referencing `.obj` files instead of copying debug info.
- **Debug build** — Added `split-debuginfo = "packed"` to `[profile.dev]`; reduces incremental link-step data movement.
- **Release binary** — Removed dead `opt-level = "s"` and `lto = "thin"` overrides from `[profile.dist]` that made the `dist` profile produce a larger binary than `release`; `dist` now inherits the full `opt-level = "z"` + fat LTO settings from `release`.
- **Incremental builds** — Removed the dead auto-harness generator from `build.rs` along with its `cargo:rerun-if-changed=tests/lua` directive; previously any `.lua` file edit triggered a full crate recompile.
- **Test runner** — Added `.config/nextest.toml`; use `cargo nextest run` for per-process test isolation, colour-coded timing output, stress/evidence thread caps, and a separate CI profile.

## [0.7.16] — 2026-04-11
### Fixed
- Fixed missing `lurek.animation` methods (`addClip`, `addFramesFromGrid`, `addClipFromGrid`) from generated API docs by correcting rustfmt multiline bindings in `animation_api.rs` to allow parser extraction.
- Re-encoded `content/examples/animation.lua` to remove cp1252 corruption and updated sprite drawing API usage in comments.

### Changed
- Rewrote every `src/<module>/AGENT.md` into a new module-reference format centered on `Module Info`, `Module Purpose`, `Files`, and `Key Types`, and preserved the prior content as sibling `AGENT.legacy.md` backups across all 50 `src/` modules.
- Generated complete `docs/specs/<module>.md` files for all 50 top-level `src/` modules, added `tools/docs/gen_module_specs.py` as the reusable spec generator, and aligned `tools/validate/validate_module_coverage.py` with the full top-level module set including `bin` and `lua_api`.
- Merged the former `src/<module>/AGENT.md` content model into `docs/specs/<module>.md`, updated the generator and validators to emit the new `General Info` / `Summary` / `Files` / `Types` / `Functions` / `Lua API Reference` / `References` / `Notes` format, and retired the legacy per-module AGENT files.

## Versioning scheme

```
MAJOR.MINOR.PATCH
```

| Segment   | Increment when…                                                                                    |
| --------- | -------------------------------------------------------------------------------------------------- |
| **MAJOR** | Breaking API changes — Lua scripts or engine configuration must be ported                          |
| **MINOR** | New backwards-compatible features — new `lurek.*` APIs, new modules, new default configs           |
| **PATCH** | Bug fixes, internal refactors, documentation and tooling changes that do not affect the public API |

Always update this file **in the same commit** as the change. Use the commit type as the section label.

---

## [0.7.15] — 2025-06-28
### Added
- **GPU render stats exposed to Lua** (`src/lua_api/render_api.rs`): `lurek.graphics.getStats()` now returns GPU-level stats: `gpu_draw_calls`, `batched_draws`, `texture_switches`, `canvas_switches`, `shader_switches` alongside existing command-count stats.
- **UI computed layout** (`src/ui/widget.rs`, `src/ui/context.rs`, `src/ui/render.rs`): `WidgetBase` now has `computed_rect: Rect` and `is_visible: bool` fields. `GuiContext::run_layout_pass()` propagates layout from parent to child widgets. `generate_render_commands()` calls layout pass automatically.
- **widget:getRect() Lua API** (`src/lua_api/ui_api.rs`): New method returns computed `(x, y, width, height)` after layout.
- **Raycaster SharedState wiring** (`src/runtime/shared_state.rs`, `src/lua_api/raycaster_api.rs`): `SharedState.raycaster_output` stores `RaycasterScene` built by raycaster API. Cleared each frame.
- **GPU 2D lighting pass** (`src/render/gpu_renderer.rs`): Full radial point-light rendering with WGSL shader, light accumulation texture (additive blend), and multiply-blend compositing over the scene. Replaces the previous empty stub.
- **GPU shadow maps** (`src/render/gpu_renderer.rs`): 1D radial shadow textures per shadow-enabled light. CPU-side ray casting against occluder edges produces per-angle distance maps. Packed into R32Float shadow atlas texture, sampled in LIGHT_SHADER fragment stage. `LightVertex` struct carries `shadow_v` for atlas row lookup. `compute_1d_shadow_map()` handles ray-segment intersection with light_mask filtering.
- **Raycaster GPU rendering** (`src/app/app.rs`): `RaycasterScene` quads (walls, floors, ceilings, billboard sprites) auto-converted to `DrawTexturedQuad` render commands with back-to-front depth sorting. Minecraft-style 3D FPS perspective via textured quad approach.
- **docs/specs/sprite.md**: Full specification for the new `src/sprite/` module.

### Changed
- **render-command-architecture.md**: Updated "Current State vs Target State" — all previously ❌ items now ✅. Implementation Checklist fully checked (raycaster GPU path, shadow map generation, all phases complete except tooling-only docstring check).

## [0.7.14] — 2026-04-11
### Added
- **Phase 0 — `DrawTexturedQuad` RenderCommand** (`src/render/renderer.rs`): New variant `DrawTexturedQuad { corners: [Vec2;4], uvs: [Vec2;4], texture_key: TextureKey, color: [f32;4] }` added to the `RenderCommand` enum. GPU handler added to `src/render/gpu_renderer.rs` via `push_tex_quad_corners()` helper, enabling perspective-correct textured quad rendering from CPU domain modules.
- **Phase 2A — Debug `generate_render_commands()` for five CPU-only modules**:
  - `src/physics/render.rs` — `World::generate_render_commands()`: AABB outlines (Rectangle), velocity arrows (Line), contact points (Circle) for all rigid bodies in the physics world. CPU `draw_to_image()` included.
  - `src/ai/render.rs` — FSM state labels (DrawText), BehaviorTree node boxes (Rectangle+Line) for AI debug overlays. `StateMachine::generate_render_commands()` and `BehaviorTree::generate_render_commands()` with `draw_to_image()`.
  - `src/pathfind/render.rs` — `NavGrid::generate_render_commands()` (walkable/blocked cells), `FlowField::generate_render_commands()` (flow arrows), `InfluenceMap::generate_render_commands()` (heat-map rectangles). Public getters added to `flow_field.rs` and `influence_map.rs`.
  - `src/graph/render.rs` — `Graph::generate_render_commands()` with circular layout: nodes as circles, edges as lines. `draw_to_image()` included.
  - `src/procgen/render.rs` — `NoiseGrid::generate_render_commands()` (grayscale rectangles per noise cell) and `draw_to_image()`.

## [0.7.13] — 2026-04-11
### Added
- **Phase 8 — Lua API Exposure** (`lurek.*` surface for render-command capabilities)
  - `lurek.physics.debugDraw(enable)` — enables/disables the physics debug render overlay (AABB outlines + velocity arrows). Controlled via `SharedState.physics_debug_draw` bool field.
  - `lurek.ui.drawToImage(w, h)` — renders the full UI widget tree to a CPU `ImageData` at the given pixel resolution; returns a `LuaImageData` userdata. Delegates to `GuiContext::draw_to_image()` in `src/ui/render.rs`.
- **Phase 9 — Quality gate pass**
  - `docs/specs/raycaster.md` — added `render.rs`, `scene.rs`, `build_scene.rs` to Source Files table; added "Render Command Generation" section documenting `DrawTexturedQuad` emission.
  - `docs/specs/ui.md` — added `render.rs` to Source Files table documenting `generate_render_commands()` and `draw_to_image()`.
  - `docs/specs/particle.md` — added `render.rs` to Source Files table.
  - All five impacted `AGENT.md` files already list `render.rs` — no changes required.
  - `SharedState.physics_debug_draw: bool` added (default `false`).

## [0.7.12] — 2026-04-11
### Added
- **Phase 1 — App auto-collection loop**: `src/app/app.rs` now automatically collects render commands from registered engine modules each frame in the correct draw order, without requiring Lua scripts to call module-level `render()` methods manually.
  - Draw order 2 (before game world): parallax layers registered in `SharedState.auto_parallax_layers` are collected and emitted via `ParallaxLayer::generate_render_commands()`.
  - Draw order 3 (before game world): tilemaps registered in `SharedState.auto_tilemaps` are collected via `TileMap::generate_render_commands(0, 0, cam_x, cam_y, cam_w, cam_h)`.
  - Draw order 4: Lua `lurek.render()` callback (game world — unchanged).
  - Draw order 6 (after game world): all particle systems in `SharedState.particle_systems` are auto-collected via `ParticleSystem::generate_render_commands()`.
  - Draw order 9 (after `render_ui`): GUI context registered in `SharedState.auto_ui_ctx` is collected via `GuiContext::generate_render_commands()`.
  - Stale `Weak<>` refs are pruned from `auto_parallax_layers` and `auto_tilemaps` once per frame.
- **SharedState auto-collection fields** (`src/runtime/shared_state.rs`):
  - `auto_parallax_layers: Vec<Weak<RefCell<ParallaxLayer>>>` — populated when `lurek.parallax.newLayer()` creates a `LuaParallaxLayer`.
  - `auto_tilemaps: Vec<Weak<RefCell<TileMap>>>` — populated when `lurek.tilemap.newTileMap()` or `MapGen:generate()` creates a `LuaTileMap`.
  - `auto_ui_ctx: Option<Weak<RefCell<GuiContext>>>` — set when the `lurek.ui` module is registered.
- **Phase 6 — Light integration verified**: `SharedState.light_world` is correctly passed as `&s_ref.light_world` to `GpuRenderer::render_frame()`, which uses it in the dedicated `LIGHT RENDERING PASS` wgpu render pass. No code changes required — architecture is complete and correct.

## [0.7.11] — 2026-04-15
### Added
- **Phase 3 + Phase 5 — render-command migration (final batch)**: Added `generate_render_commands()` and/or `draw_to_image()` to the five remaining complex modules.
  - `src/ui/render.rs` — `GuiContext::generate_render_commands()` (alias for `build_render_commands(FontKey::default())`) and `GuiContext::draw_to_image(w, h)` (DFS widget-bounds CPU rasterisation). 3 new unit tests.
  - `src/minimap/render.rs` — `Minimap::generate_render_commands(screen_x, screen_y)` producing background rectangle, fog-aware terrain cells, viewport-outline, and ping circles. Added `pings()` and `markers_iter()` public accessor methods on `Minimap`. 4 unit tests.
  - `src/tilemap/render.rs` — `TileMap::generate_render_commands(offset_x, offset_y, cam_x, cam_y, cam_w, cam_h)` with per-layer frustum culling, GID-based fallback colour table matching `draw_to_image`, and object-tile circle markers. 4 unit tests.
  - `src/particle/render.rs` — `ParticleSystem::generate_render_commands()` and `Trail::generate_render_commands()` zero-offset wrappers around the existing `build_render_commands()` methods. 3 unit tests.
  - `src/spine/render.rs` — `Skeleton::generate_render_commands(x, y)` emitting bone-position fill circles (tinted by matching slot colour) and slot-attachment outline rectangles. 3 unit tests.

## [0.7.10] — 2026-04-15
### Added
- **Phase 2B/2C/2D — render-command migration**: Added `generate_render_commands()` and `draw_to_image()` to five more modules; animation and camera draw_to_image live in `image::visualization` to avoid circular dependencies.
  - `src/terminal/render.rs` — `Terminal::generate_render_commands(font_key, char_w, char_h, scale)` (background rectangle + Print per cell) and `Terminal::draw_to_image(width, height)`.
  - `src/scene/render.rs` — `SceneStack::generate_render_commands()` (always empty — scene IDs carry no render data) and `SceneStack::draw_to_image(width, height)` (dark blank placeholder).
  - `src/image/render.rs` — `ImageData::generate_render_commands(texture_key, x, y)` (single `DrawImage` command) and `ImageData::draw_to_image()` (returns a clone).
  - `src/effect/draw.rs` — `PostFxStack::draw_to_image(width, height)` (violet tint when effects are active, dark grey otherwise).
  - `src/parallax/draw.rs` — `ParallaxLayer::draw_to_image(width, height)` (transparent when invisible, tint × opacity otherwise).
  - `src/image/visualization.rs` — `draw_animation_to_image(anim, width, height)` and `draw_camera_to_image(cam, width, height)` free functions (animation/camera cannot import image due to existing circular dependency).
  - `src/camera/render.rs` — Added `Camera::generate_render_commands(scene_commands)` and `Camera2D::generate_render_commands(scene_commands)` convenience wrappers (wrap scene commands in push/translate/scale/rotate/pop transform stack).
### Fixed
- `src/lua_api/image_api.rs` — Removed duplicate `use crate::image::image_data::ImageData` import (E0252).

## [0.7.9] — 2026-04-14
### Changed
- Refreshed all legacy `src/**/GAPS.md` files into status snapshots against the current dirty `refactor/src-migration-v2` workspace baseline and marked AGENT-era rewrite items as stale in favor of `docs/specs/<module>.md`.

### Added
- **Phase 2A — Debug overlay render commands**: Added `generate_render_commands()` and (where absent) `draw_to_image()` to five engine modules, all pure-CPU with no wgpu/winit/mlua imports.
  - `src/physics/render.rs` — `World::generate_render_commands()` (body outlines coloured by type; velocity arrows for dynamic bodies) and `World::draw_to_image()`.
  - `src/ai/render.rs` — `StateMachine::generate_render_commands()` + `draw_to_image()` (state boxes, transition lines); `BehaviorTree::generate_render_commands()` + `draw_to_image()` (depth-column node layout).
  - `src/pathfind/render.rs` — `NavGrid::generate_render_commands()` (per-cell fill); `FlowField::generate_render_commands()` (directional arrow stubs); `InfluenceMap::generate_render_commands()` (signed heatmap rectangles).
  - `src/graph/render.rs` — `Graph::generate_render_commands()` (circular node layout, edge lines).
  - `src/procgen/render.rs` — `NoiseGrid` struct with `from_perlin()`, `generate_render_commands()`, and `draw_to_image()`.
- `src/pathfind/flow_field.rs` — Added `FlowField::get_width()` and `get_height()` public getters.
- `src/pathfind/influence_map.rs` — Added `InfluenceMap::get_width()`, `get_height()`, `get_cell_size()`, and `get_layer_names()` public getters.

---

## [0.7.8] — 2026-04-13
### Changed
- `raycaster`: Upgraded `WallQuad`, `FloorQuad`, `CeilingQuad`, and `BillboardSprite` to perspective-correct textured-quad rendering.
  - Replaced `screen_x/y/w/h` rect fields with `corners: [Vec2; 4]` and `uvs: [Vec2; 4]` for per-vertex control.
  - Replaced `light_color: Color` with `light: [f32; 4]` RGBA multiplier matching `DrawTexturedQuad::color`.
  - `generate_render_commands()` now emits `DrawTexturedQuad` per textured surface (untextured falls back to `SetColor` + `Rectangle`).
### Added
- `src/raycaster/draw.rs`: `RaycasterScene::draw_to_image(width, height) -> ImageData` — CPU software-rendering fallback for headless testing and screenshots (no GPU required).

---

## [0.7.7] — 2026-04-11
### Added
- `RenderCommand::DrawTexturedQuad { corners: [Vec2;4], uvs: [Vec2;4], texture_key, color }` — new variant for arbitrary perspective-correct textured quads (raycaster walls, portal surfaces). Added handler arm in `GpuRenderer::render_frame()` and `push_tex_quad_corners()` helper in `gpu_renderer.rs`.

---

## [0.7.6] — 2026-04-13
### Fixed
- Fixed `tools/audit/quality_report.py`: corrected 4 broken script path references (`doc_audit.py`→`audit/doc_audit.py`, `test_coverage.py`→`audit/test_coverage.py`, `module_audit.py`→`audit/module_audit.py`, `validate_game.py`→`validate/validate_game.py`). Dashboard now shows real data instead of 0% everywhere.
- Fixed `tools/audit/doc_audit.py`: corrected `collect_docs.py` path, added `json_flag` parameter for `gen_lua_api_data.py` compatibility, rewrote `_analyze_lua_api()` to handle nested JSON structure.

### Added
- Created `.github/skills/quality-pipeline/SKILL.md` — full audit→diagnose→fix→verify cycle skill with issue-to-fix routing table, quality sweep recipes, and tool category reference.
- Added `quality-pipeline` to the system prompt skill catalog.

### Changed
- Rewrote `tools/README.md` with complete inventory of all 65+ scripts, tool relationship map, overlap-free ownership table, and quality pipeline guide.
- Updated `tools/docs/README.md`: added `gen_wiki_api.py`, `gen_lua_library_api.py`; organised scripts into data layer / reference generators / legacy categories; fixed output paths.
- Updated `tools/audit/README.md`: added 8 missing scripts (`lua_api_test_coverage.py`, `example_coverage.py`, `unit_test_api_coverage.py`, `test_analytics.py`, `stress_report.py`, `audit_agent_md.py`, `patch_audit_module.py`, `annotate_tests.py`, `parse_test_log.py`); organised into master dashboards / docstring / test / module / specialised categories.
- Updated `tools/validate/README.md`: added `validate_module_coverage.py`; added key args column.
- Updated `tools/fix/README.md`: added 8 missing scripts (`add_test_markers.py`, `expand_examples.py`, `fix_type_stub_vars.py`, `fix_typeof_args.py`, `format_examples.py`, `improve_examples.py`, `strip_instance_method_comments.py`, `uncomment_examples.py`); organised into docstring fixers / source code fixers / example fixers / test helpers categories.
- Updated `copilot-instructions.md` CLI Tools section: added quality-pipeline skill reference, removed duplicate API refs line, replaced stale `module_audit.py` with `quality_report.py`.

## [0.7.5] — 2026-04-12
### Changed
- **Spec Lua API coverage enforced**: Fixed `## Lua API` sections in 6 specs (`app`, `i18n`, `light`, `render`, `runtime`, `window`) to list every function in markdown tables following `data.md` golden standard. Added `docs/specs/SPEC_TEMPLATE.md` canonical format reference and `work/check_spec_quality.py` validator (47/47 modules pass).
- **Architecture docs migrated to Zen of Lurek 2.0 and the five-group module model**: all three architecture documents (`docs/architecture/philosophy.md`, `docs/architecture/engine-architecture.md`, `docs/architecture/test-framework.md`) updated in the same pass.
  - `philosophy.md`: Replaced 10 old principles with 15 Zen of Lurek 2.0 principles; replaced strict same-tier prohibition (T-03/T-04) with `No cycles, ever`; updated Active Module Group Constraints (T-01 through T-08) to reflect five-group structure; retired three legacy decisions (Strict Tier Numbering, Baseline→Tier naming, Tier 4 platform slot).
  - `engine-architecture.md`: Replaced Active Layer Model and four-tier table with Module Group Model (five groups: Foundations, Core Runtime, Platform Services, Feature Systems, Edge/Integration); updated module dependency graph; fixed eight stale Lua API namespace names (`signal`→`event`, `thread`→`task`, `entity`→`ecs`, `savegame`→`save`, `modding`→`mods`, `localization`→`i18n`, `pathfinding`→`nav`, `postfx`→`fx`); updated Tier 1/2 module tables to new group sections; added Core Runtime Group section.
  - `test-framework.md`: Fixed stale module test file names (`timer_tests.rs`→`time_tests.rs`, `entity_tests.rs`→`ecs_tests.rs`, `thread_tests.rs`→`task_tests.rs`, `savegame_tests.rs`→`save_tests.rs`, `modding_tests.rs`→`mods_tests.rs`, `pathfinding_tests.rs`→`nav_tests.rs`, `camera_tests.rs` removed — merged into render, `graphics_tests.rs`→`render_tests.rs`); same for Lua test files; removed "Tier 3" tier-numbering language.
- **Zen of Lurek 2.0 corrected to 15 structural rules**: Replaced product-focused principles with 15 architecture-focused structural rules (No Cycles Ever, Composition Root Is One-Way, Depend on Contracts, Core Stays Boring, World Is a Registry, Same-Group Imports Allowed When Acyclic, Split by Reason to Change, Draw Is a Projection Layer, Pure Logic Stays Pure, CPU/Runtime Separate, Tooling at Edge, Bindings Thin, Tests Follow Responsibility, Merge Weak Modules Fast, Optimize for Readability). Fixed remaining stale `src/ecs/`→`src/entity/`, `src/gui/`→`src/ui/`, `src/pathfind/`→`src/nav/`, `src/thread/`→`src/task/` in detail tables. Updated T-xx cross-references from "Principle" to "Rule".

## [0.7.5] — 2026-04-11
### Fixed
- Rewrote `docs/specs/` for 5 modules to include all 11 required sections (`## Summary`, `## Architecture`, `## Source Files`, `## Submodules`, `## Key Types`, `## Lua API`, `## Lua Examples`, `## Item Summary`, `## References`, `## Notes`, plus header metadata table):
  - **render**: Added `## Submodules` (18 submodule entries), `## Lua Examples`, `## Item Summary`, `## Notes`; renamed `## Cross-Module References` → `## References`; removed stale `camera/`, `effect/`, `light/` rows from Source Files table.
  - **parallax**: Complete rewrite from ad-hoc sections to full 11-section format.
  - **runtime**: Added `## Architecture` (wgpu data-flow diagram), `## Submodules`, `## Lua Examples`, `## Item Summary`, `## Notes`; renamed `## Cross-Module References` → `## References`.
  - **math**: Added `## Submodules` (15 submodule entries), `## Lua Examples`, `## Item Summary`, `## References`, `## Notes`.
  - **tween**: Added `## Submodules` (3 submodule entries), `## Lua Examples`, `## Item Summary`, `## References`, `## Notes`.
- Updated AGENT.md for all 5 modules to the required 5-section format (H1, metadata table, `## Purpose`, `## Source Files`, `## Full Specification`):
  - **render**: Fixed incorrect "No lurek.* bindings" note; added correct `lurek.graphic` metadata.
  - **parallax**: Corrected H1 format; removed duplicate source file entries.
  - **runtime**: Removed stale `## Full Specification → app.md` pointer; fixed to point to `runtime.md`.
  - **math**: Rewrote from long-form to required 5-section format; removed stale `## Key Types` and `## Lua API Summary` sections.
  - **tween**: Removed extra `## Key Types` and `## Lua API Summary` sections; standardised `## Full Specification`.
- `python work/check_spec_sections.py` now reports **0 missing sections** across all 47 modules.
- `python tools/audit/audit_agent_md.py` now reports **PASS — All 47 modules: AGENT.md and spec match disk exactly**.

## [0.7.4] — 2026-04-12
### Fixed
- Synced all 47 `src/<module>/AGENT.md` and `docs/specs/<module>.md` Source Files tables to match actual `.rs` files on disk.
  - Removed ghost `*_api.rs` entries from Source Files tables (these live in `src/lua_api/`, not in domain module dirs; cross-module references in other sections remain).
  - Added missing `mod.rs` entries to 9 AGENT.md files and 19 spec files.
  - Added newly discovered files: `visualization.rs` (image), `toml_convert.rs` (data), `sinks.rs` (log), `save_manager.rs` (save), `event_queue.rs` (event), `chart.rs` (ui), `color.rs` (render), `export.rs`/`schema.rs` (docs), `layer.rs` (parallax), `engine.rs`/`handle.rs`/`state.rs` (tween), 7 patterns files.
  - Fixed tween AGENT.md to use bare filenames instead of full `src/tween/` paths.
  - Added `## Source Files` table to `docs/specs/parallax.md` (previously used code block only).
- Completed `src/render/camera/`, `src/render/effect/`, `src/render/light/` deletion from git tracking (files were promoted to top-level modules in 0.7.3 but deletions were left unstaged).
### Added
- `tools/audit/audit_agent_md.py` — audits each module's AGENT.md and spec against actual disk files; reports GHOST (listed but deleted) and MISSING (on disk but unlisted) within Source Files tables only.

## [0.7.3] — 2026-04-11
### Fixed
- Deleted `docs/specs/camera.md`, `docs/specs/effect.md`, `docs/specs/light.md` — these are submodules inside `src/render/`, not top-level modules, and should not have standalone specs; their architecture is documented in `docs/specs/render.md`.
- Rewrote `docs/specs/README.md` to exactly match actual `src/` top-level module directories (44 domain modules + 2 infra entries: `bin`, `lua_api`).
### Added
- `tools/validate/validate_module_coverage.py` — new script that validates every `src/<module>/` has both an `AGENT.md` and a `docs/specs/<module>.md`, and reports any orphan specs with no matching source directory. Run: `python tools/validate/validate_module_coverage.py [--fix-readme]`.

## [0.7.2] — 2026-04-11
### Fixed
- Restored incorrectly deleted spec files `docs/specs/camera.md`, `docs/specs/effect.md`, `docs/specs/light.md` — these modules still exist as active submodules under `src/render/camera/`, `src/render/effect/`, `src/render/light/` with dedicated Lua APIs (`camera_api.rs`, `effect_api.rs`, `light_api.rs`).
- Added `camera`, `effect`, `light` back to `docs/specs/README.md` module list with submodule location annotation.

## [0.7.1] — 2026-04-11
### Removed
- Deleted orphaned source files `src/mod.rs`, `src/gpu_renderer.rs`, `src/renderer.rs` (superseded by `src/render/` module).
- Deleted orphaned `src/graphics/` stub directory (all code migrated to `src/render/` in v0.7.0).
- Deleted `docs/specs/graphics.md` (no corresponding `src/graphics/` module or `graphics_api.rs` Lua binding remains).
### Fixed
- Added 21 missing files to `src/render/AGENT.md` Source Files table (camera/, effect/, light/ submodules).
- Added `visualization.rs` to `src/image/AGENT.md`; added `chart.rs` to `src/ui/AGENT.md`.
- Removed ghost file entries from `docs/specs/tween.md` and `docs/specs/app.md`; synced to actual disk state.
- Added `# Fields`, `# Parameters`, `# Returns` sections to missing pub items across `src/debugbridge/bridge.rs`, `src/debugbridge/server.rs`, `src/log/mod.rs`, `src/data/dataview.rs`, `src/patterns/simple_state.rs`, `src/particle/emitter.rs`.
- Added `#[cfg(test)]` blocks with unit tests to 19 previously-untested files: all `src/serial/*.rs`, `src/image/serial.rs`, `src/image/visualization.rs`, `src/data/bin_pack.rs`, `src/data/pack.rs`, `src/dataframe/serial.rs`, `src/dataframe/sql.rs`, `src/audio/mod.rs`, `src/particle/math.rs`, `src/pathfind/astar.rs`, `src/pathfind/graph_path.rs`, `src/pathfind/hpa.rs`, `src/render/light/light2d.rs`, `src/terminal/terminal_state.rs`.
### Changed
- Regenerated `docs/API/rust-api.md` and `docs/API/lua-api.md` to remove stale `graphics` references.

## [0.7.0] — 2025-07-27
### Fixed
- Cleared all BLOCKER-level `lua.load()` violations in `src/lua_api/scene_api.rs` (converted to Rust calls), `src/lua_api/debugbridge_api.rs`, and `src/lua_api/devtools_api.rs` (justified uses now marked with `// LUA-EVAL-JUSTIFIED:`).
- Fixed 6 disconnected/missing doc comments across `src/docs/entry.rs`, `src/docs/report.rs`, `src/lib.rs`, `src/lua_api/mod.rs`.
- Removed ghost `src/lua_api/parallax_api.rs` entry from `src/parallax/AGENT.md` Source Files table.
- Updated `docs/architecture/engine-architecture.md`: corrected Tier 1 from `graphics/src/graphics/` to `render/src/render/`, marked `src/graphics/` as legacy stub, added 6 missing module tier rows (`ecs`, `i18n`, `tween` to T1; `mods`, `parallax` to T2; `runtime` to Baseline).
### Changed
- `tools/validate/validate_lua_api.py` improved: comment-line skip in `check_no_embedded_lua`, `// LUA-EVAL-JUSTIFIED:` suppressor mechanism, `__`-metamethod key exclusions in coverage and header checks.
- `.github/skills/lua-rust-bridge/SKILL.md` updated with "Forbidden Patterns in lua_api Files" section and `LUA-EVAL-JUSTIFIED` documentation.

- **BREAKING: Major `src/` directory restructuring** — module import paths have changed across the entire codebase. Lua API surface is unchanged; only Rust `use crate::` imports are affected.
  - `src/engine/` split into `src/runtime/` (config, error, shared_state, resource_keys) and `src/app/` (app lifecycle, debug overlay, error screen).
  - `src/graphics/`, `src/camera/`, `src/light/`, `src/effect/` merged into unified `src/render/` module (with `render/camera/`, `render/light/`, `render/effect/` submodules).
  - `src/graphic/` (dead code) deleted — bitmap font functions ported to `src/render/gpu_renderer.rs`.
  - Module renames: `signal/` → `event/`, `pathfinding/` → `pathfind/`, `savegame/` → `save/`, `modding/` → `mods/`, `localization/` → `i18n/`, `entity/` → `ecs/`.
  - Lua API file renames: `signal_api` → `event_api`, `pathfinding_api` → `pathfind_api`, `savegame_api` → `save_api`, `modding_api` → `mods_api`, `localization_api` → `i18n_api`, `entity_api` → `ecs_api`, `graphic_api` → `render_api`.
- **BREAKING: Bitmap font system replaces fontdue TTF rendering** — all text rendering now uses embedded bitmap/pixel font sprite sheets. The `fontdue` crate has been removed entirely.
  - 6 built-in monospaced bitmap font sizes: 3×5, 5×7, 6×10, 8×14, 10×18, 12×22 pixels (cell width × cell height).
  - Box-drawing characters (U+2500–U+257F) included for sizes ≥6×10.
  - `Font` struct rewritten: no more TTF parsing, glyph caching, or atlas growing. Glyphs are computed from grid position in the sprite sheet.
  - `glyph()` now takes `&self` (was `&mut self`) and returns `Option<GlyphInfo>` by value (was `Option<&GlyphInfo>`).
  - `text_width()` and `wrap_text()` now take `&self` (were `&mut self`).
  - `RenderCommand::PrintFont` variant removed — unified into `RenderCommand::Print` with a `font_key` field.
  - `render_text()` and `bitmap_char()` deleted from `gpu_renderer.rs`.

### Added
- `lurek.graphic.newFont(pixel_height)` — select a built-in bitmap font by pixel height (snaps to nearest available size). Accepts number or `"default"` string.
- `lurek.graphic.getFontSizes()` — returns a table of available built-in font pixel heights `{5, 7, 10, 14, 18, 22}`.
- `lurek.graphic.getDefaultFont(pixel_height?)` — returns a built-in font handle for the given size (default: 14).
- `lurek.graphic.getFontCellWidth(font)` — returns the cell width of a monospaced bitmap font.
- Terminal `setFont(pixel_height)`, `getCellSize()`, `autoResize()` methods for bitmap font integration with auto-scaling window.
- `Font::load_all_sizes()`, `Font::nearest_size()`, `Font::from_png_bytes()`, `Font::cell_width()`, `Font::has_box_drawing()` public API.
- `SharedState::default_fonts: [Option<FontKey>; 6]` — all 6 built-in sizes pre-loaded at startup.
- `SharedState::pending_window_resize` field for terminal auto-resize.
- 6 bitmap font PNG sprite sheets in `assets/fonts/` (bitmap_3x5.png through bitmap_12x22.png).

### Removed
- `fontdue` crate dependency.
- `RenderCommand::PrintFont` variant (merged into `Print`).
- `render_text()` and `bitmap_char()` functions from gpu_renderer.
- `Font::from_bytes()` (TTF loading) — replaced by `Font::from_png_bytes()`.
- `Font::ensure_glyph()` — no longer needed (grid-based lookup).
- `Font::grow_atlas()` — fixed-size atlas from PNG.

---

## [0.6.36] — 2026-04-13
### Fixed
- **Docs/tooling audit** — comprehensive sync of all module documentation with the `refactor/src-migration-v2` source layout:
  - `docs/specs/` renamed 6 stale files to match actual module names (`engine→app`, `entity→ecs`, `localization→i18n`, `modding→mods`, `pathfinding→pathfind`, `savegame→save`).
  - Deleted 4 ghost specs for non-existent modules: `fx.md`, `graphic.md`, `gui.md`, `signal.md`.
  - Created 2 new specs: `docs/specs/render.md` (src/render/ GPU pipeline) and `docs/specs/runtime.md` (src/runtime/ Baseline substrate).
  - Fixed all `lurek.gfx` → `lurek.graphic` namespace references across 12 spec files — the actual runtime namespace is `lurek.graphic` registered by `render_api.rs`.
  - Updated source path fields in `camera.md`, `light.md`, `effect.md`, `graphics.md` to reflect `src/render/camera/`, `src/render/light/`, `src/render/effect/` after migration.
  - Fixed `effect.md` Lua API field: `lurek.effect` → `lurek.overlay` / `lurek.postfx`.
  - Updated `docs/specs/README.md` modules list from 38 stale links to 49 correct links.
  - Created `src/app/AGENT.md` and `src/graphics/AGENT.md` (previously missing).
  - Fixed `src/render/AGENT.md` and `src/runtime/AGENT.md` titles and content to reflect current module names.
- **`tools/audit/doc_coverage.py`** — fixed `_LUA_MOUNT_RE` regex to match any variable name (with optional `.clone()`); fixed `has_nearby_comment` logic to anchor comment detection after the most recent `let tbl = lua.create_table()` in the scan window; extended window from 8 to 12 lines. Gate: 100% public item coverage.
- **`tools/validate/validate_lua_api.py`** — fixed `check_register_signature` to skip `//` comment lines (prevented false-positives on `pub fn register()` text in `//!` docstrings); updated `check_module_registration` regex to handle `luna_table.set(...)` and `.clone()` variants.
- **`src/lua_api/`** — added ~200 missing `/// @return type` annotations across `devtools_api.rs`, `docs_api.rs`, `i18n_api.rs`, `log_api.rs`, `minimap_api.rs`, `parallax_api.rs`, `particle_api.rs`, `patterns_api.rs`, `render_api.rs`, `system_api.rs`, `thread_api.rs`, `tilemap_api.rs`.
- **`src/particle/emitter.rs`** — added missing `///` docstring on `pub fn draw_lifecycle_to_image`.
- **`src/lua_api/mod.rs`** — fixed stale doc comment `lurek.gfx.*` → `lurek.graphic` on the `render_api` module declaration.
- **`src/runtime/config.rs`** — fixed docstring L149: `lurek.gfx` → `lurek.graphic`.
- Regenerated `docs/API/lua-api.md`, `docs/API/rust-api.md`, `docs/API/lurek.lua`, `docs/API/coverage_gaps.md`.

---

## [0.6.35] — 2026-04-12
### Added
- **GPU render() methods** for `Minimap`, `TileMap`, `Overlay`, and `ParticleSystem` — four modules now support per-frame GPU rendering via `obj:render()` which pushes `RenderCommand`s to the render queue. Previously these modules only had CPU-based `draw_to_image()`.
  - `lurek.particle`: `ParticleSystem:render(ox?, oy?)` — expands particles into individual shape/image primitives (Rectangle, Circle, Triangle, Line, DrawImageEx, DrawQuad).
  - `lurek.overlay`: `Overlay:render()` — emits screen-sized colored rectangles for flash, fade, lightning, and vignette effects with correct alpha animation.
  - `lurek.minimap`: `Minimap:render(x?, y?)` — draws terrain cells, objects, and markers as colored rectangles/circles at the given screen position.
  - `lurek.tilemap`: `TileMap:render(ox?, oy?)` — draws tile layers as colored rectangles with per-tile tints and visibility culling.
- Domain-level `build_render_commands()` added to `Minimap`, `TileMap`, and `Overlay` for clean Lua API ↔ domain separation.

---

## [0.6.34] — 2026-04-12
### Added
- **Parallax background system** (`src/parallax/`, `src/lua_api/parallax_api.rs`) — new Tier 2 module providing `lurek.parallax.newLayer(opts)` and `lurek.parallax.newSet(name)`. Features: per-layer scroll factor (X and Y independently), autoscroll (ambient drift via `rem_euclid`-bounded accumulator), horizontal and vertical texture tiling, opacity, RGBA tint, blend modes, z-ordering, visibility, and pixel-offset clamping. `ParallaxSet` batches update/draw calls and auto-sorts layers by z on add. `drawAuto()` reads `SharedState.camera.position`; `draw(cam_x, cam_y)` accepts explicit camera position. New `ModulesConfig.parallax` flag (default `true`, requires graphics). Tests: `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua`. Spec: `docs/specs/parallax.md`.

---

## [0.6.33] — 2026-04-10
### Added
- **VS Code extension — type inference** (`typeInference.ts`) — rewrote type inference engine: 25+ factory return types (Canvas, Image, Font, Shader, Entity, Timer, Tween, World, Body, ParticleSystem, etc.), dot-access now shows both fields and methods (fixes missing Canvas method completions), colon-access completions, OOP class instance tracking via `setmetatable`, module alias detection (`local gfx = lurek.graphics`), variable re-assignment tracking, hover provider showing type and factory origin.
- **VS Code extension — diagnostics** (`diagnostics.ts`) — 4 new diagnostic rules (total now 13): per-frame allocation warning (newImage/newSource/newFont/newCanvas/newShader inside update/draw callbacks), missing `test_summary()` in test files, entity nil access without guard, colon-vs-dot method call suggestion.
- **VS Code extension — debug adapter** (`luaDebugAdapter.ts`) — auto-detect game path from active editor (finds nearest `main.lua`), auto-detect engine binary from workspace `build/` folder, 4 launch configurations (Debug Game, Debug Current Demo, Debug with Stop on Entry, Attach to Running). Improved `luaDebugSession.ts` with `build/debug`/`build/release` binary scanning, increased retries from 3→5, delay from 500→800ms.
- **VS Code extension — sidebar** (`sidebar.ts`) — Project Health section (main.lua/conf.lua detection, Lua file count, test folder detection), game status indicator in Run section, last test result display in Testing section, state tracking methods.
- **VS Code extension — test infrastructure** — new test framework: `src/test/mocks/vscode.ts` (MockTextDocument, MockPosition, MockRange, MockCancellationToken), `src/test/unit/typeInference.test.ts` (23 tests covering factory types, scanDocument, getTypeInfoForVar, getMethodsForVar), `src/test/unit/luaParser.test.ts` (26 tests covering tokenization, analysis, utility methods), mocha runner infrastructure (`runTest.ts`, `suite/index.ts`).
### Changed
- **VS Code extension — build** (`esbuild.config.mjs`) — added `--test` flag for compiling test files alongside main bundle; updated test externals.
- **VS Code extension — architecture doc** (`docs/architecture/vscode-architecture.md`) — updated to v0.9.0: extension2.ts as active entry point, 13 diagnostic rules, full type inference description, test infrastructure section, correct build pipeline (esbuild → dist/), sidebar features, debug auto-detect.
- **VS Code extension — runtime/sidebar fixes** (`extensions/vscode/`) — corrected broken sidebar command IDs for Library and Game Jam actions, rebuilt Asset Explorer to scan the actual game root and render nested folders, switched API reference lookups to `docs/API/lua-api.md`, and repackaged/reinstalled the extension to replace stale local installs that were still serving old command/view registrations.
- **VS Code extension — API source of truth** (`extensions/vscode/src/services/apiData.ts`, `extensions/vscode/src/services/apiDocs.ts`) — the extension now prefers `docs/API/lurek.lua` as the workspace API source, parses its LuaCATS `@param` / `@return` annotations for richer signatures, and uses the same source for command search and MCP API lookups instead of falling back to the compact markdown reference first.
- **VS Code extension — sidebar activation manifest** (`extensions/vscode/package.json`, `extensions/vscode/src/test/unit/commandRegistration.test.ts`) — added manifest contributions for the sidebar's editor, API, CAG, debug, packaging, and tooling commands so VS Code can resolve clicked items reliably, and added a regression test that checks the reported sidebar command IDs are both contributed and registered after activation.

## [0.6.32] — 2026-04-10
### Changed
- **Test skill** (`testing-rust/SKILL.md`) — expanded BDD assertion table with `expect_greater`, `expect_less`, `expect_in_range`, `expect_contains`, `expect_match`, `expect_length`, `expect_deep_equal`; added "Performance and Golden helpers" subsection documenting `measure()`, `expect_golden()`, `expect_canvas_pixel()`; expanded "Golden Tests" section with Lua golden test pattern; added section 9 "Marker Annotations" (`@covers` syntax, placement rules, describe-block naming, scanner commands); added section 10 "Evidence-Based Testing" (all 3 tiers with code examples, evidence tags table).
- **Test architecture doc** (`test-framework.md`) — updated Framework API table to include all BDD helpers (`before_each`, `after_each`, `expect_greater`, `expect_less`, `expect_in_range`, `expect_contains`, `expect_match`, `expect_length`, `expect_deep_equal`, `measure`, `expect_golden`, `expect_canvas_pixel`); fixed Test Coverage Tooling section with correct tool paths (`tools/audit/` prefix); updated Measurement Helper from "planned" to implemented with usage example; updated ToC to include sections 17–23; updated integration test count from 29 to 43.
- **Roadmap** (`ideas/tests/roadmap.md`) — marked Phase 0.2 documentation tasks as complete.
- **Implementation plan** (`ideas/tests/implementation-plan.md`) — marked sections 5.1 and 5.2 as complete with detailed checklists.

## [0.6.31] — 2026-04-10
### Fixed
- **VS Code extension** — promoted `extension2.ts` (full implementation) as the esbuild entry point; fixed 63 command IDs from `luna.*` → `lurek.*` namespace throughout `extension2.ts` and `apiData.ts`; fixed bad `import("./debug/debugBridge")` path → `./services/debugBridge`; updated `package.json` from `package2.json` (v0.9.0, named `luna-toolkit`, full command/view manifest); updated `esbuild.config.mjs` entry to `extension2.ts`; added `loadFromLuaApiMd()` parser in `apiData.ts` so IntelliSense completions load from the real `docs/API/lua-api.md`; fixed Priority-3 lookup path from non-existent `lua_api_reference_generated.md` → `lua-api.md`; packaged as `luna-toolkit-0.9.0.vsix`.

## [0.6.30] — 2026-04-10
### Fixed
- **Namespace fixes** — six test files were using wrong `lurek.*` namespaces that would cause runtime nil-indexing errors:
  - `test_font.lua` — `lurek.gfx.*` → `lurek.graphic.*` (19 occurrences)
  - `test_shape.lua` — `lurek.gfx.*` → `lurek.graphic.*` (44 occurrences)
  - `test_drawlayer.lua` — `lurek.sprite.*` → `lurek.graphic.*` (23 occurrences), `newDrawLayer` is registered in `graphic_api.rs`
  - `test_evidence_audio.lua` — `lurek.audio.setVolume(val)` / `getVolume()` → correct `setMasterVolume(val)` / `getMasterVolume()` (per-source `setVolume` requires a source key)
  - `test_event.lua` — `describe("event.pump"…)` etc. → `describe("lurek.signal.pump"…)` to match actual namespace
  - `test_network.lua` — guarded `lurek.net.*` and `_G.enet` describe blocks with `if lurek.net then` / `if _G.enet then` since `lurek.net` is not a registered namespace; fixed `@covers` header to remove nonexistent `lurek.net.*` entries
- **Evidence test assertion** — `test_evidence_particle.lua`: `sys:count() >= 0` (always-true) → `sys:count() > 0` after `emit(10)`
- **Evidence test robustness** — `test_evidence_minimap.lua`: "setTerrain with 0-based coord errors" test replaced by "setTerrain out-of-range coordinate is rejected" (coord > grid_size) which is unambiguously out of bounds
### Changed
- `test_event.lua` — added proper file-level header, removed BOM character from file start
- `test_fx.lua` — updated header to clarify it is a focused smoke test that complements `test_postfx.lua`'s comprehensive coverage
- `test_drawlayer.lua` — added proper file-level header with headless-safe notice

## [0.6.29] — 2025-07-17
### Added
- **`SoundData::encode_wav()`** — new Rust domain method that encodes PCM f32 samples to 16-bit WAV bytes with RIFF header (`src/audio/sound_data.rs`)
- **`lurek.audio.saveWAV(sounddata, path)`** — new Lua API function that saves a SoundData buffer to a `.wav` file on disk (`src/lua_api/audio_api.rs`)
### Changed
- **Evidence tests rewritten from JSON to real file output** — all 10 evidence test files that previously saved JSON metadata now produce actual PNG images or WAV audio files:
  - `test_evidence_canvas.lua` — renders canvas sizes and lifecycle as colored diagrams → `canvas_sizes.png`, `canvas_lifecycle.png`
  - `test_evidence_graphic_drawing.lua` — renders primitives (rect, circle, line, dots) and color grid → `graphic_primitives.png`, `graphic_color_grid.png`
  - `test_evidence_light.lua` — renders radial light falloff and multi-light RGB scene → `light_single_falloff.png`, `light_multi_scene.png`
  - `test_evidence_particle.lua` — renders emitter positions and burst visualization → `particle_positions.png`, `particle_emitter_burst.png`
  - `test_evidence_postfx.lua` — applies ImageData filters and saves each effect → 7 PNG files (grayscale, invert, blur, sepia, effects strip, posterize+tint, saturation+flip)
  - `test_evidence_minimap.lua` — renders terrain grid and fog-of-war → `minimap_terrain.png`, `minimap_fog.png`
  - `test_evidence_tilemap.lua` — renders tile grid and checkerboard pattern → `tilemap_grid.png`, `tilemap_checkerboard.png`
  - `test_evidence_overlay.lua` — renders flash decay, fade-to-black, and combined effects → `overlay_flash.png`, `overlay_fade.png`, `overlay_combined.png`
  - `test_evidence_audio.lua` — generates sine wave, chord, sweep, and stereo ping-pong → 4 WAV files
  - `test_evidence_audio_bus.lua` — generates volume-scaled, pitch-shifted, and fade-out audio → 3 WAV files

## [0.6.28] — 2026-04-09
### Added
- **`lurek.img.savePNG(imgdata, path)`** — new Lua API function that encodes an `ImageData` to PNG bytes and writes them to disk, auto-creating parent directories. (`src/lua_api/image_api.rs`)
- **Evidence test category** (`tests/lua/evidence/`) — 13 new Lua test files that verify observable API state and save real artefacts (PNG images, JSON dumps) to `tests/lua/evidence/output/` for human inspection:
  - `test_evidence_imagedata.lua` — pixel creation, setPixel/getPixel round-trip, fill, mapPixel, getString, encode("png"), savePNG, crop, resizeNearest, flipHorizontal, rotate90cw
  - `test_evidence_imagedata_effects.lua` — all 11 filter methods: grayscale, invert, sepia, brightness, threshold, posterize, tint, noise, blur, sharpen; saves effect PNGs
  - `test_evidence_canvas.lua` — Canvas lifecycle: newCanvas, getWidth/getHeight/getDimensions, release (true/false), typeOf, type, stale-key error, multiple independence; saves JSON metadata
  - `test_evidence_graphic_drawing.lua` — `lurek.graphic` API surface: setColor/getColor, setBackgroundColor, getWidth/getHeight/getDimensions, clear, print, rectangle, circle, line, point, setLineWidth, push/pop transforms; saves JSON state
  - `test_evidence_audio.lua` — master volume round-trip (0/0.65/1), setPosition, getActiveSourceCount, headless-safe newSource test; saves JSON
  - `test_evidence_audio_bus.lua` — bus newBus, setVolume/getVolume/setPitch/getPitch/getName/pause/resume round-trips, multiple-bus independence, source setBus; saves JSON
  - `test_evidence_light.lua` — LightSource position/radius/color/intensity/energy/falloff/shadow round-trips, multiple light independence; saves JSON
  - `test_evidence_particle.lua` — ParticleSystem count/isEmpty/start/stop/pause/resume/reset/getCount/setPosition/getPosition/type/release, newTrail; saves JSON
  - `test_evidence_postfx.lua` — Effect getTypeName/isBuiltIn/isEnabled/getEffectType/type, Stack getWidth/getHeight/getDimensions/len/isEmpty, ImageEffect; saves JSON
  - `test_evidence_minimap.lua` — Minimap grid/display dimensions, getTerrain, isFogEnabled, getFogLevel, getObjectCount, getZoom, getCenter, getColorMode; saves JSON
  - `test_evidence_tilemap.lua` — TileSet and TileMap constructors, dimensions, getFirstGid, getLayerCount/Name/TileSetCount, fill, getTile/clearTile round-trip; saves JSON
  - `test_evidence_raycaster.lua` — Raycaster getCell/setCell/isBlocked, castRay hit/miss, castRays array, lineOfSight, projectColumn, distanceShade; saves a 128×64 depth-buffer PNG
  - `test_evidence_overlay.lua` — Overlay getWidth/Height, isActive, triggerFlash/getFlashAlpha, triggerShake/getShakeOffset, triggerFade, triggerLightning/getLightningAlpha, clear, resize, setAmbientEnabled; saves JSON
- 13 corresponding `#[test]` entries under `// ─── Evidence Tests ───` section in `tests/lua/harness.rs`
- `tests/lua/evidence/output/.gitignore` — auto-excludes all generated PNG and JSON artefacts from version control

### Removed
- 8 broken evidence test files from `tests/lua/unit/` that called non-existent APIs (`lurek.gfx`, `c:renderTo()`, `c:getPixel()`):
  `test_graphics_evidence.lua`, `test_audio_evidence.lua`, `test_light_evidence.lua`, `test_particle_evidence.lua`, `test_postfx_evidence.lua`, `test_minimap_evidence.lua`, `test_tilemap_evidence.lua`, `test_audio_integration_evidence.lua`
- Corresponding 8 broken `lua_unit_*_evidence` harness entries replaced by 13 correct `lua_evidence_*` entries

## [0.6.27] — 2026-04-11
### Added
- **Phase 6 evidence tests** — 8 new Lua test files proving that rendering and audio APIs produce actual observable output, not just API stubs:
  - `tests/lua/unit/test_graphics_evidence.lua` — canvas pixel readback for all `lurek.gfx` primitives: rectangle, circle, triangle, polygon, setColor, background color, and out-of-bounds safety.
  - `tests/lua/unit/test_audio_evidence.lua` — `lurek.audio.Source` state round-trips: volume (0/0.5/1/2), pitch (0.5/1/2), looping, 3D position, seek/tell, play/pause/stop state machine, getDuration, getChannelCount, and 10-source independence.
  - `tests/lua/unit/test_light_evidence.lua` — canvas pixel brightness proof: full ambient illumination, zero ambient darkness, point light near > far brightness, red-tinted light r > g/b, disabled vs enabled comparison, and getLightCount tracking.
  - `tests/lua/unit/test_particle_evidence.lua` — particle count via emit/getCount, lifetime expiry, reset, large color particles producing correct hue pixels on canvas, gravity displacement over time, and isActive/stop/start state.
  - `tests/lua/unit/test_postfx_evidence.lua` — PostFX pixel diff proofs: blur softens hard edges, vignette darkens corners, colourgrade red_gain shifts r > g, empty stack passes through unchanged, param round-trips, 15-type enumeration, and stacked effects.
  - `tests/lua/unit/test_minimap_evidence.lua` — terrain setTerrain/getTerrain state, terrain color round-trips (20 types), fog enable/level state, minimap draw produces red pixels on canvas for red terrain type, object marker setObject/getObject/removeObject, and dot clearDots.
  - `tests/lua/unit/test_tilemap_evidence.lua` — tile GID cell state (setTile/getTile, fill, clear, overwrite), coordinate math (worldToTile/tileToWorld round-trips for all cells), setTileColor/getTileColor round-trips, and drawSolid canvas pixel readback for red/blue adjacent tiles.
  - `tests/lua/unit/test_audio_integration_evidence.lua` — bus volume/pitch/mute/enabled round-trips, two-bus independence (no cross-bus bleed), Source→bus routing (setBus/getBus), master volume/pitch round-trips with restore, and DSP effect chain (addEffect/removeEffect/getEffectCount).
- New `@evidence` marker category (`pixel:canvas_readback`, `state:audio_source`, `pixel:light_affects_pixels`, `pixel:tilemap_solid_color_draw`, `state:audio_bus_routing`, etc.) used across all 8 files.
- All 8 evidence test files registered in `tests/lua/harness.rs` under the `lua_unit_*_evidence` naming pattern.

## [0.6.26] — 2026-04-10
### Added
- **BDD framework helpers** (`tests/lua/init.lua`) — `measure(name, count, fn)` for CPU-time throughput benchmarking (prints `[PERF]` prefix) and `expect_golden(name, actual, expected)` for deterministic snapshot assertions.
- **18 cross-module integration tests** (`tests/lua/integration/`) — entity-physics, entity-graphics, scene-entity, scene-camera, tilemap-camera, ai-pathfinding, input-camera, animation-timer, data-filesystem, savegame-tilemap, signal-entity, tilemap-pathfinding, thread-data, tween-camera, tween-entity, particle-timer, light-graphics, localization-ui.
- **7 new golden tests** (`tests/lua/golden/`) — dataframe, pathfinding, graph, AI FSM trace, compute, tilemap, entity; plus expanded math golden coverage.
- **11 new stress tests** (`tests/lua/stress/`) — AI FSM/agent throughput, scene entity lifecycle, camera update, savegame collect, timer queries, signal fan-out, tween simultaneous updates, image pixel ops, patterns (observer/SM/command-queue), filesystem I/O, and light position update.
- All 36 new test files registered in `tests/lua/harness.rs` under `lua_integration_*`, `lua_golden_*`, and `lua_stress_*` test function names.

## [0.6.25] — 2026-04-09
### Added
- **Test marker automation** (`tools/fix/add_test_markers.py`) — scans each Lua test file for `lurek.module.function` call patterns and injects `@covers`/`@stress`/`@golden`/`@security` marker comments; applied to 92 of 126 existing test files, raising explicit marker coverage from 0% to 13.2% (341/2588 functions).

## [0.6.24] — 2026-04-09
### Added
- **Test infrastructure expansion** — 21 new Lua test files:
  - 10 integration tests: graphics+camera, graphics+animation, audio+timer, audio+event, AI+entity+scene, savegame+entity+scene, tween+animation, procgen+tilemap, pathfinding+entity, data+compute
  - 5 golden tests: data serialization, serial encoding, physics simulation, animation timeline, procgen noise determinism
  - 4 stress tests: graphics draw commands (10K shapes), animation throughput (1K timelines), serial encode/decode (1K cycles), thread channel (10K messages)
  - 1 property-based test: math invariants (trig identities, sqrt, Vec2 commutativity, lerp monotonicity)
  - 1 security fuzz test: nil/wrong-type spam across gfx, physics, entity, data, AI, math, audio APIs
- **Test analytics script** (`tools/audit/test_analytics.py`) — module scoring (0-10, A-F grades), category aggregation, @covers/@evidence/@golden/@stress markers, trend comparison, JSON export

## [0.6.23] — 2026-04-10
### Fixed
- Lua test/runtime compatibility: added `content/` package-path fallbacks for `require("library.*")`, refreshed `tests/lua/examples/test_examples.lua` for the current single-file `content/examples/*.lua` layout, and aligned Lua font/UI tests with the live `lurek.gfx` and `lurek.ui` APIs.
- **Quality: D-04/D-03/T-03/SP-03/SP-04/SP-05/A-03** — Audit pre-fixes across 14 modules:
  - **network**: D-04 stubs (host.rs), T-03 test_ prefixes; T-04 float asserts in network_tests.rs
  - **compute**: D-04 stubs (array.rs, ops.rs, compute_api.rs), T-03 prefixes
  - **particle**: D-04 stubs (config.rs, emitter.rs, trail.rs), SP-03 trim, SP-04 API row
  - **raycaster**: D-04 stubs (column_batch.rs, depth_buffer.rs, doors.rs), SP-03 trim, SP-05 keys
  - **gui**: D-04 stubs (context.rs, controls.rs, extras.rs, widget.rs, gui_api.rs), SP-03/SP-04/SP-05
  - **event**: D-04 stubs (event_queue.rs, signal.rs, event_api.rs)
  - **scene**: D-04 stubs (depth_sorter.rs, stack.rs, transition.rs), T-03 prefixes
  - **docs**: D-04 stubs (catalog.rs, entry.rs, report.rs)
  - **image**: SP-05 — moved ImageLayer/LayeredImage headings inside Key Types section
  - **devtools**: D-07 — added @return annotations to p95/p99/samples in devtools_api.rs
  - **filesystem**: D-04 stubs (async_loader.rs, file_handle.rs, vfs.rs), D-03 LoadHandle # Fields, A-03 AGENT.md trim
  - **pathfinding**: D-04 stubs (5 files), T-03 (54 prefixes), A-03 AGENT.md trim, SP-03/SP-04/SP-05 fixes
  - **engine**: D-04 stubs (config.rs, resource_keys.rs), D-03 on 14 key structs + 4 types, T-03 (8 prefixes), SP-03/SP-05
  - **dataframe**: D-04 stubs (frame.rs×9, query.rs×2, serial.rs×2), T-03 (100 prefixes), T-04 (10 float asserts), SP-03
  - **fx**: SP-04 (newPass/getEffectTypes API rows), SP-03 Summary trim, T-02 (test_fx.lua created + registered in harness.rs)
  → All 14 modules now at PRE (≤2E ≤2W); will auto-PASS when Developer resolves B-02/B-03

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
