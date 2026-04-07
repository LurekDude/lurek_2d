# `lua_api` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Bridge Layer — above all module tiers |
| **Status** | Implemented — Full |
| **Lua API** | All `luna.*` namespaces |
| **Source** | `src/lua_api/` |
| **Rust Tests** | `—` (tested via Lua BDD tests) |
| **Lua Tests** | `tests/lua/` (all Lua BDD tests exercise lua_api) |

## Purpose

The `lua_api` module is the bridge between the Rust engine and Lua game scripts.
It creates and configures the Lua VM, registers all `luna.*` API tables, and
provides `UserData` wrappers that connect Lua values to typed resource keys in
`SharedState`. Every public Lua-facing capability lives here as a thin
translation layer — business logic stays in the domain modules below.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | VM creation, StdLib selection, global nulling, module registration |
| `userdata.rs` | `LunaType` trait, shared UserData patterns |
| `graphics_api/` | `luna.graphics.*` — drawing, images, fonts, canvases, shaders |
| `audio_api.rs` | `luna.audio.*` — sources, playback, volume, buses |
| `input_api.rs` | `luna.input.*`, `luna.keyboard.*`, `luna.mouse.*`, `luna.gamepad.*`, `luna.touch.*` |
| `timer_api.rs` | `luna.timer.*` — delta time, FPS, sleep (Gold standard for docstring format) |
| `math_api.rs` | `luna.math.*` — trig, random, noise, transforms, Bezier |
| `physics_api.rs` | `luna.physics.*` — worlds, bodies, joints, raycasting |
| `filesystem_api.rs` | `luna.filesystem.*` — sandboxed I/O, file handles, archives |
| `window_api.rs` | `luna.window.*` — fullscreen, VSync, display info, clipboard |
| `event_api.rs` | `luna.event.*` — event queue, quit |
| `system_api.rs` | `luna.system.*` — OS info, openURL, locales |
| `particle_api.rs` | `luna.particle.*` — emitters, config, rendering |
| `data_api.rs` | `luna.data.*` — binary data, compression, hashing, encoding |
| `image_api.rs` | `luna.image.*` — CPU pixel buffers, pixel manipulation |
| `sound_api.rs` | `luna.sound.*` — decoded PCM audio samples |
| `thread_api/` | `luna.thread.*` — worker threads, channels |
| `terminal_api.rs` | `luna.terminal.*` — in-game developer terminal |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/lua_api.md`](../../specs/lua_api.md)

_Update both this file **and** `specs/lua_api.md` whenever source files, public types, or Lua bindings change._
