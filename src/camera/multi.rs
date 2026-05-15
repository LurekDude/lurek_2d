//! - Multi-camera rig that stores and manages named Camera2D instances.
//! - Provides preset viewport layouts: split-screen, minimap, and picture-in-picture.
//! - Supports bulk update and deterministic iteration for multi-view rendering passes.

use crate::camera::types::Camera2D;
use std::collections::HashMap;

#[derive(Default)]
/// Stores named camera instances used by multi-view rendering flows.
pub struct CameraRig2D {
    /// Maps stable camera names to mutable camera states.
    cameras: HashMap<String, Camera2D>,
}
impl CameraRig2D {
    /// Create an empty rig and return it with no registered cameras.
    pub fn new() -> Self {
        Self {
            cameras: HashMap::new(),
        }
    }
    /// Check camera presence by name and return true when it exists.
    pub fn has_camera(&self, name: &str) -> bool {
        self.cameras.contains_key(name)
    }
    /// Remove camera by name and return true when an entry was removed.
    pub fn remove_camera(&mut self, name: &str) -> bool {
        self.cameras.remove(name).is_some()
    }
    /// Return mutable camera by name, creating one with the provided viewport when missing.
    pub fn ensure_camera(&mut self, name: &str, viewport_w: f32, viewport_h: f32) -> &mut Camera2D {
        self.cameras
            .entry(name.to_string())
            .or_insert_with(|| Camera2D::new(viewport_w, viewport_h))
    }
    /// Return mutable camera reference for a registered name, or none when absent.
    pub fn camera_mut(&mut self, name: &str) -> Option<&mut Camera2D> {
        self.cameras.get_mut(name)
    }
    /// Return immutable camera reference for a registered name, or none when absent.
    pub fn camera(&self, name: &str) -> Option<&Camera2D> {
        self.cameras.get(name)
    }
    /// Apply left-right split layout and return after updating both camera viewports.
    pub fn apply_split_screen_layout(&mut self, window_w: f32, window_h: f32) {
        let half_w = window_w * 0.5;
        self.ensure_camera("left", half_w, window_h)
            .set_viewport(0.0, 0.0, half_w, window_h);
        self.ensure_camera("right", half_w, window_h)
            .set_viewport(half_w, 0.0, half_w, window_h);
    }
    /// Apply main-plus-minimap layout and return after updating camera viewports.
    pub fn apply_minimap_layout(&mut self, window_w: f32, window_h: f32, minimap_ratio: f32) {
        let ratio = minimap_ratio.clamp(0.1, 0.5);
        let mm_w = window_w * ratio;
        let mm_h = window_h * ratio;
        self.ensure_camera("main", window_w, window_h)
            .set_viewport(0.0, 0.0, window_w, window_h);
        self.ensure_camera("minimap", mm_w, mm_h)
            .set_viewport(window_w - mm_w, 0.0, mm_w, mm_h);
    }
    /// Apply picture-in-picture layout and return after clamping overlay viewport size.
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
    /// Update every camera with delta time and return when all states are advanced.
    pub fn update_all(&mut self, dt: f32) {
        for camera in self.cameras.values_mut() {
            camera.update(dt);
        }
    }
    /// Read viewport for named camera and return none when camera is missing.
    pub fn viewport_of(&self, name: &str) -> Option<(f32, f32, f32, f32)> {
        self.camera(name).map(Camera2D::get_viewport)
    }
    /// Return sorted camera names for deterministic iteration in callers.
    pub fn camera_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.cameras.keys().cloned().collect();
        names.sort();
        names
    }
}
