//! Quest and objective tracking system for Luna2D games.
//!
//! Provides `Quest`, `Objective`, `QuestStage`, `JournalEntry`, and `QuestLog`
//! for building RPG-style quest systems with stages, conditions, and journal notes.

use std::collections::HashMap;

// ──────────────────────────────────────────────────────────────────────────────
// QuestStatus
// ──────────────────────────────────────────────────────────────────────────────

/// Lifecycle state of a quest.
#[derive(Debug, Clone, PartialEq)]
pub enum QuestStatus {
    /// Quest is available but not yet accepted.
    Available,
    /// Quest has been accepted and is in progress.
    Active,
    /// All required objectives are complete.
    Completed,
    /// Quest was abandoned or failed.
    Failed,
}

impl QuestStatus {
    /// Parse a status string.
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "available" => Some(Self::Available),
            "active" => Some(Self::Active),
            "completed" => Some(Self::Completed),
            "failed" => Some(Self::Failed),
            _ => None,
        }
    }

    /// Convert to the canonical string representation.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Available => "available",
            Self::Active => "active",
            Self::Completed => "completed",
            Self::Failed => "failed",
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// ObjectiveStatus
// ──────────────────────────────────────────────────────────────────────────────

/// Lifecycle state of a single objective.
#[derive(Debug, Clone, PartialEq)]
pub enum ObjectiveStatus {
    /// Not yet started.
    Pending,
    /// In progress.
    Active,
    /// Successfully completed.
    Done,
    /// Skipped (optional objectives can be skipped).
    Skipped,
    /// Failed.
    Failed,
}

impl ObjectiveStatus {
    /// Parse a status string.
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "pending" => Some(Self::Pending),
            "active" => Some(Self::Active),
            "done" => Some(Self::Done),
            "skipped" => Some(Self::Skipped),
            "failed" => Some(Self::Failed),
            _ => None,
        }
    }

    /// Convert to canonical string form.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::Active => "active",
            Self::Done => "done",
            Self::Skipped => "skipped",
            Self::Failed => "failed",
        }
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// Objective
// ──────────────────────────────────────────────────────────────────────────────

/// A single trackable task within a quest.
///
/// Supports count-based progress (`current`/`required`) and optional tagging.
#[derive(Debug, Clone)]
pub struct Objective {
    /// Unique identifier within the parent quest.
    pub id: String,
    /// Human-readable display text.
    pub description: String,
    /// Current progress count.
    pub current: u32,
    /// Required count to mark as done.
    pub required: u32,
    /// Whether this objective must be completed (true = required, false = optional).
    pub mandatory: bool,
    /// Current lifecycle status.
    pub status: ObjectiveStatus,
    /// Arbitrary tags for filtering (e.g., `"kill"`, `"collect"`, `"talk"`).
    pub tags: Vec<String>,
    /// Whether the objective is shown to the player.
    pub visible: bool,
}

impl Objective {
    /// Create a new objective with 0/`required` progress.
    pub fn new(id: impl Into<String>, description: impl Into<String>, required: u32) -> Self {
        Self {
            id: id.into(),
            description: description.into(),
            current: 0,
            required,
            mandatory: true,
            status: ObjectiveStatus::Pending,
            tags: Vec::new(),
            visible: true,
        }
    }

    /// Advance progress by `amount`. Automatically marks the objective as Done
    /// when `current >= required`. Returns the new progress value.
    pub fn advance(&mut self, amount: u32) -> u32 {
        if self.status == ObjectiveStatus::Done || self.status == ObjectiveStatus::Failed {
            return self.current;
        }
        self.current = self.current.saturating_add(amount).min(self.required);
        if self.current >= self.required {
            self.status = ObjectiveStatus::Done;
        } else {
            self.status = ObjectiveStatus::Active;
        }
        self.current
    }

    /// Set progress directly. Clamps to [0, required].
    pub fn set_progress(&mut self, value: u32) {
        self.current = value.min(self.required);
        if self.current >= self.required {
            self.status = ObjectiveStatus::Done;
        } else if self.current > 0 {
            self.status = ObjectiveStatus::Active;
        } else {
            self.status = ObjectiveStatus::Pending;
        }
    }

    /// Returns `true` if this objective is considered complete (Done or Skipped).
    pub fn is_complete(&self) -> bool {
        self.status == ObjectiveStatus::Done || self.status == ObjectiveStatus::Skipped
    }

    /// Add a tag. Has no effect if already present.
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        let t = tag.into();
        if !self.tags.contains(&t) {
            self.tags.push(t);
        }
    }

    /// Returns `true` if the given tag is present.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// QuestStage
// ──────────────────────────────────────────────────────────────────────────────

/// A named group of objectives that represent one phase of a quest.
#[derive(Debug, Clone)]
pub struct QuestStage {
    /// Unique stage identifier.
    pub id: String,
    /// Display name for this stage.
    pub name: String,
    /// Objectives belonging to this stage (ordered).
    pub objectives: Vec<Objective>,
}

