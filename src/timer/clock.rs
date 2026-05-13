use std::time::Instant;
const AVERAGE_DELTA_WINDOW: usize = 60;
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
    pub fn delta(&self) -> f64 {
        self.delta
    }
    pub fn total(&self) -> f64 {
        self.total
    }
    pub fn fps(&self) -> f64 {
        self.fps
    }
    pub fn frame_count(&self) -> u64 {
        self.frame_count
    }
    pub fn elapsed(&self) -> f64 {
        self.start_time.elapsed().as_secs_f64()
    }
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
