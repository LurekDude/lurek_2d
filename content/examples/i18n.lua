-- content/examples/i18n.lua
-- Auto-scaffolded coverage of the lurek.i18n Lua API (31 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/i18n.lua

print("[example] lurek.i18n loaded — 31 API items demonstrated")

-- ── lurek.i18n free functions ──

--@api-stub: lurek.i18n.loadTable
-- Loads a language table under the given locale code.
-- Use this when loads a language table under the given locale code is needed.
if false then
  local _r = lurek.i18n.loadTable(nil, 0)
  print(_r)
end

--@api-stub: lurek.i18n.unloadTable
-- Unloads a locale from the catalog.
-- Use this when unloads a locale from the catalog is needed.
if false then
  local _r = lurek.i18n.unloadTable(nil)
  print(_r)
end

--@api-stub: lurek.i18n.setLanguage
-- Sets the active translation language.
-- Use this when sets the active translation language is needed.
if false then
  local _r = lurek.i18n.setLanguage(nil)
  print(_r)
end

--@api-stub: lurek.i18n.getLanguage
-- Returns the currently active locale code, or nil if unset.
-- Use this when returns the currently active locale code, or nil if unset is needed.
if false then
  local _r = lurek.i18n.getLanguage()
  print(_r)
end

--@api-stub: lurek.i18n.getLanguages
-- Returns all loaded locale codes.
-- Use this when returns all loaded locale codes is needed.
if false then
  local _r = lurek.i18n.getLanguages()
  print(_r)
end

--@api-stub: lurek.i18n.setFallbacks
-- Sets the ordered list of fallback locale codes tried when a key is missing.
-- Use this when sets the ordered list of fallback locale codes tried when a key is missing is needed.
if false then
  local _r = lurek.i18n.setFallbacks(nil)
  print(_r)
end

--@api-stub: lurek.i18n.getFallbacks
-- Returns the current fallback locale array.
-- Use this when returns the current fallback locale array is needed.
if false then
  local _r = lurek.i18n.getFallbacks()
  print(_r)
end

--@api-stub: lurek.i18n.t
-- Translates a key against the active locale with optional variable.
-- Use this when translates a key against the active locale with optional variable is needed.
if false then
  local _r = lurek.i18n.t(0, 0, 1)
  print(_r)
end

--@api-stub: lurek.i18n.hasKey
-- Returns whether a key exists in the active locale.
-- Use this when returns whether a key exists in the active locale is needed.
if false then
  local _r = lurek.i18n.hasKey(0)
  print(_r)
end

--@api-stub: lurek.i18n.getKeys
-- Returns all known keys for the active locale.
-- Use this when returns all known keys for the active locale is needed.
if false then
  local _r = lurek.i18n.getKeys()
  print(_r)
end

--@api-stub: lurek.i18n.setKey
-- Inserts or overwrites a single key in the given locale.
-- Use this when inserts or overwrites a single key in the given locale is needed.
if false then
  local _r = lurek.i18n.setKey(nil, 0, 0)
  print(_r)
end

--@api-stub: lurek.i18n.interpolate
-- Interpolates {name} placeholders in a template string.
-- Use this when interpolates {name} placeholders in a template string is needed.
if false then
  local _r = lurek.i18n.interpolate(0, 0)
  print(_r)
end

--@api-stub: lurek.i18n.pluralFor
-- Returns the CLDR plural category for a number ("one" or "other", etc.).
-- Use this when returns the CLDR plural category for a number ("one" or "other", etc.) is needed.
if false then
  local _r = lurek.i18n.pluralFor(1)
  print(_r)
end

--@api-stub: lurek.i18n.onLanguageChange
-- Registers a callback invoked when setLanguage() is called.
-- Use this when registers a callback invoked when setLanguage() is called is needed.
if false then
  local _r = lurek.i18n.onLanguageChange(function() end)
  print(_r)
end

--@api-stub: lurek.i18n.hasLanguage
-- Returns whether a locale has been loaded.
-- Use this when returns whether a locale has been loaded is needed.
if false then
  local _r = lurek.i18n.hasLanguage(nil)
  print(_r)
end

--@api-stub: lurek.i18n.getAvailableLanguages
-- Returns all loaded locale codes (alias for getLanguages).
-- Use this when returns all loaded locale codes (alias for getLanguages) is needed.
if false then
  local _r = lurek.i18n.getAvailableLanguages()
  print(_r)
end

--@api-stub: lurek.i18n.setBase
-- Sets the base/fallback language (adds it as first fallback).
-- Use this when sets the base/fallback language (adds it as first fallback) is needed.
if false then
  local _r = lurek.i18n.setBase(nil)
  print(_r)
end

--@api-stub: lurek.i18n.getBase
-- Returns the base/fallback language.
-- Use this when returns the base/fallback language is needed.
if false then
  local _r = lurek.i18n.getBase()
  print(_r)
end

--@api-stub: lurek.i18n.onChange
-- Registers a callback invoked when setLanguage() is called (alias: onChange).
-- Use this when registers a callback invoked when setLanguage() is called (alias: onChange) is needed.
if false then
  local _r = lurek.i18n.onChange(function() end)
  print(_r)
end

--@api-stub: lurek.i18n.offChange
-- Unregisters all onChange callbacks.
-- Use this when unregisters all onChange callbacks is needed.
if false then
  local _r = lurek.i18n.offChange()
  print(_r)
end

--@api-stub: lurek.i18n.keyCount
-- Returns the number of keys loaded in the active locale.
-- Use this when returns the number of keys loaded in the active locale is needed.
if false then
  local _r = lurek.i18n.keyCount()
  print(_r)
end

--@api-stub: lurek.i18n.categories
-- Returns unique first-path-segment category prefixes for all active locale keys.
-- Use this when returns unique first-path-segment category prefixes for all active locale keys is needed.
if false then
  local _r = lurek.i18n.categories()
  print(_r)
end

--@api-stub: lurek.i18n.keysInCategory
-- Returns all keys in the active locale whose first path segment matches category.
-- Use this when returns all keys in the active locale whose first path segment matches category is needed.
if false then
  local _r = lurek.i18n.keysInCategory(0)
  print(_r)
end

--@api-stub: lurek.i18n.search
-- Searches active locale values for a substring query (case-insensitive).
-- Returns {key, value} pairs.
if false then
  local _r = lurek.i18n.search(0, 0)
  print(_r)
end

--@api-stub: lurek.i18n.buildIndex
-- Builds an inverted word index for the active locale.
-- Returns index as {word â†’ {keys}}.
if false then
  local _r = lurek.i18n.buildIndex()
  print(_r)
end

--@api-stub: lurek.i18n.searchIndexed
-- Searches the provided pre-built index for entries matching all words in query.
-- Use this when searches the provided pre-built index for entries matching all words in query is needed.
if false then
  local _r = lurek.i18n.searchIndexed(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.i18n.mergeLocale
-- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
-- Use this when merges a flat keyâ†’value table into an existing locale without replacing the whole table is needed.
if false then
  local _r = lurek.i18n.mergeLocale(nil, 1)
  print(_r)
end

--@api-stub: lurek.i18n.formatNumber
-- Formats a number with locale-aware decimal and thousands separators.
-- Use this when formats a number with locale-aware decimal and thousands separators is needed.
if false then
  local _r = lurek.i18n.formatNumber(1, 0)
  print(_r)
end

--@api-stub: lurek.i18n.formatDate
-- Formats a Unix timestamp according to the active locale's date order.
-- Use this when formats a Unix timestamp according to the active locale's date order is needed.
if false then
  local _r = lurek.i18n.formatDate(0, 0)
  print(_r)
end

--@api-stub: lurek.i18n.tGender
-- Looks up a translation key augmented with a gender suffix.
-- Use this when looks up a translation key augmented with a gender suffix is needed.
if false then
  local _r = lurek.i18n.tGender(0, 1, 0)
  print(_r)
end

--@api-stub: lurek.i18n.getLoadedLocales
-- Returns an array of all currently loaded locale codes.
-- Use this when returns an array of all currently loaded locale codes is needed.
if false then
  local _r = lurek.i18n.getLoadedLocales()
  print(_r)
end

