# runtime

## General Info

- Module group: `Core Runtime`
- Source path: `src/runtime/`
- Lua API path(s): None direct
- Primary Lua namespace: `lurek.runtime.setLogLevel`
- Rust test path(s): tests/rust/unit/window_tests.rs, tests/rust/ext/graphics_runtime_smoke_tests.rs, plus runtime-focused unit coverage embedded in src/runtime/messages.rs
- Lua test path(s): tests/lua/config/test_config.lua, tests/lua/harness.rs

## Summary

The `runtime` module is the foundational layer of Lurek2D — every other Rust module imports from it. It provides the central shared state, engine configuration, error handling, resource key types, and the structured log message catalog. Nothing in the engine imports from `runtime`'s upstream; it is the dependency tree's root.

`SharedState` is the engine's central mutable context, passed as `Rc<RefCell<SharedState>>` to every subsystem and Lua binding. It holds: the `EventQueue` for the current frame, all input state objects (`KeyboardState`, `MouseState`, `GamepadState`, `TouchState`), the active `Camera`, `LightWorld`, audio `Mixer`, `Clock`, `GameFS`, `GuiContext`, active `ParticleSystem`s, `TileMap`s, and the pending `Vec<RenderCommand>` for the frame. `WindowState` tracks window dimensions, fullscreen mode, and deferred window-management commands. `FullscreenType` discriminates borderless vs exclusive fullscreen. `RendererStats` carries per-frame draw call counts and timing.

`Config` is loaded from `conf.toml` at boot and covers window settings (`width`, `height`, `fps_cap`, `vsync`), graphics backend selection, performance tuning (`physics_tick_rate`, `fixed_update_tick_rate`, `frame_budget_warn_ms`), and `ModulesConfig` — per-module feature flags that gate which `lurek.*` sub-APIs are registered. `ModulesConfig::validate_and_fix()` enforces dependency constraints (e.g. `minimap` requires `graphics`). `EngineError` is a flat enum covering config, filesystem, Lua, rendering, audio, and physics error categories, each with a stable four-digit code and recovery hint. `EngineResult<T>` is the global `Result<T, EngineError>` alias used across all modules.

Resource key types (`TextureKey`, `FontKey`, `ShaderKey`, `MeshKey`, `CanvasKey`, `SpriteBatchKey`, `ParticleKey`, `SoundKey`) are newtyped `slotmap::DefaultKey` values for typed SlotMap pools. Log message IDs are stable four-character codes defined in `log_messages.rs`.

**Scope boundary**: Foundations tier. Imports only from external crates. Everything else imports from `runtime`.

## Files

- `config.rs`: Engine configuration loaded from `conf.toml`.
- `error.rs`: Structured error types and result alias for the Lurek2D engine.
- `log_messages.rs`: Structured logging with stable message IDs for the Lurek2D engine.
- `messages.rs`: TOML-backed message catalog for stable, human-readable engine log messages.
- `mod.rs`: Core engine runtime: configuration, error handling, shared state, and resource management.
- `resource_keys.rs`: Typed resource keys for generational ID-based resource pools.
- `shared_state.rs`: Central shared runtime state for the Lurek2D engine.

## Types

