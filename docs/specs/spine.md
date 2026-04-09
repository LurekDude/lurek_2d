# `spine` — Agent Reference

| Property       | Value                                          |
|----------------|------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                      |
| **Status**     | Implemented — Full                             |
| **Lua API**    | `luna.spine`                                   |
| **Source**     | `src/spine/`                                   |
| **Rust Tests** | `tests/rust/unit/spine_tests.rs`               |
| **Lua Tests**  | `tests/lua/unit/test_spine.lua`                |
| **Architecture** | —                                            |

## Summary

The `spine` module implements **skeletal 2D animation** — bone hierarchies, slots, and world-transform propagation. It is a Tier 2 Engine Extension that provides the data model for hierarchical bone rigs without any GPU, audio, or windowing dependency. This is a **completely separate system** from the `animation` module: `animation` advances frame indices through a sprite-sheet (like an animated GIF); `spine` propagates affine transforms through a parent-child bone tree (like a rigged character). Use one, the other, or both independently.

A `Skeleton` owns a flat `Vec<Bone>` array where parent-child relationships are encoded with `parent_index` pointers into earlier array entries. This means bones must be added in topological order (parent before child). Calling `Skeleton::update_world_transforms()` walks the array linearly (O(n)), composing each bone's local translation, rotation, and scale with its parent's world transform using standard 2D affine math (cos/sin rotation, multiplicative scaling). Root bones (those with no parent) are transformed by the skeleton's own root position and scale.

`Slot` values bind visual attachments (sprites, meshes) to bones. Each slot records a bone index, an optional attachment name, RGBA tint colour, and a draw-order integer for z-sorting. The `lua_api` layer reads slot data to position and tint sprites at the bone's world-space location.

`BoneParams` is a convenience struct that bundles all bone creation parameters for the `add_bone_full()` one-call constructor — name, parent index, position, rotation, and scale.

The design is inspired by the Spine runtime data model but uses entirely custom Rust types with no external SDK dependency or licence requirement. The module intentionally does not include animation timeline playback, IK solvers, or mesh deformation — those would be separate extensions if needed.

**Scope boundary**: This module owns only the bone graph data structure and transform math. GPU rendering of bone-attached sprites is handled by `lua_api/spine_api.rs`. Animation clip playback is handled externally by the `animation` module or Lua-side frame logic.

## Architecture

```
                    luna.spine.newSkeleton(name)
                              │
                              ▼
               ┌──────────────────────────────┐
               │     LuaSkeleton (UserData)    │  ← lua_api/spine_api.rs
               │       wraps Skeleton          │
               └──────────┬───────────────────┘
                          │
                          ▼
               ┌──────────────────────────────┐
               │        Skeleton              │  ← skeleton.rs
               │  name, x, y, scale_x/y      │
               │  bones: Vec<Bone>            │
               │  slots: Vec<Slot>            │
               └──────┬────────┬──────────────┘
                      │        │
               ┌──────┘        └──────┐
               ▼                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │      Bone       │    │      Slot       │  ← slot.rs
    │  name           │    │  name           │
    │  parent_index   │    │  bone_index     │
    │  local_x/y      │    │  color_rgba     │
    │  local_rotation  │    │  attachment_name│
    │  local_scale_x/y │    │  draw_order    │
    │  world_x/y      │    └─────────────────┘
    │  world_rotation  │
    │  world_scale_x/y │
    └─────────────────┘
           bone.rs

  update_world_transforms():
     for each bone in array order (topological):
       root  → world = skeleton.pos + local * skeleton.scale
       child → world = parent.world ⊕ local (rotate + scale)
```

## Source Files

| File          | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| `bone.rs`     | `Bone` struct — local and world transform fields, constructors           |
| `skeleton.rs` | `Skeleton` and `BoneParams` — bone/slot management, world-transform propagation |
| `slot.rs`     | `Slot` struct — bone attachment binding with tint colour and draw order   |

## Submodules

### `spine::bone`

Bone hierarchy node holding local transform data (position, rotation, scale) relative to a parent, plus computed world-space transform fields updated by `Skeleton::update_world_transforms()`.

- **`Bone`** (struct): A single bone in a skeletal hierarchy with local and world transform fields.

### `spine::skeleton`

