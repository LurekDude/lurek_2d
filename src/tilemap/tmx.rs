//! - Parse the Tiled TMX XML map format into engine-native structs for tile and object layers.
//! - Support orthogonal, isometric, staggered, and hexagonal map orientations.
//! - Decode tile GID arrays from CSV, raw XML, and base64 encodings with zlib/gzip decompression.
//! - Extract tileset metadata including image paths, spacing, margins, and solid-tile markers.
//! - Parse object layers with position, size, type, and optional tile-GID references.
//! - Mask Tiled flip flags (horizontal, vertical, diagonal) from raw GID values before storage.
//! - Detect solid tiles via embedded objectgroups or `solid=true` custom properties.
//! - Propagate parse failures as descriptive error strings with element and attribute context.
//! - Parse Tiled hex color strings (`#RRGGBB` / `#AARRGGBB`) for map background color.

use crate::log_msg;
use crate::runtime::log_messages::{TL01, TL02};
use base64::Engine as _;
use flate2::read::{GzDecoder, ZlibDecoder};
use std::io::Read;

/// Map projection type as declared in the TMX `<map orientation="...">` attribute.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxOrientation {
    /// Standard square-tile top-down grid.
    Orthogonal,
    /// Diamond-shaped isometric grid.
    Isometric,
    /// Staggered isometric or hexagonal grid where alternate rows/columns are offset.
    Staggered,
    /// True hexagonal grid with `hexsidelength`.
    Hexagonal,
}
impl TmxOrientation {
    /// Parse the Tiled `orientation` attribute string; defaults to `Orthogonal` on unknown values.
    fn from_str(s: &str) -> Self {
        match s {
            "isometric" => Self::Isometric,
            "staggered" => Self::Staggered,
            "hexagonal" => Self::Hexagonal,
            _ => Self::Orthogonal,
        }
    }
}
/// Which grid axis is staggered in `Staggered` and `Hexagonal` maps.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxStaggerAxis {
    /// Columns are staggered.
    X,
    /// Rows are staggered.
    Y,
}
/// Parsed `<tileset>` element, which may be external (`source` present) or inline.
#[derive(Debug, Clone)]
pub struct TmxTileset {
    /// First global GID assigned to this tileset.
    pub first_gid: u32,
    /// Path to an external `.tsx` source file, when used.
    pub source: Option<String>,
    /// Tileset name as declared in the TMX file.
    pub name: String,
    /// Width of each tile in pixels.
    pub tile_width: u32,
    /// Height of each tile in pixels.
    pub tile_height: u32,
    /// Pixel gap between tiles in the sheet image.
    pub spacing: u32,
    /// Pixel border around the edge of the sheet image.
    pub margin: u32,
    /// Total tile count declared in the tileset.
    pub tile_count: u32,
    /// Number of tile columns in the sheet image.
    pub columns: u32,
    /// Relative path to the tileset image file.
    pub image_source: Option<String>,
    /// Image width in pixels.
    pub image_width: u32,
    /// Image height in pixels.
    pub image_height: u32,
    /// Local tile IDs marked as solid via objectgroup or `solid=true` property.
    pub solid_tiles: Vec<u32>,
}
/// Parsed `<layer>` (tile layer) element.
#[derive(Debug, Clone)]
pub struct TmxTileLayer {
    /// Layer name.
    pub name: String,
    /// Tile count along X.
    pub width: u32,
    /// Tile count along Y.
    pub height: u32,
    /// Visibility flag.
    pub visible: bool,
    /// Opacity from 0.0 (transparent) to 1.0 (opaque).
    pub opacity: f32,
    /// Horizontal draw offset in pixels.
    pub offset_x: f32,
    /// Vertical draw offset in pixels.
    pub offset_y: f32,
    /// Row-major GID array with flip flags masked out; length equals `width * height`.
    pub tiles: Vec<u32>,
}
/// Parsed `<objectgroup>` element.
#[derive(Debug, Clone)]
pub struct TmxObjectLayer {
    /// Layer name.
    pub name: String,
    /// Visibility flag.
    pub visible: bool,
    /// All objects in this layer.
    pub objects: Vec<TmxObject>,
}
/// Parsed `<object>` element inside an objectgroup.
#[derive(Debug, Clone)]
pub struct TmxObject {
    /// Unique object ID within the map.
    pub id: u32,
    /// Human-readable name.
    pub name: String,
    /// Object `type` or `class` attribute.
    pub obj_type: String,
    /// World X position in pixels.
    pub x: f32,
    /// World Y position in pixels.
    pub y: f32,
    /// Bounding width in pixels; 0 for point objects.
    pub width: f32,
    /// Bounding height in pixels; 0 for point objects.
    pub height: f32,
    /// Tile GID when the object is a tile object; `0` for shape objects.
    pub gid: u32,
}
/// A single map layer, either tile data or objects.
#[derive(Debug, Clone)]
pub enum TmxLayer {
    /// A tile data layer.
    Tile(TmxTileLayer),
    /// An object group layer.
    Object(TmxObjectLayer),
}
/// Top-level parsed TMX map. This item is part of the public API.
#[derive(Debug, Clone)]
pub struct TmxMap {
    /// Map width in tiles.
    pub width: u32,
    /// Map height in tiles.
    pub height: u32,
    /// Tile width in pixels.
    pub tile_width: u32,
    /// Tile height in pixels.
    pub tile_height: u32,
    /// Projection type.
    pub orientation: TmxOrientation,
    /// Stagger axis for `Staggered`/`Hexagonal` maps.
    pub stagger_axis: Option<TmxStaggerAxis>,
    /// Hex side length in pixels for `Hexagonal` maps.
    pub hex_side_length: u32,
    /// All attached tilesets in declaration order.
    pub tilesets: Vec<TmxTileset>,
    /// All layers in declaration order.
    pub layers: Vec<TmxLayer>,
    /// Optional background fill color `[a, r, g, b]`.
    pub background_color: Option<[u8; 4]>,
}
impl TmxMap {
    /// Iterate over all tile layers in declaration order.
    pub fn tile_layers(&self) -> impl Iterator<Item = &TmxTileLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Tile(t) => Some(t),
            _ => None,
        })
    }
    /// Iterate over all object layers in declaration order.
    pub fn object_layers(&self) -> impl Iterator<Item = &TmxObjectLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Object(o) => Some(o),
            _ => None,
        })
    }
}
/// Parse an XML-encoded TMX map string; returns a `TmxMap` or an error string describing the first failure.
pub fn load_tmx(xml: &str) -> Result<TmxMap, String> {
    log_msg!(debug, TL01, "{} bytes", xml.len());
    let doc = roxmltree::Document::parse(xml).map_err(|e| format!("TMX XML parse error: {e}"))?;
    let map_node = doc
        .root()
        .children()
        .find(|n| n.has_tag_name("map"))
        .ok_or("TMX: missing <map> root element")?;
    let width = attr_u32(&map_node, "width")?;
    let height = attr_u32(&map_node, "height")?;
    let tile_width = attr_u32(&map_node, "tilewidth")?;
    let tile_height = attr_u32(&map_node, "tileheight")?;
    let orientation =
        TmxOrientation::from_str(map_node.attribute("orientation").unwrap_or("orthogonal"));
    let stagger_axis = map_node.attribute("staggeraxis").map(|s| match s {
        "x" => TmxStaggerAxis::X,
        _ => TmxStaggerAxis::Y,
    });
    let hex_side_length = map_node
        .attribute("hexsidelength")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let background_color = map_node
        .attribute("backgroundcolor")
        .and_then(parse_tiled_color);
    let mut tilesets = Vec::new();
    for child in map_node.children() {
        if child.has_tag_name("tileset") {
            tilesets.push(parse_tileset(&child)?);
        }
    }
    let mut layers = Vec::new();
    for child in map_node.children() {
        if child.has_tag_name("layer") {
            let layer = parse_tile_layer(&child, width, height)?;
            layers.push(TmxLayer::Tile(layer));
        } else if child.has_tag_name("objectgroup") {
            let ol = parse_object_layer(&child)?;
            layers.push(TmxLayer::Object(ol));
        }
    }
    log_msg!(debug, TL02, "{}x{}", width, height);
    Ok(TmxMap {
        width,
        height,
        tile_width,
        tile_height,
        orientation,
        stagger_axis,
        hex_side_length,
        tilesets,
        layers,
        background_color,
    })
}
/// Parse a `<tileset>` XML node into a `TmxTileset`; returns early with a stub when `source` attribute is present.
fn parse_tileset(node: &roxmltree::Node) -> Result<TmxTileset, String> {
    let first_gid = attr_u32(node, "firstgid")?;
    if let Some(src) = node.attribute("source") {
        return Ok(TmxTileset {
            first_gid,
            source: Some(src.to_string()),
            name: String::new(),
            tile_width: 0,
            tile_height: 0,
            spacing: 0,
            margin: 0,
            tile_count: 0,
            columns: 0,
            image_source: None,
            image_width: 0,
            image_height: 0,
            solid_tiles: Vec::new(),
        });
    }
    let name = node.attribute("name").unwrap_or("").to_string();
    let tile_width = attr_u32(node, "tilewidth")?;
    let tile_height = attr_u32(node, "tileheight")?;
    let spacing = node
        .attribute("spacing")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let margin = node
        .attribute("margin")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let tile_count = node
        .attribute("tilecount")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let columns = node
        .attribute("columns")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let mut image_source = None;
    let mut image_width = 0u32;
    let mut image_height = 0u32;
    for child in node.children() {
        if child.has_tag_name("image") {
            image_source = child.attribute("source").map(String::from);
            image_width = child
                .attribute("width")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
            image_height = child
                .attribute("height")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
            break;
        }
    }
    let mut solid_tiles = Vec::new();
    for child in node.children() {
        if child.has_tag_name("tile") {
            let tid: u32 = child
                .attribute("id")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
            for sub in child.children() {
                if sub.has_tag_name("objectgroup") {
                    solid_tiles.push(tid);
                    break;
                }
                if sub.has_tag_name("properties") {
                    for prop in sub.children() {
                        if prop.has_tag_name("property") {
                            let pname = prop.attribute("name").unwrap_or("");
                            let pval = prop.attribute("value").unwrap_or("");
                            if pname.eq_ignore_ascii_case("solid") && pval == "true" {
                                solid_tiles.push(tid);
                            }
                        }
                    }
                }
            }
        }
    }
    Ok(TmxTileset {
        first_gid,
        source: None,
        name,
        tile_width,
        tile_height,
        spacing,
        margin,
        tile_count,
        columns,
        image_source,
        image_width,
        image_height,
        solid_tiles,
    })
}
/// Parse a `<layer>` XML node into a `TmxTileLayer`, decoding CSV, base64, or XML tile data.
fn parse_tile_layer(
    node: &roxmltree::Node,
    map_w: u32,
    map_h: u32,
) -> Result<TmxTileLayer, String> {
    let name = node.attribute("name").unwrap_or("").to_string();
    let width = node
        .attribute("width")
        .and_then(|s| s.parse().ok())
        .unwrap_or(map_w);
    let height = node
        .attribute("height")
        .and_then(|s| s.parse().ok())
        .unwrap_or(map_h);
    let visible = node.attribute("visible") != Some("0");
    let opacity: f32 = node
        .attribute("opacity")
        .and_then(|s| s.parse().ok())
        .unwrap_or(1.0);
    let offset_x: f32 = node
        .attribute("offsetx")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.0);
    let offset_y: f32 = node
        .attribute("offsety")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.0);
    let data_node = node
        .children()
        .find(|n| n.has_tag_name("data"))
        .ok_or_else(|| format!("layer '{}': missing <data> element", name))?;
    let encoding = data_node.attribute("encoding").unwrap_or("xml");
    let compression = data_node.attribute("compression").unwrap_or("none");
    let tiles = match encoding {
        "csv" => parse_csv_tiles(&data_node, width, height)?,
        "base64" => parse_base64_tiles(&data_node, compression, width, height)?,
        _ => parse_xml_tiles(&data_node, width, height)?,
    };
    Ok(TmxTileLayer {
        name,
        width,
        height,
        visible,
        opacity,
        offset_x,
        offset_y,
        tiles,
    })
}
/// Decode XML-encoded tile GIDs from `<tile gid="...">` children; pads or truncates to `w * h`.
fn parse_xml_tiles(data: &roxmltree::Node, w: u32, h: u32) -> Result<Vec<u32>, String> {
    let cap = (w * h) as usize;
    let mut tiles = Vec::with_capacity(cap);
    for child in data.children() {
        if child.has_tag_name("tile") {
            let gid: u32 = child
                .attribute("gid")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
            tiles.push(gid);
        }
    }
    tiles.resize(cap, 0);
    Ok(tiles)
}
/// Decode CSV-encoded tile GIDs; strips flip flags; pads or truncates to `w * h`.
fn parse_csv_tiles(data: &roxmltree::Node, w: u32, h: u32) -> Result<Vec<u32>, String> {
    let text = data.text().unwrap_or("").trim().to_string();
    let cap = (w * h) as usize;
    let mut tiles = Vec::with_capacity(cap);
    for part in text.split(',') {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let gid: u32 = part
            .parse()
            .map_err(|_| format!("CSV tile data: cannot parse '{part}' as u32"))?;
        tiles.push(gid & 0x1FFF_FFFF);
    }
    tiles.resize(cap, 0);
    Ok(tiles)
}
/// Decode base64 tile data with optional `zlib`, `gzip`, or no compression; returns an error for unsupported `zstd`.
fn parse_base64_tiles(
    data: &roxmltree::Node,
    compression: &str,
    w: u32,
    h: u32,
) -> Result<Vec<u32>, String> {
    let text = data.text().unwrap_or("").trim().to_string();
    let raw = base64::engine::general_purpose::STANDARD
        .decode(&text)
        .map_err(|e| format!("Base64 decode error: {e}"))?;
    let bytes: Vec<u8> = match compression {
        "zlib" | "deflate" => {
            let mut decoder = ZlibDecoder::new(raw.as_slice());
            let mut out = Vec::new();
            decoder
                .read_to_end(&mut out)
                .map_err(|e| format!("zlib decompress error: {e}"))?;
            out
        }
        "gzip" => {
            let mut decoder = GzDecoder::new(raw.as_slice());
            let mut out = Vec::new();
            decoder
                .read_to_end(&mut out)
                .map_err(|e| format!("gzip decompress error: {e}"))?;
            out
        }
        "zstd" => {
            return Err("TMX: zstd compression is not supported. Re-save the map with zlib or gzip compression.".to_string());
        }
        _ => raw,
    };
    if !bytes.len().is_multiple_of(4) {
        return Err(format!(
            "TMX tile data: byte count {} is not a multiple of 4",
            bytes.len()
        ));
    }
    let cap = (w * h) as usize;
    let mut tiles = Vec::with_capacity(cap);
    for chunk in bytes.chunks_exact(4) {
        let gid = u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
        tiles.push(gid & 0x1FFF_FFFF);
    }
    tiles.resize(cap, 0);
    Ok(tiles)
}
/// Parse an `<objectgroup>` XML node into a `TmxObjectLayer`.
fn parse_object_layer(node: &roxmltree::Node) -> Result<TmxObjectLayer, String> {
    let name = node.attribute("name").unwrap_or("").to_string();
    let visible = node.attribute("visible") != Some("0");
    let mut objects = Vec::new();
    for child in node.children() {
        if child.has_tag_name("object") {
            objects.push(parse_object(&child));
        }
    }
    Ok(TmxObjectLayer {
        name,
        visible,
        objects,
    })
}
/// Parse a single `<object>` XML node into a `TmxObject`.
fn parse_object(node: &roxmltree::Node) -> TmxObject {
    TmxObject {
        id: node
            .attribute("id")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0),
        name: node.attribute("name").unwrap_or("").to_string(),
        obj_type: node
            .attribute("type")
            .or_else(|| node.attribute("class"))
            .unwrap_or("")
            .to_string(),
        x: node
            .attribute("x")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0.0),
        y: node
            .attribute("y")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0.0),
        width: node
            .attribute("width")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0.0),
        height: node
            .attribute("height")
            .and_then(|s| s.parse().ok())
            .unwrap_or(0.0),
        gid: node
            .attribute("gid")
            .and_then(|s| s.parse::<u32>().ok())
            .map(|g| g & 0x1FFF_FFFF)
            .unwrap_or(0),
    }
}
/// Read a required u32 attribute `name` from `node`; returns an error string when absent or unparseable.
fn attr_u32(node: &roxmltree::Node, name: &str) -> Result<u32, String> {
    node.attribute(name)
        .ok_or_else(|| {
            format!(
                "TMX: missing attribute '{name}' on <{}>",
                node.tag_name().name()
            )
        })?
        .parse::<u32>()
        .map_err(|e| format!("TMX: attribute '{name}' is not a valid u32: {e}"))
}
/// Parse a Tiled hex color string (`#RRGGBB` or `#AARRGGBB`) into `[a, r, g, b]`; returns `None` on parse failure.
fn parse_tiled_color(s: &str) -> Option<[u8; 4]> {
    let s = s.trim_start_matches('#');
    match s.len() {
        6 => {
            let r = u8::from_str_radix(&s[0..2], 16).ok()?;
            let g = u8::from_str_radix(&s[2..4], 16).ok()?;
            let b = u8::from_str_radix(&s[4..6], 16).ok()?;
            Some([255, r, g, b])
        }
        8 => {
            let a = u8::from_str_radix(&s[0..2], 16).ok()?;
            let r = u8::from_str_radix(&s[2..4], 16).ok()?;
            let g = u8::from_str_radix(&s[4..6], 16).ok()?;
            let b = u8::from_str_radix(&s[6..8], 16).ok()?;
            Some([a, r, g, b])
        }
        _ => None,
    }
}
