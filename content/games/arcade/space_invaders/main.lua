-- ============================================================================
-- Space Invaders — Lurek2D
-- ============================================================================
-- Category : arcade
-- Source   : content/games/arcade/space_invaders/main.lua
-- Run with : cargo run -- content/games/arcade/space_invaders
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local current_state = STATE.TITLE

-- Alien grid
local COLS, ROWS = 11, 5
local ALIEN_W, ALIEN_H = 32, 24
local ALIEN_GAP_X, ALIEN_GAP_Y = 16, 12
local ALIEN_START_X = 80
local ALIEN_START_Y = 80

-- Alien point values per row (top to bottom)
local ROW_POINTS = { 30, 20, 20, 10, 10 }
-- Alien colours per row  (top to bottom)
local ROW_COLOURS = {
    { 1.0, 0.0, 1.0 },   -- magenta (30 pts)
    { 0.0, 1.0, 1.0 },   -- cyan    (20 pts)
    { 0.0, 1.0, 1.0 },   -- cyan    (20 pts)
    { 0.0, 1.0, 0.0 },   -- green   (10 pts)
    { 0.0, 1.0, 0.0 },   -- green   (10 pts)
}

-- Player
local PLAYER_W, PLAYER_H = 48, 16
local PLAYER_TURRET_W, PLAYER_TURRET_H = 8, 10
local PLAYER_Y = SCREEN_H - 50
local PLAYER_SPEED = 280

-- Bullets
local BULLET_W, BULLET_H = 4, 12
local BULLET_SPEED = 400
local ALIEN_BULLET_SPEED = 200

-- Shields
local SHIELD_BLOCK = 8
local SHIELD_COLS, SHIELD_ROWS = 6, 4
local SHIELD_COUNT = 3
local SHIELD_Y = SCREEN_H - 130

-- UFO
local UFO_W, UFO_H = 40, 16
local UFO_SPEED = 120
local UFO_MIN_INTERVAL, UFO_MAX_INTERVAL = 8, 25

-- ---------------------------------------------------------------------------
-- Game state variables
-- ---------------------------------------------------------------------------
local player = { x = SCREEN_W / 2 - PLAYER_W / 2, y = PLAYER_Y }
local player_bullet = nil   -- { x, y }
local alien_bullets = {}
local aliens = {}
local alien_dir = 1         -- 1 = right, -1 = left
local alien_speed = 40
local alien_move_timer = 0
local alien_shoot_timer = 0
local alien_count = 0
local shields = {}
local ufo = nil             -- { x, y, dir, points }
local ufo_timer = 0

local score = 0
local high_score = 0
local lives = 3
local wave = 1

-- Tween / particles / camera
local cam = nil
local particles = {}
local score_pops = {}        -- { x, y, text, alpha, dy }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function rects_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function random_ufo_time()
    return UFO_MIN_INTERVAL + math.random() * (UFO_MAX_INTERVAL - UFO_MIN_INTERVAL)
end

