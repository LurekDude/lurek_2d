-- ============================================================================
--  Centipede — Blast a segmented centipede through a mushroom field
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : ../../../../content/demos/arcade/centipede   (original demo)
--  Run with : cargo run -- content/games/arcade/centipede
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A/D or ←/→
--    up/down    : W/S or ↑/↓  (player zone only)
--    fire       : Space
--    restart    : R  (game over only)
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local CELL               = 20
local GRID_COLS          = math.floor(SCREEN_W / CELL)  -- 40
local GRID_ROWS          = math.floor(SCREEN_H / CELL)  -- 30
local PLAYER_ZONE_ROWS   = 4
local PLAYER_ZONE_TOP    = GRID_ROWS - PLAYER_ZONE_ROWS -- row 26

-- Mushroom HP colours: 4=green, 3=yellow, 2=orange, 1=red
local MUSH_COLORS = {
    [4] = {0.2, 0.8, 0.2},
    [3] = {0.9, 0.9, 0.1},
    [2] = {1.0, 0.5, 0.1},
    [1] = {0.9, 0.2, 0.2},
}

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local state = STATE.TITLE

-- ── Mutable game state ───────────────────────────────────────────────────
local mushrooms       = {}   -- mushrooms[row][col] = hp (1-4) or nil
local centipedes      = {}   -- list of chains: {segments={{col,row},...}, dx=1/-1}
local player          = {}   -- {col, row}
local bullet          = nil  -- {x, y} in pixel coords or nil
local spider          = nil  -- {x, y, dx, dy, timer}
local flea            = nil  -- {col, row_f, mushrooms_left}
local scorpion        = nil  -- {x, row, dx}
local score           = 0
local lives           = 3
local wave            = 1
local base_segments   = 12

-- Timers
local spider_timer    = 0
local flea_timer      = 0
local scorpion_timer  = 0

-- Particle systems
local sparks          = nil  -- mushroom poof
local burst           = nil  -- centipede hit
local spider_sparks   = nil  -- spider death

-- Tween: score pop
local score_pop       = { scale = 1 }

-- Title blink
local title_blink     = 0

-- ── Mushroom grid helpers ─────────────────────────────────────────────────
local function init_mushrooms()
    mushrooms = {}
    for r = 1, GRID_ROWS do mushrooms[r] = {} end
    local count = math.random(30, 40)
    for _ = 1, count do
        local r = math.random(2, PLAYER_ZONE_TOP - 1)
        local c = math.random(1, GRID_COLS)
        mushrooms[r][c] = 4
    end
end

local function restore_all_mushrooms()
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            if mushrooms[r][c] then mushrooms[r][c] = 4 end
        end
    end
end

local function count_mushrooms_in_player_zone()
    local n = 0
    for r = PLAYER_ZONE_TOP, GRID_ROWS do
        for c = 1, GRID_COLS do
            if mushrooms[r][c] then n = n + 1 end
        end
    end
    return n
end

-- ── Centipede helpers ─────────────────────────────────────────────────────
local function spawn_centipede(num_segments)
    local segs = {}
    for i = 1, num_segments do
        segs[i] = { col = GRID_COLS - i + 1, row = 1 }
    end
    centipedes = { { segments = segs, dx = -1 } }
end

local function move_centipede_chain(chain, dt_unused)
    -- Each chain moves one cell per logic tick
    local segs = chain.segments
    if #segs == 0 then return end

    local head = segs[1]
    local next_col = head.col + chain.dx
    local hit_edge = next_col < 1 or next_col > GRID_COLS
    local hit_mush = false
    if not hit_edge and head.row >= 1 and head.row <= GRID_ROWS then
        hit_mush = mushrooms[head.row][next_col] ~= nil
    end
    -- Check for poisoned mushroom — drop straight down
    local poisoned = false
    if hit_mush and mushrooms[head.row][next_col] and mushrooms[head.row][next_col] < 0 then
        poisoned = true
    end

    if poisoned then
        -- Drop straight down through poisoned mushrooms
        for i = #segs, 2, -1 do
            segs[i].col = segs[i - 1].col
            segs[i].row = segs[i - 1].row
        end
        head.row = head.row + 1
    elseif hit_edge or hit_mush then
        -- Move all segments: tail follows next
        for i = #segs, 2, -1 do
            segs[i].col = segs[i - 1].col
            segs[i].row = segs[i - 1].row
        end
        head.row = head.row + 1
        chain.dx = -chain.dx
    else
        for i = #segs, 2, -1 do
            segs[i].col = segs[i - 1].col
            segs[i].row = segs[i - 1].row
        end
        head.col = next_col
    end
