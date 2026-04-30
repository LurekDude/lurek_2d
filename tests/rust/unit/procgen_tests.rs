//! Tests for the procgen module.

use lurek2d::procgen::*;

// ── heightmap ─────────────────────────────────────────────────────────

mod heightmap_tests {
    use super::*;

    #[test]
    fn default_dimensions() {
        let hm = Heightmap::generate(&HeightmapOpts::default());
        assert_eq!(hm.width, 64);
        assert_eq!(hm.height, 64);
        assert_eq!(hm.cells.len(), 64 * 64);
    }

    #[test]
    fn values_normalised_to_unit() {
        let hm = Heightmap::generate(&HeightmapOpts::default());
        for &v in &hm.cells {
            assert!(v >= 0.0 && v <= 1.0, "elevation out of [0,1]: {v}");
        }
    }

    #[test]
    fn get_clamps_oob() {
        let hm = Heightmap::generate(&HeightmapOpts {
            width: 4,
            height: 4,
            ..Default::default()
        });
        let _ = hm.get(100, 100); // should not panic
    }

    #[test]
    fn erosion_keeps_normalised() {
        let hm = Heightmap::generate(&HeightmapOpts {
            erosion_passes: 3,
            ..Default::default()
        });
        for &v in &hm.cells {
            assert!(v >= 0.0 && v <= 1.0, "post-erosion value out of [0,1]: {v}");
        }
    }

    #[test]
    fn to_rgba_bytes_length() {
        let hm = Heightmap::generate(&HeightmapOpts {
            width: 4,
            height: 4,
            ..Default::default()
        });
        assert_eq!(hm.to_rgba_bytes().len(), 4 * 4 * 4);
    }
}

// ── cellular ──────────────────────────────────────────────────────────

// ── bsp ───────────────────────────────────────────────────────────────

mod bsp_tests {
    use super::*;

    #[test]
    fn default_opts_produce_rooms() {
        let d = bsp_dungeon(&BspOpts::default());
        assert!(!d.rooms.is_empty(), "BSP should produce at least one room");
    }

    #[test]
    fn deterministic_with_same_seed() {
        let a = bsp_dungeon(&BspOpts::default());
        let b = bsp_dungeon(&BspOpts::default());
        assert_eq!(a.rooms.len(), b.rooms.len());
        assert_eq!(a.corridors.len(), b.corridors.len());
    }

    #[test]
    fn rooms_within_bounds() {
        let opts = BspOpts {
            width: 32,
            height: 32,
            ..Default::default()
        };
        let d = bsp_dungeon(&opts);
        for r in &d.rooms {
            assert!(r.x + r.w <= opts.width, "room exceeds width");
            assert!(r.y + r.h <= opts.height, "room exceeds height");
        }
    }

    #[test]
    fn corridors_connect_rooms() {
        let d = bsp_dungeon(&BspOpts::default());
        if d.rooms.len() > 1 {
            assert!(!d.corridors.is_empty(), "multiple rooms need corridors");
        }
    }
}

// ── lsystem ───────────────────────────────────────────────────────────

mod lsystem_tests {
    use super::*;

    #[test]
    fn generate_applies_rules() {
        let ls = LSystem::new("A", vec![('A', "AB"), ('B', "A")], 3);
        // A -> AB -> ABA -> ABAAB
        assert_eq!(ls.generate(), "ABAAB");
    }

    #[test]
    fn generate_zero_iterations_returns_axiom() {
        let ls = LSystem::new("ABC", vec![('A', "X")], 0);
        assert_eq!(ls.generate(), "ABC");
    }

    #[test]
    fn unknown_symbols_pass_through() {
        let ls = LSystem::new("AXB", vec![('A', "C")], 1);
        assert_eq!(ls.generate(), "CXB");
    }

    #[test]
    fn to_segments_produces_lines() {
        // Simple: F -> FF, one iteration, straight line
        let ls = LSystem::new("F", vec![('F', "FF")], 1);
        let segs = ls.to_segments(90.0, 1.0);
        assert_eq!(segs.len(), 2);
    }

    #[test]
    fn branching_with_brackets() {
        let ls = LSystem::new("F[+F]F", vec![], 0);
        let segs = ls.to_segments(90.0, 1.0);
        // F draws 1, [+F] draws 1 (branched), F draws 1 = 3 segments
        assert_eq!(segs.len(), 3);
    }
}

// ── world_graph ───────────────────────────────────────────────────────

mod world_graph_tests {
    use super::*;

