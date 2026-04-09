-- Paradroid — C-64 Classic (Lurek2D demo)
-- Top-down shooter on a space station. Transfer your program into enemy droids
-- to take control of them. Inspired by Andrew Braybrook's 1985 C-64 masterpiece.
-- Run with: cargo run -- content/demos/retro/paradroid

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local ROOM_X, ROOM_Y, ROOM_W, ROOM_H = 60, 40, 680, 520
local CELL = 40
local COLS = math.floor(ROOM_W / CELL)
local ROWS = math.floor(ROOM_H / CELL)

local DROID_SPEED = 90
local BULLET_SPEED = 320
local TRANSFER_RANGE = 55
local PLAYER_ENERGY_MAX = 100
local TRANSFER_TIME = 3.0  -- Seconds for transfer minigame

-- ── State ─────────────────────────────────────────────────────────────────

local player = {}
local droids = {}
local bullets = {}
local walls = {}   -- {x,y,w,h}
local score, level = 0, 1
local game_state = "playing"  -- "playing","transfer","gameover","levelclear"

-- Transfer minigame state
local transfer = { target = nil, progress = 0, player_bar = 50, enemy_bar = 50, won = false }
local transfer_accept = false

local anim = 0

-- ── Level Builder ─────────────────────────────────────────────────────────

local function build_level(lvl)
    walls = {}
    -- Outer boundary walls
    table.insert(walls, { x = ROOM_X, y = ROOM_Y, w = ROOM_W, h = 8 })
    table.insert(walls, { x = ROOM_X, y = ROOM_Y + ROOM_H - 8, w = ROOM_W, h = 8 })
    table.insert(walls, { x = ROOM_X, y = ROOM_Y, w = 8, h = ROOM_H })
    table.insert(walls, { x = ROOM_X + ROOM_W - 8, y = ROOM_Y, w = 8, h = ROOM_H })
    -- Interior rooms
    math.randomseed(lvl * 13)
    for _ = 1, 4 + lvl do
        local cx = ROOM_X + 8 + math.random(COLS - 4) * CELL
        local cy = ROOM_Y + 8 + math.random(ROWS - 4) * CELL
        local ww = CELL * (2 + math.random(2))
        local wh = 8
        table.insert(walls, { x = cx, y = cy, w = ww, h = wh })
        table.insert(walls, { x = cx, y = cy + CELL, w = 8, h = CELL })
    end

    -- Spawn droids
    droids = {}
    local count = 3 + lvl * 2
    for i = 1, count do
        local a = math.random() * math.pi * 2
        local r = 100 + math.random(150)
        local dx = W / 2 + math.cos(a) * r
        local dy = H / 2 + math.sin(a) * r
        droids[#droids+1] = {
            x = dx, y = dy, w = 24, h = 24,
            vx = (math.random()-0.5)*60, vy = (math.random()-0.5)*60,
            energy = 70 + math.random(30),
            rating = 100 + i * 100,
            shoot_cd = 1 + math.random() * 2,
            alive = true,
            is_player = false
        }
    end
    math.randomseed(os.time())
end

