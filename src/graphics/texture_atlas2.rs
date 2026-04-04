//! CPU-side bin-packing texture atlas using a shelf algorithm.
//!
//! Packs named rectangular regions into a fixed-size atlas without any
//! GPU interaction. Useful for building sprite-sheet layouts at load time.

use std::collections::HashMap;

/// A named rectangular region packed into the atlas.
///
/// # Fields
/// - `name` — `String`.
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `w` — `u32`.
/// - `h` — `u32`.
#[derive(Debug, Clone)]
pub struct AtlasRegion {
    /// Name identifying this region.
    pub name: String,
    /// X offset of the region in the atlas (pixels).
    pub x: u32,
    /// Y offset of the region in the atlas (pixels).
    pub y: u32,
    /// Width of the region (pixels).
    pub w: u32,
    /// Height of the region (pixels).
    pub h: u32,
}

/// Internal shelf for the packing algorithm.
struct Shelf {
    /// Y offset of this shelf in the atlas.
    y: u32,
    /// Maximum height of items placed on this shelf.
    height: u32,
    /// Horizontal space consumed so far.
    x_used: u32,
}

/// CPU-side bin-packing atlas for sprite regions.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `padding` — `u32`.
///
/// Uses a shelf-packing algorithm: regions are placed left-to-right on
/// horizontal shelves. When a region does not fit on any existing shelf a
/// new shelf is opened below the last one.
pub struct TextureAtlas {
    /// Total atlas width in pixels.
    pub width: u32,
    /// Total atlas height in pixels.
    pub height: u32,
    /// Padding in pixels between regions.
    pub padding: u32,
    /// Packed regions keyed by name.
    regions: HashMap<String, AtlasRegion>,
    /// Active shelves used by the packing algorithm.
    shelves: Vec<Shelf>,
}

impl TextureAtlas {
    /// Creates an empty atlas with the given pixel dimensions and inter-region padding.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `padding` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32, padding: u32) -> Self {
        Self {
            width,
            height,
            padding,
            regions: HashMap::new(),
            shelves: Vec::new(),
        }
    }

    /// Packs a named region of size `w` x `h` into the atlas.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if the region was placed successfully, or `false` if
    /// the atlas does not have enough remaining space.
    pub fn pack(&mut self, name: &str, w: u32, h: u32) -> bool {
        let padded_w = w + self.padding;
        let padded_h = h + self.padding;

        // Try existing shelves.
        for shelf in &mut self.shelves {
            if shelf.height >= padded_h && shelf.x_used + padded_w <= self.width {
                let region = AtlasRegion {
                    name: name.to_string(),
                    x: shelf.x_used + self.padding,
                    y: shelf.y + self.padding,
                    w,
                    h,
                };
                shelf.x_used += padded_w;
                self.regions.insert(name.to_string(), region);
                return true;
            }
        }

        // Try to open a new shelf.
        let shelf_y = if let Some(last) = self.shelves.last() {
            last.y + last.height
        } else {
            0
        };

        if shelf_y + padded_h > self.height {
            return false; // No vertical space left.
        }

        if padded_w > self.width {
            return false; // Region wider than the atlas.
        }

        let region = AtlasRegion {
            name: name.to_string(),
            x: self.padding,
            y: shelf_y + self.padding,
            w,
            h,
        };

        self.shelves.push(Shelf {
            y: shelf_y,
            height: padded_h,
            x_used: padded_w,
        });

        self.regions.insert(name.to_string(), region);
        true
    }

    /// Looks up a previously packed region by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&AtlasRegion>`.
    pub fn get_region(&self, name: &str) -> Option<&AtlasRegion> {
        self.regions.get(name)
    }

    /// Returns the number of packed regions. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_region_count(&self) -> usize {
        self.regions.len()
    }

    /// Returns the atlas dimensions as `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns all packed regions in arbitrary order.
    ///
    /// # Returns
    /// `Vec<&AtlasRegion>`.
    pub fn get_regions(&self) -> Vec<&AtlasRegion> {
        self.regions.values().collect()
    }

    /// Removes all packed regions and shelves. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.regions.clear();
        self.shelves.clear();
    }
}
