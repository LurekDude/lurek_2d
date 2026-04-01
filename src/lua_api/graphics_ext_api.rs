//! Lua API bindings for Phase 24 graphics extension types.
//!
//! Provides UserData wrappers and factory functions for extended graphics
//! subsystems: Light2D, TextureAtlas, DrawLayer, Viewport, ViewportScale,
//! SpriteSheet, PolygonMap, GraphRenderer, LargeMapRenderer, ColumnBatch,
//! Camera2D, Animation, Trail, DecalSurface, and PaletteLUT.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::graphics::animation::Animation;
use crate::graphics::camera::Camera2D;
use crate::graphics::column_batch::ColumnBatch;
use crate::graphics::decal_surface::DecalSurface;
use crate::graphics::data_graph_renderer::GraphRenderer;
use crate::graphics::large_map_renderer::LargeMapRenderer;
use crate::graphics::light2d::Light2D;
use crate::graphics::palette_lut::PaletteLUT;
use crate::graphics::polygon_map::PolygonMap;
use crate::graphics::sprite_sheet::{DirectionLayout, SpriteSheet};
use crate::graphics::texture_atlas::TextureAtlas;
use crate::graphics::trail::Trail;
use crate::graphics::viewport::{ScaleMode, Viewport};
use crate::graphics::viewport_scale::ViewportScale;
use crate::graphics::Color;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::math::Rect;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn parse_color(r: f32, g: f32, b: f32, a: Option<f32>) -> Color {
    Color {
        r,
        g,
        b,
        a: a.unwrap_or(1.0),
    }
}

fn rect_to_table<'a>(lua: &'a Lua, r: &Rect) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    /// X on this Object.
    ///
    /// # Returns
    /// The result.
    t.set("x", r.x)?;
    /// Y on this Object.
    ///
    /// # Returns
    /// The result.
    t.set("y", r.y)?;
    /// Width on this Object.
    ///
    /// # Returns
    /// The result.
    t.set("width", r.width)?;
    /// Height on this Object.
    ///
    /// # Returns
    /// The result.
    t.set("height", r.height)?;
    Ok(t)
}

fn parse_scale_mode(s: &str) -> ScaleMode {
    match s {
        "stretch" => ScaleMode::Stretch,
        "pixel-perfect" => ScaleMode::PixelPerfect,
        _ => ScaleMode::Letterbox,
    }
}

fn scale_mode_to_str(mode: &ScaleMode) -> &'static str {
    match mode {
        ScaleMode::Letterbox => "letterbox",
        ScaleMode::Stretch => "stretch",
        ScaleMode::PixelPerfect => "pixel-perfect",
    }
}

// ---------------------------------------------------------------------------
// 1. LuaLight2D
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for Light2D.
#[derive(Clone)]
struct LuaLight2D {
    inner: Rc<RefCell<Light2D>>,
}

impl LunaType for LuaLight2D {
    const TYPE_NAME: &'static str = "Light2D";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaLight2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Sets the position.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });
        /// Returns the position.
        ///
        /// # Parameters
        /// - `r` — `number`.
        ///
        /// # Returns
        /// The current position.
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });
        /// Sets the radius.
        ///
        /// # Parameters
        /// - `r` — `number`.
        methods.add_method("setRadius", |_, this, r: f32| {
            this.inner.borrow_mut().set_radius(r);
            Ok(())
        });
        /// Returns the radius.
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        ///
        /// # Returns
        /// The current radius.
        methods.add_method("getRadius", |_, this, ()| {
            Ok(this.inner.borrow().get_radius())
        });
        methods.add_method(
            "setColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.borrow_mut().set_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        /// Returns the color.
        ///
        /// # Parameters
        /// - `i` — `number`.
        ///
        /// # Returns
        /// The current color.
        methods.add_method("getColor", |_, this, ()| {
            let c = this.inner.borrow().get_color();
            Ok((c.r, c.g, c.b, c.a))
        });
        /// Sets the intensity.
        ///
        /// # Parameters
        /// - `i` — `number`.
        methods.add_method("setIntensity", |_, this, i: f32| {
            this.inner.borrow_mut().set_intensity(i);
            Ok(())
        });
        /// Returns the intensity.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        ///
        /// # Returns
        /// The current intensity.
        methods.add_method("getIntensity", |_, this, ()| {
            Ok(this.inner.borrow().get_intensity())
        });
        /// Sets the enabled.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        methods.add_method("setEnabled", |_, this, b: bool| {
            this.inner.borrow_mut().set_enabled(b);
            Ok(())
        });
        /// Returns `true` if enabled.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_enabled())
        });
    }
}

// ---------------------------------------------------------------------------
// 2. LuaTextureAtlas
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for TextureAtlas.
#[derive(Clone)]
struct LuaTextureAtlas {
    inner: Rc<RefCell<TextureAtlas>>,
}

