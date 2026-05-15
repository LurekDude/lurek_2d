//! - Define normalized documentation record types for lurek API symbols.
//! - Model parameter, return, and metadata fields used by export and report stages.
//! - Provide completeness validation helpers for entry quality checks.

use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
/// Hold one parameter description extracted for a callable entry.
pub struct ParamInfo {
    /// Store the parameter name as visible in the public API.
    pub name: String,
    /// Store the declared parameter type name.
    pub type_name: String,
    /// Store the user-facing parameter description text.
    pub description: String,
    /// Mark whether the parameter can be omitted by callers.
    pub optional: bool,
    /// Store the default value text when one is documented.
    pub default: Option<String>,
}
#[derive(Debug, Clone, Default)]
/// Hold one return value description extracted for a callable entry.
pub struct ReturnInfo {
    /// Store the declared return type name.
    pub type_name: String,
    /// Store the user-facing return value description text.
    pub description: String,
}
#[derive(Debug, Clone, Default)]
/// Hold one normalized documentation record for a lurek API symbol.
pub struct DocEntry {
    /// Store the short symbol name without module prefix.
    pub name: String,
    /// Store the fully qualified symbol name used by tooling lookups.
    pub qualified_name: String,
    /// Store the top-level module segment for grouping and reporting.
    pub module: String,
    /// Store the symbol kind classification such as function or value.
    pub kind: String,
    /// Store the primary user-facing description text.
    pub description: String,
    /// Store ordered parameter descriptors for callable symbols.
    pub parameters: Vec<ParamInfo>,
    /// Store ordered return descriptors for callable symbols.
    pub returns: Vec<ReturnInfo>,
    /// Store an optional runnable usage example snippet.
    pub example: Option<String>,
    /// Store an optional version tag indicating introduction release.
    pub since: Option<String>,
    /// Store an optional deprecation message when symbol is deprecated.
    pub deprecated: Option<String>,
    /// Store arbitrary tags used by docs pipelines and filters.
    pub tags: Vec<String>,
    /// Store extra key-value metadata not covered by typed fields.
    pub extra: HashMap<String, String>,
}
impl DocEntry {
    /// Create an entry shell and return it with a computed qualified name.
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
    /// Return true when required fields are present for this kind, else false.
    pub fn is_complete(&self) -> bool {
        if self.name.is_empty() || self.description.is_empty() {
            return false;
        }
        if self.kind == "value" {
            return true;
        }
        !self.parameters.is_empty() || !self.returns.is_empty()
    }
    /// Return symbolic names of missing required fields for this entry.
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