Root type managing the flat bone array and slot list, with methods for adding/finding bones and slots and propagating world transforms.

- **`BoneParams`** (struct): Parameter bundle for creating and adding a bone with full local transform in one call.
- **`Skeleton`** (struct): A skeletal animation rig composed of a bone hierarchy and render slots.

### `spine::slot`

Attachment slot that links a visual resource (sprite, mesh) to a bone for positioned rendering with tint and z-order.

- **`Slot`** (struct): A slot binding a visual attachment to a bone with RGBA tint colour and draw order.

## Key Types

### Structs

#### `spine::bone::Bone`

A single bone in a skeletal hierarchy. Each bone stores a local transform (position, rotation, scale) relative to its parent (or the skeleton root if `parent_index` is `None`). After `Skeleton::update_world_transforms()`, the `world_*` fields contain the computed world-space transform. Fields: `name` (String), `parent_index` (Option\<usize\>), `local_x/y/rotation/scale_x/scale_y` (f32), `world_x/y/rotation/scale_x/scale_y` (f32).

Key methods:
- `Bone::new(name)` — creates a root bone with identity transform.
- `Bone::with_parent(name, parent, x, y)` — creates a child bone with parent index and local offset.

#### `spine::skeleton::BoneParams`

Parameters for creating and adding a bone in one call via `Skeleton::add_bone_full()`. Fields: `name` (String), `parent_index` (Option\<usize\>), `x`, `y`, `rotation`, `scale_x`, `scale_y` (all f32).

#### `spine::skeleton::Skeleton`

A skeletal animation rig composed of a bone hierarchy and render slots. The skeleton owns a flat `Vec<Bone>` (parent indices index into this vec) and a `Vec<Slot>`. Fields: `name` (String), `bones` (Vec\<Bone\>), `slots` (Vec\<Slot\>), `x`, `y`, `scale_x`, `scale_y` (f32).

Key methods:
- `Skeleton::new(name)` — creates an empty skeleton at the origin with unit scale.
- `add_bone(bone)` → usize — appends a bone and returns its index.
- `add_slot(slot)` → usize — appends a slot and returns its index.
- `add_bone_full(params)` → usize — creates and adds a bone from `BoneParams`.
- `add_slot_full(name, bone_index, attachment)` → usize — creates and adds a slot.
- `find_bone(name)` → Option\<usize\> — looks up a bone by name.
- `find_slot(name)` → Option\<usize\> — looks up a slot by name.
- `bone_world_transform(idx)` → Option\<(f32,f32,f32,f32,f32)\> — returns world-space (x, y, rotation, scale_x, scale_y).
- `set_root_position(x, y)` — sets root bone position and calls `update_world_transforms()`.
- `bone_count()` → usize — number of bones.
- `slot_count()` → usize — number of slots.
- `update_world_transforms()` — propagates local transforms down the hierarchy.

#### `spine::slot::Slot`

A slot binding a visual attachment to a bone in the skeleton. Determines which bone drives the attachment's position, plus tint colour and draw order. Fields: `name` (String), `bone_index` (usize), `color_r/g/b/a` (f32), `attachment_name` (Option\<String\>), `draw_order` (i32).

Key methods:
- `Slot::new(name, bone_index)` — creates a slot with white colour, no attachment, draw order 0.

### Enums

No public enums.

## Lua API

Exposed under `luna.spine.*` by `src/lua_api/spine_api.rs`. The API provides a `LuaSkeleton` UserData type returned by the factory function.

### Module Functions

| Function                    | Signature                                      | Description                                        |
|-----------------------------|------------------------------------------------|----------------------------------------------------|
| `luna.spine.newSkeleton`    | `(name: string) → Skeleton`                    | Creates a new empty skeleton with the given name   |

### Skeleton Methods (UserData)

