-- ============================================================================
-- Localization Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/localization_demo/main.lua
-- Run with : cargo run -- content/games/showcase/localization_demo
-- ============================================================================
-- Multi-language localization showcase: instant language switching, variable
-- interpolation, pluralization rules, number formatting, coverage meter,
-- and a mock game menu with localized buttons.
-- Controls: 1-4 switch language, R toggle RTL preview, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE_TITLE    = "TITLE"
local STATE_BROWSING = "BROWSING"
local current_state  = STATE_TITLE

local LANGS       = { "en", "fr", "es", "pl" }
local LANG_NAMES  = { en = "English", fr = "Français", es = "Español", pl = "Polski" }
local current_lang = "en"

local rtl_mode = false
local title_timer = 0

-- Player name for interpolation demo
local player_name = "Luna"

-- Demo item counts for pluralization
local item_counts = { 0, 1, 2, 5, 12, 100 }
local item_index  = 1
local item_cycle_timer = 0

-- Clock
local clock_seconds = 0

-- ---------------------------------------------------------------------------
-- Translation table  (25 keys)
-- ---------------------------------------------------------------------------
local T = {
    -- Menu
    new_game     = { en = "New Game",       fr = "Nouvelle partie",   es = "Nueva partida",    pl = "Nowa gra"          },
    load_game    = { en = "Load Game",      fr = "Charger partie",    es = "Cargar partida",   pl = "Wczytaj grę"       },
    settings     = { en = "Settings",       fr = "Paramètres",        es = "Ajustes",          pl = "Ustawienia"        },
    quit         = { en = "Quit",           fr = "Quitter",           es = "Salir",            pl = "Wyjdź"             },
    -- UI labels
    language     = { en = "Language",       fr = "Langue",            es = "Idioma",           pl = "Język"             },
    fps_label    = { en = "FPS",            fr = "IPS",               es = "FPS",              pl = "FPS"               },
    time_label   = { en = "Time",           fr = "Heure",             es = "Hora",             pl = "Czas"              },
    items_label  = { en = "Items",          fr = "Objets",            es = "Objetos",          pl = "Przedmioty"        },
    coverage     = { en = "Coverage",       fr = "Couverture",        es = "Cobertura",        pl = "Pokrycie"          },
    demo_title   = { en = "Localization Demo", fr = "Démo localisation", es = "Demo localización", pl = "Demo lokalizacji" },
    -- Game text
    welcome      = { en = "Welcome, {name}!", fr = "Bienvenue, {name} !", es = "¡Bienvenido, {name}!", pl = "Witaj, {name}!" },
    score        = { en = "Score",          fr = "Score",             es = "Puntuación",       pl = "Wynik"             },
    level        = { en = "Level",          fr = "Niveau",            es = "Nivel",            pl = "Poziom"            },
    health       = { en = "Health",         fr = "Santé",             es = "Salud",            pl = "Zdrowie"           },
    press_start  = { en = "Press ENTER to start", fr = "Appuyez sur ENTRÉE", es = "Pulsa ENTER para empezar", pl = "Naciśnij ENTER aby zacząć" },
    controls     = { en = "Controls",       fr = "Commandes",         es = "Controles",        pl = "Sterowanie"        },
    mission      = { en = "Mission complete!", fr = "Mission accomplie !", es = "¡Misión completada!", pl = "Misja zakończona!" },
    paused       = { en = "Paused",         fr = "En pause",          es = "Pausado",          pl = "Pauza"             },
    inventory    = { en = "Inventory",      fr = "Inventaire",        es = "Inventario",       pl = "Ekwipunek"         },
    dialog_yes   = { en = "Yes",            fr = "Oui",              es = "Sí",               pl = "Tak"               },
    dialog_no    = { en = "No",             fr = "Non",              es = "No",               pl = "Nie"               },
    confirm      = { en = "Confirm",        fr = "Confirmer",        es = "Confirmar",        pl = "Potwierdź"         },
    cancel       = { en = "Cancel",         fr = "Annuler",          es = "Cancelar",         pl = "Anuluj"            },
    back         = { en = "Back",           fr = "Retour",           es = "Atrás",            pl = "Wróć"              },
    rtl_hint     = { en = "RTL Preview",    fr = "Aperçu RTL",      es = "Vista RTL",        pl = "Podgląd RTL"       },
}

