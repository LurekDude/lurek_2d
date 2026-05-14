
/// Capacity-bounded pool tracking idle and active object ids.
#[derive(Debug)]
pub struct ObjectPool {
    /// Debug name.
    pub name: String,
    /// Maximum live objects; `0` means unbounded.
    pub capacity: usize,
    /// Minimum idle objects to maintain; informational only.
    pub min_idle: usize,
    /// Free ids available for re-use.
    idle: Vec<u64>,
    /// Ids currently checked out.
    active: std::collections::HashSet<u64>,
    /// Next fresh id to allocate.
    next_id: u64,
}
/// All methods for `ObjectPool`.
impl ObjectPool {
    /// Create a pool named `name` with `capacity` limit (`0` = unbounded).
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
    /// Acquire an id from the idle list or allocate a fresh one; return `None` when capacity is full.
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
    /// Return `id` to the idle list; return false when `id` was not active.
    pub fn release(&mut self, id: u64) -> bool {
        if self.active.remove(&id) {
            self.idle.push(id);
            true
        } else {
            false
        }
    }
    /// Return all active ids to the idle list and return the list of released ids.
    pub fn release_all(&mut self) -> Vec<u64> {
        let ids: Vec<u64> = self.active.drain().collect();
        self.idle.extend(ids.iter().copied());
        ids
    }
    /// Allocate up to `count` idle ids, respecting capacity; return the newly allocated ids.
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
    /// Return the number of idle (available) ids.
    pub fn idle_count(&self) -> usize {
        self.idle.len()
    }
    /// Return the number of currently active (checked-out) ids.
    pub fn active_count(&self) -> usize {
        self.active.len()
    }
    /// Return the total number of tracked ids (idle + active).
    pub fn total_count(&self) -> usize {
        self.idle.len() + self.active.len()
    }
    /// Return true when `id` is currently active.
    pub fn is_active(&self, id: u64) -> bool {
        self.active.contains(&id)
    }
}
