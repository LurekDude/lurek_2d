-- Asteroids — Classic Arcade (Luna2D demo)
-- Pilot your ship through an asteroid belt. Shoot or dodge to survive.
-- Rotate with Left/Right, thrust with Up, shoot with Space. Screen wraps.
-- Run with: cargo run -- demos/arcade/asteroids

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local SHIP_DRAG = 0.985
local BULLET_SPEED = 420
local BULLET_LIFE = 1.4
local THRUST = 320
local ROTATE_SPEED = 200 -- degrees per second
local MAX_BULLETS = 6
local SHOOT_CD_TIME = 0.18

-- ── State ────────────────────────────────────────────────────────────────

local ship = {}
local bullets = {}
local asteroids = {}
local particles = {}
local score, lives, wave = 0, 3, 1
local game_state = "playing"
local shoot_cd = 0
local respawn_timer = 0
local invincible = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function wrap(x, y)
    return (x % W + W) % W, (y % H + H) % H
end

local function deg2rad(d) return d * math.pi / 180 end

local function spawn_asteroid(x, y, size, vx, vy)
    local angle = math.random() * 360
    local speed = (4 - size) * 30 + math.random() * 40
    return {
        x = x, y = y,
        vx = vx or math.cos(deg2rad(angle)) * speed,
        vy = vy or math.sin(deg2rad(angle)) * speed,
        size = size,          -- 3=large, 2=medium, 1=small
        r = size * 18 + math.random() * 8,
        angle = math.random() * 360,
        spin = (math.random() * 90 - 45),
        verts = {}
    }
end

