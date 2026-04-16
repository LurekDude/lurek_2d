# spine

## General Info

- Module group: `Feature Systems.`
- Source path: `src/spine/`
- Lua API path(s): `src/lua_api/spine_api.rs`
- Primary Lua namespace: `lurek.spine`
- Rust test path(s): tests/rust/unit/spine_tests.rs
- Lua test path(s): tests/lua/unit/test_spine.lua

## Summary

The `spine` module provides Lurek2D's hierarchical skeletal animation system for rigged character and object animation. It is a Feature Systems tier module implementing its own skeleton, animation, IK, and skin systems rather than integrating the official Spine SDK (respecting design assumption A-02 and licensing constraints).

`Skeleton` owns a flat list of `Bone` nodes with individual local transforms (translation x/y, rotation in radians, scale x/y) and parent bone indices. `update_world_transforms()` performs an O(n) top-down pass multiplying each bone's local transform with its parent's accumulated world transform, updating `world_x`, `world_y`, `world_rotation`, and `world_scale_x/y`. This produces the pose's complete world-space transform set without recursion.

`Slot` is an attachment point linking a bone to a displayable resource: a sprite region (`TextureRegion`), a deformable `Mesh` (for surface deformation via bone-weighted vertices), or a `PointAttachment` for secondary IK targets or weapon mounts. Swapping slot attachments at runtime implements skins and equipment changes.

`BoneTimeline` and `Keyframe` provide keyframe-driven animation: each keyframe carries a time offset, a target transform value, and an `EasingType` for the segment. `SkeletonAnimation` is a named clip with per-bone `BoneTimeline` entries. `AnimationSet` groups named animations for a skeleton. `IKConstraint` solves two-bone IK chains (upper/lower limb) using the law of cosines for inverse kinematics targeting.

