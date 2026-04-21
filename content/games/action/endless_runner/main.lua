-- ============================================================================
--  Endless Runner — Sprint through an infinite landscape, dodge or die
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/endless_runner
--
--  Controls (bound as input actions — see lurek.init):
--    jump   : Space / W / Up           (double jump after 500m)
--    slide  : S / Down                 (duck under low barriers)
--    quit   : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local GROUND_Y            = 500
local PLAYER_X            = 120
local GRAVITY             = 1800
local JUMP_FORCE          = -620
local PLAYER_W, PLAYER_H  = 28, 48
local SLIDE_H             = 20
local COIN_SIZE           = 12
local COIN_SCORE          = 50
local SPEED_START         = 300
local SPEED_INC           = 20
local SPEED_INC_INTERVAL  = 500
local SPEED_CAP           = 600
local DOUBLE_JUMP_DIST    = 500
local OBSTACLE_GAP_MIN    = 220
local OBSTACLE_GAP_MAX    = 380

-- ── Scene state ───────────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, DEAD = 3 }
local scene = STATE.TITLE

-- ── Parallax layers ───────────────────────────────────────────────────────
local layers = {
    { speed = 0.15, y = 180, h = 200, color = {0.35, 0.45, 0.65, 0.6}, shapes = {} },  -- mountains
    { speed = 0.35, y = 300, h = 150, color = {0.2,  0.5,  0.25, 0.7}, shapes = {} },  -- trees
    { speed = 0.7,  y = 440, h = 60,  color = {0.45, 0.55, 0.35, 0.5}, shapes = {} },  -- ground detail
}

-- ── Player state ──────────────────────────────────────────────────────────
local player = {
    y       = GROUND_Y - PLAYER_H,
    vy      = 0,
    on_ground = true,
    sliding = false,
    jumps   = 0,
    alive   = true,
    stumble_timer = 0,
    rotation = 0,
}

-- ── World state ───────────────────────────────────────────────────────────
local scroll_speed   = SPEED_START
local distance       = 0
local coins_collected = 0
local high_score     = 0
local obstacles      = {}
local coins          = {}
local world_offset   = 0
local next_obstacle  = 300

-- ── Particles ─────────────────────────────────────────────────────────────
local dust_ps       = nil
local coin_ps       = nil
local death_ps      = nil

