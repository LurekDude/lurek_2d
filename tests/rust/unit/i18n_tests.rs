//! INTERNAL ONLY: Rust-only tests for i18n helpers that are not reachable through lurek.i18n.*.

use lurek2d::i18n::*;
use std::collections::HashMap;

mod plural_tests {
    use super::*;

    #[test]
    fn plural_form_key_round_trip() {
        let forms = [
            PluralForm::Zero,
            PluralForm::One,
            PluralForm::Two,
            PluralForm::Few,
            PluralForm::Many,
            PluralForm::Other,
        ];
        let expected = ["zero", "one", "two", "few", "many", "other"];

        for (form, key) in forms.iter().zip(expected.iter()) {
            assert_eq!(form.key(), *key);
            assert_eq!(PluralForm::from_key(key), Some(form.clone()));
        }
    }

    #[test]
    fn from_key_unknown_returns_none() {
        assert!(PluralForm::from_key("bogus").is_none());
        assert!(PluralForm::from_key("").is_none());
    }

    #[test]
    fn slavic_one() {
        assert_eq!(PluralForm::slavic(1), PluralForm::One);
        assert_eq!(PluralForm::slavic(21), PluralForm::One);
        assert_eq!(PluralForm::slavic(101), PluralForm::One);
    }

    #[test]
    fn slavic_few() {
        assert_eq!(PluralForm::slavic(2), PluralForm::Few);
        assert_eq!(PluralForm::slavic(3), PluralForm::Few);
        assert_eq!(PluralForm::slavic(4), PluralForm::Few);
        assert_eq!(PluralForm::slavic(22), PluralForm::Few);
        assert_eq!(PluralForm::slavic(34), PluralForm::Few);
    }

    #[test]
    fn slavic_many() {
        assert_eq!(PluralForm::slavic(0), PluralForm::Many);
        assert_eq!(PluralForm::slavic(5), PluralForm::Many);
        assert_eq!(PluralForm::slavic(11), PluralForm::Many);
        assert_eq!(PluralForm::slavic(12), PluralForm::Many);
        assert_eq!(PluralForm::slavic(14), PluralForm::Many);
        assert_eq!(PluralForm::slavic(19), PluralForm::Many);
        assert_eq!(PluralForm::slavic(100), PluralForm::Many);
        assert_eq!(PluralForm::slavic(111), PluralForm::Many);
    }

    #[test]
    fn pluralize_slavic_uses_slavic_rules() {
        let mut forms = HashMap::new();
        forms.insert("one".to_string(), "jablko".to_string());
        forms.insert("few".to_string(), "jablka".to_string());
        forms.insert("many".to_string(), "jablek".to_string());

        assert_eq!(pluralize_slavic(1, &forms), "jablko");
        assert_eq!(pluralize_slavic(2, &forms), "jablka");
        assert_eq!(pluralize_slavic(5, &forms), "jablek");
        assert_eq!(pluralize_slavic(12, &forms), "jablek");
        assert_eq!(pluralize_slavic(22, &forms), "jablka");
    }
}

mod interpolation_tests {
    use super::*;

    #[test]
    fn interpolate_pairs_basic() {
        let pairs = vec![
            ("name".to_string(), "Ada".to_string()),
            ("count".to_string(), "3".to_string()),
        ];

        assert_eq!(
            interpolate_pairs("{name} has {count} items", &pairs),
            "Ada has 3 items"
        );
    }

    #[test]
    fn interpolate_pairs_empty() {
        let pairs = Vec::new();
        assert_eq!(interpolate_pairs("no vars", &pairs), "no vars");
    }
}

mod catalog_tests {
    use super::*;

    fn en_catalog() -> Catalog {
        let mut catalog = Catalog::new();
        let mut table = HashMap::new();
        table.insert("ui.ok".to_string(), "OK".to_string());
        table.insert("ui.cancel".to_string(), "Cancel".to_string());
        table.insert("item.sword".to_string(), "Sword".to_string());
        catalog.load("en", table);
        catalog.locale = "en".to_string();
        catalog
    }

    #[test]
    fn new_creates_empty_catalog() {
        let catalog = Catalog::new();
        assert_eq!(catalog.locale, "");
        assert!(catalog.fallbacks.is_empty());
        assert!(catalog.tables.is_empty());
    }

    #[test]
    fn get_missing_key_returns_error() {
        let catalog = en_catalog();
        assert!(catalog.get("nonexistent").is_err());
    }

    #[test]
    fn export_clones_table() {
        let catalog = en_catalog();
        let exported = catalog.export("en").unwrap();

        assert_eq!(exported.get("ui.ok").unwrap(), "OK");
        assert!(catalog.export("missing").is_none());
    }
}

// ── Locale utilities ──────────────────────────────────────────────────────

mod locale_util_tests {
    use lurek2d::i18n::{
        detect_system_locale, flat_table_from_json, flat_table_from_toml, is_rtl,
        is_valid_locale_code, Catalog,
    };
    use std::collections::HashMap;

    // is_valid_locale_code
    #[test]
    fn test_valid_locale_code_accepts_bare_language() {
        assert!(is_valid_locale_code("en"));
        assert!(is_valid_locale_code("pl"));
        assert!(is_valid_locale_code("ja"));
    }

    #[test]
    fn test_valid_locale_code_accepts_language_region() {
        assert!(is_valid_locale_code("en-US"));
        assert!(is_valid_locale_code("zh-CN"));
        assert!(is_valid_locale_code("pt-BR"));
        assert!(is_valid_locale_code("en_GB")); // underscore separator
    }

    #[test]
    fn test_valid_locale_code_accepts_three_letter_language() {
        assert!(is_valid_locale_code("ckb")); // Central Kurdish
    }

