use super::camera_api::LuaCamera2D;
use super::render_api::LuaImage;
use super::SharedState;
use crate::minimap::{ColorMode, FogLevel, LayerData, MarkerAnimation, Minimap};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
fn parse_color_table(tbl: LuaTable) -> LuaResult<[u8; 4]> {
    let r: u8 = tbl.get(1).unwrap_or(255);
    let g: u8 = tbl.get(2).unwrap_or(255);
    let b: u8 = tbl.get(3).unwrap_or(255);
    let a: u8 = tbl.get(4).unwrap_or(255);
    Ok([r, g, b, a])
}
fn parse_lua_image_icon(
    image_ud: LuaAnyUserData,
    default_width: Option<f32>,
    default_height: Option<f32>,
    method_name: &str,
) -> LuaResult<(
    crate::runtime::resource_keys::TextureKey,
    f32,
    f32,
    f32,
    f32,
)> {
    let image = image_ud.borrow::<LuaImage>().map_err(|_| {
        LuaError::RuntimeError(format!(
            "lurek.minimap: {} expects an LImage from lurek.render.newImage()",
            method_name
        ))
    })?;
    let (texture_width, texture_height) = {
        let state = image.state.borrow();
        let Some(texture) = state.textures.get(image.key) else {
            return Err(LuaError::RuntimeError(format!(
                "lurek.minimap: {} received an image whose texture is no longer resident",
                method_name
            )));
        };
        (texture.width as f32, texture.height as f32)
    };
    Ok((
        image.key,
        texture_width,
        texture_height,
        default_width.unwrap_or(texture_width),
        default_height.unwrap_or(texture_height),
    ))
}
pub struct LuaMinimap {
    inner: Minimap,
    state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaMinimap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getGridWidth", |_, this, ()| Ok(this.inner.grid_width()));
        methods.add_method("getGridHeight", |_, this, ()| Ok(this.inner.grid_height()));
        methods.add_method("getCellCount", |_, this, ()| Ok(this.inner.grid_size()));
        methods.add_method("getGridSize", |_, this, ()| {
            Ok((this.inner.grid_width(), this.inner.grid_height()))
        });
        methods.add_method("getDisplayWidth", |_, this, ()| {
            Ok(this.inner.display_width())
        });
        methods.add_method("getDisplayHeight", |_, this, ()| {
            Ok(this.inner.display_height())
        });
        methods.add_method("getDisplaySize", |_, this, ()| {
            Ok((this.inner.display_width(), this.inner.display_height()))
        });
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.set_display_size(w, h);
            Ok(())
        });
        methods.add_method_mut(
            "setTerrain",
            |_, this, (x, y, terrain_type): (u32, u32, u32)| {
                if x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: setTerrain coordinates are 1-based".into(),
                    ));
                }
                this.inner.set_terrain(x - 1, y - 1, terrain_type);
                Ok(())
            },
        );
        methods.add_method("getTerrain", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getTerrain coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_terrain(x - 1, y - 1))
        });
        methods.add_method_mut("setTerrainData", |_, this, data: LuaTable| {
            let len = data.len()? as usize;
            let mut values = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u32 = data.get(i)?;
                values.push(v);
            }
            this.inner.set_terrain_data(&values);
            Ok(())
        });
        methods.add_method_mut(
            "setTerrainColor",
            |_, this, (terrain_type, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_terrain_color(terrain_type, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut(
            "setTileDescription",
            |_, this, (type_id, desc): (u32, String)| {
                this.inner.set_tile_description(type_id, desc);
                Ok(())
            },
        );
        methods.add_method("getTileDescription", |_, this, type_id: u32| {
            Ok(this
                .inner
                .get_tile_description(type_id)
                .map(|s| s.to_string()))
        });
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.set_fog_enabled(enabled);
            Ok(())
        });
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog_enabled()));
        methods.add_method_mut("setFogLevel", |_, this, (x, y, level): (u32, u32, u8)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: setFogLevel coordinates are 1-based".into(),
                ));
            }
            this.inner
                .set_fog_level(x - 1, y - 1, FogLevel::from_u8(level));
            Ok(())
        });
        methods.add_method("getFogLevel", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getFogLevel coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_fog_level(x - 1, y - 1) as u8)
        });
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_fog_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog_color();
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut("setFogData", |_, this, data: LuaTable| {
            let len = data.len()? as usize;
            let mut bytes = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u8 = data.get(i)?;
                bytes.push(v);
            }
            this.inner.set_fog_data(&bytes);
            Ok(())
        });
        methods.add_method_mut(
            "addObjectType",
            |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                let idx = this
                    .inner
                    .add_object_type(name, [r, g, b, a.unwrap_or(1.0)]);
                Ok(idx + 1)
            },
        );
        methods.add_method_mut(
            "setObjectTypeVisible",
            |_, this, (type_idx, visible): (usize, bool)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner.set_object_type_visible(type_idx - 1, visible);
                Ok(())
            },
        );
        methods.add_method("isObjectTypeVisible", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: object type index is 1-based".into(),
                ));
            }
            Ok(this.inner.is_object_type_visible(type_idx - 1))
        });
        methods.add_method("getObjectTypeCount", |_, this, ()| {
            Ok(this.inner.object_type_count())
        });
        methods.add_method_mut(
            "setObjectTypeTexture",
            |_,
             this,
             (type_idx, image_ud, width, height): (
                usize,
                LuaAnyUserData,
                Option<f32>,
                Option<f32>,
            )| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                let (texture_key, tex_w, tex_h, display_w, display_h) =
                    parse_lua_image_icon(image_ud, width, height, "setObjectTypeTexture")?;
                this.inner.set_object_type_texture(
                    type_idx - 1,
                    texture_key,
                    tex_w,
                    tex_h,
                    display_w,
                    display_h,
                );
                Ok(())
            },
        );
        methods.add_method_mut("clearObjectTypeTexture", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: object type index is 1-based".into(),
                ));
            }
            this.inner.clear_object_type_texture(type_idx - 1);
            Ok(())
        });
        methods.add_method_mut(
            "setObject",
            |_, this, (id, x, y, type_idx, owner): (u32, f32, f32, usize, Option<u32>)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner
                    .set_object(id, x, y, type_idx - 1, owner.unwrap_or(0));
                Ok(())
            },
        );
        methods.add_method_mut("removeObject", |_, this, id: u32| {
            Ok(this.inner.remove_object(id))
        });
        methods.add_method_mut("clearObjects", |_, this, ()| {
            this.inner.clear_objects();
            Ok(())
        });
        methods.add_method("getObjectCount", |_, this, ()| {
            Ok(this.inner.object_count())
        });
        methods.add_method_mut(
            "setOwnerColor",
            |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });
        methods.add_method_mut("setColorMode", |_, this, mode: String| {
            let cm = ColorMode::parse_mode(&mode).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "lurek.minimap: unknown color mode '{}', expected 'terrain' or 'political'",
                    mode
                ))
            })?;
            this.inner.set_color_mode(cm);
            Ok(())
        });
        methods.add_method("getColorMode", |_, this, ()| {
            Ok(this.inner.color_mode().as_str())
        });
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.set_zoom(zoom);
            Ok(())
        });
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.zoom()));
        methods.add_method_mut("setCenter", |_, this, (x, y): (f32, f32)| {
            this.inner.set_center(x, y);
            Ok(())
        });
        methods.add_method_mut("trackCamera", |_, this, camera_ud: LuaAnyUserData| {
            let camera = camera_ud.borrow::<LuaCamera2D>().map_err(|_| {
                LuaError::RuntimeError(
                    "lurek.minimap: trackCamera expects an LCamera from lurek.camera.newCamera()"
                        .into(),
                )
            })?;
            let (camera_x, camera_y) = camera.position();
            let (vx, vy, vw, vh) = camera.visible_area();
            this.inner.set_center(camera_x, camera_y);
            this.inner.set_viewport_rect(vx, vy, vw, vh);
            Ok(())
        });
        methods.add_method_mut(
            "revealRadius",
            |_, this, (cx, cy, radius): (f32, f32, f32)| {
                this.inner.reveal_radius(cx, cy, radius);
                Ok(())
            },
        );
        methods.add_method("getCenter", |_, this, ()| {
            Ok((this.inner.center_x(), this.inner.center_y()))
        });
        methods.add_method("getCenterX", |_, this, ()| Ok(this.inner.center_x()));
        methods.add_method("getCenterY", |_, this, ()| Ok(this.inner.center_y()));
        methods.add_method_mut(
            "setViewportRect",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.set_viewport_rect(x, y, w, h);
                Ok(())
            },
        );
        methods.add_method_mut("clearViewportRect", |_, this, ()| {
            this.inner.clear_viewport_rect();
            Ok(())
        });
        methods.add_method("getViewportRect", |_, this, ()| {
            match this.inner.viewport_rect() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });
        methods.add_method_mut("setViewportVisible", |_, this, visible: bool| {
            this.inner.set_viewport_visible(visible);
            Ok(())
        });
        methods.add_method("isViewportVisible", |_, this, ()| {
            Ok(this.inner.viewport_visible())
        });
        methods.add_method_mut(
            "setViewportColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_viewport_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );
        methods.add_method("getViewportColor", |_, this, ()| {
            let c = this.inner.viewport_color();
            Ok((c[0], c[1], c[2], c[3]))
        });
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addPing",
            |_,
             this,
             (x, y, duration, r, g, b, a): (
                f32,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let color = [
                    r.unwrap_or(1.0),
                    g.unwrap_or(1.0),
                    b.unwrap_or(0.0),
                    a.unwrap_or(1.0),
                ];
                this.inner.add_ping(x, y, duration, color);
                Ok(())
            },
        );
        methods.add_method("getPingCount", |_, this, ()| Ok(this.inner.ping_count()));
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addMarker",
            |_,
             this,
             (x, y, desc, r, g, b, a): (
                f32,
                f32,
                Option<String>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let color = [
                    r.unwrap_or(1.0),
                    g.unwrap_or(0.0),
                    b.unwrap_or(0.0),
                    a.unwrap_or(1.0),
                ];
                let id = this.inner.add_marker(x, y, desc.unwrap_or_default(), color);
                Ok(id)
            },
        );
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.remove_marker(id))
        });
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.has_marker(id))
        });
        methods.add_method("getMarkerDescription", |_, this, id: u32| {
            Ok(this.inner.get_marker_description(id).map(|s| s.to_string()))
        });
        methods.add_method("getMarkerCount", |_, this, ()| {
            Ok(this.inner.marker_count())
        });
        methods.add_method_mut(
            "setMarkerTexture",
            |_, this, (id, image_ud, width, height): (u32, LuaAnyUserData, Option<f32>, Option<f32>)| {
                let (texture_key, tex_w, tex_h, display_w, display_h) =
                    parse_lua_image_icon(image_ud, width, height, "setMarkerTexture")?;
                this.inner.set_marker_texture(id, texture_key, tex_w, tex_h, display_w, display_h);
                Ok(())
            },
        );
        methods.add_method_mut("clearMarkerTexture", |_, this, id: u32| {
            this.inner.clear_marker_texture(id);
            Ok(())
        });
        methods.add_method_mut(
            "setMarkerAnimation",
            |_, this, (id, anim_type, speed): (u32, String, f32)| {
                let anim = match anim_type.as_str() {
                    "blink" => MarkerAnimation::Blink { speed, phase: 0.0 },
                    "pulse" => MarkerAnimation::Pulse { speed, phase: 0.0 },
                    "rotate" => MarkerAnimation::Rotate { speed, angle: 0.0 },
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "lurek.minimap: unknown animation type '{}', \
                             expected 'blink', 'pulse', or 'rotate'",
                            other
                        )))
                    }
                };
                this.inner.set_marker_animation(id, anim);
                Ok(())
            },
        );
        methods.add_method_mut("clearMarkerAnimation", |_, this, id: u32| {
            this.inner.clear_marker_animation(id);
            Ok(())
        });
        methods.add_method_mut(
            "drawLine",
            |_, this, (x1, y1, x2, y2, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_line(x1, y1, x2, y2, color);
                Ok(())
            },
        );
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_rect(x, y, w, h, color);
                Ok(())
            },
        );
        methods.add_method_mut("clearOverlay", |_, this, ()| {
            this.inner.clear_overlay();
            Ok(())
        });
        methods.add_method("getOverlayShapeCount", |_, this, ()| {
            Ok(this.inner.overlay_shapes().len())
        });
        methods.add_method_mut(
            "showPath",
            |_, this, (points_tbl, color_tbl): (LuaTable, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                let len = points_tbl.len()? as usize;
                let mut points = Vec::with_capacity(len);
                for i in 1..=len {
                    let pt: LuaTable = points_tbl.get(i)?;
                    let x: f32 = pt.get(1)?;
                    let y: f32 = pt.get(2)?;
                    points.push((x, y));
                }
                let id = this.inner.show_path(points, color);
                Ok(id)
            },
        );
        methods.add_method_mut("clearPath", |_, this, id: Option<u32>| {
            this.inner.clear_path(id);
            Ok(())
        });
        methods.add_method("getPathCount", |_, this, ()| Ok(this.inner.paths().len()));
        methods.add_method_mut("setLayer", |_, this, layer: usize| {
            this.inner.set_layer(layer);
            Ok(())
        });
        methods.add_method("getLayer", |_, this, ()| Ok(this.inner.get_layer()));
        methods.add_method("getLayerCount", |_, this, ()| Ok(this.inner.layer_count()));
        methods.add_method_mut(
            "setLayerData",
            |_, this, (layer, data_tbl): (usize, LuaTable)| {
                let len = data_tbl.len()? as usize;
                let mut cells = Vec::with_capacity(len);
                for i in 1..=len {
                    let v: u8 = data_tbl.get(i)?;
                    cells.push(v);
                }
                let w = this.inner.grid_width();
                let h = this.inner.grid_height();
                this.inner.set_layer_data(
                    layer,
                    LayerData {
                        cells,
                        width: w,
                        height: h,
                    },
                );
                Ok(())
            },
        );
        methods.add_method("getLayerData", |lua, this, layer: usize| {
            let Some(layer_data) = this.inner.layer_data(layer) else {
                return Ok(None::<LuaTable>);
            };
            let tbl = lua.create_table()?;
            for (index, cell) in layer_data.cells.iter().enumerate() {
                tbl.set(index + 1, *cell)?;
            }
            Ok(Some(tbl))
        });
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.set_anti_alias(enabled);
            Ok(())
        });
        methods.add_method("isAntiAlias", |_, this, ()| Ok(this.inner.anti_alias()));
        methods.add_method_mut("setClickable", |_, this, enabled: bool| {
            this.inner.set_clickable(enabled);
            Ok(())
        });
        methods.add_method("isClickable", |_, this, ()| Ok(this.inner.is_clickable()));
        methods.add_method(
            "getHoverInfo",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .get_hover_info(sx, sy, mx, my)
                    .map(|s| s.to_string()))
            },
        );
        methods.add_method(
            "screenToGrid",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.screen_to_grid(sx, sy, mx, my))
            },
        );
        methods.add_method(
            "gridToScreen",
            |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.grid_to_screen(gx, gy, mx, my))
            },
        );
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LMinimap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMinimap" || name == "Minimap" || name == "Object")
        });
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let sx = x.unwrap_or(0.0);
            let sy = y.unwrap_or(0.0);
            let cmds = this.inner.build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        methods.add_method("drawToImage", |_, this, pixel_size: u32| {
            let img = this.inner.draw_to_image(pixel_size);
            Ok(img)
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set("newMinimap", lua.create_function(
            move |_, (grid_w, grid_h, display_w, display_h): (u32, u32, Option<u32>, Option<u32>)| {
                let dw = display_w.unwrap_or(200);
                let dh = display_h.unwrap_or(200);
                Ok(LuaMinimap {
                    inner: Minimap::new(grid_w, grid_h, dw, dh),
                    state: s.clone(),
                })
            },
        )?,
    )?;
    lurek.set("minimap", tbl)?;
    Ok(())
}
