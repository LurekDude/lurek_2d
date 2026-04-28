//! `lurek.parallax` - multi-layer scrolling background system.
//!
//! Registers `lurek.parallax.newLayer(opts)` and `lurek.parallax.newSet(name)`.
//! Domain logic lives in `src/parallax/`; this file is the thin Lua bridge only.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::parallax::layer::ParallaxLayer;
use crate::render::{BlendMode, RenderCommand};

use crate::lua_api::render_api::LuaImage;

// ===============================================================================
// Helpers
// ===============================================================================

fn blend_from_str(s: &str) -> LuaResult<BlendMode> {
    match s {
        "normal" | "alpha" => Ok(BlendMode::Alpha),
        "additive" | "add" => Ok(BlendMode::Add),
        "multiply" => Ok(BlendMode::Multiply),
        "replace" => Ok(BlendMode::Replace),
        "screen" => Ok(BlendMode::Screen),
        other => Err(LuaError::RuntimeError(format!(
            "lurek.parallax: unknown blend mode '{}'; valid modes are: normal, additive, multiply, replace, screen",
            other
        ))),
    }
}

fn blend_to_str(bm: BlendMode) -> &'static str {
    match bm {
        BlendMode::Add => "additive",
        BlendMode::Multiply => "multiply",
        BlendMode::Replace => "replace",
        BlendMode::Screen => "screen",
        BlendMode::Alpha => "normal",
    }
}

// ===============================================================================
// LuaParallaxLayer
// ===============================================================================

/// Lua-side handle to a single parallax background layer.
///
/// Wraps `Rc<RefCell<ParallaxLayer>>` so that the same layer can be shared
/// cheaply between a `LuaParallaxSet` and script-side variables.
#[derive(Clone)]
pub struct LuaParallaxLayer {
    layer: Rc<RefCell<ParallaxLayer>>,
    state: Rc<RefCell<SharedState>>,
}

impl LuaParallaxLayer {
    fn new(layer: ParallaxLayer, state: Rc<RefCell<SharedState>>) -> Self {
        let layer_rc = Rc::new(RefCell::new(layer));
        // Register a weak ref for engine auto-collection (draw order pass).
        state
            .borrow_mut()
            .auto_parallax_layers
            .push(Rc::downgrade(&layer_rc));
        LuaParallaxLayer {
            layer: layer_rc,
            state,
        }
    }

    // Internal helper - push all `DrawImageEx` commands for this layer without
    // re-borrowing state (caller already holds the mutable reference).
    fn push_render_commands_internal(
        layer: &ParallaxLayer,
        st: &mut SharedState,
        cam_x: f32,
        cam_y: f32,
    ) {
        let screen_w = st.window_state.game_width;
        let screen_h = st.window_state.game_height;

        let Some(batch) = layer.build_draw_calls(cam_x, cam_y, screen_w, screen_h) else {
            return;
        };

        st.render_commands.push(RenderCommand::SetColor(
            batch.color[0],
            batch.color[1],
            batch.color[2],
            batch.color[3],
        ));
        st.render_commands
            .push(RenderCommand::SetBlendMode(batch.blend_mode));

        for (tx, ty) in &batch.tiles {
            st.render_commands.push(RenderCommand::DrawImageEx {
                texture_key: batch.texture_key,
                x: *tx,
                y: *ty,
                rotation: 0.0,
                sx: batch.sx,
                sy: batch.sy,
                ox: 0.0,
                oy: 0.0,
                effect: None,
            });
        }
    }
}

