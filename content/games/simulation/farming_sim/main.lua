-- ============================================================================
-- Farming Sim — Lurek2D
-- ============================================================================
-- Category : simulation
-- Source   : content/games/simulation/farming_sim/main.lua
-- Run with : cargo run -- content/games/simulation/farming_sim
-- ============================================================================
-- Grow crops, manage your farm, and reach 200 gold.
-- Controls: WASD move, Space interact, 1-4 tools, W/C/T seeds, M market, Esc quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local GRID_COLS, GRID_ROWS = 12, 8
local PLOT_SIZE = 50
local GRID_X = math.floor((SCREEN_W - GRID_COLS * PLOT_SIZE) / 2)
local GRID_Y = math.floor((SCREEN_H - GRID_ROWS * PLOT_SIZE) / 2) + 20

local STATE = { TITLE = 1, PLAYING = 2, MARKET = 3, VICTORY = 4 }
local current_state = STATE.TITLE

-- Plot states
local PLOT_EMPTY   = 0
local PLOT_TILLED  = 1
local PLOT_PLANTED = 2
local PLOT_GROWING = 3
local PLOT_READY   = 4

-- Crop types
local CROP_WHEAT  = 1
local CROP_CARROT = 2
local CROP_TOMATO = 3

local CROP_NAMES = { [CROP_WHEAT] = "Wheat", [CROP_CARROT] = "Carrot", [CROP_TOMATO] = "Tomato" }
local CROP_GROW_TIME = { [CROP_WHEAT] = 15, [CROP_CARROT] = 10, [CROP_TOMATO] = 20 }
local CROP_SELL = { [CROP_WHEAT] = 5, [CROP_CARROT] = 8, [CROP_TOMATO] = 12 }
local CROP_SEED_COST = { [CROP_WHEAT] = 2, [CROP_CARROT] = 3, [CROP_TOMATO] = 5 }

-- Growth stage thresholds (fraction of grow time)
local STAGE_SPROUT  = 0.25
local STAGE_GROWING = 0.60

-- Tools
local TOOL_HOE     = 1
local TOOL_SEEDS   = 2
local TOOL_WATER   = 3
local TOOL_SICKLE  = 4
local TOOL_NAMES = { "Hoe", "Seeds", "Water Can", "Sickle" }

-- Colors
local COL_EMPTY   = { 0.35, 0.25, 0.15 }
local COL_TILLED  = { 0.45, 0.30, 0.18 }
local COL_SEED    = { 0.50, 0.35, 0.15 }
local COL_SPROUT  = { 0.50, 0.75, 0.30 }
local COL_GROW    = { 0.25, 0.65, 0.20 }
local COL_READY   = { 0.90, 0.80, 0.20 }
local COL_WATER   = { 0.30, 0.50, 0.80 }
local COL_PLAYER  = { 0.20, 0.55, 0.90 }
local COL_GRID    = { 0.15, 0.12, 0.08 }

-- Day/night
local DAY_LENGTH = 60
local RAIN_CHANCE = 0.20

-- Win condition
local GOLD_GOAL = 200

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local grid = {}          -- grid[row][col] = { state, crop, growth, watered, grow_time }
local player = { col = 1, row = 1, tool = TOOL_HOE, seed_type = CROP_WHEAT }
local inventory = {
    seeds = { [CROP_WHEAT] = 5, [CROP_CARROT] = 3, [CROP_TOMATO] = 2 },
    crops = { [CROP_WHEAT] = 0, [CROP_CARROT] = 0, [CROP_TOMATO] = 0 },
}
local gold = 30
local gold_display = 30     -- tweened display value
local day_count = 1
local day_timer = 0
local is_daytime = true
local is_raining = false
local rain_timer = 0
local market_cursor = 1     -- 1..6 for market items

-- Particle systems
---@type LParticleSystem
local ps_harvest = nil
---@type LParticleSystem
local ps_rain    = nil
---@type LParticleSystem
local ps_growth  = nil
---@type LParticleSystem
local ps_plant   = nil

-- Camera
---@type LCamera
local camera = nil

