//! Nine-slice (9-patch) image rendering for scalable UI elements.
//!
//! A nine-slice divides a texture into 9 regions using 4 border insets:
//! corners are drawn at fixed size, edges stretch in one axis, and the
//! center stretches in both axes. This preserves visual quality when
//! scaling UI panels, buttons, and dialog boxes.

use crate::engine::resource_keys::TextureKey;

/// A single patch rectangle: `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
pub type Patch = (f32, f32, f32, f32, f32, f32, f32, f32);

/// A nine-slice image definition: a texture plus border insets.
///
/// The four insets (`top`, `right`, `bottom`, `left`) define pixel distances
/// from each edge of the source texture. These divide the texture into
/// 9 regions:
///
/// ```text
/// ┌───────┬─────────────────┬───────┐
/// │ TL    │    Top Edge      │  TR   │
/// ├───────┼─────────────────┼───────┤
/// │ Left  │    Center        │ Right │
/// │ Edge  │   (stretches)    │ Edge  │
/// ├───────┼─────────────────┼───────┤
/// │ BL    │   Bottom Edge    │  BR   │
/// └───────┴─────────────────┴───────┘
/// ```
///
/// Corners maintain their original pixel dimensions. Edges stretch
/// along one axis. The center stretches in both axes.
#[derive(Debug, Clone)]
pub struct NineSlice {
    /// Key into `SharedState::textures` for the source image.
    pub texture_key: TextureKey,
    /// Pixels inset from the top edge.
    pub top: f32,
    /// Pixels inset from the right edge.
    pub right: f32,
    /// Pixels inset from the bottom edge.
    pub bottom: f32,
    /// Pixels inset from the left edge.
    pub left: f32,
    /// Full source texture width in pixels.
    pub tex_width: f32,
    /// Full source texture height in pixels.
    pub tex_height: f32,
}

impl NineSlice {
    /// Creates a new nine-slice definition.
    ///
    /// # Parameters
    /// - `texture_key` — Key for the source texture in SharedState.
    /// - `top` — Pixel inset from the top edge.
    /// - `right` — Pixel inset from the right edge.
    /// - `bottom` — Pixel inset from the bottom edge.
    /// - `left` — Pixel inset from the left edge.
    /// - `tex_width` — Full source texture width in pixels.
    /// - `tex_height` — Full source texture height in pixels.
    ///
    /// # Returns
    /// A new `NineSlice`.
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

    /// Returns the 9 source and destination rectangles for rendering.
    ///
    /// Each entry is `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
    ///
    /// # Parameters
    /// - `x` — Destination X position.
    /// - `y` — Destination Y position.
    /// - `w` — Destination total width.
    /// - `h` — Destination total height.
    ///
    /// # Returns
    /// An array of 9 `Patch` rectangles.
    pub fn patches(&self, x: f32, y: f32, w: f32, h: f32) -> [Patch; 9] {
        let l = self.left;
        let r = self.right;
        let t = self.top;
        let b = self.bottom;
        let tw = self.tex_width;
        let th = self.tex_height;

        // Source column/row boundaries
        let src_cx = l;
        let src_cw = (tw - l - r).max(0.0);
        let src_rx = tw - r;
        let src_cy = t;
        let src_ch = (th - t - b).max(0.0);
        let src_by = th - b;

        // Destination column/row sizes
        let dst_cw = (w - l - r).max(0.0);
        let dst_ch = (h - t - b).max(0.0);

        [
            // Top-left corner
            (0.0, 0.0, l, t, x, y, l, t),
            // Top edge
            (src_cx, 0.0, src_cw, t, x + l, y, dst_cw, t),
            // Top-right corner
            (src_rx, 0.0, r, t, x + l + dst_cw, y, r, t),
            // Left edge
            (0.0, src_cy, l, src_ch, x, y + t, l, dst_ch),
            // Center
            (src_cx, src_cy, src_cw, src_ch, x + l, y + t, dst_cw, dst_ch),
            // Right edge
            (src_rx, src_cy, r, src_ch, x + l + dst_cw, y + t, r, dst_ch),
            // Bottom-left corner
            (0.0, src_by, l, b, x, y + t + dst_ch, l, b),
            // Bottom edge
            (src_cx, src_by, src_cw, b, x + l, y + t + dst_ch, dst_cw, b),
            // Bottom-right corner
            (src_rx, src_by, r, b, x + l + dst_cw, y + t + dst_ch, r, b),
        ]
    }
}
