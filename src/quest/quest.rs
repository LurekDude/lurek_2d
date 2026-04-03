//! Quest definition with stages, objectives, and journal.
//!
//! This module is part of Luna2D's `quest` subsystem and provides the implementation
//! details for quest-related operations and data management.
//! Key types exported from this module: `Quest`.
//! Primary functions: `new()`, `add_stage()`, `get_current_stage()`, `get_stage()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use super::journal::JournalEntry;
use super::objective::QuestStage;
use super::status::{ObjectiveStatus, QuestStatus};

// ──────────────────────────────────────────────────────────────────────────────
// Quest
// ──────────────────────────────────────────────────────────────────────────────

/// A quest with stages, objectives, and a journal.
///
/// Stages are ordered; the quest advances through them as the game logic
/// calls `next_stage()` or `goto_stage()`.
///
/// # Fields
/// - `id` — `String`.
/// - `title` — `String`.
/// - `description` — `String`.
/// - `status` — `QuestStatus`.
/// - `stages` — `Vec<QuestStage>`.
/// - `current_stage` — `usize`.
/// - `journal` — `Vec<JournalEntry>`.
/// - `metadata` — `HashMap<String`.
/// - `visible` — `bool`.
/// - `reward` — `String`.
/// - `journal_counter` — `u32`.
#[derive(Debug, Clone)]
pub struct Quest {
    /// Unique identifier.
    pub id: String,
    /// Display title.
    pub title: String,
    /// Multi-line description shown to the player.
    pub description: String,
    /// Current lifecycle status.
    pub status: QuestStatus,
    /// Ordered stage list.
    pub stages: Vec<QuestStage>,
    /// Index into `stages` of the active stage (0-based).
    pub current_stage: usize,
    /// Journal entries (append-only).
    pub journal: Vec<JournalEntry>,
    /// Arbitrary key-value string metadata (e.g., `giver`, `location`, `category`).
    pub metadata: HashMap<String, String>,
    /// Whether the quest is visible in the quest log.
    pub visible: bool,
    /// Reward description (informational only; fulfilment is game-side).
    pub reward: String,
    /// Internal counter for journal entry indices.
    journal_counter: u32,
}

impl Quest {
    /// Create a new quest in the `Available` state.
    ///
    /// # Parameters
    /// - `id` — `impl Into<String>`.
    /// - `itle` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: impl Into<String>, title: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            title: title.into(),
            description: String::new(),
            status: QuestStatus::Available,
            stages: Vec::new(),
            current_stage: 0,
            journal: Vec::new(),
            metadata: HashMap::new(),
            visible: true,
            reward: String::new(),
            journal_counter: 0,
        }
    }

    /// Add a stage to the quest (in order).
    ///
    /// # Parameters
    /// - `stage` — `QuestStage`.
    pub fn add_stage(&mut self, stage: QuestStage) {
        self.stages.push(stage);
    }

    /// Get the currently active stage, if any. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Option<&QuestStage>`.
    pub fn get_current_stage(&self) -> Option<&QuestStage> {
        self.stages.get(self.current_stage)
    }

    /// Get a stage by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&QuestStage>`.
    pub fn get_stage(&self, id: &str) -> Option<&QuestStage> {
        self.stages.iter().find(|s| s.id == id)
    }

    /// Get a mutable stage by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut QuestStage>`.
    pub fn get_stage_mut(&mut self, id: &str) -> Option<&mut QuestStage> {
        self.stages.iter_mut().find(|s| s.id == id)
    }

    /// Advance to the next stage. Returns `true` on success, `false` if already at last stage.
    ///
    /// # Returns
    /// `bool`.
    pub fn next_stage(&mut self) -> bool {
        if self.current_stage + 1 < self.stages.len() {
            self.current_stage += 1;
            true
        } else {
            false
        }
    }

    /// Jump to the stage with the given id. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn goto_stage(&mut self, id: &str) -> bool {
        for (i, stage) in self.stages.iter().enumerate() {
            if stage.id == id {
                self.current_stage = i;
                return true;
            }
        }
        false
    }

    /// Advance progress on an objective across all stages. Returns `false` if objective not found.
    ///
    /// # Parameters
    /// - `obj_id` — `&str`.
    /// - `amount` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn advance_objective(&mut self, obj_id: &str, amount: u32) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.get_objective_mut(obj_id) {
                obj.advance(amount);
                return true;
            }
        }
        false
    }

    /// Set status of an objective across all stages. Returns `false` if not found.
    ///
    /// # Parameters
    /// - `obj_id` — `&str`.
    /// - `status` — `ObjectiveStatus`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_objective_status(&mut self, obj_id: &str, status: ObjectiveStatus) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.get_objective_mut(obj_id) {
                obj.status = status;
                return true;
            }
        }
        false
    }

    /// Start the quest (transition to Active). Consult the module-level documentation for the broader usage context and preconditions.
    pub fn start(&mut self) {
        if self.status == QuestStatus::Available {
            self.status = QuestStatus::Active;
        }
    }

    /// Mark the quest as completed. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn complete(&mut self) {
        self.status = QuestStatus::Completed;
    }

    /// Mark the quest as failed. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn fail(&mut self) {
        self.status = QuestStatus::Failed;
    }

    /// Append a journal entry. Returns the entry's index.
    ///
    /// # Parameters
    /// - `ext` — `impl Into<String>`.
    /// - `ag` — `impl Into<String>`.
    ///
    /// # Returns
    /// `u32`.
    pub fn add_journal_entry(&mut self, text: impl Into<String>, tag: impl Into<String>) -> u32 {
        let idx = self.journal_counter;
        self.journal.push(JournalEntry {
            index: idx,
            text: text.into(),
            tag: tag.into(),
        });
        self.journal_counter += 1;
        idx
    }

    /// Set a metadata value. Replaces the current meta value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `key` — `impl Into<String>`.
    /// - `value` — `impl Into<String>`.
    pub fn set_meta(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }

    /// Get a metadata value. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Returns `true` if all mandatory objectives in all stages are complete.
    /// Returns percentage of mandatory objectives that are Done across all stages (0.0–100.0).
    ///
    /// # Returns
    /// `f64`.
    pub fn completion_percent(&self) -> f64 {
        let all_objs: Vec<_> = self.stages.iter()
            .flat_map(|s| s.objectives.iter())
            .filter(|o| o.mandatory)
            .collect();
        if all_objs.is_empty() { return 100.0; }
        let done = all_objs.iter().filter(|o| o.status == ObjectiveStatus::Done).count();
        done as f64 / all_objs.len() as f64 * 100.0
    }

    /// Returns the IDs of all objectives currently Active across all stages.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.stages.iter()
            .flat_map(|s| s.objectives.iter())
            .filter(|o| o.status == ObjectiveStatus::Active)
            .map(|o| o.id.clone())
            .collect()
    }

    /// Reset an objective back to Active (in progress). Returns false if not found.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.objectives.iter_mut().find(|o| o.id == id) {
                obj.status = ObjectiveStatus::Active;
                return true;
            }
        }
        false
    }

    /// Return `true` if every objective in the quest is complete.
    ///
    /// # Returns
    /// `bool`.
    pub fn all_objectives_complete(&self) -> bool {
        self.stages.iter().all(|s| s.is_complete())
    }
}
