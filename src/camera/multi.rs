//! Own camera-rig state for layouts that render multiple camera views.
//! Keep split-screen, minimap, and picture-in-picture viewport math in Rust.
//! Expose deterministic camera ordering for debug and UI panels.

use std::collections::HashMap;

use crate::camera::types::Camera2D;

#[derive(Default)]
/// Store named `Camera2D` instances used by multi-view layouts.
pub struct CameraRig2D {
    cameras: HashMap<String, Camera2D>,
}

impl CameraRig2D {
    /// Create an empty rig and return it.
    pub fn new() -> Self {
        Self {
            cameras: HashMap::new(),
        }
    }

    /// Check whether a named camera exists and return the result.
    pub fn has_camera(&self, name: &str) -> bool {
        self.cameras.contains_key(name)
    }

    /// Remove a named camera and return `true` when it existed.
    pub fn remove_camera(&mut self, name: &str) -> bool {
        self.cameras.remove(name).is_some()
    }

    /// Return a mutable named camera and create one when missing.
    pub fn ensure_camera(&mut self, name: &str, viewport_w: f32, viewport_h: f32) -> &mut Camera2D {
        self.cameras
            .entry(name.to_string())
            .or_insert_with(|| Camera2D::new(viewport_w, viewport_h))
    }

    /// Return a mutable camera by name or `None` when absent.
    pub fn camera_mut(&mut self, name: &str) -> Option<&mut Camera2D> {
        self.cameras.get_mut(name)
    }

    /// Return a camera by name or `None` when absent.
    pub fn camera(&self, name: &str) -> Option<&Camera2D> {
        self.cameras.get(name)
    }

    /// Apply a two-player vertical split layout and update `left` and `right` viewports.
    pub fn apply_split_screen_layout(&mut self, window_w: f32, window_h: f32) {
        let half_w = window_w * 0.5;
        self.ensure_camera("left", half_w, window_h)
            .set_viewport(0.0, 0.0, half_w, window_h);
        self.ensure_camera("right", half_w, window_h)
            .set_viewport(half_w, 0.0, half_w, window_h);
    }

    /// Apply a main-plus-minimap layout and clamp minimap ratio to `[0.1, 0.5]`.
    pub fn apply_minimap_layout(&mut self, window_w: f32, window_h: f32, minimap_ratio: f32) {
        let ratio = minimap_ratio.clamp(0.1, 0.5);
        let mm_w = window_w * ratio;
        let mm_h = window_h * ratio;
        self.ensure_camera("main", window_w, window_h)
            .set_viewport(0.0, 0.0, window_w, window_h);
        self.ensure_camera("minimap", mm_w, mm_h)
            .set_viewport(window_w - mm_w, 0.0, mm_w, mm_h);
    }

    /// Apply a main-plus-picture-in-picture layout and clamp pip dimensions to window bounds.
    pub fn apply_picture_in_picture_layout(
        &mut self,
        window_w: f32,
        window_h: f32,
        pip_w: f32,
        pip_h: f32,
    ) {
        let clamped_w = pip_w.clamp(32.0, window_w.max(32.0));
        let clamped_h = pip_h.clamp(32.0, window_h.max(32.0));
        self.ensure_camera("main", window_w, window_h)
            .set_viewport(0.0, 0.0, window_w, window_h);
        self.ensure_camera("pip", clamped_w, clamped_h)
            .set_viewport(
                window_w - clamped_w,
                window_h - clamped_h,
                clamped_w,
                clamped_h,
            );
    }

    /// Update every camera in the rig with `dt` seconds.
    pub fn update_all(&mut self, dt: f32) {
        for camera in self.cameras.values_mut() {
            camera.update(dt);
        }
    }

    /// Return the viewport tuple for a named camera or `None` when absent.
    pub fn viewport_of(&self, name: &str) -> Option<(f32, f32, f32, f32)> {
        self.camera(name).map(Camera2D::get_viewport)
    }

    /// Return camera names sorted lexicographically for deterministic output.
    pub fn camera_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.cameras.keys().cloned().collect();
        names.sort();
        names
    }
}
