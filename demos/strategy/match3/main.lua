-- Match-3 Puzzle: Swap adjacent gems, match 3+, cascade combos
-- Click two adjacent gems to swap, score points, special gems

local function lerp(a, b, t) return a + (b - a) * t end

local SCREEN_W, SCREEN_H = 800, 600
local GRID_SIZE = 8
local CELL = 56
local GRID_X = (SCREEN_W - GRID_SIZE * CELL) / 2
local GRID_Y = 60
local NUM_COLORS = 6

local gem_colors = {
    {0.9, 0.2, 0.2},  -- red
    {0.2, 0.7, 0.2},  -- green
    {0.2, 0.3, 0.9},  -- blue
    {0.9, 0.8, 0.1},  -- yellow
    {0.8, 0.3, 0.8},  -- purple
    {0.1, 0.8, 0.8},  -- cyan
}

local grid = {}        -- grid[row][col] = {color, special, anim_y, target_y}
local selected = nil   -- {row, col}
local score = 0
local combo = 0
local moves = 0

-- Game states
local STATE_IDLE = 1
local STATE_SWAP = 2
local STATE_CHECK = 3
local STATE_FALL = 4
local STATE_REFILL = 5
local state = STATE_IDLE
local swap_timer = 0
local swap_a, swap_b = nil, nil
local swap_revert = false

local function new_gem(color, special)
    return {
        color = color or math.random(1, NUM_COLORS),
        special = special or nil, -- "bomb" or "wiper"
        anim_y = 0,
        target_y = 0,
    }
end

local function init_grid()
    for r = 1, GRID_SIZE do
        grid[r] = {}
        for c = 1, GRID_SIZE do
            -- Avoid initial matches
            local color
            repeat
                color = math.random(1, NUM_COLORS)
                local hmatch = (c >= 3 and grid[r][c-1] and grid[r][c-2] and
                    grid[r][c-1].color == color and grid[r][c-2].color == color)
                local vmatch = (r >= 3 and grid[r-1] and grid[r-2] and
                    grid[r-1][c] and grid[r-2][c] and
                    grid[r-1][c].color == color and grid[r-2][c].color == color)
            until not hmatch and not vmatch
            grid[r][c] = new_gem(color)
        end
    end
end

local function find_matches()
    local matched = {}
    for r = 1, GRID_SIZE do matched[r] = {} end

    -- Horizontal
    for r = 1, GRID_SIZE do
        local c = 1
        while c <= GRID_SIZE do
            local run = 1
            while c + run <= GRID_SIZE and grid[r][c] and grid[r][c + run] and
                  grid[r][c].color == grid[r][c + run].color do
                run = run + 1
            end
            if run >= 3 then
                for i = 0, run - 1 do
                    matched[r][c + i] = true
                end
                -- Special gem creation
                if run == 4 and grid[r][c] then
                    grid[r][c].special = "bomb"
                elseif run >= 5 and grid[r][c] then
                    grid[r][c].special = "wiper"
                end
            end
            c = c + run
        end
    end

    -- Vertical
    for c = 1, GRID_SIZE do
        local r = 1
        while r <= GRID_SIZE do
            local run = 1
            while r + run <= GRID_SIZE and grid[r][c] and grid[r + run][c] and
                  grid[r][c].color == grid[r + run][c].color do
                run = run + 1
            end
            if run >= 3 then
                for i = 0, run - 1 do
                    matched[r + i][c] = true
                end
                if run == 4 and grid[r][c] then
                    grid[r][c].special = "bomb"
                elseif run >= 5 and grid[r][c] then
                    grid[r][c].special = "wiper"
                end
            end
            r = r + run
        end
    end

    return matched
end

local function apply_specials(matched)
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            if matched[r][c] and grid[r][c] then
                if grid[r][c].special == "bomb" then
                    -- Clear 3x3
                    for dr = -1, 1 do
                        for dc = -1, 1 do
                            local nr, nc = r + dr, c + dc
                            if nr >= 1 and nr <= GRID_SIZE and nc >= 1 and nc <= GRID_SIZE then
                                matched[nr][nc] = true
                            end
                        end
                    end
                elseif grid[r][c].special == "wiper" then
                    -- Clear all of same color
                    local clr = grid[r][c].color
                    for wr = 1, GRID_SIZE do
                        for wc = 1, GRID_SIZE do
                            if grid[wr][wc] and grid[wr][wc].color == clr then
                                matched[wr][wc] = true
                            end
                        end
                    end
                end
            end
        end
    end
    return matched
