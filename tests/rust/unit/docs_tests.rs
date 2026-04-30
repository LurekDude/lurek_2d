//! Tests for the docs module.

use lurek2d::docs::catalog::Catalog;
use lurek2d::docs::entry::{DocEntry, ParamInfo};
use lurek2d::docs::export::{export_all, export_completions, export_hover, export_signatures};
use lurek2d::docs::report::{quality_grade, quality_score, QualityReport, ValidationReport};
use lurek2d::docs::schema::{FieldRule, FieldType, Schema};

// ── catalog ────────────────────────────────────────────────────────────────

mod catalog_tests {
    use super::*;

    fn sample_entry(name: &str, module: &str, kind: &str) -> DocEntry {
        let mut e = DocEntry::new(name, module, kind);
        e.description = format!("{name} description");
        e
    }

    #[test]
    fn empty_catalog() {
        let cat = Catalog::new();
        assert_eq!(cat.entry_count(), 0);
        assert!(cat.modules().is_empty());
    }

    #[test]
    fn add_and_retrieve() {
        let mut cat = Catalog::new();
        cat.add(sample_entry("play", "audio", "function"));
        assert_eq!(cat.entry_count(), 1);
        assert!(cat.get_entry("lurek.audio.play").is_some());
    }

    #[test]
    fn modules_dedup() {
        let mut cat = Catalog::new();
        cat.add(sample_entry("a", "audio", "function"));
        cat.add(sample_entry("b", "audio", "function"));
        cat.add(sample_entry("c", "render", "function"));
        assert_eq!(cat.modules(), vec!["audio", "render"]);
    }

    #[test]
    fn search_by_name() {
        let mut cat = Catalog::new();
        cat.add(sample_entry("play", "audio", "function"));
        cat.add(sample_entry("stop", "audio", "function"));
        let results = cat.search("play");
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn filter_by_kind() {
        let mut cat = Catalog::new();
        cat.add(sample_entry("play", "audio", "function"));
        cat.add(sample_entry("volume", "audio", "value"));
        assert_eq!(cat.filter_by_kind("value").len(), 1);
    }

    #[test]
    fn entries_for_module() {
        let cat = Catalog::from_entries(&[
            sample_entry("a", "audio", "function"),
            sample_entry("b", "render", "function"),
        ]);
        assert_eq!(cat.entries_for_module("audio").len(), 1);
    }

    #[test]
    fn clear_empties_catalog() {
        let mut cat = Catalog::new();
        cat.add(sample_entry("x", "m", "function"));
        cat.clear();
        assert_eq!(cat.entry_count(), 0);
    }
}

// ── entry ──────────────────────────────────────────────────────────────────

mod entry_tests {
    use super::*;

    #[test]
    fn is_complete_with_description_and_params() {
        let mut e = DocEntry::new("play", "audio", "function");
        assert!(!e.is_complete()); // no description
        e.description = "Plays a sound".into();
        assert!(!e.is_complete()); // no params/returns
        e.parameters.push(ParamInfo {
            name: "path".into(),
            type_name: "string".into(),
            description: "sound file".into(),
            optional: false,
            default: None,
        });
        assert!(e.is_complete());
    }

    #[test]
    fn value_kind_complete_without_params() {
        let mut e = DocEntry::new("pi", "math", "value");
        e.description = "The constant pi".into();
        assert!(e.is_complete());
    }

    #[test]
    fn missing_fields() {
        let e = DocEntry::new("x", "m", "function");
        let missing = e.missing_fields();
        assert!(missing.contains(&"description"));
        assert!(missing.contains(&"parameters_or_returns"));
    }
}

// ── export ─────────────────────────────────────────────────────────────────

mod export_tests {
    use super::*;

