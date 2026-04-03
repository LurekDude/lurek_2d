//! Quest log: the player's active quest tracker.
//!
//! This module is part of Luna2D's `quest` subsystem and provides the implementation
//! details for log-related operations and data management.
//! Key types exported from this module: `QuestLog`.
//! Primary functions: `new()`, `add_quest()`, `get_quest()`, `get_quest_mut()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use super::quest::Quest;
use super::status::QuestStatus;

// ──────────────────────────────────────────────────────────────────────────────
// QuestLog
// ──────────────────────────────────────────────────────────────────────────────

/// Registry of all quests for a game session.
///
/// Quests are stored by their id. Active/completed/available sets are derived
/// by filtering on status rather than maintaining parallel lists.
///
/// # Fields
/// - `quests` — `HashMap<String`.
/// - `order` — `Vec<String>`.
#[derive(Debug, Clone, Default)]
pub struct QuestLog {
    /// All known quests indexed by id.
    quests: HashMap<String, Quest>,
    /// Insertion-order list of ids (for stable iteration).
    order: Vec<String>,
}

impl QuestLog {
    /// Create an empty quest log. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a quest. If a quest with the same id already exists, it is replaced.
    ///
    /// # Parameters
    /// - `quest` — `Quest`.
    pub fn add_quest(&mut self, quest: Quest) {
        let id = quest.id.clone();
        if !self.quests.contains_key(&id) {
            self.order.push(id.clone());
        }
        self.quests.insert(id, quest);
    }

    /// Get a quest by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&Quest>`.
    pub fn get_quest(&self, id: &str) -> Option<&Quest> {
        self.quests.get(id)
    }

    /// Get a mutable quest by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Quest>`.
    pub fn get_quest_mut(&mut self, id: &str) -> Option<&mut Quest> {
        self.quests.get_mut(id)
    }

    /// Remove a quest by id. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_quest(&mut self, id: &str) -> bool {
        if self.quests.remove(id).is_some() {
            self.order.retain(|q| q != id);
            true
        } else {
            false
        }
    }

    /// List ids of all quests in insertion order.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn quest_ids(&self) -> &[String] {
        &self.order
    }

    /// List ids of all quests with the given status.
    ///
    /// # Parameters
    /// - `status` — `&QuestStatus`.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn quests_with_status(&self, status: &QuestStatus) -> Vec<&str> {
        self.order
            .iter()
            .filter(|id| {
                self.quests
                    .get(id.as_str())
                    .map(|q| &q.status == status)
                    .unwrap_or(false)
            })
            .map(String::as_str)
            .collect()
    }

    /// Total number of registered quests. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn quest_count(&self) -> usize {
        self.quests.len()
    }

    /// Start quest by id (Available → Active). Returns `false` if not found or wrong state.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn start_quest(&mut self, id: &str) -> bool {
        if let Some(q) = self.quests.get_mut(id) {
            q.start();
            true
        } else {
            false
        }
    }

    /// Complete quest by id. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn complete_quest(&mut self, id: &str) -> bool {
        if let Some(q) = self.quests.get_mut(id) {
            q.complete();
            true
        } else {
            false
        }
    }

    /// Fail a quest by id. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn fail_quest(&mut self, id: &str) -> bool {
        if let Some(q) = self.quests.get_mut(id) {
            q.fail();
            true
        } else {
            false
        }
    }

    /// Advance an objective in a specific quest. Returns `false` if quest or objective not found.
    /// Convenience: IDs of all active quests.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn active_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Active)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all completed quests.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn completed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Completed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all failed quests. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn failed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Failed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Advance the named objective by the given amount, completing it if the goal is reached.
    ///
    /// # Parameters
    /// - `quest_id` — `&str`.
    /// - `obj_id` — `&str`.
    /// - `amount` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn advance_objective(&mut self, quest_id: &str, obj_id: &str, amount: u32) -> bool {
        if let Some(q) = self.quests.get_mut(quest_id) {
            q.advance_objective(obj_id, amount)
        } else {
            false
        }
    }
}
