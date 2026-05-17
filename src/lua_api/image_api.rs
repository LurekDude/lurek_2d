//! `lurek.image` -- Image bindings for pixel buffers, encoded image load/save, layered image stacks, DDS compressed metadata, palette lookup tables, province color grids, polygon extraction, shape rendering, and screen capture handoff.

use super::SharedState;
use crate::image::serial;
use crate::image::{CompressedImageData, ImageData, LayeredImage, ProvinceGrid};
use crate::render::{DrawMode, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
#[derive(Clone)]
/// Cached province polygon draw data with color, bounds, and flattened vertices.
struct ProvinceShapeCacheEntry {
    /// Red channel normalized to 0.0 through 1.0.
    r: f32,
    /// Green channel normalized to 0.0 through 1.0.
    g: f32,
    /// Blue channel normalized to 0.0 through 1.0.
    b: f32,
    /// Minimum x coordinate for viewport culling.
    min_x: f32,
    /// Minimum y coordinate for viewport culling.
    min_y: f32,
    /// Maximum x coordinate for viewport culling.
    max_x: f32,
    /// Maximum y coordinate for viewport culling.
    max_y: f32,
    /// Flattened `[x, y]` polygon vertices used by renderer commands.
    vertices: Vec<f32>,
}
/// Lua-side handle for a province id grid decoded from an image.
pub struct LuaProvinceGrid {
    /// Province grid, color mapping, adjacency, spans, and polygon extraction data.
    inner: ProvinceGrid,
    /// Shared runtime state receiving province shape draw commands.
    state: Rc<RefCell<SharedState>>,
    /// Lazily built simplified polygon cache for repeated shape drawing.
    shape_cache: Option<Vec<ProvinceShapeCacheEntry>>,
}
/// Provides Lua methods for province-grid inspection, geometry export, and drawing.
impl LuaUserData for LuaProvinceGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the province grid width. This method is available to Lua scripts.
        /// @return | integer | Grid width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        // -- getHeight --
        /// Returns the province grid height. This method is available to Lua scripts.
        /// @return | integer | Grid height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        // -- getAt --
        /// Returns the province id stored at grid coordinates.
        /// @param | x | integer | X coordinate.
        /// @param | y | integer | Y coordinate.
        /// @return | integer | Province id at the pixel.
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_at(x, y))
        });
        // -- provinceCount --
        /// Returns the number of distinct provinces in the grid.
        /// @return | integer | Province count.
        methods.add_method("provinceCount", |_, this, ()| {
            Ok(this.inner.province_count())
        });
        // -- adjacencies --
        /// Returns province adjacency records and shared border pixel counts.
        /// @return | table | Array table with `province_a`, `province_b`, and `border_pixels` fields.
    /// @field | province_a | integer | First province id.
    /// @field | province_b | integer | Second province id.
    /// @field | border_pixels | integer | Number of shared border pixels.
        methods.add_method("adjacencies", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, &(a, b, bp)) in this.inner.adjacencies().iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'province_a' operation.
                entry.set("province_a", a)?;
                /// Performs the 'province_b' operation.
                entry.set("province_b", b)?;
                /// Performs the 'border_pixels' operation.
                entry.set("border_pixels", bp)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        // -- provinceSpans --
        /// Returns horizontal province spans by row.
        /// @return | table | Array table with `province_id`, `y`, `x0`, and `x1` fields.
    /// @field | province_id | integer | Province id.
    /// @field | y | integer | Scanline y coordinate.
    /// @field | x0 | integer | Start x coordinate.
    /// @field | x1 | integer | End x coordinate.
        methods.add_method("provinceSpans", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (id, y, x0, x1)) in this.inner.province_spans().into_iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'province_id' operation.
                row.set("province_id", id)?;
                /// Performs the 'y' operation.
                row.set("y", y)?;
                /// Performs the 'x0' operation.
                row.set("x0", x0)?;
                /// Performs the 'x1' operation.
                row.set("x1", x1)?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });
        // -- borderSegments --
        /// Returns border line segments between neighboring provinces.
        /// @return | table | Array table with province ids and segment coordinates.
    /// @field | province_a | integer | First province id.
    /// @field | province_b | integer | Second province id.
    /// @field | x0 | number | Segment start x.
    /// @field | y0 | number | Segment start y.
    /// @field | x1 | number | Segment end x.
    /// @field | y1 | number | Segment end y.
        methods.add_method("borderSegments", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (a, b, x0, y0, x1, y1)) in this.inner.border_segments().into_iter().enumerate()
            {
                let seg = lua.create_table()?;
                /// Performs the 'province_a' operation.
                seg.set("province_a", a)?;
                /// Performs the 'province_b' operation.
                seg.set("province_b", b)?;
                /// Performs the 'x0' operation.
                seg.set("x0", x0)?;
                /// Performs the 'y0' operation.
                seg.set("y0", y0)?;
                /// Performs the 'x1' operation.
                seg.set("x1", x1)?;
                /// Performs the 'y1' operation.
                seg.set("y1", y1)?;
                t.set(i + 1, seg)?;
            }
            Ok(t)
        });
        // -- getPolygons --
        /// Returns polygon rings for every province.
        /// @return | table | Array table of province polygon records with `province_id` and `rings` fields.
    /// @field | province_id | integer | Province id.
    /// @field | rings | table | Array of rings; each ring is an array of [x, y] pairs.
        methods.add_method("getPolygons", |lua, this, ()| {
            let map = this.inner.province_polygons();
            let out = lua.create_table()?;
            let mut idx = 1usize;
            for (id, rings) in &map {
                let entry = lua.create_table()?;
                /// Performs the 'province_id' operation.
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
                /// Performs the 'rings' operation.
                entry.set("rings", rings_tbl)?;
                out.set(idx, entry)?;
                idx += 1;
            }
            Ok(out)
        });
        // -- getPolygonsSimplified --
        /// Returns simplified polygon rings for every province.
        /// @return | table | Array table of simplified province polygon records with `province_id` and `rings` fields.
    /// @field | province_id | integer | Province id.
    /// @field | rings | table | Array of simplified rings; each ring is an array of [x, y] pairs.
        methods.add_method("getPolygonsSimplified", |lua, this, ()| {
            let map = this.inner.province_polygons_simplified();
            let out = lua.create_table()?;
            let mut idx = 1usize;
            for (id, rings) in &map {
                let entry = lua.create_table()?;
                /// Performs the 'province_id' operation.
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
                /// Performs the 'rings' operation.
                entry.set("rings", rings_tbl)?;
                out.set(idx, entry)?;
                idx += 1;
            }
            Ok(out)
        });
        // -- drawShapes --
        /// Queues filled polygon draw commands for province shapes, optionally culled to a viewport rect.
        /// Pass no arguments to draw all shapes, or pass `x, y, w, h` to cull to a rectangle.
        /// @param | x | number? | Viewport left edge (required if providing a viewport).
        /// @param | y | number? | Viewport top edge (required if providing a viewport).
        /// @param | w | number? | Viewport width (required if providing a viewport).
        /// @param | h | number? | Viewport height (required if providing a viewport).
        /// @return | integer | Number of polygons emitted to the render command queue.
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
        // -- type --
        /// Returns the Lua-visible type name for this province grid handle.
        /// @return | string | The string `LProvinceGrid`.
        methods.add_method("type", |_, _, ()| Ok("LProvinceGrid"));
        // -- typeOf --
        /// Returns whether this province grid handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LProvinceGrid` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LProvinceGrid" || name == "Object")
        });
        // -- serializeShapeData --
        /// Serializes province span and border shape data into a binary Lua string.
        /// @return | string | Serialized shape data bytes.
        methods.add_method("serializeShapeData", |lua, this, ()| {
            let data = this.inner.serialize_shape_data();
            lua.create_string(&data)
        });
        // -- deserializeShapeData --
        /// Decodes serialized province shape data into span and segment tables.
        /// @param | bytes | string | Serialized shape data bytes.
        /// @return | LuaValue | Table with `spans` and `segments`, or nil when decoding fails.
        methods.add_method("deserializeShapeData", |lua, _, bytes: LuaString| {
            let data = bytes.as_bytes();
            if let Some((spans, segs)) = ProvinceGrid::deserialize_shape_data(data) {
                let result = lua.create_table()?;
                let spans_tbl = lua.create_table()?;
                for (i, (id, y, x0, x1)) in spans.into_iter().enumerate() {
                    let row = lua.create_table()?;
                    /// Performs the 'province_id' operation.
                    row.set("province_id", id)?;
                    /// Performs the 'y' operation.
                    row.set("y", y)?;
                    /// Performs the 'x0' operation.
                    row.set("x0", x0)?;
                    /// Performs the 'x1' operation.
                    row.set("x1", x1)?;
                    spans_tbl.set(i + 1, row)?;
                }
                /// Performs the 'spans' operation.
                result.set("spans", spans_tbl)?;
                let segs_tbl = lua.create_table()?;
                for (i, (a, b, x0, y0, x1, y1)) in segs.into_iter().enumerate() {
                    let seg = lua.create_table()?;
                    /// Performs the 'province_a' operation.
                    seg.set("province_a", a)?;
                    /// Performs the 'province_b' operation.
                    seg.set("province_b", b)?;
                    /// Performs the 'x0' operation.
                    seg.set("x0", x0)?;
                    /// Performs the 'y0' operation.
                    seg.set("y0", y0)?;
                    /// Performs the 'x1' operation.
                    seg.set("x1", x1)?;
                    /// Performs the 'y1' operation.
                    seg.set("y1", y1)?;
                    segs_tbl.set(i + 1, seg)?;
                }
                /// Performs the 'segments' operation.
                result.set("segments", segs_tbl)?;
                Ok(LuaValue::Table(result))
            } else {
                Ok(LuaValue::Nil)
            }
        });
    }
}
/// Lua-side handle for multiple image layers with visibility, opacity, and ordering.
pub struct LuaLayeredImage {
    /// Layer stack and per-layer metadata.
    inner: LayeredImage,
}
/// Provides Lua methods for editing and merging layered images.
impl LuaUserData for LuaLayeredImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the layered image width. This method is available to Lua scripts.
        /// @return | integer | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        // -- getHeight --
        /// Returns the layered image height. This method is available to Lua scripts.
        /// @return | integer | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        // -- layerCount --
        /// Returns the number of layers in the stack.
        /// @return | integer | Layer count.
        methods.add_method("layerCount", |_, this, ()| Ok(this.inner.layer_count()));
        // -- addLayer --
        /// Adds a blank layer with an optional name.
        /// @param | name | string? | Optional layer name.
        /// @return | integer | One-based index of the new layer.
        methods.add_method_mut("addLayer", |_, this, name: Option<String>| {
            let label = name.unwrap_or_else(|| format!("Layer {}", this.inner.layer_count() + 1));
            let idx = this.inner.add_layer(label);
            Ok(idx + 1)
        });
        // -- removeLayer --
        /// Removes a layer by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | boolean | True when a layer was removed.
        methods.add_method_mut("removeLayer", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.remove_layer(index - 1).is_some())
        });
        // -- getLayer --
        /// Returns image data for a layer by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | LImageData | Layer image data handle.
        methods.add_method("getLayer", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| lua.create_userdata(l.data.clone()))
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))?
        });
        // -- setLayer --
        /// Replaces a layer's image data by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @param | img | LImageData | Image data assigned to the layer.
        /// @return | boolean | True when the layer was replaced.
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
        // -- getOpacity --
        /// Returns a layer opacity by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | number | Layer opacity.
        methods.add_method("getOpacity", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.opacity)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        // -- setOpacity --
        /// Sets a layer opacity by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @param | opacity | number | New layer opacity.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut("setOpacity", |_, this, (index, opacity): (usize, f32)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_opacity(index - 1, opacity))
        });
        // -- isVisible --
        /// Returns layer visibility by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | boolean | True when the layer is visible.
        methods.add_method("isVisible", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.visible)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        // -- setVisible --
        /// Sets layer visibility by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @param | visible | boolean | New visibility flag.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut("setVisible", |_, this, (index, visible): (usize, bool)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_visible(index - 1, visible))
        });
        // -- getName --
        /// Returns a layer name by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @return | string | Layer name.
        methods.add_method("getName", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.name.clone())
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });
        // -- setName --
        /// Sets a layer name by one-based index.
        /// @param | index | integer | One-based layer index.
        /// @param | name | string | New layer name.
        /// @return | boolean | True when the layer exists.
        methods.add_method_mut("setName", |_, this, (index, name): (usize, String)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_name(index - 1, name))
        });
        // -- swapLayers --
        /// Swaps two layers by one-based indices.
        /// @param | a | integer | First one-based layer index.
        /// @param | b | integer | Second one-based layer index.
        /// @return | boolean | True when both layers exist.
        methods.add_method_mut("swapLayers", |_, this, (a, b): (usize, usize)| {
            if a == 0 || b == 0 {
                return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
            }
            Ok(this.inner.swap_layers(a - 1, b - 1))
        });
        // -- moveLayer --
        /// Moves a layer from one one-based index to another.
        /// @param | from_idx | integer | Source one-based layer index.
        /// @param | to_idx | integer | Destination one-based layer index.
        /// @return | boolean | True when the move succeeds.
        methods.add_method_mut(
            "moveLayer",
            |_, this, (from_idx, to_idx): (usize, usize)| {
                if from_idx == 0 || to_idx == 0 {
                    return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
                }
                Ok(this.inner.move_layer(from_idx - 1, to_idx - 1))
            },
        );
        // -- merge --
        /// Merges visible layers into a single image data object.
        /// @return | LImageData | Merged image data handle.
        methods.add_method("merge", |lua, this, ()| {
            lua.create_userdata(this.inner.merge())
        });
        // -- save --
        /// Saves the layered image stack to a file.
        /// @param | path | string | Output path.
        methods.add_method("save", |_, this, path: String| {
            serial::save_layered(&this.inner, &path).map_err(LuaError::external)
        });
        // -- type --
        /// Returns the Lua-visible type name for this layered image handle.
        /// @return | string | The string `LLayeredImage`.
        methods.add_method("type", |_, _, ()| Ok("LLayeredImage"));
        // -- typeOf --
        /// Returns whether this layered image handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LLayeredImage` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLayeredImage" || name == "Object")
        });
    }
}
/// Lua-side handle for compressed DDS image metadata and mipmap data.
pub struct LuaCompressedImageData {
    /// Compressed image dimensions, format, mipmaps, and byte data.
    inner: CompressedImageData,
}
/// Provides Lua methods for compressed image metadata.
impl LuaUserData for LuaCompressedImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns compressed image width. This method is available to Lua scripts.
        /// @return | integer | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width));
        // -- getHeight --
        /// Returns compressed image height. This method is available to Lua scripts.
        /// @return | integer | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height));
        // -- getDimensions --
        /// Returns compressed image dimensions.
        /// @return | integer | Width in pixels.
        /// @return | integer | Height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });
        // -- getMipmapCount --
        /// Returns the number of mipmap levels in this compressed image.
        /// @return | integer | Mipmap level count.
        methods.add_method("getMipmapCount", |_, this, ()| {
            Ok(this.inner.get_mipmap_count())
        });
        // -- getFormat --
        /// Returns the compressed image format name.
        /// @return | string | Format name.
        methods.add_method("getFormat", |_, this, ()| {
            Ok(this.inner.get_format().to_string())
        });
        // -- type --
        /// Returns the Lua-visible type name for this compressed image handle.
        /// @return | string | The string `LCompressedImageData`.
        methods.add_method("type", |_, _, ()| Ok("LCompressedImageData"));
        // -- typeOf --
        /// Returns whether this compressed image handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCompressedImageData` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCompressedImageData" || name == "Object")
        });
    }
}
/// Registers `lurek.image` image creation, load/save, province grid, palette, and capture helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newImageData --
    /// Creates empty image data from dimensions or decodes image data from a GameFS filename.
    /// @param | width_or_filename | integer|string | Width in pixels for a blank canvas, or a GameFS filename string to load from disk.
    /// @param | height | integer? | Height in pixels; required when the first argument is a width integer. Omit when loading from filename.
    /// @return | LImageData | New image data handle.
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
    // -- newImageDataFromBytes --
    /// Creates image data from raw RGBA bytes and explicit dimensions.
    /// @param | w | integer | Width in pixels.
    /// @param | h | integer | Height in pixels.
    /// @param | bytes | string | Raw RGBA byte string.
    /// @return | LImageData | New image data handle.
    tbl.set(
        "newImageDataFromBytes",
        lua.create_function(move |lua, (w, h, bytes): (u32, u32, LuaString)| {
            let raw = bytes.as_bytes().to_vec();
            let img = ImageData::from_bytes(w, h, raw).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(img)
        })?,
    )?;
    let s = state.clone();
    // -- newCompressedData --
    /// Loads DDS compressed image data from GameFS.
    /// @param | filename | string | GameFS path to a DDS file.
    /// @return | LCompressedImageData | New compressed image data handle.
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
    // -- isCompressed --
    /// Returns whether a GameFS image file begins with DDS compressed image magic bytes.
    /// @param | filename | string | GameFS path to inspect.
    /// @return | boolean | True when the file appears to be DDS compressed data.
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
    // -- newLayeredImage --
    /// Creates a layered image stack with one or more blank layers.
    /// @param | width | integer | Width in pixels.
    /// @param | height | integer | Height in pixels.
    /// @return | LLayeredImage | New layered image handle.
    tbl.set(
        "newLayeredImage",
        lua.create_function(move |lua, (width, height): (u32, u32)| {
            lua.create_userdata(LuaLayeredImage {
                inner: LayeredImage::new(width, height),
            })
        })?,
    )?;
    let s = state.clone();
    // -- saveImage --
    /// Saves an image data object to a path under the current game directory.
    /// @param | img_ud | LImageData | Image data handle to save.
    /// @param | filename | string | Output filename relative to game directory.
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
    // -- savePNG --
    /// Encodes image data as PNG and writes it under the current game directory.
    /// @param | img_ud | LImageData | Image data handle to encode.
    /// @param | filename | string | Output filename relative to game directory.
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
    // -- loadImage --
    /// Loads and decodes image data from GameFS.
    /// @param | filename | string | GameFS path to an encoded image.
    /// @return | LImageData | Loaded image data handle.
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
    // -- loadLayered --
    /// Loads a serialized layered image stack from GameFS.
    /// @param | filename | string | GameFS path to the layered image file.
    /// @return | LLayeredImage | Loaded layered image handle.
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
    // -- newPaletteLut --
    /// Creates an empty palette lookup table.
    /// @return | LPaletteLUT | New palette lookup table handle.
    tbl.set(
        "newPaletteLut",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaPaletteLUT {
                inner: crate::image::palette_lut::PaletteLUT::new(),
            })
        })?,
    )?;
    let s = state.clone();
    // -- newProvinceGrid --
    /// Loads a province id grid from an image file under the current game directory.
    /// @param | filename | string | Province map image filename relative to game directory.
    /// @return | LProvinceGrid | New province grid handle.
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
    // -- fromScreen --
    /// Returns a completed screen capture image or requests one for a future call.
    /// @return | LImageData|nil | `LImageData` when capture data is ready, or nil after requesting capture.
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
    /// Performs the 'image' operation.
    lurek.set("image", tbl)?;
    Ok(())
}
/// Provides Lua methods for reading, editing, filtering, drawing, and encoding image data.
impl mlua::UserData for ImageData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns image width. This method is available to Lua scripts.
        /// @return | integer | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.width()));
        // -- getHeight --
        /// Returns image height. This method is available to Lua scripts.
        /// @return | integer | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.height()));
        // -- getDimensions --
        /// Returns image dimensions. This method is available to Lua scripts.
        /// @return | integer | Width in pixels.
        /// @return | integer | Height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.dimensions();
            Ok((w, h))
        });
        // -- getPixel --
        /// Returns RGBA channels at a pixel coordinate.
        /// @param | x | integer | X coordinate.
        /// @param | y | integer | Y coordinate.
        /// @return | integer | Red channel.
        /// @return | integer | Green channel.
        /// @return | integer | Blue channel.
        /// @return | integer | Alpha channel.
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
        // -- setPixel --
        /// Sets RGBA channels at a pixel coordinate.
        /// @param | x | integer | X coordinate.
        /// @param | y | integer | Y coordinate.
        /// @param | r | integer | Red channel.
        /// @param | g | integer | Green channel.
        /// @param | b | integer | Blue channel.
        /// @param | a | integer | Alpha channel.
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
        // -- encode --
        /// Encodes image data in a supported format.
        /// @param | format | string | Format name; currently `png`.
        /// @return | string | Encoded image bytes.
        methods.add_method("encode", |_, this, format: String| match format.as_str() {
            "png" => this.encode_png().map_err(LuaError::RuntimeError),
            _ => Err(LuaError::RuntimeError(format!(
                "Unknown image format: '{}'. Use 'png'.",
                format
            ))),
        });
        // -- getString --
        /// Returns raw image bytes as a Lua string.
        /// @return | string | Raw image byte string.
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        // -- mapPixel --
        /// Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values.
        /// @param | func | function | Callback receiving `(x, y, r, g, b, a)` and returning replacement channels.
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
        // -- brightness --
        /// Applies a brightness factor to this image in place.
        /// @param | factor | number | Brightness multiplier or adjustment factor.
        methods.add_method_mut("brightness", |_, this, factor: f32| {
            this.brightness(factor);
            Ok(())
        });
        // -- contrast --
        /// Applies a contrast factor to this image in place.
        /// @param | factor | number | Contrast factor.
        methods.add_method_mut("contrast", |_, this, factor: f32| {
            this.contrast(factor);
            Ok(())
        });
        // -- saturation --
        /// Applies a saturation factor to this image in place.
        /// @param | factor | number | Saturation factor.
        methods.add_method_mut("saturation", |_, this, factor: f32| {
            this.saturation(factor);
            Ok(())
        });
        // -- gamma --
        /// Applies gamma correction to this image in place.
        /// @param | gamma | number | Gamma value.
        methods.add_method_mut("gamma", |_, this, gamma: f32| {
            this.gamma(gamma);
            Ok(())
        });
        // -- tint --
        /// Blends this image toward a tint color in place.
        /// @param | tr | integer | Tint red channel.
        /// @param | tg | integer | Tint green channel.
        /// @param | tb | integer | Tint blue channel.
        /// @param | factor | number | Tint blend factor.
        methods.add_method_mut(
            "tint",
            |_, this, (tr, tg, tb, factor): (u8, u8, u8, f32)| {
                this.tint(tr, tg, tb, factor);
                Ok(())
            },
        );
        // -- grayscale --
        /// Converts this image to grayscale in place.
        methods.add_method_mut("grayscale", |_, this, ()| {
            this.grayscale();
            Ok(())
        });
        // -- sepia --
        /// Applies a sepia filter to this image in place.
        methods.add_method_mut("sepia", |_, this, ()| {
            this.sepia();
            Ok(())
        });
        // -- invert --
        /// Inverts image color channels in place.
        methods.add_method_mut("invert", |_, this, ()| {
            this.invert();
            Ok(())
        });
        // -- threshold --
        /// Applies a threshold filter to this image in place.
        /// @param | value | integer | Threshold channel value.
        methods.add_method_mut("threshold", |_, this, value: u8| {
            this.threshold(value);
            Ok(())
        });
        // -- posterize --
        /// Reduces image colors to a fixed number of levels in place.
        /// @param | levels | integer | Number of posterization levels.
        methods.add_method_mut("posterize", |_, this, levels: u8| {
            this.posterize(levels);
            Ok(())
        });
        // -- fill --
        /// Fills the whole image with one RGBA color.
        /// @param | r | integer | Red channel.
        /// @param | g | integer | Green channel.
        /// @param | b | integer | Blue channel.
        /// @param | a | integer | Alpha channel.
        methods.add_method_mut("fill", |_, this, (r, g, b, a): (u8, u8, u8, u8)| {
            this.fill(r, g, b, a);
            Ok(())
        });
        // -- noise --
        /// Adds noise to this image in place. This method is available to Lua scripts.
        /// @param | amount | integer | Noise amount.
        methods.add_method_mut("noise", |_, this, amount: u8| {
            this.noise(amount);
            Ok(())
        });
        // -- alphaMask --
        /// Multiplies this image alpha channel by a factor in place.
        /// @param | factor | number | Alpha multiplier.
        methods.add_method_mut("alphaMask", |_, this, factor: f32| {
            this.alpha_mask(factor);
            Ok(())
        });
        // -- flipHorizontal --
        /// Flips this image horizontally in place.
        methods.add_method_mut("flipHorizontal", |_, this, ()| {
            this.flip_horizontal();
            Ok(())
        });
        // -- flipVertical --
        /// Flips this image vertically in place.
        methods.add_method_mut("flipVertical", |_, this, ()| {
            this.flip_vertical();
            Ok(())
        });
        // -- rotate90cw --
        /// Returns a new image rotated ninety degrees clockwise.
        /// @return | LImageData | Rotated image data handle.
        methods.add_method("rotate90cw", |lua, this, ()| {
            lua.create_userdata(this.rotate_90_cw())
        });
        // -- crop --
        /// Returns a cropped image region. This method is available to Lua scripts.
        /// @param | x | integer | Source x coordinate.
        /// @param | y | integer | Source y coordinate.
        /// @param | w | integer | Crop width.
        /// @param | h | integer | Crop height.
        /// @return | LImageData | Cropped image data handle.
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
        // -- resizeNearest --
        /// Returns a resized image using nearest-neighbor sampling.
        /// @param | new_w | integer | Output width.
        /// @param | new_h | integer | Output height.
        /// @return | LImageData | Resized image data handle.
        methods.add_method("resizeNearest", |lua, this, (new_w, new_h): (u32, u32)| {
            lua.create_userdata(this.resize_nearest(new_w, new_h))
        });
        // -- blur --
        /// Returns a blurred copy of this image.
        /// @param | radius | integer | Blur radius.
        /// @return | LImageData | Blurred image data handle.
        methods.add_method("blur", |lua, this, radius: u32| {
            lua.create_userdata(this.blur(radius))
        });
        // -- sharpen --
        /// Returns a sharpened copy of this image.
        /// @return | LImageData | Sharpened image data handle.
        methods.add_method("sharpen", |lua, this, ()| {
            lua.create_userdata(this.sharpen())
        });
        // -- drawRect --
        /// Draws a filled rectangle into this image.
        /// @param | x | integer | Rectangle x coordinate.
        /// @param | y | integer | Rectangle y coordinate.
        /// @param | w | integer | Rectangle width.
        /// @param | h | integer | Rectangle height.
        /// @param | r | integer | Red channel.
        /// @param | g | integer | Green channel.
        /// @param | b | integer | Blue channel.
        /// @param | a | integer | Alpha channel.
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, r, g, b, a): (i32, i32, u32, u32, u8, u8, u8, u8)| {
                this.draw_rect(x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        // -- drawCircle --
        /// Draws a filled circle into this image.
        /// @param | cx | integer | Circle center x coordinate.
        /// @param | cy | integer | Circle center y coordinate.
        /// @param | radius | integer | Circle radius.
        /// @param | r | integer | Red channel.
        /// @param | g | integer | Green channel.
        /// @param | b | integer | Blue channel.
        /// @param | a | integer | Alpha channel.
        methods.add_method_mut(
            "drawCircle",
            |_, this, (cx, cy, radius, r, g, b, a): (i32, i32, u32, u8, u8, u8, u8)| {
                this.draw_circle(cx, cy, radius, r, g, b, a);
                Ok(())
            },
        );
        // -- drawLine --
        /// Draws a line into this image. This method is available to Lua scripts.
        /// @param | x0 | integer | Start x coordinate.
        /// @param | y0 | integer | Start y coordinate.
        /// @param | x1 | integer | End x coordinate.
        /// @param | y1 | integer | End y coordinate.
        /// @param | r | integer | Red channel.
        /// @param | g | integer | Green channel.
        /// @param | b | integer | Blue channel.
        /// @param | a | integer | Alpha channel.
        methods.add_method_mut(
            "drawLine",
            |_, this, (x0, y0, x1, y1, r, g, b, a): (i32, i32, i32, i32, u8, u8, u8, u8)| {
                this.draw_line(x0, y0, x1, y1, r, g, b, a);
                Ok(())
            },
        );
        // -- resize --
        /// Returns a resized image using an optional named filter.
        /// @param | width | integer | Output width.
        /// @param | height | integer | Output height.
        /// @param | filter | string | Optional filter name, defaulting to `bilinear`.
        /// @return | LImageData|nil | Resized `LImageData` handle, or nil when resizing fails.
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
        // -- blit --
        /// Copies a source image into this image at a destination coordinate.
        /// @param | src_ud | LImageData | Source image data handle.
        /// @param | dst_x | integer | Destination x coordinate.
        /// @param | dst_y | integer | Destination y coordinate.
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<ImageData>()?;
                this.blit(&src_ref, dst_x, dst_y);
                Ok(())
            },
        );
        #[allow(clippy::type_complexity)]
        // -- drawNineSlice --
        /// Draws a nine-slice region from a source image into this image.
        /// @param | src_ud | LImageData | Source image data handle.
        /// @param | src_x | integer | Source region x coordinate.
        /// @param | src_y | integer | Source region y coordinate.
        /// @param | src_w | integer | Source region width.
        /// @param | src_h | integer | Source region height.
        /// @param | dst_x | integer | Destination x coordinate.
        /// @param | dst_y | integer | Destination y coordinate.
        /// @param | dst_w | integer | Destination width.
        /// @param | dst_h | integer | Destination height.
        /// @param | inset_left | integer | Left inset width.
        /// @param | inset_right | integer | Right inset width.
        /// @param | inset_top | integer | Top inset height.
        /// @param | inset_bottom | integer | Bottom inset height.
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
        // -- getRegion --
        /// Returns an image region when the requested rectangle is inside bounds.
        /// @param | x | integer | Region x coordinate.
        /// @param | y | integer | Region y coordinate.
        /// @param | w | integer | Region width.
        /// @param | h | integer | Region height.
        /// @return | LImageData|nil | `LImageData` handle, or nil when the region is out of bounds.
        methods.add_method(
            "getRegion",
            |lua, this, (x, y, w, h): (u32, u32, u32, u32)| match this.get_region(x, y, w, h) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            },
        );
        // -- getRawBytes --
        /// Returns raw image bytes as a Lua string.
        /// @return | string | Raw image byte string.
        methods.add_method("getRawBytes", |lua, this, ()| {
            lua.create_string(this.as_bytes())
        });
        // -- diff --
        /// Computes a difference metric against another image.
        /// @param | other_ud | LImageData | Image data handle to compare with this image.
        /// @return | number | Difference score.
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<ImageData>()?;
            Ok(this.diff(&other_ref))
        });
        // -- mapPixels --
        /// Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values.
        /// @param | func | function | Callback receiving `(x, y, r, g, b, a)` and returning replacement channels.
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
        // -- convolve --
        /// Applies a convolution kernel and returns the filtered image.
        /// @param | kernel_t | table | Array table of numeric kernel weights.
        /// @param | ksize | integer | Kernel width and height.
        /// @return | LImageData | Convolved image data handle.
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
        // -- applyPaletteLut --
        /// Applies a palette lookup table to this image in place.
        /// @param | lut_ud | LPaletteLUT | Palette lookup table handle.
        methods.add_method_mut("applyPaletteLut", |_, this, lut_ud: LuaAnyUserData| {
            let lut = lut_ud.borrow::<LuaPaletteLUT>()?;
            lut.inner.apply(this);
            Ok(())
        });
        // -- setRawData --
        /// Replaces the image byte buffer with raw bytes.
        /// @param | bytes | string | Raw byte string matching the image storage size.
        methods.add_method_mut("setRawData", |_, this, bytes: LuaString| {
            this.set_raw_data(bytes.as_bytes())
                .map_err(LuaError::RuntimeError)
        });
        // -- paste --
        /// Pastes a source image into this image at unsigned destination coordinates.
        /// @param | src_ud | LImageData | Source image data handle.
        /// @param | dx | integer | Destination x coordinate.
        /// @param | dy | integer | Destination y coordinate.
        methods.add_method_mut(
            "paste",
            |_, this, (src_ud, dx, dy): (LuaAnyUserData, u32, u32)| {
                let src = src_ud.borrow::<ImageData>()?;
                this.paste(&src, dx, dy);
                Ok(())
            },
        );
        // -- type --
        /// Returns the Lua-visible type name for this image data handle.
        /// @return | string | The string `LImageData`.
        methods.add_method("type", |_, _, ()| Ok("LImageData"));
        // -- typeOf --
        /// Returns whether this image data handle matches the `LImageData` type name.
        /// @param | name | string | Type name to compare against `LImageData` or `Object`.
        /// @return | boolean | True when the supplied type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LImageData" || name == "Object")
        });
    }
}
/// Lua-side handle for palette color remapping.
pub struct LuaPaletteLUT {
    /// Palette lookup table mapping source colors to destination colors.
    inner: crate::image::palette_lut::PaletteLUT,
}
/// Provides Lua methods for editing and applying palette lookup tables.
impl LuaUserData for LuaPaletteLUT {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setColor --
        /// Adds a color mapping from source RGBA channels to destination RGBA channels.
        /// @param | fr | integer | Source red channel.
        /// @param | fg | integer | Source green channel.
        /// @param | fb | integer | Source blue channel.
        /// @param | fa | integer | Source alpha channel.
        /// @param | tr | integer | Destination red channel.
        /// @param | tg | integer | Destination green channel.
        /// @param | tb | integer | Destination blue channel.
        /// @param | ta | integer | Destination alpha channel.
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
        // -- getColorCount --
        /// Returns the number of color mappings in this palette lookup table.
        /// @return | integer | Color mapping count.
        methods.add_method("getColorCount", |_, this, ()| {
            Ok(this.inner.get_color_count())
        });
        // -- clear --
        /// Removes every color mapping from this palette lookup table.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- cycle --
        /// Cycles palette mappings by an offset.
        /// @param | offset | integer | Mapping offset.
        methods.add_method_mut("cycle", |_, this, offset: i32| {
            this.inner.cycle_to_colors(offset);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this palette lookup table handle.
        /// @return | string | The string `LPaletteLUT`.
        methods.add_method("type", |_, _, ()| Ok("LPaletteLUT"));
        // -- typeOf --
        /// Returns whether this palette lookup table handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LPaletteLUT` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPaletteLUT" || name == "Object")
        });
    }
}
