use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct SpringAxis {
    pub position: f32,
    pub velocity: f32,
    pub target: f32,
    pub stiffness: f32,
    pub damping: f32,
    pub precision: f32,
    pub settled: bool,
}
impl SpringAxis {
    pub fn new(position: f32, target: f32, stiffness: f32, damping: f32, precision: f32) -> Self {
        let settled = (position - target).abs() < precision;
        Self {
            position,
            velocity: 0.0,
            target,
            stiffness,
            damping,
            precision,
            settled,
        }
    }
    pub fn update(&mut self, dt: f32) {
        if self.settled {
            return;
        }
        self.velocity += (self.target - self.position) * self.stiffness * dt;
        self.velocity *= 1.0 - self.damping * dt;
        self.position += self.velocity * dt;
        self.settled = (self.position - self.target).abs() < self.precision
            && self.velocity.abs() < self.precision;
        if self.settled {
            self.position = self.target;
            self.velocity = 0.0;
        }
    }
    pub fn is_settled(&self) -> bool {
        self.settled
    }
    pub fn reset(&mut self, position: f32, target: f32) {
        self.position = position;
        self.target = target;
        self.velocity = 0.0;
        self.settled = (position - target).abs() < self.precision;
    }
    pub fn set_target(&mut self, target: f32) {
        self.target = target;
        self.settled = false;
    }
}
#[derive(Debug, Clone)]
pub struct SpringSystem {
    pub axes: HashMap<String, SpringAxis>,
    pub stiffness: f32,
    pub damping: f32,
    pub precision: f32,
}
impl SpringSystem {
    pub fn new(stiffness: f32, damping: f32, precision: f32) -> Self {
        Self {
            axes: HashMap::new(),
            stiffness,
            damping,
            precision,
        }
    }
    pub fn add_axis(&mut self, key: String, position: f32, target: f32) {
        self.axes.insert(
            key,
            SpringAxis::new(
                position,
                target,
                self.stiffness,
                self.damping,
                self.precision,
            ),
        );
    }
    pub fn update(&mut self, dt: f32) {
        for axis in self.axes.values_mut() {
            axis.update(dt);
        }
    }
    pub fn is_settled(&self) -> bool {
        self.axes.values().all(|a| a.is_settled())
    }
    pub fn set_target(&mut self, key: &str, target: f32) {
        if let Some(axis) = self.axes.get_mut(key) {
            axis.set_target(target);
        }
    }
    pub fn get_position(&self, key: &str) -> Option<f32> {
        self.axes.get(key).map(|a| a.position)
    }
}
