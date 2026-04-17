-- content/examples/i18n.lua
-- Lurek2D lurek.i18n API Reference
-- Run with: cargo run -- content/examples/i18n
--
-- Scenario: A multilingual RPG with English/Spanish/Polish translations,
-- gender-aware dialogue, plural-aware item counts, number/date formatting,
-- and a searchable translation editor for modders.

print("=== lurek.i18n — Internationalization ===\n")

-- =============================================================================
-- Loading Translation Tables
-- =============================================================================

--@api-stub: lurek.i18n.loadTable
-- Load the English locale from a TOML file.
lurek.i18n.loadTable("en", "assets/locales/en.toml")
lurek.i18n.loadTable("es", "assets/locales/es.toml")
lurek.i18n.loadTable("pl", "assets/locales/pl.toml")
print("loaded 3 locales")

--@api-stub: lurek.i18n.getLoadedLocales
local loaded = lurek.i18n.getLoadedLocales()
print("loaded locales: " .. table.concat(loaded, ", "))

--@api-stub: lurek.i18n.unloadTable
lurek.i18n.unloadTable("es")
print("Spanish unloaded (to free memory)")
lurek.i18n.loadTable("es", "assets/locales/es.toml")

-- =============================================================================
-- Language Selection
-- =============================================================================

--@api-stub: lurek.i18n.setLanguage
lurek.i18n.setLanguage("en")

--@api-stub: lurek.i18n.getLanguage
print("current: " .. lurek.i18n.getLanguage())

--@api-stub: lurek.i18n.getLanguages
local langs = lurek.i18n.getLanguages()
print("languages: " .. table.concat(langs, ", "))

--@api-stub: lurek.i18n.hasLanguage
print("has Polish: " .. tostring(lurek.i18n.hasLanguage("pl")))

--@api-stub: lurek.i18n.getAvailableLanguages
local avail = lurek.i18n.getAvailableLanguages()
print("available: " .. table.concat(avail, ", "))

-- =============================================================================
-- Base Language & Fallbacks
-- =============================================================================

--@api-stub: lurek.i18n.setBase
lurek.i18n.setBase("en")

--@api-stub: lurek.i18n.getBase
print("base language: " .. lurek.i18n.getBase())

--@api-stub: lurek.i18n.setFallbacks
-- If a key is missing in Spanish, fall back to English.
lurek.i18n.setFallbacks({"en"})

--@api-stub: lurek.i18n.getFallbacks
local fb = lurek.i18n.getFallbacks()
print("fallbacks: " .. table.concat(fb, ", "))

-- =============================================================================
-- Translation Lookup
-- =============================================================================

--@api-stub: lurek.i18n.t
-- Core translation function.
print(lurek.i18n.t("menu.play"))
print(lurek.i18n.t("menu.settings"))

--@api-stub: lurek.i18n.hasKey
print("has 'menu.play': " .. tostring(lurek.i18n.hasKey("menu.play")))

--@api-stub: lurek.i18n.setKey
-- Dynamically add a translation at runtime (e.g. from mod content).
lurek.i18n.setKey("mod.greeting", "Hello from the mod!")

--@api-stub: lurek.i18n.interpolate
-- Variable substitution in translated strings.
local msg = lurek.i18n.interpolate("item.acquired", {item = "Iron Sword", count = 1})
print("interpolated: " .. msg)

--@api-stub: lurek.i18n.pluralFor
-- Get the correct plural form for a count.
local form = lurek.i18n.pluralFor(5)
print("plural form for 5: " .. form)

--@api-stub: lurek.i18n.tGender
-- Gender-aware translation for gendered languages.
local gendered = lurek.i18n.tGender("npc.greeting", "female")
print("gendered: " .. gendered)

-- =============================================================================
-- Key Management & Categories
-- =============================================================================

--@api-stub: lurek.i18n.getKeys
local keys = lurek.i18n.getKeys()
print("total keys: " .. #keys)

--@api-stub: lurek.i18n.keyCount
print("key count: " .. lurek.i18n.keyCount())

--@api-stub: lurek.i18n.categories
local cats = lurek.i18n.categories()
print("categories: " .. table.concat(cats, ", "))

--@api-stub: lurek.i18n.keysInCategory
local menu_keys = lurek.i18n.keysInCategory("menu")
print("menu keys: " .. #menu_keys)

-- =============================================================================
-- Search & Indexing (for mod translation editors)
-- =============================================================================

--@api-stub: lurek.i18n.search
-- Search translations by substring (useful for editor/debug tools).
local results = lurek.i18n.search("sword")
print("search 'sword': " .. #results .. " hits")

--@api-stub: lurek.i18n.buildIndex
-- Build a search index for fast lookups.
lurek.i18n.buildIndex()
print("search index built")

--@api-stub: lurek.i18n.searchIndexed
-- Fast indexed search after buildIndex().
local indexed = lurek.i18n.searchIndexed("potion")
print("indexed search 'potion': " .. #indexed .. " hits")

-- =============================================================================
-- Merging Locales (for mod support)
-- =============================================================================

--@api-stub: lurek.i18n.mergeLocale
-- Merge additional translations from a mod into the current locale.
lurek.i18n.mergeLocale("en", {["mod.item.name"] = "Enchanted Ring"})
print("mod locale merged")

-- =============================================================================
-- Formatting
-- =============================================================================

--@api-stub: lurek.i18n.formatNumber
-- Locale-aware number formatting.
print("number: " .. lurek.i18n.formatNumber(1234567.89))

--@api-stub: lurek.i18n.formatDate
-- Locale-aware date formatting.
print("date: " .. lurek.i18n.formatDate(os.time()))

-- =============================================================================
-- Change Callbacks
-- =============================================================================

--@api-stub: lurek.i18n.onLanguageChange
lurek.i18n.onLanguageChange(function(old_lang, new_lang)
    print("language changed: " .. old_lang .. " -> " .. new_lang)
end)

--@api-stub: lurek.i18n.onChange
local cb_id = lurek.i18n.onChange(function(key, value)
    print("translation updated: " .. key)
end)

--@api-stub: lurek.i18n.offChange
lurek.i18n.offChange(cb_id)

print("\n-- i18n.lua example complete --")
