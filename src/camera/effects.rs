use std::f32::consts::PI;
pub struct ZoomPulse {
    pub active: bool,
    pub amplitude: f32,
    pub duration: f32,
    pub elapsed: f32,
}
impl ZoomPulse {
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.0,
            duration: 1.0,
            elapsed: 0.0,
        }
    }
    pub fn trigger(&mut self, amplitude: f32, duration: f32) {
        self.amplitude = amplitude;
        self.duration = duration.max(f32::EPSILON);
        self.elapsed = 0.0;
        self.active = true;
    }
    pub fn update(&mut self, dt: f32) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.elapsed += dt;
        if self.elapsed >= self.duration {
            self.elapsed = self.duration;
            self.active = false;
            return 0.0;
        }
        self.current_delta()
    }
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        let t = (self.elapsed / self.duration).min(1.0);
        self.amplitude * (t * PI).sin()
    }
    pub fn is_active(&self) -> bool {
        self.active
    }
}
impl Default for ZoomPulse {
    fn default() -> Self {
        Self::new()
    }
}
pub struct CameraSway {
    pub active: bool,
    pub amplitude_x: f32,
    pub amplitude_y: f32,
    pub frequency: f32,
    pub phase: f32,
    pub decay: f32,
    current_factor: f32,
}
impl CameraSway {
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude_x: 0.0,
            amplitude_y: 0.0,
            frequency: 1.0,
            phase: 0.0,
            decay: 1.0,
            current_factor: 0.0,
        }
    }
    pub fn start(&mut self, amplitude_x: f32, amplitude_y: f32, frequency: f32, decay: f32) {
        self.amplitude_x = amplitude_x;
        self.amplitude_y = amplitude_y;
        self.frequency = frequency.max(f32::EPSILON);
        self.decay = decay.clamp(0.0, 1.0);
        self.current_factor = 1.0;
        self.phase = 0.0;
        self.active = true;
    }
    pub fn stop(&mut self) {
        self.active = false;
        self.current_factor = 0.0;
    }
    pub fn update(&mut self, dt: f32) -> (f32, f32) {
        if !self.active {
            return (0.0, 0.0);
        }
        self.phase += self.frequency * 2.0 * PI * dt;
        if self.decay < 1.0 {
            self.current_factor *= self.decay.powf(dt);
            if self.current_factor < 0.001 {
                self.active = false;
                self.current_factor = 0.0;
                return (0.0, 0.0);
            }
        }
        self.current_offset()
    }
    pub fn current_offset(&self) -> (f32, f32) {
        if !self.active {
            return (0.0, 0.0);
        }
        let dx = self.amplitude_x * self.current_factor * self.phase.cos();
        let dy = self.amplitude_y * self.current_factor * (self.phase + PI * 0.25).sin();
        (dx, dy)
    }
    pub fn is_active(&self) -> bool {
        self.active
    }
}
impl Default for CameraSway {
    fn default() -> Self {
        Self::new()
    }
}
pub struct CameraBreathing {
    pub active: bool,
    pub amplitude: f32,
    pub rate: f32,
    pub phase: f32,
}
impl CameraBreathing {
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.005,
            rate: 0.2,
            phase: 0.0,
        }
    }
    pub fn start(&mut self, amplitude: f32, rate: f32) {
        self.amplitude = amplitude.abs();
        self.rate = rate.max(f32::EPSILON);
        self.phase = 0.0;
        self.active = true;
    }
    pub fn stop(&mut self) {
        self.active = false;
    }
    pub fn update(&mut self, dt: f32) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.phase += self.rate * 2.0 * PI * dt;
        self.current_delta()
    }
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.amplitude * self.phase.sin()
    }
    pub fn is_active(&self) -> bool {
        self.active
    }
}
impl Default for CameraBreathing {
    fn default() -> Self {
        Self::new()
    }
}
