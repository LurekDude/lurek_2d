#[derive(Debug, Clone)]
pub struct WeightedEntry {
    pub id: u64,
    pub weight: f64,
    pub label: String,
}
#[derive(Debug, Clone)]
pub struct WeightedRandom {
    entries: Vec<WeightedEntry>,
    next_id: u64,
    pub revision: u64,
}
impl WeightedRandom {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            next_id: 1,
            revision: 0,
        }
    }
    pub fn add(&mut self, weight: f64, label: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(WeightedEntry {
            id,
            weight: weight.max(0.0),
            label: label.to_string(),
        });
        self.revision += 1;
        id
    }
    pub fn remove(&mut self, id: u64) -> bool {
        if let Some(pos) = self.entries.iter().position(|e| e.id == id) {
            self.entries.swap_remove(pos);
            self.revision += 1;
            true
        } else {
            false
        }
    }
    pub fn set_weight(&mut self, id: u64, weight: f64) -> bool {
        if let Some(e) = self.entries.iter_mut().find(|e| e.id == id) {
            e.weight = weight.max(0.0);
            self.revision += 1;
            true
        } else {
            false
        }
    }
    pub fn total_weight(&self) -> f64 {
        self.entries.iter().map(|e| e.weight).sum()
    }
    pub fn pick(&self, sample: f64) -> Option<u64> {
        let total = self.total_weight();
        if total <= 0.0 {
            return None;
        }
        let target = (sample.clamp(0.0, 1.0) * total).min(total - f64::EPSILON);
        let mut acc = 0.0;
        for e in &self.entries {
            acc += e.weight;
            if target < acc {
                return Some(e.id);
            }
        }
        self.entries.last().map(|e| e.id)
    }
    pub fn pick_n(&self, count: usize, samples: &[f64]) -> Vec<u64> {
        if count == 0 || self.entries.is_empty() {
            return Vec::new();
        }
        let mut scratch: Vec<(u64, f64)> = self.entries.iter().map(|e| (e.id, e.weight)).collect();
        let mut out = Vec::with_capacity(count.min(scratch.len()));
        for &s in samples.iter().take(count) {
            let total: f64 = scratch.iter().map(|(_, w)| w).sum();
            if total <= 0.0 {
                break;
            }
            let target = (s.clamp(0.0, 1.0) * total).min(total - f64::EPSILON);
            let mut acc = 0.0;
            let mut chosen = scratch.len() - 1;
            for (i, &(_, w)) in scratch.iter().enumerate() {
                acc += w;
                if target < acc {
                    chosen = i;
                    break;
                }
            }
            let (id, _) = scratch.swap_remove(chosen);
            out.push(id);
        }
        out
    }
    pub fn entries(&self) -> &[WeightedEntry] {
        &self.entries
    }
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    pub fn get(&self, id: u64) -> Option<&WeightedEntry> {
        self.entries.iter().find(|e| e.id == id)
    }
    pub fn clear(&mut self) {
        self.entries.clear();
        self.revision += 1;
    }
}
impl Default for WeightedRandom {
    fn default() -> Self {
        Self::new()
    }
}
