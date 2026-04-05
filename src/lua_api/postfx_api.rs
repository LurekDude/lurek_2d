//! Lua API bindings for the `luna.postfx.*` post-processing effects module.
//!
//! Registers the `luna.postfx` table and exposes factory functions:
//!
//! - `luna.postfx.newEffect(name)` â€” creates a built-in `PostFxEffect`
//!   by name (`"bloom"`, `"blur"`, `"crt"`, `"godrays"`, `"vignette"`,
//!   `"colourgrade"`, `"chromatic"`).
//! - `luna.postfx.newPass(shaderId)` â€” creates a `Custom` `PostFxEffect`
//!   backed by an external shader resource ID.
//! - `luna.postfx.newStack(width?, height?)` â€” creates an empty
//!   `PostFxStack` with the given canvas dimensions.
//! - `luna.postfx.newImageEffect(...)` â€” creates a per-image
//!   [`LuaImageEffect`] chain (empty, single-effect, chain-table, or
//!   options-table overloads).
//! - `luna.postfx.loadImageEffect(path)` â€” loads a [`LuaImageEffect`]
//!   chain from a TOML preset file.
//!
//! `LuaPostFxEffect`, `LuaPostFxStack`, and `LuaImageEffect` are thin
//! `mlua` UserData wrappers that hold `Rc<RefCell<...>>` smart pointers.
//! `LuaPostFxStack` additionally owns the concrete effect vector so that
//! effect objects added via Lua are kept alive as long as the stack is alive.
//! `LuaImageEffect` stores [`crate::fx::post::PostFxEffect`] values directly
//! inside its [`crate::fx::post::ImageEffect`] and is passed to
//! `luna.graphics.draw` via the `effect` key of the options-table overload.
//!
//! The `register` function is called once during engine startup.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;
use crate::graphics::renderer::DrawCommand;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::fx::post::{PostFxEffect, PostFxEffectType, PostFxStack};

