# sprite

## General Info

- Module group: `Feature Systems.`
- Source path: `src/sprite/`
- Lua API path(s): `src/lua_api/sprite_api.rs`
- Primary Lua namespace: `lurek.sprite`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `sprite` module provides Lurek2D's sprite and sprite-batch rendering types.
It is a Feature Systems tier module sitting above the `render` command queue,
offering higher-level game-graphics abstractions rather than raw draw calls.

**Sprite**: `Sprite` is the smallest individually controlled image quad,
wrapping a `TextureKey`, `Rect` source region, world-space position, rotation
(radians), per-axis scale, multiplicative tint `[f32; 4]` color, blend mode,
and Z-order integer. Calling `draw()` pushes a `RenderCommand::DrawImage` into
`SharedState`'s pending draw list, making each sprite a lightweight, directly
scriptable entity rather than a managed pooled object.

**SpriteBatch**: Groups many sprites sharing one texture into a single GPU draw
call, critical for efficiently rendering large numbers of similar objects
(bullets, particles, crowd NPCs, map decorations). Instances are added via
`add(x, y, src_rect, opts)`, accumulating `BatchEntry` records in a
pre-allocated `Vec<SpriteInstance>`. The batch emits one
`RenderCommand::DrawSpriteBatch` per flush, which `GpuRenderer` handles as a
single instanced draw call. The instance list is cleared at the start of each
frame. `buffer_size()` exposes the pre-allocated capacity for sizing decisions.

**SpriteSheet**: Maps 0-based frame indices to UV rectangles within a uniform
grid on a single texture. Named `FrameGroup` ranges allow game code to reference
animation sequences by name (`"walk_right"`, `"idle"`) rather than raw index
ranges. `DirectionLayout` describes whether directional frames are arranged
row-by-row or column-by-column. Factory helpers `from_rpgmaker()` build
RPGMaker VX/Ace-compatible 3×4 character sheets with standard directional
groups; `from_atlas()` builds a sheet from named entries in a `SpriteAtlas`
rather than a uniform grid.

**SpriteAtlas**: Imports TexturePacker-format JSON exports
(`parse_texturepacker_json`) and Aseprite JSON exports (`parse_aseprite_json`)
with `AtlasEntry` records per named region: trimmed source `Rect`, original
source size, rotation flag, pivot point, and optional nine-patch flags.
`get_flipped()` returns a copy with horizontal/vertical flip applied to the
source bounds without modifying the atlas.

**NineSlice**: Renders scalable nine-patch textures for resizable UI panels,
dialog boxes, and HUD frames without visible stretch artifacts. `patches()`
partitions the source texture and destination rectangle into a 3×3 grid of
`Patch` (src_rect, dst_rect) tuples that the caller passes to the render queue
as nine individual image draws.

