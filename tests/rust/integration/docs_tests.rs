//! Integration tests for `lurek2d::docs` — DocEntry, Catalog, quality_score, quality_grade,
//! ValidationReport, and QualityReport.

use lurek2d::docs::{
    quality_grade, quality_score, Catalog, DocEntry, ParamInfo, QualityReport, ValidationReport,
};

// ── DocEntry::new ─────────────────────────────────────────────────────────────

#[test]
fn doc_entry_new_sets_name() {
    let e = DocEntry::new("play", "audio", "function");
    assert_eq!(e.name, "play");
}

#[test]
fn doc_entry_new_sets_module() {
    let e = DocEntry::new("play", "audio", "function");
    assert_eq!(e.module, "audio");
}

#[test]
fn doc_entry_new_sets_kind() {
    let e = DocEntry::new("play", "audio", "function");
    assert_eq!(e.kind, "function");
}

#[test]
fn doc_entry_new_builds_qualified_name() {
    let e = DocEntry::new("play", "audio", "function");
    assert_eq!(e.qualified_name, "lurek.audio.play");
}

// ── DocEntry::is_complete ─────────────────────────────────────────────────────

#[test]
fn doc_entry_is_complete_empty_description_returns_false() {
    let e = DocEntry::new("play", "audio", "function");
    assert!(!e.is_complete());
}

#[test]
fn doc_entry_is_complete_value_kind_with_description_returns_true() {
    let mut e = DocEntry::new("volume", "audio", "value");
    e.description = "Current volume level.".to_string();
    assert!(e.is_complete());
}

#[test]
fn doc_entry_is_complete_function_with_desc_no_params_returns_false() {
    let mut e = DocEntry::new("play", "audio", "function");
    e.description = "Plays a sound.".to_string();
    assert!(!e.is_complete());
}

#[test]
fn doc_entry_is_complete_function_with_params_returns_true() {
    let mut e = DocEntry::new("play", "audio", "function");
    e.description = "Plays a sound.".to_string();
    e.parameters.push(ParamInfo {
        name: "path".to_string(),
        type_name: "string".to_string(),
        ..Default::default()
    });
    assert!(e.is_complete());
}

#[test]
fn doc_entry_is_complete_function_with_returns_only_returns_true() {
    let mut e = DocEntry::new("getDt", "timer", "function");
    e.description = "Returns the last frame delta-time.".to_string();
    e.returns.push(lurek2d::docs::ReturnInfo {
        type_name: "number".to_string(),
        description: "Delta-time in seconds.".to_string(),
    });
    assert!(e.is_complete());
}

// ── DocEntry::missing_fields ──────────────────────────────────────────────────

#[test]
fn doc_entry_missing_fields_lists_description_when_empty() {
    let e = DocEntry::new("play", "audio", "function");
    let missing = e.missing_fields();
    assert!(missing.contains(&"description"));
}

#[test]
fn doc_entry_missing_fields_empty_when_value_complete() {
    let mut e = DocEntry::new("volume", "audio", "value");
    e.description = "Current volume.".to_string();
    assert!(e.missing_fields().is_empty());
}

#[test]
fn doc_entry_missing_fields_lists_params_for_incomplete_function() {
    let mut e = DocEntry::new("play", "audio", "function");
    e.description = "Plays audio.".to_string();
    let missing = e.missing_fields();
    assert!(missing.contains(&"parameters_or_returns"));
}

// ── Catalog ───────────────────────────────────────────────────────────────────

#[test]
fn catalog_add_increases_entry_count() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("play", "audio", "function"));
    assert_eq!(c.entry_count(), 1);
}

#[test]
fn catalog_add_multiple_increases_count() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("play", "audio", "function"));
    c.add(DocEntry::new("stop", "audio", "function"));
    assert_eq!(c.entry_count(), 2);
}

#[test]
fn catalog_get_entry_finds_by_qualified_name() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("play", "audio", "function"));
    let entry = c.get_entry("lurek.audio.play");
    assert!(entry.is_some());
    assert_eq!(entry.unwrap().name, "play");
}

#[test]
fn catalog_get_entry_unknown_returns_none() {
    let c = Catalog::new();
    assert!(c.get_entry("lurek.missing.fn").is_none());
}

#[test]
fn catalog_entries_for_module_filters_correctly() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("play", "audio", "function"));
    c.add(DocEntry::new("draw", "graphics", "function"));
    c.add(DocEntry::new("stop", "audio", "function"));
    let audio = c.entries_for_module("audio");
    assert_eq!(audio.len(), 2);
    assert!(audio.iter().all(|e| e.module == "audio"));
}

#[test]
fn catalog_modules_returns_sorted_unique() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("draw", "graphics", "function"));
    c.add(DocEntry::new("play", "audio", "function"));
    c.add(DocEntry::new("stop", "audio", "function"));
    let mods = c.modules();
    assert_eq!(mods, vec!["audio", "graphics"]);
}

#[test]
fn catalog_search_matches_name_substring() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("playSound", "audio", "function"));
    c.add(DocEntry::new("stopSound", "audio", "function"));
    c.add(DocEntry::new("draw", "graphics", "function"));
    let results = c.search("sound");
    assert_eq!(results.len(), 2);
}

