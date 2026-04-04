//! Integration tests for `luna2d::province` — province-based map system.

use std::collections::HashMap;

use luna2d::math::Vec2;
use luna2d::province::adjacency::detect_adjacency;
use luna2d::province::borders::extract_all_borders;
use luna2d::province::core::{Province, ProvinceMap};
use luna2d::province::events::ProvinceEventBus;
use luna2d::province::fog::{FogOfWar, FogState};
use luna2d::province::map_mode::{resolve_colors, MapMode, MapModeColorFn};
use luna2d::province::minimap::ProvinceMinimap;
use luna2d::province::movement::MovementManager;
use luna2d::province::objects::ObjectManager;
use luna2d::province::organization::OrganizationManager;
use luna2d::province::pathfinding::{ProvinceCostFn, ProvincePath};
use luna2d::province::positions::calculate_all_positions;
use luna2d::province::properties::{ProvinceData, ProvinceProperties, ProvinceState, ProvinceValue};
use luna2d::province::relations::RelationManager;
use luna2d::province::worldgen::{generate_world, WorldGenConfig};

// ============================================================
// 1. Province and ProvinceMap basics
// ============================================================

#[test]
fn test_province_new_defaults() {
    let p = Province::new(42, [255, 0, 0]);
    assert_eq!(p.id, 42);
    assert_eq!(p.color, [255, 0, 0]);
    assert_eq!(p.area, 0);
    assert!(p.positions.is_empty());
    assert!((p.centroid.x).abs() < 1e-5);
    assert!((p.centroid.y).abs() < 1e-5);
}

#[test]
fn test_province_map_new_empty() {
    let map = ProvinceMap::new(100, 50);
    assert_eq!(map.width(), 100);
    assert_eq!(map.height(), 50);
    assert_eq!(map.province_count(), 0);
    assert!(map.province_ids().is_empty());
}

#[test]
fn test_province_map_from_image_lookup() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0; // 65536
    assert_eq!(map.province_count(), 2);
    assert!(map.get_province(id_a).is_some());
    assert_eq!(map.get_province(id_a).unwrap().id, id_a);
    assert!(map.get_province(999).is_none());
}

#[test]
fn test_province_map_pixel_lookup() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;
    // Province A occupies top-left 2x2
    assert_eq!(map.get_province_at(0, 0), Some(id_a));
    // Province B occupies top-right 2x2
    assert_eq!(map.get_province_at(2, 0), Some(id_b));
    // Bottom half is black => id 0
    assert_eq!(map.get_province_at(0, 3), Some(0));
}

#[test]
fn test_province_map_get_province_mut() {
    let mut map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    {
        let prov = map.get_province_mut(id_a).unwrap();
        prov.positions = vec![Vec2::new(1.0, 1.0), Vec2::new(2.0, 2.0)];
    }
    let prov = map.get_province(id_a).unwrap();
    assert_eq!(prov.positions.len(), 2);
    assert!((prov.positions[0].x - 1.0).abs() < 1e-5);
}

// ============================================================
// 2. PNG loader — from_image_data
// ============================================================

/// Helper: build a tiny 4x4 province image with 2 provinces + black background.
fn make_test_map() -> ProvinceMap {
    // Province A = color (1, 0, 0) = id 65536
    // Province B = color (0, 1, 0) = id 256
    // Background = black = id 0
    let w = 4u32;
    let h = 4u32;
    let mut pixels = vec![0u8; (w * h * 4) as usize];

    // Fill top-left 2x2 with province A (r=1, g=0, b=0)
    for y in 0..2u32 {
        for x in 0..2u32 {
            let idx = ((y * w + x) * 4) as usize;
            pixels[idx] = 1;
            pixels[idx + 1] = 0;
            pixels[idx + 2] = 0;
            pixels[idx + 3] = 255;
        }
    }

    // Fill top-right 2x2 with province B (r=0, g=1, b=0)
    for y in 0..2u32 {
        for x in 2..4u32 {
            let idx = ((y * w + x) * 4) as usize;
            pixels[idx] = 0;
            pixels[idx + 1] = 1;
            pixels[idx + 2] = 0;
            pixels[idx + 3] = 255;
        }
    }

    ProvinceMap::from_image_data(w, h, &pixels).unwrap()
}

