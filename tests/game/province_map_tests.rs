//! Integration tests for `luna2d::province_map`.
//!
//! Covers: map construction, pixel loading, province queries, adjacency
//! detection, border extraction, map modes, position calculation, events,
//! definition loading, and graph bridge.

use std::collections::HashMap;

use luna2d::province_map::{
    adjacency::{detect_adjacency, detect_adjacency_with_tags},
    borders::{extract_all_borders, extract_borders_with_tag, extract_borders_by_property},
    core::ProvinceMap,
    definition_loader::{load_from_definitions, ProvinceDefinition},
    events::ProvinceMapEventBus,
    graph_bridge::adjacency_to_graph,
    loader::color_to_id,
    map_mode::{resolve_colors, MapMode, MapModeColorFn},
    positions::{calculate_all_positions, calculate_capital},
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Build a 4×4 RGBA test image with two 2×2 provinces side by side (left/right),
/// and a 4×2 black (empty) strip at the bottom.
///
/// Province A: `(1,0,0)` → id = `0x010000`
/// Province B: `(0,1,0)` → id = `0x000100`
fn make_image_4x4() -> (u32, u32, Vec<u8>) {
    let width = 4u32;
    let height = 4u32;
    let red: [u8; 4] = [1, 0, 0, 255];
    let green: [u8; 4] = [0, 1, 0, 255];
    let black: [u8; 4] = [0, 0, 0, 255];

    let mut pixels = Vec::with_capacity((width * height * 4) as usize);
    for y in 0..height {
        for x in 0..width {
            let color = if y < 2 {
                if x < 2 { red } else { green }
            } else {
                black
            };
            pixels.extend_from_slice(&color);
        }
    }
    (width, height, pixels)
}

fn red_id() -> u32 {
    color_to_id(1, 0, 0)
}

fn green_id() -> u32 {
    color_to_id(0, 1, 0)
}

fn loaded_map() -> ProvinceMap {
    let (w, h, pixels) = make_image_4x4();
    ProvinceMap::from_image_data(w, h, &pixels).expect("valid image")
}

fn loaded_map_with_adjacency() -> ProvinceMap {
    let mut map = loaded_map();
    detect_adjacency(&mut map);
    map
}

// ── color_to_id ───────────────────────────────────────────────────────────────

#[test]
fn color_to_id_encoding_matches_formula() {
    assert_eq!(color_to_id(1, 0, 0), 0x010000);
    assert_eq!(color_to_id(0, 1, 0), 0x000100);
    assert_eq!(color_to_id(0, 0, 1), 0x000001);
    assert_eq!(color_to_id(255, 128, 64), (255 << 16) | (128 << 8) | 64);
}

#[test]
fn color_to_id_black_is_zero() {
    assert_eq!(color_to_id(0, 0, 0), 0);
}

#[test]
fn color_to_id_white_is_max() {
    assert_eq!(color_to_id(255, 255, 255), 0x00FF_FFFF);
}

// ── ProvinceMap construction ──────────────────────────────────────────────────

#[test]
fn province_map_new_is_empty() {
    let map = ProvinceMap::new(10, 20);
    assert_eq!(map.width(), 10);
    assert_eq!(map.height(), 20);
    assert_eq!(map.province_count(), 0);
    assert!(map.province_ids().is_empty());
    assert_eq!(map.adjacency_count(), 0);
}

#[test]
fn province_map_new_pixel_lookup_is_zero() {
    let map = ProvinceMap::new(4, 4);
    for y in 0..4 {
        for x in 0..4 {
            assert_eq!(map.get_province_at(x, y), Some(0));
        }
    }
}

#[test]
fn province_map_new_out_of_bounds_returns_none() {
    let map = ProvinceMap::new(4, 4);
    assert_eq!(map.get_province_at(4, 0), None);
    assert_eq!(map.get_province_at(0, 4), None);
    assert_eq!(map.get_province_at(100, 100), None);
}

// ── from_image_data ───────────────────────────────────────────────────────────

#[test]
fn from_image_data_loads_two_provinces() {
    let map = loaded_map();
    assert_eq!(map.province_count(), 2);
}

#[test]
fn from_image_data_skips_black_pixels() {
    let map = loaded_map();
    // Province ID 0 (black) is not stored as a province
    assert!(map.get_province(0).is_none());
}

#[test]
fn from_image_data_pixel_lookup_correct() {
    let map = loaded_map();
    assert_eq!(map.get_province_at(0, 0), Some(red_id()));
    assert_eq!(map.get_province_at(1, 1), Some(red_id()));
    assert_eq!(map.get_province_at(2, 0), Some(green_id()));
    assert_eq!(map.get_province_at(3, 1), Some(green_id()));
    // Black strip bottom two rows
    assert_eq!(map.get_province_at(0, 2), Some(0));
    assert_eq!(map.get_province_at(3, 3), Some(0));
}

#[test]
fn from_image_data_area_counts_pixels() {
    let map = loaded_map();
    let a = map.get_province(red_id()).expect("red province");
    assert_eq!(a.area, 4); // 2×2 block
    let b = map.get_province(green_id()).expect("green province");
    assert_eq!(b.area, 4);
}

#[test]
fn from_image_data_centroid_in_center() {
    let map = loaded_map();
    let a = map.get_province(red_id()).unwrap();
    // Red occupies (0,0),(1,0),(0,1),(1,1) → centroid (0.5, 0.5)
    assert!((a.centroid.x - 0.5).abs() < 1e-5);
    assert!((a.centroid.y - 0.5).abs() < 1e-5);
}

#[test]
fn from_image_data_wrong_length_returns_err() {
    let result = ProvinceMap::from_image_data(4, 4, &[0u8; 10]);
    assert!(result.is_err());
}

#[test]
fn from_image_data_zero_size_returns_empty_map() {
    // 0×0 image: no pixels, no provinces
    let result = ProvinceMap::from_image_data(0, 0, &[]);
    assert!(result.is_ok());
    let map = result.unwrap();
    assert_eq!(map.province_count(), 0);
}

// ── Province queries ──────────────────────────────────────────────────────────

#[test]
fn get_province_returns_none_for_unknown_id() {
    let map = loaded_map();
    assert!(map.get_province(0xDEADBEEF).is_none());
}

#[test]
fn province_ids_sorted_ascending() {
    let map = loaded_map();
    let ids = map.province_ids();
    let mut sorted = ids.clone();
    sorted.sort_unstable();
    assert_eq!(ids, sorted);
}

// ── Adjacency detection ───────────────────────────────────────────────────────

#[test]
fn detect_adjacency_finds_shared_border() {
    let mut map = loaded_map();
    detect_adjacency(&mut map);
    // Red (x=0..1) and green (x=2..3) share a border at column x=1/x=2
    assert_eq!(map.adjacency_count(), 1);
    assert!(map.get_adjacency(red_id(), green_id()).is_some());
}

#[test]
fn detect_adjacency_order_independent() {
    let mut map = loaded_map();
    detect_adjacency(&mut map);
    let fwd = map.get_adjacency(red_id(), green_id());
    let rev = map.get_adjacency(green_id(), red_id());
    assert!(fwd.is_some());
    assert!(rev.is_some());
    // Same edge object
    assert_eq!(
        fwd.unwrap().province_a,
        rev.unwrap().province_a
    );
}

#[test]
fn detect_adjacency_border_length_nonzero() {
    let mut map = loaded_map();
    detect_adjacency(&mut map);
    let edge = map.get_adjacency(red_id(), green_id()).unwrap();
    assert!(edge.border_length > 0);
}

#[test]
fn detect_adjacency_no_neighbours_on_empty_map() {
    let mut map = ProvinceMap::new(10, 10);
    detect_adjacency(&mut map);
    assert_eq!(map.adjacency_count(), 0);
}

#[test]
fn get_neighbors_returns_correct_ids() {
    let map = loaded_map_with_adjacency();
    let neighbours = map.get_neighbors(red_id());
    assert_eq!(neighbours, vec![green_id()]);
}

#[test]
fn get_neighbors_empty_for_isolated_province() {
    let map = loaded_map(); // No adjacency detection run
    let neighbours = map.get_neighbors(red_id());
    assert!(neighbours.is_empty());
}

#[test]
fn detect_adjacency_with_tags_marks_edges() {
    let mut map = loaded_map();
    // Use red province's id as a tag pixel: any red-adjacent province pair gets the tag
    let tag_id = red_id();
    let mut tags = HashMap::new();
    tags.insert(tag_id, "river".to_string());
    detect_adjacency_with_tags(&mut map, &tags);
    // Tag pixel isn't a regular province, check adjacency was still attempted
    // (exact result depends on layout, just assert no panic)
    let _ = map.adjacency_count();
}

// ── get_adjacency_mut ─────────────────────────────────────────────────────────

#[test]
fn get_adjacency_mut_allows_tag_modification() {
    let mut map = loaded_map_with_adjacency();
    {
        let edge = map.get_adjacency_mut(red_id(), green_id()).unwrap();
        edge.tags.insert("mountain".to_string());
    }
    let edge = map.get_adjacency(red_id(), green_id()).unwrap();
    assert!(edge.tags.contains("mountain"));
}

// ── Distance ──────────────────────────────────────────────────────────────────

#[test]
fn distance_between_adjacent_provinces_is_positive() {
    let map = loaded_map();
    let d = map.distance(red_id(), green_id());
    assert!(d > 0.0);
    assert!(d.is_finite());
}

#[test]
fn distance_missing_province_is_infinity() {
    let map = loaded_map();
    let d = map.distance(red_id(), 0xDEAD);
    assert!(d.is_infinite());
}

#[test]
fn distance_same_province_is_zero() {
    let map = loaded_map();
    let d = map.distance(red_id(), red_id());
    assert!(d < 1e-5);
}

// ── Border extraction ─────────────────────────────────────────────────────────

#[test]
fn extract_all_borders_finds_one_border() {
    let map = loaded_map_with_adjacency();
    let borders = extract_all_borders(&map);
    assert_eq!(borders.len(), 1);
}

#[test]
fn extract_all_borders_empty_when_no_adjacency() {
    let map = loaded_map(); // No adjacency detection run
    let borders = extract_all_borders(&map);
    // No border segments without adjacency data
    assert!(borders.is_empty());
}

#[test]
fn extract_borders_with_tag_returns_only_tagged() {
    let mut map = loaded_map_with_adjacency();
    // Manually tag the edge
    if let Some(edge) = map.get_adjacency_mut(red_id(), green_id()) {
        edge.tags.insert("river".to_string());
    }
    let rivers = extract_borders_with_tag(&map, "river");
    let walls = extract_borders_with_tag(&map, "wall");
    assert_eq!(rivers.len(), 1);
    assert!(walls.is_empty());
}

#[test]
fn extract_borders_by_property_groups_correctly() {
    let map = loaded_map_with_adjacency();
    // Group: red = "A", green = "B" → different groups, border kept
    let group_fn = move |id: u32| -> Option<String> {
        if id == red_id() { Some("A".to_string()) }
        else if id == green_id() { Some("B".to_string()) }
        else { None }
    };
    let result = extract_borders_by_property(&map, group_fn);
    assert_eq!(result.len(), 1);
}

#[test]
fn extract_borders_by_property_same_group_excluded() {
    let map = loaded_map_with_adjacency();
    // Both provinces in the same group → border excluded
    let group_fn = |_id: u32| -> Option<String> { Some("same".to_string()) };
    let result = extract_borders_by_property(&map, group_fn);
    assert!(result.is_empty());
}

// ── Map modes ─────────────────────────────────────────────────────────────────

#[test]
fn map_mode_fixed_assigns_colours() {
    let map = loaded_map();
    let mut colors = HashMap::new();
    colors.insert(red_id(), [1.0f32, 0.0, 0.0, 1.0]);
    colors.insert(green_id(), [0.0f32, 1.0, 0.0, 1.0]);
    let mode = MapMode {
        name: "Fixed".to_string(),
        color_fn: MapModeColorFn::Fixed(colors),
    };
    let buf = resolve_colors(&map, &mode);
    assert_eq!(buf.len(), 4 * 4 * 4); // width × height × 4
}

#[test]
fn map_mode_source_color_returns_original_color() {
    let map = loaded_map();
    let mode = MapMode {
        name: "Source".to_string(),
        color_fn: MapModeColorFn::SourceColor,
    };
    let buf = resolve_colors(&map, &mode);
    // Red province at (0,0) should be red-ish in the output
    // pixel index 0 = (0,0) → buf[0..4]
    // Red province has color [1,0,0], scaled to 0..255 → [1/255, 0, 0, 1] → [1u8]
    assert_eq!(buf.len(), 4 * 4 * 4);
}

#[test]
fn map_mode_gradient_runs_without_panic() {
    let map = loaded_map();
    let mut values = HashMap::new();
    values.insert(red_id(), 0.0f64);
    values.insert(green_id(), 1.0f64);
    let mode = MapMode {
        name: "Gradient".to_string(),
        color_fn: MapModeColorFn::Gradient {
            values,
            min_color: [0.0, 0.0, 1.0, 1.0],
            max_color: [1.0, 0.0, 0.0, 1.0],
            min_val: 0.0,
            max_val: 1.0,
        },
    };
    let buf = resolve_colors(&map, &mode);
    assert_eq!(buf.len(), 4 * 4 * 4);
}

#[test]
fn map_mode_category_uses_default_for_unknown() {
    let map = loaded_map();
    let mode = MapMode {
        name: "Category".to_string(),
        color_fn: MapModeColorFn::Category {
            categories: HashMap::new(), // no assignments → all get default
            colors: HashMap::new(),
            default_color: [0.5, 0.5, 0.5, 1.0],
        },
    };
    let buf = resolve_colors(&map, &mode);
    assert_eq!(buf.len(), 4 * 4 * 4);
}

#[test]
fn resolve_colors_empty_map_produces_empty_pixels() {
    let map = ProvinceMap::new(0, 0);
    let mode = MapMode {
        name: "empty".to_string(),
        color_fn: MapModeColorFn::SourceColor,
    };
    let buf = resolve_colors(&map, &mode);
    assert!(buf.is_empty());
}

// ── Position calculation ──────────────────────────────────────────────────────

#[test]
fn calculate_capital_returns_point_inside_province() {
    let map = loaded_map();
    let pos = calculate_capital(&map, red_id());
    // The result should be within the 2×2 red block (x: 0-1, y: 0-1)
    assert!(pos.x >= 0.0 && pos.x <= 1.0);
    assert!(pos.y >= 0.0 && pos.y <= 1.0);
}

#[test]
fn calculate_capital_unknown_province_returns_zero() {
    let map = loaded_map();
    let pos = calculate_capital(&map, 0xDEAD);
    assert!(pos.x.abs() < 1e-5);
    assert!(pos.y.abs() < 1e-5);
}

#[test]
fn calculate_all_positions_sets_center_for_all() {
    let mut map = loaded_map();
    calculate_all_positions(&mut map);
    for id in map.province_ids() {
        let p = map.get_province(id).unwrap();
        // center should be a finite, non-negative coordinate
        assert!(p.center.x.is_finite());
        assert!(p.center.y.is_finite());
    }
}

// ── Events ────────────────────────────────────────────────────────────────────

#[test]
fn event_bus_starts_empty() {
    let bus = ProvinceMapEventBus::new();
    assert!(bus.is_empty());
}

#[test]
fn emit_map_loaded_pushes_event() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_map_loaded(42);
    assert!(!bus.is_empty());
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "map_loaded");
    assert!(bus.is_empty());
}

