-- content/examples/i18n.lua
-- lurek.i18n API examples.
-- Run: cargo run -- content/examples/i18n.lua

--@api-stub: lurek.i18n.loadTable
-- Loads translations for a locale from a nested Lua table flattened with dot-separated keys
do
  lurek.i18n.loadTable("en", {
    ui = { start = "Start", quit = "Quit" },
    hud = { score = "Score: {n}" },
  })
end

--@api-stub: lurek.i18n.unloadTable
-- Removes all translations for a locale from the catalog
do
  lurek.i18n.loadTable("xx", { ui = { start = "Go" } })
  local removed = lurek.i18n.unloadTable("xx")
  lurek.log.info("xx removed=" .. tostring(removed), "i18n")
end

--@api-stub: lurek.i18n.setLanguage
-- Sets the active locale and invokes registered change callbacks with new and old locale values
do
  lurek.i18n.loadTable("fr", { ui = { start = "Commencer" } })
  lurek.i18n.setLanguage("fr")
end

--@api-stub: lurek.i18n.getLanguage
-- Returns the active locale code
do
  local active = lurek.i18n.getLanguage()
  if active then
    lurek.log.info("active locale=" .. active, "i18n")
  end
end

--@api-stub: lurek.i18n.getLanguages
-- Returns sorted locale codes currently loaded in the catalog
do
  for _, code in ipairs(lurek.i18n.getLanguages()) do
    lurek.log.info("available: " .. code, "i18n")
  end
end

--@api-stub: lurek.i18n.setFallbacks
-- Replaces the fallback locale list used for missing translations
do
  lurek.i18n.loadTable("en", { ui = { quit = "Quit" } })
  lurek.i18n.setFallbacks({ "en-US", "en" })
end

