-- ============================================================================
--  Asteroids — Fly, shoot, and survive the asteroid field
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : original game — no prior demo
--  Run with : cargo run -- content/games/arcade/asteroids
--
--  Controls (bound as input actions — see lurek.init):
--    rotate_left  : A / ←
--    rotate_right : D / →
--    thrust       : W / ↑
--    fire         : Space
--    quit         : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local SHIP_TURN_SPEED     = 5.0       -- radians / second
local SHIP_THRUST         = 280       -- acceleration px/s²
local SHIP_DRAG           = 0.98      -- velocity multiplier per frame
local SHIP_SIZE           = 14        -- half-length of ship triangle
local BULLET_SPEED        = 450
local BULLET_LIFETIME     = 2.0
local MAX_BULLETS         = 4
local FIRE_COOLDOWN       = 0.15
local RESPAWN_TIME        = 2.0       -- invincibility duration
local START_ASTEROIDS     = 4
local PI2                 = math.pi * 2

-- Asteroid radius per size tier
local ASTEROID_RADIUS = { large = 40, medium = 25, small = 15 }
local ASTEROID_SPEED  = { large = 60, medium = 100, small = 160 }
local ASTEROID_SCORE  = { large = 25, medium = 50,  small = 100 }

-- ── Scene states ──────────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local state = STATE.TITLE

-- ── Game state ────────────────────────────────────────────────────────────
local ship           -- { x, y, angle, vx, vy, thrusting }
local bullets        -- array of { x, y, vx, vy, life }
local asteroids      -- array of { x, y, vx, vy, radius, size, verts }
local score, lives, wave
local fire_timer
local respawn_timer  -- > 0 means invincible
local cam

-- Visual effects
local explosions     -- particle system
local thrust_sparks  -- particle system
local score_pops     -- array of { x, y, value, alpha }
local score_pop_tweens

-- Title blink
local title_blink = 0

-- ── Helpers ───────────────────────────────────────────────────────────────

--- Wrap a coordinate so objects reappear on the opposite edge.
local function wrap_x(x) return (x + SCREEN_W) % SCREEN_W end
local function wrap_y(y) return (y + SCREEN_H) % SCREEN_H end

