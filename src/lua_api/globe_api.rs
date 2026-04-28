//! `lurek.globe` - Geoscape globe simulation, province data, and world map helpers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

use crate::globe::loader;
use crate::globe::registry::{Globe, GlobeRegistry};
use crate::globe::types::{
    GlobeSpec, LabelStyle, Layer, LodTier, MarkerStyle, Province,
    MAX_PROVINCES,
};
use crate::math::sphere::{
    great_circle_distance, great_circle_path, lat_lon_to_unit,
};

// ── LuaGlobe ────────────────────────────────────────────────────────────────

/// Lua-accessible handle to a `Globe` inside a `GlobeRegistry`.
///
/// Internally holds `Arc<Mutex<GlobeRegistry>>` and the name of the globe.
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
        // ── Province management ──────────────────────────────────────────────

        // -- addProvince --
        /// Adds a province from a table with id, centroid, vertices, neighbors, and base_color fields.
        /// @param | p | table | Province definition table.
        /// @return | boolean | True when the province was added.
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
        /// Removes a province by ID. Returns true if it existed.
        /// @param | id | integer | Province ID to remove.
        /// @return | boolean | True when the province existed.
        methods.add_method_mut("removeProvince", |_, this, id: u32| {
            this.with_mut(|g| g.remove_province(id).is_some())
        });

        // -- provinceCount --
        /// Returns the number of provinces.
        /// @return | integer | Number of provinces.
        methods.add_method("provinceCount", |_, this, ()| {
            this.with(|g| g.province_count())
        });

        // -- getNeighbors --
        /// Returns the neighbor IDs of a province.
        /// @param | id | integer | Province ID to inspect.
        /// @return | table | Array of neighbor province IDs.
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
        /// @param | id | integer | Province ID to update.
        /// @param | key | string | Attribute name.
        /// @param | value | string | Attribute value.
        /// @return | boolean | True when the province exists.
        methods.add_method_mut("setProvinceAttr", |_, this, (id, key, val): (u32, String, String)| {
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
        /// Gets a string attribute from a province.
        /// @param | id | integer | Province ID to inspect.
        /// @param | key | string | Attribute name.
        /// @return | string | Attribute value when present.
        methods.add_method("getProvinceAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.get_province(id).and_then(|p| p.attrs.get(&key).cloned()))
        });

        // ── Camera ──────────────────────────────────────────────────────────

        // -- pan --
        /// Pan the orbit camera by delta-latitude and delta-longitude (degrees).
        /// @param | dlat | number | Latitude delta in degrees.
        /// @param | dlon | number | Longitude delta in degrees.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pan", |_, this, (dlat, dlon): (f32, f32)| {
            this.with_mut(|g| g.camera.pan(dlat, dlon))
        });

        // -- zoom --
        /// Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
        /// @param | factor | number | Zoom multiplier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("zoom", |_, this, factor: f32| {
            this.with_mut(|g| g.camera.zoom_by(factor))
        });

        // -- setCamera --
        /// Set the camera position directly.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @param | zoom | number | Zoom factor.
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
        /// Get the current camera (lat, lon, zoom).
        /// @return | number | Camera latitude in degrees.
        /// @return | number | Camera longitude in degrees.
        /// @return | number | Camera zoom level.
        methods.add_method("getCamera", |_, this, ()| {
            this.with(|g| (g.camera.lat_deg, g.camera.lon_deg, g.camera.zoom))
        });

        // -- getLod --
        /// Returns the current LOD tier as a string: "far", "mid", or "near".
        /// @return | string | Current LOD tier.
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

        // ── Picking ─────────────────────────────────────────────────────────

        // -- pick --
        /// Returns the province ID under screen coordinates, or nil.
        /// @param | sx | number | Screen x coordinate.
        /// @param | sy | number | Screen y coordinate.
        /// @return | integer | Picked province ID when one is found.
        methods.add_method("pick", |_, this, (sx, sy): (f32, f32)| {
            this.with(|g| g.pick_screen(sx, sy).map(|r| r.province_id))
        });

        // -- pickLatLon --
        /// Returns (lat, lon) of the screen point on the globe surface, or nil.
        /// @param | sx | number | Screen x coordinate.
        /// @param | sy | number | Screen y coordinate.
        /// @return | number | Picked latitude in degrees.
        /// @return | number | Picked longitude in degrees.
        methods.add_method("pickLatLon", |_lua, this, (sx, sy): (f32, f32)| {
            this.with(|g| match g.pick_screen(sx, sy) {
                Some(r) => (
                    Some(r.centroid_screen.x as f64),
                    Some(r.centroid_screen.y as f64),
                ),
                None => (None, None),
            })
        });

        // ── Fog of war ───────────────────────────────────────────────────────

        // -- setActiveViewer --
        /// Set the faction/viewer whose fog mask filters rendering.
        /// @param | viewer | string? | Viewer name, or nil to clear it.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setActiveViewer", |_, this, viewer: Option<String>| {
            this.with_mut(|g| g.active_viewer = viewer)
        });

        // -- revealProvince --
        /// Reveal a province for a viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province ID to reveal.
        /// @return | nil | No value is returned.
        methods.add_method_mut("revealProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.reveal(&viewer, id))
        });

        // -- hideProvince --
        /// Hide a province for a viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province ID to hide.
        /// @return | nil | No value is returned.
        methods.add_method_mut("hideProvince", |_, this, (viewer, id): (String, u32)| {
            this.with_mut(|g| g.fog.hide(&viewer, id))
        });

        // -- isVisible --
        /// Returns true if the province is visible to the viewer.
        /// @param | viewer | string | Viewer name.
        /// @param | id | integer | Province ID to test.
        /// @return | boolean | True when the province is visible.
        methods.add_method("isVisible", |_, this, (viewer, id): (String, u32)| {
            this.with(|g| g.fog.is_visible(&viewer, id))
        });

        // -- revealAll --
        /// Reveal all provinces for a viewer.
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

        // ── Markers ──────────────────────────────────────────────────────────

        // -- addMarker --
        /// Add a marker. Returns marker ID.
        /// @param | mtype | string | Marker type name.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @param | label | string? | Optional label text.
        /// @return | integer | Marker ID.
        methods.add_method_mut("addMarker", |_, this, (mtype, lat, lon, label): (String, f32, f32, Option<String>)| {
                this.with_mut(|g| {
                    g.markers
                        .add(mtype, lat, lon, label, MarkerStyle::default())
                })
            },
        );

        // -- removeMarker --
        /// Removes a marker from the globe map by its unique string identifier.
        /// @param | id | integer | Marker ID to remove.
        /// @return | boolean | True when the marker existed.
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            this.with_mut(|g| g.markers.remove(id).is_some())
        });

        // -- moveMarker --
        /// Move a marker to a new lat/lon.
        /// @param | id | integer | Marker ID to move.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @return | nil | No value is returned.
        methods.add_method_mut("moveMarker", |_, this, (id, lat, lon): (u32, f32, f32)| {
            this.with_mut(|g| g.markers.move_to(id, lat, lon))
        });

        // -- setMarkerVisible --
        /// Sets whether this specific marker is visible on the globe.
        /// @param | id | integer | Marker ID to update.
        /// @param | visible | boolean | Visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMarkerVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.markers.set_visible(id, vis))
        });

        // -- setMarkerAttr --
        /// Set a string attribute on a marker.
        /// @param | id | integer | Marker ID to update.
        /// @param | key | string | Attribute name.
        /// @param | value | string | Attribute value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMarkerAttr", |_, this, (id, key, val): (u32, String, String)| {
                this.with_mut(|g| g.markers.set_attr(id, key, val))
            },
        );

        // -- getMarkerAttr --
        /// Get a string attribute from a marker.
        /// @param | id | integer | Marker ID to inspect.
        /// @param | key | string | Attribute name.
        /// @return | string | Attribute value when present.
        methods.add_method("getMarkerAttr", |_, this, (id, key): (u32, String)| {
            this.with(|g| g.markers.get_attr(id, &key).map(|s| s.to_owned()))
        });

        // ── Labels ───────────────────────────────────────────────────────────

        // -- addLabel --
        /// Add a text label. Returns label ID.
        /// @param | ltype | string | Label type name.
        /// @param | lat | number | Latitude in degrees.
        /// @param | lon | number | Longitude in degrees.
        /// @param | text | string | Label text.
        /// @return | integer | Label ID.
        methods.add_method_mut("addLabel", |_, this, (ltype, lat, lon, text): (String, f32, f32, String)| {
                this.with_mut(|g| {
                    g.labels
                        .add(ltype, lat, lon, text, LabelStyle::default(), 0)
                })
            },
        );

        // -- setLabelText --
        /// Updates the visible text content of an existing globe label.
        /// @param | id | integer | Label ID to update.
        /// @param | text | string | New label text.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLabelText", |_, this, (id, text): (u32, String)| {
            this.with_mut(|g| g.labels.set_text(id, text))
        });

        // -- setLabelVisible --
        /// Sets whether this specific label is visible on the globe.
        /// @param | id | integer | Label ID to update.
        /// @param | visible | boolean | Visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLabelVisible", |_, this, (id, vis): (u32, bool)| {
            this.with_mut(|g| g.labels.set_visible(id, vis))
        });

        // -- removeLabel --
        /// Removes a text label from the globe map by its unique string identifier.
        /// @param | id | integer | Label ID to remove.
        /// @return | boolean | True when the label existed.
        methods.add_method_mut("removeLabel", |_, this, id: u32| {
            this.with_mut(|g| g.labels.remove(id).is_some())
        });

        // ── Layers ───────────────────────────────────────────────────────────

        // -- addLayer --
        /// Add or replace a named thematic layer.
        /// @param | name | string | Layer name.
        /// @param | z_order | integer? | Optional layer draw order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addLayer", |_, this, (name, z_order): (String, Option<i32>)| {
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
        /// Removes a texture layer from the globe map by its unique string identifier.
        /// @param | name | string | Layer name to remove.
        /// @return | boolean | True when the layer existed.
        methods.add_method_mut("removeLayer", |_, this, name: String| {
            this.with_mut(|g| g.layers.remove(&name).is_some())
        });

        // -- setLayerColor --
        /// Set a per-province color override on a layer.
        /// @param | layer | string | Layer name.
        /// @param | province_id | integer | Province ID to recolor.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Alpha channel.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayerColor", |_, this, (layer, id, r, g, b, a): (String, u32, f32, f32, f32, f32)| {
                this.with_mut(|globe| globe.layers.set_province_color(&layer, id, [r, g, b, a]))
            },
        );

        // -- setLayerVisible --
        /// Sets whether this specific texture layer is visible on the globe.
        /// @param | name | string | Layer name.
        /// @param | visible | boolean | Visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayerVisible", |_, this, (name, vis): (String, bool)| {
            this.with_mut(|g| g.layers.set_visible(&name, vis))
        });

        // -- setLayerAlpha --
        /// Set layer opacity (0.0–1.0).
        /// @param | name | string | Layer name.
        /// @param | alpha | number | Opacity value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayerAlpha", |_, this, (name, alpha): (String, f32)| {
            this.with_mut(|g| g.layers.set_alpha(&name, alpha))
        });

        // ── Spec / time ──────────────────────────────────────────────────────

        // -- setTimeOfDay --
        /// Set time of day (0.0–24.0 hours).
        /// @param | t | number | Time of day in hours.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTimeOfDay", |_, this, t: f32| {
            this.with_mut(|g| g.spec.time_of_day = t % 24.0)
        });

        // -- getTimeOfDay --
        /// Gets the current simulated time of day for daylight computation.
        /// @return | number | Current time of day in hours.
        methods.add_method("getTimeOfDay", |_, this, ()| {
            this.with(|g| g.spec.time_of_day)
        });

        // -- setRotation --
        /// Set planet rotation (degrees).
        /// @param | deg | number | Rotation in degrees.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setRotation", |_, this, deg: f32| {
            this.with_mut(|g| g.spec.rotation_deg = deg)
        });

        // -- update --
        /// Advance globe simulation by dt seconds.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| this.with_mut(|g| g.update(dt)));

        // -- setBorders --
        /// Enable or disable province border rendering.
        /// @param | show | boolean | Border visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setBorders", |_, this, show: bool| {
            this.with_mut(|g| g.spec.render_borders = show)
        });

        // ── Path finding ─────────────────────────────────────────────────────

        // -- findPath --
        /// Find the shortest province path from `from_id` to `to_id`.
        /// @param | from_id | integer | Starting province ID.
        /// @param | to_id | integer | Target province ID.
        /// @return | table | Array of province IDs for the path.
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
        /// Return all provinces reachable within `max_cost` steps from `start_id`.
        /// @param | start_id | integer | Starting province ID.
        /// @param | max_cost | number | Maximum traversal cost.
        /// @return | table | Table mapping province IDs to reach costs.
        methods.add_method("reachable", |lua, this, (start_id, max_cost): (u32, f64)| {
                let reached = this.with(|g| g.graph.reachable_default(start_id, max_cost))?;
                let t = lua.create_table()?;
                for (id, cost) in reached {
                    t.set(id, cost)?;
                }
                Ok(t)
            },
        );

        // ── Arc management ──────────────────────────────────────────────────

        // -- addArc --
        /// Add an arc (great-circle path between two lat/lon points).
        /// @param | lat1 | number | Start latitude in degrees.
        /// @param | lon1 | number | Start longitude in degrees.
        /// @param | lat2 | number | End latitude in degrees.
        /// @param | lon2 | number | End longitude in degrees.
        /// @param | steps | integer? | Optional point count for the arc.
        /// @return | integer | Arc ID.
        methods.add_method_mut("addArc", |_, this, (lat1, lon1, lat2, lon2, steps): (f32, f32, f32, f32, Option<u32>)| {
                let steps = steps.unwrap_or(24);
                this.with_mut(|g| {
                    let arc_id = g.arc_next_id;
                    g.arc_next_id += 1;
                    let arc = crate::globe::types::Arc {
                        id: arc_id,
                        arc_type: "route".to_string(),
                        screen_points: Vec::new(), // will be computed at draw time
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
        /// Removes an arc from the globe map by its unique string identifier.
        /// @param | id | integer | Arc ID to remove.
        /// @return | boolean | True when the arc existed.
        methods.add_method_mut("removeArc", |_, this, id: u32| {
            this.with_mut(|g| g.remove_arc(id))
        });

        // -- getName --
        /// Returns the string identifier name assigned to this globe instance.
        /// @return | string | Globe name.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        // -- __tostring --
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Globe(\"{}\")", this.name))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name.
        methods.add_method("type", |_, _, ()| Ok("LGlobe"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobe" || name == "Object")
        });
    }
}

// ── LuaGlobeRegistry ────────────────────────────────────────────────────────

/// Lua-accessible handle to the shared `GlobeRegistry`.
#[derive(Clone)]
pub struct LuaGlobeRegistry {
    reg: Arc<Mutex<GlobeRegistry>>,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaGlobeRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- new --
        /// Create a globe with the given name and optional spec table.
        /// @param | name | string | Globe name.
        /// @param | spec | table? | Optional globe specification table.
        /// @return | LGlobe | New globe instance.
        methods.add_method_mut("new", |_, this, (name, spec_tbl): (String, Option<LuaTable>)| {
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
        /// Get an existing globe by name, or nil.
        /// @param | name | string | Globe name.
        /// @return | LGlobe | Existing globe instance when found.
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
        /// Removes a globe from the central registry by its string name.
        /// @param | name | string | Globe name to remove.
        /// @return | boolean | True when the globe existed.
        methods.add_method_mut("remove", |_, this, name: String| {
            let mut guard = this
                .reg
                .lock()
                .map_err(|e| mlua::Error::RuntimeError(format!("registry lock poisoned: {e}")))?;
            Ok(guard.remove(&name).is_some())
        });

        // -- names --
        /// Returns a table of all globe names.
        /// @return | table | Array of globe names.
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
        /// Returns the type name of this object.
        /// @return | string | Type name.
        methods.add_method("type", |_, _, ()| Ok("LGlobeRegistry"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGlobeRegistry" || name == "Object")
        });
    }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

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
    }
    spec
}

// ── register ─────────────────────────────────────────────────────────────────

/// Register `lurek.globe` into the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let registry = Arc::new(Mutex::new(GlobeRegistry::new()));

    // -- new --
    {
        let reg = registry.clone();
        let s = state.clone();
        /// Creates a new globe instance with default settings and empty collections.
        /// @param | name | string | Globe name.
        /// @param | spec | table? | Optional globe specification table.
        /// @return | LGlobe | New globe instance.
        tbl.set("new", lua.create_function(move |_, (name, spec_tbl): (String, Option<LuaTable>)| {
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

    // -- get --
    {
        let reg = registry.clone();
        let s = state.clone();
        /// Get an existing globe by name, or nil.
        /// @param | name | string | Globe name.
        /// @return | LGlobe | Existing globe instance when found.
        tbl.set("get", lua.create_function(move |_, name: String| {
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

    // -- loadFromTOML --
    {
        let reg = registry.clone();
        let s = state.clone();
        /// Load provinces from a TOML string and create a globe.
        /// @param | name | string | Globe name.
        /// @param | toml_src | string | TOML source string.
        /// @param | spec | table? | Optional globe specification table.
        /// @return | LGlobe | Loaded globe instance.
        tbl.set("loadFromTOML", lua.create_function(
                move |_, (name, toml_src, spec_tbl): (String, String, Option<LuaTable>)| {
                    let spec = parse_globe_spec(spec_tbl);
                    let provinces = loader::load_from_toml_str(&toml_src)
                        .map_err(mlua::Error::RuntimeError)?;
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
    /// Great-circle distance between two lat/lon points (in unit-sphere radians).
    /// @param | lat1 | number | Start latitude in degrees.
    /// @param | lon1 | number | Start longitude in degrees.
    /// @param | lat2 | number | End latitude in degrees.
    /// @param | lon2 | number | End longitude in degrees.
    /// @return | number | Great-circle distance in radians.
    tbl.set("greatCircleDistance", lua.create_function(|_, (la, lo, lb, lo2): (f32, f32, f32, f32)| {
            Ok(great_circle_distance(la, lo, lb, lo2))
        })?,
    )?;

    // -- greatCirclePath --
    /// Great-circle path as a table of {lat, lon} pairs.
    /// @param | lat1 | number | Start latitude in degrees.
    /// @param | lon1 | number | Start longitude in degrees.
    /// @param | lat2 | number | End latitude in degrees.
    /// @param | lon2 | number | End longitude in degrees.
    /// @param | steps | integer | Number of interpolation steps.
    /// @return | table | Array of latitude and longitude pairs.
    tbl.set("greatCirclePath", lua.create_function(|lua, (la, lo, lb, lo2, n): (f32, f32, f32, f32, u32)| {
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
    /// Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.
    /// @param | lat | number | Latitude in degrees.
    /// @param | lon | number | Longitude in degrees.
    /// @return | table | Cartesian vector table with x, y, and z values.
    tbl.set("latLonToUnit", lua.create_function(|lua, (lat, lon): (f32, f32)| {
            let v = lat_lon_to_unit(lat, lon);
            let t = lua.create_table()?;
            t.set(1, v.x)?;
            t.set(2, v.y)?;
            t.set(3, v.z)?;
            Ok(t)
        })?,
    )?;

    // -- globe.MAX_PROVINCES --
    tbl.set("MAX_PROVINCES", MAX_PROVINCES as u32)?;

    // -- globe.LOD_FAR / LOD_MID / LOD_NEAR (convenience constants) --
    /// LOD_FAR: string constant `"far"` — zoomed-out detail tier (zoom < 1.5).
    tbl.set("LOD_FAR", "far")?;
    /// LOD_MID: string constant `"mid"` — medium detail tier (1.5 ≤ zoom < 4.0).
    tbl.set("LOD_MID", "mid")?;
    /// LOD_NEAR: string constant `"near"` — high detail, close-zoom tier (zoom ≥ 4.0).
    tbl.set("LOD_NEAR", "near")?;

    luna.set("globe", tbl)?;
    Ok(())
}
