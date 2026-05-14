//! Texture atlas region map and sprite atlas parsers for TexturePacker and Aseprite JSON formats.
//! Owns AtlasEntry, SpriteAtlas, parse_texturepacker_json, parse_aseprite_json, and related helpers.
//! Does not own texture upload or GPU state — callers read AtlasEntry UV data and pass it to the renderer.
//! Key dependencies: serde_json for JSON parsing, image::TextureAtlas for from_texture_atlas construction.

use std::collections::HashMap;
/// Named sub-region of a texture atlas with pixel coordinates, size, and flip/rotate flags.
#[derive(Debug, Clone)]
pub struct AtlasEntry {
    /// Region name used as the lookup key in SpriteAtlas.
    pub name: String,
    /// Left pixel coordinate of the region in the source texture.
    pub x: u32,
    /// Top pixel coordinate of the region in the source texture.
    pub y: u32,
    /// Width of the region in pixels.
    pub w: u32,
    /// Height of the region in pixels.
    pub h: u32,
    /// True when the source packer stored this region rotated 90° clockwise.
    pub rotated: bool,
    /// True when the region should be rendered horizontally flipped.
    pub flip_x: bool,
    /// True when the region should be rendered vertically flipped.
    pub flip_y: bool,
}
/// Flip accessor for AtlasEntry.
impl AtlasEntry {
    /// Clone this entry with the flip_x and flip_y flags replaced by the given values.
    pub fn get_flipped(&self, flip_x: bool, flip_y: bool) -> AtlasEntry {
        let mut cloned = self.clone();
        cloned.flip_x = flip_x;
        cloned.flip_y = flip_y;
        cloned
    }
}
/// Named-region lookup table backed by a Vec for ordered access and a HashMap for O(1) lookup.
#[derive(Debug, Clone)]
pub struct SpriteAtlas {
    /// Ordered entry array; index matches name_map values.
    entries: Vec<AtlasEntry>,
    /// Name-to-index map for O(1) lookup by region name.
    name_map: HashMap<String, usize>,
}
/// Construction and lookup methods for SpriteAtlas.
impl SpriteAtlas {
    /// Create an empty atlas with no entries.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            name_map: HashMap::new(),
        }
    }
    /// Build a SpriteAtlas from an image::TextureAtlas, sorting regions by name.
    pub fn from_texture_atlas(atlas: &crate::image::TextureAtlas) -> Self {
        let mut out = Self::new();
        let mut regions = atlas.get_regions();
        regions.sort_by(|a, b| a.name.cmp(&b.name));
        for region in regions {
            out.add_entry(AtlasEntry {
                name: region.name.clone(),
                x: region.x,
                y: region.y,
                w: region.w,
                h: region.h,
                rotated: false,
                flip_x: false,
                flip_y: false,
            });
        }
        out
    }
    /// Insert or replace an entry by name; updates both the Vec and the name map.
    pub fn add_entry(&mut self, entry: AtlasEntry) {
        if let Some(&idx) = self.name_map.get(&entry.name) {
            self.entries[idx] = entry;
        } else {
            let idx = self.entries.len();
            self.name_map.insert(entry.name.clone(), idx);
            self.entries.push(entry);
        }
    }
    /// Look up a region by name; returns None when not present.
    pub fn get_entry(&self, name: &str) -> Option<&AtlasEntry> {
        self.name_map.get(name).and_then(|&i| self.entries.get(i))
    }
    /// Return the entry at the given insertion-order index, or None when out of bounds.
    pub fn get_by_index(&self, index: usize) -> Option<&AtlasEntry> {
        self.entries.get(index)
    }
    /// Return the total number of entries in this atlas.
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }
    /// Return all entry names in insertion order.
    pub fn entry_names(&self) -> Vec<&str> {
        self.entries.iter().map(|e| e.name.as_str()).collect()
    }
}
/// Default delegates to new().
impl Default for SpriteAtlas {
    fn default() -> Self {
        Self::new()
    }
}
/// Parse a TexturePacker JSON string (array or object frames format) into a SpriteAtlas; returns Err on malformed input.
pub fn parse_texturepacker_json(json_str: &str) -> Result<SpriteAtlas, String> {
    let value: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("JSON parse error: {}", e))?;
    let frames = value
        .get("frames")
        .ok_or("Missing 'frames' key in TexturePacker JSON")?;
    let mut atlas = SpriteAtlas::new();
    match frames {
        serde_json::Value::Array(arr) => {
            for item in arr {
                let name = item
                    .get("filename")
                    .and_then(|v| v.as_str())
                    .ok_or("Array-format frame missing 'filename'")?
                    .to_owned();
                let entry = parse_frame_entry(name, item)?;
                atlas.add_entry(entry);
            }
        }
        serde_json::Value::Object(map) => {
            for (name, item) in map {
                let entry = parse_frame_entry(name.clone(), item)?;
                atlas.add_entry(entry);
            }
        }
        _ => return Err("'frames' must be an object or array".into()),
    }
    Ok(atlas)
}
/// Extract a single AtlasEntry from a TexturePacker JSON frame value using the given name.
fn parse_frame_entry(name: String, item: &serde_json::Value) -> Result<AtlasEntry, String> {
    let frame = item
        .get("frame")
        .ok_or_else(|| format!("Frame '{}' missing 'frame' rect object", name))?;
    let x = frame
        .get("x")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Frame '{}' missing 'frame.x'", name))? as u32;
    let y = frame
        .get("y")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Frame '{}' missing 'frame.y'", name))? as u32;
    let w = frame
        .get("w")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Frame '{}' missing 'frame.w'", name))? as u32;
    let h = frame
        .get("h")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Frame '{}' missing 'frame.h'", name))? as u32;
    let rotated = item
        .get("rotated")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);
    Ok(AtlasEntry {
        name,
        x,
        y,
        w,
        h,
        rotated,
        flip_x: false,
        flip_y: false,
    })
}
/// Parse an Aseprite JSON string (array or object frames format) into a SpriteAtlas; returns Err on malformed input.
pub fn parse_aseprite_json(json_str: &str) -> Result<SpriteAtlas, String> {
    let value: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("Aseprite JSON parse error: {}", e))?;
    let frames = value
        .get("frames")
        .ok_or("Missing 'frames' key in Aseprite JSON")?;
    let mut atlas = SpriteAtlas::new();
    match frames {
        serde_json::Value::Array(arr) => {
            for item in arr {
                let name = item
                    .get("filename")
                    .and_then(|v| v.as_str())
                    .ok_or("Aseprite array frame missing 'filename'")?
                    .to_owned();
                let entry = parse_aseprite_frame(name, item)?;
                atlas.add_entry(entry);
            }
        }
        serde_json::Value::Object(map) => {
            for (name, item) in map {
                let entry = parse_aseprite_frame(name.clone(), item)?;
                atlas.add_entry(entry);
            }
        }
        _ => return Err("Aseprite 'frames' must be an object or array".into()),
    }
    Ok(atlas)
}
/// Extract a single AtlasEntry from an Aseprite JSON frame value using the given name.
fn parse_aseprite_frame(name: String, item: &serde_json::Value) -> Result<AtlasEntry, String> {
    let frame = item
        .get("frame")
        .ok_or_else(|| format!("Aseprite frame '{}' missing 'frame' rect object", name))?;
    let x = frame
        .get("x")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Aseprite frame '{}' missing 'frame.x'", name))? as u32;
    let y = frame
        .get("y")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Aseprite frame '{}' missing 'frame.y'", name))? as u32;
    let w = frame
        .get("w")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Aseprite frame '{}' missing 'frame.w'", name))? as u32;
    let h = frame
        .get("h")
        .and_then(|v| v.as_u64())
        .ok_or_else(|| format!("Aseprite frame '{}' missing 'frame.h'", name))? as u32;
    Ok(AtlasEntry {
        name,
        x,
        y,
        w,
        h,
        rotated: false,
        flip_x: false,
        flip_y: false,
    })
}