--@api-stub: lurek.i18n.getFallbacks
-- Returns fallback locale codes in lookup order
do
  local chain = lurek.i18n.getFallbacks()
  lurek.log.info("fallback depth=" .. #chain, "i18n")
end

--@api-stub: lurek.i18n.t
-- Translates a key using the active locale, optional variables, and optional English plural selection
do
  lurek.i18n.loadTable("en", {
    hud = { score = "Score: {n}", lives = { one = "1 life", other = "{count} lives" } },
  })
  lurek.i18n.setLanguage("en")
  local hud = lurek.i18n.t("hud.score", { n = "1500" })
  local lives = lurek.i18n.t("hud.lives", nil, 3)
  lurek.log.info(hud .. " / " .. lives, "i18n")
end

--@api-stub: lurek.i18n.hasKey
-- Returns whether the catalog contains a translation key in active or fallback locales
do
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.setLanguage("en")
  if not lurek.i18n.hasKey("ui.credits") then
    lurek.log.warn("ui.credits not localised yet", "i18n")
  end
end

--@api-stub: lurek.i18n.getKeys
-- Returns sorted translation keys known to the catalog
do
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  local total = #lurek.i18n.getKeys()
  lurek.log.info("en key count=" .. total, "i18n")
end

--@api-stub: lurek.i18n.setKey
-- Sets one translation value for one locale and key
do
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.setKey("en", "ui.continue", "Continue")
  lurek.i18n.setLanguage("en")
  lurek.log.info(lurek.i18n.t("ui.continue"), "i18n")
end

--@api-stub: lurek.i18n.interpolate
-- Replaces `{name}` placeholders in a template using string variables
do
  local msg = lurek.i18n.interpolate(
    "Player {name} reached level {lvl}",
    { name = "Aria", lvl = "7" }
  )
  lurek.log.info(msg, "i18n")
end

--@api-stub: lurek.i18n.pluralFor
-- Returns the English plural category key for a number
do
  for _, n in ipairs({ 0, 1, 5 }) do
    local cat = lurek.i18n.pluralFor(n)
    lurek.log.info("n=" .. n .. " -> " .. cat, "i18n")
  end
end

--@api-stub: lurek.i18n.onLanguageChange
-- Registers a callback invoked when the active locale changes
do
  lurek.i18n.onLanguageChange(function(new_locale, old_locale)
    lurek.log.info("locale changed " .. tostring(old_locale) .. " -> " .. new_locale, "i18n")
  end)
  lurek.i18n.loadTable("de", { ui = { start = "Start" } })
  lurek.i18n.setLanguage("de")
end

--@api-stub: lurek.i18n.hasLanguage
-- Returns whether a locale has translations loaded
do
  lurek.i18n.loadTable("ja", { ui = { start = "é–‹ĺ§‹" } })
  if lurek.i18n.hasLanguage("ja") then
    lurek.i18n.setLanguage("ja")
  end
end

--@api-stub: lurek.i18n.getAvailableLanguages
-- Returns sorted locale codes currently loaded in the catalog
do
  local langs = lurek.i18n.getAvailableLanguages()
  lurek.log.info("options menu langs=" .. #langs, "i18n")
end

--@api-stub: lurek.i18n.setBase
-- Sets the base locale string stored by the localization module
do
  lurek.i18n.setBase("en")
end

--@api-stub: lurek.i18n.getBase
-- Returns the base locale string stored by the localization module
do
  local base = lurek.i18n.getBase()
  if base ~= "" then
    lurek.log.info("source locale=" .. base, "i18n")
  end
end

--@api-stub: lurek.i18n.onChange
-- Registers a locale-change callback using the shorter alias name
do
  lurek.i18n.onChange(function(new_locale, _old)
    lurek.log.info("UI rebuild for " .. new_locale, "i18n")
  end)
end

--@api-stub: lurek.i18n.offChange
-- Removes every registered locale-change callback
do
  lurek.i18n.onChange(function() end)
  lurek.i18n.offChange()
  lurek.log.info("locale-change handlers cleared", "i18n")
end

--@api-stub: lurek.i18n.keyCount
-- Returns the number of translation keys known to the catalog
do
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  lurek.log.info("active locale has " .. lurek.i18n.keyCount() .. " keys", "i18n")
end

--@api-stub: lurek.i18n.categories
-- Returns top-level translation key categories
do
  lurek.i18n.loadTable("en", { ui = { start = "Start" }, hud = { score = "S" } })
  lurek.i18n.setLanguage("en")
  for _, c in ipairs(lurek.i18n.categories()) do
    lurek.log.info("category " .. c, "i18n")
  end
end

--@api-stub: lurek.i18n.keysInCategory
-- Returns translation keys belonging to one category prefix
do
  lurek.i18n.loadTable("en", { ui = { start = "Start", quit = "Quit" } })
  lurek.i18n.setLanguage("en")
  local ui_keys = lurek.i18n.keysInCategory("ui")
  lurek.log.info("ui-section keys=" .. #ui_keys, "i18n")
end

--@api-stub: lurek.i18n.search
-- Searches translation keys and values for a query string
do
  lurek.i18n.loadTable("en", { ui = { start = "Start", restart = "Restart" } })
  lurek.i18n.setLanguage("en")
  local hits = lurek.i18n.search("start", 10)
  lurek.log.info("matches=" .. #hits, "i18n")
end

--@api-stub: lurek.i18n.buildIndex
-- Builds a word-to-keys search index from the catalog
do
  lurek.i18n.loadTable("en", { ui = { start = "Start game", quit = "Quit game" } })
  lurek.i18n.setLanguage("en")
  local index = lurek.i18n.buildIndex()
  lurek.log.info("indexed words=" .. tostring(next(index) ~= nil), "i18n")
end

--@api-stub: lurek.i18n.searchIndexed
-- Searches a prebuilt word index and returns matching keys
do
  lurek.i18n.loadTable("en", { ui = { start = "Start game", quit = "Quit game" } })
  lurek.i18n.setLanguage("en")
  local index = lurek.i18n.buildIndex()
  local matches = lurek.i18n.searchIndexed(index, "start game", 5)
  lurek.log.info("indexed matches=" .. #matches, "i18n")
end

--@api-stub: lurek.i18n.mergeLocale
-- Merges flat translation entries into an existing locale
do
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.mergeLocale("en", {
    ["dialog.intro"] = "Welcome, traveller.",
    ["dialog.outro"] = "Farewell.",
  })
end

--@api-stub: lurek.i18n.formatNumber
-- Formats a number with locale-aware separators and optional decimal precision
do
  lurek.i18n.setLanguage("de")
  local price = lurek.i18n.formatNumber(1234.5, { decimals = 2 })
  lurek.log.info("DE price=" .. price, "i18n")
end

--@api-stub: lurek.i18n.formatDate
-- Formats a timestamp with the active locale and a named format
do
  lurek.i18n.setLanguage("en")
  local stamp = lurek.i18n.formatDate(1700000000, "long")
  lurek.log.info("save written " .. stamp, "i18n")
end

--@api-stub: lurek.i18n.tGender
-- Translates a gender-specific key variant when present, then falls back to the base key
do
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
-- Returns locale codes currently loaded in the catalog
do
  lurek.i18n.loadTable("en", { ui = { start = "Start" } })
  lurek.i18n.loadTable("fr", { ui = { start = "Commencer" } })
  local locales = lurek.i18n.getLoadedLocales()
  lurek.log.info("loaded locale count=" .. #locales, "i18n")
end

--@api-stub: lurek.i18n.isRTL
-- Returns whether a locale is written right-to-left
do
  local rtl_arabic = lurek.i18n.isRTL("ar-SA")    -- true
  local ltr_english = lurek.i18n.isRTL("en-US")   -- false
  local active_rtl = lurek.i18n.isRTL()            -- tests current locale
  lurek.log.info(("ar-SA isRTL=%s  en-US isRTL=%s  active isRTL=%s"):format(
    tostring(rtl_arabic), tostring(ltr_english), tostring(active_rtl)), "i18n")
end

--@api-stub: lurek.i18n.validateLocale
-- Returns whether a locale code has a valid syntax
do
  local ok_code   = lurek.i18n.validateLocale("en-US")   -- true
  local bad_code  = lurek.i18n.validateLocale("1bad")     -- false
  local empty     = lurek.i18n.validateLocale("")          -- false
  lurek.log.info(("en-US=%s  1bad=%s  empty=%s"):format(
    tostring(ok_code), tostring(bad_code), tostring(empty)), "i18n")
end

--@api-stub: lurek.i18n.detectLocale
-- Detects the system locale when available
do
  local detected = lurek.i18n.detectLocale()
  if detected then
    lurek.log.info("system locale detected: " .. detected, "i18n")
  else
    lurek.log.info("no system locale detected (CI / Windows without LANG)", "i18n")
  end
end

--@api-stub: lurek.i18n.loadString
-- Loads translations for a locale from TOML or JSON source text
do
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

--@api-stub: lurek.i18n.localeCoverage
-- Returns missing translation keys for all locales compared to a reference locale
do
  lurek.i18n.loadTable("ref_en", { hello = "Hello", bye = "Goodbye", ok = "OK" })
  lurek.i18n.loadTable("ref_fr", { hello = "Bonjour", ok = "Oui" })  -- 'bye' missing
  lurek.i18n.loadTable("ref_de", { hello = "Hallo", bye = "Tschüss" }) -- 'ok' missing

  local gaps = lurek.i18n.localeCoverage("ref_en")
  for _, gap in ipairs(gaps) do
    lurek.log.warn(("missing key '%s' in: %s"):format(
      gap.key, table.concat(gap.missing_in, ", ")), "i18n")
  end
end
