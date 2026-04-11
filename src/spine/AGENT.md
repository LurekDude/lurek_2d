# spine

## Module Info
- Group: Feature Systems.
- Source: `src/spine/`.
- Spec: `docs/specs/spine.md`.
- Lua bridge: `src/lua_api/spine_api.rs` registers `lurek.spine`.
- Runtime focus: skeletal bone hierarchies, slots, world-transform propagation, and debug-oriented rendering helpers.

## Module Purpose
The spine module owns skeletal 2D animation data for rigs that need parent-child transform propagation instead of frame-only sprite swaps. It exists so games can build a `Skeleton` from bones and slots, update world transforms deterministically, and query attachment points from Lua without exposing renderer internals.

Its core boundary is the bone graph and slot metadata: local transforms, parent indices, root transform state, and slot attachment records live here, while timeline playback, texture ownership, and final draw policy stay outside the module. The render helper in this directory is intentionally a debug-facing bridge that turns current skeleton state into simple draw commands rather than a full animation renderer.

## Files
- `mod.rs`: Module root and re-export surface for the public skeletal types.
- `bone.rs`: Individual bone data with local transform input and cached world transform output.
- `render.rs`: Debug render-command generation for bones and slot attachment placeholders.
- `skeleton.rs`: Skeleton ownership, bone and slot management, transform propagation, and CPU image helpers.
- `slot.rs`: Slot data binding an attachment name, tint, and draw order to a bone index.

## Key Types
- `Skeleton`: Top-level rig object that owns bones, slots, root transform state, and hierarchy updates.
- `Bone`: Single skeletal node with local transform fields and propagated world transform fields.
- `BoneParams`: Convenience parameter bundle for creating bones in one call.
- `Slot`: Attachment record that binds a named visual slot to a specific bone.
