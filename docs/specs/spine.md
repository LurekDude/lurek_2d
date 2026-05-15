# spine

## General Info

- Module group: `Feature Systems`
- Source path: `src/spine/`
- Lua API path(s): `src/lua_api/spine_api.rs`
- Primary Lua namespace: `lurek.spine`
- Rust test path(s): tests/rust/unit/spine_tests.rs
- Lua test path(s): tests/lua/unit/test_spine.lua

## Summary

The `spine` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `render`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

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

- `Bone::new` (`bone.rs`): Create a root bone at world origin with identity transform.
- `Bone::with_parent` (`bone.rs`): Create a child bone with the given parent index and local (x, y) offset; rotation and scale default to identity.
- `IKConstraint::new` (`ik.rs`): Create a new IKConstraint with the given chain indices and bend direction; target defaults to (0, 0).
- `IKConstraint::set_target` (`ik.rs`): Update the world-space target position for this constraint.
- `IKConstraint::solve` (`ik.rs`): Solve root and elbow local_rotation angles using law-of-cosines 2-bone IK; no-op when chain length < 2 or indices out of bounds.
- `Skeleton::generate_render_commands` (`render.rs`): Build a RenderCommand list for all bones (filled circles) and slot attachments (outline rectangles) at world offset (x, y); returns empty vec when no bones exist.
- `Skeleton::new` (`skeleton.rs`): Create an empty Skeleton with identity scale and no active animation.
- `Skeleton::add_bone` (`skeleton.rs`): Append a Bone to the bone array and return its new index.
- `Skeleton::add_slot` (`skeleton.rs`): Append a Slot to the slot array and return its new index.
- `Skeleton::find_bone` (`skeleton.rs`): Return the index of the first bone whose name matches, or None.
- `Skeleton::find_slot` (`skeleton.rs`): Return the index of the first slot whose name matches, or None.
- `Skeleton::add_bone_full` (`skeleton.rs`): Add a bone using a BoneParams descriptor; sets all local transform fields and returns the new index.
- `Skeleton::add_slot_full` (`skeleton.rs`): Add a slot with optional default attachment and return its new index.
- `Skeleton::bone_world_transform` (`skeleton.rs`): Return (world_x, world_y, world_rotation, world_scale_x, world_scale_y) for bone at idx, or None when out of bounds.
- `Skeleton::set_root_position` (`skeleton.rs`): Set the root bone local position and immediately recompute all world transforms.
- `Skeleton::bone_count` (`skeleton.rs`): Return the total number of bones in this skeleton.
- `Skeleton::add_animation` (`skeleton.rs`): Append an animation clip to the animations list.
- `Skeleton::find_animation` (`skeleton.rs`): Return the index of the first animation whose name matches, or None.
- `Skeleton::play_animation` (`skeleton.rs`): Start playing an animation by name with optional loop; returns false when the animation is not registered.
- `Skeleton::stop_animation` (`skeleton.rs`): Stop the current animation without resetting anim_time.
- `Skeleton::update_animation` (`skeleton.rs`): Advance anim_time by dt and apply the current animation to bone poses; loops or stops at duration.
- `Skeleton::get_animation_time` (`skeleton.rs`): Return current animation time in seconds.
- `Skeleton::add_ik_constraint` (`skeleton.rs`): Append an IK constraint and return its index.
- `Skeleton::set_ik_target` (`skeleton.rs`): Set the target position for the IK constraint named name; returns false when not found.
- `Skeleton::apply_ik_constraints` (`skeleton.rs`): Solve all registered IK constraints against the current bone poses in registration order.
- `Skeleton::add_skin` (`skeleton.rs`): Register an empty skin by name; no-op when the skin already exists.
- `Skeleton::set_skin` (`skeleton.rs`): Switch the active skin to name; returns false when the skin has not been registered.
- `Skeleton::get_skin` (`skeleton.rs`): Return the active skin name, or None when no skin is set.
- `Skeleton::set_skin_mapping` (`skeleton.rs`): Map an attachment name to a slot within a skin, creating the skin entry if absent.
- `Skeleton::get_slot_attachment` (`skeleton.rs`): Return the resolved attachment name for slot_idx: checks active skin first, then slot default; None when no attachment.
- `Skeleton::slot_count` (`skeleton.rs`): Return the number of slots in this skeleton.
- `Skeleton::update_world_transforms` (`skeleton.rs`): Recompute all bone world transforms from local pose, traversing bones in index order (parent-before-child required).
- `Skeleton::draw_to_image` (`skeleton.rs`): Rasterise skeleton bones and slot markers into a new ImageData of the given dimensions; fills background dark.
- `Skeleton::draw_bones_to_image` (`skeleton.rs`): Rasterise bones with per-bone colour labels and a bone-count status string into a new ImageData.
- `Slot::new` (`slot.rs`): Create a slot with white opaque tint, no attachment, and draw_order 0.
- `EasingType::apply` (`timeline.rs`): Evaluate this easing curve for t in [0, 1]; clamps input; Step always returns 0.0 (caller uses prev value).
- `BoneTimeline::new` (`timeline.rs`): Create an empty BoneTimeline targeting bone_idx and the given property.
- `BoneTimeline::add_key` (`timeline.rs`): Insert a keyframe at the correct sorted position by time.
- `BoneTimeline::evaluate` (`timeline.rs`): Return the interpolated bone property value at the given time; extrapolates from first or last key outside the range.
- `EventKeyframe::new` (`timeline.rs`): Create an EventKeyframe with the given time, name, and numeric value.
- `SkeletonAnimation::new` (`timeline.rs`): Create an empty animation clip with the given name and duration.
- `SkeletonAnimation::add_timeline` (`timeline.rs`): Append a BoneTimeline to this animation.
- `SkeletonAnimation::add_event_key` (`timeline.rs`): Insert an event at the given time; events are kept sorted by time.
- `SkeletonAnimation::collect_events` (`timeline.rs`): Return all event (name, value) pairs whose time is in the half-open range (from, to].
- `SkeletonAnimation::apply_to_skeleton` (`timeline.rs`): Apply all bone timelines at the given time to the target skeleton by setting local properties directly.
- `SkeletonAnimation::apply_to_skeleton_blended` (`timeline.rs`): Apply all bone timelines blended with blend_weight in [0, 1]; weight=1 is full override, weight=0 is no-op.
- `SkeletonAnimation::pose_at` (`timeline.rs`): Return the evaluated (bone_idx, property, value) pose snapshot for all timelines at the given time.
- `SkeletonAnimation::reverse` (`timeline.rs`): Return a new animation with all keyframe times mirrored around the clip duration.
- `SkeletonAnimation::from_json` (`timeline.rs`): Parse a SkeletonAnimation from a serde_json Value; returns None when required fields are missing or malformed.

