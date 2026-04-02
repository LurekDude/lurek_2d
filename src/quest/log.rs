//! Quest log: the player's active quest tracker.

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
#[derive(Debug, Clone, Default)]
pub struct QuestLog {
    /// All known quests indexed by id.
    quests: HashMap<String, Quest>,
    /// Insertion-order list of ids (for stable iteration).
    order: Vec<String>,
}

impl QuestLog {
    /// Create an empty quest log.
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a quest. If a quest with the same id already exists, it is replaced.
    pub fn add_quest(&mut self, quest: Quest) {
        let id = quest.id.clone();
        if !self.quests.contains_key(&id) {
            self.order.push(id.clone());
        }
        self.quests.insert(id, quest);
    }

    /// Get a quest by id.
    pub fn get_quest(&self, id: &str) -> Option<&Quest> {
        self.quests.get(id)
    }

    /// Get a mutable quest by id.
    pub fn get_quest_mut(&mut self, id: &str) -> Option<&mut Quest> {
        self.quests.get_mut(id)
    }

    /// Remove a quest by id.
    pub fn remove_quest(&mut self, id: &str) -> bool {
        if self.quests.remove(id).is_some() {
            self.order.retain(|q| q != id);
            true
        } else {
            false
        }
    }

    /// List ids of all quests in insertion order.
    pub fn quest_ids(&self) -> &[String] {
        &self.order
    }

    /// List ids of all quests with the given status.
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

    /// Total number of registered quests.
    pub fn quest_count(&self) -> usize {
        self.quests.len()
    }

    /// Start quest by id (Available → Active). Returns `false` if not found or wrong state.
    pub fn start_quest(&mut self, id: &str) -> bool {
        if let Some(q) = self.quests.get_mut(id) {
            q.start();
            true
        } else {
            false
        }
    }

    /// Complete quest by id. Returns `false` if not found.
    pub fn complete_quest(&mut self, id: &str) -> bool {
        if let Some(q) = self.quests.get_mut(id) {
            q.complete();
            true
        } else {
            false
        }
    }

    /// Fail a quest by id. Returns `false` if not found.
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
    pub fn active_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Active)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all completed quests.
    pub fn completed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Completed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all failed quests.
    pub fn failed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Failed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    pub fn advance_objective(&mut self, quest_id: &str, obj_id: &str, amount: u32) -> bool {
        if let Some(q) = self.quests.get_mut(quest_id) {
            q.advance_objective(obj_id, amount)
        } else {
            false
        }
    }
}
