-- Module availability guard (added by fix_nil_module_demos.py)
-- Run with: cargo run -- content/demos/showcase/localization_demo
if not lurek.localization then
    function lurek.init()
        lurek.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        lurek.gfx.print("lurek.localization is not available in this build", 180, 270)
    end
    return
end

-- examples/localization_demo/main.lua
-- Demonstrates the lurek.localization module: multi-language text, interpolation,
-- pluralization, and on-the-fly language switching.

-- ===================================================================
-- Translation tables
-- ===================================================================
local translations = {
    en = {
        title    = "Localization Demo",
        greeting = "Hello, {name}!",
        prompt   = "Press [1] English  [2] French  [3] Spanish",
        score    = {
            one   = "You have {count} point",
            other = "You have {count} points",
        },
        menu = {
            play = "Play",
            quit = "Quit",
        },
    },
    fr = {
        title    = "Démo Localisation",
        greeting = "Bonjour, {name} !",
        prompt   = "Appuyez [1] Anglais  [2] Français  [3] Espagnol",
        score    = {
            one   = "Vous avez {count} point",
            other = "Vous avez {count} points",
        },
        menu = {
            play = "Jouer",
            quit = "Quitter",
        },
    },
    es = {
        title    = "Demo de Localización",
        greeting = "¡Hola, {name}!",
        prompt   = "Pulse [1] Inglés  [2] Francés  [3] Español",
        score    = {
            one   = "Tienes {count} punto",
            other = "Tienes {count} puntos",
        },
        menu = {
            play = "Jugar",
            quit = "Salir",
        },
    },
}

local L = lurek.localization
local points = 0
local flash_timer = 0
local lang_changed_msg = ""

function lurek.init()
    lurek.gfx.setBackgroundColor(0.12, 0.12, 0.18)

    -- Load all three languages
    for code, tbl in pairs(translations) do
        L.loadTable(code, tbl)
    end
    L.setBase("en")
    L.setLanguage("en")

    -- Listen for language changes
    L.onChange(function()
        lang_changed_msg = "Language → " .. (L.getLanguage() or "?")
        flash_timer = 2.0
    end)
end

function lurek.process(dt)
    if flash_timer > 0 then
        flash_timer = flash_timer - dt
    end
end

function lurek.render()
    -- Title
    lurek.gfx.setColor(0.9, 0.8, 0.3)
    lurek.gfx.print(L.t("title"), 40, 30)

    -- Greeting with interpolation
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print(L.t("greeting", { name = "Luna" }), 40, 80)

    -- Pluralization demo
    lurek.gfx.setColor(0.6, 0.9, 0.6)
    lurek.gfx.print(L.t("score", { count = points }), 40, 130)

    -- Nested key demo
    lurek.gfx.setColor(0.6, 0.7, 1.0)
    lurek.gfx.print("Menu: " .. L.t("menu.play") .. " | " .. L.t("menu.quit"), 40, 180)

    -- Available languages
    local langs = L.getAvailableLanguages()
    lurek.gfx.setColor(0.5, 0.5, 0.5)
    lurek.gfx.print("Available: " .. table.concat(langs, ", "), 40, 230)

    -- Key prompt
    lurek.gfx.setColor(0.8, 0.8, 0.8)
    lurek.gfx.print(L.t("prompt"), 40, 290)
    lurek.gfx.print("Press [UP/DOWN] to change score", 40, 320)

    -- Language-change flash
    if flash_timer > 0 then
        local alpha = math.min(flash_timer, 1.0)
        lurek.gfx.setColor(1, 1, 0.2, alpha)
        lurek.gfx.print(lang_changed_msg, 40, 380)
    end
end

function lurek.keypressed(key)
    if key == "1" then
        L.setLanguage("en")
    elseif key == "2" then
        L.setLanguage("fr")
    elseif key == "3" then
        L.setLanguage("es")
    elseif key == "up" then
        points = points + 1
    elseif key == "down" then
        points = math.max(0, points - 1)
    elseif key == "escape" then
        lurek.signal.quit()
    end
end
