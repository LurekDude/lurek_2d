//! Cinematic camera effects: zoom pulse, sway, and breathing.
//!
//! All effects are pure Rust — no mlua dependencies. They are stored as fields
//! on [`crate::camera::Camera2D`] and ticked each frame via [`Camera2D::update`].
//! Query current output through [`Camera2D::effective_zoom`] and
//! [`Camera2D::effect_offset`].

use std::f32::consts::PI;

// ---- Type: ZoomPulse ----

/// Zoom pulse effect — brief zoom-in that decays back to the original zoom via
/// a sine envelope.
///
/// Trigger with [`ZoomPulse::trigger`]. The zoom delta rises quickly and then
/// decays back to zero over `duration` seconds. Commonly used for hit impacts
/// or ability activations.
///
/// # Fields
/// - `active` — Whether the pulse is currently running.
/// - `amplitude` — Peak zoom delta (e.g., `0.1` = 10% zoom-in).
/// - `duration` — Total pulse duration in seconds.
/// - `elapsed` — Time elapsed since the last trigger.
pub struct ZoomPulse {
    /// Whether the pulse is currently active.
    pub active: bool,
    /// Peak zoom delta (e.g., `0.1` = 10% zoom-in at peak).
    pub amplitude: f32,
    /// Total pulse duration in seconds.
    pub duration: f32,
    /// Elapsed time since the last trigger, in seconds.
    pub elapsed: f32,
}

// ---- Implementation: ZoomPulse ----

impl ZoomPulse {
    /// Creates a new, inactive `ZoomPulse`.
    ///
    /// # Returns
    /// `Self`
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.0,
            duration: 1.0,
            elapsed: 0.0,
        }
    }

    /// Triggers a new zoom pulse, replacing any active one.
    ///
    /// # Parameters
    /// - `amplitude` — Peak zoom delta (e.g., `0.15`).
    /// - `duration` — Duration in seconds (clamped to > 0).
    pub fn trigger(&mut self, amplitude: f32, duration: f32) {
        self.amplitude = amplitude;
        self.duration = duration.max(f32::EPSILON);
        self.elapsed = 0.0;
        self.active = true;
    }

    /// Advances the pulse by `dt` seconds and returns the current zoom delta.
    ///
    /// Returns `0.0` when inactive or once the duration has elapsed.
    ///
    /// # Parameters
    /// - `dt` — `f32`
    ///
    /// # Returns
    /// `f32`
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

    /// Returns the current zoom delta without advancing time.
    ///
    /// Uses a sine envelope so the delta rises from 0, peaks near the midpoint,
    /// and returns to 0 at the end of the duration.
    ///
    /// # Returns
    /// `f32`
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        let t = (self.elapsed / self.duration).min(1.0);
        // Sine envelope: 0 at t=0, peak at t=0.5, back to 0 at t=1.
        self.amplitude * (t * PI).sin()
    }

    /// Returns `true` if the pulse is currently active.
    ///
    /// # Returns
    /// `bool`
    pub fn is_active(&self) -> bool {
        self.active
    }
}

// ---- Default Implementation ----

impl Default for ZoomPulse {
    fn default() -> Self {
        Self::new()
    }
}

// ---- Type: CameraSway ----

/// Camera sway — sinusoidal x/y offset oscillation for rocking or underwater
/// effects.
///
/// Amplitudes can decay over time via the `decay` multiplier applied per second.
/// Set `decay = 1.0` for infinite sway; values below `1.0` cause gradual
/// fade-out.
///
/// # Fields
/// - `active` — Whether sway is currently running.
/// - `amplitude_x` — Configured maximum x-axis amplitude in world units.
/// - `amplitude_y` — Configured maximum y-axis amplitude in world units.
/// - `frequency` — Oscillation frequency in cycles per second (Hz).
/// - `phase` — Accumulated phase in radians.
/// - `decay` — Per-second amplitude decay multiplier (`1.0` = no decay).
pub struct CameraSway {
    /// Whether sway is currently active.
    pub active: bool,
    /// Maximum x-axis offset amplitude in world units.
    pub amplitude_x: f32,
    /// Maximum y-axis offset amplitude in world units.
    pub amplitude_y: f32,
    /// Oscillation frequency in cycles per second (Hz).
    pub frequency: f32,
    /// Accumulated phase in radians.
    pub phase: f32,
    /// Per-second amplitude decay multiplier (`1.0` = no decay).
    pub decay: f32,
    /// Live amplitude factor in `[0.0, 1.0]`.  Starts at `1.0` and decays each
    /// frame when `decay < 1.0`.
    current_factor: f32,
}

// ---- Implementation: CameraSway ----

impl CameraSway {
    /// Creates a new, inactive `CameraSway`.
    ///
    /// # Returns
    /// `Self`
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