    #[test]
    fn add_region_returns_sequential_ids() {
        let mut g = WorldGraph::new();
        assert_eq!(g.add_region("A", 0.0, 0.0), 0);
        assert_eq!(g.add_region("B", 1.0, 0.0), 1);
        assert_eq!(g.regions.len(), 2);
    }

    #[test]
    fn find_path_trivial() {
        let mut g = WorldGraph::new();
        let a = g.add_region("A", 0.0, 0.0);
        assert_eq!(g.find_path(a, a), Some(vec![a]));
    }

    #[test]
    fn find_path_two_nodes() {
        let mut g = WorldGraph::new();
        let a = g.add_region("A", 0.0, 0.0);
        let b = g.add_region("B", 1.0, 0.0);
        g.add_edge(a, b, 1.0, true);
        assert_eq!(g.find_path(a, b), Some(vec![a, b]));
    }

    #[test]
    fn find_path_unreachable() {
        let mut g = WorldGraph::new();
        let a = g.add_region("A", 0.0, 0.0);
        let b = g.add_region("B", 5.0, 5.0);
        assert_eq!(g.find_path(a, b), None);
    }

    #[test]
    fn reachable_from_respects_cost() {
        let mut g = WorldGraph::new();
        let a = g.add_region("A", 0.0, 0.0);
        let b = g.add_region("B", 1.0, 0.0);
        let c = g.add_region("C", 5.0, 0.0);
        g.add_edge(a, b, 1.0, true);
        g.add_edge(b, c, 10.0, true);
        let r = g.reachable_from(a, 2.0);
        assert!(r.contains(&a));
        assert!(r.contains(&b));
        assert!(!r.contains(&c));
    }

    #[test]
    fn mst_connects_all() {
        let mut g = WorldGraph::new();
        let a = g.add_region("A", 0.0, 0.0);
        let b = g.add_region("B", 1.0, 0.0);
        let c = g.add_region("C", 0.0, 1.0);
        g.add_edge(a, b, 1.0, true);
        g.add_edge(b, c, 2.0, true);
        g.add_edge(a, c, 3.0, true);
        let mst = g.mst();
        assert_eq!(mst.len(), 2); // N-1 edges for N=3 nodes
    }

    #[test]
    fn generate_world_graph_creates_regions() {
        let g = generate_world_graph(100.0, 100.0, 10, 42);
        assert_eq!(g.regions.len(), 10);
        assert!(!g.edges.is_empty());
    }
}

// ── wfc ───────────────────────────────────────────────────────────────

mod wfc_tests {
    use super::*;

    #[test]
    fn empty_tiles_return_none_grid() {
        let opts = WfcOpts {
            width: 4,
            height: 4,
            tiles: vec![],
            rules: WfcRules::default(),
            seed: 0,
            max_attempts: 1,
        };
        let grid = wfc_generate(&opts);
        assert!(grid.cells.iter().all(|c| c.is_none()));
    }

    #[test]
    fn single_tile_fills_grid() {
        let mut rules = WfcRules::default();
        rules.adjacencies.insert(1, vec![1]);
        let opts = WfcOpts {
            width: 3,
            height: 3,
            tiles: vec![WfcTile { id: 1, weight: 1.0 }],
            rules,
            seed: 42,
            max_attempts: 5,
        };
        let grid = wfc_generate(&opts);
        assert!(grid.cells.iter().all(|c| *c == Some(1)));
    }

    #[test]
    fn zero_size_grid() {
        let opts = WfcOpts {
            width: 0,
            height: 0,
            tiles: vec![WfcTile { id: 1, weight: 1.0 }],
            rules: WfcRules::default(),
            seed: 0,
            max_attempts: 1,
        };
        let grid = wfc_generate(&opts);
        assert!(grid.cells.is_empty());
    }

    #[test]
    fn deterministic_same_seed() {
        let mut rules = WfcRules::default();
        rules.adjacencies.insert(1, vec![1, 2]);
        rules.adjacencies.insert(2, vec![1, 2]);
        let opts = WfcOpts {
            width: 4,
            height: 4,
            tiles: vec![
                WfcTile { id: 1, weight: 1.0 },
                WfcTile { id: 2, weight: 1.0 },
            ],
            rules,
            seed: 99,
            max_attempts: 5,
        };
        let a = wfc_generate(&opts);
        let b = wfc_generate(&opts);
        assert_eq!(a.cells, b.cells);
    }
}

// ── rooms ─────────────────────────────────────────────────────────────

mod rooms_tests {
    use super::*;

    #[test]
    fn default_opts_produce_rooms() {
        let d = rooms_dungeon(&RoomsOpts::default());
        assert!(!d.rooms.is_empty(), "should place at least one room");
    }

