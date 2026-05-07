//! INTERNAL ONLY: Rust-only tests for province engine internals.

use std::path::{Path, PathBuf};

use lurek2d::image::{ImageData, ProvinceGrid};
use lurek2d::province::cache::ProvinceGeometryCache;
use lurek2d::province::import::{
    import_metadata_from_files, sanitize_marked_png, MarkerSanitizeOptions,
    ProvinceMetadataImportOptions,
};
use lurek2d::province::registry::ProvinceRegistry;
use lurek2d::province::types::BorderClass;

fn sample_grid() -> ProvinceGrid {
    let mut img = ImageData::new(4, 2);
    // Row 0: A A B B
    img.set_pixel(0, 0, 255, 0, 0, 255);
    img.set_pixel(1, 0, 255, 0, 0, 255);
    img.set_pixel(2, 0, 0, 255, 0, 255);
    img.set_pixel(3, 0, 0, 255, 0, 255);
    // Row 1: A A B B
    img.set_pixel(0, 1, 255, 0, 0, 255);
    img.set_pixel(1, 1, 255, 0, 0, 255);
    img.set_pixel(2, 1, 0, 255, 0, 255);
    img.set_pixel(3, 1, 0, 255, 0, 255);
    ProvinceGrid::from_image(&img)
}

fn write_png(path: &Path, img: &ImageData) {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).expect("create test png parent");
    }
    let encoded = img.encode_png().expect("encode png");
    std::fs::write(path, encoded).expect("write png");
}

fn write_text(path: &Path, text: &str) {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).expect("create test text parent");
    }
    std::fs::write(path, text).expect("write text file");
}

fn test_output_path(name: &str) -> PathBuf {
    let mut p = std::env::temp_dir();
    p.push("lurek2d_province_tests");
    p.push(name);
    p
}

#[test]
fn test_registry_from_grid_has_provinces_and_adjacency() {
    let grid = sample_grid();
    let reg = ProvinceRegistry::from_grid(&grid);
    assert_eq!(reg.province_count(), 2);

    let neighbors_1 = reg.get_neighbors(1);
    assert_eq!(neighbors_1, vec![2]);

    let neighbors_2 = reg.get_neighbors(2);
    assert_eq!(neighbors_2, vec![1]);
}

#[test]
fn test_registry_revision_and_change_tracking() {
    let grid = sample_grid();
    let mut reg = ProvinceRegistry::from_grid(&grid);
    assert_eq!(reg.revision(), 0);

    assert!(reg.set_political_color(1, [1.0, 0.0, 0.0, 1.0]));
    assert!(reg.set_terrain_type(1, 7));

    let rev = reg.revision();
    assert!(rev >= 2);

    let changes = reg.get_changes_since(0);
    assert!(changes.len() >= 2);
}

#[test]
fn test_registry_border_class_roundtrip() {
    let grid = sample_grid();
    let mut reg = ProvinceRegistry::from_grid(&grid);

    reg.set_border_class(1, 2, BorderClass::Coast);
    assert_eq!(reg.get_border_class(1, 2), Some(BorderClass::Coast));
    assert_eq!(reg.get_border_class(2, 1), Some(BorderClass::Coast));
}

#[test]
fn test_geometry_cache_encode_decode_roundtrip() {
    let grid = sample_grid();
    let reg = ProvinceRegistry::from_grid(&grid);

    let cache = ProvinceGeometryCache::from_registry(&reg);
    let bytes = cache.encode();
    let decoded = ProvinceGeometryCache::decode(&bytes).expect("decode should succeed");

    assert_eq!(decoded.spans, cache.spans);
    assert_eq!(decoded.border_segments, cache.border_segments);
}

