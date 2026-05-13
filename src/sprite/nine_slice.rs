use crate::runtime::resource_keys::TextureKey;
pub type Patch = (f32, f32, f32, f32, f32, f32, f32, f32);
#[derive(Debug, Clone)]
pub struct NineSlice {
    pub texture_key: TextureKey,
    pub top: f32,
    pub right: f32,
    pub bottom: f32,
    pub left: f32,
    pub tex_width: f32,
    pub tex_height: f32,
}
impl NineSlice {
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
