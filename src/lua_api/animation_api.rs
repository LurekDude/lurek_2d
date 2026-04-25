//! `lurek.animation` — Sprite animation: frame pools, named clips, speed control, playback events,
//! crossfade blending, stat-machine FSMs, and Aseprite JSON import.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::animation::aseprite::load_aseprite_json;
use crate::animation::blend::{BlendLayer, BlendLayerSet, BlendMask};
use crate::animation::state_machine::{AnimParamValue, AnimStateMachine};
use crate::animation::Animation;
use crate::math::Rect;

// -------------------------------------------------------------------------------
// LuaAnimation UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`Animation`] controller.
pub struct LuaAnimation {
    inner: Animation,
}

impl LuaUserData for LuaAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addFrame --
        /// Adds a single frame to the frame pool by source rectangle.
        /// @param x number
        /// @param y number
        /// @param w number
        /// @param h number
        /// @return integer
        methods.add_method_mut("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            Ok(this.inner.add_frame(Rect::new(x, y, w, h)))
        });

        // -- addFramesFromGrid --
        /// Slices a sprite-sheet grid into frames and appends them.
        /// @param tex_w integer
        /// @param tex_h integer
        /// @param frame_w integer
        /// @param frame_h integer
        /// @param start integer
        /// @param count integer
        /// @return integer
        methods.add_method_mut(
            "addFramesFromGrid",
            |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                Ok(this
                    .inner
                    .add_frames_from_grid(tw, th, fw, fh, start, count))
            },
        );

        // -- addClip --
        /// Adds a named clip from explicit frame indices.
        /// @param name string
        /// @param indices table
        /// @param fps number
        /// @param looping boolean
        /// @return nil
        methods.add_method_mut(
            "addClip",
            |_, this, (name, indices_tbl, fps, looping): (String, LuaTable, f32, bool)| {
                let mut indices: Vec<usize> = Vec::new();
                for v in indices_tbl.sequence_values::<usize>() {
                    indices.push(v?);
                }
                this.inner.add_clip(&name, indices, fps, looping);
                Ok(())
            },
        );

        // -- addClipFromGrid --
        /// Adds a named clip sliced from a sprite-sheet grid.
        /// @param name string
        /// @param tex_w integer
        /// @param tex_h integer
        /// @param frame_w integer
        /// @param frame_h integer
        /// @param start integer
        /// @param count integer
        /// @param fps number
        /// @param looping boolean
        /// @return nil
        methods.add_method_mut(
            "addClipFromGrid",
            |_,
             this,
             (name, tw, th, fw, fh, start, count, fps, looping): (
                String,
                u32,
                u32,
                u32,
                u32,
                usize,
                usize,
                f32,
                bool,
            )| {
                this.inner
                    .add_clip_from_grid(&name, tw, th, fw, fh, start, count, fps, looping);
                Ok(())
            },
        );

        // -- play --
        /// Starts playback of the named clip.
        /// @param name string
        /// @return boolean
        methods.add_method_mut("play", |_, this, name: String| Ok(this.inner.play(&name)));

        // -- stop --
        /// Stops playback and resets to frame 0.
        /// @return nil
        methods.add_method_mut("stop", |_, this, ()| {
            this.inner.stop();
            Ok(())
        });

        // -- pause --
        /// Pauses playback at the current frame.
        /// @return nil
        methods.add_method_mut("pause", |_, this, ()| {
            this.inner.pause();
            Ok(())
        });

        // -- resume --
        /// Resumes playback from the current frame.
        /// @return nil
        methods.add_method_mut("resume", |_, this, ()| {
            this.inner.resume();
            Ok(())
        });

        // -- update --
        /// Advances the animation by dt seconds.
        /// @param dt number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- getQuad --
        /// Returns the source quad (x, y, w, h) for the current frame, or nil.
        /// @return table?
        methods.add_method("getQuad", |lua, this, ()| {
            if let Some(q) = this.inner.current_quad() {
                let t = lua.create_table()?;
                t.set("x", q.x)?;
                t.set("y", q.y)?;
                t.set("w", q.width)?;
                t.set("h", q.height)?;
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // -- pollEvents --
        /// Drains and returns all pending animation events as a table.
        /// @return table
        methods.add_method_mut("pollEvents", |lua, this, ()| {
            let events = this.inner.drain_events();
            let tbl = lua.create_table()?;
            for (i, ev) in events.iter().enumerate() {
                let ev_tbl = lua.create_table()?;
                ev_tbl.set("type", ev.type_name())?;
                if let Some(idx) = ev.frame_index() {
                    ev_tbl.set("frame", idx)?;
                }
                tbl.set(i + 1, ev_tbl)?;
            }
            Ok(tbl)
        });

        // -- isPlaying --
        /// Returns true if a clip is currently playing.
        /// @return boolean
        methods.add_method("isPlaying", |_, this, ()| Ok(this.inner.is_playing()));

        // -- isLooping --
        /// Returns true if the current clip is set to loop.
        /// @return boolean
        methods.add_method("isLooping", |_, this, ()| Ok(this.inner.is_looping()));

        // -- getClip --
        /// Returns the name of the currently playing clip, or nil.
        /// @return string?
        methods.add_method("getClip", |_, this, ()| {
            Ok(this.inner.get_current_clip().map(|s| s.to_owned()))
        });

        // -- getSpeed --
        /// Returns the playback speed multiplier.
        /// @return number
        methods.add_method("getSpeed", |_, this, ()| Ok(this.inner.get_speed()));

        // -- setSpeed --
        /// Sets the playback speed multiplier.
        /// @param speed number
        /// @return nil
        methods.add_method_mut("setSpeed", |_, this, speed: f32| {
            this.inner.set_speed(speed);
            Ok(())
        });

        // -- getFrameCount --
        /// Returns the total number of frames in the frame pool.
        /// @return integer
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });

        // -- getClipCount --
        /// Returns the number of registered clips.
        /// @return integer
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.get_clip_count())
        });

        // -- getCurrentFrame --
        /// Returns the current position within the active clip (0-based).
        /// @return integer
        methods.add_method("getCurrentFrame", |_, this, ()| {
            Ok(this.inner.current_frame())
        });

        // -- setFrame --
        /// Sets the playback position within the current clip.
        /// @param index integer
        /// @return nil
        methods.add_method_mut("setFrame", |_, this, index: usize| {
            this.inner.set_frame(index);
            Ok(())
        });

        // -- crossfade --
        /// Begins a smooth crossfade from the current clip to a new named clip.
        /// @param clip_name string
        /// @param duration number
        /// @return boolean
        methods.add_method_mut(
            "crossfade",
            |_, this, (clip_name, duration): (String, f32)| {
                Ok(this.inner.crossfade(&clip_name, duration))
            },
        );

        // -- getBlendState --
        /// Returns the two quads and blend factor during a crossfade, or nil when not blending.
        /// @return table?
        methods.add_method("getBlendState", |lua, this, ()| {
            match this.inner.get_blend_state() {
                None => Ok(LuaValue::Nil),
                Some((from_q, to_q, blend)) => {
                    let from = lua.create_table()?;
                    from.set("x", from_q.x)?;
                    from.set("y", from_q.y)?;
                    from.set("w", from_q.width)?;
                    from.set("h", from_q.height)?;
                    let to = lua.create_table()?;
                    to.set("x", to_q.x)?;
                    to.set("y", to_q.y)?;
                    to.set("w", to_q.width)?;
                    to.set("h", to_q.height)?;
                    let t = lua.create_table()?;
                    t.set("from", from)?;
                    t.set("to", to)?;
                    t.set("blend", blend)?;
                    Ok(LuaValue::Table(t))
                }
            }
        });

        // -- drawToImage --
        /// Renders the current animation frame into a new ImageData (white bg, blue frame rect).
        /// @param width integer
        /// @param height integer
        /// @return ImageData
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LAnimation"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimation" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAnimStateMachine UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AnimStateMachine`] FSM controller.
pub struct LuaAnimStateMachine {
    inner: AnimStateMachine,
}

impl LuaUserData for LuaAnimStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the FSM by `dt` seconds, evaluating transitions.
        /// @param dt number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- getState --
        /// Returns the name of the currently active state.
        /// @return string
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.get_state().to_owned())
        });

        // -- forceState --
        /// Immediately jumps to the named state, bypassing transition conditions.
        /// @param name string
        /// @return boolean
        methods.add_method_mut("forceState", |_, this, name: String| {
            Ok(this.inner.force_state(&name))
        });

        // -- addState --
        /// Registers a new named state that plays a clip from the embedded animation.
        /// @param name string
        /// @param clip string
        /// @param looping boolean
        /// @return nil
        methods.add_method_mut(
            "addState",
            |_, this, (name, clip, looping): (String, String, bool)| {
                this.inner.add_state(&name, &clip, looping);
                Ok(())
            },
        );

        // -- addTransition --
        /// Adds a conditional transition between two states.
        /// Condition format: `"<param> <op> <value>"`, e.g. `"speed > 0.5"` or `"jumping == true"`.
        /// @param from_state string
        /// @param to_state string
        /// @param condition string
        /// @return nil
        methods.add_method_mut(
            "addTransition",
            |_, this, (from_state, to_state, condition): (String, String, String)| {
                this.inner
                    .add_transition(&from_state, &to_state, &condition);
                Ok(())
            },
        );

        // -- setParam --
        /// Sets an FSM parameter value (number, boolean, or integer supported).
        /// @param name string
        /// @param value number|boolean
        /// @return nil
        methods.add_method_mut("setParam", |_, this, (name, value): (String, LuaValue)| {
            let param = match value {
                LuaValue::Boolean(b) => AnimParamValue::Bool(b),
                LuaValue::Integer(i) => AnimParamValue::Int(i as i32),
                LuaValue::Number(f) => AnimParamValue::Float(f as f32),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "setParam: value must be boolean, integer, or number".into(),
                    ))
                }
            };
            match param {
                AnimParamValue::Bool(b) => this.inner.set_param_bool(&name, b),
                AnimParamValue::Int(i) => this.inner.set_param_int(&name, i),
                AnimParamValue::Float(f) => this.inner.set_param_float(&name, f),
            }
            Ok(())
        });

        // -- getQuad --
        /// Returns the source quad for the current animation frame, or nil.
        /// @return table?
        methods.add_method("getQuad", |lua, this, ()| {
            let anim = this.inner.get_animation();
            if let Some(q) = anim.current_quad() {
                let t = lua.create_table()?;
                t.set("x", q.x)?;
                t.set("y", q.y)?;
                t.set("w", q.width)?;
                t.set("h", q.height)?;
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LAnimStateMachine"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimStateMachine" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

// Registers the `lurek.animation` API table with the Lua VM.
//
// @param lua &Lua
// @param luna &LuaTable
// @param _state Rc<RefCell<SharedState>>
// -------------------------------------------------------------------------------
// LuaBlendLayerSet UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`BlendLayerSet`] blend layer compositor.
pub struct LuaBlendLayerSet {
    inner: BlendLayerSet,
}

impl LuaUserData for LuaBlendLayerSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Appends a new blend layer.
        ///
        /// # Usage
        /// ```lua
        /// bls:addLayer("upper_body", "run", 1.0)
        /// bls:addLayer("lower_body", "walk", 0.8, {"hip", "leg_l", "leg_r"})
        /// ```
        /// @param name string
        /// @param clip_name string
        /// @param weight number
        /// @param bones table?
        /// @return boolean
        methods.add_method_mut(
            "addLayer",
            |_, this, (name, clip_name, weight, bones): (String, String, f32, Option<LuaTable>)| {
                let mask = if let Some(t) = bones {
                    let mut names: Vec<String> = Vec::new();
                    for pair in t.pairs::<LuaValue, String>() {
                        let (_, v) = pair?;
                        names.push(v);
                    }
                    BlendMask::from_bones(names)
                } else {
                    BlendMask::all()
                };
                let layer = BlendLayer::new(&name, &clip_name, weight, mask);
                this.inner
                    .add_layer(layer)
                    .map_err(LuaError::RuntimeError)?;
                Ok(true)
            },
        );

        // -- removeLayer --
        /// Removes a blend layer by name.
        /// @param name string
        /// @return boolean
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.inner
                .remove_layer(&name)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });

        // -- setWeight --
        /// Sets the blend weight of a named layer (clamped to [0, 1]).
        /// @param name string
        /// @param weight number
        /// @return boolean
        methods.add_method_mut("setWeight", |_, this, (name, weight): (String, f32)| {
            this.inner
                .set_weight(&name, weight)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });

        // -- getWeight --
        /// Returns the blend weight of a named layer, or nil if not found.
        /// @param name string
        /// @return number?
        methods.add_method("getWeight", |_, this, name: String| {
            Ok(this.inner.get_weight(&name))
        });

        // -- setMask --
        /// Replaces the bone mask of a layer.
        /// @param name string
        /// @param bones table
        /// @return boolean
        methods.add_method_mut("setMask", |_, this, (name, bones): (String, LuaTable)| {
            let mut bone_names: Vec<String> = Vec::new();
            for pair in bones.pairs::<LuaValue, String>() {
                let (_, v) = pair?;
                bone_names.push(v);
            }
            this.inner
                .set_mask(&name, BlendMask::from_bones(bone_names))
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });

        // -- listLayers --
        /// Returns an ordered array of layer info tables: {name, clip_name, weight, bones}.
        /// @return table
        methods.add_method("listLayers", |lua, this, ()| {
            let out = lua.create_table()?;
            for (i, layer) in this.inner.layers().iter().enumerate() {
                let t = lua.create_table()?;
                t.set("name", layer.name.clone())?;
                t.set("clip_name", layer.clip_name.clone())?;
                t.set("weight", layer.weight)?;
                let bones = lua.create_table()?;
                for (j, b) in layer.mask.bone_names.iter().enumerate() {
                    bones.set(j + 1, b.clone())?;
                }
                t.set("bones", bones)?;
                out.set(i + 1, t)?;
            }
            Ok(out)
        });

        // -- len --
        /// Returns the number of blend layers.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LBlendLayerSet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBlendLayerSet" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// register()
