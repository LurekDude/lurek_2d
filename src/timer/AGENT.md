# timer

## Module Info
- Module name: `timer`
- Module group: `Core Runtime`
- Spec path: `docs/specs/timer.md`
- Lua API path(s): `src/lua_api/timer_api.rs`
- Rust test path(s): `tests/rust/unit/timer_tests.rs`, `tests/fixtures/timer_api_fixture.rs`, plus inline unit coverage in `src/timer/scheduler.rs`
- Lua test path(s): `tests/lua/unit/test_timer.lua`, `tests/lua/stress/test_timer_stress.lua`, `tests/lua/integration/test_timer_math.lua`, `tests/lua/integration/test_physics_timer.lua`, `tests/lua/integration/test_particle_timer.lua`, `tests/lua/integration/test_audio_timer.lua`, `tests/lua/integration/test_animation_timer.lua`

## Module Purpose

The timer module owns Lurek2D's generic notion of time. It provides the frame clock used to derive delta time, total uptime, rolling FPS, and average frame duration, and it provides a standalone scheduler for delayed or repeating callbacks that can run at a caller-controlled time scale.

This module exists so time measurement and timer-driven behavior are consistent across the engine. `SharedState` keeps a `Clock` as the canonical per-frame timing source, while Lua scripts can create independent `Scheduler` instances for gameplay timing without having to implement their own event bookkeeping, repeat counts, pause state, or named timer replacement.

It intentionally does not own interpolation systems, animation state machines, or the engine's overall fixed-step orchestration. Tweening belongs in `tween`, animation playback belongs in `animation`, and the app loop decides when frame and physics callbacks run. The Lua wrapper in `src/lua_api/timer_api.rs` owns callback registry management; the core timer module only manages timing data and event IDs.

## Files
- `mod.rs` is the public entry point for the module. It re-exports `Clock` and `Scheduler` and exposes the small `sleep(seconds)` helper.
- `clock.rs` implements the wall-clock timer used for frame delta, total elapsed time, FPS, frame count, and rolling average delta. This is the file to change when the engine's canonical time measurements need to change.
- `scheduler.rs` implements delayed and repeating timed events with IDs, optional names, pause state, repeat counts, interval resets, and a global time-scale multiplier. This is the module's gameplay-facing timing primitive.

## Key Types
- `Clock` is the engine's canonical frame timer. It tracks delta time, total elapsed time, frame count, rolling FPS, and a short rolling average so HUDs and diagnostics can report stable timing data.
- `Scheduler` is a standalone timed-event manager for delayed and repeating work. It is intentionally generic: it knows about seconds, intervals, IDs, names, and pause state, but not about Lua callbacks or engine subsystems.
- `ScheduledEvent` is the per-timer record inside `Scheduler`. It captures ID, optional name, remaining time, interval, repeat count, one-shot status, and pause state.
- `LuaScheduler` in `src/lua_api/timer_api.rs` is the important bridge object for this module's public scripting surface. It wraps a `Scheduler` plus Lua registry keys so due events can invoke Lua callbacks and clean them up safely.
- `sleep(seconds)` is a very small helper, but it is an important boundary marker: blocking waits live here only as an explicit utility, not as part of frame scheduling logic.