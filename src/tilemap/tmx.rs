use crate::log_msg;
use crate::runtime::log_messages::{TL01, TL02};
use base64::Engine as _;
use flate2::read::{GzDecoder, ZlibDecoder};
use std::io::Read;
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxOrientation {
    Orthogonal,
    Isometric,
    Staggered,
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TmxStaggerAxis {
    X,
    Y,
}
#[derive(Debug, Clone)]
pub struct TmxTileset {
    pub first_gid: u32,
    pub source: Option<String>,
    pub name: String,
    pub tile_width: u32,
    pub tile_height: u32,
    pub spacing: u32,
    pub margin: u32,
    pub tile_count: u32,
    pub columns: u32,
    pub image_source: Option<String>,
    pub image_width: u32,
    pub image_height: u32,
    pub solid_tiles: Vec<u32>,
}
#[derive(Debug, Clone)]
pub struct TmxTileLayer {
    pub name: String,
    pub width: u32,
    pub height: u32,
    pub visible: bool,
    pub opacity: f32,
    pub offset_x: f32,
    pub offset_y: f32,
    pub tiles: Vec<u32>,
}
#[derive(Debug, Clone)]
pub struct TmxObjectLayer {
    pub name: String,
    pub visible: bool,
    pub objects: Vec<TmxObject>,
}
#[derive(Debug, Clone)]
pub struct TmxObject {
    pub id: u32,
    pub name: String,
    pub obj_type: String,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub gid: u32,
}
#[derive(Debug, Clone)]
pub enum TmxLayer {
    Tile(TmxTileLayer),
    Object(TmxObjectLayer),
}
#[derive(Debug, Clone)]
pub struct TmxMap {
    pub width: u32,
    pub height: u32,
    pub tile_width: u32,
    pub tile_height: u32,
    pub orientation: TmxOrientation,
    pub stagger_axis: Option<TmxStaggerAxis>,
    pub hex_side_length: u32,
    pub tilesets: Vec<TmxTileset>,
    pub layers: Vec<TmxLayer>,
    pub background_color: Option<[u8; 4]>,
}
impl TmxMap {
    pub fn tile_layers(&self) -> impl Iterator<Item = &TmxTileLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Tile(t) => Some(t),
            _ => None,
        })
    }
    pub fn object_layers(&self) -> impl Iterator<Item = &TmxObjectLayer> {
        self.layers.iter().filter_map(|l| match l {
            TmxLayer::Object(o) => Some(o),
            _ => None,
        })
    }
}
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