end

local function remove_matches(matched)
    local count = 0
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            if matched[r][c] then
                grid[r][c] = nil
                count = count + 1
            end
        end
    end
    return count
end

local function drop_gems()
    local moved = false
    for c = 1, GRID_SIZE do
        for r = GRID_SIZE, 2, -1 do
            if grid[r][c] == nil then
                -- Find gem above
                for above = r - 1, 1, -1 do
                    if grid[above][c] then
                        grid[r][c] = grid[above][c]
                        grid[r][c].anim_y = (above - r) * CELL
                        grid[r][c].target_y = 0
                        grid[above][c] = nil
                        moved = true
                        break
                    end
                end
            end
        end
    end
    return moved
end

local function refill_top()
    for c = 1, GRID_SIZE do
        for r = 1, GRID_SIZE do
            if grid[r][c] == nil then
                grid[r][c] = new_gem()
                grid[r][c].anim_y = -CELL * (GRID_SIZE - r + 2)
                grid[r][c].target_y = 0
            end
        end
    end
end

local function has_valid_moves()
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            -- Try swap right
            if c < GRID_SIZE then
                grid[r][c], grid[r][c+1] = grid[r][c+1], grid[r][c]
                local m = find_matches()
                local found = false
                for mr = 1, GRID_SIZE do
                    for mc = 1, GRID_SIZE do
                        if m[mr][mc] then found = true end
                    end
                end
                grid[r][c], grid[r][c+1] = grid[r][c+1], grid[r][c]
                if found then return true end
            end
            -- Try swap down
            if r < GRID_SIZE then
                grid[r][c], grid[r+1][c] = grid[r+1][c], grid[r][c]
                local m = find_matches()
                local found = false
                for mr = 1, GRID_SIZE do
                    for mc = 1, GRID_SIZE do
                        if m[mr][mc] then found = true end
                    end
                end
                grid[r][c], grid[r+1][c] = grid[r+1][c], grid[r][c]
                if found then return true end
            end
        end
    end
    return false
end

function luna.init()
    init_grid()
end

function luna.process(dt)
    -- Animate gem positions
    local all_settled = true
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            if grid[r][c] then
                local g = grid[r][c]
                if math.abs(g.anim_y - g.target_y) > 0.5 then
                    g.anim_y = lerp(g.anim_y, g.target_y, 12 * dt)
                    all_settled = false
                else
                    g.anim_y = g.target_y
                end
            end
        end
    end

    if state == STATE_SWAP then
        swap_timer = swap_timer + dt
        if swap_timer >= 0.15 then
            -- Actually swap
            local a, b = swap_a, swap_b
            grid[a.r][a.c], grid[b.r][b.c] = grid[b.r][b.c], grid[a.r][a.c]
            if swap_revert then
                state = STATE_IDLE
                swap_revert = false
            else
                state = STATE_CHECK
            end
        end
    elseif state == STATE_CHECK then
        local matched = find_matches()
        matched = apply_specials(matched)
        local count = 0
        for r = 1, GRID_SIZE do
            for c = 1, GRID_SIZE do
                if matched[r][c] then count = count + 1 end
            end
        end
        if count > 0 then
            combo = combo + 1
            score = score + count * 10 * combo
            remove_matches(matched)
            state = STATE_FALL
        else
            if combo == 0 and swap_a then
                -- No match after swap => revert
                swap_revert = true
                swap_timer = 0
                state = STATE_SWAP
            else
                combo = 0
                state = STATE_IDLE
                if not has_valid_moves() then
                    -- Reshuffle
                    init_grid()
                end
            end
        end
    elseif state == STATE_FALL then
        drop_gems()
        refill_top()
        if all_settled then
            state = STATE_CHECK
        end
    end
