-- ============================================================================
-- Galaga — Lurek2D
-- ============================================================================
-- Category : arcade
-- Source   : ../../../../content/games/arcade/galaga
-- Run with : cargo run -- content/games/arcade/galaga
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Formation grid
local FORM_COLS = 10
local FORM_ROWS = 4
local ENEMY_W, ENEMY_H = 24, 20
local FORM_GAP_X, FORM_GAP_Y = 14, 12
local FORM_START_Y = 70

-- Row config: color, points, hp
local ROW_CFG = {
    { color = { 1.0, 0.2, 0.2 }, pts = 400, hp = 2, is_boss = true  },  -- boss row
    { color = { 0.9, 0.6, 0.1 }, pts = 150, hp = 1, is_boss = false },
    { color = { 0.2, 0.7, 1.0 }, pts = 100, hp = 1, is_boss = false },
    { color = { 0.3, 1.0, 0.3 }, pts =  50, hp = 1, is_boss = false },
}
local BOSS_HIT_COLOR = { 1.0, 0.7, 0.9 }

-- Player
local PLAYER_W, PLAYER_H = 36, 14
local PLAYER_TURRET_W, PLAYER_TURRET_H = 6, 10
local PLAYER_Y = SCREEN_H - 50
local PLAYER_SPEED = 300
local MAX_PLAYER_BULLETS = 2

-- Bullets
local BULLET_W, BULLET_H = 3, 10
local BULLET_SPEED = 420
local ENEMY_BULLET_SPEED = 220

-- Challenging stage
local CHALLENGE_INTERVAL = 3

-- Tractor beam
local TRACTOR_W, TRACTOR_H = 40, 80

-- ---------------------------------------------------------------------------
-- Game state variables
-- ---------------------------------------------------------------------------
local player = { x = 0, y = PLAYER_Y }
local player_bullets = {}
local enemy_bullets = {}
local enemies = {}
local formation_dir = 1
local formation_offset_x = 0
local formation_sway_timer = 0

-- Dive state
local divers = {}          -- enemies currently dive-bombing
local dive_timer = 0
local dive_interval = 2.5

-- Challenge stage
local is_challenge = false
local challenge_kills = 0
local challenge_total = 0
local challenge_msg_timer = 0

-- Boss capture
local captured_ship = nil      -- { boss_idx } boss that holds captured ship
local dual_fire = false
local tractor_beam = nil       -- { boss_idx, x, y, timer }
local capture_in_progress = false

-- Stars (parallax layers)
local star_layers = {}
local STAR_LAYER_COUNT = 3
local STARS_PER_LAYER = { 40, 30, 20 }
local STAR_SPEEDS = { 30, 60, 100 }
local STAR_SIZES = { 1, 2, 2 }
local STAR_ALPHAS = { 0.3, 0.5, 0.8 }

-- Particles & score pops
local particles = {}
local score_pops = {}

-- Score / lives / wave
local score = 0
local high_score = 0
local lives = 3
local wave = 1

-- Camera
local cam = nil

-- Fly-in animation
local fly_in_queue = {}    -- enemies that haven't settled yet
local fly_in_active = {}   -- enemies currently flying in
local FLY_IN_SPEED = 280
local fly_in_timer = 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function formation_x(col)
    local grid_w = FORM_COLS * (ENEMY_W + FORM_GAP_X) - FORM_GAP_X
    local start_x = (SCREEN_W - grid_w) / 2
    return start_x + col * (ENEMY_W + FORM_GAP_X) + formation_offset_x
end

local function formation_y(row)
    return FORM_START_Y + row * (ENEMY_H + FORM_GAP_Y)
end

-- ---------------------------------------------------------------------------
-- Star field
-- ---------------------------------------------------------------------------
local function create_stars()
    star_layers = {}
    for layer = 1, STAR_LAYER_COUNT do
        local stars = {}
        for _ = 1, STARS_PER_LAYER[layer] do
            table.insert(stars, {
                x = math.random() * SCREEN_W,
                y = math.random() * SCREEN_H,
            })
        end
        star_layers[layer] = stars
    end
end

