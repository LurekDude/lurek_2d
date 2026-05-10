//! Localization subsystem for Lurek2D.
//!
//! Provides translation catalog management and text formatting utilities
//! exposed to Lua games via `lurek.i18n.*`.
//!
//! ## Architecture
//!
//! | Component | Type | Purpose |
//! |---|---|---|
//! | Catalog | [`Catalog`] | Multi-locale string table with dot-path keys and fallback chains |
//! | Interpolation | [`interpolate`] | `{variable}` substitution in translation strings |
//! | Plural forms | [`pluralize`] | CLDR-style count-based plural form selection |
//!
//! This module is a **Tier 2** Engine Extension.  It has no runtime
//! dependencies on GraphicsState, PhysicsWorld, or other subsystems.
//!
//! ## Source files
//! | File | Contents |
//! |---|---|
//! | `catalog.rs` | [`Catalog`], [`CatalogError`] |
//! | `interpolation.rs` | [`interpolate`], [`interpolate_pairs`] |
//! | `plural.rs` | [`PluralForm`], [`pluralize`], [`pluralize_slavic`] |

/// Multi-locale string table with dot-path keys and fallback chains.
pub mod catalog;
/// Number and date formatting utilities.
pub mod format;
/// Variable substitution in translation strings.
pub mod interpolation;
/// CLDR-style count-based plural form selection.
pub mod plural;

pub use catalog::{
    detect_system_locale, flat_table_from_json, flat_table_from_toml, is_rtl, is_valid_locale_code,
    Catalog, CatalogError, CoverageGap,
};
pub use format::{days_to_ymd, format_date, format_number, locale_separators};
pub use interpolation::{interpolate, interpolate_pairs};
pub use plural::{pluralize, pluralize_slavic, PluralForm};
