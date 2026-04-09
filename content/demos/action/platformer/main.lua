-- Platformer Demo for Lurek2D
-- A simple platformer showcasing physics, input, easing, and scene management.
-- Arrow keys / WASD to move, SPACE to jump.
-- Run with: cargo run -- content/demos/action/platformer

-- ── Game state ───────────────────────────────────────────────────────────

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end
local function distance(x1, y1, x2, y2) return math.sqrt((x2 - x1)^2 + (y2 - y1)^2) end

local player = {
    x = 100,
    y = 400,
    vx = 0,
    vy = 0,
    w = 24,
    h = 32,
    speed = 220,
    jump_force = -450,
    on_ground = false,
    facing = 1,        -- 1 = right, -1 = left
    score = 0,
    alive = true,
}

-- Optional: spatial audio source for footsteps (Phase 4 demo).
-- Place a "footstep.wav" next to this main.lua to enable.
local footstep_source = nil
local footstep_cooldown = 0

local gravity = 900
local platforms = {}
local coins = {}
local particles = {}
local camera_x = 0
local camera_target_x = 0

-- ── Level generation ─────────────────────────────────────────────────────

local function generate_level()
    platforms = {}
    coins = {}
    particles = {}

    -- Ground
    table.insert(platforms, { x = 0, y = 550, w = 2000, h = 50, color = {0.25, 0.6, 0.2} })

    -- Platforms
    local px = 200
    for i = 1, 12 do
        local py = 550 - math.random(80, 280)
        local pw = math.random(80, 160)
        table.insert(platforms, { x = px, y = py, w = pw, h = 16, color = {0.4, 0.35, 0.25} })

        -- Place a coin above some platforms
        if math.random() > 0.3 then
            table.insert(coins, { x = px + pw / 2, y = py - 30, collected = false, bob = 0 })
        end

        px = px + math.random(120, 250)
    end

    -- Goal flag
    table.insert(platforms, { x = px + 50, y = 350, w = 60, h = 200, color = {0.8, 0.2, 0.2} })
end

-- ── Particle effects ─────────────────────────────────────────────────────

local function spawn_particles(x, y, count, color)
    for _ = 1, count do
        table.insert(particles, {
            x = x,
            y = y,
            vx = math.random(-100, 100),
            vy = math.random(-200, -50),
            life = math.random() * 0.5 + 0.3,
            max_life = 0.8,
            r = color[1],
            g = color[2],
            b = color[3],
            size = math.random(2, 5),
        })
    end
end

-- ── Collision ────────────────────────────────────────────────────────────

local function aabb_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ── Lurek2D callbacks ─────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Platformer Demo - Lurek2D")
    lurek.gfx.setBackgroundColor(0.05, 0.07, 0.15)
    generate_level()

    -- Phase 4: load optional footstep sound for spatial audio demo
    local ok, src = pcall(lurek.audio.newSource, "footstep.wav", "static")
    if ok then
        footstep_source = src
    end
end

function lurek.process(dt)
    if not player.alive then
        return
    end

    -- Horizontal input
    player.vx = 0
    if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
        player.vx = -player.speed
        player.facing = -1
    end
    if lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
        player.vx = player.speed
        player.facing = 1
    end

    -- Apply gravity
    player.vy = player.vy + gravity * dt

    -- Move horizontally
    player.x = player.x + player.vx * dt

    -- Move vertically
    player.y = player.y + player.vy * dt

    -- Platform collision
    player.on_ground = false
    for _, p in ipairs(platforms) do
        if aabb_overlap(player.x, player.y, player.w, player.h, p.x, p.y, p.w, p.h) then
            -- Landed on top
            if player.vy > 0 and player.y + player.h - player.vy * dt <= p.y + 2 then
                player.y = p.y - player.h
                player.vy = 0
                player.on_ground = true
            -- Hit from below
            elseif player.vy < 0 and player.y - player.vy * dt >= p.y + p.h - 2 then
                player.y = p.y + p.h
                player.vy = 0
            -- Side collision
            else
                if player.vx > 0 then
                    player.x = p.x - player.w
                elseif player.vx < 0 then
                    player.x = p.x + p.w
                end
            end
        end
    end

    -- Coin collection
    for _, coin in ipairs(coins) do
        if not coin.collected then
            coin.bob = coin.bob + dt
            local dist = distance(
                player.x + player.w / 2, player.y + player.h / 2,
                coin.x, coin.y
            )
            if dist < 25 then
                coin.collected = true
                player.score = player.score + 1
                spawn_particles(coin.x, coin.y, 8, {1.0, 0.85, 0.0})
            end
        end
    end

    -- Fall off screen
    if player.y > 700 then
        player.alive = false
    end

    -- Camera follow with easing
    camera_target_x = player.x - 350
    if camera_target_x < 0 then camera_target_x = 0 end
    local ease_t = lurek.math.applyEasing("outCubic", clamp(dt * 5, 0, 1))
    camera_x = lerp(camera_x, camera_target_x, ease_t)

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    -- Phase 4: update spatial audio listener position to match player
    if footstep_source then
        lurek.audio.setPosition(footstep_source, player.x, player.y, 0)
        footstep_cooldown = footstep_cooldown - dt
        if player.on_ground and math.abs(player.vx) > 10 and footstep_cooldown <= 0 then
            lurek.audio.stop(footstep_source)
            lurek.audio.play(footstep_source)
            footstep_cooldown = 0.35
        end
    end
