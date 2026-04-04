//! Registers the `luna.province.*` province map API.
//!
//! Exposes `LuaProvinceMap` UserData wrapping `crate::province::ProvinceMap`
//! with full province query, map mode, fog of war, pathfinding, movement,
//! properties, objects, and world generation support.
//!
//! All game-specific data (terrain, owner, region, etc.) is managed through
//! the generic property system — the engine imposes no fixed schema.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::province::adjacency::{detect_adjacency, detect_adjacency_with_tags};
use crate::province::borders::{
    extract_all_borders, extract_borders_by_property, extract_borders_with_tag, BorderStyle,
};
use crate::province::core::{ProvinceError, ProvinceMap};
use crate::province::fog::{FogOfWar, FogState};
use crate::province::map_mode::{resolve_colors, MapMode, MapModeColorFn};
use crate::province::minimap::ProvinceMinimap;
use crate::province::movement::MovementManager;
use crate::province::objects::ObjectManager;
use crate::province::pathfinding::ProvinceCostFn;
use crate::province::positions::{calculate_all_positions, calculate_label_position, calculate_slots};
use crate::province::properties::{ProvinceData, ProvinceProperties, ProvinceState, ProvinceValue};
use crate::province::worldgen::{generate_world, WorldGenConfig};

use crate::math::Vec2;
use crate::province::events::ProvinceEventBus;
use crate::province::organization::OrganizationManager;
use crate::province::relations::RelationManager;

// ---------------------------------------------------------------------------
// Wrapper types
// ---------------------------------------------------------------------------

/// Lua wrapper around a province map and its associated subsystems.
#[derive(Clone)]
struct LuaProvinceMap {
    /// The province map.
    inner: Rc<RefCell<ProvinceMap>>,
    /// Fog of war state.
    fog: Rc<RefCell<FogOfWar>>,
    /// Named map modes.
    map_modes: Rc<RefCell<HashMap<String, MapMode>>>,
    /// Active map mode name.
    active_mode: Rc<RefCell<Option<String>>>,
    /// Province custom data (properties + states).
    data: Rc<RefCell<ProvinceData>>,
    /// Object and improvement manager.
    objects: Rc<RefCell<ObjectManager>>,
    /// Movement manager for moving units.
    movement: Rc<RefCell<MovementManager>>,
    /// Cached RGBA pixel buffer for current map mode (width*height*4 bytes).
    color_buffer: Rc<RefCell<Vec<u8>>>,
    /// Border styles keyed by type name.
    border_styles: Rc<RefCell<HashMap<String, BorderStyle>>>,
    /// Organization manager: physical and virtual entities controlling provinces.
    orgs: Rc<RefCell<OrganizationManager>>,
    /// Configurable relation system between organizations.
    relations: Rc<RefCell<RelationManager>>,
    /// Province event bus for lifecycle events.
    events: Rc<RefCell<ProvinceEventBus>>,
    /// Lua event handlers keyed by event type name.
    event_handlers: Rc<RefCell<HashMap<String, Vec<LuaRegistryKey>>>>,
    /// Named Lua procedures for province-scoped callbacks.
    lua_procedures: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

// ---------------------------------------------------------------------------
// LunaType impls
// ---------------------------------------------------------------------------

impl LunaType for LuaProvinceMap {
    const TYPE_NAME: &'static str = "ProvinceMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ProvinceMap", "Object"];
}

// ---------------------------------------------------------------------------
// Helper: convert ProvinceError to LuaError
// ---------------------------------------------------------------------------

fn prov_err(e: ProvinceError) -> LuaError {
    LuaError::external(e)
}

/// Convert a Lua value to ProvinceValue.
fn lua_to_province_value(val: &LuaValue) -> LuaResult<ProvinceValue> {
    match val {
        LuaValue::Integer(n) => Ok(ProvinceValue::Int(*n)),
        LuaValue::Number(n) => Ok(ProvinceValue::Float(*n)),
        LuaValue::String(s) => Ok(ProvinceValue::Str(s.to_str()?.to_string())),
        LuaValue::Boolean(b) => Ok(ProvinceValue::Bool(*b)),
        _ => Err(LuaError::external("Province property value must be int, float, string, or bool")),
    }
}

/// Convert a ProvinceValue to a Lua value.
fn province_value_to_lua<'lua>(lua: &'lua Lua, val: &ProvinceValue) -> LuaResult<LuaValue<'lua>> {
    match val {
        ProvinceValue::Int(n) => Ok(LuaValue::Integer(*n)),
        ProvinceValue::Float(n) => Ok(LuaValue::Number(*n)),
        ProvinceValue::Str(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        ProvinceValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
    }
}

/// Build a ProvinceProperties lookup from ProvinceData.
fn build_properties_map(data: &ProvinceData, ids: &[u32]) -> HashMap<u32, ProvinceProperties> {
    let mut props_map = HashMap::new();
    for &id in ids {
        if let Some(p) = data.get_properties(id) {
            props_map.insert(id, p.clone());
        }
    }
    props_map
}

/// Rebuild the cached colour buffer from the active map mode.
fn rebuild_color_buffer(map: &LuaProvinceMap) {
    let inner = map.inner.borrow();
    let modes = map.map_modes.borrow();
    let active = map.active_mode.borrow();
    let data = map.data.borrow();

    let ids = inner.province_ids();
    let props_map = build_properties_map(&data, &ids);

    let buffer = match active.as_ref().and_then(|name| modes.get(name)) {
        Some(m) => resolve_colors(&inner, m, &props_map),
        None => {
            let default_mode = MapMode {
                name: "default".to_string(),
                color_fn: MapModeColorFn::SourceColor,
            };
            resolve_colors(&inner, &default_mode, &props_map)
        }
    };

    *map.color_buffer.borrow_mut() = buffer;
}

/// Create a new LuaProvinceMap wrapper from a ProvinceMap.
fn wrap_map(map: ProvinceMap) -> LuaProvinceMap {
    LuaProvinceMap {
        inner: Rc::new(RefCell::new(map)),
        fog: Rc::new(RefCell::new(FogOfWar::new())),
        map_modes: Rc::new(RefCell::new(HashMap::new())),
        active_mode: Rc::new(RefCell::new(None)),
        data: Rc::new(RefCell::new(ProvinceData::new())),
        objects: Rc::new(RefCell::new(ObjectManager::new())),
        movement: Rc::new(RefCell::new(MovementManager::new())),
        color_buffer: Rc::new(RefCell::new(Vec::new())),
        border_styles: Rc::new(RefCell::new(HashMap::new())),
        orgs: Rc::new(RefCell::new(OrganizationManager::new())),
        relations: Rc::new(RefCell::new(RelationManager::new())),
        events: Rc::new(RefCell::new(ProvinceEventBus::new())),
        event_handlers: Rc::new(RefCell::new(HashMap::new())),
        lua_procedures: Rc::new(RefCell::new(HashMap::new())),
    }
}

// ---------------------------------------------------------------------------
// UserData implementation
// ---------------------------------------------------------------------------