    #[test]
    fn grid_size_matches_opts() {
        let opts = RoomsOpts {
            width: 32,
            height: 24,
            ..Default::default()
        };
        let d = rooms_dungeon(&opts);
        assert_eq!(d.grid.len(), (32 * 24) as usize);
    }

    #[test]
    fn rooms_within_bounds() {
        let opts = RoomsOpts::default();
        let d = rooms_dungeon(&opts);
        for r in &d.rooms {
            assert!(r.x + r.w <= opts.width);
            assert!(r.y + r.h <= opts.height);
        }
    }

    #[test]
    fn deterministic_same_seed() {
        let a = rooms_dungeon(&RoomsOpts::default());
        let b = rooms_dungeon(&RoomsOpts::default());
        assert_eq!(a.rooms.len(), b.rooms.len());
        assert_eq!(a.grid, b.grid);
    }

    #[test]
    fn grid_contains_floor_cells() {
        let d = rooms_dungeon(&RoomsOpts::default());
        assert!(d.grid.contains(&1), "grid should contain floor cells");
    }
}

// ── render (NoiseGrid) ───────────────────────────────────────────────

mod render_tests {
    use super::*;

    #[test]
    fn to_rgba_bytes_length() {
        let grid = NoiseGrid::from_perlin(4, 4, 0.1);
        assert_eq!(grid.to_rgba_bytes().len(), 4 * 4 * 4);
    }

    #[test]
    fn empty_grid_to_rgba_empty() {
        let grid = NoiseGrid {
            width: 0,
            height: 0,
            cells: Vec::new(),
        };
        assert!(grid.to_rgba_bytes().is_empty());
    }

    #[test]
    fn generate_render_commands_count() {
        let grid = NoiseGrid::from_perlin(4, 4, 0.1);
        // 16 cells × 2 commands each (SetColor + Rectangle)
        assert_eq!(grid.generate_render_commands(8.0).len(), 32);
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let grid = NoiseGrid::from_perlin(8, 6, 0.1);
        let img = grid.draw_to_image();
        assert_eq!(img.width(), 8);
        assert_eq!(img.height(), 6);
    }

    #[test]
    fn empty_grid_returns_no_commands() {
        let grid = NoiseGrid {
            width: 0,
            height: 0,
            cells: Vec::new(),
        };
        assert!(grid.generate_render_commands(8.0).is_empty());
    }
}

// ── noise (from sibling noise_tests.rs) ──────────────────────────────

mod noise_tests {
    use lurek2d::procgen::noise::*;

    // ── Standalone free functions ──────────────────────────────────────

    #[test]
    fn perlin2d_deterministic() {
        let a = perlin2d(1.5, 2.3, 42);
        let b = perlin2d(1.5, 2.3, 42);
        assert_eq!(a, b);
    }

    #[test]
    fn perlin2d_different_seeds_differ() {
        let a = perlin2d(1.5, 2.3, 0);
        let b = perlin2d(1.5, 2.3, 999);
        assert_ne!(a, b);
    }

    #[test]
    fn perlin2d_value_range() {
        for i in 0..100 {
            let v = perlin2d(i as f32 * 0.37, i as f32 * 0.53, 0);
            assert!(v >= -1.5 && v <= 1.5, "perlin2d out of expected range: {v}");
        }
    }

    #[test]
    fn simplex2d_deterministic() {
        let a = simplex2d(3.1, 4.7, 10);
        let b = simplex2d(3.1, 4.7, 10);
        assert_eq!(a, b);
    }

    #[test]
    fn simplex2d_value_range() {
        for i in 0..100 {
            let v = simplex2d(i as f32 * 0.41, i as f32 * 0.59, 0);
            assert!(
                v >= -1.5 && v <= 1.5,
                "simplex2d out of expected range: {v}"
            );
        }
    }

    #[test]
    fn simplex_noise_2d_uses_seed_zero() {
        let a = simplex_noise_2d(1.0, 2.0);
        let b = simplex2d(1.0, 2.0, 0);
        assert_eq!(a, b);
    }

    #[test]
    fn simplex_noise_3d_returns_finite() {
        let v = simplex_noise_3d(1.0, 2.0, 3.0);
        assert!(v.is_finite());
    }

    #[test]
    fn perlin3d_deterministic() {
        let a = perlin3d(0.5, 1.5, 2.5, 7);
        let b = perlin3d(0.5, 1.5, 2.5, 7);
        assert_eq!(a, b);
    }

    #[test]
    fn perlin4d_deterministic() {
        let a = perlin4d(0.1, 0.2, 0.3, 0.4, 5);
        let b = perlin4d(0.1, 0.2, 0.3, 0.4, 5);
        assert_eq!(a, b);
    }

