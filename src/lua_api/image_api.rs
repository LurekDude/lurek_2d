//! `lurek.image` - CPU-side pixel-level image manipulation.
//!
//! Exposes `ImageData` (RGBA pixel buffers), `CompressedImageData` (DXT/BC/ETC),
//! `LayeredImage` (multi-layer compositing), `ProvinceGrid` (colour-keyed region maps),
//! and `PaletteLUT` (palette-swap look-up tables). All operations run on the CPU;
//! upload to GPU is handled by the render layer.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::image::serial;
use crate::image::{CompressedImageData, ImageData, LayeredImage, ProvinceGrid};
use crate::render::{DrawMode, RenderCommand};

// -------------------------------------------------------------------------------
// LuaProvinceGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ProvinceGrid`].
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
    /// Pre-computed per-ring draw data: (r, g, b, flat_unit_vertices).
    /// Built once on the first `drawShapes()` call, then reused every frame.
    shape_cache: Option<Vec<ProvinceShapeCacheEntry>>,
}

impl LuaUserData for LuaProvinceGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the grid width in pixels.
        /// @return | integer | Grid width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));

        // -- getHeight --
        /// Returns the grid height in pixels.
        /// @return | integer | Grid height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));

        // -- getAt --
        /// Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
        /// @param | x | integer | Zero-based pixel x coordinate.
        /// @param | y | integer | Zero-based pixel y coordinate.
        /// @return | integer | Province ID at the given pixel.
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_at(x, y))
        });

        // -- provinceCount --
        /// Returns the number of unique non-zero province IDs detected in the map.
        /// @return | integer | Number of unique non-zero province IDs.
        methods.add_method("provinceCount", |_, this, ()| {
            Ok(this.inner.province_count())
        });

        // -- adjacencies --
        /// Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
        /// @return | table | Adjacency records between neighboring provinces.
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

        // -- provinceSpans --
        /// Returns province fill spans as { province_id, y, x0, x1 } records (x1 exclusive).
        /// Useful for rectangle-based shape rendering without per-province bitmaps.
        /// @return | table | Province fill-span records.
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

        // -- borderSegments --
        /// Returns merged border segments as
        /// { province_a, province_b, x0, y0, x1, y1 } records.
        /// @return | table | Border-segment records.
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

        // -- getPolygons --
        /// Returns the raw border-trace polygon(s) for every province.
        /// Each entry in the returned table is { province_id, rings }, where
        /// rings is an array of point arrays {{ x, y }, ...}.
        /// Points are in pixel-grid space (top-left corner of each pixel).
        /// @return | table | Per-province polygon data.
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

        // -- getPolygonsSimplified --
        /// Same as getPolygons but collinear points are removed and 45° staircase
        /// runs are collapsed to a single diagonal segment.
        /// Use this for rendering outlines or physics shapes — far fewer vertices.
        /// @return | table | Per-province simplified polygon data (same layout as getPolygons).
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

        // -- drawShapes --
        /// Draws all province shapes using their original PNG colours.
        /// Polygons are computed once on the first call and cached — subsequent calls
        /// only push the pre-built draw commands into the render queue.
        /// Optional viewport args `(x, y, w, h)` cull off-screen shapes in world/map space.
        /// @return | nil | No value is returned.
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
            // --- build cache once ---
            if this.shape_cache.is_none() {
                // Use simplified polygons so the cached draw data stays compact.
                // Shared borders are still derived from the same province grid.
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
                            let ring_points: &[(u32, u32)] = if ring.len() >= 2
                                && ring.first() == ring.last()
                            {
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

            // --- push cached commands ---
            let saved_color = this.state.borrow().current_color;
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
                    st.render_commands.push(RenderCommand::SetColor(entry.r, entry.g, entry.b, 1.0));
                    st.render_commands.push(RenderCommand::Polygon {
                        mode: DrawMode::Fill,
                        vertices: entry.vertices.clone(),
                    });
                }
                st.render_commands.push(RenderCommand::SetColor(
                    saved_color[0],
                    saved_color[1],
                    saved_color[2],
                    saved_color[3],
                ));
                st.current_color = saved_color;
            }
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LProvinceGrid"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True if the type name matches LProvinceGrid or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LProvinceGrid" || name == "Object")
        });

        // -- saveShapeCache --
        // -- serializeShapeData --
        /// Serializes province geometry (spans and borders) to raw bytes.
        /// Use lurek.filesystem.writeBytes() to persist. Does NOT write any file.
        /// @return | string | Binary blob (SHAP format) suitable for writeBytes.
        methods.add_method("serializeShapeData", |lua, this, ()| {
            let data = this.inner.serialize_shape_data();
            lua.create_string(&data)
        });

        // -- deserializeShapeData --
        /// Deserializes province geometry from raw bytes produced by serializeShapeData.
        /// @param | bytes | string | Binary blob previously returned by serializeShapeData.
        /// @return | table | { spans, segments } or nil if bytes are invalid.
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

