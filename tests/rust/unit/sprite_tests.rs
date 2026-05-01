//! INTERNAL ONLY: public `lurek.sprite.*` behavior is covered primarily by the Lua-first suite
//! in `tests/lua/unit/test_sprite_unit.lua`.
//!
//! This Rust file keeps only helper-level coverage that is either not asserted
//! through the Lua surface or is still more precise to check directly here.

use lurek2d::math::{Color, Vec2};
use lurek2d::runtime::resource_keys::TextureKey;
use lurek2d::sprite::sprite_batch::BatchEntry;
use lurek2d::sprite::sprite_sheet::DirectionLayout;
use lurek2d::sprite::*;
use slotmap::KeyData;

fn dummy_key() -> TextureKey {
    TextureKey::from(KeyData::from_ffi(1))
}

// ── sprite ────────────────────────────────────────────────────────────────────

mod sprite_tests {
    use super::*;

    #[test]
    fn new_sprite_defaults() {
        let s = Sprite::new(42, Vec2::new(10.0, 20.0));
        assert_eq!(s.texture_id, 42);
        assert!((s.position.x - 10.0).abs() < 1e-5);
        assert!((s.position.y - 20.0).abs() < 1e-5);
        assert!((s.scale.x - 1.0).abs() < 1e-5);
        assert!((s.scale.y - 1.0).abs() < 1e-5);
        assert!((s.rotation).abs() < 1e-5);
        assert_eq!(s.color, Color::WHITE);
    }

    #[test]
    fn set_position_updates_vec2() {
        let mut s = Sprite::new(0, Vec2::ZERO);
        s.set_position(100.0, 200.0);
        assert!((s.position.x - 100.0).abs() < 1e-5);
        assert!((s.position.y - 200.0).abs() < 1e-5);
    }

    #[test]
    fn set_scale_replaces_value() {
        let mut s = Sprite::new(0, Vec2::ZERO);
        s.set_scale(2.0, 3.0);
        assert!((s.scale.x - 2.0).abs() < 1e-5);
        assert!((s.scale.y - 3.0).abs() < 1e-5);
    }

    #[test]
    fn set_rotation_stores_radians() {
        let mut s = Sprite::new(0, Vec2::ZERO);
        s.set_rotation(std::f32::consts::PI);
        assert!((s.rotation - std::f32::consts::PI).abs() < 1e-5);
    }

    #[test]
    fn set_color_applies_tint() {
        let mut s = Sprite::new(0, Vec2::ZERO);
        let red = Color::new(1.0, 0.0, 0.0, 1.0);
        s.set_color(red);
        assert!((s.color.r - 1.0).abs() < 1e-5);
        assert!((s.color.g).abs() < 1e-5);
    }
}

// ── sprite_batch ──────────────────────────────────────────────────────────────

mod sprite_batch_tests {
    use super::*;

    fn make_entry(x: f32, y: f32) -> BatchEntry {
        BatchEntry {
            x,
            y,
            quad_x: 0.0,
            quad_y: 0.0,
            quad_w: 32.0,
            quad_h: 32.0,
            rotation: 0.0,
            sx: 1.0,
            sy: 1.0,
            ox: 0.0,
            oy: 0.0,
        }
    }

    #[test]
    fn new_batch_starts_empty() {
        let batch = SpriteBatch::new(dummy_key(), 0);
        assert!(batch.is_empty());
        assert_eq!(batch.len(), 0);
    }

    #[test]
    fn add_returns_index() {
        let mut batch = SpriteBatch::new(dummy_key(), 0);
        let idx = batch.add(make_entry(10.0, 20.0));
        assert_eq!(idx, Some(0));
        assert_eq!(batch.len(), 1);
    }

    #[test]
    fn add_respects_max_entries() {
        let mut batch = SpriteBatch::new(dummy_key(), 2);
        assert!(batch.add(make_entry(0.0, 0.0)).is_some());
        assert!(batch.add(make_entry(0.0, 0.0)).is_some());
        assert!(batch.add(make_entry(0.0, 0.0)).is_none());
    }

    #[test]
    fn clear_empties_batch() {
        let mut batch = SpriteBatch::new(dummy_key(), 0);
        batch.add(make_entry(0.0, 0.0));
        batch.clear();
        assert!(batch.is_empty());
    }

    #[test]
    fn texture_key_matches_construction() {
        let key = dummy_key();
        let batch = SpriteBatch::new(key, 0);
        assert_eq!(batch.texture_key(), key);
    }

