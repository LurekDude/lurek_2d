-- ============================================================================
-- Modding Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/modding_demo/main.lua
-- Run with : cargo run -- content/games/showcase/modding_demo
-- ============================================================================
-- Simulated mod loading and management showcase. Browse, toggle, and preview
-- six built-in mods, then enter a live test scene where active mods affect
-- gameplay in real time.
-- Controls: Up/Down navigate, Enter toggle, T test scene, E export, Esc quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE_TITLE   = "TITLE"
local STATE_BROWSER = "BROWSER"
local STATE_TEST    = "TEST_SCENE"
local current_state = STATE_TITLE

local title_timer     = 0
local title_hold      = 2.5
local export_msg      = nil
local export_timer    = 0

-- Colors
local COL_BG          = { 0.08, 0.08, 0.12 }
local COL_PANEL       = { 0.12, 0.12, 0.18 }
local COL_ACTIVE      = { 0.20, 0.80, 0.35 }
local COL_INACTIVE    = { 0.40, 0.40, 0.45 }
local COL_SELECTED    = { 0.30, 0.55, 0.95 }
local COL_WARNING     = { 0.95, 0.80, 0.20 }
local COL_TEXT        = { 0.92, 0.92, 0.95 }
local COL_DIM         = { 0.55, 0.55, 0.60 }
local COL_TITLE       = { 0.45, 0.70, 1.00 }
local COL_COIN        = { 1.00, 0.85, 0.20 }
local COL_PLAYER      = { 0.30, 0.55, 0.90 }
local COL_ENEMY       = { 0.85, 0.25, 0.20 }
local COL_NIGHT_BG    = { 0.03, 0.03, 0.06 }

-- Layout
local LIST_X, LIST_Y  = 30, 80
local LIST_SPACING     = 50
local PREVIEW_X        = 460
local PREVIEW_Y        = 80
local PREVIEW_W        = 310
local PREVIEW_H        = 400

-- Test scene
local PLAYER_SIZE      = 20
local PLAYER_SPEED     = 160
local COIN_SIZE        = 10
local COIN_COUNT       = 8
local ENEMY_SIZE       = 18
local ENEMY_COUNT      = 3

-- ---------------------------------------------------------------------------
-- Mod definitions
-- ---------------------------------------------------------------------------
local MODS = {
    {
        name        = "Extra Colors",
        author      = "PalettePro",
        version     = "1.2.0",
        description = "Adds 5 new colors to the palette",
        preview     = "New colors: Coral, Teal, Lavender, Gold, Mint",
        enabled     = false,
        colors      = { {1,0.5,0.4}, {0.2,0.8,0.7}, {0.7,0.5,0.9}, {0.9,0.8,0.3}, {0.4,0.9,0.6} },
    },
    {
        name        = "Speed Boost",
        author      = "VelocityMod",
        version     = "2.0.1",
        description = "Doubles player movement speed",
        preview     = "Player speed: 160 → 320 px/s",
        enabled     = false,
        conflicts   = { "Chaos Mode" },
    },
    {
        name        = "Big Enemies",
        author      = "ScaleMaster",
        version     = "1.0.0",
        description = "Increases enemy size 2×",
        preview     = "Enemy size: 18 → 36 px",
        enabled     = false,
    },
    {
        name        = "Night Mode",
        author      = "DarkSide",
        version     = "1.1.3",
        description = "Dark background + reduced visibility",
        preview     = "Background: near-black, visibility radius applied",
        enabled     = false,
    },
    {
        name        = "Score Multiplier",
        author      = "PointsPlus",
        version     = "3.0.0",
        description = "3× score on all pickups",
        preview     = "Score per coin: 10 → 30",
        enabled     = false,
    },
    {
        name        = "Chaos Mode",
        author      = "RandomFX",
        version     = "0.9.5",
        description = "Random effects every 5 seconds",
        preview     = "Effects: speed surge, size flip, color swap, invert",
        enabled     = false,
        conflicts   = { "Speed Boost" },
    },
}

local selected_index = 1

-- ---------------------------------------------------------------------------
-- Test scene state
-- ---------------------------------------------------------------------------
local player   = { x = 400, y = 300, vx = 0, vy = 0 }
local coins    = {}
local enemies  = {}
local score    = 0
local chaos_timer    = 0
local chaos_effect   = nil
local chaos_duration = 3.0
local chaos_elapsed  = 0

