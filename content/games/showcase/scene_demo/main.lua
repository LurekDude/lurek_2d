-- ============================================================================
-- Scene Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/scene_demo/main.lua
-- Run with : cargo run -- content/games/showcase/scene_demo
-- ============================================================================
-- Complete scene state machine with enter/exit callbacks, three transition
-- effects (fade, slide, dissolve), and a collect-the-coins mini-game.
-- Controls: Up/Down navigate, Enter select, WASD move, T transition, D debug
-- ============================================================================

-- ── constants ─────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local TRANS_FADE    = 1
local TRANS_SLIDE   = 2
local TRANS_DISSOLVE = 3
local TRANS_NAMES   = { "Fade", "Slide", "Dissolve" }
local TRANS_DUR     = 0.5

local COIN_RADIUS   = 10
local COIN_VALUE    = 10
local PLAYER_SPEED  = 200
local PLAYER_SIZE   = 20

-- ── colours ───────────────────────────────────────────────────
local COL_BG_TITLE    = { 0.06, 0.04, 0.14 }
local COL_BG_MENU     = { 0.08, 0.08, 0.12 }
local COL_BG_PLAY     = { 0.05, 0.10, 0.08 }
local COL_BG_SETTINGS = { 0.10, 0.06, 0.12 }
local COL_BG_GAMEOVER = { 0.12, 0.04, 0.04 }
local COL_TITLE       = { 1.0, 0.85, 0.4  }
local COL_TEXT        = { 1.0, 1.0, 1.0    }
local COL_DIM         = { 0.6, 0.6, 0.6    }
local COL_HIGHLIGHT   = { 1.0, 0.9, 0.3    }
local COL_COIN        = { 1.0, 0.85, 0.2   }
local COL_PLAYER      = { 0.3, 0.7, 1.0    }
local COL_DEBUG_BG    = { 0.0, 0.0, 0.0    }

-- ── game state ────────────────────────────────────────────────
local scenes         = {}
local current_scene  = nil
local previous_scene = nil

local transition_type    = TRANS_FADE
local transition_active  = false
local transition_timer   = 0
local transition_phase   = "out"  -- "out" = leaving old, "in" = entering new
local transition_target  = nil
local dissolve_grid      = {}
local dissolve_cols, dissolve_rows = 40, 30

local debug_visible  = false
local scene_history  = {}
local MAX_HISTORY    = 5

-- Settings
local settings = { difficulty = 1, volume = 50 }

-- Gameplay
local player     = { x = 400, y = 300 }
local coins      = {}
local game_score = 0

-- Particles & tweens
local ps_coin      = nil
local ps_transition = nil
local ps_hover     = nil
local menu_scales  = { 1.0, 1.0, 1.0 }

-- Camera
local camera = nil

-- FPS
local fps = 0
local fps_timer = 0
local fps_count = 0

-- Menu / settings selection
local menu_index     = 1
local settings_index = 1

-- Title animation
local title_time = 0
local star_field = {}

-- ── helpers ───────────────────────────────────────────────────
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function lerp(a, b, t) return a + (b - a) * clamp(t, 0, 1) end

local function add_history(from_name, to_name)
    scene_history[#scene_history + 1] = string.format("%s -> %s (%s)",
        from_name or "none", to_name, TRANS_NAMES[transition_type])
    while #scene_history > MAX_HISTORY do
        table.remove(scene_history, 1)
    end
end

local function spawn_coins(count)
    coins = {}
    for i = 1, count do
        coins[i] = {
            x = math.random(60, SCREEN_W - 60),
            y = math.random(60, SCREEN_H - 60),
            alive = true,
            t = math.random() * 6.28,
        }
    end
end

local function build_dissolve_grid()
    dissolve_grid = {}
    local idx = 0
    for r = 0, dissolve_rows - 1 do
        for c = 0, dissolve_cols - 1 do
            idx = idx + 1
            dissolve_grid[idx] = { c = c, r = r, t = math.random() }
        end
    end
    -- Sort by random t so cells reveal in random order
    table.sort(dissolve_grid, function(a, b) return a.t < b.t end)
end

-- ── scene manager ─────────────────────────────────────────────
local function switch_scene(name)
    if transition_active then return end
    if current_scene and scenes[current_scene] and current_scene == name then return end

    transition_target = name
    transition_active = true
    transition_timer  = 0
    transition_phase  = "out"

    if transition_type == TRANS_DISSOLVE then
        build_dissolve_grid()
    end

    add_history(current_scene, name)
