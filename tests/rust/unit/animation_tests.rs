//! INTERNAL ONLY: Rust-only tests for animation internals that are not observable via Lua.

use lurek2d::animation::render::{quad_to_draw_command, AnimRenderParams};
use lurek2d::animation::sync_group::AnimSyncGroup;
use lurek2d::math::Rect;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::runtime::resource_keys::TextureKey;
use slotmap::{DefaultKey, KeyData, SlotMap};

fn dummy_texture_key() -> TextureKey {
    TextureKey::from(KeyData::from_ffi(1))
}

fn dummy_slotmap_key() -> DefaultKey {
    let mut sm: SlotMap<DefaultKey, ()> = SlotMap::new();
    sm.insert(())
}

// ── render (Rust-only helper) ────────────────────────────────────────────────

mod render_tests {
    use super::*;

    fn make_params() -> AnimRenderParams {
        AnimRenderParams {
            texture_key: dummy_texture_key(),
            tex_w: 256.0,
            tex_h: 256.0,
            x: 100.0,
            y: 200.0,
            rotation: 0.0,
            sx: 1.0,
            sy: 1.0,
            ox: 16.0,
            oy: 16.0,
        }
    }

    #[test]
    fn quad_to_draw_preserves_all_fields() {
        let quad = Rect::new(64.0, 32.0, 16.0, 16.0);
        let params = make_params();
        let cmd = quad_to_draw_command(&quad, &params);
        if let RenderCommand::DrawQuad {
            quad_x,
            quad_y,
            tex_w,
            tex_h,
            ..
        } = cmd
        {
            assert!((quad_x - 64.0).abs() < 1e-5);
            assert!((quad_y - 32.0).abs() < 1e-5);
            assert!((tex_w - 256.0).abs() < 1e-5);
            assert!((tex_h - 256.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawQuad");
        }
    }
}

// ── sync_group ────────────────────────────────────────────────────────────────

mod sync_group_tests {
    use super::*;

    #[test]
    fn add_increases_count() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        assert_eq!(g.member_count(), 1);
    }

    #[test]
    fn add_duplicate_is_noop() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        g.add(k);
        assert_eq!(g.member_count(), 1);
    }

    #[test]
    fn remove_decreases_count() {
        let mut g = AnimSyncGroup::new();
        let k = dummy_slotmap_key();
        g.add(k);
        g.remove(k);
        assert_eq!(g.member_count(), 0);
    }

    #[test]
    fn clear_empties_group() {
        let mut g = AnimSyncGroup::new();
        let k1 = dummy_slotmap_key();
        let k2 = dummy_slotmap_key();
        g.add(k1);
        g.add(k2);
        g.clear();
        assert_eq!(g.member_count(), 0);
    }
}
