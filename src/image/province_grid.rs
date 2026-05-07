//! Province pixel grid — fast spatial index for strategic map province lookup.
//!
//! Loads a province map PNG where each unique RGB color maps to a province ID.
//! Builds a flat `Vec<u32>` pixel→id array (id=0 means "no province") for O(1)
//! coordinate lookups and a single-pass O(w×h) adjacency detection.
//!
//! This module is part of Lurek2D's `image` subsystem (Platform Services tier).
//! No rendering, no Lua — pure data.

use std::collections::HashMap;

use crate::image::ImageData;

// -------------------------------------------------------------------------------
// Public types
// -------------------------------------------------------------------------------

/// Describes two adjacent provinces and how many pixels they share on their border.
pub struct AdjacencyPair {
    /// Lower province ID in the pair.
    pub province_a: u32,
    /// Higher province ID in the pair.
    pub province_b: u32,
    /// Number of pixel-edges shared between the two provinces.
    pub border_pixels: u32,
}

/// Flat pixel grid mapping every coordinate to a province ID.
///
/// Province IDs are assigned sequentially (1, 2, 3 …) as unique RGB colors are
/// encountered during [`ProvinceGrid::from_image`]. ID 0 always means "background"
/// (pure-black pixels, or out-of-bounds).
///
/// Memory: `4 × width × height` bytes (one `u32` per pixel).
pub struct ProvinceGrid {
    /// Grid width in pixels.
    width: u32,
    /// Grid height in pixels.
    height: u32,
    /// Flat array: `ids[y * width + x]` → province_id (0 = empty/unassigned).
    ids: Vec<u32>,
    /// Sorted list of detected adjacency pairs: (province_a, province_b, shared_border_pixels).
    adjacencies: Vec<(u32, u32, u32)>,
}

// -------------------------------------------------------------------------------
// impl ProvinceGrid
// -------------------------------------------------------------------------------

impl ProvinceGrid {
    /// Build a `ProvinceGrid` from an already-loaded [`ImageData`].
    ///
    /// Each unique RGB value (ignoring alpha) is assigned a sequential province ID
    /// starting at 1. Pure-black pixels `(0, 0, 0)` are treated as background and
    /// receive ID 0. The entire image is scanned in a single O(w×h) pass.
    ///
    /// # Parameters
    /// - `img` — `&ImageData`. Source province map image.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_image(img: &ImageData) -> Self {
        let width = img.width();
        let height = img.height();
        let pixel_count = (width * height) as usize;

        let mut color_to_id: HashMap<u32, u32> = HashMap::new();
        let mut next_id: u32 = 1;
        let mut ids = Vec::with_capacity(pixel_count);

        for y in 0..height {
            for x in 0..width {
                let id = if let Some((r, g, b, _)) = img.get_pixel(x, y) {
                    if r == 0 && g == 0 && b == 0 {
                        0
                    } else {
                        let key = (r as u32) << 16 | (g as u32) << 8 | b as u32;
                        *color_to_id.entry(key).or_insert_with(|| {
                            let id = next_id;
                            next_id += 1;
                            id
                        })
                    }
                } else {
                    0
                };
                ids.push(id);
            }
        }

        let adjacencies = Self::detect_adjacencies_internal(&ids, width, height);

        log::info!(
            "ProvinceGrid: {}x{}, {} provinces, {} adjacencies",
            width,
            height,
            next_id - 1,
            adjacencies.len()
        );

