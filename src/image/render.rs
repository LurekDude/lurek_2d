//! Render-command generation for the image module.
//!
//! Provides methods on [`ImageData`] to produce GPU-facing [`RenderCommand`]s
//! and a CPU identity copy (`draw_to_image`).  The caller is responsible for
//! uploading pixel data to a GPU texture before submitting the draw command.
//! Pure CPU — no wgpu, winit, or mlua imports.

use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::TextureKey;

use super::image_data::ImageData;

impl ImageData {
    /// Generate a single `DrawImage` render command for this image.
    ///
    /// The caller is responsible for uploading the `ImageData` pixels to the
    /// GPU texture identified by `texture_key` before this command executes.
    ///
    /// # Parameters
    /// - `texture_key` — `TextureKey`. GPU texture handle to draw.
    /// - `x` — `f32`. Destination X position in screen pixels.
    /// - `y` — `f32`. Destination Y position in screen pixels.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(
        &self,
        texture_key: TextureKey,
        x: f32,
        y: f32,
    ) -> Vec<RenderCommand> {
        vec![RenderCommand::DrawImage {
            texture_key,
            x,
            y,
            effect: None,
        }]
    }

    /// Return a CPU copy of this image (identity draw-to-image).
    ///
    /// `ImageData` is already the CPU image representation, so this method
    /// returns a clone. Useful for conforming to the `draw_to_image` interface.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self) -> ImageData {
        self.clone()
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
    fn generate_render_commands_returns_one_draw_image() {
        let img = ImageData::new(64, 64);
        let cmds = img.generate_render_commands(dummy_key(), 0.0, 0.0);
        assert_eq!(cmds.len(), 1);
        assert!(matches!(cmds[0], RenderCommand::DrawImage { .. }));
    }

    #[test]
    fn generate_render_commands_position_embedded() {
        let img = ImageData::new(32, 32);
        let cmds = img.generate_render_commands(dummy_key(), 10.0, 20.0);
        if let RenderCommand::DrawImage { x, y, .. } = &cmds[0] {
            assert!((x - 10.0).abs() < f32::EPSILON);
            assert!((y - 20.0).abs() < f32::EPSILON);
        } else {
            panic!("expected DrawImage command");
        }
    }

    #[test]
    fn draw_to_image_preserves_dimensions() {
        let img = ImageData::new(128, 64);
        let copy = img.draw_to_image();
        assert_eq!(copy.width(), 128);
        assert_eq!(copy.height(), 64);
    }

    #[test]
    fn draw_to_image_preserves_pixels() {
        let mut img = ImageData::new(4, 4);
        img.set_pixel(2, 3, 255, 0, 128, 255);
        let copy = img.draw_to_image();
        assert_eq!(copy.get_pixel(2, 3), Some((255, 0, 128, 255)));
    }
}