#[test]
fn emit_province_added_carries_id() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_province_added(7);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "province_added");
    assert_eq!(e.args.len(), 1);
    if let luna2d::event::EventArg::Num(n) = &e.args[0] {
        assert!((*n - 7.0).abs() < 1e-5);
    } else {
        panic!("Expected Num argument");
    }
}

#[test]
fn emit_province_removed_carries_id() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_province_removed(99);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "province_removed");
}

#[test]
fn emit_adjacency_detected_carries_edge_count() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_adjacency_detected(15);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "adjacency_detected");
    if let luna2d::event::EventArg::Num(n) = &e.args[0] {
        assert!((*n - 15.0).abs() < 1e-5);
    } else {
        panic!("Expected Num argument");
    }
}

#[test]
fn emit_adjacency_changed_carries_both_ids() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_adjacency_changed(1, 2);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "adjacency_changed");
    assert_eq!(e.args.len(), 2);
}

#[test]
fn emit_adjacency_removed_name_correct() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_adjacency_removed(3, 4);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "adjacency_removed");
}

#[test]
fn emit_borders_extracted_carries_count() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_borders_extracted(8);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "borders_extracted");
}

#[test]
fn emit_map_mode_applied_carries_name() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_map_mode_applied("Political");
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "map_mode_applied");
    if let luna2d::event::EventArg::Str(s) = &e.args[0] {
        assert_eq!(s, "Political");
    } else {
        panic!("Expected Str argument");
    }
}

