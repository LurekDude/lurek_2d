//! Lightweight runtime data-validation schema extracted from Lurek2D.

use std::collections::HashMap;

use toml::Value;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FieldType {
    Any,
    String,
    Number,
    Integer,
    Boolean,
    Table,
    Function,
}

impl FieldType {
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "string" | "str" => Self::String,
            "number" | "float" | "f64" => Self::Number,
            "integer" | "int" | "i64" | "i32" => Self::Integer,
            "boolean" | "bool" => Self::Boolean,
            "table" | "array" => Self::Table,
            "function" | "fn" | "func" => Self::Function,
            _ => Self::Any,
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Any => "any",
            Self::String => "string",
            Self::Number => "number",
            Self::Integer => "integer",
            Self::Boolean => "boolean",
            Self::Table => "table",
            Self::Function => "function",
        }
    }
}

#[derive(Debug, Clone)]
pub struct FieldRule {
    pub field_type: FieldType,
    pub required: bool,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub min_len: Option<usize>,
    pub max_len: Option<usize>,
    pub enum_values: Vec<String>,
    pub pattern: Option<String>,
    pub description: String,
}

impl Default for FieldRule {
    fn default() -> Self {
        Self {
            field_type: FieldType::Any,
            required: false,
            min: None,
            max: None,
            min_len: None,
            max_len: None,
            enum_values: Vec::new(),
            pattern: None,
            description: String::new(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct SchemaError {
    pub field: String,
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct SchemaResult {
    pub ok: bool,
    pub errors: Vec<SchemaError>,
}

impl SchemaResult {
    pub fn pass() -> Self {
        Self {
            ok: true,
            errors: Vec::new(),
        }
    }
}

#[derive(Debug, Clone)]
pub struct Schema {
    pub name: String,
    pub rules: HashMap<String, FieldRule>,
    pub strict: bool,
}

impl Schema {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            rules: HashMap::new(),
            strict: false,
        }
    }

    pub fn add_rule(&mut self, field: &str, rule: FieldRule) -> &mut Self {
        self.rules.insert(field.to_string(), rule);
        self
    }

    pub fn from_toml(input: &str) -> Result<Self, String> {
        let root: Value = toml::from_str(input).map_err(|e| format!("invalid TOML: {e}"))?;
        let table = root
            .as_table()
            .ok_or_else(|| "schema TOML root must be a table".to_string())?;

        let name = table
            .get("name")
            .and_then(Value::as_str)
            .unwrap_or("schema");
        let mut schema = Schema::new(name);
        schema.strict = table
            .get("strict")
            .and_then(Value::as_bool)
            .unwrap_or(false);

        let rules_table = table
            .get("rules")
            .or_else(|| table.get("fields"))
            .and_then(Value::as_table)
            .ok_or_else(|| "schema TOML must contain [rules] or [fields] table".to_string())?;

        for (field_name, raw_rule) in rules_table {
            let mut rule = FieldRule::default();
            if let Some(rule_table) = raw_rule.as_table() {
                if let Some(kind) = rule_table.get("type").and_then(Value::as_str) {
                    rule.field_type = FieldType::from_str(kind);
                }
                rule.required = rule_table
                    .get("required")
                    .and_then(Value::as_bool)
                    .unwrap_or(false);
                rule.min = rule_table.get("min").and_then(Value::as_float).or_else(|| {
                    rule_table
                        .get("min")
                        .and_then(Value::as_integer)
                        .map(|v| v as f64)
                });
                rule.max = rule_table.get("max").and_then(Value::as_float).or_else(|| {
                    rule_table
                        .get("max")
                        .and_then(Value::as_integer)
                        .map(|v| v as f64)
                });
                rule.min_len = rule_table
                    .get("min_len")
                    .and_then(Value::as_integer)
                    .map(|v| v as usize)
                    .or_else(|| {
                        rule_table
                            .get("minLen")
                            .and_then(Value::as_integer)
                            .map(|v| v as usize)
                    });
                rule.max_len = rule_table
                    .get("max_len")
                    .and_then(Value::as_integer)
                    .map(|v| v as usize)
                    .or_else(|| {
                        rule_table
                            .get("maxLen")
                            .and_then(Value::as_integer)
                            .map(|v| v as usize)
                    });
                if let Some(values) = rule_table.get("enum").and_then(Value::as_array) {
                    rule.enum_values = values
                        .iter()
                        .filter_map(Value::as_str)
                        .map(str::to_string)
                        .collect();
                }
                rule.pattern = rule_table
                    .get("pattern")
                    .and_then(Value::as_str)
                    .map(str::to_string);
                rule.description = rule_table
                    .get("description")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .to_string();
            } else if let Some(kind) = raw_rule.as_str() {
                rule.field_type = FieldType::from_str(kind);
            }
            schema.add_rule(field_name, rule);
        }

        Ok(schema)
    }

    pub fn validate_pairs<'a>(&self, fields: &[(String, &'a str, String)]) -> SchemaResult {
        let mut errors = Vec::new();
        let field_map: HashMap<&str, (&'a str, &str)> = fields
            .iter()
            .map(|(k, t, v)| (k.as_str(), (*t, v.as_str())))
            .collect();

        for (field_name, rule) in &self.rules {
            match field_map.get(field_name.as_str()) {
                None => {
                    if rule.required {
                        errors.push(SchemaError {
                            field: field_name.clone(),
                            message: format!("required field '{field_name}' is missing"),
                        });
                    }
                }
                Some((type_name, value_str)) => {
                    let type_ok = match &rule.field_type {
                        FieldType::Any => true,
                        FieldType::String => *type_name == "string",
                        FieldType::Number | FieldType::Integer => {
                            *type_name == "number" || *type_name == "integer"
                        }
                        FieldType::Boolean => *type_name == "boolean",
                        FieldType::Table => *type_name == "table",
                        FieldType::Function => *type_name == "function",
                    };
                    if !type_ok {
                        errors.push(SchemaError {
                            field: field_name.clone(),
                            message: format!(
                                "field '{field_name}' expected type {}, got {type_name}",
                                rule.field_type.as_str()
                            ),
                        });
                        continue;
                    }

                    if matches!(rule.field_type, FieldType::Number | FieldType::Integer) {
                        if let Ok(n) = value_str.parse::<f64>() {
                            if let Some(min) = rule.min {
                                if n < min {
                                    errors.push(SchemaError {
                                        field: field_name.clone(),
                                        message: format!(
                                            "field '{field_name}' value {n} is below minimum {min}"
                                        ),
                                    });
                                }
                            }
                            if let Some(max) = rule.max {
                                if n > max {
                                    errors.push(SchemaError {
                                        field: field_name.clone(),
                                        message: format!(
                                            "field '{field_name}' value {n} exceeds maximum {max}"
                                        ),
                                    });
                                }
                            }
                        }
                    }

                    if rule.field_type == FieldType::String {
                        if let Some(min_len) = rule.min_len {
                            if value_str.len() < min_len {
                                errors.push(SchemaError {
                                    field: field_name.clone(),
                                    message: format!(
                                        "field '{field_name}' is too short (min {min_len})"
                                    ),
                                });
                            }
                        }
                        if let Some(max_len) = rule.max_len {
                            if value_str.len() > max_len {
                                errors.push(SchemaError {
                                    field: field_name.clone(),
                                    message: format!(
                                        "field '{field_name}' exceeds max length {max_len}"
                                    ),
                                });
                            }
                        }
                        if !rule.enum_values.is_empty() {
                            let found = rule.enum_values.iter().any(|e| e == value_str);
                            if !found {
                                errors.push(SchemaError {
                                    field: field_name.clone(),
                                    message: format!(
                                        "field '{field_name}' value '{value_str}' not in allowed set: [{}]",
                                        rule.enum_values.join(", ")
                                    ),
                                });
                            }
                        }
                    }
                }
            }
        }

        if self.strict {
            for (k, _, _) in fields {
                if !self.rules.contains_key(k.as_str()) {
                    errors.push(SchemaError {
                        field: k.clone(),
                        message: format!("unknown field '{k}' not declared in schema"),
                    });
                }
            }
        }

        SchemaResult {
            ok: errors.is_empty(),
            errors,
        }
    }
}
