use super::SharedState;
use crate::camera::{
    Camera2D, CameraFollowEasing, CameraPath, CameraRig2D, CameraTweenEasing, ZoomTween,
};
use crate::render::renderer::RenderCommand;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
fn make_lua_camera(inner: Rc<RefCell<Camera2D>>, state: Rc<RefCell<SharedState>>) -> LuaCamera2D {
    LuaCamera2D {
        inner,
        path: RefCell::new(None),
        zoom_tween: RefCell::new(None),
        parallax: RefCell::new(HashMap::new()),
        state,
    }
}
fn parse_follow_easing(name: &str) -> CameraFollowEasing {
    match name.to_ascii_lowercase().as_str() {
        "smoothstep" | "smooth" => CameraFollowEasing::SmoothStep,
        "easeout" | "ease_out" | "ease-out" => CameraFollowEasing::EaseOutCubic,
        _ => CameraFollowEasing::Linear,
    }
}
fn parse_zoom_easing(name: Option<String>) -> CameraTweenEasing {
    match name
        .unwrap_or_else(|| "linear".to_string())
        .to_ascii_lowercase()
        .as_str()
    {
        "smoothstep" | "smooth" => CameraTweenEasing::SmoothStep,
        "easeout" | "ease_out" | "ease-out" => CameraTweenEasing::EaseOutCubic,
        _ => CameraTweenEasing::Linear,
    }
}
pub struct LuaCamera2D {
    inner: Rc<RefCell<Camera2D>>,
    path: RefCell<Option<CameraPath>>,
    zoom_tween: RefCell<Option<ZoomTween>>,
    parallax: RefCell<HashMap<String, f32>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaCamera2D {
    pub(crate) fn visible_area(&self) -> (f32, f32, f32, f32) {
        self.inner.borrow().get_visible_area()
    }
    pub(crate) fn position(&self) -> (f32, f32) {
        self.inner.borrow().get_position()
    }
}
impl LuaUserData for LuaCamera2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_position(x, y);
            Ok(())
        });
        methods.add_method("getPosition", |_, this, ()| {
            Ok(this.inner.borrow().get_position())
        });
        methods.add_method("setZoom", |_, this, zoom: f32| {
            this.inner.borrow_mut().set_zoom(zoom);
            Ok(())
        });
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.borrow().get_zoom()));
        methods.add_method("setRotation", |_, this, r: f32| {
            this.inner.borrow_mut().set_rotation(r);
            Ok(())
        });
        methods.add_method("getRotation", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation())
        });
        methods.add_method(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_viewport(x, y, w, h);
                Ok(())
            },
        );
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().get_viewport())
        });
        methods.add_method("getBounds", |_, this, ()| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().get_bounds() {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });
        methods.add_method("hasBounds", |_, this, ()| {
            Ok(this.inner.borrow().has_bounds())
        });
        methods.add_method(
            "setBounds",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.borrow_mut().set_bounds(x, y, w, h);
                Ok(())
            },
        );
        methods.add_method("removeBounds", |_, this, ()| {
            this.inner.borrow_mut().remove_bounds();
            Ok(())
        });
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().set_target(x, y);
            Ok(())
        });
        methods.add_method("getTarget", |_, this, ()| {
            let out = if let Some((x, y)) = this.inner.borrow().get_target() {
                (true, x, y)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });
        methods.add_method("clearTarget", |_, this, ()| {
            this.inner.borrow_mut().clear_target();
            Ok(())
        });
        methods.add_method("setFollowSmooth", |_, this, speed: f32| {
            this.inner.borrow_mut().set_follow_smooth(speed);
            Ok(())
        });
        methods.add_method("getFollowSmooth", |_, this, ()| {
            Ok(this.inner.borrow().get_follow_smooth())
        });
        methods.add_method("setFollowEasing", |_, this, easing: String| {
            this.inner
                .borrow_mut()
                .set_follow_easing(parse_follow_easing(&easing));
            Ok(())
        });
        methods.add_method("getFollowEasing", |_, this, ()| {
            let mode = match this.inner.borrow().get_follow_easing() {
                CameraFollowEasing::Linear => "linear",
                CameraFollowEasing::SmoothStep => "smoothstep",
                CameraFollowEasing::EaseOutCubic => "easeout",
            };
            Ok(mode)
        });
        methods.add_method("setDeadZone", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_dead_zone(w, h);
            Ok(())
        });
        methods.add_method("getDeadZone", |_, this, ()| {
            let out = if let Some((w, h)) = this.inner.borrow().get_dead_zone() {
                (true, w, h)
            } else {
                (false, 0.0, 0.0)
            };
            Ok(out)
        });
        methods.add_method("setLookAhead", |_, this, mul: f32| {
            this.inner.borrow_mut().set_look_ahead(mul);
            Ok(())
        });
        methods.add_method("getLookAhead", |_, this, ()| {
            Ok(this.inner.borrow().get_look_ahead())
        });
        methods.add_method(
            "onWindowResize",
            |_, this, (window_w, window_h): (f32, f32)| {
                this.inner.borrow_mut().on_window_resize(window_w, window_h);
                Ok(())
            },
        );
        methods.add_method(
            "onWindowResizeScaled",
            |_, this, (game_w, game_h, window_w, window_h, mode): (f32, f32, f32, f32, String)| {
                let scale_mode = match mode.to_ascii_lowercase().as_str() {
                    "stretch" => crate::camera::ScaleMode::Stretch,
                    "pixelperfect" | "pixel_perfect" | "pixel-perfect" => {
                        crate::camera::ScaleMode::PixelPerfect
                    }
                    _ => crate::camera::ScaleMode::Letterbox,
                };
                this.inner
                    .borrow_mut()
                    .on_window_resize_scaled(game_w, game_h, window_w, window_h, scale_mode);
                Ok(())
            },
        );
        methods.add_method("shake", |_, this, (intensity, duration): (f32, f32)| {
            this.inner.borrow_mut().shake(intensity, duration);
            Ok(())
        });
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("toWorld", |_, this, (sx, sy): (f32, f32)| {
            Ok(this.inner.borrow().to_world_coords(sx, sy))
        });
        methods.add_method("toScreen", |_, this, (wx, wy): (f32, f32)| {
            Ok(this.inner.borrow().to_screen_coords(wx, wy))
        });
        methods.add_method("getVisibleArea", |_, this, ()| {
            Ok(this.inner.borrow().get_visible_area())
        });
        methods.add_method("lookAt", |_, this, (x, y): (f32, f32)| {
            this.inner.borrow_mut().look_at(x, y);
            Ok(())
        });
        methods.add_method("move", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().move_by(dx, dy);
            Ok(())
        });
        methods.add_method(
            "followPath",
            |_, this, (points, duration): (LuaTable, f32)| {
                let mut waypoints: Vec<[f32; 2]> = Vec::new();
                for pair in points.sequence_values::<LuaTable>() {
                    let pair = pair?;
                    let x: f32 = pair.get(1).unwrap_or(0.0);
                    let y: f32 = pair.get(2).unwrap_or(0.0);
                    waypoints.push([x, y]);
                }
                *this.path.borrow_mut() = Some(CameraPath::new(waypoints, duration));
                Ok(())
            },
        );
        methods.add_method("stopPath", |_, this, ()| {
            this.path.borrow_mut().take();
            Ok(())
        });
        methods.add_method("updatePath", |_, this, dt: f32| {
            let pos = this.path.borrow_mut().as_mut().and_then(|p| p.update(dt));
            if let Some((x, y)) = pos {
                this.inner.borrow_mut().set_position(x, y);
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method("pathProgress", |_, this, ()| {
            Ok(this
                .path
                .borrow()
                .as_ref()
                .map(|p| p.progress())
                .unwrap_or(1.0))
        });
        methods.add_method(
            "zoomTo",
            |_, this, (target_zoom, duration, easing): (f32, f32, Option<String>)| {
                let current = this.inner.borrow().get_zoom();
                *this.zoom_tween.borrow_mut() = Some(ZoomTween::new_with_easing(
                    current,
                    target_zoom,
                    duration,
                    parse_zoom_easing(easing),
                ));
                Ok(())
            },
        );
        methods.add_method("stopZoom", |_, this, ()| {
            this.zoom_tween.borrow_mut().take();
            Ok(())
        });
        methods.add_method("updateZoom", |_, this, dt: f32| {
            let zoom = this
                .zoom_tween
                .borrow_mut()
                .as_mut()
                .and_then(|z| z.update(dt));
            if let Some(z) = zoom {
                this.inner.borrow_mut().set_zoom(z);
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method(
            "setParallaxFactor",
            |_, this, (layer, factor): (String, f32)| {
                this.parallax.borrow_mut().insert(layer, factor);
                Ok(())
            },
        );
        methods.add_method("getParallaxFactor", |_, this, layer: String| {
            Ok(*this.parallax.borrow().get(&layer).unwrap_or(&1.0))
        });
        methods.add_method("clearParallaxFactors", |_, this, ()| {
            this.parallax.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("apply", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });
        methods.add_method("reset", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });
        methods.add_method("attach", |_, this, ()| {
            let mut state = this.state.borrow_mut();
            this.inner
                .borrow()
                .append_begin_render_commands(&mut state.render_commands);
            Ok(())
        });
        methods.add_method("detach", |_, this, ()| {
            this.state
                .borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        });
        methods.add_method("zoomPulse", |_, this, (amplitude, duration): (f32, f32)| {
            this.inner
                .borrow_mut()
                .zoom_pulse
                .trigger(amplitude, duration);
            Ok(())
        });
        methods.add_method("startSway", |_, this, (amplitude_x, amplitude_y, frequency, decay): (f32, f32, f32, Option<f32>)| {
                let decay = decay.unwrap_or(1.0);
                this.inner
                    .borrow_mut()
                    .sway
                    .start(amplitude_x, amplitude_y, frequency, decay);
                Ok(())
            },
        );
        methods.add_method("stopSway", |_, this, ()| {
            this.inner.borrow_mut().sway.stop();
            Ok(())
        });
        methods.add_method("isSway", |_, this, ()| {
            Ok(this.inner.borrow().sway.is_active())
        });
        methods.add_method(
            "startBreathing",
            |_, this, (amplitude, rate): (Option<f32>, Option<f32>)| {
                let amplitude = amplitude.unwrap_or(0.005);
                let rate = rate.unwrap_or(0.2);
                this.inner.borrow_mut().breathing.start(amplitude, rate);
                Ok(())
            },
        );
        methods.add_method("stopBreathing", |_, this, ()| {
            this.inner.borrow_mut().breathing.stop();
            Ok(())
        });
        methods.add_method("isBreathing", |_, this, ()| {
            Ok(this.inner.borrow().breathing.is_active())
        });
        methods.add_method("getEffectiveZoom", |_, this, ()| {
            Ok(this.inner.borrow().effective_zoom())
        });
        methods.add_method("getEffectOffset", |_, this, ()| {
            Ok(this.inner.borrow().effect_offset())
        });
        methods.add_method("getShakeOffset", |_, this, ()| {
            Ok(this.inner.borrow().get_shake_offset())
        });
        methods.add_method("getRenderOffset", |_, this, ()| {
            Ok(this.inner.borrow().render_offset())
        });
        methods.add_method(
            "setZoomConstraints",
            |_, this, (min_zoom, max_zoom): (Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_zoom_constraints(min_zoom, max_zoom);
                Ok(())
            },
        );
        methods.add_method("getZoomConstraints", |_, this, ()| {
            let (min_z, max_z) = this.inner.borrow().get_zoom_constraints();
            Ok((
                min_z.is_some(),
                min_z.unwrap_or(0.0),
                max_z.is_some(),
                max_z.unwrap_or(0.0),
            ))
        });
        methods.add_method("setZoomDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_zoom_damping(damping);
            Ok(())
        });
        methods.add_method("getZoomDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_zoom_damping())
        });
        methods.add_method(
            "setRotationConstraints",
            |_, this, (min_rot, max_rot): (Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .set_rotation_constraints(min_rot, max_rot);
                Ok(())
            },
        );
        methods.add_method("getRotationConstraints", |_, this, ()| {
            let (min_r, max_r) = this.inner.borrow().get_rotation_constraints();
            Ok((
                min_r.is_some(),
                min_r.unwrap_or(0.0),
                max_r.is_some(),
                max_r.unwrap_or(0.0),
            ))
        });
        methods.add_method("setRotationDamping", |_, this, damping: f32| {
            this.inner.borrow_mut().set_rotation_damping(damping);
            Ok(())
        });
        methods.add_method("getRotationDamping", |_, this, ()| {
            Ok(this.inner.borrow().get_rotation_damping())
        });
        methods.add_method("presetTightFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_tight_follow();
            Ok(())
        });
        methods.add_method("presetCinematicFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_cinematic_follow();
            Ok(())
        });
        methods.add_method("presetBalancedFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_balanced_follow();
            Ok(())
        });
        methods.add_method("presetAggressiveFollow", |_, this, ()| {
            this.inner.borrow_mut().preset_aggressive_follow();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LCamera"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCamera" || name == "Object")
        });
    }
}
pub struct LuaCameraRig {
    inner: Rc<RefCell<CameraRig2D>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaCameraRig {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "splitScreen",
            |_, this, (window_w, window_h): (f32, f32)| {
                this.inner
                    .borrow_mut()
                    .apply_split_screen_layout(window_w, window_h);
                Ok(())
            },
        );
        methods.add_method(
            "minimap",
            |_, this, (window_w, window_h, ratio): (f32, f32, Option<f32>)| {
                this.inner.borrow_mut().apply_minimap_layout(
                    window_w,
                    window_h,
                    ratio.unwrap_or(0.25),
                );
                Ok(())
            },
        );
        methods.add_method(
            "pictureInPicture",
            |_, this, (window_w, window_h, pip_w, pip_h): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner.borrow_mut().apply_picture_in_picture_layout(
                    window_w,
                    window_h,
                    pip_w.unwrap_or(320.0),
                    pip_h.unwrap_or(180.0),
                );
                Ok(())
            },
        );
        methods.add_method(
            "setPosition",
            |_, this, (name, x, y): (String, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .ensure_camera(&name, 800.0, 600.0)
                    .set_position(x, y);
                Ok(())
            },
        );
        methods.add_method("setZoom", |_, this, (name, zoom): (String, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_zoom(zoom);
            Ok(())
        });
        methods.add_method("setTarget", |_, this, (name, x, y): (String, f32, f32)| {
            this.inner
                .borrow_mut()
                .ensure_camera(&name, 800.0, 600.0)
                .set_target(x, y);
            Ok(())
        });
        methods.add_method("updateAll", |_, this, dt: f32| {
            this.inner.borrow_mut().update_all(dt);
            Ok(())
        });
        methods.add_method("apply", |_, this, name: String| {
            let rig = this.inner.borrow();
            if let Some(cam) = rig.camera(&name) {
                let mut state = this.state.borrow_mut();
                cam.append_begin_render_commands(&mut state.render_commands);
                return Ok(true);
            }
            Ok(false)
        });
        methods.add_method("getViewport", |_, this, name: String| {
            let out = if let Some((x, y, w, h)) = this.inner.borrow().viewport_of(&name) {
                (true, x, y, w, h)
            } else {
                (false, 0.0, 0.0, 0.0, 0.0)
            };
            Ok(out)
        });
        methods.add_method("names", |lua, this, ()| {
            let names = this.inner.borrow().camera_names();
            let table = lua.create_table()?;
            for (idx, name) in names.iter().enumerate() {
                table.set(idx + 1, name.as_str())?;
            }
            Ok(table)
        });
        methods.add_method("remove", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_camera(&name))
        });
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has_camera(&name))
        });
        methods.add_method("type", |_, _, ()| Ok("LCameraRig"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCameraRig" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "new",
        lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(make_lua_camera(
                Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                s.clone(),
            ))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newCamera",
        lua.create_function(move |lua, (vw, vh): (Option<f32>, Option<f32>)| {
            let vw = vw.unwrap_or(800.0);
            let vh = vh.unwrap_or(600.0);
            lua.create_userdata(make_lua_camera(
                Rc::new(RefCell::new(Camera2D::new(vw, vh))),
                s.clone(),
            ))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newRig",
        lua.create_function(move |lua, ()| {
            lua.create_userdata(LuaCameraRig {
                inner: Rc::new(RefCell::new(CameraRig2D::new())),
                state: s.clone(),
            })
        })?,
    )?;
    lurek.set("camera", tbl)?;
    Ok(())
}