impl LunaType for LuaTextureAtlas {
    const TYPE_NAME: &'static str = "TextureAtlas";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaTextureAtlas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Pack on this TextureAtlas.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method("pack", |_, this, (name, w, h): (String, u32, u32)| {
            Ok(this.inner.borrow_mut().pack(&name, w, h))
        });
        /// Returns the region.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current region.
        methods.add_method("getRegion", |_lua, this, name: String| {
            let atlas = this.inner.borrow();
            match atlas.get_region(&name) {
                Some(r) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Integer(r.x as i64),
                    LuaValue::Integer(r.y as i64),
                    LuaValue::Integer(r.w as i64),
                    LuaValue::Integer(r.h as i64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Returns the region count.
        ///
        /// # Returns
        /// The current region count.
        methods.add_method("getRegionCount", |_, this, ()| {
            Ok(this.inner.borrow().get_region_count())
        });
        /// Returns the dimensions.
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });
        /// Returns the regions.
        ///
        /// # Returns
        /// The current regions.
        methods.add_method("getRegions", |lua, this, ()| {
            let atlas = this.inner.borrow();
            let regions = atlas.get_regions();
            let tbl = lua.create_table()?;
            for (i, r) in regions.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Name on this TextureAtlas.
                ///
                /// # Returns
                /// The result.
                entry.set("name", r.name.clone())?;
                /// X on this TextureAtlas.
                ///
                /// # Returns
                /// The result.
                entry.set("x", r.x)?;
                /// Y on this TextureAtlas.
                ///
                /// # Returns
                /// The result.
                entry.set("y", r.y)?;
                /// W on this TextureAtlas.
                ///
                /// # Returns
                /// The result.
                entry.set("w", r.w)?;
                /// H on this TextureAtlas.
                ///
                /// # Returns
                /// The result.
                entry.set("h", r.h)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// 3. LuaDrawLayer
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for DrawLayer.
///
/// Stores Lua function callbacks alongside z-order values.
struct LuaDrawLayer {
    entries: RefCell<Vec<(f64, LuaRegistryKey)>>,
}

impl LunaType for LuaDrawLayer {
    const TYPE_NAME: &'static str = "DrawLayer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaDrawLayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Queue on this DrawLayer.
        ///
        /// # Parameters
        /// - `z` — `number`.
        /// - `func` — `function`.
        methods.add_method("queue", |lua, this, (z, func): (f64, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            this.entries.borrow_mut().push((z, key));
            Ok(())
        });
        /// Flushes pending data.
        ///
        /// # Returns
        /// The result.
        methods.add_method("flush", |lua, this, ()| {
            let mut entries = this.entries.borrow_mut();
            entries.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
            for (_, key) in entries.drain(..) {
                let func: LuaFunction = lua.registry_value(&key)?;
                func.call::<_, ()>(())?;
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |lua, this, ()| {
            let mut entries = this.entries.borrow_mut();
            for (_, key) in entries.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        /// Returns the count.
        ///
        /// # Returns
        /// The current count.
        methods.add_method("getCount", |_, this, ()| Ok(this.entries.borrow().len()));
    }
}

// ---------------------------------------------------------------------------
// 4. LuaViewport
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for Viewport.
#[derive(Clone)]
struct LuaViewport {
    inner: Rc<RefCell<Viewport>>,
}

impl LunaType for LuaViewport {
    const TYPE_NAME: &'static str = "Viewport";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaViewport {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Resize on this Viewport.
        ///
        /// # Parameters
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("resize", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });
        /// Returns the scale.
        ///
        /// # Returns
        /// The current scale.
        methods.add_method("getScale", |_, this, ()| {
            Ok(this.inner.borrow().get_scale())
        });
        /// Returns the offset.
        ///
        /// # Returns
        /// The current offset.
        methods.add_method("getOffset", |_, this, ()| {
            Ok(this.inner.borrow().get_offset())
        });
        /// Returns the game dimensions.
        ///
        /// # Parameters
        /// - `mode` — `string`.
        ///
        /// # Returns
        /// The current game dimensions.
        methods.add_method("getGameDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_game_dimensions())
        });
        /// Returns the scale mode.
        ///
        /// # Parameters
        /// - `mode` — `string`.
        ///
        /// # Returns
        /// The current scale mode.
        methods.add_method("getScaleMode", |_, this, ()| {
            Ok(scale_mode_to_str(this.inner.borrow().get_scale_mode()).to_string())
        });
        /// Sets the scale mode.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        methods.add_method("setScaleMode", |_, this, mode: String| {
            this.inner
                .borrow_mut()
                .set_scale_mode(parse_scale_mode(&mode));
            Ok(())
        });
        /// To game on this Viewport.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        methods.add_method("toGame", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_game(sx, sy))
        });
        /// To screen on this Viewport.
        ///
        /// # Parameters
        /// - `gx` — `number`.
        /// - `gy` — `number`.
        methods.add_method("toScreen", |_, this, (gx, gy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen(gx, gy))
        });
    }
}

// ---------------------------------------------------------------------------
// 5. LuaViewportScale
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for ViewportScale.
#[derive(Clone)]
struct LuaViewportScale {
    inner: Rc<RefCell<ViewportScale>>,
}

impl LunaType for LuaViewportScale {
    const TYPE_NAME: &'static str = "ViewportScale";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaViewportScale {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Resize on this ViewportScale.
        ///
        /// # Parameters
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("resize", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });
        /// Returns the game dimensions.
        ///
        /// # Returns
        /// The current game dimensions.
        methods.add_method("getGameDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_game_dimensions())
        });
        /// Returns the scaled dimensions.
        ///
        /// # Returns
        /// The current scaled dimensions.
        methods.add_method("getScaledDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_scaled_dimensions())
        });
        /// Returns the offset.
        ///
        /// # Returns
        /// The current offset.
        methods.add_method("getOffset", |_, this, ()| {
            Ok(this.inner.borrow().get_offset())
        });
        /// Returns the scale.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        ///
        /// # Returns
        /// The current scale.
        methods.add_method("getScale", |_, this, ()| {
            Ok(this.inner.borrow().get_scale())
        });
        /// Returns the mode.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        ///
        /// # Returns
        /// The current mode.
        methods.add_method("getMode", |_, this, ()| {
            Ok(scale_mode_to_str(this.inner.borrow().get_mode()).to_string())
        });
        /// To game coords on this ViewportScale.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        methods.add_method("toGameCoords", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_game_coords(sx, sy))
        });
        /// To screen coords on this ViewportScale.
        ///
        /// # Parameters
        /// - `gx` — `number`.
        /// - `gy` — `number`.
        methods.add_method("toScreenCoords", |_, this, (gx, gy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(gx, gy))
        });
    }
}

// ---------------------------------------------------------------------------
// 6. LuaSpriteSheet
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for SpriteSheet.
#[derive(Clone)]
struct LuaSpriteSheet {
    inner: Rc<RefCell<SpriteSheet>>,
}

impl LunaType for LuaSpriteSheet {
    const TYPE_NAME: &'static str = "SpriteSheet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

fn rects_to_table<'a>(lua: &'a Lua, rects: &[Rect]) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    for (i, r) in rects.iter().enumerate() {
        tbl.set(i + 1, rect_to_table(lua, r)?)?;
    }
    Ok(tbl)
}

