#[derive(Debug, Clone)]
pub struct PriorityItem {
    pub id: u64,
    pub priority: i64,
    pub label: String,
    pub seq: u64,
}
#[derive(Debug)]
pub struct PriorityQueue {
    pub name: String,
    next_id: u64,
    next_seq: u64,
    items: Vec<PriorityItem>,
}
impl PriorityQueue {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            next_id: 1,
            next_seq: 0,
            items: Vec::new(),
        }
    }
    pub fn push(&mut self, priority: i64, label: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        let seq = self.next_seq;
        self.next_seq += 1;
        let item = PriorityItem {
            id,
            priority,
            label: label.to_string(),
            seq,
        };
        let pos = self
            .items
            .partition_point(|x| x.priority > priority || (x.priority == priority && x.seq < seq));
        self.items.insert(pos, item);
        id
    }
    pub fn peek(&self) -> Option<&PriorityItem> {
        self.items.first()
    }
    pub fn pop(&mut self) -> Option<(u64, i64)> {
        if self.items.is_empty() {
            return None;
        }
        let item = self.items.remove(0);
        Some((item.id, item.priority))
    }
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.items.len();
        self.items.retain(|i| i.id != id);
        self.items.len() < before
    }
    pub fn len(&self) -> usize {
        self.items.len()
    }
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }
    pub fn items(&self) -> &[PriorityItem] {
        &self.items
    }
    pub fn clear(&mut self) {
        self.items.clear();
    }
}
