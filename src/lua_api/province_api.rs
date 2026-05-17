//! `lurek.province` — Province-based strategic map system with grid regions, borders, ownership tracking, adjacency queries, and map-mode rendering.

use super::SharedState;
use crate::image::ProvinceGrid;
use crate::province::events::ProvinceChange;
use crate::province::map_modes::ProvinceMapMode;
use crate::province::registry::ProvinceRegistry;
use crate::province::render::{generate_render_commands, ProvinceRenderOptions};
use crate::province::types::BorderClass;
use crate::province::{fit_camera_to_screen, map_to_cell, screen_to_map, zoom_camera_at};
use crate::province::{
    import_metadata_from_files, sanitize_marked_png, MarkerSanitizeOptions,
    ProvinceMetadataImportOptions,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;
/// Resolves a province asset path against the active game directory when the path is relative.
fn resolve_game_path(state: &Rc<RefCell<SharedState>>, path: &str) -> String {
    let st = state.borrow();
    let p = Path::new(path);
    if p.is_absolute() {
        p.to_string_lossy().into_owned()
    } else {
        st.game_dir.join(p).to_string_lossy().into_owned()
    }
}
/// Parses optional marker sanitization settings from a Lua options table.
fn marker_options_from_lua(opts: Option<&LuaTable>) -> MarkerSanitizeOptions {
    let mut out = MarkerSanitizeOptions::default();
    if let Some(t) = opts {
        if let Some(v) = t.get::<_, Option<u8>>("capital_min").ok().flatten() {
            out.capital_min = v;
        }
        if let Some(v) = t.get::<_, Option<u8>>("label_r_min").ok().flatten() {
            out.label_r_min = v;
        }
        if let Some(v) = t.get::<_, Option<u8>>("label_g_max").ok().flatten() {
            out.label_g_max = v;
        }
        if let Some(v) = t.get::<_, Option<u8>>("label_b_min").ok().flatten() {
            out.label_b_min = v;
        }
        if let Some(v) = t.get::<_, Option<u32>>("search_radius").ok().flatten() {
            out.search_radius = v;
        }
    }
    out
}
/// Handle to a named province registry, exposing spatial queries, style mutations, rendering, and change tracking to Lua scripts.
#[derive(Clone)]
pub struct LuaProvinceRegistry {
    name: String,
    state: Rc<RefCell<SharedState>>,
}
impl LuaProvinceRegistry {
    /// Runs a closure with the current province registry or returns a Lua runtime error when missing.
    fn with_registry<R>(&self, f: impl FnOnce(&ProvinceRegistry) -> R) -> LuaResult<R> {
        let st = self.state.borrow();
        let reg = st.province_registries.get(&self.name).ok_or_else(|| {
            LuaError::RuntimeError(format!("province registry '{}' not found", self.name))
        })?;
        Ok(f(reg))
    }
    fn with_registry_mut<R>(&self, f: impl FnOnce(&mut ProvinceRegistry) -> R) -> LuaResult<R> {
        let mut st = self.state.borrow_mut();
        let reg = st.province_registries.get_mut(&self.name).ok_or_else(|| {
            LuaError::RuntimeError(format!("province registry '{}' not found", self.name))
        })?;
        Ok(f(reg))
    }
}
impl LuaUserData for LuaProvinceRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the string name used to identify this registry in the province system.
        /// @return | string | The registry name passed to `newFromPng`.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        // -- getWidth --
        /// Returns the width of the province grid in cells (pixels of the source PNG).
        /// @return | integer | Grid width in cells.
        methods.add_method("getWidth", |_, this, ()| this.with_registry(|r| r.width()));
        // -- getHeight --
        /// Returns the height of the province grid in cells (pixels of the source PNG).
        /// @return | integer | Grid height in cells.
        methods.add_method("getHeight", |_, this, ()| {
            this.with_registry(|r| r.height())
        });
        // -- getAt --
        /// Returns the province ID at the given grid cell coordinates. Returns 0 if the cell is unowned (sea, wasteland, etc.).
        /// @param | x | integer | Zero-based column index.
        /// @param | y | integer | Zero-based row index.
        /// @return | integer | Province ID at (x, y), or 0 for unowned cells.
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            this.with_registry(|r| r.get_at(x, y))
        });
        // -- fitCamera --
        /// Computes camera position and zoom so the entire province map fits within the given screen dimensions.
        /// @param | screen_w | number | Screen width in pixels.
        /// @param | screen_h | number | Screen height in pixels.
        /// @param | pixel_size | number? | Size of one map cell in screen pixels (default 1.0).
        /// @return | number, number, number | Camera x, camera y, and zoom factor.
        methods.add_method(
            "fitCamera",
            |_, this, (screen_w, screen_h, pixel_size): (f32, f32, Option<f32>)| {
                let (map_w, map_h) = this.with_registry(|r| (r.width(), r.height()))?;
                let (x, y, zoom) = fit_camera_to_screen(
                    map_w,
                    map_h,
                    pixel_size.unwrap_or(1.0),
                    screen_w,
                    screen_h,
                );
                Ok((x, y, zoom))
            },
        );
        // -- screenToMap --
        /// Converts screen-space pixel coordinates to map-space floating-point coordinates using the current camera transform.
        /// @param | screen_x | number | Screen x in pixels.
        /// @param | screen_y | number | Screen y in pixels.
        /// @param | cam_x | number | Camera center x in map space.
        /// @param | cam_y | number | Camera center y in map space.
        /// @param | zoom | number | Current zoom factor.
        /// @param | pixel_size | number? | Cell size in screen pixels (default 1.0).
        /// @return | number, number | Map-space x and y.
        methods.add_method(
            "screenToMap",
            |_,
             _,
             (screen_x, screen_y, cam_x, cam_y, zoom, pixel_size): (
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
            )| {
                let (map_x, map_y) = screen_to_map(
                    screen_x,
                    screen_y,
                    cam_x,
                    cam_y,
                    zoom,
                    pixel_size.unwrap_or(1.0),
                );
                Ok((map_x, map_y))
            },
        );
        // -- screenToProvince --
        /// Converts screen-space coordinates directly to a province ID. Returns nil if the cursor is outside the map or over an unowned cell.
        /// @param | screen_x | number | Screen x in pixels.
        /// @param | screen_y | number | Screen y in pixels.
        /// @param | cam_x | number | Camera center x in map space.
        /// @param | cam_y | number | Camera center y in map space.
        /// @param | zoom | number | Current zoom factor.
        /// @param | pixel_size | number? | Cell size in screen pixels (default 1.0).
        /// @return | integer | Province ID under the cursor, or nil if none.
        methods.add_method(
            "screenToProvince",
            |_,
             this,
             (screen_x, screen_y, cam_x, cam_y, zoom, pixel_size): (
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
            )| {
                let (map_w, map_h) = this.with_registry(|r| (r.width(), r.height()))?;
                let (map_x, map_y) = screen_to_map(
                    screen_x,
                    screen_y,
                    cam_x,
                    cam_y,
                    zoom,
                    pixel_size.unwrap_or(1.0),
                );
                let Some((cell_x, cell_y)) = map_to_cell(map_x, map_y, map_w, map_h) else {
                    return Ok(None::<u32>);
                };
                let id = this.with_registry(|r| r.get_at(cell_x, cell_y))?;
                if id == 0 {
                    Ok(None::<u32>)
                } else {
                    Ok(Some(id))
                }
            },
        );
        // -- provinceCount --
        /// Returns the total number of distinct provinces in this registry (excluding ID 0).
        /// @return | integer | Count of provinces.
        methods.add_method("provinceCount", |_, this, ()| {
            this.with_registry(|r| r.province_count() as u32)
        });
        // -- provinceIds --
        /// Returns a sequential table of all province IDs in this registry.
        /// @return | table | Array of province ID numbers.
        methods.add_method("provinceIds", |lua, this, ()| {
            let ids = this.with_registry(|r| r.province_ids())?;
            let out = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() {
                out.set(i + 1, id)?;
            }
            Ok(out)
        });
        // -- adjacencies --
        /// Returns all adjacency pairs in the registry. Each entry has `province_a` and `province_b` fields representing two neighboring provinces.
        /// @return | table | Array of tables with fields: province_a (number), province_b (number).
        methods.add_method("adjacencies", |lua, this, ()| {
            let pairs = this.with_registry(|r| r.adjacency_pairs())?;
            let out = lua.create_table()?;
            for (i, (a, b)) in pairs.into_iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'province_a' operation.
                /// @return | nil | No value is returned.
                row.set("province_a", a)?;
                /// Performs the 'province_b' operation.
                /// @return | nil | No value is returned.
                row.set("province_b", b)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        // -- provinceSpans --
        /// Returns the raw span data for all provinces. Each span is a horizontal run of cells belonging to one province, useful for custom rendering or spatial analysis.
        /// @return | table | Array of tables with fields: province_id (number), y (number), x0 (number), x1 (number).
        methods.add_method("provinceSpans", |lua, this, ()| {
            let spans = this.with_registry(|r| r.spans().to_vec())?;
            let out = lua.create_table()?;
            for (i, (id, y, x0, x1)) in spans.into_iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'province_id' operation.
                /// @return | nil | No value is returned.
                row.set("province_id", id)?;
                /// Performs the 'y' operation.
                /// @return | nil | No value is returned.
                row.set("y", y)?;
                /// Performs the 'x0' operation.
                /// @return | nil | No value is returned.
                row.set("x0", x0)?;
                /// Performs the 'x1' operation.
                /// @return | nil | No value is returned.
                row.set("x1", x1)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        // -- borderSegments --
        /// Returns all border line segments between adjacent provinces. Each segment is a line from (x0,y0) to (x1,y1) separating province_a from province_b.
        /// @return | table | Array of tables with fields: province_a (number), province_b (number), x0 (number), y0 (number), x1 (number), y1 (number).
        methods.add_method("borderSegments", |lua, this, ()| {
            let segs = this.with_registry(|r| r.border_segments().to_vec())?;
            let out = lua.create_table()?;
            for (i, (a, b, x0, y0, x1, y1)) in segs.into_iter().enumerate() {
                let seg = lua.create_table()?;
                /// Performs the 'province_a' operation.
                /// @return | nil | No value is returned.
                seg.set("province_a", a)?;
                /// Performs the 'province_b' operation.
                /// @return | nil | No value is returned.
                seg.set("province_b", b)?;
                /// Performs the 'x0' operation.
                /// @return | nil | No value is returned.
                seg.set("x0", x0)?;
                /// Performs the 'y0' operation.
                /// @return | nil | No value is returned.
                seg.set("y0", y0)?;
                /// Performs the 'x1' operation.
                /// @return | nil | No value is returned.
                seg.set("x1", x1)?;
                /// Performs the 'y1' operation.
                /// @return | nil | No value is returned.
                seg.set("y1", y1)?;
                out.set(i + 1, seg)?;
            }
            Ok(out)
        });
        // -- getRevision --
        /// Returns the current change revision counter. Incremented on every mutation (color, terrain, border, fog changes). Use with `getChangesSince` for incremental updates.
        /// @return | integer | Current revision number.
        methods.add_method("getRevision", |_, this, ()| {
            this.with_registry(|r| r.revision())
        });
        // -- getProvince --
        /// Returns a snapshot table describing a single province: its ID, revision, style (political_color, terrain_type, border_style, fog_state, visibility_state), centroid, and custom attributes.
        /// @param | id | integer | Province ID to query.
        /// @return | table | Province snapshot table, or nil if the ID does not exist.
        methods.add_method("getProvince", |lua, this, id: u32| {
            let snap = this.with_registry(|r| r.get_province(id))?;
            let Some(snap) = snap else {
                return Ok(LuaValue::Nil);
            };
            let out = lua.create_table()?;
            /// Performs the 'province_id' operation.
            /// @return | nil | No value is returned.
            out.set("province_id", snap.province_id)?;
            /// Performs the 'revision' operation.
            /// @return | nil | No value is returned.
            out.set("revision", snap.revision)?;
            let style = lua.create_table()?;
            /// Performs the 'political_color' operation.
            /// @return | nil | No value is returned.
            style.set("political_color", {
                let t = lua.create_table()?;
                t.set(1, snap.style.political_color[0])?;
                t.set(2, snap.style.political_color[1])?;
                t.set(3, snap.style.political_color[2])?;
                t.set(4, snap.style.political_color[3])?;
                t
            })?;
            /// Performs the 'terrain_type' operation.
            /// @return | nil | No value is returned.
            style.set("terrain_type", snap.style.terrain_type)?;
            /// Performs the 'border_style' operation.
            /// @return | nil | No value is returned.
            style.set("border_style", snap.style.border_style)?;
            /// Performs the 'fog_state' operation.
            /// @return | nil | No value is returned.
            style.set("fog_state", snap.style.fog_state)?;
            /// Performs the 'visibility_state' operation.
            /// @return | nil | No value is returned.
            style.set("visibility_state", snap.style.visibility_state)?;
            /// Performs the 'style' operation.
            /// @return | nil | No value is returned.
            out.set("style", style)?;
            if let Some((cx, cy)) = snap.centroid {
                let ct = lua.create_table()?;
                /// Performs the 'x' operation.
                /// @return | nil | No value is returned.
                ct.set("x", cx)?;
                /// Performs the 'y' operation.
                /// @return | nil | No value is returned.
                ct.set("y", cy)?;
                /// Performs the 'centroid' operation.
                /// @return | nil | No value is returned.
                out.set("centroid", ct)?;
            }
            let attrs = lua.create_table()?;
            for (k, v) in snap.attrs {
                attrs.set(k, v)?;
            }
            /// Performs the 'attrs' operation.
            /// @return | nil | No value is returned.
            out.set("attrs", attrs)?;
            Ok(LuaValue::Table(out))
        });
        // -- getNeighbors --
        /// Returns a table of province IDs that share a border with the given province.
        /// @param | id | integer | Province ID to query.
        /// @return | table | Array of neighboring province IDs.
        methods.add_method("getNeighbors", |lua, this, id: u32| {
            let ids = this.with_registry(|r| r.get_neighbors(id))?;
            let out = lua.create_table()?;
            for (i, n) in ids.into_iter().enumerate() {
                out.set(i + 1, n)?;
            }
            Ok(out)
        });
        // -- getBorderClass --
        /// Returns the border classification string between two adjacent provinces (e.g. "river", "mountain", "sea"), or nil if no class is set.
        /// @param | a | integer | First province ID.
        /// @param | b | integer | Second province ID.
        /// @return | string | Border class name, or nil.
        methods.add_method("getBorderClass", |_, this, (a, b): (u32, u32)| {
            let class = this.with_registry(|r| r.get_border_class(a, b))?;
            Ok(class.map(|c| c.as_str().to_string()))
        });
        // -- setBorderClass --
        /// Sets the border classification between two adjacent provinces. Used to control border rendering style (e.g. rivers drawn as blue lines).
        /// @param | a | integer | First province ID.
        /// @param | b | integer | Second province ID.
        /// @param | class | string | Border class name (e.g. "river", "mountain", "sea").
        /// @return | nil | No return value.
        methods.add_method_mut(
            "setBorderClass",
            |_, this, (a, b, class): (u32, u32, String)| {
                let parsed = BorderClass::parse_str(class.as_str())
                    .ok_or_else(|| LuaError::RuntimeError("invalid border class".to_string()))?;
                this.with_registry_mut(|r| r.set_border_class(a, b, parsed))?;
                Ok(())
            },
        );
        // -- setPoliticalColor --
        /// Sets the political map color for a province. Used in political map mode rendering and change tracking.
        /// @param | id | integer | Province ID.
        /// @param | r | number | Red component (0.0–1.0).
        /// @param | g | number | Green component (0.0–1.0).
        /// @param | b | number | Blue component (0.0–1.0).
        /// @param | a | number? | Alpha component (default 1.0).
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setPoliticalColor",
            |_, this, (id, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.with_registry_mut(|reg| {
                    reg.set_political_color(id, [r, g, b, a.unwrap_or(1.0)])
                })
            },
        );
        // -- setTerrainType --
        /// Sets the terrain type index for a province. Terrain type controls which fill color or texture is used in terrain map mode.
        /// @param | id | integer | Province ID.
        /// @param | terrain_type | integer | Terrain type index (game-defined meaning).
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setTerrainType",
            |_, this, (id, terrain_type): (u32, u32)| {
                this.with_registry_mut(|reg| reg.set_terrain_type(id, terrain_type))
            },
        );
        // -- setBorderStyle --
        /// Sets the border rendering style index for a province. Controls line thickness, color, or pattern when borders are drawn.
        /// @param | id | integer | Province ID.
        /// @param | border_style | integer | Border style index (game-defined meaning).
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setBorderStyle",
            |_, this, (id, border_style): (u32, u32)| {
                this.with_registry_mut(|reg| reg.set_border_style(id, border_style))
            },
        );
        // -- setFogState --
        /// Sets the fog-of-war state for a province. Typically 0 = revealed, 1 = fogged, 2 = hidden. Controls rendering opacity or overlay.
        /// @param | id | integer | Province ID.
        /// @param | fog_state | integer | Fog state value (game-defined meaning).
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut("setFogState", |_, this, (id, fog_state): (u32, u8)| {
            this.with_registry_mut(|reg| reg.set_fog_state(id, fog_state))
        });
        // -- setVisibilityState --
        /// Sets the visibility state for a province. Used for strategic visibility layers separate from fog (e.g. scouted vs. unscouted).
        /// @param | id | integer | Province ID.
        /// @param | visibility_state | integer | Visibility state value (game-defined meaning).
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setVisibilityState",
            |_, this, (id, visibility_state): (u32, u8)| {
                this.with_registry_mut(|reg| reg.set_visibility_state(id, visibility_state))
            },
        );
        // -- setAttr --
        /// Sets a custom string attribute on a province. Attributes are returned in the `attrs` table of `getProvince` and can store arbitrary game metadata.
        /// @param | id | integer | Province ID.
        /// @param | key | string | Attribute name.
        /// @param | value | string | Attribute value.
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setAttr",
            |_, this, (id, key, value): (u32, String, String)| {
                this.with_registry_mut(|reg| reg.set_attr(id, key, value))
            },
        );
        // -- setCapital --
        /// Sets the capital marker position for a province. The capital is drawn as a small icon during `render` when `draw_capitals` is enabled.
        /// @param | id | integer | Province ID.
        /// @param | x | number | Capital x position in map space.
        /// @param | y | number | Capital y position in map space.
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut("setCapital", |_, this, (id, x, y): (u32, f32, f32)| {
            this.with_registry_mut(|reg| reg.set_capital(id, x, y))
        });
        // -- setLabelLine --
        /// Sets the label baseline for a province. The label text is rendered along the line from (ax,ay) to (bx,by), allowing curved or angled province names.
        /// @param | id | integer | Province ID.
        /// @param | ax | number | Start x of the label line in map space.
        /// @param | ay | number | Start y of the label line in map space.
        /// @param | bx | number | End x of the label line in map space.
        /// @param | by | number | End y of the label line in map space.
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut(
            "setLabelLine",
            |_, this, (id, ax, ay, bx, by): (u32, f32, f32, f32, f32)| {
                this.with_registry_mut(|reg| reg.set_label_line(id, ax, ay, bx, by))
            },
        );
        // -- setLabelText --
        /// Sets the display name text for a province. Rendered on the map when `draw_labels` is enabled in `render` options.
        /// @param | id | integer | Province ID.
        /// @param | text | string | Province display name.
        /// @return | boolean | True if the province ID exists.
        methods.add_method_mut("setLabelText", |_, this, (id, text): (u32, String)| {
            this.with_registry_mut(|reg| reg.set_label_text(id, text))
        });
        // -- importMetadataFromFiles --
        /// Bulk-imports province metadata (colors, capitals, labels, terrain) from external files (PNG color map, CSV color table, TOML province definitions, marker PNG). Returns a summary of how many provinces were mapped.
        /// @param | opts | table | Options table with fields: color_map_png (string, required), color_csv (string, required), marker_png (string?), province_toml (string?), water_terrain_tokens (table?), water_terrain_type (number?), land_terrain_type (number?), set_political_colors (boolean?), set_label_text (boolean?), set_capitals (boolean?), set_label_lines (boolean?), marker_options (table?).
        /// @return | table | Summary with fields: mapped_provinces (number), capitals_set (number), label_lines_set (number), labels_set (number).
        methods.add_method_mut("importMetadataFromFiles", |lua, this, opts: LuaTable| {
            let color_map_png =
                opts.get::<_, Option<String>>("color_map_png")?
                    .ok_or_else(|| {
                        LuaError::RuntimeError(
                        "lurek.province.importMetadataFromFiles: opts.color_map_png is required"
                            .to_string(),
                    )
                    })?;
            let color_csv = opts.get::<_, Option<String>>("color_csv")?.ok_or_else(|| {
                LuaError::RuntimeError(
                    "lurek.province.importMetadataFromFiles: opts.color_csv is required"
                        .to_string(),
                )
            })?;
            let marker_png = opts.get::<_, Option<String>>("marker_png")?;
            let province_toml = opts.get::<_, Option<String>>("province_toml")?;
            let mut water_tokens = vec!["sea".to_string(), "river".to_string()];
            if let Some(tbl) = opts.get::<_, Option<LuaTable>>("water_terrain_tokens")? {
                let mut parsed = Vec::new();
                for value in tbl.sequence_values::<String>() {
                    parsed.push(value?);
                }
                if !parsed.is_empty() {
                    water_tokens = parsed;
                }
            }
            let mut import_opts = ProvinceMetadataImportOptions::default();
            import_opts.color_map_png_path = resolve_game_path(&this.state, color_map_png.as_str());
            import_opts.marker_png_path = marker_png
                .as_ref()
                .map(|p| resolve_game_path(&this.state, p.as_str()));
            import_opts.color_csv_path = resolve_game_path(&this.state, color_csv.as_str());
            import_opts.province_toml_path = province_toml
                .as_ref()
                .map(|p| resolve_game_path(&this.state, p.as_str()));
            import_opts.water_terrain_tokens = water_tokens;
            import_opts.water_terrain_type = opts
                .get::<_, Option<u32>>("water_terrain_type")?
                .unwrap_or(import_opts.water_terrain_type);
            import_opts.land_terrain_type = opts
                .get::<_, Option<u32>>("land_terrain_type")?
                .unwrap_or(import_opts.land_terrain_type);
            import_opts.set_political_colors = opts
                .get::<_, Option<bool>>("set_political_colors")?
                .unwrap_or(import_opts.set_political_colors);
            import_opts.set_label_text = opts
                .get::<_, Option<bool>>("set_label_text")?
                .unwrap_or(import_opts.set_label_text);
            import_opts.set_capitals = opts
                .get::<_, Option<bool>>("set_capitals")?
                .unwrap_or(import_opts.set_capitals);
            import_opts.set_label_lines = opts
                .get::<_, Option<bool>>("set_label_lines")?
                .unwrap_or(import_opts.set_label_lines);
            import_opts.marker_options = marker_options_from_lua(
                opts.get::<_, Option<LuaTable>>("marker_options")?.as_ref(),
            );
            let summary = this
                .with_registry_mut(|reg| import_metadata_from_files(reg, &import_opts))?
                .map_err(LuaError::RuntimeError)?;
            let out = lua.create_table()?;
            /// Performs the 'mapped_provinces' operation.
            /// @return | nil | No value is returned.
            out.set("mapped_provinces", summary.mapped_provinces)?;
            /// Performs the 'capitals_set' operation.
            /// @return | nil | No value is returned.
            out.set("capitals_set", summary.capitals_set)?;
            /// Performs the 'label_lines_set' operation.
            /// @return | nil | No value is returned.
            out.set("label_lines_set", summary.label_lines_set)?;
            /// Performs the 'labels_set' operation.
            /// @return | nil | No value is returned.
            out.set("labels_set", summary.labels_set)?;
            Ok(out)
        });
        // -- render --
        /// Renders the province map to the screen using the current camera and style settings. Generates draw commands for fills, borders, labels, and capitals based on the provided options.
        /// @param | opts | table? | Render options: map_mode (string?), x/y/zoom/pixel_size/screen_w/screen_h (number?), draw_fills/draw_borders/draw_labels/draw_capitals (boolean?), border_width (number?), hovered_id/selected_id (integer?).
        /// @return | nil | No return value.
        methods.add_method("render", |_, this, opts: Option<LuaTable>| {
            let opts = opts;
            let mode = if let Some(ref t) = opts {
                let s = t
                    .get::<_, Option<String>>("map_mode")?
                    .unwrap_or_else(|| "political".to_string());
                ProvinceMapMode::parse_str(s.as_str()).unwrap_or(ProvinceMapMode::Political)
            } else {
                ProvinceMapMode::Political
            };
            let options = ProvinceRenderOptions {
                x: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("x").ok().flatten())
                    .unwrap_or(0.0),
                y: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("y").ok().flatten())
                    .unwrap_or(0.0),
                zoom: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("zoom").ok().flatten())
                    .unwrap_or(1.0),
                pixel_size: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("pixel_size").ok().flatten())
                    .unwrap_or(1.0),
                screen_w: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("screen_w").ok().flatten())
                    .unwrap_or(1280.0),
                screen_h: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("screen_h").ok().flatten())
                    .unwrap_or(720.0),
                map_mode: mode,
                draw_fills: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<bool>>("draw_fills").ok().flatten())
                    .unwrap_or(true),
                draw_borders: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<bool>>("draw_borders").ok().flatten())
                    .unwrap_or(true),
                draw_labels: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<bool>>("draw_labels").ok().flatten())
                    .unwrap_or(false),
                draw_capitals: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<bool>>("draw_capitals").ok().flatten())
                    .unwrap_or(true),
                border_width: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<f32>>("border_width").ok().flatten())
                    .unwrap_or(1.0),
                hovered_id: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<u32>>("hovered_id").ok().flatten()),
                selected_id: opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<u32>>("selected_id").ok().flatten()),
            };
            let font_key = {
                let st = this.state.borrow();
                st.active_font.or(st.default_font)
            };
            let cmds =
                this.with_registry(|reg| generate_render_commands(reg, &options, font_key))?;
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        // -- getChangesSince --
        /// Returns all province changes that occurred after the given revision. Each entry contains the revision number and a change record describing what was modified (political_color, terrain_type, border_style, fog_state, visibility_state, or border_class).
        /// @param | revision | integer | The revision to query from (exclusive). Pass the last known revision to get only new changes.
        /// @return | table | Array of change tables, each with a `revision` field and change-specific fields (kind, province_id, etc.).
        methods.add_method("getChangesSince", |lua, this, revision: u64| {
            let changes = this.with_registry(|r| r.get_changes_since(revision))?;
            let out = lua.create_table()?;
            for (i, (rev, ch)) in changes.into_iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'revision' operation.
                /// @return | nil | No value is returned.
                row.set("revision", rev)?;
                match ch {
                    ProvinceChange::PoliticalColor { province_id, color } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "political_color")?;
                        /// Performs the 'province_id' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_id", province_id)?;
                        let c = lua.create_table()?;
                        c.set(1, color[0])?;
                        c.set(2, color[1])?;
                        c.set(3, color[2])?;
                        c.set(4, color[3])?;
                        /// Performs the 'color' operation.
                        /// @return | nil | No value is returned.
                        row.set("color", c)?;
                    }
                    ProvinceChange::TerrainType {
                        province_id,
                        terrain_type,
                    } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "terrain_type")?;
                        /// Performs the 'province_id' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_id", province_id)?;
                        /// Performs the 'terrain_type' operation.
                        /// @return | nil | No value is returned.
                        row.set("terrain_type", terrain_type)?;
                    }
                    ProvinceChange::BorderStyle {
                        province_id,
                        border_style,
                    } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "border_style")?;
                        /// Performs the 'province_id' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_id", province_id)?;
                        /// Performs the 'border_style' operation.
                        /// @return | nil | No value is returned.
                        row.set("border_style", border_style)?;
                    }
                    ProvinceChange::FogState {
                        province_id,
                        fog_state,
                    } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "fog_state")?;
                        /// Performs the 'province_id' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_id", province_id)?;
                        /// Performs the 'fog_state' operation.
                        /// @return | nil | No value is returned.
                        row.set("fog_state", fog_state)?;
                    }
                    ProvinceChange::VisibilityState {
                        province_id,
                        visibility_state,
                    } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "visibility_state")?;
                        /// Performs the 'province_id' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_id", province_id)?;
                        /// Performs the 'visibility_state' operation.
                        /// @return | nil | No value is returned.
                        row.set("visibility_state", visibility_state)?;
                    }
                    ProvinceChange::BorderClass {
                        province_a,
                        province_b,
                        class,
                    } => {
                        /// Performs the 'kind' operation.
                        /// @return | nil | No value is returned.
                        row.set("kind", "border_class")?;
                        /// Performs the 'province_a' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_a", province_a)?;
                        /// Performs the 'province_b' operation.
                        /// @return | nil | No value is returned.
                        row.set("province_b", province_b)?;
                        /// Performs the 'class' operation.
                        /// @return | nil | No value is returned.
                        row.set("class", class.as_str())?;
                    }
                }
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        // -- type --
        /// Returns the type name string for this userdata object.
        /// @return | string | Always "LProvinceRegistry".
        methods.add_method("type", |_, _, ()| Ok("LProvinceRegistry"));
        // -- typeOf --
        /// Checks whether this object matches the given type name. Returns true for "LProvinceRegistry" and "Object".
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LProvinceRegistry" || name == "Object")
        });
    }
}
/// Registers the `lurek.province` module table and all its functions into the Lua state.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newFromPng --
    /// Creates a new province registry by loading a color-coded PNG where each unique color represents a distinct province. The PNG is parsed into a grid and adjacencies are computed automatically.
    /// @param | name | string | Unique registry name for later retrieval.
    /// @param | png_path | string | Path to the province map PNG (relative to game directory or absolute).
    /// @return | LProvinceRegistry | The newly created registry handle.
    tbl.set(
        "newFromPng",
        lua.create_function(move |_, (name, png_path): (String, String)| {
            let resolved_path = resolve_game_path(&s, png_path.as_str());
            let grid = ProvinceGrid::from_file(&resolved_path).map_err(LuaError::RuntimeError)?;
            let registry = ProvinceRegistry::from_grid(&grid);
            {
                let mut st = s.borrow_mut();
                st.province_registries.insert(name.clone(), registry);
                st.active_province_registry = Some(name.clone());
            }
            Ok(LuaProvinceRegistry {
                name,
                state: s.clone(),
            })
        })?,
    )?;
    let s = state.clone();
    // -- sanitizeMarkedPng --
    /// Pre-processes a marker PNG by replacing capital and label marker pixels with the surrounding province color. Outputs a cleaned PNG suitable for `newFromPng`. Returns a summary of pixel replacements.
    /// @param | input_png | string | Path to the source marker PNG.
    /// @param | output_png | string | Path to write the sanitized output PNG.
    /// @param | opts | table? | Marker detection thresholds: capital_min (number?), label_r_min (number?), label_g_max (number?), label_b_min (number?), search_radius (number?).
    /// @return | table | Summary with fields: replaced_pixels (number), unresolved_pixels (number).
    tbl.set(
        "sanitizeMarkedPng",
        lua.create_function(
            move |lua, (input_png, output_png, opts): (String, String, Option<LuaTable>)| {
                let in_path = resolve_game_path(&s, input_png.as_str());
                let out_path = resolve_game_path(&s, output_png.as_str());
                let marker_opts = marker_options_from_lua(opts.as_ref());
                let summary =
                    sanitize_marked_png(in_path.as_str(), out_path.as_str(), &marker_opts)
                        .map_err(LuaError::RuntimeError)?;
                let out = lua.create_table()?;
                /// Performs the 'replaced_pixels' operation.
                /// @return | nil | No value is returned.
                out.set("replaced_pixels", summary.replaced_pixels)?;
                /// Performs the 'unresolved_pixels' operation.
                /// @return | nil | No value is returned.
                out.set("unresolved_pixels", summary.unresolved_pixels)?;
                Ok(out)
            },
        )?,
    )?;
    let s = state.clone();
    // -- get --
    /// Retrieves an existing province registry by name. Returns nil if no registry with that name has been created.
    /// @param | name | string | Registry name to look up.
    /// @return | LProvinceRegistry | The registry handle, or nil if not found.
    tbl.set(
        "get",
        lua.create_function(move |_, name: String| {
            let exists = s.borrow().province_registries.contains_key(&name);
            if exists {
                Ok(Some(LuaProvinceRegistry {
                    name,
                    state: s.clone(),
                }))
            } else {
                Ok(None::<LuaProvinceRegistry>)
            }
        })?,
    )?;
    let s = state.clone();
    // -- exists --
    /// Checks whether a province registry with the given name exists.
    /// @param | name | string | Registry name to check.
    /// @return | boolean | True if the registry exists.
    tbl.set(
        "exists",
        lua.create_function(move |_, name: String| {
            Ok(s.borrow().province_registries.contains_key(&name))
        })?,
    )?;
    let s = state.clone();
    // -- remove --
    /// Removes a province registry by name and clears the active registry if it was the one removed. Returns true if a registry was actually removed.
    /// @param | name | string | Registry name to remove.
    /// @return | boolean | True if the registry existed and was removed.
    tbl.set(
        "remove",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            let removed = st.province_registries.remove(&name).is_some();
            if st.active_province_registry.as_deref() == Some(name.as_str()) {
                st.active_province_registry = None;
            }
            Ok(removed)
        })?,
    )?;
    let s = state.clone();
    // -- setActive --
    /// Sets the named registry as the active province registry. Returns false if no registry with that name exists.
    /// @param | name | string | Registry name to activate.
    /// @return | boolean | True if the registry was found and activated.
    tbl.set(
        "setActive",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            if st.province_registries.contains_key(&name) {
                st.active_province_registry = Some(name);
                Ok(true)
            } else {
                Ok(false)
            }
        })?,
    )?;
    let s = state.clone();
    // -- getActive --
    /// Returns the currently active province registry, or nil if none is set.
    /// @return | LProvinceRegistry | The active registry handle, or nil.
    tbl.set(
        "getActive",
        lua.create_function(move |_, ()| {
            let name_opt = s.borrow().active_province_registry.clone();
            Ok(name_opt.map(|name| LuaProvinceRegistry {
                name,
                state: s.clone(),
            }))
        })?,
    )?;
    // -- zoomCameraAt --
    /// Computes new camera position after zooming centered on an anchor point. Keeps the anchor point visually stationary on screen while the zoom level changes.
    /// @param | anchor_x | number | Anchor x in screen space.
    /// @param | anchor_y | number | Anchor y in screen space.
    /// @param | cam_x | number | Current camera x.
    /// @param | cam_y | number | Current camera y.
    /// @param | old_zoom | number | Previous zoom level.
    /// @param | new_zoom | number | Target zoom level.
    /// @return | number, number | New camera x and y after zoom adjustment.
    tbl.set(
        "zoomCameraAt",
        lua.create_function(
            move |_,
                  (anchor_x, anchor_y, cam_x, cam_y, old_zoom, new_zoom): (
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
            )| {
                Ok(zoom_camera_at(
                    anchor_x, anchor_y, cam_x, cam_y, old_zoom, new_zoom,
                ))
            },
        )?,
    )?;
    /// Performs the 'province' operation.
    /// @return | nil | No value is returned.
    lurek.set("province", tbl)?;
    Ok(())
}