-- ---------------------------------------------------------------------------
-- Particle helpers
-- ---------------------------------------------------------------------------
local function spawn_particles(px, py, r, g, b, count)
    for _ = 1, (count or 8) do
        table.insert(particles, {
            x = px, y = py,
            vx = (math.random() - 0.5) * 200,
            vy = (math.random() - 0.5) * 200,
            life = 0.3 + math.random() * 0.3,
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
-- Score pop (tween-like)
-- ---------------------------------------------------------------------------
local function add_score_pop(x, y, pts)
    table.insert(score_pops, {
        x = x, y = y,
        text = "+" .. tostring(pts),
        alpha = 1.0,
        dy = 0,
        life = 0.8,
    })
end

local function update_score_pops(dt)
    local i = 1
    while i <= #score_pops do
        local sp = score_pops[i]
        sp.dy = sp.dy - 60 * dt
        sp.y = sp.y + sp.dy * dt
        sp.life = sp.life - dt
        sp.alpha = clamp(sp.life / 0.8, 0, 1)
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
-- Shield creation
-- ---------------------------------------------------------------------------
local function create_shields()
    shields = {}
    local spacing = SCREEN_W / (SHIELD_COUNT + 1)
    for s = 1, SHIELD_COUNT do
        local sx = spacing * s - (SHIELD_COLS * SHIELD_BLOCK) / 2
        local blocks = {}
        for r = 0, SHIELD_ROWS - 1 do
            for c = 0, SHIELD_COLS - 1 do
                table.insert(blocks, {
                    x = sx + c * SHIELD_BLOCK,
                    y = SHIELD_Y + r * SHIELD_BLOCK,
                    alive = true,
                })
            end
        end
        table.insert(shields, blocks)
    end
end

-- ---------------------------------------------------------------------------
-- Alien grid creation
-- ---------------------------------------------------------------------------
local function create_aliens()
    aliens = {}
    alien_count = 0
    for row = 0, ROWS - 1 do
        for col = 0, COLS - 1 do
            table.insert(aliens, {
                x = ALIEN_START_X + col * (ALIEN_W + ALIEN_GAP_X),
                y = ALIEN_START_Y + row * (ALIEN_H + ALIEN_GAP_Y),
                row = row + 1,
                alive = true,
                points = ROW_POINTS[row + 1],
                color = ROW_COLOURS[row + 1],
            })
            alien_count = alien_count + 1
        end
    end
    alien_dir = 1
    alien_speed = 40 + (wave - 1) * 8
    alien_move_timer = 0
    alien_shoot_timer = 0
    alien_bullets = {}
end

-- ---------------------------------------------------------------------------
-- Reset game
-- ---------------------------------------------------------------------------
local function reset_game()
    player.x = SCREEN_W / 2 - PLAYER_W / 2
    player_bullet = nil
    alien_bullets = {}
    score = 0
    lives = 3
    wave = 1
    ufo = nil
    ufo_timer = random_ufo_time()
    particles = {}
    score_pops = {}
    create_aliens()
    create_shields()
end

local function next_wave()
    wave = wave + 1
    player_bullet = nil
    alien_bullets = {}
    ufo = nil
    ufo_timer = random_ufo_time()
    create_aliens()
    -- Shields persist between waves but get more damaged over time
end

-- ---------------------------------------------------------------------------
-- Lurek callbacks
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Space Invaders — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.06)

    -- Action-based input
    lurek.input.bind("left",  { "a", "left" })
    lurek.input.bind("right", { "d", "right" })
    lurek.input.bind("fire",  { "space" })
    lurek.input.bind("quit",  { "escape" })
    lurek.input.bind("start", { "return" })
    lurek.input.bind("restart", { "r" })

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    math.randomseed(os.time())
    reset_game()
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Update particles & score pops always
    update_particles(dt)
    update_score_pops(dt)

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
        if lurek.input.wasActionPressed("restart") or lurek.input.wasActionPressed("start") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- PLAYING
    -- -----------------------------------------------------------------------

    -- Player movement
    if lurek.input.isDown("left") then
        player.x = player.x - PLAYER_SPEED * dt
    end
    if lurek.input.isDown("right") then
        player.x = player.x + PLAYER_SPEED * dt
    end
    player.x = clamp(player.x, 0, SCREEN_W - PLAYER_W)

    -- Player fire
    if lurek.input.wasActionPressed("fire") and player_bullet == nil then
        player_bullet = {
            x = player.x + PLAYER_W / 2 - BULLET_W / 2,
            y = player.y - BULLET_H,
        }
    end

    -- Move player bullet
    if player_bullet then
        player_bullet.y = player_bullet.y - BULLET_SPEED * dt
        if player_bullet.y + BULLET_H < 0 then
            player_bullet = nil
        end
    end

    -- Alien movement (step-based)
    local move_interval = math.max(0.05, 0.6 - (COLS * ROWS - alien_count) * 0.008 - (wave - 1) * 0.03)
    alien_move_timer = alien_move_timer + dt
    if alien_move_timer >= move_interval then
        alien_move_timer = alien_move_timer - move_interval

        local edge_hit = false
        for _, a in ipairs(aliens) do
            if a.alive then
                local nx = a.x + alien_dir * alien_speed * 0.1
                if nx < 10 or nx + ALIEN_W > SCREEN_W - 10 then
                    edge_hit = true
                    break
                end
            end
        end

        if edge_hit then
            alien_dir = -alien_dir
            for _, a in ipairs(aliens) do
                if a.alive then
                    a.y = a.y + ALIEN_H
                end
            end
        else
            for _, a in ipairs(aliens) do
                if a.alive then
                    a.x = a.x + alien_dir * alien_speed * 0.1
                end
            end
        end
    end

    -- Alien shooting
    alien_shoot_timer = alien_shoot_timer + dt
    local shoot_interval = math.max(0.3, 1.5 - wave * 0.1)
    if alien_shoot_timer >= shoot_interval then
        alien_shoot_timer = 0
        -- Pick a random alive alien
        local shooters = {}
        for _, a in ipairs(aliens) do
            if a.alive then table.insert(shooters, a) end
        end
        if #shooters > 0 then
            local a = shooters[math.random(#shooters)]
            table.insert(alien_bullets, {
                x = a.x + ALIEN_W / 2 - BULLET_W / 2,
                y = a.y + ALIEN_H,
            })
        end
    end

    -- Move alien bullets
    local i = 1
    while i <= #alien_bullets do
        local b = alien_bullets[i]
        b.y = b.y + ALIEN_BULLET_SPEED * dt
        if b.y > SCREEN_H then
            table.remove(alien_bullets, i)
        else
            i = i + 1
        end
    end

    -- UFO logic
    ufo_timer = ufo_timer - dt
    if ufo == nil and ufo_timer <= 0 then
        local dir = math.random() > 0.5 and 1 or -1
        ufo = {
            x = dir == 1 and -UFO_W or SCREEN_W,
            y = 30,
            dir = dir,
            points = math.random(1, 6) * 50,  -- 50-300
        }
        ufo_timer = random_ufo_time()
    end
    if ufo then
        ufo.x = ufo.x + ufo.dir * UFO_SPEED * dt
        if ufo.x > SCREEN_W + UFO_W or ufo.x < -UFO_W * 2 then
            ufo = nil
        end
    end

    -- -----------------------------------------------------------------------
    -- Collision: player bullet vs aliens
    -- -----------------------------------------------------------------------
    if player_bullet then
        for _, a in ipairs(aliens) do
            if a.alive and rects_overlap(
                player_bullet.x, player_bullet.y, BULLET_W, BULLET_H,
                a.x, a.y, ALIEN_W, ALIEN_H
            ) then
                a.alive = false
                alien_count = alien_count - 1
                score = score + a.points
                if score > high_score then high_score = score end
                spawn_particles(a.x + ALIEN_W / 2, a.y + ALIEN_H / 2,
                    a.color[1], a.color[2], a.color[3], 12)
                add_score_pop(a.x + ALIEN_W / 2, a.y, a.points)
                player_bullet = nil
                break
            end
        end
    end

    -- Collision: player bullet vs UFO
    if player_bullet and ufo then
        if rects_overlap(
            player_bullet.x, player_bullet.y, BULLET_W, BULLET_H,
            ufo.x, ufo.y, UFO_W, UFO_H
        ) then
            score = score + ufo.points
            if score > high_score then high_score = score end
            spawn_particles(ufo.x + UFO_W / 2, ufo.y + UFO_H / 2, 1, 0, 0, 16)
            add_score_pop(ufo.x + UFO_W / 2, ufo.y, ufo.points)
            ufo = nil
            player_bullet = nil
        end
    end

    -- Collision: player bullet vs shields
    if player_bullet then
        for _, shield in ipairs(shields) do
            for _, blk in ipairs(shield) do
                if blk.alive and rects_overlap(
                    player_bullet.x, player_bullet.y, BULLET_W, BULLET_H,
                    blk.x, blk.y, SHIELD_BLOCK, SHIELD_BLOCK
                ) then
                    blk.alive = false
                    spawn_particles(blk.x + SHIELD_BLOCK / 2, blk.y + SHIELD_BLOCK / 2,
                        0.2, 0.8, 0.2, 4)
                    player_bullet = nil
                    break
                end
            end
            if not player_bullet then break end
        end
    end

    -- Collision: alien bullets vs player
    i = 1
    while i <= #alien_bullets do
        local b = alien_bullets[i]
        if rects_overlap(b.x, b.y, BULLET_W, BULLET_H,
            player.x, player.y, PLAYER_W, PLAYER_H)
        then
            table.remove(alien_bullets, i)
            lives = lives - 1
            spawn_particles(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2,
                0.2, 0.6, 1.0, 10)
            if lives <= 0 then
                current_state = STATE.GAME_OVER
                return
            end
        else
            i = i + 1
        end
    end

    -- Collision: alien bullets vs shields
    i = 1
    while i <= #alien_bullets do
        local b = alien_bullets[i]
        local hit = false
        for _, shield in ipairs(shields) do
            for _, blk in ipairs(shield) do
                if blk.alive and rects_overlap(
                    b.x, b.y, BULLET_W, BULLET_H,
                    blk.x, blk.y, SHIELD_BLOCK, SHIELD_BLOCK
                ) then
                    blk.alive = false
                    spawn_particles(blk.x + SHIELD_BLOCK / 2, blk.y + SHIELD_BLOCK / 2,
                        0.2, 0.8, 0.2, 4)
                    hit = true
                    break
                end
            end
            if hit then break end
        end
        if hit then
            table.remove(alien_bullets, i)
        else
            i = i + 1
        end
    end

    -- Collision: aliens vs shields (aliens descending destroy shield blocks)
    for _, a in ipairs(aliens) do
        if a.alive then
            for _, shield in ipairs(shields) do
                for _, blk in ipairs(shield) do
                    if blk.alive and rects_overlap(
                        a.x, a.y, ALIEN_W, ALIEN_H,
                        blk.x, blk.y, SHIELD_BLOCK, SHIELD_BLOCK
                    ) then
                        blk.alive = false
                    end
                end
            end
        end
    end

    -- Check: aliens reached player row
    for _, a in ipairs(aliens) do
        if a.alive and a.y + ALIEN_H >= PLAYER_Y then
            current_state = STATE.GAME_OVER
            return
        end
    end

    -- Wave cleared
    if alien_count <= 0 then
        next_wave()
    end
end

-- ---------------------------------------------------------------------------
-- Render (game world)
-- ---------------------------------------------------------------------------
function lurek.draw()
    cam:apply()

    if current_state == STATE.TITLE then
        -- Title screen
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("SPACE INVADERS", SCREEN_W / 2 - 70, 120)

        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 90, 200)

        -- Point value table
        local ty = 280
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("--- SCORE TABLE ---", SCREEN_W / 2 - 80, ty)
        ty = ty + 30

        lurek.render.setColor(1, 0, 0, 1)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 80, ty, UFO_W, UFO_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("= ? MYSTERY", SCREEN_W / 2 - 30, ty + 2)
        ty = ty + 30

        lurek.render.setColor(1, 0, 1, 1)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 80, ty, ALIEN_W, ALIEN_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("= 30 PTS", SCREEN_W / 2 - 30, ty + 4)
        ty = ty + 30

        lurek.render.setColor(0, 1, 1, 1)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 80, ty, ALIEN_W, ALIEN_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("= 20 PTS", SCREEN_W / 2 - 30, ty + 4)
        ty = ty + 30

        lurek.render.setColor(0, 1, 0, 1)
        lurek.render.rectangle("fill", SCREEN_W / 2 - 80, ty, ALIEN_W, ALIEN_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("= 10 PTS", SCREEN_W / 2 - 30, ty + 4)

        cam:reset()
        return
    end

    -- ----- PLAYING / GAME_OVER world draw -----

    -- Shields
    lurek.render.setColor(0.2, 0.8, 0.2, 1)
    for _, shield in ipairs(shields) do
        for _, blk in ipairs(shield) do
            if blk.alive then
                lurek.render.rectangle("fill", blk.x, blk.y, SHIELD_BLOCK, SHIELD_BLOCK)
            end
        end
    end

    -- Aliens
    for _, a in ipairs(aliens) do
        if a.alive then
            lurek.render.setColor(a.color[1], a.color[2], a.color[3], 1)
            lurek.render.rectangle("fill", a.x, a.y, ALIEN_W, ALIEN_H)
        end
    end

    -- UFO
    if ufo then
        lurek.render.setColor(1, 0, 0, 1)
        lurek.render.rectangle("fill", ufo.x, ufo.y, UFO_W, UFO_H)
    end

    -- Player ship (body + turret)
    lurek.render.setColor(0.2, 0.6, 1.0, 1)
    lurek.render.rectangle("fill", player.x, player.y, PLAYER_W, PLAYER_H)
    lurek.render.rectangle("fill",
        player.x + PLAYER_W / 2 - PLAYER_TURRET_W / 2,
        player.y - PLAYER_TURRET_H,
        PLAYER_TURRET_W, PLAYER_TURRET_H)

    -- Player bullet
    if player_bullet then
        lurek.render.setColor(1, 1, 0, 1)
        lurek.render.rectangle("fill", player_bullet.x, player_bullet.y, BULLET_W, BULLET_H)
    end

    -- Alien bullets
    lurek.render.setColor(1, 0.3, 0.3, 1)
    for _, b in ipairs(alien_bullets) do
        lurek.render.rectangle("fill", b.x, b.y, BULLET_W, BULLET_H)
    end

    -- Particles
    draw_particles()

    -- Score pops
    draw_score_pops()

    -- Game-over overlay (in world space)
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 50, SCREEN_H / 2 - 30)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.print("PRESS R OR ENTER TO RESTART", SCREEN_W / 2 - 120, SCREEN_H / 2 + 10)
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
    lurek.render.print("LIVES: " .. tostring(lives), SCREEN_W - 100, 8)

    -- Wave
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    lurek.render.print("WAVE " .. tostring(wave), SCREEN_W - 100, 28)

    -- FPS counter
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print("FPS: " .. tostring(math.floor(fps)), 10, SCREEN_H - 20)

    -- Ground line
    lurek.render.setColor(0.2, 0.8, 0.2, 1)
    lurek.render.rectangle("fill", 0, SCREEN_H - 24, SCREEN_W, 2)
end
