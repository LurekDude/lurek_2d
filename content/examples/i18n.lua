-- content/examples/i18n.lua
-- Hand-written coverage of the lurek.i18n API (31 items).
--
-- Translation tables are flat dot-path maps ("ui.menu.start" = "Start") and the
-- catalog falls back through setFallbacks() when a key is missing. `t` handles
-- {placeholder} interpolation and CLDR-style .one/.other plural variants.
--
-- Run: cargo run -- content/examples/i18n.lua

-- â”€â”€ lurek.i18n.* functions â”€â”€

--@api-stub: lurek.i18n.loadTable
-- Loads a language table under the given locale code.
-- Pass a nested table; keys are flattened with dot-paths so designers can group strings naturally.
do -- lurek.i18n.loadTable
  lurek.i18n.loadTable("en", {
    ui = { start = "Start", quit = "Quit" },
    hud = { score = "Score: {n}" },
  })
end

--@api-stub: lurek.i18n.unloadTable
-- Unloads a locale from the catalog.
-- Returns true if the locale existed; useful when hot-swapping language packs from a mod folder.
do -- lurek.i18n.unloadTable
  lurek.i18n.loadTable("xx", { ui = { start = "Go" } })
  local removed = lurek.i18n.unloadTable("xx")
  lurek.log.info("xx removed=" .. tostring(removed), "i18n")
end

--@api-stub: lurek.i18n.setLanguage
-- Sets the active translation language.
-- Fires every onLanguageChange callback with (new, old); call after loadTable for that locale.
do -- lurek.i18n.setLanguage
  lurek.i18n.loadTable("fr", { ui = { start = "Commencer" } })
  lurek.i18n.setLanguage("fr")
end

--@api-stub: lurek.i18n.getLanguage
-- Returns the currently active locale code, or nil if unset.
-- Branch on this when persisting the player's language choice into the save file.
do -- lurek.i18n.getLanguage
  local active = lurek.i18n.getLanguage()
  if active then
    lurek.log.info("active locale=" .. active, "i18n")
  end
end

--@api-stub: lurek.i18n.getLanguages
-- Returns all loaded locale codes.
-- Use to populate a language-picker dropdown in the options menu.
do -- lurek.i18n.getLanguages
  for _, code in ipairs(lurek.i18n.getLanguages()) do
    lurek.log.info("available: " .. code, "i18n")
  end
end

--@api-stub: lurek.i18n.setFallbacks
-- Sets the ordered list of fallback locale codes tried when a key is missing.
-- Order matters: regional variants first, then base language, then English as a last resort.
do -- lurek.i18n.setFallbacks
  lurek.i18n.loadTable("en", { ui = { quit = "Quit" } })
  lurek.i18n.setFallbacks({ "en-US", "en" })
end