#[test]
fn test_registry_capital_and_label_metadata_roundtrip() {
    let grid = sample_grid();
    let mut reg = ProvinceRegistry::from_grid(&grid);

    assert!(reg.set_capital(1, 10.5, 20.5));
    assert_eq!(reg.capital_for(1), Some((10.5, 20.5)));

    assert!(reg.set_label_line(1, 1.0, 2.0, 3.0, 4.0));
    assert_eq!(reg.label_line_for(1), Some(((1.0, 2.0), (3.0, 4.0))));

    assert!(reg.set_label_text(1, "Yukon".to_string()));
    assert_eq!(reg.label_text_for(1), Some("Yukon"));

    assert!(reg.bbox_for(1).is_some());
    assert!(reg.spans_for(1).is_some());
    assert!(reg.style_for(1).is_some());
}

#[test]
fn test_sanitize_marked_png_replaces_marker_pixels() {
    let mut src = ImageData::new(3, 1);
    src.set_pixel(0, 0, 20, 40, 60, 255);
    src.set_pixel(1, 0, 255, 255, 255, 255);
    src.set_pixel(2, 0, 80, 120, 160, 255);

    let in_path = test_output_path("sanitize_input.png");
    let out_path = test_output_path("sanitize_output.png");
    write_png(&in_path, &src);

    let summary = sanitize_marked_png(
        &in_path.to_string_lossy(),
        &out_path.to_string_lossy(),
        &MarkerSanitizeOptions::default(),
    )
    .expect("sanitize should succeed");

    assert_eq!(summary.replaced_pixels, 1);
    let out = ImageData::from_file(&out_path.to_string_lossy()).expect("read output png");
    assert_eq!(out.get_pixel(1, 0), Some((20, 40, 60, 255)));
}

#[test]
fn test_import_metadata_from_files_sets_attrs_labels_and_markers() {
    let mut marked = ImageData::new(2, 1);
    marked.set_pixel(0, 0, 12, 34, 56, 255);
    marked.set_pixel(1, 0, 255, 255, 255, 255);

    let mut color_map = ImageData::new(2, 1);
    color_map.set_pixel(0, 0, 12, 34, 56, 255);
    color_map.set_pixel(1, 0, 12, 34, 56, 255);

    let marked_path = test_output_path("import_marked.png");
    let color_path = test_output_path("import_color.png");
    let csv_path = test_output_path("import_map.csv");
    let toml_path = test_output_path("import_data.toml");

    write_png(&marked_path, &marked);
    write_png(&color_path, &color_map);
    write_text(&csv_path, "id,r,g,b\n101,12,34,56\n");
    write_text(&toml_path, "[101]\nname = \"Alpha_Province\"\nterrain = \"sea\"\n");

    let grid = ProvinceGrid::from_image(&color_map);
    let mut reg = ProvinceRegistry::from_grid(&grid);
    assert_eq!(reg.province_count(), 1);

    let mut opts = ProvinceMetadataImportOptions::default();
    opts.color_map_png_path = color_path.to_string_lossy().into_owned();
    opts.marker_png_path = Some(marked_path.to_string_lossy().into_owned());
    opts.color_csv_path = csv_path.to_string_lossy().into_owned();
    opts.province_toml_path = Some(toml_path.to_string_lossy().into_owned());

    let summary = import_metadata_from_files(&mut reg, &opts).expect("import metadata");
    assert_eq!(summary.mapped_provinces, 1);
    assert!(summary.capitals_set >= 1);
    assert!(summary.labels_set >= 1);

    let snap = reg.get_province(1).expect("province 1 snapshot");
    assert_eq!(snap.style.terrain_type, 0);
    assert_eq!(snap.attrs.get("game_id").map(String::as_str), Some("101"));
    assert_eq!(snap.attrs.get("terrain").map(String::as_str), Some("sea"));
    assert_eq!(snap.attrs.get("name").map(String::as_str), Some("Alpha Province"));
    assert_eq!(reg.label_text_for(1), Some("Alpha Province"));
    assert_eq!(reg.capital_for(1), Some((1.5, 0.5)));
}
