//! Lua API bindings for the `luna.postfx.*` post-processing effects module.
//!
//! Provides `PostFxEffect` and `PostFxStack` UserData types with factory
//! functions for creating built-in effects, custom shader passes, and
//! effect stacks that manage ping-pong canvas post-processing pipelines.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::postfx::{PostFxEffect, PostFxEffectType, PostFxStack};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaPostFxEffect
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a single post-processing effect.
///
/// # Fields
/// - `inner` — `Rc<RefCell<PostFxEffect>>`.
#[derive(Clone)]
pub(crate) struct LuaPostFxEffect {
    inner: Rc<RefCell<PostFxEffect>>,
}

impl LunaType for LuaPostFxEffect {
    const TYPE_NAME: &'static str = "PostFxEffect";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaPostFxEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // setParameter(name, value)
        /// Sets the parameter.
        /// @param name : string
        /// @param value : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `value` — `number`.
        methods.add_method("setParameter", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set_parameter(name, value);
            Ok(())
        });

        // getParameter(name, default?) -> number
        methods.add_method(
            "getParameter",
            |_, this, (name, default): (String, Option<f32>)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_parameter(&name, default.unwrap_or(0.0)))
            },
        );

        // hasParameter(name) -> boolean
        /// Returns `true` if parameter.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.borrow().has_parameter(&name))
        });

        // getParameterNames() -> table<string>
        /// Returns the parameter names.
        /// @return any
        ///
        /// # Returns
        /// The current parameter names.
        methods.add_method("getParameterNames", |lua, this, ()| {
            let names = this.inner.borrow().get_parameter_names();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // getType() -> string
        /// Returns the effect type.
        /// @return any
        ///
        /// # Returns
        /// The current effect type.
        methods.add_method("getEffectType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });

        // isBuiltIn() -> boolean
        /// Returns `true` if built in.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isBuiltIn", |_, this, ()| {
            Ok(this.inner.borrow().is_built_in())
        });

        // isEnabled() -> boolean
        /// Returns `true` if enabled.
        /// @return any
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.borrow().enabled));

        // setEnabled(enabled)
        /// Sets the enabled.
        /// @param enabled : boolean
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().enabled = enabled;
            Ok(())
        });

        // --- Convenience setters ---

        // setThreshold(value) — bloom bright-pass threshold
        /// Sets the threshold.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setThreshold", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("threshold", value);
            Ok(())
        });

        // setIntensity(value) — bloom/godrays intensity
        /// Sets the intensity.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setIntensity", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("intensity", value);
            Ok(())
        });

        // setScanlineStrength(value) — CRT scanline visibility
        /// Sets the scanline strength.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setScanlineStrength", |_, this, value: f32| {
            this.inner
                .borrow_mut()
                .set_parameter("scanline_strength", value);
            Ok(())
        });

        // setRadius(value) — blur radius
        /// Sets the radius.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setRadius", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("radius", value);
            Ok(())
        });

        // setStrength(value) — vignette/blur strength
        /// Sets the strength.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setStrength", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("strength", value);
            Ok(())
        });

        // setOffset(value) — chromatic aberration offset
        /// Sets the offset.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setOffset", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("offset", value);
            Ok(())
        });

        // setBrightness(value) — colour grading brightness
        /// Sets the brightness.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setBrightness", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("brightness", value);
            Ok(())
        });

        // setContrast(value) — colour grading contrast
        /// Sets the contrast.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setContrast", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("contrast", value);
            Ok(())
        });

        // setSaturation(value) — colour grading saturation
        /// Sets the saturation.
        /// @param value : number
        ///
        /// # Parameters
        /// - `value` — `number`.
        methods.add_method("setSaturation", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("saturation", value);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaPostFxStack
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a post-processing effect stack.
#[derive(Clone)]
struct LuaPostFxStack {
    inner: Rc<RefCell<PostFxStack>>,
    /// Local effect storage — each effect gets an incrementing index.
    effects: Rc<RefCell<Vec<Rc<RefCell<PostFxEffect>>>>>,
}

impl LunaType for LuaPostFxStack {
    const TYPE_NAME: &'static str = "PostFxStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // add(effect) — append an effect to the end of the chain
        /// Adds an entry to the collection.
        /// @param effect : PostFxEffect
        ///
        /// # Parameters
        /// - `effect` — `userdata`.
        methods.add_method("add", |_, this, effect: LuaAnyUserData| {
            let effect: LuaPostFxEffect = effect.borrow::<LuaPostFxEffect>()?.clone();
            let idx = {
                let mut effects = this.effects.borrow_mut();
                let idx = effects.len();
                effects.push(effect.inner.clone());
                idx
            };
            this.inner.borrow_mut().add(idx);
            Ok(())
        });

        // remove(effect) -> boolean
        /// Removes the entry from the collection.
        /// @param effect : PostFxEffect
        /// @return boolean
        ///
        /// # Parameters
        /// - `effect` — `userdata`.
        methods.add_method("remove", |_, this, effect: LuaAnyUserData| {
            let effect: LuaPostFxEffect = effect.borrow::<LuaPostFxEffect>()?.clone();
            let effect_idx = this
                .effects
                .borrow()
                .iter()
                .position(|e| Rc::ptr_eq(e, &effect.inner));
            if let Some(idx) = effect_idx {
                Ok(this.inner.borrow_mut().remove(idx))
            } else {
                Ok(false)
            }
        });

        // insert(position, effect) — insert at 1-based index
        methods.add_method(
            "insert",
            |_, this, (position, effect): (usize, LuaAnyUserData)| {
                let effect: LuaPostFxEffect = effect.borrow::<LuaPostFxEffect>()?.clone();
                let idx = {
                    let mut effects = this.effects.borrow_mut();
                    let idx = effects.len();
                    effects.push(effect.inner.clone());
                    idx
                };
                this.inner.borrow_mut().insert(position, idx);
                Ok(())
            },
        );

        // setEnabled(effect, enabled)
        methods.add_method(
            "setEffectEnabled",
            |_, this, (effect, enabled): (LuaAnyUserData, bool)| {
                let effect: LuaPostFxEffect = effect.borrow::<LuaPostFxEffect>()?.clone();
                let effect_idx = this
                    .effects
                    .borrow()
                    .iter()
                    .position(|e| Rc::ptr_eq(e, &effect.inner));
                if let Some(idx) = effect_idx {
                    this.inner.borrow_mut().set_enabled(idx, enabled);
                }
                Ok(())
            },
        );

        // isEnabled(effect) -> boolean
        /// Returns `true` if effect enabled.
        /// @param effect : PostFxEffect
        /// @return any
        ///
        /// # Parameters
        /// - `effect` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEffectEnabled", |_, this, effect: LuaAnyUserData| {
            let effect: LuaPostFxEffect = effect.borrow::<LuaPostFxEffect>()?.clone();
            let effect_idx = this
                .effects
                .borrow()
                .iter()
                .position(|e| Rc::ptr_eq(e, &effect.inner));
            Ok(effect_idx
                .map(|idx| this.inner.borrow().is_enabled(idx))
                .unwrap_or(false))
        });

        // getEffectCount() -> int
        /// Returns the effect count.
        /// @return any
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current effect count.
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.borrow().get_effect_count())
        });

        // getEffect(index) -> Effect | nil
        /// Returns the effect.
        /// @param index : integer
        /// @return any
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current effect.
        methods.add_method("getEffect", |_, this, index: usize| {
            let stack = this.inner.borrow();
            if let Some(effect_idx) = stack.get_effect(index) {
                let effects = this.effects.borrow();
                if effect_idx < effects.len() {
                    return Ok(Some(LuaPostFxEffect {
                        inner: effects[effect_idx].clone(),
                    }));
                }
            }
            Ok(None)
        });

        // getEnabledEffects() -> table of Effects
        /// Returns the enabled effects.
        /// @return any
        ///
        /// # Returns
        /// The current enabled effects.
        methods.add_method("getEnabledEffects", |lua, this, ()| {
            let stack = this.inner.borrow();
            let effects = this.effects.borrow();
            let enabled = stack.enabled_effects();
            let table = lua.create_table()?;
            for (i, &idx) in enabled.iter().enumerate() {
                if idx < effects.len() {
                    table.set(
                        i + 1,
                        LuaPostFxEffect {
                            inner: effects[idx].clone(),
                        },
                    )?;
                }
            }
            Ok(table)
        });

        // resize(width, height) — recreate internal canvases at new resolution
        /// Resize on this PostFxStack.
        /// @param w : integer
        /// @param h : integer
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });

        // getWidth() -> int
        /// Returns the width.
        /// @return any
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // getHeight() -> int
        /// Returns the height.
        /// @return any
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // getDimensions() -> int, int
        /// Returns the dimensions.
        /// @return any
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });

        // isCapturing() -> boolean
        /// Returns `true` if capturing.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isCapturing", |_, this, ()| {
            Ok(this.inner.borrow().capturing)
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.postfx.*` API. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let postfx = lua.create_table()?;

    // luna.postfx.newEffect(name) -> PostFxEffect
    /// New effect.
    ///
    /// @param name : string
    /// @return any
    postfx.set(
        "newEffect",
        lua.create_function(|_, name: String| {
            let effect_type = PostFxEffectType::from_name(&name).ok_or_else(|| {
                mlua::Error::RuntimeError(format!(
                    "Unknown effect type '{}'. Valid types: bloom, blur, crt, godrays, vignette, colourgrade, chromatic",
                    name
                ))
            })?;
            Ok(LuaPostFxEffect {
                inner: Rc::new(RefCell::new(PostFxEffect::new(effect_type))),
            })
        })?,
    )?;

    // luna.postfx.newPass(shaderId) -> PostFxEffect (custom shader pass)
    /// New pass.
    ///
    /// @param shader_id : integer
    /// @return any
    postfx.set(
        "newPass",
        lua.create_function(|_, shader_id: usize| {
            Ok(LuaPostFxEffect {
                inner: Rc::new(RefCell::new(PostFxEffect::new_custom(shader_id))),
            })
        })?,
    )?;

    // luna.postfx.newStack(width?, height?) -> PostFxStack
    /// New stack.
    ///
    /// @param w : integer?
    /// @param h : integer?
    /// @return any
    postfx.set(
        "newStack",
        lua.create_function(|_, (w, h): (Option<u32>, Option<u32>)| {
            Ok(LuaPostFxStack {
                inner: Rc::new(RefCell::new(PostFxStack::new(
                    w.unwrap_or(800),
                    h.unwrap_or(600),
                ))),
                effects: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;

    // luna.postfx.getEffectTypes() -> table of valid effect type names
    /// Returns the effect types.
    ///
    /// @return any
    postfx.set(
        "getEffectTypes",
        lua.create_function(|lua, ()| {
            let types = lua.create_table()?;
            let names = [
                "bloom",
                "blur",
                "crt",
                "godrays",
                "vignette",
                "colourgrade",
                "chromatic",
            ];
            for (i, name) in names.iter().enumerate() {
                types.set(i + 1, *name)?;
            }
            Ok(types)
        })?,
    )?;

    /// Postfx on this PostFxStack.
    ///
    /// # Returns
    /// The result.
    luna.set("postfx", postfx)?;

    Ok(())
}