// ---------------------------------------------------------------------------
// LuaPostFxEffect
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a single post-processing effect.
///
/// Wraps a `PostFxEffect` in an `Rc<RefCell<...>>` so it can be safely
/// shared between a `LuaPostFxStack` (which stores a clone of the `Rc`)
/// and any Lua variable holding a direct reference. Methods on this type
/// borrow the inner effect only for the duration of the call.
///
/// # Fields
/// - `inner` â€” `Rc<RefCell<PostFxEffect>>` â€” Shared reference to the effect.
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
        /// Sets a named float parameter on the effect.
        ///
        /// Inserts or replaces the parameter keyed by `name`. Common parameter
        /// names per effect type: `"threshold"` and `"intensity"` for bloom;
        /// `"radius"` and `"strength"` for blur; `"scanline_strength"` for CRT;
        /// `"offset"` for chromatic; `"strength"` for vignette;
        /// `"brightness"`, `"contrast"`, `"saturation"` for colour grading.
        ///
        /// # Parameters
        /// - `name` â€” `string` â€” Parameter key.
        /// - `value` â€” `number` â€” New float value.
        methods.add_method("setParameter", |_, this, (name, value): (String, f32)| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "setParameter: value must be finite, got {}",
                    value
                )));
            }
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
        /// Returns `true` if the named parameter exists on this effect.
        ///
        /// Useful for introspection and serialisation. Custom effects start
        /// with an empty parameter map, so this will return `false` for any
        /// name until `setParameter` is called.
        ///
        /// # Parameters
        /// - `name` â€” `string` â€” Parameter key to test.
        ///
        /// # Returns
        /// `boolean` â€” `true` if the key is present in the params map.
        methods.add_method("hasParameter", |_, this, name: String| {
            Ok(this.inner.borrow().has_parameter(&name))
        });

        // getParameterNames() -> table<string>
        /// Returns a sorted list of all parameter names currently set on this effect.
        ///
        /// The returned Lua table is 1-indexed and sorted alphabetically.
        /// Useful for iterating all parameters during serialisation or
        /// building a parameter UI.
        ///
        /// # Returns
        /// `table<string>` â€” Sorted array of parameter name strings.
        methods.add_method("getParameterNames", |lua, this, ()| {
            let names = this.inner.borrow().get_parameter_names();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // getType() -> string
        /// Returns the string name of this effect's type.
        ///
        /// Corresponds to `PostFxEffectType::name()`. Returns `"custom"` for
        /// custom shader pass effects created with `newPass`.
        ///
        /// # Returns
        /// `string` â€” One of `"bloom"`, `"blur"`, `"crt"`, `"godrays"`,
        /// `"vignette"`, `"colourgrade"`, `"chromatic"`, or `"custom"`.
        methods.add_method("getType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });

        // getEffectType() -> string  (alias for getType)
        /// Returns the string name of this effect's type.
        ///
        /// Alias for `getType`. Provided for API consistency â€” both names
        /// return the same value.
        ///
        /// # Returns
        /// `string` â€” Effect type name.
        methods.add_method("getEffectType", |_, this, ()| {
            Ok(this.inner.borrow().get_type_name().to_string())
        });

        // isBuiltIn() -> boolean
        /// Returns `true` if this is a built-in effect (not a custom shader pass).
        ///
        /// Returns `false` for effects created with `luna.postfx.newPass`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isBuiltIn", |_, this, ()| {
            Ok(this.inner.borrow().is_built_in())
        });

        // isEnabled() -> boolean
        /// Returns `true` if this effect is currently enabled.
        ///
        /// Disabled effects are skipped by the stack during `apply()` without
        /// being removed from the chain. Enable/disable state can be toggled
        /// at any time without affecting the effect's parameters.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.borrow().enabled));

        // setEnabled(enabled)
        /// Enables or disables this effect within its parent stack.
        ///
        /// When disabled the effect remains in the chain at its current
        /// position but is skipped during `apply()`. Re-enabling it restores
        /// the pass at the same position.
        ///
        /// # Parameters
        /// - `enabled` â€” `boolean` â€” `true` to activate, `false` to skip.
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            this.inner.borrow_mut().enabled = enabled;
            Ok(())
        });

        // --- Convenience setters ---

        // setThreshold(value) â€” bloom bright-pass threshold
        /// Sets the bloom bright-pass threshold.
        ///
        /// Pixels with luminance above this threshold contribute to the bloom
        /// effect. Typical values are 0.5â€“0.9; lower values bleed bloom onto
        /// more of the scene.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Threshold luminance (0.0â€“1.0).
        methods.add_method("setThreshold", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("threshold", value);
            Ok(())
        });

        // setIntensity(value) â€” bloom/godrays intensity
        /// Sets the intensity for bloom or godrays effects.
        ///
        /// For bloom: scales the brightness of the blurred highlight layer
        /// before it is composited back onto the scene. For godrays: controls
        /// the overall brightness of the light ray overlay.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Intensity multiplier (typically 0.0â€“2.0).
        methods.add_method("setIntensity", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("intensity", value);
            Ok(())
        });

        // setScanlineStrength(value) â€” CRT scanline visibility
        /// Sets the CRT scanline strength.
        ///
        /// Controls how prominent the dark horizontal scanlines are in the
        /// CRT monitor simulation. 0.0 disables the scanline overlay;
        /// 1.0 produces fully black lines every other row.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Scanline opacity (0.0â€“1.0).
        methods.add_method("setScanlineStrength", |_, this, value: f32| {
            this.inner
                .borrow_mut()
                .set_parameter("scanline_strength", value);
            Ok(())
        });

        // setRadius(value) â€” blur radius
        /// Sets the Gaussian blur radius.
        ///
        /// Larger values spread the blur sample footprint across more pixels.
        /// Values above ~8 may be expensive on integrated GPUs.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Blur radius in pixels.
        methods.add_method("setRadius", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("radius", value);
            Ok(())
        });

        // setStrength(value) â€” vignette/blur strength
        /// Sets the vignette or blur strength.
        ///
        /// For vignette: 0.0 is invisible; 1.0 darkens the corners to black.
        /// For blur: scales the overall blur weight applied per sample.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Strength factor (0.0â€“1.0).
        methods.add_method("setStrength", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("strength", value);
            Ok(())
        });

        // setOffset(value) â€” chromatic aberration offset
        /// Sets the chromatic aberration pixel offset.
        ///
        /// The R, G, and B channels are sampled at offsets proportional to
        /// this value. Larger values produce a more extreme colour-fringing
        /// effect. Typical range is 1â€“5 pixels.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Pixel offset for channel separation.
        methods.add_method("setOffset", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("offset", value);
            Ok(())
        });

        // setBrightness(value) â€” colour grading brightness
        /// Sets the colour grading brightness multiplier.
        ///
        /// Applied as a uniform scale across all channels before contrast
        /// and saturation adjustments. 1.0 is neutral; values below 1.0
        /// darken the scene; values above 1.0 brighten it.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Brightness multiplier (default 1.0).
        methods.add_method("setBrightness", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("brightness", value);
            Ok(())
        });

        // setContrast(value) â€” colour grading contrast
        /// Sets the colour grading contrast.
        ///
        /// Pivots around mid-grey (0.5). Values above 1.0 push darks darker
        /// and lights lighter; values below 1.0 flatten the tonal range.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Contrast multiplier (default 1.0).
        methods.add_method("setContrast", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("contrast", value);
            Ok(())
        });

        // setSaturation(value) â€” colour grading saturation
        /// Sets the colour grading saturation.
        ///
        /// 0.0 produces a greyscale image; 1.0 is neutral; values above 1.0
        /// boost colour vividness. Applied after brightness and contrast.
        ///
        /// # Parameters
        /// - `value` â€” `number` â€” Saturation multiplier (0.0â€“2.0, default 1.0).
        methods.add_method("setSaturation", |_, this, value: f32| {
            if !value.is_finite() {
                return Err(LuaError::RuntimeError(format!(
                    "parameter value must be finite, got {}",
                    value
                )));
            }
            this.inner.borrow_mut().set_parameter("saturation", value);
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaPostFxStack
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a post-processing effect stack.
///
/// Combines the `PostFxStack` data model with a local effect registry
/// (`effects` vec). Effect objects passed from Lua are stored here and
/// referenced by numeric index from the stack so that their shared
/// `Rc<RefCell<PostFxEffect>>` keeps them alive. Cloning the userdata
/// shares both the inner stack and the effects registry.
#[derive(Clone)]
struct LuaPostFxStack {
    inner: Rc<RefCell<PostFxStack>>,
    /// Local effect storage — each effect gets an incrementing index.
    effects: Rc<RefCell<Vec<Rc<RefCell<PostFxEffect>>>>>,
    /// Shared engine state used to push DrawCommand entries.
    state: Rc<RefCell<SharedState>>,
    /// Stable identifier for this stack, derived from its allocation address.
    stack_id: u64,
}
impl LunaType for LuaPostFxStack {
    const TYPE_NAME: &'static str = "PostFxStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaPostFxStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // add(effect) â€” append an effect to the end of the chain
        /// Appends a `PostFxEffect` to the end of the stack.
        ///
        /// Effects are applied in insertion order during `apply()`. The effect
        /// is registered in the local effects registry and its index is
        /// appended to the `PostFxStack` chain. The effect is enabled by default.
        ///
        /// # Parameters
        /// - `effect` â€” `PostFxEffect` userdata â€” The effect to append.
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
        /// Removes a `PostFxEffect` from the stack chain.
        ///
        /// Identifies the effect by pointer equality against the local registry.
        /// After removal all subsequent effects shift down by one position.
        /// Returns `false` if the effect is not in this stack's registry.
        ///
        /// # Parameters
        /// - `effect` â€” `PostFxEffect` userdata â€” The effect to remove.
        ///
        /// # Returns
        /// `boolean` â€” `true` if the effect was found and removed.
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

        // insert(position, effect) â€” insert at 1-based index
        /// Inserts a `PostFxEffect` at a specific 1-based position in the chain.
        ///
        /// A `position` of 1 places the effect as the very first shader pass
        /// (applied before all others). Values beyond the current chain length
        /// are clamped to the end, behaving like `add`. The effect is
        /// registered in the local registry and enabled by default.
        ///
        /// # Parameters
        /// - `position` â€” `integer` â€” 1-based insertion index.
        /// - `effect` â€” `PostFxEffect` userdata â€” The effect to insert.
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
        /// Sets the enabled state for an effect within this stack.
        ///
        /// When `enabled` is `false`, the effect remains in the chain at its
        /// current position but is skipped during `apply()`. This is a
        /// per-position flag in the stack and is independent of the
        /// `enabled` flag on the `PostFxEffect` object itself.
        ///
        /// # Parameters
        /// - `effect` â€” `PostFxEffect` userdata â€” The effect to toggle.
        /// - `enabled` â€” `boolean` â€” `true` to activate, `false` to skip.
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
        /// Returns `true` if the given effect is enabled within this stack.
        ///
        /// Queries the per-position enabled flag in the chain. Returns `false`
        /// if the effect is not in this stack's registry at all. This is
        /// distinct from `effect:isEnabled()`, which reads the enabled flag
        /// stored directly on the `PostFxEffect` object; both flags must be
        /// `true` for the pass to execute during `apply()`.
        ///
        /// # Parameters
        /// - `effect` â€” `PostFxEffect` userdata â€” The effect to query.
        ///
        /// # Returns
        /// `boolean` â€” `false` if the effect is absent from the chain.
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
        /// Returns the number of effects currently in the chain (enabled and disabled).
        ///
        /// Useful for iterating via `getEffect(i)` from Lua.
        ///
        /// # Returns
        /// `integer` â€” Total effects in the chain.
        methods.add_method("getEffectCount", |_, this, ()| {
            Ok(this.inner.borrow().get_effect_count())
        });

        // getEffect(index) -> Effect | nil
        /// Returns the effect at a 1-based position in the chain, or `nil`.
        ///
        /// Provides random access into the chain. Returns the
        /// `LuaPostFxEffect` UserData at that position, or `nil` if `index`
        /// is out of range. The returned object is shared â€” mutations to it
        /// are visible immediately through any other Lua variable holding the
        /// same effect.
        ///
        /// # Parameters
        /// - `index` â€” `integer` â€” 1-based position in the chain.
        ///
        /// # Returns
        /// `PostFxEffect | nil`.
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
        /// Returns a Lua table of all currently enabled effects in application order.
        ///
        /// Used by the GPU layer during `apply()` to determine which shader
        /// passes to run. Disabled effects are excluded. The returned table
        /// is 1-indexed and contains `PostFxEffect` UserData objects.
        ///
        /// # Returns
        /// `table<PostFxEffect>` â€” Enabled effects in chain order.
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

        // resize(width, height) â€” recreate internal canvases at new resolution
        /// Resizes the internal canvas dimensions.
        ///
        /// Call this whenever the window or render target changes size so the
        /// GPU layer can recreate ping-pong canvases at the correct resolution.
        /// Does not remove or invalidate any effects in the chain.
        ///
        /// # Parameters
        /// - `w` â€” `integer` â€” New canvas width in pixels.
        /// - `h` â€” `integer` â€” New canvas height in pixels.
        methods.add_method("resize", |_, this, (w, h): (u32, u32)| {
            this.inner.borrow_mut().resize(w, h);
            Ok(())
        });

        // getWidth() -> int
        /// Returns the canvas width in pixels.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().get_width())
        });

        // getHeight() -> int
        /// Returns the canvas height in pixels.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().get_height())
        });

        // getDimensions() -> int, int
        /// Returns both canvas dimensions as `(width, height)`.
        ///
        /// # Returns
        /// `integer, integer` â€” Width and height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.borrow().get_dimensions())
        });

        // isCapturing() -> boolean
        /// Returns `true` while the stack is between `beginCapture` and `endCapture`.
        ///
        /// Useful for guard checks in Lua to avoid nested capture calls.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isCapturing", |_, this, ()| {
            Ok(this.inner.borrow().capturing)
        });

        // beginCapture() — redirect subsequent draws into the PostFx capture target.
        /// Starts a post-processing capture pass.
        ///
        /// All `luna.graphics.*` draw calls between `beginCapture` and `endCapture`
        /// will target the post-FX canvas instead of the screen. Pair with
        /// `endCapture()` and `apply()` to see the effects.
        ///
        /// Returns an error if a capture is already in progress.
        methods.add_method("beginCapture", |_, this, ()| {
            if this.inner.borrow().capturing {
                return Err(LuaError::RuntimeError(
                    "PostFxStack.beginCapture: capture already in progress".to_string(),
                ));
            }
            this.inner.borrow_mut().capturing = true;
            this.state
                .borrow_mut()
                .draw_commands
                .push(DrawCommand::BeginPostFx { stack_id: this.stack_id });
            Ok(())
        });

        // endCapture() — stop capturing and return to the previous render target.
        /// Ends a post-processing capture pass.
        ///
        /// Must be called after `beginCapture()`. After this returns the engine
        /// resumes drawing to the normal screen target. Call `apply()` afterwards
        /// to composite the captured frame through the effect chain.
        methods.add_method("endCapture", |_, this, ()| {
            this.inner.borrow_mut().capturing = false;
            this.state
                .borrow_mut()
                .draw_commands
                .push(DrawCommand::EndPostFx { stack_id: this.stack_id });
            Ok(())
        });

        // apply() — composite enabled effects onto the current render target.
        /// Applies all enabled effects in the stack.
        ///
        /// Composites the captured image through each enabled effect in chain order
        /// and blends the result onto the current render target. Call this after
        /// `endCapture()` in `luna.draw`.
        methods.add_method("apply", |_, this, ()| {
            this.state
                .borrow_mut()
                .draw_commands
                .push(DrawCommand::ApplyPostFx { stack_id: this.stack_id });
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// LuaImageEffect
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a per-image shader effect chain.
///
/// Wraps an [`crate::fx::post::ImageEffect`] in an `Rc<RefCell<...>>` so it
/// can be safely passed between Lua variables and to `luna.graphics.draw`.
/// The inner [`crate::fx::post::ImageEffect`] stores [`crate::fx::post::PostFxEffect`]
/// objects directly (as owned values, not shared references).
///
/// # Fields
/// - `inner` â€” `Rc<RefCell<ImageEffect>>` â€” Shared reference to the effect chain.
#[derive(Clone)]
pub(crate) struct LuaImageEffect {
    pub(crate) inner: Rc<RefCell<crate::fx::post::ImageEffect>>,
}

impl LunaType for LuaImageEffect {
    const TYPE_NAME: &'static str = "ImageEffect";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaImageEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Appends a new effect pass by name to the end of this effect chain.
        ///
        /// Creates the effect internally and returns a shared handle so that
        /// parameter mutations through the returned object are visible in the chain.
        ///
        /// # Parameters
        /// - `name` â€” `string` â€” Effect type name (e.g. `"blur"`, `"sepia"`).
        ///
        /// # Returns
        /// `PostFxEffect` â€” Shared handle to the newly added effect.
        methods.add_method("addEffect", |_, this, name: String| {
            let effect_type = PostFxEffectType::from_name(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "addEffect: unknown effect type '{}'. Valid types: bloom, blur, crt, godrays, vignette, colourgrade, chromatic, pixelate, sepia, grayscale, invert, scanlines, edgedetect, hueshift, noise",
                    name
                ))
            })?;
            let rc = Rc::new(RefCell::new(PostFxEffect::new(effect_type)));
            this.inner.borrow_mut().add_effect_rc(Rc::clone(&rc));
            Ok(LuaPostFxEffect { inner: rc })
        });

        /// Returns the effect at the given 1-based index or by name, or `nil`.
        ///
        /// When the first argument is an integer, retrieves by 1-based position.
        /// When it is a string, retrieves the first effect whose type name matches.
        ///
        /// # Parameters
        /// - `key` ? `integer | string` ? 1-based index or effect type name.
        ///
        /// # Returns
        /// `PostFxEffect | nil`.
        methods.add_method("getEffect", |_, this, key: LuaValue| {
            let inner = this.inner.borrow();
            let opt_rc = match &key {
                LuaValue::Integer(i) => inner.get_effect_by_index((*i as usize).saturating_sub(1)),
                LuaValue::Number(n) => inner.get_effect_by_index((*n as usize).saturating_sub(1)),
                LuaValue::String(s) => {
                    inner.get_effect_by_name(s.to_str().map_err(LuaError::external)?)
                }
                _ => None,
            };
            Ok(opt_rc.map(|r| LuaPostFxEffect { inner: r }))
        });

        /// Returns the number of effects in this chain.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("effectCount", |_, this, ()| {
            Ok(this.inner.borrow().effect_count())
        });

        /// Removes an effect by 1-based index or by type name.
        ///
        /// # Parameters
        /// - `key` ? `integer | string` ? 1-based index or effect type name.
        ///
        /// # Returns
        /// `boolean` ? `true` if the effect was found and removed.
        methods.add_method("removeEffect", |_, this, key: LuaValue| {
            let mut inner = this.inner.borrow_mut();
            let removed = match &key {
                LuaValue::Integer(i) => inner.remove_by_index((*i as usize).saturating_sub(1)),
                LuaValue::Number(n) => inner.remove_by_index((*n as usize).saturating_sub(1)),
                LuaValue::String(s) => {
                    inner.remove_by_name(s.to_str().map_err(LuaError::external)?)
                }
                _ => false,
            };
            Ok(removed)
        });

        /// Removes all effects from this chain.
        methods.add_method("clearEffects", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Returns a deep clone of this `ImageEffect`.
        ///
        /// The returned object shares no state with the original.
        ///
        /// # Returns
        /// `ImageEffect`.
        methods.add_method("clone", |_, this, ()| {
            let inner = this.inner.borrow();
            let mut cloned = crate::fx::post::ImageEffect::new(&inner.name);
            for effect in &inner.effects {
                cloned.add_effect(effect.borrow().clone());
            }
            Ok(LuaImageEffect {
                inner: Rc::new(RefCell::new(cloned)),
            })
        });

        /// Serialises this effect chain to a TOML file at the given path.
        ///
        /// # Parameters
        /// - `path` ? `string` ? Destination file path.
        ///
        /// # Returns
        /// `()`.
        methods.add_method("save", |_, this, path: String| {
            let path_obj = std::path::Path::new(&path);
            if path_obj
                .components()
                .any(|c| matches!(
                    c,
                    std::path::Component::ParentDir
                        | std::path::Component::RootDir
                        | std::path::Component::Prefix(_)
                ))
            {
                return Err(LuaError::RuntimeError(
                    "ImageEffect:save: path traversal not allowed".to_string(),
                ));
            }
            let inner = this.inner.borrow();
            let mut out = String::new();
            out.push_str(&format!("name = {:?}\n", inner.name));
            for effect_rc in &inner.effects {
                let effect = effect_rc.borrow();
                out.push_str("\n[[effects]]\n");
                out.push_str(&format!("type = {:?}\n", effect.get_type_name()));
                out.push_str(&format!("enabled = {}\n", effect.enabled));
                let mut params: Vec<(&String, &f32)> = effect.params.iter().collect();
                params.sort_by_key(|(k, _)| k.as_str());
                for (k, v) in params {
                    out.push_str(&format!("{} = {}\n", k, v));
                }
            }
            std::fs::write(&path, out).map_err(|e| {
                mlua::Error::RuntimeError(format!("ImageEffect:save: {}", e))
            })
        });
    }
}


// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.postfx.*` Lua API.
///
/// Creates the `luna.postfx` sub-table and adds factory functions:
/// `newEffect`, `newPass`, `newStack`, `getEffectTypes`, `newImageEffect`,
/// and `loadImageEffect`. All `LuaPostFxEffect`, `LuaPostFxStack`, and
/// `LuaImageEffect` methods are registered on their respective UserData
/// types via `LuaUserData` impls.
///
/// # Parameters
/// - `lua` â€” `&Lua` â€” The active Lua VM.
/// - `luna` â€” `&LuaTable` â€” The root `luna` global table.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let postfx = lua.create_table()?;

    // luna.postfx.newEffect(name) -> PostFxEffect
    /// Creates a built-in post-processing effect by name.
    ///
    /// Valid names: `"bloom"`, `"blur"`, `"crt"`, `"godrays"`,
    /// `"vignette"`, `"colourgrade"`, `"chromatic"`. Returns an error
    /// if the name is not recognised. Default parameters are populated
    /// automatically; call `setParameter` to override them.
    ///
    /// @param name : string
    /// @return PostFxEffect
    postfx.set(
        "newEffect",
        lua.create_function(|_, name: String| {
            let effect_type = PostFxEffectType::from_name(&name).ok_or_else(|| {
                mlua::Error::RuntimeError(format!(
                    "Unknown effect type '{}'. Valid types: bloom, blur, crt, godrays, vignette, colourgrade, chromatic, pixelate, sepia, grayscale, invert, scanlines, edgedetect, hueshift, noise",
                    name
                ))
            })?;
            Ok(LuaPostFxEffect {
                inner: Rc::new(RefCell::new(PostFxEffect::new(effect_type))),
            })
        })?,
    )?;

    // luna.postfx.newPass(shaderId) -> PostFxEffect (custom shader pass)
    /// Creates a custom shader pass effect.
    ///
    /// The returned `PostFxEffect` has `effect_type = Custom` and starts
    /// with an empty parameter map. The `shader_id` is passed to the GPU
    /// layer during `apply()` so it can look up and dispatch the correct
    /// user-supplied shader.
    ///
    /// @param shader_id : integer
    /// @return PostFxEffect
    postfx.set(
        "newPass",
        lua.create_function(|_, shader_id: usize| {
            Ok(LuaPostFxEffect {
                inner: Rc::new(RefCell::new(PostFxEffect::new_custom(shader_id))),
            })
        })?,
    )?;

    // luna.postfx.newStack(width?, height?) -> PostFxStack
    /// Creates an empty post-processing stack.
    ///
    /// The stack starts with no effects. Call `stack:add(effect)` to build
    /// the chain, then use `stack:beginCapture()` / `stack:endCapture()` /
    /// `stack:apply()` in `luna.draw`. Width and height default to 800Ă—600
    /// if not supplied; call `stack:resize(w, h)` if the window size changes.
    ///
    /// @param w : integer?
    /// @param h : integer?
    /// @return PostFxStack
    {
        let state = state.clone();
        postfx.set(
            "newStack",
            lua.create_function(move |_, (w, h): (Option<u32>, Option<u32>)| {
                let inner = Rc::new(RefCell::new(PostFxStack::new(
                    w.unwrap_or(800),
                    h.unwrap_or(600),
                )));
                let stack_id = Rc::as_ptr(&inner) as u64;
                Ok(LuaPostFxStack {
                    inner,
                    effects: Rc::new(RefCell::new(Vec::new())),
                    state: state.clone(),
                    stack_id,
                })
            })?,
        )?;
    }

    // luna.postfx.getEffectTypes() -> table of valid effect type names
    /// Returns a Lua table listing all valid built-in effect type names.
    ///
    /// Useful for introspection tools or mod loaders that enumerate
    /// available effects without hard-coding the list.
    ///
    /// @return table<string>
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
                "pixelate",
                "sepia",
                "grayscale",
                "invert",
                "scanlines",
                "edgedetect",
                "hueshift",
                "noise",
            ];
            for (i, name) in names.iter().enumerate() {
                types.set(i + 1, *name)?;
            }
            Ok(types)
        })?,
    )?;

    // luna.postfx.newImageEffect(name?, params?) | (chain_table?) -> ImageEffect
    /// Creates a per-image effect chain.
    ///
    /// Overloads:
    /// - `newImageEffect()` â€” empty chain.
    /// - `newImageEffect("blur")` â€” chain with a single named effect.
    /// - `newImageEffect("blur", {radius=4})` â€” single effect with initial parameters.
    /// - `newImageEffect({{type="blur",radius=2},{type="sepia"}})` â€” chain from an array of spec tables.
    ///
    /// @return ImageEffect
    postfx.set(
        "newImageEffect",
        lua.create_function(|_, args: LuaMultiValue| {
            let mut it = args.iter();
            match it.next() {
                None | Some(LuaValue::Nil) => {
                    Ok(LuaImageEffect {
                        inner: Rc::new(RefCell::new(crate::fx::post::ImageEffect::new(""))),
                    })
                }
                Some(LuaValue::String(s)) => {
                    let name = s.to_str().map_err(LuaError::external)?.to_owned();
                    let effect_type = PostFxEffectType::from_name(&name).ok_or_else(|| {
                        LuaError::RuntimeError(format!(
                            "newImageEffect: unknown effect type '{}'. Valid types: bloom, blur, crt, godrays, vignette, colourgrade, chromatic, pixelate, sepia, grayscale, invert, scanlines, edgedetect, hueshift, noise",
                            name
                        ))
                    })?;
                    let rc = Rc::new(RefCell::new(PostFxEffect::new(effect_type)));
                    if let Some(LuaValue::Table(params)) = it.next() {
                        for pair in params.clone().pairs::<String, LuaValue>() {
                            let (k, v) = pair?;
                            match v {
                                LuaValue::Number(n) => rc.borrow_mut().set_parameter(k, n as f32),
                                LuaValue::Integer(n) => rc.borrow_mut().set_parameter(k, n as f32),
                                _ => {}
                            }
                        }
                    }
                    let mut chain = crate::fx::post::ImageEffect::new(&name);
                    chain.add_effect_rc(rc);
                    Ok(LuaImageEffect {
                        inner: Rc::new(RefCell::new(chain)),
                    })
                }
                Some(LuaValue::Table(t)) => {
                    let mut chain = crate::fx::post::ImageEffect::new("");
                    let mut idx: i64 = 1;
                    loop {
                        let entry: Option<LuaTable> = t.get(idx)?;
                        match entry {
                            None => break,
                            Some(spec) => {
                                let type_name: String = spec.get("type")?;
                                let effect_type = PostFxEffectType::from_name(&type_name)
                                    .ok_or_else(|| {
                                        LuaError::RuntimeError(format!(
                                            "newImageEffect: unknown effect type '{}'",
                                            type_name
                                        ))
                                    })?;
                                let rc = Rc::new(RefCell::new(PostFxEffect::new(effect_type)));
                                for pair in spec.pairs::<String, LuaValue>() {
                                    let (k, v) = pair?;
                                    if k == "enabled" {
                                        if let LuaValue::Boolean(b) = v {
                                            rc.borrow_mut().enabled = b;
                                        }
                                    } else if k != "type" {
                                        match v {
                                            LuaValue::Number(n) => {
                                                rc.borrow_mut().set_parameter(k, n as f32)
                                            }
                                            LuaValue::Integer(n) => {
                                                rc.borrow_mut().set_parameter(k, n as f32)
                                            }
                                            _ => {}
                                        }
                                    }
                                }
                                chain.add_effect_rc(rc);
                                idx += 1;
                            }
                        }
                    }
                    Ok(LuaImageEffect {
                        inner: Rc::new(RefCell::new(chain)),
                    })
                }
                _ => Err(LuaError::RuntimeError(
                    "newImageEffect: expected nil, string, or table argument".to_string(),
                )),
            }
        })?,
    )?;

    // luna.postfx.loadImageEffect(path) -> ImageEffect
    /// Loads a per-image effect chain from a TOML preset file saved by `ImageEffect:save`.
    ///
    /// @param path : string
    /// @return ImageEffect
    postfx.set(
        "loadImageEffect",
        lua.create_function(|_, path: String| {
            let path_obj = std::path::Path::new(&path);
            if path_obj
                .components()
                .any(|c| matches!(
                    c,
                    std::path::Component::ParentDir
                        | std::path::Component::RootDir
                        | std::path::Component::Prefix(_)
                ))
            {
                return Err(LuaError::RuntimeError(
                    "loadImageEffect: path traversal not allowed".to_string(),
                ));
            }
            let content = std::fs::read_to_string(&path).map_err(|e| {
                LuaError::RuntimeError(format!("loadImageEffect: {}", e))
            })?;
            let doc: toml::Value = content.parse::<toml::Value>().map_err(|e| {
                LuaError::RuntimeError(format!("loadImageEffect: TOML parse error: {}", e))
            })?;
            let name = doc.get("name").and_then(|v| v.as_str()).unwrap_or("").to_owned();
            let mut chain = crate::fx::post::ImageEffect::new(&name);
            if let Some(effects) = doc.get("effects").and_then(|v| v.as_array()) {
                for spec in effects {
                    let type_name = spec.get("type").and_then(|v| v.as_str()).unwrap_or("");
                    let effect_type = PostFxEffectType::from_name(type_name).ok_or_else(|| {
                        LuaError::RuntimeError(format!(
                            "loadImageEffect: unknown effect type '{}'",
                            type_name
                        ))
                    })?;
                    let mut effect = PostFxEffect::new(effect_type);
                    if let Some(b) = spec.get("enabled").and_then(|v| v.as_bool()) {
                        effect.enabled = b;
                    }
                    if let Some(table) = spec.as_table() {
                        for (k, v) in table {
                            if k == "type" || k == "enabled" {
                                continue;
                            }
                            if let Some(f) = v.as_float() {
                                effect.set_parameter(k.clone(), f as f32);
                            } else if let Some(i) = v.as_integer() {
                                effect.set_parameter(k.clone(), i as f32);
                            }
                        }
                    }
                    chain.add_effect(effect);
                }
            }
            Ok(LuaImageEffect {
                inner: Rc::new(RefCell::new(chain)),
            })
        })?,
    )?;

    /// Registers `luna.postfx` and returns.
    ///
    /// # Returns
    /// `LuaResult<()>`.

    luna.set("postfx", postfx)?;

    Ok(())
}

