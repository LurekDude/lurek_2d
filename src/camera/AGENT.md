# camera - Agent Reference

## Module Info

- Module: camera
- Group: Platform Services
- Spec: docs/specs/camera.md
- Lua API: src/lua_api/camera_api.rs
- Rust tests: tests/rust/unit/camera_tests.rs
- Lua tests: tests/lua/unit/test_camera.lua, tests/lua/stress/test_camera_stress.lua, tests/lua/integration/test_tween_camera.lua, tests/lua/integration/test_tilemap_camera.lua, tests/lua/integration/test_scene_camera.lua, tests/lua/integration/test_parallax_camera.lua, tests/lua/integration/test_input_camera.lua, tests/lua/integration/test_graphics_camera.lua

## Module Purpose

The camera module owns 2D camera math and virtual viewport mapping. It provides the simple Camera type used for view transforms, the richer Camera2D type used for follow behavior and coordinate conversion, and the viewport helpers that map a logical game resolution onto an actual window.

This module stays on the CPU side of the engine. It can produce transform-stack render commands and screen-to-world conversions, but it does not own live window state, renderer internals, or scene logic. Other systems decide what the camera follows and when it moves; camera is responsible for the math and state needed to express that behavior cleanly.

## Files

- mod.rs: Declares the camera submodules and re-exports the public camera and viewport surface.
- types.rs: Defines Camera and Camera2D, including transforms, follow logic, bounds, shake, and coordinate conversion.
- viewport.rs: Defines ScaleMode and Viewport for logical-resolution scaling and coordinate mapping.
- viewport_scale.rs: Defines ViewportScale, a viewport helper that also tracks scaled output dimensions.
- render.rs: Converts Camera and Camera2D state into push, translate, rotate, scale, and pop render commands.

## Key Types

- Camera: Lightweight camera state with position, zoom, rotation, and view-matrix generation.
- Camera2D: Gameplay-facing 2D camera with follow targets, dead zones, look-ahead, bounds clamping, shake, and coordinate helpers.
- Viewport: Logical-resolution mapper that computes scale and offset for letterbox, stretch, and pixel-perfect modes.
- ViewportScale: Viewport variant that also tracks scaled pixel dimensions for transform-stack integration.
- ScaleMode: Enum selecting letterbox, stretch, or pixel-perfect viewport behavior.