impl LuaUserData for LuaParallaxLayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns the Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LParallaxLayer"));

        // -- update --
        /// Advances the autonomous scroll accumulator by `dt` seconds.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |_, this, dt: f32| {
            this.layer.borrow_mut().update(dt);
            Ok(())
        });

        // -- render --
        /// Draws the layer using an explicit camera world position.
        /// @param | cam_x | number | Camera world X position.
        /// @param | cam_y | number | Camera world Y position.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (cam_x, cam_y): (f32, f32)| {
            let layer = this.layer.borrow();
            let mut st = this.state.borrow_mut();
            Self::push_render_commands_internal(&layer, &mut st, cam_x, cam_y);
            Ok(())
        });

        // -- renderAuto --
        /// Draws the layer using the engine active camera position automatically.
        /// @return | nil | No value is returned.
        methods.add_method("renderAuto", |_, this, ()| {
            let layer = this.layer.borrow();
            let cam_x;
            let cam_y;
            {
                let st = this.state.borrow();
                cam_x = st.camera.position.x;
                cam_y = st.camera.position.y;
            }
            let mut st = this.state.borrow_mut();
            Self::push_render_commands_internal(&layer, &mut st, cam_x, cam_y);
            Ok(())
        });

        // -- resetAutoscroll --
        /// Resets the autonomous scroll accumulator to zero.
        /// @return | nil | No value is returned.
        methods.add_method("resetAutoscroll", |_, this, ()| {
            this.layer.borrow_mut().reset_autoscroll();
            Ok(())
        });

        // -- setScrollFactor --
        /// Sets the scroll factor relative to camera movement on each axis.
        /// @param | x | number | Horizontal scroll factor.
        /// @param | y | number | Vertical scroll factor.
        /// @return | nil | No value is returned.
        methods.add_method("setScrollFactor", |_, this, (x, y): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.scroll_factor = [x, y];
            Ok(())
        });

        // -- getScrollFactor --
        /// Returns the scroll factor as `(x, y)`.
        /// @return | number | Horizontal scroll factor.
        /// @return | number | Vertical scroll factor.
        methods.add_method("getScrollFactor", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.scroll_factor[0], l.scroll_factor[1]))
        });

        // -- setOffset --
        /// Sets the static world-pixel position bias added on top of camera scroll.
        /// @param | x | number | Horizontal offset in world pixels.
        /// @param | y | number | Vertical offset in world pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setOffset", |_, this, (x, y): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.offset = [x, y];
            Ok(())
        });

        // -- getOffset --
        /// Returns the static offset as `(x, y)`.
        /// @return | number | Horizontal offset.
        /// @return | number | Vertical offset.
        methods.add_method("getOffset", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.offset[0], l.offset[1]))
        });

        // -- setAutoscroll --
        /// Sets the autonomous scroll velocity in world-pixels per second.
        /// @param | vx | number | Horizontal autoscroll velocity.
        /// @param | vy | number | Vertical autoscroll velocity.
        /// @return | nil | No value is returned.
        methods.add_method("setAutoscroll", |_, this, (vx, vy): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.autoscroll = [vx, vy];
            Ok(())
        });

        // -- getAutoscroll --
        /// Returns the autoscroll velocity as `(vx, vy)`.
        /// @return | number | Horizontal autoscroll velocity.
        /// @return | number | Vertical autoscroll velocity.
        methods.add_method("getAutoscroll", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.autoscroll[0], l.autoscroll[1]))
        });

        // -- setRepeat --
        /// Sets whether the layer tiles on the X and Y axes.
        /// @param | repeat_x | boolean | Whether the layer repeats on the X axis.
        /// @param | repeat_y | boolean | Whether the layer repeats on the Y axis.
        /// @return | nil | No value is returned.
        methods.add_method("setRepeat", |_, this, (rx, ry): (bool, bool)| {
            let mut l = this.layer.borrow_mut();
            l.repeat_x = rx;
            l.repeat_y = ry;
            Ok(())
        });

        // -- setScale --
        /// Sets the texture display scale factor on each axis.
        /// @param | sx | number | Horizontal scale factor.
        /// @param | sy | number | Vertical scale factor.
        /// @return | nil | No value is returned.
        methods.add_method("setScale", |_, this, (sx, sy): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.scale = [sx, sy];
            Ok(())
        });

        // -- setZ --
        /// Sets the draw-order depth. Lower values render first (further back).
        /// @param | z | integer | Integer draw-order depth.
        /// @return | nil | No value is returned.
        methods.add_method("setZ", |_, this, z: i32| {
            this.layer.borrow_mut().z = z;
            Ok(())
        });

        // -- getZ --
        /// Returns the draw-order depth.
        /// @return | integer | Returns the integer draw-order depth.
        methods.add_method("getZ", |_, this, ()| Ok(this.layer.borrow().z));

        // -- setOpacity --
        /// Sets the layer-wide opacity override in `[0.0, 1.0]`.
        /// @param | a | number | Opacity value in the range `[0.0, 1.0]`.
        /// @return | nil | No value is returned.
        methods.add_method("setOpacity", |_, this, a: f32| {
            this.layer.borrow_mut().opacity = a.clamp(0.0, 1.0);
            Ok(())
        });

        // -- getOpacity --
        /// Returns the current opacity.
        /// @return | number | Returns the current opacity value.
        methods.add_method("getOpacity", |_, this, ()| Ok(this.layer.borrow().opacity));

        // -- setTint --
        /// Sets the multiplicative RGBA tint applied to all pixels of this layer.
        /// @param | r | number | Red tint component.
        /// @param | g | number | Green tint component.
        /// @param | b | number | Blue tint component.
        /// @param | a | number | Alpha tint component.
        /// @return | nil | No value is returned.
        methods.add_method("setTint", |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
            this.layer.borrow_mut().tint = [r, g, b, a];
            Ok(())
        });

        // -- getTint --
        /// Returns the current tint as `(r, g, b, a)`.
        /// @return | number | Tint red component.
        /// @return | number | Tint green component.
        /// @return | number | Tint blue component.
        /// @return | number | Tint alpha component.
        methods.add_method("getTint", |_, this, ()| {
            let [r, g, b, a] = this.layer.borrow().tint;
            Ok((r, g, b, a))
        });

        // -- setBlendMode --
        /// Sets the GPU blend mode for this layer.
        /// @param | mode | string | Blend mode string such as `normal`, `additive`, or `multiply`.
        /// @return | nil | No value is returned.
        methods.add_method("setBlendMode", |_, this, mode: String| {
            this.layer.borrow_mut().blend_mode = blend_from_str(&mode)?;
            Ok(())
        });

        // -- getBlendMode --
        /// Returns the current blend mode as a string.
        /// @return | string | Returns the current blend mode string.
        methods.add_method("getBlendMode", |_, this, ()| {
            Ok(blend_to_str(this.layer.borrow().blend_mode).to_string())
        });

        // -- setVisible --
        /// Shows or hides this layer.
        /// @param | visible | boolean | Whether the layer should be visible.
        /// @return | nil | No value is returned.
        methods.add_method("setVisible", |_, this, v: bool| {
            this.layer.borrow_mut().visible = v;
            Ok(())
        });

        // -- isVisible --
        /// Returns `true` if the layer is currently visible.
        /// @return | boolean | Returns whether the layer is visible.
        methods.add_method("isVisible", |_, this, ()| Ok(this.layer.borrow().visible));

        // -- setClamp --
        /// Clamps the scroll offset to a world-pixel range on each axis.
        /// @param | min_x | number | Minimum horizontal offset.
        /// @param | min_y | number | Minimum vertical offset.
        /// @param | max_x | number | Maximum horizontal offset.
        /// @param | max_y | number | Maximum vertical offset.
        /// @return | nil | No value is returned.
        methods.add_method("setClamp", |_, this, (min_x, min_y, max_x, max_y): (f32, f32, f32, f32)| {
                let mut l = this.layer.borrow_mut();
                l.clamp_min = Some([min_x, min_y]);
                l.clamp_max = Some([max_x, max_y]);
                Ok(())
            },
        );

        // -- clearClamp --
        /// Removes scroll clamping so the layer scrolls freely.
        /// @return | nil | No value is returned.
        methods.add_method("clearClamp", |_, this, ()| {
            let mut l = this.layer.borrow_mut();
            l.clamp_min = None;
            l.clamp_max = None;
            Ok(())
        });

        // -- setTiling --
        /// Enables or disables seamless infinite tiling on both axes simultaneously.
        /// @param | enabled | boolean | Whether seamless tiling should be enabled.
        /// @return | nil | No value is returned.
        methods.add_method("setTiling", |_, this, enabled: bool| {
            this.layer.borrow_mut().set_tiling(enabled);
            Ok(())
        });

        // -- getTiling --
        /// Returns `true` if seamless infinite tiling is enabled.
        /// @return | boolean | Returns whether seamless tiling is enabled.
        methods.add_method("getTiling", |_, this, ()| {
            Ok(this.layer.borrow().get_tiling())
        });

        // -- setTileSize --
        /// Sets explicit tile dimensions in logical pixels.
        /// @param | w | number | Tile width in logical pixels.
        /// @param | h | number | Tile height in logical pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setTileSize", |_, this, (w, h): (f32, f32)| {
            this.layer.borrow_mut().set_tile_size(w, h);
            Ok(())
        });

        // -- setDepth --
        /// Sets the floating-point draw depth for fine-grained layer ordering.
        /// @param | z | number | Floating-point depth value.
        /// @return | nil | No value is returned.
        methods.add_method("setDepth", |_, this, z: f32| {
            this.layer.borrow_mut().set_depth(z);
            Ok(())
        });

        // -- getDepth --
        /// Returns the current floating-point depth.
        /// @return | number | Returns the floating-point depth value.
        methods.add_method("getDepth", |_, this, ()| {
            Ok(this.layer.borrow().get_depth())
        });
    }
}

