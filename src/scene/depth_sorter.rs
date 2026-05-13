const RADIX_THRESHOLD: usize = 256;
const PARALLEL_SORT_THRESHOLD: usize = 10_000;
const DEPTH_OFFSET: f32 = 65_535.0;
#[derive(Clone, Copy)]
pub struct DepthEntry {
    pub depth: f32,
    pub callback_index: usize,
    pub is_object: bool,
}
pub struct DepthSorter {
    entries: Vec<DepthEntry>,
    dirty: bool,
    stable: bool,
}
impl DepthSorter {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            dirty: false,
            stable: false,
        }
    }
    pub fn set_stable(&mut self, val: bool) {
        self.stable = val;
    }
    pub fn is_stable(&self) -> bool {
        self.stable
    }
    pub fn add(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: false,
        });
        self.dirty = true;
    }
    pub fn add_object(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: true,
        });
        self.dirty = true;
    }
    pub fn sort(&mut self) {
        if self.entries.len() > PARALLEL_SORT_THRESHOLD {
            self.sort_parallel();
        } else if !self.stable
            && self.entries.len() >= RADIX_THRESHOLD
            && Self::are_integral_depths(&self.entries)
        {
            self.sort_radix();
        } else if self.stable {
            self.entries.sort_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
        } else {
            self.entries.sort_unstable_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
        }
    }
    pub fn sort_radix(&mut self) -> bool {
        if self.entries.len() < RADIX_THRESHOLD || !Self::are_integral_depths(&self.entries) {
            self.entries.sort_unstable_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
            return false;
        }
        let n = self.entries.len();
        let mut keyed: Vec<(u32, usize)> = self
            .entries
            .iter()
            .enumerate()
            .map(|(i, e)| {
                let shifted = (e.depth + DEPTH_OFFSET).clamp(0.0, 2.0 * DEPTH_OFFSET) as u32;
                (shifted, i)
            })
            .collect();
        radix_pass_8bit(&mut keyed, 0);
        radix_pass_8bit(&mut keyed, 8);
        radix_pass_8bit(&mut keyed, 16);
        radix_pass_8bit(&mut keyed, 24);
        let old: Vec<DepthEntry> = std::mem::replace(
            &mut self.entries,
            vec![
                DepthEntry {
                    depth: 0.0,
                    callback_index: 0,
                    is_object: false
                };
                n
            ],
        );
        for (new_pos, (_, orig_idx)) in keyed.iter().enumerate() {
            self.entries[new_pos] = old[*orig_idx];
        }
        self.dirty = false;
        true
    }
    pub fn sort_parallel(&mut self) {
        use rayon::prelude::*;
        self.entries.par_sort_unstable_by(|a, b| {
            a.depth
                .partial_cmp(&b.depth)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        self.dirty = false;
    }
    pub fn sorted_entries(&mut self) -> &[DepthEntry] {
        if self.dirty {
            self.sort();
        }
        &self.entries
    }
    pub fn clear(&mut self) {
        self.entries.clear();
        self.dirty = false;
    }
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
    fn are_integral_depths(entries: &[DepthEntry]) -> bool {
        entries.iter().all(|e| e.depth.fract().abs() < 1e-4)
    }
}
fn radix_pass_8bit(data: &mut Vec<(u32, usize)>, shift: u32) {
    const BUCKETS: usize = 256;
    let mut counts = [0usize; BUCKETS];
    for &(key, _) in data.iter() {
        let bucket = ((key >> shift) & 0xFF) as usize;
        counts[bucket] += 1;
    }
    let mut offsets = [0usize; BUCKETS];
    let mut total = 0;
    for i in 0..BUCKETS {
        offsets[i] = total;
        total += counts[i];
    }
    let mut output = vec![(0u32, 0usize); data.len()];
    for &(key, idx) in data.iter() {
        let bucket = ((key >> shift) & 0xFF) as usize;
        output[offsets[bucket]] = (key, idx);
        offsets[bucket] += 1;
    }
    *data = output;
}
impl Default for DepthSorter {
    fn default() -> Self {
        Self::new()
    }
}
