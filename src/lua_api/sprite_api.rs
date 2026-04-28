//! `lurek.sprite` - Sprite-sheet UV layout, named frame groups, atlas parsing,
//! and RPGMaker character-sheet helpers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Rect;
use crate::sprite::atlas::{parse_aseprite_json, parse_texturepacker_json, SpriteAtlas};
use crate::sprite::sprite_sheet::SpriteSheet;

// -------------------------------------------------------------------------------
// LuaSpriteSheet UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SpriteSheet`] frame-grid calculator.
pub struct LuaSpriteSheet {
    inner: SpriteSheet,
}

impl LuaUserData for LuaSpriteSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getFrame --
        /// Returns the quad for the 0-based frame index.
        /// @param | index | integer | Zero-based frame index.
        /// @return | table | Frame quad table.
        methods.add_method("getFrame", |lua, this, index: usize| {
            match this.inner.get_frame(index) {
                Some(r) => {
                    let t = quad_table(lua, r)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getFrameCount --
        /// Returns the total number of frames in the sheet.
        /// @return | integer | Total frame count.
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });

        // -- getRow --
        /// Returns a sequential table of quad tables for every frame in the given row.
        /// @param | row | integer | Row index.
        /// @return | table | Array of frame quad tables.
        methods.add_method("getRow", |lua, this, row: u32| {
            let frames = this.inner.get_row(row);
            frames_to_table(lua, &frames)
        });

        // -- getColumn --
        /// Returns a sequential table of quad tables for every frame in the given column.
        /// @param | col | integer | Column index.
        /// @return | table | Array of frame quad tables.
        methods.add_method("getColumn", |lua, this, col: u32| {
            let frames = this.inner.get_column(col);
            frames_to_table(lua, &frames)
        });

        // -- getGroupFrames --
        /// Returns a sequential table of quad tables for the named frame group.
        /// @param | name | string | Frame group name.
        /// @return | table | Array of frame quad tables.
        methods.add_method("getGroupFrames", |lua, this, name: String| {
            match this.inner.get_group(&name) {
                Some(frames) => {
                    let t = frames_to_table(lua, &frames)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getGroupNames --
        /// Returns a sequential table of all defined group names.
        /// @return | table | Array of group name strings.
        methods.add_method("getGroupNames", |lua, this, ()| {
            let names = this.inner.get_group_names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, n.as_str())?;
            }
            Ok(t)
        });

        // -- nameGroup --
        /// Registers a named frame group starting at `start_frame` with `count` frames.
        /// @param | name | string | Frame group name.
        /// @param | start_frame | integer | Zero-based first frame index.
        /// @param | count | integer | Number of frames in the group.
        /// @return | nil | No value is returned.
        methods.add_method_mut("nameGroup", |_, this, (name, start, count): (String, usize, usize)| {
                this.inner.name_group(name, start, count);
                Ok(())
            },
        );

        // -- getFrameSize --
        /// Returns the width and height of a single frame cell in pixels.
        /// @return | integer | Frame width in pixels.
        /// @return | integer | Frame height in pixels.
        methods.add_method("getFrameSize", |_, this, ()| {
            let (w, h) = this.inner.get_frame_size();
            Ok((w, h))
        });

        // -- getGridSize --
        /// Returns the number of columns and rows in the grid.
        /// @return | integer | Number of columns in the sprite grid.
        /// @return | integer | Number of rows in the sprite grid.
        methods.add_method("getGridSize", |_, this, ()| {
            let (cols, rows) = this.inner.get_grid_size();
            Ok((cols, rows))
        });

        // -- drawToImage --
        /// Renders the sheet grid as a debug view into a new ImageData.
        /// @param | width | integer | Output image width.
        /// @param | height | integer | Output image height.
        /// @return | ImageData | Generated debug image.
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LSpriteSheet"));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteSheet" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaSpriteAtlas UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SpriteAtlas`] named-region store.
pub struct LuaSpriteAtlas {
    inner: SpriteAtlas,
}

impl LuaUserData for LuaSpriteAtlas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getEntry --
        /// Returns the named region as a table.
        /// @param | name | string | Region name.
        /// @return | table | Region table.
        methods.add_method("getEntry", |lua, this, name: String| {
            match this.inner.get_entry(&name) {
                Some(e) => {
                    let t = lua.create_table()?;
                    t.set("name", e.name.as_str())?;
                    t.set("x", e.x)?;
                    t.set("y", e.y)?;
                    t.set("w", e.w)?;
                    t.set("h", e.h)?;
                    t.set("rotated", e.rotated)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getByIndex --
        /// Returns the region at the given 1-based insertion index.
        /// @param | index | integer | One-based region index.
        /// @return | table | Region table.
        methods.add_method("getByIndex", |lua, this, index: usize| {
            match this.inner.get_by_index(index.saturating_sub(1)) {
                Some(e) => {
                    let t = lua.create_table()?;
                    t.set("name", e.name.as_str())?;
                    t.set("x", e.x)?;
                    t.set("y", e.y)?;
                    t.set("w", e.w)?;
                    t.set("h", e.h)?;
                    t.set("rotated", e.rotated)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- entryCount --
        /// Returns the total number of named regions in the atlas.
        /// @return | integer | Total region count.
        methods.add_method("entryCount", |_, this, ()| Ok(this.inner.entry_count()));

        // -- entryNames --
        /// Returns a sequential table of all region names.
        /// @return | table | Array of region name strings.
        methods.add_method("entryNames", |lua, this, ()| {
            let names = this.inner.entry_names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, *n)?;
            }
            Ok(t)
        });

        // -- getFlipped --
        /// Returns a copy of the named region with flip flags set.
        /// @param | name | string | Region name.
        /// @param | flip_x | boolean | Whether to flip the region horizontally.
        /// @param | flip_y | boolean | Whether to flip the region vertically.
        /// @return | table | Flipped region table.
        methods.add_method("getFlipped", |lua, this, (name, flip_x, flip_y): (String, bool, bool)| match this
                .inner
                .get_entry(&name)
            {
                Some(e) => {
                    let flipped = e.get_flipped(flip_x, flip_y);
                    let t = lua.create_table()?;
                    t.set("name", flipped.name.as_str())?;
                    t.set("x", flipped.x)?;
                    t.set("y", flipped.y)?;
                    t.set("w", flipped.w)?;
                    t.set("h", flipped.h)?;
                    t.set("rotated", flipped.rotated)?;
                    t.set("flip_x", flipped.flip_x)?;
                    t.set("flip_y", flipped.flip_y)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LSpriteAtlas"));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteAtlas" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.sprite` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSheet --
    /// Creates a sprite sheet with a uniform grid of `frame_w Ă- frame_h` frames.
    /// @param | texture_width | integer | Source texture width in pixels.
    /// @param | texture_height | integer | Source texture height in pixels.
    /// @param | frame_width | integer | Frame width in pixels.
    /// @param | frame_height | integer | Frame height in pixels.
    /// @return | LSpriteSheet | New sprite sheet object.
    tbl.set("newSheet", lua.create_function(|lua, (tw, th, fw, fh): (u32, u32, u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::new(tw, th, fw, fh),
            })
        })?,
    )?;

    // -- newRPGMakerSheet --
    /// Creates an RPGMaker VX/Ace character sheet (3 cols Ă- 4 rows) with "down", "left", "right", "up" groups.
    /// @param | texture_width | integer | Source texture width in pixels.
    /// @param | texture_height | integer | Source texture height in pixels.
    /// @return | LSpriteSheet | New sprite sheet object.
    tbl.set("newRPGMakerSheet", lua.create_function(|lua, (tw, th): (u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_rpgmaker(tw, th),
            })
        })?,
    )?;

    // -- parseAtlas --
    /// Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
    /// @param | json_str | string | TexturePacker JSON string.
    /// @return | LSpriteAtlas | Parsed sprite atlas object.
    tbl.set("parseAtlas", lua.create_function(
            |lua, json_str: String| match parse_texturepacker_json(&json_str) {
                Ok(atlas) => {
                    let ud = lua.create_userdata(LuaSpriteAtlas { inner: atlas })?;
                    Ok(LuaValue::UserData(ud))
                }
                Err(e) => Err(LuaError::RuntimeError(format!("parseAtlas: {}", e))),
            },
        )?,
    )?;

    // -- newAtlasSheet --
    /// Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
    /// @param | atlas | LSpriteAtlas | Source atlas object.
    /// @param | sheet_width | integer | Virtual sheet width in pixels.
    /// @param | sheet_height | integer | Virtual sheet height in pixels.
    /// @return | LSpriteSheet | New sprite sheet object.
    tbl.set("newAtlasSheet", lua.create_function(|lua, (atlas_ud, sw, sh): (LuaAnyUserData, u32, u32)| {
            let atlas = atlas_ud.borrow::<LuaSpriteAtlas>()?;
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_atlas(&atlas.inner, sw, sh),
            })
        })?,
    )?;

    // -- parseAsepriteAtlas --
    /// Parses an Aseprite JSON export string and returns a sprite atlas.
    /// @param | json_str | string | Aseprite JSON export string.
    /// @return | LSpriteAtlas | Parsed sprite atlas object.
    tbl.set("parseAsepriteAtlas", lua.create_function(|lua, json_str: String| {
            let atlas = parse_aseprite_json(&json_str).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaSpriteAtlas { inner: atlas })
        })?,
    )?;

    lurek.set("sprite", tbl)?;
    Ok(())
}

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

// Converts a `Rect` to a Lua table `{x, y, w, h}`.
fn quad_table(lua: &Lua, r: Rect) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    t.set("x", r.x)?;
    t.set("y", r.y)?;
    t.set("w", r.width)?;
    t.set("h", r.height)?;
    Ok(t)
}

// Converts a slice of `Rect` values to a 1-indexed Lua table of quad tables.
fn frames_to_table<'lua>(lua: &'lua Lua, frames: &[Rect]) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, r) in frames.iter().enumerate() {
        t.set(i + 1, quad_table(lua, *r)?)?;
    }
    Ok(t)
}
