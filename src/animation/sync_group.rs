//! Scope: Group animation keys that should advance in lock-step.
//! This file defines a sync-group container over animation resource keys.
//! It owns membership tracking for synchronized animation updates.

use slotmap::DefaultKey;

// ---- Type: AnimSyncGroup ----

/// A named set of animation keys that advance in lock-step.
///
/// Create via [`AnimSyncGroup::new`], add members with [`AnimSyncGroup::add`], then call
/// `tick(dt)` on the Lua side to advance all member animations by the same delta.
#[derive(Debug, Clone, Default)]
pub struct AnimSyncGroup {
    members: Vec<DefaultKey>,
}

impl AnimSyncGroup {
    // ---- Implementation: AnimSyncGroup ----
    /// Creates an empty `AnimSyncGroup`.
    pub fn new() -> Self {
        Self {
            members: Vec::new(),
        }
    }

    /// Adds an animation key to the group.
    ///
    /// If the key is already a member, this is a no-op.
    ///
    /// # Parameters
    /// - `key` â€” [`DefaultKey`] referencing an `Animation` in the engine's resource pool.
    pub fn add(&mut self, key: DefaultKey) {
        if !self.members.contains(&key) {
            self.members.push(key);
        }
    }

    /// Removes an animation key from the group.
    ///
    /// If the key is not a member, this is a no-op.
    ///
    /// # Parameters
    /// - `key` â€” [`DefaultKey`] to remove.
    pub fn remove(&mut self, key: DefaultKey) {
        self.members.retain(|k| *k != key);
    }

    /// Removes all members from the group.
    pub fn clear(&mut self) {
        self.members.clear();
    }

    /// Returns the number of animation keys currently in the group.
    pub fn member_count(&self) -> usize {
        self.members.len()
    }

    /// Returns a reference to the member key slice.
    pub fn members(&self) -> &[DefaultKey] {
        &self.members
    }
}