#[test]
fn test_from_image_data_province_count() {
    let map = make_test_map();
    assert_eq!(map.width(), 4);
    assert_eq!(map.height(), 4);
    // Two provinces: A (id=65536) and B (id=256)
    assert_eq!(map.province_count(), 2);
}

#[test]
fn test_from_image_data_pixel_lookup() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0; // 65536
    let id_b = (0u32 << 16) | (1 << 8) | 0; // 256
    assert_eq!(map.get_province_at(0, 0), Some(id_a));
    assert_eq!(map.get_province_at(1, 1), Some(id_a));
    assert_eq!(map.get_province_at(2, 0), Some(id_b));
    assert_eq!(map.get_province_at(3, 1), Some(id_b));
    // Bottom half is black => id 0
    assert_eq!(map.get_province_at(0, 3), Some(0));
}

#[test]
fn test_from_image_data_area_calculated() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;
    assert_eq!(map.get_province(id_a).unwrap().area, 4); // 2x2
    assert_eq!(map.get_province(id_b).unwrap().area, 4); // 2x2
}

// ============================================================
// 3. Adjacency detection
// ============================================================

#[test]
fn test_detect_adjacency() {
    let mut map = make_test_map();
    detect_adjacency(&mut map);

    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;

    // A and B share a vertical border
    let neighbors = map.get_neighbors(id_a);
    assert!(neighbors.contains(&id_b));

    let edge = map.get_adjacency(id_a, id_b);
    assert!(edge.is_some());
    assert!(edge.unwrap().border_length > 0);
}

#[test]
fn test_adjacency_edge_tags() {
    let mut map = make_test_map();
    detect_adjacency(&mut map);

    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;

    // Tags start empty
    let edge = map.get_adjacency(id_a, id_b).unwrap();
    assert!(edge.tags.is_empty());

    // Add a tag via mutable access
    let edge_mut = map.get_adjacency_mut(id_a, id_b).unwrap();
    edge_mut.tags.insert("river".to_string());

    // Verify tag persists
    let edge = map.get_adjacency(id_a, id_b).unwrap();
    assert!(edge.tags.contains("river"));

    // Add another tag
    let edge_mut = map.get_adjacency_mut(id_a, id_b).unwrap();
    edge_mut.tags.insert("bridge".to_string());
    assert_eq!(map.get_adjacency(id_a, id_b).unwrap().tags.len(), 2);
}

// ============================================================
// 4. Fog of War
// ============================================================

#[test]
fn test_fog_default_hidden() {
    let fog = FogOfWar::new();
    assert_eq!(fog.get(42), FogState::Hidden);
}

#[test]
fn test_fog_set_and_get() {
    let mut fog = FogOfWar::new();
    fog.set(1, FogState::Visible);
    fog.set(2, FogState::Explored);
    assert_eq!(fog.get(1), FogState::Visible);
    assert_eq!(fog.get(2), FogState::Explored);
    assert_eq!(fog.get(3), FogState::Hidden);
}

#[test]
fn test_fog_reveal_and_hide() {
    let mut fog = FogOfWar::new();
    fog.reveal(10);
    assert_eq!(fog.get(10), FogState::Visible);
    fog.hide(10);
    assert_eq!(fog.get(10), FogState::Hidden);
}

#[test]
fn test_fog_explore() {
    let mut fog = FogOfWar::new();
    fog.explore(5);
    assert_eq!(fog.get(5), FogState::Explored);
}