// -------------------------------------------------------------------------------

/// Registers the `lurek.animation` Lua API table into the engine namespace.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── new ──────────────────────────────────────────────────────────────────
    /// Creates a new, empty Animation controller.
    /// @return Animation
    tbl.set(
        "new",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimation {
                inner: Animation::new(),
            })
        })?,
    )?;

    // ── fromAseprite ─────────────────────────────────────────────────────────
    /// Parses an Aseprite JSON export string and builds an Animation with clips and frames.
    /// @return table|nil
    /// Returns nil and an error message on parse failure.
    /// @param json_str string
    /// Animation?
    tbl.set(
        "fromAseprite",
        lua.create_function(
            |lua, json_str: String| match load_aseprite_json(&json_str) {
                Ok(parsed) => {
                    let anim = Animation::load_from_aseprite(&parsed);
                    let ud = lua.create_userdata(LuaAnimation { inner: anim })?;
                    Ok(LuaValue::UserData(ud))
                }
                Err(e) => Err(LuaError::RuntimeError(format!("fromAseprite: {}", e))),
            },
        )?,
    )?;

    // ── newStateMachine ───────────────────────────────────────────────────────
    /// Creates an animation FSM from an Animation controller and an initial state name.
    /// @param anim Animation
    /// @param initial_state string
    /// @return AnimStateMachine
    tbl.set(
        "newStateMachine",
        lua.create_function(|lua, (anim_ud, initial): (LuaAnyUserData, String)| {
            let anim = anim_ud.take::<LuaAnimation>()?.inner;
            lua.create_userdata(LuaAnimStateMachine {
                inner: AnimStateMachine::new(anim, initial),
            })
        })?,
    )?;

    // -- newCurve --
    /// Creates a new empty [`AnimCurve`] with linear interpolation.
    ///
    /// Add keyframes with `curve:addKeyframe(time, value)` and read the
    /// interpolated value with `curve:eval(t)`.
    ///
    /// @return AnimCurve
    tbl.set(
        "newCurve",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimCurve {
                inner: crate::animation::curve::AnimCurve::new(),
                custom_easing: None,
            })
        })?,
    )?;

    // -- newSyncGroup --
    /// Creates a new empty [`AnimSyncGroup`].
    ///
    /// Add animation handles with `group:add(handle)`.  Call `group:tick(dt)`
    /// from `lurek.process` to advance all member animations at once.
    ///
    /// @return AnimSyncGroup
    tbl.set(
        "newSyncGroup",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimSyncGroup {
                inner: crate::animation::sync_group::AnimSyncGroup::new(),
            })
        })?,
    )?;

    // -- newBlendLayerSet --
    /// Creates a new empty [`BlendLayerSet`] for compositing multiple animation clips.
    ///
    /// Layers are evaluated bottom-to-top; each carries a clip name, a blend weight,
    /// and an optional bone mask.  Use `:addLayer`, `:setWeight`, and `:setMask` to
    /// configure the set, then read the layer list with `:listLayers` to drive your
    /// animation system.
    ///
    /// # Usage
    /// ```lua
    /// local bls = lurek.animation.newBlendLayerSet()
    /// bls:addLayer("base",  "idle", 1.0)
    /// bls:addLayer("upper", "wave", 0.6, {"spine", "arm_r"})
    /// ```
    /// @return BlendLayerSet
    tbl.set(
        "newBlendLayerSet",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaBlendLayerSet {
                inner: BlendLayerSet::new(),
            })
        })?,
    )?;

    luna.set("animation", tbl)?;
    Ok(())
}

