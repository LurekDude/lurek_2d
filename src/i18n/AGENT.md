# i18n

## Module Info
- Module name: `i18n`
- Module group: `Feature Systems`
- Spec path: `docs/specs/i18n.md`
- Lua API path(s): `src/lua_api/i18n_api.rs`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Module Purpose
The `i18n` module provides the core localization backend for translated strings, placeholder interpolation, and plural selection. It stores catalogs by locale, resolves fallback chains, and applies lightweight text substitution rules so scripts can fetch already-localized strings through a consistent API.

It exists to keep translation lookup and plural rules separate from UI widgets, script-side table parsing, and platform locale detection. The module owns the reusable text rules and catalog semantics; the Lua bridge handles script-facing table loading and namespace exposure.

It intentionally does not own full document-format parsing, date or number formatting, bidirectional text layout, or automatic locale selection from the OS. It is a compact string-catalog backend rather than a full internationalization platform.

## Files
- `mod.rs` - Declares the localization submodules and re-exports the public catalog, interpolation, and pluralization APIs.
- `catalog.rs` - Implements `Catalog` storage, locale fallback handling, and typed catalog errors.
- `interpolation.rs` - Provides placeholder substitution helpers for localized strings.
- `plural.rs` - Defines plural categories and locale-style plural selection helpers, including Slavic-specific rules.

## Key Types
- `Catalog` - The main locale-keyed translation store with fallback resolution and flat string lookup.
- `CatalogError` - Typed error enum for missing locales, missing keys, and related catalog lookup failures.
- `PluralForm` - The plural-category enum used to select the correct localized string variant.