- `Config` (`struct`, `config.rs`): Top-level engine configuration.
- `RenderConfig` (`struct`, `config.rs`): GPU backend and power-preference settings resolved once at engine startup.
- `WindowConfig` (`struct`, `config.rs`): Window dimensions, title, vsync, fullscreen, and resize settings.
- `ModulesConfig` (`struct`, `config.rs`): Flags to enable or disable optional engine subsystems.
- `PerformanceConfig` (`struct`, `config.rs`): Frame rate cap and other performance tuning options.
- `ErrorCategory` (`enum`, `error.rs`): Error category for grouping related engine errors.
- `EngineError` (`enum`, `error.rs`): All possible error conditions that can occur in the Lurek2D engine.
- `EngineResult` (`type`, `error.rs`): Convenience alias for `Result<T, EngineError>` used throughout the engine.
- `ErrorSnapshot` (`struct`, `error.rs`): A serialisable snapshot of an engine error.
- `MessageCatalog` (`struct`, `messages.rs`): Immutable map from stable message ID (e.g.
- `TextureKey` (`struct`, `resource_keys.rs`): Key for texture resources stored in SharedState.
- `FontKey` (`struct`, `resource_keys.rs`): Key for font resources stored in SharedState.
- `CanvasKey` (`struct`, `resource_keys.rs`): Key for canvas off-screen render targets.
- `SoundKey` (`struct`, `resource_keys.rs`): Key for audio source entries in the Mixer.
- `ParticleKey` (`struct`, `resource_keys.rs`): Key for particle system instances.
- `SpriteBatchKey` (`struct`, `resource_keys.rs`): Key for sprite batch instances.
- `ShaderKey` (`struct`, `resource_keys.rs`): Key for custom shader instances.
- `MeshKey` (`struct`, `resource_keys.rs`): Key for mesh instances.
- `ShapeKey` (`struct`, `resource_keys.rs`): Key for compound shape instances.
- `BusKey` (`struct`, `resource_keys.rs`): Key for audio bus instances in the Mixer.
- `MidiPlayerKey` (`struct`, `resource_keys.rs`): Key for MIDI player instances.
- `QueueableKey` (`struct`, `resource_keys.rs`): Key for queueable audio source instances in the Mixer.
- `LightKey` (`struct`, `resource_keys.rs`): Key for light source instances in LightWorld.
- `OccluderKey` (`struct`, `resource_keys.rs`): Key for shadow occluder instances in LightWorld.
- `FullscreenType` (`enum`, `shared_state.rs`): Fullscreen mode type for window management.
- `WindowState` (`struct`, `shared_state.rs`): Tracks window state and queues window operations for the event loop.
- `ErrorInfo` (`struct`, `shared_state.rs`): Structured error information for the last engine error.
- `ScreenshotRequest` (`struct`, `shared_state.rs`): Pending request to save the next rendered screen frame as a PNG.
- `SharedState` (`struct`, `shared_state.rs`): Shared mutable state passed via `Rc<RefCell<SharedState>>` to all Lua API closures and the engine loop.
- `RendererStats` (`struct`, `shared_state.rs`): Snapshot of renderer statistics for a single frame.

## Functions

- `ModulesConfig::validate_and_fix` (`config.rs`): Enforces dependency constraints so that a partially-disabled config is never internally inconsistent.
- `Config::load` (`config.rs`): Loads engine configuration from the game directory.
- `Config::load_from_conf_toml` (`config.rs`): Loads engine configuration from `conf.toml` in the game directory.
- `ErrorCategory::as_str` (`error.rs`): Returns the category name as a lowercase string.
- `EngineError::code` (`error.rs`): Returns the stable error code for this variant.
- `EngineError::category` (`error.rs`): Returns the error category for this variant.
- `EngineError::recovery_hint` (`error.rs`): Returns a human-readable recovery hint for this error variant.
- `ErrorSnapshot::to_json` (`error.rs`): Serialises the snapshot to a compact JSON string.
- `EngineError::snapshot` (`error.rs`): Creates an [`ErrorSnapshot`] capturing all diagnostic fields of this error.
- `set_log_level` (`log_messages.rs`): Sets the global log level at runtime (called from `lurek.runtime.setLogLevel`).
- `get_log_level` (`log_messages.rs`): Returns the current log level name.
- `MessageCatalog::from_toml` (`messages.rs`): Parse the embedded TOML source and build a flat ID → text map.
- `MessageCatalog::get` (`messages.rs`): Look up the human-readable text for a message ID.
- `MessageCatalog::len` (`messages.rs`): Number of registered message entries.
- `MessageCatalog::is_empty` (`messages.rs`): Returns `true` if the catalog contains no entries.
- `init` (`messages.rs`): Initialise the global message catalog from the embedded TOML.
- `get_message` (`messages.rs`): Resolve a stable message ID to its human-readable text.
- `resolve_message` (`messages.rs`): Resolve an arbitrary message ID to its human-readable text.
- `has_message` (`messages.rs`): Returns `true` if the global message catalog contains the given ID.
- `message_count` (`messages.rs`): Number of entries currently registered in the global message catalog.
- `catalog` (`messages.rs`): Returns a reference to the global [`MessageCatalog`], or `None` if [`init`] has not been called yet.
- `SharedState::new` (`shared_state.rs`): Creates a new `SharedState` with the given window dimensions, title, and game directory.
- `SharedState::step_timer` (`shared_state.rs`): Advances the clock by one tick and syncs `delta_time`, `total_time`, and `fps`.
- `SharedState::touch_texture` (`shared_state.rs`): Records that a texture was used on the current frame.
- `SharedState::evict_lru_resources` (`shared_state.rs`): Evicts least-recently-used textures until resident size is within budget.
- `SharedState::resource_memory_stats` (`shared_state.rs`): Returns a summary of resident resource memory usage.
- `SharedState::request_async_load` (`shared_state.rs`): Submits a background file-read request, lazily creating the async loader.
- `SharedState::load_default_fonts` (`shared_state.rs`): Loads all 6 embedded bitmap fonts into `fonts` and stores their keys in `default_fonts`.
- `SharedState::poll_async_load` (`shared_state.rs`): Polls a pending async load and returns the status and optional data.
- `SharedState::compute_stats` (`shared_state.rs`): Computes a snapshot of the current renderer statistics.

## Lua API Reference

- Namespace: `lurek.runtime.setLogLevel`

## References

- `audio`: Imports or references `audio` from `src/audio/`.
- `camera`: Imports or references `camera` from `src/camera/`.
- `event`: Imports or references `event` from `src/event/`.
- `filesystem`: Imports or references `filesystem` from `src/filesystem/`.
- `input`: Imports or references `input` from `src/input/`.
- `light`: Imports or references `light` from `src/light/`.
- `parallax`: Imports or references `parallax` from `src/parallax/`.
- `particle`: Imports or references `particle` from `src/particle/`.
- `raycaster`: Imports or references `raycaster` from `src/raycaster/`.
- `render`: Imports or references `render` from `src/render/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.
- `tilemap`: Imports or references `tilemap` from `src/tilemap/`.
- `timer`: Imports or references `timer` from `src/timer/`.
- `ui`: Imports or references `ui` from `src/ui/`.

## Notes

- Keep this module reference synchronized with `src/runtime/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
- **conf.toml only (updated 2026-04-21)**: `conf.lua` support has been removed. `Config::load` tries `conf.toml` and returns `Config::default()` if absent. `load_from_conf_lua`, `build_config_table`, and `read_config_table` have been deleted. Configuration is TOML-only.