end

local function finish_transition()
    if current_scene and scenes[current_scene] and scenes[current_scene].exit then
        scenes[current_scene].exit()
    end
    previous_scene = current_scene
    current_scene  = transition_target

    if scenes[current_scene] and scenes[current_scene].enter then
        scenes[current_scene].enter()
    end

    transition_phase = "in"
    transition_timer = 0
end

-- ── scene: title ──────────────────────────────────────────────
scenes.title = {
    enter = function()
        lurek.render.setBackgroundColor(COL_BG_TITLE[1], COL_BG_TITLE[2], COL_BG_TITLE[3])
        lurek.window.setTitle("Scene Demo — Title")
        title_time = 0
        star_field = {}
        for i = 1, 60 do
            star_field[i] = {
                x = math.random(0, SCREEN_W),
                y = math.random(0, SCREEN_H),
                s = 0.3 + math.random() * 0.7,
                sp = 10 + math.random() * 30,
            }
        end
    end,
    exit = function()
        star_field = {}
    end,
    process = function(dt)
        title_time = title_time + dt
        for i = 1, #star_field do
            local s = star_field[i]
            s.y = s.y + s.sp * dt
            if s.y > SCREEN_H then s.y = 0; s.x = math.random(0, SCREEN_W) end
        end
        if lurek.input.wasActionPressed("confirm") then
            switch_scene("menu")
        end
    end,
    render = function()
        -- Animated star background
        for i = 1, #star_field do
            local s = star_field[i]
            local a = 0.4 + 0.6 * math.sin(title_time * 2 + i)
            lurek.render.setColor(1, 1, 1, a * s.s)
            lurek.render.drawCircle("fill", s.x, s.y, 1 + s.s)
        end
    end,
    render_ui = function()
        -- Pulsing title
        local scale = 1.0 + 0.05 * math.sin(title_time * 3)
        local size = math.floor(36 * scale)
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("SCENE DEMO", SCREEN_W / 2 - 110, 180, size)

        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
        lurek.render.print("A scene management showcase", SCREEN_W / 2 - 120, 240, 16)

        -- Blinking prompt
        local blink = 0.5 + 0.5 * math.sin(title_time * 4)
        lurek.render.setColor(1, 1, 1, blink)
        lurek.render.print("Press Enter", SCREEN_W / 2 - 50, 400, 18)

        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.6)
        lurek.render.print("T: transition type   D: debug", SCREEN_W / 2 - 120, 550, 12)
    end,
}

-- ── scene: menu ───────────────────────────────────────────────
local menu_items = { "Play", "Settings", "Quit" }

scenes.menu = {
    enter = function()
        lurek.render.setBackgroundColor(COL_BG_MENU[1], COL_BG_MENU[2], COL_BG_MENU[3])
        lurek.window.setTitle("Scene Demo — Menu")
        menu_index = 1
        menu_scales = { 1.0, 1.0, 1.0 }
    end,
    exit = function()
        if ps_hover then ps_hover:reset() end
    end,
    process = function(dt)
        local prev = menu_index
        if lurek.input.wasActionPressed("nav_up") then
            menu_index = menu_index - 1
            if menu_index < 1 then menu_index = #menu_items end
        end
        if lurek.input.wasActionPressed("nav_down") then
            menu_index = menu_index + 1
            if menu_index > #menu_items then menu_index = 1 end
        end

        -- Tween highlight on selection change
        if prev ~= menu_index then
            menu_scales[prev] = 1.0
            menu_scales[menu_index] = 1.0
            lurek.tween.to(menu_scales, 0.25, { [menu_index] = 1.3 }, "outBack")
            if ps_hover then
                ps_hover:emit(SCREEN_W / 2, 250 + (menu_index - 1) * 60, 8)
            end
        end

        if lurek.input.wasActionPressed("confirm") then
            if menu_index == 1 then switch_scene("gameplay")
            elseif menu_index == 2 then switch_scene("settings")
            elseif menu_index == 3 then lurek.event.quit()
            end
        end
    end,
    render = function()
        -- Decorative side bars
        lurek.render.setColor(0.15, 0.12, 0.25, 0.4)
        lurek.render.rectangle("fill", 0, 0, 60, SCREEN_H)
        lurek.render.rectangle("fill", SCREEN_W - 60, 0, 60, SCREEN_H)
    end,
    render_ui = function()
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("MAIN MENU", SCREEN_W / 2 - 75, 120, 28)

        for i, item in ipairs(menu_items) do
            local y = 250 + (i - 1) * 60
            local s = menu_scales[i] or 1.0
            local sz = math.floor(20 * s)
            if i == menu_index then
                lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
                lurek.render.print("> " .. item, SCREEN_W / 2 - 60, y, sz)
            else
                lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
                lurek.render.print("  " .. item, SCREEN_W / 2 - 60, y, 20)
            end
        end

        -- Hover glow particles
        if ps_hover then
            lurek.render.setColor(1, 1, 1, 1)
            ps_hover:draw()
        end
    end,
}

