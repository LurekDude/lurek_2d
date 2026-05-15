//! `lurek.animation` -- Animation bindings for sprite clips, state machines, blend layers, curves, sync groups, and Aseprite import helpers.

use super::SharedState;
use crate::animation::aseprite::load_aseprite_json;
use crate::animation::blend::{BlendLayer, BlendLayerSet, BlendMask};
use crate::animation::clip::ClipPlaybackMode;
use crate::animation::state_machine::{AnimParamValue, AnimStateMachine};
use crate::animation::Animation;
use crate::math::Rect;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Lua-side animation object containing frame rectangles, named clips, playback state, and blend state.
pub struct LuaAnimation {
    /// Owned animation data exposed through this userdata handle.
    inner: Animation,
}
impl LuaUserData for LuaAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addFrame --
        /// Adds one frame rectangle to this animation.
        /// @param | x | number | Frame X coordinate in texture pixels.
        /// @param | y | number | Frame Y coordinate in texture pixels.
        /// @param | w | number | Frame width in texture pixels.
        /// @param | h | number | Frame height in texture pixels.
        /// @return | integer | Index of the inserted frame.
        methods.add_method_mut("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            Ok(this.inner.add_frame(Rect::new(x, y, w, h)))
        });
        // -- addFramesFromGrid --
        /// Adds frames by slicing a texture grid.
        /// @param | tw | integer | Texture width in pixels.
        /// @param | th | integer | Texture height in pixels.
        /// @param | fw | integer | Frame width in pixels.
        /// @param | fh | integer | Frame height in pixels.
        /// @param | start | integer | Zero-based grid cell index where import begins.
        /// @param | count | integer | Number of frames to add.
        /// @return | integer | Number of frames inserted.
        methods.add_method_mut(
            "addFramesFromGrid",
            |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                Ok(this
                    .inner
                    .add_frames_from_grid(tw, th, fw, fh, start, count))
            },
        );
        // -- addFramesFromRects --
        /// Adds frames from an array of rectangle tables.
        /// @param | rects | table | Array of tables with numeric `x`, `y`, `w`, and `h` fields.
        /// @return | integer | Number of frames inserted.
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
        /// Adds a named clip using existing frame indices.
        /// @param | name | string | Clip name used by playback and state machines.
        /// @param | indices_tbl | table | Array of frame indices that make up the clip.
        /// @param | fps | number | Playback speed in frames per second.
        /// @param | looping | boolean | True when playback should wrap at the end.
        /// @param | mode | string? | Playback mode `forward`, `reverse`, or `pingpong`; defaults to `forward`.
        /// @return | nil | No value is returned.
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
        /// Changes the playback mode for an existing clip.
        /// @param | name | string | Clip name to update.
        /// @param | mode | string | Playback mode `forward`, `reverse`, or `pingpong`.
        /// @return | boolean | True when the clip exists and the mode was changed.
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
        /// Returns the playback mode name for a clip when it exists.
        /// @param | name | string | Clip name to query.
        /// @return | LuaValue | Playback mode string, or nil when the clip does not exist.
        methods.add_method("getClipMode", |_, this, name: String| {
            Ok(this
                .inner
                .get_clip(&name)
                .map(|clip| clip_mode_name(clip.mode).to_string()))
        });
        // -- addClipFromGrid --
        /// Adds frames from a texture grid and creates a clip that references the new frames.
        /// @param | name | string | Clip name to create.
        /// @param | tw | integer | Texture width in pixels.
        /// @param | th | integer | Texture height in pixels.
        /// @param | fw | integer | Frame width in pixels.
        /// @param | fh | integer | Frame height in pixels.
        /// @param | start | integer | Zero-based grid cell index where import begins.
        /// @param | count | integer | Number of frames to add.
        /// @param | fps | number | Playback speed in frames per second.
        /// @param | looping | boolean | True when playback should wrap at the end.
        /// @return | nil | No value is returned.
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
        /// Starts playback of a named clip. This method is available to Lua scripts.
        /// @param | name | string | Clip name to play.
        /// @return | boolean | True when the clip exists and playback started.
        methods.add_method_mut("play", |_, this, name: String| Ok(this.inner.play(&name)));
        // -- stop --
        /// Stops playback and resets animation playback state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("stop", |_, this, ()| {
            this.inner.stop();
            Ok(())
        });
        // -- pause --
        /// Pauses animation playback without changing the current clip.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pause", |_, this, ()| {
            this.inner.pause();
            Ok(())
        });
        // -- resume --
        /// Resumes playback of a paused animation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("resume", |_, this, ()| {
            this.inner.resume();
            Ok(())
        });
        // -- update --
        /// Advances animation playback and records any frame or clip events.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        // -- getQuad --
        /// Returns the current frame rectangle as a table.
        /// @return | LuaValue | Table with `x`, `y`, `w`, and `h`, or nil when no frame is active.
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
        /// Drains animation events produced since the previous poll.
        /// @return | table | Array of event tables with `type` and optional `frame` fields.
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
        /// Returns whether this animation is currently playing.
        /// @return | boolean | True when playback is active.
        methods.add_method("isPlaying", |_, this, ()| Ok(this.inner.is_playing()));
        // -- isLooping --
        /// Returns whether the current clip loops.
        /// @return | boolean | True when the active clip is looping.
        methods.add_method("isLooping", |_, this, ()| Ok(this.inner.is_looping()));
        // -- getClip --
        /// Returns the current clip name when a clip is active.
        /// @return | LuaValue | Current clip name, or nil when no clip is active.
        methods.add_method("getClip", |_, this, ()| {
            Ok(this.inner.get_current_clip().map(|s| s.to_owned()))
        });
        // -- getSpeed --
        /// Returns the animation playback speed multiplier.
        /// @return | number | Current playback speed multiplier.
        methods.add_method("getSpeed", |_, this, ()| Ok(this.inner.get_speed()));
        // -- setSpeed --
        /// Sets the animation playback speed multiplier.
        /// @param | speed | number | Playback speed multiplier used by future updates.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSpeed", |_, this, speed: f32| {
            this.inner.set_speed(speed);
            Ok(())
        });
        // -- getFrameCount --
        /// Returns the number of frame rectangles stored in this animation.
        /// @return | integer | Frame count.
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });
        // -- getClipCount --
        /// Returns the number of named clips stored in this animation.
        /// @return | integer | Clip count.
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.get_clip_count())
        });
        // -- getCurrentFrame --
        /// Returns the current frame index. This method is available to Lua scripts.
        /// @return | integer | Current frame index.
        methods.add_method("getCurrentFrame", |_, this, ()| {
            Ok(this.inner.current_frame())
        });
        // -- setFrame --
        /// Sets the current frame index directly.
        /// @param | index | integer | Frame index to make current.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFrame", |_, this, index: usize| {
            this.inner.set_frame(index);
            Ok(())
        });
        // -- crossfade --
        /// Starts a crossfade from the current clip to another clip.
        /// @param | clip_name | string | Destination clip name.
        /// @param | duration | number | Crossfade duration in seconds.
        /// @return | boolean | True when the destination clip exists and crossfade started.
        methods.add_method_mut(
            "crossfade",
            |_, this, (clip_name, duration): (String, f32)| {
                Ok(this.inner.crossfade(&clip_name, duration))
            },
        );
        // -- getBlendState --
        /// Returns current crossfade rectangles and blend factor when a crossfade is active.
        /// @return | LuaValue | Table with `from`, `to`, and `blend`, or nil when no blend is active.
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
        /// Rasterizes the current animation frame into an image userdata.
        /// @param | w | integer | Output image width in pixels.
        /// @param | h | integer | Output image height in pixels.
        /// @return | ImageData | Image data containing the rendered frame.
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });
        // -- drawPreviewGrid --
        /// Rasterizes all animation frames into a preview grid image.
        /// @param | columns | integer | Number of columns in the preview grid.
        /// @param | cell_size | integer | Size of each preview cell in pixels.
        /// @return | ImageData | Image data containing the preview grid.
        methods.add_method(
            "drawPreviewGrid",
            |lua, this, (columns, cell_size): (u32, u32)| {
                let img = this.inner.draw_preview_grid(columns, cell_size);
                lua.create_userdata(img)
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this animation handle.
        /// @return | string | The string `LAnimation`.
        methods.add_method("type", |_, _, ()| Ok("LAnimation"));
        // -- typeOf --
        /// Returns whether this animation handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAnimation` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimation" || name == "Object")
        });
    }
}
/// Lua-side animation state machine that switches clips from named states and parameters.
pub struct LuaAnimStateMachine {
    /// Owned animation state machine exposed through this userdata handle.
    inner: AnimStateMachine,
}
impl LuaUserData for LuaAnimStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the animation state machine and its owned animation playback.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        // -- getState --
        /// Returns the current animation state name.
        /// @return | string | Current state name.
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.get_state().to_owned())
        });
        // -- forceState --
        /// Forces the state machine into a named state.
        /// @param | name | string | State name to activate immediately.
        /// @return | boolean | True when the state exists and was activated.
        methods.add_method_mut("forceState", |_, this, name: String| {
            Ok(this.inner.force_state(&name))
        });
        // -- addState --
        /// Adds a state that plays a named animation clip.
        /// @param | name | string | State name.
        /// @param | clip | string | Clip name to play while this state is active.
        /// @param | looping | boolean | True when the clip should loop in this state.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addState",
            |_, this, (name, clip, looping): (String, String, bool)| {
                this.inner.add_state(&name, &clip, looping);
                Ok(())
            },
        );
        // -- addTransition --
        /// Adds a named-condition transition between two animation states.
        /// @param | from_state | string | Source state name.
        /// @param | to_state | string | Destination state name.
        /// @param | condition | string | Parameter condition expression understood by the state machine.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addTransition",
            |_, this, (from_state, to_state, condition): (String, String, String)| {
                this.inner
                    .add_transition(&from_state, &to_state, &condition);
                Ok(())
            },
        );
        // -- setParam --
        /// Sets a boolean, integer, or numeric state machine parameter.
        /// @param | name | string | Parameter name used by transition conditions.
        /// @param | value | LuaValue | Boolean, integer, or number value to store.
        /// @return | nil | No value is returned.
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
        /// Returns the current frame rectangle from the state machine's owned animation.
        /// @return | LuaValue | Table with `x`, `y`, `w`, and `h`, or nil when no frame is active.
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
        /// Returns the Lua-visible type name for this animation state machine handle.
        /// @return | string | The string `LAnimStateMachine`.
        methods.add_method("type", |_, _, ()| Ok("LAnimStateMachine"));
        // -- typeOf --
        /// Returns whether this animation state machine handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAnimStateMachine` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimStateMachine" || name == "Object")
        });
    }
}
/// Lua-side blend layer set used to combine animation clips with weights and bone masks.
pub struct LuaBlendLayerSet {
    /// Owned blend layer set exposed through this userdata handle.
    inner: BlendLayerSet,
}
impl LuaUserData for LuaBlendLayerSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds a weighted animation blend layer with an optional bone mask.
        /// @param | name | string | Unique layer name.
        /// @param | clip_name | string | Animation clip name used by the layer.
        /// @param | weight | number | Blend weight for this layer.
        /// @param | bones | table? | Optional array or map table of bone names included in the mask.
        /// @return | boolean | True when the layer was added.
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
        /// Removes a blend layer by name. This method is available to Lua scripts.
        /// @param | name | string | Layer name to remove.
        /// @return | boolean | True when the layer was removed.
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.inner
                .remove_layer(&name)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });
        // -- setWeight --
        /// Sets the blend weight for an existing layer.
        /// @param | name | string | Layer name to update.
        /// @param | weight | number | New layer weight.
        /// @return | boolean | True when the layer exists and the weight was changed.
        methods.add_method_mut("setWeight", |_, this, (name, weight): (String, f32)| {
            this.inner
                .set_weight(&name, weight)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });
        // -- getWeight --
        /// Returns the weight for a blend layer when it exists.
        /// @param | name | string | Layer name to query.
        /// @return | LuaValue | Layer weight, or nil when the layer does not exist.
        methods.add_method("getWeight", |_, this, name: String| {
            Ok(this.inner.get_weight(&name))
        });
        // -- setMask --
        /// Replaces a layer bone mask from a table of bone names.
        /// @param | name | string | Layer name to update.
        /// @param | bones | table | Array or map table of bone names included in the mask.
        /// @return | boolean | True when the layer exists and the mask was changed.
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
        /// Returns all blend layers with names, clip names, weights, and bone masks.
        /// @return | table | Array of layer tables with `name`, `clip_name`, `weight`, and `bones` fields.
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
        /// @return | integer | Blend layer count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- type --
        /// Returns the Lua-visible type name for this blend layer set handle.
        /// @return | string | The string `LBlendLayerSet`.
        methods.add_method("type", |_, _, ()| Ok("LBlendLayerSet"));
        // -- typeOf --
        /// Returns whether this blend layer set handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LBlendLayerSet` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBlendLayerSet" || name == "Object")
        });
    }
}
/// Registers the `lurek.animation` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- new --
    /// Creates an empty animation with no frames or clips.
    /// @return | LAnimation | New animation handle.
    tbl.set(
        "new",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimation {
                inner: Animation::new(),
            })
        })?,
    )?;
    // -- fromAseprite --
    /// Loads an animation from an Aseprite JSON export string.
    /// @param | json_str | string | Raw Aseprite JSON document contents.
    /// @return | LuaValue | Animation handle when parsing succeeds; raises an error when the JSON cannot be parsed.
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
    // -- newStateMachine --
    /// Creates an animation state machine by consuming an animation handle.
    /// @param | anim_ud | LAnimation | Animation handle moved into the state machine.
    /// @param | initial | string | Initial state name stored in the state machine.
    /// @return | LAnimStateMachine | New animation state machine handle.
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
    /// Creates an empty animation curve. This function is exposed to Lua scripts.
    /// @return | LAnimCurve | New animation curve handle.
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
    /// Creates an empty animation synchronization group.
    /// @return | LAnimSyncGroup | New animation sync group handle.
    tbl.set(
        "newSyncGroup",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimSyncGroup {
                inner: crate::animation::sync_group::AnimSyncGroup::new(),
            })
        })?,
    )?;
    // -- newBlendLayerSet --
    /// Creates an empty blend layer set for layered animation playback.
    /// @return | LBlendLayerSet | New blend layer set handle.
    tbl.set(
        "newBlendLayerSet",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaBlendLayerSet {
                inner: BlendLayerSet::new(),
            })
        })?,
    )?;
    // -- buildCharacter --
    /// Builds a character animation bundle from grid frame and clip configuration.
    /// @param | cfg | table | Configuration table with texture size, frame size, clips, optional states, and optional transitions.
    /// @return | table | Table containing `animation` and, when states are supplied, `stateMachine` handles.
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
/// Parses a Lua clip mode string and returns the matching playback mode.
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
/// Converts a playback mode to the Lua-visible clip mode name.
fn clip_mode_name(mode: ClipPlaybackMode) -> &'static str {
    match mode {
        ClipPlaybackMode::Forward => "forward",
        ClipPlaybackMode::Reverse => "reverse",
        ClipPlaybackMode::PingPong => "pingpong",
    }
}
/// Lua-side animation curve with keyframes and optional custom easing callback.
pub struct LuaAnimCurve {
    /// Owned curve data exposed through this userdata handle.
    inner: crate::animation::curve::AnimCurve,
    /// Optional Lua registry key used for custom easing evaluation.
    custom_easing: Option<LuaRegistryKey>,
}
impl LuaUserData for LuaAnimCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addKeyframe --
        /// Adds a keyframe to the curve. This method is available to Lua scripts.
        /// @param | t | number | Keyframe time or normalized position.
        /// @param | v | number | Keyframe value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addKeyframe", |_, this, (t, v): (f32, f32)| {
            this.inner.add_keyframe(t, v);
            Ok(())
        });
        // -- eval --
        /// Evaluates the curve at a time or normalized position.
        /// @param | t | number | Time or normalized position to evaluate.
        /// @return | number | Interpolated curve value.
        methods.add_method("eval", |lua, this, t: f32| {
            if let Some(key) = &this.custom_easing {
                let func: mlua::Function = lua.registry_value(key)?;
                let v: f64 = func.call(t as f64)?;
                return Ok(v as f32);
            }
            Ok(this.inner.eval(t))
        });
        // -- setEasing --
        /// Sets the built-in easing mode used between keyframes.
        /// @param | mode | string | Easing mode `step`, `linear`, `ease_in`, `ease_out`, or `ease_in_out`.
        /// @return | nil | No value is returned.
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
        /// Returns the number of keyframes stored in this curve.
        /// @return | integer | Keyframe count.
        methods.add_method("keyframeCount", |_, this, ()| {
            Ok(this.inner.keyframe_count())
        });
        // -- setCustomEasing --
        /// Sets or clears a Lua callback used to evaluate custom easing.
        /// @param | func | LuaValue | Function used as custom easing callback, or nil to clear custom easing.
        /// @return | nil | No value is returned.
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
        /// Removes all keyframes from this curve.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this animation curve handle.
        /// @return | string | The string `LAnimCurve`.
        methods.add_method("type", |_, _, ()| Ok("LAnimCurve"));
        // -- typeOf --
        /// Returns whether this animation curve handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAnimCurve` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimCurve" || name == "Object")
        });
    }
}
/// Lua-side animation synchronization group for coordinating multiple animation handles.
pub struct LuaAnimSyncGroup {
    /// Owned sync group data exposed through this userdata handle.
    inner: crate::animation::sync_group::AnimSyncGroup,
}
impl LuaUserData for LuaAnimSyncGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds an animation-like handle to the sync group.
        /// @param | handle | LuaValue | Animation handle accepted by future sync group implementations.
        /// @return | nil | No value is returned.
        methods.add_method_mut("add", |_, _this, _handle: LuaValue| Ok(()));
        // -- remove --
        /// Removes an animation-like handle from the sync group.
        /// @param | handle | LuaValue | Animation handle accepted by future sync group implementations.
        /// @return | nil | No value is returned.
        methods.add_method_mut("remove", |_, _this, _handle: LuaValue| Ok(()));
        // -- clear --
        /// Removes all members from the sync group.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- memberCount --
        /// Returns the number of handles tracked by the sync group.
        /// @return | integer | Sync group member count.
        methods.add_method("memberCount", |_, this, ()| Ok(this.inner.member_count()));
        // -- type --
        /// Returns the Lua-visible type name for this animation sync group handle.
        /// @return | string | The string `LAnimSyncGroup`.
        methods.add_method("type", |_, _, ()| Ok("LAnimSyncGroup"));
        // -- typeOf --
        /// Returns whether this animation sync group handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAnimSyncGroup` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimSyncGroup" || name == "Object")
        });
    }
}
