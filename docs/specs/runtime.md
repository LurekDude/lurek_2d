# `runtime` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Baseline — always-on runtime substrate                       |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | — (foundation module; no `lurek.runtime` namespace)          |
| **Source**     | `src/runtime/`                                               |
| **Rust Tests** | `tests/rust/unit/engine_tests.rs`                            |
| **Lua Tests**  | —                                                            |
| **Architecture** | `docs/architecture/engine-architecture.md`                 |

## Summary

`src/runtime/` is the foundational substrate of Lurek2D — it owns configuration loading,
the central shared mutable state, the structured error taxonomy, stable log-message IDs,
the human-readable message catalog, and the typed `SlotMap` resource keys that identify
every GPU and audio object in the engine. It sits at the Baseline tier alongside `src/math/`,
meaning every other module in the system may import from it; the runtime module itself has
no incoming engine-module dependencies.

`Config` is loaded once at startup from `conf.toml` (preferred) or the legacy `conf.lua`.
Missing fields fall back to built-in defaults, so game authors only need to specify settings
they want to change. `SharedState` is created immediately after config loading, wrapped in
`Rc<RefCell<SharedState>>`, and cloned into every Lua API closure and into the engine event
loop. It is the single mutable hub that connects all subsystems: resource pools, render
command queue, input state, audio mixer references, camera, and event queue.

Resource pools use Rust's `slotmap` crate with 14 purpose-typed key newtypes. Typed keys
prevent accidental cross-pool lookups at compile time — a `TextureKey` cannot be used to
look up a `Font`, and the compiler enforces this without runtime overhead. All resource
lifetimes are managed by the engine; Lua receives lightweight UserData wrapping a key copy,
so no `__gc` finalizer is needed.

`EngineError` defines 12 variants with stable short codes (`E001`–`E012`) so that log
messages written by one engine version remain parseable by tooling targeting an older
version. At the Lua API boundary every `EngineError` is converted to `LuaError` via
`.map_err(LuaError::external)`. The `log_messages` submodule provides stable named
constants (`L001`–`L082`, `A001`–`A004`) used by `log_msg!` so that log message text
can be updated without breaking log-grep scripts.

## Architecture

```
conf.toml / conf.lua
        │
        ▼
  Config::load()           (src/runtime/config.rs)
        │
        ▼
  SharedState::new()       (src/runtime/shared_state.rs)
        │  Rc<RefCell<SharedState>>
        ├── render_commands: Vec<RenderCommand>
        ├── textures:        SlotMap<TextureKey, Texture>
        ├── fonts:           SlotMap<FontKey, Font>
        ├── canvases:        SlotMap<CanvasKey, Canvas>
        ├── sprite_batches:  SlotMap<SpriteBatchKey, SpriteBatch>
        ├── meshes:          SlotMap<MeshKey, Mesh>
        ├── shaders:         SlotMap<ShaderKey, Shader>
        ├── shapes:          SlotMap<ShapeKey, CompoundShape>
        ├── particles:       SlotMap<ParticleKey, ParticleSystem>
        ├── audio_sources:   SlotMap<SoundKey / BusKey / ...>
        ├── input_state      (keyboard, mouse, gamepad)
        ├── camera
        ├── event_queue
        └── window_state

  EngineError              (src/runtime/error.rs)
        │  E001–E012 stable codes
        └── .map_err(LuaError::external) at every Lua API boundary

  MessageCatalog           (src/runtime/messages.rs)
        │  TOML-backed log message strings embedded at compile time
        └── cfg/messages.toml (include_str!)

  Resource key newtypes    (src/runtime/resource_keys.rs)
        │  14 typed SlotMap keys — compiler-enforced cross-pool safety
        └── TextureKey, FontKey, CanvasKey, SoundKey, ParticleKey,
            SpriteBatchKey, ShaderKey, MeshKey, ShapeKey, BusKey,
            MidiPlayerKey, QueueableKey, LightKey, OccluderKey
```

## Source Files