**SpriteSheet debugging**: `draw_to_image()` renders the sheet grid as a
color-coded `ImageData` debug view with frame-boundary overlays, useful for
verifying grid layout and named group assignments during authoring.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`,
`runtime`. Lua bridge in `src/lua_api/sprite_api.rs` as `lurek.sprite.*`.
## Files

- `atlas.rs`: TexturePacker JSON atlas importer and named region lookup.
- `mod.rs`: Module root and re-export surface for the public sprite-related types.
- `nine_slice.rs`: Nine-slice descriptor and patch computation for scalable UI panels and borders.
- `sprite.rs`: Single sprite data with transform and tint information around a texture identifier.
- `sprite_batch.rs`: Batch container for many sprite entries that share one texture key.
- `sprite_sheet.rs`: Grid-based sprite sheet, named frame groups, and optional directional layout helpers.

## Types

- `AtlasEntry` (`struct`, `atlas.rs`): A single named region within a sprite atlas.
- `SpriteAtlas` (`struct`, `atlas.rs`): In-memory sprite atlas built from a TexturePacker JSON export.
- `Patch` (`type`, `nine_slice.rs`): One computed source/destination rectangle tuple produced by a nine-slice layout.
- `NineSlice` (`struct`, `nine_slice.rs`): Scalable panel descriptor built from one texture plus four insets.
- `Sprite` (`struct`, `sprite.rs`): Smallest textured sprite unit with position, scale, rotation, and tint.
- `SpriteBatch` (`struct`, `sprite_batch.rs`): Shared-texture batch container used to prepare many sprite draws efficiently.
- `BatchEntry` (`struct`, `sprite_batch.rs`): One packed sprite instance inside a batch, including source quad and transform fields.
- `FrameGroup` (`struct`, `sprite_sheet.rs`): Named frame-range descriptor inside a sprite sheet.
- `DirectionLayout` (`enum`, `sprite_sheet.rs`): Enum describing whether directional frames are arranged by rows or columns.
- `SpriteSheet` (`struct`, `sprite_sheet.rs`): Atlas helper that maps grid frames and named groups to reusable regions.

## Functions

- `AtlasEntry::get_flipped` (`atlas.rs`): Returns a copy of this entry with the requested flip flags applied.
- `SpriteAtlas::new` (`atlas.rs`): Creates an empty atlas.
- `SpriteAtlas::add_entry` (`atlas.rs`): Adds a region to the atlas.
- `SpriteAtlas::get_entry` (`atlas.rs`): Returns the region with the given name, or `None`.
- `SpriteAtlas::get_by_index` (`atlas.rs`): Returns the region at the given index, or `None`.
- `SpriteAtlas::entry_count` (`atlas.rs`): Returns the number of regions in the atlas.
- `SpriteAtlas::entry_names` (`atlas.rs`): Returns all region names in insertion order.
- `parse_texturepacker_json` (`atlas.rs`): Parses a TexturePacker JSON export string and returns a [`SpriteAtlas`].
- `parse_aseprite_json` (`atlas.rs`): Parses an Aseprite JSON export and returns a [`SpriteAtlas`].
- `NineSlice::new` (`nine_slice.rs`): Creates a new nine-slice definition.
- `NineSlice::patches` (`nine_slice.rs`): Returns the 9 source and destination rectangles for rendering.
- `Sprite::new` (`sprite.rs`): Creates a new `Sprite` at `position` using the texture identified by `texture_id`.
- `Sprite::set_position` (`sprite.rs`): Sets the world-space position of the sprite.
- `Sprite::set_scale` (`sprite.rs`): Sets the per-axis scale of the sprite.
- `Sprite::set_rotation` (`sprite.rs`): Sets the rotation of the sprite in radians.
- `Sprite::set_color` (`sprite.rs`): Sets the multiplicative tint color applied to the sprite.
- `SpriteBatch::new` (`sprite_batch.rs`): Creates a new empty sprite batch for the given texture.
- `SpriteBatch::add` (`sprite_batch.rs`): Adds a sprite entry to the batch.
- `SpriteBatch::clear` (`sprite_batch.rs`): Removes all entries from the batch.
- `SpriteBatch::texture_key` (`sprite_batch.rs`): Returns the texture key this batch draws from.
- `SpriteBatch::entries` (`sprite_batch.rs`): Returns a slice of all batch entries.
- `SpriteBatch::len` (`sprite_batch.rs`): Returns the number of entries in the batch.
- `SpriteBatch::is_empty` (`sprite_batch.rs`): Returns true if the batch has no entries.
- `SpriteBatch::buffer_size` (`sprite_batch.rs`): Returns the maximum number of entries (buffer size).
- `SpriteSheet::new` (`sprite_sheet.rs`): Create a new sprite sheet by dividing a texture into a uniform grid.
- `SpriteSheet::get_frame` (`sprite_sheet.rs`): Return the quad for a 0-based frame index.
- `SpriteSheet::get_frame_count` (`sprite_sheet.rs`): Total number of frames in the sheet.
- `SpriteSheet::get_frame_size` (`sprite_sheet.rs`): Dimensions of a single frame `(width, height)`.
- `SpriteSheet::get_grid_size` (`sprite_sheet.rs`): Grid dimensions `(columns, rows)`.
- `SpriteSheet::get_row` (`sprite_sheet.rs`): Return all frame quads in a 0-based row.
- `SpriteSheet::get_column` (`sprite_sheet.rs`): Return all frame quads in a 0-based column.
- `SpriteSheet::get_range` (`sprite_sheet.rs`): Return a contiguous range of frame quads starting at `start` (0-based).
- `SpriteSheet::name_group` (`sprite_sheet.rs`): Store a named frame group.
- `SpriteSheet::get_group` (`sprite_sheet.rs`): Return the frame quads for a named group.
- `SpriteSheet::get_group_names` (`sprite_sheet.rs`): Return the names of all defined groups.
- `SpriteSheet::set_directions` (`sprite_sheet.rs`): Set the directional mode (4 or 8 directions) and layout.
- `SpriteSheet::get_direction_frames` (`sprite_sheet.rs`): Return the frame quads for a 0-based direction index.
- `SpriteSheet::draw_to_image` (`sprite_sheet.rs`): Renders the sprite-sheet grid into a new `ImageData` as a colour-coded debug view.
- `SpriteSheet::from_rpgmaker` (`sprite_sheet.rs`): Builds an RPGMaker VX/Ace-style 3-column × 4-row character sprite sheet.
- `SpriteSheet::from_atlas` (`sprite_sheet.rs`): Builds a sprite sheet whose frame quads are sourced from named entries in a [`SpriteAtlas`].

## Lua API Reference

- Binding path(s): `src/lua_api/sprite_api.rs`
- Namespace: `lurek.sprite`

### Module Functions
- `lurek.sprite.newSheet`: Creates a sprite sheet with a uniform grid of `frame_w × frame_h` frames.
- `lurek.sprite.newRPGMakerSheet`: Creates an RPGMaker VX/Ace character sheet (3 cols × 4 rows) with "down", "left", "right", "up" groups.
- `lurek.sprite.parseAtlas`: Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
- `lurek.sprite.newAtlasSheet`: Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
- `lurek.sprite.parseAsepriteAtlas`: Parses an Aseprite JSON export string and returns a `SpriteAtlas`.

### `SpriteAtlas` Methods
- `SpriteAtlas:getEntry`: Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
- `SpriteAtlas:getByIndex`: Returns the region at the given 1-based insertion index, or nil.
- `SpriteAtlas:entryCount`: Returns the total number of named regions in the atlas.
- `SpriteAtlas:entryNames`: Returns a sequential table of all region names.

### `SpriteSheet` Methods
- `SpriteSheet:getFrame`: Returns the quad for the 0-based frame index, or nil if out of range.
- `SpriteSheet:getFrameCount`: Returns the total number of frames in the sheet.
- `SpriteSheet:getRow`: Returns a sequential table of quad tables for every frame in the given row.
- `SpriteSheet:getColumn`: Returns a sequential table of quad tables for every frame in the given column.
- `SpriteSheet:getGroupFrames`: Returns a sequential table of quad tables for the named frame group, or nil.
- `SpriteSheet:getGroupNames`: Returns a sequential table of all defined group names.
- `SpriteSheet:getFrameSize`: Returns the width and height of a single frame cell in pixels.
- `SpriteSheet:getGridSize`: Returns the number of columns and rows in the grid.
- `SpriteSheet:drawToImage`: Renders the sheet grid as a debug view into a new ImageData.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems.`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/sprite/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
