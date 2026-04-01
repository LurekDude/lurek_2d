//! Tiled TMX map format loader.
//!
//! Parses `.tmx` files produced by the [Tiled Map Editor](https://www.mapeditor.org/).
//! TMX is an XML-based format; this module uses [`roxmltree`] for parsing.
//!
//! Supports:
//! - Orthogonal, isometric, staggered, and hexagonal map orientations.
//! - Tile data encoding: XML elements, CSV, and Base64 (with optional zlib/gzip compression).
//! - Inline and external tileset references (TSX source returned as a path string for caller resolution).
//! - Object layers and image layers (parsed to metadata; not converted to [`TileMap`] data).
//!
//! Does NOT support:
//! - Infinite maps (chunk-based TMX format): treat as a warning; use [`ChunkMap`] directly.
//! - Embedded TSX tileset files — the caller must load them separately.
//!
//! [`ChunkMap`]: super::chunk::ChunkMap

use std::io::Read;

use base64::Engine as _;
use flate2::read::{GzDecoder, ZlibDecoder};

/// Rendering orientation of the map, as specified in the TMX `orientation` attribute.
///
/// # Variants
/// - `Orthogonal` — Orthogonal variant.
/// - `Isometric` — Isometric variant.
/// - `Staggered` — Staggered variant.
/// - `Hexagonal` — Hexagonal variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxOrientation {
    /// Standard top-down orthogonal grid.
    Orthogonal,
    /// Diamond isometric projection.
    Isometric,
    /// Staggered isometric (brick-offset rows or columns).
    Staggered,
    /// Hexagonal grid.
    Hexagonal,
}

impl TmxOrientation {
    fn from_str(s: &str) -> Self {
        match s {
            "isometric" => Self::Isometric,
            "staggered" => Self::Staggered,
            "hexagonal" => Self::Hexagonal,
            _ => Self::Orthogonal,
        }
    }
}

/// The axis along which isometric / hexagonal tiles are staggered.
///
/// # Variants
/// - `X` — X variant.
/// - `Y` — Y variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxStaggerAxis {
    /// Stagger along the X axis.
    X,
    /// Stagger along the Y axis.
    Y,
}

/// A tileset reference embedded in a TMX map.
///
/// # Fields
/// - `first_gid` — `u32`.
/// - `source` — `Option<String>`.
/// - `name` — `String`.
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `spacing` — `u32`.
/// - `margin` — `u32`.
/// - `tile_count` — `u32`.
/// - `columns` — `u32`.
/// - `image_source` — `Option<String>`.
/// - `image_width` — `u32`.
/// - `image_height` — `u32`.
/// - `solid_tiles` — `Vec<u32>`.
///
/// If `source` is `Some`, the tileset data lives in an external `.tsx` file
/// and only `first_gid` is available here.  If `source` is `None` the tileset
/// is inline and all other fields are populated.
#[derive(Debug, Clone)]
pub struct TmxTileset {
    /// First global tile ID that maps to this tileset.
    pub first_gid: u32,
    /// Path to an external `.tsx` file, if the tileset is not inline.
    pub source: Option<String>,
    /// Human-readable tileset name (empty for external-reference-only entries).
    pub name: String,
    /// Width of a single tile in pixels.
    pub tile_width: u32,
    /// Height of a single tile in pixels.
    pub tile_height: u32,
    /// Pixel spacing between tiles in the atlas.
    pub spacing: u32,
    /// Pixel margin around the atlas edges.
    pub margin: u32,
    /// Total number of tiles in the tileset.
    pub tile_count: u32,
    /// Number of tile columns in the atlas.
    pub columns: u32,
    /// Path to the atlas image, relative to the TMX file.
    pub image_source: Option<String>,
    /// Width of the atlas image in pixels.
    pub image_width: u32,
    /// Height of the atlas image in pixels.
    pub image_height: u32,
    /// Per-tile collision flag (local tile id → solid).
    pub solid_tiles: Vec<u32>,
}