impl LuaUserData for LuaSpriteSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // getFrame(index) — 1-based
        /// Returns the frame.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current frame.
        methods.add_method("getFrame", |lua, this, index: usize| {
            let sheet = this.inner.borrow();
            match sheet.get_frame(index.saturating_sub(1)) {
                Some(r) => Ok(LuaValue::Table(rect_to_table(lua, &r)?)),
                None => Ok(LuaValue::Nil),
            }
        });
        /// Returns the frame count.
        ///
        /// # Returns
        /// The current frame count.
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.borrow().get_frame_count())
        });
        /// Returns the frame size.
        ///
        /// # Parameters
        /// - `row` — `integer`.
        ///
        /// # Returns
        /// The current frame size.
        methods.add_method("getFrameSize", |_, this, ()| {
            Ok(this.inner.borrow().get_frame_size())
        });
        /// Returns the grid size.
        ///
        /// # Parameters
        /// - `row` — `integer`.
        ///
        /// # Returns
        /// The current grid size.
        methods.add_method("getGridSize", |_, this, ()| {
            Ok(this.inner.borrow().get_grid_size())
        });
        // getRow(row) — 1-based
        /// Returns the row.
        ///
        /// # Parameters
        /// - `row` — `integer`.
        ///
        /// # Returns
        /// The current row.
        methods.add_method("getRow", |lua, this, row: u32| {
            let rects = this.inner.borrow().get_row(row.saturating_sub(1));
            rects_to_table(lua, &rects)
        });
        // getColumn(col) — 1-based
        /// Returns the column.
        ///
        /// # Parameters
        /// - `start` — `integer`.
        /// - `count` — `integer`.
        ///
        /// # Returns
        /// The current column.
        methods.add_method("getColumn", |lua, this, col: u32| {
            let rects = this.inner.borrow().get_column(col.saturating_sub(1));
            rects_to_table(lua, &rects)
        });
        // getRange(start, count) — 1-based start
        /// Returns the range.
        ///
        /// # Parameters
        /// - `start` — `integer`.
        /// - `count` — `integer`.
        ///
        /// # Returns
        /// The current range.
        methods.add_method("getRange", |lua, this, (start, count): (usize, usize)| {
            let rects = this
                .inner
                .borrow()
                .get_range(start.saturating_sub(1), count);
            rects_to_table(lua, &rects)
        });
        // nameGroup(name, startFrame, count) — 1-based startFrame
        methods.add_method(
            "nameGroup",
            |_, this, (name, start, count): (String, usize, usize)| {
                this.inner
                    .borrow_mut()
                    .name_group(name, start.saturating_sub(1), count);
                Ok(())
            },
        );
        /// Returns the group.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current group.
        methods.add_method("getGroup", |lua, this, name: String| {
            let sheet = this.inner.borrow();
            match sheet.get_group(&name) {
                Some(rects) => Ok(LuaValue::Table(rects_to_table(lua, &rects)?)),
                None => Ok(LuaValue::Nil),
            }
        });
        /// Returns the group names.
        ///
        /// # Returns
        /// The current group names.
        methods.add_method("getGroupNames", |lua, this, ()| {
            let names = this.inner.borrow().get_group_names();
            let tbl = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                tbl.set(i + 1, n.clone())?;
            }
            Ok(tbl)
        });
        // setDirections(count, layout?)
        methods.add_method(
            "setDirections",
            |_, this, (count, layout): (u32, Option<String>)| {
                let dl = match layout.as_deref() {
                    Some("columns") => DirectionLayout::Columns,
                    _ => DirectionLayout::Rows,
                };
                this.inner.borrow_mut().set_directions(count, dl);
                Ok(())
            },
        );
        // getDirectionFrames(direction) — 1-based
        /// Returns the direction frames.
        ///
        /// # Parameters
        /// - `direction` — `integer`.
        ///
        /// # Returns
        /// The current direction frames.
        methods.add_method("getDirectionFrames", |lua, this, direction: u32| {
            let sheet = this.inner.borrow();
            match sheet.get_direction_frames(direction.saturating_sub(1)) {
                Some(rects) => Ok(LuaValue::Table(rects_to_table(lua, &rects)?)),
                None => Ok(LuaValue::Nil),
            }
        });
    }
}

// ---------------------------------------------------------------------------
// 7. LuaPolygonMap
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for PolygonMap.
#[derive(Clone)]
struct LuaPolygonMap {
    inner: Rc<RefCell<PolygonMap>>,
}

