//! Scheduled event manager for delayed and repeating timed callbacks.
//!
//! Provides [`Scheduler`] for one-shot delays, repeating timers, named events,
//! individual pause/resume, global time-scale, and on-the-fly interval changes.
//!
//! ## Usage
//! ```rust,no_run
//! # use lurek2d::timer::Scheduler;
//! let mut sched = Scheduler::new();
//! let id = sched.after(2.0);          // fires once after 2 seconds
//! let rid = sched.every(0.5, -1);     // fires every 0.5 s indefinitely
//! sched.set_time_scale(0.5);          // run at half speed
//! let fired = sched.update(0.1);      // advance; returns IDs that fired
//! sched.cancel(rid);
//! ```

use crate::log_msg;
use crate::runtime::log_messages::{TI01, TI02, TI03, TI04};
/// A single scheduled event with optional name and pause state.
///
/// # Fields
/// - `id` — `u32`.
/// - `name` — `Option<String>`.
/// - `remaining` — `f64`.
/// - `interval` — `f64`.
/// - `count` — `i32`.
/// - `one_shot` — `bool`.
/// - `paused` — `bool`.
#[derive(Debug, Clone)]
pub struct ScheduledEvent {
    /// Unique numeric identifier for this event.
    pub id: u32,
    /// Optional human-readable name (enables cancel-by-name).
    pub name: Option<String>,
    /// Time remaining until the next firing (seconds).
    pub remaining: f64,
    /// Interval between firings (seconds, set at creation).
    pub interval: f64,
    /// How many times left to fire (0 = expired, -1 = infinite).
    pub count: i32,
    /// Whether this is a one-shot event (fires once then removes itself).
    pub one_shot: bool,
    /// Whether this event is individually paused.
    pub paused: bool,
}

/// A frame-count–based scheduled event.
///
/// # Fields
/// - `id` — `u32`.
/// - `name` — `Option<String>`.
/// - `target_frames` — `u64`. Fire when this many frames have elapsed since creation.
/// - `frames_elapsed` — `u64`. Frames counted so far.
/// - `interval_frames` — `u64`. For repeating: frames between firings.
/// - `count` — `i32`. How many times left to fire (0 = expired, -1 = infinite).
/// - `one_shot` — `bool`.
/// - `paused` — `bool`.
#[derive(Debug, Clone)]
pub struct FrameEvent {
    /// Unique numeric identifier (shares ID-space with time-based events).
    pub id: u32,
    /// Optional name.
    pub name: Option<String>,
    /// Frames remaining until next fire.
    pub remaining_frames: u64,
    /// Interval in frames for repeating events.
    pub interval_frames: u64,
    /// How many times left to fire (0 = expired, -1 = infinite).
    pub count: i32,
    /// Whether this is a one-shot event.
    pub one_shot: bool,
    /// Whether this event is individually paused.
    pub paused: bool,
}

/// Manages a collection of timed events (one-shot and repeating).
///
/// Each event has an integer ID (returned on creation) that can be used for
/// cancellation, pause/resume, and property reads. Named events can also be
/// cancelled by their string name.
///
/// The global `time_scale` multiplier compresses or stretches all timers.
/// A scale of `0.5` makes everything run at half speed; `2.0` doubles speed.
/// Individual events can be paused with [`Scheduler::pause`].
///
/// # Fields
/// - `events` — `Vec<ScheduledEvent>`.
/// - `next_id` — `u32`.
/// - `time_scale` — `f64`.
#[derive(Debug, Clone)]
pub struct Scheduler {
    events: Vec<ScheduledEvent>,
    frame_events: Vec<FrameEvent>,
    next_id: u32,
    /// Global time multiplier applied to every `update(dt)` call.
    time_scale: f64,
}

impl Default for Scheduler {
    fn default() -> Self {
        Self::new()
    }
}

