#[derive(Debug)]
pub struct ObjectPool {
    pub name: String,
    pub capacity: usize,
    pub min_idle: usize,
    idle: Vec<u64>,
    active: std::collections::HashSet<u64>,
    next_id: u64,
}
impl ObjectPool {
    pub fn new(name: &str, capacity: usize) -> Self {
        Self {
            name: name.to_string(),
            capacity,
            min_idle: 0,
            idle: Vec::new(),
            active: std::collections::HashSet::new(),
            next_id: 1,
        }
    }
    pub fn acquire(&mut self) -> Option<u64> {
        if let Some(id) = self.idle.pop() {
            self.active.insert(id);
            return Some(id);
        }
        let total = self.idle.len() + self.active.len();
        if self.capacity == 0 || total < self.capacity {
            let id = self.next_id;
            self.next_id += 1;
            self.active.insert(id);
            return Some(id);
        }
        None
    }
    pub fn release(&mut self, id: u64) -> bool {
        if self.active.remove(&id) {
            self.idle.push(id);
            true
        } else {
            false
        }
    }
    pub fn release_all(&mut self) -> Vec<u64> {
        let ids: Vec<u64> = self.active.drain().collect();
        self.idle.extend(ids.iter().copied());
        ids
    }
    pub fn prewarm(&mut self, count: usize) -> Vec<u64> {
        let mut new_ids = Vec::new();
        while self.idle.len() + self.active.len() < count {
            if self.capacity > 0 && self.idle.len() + self.active.len() >= self.capacity {
                break;
            }
            let id = self.next_id;
            self.next_id += 1;
            self.idle.push(id);
            new_ids.push(id);
        }
        new_ids
    }
    pub fn idle_count(&self) -> usize {
        self.idle.len()
    }
    pub fn active_count(&self) -> usize {
        self.active.len()
    }
    pub fn total_count(&self) -> usize {
        self.idle.len() + self.active.len()
    }
    pub fn is_active(&self, id: u64) -> bool {
        self.active.contains(&id)
    }
}