local function rect_overlap(ax,ay,aw,ah, bx,by,bw,bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

local function check_wall(ex, ey, ew, eh)
    for _, w in ipairs(walls) do
        if rect_overlap(ex, ey, ew, eh, w.x, w.y, w.w, w.h) then
            return true
        end
    end
    return false
end

local function reset()
    player = { x = W/2 - 12, y = H/2 - 12, w = 24, h = 24,
               vx = 0, vy = 0, energy = PLAYER_ENERGY_MAX,
               shoot_cd = 0 }
    bullets = {}
    build_level(level)
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.05, 0.05, 0.12)
    score = 0; level = 1
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    anim = anim + dt

    if game_state == "transfer" then
        -- Transfer minigame: player tries to keep bar in upper half
        local t = transfer
        if lurek.input.isKeyDown("space") then
            t.player_bar = math.min(100, t.player_bar + 120 * dt)
        else
            t.player_bar = math.max(0, t.player_bar - 60 * dt)
        end
        t.enemy_bar = math.max(0, t.enemy_bar - (t.player_bar / 100) * 80 * dt
                              + (1 - t.player_bar / 100) * 40 * dt)
        t.enemy_bar = math.min(100, t.enemy_bar)
        t.progress = t.progress + dt
        if t.enemy_bar <= 0 then
            -- Success: take control
            t.target.is_player = true
            t.target.energy = math.min(100, t.target.energy + 20)
            local old_x, old_y = player.x, player.y
            player = t.target
            player.is_player = true
            player.shoot_cd = 0
            -- Spawn 0-droid where old was
            droids[#droids+1] = {
                x = old_x, y = old_y, w = 24, h = 24,
                vx = 0, vy = 0, energy = 20, rating = 0,
                shoot_cd = 2, alive = true, is_player = false
            }
            game_state = "playing"
        elseif t.player_bar <= 0 or t.progress >= TRANSFER_TIME then
            -- Failed
            player.energy = player.energy - 20
            if player.energy <= 0 then game_state = "gameover" end
            game_state = "playing"
        end
        return
    end

    if game_state ~= "playing" then return end

    -- Player movement (WASD / arrows)
    player.shoot_cd = math.max(0, player.shoot_cd - dt)
    local pvx, pvy = 0, 0
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a")  then pvx = -DROID_SPEED end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then pvx =  DROID_SPEED end
    if lurek.input.isKeyDown("up") or lurek.input.isKeyDown("w")    then pvy = -DROID_SPEED end
    if lurek.input.isKeyDown("down") or lurek.input.isKeyDown("s")  then pvy =  DROID_SPEED end

    -- Normalize diagonal
    if pvx ~= 0 and pvy ~= 0 then pvx = pvx * 0.707; pvy = pvy * 0.707 end

    local nx = player.x + pvx * dt
    local ny = player.y + pvy * dt
    -- Clamp to room
    nx = math.max(ROOM_X + 8, math.min(ROOM_X + ROOM_W - player.w - 8, nx))
    ny = math.max(ROOM_Y + 8, math.min(ROOM_Y + ROOM_H - player.h - 8, ny))
    if not check_wall(nx + 1, player.y + 1, player.w - 2, player.h - 2) then player.x = nx end
    if not check_wall(player.x + 1, ny + 1, player.w - 2, player.h - 2) then player.y = ny end

    -- Bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 or check_wall(b.x, b.y, 5, 5) then
            table.remove(bullets, i)
        end
    end

    -- Enemy droids AI
    for i = #droids, 1, -1 do
        local d = droids[i]
        if d.alive and not d.is_player then
            -- Move toward player
            local dx = player.x - d.x
            local dy = player.y - d.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 30 then
                local spd = DROID_SPEED * 0.5
                local nvx = dx / dist * spd
                local nvy = dy / dist * spd
                local nx2 = d.x + nvx * dt
                local ny2 = d.y + nvy * dt
                nx2 = math.max(ROOM_X + 8, math.min(ROOM_X + ROOM_W - d.w - 8, nx2))
                ny2 = math.max(ROOM_Y + 8, math.min(ROOM_Y + ROOM_H - d.h - 8, ny2))
                if not check_wall(nx2 + 1, d.y + 1, d.w - 2, d.h - 2) then d.x = nx2 end
                if not check_wall(d.x + 1, ny2 + 1, d.w - 2, d.h - 2) then d.y = ny2 end
            end
            -- Shoot
            d.shoot_cd = d.shoot_cd - dt
            if d.shoot_cd <= 0 and dist < 280 then
                d.shoot_cd = 1.2 + math.random()
                bullets[#bullets+1] = {
                    x = d.x + d.w/2, y = d.y + d.h/2,
                    vx = dx / dist * BULLET_SPEED * 0.8,
                    vy = dy / dist * BULLET_SPEED * 0.8,
                    life = 1.5, enemy = true
                }
            end
        end
    end

    -- Bullet hit player
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if b.enemy and rect_overlap(b.x, b.y, 5, 5, player.x, player.y, player.w, player.h) then
            player.energy = player.energy - 10
            table.remove(bullets, i)
            if player.energy <= 0 then game_state = "gameover" end
        end
    end

    -- Player bullets hit droids
    for bi = #bullets, 1, -1 do
        if not bullets[bi] or bullets[bi].enemy then goto cont end
        for di = #droids, 1, -1 do
            local d = droids[di]
            if d.alive and not d.is_player and rect_overlap(bullets[bi].x, bullets[bi].y, 5, 5, d.x, d.y, d.w, d.h) then
                d.energy = d.energy - 20
                table.remove(bullets, bi)
                if d.energy <= 0 then
                    d.alive = false
                    score = score + d.rating
                end
                break
            end
        end
        ::cont::
    end

    -- Level clear: no live enemies
    local alive_count = 0
    for _, d in ipairs(droids) do if d.alive and not d.is_player then alive_count = alive_count + 1 end end
    if alive_count == 0 then
        score = score + level * 1000
        level = level + 1
        if level > 5 then game_state = "win" else reset() end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Room floor
    lurek.gfx.setColor(0.08, 0.08, 0.18)
    lurek.gfx.rectangle("fill", ROOM_X, ROOM_Y, ROOM_W, ROOM_H)

    -- Floor grid
    lurek.gfx.setColor(0.12, 0.12, 0.25)
    for c = 0, COLS do
        lurek.gfx.line(ROOM_X + c * CELL, ROOM_Y, ROOM_X + c * CELL, ROOM_Y + ROOM_H)
    end
    for r = 0, ROWS do
        lurek.gfx.line(ROOM_X, ROOM_Y + r * CELL, ROOM_X + ROOM_W, ROOM_Y + r * CELL)
    end

    -- Walls
    lurek.gfx.setColor(0.3, 0.3, 0.5)
    for _, w in ipairs(walls) do
        lurek.gfx.rectangle("fill", w.x, w.y, w.w, w.h)
        lurek.gfx.setColor(0.5, 0.5, 0.7)
        lurek.gfx.rectangle("line", w.x, w.y, w.w, w.h)
        lurek.gfx.setColor(0.3, 0.3, 0.5)
    end

    -- Transfer range circle
    if game_state == "playing" then
        for _, d in ipairs(droids) do
            if d.alive and not d.is_player then
                local dx = (d.x + d.w/2) - (player.x + player.w/2)
                local dy = (d.y + d.h/2) - (player.y + player.h/2)
                if math.sqrt(dx*dx + dy*dy) < TRANSFER_RANGE + 10 then
                    lurek.gfx.setColor(0.1, 0.8, 0.6, 0.3)
                    lurek.gfx.circle("line", player.x + player.w/2, player.y + player.h/2, TRANSFER_RANGE)
                end
            end
        end
    end

    -- Bullets
    lurek.gfx.setColor(1, 0.9, 0.1)
    for _, b in ipairs(bullets) do
        if not b.enemy then lurek.gfx.rectangle("fill", b.x - 2, b.y - 3, 4, 6) end
    end
    lurek.gfx.setColor(1, 0.3, 0.1)
    for _, b in ipairs(bullets) do
        if b.enemy then lurek.gfx.rectangle("fill", b.x - 2, b.y - 3, 4, 6) end
    end

    -- Droids
    for _, d in ipairs(droids) do
        if d.alive and not d.is_player then
            local hue = d.energy / 100
            lurek.gfx.setColor(1 - hue, hue * 0.4, 0.6)
            lurek.gfx.rectangle("fill", d.x, d.y, d.w, d.h)
            lurek.gfx.setColor(0.8, 0.8, 1)
            lurek.gfx.rectangle("line", d.x, d.y, d.w, d.h)
            -- Rating number
            lurek.gfx.setColor(1, 1, 1)
            lurek.gfx.print(tostring(math.floor(d.rating / 100)), d.x + 6, d.y + 7, 1.2)
        end
    end

    -- Player droid
    local pulse = 0.5 + 0.5 * math.sin(anim * 6)
    lurek.gfx.setColor(0.1 + pulse * 0.2, 0.8, 0.4)
    lurek.gfx.rectangle("fill", player.x, player.y, player.w, player.h)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.rectangle("line", player.x, player.y, player.w, player.h)
    lurek.gfx.setColor(0, 0, 0)
    lurek.gfx.print("0", player.x + 8, player.y + 7, 1.2)

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.65)
    lurek.gfx.rectangle("fill", 0, 0, W, 35)
    lurek.gfx.setColor(0.1, 0.9, 0.5)
    lurek.gfx.print("PARADROID", 8, 5, 1.8)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Score: " .. score, W/2 - 50, 5, 1.6)
    lurek.gfx.setColor(1, 0.5, 0.5)
    -- Energy bar
    local emax = 130
    lurek.gfx.setColor(0.3, 0, 0)
    lurek.gfx.rectangle("fill", W - emax - 10, 7, emax, 16)
    lurek.gfx.setColor(0.1, 0.9, 0.2)
    lurek.gfx.rectangle("fill", W - emax - 10, 7, emax * (player.energy / PLAYER_ENERGY_MAX), 16)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("E", W - emax - 22, 7, 1.4)
    lurek.gfx.setColor(0.5, 0.9, 1)
    lurek.gfx.print("Lv " .. level, W/2 + 60, 5, 1.6)

    -- T key hint
    lurek.gfx.setColor(0.5, 0.8, 1, 0.7)
    lurek.gfx.print("[T] Transfer  [Space] Shoot", ROOM_X, ROOM_Y + ROOM_H + 5, 1.3)

    -- Transfer minigame overlay
    if game_state == "transfer" then
        local cx, cy = W/2, H/2
        lurek.gfx.setColor(0, 0, 0, 0.8)
        lurek.gfx.rectangle("fill", cx - 160, cy - 80, 320, 160)
        lurek.gfx.setColor(0, 0.8, 0.8)
        lurek.gfx.rectangle("line", cx - 160, cy - 80, 320, 160)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("TRANSFER OVERRIDE", cx - 110, cy - 70, 1.6)
        -- Bars
        local pb = transfer.player_bar / 100 * 200
        lurek.gfx.setColor(0.1, 0.3, 0.1)
        lurek.gfx.rectangle("fill", cx - 100, cy - 20, 200, 20)
        lurek.gfx.setColor(0.1, 0.9, 0.3)
        lurek.gfx.rectangle("fill", cx - 100, cy - 20, pb, 20)
        local eb = transfer.enemy_bar / 100 * 200
        lurek.gfx.setColor(0.3, 0.1, 0.1)
        lurek.gfx.rectangle("fill", cx - 100, cy + 10, 200, 20)
        lurek.gfx.setColor(0.9, 0.2, 0.1)
        lurek.gfx.rectangle("fill", cx - 100, cy + 10, eb, 20)
        lurek.gfx.setColor(0.6, 1, 0.6)
        lurek.gfx.print("YOU", cx - 95, cy - 18, 1.2)
        lurek.gfx.setColor(1, 0.6, 0.4)
        lurek.gfx.print("ENEMY", cx - 95, cy + 12, 1.2)
        lurek.gfx.setColor(0.9, 0.9, 0.5)
        lurek.gfx.print("Hold SPACE to override!", cx - 105, cy + 42, 1.4)
    end

    -- Overlays
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.75)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(1, 0.2, 0.2)
        lurek.gfx.print("DROID DESTROYED", W/2 - 125, H/2 - 25, 3)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    elseif game_state == "win" then
        lurek.gfx.setColor(0, 0, 0, 0.75)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(0.2, 1, 0.4)
        lurek.gfx.print("STATION CLEARED!", W/2 - 125, H/2 - 25, 3)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to play again", W/2 - 110, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end

    if game_state == "playing" then
        if key == "space" and player.shoot_cd <= 0 then
            local dir = { 0, -1 }
            -- Shoot upward (simple — could add directional input)
            bullets[#bullets+1] = {
                x = player.x + player.w/2, y = player.y - 5,
                vx = 0, vy = -BULLET_SPEED, life = 1.5, enemy = false
            }
            player.shoot_cd = 0.25
        end
        if key == "t" then
            -- Find nearest droid in range
            local best, best_dist = nil, TRANSFER_RANGE
            for _, d in ipairs(droids) do
                if d.alive and not d.is_player then
                    local dx = (d.x + d.w/2) - (player.x + player.w/2)
                    local dy = (d.y + d.h/2) - (player.y + player.h/2)
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < best_dist then best = d; best_dist = dist end
                end
            end
            if best then
                transfer.target = best
                transfer.progress = 0
                transfer.player_bar = 50
                transfer.enemy_bar = 100
                game_state = "transfer"
            end
        end
    end
end
