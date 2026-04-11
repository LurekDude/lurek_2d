//! `lurek.parallax` — multi-layer scrolling background system.
//!
//! Registers `lurek.parallax.newLayer(opts)` and `lurek.parallax.newSet(name)`.
//! Domain logic lives in `src/parallax/`; this file is the thin Lua bridge only.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::render::{BlendMode, RenderCommand};
use crate::parallax::layer::ParallaxLayer;

use crate::lua_api::render_api::LuaImage;

// ===============================================================================
// Helpers
// ===============================================================================

fn blend_from_str(s: &str) -> BlendMode {
    match s {
        "add" => BlendMode::Add,
        "multiply" => BlendMode::Multiply,
        "replace" => BlendMode::Replace,
        "screen" => BlendMode::Screen,
        _ => BlendMode::Alpha,
    }
}

fn blend_to_str(bm: BlendMode) -> &'static str {
    match bm {
        BlendMode::Add => "add",
        BlendMode::Multiply => "multiply",
        BlendMode::Replace => "replace",
        BlendMode::Screen => "screen",
        BlendMode::Alpha => "alpha",
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

    /// Internal helper — push all `DrawImageEx` commands for this layer without
    /// re-borrowing state (caller already holds the mutable reference).
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
        // ── type ──────────────────────────────────────────────────────────────
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("ParallaxLayer"));

        // ── update ────────────────────────────────────────────────────────────
        /// Advances the autonomous scroll accumulator by `dt` seconds.
        ///
        /// Call once per frame in `lurek.process` before drawing.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            this.layer.borrow_mut().update(dt);
            Ok(())
        });

        // ── draw ──────────────────────────────────────────────────────────────
        /// Draws the layer using an explicit camera world position.
        ///
        /// Must be called inside a `lurek.render` or `lurek.render_ui` callback.
        /// Sets the draw color and blend mode to this layer's settings.
        /// @param cam_x : number
        /// @param cam_y : number
        /// @return nil
        methods.add_method("render", |_, this, (cam_x, cam_y): (f32, f32)| {
            let layer = this.layer.borrow();
            let mut st = this.state.borrow_mut();
            Self::push_render_commands_internal(&layer, &mut st, cam_x, cam_y);
            Ok(())
        });

        // ── drawAuto ──────────────────────────────────────────────────────────
        /// Draws the layer using the engine active camera position automatically.
        ///
        /// Equivalent to `layer:draw(lurek.camera.x, lurek.camera.y)`.
        /// @return nil
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

        // ── resetAutoscroll ───────────────────────────────────────────────────
        /// Resets the autonomous scroll accumulator to zero.
        ///
        /// Useful when switching scenes to restart ambient drift from the origin.
        /// @return nil
        methods.add_method("resetAutoscroll", |_, this, ()| {
            this.layer.borrow_mut().reset_autoscroll();
            Ok(())
        });

        // ── setScrollFactor ───────────────────────────────────────────────────
        /// Sets the scroll factor relative to camera movement on each axis.
        ///
        /// `0` = fully fixed (sky); `1` = moves with camera (no parallax);
        /// `0.3` = slow far-background layer.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setScrollFactor", |_, this, (x, y): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.scroll_factor = [x, y];
            Ok(())
        });

        // ── getScrollFactor ───────────────────────────────────────────────────
        /// Returns the scroll factor as `(x, y)`.
        /// @return number, number
        methods.add_method("getScrollFactor", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.scroll_factor[0], l.scroll_factor[1]))
        });

        // ── setOffset ────────────────────────────────────────────────────────
        /// Sets the static world-pixel position bias added on top of camera scroll.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setOffset", |_, this, (x, y): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.offset = [x, y];
            Ok(())
        });

        // ── getOffset ────────────────────────────────────────────────────────
        /// Returns the static offset as `(x, y)`.
        /// @return number, number
        methods.add_method("getOffset", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.offset[0], l.offset[1]))
        });

        // ── setAutoscroll ─────────────────────────────────────────────────────
        /// Sets the autonomous scroll velocity in world-pixels per second.
        ///
        /// Positive X scrolls right; positive Y scrolls down.
        /// @param vx : number
        /// @param vy : number
        /// @return nil
        methods.add_method("setAutoscroll", |_, this, (vx, vy): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.autoscroll = [vx, vy];
            Ok(())
        });

        // ── getAutoscroll ─────────────────────────────────────────────────────
        /// Returns the autoscroll velocity as `(vx, vy)`.
        /// @return number, number
        methods.add_method("getAutoscroll", |_, this, ()| {
            let l = this.layer.borrow();
            Ok((l.autoscroll[0], l.autoscroll[1]))
        });

        // ── setRepeat ────────────────────────────────────────────────────────
        /// Sets whether the layer tiles on the X and Y axes.
        /// @param repeat_x : boolean
        /// @param repeat_y : boolean
        /// @return nil
        methods.add_method("setRepeat", |_, this, (rx, ry): (bool, bool)| {
            let mut l = this.layer.borrow_mut();
            l.repeat_x = rx;
            l.repeat_y = ry;
            Ok(())
        });

        // ── setScale ─────────────────────────────────────────────────────────
        /// Sets the texture display scale factor on each axis.
        ///
        /// Values > 1 zoom in (larger tiles); values < 1 zoom out (more tiles).
        /// @param sx : number
        /// @param sy : number
        /// @return nil
        methods.add_method("setScale", |_, this, (sx, sy): (f32, f32)| {
            let mut l = this.layer.borrow_mut();
            l.scale = [sx, sy];
            Ok(())
        });

        // ── setZ ─────────────────────────────────────────────────────────────
        /// Sets the draw-order depth. Lower values render first (further back).
        /// @param z : integer
        /// @return nil
        methods.add_method("setZ", |_, this, z: i32| {
            this.layer.borrow_mut().z = z;
            Ok(())
        });

        // ── getZ ─────────────────────────────────────────────────────────────
        /// Returns the draw-order depth.
        /// @return integer
        methods.add_method("getZ", |_, this, ()| Ok(this.layer.borrow().z));

        // ── setOpacity ────────────────────────────────────────────────────────
        /// Sets the layer-wide opacity override in `[0.0, 1.0]`.
        /// @param a : number
        /// @return nil
        methods.add_method("setOpacity", |_, this, a: f32| {
            this.layer.borrow_mut().opacity = a.clamp(0.0, 1.0);
            Ok(())
        });

        // ── getOpacity ────────────────────────────────────────────────────────
        /// Returns the current opacity.
        /// @return number
        methods.add_method("getOpacity", |_, this, ()| Ok(this.layer.borrow().opacity));

        // ── setTint ───────────────────────────────────────────────────────────
        /// Sets the multiplicative RGBA tint applied to all pixels of this layer.
        ///
        /// All components in `[0.0, 1.0]`. Default: `(1, 1, 1, 1)` (white — no tint).
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @return nil
        methods.add_method("setTint", |_, this, (r, g, b, a): (f32, f32, f32, f32)| {
            this.layer.borrow_mut().tint = [r, g, b, a];
            Ok(())
        });

        // ── getTint ───────────────────────────────────────────────────────────
        /// Returns the current tint as `(r, g, b, a)`.
        /// @return number, number, number, number
        methods.add_method("getTint", |_, this, ()| {
            let [r, g, b, a] = this.layer.borrow().tint;
            Ok((r, g, b, a))
        });

        // ── setBlendMode ──────────────────────────────────────────────────────
        /// Sets the GPU blend mode for this layer.
        ///
        /// Valid modes: `"alpha"` (default), `"add"`, `"multiply"`, `"replace"`, `"screen"`.
        /// @param mode : string
        /// @return nil
        methods.add_method("setBlendMode", |_, this, mode: String| {
            this.layer.borrow_mut().blend_mode = blend_from_str(&mode);
            Ok(())
        });

        // ── getBlendMode ──────────────────────────────────────────────────────
        /// Returns the current blend mode as a string.
        /// @return string
        methods.add_method("getBlendMode", |_, this, ()| {
            Ok(blend_to_str(this.layer.borrow().blend_mode).to_string())
        });

        // ── setVisible ────────────────────────────────────────────────────────
        /// Shows or hides this layer.
        /// @param visible : boolean
        /// @return nil
        methods.add_method("setVisible", |_, this, v: bool| {
            this.layer.borrow_mut().visible = v;
            Ok(())
        });

        // ── isVisible ────────────────────────────────────────────────────────
        /// Returns `true` if the layer is currently visible.
        /// @return boolean
        methods.add_method("isVisible", |_, this, ()| Ok(this.layer.borrow().visible));

        // ── setClamp ──────────────────────────────────────────────────────────
        /// Clamps the scroll offset to a world-pixel range on each axis.
        ///
        /// Prevents the layer from scrolling outside `[min_x, max_x]` × `[min_y, max_y]`.
        /// Useful for non-repeating layers that have a fixed world size.
        /// @param min_x : number
        /// @param min_y : number
        /// @param max_x : number
        /// @param max_y : number
        methods.add_method(
            "setClamp",
            |_, this, (min_x, min_y, max_x, max_y): (f32, f32, f32, f32)| {
                let mut l = this.layer.borrow_mut();
                l.clamp_min = Some([min_x, min_y]);
                l.clamp_max = Some([max_x, max_y]);
                Ok(())
            },
        );

        // ── clearClamp ────────────────────────────────────────────────────────
        /// Removes scroll clamping so the layer scrolls freely.
        /// @return nil
        methods.add_method("clearClamp", |_, this, ()| {
            let mut l = this.layer.borrow_mut();
            l.clamp_min = None;
            l.clamp_max = None;
            Ok(())
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

    /// Sorts `layers` by ascending `z` value of the underlying `ParallaxLayer`.
    fn sort_by_z(&mut self) {
        self.layers.sort_by_key(|l| l.layer.borrow().z);
    }
}

impl LuaUserData for LuaParallaxSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── type ──────────────────────────────────────────────────────────────
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("ParallaxSet"));

        // ── addLayer ──────────────────────────────────────────────────────────
        /// Adds a layer to this set.
        ///
        /// The layer is added by shared reference: mutating the original variable
        /// after adding is reflected in the set.  The set is re-sorted by `z` on
        /// every add.
        /// @param layer : LuaParallaxLayer
        /// @return nil
        methods.add_method_mut("addLayer", |_, this, layer: LuaAnyUserData| {
            let lu_layer = layer.borrow::<LuaParallaxLayer>()?.clone();
            this.layers.push(lu_layer);
            this.sort_by_z();
            Ok(())
        });

        // ── removeLayerAt ─────────────────────────────────────────────────────
        /// Removes the layer at the given 1-based index.
        ///
        /// Returns `true` if a layer was removed, `false` if the index was out of range.
        /// @param index : integer
        /// @return boolean
        methods.add_method_mut("removeLayerAt", |_, this, index: usize| {
            if index >= 1 && index <= this.layers.len() {
                this.layers.remove(index - 1);
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // ── layerCount ────────────────────────────────────────────────────────
        /// Returns the number of layers in this set.
        /// @return integer
        methods.add_method("layerCount", |_, this, ()| Ok(this.layers.len() as i64));

        // ── sortByZ ───────────────────────────────────────────────────────────
        /// Re-sorts all layers by ascending `z` value.
        ///
        /// Call this after changing any layer's `z` value via `layer:setZ()`.
        /// @return nil
        methods.add_method_mut("sortByZ", |_, this, ()| {
            this.sort_by_z();
            Ok(())
        });

        // ── setVisible ────────────────────────────────────────────────────────
        /// Shows or hides all layers in this set.
        /// @param visible : boolean
        /// @return nil
        methods.add_method_mut("setVisible", |_, this, v: bool| {
            this.visible = v;
            Ok(())
        });

        // ── isVisible ────────────────────────────────────────────────────────
        /// Returns `true` if the set is currently visible.
        /// @return boolean
        methods.add_method("isVisible", |_, this, ()| Ok(this.visible));

        // ── update ────────────────────────────────────────────────────────────
        /// Advances the autoscroll accumulator of every layer by `dt` seconds.
        ///
        /// Call once per frame in `lurek.process`.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            for l in &this.layers {
                l.layer.borrow_mut().update(dt);
            }
            Ok(())
        });

        // ── draw ──────────────────────────────────────────────────────────────
        /// Draws all visible layers in ascending `z` order using an explicit camera position.
        ///
        /// Must be called inside a `lurek.render` or `lurek.render_ui` callback.
        /// @param cam_x : number
        /// @param cam_y : number
        /// @return nil
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

        // ── drawAuto ──────────────────────────────────────────────────────────
        /// Draws all visible layers using the engine active camera position.
        /// @return nil
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

        // ── getName ───────────────────────────────────────────────────────────
        /// Returns the name of this set.
        /// @return string
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        // ── setName ───────────────────────────────────────────────────────────
        /// Sets the name of this set.
        /// @param name : string
        /// @return nil
        methods.add_method_mut("setName", |_, this, name: String| {
            this.name = name;
            Ok(())
        });
    }
}