#[test]
fn catalog_search_matches_description_substring() {
    let mut c = Catalog::new();
    let mut e = DocEntry::new("play", "audio", "function");
    e.description = "Plays a looping audio file.".to_string();
    c.add(e);
    c.add(DocEntry::new("draw", "graphics", "function"));
    let results = c.search("looping");
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].name, "play");
}

#[test]
fn catalog_search_is_case_insensitive() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("PlayAudio", "audio", "function"));
    let results = c.search("playaudio");
    assert_eq!(results.len(), 1);
}

#[test]
fn catalog_clear_resets_to_empty() {
    let mut c = Catalog::new();
    c.add(DocEntry::new("play", "audio", "function"));
    c.add(DocEntry::new("draw", "graphics", "function"));
    c.clear();
    assert_eq!(c.entry_count(), 0);
}

// ── quality_score ─────────────────────────────────────────────────────────────

#[test]
fn quality_score_empty_entry_returns_zero() {
    let e = DocEntry::default();
    let score = quality_score(&e);
    assert!((score - 0.0).abs() < 1e-5);
}

#[test]
fn quality_score_fully_populated_returns_one() {
    let mut e = DocEntry::new("play", "audio", "function");
    e.description = "Plays a sound source.".to_string();
    e.parameters.push(ParamInfo {
        name: "path".to_string(),
        type_name: "string".to_string(),
        ..Default::default()
    });
    e.example = Some("lurek.audio.play('hit.ogg')".to_string());
    e.since = Some("0.4.0".to_string());
    let score = quality_score(&e);
    assert!((score - 1.0).abs() < 1e-5);
}

#[test]
fn quality_score_partial_entry_between_zero_and_one() {
    let mut e = DocEntry::new("draw", "graphics", "function");
    e.description = "Draws a sprite.".to_string();
    // Has description + qualified_name, but no params/example/since
    let score = quality_score(&e);
    assert!(score > 0.0 && score < 1.0);
}

// ── quality_grade ─────────────────────────────────────────────────────────────

#[test]
fn quality_grade_zero_returns_f() {
    assert_eq!(quality_grade(0.0), "F");
}

#[test]
fn quality_grade_0_3_returns_d() {
    assert_eq!(quality_grade(0.3), "D");
}

#[test]
fn quality_grade_0_5_returns_c() {
    assert_eq!(quality_grade(0.5), "C");
}

#[test]
fn quality_grade_0_7_returns_b() {
    assert_eq!(quality_grade(0.7), "B");
}

#[test]
fn quality_grade_0_9_returns_a() {
    assert_eq!(quality_grade(0.9), "A");
}

// ── ValidationReport ─────────────────────────────────────────────────────────

#[test]
fn validation_report_is_clean_when_all_vecs_empty() {
    let r = ValidationReport::new();
    assert!(r.is_clean());
}

#[test]
fn validation_report_not_clean_with_missing_entry() {
    let mut r = ValidationReport::new();
    r.missing.push("lurek.audio.play".to_string());
    assert!(!r.is_clean());
}

#[test]
fn validation_report_not_clean_with_phantom_entry() {
    let mut r = ValidationReport::new();
    r.phantom.push("lurek.old.fn".to_string());
    assert!(!r.is_clean());
}

#[test]
fn validation_report_not_clean_with_incomplete_entry() {
    let mut r = ValidationReport::new();
    r.incomplete.push("lurek.audio.play".to_string());
    assert!(!r.is_clean());
}

#[test]
fn validation_report_total_issues_sums_all_categories() {
    let mut r = ValidationReport::new();
    r.missing.push("a".to_string());
    r.phantom.push("b".to_string());
    r.incomplete.push("c".to_string());
    r.incomplete.push("d".to_string());
    assert_eq!(r.total_issues(), 4);
}

#[test]
fn validation_report_total_issues_zero_when_clean() {
    let r = ValidationReport::new();
    assert_eq!(r.total_issues(), 0);
}

// ── QualityReport::compute ───────────────────────────────────────────────────

#[test]
fn quality_report_compute_calculates_module_scores() {
    let mut catalog = Catalog::new();
    // High-quality audio entry
    let mut e1 = DocEntry::new("play", "audio", "function");
    e1.description = "Plays audio.".to_string();
    e1.parameters.push(ParamInfo { name: "p".to_string(), ..Default::default() });
    e1.example = Some("ex".to_string());
    e1.since = Some("0.1.0".to_string());
    // Low-quality graphics entry (no description, no params, no example, no since)
    let e2 = DocEntry::new("draw", "graphics", "function");
    catalog.add(e1);
    catalog.add(e2);

    let report = QualityReport::compute(&catalog);
    assert!(report.module_scores.contains_key("audio"));
    assert!(report.module_scores.contains_key("graphics"));

    let audio_score = *report.module_scores.get("audio").unwrap();
    let gfx_score = *report.module_scores.get("graphics").unwrap();
    assert!(audio_score > gfx_score);
}

#[test]
fn quality_report_compute_empty_catalog_overall_score_zero() {
    let catalog = Catalog::new();
    let report = QualityReport::compute(&catalog);
    assert!((report.overall_score - 0.0).abs() < 1e-5);
    assert!(report.module_scores.is_empty());
}