#[test]
fn test_fog_reveal_radius() {
    let mut map = make_test_map();
    detect_adjacency(&mut map);

    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;

    let mut fog = FogOfWar::new();
    fog.reveal_radius(&map, id_a, 1);
    assert_eq!(fog.get(id_a), FogState::Visible);
    assert_eq!(fog.get(id_b), FogState::Visible); // neighbor within radius 1
}

// ============================================================
// 5. Map modes and colour resolution
// ============================================================

#[test]
fn test_source_color_mode() {
    let map = make_test_map();
    let mode = MapMode {
        name: "political".to_string(),
        color_fn: MapModeColorFn::SourceColor,
    };
    let props = HashMap::new();
    let buffer = resolve_colors(&map, &mode, &props);
    // Buffer should be width*height*4 bytes
    assert_eq!(buffer.len(), (map.width() * map.height() * 4) as usize);
}

#[test]
fn test_fixed_color_mode() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let mut colors = HashMap::new();
    colors.insert(id_a, [1.0f32, 0.0, 0.0, 1.0]);

    let mode = MapMode {
        name: "fixed".to_string(),
        color_fn: MapModeColorFn::Fixed(colors),
    };
    let props = HashMap::new();
    let buffer = resolve_colors(&map, &mode, &props);
    assert_eq!(buffer.len(), (map.width() * map.height() * 4) as usize);

    // Pixel (0,0) belongs to province A — should be red
    assert_eq!(buffer[0], 255); // R
    assert_eq!(buffer[1], 0);   // G
    assert_eq!(buffer[2], 0);   // B
    assert_eq!(buffer[3], 255); // A
}

#[test]
fn test_property_color_mode() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;

    // Set up properties: terrain = "land" for A, terrain = "sea" for B
    let mut province_props = HashMap::new();
    let mut props_a = ProvinceProperties::new();
    props_a.set("terrain".to_string(), ProvinceValue::Str("land".to_string()));
    province_props.insert(id_a, props_a);

    let mut props_b = ProvinceProperties::new();
    props_b.set("terrain".to_string(), ProvinceValue::Str("sea".to_string()));
    province_props.insert(id_b, props_b);

    let mut value_colors = HashMap::new();
    value_colors.insert("land".to_string(), [0.0f32, 1.0, 0.0, 1.0]); // green
    value_colors.insert("sea".to_string(), [0.0f32, 0.0, 1.0, 1.0]);  // blue

    let mode = MapMode {
        name: "terrain".to_string(),
        color_fn: MapModeColorFn::Property {
            key: "terrain".to_string(),
            value_colors,
            default_color: [0.5, 0.5, 0.5, 1.0],
        },
    };
    let buffer = resolve_colors(&map, &mode, &province_props);
    assert_eq!(buffer.len(), (map.width() * map.height() * 4) as usize);

    // Pixel (0,0) is province A with terrain=land -> green
    assert_eq!(buffer[0], 0);   // R
    assert_eq!(buffer[1], 255); // G
    assert_eq!(buffer[2], 0);   // B
    assert_eq!(buffer[3], 255); // A

    // Pixel (2,0) is province B with terrain=sea -> blue
    let px = ((0 * map.width() + 2) * 4) as usize;
    assert_eq!(buffer[px], 0);     // R
    assert_eq!(buffer[px + 1], 0); // G
    assert_eq!(buffer[px + 2], 255); // B
    assert_eq!(buffer[px + 3], 255); // A
}

// ============================================================
// 6. Pathfinding
// ============================================================

/// Build a 3-province linear map: A -- B -- C
fn make_linear_map() -> ProvinceMap {
    let w = 6u32;
    let h = 2u32;
    let mut pixels = vec![0u8; (w * h * 4) as usize];

    // Province A = (1,0,0) id=65536, columns 0-1
    // Province B = (0,1,0) id=256, columns 2-3
    // Province C = (0,0,1) id=1, columns 4-5
    for y in 0..h {
        for x in 0..w {
            let idx = ((y * w + x) * 4) as usize;
            if x < 2 {
                pixels[idx] = 1; pixels[idx + 1] = 0; pixels[idx + 2] = 0;
            } else if x < 4 {
                pixels[idx] = 0; pixels[idx + 1] = 1; pixels[idx + 2] = 0;
            } else {
                pixels[idx] = 0; pixels[idx + 1] = 0; pixels[idx + 2] = 1;
            }
            pixels[idx + 3] = 255;
        }
    }

    let mut map = ProvinceMap::from_image_data(w, h, &pixels).unwrap();
    detect_adjacency(&mut map);
    map
}

