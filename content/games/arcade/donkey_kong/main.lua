-- ============================================================================
--  Donkey Kong — Climb sloped platforms to rescue Pauline
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : ../../../../content/demos/arcade/donkey_kong   (original demo)
--  Run with : cargo run -- content/games/arcade/donkey_kong
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A/D or ←/→   — walk along platform
--    up/down    : W/S or ↑/↓   — climb ladders
--    jump       : Space         — jump over barrels
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, camera, particles, tween
-- ============================================================================

-- ── Game-wide constants ───────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 960, 540
local GRAVITY             = 600
local PLAYER_SPEED        = 120
local PLAYER_JUMP_VEL     = -260
local BARREL_SPEED        = 100
local BARREL_RADIUS       = 8
local LADDER_CLIMB_SPEED  = 80
local HAMMER_DURATION     = 5.0
local BARREL_LADDER_CHANCE = 0.30
local BARREL_THROW_BASE   = 2.2
local BARREL_THROW_MIN    = 0.9

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, WIN_ANIM = 3, GAME_OVER = 4 }
local state = STATE.TITLE

-- ── Platform definitions ──────────────────────────────────────────────────
-- Each platform: {x1, y1, x2, y2} — line segment with slope
-- 6 platforms from bottom to top, alternating tilt direction
local platforms = {}
local ladders   = {}
local hammer_spawn = nil

-- ── Game state ────────────────────────────────────────────────────────────
local player = { x = 0, y = 0, w = 16, h = 24, vx = 0, vy = 0,
                 on_ground = false, climbing = false, facing = 1,
                 jumping = false }
local dk     = { x = 0, y = 0, w = 40, h = 44, arm_angle = 0 }
local pauline = { x = 0, y = 0 }
local barrels = {}
local barrel_timer = 0
local barrel_interval = BARREL_THROW_BASE
local wave = 1

local score  = 0
local lives  = 3
local hammer = { active = false, timer = 0, x = 0, y = 0, collected = false }

-- Visual effects
local sparks        = nil
local dust          = nil
local title_blink   = 0
local win_timer     = 0
local heart_scale   = { v = 0 }
local heart_tween   = nil
local dk_throw_tween = nil
local cam           = nil

-- ── Helper: compute y on a platform at given x ────────────────────────────
local function platform_y_at(plat, px)
    local t = (px - plat[1]) / (plat[3] - plat[1])
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return plat[2] + t * (plat[4] - plat[2])
end

-- ── Helper: platform slope (dy/dx) ───────────────────────────────────────
local function platform_slope(plat)
    local dx = plat[3] - plat[1]
    if dx == 0 then return 0 end
    return (plat[4] - plat[2]) / dx
end

-- ── Helper: check if x is within platform range ──────────────────────────
local function on_platform_range(plat, px)
    local lx = math.min(plat[1], plat[3])
    local rx = math.max(plat[1], plat[3])
    return px >= lx and px <= rx
end

-- ── Helper: find platform under a point ───────────────────────────────────
local function find_platform(px, py, tolerance)
    tolerance = tolerance or 6
    for i, plat in ipairs(platforms) do
        if on_platform_range(plat, px) then
            local surf = platform_y_at(plat, px)
            if py >= surf - tolerance and py <= surf + tolerance then
                return i, plat, surf
            end
        end
    end
    return nil, nil, nil
end

-- ── Helper: find platform below a point ───────────────────────────────────
local function find_platform_below(px, py)
    local best_i, best_plat, best_y = nil, nil, 9999
    for i, plat in ipairs(platforms) do
        if on_platform_range(plat, px) then
            local surf = platform_y_at(plat, px)
            if surf > py and surf < best_y then
                best_i, best_plat, best_y = i, plat, surf
            end
        end
    end
    return best_i, best_plat, best_y
end

