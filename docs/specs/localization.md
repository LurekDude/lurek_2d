# `localization` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.localization`                                    |
| **Source**       | `src/localization/`                                    |
| **Rust Tests**   | `tests/rust/unit/localization_tests.rs`                |
| **Lua Tests**    | `tests/lua/unit/test_localization.lua`                 |
| **Architecture** | —                                                      |

## Summary

The `localization` module provides the internationalization (i18n) backend for Luna2D games. It is a **Tier 1 Core Engine Subsystem** that handles all string translation, variable substitution, and plural form selection without external file format dependencies.

The module contains three orthogonal components:

1. **Catalog** — A multi-locale string table stored as a flat `HashMap<String, String>` keyed by dot-path strings (e.g., `"menu.play"`, `"item.sword.description"`). The catalog supports a fallback chain: when a key is missing from the active locale it walks the `fallbacks` list until a match is found. Locales are loaded from flat Lua tables (the `localization_api.rs` bridge flattens nested tables via dot-path joining). The catalog supports `load()`, `unload()`, `set_key()` for runtime overrides, and `export()` for debug dumps.

2. **Interpolation** — Template variable substitution using `{name}` placeholders. Double braces `{{escaped}}` produce literal `{escaped}` in output. `interpolate(template, vars)` accepts a `HashMap<String, String>`. `interpolate_pairs` is a convenience taking a slice of `(&str, &str)` pairs.

3. **Plural forms** — CLDR-inspired plural category selection. `PluralForm` encodes six categories (`Zero`, `One`, `Two`, `Few`, `Many`, `Other`). `PluralForm::english(n)` returns `One` or `Other`. `PluralForm::slavic(n)` applies Russian/Polish rules. `pluralize(n, forms)` resolves the correct form string from a key map.

All three are **pure Rust** with no mlua dependency. All Lua plumbing lives in `src/lua_api/localization_api.rs`. The module is gated by `modules.localization = true` in `conf.lua`.

This module intentionally does **not** provide:
- XLIFF, PO, or JSON file parsers (load translated tables from Lua)
- Date/time or number formatting
- BiDi text layout
- Runtime locale detection (use `luna.platform.locale()` for OS locale then call `setLanguage()`)

## Architecture

```
src/localization/
├── mod.rs           re-exports Catalog, CatalogError, interpolate, interpolate_pairs,
│                    PluralForm, pluralize, pluralize_slavic
├── catalog.rs       Catalog + CatalogError — multi-locale flat string store
├── interpolation.rs interpolate / interpolate_pairs — {name} substitution
└── plural.rs        PluralForm enum + pluralize / pluralize_slavic

src/lua_api/
└── localization_api.rs
    ├── LocalizationShared   bridge struct: Catalog + on_change callbacks
    └── flatten_lua_table()  nested Lua table → flat HashMap<String,String>
```

Data flow:
```
Lua: luna.localization.loadTable("en", tbl)
  → flatten_lua_table(tbl)         converts {menu={play="Play"}} → {"menu.play":"Play"}
  → Catalog::load("en", flat_map)  stores in catalog.tables["en"]

Lua: luna.localization.t("menu.play")
  → Catalog::translate("menu.play")  walks locale + fallback chain
  → interpolate(raw, vars)           substitutes {name} placeholders
  → returns localized string

Lua: luna.localization.t("item.count", nil, 3)
  → PluralForm::english(3).key()    → "other"
  → lookup "item.count.other" first, fallback to "item.count"
```

## Source Files

| File               | Purpose                                                                              |
|--------------------|--------------------------------------------------------------------------------------|
| `catalog.rs`       | `Catalog`, `CatalogError` — locale string tables with dot-path keys and fallback chains |
| `interpolation.rs` | `interpolate`, `interpolate_pairs` — `{name}` placeholder substitution              |
| `plural.rs`        | `PluralForm`, `pluralize`, `pluralize_slavic` — CLDR plural category selection      |
| `mod.rs`           | Re-exports all public types                                                          |

## Submodules

### `localization::catalog`

- `Catalog`: multi-locale store; `locale`, `fallbacks`, `tables` fields
- `CatalogError`: `#[derive(thiserror::Error)]` with variants `LocaleNotFound`, `KeyNotFound`

### `localization::interpolation`

- `interpolate(template, vars)` → `String`
- `interpolate_pairs(template, pairs)` → `String` (convenience, no HashMap allocation)

### `localization::plural`

- `PluralForm` enum: `Zero | One | Two | Few | Many | Other`
- `PluralForm::english(n: f64) -> PluralForm`
- `PluralForm::slavic(n: u64) -> PluralForm`
- `PluralForm::key(&self) -> &'static str`
- `PluralForm::from_key(s: &str) -> Option<PluralForm>`
- `pluralize(n: f64, forms: &HashMap<String,String>) -> String`
- `pluralize_slavic(n: u64, forms: &HashMap<String,String>) -> String`

## Key Types

### Structs

#### `localization::catalog::Catalog`
The central translation store. Holds a flat `HashMap<String, HashMap<String, String>>` keyed first by locale tag then by dot-path key.

