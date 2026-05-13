use std::collections::{HashMap, HashSet};
#[derive(Debug, Clone, Copy)]
pub struct TouchPoint {
    pub id: u64,
    pub x: f64,
    pub y: f64,
    pub pressure: f64,
}
#[derive(Debug, Default)]
pub struct TouchState {
    touches: HashMap<u64, TouchPoint>,
    touches_pressed: HashSet<u64>,
    touches_released: HashSet<u64>,
}
impl TouchState {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn begin_frame(&mut self) {
        self.touches_pressed.clear();
        self.touches_released.clear();
    }
    pub fn touch_start(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        self.touches_pressed.insert(id);
        self.touches.insert(id, TouchPoint { id, x, y, pressure });
    }
    pub fn touch_move(&mut self, id: u64, x: f64, y: f64, pressure: f64) {
        if let Some(touch) = self.touches.get_mut(&id) {
            touch.x = x;
            touch.y = y;
            touch.pressure = pressure;
        }
    }
    pub fn touch_end(&mut self, id: u64) {
        self.touches_released.insert(id);
        self.touches.remove(&id);
    }
    pub fn was_pressed(&self, id: u64) -> bool {
        self.touches_pressed.contains(&id)
    }
    pub fn was_released(&self, id: u64) -> bool {
        self.touches_released.contains(&id)
    }
    pub fn get_touches(&self) -> Vec<TouchPoint> {
        self.touches.values().copied().collect()
    }
    pub fn get_touch(&self, id: u64) -> Option<TouchPoint> {
        self.touches.get(&id).copied()
    }
    pub fn get_touch_count(&self) -> usize {
        self.touches.len()
    }
}
