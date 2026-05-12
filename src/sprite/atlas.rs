//! TexturePacker JSON atlas importer and named region lookup.
//!
//! Parses both hash-format (`"frames": {}`) and array-format (`"frames": []`)
//! TexturePacker JSON exports and provides O(1) region lookup by name.
//!
//! # Format boundary
//!
//! This module parses **TexturePacker JSON** (hash or array, `"frames"` + `"meta"`).
//! It must not be confused with `animation::aseprite`, which parses **Aseprite JSON**
//! (array of frames with per-frame durations and `"frameTags"`).
//!
//! | Module | JSON format | Primary output |
//! |---|---|---|
//! | `sprite::atlas` (this module) | TexturePacker export | [`SpriteAtlas`] — named region lookup |
//! | `animation::aseprite` | Aseprite export | [`AsepriteData`] — frame + tag animation data |
//!
//! To feed atlas regions into an animation, collect the quads you need and call
//! `Animation::add_frames_from_rects(&quads)`.  This keeps the dependency
//! direction correct: `animation` (Tier 1) never imports `sprite`.

use std::collections::HashMap;

// -------------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------------

/// A single named region within a sprite atlas.
///
/// # Fields
/// - `name` — `String`. The region identifier (matches the source filename key in TexturePacker).
/// - `x` — `u32`. Left edge of the region on the texture, in pixels.
/// - `y` — `u32`. Top edge of the region on the texture, in pixels.
/// - `w` — `u32`. Width of the region, in pixels.
/// - `h` — `u32`. Height of the region, in pixels.
/// - `rotated` — `bool`. Whether the region was rotated 90 degrees during packing.
/// - `flip_x` — `bool`. Whether the region should be drawn horizontally flipped.
/// - `flip_y` — `bool`. Whether the region should be drawn vertically flipped.
#[derive(Debug, Clone)]
pub struct AtlasEntry {
    /// The region identifier.
    pub name: String,
    /// Left edge in pixels.
    pub x: u32,
    /// Top edge in pixels.
    pub y: u32,
    /// Width in pixels.
    pub w: u32,
    /// Height in pixels.
    pub h: u32,
    /// Whether the region was packed rotated.
    pub rotated: bool,
    /// Horizontal flip flag.  Set via [`AtlasEntry::get_flipped`].
    pub flip_x: bool,
    /// Vertical flip flag.  Set via [`AtlasEntry::get_flipped`].
    pub flip_y: bool,
}

impl AtlasEntry {
    /// Returns a copy of this entry with the requested flip flags applied.
    ///
    /// # Parameters
    /// - `flip_x` — `bool`. Flip horizontally.
    /// - `flip_y` — `bool`. Flip vertically.
    ///
    /// # Returns
    /// `AtlasEntry` — a clone of `self` with `flip_x` and `flip_y` set.
    pub fn get_flipped(&self, flip_x: bool, flip_y: bool) -> AtlasEntry {
        let mut cloned = self.clone();
        cloned.flip_x = flip_x;
        cloned.flip_y = flip_y;
        cloned
    }
}

/// In-memory sprite atlas built from a TexturePacker JSON export.
///
/// Stores all regions in insertion order and provides name-keyed lookup via an
/// internal `HashMap<String, usize>` index.
///
/// # Fields
/// - `entries` — `Vec<AtlasEntry>`. All atlas regions in insertion order.
/// - `name_map` — `HashMap<String, usize>`. Maps region name to `entries` index.
#[derive(Debug, Clone)]
pub struct SpriteAtlas {
    entries: Vec<AtlasEntry>,
    name_map: HashMap<String, usize>,
}

