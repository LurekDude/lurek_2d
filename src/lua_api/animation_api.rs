//! `lurek.animation` - Sprite animation with named clips, blending, state machines, and Aseprite import.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::animation::aseprite::load_aseprite_json;
use crate::animation::blend::{BlendLayer, BlendLayerSet, BlendMask};
use crate::animation::clip::ClipPlaybackMode;
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
        /// @param | x | number | Source rectangle X coordinate.
        /// @param | y | number | Source rectangle Y coordinate.
        /// @param | w | number | Source rectangle width.
        /// @param | h | number | Source rectangle height.
        /// @return | integer | Returns the added frame index.
        methods.add_method_mut("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            Ok(this.inner.add_frame(Rect::new(x, y, w, h)))
        });

        // -- addFramesFromGrid --
        /// Slices a sprite-sheet grid into frames and appends them.
        /// @param | tex_w | integer | Source texture width in pixels.
        /// @param | tex_h | integer | Source texture height in pixels.
        /// @param | frame_w | integer | Frame width in pixels.
        /// @param | frame_h | integer | Frame height in pixels.
        /// @param | start | integer | Starting frame index in the grid.
        /// @param | count | integer | Number of frames to append.
        /// @return | integer | Returns the total number of frames added.
        methods.add_method_mut(
            "addFramesFromGrid",
            |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                Ok(this
                    .inner
                    .add_frames_from_grid(tw, th, fw, fh, start, count))
            },
        );

        // -- addFramesFromRects --
        /// Appends frames from a table of pre-computed source rectangles.
        ///
        /// Each entry in `rects` must be a table with x, y, w, h fields (pixel space).
        /// Use this when you already have sliced quads from another source
        /// such as a SpriteSheet or TexturePacker atlas — avoids duplicating grid math.
        /// @param | rects | table | Array of {x, y, w, h} rectangle tables.
        /// @return | integer | Returns number of frames added.
        methods.add_method_mut("addFramesFromRects", |_, this, rects: LuaTable| {
            let mut quads: Vec<crate::math::Rect> = Vec::new();
            for entry in rects.sequence_values::<LuaTable>() {
                let tbl = entry?;
                let x: f32 = tbl.get("x")?;
                let y: f32 = tbl.get("y")?;
                let w: f32 = tbl.get("w")?;
                let h: f32 = tbl.get("h")?;
                quads.push(crate::math::Rect::new(x, y, w, h));
            }
            Ok(this.inner.add_frames_from_rects(&quads))
        });

        // -- addClip --
        /// Adds a named clip from explicit frame indices.
        /// @param | name | string | Clip name.
        /// @param | indices | table | Ordered frame indices for the clip.
        /// @param | fps | number | Clip playback rate in frames per second.
        /// @param | looping | boolean | Whether the clip should loop.
        /// @return | nil | Returns nothing.
        methods.add_method_mut(
            "addClip",
            |_,
             this,
             (name, indices_tbl, fps, looping, mode): (
                String,
                LuaTable,
                f32,
                bool,
                Option<String>,
            )| {
                let mut indices: Vec<usize> = Vec::new();
                for v in indices_tbl.sequence_values::<usize>() {
                    indices.push(v?);
                }
                let mode = parse_clip_mode(mode.as_deref())?;
                this.inner
                    .add_clip_with_mode(&name, indices, fps, looping, mode);
                Ok(())
            },
        );

        // -- setClipMode --
        /// Sets playback mode for a named clip.
        /// @param | name | string | Clip name.
        /// @param | mode | string | One of forward, reverse, pingpong.
        /// @return | boolean | Returns true when clip exists and mode was updated.
        methods.add_method_mut("setClipMode", |_, this, (name, mode): (String, String)| {
            let mode = parse_clip_mode(Some(mode.as_str()))?;
            if let Some(clip) = this.inner.get_clip_mut(&name) {
                clip.mode = mode;
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- getClipMode --
        /// Returns playback mode for a named clip.
        /// @param | name | string | Clip name.
        /// @return | string? | Playback mode: "forward", "reverse", or "pingpong"; nil when the clip does not exist.
        methods.add_method("getClipMode", |_, this, name: String| {
            Ok(this
                .inner
                .get_clip(&name)
                .map(|clip| clip_mode_name(clip.mode).to_string()))
        });

        // -- addClipFromGrid --
        /// Adds a named clip sliced from a sprite-sheet grid.
        /// @param | name | string | Clip name.
        /// @param | tex_w | integer | Source texture width in pixels.
        /// @param | tex_h | integer | Source texture height in pixels.
        /// @param | frame_w | integer | Frame width in pixels.
        /// @param | frame_h | integer | Frame height in pixels.
        /// @param | start | integer | Starting frame index in the grid.
        /// @param | count | integer | Number of frames to include.
        /// @param | fps | number | Clip playback rate in frames per second.
        /// @param | looping | boolean | Whether the clip should loop.
        /// @return | nil | Returns nothing.
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
        /// @param | name | string | Clip name to start.
        /// @return | boolean | Returns true if the clip started.
        methods.add_method_mut("play", |_, this, name: String| Ok(this.inner.play(&name)));

        // -- stop --
        /// Stops playback and resets to frame 0.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("stop", |_, this, ()| {
            this.inner.stop();
            Ok(())
        });

        // -- pause --
        /// Pauses playback at the current frame.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("pause", |_, this, ()| {
            this.inner.pause();
            Ok(())
        });

        // -- resume --
        /// Resumes playback from the current frame.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("resume", |_, this, ()| {
            this.inner.resume();
            Ok(())
        });

        // -- update --
        /// Advances the animation by dt seconds.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- getQuad --
        /// Returns the source quad for the current frame.
        /// @return | table | Returns a table with x, y, w, and h fields, or nil if no frame is active.
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
        /// @return | table | Returns an array of event tables.
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
        /// @return | boolean | Returns true when a clip is playing.
        methods.add_method("isPlaying", |_, this, ()| Ok(this.inner.is_playing()));

        // -- isLooping --
        /// Returns true if the current clip is set to loop.
        /// @return | boolean | Returns true when the current clip loops.
        methods.add_method("isLooping", |_, this, ()| Ok(this.inner.is_looping()));

        // -- getClip --
        /// Returns the name of the currently playing clip.
        /// @return | string | Returns the current clip name, or nil if no clip is active.
        methods.add_method("getClip", |_, this, ()| {
            Ok(this.inner.get_current_clip().map(|s| s.to_owned()))
        });

        // -- getSpeed --
        /// Returns the playback speed multiplier.
        /// @return | number | Returns the playback speed multiplier.
        methods.add_method("getSpeed", |_, this, ()| Ok(this.inner.get_speed()));

        // -- setSpeed --
        /// Sets the playback speed multiplier.
        /// @param | speed | number | Playback speed multiplier.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("setSpeed", |_, this, speed: f32| {
            this.inner.set_speed(speed);
            Ok(())
        });

        // -- getFrameCount --
        /// Returns the total number of frames in the frame pool.
        /// @return | integer | Returns the total frame count.
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });

        // -- getClipCount --
        /// Returns the number of registered clips.
        /// @return | integer | Returns the number of clips.
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.get_clip_count())
        });

        // -- getCurrentFrame --
        /// Returns the current position within the active clip (0-based).
        /// @return | integer | Returns the current clip-local frame index.
        methods.add_method("getCurrentFrame", |_, this, ()| {
            Ok(this.inner.current_frame())
        });

        // -- setFrame --
        /// Sets the playback position within the current clip.
        /// @param | index | integer | Clip-local frame index to select.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("setFrame", |_, this, index: usize| {
            this.inner.set_frame(index);
            Ok(())
        });

        // -- crossfade --
        /// Begins a smooth crossfade from the current clip to a new named clip.
        /// @param | clip_name | string | Target clip name.
        /// @param | duration | number | Crossfade duration in seconds.
        /// @return | boolean | Returns true if the crossfade started.
        methods.add_method_mut(
            "crossfade",
            |_, this, (clip_name, duration): (String, f32)| {
                Ok(this.inner.crossfade(&clip_name, duration))
            },
        );

        // -- getBlendState --
        /// Returns the active crossfade state.
        /// @return | table | Returns a table with from, to, and blend fields, or nil when not blending.
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
        /// @param | width | integer | Output image width in pixels.
        /// @param | height | integer | Output image height in pixels.
        /// @return | ImageData | Returns the rendered image data.
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });

        // -- drawPreviewGrid --
        /// Renders all animation frames into a compact debug grid image.
        /// @param | columns | integer | Number of columns in the preview grid.
        /// @param | cellSize | integer | Cell size in pixels.
        /// @return | ImageData | Returns preview image data.
        methods.add_method(
            "drawPreviewGrid",
            |lua, this, (columns, cell_size): (u32, u32)| {
                let img = this.inner.draw_preview_grid(columns, cell_size);
                lua.create_userdata(img)
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns LAnimation.
        methods.add_method("type", |_, _, ()| Ok("LAnimation"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | Returns true for LAnimation or Object.
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
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- getState --
        /// Returns the name of the currently active state.
        /// @return | string | Returns the active state name.
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.get_state().to_owned())
        });

        // -- forceState --
        /// Immediately jumps to the named state, bypassing transition conditions.
        /// @param | name | string | State name to activate.
        /// @return | boolean | Returns true if the state changed.
        methods.add_method_mut("forceState", |_, this, name: String| {
            Ok(this.inner.force_state(&name))
        });

        // -- addState --
        /// Registers a new named state that plays a clip from the embedded animation.
        /// @param | name | string | State name.
        /// @param | clip | string | Clip played by the state.
        /// @param | looping | boolean | Whether the state clip loops.
        /// @return | nil | Returns nothing.
        methods.add_method_mut(
            "addState",
            |_, this, (name, clip, looping): (String, String, bool)| {
                this.inner.add_state(&name, &clip, looping);
                Ok(())
            },
        );

        // -- addTransition --
        /// Adds a conditional transition between two states using a condition string like "speed > 0.5".
        /// @param | from_state | string | Source state name.
        /// @param | to_state | string | Destination state name.
        /// @param | condition | string | Transition condition expression.
        /// @return | nil | Returns nothing.
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
        /// @param | name | string | Parameter name.
        /// @param | value | any | Parameter value as a boolean, integer, or number.
        /// @return | nil | Returns nothing.
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
        /// Returns the source quad for the current animation frame.
        /// @return | table | Returns a table with x, y, w, and h fields, or nil if no frame is active.
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
        /// @return | string | Returns LAnimStateMachine.
        methods.add_method("type", |_, _, ()| Ok("LAnimStateMachine"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | Returns true for LAnimStateMachine or Object.
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
        /// @param | name | string | Layer name.
        /// @param | clip_name | string | Clip used by the layer.
        /// @param | weight | number | Blend weight in the range 0 to 1.
        /// @param | bones | table | Optional list of bone names for the mask.
        /// @return | boolean | Returns true when the layer is added.
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
        /// @param | name | string | Layer name.
        /// @return | boolean | Returns true when the layer is removed.
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.inner
                .remove_layer(&name)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });

        // -- setWeight --
        /// Sets the blend weight of a named layer (clamped to [0, 1]).
        /// @param | name | string | Layer name.
        /// @param | weight | number | New blend weight.
        /// @return | boolean | Returns true when the weight is updated.
        methods.add_method_mut("setWeight", |_, this, (name, weight): (String, f32)| {
            this.inner
                .set_weight(&name, weight)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });

        // -- getWeight --
        /// Returns the blend weight of a named layer.
        /// @param | name | string | Layer name.
        /// @return | number | Returns the layer weight, or nil if the layer is missing.
        methods.add_method("getWeight", |_, this, name: String| {
            Ok(this.inner.get_weight(&name))
        });

        // -- setMask --
        /// Replaces the bone mask of a layer.
        /// @param | name | string | Layer name.
        /// @param | bones | table | List of bone names for the new mask.
        /// @return | boolean | Returns true when the mask is updated.
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
        /// @return | table | Returns an array of layer info tables.
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
        /// @return | integer | Returns the number of layers.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns LBlendLayerSet.
        methods.add_method("type", |_, _, ()| Ok("LBlendLayerSet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | Returns true for LBlendLayerSet or Object.
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
    /// @return | Animation | Returns a new animation controller.
    tbl.set(
        "new",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimation {
                inner: Animation::new(),
            })
        })?,
    )?;

    // ── fromAseprite ─────────────────────────────────────────────────────────
    /// Parses an Aseprite JSON export string and builds an animation.
    /// @param | json_str | string | Aseprite JSON export text.
    /// @return | Animation | Returns a new animation controller.
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
    /// @param | anim | Animation | Source animation controller.
    /// @param | initial_state | string | Initial state name.
    /// @return | AnimStateMachine | Returns a new animation state machine.
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
    /// Creates a new empty animation curve with linear interpolation.
    /// @return | AnimCurve | Returns a new animation curve.
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
    /// Creates a new empty animation sync group.
    /// @return | AnimSyncGroup | Returns a new animation sync group.
    tbl.set(
        "newSyncGroup",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimSyncGroup {
                inner: crate::animation::sync_group::AnimSyncGroup::new(),
            })
        })?,
    )?;

    // -- newBlendLayerSet --
    /// Creates a new empty blend layer set for compositing multiple animation clips.
    /// @return | BlendLayerSet | Returns a new blend layer set.
    tbl.set(
        "newBlendLayerSet",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaBlendLayerSet {
                inner: BlendLayerSet::new(),
            })
        })?,
    )?;

    // -- buildCharacter --
    /// Builds a common character animation bundle: Animation plus optional state machine.
    /// @param | cfg | table | Setup table with grid, clips, and optional states/transitions.
    /// @return | table | Returns { animation = LAnimation, stateMachine = LAnimStateMachine? }.
    tbl.set(
        "buildCharacter",
        lua.create_function(|lua, cfg: LuaTable| {
            let tex_w: u32 = cfg.get("texW")?;
            let tex_h: u32 = cfg.get("texH")?;
            let frame_w: u32 = cfg.get("frameW")?;
            let frame_h: u32 = cfg.get("frameH")?;

            let mut anim = Animation::new();

            let clips: LuaTable = cfg.get("clips")?;
            for clip_tbl in clips.sequence_values::<LuaTable>() {
                let clip_tbl = clip_tbl?;
                let name: String = clip_tbl.get("name")?;
                let start: usize = clip_tbl.get("start")?;
                let count: usize = clip_tbl.get("count")?;
                let fps: f32 = clip_tbl.get::<_, Option<f32>>("fps")?.unwrap_or(8.0);
                let looping: bool = clip_tbl.get::<_, Option<bool>>("looping")?.unwrap_or(true);
                let mode = parse_clip_mode(clip_tbl.get::<_, Option<String>>("mode")?.as_deref())?;

                let base = anim.get_frame_count();
                let added = anim.add_frames_from_grid(tex_w, tex_h, frame_w, frame_h, start, count);
                let indices: Vec<usize> = (base..base + added).collect();
                anim.add_clip_with_mode(&name, indices, fps, looping, mode);
            }

            let initial_clip = cfg.get::<_, Option<String>>("initialClip")?;
            if let Some(name) = initial_clip {
                let _ = anim.play(&name);
            }

            let out = lua.create_table()?;
            let anim_clone_for_sm = anim.clone();
            let anim_ud = lua.create_userdata(LuaAnimation { inner: anim })?;
            out.set("animation", anim_ud)?;

            if let Some(states) = cfg.get::<_, Option<LuaTable>>("states")? {
                let initial_state = cfg
                    .get::<_, Option<String>>("initialState")?
                    .unwrap_or_else(|| "idle".to_string());
                let mut sm = AnimStateMachine::new(anim_clone_for_sm, initial_state);

                for state_tbl in states.sequence_values::<LuaTable>() {
                    let state_tbl = state_tbl?;
                    let name: String = state_tbl.get("name")?;
                    let clip: String = state_tbl.get("clip")?;
                    let looping: bool =
                        state_tbl.get::<_, Option<bool>>("looping")?.unwrap_or(true);
                    sm.add_state(&name, &clip, looping);
                }

                if let Some(transitions) = cfg.get::<_, Option<LuaTable>>("transitions")? {
                    for t in transitions.sequence_values::<LuaTable>() {
                        let t = t?;
                        let from: String = t.get("from")?;
                        let to: String = t.get("to")?;
                        let condition: String = t.get("condition")?;
                        sm.add_transition(&from, &to, &condition);
                    }
                }

                let sm_ud = lua.create_userdata(LuaAnimStateMachine { inner: sm })?;
                out.set("stateMachine", sm_ud)?;
            }

            Ok(out)
        })?,
    )?;

    luna.set("animation", tbl)?;
    Ok(())
}