// ===============================================================================
// LuaParallaxSet
// ===============================================================================

/// Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
///
/// Layers inside a set are sorted by their `z` value.  Mutating a layer through
/// its original `LuaParallaxLayer` variable is reflected in the set because both
/// share the same underlying `Rc<RefCell<ParallaxLayer>>`.
#[derive(Clone)]
pub struct LuaParallaxSet {
    layers: Vec<LuaParallaxLayer>,
    name: String,
    visible: bool,
    state: Rc<RefCell<SharedState>>,
}

impl LuaParallaxSet {
    fn new(name: impl Into<String>, state: Rc<RefCell<SharedState>>) -> Self {
        LuaParallaxSet {
            layers: Vec::new(),
            name: name.into(),
            visible: true,
            state,
        }
    }

    // Sorts `layers` by ascending `z` value of the underlying `ParallaxLayer`.
    fn sort_by_z(&mut self) {
        self.layers.sort_by_key(|l| l.layer.borrow().z);
    }
}

impl LuaUserData for LuaParallaxSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns the Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LParallaxSet"));

        // -- addLayer --
        /// Adds a layer to this set.
        /// @param | layer | LParallaxLayer | Layer userdata to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addLayer", |_, this, layer: LuaAnyUserData| {
            let lu_layer = layer.borrow::<LuaParallaxLayer>()?.clone();
            this.layers.push(lu_layer);
            this.sort_by_z();
            Ok(())
        });

        // -- removeLayerAt --
        /// Removes the layer at the given 1-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | boolean | Returns whether a layer was removed.
        methods.add_method_mut("removeLayerAt", |_, this, index: usize| {
            if index >= 1 && index <= this.layers.len() {
                this.layers.remove(index - 1);
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- layerCount --
        /// Returns the number of layers in this set.
        /// @return | integer | Returns the number of layers in the set.
        methods.add_method("layerCount", |_, this, ()| Ok(this.layers.len() as i64));

        // -- sortByZ --
        /// Re-sorts all layers by ascending `z` value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("sortByZ", |_, this, ()| {
            this.sort_by_z();
            Ok(())
        });

        // -- setVisible --
        /// Shows or hides all layers in this set.
        /// @param | visible | boolean | Whether the set should be visible.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setVisible", |_, this, v: bool| {
            this.visible = v;
            Ok(())
        });

        // -- isVisible --
        /// Returns `true` if the set is currently visible.
        /// @return | boolean | Returns whether the set is visible.
        methods.add_method("isVisible", |_, this, ()| Ok(this.visible));

        // -- update --
        /// Advances the autoscroll accumulator of every layer by `dt` seconds.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            for l in &this.layers {
                l.layer.borrow_mut().update(dt);
            }
            Ok(())
        });

        // -- render --
        /// Draws all visible layers in ascending `z` order using an explicit camera position.
        /// @param | cam_x | number | Camera world X position.
        /// @param | cam_y | number | Camera world Y position.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (cam_x, cam_y): (f32, f32)| {
            if !this.visible {
                return Ok(());
            }
            for l in &this.layers {
                let layer = l.layer.borrow();
                let mut st = this.state.borrow_mut();
                LuaParallaxLayer::push_render_commands_internal(&layer, &mut st, cam_x, cam_y);
            }
            Ok(())
        });

        // -- renderAuto --
        /// Draws all visible layers using the engine active camera position.
        /// @return | nil | No value is returned.
        methods.add_method("renderAuto", |_, this, ()| {
            if !this.visible {
                return Ok(());
            }
            let (cam_x, cam_y) = {
                let st = this.state.borrow();
                (st.camera.position.x, st.camera.position.y)
            };
            for l in &this.layers {
                let layer = l.layer.borrow();
                let mut st = this.state.borrow_mut();
                LuaParallaxLayer::push_render_commands_internal(&layer, &mut st, cam_x, cam_y);
            }
            Ok(())
        });

        // -- getName --
        /// Returns the name of this set.
        /// @return | string | Returns the set name.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        // -- setName --
        /// Sets the name of this set.
        /// @param | name | string | New set name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setName", |_, this, name: String| {
            this.name = name;
            Ok(())
        });
    }
}