/// A standard tile layer from a TMX map.
///
/// # Fields
/// - `name` — `String`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `visible` — `bool`.
/// - `opacity` — `f32`.
/// - `offset_x` — `f32`.
/// - `offset_y` — `f32`.
/// - `tiles` — `Vec<u32>`.
#[derive(Debug, Clone)]
pub struct TmxTileLayer {
    /// Layer name.
    pub name: String,
    /// Width of the layer in tiles (may differ from the map width for infinite maps).
    pub width: u32,
    /// Height of the layer in tiles.
    pub height: u32,
    /// Layer visibility.
    pub visible: bool,
    /// Opacity in `[0.0, 1.0]`.
    pub opacity: f32,
    /// X offset in pixels.
    pub offset_x: f32,
    /// Y offset in pixels.
    pub offset_y: f32,
    /// Row-major tile GIDs.  GID 0 = empty.
    pub tiles: Vec<u32>,
}

/// An object layer (object group) from a TMX map.
///
/// # Fields
/// - `name` — `String`.
/// - `visible` — `bool`.
/// - `objects` — `Vec<TmxObject>`.
#[derive(Debug, Clone)]
pub struct TmxObjectLayer {
    /// Layer name.
    pub name: String,
    /// Layer visibility.
    pub visible: bool,
    /// Objects contained in this layer.
    pub objects: Vec<TmxObject>,
}

/// A single Tiled object within an object layer.
///
/// # Fields
/// - `id` — `u32`.
/// - `name` — `String`.
/// - `obj_type` — `String`.
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `width` — `f32`.
/// - `height` — `f32`.
/// - `gid` — `u32`.
#[derive(Debug, Clone)]
pub struct TmxObject {
    /// Optional object ID.
    pub id: u32,
    /// Optional object name.
    pub name: String,
    /// Optional object type / class.
    pub obj_type: String,
    /// X position in pixels.
    pub x: f32,
    /// Y position in pixels.
    pub y: f32,
    /// Width in pixels (0 for point objects).
    pub width: f32,
    /// Height in pixels.
    pub height: f32,
    /// GID for tile objects; 0 otherwise.
    pub gid: u32,
}

/// Variant tag for TMX map layers.
///
/// # Variants
/// - `Tile` — Tile variant.
/// - `Object` — Object variant.
#[derive(Debug, Clone)]
pub enum TmxLayer {
    /// Standard tile layer.
    Tile(TmxTileLayer),
    /// Object group layer.
    Object(TmxObjectLayer),
}

/// A fully-parsed TMX map.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `tile_width` — `u32`.
/// - `tile_height` — `u32`.
/// - `orientation` — `TmxOrientation`.
/// - `stagger_axis` — `Option<TmxStaggerAxis>`.
/// - `hex_side_length` — `u32`.
/// - `tilesets` — `Vec<TmxTileset>`.
/// - `layers` — `Vec<TmxLayer>`.
/// - `background_color` — `Option<[u8; 4]>`.
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
    /// Map rendering orientation.
    pub orientation: TmxOrientation,
    /// Stagger axis for staggered/hexagonal maps.
    pub stagger_axis: Option<TmxStaggerAxis>,
    /// Side length for hexagonal maps.
    pub hex_side_length: u32,
    /// Tilesets referenced by this map (inline or external).
    pub tilesets: Vec<TmxTileset>,
    /// Map layers in draw order (bottom to top).
    pub layers: Vec<TmxLayer>,
    /// Background colour as ARGB, if specified.
    pub background_color: Option<[u8; 4]>,
}

impl TmxMap {
    /// Returns only the tile layers, ignoring object / image layers.
    ///
    /// # Returns
    /// `impl Iterator<Item = &TmxTileLayer>`.
    pub fn tile_layers(&self) -> impl Iterator<Item = &TmxTileLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Tile(t) => Some(t),
            _ => None,
        })
    }

    /// Returns only the object layers.
    ///
    /// # Returns
    /// `impl Iterator<Item = &TmxObjectLayer>`.
    pub fn object_layers(&self) -> impl Iterator<Item = &TmxObjectLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Object(o) => Some(o),
            _ => None,
        })
    }
}

// ---------------------------------------------------------------------------
// Public parsing entry point
// ---------------------------------------------------------------------------

