//! Lua API bindings for the `luna.postfx.*` post-processing effects module.
//!
//! Provides `PostFxEffect` and `PostFxStack` UserData types with factory
//! functions for creating built-in effects, custom shader passes, and
//! effect stacks that manage ping-pong canvas post-processing pipelines.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::graphics::postfx::{PostFxEffect, PostFxEffectType, PostFxStack};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaPostFxEffect
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a single post-processing effect.
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
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.borrow().has_parameter(&name))
        });

        // getParameterNames() -> table<string>
        methods.add_method("getParameterNames", |lua, this, ()| {
            let names = this.inner.borrow().get_parameter_names();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // getType() -> string
        methods.add_method("getEffectType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });

        // isBuiltIn() -> boolean
        methods.add_method("isBuiltIn", |_, this, ()| {
            Ok(this.inner.borrow().is_built_in())
        });

        // isEnabled() -> boolean
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.borrow().enabled));

        // setEnabled(enabled)
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().enabled = enabled;
            Ok(())
        });

        // --- Convenience setters ---

        // setThreshold(value) — bloom bright-pass threshold
        methods.add_method("setThreshold", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("threshold", value);
            Ok(())
        });

        // setIntensity(value) — bloom/godrays intensity
        methods.add_method("setIntensity", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("intensity", value);
            Ok(())
        });

        // setScanlineStrength(value) — CRT scanline visibility
        methods.add_method("setScanlineStrength", |_, this, value: f32| {
            this.inner
                .borrow_mut()
                .set_parameter("scanline_strength", value);
            Ok(())
        });

        // setRadius(value) — blur radius
        methods.add_method("setRadius", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("radius", value);
            Ok(())
        });

        // setStrength(value) — vignette/blur strength
        methods.add_method("setStrength", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("strength", value);
            Ok(())
        });

        // setOffset(value) — chromatic aberration offset
        methods.add_method("setOffset", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("offset", value);
            Ok(())
        });

        // setBrightness(value) — colour grading brightness
        methods.add_method("setBrightness", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("brightness", value);
            Ok(())
        });

        // setContrast(value) — colour grading contrast
        methods.add_method("setContrast", |_, this, value: f32| {
            this.inner.borrow_mut().set_parameter("contrast", value);
            Ok(())
        });

        // setSaturation(value) — colour grading saturation
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
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.borrow().get_effect_count())
        });

        // getEffect(index) -> Effect | nil
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
        methods.add_method("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });

        // getWidth() -> int
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // getHeight() -> int
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // getDimensions() -> int, int
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });

        // isCapturing() -> boolean
        methods.add_method("isCapturing", |_, this, ()| {
            Ok(this.inner.borrow().capturing)
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.postfx.*` API.
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
    postfx.set(
        "newPass",
        lua.create_function(|_, shader_id: usize| {
            Ok(LuaPostFxEffect {
                inner: Rc::new(RefCell::new(PostFxEffect::new_custom(shader_id))),
            })
        })?,
    )?;

    // luna.postfx.newStack(width?, height?) -> PostFxStack
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

    luna.set("postfx", postfx)?;

    Ok(())
}