| File                | Purpose                                                                                 |
|---------------------|-----------------------------------------------------------------------------------------|
| `mod.rs`            | Re-exports `Config`, `SharedState`, `EngineError`, all resource key types, and the `create_lua_vm` entry point. |
| `config.rs`         | `Config`, `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig` — loaded from `conf.toml` or `conf.lua` via a temporary Lua VM. |
| `error.rs`          | `EngineError` (12 variants with stable codes `E001`–`E012`), `ErrorCategory`, `EngineResult<T>`. |
| `log_messages.rs`   | Stable message ID constants (`L001`–`L082`, `A001`–`A004`), `set_log_level` / `get_log_level`, `log_msg!` macro. |
| `messages.rs`       | `MessageCatalog` — TOML-backed message lookup via `init()`, `get_message()`, and `catalog()`. |
| `resource_keys.rs`  | 14 typed `SlotMap` key newtypes for every resource category. |
| `shared_state.rs`   | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest`. |
| `cfg/messages.toml` | TOML text strings for all stable log messages, embedded at compile time via `include_str!`. |

## Submodules

### `config` — Engine Configuration
- `Config` — Top-level config container loaded from `conf.toml` or `conf.lua`.
- `WindowConfig` — Window dimensions, title, vsync, fullscreen, resize policy.
- `GraphicsConfig` — GPU backend (`"auto"`, `"dx12"`, `"vulkan"`, `"metal"`) and power preference.
- `ModulesConfig` — Boolean feature-flags for optional subsystem registration.
- `PerformanceConfig` — `fps_cap` (max frames per second).

### `error` — Typed Error Taxonomy
- `EngineError` — 12-variant error enum with stable codes `E001`–`E012`.
- `ErrorCategory` — Groups errors by origin: `Io`, `Script`, `Gpu`, `Asset`, `Config`, `Logic`.
- `EngineResult<T>` — `type EngineResult<T> = Result<T, EngineError>`.

### `log_messages` — Stable Log IDs
- Stable named constants `L001`–`L082` and `A001`–`A004` for all engine log messages.
- `set_log_level(level)` / `get_log_level()` — Runtime log-level control.
- `log_msg!` macro — Emit a stable-ID log message via the `log` crate.

### `messages` — Human-Readable Message Catalog
- `MessageCatalog` — TOML-backed message lookup; text updated without recompile via `cfg/messages.toml`.

### `resource_keys` — Typed SlotMap Keys
- 14 typed key newtypes: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `SpriteBatchKey`, `ShaderKey`, `MeshKey`, `ShapeKey`, `BusKey`, `MidiPlayerKey`, `QueueableKey`, `LightKey`, `OccluderKey`.
- Keys are compiler-checked: a `TextureKey` cannot look up a `Font`.

### `shared_state` — Central Mutable Hub
- `SharedState` — `Rc<RefCell<…>>` hub shared between the engine loop and all Lua closures; holds all resource pools, render command queue, input state, camera, and event queue.
- `WindowState` — Runtime window geometry and focus flags updated each frame.
- `FullscreenType` — `Borderless` or `Exclusive` fullscreen modes.
- `ErrorInfo` — Structured error data for display in the error overlay.
- `ScreenshotRequest` — One-shot screenshot capture request with output path.

## Key Types

| Type                | Description                                                                          |
|---------------------|--------------------------------------------------------------------------------------|
| `Config`            | Top-level engine configuration container; holds `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, and `PerformanceConfig`. Loaded from `conf.toml` (or `conf.lua`) at startup with sensible defaults for all omitted fields. |
| `WindowConfig`      | Window dimensions, title, vsync flag, fullscreen mode, and resize policy.            |
| `GraphicsConfig`    | GPU backend selection (`"auto"`, `"dx12"`, `"vulkan"`, `"metal"`) and power preference resolved at device creation. |
| `ModulesConfig`     | Boolean feature-flags controlling which optional subsystems are initialised and which `lurek.*` namespaces are registered (audio, physics, graphics, etc.). |
| `PerformanceConfig` | Frame-rate cap (`fps_cap`) — the maximum frames per second the engine will render.   |
| `SharedState`       | Central mutable hub shared between the engine loop and all Lua closures via `Rc<RefCell<SharedState>>`; holds resource pools, render command queue, input state, camera, event queue, and audio mixer reference. |
| `WindowState`       | Runtime window geometry and focus/visibility flags updated each frame by the OS event handler. |
| `EngineError`       | 12-variant typed error enum with stable codes `E001`–`E012`; converts to `LuaError` at every Lua API boundary. |
| `EngineResult<T>`   | `type EngineResult<T> = Result<T, EngineError>` — the standard return type for all fallible engine operations. |
| `MessageCatalog`    | TOML-backed string table for all human-readable log message bodies; keeps source code free of long literal strings. |
| `TextureKey`        | Opaque `SlotMap` key identifying a loaded GPU texture in `SharedState::textures`.    |
| `FontKey`           | Opaque `SlotMap` key identifying a loaded `Font` (fontdue atlas) in `SharedState::fonts`. |
| `CanvasKey`         | Opaque `SlotMap` key identifying an off-screen `Canvas` render target.               |
| `SoundKey`          | Opaque `SlotMap` key identifying an audio source registered with the Mixer.          |
| `ParticleKey`       | Opaque `SlotMap` key identifying a `ParticleSystem` instance.                        |
| `SpriteBatchKey`    | Opaque `SlotMap` key identifying a `SpriteBatch` in `SharedState::sprite_batches`.   |
| `ShaderKey`         | Opaque `SlotMap` key identifying a custom WGSL `Shader` and its compiled pipeline.   |
| `MeshKey`           | Opaque `SlotMap` key identifying a custom-geometry `Mesh`.                           |
| `ShapeKey`          | Opaque `SlotMap` key identifying a `CompoundShape` command buffer.                   |
| `BusKey`            | Opaque `SlotMap` key identifying an audio bus in the Mixer.                          |
| `MidiPlayerKey`     | Opaque `SlotMap` key identifying an active MIDI player instance.                     |
| `QueueableKey`      | Opaque `SlotMap` key for audio sources registered in the Mixer's queue.              |
| `LightKey`          | Opaque `SlotMap` key identifying a `Light` entry in `LightWorld`.                    |
| `OccluderKey`       | Opaque `SlotMap` key identifying an occlusion polygon in `LightWorld`.               |

