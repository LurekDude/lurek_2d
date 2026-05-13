//! Own time-based camera effects used by `Camera2D` update flow.
//! Keep effect state in pure Rust structs independent from Lua bindings.
//! Expose zoom and offset deltas for render transform composition.

use std::f32::consts::PI;

/// Track one zoom pulse envelope and sample its current zoom delta.
pub struct ZoomPulse {
    /// Mark whether the pulse is active.
    pub active: bool,
    /// Store peak zoom delta at pulse midpoint.
    pub amplitude: f32,
    /// Store pulse duration in seconds.
    pub duration: f32,
    /// Store elapsed pulse time in seconds.
    pub elapsed: f32,
}

impl ZoomPulse {
    /// Create an inactive pulse with default duration and return it.
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.0,
            duration: 1.0,
            elapsed: 0.0,
        }
    }

    /// Start a pulse with amplitude and positive clamped duration.
    pub fn trigger(&mut self, amplitude: f32, duration: f32) {
        self.amplitude = amplitude;
        self.duration = duration.max(f32::EPSILON);
        self.elapsed = 0.0;
        self.active = true;
    }

    /// Advance pulse time by `dt` and return current zoom delta or `0.0` when inactive.
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

    /// Return current zoom delta sample without advancing time.
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        let t = (self.elapsed / self.duration).min(1.0);
        self.amplitude * (t * PI).sin()
    }

    /// Return `true` when pulse is active.
    pub fn is_active(&self) -> bool {
        self.active
    }
}

impl Default for ZoomPulse {
    fn default() -> Self {
        Self::new()
    }
}

/// Track sinusoidal x/y sway offsets and optional amplitude decay.
pub struct CameraSway {
    /// Mark whether sway is active.
    pub active: bool,
    /// Store horizontal sway amplitude in world units.
    pub amplitude_x: f32,
    /// Store vertical sway amplitude in world units.
    pub amplitude_y: f32,
    /// Store sway frequency in cycles per second.
    pub frequency: f32,
    /// Store accumulated sway phase in radians.
    pub phase: f32,
    /// Store per-second amplitude multiplier in `[0.0, 1.0]`.
    pub decay: f32,
    /// Store runtime amplitude factor used after decay.
    current_factor: f32,
}

impl CameraSway {
    /// Create an inactive sway state and return it.
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

    /// Start sway with amplitudes, positive frequency, and clamped decay.
    pub fn start(&mut self, amplitude_x: f32, amplitude_y: f32, frequency: f32, decay: f32) {
        self.amplitude_x = amplitude_x;
        self.amplitude_y = amplitude_y;
        self.frequency = frequency.max(f32::EPSILON);
        self.decay = decay.clamp(0.0, 1.0);
        self.current_factor = 1.0;
        self.phase = 0.0;
        self.active = true;
    }

    /// Stop sway immediately and clear runtime factor.
    pub fn stop(&mut self) {
        self.active = false;
        self.current_factor = 0.0;
    }

    /// Advance sway by `dt` and return world offset; return zero offset when inactive.
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

    /// Return current sway offset without advancing phase.
    pub fn current_offset(&self) -> (f32, f32) {
        if !self.active {
            return (0.0, 0.0);
        }
        let dx = self.amplitude_x * self.current_factor * self.phase.cos();
        let dy = self.amplitude_y * self.current_factor * (self.phase + PI * 0.25).sin();
        (dx, dy)
    }

    /// Return `true` when sway is active.
    pub fn is_active(&self) -> bool {
        self.active
    }
}

impl Default for CameraSway {
    fn default() -> Self {
        Self::new()
    }
}

/// Track periodic zoom oscillation used for breathing-style camera motion.
pub struct CameraBreathing {
    /// Mark whether breathing is active.
    pub active: bool,
    /// Store zoom oscillation amplitude.
    pub amplitude: f32,
    /// Store breathing rate in cycles per second.
    pub rate: f32,
    /// Store accumulated breathing phase in radians.
    pub phase: f32,
}

impl CameraBreathing {
    /// Create an inactive breathing state with default amplitude and rate.
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.005,
            rate: 0.2,
            phase: 0.0,
        }
    }

    /// Start breathing with absolute amplitude and positive clamped rate.
    pub fn start(&mut self, amplitude: f32, rate: f32) {
        self.amplitude = amplitude.abs();
        self.rate = rate.max(f32::EPSILON);
        self.phase = 0.0;
        self.active = true;
    }

    /// Stop breathing effect.
    pub fn stop(&mut self) {
        self.active = false;
    }

    /// Advance breathing by `dt` and return current zoom delta or `0.0` when inactive.
    pub fn update(&mut self, dt: f32) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.phase += self.rate * 2.0 * PI * dt;
        self.current_delta()
    }

    /// Return current breathing zoom delta without advancing time.
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.amplitude * self.phase.sin()
    }

    /// Return `true` when breathing is active.
    pub fn is_active(&self) -> bool {
        self.active
    }
}

impl Default for CameraBreathing {
    fn default() -> Self {
        Self::new()
    }
}

