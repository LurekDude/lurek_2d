//! `luna.animation` Lua API bindings.
//!
//! Auto-generated skeleton from `src/animation/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaAnimation ────────────────────────────────────────────────────────────

pub struct LuaAnimation(/* TODO: add key + state fields */);


impl LuaAnimation {
    /// Returns the source rectangle of the current frame, or `None` if no
    /// clip is active or the frame pool is empty.
    ///
    ///
    /// @return Rect?
    pub fn current_quad(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current position within the active clip's frame list (0-based).
    ///
    ///
    /// @return integer
    pub fn current_frame(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the name of the currently active clip, if any.
    ///
    ///
    /// @return Option<
    pub fn get_current_clip(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the animation is currently playing.
    ///
    ///
    /// @return boolean
    pub fn is_playing(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the current clip is set to loop.
    ///
    ///
    /// @return boolean
    pub fn is_looping(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the playback speed multiplier.
    ///
    ///
    /// @return number
    pub fn get_speed(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of frames in the animation's frame pool.
    ///
    ///
    /// @return integer
    pub fn get_frame_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of registered clips.
    ///
    ///
    /// @return integer
    pub fn get_clip_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaAnimation {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("currentQuad", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("currentFrame", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCurrentClip", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isPlaying", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isLooping", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSpeed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFrameCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getClipCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.animation.* functions ──────────────────────────────────────────

/// Adds a single frame and returns its 0-based index.
///
/// @param quad : Source
/// @return integer
pub fn add_frame(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Slices a sprite-sheet grid into frames and appends them.
///
/// @param tex_w : Full
/// @param tex_h : Full
/// @param frame_w : Single
/// @param frame_h : Single
/// @param start : 0-based
/// @param count : Number
/// @return integer
pub fn add_frames_from_grid(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers a named clip. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param name : Unique
/// @param frame_indices : Indices
/// @param fps : Playback
/// @param looping : Whether
pub fn add_clip(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convenience method: adds grid-sliced frames then creates a clip referencing them.
///
///
/// @param name : Clip
/// @param tex_w : Full
/// @param tex_h : Full
/// @param frame_w : Single
/// @param frame_h : Single
/// @param start : 0-based
/// @param count : Number
/// @param fps : Playback
/// @param looping : Whether
pub fn add_clip_from_grid(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Starts playing a clip by name.
///
/// @param name : str
/// @return boolean
pub fn play(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advances the animation by `dt` seconds (scaled by [`speed`](Self::get_speed)).
///
///
/// @param dt : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the playback speed multiplier.
///
///
/// @param speed : number
pub fn set_speed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns and clears all pending animation events.
///
///
/// @return table
pub fn drain_events(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Sets the playback position within the current clip.
///
///
/// @param index : integer
pub fn set_frame(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.animation` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("addFrame", lua.create_function(add_frame)?)?;
    tbl.set("addFramesFromGrid", lua.create_function(add_frames_from_grid)?)?;
    tbl.set("addClip", lua.create_function(add_clip)?)?;
    tbl.set("addClipFromGrid", lua.create_function(add_clip_from_grid)?)?;
    tbl.set("play", lua.create_function(play)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("setSpeed", lua.create_function(set_speed)?)?;
    tbl.set("drainEvents", lua.create_function(drain_events)?)?;
    tbl.set("setFrame", lua.create_function(set_frame)?)?;
    luna.set("animation", tbl)?;
    Ok(())
}