local function update_stars(dt)
    for layer = 1, STAR_LAYER_COUNT do
        for _, s in ipairs(star_layers[layer]) do
            s.y = s.y + STAR_SPEEDS[layer] * dt
            if s.y > SCREEN_H then
                s.y = -2
                s.x = math.random() * SCREEN_W
            end
        end
    end
end

local function draw_stars()
    for layer = 1, STAR_LAYER_COUNT do
        local a = STAR_ALPHAS[layer]
        local sz = STAR_SIZES[layer]
        lurek.render.setColor(1, 1, 1, a)
        for _, s in ipairs(star_layers[layer]) do
            lurek.render.rectangle("fill", s.x, s.y, sz, sz)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_particles(px, py, r, g, b, count)
    for _ = 1, (count or 10) do
        table.insert(particles, {
            x = px, y = py,
            vx = (math.random() - 0.5) * 240,
            vy = (math.random() - 0.5) * 240,
            life = 0.25 + math.random() * 0.35,
            max_life = 0.6,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
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
-- Score pops (tween-like float up)
-- ---------------------------------------------------------------------------
local function add_score_pop(x, y, pts)
    table.insert(score_pops, {
        x = x, y = y,
        text = "+" .. tostring(pts),
        alpha = 1.0,
        dy = 0,
        life = 0.9,
    })
end

local function update_score_pops(dt)
    local i = 1
    while i <= #score_pops do
        local sp = score_pops[i]
        sp.dy = sp.dy - 70 * dt
        sp.y = sp.y + sp.dy * dt
        sp.life = sp.life - dt
        sp.alpha = clamp(sp.life / 0.9, 0, 1)
        if sp.life <= 0 then
            table.remove(score_pops, i)
        else
            i = i + 1
        end
    end
end

local function draw_score_pops()
    for _, sp in ipairs(score_pops) do
        lurek.render.setColor(1, 1, 0, sp.alpha)
        lurek.render.print(sp.text, sp.x, sp.y)
    end
end

-- ---------------------------------------------------------------------------
-- Enemy creation & formation
-- ---------------------------------------------------------------------------
local function create_enemies()
    enemies = {}
    divers = {}
    fly_in_queue = {}
    fly_in_active = {}
    fly_in_timer = 0
    formation_offset_x = 0
    formation_sway_timer = 0

    for row = 0, FORM_ROWS - 1 do
        local cfg = ROW_CFG[row + 1]
        for col = 0, FORM_COLS - 1 do
            local home_x = formation_x(col)
            local home_y = formation_y(row)
            -- Start off-screen for fly-in
            local side = ((row * FORM_COLS + col) % 2 == 0) and -1 or 1
            local start_x = side == -1 and -60 or (SCREEN_W + 60)
            local start_y = -40 - (row * 30) - (col * 8)
            local e = {
                home_col = col,
                home_row = row,
                x = start_x,
                y = start_y,
                hp = cfg.hp,
                max_hp = cfg.hp,
                alive = true,
                in_formation = false,
                is_boss = cfg.is_boss,
                pts = cfg.pts,
                color = { cfg.color[1], cfg.color[2], cfg.color[3] },
                original_color = { cfg.color[1], cfg.color[2], cfg.color[3] },
                captured_ship = false,  -- boss holds a captured player ship
                -- Dive state
                diving = false,
                dive_path = nil,
                dive_t = 0,
            }
            table.insert(enemies, e)
            table.insert(fly_in_queue, #enemies)  -- index
        end
    end

    if is_challenge then
        challenge_kills = 0
        challenge_total = 0
        for _, e in ipairs(enemies) do
            if e.alive then challenge_total = challenge_total + 1 end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Fly-in animation
-- ---------------------------------------------------------------------------
local function update_fly_in(dt)
    -- Release enemies from queue gradually
    fly_in_timer = fly_in_timer + dt
    while #fly_in_queue > 0 and fly_in_timer >= 0.04 do
        fly_in_timer = fly_in_timer - 0.04
        local idx = table.remove(fly_in_queue, 1)
        table.insert(fly_in_active, idx)
    end

    -- Animate active fly-ins toward home position
    local i = 1
    while i <= #fly_in_active do
        local idx = fly_in_active[i]
        local e = enemies[idx]
        local hx = formation_x(e.home_col)
        local hy = formation_y(e.home_row)
        -- Curved path: move toward home with a sine wobble
        local dx, dy = hx - e.x, hy - e.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < 4 then
            e.x = hx
            e.y = hy
            e.in_formation = true
            table.remove(fly_in_active, i)
        else
            local speed = FLY_IN_SPEED
            local nx, ny = dx / d, dy / d
            -- Add perpendicular wobble for curved entry
            local wobble = math.sin(e.y * 0.05) * 120
            e.x = e.x + (nx * speed + wobble * ny) * dt
            e.y = e.y + ny * speed * dt
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Dive-bomb logic
-- ---------------------------------------------------------------------------
local function start_dive(enemy_idx)
    local e = enemies[enemy_idx]
    if not e.alive or e.diving or not e.in_formation then return end
    e.diving = true
    e.in_formation = false
    -- Generate a simple curved dive path toward player
    e.dive_path = {
        start_x = e.x, start_y = e.y,
        mid_x = e.x + (math.random() - 0.5) * 200,
        mid_y = SCREEN_H * 0.45,
        end_x = player.x + PLAYER_W / 2,
        end_y = SCREEN_H + 40,
    }
    e.dive_t = 0
    table.insert(divers, enemy_idx)
end

local function update_divers(dt)
    local i = 1
    while i <= #divers do
        local idx = divers[i]
        local e = enemies[idx]
        if not e.alive then
            table.remove(divers, i)
        else
            e.dive_t = e.dive_t + dt * 0.6
            local t = clamp(e.dive_t, 0, 1)
            local dp = e.dive_path
            -- Quadratic bezier
            local omt = 1 - t
            e.x = omt * omt * dp.start_x + 2 * omt * t * dp.mid_x + t * t * dp.end_x
            e.y = omt * omt * dp.start_y + 2 * omt * t * dp.mid_y + t * t * dp.end_y

            -- Shoot while diving (aimed at player)
            if not is_challenge and math.random() < 0.02 then
                local bx = e.x + ENEMY_W / 2
                local by = e.y + ENEMY_H
                local px = player.x + PLAYER_W / 2
                local py = player.y
                local d2 = dist(bx, by, px, py)
                if d2 > 1 then
                    table.insert(enemy_bullets, {
                        x = bx - BULLET_W / 2,
                        y = by,
                        vx = (px - bx) / d2 * ENEMY_BULLET_SPEED,
                        vy = (py - by) / d2 * ENEMY_BULLET_SPEED,
                    })
                end
            end

            if t >= 1 then
                -- Return to formation from top
                e.diving = false
                e.x = formation_x(e.home_col)
                e.y = -30
                -- Re-enter via fly-in
                e.in_formation = false
                table.insert(fly_in_active, idx)
                table.remove(divers, i)
            else
                i = i + 1
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Tractor beam (boss capture)
-- ---------------------------------------------------------------------------
local function update_tractor_beam(dt)
    if not tractor_beam then return end
    local tb = tractor_beam
    local boss = enemies[tb.boss_idx]
    if not boss or not boss.alive then
        tractor_beam = nil
        capture_in_progress = false
        return
    end
    tb.timer = tb.timer - dt
    tb.x = boss.x + ENEMY_W / 2 - TRACTOR_W / 2
    tb.y = boss.y + ENEMY_H

    -- Check if player is inside beam
    if rects_overlap(player.x, player.y, PLAYER_W, PLAYER_H,
        tb.x, tb.y, TRACTOR_W, TRACTOR_H) then
        -- Capture!
        boss.captured_ship = true
        captured_ship = tb.boss_idx
        lives = lives - 1
        spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2,
            0.2, 0.6, 1.0, 14)
        tractor_beam = nil
        capture_in_progress = false
        if lives <= 0 then
            current_state = STATE.GAME_OVER
        end
        -- Reset player position
        player.x = SCREEN_W / 2 - PLAYER_W / 2
        return
    end

    if tb.timer <= 0 then
        tractor_beam = nil
        capture_in_progress = false
        -- Boss returns to formation
        boss.diving = false
        boss.x = formation_x(boss.home_col)
        boss.y = -30
        boss.in_formation = false
        table.insert(fly_in_active, tb.boss_idx)
    end
end

-- ---------------------------------------------------------------------------
-- Reset / next wave
-- ---------------------------------------------------------------------------
local function reset_game()
    player.x = SCREEN_W / 2 - PLAYER_W / 2
    player_bullets = {}
    enemy_bullets = {}
    divers = {}
    score = 0
    lives = 3
    wave = 1
    dual_fire = false
    captured_ship = nil
    tractor_beam = nil
    capture_in_progress = false
    is_challenge = false
    challenge_msg_timer = 0
    particles = {}
    score_pops = {}
    dive_timer = 0
    create_stars()
    create_enemies()
end

local function next_wave()
    wave = wave + 1
    player_bullets = {}
    enemy_bullets = {}
    divers = {}
    tractor_beam = nil
    capture_in_progress = false
    dive_timer = 0

    -- Every CHALLENGE_INTERVAL waves is a challenging stage
    is_challenge = (wave % CHALLENGE_INTERVAL == 0)
    if is_challenge then
        challenge_msg_timer = 2.0
    end

    dive_interval = math.max(0.8, 2.5 - (wave - 1) * 0.15)
    create_enemies()
end

-- ---------------------------------------------------------------------------
-- Lurek callbacks
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Galaga — Lurek2D")
    lurek.render.setBackgroundColor(0, 0, 0.02)

    lurek.input.bind("left",    { "a", "left" })
    lurek.input.bind("right",   { "d", "right" })
    lurek.input.bind("fire",    { "space" })
    lurek.input.bind("quit",    { "escape" })
    lurek.input.bind("start",   { "return" })
    lurek.input.bind("restart", { "r" })

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    math.randomseed(os.time())
    create_stars()
    reset_game()
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    update_particles(dt)
    update_score_pops(dt)
    update_stars(dt)

    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE.TITLE then
        if lurek.input.pressed("start") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- GAME OVER
    -- -----------------------------------------------------------------------
    if current_state == STATE.GAME_OVER then
        if lurek.input.pressed("restart") or lurek.input.pressed("start") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- PLAYING
    -- -----------------------------------------------------------------------

    -- Challenge stage banner countdown
    if challenge_msg_timer > 0 then
        challenge_msg_timer = challenge_msg_timer - dt
    end

    -- Player movement
    if lurek.input.down("left") then
        player.x = player.x - PLAYER_SPEED * dt
    end
    if lurek.input.down("right") then
        player.x = player.x + PLAYER_SPEED * dt
    end
    player.x = clamp(player.x, 0, SCREEN_W - PLAYER_W)

    -- Player fire
    if lurek.input.pressed("fire") and #player_bullets < MAX_PLAYER_BULLETS then
        -- Single or dual fire
        local cx = player.x + PLAYER_W / 2
        if dual_fire then
            table.insert(player_bullets, { x = cx - 12 - BULLET_W / 2, y = player.y - BULLET_H })
            table.insert(player_bullets, { x = cx + 12 - BULLET_W / 2, y = player.y - BULLET_H })
        else
            table.insert(player_bullets, { x = cx - BULLET_W / 2, y = player.y - BULLET_H })
        end
    end

    -- Move player bullets
    local bi = 1
    while bi <= #player_bullets do
        local b = player_bullets[bi]
        b.y = b.y - BULLET_SPEED * dt
        if b.y + BULLET_H < 0 then
            table.remove(player_bullets, bi)
        else
            bi = bi + 1
        end
    end

    -- Formation sway
    formation_sway_timer = formation_sway_timer + dt
    formation_offset_x = math.sin(formation_sway_timer * 0.5) * 30

    -- Update positions of in-formation enemies
    for _, e in ipairs(enemies) do
        if e.alive and e.in_formation then
            e.x = formation_x(e.home_col)
            e.y = formation_y(e.home_row)
        end
    end

    -- Fly-in
    update_fly_in(dt)

    -- Dive-bomb timer
    if not is_challenge then
        dive_timer = dive_timer + dt
        local num_divers = math.min(3, 1 + math.floor(wave / 3))
        if dive_timer >= dive_interval then
            dive_timer = 0
            -- Pick random formation enemies to dive
            local candidates = {}
            for idx, e in ipairs(enemies) do
                if e.alive and e.in_formation and not e.diving then
                    table.insert(candidates, idx)
                end
            end
            for _ = 1, math.min(num_divers, #candidates) do
                if #candidates > 0 then
                    local pick = math.random(#candidates)
                    start_dive(candidates[pick])
                    table.remove(candidates, pick)
                end
            end

            -- Tractor beam: boss capture attempt
            if not capture_in_progress and not captured_ship and math.random() < 0.15 then
                for idx, e in ipairs(enemies) do
                    if e.is_boss and e.alive and e.in_formation and not e.diving then
                        e.diving = true
                        e.in_formation = false
                        -- Dive boss straight down
                        e.dive_path = {
                            start_x = e.x, start_y = e.y,
                            mid_x = player.x + PLAYER_W / 2,
                            mid_y = SCREEN_H * 0.35,
                            end_x = player.x + PLAYER_W / 2,
                            end_y = SCREEN_H * 0.35,
                        }
                        e.dive_t = 0
                        tractor_beam = {
                            boss_idx = idx,
                            x = e.x, y = e.y + ENEMY_H,
                            timer = 2.5,
                        }
                        capture_in_progress = true
                        table.insert(divers, idx)
                        break
                    end
                end
            end
        end
    else
        -- Challenge stage: all enemies dive in patterns
        dive_timer = dive_timer + dt
        if dive_timer >= 0.15 then
            dive_timer = 0
            for idx, e in ipairs(enemies) do
                if e.alive and e.in_formation and not e.diving then
                    start_dive(idx)
                    break
                end
            end
        end
    end

    -- Update divers
    update_divers(dt)
    update_tractor_beam(dt)

    -- Move enemy bullets
    bi = 1
    while bi <= #enemy_bullets do
        local b = enemy_bullets[bi]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.y > SCREEN_H or b.y < -20 or b.x < -20 or b.x > SCREEN_W + 20 then
            table.remove(enemy_bullets, bi)
        else
            bi = bi + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: player bullets vs enemies
    -- -----------------------------------------------------------------------
    bi = 1
    while bi <= #player_bullets do
        local b = player_bullets[bi]
        local hit = false
        for idx, e in ipairs(enemies) do
            if e.alive and rects_overlap(
                b.x, b.y, BULLET_W, BULLET_H,
                e.x, e.y, ENEMY_W, ENEMY_H
            ) then
                e.hp = e.hp - 1
                if e.hp <= 0 then
                    e.alive = false
                    local pts = e.pts
                    -- Boss with captured ship: bonus + grant dual fire
                    if e.is_boss and e.captured_ship then
                        pts = 1600
                        dual_fire = true
                        e.captured_ship = false
                        if captured_ship == idx then captured_ship = nil end
                    end
                    score = score + pts
                    if score > high_score then high_score = score end
                    spawn_particles(e.x + ENEMY_W / 2, e.y + ENEMY_H / 2,
                        e.original_color[1], e.original_color[2], e.original_color[3], 14)
                    add_score_pop(e.x + ENEMY_W / 2, e.y, pts)
                    if is_challenge then
                        challenge_kills = challenge_kills + 1
                    end
                else
                    -- Boss first hit: change color
                    e.color = { BOSS_HIT_COLOR[1], BOSS_HIT_COLOR[2], BOSS_HIT_COLOR[3] }
                    spawn_particles(e.x + ENEMY_W / 2, e.y + ENEMY_H / 2,
                        1, 1, 0.5, 6)
                end
                hit = true
                break
            end
        end
        if hit then
            table.remove(player_bullets, bi)
        else
            bi = bi + 1
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: enemy bullets vs player
    -- -----------------------------------------------------------------------
    if not is_challenge then
        bi = 1
        while bi <= #enemy_bullets do
            local b = enemy_bullets[bi]
            if rects_overlap(b.x, b.y, BULLET_W, BULLET_H,
                player.x, player.y, PLAYER_W, PLAYER_H) then
                table.remove(enemy_bullets, bi)
                lives = lives - 1
                spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2,
                    0.2, 0.6, 1.0, 12)
                if dual_fire then dual_fire = false end
                if lives <= 0 then
                    current_state = STATE.GAME_OVER
                    return
                end
            else
                bi = bi + 1
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: diving enemy body vs player
    -- -----------------------------------------------------------------------
    for _, e in ipairs(enemies) do
        if e.alive and e.diving and rects_overlap(
            e.x, e.y, ENEMY_W, ENEMY_H,
            player.x, player.y, PLAYER_W, PLAYER_H
        ) then
            e.alive = false
            lives = lives - 1
            spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2,
                0.8, 0.4, 0.1, 16)
            spawn_particles(e.x + ENEMY_W / 2, e.y + ENEMY_H / 2,
                e.original_color[1], e.original_color[2], e.original_color[3], 10)
            if dual_fire then dual_fire = false end
            if lives <= 0 then
                current_state = STATE.GAME_OVER
                return
            end
        end
    end

    -- -----------------------------------------------------------------------
    -- Wave cleared check
    -- -----------------------------------------------------------------------
    local any_alive = false
    for _, e in ipairs(enemies) do
        if e.alive then any_alive = true; break end
    end
    if not any_alive then
        -- Challenge stage bonus
        if is_challenge and challenge_kills == challenge_total then
            local bonus = challenge_total * 100
            score = score + bonus
            if score > high_score then high_score = score end
            add_score_pop(SCREEN_W / 2, SCREEN_H / 2, bonus)
        end
        next_wave()
    end
end

-- ---------------------------------------------------------------------------
-- Render (game world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    cam:apply()

    -- Star field (always drawn)
    draw_stars()

    if current_state == STATE.TITLE then
        -- Title
        lurek.render.setColor(0.2, 0.4, 1.0, 1)
        lurek.render.print("G A L A G A", SCREEN_W / 2 - 60, 140)

        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 90, 220)

        -- Score table
        local ty = 300
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("--- SCORE TABLE ---", SCREEN_W / 2 - 80, ty)
        ty = ty + 28

        for i = 1, FORM_ROWS do
            local cfg = ROW_CFG[i]
            lurek.render.setColor(cfg.color[1], cfg.color[2], cfg.color[3], 1)
            lurek.render.rectangle("fill", SCREEN_W / 2 - 80, ty, ENEMY_W, ENEMY_H)
            lurek.render.setColor(1, 1, 1, 1)
            local label = "= " .. tostring(cfg.pts) .. " PTS"
            if cfg.is_boss then label = label .. " (x2 HP)" end
            lurek.render.print(label, SCREEN_W / 2 - 44, ty + 4)
            ty = ty + 28
        end

        cam:reset()
        return
    end

    -- ----- PLAYING / GAME_OVER world draw -----

    -- Enemies
    for idx, e in ipairs(enemies) do
        if e.alive then
            lurek.render.setColor(e.color[1], e.color[2], e.color[3], 1)
            lurek.render.rectangle("fill", e.x, e.y, ENEMY_W, ENEMY_H)
            -- Boss indicator: small inner rect
            if e.is_boss then
                lurek.render.setColor(1, 1, 1, 0.3)
                lurek.render.rectangle("fill", e.x + 4, e.y + 4, ENEMY_W - 8, ENEMY_H - 8)
            end
            -- Captured ship indicator on boss
            if e.captured_ship then
                lurek.render.setColor(0.2, 0.6, 1.0, 0.7)
                lurek.render.rectangle("fill", e.x + 2, e.y + ENEMY_H + 2, ENEMY_W - 4, 6)
            end
        end
    end

    -- Tractor beam
    if tractor_beam then
        local tb = tractor_beam
        local flash = math.sin(formation_sway_timer * 20) * 0.3 + 0.5
        lurek.render.setColor(0.3, 0.8, 1.0, flash)
        lurek.render.rectangle("fill", tb.x, tb.y, TRACTOR_W, TRACTOR_H)
    end

    -- Player ship(s)
    if current_state ~= STATE.GAME_OVER or lives > 0 then
        if dual_fire then
            -- Two ships side by side
            lurek.render.setColor(0.2, 0.6, 1.0, 1)
            -- Left ship
            lurek.render.rectangle("fill", player.x - 10, player.y, PLAYER_W, PLAYER_H)
            lurek.render.rectangle("fill",
                player.x - 10 + PLAYER_W / 2 - PLAYER_TURRET_W / 2,
                player.y - PLAYER_TURRET_H,
                PLAYER_TURRET_W, PLAYER_TURRET_H)
            -- Right ship
            lurek.render.rectangle("fill", player.x + 10, player.y, PLAYER_W, PLAYER_H)
            lurek.render.rectangle("fill",
                player.x + 10 + PLAYER_W / 2 - PLAYER_TURRET_W / 2,
                player.y - PLAYER_TURRET_H,
                PLAYER_TURRET_W, PLAYER_TURRET_H)
        else
            lurek.render.setColor(0.2, 0.6, 1.0, 1)
            lurek.render.rectangle("fill", player.x, player.y, PLAYER_W, PLAYER_H)
            lurek.render.rectangle("fill",
                player.x + PLAYER_W / 2 - PLAYER_TURRET_W / 2,
                player.y - PLAYER_TURRET_H,
                PLAYER_TURRET_W, PLAYER_TURRET_H)
        end
    end

    -- Player bullets
    lurek.render.setColor(1, 1, 0.3, 1)
    for _, b in ipairs(player_bullets) do
        lurek.render.rectangle("fill", b.x, b.y, BULLET_W, BULLET_H)
    end

    -- Enemy bullets
    lurek.render.setColor(1, 0.3, 0.3, 1)
    for _, b in ipairs(enemy_bullets) do
        lurek.render.rectangle("fill", b.x, b.y, BULLET_W, BULLET_H)
    end

    -- Particles
    draw_particles()

    -- Score pops
    draw_score_pops()

    -- Challenge stage banner
    if is_challenge and challenge_msg_timer > 0 then
        local a = clamp(challenge_msg_timer / 0.5, 0, 1)
        lurek.render.setColor(1, 1, 0, a)
        lurek.render.print("-- CHALLENGING STAGE --", SCREEN_W / 2 - 100, SCREEN_H / 2 - 40)
        lurek.render.setColor(0.8, 0.8, 0.8, a)
        lurek.render.print("Hit all enemies for bonus!", SCREEN_W / 2 - 100, SCREEN_H / 2 - 10)
    end

    -- Game over overlay
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 50, SCREEN_H / 2 - 30)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.print("PRESS R OR ENTER TO RESTART", SCREEN_W / 2 - 120, SCREEN_H / 2 + 10)

        if is_challenge then
            lurek.render.setColor(1, 1, 0, 1)
            lurek.render.print("CHALLENGE: " .. challenge_kills .. "/" .. challenge_total,
                SCREEN_W / 2 - 80, SCREEN_H / 2 + 40)
        end
    end

    cam:reset()
end

-- ---------------------------------------------------------------------------
-- Render UI (HUD overlay — screen space)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE: " .. tostring(score), 10, 8)

    -- High score
    lurek.render.print("HI: " .. tostring(high_score), SCREEN_W / 2 - 40, 8)

    -- Lives
    lurek.render.print("LIVES: " .. tostring(lives), SCREEN_W - 110, 8)

    -- Wave
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    local wave_label = is_challenge and ("WAVE " .. wave .. " (CHALLENGE)") or ("WAVE " .. wave)
    lurek.render.print(wave_label, SCREEN_W - 180, 28)

    -- Dual-fire indicator
    if dual_fire then
        lurek.render.setColor(0.3, 1.0, 0.3, 1)
        lurek.render.print("DUAL FIRE", SCREEN_W / 2 - 30, 28)
    end

    -- FPS counter
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print("FPS: " .. tostring(math.floor(fps)), 10, SCREEN_H - 20)
end