-- ── scene: settings ───────────────────────────────────────────
local settings_items = { "Difficulty", "Volume", "Back" }

scenes.settings = {
    enter = function()
        lurek.render.setBackgroundColor(COL_BG_SETTINGS[1], COL_BG_SETTINGS[2], COL_BG_SETTINGS[3])
        lurek.window.setTitle("Scene Demo — Settings")
        settings_index = 1
    end,
    exit = function() end,
    process = function(dt)
        if lurek.input.wasActionPressed("nav_up") then
            settings_index = settings_index - 1
            if settings_index < 1 then settings_index = #settings_items end
        end
        if lurek.input.wasActionPressed("nav_down") then
            settings_index = settings_index + 1
            if settings_index > #settings_items then settings_index = 1 end
        end

        -- Adjust values with left/right
        if settings_index == 1 then
            if lurek.input.wasActionPressed("move_left") then
                settings.difficulty = clamp(settings.difficulty - 1, 1, 3)
            end
            if lurek.input.wasActionPressed("move_right") then
                settings.difficulty = clamp(settings.difficulty + 1, 1, 3)
            end
        elseif settings_index == 2 then
            if lurek.input.isActionDown("move_left") then
                settings.volume = clamp(settings.volume - 60 * dt, 0, 100)
            end
            if lurek.input.isActionDown("move_right") then
                settings.volume = clamp(settings.volume + 60 * dt, 0, 100)
            end
        end

        if lurek.input.wasActionPressed("confirm") then
            if settings_index == 3 then switch_scene("menu") end
        end
    end,
    render = function() end,
    render_ui = function()
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("SETTINGS", SCREEN_W / 2 - 60, 120, 28)

        local labels = {
            "Difficulty: " .. tostring(settings.difficulty) .. "  (A/D)",
            "Volume: " .. tostring(math.floor(settings.volume)) .. "%  (A/D)",
            "Back",
        }
        for i, label in ipairs(labels) do
            local y = 230 + (i - 1) * 50
            if i == settings_index then
                lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
                lurek.render.print("> " .. label, SCREEN_W / 2 - 120, y, 20)
            else
                lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
                lurek.render.print("  " .. label, SCREEN_W / 2 - 120, y, 18)
            end
        end

        -- Difficulty bar
        local bar_x, bar_y = SCREEN_W / 2 + 80, 234
        for d = 1, 3 do
            if d <= settings.difficulty then
                lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
            else
                lurek.render.setColor(0.25, 0.25, 0.25, 1)
            end
            lurek.render.rectangle("fill", bar_x + (d - 1) * 22, bar_y, 18, 14)
        end

        -- Volume bar
        local vol_w = 120
        local vol_fill = vol_w * (settings.volume / 100)
        lurek.render.setColor(0.25, 0.25, 0.25, 1)
        lurek.render.rectangle("fill", bar_x, bar_y + 50, vol_w, 12)
        lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
        lurek.render.rectangle("fill", bar_x, bar_y + 50, vol_fill, 12)
    end,
}

-- ── scene: gameplay ───────────────────────────────────────────
local score_popups = {}

