-- examples/localization.lua
-- Demonstrates luna.localization — runtime i18n (internationalisation) engine
-- for Luna2D.  Supports keyed string lookup, variable interpolation, plural
-- rules, language fallback chains, and change-notification callbacks.
-- Run with: cargo run -- examples/localization

-- ─────────────────────────────────────────────────────────────────────────────
-- LOADING TRANSLATIONS
-- loadTable(locale, table) interns every key→string pair for a locale.
-- Call it as many times as you need — subsequent calls merge into existing data;
-- they do NOT wipe prior keys for the same locale.
-- ─────────────────────────────────────────────────────────────────────────────

-- English (en) — base language
luna.localization.loadTable("en", {
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
luna.localization.loadTable("fr", {
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
luna.localization.loadTable("de", {
    ["menu.start"]      = "Spiel starten",
    ["menu.quit"]       = "Beenden",
    -- "menu.settings" intentionally missing → will fall back to English
})

-- Japanese (ja) — minimal example
luna.localization.loadTable("ja", {
    ["menu.start"]      = "ゲームを開始",
    ["menu.quit"]       = "終了",
    ["player.greeting"] = "{name}、ようこそ！",
})

-- ─────────────────────────────────────────────────────────────────────────────
-- LANGUAGE SELECTION
-- ─────────────────────────────────────────────────────────────────────────────

-- Set the active language — all subsequent t() calls use this locale
luna.localization.setLanguage("en")
local active = luna.localization.getLanguage()   -- "en"
luna.log.info("active language: " .. active)

-- List every locale that has been loadTable'd
local langs = luna.localization.getLanguages()   -- { "en", "fr", "de", "ja" }
luna.log.info("available languages: " .. table.concat(langs, ", "))

-- getAvailableLanguages() is a synonym for getLanguages()
local avail = luna.localization.getAvailableLanguages()
_ = avail

-- Check if a specific locale has ANY loaded keys
lua_has_de = luna.localization.hasLanguage("de")   -- true
lua_has_cn = luna.localization.hasLanguage("zh")   -- false (not loaded)

-- ─────────────────────────────────────────────────────────────────────────────
-- BASE / OVERRIDE LANGUAGE
-- setBase() marks a locale as the last-resort fallback (different from the
-- fallback chain below). Typically set to "en" at startup.
-- ─────────────────────────────────────────────────────────────────────────────

luna.localization.setBase("en")
local base = luna.localization.getBase()   -- "en"
_ = base

-- ─────────────────────────────────────────────────────────────────────────────
-- TRANSLATING STRINGS — luna.localization.t()
-- t(key)             → simple lookup in active language, falls back to base
-- t(key, vars)       → lookup + variable substitution  {varname}
-- t(key, vars, n)    → lookup + plural selection + substitution
-- ─────────────────────────────────────────────────────────────────────────────

-- Simple lookup
local start_label = luna.localization.t("menu.start")   -- "Start Game"
luna.log.info("menu.start = " .. start_label)

-- Variable substitution — pass a table of {varname = value} pairs
-- All {placeholders} in the string are replaced; extras are ignored
local greeting = luna.localization.t("player.greeting", { name = "Luna" })
luna.log.info(greeting)   -- "Welcome, Luna!"

local lvl_msg = luna.localization.t("player.levelUp", { name = "Zara", level = 10 })
luna.log.info(lvl_msg)    -- "Zara reached level 10!"

-- Plural selection — pass a number as the third argument
-- luna.localization uses the active locale's plural rule to pick the right variant
-- For English: n == 1 → singular (index 1), otherwise plural (index 2)
local item_singular = luna.localization.t("item.found", { count = 1 }, 1)
local item_plural   = luna.localization.t("item.found", { count = 5 }, 5)
luna.log.info("items (1): " .. item_singular)   -- "Found 1 item."
luna.log.info("items (5): " .. item_plural)     -- "Found 5 items."

local enemy_1  = luna.localization.t("enemy.remaining", { count = 1 }, 1)
local enemy_3  = luna.localization.t("enemy.remaining", { count = 3 }, 3)
luna.log.info(enemy_1)    -- "1 enemy remains."
luna.log.info(enemy_3)    -- "3 enemies remain."

-- Switch to French and translate the same keys
luna.localization.setLanguage("fr")
local fr_start = luna.localization.t("menu.start")               -- "Commencer"
local fr_items = luna.localization.t("item.found", { count = 3 }, 3)  -- "Trouvé 3 objets."
luna.log.info("fr menu.start = " .. fr_start)
luna.log.info("fr items (3)  = " .. fr_items)

-- ─────────────────────────────────────────────────────────────────────────────
-- FALLBACK CHAINS
-- setFallbacks({ locale1, locale2, ... }) defines an ordered prioritised list.
-- When a key is missing in locale1 the engine tries locale2, then locale3, etc.
-- The base locale is always the final fallback regardless of this list.
-- ─────────────────────────────────────────────────────────────────────────────

luna.localization.setLanguage("de")
luna.localization.setFallbacks({ "de", "en" })   -- missing de keys → try en
local fallbacks = luna.localization.getFallbacks()   -- { "de", "en" }
_ = fallbacks

-- "menu.settings" is missing in German → falls back to English
local de_settings = luna.localization.t("menu.settings")   -- "Settings" (en fallback)
luna.log.info("de settings (fallback): " .. de_settings)

-- "menu.start" exists in German → no fallback needed
local de_start = luna.localization.t("menu.start")         -- "Spiel starten"
luna.log.info("de start: " .. de_start)

-- Switch back to English for the rest of the example
luna.localization.setLanguage("en")
luna.localization.setFallbacks({ "en" })

-- ─────────────────────────────────────────────────────────────────────────────
-- MANUAL INTERPOLATION
-- interpolate(template, vars) is the substitution engine exposed standalone.
-- Useful when you have a template string that is NOT in the translation table.
-- ─────────────────────────────────────────────────────────────────────────────

local template = "Hello, {name}! You have {coins} gold coins."
local result   = luna.localization.interpolate(template, { name = "Hero", coins = 999 })
luna.log.info(result)   -- "Hello, Hero! You have 999 gold coins."

-- Missing variables are left as-is (or replaced by "" depending on engine config)
local partial = luna.localization.interpolate("Hi {name}! Level {level}.", { name = "Kai" })
luna.log.debug("partial: " .. partial)   -- "Hi Kai! Level {level}."

-- ─────────────────────────────────────────────────────────────────────────────
-- PLURAL RULE PROBE
-- pluralFor(n) returns the plural category string for a number in the ACTIVE
-- locale. English: "one" (n==1) or "other".  Use to select message variants
-- when you manage your own string splitting.
-- ─────────────────────────────────────────────────────────────────────────────

local p1 = luna.localization.pluralFor(1)    -- "one"
local p5 = luna.localization.pluralFor(5)    -- "other"
local p0 = luna.localization.pluralFor(0)    -- "other"  (English: 0 is plural)
luna.log.debug(string.format("plural: 1→%s  5→%s  0→%s", p1, p5, p0))

-- ─────────────────────────────────────────────────────────────────────────────
-- KEY MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

-- Check if a key exists in the active locale (or its fallback chain)
local exists = luna.localization.hasKey("menu.start")    -- true
local missing_key = luna.localization.hasKey("ui.hud.compass")  -- false
_ = missing_key

-- List every key loaded in the active locale
local all_keys = luna.localization.getKeys()   -- { "menu.start", "menu.quit", ... }
luna.log.info("key count (en): " .. #all_keys)

-- Add or override a single key at runtime (hot-patching for mods or tweaks)
luna.localization.setKey("en", "menu.credits", "Credits")
luna.localization.setKey("fr", "menu.credits", "Crédits")

luna.log.info(luna.localization.t("menu.credits"))   -- "Credits"
luna.localization.setLanguage("fr")
luna.log.info(luna.localization.t("menu.credits"))   -- "Crédits"
luna.localization.setLanguage("en")

-- ─────────────────────────────────────────────────────────────────────────────
-- CHANGE NOTIFICATION
-- Register callbacks invoked whenever setLanguage() is called.
-- Use to refresh rendered UI, reload locale-specific assets, etc.
-- ─────────────────────────────────────────────────────────────────────────────

local function onLocaleChanged(new_locale, old_locale)
    luna.log.info(string.format("[i18n] language changed: %s → %s",
        tostring(old_locale), new_locale))
    -- Reload locale-specific assets here, e.g. font files, audio clips
end

-- onLanguageChange and onChange are synonyms
luna.localization.onLanguageChange(onLocaleChanged)

-- Test the callback
luna.localization.setLanguage("ja")   -- fires onLocaleChanged("ja", "en")
luna.localization.setLanguage("en")   -- fires onLocaleChanged("en", "ja")

-- Unregister the change listener (only one listener at a time is supported)
luna.localization.offChange()

-- ─────────────────────────────────────────────────────────────────────────────
-- UNLOADING A LOCALE
-- Free all strings for a specific locale (useful when switching to a new
-- language in a memory-constrained environment).
-- ─────────────────────────────────────────────────────────────────────────────

luna.localization.unloadTable("ja")
local no_ja = not luna.localization.hasLanguage("ja")  -- true (well, depends on impl)
luna.log.debug("Japanese unloaded: " .. tostring(no_ja))

-- ─────────────────────────────────────────────────────────────────────────────
-- PRACTICAL PATTERNS
-- ─────────────────────────────────────────────────────────────────────────────

-- Pattern A: helper alias — shorter call site
local T = luna.localization.t
luna.log.info(T("menu.start"))
luna.log.info(T("player.greeting", { name = "Player1" }))

-- Pattern B: detect OS language and set as active
-- local sys_lang = luna.window.getSystemLocale()   -- e.g. "fr-FR"
-- local code = sys_lang:sub(1, 2):lower()          -- "fr"
-- if luna.localization.hasLanguage(code) then
--     luna.localization.setLanguage(code)
-- end

-- Pattern C: load translations from GameFS JSON files
-- local json_bytes = luna.fs.readFile("locale/en.json")
-- local tbl = luna.data.fromJSON(json_bytes)    -- parse JSON → Lua table
-- luna.localization.loadTable("en", tbl)

-- Pattern D: rich UI label builder using interpolation
local function uiLabel(key, vars, count)
    local raw = luna.localization.t(key, vars, count)
    return raw ~= "" and raw or ("[" .. key .. "]")   -- graceful fallback display
end

local lbl = uiLabel("item.found", { count = 7 }, 7)
luna.log.info("UI label: " .. lbl)   -- "Found 7 items."

luna.log.info("[localization.lua] example complete")


-- ─── luna.localization ─────────────────────────────────────────────────────────
luna.localization.onChange(function() end)  -- Registers a callback invoked when setLanguage() is called (alias: onChange)


-- ─────────────────────────────────────────────────────────────────────────────
-- Advanced Locale Inspection & Search
-- ─────────────────────────────────────────────────────────────────────────────

-- Total number of translation keys loaded for the active locale
local key_count = luna.localization.keyCount()   -- e.g. 42

-- First-segment category prefixes (e.g. "menu", "hud", "item" from "menu.play" etc.)
local cats = luna.localization.categories()   -- { "menu", "hud", "item", ... }

-- All keys in a specific category (first path segment = category)
local menu_keys = luna.localization.keysInCategory("menu")   -- { "menu.play", "menu.credits", ... }

-- Add or overwrite individual keys in an existing locale without replacing the whole table
luna.localization.mergeLocale("en", { ["item.sword"] = "Iron Sword", ["item.potion"] = "Healing Potion" })
luna.log.info(luna.localization.t("item.sword"))   -- "Iron Sword"

-- Build an inverted word index for fast full-text search across all locale values
local index = luna.localization.buildIndex()   -- {word -> {key1, key2, ...}}

-- Free-text search across active locale values (case-insensitive substring)
local results = luna.localization.search("sword", 5)   -- up to 5 matches: { {key, value}, ... }
for _, r in ipairs(results) do
    luna.log.info(string.format("[search] %s = %s", r.key or r[1], r.value or r[2]))
end

-- Search using the pre-built index (faster for repeated queries)
local indexed_results = luna.localization.searchIndexed(index, "healing potion", 10)
for _, r in ipairs(indexed_results) do
    luna.log.info(string.format("[indexed] %s = %s", r.key or r[1], r.value or r[2]))
end

luna.log.info("[localization.lua] advanced search example complete")
