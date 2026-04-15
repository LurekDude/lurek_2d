//! `lurek.spine` — Skeletal animation: bone hierarchies, slots, world-transform propagation,
//! keyframe timelines, IK constraints, and skins.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::spine::ik::IKConstraint;
use crate::spine::timeline::{BoneProperty, BoneTimeline, EasingType, Keyframe, SkeletonAnimation};
use crate::spine::{BoneParams, Skeleton};

/// Extracts bone transform overrides from an optional Lua options table.
fn parse_bone_opts(opts: &Option<LuaTable>) -> LuaResult<(f32, f32, f32, f32, f32)> {
    let (mut x, mut y, mut rot, mut sx, mut sy) = (0.0, 0.0, 0.0, 1.0, 1.0);
    if let Some(tbl) = opts {
        if let Ok(v) = tbl.get::<_, f32>("x") {
            x = v;
        }
        if let Ok(v) = tbl.get::<_, f32>("y") {
            y = v;
        }
        if let Ok(v) = tbl.get::<_, f32>("rotation") {
            rot = v;
        }
        if let Ok(v) = tbl.get::<_, f32>("scale_x") {
            sx = v;
        }
        if let Ok(v) = tbl.get::<_, f32>("scale_y") {
            sy = v;
        }
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
        methods.add_method_mut(
            "addBone",
            |_, this, (name, opts): (String, Option<LuaTable>)| {
                let (x, y, rot, sx, sy) = parse_bone_opts(&opts)?;
                Ok(this.inner.add_bone_full(BoneParams {
                    name,
                    parent_index: None,
                    x,
                    y,
                    rotation: rot,
                    scale_x: sx,
                    scale_y: sy,
                }))
            },
        );

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
                    name,
                    parent_index: Some(parent_idx),
                    x,
                    y,
                    rotation: rot,
                    scale_x: sx,
                    scale_y: sy,
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
        methods.add_method("boneCount", |_, this, ()| Ok(this.inner.bone_count()));

        // -- slotCount --
        /// Returns the total number of slots.
        /// @return integer
        methods.add_method("slotCount", |_, this, ()| Ok(this.inner.slot_count()));

        // -- drawToImage --
        /// Renders the skeleton as a stick-figure debug view into a new ImageData.
        /// @param width : integer
        /// @param height : integer
        /// @return ImageData
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(LuaImageData { inner: img })
        });

        // -- playAnimation --
        /// Starts playback of the named skeletal animation clip.
        /// @param name : string
        /// @param looping : boolean?
        /// @return boolean
        methods.add_method_mut(
            "playAnimation",
            |_, this, (name, looping): (String, Option<bool>)| {
                Ok(this.inner.play_animation(&name, looping.unwrap_or(true)))
            },
        );

        // -- stopAnimation --
        /// Stops the current skeletal animation.
        /// @return nil
        methods.add_method_mut("stopAnimation", |_, this, ()| {
            this.inner.stop_animation();
            Ok(())
        });

        // -- updateAnimation --
        /// Advances the playing animation by `dt` seconds and applies keyframes.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("updateAnimation", |_, this, dt: f32| {
            this.inner.update_animation(dt);
            Ok(())
        });

        // -- getAnimationTime --
        /// Returns the current playback time in seconds of the active animation.
        /// @return number
        methods.add_method("getAnimationTime", |_, this, ()| {
            Ok(this.inner.get_animation_time())
        });

        // -- addAnimation --
        /// Adds a SkeletonAnimation to this skeleton's library.
        /// @param anim : SkeletonAnimation
        /// @return nil
        methods.add_method_mut("addAnimation", |_, this, anim_ud: LuaAnyUserData| {
            let anim = anim_ud.take::<LuaSkeletonAnimation>()?.inner;
            this.inner.add_animation(anim);
            Ok(())
        });

        // -- addIKConstraint --
        /// Adds a two-bone IK constraint and returns its index.
        /// @param name : string
        /// @param bone_chain : table
        /// @param bend_positive : boolean?
        /// @return integer
        methods.add_method_mut(
            "addIKConstraint",
            |_, this, (name, chain_tbl, bend_positive): (String, LuaTable, Option<bool>)| {
                let mut chain: Vec<usize> = Vec::new();
                for v in chain_tbl.sequence_values::<usize>() {
                    chain.push(v?);
                }
                let constraint =
                    IKConstraint::new(&name, chain, bend_positive.unwrap_or(true));
                Ok(this.inner.add_ik_constraint(constraint))
            },
        );

        // -- setIKTarget --
        /// Sets the world-space target position for the named IK constraint.
        /// @param name : string
        /// @param x : number
        /// @param y : number
        /// @return boolean
        methods.add_method_mut(
            "setIKTarget",
            |_, this, (name, x, y): (String, f32, f32)| {
                Ok(this.inner.set_ik_target(&name, x, y))
            },
        );

        // -- addSkin --
        /// Registers a new empty skin by name.
        /// @param name : string
        /// @return nil
        methods.add_method_mut("addSkin", |_, this, name: String| {
            this.inner.add_skin(&name);
            Ok(())
        });

        // -- setSkin --
        /// Activates the named skin for attachment lookups.
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("setSkin", |_, this, name: String| {
            Ok(this.inner.set_skin(&name))
        });

        // -- getSkin --
        /// Returns the name of the currently active skin, or nil.
        /// @return string?
        methods.add_method("getSkin", |_, this, ()| {
            Ok(this.inner.get_skin().map(|s| s.to_owned()))
        });

        // -- setSkinMapping --
        /// Registers a slot-to-attachment mapping in the named skin.
        /// @param skin : string
        /// @param slot : string
        /// @param attachment : string
        /// @return nil
        methods.add_method_mut(
            "setSkinMapping",
            |_, this, (skin, slot, attachment): (String, String, String)| {
                this.inner.set_skin_mapping(&skin, &slot, &attachment);
                Ok(())
            },
        );

        // -- blendAnimation --
        /// Evaluates `anim` at `time` and blends the result into this skeleton
        /// with the given `blend_weight` (`0.0` = no effect, `1.0` = full override).
        ///
        /// Useful for cross-fading between two animations:
        /// ```lua
        /// skeleton:updateAnimation(dt)           -- advance primary clip
        /// skeleton:blendAnimation(overlay, t, 0.4) -- blend in secondary
        /// ```
        /// @param anim : SkeletonAnimation
        /// @param time : number
        /// @param blend_weight : number?
        methods.add_method_mut(
            "blendAnimation",
            |_, this, (anim_ud, time, blend_weight): (mlua::AnyUserData, f32, Option<f32>)| {
                let anim_ref = anim_ud.borrow::<LuaSkeletonAnimation>().map_err(mlua::Error::external)?;
                let w = blend_weight.unwrap_or(1.0);
                anim_ref.inner.apply_to_skeleton_blended(&mut this.inner, time, w);
                Ok(())
            },
        );
    }
}