    fn test_entries() -> Vec<DocEntry> {
        let mut e = DocEntry::new("play", "audio", "function");
        e.description = "Plays a sound".into();
        e.parameters.push(ParamInfo {
            name: "path".into(),
            type_name: "string".into(),
            description: "file path".into(),
            optional: false,
            default: None,
        });
        vec![e]
    }

    #[test]
    fn export_completions_writes_file() {
        let dir = std::env::temp_dir().join("lurek_test_export_completions");
        let _ = std::fs::create_dir_all(&dir);
        let path = dir.join("completions.json");
        export_completions(&test_entries(), path.to_str().unwrap()).unwrap();
        let content = std::fs::read_to_string(&path).unwrap();
        assert!(content.contains("play"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn export_hover_writes_file() {
        let dir = std::env::temp_dir().join("lurek_test_export_hover");
        let _ = std::fs::create_dir_all(&dir);
        let path = dir.join("hover.json");
        export_hover(&test_entries(), path.to_str().unwrap()).unwrap();
        let content = std::fs::read_to_string(&path).unwrap();
        assert!(content.contains("lurek.audio.play"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn export_signatures_writes_file() {
        let dir = std::env::temp_dir().join("lurek_test_export_sigs");
        let _ = std::fs::create_dir_all(&dir);
        let path = dir.join("sigs.json");
        export_signatures(&test_entries(), path.to_str().unwrap()).unwrap();
        let content = std::fs::read_to_string(&path).unwrap();
        assert!(content.contains("path"));
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn export_all_creates_three_files() {
        let dir = std::env::temp_dir().join("lurek_test_export_all");
        let _ = std::fs::remove_dir_all(&dir);
        export_all(&test_entries(), dir.to_str().unwrap()).unwrap();
        assert!(dir.join("completions.json").exists());
        assert!(dir.join("hover.json").exists());
        assert!(dir.join("signatures.json").exists());
        let _ = std::fs::remove_dir_all(&dir);
    }
}

// ── report ─────────────────────────────────────────────────────────────────

mod report_tests {
    use super::*;

    fn full_entry() -> DocEntry {
        let mut e = DocEntry::new("play", "audio", "function");
        e.description = "Plays a sound".into();
        e.example = Some("lurek.audio.play('boom')".into());
        e.since = Some("0.1.0".into());
        e.parameters.push(ParamInfo {
            name: "path".into(),
            type_name: "string".into(),
            description: "file".into(),
            optional: false,
            default: None,
        });
        e
    }

    #[test]
    fn quality_score_full_entry() {
        let score = quality_score(&full_entry());
        assert!((score - 1.0).abs() < 1e-9);
    }

    #[test]
    fn quality_score_empty_entry() {
        let e = DocEntry::new("x", "m", "function");
        let score = quality_score(&e);
        assert!(score < 0.5);
    }

    #[test]
    fn quality_grade_mapping() {
        assert_eq!(quality_grade(1.0), "A");
        assert_eq!(quality_grade(0.8), "B");
        assert_eq!(quality_grade(0.6), "C");
        assert_eq!(quality_grade(0.4), "D");
        assert_eq!(quality_grade(0.1), "F");
    }

    #[test]
    fn validation_report_clean() {
        let r = ValidationReport::new();
        assert!(r.is_clean());
        assert_eq!(r.total_issues(), 0);
    }

    #[test]
    fn validation_report_with_issues() {
        let mut r = ValidationReport::new();
        r.missing.push("lurek.audio.play".into());
        r.incomplete.push("lurek.audio.stop".into());
        assert!(!r.is_clean());
        assert_eq!(r.total_issues(), 2);
    }

    #[test]
    fn quality_report_from_entries() {
        let entries = vec![full_entry()];
        let report = QualityReport::from_entries(&entries);
        assert!((report.overall_score - 1.0).abs() < 1e-9);
        assert_eq!(report.module_grade("audio"), "A");
    }
}

// ── schema ─────────────────────────────────────────────────────────────────

mod schema_tests {
    use super::*;

    #[test]
    fn field_type_parse() {
        assert_eq!(FieldType::from_str("string"), FieldType::String);
        assert_eq!(FieldType::from_str("number"), FieldType::Number);
        assert_eq!(FieldType::from_str("integer"), FieldType::Integer);
        assert_eq!(FieldType::from_str("boolean"), FieldType::Boolean);
        assert_eq!(FieldType::from_str("table"), FieldType::Table);
        assert_eq!(FieldType::from_str("function"), FieldType::Function);
        assert_eq!(FieldType::from_str("unknown"), FieldType::Any);
    }

    #[test]
    fn field_type_as_str() {
        assert_eq!(FieldType::String.as_str(), "string");
        assert_eq!(FieldType::Any.as_str(), "any");
    }

    #[test]
    fn schema_pass_result() {
        let r = Schema::new("test").validate_pairs(&[
            // empty, no rules
        ]);
        // No required fields → passes
        assert!(r.ok);
    }

    #[test]
    fn required_field_missing() {
        let mut schema = Schema::new("test");
        schema.add_rule(
            "name",
            FieldRule {
                field_type: FieldType::String,
                required: true,
                ..Default::default()
            },
        );
        let result = schema.validate_pairs(&[]);
        assert!(!result.ok);
        assert_eq!(result.errors.len(), 1);
        assert!(result.errors[0].message.contains("required"));
    }

    #[test]
    fn type_mismatch() {
        let mut schema = Schema::new("test");
        schema.add_rule(
            "age",
            FieldRule {
                field_type: FieldType::Number,
                required: true,
                ..Default::default()
            },
        );
        let fields = vec![("age".to_string(), "string", "hello".to_string())];
        let result = schema.validate_pairs(&fields);
        assert!(!result.ok);
        assert!(result.errors[0].message.contains("expected type"));
    }

    #[test]
    fn numeric_bounds() {
        let mut schema = Schema::new("test");
        schema.add_rule(
            "level",
            FieldRule {
                field_type: FieldType::Integer,
                required: true,
                min: Some(1.0),
                max: Some(100.0),
                ..Default::default()
            },
        );
        let fields = vec![("level".to_string(), "number", "150".to_string())];
        let result = schema.validate_pairs(&fields);
        assert!(!result.ok);
        assert!(result.errors[0].message.contains("exceeds maximum"));
    }

    #[test]
    fn enum_validation() {
        let mut schema = Schema::new("test");
        schema.add_rule(
            "class",
            FieldRule {
                field_type: FieldType::String,
                required: true,
                enum_values: vec!["warrior".into(), "mage".into()],
                ..Default::default()
            },
        );
        let fields = vec![("class".to_string(), "string", "rogue".to_string())];
        let result = schema.validate_pairs(&fields);
        assert!(!result.ok);
        assert!(result.errors[0].message.contains("not in allowed set"));
    }

    #[test]
    fn strict_mode_rejects_unknown() {
        let mut schema = Schema::new("test");
        schema.strict = true;
        let fields = vec![("extra".to_string(), "string", "val".to_string())];
        let result = schema.validate_pairs(&fields);
        assert!(!result.ok);
        assert!(result.errors[0].message.contains("unknown field"));
    }

    #[test]
    fn valid_data_passes() {
        let mut schema = Schema::new("player");
        schema.add_rule(
            "name",
            FieldRule {
                field_type: FieldType::String,
                required: true,
                ..Default::default()
            },
        );
        schema.add_rule(
            "level",
            FieldRule {
                field_type: FieldType::Integer,
                required: true,
                min: Some(1.0),
                max: Some(100.0),
                ..Default::default()
            },
        );
        let fields = vec![
            ("name".to_string(), "string", "Hero".to_string()),
            ("level".to_string(), "number", "50".to_string()),
        ];
        let result = schema.validate_pairs(&fields);
        assert!(result.ok);
    }
}
