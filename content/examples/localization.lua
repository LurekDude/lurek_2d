-- examples/localization.lua
-- Demonstrates lurek.localization — runtime i18n (internationalisation) engine
-- for Lurek2D.  Supports keyed string lookup, variable interpolation, plural
-- rules, language fallback chains, and change-notification callbacks.
-- Run with: cargo run -- examples/localization

-- ─────────────────────────────────────────────────────────────────────────────
-- LOADING TRANSLATIONS
-- loadTable(locale, table) interns every key→string pair for a locale.
-- Call it as many times as you need — subsequent calls merge into existing data;
-- they do NOT wipe prior keys for the same locale.
-- ─────────────────────────────────────────────────────────────────────────────

-- English (en) — base language
lurek.localization.loadTable("en", {
    -- Simple strings
    ["menu.start"]          = "Start Game",
    ["menu.quit"]           = "Quit",
    ["menu.settings"]       = "Settings",

    -- Variable interpolation — {varname} placeholders
    ["player.greeting"]     = "Welcome, {name}!",
    ["player.levelUp"]      = "{name} reached level {level}!",
    ["enemy.killed"]        = "You defeated {count} {enemy}.",

    -- Plural variants — engine splits on "|" using pluralFor()
    -- Format: "singular|plural" (for English: n==1 → first, n!=1 → second)
    ["item.found"]          = "Found {count} item.|Found {count} items.",
    ["enemy.remaining"]     = "{count} enemy remains.|{count} enemies remain.",
})

-- French (fr)
lurek.localization.loadTable("fr", {
    ["menu.start"]      = "Commencer",
    ["menu.quit"]       = "Quitter",
    ["menu.settings"]   = "Paramètres",

    ["player.greeting"] = "Bienvenue, {name} !",
    ["player.levelUp"]  = "{name} a atteint le niveau {level} !",
    ["enemy.killed"]    = "Vous avez vaincu {count} {enemy}.",

    -- French plural rule: n <= 1 → singular, else plural
    ["item.found"]      = "Trouvé {count} objet.|Trouvé {count} objets.",
    ["enemy.remaining"] = "Il reste {count} ennemi.|Il reste {count} ennemis.",
})

-- German (de) — partial translation to demonstrate fallback
lurek.localization.loadTable("de", {
    ["menu.start"]      = "Spiel starten",
    ["menu.quit"]       = "Beenden",
    -- "menu.settings" intentionally missing → will fall back to English
})

-- Japanese (ja) — minimal example
lurek.localization.loadTable("ja", {
    ["menu.start"]      = "ゲームを開始",
    ["menu.quit"]       = "終了",
    ["player.greeting"] = "{name}、ようこそ！",
})

-- ─────────────────────────────────────────────────────────────────────────────
-- LANGUAGE SELECTION
-- ─────────────────────────────────────────────────────────────────────────────

-- Set the active language — all subsequent t() calls use this locale
lurek.localization.setLanguage("en")
local active = lurek.localization.getLanguage()   -- "en"
lurek.log.info("active language: " .. active)

-- List every locale that has been loadTable'd
local langs = lurek.localization.getLanguages()   -- { "en", "fr", "de", "ja" }
lurek.log.info("available languages: " .. table.concat(langs, ", "))

-- getAvailableLanguages() is a synonym for getLanguages()
local avail = lurek.localization.getAvailableLanguages()
_ = avail

-- Check if a specific locale has ANY loaded keys
lua_has_de = lurek.localization.hasLanguage("de")   -- true
lua_has_cn = lurek.localization.hasLanguage("zh")   -- false (not loaded)

-- ─────────────────────────────────────────────────────────────────────────────
-- BASE / OVERRIDE LANGUAGE
-- setBase() marks a locale as the last-resort fallback (different from the
-- fallback chain below). Typically set to "en" at startup.
-- ─────────────────────────────────────────────────────────────────────────────

lurek.localization.setBase("en")
local base = lurek.localization.getBase()   -- "en"
_ = base

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSLATING STRINGS — lurek.localization.t()
-- t(key)             → simple lookup in active language, falls back to base
-- t(key, vars)       → lookup + variable substitution  {varname}
-- t(key, vars, n)    → lookup + plural selection + substitution
-- ─────────────────────────────────────────────────────────────────────────────

-- Simple lookup
local start_label = lurek.localization.t("menu.start")   -- "Start Game"
lurek.log.info("menu.start = " .. start_label)

-- Variable substitution — pass a table of {varname = value} pairs
-- All {placeholders} in the string are replaced; extras are ignored
local greeting = lurek.localization.t("player.greeting", { name = "Luna" })
lurek.log.info(greeting)   -- "Welcome, Luna!"

