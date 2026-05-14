//! Time-based camera effect primitives used by camera update paths.
//! Owns pulse zoom offsets, sway offsets, and breathing zoom oscillation.
//! Keeps effect state math separate from camera follow and bounds logic.
//! Depends only on scalar trigonometry from the standard library.

use std::f32::consts::PI;

/// Stores state for a temporary sinusoidal zoom pulse.
pub struct ZoomPulse {
    /// Indicates whether the pulse is currently contributing zoom offset.
    pub active: bool,
    /// Stores peak zoom delta applied at pulse midpoint.
    pub amplitude: f32,
    /// Stores total pulse length in seconds.
    pub duration: f32,
    /// Stores elapsed pulse time in seconds.
    pub elapsed: f32,
}
impl ZoomPulse {
    /// Create pulse state and return it with effect disabled.
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.0,
            duration: 1.0,
            elapsed: 0.0,
        }
    }
    /// Start a pulse and return once state is reset to frame zero.
    pub fn trigger(&mut self, amplitude: f32, duration: f32) {
        self.amplitude = amplitude;
        self.duration = duration.max(f32::EPSILON);
        self.elapsed = 0.0;
        self.active = true;
    }
    /// Advance pulse time and return current zoom delta, returning zero when inactive.
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
    /// Read current pulse zoom delta and return zero when inactive.
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        let t = (self.elapsed / self.duration).min(1.0);
        self.amplitude * (t * PI).sin()
    }
    /// Read active flag and return whether pulse contributes any offset.
    pub fn is_active(&self) -> bool {
        self.active
    }
}
/// Provides default pulse state for camera effect composition.
impl Default for ZoomPulse {
    /// Create default pulse state and return disabled configuration.
    fn default() -> Self {
        Self::new()
    }
}

/// Stores state for periodic camera positional sway.
pub struct CameraSway {
    /// Indicates whether sway updates should produce offsets.
    pub active: bool,
    /// Stores horizontal sway amplitude in world units.
    pub amplitude_x: f32,
    /// Stores vertical sway amplitude in world units.
    pub amplitude_y: f32,
    /// Stores oscillation frequency in hertz-like cycles per second.
    pub frequency: f32,
    /// Stores current oscillation phase in radians.
    pub phase: f32,
    /// Stores per-second decay factor multiplier.
    pub decay: f32,
    /// Stores runtime amplitude factor after decay is applied.
    current_factor: f32,
}
impl CameraSway {
    /// Create sway state and return it with zero contribution.
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
    /// Start sway motion and return after resetting phase and decay factor.
    pub fn start(&mut self, amplitude_x: f32, amplitude_y: f32, frequency: f32, decay: f32) {
        self.amplitude_x = amplitude_x;
        self.amplitude_y = amplitude_y;
        self.frequency = frequency.max(f32::EPSILON);
        self.decay = decay.clamp(0.0, 1.0);
        self.current_factor = 1.0;
        self.phase = 0.0;
        self.active = true;
    }
    /// Disable sway and return after clearing contribution factor.
    pub fn stop(&mut self) {
        self.active = false;
        self.current_factor = 0.0;
    }
    /// Advance sway phase and return the current positional offset tuple.
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
    /// Read current sway offset and return zeros when inactive.
    pub fn current_offset(&self) -> (f32, f32) {
        if !self.active {
            return (0.0, 0.0);
        }
        let dx = self.amplitude_x * self.current_factor * self.phase.cos();
        let dy = self.amplitude_y * self.current_factor * (self.phase + PI * 0.25).sin();
        (dx, dy)
    }
    /// Read active flag and return whether sway contributes offset.
    pub fn is_active(&self) -> bool {
        self.active
    }
}
/// Provides default sway state for camera effect composition.
impl Default for CameraSway {
    /// Create default sway state and return disabled configuration.
    fn default() -> Self {
        Self::new()
    }
}

/// Stores state for low-frequency breathing zoom modulation.
pub struct CameraBreathing {
    /// Indicates whether breathing updates should produce zoom delta.
    pub active: bool,
    /// Stores breathing amplitude added to zoom.
    pub amplitude: f32,
    /// Stores breathing rate in cycles per second.
    pub rate: f32,
    /// Stores current breathing phase in radians.
    pub phase: f32,
}
impl CameraBreathing {
    /// Create breathing state and return it with default tuning.
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.005,
            rate: 0.2,
            phase: 0.0,
        }
    }
    /// Start breathing and return after resetting phase.
    pub fn start(&mut self, amplitude: f32, rate: f32) {
        self.amplitude = amplitude.abs();
        self.rate = rate.max(f32::EPSILON);
        self.phase = 0.0;
        self.active = true;
    }
    /// Disable breathing and return immediately.
    pub fn stop(&mut self) {
        self.active = false;
    }
    /// Advance breathing phase and return current zoom delta.
    pub fn update(&mut self, dt: f32) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.phase += self.rate * 2.0 * PI * dt;
        self.current_delta()
    }
    /// Read current breathing zoom delta and return zero when inactive.
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.amplitude * self.phase.sin()
    }
    /// Read active flag and return whether breathing contributes zoom.
    pub fn is_active(&self) -> bool {
        self.active
    }
}
/// Provides default breathing state for camera effect composition.
impl Default for CameraBreathing {
    /// Create default breathing state and return disabled configuration.
    fn default() -> Self {
        Self::new()
    }
}