-- ---------------------------------------------------------------------------
-- Grid Initialization
-- ---------------------------------------------------------------------------
local function init_grid()
    grid = {}
    for r = 1, GRID_ROWS do
        grid[r] = {}
        for c = 1, GRID_COLS do
            grid[r][c] = {
                state = PLOT_EMPTY,
                crop = nil,
                growth = 0,
                watered = false,
                grow_time = 0,
            }
        end
    end
end

local function reset_game()
    init_grid()
    player.col = 1
    player.row = 1
    player.tool = TOOL_HOE
    player.seed_type = CROP_WHEAT
    inventory.seeds = { [CROP_WHEAT] = 5, [CROP_CARROT] = 3, [CROP_TOMATO] = 2 }
    inventory.crops = { [CROP_WHEAT] = 0, [CROP_CARROT] = 0, [CROP_TOMATO] = 0 }
    gold = 30
    gold_display = 30
    day_count = 1
    day_timer = 0
    is_daytime = true
    is_raining = false
    rain_timer = 0
    market_cursor = 1
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function plot_screen_pos(col, row)
    return GRID_X + (col - 1) * PLOT_SIZE, GRID_Y + (row - 1) * PLOT_SIZE
end

local function get_growth_color(plot)
    if plot.state == PLOT_PLANTED then return COL_SEED end
    if plot.state == PLOT_GROWING then
        local frac = plot.growth / plot.grow_time
        if frac < STAGE_SPROUT then return COL_SEED
        elseif frac < STAGE_GROWING then return COL_SPROUT
        else return COL_GROW end
    end
    if plot.state == PLOT_READY then return COL_READY end
    return COL_EMPTY
end

local function total_seeds()
    return inventory.seeds[CROP_WHEAT] + inventory.seeds[CROP_CARROT] + inventory.seeds[CROP_TOMATO]
end

local function total_crops()
    return inventory.crops[CROP_WHEAT] + inventory.crops[CROP_CARROT] + inventory.crops[CROP_TOMATO]
end

-- ---------------------------------------------------------------------------
-- Input Setup
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
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
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