#[test]
fn test_find_path_direct_neighbors() {
    let map = make_linear_map();
    let id_a = 65536u32;
    let id_b = 256u32;
    let cost_fn = ProvinceCostFn::default();
    let props = HashMap::new();

    let path = map.find_path(id_a, id_b, &cost_fn, &props);
    assert!(path.is_some());
    let p = path.unwrap();
    assert_eq!(p.provinces.first(), Some(&id_a));
    assert_eq!(p.provinces.last(), Some(&id_b));
}

#[test]
fn test_find_path_through_intermediate() {
    let map = make_linear_map();
    let id_a = 65536u32;
    let id_c = 1u32;
    let cost_fn = ProvinceCostFn::default();
    let props = HashMap::new();

    let path = map.find_path(id_a, id_c, &cost_fn, &props);
    assert!(path.is_some());
    let p = path.unwrap();
    assert!(p.provinces.len() >= 3); // A -> B -> C
    assert_eq!(p.provinces.first(), Some(&id_a));
    assert_eq!(p.provinces.last(), Some(&id_c));
}

#[test]
fn test_find_path_same_province() {
    let map = make_linear_map();
    let cost_fn = ProvinceCostFn::default();
    let props = HashMap::new();
    let path = map.find_path(65536, 65536, &cost_fn, &props);
    assert!(path.is_some());
    let p = path.unwrap();
    assert_eq!(p.provinces, vec![65536]);
}

#[test]
fn test_reachable() {
    let map = make_linear_map();
    let cost_fn = ProvinceCostFn::default();
    let props = HashMap::new();
    let reachable = map.reachable(65536, 1.5, &cost_fn, &props);
    // Should include at least A and B (direct neighbor)
    assert!(reachable.contains(&65536));
    assert!(reachable.contains(&256));
}

#[test]
fn test_find_path_with_property_costs() {
    let map = make_linear_map();
    let id_a = 65536u32;
    let id_b = 256u32;
    let id_c = 1u32;

    // Set terrain property: B is "mountain" (expensive), C is "land" (cheap)
    let mut props = HashMap::new();
    let mut props_b = ProvinceProperties::new();
    props_b.set("terrain".to_string(), ProvinceValue::Str("mountain".to_string()));
    props.insert(id_b, props_b);

    let mut props_c = ProvinceProperties::new();
    props_c.set("terrain".to_string(), ProvinceValue::Str("land".to_string()));
    props.insert(id_c, props_c);

    // Mountain costs 5.0, land costs 1.0
    let mut terrain_costs = HashMap::new();
    terrain_costs.insert("mountain".to_string(), 5.0);
    terrain_costs.insert("land".to_string(), 1.0);

    let mut property_costs = HashMap::new();
    property_costs.insert("terrain".to_string(), terrain_costs);

    let cost_fn = ProvinceCostFn {
        property_costs,
        province_costs: HashMap::new(),
        tag_costs: HashMap::new(),
        default_cost: 1.0,
    };

    // Path A->B should exist but cost 5.0
    let path = map.find_path(id_a, id_b, &cost_fn, &props);
    assert!(path.is_some());
    let p = path.unwrap();
    assert!((p.total_cost - 5.0).abs() < 1e-5);
}