scenes.gameplay = {
    enter = function()
        lurek.render.setBackgroundColor(COL_BG_PLAY[1], COL_BG_PLAY[2], COL_BG_PLAY[3])
        lurek.window.setTitle("Scene Demo — Gameplay")
        player.x = SCREEN_W / 2
        player.y = SCREEN_H / 2
        game_score = 0
        score_popups = {}
        local coin_count = 5 + settings.difficulty * 3
        spawn_coins(coin_count)
    end,
    exit = function()
        coins = {}
        score_popups = {}
    end,
    process = function(dt)
        -- Player movement
        local dx, dy = 0, 0
        if lurek.input.isActionDown("move_up")    then dy = dy - 1 end
        if lurek.input.isActionDown("move_down")   then dy = dy + 1 end
        if lurek.input.isActionDown("move_left")   then dx = dx - 1 end
        if lurek.input.isActionDown("move_right")  then dx = dx + 1 end

        -- Normalise diagonal
        if dx ~= 0 and dy ~= 0 then
            local inv = 1.0 / math.sqrt(2)
            dx, dy = dx * inv, dy * inv
        end

        local spd = PLAYER_SPEED * (1 + (settings.difficulty - 1) * 0.15)
        player.x = clamp(player.x + dx * spd * dt, PLAYER_SIZE, SCREEN_W - PLAYER_SIZE)
        player.y = clamp(player.y + dy * spd * dt, PLAYER_SIZE, SCREEN_H - PLAYER_SIZE)

        -- Coin collection
        for i = #coins, 1, -1 do
            local c = coins[i]
            if c.alive then
                c.t = c.t + dt * 3
                local cdx = player.x - c.x
                local cdy = player.y - c.y
                if cdx * cdx + cdy * cdy < (PLAYER_SIZE + COIN_RADIUS) * (PLAYER_SIZE + COIN_RADIUS) then
                    c.alive = false
                    game_score = game_score + COIN_VALUE * settings.difficulty

                    -- Sparkle particles
                    if ps_coin then ps_coin:emit(c.x, c.y, 15) end

                    -- Score popup with tween
                    local popup = {
                        x = c.x, y = c.y,
                        text = "+" .. tostring(COIN_VALUE * settings.difficulty),
                        life = 1.0, max_life = 1.0,
                    }
                    score_popups[#score_popups + 1] = popup
                    lurek.tween.to(popup, 0.8, { y = c.y - 40 }, "outQuad")
                end
            end
        end

        -- Update score popups
        local new_pops = {}
        for i = 1, #score_popups do
            local p = score_popups[i]
            p.life = p.life - dt
            if p.life > 0 then new_pops[#new_pops + 1] = p end
        end
        score_popups = new_pops

        -- Check all coins collected
        local any_left = false
        for i = 1, #coins do
            if coins[i].alive then any_left = true; break end
        end
        if not any_left then
            switch_scene("gameover")
        end
    end,
    render = function()
        camera:attach()

        -- Ground grid
        lurek.render.setColor(0.1, 0.18, 0.12, 0.3)
        for gx = 0, SCREEN_W, 40 do
            lurek.render.line(gx, 0, gx, SCREEN_H)
        end
        for gy = 0, SCREEN_H, 40 do
            lurek.render.line(0, gy, SCREEN_W, gy)
        end

        -- Coins
        for i = 1, #coins do
            local c = coins[i]
            if c.alive then
                local pulse = 0.8 + 0.2 * math.sin(c.t)
                lurek.render.setColor(COL_COIN[1], COL_COIN[2], COL_COIN[3], pulse)
                lurek.render.drawCircle("fill", c.x, c.y, COIN_RADIUS)
                lurek.render.setColor(1, 1, 0.9, 0.5)
                lurek.render.drawCircle("fill", c.x, c.y, COIN_RADIUS * 0.4)
            end
        end

        -- Player
        lurek.render.setColor(COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3], 1)
        lurek.render.rectangle("fill",
            player.x - PLAYER_SIZE / 2, player.y - PLAYER_SIZE / 2,
            PLAYER_SIZE, PLAYER_SIZE)
        lurek.render.setColor(0.5, 0.85, 1.0, 0.6)
        lurek.render.rectangle("line",
            player.x - PLAYER_SIZE / 2 - 2, player.y - PLAYER_SIZE / 2 - 2,
            PLAYER_SIZE + 4, PLAYER_SIZE + 4)

        -- Coin sparkle particles
        if ps_coin then
            lurek.render.setColor(1, 1, 1, 1)
            ps_coin:draw()
        end

        -- Score popups
        for i = 1, #score_popups do
            local p = score_popups[i]
            local a = clamp(p.life / p.max_life, 0, 1)
            lurek.render.setColor(COL_COIN[1], COL_COIN[2], COL_COIN[3], a)
            lurek.render.print(p.text, p.x - 12, p.y, 16)
        end

        camera:detach()
    end,
    render_ui = function()
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        lurek.render.print("Score: " .. tostring(game_score), 16, 12, 20)

        local alive_count = 0
        for i = 1, #coins do if coins[i].alive then alive_count = alive_count + 1 end end
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
        lurek.render.print("Coins left: " .. tostring(alive_count), 16, 38, 14)
        lurek.render.print("Difficulty: " .. tostring(settings.difficulty), SCREEN_W - 140, 12, 14)
    end,
}

-- ── scene: gameover ───────────────────────────────────────────
local gameover_time = 0

scenes.gameover = {
    enter = function()
        lurek.render.setBackgroundColor(COL_BG_GAMEOVER[1], COL_BG_GAMEOVER[2], COL_BG_GAMEOVER[3])
        lurek.window.setTitle("Scene Demo — Game Over")
        gameover_time = 0
    end,
    exit = function() end,
    process = function(dt)
        gameover_time = gameover_time + dt
        if lurek.input.wasActionPressed("confirm") then
            switch_scene("title")
        end
    end,
    render = function() end,
    render_ui = function()
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 80, 180, 32)

        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        lurek.render.print("Final Score: " .. tostring(game_score), SCREEN_W / 2 - 80, 260, 22)
        lurek.render.print("Difficulty: " .. tostring(settings.difficulty), SCREEN_W / 2 - 80, 295, 16)

        local blink = 0.5 + 0.5 * math.sin(gameover_time * 4)
        lurek.render.setColor(1, 1, 1, blink)
        lurek.render.print("Press Enter to Restart", SCREEN_W / 2 - 100, 380, 18)
    end,
}

