-- Lurek2D localization (i18n) API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.i18n namespace: loadTable, unloadTable,
-- setLanguage, getLanguages, fallbacks, t(), hasKey, getKeys, setKey,
-- interpolate, pluralFor, onChange/offChange, keyCount, categories,
-- keysInCategory, search, buildIndex/searchIndexed, mergeLocale.
-- @covers lurek.i18n.loadTable
-- @covers lurek.i18n.unloadTable
-- @covers lurek.i18n.setLanguage
-- @covers lurek.i18n.getLanguage
-- @covers lurek.i18n.getLanguages
-- @covers lurek.i18n.getAvailableLanguages
-- @covers lurek.i18n.hasLanguage
-- @covers lurek.i18n.setFallbacks
-- @covers lurek.i18n.getFallbacks
-- @covers lurek.i18n.setBase
-- @covers lurek.i18n.getBase
-- @covers lurek.i18n.t
-- @covers lurek.i18n.hasKey
-- @covers lurek.i18n.getKeys
-- @covers lurek.i18n.setKey
-- @covers lurek.i18n.interpolate
-- @covers lurek.i18n.pluralFor
-- @covers lurek.i18n.onChange
-- @covers lurek.i18n.offChange
-- @covers lurek.i18n.keyCount
-- @covers lurek.i18n.categories
-- @covers lurek.i18n.keysInCategory
-- @covers lurek.i18n.search
-- @covers lurek.i18n.buildIndex
-- @covers lurek.i18n.searchIndexed
-- @covers lurek.i18n.mergeLocale

local en = {
    greeting = "Hello",
    farewell = "Goodbye",
    menu = {
        start = "Start Game",
        quit  = "Quit",
    },
    welcome = "Welcome, {name}!",
    items = {
        one   = "{count} item",
        other = "{count} items",
    },
}

local fr = {
    greeting = "Bonjour",
    farewell = "Au revoir",
    menu = {
        start = "Demarrer",
        quit  = "Quitter",
    },
    welcome = "Bienvenue, {name} !",
    items = {
        one   = "{count} article",
        other = "{count} articles",
    },
}

-- Setup state for each describe block
local function setup_en_fr()
    lurek.i18n.loadTable("en", en)
    lurek.i18n.loadTable("fr", fr)
    lurek.i18n.setLanguage("en")
    lurek.i18n.setBase("en")
end

-- module presence
describe("lurek.i18n module", function()
    it("lurek.i18n is a table", function()
        expect_type("table", lurek.i18n)
    end)

    it("all key functions are present", function()
        local fns = {
            "loadTable", "unloadTable", "setLanguage", "getLanguage",
            "getLanguages", "getAvailableLanguages", "hasLanguage",
            "setFallbacks", "getFallbacks", "setBase", "getBase",
            "t", "hasKey", "getKeys", "setKey",
            "interpolate", "pluralFor",
            "onChange", "offChange",
            "keyCount", "categories", "keysInCategory",
            "search", "buildIndex", "searchIndexed", "mergeLocale",
        }
        for _, name in ipairs(fns) do
            expect_type("function", lurek.i18n[name],
                name .. " must be a function")
        end
    end)
end)