| Method                   | Signature                                              | Description                                        |
|--------------------------|--------------------------------------------------------|----------------------------------------------------|
| `addBone`                | `(name: string, opts?: table) → integer`               | Adds a root bone with optional local transform     |
| `addChildBone`           | `(name: string, parent_idx: integer, opts?: table) → integer` | Adds a child bone attached to a parent       |
| `addSlot`                | `(name: string, bone_idx: integer, attachment?: string) → integer` | Adds a slot bound to a bone              |
| `findBone`               | `(name: string) → integer?`                            | Returns bone index, or nil if not found            |
| `findSlot`               | `(name: string) → integer?`                            | Returns slot index, or nil if not found            |
| `updateWorldTransforms`  | `() → nil`                                             | Propagates local transforms to compute world positions |
| `getBoneWorld`           | `(idx: integer) → table?`                              | Returns `{x, y, rotation, scale_x, scale_y}` or nil |
| `setPosition`            | `(x: number, y: number) → nil`                        | Sets root bone position and propagates transforms  |
| `boneCount`              | `() → integer`                                         | Returns the total number of bones                  |
| `slotCount`              | `() → integer`                                         | Returns the total number of slots                  |

The `opts` table for `addBone`/`addChildBone` accepts: `x`, `y`, `rotation`, `scale_x`, `scale_y` (all optional, default 0/0/0/1/1).

## Lua Examples

```lua
-- Build a simple character skeleton and query world positions
function luna.init()
    skeleton = luna.spine.newSkeleton("character")

    -- Root bone at (100, 200)
    local root = skeleton:addBone("root", { x = 100, y = 200 })

    -- Child bones branching from root
    local torso = skeleton:addChildBone("torso", root, { y = -40 })
    local arm_l = skeleton:addChildBone("arm_left", torso, { x = -20, rotation = 0.3 })
    local arm_r = skeleton:addChildBone("arm_right", torso, { x = 20, rotation = -0.3 })

    -- Attach a slot for a sprite to the torso
    skeleton:addSlot("torso_sprite", torso, "torso_skin")

    -- Compute world transforms
    skeleton:updateWorldTransforms()

    -- Query world position of arm
    local arm = skeleton:getBoneWorld(arm_l)
    if arm then
        print(string.format("Left arm at (%.1f, %.1f)", arm.x, arm.y))
    end
end

function luna.process(dt)
    -- Move skeleton and re-propagate
    skeleton:setPosition(150, 250)
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 4     |
| `enum`    | 0     |
| `fn`      | 16    |
| **Total** | **20** |

## References

| Module      | Relationship | Notes                                                         |
|-------------|--------------|---------------------------------------------------------------|
| `engine`    | Imports from | Uses `log_messages` constants for structured skeleton-load log |
| `math`      | —            | Does not import `math`; uses inline trig (`f32::cos`/`sin`)   |
| `lua_api`   | Imported by  | `spine_api.rs` wraps `Skeleton` as `LuaSkeleton` UserData     |
| `animation` | Related      | Animation clips can drive bone transforms per frame; `spine` owns the rig, `animation` owns the timeline |
| `graphics`  | Related      | `lua_api` reads slot data to position sprites at bone world positions; `spine` never imports `graphics` |

## Notes

- **Topological order invariant**: Bones must be added parent-before-child. The flat array walk in `update_world_transforms()` assumes `parent_index < current_index`. Violating this produces stale world transforms (no error, just wrong output).
- **No external crate dependency**: All bone/skeleton/slot types are custom Rust. The name "spine" is inspired by the Spine runtime model but there is no Spine SDK dependency or licence requirement.
- **No GPU dependency**: This module is pure computation — no `wgpu`, no `graphics` imports. It runs in headless tests without any display device.
- **Logging**: `Skeleton::new()` emits `log_msg!(info, SP01_SKEL_LOADED)` on every skeleton creation. This uses the engine's structured log message system.
- **Shear not implemented**: `Bone` has no `local_shear` field despite the Summary mentioning shear in the old version. The current implementation supports only translation, rotation, and scale.
- **No animation timeline**: The module does not include keyframe interpolation, IK constraints, or animation mixing. Frame-by-frame bone manipulation is done in Lua or via the `animation` module.
- **Slot colour is not applied by this module**: Slot `color_r/g/b/a` fields are stored but only consumed by the `lua_api` rendering pass. The `spine` module itself never reads them.
- **Breaking change surface**: Renaming `addBone`/`addChildBone`/`addSlot` or changing the opts-table key names would break Lua scripts. The `getBoneWorld` return table field names (`x`, `y`, `rotation`, `scale_x`, `scale_y`) are also part of the public contract.
