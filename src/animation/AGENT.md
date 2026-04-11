# animation - Agent Reference

## Module Info

- Module: animation
- Group: Feature Systems
- Spec: docs/specs/animation.md
- Lua API: src/lua_api/animation_api.rs
- Rust tests: tests/rust/unit/animation_tests.rs
- Lua tests: tests/lua/unit/test_animation.lua, tests/lua/stress/test_animation_stress.lua, tests/lua/integration/test_tween_animation.lua, tests/lua/integration/test_graphics_animation.lua, tests/lua/integration/test_animation_timer.lua, tests/lua/golden/test_animation_golden.lua

## Module Purpose

The animation module owns frame-based sprite playback. It stores reusable frame definitions, named clips, playback state, speed control, and emitted animation events while staying independent from scene ownership, textures, and gameplay rules.

This module exists to answer one narrow question well: given frames and clips, which frame should be active now and what events should fire as playback advances. Rendering integration lives in helper methods that turn the current frame into render-command data, but the module does not own GPU work, sprite assets, or non-frame-based animation systems such as tweening or skeletal animation.

## Files

- mod.rs: Declares the animation submodules and re-exports the public frame, clip, controller, event, and render parameter types.
- clip.rs: Defines AnimClip, the named sequence of frame indices with clip FPS and looping behavior.
- controller.rs: Defines Animation, the main playback controller for frames, clips, speed, current state, and pending events.
- event.rs: Defines AnimEvent, the event enum emitted for frame changes, loops, and completion.
- frame.rs: Defines AnimFrame plus the AnimationFrame compatibility alias.
- render.rs: Converts the current animation frame into renderer-facing DrawQuad command data.

## Key Types

- Animation: Main playback controller that owns frames, clips, speed, timers, and pending events.
- AnimClip: Named ordered frame sequence with clip-local FPS and looping configuration.
- AnimFrame: One source rectangle plus an optional per-frame duration override.
- AnimEvent: Playback event enum used to report frame changes, loops, and finished clips.
- AnimRenderParams: Caller-supplied texture and transform bundle used when generating render commands.
