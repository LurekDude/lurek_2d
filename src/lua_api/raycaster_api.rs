//! Lua API for raycaster system extensions.
//!
//! Registers `luna.raycaster.*` bindings for door management, variable-height
//! floors and ceilings, depth buffering, point lighting, and projection
//! utilities. The core [`Raycaster2D`] grid type is exposed via `luna.math`
//! (see `math_api.rs`).
//!
//! # Lua API summary
//!
//! | Constructor / Function | Type | Description |
//! |---|---|---|
//! | `luna.raycaster.newDoorManager()` | → `DoorManager` | Empty door manager |
//! | `luna.raycaster.newHeightMap(w, h)` | → `HeightMap` | Per-cell floor/ceiling heights |
//! | `luna.raycaster.newDepthBuffer(width)` | → `DepthBuffer` | 1-D depth buffer for sprites |
//! | `luna.raycaster.newLight(x,y,r,i,lr,lg,lb)` | → `PointLight` | Point light source |
//! | `luna.raycaster.computeLighting(x,y,ambient,lights)` | → `r,g,b` | Ambient + point-light sum |
//! | `luna.raycaster.applyLitShade(shade,r,g,b)` | → `r,g,b` | Multiply shade by light colour |
//! | `luna.raycaster.projectColumn(dist,fov,screenH)` | → `h,start,end` | Wall column screen coords |
//! | `luna.raycaster.distanceShade(dist,maxDist)` | → `f32` | Distance attenuation in [0,1] |

use mlua::prelude::*;
use std::cell::RefCell;

use crate::raycaster::{
    apply_lit_shade, compute_lighting, distance_shade, project_column, DoorDirection, DoorManager,
    DepthBuffer, HeightMap, PointLight,
};

// ---------------------------------------------------------------------------
// LuaDoorManager
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for [`DoorManager`].
struct LuaDoorManager {
    inner: RefCell<DoorManager>,
}

impl LuaUserData for LuaDoorManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds a door at grid position (x, y).
        ///
        /// `direction` must be `"horizontal"` or `"vertical"`.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `direction` — `string`.
        /// - `speed` — `number` (units per second, default 2.0).
        ///
        /// # Returns
        /// Door index (1-based).
        methods.add_method(
            "addDoor",
            |_, this, (x, y, direction, speed): (u32, u32, String, Option<f32>)| {
                let dir = match direction.as_str() {
                    "horizontal" => DoorDirection::Horizontal,
                    "vertical" => DoorDirection::Vertical,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "invalid door direction '{other}'; expected 'horizontal' or 'vertical'"
                        )))
                    }
                };
                let idx = this
                    .inner
                    .borrow_mut()
                    .add_door(x - 1, y - 1, dir, speed.unwrap_or(2.0));
                Ok(idx + 1) // 1-based
            },
        );

        /// Begins opening a door by index (1-based).
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("openDoor", |_, this, index: usize| {
            this.inner.borrow_mut().open_door(index - 1);
            Ok(())
        });

        /// Begins closing a door by index (1-based).
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("closeDoor", |_, this, index: usize| {
            this.inner.borrow_mut().close_door(index - 1);
            Ok(())
        });

        /// Advances all door animations by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns the number of managed doors.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getDoorCount", |_, this, ()| {
            Ok(this.inner.borrow().doors().len())
        });

        /// Finds a door at grid position (x, y), or returns `nil`.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// Table with fields `x, y, openAmount, speed, direction, state`, or `nil`.
        methods.add_method("getDoorAt", |lua, this, (x, y): (u32, u32)| {
            let mgr = this.inner.borrow();
            match mgr.get_door_at(x - 1, y - 1) {
                Some(d) => {
                    let tbl = lua.create_table()?;
                    tbl.set("x", d.x + 1)?;
                    tbl.set("y", d.y + 1)?;
                    tbl.set("openAmount", d.open_amount)?;
                    tbl.set("speed", d.speed)?;
                    tbl.set(
                        "direction",
                        match d.direction {
                            DoorDirection::Horizontal => "horizontal",
                            DoorDirection::Vertical => "vertical",
                        },
                    )?;
                    tbl.set("state", format!("{:?}", d.state).to_lowercase())?;
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        /// Returns the door at 1-based `index` as a table, or `nil`.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// Table with fields `x, y, openAmount, speed, direction, state`, or `nil`.
        methods.add_method("getDoor", |lua, this, index: usize| {
            let mgr = this.inner.borrow();
            match mgr.doors().get(index - 1) {
                Some(d) => {
                    let tbl = lua.create_table()?;
                    tbl.set("x", d.x + 1)?;
                    tbl.set("y", d.y + 1)?;
                    tbl.set("openAmount", d.open_amount)?;
                    tbl.set("speed", d.speed)?;
                    tbl.set(
                        "direction",
                        match d.direction {
                            DoorDirection::Horizontal => "horizontal",
                            DoorDirection::Vertical => "vertical",
                        },
                    )?;
                    tbl.set("state", format!("{:?}", d.state).to_lowercase())?;
                    Ok(LuaValue::Table(tbl))
                }
                None => Ok(LuaValue::Nil),
            }
        });
    }
}

// ---------------------------------------------------------------------------
// LuaHeightMap
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for [`HeightMap`].
struct LuaHeightMap {
    inner: RefCell<HeightMap>,
}

impl LuaUserData for LuaHeightMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Sets the floor height at (x, y).
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `h` — `number`.
        methods.add_method("setFloor", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_floor(x - 1, y - 1, h);
            Ok(())
        });

        /// Sets the ceiling height at (x, y).
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `h` — `number`.
        methods.add_method("setCeiling", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_ceiling(x - 1, y - 1, h);
            Ok(())
        });

        /// Returns the floor height at (x, y).
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("floorAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().floor_at(x - 1, y - 1))
        });

        /// Returns the ceiling height at (x, y).
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("ceilingAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().ceiling_at(x - 1, y - 1))
        });

        /// Sets the floor height for a rectangular region.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        /// - `height` — `number`.
        methods.add_method(
            "setFloorRect",
            |_, this, (x, y, w, h, height): (u32, u32, u32, u32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_floor_rect(x - 1, y - 1, w, h, height);
                Ok(())
            },
        );

        /// Sets the ceiling height for a rectangular region.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        /// - `height` — `number`.
        methods.add_method(
            "setCeilingRect",
            |_, this, (x, y, w, h, height): (u32, u32, u32, u32, f32)| {
                this.inner
                    .borrow_mut()
                    .set_ceiling_rect(x - 1, y - 1, w, h, height);
                Ok(())
            },
        );
    }
}

