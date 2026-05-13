use std::collections::HashMap;
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NineSliceInsets {
    pub left: u32,
    pub right: u32,
    pub top: u32,
    pub bottom: u32,
}
#[derive(Debug, Clone)]
pub struct AtlasRegion {
    pub name: String,
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
    pub nine_slice: Option<NineSliceInsets>,
}
struct Shelf {
    y: u32,
    height: u32,
    x_used: u32,
}
pub struct TextureAtlas {
    pub width: u32,
    pub height: u32,
    pub padding: u32,
    regions: HashMap<String, AtlasRegion>,
    shelves: Vec<Shelf>,
}
impl TextureAtlas {
    pub fn new(width: u32, height: u32, padding: u32) -> Self {
        Self {
            width,
            height,
            padding,
            regions: HashMap::new(),
            shelves: Vec::new(),
        }
    }
    pub fn pack(&mut self, name: &str, w: u32, h: u32) -> bool {
        self.pack_with_nine_slice(name, w, h, None)
    }
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
    pub fn get_region(&self, name: &str) -> Option<&AtlasRegion> {
        self.regions.get(name)
    }
    pub fn get_region_count(&self) -> usize {
        self.regions.len()
    }
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn get_regions(&self) -> Vec<&AtlasRegion> {
        self.regions.values().collect()
    }
    pub fn clear(&mut self) {
        self.regions.clear();
        self.shelves.clear();
    }
}