    #[test]
    fn fbm_deterministic_and_finite() {
        let a = fbm(1.0, 2.0, 0, 4, 2.0, 0.5);
        let b = fbm(1.0, 2.0, 0, 4, 2.0, 0.5);
        assert_eq!(a, b);
        assert!(a.is_finite());
    }

    #[test]
    fn fbm_zero_octaves() {
        let v = fbm(1.0, 2.0, 0, 0, 2.0, 0.5);
        assert_eq!(v, 0.0);
    }

    // ── NoiseGenerator ─────────────────────────────────────────────────

    #[test]
    fn noise_generator_deterministic_seed() {
        let a = NoiseGenerator::new(42);
        let b = NoiseGenerator::new(42);
        assert_eq!(a.perlin_2d(1.0, 2.0), b.perlin_2d(1.0, 2.0));
    }

    #[test]
    fn noise_generator_different_seeds_differ() {
        let a = NoiseGenerator::new(0);
        let b = NoiseGenerator::new(99);
        assert_ne!(a.perlin_2d(1.25, 2.5), b.perlin_2d(1.25, 2.5));
    }

    #[test]
    fn noise_generator_seed_getter() {
        let g = NoiseGenerator::new(123);
        assert_eq!(g.seed(), 123);
    }

    #[test]
    fn noise_generator_set_seed() {
        let mut g = NoiseGenerator::new(0);
        g.set_seed(99);
        assert_eq!(g.seed(), 99);
        let fresh = NoiseGenerator::new(99);
        assert_eq!(g.perlin_2d(3.0, 4.0), fresh.perlin_2d(3.0, 4.0));
    }

    #[test]
    fn perlin_1d_range() {
        let g = NoiseGenerator::new(0);
        for i in 0..200 {
            let v = g.perlin_1d(i as f64 * 0.13);
            assert!(v >= -1.5 && v <= 1.5, "perlin_1d out of range: {v}");
        }
    }

    #[test]
    fn perlin_2d_range() {
        let g = NoiseGenerator::new(0);
        for i in 0..100 {
            let v = g.perlin_2d(i as f64 * 0.37, i as f64 * 0.53);
            assert!(v >= -1.5 && v <= 1.5, "perlin_2d out of range: {v}");
        }
    }

    #[test]
    fn perlin_3d_range() {
        let g = NoiseGenerator::new(0);
        for i in 0..100 {
            let v = g.perlin_3d(i as f64 * 0.3, i as f64 * 0.5, i as f64 * 0.7);
            assert!(v >= -1.5 && v <= 1.5, "perlin_3d out of range: {v}");
        }
    }

    #[test]
    fn simplex_2d_generator_range() {
        let g = NoiseGenerator::new(0);
        for i in 0..100 {
            let v = g.simplex_2d(i as f64 * 0.41, i as f64 * 0.59);
            assert!(v.is_finite(), "simplex_2d not finite at i={i}");
        }
    }

    #[test]
    fn simplex_3d_generator_range() {
        let g = NoiseGenerator::new(0);
        for i in 0..50 {
            let v = g.simplex_3d(i as f64 * 0.3, i as f64 * 0.5, i as f64 * 0.7);
            assert!(v.is_finite(), "simplex_3d not finite at i={i}");
        }
    }

    #[test]
    fn simplex_4d_finite() {
        let g = NoiseGenerator::new(42);
        let v = g.simplex_4d(1.0, 2.0, 3.0, 4.0);
        assert!(v.is_finite());
    }

    #[test]
    fn worley_2d_euclidean_non_negative() {
        let g = NoiseGenerator::new(0);
        for i in 0..50 {
            let v = g.worley_2d(i as f64 * 0.5, i as f64 * 0.3, DistType::Euclidean, false);
            assert!(v >= 0.0, "worley_2d distance should be non-negative: {v}");
        }
    }

    #[test]
    fn worley_2d_f2_minus_f1() {
        let g = NoiseGenerator::new(0);
        let v = g.worley_2d(1.5, 2.5, DistType::Euclidean, true);
        assert!(v >= 0.0, "F2-F1 should be non-negative: {v}");
    }

    #[test]
    fn worley_2d_manhattan() {
        let g = NoiseGenerator::new(0);
        let v = g.worley_2d(1.5, 2.5, DistType::Manhattan, false);
        assert!(v >= 0.0);
    }

    #[test]
    fn worley_2d_chebyshev() {
        let g = NoiseGenerator::new(0);
        let v = g.worley_2d(1.5, 2.5, DistType::Chebyshev, false);
        assert!(v >= 0.0);
    }

