-- Donkey Kong — Classic Arcade (Luna2D demo)
-- Climb ladders and jump over barrels to rescue Pauline at the top.
-- WASD or Arrow keys to move, Space to jump.

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 960, 540
local GRAVITY = 900
local JUMP_VEL = -480
local PLAYER_SPEED = 160
local BARREL_SPEED_BASE = 110
local FLOOR_H = 16

-- ── Platform layout ───────────────────────────────────────────────────────
-- Each row: { y, x_left, x_right, tilt_per_pixel (slope) }

local PLATFORMS = {
    { y = H - 40,   x1 = 20,  x2 = W - 20, slope = 0 },
    { y = H - 140,  x1 = 50,  x2 = W - 50, slope = -0.04 },
    { y = H - 240,  x1 = 20,  x2 = W - 20, slope = 0.04 },
    { y = H - 340,  x1 = 50,  x2 = W - 50, slope = -0.04 },
    { y = H - 440,  x1 = 20,  x2 = W - 180, slope = 0 },
}

-- Ladders: connect platform pairs
local LADDERS = {
    { x = 200, y_top = H - 440, y_bot = H - 340 + FLOOR_H },
    { x = 680, y_top = H - 340, y_bot = H - 240 + FLOOR_H },
    { x = 220, y_top = H - 240, y_bot = H - 140 + FLOOR_H },
    { x = 700, y_top = H - 140, y_bot = H - 40  + FLOOR_H },
}

-- ── State ────────────────────────────────────────────────────────────────

local player = {}
local barrels = {}
local score, lives, level = 0, 3, 1
local game_state = "playing"
local barrel_timer = 0
local barrel_interval = 2.5
local win_flash = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function platform_y_at(plat, x)
    return plat.y + (x - (plat.x1 + plat.x2) / 2) * plat.slope
end

local function get_platform_under(x, y)
    local closest = nil
    local dist = math.huge
    for _, p in ipairs(PLATFORMS) do
        if x >= p.x1 and x <= p.x2 then
            local py = platform_y_at(p, x)
            local d = y - py
            if d >= -4 and d < 40 and d < dist then
                dist = d
                closest = p
            end
        end
    end
    return closest
end

local function on_ladder_near(x, y)
    for _, lad in ipairs(LADDERS) do
        if math.abs(x - lad.x) < 16 and y >= lad.y_top - 10 and y <= lad.y_bot + 10 then
            return lad
        end
    end
    return nil
end