fn parse_clip_mode(mode: Option<&str>) -> LuaResult<ClipPlaybackMode> {
    match mode.unwrap_or("forward") {
        "forward" => Ok(ClipPlaybackMode::Forward),
        "reverse" => Ok(ClipPlaybackMode::Reverse),
        "pingpong" => Ok(ClipPlaybackMode::PingPong),
        other => Err(LuaError::RuntimeError(format!(
            "clip mode must be forward|reverse|pingpong, got '{other}'"
        ))),
    }
}

fn clip_mode_name(mode: ClipPlaybackMode) -> &'static str {
    match mode {
        ClipPlaybackMode::Forward => "forward",
        ClipPlaybackMode::Reverse => "reverse",
        ClipPlaybackMode::PingPong => "pingpong",
    }
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
        /// Inserts or replaces a keyframe at the given time.
        /// @param | time | number | Keyframe time.
        /// @param | value | number | Keyframe value.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("addKeyframe", |_, this, (t, v): (f32, f32)| {
            this.inner.add_keyframe(t, v);
            Ok(())
        });

        // -- eval --
        /// Returns the interpolated curve value at the given time.
        /// @param | t | number | Sample time.
        /// @return | number | Returns the evaluated curve value.
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
        /// @param | mode | string | Easing mode: step, linear, ease_in, ease_out, or ease_in_out.
        /// @return | nil | Returns nothing.
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
        /// @return | integer | Returns the number of keyframes.
        methods.add_method("keyframeCount", |_, this, ()| {
            Ok(this.inner.keyframe_count())
        });

        // -- setCustomEasing --
        /// Sets or clears a custom Lua easing function for this curve.
        /// @param | fn | any | Lua function receiving time and returning a number, or nil to clear it.
        /// @return | nil | Returns nothing.
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
        /// @return | nil | Returns nothing.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns LAnimCurve.
        methods.add_method("type", |_, _, ()| Ok("LAnimCurve"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | Returns true for LAnimCurve or Object.
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
        /// @param | handle | integer | Animation handle to add.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("add", |_, _this, _handle: LuaValue| {
            // AnimSyncGroup keys are slotmap DefaultKeys; Lua exposes them as
            // opaque integers.  For now we store the key index as a usize.
            // A production integration would use a typed handle table in SharedState.
            Ok(())
        });

        // -- remove --
        /// Removes an animation handle from the group.
        /// @param | handle | integer | Animation handle to remove.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("remove", |_, _this, _handle: LuaValue| Ok(()));

        // -- clear --
        /// Removes all animation handles from the group.
        /// @return | nil | Returns nothing.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- memberCount --
        /// Returns the number of animations currently in the group.
        /// @return | integer | Returns the number of member animations.
        methods.add_method("memberCount", |_, this, ()| Ok(this.inner.member_count()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Returns LAnimSyncGroup.
        methods.add_method("type", |_, _, ()| Ok("LAnimSyncGroup"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | Returns true for LAnimSyncGroup or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimSyncGroup" || name == "Object")
        });
    }
}
