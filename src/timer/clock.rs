//! Clock implementation for the `timer` subsystem.
//!
//! This module is part of Lurek2D's `timer` subsystem and provides the implementation
//! details for clock-related operations and data management.
//! Key types exported from this module: `Clock`.
//! Primary functions: `new()`, `tick()`, `delta()`, `total()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
use std::time::Instant;

/// Number of recent frames used to compute the rolling average delta.
const AVERAGE_DELTA_WINDOW: usize = 60;

/// Tracks per-frame delta time, accumulated total time, and a rolling FPS measurement.
///
/// # Fields
/// - `start_time` — `Instant`.
/// - `last_frame` — `Instant`.
/// - `delta` — `f64`.
/// - `total` — `f64`.
/// - `frame_count` — `u64`.
/// - `fps` — `f64`.
/// - `fps_timer` — `f64`.
/// - `fps_frame_count` — `u64`.
/// - `delta_buffer` — `[f64; AVERAGE_DELTA_WINDOW]`.
/// - `delta_buffer_index` — `usize`.
/// - `delta_buffer_filled` — `bool`.
pub struct Clock {
    start_time: Instant,
    last_frame: Instant,
    delta: f64,
    total: f64,
    frame_count: u64,
    fps: f64,
    fps_timer: f64,
    fps_frame_count: u64,
    delta_buffer: [f64; AVERAGE_DELTA_WINDOW],
    delta_buffer_index: usize,
    delta_buffer_filled: bool,
}

impl Default for Clock {
    fn default() -> Self {
        Self::new()
    }
}

impl Clock {
    /// Creates a new `Clock`, recording the current instant as the start time.
    ///
    /// # Returns
    /// A new `Clock` with delta = 0, FPS = 0, and frame count = 0.
    pub fn new() -> Self {
        let now = Instant::now();
        Clock {
            start_time: now,
            last_frame: now,
            delta: 0.0,
            total: 0.0,
            frame_count: 0,
            fps: 0.0,
            fps_timer: 0.0,
            fps_frame_count: 0,
            delta_buffer: [0.0; AVERAGE_DELTA_WINDOW],
            delta_buffer_index: 0,
            delta_buffer_filled: false,
        }
    }

    /// Advances the clock by one frame, updating delta time, total time, and rolling FPS.
    ///
    /// Call once per frame at the top of the game loop. The rolling FPS is updated
    /// every second using a frame-accumulation window.
    ///
    /// # Returns
    /// `f64` — The elapsed time since the last `tick` call, in seconds.
    pub fn tick(&mut self) -> f64 {
        let now = Instant::now();
        self.delta = now.duration_since(self.last_frame).as_secs_f64();
        self.last_frame = now;
        self.total = now.duration_since(self.start_time).as_secs_f64();
        self.frame_count += 1;

        self.fps_frame_count += 1;
        self.fps_timer += self.delta;
        if self.fps_timer >= 1.0 {
            self.fps = self.fps_frame_count as f64 / self.fps_timer;
            self.fps_timer = 0.0;
            self.fps_frame_count = 0;
        }

        // Store delta in rolling buffer for average calculation
        self.delta_buffer[self.delta_buffer_index] = self.delta;
        self.delta_buffer_index += 1;
        if self.delta_buffer_index >= AVERAGE_DELTA_WINDOW {
            self.delta_buffer_index = 0;
            self.delta_buffer_filled = true;
        }

        self.delta
    }

    /// Returns the delta time for the most recently completed frame in seconds.
    ///
    /// # Returns
    /// `f64` — Frame delta time in seconds.
    pub fn delta(&self) -> f64 {
        self.delta
    }
    /// Returns the total elapsed time since the clock was created, in seconds.
    ///
    /// # Returns
    /// `f64` — Total engine uptime in seconds.
    pub fn total(&self) -> f64 {
        self.total
    }
    /// Returns the rolling frames-per-second measurement.
    ///
    /// Updated once per second. Returns `0.0` during the first second of execution.
    ///
    /// # Returns
    /// `f64` — Current FPS estimate.
    pub fn fps(&self) -> f64 {
        self.fps
    }
    /// Returns the total number of frames that have elapsed since the clock was created.
    ///
    /// # Returns
    /// `u64` — Cumulative frame count.
    pub fn frame_count(&self) -> u64 {
        self.frame_count
    }

    /// Returns a live high-resolution elapsed time since the clock was created, in seconds.
    ///
    /// Unlike [`Clock::total`], which caches its value on each [`Clock::tick`] call,
    /// this method queries the system clock directly, giving sub-microsecond precision
    /// at the moment of the call.
    ///
    /// # Returns
    /// `f64` — Elapsed time since clock creation in seconds.
    pub fn elapsed(&self) -> f64 {
        self.start_time.elapsed().as_secs_f64()
    }

    /// Returns the average delta time over the last N frames (up to 60).
    ///
    /// Returns `0.0` if no frames have been ticked yet. Once the buffer is full,
    /// averages over the entire 60-frame window.
    ///
    /// # Returns
    /// `f64` — Rolling average delta in seconds.
    pub fn average_delta(&self) -> f64 {
        let count = if self.delta_buffer_filled {
            AVERAGE_DELTA_WINDOW
        } else {
            self.delta_buffer_index
        };
        if count == 0 {
            return 0.0;
        }
        let sum: f64 = self.delta_buffer[..count].iter().sum();
        sum / count as f64
    }
}
