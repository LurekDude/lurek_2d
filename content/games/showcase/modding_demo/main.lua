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
local camera         = nil
local ps_activate    = nil  -- mod activation particles
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
    lurek.tween.to(tw_test_fade, 0.4, { alpha = 1.0 })
end

local function exit_test_scene()
    lurek.tween.to(tw_test_fade, 0.3, { alpha = 0.0 })
    lurek.timer.after(0.35, function() current_state = STATE_BROWSER end)
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
lurek.init(function()
    lurek.window.setTitle("Modding Demo — Lurek2D")
    lurek.render.setBackgroundColor(COL_BG[1], COL_BG[2], COL_BG[3])

    camera = lurek.camera.new()
    camera:setPosition(0, 0)

    -- Mod activation particle system
    ps_activate = lurek.particle.new()
    ps_activate:setEmissionRate(0)
    ps_activate:setLifetime(0.4, 0.8)
    ps_activate:setSpeed(60, 140)
    ps_activate:setSpread(math.pi * 2)
    ps_activate:setColors(
        COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 1,
        COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0
    )
    ps_activate:setSizes(4, 1)

    -- Coin collect particle system
    ps_coin = lurek.particle.new()
    ps_coin:setEmissionRate(0)
    ps_coin:setLifetime(0.3, 0.6)
    ps_coin:setSpeed(40, 100)
    ps_coin:setSpread(math.pi * 2)
    ps_coin:setColors(
        COL_COIN[1], COL_COIN[2], COL_COIN[3], 1,
        COL_COIN[1], COL_COIN[2], COL_COIN[3], 0
    )
    ps_coin:setSizes(3, 1)
end)

lurek.ready(function()
    title_timer = 0
    tw_preview.alpha = 0.0
end)

lurek.process(function(dt)
    -- Title auto-advance
    if current_state == STATE_TITLE then
        title_timer = title_timer + dt
        if title_timer >= title_hold or lurek.input.pressed("toggle") then
            current_state = STATE_BROWSER
            lurek.tween.to(tw_preview, 0.3, { alpha = 1.0 })
        end
        return
    end

    -- Export message decay
    if export_msg then
        export_timer = export_timer - dt
        if export_timer <= 0 then export_msg = nil end
    end

    -- Particle updates
    ps_activate:update(dt)
    ps_coin:update(dt)

    -- -----------------------------------------------------------------------
    -- BROWSER state input
    -- -----------------------------------------------------------------------
    if current_state == STATE_BROWSER then
        if lurek.input.pressed("nav_up") then
            selected_index = selected_index - 1
            if selected_index < 1 then selected_index = #MODS end
            tw_preview.alpha = 0.0
            lurek.tween.to(tw_preview, 0.25, { alpha = 1.0 })
        end
        if lurek.input.pressed("nav_down") then
            selected_index = selected_index + 1
            if selected_index > #MODS then selected_index = 1 end
            tw_preview.alpha = 0.0
            lurek.tween.to(tw_preview, 0.25, { alpha = 1.0 })
        end
        if lurek.input.pressed("toggle") then
            local mod = MODS[selected_index]
            mod.enabled = not mod.enabled
            -- Activation flash
            local flash_y = LIST_Y + (selected_index - 1) * LIST_SPACING + 12
            ps_activate:setPosition(LIST_X + 180, flash_y)
            ps_activate:emit(25)
        end
        if lurek.input.pressed("test") then
            enter_test_scene()
        end
        if lurek.input.pressed("export") then
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
        if lurek.input.pressed("nav_up") then
            selected_index = selected_index - 1
            if selected_index < 1 then selected_index = #MODS end
        end
        if lurek.input.pressed("nav_down") then
            selected_index = selected_index + 1
            if selected_index > #MODS then selected_index = 1 end
        end
        if lurek.input.pressed("toggle") then
            local mod = MODS[selected_index]
            mod.enabled = not mod.enabled
            ps_activate:setPosition(player.x, player.y)
            ps_activate:emit(20)
        end
        if lurek.input.pressed("test") then
            exit_test_scene()
            return
        end

        -- Player movement
        local spd = get_player_speed()
        player.vx, player.vy = 0, 0
        if lurek.input.down("nav_up")   then player.vy = -spd end
        if lurek.input.down("nav_down") then player.vy =  spd end
        if lurek.input.isDown("left")   then player.vx = -spd end
        if lurek.input.isDown("right")  then player.vx =  spd end
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
                    ps_coin:setPosition(c.x, c.y)
                    ps_coin:emit(15)
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
    if lurek.input.pressed("quit") then
        lurek.event.quit()
    end
end)