    /// Starts or restarts the sway effect.
    ///
    /// # Parameters
    /// - `amplitude_x` — Max horizontal offset in world units.
    /// - `amplitude_y` — Max vertical offset in world units.
    /// - `frequency` — Oscillation speed in Hz.
    /// - `decay` — Per-second amplitude multiplier (clamped to `[0, 1]`).
    pub fn start(&mut self, amplitude_x: f32, amplitude_y: f32, frequency: f32, decay: f32) {
        self.amplitude_x = amplitude_x;
        self.amplitude_y = amplitude_y;
        self.frequency = frequency.max(f32::EPSILON);
        self.decay = decay.clamp(0.0, 1.0);
        self.current_factor = 1.0;
        self.phase = 0.0;
        self.active = true;
    }

    /// Stops the sway effect immediately.
    pub fn stop(&mut self) {
        self.active = false;
        self.current_factor = 0.0;
    }

    /// Advances sway by `dt` seconds and returns the `(dx, dy)` world-space
    /// offset.
    ///
    /// Returns `(0.0, 0.0)` when inactive. When `decay < 1.0` and the factor
    /// falls below `0.001` the effect auto-stops.
    ///
    /// # Parameters
    /// - `dt` — `f32`
    ///
    /// # Returns
    /// `(f32, f32)`
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

    /// Returns the current `(dx, dy)` sway offset without advancing time.
    ///
    /// x uses a cosine and y uses a sine offset by `π/4` for a natural oval
    /// motion rather than a perfectly straight line.
    ///
    /// # Returns
    /// `(f32, f32)`
    pub fn current_offset(&self) -> (f32, f32) {
        if !self.active {
            return (0.0, 0.0);
        }
        let dx = self.amplitude_x * self.current_factor * self.phase.cos();
        let dy = self.amplitude_y * self.current_factor * (self.phase + PI * 0.25).sin();
        (dx, dy)
    }

    /// Returns `true` if sway is currently active.
    ///
    /// # Returns
    /// `bool`
    pub fn is_active(&self) -> bool {
        self.active
    }
}

// ---- Default Implementation ----

impl Default for CameraSway {
    fn default() -> Self {
        Self::new()
    }
}

// ---- Type: CameraBreathing ----

/// Camera breathing — subtle periodic zoom oscillation for a "living camera"
/// feel.
///
/// Creates a gentle sine-wave zoom oscillation at the configured rate and
/// amplitude. Unlike [`ZoomPulse`], breathing continues indefinitely until
/// explicitly stopped.
///
/// # Fields
/// - `active` — Whether breathing is currently running.
/// - `amplitude` — Zoom oscillation amplitude (e.g., `0.005` = 0.5%).
/// - `rate` — Breathing rate in cycles per second (e.g., `0.2` = 12 per minute).
/// - `phase` — Accumulated phase in radians.
pub struct CameraBreathing {
    /// Whether breathing is currently active.
    pub active: bool,
    /// Zoom oscillation amplitude (e.g., `0.005` = 0.5%).
    pub amplitude: f32,
    /// Breathing rate in cycles per second (e.g., `0.2` = 12 per minute).
    pub rate: f32,
    /// Accumulated phase in radians.
    pub phase: f32,
}

// ---- Implementation: CameraBreathing ----

impl CameraBreathing {
    /// Creates a new, inactive `CameraBreathing` with default parameters
    /// (`amplitude=0.005`, `rate=0.2`).
    ///
    /// # Returns
    /// `Self`
    pub fn new() -> Self {
        Self {
            active: false,
            amplitude: 0.005,
            rate: 0.2,
            phase: 0.0,
        }
    }

    /// Starts or restarts the breathing effect.
    ///
    /// # Parameters
    /// - `amplitude` — Zoom oscillation amplitude (absolute value used).
    /// - `rate` — Cycles per second (clamped to > 0).
    pub fn start(&mut self, amplitude: f32, rate: f32) {
        self.amplitude = amplitude.abs();
        self.rate = rate.max(f32::EPSILON);
        self.phase = 0.0;
        self.active = true;
    }

    /// Stops the breathing effect.
    pub fn stop(&mut self) {
        self.active = false;
    }

    /// Advances breathing by `dt` seconds and returns the current zoom delta.
    ///
    /// Returns `0.0` when inactive.
    ///
    /// # Parameters
    /// - `dt` — `f32`
    ///
    /// # Returns
    /// `f32`
    pub fn update(&mut self, dt: f32) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.phase += self.rate * 2.0 * PI * dt;
        self.current_delta()
    }

    /// Returns the current zoom delta without advancing time.
    ///
    /// # Returns
    /// `f32`
    pub fn current_delta(&self) -> f32 {
        if !self.active {
            return 0.0;
        }
        self.amplitude * self.phase.sin()
    }

    /// Returns `true` if breathing is currently active.
    ///
    /// # Returns
    /// `bool`
    pub fn is_active(&self) -> bool {
        self.active
    }
}

// ---- Default Implementation ----

impl Default for CameraBreathing {
    fn default() -> Self {
        Self::new()
    }
}
