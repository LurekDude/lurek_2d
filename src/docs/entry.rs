//! Doc entry types for the Lurek2D API catalog.

use std::collections::HashMap;

/// Metadata about a single parameter in an API function.
/// # Fields
/// - `name` — `String`. Parameter name.
/// - `type_hint` — `Option<String>`. Optional type annotation.
/// - `description` — `String`. Human-readable description.
#[derive(Debug, Clone, Default)]
pub struct ParamInfo {
    /// Parameter name.
    pub name: String,
    /// Lua type name (e.g. `"number"`, `"string"`, `"table"`).
    pub type_name: String,
    /// Human-readable description.
    pub description: String,
    /// Whether the parameter may be omitted.
    pub optional: bool,
    /// Default value expression if the parameter is optional.
    pub default: Option<String>,
}

/// Metadata about a single return value.
#[derive(Debug, Clone, Default)]
pub struct ReturnInfo {
    /// Lua type name of the returned value.
    pub type_name: String,
    /// Human-readable description of what is returned.
    pub description: String,
}

/// A single documented API entry (function, method, value, or type).
/// # Fields
/// - `name` — `String`. Entry name.
/// - `module` — `String`. Owning module.
/// - `kind` — `String`. Entry kind (function, method, value, type).
/// - `description` — `String`. Full doc text.
/// - `params` — `Vec<ParamInfo>`. Parameter metadata.
/// - `returns` — `Vec<ReturnInfo>`. Return value metadata.
#[derive(Debug, Clone, Default)]
pub struct DocEntry {
    /// Short unqualified name (e.g. `"play"`).
    pub name: String,
    /// Fully qualified name (e.g. `"lurek.audio.play"`).
    pub qualified_name: String,
    /// Module that owns this entry (e.g. `"audio"`).
    pub module: String,
    /// Kind: one of `"function"`, `"method"`, `"value"`, or `"type"`.
    pub kind: String,
    /// One-sentence or short-paragraph description visible to users.
    pub description: String,
    /// Ordered list of parameter metadata.
    pub parameters: Vec<ParamInfo>,
    /// Ordered list of return value metadata.
    pub returns: Vec<ReturnInfo>,
    /// Optional short usage example in Lua.
    pub example: Option<String>,
    /// Version string when this entry was introduced (e.g. `"0.4.0"`).
    pub since: Option<String>,
    /// Non-empty if this entry is deprecated; contains migration advice.
    pub deprecated: Option<String>,
    /// Free-form tags for filtering (e.g. `["async", "render"]`).
    pub tags: Vec<String>,
    /// Arbitrary key/value pairs for tool-specific extensions.
    pub extra: HashMap<String, String>,
}

impl DocEntry {
    /// Creates a minimal entry with the given name, module, and kind.
    pub fn new(name: &str, module: &str, kind: &str) -> Self {
        let qualified_name = format!("lurek.{}.{}", module, name);
        Self {
            name: name.to_string(),
            qualified_name,
            module: module.to_string(),
            kind: kind.to_string(),
            ..Default::default()
        }
    }

    /// Returns `true` when the entry has enough information for documentation generation.
    ///
    /// A `"value"` entry is considered complete when it has a name and description.
    /// Other kinds also require at least one parameter or return entry.
    pub fn is_complete(&self) -> bool {
        if self.name.is_empty() || self.description.is_empty() {
            return false;
        }
        if self.kind == "value" {
            return true;
        }
        !self.parameters.is_empty() || !self.returns.is_empty()
    }

    /// Returns the names of fields that are missing or empty.
    pub fn missing_fields(&self) -> Vec<&'static str> {
        let mut missing = Vec::new();
        if self.name.is_empty() {
            missing.push("name");
        }
        if self.description.is_empty() {
            missing.push("description");
        }
        if self.kind != "value" && self.parameters.is_empty() && self.returns.is_empty() {
            missing.push("parameters_or_returns");
        }
        missing
    }
}