/// Parses a TMX file given its XML content as a string.
///
/// # Parameters
/// - `xml` — `&str`.
///
/// # Returns
/// `Result<TmxMap, String>`.
///
/// Returns a fully-populated [`TmxMap`], or an error string describing the problem.
///
/// ### Tile data encoding
/// - **XML**: `<tile gid="…"/>` child elements — always supported.
/// - **CSV**: Comma-separated list of GIDs — supported without extra dependencies.
/// - **Base64**: Base64-encoded little-endian `u32` array — supported via the `base64` crate.
/// - **Base64 + zlib**: Further decompressed with `flate2` — supported.
/// - **Base64 + gzip**: Gzip-decompressed with `flate2` — supported.
/// - **Base64 + zstd**: Not supported (returns an error).
pub fn load_tmx(xml: &str) -> Result<TmxMap, String> {
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

    // Parse tilesets
    let mut tilesets = Vec::new();
    for child in map_node.children() {
        if child.has_tag_name("tileset") {
            tilesets.push(parse_tileset(&child)?);
        }
    }

    // Parse layers
    let mut layers = Vec::new();
    for child in map_node.children() {
        if child.has_tag_name("layer") {
            let layer = parse_tile_layer(&child, width, height)?;
            layers.push(TmxLayer::Tile(layer));
        } else if child.has_tag_name("objectgroup") {
            let ol = parse_object_layer(&child)?;
            layers.push(TmxLayer::Object(ol));
        }
        // imagelayer skipped — no TileMap equivalent
    }

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

// ---------------------------------------------------------------------------
// Tileset parsing
// ---------------------------------------------------------------------------

fn parse_tileset(node: &roxmltree::Node) -> Result<TmxTileset, String> {
    let first_gid = attr_u32(node, "firstgid")?;

    // External tileset reference
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

    // Image child
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

    // Per-tile properties: collision
    let mut solid_tiles = Vec::new();
    for child in node.children() {
        if child.has_tag_name("tile") {
            let tid: u32 = child
                .attribute("id")
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
            // Look for <objectgroup> child (Tiled collision shapes)
            for sub in child.children() {
                if sub.has_tag_name("objectgroup") {
                    solid_tiles.push(tid);
                    break;
                }
                // Custom property "solid" = "true"
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

// ---------------------------------------------------------------------------
// Layer parsing
// ---------------------------------------------------------------------------

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
    let visible = node.attribute("visible").map_or(true, |s| s != "0");
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

    // Find <data> child
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
        // Strip flip flags (high 3 bits) — store raw GID for now
        tiles.push(gid & 0x1FFF_FFFF);
    }
    tiles.resize(cap, 0);
    Ok(tiles)
}

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

    // Each tile is a little-endian u32
    if bytes.len() % 4 != 0 {
        return Err(format!(
            "TMX tile data: byte count {} is not a multiple of 4",
            bytes.len()
        ));
    }
    let cap = (w * h) as usize;
    let mut tiles = Vec::with_capacity(cap);
    for chunk in bytes.chunks_exact(4) {
        let gid = u32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
        // Strip flip flags (top 3 bits)
        tiles.push(gid & 0x1FFF_FFFF);
    }
    tiles.resize(cap, 0);
    Ok(tiles)
}

// ---------------------------------------------------------------------------
// Object layer parsing
// ---------------------------------------------------------------------------

fn parse_object_layer(node: &roxmltree::Node) -> Result<TmxObjectLayer, String> {
    let name = node.attribute("name").unwrap_or("").to_string();
    let visible = node.attribute("visible").map_or(true, |s| s != "0");
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

/// Parses a Tiled colour string (`#AARRGGBB` or `#RRGGBB`) into `[A, R, G, B]`.
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

#[cfg(test)]
mod tests {
    use super::*;

    const SIMPLE_TMX: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<map version="1.9" tiledversion="1.9.0" orientation="orthogonal"
     renderorder="right-down" width="4" height="3" tilewidth="32" tileheight="32">
  <tileset firstgid="1" name="Ground" tilewidth="32" tileheight="32" tilecount="16" columns="4">
    <image source="ground.png" width="128" height="128"/>
  </tileset>
  <layer id="1" name="Tiles" width="4" height="3">
    <data encoding="csv">
1,2,1,0,
3,1,2,1,
0,1,0,2
    </data>
  </layer>
</map>
"#;

    #[test]
    fn parse_simple_map() {
        let map = load_tmx(SIMPLE_TMX).expect("parse failed");
        assert_eq!(map.width, 4);
        assert_eq!(map.height, 3);
        assert_eq!(map.tile_width, 32);
        assert_eq!(map.tile_height, 32);
        assert_eq!(map.orientation, TmxOrientation::Orthogonal);
    }

    #[test]
    fn parse_tileset() {
        let map = load_tmx(SIMPLE_TMX).unwrap();
        assert_eq!(map.tilesets.len(), 1);
        let ts = &map.tilesets[0];
        assert_eq!(ts.first_gid, 1);
        assert_eq!(ts.name, "Ground");
        assert_eq!(ts.tile_width, 32);
        assert_eq!(ts.image_source.as_deref(), Some("ground.png"));
    }

    #[test]
    fn parse_csv_tile_layer() {
        let map = load_tmx(SIMPLE_TMX).unwrap();
        let layers: Vec<_> = map.tile_layers().collect();
        assert_eq!(layers.len(), 1);
        let layer = &layers[0];
        assert_eq!(layer.name, "Tiles");
        assert_eq!(layer.width, 4);
        assert_eq!(layer.height, 3);
        assert_eq!(layer.tiles.len(), 12);
        assert_eq!(layer.tiles[0], 1); // GID 1
        assert_eq!(layer.tiles[3], 0); // GID 0 (empty)
    }

    #[test]
    fn parse_visibility_and_opacity() {
        let xml = r#"<?xml version="1.0"?>
<map version="1.9" orientation="orthogonal" width="2" height="2" tilewidth="16" tileheight="16">
  <layer id="1" name="Bg" width="2" height="2" visible="0" opacity="0.5">
    <data encoding="csv">0,0,0,0</data>
  </layer>
</map>"#;
        let map = load_tmx(xml).unwrap();
        let layer = map.tile_layers().next().unwrap();
        assert!(!layer.visible);
        assert!((layer.opacity - 0.5).abs() < 1e-5);
    }

    #[test]
    fn parse_object_layer() {
        let xml = r#"<?xml version="1.0"?>
<map version="1.9" orientation="orthogonal" width="4" height="4" tilewidth="32" tileheight="32">
  <objectgroup id="2" name="Entities">
    <object id="1" name="Player" x="64" y="96" width="32" height="32"/>
    <object id="2" name="Enemy" type="hostile" x="128" y="64" width="16" height="16"/>
  </objectgroup>
</map>"#;
        let map = load_tmx(xml).unwrap();
        assert_eq!(map.tile_layers().count(), 0);
        let objs: Vec<_> = map.object_layers().collect();
        assert_eq!(objs.len(), 1);
        assert_eq!(objs[0].objects.len(), 2);
        let player = &objs[0].objects[0];
        assert_eq!(player.name, "Player");
        assert!((player.x - 64.0).abs() < 1e-5);
    }

    #[test]
    fn parse_isometric_map() {
        let xml = r#"<?xml version="1.0"?>
<map version="1.9" orientation="isometric" width="4" height="4" tilewidth="64" tileheight="32">
</map>"#;
        let map = load_tmx(xml).unwrap();
        assert_eq!(map.orientation, TmxOrientation::Isometric);
    }

    #[test]
    fn external_tileset_reference() {
        let xml = r#"<?xml version="1.0"?>
<map version="1.9" orientation="orthogonal" width="2" height="2" tilewidth="32" tileheight="32">
  <tileset firstgid="1" source="tiles.tsx"/>
</map>"#;
        let map = load_tmx(xml).unwrap();
        assert_eq!(map.tilesets.len(), 1);
        assert_eq!(map.tilesets[0].source.as_deref(), Some("tiles.tsx"));
        assert_eq!(map.tilesets[0].first_gid, 1);
    }

    #[test]
    fn parse_background_color() {
        let xml = r##"<?xml version="1.0"?>
<map version="1.9" orientation="orthogonal" width="2" height="2" tilewidth="16" tileheight="16"
     backgroundcolor="#ff3366">
</map>"##;
        let map = load_tmx(xml).unwrap();
        let [a, r, g, b] = map.background_color.unwrap();
        assert_eq!(a, 255);
        assert_eq!(r, 0xff);
        assert_eq!(g, 0x33);
        assert_eq!(b, 0x66);
    }

    #[test]
    fn parse_xml_encoding() {
        let xml = r#"<?xml version="1.0"?>
<map version="1.9" orientation="orthogonal" width="2" height="2" tilewidth="16" tileheight="16">
  <layer id="1" name="Base" width="2" height="2">
    <data encoding="xml">
      <tile gid="5"/>
      <tile gid="3"/>
      <tile gid="0"/>
      <tile gid="2"/>
    </data>
  </layer>
</map>"#;
        let map = load_tmx(xml).unwrap();
        let layer = map.tile_layers().next().unwrap();
        assert_eq!(layer.tiles, vec![5, 3, 0, 2]);
    }
}
