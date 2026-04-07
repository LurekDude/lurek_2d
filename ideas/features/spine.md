# spine — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/spine.md`
**Files**: Skeletal 2D animation (custom implementation, no Spine SDK)

## Purpose

Skeletal 2D animation through bone hierarchies and world-transform propagation. Owns the bone graph and transform math. No external Spine SDK dependency — custom implementation inspired by the Spine runtime model.

## Current Feature Summary

- `Skeleton`: flat `Vec<Bone>` + `Vec<Slot>`, top-down world-transform propagation
- `Bone`: local transform (position, rotation, scale) + computed world-space transform, parent index
- `Slot`: binds visual attachment to bone with RGBA tint and draw order
- `BoneParams`: parameter bundle for bone creation
- O(n) linear walk for world transforms (topological order guarantee)
- Lua API: `newSkeleton`, `addBone`, `addChildBone`, `addSlot`, `findBone`, `findSlot`, `updateWorldTransforms`, `getBoneWorld`, `setPosition`, `boneCount`, `slotCount`

## Feature Gaps

1. **No IK (Inverse Kinematics)**: Can only pose bones via FK (forward kinematics). IK is essential for limb targets (foot placement, arm reaching, look-at).
2. **No animation timelines**: No built-in way to animate bone transforms over time. Must manually set bone positions each frame from Lua. This is the #1 usability gap.
3. **No mesh deformation**: Slots bind sprites only. Can't deform meshes by bone weights (vertex skinning). Limits to rigid piece animation.
4. **No animation blending**: Can't blend between two poses (walk→run transition). Must hard-cut.
5. **No animation events**: Can't trigger callbacks at specific keyframes (footstep sounds, spawn particles at impact).
6. **No skin/slot swapping**: Can't swap character skins (different outfits, weapon visuals) without rebuilding the skeleton.
7. **No shear transform**: Only translation, rotation, scale. Shear is used for squash-and-stretch effects.
8. **No file format import**: Can't load Spine JSON/Binary or DragonBones files. Must build skeletons programmatically.

## Structural Issues

- **Disconnect from animation module**: `animation` handles frame-based clips. `spine` handles bone hierarchies. Neither integrates with the other. A game with skeletal animation must glue them together manually.
- **Consider merging into animation**: Both modules deal with animation but through different paradigms (frame vs skeleton). A unified animation module with sub-systems would be cleaner:
  - `luna.animation.newClip()` ← current frame-based
  - `luna.animation.newSkeleton()` ← current spine
  - `luna.animation.newTimeline()` ← new: animate any property over time
- **Name "spine" is misleading**: Suggests compatibility with the Spine animation tool. But there's no Spine file import. Consider renaming to `skeleton` or `bones`.
- **Minimal API**: With only 11 Lua functions, this is one of the thinnest modules. It provides the data structure but not the tools to use it effectively.

## Suggestions

1. **Add animation timelines**: `skeleton:addAnimation(name, tracks)` where tracks define per-bone keyframes with interpolation. This transforms the module from a data structure into a usable animation system.
2. **Add IK solver**: `skeleton:addIKConstraint(bone, target, chainLength)` — two-bone IK at minimum.
3. **Add Spine JSON import**: `luna.spine.fromFile(jsonPath)` — load Spine export files. This alone would make the module production-ready, since artists use the Spine tool extensively.
4. **Add DragonBones import**: Alternative to Spine. Free and open-source.
5. **Rename to `skeleton`**: Avoids confusion with the Spine application. `luna.skeleton.new()` is clearer.
6. **Bridge with animation module**: Allow `AnimationClip` to drive bone transforms through keyframes. One unified animation system.
7. **Add skin support**: `skeleton:setSkin(name, slotMappings)` — swap visual attachments by name.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros | Spine (tool) |
|---|---|---|---|---|---|
| Bone hierarchy | ✅ | ❌ | ❌ | ✅ (runtime) | ✅ |
| World transforms | ✅ | N/A | N/A | ✅ | ✅ |
| IK | ❌ | N/A | N/A | ✅ | ✅ |
| Keyframe anim | ❌ | N/A | N/A | ✅ | ✅ |
| Mesh deform | ❌ | N/A | N/A | ✅ | ✅ |
| File import | ❌ | N/A | N/A | ✅ (Spine) | N/A |
| Animation blend | ❌ | N/A | N/A | ✅ | ✅ |

## Priority

**MEDIUM-HIGH** — Animation timelines and IK are critical to make skeletal animation usable. Without them, the module is just a data structure. Spine JSON import would connect to the professional animation workflow. Rename and animation module merger are structural fixes.
