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

    // ---------------------------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------------------------

    /// Single O(w×h) pass that counts shared pixel-edges between neighboring provinces.
    ///
    /// Only the RIGHT `(x+1, y)` and BOTTOM `(x, y+1)` neighbors are checked per pixel
    /// to avoid double-counting. Pairs are stored as `(min, max)` to keep the map
    /// canonical and avoid duplicate keys.
    fn detect_adjacencies_internal(
        ids: &[u32],
        width: u32,
        height: u32,
    ) -> Vec<(u32, u32, u32)> {
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
}