impl LunaType for LuaPolygonMap {
    const TYPE_NAME: &'static str = "PolygonMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaPolygonMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // addRegion(name, vertices, color?)
        methods.add_method(
            "addRegion",
            |_, this, (name, verts, color): (String, LuaTable, Option<LuaTable>)| {
                let vertices: Vec<f32> = verts
                    .sequence_values::<f32>()
                    .collect::<LuaResult<Vec<_>>>()?;
                let c = if let Some(ct) = color {
                    Color {
                        r: ct.get::<_, f32>(1).unwrap_or(1.0),
                        g: ct.get::<_, f32>(2).unwrap_or(1.0),
                        b: ct.get::<_, f32>(3).unwrap_or(1.0),
                        a: ct.get::<_, f32>(4).unwrap_or(1.0),
                    }
                } else {
                    Color {
                        r: 1.0,
                        g: 1.0,
                        b: 1.0,
                        a: 1.0,
                    }
                };
                this.inner.borrow_mut().add_region(name, vertices, c);
                Ok(())
            },
        );
        /// Removes region from the collection.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        methods.add_method("removeRegion", |_, this, name: String| {
            this.inner.borrow_mut().remove_region(&name);
            Ok(())
        });
        methods.add_method(
            "setRegionColor",
            |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_region_color(&name, parse_color(r, g, b, a));
                Ok(())
            },
        );
        /// Returns the region color.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current region color.
        methods.add_method("getRegionColor", |_, this, name: String| {
            match this.inner.borrow().get_region_color(&name) {
                Some(c) => Ok((c.r, c.g, c.b, c.a)),
                None => Ok((0.0, 0.0, 0.0, 0.0)),
            }
        });
        methods.add_method(
            "setRegionLabel",
            |_, this, (name, text, size): (String, String, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_region_label(&name, text, size.unwrap_or(14.0));
                Ok(())
            },
        );
        /// Returns the region at.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        ///
        /// # Returns
        /// The current region at.
        methods.add_method("getRegionAt", |_, this, (x, y): (f32, f32)| {
            Ok(this
                .inner
                .borrow()
                .get_region_at(x, y)
                .map(|s| s.to_string()))
        });
        /// Returns the region names.
        ///
        /// # Returns
        /// The current region names.
        methods.add_method("getRegionNames", |lua, this, ()| {
            let names = this.inner.borrow().get_region_names();
            let tbl = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                tbl.set(i + 1, n.clone())?;
            }
            Ok(tbl)
        });
        /// Returns the region vertices.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current region vertices.
        methods.add_method("getRegionVertices", |lua, this, name: String| {
            let pm = this.inner.borrow();
            match pm.get_region_vertices(&name) {
                Some(verts) => {
                    let tbl = lua.create_table()?;
                    for (i, v) in verts.iter().enumerate() {
                        tbl.set(i + 1, *v)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        /// Returns the region center.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current region center.
        methods.add_method("getRegionCenter", |_, this, name: String| {
            match this.inner.borrow().get_region_center(&name) {
                Some((x, y)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x as f64),
                    LuaValue::Number(y as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Returns the bounding box.
        ///
        /// # Returns
        /// The current bounding box.
        methods.add_method("getBoundingBox", |_, this, ()| {
            match this.inner.borrow().get_bounding_box() {
                Some((x, y, w, h)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x as f64),
                    LuaValue::Number(y as f64),
                    LuaValue::Number(w as f64),
                    LuaValue::Number(h as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        methods.add_method(
            "setOutlineColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_outline_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        /// Sets the outline width.
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        methods.add_method("setOutlineWidth", |_, this, w: f32| {
            this.inner.borrow_mut().set_outline_width(w);
            Ok(())
        });
        methods.add_method(
            "setHighlightColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_highlight_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        /// Highlight on this PolygonMap.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("highlight", |_, this, name: String| {
            this.inner.borrow_mut().highlight(name);
            Ok(())
        });
        /// Clear highlight on this PolygonMap.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearHighlight", |_, this, ()| {
            this.inner.borrow_mut().clear_highlight();
            Ok(())
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// 8. LuaGraphRenderer
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for GraphRenderer.
#[derive(Clone)]
struct LuaGraphRenderer {
    inner: Rc<RefCell<GraphRenderer>>,
}

impl LunaType for LuaGraphRenderer {
    const TYPE_NAME: &'static str = "GraphRenderer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaGraphRenderer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        /// Returns the viewport.
        ///
        /// # Parameters
        /// - `xmin` — `number`.
        /// - `xmax` — `number`.
        /// - `ymin` — `number`.
        /// - `ymax` — `number`.
        ///
        /// # Returns
        /// The current viewport.
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });
        methods.add_method(
            "setRange",
            |_, this, (xmin, xmax, ymin, ymax): (f64, f64, f64, f64)| {
                this.inner.borrow_mut().set_range(xmin, xmax, ymin, ymax);
                Ok(())
            },
        );
        /// Returns the range.
        ///
        /// # Returns
        /// The current range.
        methods.add_method("getRange", |_, this, ()| {
            Ok(this.inner.borrow().get_range())
        });
        /// Auto range on this GraphRenderer.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `pts` — `table`.
        /// - `color` — `table` optional.
        methods.add_method("autoRange", |_, this, ()| {
            this.inner.borrow_mut().auto_range();
            Ok(())
        });
        // addLineSeries(name, points, color?)
        methods.add_method(
            "addLineSeries",
            |_, this, (name, pts, color): (String, LuaTable, Option<LuaTable>)| {
                let points: Vec<(f64, f64)> = pts
                    .sequence_values::<LuaTable>()
                    .map(|r| {
                        let t = r?;
                        let x: f64 = t.get("x").or_else(|_| t.get(1))?;
                        let y: f64 = t.get("y").or_else(|_| t.get(2))?;
                        Ok((x, y))
                    })
                    .collect::<LuaResult<Vec<_>>>()?;
                let c = table_to_color(color);
                this.inner.borrow_mut().add_line_series(&name, points, c);
                Ok(())
            },
        );
        // addScatterSeries(name, points, color?, size?)
        methods.add_method(
            "addScatterSeries",
            |_,
             this,
             (name, pts, color, size): (String, LuaTable, Option<LuaTable>, Option<f32>)| {
                let points: Vec<(f64, f64)> = pts
                    .sequence_values::<LuaTable>()
                    .map(|r| {
                        let t = r?;
                        let x: f64 = t.get("x").or_else(|_| t.get(1))?;
                        let y: f64 = t.get("y").or_else(|_| t.get(2))?;
                        Ok((x, y))
                    })
                    .collect::<LuaResult<Vec<_>>>()?;
                let c = table_to_color(color);
                this.inner
                    .borrow_mut()
                    .add_scatter_series(&name, points, c, size.unwrap_or(4.0));
                Ok(())
            },
        );
        // addBarSeries(name, values, color?)
        methods.add_method(
            "addBarSeries",
            |_, this, (name, vals, color): (String, LuaTable, Option<LuaTable>)| {
                let values: Vec<f64> = vals
                    .sequence_values::<f64>()
                    .collect::<LuaResult<Vec<_>>>()?;
                let c = table_to_color(color);
                this.inner.borrow_mut().add_bar_series(&name, values, c);
                Ok(())
            },
        );
        /// Removes series from the collection.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeSeries", |_, this, name: String| {
            this.inner.borrow_mut().remove_series(&name);
            Ok(())
        });
        /// Clear series on this GraphRenderer.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        methods.add_method("clearSeries", |_, this, ()| {
            this.inner.borrow_mut().clear_series();
            Ok(())
        });
        /// Sets the show grid.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        methods.add_method("setShowGrid", |_, this, b: bool| {
            this.inner.borrow_mut().set_show_grid(b);
            Ok(())
        });
        /// Sets the show axes.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        methods.add_method("setShowAxes", |_, this, b: bool| {
            this.inner.borrow_mut().set_show_axes(b);
            Ok(())
        });
        /// Sets the show labels.
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        methods.add_method("setShowLabels", |_, this, b: bool| {
            this.inner.borrow_mut().set_show_labels(b);
            Ok(())
        });
        methods.add_method(
            "setGridColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_grid_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        methods.add_method(
            "setAxisColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_axis_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        methods.add_method(
            "setBackgroundColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_bg_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        /// Sets the title.
        ///
        /// # Parameters
        /// - `x_label` — `string`.
        /// - `y_label` — `string`.
        methods.add_method("setTitle", |_, this, text: String| {
            this.inner.borrow_mut().set_title(&text);
            Ok(())
        });
        methods.add_method(
            "setAxisLabels",
            |_, this, (x_label, y_label): (String, String)| {
                this.inner.borrow_mut().set_axis_labels(&x_label, &y_label);
                Ok(())
            },
        );
        /// Sets the cursor position.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("setCursorPosition", |_, this, (x, y): (f64, f64)| {
            this.inner.borrow_mut().set_cursor_position(x, y);
            Ok(())
        });
        /// Returns the cursor value.
        ///
        /// # Returns
        /// The current cursor value.
        methods.add_method("getCursorValue", |_, this, ()| {
            match this.inner.borrow().get_cursor_value() {
                Some((x, y)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x),
                    LuaValue::Number(y),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
    }
}

fn table_to_color(tbl: Option<LuaTable>) -> Color {
    match tbl {
        Some(t) => Color {
            r: t.get::<_, f32>(1).unwrap_or(1.0),
            g: t.get::<_, f32>(2).unwrap_or(1.0),
            b: t.get::<_, f32>(3).unwrap_or(1.0),
            a: t.get::<_, f32>(4).unwrap_or(1.0),
        },
        None => Color {
            r: 1.0,
            g: 1.0,
            b: 1.0,
            a: 1.0,
        },
    }
}

// ---------------------------------------------------------------------------
// 9. LuaLargeMapRenderer
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for LargeMapRenderer.
#[derive(Clone)]
struct LuaLargeMapRenderer {
    inner: Rc<RefCell<LargeMapRenderer>>,
}

impl LunaType for LuaLargeMapRenderer {
    const TYPE_NAME: &'static str = "LargeMapRenderer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaLargeMapRenderer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // setMapData(data, width, height) — data: flat table of 1-based tile IDs
        methods.add_method(
            "setMapData",
            |_, this, (data, w, h): (LuaTable, u32, u32)| {
                let tiles: Vec<u32> = data
                    .sequence_values::<u32>()
                    .collect::<LuaResult<Vec<_>>>()?;
                this.inner.borrow_mut().set_map_data(tiles, w, h);
                Ok(())
            },
        );
        // setTile(x, y, tileId) — 1-based coords and tileId
        /// Sets the tile.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `tile_id` — `integer`.
        methods.add_method("setTile", |_, this, (x, y, tile_id): (u32, u32, u32)| {
            this.inner
                .borrow_mut()
                .set_tile(x.saturating_sub(1), y.saturating_sub(1), tile_id);
            Ok(())
        });
        // getTile(x, y) — 1-based coords, returns 1-based tileId
        /// Returns the tile.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current tile.
        methods.add_method("getTile", |_, this, (x, y): (u32, u32)| {
            match this
                .inner
                .borrow()
                .get_tile(x.saturating_sub(1), y.saturating_sub(1))
            {
                Some(id) => Ok(LuaValue::Integer(id as i64)),
                None => Ok(LuaValue::Integer(0)),
            }
        });
        /// Returns the map size.
        ///
        /// # Parameters
        /// - `s` — `integer`.
        ///
        /// # Returns
        /// The current map size.
        methods.add_method("getMapSize", |_, this, ()| {
            Ok(this.inner.borrow().get_map_size())
        });
        /// Sets the chunk size.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `zoom` — `number`.
        methods.add_method("setChunkSize", |_, this, s: u32| {
            this.inner.borrow_mut().set_chunk_size(s);
            Ok(())
        });
        /// Returns the chunk size.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `zoom` — `number`.
        ///
        /// # Returns
        /// The current chunk size.
        methods.add_method("getChunkSize", |_, this, ()| {
            Ok(this.inner.borrow().get_chunk_size())
        });
        /// Sets the camera.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `zoom` — `number`.
        methods.add_method("setCamera", |_, this, (x, y, zoom): (f32, f32, f32)| {
            this.inner.borrow_mut().set_camera(x, y, zoom);
            Ok(())
        });
        /// Sets the viewport.
        ///
        /// # Parameters
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });
        /// Sets the l o d enabled.
        ///
        /// # Parameters
        /// - `b` — `boolean`.
        methods.add_method("setLODEnabled", |_, this, b: bool| {
            this.inner.borrow_mut().set_lod_enabled(b);
            Ok(())
        });
        /// Returns `true` if l o d enabled.
        ///
        /// # Parameters
        /// - `levels` — `table`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isLODEnabled", |_, this, ()| {
            Ok(this.inner.borrow().is_lod_enabled())
        });
        /// Sets the l o d thresholds.
        ///
        /// # Parameters
        /// - `cx` — `integer`.
        /// - `cy` — `integer`.
        methods.add_method("setLODThresholds", |_, this, levels: LuaTable| {
            let thresholds: Vec<f32> = levels
                .sequence_values::<f32>()
                .collect::<LuaResult<Vec<_>>>()?;
            this.inner.borrow_mut().set_lod_thresholds(thresholds);
            Ok(())
        });
        /// Invalidate chunk on this LargeMapRenderer.
        ///
        /// # Parameters
        /// - `cx` — `integer`.
        /// - `cy` — `integer`.
        methods.add_method("invalidateChunk", |_, this, (cx, cy): (i32, i32)| {
            this.inner.borrow_mut().invalidate_chunk(cx, cy);
            Ok(())
        });
        /// Invalidate all on this LargeMapRenderer.
        ///
        /// # Returns
        /// The result.
        methods.add_method("invalidateAll", |_, this, ()| {
            this.inner.borrow_mut().invalidate_all();
            Ok(())
        });
        /// Returns the visible chunks.
        ///
        /// # Parameters
        /// - `cols` — `integer`.
        ///
        /// # Returns
        /// The current visible chunks.
        methods.add_method("getVisibleChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_chunks())
        });
        /// Returns the total chunks.
        ///
        /// # Parameters
        /// - `cols` — `integer`.
        ///
        /// # Returns
        /// The current total chunks.
        methods.add_method("getTotalChunks", |_, this, ()| {
            Ok(this.inner.borrow().get_total_chunks())
        });
        /// Sets the tileset columns.
        ///
        /// # Parameters
        /// - `cols` — `integer`.
        methods.add_method("setTilesetColumns", |_, this, cols: u32| {
            this.inner.borrow_mut().set_tileset_columns(cols);
            Ok(())
        });
        /// Returns the tileset columns.
        ///
        /// # Returns
        /// The current tileset columns.
        methods.add_method("getTilesetColumns", |_, this, ()| {
            Ok(this.inner.borrow().get_tileset_columns())
        });
    }
}