local function reset()
    player = {
        x = 60, y = H - 40 - 36,
        vx = 0, vy = 0,
        w = 24, h = 36,
        on_ground = false,
        on_ladder = false,
        facing = 1,
    }
    barrels = {}
    barrel_timer = 0
    win_flash = 0
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0.05, 0.05, 0.1)
    score = 0; lives = 3; level = 1
    reset()
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.process(dt)
    if game_state ~= "playing" then
        if game_state == "win" then
            win_flash = win_flash + dt
            if win_flash > 2.0 then
                level = level + 1
                reset()
            end
        end
        return
    end

    -- Barrel spawning
    barrel_timer = barrel_timer - dt
    if barrel_timer <= 0 then
        barrel_timer = barrel_interval - (level - 1) * 0.2
        barrel_timer = math.max(1.0, barrel_timer)
        barrels[#barrels+1] = {
            x = W - 220, y = H - 440 - 24,
            vx = -BARREL_SPEED_BASE * (1 + (level - 1) * 0.1),
            vy = 0,
            w = 22, h = 22,
            on_ground = false,
            roll_anim = 0,
        }
    end

    -- Player input
    local move_input = 0
    if luna.input.isKeyDown("left") or luna.input.isKeyDown("a") then move_input = -1 end
    if luna.input.isKeyDown("right") or luna.input.isKeyDown("d") then move_input = 1 end

    local on_lad = on_ladder_near(player.x + player.w/2, player.y + player.h/2)
    if on_lad then
        if luna.input.isKeyDown("up") or luna.input.isKeyDown("w") then
            player.on_ladder = true
        end
        if luna.input.isKeyDown("down") or luna.input.isKeyDown("s") then
            player.on_ladder = true
        end
    else
        player.on_ladder = false
    end

    if player.on_ladder and on_lad then
        player.vy = 0; player.vx = 0
        if luna.input.isKeyDown("up") or luna.input.isKeyDown("w") then
            player.y = player.y - 120 * dt
        end
        if luna.input.isKeyDown("down") or luna.input.isKeyDown("s") then
            player.y = player.y + 120 * dt
        end
        -- Exit ladder at top
        if player.y + player.h <= on_lad.y_top then
            player.on_ladder = false
            player.vy = 0
        end
    else
        player.vx = move_input * PLAYER_SPEED
        if move_input ~= 0 then player.facing = move_input end

        -- Gravity
        if not player.on_ground then
            player.vy = player.vy + GRAVITY * dt
        else
            player.vy = 0
        end

        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt
    end

    -- Platform collision
    local plat = get_platform_under(player.x + player.w/2, player.y + player.h)
    if plat and player.vy >= 0 then
        local ground_y = platform_y_at(plat, player.x + player.w/2)
        player.y = ground_y - player.h
        player.vy = 0
        player.on_ground = true
    else
        player.on_ground = false
    end

    -- Clamp to screen
    player.x = math.max(0, math.min(W - player.w, player.x))

    -- Win condition: reach top
    if player.y + player.h < H - 440 then
        game_state = "win"
        score = score + level * 200
        win_flash = 0
        return
    end

    -- Update barrels
    for i = #barrels, 1, -1 do
        local b = barrels[i]
        b.roll_anim = b.roll_anim + dt * 6

        -- Gravity on barrel
        if not b.on_ground then
            b.vy = b.vy + GRAVITY * dt
        end

        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt

        -- Barrel platform
        local bp = get_platform_under(b.x + b.w/2, b.y + b.h)
        if bp and b.vy >= 0 then
            local by_ground = platform_y_at(bp, b.x + b.w/2)
            b.y = by_ground - b.h
            b.vy = 0
            b.on_ground = true
            -- Tilt slope affects speed
            b.vx = -math.abs(b.vx) * (1 + bp.slope * 8)
        else
            b.on_ground = false
        end

        -- Remove off screen
        if b.x < -40 or b.x > W + 40 or b.y > H + 40 then
            table.remove(barrels, i)
        else
            -- Collision with player
            local dx = math.abs((b.x + b.w/2) - (player.x + player.w/2))
            local dy = math.abs((b.y + b.h/2) - (player.y + player.h/2))
            if dx < (b.w + player.w) / 2 - 4 and dy < (b.h + player.h) / 2 - 4 then
                lives = lives - 1
                if lives <= 0 then game_state = "gameover" else reset() end
                return
            end

            -- Player jumps over barrel (score bonus)
            if player.vy < 0 and player.y < b.y and dx < 30 then
                score = score + 100
            end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.render()
    -- Platforms
    luna.gfx.setColor(0.5, 0.35, 0.2)
    for _, p in ipairs(PLATFORMS) do
        local y1 = platform_y_at(p, p.x1)
        local y2 = platform_y_at(p, p.x2)
        -- Draw as a sloped trapezoid by rendering rectangles along width
        local steps = math.floor((p.x2 - p.x1) / 4)
        for i = 0, steps - 1 do
            local t1 = i / steps
            local t2 = (i + 1) / steps
            local lx = p.x1 + t1 * (p.x2 - p.x1)
            local ly = y1 + t1 * (y2 - y1)
            local rw = (p.x2 - p.x1) / steps
            luna.gfx.rectangle("fill", lx, ly, rw + 1, FLOOR_H)
        end
    end

    -- Ladders
    luna.gfx.setColor(0.8, 0.65, 0.2)
    for _, lad in ipairs(LADDERS) do
        luna.gfx.rectangle("fill", lad.x - 3, lad.y_top, 6, lad.y_bot - lad.y_top)
        -- Rungs
        local num_rungs = math.floor((lad.y_bot - lad.y_top) / 20)
        for r = 0, num_rungs do
            local ry = lad.y_top + r * 20
            luna.gfx.rectangle("fill", lad.x - 12, ry, 24, 4)
        end
    end

    -- Pauline (goal) at top
    luna.gfx.setColor(1, 0.6, 0.6)
    luna.gfx.rectangle("fill", W - 200, H - 440 - 40, 20, 40)
    luna.gfx.circle("fill", W - 190, H - 440 - 48, 12)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("PAULINE!", W - 230, H - 440 - 60, 1.4)

    -- Donkey Kong at top
    luna.gfx.setColor(0.45, 0.25, 0.1)
    luna.gfx.rectangle("fill", W - 300, H - 440 - 50, 50, 50)
    luna.gfx.circle("fill", W - 275, H - 440 - 60, 18)
    -- DK arms
    luna.gfx.rectangle("fill", W - 330, H - 440 - 40, 30, 14)
    luna.gfx.rectangle("fill", W - 250, H - 440 - 40, 30, 14)

    -- Barrels
    for _, b in ipairs(barrels) do
        local roll = math.sin(b.roll_anim) * 5
        luna.gfx.setColor(0.6, 0.35, 0.1)
        luna.gfx.circle("fill", b.x + b.w/2, b.y + b.h/2, b.w/2)
        luna.gfx.setColor(0.8, 0.55, 0.2)
        luna.gfx.line(
            b.x + b.w/2 + math.cos(b.roll_anim) * b.w/2 * 0.7,
            b.y + b.h/2 + math.sin(b.roll_anim) * b.h/2 * 0.7,
            b.x + b.w/2 - math.cos(b.roll_anim) * b.w/2 * 0.7,
            b.y + b.h/2 - math.sin(b.roll_anim) * b.h/2 * 0.7
        )
    end

    -- Player
    luna.gfx.setColor(0.9, 0.2, 0.2)
    luna.gfx.rectangle("fill", player.x, player.y + player.h * 0.4, player.w, player.h * 0.6)
    luna.gfx.setColor(0.9, 0.7, 0.4)
    luna.gfx.circle("fill", player.x + player.w/2, player.y + 12, 12)
    -- Hat
    luna.gfx.setColor(0.6, 0.15, 0.1)
    luna.gfx.rectangle("fill", player.x + 2, player.y, player.w - 4, 10)
    luna.gfx.rectangle("fill", player.x - 2, player.y + 6, player.w + 4, 5)

    -- HUD
    luna.gfx.setColor(1, 1, 0)
    luna.gfx.print("DONKEY KONG", 10, 8, 2)
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("Score: " .. score, 10, 30, 1.5)
    luna.gfx.setColor(1, 0.3, 0.3)
    luna.gfx.print("Lives: " .. lives, W/2 - 50, 8, 1.5)
    luna.gfx.setColor(0.6, 0.8, 1)
    luna.gfx.print("Level " .. level, W - 90, 8, 1.5)

    -- Win overlay
    if game_state == "win" then
        luna.gfx.setColor(0, 0, 0, 0.5)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 1, 0, math.abs(math.sin(win_flash * 4)))
        luna.gfx.print("YOU SAVED PAULINE!", W/2 - 140, H/2 - 20, 3)
    end
    -- Game over overlay
    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.2, 0.2)
        luna.gfx.print("GAME OVER", W/2 - 80, H/2 - 25, 3)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.load() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "up" or key == "w") and player.on_ground and not player.on_ladder then
        player.vy = JUMP_VEL
        player.on_ground = false
    end
end
