//! - Extract source-derived Lua binding snapshots from `src/lua_api/*_api.rs` without live reflection.
//! - Keep code-registration extraction and docstring extraction separate but normalized into one machine model.
//! - Compare code-vs-doc snapshots and export JSON artifacts for drift audits.

use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
use std::fs::{self, File};
use std::io::BufWriter;
use std::path::{Path, PathBuf};

const SOURCE_DIR_RELATIVE: &str = "src/lua_api";
const CODE_SNAPSHOT_PATH: &str = "logs/data/lua_api_bindings_from_code.json";
const DOCSTRING_SNAPSHOT_PATH: &str = "logs/data/lua_api_bindings_from_docstrings.json";
const VALIDATION_REPORT_PATH: &str = "logs/reports/lua_api_binding_validation.json";
const MODULE_NAMESPACE_OVERRIDES: &[(&str, &str)] = &[("system", "runtime")];

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one normalized parameter row extracted from code or docstrings.
pub struct BindingParam {
    /// Parameter name as visible in the Lua-facing wrapper.
    pub name: String,
    /// Normalized Lua type used for drift comparison.
    pub lua_type: String,
    /// Raw source type or expression used during inference.
    pub raw_type: String,
    /// Indicates whether the parameter is optional.
    pub optional: bool,
    /// Indicates whether this parameter consumes variadic trailing values.
    pub variadic: bool,
    /// Indicates whether type inference was specific instead of a fallback.
    pub inferred: bool,
    /// Stores the docstring description when the doc extractor provides one.
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one normalized return row extracted from code or docstrings.
pub struct BindingReturn {
    /// Normalized Lua type used for drift comparison.
    pub lua_type: String,
    /// Raw source type or expression used during inference.
    pub raw_type: String,
    /// Indicates whether the return can be omitted or be nil.
    pub optional: bool,
    /// Indicates whether type inference was specific instead of a fallback.
    pub inferred: bool,
    /// Stores the docstring description when the doc extractor provides one.
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one normalized Lua binding entry reconstructed from source files.
pub struct BindingEntry {
    /// Top-level Lua module namespace segment, for example `graph` or `tween`.
    pub module: String,
    /// Namespace prefix for module functions, or owner name for userdata methods.
    pub namespace: String,
    /// Short Lua-visible wrapper name without namespace or owner prefix.
    pub name: String,
    /// Fully qualified Lua-visible wrapper name, using `:` for instance methods.
    pub qualified_name: String,
    /// Entry kind, currently `function` or `method`.
    pub kind: String,
    /// Call style used by the binding, either `.` or `:`.
    pub call_style: String,
    /// Owner display name for userdata-bound methods.
    pub owner: String,
    /// Ordered parameter rows.
    pub parameters: Vec<BindingParam>,
    /// Ordered return rows.
    pub returns: Vec<BindingReturn>,
    /// First human-readable summary line from docstrings when available.
    pub summary: String,
    /// Raw `///` block captured for docstring snapshots.
    pub raw_doc: String,
    /// Raw source signature used by the code extractor for debugging.
    pub source_signature: String,
    /// Relative source file path.
    pub source_file: String,
    /// One-based source line where the registration anchor starts.
    pub line: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one normalized snapshot of bindings extracted from source files.
pub struct BindingSnapshot {
    /// Snapshot source discriminator, either `code` or `docstrings`.
    pub source: String,
    /// Source directory scanned for `*_api.rs` files.
    pub source_dir: String,
    /// Ordered binding entries captured for the snapshot.
    pub entries: Vec<BindingEntry>,
}

impl BindingSnapshot {
    /// Returns the number of entries stored in this snapshot.
    pub fn entry_count(&self) -> usize {
        self.entries.len()
    }

    /// Returns one entry by its fully qualified Lua-visible name.
    pub fn get_entry(&self, qualified_name: &str) -> Option<&BindingEntry> {
        self.entries
            .iter()
            .find(|entry| entry.qualified_name == qualified_name)
    }

