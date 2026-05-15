# sprite

## General Info

- Module group: `Feature Systems`
- Source path: `src/sprite/`
- Lua API path(s): `src/lua_api/sprite_api.rs`
- Primary Lua namespace: `lurek.sprite`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `sprite` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `math`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

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

- `AtlasEntry::get_flipped` (`atlas.rs`): Clone this entry with the flip_x and flip_y flags replaced by the given values.
- `SpriteAtlas::new` (`atlas.rs`): Create an empty atlas with no entries.
- `SpriteAtlas::from_texture_atlas` (`atlas.rs`): Build a SpriteAtlas from an image::TextureAtlas, sorting regions by name.
- `SpriteAtlas::add_entry` (`atlas.rs`): Insert or replace an entry by name; updates both the Vec and the name map.
- `SpriteAtlas::get_entry` (`atlas.rs`): Look up a region by name; returns None when not present.
- `SpriteAtlas::get_by_index` (`atlas.rs`): Return the entry at the given insertion-order index, or None when out of bounds.
- `SpriteAtlas::entry_count` (`atlas.rs`): Return the total number of entries in this atlas.
- `SpriteAtlas::entry_names` (`atlas.rs`): Return all entry names in insertion order.
- `parse_texturepacker_json` (`atlas.rs`): Parses a TexturePacker JSON export string and returns a [`SpriteAtlas`].
- `parse_aseprite_json` (`atlas.rs`): Parses an Aseprite JSON export and returns a [`SpriteAtlas`].
- `NineSlice::new` (`nine_slice.rs`): Create a NineSlice with explicit border insets and full texture dimensions.
- `NineSlice::patches` (`nine_slice.rs`): Return the 9 Patch tuples for drawing a nine-slice box at (x, y) with target dimensions (w, h).
- `Sprite::new` (`sprite.rs`): Create a sprite at position with identity scale, zero rotation, and white tint.
- `Sprite::set_position` (`sprite.rs`): Set the world-space position to (x, y).
- `Sprite::set_scale` (`sprite.rs`): Set the non-uniform scale to (sx, sy).
- `Sprite::set_rotation` (`sprite.rs`): Set the rotation angle in radians.
- `Sprite::set_color` (`sprite.rs`): Replace the colour tint.
- `SpriteBatch::new` (`sprite_batch.rs`): Create a batch for texture_key with the given max_entries cap; 0 uses a default capacity of 256.
- `SpriteBatch::add` (`sprite_batch.rs`): Append a BatchEntry and return its index; returns None when the max_entries limit is reached.
- `SpriteBatch::clear` (`sprite_batch.rs`): Remove all entries without releasing the underlying allocation.
- `SpriteBatch::texture_key` (`sprite_batch.rs`): Return the TextureKey this batch is bound to.
- `SpriteBatch::entries` (`sprite_batch.rs`): Return the accumulated entry slice for this frame.
- `SpriteBatch::len` (`sprite_batch.rs`): Return the current number of entries in the batch.
- `SpriteBatch::is_empty` (`sprite_batch.rs`): Return true when the batch contains no entries.
- `SpriteBatch::buffer_size` (`sprite_batch.rs`): Return the configured max_entries cap; 0 means unlimited.
- `SpriteSheet::new` (`sprite_sheet.rs`): Create a SpriteSheet from texture dimensions and per-frame size; precomputes all frame Rects.
- `SpriteSheet::get_frame` (`sprite_sheet.rs`): Return the Rect for frame at linear index, or None when out of bounds.
- `SpriteSheet::get_frame_count` (`sprite_sheet.rs`): Return the total number of precomputed frames.
- `SpriteSheet::get_frame_size` (`sprite_sheet.rs`): Return (frame_width, frame_height) in pixels.
- `SpriteSheet::get_grid_size` (`sprite_sheet.rs`): Return (columns, rows) of the grid.
- `SpriteSheet::get_row` (`sprite_sheet.rs`): Return all frame Rects on the given row index; empty vec when row >= rows.
- `SpriteSheet::get_column` (`sprite_sheet.rs`): Return all frame Rects in the given column index; empty vec when col >= columns.
- `SpriteSheet::get_range` (`sprite_sheet.rs`): Return up to count frames starting at start; empty vec when start >= frame count.
- `SpriteSheet::name_group` (`sprite_sheet.rs`): Register a named frame group starting at start_frame for count consecutive frames.
- `SpriteSheet::get_group` (`sprite_sheet.rs`): Return the Rects for the named group, or None when the name is not registered.
- `SpriteSheet::get_group_names` (`sprite_sheet.rs`): Return all registered group names in unspecified order.
- `SpriteSheet::set_directions` (`sprite_sheet.rs`): Configure the sheet for directional animation with count directions arranged by layout.
- `SpriteSheet::get_direction_frames` (`sprite_sheet.rs`): Return all frame Rects for the given direction index; None when set_directions was not called or index out of range.
- `SpriteSheet::draw_to_image` (`sprite_sheet.rs`): Rasterise the sheet grid (red borders, green for group starts) into a new ImageData of the given dimensions.
- `SpriteSheet::from_rpgmaker` (`sprite_sheet.rs`): Create a SpriteSheet pre-configured for the RPGMaker 3×4 character sheet layout with named direction groups.
- `SpriteSheet::from_atlas` (`sprite_sheet.rs`): Build a SpriteSheet from a SpriteAtlas using atlas entry Rects as frames; names each entry as a group.

