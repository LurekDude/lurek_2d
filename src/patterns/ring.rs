use std::collections::VecDeque;
#[derive(Debug)]
pub struct Ring {
    pub name: String,
    pub capacity: usize,
    entries: VecDeque<RingEntry>,
    next_id: u64,
    pub total_pushed: u64,
}
#[derive(Debug, Clone)]
pub struct RingEntry {
    pub id: u64,
    pub value_f64: Option<f64>,
    pub value_str: Option<String>,
    pub tag: String,
}
impl Ring {
    pub fn new(name: &str, capacity: usize) -> Self {
        Self {
            name: name.to_string(),
            capacity: capacity.max(1),
            entries: VecDeque::with_capacity(capacity.max(1)),
            next_id: 1,
            total_pushed: 0,
        }
    }
    pub fn push_number(&mut self, value: f64, tag: &str) -> u64 {
        self.push_entry(Some(value), None, tag)
    }
    pub fn push_string(&mut self, value: String, tag: &str) -> u64 {
        self.push_entry(None, Some(value), tag)
    }
    fn push_entry(&mut self, vf: Option<f64>, vs: Option<String>, tag: &str) -> u64 {
        if self.entries.len() >= self.capacity {
            self.entries.pop_front();
        }
        let id = self.next_id;
        self.next_id += 1;
        self.total_pushed += 1;
        self.entries.push_back(RingEntry {
            id,
            value_f64: vf,
            value_str: vs,
            tag: tag.to_string(),
        });
        id
    }
    pub fn iter(&self) -> impl Iterator<Item = &RingEntry> {
        self.entries.iter()
    }
    pub fn latest(&self) -> Option<&RingEntry> {
        self.entries.back()
    }
    pub fn oldest(&self) -> Option<&RingEntry> {
        self.entries.front()
    }
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    pub fn is_full(&self) -> bool {
        self.entries.len() >= self.capacity
    }
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    pub fn sum(&self) -> f64 {
        self.entries.iter().filter_map(|e| e.value_f64).sum()
    }
    pub fn average(&self) -> f64 {
        let nums: Vec<f64> = self.entries.iter().filter_map(|e| e.value_f64).collect();
        if nums.is_empty() {
            0.0
        } else {
            nums.iter().sum::<f64>() / nums.len() as f64
        }
    }
}
