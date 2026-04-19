//! Province data loaders for the globe module.
//!
//! Supported formats:
//! - **TOML province list** (`*.toml`): a `[[province]]` array. Human-authored.
//! - **PNG color-index** (`*.png`): each unique non-white/non-black color = one province.
//!   Boundaries are derived from connected-component analysis. (Stub for MVP.)
//!
//! Both loaders produce a `Vec<Province>` that can be inserted into a `ProvinceGraph`.

use std::collections::HashMap;
use crate::globe::types::{Province, ProvinceId};

// ── TOML province list ──────────────────────────────────────────────────────

/// Province definition as read from a TOML `[[province]]` entry.
///
/// ```toml
/// [[province]]
/// id = 1
/// name = "England"
/// centroid = [51.5, -0.1]
/// vertices = [[50.0, -5.0], [55.0, -2.0], [51.0, 1.0]]
/// neighbors = [2, 3]
/// base_color = [0.2, 0.5, 0.8, 1.0]
/// texture = "england_terrain"   # optional
///
/// [province.attrs]
/// owner = "player"
/// terrain = "plains"
/// ```
#[derive(Debug, Clone)]
struct TomlProvince {
    id: ProvinceId,
    centroid: [f32; 2],
    vertices: Vec<[f32; 2]>,
    neighbors: Vec<ProvinceId>,
    base_color: Option<[f32; 4]>,
    texture: Option<String>,
    attrs: HashMap<String, String>,
}

/// Parse a TOML province file from a string.
///
/// Expected structure:
/// ```toml
/// [[province]]
/// id = 1
/// centroid = [lat, lon]
/// vertices = [[lat, lon], ...]
/// neighbors = [id, ...]
/// ```
pub fn load_from_toml_str(src: &str) -> Result<Vec<Province>, String> {
    // Minimal hand-rolled TOML parser for the [[province]] array.
    // Full TOML parsing would use the `toml` crate; this covers the required subset.
    let doc = parse_toml_province_list(src)?;
    Ok(doc.into_iter().map(toml_province_to_province).collect())
}

/// Load province data from the filesystem (synchronous).
pub fn load_from_toml_file(path: &str) -> Result<Vec<Province>, String> {
    let src = std::fs::read_to_string(path)
        .map_err(|e| format!("cannot read '{}': {}", path, e))?;
    load_from_toml_str(&src)
}

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

// ── Minimal TOML parser ──────────────────────────────────────────────────────

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
            // Other table header — skip.
            in_attrs = false;
            continue;
        }
        if let Some(b) = current.as_mut() {
            if in_attrs {
                parse_kv_string(line, |k, v| b.attrs.insert(k, v));
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

#[derive(Default)]
struct TomlProvinceBuilder {
    id: Option<ProvinceId>,
    centroid: Option<[f32; 2]>,
    vertices: Vec<[f32; 2]>,
    neighbors: Vec<ProvinceId>,
    base_color: Option<[f32; 4]>,
    texture: Option<String>,
    attrs: HashMap<String, String>,
}

impl TomlProvinceBuilder {
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

fn parse_field(line: &str, b: &mut TomlProvinceBuilder) -> Result<(), String> {
    let eq = line.find('=').ok_or_else(|| format!("no '=' in '{}'", line))?;
    let key = line[..eq].trim();
    let val = line[eq + 1..].trim();
    match key {
        "id" => { b.id = Some(parse_u32(val)?); }
        "centroid" => { b.centroid = Some(parse_f32_pair(val)?); }
        "vertices" => { b.vertices = parse_f32_pair_array(val)?; }
        "neighbors" => { b.neighbors = parse_u32_array(val)?; }
        "base_color" => { b.base_color = Some(parse_f32_4(val)?); }
        "texture" => { b.texture = Some(strip_quotes(val).to_string()); }
        _ => {} // Unknown keys are silently ignored.
    }
    Ok(())
}

fn parse_kv_string(line: &str, mut f: impl FnMut(String, String)) {
    if let Some(eq) = line.find('=') {
        let k = line[..eq].trim().to_string();
        let v = strip_quotes(line[eq + 1..].trim()).to_string();
        f(k, v);
    }
}

fn parse_u32(s: &str) -> Result<u32, String> {
    s.trim().parse().map_err(|_| format!("not a u32: '{}'", s))
}

fn parse_f32_pair(s: &str) -> Result<[f32; 2], String> {
    let inner = s.trim().trim_start_matches('[').trim_end_matches(']');
    let parts: Vec<&str> = inner.split(',').collect();
    if parts.len() != 2 {
        return Err(format!("expected [f, f], got '{}'", s));
    }
    Ok([
        parts[0].trim().parse().map_err(|_| format!("bad f32 '{}'", parts[0]))?,
        parts[1].trim().parse().map_err(|_| format!("bad f32 '{}'", parts[1]))?,
    ])
}

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

fn parse_f32_pair_array(s: &str) -> Result<Vec<[f32; 2]>, String> {
    // e.g. [[50.0, -5.0], [55.0, -2.0], [51.0, 1.0]]
    let s = s.trim().trim_start_matches('[').trim_end_matches(']');
    let mut out = Vec::new();
    let mut depth = 0i32;
    let mut start = 0usize;
    for (i, c) in s.char_indices() {
        match c {
            '[' => {
                if depth == 0 { start = i; }
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

fn parse_u32_array(s: &str) -> Result<Vec<u32>, String> {
    let inner = s.trim().trim_start_matches('[').trim_end_matches(']');
    if inner.trim().is_empty() {
        return Ok(Vec::new());
    }
    inner.split(',')
        .map(|p| p.trim().parse().map_err(|_| format!("bad u32 '{}'", p)))
        .collect()
}

fn strip_quotes(s: &str) -> &str {
    let s = s.trim();
    if (s.starts_with('"') && s.ends_with('"')) || (s.starts_with('\'') && s.ends_with('\'')) {
        &s[1..s.len() - 1]
    } else {
        s
    }
}

// ── PNG color-index loader (stub) ─────────────────────────────────────────────

/// Load provinces from a color-indexed PNG.
///
/// Each unique color in the image corresponds to one province. The province ID is
/// derived from the color value. Boundaries are the convex hull of the pixels with
/// that color (converted from pixel space to lat/lon via a configurable projection).
///
/// **This is a stub implementation.** It returns an empty list and logs a warning.
/// Full implementation requires a flood-fill connected-component analysis and a
/// pixel → lat/lon coordinate transform (provided by the caller as a closure).
pub fn load_from_png_file(_path: &str) -> Result<Vec<Province>, String> {
    // TODO(globe/P2): implement PNG color-index loader.
    // Requires: image decoding (image crate or raw pixel read), connected-component
    // analysis per color, convex-hull or bounding-polygon extraction, lat/lon mapping.
    Ok(Vec::new())
}
