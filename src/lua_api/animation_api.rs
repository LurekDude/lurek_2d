//! `lurek.animation` — Sprite animation: frame pools, named clips, speed control, and playback events.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

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
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.animation` API table with the Lua VM.
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

    luna.set("animation", tbl)?;
    Ok(())
}