// ---------------------------------------------------------------------------
// 10. LuaColumnBatch
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for ColumnBatch.
#[derive(Clone)]
struct LuaColumnBatch {
    inner: Rc<RefCell<ColumnBatch>>,
}

impl LunaType for LuaColumnBatch {
    const TYPE_NAME: &'static str = "ColumnBatch";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaColumnBatch {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // setColumn(col, texU, start, end, shade?, cellVal?) — 1-based col
        methods.add_method(
            "setColumn",
            |_,
             this,
             (col, tex_u, start, end, shade, cell_val): (
                usize,
                f32,
                f32,
                f32,
                Option<f32>,
                Option<u32>,
            )| {
                this.inner.borrow_mut().set_column(
                    col.saturating_sub(1),
                    tex_u,
                    start,
                    end,
                    shade.unwrap_or(1.0),
                    cell_val.unwrap_or(0),
                );
                Ok(())
            },
        );
        // updateFromRayData(rays, fov, maxShadeDist?)
        methods.add_method(
            "updateFromRayData",
            |_, this, (rays, fov, max_shade): (LuaTable, f32, Option<f32>)| {
                let ray_data: Vec<f32> = rays
                    .sequence_values::<f32>()
                    .collect::<LuaResult<Vec<_>>>()?;
                this.inner
                    .borrow_mut()
                    .update_from_ray_data(&ray_data, fov, max_shade);
                Ok(())
            },
        );
        methods.add_method(
            "setFloorColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_floor_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        methods.add_method(
            "setCeilingColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_ceiling_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        // getDepthAt(col) — 1-based
        /// Returns the depth at.
        ///
        /// # Parameters
        /// - `col` — `integer`.
        ///
        /// # Returns
        /// The current depth at.
        methods.add_method("getDepthAt", |_, this, col: usize| {
            Ok(this
                .inner
                .borrow()
                .get_depth_at(col.saturating_sub(1))
                .unwrap_or(0.0))
        });
        /// Returns the depth buffer.
        ///
        /// # Returns
        /// The current depth buffer.
        methods.add_method("getDepthBuffer", |lua, this, ()| {
            let buf = this.inner.borrow().get_depth_buffer();
            let tbl = lua.create_table()?;
            for (i, d) in buf.iter().enumerate() {
                tbl.set(i + 1, *d)?;
            }
            Ok(tbl)
        });
        /// Returns the column count.
        ///
        /// # Returns
        /// The current column count.
        methods.add_method("getColumnCount", |_, this, ()| {
            Ok(this.inner.borrow().get_column_count())
        });
        /// Returns the screen width.
        ///
        /// # Returns
        /// The current screen width.
        methods.add_method("getScreenWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_screen_width())
        });
        /// Returns the screen height.
        ///
        /// # Returns
        /// The current screen height.
        methods.add_method("getScreenHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_screen_height())
        });
    }
}