// -------------------------------------------------------------------------------
// LuaSkeletonAnimation UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SkeletonAnimation`] keyframe clip.
pub struct LuaSkeletonAnimation {
    inner: SkeletonAnimation,
}

impl LuaUserData for LuaSkeletonAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addKeyframe --
        /// Adds a keyframe to the bone timeline for the given property and bone index.
        /// The `property` string maps to `BoneProperty` names: "x", "y", "rotation", "scale_x", "scale_y".
        /// The optional `easing` string: "linear", "ease_in", "ease_out", "ease_in_out", "step".
        /// @param bone_idx : integer
        /// @param property : string
        /// @param time : number
        /// @param value : number
        /// @param easing : string?
        /// @return nil
        methods.add_method_mut(
            "addKeyframe",
            |_, this, (bone_idx, prop_str, time, value, easing_str): (usize, String, f32, f32, Option<String>)| {
                let property = match prop_str.as_str() {
                    "x" => BoneProperty::X,
                    "y" => BoneProperty::Y,
                    "rotation" => BoneProperty::Rotation,
                    "scale_x" => BoneProperty::ScaleX,
                    "scale_y" => BoneProperty::ScaleY,
                    other => return Err(LuaError::RuntimeError(format!(
                        "addKeyframe: unknown property '{}'", other
                    ))),
                };
                let easing = match easing_str.as_deref().unwrap_or("linear") {
                    "linear" => EasingType::Linear,
                    "ease_in" => EasingType::EaseIn,
                    "ease_out" => EasingType::EaseOut,
                    "ease_in_out" => EasingType::EaseInOut,
                    "step" => EasingType::Step,
                    other => return Err(LuaError::RuntimeError(format!(
                        "addKeyframe: unknown easing '{}'", other
                    ))),
                };
                let keyframe = Keyframe { time, value, easing };
                // Find or create the timeline for this (bone_idx, property) pair.
                let existing = this.inner.timelines.iter_mut().find(|tl| {
                    tl.bone_idx == bone_idx && tl.property == property
                });
                if let Some(tl) = existing {
                    tl.keys.push(keyframe);
                } else {
                    this.inner.timelines.push(BoneTimeline {
                        bone_idx,
                        property,
                        keys: vec![keyframe],
                    });
                }
                Ok(())
            },
        );

        // -- getDuration --
        /// Returns the total duration of the animation in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration));

        // -- addEventKey --
        /// Adds a named event marker at `time` seconds in the animation.
        ///
        /// Registered Lua callbacks receive these events when the playhead crosses
        /// each marker.  Events are sorted by time automatically.
        /// @param time : number
        /// @param name : string
        /// @param value : number?
        methods.add_method_mut(
            "addEventKey",
            |_, this, (time, name, value): (f32, String, Option<f32>)| {
                this.inner.add_event_key(time, name, value.unwrap_or(0.0));
                Ok(())
            },
        );

        // -- getEvents --
        /// Returns a list of event names that fall in the half-open interval `(from, to]`.
        ///
        /// Useful for polling events after each `updateAnimation` call.
        /// @param from : number
        /// @param to : number
        /// @return table  — Array of `{name: string, value: number}` tables.
        methods.add_method(
            "getEvents",
            |lua, this, (from, to): (f32, f32)| {
                let pairs = this.inner.collect_events(from, to);
                let tbl = lua.create_table()?;
                for (i, (name, value)) in pairs.into_iter().enumerate() {
                    let entry = lua.create_table()?;
                    entry.set("name", name)?;
                    entry.set("value", value)?;
                    tbl.set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );

        // -- getTimelineCount --
        /// Returns the number of bone timelines in this animation.
        /// @return integer
        methods.add_method("getTimelineCount", |_, this, ()| {
            Ok(this.inner.timelines.len())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.spine` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
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

    // -- newSkeletonAnimation --
    /// Creates a new empty SkeletonAnimation clip with the given name and duration.
    /// @param name : string
    /// @param duration : number
    /// @return SkeletonAnimation
    tbl.set(
        "newSkeletonAnimation",
        lua.create_function(|lua, (name, duration): (String, f32)| {
            lua.create_userdata(LuaSkeletonAnimation {
                inner: SkeletonAnimation {
                    name,
                    duration,
                    timelines: Vec::new(),
                },
            })
        })?,
    )?;

    luna.set("spine", tbl)?;
    Ok(())
}