--- Build an irregular polygon for an asteroid.
local function make_asteroid_verts(radius)
    local n = math.random(6, 8)
    local verts = {}
    for i = 1, n do
        local angle = (i - 1) / n * PI2
        local r = radius * (0.7 + math.random() * 0.6)
        verts[#verts + 1] = { math.cos(angle) * r, math.sin(angle) * r }
    end
    return verts
end

--- Spawn a single asteroid at (x,y) with given size tier.
local function spawn_asteroid(x, y, size)
    local radius = ASTEROID_RADIUS[size]
    local speed  = ASTEROID_SPEED[size]
    local angle  = math.random() * PI2
    asteroids[#asteroids + 1] = {
        x     = x,
        y     = y,
        vx    = math.cos(angle) * speed,
        vy    = math.sin(angle) * speed,
        radius = radius,
        size  = size,
        verts = make_asteroid_verts(radius),
    }
end

--- Spawn a wave of large asteroids along the screen edges.
local function spawn_wave()
    wave = wave + 1
    local count = START_ASTEROIDS + wave - 1
    for _ = 1, count do
        -- spawn along a random edge, away from ship center
        local x, y
        repeat
            local edge = math.random(4)
            if edge == 1 then     x = math.random() * SCREEN_W; y = 0
            elseif edge == 2 then x = SCREEN_W; y = math.random() * SCREEN_H
            elseif edge == 3 then x = math.random() * SCREEN_W; y = SCREEN_H
            else                  x = 0; y = math.random() * SCREEN_H
            end
        until math.abs(x - SCREEN_W / 2) > 100 or math.abs(y - SCREEN_H / 2) > 100
        spawn_asteroid(x, y, "large")
    end
end

--- Distance² between two points.
local function dist2(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

--- Circle vs circle collision.
local function circles_hit(ax, ay, ar, bx, by, br)
    return dist2(ax, ay, bx, by) < (ar + br) * (ar + br)
end

--- Reset the ship to center with invincibility.
local function respawn_ship()
    ship = {
        x = SCREEN_W / 2,
        y = SCREEN_H / 2,
        angle = -math.pi / 2,  -- pointing up
        vx = 0, vy = 0,
        thrusting = false,
    }
    respawn_timer = RESPAWN_TIME
end

--- Full game reset.
local function reset_game()
    score      = 0
    lives      = 3
    wave       = 0
    bullets    = {}
    asteroids  = {}
    fire_timer = 0
    score_pops = {}
    score_pop_tweens = {}
    respawn_ship()
    spawn_wave()
    state = STATE.PLAYING
end

--- Add a floating score pop.
local function add_score_pop(x, y, value)
    local pop = { x = x, y = y, value = value, alpha = 1.0, dy = 0 }
    score_pops[#score_pops + 1] = pop
    local tw = lurek.tween.to(pop, { alpha = 0, dy = -40 }, 0.8, "outQuad")
    score_pop_tweens[#score_pop_tweens + 1] = tw
end

-- ── Ship geometry ─────────────────────────────────────────────────────────

--- Get the three vertices of the ship triangle in world space.
local function ship_triangle()
    local a = ship.angle
    local cx, cy = ship.x, ship.y
    local s = SHIP_SIZE
    -- nose
    local nx = cx + math.cos(a) * s * 1.3
    local ny = cy + math.sin(a) * s * 1.3
    -- left wing
    local lx = cx + math.cos(a + 2.4) * s
    local ly = cy + math.sin(a + 2.4) * s
    -- right wing
    local rx = cx + math.cos(a - 2.4) * s
    local ry = cy + math.sin(a - 2.4) * s
    return nx, ny, lx, ly, rx, ry
end

-- ===========================================================================
--  lurek.init — runs ONCE before the window opens
-- ===========================================================================
function lurek.init()
    lurek.window.setTitle("Asteroids — Lurek2D")
    lurek.render.setBackgroundColor(0.0, 0.0, 0.02)

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Action-based input bindings
    lurek.input.bind("rotate_left",  { "a", "left"  })
    lurek.input.bind("rotate_right", { "d", "right" })
    lurek.input.bind("thrust",       { "w", "up"    })
    lurek.input.bind("fire",         { "space"       })
    lurek.input.bind("confirm",      { "return", "kp_enter" })
    lurek.input.bind("restart",      { "r"           })
    lurek.input.bind("quit",         { "escape"      })

    -- Explosion particles
    explosions = lurek.particle.newSystem({
        maxParticles = 400,
        emissionRate = 0,
        lifetimeMin  = 0.3, lifetimeMax = 1.0,
        speedMin     = 40,  speedMax    = 200,
        direction    = 0,   spread      = math.pi,
        gravityY     = 0,
        sizes        = { 3, 2, 1, 0.5 },
        colors = {
            { 1.0, 0.9, 0.5 },
            { 1.0, 0.5, 0.1 },
            { 0.6, 0.2, 0.0, 0.0 },
        },
    })

    -- Thrust flame particles
    thrust_sparks = lurek.particle.newSystem({
        maxParticles = 150,
        emissionRate = 0,
        lifetimeMin  = 0.1, lifetimeMax = 0.4,
        speedMin     = 60,  speedMax    = 160,
        direction    = 0,   spread      = 0.5,
        gravityY     = 0,
        sizes        = { 3, 2, 1 },
        colors = {
            { 0.3, 0.6, 1.0 },
            { 0.1, 0.3, 0.8 },
            { 0.05, 0.1, 0.4, 0.0 },
        },
    })

    -- Init state
    bullets    = {}
    asteroids  = {}
    score      = 0
    lives      = 3
    wave       = 0
    fire_timer = 0
    score_pops = {}
    score_pop_tweens = {}
    respawn_ship()
end

-- ===========================================================================
--  lurek.process(dt) — gameplay logic
-- ===========================================================================
function lurek.process(dt)
    -- Global quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    lurek.tween.update(dt)
    if explosions  then explosions:update(dt)  end
    if thrust_sparks then thrust_sparks:update(dt) end

    -- ── TITLE ─────────────────────────────────────────────────────────
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("confirm") then
            reset_game()
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("restart") then
            reset_game()
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────────────

    -- Respawn invincibility countdown
    if respawn_timer > 0 then
        respawn_timer = respawn_timer - dt
    end

    -- Ship rotation
    if lurek.input.isActionDown("rotate_left") then
        ship.angle = ship.angle - SHIP_TURN_SPEED * dt
    end
    if lurek.input.isActionDown("rotate_right") then
        ship.angle = ship.angle + SHIP_TURN_SPEED * dt
    end

    -- Ship thrust
    ship.thrusting = lurek.input.isActionDown("thrust")
    if ship.thrusting then
        ship.vx = ship.vx + math.cos(ship.angle) * SHIP_THRUST * dt
        ship.vy = ship.vy + math.sin(ship.angle) * SHIP_THRUST * dt

        -- Emit thrust particles behind the ship
        local exhaust_angle = ship.angle + math.pi
        local ex = ship.x + math.cos(exhaust_angle) * SHIP_SIZE
        local ey = ship.y + math.sin(exhaust_angle) * SHIP_SIZE
        thrust_sparks:emit(2, ex, ey)
    end

    -- Apply drag & move ship
    ship.vx = ship.vx * SHIP_DRAG
    ship.vy = ship.vy * SHIP_DRAG
    ship.x  = wrap_x(ship.x + ship.vx * dt)
    ship.y  = wrap_y(ship.y + ship.vy * dt)

    -- Fire bullets
    fire_timer = math.max(0, fire_timer - dt)
    if lurek.input.wasActionPressed("fire") and fire_timer <= 0 and #bullets < MAX_BULLETS then
        fire_timer = FIRE_COOLDOWN
        local nose_x = ship.x + math.cos(ship.angle) * SHIP_SIZE * 1.3
        local nose_y = ship.y + math.sin(ship.angle) * SHIP_SIZE * 1.3
        bullets[#bullets + 1] = {
            x    = nose_x,
            y    = nose_y,
            vx   = math.cos(ship.angle) * BULLET_SPEED + ship.vx * 0.5,
            vy   = math.sin(ship.angle) * BULLET_SPEED + ship.vy * 0.5,
            life = BULLET_LIFETIME,
        }
    end

    -- Update bullets
    local i = 1
    while i <= #bullets do
        local b = bullets[i]
        b.x    = wrap_x(b.x + b.vx * dt)
        b.y    = wrap_y(b.y + b.vy * dt)
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bullets, i)
        else
            i = i + 1
        end
    end

    -- Update asteroids
    for _, a in ipairs(asteroids) do
        a.x = wrap_x(a.x + a.vx * dt)
        a.y = wrap_y(a.y + a.vy * dt)
    end

    -- Bullet–asteroid collisions
    i = 1
    while i <= #bullets do
        local b = bullets[i]
        local hit = false
        local j = 1
        while j <= #asteroids do
            local a = asteroids[j]
            if circles_hit(b.x, b.y, 2, a.x, a.y, a.radius * 0.85) then
                -- Score
                local pts = ASTEROID_SCORE[a.size]
                score = score + pts
                add_score_pop(a.x, a.y, pts)

                -- Explosion particles
                local burst = ({ large = 20, medium = 12, small = 6 })[a.size]
                explosions:emit(burst, a.x, a.y)

                -- Split asteroid
                if a.size == "large" then
                    spawn_asteroid(a.x, a.y, "medium")
                    spawn_asteroid(a.x, a.y, "medium")
                elseif a.size == "medium" then
                    spawn_asteroid(a.x, a.y, "small")
                    spawn_asteroid(a.x, a.y, "small")
                end

                table.remove(asteroids, j)
                hit = true
                break
            else
                j = j + 1
            end
        end
        if hit then
            table.remove(bullets, i)
        else
            i = i + 1
        end
    end

    -- Ship–asteroid collision (only when not invincible)
    if respawn_timer <= 0 then
        for j = #asteroids, 1, -1 do
            local a = asteroids[j]
            if circles_hit(ship.x, ship.y, SHIP_SIZE * 0.6, a.x, a.y, a.radius * 0.85) then
                lives = lives - 1
                explosions:emit(30, ship.x, ship.y)
                if lives <= 0 then
                    state = STATE.GAME_OVER
                else
                    respawn_ship()
                end
                break
            end
        end
    end

    -- Wave clear — spawn next wave
    if #asteroids == 0 and state == STATE.PLAYING then
        spawn_wave()
    end

    -- Clean up finished score pops
    i = 1
    while i <= #score_pops do
        if score_pops[i].alpha <= 0.01 then
            table.remove(score_pops, i)
            table.remove(score_pop_tweens, i)
        else
            i = i + 1
        end
    end
end

-- ===========================================================================
--  lurek.render — draw WORLD (ship, asteroids, bullets, particles)
-- ===========================================================================
function lurek.draw()
    -- ── Asteroids ─────────────────────────────────────────────────────
    for _, a in ipairs(asteroids) do
        -- Color by size
        if a.size == "large" then
            lurek.render.setColor(0.6, 0.6, 0.6)
        elseif a.size == "medium" then
            lurek.render.setColor(0.7, 0.7, 0.5)
        else
            lurek.render.setColor(0.8, 0.8, 0.6)
        end

        -- Draw irregular polygon outline
        local v = a.verts
        for k = 1, #v do
            local k2 = (k % #v) + 1
            lurek.render.line(
                a.x + v[k][1],  a.y + v[k][2],
                a.x + v[k2][1], a.y + v[k2][2]
            )
        end
    end

    -- ── Bullets ───────────────────────────────────────────────────────
    lurek.render.setColor(1.0, 1.0, 0.8)
    for _, b in ipairs(bullets) do
        lurek.render.circle("fill", b.x, b.y, 2)
    end

    -- ── Ship ──────────────────────────────────────────────────────────
    if state == STATE.PLAYING then
        -- Blink during invincibility
        local visible = true
        if respawn_timer > 0 then
            visible = math.floor(respawn_timer * 8) % 2 == 0
        end

        if visible then
            local nx, ny, lx, ly, rx, ry = ship_triangle()

            -- Ship body (white triangle)
            lurek.render.setColor(1.0, 1.0, 1.0)
            lurek.render.line(nx, ny, lx, ly)
            lurek.render.line(lx, ly, rx, ry)
            lurek.render.line(rx, ry, nx, ny)

            -- Thrust exhaust flame
            if ship.thrusting then
                local mid_x = (lx + rx) / 2
                local mid_y = (ly + ry) / 2
                local flame_len = 10 + math.random() * 8
                local tail_x = mid_x + math.cos(ship.angle + math.pi) * flame_len
                local tail_y = mid_y + math.sin(ship.angle + math.pi) * flame_len

                lurek.render.setColor(0.3, 0.6, 1.0, 0.9)
                lurek.render.line(lx, ly, tail_x, tail_y)
                lurek.render.line(rx, ry, tail_x, tail_y)
            end
        end
    end

    -- ── Score pops ────────────────────────────────────────────────────
    for _, pop in ipairs(score_pops) do
        lurek.render.setColor(1.0, 1.0, 0.3, pop.alpha)
        lurek.render.print(tostring(pop.value), pop.x - 10, pop.y + pop.dy, 1.5)
    end

    -- ── Particles (explosions + thrust) are drawn by their systems ───
end

-- ===========================================================================
--  lurek.render_ui — draw UI OVERLAY (score, lives, wave, menus)
-- ===========================================================================
function lurek.draw_ui()
    -- ── TITLE SCREEN ──────────────────────────────────────────────────
    if state == STATE.TITLE then
        lurek.render.setColor(1.0, 1.0, 1.0)
        lurek.render.print("A S T E R O I D S", SCREEN_W / 2 - 150, 160, 4)

        lurek.render.setColor(0.6, 0.6, 0.7)
        lurek.render.print("Navigate the asteroid field and survive", SCREEN_W / 2 - 170, 230, 1.5)

        -- Blinking prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 120, 320, 2)
        end

        -- Controls preview
        lurek.render.setColor(0.4, 0.4, 0.5)
        lurek.render.print("A/←  D/→  Rotate",   240, 420, 1.3)
        lurek.render.print("W/↑       Thrust",    240, 440, 1.3)
        lurek.render.print("Space     Fire",      240, 460, 1.3)
        lurek.render.print("Escape    Quit",      240, 480, 1.3)
        return
    end

    -- ── HUD (always visible during play and game-over) ────────────────
    -- Score — top left
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("SCORE  " .. tostring(score), 16, 12, 2)

    -- Wave — top center
    lurek.render.setColor(0.6, 0.6, 0.7)
    lurek.render.print("WAVE " .. tostring(wave), SCREEN_W / 2 - 30, 12, 1.8)

    -- Lives — top right (draw small ship icons)
    for l = 1, lives do
        local lx = SCREEN_W - 30 - (l - 1) * 22
        local ly = 20
        lurek.render.setColor(1, 1, 1)
        lurek.render.line(lx, ly - 8, lx - 5, ly + 6)
        lurek.render.line(lx - 5, ly + 6, lx + 5, ly + 6)
        lurek.render.line(lx + 5, ly + 6, lx, ly - 8)
    end

    -- FPS — bottom left
    lurek.render.setColor(0.4, 0.4, 0.5)
    lurek.render.print("FPS: " .. math.floor(lurek.timer.getFPS()), 8, SCREEN_H - 20, 1)

    -- ── GAME OVER OVERLAY ─────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1, 0.2, 0.2)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 100, SCREEN_H / 2 - 50, 3.5)

        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Final Score: " .. tostring(score), SCREEN_W / 2 - 80, SCREEN_H / 2 + 10, 2)
        lurek.render.print("Wave: " .. tostring(wave), SCREEN_W / 2 - 40, SCREEN_H / 2 + 40, 2)

        lurek.render.setColor(0.7, 0.7, 0.7)
        lurek.render.print("Press R to restart", SCREEN_W / 2 - 100, SCREEN_H / 2 + 90, 2)
    end
end