-- ── Tween targets ─────────────────────────────────────────────────────────
local coin_flash    = { scale = 1 }
local speed_flash   = { alpha = 0 }
local title_blink   = 0
-- ── Parallax init ─────────────────────────────────────────────────────────
local function generate_layer_shapes(layer)
    layer.shapes = {}
    local x = 0
    while x < SCREEN_W + 200 do
        local w = math.random(40, 120)
        local h = math.random(20, layer.h)
        layer.shapes[#layer.shapes + 1] = { x = x, w = w, h = h }
        x = x + w + math.random(10, 60)
    end
end

-- ── Obstacle types ────────────────────────────────────────────────────────
-- tall: must jump over   low: must slide under   gap: must jump across
local OBS_TYPES = { "tall", "low", "gap" }

local function spawn_obstacle()
    local kind = OBS_TYPES[math.random(1, #OBS_TYPES)]
    local obs = { x = SCREEN_W + 50, kind = kind }
    if kind == "tall" then
        obs.w = 30
        obs.h = 60
        obs.y = GROUND_Y - obs.h
    elseif kind == "low" then
        obs.w = 50
        obs.h = 25
        obs.y = GROUND_Y - 55
    else -- gap
        obs.w = 80
        obs.h = 20
        obs.y = GROUND_Y
        obs.is_gap = true
    end
    obstacles[#obstacles + 1] = obs
end

local function spawn_coin(obs_x)
    local cy = math.random(GROUND_Y - 120, GROUND_Y - 50)
    local cx = obs_x + math.random(-40, 80)
    coins[#coins + 1] = { x = cx, y = cy, collected = false }
end

-- ── Collision helpers ─────────────────────────────────────────────────────
local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function get_player_rect()
    local h = player.sliding and SLIDE_H or PLAYER_H
    local y = player.sliding and (GROUND_Y - SLIDE_H) or player.y
    return PLAYER_X, y, PLAYER_W, h
end

-- ── Reset / new game ─────────────────────────────────────────────────────
local function reset_game()
    player.y         = GROUND_Y - PLAYER_H
    player.vy        = 0
    player.on_ground = true
    player.sliding   = false
    player.jumps     = 0
    player.alive     = true
    player.stumble_timer = 0
    player.rotation  = 0

    scroll_speed    = SPEED_START
    distance        = 0
    coins_collected = 0
    obstacles       = {}
    coins           = {}
    world_offset    = 0
    next_obstacle   = 300
    scene           = STATE.PLAYING

    coin_flash.scale  = 1
    speed_flash.alpha = 0

    for _, layer in ipairs(layers) do generate_layer_shapes(layer) end
end

-- ── Player physics ────────────────────────────────────────────────────────
local function update_player(dt)
    if not player.alive then
        -- Death stumble animation
        player.stumble_timer = player.stumble_timer + dt
        player.rotation = player.rotation + dt * 8
        player.y = player.y + 200 * dt
        if player.y > SCREEN_H + 100 then
            if distance > high_score then high_score = distance end
            scene = STATE.DEAD
        end
        return
    end

    -- Jump input
    local max_jumps = distance >= DOUBLE_JUMP_DIST and 2 or 1
    if lurek.input.wasActionPressed("jump") then
        if player.jumps < max_jumps then
            player.vy = JUMP_FORCE
            player.on_ground = false
            player.jumps = player.jumps + 1
        end
    end

    -- Slide input
    player.sliding = lurek.input.isActionDown("slide") and player.on_ground

    -- Gravity
    if not player.on_ground then
        player.vy = player.vy + GRAVITY * dt
        player.y  = player.y + player.vy * dt
    end

    -- Land on ground
    if player.y >= GROUND_Y - PLAYER_H then
        player.y = GROUND_Y - PLAYER_H
        player.vy = 0
        if not player.on_ground then
            player.on_ground = true
            player.jumps = 0
            -- Landing dust
            if dust_ps then dust_ps:emit(8, PLAYER_X + PLAYER_W / 2, GROUND_Y) end
        end
    end
end

-- ── Gap death check ───────────────────────────────────────────────────────
local function check_gap_death()
    if not player.on_ground then return false end
    local px, _, pw, _ = get_player_rect()
    for _, obs in ipairs(obstacles) do
        if obs.is_gap then
            local pcx = px + pw / 2
            if pcx > obs.x + 10 and pcx < obs.x + obs.w - 10 then
                return true
            end
        end
    end
    return false
end

-- ── Obstacle / coin update ────────────────────────────────────────────────
local function update_world(dt)
    local move = scroll_speed * dt
    distance = distance + move
    world_offset = world_offset + move

    -- Speed increase
    local speed_tier = math.floor(distance / SPEED_INC_INTERVAL)
    local target_speed = math.min(SPEED_START + speed_tier * SPEED_INC, SPEED_CAP)
    if target_speed > scroll_speed then
        scroll_speed = target_speed
        speed_flash.alpha = 1
        lurek.tween.to(speed_flash, { alpha = 0 }, 1.0, "outQuad")
    end

    -- Scroll obstacles
    for i = #obstacles, 1, -1 do
        obstacles[i].x = obstacles[i].x - move
        if obstacles[i].x + (obstacles[i].w or 80) < -50 then
            table.remove(obstacles, i)
        end
    end

    -- Scroll coins
    for i = #coins, 1, -1 do
        coins[i].x = coins[i].x - move
        if coins[i].x < -30 then
            table.remove(coins, i)
        end
    end

    -- Spawn obstacles
    next_obstacle = next_obstacle - move
    if next_obstacle <= 0 then
        spawn_obstacle()
        if math.random() < 0.6 then
            spawn_coin(SCREEN_W + 50)
        end
        next_obstacle = math.random(OBSTACLE_GAP_MIN, OBSTACLE_GAP_MAX)
    end

    -- Parallax scrolling
    for _, layer in ipairs(layers) do
        for _, s in ipairs(layer.shapes) do
            s.x = s.x - move * layer.speed
        end
        -- Recycle shapes that scroll off left
        while #layer.shapes > 0 and layer.shapes[1].x + layer.shapes[1].w < -20 do
            table.remove(layer.shapes, 1)
        end
        -- Add new shapes on right
        local last = layer.shapes[#layer.shapes]
        local edge = last and (last.x + last.w) or 0
        while edge < SCREEN_W + 200 do
            local w = math.random(40, 120)
            local h = math.random(20, layer.h)
            local gap = math.random(10, 60)
            layer.shapes[#layer.shapes + 1] = { x = edge + gap, w = w, h = h }
            edge = edge + gap + w
        end
    end
end

-- ── Collision detection ───────────────────────────────────────────────────
local function check_collisions()
    local px, py, pw, ph = get_player_rect()

    -- vs obstacles
    for _, obs in ipairs(obstacles) do
        if not obs.is_gap then
            if rects_overlap(px, py, pw, ph, obs.x, obs.y, obs.w, obs.h) then
                player.alive = false
                player.stumble_timer = 0
                player.rotation = 0
                if death_ps then
                    death_ps:emit(20, PLAYER_X + PLAYER_W / 2, player.y + PLAYER_H / 2)
                end
                return
            end
        end
    end

    -- Gap death
    if check_gap_death() then
        player.alive = false
        player.stumble_timer = 0
        player.rotation = 0
        if death_ps then
            death_ps:emit(15, PLAYER_X + PLAYER_W / 2, GROUND_Y)
        end
        return
    end

    -- vs coins
    for _, c in ipairs(coins) do
        if not c.collected then
            local cdist_x = (PLAYER_X + PLAYER_W / 2) - c.x
            local cdist_y = (py + ph / 2) - c.y
            if cdist_x * cdist_x + cdist_y * cdist_y < (COIN_SIZE + pw / 2) * (COIN_SIZE + pw / 2) then
                c.collected = true
                coins_collected = coins_collected + 1
                if coin_ps then coin_ps:emit(10, c.x, c.y) end
                coin_flash.scale = 1.8
                lurek.tween.to(coin_flash, { scale = 1.0 }, 0.3, "outBack")
            end
        end
    end
end

-- ── Draw helpers ──────────────────────────────────────────────────────────
local function draw_parallax()
    for _, layer in ipairs(layers) do
        local c = layer.color
        lurek.render.setColor(c[1], c[2], c[3], c[4])
        for _, s in ipairs(layer.shapes) do
            local base_y = layer.y + (layer.h - s.h)
            lurek.render.rectangle("fill", s.x, base_y, s.w, s.h)
        end
    end
end

local function draw_ground()
    lurek.render.setColor(0.35, 0.25, 0.15, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y)
    lurek.render.setColor(0.5, 0.4, 0.2, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y, SCREEN_W, 3)
end

local function draw_player_char()
    if not player.alive then
        -- Stumble + fall rotation
        local cx = PLAYER_X + PLAYER_W / 2
        local cy = player.y + PLAYER_H / 2
        lurek.render.setColor(0.9, 0.3, 0.2, 1)
        local s = math.sin(player.rotation)
        local co = math.cos(player.rotation)
        local hw, hh = PLAYER_W / 2, PLAYER_H / 2
        local x1, y1 = cx + (-hw * co - (-hh) * s), cy + (-hw * s + (-hh) * co)
        local x2, y2 = cx + ( hw * co - (-hh) * s), cy + ( hw * s + (-hh) * co)
        local x3, y3 = cx + ( hw * co -   hh  * s), cy + ( hw * s +   hh  * co)
        local x4, y4 = cx + (-hw * co -   hh  * s), cy + (-hw * s +   hh  * co)
        lurek.render.line(x1, y1, x2, y2)
        lurek.render.line(x2, y2, x3, y3)
        lurek.render.line(x3, y3, x4, y4)
        lurek.render.line(x4, y4, x1, y1)
        return
    end

    if player.sliding then
        lurek.render.setColor(0.2, 0.7, 1.0, 1)
        lurek.render.rectangle("fill", PLAYER_X, GROUND_Y - SLIDE_H, PLAYER_W + 8, SLIDE_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.rectangle("fill", PLAYER_X + PLAYER_W - 2, GROUND_Y - SLIDE_H + 4, 8, 6)
    else
        -- Body
        lurek.render.setColor(0.2, 0.7, 1.0, 1)
        lurek.render.rectangle("fill", PLAYER_X, player.y, PLAYER_W, PLAYER_H)
        -- Head
        lurek.render.setColor(0.9, 0.75, 0.6, 1)
        lurek.render.circle("fill", PLAYER_X + PLAYER_W / 2, player.y - 6, 10)
        -- Eye
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.circle("fill", PLAYER_X + PLAYER_W / 2 + 4, player.y - 8, 3)
        lurek.render.setColor(0, 0, 0, 1)
        lurek.render.circle("fill", PLAYER_X + PLAYER_W / 2 + 5, player.y - 8, 1.5)
        -- Animated legs
        local leg_phase = math.sin(distance * 0.08) * 6
        lurek.render.setColor(0.15, 0.5, 0.85, 1)
        lurek.render.rectangle("fill", PLAYER_X + 4,  player.y + PLAYER_H, 6, 8 + leg_phase)
        lurek.render.rectangle("fill", PLAYER_X + 18, player.y + PLAYER_H, 6, 8 - leg_phase)
    end
end

local function draw_obstacles()
    for _, obs in ipairs(obstacles) do
        if obs.is_gap then
            lurek.render.setColor(0.1, 0.08, 0.05, 1)
            lurek.render.rectangle("fill", obs.x, obs.y, obs.w, SCREEN_H - obs.y)
            lurek.render.setColor(0.9, 0.2, 0.1, 0.7)
            lurek.render.rectangle("fill", obs.x, obs.y, 4, 20)
            lurek.render.rectangle("fill", obs.x + obs.w - 4, obs.y, 4, 20)
        elseif obs.kind == "tall" then
            lurek.render.setColor(0.7, 0.15, 0.1, 1)
            lurek.render.rectangle("fill", obs.x, obs.y, obs.w, obs.h)
            lurek.render.setColor(0.9, 0.8, 0.1, 0.8)
            lurek.render.rectangle("fill", obs.x + 4, obs.y + obs.h / 2 - 3, obs.w - 8, 6)
        elseif obs.kind == "low" then
            lurek.render.setColor(0.6, 0.4, 0.1, 1)
            lurek.render.rectangle("fill", obs.x, obs.y, obs.w, obs.h)
            lurek.render.setColor(0.5, 0.35, 0.1, 1)
            lurek.render.rectangle("fill", obs.x, obs.y + obs.h, 4, GROUND_Y - obs.y - obs.h)
            lurek.render.rectangle("fill", obs.x + obs.w - 4, obs.y + obs.h, 4, GROUND_Y - obs.y - obs.h)
        end
    end
end

local function draw_coins()
    for _, c in ipairs(coins) do
        if not c.collected then
            local wobble = math.abs(math.sin(distance * 0.05 + c.x * 0.1))
            local w = COIN_SIZE * (0.4 + 0.6 * wobble)
            lurek.render.setColor(1.0, 0.85, 0.1, 1)
            lurek.render.circle("fill", c.x, c.y, w)
            lurek.render.setColor(0.9, 0.7, 0.0, 1)
            lurek.render.circle("fill", c.x, c.y, w * 0.6)
        end
    end
end

-- ── load ──────────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Endless Runner — Lurek2D")
    lurek.render.setBackgroundColor(0.4, 0.6, 0.9)

    lurek.input.bind("jump",  {"space", "w", "up"})
    lurek.input.bind("slide", {"s", "down"})
    lurek.input.bind("quit",  {"escape"})
    lurek.input.bind("start", {"return"})

    -- Particle: landing dust
    dust_ps = lurek.particle.newSystem({
        maxParticles = 40,
        emissionRate = 0,
        lifetimeMin  = 0.15,
        lifetimeMax  = 0.4,
        speedMin     = 20,
        speedMax     = 60,
        direction    = 4.71,
        spread       = 1.2,
        gravityY     = 50,
        sizes        = {4, 1},
        colors       = {0.6, 0.5, 0.3, 0.8,  0.6, 0.5, 0.3, 0},
    })

    -- Particle: coin collect sparkle
    coin_ps = lurek.particle.newSystem({
        maxParticles = 50,
        emissionRate = 0,
        lifetimeMin  = 0.2,
        lifetimeMax  = 0.5,
        speedMin     = 40,
        speedMax     = 100,
        direction    = 0,
        spread       = 6.28,
        gravityY     = -20,
        sizes        = {5, 1},
        colors       = {1, 0.9, 0.2, 1,  1, 0.7, 0.0, 0},
    })

    -- Particle: death poof
    death_ps = lurek.particle.newSystem({
        maxParticles = 60,
        emissionRate = 0,
        lifetimeMin  = 0.3,
        lifetimeMax  = 0.7,
        speedMin     = 30,
        speedMax     = 90,
        direction    = 0,
        spread       = 6.28,
        gravityY     = 30,
        sizes        = {6, 2},
        colors       = {0.8, 0.2, 0.1, 1,  0.4, 0.1, 0.05, 0},
    })

    for _, layer in ipairs(layers) do generate_layer_shapes(layer) end
    math.randomseed(os.time())
end

-- ── update ────────────────────────────────────────────────────────────────
function lurek.process(dt)
    lurek.tween.update(dt)
    dust_ps:update(dt)
    coin_ps:update(dt)
    death_ps:update(dt)

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if scene == STATE.TITLE then
        title_blink = title_blink + dt
        -- Scroll parallax gently on title
        for _, layer in ipairs(layers) do
            for _, s in ipairs(layer.shapes) do
                s.x = s.x - 60 * layer.speed * dt
            end
            while #layer.shapes > 0 and layer.shapes[1].x + layer.shapes[1].w < -20 do
                table.remove(layer.shapes, 1)
            end
            local last = layer.shapes[#layer.shapes]
            local edge = last and (last.x + last.w) or 0
            while edge < SCREEN_W + 200 do
                local w = math.random(40, 120)
                local h = math.random(20, layer.h)
                local gap = math.random(10, 60)
                layer.shapes[#layer.shapes + 1] = { x = edge + gap, w = w, h = h }
                edge = edge + gap + w
            end
        end
        if lurek.input.wasActionPressed("start") then reset_game() end
        return
    end

    if scene == STATE.DEAD then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("start") then reset_game() end
        return
    end

    -- PLAYING
    update_player(dt)
    if player.alive then
        update_world(dt)
        check_collisions()
    end
end

-- ── render (world space — parallax + player + obstacles) ──────────────────
function lurek.render()
    -- Sky gradient band near horizon
    lurek.render.setColor(0.55, 0.75, 1.0, 0.3)
    lurek.render.rectangle("fill", 0, GROUND_Y - 80, SCREEN_W, 80)

    draw_parallax()

    if scene == STATE.TITLE then
        draw_ground()
        return
    end

    draw_ground()
    draw_obstacles()
    draw_coins()
    draw_player_char()

    -- Particles (world space)
    lurek.render.setColor(1, 1, 1, 1)
    dust_ps:draw()
    coin_ps:draw()
    death_ps:draw()
end

-- ── render_ui (screen space — HUD, title, death) ──────────────────────────
function lurek.render_ui()
    if scene == STATE.TITLE then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("ENDLESS RUNNER", SCREEN_W / 2 - 160, 140, 3)

        lurek.render.setColor(0.9, 0.85, 0.7, 1)
        lurek.render.print("Run. Jump. Slide. Survive.", SCREEN_W / 2 - 115, 210, 1.2)

        if high_score > 0 then
            lurek.render.setColor(1, 0.85, 0.1, 1)
            lurek.render.print("HIGH SCORE: " .. math.floor(high_score) .. "m", SCREEN_W / 2 - 80, 270, 1.2)
        end

        local alpha = 0.4 + 0.6 * math.abs(math.sin(title_blink * 2.5))
        lurek.render.setColor(1, 1, 0.3, alpha)
        lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 60, 340, 1.5)

        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("Jump: Space/W/Up   Slide: S/Down   Quit: Escape", SCREEN_W / 2 - 210, 430, 1)
        lurek.render.print("Double jump unlocks at 500m!", SCREEN_W / 2 - 120, 460, 1)

        lurek.render.setColor(0.4, 0.4, 0.4, 1)
        lurek.render.print(tostring(lurek.timer.getFPS()) .. " FPS", SCREEN_W - 80, SCREEN_H - 18, 1)
        return
    end

    -- ── HUD ───────────────────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("DISTANCE", 10, 8, 1)
    lurek.render.setColor(0.3, 1, 0.5, 1)
    lurek.render.print(math.floor(distance) .. "m", 90, 8, 1.1)

    lurek.render.setColor(1, 0.85, 0.1, 1)
    lurek.render.print("COINS", 10, 30, 1)
    lurek.render.setColor(1, 0.9, 0.3, 1)
    lurek.render.print(tostring(coins_collected), 65, 30, coin_flash.scale)

    local total = math.floor(distance) + coins_collected * COIN_SCORE
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE", SCREEN_W / 2 - 40, 8, 1)
    lurek.render.setColor(0.4, 0.9, 1, 1)
    lurek.render.print(tostring(total), SCREEN_W / 2 + 20, 8, 1.1)

    lurek.render.setColor(0.8, 0.8, 0.8, 1)
    lurek.render.print("SPEED", SCREEN_W - 130, 8, 1)
    lurek.render.setColor(1, 0.5 + 0.5 * (scroll_speed / SPEED_CAP), 0.2, 1)
    lurek.render.print(math.floor(scroll_speed), SCREEN_W - 70, 8, 1.1)

    -- Speed increase flash
    if speed_flash.alpha > 0.01 then
        lurek.render.setColor(1, 1, 0.3, speed_flash.alpha)
        lurek.render.print("SPEED UP!", SCREEN_W / 2 - 45, SCREEN_H / 2 - 60, 2)
    end

    -- Double jump indicator
    if distance >= DOUBLE_JUMP_DIST then
        lurek.render.setColor(0.3, 0.9, 1, 0.7)
        lurek.render.print("2x JUMP", SCREEN_W - 100, 30, 1)
    end

    if high_score > 0 then
        lurek.render.setColor(1, 0.85, 0.1, 0.5)
        lurek.render.print("BEST: " .. math.floor(high_score) .. "m", SCREEN_W - 130, SCREEN_H - 18, 1)
    end

    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print(tostring(lurek.timer.getFPS()) .. " FPS", 10, SCREEN_H - 18, 1)

    -- ── Death overlay ─────────────────────────────────────────────────────
    if scene == STATE.DEAD then
        lurek.render.setColor(0, 0, 0, 0.55)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 180, SCREEN_H / 2 - 80, 360, 180)

        lurek.render.setColor(0.9, 0.15, 0.1, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 90, SCREEN_H / 2 - 60, 2.5)

        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Distance: " .. math.floor(distance) .. "m", SCREEN_W / 2 - 65, SCREEN_H / 2 + 5, 1.2)
        lurek.render.print("Coins: " .. coins_collected .. " (+" .. coins_collected * COIN_SCORE .. ")", SCREEN_W / 2 - 75, SCREEN_H / 2 + 30, 1)

        local final_score = math.floor(distance) + coins_collected * COIN_SCORE
        lurek.render.setColor(0.4, 0.9, 1, 1)
        lurek.render.print("TOTAL: " .. final_score, SCREEN_W / 2 - 50, SCREEN_H / 2 + 55, 1.3)

        local alpha = 0.4 + 0.6 * math.abs(math.sin(title_blink * 3))
        lurek.render.setColor(1, 1, 0.3, alpha)
        lurek.render.print("PRESS ENTER", SCREEN_W / 2 - 60, SCREEN_H / 2 + 85, 1.2)
    end
end

-- ── keypressed (fallback) ─────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
end
