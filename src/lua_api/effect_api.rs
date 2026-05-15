//! `lurek.effect` -- Visual effect bindings for post-processing passes, effect stacks, image effect chains, screen overlays, weather and ambient controls, screen transitions, and shader error display state used by the renderer command queue.

use super::SharedState;
use crate::effect::{
    presets::build_preset, ImageEffect, Overlay, PostFxEffect, PostFxEffectType, PostFxStack,
    WeatherType,
};
use crate::render::renderer::{PostFxPass, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::atomic::{AtomicU64, Ordering};
static NEXT_STACK_ID: AtomicU64 = AtomicU64::new(1);
/// Lua-side handle for a single post-processing effect instance.
pub struct LuaPostFxEffect {
    /// Shared effect state so image effects and stacks can reference the same effect.
    inner: Rc<RefCell<PostFxEffect>>,
}
impl LuaPostFxEffect {
    /// Wraps an owned post-processing effect in shared Lua state.
    fn from_owned(e: PostFxEffect) -> Self {
        Self {
            inner: Rc::new(RefCell::new(e)),
        }
    }
    /// Wraps an existing shared post-processing effect handle.
    fn from_rc(rc: Rc<RefCell<PostFxEffect>>) -> Self {
        Self { inner: rc }
    }
}
/// Provides Lua methods for querying and editing post-processing effect parameters.
impl LuaUserData for LuaPostFxEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getTypeName --
        /// Returns the built-in or custom effect type name.
        /// @return | string | Effect type name used by the renderer.
        methods.add_method("getTypeName", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });
        // -- isBuiltIn --
        /// Returns whether this effect uses one of the engine built-in effect types.
        /// @return | boolean | True for built-in effects, false for custom shader effects.
        methods.add_method("isBuiltIn", |_, this, ()| {
            Ok(this.inner.borrow().is_built_in())
        });
        // -- isEnabled --
        /// Returns whether this effect is enabled on its owning effect object.
        /// @return | boolean | Current enabled flag stored on the effect.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.borrow().enabled));
        // -- setEnabled --
        /// Enables or disables this effect.
        /// @param | enabled | boolean | New enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().enabled = enabled;
            Ok(())
        });
        // -- setParameter --
        /// Sets a numeric shader parameter by name.
        /// @param | name | string | Parameter name expected by the effect shader.
        /// @param | value | number | Numeric parameter value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setParameter", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set_parameter(name, value);
            Ok(())
        });
        // -- getParameter --
        /// Reads a numeric shader parameter and falls back to a default value when missing.
        /// @param | name | string | Parameter name to read.
        /// @param | default | number | Optional default value returned when the parameter is absent.
        /// @return | number | Stored parameter value or the supplied default.
        methods.add_method(
            "getParameter",
            |_, this, (name, default): (String, Option<f32>)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_parameter(&name, default.unwrap_or(0.0)))
            },
        );
        // -- hasParameter --
        /// Returns whether a shader parameter exists on this effect.
        /// @param | name | string | Parameter name to check.
        /// @return | boolean | True when the parameter is present.
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.borrow().has_parameter(&name))
        });
        // -- getParameterNames --
        /// Returns the parameter names stored on this effect.
        /// @return | table | Array table of parameter name strings.
        methods.add_method("getParameterNames", |_, this, ()| {
            Ok(this.inner.borrow().get_parameter_names())
        });
        // -- getEffectType --
        /// Returns the renderer effect type name.
        /// @return | string | Effect type name used by the renderer.
        methods.add_method("getEffectType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name())
        });
        // -- getType --
        /// Returns the renderer effect type name.
        /// @return | string | Effect type name used by the renderer.
        methods.add_method("getType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name())
        });
        // -- type --
        /// Returns the Lua-visible type name for this post-processing effect handle.
        /// @return | string | The string `LPostFxEffect`.
        methods.add_method("type", |_, _, ()| Ok("LPostFxEffect"));
        // -- typeOf --
        /// Returns whether this effect handle matches a supported type name.
        /// @param | name | string | Type name to compare against `PostFxEffect` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "PostFxEffect" || name == "Object")
        });
        // -- setThreshold --
        /// Sets the `threshold` shader parameter.
        /// @param | v | number | Threshold value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setThreshold", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("threshold", v);
            Ok(())
        });
        // -- setIntensity --
        /// Sets the `intensity` shader parameter.
        /// @param | v | number | Intensity value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setIntensity", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("intensity", v);
            Ok(())
        });
        // -- setRadius --
        /// Sets the `radius` shader parameter.
        /// @param | v | number | Radius value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setRadius", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("radius", v);
            Ok(())
        });
        // -- setStrength --
        /// Sets the `strength` shader parameter.
        /// @param | v | number | Strength value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setStrength", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("strength", v);
            Ok(())
        });
        // -- setScanlineStrength --
        /// Sets the `scanline_strength` shader parameter.
        /// @param | v | number | Scanline strength value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setScanlineStrength", |_, this, v: f32| {
            this.inner
                .borrow_mut()
                .set_parameter("scanline_strength", v);
            Ok(())
        });
        // -- setOffset --
        /// Sets the `offset` shader parameter.
        /// @param | v | number | Offset value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setOffset", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("offset", v);
            Ok(())
        });
        // -- setBrightness --
        /// Sets the `brightness` shader parameter.
        /// @param | v | number | Brightness value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setBrightness", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("brightness", v);
            Ok(())
        });
        // -- setContrast --
        /// Sets the `contrast` shader parameter.
        /// @param | v | number | Contrast value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setContrast", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("contrast", v);
            Ok(())
        });
        // -- setSaturation --
        /// Sets the `saturation` shader parameter.
        /// @param | v | number | Saturation value passed to the effect shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSaturation", |_, this, v: f32| {
            this.inner.borrow_mut().set_parameter("saturation", v);
            Ok(())
        });
        // -- enableAutoUniforms --
        /// Enables automatic time and resolution uniforms for this effect.
        /// @return | nil | No value is returned.
        methods.add_method_mut("enableAutoUniforms", |_, this, ()| {
            this.inner.borrow_mut().auto_uniforms = true;
            Ok(())
        });
        // -- disableAutoUniforms --
        /// Disables automatic time and resolution uniforms for this effect.
        /// @return | nil | No value is returned.
        methods.add_method_mut("disableAutoUniforms", |_, this, ()| {
            this.inner.borrow_mut().auto_uniforms = false;
            Ok(())
        });
        // -- isAutoUniforms --
        /// Returns whether automatic uniforms are enabled for this effect.
        /// @return | boolean | True when automatic uniforms are enabled.
        methods.add_method("isAutoUniforms", |_, this, ()| {
            Ok(this.inner.borrow().auto_uniforms)
        });
    }
}
/// Lua-side handle for an ordered post-processing stack.
pub struct LuaPostFxStack {
    /// Core stack dimensions, enabled flags, and pass ordering.
    inner: PostFxStack,
    /// Shared Lua effect handles used by stack pass entries.
    effects: Vec<Rc<RefCell<PostFxEffect>>>,
    /// Unique stack id referenced by renderer commands.
    stack_id: u64,
    /// Shared runtime state that receives renderer post-effect commands.
    state: Rc<RefCell<SharedState>>,
    /// Feedback blend factor clamped to the range 0.0..=1.0.
    feedback_factor: f32,
}
/// Provides Lua methods for editing post-processing stack order, capture, and renderer submission.
impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Appends an effect to the end of this stack.
        /// @param | effect_ud | LPostFxEffect | Effect handle to append.
        /// @return | nil | No value is returned.
        methods.add_method_mut("add", |_, this, effect_ud: LuaAnyUserData| {
            let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
            this.effects.push(Rc::clone(&effect.inner));
            let idx = this.effects.len() - 1;
            this.inner.add(idx);
            Ok(())
        });
        // -- remove --
        /// Removes the first matching effect handle from this stack.
        /// @param | effect_ud | LPostFxEffect | Effect handle to remove.
        /// @return | boolean | True when the effect was found and removed.
        methods.add_method_mut("remove", |_, this, effect_ud: LuaAnyUserData| {
            let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
            let ptr = Rc::as_ptr(&effect.inner);
            if let Some(pos) = this.effects.iter().position(|e| Rc::as_ptr(e) == ptr) {
                this.effects.remove(pos);
                if pos < this.inner.effects.len() {
                    this.inner.effects.remove(pos);
                    this.inner.enabled.remove(pos);
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });
        // -- insert --
        /// Inserts an effect at a one-based stack position.
        /// @param | position | integer | One-based insertion position, clamped to the stack length.
        /// @param | effect_ud | LPostFxEffect | Effect handle to insert.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "insert",
            |_, this, (position, effect_ud): (usize, LuaAnyUserData)| {
                let effect = effect_ud.borrow::<LuaPostFxEffect>()?;
                let idx = (position.saturating_sub(1)).min(this.effects.len());
                this.effects.insert(idx, Rc::clone(&effect.inner));
                this.inner.effects.insert(idx, idx);
                this.inner.enabled.insert(idx, true);
                Ok(())
            },
        );
        // -- setEnabled --
        /// Enables or disables the effect pass at a one-based stack position.
        /// @param | position | integer | One-based stack position.
        /// @param | enabled | boolean | New enabled flag for the pass.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setEnabled",
            |_, this, (position, enabled): (usize, bool)| {
                let idx = position.saturating_sub(1);
                if idx < this.inner.enabled.len() {
                    this.inner.enabled[idx] = enabled;
                }
                Ok(())
            },
        );
        // -- isEnabled --
        /// Returns whether the effect pass at a one-based position is enabled.
        /// @param | position | integer | One-based stack position.
        /// @return | boolean | True when the pass is enabled; false for out-of-range positions.
        methods.add_method("isEnabled", |_, this, position: usize| {
            let idx = position.saturating_sub(1);
            Ok(this.inner.enabled.get(idx).copied().unwrap_or(false))
        });
        // -- getEffectCount --
        /// Returns the number of effect handles in this stack.
        /// @return | integer | Effect count.
        methods.add_method("getEffectCount", |_, this, ()| Ok(this.effects.len()));
        // -- getEffect --
        /// Returns the effect handle at a one-based position.
        /// @param | index | integer | One-based stack position.
        /// @return | LuaValue | `LPostFxEffect` handle, or nil when the index is out of range.
        methods.add_method("getEffect", |lua, this, index: usize| {
            let idx = index.saturating_sub(1);
            match this.effects.get(idx) {
                Some(rc) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaPostFxEffect::from_rc(Rc::clone(rc)))?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- getEnabledEffects --
        /// Returns effect handles whose stack passes are enabled.
        /// @return | table | Array table of enabled `LPostFxEffect` handles.
        methods.add_method("getEnabledEffects", |lua, this, ()| {
            let t = lua.create_table()?;
            let mut count = 1;
            for (i, rc) in this.effects.iter().enumerate() {
                if this.inner.enabled.get(i).copied().unwrap_or(true) {
                    t.set(
                        count,
                        lua.create_userdata(LuaPostFxEffect::from_rc(Rc::clone(rc)))?,
                    )?;
                    count += 1;
                }
            }
            Ok(t)
        });
        // -- getWidth --
        /// Returns the stack render width.
        /// @return | integer | Stack width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));
        // -- getHeight --
        /// Returns the stack render height.
        /// @return | integer | Stack height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));
        // -- getDimensions --
        /// Returns the stack render dimensions.
        /// @return | integer | Stack width in pixels.
        /// @return | integer | Stack height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        // -- resize --
        /// Resizes the post-processing stack render target dimensions.
        /// @param | w | integer | New width in pixels.
        /// @param | h | integer | New height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });
        // -- len --
        /// Returns the number of effect handles in this stack.
        /// @return | integer | Effect count.
        methods.add_method("len", |_, this, ()| Ok(this.effects.len()));
        // -- isEmpty --
        /// Returns whether this stack has no effects.
        /// @return | boolean | True when the stack has zero effects.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.effects.is_empty()));
        // -- clear --
        /// Removes all effects and pass state from this stack.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.effects.clear();
            this.inner.clear();
            Ok(())
        });
        // -- dedup --
        /// Removes duplicate effect handles while preserving first occurrences.
        /// @return | integer | Number of duplicate effects removed.
        methods.add_method_mut("dedup", |_, this, ()| {
            let mut seen_ptrs: Vec<*const ()> = Vec::new();
            let mut new_lua = Vec::with_capacity(this.effects.len());
            let mut new_inner_effects = Vec::with_capacity(this.effects.len());
            let mut new_inner_enabled = Vec::with_capacity(this.effects.len());
            for (i, rc) in this.effects.iter().enumerate() {
                let ptr = Rc::as_ptr(rc) as *const ();
                if !seen_ptrs.contains(&ptr) {
                    seen_ptrs.push(ptr);
                    new_lua.push(Rc::clone(rc));
                    new_inner_effects.push(new_lua.len() - 1);
                    new_inner_enabled.push(this.inner.enabled.get(i).copied().unwrap_or(true));
                }
            }
            let removed = this.effects.len() - new_lua.len();
            this.effects = new_lua;
            this.inner.effects = new_inner_effects;
            this.inner.enabled = new_inner_enabled;
            Ok(removed as i64)
        });
        // -- isCapturing --
        /// Returns whether this stack is currently capturing draw commands.
        /// @return | boolean | True when capture mode is active.
        methods.add_method("isCapturing", |_, this, ()| Ok(this.inner.capturing));
        // -- beginCapture --
        /// Starts post-effect capture and queues a renderer begin-capture command.
        /// @return | nil | No value is returned.
        methods.add_method_mut("beginCapture", |_, this, ()| {
            this.inner.capturing = true;
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::BeginPostFx {
                    stack_id: this.stack_id,
                });
            Ok(())
        });
        // -- endCapture --
        /// Ends post-effect capture and queues a renderer end-capture command.
        /// @return | nil | No value is returned.
        methods.add_method_mut("endCapture", |_, this, ()| {
            this.inner.capturing = false;
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::EndPostFx {
                    stack_id: this.stack_id,
                });
            Ok(())
        });
        // -- apply --
        /// Queues this stack's enabled post-effect passes for renderer application.
        /// @return | nil | No value is returned.
        methods.add_method("apply", |_, this, ()| {
            let passes: Vec<PostFxPass> = this
                .effects
                .iter()
                .zip(this.inner.enabled.iter())
                .filter(|(_, &enabled)| enabled)
                .map(|(effect_rc, _)| {
                    let e = effect_rc.borrow();
                    PostFxPass {
                        effect_name: e.get_type_name().to_string(),
                        params: e.params.clone(),
                        shader_id: e.shader_id,
                        auto_uniforms: e.auto_uniforms,
                    }
                })
                .collect();
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::ApplyPostFx {
                    stack_id: this.stack_id,
                    passes,
                    width: this.inner.width,
                    height: this.inner.height,
                });
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this post-processing stack handle.
        /// @return | string | The string `LPostFxStack`.
        methods.add_method("type", |_, _, ()| Ok("LPostFxStack"));
        // -- typeOf --
        /// Returns whether this stack handle matches a supported type name.
        /// @param | name | string | Type name to compare against `PostFxStack` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "PostFxStack" || name == "Object")
        });
        // -- setFeedback --
        /// Sets the stack feedback blend factor and clamps it to 0.0 through 1.0.
        /// @param | factor | number | Feedback blend factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFeedback", |_, this, factor: f32| {
            this.feedback_factor = factor.clamp(0.0, 1.0);
            Ok(())
        });
        // -- getFeedback --
        /// Returns the current stack feedback blend factor.
        /// @return | number | Feedback blend factor in the range 0.0 through 1.0.
        methods.add_method("getFeedback", |_, this, ()| Ok(this.feedback_factor));
        // -- clearFeedback --
        /// Resets the stack feedback blend factor to zero.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearFeedback", |_, this, ()| {
            this.feedback_factor = 0.0;
            Ok(())
        });
    }
}
/// Lua-side handle for an image effect chain detached from live post-effect capture.
pub struct LuaImageEffect {
    /// Image effect chain and its owned effect entries.
    inner: ImageEffect,
}
/// Provides Lua methods for editing image effect chains.
impl LuaUserData for LuaImageEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addEffect --
        /// Appends a built-in post-effect by type name to this image effect chain.
        /// @param | name | string | Built-in effect type name.
        /// @return | LPostFxEffect | Handle for the effect added to the chain.
        methods.add_method_mut("addEffect", |lua, this, name: String| {
            let et = PostFxEffectType::from_name(&name)
                .ok_or_else(|| LuaError::RuntimeError(format!("unknown effect type: {name}")))?;
            let rc = Rc::new(RefCell::new(PostFxEffect::new(et)));
            this.inner.add_effect_rc(Rc::clone(&rc));
            lua.create_userdata(LuaPostFxEffect::from_rc(rc))
        });
        // -- getEffect --
        /// Looks up an image effect by one-based index or effect type name.
        /// @param | key | LuaValue | Integer index, numeric index, or effect type name.
        /// @return | LuaValue | `LPostFxEffect` handle, or nil when no matching effect exists.
        methods.add_method("getEffect", |lua, this, key: LuaValue| {
            let rc_opt = match &key {
                LuaValue::Integer(i) => this
                    .inner
                    .get_effect_by_index((*i as usize).saturating_sub(1)),
                LuaValue::Number(n) => this
                    .inner
                    .get_effect_by_index((*n as usize).saturating_sub(1)),
                LuaValue::String(s) => this.inner.get_effect_by_name(s.to_str()?),
                _ => None,
            };
            match rc_opt {
                Some(rc) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaPostFxEffect::from_rc(rc))?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- removeEffect --
        /// Removes an image effect by one-based index or effect type name.
        /// @param | key | LuaValue | Integer index, numeric index, or effect type name.
        /// @return | boolean | True when an effect was removed.
        methods.add_method_mut("removeEffect", |_, this, key: LuaValue| match &key {
            LuaValue::Integer(i) => Ok(this.inner.remove_by_index((*i as usize).saturating_sub(1))),
            LuaValue::Number(n) => Ok(this.inner.remove_by_index((*n as usize).saturating_sub(1))),
            LuaValue::String(s) => Ok(this.inner.remove_by_name(s.to_str()?)),
            _ => Ok(false),
        });
        // -- clearEffects --
        /// Removes every effect from this image effect chain.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearEffects", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- clear --
        /// Removes every effect from this image effect chain.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- effectCount --
        /// Returns the number of effects in this image effect chain.
        /// @return | integer | Effect count.
        methods.add_method("effectCount", |_, this, ()| Ok(this.inner.effect_count()));
        // -- getEffectCount --
        /// Returns the number of effects in this image effect chain.
        /// @return | integer | Effect count.
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.effect_count())
        });
        // -- clone --
        /// Creates a new image effect chain with cloned effect entries.
        /// @return | LImageEffect | New image effect handle with the same effect chain.
        methods.add_method("clone", |lua, this, ()| {
            let mut new_ie = ImageEffect::new("");
            for i in 0..this.inner.effect_count() {
                if let Some(rc) = this.inner.get_effect_by_index(i) {
                    new_ie.add_effect(rc.borrow().clone());
                }
            }
            lua.create_userdata(LuaImageEffect { inner: new_ie })
        });
        // -- save --
        /// Reports success for the current image effect save placeholder.
        /// @return | boolean | Always true.
        methods.add_method("save", |_, _, ()| Ok(true));
        // -- type --
        /// Returns the Lua-visible type name for this image effect handle.
        /// @return | string | The string `LImageEffect`.
        methods.add_method("type", |_, _, ()| Ok("LImageEffect"));
        // -- typeOf --
        /// Returns whether this image effect handle matches a supported type name.
        /// @param | name | string | Type name to compare against `ImageEffect` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ImageEffect" || name == "Object")
        });
        // -- removeByIndex --
        /// Removes an image effect by zero-based internal index.
        /// @param | idx | integer | Zero-based effect index.
        /// @return | boolean | True when an effect was removed.
        methods.add_method_mut("removeByIndex", |_, this, idx: usize| {
            Ok(this.inner.remove_by_index(idx))
        });
        // -- removeByName --
        /// Removes the first image effect with a matching effect type name.
        /// @param | name | string | Effect type name to remove.
        /// @return | boolean | True when an effect was removed.
        methods.add_method_mut("removeByName", |_, this, name: String| {
            Ok(this.inner.remove_by_name(&name))
        });
    }
}
/// Lua-side handle for screen overlay, ambient, weather, and transition visual state.
pub struct LuaOverlay {
    /// Overlay state that builds renderer commands for full-screen effects.
    inner: Overlay,
    /// Shared runtime state used for renderer commands and light ambient synchronization.
    state: Rc<RefCell<SharedState>>,
}
/// Provides Lua methods for overlay animation, ambient, weather, fog, water, and render submission.
impl LuaUserData for LuaOverlay {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances overlay timers and animated effect state.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        // -- triggerFlash --
        /// Starts a screen flash with explicit RGBA color and duration.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Alpha channel.
        /// @param | duration | number | Flash duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "triggerFlash",
            |_, this, (r, g, b, a, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_flash(r, g, b, a, duration);
                Ok(())
            },
        );
        // -- triggerShake --
        /// Starts a screen shake effect.
        /// @param | intensity | number | Shake intensity.
        /// @param | duration | number | Shake duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "triggerShake",
            |_, this, (intensity, duration): (f32, f32)| {
                this.inner.trigger_shake(intensity, duration);
                Ok(())
            },
        );
        // -- triggerFade --
        /// Starts a fade overlay toward a target alpha.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | target_alpha | number | Target alpha value.
        /// @param | duration | number | Fade duration in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "triggerFade",
            |_, this, (r, g, b, target_alpha, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_fade(r, g, b, target_alpha, duration);
                Ok(())
            },
        );
        // -- triggerLightning --
        /// Starts a lightning flash using the overlay lightning state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("triggerLightning", |_, this, ()| {
            this.inner.trigger_lightning();
            Ok(())
        });
        // -- getShakeOffset --
        /// Returns the current screen shake offset.
        /// @return | number | Current x offset.
        /// @return | number | Current y offset.
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.get_shake_offset())
        });
        // -- isActive --
        /// Returns whether any overlay effect is currently active.
        /// @return | boolean | True when overlay state should render.
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));
        // -- clear --
        /// Clears active overlay effects and resets transient state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- resize --
        /// Resizes the overlay target dimensions.
        /// @param | w | integer | New width in pixels.
        /// @param | h | integer | New height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });
        // -- getWidth --
        /// Returns the overlay width.
        /// @return | integer | Overlay width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));
        // -- getHeight --
        /// Returns the overlay height.
        /// @return | integer | Overlay height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));
        // -- getDimensions --
        /// Returns the overlay dimensions.
        /// @return | integer | Overlay width in pixels.
        /// @return | integer | Overlay height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        // -- getFlashAlpha --
        /// Returns the current flash alpha.
        /// @return | number | Flash alpha value.
        methods.add_method("getFlashAlpha", |_, this, ()| {
            Ok(this.inner.get_flash_alpha())
        });
        // -- getLightningAlpha --
        /// Returns the current lightning alpha.
        /// @return | number | Lightning alpha value.
        methods.add_method("getLightningAlpha", |_, this, ()| {
            Ok(this.inner.get_lightning_alpha())
        });
        // -- setAmbientEnabled --
        /// Enables or disables overlay ambient color rendering.
        /// @param | v | boolean | New ambient enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setAmbientEnabled", |_, this, v: bool| {
            this.inner.ambient.enabled = v;
            Ok(())
        });
        // -- isAmbientEnabled --
        /// Returns whether overlay ambient color rendering is enabled.
        /// @return | boolean | True when ambient rendering is enabled.
        methods.add_method("isAmbientEnabled", |_, this, ()| {
            Ok(this.inner.ambient.enabled)
        });
        // -- setAmbientColor --
        /// Sets overlay ambient RGBA color.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional alpha channel, defaulting to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setAmbientColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.ambient.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        // -- getAmbientColor --
        /// Returns overlay ambient RGBA color.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getAmbientColor", |_, this, ()| {
            let c = this.inner.ambient.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- pullAmbientFromLight --
        /// Copies ambient color from the shared light world into this overlay.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pullAmbientFromLight", |_, this, ()| {
            let c = this.state.borrow().light_world.ambient;
            this.inner.ambient.color = [c.r, c.g, c.b, c.a];
            Ok(())
        });
        // -- pushAmbientToLight --
        /// Copies this overlay ambient color into the shared light world.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pushAmbientToLight", |_, this, ()| {
            let c = this.inner.ambient.color;
            this.state.borrow_mut().light_world.ambient =
                crate::math::Color::new(c[0], c[1], c[2], c[3]);
            Ok(())
        });
        // -- syncAmbientWithLight --
        /// Resolves overlay and light ambient colors using a named mode and writes both stores.
        /// @param | mode | string | One of `light`, `overlay`, `avg`, `max`, or `min`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("syncAmbientWithLight", |_, this, mode: String| {
            let light_color = {
                let st = this.state.borrow();
                [
                    st.light_world.ambient.r,
                    st.light_world.ambient.g,
                    st.light_world.ambient.b,
                    st.light_world.ambient.a,
                ]
            };
            let overlay_color = this.inner.ambient.color;
            let resolved = match mode.as_str() {
                "light" => light_color,
                "overlay" => overlay_color,
                "avg" => [
                    (light_color[0] + overlay_color[0]) * 0.5,
                    (light_color[1] + overlay_color[1]) * 0.5,
                    (light_color[2] + overlay_color[2]) * 0.5,
                    (light_color[3] + overlay_color[3]) * 0.5,
                ],
                "max" => [
                    light_color[0].max(overlay_color[0]),
                    light_color[1].max(overlay_color[1]),
                    light_color[2].max(overlay_color[2]),
                    light_color[3].max(overlay_color[3]),
                ],
                "min" => [
                    light_color[0].min(overlay_color[0]),
                    light_color[1].min(overlay_color[1]),
                    light_color[2].min(overlay_color[2]),
                    light_color[3].min(overlay_color[3]),
                ],
                _ => {
                    return Err(LuaError::RuntimeError(
                        "Overlay:syncAmbientWithLight invalid mode; expected 'light', 'overlay', 'avg', 'max', or 'min'"
                            .to_string(),
                    ))
                }
            };
            this.inner.ambient.color = resolved;
            this.state.borrow_mut().light_world.ambient =
                crate::math::Color::new(resolved[0], resolved[1], resolved[2], resolved[3]);
            Ok(())
        });
        // -- setTimeOfDay --
        /// Sets the overlay time-of-day value used by ambient effects.
        /// @param | v | number | Time-of-day value stored on the overlay ambient state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTimeOfDay", |_, this, v: f32| {
            this.inner.ambient.time_of_day = v;
            Ok(())
        });
        // -- getTimeOfDay --
        /// Returns the overlay time-of-day value.
        /// @return | number | Current time-of-day value.
        methods.add_method("getTimeOfDay", |_, this, ()| {
            Ok(this.inner.ambient.time_of_day)
        });
        // -- setFogEnabled --
        /// Enables or disables overlay fog rendering.
        /// @param | v | boolean | New fog enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFogEnabled", |_, this, v: bool| {
            this.inner.fog.enabled = v;
            Ok(())
        });
        // -- isFogEnabled --
        /// Returns whether overlay fog rendering is enabled.
        /// @return | boolean | True when fog rendering is enabled.
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog.enabled));
        // -- setFogDensity --
        /// Sets overlay fog density.
        /// @param | v | number | Fog density value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFogDensity", |_, this, v: f32| {
            this.inner.fog.density = v;
            Ok(())
        });
        // -- getFogDensity --
        /// Returns overlay fog density.
        /// @return | number | Current fog density.
        methods.add_method("getFogDensity", |_, this, ()| Ok(this.inner.fog.density));
        // -- setFogColor --
        /// Sets overlay fog RGBA color.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional alpha channel, defaulting to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.fog.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        // -- getFogColor --
        /// Returns overlay fog RGBA color.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setHeatHazeEnabled --
        /// Enables or disables overlay heat haze rendering.
        /// @param | v | boolean | New heat haze enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setHeatHazeEnabled", |_, this, v: bool| {
            this.inner.heat_haze.enabled = v;
            Ok(())
        });
        // -- isHeatHazeEnabled --
        /// Returns whether overlay heat haze rendering is enabled.
        /// @return | boolean | True when heat haze rendering is enabled.
        methods.add_method("isHeatHazeEnabled", |_, this, ()| {
            Ok(this.inner.heat_haze.enabled)
        });
        // -- setHeatHazeIntensity --
        /// Sets overlay heat haze intensity.
        /// @param | v | number | Heat haze intensity value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setHeatHazeIntensity", |_, this, v: f32| {
            this.inner.heat_haze.intensity = v;
            Ok(())
        });
        // -- getHeatHazeIntensity --
        /// Returns overlay heat haze intensity.
        /// @return | number | Current heat haze intensity.
        methods.add_method("getHeatHazeIntensity", |_, this, ()| {
            Ok(this.inner.heat_haze.intensity)
        });
        // -- setVignetteEnabled --
        /// Enables or disables overlay vignette rendering.
        /// @param | v | boolean | New vignette enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setVignetteEnabled", |_, this, v: bool| {
            this.inner.vignette.enabled = v;
            Ok(())
        });
        // -- isVignetteEnabled --
        /// Returns whether overlay vignette rendering is enabled.
        /// @return | boolean | True when vignette rendering is enabled.
        methods.add_method("isVignetteEnabled", |_, this, ()| {
            Ok(this.inner.vignette.enabled)
        });
        // -- setVignetteStrength --
        /// Sets overlay vignette strength.
        /// @param | v | number | Vignette strength value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setVignetteStrength", |_, this, v: f32| {
            this.inner.vignette.strength = v;
            Ok(())
        });
        // -- getVignetteStrength --
        /// Returns overlay vignette strength.
        /// @return | number | Current vignette strength.
        methods.add_method("getVignetteStrength", |_, this, ()| {
            Ok(this.inner.vignette.strength)
        });
        // -- setFilmGrainEnabled --
        /// Enables or disables overlay film grain rendering.
        /// @param | v | boolean | New film grain enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFilmGrainEnabled", |_, this, v: bool| {
            this.inner.film_grain.enabled = v;
            Ok(())
        });
        // -- isFilmGrainEnabled --
        /// Returns whether overlay film grain rendering is enabled.
        /// @return | boolean | True when film grain rendering is enabled.
        methods.add_method("isFilmGrainEnabled", |_, this, ()| {
            Ok(this.inner.film_grain.enabled)
        });
        // -- setFilmGrainIntensity --
        /// Sets overlay film grain intensity.
        /// @param | v | number | Film grain intensity value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFilmGrainIntensity", |_, this, v: f32| {
            this.inner.film_grain.intensity = v;
            Ok(())
        });
        // -- getFilmGrainIntensity --
        /// Returns overlay film grain intensity.
        /// @return | number | Current film grain intensity.
        methods.add_method("getFilmGrainIntensity", |_, this, ()| {
            Ok(this.inner.film_grain.intensity)
        });
        // -- setCloudShadows --
        /// Enables or disables overlay cloud shadow rendering.
        /// @param | v | boolean | New cloud shadow enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCloudShadows", |_, this, v: bool| {
            this.inner.clouds.enabled = v;
            Ok(())
        });
        // -- isCloudShadowsEnabled --
        /// Returns whether overlay cloud shadow rendering is enabled.
        /// @return | boolean | True when cloud shadow rendering is enabled.
        methods.add_method("isCloudShadowsEnabled", |_, this, ()| {
            Ok(this.inner.clouds.enabled)
        });
        // -- setCloudCount --
        /// Sets the overlay cloud shadow count.
        /// @param | v | integer | Cloud shadow count.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCloudCount", |_, this, v: u32| {
            this.inner.clouds.count = v;
            Ok(())
        });
        // -- getCloudCount --
        /// Returns the overlay cloud shadow count.
        /// @return | integer | Cloud shadow count.
        methods.add_method("getCloudCount", |_, this, ()| Ok(this.inner.clouds.count));
        // -- setCloudSpeed --
        /// Sets cloud shadow movement speed.
        /// @param | v | number | Cloud speed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCloudSpeed", |_, this, v: f32| {
            this.inner.clouds.speed = v;
            Ok(())
        });
        // -- getCloudSpeed --
        /// Returns cloud shadow movement speed.
        /// @return | number | Cloud speed value.
        methods.add_method("getCloudSpeed", |_, this, ()| Ok(this.inner.clouds.speed));
        // -- setCloudScale --
        /// Sets cloud shadow scale.
        /// @param | v | number | Cloud scale value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCloudScale", |_, this, v: f32| {
            this.inner.clouds.scale = v;
            Ok(())
        });
        // -- getCloudScale --
        /// Returns cloud shadow scale.
        /// @return | number | Cloud scale value.
        methods.add_method("getCloudScale", |_, this, ()| Ok(this.inner.clouds.scale));
        // -- setCloudOpacity --
        /// Sets cloud shadow opacity.
        /// @param | v | number | Cloud opacity value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCloudOpacity", |_, this, v: f32| {
            this.inner.clouds.opacity = v;
            Ok(())
        });
        // -- getCloudOpacity --
        /// Returns cloud shadow opacity.
        /// @return | number | Cloud opacity value.
        methods.add_method("getCloudOpacity", |_, this, ()| {
            Ok(this.inner.clouds.opacity)
        });
        // -- setWeatherEnabled --
        /// Enables or disables overlay weather rendering.
        /// @param | v | boolean | New weather enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWeatherEnabled", |_, this, v: bool| {
            this.inner.weather.enabled = v;
            Ok(())
        });
        // -- isWeatherEnabled --
        /// Returns whether overlay weather rendering is enabled.
        /// @return | boolean | True when weather rendering is enabled.
        methods.add_method("isWeatherEnabled", |_, this, ()| {
            Ok(this.inner.weather.enabled)
        });
        // -- setWeather --
        /// Sets the overlay weather type by name.
        /// @param | name | string | Weather type name recognized by the engine.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWeather", |_, this, name: String| {
            this.inner.weather.weather_type = WeatherType::from_name(&name)
                .ok_or_else(|| LuaError::RuntimeError(format!("unknown weather type: {name}")))?;
            Ok(())
        });
        // -- getWeather --
        /// Returns the overlay weather type name.
        /// @return | string | Current weather type name.
        methods.add_method("getWeather", |_, this, ()| {
            Ok(this.inner.weather.weather_type.name().to_owned())
        });
        // -- setWeatherIntensity --
        /// Sets weather intensity for the current weather type.
        /// @param | v | number | Weather intensity value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWeatherIntensity", |_, this, v: f32| {
            this.inner.weather.intensity = v;
            Ok(())
        });
        // -- getWeatherIntensity --
        /// Returns weather intensity for the current weather type.
        /// @return | number | Weather intensity value.
        methods.add_method("getWeatherIntensity", |_, this, ()| {
            Ok(this.inner.weather.intensity)
        });
        // -- setWindDirection --
        /// Sets the overlay weather wind direction.
        /// @param | v | number | Wind direction value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWindDirection", |_, this, v: f32| {
            this.inner.weather.wind_direction = v;
            Ok(())
        });
        // -- getWindDirection --
        /// Returns the overlay weather wind direction.
        /// @return | number | Wind direction value.
        methods.add_method("getWindDirection", |_, this, ()| {
            Ok(this.inner.weather.wind_direction)
        });
        // -- setWindSpeed --
        /// Sets the overlay weather wind speed.
        /// @param | v | number | Wind speed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWindSpeed", |_, this, v: f32| {
            this.inner.weather.wind_speed = v;
            Ok(())
        });
        // -- getWindSpeed --
        /// Returns the overlay weather wind speed.
        /// @return | number | Wind speed value.
        methods.add_method("getWindSpeed", |_, this, ()| {
            Ok(this.inner.weather.wind_speed)
        });
        // -- setLightningColor --
        /// Sets overlay lightning RGBA color.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional alpha channel, defaulting to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setLightningColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.lightning.color = [r, g, b, a.unwrap_or(1.0)];
                Ok(())
            },
        );
        // -- getLightningColor --
        /// Returns overlay lightning RGBA color.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getLightningColor", |_, this, ()| {
            let c = this.inner.lightning.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- flash --
        /// Starts a short flash overlay with optional alpha and duration.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional alpha channel, defaulting to 1.0.
        /// @param | dur | number | Optional duration in seconds, defaulting to 0.2.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "flash",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_flash(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(0.2));
                Ok(())
            },
        );
        // -- isFlashing --
        /// Returns whether the flash overlay is active.
        /// @return | boolean | True while the flash is active.
        methods.add_method("isFlashing", |_, this, ()| Ok(this.inner.flash.active));
        // -- shake --
        /// Starts a screen shake with optional duration.
        /// @param | intensity | number | Shake intensity.
        /// @param | dur | number | Optional duration in seconds, defaulting to 0.5.
        /// @return | nil | No value is returned.
        methods.add_method_mut("shake", |_, this, (intensity, dur): (f32, Option<f32>)| {
            this.inner.trigger_shake(intensity, dur.unwrap_or(0.5));
            Ok(())
        });
        // -- isShaking --
        /// Returns whether the screen shake effect is active.
        /// @return | boolean | True while screen shake is active.
        methods.add_method("isShaking", |_, this, ()| Ok(this.inner.shake.active));
        // -- fade --
        /// Starts a fade overlay with optional alpha and duration.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional target alpha, defaulting to 1.0.
        /// @param | dur | number | Optional duration in seconds, defaulting to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "fade",
            |_, this, (r, g, b, a, dur): (f32, f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .trigger_fade(r, g, b, a.unwrap_or(1.0), dur.unwrap_or(1.0));
                Ok(())
            },
        );
        // -- isFading --
        /// Returns whether the fade overlay is active.
        /// @return | boolean | True while fade is active.
        methods.add_method("isFading", |_, this, ()| Ok(this.inner.fade.active));
        // -- render --
        /// Queues renderer commands for the overlay's current visual state.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, ()| {
            let cmds = this.inner.build_render_commands();
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        // -- drawToImage --
        /// Renders overlay state into an image object of the requested size.
        /// @param | w | integer | Target image width in pixels.
        /// @param | h | integer | Target image height in pixels.
        /// @return | Image | Image containing the overlay draw state.
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_state_to_image(w, h);
            Ok(img)
        });
        // -- setWater --
        /// Enables water distortion and sets wave amplitude, frequency, and speed.
        /// @param | amplitude | number | Water wave amplitude.
        /// @param | frequency | number | Water wave frequency.
        /// @param | speed | number | Water animation speed.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setWater",
            |_, this, (amplitude, frequency, speed): (f32, f32, f32)| {
                this.inner.water.amplitude = amplitude;
                this.inner.water.frequency = frequency;
                this.inner.water.speed = speed;
                this.inner.water.enabled = true;
                Ok(())
            },
        );
        // -- setWaterTint --
        /// Sets the water tint color and strength.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | strength | number | Tint strength.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setWaterTint",
            |_, this, (r, g, b, strength): (f32, f32, f32, f32)| {
                this.inner.water.tint_r = r;
                this.inner.water.tint_g = g;
                this.inner.water.tint_b = b;
                this.inner.water.tint_strength = strength;
                Ok(())
            },
        );
        // -- setCustomShader --
        /// Sets or clears the custom overlay shader name.
        /// @param | name | string | Optional shader name; nil clears the custom shader.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCustomShader", |_, this, name: Option<String>| {
            this.inner.custom_shader = name;
            Ok(())
        });
        // -- getWater --
        /// Returns a table describing the current water effect settings.
        /// @return | table | Water state table with enabled, wave, tint, depth, and time fields.
        methods.add_method("getWater", |lua, this, ()| {
            let w = &this.inner.water;
            let t = lua.create_table()?;
            t.set("enabled", w.enabled)?;
            t.set("amplitude", w.amplitude)?;
            t.set("frequency", w.frequency)?;
            t.set("speed", w.speed)?;
            t.set("tint_r", w.tint_r)?;
            t.set("tint_g", w.tint_g)?;
            t.set("tint_b", w.tint_b)?;
            t.set("tint_strength", w.tint_strength)?;
            t.set("depth_r", w.depth_r)?;
            t.set("depth_g", w.depth_g)?;
            t.set("depth_b", w.depth_b)?;
            t.set("depth_strength", w.depth_strength)?;
            t.set("time", w.time)?;
            Ok(t)
        });
        // -- type --
        /// Returns the Lua-visible type name for this overlay handle.
        /// @return | string | The string `LOverlay`.
        methods.add_method("type", |_, _this, ()| Ok("LOverlay"));
        // -- typeOf --
        /// Returns whether this overlay handle matches a supported type name.
        /// @param | name | string | Type name to compare against `Overlay` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _this, name: String| {
            Ok(name == "Object" || name == "Overlay")
        });
    }
}
/// Lua-side handle for a timed screen transition effect.
pub struct LuaScreenTransition {
    /// Transition kind, timer, direction, and RGBA color.
    inner: crate::effect::ScreenTransition,
}
/// Provides Lua methods for playing and inspecting screen transitions.
impl mlua::UserData for LuaScreenTransition {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- play --
        /// Starts this screen transition forward from its current state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("play", |_, this, ()| {
            this.inner.play();
            Ok(())
        });
        // -- reverse --
        /// Starts this screen transition in reverse from its current state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reverse", |_, this, ()| {
            this.inner.reverse();
            Ok(())
        });
        // -- update --
        /// Advances this transition timer and returns whether it remains active.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True when the transition is still active after the update.
        methods.add_method_mut("update", |_, this, dt: f32| Ok(this.inner.update(dt)));
        // -- progress --
        /// Returns normalized transition progress.
        /// @return | number | Progress value between the transition start and end.
        methods.add_method("progress", |_, this, ()| Ok(this.inner.progress()));
        // -- isActive --
        /// Returns whether the transition is currently active.
        /// @return | boolean | True when the transition is active.
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));
        // -- isDone --
        /// Returns whether the transition has finished.
        /// @return | boolean | True when the transition is complete.
        methods.add_method("isDone", |_, this, ()| Ok(this.inner.is_done()));
        // -- kind --
        /// Returns the transition kind name.
        /// @return | string | Transition kind name.
        methods.add_method("kind", |_, this, ()| Ok(this.inner.kind.name()));
        // -- color --
        /// Returns the transition RGBA color.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("color", |_, this, ()| {
            let c = this.inner.color;
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setColor --
        /// Sets the transition RGBA color from a numeric array table.
        /// @param | color | table | Numeric color table using indices 1 through 4.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setColor", |_, this, ct: mlua::Table| {
            this.inner.color = [
                ct.get::<_, f32>(1).unwrap_or(0.0),
                ct.get::<_, f32>(2).unwrap_or(0.0),
                ct.get::<_, f32>(3).unwrap_or(0.0),
                ct.get::<_, f32>(4).unwrap_or(1.0),
            ];
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this transition handle.
        /// @return | string | The string `LScreenTransition`.
        methods.add_method("type", |_, _, ()| Ok("LScreenTransition"));
        // -- typeOf --
        /// Returns whether this transition handle matches a supported type name.
        /// @param | name | string | Type name to compare against `ScreenTransition` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ScreenTransition" || name == "Object")
        });
    }
}
/// Registers `lurek.effect` constructors and effect state controls.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newEffect --
    /// Creates a built-in post-processing effect by type name.
    /// @param | type_name | string | Built-in effect type name such as `blur`, `bloom`, or `crt`.
    /// @return | LPostFxEffect | New post-processing effect handle.
    tbl.set(
        "newEffect",
        lua.create_function(|lua, type_name: String| {
            let effect_type = PostFxEffectType::from_name(&type_name).ok_or_else(|| {
                LuaError::RuntimeError(format!("unknown effect type: {type_name}"))
            })?;
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new(effect_type)))
        })?,
    )?;
    // -- newCustomEffect --
    /// Creates a custom post-processing effect that references an existing shader id.
    /// @param | shader_id | integer | Renderer shader identifier used for the custom effect.
    /// @return | LPostFxEffect | New custom post-processing effect handle.
    tbl.set(
        "newCustomEffect",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new_custom(
                shader_id,
            )))
        })?,
    )?;
    let s = state.clone();
    // -- newStack --
    /// Creates a post-processing stack using optional dimensions or the current window size.
    /// @param | w | integer | Optional stack width in pixels.
    /// @param | h | integer | Optional stack height in pixels.
    /// @return | LPostFxStack | New post-processing stack handle.
    tbl.set(
        "newStack",
        lua.create_function(move |lua, (w, h): (Option<u32>, Option<u32>)| {
            let (default_w, default_h) = {
                let s = s.borrow();
                (s.window_width, s.window_height)
            };
            let w = w.unwrap_or(default_w);
            let h = h.unwrap_or(default_h);
            lua.create_userdata(LuaPostFxStack {
                inner: PostFxStack::new(w, h),
                effects: Vec::new(),
                stack_id: NEXT_STACK_ID.fetch_add(1, Ordering::Relaxed),
                state: Rc::clone(&s),
                feedback_factor: 0.0,
            })
        })?,
    )?;
    let s = state.clone();
    // -- newPresetStack --
    /// Creates a named preset post-processing stack with optional dimensions.
    /// @param | name | string | Preset stack name.
    /// @param | w | integer | Optional stack width in pixels.
    /// @param | h | integer | Optional stack height in pixels.
    /// @return | LPostFxStack | New preset post-processing stack handle.
    tbl.set(
        "newPresetStack",
        lua.create_function(
            move |lua, (name, w, h): (String, Option<u32>, Option<u32>)| {
                let (default_w, default_h) = {
                    let borrow = s.borrow();
                    (borrow.window_width, borrow.window_height)
                };
                let w = w.unwrap_or(default_w);
                let h = h.unwrap_or(default_h);
                let preset = build_preset(&name, w, h)
                    .ok_or_else(|| LuaError::RuntimeError(format!("unknown preset '{}'", name)))?;
                let effects: Vec<Rc<RefCell<PostFxEffect>>> = preset
                    .effects
                    .into_iter()
                    .map(|e| Rc::new(RefCell::new(e)))
                    .collect();
                lua.create_userdata(LuaPostFxStack {
                    inner: preset.stack,
                    effects,
                    stack_id: NEXT_STACK_ID.fetch_add(1, Ordering::Relaxed),
                    state: Rc::clone(&s),
                    feedback_factor: 0.0,
                })
            },
        )?,
    )?;
    // -- newPass --
    /// Creates a custom post-processing pass from an existing shader id.
    /// @param | shader_id | integer | Renderer shader identifier used for the pass.
    /// @return | LPostFxEffect | New custom post-processing effect handle.
    tbl.set(
        "newPass",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect::from_owned(PostFxEffect::new_custom(
                shader_id,
            )))
        })?,
    )?;
    // -- getEffectTypes --
    /// Returns all built-in post-processing effect type names.
    /// @return | table | Array table of built-in effect type strings.
    tbl.set(
        "getEffectTypes",
        lua.create_function(|_, ()| Ok(PostFxEffectType::built_in_names()))?,
    )?;
    // -- newImageEffect --
    /// Creates an image effect chain from no arguments, a type name and optional parameters, or a chain table.
    /// @param | args | LuaValue | Optional effect type string plus parameter table, or an array table of effect entries.
    /// @return | LImageEffect | New image effect chain handle.
    tbl.set(
        "newImageEffect",
        lua.create_function(|lua, args: LuaMultiValue| {
            let mut ie = ImageEffect::new("");
            match args.iter().next() {
                None => {}
                Some(LuaValue::String(s)) => {
                    let name = s.to_str().map_err(LuaError::external)?.to_string();
                    let et = PostFxEffectType::from_name(&name).ok_or_else(|| {
                        LuaError::RuntimeError(format!("unknown effect type: {name}"))
                    })?;
                    let mut eff = PostFxEffect::new(et);
                    if let Some(LuaValue::Table(params)) = args.iter().nth(1) {
                        for (k, v) in params.clone().pairs::<String, f32>().flatten() {
                            eff.set_parameter(&k, v);
                        }
                    }
                    ie.add_effect(eff);
                }
                Some(LuaValue::Table(chain)) => {
                    for entry in chain.clone().sequence_values::<LuaTable>() {
                        let entry = entry?;
                        let name: String = entry
                            .get("type")
                            .or_else(|_| entry.get(1))
                            .unwrap_or_default();
                        let et = PostFxEffectType::from_name(&name).ok_or_else(|| {
                            LuaError::RuntimeError(format!("unknown effect type: {name}"))
                        })?;
                        let mut eff = PostFxEffect::new(et);
                        for (k, v) in entry.pairs::<String, LuaValue>().flatten() {
                            if k != "type" {
                                if let LuaValue::Number(n) = v {
                                    eff.set_parameter(&k, n as f32);
                                } else if let LuaValue::Integer(i) = v {
                                    eff.set_parameter(&k, i as f32);
                                }
                            }
                        }
                        ie.add_effect(eff);
                    }
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "newImageEffect: invalid arguments".to_string(),
                    ))
                }
            }
            lua.create_userdata(LuaImageEffect { inner: ie })
        })?,
    )?;
    let s = state.clone();
    // -- newOverlay --
    /// Creates an overlay controller for screen effects using optional dimensions.
    /// @param | w | integer | Optional overlay width in pixels, defaulting to 800.
    /// @param | h | integer | Optional overlay height in pixels, defaulting to 600.
    /// @return | LOverlay | New overlay handle.
    tbl.set(
        "newOverlay",
        lua.create_function(move |lua, (w, h): (Option<u32>, Option<u32>)| {
            let width = w.unwrap_or(800);
            let height = h.unwrap_or(600);
            lua.create_userdata(LuaOverlay {
                inner: Overlay::new(width, height),
                state: s.clone(),
            })
        })?,
    )?;
    // -- newTransition --
    /// Creates a timed screen transition with optional kind, duration, and color.
    /// @param | kind | string | Optional transition kind name, defaulting to `fade`.
    /// @param | duration | number | Optional duration in seconds, defaulting to 1.0.
    /// @param | color_tbl | table | Optional numeric RGBA table using indices 1 through 4.
    /// @return | LScreenTransition | New screen transition handle.
    tbl.set("newTransition", lua.create_function(move |lua, (kind, duration, color_tbl): (Option<String>, Option<f32>, Option<LuaTable>)| {
            let k = crate::effect::TransitionKind::from_str(
                kind.as_deref().unwrap_or("fade"),
            );
            let dur = duration.unwrap_or(1.0);
            let color = if let Some(ct) = color_tbl {
                [
                    ct.get::<_, f32>(1).unwrap_or(0.0),
                    ct.get::<_, f32>(2).unwrap_or(0.0),
                    ct.get::<_, f32>(3).unwrap_or(0.0),
                    ct.get::<_, f32>(4).unwrap_or(1.0),
                ]
            } else {
                [0.0, 0.0, 0.0, 1.0]
            };
            lua.create_userdata(LuaScreenTransition {
                inner: crate::effect::ScreenTransition::new(k, dur, color),
            })
        })?,
    )?;
    let s = state.clone();
    // -- setShaderErrorDisplay --
    /// Enables or disables renderer shader error display overlays.
    /// @param | enabled | boolean | New shader error display flag.
    /// @return | nil | No value is returned.
    tbl.set(
        "setShaderErrorDisplay",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().shader_error_display_enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getShaderErrorDisplay --
    /// Returns whether renderer shader error display overlays are enabled.
    /// @return | boolean | True when shader error display is enabled.
    tbl.set(
        "getShaderErrorDisplay",
        lua.create_function(move |_, ()| Ok(s.borrow().shader_error_display_enabled))?,
    )?;
    lurek.set("effect", tbl)?;
    Ok(())
}