#[test]
fn test_find_path_with_tag_costs() {
    let mut map = make_linear_map();
    let id_a = 65536u32;
    let id_b = 256u32;

    // Add a "river" tag to the A-B edge
    let edge = map.get_adjacency_mut(id_a, id_b).unwrap();
    edge.tags.insert("river".to_string());

    // river crossing costs 2.0 extra
    let mut tag_costs = HashMap::new();
    tag_costs.insert("river".to_string(), 2.0);

    let cost_fn = ProvinceCostFn {
        property_costs: HashMap::new(),
        province_costs: HashMap::new(),
        tag_costs,
        default_cost: 1.0,
    };
    let props = HashMap::new();

    let path = map.find_path(id_a, id_b, &cost_fn, &props);
    assert!(path.is_some());
    // Cost should be default_cost (1.0) + river tag cost (2.0) = 3.0
    let p = path.unwrap();
    assert!((p.total_cost - 3.0).abs() < 1e-5);
}

// ============================================================
// 7. Movement
// ============================================================

#[test]
fn test_movement_manager_add_and_remove() {
    let mut mm = MovementManager::new();
    let path = ProvincePath {
        provinces: vec![1, 2, 3],
        total_cost: 3.0,
    };
    let id = mm.add_unit(path, 1.0);
    assert!(mm.get_unit(id).is_some());
    assert!(mm.remove_unit(id));
    assert!(mm.get_unit(id).is_none());
}

#[test]
fn test_movement_update() {
    let mut mm = MovementManager::new();
    let path = ProvincePath {
        provinces: vec![1, 2, 3],
        total_cost: 3.0,
    };
    let id = mm.add_unit(path, 1.0);
    mm.update_all(0.5);
    let unit = mm.get_unit(id).unwrap();
    assert!(!unit.is_finished());
}

#[test]
fn test_movement_finish() {
    let mut mm = MovementManager::new();
    let path = ProvincePath {
        provinces: vec![1, 2],
        total_cost: 1.0,
    };
    let id = mm.add_unit(path, 10.0); // very fast
    mm.update_all(1.0); // advance a lot
    let unit = mm.get_unit(id).unwrap();
    assert!(unit.is_finished());
}

// ============================================================
// 8. Properties and States
// ============================================================

#[test]
fn test_province_data_properties() {
    let mut data = ProvinceData::new();
    data.set_property(1, "population".to_string(), ProvinceValue::Int(1000));
    data.set_property(1, "income".to_string(), ProvinceValue::Float(42.5));
    data.set_property(1, "name".to_string(), ProvinceValue::Str("Paris".to_string()));
    data.set_property(1, "coastal".to_string(), ProvinceValue::Bool(true));

    assert_eq!(
        data.get_property(1, "population"),
        Some(&ProvinceValue::Int(1000))
    );
    assert_eq!(
        data.get_property(1, "name"),
        Some(&ProvinceValue::Str("Paris".to_string()))
    );
    assert!(data.get_property(1, "nonexistent").is_none());
    assert!(data.get_property(999, "population").is_none());
}

#[test]
fn test_province_properties_get_string() {
    let mut props = ProvinceProperties::new();
    props.set("terrain".to_string(), ProvinceValue::Str("forest".to_string()));
    props.set("population".to_string(), ProvinceValue::Int(500));

    assert_eq!(props.get_string("terrain"), Some("forest".to_string()));
    assert!(props.get_string("population").is_none()); // Int, not Str
    assert!(props.get_string("missing").is_none());
}

#[test]
fn test_province_data_states() {
    let mut data = ProvinceData::new();
    data.add_state(
        1,
        ProvinceState {
            name: "siege".to_string(),
            data: HashMap::new(),
            duration: Some(5.0),
            elapsed: 0.0,
        },
    );
    assert!(data.has_state(1, "siege"));
    assert!(!data.has_state(1, "famine"));

    // Update states — advance time
    data.update_states(3.0);
    assert!(data.has_state(1, "siege")); // not expired yet

    data.update_states(3.0); // total 6.0 > duration 5.0
    assert!(!data.has_state(1, "siege")); // should be expired
}

