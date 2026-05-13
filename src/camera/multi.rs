use crate::camera::types::Camera2D;
use std::collections::HashMap;
#[derive(Default)]
pub struct CameraRig2D {
    cameras: HashMap<String, Camera2D>,
}
impl CameraRig2D {
    pub fn new() -> Self {
        Self {
            cameras: HashMap::new(),
        }
    }
    pub fn has_camera(&self, name: &str) -> bool {
        self.cameras.contains_key(name)
    }
    pub fn remove_camera(&mut self, name: &str) -> bool {
        self.cameras.remove(name).is_some()
    }
    pub fn ensure_camera(&mut self, name: &str, viewport_w: f32, viewport_h: f32) -> &mut Camera2D {
        self.cameras
            .entry(name.to_string())
            .or_insert_with(|| Camera2D::new(viewport_w, viewport_h))
    }
    pub fn camera_mut(&mut self, name: &str) -> Option<&mut Camera2D> {
        self.cameras.get_mut(name)
    }
    pub fn camera(&self, name: &str) -> Option<&Camera2D> {
        self.cameras.get(name)
    }
    pub fn apply_split_screen_layout(&mut self, window_w: f32, window_h: f32) {
        let half_w = window_w * 0.5;
        self.ensure_camera("left", half_w, window_h)
            .set_viewport(0.0, 0.0, half_w, window_h);
        self.ensure_camera("right", half_w, window_h)
            .set_viewport(half_w, 0.0, half_w, window_h);
    }
    pub fn apply_minimap_layout(&mut self, window_w: f32, window_h: f32, minimap_ratio: f32) {
        let ratio = minimap_ratio.clamp(0.1, 0.5);
        let mm_w = window_w * ratio;
        let mm_h = window_h * ratio;
        self.ensure_camera("main", window_w, window_h)
            .set_viewport(0.0, 0.0, window_w, window_h);
        self.ensure_camera("minimap", mm_w, mm_h)
            .set_viewport(window_w - mm_w, 0.0, mm_w, mm_h);
    }
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
    pub fn update_all(&mut self, dt: f32) {
        for camera in self.cameras.values_mut() {
            camera.update(dt);
        }
    }
    pub fn viewport_of(&self, name: &str) -> Option<(f32, f32, f32, f32)> {
        self.camera(name).map(Camera2D::get_viewport)
    }
    pub fn camera_names(&self) -> Vec<String> {
        let mut names: Vec<String> = self.cameras.keys().cloned().collect();
        names.sort();
        names
    }
}
