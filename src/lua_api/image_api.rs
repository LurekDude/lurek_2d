use super::SharedState;
use crate::image::serial;
use crate::image::{CompressedImageData, ImageData, LayeredImage, ProvinceGrid};
use crate::render::{DrawMode, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
#[derive(Clone)]
struct ProvinceShapeCacheEntry {
    r: f32,
    g: f32,
    b: f32,
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,
    vertices: Vec<f32>,
}
pub struct LuaProvinceGrid {
    inner: ProvinceGrid,
    state: Rc<RefCell<SharedState>>,
    shape_cache: Option<Vec<ProvinceShapeCacheEntry>>,
}
impl LuaUserData for LuaProvinceGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_at(x, y))
        });
        methods.add_method("provinceCount", |_, this, ()| {
            Ok(this.inner.province_count())
        });
        methods.add_method("adjacencies", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, &(a, b, bp)) in this.inner.adjacencies().iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("province_a", a)?;
                entry.set("province_b", b)?;
                entry.set("border_pixels", bp)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        methods.add_method("provinceSpans", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (id, y, x0, x1)) in this.inner.province_spans().into_iter().enumerate() {
                let row = lua.create_table()?;
                row.set("province_id", id)?;
                row.set("y", y)?;
                row.set("x0", x0)?;
                row.set("x1", x1)?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });
        methods.add_method("borderSegments", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (a, b, x0, y0, x1, y1)) in this.inner.border_segments().into_iter().enumerate()
            {
                let seg = lua.create_table()?;
                seg.set("province_a", a)?;
                seg.set("province_b", b)?;
                seg.set("x0", x0)?;
                seg.set("y0", y0)?;
                seg.set("x1", x1)?;
                seg.set("y1", y1)?;
                t.set(i + 1, seg)?;
            }
            Ok(t)
        });
        methods.add_method("getPolygons", |lua, this, ()| {
            let map = this.inner.province_polygons();
            let out = lua.create_table()?;
            let mut idx = 1usize;
            for (id, rings) in &map {
                let entry = lua.create_table()?;
                entry.set("province_id", *id)?;
                let rings_tbl = lua.create_table()?;
                for (ri, ring) in rings.iter().enumerate() {
                    let pts = lua.create_table()?;
                    for (pi, &(x, y)) in ring.iter().enumerate() {
                        let pt = lua.create_table()?;
                        pt.set(1, x)?;
                        pt.set(2, y)?;
                        pts.set(pi + 1, pt)?;
                    }
                    rings_tbl.set(ri + 1, pts)?;
                }
                entry.set("rings", rings_tbl)?;
                out.set(idx, entry)?;
                idx += 1;
            }
            Ok(out)
        });
        methods.add_method("getPolygonsSimplified", |lua, this, ()| {
            let map = this.inner.province_polygons_simplified();
            let out = lua.create_table()?;
            let mut idx = 1usize;
            for (id, rings) in &map {
                let entry = lua.create_table()?;
                entry.set("province_id", *id)?;
                let rings_tbl = lua.create_table()?;
                for (ri, ring) in rings.iter().enumerate() {
                    let pts = lua.create_table()?;
                    for (pi, &(x, y)) in ring.iter().enumerate() {
                        let pt = lua.create_table()?;
                        pt.set(1, x)?;
                        pt.set(2, y)?;
                        pts.set(pi + 1, pt)?;
                    }
                    rings_tbl.set(ri + 1, pts)?;
                }
                entry.set("rings", rings_tbl)?;
                out.set(idx, entry)?;
                idx += 1;
            }
            Ok(out)
        });
        methods.add_method_mut("drawShapes", |_, this, args: LuaMultiValue| {
            let viewport = if args.is_empty() {
                None
            } else {
                let mut it = args.into_iter();
                let next_f32 = |v: Option<LuaValue>| -> Result<f32, LuaError> {
                    match v {
                        Some(LuaValue::Integer(n)) => Ok(n as f32),
                        Some(LuaValue::Number(n)) => Ok(n as f32),
                        Some(other) => Err(LuaError::RuntimeError(format!(
                            "drawShapes expected numeric viewport argument, got {:?}",
                            other.type_name()
                        ))),
                        None => Err(LuaError::RuntimeError(
                            "drawShapes expected four viewport numbers".into(),
                        )),
                    }
                };
                let x = next_f32(it.next())?;
                let y = next_f32(it.next())?;
                let w = next_f32(it.next())?;
                let h = next_f32(it.next())?;
                if it.next().is_some() {
                    return Err(LuaError::RuntimeError(
                        "drawShapes accepts either no args or four viewport numbers".into(),
                    ));
                }
                Some((x, y, w, h))
            };
            if this.shape_cache.is_none() {
                let polygons = this.inner.province_polygons_simplified();
                let mut cache: Vec<ProvinceShapeCacheEntry> = Vec::new();
                for (&id, rings) in &polygons {
                    if let Some((r, g, b)) = this.inner.province_color(id) {
                        let rf = r as f32 / 255.0;
                        let gf = g as f32 / 255.0;
                        let bf = b as f32 / 255.0;
                        for ring in rings {
                            if ring.len() < 3 {
                                continue;
                            }
                            let ring_points: &[(u32, u32)] =
                                if ring.len() >= 2 && ring.first() == ring.last() {
                                    &ring[..ring.len() - 1]
                                } else {
                                    ring.as_slice()
                                };
                            if ring_points.len() < 3 {
                                continue;
                            }
                            let verts: Vec<f32> = ring_points
                                .iter()
                                .flat_map(|&(px, py)| [px as f32, py as f32])
                                .collect();
                            let mut min_x = f32::INFINITY;
                            let mut min_y = f32::INFINITY;
                            let mut max_x = f32::NEG_INFINITY;
                            let mut max_y = f32::NEG_INFINITY;
                            for chunk in verts.chunks_exact(2) {
                                let x = chunk[0];
                                let y = chunk[1];
                                min_x = min_x.min(x);
                                min_y = min_y.min(y);
                                max_x = max_x.max(x);
                                max_y = max_y.max(y);
                            }
                            cache.push(ProvinceShapeCacheEntry {
                                r: rf,
                                g: gf,
                                b: bf,
                                min_x,
                                min_y,
                                max_x,
                                max_y,
                                vertices: verts,
                            });
                        }
                    }
                }
                this.shape_cache = Some(cache);
            }
            let (view_x, view_y, view_w, view_h) = viewport.unwrap_or((
                f32::NEG_INFINITY,
                f32::NEG_INFINITY,
                f32::INFINITY,
                f32::INFINITY,
            ));
            let view_x2 = view_x + view_w;
            let view_y2 = view_y + view_h;
            let saved_color = this.state.borrow().current_color;
            let mut emitted = 0usize;
            {
                let mut st = this.state.borrow_mut();
                for entry in this.shape_cache.as_ref().unwrap() {
                    if entry.max_x < view_x
                        || entry.min_x > view_x2
                        || entry.max_y < view_y
                        || entry.min_y > view_y2
                    {
                        continue;
                    }
                    st.render_commands
                        .push(RenderCommand::SetColor(entry.r, entry.g, entry.b, 1.0));
                    st.render_commands.push(RenderCommand::Polygon {
                        mode: DrawMode::Fill,
                        vertices: entry.vertices.clone(),
                    });
                    emitted += 1;
                }
                st.render_commands.push(RenderCommand::SetColor(
                    saved_color[0],
                    saved_color[1],
                    saved_color[2],
                    saved_color[3],
                ));
                st.current_color = saved_color;
            }
            Ok(emitted as u32)
        });
        methods.add_method("type", |_, _, ()| Ok("LProvinceGrid"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LProvinceGrid" || name == "Object")
        });
        methods.add_method("serializeShapeData", |lua, this, ()| {
            let data = this.inner.serialize_shape_data();
            lua.create_string(&data)
        });
        methods.add_method("deserializeShapeData", |lua, _, bytes: LuaString| {
            let data = bytes.as_bytes();
            if let Some((spans, segs)) = ProvinceGrid::deserialize_shape_data(data) {
                let result = lua.create_table()?;
                let spans_tbl = lua.create_table()?;
                for (i, (id, y, x0, x1)) in spans.into_iter().enumerate() {
                    let row = lua.create_table()?;
                    row.set("province_id", id)?;
                    row.set("y", y)?;
                    row.set("x0", x0)?;
                    row.set("x1", x1)?;
                    spans_tbl.set(i + 1, row)?;
                }
                result.set("spans", spans_tbl)?;
                let segs_tbl = lua.create_table()?;
                for (i, (a, b, x0, y0, x1, y1)) in segs.into_iter().enumerate() {
                    let seg = lua.create_table()?;
                    seg.set("province_a", a)?;
                    seg.set("province_b", b)?;
                    seg.set("x0", x0)?;
                    seg.set("y0", y0)?;
                    seg.set("x1", x1)?;
                    seg.set("y1", y1)?;
                    segs_tbl.set(i + 1, seg)?;
                }
                result.set("segments", segs_tbl)?;
                Ok(LuaValue::Table(result))
            } else {
                Ok(LuaValue::Nil)
            }
        });
    }
}
pub struct LuaLayeredImage {
    inner: LayeredImage,
}
impl LuaUserData for LuaLayeredImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        methods.add_method("layerCount", |_, this, ()| Ok(this.inner.layer_count()));
        methods.add_method_mut("addLayer", |_, this, name: Option<String>| {
            let label = name.unwrap_or_else(|| format!("Layer {}", this.inner.layer_count() + 1));
            let idx = this.inner.add_layer(label);
            Ok(idx + 1)
        });
        methods.add_method_mut("removeLayer", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.remove_layer(index - 1).is_some())
        });
        methods.add_method("getLayer", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| lua.create_userdata(l.data.clone()))
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))?
        });
        methods.add_method_mut(
            "setLayer",
            |_, this, (index, img): (usize, LuaAnyUserData)| {
                if index == 0 {
                    return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
                }
                let src = img
                    .borrow::<ImageData>()
                    .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
                Ok(this.inner.set_layer_image(index - 1, &src))
            },
        );
        methods.add_method("getOpacity", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.opacity)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        methods.add_method_mut("setOpacity", |_, this, (index, opacity): (usize, f32)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_opacity(index - 1, opacity))
        });
        methods.add_method("isVisible", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.visible)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        methods.add_method_mut("setVisible", |_, this, (index, visible): (usize, bool)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_visible(index - 1, visible))
        });
        methods.add_method("getName", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.name.clone())
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        methods.add_method_mut("setName", |_, this, (index, name): (usize, String)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_name(index - 1, name))
        });
        methods.add_method_mut("swapLayers", |_, this, (a, b): (usize, usize)| {
            if a == 0 || b == 0 {
                return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
            }
            Ok(this.inner.swap_layers(a - 1, b - 1))
        });
        methods.add_method_mut(
            "moveLayer",
            |_, this, (from_idx, to_idx): (usize, usize)| {
                if from_idx == 0 || to_idx == 0 {
                    return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
                }
                Ok(this.inner.move_layer(from_idx - 1, to_idx - 1))
            },
        );
        methods.add_method("merge", |lua, this, ()| {
            lua.create_userdata(this.inner.merge())
        });
        methods.add_method("save", |_, this, path: String| {
            serial::save_layered(&this.inner, &path).map_err(LuaError::external)
        });
        methods.add_method("type", |_, _, ()| Ok("LLayeredImage"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLayeredImage" || name == "Object")
        });
    }
}
pub struct LuaCompressedImageData {
    inner: CompressedImageData,
}
impl LuaUserData for LuaCompressedImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height));
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        methods.add_method("getMipmapCount", |_, this, ()| {
            Ok(this.inner.get_mipmap_count())
        });
        methods.add_method("getFormat", |_, this, ()| {
            Ok(this.inner.get_format().to_string())
        });
        methods.add_method("type", |_, _, ()| Ok("LCompressedImageData"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCompressedImageData" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "newImageData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let first = iter.next().ok_or_else(|| {
                LuaError::RuntimeError("newImageData expects (width, height) or (filename)".into())
            })?;
            let img = if let LuaValue::String(ref filename) = first {
                let name = filename
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                let bytes = s.borrow().fs.read_bytes(name).map_err(LuaError::external)?;
                ImageData::from_encoded_bytes(&bytes, name).map_err(LuaError::RuntimeError)?
            } else {
                let width = match first {
                    LuaValue::Integer(n) => n as u32,
                    LuaValue::Number(n) => n as u32,
                    _ => {
                        return Err(LuaError::RuntimeError("width must be a number".into()));
                    }
                };
                let height = match iter.next() {
                    Some(LuaValue::Integer(n)) => n as u32,
                    Some(LuaValue::Number(n)) => n as u32,
                    _ => {
                        return Err(LuaError::RuntimeError("height must be a number".into()));
                    }
                };
                ImageData::new(width, height)
            };
            lua.create_userdata(img)
        })?,
    )?;
    tbl.set(
        "newImageDataFromBytes",
        lua.create_function(move |lua, (w, h, bytes): (u32, u32, LuaString)| {
            let raw = bytes.as_bytes().to_vec();
            let img = ImageData::from_bytes(w, h, raw).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(img)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newCompressedData",
        lua.create_function(move |lua, filename: String| {
            let bytes = s
                .borrow()
                .fs
                .read_bytes(&filename)
                .map_err(LuaError::external)?;
            let cid = CompressedImageData::from_dds(&bytes).map_err(LuaError::external)?;
            lua.create_userdata(LuaCompressedImageData { inner: cid })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isCompressed",
        lua.create_function(move |_, filename: String| {
            let bytes = match s.borrow().fs.read_bytes(&filename) {
                Ok(bytes) => bytes,
                Err(_) => return Ok(false),
            };
            Ok(CompressedImageData::is_dds_magic(&bytes))
        })?,
    )?;
    tbl.set(
        "newLayeredImage",
        lua.create_function(move |lua, (width, height): (u32, u32)| {
            lua.create_userdata(LuaLayeredImage {
                inner: LayeredImage::new(width, height),
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "saveImage",
        lua.create_function(move |_, (img_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let img = img_ud
                .borrow::<ImageData>()
                .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
            serial::save_image(&img, path_str).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "savePNG",
        lua.create_function(move |_, (img_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let raw = img_ud
                .borrow::<ImageData>()
                .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
            let bytes = raw.encode_png().map_err(LuaError::RuntimeError)?;
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).map_err(LuaError::external)?;
            }
            std::fs::write(&path, &bytes).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "loadImage",
        lua.create_function(move |lua, filename: String| {
            let bytes = s
                .borrow()
                .fs
                .read_bytes(&filename)
                .map_err(LuaError::external)?;
            let img =
                serial::load_image_from_bytes(&bytes, &filename).map_err(LuaError::external)?;
            lua.create_userdata(img)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "loadLayered",
        lua.create_function(move |lua, filename: String| {
            let bytes = s
                .borrow()
                .fs
                .read_bytes(&filename)
                .map_err(LuaError::external)?;
            let stack =
                serial::load_layered_from_bytes(&bytes, &filename).map_err(LuaError::external)?;
            lua.create_userdata(LuaLayeredImage { inner: stack })
        })?,
    )?;
    tbl.set(
        "newPaletteLut",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaPaletteLUT {
                inner: crate::image::palette_lut::PaletteLUT::new(),
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newProvinceGrid",
        lua.create_function(move |lua, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let grid = ProvinceGrid::from_file(path_str).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaProvinceGrid {
                inner: grid,
                state: s.clone(),
                shape_cache: None,
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "fromScreen",
        lua.create_function(move |lua, ()| {
            let mut st = s.borrow_mut();
            if let Some(img) = st.captured_screen_image.take() {
                Ok(LuaValue::UserData(lua.create_userdata(img)?))
            } else {
                st.pending_screen_capture = true;
                Ok(LuaValue::Nil)
            }
        })?,
    )?;
    lurek.set("image", tbl)?;
    Ok(())
}
impl mlua::UserData for ImageData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.height()));
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.dimensions();
            Ok((w, h))
        });
        methods.add_method("getPixel", |_, this, (x, y): (u32, u32)| {
            this.get_pixel(x, y).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Pixel ({}, {}) out of bounds ({}x{})",
                    x,
                    y,
                    this.width(),
                    this.height()
                ))
            })
        });
        methods.add_method_mut(
            "setPixel",
            |_, this, (x, y, r, g, b, a): (u32, u32, u8, u8, u8, u8)| {
                if this.set_pixel(x, y, r, g, b, a) {
                    Ok(())
                } else {
                    Err(LuaError::RuntimeError(format!(
                        "Pixel ({}, {}) out of bounds ({}x{})",
                        x,
                        y,
                        this.width(),
                        this.height()
                    )))
                }
            },
        );
        methods.add_method("encode", |_, this, format: String| match format.as_str() {
            "png" => this.encode_png().map_err(LuaError::RuntimeError),
            _ => Err(LuaError::RuntimeError(format!(
                "Unknown image format: '{}'. Use 'png'.",
                format
            ))),
        });
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        methods.add_method_mut("mapPixel", |_, this, func: LuaFunction| {
            let w = this.width();
            let h = this.height();
            for y in 0..h {
                for x in 0..w {
                    if let Some((r, g, b, a)) = this.get_pixel(x, y) {
                        let result: (u8, u8, u8, u8) =
                            func.call((x, y, r, g, b, a)).map_err(|e| {
                                LuaError::RuntimeError(format!("mapPixel callback: {}", e))
                            })?;
                        this.set_pixel(x, y, result.0, result.1, result.2, result.3);
                    }
                }
            }
            Ok(())
        });
        methods.add_method_mut("brightness", |_, this, factor: f32| {
            this.brightness(factor);
            Ok(())
        });
        methods.add_method_mut("contrast", |_, this, factor: f32| {
            this.contrast(factor);
            Ok(())
        });
        methods.add_method_mut("saturation", |_, this, factor: f32| {
            this.saturation(factor);
            Ok(())
        });
        methods.add_method_mut("gamma", |_, this, gamma: f32| {
            this.gamma(gamma);
            Ok(())
        });
        methods.add_method_mut(
            "tint",
            |_, this, (tr, tg, tb, factor): (u8, u8, u8, f32)| {
                this.tint(tr, tg, tb, factor);
                Ok(())
            },
        );
        methods.add_method_mut("grayscale", |_, this, ()| {
            this.grayscale();
            Ok(())
        });
        methods.add_method_mut("sepia", |_, this, ()| {
            this.sepia();
            Ok(())
        });
        methods.add_method_mut("invert", |_, this, ()| {
            this.invert();
            Ok(())
        });
        methods.add_method_mut("threshold", |_, this, value: u8| {
            this.threshold(value);
            Ok(())
        });
        methods.add_method_mut("posterize", |_, this, levels: u8| {
            this.posterize(levels);
            Ok(())
        });
        methods.add_method_mut("fill", |_, this, (r, g, b, a): (u8, u8, u8, u8)| {
            this.fill(r, g, b, a);
            Ok(())
        });
        methods.add_method_mut("noise", |_, this, amount: u8| {
            this.noise(amount);
            Ok(())
        });
        methods.add_method_mut("alphaMask", |_, this, factor: f32| {
            this.alpha_mask(factor);
            Ok(())
        });
        methods.add_method_mut("flipHorizontal", |_, this, ()| {
            this.flip_horizontal();
            Ok(())
        });
        methods.add_method_mut("flipVertical", |_, this, ()| {
            this.flip_vertical();
            Ok(())
        });
        methods.add_method("rotate90cw", |lua, this, ()| {
            lua.create_userdata(this.rotate_90_cw())
        });
        methods.add_method("crop", |lua, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.crop(x, y, w, h)
                .ok_or_else(|| {
                    LuaError::RuntimeError(format!(
                        "crop ({},{},{},{}) out of bounds ({}x{})",
                        x,
                        y,
                        w,
                        h,
                        this.width(),
                        this.height()
                    ))
                })
                .and_then(|img| lua.create_userdata(img))
        });
        methods.add_method("resizeNearest", |lua, this, (new_w, new_h): (u32, u32)| {
            lua.create_userdata(this.resize_nearest(new_w, new_h))
        });
        methods.add_method("blur", |lua, this, radius: u32| {
            lua.create_userdata(this.blur(radius))
        });
        methods.add_method("sharpen", |lua, this, ()| {
            lua.create_userdata(this.sharpen())
        });
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, r, g, b, a): (i32, i32, u32, u32, u8, u8, u8, u8)| {
                this.draw_rect(x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method_mut(
            "drawCircle",
            |_, this, (cx, cy, radius, r, g, b, a): (i32, i32, u32, u8, u8, u8, u8)| {
                this.draw_circle(cx, cy, radius, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method_mut(
            "drawLine",
            |_, this, (x0, y0, x1, y1, r, g, b, a): (i32, i32, i32, i32, u8, u8, u8, u8)| {
                this.draw_line(x0, y0, x1, y1, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method("resize", |lua, this, args: LuaMultiValue| {
            let mut it = args.into_iter();
            let w = match it.next() {
                Some(LuaValue::Integer(v)) => v as u32,
                Some(LuaValue::Number(v)) => v as u32,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "resize(width, height, [filter]): width must be numeric".into(),
                    ));
                }
            };
            let h = match it.next() {
                Some(LuaValue::Integer(v)) => v as u32,
                Some(LuaValue::Number(v)) => v as u32,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "resize(width, height, [filter]): height must be numeric".into(),
                    ));
                }
            };
            let filter = match it.next() {
                Some(LuaValue::String(name)) => {
                    let name = name
                        .to_str()
                        .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                    crate::image::effects::ResizeFilter::parse(name).ok_or_else(|| {
                        LuaError::RuntimeError(format!(
                            "resize: invalid filter '{}', expected 'bilinear' or 'lanczos3'",
                            name
                        ))
                    })?
                }
                Some(_) => {
                    return Err(LuaError::RuntimeError(
                        "resize(width, height, [filter]): filter must be a string".into(),
                    ));
                }
                None => crate::image::effects::ResizeFilter::Bilinear,
            };
            match this.resize_with_filter(w, h, filter) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<ImageData>()?;
                this.blit(&src_ref, dst_x, dst_y);
                Ok(())
            },
        );
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "drawNineSlice",
            |_,
             this,
             (
                src_ud,
                src_x,
                src_y,
                src_w,
                src_h,
                dst_x,
                dst_y,
                dst_w,
                dst_h,
                inset_left,
                inset_right,
                inset_top,
                inset_bottom,
            ): (
                LuaAnyUserData,
                u32,
                u32,
                u32,
                u32,
                i32,
                i32,
                u32,
                u32,
                u32,
                u32,
                u32,
                u32,
            )| {
                let src_ref = src_ud
                    .borrow::<ImageData>()
                    .map_err(|_| LuaError::RuntimeError("source must be an ImageData".into()))?;
                this.draw_nine_slice(
                    &src_ref,
                    src_x,
                    src_y,
                    src_w,
                    src_h,
                    dst_x,
                    dst_y,
                    dst_w,
                    dst_h,
                    inset_left,
                    inset_right,
                    inset_top,
                    inset_bottom,
                )
                .map_err(LuaError::RuntimeError)?;
                Ok(())
            },
        );
        methods.add_method(
            "getRegion",
            |lua, this, (x, y, w, h): (u32, u32, u32, u32)| match this.get_region(x, y, w, h) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            },
        );
        methods.add_method("getRawBytes", |lua, this, ()| {
            lua.create_string(this.as_bytes())
        });
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<ImageData>()?;
            Ok(this.diff(&other_ref))
        });
        methods.add_method_mut("mapPixels", |_, this, func: LuaFunction| {
            let w = this.width();
            let h = this.height();
            for y in 0..h {
                for x in 0..w {
                    if let Some((r, g, b, a)) = this.get_pixel(x, y) {
                        let result: (u8, u8, u8, u8) = func.call((x, y, r, g, b, a))?;
                        this.set_pixel(x, y, result.0, result.1, result.2, result.3);
                    }
                }
            }
            Ok(())
        });
        methods.add_method(
            "convolve",
            |lua, this, (kernel_t, ksize): (LuaTable, usize)| {
                let len = kernel_t.len()? as usize;
                let mut kernel: Vec<f64> = Vec::with_capacity(len);
                for i in 1..=len {
                    kernel.push(kernel_t.get::<_, f64>(i)?);
                }
                let result = this.convolve(&kernel, ksize).map_err(LuaError::external)?;
                lua.create_userdata(result)
            },
        );
        methods.add_method_mut("applyPaletteLut", |_, this, lut_ud: LuaAnyUserData| {
            let lut = lut_ud.borrow::<LuaPaletteLUT>()?;
            lut.inner.apply(this);
            Ok(())
        });
        methods.add_method_mut("setRawData", |_, this, bytes: LuaString| {
            this.set_raw_data(bytes.as_bytes())
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut(
            "paste",
            |_, this, (src_ud, dx, dy): (LuaAnyUserData, u32, u32)| {
                let src = src_ud.borrow::<ImageData>()?;
                this.paste(&src, dx, dy);
                Ok(())
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LImageData"));
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "ImageData"));
    }
}
pub struct LuaPaletteLUT {
    inner: crate::image::palette_lut::PaletteLUT,
}
impl LuaUserData for LuaPaletteLUT {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "setColor",
            |_, this, (fr, fg, fb, fa, tr, tg, tb, ta): (u8, u8, u8, u8, u8, u8, u8, u8)| {
                use crate::math::color::Color;
                let from = Color {
                    r: fr as f32 / 255.0,
                    g: fg as f32 / 255.0,
                    b: fb as f32 / 255.0,
                    a: fa as f32 / 255.0,
                };
                let to = Color {
                    r: tr as f32 / 255.0,
                    g: tg as f32 / 255.0,
                    b: tb as f32 / 255.0,
                    a: ta as f32 / 255.0,
                };
                let next_idx = this.inner.get_color_count();
                this.inner.set_color(next_idx, from, to);
                Ok(())
            },
        );
        methods.add_method("getColorCount", |_, this, ()| {
            Ok(this.inner.get_color_count())
        });
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method_mut("cycle", |_, this, offset: i32| {
            this.inner.cycle_to_colors(offset);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LPaletteLUT"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPaletteLUT" || name == "Object")
        });
    }
}
