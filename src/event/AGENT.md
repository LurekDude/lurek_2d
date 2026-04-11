# event

## Module Info
- Module name: `event`
- Module group: `Core Runtime`
- Spec path: `docs/specs/event.md`
- Lua API path(s): `src/lua_api/event_api.rs`
- Rust test path(s): `tests/rust/unit/event_tests.rs`, plus inline unit coverage in `src/event/event_queue.rs` and `src/event/signal.rs`
- Lua test path(s): `tests/lua/unit/test_event.lua`, `tests/lua/integration/test_audio_event.lua`

## Module Purpose

The event module gives Lurek2D two lightweight messaging primitives: a FIFO event queue for polling named events and a handle-based signal dispatcher for callback-style fan-out. It exists so gameplay code can communicate across systems without introducing direct ownership or import dependencies between those systems.

The queue side is about ordered delivery and explicit consumption. Engine or gameplay code can push named events with primitive payload values, and scripts can poll or wait for them later. The signal side is about local pub-sub: listeners subscribe by name, get handles back, and can be removed or cleared without needing a full feature-rich event bus.

This module intentionally does not own OS input capture, scene transitions, or higher-order event orchestration policies. Hardware events originate in `input` and the app loop, richer callback patterns live under `patterns`, and Lua registry management for callbacks belongs in `src/lua_api/event_api.rs` rather than in the core `event` data structures.

## Files
- `mod.rs` is the module root and public re-export layer. It makes the queue and signal pieces feel like one coherent runtime service to the rest of the engine.
- `event_queue.rs` defines the FIFO event model, Lua value conversion helpers, and queue operations such as push, poll, clear, pump, and wait. This is the right file for changes to payload shape or queue semantics.
- `signal.rs` defines the handle-based subscription registry used by `Signal`. It owns subscribe, remove, clear, and listener-count behavior, but deliberately does not store executable callbacks.

## Key Types
- `EventArg` is the queue payload atom for strings, numbers, booleans, and nil. Its narrow type set is deliberate so event payloads stay easy to bridge to and from Lua.
- `Event` is a single named queue entry with an ordered payload vector. It is the unit that moves through `EventQueue`.
- `EventQueue` is the pollable FIFO for system and gameplay events. Use it when order and explicit consumption matter more than callback fan-out.
- `Signal` is the module's lightweight pub-sub dispatcher. It tracks listener handles by event name and is the right primitive when code wants broadcast-style notification without touching the queue.
- `Subscription` is the bookkeeping record behind `Signal`. It matters mainly when reasoning about handle lifecycle and listener cleanup rather than everyday gameplay logic.
- `event_to_lua_multi` is the core bridge helper for turning an `Event` into a Lua-visible multi-return. It is not a type, but it is a key object-level boundary in the module because the queue API depends on it.