## Lua API Reference

- Binding path(s): `src/lua_api/spine_api.rs`
- Namespace: `lurek.spine`

### Module Functions
- `lurek.spine.newSkeleton`: Creates a new empty skeleton with the given name. Add bones and slots to build the hierarchy.
- `lurek.spine.newSkeletonAnimation`: Creates a new empty animation with the given name and duration. Add keyframes to define motion.
- `lurek.spine.animationFromJson`: Parses a JSON string into a SkeletonAnimation. Returns nil if parsing fails or the format is invalid.

### `LSkeleton` Methods
- `LSkeleton:addBone`: Adds a root-level bone to the skeleton with optional transform properties.
- `LSkeleton:addChildBone`: Adds a bone as a child of an existing bone, inheriting its parent's world transform.
- `LSkeleton:addSlot`: Adds a slot attached to a specific bone, optionally assigning a default attachment name.
- `LSkeleton:findBone`: Searches for a bone by name and returns its zero-based index, or nil if not found.
- `LSkeleton:findSlot`: Searches for a slot by name and returns its zero-based index, or nil if not found.
- `LSkeleton:updateWorldTransforms`: Recomputes world transforms for all bones in hierarchy order. Call after modifying bone locals or IK targets.
- `LSkeleton:getBoneWorld`: Returns the final world-space transform of a bone after hierarchy resolution.
- `LSkeleton:setPosition`: Sets the root bone world position, shifting the entire skeleton.
- `LSkeleton:boneCount`: Returns the total number of bones in the skeleton.
- `LSkeleton:slotCount`: Returns the total number of slots in the skeleton.
- `LSkeleton:drawToImage`: Renders the skeleton into an in-memory image of the given dimensions and returns it as LImage userdata.
- `LSkeleton:playAnimation`: Starts playing a named animation on this skeleton. Optionally loops.
- `LSkeleton:stopAnimation`: Stops the currently playing animation and resets playback state.
- `LSkeleton:updateAnimation`: Advances the current animation by a delta time, applying bone transforms to the skeleton.
- `LSkeleton:getAnimationTime`: Returns the current playback time of the active animation in seconds.
- `LSkeleton:addAnimation`: Registers a SkeletonAnimation object with this skeleton so it can be played by name.
- `LSkeleton:addIKConstraint`: Adds an inverse-kinematics constraint that controls a chain of bones to reach a target position.
- `LSkeleton:setIKTarget`: Sets the world-space target position for a named IK constraint. Call updateWorldTransforms after.
- `LSkeleton:addSkin`: Registers a new named skin on this skeleton. Skins remap slot attachments for visual variants.
- `LSkeleton:setSkin`: Activates a named skin, applying its slot-attachment mappings to the skeleton.
- `LSkeleton:getSkin`: Returns the name of the currently active skin, or nil if no skin is set.
- `LSkeleton:setSkinMapping`: Maps a slot to a specific attachment name within a skin. When that skin is active, the slot shows this attachment.
- `LSkeleton:blendAnimation`: Blends an animation pose onto the skeleton at a given time with a weight factor for smooth transitions.
- `LSkeleton:type`: Returns the type name of this userdata object.
- `LSkeleton:typeOf`: Checks whether this object is of the given type name. Supports "LSkeleton" and "Object".

