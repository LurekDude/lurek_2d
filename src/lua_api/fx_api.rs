//! `luna.fx` — Composable visual effects: post-processing pipeline and screen overlays.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::fx::{ImageEffect, Overlay, PostFxEffect, PostFxEffectType, PostFxStack};

// -------------------------------------------------------------------------------
// LuaPostFxEffect UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PostFxEffect`].
pub struct LuaPostFxEffect {
    inner: PostFxEffect,
}

impl LuaUserData for LuaPostFxEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getTypeName --
        /// Returns the display name of this effect type.
        /// @return string
        methods.add_method("getTypeName", |_, this, ()| {
            Ok(this.inner.get_type_name().to_string())
        });

        // -- isBuiltIn --
        /// Returns true if this is a built-in effect, false if custom.
        /// @return boolean
        methods.add_method("isBuiltIn", |_, this, ()| Ok(this.inner.is_built_in()));

        // -- isEnabled --
        /// Returns whether this effect is currently active.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.enabled));

        // -- setEnabled --
        /// Enables or disables this effect.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.enabled = enabled;
            Ok(())
        });

        // -- setParameter --
        /// Sets a named float parameter on this effect.
        /// @param name : string
        /// @param value : number
        /// @return nil
        methods.add_method_mut("setParameter", |_, this, (name, value): (String, f32)| {
            this.inner.set_parameter(name, value);
            Ok(())
        });

        // -- getParameter --
        /// Returns a named parameter value, or the default if not set.
        /// @param name : string
        /// @param default : number
        /// @return number
        methods.add_method("getParameter", |_, this, (name, default): (String, f32)| {
            Ok(this.inner.get_parameter(&name, default))
        });

        // -- hasParameter --
        /// Returns true if the named parameter exists on this effect.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.has_parameter(&name))
        });

        // -- getParameterNames --
        /// Returns a list of all parameter names on this effect.
        /// @return table
        methods.add_method("getParameterNames", |_, this, ()| {
            Ok(this.inner.get_parameter_names())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPostFxStack UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PostFxStack`].
pub struct LuaPostFxStack {
    inner: PostFxStack,
}

impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Appends an effect index to the end of the pipeline.
        /// @param effect_idx : integer
        /// @return nil
        methods.add_method_mut("add", |_, this, effect_idx: usize| {
            this.inner.add(effect_idx);
            Ok(())
        });

        // -- remove --
        /// Removes an effect index from the pipeline.
        /// @param effect_idx : integer
        /// @return boolean
        methods.add_method_mut("remove", |_, this, effect_idx: usize| {
            Ok(this.inner.remove(effect_idx))
        });

        // -- insert --
        /// Inserts an effect index at a specific position in the pipeline.
        /// @param position : integer
        /// @param effect_idx : integer
        /// @return nil
        methods.add_method_mut(
            "insert",
            |_, this, (position, effect_idx): (usize, usize)| {
                this.inner.insert(position, effect_idx);
                Ok(())
            },
        );

        // -- setEnabled --
        /// Enables or disables the effect at the given index.
        /// @param effect_idx : integer
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut(
            "setEnabled",
            |_, this, (effect_idx, enabled): (usize, bool)| {
                this.inner.set_enabled(effect_idx, enabled);
                Ok(())
            },
        );

        // -- isEnabled --
        /// Returns whether the effect at the given index is enabled.
        /// @param effect_idx : integer
        /// @return boolean
        methods.add_method("isEnabled", |_, this, effect_idx: usize| {
            Ok(this.inner.is_enabled(effect_idx))
        });

        // -- getEffectCount --
        /// Returns the number of effects in the pipeline.
        /// @return integer
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.get_effect_count())
        });

        // -- getEffect --
        /// Returns the effect index at the given pipeline position, or nil.
        /// @param index : integer
        /// @return integer?
        methods.add_method("getEffect", |_, this, index: usize| {
            Ok(this.inner.get_effect(index))
        });

        // -- getEnabledEffects --
        /// Returns a list of currently enabled effect indices.
        /// @return table
        methods.add_method("getEnabledEffects", |_, this, ()| {
            Ok(this.inner.enabled_effects())
        });

        // -- getWidth --
        /// Returns the width of the render target.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));

        // -- getHeight --
        /// Returns the height of the render target.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));

        // -- getDimensions --
        /// Returns width and height of the render target.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- resize --
        /// Resizes the render target to the given dimensions.
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });

        // -- len --
        /// Returns the total number of effect slots in the pipeline.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));

        // -- isEmpty --
        /// Returns true if the pipeline has no effect slots.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));

        // -- clear --
        /// Removes all effects from the pipeline.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaImageEffect UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ImageEffect`].
pub struct LuaImageEffect {
    inner: ImageEffect,
}

impl LuaUserData for LuaImageEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addEffect --
        /// Appends a post-processing effect to this image effect chain.
        /// @param effect : PostFxEffect
        /// @return nil
        methods.add_method_mut("addEffect", |_, this, effect: LuaAnyUserData| {
            let borrowed = effect.borrow::<LuaPostFxEffect>()?;
            this.inner.add_effect(borrowed.inner.clone());
            Ok(())
        });

        // -- removeByIndex --
        /// Removes the effect at the given index from the chain.
        /// @param idx : integer
        /// @return boolean
        methods.add_method_mut("removeByIndex", |_, this, idx: usize| {
            Ok(this.inner.remove_by_index(idx))
        });

        // -- removeByName --
        /// Removes the first effect matching the given type name.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("removeByName", |_, this, name: String| {
            Ok(this.inner.remove_by_name(&name))
        });

        // -- clear --
        /// Removes all effects from the chain.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- getEffectCount --
        /// Returns the number of effects in the chain.
        /// @return integer
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.effect_count())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaOverlay UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`Overlay`].
pub struct LuaOverlay {
    inner: Overlay,
}