end

-- ── Spider helpers ────────────────────────────────────────────────────────
local function spawn_spider()
    local side = math.random(1, 2)
    spider = {
        x     = side == 1 and 10 or SCREEN_W - 10,
        y     = math.random(PLAYER_ZONE_TOP * CELL, SCREEN_H - 30),
        dx    = side == 1 and 120 or -120,
        dy    = math.random() > 0.5 and 100 or -100,
        timer = 0,
    }
end

local function update_spider(dt)
    if not spider then return end
    spider.x = spider.x + spider.dx * dt
    spider.y = spider.y + spider.dy * dt
    spider.timer = spider.timer + dt

    -- Bounce vertically in player zone
    if spider.y < PLAYER_ZONE_TOP * CELL then
        spider.y = PLAYER_ZONE_TOP * CELL
        spider.dy = math.abs(spider.dy)
    elseif spider.y > SCREEN_H - 10 then
        spider.y = SCREEN_H - 10
        spider.dy = -math.abs(spider.dy)
    end

    -- Random direction change
    if spider.timer > 0.4 then
        spider.timer = 0
        spider.dy = (math.random() > 0.5 and 1 or -1) * math.random(80, 140)
    end

    -- Eat mushrooms it touches
    local sr = math.floor(spider.y / CELL) + 1
    local sc = math.floor(spider.x / CELL) + 1
    if sr >= 1 and sr <= GRID_ROWS and sc >= 1 and sc <= GRID_COLS then
        if mushrooms[sr][sc] then mushrooms[sr][sc] = nil end
    end

    -- Off screen → remove
    if spider.x < -20 or spider.x > SCREEN_W + 20 then spider = nil end
end

-- ── Flea helpers ──────────────────────────────────────────────────────────
local function spawn_flea()
    flea = {
        col = math.random(3, GRID_COLS - 2),
        row_f = 0,
        speed = 200,
    }
end

local function update_flea(dt)
    if not flea then return end
    flea.row_f = flea.row_f + flea.speed * dt / CELL
    local r = math.floor(flea.row_f) + 1
    -- Leave mushrooms behind (every ~3 rows)
    if r >= 1 and r <= GRID_ROWS and math.random() < 0.3 then
        if not mushrooms[r][flea.col] then
            mushrooms[r][flea.col] = 4
        end
    end
    if flea.row_f * CELL > SCREEN_H then flea = nil end
end

-- ── Scorpion helpers ──────────────────────────────────────────────────────
local function spawn_scorpion()
    local side = math.random(1, 2)
    scorpion = {
        x   = side == 1 and -20 or SCREEN_W + 20,
        row = math.random(3, PLAYER_ZONE_TOP - 2),
        dx  = side == 1 and 100 or -100,
    }
end

local function update_scorpion(dt)
    if not scorpion then return end
    scorpion.x = scorpion.x + scorpion.dx * dt
    -- Poison mushrooms it passes through
    local sc = math.floor(scorpion.x / CELL) + 1
    if sc >= 1 and sc <= GRID_COLS and mushrooms[scorpion.row][sc] then
        -- Negative HP = poisoned (absolute value is remaining HP)
        local hp = mushrooms[scorpion.row][sc]
        if hp > 0 then mushrooms[scorpion.row][sc] = -hp end
    end
    if scorpion.x < -40 or scorpion.x > SCREEN_W + 40 then scorpion = nil end
end

-- ── Scoring helper ────────────────────────────────────────────────────────
local function add_score(pts)
    score = score + pts
    score_pop.scale = 1.5
    lurek.tween.to(score_pop, { scale = 1.0 }, 0.3, "outBack")
end

-- ── New game / new wave ───────────────────────────────────────────────────
local function start_wave()
    spawn_centipede(base_segments + wave - 1)
    spider = nil
    flea   = nil
    scorpion = nil
    spider_timer   = math.random(3, 6)
    flea_timer     = math.random(5, 10)
    scorpion_timer = math.random(8, 15)
    bullet = nil
end

local function new_game()
    score = 0
    lives = 3
    wave  = 1
    player = { col = math.floor(GRID_COLS / 2), row = GRID_ROWS - 1 }
    init_mushrooms()
    start_wave()
    state = STATE.PLAYING
end

