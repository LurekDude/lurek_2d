use super::SharedState;
use crate::globe::export::export_provinces_to_obj;
use crate::globe::loader;
use crate::globe::registry::{Globe, GlobeRegistry};
use crate::globe::types::{
    FogState, GlobeSpec, HeatLayer, LabelStyle, Layer, LodTier, MarkerStyle, Province,
    MAX_PROVINCES,
};
use crate::math::sphere::{great_circle_distance, great_circle_path, lat_lon_to_unit};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};
#[derive(Clone)]
pub struct LuaGlobe {
    reg: Arc<Mutex<GlobeRegistry>>,
    name: String,
    #[allow(dead_code)]
    state: Rc<RefCell<SharedState>>,
}
impl LuaGlobe {
    fn with<R>(&self, f: impl FnOnce(&Globe) -> R) -> LuaResult<R> {
        let guard = self
            .reg
            .lock()
            .map_err(|e| mlua::Error::RuntimeError(format!("globe registry lock poisoned: {e}")))?;
        guard
            .get(&self.name)
            .map(f)
            .ok_or_else(|| mlua::Error::RuntimeError(format!("globe '{}' not found", self.name)))
    }
    fn with_mut<R>(&self, f: impl FnOnce(&mut Globe) -> R) -> LuaResult<R> {
        let mut guard = self
            .reg
            .lock()
            .map_err(|e| mlua::Error::RuntimeError(format!("globe registry lock poisoned: {e}")))?;
        guard
            .get_mut(&self.name)
            .map(f)
            .ok_or_else(|| mlua::Error::RuntimeError(format!("globe '{}' not found", self.name)))
    }
}
impl LuaUserData for LuaGlobe {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addProvince", |_, this, p: LuaTable| {
            let id: u32 = p.get("id")?;
            let ct: LuaTable = p.get("centroid")?;
            let centroid = (ct.get::<_, f32>(1)?, ct.get::<_, f32>(2)?);
            let verts_tbl: LuaTable = p.get::<_, LuaTable>("vertices").map_err(|_| {
                mlua::Error::RuntimeError(format!("province {id}: 'vertices' field is required"))
            })?;
            let mut vertices = Vec::new();
            for vt in verts_tbl.sequence_values::<LuaTable>() {
                let vt = vt?;
                vertices.push((vt.get::<_, f32>(1)?, vt.get::<_, f32>(2)?));
            }
            let neighbors: Vec<u32> = p
                .get::<_, LuaTable>("neighbors")
                .map(|t| t.sequence_values::<u32>().collect::<LuaResult<Vec<_>>>())
                .unwrap_or_else(|_| Ok(vec![]))?;
            let color_tbl: Option<LuaTable> = p.get("base_color").ok();
            let base_color = if let Some(ct) = color_tbl {
                [
                    ct.get::<_, f32>(1).unwrap_or(0.5),
                    ct.get::<_, f32>(2).unwrap_or(0.5),
                    ct.get::<_, f32>(3).unwrap_or(0.5),
                    ct.get::<_, f32>(4).unwrap_or(1.0),
                ]
            } else {
                [0.5, 0.5, 0.5, 1.0]
            };
            let province = Province::with_data(id, centroid, vertices, neighbors, base_color);
            this.with_mut(|g| g.add_province(province).map(|_| true).unwrap_or(false))
        });
        methods.add_method_mut("removeProvince", |_, this, id: u32| {
            this.with_mut(|g| g.remove_province(id).is_some())
        });
        methods.add_method("provinceCount", |_, this, ()| {
            this.with(|g| g.province_count())
        });
        methods.add_method("getNeighbors", |lua, this, id: u32| {
            let neighbors = this.with(|g| {
                g.get_province(id)
                    .map(|p| p.neighbors.clone())
                    .unwrap_or_default()
            })?;
            let t = lua.create_table()?;
            for (i, n) in neighbors.iter().enumerate() {
                t.set(i + 1, *n)?;
            }
            Ok(t)
        });
        methods.add_method_mut(
            "setProvinceAttr",
            |_, this, (id, key, val): (u32, String, String)| {
                this.with_mut(|g| {
                    if let Some(p) = g.get_province_mut(id) {
                        p.attrs.insert(key, val);
                        true
                    } else {
                        false
                    }
                })
            },
        );
        methods.add_method("getProvinceAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.get_province(id).and_then(|p| p.attrs.get(&key).cloned()))
        });
        methods.add_method_mut(
            "setProvinceTexture",
            |_, this, (id, tex_raw, u0, v0, u1, v1): (u32, u64, f32, f32, f32, f32)| {
                this.with_mut(|g| {
                    if let Some(p) = g.get_province_mut(id) {
                        p.attrs
                            .insert("__texture_raw".to_string(), tex_raw.to_string());
                        p.texture_uv_rect = Some([u0, v0, u1, v1]);
                        true
                    } else {
                        false
                    }
                })
            },
        );
        methods.add_method_mut("clearProvinceTexture", |_, this, id: u32| {
            this.with_mut(|g| {
                if let Some(p) = g.get_province_mut(id) {
                    p.attrs.remove("__texture_raw");
                    p.texture_uv_rect = None;
                    true
                } else {
                    false
                }
            })
        });
        methods.add_method_mut(
            "setProvinceSector",
            |_, this, (id, sector): (u32, String)| {
                this.with_mut(|g| g.set_province_sector(id, sector))
            },
        );
        methods.add_method("getProvinceSector", |_, this, id: u32| {
            this.with(|g| g.province_sector(id).map(|s| s.to_string()))
        });
        methods.add_method("getSectorProvinces", |lua, this, sector: String| {
            let ids = this.with(|g| g.sector_provinces(&sector))?;
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(t)
        });
        methods.add_method_mut(
            "setHeatLayer",
            |_, this, (name, attr_key, min, max, alpha): (String, String, f32, f32, f32)| {
                this.with_mut(|g| {
                    g.set_heat_layer(HeatLayer {
                        name,
                        attr_key,
                        min_value: min,
                        max_value: max,
                        cold_color: [0.1, 0.2, 0.9, 1.0],
                        hot_color: [0.9, 0.2, 0.1, 1.0],
                        alpha: alpha.clamp(0.0, 1.0),
                        visible: true,
                        z_order: 0,
                    })
                })
            },
        );
        methods.add_method_mut("removeHeatLayer", |_, this, name: String| {
            this.with_mut(|g| g.remove_heat_layer(&name))
        });
        methods.add_method_mut("pan", |_, this, (dlat, dlon): (f32, f32)| {
            this.with_mut(|g| g.camera.pan(dlat, dlon))
        });
        methods.add_method_mut("zoom", |_, this, factor: f32| {
            this.with_mut(|g| g.camera.zoom_by(factor))
        });
        methods.add_method_mut("setCamera", |_, this, (lat, lon, z): (f32, f32, f32)| {
            this.with_mut(|g| {
                g.camera.lat_deg = lat;
                g.camera.lon_deg = lon;
                g.camera.zoom = z.max(0.1);
                g.camera.clamp();
            })
        });
        methods.add_method("getCamera", |_, this, ()| {
            this.with(|g| (g.camera.lat_deg, g.camera.lon_deg, g.camera.zoom))
        });
        methods.add_method("getLod", |_, this, ()| {
            this.with(|g| {
                match g.camera.lod() {
                    LodTier::Far => "far",
                    LodTier::Mid => "mid",
                    LodTier::Near => "near",
                }
                .to_string()
            })
        });
        methods.add_method("pick", |_, this, (sx, sy): (f32, f32)| {
            this.with(|g| g.pick_screen(sx, sy).map(|r| r.province_id))
        });
        methods.add_method(
            "pickRaycast",
            |_, this, (sx, sy, steps): (f32, f32, Option<u32>)| {
                let n = steps.unwrap_or(24).max(1);
                this.with(|g| {
                    let cx = g.camera.screen_cx;
                    let cy = g.camera.screen_cy;
                    let dx = sx - cx;
                    let dy = sy - cy;
                    for i in 1..=n {
                        let t = i as f32 / n as f32;
                        let px = cx + dx * t;
                        let py = cy + dy * t;
                        if let Some(hit) = g.pick_screen(px, py) {
                            return Some(hit.province_id);
                        }
                    }
                    None
                })
            },
        );
        methods.add_method("pickLatLon", |_lua, this, (sx, sy): (f32, f32)| {
            this.with(|g| match g.pick_screen(sx, sy) {
                Some(r) => (
                    Some(r.centroid_screen.x as f64),
                    Some(r.centroid_screen.y as f64),
                ),
                None => (None, None),
            })
        });
        methods.add_method_mut("setActiveViewer", |_, this, viewer: Option<String>| {
            this.with_mut(|g| g.active_viewer = viewer)
        });
        methods.add_method_mut(
            "setFogState",
            |_, this, (viewer, id, state): (String, u32, String)| {
                let st = match state.as_str() {
                    "visible" => FogState::Visible,
                    "explored" => FogState::Explored,
                    _ => FogState::Hidden,
                };
                this.with_mut(|g| g.fog.set_state(&viewer, id, st))
            },
        );
        methods.add_method("getFogState", |_, this, (viewer, id): (String, u32)| {
            this.with(|g| {
                match g.fog.state(&viewer, id) {
                    FogState::Visible => "visible",
                    FogState::Explored => "explored",
                    FogState::Hidden => "hidden",
                }
                .to_string()
            })
        });
        methods.add_method("encodeFogBase64", |_, this, viewer: String| {
            this.with(|g| g.fog.to_base64(&viewer).unwrap_or_default())
        });
        methods.add_method_mut(
            "decodeFogBase64",
            |_, this, (viewer, payload): (String, String)| {
                this.with_mut(|g| g.fog.load_base64(&viewer, &payload).is_ok())
            },
        );
        methods.add_method_mut("revealProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.reveal(&viewer, id))
        });
        methods.add_method_mut("hideProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.hide(&viewer, id))
        });
        methods.add_method("isVisible", |_, this, (viewer, id): (String, u32)| {
            this.with(|g| g.fog.is_visible(&viewer, id))
        });
        methods.add_method_mut("revealAll", |_, this, viewer: String| {
            this.with_mut(|g| {
                let ids: Vec<u32> = g.graph.iter().map(|p| p.id).collect();
                for id in ids {
                    g.fog.reveal(&viewer, id);
                }
            })
        });
        methods.add_method_mut(
            "addMarker",
            |_, this, (mtype, lat, lon, label): (String, f32, f32, Option<String>)| {
                this.with_mut(|g| {
                    g.markers
                        .add(mtype, lat, lon, label, MarkerStyle::default())
                })
            },
        );
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            this.with_mut(|g| g.markers.remove(id).is_some())
        });
        methods.add_method_mut("moveMarker", |_, this, (id, lat, lon): (u32, f32, f32)| {
            this.with_mut(|g| g.markers.move_to(id, lat, lon))
        });
        methods.add_method_mut("setMarkerVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.markers.set_visible(id, vis))
        });
        methods.add_method_mut(
            "setMarkerPulse",
            |_, this, (id, hz, amp): (u32, f32, f32)| {
                this.with_mut(|g| {
                    if let Some(m) = g.markers.get_mut(id) {
                        m.style.pulse_hz = hz.max(0.0);
                        m.style.pulse_amplitude = amp.clamp(0.0, 1.0);
                        true
                    } else {
                        false
                    }
                })
            },
        );
        methods.add_method_mut("setMarkerRotation", |_, this, (id, dps): (u32, f32)| {
            this.with_mut(|g| {
                if let Some(m) = g.markers.get_mut(id) {
                    m.style.rotation_deg_per_sec = dps;
                    true
                } else {
                    false
                }
            })
        });
        methods.add_method_mut(
            "setMarkerAttr",
            |_, this, (id, key, val): (u32, String, String)| {
                this.with_mut(|g| g.markers.set_attr(id, key, val))
            },
        );
        methods.add_method("getMarkerAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.markers.get_attr(id, &key).map(|s| s.to_owned()))
        });
        methods.add_method_mut(
            "addLabel",
            |_, this, (ltype, lat, lon, text): (String, f32, f32, String)| {
                this.with_mut(|g| {
                    g.labels
                        .add(ltype, lat, lon, text, LabelStyle::default(), 0)
                })
            },
        );
        methods.add_method_mut("setLabelText", |_, this, (id, text): (u32, String)| {
            this.with_mut(|g| g.labels.set_text(id, text))
        });
        methods.add_method_mut("setLabelVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.labels.set_visible(id, vis))
        });
        methods.add_method_mut("removeLabel", |_, this, id: u32| {
            this.with_mut(|g| g.labels.remove(id).is_some())
        });
        methods.add_method_mut(
            "addLayer",
            |_, this, (name, z_order): (String, Option<i32>)| {
                this.with_mut(|g| {
                    g.layers.add(Layer {
                        name,
                        visible: true,
                        alpha: 1.0,
                        z_order: z_order.unwrap_or(0),
                        kind: String::new(),
                        province_colors: HashMap::new(),
                    })
                })
            },
        );
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.with_mut(|g| g.layers.remove(&name).is_some())
        });
        methods.add_method_mut(
            "setLayerColor",
            |_, this, (layer, id, r, g, b, a): (String, u32, f32, f32, f32, f32)| {
                this.with_mut(|globe| globe.layers.set_province_color(&layer, id, [r, g, b, a]))
            },
        );
        methods.add_method_mut("setLayerVisible", |_, this, (name, vis): (String, bool)| {
            this.with_mut(|g| g.layers.set_visible(&name, vis))
        });
        methods.add_method_mut("setLayerAlpha", |_, this, (name, alpha): (String, f32)| {
            this.with_mut(|g| g.layers.set_alpha(&name, alpha))
        });
        methods.add_method_mut("setTimeOfDay", |_, this, t: f32| {
            this.with_mut(|g| g.spec.time_of_day = t % 24.0)
        });
        methods.add_method("getTimeOfDay", |_, this, ()| {
            this.with(|g| g.spec.time_of_day)
        });
        methods.add_method_mut("setRotation", |_, this, deg: f32| {
            this.with_mut(|g| g.spec.rotation_deg = deg)
        });
        methods.add_method_mut("setAutoRotationSpeed", |_, this, dps: f32| {
            this.with_mut(|g| g.spec.auto_rotation_deg_per_sec = dps)
        });
        methods.add_method_mut("update", |_, this, dt: f32| this.with_mut(|g| g.update(dt)));
        methods.add_method_mut("setBorders", |_, this, show: bool| {
            this.with_mut(|g| g.spec.render_borders = show)
        });
        methods.add_method("findPath", |lua, this, (from_id, to_id): (u32, u32)| {
            let path_opt = this.with(|g| g.graph.find_path_default(from_id, to_id))?;
            match path_opt {
                None => Ok(None),
                Some(path) => {
                    let t = lua.create_table()?;
                    for (i, id) in path.provinces.iter().enumerate() {
                        t.set(i + 1, *id)?;
                    }
                    Ok(Some(t))
                }
            }
        });
        methods.add_method(
            "reachable",
            |lua, this, (start_id, max_cost): (u32, f64)| {
                let reached = this.with(|g| g.graph.reachable_default(start_id, max_cost))?;
                let t = lua.create_table()?;
                for (id, cost) in reached {
                    t.set(id, cost)?;
                }
                Ok(t)
            },
        );
        methods.add_method_mut(
            "cacheReachability",
            |_, this, (faction, start_id, max_cost): (String, u32, f64)| {
                this.with_mut(|g| g.cache_reachability_default(faction, start_id, max_cost))
            },
        );
        methods.add_method("getCachedReachability", |lua, this, faction: String| {
            let t = lua.create_table()?;
            let map = this.with(|g| g.cached_reachability(&faction).cloned())?;
            if let Some(map) = map {
                for (id, cost) in map {
                    t.set(id, cost)?;
                }
            }
            Ok(t)
        });
        methods.add_method("exportProvinceMeshOBJ", |_, this, ()| {
            this.with(export_provinces_to_obj)
        });
        methods.add_method_mut(
            "addArc",
            |_, this, (lat1, lon1, lat2, lon2, steps): (f32, f32, f32, f32, Option<u32>)| {
                let steps = steps.unwrap_or(24);
                this.with_mut(|g| {
                    let arc_id = g.arc_next_id;
                    g.arc_next_id += 1;
                    let arc = crate::globe::types::Arc {
                        id: arc_id,
                        arc_type: "route".to_string(),
                        screen_points: Vec::new(),
                        color: [1.0, 1.0, 0.0, 1.0],
                        width: 1.5,
                        from: (lat1, lon1),
                        to: (lat2, lon2),
                        steps,
                        visible: true,
                    };
                    g.arcs.insert(arc_id, arc);
                    arc_id
                })
            },
        );
        methods.add_method_mut("removeArc", |_, this, id: u32| {
            this.with_mut(|g| g.remove_arc(id))
        });
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Globe(\"{}\")", this.name))
        });
        methods.add_method("type", |_, _, ()| Ok("LGlobe"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobe" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaGlobeRegistry {
    reg: Arc<Mutex<GlobeRegistry>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaGlobeRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "new",
            |_, this, (name, spec_tbl): (String, Option<LuaTable>)| {
                let spec = parse_globe_spec(spec_tbl);
                {
                    let mut guard = this.reg.lock().map_err(|e| {
                        mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                    })?;
                    guard.create(name.clone(), spec);
                }
                Ok(LuaGlobe {
                    reg: this.reg.clone(),
                    name,
                    state: this.state.clone(),
                })
            },
        );
        methods.add_method("get", |_, this, name: String| {
            let exists = {
                let guard = this.reg.lock().map_err(|e| {
                    mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                })?;
                guard.get(&name).is_some()
            };
            if exists {
                Ok(Some(LuaGlobe {
                    reg: this.reg.clone(),
                    name,
                    state: this.state.clone(),
                }))
            } else {
                Ok(None)
            }
        });
        methods.add_method_mut("remove", |_, this, name: String| {
            let mut guard = this
                .reg
                .lock()
                .map_err(|e| mlua::Error::RuntimeError(format!("registry lock poisoned: {e}")))?;
            Ok(guard.remove(&name).is_some())
        });
        methods.add_method("names", |lua, this, ()| {
            let guard = this
                .reg
                .lock()
                .map_err(|e| mlua::Error::RuntimeError(format!("registry lock poisoned: {e}")))?;
            let names = guard.names();
            let t = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                t.set(i + 1, n.clone())?;
            }
            Ok(t)
        });
        methods.add_method("type", |_, _, ()| Ok("LGlobeRegistry"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobeRegistry" || name == "Object")
        });
    }
}
fn parse_globe_spec(tbl: Option<LuaTable>) -> GlobeSpec {
    let mut spec = GlobeSpec::default();
    if let Some(t) = tbl {
        if let Ok(v) = t.get::<_, f32>("radius") {
            spec.radius = v;
        }
        if let Ok(v) = t.get::<_, f32>("axial_tilt_deg") {
            spec.axial_tilt_deg = v;
        }
        if let Ok(v) = t.get::<_, f32>("rotation_deg") {
            spec.rotation_deg = v;
        }
        if let Ok(v) = t.get::<_, f32>("time_of_day") {
            spec.time_of_day = v;
        }
        if let Ok(v) = t.get::<_, bool>("render_borders") {
            spec.render_borders = v;
        }
        if let Ok(v) = t.get::<_, f32>("border_width") {
            spec.border_width = v;
        }
        if let Ok(v) = t.get::<_, f32>("ambient") {
            spec.ambient = v;
        }
        if let Ok(v) = t.get::<_, f32>("auto_rotation_deg_per_sec") {
            spec.auto_rotation_deg_per_sec = v;
        }
        if let Ok(v) = t.get::<_, f32>("atmosphere_width") {
            spec.atmosphere_width = v.max(0.0);
        }
        if let Ok(v) = t.get::<_, u8>("border_smoothing_passes") {
            spec.border_smoothing_passes = v;
        }
    }
    spec
}
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let registry = Arc::new(Mutex::new(GlobeRegistry::new()));
    {
        let reg = registry.clone();
        let s = state.clone();
        tbl.set(
            "new",
            lua.create_function(move |_, (name, spec_tbl): (String, Option<LuaTable>)| {
                let spec = parse_globe_spec(spec_tbl);
                {
                    let mut guard = reg.lock().map_err(|e| {
                        mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                    })?;
                    guard.create(name.clone(), spec);
                }
                Ok(LuaGlobe {
                    reg: reg.clone(),
                    name,
                    state: s.clone(),
                })
            })?,
        )?;
    }
    {
        let reg = registry.clone();
        let s = state.clone();
        tbl.set(
            "get",
            lua.create_function(move |_, name: String| {
                let exists = {
                    let guard = reg.lock().map_err(|e| {
                        mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                    })?;
                    guard.get(&name).is_some()
                };
                if exists {
                    Ok(Some(LuaGlobe {
                        reg: reg.clone(),
                        name,
                        state: s.clone(),
                    }))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let reg = registry.clone();
        let s = state.clone();
        tbl.set(
            "loadFromTOML",
            lua.create_function(
                move |_, (name, toml_src, spec_tbl): (String, String, Option<LuaTable>)| {
                    let spec = parse_globe_spec(spec_tbl);
                    let provinces =
                        loader::load_from_toml_str(&toml_src).map_err(mlua::Error::RuntimeError)?;
                    {
                        let mut guard = reg.lock().map_err(|e| {
                            mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                        })?;
                        let globe = guard.create(name.clone(), spec);
                        for p in provinces {
                            let _ = globe.add_province(p);
                        }
                    }
                    Ok(LuaGlobe {
                        reg: reg.clone(),
                        name,
                        state: s.clone(),
                    })
                },
            )?,
        )?;
    }
    {
        let reg = registry.clone();
        let s = state.clone();
        tbl.set(
            "loadFromPNG",
            lua.create_function(
                move |_, (name, png_path, spec_tbl): (String, String, Option<LuaTable>)| {
                    let spec = parse_globe_spec(spec_tbl);
                    let provinces =
                        loader::load_from_png_file(&png_path).map_err(mlua::Error::RuntimeError)?;
                    {
                        let mut guard = reg.lock().map_err(|e| {
                            mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                        })?;
                        let globe = guard.create(name.clone(), spec);
                        for p in provinces {
                            let _ = globe.add_province(p);
                        }
                    }
                    Ok(LuaGlobe {
                        reg: reg.clone(),
                        name,
                        state: s.clone(),
                    })
                },
            )?,
        )?;
    }
    {
        let reg = registry.clone();
        let s = state.clone();
        tbl.set(
            "generateVoronoi",
            lua.create_function(
                move |_, (name, seeds_tbl, spec_tbl): (String, LuaTable, Option<LuaTable>)| {
                    let spec = parse_globe_spec(spec_tbl);
                    let mut seeds = Vec::new();
                    for item in seeds_tbl.sequence_values::<LuaTable>() {
                        let p = item?;
                        let lat: f32 = p.get(1)?;
                        let lon: f32 = p.get(2)?;
                        seeds.push((lat, lon));
                    }
                    let provinces = loader::generate_voronoi_provinces(&seeds);
                    {
                        let mut guard = reg.lock().map_err(|e| {
                            mlua::Error::RuntimeError(format!("registry lock poisoned: {e}"))
                        })?;
                        let globe = guard.create(name.clone(), spec);
                        for p in provinces {
                            let _ = globe.add_province(p);
                        }
                    }
                    Ok(LuaGlobe {
                        reg: reg.clone(),
                        name,
                        state: s.clone(),
                    })
                },
            )?,
        )?;
    }
    tbl.set(
        "greatCircleDistance",
        lua.create_function(|_, (la, lo, lb, lo2): (f32, f32, f32, f32)| {
            Ok(great_circle_distance(la, lo, lb, lo2))
        })?,
    )?;
    tbl.set(
        "greatCirclePath",
        lua.create_function(|lua, (la, lo, lb, lo2, n): (f32, f32, f32, f32, u32)| {
            let pts = great_circle_path(la, lo, lb, lo2, n);
            let t = lua.create_table()?;
            for (i, (lat, lon)) in pts.iter().enumerate() {
                let p = lua.create_table()?;
                p.set(1, *lat)?;
                p.set(2, *lon)?;
                t.set(i + 1, p)?;
            }
            Ok(t)
        })?,
    )?;
    tbl.set(
        "latLonToUnit",
        lua.create_function(|lua, (lat, lon): (f32, f32)| {
            let v = lat_lon_to_unit(lat, lon);
            let t = lua.create_table()?;
            t.set(1, v.x)?;
            t.set(2, v.y)?;
            t.set(3, v.z)?;
            Ok(t)
        })?,
    )?;
    tbl.set("MAX_PROVINCES", MAX_PROVINCES as u32)?;
    tbl.set("LOD_FAR", "far")?;
    tbl.set("LOD_MID", "mid")?;
    tbl.set("LOD_NEAR", "near")?;
    luna.set("globe", tbl)?;
    Ok(())
}
