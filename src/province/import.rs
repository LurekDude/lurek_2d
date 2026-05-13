use crate::image::ImageData;
use crate::province::registry::ProvinceRegistry;
use std::collections::{HashMap, HashSet};
use std::path::Path;
#[derive(Debug, Clone)]
struct ProvinceInfo {
    name: Option<String>,
    terrain: Option<String>,
}
#[derive(Debug, Clone)]
pub struct MarkerSanitizeOptions {
    pub capital_min: u8,
    pub label_r_min: u8,
    pub label_g_max: u8,
    pub label_b_min: u8,
    pub search_radius: u32,
}
impl Default for MarkerSanitizeOptions {
    fn default() -> Self {
        Self {
            capital_min: 245,
            label_r_min: 210,
            label_g_max: 80,
            label_b_min: 210,
            search_radius: 6,
        }
    }
}
#[derive(Debug, Clone, Copy)]
pub struct MarkerSanitizeSummary {
    pub replaced_pixels: u32,
    pub unresolved_pixels: u32,
}
#[derive(Debug, Clone)]
pub struct ProvinceMetadataImportOptions {
    pub color_map_png_path: String,
    pub marker_png_path: Option<String>,
    pub color_csv_path: String,
    pub province_toml_path: Option<String>,
    pub water_terrain_tokens: Vec<String>,
    pub water_terrain_type: u32,
    pub land_terrain_type: u32,
    pub set_political_colors: bool,
    pub set_label_text: bool,
    pub set_capitals: bool,
    pub set_label_lines: bool,
    pub marker_options: MarkerSanitizeOptions,
}
impl Default for ProvinceMetadataImportOptions {
    fn default() -> Self {
        Self {
            color_map_png_path: String::new(),
            marker_png_path: None,
            color_csv_path: String::new(),
            province_toml_path: None,
            water_terrain_tokens: vec!["sea".to_string(), "river".to_string()],
            water_terrain_type: 0,
            land_terrain_type: 1,
            set_political_colors: true,
            set_label_text: true,
            set_capitals: true,
            set_label_lines: true,
            marker_options: MarkerSanitizeOptions::default(),
        }
    }
}
#[derive(Debug, Clone, Copy)]
pub struct ProvinceMetadataImportSummary {
    pub mapped_provinces: u32,
    pub capitals_set: u32,
    pub label_lines_set: u32,
    pub labels_set: u32,
}
fn pack_rgb(r: u8, g: u8, b: u8) -> u32 {
    ((r as u32) << 16) | ((g as u32) << 8) | (b as u32)
}
fn is_capital_marker(r: u8, g: u8, b: u8, opts: &MarkerSanitizeOptions) -> bool {
    r >= opts.capital_min && g >= opts.capital_min && b >= opts.capital_min
}
fn is_label_marker(r: u8, g: u8, b: u8, opts: &MarkerSanitizeOptions) -> bool {
    r >= opts.label_r_min && g <= opts.label_g_max && b >= opts.label_b_min
}
fn is_special_marker(r: u8, g: u8, b: u8, opts: &MarkerSanitizeOptions) -> bool {
    is_capital_marker(r, g, b, opts) || is_label_marker(r, g, b, opts)
}
fn find_owner_rgb(
    img: &ImageData,
    x: u32,
    y: u32,
    opts: &MarkerSanitizeOptions,
) -> Option<(u8, u8, u8)> {
    let w = img.width() as i32;
    let h = img.height() as i32;
    let x = x as i32;
    let y = y as i32;
    for radius in 1..=opts.search_radius as i32 {
        for dy in -radius..=radius {
            for dx in -radius..=radius {
                if dx.abs() != radius && dy.abs() != radius {
                    continue;
                }
                let xx = x + dx;
                let yy = y + dy;
                if xx < 0 || yy < 0 || xx >= w || yy >= h {
                    continue;
                }
                if let Some((r, g, b, _)) = img.get_pixel(xx as u32, yy as u32) {
                    if !is_special_marker(r, g, b, opts) {
                        return Some((r, g, b));
                    }
                }
            }
        }
    }
    None
}
pub fn sanitize_marked_png(
    input_png_path: &str,
    output_png_path: &str,
    opts: &MarkerSanitizeOptions,
) -> Result<MarkerSanitizeSummary, String> {
    let src = ImageData::from_file(input_png_path)?;
    let (w, h) = src.dimensions();
    let mut out = ImageData::new(w, h);
    let mut replaced_pixels = 0u32;
    let mut unresolved_pixels = 0u32;
    for y in 0..h {
        for x in 0..w {
            let (r, g, b, _) = src
                .get_pixel(x, y)
                .ok_or_else(|| "sanitize_marked_png: pixel read out of bounds".to_string())?;
            if is_special_marker(r, g, b, opts) {
                if let Some((rr, gg, bb)) = find_owner_rgb(&src, x, y, opts) {
                    out.set_pixel(x, y, rr, gg, bb, 255);
                    replaced_pixels = replaced_pixels.saturating_add(1);
                } else {
                    out.set_pixel(x, y, 0, 0, 0, 255);
                    unresolved_pixels = unresolved_pixels.saturating_add(1);
                }
            } else {
                out.set_pixel(x, y, r, g, b, 255);
            }
        }
    }
    if let Some(parent) = Path::new(output_png_path).parent() {
        if !parent.as_os_str().is_empty() {
            std::fs::create_dir_all(parent).map_err(|e| {
                format!(
                    "sanitize_marked_png: failed to create output directory '{}': {}",
                    parent.to_string_lossy(),
                    e
                )
            })?;
        }
    }
    let encoded = out.encode_png()?;
    std::fs::write(output_png_path, encoded).map_err(|e| {
        format!(
            "sanitize_marked_png: failed to write '{}': {}",
            output_png_path, e
        )
    })?;
    Ok(MarkerSanitizeSummary {
        replaced_pixels,
        unresolved_pixels,
    })
}
fn parse_rgb_id_map(csv_path: &str) -> Result<HashMap<u32, u32>, String> {
    let raw = std::fs::read_to_string(csv_path)
        .map_err(|e| format!("province metadata: failed to read '{}': {}", csv_path, e))?;
    let mut out = HashMap::new();
    let mut rdr = csv::ReaderBuilder::new()
        .has_headers(true)
        .from_reader(raw.as_bytes());
    for row in rdr.records() {
        let rec = row.map_err(|e| {
            format!(
                "province metadata: invalid CSV row in '{}': {}",
                csv_path, e
            )
        })?;
        if rec.len() < 4 {
            continue;
        }
        let game_id = rec
            .get(0)
            .unwrap_or_default()
            .trim()
            .parse::<u32>()
            .map_err(|e| {
                format!(
                    "province metadata: invalid game id '{}': {}",
                    rec.get(0).unwrap_or_default(),
                    e
                )
            })?;
        let r = rec
            .get(1)
            .unwrap_or_default()
            .trim()
            .parse::<u8>()
            .map_err(|e| {
                format!(
                    "province metadata: invalid red '{}': {}",
                    rec.get(1).unwrap_or_default(),
                    e
                )
            })?;
        let g = rec
            .get(2)
            .unwrap_or_default()
            .trim()
            .parse::<u8>()
            .map_err(|e| {
                format!(
                    "province metadata: invalid green '{}': {}",
                    rec.get(2).unwrap_or_default(),
                    e
                )
            })?;
        let b = rec
            .get(3)
            .unwrap_or_default()
            .trim()
            .parse::<u8>()
            .map_err(|e| {
                format!(
                    "province metadata: invalid blue '{}': {}",
                    rec.get(3).unwrap_or_default(),
                    e
                )
            })?;
        out.insert(pack_rgb(r, g, b), game_id);
    }
    Ok(out)
}
fn parse_province_toml(path: &str) -> Result<HashMap<u32, ProvinceInfo>, String> {
    let raw = std::fs::read_to_string(path)
        .map_err(|e| format!("province metadata: failed to read '{}': {}", path, e))?;
    let value: toml::Value = toml::from_str(&raw)
        .map_err(|e| format!("province metadata: invalid TOML '{}': {}", path, e))?;
    let Some(root) = value.as_table() else {
        return Ok(HashMap::new());
    };
    let mut out = HashMap::new();
    for (key, entry) in root {
        let Ok(id) = key.parse::<u32>() else {
            continue;
        };
        let Some(table) = entry.as_table() else {
            continue;
        };
        let name = table
            .get("name")
            .and_then(toml::Value::as_str)
            .map(str::to_string);
        let terrain = table
            .get("terrain")
            .and_then(toml::Value::as_str)
            .map(str::to_string);
        out.insert(id, ProvinceInfo { name, terrain });
    }
    Ok(out)
}
fn color_for_gameid(game_id: u32, water: bool) -> [f32; 4] {
    if water {
        return [45.0 / 255.0, 120.0 / 255.0, 215.0 / 255.0, 1.0];
    }
    let h = (game_id.wrapping_mul(1_103_515_245).wrapping_add(12_345)) % 997;
    let r = 80 + (h % 120);
    let g = 110 + ((h * 3) % 110);
    let b = 70 + ((h * 7) % 90);
    [r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0, 1.0]
}
pub fn import_metadata_from_files(
    registry: &mut ProvinceRegistry,
    opts: &ProvinceMetadataImportOptions,
) -> Result<ProvinceMetadataImportSummary, String> {
    if opts.color_map_png_path.trim().is_empty() {
        return Err("province metadata: color_map_png_path is required".to_string());
    }
    if opts.color_csv_path.trim().is_empty() {
        return Err("province metadata: color_csv_path is required".to_string());
    }
    let color_img = ImageData::from_file(&opts.color_map_png_path)?;
    let marker_img = if let Some(path) = &opts.marker_png_path {
        ImageData::from_file(path)?
    } else {
        color_img.clone()
    };
    let (reg_w, reg_h) = (registry.width(), registry.height());
    if color_img.width() != reg_w || color_img.height() != reg_h {
        return Err(format!(
            "province metadata: color map dimensions mismatch, expected {}x{}, got {}x{}",
            reg_w,
            reg_h,
            color_img.width(),
            color_img.height()
        ));
    }
    if marker_img.width() != reg_w || marker_img.height() != reg_h {
        return Err(format!(
            "province metadata: marker map dimensions mismatch, expected {}x{}, got {}x{}",
            reg_w,
            reg_h,
            marker_img.width(),
            marker_img.height()
        ));
    }
    let rgb_to_game_id = parse_rgb_id_map(&opts.color_csv_path)?;
    let province_info = if let Some(path) = &opts.province_toml_path {
        parse_province_toml(path)?
    } else {
        HashMap::new()
    };
    let water_tokens: HashSet<String> = opts
        .water_terrain_tokens
        .iter()
        .map(|s| s.to_ascii_lowercase())
        .collect();
    let mut gid_to_game_id: HashMap<u32, u32> = HashMap::new();
    let mut label_points: HashMap<u32, Vec<(f32, f32)>> = HashMap::new();
    let mut mapped_provinces = 0u32;
    let mut capitals_set = 0u32;
    let mut labels_set = 0u32;
    for y in 0..reg_h {
        for x in 0..reg_w {
            let gid = registry.get_at(x, y);
            if gid == 0 {
                continue;
            }
            if let std::collections::hash_map::Entry::Vacant(entry) = gid_to_game_id.entry(gid) {
                let (r, g, b, _) = color_img.get_pixel(x, y).ok_or_else(|| {
                    "province metadata: color map pixel out of bounds".to_string()
                })?;
                if let Some(game_id) = rgb_to_game_id.get(&pack_rgb(r, g, b)).copied() {
                    entry.insert(game_id);
                    mapped_provinces = mapped_provinces.saturating_add(1);
                    let info = province_info.get(&game_id);
                    let terrain = info
                        .and_then(|p| p.terrain.as_ref())
                        .map(|s| s.to_ascii_lowercase());
                    let is_water = terrain
                        .as_ref()
                        .map(|t| water_tokens.contains(t))
                        .unwrap_or(false);
                    let terrain_type = if is_water {
                        opts.water_terrain_type
                    } else {
                        opts.land_terrain_type
                    };
                    registry.set_terrain_type(gid, terrain_type);
                    if opts.set_political_colors {
                        registry.set_political_color(gid, color_for_gameid(game_id, is_water));
                    }
                    registry.set_attr(gid, "game_id".to_string(), game_id.to_string());
                    if let Some(t) = terrain {
                        registry.set_attr(gid, "terrain".to_string(), t.clone());
                    }
                    if opts.set_label_text {
                        let label = info
                            .and_then(|p| p.name.as_ref())
                            .map(|s| s.replace('_', " "))
                            .unwrap_or_else(|| game_id.to_string());
                        if registry.set_label_text(gid, label.clone()) {
                            labels_set = labels_set.saturating_add(1);
                        }
                        registry.set_attr(gid, "name".to_string(), label);
                    }
                }
            }
            let (mr, mg, mb, _) = marker_img
                .get_pixel(x, y)
                .ok_or_else(|| "province metadata: marker map pixel out of bounds".to_string())?;
            if opts.set_capitals && is_capital_marker(mr, mg, mb, &opts.marker_options) {
                if registry.set_capital(gid, x as f32 + 0.5, y as f32 + 0.5) {
                    capitals_set = capitals_set.saturating_add(1);
                }
            } else if opts.set_label_lines && is_label_marker(mr, mg, mb, &opts.marker_options) {
                label_points
                    .entry(gid)
                    .or_default()
                    .push((x as f32 + 0.5, y as f32 + 0.5));
            }
        }
    }
    let mut label_lines_set = 0u32;
    if opts.set_label_lines {
        for (gid, points) in label_points {
            if points.len() < 2 {
                continue;
            }
            let mut best = -1.0f32;
            let mut p1 = points[0];
            let mut p2 = points[1];
            for i in 0..(points.len() - 1) {
                for j in (i + 1)..points.len() {
                    let dx = points[j].0 - points[i].0;
                    let dy = points[j].1 - points[i].1;
                    let d2 = dx * dx + dy * dy;
                    if d2 > best {
                        best = d2;
                        p1 = points[i];
                        p2 = points[j];
                    }
                }
            }
            if registry.set_label_line(gid, p1.0, p1.1, p2.0, p2.1) {
                label_lines_set = label_lines_set.saturating_add(1);
            }
        }
    }
    Ok(ProvinceMetadataImportSummary {
        mapped_provinces,
        capitals_set,
        label_lines_set,
        labels_set,
    })
}
