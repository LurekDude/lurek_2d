-- tests/lua/test_localization.lua
-- BDD-style integration tests for luna.localization module

-- ===================================================================
-- Setup helpers
-- ===================================================================
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
describe("luna.localization.loadTable + getLanguage", function()
    it("initially has no active language", function()
        expect_nil(luna.localization.getLanguage())
    end)

    it("loadTable adds a language", function()
        luna.localization.loadTable("en", en)
        expect_true(luna.localization.hasLanguage("en"))
    end)

    it("getAvailableLanguages lists loaded languages", function()
        luna.localization.loadTable("en", en)
        luna.localization.loadTable("fr", fr)
        local langs = luna.localization.getAvailableLanguages()
        expect_true(#langs >= 2)
    end)
end)

describe("luna.localization.setLanguage / getLanguage", function()
    it("sets and gets the active language", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        expect_equal("en", luna.localization.getLanguage())
    end)
end)

describe("luna.localization.setBase / getBase", function()
    it("sets a fallback language", function()
        luna.localization.setBase("en")
        expect_equal("en", luna.localization.getBase())
    end)
end)

describe("luna.localization.t — basic lookup", function()
    it("returns translated string for active language", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        expect_equal("Hello", luna.localization.t("greeting"))
    end)

    it("supports dot-keys for nested tables", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        expect_equal("Start Game", luna.localization.t("menu.start"))
    end)

    it("returns key when translation missing", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        expect_equal("nonexistent.key", luna.localization.t("nonexistent.key"))
    end)
end)

describe("luna.localization.t — fallback", function()
    it("falls back to base language", function()
        luna.localization.loadTable("en", en)
        luna.localization.loadTable("fr", fr)
        luna.localization.setBase("en")
        luna.localization.setLanguage("fr")
        -- "farewell" exists in both, should return French
        expect_equal("Au revoir", luna.localization.t("farewell"))
    end)
end)

describe("luna.localization.t — interpolation", function()
    it("replaces {var} placeholders", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        local result = luna.localization.t("welcome", { name = "Luna" })
        expect_equal("Welcome, Luna!", result)
    end)
end)

describe("luna.localization.t — pluralization", function()
    it("selects 'one' for count == 1", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        local result = luna.localization.t("items", { count = 1 })
        expect_equal("1 item", result)
    end)

    it("selects 'other' for count > 1", function()
        luna.localization.loadTable("en", en)
        luna.localization.setLanguage("en")
        local result = luna.localization.t("items", { count = 5 })
        expect_equal("5 items", result)
    end)
end)

describe("luna.localization.onChange / offChange", function()
    it("fires callback when language changes", function()
        local fired = false
        luna.localization.loadTable("en", en)
        luna.localization.onChange(function() fired = true end)
        luna.localization.setLanguage("en")
        expect_true(fired)
    end)
end)

test_summary()