// -------------------------------------------------------------------------------
// LuaLayeredImage UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`LayeredImage`].
pub struct LuaLayeredImage {
    inner: LayeredImage,
}

impl LuaUserData for LuaLayeredImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the canvas width shared by all layers.
        /// @return | integer | Canvas width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));

        // -- getHeight --
        /// Returns the canvas height shared by all layers.
        /// @return | integer | Canvas height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));

        // -- layerCount --
        /// Returns the number of layers in the stack.
        /// @return | integer | Number of layers in the stack.
        methods.add_method("layerCount", |_, this, ()| Ok(this.inner.layer_count()));

        // -- addLayer --
        /// Appends a new blank transparent layer on top and returns its 1-based index.
        /// @param | name | string? | New image layer name.
        /// @return | integer | 1-based index of the new layer.
        methods.add_method_mut("addLayer", |_, this, name: Option<String>| {
            let label = name.unwrap_or_else(|| format!("Layer {}", this.inner.layer_count() + 1));
            let idx = this.inner.add_layer(label);
            Ok(idx + 1) // expose as 1-based
        });

        // -- removeLayer --
        /// Removes the layer at the given 1-based index. Returns true on success.
        /// @param | index | integer | 1-based layer index.
        /// @return | boolean | True if the layer was removed.
        methods.add_method_mut("removeLayer", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.remove_layer(index - 1).is_some())
        });

        // -- getLayer --
        /// Returns a copy of the layer's pixel buffer as an ImageData.
        /// @param | index | integer | 1-based layer index.
        /// @return | ImageData | Image data for the requested layer.
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
        /// Replaces a layer's pixel buffer with a copy of the given ImageData.
        /// @param | index | integer | 1-based layer index.
        /// @param | imagedata | ImageData | Replacement image data.
        /// @return | boolean | True if the layer image was replaced.
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
        /// Returns the opacity of a layer in [0.0, 1.0].
        /// @param | index | integer | 1-based layer index.
        /// @return | number | Layer opacity in the range [0.0, 1.0].
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
        /// Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
        /// @param | index | integer | 1-based layer index.
        /// @param | opacity | number | New layer opacity.
        /// @return | boolean | True if the layer opacity was updated.
        methods.add_method_mut("setOpacity", |_, this, (index, opacity): (usize, f32)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_opacity(index - 1, opacity))
        });

        // -- isVisible --
        /// Returns whether a layer is visible.
        /// @param | index | integer | 1-based layer index.
        /// @return | boolean | True if the layer is visible.
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
        /// Shows or hides a layer during compositing.
        /// @param | index | integer | 1-based layer index.
        /// @param | visible | boolean | New layer visibility state.
        /// @return | boolean | True if the layer visibility was updated.
        methods.add_method_mut("setVisible", |_, this, (index, visible): (usize, bool)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_visible(index - 1, visible))
        });

        // -- getName --
        /// Returns the name of a layer.
        /// @param | index | integer | 1-based layer index.
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
        /// Renames the layer at the given index to the new name string.
        /// @param | index | integer | 1-based layer index.
        /// @param | name | string | New image layer name.
        /// @return | boolean | True if the layer was renamed.
        methods.add_method_mut("setName", |_, this, (index, name): (usize, String)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_name(index - 1, name))
        });

        // -- swapLayers --
        /// Swaps two layers by their 1-based indices, changing their compositing order.
        /// @param | a | integer | First 1-based layer index.
        /// @param | b | integer | Second 1-based layer index.
        /// @return | boolean | True if the two layers were swapped.
        methods.add_method_mut("swapLayers", |_, this, (a, b): (usize, usize)| {
            if a == 0 || b == 0 {
                return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
            }
            Ok(this.inner.swap_layers(a - 1, b - 1))
        });

        // -- moveLayer --
        /// Moves a layer from one position to another, shifting layers in between.
        /// @param | from_index | integer | Current 1-based layer index.
        /// @param | to_index | integer | Target 1-based layer index.
        /// @return | boolean | True if the layer was moved.
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
        /// Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
        /// @return | ImageData | Flattened image of all visible layers.
        methods.add_method("merge", |lua, this, ()| {
            lua.create_userdata(this.inner.merge())
        });

        // -- save --
        /// Saves the layered image to a LIMG binary file at the given path.
        /// @param | path | string | Output file path relative to the game directory.
        /// @return | nil | No value is returned.
        methods.add_method("save", |_, this, path: String| {
            serial::save_layered(&this.inner, &path).map_err(LuaError::external)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LLayeredImage"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True if the type name matches LLayeredImage or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLayeredImage" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaCompressedImageData UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`CompressedImageData`].
pub struct LuaCompressedImageData {
    inner: CompressedImageData,
}

impl LuaUserData for LuaCompressedImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of the base mip level in pixels.
        /// @return | integer | Base mip level width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width));

        // -- getHeight --
        /// Returns the height of the base mip level in pixels.
        /// @return | integer | Base mip level height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height));

        // -- getDimensions --
        /// Returns the width and height of the base mip level.
        /// @return | integer | Image width in pixels.
        /// @return | integer | Image height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- getMipmapCount --
        /// Returns the number of mipmap levels stored.
        /// @return | integer | Number of stored mipmap levels.
        methods.add_method("getMipmapCount", |_, this, ()| {
            Ok(this.inner.get_mipmap_count())
        });

        // -- getFormat --
        /// Returns the compressed format name string.
        /// @return | string | Compressed format name.
        methods.add_method("getFormat", |_, this, ()| {
            Ok(this.inner.get_format().to_string())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LCompressedImageData"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare.
        /// @return | boolean | True if the type name matches LCompressedImageData or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCompressedImageData" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.image` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newImageData --
    /// Creates a new blank ImageData or loads one from a file.
    /// @param | width_or_filename | integer|string | Image width, or filename to load.
    /// @param | height | integer? | Image height when creating a blank image.
    /// @return | ImageData | New or loaded image data.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// Creates an ImageData from a raw RGBA8 byte string. Width Ă— height Ă— 4 bytes required.
    /// @param | width | integer | Image width in pixels.
    /// @param | height | integer | Image height in pixels.
    /// @param | bytes | string | Raw RGBA8 pixel data (width Ă— height Ă— 4 bytes).
    /// @return | ImageData | New image data backed by the provided bytes.
    tbl.set(
        "newImageDataFromBytes",
        lua.create_function(move |lua, (w, h, bytes): (u32, u32, LuaString)| {
            let raw = bytes.as_bytes().to_vec();
            let img = ImageData::from_bytes(w, h, raw).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(img)
        })?,
    )?;

    // -- newCompressedData --
    /// Loads compressed texture data from a DDS file.
    /// @param | filename | string | DDS file path relative to the game directory.
    /// @return | CompressedImageData | Loaded compressed texture data.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- isCompressed --
    /// Returns true if the file at the given path is a DDS file.
    /// @param | filename | string | File path to test.
    /// @return | boolean | True if the file is a DDS image.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// Creates a new empty LayeredImage canvas with no layers.
    /// @param | width | integer | Canvas width in pixels.
    /// @param | height | integer | Canvas height in pixels.
    /// @return | LayeredImage | New empty layered image.
    tbl.set(
        "newLayeredImage",
        lua.create_function(move |lua, (width, height): (u32, u32)| {
            lua.create_userdata(LuaLayeredImage {
                inner: LayeredImage::new(width, height),
            })
        })?,
    )?;

    // -- saveImage --
    /// Saves a flat ImageData to a LIMG binary file at the given path.
    /// @param | imagedata | ImageData | Image data to save.
    /// @param | path | string | Output file path relative to the game directory.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- savePNG --
    /// Saves a flat ImageData as a PNG file at the given path.
    /// @param | imagedata | ImageData | Image data to save.
    /// @param | path | string | Output PNG path relative to the game directory.
    /// @return | nil | No value is returned.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- loadImage --
    /// Loads an ImageData from a LIMG binary file.
    /// @param | path | string | Input LIMG path relative to the game directory.
    /// @return | ImageData | Loaded image data.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- loadLayered --
    /// Loads a LayeredImage from a LIMG binary file.
    /// @param | path | string | Input layered image path relative to the game directory.
    /// @return | LayeredImage | Loaded layered image.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// Creates a new empty `PaletteLUT` used to remap colours in an image.
    /// @return | PaletteLUT | New empty palette lookup table.
    tbl.set(
        "newPaletteLut",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaPaletteLUT {
                inner: crate::image::palette_lut::PaletteLUT::new(),
            })
        })?,
    )?;
    // -- newProvinceGrid -------------------------------------------------
    // -- newProvinceGrid --
    /// Loads a province map PNG and builds an O(1) spatial index with adjacency data.
    /// Each unique RGB color in the PNG is assigned a sequential province ID (1..n).
    /// Black pixels (0,0,0) are treated as background and return ID 0.
    /// @param | filename | string | Province map PNG path relative to the game directory.
    /// @return | ProvinceGrid | Loaded province grid with adjacency data.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- fromScreen --
    /// Returns a screen capture `ImageData` when ready; otherwise queues capture for next frame and returns nil.
    ///
    /// This is an async poll API: the first call typically returns nil, then a later call
    /// returns the captured pixels after the renderer completes a readback.
    ///
    /// @return | ImageData | Captured screen image when ready.
    /// @return | nil | Returned when capture is pending; call again on a later frame.
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

