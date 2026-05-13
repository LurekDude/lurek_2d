//! Engine error taxonomy and transport-friendly snapshots.
//! Maps subsystem failures to stable error codes, categories, and recovery hints.

use thiserror::Error;
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// High-level classification used to group runtime failures.
pub enum ErrorCategory {
    /// Startup and initialization failures.
    Init,
    /// Frame-time subsystem execution failures.
    Runtime,
    /// Asset and handle lifecycle failures.
    Resource,
    /// Script execution or callback failures.
    Script,
    /// Filesystem path or IO policy failures.
    Filesystem,
    /// OS-level or infrastructure failures.
    System,
}
impl ErrorCategory {
    /// Map error category to stable lowercase identifier string.
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
#[derive(Debug, Error)]
/// Engine-wide error enum used by runtime APIs and subsystem adapters.
pub enum EngineError {
    #[error("Initialization error: {0}")]
    /// Failure while bootstrapping runtime components.
    InitializationError(String),
    #[error("Render error: {0}")]
    /// Failure while issuing or presenting render work.
    RenderError(String),
    #[error("Input error: {0}")]
    /// Failure while handling keyboard, mouse, or gamepad input.
    InputError(String),
    #[error("Audio error: {0}")]
    /// Failure while decoding or playing audio content.
    AudioError(String),
    #[error("Physics error: {0}")]
    /// Failure while stepping or configuring physics state.
    PhysicsError(String),
    #[error("Filesystem error: {0}")]
    /// Failure while resolving or accessing game filesystem paths.
    FileSystemError(String),
    #[error("Lua error: {0}")]
    /// Failure raised from Lua execution.
    LuaError(String),
    #[error("Window error: {0}")]
    /// Failure while creating or managing window state.
    WindowError(String),
    #[error("Config error: {0}")]
    /// Failure while parsing or validating configuration.
    ConfigError(String),
    #[error("Resource not found: {0}")]
    /// Referenced resource path or key was not found.
    ResourceNotFound(String),
    #[error("Resource not loaded: {0}")]
    /// Referenced resource handle exists but has no loaded payload.
    ResourceNotLoaded(String),
    #[error("IO error: {0}")]
    /// Wrapped standard library IO failure.
    IoError(#[from] std::io::Error),
}
impl EngineError {
    /// Return stable machine-readable error code for this variant.
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
    /// Return high-level category used for diagnostics grouping.
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
    /// Return operator hint describing likely remediation path.
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
            Self::ConfigError(_) => "Review conf.toml for syntax errors or invalid values.",
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
/// Convenience alias for runtime results that use `EngineError`.
pub type EngineResult<T> = Result<T, EngineError>;
#[derive(Debug, Clone)]
/// Serializable error view used by logs, UI overlays, and tooling output.
pub struct ErrorSnapshot {
    /// Human-readable error message text.
    pub message: String,
    /// Stable short error code.
    pub code: &'static str,
    /// Stable category identifier.
    pub category: &'static str,
    /// Suggested recovery hint for operators.
    pub recovery_hint: &'static str,
}
impl ErrorSnapshot {
    /// Encode snapshot as compact JSON for external consumers.
    pub fn to_json(&self) -> String {
        let escaped = self.message.replace('\\', "\\\\").replace('"', "\\\"");
        format!(
            r#"{{"message":"{}","code":"{}","category":"{}","hint":"{}"}}"#,
            escaped, self.code, self.category, self.recovery_hint
        )
    }
}
impl EngineError {
    /// Build snapshot payload from this error value.
    pub fn snapshot(&self) -> ErrorSnapshot {
        ErrorSnapshot {
            message: self.to_string(),
            code: self.code(),
            category: self.category().as_str(),
            recovery_hint: self.recovery_hint(),
        }
    }
}