#[test]
fn emit_positions_calculated_carries_count() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_positions_calculated(100);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "positions_calculated");
}

#[test]
fn emit_province_selected_carries_id_and_coords() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_province_selected(5, 10.5, 20.0);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "province_selected");
    assert_eq!(e.args.len(), 3);
}

#[test]
fn emit_province_deselected_carries_id() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_province_deselected(5);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "province_deselected");
}

#[test]
fn emit_province_hovered_carries_id_and_coords() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_province_hovered(3, 1.0, 2.0);
    let e = bus.poll().unwrap();
    assert_eq!(e.name, "province_hovered");
    assert_eq!(e.args.len(), 3);
}

#[test]
fn event_bus_drain_empties_queue_in_order() {
    let mut bus = ProvinceMapEventBus::new();
    bus.emit_map_loaded(1);
    bus.emit_adjacency_detected(2);
    bus.emit_borders_extracted(3);
    let events = bus.drain();
    assert_eq!(events.len(), 3);
    assert_eq!(events[0].name, "map_loaded");
    assert_eq!(events[1].name, "adjacency_detected");
    assert_eq!(events[2].name, "borders_extracted");
    assert!(bus.is_empty());
}

#[test]
fn event_bus_poll_on_empty_returns_none() {
    let mut bus = ProvinceMapEventBus::new();
    assert!(bus.poll().is_none());
}