#[test]
fn test_province_data_remove_state() {
    let mut data = ProvinceData::new();
    data.add_state(
        1,
        ProvinceState {
            name: "revolt".to_string(),
            data: HashMap::new(),
            duration: None,
            elapsed: 0.0,
        },
    );
    assert!(data.has_state(1, "revolt"));
    assert!(data.remove_state(1, "revolt"));
    assert!(!data.has_state(1, "revolt"));
}

// ============================================================
// 9. Objects and Improvements
// ============================================================

#[test]
fn test_object_manager_improvements() {
    let mut om = ObjectManager::new();
    let id = om.add_improvement(1, "fort".to_string(), Vec2::new(10.0, 20.0));
    assert!(om.get_improvement(id).is_some());
    assert_eq!(om.get_improvement(id).unwrap().type_name, "fort");
    assert_eq!(om.get_improvement(id).unwrap().province_id, 1);

    let in_prov = om.improvements_in_province(1);
    assert_eq!(in_prov.len(), 1);

    assert!(om.remove_improvement(id));
    assert!(om.get_improvement(id).is_none());
}

#[test]
fn test_object_manager_objects() {
    let mut om = ObjectManager::new();
    let id = om.add_object(2, "army".to_string(), Vec2::new(5.0, 5.0));
    assert!(om.get_object(id).is_some());
    assert_eq!(om.get_object(id).unwrap().type_name, "army");

    // Move object to another province
    assert!(om.move_object(id, 3, Vec2::new(15.0, 15.0)));
    assert_eq!(om.get_object(id).unwrap().province_id, 3);

    let in_prov = om.objects_in_province(3);
    assert_eq!(in_prov.len(), 1);

    assert!(om.remove_object(id));
    assert!(om.get_object(id).is_none());
}

// ============================================================
// 10. World generation
// ============================================================

#[test]
fn test_worldgen_produces_provinces() {
    let config = WorldGenConfig {
        width: 100,
        height: 50,
        province_count: 10,
        seed: 123,
    };
    let map = generate_world(&config);
    assert_eq!(map.width(), 100);
    assert_eq!(map.height(), 50);
    assert!(map.province_count() > 0);
}

#[test]
fn test_worldgen_deterministic() {
    let config = WorldGenConfig {
        width: 60,
        height: 30,
        province_count: 8,
        seed: 42,
    };
    let map1 = generate_world(&config);
    let map2 = generate_world(&config);
    assert_eq!(map1.province_count(), map2.province_count());
    assert_eq!(map1.province_ids(), map2.province_ids());
}

// ============================================================
// 11. Borders
// ============================================================

#[test]
fn test_extract_borders() {
    let mut map = make_test_map();
    detect_adjacency(&mut map);
    let borders = extract_all_borders(&map);
    // At least one border between the two provinces
    assert!(!borders.is_empty());
}

// ============================================================
// 12. Minimap
// ============================================================

#[test]
fn test_minimap_generation() {
    let map = make_test_map();
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let id_b = (0u32 << 16) | (1 << 8) | 0;
    let mut colors = HashMap::new();
    colors.insert(id_a, [1.0f32, 0.0, 0.0, 1.0]);
    colors.insert(id_b, [0.0f32, 1.0, 0.0, 1.0]);

    let minimap = ProvinceMinimap::new(&map, &colors, 2, 2);
    assert_eq!(minimap.width(), 2);
    assert_eq!(minimap.height(), 2);
    assert_eq!(minimap.pixels().len(), 2 * 2 * 4);
}

// ============================================================
// 13. Positions
// ============================================================

#[test]
fn test_calculate_positions() {
    let mut map = make_test_map();
    calculate_all_positions(&mut map);
    let id_a = (1u32 << 16) | (0 << 8) | 0;
    let prov = map.get_province(id_a).unwrap();
    // Primary position should be near the centroid
    assert!(!prov.positions.is_empty());
    assert!((prov.positions[0].x - prov.centroid.x).abs() < 5.0);
    assert!((prov.positions[0].y - prov.centroid.y).abs() < 5.0);
}

