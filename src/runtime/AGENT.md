# runtime

## Module Info
- Module name: `runtime`
- Module group: `Core Runtime`
- Spec path: `docs/specs/runtime.md`
- Lua API path(s): none; this module is consumed indirectly through shared state and resource handles
- Rust test path(s): `tests/rust/unit/window_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs`, plus runtime-focused unit coverage embedded in `src/runtime/messages.rs`
- Lua test path(s): `tests/lua/config/test_config.lua`, `tests/lua/harness.rs`

## Module Purpose

The runtime module is the engine's shared substrate. It defines startup configuration, the canonical engine error type, stable log message IDs, the embedded human-readable message catalog, and the central `SharedState` object that all Lua bindings and the main loop mutate through `Rc<RefCell<_>>`.

This module exists so the rest of Lurek2D can agree on a single source of truth for engine-wide state and identifiers. Rendering, input, audio, events, timers, filesystem access, and many higher-level systems all meet here through typed resource pools, per-frame timing fields, the event queue, and pending runtime actions such as restart, quit, async loads, and screenshots.

It intentionally does not own subsystem behavior. Rendering logic lives in `render`, audio mixing in `audio`, input device state machines in `input`, sandboxed path policy in `filesystem`, and Lua-facing registration in `src/lua_api/`. If a change is about how a subsystem behaves rather than how global state is stored or shared, that change usually belongs outside `runtime`.

## Files
- `mod.rs` re-exports the runtime surface used across the engine. It is the narrow import point for config, errors, message lookup, shared state, and typed resource keys.
- `config.rs` defines `Config` and its nested configuration structs, default values, and module-enable flags. It is the boot-time contract between `conf.toml` or legacy `conf.lua` and the engine bootstrap path.
- `error.rs` defines `EngineError`, `ErrorCategory`, and `EngineResult`. Use it when an engine-level failure needs a stable category, code, and recovery hint rather than ad hoc strings.
- `log_messages.rs` centralizes stable log IDs and the `log_msg!` macro. This lets tooling key off IDs even when the human-readable text changes.
- `messages.rs` loads and caches the embedded TOML message catalog. It is the bridge between stable IDs and readable log text.
- `resource_keys.rs` declares the typed `SlotMap` keys used across the engine's resource pools. The point is compile-time separation between textures, fonts, canvases, shaders, lights, and other handle families.
- `shared_state.rs` defines `SharedState` and runtime-adjacent types such as `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest`, and `RendererStats`. It is the highest-value file in the module because it is the shared contract most other modules read or mutate.

## Key Types
- `Config` is the top-level engine configuration object loaded at startup. It groups window, graphics, module-toggle, performance, identity, and logging settings into one boot contract.
- `WindowConfig` describes initial window shape and presentation policy. It owns startup dimensions, title, fullscreen mode, scaling mode, logical game resolution, and icon path.
- `GraphicsConfig` holds backend and power-preference hints for renderer startup. It does not perform GPU setup itself.
- `ModulesConfig` is the runtime feature gate table for optional subsystems. It also repairs invalid combinations such as graphics-dependent systems being enabled while graphics is disabled.
- `PerformanceConfig` carries frame pacing inputs such as target FPS and fixed physics tick rate. It is configuration data, not the active clock.
- `EngineError` is the engine-wide error enum used to classify failures before they cross into Lua or UI layers. It is where stable error codes and recovery hints live.
- `ErrorCategory` groups engine errors into broad operational buckets. Use it when reporting or aggregating failures rather than branching on raw message text.
- `MessageCatalog` is the cached ID-to-text lookup table for stable logging. It keeps the codebase from hardcoding long user-facing log strings everywhere.
- `SharedState` is the central mutable hub shared between the engine loop and Lua bindings. It stores render commands, resource pools, timing state, input state, pending control actions, filesystem access, and cross-system objects such as the event queue and clock.
- `WindowState` holds both observed window state and queued window operations. It is the handshake object between Lua requests and the event loop's actual OS-facing window changes.
- `FullscreenType` distinguishes desktop fullscreen from exclusive fullscreen. It is small, but important because window behavior changes depend on it.
- `ErrorInfo` stores the structured version of the last engine error for overlays and diagnostics. It keeps presentation concerns separate from the raw `EngineError`.
- `ScreenshotRequest` represents a deferred save of the next completed frame. It exists so Lua can request a screenshot without the API layer doing GPU work directly.
- `RendererStats` is a cheap snapshot of counts and estimated texture memory. It is for observation and overlays, not for driving renderer decisions.
- `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `SpriteBatchKey`, `ShaderKey`, `MeshKey`, `ShapeKey`, `BusKey`, `MidiPlayerKey`, `QueueableKey`, `LightKey`, and `OccluderKey` are the typed resource-handle family. Their main value is preventing one resource pool from being indexed with the wrong key type.