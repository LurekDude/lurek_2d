//! Quest objectives and quest stages.
//!
//! This module is part of Luna2D's `quest` subsystem and provides the implementation
//! details for objective-related operations and data management.
//! Key types exported from this module: `Objective`, `QuestStage`.
//! Primary functions: `new()`, `advance()`, `set_progress()`, `is_complete()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.


use super::status::ObjectiveStatus;

// ──────────────────────────────────────────────────────────────────────────────
// Objective
// ──────────────────────────────────────────────────────────────────────────────

/// A single trackable task within a quest. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Supports count-based progress (`current`/`required`) and optional tagging.
///
/// # Fields
/// - `id` — `String`.
/// - `description` — `String`.
/// - `current` — `u32`.
/// - `required` — `u32`.
/// - `mandatory` — `bool`.
/// - `status` — `ObjectiveStatus`.
/// - `tags` — `Vec<String>`.
/// - `visible` — `bool`.
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
    ///
    /// # Parameters
    /// - `id` — `impl Into<String>`.
    /// - `description` — `impl Into<String>`.
    /// - `required` — `u32`.
    ///
    /// # Returns
    /// `Self`.
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
    ///
    /// # Parameters
    /// - `amount` — `u32`.
    ///
    /// # Returns
    /// `u32`.
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
    ///
    /// # Parameters
    /// - `value` — `u32`.
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
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.status == ObjectiveStatus::Done || self.status == ObjectiveStatus::Skipped
    }

    /// Add a tag. Has no effect if already present.
    ///
    /// # Parameters
    /// - `ag` — `impl Into<String>`.
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        let t = tag.into();
        if !self.tags.contains(&t) {
            self.tags.push(t);
        }
    }

    /// Returns `true` if the given tag is present.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// QuestStage
// ──────────────────────────────────────────────────────────────────────────────

/// A named group of objectives that represent one phase of a quest.
///
/// # Fields
/// - `id` — `String`.
/// - `name` — `String`.
/// - `objectives` — `Vec<Objective>`.
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
    /// Create a new empty stage. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `id` — `impl Into<String>`.
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            objectives: Vec::new(),
        }
    }

    /// Add an objective to this stage. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `obj` — `Objective`.
    pub fn add_objective(&mut self, obj: Objective) {
        self.objectives.push(obj);
    }

    /// Get an objective by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&Objective>`.
    pub fn get_objective(&self, id: &str) -> Option<&Objective> {
        self.objectives.iter().find(|o| o.id == id)
    }

    /// Get a mutable objective by id. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Objective>`.
    pub fn get_objective_mut(&mut self, id: &str) -> Option<&mut Objective> {
        self.objectives.iter_mut().find(|o| o.id == id)
    }

    /// Returns `true` when all mandatory objectives in this stage are complete.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.objectives
            .iter()
            .filter(|o| o.mandatory)
            .all(|o| o.is_complete())
    }
}