function lurek.init()
    lurek.window.setTitle("Farming Sim — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.15, 0.05)

    lurek.input.bind("move_up",    { "w" })
    lurek.input.bind("move_down",  { "s" })
    lurek.input.bind("move_left",  { "a" })
    lurek.input.bind("move_right", { "d" })
    lurek.input.bind("action",     { "space" })
    lurek.input.bind("tool_hoe",    { "1" })
    lurek.input.bind("tool_seeds",  { "2" })
    lurek.input.bind("tool_water",  { "3" })
    lurek.input.bind("tool_sickle", { "4" })
    lurek.input.bind("seed_wheat",  { "q" })
    lurek.input.bind("seed_carrot", { "e" })
    lurek.input.bind("seed_tomato", { "r" })
    lurek.input.bind("market",      { "m" })
    lurek.input.bind("quit",        { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle systems
    ps_harvest = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0, lifetimeMin = 0.3, lifetimeMax = 0.7,
        speedMin = 40, speedMax = 120, direction = -1.57, spread = 1.5,
        gravityY = 80, sizes = { 4, 2, 0 },
        colors = { 1, 0.85, 0.2, 1, 1, 0.6, 0.1, 0 },
    })
    ps_rain = lurek.particle.newSystem({
        maxParticles = 200, emissionRate = 0, lifetimeMin = 0.4, lifetimeMax = 0.8,
        speedMin = 150, speedMax = 250, direction = 1.7, spread = 0.3,
        sizes = { 2, 1 }, colors = { 0.4, 0.6, 1, 0.7, 0.3, 0.5, 0.9, 0 },
    })
    ps_growth = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0, lifetimeMin = 0.4, lifetimeMax = 0.8,
        speedMin = 15, speedMax = 40, direction = -1.57, spread = 1.0,
        sizes = { 3, 1 }, colors = { 0.5, 1, 0.4, 0.8, 0.3, 0.8, 0.2, 0 },
    })
    ps_plant = lurek.particle.newSystem({
        maxParticles = 30, emissionRate = 0, lifetimeMin = 0.2, lifetimeMax = 0.4,
        speedMin = 30, speedMax = 80, direction = -1.57, spread = 3.14,
        sizes = { 3, 2, 0 }, colors = { 0.6, 0.45, 0.2, 1, 0.4, 0.3, 0.15, 0 },
    })

    reset_game()
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Quit
    if lurek.input.wasActionPressed("quit") then
        if current_state == STATE.MARKET then
            current_state = STATE.PLAYING
        else
            lurek.event.quit()
        end
        return
    end

    -- Title
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("action") then
            current_state = STATE.PLAYING
        end
        return
    end

    -- Victory
    if current_state == STATE.VICTORY then
        if lurek.input.wasActionPressed("action") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- Market
    if current_state == STATE.MARKET then
        if lurek.input.wasActionPressed("move_up") then
            market_cursor = math.max(1, market_cursor - 1)
        end
        if lurek.input.wasActionPressed("move_down") then
            market_cursor = math.min(6, market_cursor + 1)
        end
        if lurek.input.wasActionPressed("action") then
            -- Items 1-3: sell crops, 4-6: buy seeds
            if market_cursor == 1 and inventory.crops[CROP_WHEAT] > 0 then
                inventory.crops[CROP_WHEAT] = inventory.crops[CROP_WHEAT] - 1
                gold = gold + CROP_SELL[CROP_WHEAT]
            elseif market_cursor == 2 and inventory.crops[CROP_CARROT] > 0 then
                inventory.crops[CROP_CARROT] = inventory.crops[CROP_CARROT] - 1
                gold = gold + CROP_SELL[CROP_CARROT]
            elseif market_cursor == 3 and inventory.crops[CROP_TOMATO] > 0 then
                inventory.crops[CROP_TOMATO] = inventory.crops[CROP_TOMATO] - 1
                gold = gold + CROP_SELL[CROP_TOMATO]
            elseif market_cursor == 4 and gold >= CROP_SEED_COST[CROP_WHEAT] then
                gold = gold - CROP_SEED_COST[CROP_WHEAT]
                inventory.seeds[CROP_WHEAT] = inventory.seeds[CROP_WHEAT] + 1
            elseif market_cursor == 5 and gold >= CROP_SEED_COST[CROP_CARROT] then
                gold = gold - CROP_SEED_COST[CROP_CARROT]
                inventory.seeds[CROP_CARROT] = inventory.seeds[CROP_CARROT] + 1
            elseif market_cursor == 6 and gold >= CROP_SEED_COST[CROP_TOMATO] then
                gold = gold - CROP_SEED_COST[CROP_TOMATO]
                inventory.seeds[CROP_TOMATO] = inventory.seeds[CROP_TOMATO] + 1
            end
            -- Tween gold display
            lurek.tween.to(gold_display, { [1] = gold }, 0.3)
        end
        -- Update tweens / particles even in market
        lurek.tween.update(dt)
        ps_harvest:update(dt)
        ps_rain:update(dt)
        ps_growth:update(dt)
        ps_plant:update(dt)
        return
    end

    -- ─── PLAYING state ───
    -- Player movement (grid snap)
    if lurek.input.wasActionPressed("move_up") then
        player.row = math.max(1, player.row - 1)
    end
    if lurek.input.wasActionPressed("move_down") then
        player.row = math.min(GRID_ROWS, player.row + 1)
    end
    if lurek.input.wasActionPressed("move_left") then
        player.col = math.max(1, player.col - 1)
    end
    if lurek.input.wasActionPressed("move_right") then
        player.col = math.min(GRID_COLS, player.col + 1)
    end

    -- Tool selection
    if lurek.input.wasActionPressed("tool_hoe")    then player.tool = TOOL_HOE end
    if lurek.input.wasActionPressed("tool_seeds")  then player.tool = TOOL_SEEDS end
    if lurek.input.wasActionPressed("tool_water")  then player.tool = TOOL_WATER end
    if lurek.input.wasActionPressed("tool_sickle") then player.tool = TOOL_SICKLE end

    -- Seed type selection
    if lurek.input.wasActionPressed("seed_wheat")  then player.seed_type = CROP_WHEAT end
    if lurek.input.wasActionPressed("seed_carrot") then player.seed_type = CROP_CARROT end
    if lurek.input.wasActionPressed("seed_tomato") then player.seed_type = CROP_TOMATO end

    -- Open market
    if lurek.input.wasActionPressed("market") then
        current_state = STATE.MARKET
        market_cursor = 1
        return
    end

    -- Action (Space) — depends on tool
    if lurek.input.wasActionPressed("action") then
        local plot = grid[player.row][player.col]
        local px, py = plot_screen_pos(player.col, player.row)
        local cx, cy = px + PLOT_SIZE * 0.5, py + PLOT_SIZE * 0.5

        if player.tool == TOOL_HOE and plot.state == PLOT_EMPTY then
            plot.state = PLOT_TILLED
            ps_plant:moveTo(cx, cy)
            ps_plant:emit(8)
        elseif player.tool == TOOL_SEEDS and plot.state == PLOT_TILLED then
            local st = player.seed_type
            if inventory.seeds[st] > 0 then
                inventory.seeds[st] = inventory.seeds[st] - 1
                plot.state = PLOT_PLANTED
                plot.crop = st
                plot.growth = 0
                plot.grow_time = CROP_GROW_TIME[st]
                plot.watered = false
                ps_plant:moveTo(cx, cy)
                ps_plant:emit(12)
            end
        elseif player.tool == TOOL_WATER and (plot.state == PLOT_PLANTED or plot.state == PLOT_GROWING) then
            if not plot.watered then
                plot.watered = true
                plot.grow_time = CROP_GROW_TIME[plot.crop] * 0.5
                ps_growth:moveTo(cx, cy)
                ps_growth:emit(6)
            end
        elseif player.tool == TOOL_SICKLE and plot.state == PLOT_READY then
            local crop = plot.crop
            inventory.crops[crop] = inventory.crops[crop] + 1
            plot.state = PLOT_EMPTY
            plot.crop = nil
            plot.growth = 0
            plot.watered = false
            ps_harvest:moveTo(cx, cy)
            ps_harvest:emit(20)
        end
    end

    -- Day/night cycle
    day_timer = day_timer + dt
    if day_timer >= DAY_LENGTH then
        day_timer = day_timer - DAY_LENGTH
        is_daytime = not is_daytime
        if is_daytime then
            day_count = day_count + 1
            -- Weather roll at dawn
            is_raining = math.random() < RAIN_CHANCE
            if is_raining then rain_timer = DAY_LENGTH * 0.5 end
        end
    end

    -- Rain
    if is_raining then
        rain_timer = rain_timer - dt
        -- Emit rain particles from top
        ps_rain:moveTo(math.random(0, SCREEN_W), 0)
        ps_rain:emit(2)
        if rain_timer <= 0 then
            is_raining = false
            -- Water all planted/growing plots
            for r = 1, GRID_ROWS do
                for c = 1, GRID_COLS do
                    local p = grid[r][c]
                    if (p.state == PLOT_PLANTED or p.state == PLOT_GROWING) and not p.watered then
                        p.watered = true
                        p.grow_time = CROP_GROW_TIME[p.crop] * 0.5
                    end
                end
            end
        end
    end

    -- Crop growth (only during daytime)
    if is_daytime then
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                local p = grid[r][c]
                if p.state == PLOT_PLANTED or p.state == PLOT_GROWING then
                    p.growth = p.growth + dt
                    if p.growth >= p.grow_time * STAGE_SPROUT and p.state == PLOT_PLANTED then
                        p.state = PLOT_GROWING
                    end
                    if p.growth >= p.grow_time then
                        p.state = PLOT_READY
                        local px, py = plot_screen_pos(c, r)
                        ps_growth:moveTo(px + PLOT_SIZE * 0.5, py + PLOT_SIZE * 0.5)
                        ps_growth:emit(8)
                    end
                end
            end
        end
    end

    -- Tween gold display toward actual gold
    local diff = gold - gold_display
    if math.abs(diff) > 0.5 then
        gold_display = gold_display + diff * dt * 5
    else
        gold_display = gold
    end

    -- Victory check
    if gold >= GOLD_GOAL then
        current_state = STATE.VICTORY
    end

    -- Update systems
    lurek.tween.update(dt)
    ps_harvest:update(dt)
    ps_rain:update(dt)
    ps_growth:update(dt)
    ps_plant:update(dt)
