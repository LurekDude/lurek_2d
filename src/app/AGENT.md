# app

## Module Info
- Module name: app
- Module group: Edge/Integration
- Spec path: docs/specs/app.md
- Lua API path(s): None directly. App consumes the VM assembled in src/lua_api/mod.rs.
- Rust test path(s): tests/rust/unit/engine_tests.rs; tests/rust/ext/graphics_runtime_smoke_tests.rs
- Lua test path(s): None dedicated

## Module Purpose

The app module is the engine composition root. It exists to turn configuration, platform services, shared runtime state, and the Lua VM into a running desktop application with a winit event loop, GPU renderer, input processing, and frame lifecycle callbacks.

This is where engine startup policy lives: window creation, renderer initialization, splash behavior when no game is loaded, SharedState ownership, frame pacing, restart or error-screen transitions, and routing of OS events into engine systems. If a change affects the overall boot sequence or the order in which runtime systems come alive, it usually lands here.

The module intentionally does not own the underlying domain logic for rendering, input, audio, physics, or Lua bindings. It wires those systems together and drives them at runtime, but their actual behavior lives in their own modules. App is orchestration, not a place for subsystem-specific business logic.

## Files
- mod.rs: Module root that exposes the public app-facing types. It keeps the external surface small while hiding most of the runtime wiring details.
- app.rs: Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions.
- app_winit.rs: Contains alternate or parked winit-specific app code that is not part of the active module export surface. Treat it as implementation context, not the first place to extend live behavior unless it is reconnected deliberately.
- debug_overlay.rs: Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack.
- error_screen.rs: Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output.

## Key Types
- App: Public entry point used to launch the engine with loaded configuration and optional startup error context. It is the outward-facing runtime shell around the real application lifecycle.
- LunaApp: Internal winit application handler that owns most live runtime state during execution. This is the type to inspect when debugging frame flow, event ordering, or integration between platform callbacks and SharedState.
- RunState: Internal state machine that distinguishes normal execution from error display and restart transitions. It exists so the app loop can recover from some failures without collapsing the whole process immediately.
- DebugOverlay: Small runtime overlay for FPS and draw-call visibility. It is useful when changes affect per-frame diagnostics rather than the full devtools subsystem.
- ErrorScreen: Structured error presentation model that converts failures into readable render commands. It is the module's user-facing failure surface.