impl LuaUserData for LuaOverlay {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances all overlay subsystems by the given delta time.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- triggerFlash --
        /// Triggers a screen-wide colour flash effect.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerFlash",
            |_, this, (r, g, b, a, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_flash(r, g, b, a, duration);
                Ok(())
            },
        );

        // -- triggerShake --
        /// Triggers a screen shake effect with the given intensity and duration.
        /// @param intensity : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerShake",
            |_, this, (intensity, duration): (f32, f32)| {
                this.inner.trigger_shake(intensity, duration);
                Ok(())
            },
        );

        // -- triggerFade --
        /// Triggers a screen fade effect to the given colour and alpha.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param target_alpha : number
        /// @param duration : number
        /// @return nil
        methods.add_method_mut(
            "triggerFade",
            |_, this, (r, g, b, target_alpha, duration): (f32, f32, f32, f32, f32)| {
                this.inner.trigger_fade(r, g, b, target_alpha, duration);
                Ok(())
            },
        );

        // -- triggerLightning --
        /// Triggers a lightning flash effect.
        /// @return nil
        methods.add_method_mut("triggerLightning", |_, this, ()| {
            this.inner.trigger_lightning();
            Ok(())
        });

        // -- getShakeOffset --
        /// Returns the current shake displacement as x, y.
        /// @return number, number
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.get_shake_offset())
        });

        // -- isActive --
        /// Returns true if any overlay subsystem is currently active.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| Ok(this.inner.is_active()));

        // -- clear --
        /// Resets all overlay subsystems to their default inactive state.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- resize --
        /// Resizes the overlay to match new window dimensions.
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        methods.add_method_mut("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.resize(w, h);
            Ok(())
        });

        // -- getWidth --
        /// Returns the overlay width.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.get_width()));

        // -- getHeight --
        /// Returns the overlay height.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.get_height()));

        // -- getDimensions --
        /// Returns the overlay width and height.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- getFlashAlpha --
        /// Returns the current flash overlay alpha value.
        /// @return number
        methods.add_method("getFlashAlpha", |_, this, ()| {
            Ok(this.inner.get_flash_alpha())
        });

        // -- getLightningAlpha --
        /// Returns the current lightning overlay alpha value.
        /// @return number
        methods.add_method("getLightningAlpha", |_, this, ()| {
            Ok(this.inner.get_lightning_alpha())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.fx` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newEffect --
    /// Creates a new built-in post-processing effect by type name.
    /// @param type_name : string
    /// @return PostFxEffect
    tbl.set(
        "newEffect",
        lua.create_function(|lua, type_name: String| {
            let effect_type = PostFxEffectType::from_name(&type_name).ok_or_else(|| {
                LuaError::RuntimeError(format!("unknown effect type: {type_name}"))
            })?;
            lua.create_userdata(LuaPostFxEffect {
                inner: PostFxEffect::new(effect_type),
            })
        })?,
    )?;

    // -- newCustomEffect --
    /// Creates a custom shader post-processing effect.
    /// @param shader_id : integer
    /// @return PostFxEffect
    tbl.set(
        "newCustomEffect",
        lua.create_function(|lua, shader_id: usize| {
            lua.create_userdata(LuaPostFxEffect {
                inner: PostFxEffect::new_custom(shader_id),
            })
        })?,
    )?;

    // -- newStack --
    /// Creates a new post-processing pipeline stack.
    /// @param width : integer
    /// @param height : integer
    /// @return PostFxStack
    tbl.set(
        "newStack",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaPostFxStack {
                inner: PostFxStack::new(w, h),
            })
        })?,
    )?;

    // -- newImageEffect --
    /// Creates a new per-image effect chain.
    /// @param name : string
    /// @return ImageEffect
    tbl.set(
        "newImageEffect",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaImageEffect {
                inner: ImageEffect::new(&name),
            })
        })?,
    )?;

    // -- newOverlay --
    /// Creates a new screen overlay controller for weather, flash, shake, and fade effects.
    /// @param width : integer
    /// @param height : integer
    /// @return Overlay
    tbl.set(
        "newOverlay",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaOverlay {
                inner: Overlay::new(w, h),
            })
        })?,
    )?;

    luna.set("fx", tbl)?;
    Ok(())
}