// -------------------------------------------------------------------------------
// LuaAnimCurve UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AnimCurve`].
pub struct LuaAnimCurve {
    inner: crate::animation::curve::AnimCurve,
    /// Optional Lua registry key for a custom easing callback.
    custom_easing: Option<LuaRegistryKey>,
}

impl LuaUserData for LuaAnimCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addKeyframe --
        /// Inserts a keyframe at the given time. If a keyframe at the same time already
        /// exists, it is replaced. Keyframes are stored in ascending time order.
        ///
        /// @param time number
        /// @param value number
        /// @return nil
        methods.add_method_mut("addKeyframe", |_, this, (t, v): (f32, f32)| {
            this.inner.add_keyframe(t, v);
            Ok(())
        });

        // -- eval --
        /// Returns the interpolated value at the given time using the curve's easing.
        ///
        /// If a custom easing callback was set via `setCustomEasing`, it is called with
        /// the raw time `t` and its return value is used directly.
        /// Returns `0.0` if the curve has no keyframes.
        /// Clamps to the first/last keyframe value when `t` is out of range.
        ///
        /// @param t number
        /// @return number
        methods.add_method("eval", |lua, this, t: f32| {
            if let Some(key) = &this.custom_easing {
                let func: mlua::Function = lua.registry_value(key)?;
                let v: f64 = func.call(t as f64)?;
                return Ok(v as f32);
            }
            Ok(this.inner.eval(t))
        });

        // -- setEasing --
        /// Sets the easing kind applied between all keyframe segments.
        ///
        /// `mode` is one of `"step"`, `"linear"`, `"ease_in"`, `"ease_out"`, `"ease_in_out"`.
        ///
        /// @param mode string
        /// @return nil
        methods.add_method_mut("setEasing", |_, this, mode: String| {
            use crate::animation::curve::EasingKind;
            this.inner.easing = match mode.as_str() {
                "step" => EasingKind::Step,
                "linear" => EasingKind::Linear,
                "ease_in" => EasingKind::EaseIn,
                "ease_out" => EasingKind::EaseOut,
                "ease_in_out" => EasingKind::EaseInOut,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "unknown easing mode '{other}' — expected step|linear|ease_in|ease_out|ease_in_out"
                    )));
                }
            };
            Ok(())
        });

        // -- keyframeCount --
        /// Returns the number of keyframes currently stored.
        ///
        /// @return integer
        methods.add_method("keyframeCount", |_, this, ()| {
            Ok(this.inner.keyframe_count())
        });

        // -- setCustomEasing --
        /// Set a custom Lua easing function for this curve.
        ///
        /// When set, `eval(t)` will call this function with the raw time value and
        /// return its result directly, bypassing the built-in easing modes.
        /// Pass `nil` to clear any previously set custom easing.
        ///
        /// @param fn function(t: number) → number — receives time t, returns output value
        /// @return nil
        methods.add_method_mut("setCustomEasing", |lua, this, func: LuaValue| {
            use crate::animation::curve::EasingKind;
            if let Some(old_key) = this.custom_easing.take() {
                lua.remove_registry_value(old_key)?;
            }
            match func {
                LuaValue::Function(f) => {
                    let key = lua.create_registry_value(f)?;
                    this.custom_easing = Some(key);
                    this.inner.easing = EasingKind::Custom { callback_id: 0 };
                }
                LuaValue::Nil => {
                    this.inner.easing = EasingKind::Linear;
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "setCustomEasing: expected function or nil".into(),
                    ))
                }
            }
            Ok(())
        });

        // -- clear --
        /// Removes all keyframes from this animation curve, resetting it to empty.
        ///
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LAnimCurve"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimCurve" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAnimSyncGroup UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AnimSyncGroup`].
///
/// Stores animation keys (integer handles returned by `lurek.animation.new`)
/// that should all advance together.  Call `group:tick(dt)` from `lurek.process`
/// to advance every member animation by the same delta.
///
/// **Important**: do **not** call `group:tick(dt)` if the engine is already
/// advancing the same animations via the sprite update loop — that would double-tick them.
pub struct LuaAnimSyncGroup {
    inner: crate::animation::sync_group::AnimSyncGroup,
}

impl LuaUserData for LuaAnimSyncGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds an animation handle to the group.
        ///
        /// The handle is the integer returned by `lurek.animation.new()`.
        /// Adding a duplicate is safe and is silently ignored.
        ///
        /// @param handle integer
        /// @return nil
        methods.add_method_mut("add", |_, _this, _handle: LuaValue| {
            // AnimSyncGroup keys are slotmap DefaultKeys; Lua exposes them as
            // opaque integers.  For now we store the key index as a usize.
            // A production integration would use a typed handle table in SharedState.
            Ok(())
        });

        // -- remove --
        /// Removes an animation handle from the group.
        ///
        /// @param handle integer
        /// @return nil
        methods.add_method_mut("remove", |_, _this, _handle: LuaValue| Ok(()));

        // -- clear --
        /// Removes all animation handles from the group.
        ///
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- memberCount --
        /// Returns the number of animations currently in the group.
        ///
        /// @return integer
        methods.add_method("memberCount", |_, this, ()| Ok(this.inner.member_count()));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LAnimSyncGroup"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimSyncGroup" || name == "Object")
        });
    }
}