### `LSkeletonAnimation` Methods
- `LSkeletonAnimation:addKeyframe`: Adds a keyframe to a bone's property timeline at a specific time with a value and easing curve.
- `LSkeletonAnimation:getDuration`: Returns the total duration of this animation in seconds.
- `LSkeletonAnimation:addEventKey`: Inserts an event trigger at a specific time within the animation timeline.
- `LSkeletonAnimation:getEvents`: Collects all events that fire within a time range. Useful for triggering sound effects or gameplay actions.
- `LSkeletonAnimation:getTimelineCount`: Returns the number of bone-property timelines in this animation.
- `LSkeletonAnimation:poseAt`: Samples all timelines at a given time and returns the computed pose as an array of bone-property-value entries.
- `LSkeletonAnimation:reverse`: Creates a new animation that plays this animation's keyframes in reverse order.
- `LSkeletonAnimation:type`: Returns the type name of this userdata object.
- `LSkeletonAnimation:typeOf`: Checks whether this object is of the given type name. Supports "LSkeletonAnimation" and "Object".

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/spine/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### 2026-05-12 Update

- Added `SkeletonAnimation` helpers in `src/spine/timeline.rs`:
	- `pose_at(time)` (non-mutating pose snapshot)
	- `reverse()` (time-mirrored clip clone)
	- `from_json(&serde_json::Value)`
- Exposed in Lua API:
	- `LSkeletonAnimation:poseAt(time)`
	- `LSkeletonAnimation:reverse()`
	- `lurek.spine.animationFromJson(json)`
