-- content/examples/i18n.lua
-- Scaffolded coverage of the lurek.i18n API (31 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/i18n_api.rs   (Lua binding, arg types, return shape)
--   * src/i18n/                 (semantics, side effects)
--   * docs/specs/i18n.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/i18n.lua

-- ── lurek.i18n.* functions ──

--@api-stub: lurek.i18n.loadTable
-- Loads a language table under the given locale code.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.loadTable
  local _todo = "TODO: write a real lurek.i18n.loadTable usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.unloadTable
-- Unloads a locale from the catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.unloadTable
  local _todo = "TODO: write a real lurek.i18n.unloadTable usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.setLanguage
-- Sets the active translation language.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.setLanguage
  local _todo = "TODO: write a real lurek.i18n.setLanguage usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getLanguage
-- Returns the currently active locale code, or nil if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getLanguage
  local _todo = "TODO: write a real lurek.i18n.getLanguage usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getLanguages
-- Returns all loaded locale codes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getLanguages
  local _todo = "TODO: write a real lurek.i18n.getLanguages usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.setFallbacks
-- Sets the ordered list of fallback locale codes tried when a key is missing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.setFallbacks
  local _todo = "TODO: write a real lurek.i18n.setFallbacks usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getFallbacks
-- Returns the current fallback locale array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getFallbacks
  local _todo = "TODO: write a real lurek.i18n.getFallbacks usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.t
-- Translates a key against the active locale with optional variable.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.t
  local _todo = "TODO: write a real lurek.i18n.t usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.hasKey
-- Returns whether a key exists in the active locale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.hasKey
  local _todo = "TODO: write a real lurek.i18n.hasKey usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getKeys
-- Returns all known keys for the active locale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getKeys
  local _todo = "TODO: write a real lurek.i18n.getKeys usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.setKey
-- Inserts or overwrites a single key in the given locale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.setKey
  local _todo = "TODO: write a real lurek.i18n.setKey usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.interpolate
-- Interpolates {name} placeholders in a template string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.interpolate
  local _todo = "TODO: write a real lurek.i18n.interpolate usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.pluralFor
-- Returns the CLDR plural category for a number ("one" or "other", etc.).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.pluralFor
  local _todo = "TODO: write a real lurek.i18n.pluralFor usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.onLanguageChange
-- Registers a callback invoked when setLanguage() is called.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.onLanguageChange
  local _todo = "TODO: write a real lurek.i18n.onLanguageChange usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.hasLanguage
-- Returns whether a locale has been loaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.hasLanguage
  local _todo = "TODO: write a real lurek.i18n.hasLanguage usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getAvailableLanguages
-- Returns all loaded locale codes (alias for getLanguages).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getAvailableLanguages
  local _todo = "TODO: write a real lurek.i18n.getAvailableLanguages usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.setBase
-- Sets the base/fallback language (adds it as first fallback).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.setBase
  local _todo = "TODO: write a real lurek.i18n.setBase usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getBase
-- Returns the base/fallback language.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getBase
  local _todo = "TODO: write a real lurek.i18n.getBase usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.onChange
-- Registers a callback invoked when setLanguage() is called (alias: onChange).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.onChange
  local _todo = "TODO: write a real lurek.i18n.onChange usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.offChange
-- Unregisters all onChange callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.offChange
  local _todo = "TODO: write a real lurek.i18n.offChange usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.keyCount
-- Returns the number of keys loaded in the active locale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.keyCount
  local _todo = "TODO: write a real lurek.i18n.keyCount usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.categories
-- Returns unique first-path-segment category prefixes for all active locale keys.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.categories
  local _todo = "TODO: write a real lurek.i18n.categories usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.keysInCategory
-- Returns all keys in the active locale whose first path segment matches category.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.keysInCategory
  local _todo = "TODO: write a real lurek.i18n.keysInCategory usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.search
-- Searches active locale values for a substring query (case-insensitive).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.search
  local _todo = "TODO: write a real lurek.i18n.search usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.buildIndex
-- Builds an inverted word index for the active locale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.buildIndex
  local _todo = "TODO: write a real lurek.i18n.buildIndex usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.searchIndexed
-- Searches the provided pre-built index for entries matching all words in query.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.searchIndexed
  local _todo = "TODO: write a real lurek.i18n.searchIndexed usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.mergeLocale
-- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.mergeLocale
  local _todo = "TODO: write a real lurek.i18n.mergeLocale usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.formatNumber
-- Formats a number with locale-aware decimal and thousands separators.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.formatNumber
  local _todo = "TODO: write a real lurek.i18n.formatNumber usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.formatDate
-- Formats a Unix timestamp according to the active locale's date order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.formatDate
  local _todo = "TODO: write a real lurek.i18n.formatDate usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.tGender
-- Looks up a translation key augmented with a gender suffix.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.tGender
  local _todo = "TODO: write a real lurek.i18n.tGender usage example"
  print(_todo)
end

--@api-stub: lurek.i18n.getLoadedLocales
-- Returns an array of all currently loaded locale codes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/i18n_api.rs and docs/specs/i18n.md).
do  -- TODO: lurek.i18n.getLoadedLocales
  local _todo = "TODO: write a real lurek.i18n.getLoadedLocales usage example"
  print(_todo)
end