-- ── transition rendering ──────────────────────────────────────
local function draw_transition(progress)
    if not transition_active then return end

    if transition_type == TRANS_FADE then
        lurek.render.setColor(0, 0, 0, progress)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    elseif transition_type == TRANS_SLIDE then
        local offset = progress * SCREEN_W
        lurek.render.setColor(0.05, 0.05, 0.08, 1)
        lurek.render.rectangle("fill", -SCREEN_W + offset, 0, SCREEN_W, SCREEN_H)

    elseif transition_type == TRANS_DISSOLVE then
        local cell_w = SCREEN_W / dissolve_cols
        local cell_h = SCREEN_H / dissolve_rows
        local total  = #dissolve_grid
        local reveal = math.floor(total * progress)
        lurek.render.setColor(0, 0, 0, 1)
        for i = 1, reveal do
            local g = dissolve_grid[i]
            lurek.render.rectangle("fill", g.c * cell_w, g.r * cell_h, cell_w + 1, cell_h + 1)
        end
    end

    -- Transition particles in the middle of the effect
    if ps_transition and progress > 0.2 and progress < 0.8 then
        ps_transition:emit(SCREEN_W / 2, SCREEN_H / 2, 3)
        lurek.render.setColor(1, 1, 1, 1)
        ps_transition:draw()
    end
end

