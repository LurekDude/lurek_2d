//! - Record hierarchical profiling zones with push/pop stack semantics
//! - Compute total and self (exclusive) duration per zone
//! - Capture per-frame zone trees into bounded rolling history
//! - Retrieve frames by positive or negative index
//! - Flatten nested zone trees for aggregate reporting

use crate::devtools::time_anchor::TimeAnchor;
use std::collections::VecDeque;
#[derive(Debug, Clone)]
/// Represent one timed profiling zone with nested child zones.
pub struct ProfileZone {
    /// Store zone label captured at push time.
    pub name: String,
    /// Store start timestamp in seconds relative to profiler epoch.
    pub start_time: f64,
    /// Store end timestamp in seconds relative to profiler epoch.
    pub end_time: f64,
    /// Store nested zones recorded inside this zone.
    pub children: Vec<ProfileZone>,
}
impl ProfileZone {
    /// Return total duration of this zone in seconds.
    pub fn total_time(&self) -> f64 {
        self.end_time - self.start_time
    }
    /// Return exclusive duration after subtracting child zone totals.
    pub fn self_time(&self) -> f64 {
        let child_sum: f64 = self.children.iter().map(|c| c.total_time()).sum();
        (self.total_time() - child_sum).max(0.0)
    }
    /// Return a flattened pre-order list containing this zone and descendants.
    pub fn flatten(&self) -> Vec<&ProfileZone> {
        let mut out = vec![self];
        for child in &self.children {
            out.extend(child.flatten());
        }
        out
    }
}
#[derive(Debug)]
/// Store profiler capture state and bounded frame history of root zones.
pub struct Profiler {
    /// Enable or disable zone recording and frame capture.
    pub enabled: bool,
    /// Store captured frames as vectors of root profile zones.
    pub frames: VecDeque<Vec<ProfileZone>>,
    /// Define maximum number of frames retained in memory.
    pub max_frames: usize,
    /// Hold active zone stack entries with buffered children.
    zone_stack: Vec<(String, f64, Vec<ProfileZone>)>,
    /// Measure elapsed timestamps for zone start and end markers.
    epoch: TimeAnchor,
}
impl Profiler {
    /// Create profiler state with recording disabled and default retention.
    pub fn new() -> Self {
        Self {
            enabled: false,
            frames: VecDeque::new(),
            max_frames: 300,
            zone_stack: Vec::new(),
            epoch: TimeAnchor::new(),
        }
    }
    /// Return elapsed time in seconds from profiler epoch.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed_seconds()
    }
    /// Push a zone name onto the stack when profiling is enabled.
    pub fn push(&mut self, name: &str) {
        if !self.enabled {
            return;
        }
        let now = self.elapsed();
        self.zone_stack.push((name.to_string(), now, Vec::new()));
    }
    /// Pop current zone and attach it to parent or temporary frame root bucket.
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
                self.zone_stack.push((String::new(), 0.0, vec![zone]));
            }
        }
    }
    /// Finalize current frame zones and append them to retained frame history.
    pub fn end_frame(&mut self) {
        if !self.enabled {
            return;
        }
        let mut frame_zones: Vec<ProfileZone> = Vec::with_capacity(self.zone_stack.len());
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
        self.frames.push_back(frame_zones);
        if self.frames.len() > self.max_frames {
            let _ = self.frames.pop_front();
        }
    }
    /// Return one frame by index, supporting non-positive indices from the end.
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
    /// Clear active zones and stored frame history.
    pub fn reset(&mut self) {
        self.zone_stack.clear();
        self.frames.clear();
    }
}
/// Provide a default profiler with standard retention settings.
impl Default for Profiler {
    fn default() -> Self {
        Self::new()
    }
}