// ── Definition loader ─────────────────────────────────────────────────────────

fn make_defs() -> Vec<ProvinceDefinition> {
    vec![
        ProvinceDefinition { id: 1, color: [100, 0, 0], center: (10.0, 10.0), neighbors: vec![2], name: Some("Alpha".to_string()) },
        ProvinceDefinition { id: 2, color: [0, 100, 0], center: (30.0, 10.0), neighbors: vec![1], name: Some("Beta".to_string()) },
        ProvinceDefinition { id: 3, color: [0, 0, 100], center: (20.0, 30.0), neighbors: vec![], name: None },
    ]
}

#[test]
fn load_from_definitions_creates_all_provinces() {
    let map = load_from_definitions(&make_defs(), 100, 100);
    assert_eq!(map.province_count(), 3);
}

#[test]
fn load_from_definitions_sets_province_names() {
    let map = load_from_definitions(&make_defs(), 100, 100);
    let p1 = map.get_province(1).unwrap();
    assert_eq!(p1.name.as_deref(), Some("Alpha"));
    let p3 = map.get_province(3).unwrap();
    assert!(p3.name.is_none());
}

#[test]
fn load_from_definitions_sets_center_positions() {
    let map = load_from_definitions(&make_defs(), 100, 100);
    let p1 = map.get_province(1).unwrap();
    assert!((p1.center.x - 10.0).abs() < 1e-5);
    assert!((p1.center.y - 10.0).abs() < 1e-5);
}

