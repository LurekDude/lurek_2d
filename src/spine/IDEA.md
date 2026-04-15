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

### ✅ DONE — Animation Timelines
**Source**: features/spine.md — Feature Gaps #2 / Suggestions #1

`BoneTimeline`, `Keyframe`, `SkeletonAnimation` in `src/spine/timeline.rs`. `LuaSkeletonAnimation`
registered in `src/lua_api/spine_api.rs`. Supports `addAnimation`, `updateAnimation(dt)`, and
`playAnimation(name, loop?)`. Lerp/step interpolation per bone property per keyframe.

```lua
local anim = lurek.spine.newAnimation()
anim:addBoneKeyframe("leg_l", 0.0, {rx=0})
anim:addBoneKeyframe("leg_l", 0.3, {rx=30})
skeleton:addAnimation(anim)
skeleton:playAnimation(anim, true)
```

Implemented: source already present when IDEA.md was reviewed 2026-04-15

---

### ✅ DONE — IK Solver (Inverse Kinematics)
**Source**: features/spine.md — Feature Gaps #1 / Suggestions #2

Two-bone analytic IK in `src/spine/ik.rs` (`IKConstraint` struct with `apply_ik_two_bone`).
`LuaSkeleton:addIKConstraint(name, target_bone_name, chain_length?)` and `setIKTarget(name, x, y)`
registered in `src/lua_api/spine_api.rs`. Applied per-frame via `applyIKConstraints()`.

```lua
skeleton:addIKConstraint("arm", "hand_target", 2)
skeleton:setIKTarget("arm", mx, my)
skeleton:applyIKConstraints()
```

Implemented: source already present when IDEA.md was reviewed 2026-04-15

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

### ✅ DONE — Skin / Attachment Swapping
**Source**: features/spine.md — Feature Gaps #6 / Suggestions #7

`add_skin`, `set_skin`, `get_skin`, `set_skin_mapping`, `get_slot_attachment` in `src/spine/skeleton.rs`.
`LuaSkeleton:addSkin(name)`, `setSkin(name)`, `getSkin()`, `setSkinMapping(slot, skin, texture_key)` all
registered in `src/lua_api/spine_api.rs`. Skin mapping overrides slot attachments per skin.

```lua
skeleton:addSkin("heavy_armor")
skeleton:setSkinMapping("chest_slot", "heavy_armor", chest_tex)
skeleton:setSkin("heavy_armor")
```

Implemented: source already present when IDEA.md was reviewed 2026-04-15

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
