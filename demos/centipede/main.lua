-- Centipede — Classic Arcade (Luna2D demo)
-- Shoot the descending centipede. Mushrooms block bullets and redirect the worm.
-- Mouse/WASD to move, Space to shoot. Centipede splits when hit.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local CELL = 20
local COLS = math.floor(W / CELL)
local ROWS = math.floor(H / CELL)
local PLAYER_ZONE_TOP = ROWS - 6  -- rows player can occupy
local BULLET_SPEED = 500
local SHOOT_CD_TIME = 0.20
local CENTIPEDE_SPEED_BASE = 6    -- cells per second
local MUSHROOM_HP = 4

-- ── State ────────────────────────────────────────────────────────────────

local player = {}
local bullets = {}
local mushrooms = {}  -- [col][row] = hp
local segments = {}   -- centipede segments
local spiders = {}
local score, lives, wave = 0, 3, 1
local shoot_cd = 0
local game_state = "playing"
local spider_timer = 5

-- ── Helpers ──────────────────────────────────────────────────────────────

local function place_mushrooms()
    mushrooms = {}
    for col = 0, COLS - 1 do mushrooms[col] = {} end
    for i = 1, 30 do
        local mx = math.random(0, COLS - 1)
        local my = math.random(1, PLAYER_ZONE_TOP - 2)
        mushrooms[mx][my] = MUSHROOM_HP
    end
end

local function spawn_centipede(length)
    segments = {}
    local speed = CENTIPEDE_SPEED_BASE + (wave - 1) * 1.5
    for i = 1, length do
        segments[#segments+1] = {
            cx = COLS/2 - i + 1,  -- grid cell X
            cy = 0,                -- grid cell Y
            dx = 1,               -- movement direction (+1/-1 columns)
            px = (COLS/2 - i + 1) * CELL,   -- pixel X
            py = 0,                          -- pixel Y
            move_timer = (i - 1) / speed,   -- stagger spawn
            speed = speed,
            head = (i == 1)
        }
    end
end

