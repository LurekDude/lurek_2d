# sprite

## Module Info
- Group: Feature Systems.
- Source: `src/sprite/`.
- Spec: `docs/specs/sprite.md`.
- Lua exposure: no dedicated `sprite_api.rs`; sprite-facing types are consumed through `src/lua_api/render_api.rs` and the render pipeline.
- Runtime focus: CPU-side sprite, batch, sheet, and nine-slice data structures.

## Module Purpose
The sprite module owns the engine's sprite-domain data types without taking ownership of the GPU backend. It exists so gameplay, UI, animation, and render-facing code can share a stable set of structs for single sprites, sprite batches, sprite sheets, and scalable nine-slice panels.

Its boundary is deliberately CPU-side: these types hold transforms, atlas regions, batch entries, and patch geometry, but they do not issue draw calls themselves. Rendering, texture loading, and shader execution stay in other modules, while `src/sprite/` remains the place to change sprite layout rules and batching data contracts.

## Files
- `mod.rs`: Module root and re-export surface for the public sprite-related types.
- `nine_slice.rs`: Nine-slice descriptor and patch computation for scalable UI panels and borders.
- `sprite.rs`: Single sprite data with transform and tint information around a texture identifier.
- `sprite_batch.rs`: Batch container for many sprite entries that share one texture key.
- `sprite_sheet.rs`: Grid-based sprite sheet, named frame groups, and optional directional layout helpers.

## Key Types
- `Sprite`: Smallest textured sprite unit with position, scale, rotation, and tint.
- `SpriteBatch`: Shared-texture batch container used to prepare many sprite draws efficiently.
- `BatchEntry`: One packed sprite instance inside a batch, including source quad and transform fields.
- `SpriteSheet`: Atlas helper that maps grid frames and named groups to reusable regions.
- `FrameGroup`: Named frame-range descriptor inside a sprite sheet.
- `DirectionLayout`: Enum describing whether directional frames are arranged by rows or columns.
- `NineSlice`: Scalable panel descriptor built from one texture plus four insets.
- `Patch`: One computed source/destination rectangle tuple produced by a nine-slice layout.
