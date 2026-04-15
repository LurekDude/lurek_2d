# IDEA.md — `app` module

> Migrated from `ideas/features/engine.md`.
> Status checked against `src/app/` (includes `app.rs`, `shared_state.rs`, boot sequence).
> Lua namespace: N/A — `app` is the engine lifecycle entry point; no direct Lua exposure.

---

## Features

### ✅ DONE — Winit Event Loop + Boot Sequence
**Source**: features/engine.md — Summary

`App::new()` → winit + wgpu + rodio + GameFS setup → `create_lua_vm()` →
`main.lua` → `lurek.init()` / `lurek.ready()` → event loop.

---

### ✅ DONE — Debug Overlay (FPS, Draw Calls, Memory)
**Source**: features/engine.md — Summary

`F3` key toggles debug overlay. Displays per-frame diagnostics.

---

### ✅ DONE — Error Screen (Lua Error Render)
**Source**: features/engine.md — Summary

Lua errors render a human-readable error screen with file/line context.

---

### ✅ DONE — Splash Screen (No-Game Mode)
**Source**: Engine branding feature

No-game splash implemented in `app.rs` via `make_splash_commands()`.
Embeds `assets/svg/large_icon.png` and `assets/svg/banner.png`.

---

### ✅ DONE — Typed Resource Pools (SlotMap)
**Source**: features/engine.md — Summary

`SharedState` contains `SlotMap<TypedKey, Resource>` for all resource types:
TextureKey, FontKey, ShaderKey, MeshKey, CanvasKey, SpriteBatchKey, ParticleKey
(defined in `src/runtime/resource_keys.rs`).

---

### ❌ TODO — Hot Reload (Lua + Assets) — HIGH PRIORITY
**Source**: features/engine.md — Feature Gaps #1 / Suggestions #1

No mechanism to reload Lua scripts or assets at runtime without restarting.
This is the #1 missing feature for development workflow — every competitor engine
supports some form of live reload.

Implementation path:
1. File watcher (`notify` crate) watching `main.lua` + all `require()`'d files
2. On change: re-run `main.lua` in existing Lua VM (or rebuild VM)
3. Re-invoke `lurek.init()` callback, keep window/GPU state

---

### ❌ TODO — `.luna` Single-File Distribution Format — HIGH PRIORITY
**Source**: features/engine.md — Feature Gaps #4 / Suggestions #3

Games are loose folders. Engine A has `.love` (renamed ZIP). A `.luna` format:
1. ZIP renamed to `.luna` with `main.lua` at root
2. Engine detects extension and mounts as `GameFS` root
3. Distribution = "zip your game, rename to `.luna`"

---

### ✅ DONE — Fixed Timestep Mode (`lurek.fixedUpdate`)
**Source**: features/engine.md — Feature Gaps #2 / Suggestions #2

`PerformanceConfig.fixed_update_tick_rate: Option<u32>` added to `src/runtime/config.rs`.
`SharedState.fixed_update_dt: f64` added to `src/runtime/shared_state.rs`.
`LunaApp.fixed_update_accumulator: f64` added to `src/app/app.rs` with step-and-drip
accumulator loop (max 8 steps per frame) calling the optional `fixedUpdate(dt)` Lua callback.

```toml
[performance]
fixed_update_tick_rate = 60  # enables fixedUpdate at 60 Hz
```

```lua
lurek.fixedUpdate = function(dt)
    -- deterministic physics / AI update at 60 Hz
end
```

Implemented: 2026-04-15

---

### ✅ DONE — Frame Budget Warning
**Source**: features/engine.md — Feature Gaps #5 / Suggestions #5

`PerformanceConfig.frame_budget_warn_ms: Option<f32>` added to `src/runtime/config.rs`.
At the end of `game_update()` in `src/app/app.rs`, elapsed time is compared against the
threshold and `log::warn!` is emitted when exceeded.

```toml
[performance]
frame_budget_warn_ms = 16.7
```

Logs: `WARN  lurek2d > frame budget exceeded: 21.3ms > 16.7ms threshold`

Implemented: 2026-04-15

---

### ❌ TODO — Plugin / Extension Registry
**Source**: features/engine.md — Feature Gaps #3

No way to register new `lurek.*` namespaces without modifying `src/lua_api/mod.rs`.
Requires a trait-based plugin registry.

---

### 🤔 CONSIDER — Extract Splash Screen to Dedicated Module
**Source**: features/engine.md — Structural Issues

`app.rs` handles: boot + event loop + splash screen + debug overlay.
Splash screen logic (embeds large PNGs, draw commands) bloats `app.rs` significantly.
A `src/splash/` module would isolate branding code from lifecycle logic.

---

### 🤔 CONSIDER — Config Fallback on conf.lua Syntax Error
**Source**: features/engine.md — Structural Issues

`Config` loaded via temporary Lua VM. `conf.lua` syntax errors crash before the
error screen exists. A default fallback config would ensure the error screen
at least displays before crashing.
