//! `lurek.sprite` â€” Sprite-sheet UV layout, named frame groups, atlas parsing,
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
        /// Returns the quad for the 0-based frame index, or nil if out of range.
        /// @param index integer
        /// @return table?
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
        /// @return integer
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });

        // -- getRow --
        /// Returns a sequential table of quad tables for every frame in the given row.
        /// @param row integer
        /// @return table
        methods.add_method("getRow", |lua, this, row: u32| {
            let frames = this.inner.get_row(row);
            frames_to_table(lua, &frames)
        });

        // -- getColumn --
        /// Returns a sequential table of quad tables for every frame in the given column.
        /// @param col integer
        /// @return table
        methods.add_method("getColumn", |lua, this, col: u32| {
            let frames = this.inner.get_column(col);
            frames_to_table(lua, &frames)
        });

        // -- getGroupFrames --
        /// Returns a sequential table of quad tables for the named frame group, or nil.
        /// @param name string
        /// @return table?
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
        /// @return table
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
        /// @param name string
        /// @param start_frame integer
        /// @param count integer
        /// @return nil
        methods.add_method_mut(
            "nameGroup",
            |_, this, (name, start, count): (String, usize, usize)| {
                this.inner.name_group(name, start, count);
                Ok(())
            },
        );

        // -- getFrameSize --
        /// Returns the width and height of a single frame cell in pixels.
        /// @return integer, integer
        methods.add_method("getFrameSize", |_, this, ()| {
            let (w, h) = this.inner.get_frame_size();
            Ok((w, h))
        });

        // -- getGridSize --
        /// Returns the number of columns and rows in the grid.
        /// @return integer, integer
        methods.add_method("getGridSize", |_, this, ()| {
            let (cols, rows) = this.inner.get_grid_size();
            Ok((cols, rows))
        });

        // -- drawToImage --
        /// Renders the sheet grid as a debug view into a new ImageData.
        /// Frame borders are red; first frames of named groups are green.
        /// @param width integer
        /// @param height integer
        /// @return ImageData
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LSpriteSheet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
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
        /// Returns the named region as a table `{name, x, y, w, h, rotated}`, or nil.
        /// @param name string
        /// @return table?
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
        /// Returns the region at the given 1-based insertion index, or nil.
        /// @param index integer
        /// @return table?
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
        /// @return integer
        methods.add_method("entryCount", |_, this, ()| Ok(this.inner.entry_count()));

        // -- entryNames --
        /// Returns a sequential table of all region names.
        /// @return table
        methods.add_method("entryNames", |lua, this, ()| {
            let names = this.inner.entry_names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, *n)?;
            }
            Ok(t)
        });

        // -- getFlipped --
        /// Returns a copy of the named region with `flip_x` and `flip_y` flags set.
        /// Returns nil if the region name is not found.
        /// @param name string
        /// @param flip_x boolean
        /// @param flip_y boolean
        /// @return table?
        methods.add_method(
            "getFlipped",
            |lua, this, (name, flip_x, flip_y): (String, bool, bool)| match this
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
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LSpriteAtlas"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteAtlas" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.sprite.*` Lua namespace.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
/// Factory functions:
/// - `lurek.sprite.newSheet(tw, th, fw, fh)` â†’ SpriteSheet
/// - `lurek.sprite.newRPGMakerSheet(tw, th)` â†’ SpriteSheet
/// - `lurek.sprite.parseAtlas(json_str)` â†’ SpriteAtlas
/// - `lurek.sprite.newAtlasSheet(atlas, sheet_w, sheet_h)` â†’ SpriteSheet
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // â”€â”€ newSheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a sprite sheet with a uniform grid of `frame_w Ă— frame_h` frames.
    /// @param texture_width integer
    /// @param texture_height integer
    /// @param frame_width integer
    /// @param frame_height integer
    /// @return SpriteSheet
    tbl.set(
        "newSheet",
        lua.create_function(|lua, (tw, th, fw, fh): (u32, u32, u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::new(tw, th, fw, fh),
            })
        })?,
    )?;

    // â”€â”€ newRPGMakerSheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates an RPGMaker VX/Ace character sheet (3 cols Ă— 4 rows) with "down", "left", "right", "up" groups.
    /// @param texture_width integer
    /// @param texture_height integer
    /// @return SpriteSheet
    tbl.set(
        "newRPGMakerSheet",
        lua.create_function(|lua, (tw, th): (u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_rpgmaker(tw, th),
            })
        })?,
    )?;

    // â”€â”€ parseAtlas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Parses a TexturePacker JSON string (hash or array format) and returns a SpriteAtlas.
    /// @param json_str string
    /// @return SpriteAtlas
    tbl.set(
        "parseAtlas",
        lua.create_function(
            |lua, json_str: String| match parse_texturepacker_json(&json_str) {
                Ok(atlas) => {
                    let ud = lua.create_userdata(LuaSpriteAtlas { inner: atlas })?;
                    Ok(LuaValue::UserData(ud))
                }
                Err(e) => Err(LuaError::RuntimeError(format!("parseAtlas: {}", e))),
            },
        )?,
    )?;

    // â”€â”€ newAtlasSheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Builds a SpriteSheet whose frames come from named entries in a SpriteAtlas.
    /// Each atlas region becomes a frame; regions are also registered as single-frame named groups.
    /// @param atlas SpriteAtlas
    /// @param sheet_width integer
    /// @param sheet_height integer
    /// @return SpriteSheet
    tbl.set(
        "newAtlasSheet",
        lua.create_function(|lua, (atlas_ud, sw, sh): (LuaAnyUserData, u32, u32)| {
            let atlas = atlas_ud.borrow::<LuaSpriteAtlas>()?;
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_atlas(&atlas.inner, sw, sh),
            })
        })?,
    )?;

    // â”€â”€ parseAsepriteAtlas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Parses an Aseprite JSON export string and returns a `SpriteAtlas`.
    /// Supports both array and hash Aseprite export formats.
    /// @param json_str string
    /// @return SpriteAtlas
    tbl.set(
        "parseAsepriteAtlas",
        lua.create_function(|lua, json_str: String| {
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

/// Converts a `Rect` to a Lua table `{x, y, w, h}`.
fn quad_table(lua: &Lua, r: Rect) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    t.set("x", r.x)?;
    t.set("y", r.y)?;
    t.set("w", r.width)?;
    t.set("h", r.height)?;
    Ok(t)
}

/// Converts a slice of `Rect` values to a 1-indexed Lua table of quad tables.
fn frames_to_table<'lua>(lua: &'lua Lua, frames: &[Rect]) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, r) in frames.iter().enumerate() {
        t.set(i + 1, quad_table(lua, *r)?)?;
    }
    Ok(t)
}
