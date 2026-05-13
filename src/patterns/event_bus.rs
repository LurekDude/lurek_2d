use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct Subscription {
    pub id: u64,
    pub event: String,
    pub priority: i64,
    pub once: bool,
}
#[derive(Debug)]
pub struct EventBus {
    pub name: String,
    pub enabled: bool,
    next_id: u64,
    subs: HashMap<u64, Subscription>,
}
impl EventBus {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            enabled: true,
            next_id: 1,
            subs: HashMap::new(),
        }
    }
    pub fn subscribe(&mut self, event: &str, priority: i64, once: bool) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.subs.insert(
            id,
            Subscription {
                id,
                event: event.to_string(),
                priority,
                once,
            },
        );
        id
    }
    pub fn unsubscribe(&mut self, id: u64) -> bool {
        self.subs.remove(&id).is_some()
    }
    pub fn get_listeners(&self, event: &str) -> Vec<u64> {
        if !self.enabled {
            return Vec::new();
        }
        let mut listeners: Vec<&Subscription> = self
            .subs
            .values()
            .filter(|s| s.event == event || s.event == "*")
            .collect();
        listeners.sort_by(|a, b| b.priority.cmp(&a.priority));
        listeners.iter().map(|s| s.id).collect()
    }
    pub fn drain_once(&mut self, ids: &[u64]) -> Vec<u64> {
        let once: Vec<u64> = ids
            .iter()
            .copied()
            .filter(|id| self.subs.get(id).map(|s| s.once).unwrap_or(false))
            .collect();
        for id in &once {
            self.subs.remove(id);
        }
        once
    }
    pub fn clear_event(&mut self, event: &str) -> Vec<u64> {
        let ids: Vec<u64> = self
            .subs
            .values()
            .filter(|s| s.event == event)
            .map(|s| s.id)
            .collect();
        for id in &ids {
            self.subs.remove(id);
        }
        ids
    }
    pub fn clear_all(&mut self) -> Vec<u64> {
        let ids: Vec<u64> = self.subs.keys().copied().collect();
        self.subs.clear();
        ids
    }
    pub fn listener_count(&self, event: &str) -> usize {
        self.subs.values().filter(|s| s.event == event).count()
    }
    pub fn event_names(&self) -> Vec<String> {
        let mut events: Vec<String> = self
            .subs
            .values()
            .map(|s| s.event.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();
        events.sort();
        events
    }
    pub fn total_count(&self) -> usize {
        self.subs.len()
    }
}
