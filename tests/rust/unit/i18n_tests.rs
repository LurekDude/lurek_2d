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