// -- getWidth --
/// RGBA pixel buffer for software image manipulation, pixel access, and encoding.
impl mlua::UserData for ImageData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of the image in pixels.
        ///
        /// @return | integer | Image width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.width()));
        // -- getHeight --
        /// Returns the height of the image in pixels.
        ///
        /// @return | integer | Image height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.height()));
        // -- getDimensions --
        /// Returns the width and height of the image as two integers.
        ///
        /// @return | integer | Image width in pixels.
        /// @return | integer | Image height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.dimensions();
            Ok((w, h))
        });
        // -- getPixel --
        /// Returns the RGBA colour components of the pixel at (x, y) as four integers (0-255).
        ///
        /// @param | x | integer | Zero-based pixel x coordinate.
        /// @param | y | integer | Zero-based pixel y coordinate.
        /// @return | integer | Red channel value.
        /// @return | integer | Green channel value.
        /// @return | integer | Blue channel value.
        /// @return | integer | Alpha channel value.
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
        /// Sets the RGBA colour of the pixel at (x, y); returns an error if coordinates are out of bounds.
        ///
        /// @param | x | integer | Zero-based pixel x coordinate.
        /// @param | y | integer | Zero-based pixel y coordinate.
        /// @param | r | integer | red [0-255].
        /// @param | g | integer | green [0-255].
        /// @param | b | integer | blue [0-255].
        /// @param | a | integer | alpha [0-255].
        /// @return | nil | No value is returned.
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
        /// Encodes the image into a byte string in the specified format (currently "png").
        ///
        /// @param | format | string | encoding format; "png" is the only supported value.
        /// @return | string | Encoded image bytes as a Lua string.
        methods.add_method("encode", |_, this, format: String| match format.as_str() {
            "png" => this.encode_png().map_err(LuaError::RuntimeError),
            _ => Err(LuaError::RuntimeError(format!(
                "Unknown image format: '{}'. Use 'png'.",
                format
            ))),
        });
        // -- getString --
        /// Returns the raw pixel bytes of the image as a Lua string.
        ///
        /// @return | string | Raw RGBA pixel bytes.
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));

        // -- mapPixel --
        /// Calls func(x, y, r, g, b, a) for each pixel and writes the returned RGBA back.
        ///
        /// @param | func | function | Callback that returns replacement RGBA values.
        /// @return | nil | No value is returned.
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
        /// Adjusts the brightness of every pixel by the given factor (< 1.0 darkens, > 1.0 brightens).
        ///
        /// @param | factor | number | Brightness multiplier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("brightness", |_, this, factor: f32| {
            this.brightness(factor);
            Ok(())
        });
        // -- contrast --
        /// Adjusts the contrast of every pixel by the given factor (< 1.0 reduces, > 1.0 increases).
        ///
        /// @param | factor | number | Contrast multiplier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("contrast", |_, this, factor: f32| {
            this.contrast(factor);
            Ok(())
        });
        // -- saturation --
        /// Adjusts colour saturation; 0.0 produces grayscale, 1.0 is unchanged, > 1.0 boosts saturation.
        ///
        /// @param | factor | number | Saturation multiplier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("saturation", |_, this, factor: f32| {
            this.saturation(factor);
            Ok(())
        });
        // -- gamma --
        /// Applies gamma correction; values < 1.0 brighten shadows, > 1.0 darken them.
        ///
        /// @param | gamma | number | Gamma correction value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("gamma", |_, this, gamma: f32| {
            this.gamma(gamma);
            Ok(())
        });
        // -- tint --
        /// Blends an RGB tint colour into every pixel, controlled by factor (0.0 = no change, 1.0 = full tint).
        ///
        /// @param | tr | integer | red component [0-255].
        /// @param | tg | integer | green component [0-255].
        /// @param | tb | integer | blue component [0-255].
        /// @param | factor | number | blend weight [0.0-1.0].
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "tint",
            |_, this, (tr, tg, tb, factor): (u8, u8, u8, f32)| {
                this.tint(tr, tg, tb, factor);
                Ok(())
            },
        );
        // -- grayscale --
        /// Converts the image to grayscale using luminance weights (BT.601).
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("grayscale", |_, this, ()| {
            this.grayscale();
            Ok(())
        });
        // -- sepia --
        /// Applies a warm sepia tone to the image using standard sepia matrix weights.
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("sepia", |_, this, ()| {
            this.sepia();
            Ok(())
        });
        // -- invert --
        /// Inverts every colour channel (subtracts each R/G/B value from 255); alpha is preserved.
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("invert", |_, this, ()| {
            this.invert();
            Ok(())
        });
        // -- threshold --
        /// Converts the image to black-and-white: pixels above value become white, at or below become black.
        ///
        /// @param | value | integer | threshold [0-255].
        /// @return | nil | No value is returned.
        methods.add_method_mut("threshold", |_, this, value: u8| {
            this.threshold(value);
            Ok(())
        });
        // -- posterize --
        /// Reduces each channel to `levels` discrete steps, creating a flat poster-paint look.
        ///
        /// @param | levels | integer | number of colour levels per channel [1-255].
        /// @return | nil | No value is returned.
        methods.add_method_mut("posterize", |_, this, levels: u8| {
            this.posterize(levels);
            Ok(())
        });
        // -- fill --
        /// Fills every pixel with the given solid RGBA colour, overwriting all existing content.
        ///
        /// @param | r | integer | red [0-255].
        /// @param | g | integer | green [0-255].
        /// @param | b | integer | blue [0-255].
        /// @param | a | integer | alpha [0-255].
        /// @return | nil | No value is returned.
        methods.add_method_mut("fill", |_, this, (r, g, b, a): (u8, u8, u8, u8)| {
            this.fill(r, g, b, a);
            Ok(())
        });
        // -- noise --
        /// Adds random noise to every pixel channel; amount controls the maximum per-channel perturbation.
        ///
        /// @param | amount | integer | max perturbation per channel [0-255].
        /// @return | nil | No value is returned.
        methods.add_method_mut("noise", |_, this, amount: u8| {
            this.noise(amount);
            Ok(())
        });
        // -- alphaMask --
        /// Scales every pixel's alpha channel by factor; use to fade an image in or out uniformly.
        ///
        /// @param | factor | number | multiplier for the alpha channel [0.0-1.0].
        /// @return | nil | No value is returned.
        methods.add_method_mut("alphaMask", |_, this, factor: f32| {
            this.alpha_mask(factor);
            Ok(())
        });
        // -- flipHorizontal --
        /// Flips the image left-to-right (mirror across vertical axis), modifying in place.
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("flipHorizontal", |_, this, ()| {
            this.flip_horizontal();
            Ok(())
        });
        // -- flipVertical --
        /// Flips the image top-to-bottom (mirror across horizontal axis), modifying in place.
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("flipVertical", |_, this, ()| {
            this.flip_vertical();
            Ok(())
        });
        // -- rotate90cw --
        /// Returns a new ImageData rotated 90 degrees clockwise; the original is not modified.
        ///
        /// @return | ImageData | New ImageData rotated 90 degrees clockwise; the original is not modified.
        methods.add_method("rotate90cw", |lua, this, ()| {
            lua.create_userdata(this.rotate_90_cw())
        });
        // -- crop --
        /// Returns a new ImageData containing the rectangular sub-region at (x, y) of the given width and height.
        ///
        /// @param | x | integer | X position.
        /// @param | y | integer | Y position.
        /// @param | w | integer | Width value.
        /// @param | h | integer | Height value.
        /// @return | ImageData | New ImageData containing the rectangular sub-region at (x, y) of the given width and height.
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
        /// Returns a new ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
        ///
        /// @param | new_w | integer | New width in pixels.
        /// @param | new_h | integer | New height in pixels.
        /// @return | ImageData | New ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
        methods.add_method("resizeNearest", |lua, this, (new_w, new_h): (u32, u32)| {
            lua.create_userdata(this.resize_nearest(new_w, new_h))
        });
        // -- blur --
        /// Returns a new ImageData with a box blur applied using the given pixel radius.
        ///
        /// @param | radius | integer | Radius value.
        /// @return | ImageData | New ImageData with a box blur applied using the given pixel radius.
        methods.add_method("blur", |lua, this, radius: u32| {
            lua.create_userdata(this.blur(radius))
        });
        // -- sharpen --
        /// Returns a new ImageData with a sharpening convolution kernel applied.
        ///
        /// @return | ImageData | New ImageData with a sharpening convolution kernel applied.
        methods.add_method("sharpen", |lua, this, ()| {
            lua.create_userdata(this.sharpen())
        });
        // -- drawRect --
        /// Draws a filled rectangle onto the image.
        /// @param | x | integer | X position.
        /// @param | y | integer | Y position.
        /// @param | w | integer | Width value.
        /// @param | h | integer | Height value.
        /// @param | r | integer | Red component.
        /// @param | g | integer | Green component.
        /// @param | b | integer | Blue component.
        /// @param | a | integer | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, r, g, b, a): (i32, i32, u32, u32, u8, u8, u8, u8)| {
                this.draw_rect(x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        // -- drawCircle --
        /// Draws a filled circle onto the image.
        /// @param | cx | integer | Center X position.
        /// @param | cy | integer | Center Y position.
        /// @param | radius | integer | Radius value.
        /// @param | r | integer | Red component.
        /// @param | g | integer | Green component.
        /// @param | b | integer | Blue component.
        /// @param | a | integer | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "drawCircle",
            |_, this, (cx, cy, radius, r, g, b, a): (i32, i32, u32, u8, u8, u8, u8)| {
                this.draw_circle(cx, cy, radius, r, g, b, a);
                Ok(())
            },
        );
        // -- drawLine --
        /// Draws a line using Bresenham's algorithm.
        /// @param | x0 | integer | Start X position.
        /// @param | y0 | integer | Start Y position.
        /// @param | x1 | integer | End X position.
        /// @param | y1 | integer | End Y position.
        /// @param | r | integer | Red component.
        /// @param | g | integer | Green component.
        /// @param | b | integer | Blue component.
        /// @param | a | integer | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "drawLine",
            |_, this, (x0, y0, x1, y1, r, g, b, a): (i32, i32, i32, i32, u8, u8, u8, u8)| {
                this.draw_line(x0, y0, x1, y1, r, g, b, a);
                Ok(())
            },
        );

        // -- resize --
        /// Returns a bilinear-interpolated copy of the image at the given dimensions.
        ///
        /// Returns nil if either dimension is zero or the source image is empty.
        ///
        /// @param | width | integer | Width in pixels.
        /// @param | height | integer | Height in pixels.
        /// @param | filter | string? | Optional filter: "bilinear" (default) or "lanczos3".
        /// @return | ImageData | Bilinear-interpolated copy of the image at the given dimensions.
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
        /// Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff over.
        ///
        /// Out-of-bounds pixels are silently clipped.
        ///
        /// @param | src | ImageData | Source image data.
        /// @param | dst_x | integer | Destination X position.
        /// @param | dst_y | integer | Destination Y position.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<ImageData>()?;
                this.blit(&src_ref, dst_x, dst_y);
                Ok(())
            },
        );

        // -- drawNineSlice --
        #[allow(clippy::type_complexity)]
        /// Draws a nine-slice patch from a source atlas image into this image.
        ///
        /// Source rect is defined by `(src_x, src_y, src_w, src_h)`. Insets split
        /// that rect into corners, edges, and center; corners keep fixed size while
        /// edges/center stretch to destination size.
        ///
        /// @param | source | ImageData | Atlas/source image that contains the patch.
        /// @param | src_x | integer | Source X in source image.
        /// @param | src_y | integer | Source Y in source image.
        /// @param | src_w | integer | Source width.
        /// @param | src_h | integer | Source height.
        /// @param | dst_x | integer | Destination X in this image.
        /// @param | dst_y | integer | Destination Y in this image.
        /// @param | dst_w | integer | Destination width.
        /// @param | dst_h | integer | Destination height.
        /// @param | inset_left | integer | Left inset from atlas metadata.
        /// @param | inset_right | integer | Right inset from atlas metadata.
        /// @param | inset_top | integer | Top inset from atlas metadata.
        /// @param | inset_bottom | integer | Bottom inset from atlas metadata.
        /// @return | nil | No value is returned.
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
        /// Returns a copy of the rectangular sub-region as a new ImageData.
        ///
        /// Returns nil if the region is empty or entirely outside the image.
        ///
        /// @param | x | integer | X position.
        /// @param | y | integer | Y position.
        /// @param | width | integer | Width in pixels.
        /// @param | height | integer | Height in pixels.
        /// @return | ImageData | Copy of the rectangular sub-region as a new ImageData.
        methods.add_method(
            "getRegion",
            |lua, this, (x, y, w, h): (u32, u32, u32, u32)| match this.get_region(x, y, w, h) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            },
        );

        // -- getRawBytes --
        /// Returns the raw RGBA8 pixel data as a Lua string (width Ă— height Ă— 4 bytes).
        /// @return | string | Raw RGBA8 pixel bytes in row-major order.
        methods.add_method("getRawBytes", |lua, this, ()| {
            lua.create_string(this.as_bytes())
        });

        // -- diff --
        /// Returns the sum of absolute per-channel pixel differences with another ImageData.
        ///
        /// Returns `u32::MAX` when the two images have different dimensions.
        ///
        /// @param | other | ImageData | Other input value.
        /// @return | integer | Sum of absolute per-channel pixel differences.
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<ImageData>()?;
            Ok(this.diff(&other_ref))
        });

        // -- mapPixels --
        /// Applies a function to every pixel in-place.
        ///
        /// The callback receives `(x, y, r, g, b, a)` (integers 0-255) and must return
        /// `r, g, b, a`. Pixels are visited in row-major order.
        ///
        /// @param | fn | function | Fn value.
        /// @return | nil | No value is returned.
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
        /// Applies a custom NxN convolution kernel to the image and returns a new ImageData.
        ///
        /// `kernel` is a flat table of N*N weights in row-major order.
        /// `ksize` must be odd and satisfy `ksize * ksize == #kernel`.
        /// RGB channels are convolved; alpha is copied unchanged.
        /// Output values are clamped to [0, 255].
        ///
        /// @param | kernel | table | Kernel coefficient table.
        /// @param | ksize | integer | Kernel size.
        /// @return | ImageData | Image data object.
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
        /// Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
        ///
        /// @param | lut | PaletteLUT | Palette lookup table.
        /// @return | nil | No value is returned.
        methods.add_method_mut("applyPaletteLut", |_, this, lut_ud: LuaAnyUserData| {
            let lut = lut_ud.borrow::<LuaPaletteLUT>()?;
            lut.inner.apply(this);
            Ok(())
        });

        // -- setRawData --
        /// Replaces all pixel data from a raw RGBA byte string.
        /// The string length must equal `width * height * 4`.
        ///
        /// @param | bytes | string | Encoded byte string.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setRawData", |_, this, bytes: LuaString| {
            this.set_raw_data(bytes.as_bytes())
                .map_err(LuaError::RuntimeError)
        });

        // -- paste --
        /// Copies pixels from `source` onto this image starting at (dx, dy).
        /// Pixels that fall outside the destination bounds are clipped.
        ///
        /// @param | source | ImageData | Source image data.
        /// @param | dx | integer | Dx value.
        /// @param | dy | integer | Dy value.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "paste",
            |_, this, (src_ud, dx, dy): (LuaAnyUserData, u32, u32)| {
                let src = src_ud.borrow::<ImageData>()?;
                this.paste(&src, dx, dy);
                Ok(())
            },
        );

        // -- type --
        /// Returns the type name of this object.
        ///
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LImageData"));
        // -- typeOf --
        /// Returns true if this object is of the given type name.
        ///
        /// @param | name | string | Name string.
        /// @return | boolean | True if the type name matches ImageData.
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "ImageData"));
    }
}