-- ── Helper: find ladder at position ───────────────────────────────────────
local function find_ladder(px, py, w, h)
    for _, lad in ipairs(ladders) do
        local lx, ltop, lbot = lad.x, lad.top, lad.bottom
        if px + w > lx - 8 and px < lx + 8 then
            if py + h > ltop and py < lbot then
                return lad
            end
        end
    end
    return nil
end

-- ── Helper: rectangle overlap ─────────────────────────────────────────────
local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ── Build level geometry ──────────────────────────────────────────────────
local function build_level()
    platforms = {}
    ladders   = {}

    local pw = SCREEN_W - 80  -- platform width
    local gap = 75             -- vertical gap between platforms
    local base_y = SCREEN_H - 30
    local slope_amount = 18

    for i = 1, 6 do
        local y = base_y - (i - 1) * gap
        local x_start, x_end
        if i % 2 == 1 then
            -- slopes right-to-left (left side lower)
            x_start, x_end = 40, 40 + pw
            local y1 = y
            local y2 = y - slope_amount
            platforms[i] = { x_start, y1, x_end, y2 }
        else
            -- slopes left-to-right (right side lower)
            x_start, x_end = 40, 40 + pw
            local y1 = y - slope_amount
            local y2 = y
            platforms[i] = { x_start, y1, x_end, y2 }
        end
    end

    -- Ladders: 2-3 per gap, connecting adjacent platforms
    for i = 1, 5 do
        local plat_bottom = platforms[i]
        local plat_top    = platforms[i + 1]
        local num_ladders = (i % 2 == 0) and 3 or 2

        for j = 1, num_ladders do
            local frac = (j) / (num_ladders + 1)
            local lx = plat_bottom[1] + frac * (plat_bottom[3] - plat_bottom[1])
            local y_bot = platform_y_at(plat_bottom, lx)
            local y_top = platform_y_at(plat_top, lx)
            ladders[#ladders + 1] = { x = lx, top = y_top, bottom = y_bot, gap_index = i }
        end
    end

    -- Hammer spawn on platform 3, right side
    local hx = platforms[3][3] - 60
    local hy = platform_y_at(platforms[3], hx) - 16
    hammer_spawn = { x = hx, y = hy }

    -- Player start: bottom-left of platform 1
    player.x = platforms[1][1] + 20
    player.y = platform_y_at(platforms[1], player.x) - player.h
    player.vx = 0
    player.vy = 0
    player.on_ground = true
    player.climbing = false
    player.jumping = false

    -- DK position: top-left area on platform 6
    dk.x = platforms[6][1] + 10
    dk.y = platform_y_at(platforms[6], dk.x + dk.w / 2) - dk.h

    -- Pauline position: top-right area on platform 6
    pauline.x = platforms[6][3] - 60
    pauline.y = platform_y_at(platforms[6], pauline.x) - 20
end

-- ── Spawn a barrel from DK ───────────────────────────────────────────────
local function spawn_barrel()
    local bx = dk.x + dk.w
    local by = dk.y + dk.h - 10
    barrels[#barrels + 1] = {
        x = bx, y = by, r = BARREL_RADIUS,
        vx = BARREL_SPEED, vy = 0,
        platform_index = 6, on_ladder = false,
        active = true
    }
    -- DK throw animation
    dk.arm_angle = 0
    dk_throw_tween = lurek.tween.to(dk, 0.3, { arm_angle = 1 })
end

-- ── Reset game ────────────────────────────────────────────────────────────
local function reset_game()
    score = 0
    lives = 3
    wave = 1
    barrel_interval = BARREL_THROW_BASE
    barrels = {}
    barrel_timer = 0
    hammer.active = false
    hammer.collected = false
    build_level()
end

-- ── Respawn player after death ────────────────────────────────────────────
local function respawn_player()
    player.x = platforms[1][1] + 20
    player.y = platform_y_at(platforms[1], player.x) - player.h
    player.vx = 0
    player.vy = 0
    player.on_ground = true
    player.climbing = false
    player.jumping = false
    hammer.active = false
end

-- ═══════════════════════════════════════════════════════════════════════════
--  lurek.init — one-time setup
-- ═══════════════════════════════════════════════════════════════════════════
function lurek.init()
    lurek.window.setTitle("Donkey Kong — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.1)

    -- Input bindings
    lurek.input.bind("left",  {"a", "left"})
    lurek.input.bind("right", {"d", "right"})
    lurek.input.bind("up",    {"w", "up"})
    lurek.input.bind("down",  {"s", "down"})
    lurek.input.bind("jump",  {"space"})
    lurek.input.bind("quit",  {"escape"})

    -- Camera (static, full screen)
    cam = lurek.camera.new(SCREEN_W, SCREEN_H)
    cam:setPosition(SCREEN_W / 2, SCREEN_H / 2)

    -- Particle systems
    sparks = lurek.particle.newSystem({
        maxParticles  = 60,
        emissionRate  = 0,
        lifetimeMin   = 0.25,
        lifetimeMax   = 0.5,
        speedMin      = 80,
        speedMax      = 200,
        direction     = -math.pi / 2,
        spread        = math.pi * 2,
        gravityY      = 120,
        sizes         = {4, 1},
        colors        = {1, 0.6, 0.1, 1,  1, 0.2, 0.0, 0}
    })

    dust = lurek.particle.newSystem({
        maxParticles  = 30,
        emissionRate  = 0,
        lifetimeMin   = 0.15,
        lifetimeMax   = 0.35,
        speedMin      = 20,
        speedMax      = 60,
        direction     = -math.pi / 2,
        spread        = math.pi,
        gravityY      = 40,
        sizes         = {3, 1},
        colors        = {0.7, 0.6, 0.5, 0.8,  0.5, 0.4, 0.3, 0}
    })

    build_level()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  lurek.process — game logic
-- ═══════════════════════════════════════════════════════════════════════════
function lurek.process(dt)
    lurek.tween.update(dt)
    sparks:update(dt)
    dust:update(dt)

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title state ───────────────────────────────────────────────────
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("jump") then
            state = STATE.PLAYING
            reset_game()
        end
        return
    end

    -- ── Game over state ───────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("jump") then
            state = STATE.TITLE
        end
        return
    end

    -- ── Win animation state ───────────────────────────────────────────
    if state == STATE.WIN_ANIM then
        win_timer = win_timer + dt
        if win_timer > 3 then
            -- Next wave: faster barrels
            wave = wave + 1
            barrel_interval = math.max(BARREL_THROW_MIN, BARREL_THROW_BASE - wave * 0.2)
            barrels = {}
            barrel_timer = 0
            hammer.active = false
            hammer.collected = false
            build_level()
            state = STATE.PLAYING
        end
        return
    end

    -- ── Playing state ─────────────────────────────────────────────────

    -- Player movement
    local moving = false
    if not player.climbing then
        -- Horizontal movement
        if lurek.input.isActionDown("left") then
            player.vx = -PLAYER_SPEED
            player.facing = -1
            moving = true
        elseif lurek.input.isActionDown("right") then
            player.vx = PLAYER_SPEED
            player.facing = 1
            moving = true
        else
            player.vx = 0
        end

        -- Jump
        if lurek.input.wasActionPressed("jump") and player.on_ground then
            player.vy = PLAYER_JUMP_VEL
            player.on_ground = false
            player.jumping = true
        end

        -- Apply gravity
        if not player.on_ground then
            player.vy = player.vy + GRAVITY * dt
        end

        -- Move player
        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt

        -- Clamp to screen
        if player.x < 30 then player.x = 30 end
        if player.x + player.w > SCREEN_W - 30 then player.x = SCREEN_W - 30 - player.w end

        -- Platform collision (snap to surface)
        player.on_ground = false
        for pi, plat in ipairs(platforms) do
            if on_platform_range(plat, player.x + player.w / 2) then
                local surf = platform_y_at(plat, player.x + player.w / 2)
                local feet = player.y + player.h
                if feet >= surf - 4 and feet <= surf + 12 and player.vy >= 0 then
                    player.y = surf - player.h
                    player.vy = 0
                    player.on_ground = true
                    if player.jumping then
                        player.jumping = false
                        dust:emit(5, player.x + player.w / 2, surf)
                    end
                    break
                end
            end
        end

        -- Fall off screen
        if player.y > SCREEN_H + 50 then
            lives = lives - 1
            if lives <= 0 then
                state = STATE.GAME_OVER
            else
                respawn_player()
            end
            return
        end

        -- Check for ladder entry
        if lurek.input.isActionDown("up") or lurek.input.isActionDown("down") then
            local lad = find_ladder(player.x, player.y, player.w, player.h)
            if lad then
                player.climbing = true
                player.x = lad.x - player.w / 2
                player.vy = 0
                player.vx = 0
            end
        end
    else
        -- Climbing movement
        local lad = find_ladder(player.x, player.y, player.w, player.h)
        if lad then
            if lurek.input.isActionDown("up") then
                player.y = player.y - LADDER_CLIMB_SPEED * dt
            elseif lurek.input.isActionDown("down") then
                player.y = player.y + LADDER_CLIMB_SPEED * dt
            end

            -- Reached top or bottom of ladder → dismount
            if player.y + player.h <= lad.top + 4 then
                player.y = lad.top - player.h
                player.climbing = false
                player.on_ground = true
            elseif player.y + player.h >= lad.bottom then
                player.y = lad.bottom - player.h
                player.climbing = false
                player.on_ground = true
            end

            -- Jump off ladder
            if lurek.input.wasActionPressed("jump") then
                player.climbing = false
                player.vy = PLAYER_JUMP_VEL * 0.7
                player.on_ground = false
                player.jumping = true
            end
        else
            player.climbing = false
        end
    end

    -- ── Hammer power-up ──────────────────────────────────────────────
    if not hammer.collected and hammer_spawn then
        local hx, hy = hammer_spawn.x, hammer_spawn.y
        if rects_overlap(player.x, player.y, player.w, player.h, hx, hy, 14, 14) then
            hammer.active = true
            hammer.timer = HAMMER_DURATION
            hammer.collected = true
        end
    end

    if hammer.active then
        hammer.timer = hammer.timer - dt
        if hammer.timer <= 0 then
            hammer.active = false
        end
    end

    -- ── DK barrel throw ──────────────────────────────────────────────
    barrel_timer = barrel_timer + dt
    if barrel_timer >= barrel_interval then
        barrel_timer = 0
        spawn_barrel()
    end

    -- ── Update barrels ───────────────────────────────────────────────
    for i = #barrels, 1, -1 do
        local b = barrels[i]
        if b.active then
            if b.on_ladder then
                -- Barrel going down a ladder
                b.y = b.y + BARREL_SPEED * 0.6 * dt
                if b.y >= b.ladder_bottom then
                    b.on_ladder = false
                    b.y = b.ladder_bottom - b.r
                    -- Find the next platform below
                    local pi, plat, sy = find_platform(b.x, b.y + b.r, 12)
                    if pi then
                        b.platform_index = pi
                        local sl = platform_slope(plat)
                        b.vx = (sl > 0) and BARREL_SPEED or -BARREL_SPEED
                    end
                end
            else
                -- Rolling on platform
                local pi = b.platform_index
                local plat = platforms[pi]
                if plat then
                    local sl = platform_slope(plat)
                    -- Speed boost going downhill
                    local speed = BARREL_SPEED + math.abs(sl) * 200
                    b.x = b.x + b.vx * (speed / BARREL_SPEED) * dt
                    b.y = platform_y_at(plat, b.x) - b.r

                    -- Check if barrel rolled off platform edge
                    local lx = math.min(plat[1], plat[3])
                    local rx = math.max(plat[1], plat[3])
                    if b.x < lx - b.r or b.x > rx + b.r then
                        -- Check for ladder intersection (30% chance)
                        local took_ladder = false
                        if math.random() < BARREL_LADDER_CHANCE then
                            for _, lad in ipairs(ladders) do
                                if lad.gap_index == pi - 1 or lad.gap_index == pi then
                                    if math.abs(b.x - lad.x) < 20 then
                                        b.on_ladder = true
                                        b.x = lad.x
                                        b.ladder_bottom = lad.bottom
                                        took_ladder = true
                                        break
                                    end
                                end
                            end
                        end

                        if not took_ladder then
                            -- Fall to next platform below
                            if pi > 1 then
                                b.platform_index = pi - 1
                                local np = platforms[pi - 1]
                                -- Reverse direction on new platform
                                local nsl = platform_slope(np)
                                b.vx = (nsl > 0) and BARREL_SPEED or -BARREL_SPEED
                                b.x = math.max(np[1] + b.r, math.min(np[3] - b.r, b.x))
                                b.y = platform_y_at(np, b.x) - b.r
                            else
                                -- Fell off bottom
                                b.active = false
                            end
                        end
                    end
                end
            end

            -- Barrel-player collision
            if b.active then
                local bx, by = b.x - b.r, b.y - b.r
                if rects_overlap(player.x, player.y, player.w, player.h,
                                 bx, by, b.r * 2, b.r * 2) then
                    if hammer.active then
                        -- Smash barrel
                        sparks:emit(15, b.x, b.y)
                        score = score + 300
                        b.active = false
                    else
                        -- Player hit
                        lives = lives - 1
                        sparks:emit(10, player.x + player.w / 2, player.y + player.h / 2)
                        if lives <= 0 then
                            state = STATE.GAME_OVER
                        else
                            respawn_player()
                            barrels = {}
                            barrel_timer = 0
                        end
                        return
                    end
                end

                -- Jumped over barrel bonus (player above barrel, close x)
                if player.jumping and player.vy < 0 then
                    local px_center = player.x + player.w / 2
                    local dx = math.abs(px_center - b.x)
                    local dy = (b.y - b.r) - (player.y + player.h)
                    if dx < 20 and dy > 0 and dy < 30 and not b.jumped_over then
                        b.jumped_over = true
                        score = score + 100
                    end
                end
            end
        end
    end

    -- Remove inactive barrels
    for i = #barrels, 1, -1 do
        if not barrels[i].active then table.remove(barrels, i) end
    end

    -- ── Win condition: player reached top platform near Pauline ───────
    if player.on_ground then
        local px_center = player.x + player.w / 2
        local py_feet = player.y + player.h
        -- Check if on platform 6
        if on_platform_range(platforms[6], px_center) then
            local surf = platform_y_at(platforms[6], px_center)
            if math.abs(py_feet - surf) < 10 then
                -- Check near Pauline
                if math.abs(px_center - pauline.x) < 80 then
                    state = STATE.WIN_ANIM
                    win_timer = 0
                    score = score + 1000
                    heart_scale.v = 0
                    heart_tween = lurek.tween.to(heart_scale, 0.6, { v = 1 })
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  Drawing helpers
-- ═══════════════════════════════════════════════════════════════════════════

-- Draw DK as a brown rectangle stack
local function draw_dk()
    local x, y = dk.x, dk.y
    -- Body
    lurek.render.setColor(0.45, 0.25, 0.1, 1)
    lurek.render.rectangle("fill", x + 4, y + 16, 32, 28)
    -- Head
    lurek.render.setColor(0.55, 0.3, 0.12, 1)
    lurek.render.rectangle("fill", x + 8, y, 24, 18)
    -- Eyes
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.rectangle("fill", x + 14, y + 4, 5, 5)
    lurek.render.rectangle("fill", x + 23, y + 4, 5, 5)
    lurek.render.setColor(0, 0, 0, 1)
    lurek.render.rectangle("fill", x + 16, y + 5, 3, 3)
    lurek.render.rectangle("fill", x + 25, y + 5, 3, 3)
    -- Mouth
    lurek.render.setColor(0.3, 0.15, 0.05, 1)
    lurek.render.rectangle("fill", x + 15, y + 12, 10, 4)
    -- Arms (right arm animates during throw)
    lurek.render.setColor(0.45, 0.25, 0.1, 1)
    lurek.render.rectangle("fill", x - 4, y + 18, 8, 20)  -- left arm
    local arm_offset = math.floor(dk.arm_angle * 12)
    lurek.render.rectangle("fill", x + 36, y + 18 - arm_offset, 8, 20)  -- right arm
    -- Legs
    lurek.render.setColor(0.4, 0.2, 0.08, 1)
    lurek.render.rectangle("fill", x + 8, y + 44, 10, 8)
    lurek.render.rectangle("fill", x + 22, y + 44, 10, 8)
end

-- Draw Mario (player) as blue/red rectangles
local function draw_player()
    local x, y = player.x, player.y
    local flash = hammer.active and (math.floor(hammer.timer * 8) % 2 == 0)
    -- Hat (red)
    if flash then
        lurek.render.setColor(1, 1, 0, 1)
    else
        lurek.render.setColor(0.9, 0.15, 0.1, 1)
    end
    lurek.render.rectangle("fill", x, y, player.w, 6)
    -- Face
    lurek.render.setColor(0.95, 0.75, 0.55, 1)
    lurek.render.rectangle("fill", x + 2, y + 6, 12, 6)
    -- Body (blue overalls)
    if flash then
        lurek.render.setColor(1, 1, 0, 1)
    else
        lurek.render.setColor(0.1, 0.2, 0.8, 1)
    end
    lurek.render.rectangle("fill", x + 1, y + 12, 14, 8)
    -- Legs
    lurek.render.setColor(0.1, 0.2, 0.8, 1)
    lurek.render.rectangle("fill", x + 2, y + 20, 5, 4)
    lurek.render.rectangle("fill", x + 9, y + 20, 5, 4)

    -- Hammer (if active, draw above player)
    if hammer.active then
        lurek.render.setColor(0.6, 0.4, 0.2, 1)
        local hx = x + (player.facing > 0 and player.w or -10)
        local hy = y - 4
        -- Handle
        lurek.render.rectangle("fill", hx + 2, hy, 4, 14)
        -- Head (T-shape)
        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        lurek.render.rectangle("fill", hx - 2, hy - 4, 12, 6)
    end
end

-- Draw Pauline
local function draw_pauline()
    local x, y = pauline.x, pauline.y
    -- Hair
    lurek.render.setColor(0.9, 0.75, 0.2, 1)
    lurek.render.rectangle("fill", x + 2, y - 4, 10, 6)
    -- Dress (pink)
    lurek.render.setColor(1, 0.4, 0.6, 1)
    lurek.render.rectangle("fill", x, y + 2, 14, 16)
    -- Face
    lurek.render.setColor(0.95, 0.75, 0.55, 1)
    lurek.render.rectangle("fill", x + 3, y - 2, 8, 6)
end

-- Draw a barrel
local function draw_barrel(b)
    lurek.render.setColor(0.6, 0.35, 0.1, 1)
    lurek.render.circle("fill", b.x, b.y, b.r)
    -- Barrel bands
    lurek.render.setColor(0.4, 0.22, 0.05, 1)
    lurek.render.circle("line", b.x, b.y, b.r)
    lurek.render.circle("line", b.x, b.y, b.r * 0.5)
end

-- Draw a ladder
local function draw_ladder(lad)
    local x, top, bot = lad.x, lad.top, lad.bottom
    -- Two vertical rails
    lurek.render.setColor(0.6, 0.8, 1, 0.7)
    lurek.render.rectangle("fill", x - 6, top, 2, bot - top)
    lurek.render.rectangle("fill", x + 4, top, 2, bot - top)
    -- Rungs
    local rung_spacing = 12
    local ny = math.floor((bot - top) / rung_spacing)
    for i = 0, ny do
        local ry = top + i * rung_spacing
        lurek.render.rectangle("fill", x - 6, ry, 12, 2)
    end
end

-- Draw hammer pickup
local function draw_hammer_pickup()
    if hammer.collected then return end
    if not hammer_spawn then return end
    local x, y = hammer_spawn.x, hammer_spawn.y
    local pulse = 0.7 + 0.3 * math.sin(lurek.timer.getTime() * 6)
    -- Handle
    lurek.render.setColor(0.6, 0.4, 0.2, pulse)
    lurek.render.rectangle("fill", x + 4, y + 4, 4, 10)
    -- Head (T-shape)
    lurek.render.setColor(0.7, 0.7, 0.7, pulse)
    lurek.render.rectangle("fill", x, y, 14, 6)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  lurek.render — world drawing
-- ═══════════════════════════════════════════════════════════════════════════
function lurek.render()
    cam:apply()

    if state == STATE.TITLE then
        -- DK silhouette art (large rectangles)
        lurek.render.setColor(0.4, 0.22, 0.08, 1)
        -- Body
        lurek.render.rectangle("fill", SCREEN_W / 2 - 60, 140, 120, 100)
        -- Head
        lurek.render.rectangle("fill", SCREEN_W / 2 - 40, 100, 80, 50)
        -- Arms
        lurek.render.rectangle("fill", SCREEN_W / 2 - 80, 160, 25, 60)
        lurek.render.rectangle("fill", SCREEN_W / 2 + 55, 160, 25, 60)
        -- Legs
        lurek.render.rectangle("fill", SCREEN_W / 2 - 40, 240, 30, 40)
        lurek.render.rectangle("fill", SCREEN_W / 2 + 10, 240, 30, 40)
        -- Eyes
        lurek.render.setColor(1, 0.3, 0.1, 1)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 20, 115, 14, 12)
        lurek.render.rectangle("fill", SCREEN_W / 2 + 8, 115, 14, 12)

        cam:reset()
        return
    end

    -- ── Draw platforms ────────────────────────────────────────────────
    for _, plat in ipairs(platforms) do
        lurek.render.setColor(0.8, 0.15, 0.1, 1)
        -- Draw platform as thick line (two rectangles for thickness)
        local x1, y1, x2, y2 = plat[1], plat[2], plat[3], plat[4]
        local len = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        local segments = 20
        for s = 0, segments - 1 do
            local t0 = s / segments
            local t1 = (s + 1) / segments
            local sx = x1 + t0 * (x2 - x1)
            local sy = y1 + t0 * (y2 - y1)
            local ex = x1 + t1 * (x2 - x1)
            local sw = (ex - sx)
            lurek.render.rectangle("fill", sx, sy - 3, sw + 1, 8)
        end
        -- Girder detail lines
        lurek.render.setColor(0.6, 0.1, 0.08, 1)
        for s = 0, segments - 1, 2 do
            local t0 = s / segments
            local sx = x1 + t0 * (x2 - x1)
            local sy = y1 + t0 * (y2 - y1)
            local sw = (x2 - x1) / segments
            lurek.render.rectangle("fill", sx, sy - 1, sw, 3)
        end
    end

    -- ── Draw ladders ──────────────────────────────────────────────────
    for _, lad in ipairs(ladders) do
        draw_ladder(lad)
    end

    -- ── Draw hammer pickup ────────────────────────────────────────────
    draw_hammer_pickup()

    -- ── Draw barrels ──────────────────────────────────────────────────
    for _, b in ipairs(barrels) do
        if b.active then draw_barrel(b) end
    end

    -- ── Draw characters ───────────────────────────────────────────────
    draw_dk()
    draw_pauline()
    draw_player()

    -- ── Draw particles ────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    sparks:draw()
    dust:draw()

    -- ── Win animation heart ───────────────────────────────────────────
    if state == STATE.WIN_ANIM then
        local hs = heart_scale.v
        if hs > 0 then
            local hx = (player.x + pauline.x) / 2 + 5
            local hy = math.min(player.y, pauline.y) - 30
            lurek.render.setColor(1, 0.2, 0.4, hs)
            -- Heart shape from rectangles
            local s = hs * 12
            lurek.render.rectangle("fill", hx - s, hy, s, s)
            lurek.render.rectangle("fill", hx, hy, s, s)
            lurek.render.rectangle("fill", hx - s * 0.5, hy + s * 0.5, s, s)
        end
    end

    cam:reset()
end

-- ═══════════════════════════════════════════════════════════════════════════
--  lurek.render_ui — HUD overlay (screen space)
-- ═══════════════════════════════════════════════════════════════════════════
function lurek.render_ui()
    if state == STATE.TITLE then
        -- Title text
        lurek.render.setColor(1, 0.85, 0.2, 1)
        lurek.render.print("DONKEY KONG", SCREEN_W / 2 - 110, 40, 3)

        -- Blink prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.9)
            lurek.render.print("Press SPACE to start", SCREEN_W / 2 - 100, 340, 1.5)
        end

        -- Controls
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        lurek.render.print("A/D or Arrows: Move   W/S: Climb   Space: Jump", SCREEN_W / 2 - 200, 400, 1)

        -- FPS
        lurek.render.setColor(0.4, 0.4, 0.5, 1)
        lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, 4, 1)
        return
    end

    if state == STATE.GAME_OVER then
        lurek.render.setColor(0.9, 0.15, 0.1, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 90, SCREEN_H / 2 - 30, 3)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.print("Score: " .. score, SCREEN_W / 2 - 50, SCREEN_H / 2 + 20, 1.5)
        lurek.render.print("Press SPACE", SCREEN_W / 2 - 55, SCREEN_H / 2 + 50, 1)

        lurek.render.setColor(0.4, 0.4, 0.5, 1)
        lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, 4, 1)
        return
    end

    if state == STATE.WIN_ANIM then
        lurek.render.setColor(1, 0.85, 0.3, 1)
        lurek.render.print("RESCUED!", SCREEN_W / 2 - 70, 20, 2.5)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.print("Score: " .. score .. "   Wave: " .. wave, SCREEN_W / 2 - 80, 60, 1.2)

        lurek.render.setColor(0.4, 0.4, 0.5, 1)
        lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, 4, 1)
        return
    end

    -- ── Playing HUD ───────────────────────────────────────────────────
    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE: " .. score, 10, 6, 1.2)

    -- Lives
    lurek.render.setColor(0.9, 0.15, 0.1, 1)
    for i = 1, lives do
        lurek.render.rectangle("fill", SCREEN_W - 30 * i, 6, 20, 12)
    end

    -- Wave
    lurek.render.setColor(0.7, 0.7, 0.8, 1)
    lurek.render.print("WAVE " .. wave, SCREEN_W / 2 - 30, 6, 1.2)

    -- Hammer timer
    if hammer.active then
        lurek.render.setColor(1, 0.9, 0.2, 1)
        local bar_w = 80 * (hammer.timer / HAMMER_DURATION)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 40, 24, bar_w, 6)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.print("HAMMER!", SCREEN_W / 2 - 28, 20, 1)
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.5, 1)
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, SCREEN_H - 16, 1)
end
