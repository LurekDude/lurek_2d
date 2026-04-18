-- ============================================================================
-- Cannon Fodder — Lurek2D
-- ============================================================================
-- Category : action
-- Source   : content/games/action/cannon_fodder/main.lua
-- Run with : cargo run -- content/games/action/cannon_fodder
-- ============================================================================
-- Top-down military squad action inspired by Cannon Fodder (Amiga).
-- Lead a squad of soldiers, click-to-move, auto-fire at enemies in range.
-- Controls: LMB click-to-move squad, RMB fire order, Escape quit
-- ============================================================================

local W, H = 800, 600

-- ── Constants ─────────────────────────────────────────────────────────────
local SOLDIER_R    = 8
local ENEMY_R      = 9
local BULLET_R     = 3
local SHOOT_RANGE  = 160
local SHOOT_CD     = 0.45       -- seconds between shots
local BULLET_SPEED = 300
local MOVE_SPEED   = 90
local ENEMY_SPEED  = 55

-- ── Map tiles (simple hand-authored) ──────────────────────────────────────
local TILE        = 40
local MAP_COLS    = 20
local MAP_ROWS    = 15
-- 0 = grass, 1 = wall/tree, 2 = bunker (cover)
local MAP_DATA = {
    "11111111111111111111",
    "10000000001000000001",
    "10011000001001100001",
    "10010000001000100001",
    "10000000000000000001",
    "10000110000011000001",
    "10000000000000000001",
    "10001000000000100001",
    "10001100000011000001",
    "10000000000000000001",
    "10000001111000000001",
    "10000001001000000001",
    "10001001001001000001",
    "10000000000000000001",
    "11111111111111111111",
}
local function tile_at(col, row)
    if row < 1 or row > MAP_ROWS or col < 1 or col > MAP_COLS then return 1 end
    local ch = MAP_DATA[row]:sub(col, col)
    return tonumber(ch) or 0
end
local function walkable(px, py)
    local col = math.floor(px / TILE) + 1
    local row = math.floor(py / TILE) + 1
    return tile_at(col, row) == 0
end

-- ── State ─────────────────────────────────────────────────────────────────
local STATE = { PLAY = 1, WIN = 2, LOSE = 3 }
local state  = STATE.PLAY
local score  = 0

local soldiers = {}
local enemies  = {}
local bullets  = {}
local explosions = {}      -- { x, y, t, dur }

-- formation target
local squad_target = { x = 120, y = 300 }

-- Spatial hash for fast range queries
local spatial = nil

-- ── Helpers ───────────────────────────────────────────────────────────────
local function dist2(ax,ay,bx,by) return (ax-bx)^2 + (ay-by)^2 end

local function clamp_to_map(x, y)
    return math.max(TILE+1, math.min(W-TILE-1, x)),
           math.max(TILE+1, math.min(H-TILE-1, y))
end

local function new_soldier(x, y)
    return { x=x, y=y, hp=3, shoot_cd=0, dir_x=1, dir_y=0 }
end

local function new_enemy(x, y)
    return { x=x, y=y, hp=2, shoot_cd=math.random()*SHOOT_CD, alert=false }
end