## Lua API

`src/runtime/` exposes **no public `lurek.*` functions** directly. It is the internal substrate consumed by every other module through `SharedState`. Lua scripts interact with runtime state indirectly via resource handles (e.g. `LuaImage`, `LuaFont`) returned by other API namespaces.

| Namespace | Status |
|---|---|
| `lurek.runtime` | Not registered — `src/runtime/` has no Lua API surface. |

## Lua Examples

_`runtime` has no `lurek.*` Lua API. Scripts interact with its types indirectly through resource handles returned by other modules._

```lua
-- Config is read at startup from conf.toml.
-- Scripts cannot access Config at runtime — it is consumed during engine init.

-- Typed resource handles are returned by API functions and used opaquely:
local img = lurek.graphic.newImage("assets/player.png")
-- 'img' wraps a TextureKey internally; the script never sees the key value.

-- Window state can be queried via lurek.window:
local w, h = lurek.window.getSize()
print(string.format("window: %d × %d", w, h))
```

## Item Summary

| Kind              | Count |
|-------------------|-------|
| Structs           | 12    |
| Enums             | 7     |
| Resource key types | 14   |
| Free functions    | 5     |
| **Total**         | **38** |

## References

| Module       | Relationship                                                                         |
|--------------|--------------------------------------------------------------------------------------|
| `app`        | `src/app/` reads `Config` at startup and wraps `SharedState` in the winit event loop. |
| `render`     | `SharedState::render_commands` is the deferred `RenderCommand` queue processed by `GpuRenderer`. All GPU resource pools (`textures`, `fonts`, `canvases`, …) are `SlotMap` fields on `SharedState`. |
| `audio`      | `SharedState` holds a reference to the rodio `Mixer`; `SoundKey` and `BusKey` address audio resources. |
| `lua_api`    | Every `src/lua_api/<module>_api.rs` registration function receives a cloned `Rc<RefCell<SharedState>>`; `EngineError` converts to `LuaError` at each boundary. |
| `math`       | `Baseline` — `src/math/` is the only other Baseline module; both are safe to import from every tier. |
## Notes

- **Baseline module**: `runtime` may be imported by every other module in the engine. It has no internal Lurek2D module dependencies (other than `src/math/` for `Color` and `Vec2`).
- **`Rc<RefCell<SharedState>>`**: All Lua API closures clone this `Rc` on registration. Borrowing must be kept to the shortest possible scope; never hold a `RefMut` across a Lua boundary.
- **Stable error codes**: `E001`–`E012` are guaranteed not to change between minor versions. Log-grep scripts may rely on them. Message text (in `messages.toml`) may change without incrementing the code.
- **14 resource key types**: Each is a distinct newtype around `slotmap::DefaultKey`. They are not serializable; do not save keys across sessions.
- **`conf.lua` legacy**: The `conf.lua` bootstrap loader uses a temporary Lua VM to parse game config before the main VM is created. The preferred format going forward is `conf.toml`.
- **Breaking change surface**: Adding a field to `Config` or `SharedState` is backward-compatible with defaults. Removing or renaming a field is a breaking change for all conf files.