Updated spine animation methods expand the Lua-accessible surface for runtime skeleton manipulation. New methods on `Skeleton` and `SkeletonAnimation` allow Lua scripts to query current pose state, blend between animation clips, and attach or detach slot resources dynamically through `lurek.spine.*`, reducing the boilerplate needed for common game-character workflows like equipment swaps and procedural pose blending.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/spine_api.rs`.

## Files

- `bone.rs`: Individual bone data with local transform input and cached world transform output.
- `ik.rs`: Two-bone IK constraint using the law-of-cosines analytic solver.
- `mod.rs`: Module root and re-export surface for the public skeletal types.
- `render.rs`: Debug render-command generation for bones and slot attachment placeholders.
- `skeleton.rs`: Skeleton ownership, bone and slot management, transform propagation, and CPU image helpers.
- `slot.rs`: Slot data binding an attachment name, tint, and draw order to a bone index.
- `timeline.rs`: Keyframe timelines and skeleton animation playback for the spine module.

## Types

- `Bone` (`struct`, `bone.rs`): Single skeletal node with local transform fields and propagated world transform fields.
- `IKConstraint` (`struct`, `ik.rs`): Two-bone IK constraint: positions two chained bones to reach a world-space target.
- `BoneParams` (`struct`, `skeleton.rs`): Convenience parameter bundle for creating bones in one call.
- `Skeleton` (`struct`, `skeleton.rs`): Top-level rig object that owns bones, slots, root transform state, and hierarchy updates.
- `Slot` (`struct`, `slot.rs`): Attachment record that binds a named visual slot to a specific bone.
- `EasingType` (`enum`, `timeline.rs`): Interpolation curve type for keyframe blending.
- `BoneProperty` (`enum`, `timeline.rs`): Bone local-transform property that a timeline can animate.
- `Keyframe` (`struct`, `timeline.rs`): A single timed value sample on a bone timeline.
- `BoneTimeline` (`struct`, `timeline.rs`): Sequence of keyframes that animate a single property of a single bone.
- `EventKeyframe` (`struct`, `timeline.rs`): A timed event marker inside a [`SkeletonAnimation`].
- `SkeletonAnimation` (`struct`, `timeline.rs`): Named animation clip for a skeleton: contains timelines for multiple bones.

## Functions

- `Bone::new` (`bone.rs`): Creates a new bone with identity local transform and no parent.
- `Bone::with_parent` (`bone.rs`): Creates a bone with a parent index and local offset.
- `IKConstraint::new` (`ik.rs`): Creates a new two-bone IK constraint.
- `IKConstraint::set_target` (`ik.rs`): Sets the world-space target position for this constraint.
- `IKConstraint::solve` (`ik.rs`): Solves the two-bone IK and writes the resulting local rotations into the bone array.
- `Skeleton::generate_render_commands` (`render.rs`): Generate debug render commands for the skeleton at the given world position.
- `Skeleton::new` (`skeleton.rs`): Creates a new empty skeleton.
- `Skeleton::add_bone` (`skeleton.rs`): Adds a bone to the skeleton and returns its index.
- `Skeleton::add_slot` (`skeleton.rs`): Adds a slot to the skeleton and returns its index.
- `Skeleton::find_bone` (`skeleton.rs`): Finds a bone by name and returns its index.
- `Skeleton::find_slot` (`skeleton.rs`): Finds a slot by name and returns its index.
- `Skeleton::add_bone_full` (`skeleton.rs`): Creates and adds a bone with the given local transform in one call.
- `Skeleton::add_slot_full` (`skeleton.rs`): Creates and adds a slot with an optional attachment name in one call.
- `Skeleton::bone_world_transform` (`skeleton.rs`): Returns the world-space transform of the bone at the given index.
- `Skeleton::set_root_position` (`skeleton.rs`): Sets the root bone's local position and propagates world transforms.
- `Skeleton::bone_count` (`skeleton.rs`): Returns the number of bones in this skeleton.
- `Skeleton::add_animation` (`skeleton.rs`): Adds a [`SkeletonAnimation`] to this skeleton's animation library.
- `Skeleton::find_animation` (`skeleton.rs`): Returns the index of the animation with the given name.
- `Skeleton::play_animation` (`skeleton.rs`): Starts playing the named animation.
- `Skeleton::stop_animation` (`skeleton.rs`): Stops playback of the current animation.
- `Skeleton::update_animation` (`skeleton.rs`): Advances the active animation by `dt` seconds, applies keyframes, and wraps or stops at the end.
- `Skeleton::get_animation_time` (`skeleton.rs`): Returns the current playback time in seconds.
- `Skeleton::add_ik_constraint` (`skeleton.rs`): Adds an IK constraint and returns its index.
- `Skeleton::set_ik_target` (`skeleton.rs`): Sets the target position for the named IK constraint.
- `Skeleton::apply_ik_constraints` (`skeleton.rs`): Evaluates all IK constraints and writes resulting rotations into the bone array.
- `Skeleton::add_skin` (`skeleton.rs`): Registers a new empty skin by name.
- `Skeleton::set_skin` (`skeleton.rs`): Sets the active skin, changing slot attachment lookups.
- `Skeleton::get_skin` (`skeleton.rs`): Returns the name of the currently active skin.
- `Skeleton::set_skin_mapping` (`skeleton.rs`): Registers a slot-to-attachment mapping within a named skin.
- `Skeleton::get_slot_attachment` (`skeleton.rs`): Returns the effective attachment name for a slot, consulting the active skin first.
- `slot_count` (`skeleton.rs`): Returns the number of slots in this skeleton.
- `update_world_transforms` (`skeleton.rs`): Propagates local transforms down the bone hierarchy to compute world transforms.
- `draw_to_image` (`skeleton.rs`): Renders the skeleton as a stick figure to an `ImageData`.
- `draw_bones_to_image` (`skeleton.rs`): Draw skeleton with colour-coded joints and bone labels.
- `Slot::new` (`slot.rs`): Creates a new slot bound to a bone with default white colour and no attachment.
- `EasingType::apply` (`timeline.rs`): Applies the easing curve to a normalised time value `t ∈ [0, 1]`.
- `BoneTimeline::new` (`timeline.rs`): Creates a new empty timeline for the given bone and property.
- `BoneTimeline::add_key` (`timeline.rs`): Appends a keyframe at `time` with `value` and the given easing.
- `BoneTimeline::evaluate` (`timeline.rs`): Evaluates the timeline at `time`, interpolating between surrounding keyframes.
- `EventKeyframe::new` (`timeline.rs`): Creates a new event keyframe.
- `SkeletonAnimation::new` (`timeline.rs`): Creates a new empty skeleton animation clip.
- `SkeletonAnimation::add_timeline` (`timeline.rs`): Appends a bone timeline.
- `SkeletonAnimation::add_event_key` (`timeline.rs`): Adds an event keyframe to the clip.
- `SkeletonAnimation::collect_events` (`timeline.rs`): Returns the names of all events whose timestamps fall in `(from, to]`.
- `SkeletonAnimation::apply_to_skeleton` (`timeline.rs`): Evaluates all timelines at `time` and writes results into the skeleton's bones.
- `SkeletonAnimation::apply_to_skeleton_blended` (`timeline.rs`): Evaluates all timelines at `time` and **blends** the results with the skeleton's current bone values using `blend_weight`.

## Lua API Reference

- Binding path(s): `src/lua_api/spine_api.rs`
- Namespace: `lurek.spine`

### Module Functions
- `lurek.spine.newSkeleton`: Creates a new empty skeleton with the given name.
- `lurek.spine.newSkeletonAnimation`: Creates a new empty SkeletonAnimation clip with the given name and duration.

### `Skeleton` Methods
- `Skeleton:findBone`: Returns the index of the named bone, or nil if not found.
- `Skeleton:findSlot`: Returns the index of the named slot, or nil if not found.
- `Skeleton:updateWorldTransforms`: Propagates local transforms down the bone hierarchy to compute world positions.
- `Skeleton:getBoneWorld`: Returns the world-space transform of a bone as a table, or nil if out of range.
- `Skeleton:setPosition`: Sets the root bone position and propagates world transforms.
- `Skeleton:boneCount`: Returns the total number of bones.
- `Skeleton:slotCount`: Returns the total number of slots.
- `Skeleton:drawToImage`: Renders the skeleton as a stick-figure debug view into a new ImageData.
- `Skeleton:stopAnimation`: Stops the current skeletal animation.
- `Skeleton:updateAnimation`: Advances the playing animation by `dt` seconds and applies keyframes.
- `Skeleton:getAnimationTime`: Returns the current playback time in seconds of the active animation.
- `Skeleton:addAnimation`: Adds a SkeletonAnimation to this skeleton's library.
- `Skeleton:addSkin`: Registers a new empty skin by name.
- `Skeleton:setSkin`: Activates the named skin for attachment lookups.
- `Skeleton:getSkin`: Returns the name of the currently active skin, or nil.

### `SkeletonAnimation` Methods
- `SkeletonAnimation:getDuration`: Returns the total duration of the animation in seconds.
- `SkeletonAnimation:getTimelineCount`: Returns the number of bone timelines in this animation.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/spine/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
