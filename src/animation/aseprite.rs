//! Aseprite JSON export parser for sprite animation data.
//!
//! Parses the JSON exported by Aseprite (File → Export Sprite Sheet → Output → JSON Data)
//! and converts frame and tag data into types that [`Animation::load_from_aseprite`] can consume.
//!
//! # Format boundary
//!
//! | Module | JSON format | Primary output |
//! |---|---|---|
//! | `animation::aseprite` (this module) | Aseprite export (`"frames"` array + `"meta"` + `"frameTags"`) | [`AsepriteData`] consumed by [`Animation::load_from_aseprite`] |
//! | `sprite::atlas` | TexturePacker JSON (hash or array, `"frames"` + `"meta"`) | [`SpriteAtlas`] with named region lookup |
//!
//! These two parsers handle **different JSON schemas** produced by different tools for
//! different use cases.  They must not be merged:
//! - Aseprite JSON carries per-frame duration data and animation tag information.
//!   It is consumed solely by the animation subsystem.
//! - TexturePacker JSON carries named sprite regions without animation metadata.
//!   It is consumed by the sprite/rendering subsystem.
//!
//! If you need to drive an animation from a TexturePacker atlas, pass the region
//! quads through `Animation::add_frames_from_rects`.  The bridge between the two
//! systems is intentionally at the Lua/game-code layer, not inside the parsers.

use serde_json::Value;

/// Pixel-level frame rectangle extracted from an Aseprite JSON export.
///
/// # Fields
/// - `x` â€” `u32`. Left edge within the sprite sheet.
/// - `y` â€” `u32`. Top edge within the sprite sheet.
/// - `w` â€” `u32`. Frame width in pixels.
/// - `h` â€” `u32`. Frame height in pixels.
/// - `duration_ms` â€” `u32`. Display duration in milliseconds.
#[derive(Debug, Clone)]
pub struct AsepriteFrameData {
    /// Left edge of the frame within the sprite sheet in pixels.
    pub x: u32,
    /// Top edge of the frame within the sprite sheet in pixels.
    pub y: u32,
    /// Frame width in pixels.
    pub w: u32,
    /// Frame height in pixels.
    pub h: u32,
    /// Display duration for this frame in milliseconds.
    pub duration_ms: u32,
}

/// Playback direction of an Aseprite frame tag.
///
/// # Variants
/// - `Forward` â€” plays from `from` to `to`.
/// - `Reverse` â€” plays from `to` to `from`.
/// - `PingPong` â€” plays forward then backward.
#[derive(Debug, Clone, PartialEq)]
pub enum AsepriteDirection {
    /// Plays frames from `from` to `to` in order.
    Forward,
    /// Plays frames from `to` to `from` in reverse order.
    Reverse,
    /// Plays frames forward then backward.
    PingPong,
}

/// Frame tag (named clip range) from an Aseprite JSON export.
///
/// # Fields
/// - `name` â€” `String`. Clip name (e.g. "idle", "walk").
/// - `from` â€” `usize`. First frame index (0-based).
/// - `to` â€” `usize`. Last frame index (0-based, inclusive).
/// - `direction` â€” [`AsepriteDirection`].
#[derive(Debug, Clone)]
pub struct AsepriteTagData {
    /// Human-readable clip name.
    pub name: String,
    /// 0-based index of the first frame in this tag.
    pub from: usize,
    /// 0-based index of the last frame in this tag (inclusive).
    pub to: usize,
    /// Playback direction.
    pub direction: AsepriteDirection,
}

/// Result of parsing an Aseprite JSON export.
///
/// # Fields
/// - `frames` â€” `Vec<AsepriteFrameData>`. All frame rectangles in order.
/// - `tags` â€” `Vec<AsepriteTagData>`. Named animation ranges.
/// - `sheet_width` â€” `u32`. Total sprite sheet width.
/// - `sheet_height` â€” `u32`. Total sprite sheet height.
#[derive(Debug, Clone)]
pub struct AsepriteParsed {
    /// All frame rectangles in export order.
    pub frames: Vec<AsepriteFrameData>,
    /// Named animation ranges (frame tags).
    pub tags: Vec<AsepriteTagData>,
    /// Total sprite sheet width in pixels.
    pub sheet_width: u32,
    /// Total sprite sheet height in pixels.
    pub sheet_height: u32,
}

