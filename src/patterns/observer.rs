use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct ObserverEntry {
    pub id: u64,
    pub key: String,
    pub once: bool,
}
#[derive(Debug)]
pub struct Observer {
    pub name: String,
    next_id: u64,
    subscriptions: HashMap<String, Vec<ObserverEntry>>,
}
impl Observer {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            next_id: 1,
            subscriptions: HashMap::new(),
        }
    }
    pub fn subscribe(&mut self, key: &str, once: bool) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let entry = ObserverEntry {
            id,
            key: key.to_string(),
            once,
        };
        self.subscriptions
            .entry(key.to_string())
            .or_default()
            .push(entry);
        id
    }
    pub fn unsubscribe(&mut self, id: u64) -> bool {
        let mut found = false;
        for subs in self.subscriptions.values_mut() {
            let before = subs.len();
            subs.retain(|e| e.id != id);
            if subs.len() < before {
                found = true;
            }
        }
        found
    }
    pub fn watchers_for(&mut self, key: &str) -> Vec<u64> {
        let mut ids = Vec::new();
        let mut once_ids = Vec::new();
        if let Some(subs) = self.subscriptions.get(key) {
            for e in subs {
                ids.push(e.id);
                if e.once {
                    once_ids.push(e.id);
                }
            }
        }
        if let Some(subs) = self.subscriptions.get("*") {
            for e in subs {
                ids.push(e.id);
                if e.once {
                    once_ids.push(e.id);
                }
            }
        }
        for id in once_ids {
            self.unsubscribe(id);
        }
        ids
    }
    pub fn clear_key(&mut self, key: &str) {
        self.subscriptions.remove(key);
    }
    pub fn clear_all(&mut self) {
        self.subscriptions.clear();
    }
    pub fn subscription_count(&self) -> usize {
        self.subscriptions.values().map(Vec::len).sum()
    }
}
