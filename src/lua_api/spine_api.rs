//! `lurek.spine` - Skeletal animation with bones, slots, timelines, constraints, and skins.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::spine::ik::IKConstraint;
use crate::spine::timeline::{BoneProperty, BoneTimeline, EasingType, Keyframe, SkeletonAnimation};
use crate::spine::{BoneParams, Skeleton};

// Extracts bone transform overrides from an optional Lua options table.
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
        /// @param | name | string | Bone name.
        /// @param | opts | table? | Optional local transform settings.
        /// @return | integer | Bone index.
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
        /// @param | name | string | Bone name.
        /// @param | parent_idx | integer | Parent bone index.
        /// @param | opts | table? | Optional local transform settings.
        /// @return | integer | Bone index.
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
        /// @param | name | string | Slot name.
        /// @param | bone_idx | integer | Bone index to attach to.
        /// @param | attachment | string? | Optional attachment name.
        /// @return | integer | Slot index.
        methods.add_method_mut(
            "addSlot",
            |_, this, (name, bone_idx, attachment): (String, usize, Option<String>)| {
                Ok(this.inner.add_slot_full(&name, bone_idx, attachment))
            },
        );

        // -- findBone --
        /// Returns the index of the named bone.
        /// @param | name | string | Bone name.
        /// @return | integer | Bone index.
        methods.add_method("findBone", |_, this, name: String| {
            Ok(this.inner.find_bone(&name))
        });

        // -- findSlot --
        /// Returns the index of the named slot.
        /// @param | name | string | Slot name.
        /// @return | integer | Slot index.
        methods.add_method("findSlot", |_, this, name: String| {
            Ok(this.inner.find_slot(&name))
        });

        // -- updateWorldTransforms --
        /// Propagates local transforms down the bone hierarchy to compute world positions.
        /// @return | nil | No value is returned.
        methods.add_method_mut("updateWorldTransforms", |_, this, ()| {
            this.inner.update_world_transforms();
            Ok(())
        });

        // -- getBoneWorld --
        /// Returns the world-space transform of a bone as a table.
        /// @param | idx | integer | Bone index.
        /// @return | table | Bone world transform table.
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
        /// @param | x | number | Root X position.
        /// @param | y | number | Root Y position.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.set_root_position(x, y);
            Ok(())
        });

        // -- boneCount --
        /// Returns the total number of bones.
        /// @return | integer | Bone count.
        methods.add_method("boneCount", |_, this, ()| Ok(this.inner.bone_count()));

        // -- slotCount --
        /// Returns the total number of slots.
        /// @return | integer | Slot count.
        methods.add_method("slotCount", |_, this, ()| Ok(this.inner.slot_count()));

        // -- drawToImage --
        /// Renders the skeleton as a stick-figure debug view into a new ImageData.
        /// @param | width | integer | Output image width.
        /// @param | height | integer | Output image height.
        /// @return | ImageData | Generated debug image.
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });

        // -- playAnimation --
        /// Starts playback of the named skeletal animation clip.
        /// @param | name | string | Animation clip name.
        /// @param | looping | boolean? | Whether playback should loop.
        /// @return | boolean | True when playback started.
        methods.add_method_mut(
            "playAnimation",
            |_, this, (name, looping): (String, Option<bool>)| {
                Ok(this.inner.play_animation(&name, looping.unwrap_or(true)))
            },
        );

        // -- stopAnimation --
        /// Stops the current skeletal animation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("stopAnimation", |_, this, ()| {
            this.inner.stop_animation();
            Ok(())
        });

        // -- updateAnimation --
        /// Advances the playing animation by `dt` seconds and applies keyframes.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("updateAnimation", |_, this, dt: f32| {
            this.inner.update_animation(dt);
            Ok(())
        });

        // -- getAnimationTime --
        /// Returns the current playback time in seconds of the active animation.
        /// @return | number | Playback time in seconds.
        methods.add_method("getAnimationTime", |_, this, ()| {
            Ok(this.inner.get_animation_time())
        });

        // -- addAnimation --
        /// Adds a SkeletonAnimation to this skeleton's library.
        /// @param | anim | LSkeletonAnimation | Animation object to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addAnimation", |_, this, anim_ud: LuaAnyUserData| {
            let anim = anim_ud.take::<LuaSkeletonAnimation>()?.inner;
            this.inner.add_animation(anim);
            Ok(())
        });

        // -- addIKConstraint --
        /// Adds a two-bone IK constraint and returns its index.
        /// @param | name | string | Constraint name.
        /// @param | bone_chain | table | Array of bone indices.
        /// @param | bend_positive | boolean? | Preferred bend direction.
        /// @return | integer | Constraint index.
        methods.add_method_mut(
            "addIKConstraint",
            |_, this, (name, chain_tbl, bend_positive): (String, LuaTable, Option<bool>)| {
                let mut chain: Vec<usize> = Vec::new();
                for v in chain_tbl.sequence_values::<usize>() {
                    chain.push(v?);
                }
                let constraint = IKConstraint::new(&name, chain, bend_positive.unwrap_or(true));
                Ok(this.inner.add_ik_constraint(constraint))
            },
        );

        // -- setIKTarget --
        /// Sets the world-space target position for the named IK constraint.
        /// @param | name | string | Constraint name.
        /// @param | x | number | Target X coordinate.
        /// @param | y | number | Target Y coordinate.
        /// @return | boolean | True when the constraint was found.
        methods.add_method_mut(
            "setIKTarget",
            |_, this, (name, x, y): (String, f32, f32)| Ok(this.inner.set_ik_target(&name, x, y)),
        );

        // -- addSkin --
        /// Registers a new empty skin by name.
        /// @param | name | string | Skin name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addSkin", |_, this, name: String| {
            this.inner.add_skin(&name);
            Ok(())
        });

        // -- setSkin --
        /// Activates the named skin for attachment lookups.
        /// @param | name | string | Skin name.
        /// @return | boolean | True when the skin was found.
        methods.add_method_mut("setSkin", |_, this, name: String| {
            Ok(this.inner.set_skin(&name))
        });

        // -- getSkin --
        /// Returns the name of the currently active skin.
        /// @return | string | Active skin name.
        methods.add_method("getSkin", |_, this, ()| {
            Ok(this.inner.get_skin().map(|s| s.to_owned()))
        });

        // -- setSkinMapping --
        /// Registers a slot-to-attachment mapping in the named skin.
        /// @param | skin | string | Skin name.
        /// @param | slot | string | Slot name.
        /// @param | attachment | string | Attachment name.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setSkinMapping",
            |_, this, (skin, slot, attachment): (String, String, String)| {
                this.inner.set_skin_mapping(&skin, &slot, &attachment);
                Ok(())
            },
        );

        // -- blendAnimation --
        /// Evaluates an animation at `time` and blends it into this skeleton.
        /// @param | anim | LSkeletonAnimation | Animation object to sample.
        /// @param | time | number | Sample time in seconds.
        /// @param | blend_weight | number? | Optional blend weight from `0.0` to `1.0`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "blendAnimation",
            |_, this, (anim_ud, time, blend_weight): (mlua::AnyUserData, f32, Option<f32>)| {
                let anim_ref = anim_ud
                    .borrow::<LuaSkeletonAnimation>()
                    .map_err(mlua::Error::external)?;
                let w = blend_weight.unwrap_or(1.0);
                anim_ref
                    .inner
                    .apply_to_skeleton_blended(&mut this.inner, time, w);
                Ok(())
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LSkeleton"));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeleton" || name == "Object")
        });
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
        /// Adds a keyframe to a bone timeline for the given property.
        /// @param | bone_idx | integer | Bone index.
        /// @param | property | string | Property name such as `x`, `y`, or `rotation`.
        /// @param | time | number | Keyframe time in seconds.
        /// @param | value | number | Keyframe value.
        /// @param | easing | string? | Optional easing mode.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addKeyframe",
            |_,
             this,
             (bone_idx, prop_str, time, value, easing_str): (
                usize,
                String,
                f32,
                f32,
                Option<String>,
            )| {
                let property = match prop_str.as_str() {
                    "x" => BoneProperty::X,
                    "y" => BoneProperty::Y,
                    "rotation" => BoneProperty::Rotation,
                    "scale_x" => BoneProperty::ScaleX,
                    "scale_y" => BoneProperty::ScaleY,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "addKeyframe: unknown property '{}'",
                            other
                        )))
                    }
                };
                let easing = match easing_str.as_deref().unwrap_or("linear") {
                    "linear" => EasingType::Linear,
                    "ease_in" => EasingType::EaseIn,
                    "ease_out" => EasingType::EaseOut,
                    "ease_in_out" => EasingType::EaseInOut,
                    "step" => EasingType::Step,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "addKeyframe: unknown easing '{}'",
                            other
                        )))
                    }
                };
                let keyframe = Keyframe {
                    time,
                    value,
                    easing,
                };
                // Find or create the timeline for this (bone_idx, property) pair.
                let existing = this
                    .inner
                    .timelines
                    .iter_mut()
                    .find(|tl| tl.bone_idx == bone_idx && tl.property == property);
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
        /// @return | number | Animation duration in seconds.
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration));

        // -- addEventKey --
        /// Adds a named event marker at a time in the animation.
        /// @param | time | number | Event time in seconds.
        /// @param | name | string | Event name.
        /// @param | value | number? | Optional numeric payload.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addEventKey",
            |_, this, (time, name, value): (f32, String, Option<f32>)| {
                this.inner.add_event_key(time, name, value.unwrap_or(0.0));
                Ok(())
            },
        );

        // -- getEvents --
        /// Returns event entries in the half-open interval `(from, to]`.
        /// @param | from | number | Interval start time.
        /// @param | to | number | Interval end time.
        /// @return | table | Array of `{ name, value }` event tables.
        methods.add_method("getEvents", |lua, this, (from, to): (f32, f32)| {
            let pairs = this.inner.collect_events(from, to);
            let tbl = lua.create_table()?;
            for (i, (name, value)) in pairs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("name", name)?;
                entry.set("value", value)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });

        // -- getTimelineCount --
        /// Returns the number of bone timelines in this animation.
        /// @return | integer | Timeline count.
        methods.add_method("getTimelineCount", |_, this, ()| {
            Ok(this.inner.timelines.len())
        });

        // -- poseAt --
        /// Evaluates all timelines at the given time and returns a snapshot table.
        /// @param | time | number | Playback time in seconds.
        /// @return | table | Array of `{ bone_idx, property, value }` entries.
        methods.add_method("poseAt", |lua, this, time: f32| {
            let snapshot = this.inner.pose_at(time);
            let arr = lua.create_table()?;
            for (i, (bone_idx, prop, value)) in snapshot.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("bone_idx", *bone_idx)?;
                let prop_name = match prop {
                    BoneProperty::X => "x",
                    BoneProperty::Y => "y",
                    BoneProperty::Rotation => "rotation",
                    BoneProperty::ScaleX => "scale_x",
                    BoneProperty::ScaleY => "scale_y",
                };
                entry.set("property", prop_name)?;
                entry.set("value", *value)?;
                arr.set(i + 1, entry)?;
            }
            Ok(arr)
        });

        // -- reverse --
        /// Creates a reversed copy of this animation clip.
        /// @return | LSkeletonAnimation | New reversed animation clip.
        methods.add_method("reverse", |lua, this, ()| {
            lua.create_userdata(LuaSkeletonAnimation {
                inner: this.inner.reverse(),
            })
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LSkeletonAnimation"));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeletonAnimation" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.spine` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSkeleton --
    /// Creates a new empty skeleton with the given name.
    /// @param | name | string | Skeleton name.
    /// @return | LSkeleton | New skeleton object.
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
    /// @param | name | string | Animation name.
    /// @param | duration | number | Clip duration in seconds.
    /// @return | LSkeletonAnimation | New animation object.
    tbl.set(
        "newSkeletonAnimation",
        lua.create_function(|lua, (name, duration): (String, f32)| {
            lua.create_userdata(LuaSkeletonAnimation {
                inner: SkeletonAnimation {
                    name,
                    duration,
                    timelines: Vec::new(),
                    events: Vec::new(),
                },
            })
        })?,
    )?;

    // -- animationFromJson --
    /// Builds a SkeletonAnimation from a JSON string.
    /// @param | json | string | JSON payload describing the animation clip.
    /// @return | LSkeletonAnimation? | Parsed animation or nil on schema mismatch.
    tbl.set(
        "animationFromJson",
        lua.create_function(|lua, json: String| {
            let parsed: serde_json::Value = serde_json::from_str(&json)
                .map_err(|e| LuaError::RuntimeError(format!("animationFromJson: {e}")))?;
            match SkeletonAnimation::from_json(&parsed) {
                Some(anim) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaSkeletonAnimation { inner: anim })?,
                )),
                None => Ok(LuaValue::Nil),
            }
        })?,
    )?;

    luna.set("spine", tbl)?;
    Ok(())
}