    /// Serializes this snapshot to pretty-printed JSON.
    pub fn to_json_pretty(&self) -> Result<String, String> {
        serde_json::to_string_pretty(self).map_err(|error| format!("json error: {error}"))
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one entry count mismatch for parameters or returns.
pub struct BindingCountMismatch {
    /// Fully qualified entry name whose arity drifted.
    pub qualified_name: String,
    /// Expected item count from the code snapshot.
    pub expected: usize,
    /// Actual item count from the docstring snapshot.
    pub actual: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one parameter order mismatch where the same name moved to another index.
pub struct BindingParameterOrderMismatch {
    /// Fully qualified entry name whose parameter order drifted.
    pub qualified_name: String,
    /// Parameter name found at a different index.
    pub name: String,
    /// Expected zero-based index from the code snapshot.
    pub expected_index: usize,
    /// Actual zero-based index from the docstring snapshot.
    pub actual_index: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one indexed string mismatch for parameter or return comparison.
pub struct BindingIndexedStringMismatch {
    /// Fully qualified entry name that drifted.
    pub qualified_name: String,
    /// Zero-based parameter or return index.
    pub index: usize,
    /// Expected string value from the code snapshot.
    pub expected: String,
    /// Actual string value from the docstring snapshot.
    pub actual: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores one indexed boolean mismatch for parameter or return comparison.
pub struct BindingIndexedBoolMismatch {
    /// Fully qualified entry name that drifted.
    pub qualified_name: String,
    /// Zero-based parameter or return index.
    pub index: usize,
    /// Expected boolean value from the code snapshot.
    pub expected: bool,
    /// Actual boolean value from the docstring snapshot.
    pub actual: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
/// Stores the categorized drift between code-derived and docstring-derived binding snapshots.
pub struct BindingValidationReport {
    /// Code entries that have no corresponding docstring-derived entry.
    pub missing_doc_entries: Vec<String>,
    /// Docstring entries that have no corresponding code-derived entry.
    pub phantom_doc_entries: Vec<String>,
    /// Parameter count drift grouped by entry name.
    pub parameter_count_mismatches: Vec<BindingCountMismatch>,
    /// Parameter order drift grouped by entry name.
    pub parameter_order_mismatches: Vec<BindingParameterOrderMismatch>,
    /// Parameter name drift at the same index.
    pub parameter_name_mismatches: Vec<BindingIndexedStringMismatch>,
    /// Parameter type drift at the same index.
    pub parameter_type_mismatches: Vec<BindingIndexedStringMismatch>,
    /// Parameter optionality drift at the same index.
    pub parameter_optionality_mismatches: Vec<BindingIndexedBoolMismatch>,
    /// Return count drift grouped by entry name.
    pub return_count_mismatches: Vec<BindingCountMismatch>,
    /// Return type drift at the same index.
    pub return_type_mismatches: Vec<BindingIndexedStringMismatch>,
    /// Return optionality drift at the same index.
    pub return_optionality_mismatches: Vec<BindingIndexedBoolMismatch>,
}

impl BindingValidationReport {
    /// Returns true when the report contains no categorized drift.
    pub fn is_clean(&self) -> bool {
        self.missing_doc_entries.is_empty()
            && self.phantom_doc_entries.is_empty()
            && self.parameter_count_mismatches.is_empty()
            && self.parameter_order_mismatches.is_empty()
            && self.parameter_name_mismatches.is_empty()
            && self.parameter_type_mismatches.is_empty()
            && self.parameter_optionality_mismatches.is_empty()
            && self.return_count_mismatches.is_empty()
            && self.return_type_mismatches.is_empty()
            && self.return_optionality_mismatches.is_empty()
    }

    /// Serializes this report to pretty-printed JSON.
    pub fn to_json_pretty(&self) -> Result<String, String> {
        serde_json::to_string_pretty(self).map_err(|error| format!("json error: {error}"))
    }
}

#[derive(Debug, Clone)]
struct ValueHint {
    lua_type: String,
    raw_type: String,
    optional: bool,
    inferred: bool,
}

#[derive(Debug, Clone)]
struct NamedFunctionInfo {
    header: String,
    doc_block: String,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum SnapshotMode {
    Code,
    Docstrings,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum RegistrationKind {
    TableFunction,
    AddMethod,
    AddMethodMut,
    AddFunction,
}

impl RegistrationKind {
    fn is_method(self) -> bool {
        matches!(self, Self::AddMethod | Self::AddMethodMut | Self::AddFunction)
    }
}

/// Returns the canonical default output path for code-derived binding snapshots.
pub fn default_binding_code_snapshot_path() -> &'static str {
    CODE_SNAPSHOT_PATH
}

/// Returns the canonical default output path for docstring-derived binding snapshots.
pub fn default_binding_docstring_snapshot_path() -> &'static str {
    DOCSTRING_SNAPSHOT_PATH
}

/// Returns the canonical default output path for binding validation reports.
pub fn default_binding_validation_report_path() -> &'static str {
    VALIDATION_REPORT_PATH
}

/// Extracts the current Lua binding surface from registration code only.
pub fn extract_binding_snapshot_from_code() -> Result<BindingSnapshot, String> {
    extract_binding_snapshot(SnapshotMode::Code)
}

/// Extracts the current Lua binding documentation surface from `///` docstrings only.
pub fn extract_binding_snapshot_from_docstrings() -> Result<BindingSnapshot, String> {
    extract_binding_snapshot(SnapshotMode::Docstrings)
}

/// Builds a drift report by comparing a code snapshot against a docstring snapshot.
pub fn validate_binding_snapshots(
    expected: &BindingSnapshot,
    actual: &BindingSnapshot,
) -> BindingValidationReport {
    let expected_map: BTreeMap<&str, &BindingEntry> = expected
        .entries
        .iter()
        .map(|entry| (entry.qualified_name.as_str(), entry))
        .collect();
    let actual_map: BTreeMap<&str, &BindingEntry> = actual
        .entries
        .iter()
        .map(|entry| (entry.qualified_name.as_str(), entry))
        .collect();

    let mut report = BindingValidationReport::default();

    for qualified_name in expected_map.keys() {
        if !actual_map.contains_key(qualified_name) {
            report.missing_doc_entries.push((*qualified_name).to_string());
        }
    }
    for qualified_name in actual_map.keys() {
        if !expected_map.contains_key(qualified_name) {
            report.phantom_doc_entries.push((*qualified_name).to_string());
        }
    }

    for qualified_name in expected_map.keys() {
        let Some(expected_entry) = expected_map.get(qualified_name).copied() else {
            continue;
        };
        let Some(actual_entry) = actual_map.get(qualified_name).copied() else {
            continue;
        };

        if expected_entry.parameters.len() != actual_entry.parameters.len() {
            report.parameter_count_mismatches.push(BindingCountMismatch {
                qualified_name: (*qualified_name).to_string(),
                expected: expected_entry.parameters.len(),
                actual: actual_entry.parameters.len(),
            });
        }

        let actual_param_positions: HashMap<&str, usize> = actual_entry
            .parameters
            .iter()
            .enumerate()
            .map(|(index, parameter)| (parameter.name.as_str(), index))
            .collect();
        for (expected_index, parameter) in expected_entry.parameters.iter().enumerate() {
            if let Some(actual_index) = actual_param_positions.get(parameter.name.as_str()) {
                if *actual_index != expected_index {
                    report
                        .parameter_order_mismatches
                        .push(BindingParameterOrderMismatch {
                            qualified_name: (*qualified_name).to_string(),
                            name: parameter.name.clone(),
                            expected_index,
                            actual_index: *actual_index,
                        });
                }
            }
        }

        let param_count = expected_entry.parameters.len().min(actual_entry.parameters.len());
        for index in 0..param_count {
            let expected_parameter = &expected_entry.parameters[index];
            let actual_parameter = &actual_entry.parameters[index];

            if expected_parameter.name != actual_parameter.name {
                report
                    .parameter_name_mismatches
                    .push(BindingIndexedStringMismatch {
                        qualified_name: (*qualified_name).to_string(),
                        index,
                        expected: expected_parameter.name.clone(),
                        actual: actual_parameter.name.clone(),
                    });
            }
            if expected_parameter.inferred
                && actual_parameter.inferred
                && expected_parameter.lua_type != actual_parameter.lua_type
            {
                report
                    .parameter_type_mismatches
                    .push(BindingIndexedStringMismatch {
                        qualified_name: (*qualified_name).to_string(),
                        index,
                        expected: expected_parameter.lua_type.clone(),
                        actual: actual_parameter.lua_type.clone(),
                    });
            }
            if expected_parameter.optional != actual_parameter.optional {
                report
                    .parameter_optionality_mismatches
                    .push(BindingIndexedBoolMismatch {
                        qualified_name: (*qualified_name).to_string(),
                        index,
                        expected: expected_parameter.optional,
                        actual: actual_parameter.optional,
                    });
            }
        }

        if expected_entry.returns.len() != actual_entry.returns.len() {
            report.return_count_mismatches.push(BindingCountMismatch {
                qualified_name: (*qualified_name).to_string(),
                expected: expected_entry.returns.len(),
                actual: actual_entry.returns.len(),
            });
        }

        let return_count = expected_entry.returns.len().min(actual_entry.returns.len());
        for index in 0..return_count {
            let expected_return = &expected_entry.returns[index];
            let actual_return = &actual_entry.returns[index];

            if expected_return.inferred
                && actual_return.inferred
                && expected_return.lua_type != actual_return.lua_type
            {
                report
                    .return_type_mismatches
                    .push(BindingIndexedStringMismatch {
                        qualified_name: (*qualified_name).to_string(),
                        index,
                        expected: expected_return.lua_type.clone(),
                        actual: actual_return.lua_type.clone(),
                    });
            }
            if expected_return.optional != actual_return.optional {
                report
                    .return_optionality_mismatches
                    .push(BindingIndexedBoolMismatch {
                        qualified_name: (*qualified_name).to_string(),
                        index,
                        expected: expected_return.optional,
                        actual: actual_return.optional,
                    });
            }
        }
    }

    report.missing_doc_entries.sort();
    report.phantom_doc_entries.sort();
    report
        .parameter_count_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .parameter_order_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .parameter_name_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .parameter_type_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .parameter_optionality_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .return_count_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .return_type_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
        .return_optionality_mismatches
        .sort_by(|left, right| left.qualified_name.cmp(&right.qualified_name));
    report
}

/// Builds a drift report by extracting fresh code and docstring snapshots from `src/lua_api`.
pub fn validate_current_binding_docstrings() -> Result<BindingValidationReport, String> {
    let expected = extract_binding_snapshot_from_code()?;
    let actual = extract_binding_snapshot_from_docstrings()?;
    Ok(validate_binding_snapshots(&expected, &actual))
}

/// Writes a binding snapshot JSON artifact to the requested file path.
pub fn export_binding_snapshot(snapshot: &BindingSnapshot, path: &str) -> Result<(), String> {
    write_json_file(path, snapshot)
}

/// Writes a binding validation JSON artifact to the requested file path.
pub fn export_binding_validation(
    report: &BindingValidationReport,
    path: &str,
) -> Result<(), String> {
    write_json_file(path, report)
}

fn extract_binding_snapshot(mode: SnapshotMode) -> Result<BindingSnapshot, String> {
    let source_dir = workspace_root().join(SOURCE_DIR_RELATIVE);
    let mut entries_by_name: BTreeMap<String, BindingEntry> = BTreeMap::new();
    for api_file in collect_api_files(&source_dir)? {
        for entry in extract_entries_from_file(&api_file, mode)? {
            entries_by_name.insert(entry.qualified_name.clone(), entry);
        }
    }
    Ok(BindingSnapshot {
        source: mode_label(mode).to_string(),
        source_dir: SOURCE_DIR_RELATIVE.to_string(),
        entries: entries_by_name.into_values().collect(),
    })
}

fn mode_label(mode: SnapshotMode) -> &'static str {
    match mode {
        SnapshotMode::Code => "code",
        SnapshotMode::Docstrings => "docstrings",
    }
}

fn workspace_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

fn collect_api_files(source_dir: &Path) -> Result<Vec<PathBuf>, String> {
    let mut files = Vec::new();
    let read_dir = fs::read_dir(source_dir)
        .map_err(|error| format!("read_dir {} failed: {error}", source_dir.display()))?;
    for entry in read_dir {
        let path = entry
            .map_err(|error| format!("read_dir entry failed: {error}"))?
            .path();
        let is_api_file = path
            .file_name()
            .and_then(|name| name.to_str())
            .is_some_and(|name| name.ends_with("_api.rs"));
        if is_api_file {
            files.push(path);
        }
    }
    files.sort();
    Ok(files)
}

fn extract_entries_from_file(path: &Path, mode: SnapshotMode) -> Result<Vec<BindingEntry>, String> {
    let content = fs::read_to_string(path)
        .map_err(|error| format!("read {} failed: {error}", path.display()))?;
    let lines: Vec<String> = content.lines().map(ToString::to_string).collect();
    let relative_path = relative_path(path);
    let module_name = module_name_for_file(path);
    let default_namespace = format!("lurek.{}", lua_namespace_for_module(&module_name));
    let table_namespaces = collect_table_namespaces(&lines);
    let owner_display_names = collect_owner_display_names(&lines);
    let named_functions = collect_named_functions(&lines);

    let mut entries = Vec::new();
    let mut current_owner: Option<String> = None;
    let mut current_owner_depth = 0i32;

    for (index, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        if current_owner.is_none() {
            if let Some(owner) = parse_lua_userdata_impl_owner(trimmed) {
                current_owner = Some(owner);
                current_owner_depth = brace_delta(trimmed);
                continue;
            }
        }

        if let Some(entry) = parse_table_function_entry(
            &lines,
            index,
            &module_name,
            &relative_path,
            &default_namespace,
            &table_namespaces,
            &owner_display_names,
            &named_functions,
            mode,
        )? {
            entries.push(entry);
        }

        if let Some(owner) = current_owner.as_deref() {
            if let Some(entry) = parse_userdata_function_entry(
                &lines,
                index,
                owner,
                &module_name,
                &relative_path,
                &owner_display_names,
                &named_functions,
                mode,
            )? {
                entries.push(entry);
            }
        }

        if current_owner.is_some() {
            current_owner_depth += brace_delta(trimmed);
            if current_owner_depth <= 0 {
                current_owner = None;
                current_owner_depth = 0;
            }
        }
    }

    Ok(entries)
}

#[allow(clippy::too_many_arguments)]
fn parse_table_function_entry(
    lines: &[String],
    index: usize,
    module_name: &str,
    relative_path: &str,
    default_namespace: &str,
    table_namespaces: &HashMap<String, String>,
    owner_display_names: &HashMap<String, String>,
    named_functions: &HashMap<String, NamedFunctionInfo>,
    mode: SnapshotMode,
) -> Result<Option<BindingEntry>, String> {
    let trimmed = lines[index].trim();
    if !trimmed.contains(".set(") || trimmed.starts_with("methods.") || trimmed.starts_with("fields.") {
        return Ok(None);
    }

    let Some(receiver) = identifier_before(trimmed, ".set(") else {
        return Ok(None);
    };
    let window = collect_window(lines, index, 16);
    if !window.contains("lua.create_function") {
        return Ok(None);
    }
    let Some(name) = first_string_literal(&window) else {
        return Ok(None);
    };

    let named_function = named_create_function(&window);
    let signature = if let Some(function_name) = named_function.as_deref() {
        named_functions
            .get(function_name)
            .map(|info| parse_function_signature(&info.header, RegistrationKind::TableFunction, owner_display_names))
            .transpose()?
            .unwrap_or_default()
    } else {
        parse_closure_signature(lines, index, RegistrationKind::TableFunction, owner_display_names)?
    };

    let doc_block = if let Some(function_name) = named_function.as_deref() {
        named_functions
            .get(function_name)
            .map(|info| info.doc_block.clone())
            .unwrap_or_else(|| collect_doc_block_above(lines, index))
    } else {
        collect_doc_block_above(lines, index)
    };

    let namespace = table_namespaces
        .get(&receiver)
        .cloned()
        .unwrap_or_else(|| default_namespace.to_string());
    let qualified_name = format!("{namespace}.{name}");

    let entry = build_binding_entry(
        mode,
        BindingEntry {
            module: namespace
                .strip_prefix("lurek.")
                .and_then(|value| value.split('.').next())
                .unwrap_or(module_name)
                .to_string(),
            namespace,
            name,
            qualified_name,
            kind: "function".to_string(),
            call_style: ".".to_string(),
            owner: String::new(),
            parameters: signature.parameters,
            returns: signature.returns,
            summary: String::new(),
            raw_doc: String::new(),
            source_signature: signature.source_signature,
            source_file: relative_path.to_string(),
            line: index + 1,
        },
        doc_block,
    );
    Ok(entry)
}

#[allow(clippy::too_many_arguments)]
fn parse_userdata_function_entry(
    lines: &[String],
    index: usize,
    owner_name: &str,
    module_name: &str,
    relative_path: &str,
    owner_display_names: &HashMap<String, String>,
    named_functions: &HashMap<String, NamedFunctionInfo>,
    mode: SnapshotMode,
) -> Result<Option<BindingEntry>, String> {
    let trimmed = lines[index].trim();
    let kind = if trimmed.contains("methods.add_method_mut(") {
        Some(RegistrationKind::AddMethodMut)
    } else if trimmed.contains("methods.add_method(") {
        Some(RegistrationKind::AddMethod)
    } else if trimmed.contains("methods.add_function(") {
        Some(RegistrationKind::AddFunction)
    } else {
        None
    };
    let Some(registration_kind) = kind else {
        return Ok(None);
    };

    let window = collect_window(lines, index, 16);
    let Some(name) = first_string_literal(&window) else {
        return Ok(None);
    };
    let owner_display_name = owner_display_name(owner_name, owner_display_names);
    let named_function = self_named_function(&window);

    let mut signature = if let Some(function_name) = named_function.as_deref() {
        named_functions
            .get(function_name)
            .map(|info| parse_function_signature(&info.header, registration_kind, owner_display_names))
            .transpose()?
            .unwrap_or_default()
    } else {
        parse_closure_signature(lines, index, registration_kind, owner_display_names)?
    };

    let doc_block = if let Some(function_name) = named_function.as_deref() {
        named_functions
            .get(function_name)
            .map(|info| info.doc_block.clone())
            .unwrap_or_else(|| collect_doc_block_above(lines, index))
    } else {
        collect_doc_block_above(lines, index)
    };

    if registration_kind == RegistrationKind::AddFunction {
        if let Some(first_parameter) = signature.parameters.first() {
            if is_userdata_receiver_parameter(first_parameter) {
                signature.call_style = ":".to_string();
                signature.parameters.remove(0);
            }
        }
    }

    let qualified_name = if signature.call_style == ":" {
        format!("{owner_display_name}:{name}")
    } else {
        format!("{owner_display_name}.{}", name)
    };

    let entry = build_binding_entry(
        mode,
        BindingEntry {
            module: module_name.to_string(),
            namespace: owner_display_name.clone(),
            name,
            qualified_name,
            kind: "method".to_string(),
            call_style: signature.call_style,
            owner: owner_display_name,
            parameters: signature.parameters,
            returns: signature.returns,
            summary: String::new(),
            raw_doc: String::new(),
            source_signature: signature.source_signature,
            source_file: relative_path.to_string(),
            line: index + 1,
        },
        doc_block,
    );
    Ok(entry)
}

fn build_binding_entry(
    mode: SnapshotMode,
    mut entry: BindingEntry,
    doc_block: String,
) -> Option<BindingEntry> {
    match mode {
        SnapshotMode::Code => Some(entry),
        SnapshotMode::Docstrings => {
            if doc_block.is_empty() {
                return None;
            }
            entry.summary = first_summary_line(&doc_block);
            entry.raw_doc = doc_block.clone();
            entry.parameters = parse_doc_parameters(&doc_block);
            entry.returns = parse_doc_returns(&doc_block);
            entry.source_signature.clear();
            Some(entry)
        }
    }
}

#[derive(Default)]
struct ParsedSignature {
    call_style: String,
    parameters: Vec<BindingParam>,
    returns: Vec<BindingReturn>,
    source_signature: String,
}

fn parse_closure_signature(
    lines: &[String],
    index: usize,
    registration_kind: RegistrationKind,
    owner_display_names: &HashMap<String, String>,
) -> Result<ParsedSignature, String> {
    let window = collect_window(lines, index, 20);
    let Some((signature_head, return_type)) = closure_head_and_return_type(&window) else {
        return Ok(ParsedSignature {
            call_style: default_call_style(registration_kind).to_string(),
            ..Default::default()
        });
    };

    let parameters = parse_callable_parameters(&signature_head, registration_kind, owner_display_names);
    let returns = if let Some(raw_return_type) = return_type {
        parse_return_type_list(&raw_return_type, owner_display_names)
    } else {
        let body_text = closure_body_text(lines, index, &window);
        infer_returns_from_text(&body_text, owner_display_names)
    };

    Ok(ParsedSignature {
        call_style: default_call_style(registration_kind).to_string(),
        parameters,
        returns,
        source_signature: signature_head,
    })
}

fn parse_function_signature(
    header: &str,
    registration_kind: RegistrationKind,
    owner_display_names: &HashMap<String, String>,
) -> Result<ParsedSignature, String> {
    let fn_name_index = header
        .find("fn ")
        .ok_or_else(|| format!("missing fn keyword in header: {header}"))?;
    let after_fn = &header[fn_name_index + 3..];
    let params_text = parenthesized_segment(after_fn)
        .ok_or_else(|| format!("missing function params in header: {header}"))?;
    let return_type = function_return_type(header);
    let parameters = parse_callable_parameters(&params_text, registration_kind, owner_display_names);
    let returns = return_type
        .map(|raw_return_type| parse_return_type_list(&raw_return_type, owner_display_names))
        .unwrap_or_default();
    Ok(ParsedSignature {
        call_style: default_call_style(registration_kind).to_string(),
        parameters,
        returns,
        source_signature: header.trim().to_string(),
    })
}

fn parse_callable_parameters(
    source_signature: &str,
    registration_kind: RegistrationKind,
    owner_display_names: &HashMap<String, String>,
) -> Vec<BindingParam> {
    let params_text = if source_signature.trim_start().starts_with('|') {
        closure_parameter_segment(source_signature).unwrap_or_default()
    } else {
        source_signature.to_string()
    };
    let raw_tokens = split_top_level(&params_text, ',');
    let mut parsed_parameters = Vec::new();
    for token in raw_tokens {
        parsed_parameters.extend(parse_parameter_token(&token, owner_display_names));
    }

    let mut public_parameters = parsed_parameters;
    if matches!(registration_kind, RegistrationKind::TableFunction | RegistrationKind::AddFunction) {
        if public_parameters
            .first()
            .is_some_and(is_lua_context_parameter)
        {
            public_parameters.remove(0);
        }
    }
    if matches!(registration_kind, RegistrationKind::AddMethod | RegistrationKind::AddMethodMut) {
        if public_parameters
            .first()
            .is_some_and(is_lua_context_parameter)
        {
            public_parameters.remove(0);
        }
        if public_parameters.first().is_some_and(is_receiver_parameter) {
            public_parameters.remove(0);
        }
    }
    public_parameters
}

fn parse_parameter_token(
    token: &str,
    owner_display_names: &HashMap<String, String>,
) -> Vec<BindingParam> {
    let trimmed = token.trim();
    if trimmed.is_empty() || trimmed == "()" {
        return Vec::new();
    }

    let Some((pattern, raw_type)) = split_pattern_and_type(trimmed) else {
        return vec![binding_param(trimmed, "any", "any", false, false, true, "")];
    };
    let pattern = pattern.trim();
    let raw_type = raw_type.trim();

    if is_parenthesized(pattern) && is_parenthesized(raw_type) {
        let names = split_top_level(inner_parenthesized(pattern).unwrap_or_default(), ',');
        let types = split_top_level(inner_parenthesized(raw_type).unwrap_or_default(), ',');
        let mut parameters = Vec::new();
        for (name, raw_inner_type) in names.into_iter().zip(types.into_iter()) {
            let name = normalize_parameter_name(&name);
            if name.is_empty() || name == "()" {
                continue;
            }
            if raw_inner_type.trim().contains("LuaMultiValue") {
                parameters.push(binding_param("...", "any", raw_inner_type.trim(), false, true, true, ""));
                continue;
            }
            let hint = normalize_rust_type(raw_inner_type.trim(), owner_display_names);
            parameters.push(binding_param(
                &name,
                &hint.lua_type,
                raw_inner_type.trim(),
                hint.optional,
                false,
                hint.inferred,
                "",
            ));
        }
        return parameters;
    }

    if raw_type.contains("LuaMultiValue") {
        return vec![binding_param("...", "any", raw_type, false, true, true, "")];
    }

    let normalized_name = normalize_parameter_name(pattern);
    let hint = normalize_rust_type(raw_type, owner_display_names);
    vec![binding_param(
        &normalized_name,
        &hint.lua_type,
        raw_type,
        hint.optional,
        false,
        hint.inferred,
        "",
    )]
}

fn parse_return_type_list(
    raw_return_type: &str,
    owner_display_names: &HashMap<String, String>,
) -> Vec<BindingReturn> {
    let stripped = strip_result_wrapper(raw_return_type.trim());
    if stripped.trim().is_empty() {
        return Vec::new();
    }
    if stripped.trim() == "()" {
        return vec![binding_return("nil", raw_return_type.trim(), false, true, "")];
    }
    if is_parenthesized(stripped) {
        return split_top_level(inner_parenthesized(stripped).unwrap_or_default(), ',')
            .into_iter()
            .filter(|segment| !segment.trim().is_empty())
            .map(|segment| {
                let hint = normalize_rust_type(segment.trim(), owner_display_names);
                binding_return(&hint.lua_type, segment.trim(), hint.optional, hint.inferred, "")
            })
            .collect();
    }
    let hint = normalize_rust_type(stripped, owner_display_names);
    vec![binding_return(
        &hint.lua_type,
        stripped,
        hint.optional,
        hint.inferred,
        "",
    )]
}

fn infer_returns_from_text(
    body_text: &str,
    owner_display_names: &HashMap<String, String>,
) -> Vec<BindingReturn> {
    if body_text.trim().is_empty() {
        return Vec::new();
    }
    let variable_hints = collect_variable_hints(body_text, owner_display_names);
    let expression = last_ok_expression(body_text).unwrap_or_else(|| body_text.trim().to_string());
    infer_return_expression(&expression, &variable_hints, owner_display_names)
        .into_iter()
        .map(|hint| binding_return(&hint.lua_type, &hint.raw_type, hint.optional, hint.inferred, ""))
        .collect()
}

fn infer_return_expression(
    expression: &str,
    variable_hints: &HashMap<String, ValueHint>,
    owner_display_names: &HashMap<String, String>,
) -> Vec<ValueHint> {
    let trimmed = expression.trim().trim_end_matches(';').trim();
    if trimmed.is_empty() {
        return Vec::new();
    }
    if trimmed == "()" {
        return vec![ValueHint {
            lua_type: "nil".to_string(),
            raw_type: "()".to_string(),
            optional: false,
            inferred: true,
        }];
    }
    if let Some(inner) = trimmed.strip_prefix("Some(") {
        if let Some(inner_expression) = balanced_suffix(inner, '(', ')') {
            let mut hints = infer_return_expression(inner_expression, variable_hints, owner_display_names);
            for hint in &mut hints {
                hint.optional = true;
            }
            return hints;
        }
    }
    if trimmed == "None" {
        return vec![ValueHint {
            lua_type: "nil".to_string(),
            raw_type: "None".to_string(),
            optional: true,
            inferred: true,
        }];
    }
    if is_parenthesized(trimmed) {
        return split_top_level(inner_parenthesized(trimmed).unwrap_or_default(), ',')
            .into_iter()
            .flat_map(|segment| infer_return_expression(&segment, variable_hints, owner_display_names))
            .collect();
    }
    vec![infer_value_hint(trimmed, variable_hints, owner_display_names)]
}

fn collect_variable_hints(
    body_text: &str,
    owner_display_names: &HashMap<String, String>,
) -> HashMap<String, ValueHint> {
    let mut hints = HashMap::new();
    for raw_line in body_text.lines() {
        let line = raw_line.trim();
        if !line.starts_with("let ") {
            continue;
        }
        let Some((left, right)) = line
            .trim_start_matches("let ")
            .split_once('=')
        else {
            continue;
        };
        let value_expression = right.trim().trim_end_matches(';').trim();
        let (name, explicit_type) = if let Some((name, explicit_type)) = split_pattern_and_type(left) {
            (normalize_parameter_name(name), Some(explicit_type.trim().to_string()))
        } else {
            (normalize_parameter_name(left), None)
        };
        if name.is_empty() || name == "()" {
            continue;
        }
        let hint = if let Some(explicit_type) = explicit_type {
            normalize_rust_type(&explicit_type, owner_display_names)
        } else {
            infer_value_hint(value_expression, &hints, owner_display_names)
        };
        hints.insert(name, hint);
    }
    hints
}

fn infer_value_hint(
    expression: &str,
    variable_hints: &HashMap<String, ValueHint>,
    owner_display_names: &HashMap<String, String>,
) -> ValueHint {
    let trimmed = expression.trim().trim_end_matches('?').trim();
    if let Some(hint) = variable_hints.get(trimmed) {
        return hint.clone();
    }
    if let Some(inner) = trimmed.strip_prefix("Some(") {
        if let Some(inner_expression) = balanced_suffix(inner, '(', ')') {
            let mut hint = infer_value_hint(inner_expression, variable_hints, owner_display_names);
            hint.optional = true;
            return hint;
        }
    }
    if trimmed == "None" {
        return ValueHint {
            lua_type: "nil".to_string(),
            raw_type: "None".to_string(),
            optional: true,
            inferred: true,
        };
    }
    if trimmed.starts_with("lua.create_table") {
        return ValueHint {
            lua_type: "table".to_string(),
            raw_type: "LuaTable".to_string(),
            optional: false,
            inferred: true,
        };
    }
    if trimmed.starts_with("lua.create_string") {
        return ValueHint {
            lua_type: "string".to_string(),
            raw_type: "LuaString".to_string(),
            optional: false,
            inferred: true,
        };
    }
    if trimmed.starts_with("lua.create_userdata(") {
        if let Some(inner_expression) = balanced_suffix(trimmed.trim_start_matches("lua.create_userdata"), '(', ')') {
            let inner_hint = infer_value_hint(inner_expression, variable_hints, owner_display_names);
            if inner_hint.lua_type != "any" {
                return ValueHint {
                    raw_type: inner_hint.raw_type,
                    ..inner_hint
                };
            }
        }
        return ValueHint {
            lua_type: "userdata".to_string(),
            raw_type: "LuaAnyUserData".to_string(),
            optional: false,
            inferred: true,
        };
    }
    if let Some(owner_type) = owner_type_from_expression(trimmed, owner_display_names) {
        return ValueHint {
            raw_type: owner_type.clone(),
            lua_type: owner_type,
            optional: false,
            inferred: true,
        };
    }
    if trimmed.starts_with('"') || trimmed.starts_with("format!(") || trimmed.ends_with(".to_string()") {
        return ValueHint {
            lua_type: "string".to_string(),
            raw_type: trimmed.to_string(),
            optional: false,
            inferred: true,
        };
    }
    if trimmed == "true" || trimmed == "false" || looks_like_boolean_expression(trimmed) {
        return ValueHint {
            lua_type: "boolean".to_string(),
            raw_type: trimmed.to_string(),
            optional: false,
            inferred: true,
        };
    }
    if let Some(number_type) = numeric_literal_type(trimmed) {
        return ValueHint {
            lua_type: number_type.to_string(),
            raw_type: trimmed.to_string(),
            optional: false,
            inferred: true,
        };
    }
    if let Some(identifier) = last_method_identifier(trimmed) {
        if looks_like_boolean_name(&identifier) {
            return ValueHint {
                lua_type: "boolean".to_string(),
                raw_type: trimmed.to_string(),
                optional: false,
                inferred: true,
            };
        }
        if looks_like_integer_name(&identifier) {
            return ValueHint {
                lua_type: "integer".to_string(),
                raw_type: trimmed.to_string(),
                optional: false,
                inferred: true,
            };
        }
    }
    ValueHint {
        lua_type: "any".to_string(),
        raw_type: trimmed.to_string(),
        optional: false,
        inferred: false,
    }
}

fn owner_type_from_expression(
    expression: &str,
    owner_display_names: &HashMap<String, String>,
) -> Option<String> {
    let trimmed = expression.trim();
    let candidate = if let Some(index) = trimmed.find("::") {
        trimmed[..index].trim()
    } else if let Some(index) = trimmed.find('{') {
        trimmed[..index].trim()
    } else {
        ""
    };
    if candidate.is_empty() {
        return None;
    }
    let identifier = last_path_segment(candidate);
    if identifier.starts_with('L') {
        return Some(identifier.to_string());
    }
    if identifier.starts_with("Lua") {
        return Some(owner_display_name(identifier, owner_display_names));
    }
    None
}

fn default_call_style(registration_kind: RegistrationKind) -> &'static str {
    if registration_kind.is_method() {
        ":"
    } else {
        "."
    }
}

fn collect_table_namespaces(lines: &[String]) -> HashMap<String, String> {
    let mut namespaces = HashMap::new();
    loop {
        let mut next = namespaces.clone();
        for line in lines {
            let trimmed = line.trim();
            let Some((receiver, key, value)) = parse_table_attachment(trimmed) else {
                continue;
            };
            if matches!(receiver.as_str(), "lurek" | "luna" | "lurek_table") {
                let namespace = format!("lurek.{key}");
                next.insert(value, namespace);
                continue;
            }
            if let Some(parent_namespace) = namespaces.get(&receiver) {
                let namespace = format!("{parent_namespace}.{key}");
                next.insert(value, namespace);
            }
        }
        if next == namespaces {
            break;
        }
        namespaces = next;
    }
    namespaces
}

fn parse_table_attachment(line: &str) -> Option<(String, String, String)> {
    if !line.contains(".set(") || line.contains("lua.create_function") {
        return None;
    }
    let receiver = identifier_before(line, ".set(")?;
    let key = first_string_literal(line)?;
    let remainder = line.split_once(&format!("\"{key}\""))?.1;
    let value = first_identifier_after(remainder)?;
    Some((receiver, key, value))
}

fn collect_owner_display_names(lines: &[String]) -> HashMap<String, String> {
    let mut names = HashMap::new();
    collect_luna_type_names(lines, &mut names);

    let mut current_owner: Option<String> = None;
    let mut depth = 0i32;
    for (index, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        if current_owner.is_none() {
            if let Some(owner) = parse_lua_userdata_impl_owner(trimmed) {
                current_owner = Some(owner);
                depth = brace_delta(trimmed);
                continue;
            }
        }
        if let Some(owner) = current_owner.as_deref() {
            if trimmed.contains("add_method(\"type\"") || trimmed.contains("add_method_mut(\"type\"") {
                let window = collect_window(lines, index, 8);
                if let Some(type_name) = ok_string_literal(&window) {
                    names.insert(owner.to_string(), type_name);
                }
            }
            depth += brace_delta(trimmed);
            if depth <= 0 {
                current_owner = None;
                depth = 0;
            }
        }
    }
    names
}

fn collect_luna_type_names(lines: &[String], names: &mut HashMap<String, String>) {
    let mut current_owner: Option<String> = None;
    let mut depth = 0i32;
    for line in lines {
        let trimmed = line.trim();
        if current_owner.is_none() {
            if let Some(owner) = parse_luna_type_impl_owner(trimmed) {
                current_owner = Some(owner);
                depth = brace_delta(trimmed);
                continue;
            }
        }
        if let Some(owner) = current_owner.as_deref() {
            if trimmed.contains("TYPE_NAME") {
                if let Some(type_name) = first_string_literal(trimmed) {
                    names.insert(owner.to_string(), type_name);
                }
            }
            depth += brace_delta(trimmed);
            if depth <= 0 {
                current_owner = None;
                depth = 0;
            }
        }
    }
}

fn collect_named_functions(lines: &[String]) -> HashMap<String, NamedFunctionInfo> {
    let mut functions = HashMap::new();
    for index in 0..lines.len() {
        let trimmed = lines[index].trim();
        if !trimmed.contains("fn ") || trimmed.starts_with("//") {
            continue;
        }
        let Some(function_name) = function_name_from_line(trimmed) else {
            continue;
        };
        let header = collect_header(lines, index);
        functions.insert(
            function_name,
            NamedFunctionInfo {
                header,
                doc_block: collect_doc_block_above(lines, index),
            },
        );
    }
    functions
}

fn binding_param(
    name: &str,
    lua_type: &str,
    raw_type: &str,
    optional: bool,
    variadic: bool,
    inferred: bool,
    description: &str,
) -> BindingParam {
    BindingParam {
        name: name.to_string(),
        lua_type: lua_type.to_string(),
        raw_type: raw_type.to_string(),
        optional,
        variadic,
        inferred,
        description: description.to_string(),
    }
}

fn binding_return(
    lua_type: &str,
    raw_type: &str,
    optional: bool,
    inferred: bool,
    description: &str,
) -> BindingReturn {
    BindingReturn {
        lua_type: lua_type.to_string(),
        raw_type: raw_type.to_string(),
        optional,
        inferred,
        description: description.to_string(),
    }
}

fn parse_doc_parameters(doc_block: &str) -> Vec<BindingParam> {
    let mut parameters = Vec::new();
    for line in doc_block.lines() {
        let trimmed = line.trim();
        if !trimmed.starts_with("@param") {
            continue;
        }
        let columns: Vec<String> = trimmed
            .split('|')
            .map(|part| part.trim().to_string())
            .collect();
        if columns.len() < 4 {
            continue;
        }
        let mut name = columns[1].clone();
        let type_text = columns[2].clone();
        let description = columns[3..].join(" | ");
        let variadic = name == "...";
        let mut optional = false;
        if name.ends_with('?') && !variadic {
            optional = true;
            name.pop();
        }
        let type_hint = normalize_doc_type(&type_text);
        parameters.push(binding_param(
            &name,
            &type_hint.lua_type,
            &type_text,
            optional || type_hint.optional,
            variadic,
            true,
            &description,
        ));
    }
    parameters
}

fn parse_doc_returns(doc_block: &str) -> Vec<BindingReturn> {
    let mut returns = Vec::new();
    for line in doc_block.lines() {
        let trimmed = line.trim();
        if !trimmed.starts_with("@return") {
            continue;
        }
        let columns: Vec<String> = trimmed
            .split('|')
            .map(|part| part.trim().to_string())
            .collect();
        if columns.len() < 3 {
            continue;
        }
        let type_text = columns[1].clone();
        let description = columns[2..].join(" | ");
        let type_hint = normalize_doc_type(&type_text);
        returns.push(binding_return(
            &type_hint.lua_type,
            &type_text,
            type_hint.optional,
            true,
            &description,
        ));
    }
    returns
}

fn normalize_doc_type(raw_type: &str) -> ValueHint {
    let mut cleaned = raw_type.trim().trim_matches('`').replace(' ', "");
    let mut optional = false;
    if cleaned.ends_with('?') {
        cleaned.pop();
        optional = true;
    }
    let mut parts: Vec<String> = cleaned.split('|').map(|part| part.to_string()).collect();
    if parts.len() == 2 && parts.iter().any(|part| part == "nil") {
        optional = true;
        parts.retain(|part| part != "nil");
    }
    parts.sort();
    parts.dedup();
    let normalized = if parts.is_empty() {
        "nil".to_string()
    } else {
        parts
            .into_iter()
            .map(|part| match part.as_str() {
                "int" | "integer" | "u8" | "u16" | "u32" | "u64" | "usize" | "i8"
                | "i16" | "i32" | "i64" | "isize" => "integer".to_string(),
                "float" | "double" | "number" | "f32" | "f64" => "number".to_string(),
                "bool" | "boolean" => "boolean".to_string(),
                "str" | "string" => "string".to_string(),
                other => other.to_string(),
            })
            .collect::<Vec<_>>()
            .join("|")
    };
    ValueHint {
        lua_type: normalized,
        raw_type: raw_type.trim().to_string(),
        optional,
        inferred: true,
    }
}

fn normalize_rust_type(raw_type: &str, owner_display_names: &HashMap<String, String>) -> ValueHint {
    let cleaned = strip_references(raw_type.trim());
    if let Some(inner) = wrapper_inner_type(&cleaned, "Option") {
        let mut hint = normalize_rust_type(inner, owner_display_names);
        hint.optional = true;
        return hint;
    }
    let simplified = strip_result_wrapper(&cleaned);
    if simplified == "()" {
        return ValueHint {
            lua_type: "nil".to_string(),
            raw_type: raw_type.trim().to_string(),
            optional: false,
            inferred: true,
        };
    }
    if wrapper_inner_type(simplified, "Vec").is_some()
        || wrapper_inner_type(simplified, "HashMap").is_some()
        || wrapper_inner_type(simplified, "BTreeMap").is_some()
        || wrapper_inner_type(simplified, "IndexMap").is_some()
        || wrapper_inner_type(simplified, "HashSet").is_some()
        || wrapper_inner_type(simplified, "BTreeSet").is_some()
    {
        return ValueHint {
            lua_type: "table".to_string(),
            raw_type: raw_type.trim().to_string(),
            optional: false,
            inferred: true,
        };
    }

    let last_segment = last_path_segment(simplified);
    let normalized = match last_segment {
        "String" | "str" | "LuaString" => "string",
        "bool" => "boolean",
        "f32" | "f64" => "number",
        "u8" | "u16" | "u32" | "u64" | "usize" | "i8" | "i16" | "i32"
        | "i64" | "isize" => "integer",
        "LuaTable" | "Table" => "table",
        "LuaFunction" | "Function" => "function",
        "LuaValue" | "Value" | "LuaSerdeValue" => "any",
        "LuaAnyUserData" | "AnyUserData" => "userdata",
        other if owner_display_names.contains_key(other) => {
            return ValueHint {
                lua_type: owner_display_name(other, owner_display_names),
                raw_type: raw_type.trim().to_string(),
                optional: false,
                inferred: true,
            };
        }
        other if other.starts_with('L') => other,
        other if other.starts_with("Lua") => {
            return ValueHint {
                lua_type: owner_display_name(other, owner_display_names),
                raw_type: raw_type.trim().to_string(),
                optional: false,
                inferred: true,
            };
        }
        _ => "any",
    };
    ValueHint {
        lua_type: normalized.to_string(),
        raw_type: raw_type.trim().to_string(),
        optional: false,
        inferred: normalized != "any" || matches!(last_segment, "LuaValue" | "Value" | "LuaAnyUserData" | "AnyUserData"),
    }
}

fn write_json_file<T: Serialize>(path: &str, value: &T) -> Result<(), String> {
    let output_path = workspace_root().join(path);
    if let Some(parent) = output_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|error| format!("mkdir {} failed: {error}", parent.display()))?;
    }
    let file = File::create(&output_path)
        .map_err(|error| format!("create {} failed: {error}", output_path.display()))?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(&mut writer, value)
        .map_err(|error| format!("json write {} failed: {error}", output_path.display()))
}

fn relative_path(path: &Path) -> String {
    path.strip_prefix(workspace_root())
        .unwrap_or(path)
        .to_string_lossy()
        .replace('\\', "/")
}

fn module_name_for_file(path: &Path) -> String {
    path.file_stem()
        .and_then(|stem| stem.to_str())
        .map(|stem| stem.trim_end_matches("_api").to_string())
        .unwrap_or_default()
}

fn lua_namespace_for_module(module_name: &str) -> String {
    MODULE_NAMESPACE_OVERRIDES
        .iter()
        .find_map(|(rust_name, lua_name)| (*rust_name == module_name).then(|| (*lua_name).to_string()))
        .unwrap_or_else(|| module_name.to_string())
}

fn owner_display_name(owner_name: &str, owner_display_names: &HashMap<String, String>) -> String {
    owner_display_names
        .get(owner_name)
        .cloned()
        .unwrap_or_else(|| {
            if owner_name.starts_with("Lua") {
                format!("L{}", &owner_name[3..])
            } else if owner_name.starts_with('L') {
                owner_name.to_string()
            } else {
                format!("L{owner_name}")
            }
        })
}

fn parse_lua_userdata_impl_owner(line: &str) -> Option<String> {
    if !line.contains("impl") || !line.contains("for") || !line.contains("UserData") {
        return None;
    }
    let after_for = line.split_once("for")?.1.trim();
    let identifier = leading_identifier(after_for)?;
    Some(identifier)
}

fn parse_luna_type_impl_owner(line: &str) -> Option<String> {
    if !line.contains("impl") || !line.contains("LunaType") || !line.contains("for") {
        return None;
    }
    let after_for = line.split_once("for")?.1.trim();
    leading_identifier(after_for)
}

fn collect_window(lines: &[String], start: usize, max_lines: usize) -> String {
    lines
        .iter()
        .skip(start)
        .take(max_lines)
        .map(|line| line.trim())
        .collect::<Vec<_>>()
        .join(" ")
}

fn collect_header(lines: &[String], start: usize) -> String {
    let mut header = String::new();
    for line in lines.iter().skip(start).take(24) {
        if !header.is_empty() {
            header.push(' ');
        }
        header.push_str(line.trim());
        if line.contains('{') {
            break;
        }
    }
    header
}

fn collect_block(lines: &[String], start: usize) -> String {
    let mut body = String::new();
    let mut started = false;
    let mut depth = 0i32;
    for line in lines.iter().skip(start).take(256) {
        if !started {
            if let Some(offset) = line.find('{') {
                started = true;
                depth = 1;
                body.push_str(&line[offset + 1..]);
                body.push('\n');
                depth += brace_delta(&line[offset + 1..]);
                if depth <= 0 {
                    break;
                }
            }
            continue;
        }
        depth += brace_delta(line);
        body.push_str(line);
        body.push('\n');
        if depth <= 0 {
            break;
        }
    }
    body
}

fn closure_head_and_return_type(window: &str) -> Option<(String, Option<String>)> {
    let start = window.find('|')?;
    let end = window[start + 1..].find('|')? + start + 1;
    let signature_head = window[start..=end].trim().to_string();
    let tail = window[end + 1..].trim_start();
    let return_type = tail
        .strip_prefix("->")
        .map(str::trim_start)
        .and_then(extract_type_before_body);
    Some((signature_head, return_type))
}

fn closure_parameter_segment(signature_head: &str) -> Option<String> {
    let trimmed = signature_head.trim();
    let inner = trimmed.strip_prefix('|')?.strip_suffix('|')?;
    Some(inner.trim().to_string())
}

fn closure_body_text(lines: &[String], index: usize, window: &str) -> String {
    if window.contains('{') {
        collect_block(lines, index)
    } else if let Some((_, tail)) = window.rsplit_once('|') {
        tail.trim().to_string()
    } else {
        String::new()
    }
}

fn last_ok_expression(body_text: &str) -> Option<String> {
    let mut last_expression = None;
    let mut offset = 0usize;
    while let Some(found) = body_text[offset..].find("Ok(") {
        let start = offset + found + 2;
        let segment = &body_text[start..];
        if let Some(inner) = balanced_suffix(segment, '(', ')') {
            last_expression = Some(inner.trim().to_string());
            offset = start + inner.len();
        } else {
            break;
        }
    }
    last_expression
}

fn function_name_from_line(line: &str) -> Option<String> {
    let fn_index = line.find("fn ")?;
    leading_identifier(&line[fn_index + 3..])
}

fn function_return_type(header: &str) -> Option<String> {
    let after_parens = header.rsplit_once(')')?.1.trim();
    let return_tail = after_parens.strip_prefix("->")?.trim();
    extract_type_before_body(return_tail)
}

fn collect_doc_block_above(lines: &[String], index: usize) -> String {
    let mut collected = Vec::new();
    let mut cursor = index;
    while cursor > 0 {
        cursor -= 1;
        let trimmed = lines[cursor].trim();
        if let Some(doc_text) = trimmed.strip_prefix("///") {
            collected.push(doc_text.trim_start().to_string());
            continue;
        }
        if trimmed.is_empty()
            || trimmed.starts_with("#[")
            || is_simple_bridge_line(trimmed)
            || (trimmed.starts_with("//") && !trimmed.starts_with("///"))
        {
            continue;
        }
        break;
    }
    collected.reverse();
    collected.join("\n").trim().to_string()
}

fn is_simple_bridge_line(line: &str) -> bool {
    line.starts_with("let ") && line.ends_with(';') && !line.contains('{') && !line.contains('}')
}

fn first_summary_line(doc_block: &str) -> String {
    doc_block
        .lines()
        .map(str::trim)
        .find(|line| !line.is_empty() && !line.starts_with('@'))
        .unwrap_or_default()
        .to_string()
}

fn named_create_function(window: &str) -> Option<String> {
    let after_call = window.split_once("lua.create_function(")?.1.trim_start();
    if after_call.starts_with('|') || after_call.starts_with("move |") {
        return None;
    }
    leading_identifier(after_call)
}

fn self_named_function(window: &str) -> Option<String> {
    let after_self = window.split_once("Self::")?.1;
    leading_identifier(after_self)
}

fn ok_string_literal(text: &str) -> Option<String> {
    let after_ok = text.split_once("Ok(")?.1;
    first_string_literal(after_ok)
}

fn first_string_literal(text: &str) -> Option<String> {
    let mut in_string = false;
    let mut escape = false;
    let mut literal = String::new();
    for character in text.chars() {
        if !in_string {
            if character == '"' {
                in_string = true;
                literal.clear();
            }
            continue;
        }
        if escape {
            literal.push(character);
            escape = false;
            continue;
        }
        match character {
            '\\' => escape = true,
            '"' => return Some(literal),
            other => literal.push(other),
        }
    }
    None
}

fn leading_identifier(text: &str) -> Option<String> {
    let mut identifier = String::new();
    for character in text.chars() {
        if identifier.is_empty() {
            if character == '_' || character.is_ascii_alphabetic() {
                identifier.push(character);
            } else if character.is_whitespace() {
                continue;
            } else {
                return None;
            }
        } else if character == '_' || character.is_ascii_alphanumeric() {
            identifier.push(character);
        } else {
            break;
        }
    }
    (!identifier.is_empty()).then_some(identifier)
}

fn identifier_before(text: &str, marker: &str) -> Option<String> {
    let index = text.find(marker)?;
    let prefix = text[..index].trim_end();
    let mut identifier = String::new();
    for character in prefix.chars().rev() {
        if character == '_' || character.is_ascii_alphanumeric() {
            identifier.push(character);
        } else if identifier.is_empty() {
            continue;
        } else {
            break;
        }
    }
    if identifier.is_empty() {
        None
    } else {
        Some(identifier.chars().rev().collect())
    }
}

fn first_identifier_after(text: &str) -> Option<String> {
    leading_identifier(text.trim_start_matches(|character: char| {
        character.is_whitespace() || matches!(character, ',' | '(')
    }))
}

fn parenthesized_segment(text: &str) -> Option<String> {
    let start = text.find('(')?;
    balanced_suffix(&text[start..], '(', ')').map(str::to_string)
}

fn balanced_suffix(text: &str, open: char, close: char) -> Option<&str> {
    let mut depth = 0i32;
    let mut in_string = false;
    let mut in_char = false;
    let mut escape = false;
    let mut start = None;
    for (index, character) in text.char_indices() {
        if in_string {
            if escape {
                escape = false;
                continue;
            }
            match character {
                '\\' => escape = true,
                '"' => in_string = false,
                _ => {}
            }
            continue;
        }
        if in_char {
            if escape {
                escape = false;
                continue;
            }
            match character {
                '\\' => escape = true,
                '\'' => in_char = false,
                _ => {}
            }
            continue;
        }
        match character {
            '"' => in_string = true,
            '\'' => in_char = true,
            value if value == open => {
                depth += 1;
                if start.is_none() {
                    start = Some(index + value.len_utf8());
                }
            }
            value if value == close => {
                depth -= 1;
                if depth == 0 {
                    return start.map(|start_index| &text[start_index..index]);
                }
            }
            _ => {}
        }
    }
    None
}

fn extract_type_before_body(text: &str) -> Option<String> {
    let mut result = String::new();
    let mut paren_depth = 0i32;
    let mut angle_depth = 0i32;
    let mut bracket_depth = 0i32;
    let mut in_string = false;
    let mut in_char = false;
    let mut escape = false;
    for character in text.chars() {
        if in_string {
            result.push(character);
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '"' {
                in_string = false;
            }
            continue;
        }
        if in_char {
            result.push(character);
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '\'' {
                in_char = false;
            }
            continue;
        }
        match character {
            '"' => {
                in_string = true;
                result.push(character);
            }
            '\'' => {
                in_char = true;
                result.push(character);
            }
            '(' => {
                paren_depth += 1;
                result.push(character);
            }
            ')' => {
                paren_depth -= 1;
                result.push(character);
            }
            '<' => {
                angle_depth += 1;
                result.push(character);
            }
            '>' => {
                angle_depth -= 1;
                result.push(character);
            }
            '[' => {
                bracket_depth += 1;
                result.push(character);
            }
            ']' => {
                bracket_depth -= 1;
                result.push(character);
            }
            '{' if paren_depth == 0 && angle_depth == 0 && bracket_depth == 0 => break,
            _ => result.push(character),
        }
    }
    let trimmed = result.trim().trim_end_matches(')').trim();
    (!trimmed.is_empty()).then(|| trimmed.to_string())
}

fn strip_result_wrapper(raw_type: &str) -> &str {
    wrapper_inner_type(raw_type, "LuaResult")
        .or_else(|| wrapper_inner_type(raw_type, "Result"))
        .or_else(|| wrapper_inner_type(raw_type, "mlua::Result"))
        .unwrap_or(raw_type)
}

fn wrapper_inner_type<'a>(raw_type: &'a str, wrapper_name: &str) -> Option<&'a str> {
    let trimmed = raw_type.trim();
    let prefix = format!("{wrapper_name}<");
    if !trimmed.starts_with(&prefix) {
        return None;
    }
    balanced_suffix(&trimmed[prefix.len() - 1..], '<', '>')
}

fn strip_references(raw_type: &str) -> String {
    raw_type
        .trim_start_matches('&')
        .trim_start_matches("mut ")
        .trim()
        .to_string()
}

fn normalize_parameter_name(pattern: &str) -> String {
    let trimmed = pattern.trim().trim_start_matches("mut ").trim();
    trimmed.trim_start_matches('_').trim().to_string()
}

fn split_pattern_and_type(text: &str) -> Option<(&str, &str)> {
    let mut paren_depth = 0i32;
    let mut angle_depth = 0i32;
    let mut bracket_depth = 0i32;
    for (index, character) in text.char_indices() {
        match character {
            '(' => paren_depth += 1,
            ')' => paren_depth -= 1,
            '<' => angle_depth += 1,
            '>' => angle_depth -= 1,
            '[' => bracket_depth += 1,
            ']' => bracket_depth -= 1,
            ':' if paren_depth == 0 && angle_depth == 0 && bracket_depth == 0 => {
                return Some((&text[..index], &text[index + 1..]));
            }
            _ => {}
        }
    }
    None
}

fn split_top_level(text: &str, delimiter: char) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let mut paren_depth = 0i32;
    let mut angle_depth = 0i32;
    let mut bracket_depth = 0i32;
    let mut brace_depth = 0i32;
    let mut in_string = false;
    let mut in_char = false;
    let mut escape = false;
    for character in text.chars() {
        if in_string {
            current.push(character);
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '"' {
                in_string = false;
            }
            continue;
        }
        if in_char {
            current.push(character);
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '\'' {
                in_char = false;
            }
            continue;
        }
        match character {
            '"' => {
                in_string = true;
                current.push(character);
            }
            '\'' => {
                in_char = true;
                current.push(character);
            }
            '(' => {
                paren_depth += 1;
                current.push(character);
            }
            ')' => {
                paren_depth -= 1;
                current.push(character);
            }
            '<' => {
                angle_depth += 1;
                current.push(character);
            }
            '>' => {
                angle_depth -= 1;
                current.push(character);
            }
            '[' => {
                bracket_depth += 1;
                current.push(character);
            }
            ']' => {
                bracket_depth -= 1;
                current.push(character);
            }
            '{' => {
                brace_depth += 1;
                current.push(character);
            }
            '}' => {
                brace_depth -= 1;
                current.push(character);
            }
            value
                if value == delimiter
                    && paren_depth == 0
                    && angle_depth == 0
                    && bracket_depth == 0
                    && brace_depth == 0 =>
            {
                let trimmed = current.trim();
                if !trimmed.is_empty() {
                    parts.push(trimmed.to_string());
                }
                current.clear();
            }
            _ => current.push(character),
        }
    }
    let trimmed = current.trim();
    if !trimmed.is_empty() {
        parts.push(trimmed.to_string());
    }
    parts
}

fn is_parenthesized(text: &str) -> bool {
    text.trim().starts_with('(') && text.trim().ends_with(')')
}

fn inner_parenthesized(text: &str) -> Option<&str> {
    let trimmed = text.trim();
    trimmed.strip_prefix('(')?.strip_suffix(')')
}

fn last_path_segment(text: &str) -> &str {
    text.rsplit("::").next().unwrap_or(text)
}

fn is_lua_context_parameter(parameter: &BindingParam) -> bool {
    parameter.name == "lua" || parameter.name == "" || parameter.raw_type.contains("Lua") && parameter.raw_type.contains("&Lua")
}

fn is_receiver_parameter(parameter: &BindingParam) -> bool {
    matches!(parameter.name.as_str(), "this" | "self" | "ud")
        || parameter.raw_type.contains("Self")
        || is_userdata_receiver_parameter(parameter)
}

fn is_userdata_receiver_parameter(parameter: &BindingParam) -> bool {
    parameter.raw_type.contains("LuaAnyUserData") || parameter.raw_type.contains("AnyUserData")
}

fn numeric_literal_type(text: &str) -> Option<&'static str> {
    if text.parse::<i64>().is_ok() {
        return Some("integer");
    }
    if text.parse::<f64>().is_ok() {
        return Some("number");
    }
    None
}

