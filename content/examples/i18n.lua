-- content/examples/i18n.lua
-- Practical usage examples for the lurek.i18n API (31 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.i18n.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/i18n.lua

print("[example] lurek.i18n — 31 API entries")

-- ── lurek.i18n.* free functions ──

--@api-stub: lurek.i18n.loadTable
-- Loads a language table under the given locale code.
-- Call when you need to load table.
local ok, obj = pcall(function() return lurek.i18n.loadTable(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.i18n.loadTable ok=", ok)

--@api-stub: lurek.i18n.unloadTable
-- Unloads a locale from the catalog.
-- Call when you need to invoke unload table.
local ok, result = pcall(function() return lurek.i18n.unloadTable(nil) end)
if ok then print("lurek.i18n.unloadTable ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.setLanguage
-- Sets the active translation language.
-- Call when you need to assign language.
local ok, err = pcall(function() lurek.i18n.setLanguage(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.i18n.setLanguage applied=", ok)

--@api-stub: lurek.i18n.getLanguage
-- Returns the currently active locale code, or nil if unset.
-- Call when you need to read language.
local ok, value = pcall(function() return lurek.i18n.getLanguage() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getLanguage ->", v)

--@api-stub: lurek.i18n.getLanguages
-- Returns all loaded locale codes.
-- Call when you need to read languages.
local ok, value = pcall(function() return lurek.i18n.getLanguages() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getLanguages ->", v)

--@api-stub: lurek.i18n.setFallbacks
-- Sets the ordered list of fallback locale codes tried when a key is missing.
-- Call when you need to assign fallbacks.
local ok, err = pcall(function() lurek.i18n.setFallbacks(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.i18n.setFallbacks applied=", ok)

--@api-stub: lurek.i18n.getFallbacks
-- Returns the current fallback locale array.
-- Call when you need to read fallbacks.
local ok, value = pcall(function() return lurek.i18n.getFallbacks() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getFallbacks ->", v)

--@api-stub: lurek.i18n.t
-- Translates a key against the active locale with optional variable.
-- Call when you need to invoke t.
local ok, result = pcall(function() return lurek.i18n.t("ui.greeting", nil, 10) end)
if ok then print("lurek.i18n.t ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.hasKey
-- Returns whether a key exists in the active locale.
-- Call when you need to check has key.
local ok, result = pcall(function() return lurek.i18n.hasKey("ui.greeting") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.i18n.hasKey ok=", ok)

--@api-stub: lurek.i18n.getKeys
-- Returns all known keys for the active locale.
-- Call when you need to read keys.
local ok, value = pcall(function() return lurek.i18n.getKeys() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getKeys ->", v)

--@api-stub: lurek.i18n.setKey
-- Inserts or overwrites a single key in the given locale.
-- Call when you need to assign key.
local ok, err = pcall(function() lurek.i18n.setKey(nil, "ui.greeting", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.i18n.setKey applied=", ok)

--@api-stub: lurek.i18n.interpolate
-- Interpolates {name} placeholders in a template string.
-- Call when you need to invoke interpolate.
local ok, result = pcall(function() return lurek.i18n.interpolate(nil, nil) end)
if ok then print("lurek.i18n.interpolate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.pluralFor
-- Returns the CLDR plural category for a number ("one" or "other", etc.).
-- Call when you need to invoke plural for.
local ok, result = pcall(function() return lurek.i18n.pluralFor(10) end)
if ok then print("lurek.i18n.pluralFor ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.onLanguageChange
-- Registers a callback invoked when setLanguage() is called.
-- Call when you need to invoke on language change.
local ok, result = pcall(function() return lurek.i18n.onLanguageChange(function() end) end)
if ok then print("lurek.i18n.onLanguageChange ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.hasLanguage
-- Returns whether a locale has been loaded.
-- Call when you need to check has language.
local ok, result = pcall(function() return lurek.i18n.hasLanguage(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.i18n.hasLanguage ok=", ok)

--@api-stub: lurek.i18n.getAvailableLanguages
-- Returns all loaded locale codes (alias for getLanguages).
-- Call when you need to read available languages.
local ok, value = pcall(function() return lurek.i18n.getAvailableLanguages() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getAvailableLanguages ->", v)

--@api-stub: lurek.i18n.setBase
-- Sets the base/fallback language (adds it as first fallback).
-- Call when you need to assign base.
local ok, err = pcall(function() lurek.i18n.setBase(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.i18n.setBase applied=", ok)

--@api-stub: lurek.i18n.getBase
-- Returns the base/fallback language.
-- Call when you need to read base.
local ok, value = pcall(function() return lurek.i18n.getBase() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getBase ->", v)

--@api-stub: lurek.i18n.onChange
-- Registers a callback invoked when setLanguage() is called (alias: onChange).
-- Call when you need to invoke on change.
local ok, result = pcall(function() return lurek.i18n.onChange(function() end) end)
if ok then print("lurek.i18n.onChange ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.offChange
-- Unregisters all onChange callbacks.
-- Call when you need to invoke off change.
local ok, result = pcall(function() return lurek.i18n.offChange() end)
if ok then print("lurek.i18n.offChange ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.keyCount
-- Returns the number of keys loaded in the active locale.
-- Call when you need to invoke key count.
local ok, result = pcall(function() return lurek.i18n.keyCount() end)
if ok then print("lurek.i18n.keyCount ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.categories
-- Returns unique first-path-segment category prefixes for all active locale keys.
-- Call when you need to invoke categories.
local ok, result = pcall(function() return lurek.i18n.categories() end)
if ok then print("lurek.i18n.categories ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.keysInCategory
-- Returns all keys in the active locale whose first path segment matches category.
-- Call when you need to invoke keys in category.
local ok, result = pcall(function() return lurek.i18n.keysInCategory(nil) end)
if ok then print("lurek.i18n.keysInCategory ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.search
-- Searches active locale values for a substring query (case-insensitive).
-- Returns {key, value} pairs.
local ok, result = pcall(function() return lurek.i18n.search(nil, nil) end)
if ok then print("lurek.i18n.search ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.buildIndex
-- Builds an inverted word index for the active locale.
-- Returns index as {word â†’ {keys}}.
local ok, obj = pcall(function() return lurek.i18n.buildIndex() end)
if ok and obj then print("created:", obj) end
print("lurek.i18n.buildIndex ok=", ok)

--@api-stub: lurek.i18n.searchIndexed
-- Searches the provided pre-built index for entries matching all words in query.
-- Call when you need to invoke search indexed.
local ok, result = pcall(function() return lurek.i18n.searchIndexed(1, nil, nil) end)
if ok then print("lurek.i18n.searchIndexed ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.mergeLocale
-- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
-- Call when you need to invoke merge locale.
local ok, result = pcall(function() return lurek.i18n.mergeLocale(nil, nil) end)
if ok then print("lurek.i18n.mergeLocale ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.formatNumber
-- Formats a number with locale-aware decimal and thousands separators.
-- Call when you need to invoke format number.
local ok, result = pcall(function() return lurek.i18n.formatNumber(10, {}) end)
if ok then print("lurek.i18n.formatNumber ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.formatDate
-- Formats a Unix timestamp according to the active locale's date order.
-- Call when you need to invoke format date.
local ok, result = pcall(function() return lurek.i18n.formatDate(nil, "fmt value") end)
if ok then print("lurek.i18n.formatDate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.tGender
-- Looks up a translation key augmented with a gender suffix.
-- Call when you need to invoke t gender.
local ok, result = pcall(function() return lurek.i18n.tGender("ui.greeting", nil, nil) end)
if ok then print("lurek.i18n.tGender ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.i18n.getLoadedLocales
-- Returns an array of all currently loaded locale codes.
-- Call when you need to read loaded locales.
local ok, value = pcall(function() return lurek.i18n.getLoadedLocales() end)
local v = ok and value or "(unavailable)"
print("lurek.i18n.getLoadedLocales ->", v)

