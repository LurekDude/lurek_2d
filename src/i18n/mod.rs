
/// Locale catalog storage and flattening helpers.
pub mod catalog;
/// Locale-aware date and number formatting helpers.
pub mod format;
/// Template interpolation for localized strings.
pub mod interpolation;
/// Plural-form selection and pluralization helpers.
pub mod plural;
/// Locale detection, validation, catalog types, and flat-table helpers.
pub use catalog::{
    detect_system_locale, flat_table_from_json, flat_table_from_toml, is_rtl, is_valid_locale_code,
    Catalog, CatalogError, CoverageGap,
};
/// Date and number formatting helpers.
pub use format::{days_to_ymd, format_date, format_number, locale_separators};
/// Template interpolation helpers.
pub use interpolation::{interpolate, interpolate_pairs};
/// Plural-form helpers and enum type.
pub use plural::{pluralize, pluralize_slavic, PluralForm};
