-- Space Invaders — Classic Arcade (Luna2D demo)
-- Defend Earth! Shoot the alien invasion fleet before they reach the ground.
-- Arrow/AD to move, Space to fire. Barriers absorb shots.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local PLAYER_SPEED = 280
local BULLET_SPEED = 450
local INVADER_COLS, INVADER_ROWS = 11, 5
local INVADER_W, INVADER_H = 36, 28
local INVADER_PADX, INVADER_PADY = 10, 10
local BARRIER_COUNT = 4
local BARRIER_CELL = 7 -- pixels per barrier block

-- ── State ────────────────────────────────────────────────────────────────

local player = {}
local bullets = {}     -- player bullets
local inv_bullets = {} -- invader bullets
local invaders = {}
local barriers = {}
local score, lives, wave = 0, 3, 1
local inv_dir = 1       -- 1 = right, -1 = left
local inv_speed = 40
local inv_drop_amount = 16
local inv_shoot_timer = 0
local game_state = "playing"
local shoot_cooldown = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function barrier_block(bx, by)
    -- 4×3 grid of cells per barrier
    local blocks = {}
    for row = 0, 2 do
        for col = 0, 3 do
            if not (row == 0 and (col == 0 or col == 3)) then -- notched top corners
                blocks[#blocks+1] = { x = bx + col * BARRIER_CELL, y = by + row * BARRIER_CELL, hp = 3 }
            end
        end
    end
    return blocks
end

local function init()
    -- Player
    player = { x = W/2 - 20, y = H - 60, w = 40, h = 20 }
    bullets = {}; inv_bullets = {}
    shoot_cooldown = 0

    -- Invaders
    invaders = {}
    local start_x = 60
    local start_y = 80
    for row = 1, INVADER_ROWS do
        for col = 1, INVADER_COLS do
            invaders[#invaders+1] = {
                x = start_x + (col-1) * (INVADER_W + INVADER_PADX),
                y = start_y + (row-1) * (INVADER_H + INVADER_PADY),
                alive = true,
                row = row,
                anim = 0,
            }
        end
    end

    -- Barriers
    barriers = {}
    local bspacing = W / (BARRIER_COUNT + 1)
    for i = 1, BARRIER_COUNT do
        local bx = math.floor(bspacing * i - 14)
        local by = H - 130
        local blocks = barrier_block(bx, by)
        for _, b in ipairs(blocks) do barriers[#barriers+1] = b end
    end

    inv_dir = 1
    inv_speed = 40 + (wave - 1) * 10
    inv_shoot_timer = 1.5
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0, 0, 0)
    score = 0; lives = 3; wave = 1
    init()
end

-- ── Update ───────────────────────────────────────────────────────────────

local anim_timer = 0

function luna.process(dt)
    if game_state ~= "playing" then return end

    anim_timer = anim_timer + dt
    shoot_cooldown = math.max(0, shoot_cooldown - dt)

    -- Player movement
    if luna.input.isKeyDown("left") or luna.input.isKeyDown("a") then
        player.x = math.max(0, player.x - PLAYER_SPEED * dt)
    end
    if luna.input.isKeyDown("right") or luna.input.isKeyDown("d") then
        player.x = math.min(W - player.w, player.x + PLAYER_SPEED * dt)
    end

    -- Player bullet movement
    for i = #bullets, 1, -1 do
        bullets[i].y = bullets[i].y - BULLET_SPEED * dt
        if bullets[i].y < 0 then table.remove(bullets, i) end
    end

    -- Invader bullets
    for i = #inv_bullets, 1, -1 do
        inv_bullets[i].y = inv_bullets[i].y + BULLET_SPEED * 0.55 * dt
        if inv_bullets[i].y > H then table.remove(inv_bullets, i) end
    end

    -- Invader movement
    local alive = {}
    for _, inv in ipairs(invaders) do
        if inv.alive then alive[#alive+1] = inv end
    end
    if #alive == 0 then
        wave = wave + 1; init(); return
    end

    local left_edge = math.huge
    local right_edge = -math.huge
    for _, inv in ipairs(alive) do
        left_edge  = math.min(left_edge,  inv.x)
        right_edge = math.max(right_edge, inv.x + INVADER_W)
    end

    local move = inv_speed * dt * inv_dir
    local edge_hit = (inv_dir > 0 and right_edge + move >= W - 10) or
                     (inv_dir < 0 and left_edge + move <= 10)
    if edge_hit then
        inv_dir = -inv_dir
        for _, inv in ipairs(invaders) do
            if inv.alive then inv.y = inv.y + inv_drop_amount end
        end
    else
        for _, inv in ipairs(invaders) do
            if inv.alive then inv.x = inv.x + move end
        end
    end

    -- Invader invasion check
    for _, inv in ipairs(alive) do
        if inv.y + INVADER_H >= player.y then
            game_state = "gameover"; return
        end
    end

    -- Invader shooting
    inv_shoot_timer = inv_shoot_timer - dt
    if inv_shoot_timer <= 0 and #alive > 0 then
        inv_shoot_timer = 0.6 + math.random() * 1.0
        local shooter = alive[math.random(#alive)]
        inv_bullets[#inv_bullets+1] = {
            x = shooter.x + INVADER_W/2 - 2,
            y = shooter.y + INVADER_H,
            w = 4, h = 12
        }
    end

    -- Collision: player bullet vs invader
    for bi = #bullets, 1, -1 do
        local b = bullets[bi]
        for _, inv in ipairs(invaders) do
            if inv.alive and b.x > inv.x and b.x < inv.x + INVADER_W and
               b.y > inv.y and b.y < inv.y + INVADER_H then
                inv.alive = false
                table.remove(bullets, bi)
                local pts = (INVADER_ROWS + 1 - inv.row) * 10
                score = score + pts
                break
            end
        end
    end

    -- Collision: player bullet vs barriers
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        for _, blk in ipairs(barriers) do
            if blk.hp > 0 and b.x > blk.x and b.x < blk.x + BARRIER_CELL and
               b.y > blk.y and b.y < blk.y + BARRIER_CELL then
                blk.hp = blk.hp - 1
                table.remove(bullets, bi)
                break
            end
        end
    end

    -- Collision: invader bullet vs barriers
    for bi = #inv_bullets, 1, -1 do
        if not inv_bullets[bi] then break end
        local b = inv_bullets[bi]
        for _, blk in ipairs(barriers) do
            if blk.hp > 0 and b.x < blk.x + BARRIER_CELL and b.x + b.w > blk.x and
               b.y < blk.y + BARRIER_CELL and b.y + b.h > blk.y then
                blk.hp = blk.hp - 1
                table.remove(inv_bullets, bi)
                break
            end
        end
    end

    -- Collision: invader bullet vs player
    for bi = #inv_bullets, 1, -1 do
        if not inv_bullets[bi] then break end
        local b = inv_bullets[bi]
        if b.x < player.x + player.w and b.x + b.w > player.x and
           b.y < player.y + player.h and b.y + b.h > player.y then
            table.remove(inv_bullets, bi)
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

local ANIM_PERIOD = 0.5

function luna.render()
    -- Stars background
    math.randomseed(42)
    luna.gfx.setColor(0.9, 0.9, 0.9, 0.4)
    for i = 1, 80 do
        local sx = math.random(W)
        local sy = math.random(H)
        luna.gfx.circle("fill", sx, sy, 1)
    end
    math.randomseed(os.time())

    -- HUD
    luna.gfx.setColor(0.8, 1, 0.8)
    luna.gfx.print("SCORE: " .. score, 10, 8, 1.5)
    luna.gfx.print("WAVE: " .. wave, W/2 - 40, 8, 1.5)
    luna.gfx.setColor(1, 0.3, 0.3)
    luna.gfx.print("LIVES: " .. lives, W - 100, 8, 1.5)

    -- Ground line
    luna.gfx.setColor(0.4, 0.8, 0.4)
    luna.gfx.line(0, H - 30, W, H - 30)

    -- Barriers
    for _, blk in ipairs(barriers) do
        if blk.hp > 0 then
            local alpha = blk.hp / 3
            luna.gfx.setColor(0.2, 0.9, 0.2, alpha)
            luna.gfx.rectangle("fill", blk.x, blk.y, BARRIER_CELL, BARRIER_CELL)
        end
    end

    -- Player ship (simple polygon)
    luna.gfx.setColor(0.4, 0.8, 1.0)
    luna.gfx.rectangle("fill", player.x + player.w/2 - 4, player.y - 10, 8, 10)
    luna.gfx.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Invaders
    local frame = math.floor(anim_timer / ANIM_PERIOD) % 2
    for _, inv in ipairs(invaders) do
        if inv.alive then
            local row_hue = (inv.row - 1) / (INVADER_ROWS - 1)
            luna.gfx.setColor(0.2 + row_hue * 0.8, 1.0 - row_hue * 0.5, 0.2)
            local ix = inv.x + (frame == 1 and 3 or 0)
            -- Body
            luna.gfx.rectangle("fill", ix + 5, inv.y + 4, INVADER_W - 10, INVADER_H - 10)
            -- Head bumps
            luna.gfx.rectangle("fill", ix + 8, inv.y, INVADER_W - 16, 8)
            -- Legs (alternate frame)
            if frame == 0 then
                luna.gfx.rectangle("fill", ix + 2, inv.y + INVADER_H - 8, 6, 8)
                luna.gfx.rectangle("fill", ix + INVADER_W - 8, inv.y + INVADER_H - 8, 6, 8)
            else
                luna.gfx.rectangle("fill", ix + 6, inv.y + INVADER_H - 8, 6, 8)
                luna.gfx.rectangle("fill", ix + INVADER_W - 12, inv.y + INVADER_H - 8, 6, 8)
            end
            -- Eyes
            luna.gfx.setColor(0, 0, 0)
            luna.gfx.circle("fill", ix + INVADER_W/2 - 5, inv.y + 8, 3)
            luna.gfx.circle("fill", ix + INVADER_W/2 + 5, inv.y + 8, 3)
        end
    end

    -- Player bullets
    luna.gfx.setColor(1, 1, 0.5)
    for _, b in ipairs(bullets) do
        luna.gfx.rectangle("fill", b.x, b.y, b.w, b.h)
    end

    -- Invader bullets
    luna.gfx.setColor(1, 0.3, 0.3)
    for _, b in ipairs(inv_bullets) do
        luna.gfx.rectangle("fill", b.x, b.y, b.w, b.h)
    end

    -- Overlays
    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.2, 0.2)
        luna.gfx.print("GAME OVER", W/2 - 80, H/2 - 30, 3)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 45, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then score = 0; lives = 3; wave = 1; init() end
    if game_state ~= "playing" then return end
    if key == "space" and shoot_cooldown <= 0 and #bullets < 3 then
        bullets[#bullets+1] = { x = player.x + player.w/2 - 2, y = player.y - 10, w = 4, h = 14 }
        shoot_cooldown = 0.25
    end
end
