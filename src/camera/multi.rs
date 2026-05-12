//! Multi-camera orchestration helpers for split-screen, minimap, and picture-in-picture.
//!
//! This module keeps layout logic in Rust so Lua bindings can remain thin.

use std::collections::HashMap;

use crate::camera::types::Camera2D;

/// Named camera rig for orchestrating multiple cameras in one frame.
#[derive(Default)]
pub struct CameraRig2D {
    cameras: HashMap<String, Camera2D>,
}

impl CameraRig2D {
    /// Creates an empty camera rig.
    pub fn new() -> Self {
        Self {
            cameras: HashMap::new(),
        }
    }

    /// Returns `true` when a named camera exists.
    pub fn has_camera(&self, name: &str) -> bool {
        self.cameras.contains_key(name)
    }

    /// Removes a named camera and returns `true` when one existed.
    pub fn remove_camera(&mut self, name: &str) -> bool {
        self.cameras.remove(name).is_some()
    }

    /// Returns a mutable reference to a named camera, creating it when missing.
    pub fn ensure_camera(&mut self, name: &str, viewport_w: f32, viewport_h: f32) -> &mut Camera2D {
        self.cameras
            .entry(name.to_string())
            .or_insert_with(|| Camera2D::new(viewport_w, viewport_h))
    }

    /// Returns a mutable camera by name.
    pub fn camera_mut(&mut self, name: &str) -> Option<&mut Camera2D> {
        self.cameras.get_mut(name)
    }

    /// Returns a camera by name.
    pub fn camera(&self, name: &str) -> Option<&Camera2D> {
        self.cameras.get(name)
    }

    /// Applies a two-player vertical split-screen layout.
    pub fn apply_split_screen_layout(&mut self, window_w: f32, window_h: f32) {
        let half_w = window_w * 0.5;
        self.ensure_camera("left", half_w, window_h)
            .set_viewport(0.0, 0.0, half_w, window_h);
        self.ensure_camera("right", half_w, window_h)
            .set_viewport(half_w, 0.0, half_w, window_h);
    }

    /// Applies a main+minimap layout.
    pub fn apply_minimap_layout(&mut self, window_w: f32, window_h: f32, minimap_ratio: f32) {
        let ratio = minimap_ratio.clamp(0.1, 0.5);
        let mm_w = window_w * ratio;
        let mm_h = window_h * ratio;
        self.ensure_camera("main", window_w, window_h)
            .set_viewport(0.0, 0.0, window_w, window_h);
        self.ensure_camera("minimap", mm_w, mm_h)
            .set_viewport(window_w - mm_w, 0.0, mm_w, mm_h);
    }

    /// Applies a main+picture-in-picture layout.
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

    /// Updates all cameras.
    pub fn update_all(&mut self, dt: f32) {
        for camera in self.cameras.values_mut() {
            camera.update(dt);
        }
    }

    /// Returns the viewport for a named camera.
    pub fn viewport_of(&self, name: &str) -> Option<(f32, f32, f32, f32)> {
        self.camera(name).map(Camera2D::get_viewport)
    }

    /// Returns sorted camera names for deterministic UI/debug output.
    pub fn camera_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.cameras.keys().cloned().collect();
        names.sort();
        names
    }
}
