//! `lurek.spine` — Spine-like skeletal animation with bones, slots, attachments, IK constraints, and skin mixing.

use super::SharedState;
use crate::spine::ik::IKConstraint;
use crate::spine::timeline::{BoneProperty, BoneTimeline, EasingType, Keyframe, SkeletonAnimation};
use crate::spine::{BoneParams, Skeleton};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Parses optional bone transform overrides from a Lua table.
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
/// Lua-facing skeleton object providing bone hierarchy, slots, IK, skins, and animation playback.
pub struct LuaSkeleton {
    inner: Skeleton,
}
impl LuaUserData for LuaSkeleton {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addBone --
        /// Adds a root-level bone to the skeleton with optional transform properties.
        /// @param | name | string | Unique name for this bone.
        /// @param | opts | table? | Optional table with keys: x, y, rotation, scale_x, scale_y.
        /// @return | integer | Zero-based index of the newly added bone.
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
        /// Adds a bone as a child of an existing bone, inheriting its parent's world transform.
        /// @param | name | string | Unique name for this bone.
        /// @param | parent_idx | integer | Zero-based index of the parent bone.
        /// @param | opts | table? | Optional table with keys: x, y, rotation, scale_x, scale_y (local offsets from parent).
        /// @return | integer | Zero-based index of the newly added child bone.
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
        /// Adds a slot attached to a specific bone, optionally assigning a default attachment name.
        /// @param | name | string | Unique name for this slot.
        /// @param | bone_idx | integer | Zero-based index of the bone this slot is attached to.
        /// @param | attachment | string? | Optional default attachment name for this slot.
        /// @return | integer | Zero-based index of the newly added slot.
        methods.add_method_mut(
            "addSlot",
            |_, this, (name, bone_idx, attachment): (String, usize, Option<String>)| {
                Ok(this.inner.add_slot_full(&name, bone_idx, attachment))
            },
        );
        // -- findBone --
        /// Searches for a bone by name and returns its zero-based index, or nil if not found.
        /// @param | name | string | Name of the bone to find.
        /// @return | integer | Zero-based bone index, or nil if no bone with that name exists.
        methods.add_method("findBone", |_, this, name: String| {
            Ok(this.inner.find_bone(&name))
        });
        // -- findSlot --
        /// Searches for a slot by name and returns its zero-based index, or nil if not found.
        /// @param | name | string | Name of the slot to find.
        /// @return | integer | Zero-based slot index, or nil if no slot with that name exists.
        methods.add_method("findSlot", |_, this, name: String| {
            Ok(this.inner.find_slot(&name))
        });
        // -- updateWorldTransforms --
        /// Recomputes world transforms for all bones in hierarchy order. Call after modifying bone locals or IK targets.
        methods.add_method_mut("updateWorldTransforms", |_, this, ()| {
            this.inner.update_world_transforms();
            Ok(())
        });
        // -- getBoneWorld --
        /// Returns the final world-space transform of a bone after hierarchy resolution.
        /// @param | idx | integer | Zero-based bone index.
        /// @return | table | Table with keys x, y, rotation, scale_x, scale_y — or nil if the index is invalid.
        /// @field | x | number | X position.
        /// @field | y | number | Y position.
        /// @field | rotation | number | Rotation in degrees.
        /// @field | scale_x | number | Horizontal scale.
        /// @field | scale_y | number | Vertical scale.
        methods.add_method("getBoneWorld", |lua, this, idx: usize| {
            match this.inner.bone_world_transform(idx) {
                None => Ok(LuaValue::Nil),
                Some((x, y, rotation, sx, sy)) => {
                    let t = lua.create_table()?;
                    /// Performs the 'x' operation.
                    t.set("x", x)?;
                    /// Performs the 'y' operation.
                    t.set("y", y)?;
                    /// Performs the 'rotation' operation.
                    t.set("rotation", rotation)?;
                    /// Performs the 'scale_x' operation.
                    t.set("scale_x", sx)?;
                    /// Performs the 'scale_y' operation.
                    t.set("scale_y", sy)?;
                    Ok(LuaValue::Table(t))
                }
            }
        });
        // -- setPosition --
        /// Sets the root bone world position, shifting the entire skeleton.
        /// @param | x | number | World X coordinate.
        /// @param | y | number | World Y coordinate.
        methods.add_method_mut("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.set_root_position(x, y);
            Ok(())
        });
        // -- boneCount --
        /// Returns the total number of bones in the skeleton.
        /// @return | integer | Bone count.
        methods.add_method("boneCount", |_, this, ()| Ok(this.inner.bone_count()));
        // -- slotCount --
        /// Returns the total number of slots in the skeleton.
        /// @return | integer | Slot count.
        methods.add_method("slotCount", |_, this, ()| Ok(this.inner.slot_count()));
        // -- drawToImage --
        /// Renders the skeleton into an in-memory image of the given dimensions and returns it as LImageData userdata.
        /// @param | w | integer | Width of the output image in pixels.
        /// @param | h | integer | Height of the output image in pixels.
        /// @return | LImageData | A new image data object containing the rendered skeleton.
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });
        // -- playAnimation --
        /// Starts playing a named animation on this skeleton. Optionally loops.
        /// @param | name | string | Name of the animation to play (must have been added via addAnimation).
        /// @param | looping | boolean? | Whether to loop the animation. Defaults to true.
        /// @return | boolean | True if the animation was found and started, false otherwise.
        methods.add_method_mut(
            "playAnimation",
            |_, this, (name, looping): (String, Option<bool>)| {
                Ok(this.inner.play_animation(&name, looping.unwrap_or(true)))
            },
        );
        // -- stopAnimation --
        /// Stops the currently playing animation and resets playback state.
        methods.add_method_mut("stopAnimation", |_, this, ()| {
            this.inner.stop_animation();
            Ok(())
        });
        // -- updateAnimation --
        /// Advances the current animation by a delta time, applying bone transforms to the skeleton.
        /// @param | dt | number | Time step in seconds (e.g. from lurek.timer.getDelta()).
        methods.add_method_mut("updateAnimation", |_, this, dt: f32| {
            this.inner.update_animation(dt);
            Ok(())
        });
        // -- getAnimationTime --
        /// Returns the current playback time of the active animation in seconds.
        /// @return | number | Current animation time position.
        methods.add_method("getAnimationTime", |_, this, ()| {
            Ok(this.inner.get_animation_time())
        });
        // -- addAnimation --
        /// Registers a SkeletonAnimation object with this skeleton so it can be played by name.
        /// @param | anim | LSkeletonAnimation | The animation userdata to register. Consumed by this call.
        methods.add_method_mut("addAnimation", |_, this, anim_ud: LuaAnyUserData| {
            let anim = anim_ud.take::<LuaSkeletonAnimation>()?.inner;
            this.inner.add_animation(anim);
            Ok(())
        });
        // -- addIKConstraint --
        /// Adds an inverse-kinematics constraint that controls a chain of bones to reach a target position.
        /// @param | name | string | Unique name for this IK constraint (used with setIKTarget).
        /// @param | chain | table | Array of bone indices forming the IK chain from root to tip.
        /// @param | bend_positive | boolean? | Whether the joint bends in the positive direction. Defaults to true.
        /// @return | integer | Index of the newly added constraint.
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
        /// Sets the world-space target position for a named IK constraint. Call updateWorldTransforms after.
        /// @param | name | string | Name of the IK constraint to update.
        /// @param | x | number | Target world X coordinate.
        /// @param | y | number | Target world Y coordinate.
        /// @return | boolean | True if the constraint was found and updated, false otherwise.
        methods.add_method_mut(
            "setIKTarget",
            |_, this, (name, x, y): (String, f32, f32)| Ok(this.inner.set_ik_target(&name, x, y)),
        );
        // -- addSkin --
        /// Registers a new named skin on this skeleton. Skins remap slot attachments for visual variants.
        /// @param | name | string | Unique name for the skin.
        methods.add_method_mut("addSkin", |_, this, name: String| {
            this.inner.add_skin(&name);
            Ok(())
        });
        // -- setSkin --
        /// Activates a named skin, applying its slot-attachment mappings to the skeleton.
        /// @param | name | string | Name of the skin to activate (must have been added via addSkin).
        /// @return | boolean | True if the skin was found and activated, false otherwise.
        methods.add_method_mut("setSkin", |_, this, name: String| {
            Ok(this.inner.set_skin(&name))
        });
        // -- getSkin --
        /// Returns the name of the currently active skin, or nil if no skin is set.
        /// @return | string | Active skin name or nil.
        methods.add_method("getSkin", |_, this, ()| {
            Ok(this.inner.get_skin().map(|s| s.to_owned()))
        });
        // -- setSkinMapping --
        /// Maps a slot to a specific attachment name within a skin. When that skin is active, the slot shows this attachment.
        /// @param | skin | string | Name of the skin to add the mapping to.
        /// @param | slot | string | Name of the slot to remap.
        /// @param | attachment | string | Attachment name to display in that slot when the skin is active.
        methods.add_method_mut(
            "setSkinMapping",
            |_, this, (skin, slot, attachment): (String, String, String)| {
                this.inner.set_skin_mapping(&skin, &slot, &attachment);
                Ok(())
            },
        );
        // -- blendAnimation --
        /// Blends an animation pose onto the skeleton at a given time with a weight factor for smooth transitions.
        /// @param | anim | LSkeletonAnimation | The animation to sample and blend from.
        /// @param | time | number | The time position to sample within the animation.
        /// @param | blend_weight | number? | Blend factor from 0.0 (no effect) to 1.0 (full). Defaults to 1.0.
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
        /// Returns the type name of this userdata object.
        /// @return | string | Always "LSkeleton".
        methods.add_method("type", |_, _, ()| Ok("LSkeleton"));
        // -- typeOf --
        /// Checks whether this object is of the given type name. Supports "LSkeleton" and "Object".
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeleton" || name == "Object")
        });
    }
}
/// Lua-facing animation object containing bone timelines, keyframes, events, and easing curves.
pub struct LuaSkeletonAnimation {
    inner: SkeletonAnimation,
}
impl LuaUserData for LuaSkeletonAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addKeyframe --
        /// Adds a keyframe to a bone's property timeline at a specific time with a value and easing curve.
        /// @param | bone_idx | integer | Zero-based index of the target bone.
        /// @param | property | string | Bone property: "x", "y", "rotation", "scale_x", or "scale_y".
        /// @param | time | number | Time position in seconds for this keyframe.
        /// @param | value | number | Value of the property at this keyframe.
        /// @param | easing | string? | Easing type: "linear" (default), "ease_in", "ease_out", "ease_in_out", or "step".
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
        /// Returns the total duration of this animation in seconds.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration));
        // -- addEventKey --
        /// Inserts an event trigger at a specific time within the animation timeline.
        /// @param | time | number | Time position in seconds when the event fires.
        /// @param | name | string | Name of the event (used to identify it when querying).
        /// @param | value | number? | Optional numeric payload for the event. Defaults to 0.
        methods.add_method_mut(
            "addEventKey",
            |_, this, (time, name, value): (f32, String, Option<f32>)| {
                this.inner.add_event_key(time, name, value.unwrap_or(0.0));
                Ok(())
            },
        );
        // -- getEvents --
        /// Collects all events that fire within a time range. Useful for triggering sound effects or gameplay actions.
        /// @param | from | number | Start time in seconds (inclusive).
        /// @param | to | number | End time in seconds (exclusive).
        /// @return | table | Array of tables, each with "name" (string) and "value" (number) fields.
    /// @field | name | string | Event name.
    /// @field | value | number | Event value.
        methods.add_method("getEvents", |lua, this, (from, to): (f32, f32)| {
            let pairs = this.inner.collect_events(from, to);
            let tbl = lua.create_table()?;
            for (i, (name, value)) in pairs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'name' operation.
                entry.set("name", name)?;
                /// Performs the 'value' operation.
                entry.set("value", value)?;
                tbl.set(i + 1, entry)?;
            }
            Ok(tbl)
        });
        // -- getTimelineCount --
        /// Returns the number of bone-property timelines in this animation.
        /// @return | integer | Timeline count.
        methods.add_method("getTimelineCount", |_, this, ()| {
            Ok(this.inner.timelines.len())
        });
        // -- poseAt --
        /// Samples all timelines at a given time and returns the computed pose as an array of bone-property-value entries.
        /// @param | time | number | Time position in seconds to sample.
        /// @return | table | Array of tables, each with "bone_idx" (integer), "property" (string), and "value" (number).
    /// @field | bone_idx | integer | Bone index.
    /// @field | property | string | Property name.
    /// @field | value | number | Property value.
        methods.add_method("poseAt", |lua, this, time: f32| {
            let snapshot = this.inner.pose_at(time);
            let arr = lua.create_table()?;
            for (i, (bone_idx, prop, value)) in snapshot.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'bone_idx' operation.
                entry.set("bone_idx", *bone_idx)?;
                let prop_name = match prop {
                    BoneProperty::X => "x",
                    BoneProperty::Y => "y",
                    BoneProperty::Rotation => "rotation",
                    BoneProperty::ScaleX => "scale_x",
                    BoneProperty::ScaleY => "scale_y",
                };
                /// Performs the 'property' operation.
                entry.set("property", prop_name)?;
                /// Performs the 'value' operation.
                entry.set("value", *value)?;
                arr.set(i + 1, entry)?;
            }
            Ok(arr)
        });
        // -- reverse --
        /// Creates a new animation that plays this animation's keyframes in reverse order.
        /// @return | LSkeletonAnimation | A new reversed copy of this animation.
        methods.add_method("reverse", |lua, this, ()| {
            lua.create_userdata(LuaSkeletonAnimation {
                inner: this.inner.reverse(),
            })
        });
        // -- type --
        /// Returns the type name of this userdata object.
        /// @return | string | Always "LSkeletonAnimation".
        methods.add_method("type", |_, _, ()| Ok("LSkeletonAnimation"));
        // -- typeOf --
        /// Checks whether this object is of the given type name. Supports "LSkeletonAnimation" and "Object".
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeletonAnimation" || name == "Object")
        });
    }
}
/// Registers the `lurek.spine` module on the given Lua table.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newSkeleton --
    /// Creates a new empty skeleton with the given name. Add bones and slots to build the hierarchy.
    /// @param | name | string | Name identifier for this skeleton.
    /// @return | LSkeleton | A new skeleton userdata.
    tbl.set(
        "newSkeleton",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaSkeleton {
                inner: Skeleton::new(&name),
            })
        })?,
    )?;
    // -- newSkeletonAnimation --
    /// Creates a new empty animation with the given name and duration. Add keyframes to define motion.
    /// @param | name | string | Name identifier for this animation (used with playAnimation).
    /// @param | duration | number | Total duration of the animation in seconds.
    /// @return | LSkeletonAnimation | A new animation userdata.
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
    /// Parses a JSON string into a SkeletonAnimation. Returns nil if parsing fails or the format is invalid.
    /// @param | json | string | JSON string describing the animation (Spine-compatible format).
    /// @return | LSkeletonAnimation | Parsed animation userdata, or nil on failure.
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
    /// Performs the 'spine' operation.
    luna.set("spine", tbl)?;
    Ok(())
}