local lvl_msg = lurek.localization.t("player.levelUp", { name = "Zara", level = 10 })
lurek.log.info(lvl_msg)    -- "Zara reached level 10!"

-- Plural selection — pass a number as the third argument
-- lurek.localization uses the active locale's plural rule to pick the right variant
-- For English: n == 1 → singular (index 1), otherwise plural (index 2)
local item_singular = lurek.localization.t("item.found", { count = 1 }, 1)
local item_plural   = lurek.localization.t("item.found", { count = 5 }, 5)
lurek.log.info("items (1): " .. item_singular)   -- "Found 1 item."
lurek.log.info("items (5): " .. item_plural)     -- "Found 5 items."

local enemy_1  = lurek.localization.t("enemy.remaining", { count = 1 }, 1)
local enemy_3  = lurek.localization.t("enemy.remaining", { count = 3 }, 3)
lurek.log.info(enemy_1)    -- "1 enemy remains."
lurek.log.info(enemy_3)    -- "3 enemies remain."

-- Switch to French and translate the same keys
lurek.localization.setLanguage("fr")
local fr_start = lurek.localization.t("menu.start")               -- "Commencer"
local fr_items = lurek.localization.t("item.found", { count = 3 }, 3)  -- "Trouvé 3 objets."
lurek.log.info("fr menu.start = " .. fr_start)
lurek.log.info("fr items (3)  = " .. fr_items)

-- ─────────────────────────────────────────────────────────────────────────────
-- FALLBACK CHAINS
-- setFallbacks({ locale1, locale2, ... }) defines an ordered prioritised list.
-- When a key is missing in locale1 the engine tries locale2, then locale3, etc.
-- The base locale is always the final fallback regardless of this list.
-- ─────────────────────────────────────────────────────────────────────────────

lurek.localization.setLanguage("de")
lurek.localization.setFallbacks({ "de", "en" })   -- missing de keys → try en
local fallbacks = lurek.localization.getFallbacks()   -- { "de", "en" }
_ = fallbacks

-- "menu.settings" is missing in German → falls back to English
local de_settings = lurek.localization.t("menu.settings")   -- "Settings" (en fallback)
lurek.log.info("de settings (fallback): " .. de_settings)

-- "menu.start" exists in German → no fallback needed
local de_start = lurek.localization.t("menu.start")         -- "Spiel starten"
lurek.log.info("de start: " .. de_start)

-- Switch back to English for the rest of the example
lurek.localization.setLanguage("en")
lurek.localization.setFallbacks({ "en" })

-- ─────────────────────────────────────────────────────────────────────────────
-- MANUAL INTERPOLATION
-- interpolate(template, vars) is the substitution engine exposed standalone.
-- Useful when you have a template string that is NOT in the translation table.
-- ─────────────────────────────────────────────────────────────────────────────

local template = "Hello, {name}! You have {coins} gold coins."
local result   = lurek.localization.interpolate(template, { name = "Hero", coins = 999 })
lurek.log.info(result)   -- "Hello, Hero! You have 999 gold coins."

-- Missing variables are left as-is (or replaced by "" depending on engine config)
local partial = lurek.localization.interpolate("Hi {name}! Level {level}.", { name = "Kai" })
lurek.log.debug("partial: " .. partial)   -- "Hi Kai! Level {level}."

-- ─────────────────────────────────────────────────────────────────────────────
-- PLURAL RULE PROBE
-- pluralFor(n) returns the plural category string for a number in the ACTIVE
-- locale. English: "one" (n==1) or "other".  Use to select message variants
-- when you manage your own string splitting.
-- ─────────────────────────────────────────────────────────────────────────────

local p1 = lurek.localization.pluralFor(1)    -- "one"
local p5 = lurek.localization.pluralFor(5)    -- "other"
local p0 = lurek.localization.pluralFor(0)    -- "other"  (English: 0 is plural)
lurek.log.debug(string.format("plural: 1→%s  5→%s  0→%s", p1, p5, p0))

-- ─────────────────────────────────────────────────────────────────────────────
-- KEY MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

-- Check if a key exists in the active locale (or its fallback chain)
local exists = lurek.localization.hasKey("menu.start")    -- true
local missing_key = lurek.localization.hasKey("ui.hud.compass")  -- false
_ = missing_key

