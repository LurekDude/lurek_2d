# `animation` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.animation`                                     |
| **Source**     | `src/animation/`                                     |
| **Rust Tests** | `tests/rust/unit/animation_tests.rs`                 |
| **Lua Tests**  | `tests/lua/unit/test_animation.lua`                  |
| **Architecture** | �                                                  |

## Purpose

The `animation` module provides frame-based sprite animation for 2D characters and objects. It is a Tier 1 Engine Subsystem that depends only on `crate::math` (for `Rect`) and `crate::engine` (for structured log messages).

## Source Files

| File            | Purpose                                                                  |
|-----------------|--------------------------------------------------------------------------|
| `mod.rs`        | Module root � declares submodules and re-exports `AnimClip`, `Animation`, `AnimEvent`, `AnimFrame`, `AnimationFrame`. |
| `clip.rs`       | `AnimClip` � a named animation clip with frame indices, FPS, and loop flag. |
| `controller.rs` | `Animation` � the main playback controller with frame pool, clip registry, update loop, and event queue. |
| `event.rs`      | `AnimEvent` � enum of playback events (`Finished`, `FrameChanged`, `Looped`). |
| `frame.rs`      | `AnimFrame` � a single frame with a source rectangle and optional duration override. Also defines `AnimationFrame` type alias. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/animation.md`](../../docs/specs/animation.md)

_Update both this file **and** `docs/specs/animation.md` whenever source files, public types, or Lua bindings change._