-- ---------------------------------------------------------------------------
-- Engine objects
-- ---------------------------------------------------------------------------
---@type LCamera
local camera         = nil
---@type any
local ps_activate    = nil  -- mod activation particles
---@type any
local ps_coin        = nil  -- coin collect particles
local tw_preview     = { alpha = 0.0 }
local tw_test_fade   = { alpha = 0.0 }
local preview_target = 0.0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function lerp(a, b, t) return a + (b - a) * t end

local function is_mod_enabled(name)
    for _, m in ipairs(MODS) do
        if m.name == name and m.enabled then return true end
    end
    return false
end

local function has_conflict(mod)
    if not mod.conflicts then return false end
    for _, cname in ipairs(mod.conflicts) do
        if is_mod_enabled(cname) and mod.enabled then return true end
    end
    return false
end

local function active_mod_count()
    local n = 0
    for _, m in ipairs(MODS) do if m.enabled then n = n + 1 end end
    return n
end

local function get_player_speed()
    local spd = PLAYER_SPEED
    if is_mod_enabled("Speed Boost") then spd = spd * 2 end
    if chaos_effect == "speed_surge" then spd = spd * 1.5 end
    return spd
end

local function get_enemy_size()
    local sz = ENEMY_SIZE
    if is_mod_enabled("Big Enemies") then sz = sz * 2 end
    if chaos_effect == "size_flip" then sz = sz * 0.5 end
    return sz
end

local function get_score_value()
    local base = 10
    if is_mod_enabled("Score Multiplier") then base = base * 3 end
    return base
end

local function get_bg_color()
    if is_mod_enabled("Night Mode") then return COL_NIGHT_BG end
    return COL_BG
end

