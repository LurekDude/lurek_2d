//! Globe province loading from TOML, PNG grids, and generated Voronoi points.
//!
//! Owns lightweight parsing and conversion into shared province types.
//! Registry insertion and render behavior stay outside this module.

use crate::globe::types::{Province, ProvinceId};
use crate::image::province_grid::ProvinceGrid;
use crate::math::voronoi::voronoi_from_points;
use std::collections::HashMap;
/// Parsed TOML province record before conversion into the shared province type.
#[derive(Debug, Clone)]
struct TomlProvince {
    /// Province identifier.
    id: ProvinceId,
    /// Province centroid as latitude and longitude.
    centroid: [f32; 2],
    /// Province polygon vertices as latitude and longitude pairs.
    vertices: Vec<[f32; 2]>,
    /// Neighboring province ids.
    neighbors: Vec<ProvinceId>,
    /// Optional base RGBA color.
    base_color: Option<[f32; 4]>,
    /// Optional province texture name.
    texture: Option<String>,
    /// Arbitrary string attributes.
    attrs: HashMap<String, String>,
}
/// Load provinces from a TOML string or return a parse error.
pub fn load_from_toml_str(src: &str) -> Result<Vec<Province>, String> {
    let doc = parse_toml_province_list(src)?;
    Ok(doc.into_iter().map(toml_province_to_province).collect())
}
/// Load provinces from a TOML file path or return a parse or I/O error.
pub fn load_from_toml_file(path: &str) -> Result<Vec<Province>, String> {
    let src =
        std::fs::read_to_string(path).map_err(|e| format!("cannot read '{}': {}", path, e))?;
    load_from_toml_str(&src)
}
/// Convert a parsed TOML province into the shared province type.
fn toml_province_to_province(tp: TomlProvince) -> Province {
    let verts: Vec<(f32, f32)> = tp.vertices.iter().map(|v| (v[0], v[1])).collect();
    let mut p = Province::new(tp.id, verts);
    p.centroid = (tp.centroid[0], tp.centroid[1]);
    p.neighbors = tp.neighbors;
    p.base_color = tp.base_color.unwrap_or([0.5, 0.5, 0.5, 1.0]);
    p.texture = tp.texture;
    p.attrs = tp.attrs;
    p
}
/// Parse a TOML province list using the local lightweight parser.
fn parse_toml_province_list(src: &str) -> Result<Vec<TomlProvince>, String> {
    let mut provinces: Vec<TomlProvince> = Vec::new();
    let mut current: Option<TomlProvinceBuilder> = None;
    let mut in_attrs = false;
    for (line_no, raw_line) in src.lines().enumerate() {
        let line = raw_line.trim();
        if line.starts_with('#') || line.is_empty() {
            continue;
        }
        if line == "[[province]]" {
            if let Some(b) = current.take() {
                provinces.push(b.build().map_err(|e| format!("line {}: {}", line_no, e))?);
            }
            current = Some(TomlProvinceBuilder::default());
            in_attrs = false;
            continue;
        }
        if line == "[province.attrs]" {
            in_attrs = true;
            continue;
        }
        if line.starts_with('[') {
            in_attrs = false;
            continue;
        }
        if let Some(b) = current.as_mut() {
            if in_attrs {
                parse_kv_string(line, |k, v| {
                    b.attrs.insert(k, v);
                });
            } else {
                parse_field(line, b).map_err(|e| format!("line {}: {}", line_no, e))?;
            }
        }
    }
    if let Some(b) = current {
        provinces.push(b.build()?);
    }
    Ok(provinces)
}
/// Incremental TOML province builder used by the lightweight parser.
#[derive(Default)]
struct TomlProvinceBuilder {
    /// Optional province identifier.
    id: Option<ProvinceId>,
    /// Optional centroid pair.
    centroid: Option<[f32; 2]>,
    /// Collected province vertices.
    vertices: Vec<[f32; 2]>,
    /// Collected neighbor ids.
    neighbors: Vec<ProvinceId>,
    /// Optional base RGBA color.
    base_color: Option<[f32; 4]>,
    /// Optional texture name.
    texture: Option<String>,
    /// Collected string attributes.
    attrs: HashMap<String, String>,
}
impl TomlProvinceBuilder {
    /// Finalize the builder into a TOML province or return a missing-field error.
    fn build(self) -> Result<TomlProvince, String> {
        Ok(TomlProvince {
            id: self.id.ok_or("province missing 'id'")?,
            centroid: self.centroid.unwrap_or([0.0, 0.0]),
            vertices: self.vertices,
            neighbors: self.neighbors,
            base_color: self.base_color,
            texture: self.texture,
            attrs: self.attrs,
        })
    }
}
/// Parse one non-attribute TOML field into the province builder.
fn parse_field(line: &str, b: &mut TomlProvinceBuilder) -> Result<(), String> {
    let eq = line
        .find('=')
        .ok_or_else(|| format!("no '=' in '{}'", line))?;
    let key = line[..eq].trim();
    let val = line[eq + 1..].trim();
    match key {
        "id" => {
            b.id = Some(parse_u32(val)?);
        }
        "centroid" => {
            b.centroid = Some(parse_f32_pair(val)?);
        }
        "vertices" => {
            b.vertices = parse_f32_pair_array(val)?;
        }
        "neighbors" => {
            b.neighbors = parse_u32_array(val)?;
        }
        "base_color" => {
            b.base_color = Some(parse_f32_4(val)?);
        }
        "texture" => {
            b.texture = Some(strip_quotes(val).to_string());
        }
        _ => {}
    }
    Ok(())
}
/// Parse one string key-value pair line and call the supplied sink.
fn parse_kv_string(line: &str, mut f: impl FnMut(String, String)) {
    if let Some(eq) = line.find('=') {
        let k = line[..eq].trim().to_string();
        let v = strip_quotes(line[eq + 1..].trim()).to_string();
        f(k, v);
    }
}
/// Parse a u32 literal or return a parse error.
fn parse_u32(s: &str) -> Result<u32, String> {
    s.trim().parse().map_err(|_| format!("not a u32: '{}'", s))
}
/// Parse a two-element float array or return a parse error.
fn parse_f32_pair(s: &str) -> Result<[f32; 2], String> {
    let inner = s.trim().trim_start_matches('[').trim_end_matches(']');
    let parts: Vec<&str> = inner.split(',').collect();
    if parts.len() != 2 {
        return Err(format!("expected [f, f], got '{}'", s));
    }
    Ok([
        parts[0]
            .trim()
            .parse()
            .map_err(|_| format!("bad f32 '{}'", parts[0]))?,
        parts[1]
            .trim()
            .parse()
            .map_err(|_| format!("bad f32 '{}'", parts[1]))?,
    ])
}
/// Parse a four-element float array or return a parse error.
fn parse_f32_4(s: &str) -> Result<[f32; 4], String> {
    let inner = s.trim().trim_start_matches('[').trim_end_matches(']');
    let parts: Vec<&str> = inner.split(',').collect();
    if parts.len() != 4 {
        return Err(format!("expected 4 floats, got '{}'", s));
    }
    let mut out = [0.0f32; 4];
    for (i, p) in parts.iter().enumerate() {
        out[i] = p.trim().parse().map_err(|_| format!("bad f32 '{}'", p))?;
    }
    Ok(out)
}
/// Parse an array of two-element float arrays or return a parse error.
fn parse_f32_pair_array(s: &str) -> Result<Vec<[f32; 2]>, String> {
    let s = s.trim().trim_start_matches('[').trim_end_matches(']');
    let mut out = Vec::new();
    let mut depth = 0i32;
    let mut start = 0usize;
    for (i, c) in s.char_indices() {
        match c {
            '[' => {
                if depth == 0 {
                    start = i;
                }
                depth += 1;
            }
            ']' => {
                depth -= 1;
                if depth == 0 {
                    out.push(parse_f32_pair(&s[start..=i])?);
                }
            }
            _ => {}
        }
    }
    Ok(out)
}
/// Parse a u32 array or return a parse error.
fn parse_u32_array(s: &str) -> Result<Vec<u32>, String> {
    let inner = s.trim().trim_start_matches('[').trim_end_matches(']');
    if inner.trim().is_empty() {
        return Ok(Vec::new());
    }
    inner
        .split(',')
        .map(|p| p.trim().parse().map_err(|_| format!("bad u32 '{}'", p)))
        .collect()
}
/// Strip matching single or double quotes from a string literal.
fn strip_quotes(s: &str) -> &str {
    let s = s.trim();
    if (s.starts_with('"') && s.ends_with('"')) || (s.starts_with('\'') && s.ends_with('\'')) {
        &s[1..s.len() - 1]
    } else {
        s
    }
}
/// Load provinces from a PNG province grid or return a decode or I/O error.
pub fn load_from_png_file(_path: &str) -> Result<Vec<Province>, String> {
    let grid = ProvinceGrid::from_file(_path)?;
    let width = grid.width().max(1);
    let height = grid.height().max(1);
    let mut bounds: HashMap<ProvinceId, (u32, u32, u32, u32)> = HashMap::new();
    for y in 0..height {
        for x in 0..width {
            let id = grid.get_at(x, y);
            if id == 0 {
                continue;
            }
            let e = bounds.entry(id).or_insert((x, y, x, y));
            e.0 = e.0.min(x);
            e.1 = e.1.min(y);
            e.2 = e.2.max(x);
            e.3 = e.3.max(y);
        }
    }
    let mut neighbors: HashMap<ProvinceId, Vec<ProvinceId>> = HashMap::new();
    for (a, b, _) in grid.adjacencies() {
        neighbors.entry(*a).or_default().push(*b);
        neighbors.entry(*b).or_default().push(*a);
    }
    let mut out = Vec::with_capacity(bounds.len());
    for (id, (min_x, min_y, max_x, max_y)) in bounds {
        let to_lon = |x: u32| (x as f32 / width as f32) * 360.0 - 180.0;
        let to_lat = |y: u32| 90.0 - (y as f32 / height as f32) * 180.0;
        let lat0 = to_lat(min_y);
        let lat1 = to_lat(max_y);
        let lon0 = to_lon(min_x);
        let lon1 = to_lon(max_x);
        let vertices = vec![(lat0, lon0), (lat0, lon1), (lat1, lon1), (lat1, lon0)];
        let centroid = ((lat0 + lat1) * 0.5, (lon0 + lon1) * 0.5);
        let p = Province::with_data(
            id,
            centroid,
            vertices,
            neighbors.remove(&id).unwrap_or_default(),
            [0.5, 0.5, 0.5, 1.0],
        );
        out.push(p);
    }
    Ok(out)
}
/// Generate approximate provinces from Voronoi input points.
pub fn generate_voronoi_provinces(points: &[(f32, f32)]) -> Vec<Province> {
    if points.is_empty() {
        return Vec::new();
    }
    let pts_xy: Vec<(f32, f32)> = points.iter().map(|(lat, lon)| (*lon, *lat)).collect();
    let cells = voronoi_from_points(&pts_xy);
    let mut out = Vec::with_capacity(cells.len());
    for (i, cell) in cells.iter().enumerate() {
        let id = (i + 1) as u32;
        let mut vertices = Vec::with_capacity(cell.vertices.len().max(3));
        if cell.vertices.is_empty() {
            let (x, y) = cell.site;
            vertices.push((y - 0.5, x - 0.5));
            vertices.push((y - 0.5, x + 0.5));
            vertices.push((y + 0.5, x));
        } else {
            for (x, y) in &cell.vertices {
                let lat = (*y).clamp(-90.0, 90.0);
                let lon = (*x).clamp(-180.0, 180.0);
                vertices.push((lat, lon));
            }
        }
        let centroid = points.get(i).copied().unwrap_or((0.0, 0.0));
        out.push(Province::with_data(
            id,
            centroid,
            vertices,
            Vec::new(),
            [0.45, 0.45, 0.5, 1.0],
        ));
    }
    for i in 0..out.len() {
        let (ilat, ilon) = out[i].centroid;
        let mut nearest: Vec<(f32, u32)> = out
            .iter()
            .filter(|p| p.id != out[i].id)
            .map(|p| {
                let dlat = ilat - p.centroid.0;
                let dlon = ilon - p.centroid.1;
                (dlat * dlat + dlon * dlon, p.id)
            })
            .collect();
        nearest.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
        out[i].neighbors = nearest.into_iter().take(4).map(|(_, id)| id).collect();
    }
    out
}
