//! Tab-completion engine for the terminal emulator. Owns the sorted candidate
//! list and prefix-cycling state. Does not own key-event routing or history;
//! callers feed candidates, then call `next_completion` on each Tab press.

/// Sorted candidate store with prefix-based cycling for terminal Tab completion.
pub struct CompletionEngine {
    /// Alphabetically sorted list of registered completion strings.
    candidates: Vec<String>,
    /// Active cycle: `(prefix, current_index)`, reset when prefix changes or cycling ends.
    cycle_state: Option<(String, usize)>,
}

impl CompletionEngine {
    /// Create an empty `CompletionEngine` with no candidates and no active cycle.
    pub fn new() -> Self {
        Self {
            candidates: Vec::new(),
            cycle_state: None,
        }
    }

    /// Insert `candidate` into the sorted list if not already present.
    pub fn add_candidate(&mut self, candidate: &str) {
        if !self.candidates.contains(&candidate.to_string()) {
            self.candidates.push(candidate.to_string());
            self.candidates.sort();
        }
    }

    /// Remove `candidate` from the list and reset any active cycle.
    pub fn remove_candidate(&mut self, candidate: &str) {
        self.candidates.retain(|c| c != candidate);
        self.cycle_state = None;
    }

    /// Remove all candidates and reset the cycle state.
    pub fn clear(&mut self) {
        self.candidates.clear();
        self.cycle_state = None;
    }

    /// Return the number of registered candidates.
    pub fn len(&self) -> usize {
        self.candidates.len()
    }

    /// Return `true` when no candidates are registered.
    pub fn is_empty(&self) -> bool {
        self.candidates.is_empty()
    }

    /// Return all candidates that start with `prefix`, in sorted order.
    pub fn completions_for(&self, prefix: &str) -> Vec<String> {
        self.candidates
            .iter()
            .filter(|c| c.starts_with(prefix))
            .cloned()
            .collect()
    }

    /// Advance to the next candidate matching `prefix` and return it; returns `None` when no matches exist.
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

    /// Reset the cycling position without clearing candidates.
    pub fn reset(&mut self) {
        self.cycle_state = None;
    }
}

/// `Default` implementation for `CompletionEngine`.
impl Default for CompletionEngine {
    fn default() -> Self {
        Self::new()
    }
}

