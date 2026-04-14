//! `lurek.animation` — Sprite animation: frame pools, named clips, speed control, playback events,
//! crossfade blending, stat-machine FSMs, and Aseprite JSON import.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::animation::aseprite::load_aseprite_json;
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
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return integer
        methods.add_method_mut("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            Ok(this.inner.add_frame(Rect::new(x, y, w, h)))
        });

        // -- addFramesFromGrid --
        /// Slices a sprite-sheet grid into frames and appends them.
        /// @param tex_w : integer
        /// @param tex_h : integer
        /// @param frame_w : integer
        /// @param frame_h : integer
        /// @param start : integer
        /// @param count : integer
        /// @return integer
        methods.add_method_mut("addFramesFromGrid", |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                Ok(this
                    .inner
                    .add_frames_from_grid(tw, th, fw, fh, start, count))
            },
        );

        // -- addClip --
        /// Adds a named clip from explicit frame indices.
        /// @param name : string
        /// @param indices : table
        /// @param fps : number
        /// @param looping : boolean
        /// @return nil
        methods.add_method_mut("addClip", |_, this, (name, indices_tbl, fps, looping): (String, LuaTable, f32, bool)| {
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
        /// @param name : string
        /// @param tex_w : integer
        /// @param tex_h : integer
        /// @param frame_w : integer
        /// @param frame_h : integer
        /// @param start : integer
        /// @param count : integer
        /// @param fps : number
        /// @param looping : boolean
        /// @return nil
        methods.add_method_mut("addClipFromGrid", |_, this, (name, tw, th, fw, fh, start, count, fps, looping): (String, u32, u32, u32, u32, usize, usize, f32, bool)| {
                this.inner
                    .add_clip_from_grid(&name, tw, th, fw, fh, start, count, fps, looping);
                Ok(())
            },
        );

        // -- play --
        /// Starts playback of the named clip.
        /// @param name : string
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
        /// @param dt : number
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
        /// @param speed : number
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
        /// @param index : integer
        /// @return nil
        methods.add_method_mut("setFrame", |_, this, index: usize| {
            this.inner.set_frame(index);
            Ok(())
        });

        // -- crossfade --
        /// Begins a smooth crossfade from the current clip to a new named clip.
        /// @param clip_name : string
        /// @param duration : number
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
        /// @param width : integer
        /// @param height : integer
        /// @return ImageData
        methods.add_method(
            "drawToImage",
            |lua, this, (w, h): (u32, u32)| {
                let img = this.inner.draw_to_image(w, h);
                lua.create_userdata(LuaImageData { inner: img })
            },
        );
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
        /// @param dt : number
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
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("forceState", |_, this, name: String| {
            Ok(this.inner.force_state(&name))
        });

        // -- addState --
        /// Registers a new named state that plays a clip from the embedded animation.
        /// @param name : string
        /// @param clip : string
        /// @param looping : boolean
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
        /// @param from_state : string
        /// @param to_state : string
        /// @param condition : string
        /// @return nil
        methods.add_method_mut(
            "addTransition",
            |_, this, (from_state, to_state, condition): (String, String, String)| {
                this.inner.add_transition(&from_state, &to_state, &condition);
                Ok(())
            },
        );

        // -- setParam --
        /// Sets an FSM parameter value (number, boolean, or integer supported).
        /// @param name : string
        /// @param value : number|boolean
        /// @return nil
        methods.add_method_mut(
            "setParam",
            |_, this, (name, value): (String, LuaValue)| {
                let param = match value {
                    LuaValue::Boolean(b) => AnimParamValue::Bool(b),
                    LuaValue::Integer(i) => AnimParamValue::Int(i as i32),
                    LuaValue::Number(f) => AnimParamValue::Float(f as f32),
                    _ => return Err(LuaError::RuntimeError(
                        "setParam: value must be boolean, integer, or number".into(),
                    )),
                };
                this.inner.set_param(&name, param);
                Ok(())
            },
        );

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
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.animation` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
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
    /// Returns nil and an error message on parse failure.
    /// @param json_str : string
    /// @return Animation?
    tbl.set(
        "fromAseprite",
        lua.create_function(|lua, json_str: String| {
            match load_aseprite_json(&json_str) {
                Ok(parsed) => {
                    let anim = Animation::load_from_aseprite(&parsed);
                    let ud = lua.create_userdata(LuaAnimation { inner: anim })?;
                    Ok(LuaValue::UserData(ud))
                }
                Err(e) => Err(LuaError::RuntimeError(format!(
                    "fromAseprite: {}",
                    e
                ))),
            }
        })?,
    )?;

    // ── newStateMachine ───────────────────────────────────────────────────────
    /// Creates an animation FSM from an Animation controller and an initial state name.
    /// @param anim : Animation
    /// @param initial_state : string
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

    luna.set("animation", tbl)?;
    Ok(())
}
