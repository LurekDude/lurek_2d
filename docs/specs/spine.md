# `spine` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.spine` |
| **Source** | `src/spine/` |
| **Rust Tests** | `tests/rust/unit/spine_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_spine.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The spine module owns skeletal 2D animation data for rigs that need parent-child transform propagation instead of frame-only sprite swaps. It exists so games can build a `Skeleton` from bones and slots, update world transforms deterministically, and query attachment points from Lua without exposing renderer internals.

Its core boundary is the bone graph and slot metadata: local transforms, parent indices, root transform state, and slot attachment records live here, while timeline playback, texture ownership, and final draw policy stay outside the module. The render helper in this directory is intentionally a debug-facing bridge that turns current skeleton state into simple draw commands rather than a full animation renderer.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.spine.* (Lua API — src/lua_api/spine_api.rs)
    |
    v
src/spine/mod.rs
    |- bone.rs - bone
    |- render.rs - render
    |- skeleton.rs - skeleton
    |- slot.rs - slot
```

---

## Source Files

| File | Purpose |
|------|---------|
| `bone.rs` | Individual bone data with local transform input and cached world transform output. |
| `mod.rs` | Module root and re-export surface for the public skeletal types. |
| `render.rs` | Debug render-command generation for bones and slot attachment placeholders. |
| `skeleton.rs` | Skeleton ownership, bone and slot management, transform propagation, and CPU image helpers. |
| `slot.rs` | Slot data binding an attachment name, tint, and draw order to a bone index. |

---

## Submodules

### `spine::bone`

Individual bone data with local transform input and cached world transform output.

- **`Bone`** (struct): A single bone in a skeletal hierarchy.

### `spine::render`

Debug render-command generation for bones and slot attachment placeholders.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `spine::skeleton`

Skeleton ownership, bone and slot management, transform propagation, and CPU image helpers.

- **`BoneParams`** (struct): Parameters for creating and adding a bone in one call.
- **`Skeleton`** (struct): A skeletal animation rig composed of a bone hierarchy and render slots.

### `spine::slot`

Slot data binding an attachment name, tint, and draw order to a bone index.

- **`Slot`** (struct): A slot binding a visual attachment to a bone in the skeleton.

---

## Key Types

### Public Types

#### `Skeleton`

Top-level rig object that owns bones, slots, root transform state, and hierarchy updates.

#### `Bone`

Single skeletal node with local transform fields and propagated world transform fields.

#### `BoneParams`

Convenience parameter bundle for creating bones in one call.

#### `Slot`

Attachment record that binds a named visual slot to a specific bone.

---

## Lua API

Exposed under `lurek.spine.*` by `src/lua_api/spine_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.spine.newSkeleton` | Creates a new empty skeleton with the given name. |

### `Skeleton` Methods

| Method | Description |
|--------|-------------|
| `skeleton:addBone(...)` | Adds a root bone with optional local transform and returns its index. |
| `skeleton:findBone(...)` | Returns the index of the named bone, or nil if not found. |
| `skeleton:findSlot(...)` | Returns the index of the named slot, or nil if not found. |
| `skeleton:updateWorldTransforms(...)` | Propagates local transforms down the bone hierarchy to compute world positions. |
| `skeleton:getBoneWorld(...)` | Returns the world-space transform of a bone as a table, or nil if out of range. |
| `skeleton:setPosition(...)` | Sets the root bone position and propagates world transforms. |
| `skeleton:boneCount(...)` | Returns the total number of bones. |
| `skeleton:slotCount(...)` | Returns the total number of slots. |
| `skeleton:drawToImage(...)` | Renders the skeleton as a stick-figure debug view into a new ImageData. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.spine.
if lurek.spine then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 0 |
| `fn` (Lua API) | 10 |
| **Total** | **14** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/spine/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