// ---------------------------------------------------------------------------
// LuaDepthBuffer
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for [`DepthBuffer`].
struct LuaDepthBuffer {
    inner: RefCell<DepthBuffer>,
}

impl LuaUserData for LuaDepthBuffer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Clears all depth values to infinity.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Sets the depth for a screen column (1-based).
        ///
        /// # Parameters
        /// - `column` — `integer`.
        /// - `depth` — `number`.
        methods.add_method("set", |_, this, (column, depth): (u32, f32)| {
            this.inner.borrow_mut().set(column - 1, depth);
            Ok(())
        });

        /// Returns the depth for a screen column (1-based).
        ///
        /// # Parameters
        /// - `column` — `integer`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("get", |_, this, column: u32| {
            Ok(this.inner.borrow().get(column - 1))
        });

        /// Returns `true` if a sprite at this depth is visible through the column.
        ///
        /// # Parameters
        /// - `column` — `integer`.
        /// - `depth` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isVisible", |_, this, (column, depth): (u32, f32)| {
            Ok(this.inner.borrow().is_visible(column - 1, depth))
        });

        /// Returns the width of the depth buffer.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width()));
    }
}

// ---------------------------------------------------------------------------
// LuaPointLight
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for [`PointLight`].
struct LuaPointLight {
    inner: RefCell<PointLight>,
}

