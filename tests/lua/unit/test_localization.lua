-- tests/lua/test_localization.lua
-- BDD-style integration tests for lurek.localization module

-- ===================================================================
-- Setup helpers
-- ===================================================================
-- @covers lurek.localization.getAvailableLanguages
-- @covers lurek.localization.getBase
-- @covers lurek.localization.getLanguage
-- @covers lurek.localization.hasLanguage
-- @covers lurek.localization.loadTable
-- @covers lurek.localization.onChange
-- @covers lurek.localization.setBase
-- @covers lurek.localization.setLanguage
-- @covers lurek.localization.t

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
        start = "Démarrer",
        quit  = "Quitter",
    },
    welcome = "Bienvenue, {name} !",
    items = {
        one   = "{count} article",
        other = "{count} articles",
    },
}

-- ===================================================================
-- Tests
-- ===================================================================
describe("lurek.localization.loadTable + getLanguage", function()
    it("initially has no active language", function()
        expect_nil(lurek.localization.getLanguage())
    end)

    it("loadTable adds a language", function()
        lurek.localization.loadTable("en", en)
        expect_true(lurek.localization.hasLanguage("en"))
    end)

    it("getAvailableLanguages lists loaded languages", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.loadTable("fr", fr)
        local langs = lurek.localization.getAvailableLanguages()
        expect_true(#langs >= 2)
    end)
end)

describe("lurek.localization.setLanguage / getLanguage", function()
    it("sets and gets the active language", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        expect_equal("en", lurek.localization.getLanguage())
    end)
end)

describe("lurek.localization.setBase / getBase", function()
    it("sets a fallback language", function()
        lurek.localization.setBase("en")
        expect_equal("en", lurek.localization.getBase())
    end)
end)

describe("lurek.localization.t — basic lookup", function()
    it("returns translated string for active language", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        expect_equal("Hello", lurek.localization.t("greeting"))
    end)

    it("supports dot-keys for nested tables", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        expect_equal("Start Game", lurek.localization.t("menu.start"))
    end)

    it("returns key when translation missing", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        expect_equal("nonexistent.key", lurek.localization.t("nonexistent.key"))
    end)
end)

describe("lurek.localization.t — fallback", function()
    it("falls back to base language", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.loadTable("fr", fr)
        lurek.localization.setBase("en")
        lurek.localization.setLanguage("fr")
        -- "farewell" exists in both, should return French
        expect_equal("Au revoir", lurek.localization.t("farewell"))
    end)
end)

describe("lurek.localization.t — interpolation", function()
    it("replaces {var} placeholders", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        local result = lurek.localization.t("welcome", { name = "Luna" })
        expect_equal("Welcome, Luna!", result)
    end)
end)

describe("lurek.localization.t — pluralization", function()
    it("selects 'one' for count == 1", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        local result = lurek.localization.t("items", { count = 1 })
        expect_equal("1 item", result)
    end)

    it("selects 'other' for count > 1", function()
        lurek.localization.loadTable("en", en)
        lurek.localization.setLanguage("en")
        local result = lurek.localization.t("items", { count = 5 })
        expect_equal("5 items", result)
    end)
end)

describe("lurek.localization.onChange / offChange", function()
    it("fires callback when language changes", function()
        local fired = false
        lurek.localization.loadTable("en", en)
        lurek.localization.onChange(function() fired = true end)
        lurek.localization.setLanguage("en")
        expect_true(fired)
    end)
end)

test_summary()
