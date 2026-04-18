-- ============================================================
-- Match 3 — Swap gems, match 3+, cascade combos, tween falls
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/match3
-- ============================================================

local W, H     = 800, 600
local GRID_SIZE = 8
local CELL      = 56
local GRID_X    = math.floor((W - GRID_SIZE * CELL) / 2)
local GRID_Y    = 70
local NUM_COLORS = 6
local MOVES_MAX  = 30

local GEM_COLORS = {
    {0.95,0.2,0.2,1},   -- red
    {0.2,0.8,0.25,1},   -- green
    {0.2,0.35,0.95,1},  -- blue
    {0.95,0.85,0.1,1},  -- yellow
    {0.8,0.3,0.85,1},   -- purple
    {0.1,0.85,0.85,1},  -- cyan
}

-- Grid: grid[r][c] = { color=1..6, special=nil/"bomb"/"row", fall_y=0 }
local grid       = {}
local sel_r, sel_c = nil, nil
local score      = 0
local combo      = 0
local moves_left = MOVES_MAX
local game_state = "idle"   -- idle | swap | fall | gameover | win

-- Falling animation
local fall_anim  = false
local fall_speed = 300   -- px/s

-- Swap animation
local swap_src, swap_dst = nil, nil
local swap_t, swap_max   = 0, 0.12
local swap_revert        = false

-- Particle systems
local match_sparks = nil
local bomb_burst   = nil
local drop_dust    = nil

-- ── Helpers ───────────────────────────────────────────────
local function new_gem(color)
    return {
        color   = color or math.random(1, NUM_COLORS),
        special = nil,
        py      = 0,   -- pixel y offset for fall animation
    }
end

local function rand_color_no_match(r, c)
    local forbidden = {}
    if c >= 3 and grid[r][c-1] and grid[r][c-2] and
       grid[r][c-1].color == grid[r][c-2].color then
        forbidden[grid[r][c-1].color] = true
    end
    if r >= 3 and grid[r-1] and grid[r-2] and
       grid[r-1][c] and grid[r-2][c] and
       grid[r-1][c].color == grid[r-2][c].color then
        forbidden[grid[r-1][c].color] = true
    end
    local col = math.random(1, NUM_COLORS)
    local tries = 0
    while forbidden[col] and tries < 20 do
        col = math.random(1, NUM_COLORS)
        tries = tries + 1
    end
    return col
end

local function init_grid()
    grid = {}
    for r = 1, GRID_SIZE do
        grid[r] = {}
        for c = 1, GRID_SIZE do
            grid[r][c] = new_gem(rand_color_no_match(r, c))
        end
    end
end

-- Scan and return all match-3+ groups as a set of {r,c}->true
local function find_matches()
    local marked = {}
    -- Horizontal
    for r = 1, GRID_SIZE do
        local run_start, run_col = 1, grid[r][1].color
        for c = 2, GRID_SIZE do
            if grid[r][c].color == run_col then
                if c - run_start >= 2 then  -- 3+ in a row
                    for i = run_start, c do
                        marked[r .. "," .. i] = true
                    end
                end
            else
                run_start = c
                run_col   = grid[r][c].color
            end
        end
    end
    -- Vertical
    for c = 1, GRID_SIZE do
        local run_start, run_col = 1, grid[1][c].color
        for r = 2, GRID_SIZE do
            if grid[r][c].color == run_col then
                if r - run_start >= 2 then
                    for i = run_start, r do
                        marked[i .. "," .. c] = true
                    end
                end
            else
                run_start = r
                run_col   = grid[r][c].color
            end
        end
    end
    return marked
end