impl LuaUserData for LuaProvinceMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ---- Query methods ----

        // Get map width in pixels.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width())
        });

        // Get map height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height())
        });

        // Get province count.
        methods.add_method("getProvinceCount", |_, this, ()| {
            Ok(this.inner.borrow().province_count())
        });

        // Get all province IDs as a Lua array.
        methods.add_method("getProvinces", |_, this, ()| {
            Ok(this.inner.borrow().province_ids())
        });

        // Get province info as a table: {id, color, area, centroid, bounding_box, positions}.
        methods.add_method("getProvince", |lua, this, id: u32| {
            let inner = this.inner.borrow();
            let prov = inner
                .get_province(id)
                .ok_or_else(|| prov_err(ProvinceError::NotFound(id)))?;

            let t = lua.create_table()?;
            t.set("id", prov.id)?;
            t.set("area", prov.area)?;

            let color = lua.create_table()?;
            color.set(1, prov.color[0])?;
            color.set(2, prov.color[1])?;
            color.set(3, prov.color[2])?;
            t.set("color", color)?;

            let centroid = lua.create_table()?;
            centroid.set("x", prov.centroid.x)?;
            centroid.set("y", prov.centroid.y)?;
            t.set("centroid", centroid)?;

            let bb = lua.create_table()?;
            bb.set("x", prov.bounding_box.x)?;
            bb.set("y", prov.bounding_box.y)?;
            bb.set("width", prov.bounding_box.width)?;
            bb.set("height", prov.bounding_box.height)?;
            t.set("boundingBox", bb)?;

            let positions = lua.create_table()?;
            for (i, pos) in prov.positions.iter().enumerate() {
                let pt = lua.create_table()?;
                pt.set("x", pos.x)?;
                pt.set("y", pos.y)?;
                positions.set(i + 1, pt)?;
            }
            t.set("positions", positions)?;

            Ok(t)
        });

        // Get the province ID at a pixel coordinate.
        methods.add_method("getProvinceAt", |_, this, (x, y): (u32, u32)| {
            let inner = this.inner.borrow();
            match inner.get_province_at(x, y) {
                Some(id) if id != 0 => Ok(Some(id)),
                _ => Ok(None),
            }
        });

        // Get neighbor province IDs.
        methods.add_method("getNeighbors", |_, this, id: u32| {
            Ok(this.inner.borrow().get_neighbors(id))
        });

        // Get adjacency info between two provinces.
        methods.add_method("getAdjacency", |lua, this, (a, b): (u32, u32)| {
            let inner = this.inner.borrow();
            match inner.get_adjacency(a, b) {
                Some(edge) => {
                    let t = lua.create_table()?;
                    t.set("borderLength", edge.border_length)?;
                    // Return tags as a Lua array
                    let tags = lua.create_table()?;
                    for (i, tag) in edge.tags.iter().enumerate() {
                        tags.set(i + 1, tag.as_str())?;
                    }
                    t.set("tags", tags)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // Get the area of a province.
        methods.add_method("getArea", |_, this, id: u32| {
            let inner = this.inner.borrow();
            let prov = inner
                .get_province(id)
                .ok_or_else(|| prov_err(ProvinceError::NotFound(id)))?;
            Ok(prov.area)
        });

        // Get the centroid of a province as {x, y}.
        methods.add_method("getCentroid", |lua, this, id: u32| {
            let inner = this.inner.borrow();
            let prov = inner
                .get_province(id)
                .ok_or_else(|| prov_err(ProvinceError::NotFound(id)))?;
            let t = lua.create_table()?;
            t.set("x", prov.centroid.x)?;
            t.set("y", prov.centroid.y)?;
            Ok(t)
        });

        // Get the position slots for a province as an array of {x, y}.
        methods.add_method("getPositions", |lua, this, id: u32| {
            let inner = this.inner.borrow();
            let prov = inner
                .get_province(id)
                .ok_or_else(|| prov_err(ProvinceError::NotFound(id)))?;
            let result = lua.create_table()?;
            for (i, pos) in prov.positions.iter().enumerate() {
                let pt = lua.create_table()?;
                pt.set("x", pos.x)?;
                pt.set("y", pos.y)?;
                result.set(i + 1, pt)?;
            }
            Ok(result)
        });

        // Get the distance between two province centroids.
        methods.add_method("getDistance", |_, this, (a, b): (u32, u32)| {
            Ok(this.inner.borrow().distance(a, b))
        });

        // Get the border length between two provinces.
        methods.add_method("getBorderLength", |_, this, (a, b): (u32, u32)| {
            let inner = this.inner.borrow();
            match inner.get_adjacency(a, b) {
                Some(edge) => Ok(edge.border_length),
                None => Ok(0),
            }
        });

        // Get all provinces that have a specific property value.
        methods.add_method("getProvincesByProperty", |_, this, (key, val): (String, LuaValue)| {
            let data = this.data.borrow();
            let inner = this.inner.borrow();
            let target = lua_to_province_value(&val)?;
            let mut result = Vec::new();
            for id in inner.province_ids() {
                if let Some(pv) = data.get_property(id, &key) {
                    if *pv == target {
                        result.push(id);
                    }
                }
            }
            Ok(result)
        });

        // ---- Edge tag methods ----

        // Check if an edge between two provinces has a specific tag.
        methods.add_method("hasEdgeTag", |_, this, (a, b, tag): (u32, u32, String)| {
            let inner = this.inner.borrow();
            match inner.get_adjacency(a, b) {
                Some(edge) => Ok(edge.tags.contains(&tag)),
                None => Ok(false),
            }
        });

        // Get all tags on the edge between two provinces.
        methods.add_method("getEdgeTags", |_, this, (a, b): (u32, u32)| {
            let inner = this.inner.borrow();
            match inner.get_adjacency(a, b) {
                Some(edge) => {
                    let tags: Vec<String> = edge.tags.iter().cloned().collect();
                    Ok(tags)
                }
                None => Ok(Vec::new()),
            }
        });

        // Add a tag to the edge between two provinces.
        methods.add_method("addEdgeTag", |_, this, (a, b, tag): (u32, u32, String)| {
            let mut inner = this.inner.borrow_mut();
            match inner.get_adjacency_mut(a, b) {
                Some(edge) => {
                    edge.tags.insert(tag);
                    Ok(true)
                }
                None => Ok(false),
            }
        });

        // Remove a tag from the edge between two provinces.
        methods.add_method("removeEdgeTag", |_, this, (a, b, tag): (u32, u32, String)| {
            let mut inner = this.inner.borrow_mut();
            match inner.get_adjacency_mut(a, b) {
                Some(edge) => Ok(edge.tags.remove(&tag)),
                None => Ok(false),
            }
        });

        // ---- Mutation methods ----

        // Calculate and set primary positions for all provinces.
        methods.add_method("calculatePositions", |_, this, ()| {
            let mut inner = this.inner.borrow_mut();
            calculate_all_positions(&mut inner);
            Ok(())
        });

        // Generate position slots within a province for placing objects.
        methods.add_method("getSlots", |lua, this, (id, count, seed): (u32, usize, Option<u64>)| {
            let inner = this.inner.borrow();
            let slots = calculate_slots(&inner, id, count, seed.unwrap_or(42));
            let result = lua.create_table()?;
            for (i, pos) in slots.iter().enumerate() {
                let pt = lua.create_table()?;
                pt.set("x", pos.x)?;
                pt.set("y", pos.y)?;
                result.set(i + 1, pt)?;
            }
            Ok(result)
        });

        // Get the label anchor angle for a province (PCA-based).
        methods.add_method("getLabelAngle", |lua, this, id: u32| {
            let inner = this.inner.borrow();
            let (pos, angle) = calculate_label_position(&inner, id);
            let t = lua.create_table()?;
            t.set("x", pos.x)?;
            t.set("y", pos.y)?;
            t.set("angle", angle)?;
            Ok(t)
        });

        // Detect adjacencies between provinces.
        methods.add_method("detectAdjacency", |_, this, ()| {
            let mut inner = this.inner.borrow_mut();
            detect_adjacency(&mut inner);
            Ok(())
        });

        // Detect adjacencies with tag-pixel detection.
        // Takes a table of {[color_id] = "tag_string"} mappings.
        methods.add_method("detectAdjacencyWithTags", |_, this, tag_table: LuaTable| {
            let mut tag_colors: HashMap<u32, String> = HashMap::new();
            for pair in tag_table.pairs::<u32, String>() {
                let (color_id, tag) = pair?;
                tag_colors.insert(color_id, tag);
            }
            let mut inner = this.inner.borrow_mut();
            detect_adjacency_with_tags(&mut inner, &tag_colors);
            Ok(())
        });

        // ---- Map mode methods ----

        // Add a map mode. Config table: {name, type, colors?, key?, minColor?, maxColor?, minVal?, maxVal?, valueColors?, defaultColor?}
        methods.add_method("addMapMode", |_, this, (name, config): (String, LuaTable)| {
            let mode_type: String = config.get::<_, String>("type").unwrap_or_else(|_| "source".to_string());

            let color_fn = match mode_type.as_str() {
                "source" => MapModeColorFn::SourceColor,
                "fixed" => {
                    let colors_table: LuaTable = config.get("colors")?;
                    let mut colors = HashMap::new();
                    for pair in colors_table.pairs::<u32, LuaTable>() {
                        let (id, ct) = pair?;
                        let r: f32 = ct.get(1)?;
                        let g: f32 = ct.get(2)?;
                        let b: f32 = ct.get(3)?;
                        let a: f32 = ct.get::<_, f32>(4).unwrap_or(1.0);
                        colors.insert(id, [r, g, b, a]);
                    }
                    MapModeColorFn::Fixed(colors)
                }
                "gradient" => {
                    let key: String = config.get("key")?;
                    let min_c: LuaTable = config.get("minColor")?;
                    let max_c: LuaTable = config.get("maxColor")?;
                    let min_val: f64 = config.get::<_, f64>("minVal").unwrap_or(0.0);
                    let max_val: f64 = config.get::<_, f64>("maxVal").unwrap_or(1.0);
                    MapModeColorFn::Gradient {
                        key,
                        min_color: [min_c.get(1)?, min_c.get(2)?, min_c.get(3)?, min_c.get::<_, f32>(4).unwrap_or(1.0)],
                        max_color: [max_c.get(1)?, max_c.get(2)?, max_c.get(3)?, max_c.get::<_, f32>(4).unwrap_or(1.0)],
                        min_val,
                        max_val,
                    }
                }
                "property" => {
                    let key: String = config.get("key")?;
                    let colors_table: LuaTable = config.get("valueColors")?;
                    let mut value_colors = HashMap::new();
                    for pair in colors_table.pairs::<String, LuaTable>() {
                        let (val_name, ct) = pair?;
                        let r: f32 = ct.get(1)?;
                        let g: f32 = ct.get(2)?;
                        let b: f32 = ct.get(3)?;
                        let a: f32 = ct.get::<_, f32>(4).unwrap_or(1.0);
                        value_colors.insert(val_name, [r, g, b, a]);
                    }
                    let default_color = match config.get::<_, LuaTable>("defaultColor") {
                        Ok(dc) => [
                            dc.get::<_, f32>(1).unwrap_or(0.5),
                            dc.get::<_, f32>(2).unwrap_or(0.5),
                            dc.get::<_, f32>(3).unwrap_or(0.5),
                            dc.get::<_, f32>(4).unwrap_or(1.0),
                        ],
                        Err(_) => [0.5, 0.5, 0.5, 1.0],
                    };
                    MapModeColorFn::Property {
                        key,
                        value_colors,
                        default_color,
                    }
                }
                _ => {
                    return Err(LuaError::external(format!(
                        "Unknown map mode type: '{}'. Expected: source, fixed, gradient, property",
                        mode_type
                    )));
                }
            };

            let mode = MapMode {
                name: name.clone(),
                color_fn,
            };

            this.map_modes.borrow_mut().insert(name, mode);
            Ok(())
        });

        // Set the active map mode by name. Rebuilds the colour buffer.
        methods.add_method("setMapMode", |_, this, name: String| {
            {
                let modes = this.map_modes.borrow();
                if !modes.contains_key(&name) {
                    return Err(LuaError::external(format!("Map mode '{}' not found", name)));
                }
            }
            *this.active_mode.borrow_mut() = Some(name);
            rebuild_color_buffer(this);
            Ok(())
        });

        // Get the name of the active map mode.
        methods.add_method("getMapMode", |_, this, ()| {
            Ok(this.active_mode.borrow().clone())
        });

        // Force-rebuild the colour buffer (e.g., after changing properties).
        methods.add_method("refreshColors", |_, this, ()| {
            rebuild_color_buffer(this);
            Ok(())
        });

        // Get the colour buffer as a flat table of bytes (width*height*4 RGBA).
        methods.add_method("getColorBuffer", |_, this, ()| {
            let buf = this.color_buffer.borrow();
            Ok(buf.clone())
        });

        // Get the colour buffer dimensions as width, height (multi-return).
        methods.add_method("getColorBufferSize", |_, this, ()| {
            let inner = this.inner.borrow();
            Ok((inner.width(), inner.height()))
        });

        // ---- Fog of War methods ----

        // Set fog state for a province: "hidden", "explored", or "visible".
        methods.add_method("setFog", |_, this, (id, state_name): (u32, String)| {
            let state = match state_name.to_ascii_lowercase().as_str() {
                "hidden" => FogState::Hidden,
                "explored" => FogState::Explored,
                "visible" => FogState::Visible,
                _ => {
                    return Err(LuaError::external(format!(
                        "Invalid fog state: '{}'. Expected: hidden, explored, visible",
                        state_name
                    )));
                }
            };
            this.fog.borrow_mut().set(id, state);
            Ok(())
        });

        // Get the fog state for a province as a string.
        methods.add_method("getFog", |_, this, id: u32| {
            let state = this.fog.borrow().get(id);
            Ok(match state {
                FogState::Hidden => "hidden",
                FogState::Explored => "explored",
                FogState::Visible => "visible",
            })
        });

        // Reveal all provinces within radius adjacency hops of center.
        methods.add_method("revealRadius", |_, this, (center, radius): (u32, u32)| {
            let inner = this.inner.borrow();
            this.fog.borrow_mut().reveal_radius(&inner, center, radius);
            Ok(())
        });

        // Apply fog to the cached colour buffer in-place.
        methods.add_method("applyFog", |_, this, ()| {
            let inner = this.inner.borrow();
            let fog = this.fog.borrow();
            let mut buf = this.color_buffer.borrow_mut();
            fog.apply_to_pixels(&mut buf, &inner);
            Ok(())
        });

        // Reveal a single province.
        methods.add_method("reveal", |_, this, id: u32| {
            this.fog.borrow_mut().reveal(id);
            Ok(())
        });

        // Set all provinces to hidden.
        methods.add_method("hideAll", |_, this, ()| {
            let inner = this.inner.borrow();
            let mut fog = this.fog.borrow_mut();
            for id in inner.province_ids() {
                fog.hide(id);
            }
            Ok(())
        });

        // Set all provinces to visible.
        methods.add_method("revealAll", |_, this, ()| {
            let inner = this.inner.borrow();
            let mut fog = this.fog.borrow_mut();
            for id in inner.province_ids() {
                fog.reveal(id);
            }
            Ok(())
        });

        // ---- Border methods ----

        // Set a border style by name.
        methods.add_method("setBorderStyle", |_, this, (border_type, config): (String, LuaTable)| {
            let width: f32 = config.get::<_, f32>("width").unwrap_or(1.0);
            let color_table: Option<LuaTable> = config.get("color").ok();
            let color = match color_table {
                Some(ct) => [
                    ct.get::<_, f32>(1).unwrap_or(0.0),
                    ct.get::<_, f32>(2).unwrap_or(0.0),
                    ct.get::<_, f32>(3).unwrap_or(0.0),
                    ct.get::<_, f32>(4).unwrap_or(1.0),
                ],
                None => [0.0, 0.0, 0.0, 1.0],
            };
            let dashed: bool = config.get::<_, bool>("dashed").unwrap_or(false);

            this.border_styles.borrow_mut().insert(
                border_type,
                BorderStyle {
                    width,
                    color,
                    dashed,
                },
            );
            Ok(())
        });

        // Get all borders as an array of {provinceA, provinceB, points, tags}.
        methods.add_method("getAllBorders", |lua, this, ()| {
            let inner = this.inner.borrow();
            let segments = extract_all_borders(&inner);
            let result = lua.create_table()?;
            for (i, seg) in segments.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("provinceA", seg.province_a)?;
                t.set("provinceB", seg.province_b)?;
                let tags = lua.create_table()?;
                for (j, tag) in seg.tags.iter().enumerate() {
                    tags.set(j + 1, tag.as_str())?;
                }
                t.set("tags", tags)?;
                let pts = lua.create_table()?;
                for (j, &(x, y)) in seg.points.iter().enumerate() {
                    let p = lua.create_table()?;
                    p.set("x", x)?;
                    p.set("y", y)?;
                    pts.set(j + 1, p)?;
                }
                t.set("points", pts)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Get only borders that have a specific tag.
        methods.add_method("getBordersWithTag", |lua, this, tag: String| {
            let inner = this.inner.borrow();
            let segments = extract_borders_with_tag(&inner, &tag);
            let result = lua.create_table()?;
            for (i, seg) in segments.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("provinceA", seg.province_a)?;
                t.set("provinceB", seg.province_b)?;
                let pts = lua.create_table()?;
                for (j, &(x, y)) in seg.points.iter().enumerate() {
                    let p = lua.create_table()?;
                    p.set("x", x)?;
                    p.set("y", y)?;
                    pts.set(j + 1, p)?;
                }
                t.set("points", pts)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Get borders where a property differs between adjacent provinces.
        methods.add_method("getBordersByProperty", |lua, this, key: String| {
            let inner = this.inner.borrow();
            let data = this.data.borrow();
            let segments = extract_borders_by_property(&inner, |id| {
                data.get_property(id, &key)
                    .map(|v| match v {
                        ProvinceValue::Str(s) => s.clone(),
                        ProvinceValue::Int(n) => n.to_string(),
                        ProvinceValue::Float(n) => format!("{:.6}", n),
                        ProvinceValue::Bool(b) => b.to_string(),
                    })
            });
            let result = lua.create_table()?;
            for (i, seg) in segments.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("provinceA", seg.province_a)?;
                t.set("provinceB", seg.province_b)?;
                let pts = lua.create_table()?;
                for (j, &(x, y)) in seg.points.iter().enumerate() {
                    let p = lua.create_table()?;
                    p.set("x", x)?;
                    p.set("y", y)?;
                    pts.set(j + 1, p)?;
                }
                t.set("points", pts)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // ---- Pathfinding methods ----

        // Find a path between two provinces. Optional cost config table.
        methods.add_method("findPath", |lua, this, (from, to, opts): (u32, u32, Option<LuaTable>)| {
            let cost_fn = parse_cost_fn(opts)?;
            let inner = this.inner.borrow();
            let data = this.data.borrow();
            let ids = inner.province_ids();
            let props_map = build_properties_map(&data, &ids);
            match inner.find_path(from, to, &cost_fn, &props_map) {
                Some(path) => {
                    let t = lua.create_table()?;
                    t.set("provinces", path.provinces.clone())?;
                    t.set("totalCost", path.total_cost)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // Get all provinces reachable from a province within a cost budget.
        methods.add_method("getReachable", |_, this, (from, max_cost, opts): (u32, f64, Option<LuaTable>)| {
            let cost_fn = parse_cost_fn(opts)?;
            let inner = this.inner.borrow();
            let data = this.data.borrow();
            let ids = inner.province_ids();
            let props_map = build_properties_map(&data, &ids);
            Ok(inner.reachable(from, max_cost, &cost_fn, &props_map))
        });

        // ---- Movement methods ----

        // Add a moving unit along a path. Returns unit ID.
        methods.add_method("addMovingUnit", |_, this, (path_table, speed): (LuaTable, f32)| {
            let provinces: Vec<u32> = path_table.get("provinces")?;
            let total_cost: f64 = path_table.get::<_, f64>("totalCost").unwrap_or(0.0);
            let path = crate::province::ProvincePath {
                provinces,
                total_cost,
            };
            Ok(this.movement.borrow_mut().add_unit(path, speed))
        });

        // Remove a moving unit by ID.
        methods.add_method("removeMovingUnit", |_, this, id: u64| {
            Ok(this.movement.borrow_mut().remove_unit(id))
        });

        // Update all moving units by dt seconds.
        methods.add_method("updateMovement", |_, this, dt: f32| {
            this.movement.borrow_mut().update_all(dt);
            Ok(())
        });

        // Get the world position of a moving unit as {x, y}.
        methods.add_method("getUnitPosition", |lua, this, id: u64| {
            let inner = this.inner.borrow();
            let movement = this.movement.borrow();
            match movement.get_unit(id) {
                Some(unit) => {
                    let pos = unit.world_position(&inner);
                    let t = lua.create_table()?;
                    t.set("x", pos.x)?;
                    t.set("y", pos.y)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // Get the current province of a moving unit.
        methods.add_method("getUnitProvince", |_, this, id: u64| {
            let movement = this.movement.borrow();
            match movement.get_unit(id) {
                Some(unit) => Ok(Some(unit.current_province())),
                None => Ok(None),
            }
        });

        // Check if a moving unit has finished its path.
        methods.add_method("isUnitFinished", |_, this, id: u64| {
            let movement = this.movement.borrow();
            match movement.get_unit(id) {
                Some(unit) => Ok(unit.is_finished()),
                None => Err(LuaError::external("Moving unit not found")),
            }
        });

        // ---- Properties methods ----

        // Set a custom property on a province. Emits "property_changed" event.
        methods.add_method("setProperty", |_, this, (id, key, val): (u32, String, LuaValue)| {
            let pv = lua_to_province_value(&val)?;
            let display = province_value_display(&pv);
            this.data.borrow_mut().set_property(id, key.clone(), pv);
            this.events.borrow_mut().emit_property_changed(id, &key, &display);
            Ok(())
        });

        // Get a custom property from a province.
        methods.add_method("getProperty", |lua, this, (id, key): (u32, String)| {
            let data = this.data.borrow();
            match data.get_property(id, &key) {
                Some(val) => province_value_to_lua(lua, val),
                None => Ok(LuaValue::Nil),
            }
        });

        // Add a temporary state to a province. Config: {name, data?, duration?}
        methods.add_method("addState", |_, this, (id, config): (u32, LuaTable)| {
            let name: String = config.get("name")?;
            let duration: Option<f32> = config.get("duration").ok();
            let mut state_data = HashMap::new();

            if let Ok(data_table) = config.get::<_, LuaTable>("data") {
                for pair in data_table.pairs::<String, LuaValue>() {
                    let (k, v) = pair?;
                    state_data.insert(k, lua_to_province_value(&v)?);
                }
            }

            this.data.borrow_mut().add_state(
                id,
                ProvinceState {
                    name,
                    data: state_data,
                    duration,
                    elapsed: 0.0,
                },
            );
            Ok(())
        });

        // Remove a state by name from a province.
        methods.add_method("removeState", |_, this, (id, name): (u32, String)| {
            Ok(this.data.borrow_mut().remove_state(id, &name))
        });

        // Check whether a province has a state with the given name.
        methods.add_method("hasState", |_, this, (id, name): (u32, String)| {
            Ok(this.data.borrow().has_state(id, &name))
        });

        // Get all states on a province as an array of {name, duration?, elapsed}.
        methods.add_method("getStates", |lua, this, id: u32| {
            let data = this.data.borrow();
            let states = data.get_states(id);
            let result = lua.create_table()?;
            for (i, s) in states.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("name", s.name.as_str())?;
                t.set("elapsed", s.elapsed)?;
                if let Some(d) = s.duration {
                    t.set("duration", d)?;
                }
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Update all timed states (expire finished ones).
        methods.add_method("updateStates", |_, this, dt: f32| {
            this.data.borrow_mut().update_states(dt);
            Ok(())
        });

        // ---- Objects / Improvements methods ----

        // Add an improvement to a province. Returns improvement ID.
        methods.add_method(
            "addImprovement",
            |_, this, (province_id, type_name, x, y): (u32, String, Option<f32>, Option<f32>)| {
                let inner = this.inner.borrow();
                let pos = match (x, y) {
                    (Some(px), Some(py)) => Vec2::new(px, py),
                    _ => inner
                        .get_province(province_id)
                        .and_then(|p| p.positions.first().copied())
                        .unwrap_or(Vec2::ZERO),
                };
                let imp_id = this
                    .objects
                    .borrow_mut()
                    .add_improvement(province_id, type_name.clone(), pos);
                this.events.borrow_mut().emit_object_added(province_id, imp_id, &type_name);
                Ok(imp_id)
            },
        );

        // Remove an improvement by ID. Emits "object_removed" event.
        methods.add_method("removeImprovement", |_, this, imp_id: u64| {
            let info = {
                let objects = this.objects.borrow();
                objects.get_improvement(imp_id).map(|imp| (imp.province_id, imp.type_name.clone()))
            };
            let removed = this.objects.borrow_mut().remove_improvement(imp_id);
            if removed {
                if let Some((pid, tname)) = info {
                    this.events.borrow_mut().emit_object_removed(pid, imp_id, &tname);
                }
            }
            Ok(removed)
        });

        // Get an improvement by ID.
        methods.add_method("getImprovement", |lua, this, id: u64| {
            let objects = this.objects.borrow();
            match objects.get_improvement(id) {
                Some(imp) => {
                    let t = lua.create_table()?;
                    t.set("id", imp.id)?;
                    t.set("type", imp.type_name.as_str())?;
                    t.set("provinceId", imp.province_id)?;
                    t.set("x", imp.position.x)?;
                    t.set("y", imp.position.y)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // Get all improvements in a province.
        methods.add_method("getImprovementsIn", |lua, this, province_id: u32| {
            let objects = this.objects.borrow();
            let imps = objects.improvements_in_province(province_id);
            let result = lua.create_table()?;
            for (i, imp) in imps.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("id", imp.id)?;
                t.set("type", imp.type_name.as_str())?;
                t.set("x", imp.position.x)?;
                t.set("y", imp.position.y)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Add a movable object to a province. Returns object ID.
        methods.add_method(
            "addObject",
            |_, this, (province_id, type_name, x, y): (u32, String, Option<f32>, Option<f32>)| {
                let inner = this.inner.borrow();
                let pos = match (x, y) {
                    (Some(px), Some(py)) => Vec2::new(px, py),
                    _ => inner
                        .get_province(province_id)
                        .and_then(|p| p.positions.first().copied())
                        .unwrap_or(Vec2::ZERO),
                };
                let obj_id = this
                    .objects
                    .borrow_mut()
                    .add_object(province_id, type_name.clone(), pos);
                this.events.borrow_mut().emit_object_added(province_id, obj_id, &type_name);
                Ok(obj_id)
            },
        );

        // Remove a movable object by ID. Emits "object_removed" event.
        methods.add_method("removeObject", |_, this, obj_id: u64| {
            let info = {
                let objects = this.objects.borrow();
                objects.get_object(obj_id).map(|o| (o.province_id, o.type_name.clone()))
            };
            let removed = this.objects.borrow_mut().remove_object(obj_id);
            if removed {
                if let Some((pid, tname)) = info {
                    this.events.borrow_mut().emit_object_removed(pid, obj_id, &tname);
                }
            }
            Ok(removed)
        });

        // Get a movable object by ID.
        methods.add_method("getObject", |lua, this, id: u64| {
            let objects = this.objects.borrow();
            match objects.get_object(id) {
                Some(obj) => {
                    let t = lua.create_table()?;
                    t.set("id", obj.id)?;
                    t.set("type", obj.type_name.as_str())?;
                    t.set("provinceId", obj.province_id)?;
                    t.set("x", obj.position.x)?;
                    t.set("y", obj.position.y)?;
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // Get all objects in a province.
        methods.add_method("getObjectsIn", |lua, this, province_id: u32| {
            let objects = this.objects.borrow();
            let objs = objects.objects_in_province(province_id);
            let result = lua.create_table()?;
            for (i, obj) in objs.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("id", obj.id)?;
                t.set("type", obj.type_name.as_str())?;
                t.set("x", obj.position.x)?;
                t.set("y", obj.position.y)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Move an object to a different province.
        methods.add_method("moveObject", |_, this, (id, target_province, x, y): (u64, u32, Option<f32>, Option<f32>)| {
            let inner = this.inner.borrow();
            let pos = match (x, y) {
                (Some(px), Some(py)) => Vec2::new(px, py),
                _ => inner
                    .get_province(target_province)
                    .and_then(|p| p.positions.first().copied())
                    .unwrap_or(Vec2::ZERO),
            };
            Ok(this.objects.borrow_mut().move_object(id, target_province, pos))
        });

        // Get all objects (across all provinces) as an array.
        methods.add_method("getAllObjects", |lua, this, ()| {
            let objects = this.objects.borrow();
            let result = lua.create_table()?;
            for (i, obj) in objects.all_objects().enumerate() {
                let t = lua.create_table()?;
                t.set("id", obj.id)?;
                t.set("type", obj.type_name.as_str())?;
                t.set("provinceId", obj.province_id)?;
                t.set("x", obj.position.x)?;
                t.set("y", obj.position.y)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Get all improvements (across all provinces) as an array.
        methods.add_method("getAllImprovements", |lua, this, ()| {
            let objects = this.objects.borrow();
            let result = lua.create_table()?;
            for (i, imp) in objects.all_improvements().enumerate() {
                let t = lua.create_table()?;
                t.set("id", imp.id)?;
                t.set("type", imp.type_name.as_str())?;
                t.set("provinceId", imp.province_id)?;
                t.set("x", imp.position.x)?;
                t.set("y", imp.position.y)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // ---- Minimap methods ----

        // Generate a minimap. Returns {width, height, pixels} table.
        methods.add_method("generateMinimap", |lua, this, (width, height): (u32, u32)| {
            let inner = this.inner.borrow();
            let mut colors = HashMap::new();
            for id in inner.province_ids() {
                if let Some(prov) = inner.get_province(id) {
                    colors.insert(id, [
                        prov.color[0] as f32 / 255.0,
                        prov.color[1] as f32 / 255.0,
                        prov.color[2] as f32 / 255.0,
                        1.0,
                    ]);
                }
            }

            let minimap = ProvinceMinimap::new(&inner, &colors, width, height);
            let t = lua.create_table()?;
            t.set("width", minimap.width())?;
            t.set("height", minimap.height())?;
            t.set("pixels", minimap.pixels().to_vec())?;
            Ok(t)
        });

        // ========== Organization API ==========

        // Create an organization. Args: name, type, isPhysical?. Returns org ID.
        methods.add_method("createOrg", |_, this, (name, org_type, is_physical): (String, String, Option<bool>)| {
            Ok(this.orgs.borrow_mut().create(&name, &org_type, is_physical.unwrap_or(true)))
        });

        // Remove an organization by ID. Returns true if it existed.
        methods.add_method("removeOrg", |_, this, id: u64| {
            Ok(this.orgs.borrow_mut().remove(id))
        });

        // Get an organization as a table: {id, name, type, isPhysical, capital?, provinces}.
        methods.add_method("getOrg", |lua, this, id: u64| {
            let orgs = this.orgs.borrow();
            match orgs.get(id) {
                None => Ok(LuaValue::Nil),
                Some(org) => {
                    let t = lua.create_table()?;
                    t.set("id", org.id)?;
                    t.set("name", org.name.as_str())?;
                    t.set("type", org.org_type.as_str())?;
                    t.set("isPhysical", org.is_physical)?;
                    if let Some(cap) = org.capital_province {
                        t.set("capital", cap)?;
                    }
                    let provinces = lua.create_table()?;
                    for (i, &pid) in org.province_ids.iter().enumerate() {
                        provinces.set(i + 1, pid)?;
                    }
                    t.set("provinces", provinces)?;
                    Ok(LuaValue::Table(t))
                }
            }
        });

        // Get all organizations as an array of org tables.
        methods.add_method("getAllOrgs", |lua, this, ()| {
            let orgs = this.orgs.borrow();
            let result = lua.create_table()?;
            for (i, id) in orgs.all_ids().iter().enumerate() {
                if let Some(org) = orgs.get(*id) {
                    let t = lua.create_table()?;
                    t.set("id", org.id)?;
                    t.set("name", org.name.as_str())?;
                    t.set("type", org.org_type.as_str())?;
                    t.set("isPhysical", org.is_physical)?;
                    result.set(i + 1, t)?;
                }
            }
            Ok(result)
        });

        // Assign a province to an organization. Returns true on success.
        methods.add_method("assignProvince", |_, this, (org_id, province_id): (u64, u32)| {
            let ok = this.orgs.borrow_mut().assign_province(org_id, province_id);
            if ok {
                this.events.borrow_mut().emit_org_assigned(province_id, org_id);
            }
            Ok(ok)
        });

        // Remove a province from an organization. Returns true if it was present.
        methods.add_method("unassignProvince", |_, this, (org_id, province_id): (u64, u32)| {
            let ok = this.orgs.borrow_mut().unassign_province(org_id, province_id);
            if ok {
                this.events.borrow_mut().emit_org_unassigned(province_id, org_id);
            }
            Ok(ok)
        });

        // Set the capital province of an organization.
        methods.add_method("setCapital", |_, this, (org_id, province_id): (u64, u32)| {
            Ok(this.orgs.borrow_mut().set_capital(org_id, province_id))
        });

        // Get all org IDs that include a province.
        methods.add_method("getOrgsInProvince", |_, this, province_id: u32| {
            Ok(this.orgs.borrow().orgs_in_province(province_id))
        });

        // Get all province IDs controlled by an org.
        methods.add_method("getProvincesOfOrg", |_, this, org_id: u64| {
            Ok(this.orgs.borrow().provinces_of_org(org_id))
        });

        // Get the primary (lowest-ID physical) org controlling a province, or nil.
        methods.add_method("getPrimaryOrg", |_, this, province_id: u32| {
            Ok(this.orgs.borrow().primary_org(province_id))
        });

        // Set a property on an organization.
        methods.add_method("setOrgProperty", |_, this, (org_id, key, val): (u64, String, LuaValue)| {
            let pv = lua_to_province_value(&val)?;
            Ok(this.orgs.borrow_mut().set_property(org_id, key, pv))
        });

        // Get a property from an organization. Returns nil if not set.
        methods.add_method("getOrgProperty", |lua, this, (org_id, key): (u64, String)| {
            let orgs = this.orgs.borrow();
            match orgs.get_property(org_id, &key) {
                Some(val) => province_value_to_lua(lua, val),
                None => Ok(LuaValue::Nil),
            }
        });

        // Get border segments that separate provinces belonging to different primary orgs.
        methods.add_method("getOrgBorders", |lua, this, ()| {
            let inner = this.inner.borrow();
            let orgs = this.orgs.borrow();
            let segments = extract_borders_by_property(&inner, |id| {
                orgs.primary_org(id).map(|oid| oid.to_string())
            });
            let result = lua.create_table()?;
            for (i, seg) in segments.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("provinceA", seg.province_a)?;
                t.set("provinceB", seg.province_b)?;
                let pts = lua.create_table()?;
                for (j, &(x, y)) in seg.points.iter().enumerate() {
                    let p = lua.create_table()?;
                    p.set("x", x)?;
                    p.set("y", y)?;
                    pts.set(j + 1, p)?;
                }
                t.set("points", pts)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // Get border segments between provinces owned by org_a and provinces owned by org_b.
        methods.add_method("getBordersBetweenOrgs", |lua, this, (org_a_id, org_b_id): (u64, u64)| {
            let inner = this.inner.borrow();
            let orgs = this.orgs.borrow();
            let segments = extract_all_borders(&inner);
            let result = lua.create_table()?;
            let mut idx = 1usize;
            for seg in &segments {
                let primary_a = orgs.primary_org(seg.province_a);
                let primary_b = orgs.primary_org(seg.province_b);
                let is_boundary = matches!(
                    (primary_a, primary_b),
                    (Some(a), Some(b)) if (a == org_a_id && b == org_b_id) || (a == org_b_id && b == org_a_id)
                );
                if is_boundary {
                    let t = lua.create_table()?;
                    t.set("provinceA", seg.province_a)?;
                    t.set("provinceB", seg.province_b)?;
                    let pts = lua.create_table()?;
                    for (j, &(x, y)) in seg.points.iter().enumerate() {
                        let p = lua.create_table()?;
                        p.set("x", x)?;
                        p.set("y", y)?;
                        pts.set(j + 1, p)?;
                    }
                    t.set("points", pts)?;
                    result.set(idx, t)?;
                    idx += 1;
                }
            }
            Ok(result)
        });

        // ========== Relation API ==========

        // Define a named relation type with valid levels. E.g. ("military", {"war","peace","alliance"}, "peace").
        methods.add_method("defineRelationType", |_, this, (name, levels_table, default_level): (String, LuaTable, String)| {
            let mut levels = Vec::new();
            for val in levels_table.sequence_values::<String>() {
                levels.push(val?);
            }
            this.relations.borrow_mut().define_type(&name, levels, &default_level);
            Ok(())
        });

        // Remove a relation type definition. Returns true if it existed.
        methods.add_method("removeRelationType", |_, this, name: String| {
            Ok(this.relations.borrow_mut().remove_type(&name))
        });

        // Get all defined relation type names as an array.
        methods.add_method("getRelationTypes", |_, this, ()| {
            Ok(this.relations.borrow().type_names())
        });

        // Set the numeric relation value between two orgs.
        methods.add_method("setRelationValue", |_, this, (from_org, to_org, value): (u64, u64, f64)| {
            this.relations.borrow_mut().set_value(from_org, to_org, value);
            this.events.borrow_mut().emit_relation_value_changed(from_org, to_org, value);
            Ok(())
        });

        // Get the numeric relation value between two orgs (default: 0.0).
        methods.add_method("getRelationValue", |_, this, (from_org, to_org): (u64, u64)| {
            Ok(this.relations.borrow().get_value(from_org, to_org))
        });

        // Add delta to the relation value between two orgs.
        methods.add_method("adjustRelationValue", |_, this, (from_org, to_org, delta): (u64, u64, f64)| {
            {
                this.relations.borrow_mut().adjust_value(from_org, to_org, delta);
            }
            let new_val = this.relations.borrow().get_value(from_org, to_org);
            this.events.borrow_mut().emit_relation_value_changed(from_org, to_org, new_val);
            Ok(new_val)
        });

        // Set the named level for a relation type between two orgs. Returns false if unknown type/level.
        methods.add_method("setRelationLevel", |_, this, (from_org, to_org, type_name, level): (u64, u64, String, String)| {
            let ok = this.relations.borrow_mut().set_level(from_org, to_org, &type_name, &level);
            if ok {
                this.events.borrow_mut().emit_relation_changed(from_org, to_org, &type_name, &level);
            }
            Ok(ok)
        });

        // Get the level for a relation type. Returns the default if not set, nil if type unknown.
        methods.add_method("getRelationLevel", |lua, this, (from_org, to_org, type_name): (u64, u64, String)| {
            match this.relations.borrow().get_level(from_org, to_org, &type_name) {
                Some(level) => Ok(LuaValue::String(lua.create_string(&level)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // Get all relations involving an org as [{orgId, value}].
        methods.add_method("getAllRelationsFor", |lua, this, org_id: u64| {
            let relations = this.relations.borrow();
            let result = lua.create_table()?;
            for (i, rel) in relations.all_relations_for(org_id).iter().enumerate() {
                let t = lua.create_table()?;
                let other = if rel.from_org == org_id { rel.to_org } else { rel.from_org };
                t.set("orgId", other)?;
                t.set("value", rel.value)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        });

        // ========== Event API ==========

        // Register a Lua handler for an event type. Multiple handlers per type are supported.
        methods.add_method("onEvent", |lua, this, (event_type, handler): (String, LuaFunction)| {
            let key = lua.create_registry_value(handler)?;
            this.event_handlers.borrow_mut()
                .entry(event_type)
                .or_default()
                .push(key);
            Ok(())
        });

        // Process all pending events, calling registered Lua handlers.
        methods.add_method("processEvents", |lua, this, ()| {
            let events = this.events.borrow_mut().drain();
            for event in &events {
                let funcs: Vec<LuaFunction> = {
                    let handlers = this.event_handlers.borrow();
                    if let Some(keys) = handlers.get(&event.name) {
                        keys.iter()
                            .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                            .collect()
                    } else {
                        Vec::new()
                    }
                };
                let ev_table = make_event_table(lua, event)?;
                for func in &funcs {
                    func.call::<_, ()>(ev_table.clone())?;
                }
            }
            Ok(())
        });

        // Advance the turn counter and emit a "turn" event. Returns new turn number.
        methods.add_method("advanceTurn", |_, this, ()| {
            Ok(this.events.borrow_mut().advance_turn())
        });

        // Emit a tick event with the given delta-time.
        methods.add_method("emitTick", |_, this, dt: f64| {
            this.events.borrow_mut().emit_tick(dt);
            Ok(())
        });

        // Emit a custom-named event with an optional args table.
        methods.add_method("emitEvent", |_, this, (name, args_table): (String, Option<LuaTable>)| {
            use crate::event::EventArg;
            let mut args = Vec::new();
            if let Some(t) = args_table {
                for pair in t.pairs::<LuaValue, LuaValue>() {
                    let (_, val) = pair?;
                    match val {
                        LuaValue::Number(n) => args.push(EventArg::Num(n)),
                        LuaValue::Integer(n) => args.push(EventArg::Num(n as f64)),
                        LuaValue::String(s) => args.push(EventArg::Str(s.to_str()?.to_string())),
                        LuaValue::Boolean(b) => args.push(EventArg::Bool(b)),
                        _ => args.push(EventArg::Nil),
                    }
                }
            }
            this.events.borrow_mut().emit_custom(&name, args);
            Ok(())
        });

        // Get the current turn number.
        methods.add_method("currentTurn", |_, this, ()| {
            Ok(this.events.borrow().turn())
        });

        // ========== Procedure API ==========

        // Define a named Lua procedure: fn(province_id, event_table?).
        methods.add_method("defineProcedure", |lua, this, (name, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            this.lua_procedures.borrow_mut().insert(name, key);
            Ok(())
        });

        // Trigger a named procedure for a specific province. Returns false if not defined.
        methods.add_method("triggerProcedure", |lua, this, (province_id, name, ev_table): (u32, String, Option<LuaTable>)| {
            let func: Option<LuaFunction> = {
                let procs = this.lua_procedures.borrow();
                procs.get(&name).and_then(|k| lua.registry_value::<LuaFunction>(k).ok())
            };
            match func {
                Some(f) => {
                    f.call::<_, ()>((province_id, ev_table))?;
                    Ok(true)
                }
                None => Ok(false),
            }
        });

        // Trigger a named procedure for every province on the map. Returns number of invocations.
        methods.add_method("triggerProcedureAll", |lua, this, (name, ev_table): (String, Option<LuaTable>)| {
            let func: Option<LuaFunction> = {
                let procs = this.lua_procedures.borrow();
                procs.get(&name).and_then(|k| lua.registry_value::<LuaFunction>(k).ok())
            };
            let province_ids = this.inner.borrow().province_ids();
            let mut count = 0u32;
            if let Some(f) = func {
                for id in &province_ids {
                    f.call::<_, ()>((*id, ev_table.clone()))?;
                    count += 1;
                }
            }
            Ok(count)
        });
    }
}

// ---------------------------------------------------------------------------
// Helper: province value display string
// ---------------------------------------------------------------------------

fn province_value_display(val: &ProvinceValue) -> String {
    match val {
        ProvinceValue::Int(n) => n.to_string(),
        ProvinceValue::Float(n) => n.to_string(),
        ProvinceValue::Str(s) => s.clone(),
        ProvinceValue::Bool(b) => b.to_string(),
    }
}

// ---------------------------------------------------------------------------
// Helper: convert Event to a Lua table
// ---------------------------------------------------------------------------

fn make_event_table<'lua>(lua: &'lua Lua, event: &crate::event::Event) -> LuaResult<LuaTable<'lua>> {
    use crate::event::EventArg;
    let t = lua.create_table()?;
    t.set("name", event.name.as_str())?;
    let args = lua.create_table()?;
    for (i, arg) in event.args.iter().enumerate() {
        let val: LuaValue = match arg {
            EventArg::Str(s) => LuaValue::String(lua.create_string(s)?),
            EventArg::Num(n) => LuaValue::Number(*n),
            EventArg::Bool(b) => LuaValue::Boolean(*b),
            EventArg::Nil => LuaValue::Nil,
        };
        args.set(i + 1, val)?;
    }
    t.set("args", args)?;
    Ok(t)
}

// ---------------------------------------------------------------------------
// Helper: parse cost function from Lua table
// ---------------------------------------------------------------------------

fn parse_cost_fn(opts: Option<LuaTable>) -> LuaResult<ProvinceCostFn> {
    let mut cost_fn = ProvinceCostFn::default();

    if let Some(t) = opts {
        // property_costs: {property_key = {value = cost, ...}, ...}
        if let Ok(prop_costs) = t.get::<_, LuaTable>("propertyCosts") {
            for pair in prop_costs.pairs::<String, LuaTable>() {
                let (key, value_costs_table) = pair?;
                let mut value_costs = HashMap::new();
                for inner_pair in value_costs_table.pairs::<String, f64>() {
                    let (val, cost) = inner_pair?;
                    value_costs.insert(val, cost);
                }
                cost_fn.property_costs.insert(key, value_costs);
            }
        }
        // province_costs: {[id] = cost, ...}
        if let Ok(province_costs) = t.get::<_, LuaTable>("provinceCosts") {
            for pair in province_costs.pairs::<u32, f64>() {
                let (k, v) = pair?;
                cost_fn.province_costs.insert(k, v);
            }
        }
        // tag_costs: {tag = cost, ...}
        if let Ok(tag_costs) = t.get::<_, LuaTable>("tagCosts") {
            for pair in tag_costs.pairs::<String, f64>() {
                let (k, v) = pair?;
                cost_fn.tag_costs.insert(k, v);
            }
        }
        // default_cost: number
        if let Ok(dc) = t.get::<_, f64>("defaultCost") {
            cost_fn.default_cost = dc;
        }
    }

    Ok(cost_fn)
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

// Registers the `luna.province.*` province map API.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let province_table = lua.create_table()?;

    // Load a province map from a PNG file path.
    province_table.set(
        "load",
        lua.create_function(|_, path: String| {
            let map = ProvinceMap::from_file(&path).map_err(prov_err)?;
            Ok(wrap_map(map))
        })?,
    )?;

    // Generate a random province map. Config: {width?, height?, provinceCount?, seed?}
    province_table.set(
        "generate",
        lua.create_function(|_, config: Option<LuaTable>| {
            let wg_config = match config {
                Some(t) => WorldGenConfig {
                    width: t.get::<_, u32>("width").unwrap_or(800),
                    height: t.get::<_, u32>("height").unwrap_or(400),
                    province_count: t.get::<_, u32>("provinceCount").unwrap_or(100),
                    seed: t.get::<_, u64>("seed").unwrap_or(42),
                },
                None => WorldGenConfig::default(),
            };

            let map = generate_world(&wg_config);
            Ok(wrap_map(map))
        })?,
    )?;

    // Create an empty province map with given pixel dimensions.
    province_table.set(
        "newMap",
        lua.create_function(|_, (width, height): (u32, u32)| {
            let map = ProvinceMap::new(width, height);
            Ok(wrap_map(map))
        })?,
    )?;

    luna.set("province", province_table)?;
    Ok(())
}