end

function luna.mousepressed(mx, my, button)
    if button ~= 1 or state ~= STATE_IDLE then return end

    local col = math.floor((mx - GRID_X) / CELL) + 1
    local row = math.floor((my - GRID_Y) / CELL) + 1

    if col < 1 or col > GRID_SIZE or row < 1 or row > GRID_SIZE then
        selected = nil
        return
    end

    if selected == nil then
        selected = { r = row, c = col }
    else
        local dr = math.abs(row - selected.r)
        local dc = math.abs(col - selected.c)
        if (dr == 1 and dc == 0) or (dr == 0 and dc == 1) then
            swap_a = { r = selected.r, c = selected.c }
            swap_b = { r = row, c = col }
            swap_timer = 0
            swap_revert = false
            combo = 0
            moves = moves + 1
            state = STATE_SWAP
        end
        selected = nil
    end
end

function luna.keypressed(key)
    if key == "r" then
        init_grid()
        score = 0
        moves = 0
        combo = 0
        state = STATE_IDLE
        selected = nil
    end
    if key == "escape" then luna.signal.quit() end
end

function luna.render()
    luna.gfx.setBackgroundColor(0.12, 0.1, 0.18)

    -- Title and score
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("MATCH-3", GRID_X, 10, 2)
    luna.gfx.print("Score: " .. score, GRID_X + 250, 15, 1.5)
    luna.gfx.print("Moves: " .. moves, GRID_X + 250, 38)
    if combo > 1 then
        luna.gfx.setColor(1, 0.8, 0.1, 1)
        luna.gfx.print("COMBO x" .. combo, GRID_X + 420, 15, 1.5)
    end

    -- Grid background
    luna.gfx.setColor(0.18, 0.16, 0.22, 1)
    luna.gfx.rectangle("fill", GRID_X - 4, GRID_Y - 4, GRID_SIZE * CELL + 8, GRID_SIZE * CELL + 8)

    -- Gems
    for r = 1, GRID_SIZE do
        for c = 1, GRID_SIZE do
            local g = grid[r][c]
            if g then
                local x = GRID_X + (c - 1) * CELL
                local y = GRID_Y + (r - 1) * CELL + g.anim_y
                local pad = 3

                -- Cell background
                luna.gfx.setColor(0.14, 0.12, 0.18, 1)
                luna.gfx.rectangle("fill", x, y, CELL, CELL)

                -- Gem
                local clr = gem_colors[g.color]
                luna.gfx.setColor(clr[1], clr[2], clr[3], 1)
                luna.gfx.circle("fill", x + CELL / 2, y + CELL / 2, CELL / 2 - pad)

                -- Highlight for specials
                if g.special == "bomb" then
                    luna.gfx.setColor(1, 1, 1, 0.5)
                    luna.gfx.circle("fill", x + CELL / 2, y + CELL / 2, 8)
                elseif g.special == "wiper" then
                    luna.gfx.setColor(1, 1, 1, 0.4)
                    luna.gfx.circle("line", x + CELL / 2, y + CELL / 2, CELL / 2 - pad - 3)
                    luna.gfx.circle("line", x + CELL / 2, y + CELL / 2, CELL / 2 - pad - 6)
                end

                -- Shine
                luna.gfx.setColor(1, 1, 1, 0.15)
                luna.gfx.circle("fill", x + CELL / 2 - 6, y + CELL / 2 - 8, 6)
            end
        end
    end

    -- Selection highlight
    if selected then
        local sx = GRID_X + (selected.c - 1) * CELL
        local sy = GRID_Y + (selected.r - 1) * CELL
        luna.gfx.setColor(1, 1, 1, 0.5)
        luna.gfx.setLineWidth(3)
        luna.gfx.rectangle("line", sx, sy, CELL, CELL)
        luna.gfx.setLineWidth(1)
    end

    -- Controls
    luna.gfx.setColor(0.5, 0.5, 0.5, 1)
    luna.gfx.print("Click gems to swap | R: restart | ESC: quit", GRID_X, SCREEN_H - 28)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), SCREEN_W - 90, 10)
end
