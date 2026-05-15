//! INTERNAL ONLY: Rust-only tests for docs internals not reachable via lurek.docs.*.

use std::fs;

use lurek2d::docs::{
    export_all, export_completions, export_hover, export_signatures, Catalog, DocEntry,
    FieldRule, FieldType, ParamInfo, QualityReport, ReturnInfo, Schema,
};

fn sample_entry() -> DocEntry {
    let mut entry = DocEntry::new("play", "audio", "function");
    entry.description = "Play a sound".to_string();
    entry.parameters.push(ParamInfo {
        name: "path".to_string(),
        type_name: "string".to_string(),
        description: "Source path".to_string(),
        optional: false,
        default: None,
    });
    entry.returns.push(ReturnInfo {
        type_name: "boolean".to_string(),
        description: "true on success".to_string(),
    });
    entry
}

fn temp_dir(name: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(name);
    let _ = fs::remove_dir_all(&dir);
    fs::create_dir_all(&dir).expect("temp dir should be creatable");
    dir
}

#[test]
fn catalog_merge_overrides_duplicate_entries() {
    let mut left = Catalog::new();
    let mut right = Catalog::new();

    let mut first = sample_entry();
    first.description = "left".to_string();
    left.add(first);

    let mut override_entry = sample_entry();
    override_entry.description = "right".to_string();
    right.add(override_entry);

    let merged = left.merge(&right);
    let merged_entry = merged
        .get_entry("lurek.audio.play")
        .expect("merged catalog should contain entry");
    assert_eq!(merged_entry.description, "right");
}

#[test]
fn schema_validate_pairs_enforces_string_length_bounds() {
    let mut schema = Schema::new("player");
    let rule = FieldRule {
        field_type: FieldType::String,
        required: true,
        min_len: Some(3),
        max_len: Some(8),
        ..Default::default()
    };
    schema.add_rule("name", rule);

    let short = vec![("name".to_string(), "string", "ab".to_string())];
    let long = vec![("name".to_string(), "string", "very_long_name".to_string())];
    let valid = vec![("name".to_string(), "string", "Lurek".to_string())];

    assert!(!schema.validate_pairs(&short).ok);
    assert!(!schema.validate_pairs(&long).ok);
    assert!(schema.validate_pairs(&valid).ok);
}

#[test]
fn schema_from_toml_parses_rules_and_strict_mode() {
    let toml = r#"
name = "save"
strict = true

[rules.level]
type = "integer"
required = true
min = 1
max = 99

[rules.class]
type = "string"
enum = ["mage", "rogue"]
"#;

    let schema = Schema::from_toml(toml).expect("schema TOML should parse");
    assert_eq!(schema.name, "save");
    assert!(schema.strict);
    assert_eq!(schema.rules.len(), 2);

    let level = schema.rules.get("level").expect("level rule should exist");
    assert_eq!(level.field_type, FieldType::Integer);
    assert_eq!(level.min, Some(1.0));
    assert_eq!(level.max, Some(99.0));
}

#[test]
fn quality_report_handles_mixed_modules() {
    let mut audio = sample_entry();
    audio.module = "audio".to_string();
    audio.example = Some("lurek.audio.play('a')".to_string());
    audio.since = Some("1.0.0".to_string());

    let mut render = DocEntry::new("setColor", "render", "function");
    render.description = "".to_string();

    let report = QualityReport::from_entries(&[audio, render]);
    assert!(report.module_scores.contains_key("audio"));
    assert!(report.module_scores.contains_key("render"));
    assert!(report.overall_score >= 0.0 && report.overall_score <= 1.0);
}

#[test]
fn export_all_writes_compact_hover_variant() {
    let dir = temp_dir("lurek_docs_export_all_compact");
    export_all(&[sample_entry()], dir.to_str().expect("utf-8 path"))
        .expect("export_all should succeed");

    let hover_path = dir.join("hover.json");
    let hover = fs::read_to_string(hover_path).expect("hover.json should exist");
    assert!(hover.contains("\"name\""));
    assert!(!hover.contains("\"parameters\""));

    let _ = fs::remove_dir_all(dir);
}

#[test]
fn export_functions_write_files() {
    let dir = temp_dir("lurek_docs_export_functions");
    let completions = dir.join("completions.json");
    let hover = dir.join("hover.json");
    let signatures = dir.join("signatures.json");

    let entries = vec![sample_entry()];
    export_completions(&entries, completions.to_str().expect("utf-8 path"))
        .expect("completions export should succeed");
    export_hover(&entries, hover.to_str().expect("utf-8 path"))
        .expect("hover export should succeed");
    export_signatures(&entries, signatures.to_str().expect("utf-8 path"))
        .expect("signatures export should succeed");

    assert!(completions.exists());
    assert!(hover.exists());
    assert!(signatures.exists());

    let _ = fs::remove_dir_all(dir);
}

#[test]
fn param_and_return_info_support_edge_values() {
    let mut entry = DocEntry::new("spawn", "entity", "function");
    entry.description = "Spawn entity".to_string();
    entry.parameters.push(ParamInfo {
        name: "opts".to_string(),
        type_name: "table".to_string(),
        description: "optional options".to_string(),
        optional: true,
        default: Some("{}".to_string()),
    });
    entry.returns.push(ReturnInfo {
        type_name: "nil|userdata".to_string(),
        description: "nil on failure".to_string(),
    });

    assert!(entry.is_complete());
    assert_eq!(entry.parameters[0].default.as_deref(), Some("{}"));
    assert_eq!(entry.returns[0].type_name, "nil|userdata");
}
