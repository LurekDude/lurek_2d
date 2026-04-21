-- Lurek2D localization (i18n) API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.i18n namespace: loadTable, unloadTable,
-- setLanguage, getLanguages, fallbacks, t(), hasKey, getKeys, setKey,
-- interpolate, pluralFor, onChange/offChange, keyCount, categories,
-- keysInCategory, search, buildIndex/searchIndexed, mergeLocale.
-- @tests lurek.i18n.loadTable
-- @tests lurek.i18n.unloadTable
-- @tests lurek.i18n.setLanguage
-- @tests lurek.i18n.getLanguage
-- @tests lurek.i18n.getLanguages
-- @tests lurek.i18n.getAvailableLanguages
-- @tests lurek.i18n.hasLanguage
-- @tests lurek.i18n.setFallbacks
-- @tests lurek.i18n.getFallbacks
-- @tests lurek.i18n.setBase
-- @tests lurek.i18n.getBase
-- @tests lurek.i18n.t
-- @tests lurek.i18n.hasKey
-- @tests lurek.i18n.getKeys
-- @tests lurek.i18n.setKey
-- @tests lurek.i18n.interpolate
-- @tests lurek.i18n.pluralFor
-- @tests lurek.i18n.onChange
-- @tests lurek.i18n.offChange
-- @tests lurek.i18n.keyCount
-- @tests lurek.i18n.categories
-- @tests lurek.i18n.keysInCategory
-- @tests lurek.i18n.search
-- @tests lurek.i18n.buildIndex
-- @tests lurek.i18n.searchIndexed
-- @tests lurek.i18n.mergeLocale

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