// -------------------------------------------------------------------------------
// LuaPaletteLUT UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PaletteLUT`].
pub struct LuaPaletteLUT {
    inner: crate::image::palette_lut::PaletteLUT,
}

impl LuaUserData for LuaPaletteLUT {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Appends a colour mapping entry to the palette: when a pixel exactly matching
        /// `from_r, from_g, from_b, from_a` (0-255) is encountered it is replaced by
        /// `to_r, to_g, to_b, to_a`.
        ///
        /// @param | from_r | integer | 0-255.
        /// @param | from_g | integer | 0-255.
        // -- setColor --
        /// @param | from_b | integer | 0-255.
        /// @param | from_a | integer | 0-255  (255 = fully opaque).
        /// @param | to_r | integer | 0-255.
        /// @param | to_g | integer | 0-255.
        /// @param | to_b | integer | 0-255.
        /// @param | to_a | integer | 0-255.
        /// @return | nil | No value is returned.
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
        /// Returns the number of colour mapping entries.
        ///
        /// @return | integer | Number of colour mapping entries.
        methods.add_method("getColorCount", |_, this, ()| {
            Ok(this.inner.get_color_count())
        });

        // -- clear --
        /// Removes all colour mapping entries.
        ///
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- cycle --
        /// Rotates destination palette entries for palette-cycling animation.
        ///
        /// Positive values rotate to the right, negative values rotate to the left.
        /// The source-color side of the LUT stays unchanged.
        ///
        /// @param | offset | integer | Rotation offset in entries.
        /// @return | nil | No value is returned.
        methods.add_method_mut("cycle", |_, this, offset: i32| {
            this.inner.cycle_to_colors(offset);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LPaletteLUT"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Name string.
        /// @return | boolean | True if the type name matches LPaletteLUT or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPaletteLUT" || name == "Object")
        });
    }
}
