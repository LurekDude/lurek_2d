---
name: animation-system
description: "Load this skill when implementing sprite animations, frame sequencing, sprite-sheet slicing, or tween-based property animation in Luna2D. Skip it for static image rendering, physics, audio, or engine-side Rust code."
---

# Animation System — Luna2D Engine

## Load When

- Writing Lua animation state machines (walk cycles, idle, attack frames)
- Implementing sprite-sheet frame selection or texture atlas slicing
- Building tween/interpolation helpers for position, scale, or opacity
- Deciding whether to add source-rect support to `DrawCommand`

## Owns

- Lua-side animation state (frame index, timer, loop flag)
- Sprite sheet slicing strategy given current `DrawCommand` constraints
- `luna.update(dt)` frame-advance pattern
- Linear interpolation (tween) for smooth property animation

## Does Not Cover

- Rust renderer internals → use `software-rendering` skill
- Particle effects or screen-shake → use `shader-patterns` skill
- Physics-driven motion → use `physics-engine` skill

## Live Repository Contracts

- `src/graphics/renderer.rs` — `DrawCommand` enum; `DrawImage { texture_id, x, y }` is the only image variant; **no source-rect field exists**
- `src/graphics/sprite.rs` — `Sprite` struct: `texture_id`, `position`, `scale`, `rotation`, `color`; no frame or source-rect field
- `src/lua_api/graphics_api.rs` — `luna.graphics.newImage(path)` → `texture_id: usize`; `luna.graphics.draw(id, x, y)`

## Decision Rules

- **Animation state lives in Lua locals, not the engine.** The engine has no animation component; track `current_frame`, `frame_timer`, `frame_duration`, `looping` as Lua table fields or locals.
- **dt-based timing only.** Never advance frames by raw frame count; always use `frame_timer += dt` so animation speed is display-rate independent.
- **Frame wrap vs clamp.** Looping animations: `current_frame = (current_frame % frame_count) + 1`. One-shot animations: clamp at `frame_count` and set a `finished` flag.
- **Source-rect gap.** `DrawImage` has no source rect — drawing a single frame from a sprite sheet is **not natively supported**. Workaround: load each frame as a separate texture via `luna.graphics.newImage`. Adding `DrawCommand::DrawImageRegion { texture_id, x, y, sx, sy, sw, sh }` is the correct engine-side fix when this is needed.
- **Tween pattern.** For smooth property animation: store `elapsed` and `duration`; each update `elapsed = math.min(elapsed + dt, duration)`; compute `t = elapsed / duration`; apply `value = start + (target - start) * t`. Use `1 - (1 - t)^2` for ease-out.
- **No Sprite struct in Lua.** `src/graphics/sprite.rs` is a Rust-only type; Lua scripts manage draw state manually through `luna.graphics.draw` calls.

## Frame-Advance Pattern

> See [example.lua](example.lua) for the frame-advance pattern code example.