end

function lurek.render()
    lurek.gfx.push()
    lurek.gfx.translate(-camera_x, 0)

    -- Draw sky gradient (simple horizontal bands)
    for i = 0, 5 do
        local shade = 0.05 + i * 0.02
        lurek.gfx.setColor(shade * 0.5, shade * 0.7, shade * 1.5)
        lurek.gfx.rectangle("fill", camera_x, i * 100, 800, 100)
    end

    -- Draw platforms
    for _, p in ipairs(platforms) do
        lurek.gfx.setColor(p.color[1], p.color[2], p.color[3])
        lurek.gfx.rectangle("fill", p.x, p.y, p.w, p.h)
        -- Platform top highlight
        lurek.gfx.setColor(p.color[1] + 0.1, p.color[2] + 0.1, p.color[3] + 0.1)
        lurek.gfx.rectangle("fill", p.x, p.y, p.w, 3)
    end

    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then
            local bob_y = math.sin(coin.bob * 3) * 5
            lurek.gfx.setColor(1.0, 0.85, 0.0)
            lurek.gfx.circle("fill", coin.x, coin.y + bob_y, 8)
            lurek.gfx.setColor(1.0, 0.95, 0.5)
            lurek.gfx.circle("fill", coin.x - 2, coin.y + bob_y - 2, 3)
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        lurek.gfx.setColor(p.r, p.g, p.b, alpha)
        lurek.gfx.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    -- Draw player
    if player.alive then
        -- Body
        lurek.gfx.setColor(0.3, 0.6, 1.0)
        lurek.gfx.rectangle("fill", player.x, player.y, player.w, player.h)
        -- Eyes
        local eye_x = player.x + (player.facing > 0 and 16 or 4)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.rectangle("fill", eye_x, player.y + 8, 6, 6)
        lurek.gfx.setColor(0, 0, 0)
        lurek.gfx.rectangle("fill", eye_x + (player.facing > 0 and 2 or 0), player.y + 10, 3, 3)
    end

    lurek.gfx.pop()

    -- HUD (not affected by camera)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Coins: " .. tostring(player.score), 10, 10, 2)

    local fps = math.floor(lurek.time.getFPS())
    lurek.gfx.setColor(0.5, 0.5, 0.5)
    lurek.gfx.print("FPS: " .. tostring(fps), 700, 10, 1.5)

    if not player.alive then
        lurek.gfx.setColor(1, 0.2, 0.2)
        lurek.gfx.print("GAME OVER - Press R to restart", 200, 280, 2.5)
    end

    lurek.gfx.setColor(0.4, 0.4, 0.4)
    lurek.gfx.print("Arrows/WASD + SPACE to jump", 10, 575, 1.5)
end

function lurek.keypressed(key)
    if key == "space" and player.on_ground and player.alive then
        player.vy = player.jump_force
        player.on_ground = false
        spawn_particles(player.x + player.w / 2, player.y + player.h, 5, {0.6, 0.6, 0.6})
    end

    if key == "r" and not player.alive then
        player.x = 100
        player.y = 400
        player.vx = 0
        player.vy = 0
        player.score = 0
        player.alive = true
        player.on_ground = false
        camera_x = 0
        generate_level()
    end

    if key == "escape" then
        lurek.signal.quit()
    end
end