// ===============================================================================
// register
// ===============================================================================

/// Registers the `lurek.parallax` sub-table on the given `luna` global.
///
/// Registers `lurek.parallax` onto the given global table.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let parallax = lua.create_table()?;

    // ── newLayer ──────────────────────────────────────────────────────────────
    /// Creates a new parallax background layer from an options table.
    ///
    /// Required field — `texture`: a `LuaImage` returned by `lurek.gfx.newImage()`.
    ///
    /// Optional fields: `scroll_factor_x`, `scroll_factor_y`, `offset_x`, `offset_y`,
    /// `autoscroll_x`, `autoscroll_y`, `repeat_x`, `repeat_y`, `z`, `opacity`,
    /// `tint_r`, `tint_g`, `tint_b`, `tint_a`, `blend_mode`, `visible`,
    /// `scale_x`, `scale_y`.
    ///
    /// @param opts : table
    /// @return LuaParallaxLayer
    let s = state.clone();
    parallax.set(
        "newLayer",
        lua.create_function(move |_, opts: LuaTable| {
            // --- mandatory: texture ---
            let img_ud: LuaAnyUserData = opts
                .get::<_, LuaAnyUserData>("texture")
                .map_err(|_| LuaError::RuntimeError(
                    "lurek.parallax.newLayer: 'texture' field is required and must be a LuaImage".into(),
                ))?;
            let (tex_key, tex_w, tex_h) = {
                let img = img_ud.borrow::<LuaImage>().map_err(|_| {
                    LuaError::RuntimeError(
                        "lurek.parallax.newLayer: 'texture' must be a valid LuaImage from lurek.gfx.newImage()".into(),
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
                layer.blend_mode = blend_from_str(&v);
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

    // ── newSet ────────────────────────────────────────────────────────────────
    /// Creates a new empty parallax set with the given name.
    ///
    /// A set groups multiple layers for scene-level management: update all and
    /// draw all in one call.
    /// @param name : string
    /// @return LuaParallaxSet
    let s = state.clone();
    parallax.set(
        "newSet",
        lua.create_function(move |_, name: String| Ok(LuaParallaxSet::new(name, s.clone())))?,
    )?;

    luna.set("parallax", parallax)?;
    Ok(())
}