-- List every key loaded in the active locale
local all_keys = lurek.localization.getKeys()   -- { "menu.start", "menu.quit", ... }
lurek.log.info("key count (en): " .. #all_keys)

-- Add or override a single key at runtime (hot-patching for mods or tweaks)
lurek.localization.setKey("en", "menu.credits", "Credits")
lurek.localization.setKey("fr", "menu.credits", "Crédits")

lurek.log.info(lurek.localization.t("menu.credits"))   -- "Credits"
lurek.localization.setLanguage("fr")
lurek.log.info(lurek.localization.t("menu.credits"))   -- "Crédits"
lurek.localization.setLanguage("en")

-- ─────────────────────────────────────────────────────────────────────────────
-- CHANGE NOTIFICATION
-- Register callbacks invoked whenever setLanguage() is called.
-- Use to refresh rendered UI, reload locale-specific assets, etc.
-- ─────────────────────────────────────────────────────────────────────────────

local function onLocaleChanged(new_locale, old_locale)
    lurek.log.info(string.format("[i18n] language changed: %s → %s",
        tostring(old_locale), new_locale))
    -- Reload locale-specific assets here, e.g. font files, audio clips
end

-- onLanguageChange and onChange are synonyms
lurek.localization.onLanguageChange(onLocaleChanged)

-- Test the callback
lurek.localization.setLanguage("ja")   -- fires onLocaleChanged("ja", "en")
lurek.localization.setLanguage("en")   -- fires onLocaleChanged("en", "ja")

-- Unregister the change listener (only one listener at a time is supported)
lurek.localization.offChange()

-- ─────────────────────────────────────────────────────────────────────────────
-- UNLOADING A LOCALE
-- Free all strings for a specific locale (useful when switching to a new
-- language in a memory-constrained environment).
-- ─────────────────────────────────────────────────────────────────────────────

lurek.localization.unloadTable("ja")
local no_ja = not lurek.localization.hasLanguage("ja")  -- true (well, depends on impl)
lurek.log.debug("Japanese unloaded: " .. tostring(no_ja))

-- ─────────────────────────────────────────────────────────────────────────────
-- PRACTICAL PATTERNS
-- ─────────────────────────────────────────────────────────────────────────────

-- Pattern A: helper alias — shorter call site
local T = lurek.localization.t
lurek.log.info(T("menu.start"))
lurek.log.info(T("player.greeting", { name = "Player1" }))

-- Pattern B: detect OS language and set as active
local sys_lang = lurek.window.getSystemLocale()   -- e.g. "fr-FR"
local code = sys_lang:sub(1, 2):lower()          -- "fr"
-- if lurek.localization.hasLanguage(code) then
lurek.localization.setLanguage(code)
-- end

-- Pattern C: load translations from GameFS JSON files
local json_bytes = lurek.fs.readFile("locale/en.json")
local tbl = lurek.data.fromJSON(json_bytes)    -- parse JSON → Lua table
lurek.localization.loadTable("en", tbl)

-- Pattern D: rich UI label builder using interpolation
local function uiLabel(key, vars, count)
    local raw = lurek.localization.t(key, vars, count)
    return raw ~= "" and raw or ("[" .. key .. "]")   -- graceful fallback display
end

local lbl = uiLabel("item.found", { count = 7 }, 7)
lurek.log.info("UI label: " .. lbl)   -- "Found 7 items."

lurek.log.info("[localization.lua] example complete")


-- ─── lurek.localization ─────────────────────────────────────────────────────────
lurek.localization.onChange(function() end)  -- Registers a callback invoked when setLanguage() is called (alias: onChange)


-- ─────────────────────────────────────────────────────────────────────────────
-- Advanced Locale Inspection & Search
-- ─────────────────────────────────────────────────────────────────────────────

-- Total number of translation keys loaded for the active locale
local key_count = lurek.localization.keyCount()   -- e.g. 42

-- First-segment category prefixes (e.g. "menu", "hud", "item" from "menu.play" etc.)
local cats = lurek.localization.categories()   -- { "menu", "hud", "item", ... }

-- All keys in a specific category (first path segment = category)
local menu_keys = lurek.localization.keysInCategory("menu")   -- { "menu.play", "menu.credits", ... }

-- Add or overwrite individual keys in an existing locale without replacing the whole table
lurek.localization.mergeLocale("en", { ["item.sword"] = "Iron Sword", ["item.potion"] = "Healing Potion" })
lurek.log.info(lurek.localization.t("item.sword"))   -- "Iron Sword"

-- Build an inverted word index for fast full-text search across all locale values
local index = lurek.localization.buildIndex()   -- {word -> {key1, key2, ...}}

-- Free-text search across active locale values (case-insensitive substring)
local results = lurek.localization.search("sword", 5)   -- up to 5 matches: { {key, value}, ... }
for _, r in ipairs(results) do
    lurek.log.info(string.format("[search] %s = %s", r.key or r[1], r.value or r[2]))
end

-- Search using the pre-built index (faster for repeated queries)
local indexed_results = lurek.localization.searchIndexed(index, "healing potion", 10)
for _, r in ipairs(indexed_results) do
    lurek.log.info(string.format("[indexed] %s = %s", r.key or r[1], r.value or r[2]))
end

lurek.log.info("[localization.lua] advanced search example complete")