**Public fields:** `locale: String`, `fallbacks: Vec<String>`, `tables: HashMap<String, HashMap<String, String>>`

**Key methods:**
- `load(locale, map)` — store a flat key→value map for a locale
- `unload(locale)` — remove a locale's entire table
- `has_locale(locale)` / `locales()` — inspect loaded locales
- `has_key(key)` / `keys()` — inspect active locale keys
- `get(key)` → `Option<&str>` — look up without fallback
- `translate(key)` → `&str` — look up with fallback chain; returns the key itself if not found
- `set_key(key, value)` — add/override a key in the active locale
- `export()` → `HashMap<String, String>` — dump the active locale

### Enums

#### `localization::catalog::CatalogError`
Typed error carrying locale or key name for diagnostics. Variants: `LocaleNotFound { locale: String }`, `KeyNotFound { key: String }`.

#### `localization::plural::PluralForm`
Six CLDR plural categories. `key()` returns the lowercase string form. `english()` / `slavic()` are locale-specific constructors.

## Lua API

The Lua API is registered in `src/lua_api/localization_api.rs` under `luna.localization.*`.

`flatten_lua_table(tbl)` converts nested Lua tables to a flat `HashMap<String,String>` using dot-joined paths. This happens at `loadTable` time so the catalog always stores flat maps internally.

`on_change: Vec<LuaRegistryKey>` callbacks fire whenever `setLanguage()` is called. Callbacks receive `(new_locale, old_locale)`.

| Function | Signature | Description |
|---|---|---|
| `loadTable(locale, tbl)` | — | Load a (possibly nested) Lua table as a locale |
| `unloadTable(locale)` | — | Remove a locale's data |
| `setLanguage(locale)` | — | Switch active locale, fires onChange callbacks |
| `getLanguage()` | `→ string` | Current active locale tag |
| `getLanguages()` | `→ table` | Array of loaded locale tags |
| `setFallbacks(tbl)` | — | Set ordered fallback locale array |
| `getFallbacks()` | `→ table` | Current fallback chain |
| `t(key, vars?, count?)` | `→ string` | Translate key with optional vars and pluralization |
| `hasKey(key)` | `→ boolean` | True if key exists in active locale |
| `getKeys()` | `→ table` | All keys in active locale |
| `setKey(key, value)` | — | Add/override a key at runtime |
| `interpolate(template, vars)` | `→ string` | Standalone `{name}` substitution |
| `pluralFor(n)` | `→ string` | CLDR form name for a number ("one"/"other") |
| `onLanguageChange(cb)` | — | Register `function(new, old)` callback |

## Lua Examples

```lua
-- Load English and Spanish tables
luna.localization.loadTable("en", {
    menu = { play = "Play", quit = "Quit" },
    item = {
        sword = { name = "Sword", description = "A sharp blade." },
        count = { one = "1 item", other = "{n} items" }
    }
})
luna.localization.loadTable("es", {
    menu = { play = "Jugar", quit = "Salir" }
})

-- Set fallback: ES falls back to EN for missing keys
luna.localization.setFallbacks({ "en" })
luna.localization.setLanguage("es")

-- Basic translation
print(luna.localization.t("menu.play"))          -- "Jugar"
print(luna.localization.t("item.sword.name"))    -- "Sword" (fallback)

-- With variable substitution
print(luna.localization.t("item.count", { n = "5" }, 5))  -- "5 items"
print(luna.localization.t("item.count", { n = "1" }, 1))  -- "1 item"

-- Standalone interpolation
local msg = luna.localization.interpolate("Hello, {name}!", { name = "Player" })
print(msg)  -- "Hello, Player!"

-- Plural form query
print(luna.localization.pluralFor(1))   -- "one"
print(luna.localization.pluralFor(5))   -- "other"

-- Language change callback
luna.localization.onLanguageChange(function(new_locale, old_locale)
    print("Language changed:", old_locale, "→", new_locale)
end)
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 2     |
| `enum`    | 2     |
| `fn`      | 15+   |
| **Total** | **19+** |

## References

| Module       | Relationship | Notes                                              |
|--------------|--------------|----------------------------------------------------|
| `engine`     | Imports from | `SharedState` used in `localization_api.rs` only   |
| `lua_api`    | Imported by  | `localization_api.rs` registers the Lua surface     |
| `filesystem` | —            | Tables are loaded from Lua directly, not read from files |

## Notes

- `Catalog::translate()` returns the key itself when not found — never panics, always returns a string.
- `flatten_lua_table` uses recursion depth-limited to 16 levels to guard against infinite Lua table cycles.
- The `thiserror` crate is required by `catalog.rs`; it must be in `[dependencies]` in `Cargo.toml`.
- `pluralFor` uses English two-form rules (`one`/`other`) — for Slavic languages call `pluralize_slavic` from Rust code directly.
- Callbacks registered with `onLanguageChange` are stored as `LuaRegistryKey` and are never GC'd unless the localization module is deregistered.
