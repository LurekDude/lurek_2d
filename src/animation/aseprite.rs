
//! - Loads Aseprite JSON exports into engine animation metadata.
//! - Extracts sheet frame rectangles, per-frame durations, and sheet size.
//! - Parses frame tags into named clip ranges with forward, reverse, or ping-pong playback.
//! - Accepts both array and object `frames` layouts and normalizes object order into playback order.
//! - Validates required metadata fields and returns explicit parse errors when the export is incomplete.

use serde_json::Value;
/// One frame rectangle parsed from an Aseprite sheet.
#[derive(Debug, Clone)]
pub struct AsepriteFrameData {
    /// Frame X coordinate in the sheet.
    pub x: u32,
    /// Frame Y coordinate in the sheet.
    pub y: u32,
    /// Frame width in pixels.
    pub w: u32,
    /// Frame height in pixels.
    pub h: u32,
    /// Frame duration in milliseconds.
    pub duration_ms: u32,
}
#[derive(Debug, Clone, PartialEq)]
/// Playback direction declared by an Aseprite tag.
pub enum AsepriteDirection {
    /// Play frames in ascending order.
    Forward,
    /// Play frames in reverse order.
    Reverse,
    /// Play forward then backward.
    PingPong,
}
#[derive(Debug, Clone)]
/// Frame tag extracted from Aseprite metadata.
pub struct AsepriteTagData {
    /// Tag name.
    pub name: String,
    /// First frame index.
    pub from: usize,
    /// Last frame index.
    pub to: usize,
    /// Playback direction.
    pub direction: AsepriteDirection,
}
#[derive(Debug, Clone)]
/// Parsed Aseprite sheet metadata.
pub struct AsepriteParsed {
    /// All frame rectangles in playback order.
    pub frames: Vec<AsepriteFrameData>,
    /// All parsed frame tags.
    pub tags: Vec<AsepriteTagData>,
    /// Sheet width in pixels.
    pub sheet_width: u32,
    /// Sheet height in pixels.
    pub sheet_height: u32,
}
/// Parse an Aseprite JSON string into frame and tag metadata.
pub fn load_aseprite_json(json_str: &str) -> Result<AsepriteParsed, String> {
    let root: Value =
        serde_json::from_str(json_str).map_err(|e| format!("aseprite: JSON parse error: {}", e))?;
    let frames_val = root.get("frames").ok_or("aseprite: missing 'frames' key")?;
    let mut frames: Vec<AsepriteFrameData> = Vec::new();
    if let Some(arr) = frames_val.as_array() {
        for entry in arr {
            frames.push(parse_frame_entry(entry)?);
        }
    } else if let Some(obj) = frames_val.as_object() {
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
/// Parse one frame entry object into `AsepriteFrameData`.
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