// ---------------------------------------------------------------------------
// 11. LuaCamera2D
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for Camera2D.
#[derive(Clone)]
struct LuaCamera2D {
    inner: Rc<RefCell<Camera2D>>,
}

impl LunaType for LuaCamera2D {
    const TYPE_NAME: &'static str = "Camera2D";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaCamera2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Sets the position.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });
        /// Returns the position.
        ///
        /// # Parameters
        /// - `z` — `number`.
        ///
        /// # Returns
        /// The current position.
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });
        /// Sets the zoom.
        ///
        /// # Parameters
        /// - `z` — `number`.
        methods.add_method("setZoom", |_, this, z: f32| {
            this.inner.borrow_mut().set_zoom(z);
            Ok(())
        });
        /// Returns the zoom.
        ///
        /// # Parameters
        /// - `r` — `number`.
        ///
        /// # Returns
        /// The current zoom.
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.borrow().get_zoom()));
        /// Sets the rotation.
        ///
        /// # Parameters
        /// - `r` — `number`.
        methods.add_method("setRotation", |_, this, r: f32| {
            this.inner.borrow_mut().set_rotation(r);
            Ok(())
        });
        /// Returns the rotation.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        ///
        /// # Returns
        /// The current rotation.
        methods.add_method("getRotation", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation())
        });
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        /// Returns the viewport.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        ///
        /// # Returns
        /// The current viewport.
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });
        methods.add_method(
            "setBounds",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_bounds(x, y, w, h);
                Ok(())
            },
        );
        /// Returns the bounds.
        ///
        /// # Returns
        /// The current bounds.
        methods.add_method("getBounds", |_, this, ()| {
            match this.inner.borrow().get_bounds() {
                Some((x, y, w, h)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x as f64),
                    LuaValue::Number(y as f64),
                    LuaValue::Number(w as f64),
                    LuaValue::Number(h as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Removes bounds from the collection.
        ///
        /// # Parameters
        /// - `dx` — `number`.
        /// - `dy` — `number`.
        methods.add_method("removeBounds", |_, this, ()| {
            this.inner.borrow_mut().remove_bounds();
            Ok(())
        });
        /// Returns `true` if bounds.
        ///
        /// # Parameters
        /// - `dx` — `number`.
        /// - `dy` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasBounds", |_, this, ()| {
            Ok(this.inner.borrow().has_bounds())
        });
        /// Move on this Camera2D.
        ///
        /// # Parameters
        /// - `dx` — `number`.
        /// - `dy` — `number`.
        methods.add_method("move", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().move_by(dx, dy);
            Ok(())
        });
        /// Look at on this Camera2D.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("lookAt", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().look_at(x, y);
            Ok(())
        });
        /// To world coords on this Camera2D.
        ///
        /// # Parameters
        /// - `sx` — `number`.
        /// - `sy` — `number`.
        methods.add_method("toWorldCoords", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_world_coords(sx, sy))
        });
        /// To screen coords on this Camera2D.
        ///
        /// # Parameters
        /// - `wx` — `number`.
        /// - `wy` — `number`.
        methods.add_method("toScreenCoords", |_, this, (wx, wy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(wx, wy))
        });
        /// Returns the visible area.
        ///
        /// # Parameters
        /// - `w` — `number`.
        /// - `h` — `number`.
        ///
        /// # Returns
        /// The current visible area.
        methods.add_method("getVisibleArea", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_area())
        });
        /// Sets the dead zone.
        ///
        /// # Parameters
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });
        /// Returns the dead zone.
        ///
        /// # Returns
        /// The current dead zone.
        methods.add_method("getDeadZone", |_, this, ()| {
            match this.inner.borrow().get_dead_zone() {
                Some((w, h)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(w as f64),
                    LuaValue::Number(h as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Sets the target.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_target(x, y);
            Ok(())
        });
        /// Returns the target.
        ///
        /// # Returns
        /// The current target.
        methods.add_method("getTarget", |_, this, ()| {
            match this.inner.borrow().get_target() {
                Some((x, y)) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x as f64),
                    LuaValue::Number(y as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Sets the follow smooth.
        ///
        /// # Parameters
        /// - `intensity` — `number`.
        /// - `duration` — `number`.
        methods.add_method("setFollowSmooth", |_, this, s: f32| {
            this.inner.borrow_mut().set_follow_smooth(s);
            Ok(())
        });
        /// Returns the follow smooth.
        ///
        /// # Parameters
        /// - `intensity` — `number`.
        /// - `duration` — `number`.
        ///
        /// # Returns
        /// The current follow smooth.
        methods.add_method("getFollowSmooth", |_, this, ()| {
            Ok(this.inner.borrow().get_follow_smooth())
        });
        /// Shake on this Camera2D.
        ///
        /// # Parameters
        /// - `intensity` — `number`.
        /// - `duration` — `number`.
        methods.add_method("shake", |_, this, (intensity, duration): (f32, f32)| {
            this.inner.borrow_mut().shake(intensity, duration);
            Ok(())
        });
        /// Sets the look ahead.
        ///
        /// # Parameters
        /// - `mul` — `number`.
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });
        /// Returns the look ahead.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        ///
        /// # Returns
        /// The current look ahead.
        methods.add_method("getLookAhead", |_, this, ()| {
            Ok(this.inner.borrow().get_look_ahead())
        });
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// 12. LuaAnimation
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for Animation.
#[derive(Clone)]
struct LuaAnimation {
    inner: Rc<RefCell<Animation>>,
}

impl LunaType for LuaAnimation {
    const TYPE_NAME: &'static str = "Animation";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // addFrame(x, y, w, h) → 1-based index
        /// Adds frame to the collection.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let idx = this.inner.borrow_mut().add_frame(Rect::new(x, y, w, h));
            // Rust returns 0-based index; convert to 1-based
            Ok(idx + 1)
        });
        // addClip(name, frames, fps, loop?) — frames: 1-based indices
        methods.add_method(
            "addClip",
            |_, this, (name, frames, fps, looping): (String, LuaTable, f32, Option<bool>)| {
                let indices: Vec<usize> = frames
                    .sequence_values::<usize>()
                    .map(|r| r.map(|i| i.saturating_sub(1)))
                    .collect::<LuaResult<Vec<_>>>()?;
                this.inner
                    .borrow_mut()
                    .add_clip(&name, indices, fps, looping.unwrap_or(true));
                Ok(())
            },
        );
        /// Starts playback.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("play", |_, this, name: String| {
            Ok(this.inner.borrow_mut().play(&name))
        });
        /// Stops playback.
        ///
        /// # Returns
        /// The result.
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });
        /// Pauses playback.
        ///
        /// # Returns
        /// The result.
        methods.add_method("pause", |_, this, ()| {
            this.inner.borrow_mut().pause();
            Ok(())
        });
        /// Resumes paused playback.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("resume", |_, this, ()| {
            this.inner.borrow_mut().resume();
            Ok(())
        });
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |_, this, dt: f32| {
            let mut anim = this.inner.borrow_mut();
            anim.update(dt);
            // Drain events so they don't accumulate
            let _ = anim.drain_events();
            Ok(())
        });
        /// Returns the current quad.
        ///
        /// # Returns
        /// The current current quad.
        methods.add_method("getCurrentQuad", |_, this, ()| {
            match this.inner.borrow().current_quad() {
                Some(r) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(r.x as f64),
                    LuaValue::Number(r.y as f64),
                    LuaValue::Number(r.width as f64),
                    LuaValue::Number(r.height as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        // getCurrentFrame() → 1-based
        /// Returns the current frame.
        ///
        /// # Returns
        /// The current current frame.
        methods.add_method("getCurrentFrame", |_, this, ()| {
            Ok(this.inner.borrow().current_frame() + 1)
        });
        /// Returns the current clip.
        ///
        /// # Returns
        /// The current current clip.
        methods.add_method("getCurrentClip", |_, this, ()| {
            Ok(this
                .inner
                .borrow()
                .get_current_clip()
                .map(|s| s.to_string()))
        });
        /// Returns `true` if playing.
        ///
        /// # Parameters
        /// - `f` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });
        /// Returns `true` if looping.
        ///
        /// # Parameters
        /// - `f` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isLooping", |_, this, ()| {
            Ok(this.inner.borrow().is_looping())
        });
        /// Sets the speed.
        ///
        /// # Parameters
        /// - `f` — `number`.
        methods.add_method("setSpeed", |_, this, f: f32| {
            this.inner.borrow_mut().set_speed(f);
            Ok(())
        });
        /// Returns the speed.
        ///
        /// # Returns
        /// The current speed.
        methods.add_method("getSpeed", |_, this, ()| {
            Ok(this.inner.borrow().get_speed())
        });
        /// Returns the frame count.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current frame count.
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.borrow().get_frame_count())
        });
        /// Returns the clip count.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current clip count.
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.borrow().get_clip_count())
        });
        // setFrame(index) — 1-based
        /// Sets the frame.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("setFrame", |_, this, index: usize| {
            this.inner.borrow_mut().set_frame(index.saturating_sub(1));
            Ok(())
        });
        // addFramesFromGrid(texW, texH, frameW, frameH, start?, count?) — 1-based start
        methods.add_method(
            "addFramesFromGrid",
            |_,
             this,
             (tex_w, tex_h, frame_w, frame_h, start, count): (
                u32,
                u32,
                u32,
                u32,
                Option<usize>,
                Option<usize>,
            )| {
                let s = start.unwrap_or(1).saturating_sub(1);
                let total_cells = if frame_w > 0 && frame_h > 0 {
                    ((tex_w / frame_w) * (tex_h / frame_h)) as usize
                } else {
                    0
                };
                let c = count.unwrap_or(total_cells.saturating_sub(s));
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_frames_from_grid(tex_w, tex_h, frame_w, frame_h, s, c))
            },
        );
        // addClipFromGrid(name, texW, texH, frameW, frameH, start, count, fps, loop?) — 1-based start
        methods.add_method(
            "addClipFromGrid",
            |_,
             this,
             (name, tex_w, tex_h, frame_w, frame_h, start, count, fps, looping): (
                String,
                u32,
                u32,
                u32,
                u32,
                usize,
                usize,
                f32,
                Option<bool>,
            )| {
                this.inner.borrow_mut().add_clip_from_grid(
                    &name,
                    tex_w,
                    tex_h,
                    frame_w,
                    frame_h,
                    start.saturating_sub(1),
                    count,
                    fps,
                    looping.unwrap_or(true),
                );
                Ok(())
            },
        );
    }
}