local function reset()
    player = { x = W/2 - 10, y = H - 50, w = 20, h = 20, speed = 200 }
    bullets = {}
    shoot_cd = 0
    place_mushrooms()
    spawn_centipede(12)
    spiders = {}
    spider_timer = 5
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.load()
    luna.graphics.setBackgroundColor(0, 0, 0.04)
    score = 0; lives = 3; wave = 1
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.update(dt)
    if game_state ~= "playing" then return end
    shoot_cd = math.max(0, shoot_cd - dt)

    -- Player movement
    local px_min = 0
    local px_max = W - player.w
    local py_min = PLAYER_ZONE_TOP * CELL
    local py_max = H - player.h
    if luna.input.isKeyDown("left") or luna.input.isKeyDown("a") then
        player.x = math.max(px_min, player.x - player.speed * dt)
    end
    if luna.input.isKeyDown("right") or luna.input.isKeyDown("d") then
        player.x = math.min(px_max, player.x + player.speed * dt)
    end
    if luna.input.isKeyDown("up") or luna.input.isKeyDown("w") then
        player.y = math.max(py_min, player.y - player.speed * dt)
    end
    if luna.input.isKeyDown("down") or luna.input.isKeyDown("s") then
        player.y = math.min(py_max, player.y + player.speed * dt)
    end

    -- Bullets
    for i = #bullets, 1, -1 do
        bullets[i].y = bullets[i].y - BULLET_SPEED * dt
        if bullets[i].y < 0 then table.remove(bullets, i) end
    end

    -- Centipede movement (grid-based)
    local to_remove = {}
    for idx, seg in ipairs(segments) do
        seg.move_timer = seg.move_timer - dt
        if seg.move_timer <= 0 then
            seg.move_timer = 1 / seg.speed
            -- Try to move in dx direction
            local ncx = seg.cx + seg.dx
            if ncx < 0 or ncx >= COLS or (mushrooms[ncx] and mushrooms[ncx][seg.cy]) then
                -- Hit edge or mushroom — drop down and reverse
                seg.cy = seg.cy + 1
                seg.dx = -seg.dx
                if seg.cy >= ROWS then
                    seg.cy = 0  -- reappear at top
                end
            else
                seg.cx = ncx
            end
            seg.px = seg.cx * CELL
            seg.py = seg.cy * CELL
            -- Check if reached player zone bottom
            if seg.cy >= ROWS - 1 then
                game_state = "gameover"
                return
            end
        end
    end

    -- Spider
    spider_timer = spider_timer - dt
    if spider_timer <= 0 then
        spider_timer = 4 + math.random() * 4
        spiders[#spiders+1] = {
            x = math.random() > 0.5 and 0 or W - CELL,
            y = (PLAYER_ZONE_TOP + math.random(5)) * CELL,
            vx = (math.random() > 0.5 and 1 or -1) * 80,
            vy = 0,
            timer = 0
        }
    end
    for i = #spiders, 1, -1 do
        local sp = spiders[i]
        sp.timer = sp.timer + dt
        sp.x = sp.x + sp.vx * dt
        if sp.timer > 0.5 then
            sp.timer = 0
            sp.vy = (math.random() > 0.5 and 1 or -1) * 60
        end
        sp.y = sp.y + sp.vy * dt
        if sp.x < -30 or sp.x > W + 30 then table.remove(spiders, i) end
    end

    -- Bullet vs centipede
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        for si = #segments, 1, -1 do
            local seg = segments[si]
            if b.x > seg.px and b.x < seg.px + CELL and b.y > seg.py and b.y < seg.py + CELL then
                -- Place mushroom where it died
                mushrooms[seg.cx][seg.cy] = MUSHROOM_HP
                score = score + (seg.head and 100 or 10)
                table.remove(segments, si)
                table.remove(bullets, bi)
                -- Mark next segment as head
                if segments[si] then segments[si].head = true end
                break
            end
        end
    end

    -- Bullet vs mushroom
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        local mcx = math.floor(b.x / CELL)
        local mcy = math.floor(b.y / CELL)
        if mushrooms[mcx] and mushrooms[mcx][mcy] and mushrooms[mcx][mcy] > 0 then
            mushrooms[mcx][mcy] = mushrooms[mcx][mcy] - 1
            if mushrooms[mcx][mcy] <= 0 then mushrooms[mcx][mcy] = nil; score = score + 5 end
            table.remove(bullets, bi)
        end
    end

    -- Bullet vs spider
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        for i = #spiders, 1, -1 do
            local sp = spiders[i]
            if b.x > sp.x and b.x < sp.x + CELL and b.y > sp.y and b.y < sp.y + CELL then
                score = score + 300
                table.remove(spiders, i)
                table.remove(bullets, bi)
                break
            end
        end
    end

    -- Spider vs player (damage)
    for _, sp in ipairs(spiders) do
        if sp.x < player.x + player.w and sp.x + CELL > player.x and
           sp.y < player.y + player.h and sp.y + CELL > player.y then
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" else reset() end
            return
        end
    end

    -- Wave clear
    if #segments == 0 then
        wave = wave + 1
        place_mushrooms()
        spawn_centipede(12 + wave)
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.draw()
    -- Mushrooms
    for col = 0, COLS - 1 do
        if mushrooms[col] then
            for row, hp in pairs(mushrooms[col]) do
                local t = hp / MUSHROOM_HP
                luna.graphics.setColor(0.2 + t * 0.4, 0.6 * t, 0.1)
                luna.graphics.circle("fill", col * CELL + CELL/2, row * CELL + CELL/2, CELL/2 - 1)
            end
        end
    end

    -- Centipede
    for _, seg in ipairs(segments) do
        if seg.head then
            luna.graphics.setColor(0.9, 0.3, 0.8)
        else
            luna.graphics.setColor(0.2, 0.8, 0.3)
        end
        luna.graphics.circle("fill", seg.px + CELL/2, seg.py + CELL/2, CELL/2 - 1)
        -- Eyes on head
        if seg.head then
            luna.graphics.setColor(1, 1, 0)
            luna.graphics.circle("fill", seg.px + CELL/2 - 3, seg.py + CELL/2 - 3, 2)
            luna.graphics.circle("fill", seg.px + CELL/2 + 3, seg.py + CELL/2 - 3, 2)
        end
    end

    -- Spiders
    luna.graphics.setColor(1, 0.6, 0.1)
    for _, sp in ipairs(spiders) do
        luna.graphics.circle("fill", sp.x + CELL/2, sp.y + CELL/2, CELL/2 - 1)
        -- Legs
        for li = 0, 3 do
            local ang = li * math.pi / 2
            luna.graphics.line(sp.x + CELL/2, sp.y + CELL/2,
                sp.x + CELL/2 + math.cos(ang) * CELL, sp.y + CELL/2 + math.sin(ang) * CELL)
        end
    end

    -- Player
    luna.graphics.setColor(0.4, 0.7, 1.0)
    luna.graphics.rectangle("fill", player.x + 5, player.y, player.w - 10, player.h)
    luna.graphics.rectangle("fill", player.x, player.y + 10, player.w, 10)

    -- Bullets
    luna.graphics.setColor(1, 1, 0.5)
    for _, b in ipairs(bullets) do
        luna.graphics.rectangle("fill", b.x - 2, b.y, 4, 12)
    end

    -- Player zone separator line
    luna.graphics.setColor(0.2, 0.2, 0.4)
    luna.graphics.line(0, PLAYER_ZONE_TOP * CELL, W, PLAYER_ZONE_TOP * CELL)

    -- HUD
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Score: " .. score, 8, 4, 1.5)
    luna.graphics.setColor(1, 0.4, 0.4)
    luna.graphics.print("Lives: " .. lives, W - 95, 4, 1.5)
    luna.graphics.setColor(0.5, 0.7, 0.5)
    luna.graphics.print("Wave " .. wave, W/2 - 30, 4, 1.5)

    -- Overlay
    if game_state == "gameover" then
        luna.graphics.setColor(0, 0, 0, 0.7)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 0.2, 0.2)
        luna.graphics.print("GAME OVER", W/2 - 80, H/2 - 25, 3)
        luna.graphics.setColor(1, 1, 1)
        luna.graphics.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        luna.graphics.setColor(0.6, 0.6, 0.6)
        luna.graphics.print("Press R to restart", W/2 - 100, H/2 + 45, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then score = 0; lives = 3; wave = 1; reset() end
    if game_state ~= "playing" then return end
    if key == "space" and shoot_cd <= 0 and #bullets < 4 then
        bullets[#bullets+1] = { x = player.x + player.w/2, y = player.y - 10 }
        shoot_cd = SHOOT_CD_TIME
    end
end
