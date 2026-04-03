//! Lua API bindings for the `luna.minimap.*` minimap module.
//!
//! Provides a `Minimap` UserData type with factory functions for creating
//! grid-based minimaps with terrain coloring, fog of war, tracked objects,
//! pings, markers, and viewport rectangle overlay.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::minimap::{ColorMode, FogLevel, Minimap};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaMinimap
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a grid-based minimap.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Minimap>>`.
#[derive(Clone)]
pub(crate) struct LuaMinimap {
    inner: Rc<RefCell<Minimap>>,
}

impl LunaType for LuaMinimap {
    const TYPE_NAME: &'static str = "Minimap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaMinimap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ── Grid queries ──

        /// Returns the grid width.
        /// @return any
        ///
        /// # Returns
        /// The current grid width.
        methods.add_method("getGridWidth", |_, this, ()| {
            Ok(this.inner.borrow().grid_width())
        });

        /// Returns the grid height.
        /// @return any
        ///
        /// # Returns
        /// The current grid height.
        methods.add_method("getGridHeight", |_, this, ()| {
            Ok(this.inner.borrow().grid_height())
        });

        /// Returns the grid size.
        /// @return any
        ///
        /// # Returns
        /// The current grid size.
        methods.add_method("getGridSize", |_, this, ()| {
            let m = this.inner.borrow();
            Ok((m.grid_width(), m.grid_height()))
        });

        // ── Display dimensions ──

        /// Returns the display width.
        /// @return any
        ///
        /// # Returns
        /// The current display width.
        methods.add_method("getDisplayWidth", |_, this, ()| {
            Ok(this.inner.borrow().display_width())
        });

        /// Returns the display height.
        /// @return any
        ///
        /// # Returns
        /// The current display height.
        methods.add_method("getDisplayHeight", |_, this, ()| {
            Ok(this.inner.borrow().display_height())
        });

        /// Returns the display size.
        /// @return any
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        ///
        /// # Returns
        /// The current display size.
        methods.add_method("getDisplaySize", |_, this, ()| {
            let m = this.inner.borrow();
            Ok((m.display_width(), m.display_height()))
        });

        /// Sets the display size.
        /// @param w : integer
        /// @param h : integer
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().set_display_size(w, h);
            Ok(())
        });

        // ── Terrain ──
        // 1-based coords at Lua boundary

        methods.add_method_mut(
            "setTerrain",
            |_, this, (x, y, terrain_type): (u32, u32, u32)| {
                if x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: setTerrain coordinates are 1-based".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_terrain(x - 1, y - 1, terrain_type);
                Ok(())
            },
        );

        /// Returns the terrain.
        /// @param x : integer
        /// @param y : integer
        /// @return any
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current terrain.
        methods.add_method("getTerrain", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: getTerrain coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.borrow().get_terrain(x - 1, y - 1))
        });

        methods.add_method_mut(
            "setTerrainColor",
            |_, this, (terrain_type, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_terrain_color(terrain_type, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        /// Returns the terrain color.
        /// @param terrain_type : integer
        /// @return any
        ///
        /// # Parameters
        /// - `terrain_type` — `integer`.
        ///
        /// # Returns
        /// The current terrain color.
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.borrow().get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Fog of war ──

        /// Sets the fog enabled.
        /// @param enabled : boolean
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_fog_enabled(enabled);
            Ok(())
        });

        /// Returns `true` if fog enabled.
        /// @return any
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `level` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFogEnabled", |_, this, ()| {
            Ok(this.inner.borrow().fog_enabled())
        });

        methods.add_method_mut(
            "setFogLevel",
            |_, this, (x, y, level): (u32, u32, u8)| {
                if x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: setFogLevel coordinates are 1-based".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_fog_level(x - 1, y - 1, FogLevel::from_u8(level));
                Ok(())
            },
        );

        /// Returns the fog level.
        /// @param x : integer
        /// @param y : integer
        /// @return any
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current fog level.
        methods.add_method("getFogLevel", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: getFogLevel coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.borrow().get_fog_level(x - 1, y - 1) as u8)
        });

        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_fog_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        /// Returns the fog color.
        /// @return any
        ///
        /// # Parameters
        /// - `data` — `table`.
        ///
        /// # Returns
        /// The current fog color.
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.borrow().fog_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        /// Sets the fog data.
        /// @param data : table
        ///
        /// # Parameters
        /// - `data` — `table`.
        methods.add_method_mut("setFogData", |_, this, data: LuaTable| {
            let len = data.len()? as usize;
            let mut bytes = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u8 = data.get(i)?;
                bytes.push(v);
            }
            this.inner.borrow_mut().set_fog_data(&bytes);
            Ok(())
        });

        // ── Object types ──
        // Indices are 1-based at Lua boundary

        methods.add_method_mut(
            "addObjectType",
            |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                let idx = this
                    .inner
                    .borrow_mut()
                    .add_object_type(name, [r, g, b, a.unwrap_or(1.0)]);
                Ok(idx + 1) // 1-based
            },
        );

        methods.add_method_mut(
            "setObjectTypeVisible",
            |_, this, (type_idx, visible): (usize, bool)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_object_type_visible(type_idx - 1, visible);
                Ok(())
            },
        );

        /// Returns `true` if object type visible.
        /// @param type_idx : integer
        /// @return any
        ///
        /// # Parameters
        /// - `type_idx` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isObjectTypeVisible", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: object type index is 1-based".into(),
                ));
            }
            Ok(this.inner.borrow().is_object_type_visible(type_idx - 1))
        });

        /// Returns the object type count.
        /// @return any
        ///
        /// # Returns
        /// The current object type count.
        methods.add_method("getObjectTypeCount", |_, this, ()| {
            Ok(this.inner.borrow().object_type_count())
        });

        // ── Objects ──

        methods.add_method_mut(
            "setObject",
            |_, this, (id, x, y, type_idx, owner): (u32, f32, f32, usize, Option<u32>)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner
                    .borrow_mut()
                    .set_object(id, x, y, type_idx - 1, owner.unwrap_or(0));
                Ok(())
            },
        );

        /// Removes object from the collection.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method_mut("removeObject", |_, this, id: u32| {
            Ok(this.inner.borrow_mut().remove_object(id))
        });

        /// Clear objects on this Minimap.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("clearObjects", |_, this, ()| {
            this.inner.borrow_mut().clear_objects();
            Ok(())
        });

        /// Returns the object count.
        /// @return any
        ///
        /// # Returns
        /// The current object count.
        methods.add_method("getObjectCount", |_, this, ()| {
            Ok(this.inner.borrow().object_count())
        });

        // ── Owner colors ──

        methods.add_method_mut(
            "setOwnerColor",
            |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        /// Returns the owner color.
        /// @param owner : integer
        /// @return any
        ///
        /// # Parameters
        /// - `owner` — `integer`.
        ///
        /// # Returns
        /// The current owner color.
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.borrow().get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Color mode ──

        /// Sets the color mode.
        /// @param mode : string
        ///
        /// # Parameters
        /// - `mode` — `string`.
        methods.add_method_mut("setColorMode", |_, this, mode: String| {
            let cm = match mode.as_str() {
                "terrain" => ColorMode::Terrain,
                "political" => ColorMode::Political,
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "luna.minimap: unknown color mode '{}', expected 'terrain' or 'political'",
                        mode
                    )));
                }
            };
            this.inner.borrow_mut().set_color_mode(cm);
            Ok(())
        });

        /// Returns the color mode.
        /// @return any
        ///
        /// # Returns
        /// The current color mode.
        methods.add_method("getColorMode", |_, this, ()| {
            let mode = this.inner.borrow().color_mode();
            Ok(match mode {
                ColorMode::Terrain => "terrain",
                ColorMode::Political => "political",
            })
        });

        // ── Zoom and pan ──

        /// Sets the zoom.
        /// @param zoom : number
        ///
        /// # Parameters
        /// - `zoom` — `number`.
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.borrow_mut().set_zoom(zoom);
            Ok(())
        });

        /// Returns the zoom.
        /// @return any
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        ///
        /// # Returns
        /// The current zoom.
        methods.add_method("getZoom", |_, this, ()| {
            Ok(this.inner.borrow().zoom())
        });

        /// Sets the center.
        /// @param x : number
        /// @param y : number
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method_mut("setCenter", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_center(x, y);
            Ok(())
        });

        /// Returns the center.
        /// @return any
        ///
        /// # Returns
        /// The current center.
        methods.add_method("getCenter", |_, this, ()| {
            let m = this.inner.borrow();
            Ok((m.center_x(), m.center_y()))
        });

        // ── Viewport rectangle ──

        methods.add_method_mut(
            "setViewportRect",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport_rect(x, y, w, h);
                Ok(())
            },
        );

        /// Clear viewport rect on this Minimap.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("clearViewportRect", |_, this, ()| {
            this.inner.borrow_mut().clear_viewport_rect();
            Ok(())
        });

        /// Returns the viewport rect.
        /// @return any
        ///
        /// # Returns
        /// The current viewport rect.
        methods.add_method("getViewportRect", |lua, this, ()| {
            match this.inner.borrow().viewport_rect() {
                Some((x, y, w, h)) => Ok(LuaValue::Table({
                    let t = lua.create_table()?;
                    /// X on this Minimap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("x", x)?;
                    /// Y on this Minimap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("y", y)?;
                    /// W on this Minimap.
                    ///
                    /// # Returns
                    /// The result.
                    t.set("w", w)?;
                    /// H on this Minimap.
                    ///
                    /// # Parameters
                    /// - `visible` — `boolean`.
                    t.set("h", h)?;
                    t
                })),
                None => Ok(LuaValue::Nil),
            }
        });

        /// Sets the viewport visible.
        /// @param visible : boolean
        ///
        /// # Parameters
        /// - `visible` — `boolean`.
        methods.add_method_mut("setViewportVisible", |_, this, visible: bool| {
            this.inner.borrow_mut().set_viewport_visible(visible);
            Ok(())
        });

        /// Returns `true` if viewport visible.
        /// @return any
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        /// - `a` — `number` optional.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isViewportVisible", |_, this, ()| {
            Ok(this.inner.borrow().viewport_visible())
        });

        methods.add_method_mut(
            "setViewportColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_viewport_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        /// Returns the viewport color.
        /// @return any
        ///
        /// # Returns
        /// The current viewport color.
        methods.add_method("getViewportColor", |_, this, ()| {
            let c = this.inner.borrow().viewport_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Pings ──

        /// Adds ping to the collection.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("addPing", |_, this, args: mlua::Variadic<f32>| {
            let args: Vec<f32> = args.into_iter().collect();
            if args.len() < 3 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: addPing requires at least (x, y, duration)".into(),
                ));
            }
            let (x, y, duration) = (args[0], args[1], args[2]);
            let color = [
                args.get(3).copied().unwrap_or(1.0),
                args.get(4).copied().unwrap_or(1.0),
                args.get(5).copied().unwrap_or(0.0),
                args.get(6).copied().unwrap_or(1.0),
            ];
            this.inner.borrow_mut().add_ping(x, y, duration, color);
            Ok(())
        });

        /// Returns the ping count.
        /// @return any
        ///
        /// # Returns
        /// The current ping count.
        methods.add_method("getPingCount", |_, this, ()| {
            Ok(this.inner.borrow().ping_count())
        });

        // ── Markers ──

        methods.add_method_mut(
            "addMarker",
            |lua, this, args: mlua::MultiValue| {
                let mut iter = args.into_iter();
                let x: f32 = lua
                    .unpack(iter.next().unwrap_or(mlua::Value::Nil))?;
                let y: f32 = lua
                    .unpack(iter.next().unwrap_or(mlua::Value::Nil))?;
                let desc: String = iter
                    .next()
                    .and_then(|v| lua.unpack::<String>(v).ok())
                    .unwrap_or_default();
                let r: f32 = iter
                    .next()
                    .and_then(|v| lua.unpack::<f32>(v).ok())
                    .unwrap_or(1.0);
                let g: f32 = iter
                    .next()
                    .and_then(|v| lua.unpack::<f32>(v).ok())
                    .unwrap_or(0.0);
                let b: f32 = iter
                    .next()
                    .and_then(|v| lua.unpack::<f32>(v).ok())
                    .unwrap_or(0.0);
                let a: f32 = iter
                    .next()
                    .and_then(|v| lua.unpack::<f32>(v).ok())
                    .unwrap_or(1.0);
                let id = this
                    .inner
                    .borrow_mut()
                    .add_marker(x, y, desc, [r, g, b, a]);
                Ok(id)
            },
        );

        /// Removes marker from the collection.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.borrow_mut().remove_marker(id))
        });

        /// Returns `true` if marker.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.borrow().has_marker(id))
        });

        /// Returns the marker description.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// The current marker description.
        methods.add_method("getMarkerDescription", |_, this, id: u32| {
            Ok(this
                .inner
                .borrow()
                .get_marker_description(id)
                .map(|s| s.to_string()))
        });

        /// Returns the marker count.
        /// @return any
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        ///
        /// # Returns
        /// The current marker count.
        methods.add_method("getMarkerCount", |_, this, ()| {
            Ok(this.inner.borrow().marker_count())
        });

        // ── Rendering options ──

        /// Sets the anti alias.
        /// @param enabled : boolean
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_anti_alias(enabled);
            Ok(())
        });

        /// Returns `true` if anti alias.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isAntiAlias", |_, this, ()| {
            Ok(this.inner.borrow().anti_alias())
        });

        // ── Coordinate conversion ──

        methods.add_method(
            "screenToGrid",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                let (gx, gy) = this.inner.borrow().screen_to_grid(sx, sy, mx, my);
                Ok((gx, gy))
            },
        );

        methods.add_method(
            "gridToScreen",
            |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                let (sx, sy) = this.inner.borrow().grid_to_screen(gx, gy, mx, my);
                Ok((sx, sy))
            },
        );

        // ── Update ──

        /// Advances the simulation by `dt` seconds.
        /// @param dt : number
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Register the `luna.minimap` module. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// New minimap.
    ///
    /// @param grid_w : integer
    /// @param grid_h : integer
    /// @param display_w : integer?
    /// @param display_h : integer?
    /// @return any
    module.set(
        "newMinimap",
        lua.create_function(
            |_, (grid_w, grid_h, display_w, display_h): (u32, u32, Option<u32>, Option<u32>)| {
                let dw = display_w.unwrap_or(200);
                let dh = display_h.unwrap_or(200);
                let minimap = Minimap::new(grid_w, grid_h, dw, dh);
                Ok(LuaMinimap {
                    inner: Rc::new(RefCell::new(minimap)),
                })
            },
        )?,
    )?;

    /// Minimap on this Minimap.
    ///
    /// # Returns
    /// The result.
    luna.set("minimap", module)?;
    Ok(())
}
