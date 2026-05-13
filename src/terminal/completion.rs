pub struct CompletionEngine {
    candidates: Vec<String>,
    cycle_state: Option<(String, usize)>,
}
impl CompletionEngine {
    pub fn new() -> Self {
        Self {
            candidates: Vec::new(),
            cycle_state: None,
        }
    }
    pub fn add_candidate(&mut self, candidate: &str) {
        if !self.candidates.contains(&candidate.to_string()) {
            self.candidates.push(candidate.to_string());
            self.candidates.sort();
        }
    }
    pub fn remove_candidate(&mut self, candidate: &str) {
        self.candidates.retain(|c| c != candidate);
        self.cycle_state = None;
    }
    pub fn clear(&mut self) {
        self.candidates.clear();
        self.cycle_state = None;
    }
    pub fn len(&self) -> usize {
        self.candidates.len()
    }
    pub fn is_empty(&self) -> bool {
        self.candidates.is_empty()
    }
    pub fn completions_for(&self, prefix: &str) -> Vec<String> {
        self.candidates
            .iter()
            .filter(|c| c.starts_with(prefix))
            .cloned()
            .collect()
    }
    pub fn next_completion(&mut self, prefix: &str) -> Option<String> {
        let matches = self.completions_for(prefix);
        if matches.is_empty() {
            self.cycle_state = None;
            return None;
        }
        let idx = match &self.cycle_state {
            Some((last_prefix, last_idx)) if last_prefix == prefix => {
                (last_idx + 1) % matches.len()
            }
            _ => 0,
        };
        self.cycle_state = Some((prefix.to_string(), idx));
        Some(matches[idx].clone())
    }
    pub fn reset(&mut self) {
        self.cycle_state = None;
    }
}
impl Default for CompletionEngine {
    fn default() -> Self {
        Self::new()
    }
}
