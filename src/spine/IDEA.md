# IDEA.md — `spine` module

> Migrated from `ideas/features/spine.md`.
> Status checked against `src/spine/` and `src/lua_api/spine_api.rs`.
> Lua namespace: `lurek.spine`.

---

## Features

### ✅ DONE — Skeleton with Bone Hierarchy
**Source**: features/spine.md — Summary

`lurek.spine.newSkeleton()` — flat `Vec<Bone>` + world-transform propagation. O(n) linear walk.

---

### ✅ DONE — Bone Operations (Add, Find, Set Position)
**Source**: features/spine.md — Summary

`addBone`, `addChildBone`, `findBone`, `setPosition`, `getBoneWorld`, `updateWorldTransforms`.

---

### ✅ DONE — Slots (Visual Attachment + Draw Order)
**Source**: features/spine.md — Summary

`addSlot`, `findSlot`, `slotCount` — bind sprites to bones with RGBA tint.

---

### ❌ TODO — Animation Timelines (CRITICAL)
**Source**: features/spine.md — Feature Gaps #2 / Suggestions #1

No built-in keyframe animation for bone transforms over time. Without timelines,
the module is a data structure only — must update every bone every frame from Lua manually.

```lua
skeleton:addAnimation("walk", {
  boneFrames = {
    { bone = "leg_l", keyframes = {{t=0, rx=0}, {t=0.3, rx=30}, {t=0.6, rx=0}} }
  }
})
skeleton:play("walk")
```

---

### ❌ TODO — IK Solver (Inverse Kinematics)
**Source**: features/spine.md — Feature Gaps #1 / Suggestions #2

Forward kinematics only. No IK for limb targeting (foot placement, arm reach, look-at).
Two-bone IK would cover the majority of use cases.

```lua
skeleton:addIKConstraint("arm", targetBone, chainLength=2)
```

---

### ✅ DONE — Animation Blending
**Source**: features/spine.md — Feature Gaps #4

`SkeletonAnimation::apply_to_skeleton_blended(skeleton, time, blend_weight)` added to `src/spine/timeline.rs`.
`LuaSkeleton:blendAnimation(anim, time, weight?)` registered in `src/lua_api/spine_api.rs`.
Lerps each bone property between current pose and target animation at the given blend weight.

```lua
skeleton:updateAnimation(dt)        -- advance primary clip
skeleton:blendAnimation(run_anim, t, 0.6)  -- blend in run at 60%
```

Implemented: 2026-04-15

---

### ❌ TODO — Skin / Attachment Swapping
**Source**: features/spine.md — Feature Gaps #6 / Suggestions #7

No skin system for swapping character outfits, weapon visuals, or color variants.

```lua
skeleton:setSkin("heavy_armor")
```

---

### ✅ DONE — Animation Event Callbacks
**Source**: features/spine.md — Feature Gaps #5

`EventKeyframe` struct + `events: Vec<EventKeyframe>` field added to `SkeletonAnimation` in `src/spine/timeline.rs`.
`SkeletonAnimation:add_event_key(time, name, value)` and `:collect_events(from, to)` added.
`LuaSkeletonAnimation:addEventKey(time, name, value?)` and `:getEvents(from, to)` registered in `src/lua_api/spine_api.rs`.

```lua
anim:addEventKey(0.25, "footstep", 0)
anim:addEventKey(0.75, "footstep", 0)
lurek.process = function(dt)
    local events = anim:getEvents(prev_t, current_t)
    for _, e in ipairs(events) do
        if e.name == "footstep" then lurek.audio.play(step_snd) end
    end
end
```

Implemented: 2026-04-15

---

### ❌ TODO — Spine JSON / DragonBones File Import
**Source**: features/spine.md — Feature Gaps #8 / Suggestions #3+4

No file format import. Artists use Spine and DragonBones export pipelines. Without
import support, must build skeletons programmatically (very tedious).

---

### ❌ TODO — Mesh Deformation (Vertex Skinning)
**Source**: features/spine.md — Feature Gaps #3

Slots bind sprites only — no mesh deformation by bone weights. Limits animation to
rigid piece (paper-doll) style.

---

### 🤔 CONSIDER — Rename to `skeleton` Module
**Source**: features/spine.md — Structural Issues

`lurek.spine` implies compatibility with the Spine animation tool. Since there's
no Spine file import and this is a custom implementation, `lurek.skeleton` is more
accurate and avoids confusion.

---

### 🤔 CONSIDER — Bridge with `animation` Module
**Source**: features/spine.md — Structural Issues

`animation` handles frame-based clips. `spine` handles bone hierarchies. Merging
into a unified animation system with sub-systems would improve ergonomics:
- `lurek.animation.newClip()` — existing frame-based
- `lurek.animation.newSkeleton()` — current spine
- `lurek.animation.newTimeline()` — new keyframe-over-bone