// ---------------------------------------------------------------------------
// Internal-only UserData (no factory functions)
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for Trail (internal — no factory).
#[derive(Clone)]
pub struct LuaTrail {
    inner: Rc<RefCell<Trail>>,
}

impl LunaType for LuaTrail {
    const TYPE_NAME: &'static str = "Trail";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaTrail {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Adds point to the collection.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("pushPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().push_point(x, y);
            Ok(())
        });
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `start` — `number`.
        /// - `end` — `number` optional.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        /// Sets the width.
        ///
        /// # Parameters
        /// - `start` — `number`.
        /// - `end` — `number` optional.
        methods.add_method("setWidth", |_, this, (start, end): (f32, Option<f32>)| {
            this.inner.borrow_mut().set_width(start, end);
            Ok(())
        });
        /// Sets the lifetime.
        ///
        /// # Parameters
        /// - `lt` — `number`.
        methods.add_method("setLifetime", |_, this, lt: f32| {
            this.inner.borrow_mut().set_lifetime(lt);
            Ok(())
        });
        /// Returns the lifetime.
        ///
        /// # Parameters
        /// - `d` — `number`.
        ///
        /// # Returns
        /// The current lifetime.
        methods.add_method("getLifetime", |_, this, ()| {
            Ok(this.inner.borrow().get_lifetime())
        });
        /// Sets the min distance.
        ///
        /// # Parameters
        /// - `d` — `number`.
        methods.add_method("setMinDistance", |_, this, d: f32| {
            this.inner.borrow_mut().set_min_distance(d);
            Ok(())
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        /// Returns the point count.
        ///
        /// # Returns
        /// The current point count.
        methods.add_method("getPointCount", |_, this, ()| {
            Ok(this.inner.borrow().get_point_count())
        });
        /// Returns the width.
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        methods.add_method(
            "setHeadColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_head_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
        methods.add_method(
            "setTailColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_tail_color(parse_color(r, g, b, a));
                Ok(())
            },
        );
    }
}