-- Pluralization strings: { singular, plural } or { singular, few, many } for Polish
local PLURALS = {
    en = { "{n} item",  "{n} items" },
    fr = { "{n} objet", "{n} objets" },
    es = { "{n} objeto","{n} objetos" },
    pl = { "{n} przedmiot", "{n} przedmioty", "{n} przedmiotów" },
}

-- ---------------------------------------------------------------------------
-- Engine objects
-- ---------------------------------------------------------------------------
local camera       = nil
local ps_confetti  = nil

-- Tween / animation values
local menu_buttons = {}       -- { label_key, y, target_y, alpha }
local text_fade    = { a = 1.0 }
local title_alpha  = { a = 1.0 }
local title_scale  = { s = 1.0 }
local subtitle_alpha = { a = 0.0 }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function lerp(a, b, t) return a + (b - a) * t end

--- Fetch a translated string; returns [MISSING: key] if absent
local function tr(key)
    local entry = T[key]
    if not entry then return "[MISSING: " .. key .. "]" end
    local val = entry[current_lang]
    if not val then return "[MISSING: " .. key .. "]" end
    return val
end

--- Interpolate {name} placeholders
local function tr_interp(key, vars)
    local s = tr(key)
    for k, v in pairs(vars) do
        s = s:gsub("{" .. k .. "}", tostring(v))
    end
    return s
end

--- Pluralize: pick correct form based on language and count
local function plural(n)
    local forms = PLURALS[current_lang]
    if not forms then return tostring(n) end

    if current_lang == "pl" then
        -- Polish: 1 → singular, 2-4 (not 12-14) → few, else → many
        local abs_n = math.abs(n)
        local last_digit = abs_n % 10
        local last_two   = abs_n % 100
        local form
        if n == 1 then
            form = forms[1]
        elseif last_digit >= 2 and last_digit <= 4 and (last_two < 12 or last_two > 14) then
            form = forms[2] or forms[1]
        else
            form = forms[3] or forms[2] or forms[1]
        end
        return form:gsub("{n}", tostring(n))
    elseif current_lang == "fr" then
        -- French: 0 and 1 → singular, else plural
        local form = (n <= 1) and forms[1] or forms[2]
        return form:gsub("{n}", tostring(n))
    else
        -- English / Spanish: 1 → singular, else plural
        local form = (n == 1) and forms[1] or forms[2]
        return form:gsub("{n}", tostring(n))
    end
end

--- Format number with locale-specific separators
local function format_number(n)
    local int_part  = math.floor(n)
    local frac_part = n - int_part
    local frac_str  = string.format("%.2f", frac_part):sub(2) -- ".56"

    -- Insert thousands separators
    local s = tostring(int_part)
    local len = #s
    local parts = {}
    local j = 0
    for i = len, 1, -1 do
        j = j + 1
        table.insert(parts, 1, s:sub(i, i))
        if j % 3 == 0 and i > 1 then
            if current_lang == "fr" or current_lang == "pl" then
                table.insert(parts, 1, " ")   -- space separator
            else
                table.insert(parts, 1, ",")   -- comma separator
            end
        end
    end
    local int_str = table.concat(parts)

    -- Decimal separator
    if current_lang == "fr" or current_lang == "pl" then
        frac_str = frac_str:gsub("%.", ",")
    end

    return int_str .. frac_str
end

--- Format clock time for locale
local function format_time(secs)
    local h = math.floor(secs / 3600) % 24
    local m = math.floor(secs / 60) % 60
    local s = math.floor(secs) % 60
    if current_lang == "en" then
        local ampm = h >= 12 and "PM" or "AM"
        local h12 = h % 12
        if h12 == 0 then h12 = 12 end
        return string.format("%d:%02d:%02d %s", h12, m, s, ampm)
    else
        return string.format("%02d:%02d:%02d", h, m, s)
    end
end

