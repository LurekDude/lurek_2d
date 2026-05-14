
use std::collections::HashMap;
/// Nine-slice border distances used to preserve corners and edges.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NineSliceInsets {
    /// Left border width in pixels.
    pub left: u32,
    /// Right border width in pixels.
    pub right: u32,
    /// Top border height in pixels.
    pub top: u32,
    /// Bottom border height in pixels.
    pub bottom: u32,
}
/// A packed atlas region with coordinates, size, and optional nine-slice data.
#[derive(Debug, Clone)]
pub struct AtlasRegion {
    /// Region name used for lookup.
    pub name: String,
    /// Left coordinate in atlas pixels.
    pub x: u32,
    /// Top coordinate in atlas pixels.
    pub y: u32,
    /// Region width in pixels.
    pub w: u32,
    /// Region height in pixels.
    pub h: u32,
    /// Optional nine-slice border metadata.
    pub nine_slice: Option<NineSliceInsets>,
}
/// Single packing shelf tracked by the atlas allocator.
struct Shelf {
    /// Shelf top coordinate.
    y: u32,
    /// Shelf height including padding.
    height: u32,
    /// Horizontal pixels consumed on this shelf.
    x_used: u32,
}
/// Shelf-based texture atlas for packing named regions into a fixed canvas.
pub struct TextureAtlas {
    /// Atlas width in pixels.
    pub width: u32,
    /// Atlas height in pixels.
    pub height: u32,
    /// Padding added around packed regions.
    pub padding: u32,
    /// Packed regions keyed by name.
    regions: HashMap<String, AtlasRegion>,
    /// Active shelf list used by the packer.
    shelves: Vec<Shelf>,
}
impl TextureAtlas {
    /// Create an empty atlas with the given dimensions and padding.
    pub fn new(width: u32, height: u32, padding: u32) -> Self {
        Self {
            width,
            height,
            padding,
            regions: HashMap::new(),
            shelves: Vec::new(),
        }
    }
    /// Pack a region without nine-slice metadata and return whether it fit.
    pub fn pack(&mut self, name: &str, w: u32, h: u32) -> bool {
        self.pack_with_nine_slice(name, w, h, None)
    }
    /// Pack a region with optional nine-slice metadata and return whether it fit.
    pub fn pack_with_nine_slice(
        &mut self,
        name: &str,
        w: u32,
        h: u32,
        nine_slice: Option<NineSliceInsets>,
    ) -> bool {
        if let Some(insets) = nine_slice {
            if insets.left + insets.right > w || insets.top + insets.bottom > h {
                return false;
            }
        }
        let padded_w = w + self.padding;
        let padded_h = h + self.padding;
        for shelf in &mut self.shelves {
            if shelf.height >= padded_h && shelf.x_used + padded_w <= self.width {
                let region = AtlasRegion {
                    name: name.to_string(),
                    x: shelf.x_used + self.padding,
                    y: shelf.y + self.padding,
                    w,
                    h,
                    nine_slice,
                };
                shelf.x_used += padded_w;
                self.regions.insert(name.to_string(), region);
                return true;
            }
        }
        let shelf_y = if let Some(last) = self.shelves.last() {
            last.y + last.height
        } else {
            0
        };
        if shelf_y + padded_h > self.height {
            return false;
        }
        if padded_w > self.width {
            return false;
        }
        let region = AtlasRegion {
            name: name.to_string(),
            x: self.padding,
            y: shelf_y + self.padding,
            w,
            h,
            nine_slice,
        };
        self.shelves.push(Shelf {
            y: shelf_y,
            height: padded_h,
            x_used: padded_w,
        });
        self.regions.insert(name.to_string(), region);
        true
    }
    /// Update the nine-slice metadata for a packed region and return whether it fit.
    pub fn set_nine_slice(&mut self, name: &str, nine_slice: Option<NineSliceInsets>) -> bool {
        let Some(region) = self.regions.get_mut(name) else {
            return false;
        };
        if let Some(insets) = nine_slice {
            if insets.left + insets.right > region.w || insets.top + insets.bottom > region.h {
                return false;
            }
        }
        region.nine_slice = nine_slice;
        true
    }
    /// Return a packed region by name.
    pub fn get_region(&self, name: &str) -> Option<&AtlasRegion> {
        self.regions.get(name)
    }
    /// Return the number of packed regions.
    pub fn get_region_count(&self) -> usize {
        self.regions.len()
    }
    /// Return the atlas dimensions.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Return all packed regions as borrowed values.
    pub fn get_regions(&self) -> Vec<&AtlasRegion> {
        self.regions.values().collect()
    }
    /// Remove all packed regions and shelves.
    pub fn clear(&mut self) {
        self.regions.clear();
        self.shelves.clear();
    }
}