-- ── debug panel ───────────────────────────────────────────────
local function draw_debug()
    if not debug_visible then return end

    -- Background
    lurek.render.setColor(COL_DEBUG_BG[1], COL_DEBUG_BG[2], COL_DEBUG_BG[3], 0.75)
    lurek.render.rectangle("fill", SCREEN_W - 260, 0, 260, 160 + #scene_history * 16)

    local x, y = SCREEN_W - 250, 8
    lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
    lurek.render.print("DEBUG", x, y, 14)

    y = y + 20
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
    lurek.render.print("Scene: " .. tostring(current_scene), x, y, 12)
    y = y + 16
    lurek.render.print("Previous: " .. tostring(previous_scene), x, y, 12)
    y = y + 16
    lurek.render.print("Transition: " .. TRANS_NAMES[transition_type], x, y, 12)
    y = y + 16
    lurek.render.print("FPS: " .. tostring(fps), x, y, 12)
    y = y + 16
    lurek.render.print("Difficulty: " .. tostring(settings.difficulty), x, y, 12)
    y = y + 16
    lurek.render.print("Volume: " .. tostring(math.floor(settings.volume)) .. "%", x, y, 12)

    y = y + 22
    lurek.render.setColor(COL_HIGHLIGHT[1], COL_HIGHLIGHT[2], COL_HIGHLIGHT[3], 1)
    lurek.render.print("History:", x, y, 12)
    y = y + 16
    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
    for i = 1, #scene_history do
        lurek.render.print(scene_history[i], x, y, 11)
        y = y + 16
    end
end

-- ── init ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Scene Demo — Lurek2D")
    lurek.render.setBackgroundColor(COL_BG_TITLE[1], COL_BG_TITLE[2], COL_BG_TITLE[3])

    -- Input bindings
    lurek.input.bind("nav_up",     { "up"     })
    lurek.input.bind("nav_down",   { "down"   })
    lurek.input.bind("confirm",    { "return", "kp_enter" })
    lurek.input.bind("move_up",    { "w"      })
    lurek.input.bind("move_down",  { "s"      })
    lurek.input.bind("move_left",  { "a"      })
    lurek.input.bind("move_right", { "d"      })
    lurek.input.bind("cycle_trans", { "t"     })
    lurek.input.bind("toggle_debug", { "d"    })
    lurek.input.bind("quit",       { "escape" })

    -- Camera
    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Coin collect sparkle
    ps_coin = lurek.particle.newSystem(100)
    ps_coin:setEmissionRate(0)
    ps_coin:setParticleLifetime(0.2, 0.5)
    ps_coin:setSpeed(40, 120)
    ps_coin:setDirection(0)
    ps_coin:setSpread(6.28)
    ps_coin:setSizes(3, 1.5, 0)
    ps_coin:setColors(
        1, 0.9, 0.3, 1,
        1, 0.7, 0.1, 0.6,
        1, 0.5, 0.0, 0
    )

    -- Transition particles
    ps_transition = lurek.particle.newSystem(60)
    ps_transition:setEmissionRate(0)
    ps_transition:setParticleLifetime(0.3, 0.6)
    ps_transition:setSpeed(20, 80)
    ps_transition:setDirection(0)
    ps_transition:setSpread(6.28)
    ps_transition:setSizes(2, 1, 0)
    ps_transition:setColors(
        0.8, 0.8, 1.0, 0.8,
        0.4, 0.4, 0.8, 0.3,
        0.2, 0.2, 0.5, 0
    )

    -- Menu hover glow
    ps_hover = lurek.particle.newSystem(40)
    ps_hover:setEmissionRate(0)
    ps_hover:setParticleLifetime(0.3, 0.7)
    ps_hover:setSpeed(10, 40)
    ps_hover:setDirection(0)
    ps_hover:setSpread(6.28)
    ps_hover:setSizes(2, 1)
    ps_hover:setColors(
        1, 0.95, 0.5, 0.8,
        1, 0.8, 0.2, 0
    )

    -- Start at title scene directly (no transition)
    current_scene = "title"
    if scenes.title.enter then scenes.title.enter() end
end

-- ── process ───────────────────────────────────────────────────
function lurek.process(dt)
    -- FPS counter
    fps_count = fps_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Global controls (always active)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if lurek.input.wasActionPressed("cycle_trans") then
        transition_type = transition_type + 1
        if transition_type > 3 then transition_type = 1 end
    end

    if lurek.input.wasActionPressed("toggle_debug") then
        debug_visible = not debug_visible
    end

    -- Update particles
    ps_coin:update(dt)
    ps_transition:update(dt)
    ps_hover:update(dt)
    lurek.tween.update(dt)

    -- Transition logic
    if transition_active then
        transition_timer = transition_timer + dt
        local progress = clamp(transition_timer / (TRANS_DUR / 2), 0, 1)

        if transition_phase == "out" then
            if progress >= 1.0 then
                finish_transition()
            end
        elseif transition_phase == "in" then
            if progress >= 1.0 then
                transition_active = false
                transition_timer  = 0
            end
        end
    end

    -- Scene process
    if not transition_active or transition_phase == "out" then
        -- Let old scene still process during out phase (optional: can freeze instead)
    end
    if current_scene and scenes[current_scene] and scenes[current_scene].process then
        scenes[current_scene].process(dt)
    end
end

-- ── render (world space) ──────────────────────────────────────
function lurek.draw()
    if current_scene and scenes[current_scene] and scenes[current_scene].render then
        scenes[current_scene].render()
    end
end

-- ── render_ui (screen space) ──────────────────────────────────
function lurek.draw_ui()
    if current_scene and scenes[current_scene] and scenes[current_scene].render_ui then
        scenes[current_scene].render_ui()
    end

    -- Transition overlay (always on top of scene UI)
    if transition_active then
        local raw = clamp(transition_timer / (TRANS_DUR / 2), 0, 1)
        local progress
        if transition_phase == "out" then
            progress = raw
        else
            progress = 1.0 - raw
        end
        draw_transition(progress)
    end

    -- Transition type indicator (bottom-left)
    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.7)
    lurek.render.print("Trans: " .. TRANS_NAMES[transition_type] .. " (T)", 12, SCREEN_H - 22, 12)

    -- Debug panel
    draw_debug()
end