// ============================================================
// 14. OrganizationManager
// ============================================================

#[test]
fn test_org_create_and_get() {
    let mut mgr = OrganizationManager::new();
    let id = mgr.create("Elves", "nation", true);
    let org = mgr.get(id).unwrap();
    assert_eq!(org.name, "Elves");
    assert_eq!(org.org_type, "nation");
    assert!(org.is_physical);
}

#[test]
fn test_org_assign_and_unassign_province() {
    let mut mgr = OrganizationManager::new();
    let org_id = mgr.create("Dwarves", "nation", true);
    assert!(mgr.assign_province(org_id, 1));
    assert!(mgr.assign_province(org_id, 2));
    assert_eq!(mgr.orgs_in_province(1), vec![org_id]);
    assert!(mgr.unassign_province(org_id, 1));
    assert!(mgr.orgs_in_province(1).is_empty());
    assert_eq!(mgr.provinces_of_org(org_id), vec![2]);
}

#[test]
fn test_org_remove() {
    let mut mgr = OrganizationManager::new();
    let id = mgr.create("Goblins", "tribe", true);
    mgr.assign_province(id, 10);
    assert!(mgr.remove(id));
    assert!(mgr.get(id).is_none());
    assert!(mgr.orgs_in_province(10).is_empty());
    assert!(!mgr.remove(id)); // second remove returns false
}

#[test]
fn test_org_primary() {
    let mut mgr = OrganizationManager::new();
    // Two physical orgs share the same province — lower ID is primary
    let id_a = mgr.create("A", "nation", true);
    let id_b = mgr.create("B", "nation", true);
    mgr.assign_province(id_a, 42);
    mgr.assign_province(id_b, 42);
    let primary = mgr.primary_org(42).unwrap();
    assert_eq!(primary, id_a.min(id_b));
}

#[test]
fn test_org_set_capital() {
    let mut mgr = OrganizationManager::new();
    let id = mgr.create("Empire", "nation", true);
    mgr.assign_province(id, 7);
    assert!(mgr.set_capital(id, 7));
    assert_eq!(mgr.get(id).unwrap().capital_province, Some(7));
    // Setting to a province not owned returns false
    assert!(!mgr.set_capital(id, 99));
}

#[test]
fn test_org_property() {
    let mut mgr = OrganizationManager::new();
    let id = mgr.create("Traders", "guild", false);
    mgr.set_property(id, "gold".to_string(), ProvinceValue::Int(100));
    assert_eq!(mgr.get_property(id, "gold"), Some(&ProvinceValue::Int(100)));
    assert_eq!(mgr.get_property(id, "missing"), None);
}

// ============================================================
// 15. RelationManager
// ============================================================

#[test]
fn test_relation_define_type() {
    let mut mgr = RelationManager::new();
    mgr.define_type(
        "military",
        vec!["war".to_string(), "neutral".to_string(), "alliance".to_string()],
        "neutral",
    );
    let rt = mgr.get_type("military").unwrap();
    assert!(rt.has_level("war"));
    assert!(rt.has_level("alliance"));
    assert!(!rt.has_level("embargo"));
}

#[test]
fn test_relation_remove_type() {
    let mut mgr = RelationManager::new();
    mgr.define_type("trade", vec!["open".to_string()], "open");
    assert!(mgr.remove_type("trade"));
    assert!(mgr.get_type("trade").is_none());
    assert!(!mgr.remove_type("trade")); // second remove returns false
}

#[test]
fn test_relation_value_set_and_get() {
    let mut mgr = RelationManager::new();
    mgr.set_value(1, 2, 75.0);
    assert!((mgr.get_value(1, 2) - 75.0).abs() < 1e-5);
    // Symmetric
    assert!((mgr.get_value(2, 1) - 75.0).abs() < 1e-5);
}

