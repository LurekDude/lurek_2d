//! Scheduled event manager for delayed and repeating timed callbacks.
//!
//! Provides [`Scheduler`] for one-shot delays, repeating timers, named events,
//! individual pause/resume, global time-scale, and on-the-fly interval changes.
//!
//! ## Usage
//! ```rust,no_run
//! # use luna2d::timer::Scheduler;
//! let mut sched = Scheduler::new();
//! let id = sched.after(2.0);          // fires once after 2 seconds
//! let rid = sched.every(0.5, -1);     // fires every 0.5 s indefinitely
//! sched.set_time_scale(0.5);          // run at half speed
//! let fired = sched.update(0.1);      // advance; returns IDs that fired
//! sched.cancel(rid);
//! ```

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
        Self {
            events: Vec::new(),
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

    /// Schedule a named repeating callback. Consult the module-level documentation for the broader usage context and preconditions.
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

    // ── Cancellation ──────────────────────────────────────────────────────

    /// Cancel a scheduled event by its ID. Consult the module-level documentation for the broader usage context and preconditions.
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
        } else {
            false
        }
    }

    /// Cancel a scheduled event by its name. Consult the module-level documentation for the broader usage context and preconditions.
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

    /// Cancel all scheduled events. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// Returns the number cancelled.
    pub fn cancel_all(&mut self) -> u32 {
        let count = self.events.len() as u32;
        self.events.clear();
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

    /// Resume a previously paused event by ID. Consult the module-level documentation for the broader usage context and preconditions.
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

    /// Returns the current global time-scale. This accessor incurs no allocation; call it freely in hot paths.
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

        for event in &mut self.events {
            if event.paused {
                continue;
            }
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

        // Remove expired events
        self.events.retain(|e| e.count != 0);

        fired
    }

    // ── Collection queries ────────────────────────────────────────────────

    /// Get the number of active (non-expired) scheduled events.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.events.len()
    }

    /// Get the IDs of all active events. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn active_ids(&self) -> Vec<u32> {
        self.events.iter().map(|e| e.id).collect()
    }

    /// Returns `true` if no events are scheduled.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_scheduler_is_empty() {
        let sched = Scheduler::new();
        assert_eq!(sched.count(), 0);
        assert!(sched.is_empty());
    }

    #[test]
    fn after_schedules_event() {
        let mut sched = Scheduler::new();
        let id = sched.after(1.0);
        assert!(id > 0);
        assert_eq!(sched.count(), 1);
    }

    #[test]
    fn after_fires_once() {
        let mut sched = Scheduler::new();
        sched.after(1.0);
        let fired = sched.update(0.5);
        assert!(fired.is_empty());
        let fired = sched.update(0.6);
        assert_eq!(fired.len(), 1);
        assert_eq!(sched.count(), 0); // removed after firing
    }

    #[test]
    fn every_fires_repeatedly() {
        let mut sched = Scheduler::new();
        sched.every(0.5, -1); // infinite
        let fired = sched.update(1.1);
        assert_eq!(fired.len(), 2); // fired at 0.5 and 1.0
        assert_eq!(sched.count(), 1); // still active
    }

    #[test]
    fn every_with_count_expires() {
        let mut sched = Scheduler::new();
        sched.every(0.5, 2);
        let fired = sched.update(1.1);
        assert_eq!(fired.len(), 2);
        assert_eq!(sched.count(), 0); // expired
    }

    #[test]
    fn cancel_removes_event() {
        let mut sched = Scheduler::new();
        let id = sched.after(1.0);
        assert!(sched.cancel(id));
        assert_eq!(sched.count(), 0);
    }

    #[test]
    fn cancel_returns_false_for_unknown() {
        let mut sched = Scheduler::new();
        assert!(!sched.cancel(999));
    }

    #[test]
    fn cancel_all_clears() {
        let mut sched = Scheduler::new();
        sched.after(1.0);
        sched.every(0.5, -1);
        let n = sched.cancel_all();
        assert_eq!(n, 2);
        assert_eq!(sched.count(), 0);
    }

    #[test]
    fn default_is_empty() {
        let sched = Scheduler::default();
        assert_eq!(sched.count(), 0);
    }

    // ── New feature tests ─────────────────────────────────────────────────

    #[test]
    fn pause_freezes_event() {
        let mut sched = Scheduler::new();
        let id = sched.after(1.0);
        sched.pause(id);
        assert!(sched.is_paused(id));
        let fired = sched.update(2.0); // would have fired if not paused
        assert!(fired.is_empty());
        assert_eq!(sched.count(), 1);
    }

    #[test]
    fn resume_unfreezes_event() {
        let mut sched = Scheduler::new();
        let id = sched.after(0.5);
        sched.pause(id);
        sched.update(1.0);
        assert_eq!(sched.count(), 1); // still there, paused
        sched.resume(id);
        assert!(!sched.is_paused(id));
        let fired = sched.update(0.6);
        assert_eq!(fired.len(), 1);
    }

    #[test]
    fn get_remaining_returns_correct_value() {
        let mut sched = Scheduler::new();
        let id = sched.after(2.0);
        sched.update(0.5);
        let rem = sched.get_remaining(id).unwrap();
        assert!((rem - 1.5).abs() < 1e-9);
    }

    #[test]
    fn get_remaining_returns_none_for_missing() {
        let sched = Scheduler::new();
        assert!(sched.get_remaining(99).is_none());
    }

    #[test]
    fn set_interval_changes_timing() {
        let mut sched = Scheduler::new();
        let id = sched.every(1.0, -1);
        sched.set_interval(id, 0.5);
        assert_eq!(sched.get_interval(id).unwrap(), 0.5);
        let fired = sched.update(1.1);
        assert_eq!(fired.len(), 2); // fires at 0.5 and 1.0
    }

    #[test]
    fn reset_event_restarts_remaining() {
        let mut sched = Scheduler::new();
        let id = sched.after(1.0);
        sched.update(0.7);
        sched.reset_event(id);
        let fired = sched.update(0.5);
        assert!(fired.is_empty()); // should not fire yet (reset to 1.0 remaining)
        let fired = sched.update(0.6);
        assert_eq!(fired.len(), 1);
    }

    #[test]
    fn time_scale_slows_timers() {
        let mut sched = Scheduler::new();
        sched.after(1.0);
        sched.set_time_scale(0.5);
        assert!((sched.get_time_scale() - 0.5).abs() < 1e-9);
        let fired = sched.update(1.5); // effective = 0.75s, not enough
        assert!(fired.is_empty());
        let fired = sched.update(1.0); // effective += 0.5 -> total 1.25s
        assert_eq!(fired.len(), 1);
    }

    #[test]
    fn time_scale_zero_freezes_all() {
        let mut sched = Scheduler::new();
        sched.after(0.1);
        sched.set_time_scale(0.0);
        let fired = sched.update(100.0);
        assert!(fired.is_empty());
        assert_eq!(sched.count(), 1);
    }

    #[test]
    fn after_named_fires_and_removes() {
        let mut sched = Scheduler::new();
        sched.after_named("boss-spawn", 0.5);
        let fired = sched.update(0.6);
        assert_eq!(fired.len(), 1);
        assert_eq!(sched.count(), 0);
    }

    #[test]
    fn cancel_named_works() {
        let mut sched = Scheduler::new();
        sched.after_named("foo", 1.0);
        let cancelled = sched.cancel_named("foo");
        assert!(cancelled.is_some());
        assert_eq!(sched.count(), 0);
    }

    #[test]
    fn cancel_named_returns_none_for_missing() {
        let mut sched = Scheduler::new();
        assert!(sched.cancel_named("nonexistent").is_none());
    }

    #[test]
    fn after_named_replaces_existing() {
        let mut sched = Scheduler::new();
        sched.after_named("wave", 5.0);
        sched.after_named("wave", 1.0); // replaces
        assert_eq!(sched.count(), 1);
        let fired = sched.update(1.1);
        assert_eq!(fired.len(), 1);
    }

    #[test]
    fn every_named_repeating() {
        let mut sched = Scheduler::new();
        sched.every_named("tick", 0.5, 3);
        let fired = sched.update(1.6);
        assert_eq!(fired.len(), 3);
        assert_eq!(sched.count(), 0);
    }

    #[test]
    fn get_repeat_count_decrements() {
        let mut sched = Scheduler::new();
        let id = sched.every(0.5, 3);
        assert_eq!(sched.get_repeat_count(id), Some(3));
        sched.update(0.6);
        assert_eq!(sched.get_repeat_count(id), Some(2));
    }
}
