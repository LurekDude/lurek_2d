use super::SharedState;
use crate::spine::ik::IKConstraint;
use crate::spine::timeline::{BoneProperty, BoneTimeline, EasingType, Keyframe, SkeletonAnimation};
use crate::spine::{BoneParams, Skeleton};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
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
pub struct LuaSkeleton {
    inner: Skeleton,
}
impl LuaUserData for LuaSkeleton {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method_mut(
            "addSlot",
            |_, this, (name, bone_idx, attachment): (String, usize, Option<String>)| {
                Ok(this.inner.add_slot_full(&name, bone_idx, attachment))
            },
        );
        methods.add_method("findBone", |_, this, name: String| {
            Ok(this.inner.find_bone(&name))
        });
        methods.add_method("findSlot", |_, this, name: String| {
            Ok(this.inner.find_slot(&name))
        });
        methods.add_method_mut("updateWorldTransforms", |_, this, ()| {
            this.inner.update_world_transforms();
            Ok(())
        });
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
        methods.add_method_mut("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.set_root_position(x, y);
            Ok(())
        });
        methods.add_method("boneCount", |_, this, ()| Ok(this.inner.bone_count()));
        methods.add_method("slotCount", |_, this, ()| Ok(this.inner.slot_count()));
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });
        methods.add_method_mut(
            "playAnimation",
            |_, this, (name, looping): (String, Option<bool>)| {
                Ok(this.inner.play_animation(&name, looping.unwrap_or(true)))
            },
        );
        methods.add_method_mut("stopAnimation", |_, this, ()| {
            this.inner.stop_animation();
            Ok(())
        });
        methods.add_method_mut("updateAnimation", |_, this, dt: f32| {
            this.inner.update_animation(dt);
            Ok(())
        });
        methods.add_method("getAnimationTime", |_, this, ()| {
            Ok(this.inner.get_animation_time())
        });
        methods.add_method_mut("addAnimation", |_, this, anim_ud: LuaAnyUserData| {
            let anim = anim_ud.take::<LuaSkeletonAnimation>()?.inner;
            this.inner.add_animation(anim);
            Ok(())
        });
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
        methods.add_method_mut(
            "setIKTarget",
            |_, this, (name, x, y): (String, f32, f32)| Ok(this.inner.set_ik_target(&name, x, y)),
        );
        methods.add_method_mut("addSkin", |_, this, name: String| {
            this.inner.add_skin(&name);
            Ok(())
        });
        methods.add_method_mut("setSkin", |_, this, name: String| {
            Ok(this.inner.set_skin(&name))
        });
        methods.add_method("getSkin", |_, this, ()| {
            Ok(this.inner.get_skin().map(|s| s.to_owned()))
        });
        methods.add_method_mut(
            "setSkinMapping",
            |_, this, (skin, slot, attachment): (String, String, String)| {
                this.inner.set_skin_mapping(&skin, &slot, &attachment);
                Ok(())
            },
        );
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
        methods.add_method("type", |_, _, ()| Ok("LSkeleton"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeleton" || name == "Object")
        });
    }
}
pub struct LuaSkeletonAnimation {
    inner: SkeletonAnimation,
}
impl LuaUserData for LuaSkeletonAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration));
        methods.add_method_mut(
            "addEventKey",
            |_, this, (time, name, value): (f32, String, Option<f32>)| {
                this.inner.add_event_key(time, name, value.unwrap_or(0.0));
                Ok(())
            },
        );
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
        methods.add_method("getTimelineCount", |_, this, ()| {
            Ok(this.inner.timelines.len())
        });
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
        methods.add_method("reverse", |lua, this, ()| {
            lua.create_userdata(LuaSkeletonAnimation {
                inner: this.inner.reverse(),
            })
        });
        methods.add_method("type", |_, _, ()| Ok("LSkeletonAnimation"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSkeletonAnimation" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newSkeleton",
        lua.create_function(|lua, name: String| {
            lua.create_userdata(LuaSkeleton {
                inner: Skeleton::new(&name),
            })
        })?,
    )?;
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
