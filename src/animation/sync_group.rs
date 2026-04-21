//! Named animation synchronisation groups.
//!
//! An [`AnimSyncGroup`] holds a collection of [`Animation`](crate::animation::Animation)
//! keys (slot-map `DefaultKey`) that should all receive the same [`tick`](no-link) call
//! together.  The group itself does **not** own the animations â€” it only stores the keys.
//! Ticking is performed in the Lua API layer so that it can borrow `SharedState`.

use slotmap::DefaultKey;

/// A named set of animation keys that advance in lock-step.
///
/// Create via [`AnimSyncGroup::new`], add members with [`AnimSyncGroup::add`], then call
/// `tick(dt)` on the Lua side to advance all member animations by the same delta.
#[derive(Debug, Clone, Default)]
pub struct AnimSyncGroup {
    members: Vec<DefaultKey>,
}

impl AnimSyncGroup {
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
