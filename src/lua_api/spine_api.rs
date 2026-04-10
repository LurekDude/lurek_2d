//! `lurek.spine` — Skeletal animation: bone hierarchies, slots, and world-transform propagation.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::spine::{BoneParams, Skeleton};

/// Extracts bone transform overrides from an optional Lua options table.
fn parse_bone_opts(opts: &Option<LuaTable>) -> LuaResult<(f32, f32, f32, f32, f32)> {
    let (mut x, mut y, mut rot, mut sx, mut sy) = (0.0, 0.0, 0.0, 1.0, 1.0);
    if let Some(tbl) = opts {
        if let Ok(v) = tbl.get::<_, f32>("x") { x = v; }
        if let Ok(v) = tbl.get::<_, f32>("y") { y = v; }
        if let Ok(v) = tbl.get::<_, f32>("rotation") { rot = v; }
        if let Ok(v) = tbl.get::<_, f32>("scale_x") { sx = v; }
        if let Ok(v) = tbl.get::<_, f32>("scale_y") { sy = v; }
    }
    Ok((x, y, rot, sx, sy))
}

// -------------------------------------------------------------------------------
// LuaSkeleton UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Skeleton`].
pub struct LuaSkeleton {
    inner: Skeleton,
}

impl LuaUserData for LuaSkeleton {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- addBone --
        /// Adds a root bone with optional local transform and returns its index.
        /// @param name : string
        /// @param opts : table?
        /// @return integer
        methods.add_method_mut("addBone", |_, this, (name, opts): (String, Option<LuaTable>)| {
            let (x, y, rot, sx, sy) = parse_bone_opts(&opts)?;
            Ok(this.inner.add_bone_full(BoneParams {
                name, parent_index: None, x, y, rotation: rot, scale_x: sx, scale_y: sy,
            }))
        });

        // -- addChildBone --
        /// Adds a child bone attached to a parent and returns its index.
        /// @param name : string
        /// @param parent_idx : integer
        /// @param opts : table?
        /// @return integer
        methods.add_method_mut(
            "addChildBone",
            |_, this, (name, parent_idx, opts): (String, usize, Option<LuaTable>)| {
                let (x, y, rot, sx, sy) = parse_bone_opts(&opts)?;
                Ok(this.inner.add_bone_full(BoneParams {
                    name, parent_index: Some(parent_idx), x, y, rotation: rot, scale_x: sx, scale_y: sy,
                }))
            },
        );

        // -- addSlot --
        /// Adds a slot bound to a bone and returns its index.
        /// @param name : string
        /// @param bone_idx : integer
        /// @param attachment : string?
        /// @return integer
        methods.add_method_mut(
            "addSlot",
            |_, this, (name, bone_idx, attachment): (String, usize, Option<String>)| {
                Ok(this.inner.add_slot_full(&name, bone_idx, attachment))
            },
        );

        // -- findBone --
        /// Returns the index of the named bone, or nil if not found.
        /// @param name : string
        /// @return integer?
        methods.add_method("findBone", |_, this, name: String| {
            Ok(this.inner.find_bone(&name))
        });

        // -- findSlot --
        /// Returns the index of the named slot, or nil if not found.
        /// @param name : string
        /// @return integer?
        methods.add_method("findSlot", |_, this, name: String| {
            Ok(this.inner.find_slot(&name))
        });

        // -- updateWorldTransforms --
        /// Propagates local transforms down the bone hierarchy to compute world positions.
        /// @return nil
        methods.add_method_mut("updateWorldTransforms", |_, this, ()| {
            this.inner.update_world_transforms();
            Ok(())
        });

        // -- getBoneWorld --
        /// Returns the world-space transform of a bone as a table, or nil if out of range.
        /// @param idx : integer
        /// @return table?
        methods.add_method("getBoneWorld", |lua, this, idx: usize| {
            match this.inner.bone_world_transform(idx) {
                None => Ok(LuaValue::Nil),
                Some((x, y, rotation, sx, sy)) => {
                    let t = lua.create_table()?;
                    t.set("x", x)?;
                    t.set("y", y)?;
                    t.set("rotation", rotation)?;
                    t.set("scale_x", sx)?;
                    t.set("scale_y", sy)?;
                    Ok(LuaValue::Table(t))
                }
            }
        });

        // -- setPosition --
        /// Sets the root bone position and propagates world transforms.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method_mut("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.set_root_position(x, y);
            Ok(())
        });

        // -- boneCount --
        /// Returns the total number of bones.
        /// @return integer
        methods.add_method("boneCount", |_, this, ()| {
            Ok(this.inner.bone_count())
        });

        // -- slotCount --
        /// Returns the total number of slots.
        /// @return integer
        methods.add_method("slotCount", |_, this, ()| {
            Ok(this.inner.slot_count())
        });

        // -- drawToImage --
        /// Renders the skeleton as a stick-figure debug view into a new ImageData.
        /// @param width : integer
        /// @param height : integer
        /// @return ImageData
        methods.add_method("drawToImage", |_, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            Ok(LuaImageData { inner: img })
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.spine` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSkeleton --
    /// Creates a new empty skeleton with the given name.
    /// @param name : string
    /// @return Skeleton
    tbl.set(
        "newSkeleton",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaSkeleton {
                inner: Skeleton::new(&name),
            })
        })?,
    )?;

    luna.set("spine", tbl)?;
    Ok(())
}
