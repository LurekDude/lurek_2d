//! Nine-slice panel geometry for scalable UI borders and boxes.
//! Owns NineSlice and the Patch type alias; computes the 9 source/destination rect pairs for tiled stretching.
//! Does not own texture data or rendering commands — callers iterate patches() and emit draw calls.
//! Key dependencies: TextureKey for referencing the border texture.

use crate::runtime::resource_keys::TextureKey;

/// Source and destination rect tuple: (src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h).
pub type Patch = (f32, f32, f32, f32, f32, f32, f32, f32);
/// Nine-slice border descriptor: stores texture key and the four border inset sizes.
#[derive(Debug, Clone)]
pub struct NineSlice {
    /// Texture containing the nine-slice source art.
    pub texture_key: TextureKey,
    /// Height of the top border strip in source pixels.
    pub top: f32,
    /// Width of the right border strip in source pixels.
    pub right: f32,
    /// Height of the bottom border strip in source pixels.
    pub bottom: f32,
    /// Width of the left border strip in source pixels.
    pub left: f32,
    /// Total source texture width in pixels.
    pub tex_width: f32,
    /// Total source texture height in pixels.
    pub tex_height: f32,
}
/// Constructor and patch generation for NineSlice.
impl NineSlice {
    /// Create a NineSlice with explicit border insets and full texture dimensions.
    pub fn new(
        texture_key: TextureKey,
        top: f32,
        right: f32,
        bottom: f32,
        left: f32,
        tex_width: f32,
        tex_height: f32,
    ) -> Self {
        NineSlice {
            texture_key,
            top,
            right,
            bottom,
            left,
            tex_width,
            tex_height,
        }
    }
    /// Return the 9 Patch tuples for drawing a nine-slice box at (x, y) with target dimensions (w, h).
    /// Order: top-left, top-centre, top-right, mid-left, mid-centre, mid-right, bot-left, bot-centre, bot-right.
    pub fn patches(&self, x: f32, y: f32, w: f32, h: f32) -> [Patch; 9] {
        let l = self.left;
        let r = self.right;
        let t = self.top;
        let b = self.bottom;
        let tw = self.tex_width;
        let th = self.tex_height;
        let src_cx = l;
        let src_cw = (tw - l - r).max(0.0);
        let src_rx = tw - r;
        let src_cy = t;
        let src_ch = (th - t - b).max(0.0);
        let src_by = th - b;
        let dst_cw = (w - l - r).max(0.0);
        let dst_ch = (h - t - b).max(0.0);
        [
            (0.0, 0.0, l, t, x, y, l, t),
            (src_cx, 0.0, src_cw, t, x + l, y, dst_cw, t),
            (src_rx, 0.0, r, t, x + l + dst_cw, y, r, t),
            (0.0, src_cy, l, src_ch, x, y + t, l, dst_ch),
            (src_cx, src_cy, src_cw, src_ch, x + l, y + t, dst_cw, dst_ch),
            (src_rx, src_cy, r, src_ch, x + l + dst_cw, y + t, r, dst_ch),
            (0.0, src_by, l, b, x, y + t + dst_ch, l, b),
            (src_cx, src_by, src_cw, b, x + l, y + t + dst_ch, dst_cw, b),
            (src_rx, src_by, r, b, x + l + dst_cw, y + t + dst_ch, r, b),
        ]
    }
}
