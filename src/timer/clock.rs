//! Per-frame wall-clock that tracks delta, total elapsed time, FPS, and a
//! rolling average delta over the last 60 frames. Does not own scheduling or
//! sleep; consumed by the runtime main loop and `lurek.timer` bindings.
//! Depends only on `std::time::Instant`.

use std::time::Instant;

/// Number of frames kept in the rolling delta average window.
const AVERAGE_DELTA_WINDOW: usize = 60;

/// Per-frame clock tracking delta, total elapsed time, FPS, and rolling delta average; used by the runtime main loop.
pub struct Clock {
    /// Instant captured when the clock was created; used to compute total elapsed.
    start_time: Instant,
    /// Instant captured at the end of the previous `tick` call.
    last_frame: Instant,
    /// Seconds elapsed between the last two `tick` calls.
    delta: f64,
    /// Seconds elapsed since `start_time`, updated each `tick`.
    total: f64,
    /// Total frames ticked since clock creation.
    frame_count: u64,
    /// Frames-per-second, updated once per second.
    fps: f64,
    /// Accumulated seconds within the current one-second FPS measurement window.
    fps_timer: f64,
    /// Frame counter within the current FPS window, reset every second.
    fps_frame_count: u64,
    /// Ring buffer of the last `AVERAGE_DELTA_WINDOW` delta values in seconds.
    delta_buffer: [f64; AVERAGE_DELTA_WINDOW],
    /// Write cursor into `delta_buffer`.
    delta_buffer_index: usize,
    /// True once `delta_buffer` has been filled at least once.
    delta_buffer_filled: bool,
}

/// Provide `Clock::new()` as the default constructor.
impl Default for Clock {
    fn default() -> Self {
        Self::new()
    }
}

impl Clock {
    /// Create a new clock with all counters zeroed and both `start_time` and `last_frame` set to now.
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

    /// Advance the clock by one frame: compute delta, update FPS every second, append to rolling buffer; return delta in seconds.
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
        self.delta_buffer[self.delta_buffer_index] = self.delta;
        self.delta_buffer_index += 1;
        if self.delta_buffer_index >= AVERAGE_DELTA_WINDOW {
            self.delta_buffer_index = 0;
            self.delta_buffer_filled = true;
        }
        self.delta
    }

    /// Return seconds elapsed between the last two `tick` calls.
    pub fn delta(&self) -> f64 {
        self.delta
    }

    /// Return seconds elapsed since the clock was created, as of the last `tick`.
    pub fn total(&self) -> f64 {
        self.total
    }

    /// Return the most recently computed frames-per-second value, updated once per second.
    pub fn fps(&self) -> f64 {
        self.fps
    }

    /// Return the total number of `tick` calls since clock creation.
    pub fn frame_count(&self) -> u64 {
        self.frame_count
    }

    /// Return live wall-clock seconds since the clock was created, measured at call time (not last tick).
    pub fn elapsed(&self) -> f64 {
        self.start_time.elapsed().as_secs_f64()
    }

    /// Return the mean delta over the last `AVERAGE_DELTA_WINDOW` frames, or 0.0 if no frames have been ticked.
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