/// Lua UserData wrapper for DecalSurface (internal — no factory).
#[derive(Clone)]
pub struct LuaDecalSurface {
    inner: Rc<RefCell<DecalSurface>>,
}

impl LunaType for LuaDecalSurface {
    const TYPE_NAME: &'static str = "DecalSurface";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaDecalSurface {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the dimensions.
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });
        /// Returns the width.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });
        /// Returns the height.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });
    }
}

/// Lua UserData wrapper for PaletteLUT (internal — no factory).
#[derive(Clone)]
pub struct LuaPaletteLUT {
    inner: Rc<RefCell<PaletteLUT>>,
}

impl LunaType for LuaPaletteLUT {
    const TYPE_NAME: &'static str = "PaletteLUT";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaPaletteLUT {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the color count.
        ///
        /// # Returns
        /// The current color count.
        methods.add_method("getColorCount", |_, this, ()| {
            Ok(this.inner.borrow().get_color_count())
        });
        // setColor(index, fromR, fromG, fromB, fromA, toR, toG, toB, toA)
        methods.add_method(
            "setColor",
            |_,
             this,
             (index, fr, fg, fb, fa, tr, tg, tb, ta): (
                usize,
                f32,
                f32,
                f32,
                Option<f32>,
                f32,
                f32,
                f32,
                Option<f32>,
            )| {
                let from = parse_color(fr, fg, fb, fa);
                let to = parse_color(tr, tg, tb, ta);
                this.inner.borrow_mut().set_color(index, from, to);
                Ok(())
            },
        );
        /// Returns the from color.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current from color.
        methods.add_method("getFromColor", |_, this, index: usize| {
            match this.inner.borrow().get_from_color(index) {
                Some(c) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(c.r as f64),
                    LuaValue::Number(c.g as f64),
                    LuaValue::Number(c.b as f64),
                    LuaValue::Number(c.a as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Returns the to color.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current to color.
        methods.add_method("getToColor", |_, this, index: usize| {
            match this.inner.borrow().get_to_color(index) {
                Some(c) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Number(c.r as f64),
                    LuaValue::Number(c.g as f64),
                    LuaValue::Number(c.b as f64),
                    LuaValue::Number(c.a as f64),
                ])),
                None => Ok(LuaMultiValue::from_vec(vec![LuaValue::Nil])),
            }
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers Phase 24 graphics extension factory functions on `luna.graphics`.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let graphics: LuaTable = luna.get("graphics")?;

    // luna.graphics.newLight2D
    graphics.set(
        "newLight2D",
        lua.create_function(|_, (x, y, radius): (f32, f32, f32)| {
            Ok(LuaLight2D {
                inner: Rc::new(RefCell::new(Light2D::new(x, y, radius))),
            })
        })?,
    )?;

    // luna.graphics.newTextureAtlas(w, h, padding?)
    graphics.set(
        "newTextureAtlas",
        lua.create_function(|_, (w, h, padding): (u32, u32, Option<u32>)| {
            Ok(LuaTextureAtlas {
                inner: Rc::new(RefCell::new(TextureAtlas::new(w, h, padding.unwrap_or(0)))),
            })
        })?,
    )?;

    // luna.graphics.newDrawLayer()
    graphics.set(
        "newDrawLayer",
        lua.create_function(|_, ()| {
            Ok(LuaDrawLayer {
                entries: RefCell::new(Vec::new()),
            })
        })?,
    )?;

    // luna.graphics.newViewport(w, h, mode?)
    graphics.set(
        "newViewport",
        lua.create_function(|_, (w, h, mode): (f32, f32, Option<String>)| {
            let sm = parse_scale_mode(mode.as_deref().unwrap_or("letterbox"));
            Ok(LuaViewport {
                inner: Rc::new(RefCell::new(Viewport::new(w, h, sm))),
            })
        })?,
    )?;

    // luna.graphics.newViewportScale(w, h, mode?)
    graphics.set(
        "newViewportScale",
        lua.create_function(|_, (w, h, mode): (f32, f32, Option<String>)| {
            let sm = parse_scale_mode(mode.as_deref().unwrap_or("letterbox"));
            Ok(LuaViewportScale {
                inner: Rc::new(RefCell::new(ViewportScale::new(w, h, sm))),
            })
        })?,
    )?;

    // luna.graphics.newSpriteSheet(texW, texH, frameW, frameH)
    graphics.set(
        "newSpriteSheet",
        lua.create_function(
            |_, (tex_w, tex_h, frame_w, frame_h): (u32, u32, u32, u32)| {
                Ok(LuaSpriteSheet {
                    inner: Rc::new(RefCell::new(SpriteSheet::new(
                        tex_w, tex_h, frame_w, frame_h,
                    ))),
                })
            },
        )?,
    )?;

    // luna.graphics.newPolygonMap()
    graphics.set(
        "newPolygonMap",
        lua.create_function(|_, ()| {
            Ok(LuaPolygonMap {
                inner: Rc::new(RefCell::new(PolygonMap::new())),
            })
        })?,
    )?;

    // luna.graphics.newGraphRenderer()
    graphics.set(
        "newGraphRenderer",
        lua.create_function(|_, ()| {
            Ok(LuaGraphRenderer {
                inner: Rc::new(RefCell::new(GraphRenderer::new())),
            })
        })?,
    )?;

    // luna.graphics.newLargeMapRenderer(tileW, tileH)
    graphics.set(
        "newLargeMapRenderer",
        lua.create_function(|_, (tile_w, tile_h): (u32, u32)| {
            Ok(LuaLargeMapRenderer {
                inner: Rc::new(RefCell::new(LargeMapRenderer::new(tile_w, tile_h))),
            })
        })?,
    )?;

    // luna.graphics.newColumnBatch(colCount, screenW, screenH)
    graphics.set(
        "newColumnBatch",
        lua.create_function(|_, (col_count, screen_w, screen_h): (usize, f32, f32)| {
            Ok(LuaColumnBatch {
                inner: Rc::new(RefCell::new(ColumnBatch::new(
                    col_count, screen_w, screen_h,
                ))),
            })
        })?,
    )?;

    // luna.graphics.newCamera2D(w?, h?)
    graphics.set(
        "newCamera2D",
        lua.create_function(|_, (w, h): (Option<f32>, Option<f32>)| {
            Ok(LuaCamera2D {
                inner: Rc::new(RefCell::new(Camera2D::new(
                    w.unwrap_or(800.0),
                    h.unwrap_or(600.0),
                ))),
            })
        })?,
    )?;

    // luna.graphics.newAnimation()
    graphics.set(
        "newAnimation",
        lua.create_function(|_, ()| {
            Ok(LuaAnimation {
                inner: Rc::new(RefCell::new(Animation::new())),
            })
        })?,
    )?;

    Ok(())
}
