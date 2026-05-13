use crate::log_msg;
use crate::runtime::log_messages::{TI01, TI02, TI03, TI04};
#[derive(Debug, Clone)]
pub struct ScheduledEvent {
    pub id: u32,
    pub name: Option<String>,
    pub remaining: f64,
    pub interval: f64,
    pub count: i32,
    pub one_shot: bool,
    pub paused: bool,
}
#[derive(Debug, Clone)]
pub struct FrameEvent {
    pub id: u32,
    pub name: Option<String>,
    pub remaining_frames: u64,
    pub interval_frames: u64,
    pub count: i32,
    pub one_shot: bool,
    pub paused: bool,
}
#[derive(Debug, Clone)]
pub struct Scheduler {
    events: Vec<ScheduledEvent>,
    frame_events: Vec<FrameEvent>,
    next_id: u32,
    time_scale: f64,
}
impl Default for Scheduler {
    fn default() -> Self {
        Self::new()
    }
}
impl Scheduler {
    pub fn new() -> Self {
        log_msg!(debug, TI01);
        Self {
            events: Vec::new(),
            frame_events: Vec::new(),
            next_id: 1,
            time_scale: 1.0,
        }
    }
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
    pub fn after_named(&mut self, name: impl Into<String>, delay: f64) -> u32 {
        let name = name.into();
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
    pub fn cancel_all(&mut self) -> u32 {
        let count = (self.events.len() + self.frame_events.len()) as u32;
        self.events.clear();
        self.frame_events.clear();
        log_msg!(debug, TI04, "{}", count);
        count
    }
    pub fn pause(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.paused = true;
            true
        } else {
            false
        }
    }
    pub fn resume(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.paused = false;
            true
        } else {
            false
        }
    }
    pub fn is_paused(&self, id: u32) -> bool {
        self.events
            .iter()
            .find(|e| e.id == id)
            .map(|e| e.paused)
            .unwrap_or(false)
    }
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
    pub fn is_paused_named(&self, name: &str) -> bool {
        self.events
            .iter()
            .find(|e| e.name.as_deref() == Some(name))
            .map(|e| e.paused)
            .unwrap_or(false)
    }
    pub fn get_remaining(&self, id: u32) -> Option<f64> {
        self.events.iter().find(|e| e.id == id).map(|e| e.remaining)
    }
    pub fn get_interval(&self, id: u32) -> Option<f64> {
        self.events.iter().find(|e| e.id == id).map(|e| e.interval)
    }
    pub fn get_repeat_count(&self, id: u32) -> Option<i32> {
        self.events.iter().find(|e| e.id == id).map(|e| e.count)
    }
    pub fn set_interval(&mut self, id: u32, new_interval: f64) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.interval = new_interval;
            ev.remaining = new_interval;
            true
        } else {
            false
        }
    }
    pub fn reset_event(&mut self, id: u32) -> bool {
        if let Some(ev) = self.events.iter_mut().find(|e| e.id == id) {
            ev.remaining = ev.interval;
            true
        } else {
            false
        }
    }
    pub fn set_time_scale(&mut self, scale: f64) {
        self.time_scale = scale.clamp(0.0, 100.0);
    }
    pub fn get_time_scale(&self) -> f64 {
        self.time_scale
    }
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
    pub fn count(&self) -> usize {
        self.events.len() + self.frame_events.len()
    }
    pub fn active_ids(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.events.iter().map(|e| e.id).collect();
        ids.extend(self.frame_events.iter().map(|e| e.id));
        ids
    }
    pub fn is_empty(&self) -> bool {
        self.events.is_empty() && self.frame_events.is_empty()
    }
}
