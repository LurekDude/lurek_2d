
use slotmap::DefaultKey;
/// Set of animation keys that should stay in sync.
#[derive(Debug, Clone, Default)]
pub struct AnimSyncGroup {
    /// Registered members.
    members: Vec<DefaultKey>,
}
impl AnimSyncGroup {
    /// Create an empty sync group.
    pub fn new() -> Self {
        Self {
            members: Vec::new(),
        }
    }
    /// Add `key` when it is not already present.
    pub fn add(&mut self, key: DefaultKey) {
        if !self.members.contains(&key) {
            self.members.push(key);
        }
    }
    /// Remove `key` from the group.
    pub fn remove(&mut self, key: DefaultKey) {
        self.members.retain(|k| *k != key);
    }
    /// Remove all members.
    pub fn clear(&mut self) {
        self.members.clear();
    }
    /// Return the number of members.
    pub fn member_count(&self) -> usize {
        self.members.len()
    }
    /// Return the member slice.
    pub fn members(&self) -> &[DefaultKey] {
        &self.members
    }
}