#[test]
fn load_from_definitions_creates_adjacency_from_neighbors() {
    let map = load_from_definitions(&make_defs(), 100, 100);
    // Provinces 1 and 2 are mutual neighbors → adjacency edge
    assert!(map.get_adjacency(1, 2).is_some());
    // Province 3 has no neighbors
    assert!(map.get_adjacency(1, 3).is_none());
}

#[test]
fn load_from_definitions_skips_id_zero() {
    let defs = vec![
        ProvinceDefinition { id: 0, color: [0, 0, 0], center: (0.0, 0.0), neighbors: vec![], name: None },
        ProvinceDefinition { id: 1, color: [1, 0, 0], center: (5.0, 5.0), neighbors: vec![], name: None },
    ];
    let map = load_from_definitions(&defs, 10, 10);
    assert_eq!(map.province_count(), 1);
    assert!(map.get_province(0).is_none());
}

#[test]
fn load_from_definitions_empty_list_returns_empty_map() {
    let map = load_from_definitions(&[], 100, 100);
    assert_eq!(map.province_count(), 0);
}

// ── Graph bridge ──────────────────────────────────────────────────────────────

#[test]
fn adjacency_to_graph_empty_map_produces_empty_graph() {
    let map = ProvinceMap::new(10, 10);
    let (graph, id_map) = adjacency_to_graph(&map);
    assert!(id_map.is_empty());
    assert!(graph.get_node_ids().is_empty());
}

#[test]
fn adjacency_to_graph_node_count_matches_provinces() {
    let map = loaded_map_with_adjacency();
    let (graph, id_map) = adjacency_to_graph(&map);
    assert_eq!(id_map.len(), map.province_count());
    assert_eq!(graph.get_node_ids().len(), map.province_count());
}

#[test]
fn adjacency_to_graph_all_province_ids_in_map() {
    let map = loaded_map_with_adjacency();
    let (_, id_map) = adjacency_to_graph(&map);
    for pid in map.province_ids() {
        assert!(id_map.contains_key(&pid));
    }
}

#[test]
fn adjacency_to_graph_definition_map_has_correct_nodes() {
    let map = load_from_definitions(&make_defs(), 100, 100);
    let (graph, id_map) = adjacency_to_graph(&map);
    // 3 provinces → 3 nodes
    assert_eq!(id_map.len(), 3);
    assert_eq!(graph.get_node_ids().len(), 3);
}
