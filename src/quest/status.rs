//! Quest and objective status enums.
//!
//! This module is part of Luna2D's `quest` subsystem and provides the implementation
//! details for status-related operations and data management.
//! Key types exported from this module: `QuestStatus`, `ObjectiveStatus`.
//! Primary functions: `from_str()`, `as_str()`, `from_str()`, `as_str()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

// ──────────────────────────────────────────────────────────────────────────────
// QuestStatus
// ──────────────────────────────────────────────────────────────────────────────

/// Lifecycle state of a quest. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Quest` — Quest variant.
/// - `Available` — Available variant.
/// - `Active` — Active variant.
/// - `All` — All variant.
/// - `Completed` — Completed variant.
/// - `Failed` — Failed variant.
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
    /// Parse a status string. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Self>`.
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
    ///
    /// # Returns
    /// `&'static str`.
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

/// Lifecycle state of a single objective. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Not` — Not variant.
/// - `Pending` — Pending variant.
/// - `In` — In variant.
/// - `Active` — Active variant.
/// - `Successfully` — Successfully variant.
/// - `Done` — Done variant.
/// - `Skipped` — Skipped variant.
/// - `Failed` — Failed variant.
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
    /// Parse a status string. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Self>`.
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

    /// Convert to canonical string form. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&'static str`.
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
