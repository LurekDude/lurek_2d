use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct ParamInfo {
    pub name: String,
    pub type_name: String,
    pub description: String,
    pub optional: bool,
    pub default: Option<String>,
}
#[derive(Debug, Clone, Default)]
pub struct ReturnInfo {
    pub type_name: String,
    pub description: String,
}
#[derive(Debug, Clone, Default)]
pub struct DocEntry {
    pub name: String,
    pub qualified_name: String,
    pub module: String,
    pub kind: String,
    pub description: String,
    pub parameters: Vec<ParamInfo>,
    pub returns: Vec<ReturnInfo>,
    pub example: Option<String>,
    pub since: Option<String>,
    pub deprecated: Option<String>,
    pub tags: Vec<String>,
    pub extra: HashMap<String, String>,
}
impl DocEntry {
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
    pub fn is_complete(&self) -> bool {
        if self.name.is_empty() || self.description.is_empty() {
            return false;
        }
        if self.kind == "value" {
            return true;
        }
        !self.parameters.is_empty() || !self.returns.is_empty()
    }
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
