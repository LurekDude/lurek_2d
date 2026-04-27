//! Lightweight runtime data-validation schema for Lurek2D game developers.
//!
//! A [`Schema`] is built from a table of named [`FieldRule`]s and validates
//! any Lua-table data record, returning a [`SchemaResult`] that can be
//! inspected or thrown as a Lua error.
//!
//! Typical use — game config validation, save-data integrity, mod manifests:
//! ```lua
//! local schema = lurek.docs.schema({
//!   name    = { type = "string",  required = true },
//!   level   = { type = "integer", min = 1, max = 100 },
//!   class   = { type = "string",  enum = { "warrior", "mage", "rogue" } },
//! })
//! local ok, errors = schema:validate(player)
//! ```

use std::collections::HashMap;

// ── FieldType ────────────────────────────────────────────────────────────

/// Accepted type for a schema field.
///
/// # Variants
/// - `Any` — Any variant (accept anything).
/// - `String` — String variant.
/// - `Number` — Number variant.
/// - `Integer` — Integer variant.
/// - `Boolean` — Boolean variant.
/// - `Table` — Table variant.
/// - `Function` — Function variant.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FieldType {
    /// Accept any Lua value.
    Any,
    /// Require a string.
    String,
    /// Require a Lua number.
    Number,
    /// Require a Lua integer (number with no fractional part).
    Integer,
    /// Require a boolean.
    Boolean,
    /// Require a table.
    Table,
    /// Require a function.
    Function,
}

impl FieldType {
    /// Parses a type name string.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Returns the display name.
    ///
    /// # Returns
    /// `&'static str`.
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

// ── FieldRule ────────────────────────────────────────────────────────────

/// Validation rule for a single schema field.
///
/// # Fields
/// - `field_type` — `FieldType`.
/// - `required` — `bool`.
/// - `min` — `Option<f64>`.
/// - `max` — `Option<f64>`.
/// - `min_len` — `Option<usize>`.
/// - `max_len` — `Option<usize>`.
/// - `enum_values` — `Vec<String>`.
/// - `pattern` — `Option<String>`.
/// - `default` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct FieldRule {
    /// Expected type for this field.
    pub field_type: FieldType,
    /// Whether the field must be present.
    pub required: bool,
    /// Minimum numeric value (for Number/Integer fields).
    pub min: Option<f64>,
    /// Maximum numeric value (for Number/Integer fields).
    pub max: Option<f64>,
    /// Minimum string length (for String fields).
    pub min_len: Option<usize>,
    /// Maximum string length (for String fields).
    pub max_len: Option<usize>,
    /// Allowed string values for enum validation.
    pub enum_values: Vec<String>,
    /// Simple substring or prefix pattern hint (not a regex — for doc purposes).
    pub pattern: Option<String>,
    /// Human-readable description of this field.
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

// ── SchemaError ──────────────────────────────────────────────────────────

/// A single validation failure.
///
/// # Fields
/// - `field` — `String`.
/// - `message` — `String`.
#[derive(Debug, Clone)]
pub struct SchemaError {
    /// The field name that failed.
    pub field: String,
    /// Description of the validation failure.
    pub message: String,
}

// ── SchemaResult ─────────────────────────────────────────────────────────

/// Result returned by [`Schema::validate_pairs`].
///
/// # Fields
/// - `ok` — `bool`.
/// - `errors` — `Vec<SchemaError>`.
#[derive(Debug, Clone)]
pub struct SchemaResult {
    /// Whether all validations passed.
    pub ok: bool,
    /// List of individual field errors.
    pub errors: Vec<SchemaError>,
}

impl SchemaResult {
    /// Creates a passing result.
    ///
    /// # Returns
    /// `Self`.
    pub fn pass() -> Self {
        Self {
            ok: true,
            errors: Vec::new(),
        }
    }
}

// ── Schema ───────────────────────────────────────────────────────────────

/// A named collection of [`FieldRule`]s that can validate Lua table data.
///
/// # Fields
/// - `name` — `String`.
/// - `rules` — `HashMap<String, FieldRule>`.
/// - `strict` — `bool`.
#[derive(Debug, Clone)]
pub struct Schema {
    /// Human-readable schema name.
    pub name: String,
    /// Field rules keyed by field name.
    pub rules: HashMap<String, FieldRule>,
    /// When true, extra fields not declared in rules are reported as errors.
    pub strict: bool,
}

impl Schema {
    /// Creates a new schema.
    ///
    /// # Parameters
    /// - `name` — `String`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            rules: HashMap::new(),
            strict: false,
        }
    }

    /// Adds a field rule.
    ///
    /// # Parameters
    /// - `field` — `&str`.
    /// - `rule` — `FieldRule`.
    ///
    /// # Returns
    /// `&mut Self`.
    pub fn add_rule(&mut self, field: &str, rule: FieldRule) -> &mut Self {
        self.rules.insert(field.to_string(), rule);
        self
    }

    /// Validates a set of `(field, value_type, value_str)` pairs.
    ///
    /// Callers convert the Lua table to this intermediate form before calling.
    ///
    /// # Parameters
    /// - `fields` — `&[(String, &str, String)]` — tuples of (name, type_name, display_value).
    ///
    /// # Returns
    /// `SchemaResult`.
    pub fn validate_pairs(&self, fields: &[(String, &'static str, String)]) -> SchemaResult {
        let mut errors = Vec::new();
        let field_map: HashMap<&str, (&'static str, &str)> = fields
            .iter()
            .map(|(k, t, v)| (k.as_str(), (*t, v.as_str())))
            .collect();

        // Check required and type rules.
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
                    // Type check.
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

                    // Numeric bounds.
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

                    // String length and enum.
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

        // Strict mode: report unknown fields.
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