local function get_palette()
    local pal = { {0.9,0.2,0.3}, {0.2,0.7,0.9}, {0.3,0.9,0.4} }
    if is_mod_enabled("Extra Colors") then
        for _, c in ipairs(MODS[1].colors) do pal[#pal + 1] = c end
    end
    if chaos_effect == "color_swap" then
        -- reverse palette
        local rev = {}
        for i = #pal, 1, -1 do rev[#rev + 1] = pal[i] end
        return rev
    end
    return pal
end

local tween_to

-- ---------------------------------------------------------------------------
-- Test scene setup
-- ---------------------------------------------------------------------------
local function spawn_coins()
    coins = {}
    for i = 1, COIN_COUNT do
        coins[i] = {
            x = 60 + math.random(0, SCREEN_W - 120),
            y = 60 + math.random(0, SCREEN_H - 160),
            alive = true,
        }
    end
end

local function spawn_enemies()
    enemies = {}
    for i = 1, ENEMY_COUNT do
        enemies[i] = {
            x  = 80 + math.random(0, SCREEN_W - 160),
            y  = 80 + math.random(0, SCREEN_H - 200),
            vx = (math.random() > 0.5 and 1 or -1) * (40 + math.random(0, 30)),
            vy = (math.random() > 0.5 and 1 or -1) * (30 + math.random(0, 20)),
        }
    end
end

local function enter_test_scene()
    current_state = STATE_TEST
    player.x, player.y = SCREEN_W * 0.5, SCREEN_H * 0.5
    player.vx, player.vy = 0, 0
    score = 0
    chaos_timer = 0
    chaos_effect = nil
    chaos_elapsed = 0
    spawn_coins()
    spawn_enemies()
    tw_test_fade.alpha = 0.0
    tween_to(tw_test_fade, 0.4, { alpha = 1.0 })
end

local function exit_test_scene()
    tween_to(tw_test_fade, 0.3, { alpha = 0.0 })
    lurek.timer.afterReal(0.35, function() current_state = STATE_BROWSER end)
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
lurek.input.bind("up",     "nav_up")
lurek.input.bind("down",   "nav_down")
lurek.input.bind("return", "toggle")
lurek.input.bind("t",      "test")
lurek.input.bind("e",      "export")
lurek.input.bind("escape", "quit")

-- ---------------------------------------------------------------------------
-- Callbacks
-- ---------------------------------------------------------------------------

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(...)
    local a, b, c, d, e, f, g, h, i = ...
    if type(a) == "string" then
        if type(f) == "table" then
            _sc(f)
        elseif type(f) == "number" then
            _gfx.setColor(f or 1, g or 1, h or 1, i or 1)
        end
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

tween_to = function(...)
    local target, duration, fields, easing = ...
    return lurek.tween.to(target, fields, duration, easing)
end

local function particle_update(ps, dt)
    if ps then ps:update(dt) end
end

local function particle_set_position(ps, x, y)
    if ps then ps:setPosition(x, y) end
end

local function particle_emit(ps, count)
    if ps then ps:emit(count) end
end

function lurek.init()
    lurek.window.setTitle("Modding Demo — Lurek2D")
    lurek.render.setBackgroundColor(COL_BG[1], COL_BG[2], COL_BG[3])

    camera = lurek.camera.new()
    camera:setPosition(0, 0)

    -- Mod activation particle system
    ps_activate = lurek.particle.newSystem({maxParticles=500})
    ps_activate:setEmissionRate(0)
    ps_activate:setParticleLifetime(0.4, 0.8)
    ps_activate:setSpeed(60, 140)
    ps_activate:setSpread(math.pi * 2)
    ps_activate:setColors(
        { COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 1 },
        { COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0 }
    )
    ps_activate:setSizes(4, 1)

    -- Coin collect particle system
    ps_coin = lurek.particle.newSystem({maxParticles=500})
    ps_coin:setEmissionRate(0)
    ps_coin:setParticleLifetime(0.3, 0.6)
    ps_coin:setSpeed(40, 100)
    ps_coin:setSpread(math.pi * 2)
    ps_coin:setColors(
        { COL_COIN[1], COL_COIN[2], COL_COIN[3], 1 },
        { COL_COIN[1], COL_COIN[2], COL_COIN[3], 0 }
    )
    ps_coin:setSizes(3, 1)
end

local function _ready_setup()
    title_timer = 0
    tw_preview.alpha = 0.0
end

function lurek.process(dt)
    -- Title auto-advance
    if current_state == STATE_TITLE then
        title_timer = title_timer + dt
        if title_timer >= title_hold or lurek.input.wasActionPressed("toggle") then
            current_state = STATE_BROWSER
            tween_to(tw_preview, 0.3, { alpha = 1.0 })
        end
        return
    end

    -- Export message decay
    if export_msg then
        export_timer = export_timer - dt
        if export_timer <= 0 then export_msg = nil end
    end

    -- Particle updates
    particle_update(ps_activate, dt)
    particle_update(ps_coin, dt)

    -- -----------------------------------------------------------------------
    -- BROWSER state input
    -- -----------------------------------------------------------------------
    if current_state == STATE_BROWSER then
        if lurek.input.wasActionPressed("nav_up") then
            selected_index = selected_index - 1
            if selected_index < 1 then selected_index = #MODS end
            tw_preview.alpha = 0.0
            tween_to(tw_preview, 0.25, { alpha = 1.0 })
        end
        if lurek.input.wasActionPressed("nav_down") then
            selected_index = selected_index + 1
            if selected_index > #MODS then selected_index = 1 end
            tw_preview.alpha = 0.0
            tween_to(tw_preview, 0.25, { alpha = 1.0 })
        end
        if lurek.input.wasActionPressed("toggle") then
            local mod = MODS[selected_index]
            mod.enabled = not mod.enabled
            -- Activation flash
            local flash_y = LIST_Y + (selected_index - 1) * LIST_SPACING + 12
            particle_set_position(ps_activate, LIST_X + 180, flash_y)
            particle_emit(ps_activate, 25)
        end
        if lurek.input.wasActionPressed("test") then
            enter_test_scene()
        end
        if lurek.input.wasActionPressed("export") then
            local lines = { "=== Mod Config ===" }
            local order = 1
            for i, m in ipairs(MODS) do
                if m.enabled then
                    lines[#lines + 1] = string.format("#%d  %s v%s", order, m.name, m.version)
                    order = order + 1
                end
            end
            if order == 1 then lines[#lines + 1] = "(no mods enabled)" end
            export_msg = table.concat(lines, "\n")
            export_timer = 4.0
        end
    end

    -- -----------------------------------------------------------------------
    -- TEST SCENE state
    -- -----------------------------------------------------------------------
    if current_state == STATE_TEST then
        -- Allow toggling mods during test
        if lurek.input.wasActionPressed("nav_up") then
            selected_index = selected_index - 1
            if selected_index < 1 then selected_index = #MODS end
        end
        if lurek.input.wasActionPressed("nav_down") then
            selected_index = selected_index + 1
            if selected_index > #MODS then selected_index = 1 end
        end
        if lurek.input.wasActionPressed("toggle") then
            local mod = MODS[selected_index]
            mod.enabled = not mod.enabled
            particle_set_position(ps_activate, player.x, player.y)
            particle_emit(ps_activate, 20)
        end
        if lurek.input.wasActionPressed("test") then
            exit_test_scene()
            return
        end

        -- Player movement
        local spd = get_player_speed()
        player.vx, player.vy = 0, 0
        if lurek.input.isActionDown("nav_up")   then player.vy = -spd end
        if lurek.input.isActionDown("nav_down") then player.vy =  spd end
        if lurek.input.isActionDown("left")   then player.vx = -spd end
        if lurek.input.isActionDown("right")  then player.vx =  spd end
        player.x = clamp(player.x + player.vx * dt, PLAYER_SIZE, SCREEN_W - PLAYER_SIZE)
        player.y = clamp(player.y + player.vy * dt, PLAYER_SIZE, SCREEN_H - PLAYER_SIZE)

        -- Apply background color based on mods
        local bg = get_bg_color()
        lurek.render.setBackgroundColor(bg[1], bg[2], bg[3])

        -- Coin collection
        for _, c in ipairs(coins) do
            if c.alive then
                local dx = player.x - c.x
                local dy = player.y - c.y
                if dx * dx + dy * dy < (PLAYER_SIZE + COIN_SIZE) * (PLAYER_SIZE + COIN_SIZE) then
                    c.alive = false
                    score = score + get_score_value()
                    particle_set_position(ps_coin, c.x, c.y)
                    particle_emit(ps_coin, 15)
                end
            end
        end

        -- Respawn coins when all collected
        local all_gone = true
        for _, c in ipairs(coins) do if c.alive then all_gone = false; break end end
        if all_gone then spawn_coins() end

        -- Enemy movement
        local esz = get_enemy_size()
        for _, e in ipairs(enemies) do
            e.x = e.x + e.vx * dt
            e.y = e.y + e.vy * dt
            if e.x < esz or e.x > SCREEN_W - esz then e.vx = -e.vx end
            if e.y < esz or e.y > SCREEN_H - esz then e.vy = -e.vy end
            e.x = clamp(e.x, esz, SCREEN_W - esz)
            e.y = clamp(e.y, esz, SCREEN_H - esz)
        end

        -- Chaos Mode timer
        if is_mod_enabled("Chaos Mode") then
            chaos_timer = chaos_timer + dt
            if chaos_effect then
                chaos_elapsed = chaos_elapsed + dt
                if chaos_elapsed >= chaos_duration then
                    chaos_effect = nil
                    chaos_elapsed = 0
                end
            end
            if chaos_timer >= 5.0 then
                chaos_timer = 0
                local effects = { "speed_surge", "size_flip", "color_swap", "invert" }
                chaos_effect = effects[math.random(1, #effects)]
                chaos_elapsed = 0
            end
        else
            chaos_timer = 0
            chaos_effect = nil
            chaos_elapsed = 0
        end
    end

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
    end
end

-- ---------------------------------------------------------------------------
-- Render: world layer
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state ~= STATE_TEST then return end
    if tw_test_fade.alpha < 0.01 then return end

    local pal = get_palette()
    local esz = get_enemy_size()
    local invert = (chaos_effect == "invert")

    -- Coins
    for _, c in ipairs(coins) do
        if c.alive then
            local col = invert and { 0.2, 0.3, 0.8 } or COL_COIN
            circ("fill", c.x, c.y, COIN_SIZE, col[1], col[2], col[3], tw_test_fade.alpha)
            circ("line", c.x, c.y, COIN_SIZE + 2, col[1] * 0.7, col[2] * 0.7, col[3] * 0.7, tw_test_fade.alpha * 0.5)
        end
    end

    -- Enemies
    for i, e in ipairs(enemies) do
        local ci = ((i - 1) % #pal) + 1
        local col = invert and { 1 - pal[ci][1], 1 - pal[ci][2], 1 - pal[ci][3] } or COL_ENEMY
        rect("fill", e.x - esz * 0.5, e.y - esz * 0.5, esz, esz, col[1], col[2], col[3], tw_test_fade.alpha)
    end

    -- Player
    local pcol = invert and { 0.7, 0.45, 0.1 } or COL_PLAYER
    rect("fill", player.x - PLAYER_SIZE * 0.5, player.y - PLAYER_SIZE * 0.5,
        PLAYER_SIZE, PLAYER_SIZE, pcol[1], pcol[2], pcol[3], tw_test_fade.alpha)
    -- Player direction indicator
    circ("fill", player.x, player.y - PLAYER_SIZE * 0.35,
        3, 1, 1, 1, tw_test_fade.alpha * 0.8)

    -- Night mode visibility circle
    if is_mod_enabled("Night Mode") then
        -- Draw a large dark overlay with a cutout hint
        circ("line", player.x, player.y, 120,
            0.15, 0.15, 0.25, tw_test_fade.alpha * 0.4)
        circ("line", player.x, player.y, 121,
            0.10, 0.10, 0.20, tw_test_fade.alpha * 0.3)
    end

    -- Particles
    lurek.render.draw(ps_activate)
    lurek.render.draw(ps_coin)
end

-- ---------------------------------------------------------------------------
-- Render: UI layer
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    -- -----------------------------------------------------------------------
    -- TITLE screen
    -- -----------------------------------------------------------------------
    if current_state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.abs(math.sin(title_timer * 2.0))
        text_("MODDING DEMO", SCREEN_W * 0.5 - 130, SCREEN_H * 0.35,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], pulse)
        text_("CUSTOMIZE YOUR GAME", SCREEN_W * 0.5 - 110, SCREEN_H * 0.35 + 40,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pulse * 0.7)
        text_("Press ENTER to continue", SCREEN_W * 0.5 - 100, SCREEN_H * 0.65,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.5 + 0.5 * math.sin(title_timer * 3))
        text_(string.format("FPS: %d", fps), SCREEN_W - 80, 10,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)
        return
    end

    -- FPS in top-right
    text_(string.format("FPS: %d", fps), SCREEN_W - 80, 10,
        COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)

    -- -----------------------------------------------------------------------
    -- BROWSER state
    -- -----------------------------------------------------------------------
    if current_state == STATE_BROWSER then
        -- Header
        text_("MOD BROWSER", LIST_X, 20,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        text_(string.format("Active: %d / %d   Load order: list order",
            active_mod_count(), #MODS), LIST_X, 48,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.8)

        -- Mod list (left panel)
        for i, m in ipairs(MODS) do
            local y = LIST_Y + (i - 1) * LIST_SPACING
            local is_sel = (i == selected_index)
            local conflict = has_conflict(m)

            -- Selection highlight
            if is_sel then
                rect("fill", LIST_X - 8, y - 4, 410, LIST_SPACING - 6,
                    COL_SELECTED[1], COL_SELECTED[2], COL_SELECTED[3], 0.15)
            end

            -- Status icon
            local icon, icon_col
            if conflict then
                icon = "!"
                icon_col = COL_WARNING
            elseif m.enabled then
                icon = "+"
                icon_col = COL_ACTIVE
            else
                icon = "-"
                icon_col = COL_INACTIVE
            end
            text_(icon, LIST_X, y,
                icon_col[1], icon_col[2], icon_col[3], 1)

            -- Mod name + version
            local name_col = m.enabled and COL_TEXT or COL_DIM
            text_(string.format("%s v%s", m.name, m.version), LIST_X + 20, y,
                name_col[1], name_col[2], name_col[3], 1)

            -- Author
            text_(string.format("by %s", m.author), LIST_X + 20, y + 16,
                COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)

            -- Conflict warning text
            if conflict then
                text_("CONFLICT", LIST_X + 300, y,
                    COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], 0.9)
            end
        end

        -- Preview panel (right side)
        rect("fill", PREVIEW_X, PREVIEW_Y, PREVIEW_W, PREVIEW_H,
            COL_PANEL[1], COL_PANEL[2], COL_PANEL[3], tw_preview.alpha * 0.9)
        rect("line", PREVIEW_X, PREVIEW_Y, PREVIEW_W, PREVIEW_H,
            COL_SELECTED[1], COL_SELECTED[2], COL_SELECTED[3], tw_preview.alpha * 0.4)

        local sel = MODS[selected_index]
        local pa = tw_preview.alpha

        text_("PREVIEW", PREVIEW_X + 12, PREVIEW_Y + 10,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], pa)
        text_(sel.name, PREVIEW_X + 12, PREVIEW_Y + 40,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa)
        text_(string.format("v%s by %s", sel.version, sel.author),
            PREVIEW_X + 12, PREVIEW_Y + 60,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)

        -- Description
        text_(sel.description, PREVIEW_X + 12, PREVIEW_Y + 95,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa * 0.9)

        -- Preview effect text
        text_("Effect:", PREVIEW_X + 12, PREVIEW_Y + 130,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)
        text_(sel.preview, PREVIEW_X + 12, PREVIEW_Y + 150,
            COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], pa * 0.85)

        -- Status
        local status = sel.enabled and "ENABLED" or "DISABLED"
        local status_col = sel.enabled and COL_ACTIVE or COL_INACTIVE
        text_(string.format("Status: %s", status), PREVIEW_X + 12, PREVIEW_Y + 190,
            status_col[1], status_col[2], status_col[3], pa)

        -- Conflicts
        if sel.conflicts then
            text_("Conflicts with:", PREVIEW_X + 12, PREVIEW_Y + 225,
                COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], pa * 0.8)
            for ci, cname in ipairs(sel.conflicts) do
                text_(string.format("  - %s", cname),
                    PREVIEW_X + 12, PREVIEW_Y + 225 + ci * 18,
                    COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], pa * 0.65)
            end
        end

        -- Load order display
        local load_y = PREVIEW_Y + 300
        text_("Load Order:", PREVIEW_X + 12, load_y,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)
        local order = 1
        for _, m in ipairs(MODS) do
            if m.enabled then
                text_(string.format("%d. %s", order, m.name),
                    PREVIEW_X + 12, load_y + order * 18,
                    COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa * 0.8)
                order = order + 1
            end
        end
        if order == 1 then
            text_("(none)", PREVIEW_X + 12, load_y + 18,
                COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.5)
        end

        -- Footer controls
        text_("Up/Down: Select  Enter: Toggle  T: Test  E: Export  Esc: Quit",
            LIST_X, SCREEN_H - 30,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)
    end

    -- -----------------------------------------------------------------------
    -- TEST SCENE UI overlay
    -- -----------------------------------------------------------------------
    if current_state == STATE_TEST then
        local ta = tw_test_fade.alpha

        -- Score
        text_(string.format("Score: %d", score), 20, 10,
            COL_COIN[1], COL_COIN[2], COL_COIN[3], ta)

        -- Active mods strip
        text_("Active Mods:", 20, 35,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], ta * 0.7)
        local mx = 120
        for _, m in ipairs(MODS) do
            if m.enabled then
                text_(m.name, mx, 35,
                    COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], ta * 0.8)
                mx = mx + #m.name * 8 + 16
            end
        end

        -- Mod selector (compact, bottom)
        for i, m in ipairs(MODS) do
            local bx = 20 + (i - 1) * 125
            local by = SCREEN_H - 28
            local is_sel = (i == selected_index)
            local col = m.enabled and COL_ACTIVE or COL_INACTIVE
            if is_sel then
                rect("fill", bx - 4, by - 3, 118, 22,
                    COL_SELECTED[1], COL_SELECTED[2], COL_SELECTED[3], ta * 0.2)
            end
            text_(m.name, bx, by,
                col[1], col[2], col[3], ta * 0.7)
        end

        -- Chaos effect indicator
        if chaos_effect then
            local remaining = chaos_duration - chaos_elapsed
            text_(string.format("CHAOS: %s (%.1fs)", chaos_effect, remaining),
                SCREEN_W * 0.5 - 80, 10,
                COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], ta * (0.6 + 0.4 * math.sin(chaos_elapsed * 6)))
        end

        -- Controls
        text_("Arrows: Move  Enter: Toggle Mod  T: Exit Test",
            SCREEN_W * 0.5 - 140, SCREEN_H - 50,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], ta * 0.5)
    end

    -- -----------------------------------------------------------------------
    -- Export overlay
    -- -----------------------------------------------------------------------
    if export_msg then
        local ea = clamp(export_timer / 0.5, 0, 1)
        rect("fill", SCREEN_W * 0.5 - 160, SCREEN_H * 0.5 - 80, 320, 160,
            0.05, 0.05, 0.10, ea * 0.92)
        rect("line", SCREEN_W * 0.5 - 160, SCREEN_H * 0.5 - 80, 320, 160,
            COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], ea * 0.6)
        local lines = {}
        for line in export_msg:gmatch("[^\n]+") do lines[#lines + 1] = line end
        for li, line in ipairs(lines) do
            text_(line, SCREEN_W * 0.5 - 140, SCREEN_H * 0.5 - 60 + (li - 1) * 18,
                COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], ea)
        end
    end
end
