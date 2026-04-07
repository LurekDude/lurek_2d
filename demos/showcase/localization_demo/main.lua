-- Module availability guard (added by fix_nil_module_demos.py)
if not luna.localization then
    function luna.init()
        luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        luna.gfx.print("luna.localization is not available in this build", 180, 270)
    end
    return
end

-- examples/localization_demo/main.lua
-- Demonstrates the luna.localization module: multi-language text, interpolation,
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

local L = luna.localization
local points = 0
local flash_timer = 0
local lang_changed_msg = ""

function luna.init()
    luna.gfx.setBackgroundColor(0.12, 0.12, 0.18)

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

function luna.process(dt)
    if flash_timer > 0 then
        flash_timer = flash_timer - dt
    end
end

function luna.render()
    -- Title
    luna.gfx.setColor(0.9, 0.8, 0.3)
    luna.gfx.print(L.t("title"), 40, 30)

    -- Greeting with interpolation
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print(L.t("greeting", { name = "Luna" }), 40, 80)

    -- Pluralization demo
    luna.gfx.setColor(0.6, 0.9, 0.6)
    luna.gfx.print(L.t("score", { count = points }), 40, 130)

    -- Nested key demo
    luna.gfx.setColor(0.6, 0.7, 1.0)
    luna.gfx.print("Menu: " .. L.t("menu.play") .. " | " .. L.t("menu.quit"), 40, 180)

    -- Available languages
    local langs = L.getAvailableLanguages()
    luna.gfx.setColor(0.5, 0.5, 0.5)
    luna.gfx.print("Available: " .. table.concat(langs, ", "), 40, 230)

    -- Key prompt
    luna.gfx.setColor(0.8, 0.8, 0.8)
    luna.gfx.print(L.t("prompt"), 40, 290)
    luna.gfx.print("Press [UP/DOWN] to change score", 40, 320)

    -- Language-change flash
    if flash_timer > 0 then
        local alpha = math.min(flash_timer, 1.0)
        luna.gfx.setColor(1, 1, 0.2, alpha)
        luna.gfx.print(lang_changed_msg, 40, 380)
    end
end

function luna.keypressed(key)
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
        luna.signal.quit()
    end
end
