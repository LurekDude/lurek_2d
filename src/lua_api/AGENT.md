# `lua_api` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Bridge Layer — above all module tiers |
| **Status** | Implemented — Full |
| **Lua API** | All `lurek.*` namespaces |
| **Source** | `src/lua_api/` |
| **Rust Tests** | `—` (tested via Lua BDD tests) |
| **Lua Tests** | `tests/lua/` (all Lua BDD tests exercise lua_api) |

## Purpose

The `lua_api` module is the bridge between the Rust engine and Lua game scripts.
It creates and configures the Lua VM, registers all `lurek.*` API tables, and
provides `UserData` wrappers that connect Lua values to typed resource keys in
`SharedState`. Every public Lua-facing capability lives here as a thin
translation layer — business logic stays in the domain modules below.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | VM creation, StdLib selection, global nulling, module registration |
| `userdata.rs` | `LunaType` trait, shared UserData patterns |
| `graphics_api/` | `lurek.gfx.*` — drawing, images, fonts, canvases, shaders |
| `audio_api.rs` | `lurek.audio.*` — sources, playback, volume, buses |
| `input_api.rs` | `lurek.input.*`, `lurek.keyboard.*`, `lurek.mouse.*`, `lurek.gamepad.*`, `lurek.touch.*` |
| `timer_api.rs` | `lurek.time.*` — delta time, FPS, sleep (Gold standard for docstring format) |
| `math_api.rs` | `lurek.math.*` — trig, random, noise, transforms, Bezier |
| `physics_api.rs` | `lurek.physics.*` — worlds, bodies, joints, raycasting |
| `filesystem_api.rs` | `lurek.fs.*` — sandboxed I/O, file handles, archives |
| `window_api.rs` | `lurek.window.*` — fullscreen, VSync, display info, clipboard |
| `event_api.rs` | `lurek.signal.*` — event queue, quit |
| `system_api.rs` | `lurek.platform.*` — OS info, openURL, locales |
| `particle_api.rs` | `lurek.particles.*` — emitters, config, rendering |
| `data_api.rs` | `lurek.data.*` — binary data, compression, hashing, encoding |
| `image_api.rs` | `lurek.img.*` — CPU pixel buffers, pixel manipulation |
| `sound_api.rs` | `lurek.sound.*` — decoded PCM audio samples |
| `thread_api/` | `lurek.thread.*` — worker threads, channels |
| `terminal_api.rs` | `lurek.terminal.*` — in-game developer terminal |

## Key Types

| Type | Description |
|------|-------------|
| `LuaAnimation` | Principal type for the `lua_api` module. |
| `LuaSource` | Principal type for the `lua_api` module. |
| `LuaBus` | Principal type for the `lua_api` module. |
| `LuaMidiPlayer` | Principal type for the `lua_api` module. |
| `LuaDecoder` | Principal type for the `lua_api` module. |
| `LuaCamera2D` | Principal type for the `lua_api` module. |
| `LuaArray` | Principal type for the `lua_api` module. |
| `LuaDataFrame` | Principal type for the `lua_api` module. |
| `LuaDatabase` | Principal type for the `lua_api` module. |
| `LuaUniverse` | Principal type for the `lua_api` module. |
| `LuaSignal` | Principal type for the `lua_api` module. |
| `LuaFileData` | Principal type for the `lua_api` module. |

## Lua API Summary

_No `lurek.*` bindings registered for this module._

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/lua_api.md`](../../docs/specs/lua_api.md)

_Update both this file **and** `docs/specs/lua_api.md` whenever source files, public types, or Lua bindings change._