end

-- ---------------------------------------------------------------------------
-- Render (world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    -- Title screen
    if current_state == STATE.TITLE then
        text_("FARMING SIM", 200, 180, { size = 48, color = { 0.9, 0.80, 0.20, 1 } })
        text_("GROW YOUR FORTUNE", 240, 250, { size = 22, color = { 0.6, 0.75, 0.35, 1 } })
        text_("Press SPACE to start", 280, 350, { size = 16, color = { 0.6, 0.6, 0.6, 1 } })
        text_("WASD move  |  1-4 tools  |  SPACE interact  |  M market", 120, 420, { size = 12, color = { 0.45, 0.45, 0.45, 1 } })
        return
    end

    -- Victory screen
    if current_state == STATE.VICTORY then
        text_("VICTORY!", 260, 180, { size = 48, color = { 1, 0.85, 0.15, 1 } })
        local msg = string.format("You earned %d gold in %d days!", gold, day_count)
        text_(msg, 210, 260, { size = 20, color = { 0.85, 0.85, 0.85, 1 } })
        text_("Press SPACE to play again", 260, 350, { size = 16, color = { 0.6, 0.6, 0.6, 1 } })
        return
    end

    -- Day/night tint
    local night_alpha = 0
    if not is_daytime then
        night_alpha = 0.25
    end

    -- Draw farm grid
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local plot = grid[r][c]
            local px, py = plot_screen_pos(c, r)

            -- Plot background
            local bg = COL_EMPTY
            if plot.state == PLOT_TILLED then bg = COL_TILLED end
            rect(px, py, PLOT_SIZE, PLOT_SIZE, { color = { bg[1], bg[2], bg[3], 1 } })

            -- Crop
            if plot.state >= PLOT_PLANTED then
                local crop_col = get_growth_color(plot)
                local crop_size = 12 + 14 * math.min(1, plot.growth / (plot.grow_time + 0.01))
                local cx = px + PLOT_SIZE * 0.5
                local cy = py + PLOT_SIZE * 0.5
                circ(cx, cy, crop_size * 0.5, { color = { crop_col[1], crop_col[2], crop_col[3], 1 } })

                -- Watered indicator
                if plot.watered then
                    circ(cx, cy, crop_size * 0.5 + 3, { color = { COL_WATER[1], COL_WATER[2], COL_WATER[3], 0.3 }, mode = "line" })
                end
            end

            -- Grid line
            rect(px, py, PLOT_SIZE, PLOT_SIZE, { color = { COL_GRID[1], COL_GRID[2], COL_GRID[3], 0.4 }, mode = "line" })
        end
    end

    -- Player
    local player_px, player_py = plot_screen_pos(player.col, player.row)
    local pad = 6
    rect(player_px + pad, player_py + pad, PLOT_SIZE - pad * 2, PLOT_SIZE - pad * 2,
        { color = { COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3], 0.7 }, mode = "line" })
    rect(player_px + pad + 2, player_py + pad + 2, PLOT_SIZE - pad * 2 - 4, PLOT_SIZE - pad * 2 - 4,
        { color = { COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3], 0.35 } })

    -- Particles (world-space)
    ps_harvest:render()
    ps_rain:render()
    ps_growth:render()
    ps_plant:render()

    -- Night overlay
    if night_alpha > 0 then
        rect(0, 0, SCREEN_W, SCREEN_H, { color = { 0.02, 0.02, 0.12, night_alpha } })
    end

    -- Rain overlay
    if is_raining then
        rect(0, 0, SCREEN_W, SCREEN_H, { color = { 0.15, 0.20, 0.35, 0.12 } })
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (HUD overlay)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state == STATE.TITLE or current_state == STATE.VICTORY then return end

    local W = SCREEN_W

    -- ─── Market overlay ───
    if current_state == STATE.MARKET then
        -- Dim background
        rect(0, 0, W, SCREEN_H, { color = { 0, 0, 0, 0.6 } })

        text_("MARKET", 330, 60, { size = 36, color = { 0.95, 0.85, 0.2, 1 } })
        text_(string.format("Gold: %d", gold), 340, 110, { size = 18, color = { 1, 0.9, 0.3, 1 } })

        local items = {
            { label = string.format("Sell Wheat   (%d) → +%dg", inventory.crops[CROP_WHEAT], CROP_SELL[CROP_WHEAT]),   ok = inventory.crops[CROP_WHEAT] > 0 },
            { label = string.format("Sell Carrot  (%d) → +%dg", inventory.crops[CROP_CARROT], CROP_SELL[CROP_CARROT]), ok = inventory.crops[CROP_CARROT] > 0 },
            { label = string.format("Sell Tomato  (%d) → +%dg", inventory.crops[CROP_TOMATO], CROP_SELL[CROP_TOMATO]), ok = inventory.crops[CROP_TOMATO] > 0 },
            { label = string.format("Buy Wheat Seed   -%dg", CROP_SEED_COST[CROP_WHEAT]),  ok = gold >= CROP_SEED_COST[CROP_WHEAT] },
            { label = string.format("Buy Carrot Seed  -%dg", CROP_SEED_COST[CROP_CARROT]), ok = gold >= CROP_SEED_COST[CROP_CARROT] },
            { label = string.format("Buy Tomato Seed  -%dg", CROP_SEED_COST[CROP_TOMATO]), ok = gold >= CROP_SEED_COST[CROP_TOMATO] },
        }

        for i, item in ipairs(items) do
            local y = 155 + (i - 1) * 40
            local is_sel = (i == market_cursor)
            local col = item.ok and { 0.85, 0.85, 0.85, 1 } or { 0.4, 0.4, 0.4, 1 }
            if is_sel then col = { 1, 1, 0.6, 1 } end
            local prefix = is_sel and "> " or "  "
            text_(prefix .. item.label, 220, y, { size = 16, color = col })
        end

        text_("W/S navigate  |  SPACE select  |  ESC close", 210, 420, { size = 12, color = { 0.5, 0.5, 0.5, 1 } })
        return
    end

    -- ─── Playing HUD ───
    local hud_h = 28
    rect(0, 0, W, hud_h, { color = { 0, 0, 0, 0.7 } })

    -- Gold
    local gold_str = string.format("Gold: %d/%d", math.floor(gold_display), GOLD_GOAL)
    text_(gold_str, 10, 6, { size = 13, color = { 1, 0.9, 0.3, 1 } })

    -- Day/Time
    local time_frac = day_timer / DAY_LENGTH
    local time_str = string.format("Day %d  %s", day_count, is_daytime and "DAY" or "NIGHT")
    text_(time_str, 170, 6, { size = 13, color = is_daytime and { 1, 0.95, 0.6, 1 } or { 0.5, 0.5, 0.8, 1 } })

    -- Weather
    if is_raining then
        text_("RAIN", 310, 6, { size = 13, color = { 0.4, 0.65, 1, 1 } })
    end

    -- Tool
    local tool_str = string.format("Tool: %s [%d]", TOOL_NAMES[player.tool], player.tool)
    text_(tool_str, 380, 6, { size = 13, color = { 0.8, 0.8, 0.8, 1 } })

    -- Seed type (when seed tool active)
    if player.tool == TOOL_SEEDS then
        local seed_str = string.format("Seed: %s (%d)", CROP_NAMES[player.seed_type], inventory.seeds[player.seed_type])
        text_(seed_str, 540, 6, { size = 13, color = { 0.7, 0.9, 0.5, 1 } })
    end

    -- FPS
    local fps = lurek.timer.getFPS()
    text_(string.format("FPS: %d", fps), W - 75, 6, { size = 12, color = { 0.5, 0.5, 0.5, 1 } })

    -- Bottom bar — inventory
    local bot_y = SCREEN_H - 26
    rect(0, bot_y, W, 26, { color = { 0, 0, 0, 0.7 } })

    local inv_str = string.format(
        "Seeds: W%d C%d T%d  |  Crops: W%d C%d T%d  |  M=Market",
        inventory.seeds[CROP_WHEAT], inventory.seeds[CROP_CARROT], inventory.seeds[CROP_TOMATO],
        inventory.crops[CROP_WHEAT], inventory.crops[CROP_CARROT], inventory.crops[CROP_TOMATO]
    )
    text_(inv_str, 10, bot_y + 5, { size = 12, color = { 0.75, 0.75, 0.75, 1 } })

    -- Controls hint
    text_("Q=Wheat E=Carrot R=Tomato", W - 210, bot_y + 5, { size = 12, color = { 0.5, 0.5, 0.5, 1 } })
end