local function count_keys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function clear_matches(marked)
    local cleared = count_keys(marked)
    for key in pairs(marked) do
        local r, c = key:match("(%d+),(%d+)")
        r, c = tonumber(r), tonumber(c)
        local g = grid[r][c]
        -- Emit particles at gem position
        local px = GRID_X + (c-1)*CELL + CELL/2
        local py = GRID_Y + (r-1)*CELL + CELL/2
        if g.special == "bomb" then
            if bomb_burst then bomb_burst:emit(px, py, 16) end
        else
            if match_sparks then match_sparks:emit(px, py, 5) end
        end
        grid[r][c] = nil  -- cleared
    end

    -- Handle bomb specials: clear 3×3 around them
    for key in pairs(marked) do
        local r, c = key:match("(%d+),(%d+)")
        r, c = tonumber(r), tonumber(c)
        -- already cleared above
    end

    -- Score: triangular (bigger combos score more)
    local pts = cleared * 10 * (combo + 1)
    score = score + pts

    -- Promote a gem to special if match ≥ 5
    if cleared >= 5 then
        -- Find first non-nil in the group
        for key in pairs(marked) do
            local r, c = key:match("(%d+),(%d+)")
            r, c = tonumber(r), tonumber(c)
            if grid[r] and grid[r][c] == nil then
                grid[r][c] = new_gem(math.random(1, NUM_COLORS))
                grid[r][c].special = "bomb"
                break
            end
        end
    end

    return cleared
end

local function apply_gravity()
    local any_fell = false
    for c = 1, GRID_SIZE do
        local write = GRID_SIZE
        for r = GRID_SIZE, 1, -1 do
            if grid[r][c] then
                if r ~= write then
                    -- Move gem down
                    grid[write][c] = grid[r][c]
                    grid[r][c]     = nil
                    -- Set fall animation offset
                    local fall_rows = write - r
                    grid[write][c].py = -fall_rows * CELL
                    any_fell = true
                end
                write = write - 1
            end
        end
        -- Fill empty cells at top
        while write >= 1 do
            local g = new_gem()
            g.py = -(write + 1) * CELL  -- enter from above
            grid[write][c] = g
            write = write - 1
            any_fell = true
        end
    end
    return any_fell
end

local function swap(r1,c1,r2,c2)
    local tmp = grid[r1][c1]
    grid[r1][c1] = grid[r2][c2]
    grid[r2][c2] = tmp
end

local function adjacent(r1,c1,r2,c2)
    return math.abs(r1-r2) + math.abs(c1-c2) == 1
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("click", "mouse1")
lurek.input.bind("quit",  "escape")

-- ── Init ──────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Match 3 — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.04, 0.10, 1.0)
    math.randomseed(os.time())

    match_sparks = lurek.particles.newSystem({
        maxParticles = 60,
        emitRate = 0, lifetime = {0.2,0.5}, speed = {40,120},
        startColor = {1,1,0.3,1}, endColor = {0.7,0.2,0,0},
        startSize = 4, endSize = 1, spread = math.pi*2
    })
    bomb_burst = lurek.particles.newSystem({
        maxParticles = 40,
        emitRate = 0, lifetime = {0.3,0.7}, speed = {60,200},
        startColor = {1,0.5,0.1,1}, endColor = {0.4,0,0,0},
        startSize = 7, endSize = 1, spread = math.pi*2
    })
    drop_dust = lurek.particles.newSystem({
        maxParticles = 30,
        emitRate = 0, lifetime = {0.15,0.35}, speed = {5,20},
        startColor = {0.5,0.5,0.7,0.5}, endColor = {0.3,0.3,0.5,0},
        startSize = 3, endSize = 1, spread = math.pi*2
    })

    init_grid()
end)

