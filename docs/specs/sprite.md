# `sprite` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | Indirect / none |
| **Source** | `src/sprite/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The sprite module owns the engine's sprite-domain data types without taking ownership of the GPU backend. It exists so gameplay, UI, animation, and render-facing code can share a stable set of structs for single sprites, sprite batches, sprite sheets, and scalable nine-slice panels.

Its boundary is deliberately CPU-side: these types hold transforms, atlas regions, batch entries, and patch geometry, but they do not issue draw calls themselves. Rendering, texture loading, and shader execution stay in other modules, while `src/sprite/` remains the place to change sprite layout rules and batching data contracts.

**Scope boundary**: This module currently depends on `math`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
No direct Lua namespace — consumed through app/runtime integration or other bindings
    |
    v
src/sprite/mod.rs
    |- nine_slice.rs - nine_slice
    |- sprite.rs - sprite
    |- sprite_batch.rs - sprite_batch
    |- sprite_sheet.rs - sprite_sheet
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root and re-export surface for the public sprite-related types. |
| `nine_slice.rs` | Nine-slice descriptor and patch computation for scalable UI panels and borders. |
| `sprite.rs` | Single sprite data with transform and tint information around a texture identifier. |
| `sprite_batch.rs` | Batch container for many sprite entries that share one texture key. |
| `sprite_sheet.rs` | Grid-based sprite sheet, named frame groups, and optional directional layout helpers. |

---

## Submodules

### `sprite::nine_slice`

Nine-slice descriptor and patch computation for scalable UI panels and borders.

- **`Patch`** (type): A single patch rectangle: `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
- **`NineSlice`** (struct): A nine-slice image definition: a texture plus border insets.

### `sprite::sprite`

Single sprite data with transform and tint information around a texture identifier.

- **`Sprite`** (struct): A textured game object with position, scale, rotation, and tint color.

### `sprite::sprite_batch`

Batch container for many sprite entries that share one texture key.

- **`SpriteBatch`** (struct): A batch of sprites sharing a single texture, drawn in one GPU call.
- **`BatchEntry`** (struct): A single sprite in a batch, describing position, region, and transform.

### `sprite::sprite_sheet`

Grid-based sprite sheet, named frame groups, and optional directional layout helpers.

- **`FrameGroup`** (struct): Named frame group within the sprite sheet.
- **`DirectionLayout`** (enum): Directional layout for sprite sets.
- **`SpriteSheet`** (struct): Grid-based sprite sheet with directional support and named groups.

---

## Key Types

### Public Types

#### `Sprite`

Smallest textured sprite unit with position, scale, rotation, and tint.

#### `SpriteBatch`

Shared-texture batch container used to prepare many sprite draws efficiently.

#### `BatchEntry`

One packed sprite instance inside a batch, including source quad and transform fields.

#### `SpriteSheet`

Atlas helper that maps grid frames and named groups to reusable regions.

#### `FrameGroup`

Named frame-range descriptor inside a sprite sheet.

#### `DirectionLayout`

Enum describing whether directional frames are arranged by rows or columns.

#### `NineSlice`

Scalable panel descriptor built from one texture plus four insets.

#### `Patch`

One computed source/destination rectangle tuple produced by a nine-slice layout.

---

## Lua API

This module does not expose a dedicated direct Lua namespace. It is consumed indirectly through higher-level engine callbacks, shared state, or other `lurek.*` surfaces.

---

## Lua Examples

```lua
-- This module has no dedicated direct Lua namespace.
-- It is used indirectly through other engine systems.
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 6 |
| `enum` | 1 |
| `fn` (Lua API) | 0 |
| **Total** | **7** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/sprite/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.
