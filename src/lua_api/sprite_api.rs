use super::SharedState;
use crate::math::Rect;
use crate::sprite::atlas::{parse_aseprite_json, parse_texturepacker_json, SpriteAtlas};
use crate::sprite::sprite_sheet::SpriteSheet;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
pub struct LuaSpriteSheet {
    inner: SpriteSheet,
}
impl LuaUserData for LuaSpriteSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getFrame", |lua, this, index: usize| {
            match this.inner.get_frame(index) {
                Some(r) => {
                    let t = quad_table(lua, r)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });
        methods.add_method("getRow", |lua, this, row: u32| {
            let frames = this.inner.get_row(row);
            frames_to_table(lua, &frames)
        });
        methods.add_method("getColumn", |lua, this, col: u32| {
            let frames = this.inner.get_column(col);
            frames_to_table(lua, &frames)
        });
        methods.add_method("getGroupFrames", |lua, this, name: String| {
            match this.inner.get_group(&name) {
                Some(frames) => {
                    let t = frames_to_table(lua, &frames)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getGroupNames", |lua, this, ()| {
            let names = this.inner.get_group_names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, n.as_str())?;
            }
            Ok(t)
        });
        methods.add_method_mut(
            "nameGroup",
            |_, this, (name, start, count): (String, usize, usize)| {
                this.inner.name_group(name, start, count);
                Ok(())
            },
        );
        methods.add_method("getFrameSize", |_, this, ()| {
            let (w, h) = this.inner.get_frame_size();
            Ok((w, h))
        });
        methods.add_method("getGridSize", |_, this, ()| {
            let (cols, rows) = this.inner.get_grid_size();
            Ok((cols, rows))
        });
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });
        methods.add_method("type", |_, _, ()| Ok("LSpriteSheet"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteSheet" || name == "Object")
        });
    }
}
pub struct LuaSpriteAtlas {
    inner: SpriteAtlas,
}
impl LuaUserData for LuaSpriteAtlas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("entryCount", |_, this, ()| Ok(this.inner.entry_count()));
        methods.add_method("entryNames", |lua, this, ()| {
            let names = this.inner.entry_names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, *n)?;
            }
            Ok(t)
        });
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
        methods.add_method("type", |_, _, ()| Ok("LSpriteAtlas"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteAtlas" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newSheet",
        lua.create_function(|lua, (tw, th, fw, fh): (u32, u32, u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::new(tw, th, fw, fh),
            })
        })?,
    )?;
    tbl.set(
        "newRPGMakerSheet",
        lua.create_function(|lua, (tw, th): (u32, u32)| {
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_rpgmaker(tw, th),
            })
        })?,
    )?;
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
    tbl.set(
        "newAtlasSheet",
        lua.create_function(|lua, (atlas_ud, sw, sh): (LuaAnyUserData, u32, u32)| {
            let atlas = atlas_ud.borrow::<LuaSpriteAtlas>()?;
            lua.create_userdata(LuaSpriteSheet {
                inner: SpriteSheet::from_atlas(&atlas.inner, sw, sh),
            })
        })?,
    )?;
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
fn quad_table(lua: &Lua, r: Rect) -> LuaResult<LuaTable<'_>> {
    let t = lua.create_table()?;
    t.set("x", r.x)?;
    t.set("y", r.y)?;
    t.set("w", r.width)?;
    t.set("h", r.height)?;
    Ok(t)
}
fn frames_to_table<'lua>(lua: &'lua Lua, frames: &[Rect]) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, r) in frames.iter().enumerate() {
        t.set(i + 1, quad_table(lua, *r)?)?;
    }
    Ok(t)
}
