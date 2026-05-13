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
fn resolve_game_path(state: &Rc<RefCell<SharedState>>, path: &str) -> String {
    let st = state.borrow();
    let p = Path::new(path);
    if p.is_absolute() {
        p.to_string_lossy().into_owned()
    } else {
        st.game_dir.join(p).to_string_lossy().into_owned()
    }
}
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
#[derive(Clone)]
pub struct LuaProvinceRegistry {
    name: String,
    state: Rc<RefCell<SharedState>>,
}
impl LuaProvinceRegistry {
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
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        methods.add_method("getWidth", |_, this, ()| this.with_registry(|r| r.width()));
        methods.add_method("getHeight", |_, this, ()| {
            this.with_registry(|r| r.height())
        });
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            this.with_registry(|r| r.get_at(x, y))
        });
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
        methods.add_method("provinceCount", |_, this, ()| {
            this.with_registry(|r| r.province_count() as u32)
        });
        methods.add_method("provinceIds", |lua, this, ()| {
            let ids = this.with_registry(|r| r.province_ids())?;
            let out = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() {
                out.set(i + 1, id)?;
            }
            Ok(out)
        });
        methods.add_method("adjacencies", |lua, this, ()| {
            let pairs = this.with_registry(|r| r.adjacency_pairs())?;
            let out = lua.create_table()?;
            for (i, (a, b)) in pairs.into_iter().enumerate() {
                let row = lua.create_table()?;
                row.set("province_a", a)?;
                row.set("province_b", b)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        methods.add_method("provinceSpans", |lua, this, ()| {
            let spans = this.with_registry(|r| r.spans().to_vec())?;
            let out = lua.create_table()?;
            for (i, (id, y, x0, x1)) in spans.into_iter().enumerate() {
                let row = lua.create_table()?;
                row.set("province_id", id)?;
                row.set("y", y)?;
                row.set("x0", x0)?;
                row.set("x1", x1)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        methods.add_method("borderSegments", |lua, this, ()| {
            let segs = this.with_registry(|r| r.border_segments().to_vec())?;
            let out = lua.create_table()?;
            for (i, (a, b, x0, y0, x1, y1)) in segs.into_iter().enumerate() {
                let seg = lua.create_table()?;
                seg.set("province_a", a)?;
                seg.set("province_b", b)?;
                seg.set("x0", x0)?;
                seg.set("y0", y0)?;
                seg.set("x1", x1)?;
                seg.set("y1", y1)?;
                out.set(i + 1, seg)?;
            }
            Ok(out)
        });
        methods.add_method("getRevision", |_, this, ()| {
            this.with_registry(|r| r.revision())
        });
        methods.add_method("getProvince", |lua, this, id: u32| {
            let snap = this.with_registry(|r| r.get_province(id))?;
            let Some(snap) = snap else {
                return Ok(LuaValue::Nil);
            };
            let out = lua.create_table()?;
            out.set("province_id", snap.province_id)?;
            out.set("revision", snap.revision)?;
            let style = lua.create_table()?;
            style.set("political_color", {
                let t = lua.create_table()?;
                t.set(1, snap.style.political_color[0])?;
                t.set(2, snap.style.political_color[1])?;
                t.set(3, snap.style.political_color[2])?;
                t.set(4, snap.style.political_color[3])?;
                t
            })?;
            style.set("terrain_type", snap.style.terrain_type)?;
            style.set("border_style", snap.style.border_style)?;
            style.set("fog_state", snap.style.fog_state)?;
            style.set("visibility_state", snap.style.visibility_state)?;
            out.set("style", style)?;
            if let Some((cx, cy)) = snap.centroid {
                let ct = lua.create_table()?;
                ct.set("x", cx)?;
                ct.set("y", cy)?;
                out.set("centroid", ct)?;
            }
            let attrs = lua.create_table()?;
            for (k, v) in snap.attrs {
                attrs.set(k, v)?;
            }
            out.set("attrs", attrs)?;
            Ok(LuaValue::Table(out))
        });
        methods.add_method("getNeighbors", |lua, this, id: u32| {
            let ids = this.with_registry(|r| r.get_neighbors(id))?;
            let out = lua.create_table()?;
            for (i, n) in ids.into_iter().enumerate() {
                out.set(i + 1, n)?;
            }
            Ok(out)
        });
        methods.add_method("getBorderClass", |_, this, (a, b): (u32, u32)| {
            let class = this.with_registry(|r| r.get_border_class(a, b))?;
            Ok(class.map(|c| c.as_str().to_string()))
        });
        methods.add_method_mut(
            "setBorderClass",
            |_, this, (a, b, class): (u32, u32, String)| {
                let parsed = BorderClass::parse_str(class.as_str())
                    .ok_or_else(|| LuaError::RuntimeError("invalid border class".to_string()))?;
                this.with_registry_mut(|r| r.set_border_class(a, b, parsed))?;
                Ok(())
            },
        );
        methods.add_method_mut(
            "setPoliticalColor",
            |_, this, (id, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.with_registry_mut(|reg| {
                    reg.set_political_color(id, [r, g, b, a.unwrap_or(1.0)])
                })
            },
        );
        methods.add_method_mut(
            "setTerrainType",
            |_, this, (id, terrain_type): (u32, u32)| {
                this.with_registry_mut(|reg| reg.set_terrain_type(id, terrain_type))
            },
        );
        methods.add_method_mut(
            "setBorderStyle",
            |_, this, (id, border_style): (u32, u32)| {
                this.with_registry_mut(|reg| reg.set_border_style(id, border_style))
            },
        );
        methods.add_method_mut("setFogState", |_, this, (id, fog_state): (u32, u8)| {
            this.with_registry_mut(|reg| reg.set_fog_state(id, fog_state))
        });
        methods.add_method_mut(
            "setVisibilityState",
            |_, this, (id, visibility_state): (u32, u8)| {
                this.with_registry_mut(|reg| reg.set_visibility_state(id, visibility_state))
            },
        );
        methods.add_method_mut(
            "setAttr",
            |_, this, (id, key, value): (u32, String, String)| {
                this.with_registry_mut(|reg| reg.set_attr(id, key, value))
            },
        );
        methods.add_method_mut("setCapital", |_, this, (id, x, y): (u32, f32, f32)| {
            this.with_registry_mut(|reg| reg.set_capital(id, x, y))
        });
        methods.add_method_mut(
            "setLabelLine",
            |_, this, (id, ax, ay, bx, by): (u32, f32, f32, f32, f32)| {
                this.with_registry_mut(|reg| reg.set_label_line(id, ax, ay, bx, by))
            },
        );
        methods.add_method_mut("setLabelText", |_, this, (id, text): (u32, String)| {
            this.with_registry_mut(|reg| reg.set_label_text(id, text))
        });
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
            out.set("mapped_provinces", summary.mapped_provinces)?;
            out.set("capitals_set", summary.capitals_set)?;
            out.set("label_lines_set", summary.label_lines_set)?;
            out.set("labels_set", summary.labels_set)?;
            Ok(out)
        });
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
        methods.add_method("getChangesSince", |lua, this, revision: u64| {
            let changes = this.with_registry(|r| r.get_changes_since(revision))?;
            let out = lua.create_table()?;
            for (i, (rev, ch)) in changes.into_iter().enumerate() {
                let row = lua.create_table()?;
                row.set("revision", rev)?;
                match ch {
                    ProvinceChange::PoliticalColor { province_id, color } => {
                        row.set("kind", "political_color")?;
                        row.set("province_id", province_id)?;
                        let c = lua.create_table()?;
                        c.set(1, color[0])?;
                        c.set(2, color[1])?;
                        c.set(3, color[2])?;
                        c.set(4, color[3])?;
                        row.set("color", c)?;
                    }
                    ProvinceChange::TerrainType {
                        province_id,
                        terrain_type,
                    } => {
                        row.set("kind", "terrain_type")?;
                        row.set("province_id", province_id)?;
                        row.set("terrain_type", terrain_type)?;
                    }
                    ProvinceChange::BorderStyle {
                        province_id,
                        border_style,
                    } => {
                        row.set("kind", "border_style")?;
                        row.set("province_id", province_id)?;
                        row.set("border_style", border_style)?;
                    }
                    ProvinceChange::FogState {
                        province_id,
                        fog_state,
                    } => {
                        row.set("kind", "fog_state")?;
                        row.set("province_id", province_id)?;
                        row.set("fog_state", fog_state)?;
                    }
                    ProvinceChange::VisibilityState {
                        province_id,
                        visibility_state,
                    } => {
                        row.set("kind", "visibility_state")?;
                        row.set("province_id", province_id)?;
                        row.set("visibility_state", visibility_state)?;
                    }
                    ProvinceChange::BorderClass {
                        province_a,
                        province_b,
                        class,
                    } => {
                        row.set("kind", "border_class")?;
                        row.set("province_a", province_a)?;
                        row.set("province_b", province_b)?;
                        row.set("class", class.as_str())?;
                    }
                }
                out.set(i + 1, row)?;
            }
            Ok(out)
        });
        methods.add_method("type", |_, _, ()| Ok("LProvinceRegistry"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LProvinceRegistry" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
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
                out.set("replaced_pixels", summary.replaced_pixels)?;
                out.set("unresolved_pixels", summary.unresolved_pixels)?;
                Ok(out)
            },
        )?,
    )?;
    let s = state.clone();
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
    tbl.set(
        "exists",
        lua.create_function(move |_, name: String| {
            Ok(s.borrow().province_registries.contains_key(&name))
        })?,
    )?;
    let s = state.clone();
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
    lurek.set("province", tbl)?;
    Ok(())
}
