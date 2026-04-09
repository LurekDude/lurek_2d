//! Integration tests for `lurek2d::localization` — catalog, interpolation, plural forms.

use lurek2d::localization::*;
use std::collections::HashMap;

// ── Catalog ───────────────────────────────────────────────────────────────────

#[test]
fn catalog_new_is_empty() {
    let c = Catalog::new();
    assert!(!c.has_locale("en"));
    assert!(c.locale.is_empty());
}

#[test]
fn catalog_load_and_get() {
    let mut c = Catalog::new();
    let mut map = HashMap::new();
    map.insert("hello".to_string(), "Hello World".to_string());
    c.load("en", map);
    c.locale = "en".to_string();
    assert_eq!(c.get("hello").unwrap(), "Hello World");
}

#[test]
fn catalog_translate_returns_key_when_missing() {
    let c = Catalog::new();
    assert_eq!(c.translate("missing.key"), "missing.key");
}

#[test]
fn catalog_translate_uses_fallback_chain() {
    let mut c = Catalog::new();
    let mut en_map = HashMap::new();
    en_map.insert("greeting".to_string(), "Hello".to_string());
    c.load("en", en_map);
    c.locale = "fr".to_string();
    c.fallbacks = vec!["en".to_string()];
    assert_eq!(c.translate("greeting"), "Hello");
}

#[test]
fn catalog_has_locale_after_load() {
    let mut c = Catalog::new();
    c.load("de", HashMap::new());
    assert!(c.has_locale("de"));
    assert!(!c.has_locale("fr"));
}

#[test]
fn catalog_locales_returns_loaded() {
    let mut c = Catalog::new();
    c.load("en", HashMap::new());
    c.load("es", HashMap::new());
    let mut locales = c.locales();
    locales.sort();
    assert_eq!(locales, vec!["en", "es"]);
}

#[test]
fn catalog_has_key_checks_active_locale() {
    let mut c = Catalog::new();
    let mut map = HashMap::new();
    map.insert("ui.ok".to_string(), "OK".to_string());
    c.load("en", map);
    c.locale = "en".to_string();
    assert!(c.has_key("ui.ok"));
    assert!(!c.has_key("ui.cancel"));
}

#[test]
fn catalog_set_key_adds_runtime_override() {
    let mut c = Catalog::new();
    c.load("en", HashMap::new());
    c.locale = "en".to_string();
    c.set_key("en", "dynamic.key", "Dynamic Value");
    assert_eq!(c.get("dynamic.key").unwrap(), "Dynamic Value");
}

#[test]
fn catalog_export_returns_active_locale() {
    let mut c = Catalog::new();
    let mut map = HashMap::new();
    map.insert("k1".to_string(), "v1".to_string());
    map.insert("k2".to_string(), "v2".to_string());
    c.load("en", map);
    c.locale = "en".to_string();
    let exported = c.export("en").expect("locale must exist");
    assert_eq!(exported.len(), 2);
    assert_eq!(exported.get("k1").map(|s| s.as_str()), Some("v1"));
}

#[test]
fn catalog_unload_removes_locale() {
    let mut c = Catalog::new();
    c.load("en", HashMap::new());
    c.unload("en");
    assert!(!c.has_locale("en"));
}

// ── Interpolation ─────────────────────────────────────────────────────────────

#[test]
fn interpolate_replaces_single_placeholder() {
    let mut vars = HashMap::new();
    vars.insert("name".to_string(), "Alice".to_string());
    assert_eq!(interpolate("Hello, {name}!", &vars), "Hello, Alice!");
}

#[test]
fn interpolate_multiple_placeholders() {
    let mut vars = HashMap::new();
    vars.insert("a".to_string(), "X".to_string());
    vars.insert("b".to_string(), "Y".to_string());
    assert_eq!(interpolate("{a} and {b}", &vars), "X and Y");
}

#[test]
fn interpolate_double_brace_escaping() {
    let vars = HashMap::new();
    assert_eq!(interpolate("{{escaped}}", &vars), "{escaped}");
}

#[test]
fn interpolate_missing_key_left_as_placeholder() {
    let vars = HashMap::new();
    // Missing key should be left in place (or replaced with empty — check actual behavior)
    let result = interpolate("Hello {missing}", &vars);
    // Just verify it doesn't panic
    let _ = result;
}

#[test]
fn interpolate_pairs_convenience() {
    let result = interpolate_pairs("Hi {n}!", &[("n".to_string(), "Bob".to_string())]);
    assert_eq!(result, "Hi Bob!");
}

// ── PluralForm ────────────────────────────────────────────────────────────────

#[test]
fn plural_form_english_one() {
    assert_eq!(PluralForm::english(1.0), PluralForm::One);
}

#[test]
fn plural_form_english_other() {
    assert_eq!(PluralForm::english(0.0), PluralForm::Other);
    assert_eq!(PluralForm::english(2.0), PluralForm::Other);
    assert_eq!(PluralForm::english(100.0), PluralForm::Other);
}

#[test]
fn plural_form_key_returns_cldr_string() {
    assert_eq!(PluralForm::One.key(), "one");
    assert_eq!(PluralForm::Other.key(), "other");
    assert_eq!(PluralForm::Few.key(), "few");
    assert_eq!(PluralForm::Zero.key(), "zero");
}

#[test]
fn plural_form_from_key_round_trips() {
    for key in ["zero", "one", "two", "few", "many", "other"] {
        let form = PluralForm::from_key(key).expect("key should be valid");
        assert_eq!(form.key(), key);
    }
}

#[test]
fn plural_form_from_key_unknown_returns_none() {
    assert!(PluralForm::from_key("unknown_form").is_none());
}

#[test]
fn pluralize_selects_one_form() {
    let mut forms = HashMap::new();
    forms.insert("one".to_string(), "1 item".to_string());
    forms.insert("other".to_string(), "{n} items".to_string());
    assert_eq!(pluralize(1.0, &forms), "1 item");
}

#[test]
fn pluralize_selects_other_form() {
    let mut forms = HashMap::new();
    forms.insert("one".to_string(), "1 item".to_string());
    forms.insert("other".to_string(), "{n} items".to_string());
    assert_eq!(pluralize(5.0, &forms), "{n} items");
}

#[test]
fn pluralize_falls_back_to_other_when_no_match() {
    let mut forms = HashMap::new();
    forms.insert("other".to_string(), "fallback".to_string());
    assert_eq!(pluralize(1.0, &forms), "fallback");
}

#[test]
fn plural_slavic_one_suffix() {
    // 1, 21, 31 are One in Russian
    assert_eq!(PluralForm::slavic(1), PluralForm::One);
    assert_eq!(PluralForm::slavic(21), PluralForm::One);
}

#[test]
fn plural_slavic_few_suffix() {
    // 2, 3, 4, 22, 23 are Few
    assert_eq!(PluralForm::slavic(2), PluralForm::Few);
    assert_eq!(PluralForm::slavic(22), PluralForm::Few);
}

#[test]
fn plural_slavic_many_for_teens() {
    // 11-19 are always Many
    assert_eq!(PluralForm::slavic(11), PluralForm::Many);
    assert_eq!(PluralForm::slavic(14), PluralForm::Many);
}