impl SpriteAtlas {
    /// Creates an empty atlas.
    ///
    /// # Returns
    /// `SpriteAtlas`.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            name_map: HashMap::new(),
        }
    }

    /// Builds a `SpriteAtlas` from regions packed by `image::TextureAtlas`.
    ///
    /// This is an interoperability helper so CPU-packed atlas regions can be
    /// consumed by sprite systems that already expect `SpriteAtlas` entries.
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

    /// Adds a region to the atlas.
    ///
    /// If a region with the same name already exists it is overwritten in-place.
    ///
    /// # Parameters
    /// - `entry` — [`AtlasEntry`].
    pub fn add_entry(&mut self, entry: AtlasEntry) {
        if let Some(&idx) = self.name_map.get(&entry.name) {
            self.entries[idx] = entry;
        } else {
            let idx = self.entries.len();
            self.name_map.insert(entry.name.clone(), idx);
            self.entries.push(entry);
        }
    }

    /// Returns the region with the given name, or `None`.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&AtlasEntry>`.
    pub fn get_entry(&self, name: &str) -> Option<&AtlasEntry> {
        self.name_map.get(name).and_then(|&i| self.entries.get(i))
    }

    /// Returns the region at the given index, or `None`.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&AtlasEntry>`.
    pub fn get_by_index(&self, index: usize) -> Option<&AtlasEntry> {
        self.entries.get(index)
    }

    /// Returns the number of regions in the atlas.
    ///
    /// # Returns
    /// `usize`.
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }

    /// Returns all region names in insertion order.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn entry_names(&self) -> Vec<&str> {
        self.entries.iter().map(|e| e.name.as_str()).collect()
    }
}

impl Default for SpriteAtlas {
    fn default() -> Self {
        Self::new()
    }
}

// -------------------------------------------------------------------------------
// JSON parser
// -------------------------------------------------------------------------------

/// Parses a TexturePacker JSON export string and returns a [`SpriteAtlas`].
///
/// Supports both hash-format (`"frames": { "name": {...} }`) and array-format
/// (`"frames": [ { "filename": "name", "frame": {...} } ]`) exports.
///
/// # Parameters
/// - `json_str` — `&str`. Raw TexturePacker JSON.
///
/// # Returns
/// `Result<SpriteAtlas, String>` — `Ok` with the populated atlas or `Err` with a
/// message describing why parsing failed.
pub fn parse_texturepacker_json(json_str: &str) -> Result<SpriteAtlas, String> {
    let value: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("JSON parse error: {}", e))?;

    let frames = value
        .get("frames")
        .ok_or("Missing 'frames' key in TexturePacker JSON")?;

    let mut atlas = SpriteAtlas::new();

    match frames {
        // Array format: "frames": [ { "filename": "name", "frame": { "x":n, "y":n, "w":n, "h":n }, "rotated": false }, ... ]
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
        // Hash format: "frames": { "name": { "frame": { "x":n, "y":n, "w":n, "h":n }, "rotated": false }, ... }
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

/// Extracts an `AtlasEntry` from a single frame record (shared between array and hash formats).
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

// -------------------------------------------------------------------------------
// Aseprite JSON parser
// -------------------------------------------------------------------------------

/// Parses an Aseprite JSON export and returns a [`SpriteAtlas`].
///
/// Aseprite exports two JSON variants:
/// - **Array**: `"frames": [ { "filename": "name", "frame": {"x":n,"y":n,"w":n,"h":n} } ]`
/// - **Hash**: `"frames": { "name": { "frame": {"x":n,"y":n,"w":n,"h":n} } }`
///
/// The `"meta"` key (if present) is ignored.
///
/// # Parameters
/// - `json_str` — `&str`. Raw Aseprite JSON export string.
///
/// # Returns
/// `Result<SpriteAtlas, String>` — `Ok` with the populated atlas, or `Err` with a
/// description of why parsing failed.
pub fn parse_aseprite_json(json_str: &str) -> Result<SpriteAtlas, String> {
    let value: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("Aseprite JSON parse error: {}", e))?;

    let frames = value
        .get("frames")
        .ok_or("Missing 'frames' key in Aseprite JSON")?;

    let mut atlas = SpriteAtlas::new();

    match frames {
        // Array format: [ { "filename": "name", "frame": {...} }, ... ]
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
        // Hash format: { "name": { "frame": {...} }, ... }
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

/// Extracts an [`AtlasEntry`] from a single Aseprite frame record.
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

    // Aseprite does not record rotation — always false.
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

// -------------------------------------------------------------------------------
// Tests
// -------------------------------------------------------------------------------
