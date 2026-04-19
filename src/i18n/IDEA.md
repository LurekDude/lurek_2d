# IDEA.md — `i18n` module

| Field           | Value         |
| --------------- | ------------- |
| **Module**      | `i18n`        |
| **Path**        | `src/i18n/`   |
| **Date**        | 2026-04-18    |
| **Plugin Tier** | TIER-2-PLUGIN |

---

## Mission Summary

The `i18n` module provides Lurek2D's internationalization and localization system. It manages multi-locale string catalogs with dot-path key resolution, fallback chains, `{variable}` interpolation, and CLDR-style plural form selection (including Slavic rules). Exposed to Lua as `lurek.i18n.*`.

## Existing Strengths

- Clean separation: `Catalog` (storage), `interpolation` (substitution), `plural` (form selection).
- Fallback chain handles missing keys gracefully (returns the key itself as last resort).
- Slavic plural rules cover Polish/Russian/Ukrainian — rare in 2D engines.
- Inverted word index (`build_index`) enables efficient repeated searches on large catalogs.
- No external crate dependencies beyond `thiserror` — lightweight.
- `{{double braces}}` escape convention matches industry standard (Handlebars, Rust `format!`).

## Gap List

1. No TOML/JSON file loading from disk — `Catalog::load` accepts pre-parsed `HashMap`, so file I/O is done entirely in the Lua API layer.
2. No locale auto-detection (system locale or browser accept-language).
3. No RTL (right-to-left) text direction hint forwarded to the font renderer.
4. No ICU MessageFormat or gender-aware plural rules beyond the basic CLDR six categories.
5. No locale validation — any string is accepted as a locale code.
6. No key diff / coverage audit — can't detect which keys are missing across locales.

## Feature Ideas

1. **Locale file auto-loader** — Load all `*.toml` files from a `locales/` directory automatically. *Citation*: LÖVE2D's `i18n` community library pattern loads flat files by convention.
2. **Locale coverage audit** — `lurek.i18n.coverage()` returns `{locale → missingKeys[]}` across all loaded locales. *Citation*: Godot's `POT Generation` and `Translation Remaps` provide built-in coverage checking.
3. **RTL text direction hint** — `lurek.i18n.isRTL()` returns `true` for Hebrew/Arabic locales so the UI layout system can mirror. *Citation*: Solar2D provides `system.getPreference("locale", "language")` but no built-in RTL support; Godot's `TextServer` has `is_locale_right_to_left()`.

## Perf/Quality Ideas

- `categories()` and `keys_in_category()` scan all keys on every call — consider caching if catalogs exceed 10k entries.
- `build_index()` allocates a fresh `HashMap` every call — could be cached on the Catalog and invalidated on `load`/`set_key`/`merge`.
- `search()` is O(n) over all values — acceptable for interactive use but not for per-frame lookups.

## Test Coverage Gaps

- `catalog.rs` has 19 tests covering all public methods — solid.
- `plural.rs` has 12 tests covering all PluralForm methods + pluralize functions.
- `interpolation.rs` has 10 tests including edge cases (unterminated, empty, no vars).
- Inline comments expanded in `interpolation.rs` (parser loop) and `catalog.rs` (`build_index`).
- No Lua-level tests exist for `lurek.i18n.*` (identified in P4 matrix).

## TODO(dedup): Entries

- `TODO(dedup): serial::toml — Catalog could delegate TOML locale file parsing to crate::serial instead of relying on the Lua API layer to pre-parse tables.`

## TODO(helper): Entries

- `TODO(helper): i18n-loader — A content/library/ helper that auto-discovers and loads locale TOML files from a conventional directory, reducing boilerplate in game scripts.`

## TODO(plugin): Entry

- `TODO(plugin): TIER-2-PLUGIN — i18n has zero dependencies on render/audio/physics and is opt-in for games that don't need localization. Extracting it as a Cargo feature or plugin crate would reduce binary size for single-language games. Low priority since the module is lightweight (~400 lines).`

## References

- `src/lua_api/i18n_api.rs` — Lua binding layer
- `docs/specs/i18n.md` — Module specification
- CLDR Plural Rules: <https://cldr.unicode.org/index/cldr-spec/plural-rules>
