//! CPU software-rendering fallback for the parallax module.
//!
//! Provides `draw_to_image()` on [`ParallaxLayer`] for headless testing.
//! GPU render commands live in `src/parallax/render.rs`.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::image::ImageData;

use super::layer::ParallaxLayer;

impl ParallaxLayer {
    /// Render this parallax layer to a CPU image for headless testing.
    ///
    /// Produces a solid-colour fill using the layer's tint and opacity,
    /// representing the visible colour the layer would contribute at the
    /// given dimensions. No GPU texture sampling is performed.
    ///
    /// Invisible layers (`visible = false`) return a fully transparent image.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width in pixels.
    /// - `height` — `u32`. Output image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> ImageData {
        let mut img = ImageData::new(width, height);

        if !self.visible {
            // Fully transparent — layer is hidden.
            img.fill(0, 0, 0, 0);
            return img;
        }

        let [tr, tg, tb, _ta] = self.tint;
        let alpha = (self.opacity * 255.0).clamp(0.0, 255.0) as u8;
        let r = (tr * 255.0).clamp(0.0, 255.0) as u8;
        let g = (tg * 255.0).clamp(0.0, 255.0) as u8;
        let b = (tb * 255.0).clamp(0.0, 255.0) as u8;

        img.fill(r, g, b, alpha);
        img
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runtime::resource_keys::TextureKey;
    use slotmap::KeyData;

    fn dummy_key() -> TextureKey {
        TextureKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        let img = layer.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_invisible_layer_is_transparent() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.visible = false;
        let img = layer.draw_to_image(16, 16);
        if let Some((_, _, _, a)) = img.get_pixel(0, 0) {
            assert_eq!(a, 0, "invisible layer should be fully transparent");
        }
    }

    #[test]
    fn draw_to_image_uses_layer_tint() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.tint = [1.0, 0.0, 0.5, 1.0];
        layer.opacity = 1.0;
        let img = layer.draw_to_image(16, 16);
        if let Some((r, g, _, _)) = img.get_pixel(0, 0) {
            assert!(r > 200, "expected high red channel from tint");
            assert!(g < 10, "expected zero green channel from tint");
        }
    }
}
