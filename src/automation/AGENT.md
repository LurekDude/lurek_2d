# automation

## Module Info
- Module name: automation
- Module group: Feature Systems
- Spec path: docs/specs/automation.md
- Lua API path(s): src/lua_api/automation_api.rs
- Rust test path(s): tests/rust/unit/automation_tests.rs
- Lua test path(s): tests/lua/unit/test_automation.lua

## Module Purpose

The automation module replays scripted input into the engine event queue. It exists so tests, demos, and developer tooling can drive the game exactly as if keys, mouse movement, clicks, wheel events, or text input came from real hardware.

Its core abstraction is a named Script made of timed Step records. A Simulator owns those scripts, advances playback over time, and turns each due Step into a synthetic event for the shared EventQueue. That keeps automation compatible with the rest of the input stack instead of inventing a separate test-only path.

This module does not own input state, window events, or general scheduling. Real hardware capture and input state live in input and the app loop, while generic timers and callback scheduling belong in timer. Automation only manages script data, playback state, and event injection.

## Files
- mod.rs: Module root that documents the automation surface and re-exports Script, Simulator, Action, and Step. This is the shortest entry point for understanding what the module exposes to other Rust code.
- script.rs: Defines Script, the named container for a time-sorted list of Steps. It also enforces the step-count cap and supports TOML-based script loading.
- simulator.rs: Defines Simulator and its internal playback state machine. This is the runtime engine that loads scripts, starts and stops playback, advances elapsed time, and pushes synthetic events into the EventQueue.
- step.rs: Defines the Action enum and Step record that describe a single timed automation action. This file is the schema for every script entry regardless of whether it comes from Lua, TOML, or Rust-side tests.

## Key Types
- Script: Named automation script with optional human-readable metadata and an ordered Vec of Step values. It is the durable unit loaded into the simulator and reused across playback runs.
- Simulator: Playback engine that owns the script registry, current script selection, elapsed time, next-step index, and running or paused state. This is the type to inspect when behavior changes around script lifecycle, event dispatch timing, or completion rules.
- Step: One timed automation record with optional fields for key names, scancodes, mouse coordinates, wheel deltas, button data, and text input. It is intentionally flexible so a single structure can represent all supported synthetic input events.
- Action: Enum of supported automation actions such as keypress, mousemove, mousepress, and wait. It is the boundary between script data and concrete EventQueue dispatch behavior.