fn looks_like_boolean_expression(text: &str) -> bool {
    ["==", "!=", ">=", "<=", "&&", "||", ".is_", ".has_"]
        .iter()
        .any(|needle| text.contains(needle))
        || text.trim_start().starts_with('!')
}

fn last_method_identifier(text: &str) -> Option<String> {
    let candidate = text
        .rsplit(['.', ':'])
        .next()
        .unwrap_or(text)
        .trim_end_matches("()")
        .trim();
    leading_identifier(candidate)
}

fn looks_like_boolean_name(name: &str) -> bool {
    matches!(
        name,
        "isActive"
            | "isAlive"
            | "isBlocked"
            | "isComplete"
            | "isFogEnabled"
            | "isRunning"
            | "has"
            | "hasTag"
    ) || name.starts_with("is")
        || name.starts_with("has")
}

fn looks_like_integer_name(name: &str) -> bool {
    matches!(
        name,
        "len"
            | "count"
            | "width"
            | "height"
            | "grid_width"
            | "grid_height"
            | "grid_size"
            | "display_width"
            | "display_height"
            | "active_count"
            | "get_width"
            | "get_height"
            | "get_chunk_size"
    ) || name.ends_with("Count")
        || name.ends_with("Width")
        || name.ends_with("Height")
        || name.ends_with("Size")
        || name.ends_with("Id")
        || name.ends_with("Index")
}

fn brace_delta(text: &str) -> i32 {
    let mut delta = 0i32;
    let mut in_string = false;
    let mut in_char = false;
    let mut escape = false;
    let mut chars = text.chars().peekable();
    while let Some(character) = chars.next() {
        if in_string {
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '"' {
                in_string = false;
            }
            continue;
        }
        if in_char {
            if escape {
                escape = false;
            } else if character == '\\' {
                escape = true;
            } else if character == '\'' {
                in_char = false;
            }
            continue;
        }
        if character == '/' && chars.peek() == Some(&'/') {
            break;
        }
        match character {
            '"' => in_string = true,
            '\'' => in_char = true,
            '{' => delta += 1,
            '}' => delta -= 1,
            _ => {}
        }
    }
    delta
}