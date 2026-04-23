-- ============================================================================
-- Bullet Hell — Lurek2D
-- ============================================================================
-- Category : action
-- Source   : content/games/action/bullet_hell/main.lua
-- Run with : cargo run -- content/games/action/bullet_hell
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Player
local PLAYER_SIZE   = 20
local PLAYER_SPEED  = 280
local FOCUS_SPEED   = 120
local HITBOX_RADIUS = 2
local GRAZE_RADIUS  = 20
local FIRE_RATE     = 0.08
local BULLET_SPEED  = 600
local BULLET_W, BULLET_H = 3, 10
local INVULN_TIME   = 2.0

-- Enemy types
local ENEMY_SMALL  = 1
local ENEMY_MEDIUM = 2
local ENEMY_LARGE  = 3
local ENEMY_BOSS   = 4

local ENEMY_HP     = { [ENEMY_SMALL] = 1, [ENEMY_MEDIUM] = 3, [ENEMY_LARGE] = 6, [ENEMY_BOSS] = 40 }
local ENEMY_SIZE   = { [ENEMY_SMALL] = 14, [ENEMY_MEDIUM] = 22, [ENEMY_LARGE] = 32, [ENEMY_BOSS] = 48 }
local ENEMY_POINTS = { [ENEMY_SMALL] = 100, [ENEMY_MEDIUM] = 300, [ENEMY_LARGE] = 600, [ENEMY_BOSS] = 5000 }
local ENEMY_COLORS = {
    [ENEMY_SMALL]  = { 1.0, 0.3, 0.3 },
    [ENEMY_MEDIUM] = { 1.0, 0.6, 0.1 },
    [ENEMY_LARGE]  = { 0.8, 0.2, 1.0 },
    [ENEMY_BOSS]   = { 1.0, 0.0, 0.4 },
}

local ENEMY_BULLET_SPEED = 160
local ENEMY_BULLET_RAD   = 4

-- ---------------------------------------------------------------------------
-- Game state variables
-- ---------------------------------------------------------------------------
local player = { x = SCREEN_W / 2, y = SCREEN_H - 80 }
local player_bullets = {}
local fire_timer = 0
local lives = 3
local bombs = 3
local invuln_timer = 0
local death_flash = 0

local enemies = {}
local enemy_bullets = {}

local score = 0
local high_score = 0
local multiplier = 1.0
local graze_count = 0
local mult_pop_timer = 0
local mult_pop_scale = 1.0

local wave = 0
local wave_timer = 0
local wave_enemies_left = 0
local spawn_queue = {}
local spawn_timer = 0

local particles = {}
local score_pops = {}

local cam = nil
local bomb_flash = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end
local function angle_to(x1, y1, x2, y2) return math.atan2(y2 - y1, x2 - x1) end

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_particles(px, py, r, g, b, count, speed_mult)
    speed_mult = speed_mult or 1
    for _ = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local spd = (40 + math.random() * 160) * speed_mult
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.2 + math.random() * 0.4,
            max_life = 0.6,
            r = r, g = g, b = b,
            size = 1 + math.random() * 3,
        })
    end
end

