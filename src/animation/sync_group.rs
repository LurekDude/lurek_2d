//! Group animation keys that should advance in lock-step.

use slotmap::DefaultKey;

// ---- Type: AnimSyncGroup ----

/// A named set of animation keys that advance in lock-step.
#[derive(Debug, Clone, Default)]
pub struct AnimSyncGroup {
    members: Vec<DefaultKey>,
}

impl AnimSyncGroup {
    // ---- Implementation: AnimSyncGroup ----
    /// Create an empty `AnimSyncGroup`.
    pub fn new() -> Self {
        Self {
            members: Vec::new(),
        }
    }

    /// Add an animation key to the group.
    pub fn add(&mut self, key: DefaultKey) {
        if !self.members.contains(&key) {
            self.members.push(key);
        }
    }

    /// Remove an animation key from the group.
    pub fn remove(&mut self, key: DefaultKey) {
        self.members.retain(|k| *k != key);
    }

    /// Remove all members from the group.
    pub fn clear(&mut self) {
        self.members.clear();
    }

    /// Return the number of animation keys currently in the group.
    pub fn member_count(&self) -> usize {
        self.members.len()
    }

    /// Return a reference to the member key slice.
    pub fn members(&self) -> &[DefaultKey] {
        &self.members
    }
}