        Self {
            width,
            height,
            ids,
            adjacencies,
        }
    }

    /// Load a province map PNG from disk and build the grid.
    ///
    /// # Parameters
    /// - `path` — `&str`. Filesystem path to a PNG file.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn from_file(path: &str) -> Result<Self, String> {
        let img = ImageData::from_file(path)?;
        Ok(Self::from_image(&img))
    }

    /// Returns the grid width in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Returns the grid height in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Returns the province ID at pixel coordinates `(x, y)`.
    ///
    /// Returns 0 for background pixels or any out-of-bounds coordinate.
    ///
    /// # Parameters
    /// - `x` — `u32`. Pixel column (0-based).
    /// - `y` — `u32`. Pixel row (0-based).
    ///
    /// # Returns
    /// `u32` — province ID, or 0.
    pub fn get_at(&self, x: u32, y: u32) -> u32 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.ids[(y * self.width + x) as usize]
    }

    /// Returns the number of unique non-zero province IDs in the grid.
    ///
    /// # Returns
    /// `u32`.
    pub fn province_count(&self) -> u32 {
        // IDs are assigned 1..next_id, so the count equals the maximum ID value.
        self.ids.iter().copied().max().unwrap_or(0)
    }

    /// Returns a slice of `(province_a, province_b, border_pixel_count)` tuples,
    /// sorted by `(province_a, province_b)`.
    ///
    /// # Returns
    /// `&[(u32, u32, u32)]`.
    pub fn adjacencies(&self) -> &[(u32, u32, u32)] {
        &self.adjacencies
    }

    /// Returns horizontal fill spans for all non-zero provinces.
    ///
    /// Each span is `(province_id, y, x0, x1)` where `x1` is exclusive.
    /// Spans are maximal on each scanline and are suitable for rectangle-based fill rendering.
    pub fn province_spans(&self) -> Vec<(u32, u32, u32, u32)> {
        let mut spans = Vec::new();
        let w = self.width as usize;
        let h = self.height as usize;

        for y in 0..h {
            let row_off = y * w;
            let mut x = 0usize;
            while x < w {
                let id = self.ids[row_off + x];
                if id == 0 {
                    x += 1;
                    continue;
                }

                let x0 = x;
                x += 1;
                while x < w && self.ids[row_off + x] == id {
                    x += 1;
                }
                spans.push((id, y as u32, x0 as u32, x as u32));
            }
        }

        spans
    }

    /// Returns merged border segments between neighboring provinces.
    ///
    /// Each segment is `(province_a, province_b, x0, y0, x1, y1)` in pixel-space,
    /// where `(x0, y0) -> (x1, y1)` is axis-aligned and endpoints are on pixel-edge coordinates.
    ///
    /// - Horizontal segments come from province changes between rows `(y, y+1)`.
    /// - Vertical segments come from province changes between columns `(x, x+1)`.
    pub fn border_segments(&self) -> Vec<(u32, u32, u32, u32, u32, u32)> {
        let mut out = Vec::new();
        let w = self.width as usize;
        let h = self.height as usize;

        // Horizontal boundaries (between y and y+1), merged along x.
        if h >= 2 {
            for y in 0..(h - 1) {
                let top_off = y * w;
                let bot_off = (y + 1) * w;
                let mut x = 0usize;

                while x < w {
                    let a = self.ids[top_off + x];
                    let b = self.ids[bot_off + x];
                    if a == 0 || b == 0 || a == b {
                        x += 1;
                        continue;
                    }

                    let pa = a.min(b);
                    let pb = a.max(b);
                    let x0 = x;
                    x += 1;
                    while x < w {
                        let aa = self.ids[top_off + x];
                        let bb = self.ids[bot_off + x];
                        if aa == 0 || bb == 0 || aa == bb {
                            break;
                        }
                        if aa.min(bb) != pa || aa.max(bb) != pb {
                            break;
                        }
                        x += 1;
                    }

                    out.push((pa, pb, x0 as u32, (y + 1) as u32, x as u32, (y + 1) as u32));
                }
            }
        }

        // Vertical boundaries (between x and x+1), merged along y.
        if w >= 2 {
            for x in 0..(w - 1) {
                let mut y = 0usize;

                while y < h {
                    let a = self.ids[y * w + x];
                    let b = self.ids[y * w + (x + 1)];
                    if a == 0 || b == 0 || a == b {
                        y += 1;
                        continue;
                    }

                    let pa = a.min(b);
                    let pb = a.max(b);
                    let y0 = y;
                    y += 1;
                    while y < h {
                        let aa = self.ids[y * w + x];
                        let bb = self.ids[y * w + (x + 1)];
                        if aa == 0 || bb == 0 || aa == bb {
                            break;
                        }
                        if aa.min(bb) != pa || aa.max(bb) != pb {
                            break;
                        }
                        y += 1;
                    }

                    out.push((pa, pb, (x + 1) as u32, y0 as u32, (x + 1) as u32, y as u32));
                }
            }
        }

        out
    }

    // ---------------------------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------------------------

    /// Single O(w×h) pass that counts shared pixel-edges between neighboring provinces.
    ///
    /// Only the RIGHT `(x+1, y)` and BOTTOM `(x, y+1)` neighbors are checked per pixel
    /// to avoid double-counting. Pairs are stored as `(min, max)` to keep the map
    /// canonical and avoid duplicate keys.
    fn detect_adjacencies_internal(ids: &[u32], width: u32, height: u32) -> Vec<(u32, u32, u32)> {
        let mut counts: HashMap<(u32, u32), u32> = HashMap::new();

        for y in 0..height {
            for x in 0..width {
                let a = ids[(y * width + x) as usize];
                if a == 0 {
                    continue;
                }

                // Check right neighbor
                if x + 1 < width {
                    let b = ids[(y * width + x + 1) as usize];
                    if b != 0 && b != a {
                        let pair = (a.min(b), a.max(b));
                        *counts.entry(pair).or_insert(0) += 1;
                    }
                }

                // Check bottom neighbor
                if y + 1 < height {
                    let b = ids[((y + 1) * width + x) as usize];
                    if b != 0 && b != a {
                        let pair = (a.min(b), a.max(b));
                        *counts.entry(pair).or_insert(0) += 1;
                    }
                }
            }
        }

        let mut result: Vec<(u32, u32, u32)> = counts
            .into_iter()
            .map(|((pa, pb), count)| (pa, pb, count))
            .collect();
        result.sort_by(|a, b| a.0.cmp(&b.0).then(a.1.cmp(&b.1)));
        result
    }

    // ---------------------------------------------------------------------------
    // Serialization for shape-based rendering cache
    // ---------------------------------------------------------------------------

    /// Serializes province geometry for shape-based rendering into a binary cache.
    ///
    /// Format: [magic:4][version:4][width:4][height:4][num_spans:4][spans...][num_segs:4][segs...]
    /// Each span: [province_id:4][y:4][x0:4][x1:4] (all u32 little-endian)
    /// Each segment: [a:4][b:4][x0:4][y0:4][x1:4][y1:4] (all u32 little-endian)
    pub fn serialize_shape_data(&self) -> Vec<u8> {
        const MAGIC: u32 = 0x5348_4150; // "SHAP" in ASCII
        const VERSION: u32 = 1;
        let mut buf = Vec::new();

        // Header
        buf.extend_from_slice(&MAGIC.to_le_bytes());
        buf.extend_from_slice(&VERSION.to_le_bytes());
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());

        // Spans
        let spans = self.province_spans();
        buf.extend_from_slice(&(spans.len() as u32).to_le_bytes());
        for (id, y, x0, x1) in spans {
            buf.extend_from_slice(&id.to_le_bytes());
            buf.extend_from_slice(&y.to_le_bytes());
            buf.extend_from_slice(&x0.to_le_bytes());
            buf.extend_from_slice(&x1.to_le_bytes());
        }

        // Border segments
        let segs = self.border_segments();
        buf.extend_from_slice(&(segs.len() as u32).to_le_bytes());
        for (a, b, x0, y0, x1, y1) in segs {
            buf.extend_from_slice(&a.to_le_bytes());
            buf.extend_from_slice(&b.to_le_bytes());
            buf.extend_from_slice(&x0.to_le_bytes());
            buf.extend_from_slice(&y0.to_le_bytes());
            buf.extend_from_slice(&x1.to_le_bytes());
            buf.extend_from_slice(&y1.to_le_bytes());
        }

        buf
    }

    /// Deserializes province geometry from shape cache binary.
    ///
    /// Returns (spans, segments) or None if format is invalid.
    #[allow(clippy::type_complexity)]
    pub fn deserialize_shape_data(data: &[u8]) -> Option<(Vec<(u32, u32, u32, u32)>, Vec<(u32, u32, u32, u32, u32, u32)>)> {
        if data.len() < 16 {
            return None;
        }

        let mut off = 0usize;
        let magic = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
        off += 4;
        if magic != 0x5348_4150 {
            return None;
        }

        let _version = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
        off += 4;
        let _width = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
        off += 4;
        let _height = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
        off += 4;

        if off + 4 > data.len() {
            return None;
        }
        let num_spans = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]) as usize;
        off += 4;

        let mut spans = Vec::new();
        for _ in 0..num_spans {
            if off + 16 > data.len() {
                return None;
            }
            let id = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let y = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let x0 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let x1 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            spans.push((id, y, x0, x1));
        }

        if off + 4 > data.len() {
            return None;
        }
        let num_segs = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]) as usize;
        off += 4;

        let mut segs = Vec::new();
        for _ in 0..num_segs {
            if off + 24 > data.len() {
                return None;
            }
            let a = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let b = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let x0 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let y0 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let x1 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            let y1 = u32::from_le_bytes([data[off], data[off+1], data[off+2], data[off+3]]);
            off += 4;
            segs.push((a, b, x0, y0, x1, y1));
        }

        Some((spans, segs))
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────