#[test]
fn test_relation_adjust_value() {
    let mut mgr = RelationManager::new();
    mgr.set_value(1, 2, 50.0);
    mgr.adjust_value(1, 2, -20.0);
    assert!((mgr.get_value(1, 2) - 30.0).abs() < 1e-5);
}

#[test]
fn test_relation_level_set_and_get() {
    let mut mgr = RelationManager::new();
    mgr.define_type(
        "diplomatic",
        vec!["hostile".to_string(), "neutral".to_string(), "friendly".to_string()],
        "neutral",
    );
    assert!(mgr.set_level(1, 2, "diplomatic", "friendly"));
    assert_eq!(mgr.get_level(1, 2, "diplomatic"), Some("friendly".to_string()));
    // Default returned when no explicit level set for a second pair
    assert_eq!(mgr.get_level(3, 4, "diplomatic"), Some("neutral".to_string()));
}

#[test]
fn test_relation_level_invalid_rejected() {
    let mut mgr = RelationManager::new();
    mgr.define_type("military", vec!["peace".to_string()], "peace");
    assert!(!mgr.set_level(1, 2, "military", "invalid_level"));
}

#[test]
fn test_relation_all_relations_for() {
    let mut mgr = RelationManager::new();
    mgr.set_value(1, 2, 10.0);
    mgr.set_value(1, 3, 20.0);
    mgr.set_value(4, 5, 30.0);
    let rels = mgr.all_relations_for(1);
    // Org 1 appears in relation with 2 and 3 — both should be returned
    assert_eq!(rels.len(), 2);
}

// ============================================================
// 16. ProvinceEventBus
// ============================================================

#[test]
fn test_event_emit_and_poll() {
    let mut bus = ProvinceEventBus::new();
    bus.emit_property_changed(1, "terrain", "mountain");
    let ev = bus.poll().unwrap();
    assert_eq!(ev.name, "property_changed");
    assert!(bus.poll().is_none());
}

#[test]
fn test_event_drain() {
    let mut bus = ProvinceEventBus::new();
    bus.emit_property_changed(1, "terrain", "forest");
    bus.emit_object_added(2, 99, "building");
    let events = bus.drain();
    assert_eq!(events.len(), 2);
    assert!(bus.is_empty());
}

#[test]
fn test_event_advance_turn() {
    let mut bus = ProvinceEventBus::new();
    assert_eq!(bus.turn(), 0);
    assert_eq!(bus.advance_turn(), 1);
    assert_eq!(bus.advance_turn(), 2);
    assert_eq!(bus.turn(), 2);
    // advance_turn emits a turn_changed event each time
    let events = bus.drain();
    assert_eq!(events.len(), 2);
    assert_eq!(events[0].name, "turn_changed");
}

#[test]
fn test_event_org_assigned() {
    let mut bus = ProvinceEventBus::new();
    bus.emit_org_assigned(7, 42);
    let ev = bus.poll().unwrap();
    assert_eq!(ev.name, "org_assigned");
    // Args: province_id, org_id
    use luna2d::event::EventArg;
    assert!(matches!(&ev.args[0], EventArg::Num(n) if (*n as u32) == 7));
    assert!(matches!(&ev.args[1], EventArg::Num(n) if (*n as u64) == 42));
}

#[test]
fn test_event_custom_emit() {
    use luna2d::event::EventArg;
    let mut bus = ProvinceEventBus::new();
    bus.emit_custom("my_event", vec![EventArg::Str("hello".into()), EventArg::Num(3.0)]);
    let ev = bus.poll().unwrap();
    assert_eq!(ev.name, "my_event");
    assert_eq!(ev.args.len(), 2);
}

#[test]
fn test_event_relation_value_changed() {
    let mut bus = ProvinceEventBus::new();
    bus.emit_relation_value_changed(10, 20, -15.0);
    let ev = bus.poll().unwrap();
    assert_eq!(ev.name, "relation_value_changed");
}