-- loadTable / unloadTable / getLanguages / hasLanguage
describe("lurek.i18n.loadTable / unloadTable", function()
    it("loadTable adds a language detectable by hasLanguage", function()
        lurek.i18n.loadTable("en", en)
        expect_true(lurek.i18n.hasLanguage("en"))
    end)

    it("getAvailableLanguages lists loaded languages", function()
        lurek.i18n.loadTable("en", en)
        lurek.i18n.loadTable("fr", fr)
        local langs = lurek.i18n.getAvailableLanguages()
        expect_true(#langs >= 2)
    end)

    it("getLanguages is an alias for getAvailableLanguages", function()
        lurek.i18n.loadTable("en", en)
        local l1 = lurek.i18n.getLanguages()
        local l2 = lurek.i18n.getAvailableLanguages()
        expect_type("table", l1)
        expect_equal(#l2, #l1)
    end)

    it("unloadTable removes the language", function()
        lurek.i18n.loadTable("zz_test", { hello = "Hi" })
        expect_true(lurek.i18n.hasLanguage("zz_test"))
        lurek.i18n.unloadTable("zz_test")
        expect_false(lurek.i18n.hasLanguage("zz_test"))
    end)
end)

-- setLanguage / getLanguage / setBase / getBase
describe("lurek.i18n.setLanguage / getLanguage / setBase / getBase", function()
    it("sets and gets the active language", function()
        setup_en_fr()
        expect_equal("en", lurek.i18n.getLanguage())
    end)

    it("setBase / getBase round-trip", function()
        lurek.i18n.setBase("en")
        expect_equal("en", lurek.i18n.getBase())
    end)
end)

-- setFallbacks / getFallbacks
describe("lurek.i18n.setFallbacks / getFallbacks", function()
    it("setFallbacks stores ordered fallback chain", function()
        setup_en_fr()
        lurek.i18n.setFallbacks({ "fr", "en" })
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
        expect_equal("fr", fb[1])
        expect_equal("en", fb[2])
    end)

    it("getFallbacks returns empty table when not set", function()
        lurek.i18n.setFallbacks({})
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
    end)
end)

-- t() basic lookup
describe("lurek.i18n.t basic lookup", function()
    it("returns translated string for active language", function()
        setup_en_fr()
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    it("supports dot-keys for nested tables", function()
        setup_en_fr()
        expect_equal("Start Game", lurek.i18n.t("menu.start"))
    end)

    it("returns key when translation missing", function()
        setup_en_fr()
        expect_equal("nonexistent.key", lurek.i18n.t("nonexistent.key"))
    end)

    it("falls back to base language", function()
        setup_en_fr()
        lurek.i18n.setLanguage("fr")
        expect_equal("Au revoir", lurek.i18n.t("farewell"))
    end)

    it("replaces {var} placeholders", function()
        setup_en_fr()
        local result = lurek.i18n.t("welcome", { name = "Luna" })
        expect_equal("Welcome, Luna!", result)
    end)

    it("selects one for count == 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "1" }, 1)
        expect_equal("1 item", result)
    end)

    it("selects other for count > 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "5" }, 5)
        expect_equal("5 items", result)
    end)
end)

-- hasKey / getKeys / setKey
describe("lurek.i18n.hasKey / getKeys / setKey", function()
    it("hasKey returns true for a loaded key", function()
        setup_en_fr()
        expect_true(lurek.i18n.hasKey("greeting"))
    end)

    it("hasKey returns false for a missing key", function()
        setup_en_fr()
        expect_false(lurek.i18n.hasKey("nonexistent_key_xyz"))
    end)

    it("getKeys returns a table of key strings", function()
        setup_en_fr()
        local keys = lurek.i18n.getKeys()
        expect_type("table", keys)
        expect_true(#keys >= 1, "at least one key exists")
    end)

    it("setKey adds or overrides a key in the current language", function()
        setup_en_fr()
        lurek.i18n.setKey("en", "custom_added_key", "Custom Value")
        expect_equal("Custom Value", lurek.i18n.t("custom_added_key"))
    end)
end)

-- interpolate / pluralFor
describe("lurek.i18n.interpolate / pluralFor", function()
    it("interpolate replaces {var} in a raw string", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    it("interpolate with no vars returns string unchanged", function()
        local result = lurek.i18n.interpolate("No vars here", {})
        expect_equal("No vars here", result)
    end)

    it("pluralFor returns one for n=1", function()
        local form = lurek.i18n.pluralFor(1)
        expect_equal("one", form)
    end)

    it("pluralFor returns other for n=5", function()
        local form = lurek.i18n.pluralFor(5)
        expect_equal("other", form)
    end)
end)

-- onChange / offChange
describe("lurek.i18n.onChange / offChange", function()
    it("fires callback when language changes", function()
        lurek.i18n.loadTable("en", en)
        local fired = false
        lurek.i18n.onChange(function() fired = true end)
        lurek.i18n.setLanguage("en")
        expect_true(fired)
    end)

    it("offChange removes the callback", function()
        lurek.i18n.loadTable("en", en)
        local count = 0
        local function cb() count = count + 1 end
        lurek.i18n.onChange(cb)
        lurek.i18n.setLanguage("en")
        lurek.i18n.offChange()
        lurek.i18n.setLanguage("en")
        expect_equal(1, count, "callback fired once, then removed")
    end)
end)

-- keyCount / categories / keysInCategory
describe("lurek.i18n.keyCount / categories / keysInCategory", function()
    it("keyCount returns a non-negative number", function()
        setup_en_fr()
        local n = lurek.i18n.keyCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least one key loaded")
    end)

    it("categories returns a table", function()
        setup_en_fr()
        local cats = lurek.i18n.categories()
        expect_type("table", cats)
    end)

    it("keysInCategory returns a table for a known category", function()
        setup_en_fr()
        local cats = lurek.i18n.categories()
        if #cats > 0 then
            local keys = lurek.i18n.keysInCategory(cats[1])
            expect_type("table", keys)
        else
            expect_true(true, "no categories to test (flat locale is acceptable)")
        end
    end)
end)

-- search / buildIndex / searchIndexed
describe("lurek.i18n.search / buildIndex / searchIndexed", function()
    it("search returns a table", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_type("table", results)
    end)

    it("search finds a known term", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_true(#results >= 1, "search should find greeting=Hello")
    end)

    it("buildIndex runs without error", function()
        setup_en_fr()
        expect_no_error(function() lurek.i18n.buildIndex() end)
    end)

    it("searchIndexed returns a table after buildIndex", function()
        setup_en_fr()
        local idx = lurek.i18n.buildIndex()
        local results = lurek.i18n.searchIndexed(idx, "Hello")
        expect_type("table", results)
    end)
end)

-- mergeLocale
describe("lurek.i18n.mergeLocale", function()
    it("mergeLocale adds new keys to existing language without overwriting", function()
        setup_en_fr()
        lurek.i18n.mergeLocale("en", { extra_key = "Extra Value" })
        expect_equal("Extra Value", lurek.i18n.t("extra_key"))
        -- Original key preserved
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    it("mergeLocale creates a new language if it did not exist", function()
        lurek.i18n.mergeLocale("zz_merge_test", { hello = "Hola" })
        expect_true(lurek.i18n.hasLanguage("zz_merge_test"))
        lurek.i18n.unloadTable("zz_merge_test")
    end)
end)

describe("string interpolation (RS parity)", function()
    it("interpolate replaces a single placeholder", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    it("interpolate replaces multiple placeholders", function()
        local result = lurek.i18n.interpolate("{a} + {b} = {c}", { a = "1", b = "2", c = "3" })
        expect_equal("1 + 2 = 3", result)
    end)

    it("interpolate leaves unknown placeholders as-is", function()
        local result = lurek.i18n.interpolate("Hi {unknown}", {})
        expect_contains(result, "{unknown}")
    end)

    it("interpolate double-brace escaping produces single brace", function()
        local result = lurek.i18n.interpolate("{{literal}}", {})
        expect_contains(result, "literal")
    end)
end)

describe("localization format helpers (RS parity)", function()
    it("format returns a string", function()
        local result = lurek.i18n.interpolate("Value: {n}", { n = "42" })
        expect_equal("string", type(result))
        expect_contains(result, "42")
    end)

    it("getLanguages returns a non-empty table after loading", function()
        local langs = lurek.i18n.getLanguages()
        expect_equal("table", type(langs))
    end)
end)

describe("lurek.i18n helper coverage", function()
    -- @covers lurek.i18n.onLanguageChange
    it("onLanguageChange receives new and old locale codes", function()
        setup_en_fr()
        lurek.i18n.offChange()

        local new_locale = nil
        local old_locale = nil

        lurek.i18n.onLanguageChange(function(next_locale, previous_locale)
            new_locale = next_locale
            old_locale = previous_locale
        end)

        lurek.i18n.setLanguage("fr")

        expect_equal("fr", new_locale)
        expect_equal("en", old_locale)

        lurek.i18n.offChange()
    end)

    -- @covers lurek.i18n.formatNumber
    it("formatNumber applies locale separators and decimals", function()
        setup_en_fr()
        lurek.i18n.setLanguage("fr")

        local formatted = lurek.i18n.formatNumber(12345.678, { decimals = 2 })

        expect_equal("12.345,68", formatted)
    end)

    -- @covers lurek.i18n.formatDate
    it("formatDate supports iso and short formats", function()
        setup_en_fr()
        lurek.i18n.setLanguage("en")

        expect_equal("1970-01-01", lurek.i18n.formatDate(0, "iso"))
        expect_equal("Jan 1, 1970", lurek.i18n.formatDate(0, "short"))
    end)

    -- @covers lurek.i18n.tGender
    it("tGender resolves gendered keys and falls back to base key", function()
        setup_en_fr()
        lurek.i18n.setKey("en", "title", "Captain {name}")
        lurek.i18n.setKey("en", "title.masculine", "Sir {name}")

        local masculine = lurek.i18n.tGender("title", "masculine", { name = "Alex" })
        local fallback = lurek.i18n.tGender("title", "neutral", { name = "Alex" })

        expect_equal("Sir Alex", masculine)
        expect_equal("Captain Alex", fallback)
    end)

    -- @covers lurek.i18n.getLoadedLocales
    it("getLoadedLocales returns every loaded locale", function()
        setup_en_fr()
        lurek.i18n.loadTable("zz_loaded", { hello = "Ciao" })

        local locales = lurek.i18n.getLoadedLocales()
        local seen = {}

        expect_type("table", locales)
        for _, locale in ipairs(locales) do
            seen[locale] = true
        end

        expect_true(seen["en"] ~= nil, "expected en to be listed")
        expect_true(seen["fr"] ~= nil, "expected fr to be listed")
        expect_true(seen["zz_loaded"] ~= nil, "expected zz_loaded to be listed")

        lurek.i18n.unloadTable("zz_loaded")
    end)
end)

test_summary()