/// Parses an Aseprite JSON export string into an [`AsepriteParsed`] result.
///
/// Handles both array-format (`"frames": [...]`) and hash-format
/// (`"frames": {"name": {...}}`) exports.
///
/// # Parameters
/// - `json_str` â€” `&str`. UTF-8 JSON string exported by Aseprite.
///
/// # Returns
/// `Result<AsepriteParsed, String>` â€” parsed data, or an error description.
pub fn load_aseprite_json(json_str: &str) -> Result<AsepriteParsed, String> {
    let root: Value =
        serde_json::from_str(json_str).map_err(|e| format!("aseprite: JSON parse error: {}", e))?;

    // â”€â”€ frames â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    let frames_val = root.get("frames").ok_or("aseprite: missing 'frames' key")?;

    let mut frames: Vec<AsepriteFrameData> = Vec::new();

    if let Some(arr) = frames_val.as_array() {
        // Array format: [{filename, frame:{x,y,w,h}, duration}, ...]
        for entry in arr {
            frames.push(parse_frame_entry(entry)?);
        }
    } else if let Some(obj) = frames_val.as_object() {
        // Hash format: {"name": {frame:{x,y,w,h}, duration}, ...}
        // Sort keys to preserve stable frame order (numeric suffix if present).
        let mut entries: Vec<(&String, &Value)> = obj.iter().collect();
        entries.sort_by_key(|(k, _)| {
            let base = k.trim_end_matches(".png").trim_end_matches(".jpg");
            base.rsplit_once('_')
                .or_else(|| base.rsplit_once(' '))
                .and_then(|(_, s)| s.parse::<u64>().ok())
                .unwrap_or(0)
        });
        for (_, entry) in entries {
            frames.push(parse_frame_entry(entry)?);
        }
    } else {
        return Err("aseprite: 'frames' must be an array or object".to_string());
    }

    // â”€â”€ meta â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    let meta = root.get("meta").ok_or("aseprite: missing 'meta' key")?;

    let size = meta.get("size").ok_or("aseprite: missing 'meta.size'")?;

    let sheet_width = size
        .get("w")
        .and_then(Value::as_u64)
        .ok_or("aseprite: missing 'meta.size.w'")? as u32;

    let sheet_height = size
        .get("h")
        .and_then(Value::as_u64)
        .ok_or("aseprite: missing 'meta.size.h'")? as u32;

    // â”€â”€ frameTags â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    let mut tags: Vec<AsepriteTagData> = Vec::new();
    if let Some(tag_arr) = meta.get("frameTags").and_then(Value::as_array) {
        for tag_val in tag_arr {
            let name = tag_val
                .get("name")
                .and_then(Value::as_str)
                .ok_or("aseprite: tag missing 'name'")?
                .to_string();
            let from = tag_val
                .get("from")
                .and_then(Value::as_u64)
                .ok_or("aseprite: tag missing 'from'")? as usize;
            let to = tag_val
                .get("to")
                .and_then(Value::as_u64)
                .ok_or("aseprite: tag missing 'to'")? as usize;
            let direction = match tag_val
                .get("direction")
                .and_then(Value::as_str)
                .unwrap_or("forward")
            {
                "reverse" => AsepriteDirection::Reverse,
                "pingpong" => AsepriteDirection::PingPong,
                _ => AsepriteDirection::Forward,
            };
            tags.push(AsepriteTagData {
                name,
                from,
                to,
                direction,
            });
        }
    }

    Ok(AsepriteParsed {
        frames,
        tags,
        sheet_width,
        sheet_height,
    })
}

/// Parses a single frame entry from either array or hash format.
fn parse_frame_entry(entry: &Value) -> Result<AsepriteFrameData, String> {
    let frame_obj = entry
        .get("frame")
        .ok_or("aseprite: frame entry missing 'frame' object")?;

    let x = frame_obj
        .get("x")
        .and_then(Value::as_u64)
        .ok_or("aseprite: frame missing 'x'")? as u32;
    let y = frame_obj
        .get("y")
        .and_then(Value::as_u64)
        .ok_or("aseprite: frame missing 'y'")? as u32;
    let w = frame_obj
        .get("w")
        .and_then(Value::as_u64)
        .ok_or("aseprite: frame missing 'w'")? as u32;
    let h = frame_obj
        .get("h")
        .and_then(Value::as_u64)
        .ok_or("aseprite: frame missing 'h'")? as u32;
    let duration_ms = entry.get("duration").and_then(Value::as_u64).unwrap_or(100) as u32;

    Ok(AsepriteFrameData {
        x,
        y,
        w,
        h,
        duration_ms,
    })
}
