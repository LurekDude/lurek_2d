//! `lurek.globe` -- Spherical province-map bindings for globe registries, province graphs, sectors, heat layers, camera controls, picking, fog of war, markers, labels, render layers, arcs, pathfinding, exports, and coordinate math.

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
/// Lua-side handle for a named globe stored inside a shared registry.
pub struct LuaGlobe {
    /// Shared globe registry containing all named globes.
    reg: Arc<Mutex<GlobeRegistry>>,
    /// Registry key for the globe represented by this Lua handle.
    name: String,
    #[allow(dead_code)]
    /// Shared runtime state retained for future renderer integration.
    state: Rc<RefCell<SharedState>>,
}
impl LuaGlobe {
    /// Reads the named globe from the registry and maps it to a Lua result.
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
            /// Mutates the named globe in the registry and maps it to a Lua result.
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
/// Provides Lua methods for editing and querying one named globe.
impl LuaUserData for LuaGlobe {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addProvince --
        /// Adds a province described by id, centroid, vertices, neighbors, and optional base color.
        /// @param | p | table | Province table with `id`, `centroid`, `vertices`, optional `neighbors`, and optional `base_color`.
        /// @return | boolean | True when the province was accepted by the globe.
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
        // -- removeProvince --
        /// Removes a province by id.
        /// @param | id | integer | Province id to remove.
        /// @return | boolean | True when a province was removed.
        methods.add_method_mut("removeProvince", |_, this, id: u32| {
            this.with_mut(|g| g.remove_province(id).is_some())
        });
        // -- provinceCount --
        /// Returns the number of provinces in this globe.
        /// @return | integer | Province count.
        methods.add_method("provinceCount", |_, this, ()| {
            this.with(|g| g.province_count())
        });
        // -- getNeighbors --
        /// Returns neighboring province ids for a province.
        /// @param | id | integer | Province id.
        /// @return | table | Array table of neighboring province ids.
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
        // -- setProvinceAttr --
        /// Sets a string attribute on a province.
        /// @param | id | integer | Province id.
        /// @param | key | string | Attribute key.
        /// @param | val | string | Attribute value.
        /// @return | boolean | True when the province exists.
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
        // -- getProvinceAttr --
        /// Reads a string attribute from a province.
        /// @param | id | integer | Province id.
        /// @param | key | string | Attribute key.
        /// @return | LuaValue | Attribute string, or nil when the province or key is missing.
        methods.add_method("getProvinceAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.get_province(id).and_then(|p| p.attrs.get(&key).cloned()))
        });
        // -- setProvinceTexture --
        /// Assigns a raw texture handle and UV rectangle to a province.
        /// @param | id | integer | Province id.
        /// @param | tex_raw | integer | Raw texture identifier stored in province attributes.
        /// @param | u0 | number | Left UV coordinate.
        /// @param | v0 | number | Top UV coordinate.
        /// @param | u1 | number | Right UV coordinate.
        /// @param | v1 | number | Bottom UV coordinate.
        /// @return | boolean | True when the province exists.
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
        // -- clearProvinceTexture --
        /// Removes texture metadata from a province.
        /// @param | id | integer | Province id.
        /// @return | boolean | True when the province exists.
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
        // -- setProvinceSector --
        /// Assigns a province to a named sector.
        /// @param | id | integer | Province id.
        /// @param | sector | string | Sector name.
        /// @return | boolean | True when the province sector was set.
        methods.add_method_mut(
            "setProvinceSector",
            |_, this, (id, sector): (u32, String)| {
                this.with_mut(|g| g.set_province_sector(id, sector))
            },
        );
        // -- getProvinceSector --
        /// Returns the sector name assigned to a province.
        /// @param | id | integer | Province id.
        /// @return | LuaValue | Sector string, or nil when absent.
        methods.add_method("getProvinceSector", |_, this, id: u32| {
            this.with(|g| g.province_sector(id).map(|s| s.to_string()))
        });
        // -- getSectorProvinces --
        /// Returns province ids assigned to a sector.
        /// @param | sector | string | Sector name.
        /// @return | table | Array table of province ids.
        methods.add_method("getSectorProvinces", |lua, this, sector: String| {
            let ids = this.with(|g| g.sector_provinces(&sector))?;
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(t)
        });
        // -- setHeatLayer --
        /// Creates or replaces a heat layer that maps province attributes into colors.
        /// @param | name | string | Heat layer name.
        /// @param | attr_key | string | Province attribute key read as a numeric value.
        /// @param | min | number | Attribute value mapped to cold color.
        /// @param | max | number | Attribute value mapped to hot color.
        /// @param | alpha | number | Layer alpha clamped to 0.0 through 1.0.
        /// @return | nil | No value is returned.
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
        // -- removeHeatLayer --
        /// Removes a heat layer by name.
        /// @param | name | string | Heat layer name.
        /// @return | boolean | True when a layer was removed.
        methods.add_method_mut("removeHeatLayer", |_, this, name: String| {
            this.with_mut(|g| g.remove_heat_layer(&name))
        });
        // -- pan --
        /// Pans the globe camera by latitude and longitude deltas.
        /// @param | dlat | number | Latitude delta in degrees.
        /// @param | dlon | number | Longitude delta in degrees.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pan", |_, this, (dlat, dlon): (f32, f32)| {
            this.with_mut(|g| g.camera.pan(dlat, dlon))
        });
        // -- zoom --
        /// Multiplies the globe camera zoom by a factor.
        /// @param | factor | number | Zoom factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("zoom", |_, this, factor: f32| {
            this.with_mut(|g| g.camera.zoom_by(factor))
        });
        // -- setCamera --
        /// Sets camera latitude, longitude, and zoom.
        /// @param | lat | number | Camera latitude in degrees.
        /// @param | lon | number | Camera longitude in degrees.
        /// @param | z | number | Camera zoom, clamped to at least 0.1.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCamera", |_, this, (lat, lon, z): (f32, f32, f32)| {
            this.with_mut(|g| {
                g.camera.lat_deg = lat;
                g.camera.lon_deg = lon;
                g.camera.zoom = z.max(0.1);
                g.camera.clamp();
            })
        });
        // -- getCamera --
        /// Returns camera latitude, longitude, and zoom.
        /// @return | number | Camera latitude in degrees.
        /// @return | number | Camera longitude in degrees.
        /// @return | number | Camera zoom.
        methods.add_method("getCamera", |_, this, ()| {
            this.with(|g| (g.camera.lat_deg, g.camera.lon_deg, g.camera.zoom))
        });
        // -- getLod --
        /// Returns the camera-derived level-of-detail tier name.
        /// @return | string | One of `far`, `mid`, or `near`.
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
        // -- pick --
        /// Picks a province at screen coordinates.
        /// @param | sx | number | Screen x coordinate.
        /// @param | sy | number | Screen y coordinate.
        /// @return | LuaValue | Province id, or nil when nothing is hit.
        methods.add_method("pick", |_, this, (sx, sy): (f32, f32)| {
            this.with(|g| g.pick_screen(sx, sy).map(|r| r.province_id))
        });
        // -- pickRaycast --
        /// Samples along a screen ray from the camera center and returns the first hit province.
        /// @param | sx | number | Target screen x coordinate.
        /// @param | sy | number | Target screen y coordinate.
        /// @param | steps | integer | Optional number of samples along the ray, defaulting to 24.
        /// @return | LuaValue | Province id, or nil when no sample hits.
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
        // -- pickLatLon --
        /// Picks at screen coordinates and returns the hit province centroid screen coordinates.
        /// @param | sx | number | Screen x coordinate.
        /// @param | sy | number | Screen y coordinate.
        /// @return | LuaValue | Centroid x coordinate, or nil when nothing is hit.
        /// @return | LuaValue | Centroid y coordinate, or nil when nothing is hit.
        methods.add_method("pickLatLon", |_lua, this, (sx, sy): (f32, f32)| {
            this.with(|g| match g.pick_screen(sx, sy) {
                Some(r) => (
                    Some(r.centroid_screen.x as f64),
                    Some(r.centroid_screen.y as f64),
                ),
                None => (None, None),
            })
        });
        // -- setActiveViewer --
        /// Sets the active fog-of-war viewer name or clears it.
        /// @param | viewer | string | Optional viewer name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setActiveViewer", |_, this, viewer: Option<String>| {
            this.with_mut(|g| g.active_viewer = viewer)
        });
        // -- setFogState --
        /// Sets fog-of-war state for one viewer and province.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province id.
        /// @param | state | string | `visible`, `explored`, or any other value for hidden.
        /// @return | nil | No value is returned.
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
        // -- getFogState --
        /// Returns fog-of-war state for one viewer and province.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province id.
        /// @return | string | `visible`, `explored`, or `hidden`.
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
        // -- encodeFogBase64 --
        /// Serializes one viewer's fog state to a base64 string.
        /// @param | viewer | string | Viewer name.
        /// @return | string | Base64-encoded fog state, or an empty string on encode failure.
        methods.add_method("encodeFogBase64", |_, this, viewer: String| {
            this.with(|g| g.fog.to_base64(&viewer).unwrap_or_default())
        });
        // -- decodeFogBase64 --
        /// Loads one viewer's fog state from a base64 string.
        /// @param | viewer | string | Viewer name.
        /// @param | payload | string | Base64-encoded fog state.
        /// @return | boolean | True when the payload was decoded.
        methods.add_method_mut(
            "decodeFogBase64",
            |_, this, (viewer, payload): (String, String)| {
                this.with_mut(|g| g.fog.load_base64(&viewer, &payload).is_ok())
            },
        );
        // -- revealProvince --
        /// Reveals a province for one fog-of-war viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("revealProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.reveal(&viewer, id))
        });
        // -- hideProvince --
        /// Hides a province for one fog-of-war viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("hideProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.hide(&viewer, id))
        });
        // -- isVisible --
        /// Returns whether a province is visible for one fog-of-war viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province id.
        /// @return | boolean | True when the province is visible.
        methods.add_method("isVisible", |_, this, (viewer, id): (String, u32)| {
            this.with(|g| g.fog.is_visible(&viewer, id))
        });
        // -- revealAll --
        /// Reveals every province for one fog-of-war viewer.
        /// @param | viewer | string | Viewer name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("revealAll", |_, this, viewer: String| {
            this.with_mut(|g| {
                let ids: Vec<u32> = g.graph.iter().map(|p| p.id).collect();
                for id in ids {
                    g.fog.reveal(&viewer, id);
                }
            })
        });
        // -- addMarker --
        /// Adds a marker at latitude and longitude with an optional label.
        /// @param | mtype | string | Marker type name.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @param | label | string | Optional marker label.
        /// @return | integer | New marker id.
        methods.add_method_mut(
            "addMarker",
            |_, this, (mtype, lat, lon, label): (String, f32, f32, Option<String>)| {
                this.with_mut(|g| {
                    g.markers
                        .add(mtype, lat, lon, label, MarkerStyle::default())
                })
            },
        );
        // -- removeMarker --
        /// Removes a marker by id.
        /// @param | id | integer | Marker id.
        /// @return | boolean | True when a marker was removed.
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            this.with_mut(|g| g.markers.remove(id).is_some())
        });
        // -- moveMarker --
        /// Moves a marker to latitude and longitude coordinates.
        /// @param | id | integer | Marker id.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @return | boolean | True when the marker exists.
        methods.add_method_mut("moveMarker", |_, this, (id, lat, lon): (u32, f32, f32)| {
            this.with_mut(|g| g.markers.move_to(id, lat, lon))
        });
        // -- setMarkerVisible --
        /// Shows or hides a marker.
        /// @param | id | integer | Marker id.
        /// @param | vis | boolean | New visibility flag.
        /// @return | boolean | True when the marker exists.
        methods.add_method_mut("setMarkerVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.markers.set_visible(id, vis))
        });
        // -- setMarkerPulse --
        /// Sets marker pulse frequency and amplitude.
        /// @param | id | integer | Marker id.
        /// @param | hz | number | Pulse frequency in hertz, clamped to at least zero.
        /// @param | amp | number | Pulse amplitude clamped to 0.0 through 1.0.
        /// @return | boolean | True when the marker exists.
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
        // -- setMarkerRotation --
        /// Sets marker rotation speed.
        /// @param | id | integer | Marker id.
        /// @param | dps | number | Rotation speed in degrees per second.
        /// @return | boolean | True when the marker exists.
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
        // -- setMarkerAttr --
        /// Sets a string attribute on a marker.
        /// @param | id | integer | Marker id.
        /// @param | key | string | Attribute key.
        /// @param | val | string | Attribute value.
        /// @return | boolean | True when the marker exists.
        methods.add_method_mut(
            "setMarkerAttr",
            |_, this, (id, key, val): (u32, String, String)| {
                this.with_mut(|g| g.markers.set_attr(id, key, val))
            },
        );
        // -- getMarkerAttr --
        /// Reads a string attribute from a marker.
        /// @param | id | integer | Marker id.
        /// @param | key | string | Attribute key.
        /// @return | LuaValue | Attribute string, or nil when missing.
        methods.add_method("getMarkerAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.markers.get_attr(id, &key).map(|s| s.to_owned()))
        });
        // -- addLabel --
        /// Adds a text label at latitude and longitude.
        /// @param | ltype | string | Label type name.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @param | text | string | Label text.
        /// @return | integer | New label id.
        methods.add_method_mut(
            "addLabel",
            |_, this, (ltype, lat, lon, text): (String, f32, f32, String)| {
                this.with_mut(|g| {
                    g.labels
                        .add(ltype, lat, lon, text, LabelStyle::default(), 0)
                })
            },
        );
        // -- setLabelText --
        /// Changes text for an existing label.
        /// @param | id | integer | Label id.
        /// @param | text | string | New label text.
        /// @return | boolean | True when the label exists.
        methods.add_method_mut("setLabelText", |_, this, (id, text): (u32, String)| {
            this.with_mut(|g| g.labels.set_text(id, text))
        });
        // -- setLabelVisible --
        /// Shows or hides a label.
        /// @param | id | integer | Label id.
        /// @param | vis | boolean | New visibility flag.
        /// @return | boolean | True when the label exists.
        methods.add_method_mut("setLabelVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.labels.set_visible(id, vis))
        });
        // -- removeLabel --
        /// Removes a label by id.
        /// @param | id | integer | Label id.
        /// @return | boolean | True when a label was removed.
        methods.add_method_mut("removeLabel", |_, this, id: u32| {
            this.with_mut(|g| g.labels.remove(id).is_some())
        });
        // -- addLayer --
        /// Adds a render layer with optional z-order.
        /// @param | name | string | Layer name.
        /// @param | z_order | integer | Optional layer z-order, defaulting to zero.
        /// @return | nil | No value is returned.
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
        // -- removeLayer --
        /// Removes a render layer by name.
        /// @param | name | string | Layer name.
        /// @return | boolean | True when a layer was removed.
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.with_mut(|g| g.layers.remove(&name).is_some())
        });
        // -- setLayerColor --
        /// Sets a province color override inside a render layer.
        /// @param | layer | string | Layer name.
        /// @param | id | integer | Province id.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Alpha channel.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut(
            "setLayerColor",
            |_, this, (layer, id, r, g, b, a): (String, u32, f32, f32, f32, f32)| {
                this.with_mut(|globe| globe.layers.set_province_color(&layer, id, [r, g, b, a]))
            },
        );
        // -- setLayerVisible --
        /// Shows or hides a render layer.
        /// @param | name | string | Layer name.
        /// @param | vis | boolean | New visibility flag.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut("setLayerVisible", |_, this, (name, vis): (String, bool)| {
            this.with_mut(|g| g.layers.set_visible(&name, vis))
        });
        // -- setLayerAlpha --
        /// Sets render layer alpha.
        /// @param | name | string | Layer name.
        /// @param | alpha | number | Layer alpha.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut("setLayerAlpha", |_, this, (name, alpha): (String, f32)| {
            this.with_mut(|g| g.layers.set_alpha(&name, alpha))
        });
        // -- setTimeOfDay --
        /// Sets globe time of day modulo 24 hours.
        /// @param | t | number | Time of day in hours.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTimeOfDay", |_, this, t: f32| {
            this.with_mut(|g| g.spec.time_of_day = t % 24.0)
        });
        // -- getTimeOfDay --
        /// Returns globe time of day.
        /// @return | number | Time of day in hours.
        methods.add_method("getTimeOfDay", |_, this, ()| {
            this.with(|g| g.spec.time_of_day)
        });
        // -- setRotation --
        /// Sets globe rotation angle.
        /// @param | deg | number | Rotation in degrees.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setRotation", |_, this, deg: f32| {
            this.with_mut(|g| g.spec.rotation_deg = deg)
        });
        // -- setAutoRotationSpeed --
        /// Sets automatic globe rotation speed.
        /// @param | dps | number | Rotation speed in degrees per second.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setAutoRotationSpeed", |_, this, dps: f32| {
            this.with_mut(|g| g.spec.auto_rotation_deg_per_sec = dps)
        });
        // -- update --
        /// Advances globe simulation timers and animated state.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| this.with_mut(|g| g.update(dt)));
        // -- setBorders --
        /// Enables or disables province border rendering.
        /// @param | show | boolean | New border visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setBorders", |_, this, show: bool| {
            this.with_mut(|g| g.spec.render_borders = show)
        });
        // -- findPath --
        /// Finds a default-cost province path between two province ids.
        /// @param | from_id | integer | Start province id.
        /// @param | to_id | integer | Target province id.
        /// @return | LuaValue | Array table of province ids, or nil when no path exists.
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
        // -- reachable --
        /// Returns provinces reachable from a start province within a cost budget.
        /// @param | start_id | integer | Start province id.
        /// @param | max_cost | number | Maximum traversal cost.
        /// @return | table | Map table from province id to accumulated cost.
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
        // -- cacheReachability --
        /// Caches default-cost reachability for a named faction.
        /// @param | faction | string | Faction cache key.
        /// @param | start_id | integer | Start province id.
        /// @param | max_cost | number | Maximum traversal cost.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "cacheReachability",
            |_, this, (faction, start_id, max_cost): (String, u32, f64)| {
                this.with_mut(|g| g.cache_reachability_default(faction, start_id, max_cost))
            },
        );
        // -- getCachedReachability --
        /// Returns cached reachability costs for a faction.
        /// @param | faction | string | Faction cache key.
        /// @return | table | Map table from province id to accumulated cost, empty when missing.
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
        // -- exportProvinceMeshOBJ --
        /// Exports province geometry as Wavefront OBJ text.
        /// @return | string | OBJ mesh text for the current provinces.
        methods.add_method("exportProvinceMeshOBJ", |_, this, ()| {
            this.with(export_provinces_to_obj)
        });
        // -- addArc --
        /// Adds a visible route arc between two latitude and longitude points.
        /// @param | lat1 | number | Start latitude in degrees.
        /// @param | lon1 | number | Start longitude in degrees.
        /// @param | lat2 | number | End latitude in degrees.
        /// @param | lon2 | number | End longitude in degrees.
        /// @param | steps | integer | Optional point count for the arc, defaulting to 24.
        /// @return | integer | New arc id.
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
        // -- removeArc --
        /// Removes an arc by id.
        /// @param | id | integer | Arc id.
        /// @return | boolean | True when an arc was removed.
        methods.add_method_mut("removeArc", |_, this, id: u32| {
            this.with_mut(|g| g.remove_arc(id))
        });
        // -- getName --
        /// Returns the registry name of this globe.
        /// @return | string | Globe registry name.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Globe(\"{}\")", this.name))
        });
        // -- type --
        /// Returns the Lua-visible type name for this globe handle.
        /// @return | string | The string `LGlobe`.
        methods.add_method("type", |_, _, ()| Ok("LGlobe"));
        // -- typeOf --
        /// Returns whether this globe handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGlobe` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobe" || name == "Object")
        });
    }
}
#[derive(Clone)]
/// Lua-side handle for creating and locating named globes in one registry.
pub struct LuaGlobeRegistry {
    /// Shared registry containing named globe instances.
    reg: Arc<Mutex<GlobeRegistry>>,
    /// Shared runtime state propagated into globe handles.
    state: Rc<RefCell<SharedState>>,
}
/// Provides Lua methods for managing globe registry entries.
impl LuaUserData for LuaGlobeRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- new --
        /// Creates a named globe with optional specification fields.
        /// @param | name | string | Globe registry name.
        /// @param | spec_tbl | table | Optional globe specification table.
        /// @return | LGlobe | New globe handle.
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
        // -- get --
        /// Returns a globe handle by registry name.
        /// @param | name | string | Globe registry name.
        /// @return | LuaValue | `LGlobe` handle, or nil when no globe exists with that name.
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
        // -- remove --
        /// Removes a globe from the registry by name.
        /// @param | name | string | Globe registry name.
        /// @return | boolean | True when a globe was removed.
        methods.add_method_mut("remove", |_, this, name: String| {
            let mut guard = this
                .reg
                .lock()
                .map_err(|e| mlua::Error::RuntimeError(format!("registry lock poisoned: {e}")))?;
            Ok(guard.remove(&name).is_some())
        });
        // -- names --
        /// Returns all globe names currently stored in this registry.
        /// @return | table | Array table of globe names.
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
        // -- type --
        /// Returns the Lua-visible type name for this globe registry handle.
        /// @return | string | The string `LGlobeRegistry`.
        methods.add_method("type", |_, _, ()| Ok("LGlobeRegistry"));
        // -- typeOf --
        /// Returns whether this registry handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGlobeRegistry` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobeRegistry" || name == "Object")
        });
    }
}
/// Parses optional Lua table fields into a globe specification.
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
/// Registers `lurek.globe` constructors, geometry helpers, and constants.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let registry = Arc::new(Mutex::new(GlobeRegistry::new()));
    {
        let reg = registry.clone();
        let s = state.clone();
        // -- new --
        /// Creates a named globe with optional specification fields in the module registry.
        /// @param | name | string | Globe registry name.
        /// @param | spec_tbl | table | Optional globe specification table.
        /// @return | LGlobe | New globe handle.
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
        // -- get --
        /// Returns a globe from the module registry by name.
        /// @param | name | string | Globe registry name.
        /// @return | LuaValue | `LGlobe` handle, or nil when no globe exists with that name.
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
        // -- loadFromTOML --
        /// Creates a globe and populates provinces from TOML source text.
        /// @param | name | string | Globe registry name.
        /// @param | toml_src | string | TOML province document source.
        /// @param | spec_tbl | table | Optional globe specification table.
        /// @return | LGlobe | New populated globe handle.
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
        // -- loadFromPNG --
        /// Creates a globe and populates provinces from a PNG file.
        /// @param | name | string | Globe registry name.
        /// @param | png_path | string | PNG file path to load.
        /// @param | spec_tbl | table | Optional globe specification table.
        /// @return | LGlobe | New populated globe handle.
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
        // -- generateVoronoi --
        /// Creates a globe and populates provinces from latitude-longitude seed points.
        /// @param | name | string | Globe registry name.
        /// @param | seeds_tbl | table | Array table of `{lat, lon}` seed pairs.
        /// @param | spec_tbl | table | Optional globe specification table.
        /// @return | LGlobe | New generated globe handle.
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
    // -- greatCircleDistance --
    /// Computes great-circle distance between two latitude-longitude points.
    /// @param | la | number | Start latitude in degrees.
    /// @param | lo | number | Start longitude in degrees.
    /// @param | lb | number | End latitude in degrees.
    /// @param | lo2 | number | End longitude in degrees.
    /// @return | number | Great-circle distance on the unit sphere.
    tbl.set(
        "greatCircleDistance",
        lua.create_function(|_, (la, lo, lb, lo2): (f32, f32, f32, f32)| {
            Ok(great_circle_distance(la, lo, lb, lo2))
        })?,
    )?;
    // -- greatCirclePath --
    /// Computes sampled latitude-longitude points along a great-circle path.
    /// @param | la | number | Start latitude in degrees.
    /// @param | lo | number | Start longitude in degrees.
    /// @param | lb | number | End latitude in degrees.
    /// @param | lo2 | number | End longitude in degrees.
    /// @param | n | integer | Number of samples.
    /// @return | table | Array table of `{lat, lon}` point tables.
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
    // -- latLonToUnit --
    /// Converts latitude and longitude to a unit-sphere 3D vector table.
    /// @param | lat | number | Latitude in degrees.
    /// @param | lon | number | Longitude in degrees.
    /// @return | table | Array table `{x, y, z}` on the unit sphere.
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
