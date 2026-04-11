# scene

## Module Info
- Group: Feature Systems.
- Source: `src/scene/`.
- Spec: `docs/specs/scene.md`.
- Lua bridge: `src/lua_api/scene_api.rs` registers `lurek.scene`.
- Runtime focus: stack-based scene flow, transition bookkeeping, registry/data helpers, and depth-sorted callback batching.

## Module Purpose
The scene module owns the Rust-side state model for scene flow. It exists so games can push, pop, replace, and query scenes through one consistent stack abstraction while leaving the actual scene tables and lifecycle callback execution in the Lua API layer.

Its boundary is intentionally narrow: `SceneStack` tracks IDs, registry entries, shared data keys, and active transition timing, while `DepthSorter` provides a per-frame helper for ordering scene-related draw callbacks. It does not own scene content, entity storage, or renderer-specific transition visuals; those stay in Lua or in the systems the scenes call into.

## Files
- `mod.rs`: Module root and re-export surface for the stack, transition, and depth-sorting types.
- `depth_sorter.rs`: Per-frame depth-ordered callback batcher used by the Lua scene layer.
- `render.rs`: Empty render-command and simple CPU-image helpers so `SceneStack` fits shared engine interfaces.
- `stack.rs`: Scene stack, registry, shared-data bookkeeping, and transition state ownership.
- `transition.rs`: Transition-type enum plus active transition progress and timer logic.

## Key Types
- `SceneId`: Stable integer identifier used by the Rust stack while Lua owns the actual scene tables.
- `SceneStack`: Main scene-flow owner for stack order, registry lookups, stored data keys, and active transition state.
- `TransitionType`: Enum for no transition, fade, and slide directions.
- `ActiveTransition`: Timer and progress record for one transition in flight.
- `DepthSorter`: Per-frame sorter for scene draw callbacks or scene objects.
- `DepthEntry`: Individual depth-sorted entry stored inside `DepthSorter`.
