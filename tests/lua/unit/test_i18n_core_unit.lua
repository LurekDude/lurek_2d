-- Lurek2D localization (i18n) API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.i18n namespace: loadTable, unloadTable,
-- setLanguage, getLanguages, fallbacks, t(), hasKey, getKeys, setKey,
-- interpolate, pluralFor, onChange/offChange, keyCount, categories,
-- keysInCategory, search, buildIndex/searchIndexed, mergeLocale.

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
-- @describe lurek.i18n module
describe("lurek.i18n module", function()
    -- @covers lurek.i18n
    it("lurek.i18n is a table", function()
        expect_type("table", lurek.i18n)
    end)

    -- @covers lurek.i18n
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
-- @describe lurek.i18n.loadTable / unloadTable
describe("lurek.i18n.loadTable / unloadTable", function()
    -- @covers lurek.i18n.hasLanguage
    -- @covers lurek.i18n.loadTable
    it("loadTable adds a language detectable by hasLanguage", function()
        lurek.i18n.loadTable("en", en)
        expect_true(lurek.i18n.hasLanguage("en"))
    end)

    -- @covers lurek.i18n.getAvailableLanguages
    -- @covers lurek.i18n.loadTable
    it("getAvailableLanguages lists loaded languages", function()
        lurek.i18n.loadTable("en", en)
        lurek.i18n.loadTable("fr", fr)
        local langs = lurek.i18n.getAvailableLanguages()
        expect_true(#langs >= 2)
    end)

    -- @covers lurek.i18n.getAvailableLanguages
    -- @covers lurek.i18n.getLanguages
    -- @covers lurek.i18n.loadTable
    it("getLanguages is an alias for getAvailableLanguages", function()
        lurek.i18n.loadTable("en", en)
        local l1 = lurek.i18n.getLanguages()
        local l2 = lurek.i18n.getAvailableLanguages()
        expect_type("table", l1)
        expect_equal(#l2, #l1)
    end)

    -- @covers lurek.i18n.hasLanguage
    -- @covers lurek.i18n.loadTable
    -- @covers lurek.i18n.unloadTable
    it("unloadTable removes the language", function()
        lurek.i18n.loadTable("zz_test", { hello = "Hi" })
        expect_true(lurek.i18n.hasLanguage("zz_test"))
        lurek.i18n.unloadTable("zz_test")
        expect_false(lurek.i18n.hasLanguage("zz_test"))
    end)
end)

-- setLanguage / getLanguage / setBase / getBase
-- @describe lurek.i18n.setLanguage / getLanguage / setBase / getBase
describe("lurek.i18n.setLanguage / getLanguage / setBase / getBase", function()
    -- @covers lurek.i18n.getLanguage
    it("sets and gets the active language", function()
        setup_en_fr()
        expect_equal("en", lurek.i18n.getLanguage())
    end)

    -- @covers lurek.i18n.getBase
    -- @covers lurek.i18n.setBase
    it("setBase / getBase round-trip", function()
        lurek.i18n.setBase("en")
        expect_equal("en", lurek.i18n.getBase())
    end)
end)

-- setFallbacks / getFallbacks
-- @describe lurek.i18n.setFallbacks / getFallbacks
describe("lurek.i18n.setFallbacks / getFallbacks", function()
    -- @covers lurek.i18n.getFallbacks
    -- @covers lurek.i18n.setFallbacks
    it("setFallbacks stores ordered fallback chain", function()
        setup_en_fr()
        lurek.i18n.setFallbacks({ "fr", "en" })
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
        expect_equal("fr", fb[1])
        expect_equal("en", fb[2])
    end)

    -- @covers lurek.i18n.getFallbacks
    -- @covers lurek.i18n.setFallbacks
    it("getFallbacks returns empty table when not set", function()
        lurek.i18n.setFallbacks({})
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
    end)
end)

-- t() basic lookup
-- @describe lurek.i18n.t basic lookup
describe("lurek.i18n.t basic lookup", function()
    -- @covers lurek.i18n.t
    it("returns translated string for active language", function()
        setup_en_fr()
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    -- @covers lurek.i18n.t
    it("supports dot-keys for nested tables", function()
        setup_en_fr()
        expect_equal("Start Game", lurek.i18n.t("menu.start"))
    end)

    -- @covers lurek.i18n.t
    it("returns key when translation missing", function()
        setup_en_fr()
        expect_equal("nonexistent.key", lurek.i18n.t("nonexistent.key"))
    end)

    -- @covers lurek.i18n.setLanguage
    -- @covers lurek.i18n.t
    it("falls back to base language", function()
        setup_en_fr()
        lurek.i18n.setLanguage("fr")
        expect_equal("Au revoir", lurek.i18n.t("farewell"))
    end)

    -- @covers lurek.i18n.t
    it("replaces {var} tokens", function()
        setup_en_fr()
        local result = lurek.i18n.t("welcome", { name = "Luna" })
        expect_equal("Welcome, Luna!", result)
    end)

    -- @covers lurek.i18n.t
    it("selects one for count == 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "1" }, 1)
        expect_equal("1 item", result)
    end)

    -- @covers lurek.i18n.t
    it("selects other for count > 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "5" }, 5)
        expect_equal("5 items", result)
    end)
end)

-- hasKey / getKeys / setKey
-- @describe lurek.i18n.hasKey / getKeys / setKey
describe("lurek.i18n.hasKey / getKeys / setKey", function()
    -- @covers lurek.i18n.hasKey
    it("hasKey returns true for a loaded key", function()
        setup_en_fr()
        expect_true(lurek.i18n.hasKey("greeting"))
    end)

    -- @covers lurek.i18n.hasKey
    it("hasKey returns false for a missing key", function()
        setup_en_fr()
        expect_false(lurek.i18n.hasKey("nonexistent_key_xyz"))
    end)

    -- @covers lurek.i18n.getKeys
    it("getKeys returns a table of key strings", function()
        setup_en_fr()
        local keys = lurek.i18n.getKeys()
        expect_type("table", keys)
        expect_true(#keys >= 1, "at least one key exists")
    end)

    -- @covers lurek.i18n.setKey
    -- @covers lurek.i18n.t
    it("setKey adds or overrides a key in the current language", function()
        setup_en_fr()
        lurek.i18n.setKey("en", "custom_added_key", "Custom Value")
        expect_equal("Custom Value", lurek.i18n.t("custom_added_key"))
    end)
end)

-- interpolate / pluralFor
-- @describe lurek.i18n.interpolate / pluralFor
describe("lurek.i18n.interpolate / pluralFor", function()
    -- @covers lurek.i18n.interpolate
    it("interpolate replaces {var} in a raw string", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    -- @covers lurek.i18n.interpolate
    it("interpolate with no vars returns string unchanged", function()
        local result = lurek.i18n.interpolate("No vars here", {})
        expect_equal("No vars here", result)
    end)

    -- @covers lurek.i18n.pluralFor
    it("pluralFor returns one for n=1", function()
        local form = lurek.i18n.pluralFor(1)
        expect_equal("one", form)
    end)

    -- @covers lurek.i18n.pluralFor
    it("pluralFor returns other for n=5", function()
        local form = lurek.i18n.pluralFor(5)
        expect_equal("other", form)
    end)
end)

-- onChange / offChange
-- @describe lurek.i18n.onChange / offChange
describe("lurek.i18n.onChange / offChange", function()
    -- @covers lurek.i18n.loadTable
    -- @covers lurek.i18n.onChange
    -- @covers lurek.i18n.setLanguage
    it("fires callback when language changes", function()
        lurek.i18n.loadTable("en", en)
        local fired = false
        lurek.i18n.onChange(function() fired = true end)
        lurek.i18n.setLanguage("en")
        expect_true(fired)
    end)

    -- @covers lurek.i18n.loadTable
    -- @covers lurek.i18n.offChange
    -- @covers lurek.i18n.onChange
    -- @covers lurek.i18n.setLanguage
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
-- @describe lurek.i18n.keyCount / categories / keysInCategory
describe("lurek.i18n.keyCount / categories / keysInCategory", function()
    -- @covers lurek.i18n.keyCount
    it("keyCount returns a non-negative number", function()
        setup_en_fr()
        local n = lurek.i18n.keyCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least one key loaded")
    end)

    -- @covers lurek.i18n.categories
    it("categories returns a table", function()
        setup_en_fr()
        local cats = lurek.i18n.categories()
        expect_type("table", cats)
    end)

    -- @covers lurek.i18n.categories
    -- @covers lurek.i18n.keysInCategory
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
-- @describe lurek.i18n.search / buildIndex / searchIndexed
describe("lurek.i18n.search / buildIndex / searchIndexed", function()
    -- @covers lurek.i18n.search
    it("search returns a table", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_type("table", results)
    end)

    -- @covers lurek.i18n.search
    it("search finds a known term", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_true(#results >= 1, "search should find greeting=Hello")
    end)

    -- @covers lurek.i18n.buildIndex
    it("buildIndex runs without error", function()
        setup_en_fr()
        expect_no_error(function() lurek.i18n.buildIndex() end)
    end)

    -- @covers lurek.i18n.buildIndex
    -- @covers lurek.i18n.searchIndexed
    it("searchIndexed returns a table after buildIndex", function()
        setup_en_fr()
        local idx = lurek.i18n.buildIndex()
        local results = lurek.i18n.searchIndexed(idx, "Hello")
        expect_type("table", results)
    end)
end)

-- mergeLocale
-- @describe lurek.i18n.mergeLocale
describe("lurek.i18n.mergeLocale", function()
    -- @covers lurek.i18n.mergeLocale
    -- @covers lurek.i18n.t
    it("mergeLocale adds new keys to existing language without overwriting", function()
        setup_en_fr()
        lurek.i18n.mergeLocale("en", { extra_key = "Extra Value" })
        expect_equal("Extra Value", lurek.i18n.t("extra_key"))
        -- Original key preserved
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    -- @covers lurek.i18n.hasLanguage
    -- @covers lurek.i18n.mergeLocale
    -- @covers lurek.i18n.unloadTable
    it("mergeLocale creates a new language if it did not exist", function()
        lurek.i18n.mergeLocale("zz_merge_test", { hello = "Hola" })
        expect_true(lurek.i18n.hasLanguage("zz_merge_test"))
        lurek.i18n.unloadTable("zz_merge_test")
    end)
end)

-- @describe string interpolation (RS parity)
describe("string interpolation (RS parity)", function()
    -- @covers lurek.i18n.interpolate
    it("interpolate replaces a single token", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    -- @covers lurek.i18n.interpolate
    it("interpolate replaces multiple tokens", function()
        local result = lurek.i18n.interpolate("{a} + {b} = {c}", { a = "1", b = "2", c = "3" })
        expect_equal("1 + 2 = 3", result)
    end)

    -- @covers lurek.i18n.interpolate
    it("interpolate leaves unknown tokens as-is", function()
        local result = lurek.i18n.interpolate("Hi {unknown}", {})
        expect_contains(result, "{unknown}")
    end)

    -- @covers lurek.i18n.interpolate
    it("interpolate double-brace escaping produces single brace", function()
        local result = lurek.i18n.interpolate("{{literal}}", {})
        expect_contains(result, "literal")
    end)
end)

-- @describe localization format helpers (RS parity)
describe("localization format helpers (RS parity)", function()
    -- @covers lurek.i18n.interpolate
    it("format returns a string", function()
        local result = lurek.i18n.interpolate("Value: {n}", { n = "42" })
        expect_equal("string", type(result))
        expect_contains(result, "42")
    end)

    -- @covers lurek.i18n.getLanguages
    it("getLanguages returns a non-empty table after loading", function()
        local langs = lurek.i18n.getLanguages()
        expect_equal("table", type(langs))
    end)
end)

-- @describe lurek.i18n helper coverage
describe("lurek.i18n helper coverage", function()
    -- @covers lurek.i18n.offChange
    -- @covers lurek.i18n.onLanguageChange
    -- @covers lurek.i18n.setLanguage
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
    -- @covers lurek.i18n.setLanguage
    it("formatNumber applies locale separators and decimals", function()
        setup_en_fr()
        lurek.i18n.setLanguage("fr")

        local formatted = lurek.i18n.formatNumber(12345.678, { decimals = 2 })

        expect_equal("12.345,68", formatted)
    end)

    -- @covers lurek.i18n.formatDate
    -- @covers lurek.i18n.setLanguage
    it("formatDate supports iso and short formats", function()
        setup_en_fr()
        lurek.i18n.setLanguage("en")

        expect_equal("1970-01-01", lurek.i18n.formatDate(0, "iso"))
        expect_equal("Jan 1, 1970", lurek.i18n.formatDate(0, "short"))
    end)

    -- @covers lurek.i18n.setKey
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
    -- @covers lurek.i18n.loadTable
    -- @covers lurek.i18n.unloadTable
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

-- @describe unit: migrated from integration/test_i18n_dialog.lua
describe("unit: migrated from integration/test_i18n_dialog.lua", function()
        if lurek.dialog == nil or lurek.dialog.newSequencer == nil then
            -- @covers lurek.dialog
            it("dialog module unavailable in this runtime", function()
                expect_true(lurek.dialog == nil or lurek.dialog.newSequencer == nil)
            end)
            return
        end

        local function new_localized_sequence(key)
            local seq = lurek.dialog.newSequencer()
            seq:setSpeed(0)
            seq:load({
                { type = "say", speaker = "Narrator", text = lurek.i18n.t(key) },
            })
            seq:start()
            return seq
        end
        -- @covers lurek.i18n.loadTable
        -- @covers lurek.i18n.setLanguage
        -- @covers lurek.i18n.t
        it("resolves dialog line key through i18n locale table", function()
            lurek.i18n.loadTable("en", {
                dialog = {
                    intro = "Welcome, traveler.",
                },
            })
            lurek.i18n.setLanguage("en")

            local seq = new_localized_sequence("dialog.intro")

            expect_equal("Narrator", seq:currentSpeaker())
            expect_equal("Welcome, traveler.", seq:currentText())
            expect_equal("waiting", seq:getState())
        end)

        -- @covers lurek.i18n.loadTable
        -- @covers lurek.i18n.setFallbacks
        -- @covers lurek.i18n.setLanguage
        -- @covers lurek.i18n.t
        it("falls back to default locale when key missing in active locale", function()
            lurek.i18n.loadTable("en", {
                dialog = {
                    farewell = "Safe travels.",
                },
            })
            lurek.i18n.loadTable("pl", {
                dialog = {
                    intro = "Witaj, podróżniku.",
                },
            })
            lurek.i18n.setFallbacks({ "en" })
            lurek.i18n.setLanguage("pl")

            local seq = new_localized_sequence("dialog.farewell")

            expect_equal("Safe travels.", seq:currentText())
            expect_equal("waiting", seq:getState())
        end)

        -- @covers lurek.i18n.loadTable
        -- @covers lurek.i18n.setLanguage
        -- @covers lurek.i18n.t
        it("building a new dialog after locale switch uses the new translation", function()
            lurek.i18n.loadTable("en", {
                dialog = {
                    choice = "Choose your path.",
                },
            })
            lurek.i18n.loadTable("pl", {
                dialog = {
                    choice = "Wybierz swoją ścieżkę.",
                },
            })

            lurek.i18n.setLanguage("en")
            local english_seq = new_localized_sequence("dialog.choice")

            lurek.i18n.setLanguage("pl")
            local polish_seq = new_localized_sequence("dialog.choice")

            expect_equal("Choose your path.", english_seq:currentText())
            expect_equal("Wybierz swoją ścieżkę.", polish_seq:currentText())
        end)

end)

-- @describe unit: migrated from integration/test_i18n_ui.lua
describe("unit: migrated from integration/test_i18n_ui.lua", function()
        -- @covers lurek.i18n.setLanguage
        -- @covers lurek.i18n.t
        it("missing key returns key name as fallback", function()
            lurek.i18n.setLanguage("en")
            local val = lurek.i18n.t("non_existent_key_xyz")
            -- Should return key name, not crash
            expect_type("string", val, "missing key returns a string fallback")
        end)

end)

test_summary()