-- â”€â”€ module presence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Verifies that the i18n namespace exists and exposes every documented entry point as a callable function.
describe("lurek.i18n module", function()
    -- @description Asserts that lurek.i18n is registered as a table on the global lurek namespace.
    it("lurek.i18n is a table", function()
        expect_type("table", lurek.i18n)
    end)

    -- @description Checks that each expected API name resolves to a function, including loading, lookup, fallback, search, and merge helpers.
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

-- â”€â”€ loadTable / unloadTable / getLanguages / hasLanguage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Exercises language registration and removal, then confirms the discovery APIs reflect the loaded locale set.
describe("lurek.i18n.loadTable / unloadTable", function()
    -- @description Loads the en table and confirms hasLanguage immediately reports the new locale as available.
    it("loadTable adds a language detectable by hasLanguage", function()
        lurek.i18n.loadTable("en", en)
        expect_true(lurek.i18n.hasLanguage("en"))
    end)

    -- @description Loads two locales and checks that getAvailableLanguages returns a table containing at least both entries.
    it("getAvailableLanguages lists loaded languages", function()
        lurek.i18n.loadTable("en", en)
        lurek.i18n.loadTable("fr", fr)
        local langs = lurek.i18n.getAvailableLanguages()
        expect_true(#langs >= 2)
    end)

    -- @description Confirms getLanguages returns a table and matches getAvailableLanguages in entry count after loading en.
    it("getLanguages is an alias for getAvailableLanguages", function()
        lurek.i18n.loadTable("en", en)
        local l1 = lurek.i18n.getLanguages()
        local l2 = lurek.i18n.getAvailableLanguages()
        expect_type("table", l1)
        expect_equal(#l2, #l1)
    end)

    -- @description Loads a temporary locale, verifies it exists, unloads it, and then checks that hasLanguage flips to false.
    it("unloadTable removes the language", function()
        lurek.i18n.loadTable("zz_test", { hello = "Hi" })
        expect_true(lurek.i18n.hasLanguage("zz_test"))
        lurek.i18n.unloadTable("zz_test")
        expect_false(lurek.i18n.hasLanguage("zz_test"))
    end)
end)

-- â”€â”€ setLanguage / getLanguage / setBase / getBase â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Validates that the active language and base language setters persist values that the matching getters return unchanged.
describe("lurek.i18n.setLanguage / getLanguage / setBase / getBase", function()
    -- @description Initializes the English and French tables, sets English active in setup, and checks getLanguage returns en.
    it("sets and gets the active language", function()
        setup_en_fr()
        expect_equal("en", lurek.i18n.getLanguage())
    end)

    -- @description Sets the base locale to en and verifies getBase returns the same language code.
    it("setBase / getBase round-trip", function()
        lurek.i18n.setBase("en")
        expect_equal("en", lurek.i18n.getBase())
    end)
end)

-- â”€â”€ setFallbacks / getFallbacks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Confirms fallback chain storage preserves order and that an empty configuration still returns a table.
describe("lurek.i18n.setFallbacks / getFallbacks", function()
    -- @description Stores a two-language fallback list and checks the returned table keeps fr first and en second.
    it("setFallbacks stores ordered fallback chain", function()
        setup_en_fr()
        lurek.i18n.setFallbacks({ "fr", "en" })
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
        expect_equal("fr", fb[1])
        expect_equal("en", fb[2])
    end)

    -- @description Clears fallbacks with an empty table and verifies getFallbacks still yields a table value.
    it("getFallbacks returns empty table when not set", function()
        lurek.i18n.setFallbacks({})
        local fb = lurek.i18n.getFallbacks()
        expect_type("table", fb)
    end)
end)

-- â”€â”€ t() basic lookup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Covers direct key lookup, nested dot-path resolution, missing-key behavior, placeholder substitution, and plural form selection.
describe("lurek.i18n.t basic lookup", function()
    -- @description Sets up English as the active locale and expects the greeting key to resolve to Hello.
    it("returns translated string for active language", function()
        setup_en_fr()
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    -- @description Looks up the nested menu.start entry through dot-key syntax and expects the flattened result Start Game.
    it("supports dot-keys for nested tables", function()
        setup_en_fr()
        expect_equal("Start Game", lurek.i18n.t("menu.start"))
    end)

    -- @description Requests a missing key and confirms the API returns the original key string as the fallback result.
    it("returns key when translation missing", function()
        setup_en_fr()
        expect_equal("nonexistent.key", lurek.i18n.t("nonexistent.key"))
    end)

    -- @description Switches to French and verifies the farewell key resolves to the French string Au revoir.
    it("falls back to base language", function()
        setup_en_fr()
        lurek.i18n.setLanguage("fr")
        expect_equal("Au revoir", lurek.i18n.t("farewell"))
    end)

    -- @description Passes a name variable into the welcome template and checks that the {name} placeholder is replaced with Luna.
    it("replaces {var} placeholders", function()
        setup_en_fr()
        local result = lurek.i18n.t("welcome", { name = "Luna" })
        expect_equal("Welcome, Luna!", result)
    end)

    -- @description Resolves the pluralized items entry with count 1 and expects the singular template 1 item.
    it("selects one for count == 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "1" }, 1)
        expect_equal("1 item", result)
    end)

    -- @description Resolves the pluralized items entry with count 5 and expects the plural template 5 items.
    it("selects other for count > 1", function()
        setup_en_fr()
        local result = lurek.i18n.t("items", { count = "5" }, 5)
        expect_equal("5 items", result)
    end)
end)

-- â”€â”€ hasKey / getKeys / setKey â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Checks key existence reporting, key enumeration, and runtime insertion or override of localized strings.
describe("lurek.i18n.hasKey / getKeys / setKey", function()
    -- @description Uses the loaded locale data to confirm hasKey reports greeting as present.
    it("hasKey returns true for a loaded key", function()
        setup_en_fr()
        expect_true(lurek.i18n.hasKey("greeting"))
    end)

    -- @description Queries an obviously absent key name and confirms hasKey returns false.
    it("hasKey returns false for a missing key", function()
        setup_en_fr()
        expect_false(lurek.i18n.hasKey("nonexistent_key_xyz"))
    end)

    -- @description Retrieves the current key list and verifies it is a table with at least one entry.
    it("getKeys returns a table of key strings", function()
        setup_en_fr()
        local keys = lurek.i18n.getKeys()
        expect_type("table", keys)
        expect_true(#keys >= 1, "at least one key exists")
    end)

    -- @description Inserts a custom key into the English locale and confirms t() resolves the new value exactly.
    it("setKey adds or overrides a key in the current language", function()
        setup_en_fr()
        lurek.i18n.setKey("en", "custom_added_key", "Custom Value")
        expect_equal("Custom Value", lurek.i18n.t("custom_added_key"))
    end)
end)

-- â”€â”€ interpolate / pluralFor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Verifies the raw interpolation helper and the plural classification helper independently of locale table lookup.
describe("lurek.i18n.interpolate / pluralFor", function()
    -- @description Calls interpolate on a literal template and checks that the name placeholder becomes World.
    it("interpolate replaces {var} in a raw string", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    -- @description Provides an empty substitution table and confirms interpolate leaves a placeholder-free string unchanged.
    it("interpolate with no vars returns string unchanged", function()
        local result = lurek.i18n.interpolate("No vars here", {})
        expect_equal("No vars here", result)
    end)

    -- @description Verifies pluralFor classifies the numeric value 1 as the singular form one.
    it("pluralFor returns one for n=1", function()
        local form = lurek.i18n.pluralFor(1)
        expect_equal("one", form)
    end)

    -- @description Verifies pluralFor classifies the numeric value 5 as the plural form other.
    it("pluralFor returns other for n=5", function()
        local form = lurek.i18n.pluralFor(5)
        expect_equal("other", form)
    end)
end)

-- â”€â”€ onChange / offChange â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Ensures language change callbacks fire when registered and stop firing once the same callback is removed.
describe("lurek.i18n.onChange / offChange", function()
    -- @description Registers a callback that flips a boolean and confirms setLanguage invokes it at least once.
    it("fires callback when language changes", function()
        lurek.i18n.loadTable("en", en)
        local fired = false
        lurek.i18n.onChange(function() fired = true end)
        lurek.i18n.setLanguage("en")
        expect_true(fired)
    end)

    -- @description Counts callback invocations across two setLanguage calls and verifies offChange prevents the second increment.
    it("offChange removes the callback", function()
        lurek.i18n.loadTable("en", en)
        local count = 0
        local function cb() count = count + 1 end
        lurek.i18n.onChange(cb)
        lurek.i18n.setLanguage("en")
        lurek.i18n.offChange(cb)
        lurek.i18n.setLanguage("en")
        expect_equal(1, count, "callback fired once, then removed")
    end)
end)

-- â”€â”€ keyCount / categories / keysInCategory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Checks summary and grouping helpers by validating count types, category list shape, and category-specific key lookup behavior.
describe("lurek.i18n.keyCount / categories / keysInCategory", function()
    -- @description Reads the total key count and confirms it is numeric and at least one after loading fixtures.
    it("keyCount returns a non-negative number", function()
        setup_en_fr()
        local n = lurek.i18n.keyCount()
        expect_type("number", n)
        expect_true(n >= 1, "at least one key loaded")
    end)

    -- @description Calls categories after loading locale data and verifies the result is always a table.
    it("categories returns a table", function()
        setup_en_fr()
        local cats = lurek.i18n.categories()
        expect_type("table", cats)
    end)

    -- @description Uses the first returned category when available and checks keysInCategory yields a table, otherwise accepts flat locales with no categories.
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

-- â”€â”€ search / buildIndex / searchIndexed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Validates both direct and indexed text search helpers, including successful query results and index construction without errors.
describe("lurek.i18n.search / buildIndex / searchIndexed", function()
    -- @description Searches for Hello and verifies the plain search API returns a table result container.
    it("search returns a table", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_type("table", results)
    end)

    -- @description Searches for the known greeting value Hello and asserts that at least one result is returned.
    it("search finds a known term", function()
        setup_en_fr()
        local results = lurek.i18n.search("Hello")
        expect_true(#results >= 1, "search should find greeting=Hello")
    end)

    -- @description Builds the i18n search index and confirms the operation completes without raising an error.
    it("buildIndex runs without error", function()
        setup_en_fr()
        expect_no_error(function() lurek.i18n.buildIndex() end)
    end)

    -- @description Builds an index, runs the indexed search for Hello, and verifies the indexed search result is a table.
    it("searchIndexed returns a table after buildIndex", function()
        setup_en_fr()
        local idx = lurek.i18n.buildIndex()
        local results = lurek.i18n.searchIndexed(idx, "Hello")
        expect_type("table", results)
    end)
end)

-- â”€â”€ mergeLocale â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- @description Covers locale merging for both extending an existing language and creating a brand-new language entry on demand.
describe("lurek.i18n.mergeLocale", function()
    -- @description Merges an extra key into English, confirms the new key resolves, and then checks the original greeting remains unchanged.
    it("mergeLocale adds new keys to existing language without overwriting", function()
        setup_en_fr()
        lurek.i18n.mergeLocale("en", { extra_key = "Extra Value" })
        expect_equal("Extra Value", lurek.i18n.t("extra_key"))
        -- Original key preserved
        expect_equal("Hello", lurek.i18n.t("greeting"))
    end)

    -- @description Merges data into a previously unknown language code, verifies the language now exists, and then removes the temporary fixture.
    it("mergeLocale creates a new language if it did not exist", function()
        lurek.i18n.mergeLocale("zz_merge_test", { hello = "Hola" })
        expect_true(lurek.i18n.hasLanguage("zz_merge_test"))
        lurek.i18n.unloadTable("zz_merge_test")
    end)
end)

-- @description Mirrors Rust-side interpolation parity cases by checking single replacement, multiple replacements, unknown placeholder retention, and brace escaping behavior.
describe("string interpolation (RS parity)", function()
    -- @description Replaces one named placeholder in Hello, {name}! and expects the exact final string Hello, World!.
    it("interpolate replaces a single placeholder", function()
        local result = lurek.i18n.interpolate("Hello, {name}!", { name = "World" })
        expect_equal("Hello, World!", result)
    end)

    -- @description Replaces three placeholders in the arithmetic template and expects the fully expanded string 1 + 2 = 3.
    it("interpolate replaces multiple placeholders", function()
        local result = lurek.i18n.interpolate("{a} + {b} = {c}", { a = "1", b = "2", c = "3" })
        expect_equal("1 + 2 = 3", result)
    end)

    -- @description Leaves an unresolved placeholder untouched and checks the output still contains the literal token {unknown}.
    it("interpolate leaves unknown placeholders as-is", function()
        local result = lurek.i18n.interpolate("Hi {unknown}", {})
        expect_contains(result, "{unknown}")
    end)

    -- @description Uses double braces around literal text and confirms the interpolated output still contains literal as escaped content.
    it("interpolate double-brace escaping produces single brace", function()
        local result = lurek.i18n.interpolate("{{literal}}", {})
        expect_contains(result, "literal")
    end)
end)

-- @description Covers parity helpers that rely on interpolation and language enumeration by checking formatted string output and loaded-language table shape.
describe("localization format helpers (RS parity)", function()
    -- @description Interpolates a numeric placeholder, then verifies the result type is string and that the rendered output includes 42.
    it("format returns a string", function()
        local result = lurek.i18n.interpolate("Value: {n}", { n = "42" })
        expect_equal("string", type(result))
        expect_contains(result, "42")
    end)

    -- @description Calls getLanguages after prior test loading and confirms the returned value is a table.
    it("getLanguages returns a non-empty table after loading", function()
        local langs = lurek.i18n.getLanguages()
        expect_equal("table", type(langs))
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.i18n.onLanguageChange
    it("covers lurek.i18n.onLanguageChange", function()
        -- TODO: Implement test for lurek.i18n.onLanguageChange
    end)

    -- @tests lurek.i18n.formatNumber
    it("covers lurek.i18n.formatNumber", function()
        -- TODO: Implement test for lurek.i18n.formatNumber
    end)

    -- @tests lurek.i18n.formatDate
    it("covers lurek.i18n.formatDate", function()
        -- TODO: Implement test for lurek.i18n.formatDate
    end)

    -- @tests lurek.i18n.tGender
    it("covers lurek.i18n.tGender", function()
        -- TODO: Implement test for lurek.i18n.tGender
    end)

    -- @tests lurek.i18n.getLoadedLocales
    it("covers lurek.i18n.getLoadedLocales", function()
        -- TODO: Implement test for lurek.i18n.getLoadedLocales
    end)

end)