impl QuestStage {
    /// Create a new empty stage.
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            objectives: Vec::new(),
        }
    }

    /// Add an objective to this stage.
    pub fn add_objective(&mut self, obj: Objective) {
        self.objectives.push(obj);
    }

    /// Get an objective by id.
    pub fn get_objective(&self, id: &str) -> Option<&Objective> {
        self.objectives.iter().find(|o| o.id == id)
    }

    /// Get a mutable objective by id.
    pub fn get_objective_mut(&mut self, id: &str) -> Option<&mut Objective> {
        self.objectives.iter_mut().find(|o| o.id == id)
    }

    /// Returns `true` when all mandatory objectives in this stage are complete.
    pub fn is_complete(&self) -> bool {
        self.objectives
            .iter()
            .filter(|o| o.mandatory)
            .all(|o| o.is_complete())
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// JournalEntry
// ──────────────────────────────────────────────────────────────────────────────

/// A timestamped text entry in a quest's journal.
#[derive(Debug, Clone)]
pub struct JournalEntry {
    /// Monotone sequence number (assigned by `Quest`).
    pub index: u32,
    /// Text body of the entry.
    pub text: String,
    /// Optional tag (e.g., `"discovered"`, `"completed"`, `"failed"`).
    pub tag: String,
}

// ──────────────────────────────────────────────────────────────────────────────
// Quest
// ──────────────────────────────────────────────────────────────────────────────

/// A quest with stages, objectives, and a journal.
///
/// Stages are ordered; the quest advances through them as the game logic
/// calls `next_stage()` or `goto_stage()`.
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
    pub fn add_stage(&mut self, stage: QuestStage) {
        self.stages.push(stage);
    }

    /// Get the currently active stage, if any.
    pub fn get_current_stage(&self) -> Option<&QuestStage> {
        self.stages.get(self.current_stage)
    }

    /// Get a stage by id.
    pub fn get_stage(&self, id: &str) -> Option<&QuestStage> {
        self.stages.iter().find(|s| s.id == id)
    }

    /// Get a mutable stage by id.
    pub fn get_stage_mut(&mut self, id: &str) -> Option<&mut QuestStage> {
        self.stages.iter_mut().find(|s| s.id == id)
    }

    /// Advance to the next stage. Returns `true` on success, `false` if already at last stage.
    pub fn next_stage(&mut self) -> bool {
        if self.current_stage + 1 < self.stages.len() {
            self.current_stage += 1;
            true
        } else {
            false
        }
    }

    /// Jump to the stage with the given id. Returns `false` if not found.
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
    pub fn set_objective_status(&mut self, obj_id: &str, status: ObjectiveStatus) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.get_objective_mut(obj_id) {
                obj.status = status;
                return true;
            }
        }
        false
    }

    /// Start the quest (transition to Active).
    pub fn start(&mut self) {
        if self.status == QuestStatus::Available {
            self.status = QuestStatus::Active;
        }
    }

    /// Mark the quest as completed.
    pub fn complete(&mut self) {
        self.status = QuestStatus::Completed;
    }

    /// Mark the quest as failed.
    pub fn fail(&mut self) {
        self.status = QuestStatus::Failed;
    }

    /// Append a journal entry. Returns the entry's index.
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

    /// Set a metadata value.
    pub fn set_meta(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }

    /// Get a metadata value.
    pub fn get_meta(&self, key: &str) -> Option<&str> {
        self.metadata.get(key).map(String::as_str)
    }

    /// Returns `true` if all mandatory objectives in all stages are complete.
    /// Returns percentage of mandatory objectives that are Done across all stages (0.0–100.0).
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
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.stages.iter()
            .flat_map(|s| s.objectives.iter())
            .filter(|o| o.status == ObjectiveStatus::Active)
            .map(|o| o.id.clone())
            .collect()
    }

    /// Reset an objective back to Active (in progress). Returns false if not found.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.objectives.iter_mut().find(|o| o.id == id) {
                obj.status = ObjectiveStatus::Active;
                return true;
            }
        }
        false
    }

    pub fn all_objectives_complete(&self) -> bool {
        self.stages.iter().all(|s| s.is_complete())
    }
}

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

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn objective_advance_completes() {
        let mut obj = Objective::new("kill_wolves", "Kill 3 wolves", 3);
        obj.advance(2);
        assert_eq!(obj.status, ObjectiveStatus::Active);
        obj.advance(1);
        assert_eq!(obj.status, ObjectiveStatus::Done);
    }

    #[test]
    fn objective_advance_clamps() {
        let mut obj = Objective::new("fetch", "Fetch 5 apples", 5);
        obj.advance(10);
        assert_eq!(obj.current, 5);
        assert_eq!(obj.status, ObjectiveStatus::Done);
    }

    #[test]
    fn quest_start_and_complete() {
        let mut q = Quest::new("tutorial", "Tutorial Quest");
        assert_eq!(q.status, QuestStatus::Available);
        q.start();
        assert_eq!(q.status, QuestStatus::Active);
        q.complete();
        assert_eq!(q.status, QuestStatus::Completed);
    }

    #[test]
    fn quest_stages_and_next() {
        let mut q = Quest::new("main", "Main Quest");
        q.add_stage(QuestStage::new("s1", "Stage 1"));
        q.add_stage(QuestStage::new("s2", "Stage 2"));
        assert_eq!(q.current_stage, 0);
        assert!(q.next_stage());
        assert_eq!(q.current_stage, 1);
        assert!(!q.next_stage()); // already at last
    }

    #[test]
    fn quest_log_start_fail() {
        let mut log = QuestLog::new();
        let q = Quest::new("q1", "Quest 1");
        log.add_quest(q);
        log.start_quest("q1");
        assert_eq!(log.get_quest("q1").unwrap().status, QuestStatus::Active);
        log.fail_quest("q1");
        assert_eq!(log.get_quest("q1").unwrap().status, QuestStatus::Failed);
    }
}
