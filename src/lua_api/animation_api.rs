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
pub struct LuaAnimation {
    inner: Animation,
}
impl LuaUserData for LuaAnimation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addFrame", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            Ok(this.inner.add_frame(Rect::new(x, y, w, h)))
        });
        methods.add_method_mut(
            "addFramesFromGrid",
            |_, this, (tw, th, fw, fh, start, count): (u32, u32, u32, u32, usize, usize)| {
                Ok(this
                    .inner
                    .add_frames_from_grid(tw, th, fw, fh, start, count))
            },
        );
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
        methods.add_method_mut("setClipMode", |_, this, (name, mode): (String, String)| {
            let mode = parse_clip_mode(Some(mode.as_str()))?;
            if let Some(clip) = this.inner.get_clip_mut(&name) {
                clip.mode = mode;
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method("getClipMode", |_, this, name: String| {
            Ok(this
                .inner
                .get_clip(&name)
                .map(|clip| clip_mode_name(clip.mode).to_string()))
        });
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
        methods.add_method_mut("play", |_, this, name: String| Ok(this.inner.play(&name)));
        methods.add_method_mut("stop", |_, this, ()| {
            this.inner.stop();
            Ok(())
        });
        methods.add_method_mut("pause", |_, this, ()| {
            this.inner.pause();
            Ok(())
        });
        methods.add_method_mut("resume", |_, this, ()| {
            this.inner.resume();
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
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
        methods.add_method("isPlaying", |_, this, ()| Ok(this.inner.is_playing()));
        methods.add_method("isLooping", |_, this, ()| Ok(this.inner.is_looping()));
        methods.add_method("getClip", |_, this, ()| {
            Ok(this.inner.get_current_clip().map(|s| s.to_owned()))
        });
        methods.add_method("getSpeed", |_, this, ()| Ok(this.inner.get_speed()));
        methods.add_method_mut("setSpeed", |_, this, speed: f32| {
            this.inner.set_speed(speed);
            Ok(())
        });
        methods.add_method("getFrameCount", |_, this, ()| {
            Ok(this.inner.get_frame_count())
        });
        methods.add_method("getClipCount", |_, this, ()| {
            Ok(this.inner.get_clip_count())
        });
        methods.add_method("getCurrentFrame", |_, this, ()| {
            Ok(this.inner.current_frame())
        });
        methods.add_method_mut("setFrame", |_, this, index: usize| {
            this.inner.set_frame(index);
            Ok(())
        });
        methods.add_method_mut(
            "crossfade",
            |_, this, (clip_name, duration): (String, f32)| {
                Ok(this.inner.crossfade(&clip_name, duration))
            },
        );
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
        methods.add_method("drawToImage", |lua, this, (w, h): (u32, u32)| {
            let img = this.inner.draw_to_image(w, h);
            lua.create_userdata(img)
        });
        methods.add_method(
            "drawPreviewGrid",
            |lua, this, (columns, cell_size): (u32, u32)| {
                let img = this.inner.draw_preview_grid(columns, cell_size);
                lua.create_userdata(img)
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LAnimation"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimation" || name == "Object")
        });
    }
}
pub struct LuaAnimStateMachine {
    inner: AnimStateMachine,
}
impl LuaUserData for LuaAnimStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.get_state().to_owned())
        });
        methods.add_method_mut("forceState", |_, this, name: String| {
            Ok(this.inner.force_state(&name))
        });
        methods.add_method_mut(
            "addState",
            |_, this, (name, clip, looping): (String, String, bool)| {
                this.inner.add_state(&name, &clip, looping);
                Ok(())
            },
        );
        methods.add_method_mut(
            "addTransition",
            |_, this, (from_state, to_state, condition): (String, String, String)| {
                this.inner
                    .add_transition(&from_state, &to_state, &condition);
                Ok(())
            },
        );
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
        methods.add_method("type", |_, _, ()| Ok("LAnimStateMachine"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimStateMachine" || name == "Object")
        });
    }
}
pub struct LuaBlendLayerSet {
    inner: BlendLayerSet,
}
impl LuaUserData for LuaBlendLayerSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.inner
                .remove_layer(&name)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });
        methods.add_method_mut("setWeight", |_, this, (name, weight): (String, f32)| {
            this.inner
                .set_weight(&name, weight)
                .map_err(LuaError::RuntimeError)?;
            Ok(true)
        });
        methods.add_method("getWeight", |_, this, name: String| {
            Ok(this.inner.get_weight(&name))
        });
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
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        methods.add_method("type", |_, _, ()| Ok("LBlendLayerSet"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBlendLayerSet" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "new",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimation {
                inner: Animation::new(),
            })
        })?,
    )?;
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
    tbl.set(
        "newStateMachine",
        lua.create_function(|lua, (anim_ud, initial): (LuaAnyUserData, String)| {
            let anim = anim_ud.take::<LuaAnimation>()?.inner;
            lua.create_userdata(LuaAnimStateMachine {
                inner: AnimStateMachine::new(anim, initial),
            })
        })?,
    )?;
    tbl.set(
        "newCurve",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimCurve {
                inner: crate::animation::curve::AnimCurve::new(),
                custom_easing: None,
            })
        })?,
    )?;
    tbl.set(
        "newSyncGroup",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAnimSyncGroup {
                inner: crate::animation::sync_group::AnimSyncGroup::new(),
            })
        })?,
    )?;
    tbl.set(
        "newBlendLayerSet",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaBlendLayerSet {
                inner: BlendLayerSet::new(),
            })
        })?,
    )?;
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
pub struct LuaAnimCurve {
    inner: crate::animation::curve::AnimCurve,
    custom_easing: Option<LuaRegistryKey>,
}
impl LuaUserData for LuaAnimCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addKeyframe", |_, this, (t, v): (f32, f32)| {
            this.inner.add_keyframe(t, v);
            Ok(())
        });
        methods.add_method("eval", |lua, this, t: f32| {
            if let Some(key) = &this.custom_easing {
                let func: mlua::Function = lua.registry_value(key)?;
                let v: f64 = func.call(t as f64)?;
                return Ok(v as f32);
            }
            Ok(this.inner.eval(t))
        });
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
        methods.add_method("keyframeCount", |_, this, ()| {
            Ok(this.inner.keyframe_count())
        });
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
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LAnimCurve"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimCurve" || name == "Object")
        });
    }
}
pub struct LuaAnimSyncGroup {
    inner: crate::animation::sync_group::AnimSyncGroup,
}
impl LuaUserData for LuaAnimSyncGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("add", |_, _this, _handle: LuaValue| Ok(()));
        methods.add_method_mut("remove", |_, _this, _handle: LuaValue| Ok(()));
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("memberCount", |_, this, ()| Ok(this.inner.member_count()));
        methods.add_method("type", |_, _, ()| Ok("LAnimSyncGroup"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAnimSyncGroup" || name == "Object")
        });
    }
}