    #[test]
    fn test_valid_locale_code_rejects_empty() {
        assert!(!is_valid_locale_code(""));
    }

    #[test]
    fn test_valid_locale_code_rejects_single_char() {
        assert!(!is_valid_locale_code("e"));
    }

    #[test]
    fn test_valid_locale_code_rejects_digits_in_language() {
        assert!(!is_valid_locale_code("1en"));
    }

    #[test]
    fn test_valid_locale_code_rejects_too_long() {
        assert!(!is_valid_locale_code("abcdefghijklmnopqrstuvwxyzabcdefghijk"));
    }

    // is_rtl
    #[test]
    fn test_is_rtl_arabic() {
        assert!(is_rtl("ar"));
        assert!(is_rtl("ar-SA"));
    }

    #[test]
    fn test_is_rtl_hebrew() {
        assert!(is_rtl("he"));
        assert!(is_rtl("he-IL"));
    }

    #[test]
    fn test_is_rtl_persian() {
        assert!(is_rtl("fa"));
    }

    #[test]
    fn test_is_rtl_false_for_ltr() {
        assert!(!is_rtl("en"));
        assert!(!is_rtl("pl"));
        assert!(!is_rtl("fr-FR"));
        assert!(!is_rtl("ja"));
    }

    // detect_system_locale (smoke only — env-dependent)
    #[test]
    fn test_detect_system_locale_returns_none_or_valid_string() {
        // Either returns None or a non-empty String.
        if let Some(code) = detect_system_locale() {
            assert!(!code.is_empty());
            // Should not contain encoding suffix.
            assert!(!code.contains('.'));
        }
    }

    // flat_table_from_toml
    #[test]
    fn test_flat_table_from_toml_basic() {
        let toml = r#"
[greeting]
hello = "Hello"
bye   = "Goodbye"
"#;
        let flat = flat_table_from_toml(toml).unwrap();
        assert_eq!(flat.get("greeting.hello").unwrap(), "Hello");
        assert_eq!(flat.get("greeting.bye").unwrap(), "Goodbye");
    }

    #[test]
    fn test_flat_table_from_toml_nested() {
        let toml = r#"
[menu.main]
start = "Start"
quit  = "Quit"
"#;
        let flat = flat_table_from_toml(toml).unwrap();
        assert_eq!(flat.get("menu.main.start").unwrap(), "Start");
        assert_eq!(flat.get("menu.main.quit").unwrap(), "Quit");
    }

    #[test]
    fn test_flat_table_from_toml_invalid_returns_err() {
        assert!(flat_table_from_toml("not valid toml !!! ===").is_err());
    }

    // flat_table_from_json
    #[test]
    fn test_flat_table_from_json_basic() {
        let json = r#"{"greeting":{"hello":"Hello","bye":"Goodbye"}}"#;
        let flat = flat_table_from_json(json).unwrap();
        assert_eq!(flat.get("greeting.hello").unwrap(), "Hello");
        assert_eq!(flat.get("greeting.bye").unwrap(), "Goodbye");
    }

    #[test]
    fn test_flat_table_from_json_invalid_returns_err() {
        assert!(flat_table_from_json("{bad json").is_err());
    }

    // coverage_gaps
    #[test]
    fn test_coverage_gaps_finds_missing_keys() {
        let mut catalog = Catalog::new();
        let mut en = HashMap::new();
        en.insert("greeting".to_string(), "Hello".to_string());
        en.insert("farewell".to_string(), "Goodbye".to_string());
        catalog.load("en", en);

        let mut fr = HashMap::new();
        fr.insert("greeting".to_string(), "Bonjour".to_string());
        // "farewell" is missing in French
        catalog.load("fr", fr);

        let gaps = catalog.coverage_gaps("en");
        assert_eq!(gaps.len(), 1);
        assert_eq!(gaps[0].key, "farewell");
        assert!(gaps[0].missing_in.contains(&"fr".to_string()));
    }

    #[test]
    fn test_coverage_gaps_empty_when_complete() {
        let mut catalog = Catalog::new();
        let mut en = HashMap::new();
        en.insert("ok".to_string(), "OK".to_string());
        catalog.load("en", en.clone());
        catalog.load("fr", en); // same keys

        let gaps = catalog.coverage_gaps("en");
        assert!(gaps.is_empty());
    }

    #[test]
    fn test_coverage_gaps_unknown_reference_returns_empty() {
        let catalog = Catalog::new();
        let gaps = catalog.coverage_gaps("nonexistent");
        assert!(gaps.is_empty());
    }

    // categories + index cache invalidation
    #[test]
    fn test_categories_cache_invalidated_on_load() {
        let mut catalog = Catalog::new();
        let mut table = HashMap::new();
        table.insert("ui.ok".to_string(), "OK".to_string());
        catalog.load("en", table);
        catalog.locale = "en".to_string();

        let cats1 = catalog.categories();
        assert!(cats1.contains(&"ui".to_string()));

        // Add a new locale entry — cache should invalidate.
        let mut table2 = HashMap::new();
        table2.insert("menu.start".to_string(), "Start".to_string());
        table2.insert("ui.ok".to_string(), "OK".to_string());
        catalog.load("en", table2);

        let cats2 = catalog.categories();
        assert!(cats2.contains(&"menu".to_string()));
    }

    #[test]
    fn test_build_index_cache_invalidated_on_set_key() {
        let mut catalog = Catalog::new();
        let mut table = HashMap::new();
        table.insert("greeting".to_string(), "Hello".to_string());
        catalog.load("en", table);
        catalog.locale = "en".to_string();

        let idx1 = catalog.build_index();
        assert!(idx1.contains_key("hello"));

        catalog.set_key("en", "farewell", "Goodbye World");

        let idx2 = catalog.build_index();
        assert!(idx2.contains_key("goodbye"));
    }
}