// ===============================================================================
// register
// ===============================================================================

/// Registers the `lurek.parallax` sub-table on the given `lurek` global.
/// @param | lua | Lua | Active Lua state.
/// @param | lurek | table | Root `lurek` table.
/// @param | state | SharedState | Shared engine state.
/// @return | nil | Registers the parallax API table.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let parallax = lua.create_table()?;

    // -- newLayer --
    /// Creates a new parallax background layer from an options table.
    /// @param | opts | table | Layer options including a required `texture` field.
    /// @return | LParallaxLayer | Returns the new parallax layer userdata.
    let s = state.clone();
    parallax.set("newLayer", lua.create_function(move |_, opts: LuaTable| {
            // --- mandatory: texture ---
            let img_ud: LuaAnyUserData = opts
                .get::<_, LuaAnyUserData>("texture")
                .map_err(|_| LuaError::RuntimeError(
                    "lurek.parallax.newLayer: 'texture' field is required and must be a LuaImage".into(),
                ))?;
            let (tex_key, tex_w, tex_h) = {
                let img = img_ud.borrow::<LuaImage>().map_err(|_| {
                    LuaError::RuntimeError(
                        "lurek.parallax.newLayer: 'texture' must be a valid LuaImage from lurek.render.newImage()".into(),
                    )
                })?;
                let st = s.borrow();
                let tex_data = st.textures.get(img.key).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "lurek.parallax.newLayer: texture handle is stale or has been released".into(),
                    )
                })?;
                (img.key, tex_data.width as f32, tex_data.height as f32)
            };

            let mut layer = ParallaxLayer::new(tex_key, tex_w, tex_h);

            // --- optional fields ---
            if let Ok(v) = opts.get::<_, f32>("scroll_factor_x") {
                layer.scroll_factor[0] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("scroll_factor_y") {
                layer.scroll_factor[1] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("offset_x") {
                layer.offset[0] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("offset_y") {
                layer.offset[1] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("autoscroll_x") {
                layer.autoscroll[0] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("autoscroll_y") {
                layer.autoscroll[1] = v;
            }
            if let Ok(Some(v)) = opts.get::<_, Option<bool>>("repeat_x") {
                layer.repeat_x = v;
            }
            if let Ok(Some(v)) = opts.get::<_, Option<bool>>("repeat_y") {
                layer.repeat_y = v;
            }
            if let Ok(v) = opts.get::<_, i32>("z") {
                layer.z = v;
            }
            if let Ok(v) = opts.get::<_, f32>("opacity") {
                layer.opacity = v.clamp(0.0, 1.0);
            }
            if let Ok(r) = opts.get::<_, f32>("tint_r") {
                layer.tint[0] = r;
            }
            if let Ok(g) = opts.get::<_, f32>("tint_g") {
                layer.tint[1] = g;
            }
            if let Ok(b) = opts.get::<_, f32>("tint_b") {
                layer.tint[2] = b;
            }
            if let Ok(a) = opts.get::<_, f32>("tint_a") {
                layer.tint[3] = a;
            }
            if let Ok(v) = opts.get::<_, String>("blend_mode") {
                layer.blend_mode = blend_from_str(&v)?;
            }
            if let Ok(Some(v)) = opts.get::<_, Option<bool>>("visible") {
                layer.visible = v;
            }
            if let Ok(v) = opts.get::<_, f32>("scale_x") {
                layer.scale[0] = v;
            }
            if let Ok(v) = opts.get::<_, f32>("scale_y") {
                layer.scale[1] = v;
            }

            Ok(LuaParallaxLayer::new(layer, s.clone()))
        })?,
    )?;

    // -- newSet --
    /// Creates a new empty parallax set with the given name.
    /// @param | name | string | Name assigned to the new set.
    /// @return | LParallaxSet | Returns the new parallax set userdata.
    let s = state.clone();
    parallax.set("newSet", lua.create_function(move |_, name: String| Ok(LuaParallaxSet::new(name, s.clone())))?,
    )?;

    lurek.set("parallax", parallax)?;
    Ok(())
}