## Lua API Reference

- Binding path(s): `src/lua_api/sprite_api.rs`
- Namespace: `lurek.sprite`

### Module Functions
- `lurek.sprite.newSheet`: Creates a new sprite sheet by dividing a texture of the given pixel size into a grid of equal-sized frames.
- `lurek.sprite.newRPGMakerSheet`: Creates a sprite sheet using RPG Maker's standard character layout (4 columns × 4 rows per character block).
- `lurek.sprite.parseAtlas`: Parses a TexturePacker JSON atlas string and returns a sprite atlas object.
- `lurek.sprite.newAtlasSheet`: Creates a sprite sheet from an existing atlas, treating each atlas entry as a frame within the given sheet dimensions.
- `lurek.sprite.parseAsepriteAtlas`: Parses an Aseprite JSON atlas string and returns a sprite atlas object.

### `LSpriteAtlas` Methods
- `LSpriteAtlas:getEntry`: Looks up a named sprite region in the atlas by its original filename or tag.
- `LSpriteAtlas:getByIndex`: Returns a sprite region by its 1-based index in the atlas.
- `LSpriteAtlas:entryCount`: Returns the total number of entries (sprite regions) in the atlas.
- `LSpriteAtlas:entryNames`: Returns an array of all entry names in the atlas.
- `LSpriteAtlas:getFlipped`: Returns a copy of a named atlas entry with the specified flip flags applied.
- `LSpriteAtlas:type`: Returns the type name of this object.
- `LSpriteAtlas:typeOf`: Checks whether this object matches the given type name.

### `LSpriteSheet` Methods
- `LSpriteSheet:getFrame`: Returns the UV quad for a single frame by its 1-based index.
- `LSpriteSheet:getFrameCount`: Returns the total number of frames in this sprite sheet.
- `LSpriteSheet:getRow`: Returns all frame quads in the given row of the sprite sheet grid.
- `LSpriteSheet:getColumn`: Returns all frame quads in the given column of the sprite sheet grid.
- `LSpriteSheet:getGroupFrames`: Returns the frame quads for a named animation group.
- `LSpriteSheet:getGroupNames`: Returns an array of all named animation group names defined on this sheet.
- `LSpriteSheet:nameGroup`: Defines a named animation group as a contiguous range of frames.
- `LSpriteSheet:getFrameSize`: Returns the pixel dimensions of a single frame cell.
- `LSpriteSheet:getGridSize`: Returns the number of columns and rows in the sprite sheet grid.
- `LSpriteSheet:drawToImage`: Renders the sprite sheet grid into an LImage of the given size for debugging or previews.
- `LSpriteSheet:type`: Returns the type name of this object.
- `LSpriteSheet:typeOf`: Checks whether this object matches the given type name.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from ``Feature Systems.`` into `Platform Services`.
- `math`: Imports or references `math` from `src/math/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/sprite/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- This module has no dedicated direct `lurek.*` namespace and is usually consumed through higher integration layers.