local function spawn_graze_sparkle(px, py)
    for _ = 1, 3 do
        local angle = math.random() * math.pi * 2
        local spd = 30 + math.random() * 60
        table.insert(particles, {
            x = px, y = py,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.15 + math.random() * 0.15,
            max_life = 0.3,
            r = 1, g = 1, b = 0.5,
            size = 1 + math.random() * 2,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function draw_particles()
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-- ---------------------------------------------------------------------------
-- Score pop (tween-like)
-- ---------------------------------------------------------------------------
local function add_score_pop(x, y, text, r, g, b)
    table.insert(score_pops, {
        x = x, y = y,
        text = text,
        alpha = 1.0,
        dy = 0,
        life = 0.7,
        r = r or 1, g = g or 1, b = b or 0,
    })
end

local function update_score_pops(dt)
    local i = 1
    while i <= #score_pops do
        local sp = score_pops[i]
        sp.dy = sp.dy - 80 * dt
        sp.y = sp.y + sp.dy * dt
        sp.life = sp.life - dt
        sp.alpha = clamp(sp.life / 0.7, 0, 1)
        if sp.life <= 0 then
            table.remove(score_pops, i)
        else
            i = i + 1
        end
    end
end

local function draw_score_pops()
    for _, sp in ipairs(score_pops) do
        lurek.render.setColor(sp.r, sp.g, sp.b, sp.alpha)
        lurek.render.print(sp.text, sp.x, sp.y)
    end
end

-- ---------------------------------------------------------------------------
-- Enemy bullet patterns
-- ---------------------------------------------------------------------------
local function fire_aimed(ex, ey)
    local a = angle_to(ex, ey, player.x, player.y)
    table.insert(enemy_bullets, {
        x = ex, y = ey,
        vx = math.cos(a) * ENEMY_BULLET_SPEED,
        vy = math.sin(a) * ENEMY_BULLET_SPEED,
        grazed = false,
    })
end

local function fire_spiral(ex, ey, base_angle, count)
    count = count or 8
    for i = 0, count - 1 do
        local a = base_angle + (i / count) * math.pi * 2
        table.insert(enemy_bullets, {
            x = ex, y = ey,
            vx = math.cos(a) * ENEMY_BULLET_SPEED * 0.9,
            vy = math.sin(a) * ENEMY_BULLET_SPEED * 0.9,
            grazed = false,
        })
    end
end

local function fire_radial(ex, ey, count)
    count = count or 16
    for i = 0, count - 1 do
        local a = (i / count) * math.pi * 2
        table.insert(enemy_bullets, {
            x = ex, y = ey,
            vx = math.cos(a) * ENEMY_BULLET_SPEED * 0.8,
            vy = math.sin(a) * ENEMY_BULLET_SPEED * 0.8,
            grazed = false,
        })
    end
end

local function fire_curtain(y_pos, gap_x, gap_width)
    for bx = 0, SCREEN_W, 30 do
        if bx < gap_x or bx > gap_x + gap_width then
            table.insert(enemy_bullets, {
                x = bx, y = y_pos,
                vx = 0,
                vy = ENEMY_BULLET_SPEED * 0.7,
                grazed = false,
            })
        end
    end
end

-- ---------------------------------------------------------------------------
-- Wave spawning
-- ---------------------------------------------------------------------------
local function build_wave(w)
    local q = {}
    local is_boss_wave = (w % 5 == 0) and w > 0

    if is_boss_wave then
        -- Mini-boss wave
        table.insert(q, { type = ENEMY_BOSS, x = SCREEN_W / 2, y = -60, delay = 0.5 })
        -- Escort smalls
        for i = 1, 4 do
            table.insert(q, { type = ENEMY_SMALL, x = 100 + i * 140, y = -30, delay = 1.0 + i * 0.3 })
        end
    else
        -- Normal wave: scale with wave number
        local smalls  = math.min(6 + w, 14)
        local mediums = math.floor(w / 2)
        local larges  = math.floor(w / 4)

        local t = 0.3
        for i = 1, smalls do
            local sx = 60 + math.random() * (SCREEN_W - 120)
            table.insert(q, { type = ENEMY_SMALL, x = sx, y = -20, delay = t })
            t = t + 0.25
        end
        for i = 1, mediums do
            local sx = 100 + math.random() * (SCREEN_W - 200)
            table.insert(q, { type = ENEMY_MEDIUM, x = sx, y = -30, delay = t })
            t = t + 0.5
        end
        for i = 1, larges do
            local sx = 150 + math.random() * (SCREEN_W - 300)
            table.insert(q, { type = ENEMY_LARGE, x = sx, y = -40, delay = t })
            t = t + 0.8
        end
    end

    return q
end

local function start_wave()
    wave = wave + 1
    spawn_queue = build_wave(wave)
    spawn_timer = 0
    wave_enemies_left = #spawn_queue
end

-- ---------------------------------------------------------------------------
-- Bomb
-- ---------------------------------------------------------------------------
local function activate_bomb()
    if bombs <= 0 then return end
    bombs = bombs - 1
    bomb_flash = 0.3
    -- Clear all enemy bullets
    local count = #enemy_bullets
    for _, b in ipairs(enemy_bullets) do
        spawn_particles(b.x, b.y, 1, 1, 1, 2, 0.5)
    end
    enemy_bullets = {}
    -- Damage all enemies on screen
    for _, e in ipairs(enemies) do
        e.hp = e.hp - 2
    end
    -- Score for clearing bullets
    score = score + count * 10
    spawn_particles(player.x, player.y, 1, 1, 1, 30, 2)
end

-- ---------------------------------------------------------------------------
-- Reset
-- ---------------------------------------------------------------------------
local function reset_game()
    player.x = SCREEN_W / 2
    player.y = SCREEN_H - 80
    player_bullets = {}
    fire_timer = 0
    lives = 3
    bombs = 3
    invuln_timer = 0
    death_flash = 0
    enemies = {}
    enemy_bullets = {}
    score = 0
    multiplier = 1.0
    graze_count = 0
    mult_pop_timer = 0
    mult_pop_scale = 1.0
    wave = 0
    wave_timer = 0
    spawn_queue = {}
    spawn_timer = 0
    wave_enemies_left = 0
    particles = {}
    score_pops = {}
    bomb_flash = 0
    start_wave()
end

-- ---------------------------------------------------------------------------
-- Player death
-- ---------------------------------------------------------------------------
local function player_die()
    lives = lives - 1
    invuln_timer = INVULN_TIME
    death_flash = 0.3
    multiplier = 1.0
    graze_count = 0
    bombs = 3
    spawn_particles(player.x, player.y, 0.3, 0.5, 1.0, 20, 1.5)
    if lives <= 0 then
        if score > high_score then high_score = score end
        current_state = STATE.GAME_OVER
    end
end

-- ---------------------------------------------------------------------------
-- Lurek callbacks
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Bullet Hell — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.02, 0.1)

    -- Action-based input
    lurek.input.bind("up",      { "w", "up" })
    lurek.input.bind("down",    { "s", "down" })
    lurek.input.bind("left",    { "a", "left" })
    lurek.input.bind("right",   { "d", "right" })
    lurek.input.bind("fire",    { "space" })
    lurek.input.bind("bomb",    { "x" })
    lurek.input.bind("focus",   { "lshift", "rshift" })
    lurek.input.bind("quit",    { "escape" })
    lurek.input.bind("start",   { "return" })

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)
    math.randomseed(os.time())
    reset_game()
    current_state = STATE.TITLE
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    update_particles(dt)
    update_score_pops(dt)

    -- Bomb flash decay
    if bomb_flash > 0 then bomb_flash = bomb_flash - dt end
    if death_flash > 0 then death_flash = death_flash - dt end

    -- Multiplier pop tween
    if mult_pop_timer > 0 then
        mult_pop_timer = mult_pop_timer - dt
        mult_pop_scale = 1.0 + 0.5 * clamp(mult_pop_timer / 0.3, 0, 1)
    else
        mult_pop_scale = 1.0
    end

    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- GAME OVER
    -- -----------------------------------------------------------------------
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("start") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- PLAYING
    -- -----------------------------------------------------------------------
    local focused = lurek.input.isDown("focus")
    local speed = focused and FOCUS_SPEED or PLAYER_SPEED

    -- Player movement
    if lurek.input.isDown("left")  then player.x = player.x - speed * dt end
    if lurek.input.isDown("right") then player.x = player.x + speed * dt end
    if lurek.input.isDown("up")    then player.y = player.y - speed * dt end
    if lurek.input.isDown("down")  then player.y = player.y + speed * dt end
    player.x = clamp(player.x, PLAYER_SIZE, SCREEN_W - PLAYER_SIZE)
    player.y = clamp(player.y, PLAYER_SIZE, SCREEN_H - PLAYER_SIZE)

    -- Invulnerability
    if invuln_timer > 0 then invuln_timer = invuln_timer - dt end

    -- Auto-fire
    fire_timer = fire_timer + dt
    if lurek.input.isDown("fire") and fire_timer >= FIRE_RATE then
        fire_timer = 0
        table.insert(player_bullets, { x = player.x - 4, y = player.y - PLAYER_SIZE })
        table.insert(player_bullets, { x = player.x + 2,  y = player.y - PLAYER_SIZE })
    end

    -- Bomb
    if lurek.input.wasActionPressed("bomb") then
        activate_bomb()
    end

    -- Move player bullets
    local i = 1
    while i <= #player_bullets do
        local b = player_bullets[i]
        b.y = b.y - BULLET_SPEED * dt
        if b.y + BULLET_H < 0 then
            table.remove(player_bullets, i)
        else
            i = i + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Spawn enemies from queue
    -- -----------------------------------------------------------------------
    if #spawn_queue > 0 then
        spawn_timer = spawn_timer + dt
        while #spawn_queue > 0 and spawn_timer >= spawn_queue[1].delay do
            local info = table.remove(spawn_queue, 1)
            local size = ENEMY_SIZE[info.type]
            table.insert(enemies, {
                type = info.type,
                x = info.x,
                y = info.y,
                hp = ENEMY_HP[info.type],
                max_hp = ENEMY_HP[info.type],
                size = size,
                color = ENEMY_COLORS[info.type],
                shoot_timer = 0.5 + math.random() * 1.5,
                spiral_angle = 0,
                move_timer = math.random() * math.pi * 2,
                target_y = 60 + math.random() * 200,
            })
        end
    end

    -- -----------------------------------------------------------------------
    -- Update enemies
    -- -----------------------------------------------------------------------
    i = 1
    while i <= #enemies do
        local e = enemies[i]

        -- Movement: drift downward to target_y then sway
        if e.y < e.target_y then
            e.y = e.y + 80 * dt
        end
        e.move_timer = e.move_timer + dt
        if e.type == ENEMY_BOSS then
            e.x = SCREEN_W / 2 + math.sin(e.move_timer * 0.5) * 200
        else
            e.x = e.x + math.sin(e.move_timer * 1.5) * 60 * dt
        end
        e.x = clamp(e.x, e.size, SCREEN_W - e.size)

        -- Shooting
        e.shoot_timer = e.shoot_timer - dt
        if e.shoot_timer <= 0 and e.y > 0 then
            if e.type == ENEMY_SMALL then
                fire_aimed(e.x, e.y + e.size)
                e.shoot_timer = 1.5 - clamp(wave * 0.05, 0, 0.8)
            elseif e.type == ENEMY_MEDIUM then
                e.spiral_angle = e.spiral_angle + 0.4
                fire_spiral(e.x, e.y + e.size, e.spiral_angle, 6)
                e.shoot_timer = 1.8 - clamp(wave * 0.04, 0, 0.7)
            elseif e.type == ENEMY_LARGE then
                fire_radial(e.x, e.y + e.size, 12 + wave)
                e.shoot_timer = 2.5 - clamp(wave * 0.05, 0, 1.0)
            elseif e.type == ENEMY_BOSS then
                -- Boss fires multiple patterns
                fire_radial(e.x, e.y + e.size, 20)
                fire_aimed(e.x - 20, e.y + e.size)
                fire_aimed(e.x + 20, e.y + e.size)
                if wave >= 10 then
                    fire_curtain(e.y + e.size + 40,
                        math.random() * (SCREEN_W - 120), 100 + math.random() * 60)
                end
                e.shoot_timer = 1.2 - clamp(wave * 0.02, 0, 0.5)
            end
        end

        -- Remove if off-screen bottom
        if e.y > SCREEN_H + 60 then
            table.remove(enemies, i)
            wave_enemies_left = wave_enemies_left - 1
        else
            i = i + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Move enemy bullets
    -- -----------------------------------------------------------------------
    i = 1
    while i <= #enemy_bullets do
        local b = enemy_bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.x < -20 or b.x > SCREEN_W + 20 or b.y < -20 or b.y > SCREEN_H + 20 then
            table.remove(enemy_bullets, i)
        else
            i = i + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: player bullets vs enemies
    -- -----------------------------------------------------------------------
    for pi = #player_bullets, 1, -1 do
        local pb = player_bullets[pi]
        for ei = #enemies, 1, -1 do
            local e = enemies[ei]
            if dist(pb.x, pb.y, e.x, e.y) < e.size then
                e.hp = e.hp - 1
                table.remove(player_bullets, pi)
                spawn_particles(pb.x, pb.y, e.color[1], e.color[2], e.color[3], 4)
                if e.hp <= 0 then
                    local pts = math.floor(ENEMY_POINTS[e.type] * multiplier)
                    score = score + pts
                    if score > high_score then high_score = score end
                    add_score_pop(e.x, e.y - e.size, "+" .. pts, e.color[1], e.color[2], e.color[3])
                    spawn_particles(e.x, e.y, e.color[1], e.color[2], e.color[3], 16, 1.5)
                    table.remove(enemies, ei)
                    wave_enemies_left = wave_enemies_left - 1
                end
                break
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: enemy bullets vs player (hitbox + graze)
    -- -----------------------------------------------------------------------
    i = 1
    while i <= #enemy_bullets do
        local b = enemy_bullets[i]
        local d = dist(b.x, b.y, player.x, player.y)

        if d < HITBOX_RADIUS + ENEMY_BULLET_RAD then
            -- Hit!
            table.remove(enemy_bullets, i)
            if invuln_timer <= 0 then
                player_die()
            end
        elseif d < GRAZE_RADIUS + ENEMY_BULLET_RAD and not b.grazed then
            -- Graze!
            b.grazed = true
            graze_count = graze_count + 1
            score = score + math.floor(50 * multiplier)
            multiplier = multiplier + 0.1
            mult_pop_timer = 0.3
            spawn_graze_sparkle(b.x, b.y)
            i = i + 1
        else
            i = i + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Next wave check
    -- -----------------------------------------------------------------------
    if wave_enemies_left <= 0 and #spawn_queue == 0 and #enemies == 0 then
        wave_timer = wave_timer + dt
        if wave_timer >= 1.5 then
            wave_timer = 0
            start_wave()
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render (game world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    cam:apply()

    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE.TITLE then
        lurek.render.setColor(1, 0.2, 0.3, 1)
        lurek.render.print("BULLET HELL", SCREEN_W / 2 - 55, 120)

        lurek.render.setColor(0.8, 0.8, 0.2, 1)
        lurek.render.print("WARNING: INTENSE BULLET PATTERNS", SCREEN_W / 2 - 140, 180)

        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("WASD — Move    Space — Fire    Shift — Focus", SCREEN_W / 2 - 180, 260)
        lurek.render.print("X — Bomb       ESC — Quit", SCREEN_W / 2 - 110, 290)

        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 90, 380)

        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        lurek.render.print("Graze bullets for bonus points!", SCREEN_W / 2 - 120, 440)

        draw_particles()
        return
    end

    -- -----------------------------------------------------------------------
    -- Bomb flash overlay
    -- -----------------------------------------------------------------------
    if bomb_flash > 0 then
        local a = clamp(bomb_flash / 0.3, 0, 0.6)
        lurek.render.setColor(1, 1, 1, a)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- -----------------------------------------------------------------------
    -- Player
    -- -----------------------------------------------------------------------
    if current_state == STATE.PLAYING then
        local visible = true
        if invuln_timer > 0 then
            visible = math.floor(invuln_timer * 10) % 2 == 0
        end

        if visible then
            -- Ship body (triangle-ish using rects)
            lurek.render.setColor(0.3, 0.5, 1.0, 1)
            lurek.render.rectangle("fill",
                player.x - PLAYER_SIZE / 2, player.y - PLAYER_SIZE / 2,
                PLAYER_SIZE, PLAYER_SIZE)
            -- Nose
            lurek.render.setColor(0.5, 0.7, 1.0, 1)
            lurek.render.rectangle("fill",
                player.x - 3, player.y - PLAYER_SIZE,
                6, PLAYER_SIZE / 2)

            -- Hitbox dot (always visible when focused, pulsing otherwise)
            local focused = lurek.input.isDown("focus")
            if focused then
                lurek.render.setColor(1, 1, 1, 1)
                lurek.render.circle("fill", player.x, player.y, HITBOX_RADIUS + 1)
                -- Graze radius indicator
                lurek.render.setColor(1, 1, 1, 0.15)
                lurek.render.circle("line", player.x, player.y, GRAZE_RADIUS)
            else
                lurek.render.setColor(1, 1, 1, 0.8)
                lurek.render.circle("fill", player.x, player.y, HITBOX_RADIUS)
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Player bullets
    -- -----------------------------------------------------------------------
    lurek.render.setColor(0.5, 0.8, 1.0, 1)
    for _, b in ipairs(player_bullets) do
        lurek.render.rectangle("fill", b.x, b.y, BULLET_W, BULLET_H)
    end

    -- -----------------------------------------------------------------------
    -- Enemies
    -- -----------------------------------------------------------------------
    for _, e in ipairs(enemies) do
        local c = e.color
        lurek.render.setColor(c[1], c[2], c[3], 1)

        if e.type == ENEMY_BOSS then
            -- Boss: larger shape with inner details
            lurek.render.rectangle("fill", e.x - e.size / 2, e.y - e.size / 2, e.size, e.size)
            lurek.render.setColor(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 1)
            lurek.render.rectangle("fill", e.x - e.size / 4, e.y - e.size / 4,
                e.size / 2, e.size / 2)
            -- HP bar
            local bar_w = e.size * 1.2
            local hp_frac = e.hp / e.max_hp
            lurek.render.setColor(0.3, 0.3, 0.3, 0.8)
            lurek.render.rectangle("fill", e.x - bar_w / 2, e.y - e.size / 2 - 8, bar_w, 4)
            lurek.render.setColor(1, 0.2, 0.2, 1)
            lurek.render.rectangle("fill", e.x - bar_w / 2, e.y - e.size / 2 - 8, bar_w * hp_frac, 4)
        else
            lurek.render.rectangle("fill",
                e.x - e.size / 2, e.y - e.size / 2, e.size, e.size)
        end
    end

    -- -----------------------------------------------------------------------
    -- Enemy bullets
    -- -----------------------------------------------------------------------
    for _, b in ipairs(enemy_bullets) do
        lurek.render.setColor(1, 0.3, 0.5, 0.9)
        lurek.render.circle("fill", b.x, b.y, ENEMY_BULLET_RAD)
        lurek.render.setColor(1, 0.8, 0.9, 0.5)
        lurek.render.circle("fill", b.x, b.y, ENEMY_BULLET_RAD - 1)
    end

    -- -----------------------------------------------------------------------
    -- Particles & score pops
    -- -----------------------------------------------------------------------
    draw_particles()
    draw_score_pops()

    -- -----------------------------------------------------------------------
    -- GAME OVER overlay
    -- -----------------------------------------------------------------------
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 45, SCREEN_H / 2 - 40)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Score: " .. score, SCREEN_W / 2 - 40, SCREEN_H / 2)
        lurek.render.print("Wave: " .. wave, SCREEN_W / 2 - 30, SCREEN_H / 2 + 20)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("PRESS ENTER TO RESTART", SCREEN_W / 2 - 100, SCREEN_H / 2 + 60)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (HUD — not affected by camera)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state ~= STATE.PLAYING then return end

    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE: " .. score, 10, 10)

    -- High score
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    lurek.render.print("HI: " .. high_score, SCREEN_W / 2 - 30, 10)

    -- Wave
    lurek.render.setColor(0.6, 0.8, 1, 1)
    lurek.render.print("WAVE " .. wave, SCREEN_W - 90, 10)

    -- Lives
    lurek.render.setColor(0.3, 0.5, 1, 1)
    for l = 1, lives do
        lurek.render.rectangle("fill", 10 + (l - 1) * 18, 30, 12, 12)
    end

    -- Bombs
    lurek.render.setColor(1, 0.8, 0, 1)
    for b = 1, bombs do
        lurek.render.circle("fill", 10 + (b - 1) * 18 + 6, 55, 5)
    end

    -- Multiplier
    lurek.render.setColor(1, 1, 0.3, 1)
    local mult_text = string.format("x%.1f", multiplier)
    lurek.render.print(mult_text, 10, 68)
    if mult_pop_timer > 0 then
        lurek.render.setColor(1, 1, 0, clamp(mult_pop_timer / 0.3, 0, 1))
        lurek.render.print(mult_text, 8, 66)
    end

    -- Graze count
    lurek.render.setColor(0.8, 0.8, 0.8, 0.6)
    lurek.render.print("Graze: " .. graze_count, 10, 86)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
    lurek.render.print("FPS: " .. fps, SCREEN_W - 80, SCREEN_H - 20)
end
