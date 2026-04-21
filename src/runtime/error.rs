//! Structured error types and result alias for the Lurek2D engine.
//!
//! All engine-level error conditions are expressed as variants of [`EngineError`], a
//! `thiserror`-derived enum that carries a human-readable description and belongs to one
//! of the six [`ErrorCategory`] groups: `Init`, `Runtime`, `Resource`, `Script`,
//! `System`, or `Filesystem`.
//!
//! This module also provides [`EngineResult<T>`], a type alias for
//! `Result<T, EngineError>`, which should be used in public APIs that can fail.
//!
//! # Design goal
//!
//! Every error variant has a stable four-digit numeric code (e.g. `E1001`) that can be
//! displayed in the error screen and referenced in documentation without changing across
//! releases.  This makes it straightforward for users to search for a specific error online
//! or in the Lurek2D issue tracker.
//!
//! Lua errors are wrapped as [`EngineError::LuaError`] so they can flow through the same
//! result type and be presented by [`crate::app::error_screen::ErrorScreen`].

use thiserror::Error;

/// Error category for grouping related engine errors.
///
/// # Variants
/// - `Init` — Init variant.
/// - `Runtime` — Runtime variant.
/// - `Resource` — Resource variant.
/// - `Script` — Script variant.
/// - `System` — System variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorCategory {
    /// Startup / initialization failures.
    Init,
    /// Runtime failures during the game loop.
    Runtime,
    /// Missing or invalid assets/resources.
    Resource,
    /// Lua script execution errors.
    Script,
    /// Filesystem and sandboxed I/O errors.
    Filesystem,
    /// System-level or I/O errors.
    System,
}

impl ErrorCategory {
    /// Returns the category name as a lowercase string.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Init => "init",
            Self::Runtime => "runtime",
            Self::Resource => "resource",
            Self::Script => "script",
            Self::Filesystem => "filesystem",
            Self::System => "system",
        }
    }
}

/// All possible error conditions that can occur in the Lurek2D engine.
///
/// Each variant carries a stable error code (`E1001`–`E1012`) and belongs to an
/// [`ErrorCategory`] for structured error reporting.
///
/// # Variants
/// - `InitializationError` — Engine startup failure (window, renderer, Lua VM).
/// - `RenderError` — Error during frame rendering.
/// - `InputError` — Error reading or processing input state.
/// - `AudioError` — Failure in the audio subsystem.
/// - `PhysicsError` — Error in the physics world or body simulation.
/// - `FileSystemError` — Sandboxed I/O failure.
/// - `LuaError` — Lua script execution or binding error.
/// - `WindowError` — Window creation or event loop failure.
/// - `ConfigError` — `conf.lua` parse error.
/// - `ResourceNotFound` — A requested asset was not found in the game directory.
/// - `ResourceNotLoaded` — A resource was released but a stale handle was accessed.
/// - `IoError` — Low-level I/O error (from `std::io::Error`).
#[derive(Debug, Error)]
pub enum EngineError {
    #[error("Initialization error: {0}")]
    InitializationError(String),

    #[error("Render error: {0}")]
    RenderError(String),

    #[error("Input error: {0}")]
    InputError(String),

    #[error("Audio error: {0}")]
    AudioError(String),

    #[error("Physics error: {0}")]
    PhysicsError(String),

    #[error("Filesystem error: {0}")]
    FileSystemError(String),

    #[error("Lua error: {0}")]
    LuaError(String),

    #[error("Window error: {0}")]
    WindowError(String),

    #[error("Config error: {0}")]
    ConfigError(String),

    #[error("Resource not found: {0}")]
    ResourceNotFound(String),

