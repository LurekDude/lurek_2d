# engine — Feature Analysis

**Tier**: Baseline
**Spec**: `specs/engine.md`
**Files**: Core infrastructure — App, Config, SharedState, EngineError, ResourceKeys, DebugOverlay, ErrorScreen

## Purpose

Engine backbone: application lifecycle, configuration, shared state container, typed resource pools (SlotMap), and error handling. Everything depends on this module.

## Current Feature Summary

- `App` struct: winit event loop, boot sequence, frame scheduling
- `Config` loaded from `conf.lua` via temporary Lua VM
- `SharedState` with typed `SlotMap` pools for all resource types (TextureKey, FontKey, ShaderKey, MeshKey, CanvasKey, SpriteBatchKey, ParticleKey)
- `EngineError` central error type with module-scoped variants
- Debug overlay (FPS, draw calls, memory)
- Error screen (pretty-prints Lua errors with context)
- Resource key types in `resource_keys.rs`

## Feature Gaps

1. **No hot reload**: No mechanism to reload Lua scripts or assets at runtime without restarting. This is the #1 missing feature cited across competitor engines (Love2D, Bevy, Solar2D all support some form of live reload).
2. **No fixed timestep accumulator**: The original Luna2D C++ engine had delta time smoothing. The Rust engine exposes `timer.deltaTime()` but doesn't provide a built-in fixed-step accumulator for physics or simulation consistency.
3. **No plugin/extension API**: No way for Rust-side plugins to register new `luna.*` namespaces without modifying `lua_api/mod.rs`. A trait-based plugin registry would allow optional modules.
4. **No .luna distribution format**: Love2D has `.love` (renamed ZIP). Luna2D games are loose folders. A single-file distribution format would simplify sharing.
5. **No frame budget / time quota**: No mechanism to cap frame time or warn when update/draw exceeds budget.
6. **No graceful degradation**: No built-in FPS scaling or quality adjustment when frame rate drops.
7. **No explicit game state serialization**: `SharedState` can't be snapshotted for save/load or networked state sync.

## Structural Issues

- **App.rs is very large**: Boot sequence + event loop + splash screen + debug overlay all live here. Consider extracting splash screen into its own module.
- **Config is loaded via temporary Lua VM**: This is clever but means conf.lua syntax errors crash before the error screen exists. Consider a fallback default config.
- **DebugOverlay parity**: The debug overlay could be a Tier 2 module (`debug`) rather than baked into engine baseline.

## Suggestions

1. **Add hot reload support**: File watcher → reload Lua scripts → re-invoke `luna.load()`. This is transformative for development workflow. Many 2D engine users cite this as the #1 productivity feature.
2. **Add fixed timestep mode**: `conf.lua` option for fixed timestep (e.g., `t.fixedTimestep = 1/60`). Engine accumulates time and calls `luna.fixedUpdate(dt)` at fixed intervals, `luna.update(dt)` for rendering interpolation.
3. **Add .luna file format**: ZIP archive with `main.lua` at root + assets. Engine detects and mounts as GameFS root. Distribution story becomes: "zip your game folder, rename to .luna, double-click to play."
4. **Extract DebugOverlay to Tier 2**: Make it a proper module with config flags, extensible panels, and Lua-accessible debug drawing.
5. **Add frame budget warning**: `Config` option for target frame time; engine logs warning when exceeded. Helps developers catch performance regressions early.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Hot reload | ❌ | ✅ (manual) | ✅ (live) | ✅ (full) |
| Distribution format | ❌ | ✅ (.love) | ✅ (.app) | ❌ |
| Fixed timestep | ❌ | ❌ (manual) | ✅ (30/60) | ✅ (built-in) |
| Error screen | ✅ | ✅ | ❌ | ❌ |
| Debug overlay | ✅ | ❌ (manual) | ❌ | ✅ (inspector) |
| Plugin API | ❌ | ❌ | ✅ (native) | ✅ (Plugin trait) |

## Priority

**HIGH** — Hot reload and .luna distribution format are the two most impactful missing features across the entire engine. Fixed timestep is important for physics-heavy games.
