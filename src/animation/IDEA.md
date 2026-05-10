- DONE: Add a Spine bridge so animation state machines can drive Spine rigs.
  → `src/animation/spine_bridge.rs` — `SpineAnimBridge` struct with `map()`, `map_looping()`, `update(dt, &mut AnimStateMachine)`.
- DONE: Deduplicate sprite-sheet grid slicing by integrating `Animation::add_frames_from_grid` with `SpriteSheet` data.
  → Added `Animation::add_frames_from_rects(&[Rect]) -> usize`. Lua binding: `LAnimation:addFramesFromRects(rects)`.
  → `animation` is Tier 1 and must not import `sprite`; the bridge is intentionally at the Lua layer via `buildCharacter` or caller-assembled quads.
- DONE: Implement real PingPong clip playback so Aseprite PingPong tags do not run forward-only.
  → `ClipPlaybackMode::PingPong` in `src/animation/clip.rs`; update loop in `Animation::update`.
- DONE: Add an explicit PingPong clip mode on `AnimClip`.
  → `ClipPlaybackMode` enum (`Forward`, `Reverse`, `PingPong`); `Animation::add_clip_with_mode`.
- DONE: Allow one `AnimCurve` timeline to drive multiple named properties in parallel.
  → `AnimPropertyTimeline` in `src/animation/curve.rs` with `add_keyframe(time, props)`, `eval_property`, `eval_all`.
- DONE: Remove the per-frame `AnimClip` clone in `Animation::update` and borrow instead.
  → `update()` now borrows the clip by index instead of cloning it.
- DONE: Add `AnimFrame::new(quad, duration)` for API consistency.
  → `AnimFrame::new(quad: Rect, duration: f32)` in `src/animation/frame.rs`.
- DONE: Add Rust tests for `Animation::load_from_aseprite`, including tag-direction and empty-frame cases.
  → `aseprite_tests` module in `tests/rust/unit/animation_tests.rs`.
- DONE: Add Rust tests for multi-hop `AnimStateMachine::update` transition chains.
  → `state_machine_chain_tests` module in `tests/rust/unit/animation_tests.rs`.
- DONE: Add a fuzz target for `load_aseprite_json`.
  → `load_aseprite_json_random_payloads_do_not_panic` (256 pseudo-random seeds) +
     `load_aseprite_json_structured_malformed_inputs_do_not_panic` (16 structured edge cases including
     inverted ranges, out-of-bounds indices, unknown direction strings, zero-size frames, Unicode names,
     and truncated JSON). Formal `cargo-fuzz` target is blocked on nightly toolchain.
- DONE: Unify Aseprite JSON parsing between `animation::aseprite` and `sprite::atlas`, or define a strict layering boundary.
  → Documented format boundary in module-level doc comments:
     `animation::aseprite` = Aseprite JSON (frames + frameTags with durations).
     `sprite::atlas` = TexturePacker JSON (named regions, no animation metadata).
     Different schemas, different tools, must not be merged.
- DONE: Clarify or deduplicate ownership between `AnimCurve` and `tween::TweenState`.
  → Documented design boundary in `src/animation/curve.rs` module doc:
     `AnimCurve`/`AnimPropertyTimeline` = permanently attached to an animation clip, reset/loops with it.
     `TweenState` = one-shot or explicitly triggered, lifecycle managed by the tween engine.
- DONE: Add a Lua helper that bundles Animation, SpriteSheet, and state machine setup for common animated-character flows.
  → `lurek.animation.buildCharacter(cfg)` in `src/lua_api/animation_api.rs`.
- DONE: Add an animation preview helper that renders frames into an `ImageData` grid for debug UI.
  → `Animation::draw_preview_grid(columns, cell_size)` in `src/animation/controller.rs`.
     Lua binding: `LAnimation:drawPreviewGrid(columns, cellSize)`.