-- ---------------------------------------------------------------------------
-- Render: world layer
-- ---------------------------------------------------------------------------
lurek.render(function()
    if current_state ~= STATE_TEST then return end
    if tw_test_fade.alpha < 0.01 then return end

    local pal = get_palette()
    local esz = get_enemy_size()
    local invert = (chaos_effect == "invert")

    -- Coins
    for _, c in ipairs(coins) do
        if c.alive then
            local col = invert and { 0.2, 0.3, 0.8 } or COL_COIN
            lurek.render.circle("fill", c.x, c.y, COIN_SIZE, col[1], col[2], col[3], tw_test_fade.alpha)
            lurek.render.circle("line", c.x, c.y, COIN_SIZE + 2, col[1] * 0.7, col[2] * 0.7, col[3] * 0.7, tw_test_fade.alpha * 0.5)
        end
    end

    -- Enemies
    for i, e in ipairs(enemies) do
        local ci = ((i - 1) % #pal) + 1
        local col = invert and { 1 - pal[ci][1], 1 - pal[ci][2], 1 - pal[ci][3] } or COL_ENEMY
        lurek.render.rectangle("fill", e.x - esz * 0.5, e.y - esz * 0.5, esz, esz, col[1], col[2], col[3], tw_test_fade.alpha)
    end

    -- Player
    local pcol = invert and { 0.7, 0.45, 0.1 } or COL_PLAYER
    lurek.render.rectangle("fill", player.x - PLAYER_SIZE * 0.5, player.y - PLAYER_SIZE * 0.5,
        PLAYER_SIZE, PLAYER_SIZE, pcol[1], pcol[2], pcol[3], tw_test_fade.alpha)
    -- Player direction indicator
    lurek.render.circle("fill", player.x, player.y - PLAYER_SIZE * 0.35,
        3, 1, 1, 1, tw_test_fade.alpha * 0.8)

    -- Night mode visibility circle
    if is_mod_enabled("Night Mode") then
        -- Draw a large dark overlay with a cutout hint
        lurek.render.circle("line", player.x, player.y, 120,
            0.15, 0.15, 0.25, tw_test_fade.alpha * 0.4)
        lurek.render.circle("line", player.x, player.y, 121,
            0.10, 0.10, 0.20, tw_test_fade.alpha * 0.3)
    end

    -- Particles
    lurek.render.draw(ps_activate)
    lurek.render.draw(ps_coin)
end)

-- ---------------------------------------------------------------------------
-- Render: UI layer
-- ---------------------------------------------------------------------------
lurek.render_ui(function()
    local fps = lurek.timer.getFPS()

    -- -----------------------------------------------------------------------
    -- TITLE screen
    -- -----------------------------------------------------------------------
    if current_state == STATE_TITLE then
        local pulse = 0.7 + 0.3 * math.abs(math.sin(title_timer * 2.0))
        lurek.render.print("MODDING DEMO", SCREEN_W * 0.5 - 130, SCREEN_H * 0.35,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], pulse)
        lurek.render.print("CUSTOMIZE YOUR GAME", SCREEN_W * 0.5 - 110, SCREEN_H * 0.35 + 40,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pulse * 0.7)
        lurek.render.print("Press ENTER to continue", SCREEN_W * 0.5 - 100, SCREEN_H * 0.65,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.5 + 0.5 * math.sin(title_timer * 3))
        lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 10,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)
        return
    end

    -- FPS in top-right
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, 10,
        COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)

    -- -----------------------------------------------------------------------
    -- BROWSER state
    -- -----------------------------------------------------------------------
    if current_state == STATE_BROWSER then
        -- Header
        lurek.render.print("MOD BROWSER", LIST_X, 20,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print(string.format("Active: %d / %d   Load order: list order",
            active_mod_count(), #MODS), LIST_X, 48,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.8)

        -- Mod list (left panel)
        for i, m in ipairs(MODS) do
            local y = LIST_Y + (i - 1) * LIST_SPACING
            local is_sel = (i == selected_index)
            local conflict = has_conflict(m)

            -- Selection highlight
            if is_sel then
                lurek.render.rectangle("fill", LIST_X - 8, y - 4, 410, LIST_SPACING - 6,
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
            lurek.render.print(icon, LIST_X, y,
                icon_col[1], icon_col[2], icon_col[3], 1)

            -- Mod name + version
            local name_col = m.enabled and COL_TEXT or COL_DIM
            lurek.render.print(string.format("%s v%s", m.name, m.version), LIST_X + 20, y,
                name_col[1], name_col[2], name_col[3], 1)

            -- Author
            lurek.render.print(string.format("by %s", m.author), LIST_X + 20, y + 16,
                COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)

            -- Conflict warning text
            if conflict then
                lurek.render.print("CONFLICT", LIST_X + 300, y,
                    COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], 0.9)
            end
        end

        -- Preview panel (right side)
        lurek.render.rectangle("fill", PREVIEW_X, PREVIEW_Y, PREVIEW_W, PREVIEW_H,
            COL_PANEL[1], COL_PANEL[2], COL_PANEL[3], tw_preview.alpha * 0.9)
        lurek.render.rectangle("line", PREVIEW_X, PREVIEW_Y, PREVIEW_W, PREVIEW_H,
            COL_SELECTED[1], COL_SELECTED[2], COL_SELECTED[3], tw_preview.alpha * 0.4)

        local sel = MODS[selected_index]
        local pa = tw_preview.alpha

        lurek.render.print("PREVIEW", PREVIEW_X + 12, PREVIEW_Y + 10,
            COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], pa)
        lurek.render.print(sel.name, PREVIEW_X + 12, PREVIEW_Y + 40,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa)
        lurek.render.print(string.format("v%s by %s", sel.version, sel.author),
            PREVIEW_X + 12, PREVIEW_Y + 60,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)

        -- Description
        lurek.render.print(sel.description, PREVIEW_X + 12, PREVIEW_Y + 95,
            COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa * 0.9)

        -- Preview effect text
        lurek.render.print("Effect:", PREVIEW_X + 12, PREVIEW_Y + 130,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)
        lurek.render.print(sel.preview, PREVIEW_X + 12, PREVIEW_Y + 150,
            COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], pa * 0.85)

        -- Status
        local status = sel.enabled and "ENABLED" or "DISABLED"
        local status_col = sel.enabled and COL_ACTIVE or COL_INACTIVE
        lurek.render.print(string.format("Status: %s", status), PREVIEW_X + 12, PREVIEW_Y + 190,
            status_col[1], status_col[2], status_col[3], pa)

        -- Conflicts
        if sel.conflicts then
            lurek.render.print("Conflicts with:", PREVIEW_X + 12, PREVIEW_Y + 225,
                COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], pa * 0.8)
            for ci, cname in ipairs(sel.conflicts) do
                lurek.render.print(string.format("  - %s", cname),
                    PREVIEW_X + 12, PREVIEW_Y + 225 + ci * 18,
                    COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], pa * 0.65)
            end
        end

        -- Load order display
        local load_y = PREVIEW_Y + 300
        lurek.render.print("Load Order:", PREVIEW_X + 12, load_y,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.7)
        local order = 1
        for _, m in ipairs(MODS) do
            if m.enabled then
                lurek.render.print(string.format("%d. %s", order, m.name),
                    PREVIEW_X + 12, load_y + order * 18,
                    COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], pa * 0.8)
                order = order + 1
            end
        end
        if order == 1 then
            lurek.render.print("(none)", PREVIEW_X + 12, load_y + 18,
                COL_DIM[1], COL_DIM[2], COL_DIM[3], pa * 0.5)
        end

        -- Footer controls
        lurek.render.print("Up/Down: Select  Enter: Toggle  T: Test  E: Export  Esc: Quit",
            LIST_X, SCREEN_H - 30,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)
    end

    -- -----------------------------------------------------------------------
    -- TEST SCENE UI overlay
    -- -----------------------------------------------------------------------
    if current_state == STATE_TEST then
        local ta = tw_test_fade.alpha

        -- Score
        lurek.render.print(string.format("Score: %d", score), 20, 10,
            COL_COIN[1], COL_COIN[2], COL_COIN[3], ta)

        -- Active mods strip
        lurek.render.print("Active Mods:", 20, 35,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], ta * 0.7)
        local mx = 120
        for _, m in ipairs(MODS) do
            if m.enabled then
                lurek.render.print(m.name, mx, 35,
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
                lurek.render.rectangle("fill", bx - 4, by - 3, 118, 22,
                    COL_SELECTED[1], COL_SELECTED[2], COL_SELECTED[3], ta * 0.2)
            end
            lurek.render.print(m.name, bx, by,
                col[1], col[2], col[3], ta * 0.7)
        end

        -- Chaos effect indicator
        if chaos_effect then
            local remaining = chaos_duration - chaos_elapsed
            lurek.render.print(string.format("CHAOS: %s (%.1fs)", chaos_effect, remaining),
                SCREEN_W * 0.5 - 80, 10,
                COL_WARNING[1], COL_WARNING[2], COL_WARNING[3], ta * (0.6 + 0.4 * math.sin(chaos_elapsed * 6)))
        end

        -- Controls
        lurek.render.print("Arrows: Move  Enter: Toggle Mod  T: Exit Test",
            SCREEN_W * 0.5 - 140, SCREEN_H - 50,
            COL_DIM[1], COL_DIM[2], COL_DIM[3], ta * 0.5)
    end

    -- -----------------------------------------------------------------------
    -- Export overlay
    -- -----------------------------------------------------------------------
    if export_msg then
        local ea = clamp(export_timer / 0.5, 0, 1)
        lurek.render.rectangle("fill", SCREEN_W * 0.5 - 160, SCREEN_H * 0.5 - 80, 320, 160,
            0.05, 0.05, 0.10, ea * 0.92)
        lurek.render.rectangle("line", SCREEN_W * 0.5 - 160, SCREEN_H * 0.5 - 80, 320, 160,
            COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], ea * 0.6)
        local lines = {}
        for line in export_msg:gmatch("[^\n]+") do lines[#lines + 1] = line end
        for li, line in ipairs(lines) do
            lurek.render.print(line, SCREEN_W * 0.5 - 140, SCREEN_H * 0.5 - 60 + (li - 1) * 18,
                COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], ea)
        end
    end
end)