--- Count translation coverage for current language
local function get_coverage()
    local total = 0
    local translated = 0
    for _, entry in pairs(T) do
        total = total + 1
        if entry[current_lang] then
            translated = translated + 1
        end
    end
    return translated, total
end

--- Emit language switch confetti
local function emit_confetti()
    if ps_confetti then
        for i = 1, 6 do
            ps_confetti:emit(math.random(80, SCREEN_W - 80), math.random(80, SCREEN_H - 80), 14)
        end
    end
end

--- Animate text swap fade
local function do_text_fade()
    text_fade.a = 0.0
    lurek.tween.to(text_fade, 0.25, { a = 1.0 }, "outQuad")
end

--- Slide menu buttons to their target positions
local function slide_menu_buttons()
    for i, btn in ipairs(menu_buttons) do
        btn.y = btn.target_y + 40
        btn.alpha = 0
        lurek.tween.to(btn, 0.4 + i * 0.08, { y = btn.target_y, alpha = 1.0 }, "outBack")
    end
end

--- Switch language with full fanfare
local function switch_language(lang)
    if lang == current_lang then return end
    current_lang = lang
    emit_confetti()
    do_text_fade()
    slide_menu_buttons()
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Localization Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.06, 0.1)

    -- Input bindings
    lurek.input.bind("lang1", { "1" })
    lurek.input.bind("lang2", { "2" })
    lurek.input.bind("lang3", { "3" })
    lurek.input.bind("lang4", { "4" })
    lurek.input.bind("rtl",   { "r" })
    lurek.input.bind("quit",  { "escape" })
    lurek.input.bind("start", { "return" })

    -- Camera
    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Confetti particles (language switch celebration)
    ps_confetti = lurek.particle.newSystem({
        maxParticles = 300, emissionRate = 0,
        lifetimeMin = 0.5, lifetimeMax = 1.4,
        speedMin = 50, speedMax = 220, direction = -1.57, spread = 6.28,
        gravityY = 180,
        sizes = { 6, 3, 0 },
        colors = { 1, 0.9, 0.2, 1, 0.2, 0.6, 1.0, 0 },
    })

    -- Build menu buttons
    local menu_keys = { "new_game", "load_game", "settings", "quit" }
    local btn_y_start = 260
    local btn_spacing = 52
    for i, key in ipairs(menu_keys) do
        menu_buttons[i] = {
            label_key = key,
            y = btn_y_start + (i - 1) * btn_spacing,
            target_y = btn_y_start + (i - 1) * btn_spacing,
            alpha = 1.0,
            hover = false,
        }
    end
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
function lurek.ready()
    -- Title fade-in and subtitle stagger
    title_alpha.a = 0.0
    lurek.tween.to(title_alpha, 0.8, { a = 1.0 }, "outQuad")
    lurek.tween.to(subtitle_alpha, 1.0, { a = 1.0 }, "outQuad")
    title_scale.s = 1.3
    lurek.tween.to(title_scale, 0.6, { s = 1.0 }, "outBack")
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Global quit
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update systems
    ps_confetti:update(dt)
    lurek.tween.update(dt)

    -- Clock
    clock_seconds = clock_seconds + dt

    -- Cycle item count for pluralization demo
    item_cycle_timer = item_cycle_timer + dt
    if item_cycle_timer > 2.0 then
        item_cycle_timer = 0
        item_index = (item_index % #item_counts) + 1
    end

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE_TITLE then
        title_timer = title_timer + dt
        if lurek.input.wasActionPressed("start") then
            current_state = STATE_BROWSING
            slide_menu_buttons()
        end
        return
    end

    -- ── BROWSING ──────────────────────────────────────────────
    -- Language switch
    if lurek.input.wasActionPressed("lang1") then switch_language("en") end
    if lurek.input.wasActionPressed("lang2") then switch_language("fr") end
    if lurek.input.wasActionPressed("lang3") then switch_language("es") end
    if lurek.input.wasActionPressed("lang4") then switch_language("pl") end

    -- RTL toggle
    if lurek.input.wasActionPressed("rtl") then
        rtl_mode = not rtl_mode
        emit_confetti()
    end

    -- Menu button hover detection
    local mx, my = lurek.input.getMousePosition()
    for _, btn in ipairs(menu_buttons) do
        local bx = rtl_mode and (SCREEN_W - 380 - 200) or 380
        btn.hover = mx >= bx and mx <= bx + 200 and my >= btn.y - 18 and my <= btn.y + 18
    end
end

-- ---------------------------------------------------------------------------
-- Render (world space)
-- ---------------------------------------------------------------------------
function lurek.render()
    camera:attach()

    if current_state == STATE_TITLE then
        -- Title screen
        local cx = SCREEN_W / 2
        local cy = SCREEN_H / 2 - 60
        local pulse = 0.85 + 0.15 * math.sin(title_timer * 2.5)

        lurek.render.setColor(0.3, 0.7, 1.0, title_alpha.a * pulse * title_scale.s)
        lurek.render.print("LOCALIZATION DEMO", cx - 160, cy, 32)

        lurek.render.setColor(0.8, 0.6, 1.0, subtitle_alpha.a * pulse)
        lurek.render.print("SPEAK EVERY LANGUAGE", cx - 130, cy + 50, 20)

        -- Blinking prompt
        if math.floor(title_timer * 2) % 2 == 0 then
            lurek.render.setColor(0.6, 0.6, 0.6, title_alpha.a * 0.8)
            lurek.render.print("Press ENTER", cx - 55, cy + 130, 16)
        end
    else
        -- Particles in world space
        lurek.render.setColor(1, 1, 1, 1)
        ps_confetti:draw()
    end

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    if current_state == STATE_TITLE then return end

    local fade = text_fade.a
    local x_base = rtl_mode and SCREEN_W or 0
    local x_dir  = rtl_mode and -1 or 1

    -- ── Header bar ────────────────────────────────────────────
    lurek.render.setColor(0.12, 0.10, 0.16, 0.95)
    lurek.render.drawRect("fill", 0, 0, SCREEN_W, 44)

    -- Language name
    lurek.render.setColor(0.4, 0.85, 1.0, fade)
    local lang_x = rtl_mode and (SCREEN_W - 20) or 20
    lurek.render.print(tr("language") .. ": " .. LANG_NAMES[current_lang], lang_x, 12, 18)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.6, 0.6, 0.6, 0.8)
    lurek.render.print(tr("fps_label") .. ": " .. tostring(fps), SCREEN_W - 110, 12, 14)

    -- Key hints
    lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
    lurek.render.print("1:EN  2:FR  3:ES  4:PL  R:RTL", SCREEN_W / 2 - 100, 14, 12)

    -- ── Welcome banner ────────────────────────────────────────
    local welcome_text = tr_interp("welcome", { name = player_name })
    lurek.render.setColor(1.0, 0.9, 0.5, fade)
    local welcome_x = rtl_mode and (SCREEN_W - 60) or 60
    lurek.render.print(welcome_text, welcome_x, 60, 22)

    -- ── Menu buttons ──────────────────────────────────────────
    for i, btn in ipairs(menu_buttons) do
        local bx = rtl_mode and (SCREEN_W - 380 - 200) or 380
        local bw, bh = 200, 36

        -- Button background
        if btn.hover then
            lurek.render.setColor(0.25, 0.20, 0.35, btn.alpha * fade)
        else
            lurek.render.setColor(0.15, 0.12, 0.22, btn.alpha * fade)
        end
        lurek.render.drawRect("fill", bx, btn.y - 18, bw, bh, 6)

        -- Button border
        lurek.render.setColor(0.4, 0.3, 0.6, btn.alpha * fade * 0.6)
        lurek.render.drawRect("line", bx, btn.y - 18, bw, bh, 6)

        -- Button text
        lurek.render.setColor(0.9, 0.85, 1.0, btn.alpha * fade)
        local label = tr(btn.label_key)
        lurek.render.print(label, bx + 20, btn.y - 8, 18)
    end

    -- ── Left column: localization info ────────────────────────
    local col_x = rtl_mode and (SCREEN_W - 320) or 40
    local cy = 100

    -- Time display
    lurek.render.setColor(0.7, 0.7, 0.9, fade)
    lurek.render.print(tr("time_label") .. ": " .. format_time(clock_seconds + 43200), col_x, cy, 16)
    cy = cy + 30

    -- Number formatting
    local big_number = 1234.56
    lurek.render.setColor(0.7, 0.9, 0.7, fade)
    lurek.render.print("Number: " .. format_number(big_number), col_x, cy, 16)
    cy = cy + 30

    -- Pluralization
    local count = item_counts[item_index]
    lurek.render.setColor(0.9, 0.7, 0.5, fade)
    lurek.render.print(tr("items_label") .. ": " .. plural(count), col_x, cy, 16)
    cy = cy + 30

    -- Interpolation demo
    lurek.render.setColor(0.9, 0.8, 0.6, fade)
    lurek.render.print(tr_interp("welcome", { name = "Player1" }), col_x, cy, 14)
    cy = cy + 25
    lurek.render.print(tr_interp("welcome", { name = "世界" }), col_x, cy, 14)
    cy = cy + 40

    -- ── Additional labels showcase ────────────────────────────
    local labels = { "score", "level", "health", "controls", "inventory", "mission", "paused" }
    lurek.render.setColor(0.6, 0.6, 0.8, fade * 0.9)
    for _, key in ipairs(labels) do
        lurek.render.print(key .. " → " .. tr(key), col_x, cy, 13)
        cy = cy + 20
    end

    -- ── Dialog buttons ────────────────────────────────────────
    cy = cy + 15
    local dialog_keys = { "dialog_yes", "dialog_no", "confirm", "cancel", "back" }
    local dx = col_x
    for _, key in ipairs(dialog_keys) do
        local label = tr(key)
        local bw = #label * 9 + 20
        lurek.render.setColor(0.2, 0.18, 0.28, fade)
        lurek.render.drawRect("fill", dx, cy, bw, 26, 4)
        lurek.render.setColor(0.4, 0.35, 0.55, fade * 0.7)
        lurek.render.drawRect("line", dx, cy, bw, 26, 4)
        lurek.render.setColor(0.85, 0.8, 0.95, fade)
        lurek.render.print(label, dx + 10, cy + 5, 13)
        dx = dx + bw + 8
    end

    -- ── RTL indicator ─────────────────────────────────────────
    if rtl_mode then
        lurek.render.setColor(1.0, 0.6, 0.2, 0.9)
        lurek.render.print("◀ " .. tr("rtl_hint") .. " ▶", SCREEN_W / 2 - 60, SCREEN_H - 80, 16)
    end

    -- ── Coverage meter ────────────────────────────────────────
    local translated, total = get_coverage()
    local pct = math.floor(translated / total * 100 + 0.5)
    local bar_w = 160
    local bar_h = 14
    local bar_x = SCREEN_W - bar_w - 30
    local bar_y = SCREEN_H - 50

    lurek.render.setColor(0.15, 0.12, 0.2, 0.9)
    lurek.render.drawRect("fill", bar_x - 4, bar_y - 20, bar_w + 8, 46, 6)

    lurek.render.setColor(0.5, 0.5, 0.6, fade * 0.8)
    lurek.render.print(tr("coverage") .. ": " .. translated .. "/" .. total .. " (" .. pct .. "%)", bar_x, bar_y - 16, 12)

    -- Bar background
    lurek.render.setColor(0.2, 0.2, 0.3, 0.8)
    lurek.render.drawRect("fill", bar_x, bar_y, bar_w, bar_h, 3)

    -- Bar fill
    local fill_w = math.floor(bar_w * translated / total)
    if pct == 100 then
        lurek.render.setColor(0.2, 1.0, 0.4, fade)
    else
        lurek.render.setColor(0.9, 0.7, 0.2, fade)
    end
    lurek.render.drawRect("fill", bar_x, bar_y, fill_w, bar_h, 3)

    -- ── Missing key demo ──────────────────────────────────────
    local missing_text = tr("nonexistent_key")
    if missing_text:find("MISSING") then
        lurek.render.setColor(1.0, 0.3, 0.3, fade * 0.9)
    else
        lurek.render.setColor(0.8, 0.8, 0.8, fade)
    end
    lurek.render.print(missing_text, bar_x, bar_y + 20, 11)
end