local function player_death()
    lives = lives - 1
    restore_all_mushrooms()
    bullet = nil
    player.col = math.floor(GRID_COLS / 2)
    player.row = GRID_ROWS - 1
    if lives <= 0 then
        state = STATE.GAME_OVER
    else
        start_wave()
    end
end

-- ── Centipede move timer ──────────────────────────────────────────────────
local centi_timer     = 0
local centi_interval  = 0.08

-- ── load ──────────────────────────────────────────────────────────────────
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
    lurek.window.setTitle("Centipede — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.06)

    lurek.input.bind("left",    {"a", "left"})
    lurek.input.bind("right",   {"d", "right"})
    lurek.input.bind("up",      {"w", "up"})
    lurek.input.bind("down",    {"s", "down"})
    lurek.input.bind("fire",    {"space"})
    lurek.input.bind("restart", {"r"})
    lurek.input.bind("quit",    {"escape"})

    -- Particle systems
    sparks = lurek.particle.newSystem({
        maxParticles  = 80,
        emissionRate  = 0,
        lifetimeMin   = 0.2,
        lifetimeMax   = 0.5,
        speedMin      = 30,
        speedMax      = 80,
        direction     = 0,
        spread        = 6.28,
        gravityY      = 40,
        sizes         = {3, 1},
        colors        = {0.2, 0.8, 0.2, 1,  0.2, 0.8, 0.2, 0},
    })

    burst = lurek.particle.newSystem({
        maxParticles  = 60,
        emissionRate  = 0,
        lifetimeMin   = 0.15,
        lifetimeMax   = 0.4,
        speedMin      = 50,
        speedMax      = 120,
        direction     = 0,
        spread        = 6.28,
        gravityY      = 0,
        sizes         = {4, 1},
        colors        = {1, 0.4, 0.1, 1,  1, 0.8, 0.2, 0},
    })

    spider_sparks = lurek.particle.newSystem({
        maxParticles  = 50,
        emissionRate  = 0,
        lifetimeMin   = 0.2,
        lifetimeMax   = 0.5,
        speedMin      = 40,
        speedMax      = 100,
        direction     = 0,
        spread        = 6.28,
        gravityY      = 20,
        sizes         = {4, 2},
        colors        = {0.8, 0.2, 0.8, 1,  0.8, 0.2, 0.8, 0},
    })

    math.randomseed(os.time())
end

-- ── Input helpers (called every frame in PLAYING) ─────────────────────────
local move_cooldown = 0
local MOVE_RATE     = 0.06

local function handle_input(dt)
    move_cooldown = move_cooldown - dt

    if move_cooldown <= 0 then
        if lurek.input.isActionDown("left") and player.col > 1 then
            player.col = player.col - 1
            move_cooldown = MOVE_RATE
        elseif lurek.input.isActionDown("right") and player.col < GRID_COLS then
            player.col = player.col + 1
            move_cooldown = MOVE_RATE
        end
        if lurek.input.isActionDown("up") and player.row > PLAYER_ZONE_TOP then
            player.row = player.row - 1
            move_cooldown = MOVE_RATE
        elseif lurek.input.isActionDown("down") and player.row < GRID_ROWS then
            player.row = player.row + 1
            move_cooldown = MOVE_RATE
        end
    end

    if lurek.input.wasActionPressed("fire") and not bullet then
        local px = (player.col - 0.5) * CELL
        local py = (player.row - 1) * CELL
        bullet = { x = px, y = py }
    end
end

-- ── Bullet vs world collision ─────────────────────────────────────────────
local BULLET_SPEED = 600

local function update_bullet(dt)
    if not bullet then return end
    bullet.y = bullet.y - BULLET_SPEED * dt

    if bullet.y < 0 then bullet = nil; return end

    local br = math.floor(bullet.y / CELL) + 1
    local bc = math.floor(bullet.x / CELL) + 1

    -- vs mushroom
    if br >= 1 and br <= GRID_ROWS and bc >= 1 and bc <= GRID_COLS then
        local hp = mushrooms[br][bc]
        if hp then
            local abs_hp = math.abs(hp)
            abs_hp = abs_hp - 1
            if abs_hp <= 0 then
                mushrooms[br][bc] = nil
                sparks:emit(8, (bc - 0.5) * CELL, (br - 0.5) * CELL)
                add_score(1)
            else
                mushrooms[br][bc] = hp > 0 and abs_hp or -abs_hp
            end
            bullet = nil
            return
        end
    end

    -- vs centipede segments
    for ci = #centipedes, 1, -1 do
        local chain = centipedes[ci]
        for si = #chain.segments, 1, -1 do
            local seg = chain.segments[si]
            local sx = (seg.col - 0.5) * CELL
            local sy = (seg.row - 0.5) * CELL
            local dx = bullet.x - sx
            local dy = bullet.y - sy
            if dx * dx + dy * dy < (CELL * 0.6) * (CELL * 0.6) then
                -- Hit! spawn mushroom at segment position
                if seg.row >= 1 and seg.row <= GRID_ROWS and seg.col >= 1 and seg.col <= GRID_COLS then
                    mushrooms[seg.row][seg.col] = 4
                end
                burst:emit(10, sx, sy)
                add_score(10)

                -- Split centipede into two chains
                if si == 1 then
                    -- Head hit: remove first segment
                    table.remove(chain.segments, 1)
                    if #chain.segments == 0 then
                        table.remove(centipedes, ci)
                    end
                elseif si == #chain.segments then
                    -- Tail hit: remove last segment
                    table.remove(chain.segments, si)
                    if #chain.segments == 0 then
                        table.remove(centipedes, ci)
                    end
                else
                    -- Middle hit: split into two chains
                    local new_segs = {}
                    for j = si + 1, #chain.segments do
                        new_segs[#new_segs + 1] = chain.segments[j]
                    end
                    -- Trim original chain
                    for j = #chain.segments, si, -1 do
                        table.remove(chain.segments, j)
                    end
                    -- New chain goes opposite direction
                    if #new_segs > 0 then
                        centipedes[#centipedes + 1] = { segments = new_segs, dx = -chain.dx }
                    end
                    if #chain.segments == 0 then
                        table.remove(centipedes, ci)
                    end
                end

                bullet = nil
                return
            end
        end
    end

    -- vs spider
    if spider then
        local dx = bullet.x - spider.x
        local dy = bullet.y - spider.y
        if dx * dx + dy * dy < 14 * 14 then
            -- Score based on distance to player
            local pdist = math.abs(spider.y - player.row * CELL)
            local pts = pdist < 60 and 900 or (pdist < 120 and 600 or 300)
            spider_sparks:emit(12, spider.x, spider.y)
            add_score(pts)
            spider = nil
            bullet = nil
            return
        end
    end

    -- vs flea
    if flea then
        local fx = (flea.col - 0.5) * CELL
        local fy = flea.row_f * CELL
        local dx = bullet.x - fx
        local dy = bullet.y - fy
        if dx * dx + dy * dy < 12 * 12 then
            burst:emit(8, fx, fy)
            add_score(200)
            flea = nil
            bullet = nil
            return
        end
    end

    -- vs scorpion
    if scorpion then
        local sy = (scorpion.row - 0.5) * CELL
        local dx = bullet.x - scorpion.x
        local dy = bullet.y - sy
        if dx * dx + dy * dy < 14 * 14 then
            burst:emit(10, scorpion.x, sy)
            add_score(1000)
            scorpion = nil
            bullet = nil
            return
        end
    end
end

-- ── Player collision with enemies ─────────────────────────────────────────
local function check_player_death()
    local px = (player.col - 0.5) * CELL
    local py = (player.row - 0.5) * CELL

    -- vs centipede
    for _, chain in ipairs(centipedes) do
        for _, seg in ipairs(chain.segments) do
            local sx = (seg.col - 0.5) * CELL
            local sy = (seg.row - 0.5) * CELL
            if math.abs(px - sx) < CELL * 0.7 and math.abs(py - sy) < CELL * 0.7 then
                return true
            end
        end
    end

    -- vs spider
    if spider then
        if math.abs(px - spider.x) < CELL and math.abs(py - spider.y) < CELL then
            return true
        end
    end

    -- vs flea
    if flea then
        local fx = (flea.col - 0.5) * CELL
        local fy = flea.row_f * CELL
        if math.abs(px - fx) < CELL and math.abs(py - fy) < CELL then
            return true
        end
    end

    return false
end

-- ── update ────────────────────────────────────────────────────────────────
function lurek.process(dt)
    lurek.tween.update(dt)
    sparks:update(dt)
    burst:update(dt)
    spider_sparks:update(dt)

    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("fire") then new_game() end
        return
    end

    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("restart") then new_game() end
        return
    end

    -- PLAYING
    handle_input(dt)
    update_bullet(dt)
    update_spider(dt)
    update_flea(dt)
    update_scorpion(dt)

    -- Move centipede on tick
    centi_timer = centi_timer + dt
    local speed = math.max(0.03, centi_interval - wave * 0.003)
    if centi_timer >= speed then
        centi_timer = centi_timer - speed
        for _, chain in ipairs(centipedes) do
            move_centipede_chain(chain)
        end
    end

    -- Centipede reached bottom — death
    for _, chain in ipairs(centipedes) do
        for _, seg in ipairs(chain.segments) do
            if seg.row > GRID_ROWS then
                player_death()
                return
            end
        end
    end

    -- All centipede segments destroyed → next wave
    local total_segs = 0
    for _, chain in ipairs(centipedes) do
        total_segs = total_segs + #chain.segments
    end
    if total_segs == 0 then
        wave = wave + 1
        start_wave()
    end

    -- Spawn enemies
    spider_timer = spider_timer - dt
    if spider_timer <= 0 and not spider then
        spawn_spider()
        spider_timer = math.random(4, 8)
    end

    flea_timer = flea_timer - dt
    if flea_timer <= 0 and not flea then
        if count_mushrooms_in_player_zone() < 3 then
            spawn_flea()
        end
        flea_timer = math.random(5, 10)
    end

    scorpion_timer = scorpion_timer - dt
    if scorpion_timer <= 0 and not scorpion then
        spawn_scorpion()
        scorpion_timer = math.random(10, 18)
    end

    -- Player death check
    if check_player_death() then
        player_death()
    end
end

-- ── draw helpers ──────────────────────────────────────────────────────────
local function draw_mushrooms()
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local hp = mushrooms[r][c]
            if hp then
                local abs_hp = math.abs(hp)
                local col = MUSH_COLORS[abs_hp] or MUSH_COLORS[1]
                if hp < 0 then
                    -- Poisoned: purple tint
                    lurek.render.setColor(0.6, 0.1, 0.8, 1)
                else
                    lurek.render.setColor(col[1], col[2], col[3], 1)
                end
                local x = (c - 1) * CELL + 2
                local y = (r - 1) * CELL + 2
                rect("fill", x, y, CELL - 4, CELL - 4)
            end
        end
    end
end

local function draw_centipede()
    for _, chain in ipairs(centipedes) do
        for i, seg in ipairs(chain.segments) do
            local cx = (seg.col - 0.5) * CELL
            local cy = (seg.row - 0.5) * CELL
            -- Body
            if i == 1 then
                lurek.render.setColor(0.1, 0.9, 0.3, 1)
            else
                lurek.render.setColor(0.1, 0.7, 0.2, 1)
            end
            circ("fill", cx, cy, CELL * 0.45)
            -- Eye dots on head
            if i == 1 then
                lurek.render.setColor(1, 1, 1, 1)
                local ex = chain.dx > 0 and 3 or -3
                circ("fill", cx + ex - 2, cy - 3, 2)
                circ("fill", cx + ex + 2, cy - 3, 2)
            end
        end
    end
end

local function draw_player()
    local px = (player.col - 0.5) * CELL
    local py = (player.row - 0.5) * CELL
    -- Triangle pointing up
    lurek.render.setColor(0.3, 0.6, 1.0, 1)
    local half = CELL * 0.45
    ln(px, py - half, px - half, py + half)
    ln(px - half, py + half, px + half, py + half)
    ln(px + half, py + half, px, py - half)
    -- Fill body as small rect
    rect("fill", px - 4, py - 2, 8, 10)
end

local function draw_bullet()
    if not bullet then return end
    lurek.render.setColor(1, 1, 0.3, 1)
    rect("fill", bullet.x - 1.5, bullet.y - 4, 3, 8)
end

local function draw_spider()
    if not spider then return end
    -- Diamond shape
    lurek.render.setColor(0.8, 0.2, 0.8, 1)
    local sz = 8
    ln(spider.x, spider.y - sz, spider.x + sz, spider.y)
    ln(spider.x + sz, spider.y, spider.x, spider.y + sz)
    ln(spider.x, spider.y + sz, spider.x - sz, spider.y)
    ln(spider.x - sz, spider.y, spider.x, spider.y - sz)
    lurek.render.setColor(0.9, 0.3, 0.9, 1)
    circ("fill", spider.x, spider.y, 4)
end

local function draw_flea()
    if not flea then return end
    local fx = (flea.col - 0.5) * CELL
    local fy = flea.row_f * CELL
    lurek.render.setColor(1.0, 0.3, 0.3, 1)
    rect("fill", fx - 3, fy - 5, 6, 10)
    lurek.render.setColor(1.0, 0.5, 0.5, 1)
    circ("fill", fx, fy - 5, 3)
end

local function draw_scorpion()
    if not scorpion then return end
    local sy = (scorpion.row - 0.5) * CELL
    lurek.render.setColor(0.9, 0.6, 0.1, 1)
    rect("fill", scorpion.x - 8, sy - 4, 16, 8)
    -- Tail
    local tail_dir = scorpion.dx > 0 and -1 or 1
    ln(scorpion.x + tail_dir * 8, sy, scorpion.x + tail_dir * 14, sy - 6)
    ln(scorpion.x + tail_dir * 14, sy - 6, scorpion.x + tail_dir * 18, sy - 3)
    -- Eyes
    lurek.render.setColor(1, 1, 1, 1)
    local eye_x = scorpion.dx > 0 and 5 or -5
    circ("fill", scorpion.x + eye_x, sy - 2, 2)
end

-- ── render (world space) ──────────────────────────────────────────────────
function lurek.draw()
    if state == STATE.TITLE then
        -- Decorative mushrooms
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                if math.sin(r * 7.3 + c * 3.1) > 0.7 then
                    local g = 0.15 + math.sin(r + c + title_blink) * 0.05
                    lurek.render.setColor(0.1, g, 0.1, 0.5)
                    rect("fill", (c-1)*CELL+4, (r-1)*CELL+4, CELL-8, CELL-8)
                end
            end
        end
        return
    end

    if state == STATE.PLAYING or state == STATE.GAME_OVER then
        -- Player zone boundary line
        lurek.render.setColor(0.15, 0.15, 0.25, 1)
        ln(0, PLAYER_ZONE_TOP * CELL, SCREEN_W, PLAYER_ZONE_TOP * CELL)

        draw_mushrooms()
        draw_centipede()
        draw_player()
        draw_bullet()
        draw_spider()
        draw_flea()
        draw_scorpion()
    end
end

-- ── render_ui (screen space) ──────────────────────────────────────────────
function lurek.draw_ui()
    if state == STATE.TITLE then
        lurek.render.setColor(0.2, 0.9, 0.3, 1)
        text_("CENTIPEDE", SCREEN_W / 2 - 100, 160, 3)

        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        text_("Blast the centipede through a mushroom field", SCREEN_W / 2 - 190, 230, 1)

        local alpha = 0.5 + 0.5 * math.sin(title_blink * 3)
        lurek.render.setColor(1, 1, 0.3, alpha)
        text_("Press SPACE to start", SCREEN_W / 2 - 90, 340, 1.2)

        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        text_("Move: WASD / Arrows   Fire: Space   Quit: Escape", SCREEN_W / 2 - 210, 420, 1)
        return
    end

    -- HUD
    lurek.render.setColor(1, 1, 1, 1)
    text_("SCORE", 10, 4, 1)
    lurek.render.setColor(0.3, 1, 0.3, 1)
    text_(tostring(score), 70, 4, score_pop.scale)

    lurek.render.setColor(1, 1, 1, 1)
    text_("WAVE " .. wave, SCREEN_W / 2 - 30, 4, 1)

    lurek.render.setColor(1, 0.3, 0.3, 1)
    for i = 1, lives do
        local lx = SCREEN_W - 30 * i
        circ("fill", lx, 12, 6)
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    text_(tostring(lurek.timer.getFPS()) .. " FPS", SCREEN_W - 80, SCREEN_H - 18, 1)

    if state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        rect("fill", SCREEN_W / 2 - 160, SCREEN_H / 2 - 60, 320, 120)

        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        text_("GAME OVER", SCREEN_W / 2 - 80, SCREEN_H / 2 - 40, 2)

        lurek.render.setColor(1, 1, 1, 1)
        text_("Final Score: " .. score, SCREEN_W / 2 - 60, SCREEN_H / 2 + 10, 1)

        local alpha = 0.5 + 0.5 * math.sin(title_blink * 3)
        lurek.render.setColor(1, 1, 0.3, alpha)
        text_("Press R to restart", SCREEN_W / 2 - 75, SCREEN_H / 2 + 40, 1)
    end
end

-- ── keypressed ────────────────────────────────────────────────────────────
function lurek._keypressed(key)
    if key == "escape" then lurek.event.quit() end
end