    #[test]
    fn worley_3d_finite() {
        let g = NoiseGenerator::new(0);
        let v = g.worley_3d(1.0, 2.0, 3.0, DistType::Euclidean, false);
        assert!(v.is_finite() && v >= 0.0);
    }

    #[test]
    fn fbm_generator_finite() {
        let g = NoiseGenerator::new(0);
        let v = g.fbm(1.0, 2.0, 4, 2.0, 0.5, NoiseKind::Perlin);
        assert!(v.is_finite());
    }

    #[test]
    fn ridged_finite() {
        let g = NoiseGenerator::new(0);
        let v = g.ridged(1.0, 2.0, 4, 2.0, 0.5, NoiseKind::Simplex);
        assert!(v.is_finite());
    }

    #[test]
    fn turbulence_finite() {
        let g = NoiseGenerator::new(0);
        let v = g.turbulence(1.0, 2.0, 4, 2.0, 0.5, NoiseKind::Perlin);
        assert!(v.is_finite());
    }

    #[test]
    fn warp_domain_returns_finite() {
        let g = NoiseGenerator::new(0);
        let (wx, wy) = g.warp_domain(1.0, 2.0, 0.5);
        assert!(wx.is_finite() && wy.is_finite());
    }

    #[test]
    fn generate_map_correct_length() {
        let g = NoiseGenerator::new(0);
        let map = g.generate_map(8, 6, &MapGenOptions::default());
        assert_eq!(map.len(), 48);
        assert!(map.iter().all(|v| v.is_finite()));
    }

    #[test]
    fn generate_map_ridged_mode() {
        let g = NoiseGenerator::new(0);
        let opts = MapGenOptions {
            fractal: FractalType::Ridged,
            ..Default::default()
        };
        let map = g.generate_map(4, 4, &opts);
        assert_eq!(map.len(), 16);
        assert!(map.iter().all(|v| v.is_finite()));
    }

    #[test]
    fn generate_map_turbulence_mode() {
        let g = NoiseGenerator::new(0);
        let opts = MapGenOptions {
            fractal: FractalType::Turbulence,
            ..Default::default()
        };
        let map = g.generate_map(4, 4, &opts);
        assert_eq!(map.len(), 16);
    }

    // ── Parallel map generation ────────────────────────────────────────

    #[test]
    fn parallel_map_correct_length() {
        let map = generate_noise_map_parallel(8, 6, &MapGenOptions::default());
        assert_eq!(map.len(), 48);
        assert!(map.iter().all(|v| v.is_finite()));
    }

    #[test]
    fn parallel_map_ridged() {
        let opts = MapGenOptions {
            fractal: FractalType::Ridged,
            ..Default::default()
        };
        let map = generate_noise_map_parallel(4, 4, &opts);
        assert_eq!(map.len(), 16);
    }

    #[test]
    fn parallel_map_turbulence() {
        let opts = MapGenOptions {
            fractal: FractalType::Turbulence,
            ..Default::default()
        };
        let map = generate_noise_map_parallel(4, 4, &opts);
        assert_eq!(map.len(), 16);
    }
}

// ── namegen ───────────────────────────────────────────────────────────

mod namegen_tests {
    use super::*;

    #[test]
    fn generates_non_empty_name() {
        let mut gen = NameGen::new(&["alice", "bob", "charlie", "david"], 2, 42);
        let name = gen.generate(2, 8);
        assert!(!name.is_empty(), "should generate at least one name");
    }

    #[test]
    fn respects_max_length() {
        let mut gen = NameGen::new(&["alexander", "benjamin", "christopher"], 2, 0);
        let name = gen.generate(1, 5);
        assert!(name.len() <= 5, "name '{}' exceeds max_len 5", name);
    }

    #[test]
    fn capitalises_first_letter() {
        let mut gen = NameGen::new(&["anna", "amy", "alex"], 2, 99);
        let name = gen.generate(1, 10);
        if !name.is_empty() {
            assert!(name.chars().next().unwrap().is_uppercase());
        }
    }

    #[test]
    fn generate_n_returns_correct_count() {
        let mut gen = NameGen::new(&["foo", "bar", "baz", "qux"], 2, 7);
        let names = gen.generate_n(3, 2, 6);
        assert_eq!(names.len(), 3);
    }

    #[test]
    fn deterministic_same_seed() {
        let mut a = NameGen::new(&["test", "name"], 2, 42);
        let mut b = NameGen::new(&["test", "name"], 2, 42);
        assert_eq!(a.generate(1, 10), b.generate(1, 10));
    }
}