local function spawn_explosion(x, y)
    explosions[#explosions+1] = { x=x, y=y, t=0, dur=0.6 }
end

-- ── Load ──────────────────────────────────────────────────────────────────
function lurek.load()
    lurek.window.setTitle("Cannon Fodder — Lurek2D")
    lurek.gfx.setBackgroundColor(0.18, 0.32, 0.12)

    math.randomseed(os.time())

    -- Spawn squad at left
    for i = 0, 3 do
        soldiers[#soldiers+1] = new_soldier(80 + (i%2)*20, 260 + math.floor(i/2)*24)
    end

    -- Spawn enemies in the right half
    local enemy_positions = {
        {580,150},{620,200},{700,180},
        {540,300},{680,320},{720,260},
        {600,440},{660,480},{580,500},{720,420},
    }
    for _, ep in ipairs(enemy_positions) do
        enemies[#enemies+1] = new_enemy(ep[1], ep[2])
    end

    spatial = lurek.math.newSpatialHash(TILE * 2)
end

-- ── Update ────────────────────────────────────────────────────────────────
function lurek.update(dt)
    if state ~= STATE.PLAY then return end

    -- Move squad toward target in formation
    for i, s in ipairs(soldiers) do
        local offset_x = ((i-1) % 2) * 22 - 11
        local offset_y = (math.floor((i-1) / 2)) * 18 - 9
        local tx = squad_target.x + offset_x
        local ty = squad_target.y + offset_y
        local dx = tx - s.x; local dy = ty - s.y
        local d  = math.sqrt(dx*dx + dy*dy)
        if d > 4 then
            s.dir_x, s.dir_y = dx/d, dy/d
            local nx = s.x + s.dir_x * MOVE_SPEED * dt
            local ny = s.y + s.dir_y * MOVE_SPEED * dt
            if walkable(nx, ny) then s.x, s.y = nx, ny end
        end

        -- Auto-shoot nearest enemy in range
        s.shoot_cd = math.max(0, s.shoot_cd - dt)
        if s.shoot_cd == 0 then
            local best, bd = nil, SHOOT_RANGE * SHOOT_RANGE
            for _, e in ipairs(enemies) do
                local d2 = dist2(s.x, s.y, e.x, e.y)
                if d2 < bd then best, bd = e, d2 end
            end
            if best then
                local ddx = best.x - s.x; local ddy = best.y - s.y
                local dd  = math.sqrt(ddx*ddx + ddy*ddy)
                bullets[#bullets+1] = {
                    x=s.x, y=s.y,
                    vx=(ddx/dd)*BULLET_SPEED, vy=(ddy/dd)*BULLET_SPEED,
                    owner="soldier"
                }
                s.shoot_cd = SHOOT_CD
            end
        end
    end

    -- Enemy AI: alert if soldier within range, then shoot
    for _, e in ipairs(enemies) do
        e.shoot_cd = math.max(0, e.shoot_cd - dt)
        local nearest_s, nd2 = nil, (SHOOT_RANGE*1.5)^2
        for _, s in ipairs(soldiers) do
            local d2 = dist2(e.x, e.y, s.x, s.y)
            if d2 < nd2 then nearest_s, nd2 = s, d2 end
        end
        if nearest_s then
            e.alert = true
            -- Slow pursuit
            local ddx = nearest_s.x - e.x; local ddy = nearest_s.y - e.y
            local dd  = math.sqrt(ddx*ddx + ddy*ddy)
            local nx  = e.x + (ddx/dd) * ENEMY_SPEED * dt
            local ny  = e.y + (ddy/dd) * ENEMY_SPEED * dt
            if walkable(nx, ny) then e.x, e.y = nx, ny end
            -- Shoot
            if e.shoot_cd == 0 and dd < SHOOT_RANGE then
                bullets[#bullets+1] = {
                    x=e.x, y=e.y,
                    vx=(ddx/dd)*BULLET_SPEED, vy=(ddy/dd)*BULLET_SPEED,
                    owner="enemy"
                }
                e.shoot_cd = SHOOT_CD * 1.4
            end
        else
            e.alert = false
        end
    end

    -- Move bullets + hit detection
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        local remove = false

        -- Out of bounds or hit wall
        if not walkable(b.x, b.y) then remove = true end

        if b.owner == "soldier" then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if dist2(b.x, b.y, e.x, e.y) < (BULLET_R + ENEMY_R)^2 then
                    e.hp = e.hp - 1
                    remove = true
                    if e.hp <= 0 then
                        spawn_explosion(e.x, e.y)
                        score = score + 10
                        table.remove(enemies, j)
                    end
                    break
                end
            end
        else
            for j = #soldiers, 1, -1 do
                local s = soldiers[j]
                if dist2(b.x, b.y, s.x, s.y) < (BULLET_R + SOLDIER_R)^2 then
                    s.hp = s.hp - 1
                    remove = true
                    if s.hp <= 0 then
                        spawn_explosion(s.x, s.y)
                        table.remove(soldiers, j)
                    end
                    break
                end
            end
        end
        if remove then table.remove(bullets, i) end
    end

    -- Explosion timers
    for i = #explosions, 1, -1 do
        local ex = explosions[i]
        ex.t = ex.t + dt
        if ex.t >= ex.dur then table.remove(explosions, i) end
    end

    -- Win / lose
    if #enemies == 0 then state = STATE.WIN end
    if #soldiers == 0 then state = STATE.LOSE end
end

-- ── Draw ──────────────────────────────────────────────────────────────────
function lurek.draw()
    -- Tiles
    for row = 1, MAP_ROWS do
        for col = 1, MAP_COLS do
            local t = tile_at(col, row)
            if t == 1 then
                lurek.gfx.setColor(0.22, 0.38, 0.12)
                lurek.gfx.rectangle("fill", (col-1)*TILE, (row-1)*TILE, TILE, TILE)
                lurek.gfx.setColor(0.15, 0.26, 0.08)
                lurek.gfx.rectangle("line", (col-1)*TILE, (row-1)*TILE, TILE, TILE)
            end
        end
    end

    -- Squad target marker
    lurek.gfx.setColor(1, 1, 0, 0.4)
    lurek.gfx.circle("line", squad_target.x, squad_target.y, 14)

    -- Enemies
    for _, e in ipairs(enemies) do
        local r = e.alert and 0.95 or 0.6
        lurek.gfx.setColor(r, 0.15, 0.15)
        lurek.gfx.circle("fill", e.x, e.y, ENEMY_R)
        if e.alert then
            lurek.gfx.setColor(1, 0.4, 0)
            lurek.gfx.print("!", e.x - 2, e.y - ENEMY_R - 14)
        end
        -- HP pips
        for pip = 1, e.hp do
            lurek.gfx.setColor(0.1, 0.9, 0.1)
            lurek.gfx.rectangle("fill", e.x - 8 + (pip-1)*9, e.y - ENEMY_R - 8, 7, 4)
        end
    end

    -- Soldiers
    for i, s in ipairs(soldiers) do
        lurek.gfx.setColor(0.2, 0.6, 0.95)
        lurek.gfx.circle("fill", s.x, s.y, SOLDIER_R)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print(tostring(i), s.x - 3, s.y - 5)
        -- HP pips
        for pip = 1, s.hp do
            lurek.gfx.setColor(0.1, 0.9, 0.1)
            lurek.gfx.rectangle("fill", s.x - 12 + (pip-1)*9, s.y - SOLDIER_R - 8, 7, 4)
        end
    end

    -- Bullets
    lurek.gfx.setColor(1, 1, 0.3)
    for _, b in ipairs(bullets) do
        lurek.gfx.circle("fill", b.x, b.y, BULLET_R)
    end

    -- Explosions
    for _, ex in ipairs(explosions) do
        local prog = ex.t / ex.dur
        local r2   = prog * 30
        local alpha = 1 - prog
        lurek.gfx.setColor(1, 0.5, 0.1, alpha)
        lurek.gfx.circle("fill", ex.x, ex.y, r2)
        lurek.gfx.setColor(1, 1, 0, alpha * 0.6)
        lurek.gfx.circle("line", ex.x, ex.y, r2)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.55)
    lurek.gfx.rectangle("fill", 0, 0, W, 26)
    lurek.gfx.setColor(0.2, 0.6, 0.95)
    lurek.gfx.print(string.format("Squad: %d   Enemies: %d   Score: %d", #soldiers, #enemies, score), 10, 5)

    if state == STATE.WIN then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", W/2 - 140, H/2 - 30, 280, 60)
        lurek.gfx.setColor(0.2, 1, 0.4)
        lurek.gfx.print("MISSION COMPLETE!", W/2 - 90, H/2 - 10, 0, 1.4)
        lurek.gfx.setColor(1,1,1)
        lurek.gfx.print(string.format("Score: %d  (Esc to quit)", score), W/2 - 90, H/2 + 16)
    elseif state == STATE.LOSE then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", W/2 - 120, H/2 - 30, 240, 60)
        lurek.gfx.setColor(1, 0.2, 0.2)
        lurek.gfx.print("SQUAD ELIMINATED", W/2 - 85, H/2 - 10, 0, 1.4)
        lurek.gfx.setColor(1,1,1)
        lurek.gfx.print("Esc to quit", W/2 - 40, H/2 + 16)
    end
end

-- ── Mousepressed ──────────────────────────────────────────────────────────
function lurek.mousepressed(x, y, button)
    if button == 1 and state == STATE.PLAY then
        -- Click-to-move squad
        if walkable(x, y) then
            squad_target.x, squad_target.y = x, y
        end
    end
end

-- ── Keypressed ────────────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
end