    #[error("Resource not loaded: {0}")]
    ResourceNotLoaded(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

impl EngineError {
    /// Returns the stable error code for this variant.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn code(&self) -> &'static str {
        match self {
            Self::InitializationError(_) => "E1001",
            Self::RenderError(_) => "E1002",
            Self::InputError(_) => "E1003",
            Self::AudioError(_) => "E1004",
            Self::PhysicsError(_) => "E1005",
            Self::FileSystemError(_) => "E1006",
            Self::LuaError(_) => "E1007",
            Self::WindowError(_) => "E1008",
            Self::ConfigError(_) => "E1009",
            Self::ResourceNotFound(_) => "E1010",
            Self::ResourceNotLoaded(_) => "E1011",
            Self::IoError(_) => "E1012",
        }
    }

    /// Returns the error category for this variant.
    ///
    /// # Returns
    /// `ErrorCategory`.
    pub fn category(&self) -> ErrorCategory {
        match self {
            Self::InitializationError(_) | Self::WindowError(_) | Self::ConfigError(_) => {
                ErrorCategory::Init
            }
            Self::RenderError(_)
            | Self::InputError(_)
            | Self::AudioError(_)
            | Self::PhysicsError(_) => ErrorCategory::Runtime,
            Self::ResourceNotFound(_) | Self::ResourceNotLoaded(_) => ErrorCategory::Resource,
            Self::LuaError(_) => ErrorCategory::Script,
            Self::FileSystemError(_) => ErrorCategory::Filesystem,
            Self::IoError(_) => ErrorCategory::System,
        }
    }

    /// Returns a human-readable recovery hint for this error variant.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn recovery_hint(&self) -> &'static str {
        match self {
            Self::InitializationError(_) => "Check GPU drivers and display configuration.",
            Self::RenderError(_) => "Try reducing window size or updating GPU drivers.",
            Self::InputError(_) => "Ensure input devices are connected.",
            Self::AudioError(_) => {
                "Check audio output device. The engine will continue without sound."
            }
            Self::PhysicsError(_) => "Verify physics body parameters (mass > 0, valid dimensions).",
            Self::FileSystemError(_) => {
                "Ensure the file path is correct and within the game directory."
            }
            Self::LuaError(_) => "Check the Lua script for syntax errors or undefined variables.",
            Self::WindowError(_) => "Try running with a different display backend.",
            Self::ConfigError(_) => "Review conf.lua for syntax errors or invalid values.",
            Self::ResourceNotFound(_) => {
                "Verify the file exists in the game directory and the path is spelled correctly."
            }
            Self::ResourceNotLoaded(_) => {
                "The resource handle is stale — it may have been released."
            }
            Self::IoError(_) => "Check file permissions and disk space.",
        }
    }
}

/// Convenience alias for `Result<T, EngineError>` used throughout the engine.
///
/// # Returns
/// Wraps any value type `T` in a `Result` that carries an `EngineError` on failure.
pub type EngineResult<T> = Result<T, EngineError>;

/// A serialisable snapshot of an engine error.
///
/// This struct captures all fields of an [`EngineError`] needed for
/// diagnostics: the human-readable message, numeric code, category name, and a
/// recovery hint. Used by `lurek.runtime.errorSnapshot()` and by the engine's
/// JSON crash reporter.
///
/// # Fields
/// - `message` — The display message for this error.
/// - `code` — The four-digit numeric code, e.g. `"E1004"`.
/// - `category` — The category name, e.g. `"filesystem"`.
/// - `recovery_hint` — Short actionable hint to present to the user.
#[derive(Debug, Clone)]
pub struct ErrorSnapshot {
    /// Display message for this error.
    pub message: String,
    /// Stable four-digit code, e.g. `"E1004"`.
    pub code: &'static str,
    /// Category name, e.g. `"filesystem"`.
    pub category: &'static str,
    /// Short actionable recovery hint.
    pub recovery_hint: &'static str,
}

impl ErrorSnapshot {
    /// Serialises the snapshot to a compact JSON string.
    ///
    /// The output has the form
    /// `{"message":"...","code":"...","category":"...","hint":"..."}`.
    ///
    /// # Returns
    /// `String`.
    pub fn to_json(&self) -> String {
        // Escape double quotes and backslashes so the JSON is always valid.
        let escaped = self.message.replace('\\', "\\\\").replace('"', "\\\"");
        format!(
            r#"{{"message":"{}","code":"{}","category":"{}","hint":"{}"}}"#,
            escaped, self.code, self.category, self.recovery_hint
        )
    }
}

impl EngineError {
    /// Creates an [`ErrorSnapshot`] capturing all diagnostic fields of this error.
    ///
    /// # Returns
    /// [`ErrorSnapshot`].
    pub fn snapshot(&self) -> ErrorSnapshot {
        ErrorSnapshot {
            message: self.to_string(),
            code: self.code(),
            category: self.category().as_str(),
            recovery_hint: self.recovery_hint(),
        }
    }
}

// Tests migrated to tests/rust/unit/runtime_tests.rs