impl Scheduler {
    /// Create a new empty Scheduler with time-scale 1.0.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, TI01);
        Self {
            events: Vec::new(),
            frame_events: Vec::new(),
            next_id: 1,
            time_scale: 1.0,
        }
    }

    // ── Scheduling ────────────────────────────────────────────────────────

    /// Schedule a one-shot callback after `delay` seconds.
    ///
    /// # Parameters
    /// - `delay` — `f64`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Returns an event ID usable for cancellation, pause, and queries.
    pub fn after(&mut self, delay: f64) -> u32 {
        log_msg!(debug, TI02, "{:.3}s", delay);
        let id = self.next_id;
        self.next_id += 1;
        self.events.push(ScheduledEvent {
            id,
            name: None,
            remaining: delay,
            interval: delay,
            count: 1,
            one_shot: true,
            paused: false,
        });
        id
    }

    /// Schedule a one-shot callback with a `name` for cancel-by-name support.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `delay` — `f64`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// If an event with the same name already exists it is replaced.
    /// Returns the new event ID.
    pub fn after_named(&mut self, name: impl Into<String>, delay: f64) -> u32 {
        let name = name.into();
        // Remove existing event with same name
        self.events.retain(|e| e.name.as_deref() != Some(&name));
        let id = self.next_id;
        self.next_id += 1;
        self.events.push(ScheduledEvent {
            id,
            name: Some(name),
            remaining: delay,
            interval: delay,
            count: 1,
            one_shot: true,
            paused: false,
        });
        id
    }

    /// Schedule a repeating callback at `interval` seconds.
    ///
    /// # Parameters
    /// - `interval` — `f64`.
    /// - `count` — `i32`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// `count` limits repetitions (-1 = infinite). Returns event ID.
    pub fn every(&mut self, interval: f64, count: i32) -> u32 {
        log_msg!(debug, TI03, "{:.3}s", interval);
        let id = self.next_id;
        self.next_id += 1;
        self.events.push(ScheduledEvent {
            id,
            name: None,
            remaining: interval,
            interval,
            count,
            one_shot: false,
            paused: false,
        });
        id
    }

    /// Schedule a named repeating callback.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `interval` — `f64`.
    /// - `count` — `i32`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Replaces any existing event with the same name.
    pub fn every_named(&mut self, name: impl Into<String>, interval: f64, count: i32) -> u32 {
        let name = name.into();
        self.events.retain(|e| e.name.as_deref() != Some(&name));
        let id = self.next_id;
        self.next_id += 1;
        self.events.push(ScheduledEvent {
            id,
            name: Some(name),
            remaining: interval,
            interval,
            count,
            one_shot: false,
            paused: false,
        });
        id
    }

    // ── Frame-Based Scheduling ──────────────────────────────────────────

    /// Schedule a one-shot event that fires after `n` frames.
    ///
    /// # Parameters
    /// - `n` — `u64`. Number of frames to wait.
    ///
    /// # Returns
    /// `u32` — event ID.
    pub fn after_frames(&mut self, n: u64) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.frame_events.push(FrameEvent {
            id,
            name: None,
            remaining_frames: n,
            interval_frames: n,
            count: 1,
            one_shot: true,
            paused: false,
        });
        id
    }

    /// Schedule a repeating event that fires every `n` frames.
    ///
    /// # Parameters
    /// - `n` — `u64`. Interval in frames.
    /// - `count` — `i32`. How many times to fire (-1 = infinite).
    ///
    /// # Returns
    /// `u32` — event ID.
    pub fn every_frames(&mut self, n: u64, count: i32) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.frame_events.push(FrameEvent {
            id,
            name: None,
            remaining_frames: n,
            interval_frames: n,
            count,
            one_shot: false,
            paused: false,
        });
        id
    }

    // ── Cancellation ──────────────────────────────────────────────────────

    /// Cancel a scheduled event by its ID.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if found and cancelled.
    pub fn cancel(&mut self, id: u32) -> bool {
        if let Some(pos) = self.events.iter().position(|e| e.id == id) {
            self.events.remove(pos);
            true
        } else if let Some(pos) = self.frame_events.iter().position(|e| e.id == id) {
            self.frame_events.remove(pos);
            true
        } else {
            false
        }
    }

    /// Cancel a scheduled event by its name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<u32>`.
    ///
    /// Returns the ID of the cancelled event, or `None` if no match.
    pub fn cancel_named(&mut self, name: &str) -> Option<u32> {
        if let Some(pos) = self
            .events
            .iter()
            .position(|e| e.name.as_deref() == Some(name))
        {
            let id = self.events[pos].id;
            self.events.remove(pos);
            Some(id)
        } else {
            None
        }
    }

    /// Cancel all scheduled events.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Returns the number cancelled.
    pub fn cancel_all(&mut self) -> u32 {
        let count = (self.events.len() + self.frame_events.len()) as u32;
        self.events.clear();
        self.frame_events.clear();
        log_msg!(debug, TI04, "{}", count);
        count
    }

    // ── Pause / Resume ────────────────────────────────────────────────────

    /// Pause a single event by ID. Its remaining time is frozen until resumed.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if found.
    pub fn pause(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.paused = true;
            true
        } else {
            false
        }
    }

    /// Resume a previously paused event by ID.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if found.
    pub fn resume(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.paused = false;
            true
        } else {
            false
        }
    }

    /// Returns `true` if the event with `id` is currently paused.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self, id: u32) -> bool {
        self.events
            .iter()
            .find(|e| e.id == id)
            .map(|e| e.paused)
            .unwrap_or(false)
    }

    /// Pauses a scheduled event by its string name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if an event with that name was found.
    pub fn pause_named(&mut self, name: &str) -> bool {
        if let Some(ev) = self
            .events
            .iter_mut()
            .find(|e| e.name.as_deref() == Some(name))
        {
            ev.paused = true;
            true
        } else {
            false
        }
    }

    /// Resumes a previously paused event by its string name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if an event with that name was found.
    pub fn resume_named(&mut self, name: &str) -> bool {
        if let Some(ev) = self
            .events
            .iter_mut()
            .find(|e| e.name.as_deref() == Some(name))
        {
            ev.paused = false;
            true
        } else {
            false
        }
    }

    /// Returns `true` if the named event is currently paused.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused_named(&self, name: &str) -> bool {
        self.events
            .iter()
            .find(|e| e.name.as_deref() == Some(name))
            .map(|e| e.paused)
            .unwrap_or(false)
    }

    // ── Queries ───────────────────────────────────────────────────────────

    /// Returns the time remaining until the next fire for event `id`, or `None` if not found.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn get_remaining(&self, id: u32) -> Option<f64> {
        self.events.iter().find(|e| e.id == id).map(|e| e.remaining)
    }

    /// Returns the base interval for event `id`, or `None` if not found.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn get_interval(&self, id: u32) -> Option<f64> {
        self.events.iter().find(|e| e.id == id).map(|e| e.interval)
    }

    /// Returns the repeat count remaining for event `id` (-1 = infinite), or `None` if not found.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `Option<i32>`.
    pub fn get_repeat_count(&self, id: u32) -> Option<i32> {
        self.events.iter().find(|e| e.id == id).map(|e| e.count)
    }

    // ── Modification ──────────────────────────────────────────────────────

    /// Change the interval of a repeating event.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `new_interval` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Also resets `remaining` to the new interval. Returns `true` if found.
    pub fn set_interval(&mut self, id: u32, new_interval: f64) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.interval = new_interval;
            ev.remaining = new_interval;
            true
        } else {
            false
        }
    }

    /// Reset an event's remaining time to its original interval.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Useful to restart a repeating event without cancelling it.
    /// Returns `true` if found.
    pub fn reset_event(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.remaining = ev.interval;
            true
        } else {
            false
        }
    }

    // ── Time Scale ────────────────────────────────────────────────────────

    /// Set the global time-scale multiplier for this scheduler.
    ///
    /// # Parameters
    /// - `scale` — `f64`.
    ///
    /// A scale of `0.5` runs all timers at half speed; `2.0` doubles speed.
    /// The scale is clamped to `[0.0, 100.0]`.
    pub fn set_time_scale(&mut self, scale: f64) {
        self.time_scale = scale.clamp(0.0, 100.0);
    }

    /// Returns the current global time-scale.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_time_scale(&self) -> f64 {
        self.time_scale
    }

    // ── Update ────────────────────────────────────────────────────────────

    /// Advance all non-paused timers by `dt * time_scale` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    ///
    /// Returns a vector of event IDs that fired this update.
    /// Expired one-shot and count-limited events are automatically removed.
    pub fn update(&mut self, dt: f64) -> Vec<u32> {
        let scaled_dt = dt * self.time_scale;
        let mut fired = Vec::new();

        let mut idx = 0;
        while idx < self.events.len() {
            let remove;
            {
                let event = &mut self.events[idx];
                if !event.paused {
                    event.remaining -= scaled_dt;
                    while event.remaining <= 0.0 {
                        fired.push(event.id);
                        if event.one_shot {
                            event.count = 0;
                            break;
                        } else if event.count > 0 {
                            event.count -= 1;
                            if event.count == 0 {
                                break;
                            }
                        }
                        event.remaining += event.interval;
                    }
                }
                remove = event.count == 0;
            }

            if remove {
                self.events.swap_remove(idx);
            } else {
                idx += 1;
            }
        }

        fired
    }

    // ── Collection queries ────────────────────────────────────────────────

    /// Advance all non-paused frame-based events by one frame.
    ///
    /// # Returns
    /// `Vec<u32>` — IDs of frame events that fired this frame.
    ///
    /// Call once per game frame (not affected by `time_scale`).
    pub fn update_frames(&mut self) -> Vec<u32> {
        let mut fired = Vec::new();

        let mut idx = 0;
        while idx < self.frame_events.len() {
            let remove;
            {
                let event = &mut self.frame_events[idx];
                if !event.paused {
                    if event.remaining_frames > 0 {
                        event.remaining_frames -= 1;
                    }
                    if event.remaining_frames == 0 {
                        fired.push(event.id);
                        if event.one_shot {
                            event.count = 0;
                        } else if event.count > 0 {
                            event.count -= 1;
                            if event.count > 0 {
                                event.remaining_frames = event.interval_frames;
                            }
                        } else {
                            event.remaining_frames = event.interval_frames;
                        }
                    }
                }
                remove = event.count == 0;
            }

            if remove {
                self.frame_events.swap_remove(idx);
            } else {
                idx += 1;
            }
        }

        fired
    }

    /// Get the number of active (non-expired) scheduled events.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.events.len() + self.frame_events.len()
    }

    /// Get the IDs of all active events.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn active_ids(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.events.iter().map(|e| e.id).collect();
        ids.extend(self.frame_events.iter().map(|e| e.id));
        ids
    }

    /// Returns `true` if no events are scheduled.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.events.is_empty() && self.frame_events.is_empty()
    }
}
