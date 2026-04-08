//! Hierarchical frame profiler with zone push/pop and rolling frame storage.
//!
//! The profiler tracks nested timing zones — each [`profilePush`][luna.devtools.profilePush]
//! opens a zone and each [`profilePop`][luna.devtools.profilePop] closes it.
//! Completed frames are stored in a capped ring and can be queried for the
//! flame-graph data needed by an overlay panel.

use std::time::Instant;

// ── zone ──────────────────────────────────────────────────────────────────

/// A completed timing zone with optional nested children.
///
/// # Fields
/// - `name` — `String`.
/// - `start_time` — `f64`.
/// - `end_time` — `f64`.
/// - `children` — `Vec<ProfileZone>`.
#[derive(Debug, Clone)]
pub struct ProfileZone {
    /// Human-readable zone name.
    pub name: String,
    /// Start time in seconds from the profiler epoch.
    pub start_time: f64,
    /// End time in seconds from the profiler epoch.
    pub end_time: f64,
    /// Direct child zones.
    pub children: Vec<ProfileZone>,
}

impl ProfileZone {
    /// Total wall-clock duration of this zone (includes children).
    ///
    /// # Returns
    /// `f64`.
    pub fn total_time(&self) -> f64 {
        self.end_time - self.start_time
    }

    /// Exclusive (self-only) duration, excluding children.
    ///
    /// # Returns
    /// `f64`.
    pub fn self_time(&self) -> f64 {
        let child_sum: f64 = self.children.iter().map(|c| c.total_time()).sum();
        (self.total_time() - child_sum).max(0.0)
    }

    /// Flattens all zones and children into a single pre-order list.
    ///
    /// # Returns
    /// `Vec<&ProfileZone>`.
    pub fn flatten(&self) -> Vec<&ProfileZone> {
        let mut out = vec![self];
        for child in &self.children {
            out.extend(child.flatten());
        }
        out
    }
}

// ── profiler ──────────────────────────────────────────────────────────────

/// Hierarchical frame profiler.
///
/// # Fields
/// - `enabled` — `bool`.
/// - `frames` — `Vec<Vec<ProfileZone>>`.
/// - `max_frames` — `usize`.
/// - `zone_stack` — internal open zone stack.
/// - `epoch` — `Instant`.
#[derive(Debug)]
pub struct Profiler {
    /// Whether profiling is active.
    pub enabled: bool,
    /// Completed frame records (oldest first).
    pub frames: Vec<Vec<ProfileZone>>,
    /// Maximum number of frames to retain.
    pub max_frames: usize,
    /// Stack entries: (name, start_time, accumulated_children).
    zone_stack: Vec<(String, f64, Vec<ProfileZone>)>,
    epoch: Instant,
}

impl Profiler {
    /// Creates a new profiler (disabled by default, 300 frame buffer).
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            enabled: false,
            frames: Vec::new(),
            max_frames: 300,
            zone_stack: Vec::new(),
            epoch: Instant::now(),
        }
    }

    /// Current seconds from the profiler epoch.
    ///
    /// # Returns
    /// `f64`.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }

    /// Opens a named timing zone.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn push(&mut self, name: &str) {
        if !self.enabled {
            return;
        }
        let now = self.elapsed();
        self.zone_stack.push((name.to_string(), now, Vec::new()));
    }

    /// Closes the most recent open zone.
    pub fn pop(&mut self) {
        if !self.enabled {
            return;
        }
        if let Some((name, start, children)) = self.zone_stack.pop() {
            let zone = ProfileZone {
                name,
                start_time: start,
                end_time: self.elapsed(),
                children,
            };
            if let Some(parent) = self.zone_stack.last_mut() {
                parent.2.push(zone);
            } else {
                // Top-level zone — keep in a sentinel entry
                self.zone_stack.push((String::new(), 0.0, vec![zone]));
            }
        }
    }

    /// Seals the current frame and stores the collected zones.
    pub fn end_frame(&mut self) {
        if !self.enabled {
            return;
        }
        let mut frame_zones: Vec<ProfileZone> = Vec::new();
        while let Some((name, start, children)) = self.zone_stack.pop() {
            if name.is_empty() && start == 0.0 {
                frame_zones.extend(children);
            } else {
                frame_zones.push(ProfileZone {
                    name,
                    start_time: start,
                    end_time: self.elapsed(),
                    children,
                });
            }
        }
        self.frames.push(frame_zones);
        if self.frames.len() > self.max_frames {
            self.frames.remove(0);
        }
    }

    /// Returns zone data for the frame at offset `idx` (0 = most recent, negative = relative).
    ///
    /// # Parameters
    /// - `idx` — `i64`.
    ///
    /// # Returns
    /// `Option<&Vec<ProfileZone>>`.
    pub fn get_frame(&self, idx: i64) -> Option<&Vec<ProfileZone>> {
        let n = self.frames.len();
        if n == 0 {
            return None;
        }
        let pos = if idx <= 0 {
            let abs = (-idx) as usize;
            n.saturating_sub(abs + 1).min(n - 1)
        } else {
            (idx as usize).min(n - 1)
        };
        self.frames.get(pos)
    }

    /// Clears all captured profiling data and resets the zone stack.
    pub fn reset(&mut self) {
        self.zone_stack.clear();
        self.frames.clear();
    }
}

impl Default for Profiler {
    fn default() -> Self {
        Self::new()
    }
}
