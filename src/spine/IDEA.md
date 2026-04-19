# IDEA.md — `spine`

| Field  | Value           |
| ------ | --------------- |
| Module | `spine`         |
| Path   | `src/spine/`    |
| Date   | 2026-04-18      |
| Tier   | Feature Systems |

## Mission

Hierarchical bone-based skeletal animation: bone trees, world-transform propagation, keyframe timelines with easing, two-bone IK constraints, slot/skin system, and debug rendering. Powers rigged character and object animation without requiring the Spine runtime SDK.

## Strengths

- Clean topological bone hierarchy with O(n) world-transform propagation — no recursion.
- Full keyframe timeline system with five easing types and sorted-insert ordering.
- Two-bone IK solver using analytic law-of-cosines — stable and cheap.
- Skin/slot system enables runtime equipment and costume swaps.
- Animation blending (`apply_to_skeleton_blended`) supports cross-fade transitions.
- Event keyframes allow frame-precise sound/effect triggers.
- Pure CPU data model with separate `render.rs` for debug drawing — no coupling.

## Gaps

- No file format import (Spine JSON, DragonBones, Aseprite skeleton) — skeletons must be built programmatically. **Spine** (Esoteric Software) exports JSON/binary; **DragonBones** exports to JSON; **Godot** imports `.tres`/`.tscn` from Spine. All competitors load assets from authored files.
- No mesh deformation / vertex skinning — limited to rigid-piece (paper-doll) animation. **LÖVE** via `spine-love` supports mesh attachments; **Godot** Skeleton2D has `Polygon2D` mesh deform; **Solar2D** via spine-corona supports meshes.
- No animation state machine or blending tree — only one active animation, manual cross-fade. **Godot** has `AnimationTree` with blend spaces; **Spine** runtime has `AnimationState` with track mixing; **Unity 2D Animation** has `Animator` with state graphs.

## Features (Competitor Cites)

1. **Spine JSON import** — Spine runtime (Esoteric Software), Godot Skeleton2D importer, DragonBones JSON loader. Essential for artist pipeline integration.
2. **Mesh deformation / weighted vertices** — Spine mesh attachments, Godot Polygon2D bone-weighted deform, LÖVE spine-love mesh support. Enables smooth organic animation.
3. **Animation state machine / blending tree** — Godot AnimationTree, Spine AnimationState track mixing, Unity 2D Animator state graph. Automates transitions, layered anims.

## Perf / Quality

- `update_world_transforms` is O(n) with no heap allocation — good for per-frame.
- `SkeletonAnimation::apply_to_skeleton` clones the animation each frame inside `update_animation` to avoid borrow conflicts — an `Rc` or index-based approach would eliminate the clone.
- IK solver runs per-constraint with a clone of the constraint — same clone concern.
- No SIMD or batched bone processing; fine for typical character rigs (< 50 bones).

## Test Gaps

- `skeleton.rs` had no tests — added: construction, bone/slot CRUD, transform propagation, animation playback (loop/non-loop), IK, skins, slot attachment lookup.
- `mod.rs` has no tests (re-exports only — acceptable).
- No integration test for full animation → IK → render pipeline round-trip.
- No benchmark for `update_world_transforms` at scale (100+ bones).

## TODO(dedup)

- `update_animation` clones the entire `SkeletonAnimation` each frame to work around borrow checker. Deduplicate by storing animation index and applying via index.
- `apply_ik_constraints` clones each `IKConstraint`. Use index-based iteration to avoid clone.

## TODO(helper)

- `Skeleton::from_json(path)` — load a Spine/DragonBones JSON file into a Skeleton.
- `Skeleton::pose_at(animation_name, time)` — snapshot a specific frame without playback state.
- `SkeletonAnimation::reverse()` — play an animation clip backwards.

## TODO(plugin)

- **Plugin candidacy: TIER-2-PLUGIN.** Spine is a Feature Systems module with no core-engine consumers. It could be extracted behind a `spine` Cargo feature flag. The Lua surface `lurek.spine.*` would remain but the Rust types would move to an optional crate.
- Mesh deformation and file format import are candidates for a `spine-formats` plugin.

## References

- `docs/specs/spine.md` — module spec (canonical).
- `src/lua_api/spine_api.rs` — Lua binding.
- `src/render/renderer.rs` — `RenderCommand` types used by `render.rs`.
- `src/image/` — `ImageData` used by `draw_to_image`.