impl LuaUserData for LuaPointLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the world-space X position.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getX", |_, this, ()| Ok(this.inner.borrow().x));
        /// Returns the world-space Y position.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getY", |_, this, ()| Ok(this.inner.borrow().y));

        /// Sets the world-space position.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut light = this.inner.borrow_mut();
            light.x = x;
            light.y = y;
            Ok(())
        });

        /// Returns the illumination radius.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getRadius", |_, this, ()| Ok(this.inner.borrow().radius));
        /// Sets the illumination radius.
        ///
        /// # Parameters
        /// - `radius` — `number`.
        methods.add_method("setRadius", |_, this, radius: f32| {
            this.inner.borrow_mut().radius = radius;
            Ok(())
        });

        /// Returns the intensity multiplier.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getIntensity", |_, this, ()| {
            Ok(this.inner.borrow().intensity)
        });
        /// Sets the intensity multiplier.
        ///
        /// # Parameters
        /// - `intensity` — `number`.
        methods.add_method("setIntensity", |_, this, intensity: f32| {
            this.inner.borrow_mut().intensity = intensity;
            Ok(())
        });

        /// Returns the RGB colour components (each in [0, 1]).
        ///
        /// # Returns
        /// `r, g, b` — three numbers.
        methods.add_method("getColor", |_, this, ()| {
            let c = this.inner.borrow().color;
            Ok((c[0], c[1], c[2]))
        });
        /// Sets the RGB colour components (each in [0, 1]).
        ///
        /// # Parameters
        /// - `r` — `number`.
        /// - `g` — `number`.
        /// - `b` — `number`.
        methods.add_method("setColor", |_, this, (r, g, b): (f32, f32, f32)| {
            this.inner.borrow_mut().color = [r, g, b];
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `luna.raycaster.*` API on the Lua VM.
///
/// Exposes constructors and utility functions for raycaster extensions:
/// door management, heightmaps, depth buffers, point lights, and projection
/// helpers.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let raycaster = lua.create_table()?;

    /// Creates an empty door manager.
    ///
    /// # Returns
    /// `DoorManager` userdata.
    raycaster.set(
        "newDoorManager",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaDoorManager {
                inner: RefCell::new(DoorManager::new()),
            })
        })?,
    )?;

    /// Creates a height map for variable-height floors and ceilings.
    ///
    /// # Parameters
    /// - `width` — `integer`.
    /// - `height` — `integer`.
    ///
    /// # Returns
    /// `HeightMap` userdata.
    raycaster.set(
        "newHeightMap",
        lua.create_function(|lua, (width, height): (u32, u32)| {
            lua.create_userdata(LuaHeightMap {
                inner: RefCell::new(HeightMap::new(width, height)),
            })
        })?,
    )?;

    /// Creates a 1-D depth buffer for sprite occlusion.
    ///
    /// # Parameters
    /// - `width` — `integer` — number of screen columns.
    ///
    /// # Returns
    /// `DepthBuffer` userdata.
    raycaster.set(
        "newDepthBuffer",
        lua.create_function(|lua, width: u32| {
            lua.create_userdata(LuaDepthBuffer {
                inner: RefCell::new(DepthBuffer::new(width)),
            })
        })?,
    )?;

    /// Creates a point light source.
    ///
    /// All colour components are in the [0, 1] range.
    ///
    /// # Parameters
    /// - `x` — `number`.
    /// - `y` — `number`.
    /// - `radius` — `number`.
    /// - `intensity` — `number` (default 1.0).
    /// - `r` — `number` (default 1.0).
    /// - `g` — `number` (default 1.0).
    /// - `b` — `number` (default 1.0).
    ///
    /// # Returns
    /// `PointLight` userdata.
    raycaster.set(
        "newLight",
        lua.create_function(
            |lua,
             (x, y, radius, intensity, r, g, b): (
                f32,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                lua.create_userdata(LuaPointLight {
                    inner: RefCell::new(PointLight {
                        x,
                        y,
                        radius,
                        intensity: intensity.unwrap_or(1.0),
                        color: [r.unwrap_or(1.0), g.unwrap_or(1.0), b.unwrap_or(1.0)],
                    }),
                })
            },
        )?,
    )?;

    /// Computes ambient + point-light illumination at world position (x, y).
    ///
    /// `lights` is a Lua table of `PointLight` userdata objects.
    ///
    /// # Parameters
    /// - `x` — `number`.
    /// - `y` — `number`.
    /// - `ambient` — `number` in [0, 1].
    /// - `lights` — `table` of `PointLight` userdata.
    ///
    /// # Returns
    /// `r, g, b` — three numbers in [0, 1].
    raycaster.set(
        "computeLighting",
        lua.create_function(
            |_, (x, y, ambient, lights_tbl): (f32, f32, f32, LuaTable)| {
                let len = lights_tbl.raw_len();
                let mut lights: Vec<PointLight> = Vec::with_capacity(len);
                for i in 1..=len {
                    let ud: LuaAnyUserData = lights_tbl.raw_get(i)?;
                    let pl = ud.borrow::<LuaPointLight>()?;
                    lights.push(pl.inner.borrow().clone());
                }
                let [r, g, b] = compute_lighting(x, y, ambient, &lights);
                Ok((r, g, b))
            },
        )?,
    )?;

    /// Multiplies a base shade value by a light colour.
    ///
    /// # Parameters
    /// - `base_shade` — `number` in [0, 1].
    /// - `r` — `number` in [0, 1].
    /// - `g` — `number` in [0, 1].
    /// - `b` — `number` in [0, 1].
    ///
    /// # Returns
    /// `r, g, b` — three numbers in [0, 1].
    raycaster.set(
        "applyLitShade",
        lua.create_function(|_, (base_shade, r, g, b): (f32, f32, f32, f32)| {
            let [lr, lg, lb] = apply_lit_shade(base_shade, [r, g, b]);
            Ok((lr, lg, lb))
        })?,
    )?;

    /// Projects a wall column distance to screen-space drawing parameters.
    ///
    /// # Parameters
    /// - `distance` — `number`.
    /// - `fov` — `number` (radians).
    /// - `screen_height` — `number`.
    ///
    /// # Returns
    /// `wall_height, draw_start, draw_end` — three numbers.
    raycaster.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_height): (f32, f32, f32)| {
            let (h, start, end) = project_column(distance, fov, screen_height);
            Ok((h, start, end))
        })?,
    )?;

    /// Distance-based brightness attenuation.
    ///
    /// Returns `(1 - distance / max_distance)` clamped to [0, 1].
    ///
    /// # Parameters
    /// - `distance` — `number`.
    /// - `max_distance` — `number`.
    ///
    /// # Returns
    /// `number` in [0, 1].
    raycaster.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_distance): (f32, f32)| {
            Ok(distance_shade(distance, max_distance))
        })?,
    )?;

    luna.set("raycaster", raycaster)?;
    Ok(())
}
