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
/// Variable substitution in translation strings.
pub mod interpolation;
/// CLDR-style count-based plural form selection.
pub mod plural;

pub use catalog::{Catalog, CatalogError};
pub use interpolation::{interpolate, interpolate_pairs};
pub use plural::{pluralize, pluralize_slavic, PluralForm};