    #[test]
    fn buffer_size_zero_means_unlimited() {
        let mut batch = SpriteBatch::new(dummy_key(), 0);
        for _ in 0..300 {
            assert!(batch.add(make_entry(0.0, 0.0)).is_some());
        }
        assert_eq!(batch.buffer_size(), 0);
    }
}

// ── sprite_sheet ──────────────────────────────────────────────────────────────

mod sprite_sheet_tests {
    use super::*;

    #[test]
    fn get_frame_out_of_range_returns_none() {
        let sheet = SpriteSheet::new(32, 32, 32, 32);
        assert!(sheet.get_frame(5).is_none());
    }

    #[test]
    fn get_range_clamps_to_bounds() {
        let sheet = SpriteSheet::new(64, 32, 32, 32);
        let range = sheet.get_range(1, 100);
        assert_eq!(range.len(), 1); // only frame index 1 exists
    }

    #[test]
    fn direction_frames_rows_layout() {
        let mut sheet = SpriteSheet::new(96, 128, 32, 32);
        sheet.set_directions(4, DirectionLayout::Rows);
        let frames = sheet.get_direction_frames(0).unwrap();
        assert_eq!(frames.len(), 3);
        assert!(sheet.get_direction_frames(10).is_none());
    }

    #[test]
    fn zero_frame_size_yields_empty_sheet() {
        let sheet = SpriteSheet::new(128, 128, 0, 0);
        assert_eq!(sheet.get_frame_count(), 0);
    }
}

// ── nine_slice ────────────────────────────────────────────────────────────────

mod nine_slice_tests {
    use super::*;

    #[test]
    fn patches_corners_preserve_size() {
        let ns = NineSlice::new(dummy_key(), 10.0, 10.0, 10.0, 10.0, 100.0, 100.0);
        let p = ns.patches(0.0, 0.0, 200.0, 200.0);
        // Top-left corner: dst_w = left (10), dst_h = top (10)
        assert!((p[0].6 - 10.0).abs() < 1e-5);
        assert!((p[0].7 - 10.0).abs() < 1e-5);
        // Top-right corner: dst_w = right (10)
        assert!((p[2].6 - 10.0).abs() < 1e-5);
    }

    #[test]
    fn patches_center_stretches() {
        let ns = NineSlice::new(dummy_key(), 10.0, 10.0, 10.0, 10.0, 100.0, 100.0);
        let p = ns.patches(0.0, 0.0, 200.0, 200.0);
        // Center patch: dst_w = 200 - 10 - 10 = 180, dst_h = 180
        assert!((p[4].6 - 180.0).abs() < 1e-5);
        assert!((p[4].7 - 180.0).abs() < 1e-5);
    }

    #[test]
    fn patches_small_destination_clamps_center() {
        let ns = NineSlice::new(dummy_key(), 10.0, 10.0, 10.0, 10.0, 100.0, 100.0);
        // Destination smaller than combined insets
        let p = ns.patches(0.0, 0.0, 15.0, 15.0);
        // Center width clamps to 0
        assert!(p[4].6 >= 0.0);
    }
}

// ── atlas ─────────────────────────────────────────────────────────────────────

mod atlas_tests {
    use super::*;

    #[test]
    fn atlas_hash_format_parses_correctly() {
        let json =
            r#"{"frames":{"hero.png":{"frame":{"x":0,"y":0,"w":32,"h":32},"rotated":false}}}"#;
        let atlas = parse_texturepacker_json(json).unwrap();
        assert_eq!(atlas.entry_count(), 1);
        let entry = atlas.get_entry("hero.png").unwrap();
        assert_eq!(entry.x, 0);
        assert_eq!(entry.w, 32);
        assert!(!entry.rotated);
    }

    #[test]
    fn atlas_array_format_parses_correctly() {
        let json = r#"{"frames":[{"filename":"bullet.png","frame":{"x":32,"y":0,"w":8,"h":8},"rotated":true}]}"#;
        let atlas = parse_texturepacker_json(json).unwrap();
        let entry = atlas.get_entry("bullet.png").unwrap();
        assert_eq!(entry.x, 32);
        assert!(entry.rotated);
    }

    #[test]
    fn atlas_missing_frames_key_returns_error() {
        let json = r#"{"meta":{}}"#;
        assert!(parse_texturepacker_json(json).is_err());
    }
}