--@api-stub: lurek.i18n.getFallbacks
-- Returns the current fallback locale array.
-- Inspect on startup to verify a config file was applied before any translation lookup runs.
do -- lurek.i18n.getFallbacks
  local chain = lurek.i18n.getFallbacks()
  lurek.log.info("fallback depth=" .. #chain, "i18n")
end

--@api-stub: lurek.i18n.t
-- Translates a key against the active locale with optional variable substitution and pluralization.
-- Pass a vars table for {name} placeholders; pass count to pick between key.one and key.other.
do -- lurek.i18n.t
  lurek.i18n.loadTable("en", {
    hud = { score = "Score: {n}", lives = { one = "1 life", other = "{count} lives" } },
  })
  lurek.i18n.setLanguage("en")
  local hud = lurek.i18n.t("hud.score", { n = "1500" })
  local lives = lurek.i18n.t("hud.lives", nil, 3)
  lurek.log.info(hud .. " / " .. lives, "i18n")
end

--@api-stub: lurek.i18n.hasKey
-- Returns whether a key exists in the active locale.
-- Use before t() when a missing key should trigger a different code path rather than a placeholder string.
do -- lurek.i18n.hasKey
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.setLanguage("en")
  if not lurek.i18n.hasKey("ui.credits") then
    lurek.log.warn("ui.credits not localised yet", "i18n")
  end
end

--@api-stub: lurek.i18n.getKeys
-- Returns all known keys for the active locale.
-- Handy for editor tooling or dumping a coverage diff against a reference locale.
do -- lurek.i18n.getKeys
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  local total = #lurek.i18n.getKeys()
  lurek.log.info("en key count=" .. total, "i18n")
end

--@api-stub: lurek.i18n.setKey
-- Inserts or overwrites a single key in the given locale.
-- Useful for runtime patches (mod overrides, dynamic NPC names) without rebuilding the table.
do -- lurek.i18n.setKey
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.setKey("en", "ui.continue", "Continue")
  lurek.i18n.setLanguage("en")
  lurek.log.info(lurek.i18n.t("ui.continue"), "i18n")
end

--@api-stub: lurek.i18n.interpolate
-- Interpolates {name} placeholders in a template string.
-- Reach for this when formatting strings that aren't in the catalog (debug overlays, log lines).
do -- lurek.i18n.interpolate
  local msg = lurek.i18n.interpolate(
    "Player {name} reached level {lvl}",
    { name = "Aria", lvl = "7" }
  )
  lurek.log.info(msg, "i18n")
end

--@api-stub: lurek.i18n.pluralFor
-- Returns the CLDR plural category for a number ("one" or "other", etc.).
-- Use to pick a manual plural variant when t()'s built-in plural lookup isn't enough.
do -- lurek.i18n.pluralFor
  for _, n in ipairs({ 0, 1, 5 }) do
    local cat = lurek.i18n.pluralFor(n)
    lurek.log.info("n=" .. n .. " -> " .. cat, "i18n")
  end
end

--@api-stub: lurek.i18n.onLanguageChange
-- Registers a callback invoked when setLanguage() is called.
-- Use to refresh cached string textures (font atlases, pre-rendered HUD labels) on language switch.
do -- lurek.i18n.onLanguageChange
  lurek.i18n.onLanguageChange(function(new_locale, old_locale)
    lurek.log.info("locale changed " .. tostring(old_locale) .. " -> " .. new_locale, "i18n")
  end)
  lurek.i18n.loadTable("de", { ui = { start = "Start" } })
  lurek.i18n.setLanguage("de")
end

--@api-stub: lurek.i18n.hasLanguage
-- Returns whether a locale has been loaded.
-- Cheaper than scanning getLanguages(); call before setLanguage() to avoid switching to an empty catalog.
do -- lurek.i18n.hasLanguage
  lurek.i18n.loadTable("ja", { ui = { start = "é–‹ĺ§‹" } })
  if lurek.i18n.hasLanguage("ja") then
    lurek.i18n.setLanguage("ja")
  end
end

--@api-stub: lurek.i18n.getAvailableLanguages
-- Returns all loaded locale codes (alias for getLanguages).
-- Prefer this name in UI code where "available" reads better than "loaded".
do -- lurek.i18n.getAvailableLanguages
  local langs = lurek.i18n.getAvailableLanguages()
  lurek.log.info("options menu langs=" .. #langs, "i18n")
end

--@api-stub: lurek.i18n.setBase
-- Sets the base/fallback language (adds it as first fallback).
-- Set once at boot to the locale your source strings are written in (typically "en").
do -- lurek.i18n.setBase
  lurek.i18n.setBase("en")
end

--@api-stub: lurek.i18n.getBase
-- Returns the base/fallback language.
-- Use to know which locale a translator should diff their work against.
do -- lurek.i18n.getBase
  local base = lurek.i18n.getBase()
  if base ~= "" then
    lurek.log.info("source locale=" .. base, "i18n")
  end
end

--@api-stub: lurek.i18n.onChange
-- Registers a callback invoked when setLanguage() is called (alias: onChange).
-- Shorter spelling; both onChange and onLanguageChange push to the same callback list.
do -- lurek.i18n.onChange
  lurek.i18n.onChange(function(new_locale, _old)
    lurek.log.info("UI rebuild for " .. new_locale, "i18n")
  end)
end

--@api-stub: lurek.i18n.offChange
-- Unregisters all onChange callbacks.
-- Call on scene teardown so dead UI handlers don't fire when the next scene switches language.
do -- lurek.i18n.offChange
  lurek.i18n.onChange(function() end)
  lurek.i18n.offChange()
  lurek.log.info("locale-change handlers cleared", "i18n")
end

--@api-stub: lurek.i18n.keyCount
-- Returns the number of keys loaded in the active locale.
-- Display in a dev overlay to spot when a locale ships with far fewer entries than the base.
do -- lurek.i18n.keyCount
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  lurek.log.info("active locale has " .. lurek.i18n.keyCount() .. " keys", "i18n")
end

--@api-stub: lurek.i18n.categories
-- Returns unique first-path-segment category prefixes for all active locale keys.
-- Use to drive a sectioned in-game string browser ("ui", "hud", "dialog", ...).
do -- lurek.i18n.categories
  lurek.i18n.loadTable("en", { ui = { start = "Start" }, hud = { score = "S" } })
  lurek.i18n.setLanguage("en")
  for _, c in ipairs(lurek.i18n.categories()) do
    lurek.log.info("category " .. c, "i18n")
  end
end

--@api-stub: lurek.i18n.keysInCategory
-- Returns all keys in the active locale whose first path segment matches category.
-- Pair with categories() to lazily build a translator-tools panel one section at a time.
do -- lurek.i18n.keysInCategory
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  local ui_keys = lurek.i18n.keysInCategory("ui")
  lurek.log.info("ui-section keys=" .. #ui_keys, "i18n")
end

--@api-stub: lurek.i18n.search
-- Searches active locale values for a substring query (case-insensitive).
-- For one-off searches; build an inverted index (buildIndex) when querying repeatedly.
do -- lurek.i18n.search
  lurek.i18n.loadTable("en", { ui = { start = "Start", restart = "Restart" } })
  lurek.i18n.setLanguage("en")
  local hits = lurek.i18n.search("start", 10)
  lurek.log.info("matches=" .. #hits, "i18n")
end

--@api-stub: lurek.i18n.buildIndex
-- Builds an inverted word index for the active locale.
-- Cache the returned table once; repeat searchIndexed() calls run in O(query words) instead of O(keys).
do -- lurek.i18n.buildIndex
  lurek.i18n.loadTable("en", { ui = { start = "Start game", quit = "Quit game" } })
  lurek.i18n.setLanguage("en")
  local index = lurek.i18n.buildIndex()
  lurek.log.info("indexed words=" .. tostring(next(index) ~= nil), "i18n")
end

--@api-stub: lurek.i18n.searchIndexed
-- Searches the provided pre-built index for entries matching all words in query.
-- Multi-word queries intersect the per-word key sets, so order of words doesn't matter.
do -- lurek.i18n.searchIndexed
  lurek.i18n.loadTable("en", { ui = { start = "Start game", quit = "Quit game" } })
  lurek.i18n.setLanguage("en")
  local index = lurek.i18n.buildIndex()
  local matches = lurek.i18n.searchIndexed(index, "start game", 5)
  lurek.log.info("indexed matches=" .. #matches, "i18n")
end

--@api-stub: lurek.i18n.mergeLocale
-- Merges a flat keyâ†’value table into an existing locale without replacing the whole table.
-- Use for incremental loads: ship the base pack at boot, then merge per-scene strings on demand.
do -- lurek.i18n.mergeLocale
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.mergeLocale("en", {
    ["dialog.intro"] = "Welcome, traveller.",
    ["dialog.outro"] = "Farewell.",
  })
end

--@api-stub: lurek.i18n.formatNumber
-- Formats a number with locale-aware decimal and thousands separators.
-- European locales (de, fr, ...) emit "1.234,50"; pass {decimals=N} to control precision.
do -- lurek.i18n.formatNumber
  lurek.i18n.setLanguage("de")
  local price = lurek.i18n.formatNumber(1234.5, { decimals = 2 })
  lurek.log.info("DE price=" .. price, "i18n")
end

--@api-stub: lurek.i18n.formatDate
-- Formats a Unix timestamp according to the active locale's date order.
-- Pass "iso" for machine-readable, "short" for HUD use, "long" for dialog/UI prose.
do -- lurek.i18n.formatDate
  lurek.i18n.setLanguage("en")
  local stamp = lurek.i18n.formatDate(1700000000, "long")
  lurek.log.info("save written " .. stamp, "i18n")
end

--@api-stub: lurek.i18n.tGender
-- Looks up a translation key augmented with a gender suffix.
-- Falls back to the bare key if the gendered variant is missing, so partial coverage is safe.
do -- lurek.i18n.tGender
  lurek.i18n.loadTable("en", {
    npc = {
      greet = {
        masculine = "He waves at you.",
        feminine = "She waves at you.",
        neutral = "They wave at you.",
      },
    },
  })
  lurek.i18n.setLanguage("en")
  local line = lurek.i18n.tGender("npc.greet", "feminine")
  lurek.log.info(line, "i18n")
end

--@api-stub: lurek.i18n.getLoadedLocales
-- Returns an array of all currently loaded locale codes.
-- Equivalent to getLanguages(); prefer this name in save/load code that talks about "locales".
do -- lurek.i18n.getLoadedLocales
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.loadTable("fr", { ui = { start = "Commencer" } })
  local locales = lurek.i18n.getLoadedLocales()
  lurek.log.info("loaded locale count=" .. #locales, "i18n")
end

--@api-stub: lurek.i18n.isRTL
-- Returns true when the locale uses a right-to-left writing direction.
-- Pass an explicit locale code or omit to test the active locale; use the return value to mirror UI layouts.
do -- lurek.i18n.isRTL
  local rtl_arabic = lurek.i18n.isRTL("ar-SA")    -- true
  local ltr_english = lurek.i18n.isRTL("en-US")   -- false
  local active_rtl = lurek.i18n.isRTL()            -- tests current locale
  lurek.log.info(("ar-SA isRTL=%s  en-US isRTL=%s  active isRTL=%s"):format(
    tostring(rtl_arabic), tostring(ltr_english), tostring(active_rtl)), "i18n")
end

--@api-stub: lurek.i18n.validateLocale
-- Returns true when a locale code conforms to the BCP 47 subset accepted by the catalog.
-- Validate before calling loadTable or setLanguage when the code comes from user input or a config file.
do -- lurek.i18n.validateLocale
  local ok_code   = lurek.i18n.validateLocale("en-US")   -- true
  local bad_code  = lurek.i18n.validateLocale("1bad")     -- false
  local empty     = lurek.i18n.validateLocale("")          -- false
  lurek.log.info(("en-US=%s  1bad=%s  empty=%s"):format(
    tostring(ok_code), tostring(bad_code), tostring(empty)), "i18n")
end

--@api-stub: lurek.i18n.detectLocale
-- Reads LANG / LANGUAGE / LC_ALL / LC_MESSAGES to guess the system locale.
-- Use on first launch to pre-select the player's language before showing the settings menu.
do -- lurek.i18n.detectLocale
  local detected = lurek.i18n.detectLocale()
  if detected then
    lurek.log.info("system locale detected: " .. detected, "i18n")
  else
    lurek.log.info("no system locale detected (CI / Windows without LANG)", "i18n")
  end
end

--@api-stub: lurek.i18n.loadString
-- Parses a TOML or JSON string and registers it as a locale translation table.
-- Useful for loading locale data from GameFS without a custom parser; the flat key-path format
-- matches loadTable so both sources can co-exist under the same locale code.
do -- lurek.i18n.loadString — TOML
  local toml_src = [[
[ui]
ok     = "OK"
cancel = "Cancel"
[item]
sword  = "Iron Sword"
]]
  lurek.i18n.loadString("demo_toml", toml_src, "toml")
  lurek.i18n.setLanguage("demo_toml")
  lurek.log.info("ok=" .. lurek.i18n.t("ui.ok"), "i18n")
  lurek.log.info("sword=" .. lurek.i18n.t("item.sword"), "i18n")
end

do -- lurek.i18n.loadString — JSON
  local json_src = '{"menu":{"start":"Start","quit":"Quit"}}'
  lurek.i18n.loadString("demo_json", json_src, "json")
  lurek.i18n.setLanguage("demo_json")
  lurek.log.info("start=" .. lurek.i18n.t("menu.start"), "i18n")
end

--@api-stub: lurek.i18n.localeCoverage
-- Returns an array of coverage gaps: keys present in the reference locale but absent in others.
-- Run in a test mode or startup check to alert authors before shipping a release.
do -- lurek.i18n.localeCoverage
  lurek.i18n.loadTable("ref_en", { hello = "Hello", bye = "Goodbye", ok = "OK" })
  lurek.i18n.loadTable("ref_fr", { hello = "Bonjour", ok = "Oui" })  -- 'bye' missing
  lurek.i18n.loadTable("ref_de", { hello = "Hallo", bye = "Tschüss" }) -- 'ok' missing

  local gaps = lurek.i18n.localeCoverage("ref_en")
  for _, gap in ipairs(gaps) do
    lurek.log.warn(("missing key '%s' in: %s"):format(
      gap.key, table.concat(gap.missing_in, ", ")), "i18n")
  end
end