-- ── Process ───────────────────────────────────────────────
lurek.process(function(dt)
    if match_sparks then match_sparks:update(dt) end
    if bomb_burst   then bomb_burst:update(dt)   end
    if drop_dust    then drop_dust:update(dt)    end

    if lurek.input.isActionJustPressed("quit") then lurek.signal.quit() return end
    if game_state == "gameover" or game_state == "win" then return end

    -- Swap animation
    if game_state == "swap" then
        swap_t = swap_t + dt
        if swap_t >= swap_max then
            swap_t = 0
            if swap_revert then
                -- Swap back (invalid move)
                swap(swap_src[1],swap_src[2], swap_dst[1],swap_dst[2])
                game_state = "idle"
                swap_src = nil ; swap_dst = nil
            else
                -- Check for matches after swap
                local matches = find_matches()
                if count_keys(matches) > 0 then
                    combo = combo + 1
                    clear_matches(matches)
                    apply_gravity()
                    game_state = "fall"
                    fall_anim  = true
                    moves_left = moves_left - 1
                    if moves_left <= 0 then game_state = "gameover" end
                else
                    -- No match: revert
                    swap(swap_src[1],swap_src[2], swap_dst[1],swap_dst[2])
                    game_state = "idle"
                end
                swap_src = nil ; swap_dst = nil
            end
        end
        return
    end

    -- Fall animation
    if game_state == "fall" then
        local any_still_falling = false
        for r = 1, GRID_SIZE do
            for c = 1, GRID_SIZE do
                if grid[r] and grid[r][c] and grid[r][c].py < 0 then
                    grid[r][c].py = math.min(0, grid[r][c].py + fall_speed * dt)
                    if grid[r][c].py < 0 then any_still_falling = true end
                end
            end
        end
        if not any_still_falling then
            -- Check for chain matches
            local matches = find_matches()
            if count_keys(matches) > 0 then
                combo = combo + 1
                clear_matches(matches)
                apply_gravity()
            else
                combo      = 0
                game_state = "idle"
                fall_anim  = false
            end
        end
        return
    end

    -- Idle: handle click selection / swap
    if game_state == "idle" then
        local mx, my = lurek.input.getMousePosition()
        local c = math.floor((mx - GRID_X) / CELL) + 1
        local r = math.floor((my - GRID_Y) / CELL) + 1

        if lurek.input.isActionJustPressed("click") then
            if c >= 1 and c <= GRID_SIZE and r >= 1 and r <= GRID_SIZE then
                if sel_r == nil then
                    sel_r, sel_c = r, c
                else
                    if adjacent(sel_r, sel_c, r, c) then
                        -- Do swap
                        swap(sel_r, sel_c, r, c)
                        swap_src    = {sel_r, sel_c}
                        swap_dst    = {r, c}
                        swap_t      = 0
                        swap_revert = false
                        game_state  = "swap"
                    end
                    sel_r, sel_c = nil, nil
                end
            else
                sel_r, sel_c = nil, nil
            end
        end
    end
end)

-- ── Render ────────────────────────────────────────────────
lurek.render(function()
    -- Board background
    lurek.render.drawRect(GRID_X - 6, GRID_Y - 6, GRID_SIZE*CELL + 12, GRID_SIZE*CELL + 12, { color = {0.15,0.12,0.2,1} })

    -- Gems
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            if grid[r] and grid[r][c] then
                local g  = grid[r][c]
                local gx = GRID_X + (c-1)*CELL + 4
                local gy = GRID_Y + (r-1)*CELL + g.py + 4

                -- Selection highlight
                if r == sel_r and c == sel_c then
                    lurek.render.drawRect(gx - 4, gy - 4, CELL, CELL, { color = {1,1,1,0.3} })
                end

                local col = GEM_COLORS[g.color]
                lurek.render.drawRect(gx, gy, CELL - 8, CELL - 8, { color = col })

                -- Special bomb marker
                if g.special == "bomb" then
                    lurek.render.drawCircle(gx + (CELL-8)/2, gy + (CELL-8)/2, 10, { color = {1,0.5,0.1,0.9}, segments = 6 })
                end
            end
        end
    end

    if match_sparks then match_sparks:draw() end
    if bomb_burst   then bomb_burst:draw()   end
    if drop_dust    then drop_dust:draw()    end
end)

-- ── Render UI ─────────────────────────────────────────────
lurek.render_ui(function()
    lurek.render.drawRect(0, 0, W, GRID_Y - 4, { color = {0.08,0.06,0.14,1} })
    lurek.render.drawText("Score: " .. score, 14, 10, { color = {1,1,0.3,1}, size = 18 })
    lurek.render.drawText("Moves: " .. moves_left, 240, 10, { color = {0.4,0.9,0.4,1}, size = 18 })
    if combo > 1 then
        lurek.render.drawText("COMBO x" .. combo .. "!", 420, 10, { color = {1,0.5,0.2,1}, size = 18 })
    end
    lurek.render.drawText("Click gem then adjacent gem to swap", 14, 40, { color = {0.4,0.4,0.4,1}, size = 11 })

    if game_state == "gameover" then
        lurek.render.drawRect(180, 220, 440, 100, { color = {0,0,0,0.88} })
        lurek.render.drawText("GAME OVER", 280, 245, { color = {0.9,0.2,0.2,1}, size = 34 })
        lurek.render.drawText("Final score: " .. score, 300, 295, { color = {1,1,1,1}, size = 18 })
    end
end)
