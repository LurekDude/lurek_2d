//! Quest and objective status enums.

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
    #[allow(clippy::should_implement_trait)]
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
    #[allow(clippy::should_implement_trait)]
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
