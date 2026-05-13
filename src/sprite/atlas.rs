use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct AtlasEntry {
    pub name: String,
    pub x: u32,
    pub y: u32,
    pub w: u32,
    pub h: u32,
    pub rotated: bool,
    pub flip_x: bool,
    pub flip_y: bool,
}
impl AtlasEntry {
    pub fn get_flipped(&self, flip_x: bool, flip_y: bool) -> AtlasEntry {
        let mut cloned = self.clone();
        cloned.flip_x = flip_x;
        cloned.flip_y = flip_y;
        cloned
    }
}
#[derive(Debug, Clone)]
pub struct SpriteAtlas {
    entries: Vec<AtlasEntry>,
    name_map: HashMap<String, usize>,
}
impl SpriteAtlas {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            name_map: HashMap::new(),
        }
    }
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
    pub fn add_entry(&mut self, entry: AtlasEntry) {
        if let Some(&idx) = self.name_map.get(&entry.name) {
            self.entries[idx] = entry;
        } else {
            let idx = self.entries.len();
            self.name_map.insert(entry.name.clone(), idx);
            self.entries.push(entry);
        }
    }
    pub fn get_entry(&self, name: &str) -> Option<&AtlasEntry> {
        self.name_map.get(name).and_then(|&i| self.entries.get(i))
    }
    pub fn get_by_index(&self, index: usize) -> Option<&AtlasEntry> {
        self.entries.get(index)
    }
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }
    pub fn entry_names(&self) -> Vec<&str> {
        self.entries.iter().map(|e| e.name.as_str()).collect()
    }
}
impl Default for SpriteAtlas {
    fn default() -> Self {
        Self::new()
    }
}
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