local function gen_verts(a)
    a.verts = {}
    local n = 10 + math.random(5)
    for i = 1, n do
        local ang = (i - 1) / n * 2 * math.pi
        local jitter = a.r * (0.75 + math.random() * 0.35)
        a.verts[#a.verts+1] = { math.cos(ang) * jitter, math.sin(ang) * jitter }
    end
end

local function init_wave()
    asteroids = {}
    local count = 2 + wave
    for i = 1, count do
        local angle = math.random() * 360
        local dist = 200 + math.random() * 200
        local ax = W/2 + math.cos(deg2rad(angle)) * dist
        local ay = H/2 + math.sin(deg2rad(angle)) * dist
        local a = spawn_asteroid(ax, ay, 3)
        gen_verts(a)
        asteroids[#asteroids+1] = a
    end
    bullets = {}
end

local function reset_ship()
    ship = { x = W/2, y = H/2, vx = 0, vy = 0, angle = -90, thrusting = false }
    invincible = 2.5
end

local function emit_particles(x, y, n, speed, life)
    for i = 1, n do
        local a = deg2rad(math.random() * 360)
        local sp = speed * (0.5 + math.random() * 0.5)
        particles[#particles+1] = {
            x = x, y = y,
            vx = math.cos(a) * sp, vy = math.sin(a) * sp,
            life = life, max_life = life,
            size = 3 + math.random() * 3
        }
    end
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.init()
    luna.gfx.setBackgroundColor(0, 0, 0.02)
    score = 0; lives = 3; wave = 1
    reset_ship()
    init_wave()
    game_state = "playing"
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.process(dt)
    if game_state ~= "playing" then return end

    shoot_cd = math.max(0, shoot_cd - dt)
    invincible = math.max(0, invincible - dt)

    -- Ship rotation
    if luna.input.isKeyDown("left") then
        ship.angle = ship.angle - ROTATE_SPEED * dt
    end
    if luna.input.isKeyDown("right") then
        ship.angle = ship.angle + ROTATE_SPEED * dt
    end

    -- Thrust
    ship.thrusting = luna.input.isKeyDown("up")
    if ship.thrusting then
        local rad = deg2rad(ship.angle)
        ship.vx = ship.vx + math.cos(rad) * THRUST * dt
        ship.vy = ship.vy + math.sin(rad) * THRUST * dt
    end

    -- Drag
    ship.vx = ship.vx * math.pow(SHIP_DRAG, dt * 60)
    ship.vy = ship.vy * math.pow(SHIP_DRAG, dt * 60)

    -- Move and wrap
    ship.x, ship.y = wrap(ship.x + ship.vx * dt, ship.y + ship.vy * dt)

    -- Update bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.x, b.y = wrap(b.x, b.y)
        b.life = b.life - dt
        if b.life <= 0 then table.remove(bullets, i) end
    end

    -- Update asteroids
    for _, a in ipairs(asteroids) do
        a.x, a.y = wrap(a.x + a.vx * dt, a.y + a.vy * dt)
        a.angle = a.angle + a.spin * dt
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end

    -- Bullet vs asteroid
    for bi = #bullets, 1, -1 do
        if not bullets[bi] then break end
        local b = bullets[bi]
        for ai = #asteroids, 1, -1 do
            if not asteroids[ai] then break end
            local a = asteroids[ai]
            local dx = b.x - a.x; local dy = b.y - a.y
            if dx*dx + dy*dy < a.r * a.r then
                table.remove(bullets, bi)
                score = score + ({150, 75, 30})[a.size] or 30
                emit_particles(a.x, a.y, 12, 80, 0.8)
                if a.size > 1 then
                    for s = 1, 2 do
                        local na = spawn_asteroid(a.x, a.y, a.size - 1, a.vx + (s==1 and 40 or -40), a.vy + (s==1 and -30 or 30))
                        gen_verts(na)
                        asteroids[#asteroids+1] = na
                    end
                end
                table.remove(asteroids, ai)
                break
            end
        end
    end

    -- Asteroid vs ship
    if invincible <= 0 then
        for _, a in ipairs(asteroids) do
            local dx = ship.x - a.x; local dy = ship.y - a.y
            if dx*dx + dy*dy < (a.r + 8)^2 then
                emit_particles(ship.x, ship.y, 20, 120, 1.2)
                lives = lives - 1
                reset_ship()
                if lives <= 0 then game_state = "gameover" end
                break
            end
        end
    end

    -- Wave clear
    if #asteroids == 0 then
        wave = wave + 1
        init_wave()
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

local function draw_ship(sx, sy, angle)
    local rad = deg2rad(angle)
    local cos_a, sin_a = math.cos(rad), math.sin(rad)
    local function rot(lx, ly)
        return sx + lx * cos_a - ly * sin_a, sy + lx * sin_a + ly * cos_a
    end
    local x1, y1 = rot(16, 0)
    local x2, y2 = rot(-10, -9)
    local x3, y3 = rot(-10, 9)
    luna.gfx.line(x1, y1, x2, y2)
    luna.gfx.line(x2, y2, x3, y3)
    luna.gfx.line(x3, y3, x1, y1)
end

local star_seed = 7
function luna.render()
    -- Stars
    math.randomseed(star_seed)
    for i = 1, 90 do
        local alpha = 0.3 + math.random() * 0.5
        luna.gfx.setColor(alpha, alpha, alpha)
        luna.gfx.circle("fill", math.random(W), math.random(H), 1)
    end
    math.randomseed(os.time())

    -- HUD
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("ASTEROIDS", W/2 - 55, 5, 2)
    luna.gfx.setColor(0.8, 0.9, 1)
    luna.gfx.print("Score: " .. score, 8, 8, 1.5)
    luna.gfx.setColor(1, 0.4, 0.4)
    luna.gfx.print("Lives: " .. lives, W - 100, 8, 1.5)
    luna.gfx.setColor(0.5, 0.6, 0.8)
    luna.gfx.print("Wave " .. wave, W - 70, H - 20, 1.5)

    -- Particles
    for _, p in ipairs(particles) do
        local t = p.life / p.max_life
        luna.gfx.setColor(1, 0.6 * t + 0.2, 0.1, t)
        luna.gfx.circle("fill", p.x, p.y, p.size * t)
    end

    -- Asteroids
    luna.gfx.setColor(0.8, 0.75, 0.65)
    for _, a in ipairs(asteroids) do
        local rad = deg2rad(a.angle)
        local cos_a, sin_a = math.cos(rad), math.sin(rad)
        if #a.verts >= 2 then
            for vi = 1, #a.verts do
                local v1 = a.verts[vi]
                local v2 = a.verts[vi % #a.verts + 1]
                local x1 = a.x + v1[1] * cos_a - v1[2] * sin_a
                local y1 = a.y + v1[1] * sin_a + v1[2] * cos_a
                local x2 = a.x + v2[1] * cos_a - v2[2] * sin_a
                local y2 = a.y + v2[1] * sin_a + v2[2] * cos_a
                luna.gfx.line(x1, y1, x2, y2)
            end
        end
    end

    -- Ship (blink when invincible)
    if game_state == "playing" and (invincible <= 0 or math.floor(invincible * 8) % 2 == 0) then
        luna.gfx.setColor(0.4, 0.9, 1.0)
        draw_ship(ship.x, ship.y, ship.angle)
        -- Thrust flame
        if ship.thrusting then
            local rad = deg2rad(ship.angle + 180)
            local cos_a, sin_a = math.cos(rad), math.sin(rad)
            local fx = ship.x + math.cos(deg2rad(ship.angle)) * (-12)
            local fy = ship.y + math.sin(deg2rad(ship.angle)) * (-12)
            luna.gfx.setColor(1, 0.5, 0.1, 0.8)
            luna.gfx.circle("fill", fx, fy, 5 + math.random() * 4)
        end
    end

    -- Bullets
    luna.gfx.setColor(1, 1, 0.6)
    for _, b in ipairs(bullets) do
        luna.gfx.circle("fill", b.x, b.y, 3)
    end

    -- Overlay
    if game_state == "gameover" then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.3, 0.3)
        luna.gfx.print("GAME OVER", W/2 - 80, H/2 - 30, 3)
        luna.gfx.setColor(1, 1, 1)
        luna.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        luna.gfx.setColor(0.6, 0.6, 0.6)
        luna.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.signal.restart() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "z") and shoot_cd <= 0 and #bullets < MAX_BULLETS then
        local rad = deg2rad(ship.angle)
        bullets[#bullets+1] = {
            x = ship.x + math.cos(rad) * 16,
            y = ship.y + math.sin(rad) * 16,
            vx = ship.vx + math.cos(rad) * BULLET_SPEED,
            vy = ship.vy + math.sin(rad) * BULLET_SPEED,
            life = BULLET_LIFE
        }
        shoot_cd = SHOOT_CD_TIME
    end
end
