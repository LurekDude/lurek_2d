//! Registers the `luna.animation` namespace.
//!
//! Provides Lua-level sprite animation: frame pools, named clips, speed
//! control, and playback events.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the
//! implementation details for animation API-related operations.
//! Key types exported: `LuaAnimation`.
//! Primary functions: `register()`.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::animation::{AnimEvent, Animation};
use crate::math::Rect;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ── UserData wrapper ──────────────────────────────────────────────────────────

/// Lua UserData wrapper for an [`Animation`] controller.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Animation>>`. Shared animation state.
#[derive(Clone)]
pub struct LuaAnimation {
    /// Shared animation controller.
    pub(crate) inner: Rc<RefCell<Animation>>,
}

impl LunaType for LuaAnimation {
    const TYPE_NAME: &'static str = "Animation";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Animation", "Object"];
}

impl LuaUserData for LuaAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Adds a single frame to the frame pool.
        /// @param x number
        /// @param y number
        /// @param w number
        /// @param h number
        /// @return number   Frame index (0-based).
        methods.add_method("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let idx = this.inner.borrow_mut().add_frame(Rect::new(x, y, w, h));
            Ok(idx)
        });

        /// Adds multiple frames sliced from a texture grid.
        /// @param tex_w  number  Texture width in pixels.
        /// @param tex_h  number  Texture height in pixels.
        /// @param frame_w number Frame width in pixels.
        /// @param frame_h number Frame height in pixels.
        /// @param start  number  First frame index in the grid (0-based).
        /// @param count  number  Number of frames to add.
        /// @return number   Number of frames added.
        methods.add_method(
            "addFramesFromGrid",
            |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                let added = this
                    .inner
                    .borrow_mut()
                    .add_frames_from_grid(tw, th, fw, fh, start, count);
                Ok(added)
            },
        );

        /// Adds a named clip from a list of explicit frame indices.
        /// @param name    string
        /// @param indices table   Array of frame indices (1-based Lua table).
        /// @param fps     number
        /// @param looping boolean
        methods.add_method(
            "addClip",
            |_, this, (name, indices_tbl, fps, looping): (String, LuaTable, f32, bool)| {
                let mut indices: Vec<usize> = Vec::new();
                for v in indices_tbl.sequence_values::<usize>() {
                    indices.push(v?);
                }
                this.inner
                    .borrow_mut()
                    .add_clip(&name, indices, fps, looping);
                Ok(())
            },
        );

        /// Adds a named clip sliced from a texture grid.
        /// @param name    string
        /// @param tex_w   number
        /// @param tex_h   number
        /// @param frame_w number
        /// @param frame_h number
        /// @param start   number  First grid index (0-based).
        /// @param count   number
        /// @param fps     number
        /// @param looping boolean
        methods.add_method(
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
                this.inner.borrow_mut().add_clip_from_grid(
                    &name, tw, th, fw, fh, start, count, fps, looping,
                );
                Ok(())
            },
        );

        /// Starts playback of the named clip. Returns `true` if the clip exists.
        /// @param name string
        /// @return boolean
        methods.add_method("play", |_, this, name: String| {
            let ok = this.inner.borrow_mut().play(&name);
            Ok(ok)
        });

        /// Stops playback and clears the current clip.
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });

        /// Advances the animation by `dt` seconds.
        /// @param dt number
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns the source quad `{x, y, w, h}` for the current frame, or `nil`.
        /// @return table|nil
        methods.add_method("getQuad", |lua, this, ()| {
            if let Some(q) = this.inner.borrow().current_quad() {
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

        /// Drains and returns all pending animation events as a table.
        ///
        /// Each event is a table with a `type` string (`"finished"`, `"looped"`,
        /// or `"frameChanged"`) and, for `"frameChanged"`, a `frame` integer.
        /// @return table
        methods.add_method("pollEvents", |lua, this, ()| {
            let events = this.inner.borrow_mut().drain_events();
            let tbl = lua.create_table()?;
            for (i, ev) in events.into_iter().enumerate() {
                let ev_tbl = lua.create_table()?;
                match ev {
                    AnimEvent::Finished => ev_tbl.set("type", "finished")?,
                    AnimEvent::Looped => ev_tbl.set("type", "looped")?,
                    AnimEvent::FrameChanged { frame_index } => {
                        ev_tbl.set("type", "frameChanged")?;
                        ev_tbl.set("frame", frame_index)?;
                    }
                }
                tbl.set(i + 1, ev_tbl)?;
            }
            Ok(tbl)
        });

        /// Returns `true` if a clip is currently playing.
        /// @return boolean
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });

        /// Returns the name of the currently playing clip, or `nil`.
        /// @return string|nil
        methods.add_method("getClip", |_, this, ()| {
            Ok(this
                .inner
                .borrow()
                .get_current_clip()
                .map(|s| s.to_owned()))
        });

        /// Returns the playback speed multiplier.
        /// @return number
        methods.add_method("getSpeed", |_, this, ()| {
            Ok(this.inner.borrow().get_speed())
        });

        /// Sets the playback speed multiplier.
        /// @param speed number
        methods.add_method("setSpeed", |_, this, speed: f32| {
            this.inner.borrow_mut().set_speed(speed);
            Ok(())
        });

        /// Returns the total number of frames in the frame pool.
        /// @return number
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.borrow().get_frame_count())
        });

        /// Returns the total number of named clips.
        /// @return number
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.borrow().get_clip_count())
        });
    }
}

// ── Registration ──────────────────────────────────────────────────────────────

/// Registers the `luna.animation` namespace into the given `luna` table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let animation_tbl = lua.create_table()?;

    /// Creates a new, empty [`Animation`] controller.
    /// @return Animation
    animation_tbl.set(
        "new",
        lua.create_function(|_, ()| {
            Ok(LuaAnimation {
                inner: Rc::new(RefCell::new(Animation::new())),
            })
        })?,
    )?;

    luna.set("animation", animation_tbl)?;
    Ok(())
}
